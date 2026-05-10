local _, ns = ...

ns:MarkAuraDirty()

local monitorFrame = CreateFrame("Frame")
local auraProbes = {} -- key (unit_spellID) -> probe frame

-- Cache: unit -> { [spellID] = { [auraInstanceID] = true } }
local auraCache = {}
-- Cache by name: unit -> { [name] = { [auraInstanceID] = true } }
local auraCacheByName = {}
-- CDM (Blizzard Cooldown Manager) cache: extracted via hooksecurefunc on CDM viewer frames.
-- This is the ONLY way to access secret auras in WoW Midnight.
-- cdmData[unit][auraInstanceID] = { spellID = N }
local cdmData = { player = {}, target = {} }
local cdmHookedFrames = setmetatable({}, { __mode = "k" })

-- Returns a list of all spellIDs the CDM frame relates to (primary + linked)
local function GetCdmFrameSpellIDs(frame)
    if not frame.cooldownInfo or not frame.cooldownID then return {} end
    local info = frame.cooldownInfo
    local ids = {}
    if info.spellID then table.insert(ids, info.spellID) end
    if info.linkedSpellIDs then
        for _, id in ipairs(info.linkedSpellIDs) do
            table.insert(ids, id)
        end
    end
    return ids
end

local function GetCdmFrameSpellID(frame)
    local ids = GetCdmFrameSpellIDs(frame)
    return ids[#ids] -- prefer last linked (usually the buff ID), fall back to primary
end

local function HookCdmFrame(frame)
    if not frame or cdmHookedFrames[frame] then return end
    if type(frame.SetAuraInstanceInfo) ~= "function" then return end
    cdmHookedFrames[frame] = true
    hooksecurefunc(frame, "SetAuraInstanceInfo", function(self, cdmAuraInstance)
        if not cdmAuraInstance or not cdmAuraInstance.auraInstanceID then return end
        local spellIDs = GetCdmFrameSpellIDs(self)
        local unit = self.auraDataUnit
        if #spellIDs == 0 or not unit then return end
        cdmData[unit] = cdmData[unit] or {}
        local instanceID = cdmAuraInstance.auraInstanceID
        local existing = cdmData[unit][instanceID]
        if not existing or not existing.spellIDs or existing.spellIDs[1] ~= spellIDs[1] then
            cdmData[unit][instanceID] = {
                spellID = spellIDs[#spellIDs], -- legacy single field (last one)
                spellIDs = spellIDs,           -- all linked spellIDs
                appliedAt = GetTime(),
            }
        end
        ns:MarkAuraDirty()
    end)
end

local function CaptureCdmFrameState(frame)
    if not frame.cooldownInfo or not frame.cooldownID then return end
    local spellIDs = GetCdmFrameSpellIDs(frame)
    local unit = frame.auraDataUnit
    local instanceID = rawget(frame, "auraInstanceID")
    if #spellIDs > 0 and unit and type(instanceID) == "number" and instanceID > 0 then
        cdmData[unit] = cdmData[unit] or {}
        if not cdmData[unit][instanceID] then
            cdmData[unit][instanceID] = {
                spellID = spellIDs[#spellIDs],
                spellIDs = spellIDs,
                appliedAt = GetTime(),
            }
            ns:MarkAuraDirty()
        end
    end
end

-- Sets refreshed every CDM scan tick. cdmConfiguredSpellIDs reflects what the user
-- has CONFIGURED to be tracked in the Cooldown Manager — independent of whether
-- the aura is currently active. The frame stays a viewer child while configured,
-- even when hidden because the aura isn't up. Disabled cooldowns get removed from
-- the children list (or have cooldownInfo/cooldownID cleared), so we filter on
-- those fields, not on IsShown.
local cdmConfiguredSpellIDs = {}
-- Set of all spellIDs eligible for CDM in the current spec (per
-- C_CooldownViewer.GetCooldownViewerCategorySet across all 4 categories).
-- Built lazily, invalidated on spec/talent/hotfix change.
local cdmEligibleSpellIDs = {}
local cdmEligibleBuilt = false

local function ScanCdmViewers()
    wipe(cdmConfiguredSpellIDs)
    local viewers = {
        rawget(_G, "EssentialCooldownViewer"),
        rawget(_G, "BuffIconCooldownViewer"),
        rawget(_G, "BuffBarCooldownViewer"),
        rawget(_G, "UtilityCooldownViewer"),
    }
    for _, viewer in ipairs(viewers) do
        if viewer and viewer.GetChildren then
            local function visit(...)
                for i = 1, select("#", ...) do
                    local f = select(i, ...)
                    HookCdmFrame(f)
                    CaptureCdmFrameState(f)
                    if f and f.cooldownInfo and f.cooldownID then
                        local cdInfo = f.cooldownInfo
                        if cdInfo.spellID then cdmConfiguredSpellIDs[cdInfo.spellID] = true end
                        if cdInfo.linkedSpellIDs then
                            for _, id in ipairs(cdInfo.linkedSpellIDs) do
                                cdmConfiguredSpellIDs[id] = true
                            end
                        end
                    end
                end
            end
            pcall(visit, viewer:GetChildren())
        end
    end
end

local function BuildCdmEligibleCache()
    wipe(cdmEligibleSpellIDs)
    if C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCategorySet then
        for cat = 0, 3 do
            local okIDs, ids = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, cat, true)
            if okIDs and type(ids) == "table" then
                for _, cdID in ipairs(ids) do
                    local okInfo, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
                    if okInfo and type(info) == "table" then
                        if info.spellID then cdmEligibleSpellIDs[info.spellID] = true end
                        if type(info.linkedSpellIDs) == "table" then
                            for _, lid in ipairs(info.linkedSpellIDs) do
                                cdmEligibleSpellIDs[lid] = true
                            end
                        end
                    end
                end
            end
        end
    end
    cdmEligibleBuilt = true
end

local function FindCdmAuraData(unit, spellID)
    local data = cdmData[unit]
    if not data then return nil, nil end
    for instanceID, info in pairs(data) do
        local match = (info.spellID == spellID)
        if not match and info.spellIDs then
            for _, id in ipairs(info.spellIDs) do
                if id == spellID then match = true; break end
            end
        end
        if match and C_UnitAuras.GetAuraDataByAuraInstanceID then
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, instanceID)
            if auraData then return auraData, info end
            data[instanceID] = nil
        end
    end
    return nil, nil
end

-- Used by Config UI to decide whether to flag an aura with the !CDM badge.
-- Three branches, only the middle one returns false (= show badge):
--   1. Configured in any CDM viewer            → true  (user tracks it; aura active or not)
--   2. Eligible per CategorySet but not chosen → false (user disabled it; show badge)
--   3. Not in any CategorySet at all           → true  (CDM literally can't track it,
--                                                       so the badge would be misleading)
function ns:IsAuraInCDM(spellID)
    if type(spellID) ~= "number" then return true end
    if cdmConfiguredSpellIDs[spellID] then return true end
    if not cdmEligibleBuilt then BuildCdmEligibleCache() end
    if cdmEligibleSpellIDs[spellID] then return false end
    return true
end
-- CLEU-based tracking for auras hidden from standard APIs.
-- key: unit_spellID -> { active = bool, startTime, duration, stacks }
local cleuAuras = {}

local function CleuKey(unit, spellID) return (unit or "?") .. "_" .. (spellID or 0) end

local function CleuMarkApplied(unit, spellID, duration)
    local k = CleuKey(unit, spellID)
    local now = GetTime()
    cleuAuras[k] = cleuAuras[k] or {}
    cleuAuras[k].active = true
    cleuAuras[k].startTime = now
    cleuAuras[k].duration = duration or cleuAuras[k].duration or 0
    cleuAuras[k].stacks = (cleuAuras[k].stacks and cleuAuras[k].active) and cleuAuras[k].stacks or 1
end

local function CleuMarkRemoved(unit, spellID)
    local k = CleuKey(unit, spellID)
    if cleuAuras[k] then cleuAuras[k].active = false end
end

local function CleuMarkDose(unit, spellID, stacks)
    local k = CleuKey(unit, spellID)
    cleuAuras[k] = cleuAuras[k] or { active = true, startTime = GetTime() }
    cleuAuras[k].stacks = stacks or (cleuAuras[k].stacks or 1)
end

local function GetCleuStatus(unit, spellID)
    local entry = cleuAuras[CleuKey(unit, spellID)]
    if not entry or not entry.active then return nil end
    local remaining = 0
    if entry.duration and entry.duration > 0 then
        remaining = (entry.startTime + entry.duration) - GetTime()
        if remaining <= 0 then
            entry.active = false
            return nil
        end
    end
    return { active = true, remaining = remaining, duration = entry.duration or 0, stacks = entry.stacks or 1 }
end

-- Per-spellID cache of the last-known public aura duration. Persisted in SavedVariables
-- (ns.globalDB.knownDurations) and rebound at InitAuraMonitor; without this, every /reload
-- erases the learned values and the SecureNumber-tainted-in-combat fallback can't compute
-- remaining time until the player sees the aura once out of combat.
local knownAuraDurations = {}
local function LearnAuraDuration(spellID, duration)
    if type(duration) == "number" and duration > 0 then
        knownAuraDurations[spellID] = duration
    end
end

local function GetProbe(key)
    local probe = auraProbes[key]
    if probe then return probe end
    probe = ns.CreateProbe()
    auraProbes[key] = probe
    return probe
end

local function CacheAddAura(unit, spellID, name, auraInstanceID)
    if not unit or not auraInstanceID then return end
    if spellID then
        auraCache[unit] = auraCache[unit] or {}
        auraCache[unit][spellID] = auraCache[unit][spellID] or {}
        auraCache[unit][spellID][auraInstanceID] = true
    end
    if name and type(name) == "string" then
        auraCacheByName[unit] = auraCacheByName[unit] or {}
        auraCacheByName[unit][name] = auraCacheByName[unit][name] or {}
        auraCacheByName[unit][name][auraInstanceID] = true
    end
end

local function CacheRemoveByInstanceID(unit, auraInstanceID)
    local byUnit = auraCache[unit]
    if byUnit then
        for spellID, instances in pairs(byUnit) do
            if instances[auraInstanceID] then
                instances[auraInstanceID] = nil
                if next(instances) == nil then byUnit[spellID] = nil end
            end
        end
    end
    local byName = auraCacheByName[unit]
    if byName then
        for name, instances in pairs(byName) do
            if instances[auraInstanceID] then
                instances[auraInstanceID] = nil
                if next(instances) == nil then byName[name] = nil end
            end
        end
    end
end

local function CacheClearUnit(unit)
    auraCache[unit] = nil
    auraCacheByName[unit] = nil
end

-- Get the first cached auraInstanceID for (unit, spellID) — try by ID first, then by name
local function GetCachedAuraInstanceID(unit, spellID)
    local byUnit = auraCache[unit]
    if byUnit then
        local instances = byUnit[spellID]
        if instances then
            local id = next(instances)
            if id then return id end
        end
    end
    -- Fall back to name lookup
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local spellName = spellInfo and spellInfo.name
    if spellName then
        local byName = auraCacheByName[unit]
        if byName then
            local instances = byName[spellName]
            if instances then return next(instances) end
        end
    end
    return nil
end

-- Build set of (spellID, name) that we want to cache
local function GetTrackedSets()
    local idSet, nameSet = {}, {}
    for _, e in ipairs(ns.db.cursorAuras or {}) do
        idSet[e.spellID] = true
        local info = C_Spell.GetSpellInfo(e.spellID)
        if info and info.name then nameSet[info.name] = true end
    end
    for _, e in ipairs(ns.db.ringAuras or {}) do
        idSet[e.spellID] = true
        local info = C_Spell.GetSpellInfo(e.spellID)
        if info and info.name then nameSet[info.name] = true end
    end
    return idSet, nameSet
end

local function SafePublicString(v)
    if type(v) ~= "string" then return nil end
    local isSecretFn = rawget(_G, "issecretvalue")
    if isSecretFn and isSecretFn(v) then return nil end
    return v
end

-- Reproduce un sonido cuando la aura recién aplicada coincide con una entry que
-- tenga playSound activo. Sólo se llama desde la rama addedAuras de
-- ProcessAuraUpdate, así que no dispara en zone-in / cambios de target / refreshes.
local function PlayAuraSoundIfEnabled(unit, spellID)
    if not spellID or not unit or not ns.db then return end
    local function check(list)
        for _, e in ipairs(list or {}) do
            if e.spellID == spellID and e.unit == unit and e.playSound then
                ns.PlayAuraSound(e.soundName or e.soundID or 8959)
                return true
            end
        end
        return false
    end
    if check(ns.db.cursorAuras) then return end
    check(ns.db.ringAuras)
end

-- Dispara el pulse central cuando una aura recién aplicada coincide con una
-- entry (cursor o ring) que tenga cdPulse activo. Sólo activación, no refresh.
local function ShowAuraPulseIfEnabled(unit, spellID)
    if not spellID or not unit or not ns.db or not ns.ShowPulse then return end
    local function check(list)
        for _, e in ipairs(list or {}) do
            if e.spellID == spellID and e.unit == unit and e.cdPulse then
                local info = C_Spell.GetSpellInfo(spellID)
                ns:ShowPulse(info and info.iconID or 134400, info and info.name or "", false, nil)
                return true
            end
        end
        return false
    end
    if check(ns.db.cursorAuras) then return end
    check(ns.db.ringAuras)
end

local function ProcessAuraUpdate(unit, updateInfo)
    if updateInfo.isFullUpdate then
        CacheClearUnit(unit)
        if AuraUtil and AuraUtil.ForEachAura then
            local idSet, nameSet = GetTrackedSets()
            local function visit(auraData)
                if not auraData or not auraData.auraInstanceID then return end
                local sid = ns.ToPublic(auraData.spellId)
                local name = SafePublicString(auraData.name)
                local match = (sid and idSet[sid]) or (name and nameSet[name])
                if match then
                    CacheAddAura(unit, sid, name, auraData.auraInstanceID)
                end
            end
            pcall(AuraUtil.ForEachAura, unit, "HELPFUL", nil, visit, true)
            pcall(AuraUtil.ForEachAura, unit, "HARMFUL", nil, visit, true)
        end
        return
    end
    if updateInfo.addedAuras then
        local idSet, nameSet = GetTrackedSets()
        for _, auraData in ipairs(updateInfo.addedAuras) do
            if auraData.auraInstanceID then
                local sid = ns.ToPublic(auraData.spellId)
                local name = SafePublicString(auraData.name)
                local match = (sid and idSet[sid]) or (name and nameSet[name])
                if match then
                    CacheAddAura(unit, sid, name, auraData.auraInstanceID)
                    PlayAuraSoundIfEnabled(unit, sid)
                    ShowAuraPulseIfEnabled(unit, sid)
                end
            end
        end
    end
    if updateInfo.removedAuraInstanceIDs then
        for _, instanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
            CacheRemoveByInstanceID(unit, instanceID)
            if cdmData[unit] then cdmData[unit][instanceID] = nil end
        end
    end
end

local function FindAuraBySpellID(unit, spellID, filter)
    if not unit or not UnitExists(unit) then return nil end
    -- 1. CDM cache (works in combat for auras the Blizzard Cooldown Manager tracks)
    local cdmAura, cdmInfo = FindCdmAuraData(unit, spellID)
    if cdmAura then return cdmAura, cdmInfo end
    -- 2. Our event-driven cache
    local cachedID = GetCachedAuraInstanceID(unit, spellID)
    if cachedID and C_UnitAuras.GetAuraDataByAuraInstanceID then
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, cachedID)
        if auraData then return auraData end
        CacheRemoveByInstanceID(unit, cachedID)
    end
    -- Fallback: official APIs
    if unit == "player" and C_UnitAuras.GetPlayerAuraBySpellID then
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if auraData then return auraData end
    end
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local spellName = spellInfo and spellInfo.name
    if spellName and C_UnitAuras.GetAuraDataBySpellName then
        for _, f in ipairs({filter, "HELPFUL|PLAYER", "HELPFUL", "HARMFUL", "HARMFUL|PLAYER"}) do
            local auraData = C_UnitAuras.GetAuraDataBySpellName(unit, spellName, f)
            if auraData then return auraData end
        end
    end
    if AuraUtil and AuraUtil.FindAuraByName and spellName then
        for _, f in ipairs({filter, "HELPFUL|PLAYER", "HELPFUL", "HARMFUL", "HARMFUL|PLAYER"}) do
            local name, _, count, _, duration, expirationTime, _, _, _, sid, _, _, _, _, _, _, _, _, _, _ = AuraUtil.FindAuraByName(spellName, unit, f)
            if name then
                return {
                    name = name,
                    auraInstanceID = nil,
                    applications = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    spellId = sid,
                }
            end
        end
    end
    return nil
