local _, ns = ...

ns:MarkSpellDirty()

local monitorFrame = CreateFrame("Frame")
local cdProbes = {} -- spellID -> { cd = CooldownFrame, recharge = CooldownFrame }

local ToPublic = ns.ToPublic

local function GetProbes(spellID)
    local entry = cdProbes[spellID]
    if entry then return entry end
    entry = { cd = ns.CreateProbe(), recharge = ns.CreateProbe() }
    cdProbes[spellID] = entry
    return entry
end

-- Apply (startTime, duration) — possibly SecureNumbers — to the probe frame.
-- Returns: isActive (boolean), remainingSeconds (public number or nil)
local function ProbeCooldown(probe, startTime, duration)
    if not probe or startTime == nil or duration == nil then return false, nil end
    local okSet = pcall(probe.SetCooldown, probe, startTime, duration)
    if not okSet then return false, nil end
    local okShown, shown = pcall(probe.IsShown, probe)
    if not okShown or not shown then return false, 0 end
    -- Cooldown is active. Try to read remaining seconds.
    local okTimes, startMs, durationMs = pcall(probe.GetCooldownTimes, probe)
    if okTimes then
        startMs = ToPublic(startMs)
        durationMs = ToPublic(durationMs)
        if type(startMs) == "number" and type(durationMs) == "number" and startMs > 0 and durationMs > 0 then
            local remaining = ((startMs + durationMs) / 1000) - GetTime()
            if remaining > 0 then return true, remaining end
            return true, 0
        end
    end
    return true, nil
end

