local _, ns = ...

-- SimulatedAuras: estado sintetico de auras que el API de Blizzard no expone
-- al addon. Modelo: el user define una lista de hechizos hardcodeados con
-- (spellID, stacks iniciales, duracion). Al castear el hechizo (detectado via
-- UNIT_SPELLCAST_SUCCEEDED) el modulo aplica el estado simulado; cada cast
-- subsecuente consume 1 stack. Cuando stacks llegan a 0 o expira la duracion,
-- el estado se borra.
--
-- Caso tipico: hechizos con auras "fully restricted" donde GetAura* retorna nil
-- en runtime — la unica forma de saber el estado es modelarlo nosotros desde
-- los eventos publicos del cast.
--
-- Override manual: /hnzsim <spellID|nombre> dispara la misma logica press —
-- util cuando UNIT_SPELLCAST_SUCCEEDED tiene quirks (cast cancelado, queueing
-- raro, item-effects que no disparan el event para el spellID esperado).
--
-- GetSimulatedAuraStatus(spellID) devuelve el estado a consumers (AuraMonitor
-- lo consulta como una path mas en GetAuraStatus, asi cursor/ring/pulse lo
-- tratan como cualquier otra aura tracked).

local GetTime = GetTime
local UnitName = UnitName
local C_Spell = C_Spell
local C_Timer = C_Timer

-- ============================================================
-- State
-- ============================================================
-- simulatedState[spellID] = { stacks=N, appliedAt=time, duration=D, initialStacks=I }
-- Solo state para self ("player"). El consumer en AuraMonitor matchea por unit
-- == "player" solamente — no expandimos a otros units (no tendria sentido sin
-- eventos del cast ajeno).
local simulatedState = {}

-- Ticker que limpia expiradas periodicamente. No es estrictamente necesario
-- (GetSimulatedAuraStatus chequea expiracion en cada lookup) pero ayuda a
-- que MarkAuraDirty se dispare cuando el aura expira sin un cast nuevo —
-- asi el ring se apaga visualmente sin esperar al siguiente frame.
local expirationTicker
local EXPIRATION_CHECK_INTERVAL = 0.25

-- ============================================================
-- Curated presets
-- ============================================================
-- Lista de hechizos conocidos donde el patron "apply + consume by re-press"
-- funciona. Cada preset trae los valores recomendados de stacks/duracion +
-- instrucciones de macro listas para copiar. El user habilita el preset desde
-- el menu y queda agregado a su profile (mutable: puede ajustar stacks/dur).
--
-- Para agregar un preset nuevo: definir aca + traducir su `notes` en los
-- locales si querias verlo localizado. Los nombres de spell se resuelven en
-- runtime via C_Spell.GetSpellInfo asi el icono y label localizado salen
-- automaticamente del cliente del jugador.
local SPELL_PRESETS = {
    {
        spellID = 444995,
        class = "SHAMAN",
        specHint = "Restoration · Totemic Hero Talent",
        initialStacks = 2,
        duration = 24,
        -- Falback label si C_Spell.GetSpellInfo no resuelve (pasa con Hero
        -- Talent spells no aprendidas o data no cacheada todavia).
        fallbackLabel = "Surging Totem",
        -- Icon fileID hardcoded para que la card del preset muestre el icono
        -- correcto incluso si C_Spell.GetSpellInfo no devuelve iconID.
        iconID = 1698701,
        notes = "Surging Totem (Tótem volátil) es un hero talent del chamán cuya aura no es visible al addon vía API. Lo modelamos como 2 cargas que se aplican al castear y se consumen presionando una macro adicional.",
        -- Pasos detallados para configurar el preset end-to-end. Se muestran
        -- en el modal de instrucciones.
        steps = {
            "Hacé clic en 'Habilitar' arriba para activar el preset. Eso agrega Surging Totem (444995) a tu profile con 2 cargas y 24s de duración.",
            "Abrí /macro y creá una macro nueva. Pegá el bloque de macro que aparece abajo (CTRL+C en el cuadro de macro de este modal). Asignala a un keybind cómodo o ubicala en una barra de acción visible.",
            "Abrí Config → Cursor (o Ring / Pulse) → Auras. Agregá el spellID 444995 a la lista de auras trackeadas. Sin esto, el icono no se muestra visualmente aunque el state se siga aplicando internamente.",
            "Castea Surging Totem normalmente desde tu barra de acción / spellbook. UNIT_SPELLCAST_SUCCEEDED dispara automáticamente y aplica las 2 cargas — vas a ver el icono con el contador '2' encima.",
            "Cada vez que querás consumir una carga (por ejemplo, cuando uses una habilidad que se beneficia del totem), presioná la macro. El contador baja: 2 → 1 → icono se apaga.",
            "Si pasan 24 segundos sin que consumas todas las cargas, el state expira y el icono se apaga automáticamente.",
        },
        -- Macro recomendada: solo el slash command. El cast del totem se hace
        -- por separado (action bar / otra macro). Cada press de ESTA macro
        -- consume 1 carga del state simulado.
        macroLines = {
            "#showtooltip",
            "/hnzsim 444995",
        },
    },
}

