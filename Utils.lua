local _, ns = ...

function ns.DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = ns.DeepCopy(v)
    end
    return copy
end

function ns.MergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            target[k] = ns.DeepCopy(v)
        elseif type(v) == "table" and type(target[k]) == "table" then
            ns.MergeDefaults(target[k], v)
        end
    end
end

-- Predicado del gate de visibilidad: "always" | "combat" | "ooc". Reemplazo del
-- legacy `showOnlyInCombat and not inCombat` que estaba inline en cada modulo.
-- Cada caller pasa su propia cache de inCombat (los modulos la mantienen via
-- PLAYER_REGEN_*) para evitar el costo de InCombatLockdown por frame.
function ns.MatchesVisibility(vis, inCombat)
    if vis == "combat" then return inCombat and true or false end
    if vis == "ooc" then return not inCombat end
    return true
end

function ns.FormatDuration(seconds)
    if type(seconds) ~= "number" or seconds <= 0 then return "" end
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
    end
    return string.format("%.0f", seconds)
end

-- True only if the value is a regular public number on which arithmetic/comparisons won't throw.
-- The canary `n > 0` triggers WoW's "secret number value" error when n is a SecureNumber, so we
-- pcall it instead of relying on issecretvalue (which has different names across patches).
local function _gtZero(n) return n > 0 end
local function IsPublicNumber(n)
    if type(n) ~= "number" then return false end
    return (pcall(_gtZero, n))
end

-- Convert any value (incl. SecureNumber) to a safe public number, or nil.
-- NOTE: tostring(SecureNumber) returns a "secret string" that cannot be indexed/parsed,
-- so we cannot fall back to tonumber(tostring(v)) — it taints execution. SNs that the
-- API doesn't convert are simply unrecoverable here; callers must use a different signal.
function ns.ToPublic(v)
    if v == nil then return nil end
    if IsPublicNumber(v) then return v end
    local toPublicFn = rawget(_G, "ToPublicNumber")
    if type(toPublicFn) == "function" then
        local ok, val = pcall(toPublicFn, v)
        if ok and IsPublicNumber(val) then return val end
    end
    return nil
end

ns.IsPublicNumber = IsPublicNumber

-- Create an invisible Cooldown frame for SecureNumber → public conversion
function ns.CreateProbe()
    local cd = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
    cd:SetSize(1, 1)
    cd:SetDrawSwipe(false)
    cd:SetDrawEdge(false)
    cd:SetDrawBling(false)
    cd:SetHideCountdownNumbers(true)
    cd:SetAlpha(0)
    cd:ClearAllPoints()
    cd:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    return cd
end

-- Apply duration object to a probe frame and read remaining seconds.
-- Returns: isActive (boolean), remainingSeconds (public number or nil), durationSeconds (public number or nil)
-- The third return is needed in combat where auraData.duration arrives as a SecureNumber:
-- the probe round-trip recovers it as a public number, so callers can compute progress = rem/dur.
function ns.ProbeDurationObject(probe, durationObj)
    if not probe or not durationObj then return false, nil, nil end
    if type(probe.SetCooldownFromDurationObject) ~= "function" then return false, nil, nil end
    local okSet = pcall(probe.SetCooldownFromDurationObject, probe, durationObj)
    if not okSet then return false, nil, nil end
    local okShown, shown = pcall(probe.IsShown, probe)
    if not okShown or not shown then return false, 0, nil end
    local okTimes, startMs, durationMs = pcall(probe.GetCooldownTimes, probe)
    if okTimes then
        startMs = ns.ToPublic(startMs)
        durationMs = ns.ToPublic(durationMs)
        if type(startMs) == "number" and type(durationMs) == "number" and startMs > 0 and durationMs > 0 then
            local duration = durationMs / 1000
            local remaining = ((startMs + durationMs) / 1000) - GetTime()
            if remaining > 0 then return true, remaining, duration end
            return true, 0, duration
        end
    end
    return true, nil, nil
end

function ns.GetCurrentSpecID()
    local idx = GetSpecialization and GetSpecialization() or nil
    if not idx then return nil end
    local id = GetSpecializationInfo and GetSpecializationInfo(idx) or nil
    return id
end

function ns.GetClassSpecs()
    local _, _, classID = UnitClass("player")
    if not classID or not GetNumSpecializationsForClassID then return {} end
    local out = {}
    for i = 1, GetNumSpecializationsForClassID(classID) do
        local id, name = GetSpecializationInfoForClassID(classID, i)
        if id then table.insert(out, {id=id, name=name}) end
    end
    return out
end

function ns.IsEntryAllowedForCurrentSpec(entry)
    if not entry.specs or #entry.specs == 0 then return true end
    local cur = ns.GetCurrentSpecID()
    if not cur then return true end
    for _, id in ipairs(entry.specs) do
        if id == cur then return true end
    end
    return false
