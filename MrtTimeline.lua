local addonName, ns = ...

-- ============================================================
-- MRT / NSRT Timeline Reminders
--
-- Lista de notas por-encuentro en savedvars (ns.db.mrtTimeline.notes). Cada
-- nota tiene { id = encounterID, name = label, text = cadena pegada }. id=0
-- es comodin: aplica a cualquier encuentro si no hay match por ID exacto.
--
-- En ENCOUNTER_START(encounterID) buscamos la nota con ese id (sino fallback
-- a id=0), parseamos las lineas, y arrancamos el timer. Mientras pasa el
-- tiempo cada entry pasa por 3 estados visuales:
--
--   1. HIDDEN     (now < trigger - leadTime)        — no se renderiza
--   2. PRE        (trigger - leadTime <= now < trigger) — icono dim + countdown
--   3. ACTIVE     (now >= trigger, no consumido, dentro de activeWindow) — icono saturado
--   4. consumido/expirado → vuelve a HIDDEN
--
-- "Consumido" = el player casteo el spellID despues de que la entry triggereo
-- (UNIT_SPELLCAST_SUCCEEDED). "Expirado" = paso activeWindow segundos desde
-- el trigger sin que el player castee.
--
-- Soporta dos formatos en el parser: MRT (con {time:M:SS.t}{spell:N}) y NSRT
-- (con key:value;... y header EncounterID:N que se usa para auto-asociar la
-- nota a un encuentro).
-- ============================================================

local frame              -- container anchored al cursor que hostea los iconos
local iconPool = {}      -- pool de { frame=, tex=, countdown= }
local entries = {}       -- entries de la nota activa con runtime state
local activeEncounterID  -- id del encuentro actual (o test); nil si no hay
local encounterStart     -- GetTime() del pull (o nil)
local inEncounter = false
local isTestEncounter = false  -- true cuando StartEncounter vino de MrtTimelineTest

local function GetCfg() return ns.db and ns.db.mrtTimeline end

local function GetSpellTexture(spellID)
    if not spellID then return 134400 end
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex and tex ~= 0 then return tex end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.iconID and info.iconID ~= 0 then return info.iconID end
    end
    return 134400
end

-- ============================================================
-- Parser
-- ============================================================

local function ParseMrtLine(line, me)
    -- Lua patterns no soportan `?`; intentamos primero la variante con decimal,
    -- si no matchea, fallback sin decimal.
    local sign, mm, ss, frac = line:match("{time:(%-?)(%d+):(%d+)%.(%d+)}")
    if not mm then
        sign, mm, ss = line:match("{time:(%-?)(%d+):(%d+)}")
        frac = nil
    end
    if not mm then return nil end

    local spellStr = line:match("{spell:(%d+)}")
    if not spellStr then return nil end

    local seconds = tonumber(mm) * 60 + tonumber(ss)
    if frac then seconds = seconds + tonumber("0." .. frac) end
    if sign == "-" then seconds = -seconds end

    -- Filtro de jugador: {p:Name} explicito O nombre en texto plano entre
    -- {time:...} y {spell:...} (MRT moderno: "- Nombre"). Sin filtro = publico.
    local hasFilter, matched = false, false
    for pname in line:gmatch("{p:([^}]+)}") do
        hasFilter = true
        if pname == me then matched = true end
    end
    if not hasFilter then
        local mid = line:match("{time:[^}]+}(.-){spell:")
        if mid then
            local name = mid:gsub("^[%s%-]+", ""):gsub("[%s%-]+$", "")
            if name ~= "" then
                hasFilter = true
                if name == me then matched = true end
            end
        end
    end
    if hasFilter and not matched then return nil end
    return { time = seconds, spellID = tonumber(spellStr), line = line }
end