-- IsActive necesita estar declarada antes que cualquier funcion publica que la
-- use (GetSimulatedAuraRuntimeState la consulta para gatear el return). Si
-- queda definida mas abajo en el archivo, las funciones publicas la capturan
-- como global = nil y crashea con "attempt to call a nil value".
local function IsActive(st)
    if not st then return false end
    if (st.stacks or 0) <= 0 then return false end
    if st.duration and st.duration > 0 then
        if (st.appliedAt + st.duration) <= GetTime() then return false end
    end
    return true
end

function ns:GetSimulatedAuraPresets()
    return SPELL_PRESETS
end

-- Devuelve el iconID hardcoded del preset si existe, sino nil. Lo usa
-- GetAuraStatus para inyectar result.icon cuando el cliente no resuelve
-- C_Spell.GetSpellInfo(spellID).iconID (Hero Talent spells sin learn).
function ns:GetSimulatedAuraIconID(spellID)
    if not spellID then return nil end
    for _, p in ipairs(SPELL_PRESETS) do
        if p.spellID == spellID then return p.iconID end
    end
    return nil
end

-- Devuelve el preset por spellID (o nil). Util para que la Config UI muestre
-- cards solo de presets que matcheen la clase del player.
function ns:GetSimulatedAuraPreset(spellID)
    if not spellID then return nil end
    for _, p in ipairs(SPELL_PRESETS) do
        if p.spellID == spellID then return p end
    end
    return nil
end

-- Devuelve el state runtime para inspeccion (UI). nil si no hay state.
function ns:GetSimulatedAuraRuntimeState(spellID)
    if not spellID then return nil end
    local st = simulatedState[spellID]
    if not IsActive(st) then return nil end
    return st
end

-- Trigger publico del press (mismo path que UNIT_SPELLCAST_SUCCEEDED y /hnzsim).
-- Usado por el boton "Probar" de la Config UI para validar el state machine.
-- PressSpell esta definida abajo pero asignamos esta wrapper despues; aca solo
-- declaramos el slot publico — la implementacion real se setea cuando PressSpell
-- existe (al final del file no funciona porque ns:Foo se evalua a parse time,
-- entonces forward-declaramos con un placeholder y lo sobreescribimos abajo).
function ns:TriggerSimulatedAuraPress(spellID)
    -- placeholder — la version real se asigna luego de que PressSpell exista
end

-- ============================================================
-- Config lookup
-- ============================================================
local function GetConfig()
    return ns.db and ns.db.simulatedAuras
end

local function GetEntries()
    local s = GetConfig()
    return (s and s.entries) or nil
end

-- Build a fast lookup spellID -> entry (rebuild en cada cambio del array).
-- Lazy-rebuild via dirty flag; los callers de press son hot-path durante peleas.
local _entriesByID = nil
local _entriesDirty = true

local function MarkEntriesDirty()
    _entriesDirty = true
end
ns.MarkSimulatedAurasDirty = MarkEntriesDirty

local function GetEntriesByID()
    if _entriesDirty then
        _entriesByID = {}
        local list = GetEntries()
        if list then
            for _, e in ipairs(list) do
                if type(e) == "table" and tonumber(e.spellID) then
                    _entriesByID[tonumber(e.spellID)] = e
                end
            end
        end
        _entriesDirty = false
    end
    return _entriesByID