end

-- Gate: hide entry when a required talent is not currently selected.
-- IsPlayerSpell returns true only for spells the player currently knows, which
-- includes spells granted by talents in the active loadout.
function ns.IsEntryAllowedForRequiredTalent(entry)
    local req = entry.requiredTalentSpellID
    if not req or req == 0 then return true end
    if IsPlayerSpell and IsPlayerSpell(req) then return true end
    return false
end

-- Enumerate every spell reachable from the player's active talent loadout
-- (class tree, spec tree, hero subtrees). Returns a list of {spellID, name, icon, tree}
-- sorted alphabetically by name. Each spellID appears once even if it has
-- multiple ranks. Tree is a short stable English key: "Class", "Spec", "Hero" —
-- callers translate at display time via ns.L[tree].
function ns.GetClassTalents()
    local out = {}
    if not (C_ClassTalents and C_Traits) then return out end
    local configID = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    if not configID then return out end
    local configInfo = C_Traits.GetConfigInfo(configID)
    if not configInfo or not configInfo.treeIDs then return out end

    local seen = {}

    local function CollectFromNode(nodeID, treeLabel)
        local node = C_Traits.GetNodeInfo(configID, nodeID)
        if not node or not node.entryIDs then return end
        local label = treeLabel
        if node.subTreeID and node.subTreeID ~= 0 then label = "Hero" end
        for _, entryID in ipairs(node.entryIDs) do
            local te = C_Traits.GetEntryInfo(configID, entryID)
            if te and te.definitionID then
                local def = C_Traits.GetDefinitionInfo(te.definitionID)
                local sid = def and def.spellID
                if sid and not seen[sid] then
                    local info = C_Spell.GetSpellInfo(sid)
                    if info and info.name then
                        seen[sid] = true
                        table.insert(out, {spellID=sid, name=info.name, icon=info.iconID or 134400, tree=label})
                    end
                end
            end
        end
    end

    for treeIdx, treeID in ipairs(configInfo.treeIDs) do
        local treeLabel = (treeIdx == 1) and "Class" or "Spec"
        local nodes = C_Traits.GetTreeNodes(treeID)
        if nodes then
            for _, nodeID in ipairs(nodes) do CollectFromNode(nodeID, treeLabel) end
        end
    end

    table.sort(out, function(a, b)
        if a.tree ~= b.tree then
            local order = {["Class"]=1, ["Spec"]=2, ["Hero"]=3}
            return (order[a.tree] or 99) < (order[b.tree] or 99)
        end
        return a.name < b.name
    end)
    return out
end

-- Enumerate spells available to the player: spellbook lines (general + active spec),
-- pet spellbook, plus talent-granted spells. Returns {spellID, name, icon, source}
-- sorted alphabetically; each spellID appears once.
function ns.GetPlayerSpells()
    local out = {}
    local seen = {}

    local function Add(sid, source)
        if not sid or seen[sid] then return end
        local info = C_Spell.GetSpellInfo(sid)
        if info and info.name then
            seen[sid] = true
            -- lowerName precomputado para que el autocomplete no recompute en cada keystroke
            table.insert(out, {spellID=info.spellID, name=info.name, lowerName=info.name:lower(), icon=info.iconID or 134400, source=source or ""})
        end
    end

    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        local n = C_SpellBook.GetNumSpellBookSkillLines() or 0
        for li = 1, n do
            local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(li)
            if lineInfo and not lineInfo.shouldHide and lineInfo.numSpellBookItems then
                local label = lineInfo.name or ""
                for i = 1, lineInfo.numSpellBookItems do
                    local idx = (lineInfo.itemIndexOffset or 0) + i
                    local item = C_SpellBook.GetSpellBookItemInfo(idx, Enum.SpellBookSpellBank.Player)
                    if item and item.itemType == Enum.SpellBookItemType.Spell and item.spellID then
                        Add(item.spellID, label)
                    end
                end
            end
        end
    end

    if C_SpellBook and C_SpellBook.HasPetSpells then
        local petCount = C_SpellBook.HasPetSpells()
        if petCount and petCount > 0 then
            for i = 1, petCount do
                local item = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Pet)
                if item and item.itemType == Enum.SpellBookItemType.Spell and item.spellID then
                    Add(item.spellID, "Pet")
                end
            end
        end
    end

    if ns.GetClassTalents then
        for _, t in ipairs(ns.GetClassTalents()) do
            Add(t.spellID, t.tree)
        end
    end

    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function ns.FindSpellEntry(list, spellID)
    for i, entry in ipairs(list) do
        if entry.spellID == spellID then return i, entry end
    end
    return nil
end

