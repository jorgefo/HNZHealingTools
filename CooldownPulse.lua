local _, ns = ...

-- CooldownPulse: muestra un icono grande en el centro de la pantalla
-- (estilo CDPulse) cuando un hechizo configurado pasa de COOLDOWN -> READY,
-- opcionalmente reproduce un sonido. Reusa ns:GetSpellStatus y la lista de
-- cursorSpells; el flag per-entry es `cdPulse` (+ `cdPulseSound`, `cdPulseSoundName`).

local CreateFrame = CreateFrame
local UIParent = UIParent
local ipairs = ipairs
local wipe = wipe
local mathmax = math.max
local mathfloor = math.floor

local pulseFrame
local lastStatus = {}      -- spellID -> ultimo status observado (cooldown spells)
local seenSpell  = {}      -- spellID -> true tras la primera observacion
                           -- (evita disparar al loguear o cambiar de zona)
local lastAuraActive = {}  -- key -> true/false (estado previo de cada aura tracked)
local seenAura = {}        -- key -> true tras primera observacion
local elapsed = 0
local POLL_INTERVAL = 0.1
local inCombat = false     -- gateado por PLAYER_REGEN_DISABLED/ENABLED

-- weak-keyed por entry-reference para no contaminar SavedVariables. Se reciclan
-- cuando la entry desaparece (remove o switch de profile).
local pulseKeyCache = setmetatable({}, {__mode = "k"})

local function GetPulseKey(entry)
    local k = pulseKeyCache[entry]
    if not k then
        k = (entry.spellID or 0) .. "|" .. (entry.unit or "player") .. "|" .. (entry.filter or "HELPFUL")
        pulseKeyCache[entry] = k
    end
    return k
end

local function GetSettings()
    return ns.db and ns.db.cooldownPulse
end

local function ApplyPlacement(f)
    local s = GetSettings()
    if not s then return end
    f:SetSize(s.iconSize or 80, s.iconSize or 80)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 120)
    f:SetAlpha(s.opacity or 1.0)
end

local function CreatePulseFrame()
    local f = CreateFrame("Frame", "HNZHealingToolsPulseFrame", UIParent)
    f:SetFrameStrata("HIGH"); f:SetFrameLevel(200)
    f:EnableMouse(false)
    f:Hide()

    local border = f:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -2, 2); border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0, 0, 0, 0.85)
    f.border = border

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon

    local glow = f:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", -8, 8); glow:SetPoint("BOTTOMRIGHT", 8, -8)
    glow:SetColorTexture(1, 1, 1, 0.25); glow:SetBlendMode("ADD")
    f.glow = glow

    local name = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOP", f, "BOTTOM", 0, -6)
    name:SetShadowOffset(1, -1); name:SetTextColor(1, 1, 1)
    f.name = name

    ApplyPlacement(f)

    -- Animation: scale-in + fade-in -> hold -> scale-out + fade-out
    local ag = f:CreateAnimationGroup()
    f.ag = ag

    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.18); fadeIn:SetOrder(1)
    local scaleIn = ag:CreateAnimation("Scale")
    scaleIn:SetScaleFrom(1.8, 1.8); scaleIn:SetScaleTo(1.0, 1.0)
    scaleIn:SetDuration(0.18); scaleIn:SetOrder(1); scaleIn:SetOrigin("CENTER", 0, 0)

    local hold = ag:CreateAnimation("Alpha")
    hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(0.55); hold:SetOrder(2)
    f.holdAnim = hold

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(0.40); fadeOut:SetOrder(3)
    local scaleOut = ag:CreateAnimation("Scale")
    scaleOut:SetScaleFrom(1.0, 1.0); scaleOut:SetScaleTo(0.6, 0.6)
    scaleOut:SetDuration(0.40); scaleOut:SetOrder(3); scaleOut:SetOrigin("CENTER", 0, 0)

    ag:SetScript("OnFinished", function() f:Hide() end)
    return f
end