end

-- ============================================================
-- State machine (IsActive declarada arriba para precedencia)
-- ============================================================
local function PressSpell(spellID)
    if not spellID then return end
    local entry = GetEntriesByID()[spellID]
    if not entry then return end
    local initial = tonumber(entry.initialStacks) or 1
    local duration = tonumber(entry.duration) or 0
    local st = simulatedState[spellID]
    if not IsActive(st) then
        -- First press: apply
        simulatedState[spellID] = {
            stacks = initial,
            initialStacks = initial,
            appliedAt = GetTime(),
            duration = duration,
        }
    else
        -- Subsequent press: consume 1 stack
        st.stacks = (st.stacks or 1) - 1
        if st.stacks <= 0 then
            simulatedState[spellID] = nil
        end
    end
    if ns.MarkAuraDirty then ns:MarkAuraDirty() end
end

-- Re-asignamos el wrapper publico ahora que PressSpell existe (la version
-- arriba era un placeholder porque ns:Foo se evalua a parse time).
function ns:TriggerSimulatedAuraPress(spellID)
    PressSpell(spellID)
end

-- ============================================================
-- Public API: query
-- ============================================================
-- Devuelve nil si no hay state activo para spellID. Si activo, devuelve
-- { stacks, duration, remaining, expirationTime, appliedAt }. AuraMonitor
-- usa esto como una path mas en GetAuraStatus (sintetiza el ACTIVE result).
function ns:GetSimulatedAuraStatus(spellID)
    local st = simulatedState[spellID]
    if not IsActive(st) then
        if st then simulatedState[spellID] = nil end -- evict expired
        return nil
    end
    local out = {
        stacks = st.stacks,
        duration = st.duration or 0,
        appliedAt = st.appliedAt,
    }
    if st.duration and st.duration > 0 then
        out.expirationTime = st.appliedAt + st.duration
        out.remaining = out.expirationTime - GetTime()
        if out.remaining < 0 then out.remaining = 0 end
    end
    return out
end

-- Set para que AuraMonitor / Config UI sepan si un spellID esta configurado
-- como simulado (skipea otras paths de deteccion / decora el badge).
function ns:IsSimulatedAura(spellID)
    if not spellID then return false end
    return GetEntriesByID()[spellID] ~= nil
end

-- ============================================================
-- Public API: mutation (used by Config UI)
-- ============================================================
function ns:AddSimulatedAura(input, initialStacks, duration)
    local s = GetConfig()
    if not s then return false, "db not ready" end
    s.entries = s.entries or {}
    local spellID, name
    if ns.GetSpellIDFromInput then
        spellID, name = ns.GetSpellIDFromInput(input)
    else
        spellID = tonumber(input)
    end
    if not spellID then
        return false, (ns.L and ns.L["Unknown spell — check the ID or name."]) or "Unknown spell — check the ID or name."
    end
    for _, e in ipairs(s.entries) do
        if tonumber(e.spellID) == spellID then
            return false, (ns.L and ns.L["Spell already tracked."]) or "Spell already tracked."
        end
    end
    local resolvedName = name
    if not resolvedName and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        resolvedName = info and info.name
    end
    table.insert(s.entries, {
        spellID = spellID,
        label = resolvedName or tostring(spellID),
        initialStacks = tonumber(initialStacks) or 2,
        duration = tonumber(duration) or 15,
    })
    MarkEntriesDirty()
    return true, spellID, resolvedName
end

function ns:RemoveSimulatedAura(spellID)
    if not spellID then return false end
    local s = GetConfig()
    if not s or not s.entries then return false end
    for i, e in ipairs(s.entries) do
        if tonumber(e.spellID) == spellID then
            table.remove(s.entries, i)
            simulatedState[spellID] = nil
            MarkEntriesDirty()
            return true
        end
    end
    return false
end