end

local function HandleCleu()
    local _, subEvent, _, _, _, _, _, destGUID, _, _, _, spellID, _, _, _, _, _, amount = CombatLogGetCurrentEventInfo()
    if not spellID then return end
    -- Determine which "unit" key matches this event's destination
    local unit
    if destGUID == UnitGUID("player") then unit = "player"
    elseif UnitExists("target") and destGUID == UnitGUID("target") then unit = "target"
    elseif UnitExists("focus") and destGUID == UnitGUID("focus") then unit = "focus"
    end
    if not unit then return end
    -- Only process if we're tracking this spellID
    local idSet = GetTrackedSets()
    if not idSet[spellID] then return end
    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
        local dur = knownAuraDurations[spellID] or 0
        CleuMarkApplied(unit, spellID, dur)
        ns:MarkAuraDirty()
    elseif subEvent == "SPELL_AURA_APPLIED_DOSE" or subEvent == "SPELL_AURA_REMOVED_DOSE" then
        CleuMarkDose(unit, spellID, amount)
        ns:MarkAuraDirty()
    elseif subEvent == "SPELL_AURA_REMOVED" then
        CleuMarkRemoved(unit, spellID)
        ns:MarkAuraDirty()
    end
end

local function FullScanUnit(unit)
    if unit and UnitExists(unit) then
        ProcessAuraUpdate(unit, { isFullUpdate = true })
    end
