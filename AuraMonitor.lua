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
    -- 6. Slot-iteration fallback: en Midnight algunos auras (especialmente buffs
    -- de items consumibles) son visibles en GetAuraSlots pero suprimidos por
    -- todos los lookups por-ID/nombre. Iteramos los slots manualmente y
    -- matcheamos por spellId. Mas caro que un lookup directo (O(n) sobre todos
    -- los buffs/debuffs del unit) pero solo se llega aqui cuando los 5 paths
    -- anteriores fallaron, asi que el costo es acotado.
    --
    -- IMPORTANTE: data.spellId puede ser un SecureNumber para auras
    -- restringidas. Comparar SecureNumber con == taintea la ejecucion del addon
    -- de inmediato ("attempt to compare field 'spellId' (a secret number
    -- value)"). ToPublic envuelve la conversion en pcall y devuelve nil cuando
    -- el SecureNumber no es recuperable; ese aura simplemente queda fuera de
    -- match (no podemos saber si es el que buscamos sin tocar el secret value).
    if C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot then
        -- Dedupe filter: si filter es HELPFUL/HARMFUL, no lo iteramos dos veces.
        local filtersToScan
        if filter == "HELPFUL" or filter == "HARMFUL" then
            filtersToScan = { "HELPFUL", "HARMFUL" }
        else
            filtersToScan = { filter, "HELPFUL", "HARMFUL" }
        end
        for _, f in ipairs(filtersToScan) do
            local cont
            repeat
                local slots = { C_UnitAuras.GetAuraSlots(unit, f, 50, cont) }
                cont = slots[1]
                for i = 2, #slots do
                    local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
                    if data then
                        local sid = ns.ToPublic(data.spellId) or ns.ToPublic(data.spellID)
                        if sid and sid == spellID then
                            return data
                        end
                    end
                end
            until not cont
        end
    end
    return nil
end

-- ============================================================
-- Manual trigger fallback (para auras "fully restricted" en Midnight)
-- ============================================================
-- Algunos buffs (items consumibles, efectos restringidos) no se pueden detectar
-- por ningun path: GetPlayerAuraBySpellID/GetAuraDataBySpellName/FindAuraByName
-- los ocultan, CLEU los suprime, GetAuraSlots devuelve los slots pero con
-- spellId como SecureNumber (intocable). Para esos casos exponemos un workaround:
-- el usuario configura `entry.manualTriggerSpellID` o `entry.manualTriggerItemID`
-- en el editor del aura, y nosotros disparamos status=ACTIVE manualmente al
-- detectar el cast/uso del trigger. La duracion se toma de entry.manualDuration
-- (que ya existe). Sin manualDuration no hay forma de saber cuando expira, asi
-- que el modo manual requiere ese campo seteado.

-- Estado: appliedAt timestamp por (unit, spellID). El consumer en GetAuraStatus
-- compara contra GetTime() para decidir si el aura sigue "activa" segun el
-- workaround. Se sobreescribe en cada nuevo trigger.
local manualTriggerActiveSince = {}

local function MarkManualTrigger(unit, spellID)
    if not (unit and spellID) then return end
    manualTriggerActiveSince[unit] = manualTriggerActiveSince[unit] or {}
    manualTriggerActiveSince[unit][spellID] = GetTime()
    ns:MarkAuraDirty()
end

local function GetManualTriggerSince(unit, spellID)
    local u = manualTriggerActiveSince[unit]
    return u and u[spellID]
end
ns._GetManualTriggerSince = GetManualTriggerSince

-- Iterar las listas y disparar para entries cuyo trigger coincide.
-- `kind` = "item" o "spell"; `id` = itemID o spellID disparador.
--
-- Reverse lookup item→use-effect-spell: cuando el cast viene por UNIT_SPELLCAST_SUCCEEDED
-- (action bar, /use, macros), recibimos el spellID del use-effect, pero el usuario
-- pudo haber configurado solo manualTriggerItemID. Para que ese caso funcione,
-- iteramos los items configurados y comparamos su use-effect spell. Asi una sola
-- config (Item disparador=N) cubre las dos formas de activar el item: hooks de
-- bag/inventory directos y casts via action bar.
local function FireManualTriggerByID(kind, id)
    if not (kind and id and ns.db) then return end
    local function check(list)
        for _, e in ipairs(list or {}) do
            local match = false
            if kind == "item" and e.manualTriggerItemID == id then
                match = true
            elseif kind == "spell" then
                if e.manualTriggerSpellID == id then
                    match = true
                elseif e.manualTriggerItemID and C_Item and C_Item.GetItemSpell then
                    -- Reverse: este spellID podria ser el use-effect del item configurado
                    local _, useSpellID = C_Item.GetItemSpell(e.manualTriggerItemID)
                    if useSpellID == id then match = true end
                end
            end
            if match and e.spellID then
                MarkManualTrigger(e.unit or "player", e.spellID)
            end
        end
    end
    check(ns.db.cursorAuras)
    check(ns.db.ringAuras)