function ns:UpdateSimulatedAura(spellID, field, value)
    if not spellID or not field then return false end
    local s = GetConfig()
    if not s or not s.entries then return false end
    for _, e in ipairs(s.entries) do
        if tonumber(e.spellID) == spellID then
            e[field] = value
            -- Re-evaluate active state with new params si esta activo y bumpea
            -- el initial o la duracion en runtime. Mantenemos appliedAt para
            -- no resetear el clock.
            if (field == "initialStacks" or field == "duration") and simulatedState[spellID] then
                if field == "initialStacks" then
                    simulatedState[spellID].initialStacks = tonumber(value) or 1
                else
                    simulatedState[spellID].duration = tonumber(value) or 0
                end
            end
            MarkEntriesDirty()
            return true
        end
    end
    return false
end

function ns:GetSimulatedAuras()
    return GetEntries() or {}
end

-- Enable a preset by spellID: agrega la entry con los defaults del preset si
-- no estaba ya. Devuelve true si se agrego, false si ya estaba habilitado o
-- el preset no existe.
function ns:EnableSimulatedAuraPreset(spellID)
    if not spellID then return false end
    if GetEntriesByID()[spellID] then return false end
    local preset
    for _, p in ipairs(SPELL_PRESETS) do
        if p.spellID == spellID then preset = p; break end
    end
    if not preset then return false end
    local s = GetConfig()
    if not s then return false end
    s.entries = s.entries or {}
    local label = preset.fallbackLabel
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(preset.spellID)
        if info and info.name then label = info.name end
    end
    table.insert(s.entries, {
        spellID = preset.spellID,
        label = label or tostring(preset.spellID),
        initialStacks = preset.initialStacks,
        duration = preset.duration,
    })
    MarkEntriesDirty()
    return true
end

-- Devuelve true si el preset esta en el profile del user (no chequea si esta
-- actualmente activo en runtime, solo habilitado en la lista).
function ns:IsSimulatedAuraPresetEnabled(spellID)
    if not spellID then return false end
    return GetEntriesByID()[spellID] ~= nil
end

-- Force reset state for a spell (used by Config "reset" button + slash command)
function ns:ResetSimulatedAuraState(spellID)
    if spellID then
        simulatedState[spellID] = nil
    else
        simulatedState = {}
    end
    if ns.MarkAuraDirty then ns:MarkAuraDirty() end
end