-- bypassEnabled: cuando true, ignora el toggle `enabled` Y el gate de visibility
-- del cooldownPulse module. Lo usa MrtTimeline para disparar pulses como
-- visualizacion de sus triggers aunque el cooldownPulse general este off (el
-- usuario activo MRT->Pulse desde otro menu y no deberia tener que habilitar
-- tambien cooldownPulse). Tambien bypaseamos visibility porque MRT solo dispara
-- durante encounters (in-combat por definicion) y porque si el usuario tiene
-- cooldownPulse.visibility="combat" pero prueba la nota fuera de combate con el
-- boton de test, el pulse no aparecia.
function ns:ShowPulse(icon, name, soundEnabled, soundName, soundChannel, bypassEnabled)
    local s = GetSettings()
    if not bypassEnabled then
        if s and s.enabled == false then return end
        -- Combat-gate via visibility ("always"|"combat"|"ooc"). Aplica a la animacion
        -- + sonido (sonidos de READY fuera de combate son ruido para muchos healers).
        if s and not ns.MatchesVisibility(s.visibility, inCombat) then return end
    end
    if not pulseFrame then pulseFrame = CreatePulseFrame() end

    ApplyPlacement(pulseFrame)
    pulseFrame.icon:SetTexture(icon or 134400)
    pulseFrame.name:SetText(name or "")
    if pulseFrame.holdAnim and s and s.holdDuration then
        pulseFrame.holdAnim:SetDuration(mathmax(0.05, s.holdDuration))
    end

    pulseFrame.ag:Stop()
    pulseFrame:Show()
    pulseFrame.ag:Play()

    if soundEnabled and ns.PlayAuraSound then
        ns.PlayAuraSound(soundName or "Default", soundChannel)
    end
end

local function ProcessPulseSpell(entry, soundEnabledKey, soundNameKey, soundChannelKey)
    if not (entry and entry.enabled) then return end
    if ns.IsEntryAllowedForCurrentSpec and not ns.IsEntryAllowedForCurrentSpec(entry) then return end
    if ns.IsEntryAllowedForRequiredTalent and not ns.IsEntryAllowedForRequiredTalent(entry) then return end
    if ns.IsEntryAllowedForCurrentInstance and not ns.IsEntryAllowedForCurrentInstance(entry) then return end
    -- Key estable que distingue spell vs item (ambos pueden compartir IDs
    -- numericos). lastStatus/seenSpell estan keyed por esta string en lugar de
    -- por spellID directo desde que aceptamos entries item-based.
    local key = ns.GetEntryKey and ns.GetEntryKey(entry) or (entry.spellID and ("s"..entry.spellID))
    if not key then return end
    local status = ns:GetEntryStatus(entry)
    local newSt = status.status
    if seenSpell[key] then
        local prev = lastStatus[key]
        -- Trigger when leaving the COOLDOWN state to READY. Other transitions
        -- (NO_POWER->READY, OUT_OF_RANGE->READY) just reflect player state and
        -- would be noisy.
        if prev == "COOLDOWN" and newSt == "READY" then
            local channel = soundChannelKey and entry[soundChannelKey] or nil
            ns:ShowPulse(status.icon, status.name, entry[soundEnabledKey], entry[soundNameKey], channel)
        end
    end
    lastStatus[key] = newSt
    seenSpell[key] = true
end

local function ProcessPulseAura(entry)
    if not (entry and entry.enabled) then return end
    if ns.IsEntryAllowedForCurrentSpec and not ns.IsEntryAllowedForCurrentSpec(entry) then return end
    if ns.IsEntryAllowedForRequiredTalent and not ns.IsEntryAllowedForRequiredTalent(entry) then return end
    if ns.IsEntryAllowedForCurrentInstance and not ns.IsEntryAllowedForCurrentInstance(entry) then return end
    local sid = entry.spellID
    if not sid or not ns.GetAuraStatus then return end
    local unit, filter = entry.unit or "player", entry.filter or "HELPFUL"
    local status = ns:GetAuraStatus(sid, unit, filter, entry.manualDuration)
    local active = status and status.status == "ACTIVE"
    local key = GetPulseKey(entry)
    if seenAura[key] then
        local prev = lastAuraActive[key]
        -- Disparo al ganar el aura: MISSING -> ACTIVE.
        if not prev and active then
            local icon, name = status and status.icon, status and status.name
            if not (icon and name) and ns.GetSpellDisplayInfo then
                local n2, i2 = ns.GetSpellDisplayInfo(sid)
                icon = icon or i2
                name = name or n2
            end
            ns:ShowPulse(icon, name, entry.soundEnabled, entry.soundName, entry.soundChannel)
        end
    end
    lastAuraActive[key] = active
    seenAura[key] = true
