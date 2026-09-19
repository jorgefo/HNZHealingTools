local addonName, ns = ...

-- ============================================================
-- CDM Enhancer
--
-- Aplica efectos (glow / pulse / sonido / recolor / desaturar / countdown) sobre
-- los iconos del Cooldown Manager NATIVO de Blizzard (los CooldownViewer), cuando
-- el hechizo de una regla entra en un estado: por expirar, listo (off CD), o bajo
-- en stacks. NO dibuja iconos propios: engancha los iconos de Blizzard y les pone
-- un overlay propio encima.
--
-- Taint-safe: el overlay es un frame hijo NUESTRO (inseguro) anclado al icono.
-- Nunca tocamos SetScale/SetPoint del frame protegido de Blizzard. Solo leemos
-- (Cooldown:GetCooldownTimes, GetSpellCooldown) y dibujamos encima. Coexiste con
-- Ayije_CDM (que re-skinea los mismos iconos): los overlays no pelean con su layout.
--
-- Limitacion: solo enriquece iconos que el CDM de Blizzard EFECTIVAMENTE muestra
-- (lo que el usuario agrego en Edit Mode). Si el hechizo no esta en el CDM, no hay
-- icono que enganchar — para eso estan el cursor/paneles.
-- ============================================================

local function GetCfg() return ns.db and ns.db.cdmEnhancer end

-- Viewers del CDM y su "kind": cooldown (Essential/Utility) o aura (Buff*).
local VIEWERS = {
    { name = "EssentialCooldownViewer", kind = "cooldown" },
    { name = "UtilityCooldownViewer",   kind = "cooldown" },
    { name = "BuffIconCooldownViewer",  kind = "aura" },
    { name = "BuffBarCooldownViewer",   kind = "aura" },
}

local driverFrame
local dataElapsed = 0
local masterVisible = true
local overlays = setmetatable({}, { __mode = "k" })  -- itemFrame -> overlay (weak)
local soundTickers = {}        -- rule(table) -> C_Timer ticker (loop de sonido)
local frameBySpell = {}        -- spellID -> itemFrame (reconstruido por tick)
local frameKind = setmetatable({}, { __mode = "k" })  -- itemFrame -> "cooldown"|"aura"

local GLOW_TEXTURE = "Interface\\Buttons\\UI-ActionButton-Border"

-- ============================================================
-- frame -> spellID (replica de Ayije_CDM/Core/SpellUtils.lua GetBaseSpellID)
-- ============================================================
local function GetFrameCooldownInfo(frame)
    if not frame then return nil end
    if frame.GetCooldownInfo then
        local ok, info = pcall(frame.GetCooldownInfo, frame)
        if ok and info then return info end
    end
    return frame.cooldownInfo
end

local function GetBaseSpellID(frame)
    local info = GetFrameCooldownInfo(frame)
    if info then
        local id = info.overrideTooltipSpellID or info.overrideSpellID or info.spellID
        if type(id) == "number" and id > 0 then return id end
    end
    if frame.GetSpellID then
        local ok, id = pcall(frame.GetSpellID, frame)
        if ok and type(id) == "number" and id > 0 then return id end
    end
    return nil
end

-- Reconstruye frameBySpell desde los iconos vivos de cada viewer. Barato (pocos
-- iconos) y siempre actual — evita depender de hooks event-driven.
local function RebuildFrameIndex()
    wipe(frameBySpell)
    for _, v in ipairs(VIEWERS) do
        local viewer = rawget(_G, v.name)
        if viewer and viewer.itemFramePool and viewer.itemFramePool.EnumerateActive then
            local ok = pcall(function()
                for frame in viewer.itemFramePool:EnumerateActive() do
                    local sid = GetBaseSpellID(frame)
                    if sid and not frameBySpell[sid] then
                        frameBySpell[sid] = frame
                        frameKind[frame] = v.kind
                    end
                end
            end)
            if not ok then --[[ viewer con estructura inesperada: ignorar ]] end
        end
    end
end