end

local function FullScanAll()
    FullScanUnit("player")
    FullScanUnit("target")
    FullScanUnit("focus")
    FullScanUnit("mouseover")
end

function ns:InitAuraMonitor()
    -- Hydrate (and rebind) the in-memory duration cache from SavedVariables so learned
    -- durations survive /reload and login. Rebinding the upvalue means LearnAuraDuration
    -- writes through to the persisted table without further plumbing.
    if ns.globalDB then
        ns.globalDB.knownDurations = ns.globalDB.knownDurations or {}
        knownAuraDurations = ns.globalDB.knownDurations
    end
    -- RegisterUnitEvent (not RegisterEvent) for UNIT_AURA: we only care about these specific
    -- units, and registering globally puts us in the dispatch chain for raid/party members,
    -- tainting Blizzard's health/mana/aura code on those units. Cross-addon taint = bad.
    pcall(monitorFrame.RegisterUnitEvent, monitorFrame, "UNIT_AURA", "player", "target", "focus", "mouseover", "pet")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "PLAYER_TARGET_CHANGED")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "PLAYER_FOCUS_CHANGED")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "UPDATE_MOUSEOVER_UNIT")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "PLAYER_ENTERING_WORLD")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "PLAYER_REGEN_DISABLED")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "PLAYER_REGEN_ENABLED")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "SPELL_ACTIVATION_OVERLAY_SHOW")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "SPELL_ACTIVATION_OVERLAY_HIDE")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "PLAYER_SPECIALIZATION_CHANGED")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "ACTIVE_TALENT_GROUP_CHANGED")
    pcall(monitorFrame.RegisterEvent, monitorFrame, "COOLDOWN_VIEWER_TABLE_HOTFIXED")

    -- Periodic re-scan: keeps cache fresh and hooks new CDM frames as they're created.
    local scanElapsed = 0
    monitorFrame:SetScript("OnUpdate", function(_, elapsed)
        scanElapsed = scanElapsed + elapsed
        if scanElapsed >= 0.5 then
            scanElapsed = 0
            FullScanAll()
            ScanCdmViewers()
        end
    end)
    -- Initial scan
    C_Timer.After(1, ScanCdmViewers)
    monitorFrame:SetScript("OnEvent", function(self, event, unit, updateInfo)
        if event == "UNIT_AURA" then
            if not unit then return end
            -- Skip units we don't track (huge perf win in raids: filters out raidN, partyN, nameplate*, etc.)
            local tracked = false
            for _, entry in ipairs(ns.db.cursorAuras) do
                if entry.unit == unit then tracked = true; break end
            end
            if not tracked then
                for _, entry in ipairs(ns.db.ringAuras) do
                    if entry.unit == unit then tracked = true; break end
                end
            end
            if not tracked then return end
            if type(updateInfo) == "table" then
                ProcessAuraUpdate(unit, updateInfo)
            end
            ns:MarkAuraDirty()
        elseif event == "SPELL_ACTIVATION_OVERLAY_SHOW" then
            -- arg1=spellID, arg2=texture, arg3=position
            local spellID = unit -- 1st arg after self/event
            if type(spellID) == "number" then
                local idSet = GetTrackedSets()
                if idSet[spellID] then
                    local dur = knownAuraDurations[spellID] or 0
                    CleuMarkApplied("player", spellID, dur)
                    ns:MarkAuraDirty()
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_HIDE" then
            local spellID = unit
            if type(spellID) == "number" then
                CleuMarkRemoved("player", spellID)
                ns:MarkAuraDirty()
            elseif spellID == nil then
                -- nil spellID means clear all active overlays
                wipe(cleuAuras)
                ns:MarkAuraDirty()
            end
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            -- One last scan when combat state changes
            FullScanAll()
            ns:MarkAuraDirty()
        elseif event == "PLAYER_TARGET_CHANGED" then
            CacheClearUnit("target")
            FullScanUnit("target")
            ns:MarkAuraDirty()
        elseif event == "PLAYER_FOCUS_CHANGED" then
            CacheClearUnit("focus")
            ns:MarkAuraDirty()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            CacheClearUnit("mouseover")
            ns:MarkAuraDirty()
        elseif event == "PLAYER_ENTERING_WORLD" then
            wipe(auraCache)
            wipe(auraCacheByName)
            wipe(cleuAuras)
            ns:MarkAuraDirty()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
            cdmEligibleBuilt = false
            ns:MarkAuraDirty()
            ns:MarkSpellDirty()
        elseif event == "COOLDOWN_VIEWER_TABLE_HOTFIXED" then
            cdmEligibleBuilt = false
        end
    end)