-- Apply duration object as fallback (for cases where startTime/duration aren't directly available).
local function ProbeCooldownFromDurationObject(probe, durationObj)
    if not probe or not durationObj then return false, nil end
    if type(probe.SetCooldownFromDurationObject) ~= "function" then return false, nil end
    local okSet = pcall(probe.SetCooldownFromDurationObject, probe, durationObj)
    if not okSet then return false, nil end
    local okShown, shown = pcall(probe.IsShown, probe)
    if not okShown or not shown then return false, 0 end
    local okTimes, startMs, durationMs = pcall(probe.GetCooldownTimes, probe)
    if okTimes then
        startMs = ToPublic(startMs)
        durationMs = ToPublic(durationMs)
        if type(startMs) == "number" and type(durationMs) == "number" and startMs > 0 and durationMs > 0 then
            local remaining = ((startMs + durationMs) / 1000) - GetTime()
            if remaining > 0 then return true, remaining end
            return true, 0
        end
    end
    return true, nil
end

function ns:InitSpellMonitor()
    monitorFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    monitorFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    monitorFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    -- BAG_UPDATE_COOLDOWN: cooldowns de items (trinkets, pociones) tickan/refrescan
    -- por aqui — sin esto, los entries item-based no se enteran de start/finish
    -- entre los SPELL_UPDATE_* que ya teniamos.
    monitorFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    -- RegisterUnitEvent (not RegisterEvent) so we ONLY get the event for "player".
    -- Critical: registering for UNIT_POWER_FREQUENT globally puts us in Blizzard's dispatch
    -- list for raid1..raid40/party1..party4 and taints their mana bar updates.
    pcall(monitorFrame.RegisterUnitEvent, monitorFrame, "UNIT_POWER_FREQUENT", "player")
    monitorFrame:SetScript("OnEvent", function(self, event, arg1)
        ns:MarkSpellDirty()
    end)
end

-- ============================================================
-- Item status (trinkets / use-items)
-- ============================================================
-- Devuelve la misma shape que GetSpellStatus para que los modulos consumidores
-- (CursorDisplay/CooldownPulse) no necesiten ramificar.
--
-- Cooldown: C_Item.GetItemCooldown(itemID) → (start, duration, enabled). El campo
-- `enabled` es 0 o 1 (no boolean — Blizz quirk). start/duration son segundos
-- (no ms — distinto de spells que usan ms). Cuando duration==0 el item esta
-- READY; cuando start>0 y duration>0, esta en cooldown.
--
-- charges/maxCharges: items con cargas (potion macros, etc.) las exponen via
-- GetItemCount; el numero de items en la bolsa actua como "cargas". Para un
-- trinket equipado (siempre 1) no tiene sentido — devolvemos nil.
function ns:GetItemStatus(itemID)
    local name, icon = ns.GetItemDisplayInfo(itemID)
    local result = { itemID=itemID, name=name, icon=icon, status="READY",
                     cooldownRemaining=0, charges=nil, maxCharges=nil,
                     hasCharges=false, chargesFull=nil }

    local getCD = (C_Item and C_Item.GetItemCooldown) or GetItemCooldown
    if not getCD then
        result.status = "UNUSABLE"
        return result
    end
    local ok, startTime, duration, enabled = pcall(getCD, itemID)
    if ok and type(duration) == "number" and duration > 0 and type(startTime) == "number" and startTime > 0 then
        local remaining = (startTime + duration) - GetTime()
        -- GCD-equivalente para items: cooldowns muy cortos (<= 1.5s) son el
        -- "global" item cooldown post-uso, no el real cooldown del trinket. Los
        -- ignoramos para no marcar COOLDOWN durante los 1.5s post-cast.
        if remaining > 1.6 then
            result.cooldownRemaining = remaining
            result.status = "COOLDOWN"
        end
    end

    -- Si no tenemos el item en la bolsa (count==0), marcamos UNUSABLE para que
    -- el icono se diferencie visualmente. Trinket equipado cuenta como 1 via
    -- GetItemCount(itemID, false, false, true) — cuarto param "includeCharges".
    if result.status == "READY" then
        local cnt
        if C_Item and C_Item.GetItemCount then
            cnt = C_Item.GetItemCount(itemID, false, false, true)
        elseif GetItemCount then
            cnt = GetItemCount(itemID, false, false, true)
        end
        if type(cnt) == "number" and cnt <= 0 then
            result.status = "UNUSABLE"
        end
    end

    return result
end

-- Dispatcher unificado: cualquier consumidor llama esto y recibe la shape de
-- status sin saber si la entry es spell o item. Si la entry no tiene ni spellID
-- ni itemID, devuelve un status UNUSABLE seguro (no dispara cooldown).
function ns:GetEntryStatus(entry)
    if not entry then return { status="UNUSABLE", cooldownRemaining=0 } end
    if entry.itemID and entry.itemID > 0 then return ns:GetItemStatus(entry.itemID) end
    if entry.spellID then return ns:GetSpellStatus(entry.spellID) end
    return { status="UNUSABLE", cooldownRemaining=0 }
end

function ns:GetSpellStatus(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    if not info then
        return { spellID=spellID, name="Unknown", icon=134400, status="UNUSABLE", cooldownRemaining=0, charges=nil, maxCharges=nil }
    end

    local result = { spellID=spellID, name=info.name, icon=info.iconID, status="READY", cooldownRemaining=0, charges=nil, maxCharges=nil, chargesFull=nil, hasCharges=false }

    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    local pubCurrent = ToPublic(chargeInfo and chargeInfo.currentCharges)
    local pubMax = ToPublic(chargeInfo and chargeInfo.maxCharges)
    -- Display value: raw SN if pubCurrent unavailable (SetText handles SecureNumbers natively)
    result.charges = pubCurrent or (chargeInfo and chargeInfo.currentCharges) or nil
    result.maxCharges = pubMax
    result.hasCharges = chargeInfo ~= nil
    -- isActive is a public boolean: false = no recharge running = currentCharges == maxCharges (full).
    -- true = recharge running = at least one charge missing. We can't read the count when SN-tainted,
    -- but this boolean is enough for the common gate case (minCharges == maxCharges).
    if chargeInfo and type(chargeInfo.isActive) == "boolean" then
        result.chargesFull = (chargeInfo.isActive == false)
    end
    local isMultiCharge = type(pubMax) == "number" and pubMax > 1

    local probes = GetProbes(spellID)

    -- "Has zero charges" check: prefer pubCurrent == 0; fall back to IsSpellUsable proxy
    local function HasZeroCharges()
        if type(pubCurrent) == "number" then return pubCurrent <= 0 end
        local ok, isUsable = pcall(C_Spell.IsSpellUsable, spellID)
        if ok and isUsable == false then return true end
        return false
    end

    -- Multi-charge: check recharge probe; only mark COOLDOWN if 0 charges
    if isMultiCharge and chargeInfo then
        local active, remaining = ProbeCooldown(probes.recharge, chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration)
        if not active and C_Spell.GetSpellChargeDuration then
            local rechargeObj = C_Spell.GetSpellChargeDuration(spellID)
            active, remaining = ProbeCooldownFromDurationObject(probes.recharge, rechargeObj)
        end
        if active then
            if remaining and remaining > 0 then result.cooldownRemaining = remaining end
            if HasZeroCharges() then result.status = "COOLDOWN" end
        end
    end

    -- Standard cooldown (covers non-charge AND single-charge spells like TFT)
    if result.status == "READY" then
        local cdInfo = C_Spell.GetSpellCooldown(spellID)
        local isOnGCD = cdInfo and cdInfo.isOnGCD == true
        local active, remaining = false, nil
        if cdInfo then
            active, remaining = ProbeCooldown(probes.cd, cdInfo.startTime, cdInfo.duration)
        end
        if not active and C_Spell.GetSpellCooldownDuration then
            local cdObj = C_Spell.GetSpellCooldownDuration(spellID)
            active, remaining = ProbeCooldownFromDurationObject(probes.cd, cdObj)
        end
        if active and not isOnGCD then
            if remaining and remaining > 0 then result.cooldownRemaining = remaining end
            -- For non-charge spells: any real CD = COOLDOWN
            -- For multi-charge: real CD activates only when 0 charges available
            result.status = "COOLDOWN"
        end
        -- NOTA: removido el fallback IsSpellUsable que marcaba COOLDOWN. Causaba
        -- pulses falsos al terminar estados temporales (GCD, Monk Roll,
        -- channeling, stun): el spell pasaba transitoriamente a isUsable=false,
        -- lo marcabamos COOLDOWN, y al volver a usable disparaba el pulse de
        -- "esta listo". Los cooldowns reales se detectan via el probe-path de
        -- arriba (`C_Spell.GetSpellCooldown` + isOnGCD filter). Los estados
        -- transitorios caen al check de NO_POWER/UNUSABLE de abajo — Pulse solo
        -- dispara en transicion COOLDOWN->READY, asi que UNUSABLE->READY no
        -- triggerea nada.
    end

    if result.status == "READY" then
        local ok, isUsable, insufficientPower = pcall(C_Spell.IsSpellUsable, spellID)
        if ok and isUsable == false then result.status = insufficientPower and "NO_POWER" or "UNUSABLE" end
    end

    if result.status == "READY" then
        -- Skip OOR for helpful spells when current target is hostile/unattackable —
        -- these spells will be cast on player or a friendly, so "out of range" is misleading.
        local helpful = false
        if C_Spell.IsSpellHelpful then
            local okH, h = pcall(C_Spell.IsSpellHelpful, spellID); if okH then helpful = h and true or false end
        elseif IsHelpfulSpell then
            helpful = IsHelpfulSpell(spellID) and true or false
        end
        local skipOOR = helpful and UnitExists("target") and UnitCanAttack("player", "target")
        if not skipOOR then
            local ok, inRange = pcall(C_Spell.IsSpellInRange, spellID, "target")
            if ok and inRange == false then result.status = "OUT_OF_RANGE" end
        end
    end

    return result
end

-- Debug helper: /sat debug <spellID> prints diagnostic info
function ns:DebugSpell(spellID)
    spellID = tonumber(spellID)
    if not spellID then print("|cffff0000SAT:|r usage: /sat debug <spellID>"); return end
    local status = ns:GetSpellStatus(spellID)
    print(string.format("|cff00ff00SAT debug|r v%s spell=%d name=%s", ns.VERSION or "?", spellID, status.name or "?"))
    print(string.format("  status=%s  cdRemaining=%.2fs  charges=%s/%s",
        status.status, status.cooldownRemaining or 0, tostring(status.charges), tostring(status.maxCharges)))
    local cdInfo = C_Spell.GetSpellCooldown(spellID)
    if cdInfo then
        print(string.format("  cdInfo: isEnabled=%s isOnGCD=%s",
            tostring(cdInfo.isEnabled), tostring(cdInfo.isOnGCD)))
    end
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if chargeInfo then
        print(string.format("  chargeInfo: currentCharges=%s (type=%s) maxCharges=%s (type=%s) isActive=%s",
            tostring(chargeInfo.currentCharges), type(chargeInfo.currentCharges),
            tostring(chargeInfo.maxCharges), type(chargeInfo.maxCharges),
            tostring(chargeInfo.isActive)))
        print(string.format("  ToPublic(currentCharges)=%s  ToPublic(maxCharges)=%s",
            tostring(ns.ToPublic(chargeInfo.currentCharges)), tostring(ns.ToPublic(chargeInfo.maxCharges))))
    else
        print("  chargeInfo: nil (spell has no charges per API)")
    end
    local probes = GetProbes(spellID)
    print(string.format("  cd probe shown=%s  recharge probe shown=%s",
        tostring(probes.cd:IsShown()), tostring(probes.recharge:IsShown())))

    -- Cursor display config + hide-gate simulation
    local entry
    for _, e in ipairs(ns.db.cursorSpells or {}) do
        if e.spellID == spellID then entry = e; break end
    end
    if not entry then
        print("  |cffaaaaaa(not in cursorSpells list)|r")
        return
    end
    local talentLabel = "none"
    if entry.requiredTalentSpellID then
        local tInfo = C_Spell.GetSpellInfo(entry.requiredTalentSpellID)
        local known = IsPlayerSpell and IsPlayerSpell(entry.requiredTalentSpellID) or false
        talentLabel = string.format("%s (id=%d, known=%s)", tInfo and tInfo.name or "?", entry.requiredTalentSpellID, tostring(known))
    end
    print(string.format("  entry: enabled=%s hideOnCooldown=%s minCharges=%s specs=%s talent=%s",
        tostring(entry.enabled), tostring(entry.hideOnCooldown),
        tostring(entry.minCharges or 0), (entry.specs and #entry.specs > 0) and ("["..table.concat(entry.specs,",").."]") or "any",
        talentLabel))
    -- Simulate hide logic
    local pubCharges = ns.ToPublic(status.charges)
    local pubMax = ns.ToPublic(status.maxCharges)
    local hide = entry.hideOnCooldown and status.status == "COOLDOWN"
    local reason
    if hide then reason = "hideOnCooldown + status=COOLDOWN" end
    if not hide and entry.minCharges and entry.minCharges > 0 then
        if type(pubCharges) == "number" then
            if pubCharges < entry.minCharges then
                hide = true; reason = string.format("pubCharges=%d < minCharges=%d", pubCharges, entry.minCharges)
            end
        elseif status.hasCharges and status.chargesFull ~= nil then
            if status.chargesFull then
                if type(pubMax) == "number" and pubMax < entry.minCharges then
                    hide = true; reason = string.format("full but pubMax=%d < minCharges=%d", pubMax, entry.minCharges)
                end
            else
                if type(pubMax) == "number" then
                    if entry.minCharges > (pubMax - 1) then
                        hide = true; reason = string.format("recharge active, minCharges=%d > pubMax-1=%d", entry.minCharges, pubMax-1)
                    end
                else
                    hide = true; reason = "recharge active and no public count → safe-hide"
                end
            end
        end
    end
    if not ns.IsEntryAllowedForCurrentSpec(entry) then hide = true; reason = "spec filter" end
    if not ns.IsEntryAllowedForRequiredTalent(entry) then hide = true; reason = "required talent not selected" end
    if not entry.enabled then hide = true; reason = "entry disabled" end
    print(string.format("  |cffffcc00display gate:|r pubCharges=%s pubMax=%s chargesFull=%s  hidden=%s  reason=%s",
        tostring(pubCharges), tostring(pubMax), tostring(status.chargesFull), tostring(hide), reason or "-"))
end