end

local function PollSpells(_, e)
    elapsed = elapsed + e
    if elapsed < POLL_INTERVAL then return end
    elapsed = 0
    local db = ns.db
    if not db then return end
    local cp = db.cooldownPulse
    if cp and cp.enabled == false then return end
    -- Pulse solo dispara en transicion (COOLDOWN -> READY, MISSING -> ACTIVE).
    -- Eventos (SPELL_UPDATE_COOLDOWN, UNIT_AURA) marcan dirty cuando la transicion
    -- ocurre, asi que solo necesitamos ejecutar el scan en respuesta. Sin esto el
    -- modulo recorria todas las listas llamando GetSpellStatus/GetAuraStatus 10x/s
    -- aunque nada hubiera cambiado. Si dirty=false saltamos el work entero.
    if not (ns._spellDirtyPulse or ns._auraDirtyPulse) then return end
    ns._spellDirtyPulse = false
    ns._auraDirtyPulse = false

    local pulseSpells = db.pulseSpells
    local pulseAuras = db.pulseAuras
    local cursorSpells = db.cursorSpells
    local hasPulse = (pulseSpells and #pulseSpells > 0)
                  or (pulseAuras and #pulseAuras > 0)
                  or (cursorSpells and #cursorSpells > 0)
    if not hasPulse then return end

    if pulseSpells then
        for i = 1, #pulseSpells do
            ProcessPulseSpell(pulseSpells[i], "soundEnabled", "soundName", "soundChannel")
        end
    end

    -- Compatibilidad legacy: entries de cursorSpells con flag cdPulse (sin canal)
    if cursorSpells then
        for i = 1, #cursorSpells do
            local entry = cursorSpells[i]
            if entry and entry.cdPulse then
                ProcessPulseSpell(entry, "cdPulseSound", "cdPulseSoundName", nil)
            end
        end
    end

    if pulseAuras then
        for i = 1, #pulseAuras do
            ProcessPulseAura(pulseAuras[i])
        end
    end
end

local function ResetCache()
    wipe(lastStatus)
    wipe(seenSpell)
    wipe(lastAuraActive)
    wipe(seenAura)
end

function ns:ResetCooldownPulseCache() ResetCache() end

function ns:RefreshCooldownPulse()
    if pulseFrame then ApplyPlacement(pulseFrame) end
    if ns._pulseAnchor then ns:RefreshCooldownPulseAnchor() end
    if ns._notifyCooldownPulsePreviews then ns._notifyCooldownPulsePreviews() end
end

-- Anchor visible y movible para reposicionar el pulse. Mientras esta visible
-- el usuario lo arrastra y al soltar guarda offsetX/Y en db.cooldownPulse.
local function CreateAnchor()
    local s = GetSettings() or {}
    local a = CreateFrame("Frame", "HNZHealingToolsPulseAnchor", UIParent, "BackdropTemplate")
    a:SetSize(s.iconSize or 80, s.iconSize or 80)
    a:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 120)
    a:SetFrameStrata("HIGH"); a:SetFrameLevel(150)
    a:SetMovable(true); a:EnableMouse(true); a:RegisterForDrag("LeftButton")
    a:SetClampedToScreen(true)
    a:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
                    tile=true, tileSize=16, edgeSize=12, insets={left=2,right=2,top=2,bottom=2} })
    a:SetBackdropColor(0, 0.7, 0.7, 0.45)
    a:SetBackdropBorderColor(0.4, 1, 1, 0.9)

    local label = a:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText("PULSE")
    label:SetTextColor(1, 1, 1)
    a.label = label

    local hint = a:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOP", a, "BOTTOM", 0, -4)
    hint:SetText(ns.L["Drag to move"])
    hint:SetTextColor(0.8, 0.8, 0.8)
    a.hint = hint

    a:SetScript("OnDragStart", function(self) self:StartMoving() end)
    a:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        local sx, sy = self:GetCenter()
        if cx and sx then
            local d = ns.db and ns.db.cooldownPulse
            if d then
                d.offsetX = mathfloor(sx - cx + 0.5)
                d.offsetY = mathfloor(sy - cy + 0.5)
            end
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", d and d.offsetX or 0, d and d.offsetY or 0)
            if pulseFrame then ApplyPlacement(pulseFrame) end
        end
    end)

    return a