local function ParseNsrtLine(line, me)
    local timeStr = line:match("time:([%d%.]+)")
    local spellStr = line:match("spellid:(%d+)")
    if not (timeStr and spellStr) then return nil end
    local tag = line:match("tag:([^;]+)")
    if tag then tag = tag:gsub("^%s+", ""):gsub("%s+$", "") end
    if tag and tag ~= "" and tag ~= me then return nil end
    return { time = tonumber(timeStr), spellID = tonumber(spellStr), line = line }
end

local function ParseLine(line, me)
    if line:find("{time:", 1, true) then
        return ParseMrtLine(line, me)
    elseif line:find("time:", 1, true) and line:find("spellid:", 1, true) then
        return ParseNsrtLine(line, me)
    end
    return nil
end

local function ParseNote(text)
    local out = {}
    if not text or text == "" then return out end
    local me = UnitName("player")
    for line in text:gmatch("[^\r\n]+") do
        local e = ParseLine(line, me)
        if e and e.time and e.spellID then table.insert(out, e) end
    end
    table.sort(out, function(a, b) return a.time < b.time end)
    return out
end
ns.MrtParseNote = ParseNote

-- Para autocompletar el encounterID/nombre cuando el usuario pega una nota NSRT.
function ns.MrtParseEncounterID(text)
    if not text or text == "" then return nil end
    return tonumber(text:match("EncounterID:(%d+)"))
end

function ns.MrtParseEncounterName(text)
    if not text or text == "" then return nil end
    local n = text:match("Name:([^;\r\n]+)")
    if n then return n:gsub("^%s+", ""):gsub("%s+$", "") end
    return nil
end

-- ============================================================
-- Encounter Journal index
-- ============================================================
-- Build flat list of all encounters across tiers (raids + dungeons) por el EJ.
-- Cached al primer uso. Side effect: EJ_SelectTier/SelectInstance cambian el
-- estado del Encounter Journal — si el usuario lo tiene abierto puede ver
-- "jumps" momentaneos. Restauramos el tier previo al terminar para minimizar.

local encounterIndex

function ns.GetEncounterIndex()
    if encounterIndex then return encounterIndex end
    encounterIndex = {}
    if not _G.EJ_GetNumTiers then return encounterIndex end
    local prevTier = _G.EJ_GetCurrentTier and _G.EJ_GetCurrentTier()

    local function scanInstance(instanceID, instanceName)
        local idx = 1
        while true do
            local ok, name, _, encounterID = pcall(_G.EJ_GetEncounterInfoByIndex, idx, instanceID)
            if not ok or not name or not encounterID then break end
            table.insert(encounterIndex, {
                id = encounterID,
                name = name,
                instance = instanceName,
                lowerName = name:lower(),
            })
            idx = idx + 1
        end
    end

    local function scanTier(tier, isRaid)
        if not _G.EJ_SelectTier then return end
        pcall(_G.EJ_SelectTier, tier)
        local idx = 1
        while true do
            local instanceID = _G.EJ_GetInstanceByIndex and _G.EJ_GetInstanceByIndex(idx, isRaid)
            if not instanceID then break end
            local instanceName = "?"
            if _G.EJ_GetInstanceInfo then
                local results = { pcall(_G.EJ_GetInstanceInfo, instanceID) }
                if results[1] and results[2] then instanceName = results[2] end
            end
            scanInstance(instanceID, instanceName)
            idx = idx + 1
        end
    end

    local numTiers = _G.EJ_GetNumTiers()
    for t = 1, numTiers do
        scanTier(t, true)   -- raids
        scanTier(t, false)  -- dungeons
    end
    if prevTier and _G.EJ_SelectTier then pcall(_G.EJ_SelectTier, prevTier) end
    return encounterIndex
end

function ns.SearchEncounters(query, limit)
    limit = limit or 30
    local out = {}
    if not query or query == "" then return out end
    local q = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then return out end
    for _, e in ipairs(ns.GetEncounterIndex()) do
        if e.lowerName:find(q, 1, true) then
            table.insert(out, e)
            if #out >= limit then break end
        end
    end
    return out