-- ============================================================
-- Estado del icono (leido del propio frame → sin ambiguedad de unidad)
-- ============================================================
-- Devuelve remaining(seg), active(bool), ready(bool), stacks(num|nil)
local function ComputeState(frame, spellID)
    local remaining, active = 0, false
    local cd = frame.Cooldown
    if cd and cd.GetCooldownTimes then
        local ok, startMs, durMs = pcall(cd.GetCooldownTimes, cd)
        if ok then
            startMs = ns.ToPublic(startMs)
            durMs = ns.ToPublic(durMs)
            if type(startMs) == "number" and type(durMs) == "number" and durMs > 0 then
                active = true
                remaining = (startMs + durMs) / 1000 - GetTime()
                if remaining < 0 then remaining = 0; active = false end
            end
        end
    end
    -- Ready (cooldown disponible): canonico via GetSpellCooldown, con guarda de
    -- GCD (duracion <= ~1.55s = GCD, lo tratamos como listo) para no parpadear el
    -- efecto cada vez que el global cooldown corre. No dependemos de isActive
    -- (su presencia varia entre versiones del API).
    local ready = false
    if C_Spell and C_Spell.GetSpellCooldown then
        local ci = C_Spell.GetSpellCooldown(spellID)
        if ci then
            local dur = ns.ToPublic(ci.duration) or 0
            local start = ns.ToPublic(ci.startTime) or 0
            ready = (start == 0) or (dur == 0) or (dur <= 1.55)
        end
    end
    -- Stacks: best-effort desde el propio frame del CDM (Applications/Count).
    local stacks
    local appsFS = frame.Applications or frame.Count
    if appsFS and appsFS.GetText then
        stacks = tonumber(appsFS:GetText())
    end
    return remaining, active, ready, stacks
end

-- ============================================================
-- Overlay de efectos (frame hijo propio anclado al icono)
-- ============================================================
local function EnsureOverlay(frame)
    local ov = overlays[frame]
    if ov then return ov end

    ov = CreateFrame("Frame", nil, frame)
    ov:SetAllPoints(frame)
    ov:SetFrameLevel((frame:GetFrameLevel() or 0) + 10)
    ov:EnableMouse(false)
    ov:Hide()

    -- Glow: borde aditivo pulsante (alpha loop en su propio subframe).
    local glowFrame = CreateFrame("Frame", nil, ov)
    glowFrame:SetAllPoints(ov)
    local glowTex = glowFrame:CreateTexture(nil, "OVERLAY")
    glowTex:SetTexture(GLOW_TEXTURE)
    glowTex:SetBlendMode("ADD")
    glowTex:SetPoint("TOPLEFT", -5, 5)
    glowTex:SetPoint("BOTTOMRIGHT", 5, -5)
    local gag = glowFrame:CreateAnimationGroup()
    gag:SetLooping("REPEAT")
    local g1 = gag:CreateAnimation("Alpha"); g1:SetFromAlpha(0.25); g1:SetToAlpha(1); g1:SetDuration(0.5); g1:SetOrder(1)
    local g2 = gag:CreateAnimation("Alpha"); g2:SetFromAlpha(1); g2:SetToAlpha(0.25); g2:SetDuration(0.5); g2:SetOrder(2)
    glowFrame:Hide()
    ov.glowFrame, ov.glowTex, ov.glowAnim = glowFrame, glowTex, gag

    -- Pulse: copia del icono que "late" (scale loop heartbeat) sobre el icono real.
    local pulseFrame = CreateFrame("Frame", nil, ov)
    pulseFrame:SetAllPoints(ov)
    local pulseTex = pulseFrame:CreateTexture(nil, "ARTWORK")
    pulseTex:SetAllPoints(pulseFrame)
    pulseTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    pulseTex:SetAlpha(0.55)
    local pag = pulseFrame:CreateAnimationGroup()
    pag:SetLooping("REPEAT")
    local ps1 = pag:CreateAnimation("Scale"); ps1:SetDuration(0.45); ps1:SetOrder(1); ps1:SetOrigin("CENTER", 0, 0)
    local ps2 = pag:CreateAnimation("Scale"); ps2:SetDuration(0.45); ps2:SetOrder(2); ps2:SetOrigin("CENTER", 0, 0)
    pulseFrame:Hide()
    ov.pulseFrame, ov.pulseTex, ov.pulseAnim, ov.pulseUp, ov.pulseDown = pulseFrame, pulseTex, pag, ps1, ps2

    -- Recolor: borde teñido estatico.
    local recolorTex = ov:CreateTexture(nil, "OVERLAY")
    recolorTex:SetTexture(GLOW_TEXTURE)
    recolorTex:SetPoint("TOPLEFT", -4, 4)
    recolorTex:SetPoint("BOTTOMRIGHT", 4, -4)
    recolorTex:Hide()
    ov.recolorTex = recolorTex

    -- Countdown: tiempo restante en el centro.
    local cdFS = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cdFS:SetPoint("CENTER", 0, 0)
    cdFS:SetShadowOffset(1, -1)
    cdFS:Hide()
    ov.countdownFS = cdFS

    ov._firing = false
    overlays[frame] = ov
    return ov