-- ============================================================
-- Slash command
-- ============================================================
-- /hnzsim <spellID|name>            press (apply or consume)
-- /hnzsim reset [spellID|name]      reset active state
-- /hnzsim list                      print configured entries
local function ParseSlash(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then return nil, nil end
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    return cmd, (rest ~= "" and rest or nil)
end

local function HandleSlash(msg)
    local cmd, arg = ParseSlash(msg)
    if not cmd then
        print("|cff00ccffHNZSim|r usage: /hnzsim <spellID|name>  |  /hnzsim reset [spellID|name]  |  /hnzsim list")
        return
    end

    if cmd == "list" then
        local entries = GetEntries() or {}
        if #entries == 0 then
            print("|cff00ccffHNZSim|r " .. ((ns.L and ns.L["No simulated auras configured."]) or "No simulated auras configured."))
            return
        end
        print("|cff00ccffHNZSim|r " .. ((ns.L and ns.L["Configured simulated auras:"]) or "Configured simulated auras:"))
        for _, e in ipairs(entries) do
            local st = simulatedState[tonumber(e.spellID)]
            local active = IsActive(st) and (" |cff66ff66[active "..(st.stacks or 0).."]|r") or ""
            print(string.format("  %s (id=%d) stacks=%d dur=%ds%s",
                tostring(e.label or "?"), tonumber(e.spellID) or 0,
                tonumber(e.initialStacks) or 0, tonumber(e.duration) or 0, active))
        end
        return
    end

    if cmd == "debug" then
        local sid
        if arg then
            sid = tonumber(arg)
            if not sid and ns.GetSpellIDFromInput then sid = ns.GetSpellIDFromInput(arg) end
        end
        if not sid then
            print("|cff00ccffHNZSim debug|r usage: /hnzsim debug <spellID|name>")
            return
        end
        print(string.format("|cff00ccffHNZSim debug|r ===== spellID %d =====", sid))
        -- Profile entry
        local cfgEntry = GetEntriesByID()[sid]
        if cfgEntry then
            print(string.format("  config: stacks=%d, duration=%ds, label=%s",
                tonumber(cfgEntry.initialStacks) or 0,
                tonumber(cfgEntry.duration) or 0,
                tostring(cfgEntry.label)))
        else
            print("  |cffff8800config: NOT in profile|r — preset no habilitado")
        end
        -- Runtime state
        local st = simulatedState[sid]
        if st then
            local age = GetTime() - (st.appliedAt or 0)
            local rem = (st.duration and st.duration > 0) and ((st.appliedAt + st.duration) - GetTime()) or -1
            print(string.format("  runtime: stacks=%d/%d  age=%.1fs  remaining=%.1fs  active=%s",
                st.stacks or 0, st.initialStacks or 0, age, rem, tostring(IsActive(st))))
        else
            print("  |cff888888runtime: no state (nunca se aplico o ya expiro)|r")
        end
        -- GetAuraStatus result
        if ns.GetAuraStatus then
            local result = ns:GetAuraStatus(sid, "player")
            print(string.format("  GetAuraStatus: status=%s stacks=%s duration=%s remaining=%.1f isSimulated=%s icon=%s",
                tostring(result.status), tostring(result.stacks),
                tostring(result.duration), tonumber(result.remaining) or 0,
                tostring(result.isSimulated), tostring(result.icon)))
        end
        -- Preset existence
        for _, p in ipairs(SPELL_PRESETS) do
            if p.spellID == sid then
                print(string.format("  preset: class=%s, iconID=%s, initialStacks=%d, duration=%d",
                    tostring(p.class), tostring(p.iconID),
                    p.initialStacks, p.duration))
                break
            end
        end
        return
    end

    if cmd == "reset" then
        if arg then
            local sid = tonumber(arg)
            if not sid and ns.GetSpellIDFromInput then
                sid = ns.GetSpellIDFromInput(arg)
            end
            if sid then
                ns:ResetSimulatedAuraState(sid)
                print(string.format("|cff00ccffHNZSim|r reset %d", sid))
            else
                print("|cffff8800HNZSim|r unknown: "..tostring(arg))
            end
        else
            ns:ResetSimulatedAuraState(nil)
            print("|cff00ccffHNZSim|r reset all")
        end
        return
    end

    -- Treat the whole msg as a spell identifier (id or name) and press.
    local sid = tonumber(msg)
    local name
    if not sid and ns.GetSpellIDFromInput then
        sid, name = ns.GetSpellIDFromInput(msg)
    end
    if not sid then
        print("|cffff8800HNZSim|r unknown spell: "..tostring(msg))
        return
    end
    if not GetEntriesByID()[sid] then
        print(string.format("|cffff8800HNZSim|r spellID %d (%s) not configured — agrega en Config", sid, name or "?"))
        return
    end
    PressSpell(sid)
end

-- ============================================================
-- Init + events
-- ============================================================
function ns:InitSimulatedAuras()
    MarkEntriesDirty() -- force rebuild after profile load

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    ev:SetScript("OnEvent", function(_, event, unit, _, spellID)
        if event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end
        if unit ~= "player" then return end
        if not spellID then return end
        if not GetEntriesByID()[spellID] then return end
        local s = GetConfig()
        if not s or s.enabled == false then return end
        PressSpell(spellID)
    end)

    -- Expiration ticker: barrido periodico para apagar el ring cuando un aura
    -- expira por duration (sin un cast nuevo que dispare MarkAuraDirty).
    if not expirationTicker then
        expirationTicker = C_Timer.NewTicker(EXPIRATION_CHECK_INTERVAL, function()
            local anyExpired = false
            local now = GetTime()
            for sid, st in pairs(simulatedState) do
                if st.duration and st.duration > 0 and (st.appliedAt + st.duration) <= now then
                    simulatedState[sid] = nil
                    anyExpired = true
                end
            end
            if anyExpired and ns.MarkAuraDirty then ns:MarkAuraDirty() end
        end)
    end

    SLASH_HNZSIM1 = "/hnzsim"
    SlashCmdList["HNZSIM"] = HandleSlash
end

function ns:RefreshSimulatedAuras()
    MarkEntriesDirty()
    if ns.MarkAuraDirty then ns:MarkAuraDirty() end
end