end

function ns:DebugAura(args)
    local spellID, unit, filter = args:match("^(%S+)%s*(%S*)%s*(%S*)$")
    spellID = tonumber(spellID)
    if not spellID then print("|cffff0000SAT:|r usage: /sat auradebug <spellID> [unit] [filter]"); return end
    unit = (unit ~= "" and unit) or "player"
    filter = (filter ~= "" and filter) or "HELPFUL"
    local isSecretFn = rawget(_G, "issecretvalue")
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local spellName = spellInfo and spellInfo.name or "?"
    print(string.format("|cff00ff00SAT aura debug|r v%s id=%d name=%s unit=%s filter=%s", ns.VERSION or "?", spellID, spellName, unit, filter))
    if not UnitExists(unit) then print("  unit doesn't exist"); return end
    local cachedID = GetCachedAuraInstanceID(unit, spellID)
    print(string.format("  cached auraInstanceID=%s", tostring(cachedID)))
    local byID = (unit == "player" and C_UnitAuras.GetPlayerAuraBySpellID) and C_UnitAuras.GetPlayerAuraBySpellID(spellID) or nil
    local byName = (spellName and C_UnitAuras.GetAuraDataBySpellName) and C_UnitAuras.GetAuraDataBySpellName(unit, spellName, filter) or nil
    local byNameAU = (spellName and AuraUtil and AuraUtil.FindAuraByName) and AuraUtil.FindAuraByName(spellName, unit, filter) or nil
    print(string.format("  GetPlayerAuraBySpellID=%s  GetAuraDataBySpellName=%s  AuraUtil.FindAuraByName=%s",
        byID and "FOUND" or "nil", byName and "FOUND" or "nil", byNameAU and "FOUND" or "nil"))
    local cleu = GetCleuStatus(unit, spellID)
    if cleu then
        print(string.format("  CLEU: active=true remaining=%.2f duration=%.2f stacks=%s",
            cleu.remaining or 0, cleu.duration or 0, tostring(cleu.stacks)))
    else
        print("  CLEU: not active")
    end
    local cdmHits = 0
    if cdmData[unit] then
        for iid, info in pairs(cdmData[unit]) do
            if info.spellID == spellID then cdmHits = cdmHits + 1 end
        end
    end
    local hooked = 0
    for _ in pairs(cdmHookedFrames) do hooked = hooked + 1 end
    print(string.format("  CDM: hookedFrames=%d  matchingEntries=%d  cooldownViewerEnabled=%s",
        hooked, cdmHits,
        tostring(C_CVar and C_CVar.GetCVarBool and C_CVar.GetCVarBool("cooldownViewerEnabled") or "?")))
    local auraData = FindAuraBySpellID(unit, spellID, filter)
    if not auraData then
        print("  |cffff8800Aura no encontrada.|r Si está visible en el juego, espera a que se reaplique (cache se llena con UNIT_AURA addedAuras).")
        return
    end
    local function secretStr(v) if isSecretFn and isSecretFn(v) then return "SECRET" else return tostring(v) end end
    print(string.format("  auraInstanceID=%s applications=%s duration=%s expirationTime=%s",
        tostring(auraData.auraInstanceID), secretStr(auraData.applications), secretStr(auraData.duration), secretStr(auraData.expirationTime)))
    local pubStacks = ns.ToPublic(auraData.applications)
    local pubDur = ns.ToPublic(auraData.duration)
    local pubExp = ns.ToPublic(auraData.expirationTime)
    print(string.format("  pubStacks=%s  pubDur=%s  pubExp=%s",
        tostring(pubStacks), tostring(pubDur), tostring(pubExp)))
    if auraData.auraInstanceID and C_UnitAuras.GetAuraDuration then
        local okObj, durationObj = pcall(C_UnitAuras.GetAuraDuration, unit, auraData.auraInstanceID)
        if okObj and durationObj then
            local probe = ns.CreateProbe()
            local active, remaining = ns.ProbeDurationObject(probe, durationObj)
            print(string.format("  probe active=%s remaining=%s", tostring(active), tostring(remaining)))
        end
    end
    -- Look up manualDuration from user's tracked entries
    local manualDur
    for _, e in ipairs(ns.db.cursorAuras or {}) do
        if e.spellID == spellID then manualDur = e.manualDuration; break end
    end
    if not manualDur then
        for _, e in ipairs(ns.db.ringAuras or {}) do
            if e.spellID == spellID then manualDur = e.manualDuration; break end
        end
    end
    print(string.format("  configured manualDuration=%s  knownDuration=%s",
        tostring(manualDur), tostring(knownAuraDurations[spellID])))
    -- Check cdmInfo
    local _, cdmInfoChk = FindAuraBySpellID(unit, spellID, filter)
    if cdmInfoChk then
        print(string.format("  cdmInfo.appliedAt=%.2f (age=%.2fs)",
            cdmInfoChk.appliedAt or 0, GetTime() - (cdmInfoChk.appliedAt or 0)))
    else
        print("  cdmInfo: nil")
    end
    local status = ns:GetAuraStatus(spellID, unit, filter, manualDur)
    print(string.format("  RESULT: status=%s remaining=%.2f duration=%.2f stacks=%s  progress=%.2f",
        status.status, status.remaining or 0, status.duration or 0, tostring(status.stacks),
        (status.duration and status.duration > 0 and status.remaining and status.remaining > 0)
            and (status.remaining / status.duration) or 1.0))