end

local function StopSoundLoop(rule)
    local t = soundTickers[rule]
    if t then if t.Cancel then pcall(t.Cancel, t) end; soundTickers[rule] = nil end
end

local function StartSoundLoop(rule)
    if soundTickers[rule] then return end
    if not (C_Timer and C_Timer.NewTicker) then return end
    local interval = tonumber(rule.sound and rule.sound.interval) or 2
    if interval < 0.5 then interval = 0.5 end
    soundTickers[rule] = C_Timer.NewTicker(interval, function()
        ns.PlayAuraSound(rule.sound.name or "Default", rule.sound.channel or "Master")
    end)
end

-- Aplica los efectos de `rule` al overlay (edge-triggered: animaciones y sonido
-- arrancan al ENTRAR al estado). `remaining` actualiza el countdown cada tick.
local function ApplyFiring(ov, frame, rule, remaining)
    local entering = not ov._firing
    ov._firing = true
    ov._rule = rule
    ov:Show()

    -- Glow
    if rule.glow and rule.glow.on then
        local c = rule.glow.color or { r = 1, g = 0.9, b = 0.3 }
        ov.glowTex:SetVertexColor(c.r or 1, c.g or 0.9, c.b or 0.3)
        ov.glowFrame:Show()
        if entering then ov.glowAnim:Play() end
    else
        ov.glowFrame:Hide(); ov.glowAnim:Stop()
    end

    -- Pulse (heartbeat). El factor de escala puede cambiar entre fires → seteamos
    -- siempre y reiniciamos la animacion al entrar.
    if rule.pulse and rule.pulse.on then
        local scale = tonumber(rule.pulse.scale) or 1.4
        ov.pulseUp:SetScaleFrom(1, 1);     ov.pulseUp:SetScaleTo(scale, scale)
        ov.pulseDown:SetScaleFrom(scale, scale); ov.pulseDown:SetScaleTo(1, 1)
        if frame.Icon and frame.Icon.GetTexture then ov.pulseTex:SetTexture(frame.Icon:GetTexture()) end
        ov.pulseFrame:Show()
        if entering then ov.pulseAnim:Stop(); ov.pulseAnim:Play() end
    else
        ov.pulseFrame:Hide(); ov.pulseAnim:Stop()
    end

    -- Recolor (borde teñido)
    if rule.recolor and rule.recolor.on then
        local c = rule.recolor.color or { r = 1, g = 0.2, b = 0.2 }
        ov.recolorTex:SetVertexColor(c.r or 1, c.g or 0.2, c.b or 0.2)
        ov.recolorTex:SetAlpha(0.9)
        ov.recolorTex:Show()
    else
        ov.recolorTex:Hide()
    end

    -- Desaturar el icono de Blizzard. Toca frame.Icon directo (visual, sin taint);
    -- puede coexistir con Ayije aunque podria parpadear si ambos lo manejan.
    if rule.desaturate and frame.Icon and frame.Icon.SetDesaturation then
        frame.Icon:SetDesaturation(1)
        ov._desatApplied = true
    elseif ov._desatApplied and frame.Icon and frame.Icon.SetDesaturation then
        frame.Icon:SetDesaturation(0); ov._desatApplied = nil
    end

    -- Countdown
    if rule.countdown and rule.countdown.on then
        ov.countdownFS:SetText(remaining and remaining > 0 and ns.FormatDuration(remaining) or "")
        ov.countdownFS:Show()
    else
        ov.countdownFS:Hide()
    end

    -- Sonido one-shot al entrar; loop opcional mientras dure el estado.
    if entering and rule.sound and rule.sound.on then
        ns.PlayAuraSound(rule.sound.name or "Default", rule.sound.channel or "Master")
        if rule.sound.loop then StartSoundLoop(rule) end
    end