end

function ns:RefreshCooldownPulseAnchor()
    if not ns._pulseAnchor then return end
    local s = GetSettings() or {}
    ns._pulseAnchor:SetSize(s.iconSize or 80, s.iconSize or 80)
    ns._pulseAnchor:ClearAllPoints()
    ns._pulseAnchor:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 120)
end

function ns:ShowCooldownPulseAnchor()
    if not ns._pulseAnchor then ns._pulseAnchor = CreateAnchor() end
    ns:RefreshCooldownPulseAnchor()
    ns._pulseAnchor:Show()
end

function ns:HideCooldownPulseAnchor()
    if ns._pulseAnchor then ns._pulseAnchor:Hide() end
end

function ns:ToggleCooldownPulseAnchor()
    if ns._pulseAnchor and ns._pulseAnchor:IsShown() then
        ns:HideCooldownPulseAnchor()
        return false
    end
    ns:ShowCooldownPulseAnchor()
    return true
end

function ns:IsCooldownPulseAnchorShown()
    return ns._pulseAnchor and ns._pulseAnchor:IsShown() or false
end

function ns:TestPulseEntry(entry)
    -- Test per-entry desde el row del config: dispara un pulse one-shot con el
    -- icono/sonido de esta entry especifica (bypass del toggle enabled global).
    if not entry then return end
    local nm, ic
    if entry.itemID and entry.itemID > 0 then
        nm, ic = ns.GetItemDisplayInfo(entry.itemID)
    elseif entry.spellID then
        nm, ic = ns.GetSpellDisplayInfo(entry.spellID)
    else
        return
    end
    local soundEnabled = entry.soundEnabled or entry.cdPulseSound
    local soundName = entry.soundName or entry.cdPulseSoundName
    local soundChannel = entry.soundChannel
    ns:ShowPulse(ic, nm, soundEnabled, soundName, soundChannel, true)
end

function ns:TestCooldownPulse()
    -- Used by the config "Test" button: prefiere pulseSpells, después legacy cdPulse, después fallback.
    local db = ns.db or {}
    local entry
    if db.pulseSpells and db.pulseSpells[1] then
        entry = db.pulseSpells[1]
    else
        for _, e in ipairs(db.cursorSpells or {}) do
            if e.cdPulse then entry = e; break end
        end
        if not entry then entry = (db.cursorSpells or {})[1] end
    end
    if entry then
        local st = ns:GetSpellStatus(entry.spellID)
        local soundEnabled = entry.soundEnabled or entry.cdPulseSound
        local soundName = entry.soundName or entry.cdPulseSoundName
        ns:ShowPulse(st.icon, st.name, soundEnabled, soundName, entry.soundChannel)
    else
        ns:ShowPulse(134400, "Test", false)
    end
end

-- ============================================================
-- Live preview: dispara un pulse de muestra en loop usando los settings actuales
-- (iconSize / opacity / holdDuration). Auto-contenido — no toca pulseFrame ni
-- el anchor real. Rebota entre 3 iconos para que se note que esta animado.
-- ============================================================

local previewRegistry = {}

local PREVIEW_SAMPLES = {
    { icon = "Interface\\Icons\\Spell_Holy_FlashHeal",            name = "Flash Heal"    },
    { icon = "Interface\\Icons\\Spell_Nature_Rejuvenation",       name = "Rejuvenation"  },
    { icon = "Interface\\Icons\\Spell_Nature_HealingWaveGreater", name = "Healing Wave"  },
}