end

-- Obtiene info del Encounter Journal para enriquecer la UI: nombre del jefe,
-- nombre de la raid/dungeon y portrait icon. Cualquier API que falle se
-- maneja via pcall; en peor caso devuelve nil y la UI muestra solo el ID.
function ns.GetEncounterDisplay(encounterID)
    if not encounterID or encounterID == 0 then return nil end
    if not _G.EJ_GetEncounterInfo then return nil end
    local ok, name, _, _, _, _, instanceID = pcall(_G.EJ_GetEncounterInfo, encounterID)
    if not ok or not name then return nil end
    local out = { name = name }
    if instanceID and _G.EJ_GetInstanceInfo then
        local ok2, iname, _, _, buttonImage1 = pcall(_G.EJ_GetInstanceInfo, instanceID)
        if ok2 and iname then
            out.raid = iname
            out.raidIcon = buttonImage1
        end
    end
    if _G.EJ_GetCreatureInfo then
        local ok3, _, _, _, _, iconImage = pcall(_G.EJ_GetCreatureInfo, 1, encounterID)
        if ok3 and iconImage and iconImage ~= "" then out.icon = iconImage end
    end
    return out
end

-- ============================================================
-- Note lookup por encuentro
-- ============================================================

local function FindNoteForEncounter(encounterID)
    local cfg = GetCfg()
    if not cfg or not cfg.notes then return nil end
    -- Match exacto primero
    for _, n in ipairs(cfg.notes) do
        if n.id == encounterID and n.text and n.text ~= "" then return n end
    end
    -- Fallback a id=0 (cualquier encuentro)
    for _, n in ipairs(cfg.notes) do
        if n.id == 0 and n.text and n.text ~= "" then return n end
    end
    return nil
end
ns.MrtFindNoteForEncounter = FindNoteForEncounter

function ns.GetMrtEntryCount() return #entries end
function ns.GetMrtActiveEncounterID() return activeEncounterID end

-- ============================================================
-- Render: state machine por entry
-- ============================================================

local function HideAllIcons()
    for _, ic in ipairs(iconPool) do ic.frame:Hide() end
end

-- ============================================================
-- Ring overlay (integracion con Ring module)
--
-- Frame standalone, anclado al mismo offset que RingDisplay para aparecer
-- alrededor del personaje junto a los anillos de auras. Usa segmentos de
-- linea (igual estilo que RingDisplay) para visualizar progreso del countdown
-- durante PRE: el ring se va llenando de 0% (3s antes) a 100% (en el trigger).
-- Probamos antes con CooldownFrame sweep — quedaba estatico, no animaba.
-- ============================================================
local MRT_RING_RADIUS = 70   -- radio del segmented ring; baseRadius+10 = afuera de los aura rings
local MRT_RING_THICKNESS = 6
local MRT_RING_SEGMENTS = 72

local mrtRingFrame, mrtRingIcon, mrtRingCountdown
local mrtRingSegments