end

local function ClearFiring(ov, frame)
    if not ov._firing then return end
    ov._firing = false
    if ov._rule then StopSoundLoop(ov._rule) end
    ov._rule = nil
    ov.glowFrame:Hide(); ov.glowAnim:Stop()
    ov.pulseFrame:Hide(); ov.pulseAnim:Stop()
    ov.recolorTex:Hide()
    ov.countdownFS:Hide()
    if ov._desatApplied and frame and frame.Icon and frame.Icon.SetDesaturation then
        frame.Icon:SetDesaturation(0)
    end
    ov._desatApplied = nil
    ov:Hide()
end

-- ============================================================
-- Evaluador
-- ============================================================
local function ShouldFire(rule, kind, remaining, active, ready, stacks)
    if rule.onExpiring and active and remaining > 0 and remaining <= (tonumber(rule.expireWarn) or 5) then
        return true
    end
    if rule.onReady and ready then return true end
    if rule.onLowStacks then
        local minS = tonumber(rule.minStacks) or 0
        if stacks ~= nil and stacks < minS then return true end
    end
    return false
end

local function UpdateAll()
    local cfg = GetCfg()
    if not cfg then return end
    RebuildFrameIndex()

    local touched = {}
    for _, rule in ipairs(cfg.rules or {}) do
        if rule.enabled ~= false and rule.spellID then
            local frame = frameBySpell[rule.spellID]
            if frame and frame:IsVisible() then
                local remaining, active, ready, stacks = ComputeState(frame, rule.spellID)
                local ov = EnsureOverlay(frame)
                touched[ov] = true
                if ShouldFire(rule, frameKind[frame], remaining, active, ready, stacks) then
                    ApplyFiring(ov, frame, rule, remaining)
                else
                    ClearFiring(ov, frame)
                end
            end
        end
    end

    -- Limpiar overlays que dispararon antes pero ya no fueron tocados (icono se
    -- escondio / regla borrada / spell ya no esta en el CDM).
    for frame, ov in pairs(overlays) do
        if not touched[ov] and ov._firing then ClearFiring(ov, frame) end
    end
end

function ns:InitCdmEnhancer()
    driverFrame = CreateFrame("Frame")

    driverFrame:SetScript("OnUpdate", function(_, elapsed)
        local cfg = GetCfg()
        if not (masterVisible and cfg and cfg.enabled) then return end
        if not cfg.rules or #cfg.rules == 0 then return end

        dataElapsed = dataElapsed + elapsed
        -- 10 Hz cuando hay reglas (necesario para countdown y para captar expiry
        -- al segundo). Es opt-in y son pocas reglas → costo trivial.
        if dataElapsed >= 0.1 then
            dataElapsed = 0
            ns._dirtyCdm = false
            UpdateAll()
        end
    end)
end

-- ============================================================
-- API para el Config
-- ============================================================

-- Limpia TODOS los overlays (firing) y corta loops de sonido. Usado al
-- deshabilitar la feature y al reconstruir reglas.
local function ClearAllOverlays()
    for frame, ov in pairs(overlays) do ClearFiring(ov, frame) end
    for rule in pairs(soundTickers) do StopSoundLoop(rule) end
end

-- Toggle de "Habilitar Funciones": al apagar limpia overlays; al prender marca dirty.
function ns.RefreshCdmEnhancer()
    local cfg = GetCfg()
    if not cfg or not cfg.enabled then
        ClearAllOverlays()
        return
    end
    ns._dirtyCdm = true
end

-- Tras add/edit/remove de reglas: limpiar overlays para reevaluar desde cero.
function ns.RebuildCdmRules()
    ClearAllOverlays()
    ns._dirtyCdm = true
end

function ns:ToggleCdmEnhancer()
    masterVisible = not masterVisible
    if not masterVisible then ClearAllOverlays() end
end