end

function ns:DumpCdm()
    print("|cff00ff00SAT CDM dump:|r")
    -- 1. Captured aura instances
    local cdmCount = 0
    for unit, instances in pairs(cdmData) do
        for instanceID, info in pairs(instances) do
            cdmCount = cdmCount + 1
            local idsStr = "?"
            if info.spellIDs then idsStr = table.concat(info.spellIDs, ",") end
            local spellInfo = info.spellID and C_Spell.GetSpellInfo(info.spellID)
            local name = spellInfo and spellInfo.name or "?"
            print(string.format("  CAPTURED unit=%s instanceID=%d spellIDs=[%s] name=%s",
                unit, instanceID, idsStr, name))
        end
    end
    if cdmCount == 0 then print("  (no aura instances captured yet)") end

    -- 2. All hooked CDM frames with their current spellIDs
    print("|cff00ff00CDM frames (hooked) with their spellIDs:|r")
    local frameCount = 0
    for frame in pairs(cdmHookedFrames) do
        if frame.cooldownInfo and frame.cooldownID then
            frameCount = frameCount + 1
            local ids = GetCdmFrameSpellIDs(frame)
            local idsStr = (#ids > 0) and table.concat(ids, ",") or "?"
            local primaryName = ids[1] and (C_Spell.GetSpellInfo(ids[1]) and C_Spell.GetSpellInfo(ids[1]).name) or "?"
            local hasAura = rawget(frame, "auraInstanceID")
            print(string.format("  frame spellIDs=[%s] (%s) auraInstanceID=%s unit=%s",
                idsStr, primaryName, tostring(hasAura), tostring(frame.auraDataUnit)))
        end
    end
    print(string.format("  total active CDM frames: %d / %d hooked", frameCount, (function() local n=0; for _ in pairs(cdmHookedFrames) do n=n+1 end; return n end)()))
end

function ns:GetAuraStatus(spellID, unit, filter, manualDuration)
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local spellName = spellInfo and spellInfo.name or "Unknown"
    local spellIcon = spellInfo and spellInfo.iconID or 134400

    local result = { spellID=spellID, name=spellName, icon=spellIcon, status="MISSING", remaining=0, stacks=0, duration=0, expirationTime=0 }

    if not UnitExists(unit) then return result end

    local auraData, cdmInfo = FindAuraBySpellID(unit, spellID, filter)
    if auraData then
        result.status = "ACTIVE"
        result.stacks = ns.ToPublic(auraData.applications) or 0
        result.duration = ns.ToPublic(auraData.duration) or 0
        result.expirationTime = ns.ToPublic(auraData.expirationTime) or 0

        if result.expirationTime > 0 then
            local remaining = result.expirationTime - GetTime()
            if remaining < 0 then remaining = 0 end
            result.remaining = remaining
        end
        LearnAuraDuration(spellID, result.duration)

        -- Timestamp-based fallback: if duration values are secret, use CDM appliedAt + duration source
        if result.remaining == 0 and cdmInfo and cdmInfo.appliedAt then
            local dur = (manualDuration and manualDuration > 0) and manualDuration or knownAuraDurations[spellID]
            if dur and dur > 0 then
                local rem = (cdmInfo.appliedAt + dur) - GetTime()
                if rem > 0 then
                    result.remaining = rem
                    result.duration = dur
                end
            end
        end

        -- Probe path: works in combat when auraData.duration/expirationTime are SecureNumbers.
        -- Run if EITHER value is missing — the ring needs both to draw progress (rem/dur).
        if (result.remaining == 0 or result.duration == 0) and auraData.auraInstanceID and C_UnitAuras.GetAuraDuration then
            local okObj, durationObj = pcall(C_UnitAuras.GetAuraDuration, unit, auraData.auraInstanceID)
            if okObj and durationObj then
                local probe = GetProbe(unit .. "_" .. spellID)
                local active, remaining, duration = ns.ProbeDurationObject(probe, durationObj)
                if active then
                    if remaining and remaining > 0 and result.remaining == 0 then
                        result.remaining = remaining
                    end
                    if duration and duration > 0 and result.duration == 0 then
                        result.duration = duration
                        LearnAuraDuration(spellID, duration)
                    end
                end
                -- Fallback: try durObj:GetStartTime() + known duration (TMW approach)
                if result.remaining == 0 and type(durationObj.GetStartTime) == "function" then
                    local okStart, startMs = pcall(durationObj.GetStartTime, durationObj)
                    if okStart then
                        local pubStart = ns.ToPublic(startMs)
                        local known = knownAuraDurations[spellID]
                        if pubStart and pubStart > 0 and known and known > 0 then
                            local rem = ((pubStart / 1000) + known) - GetTime()
                            if rem > 0 then
                                result.remaining = rem
                                if result.duration == 0 then result.duration = known end
                            end
                        end
                    end
                end
            end
        end
    else
        -- Fallback: CLEU-based tracking for auras hidden from standard APIs
        local cleu = GetCleuStatus(unit, spellID)
        if cleu then
            result.status = "ACTIVE"
            result.stacks = cleu.stacks or 1
            result.duration = cleu.duration or 0
            result.remaining = cleu.remaining or 0
            if cleu.duration and cleu.duration > 0 then
                result.expirationTime = GetTime() + cleu.remaining
            end
        end
    end
    return result
end