local function BuildPreviewPulse(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(80, 80)
    f:SetPoint("CENTER", parent, "CENTER")
    f:EnableMouse(false)
    f:Hide()

    local border = f:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -2, 2); border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0, 0, 0, 0.85)
    f.border = border

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon

    local glow = f:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", -8, 8); glow:SetPoint("BOTTOMRIGHT", 8, -8)
    glow:SetColorTexture(1, 1, 1, 0.25); glow:SetBlendMode("ADD")
    f.glow = glow

    local name = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOP", f, "BOTTOM", 0, -6)
    name:SetShadowOffset(1, -1); name:SetTextColor(1, 1, 1)
    f.name = name

    local ag = f:CreateAnimationGroup()
    f.ag = ag

    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.18); fadeIn:SetOrder(1)
    local scaleIn = ag:CreateAnimation("Scale")
    scaleIn:SetScaleFrom(1.8, 1.8); scaleIn:SetScaleTo(1.0, 1.0)
    scaleIn:SetDuration(0.18); scaleIn:SetOrder(1); scaleIn:SetOrigin("CENTER", 0, 0)

    local hold = ag:CreateAnimation("Alpha")
    hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(0.55); hold:SetOrder(2)
    f.holdAnim = hold

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(0.40); fadeOut:SetOrder(3)
    local scaleOut = ag:CreateAnimation("Scale")
    scaleOut:SetScaleFrom(1.0, 1.0); scaleOut:SetScaleTo(0.6, 0.6)
    scaleOut:SetDuration(0.40); scaleOut:SetOrder(3); scaleOut:SetOrigin("CENTER", 0, 0)

    ag:SetScript("OnFinished", function() f:Hide() end)
    return f
end

function ns:CreateCooldownPulsePreview(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:EnableMouse(false)

    local pulseF = BuildPreviewPulse(container)
    local preview = { container = container, pulseFrame = pulseF, idx = 0, lastTrigger = -math.huge }

    local function ApplySize()
        local s = ns.db.cooldownPulse or {}
        local size = s.iconSize or 80
        local ch = container:GetHeight() or 0
        local cw = container:GetWidth() or 0
        -- Reservamos ~30 px verticales para el texto debajo del icono.
        local maxSize = math.min(ch - 30, cw) * 0.65
        if maxSize > 0 and size > maxSize then
            pulseF:SetScale(maxSize / size)
        else
            pulseF:SetScale(1)
        end
        pulseF:SetSize(size, size)
        pulseF:ClearAllPoints()
        pulseF:SetPoint("CENTER", container, "CENTER", 0, 0)
    end

    local function Trigger()
        local s = ns.db.cooldownPulse or {}
        ApplySize()
        preview.idx = preview.idx + 1
        local sample = PREVIEW_SAMPLES[((preview.idx - 1) % #PREVIEW_SAMPLES) + 1]
        pulseF.icon:SetTexture(sample.icon)
        pulseF.name:SetText(sample.name)
        if pulseF.holdAnim and s.holdDuration then
            pulseF.holdAnim:SetDuration(mathmax(0.05, s.holdDuration))
        end
        pulseF:SetAlpha(s.opacity or 1.0)
        pulseF.ag:Stop()
        pulseF:Show()
        pulseF.ag:Play()
    end

    preview.Refresh = ApplySize
    preview.Trigger = Trigger

    container:SetScript("OnUpdate", function()
        local s = ns.db.cooldownPulse or {}
        local now = GetTime()
        -- cycle = fade-in (0.18) + hold + fade-out (0.40) + idle gap (1.2)
        local cycle = (s.holdDuration or 0.55) + 1.78
        if now - preview.lastTrigger >= cycle then
            preview.lastTrigger = now
            Trigger()
        end
    end)

    container:HookScript("OnSizeChanged", ApplySize)
    container:HookScript("OnShow", function()
        preview.lastTrigger = -math.huge
        ApplySize()
    end)
    table.insert(previewRegistry, preview)

    C_Timer.After(0, ApplySize)
    return preview
end

ns._notifyCooldownPulsePreviews = function()
    for _, p in ipairs(previewRegistry) do
        if p.container:IsShown() then p.Refresh() end
    end
end

function ns:InitCooldownPulse()
    inCombat = UnitAffectingCombat("player") and true or false

    local poll = CreateFrame("Frame")
    poll:SetScript("OnUpdate", PollSpells)

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ev:RegisterEvent("PLAYER_TALENT_UPDATE")
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    ev:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then inCombat = false
        elseif event == "PLAYER_ENTERING_WORLD" then
            inCombat = UnitAffectingCombat("player") and true or false
            ResetCache()
        else
            ResetCache()
        end
    end)
end