end

-- Resuelve el itemID disparado por UseInventoryItem/UseContainerItem y dispara.
local function HandleItemUse(itemID)
    if not itemID then return end
    FireManualTriggerByID("item", itemID)
    -- Tambien: si el item tiene use-effect spell, dispara por spellID. Esto cubre
    -- el caso del usuario que pone manualTriggerSpellID en lugar de itemID.
    if C_Item and C_Item.GetItemSpell then
        local _, sid = C_Item.GetItemSpell(itemID)
        if sid then FireManualTriggerByID("spell", sid) end
    end
end

-- Hooks defensivos: no todas las versiones del cliente exponen las mismas
-- variantes del API de uso de items. Cubrimos las 3 mas comunes.
local function InstallManualTriggerHooks()
    if rawget(_G, "UseInventoryItem") then
        hooksecurefunc("UseInventoryItem", function(slot)
            if not slot then return end
            local itemID = GetInventoryItemID and GetInventoryItemID("player", slot)
            HandleItemUse(itemID)
        end)
    end
    if rawget(_G, "UseContainerItem") then
        hooksecurefunc("UseContainerItem", function(bag, slot)
            if not (bag and slot) then return end
            local itemID = C_Container and C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot)
            HandleItemUse(itemID)
        end)
    end
    if C_Container and type(C_Container.UseContainerItem) == "function" then
        hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
            if not (bag and slot) then return end
            local itemID = C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot)
            HandleItemUse(itemID)
        end)
    end