local function EnsureMrtRing()
    if mrtRingFrame then return end
    mrtRingFrame = CreateFrame("Frame", "HNZHealingToolsMrtRing", UIParent)
    mrtRingFrame:SetSize(MRT_RING_RADIUS * 2 + MRT_RING_THICKNESS,
                         MRT_RING_RADIUS * 2 + MRT_RING_THICKNESS)
    mrtRingFrame:SetFrameStrata("MEDIUM")
    mrtRingFrame:EnableMouse(false)

    -- Segmentos de linea, mismo patron que RingDisplay (CreateLine en circulo).
    -- Cada uno se muestra/oculta segun SetMrtRingProgress para visualizar el
    -- avance del countdown.
    mrtRingSegments = {}
    for i = 1, MRT_RING_SEGMENTS do
        local a1 = (i - 1) * (2 * math.pi / MRT_RING_SEGMENTS) - (math.pi / 2)
        local a2 = i * (2 * math.pi / MRT_RING_SEGMENTS) - (math.pi / 2)
        local line = mrtRingFrame:CreateLine(nil, "ARTWORK")
        line:SetThickness(MRT_RING_THICKNESS)
        line:SetStartPoint("CENTER", mrtRingFrame, math.cos(a1) * MRT_RING_RADIUS, math.sin(a1) * MRT_RING_RADIUS)
        line:SetEndPoint("CENTER", mrtRingFrame, math.cos(a2) * MRT_RING_RADIUS, math.sin(a2) * MRT_RING_RADIUS)
        line:SetColorTexture(1, 0.82, 0.20, 1)
        mrtRingSegments[i] = line
    end

    mrtRingIcon = mrtRingFrame:CreateTexture(nil, "OVERLAY")
    mrtRingIcon:SetPoint("CENTER")
    mrtRingIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    mrtRingCountdown = mrtRingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    mrtRingCountdown:SetPoint("CENTER")
    mrtRingCountdown:SetTextColor(1, 1, 1, 1)
    mrtRingCountdown:SetShadowColor(0, 0, 0, 1)
    mrtRingCountdown:SetShadowOffset(2, -2)

    mrtRingFrame:Hide()
end

local function PositionMrtRing()
    EnsureMrtRing()
    local rd = ns.db and ns.db.ringDisplay or {}
    mrtRingFrame:ClearAllPoints()
    mrtRingFrame:SetPoint("CENTER", UIParent, "CENTER", rd.offsetX or 0, rd.offsetY or 0)
end

-- progress 0..1 — cuantos segmentos se muestran. Mismo algoritmo que
-- RingDisplay.SetRingProgress: full segments + un segment "parcial" con alpha
-- proporcional para suavizar la transicion.
local function SetMrtRingProgress(progress)
    if not mrtRingSegments then return end
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end
    local n = #mrtRingSegments
    local pos = progress * n
    local full = math.floor(pos)
    local frac = pos - full
    for i = 1, n do
        local line = mrtRingSegments[i]
        if i <= full then
            line:SetShown(true); line:SetAlpha(1)
        elseif i == full + 1 and frac > 0 then
            line:SetShown(true); line:SetAlpha(frac)
        else
            line:SetShown(false)
        end
    end
end

-- Renderiza el ring overlay. PRE = icono dim + countdown numerico + ring
-- llenandose 0->1; ACTIVE = icono saturado, ring lleno (100%), sin countdown.
local function ShowMrtRing(entry, state, remainingCountdown)
    EnsureMrtRing()
    PositionMrtRing()
    local cfg = GetCfg() or {}

    -- Tamaño del icono leido cada frame asi el slider del config se aplica vivo.
    local iconSize = cfg.ringIconSize or 36
    mrtRingIcon:SetSize(iconSize, iconSize)
    mrtRingIcon:SetTexture(GetSpellTexture(entry.spellID))

    if state == "pre" then
        mrtRingIcon:SetDesaturated(true)
        mrtRingIcon:SetVertexColor(0.6, 0.6, 0.6, 1)
        mrtRingCountdown:SetText(tostring(math.max(1, math.ceil(remainingCountdown or 1))))
        mrtRingCountdown:Show()
        -- Progress: 0 al inicio de PRE (remaining=leadTime), 1 al llegar al
        -- trigger (remaining=0). Llamado cada frame para animar suavemente.
        local lead = cfg.leadTime or 3
        if lead > 0 then
            SetMrtRingProgress(1 - ((remainingCountdown or 0) / lead))
        else
            SetMrtRingProgress(1)
        end
    else  -- "active"
        mrtRingIcon:SetDesaturated(false)
        mrtRingIcon:SetVertexColor(1, 1, 1, 1)
        mrtRingCountdown:Hide()
        SetMrtRingProgress(1)  -- ring lleno durante ACTIVE
    end
    mrtRingFrame:Show()