function ns.RemoveSpellEntry(list, spellID)
    local idx = ns.FindSpellEntry(list, spellID)
    if idx then table.remove(list, idx); return true end
    return false
end

-- Devuelve (name, iconID) para un spellID, con fallback robusto. Si GetSpellInfo
-- devuelve un info con iconID = 0 (pasa con spells/auras que el jugador no conoce
-- o que aún no se han cargado), reintentamos con C_Spell.GetSpellTexture (más
-- directo) antes de caer al question-mark default. Sin este fallback, los rows
-- pintan un cuadrado verde porque SetTexture(0) deja la textura sin contenido.
function ns.GetSpellDisplayInfo(spellID)
    if not spellID then return tostring(spellID), 134400 end
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    local name = info and info.name
    local icon = info and info.iconID
    if (not icon or icon == 0) and C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex and tex ~= 0 then icon = tex end
    end
    if not icon or icon == 0 then icon = 134400 end
    return name or tostring(spellID), icon
end

-- Devuelve el spellID que el usuario seleccionó del autocomplete (si está
-- vigente y el texto del editbox no se ha editado), o el resultado de
-- GetSpellIDFromInput sobre el texto. El path de ID directo evita
-- C_Spell.GetSpellInfo(name) — que falla con spells no conocidos del jugador.
function ns.GetResolvedSpellID(eb)
    if not eb then return nil end
    local txt = (eb:GetText() or ""):trim()
    if txt == "" then return nil end
    if eb._satResolvedID and eb._satResolvedName == txt then
        return eb._satResolvedID, eb._satResolvedName
    end
    return ns.GetSpellIDFromInput(txt)
end

function ns.GetSpellIDFromInput(input)
    if not input or input == "" then return nil end
    local id = tonumber(input)
    if id then
        local info = C_Spell.GetSpellInfo(id)
        if info then return info.spellID, info.name, info.iconID end
        return nil
    end
    local info = C_Spell.GetSpellInfo(input)
    if info then return info.spellID, info.name, info.iconID end
    return nil
end

-- ============================================================
-- Serialize / Deserialize for profile import/export
-- ============================================================

function ns.Serialize(tbl)
    local function ser(v)
        local t = type(v)
        if t == "string" then return string.format("%q", v)
        elseif t == "number" then return tostring(v)
        elseif t == "boolean" then return v and "true" or "false"
        elseif t == "table" then
            local parts = {}
            -- Array part
            local n = #v
            for i = 1, n do
                table.insert(parts, ser(v[i]))
            end
            -- Hash part
            for k, val in pairs(v) do
                if type(k) == "string" then
                    table.insert(parts, "[" .. string.format("%q", k) .. "]=" .. ser(val))
                elseif type(k) == "number" and (k < 1 or k > n or k ~= math.floor(k)) then
                    table.insert(parts, "[" .. k .. "]=" .. ser(val))
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
        return "nil"
    end
    return ser(tbl)
end

function ns.Deserialize(str)
    if not str or str == "" then return nil end
    -- Only allow table constructors, strings, numbers, booleans
    local sanitized = str:match("^%s*(%{.+%})%s*$")
    if not sanitized then return nil end
    local func = loadstring("return " .. sanitized)
    if not func then return nil end
    setfenv(func, {}) -- empty environment for safety
    local ok, result = pcall(func)
    if ok and type(result) == "table" then return result end
    return nil
end

-- ============================================================
-- Reproducir el sonido configurado en una entry de aura.
-- Acepta: número (kit ID), o nombre LSM (string). Cae a 8959 si no es válido.
-- ============================================================

-- Canales validos de PlaySound/PlaySoundFile en WoW
ns.SOUND_CHANNELS = { "Master", "SFX", "Music", "Ambience", "Dialog" }

function ns.PlayAuraSound(value, channel)
    if not value or value == "" or value == "None" then return end
    channel = channel or "Master"
    if type(value) == "number" then
        pcall(PlaySound, value, channel)
        return
    end
    if value == "Default" then
        pcall(PlaySound, 8959, channel)
        return
    end
    -- Try LibSharedMedia-3.0 (la mayoría de addons populares la traen embebida).
    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if lsm then
        local data = lsm:Fetch("sound", value)
        if data and data ~= "" then
            if type(data) == "number" then
                pcall(PlaySound, data, channel)
            else
                pcall(PlaySoundFile, data, channel)
            end
            return
        end
    end
    -- Fallback: lookup en la lista corta de SAT (label → kit ID)
    if ns.SOUND_OPTIONS then
        for _, opt in ipairs(ns.SOUND_OPTIONS) do
            if opt.label == value then pcall(PlaySound, opt.value, channel); return end
        end
    end
    -- Último recurso
    pcall(PlaySound, 8959, channel)
end