end
ns._InstallManualTriggerHooks = InstallManualTriggerHooks

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
    -- UNIT_SPELLCAST_SUCCEEDED para player: triggerea el manual fallback cuando
    -- el cast de un spell configurado como manualTriggerSpellID se completa.
    -- RegisterUnitEvent (no RegisterEvent) para no contaminar party/raid units.
    pcall(monitorFrame.RegisterUnitEvent, monitorFrame, "UNIT_SPELLCAST_SUCCEEDED", "player")
    -- Hooks para uso de items (UseInventoryItem para slots equipados, UseContainerItem
    -- para slots de bolsa). Disparan manualTriggerItemID + auto-resuelven al
    -- spellID del use-effect via C_Item.GetItemSpell.
    InstallManualTriggerHooks()

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
    monitorFrame:SetScript("OnEvent", function(self, event, ...)
        local unit, updateInfo = ...
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
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- Args desempaquetados: castUnit, castGUID, spellID. Filtramos a
            -- player porque RegisterUnitEvent ya lo hace, pero es defensivo.
            local castUnit, _, spellID = ...
            if castUnit == "player" and type(spellID) == "number" then
                FireManualTriggerByID("spell", spellID)
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

-- Lista todas las auras activas en `unit` (default player) con su nombre +
-- spellID + source. Util cuando un item aplica un buff con spellID distinto al
-- que parece (cadena use-spell -> wrapper -> aura final): el usuario activa el
-- item, corre /hht listauras, y busca el nombre en la salida para sacar el ID
-- correcto del buff que realmente aparece en el unit.
function ns:ListAuras(args)
    local unit = (args and args:match("(%S+)")) or "player"
    if not UnitExists(unit) then print("|cffff0000HNZ:|r unit '"..unit.."' no existe"); return end
    print(string.format("|cff00ff00HNZ aura list|r unit=%s", unit))
    local found = 0
    -- Path preferido: GetAuraSlots + GetAuraDataBySlot. Devuelve siempre el
    -- AuraData table (no valores desempaquetados como ForEachAura sin
    -- usePackedAura=true), asi tenemos acceso confiable a spellId/name/source.
    if C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot then
        for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
            local cont = nil
            repeat
                local slots = { C_UnitAuras.GetAuraSlots(unit, filter, 50, cont) }
                cont = slots[1]
                for i = 2, #slots do
                    local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
                    if data then
                        local sid = data.spellId or data.spellID
                        local name = data.name or "?"
                        local src = data.sourceUnit or "?"
                        local dur = ns.ToPublic(data.duration) or 0
                        local exp = ns.ToPublic(data.expirationTime) or 0
                        local rem = (exp > 0) and (exp - GetTime()) or 0
                        print(string.format("  [%s] %s |cff888888id=%s|r src=%s dur=%.1fs rem=%.1fs",
                            filter, tostring(name), tostring(sid), tostring(src), dur, rem))
                        found = found + 1
                    end
                end
            until not cont
        end
    elseif AuraUtil and AuraUtil.ForEachAura then
        -- Fallback con la firma correcta: usePackedAura=true (5to argumento) para
        -- recibir el AuraData table en vez de los valores desempaquetados.
        for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
            AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
                if not auraData then return end
                local sid = auraData.spellId or auraData.spellID
                local name = auraData.name or "?"
                local src = auraData.sourceUnit or "?"
                local dur = ns.ToPublic(auraData.duration) or 0
                local exp = ns.ToPublic(auraData.expirationTime) or 0
                local rem = (exp > 0) and (exp - GetTime()) or 0
                print(string.format("  [%s] %s |cff888888id=%s|r src=%s dur=%.1fs rem=%.1fs",
                    filter, tostring(name), tostring(sid), tostring(src), dur, rem))
                found = found + 1
            end, true)
        end
    end
    print(string.format("|cff00ff00HNZ:|r %d auras encontradas", found))
    if found == 0 then
        print("  |cffff8800Nota:|r las 'restricted/secret auras' (algunos buffs de items en Midnight) NO aparecen aqui — solo via Cooldown Manager hook.")
    end
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
    -- Eligibilidad: si el aura no esta en cdmEligibleSpellIDs, ni siquiera el
    -- Cooldown Manager de Blizzard puede mostrarla — y nuestro hook depende de
    -- que CDM la muestre para capturarla. Si esta en eligible pero no en
    -- configured, el usuario solo tiene que añadirla al viewer correspondiente.
    if not cdmEligibleBuilt then BuildCdmEligibleCache() end
    local eligible = cdmEligibleSpellIDs[spellID] and true or false
    local configured = cdmConfiguredSpellIDs[spellID] and true or false
    print(string.format("  CDM eligibility: eligible=%s  configured=%s",
        tostring(eligible), tostring(configured)))
    if not eligible then
        print("  |cffff8800Hint:|r el spellID no esta en ninguna categoria de CDM. Ni Blizzard ni el addon pueden trackear este aura. Verifica que sea el ID correcto (puede ser otro distinto al que aplica el item).")
    elseif not configured then
        print("  |cff00ccffHint:|r el spellID es elegible para CDM pero no esta agregado a ningun viewer. Añadelo en Edit Mode → Cooldown Manager (BuffIcon o BuffBar para buffs propios) y el addon lo trackeara automaticamente.")
    end
    -- Estado del manual trigger: el sexto path final de GetAuraStatus, no parte
    -- de FindAuraBySpellID. Lo reportamos siempre porque es la red de seguridad
    -- para fully-restricted auras donde los 6 paths de deteccion no pueden matchear.
    local manualEntry
    for _, e in ipairs(ns.db.cursorAuras or {}) do
        if e.spellID == spellID and e.unit == unit then manualEntry = e; break end
    end
    if not manualEntry then
        for _, e in ipairs(ns.db.ringAuras or {}) do
            if e.spellID == spellID and e.unit == unit then manualEntry = e; break end
        end
    end
    if manualEntry then
        local triggerSince = ns._GetManualTriggerSince and ns._GetManualTriggerSince(unit, spellID)
        local age = triggerSince and (GetTime() - triggerSince) or nil
        print(string.format("  Manual trigger: spell=%s item=%s manualDuration=%s",
            tostring(manualEntry.manualTriggerSpellID or "nil"),
            tostring(manualEntry.manualTriggerItemID or "nil"),
            tostring(manualEntry.manualDuration or 0)))
        if triggerSince then
            print(string.format("  Manual trigger fired %.1fs ago (sintetiza ACTIVE si age < manualDuration)", age))
        else
            print("  Manual trigger no se ha disparado aun (no se detecto cast/uso del trigger)")
        end
    end

    local auraData = FindAuraBySpellID(unit, spellID, filter)
    if not auraData then
        print("  |cffff8800FindAuraBySpellID:|r nil (los 6 paths de deteccion fallaron). Si la aura SI esta visible en el buff bar de Blizzard, es 'fully restricted' — solo el manual trigger puede sintetizarla. Configura Item/Spell disparador en el editor.")
        -- Igual corremos GetAuraStatus para reportar si el manual trigger sintetiza ACTIVE.
        local statusFinal = ns:GetAuraStatus(spellID, unit, filter, manualEntry and manualEntry.manualDuration or nil)
        print(string.format("  |cffffcc00RESULT (con manual trigger):|r status=%s remaining=%.2f duration=%.2f",
            statusFinal.status, statusFinal.remaining or 0, statusFinal.duration or 0))
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

    -- Manual trigger fallback: ultima oportunidad para auras "fully restricted"
    -- en Midnight (item buffs, efectos secret) que ningun path detecta. Si el
    -- usuario configuro un trigger spell/item en el editor y manualDuration > 0,
    -- usamos el timestamp del ultimo cast/uso del trigger para sintetizar el
    -- estado ACTIVE. Solo entra cuando MISSING (no pisa una deteccion real).
    if result.status == "MISSING" and manualDuration and manualDuration > 0 then
        local since = GetManualTriggerSince(unit, spellID)
        if since then
            local elapsed = GetTime() - since
            if elapsed >= 0 and elapsed < manualDuration then
                result.status = "ACTIVE"
                result.duration = manualDuration
                result.remaining = manualDuration - elapsed
                result.expirationTime = since + manualDuration
            end
        end
    end
    return result
end