end

local function HideMrtRing()
    if mrtRingFrame then mrtRingFrame:Hide() end
end

local function AcquireIcon()
    for _, ic in ipairs(iconPool) do
        if not ic.frame:IsShown() then return ic end
    end
    local fr = CreateFrame("Frame", nil, frame)
    fr:Hide()
    local tex = fr:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(fr)
    local cd = fr:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    cd:SetPoint("CENTER", fr, "CENTER", 0, 0)
    cd:SetTextColor(1, 1, 1, 1)
    -- Sombra para que el numero se lea sobre el icono dim
    cd:SetShadowColor(0, 0, 0, 1)
    cd:SetShadowOffset(2, -2)
    local ic = { frame = fr, tex = tex, countdown = cd }
    table.insert(iconPool, ic)
    return ic
end

-- Computa el estado visual de una entry en `now`. Devuelve "pre", "active",
-- o nil si no debe mostrarse.
local function EntryState(e, now, cfg)
    if e.consumed then return nil end
    local lead = cfg.leadTime or 3
    local active = cfg.activeWindow or 10
    if now < e.time - lead then return nil end
    if now < e.time then return "pre" end
    if now < e.time + active then return "active" end
    return nil
end

-- Devuelve el spell name (con fallback) para mostrar en pulse.
local function GetSpellNameSafe(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    end
    return "Spell " .. tostring(spellID)
end

-- Render principal: itera entries, computa state actual vs anterior, despacha
-- transiciones a las integraciones (ring/pulse) y dibuja iconos cerca del cursor.
local function UpdateIcons(now, cfg)
    -- Siempre ocultamos primero para que apagar showInCursor mid-encuentro no
    -- deje iconos huerfanos. Si esta on los re-renderizamos abajo.
    HideAllIcons()
    local size = cfg.iconSize or 40
    local spacing = 4
    local visible = 0
    local ringActiveEntry  -- la entry "mas urgente" para mostrar en el ring overlay
    local ringActiveState  -- "pre" o "active" — controla rendering del icono

    for _, e in ipairs(entries) do
        local state = EntryState(e, now, cfg)
        local prev = e._prevState

        -- Transiciones (one-shot):
        if state ~= prev then
            if state == "active" then
                -- ACTIVE_ENTER: integracion con Pulse module + sonido opcional.
                if cfg.showInPulse and ns.ShowPulse then
                    ns:ShowPulse(GetSpellTexture(e.spellID), GetSpellNameSafe(e.spellID),
                        false, nil, nil, true)  -- bypassEnabled=true
                end
                if cfg.soundEnabled and ns.PlayAuraSound then
                    ns.PlayAuraSound(cfg.soundName or "Default", cfg.soundChannel or "Master")
                end
            end
            e._prevState = state
        end

        -- Ring overlay: mismo lifecycle que cursor display (PRE + ACTIVE). Como
        -- `entries` esta ordenado por tiempo asc, la primera en PRE/ACTIVE es la
        -- mas urgente (la mas vieja todavia no consumida) — esa es la que el
        -- jugador deberia castear ahora.
        if (state == "pre" or state == "active") and cfg.showInRing and not ringActiveEntry then
            ringActiveEntry = e
            ringActiveState = state
        end

        -- Cursor icons: stacked horizontally cerca del cursor.
        if state and cfg.showInCursor then
            local ic = AcquireIcon()
            ic.frame:SetSize(size, size)
            ic.tex:SetTexture(GetSpellTexture(e.spellID))
            ic.frame:ClearAllPoints()
            ic.frame:SetPoint("CENTER", frame, "CENTER", visible * (size + spacing), 0)
            if state == "pre" then
                ic.tex:SetDesaturated(true)
                ic.tex:SetVertexColor(0.6, 0.6, 0.6, 1)
                local remaining = math.ceil(e.time - now)
                ic.countdown:SetText(tostring(math.max(1, remaining)))
                ic.countdown:Show()
            else
                ic.tex:SetDesaturated(false)
                ic.tex:SetVertexColor(1, 1, 1, 1)
                ic.countdown:Hide()
            end
            ic.frame:Show()
            visible = visible + 1
        end
    end

    -- Ring overlay: o mostramos la entry mas urgente, o escondemos si no hay nada.
    if cfg.showInRing and ringActiveEntry then
        local remaining = ringActiveEntry.time - now
        ShowMrtRing(ringActiveEntry, ringActiveState or "pre", remaining)
    else
        HideMrtRing()
    end
end

-- ============================================================
-- Encounter lifecycle
-- ============================================================

local function LoadEntriesForEncounter(encounterID)
    local note = FindNoteForEncounter(encounterID)
    if note then
        entries = ParseNote(note.text)
    else
        entries = {}
    end
    -- Reset runtime state (consumed flags) — entries fueron re-parseadas asi
    -- que ya vienen limpias, pero esto es por si en el futuro reusamos.
    for _, e in ipairs(entries) do e.consumed = nil end
end
ns.MrtLoadEntriesForEncounter = LoadEntriesForEncounter

local function StartEncounter(encounterID, fromTest)
    activeEncounterID = encounterID
    encounterStart = GetTime()
    inEncounter = true
    isTestEncounter = fromTest and true or false
    LoadEntriesForEncounter(encounterID)
end

local function EndEncounter()
    activeEncounterID = nil
    encounterStart = nil
    inEncounter = false
    isTestEncounter = false
    HideAllIcons()
    HideMrtRing()
end

-- Cast detection: cuando el player castea un spellID que matchea una entry ya
-- triggereada (en fase active), la marcamos consumida -> desaparece del HUD.
local function OnSpellCast(spellID)
    if not inEncounter or not encounterStart or not spellID then return end
    local now = GetTime() - encounterStart
    for _, e in ipairs(entries) do
        if e.spellID == spellID and not e.consumed and now >= e.time then
            e.consumed = true
            return
        end
    end
end

function ns:InitMrtTimeline()
    frame = CreateFrame("Frame", "HNZHealingToolsMrtTimeline", UIParent)
    frame:SetSize(1, 1)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(101)
    frame:EnableMouse(false)

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("ENCOUNTER_START")
    ev:RegisterEvent("ENCOUNTER_END")
    ev:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    ev:SetScript("OnEvent", function(_, event, ...)
        if event == "ENCOUNTER_START" then
            local encounterID = ...
            StartEncounter(encounterID, false)
        elseif event == "ENCOUNTER_END" then
            EndEncounter()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local _, _, spellID = ...
            OnSpellCast(spellID)
        end
    end)

    frame:SetScript("OnUpdate", function(self)
        local cfg = GetCfg()
        if not cfg or not cfg.enabled then HideAllIcons(); HideMrtRing(); return end
        if not inEncounter or not encounterStart then HideAllIcons(); HideMrtRing(); return end
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
            cx + (cfg.offsetX or 0), cy + (cfg.offsetY or 60))
        UpdateIcons(GetTime() - encounterStart, cfg)
    end)
end

-- Test mode: simula un pull con el encounterID dado, asi el usuario puede ver
-- como se renderiza una nota especifica sin estar en el encuentro real. Si no
-- pasan encounterID, usa 0 (busca la nota id=0). Auto-detiene a los 90s pero
-- solo si seguimos en modo test — si un ENCOUNTER_START real ocurrio mientras,
-- isTestEncounter ya es false y no tocamos el encuentro real.
function ns:MrtTimelineTest(encounterID)
    StartEncounter(encounterID or 0, true)
    C_Timer.After(90, function()
        if inEncounter and isTestEncounter then EndEncounter() end
    end)
end
