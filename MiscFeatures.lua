local _, ns = ...

-- ============================================================
-- MiscFeatures: cajón de features pequeñas que no ameritan su propio menú.
-- Viven todas bajo el sidebar "Varios". Cada sub-feature tiene su propio enable
-- en ns.db.misc.<feature>.enabled.
--
-- Feature 1: Combat Resurrection tracker (resurrecciones de combate del GRUPO).
--   El pool de brez es compartido por toda la raid/M+ — NO depende de tu clase.
--   En contenido instanciado el juego sobreescribe las cargas del spell Rebirth
--   (Druida, ID 20484) para devolver el pool del encuentro: cualquier clase puede
--   consultarlo aunque no conozca el hechizo. Mostramos cuántas cargas hay y, si
--   no hay, cuánto falta para la próxima. Fuera de contenido con pool, el API
--   devuelve nil y ocultamos el indicador ("solo cuando hay pool activo").
--   Companion: icono de Reencarnación (solo Chamán) anclado a la derecha.
-- ============================================================

local CreateFrame = CreateFrame
local UIParent = UIParent
local GetTime = GetTime
local C_Spell = C_Spell

-- Rebirth (Druida). Es el spellID canónico que el juego usa como "host" del pool
-- de combat-res en raids y Mythic+. Consultarlo funciona para cualquier clase.
local BREZ_SPELL_ID = 20484
local BREZ_FALLBACK_ICON = 136080 -- Interface/Icons/Spell_Nature_Reincarnation
-- Reincarnation (Chamán): auto-res con cooldown largo.
local REINC_SPELL_ID = 20608

local crFrame             -- frame del indicador de brez del grupo (el draggable)
local reincFrame          -- frame de Reencarnación (anclado a la derecha del brez)
local moveMode = false    -- desbloqueado para arrastrar libremente + muestra dummy
local REINC_GAP = 6       -- separación entre el icono de brez y el de reinc

-- El icono de auto-res (reinc) aparece para quien CONOZCA el hechizo, no por clase
-- ("a menos que tengan el mismo hechizo del chaman"). Hoy solo Chamán tiene
-- Reincarnation (20608), pero gatear por conocimiento del spell es lo correcto:
-- se adapta solo si el pj aún no lo aprendió o si en el futuro otra clase lo tuviera.
local function HasReincarnation()
    if type(IsPlayerSpell) == "function" then
        local ok, known = pcall(IsPlayerSpell, REINC_SPELL_ID)
        if ok and known then return true end
    end
    if type(IsSpellKnown) == "function" then
        local ok, known = pcall(IsSpellKnown, REINC_SPELL_ID)
        if ok and known then return true end
    end
    return false
end

local function GetCR() return ns.db and ns.db.misc and ns.db.misc.combatRes end

-- Aplica un tamaño de fuente puntual conservando font/flags actuales.
local function ApplyLabelFont(label, size)
    local font, _, flags = label:GetFont()
    if font then label:SetFont(font, size, flags or "OUTLINE") end
end

-- ============================================================
-- Tracking del pool de brez del grupo.
--   API: C_Spell.GetSpellCharges(20484) devuelve nil desde BfA para brez, así que
--   NO es confiable. La usamos como primer intento (por si el patch la soporta en
--   el encuentro) y caemos a un tracker MANUAL — el mismo enfoque que oRA3/BigWigs.
--
--   Modelo manual (fórmula del juego):
--     - Raid: al pull (ENCOUNTER_START) el pool arranca con 1 carga y recarga
--       1 cada (90/raidSize) minutos.
--     - M+: al iniciar la llave (CHALLENGE_MODE_START) arranca con 1 carga y
--       recarga ~1 cada 10 min (aprox; constante REINC... ver BREZ_MPLUS_RECHARGE).
--     - Cada brez aceptado (CLEU SPELL_RESURRECT de un spell de la lista) descuenta 1.
--   Es una aproximación: el contador puede desviarse si se pierde/rechaza un brez,
--   pero el timer de recarga es exacto. Cap de cargas acumulables = 5.
-- ============================================================
local BREZ_SPELLS = {
    [20484] = true,  -- Rebirth (Druida)
    [61999] = true,  -- Raise Ally (Caballero de la Muerte)
    [391054] = true, -- Intercession (Paladín)
    [20707] = true,  -- Soulstone (Brujo)
}
local BREZ_CAP = 5
local BREZ_MPLUS_RECHARGE = 600 -- M+: ~1 cada 10 min (ajustable si difiere en vivo)
local brez = { active = false, charges = 0, rechargeStart = 0, rechargeDur = 0 }

local function BrezRechargeDuration()
    local _, itype = IsInInstance()
    if itype == "party" then return BREZ_MPLUS_RECHARGE end
    local n = GetNumGroupMembers()
    if n < 1 then n = 1 end
    return (90 / n) * 60 -- raid: 90/raidSize minutos por carga
end

-- Acredita cargas según el tiempo transcurrido (hasta el cap).
local function BrezTick()
    if not brez.active or brez.rechargeDur <= 0 then return end
    while brez.charges < BREZ_CAP and (GetTime() - brez.rechargeStart) >= brez.rechargeDur do
        brez.charges = brez.charges + 1
        brez.rechargeStart = brez.rechargeStart + brez.rechargeDur
    end
end

local function BrezActivate()
    brez.active = true
    brez.charges = 1
    brez.rechargeDur = BrezRechargeDuration()
    brez.rechargeStart = GetTime()
end

local function BrezDeactivate()
    brez.active = false
    brez.charges = 0
end

local function BrezConsume()
    if not brez.active then return end
    -- Si estaba lleno, arranca el ciclo de recarga desde ahora.
    if brez.charges >= BREZ_CAP then brez.rechargeStart = GetTime() end
    if brez.charges > 0 then brez.charges = brez.charges - 1 end
end

-- ¿Estoy en contenido con pool de brez? = raid instanciada, o M+ activa (party
-- con challenge mode). En este contenido los iconos se muestran SIEMPRE (en o
-- fuera de combate, haya boss activo o no).
local function InBrezContent()
    local inInst, itype = IsInInstance()
    if not inInst then return false end
    if itype == "raid" then return true end
    if itype == "party" then
        if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
            return C_ChallengeMode.IsChallengeModeActive() and true or false
        end
    end
    return false
end

-- Devuelve cur, max, start, dur o nil si no hay pool activo.
local function GetBrezCharges()
    -- 1) API oficial (úsala si el patch la soporta durante el encuentro).
    if C_Spell and C_Spell.GetSpellCharges then
        local ok, info = pcall(C_Spell.GetSpellCharges, BREZ_SPELL_ID)
        if ok and type(info) == "table"
           and type(info.currentCharges) == "number" and type(info.maxCharges) == "number"
           and info.maxCharges > 0 then
            return info.currentCharges, info.maxCharges, info.cooldownStartTime, info.cooldownDuration
        end
    end
    -- 2) Fallback manual (encuentro de raid / M+ activo).
    if brez.active then
        BrezTick()
        local s, d = 0, 0
        if brez.charges < BREZ_CAP then s, d = brez.rechargeStart, brez.rechargeDur end
        return brez.charges, BREZ_CAP, s, d
    end
    return nil
end

-- Cooldown de Reencarnación. Devuelve start, dur o nil. Tolerante a las dos
-- formas del API (C_Spell.GetSpellCooldown tabla / global legacy multi-return).
local function GetReincCooldown()
    local start, dur
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, REINC_SPELL_ID)
        if ok and type(info) == "table" then start, dur = info.startTime, info.duration end
    end
    if start == nil and type(_G.GetSpellCooldown) == "function" then
        local ok, s, d = pcall(_G.GetSpellCooldown, REINC_SPELL_ID)
        if ok then start, dur = s, d end
    end
    return start, dur
end

-- "M:SS" desde segundos. Para countdowns (próxima carga / próximo reencarnar).
local function FormatMMSS(secs)
    if not secs or secs < 0 then secs = 0 end
    local m = math.floor(secs / 60)
    local s = math.floor(secs % 60)
    return string.format("%d:%02d", m, s)
end

local function ResolveTextSize(cr, sz)
    local ts = cr.textSize or 0
    if ts <= 0 then ts = math.max(8, math.floor(sz * 0.45)) end
    return ts
end

-- Posiciona/dimensiona ambos iconos. El de brez usa CENTER + offsets (es el que
-- se arrastra); el de reinc se ancla a la DERECHA del brez para seguirlo en vivo
-- al moverlo (y mantiene posición aunque el brez esté Hide(): el anclaje resuelve
-- la posición igual). Aplica también opacidad y tamaño de texto a los dos.
local function ApplyPlacement()
    local cr = GetCR()
    if not cr or not crFrame then return end
    local sz = cr.iconSize or 44
    local ts = ResolveTextSize(cr, sz)
    local alpha = cr.opacity or 1.0

    crFrame:SetSize(sz, sz); crFrame:SetAlpha(alpha)
    crFrame:ClearAllPoints()
    crFrame:SetPoint("CENTER", UIParent, "CENTER", cr.offsetX or 0, cr.offsetY or -150)
    if crFrame.label then ApplyLabelFont(crFrame.label, ts) end

    if reincFrame then
        reincFrame:SetSize(sz, sz); reincFrame:SetAlpha(alpha)
        reincFrame:ClearAllPoints()
        reincFrame:SetPoint("LEFT", crFrame, "RIGHT", REINC_GAP, 0)
        if reincFrame.label then ApplyLabelFont(reincFrame.label, ts) end
    end
end

-- Guarda la posición tras un drag como offset relativo al CENTER de UIParent.
-- crFrame es hijo directo de UIParent con escala default, así que GetCenter()
-- de ambos comparte espacio de coordenadas — la resta da el offset directo.
local function SaveDraggedPosition()
    local cr = GetCR()
    if not cr or not crFrame then return end
    local fx, fy = crFrame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not (fx and fy and ux and uy) then return end
    cr.offsetX = math.floor(fx - ux + 0.5)
    cr.offsetY = math.floor(fy - uy + 0.5)
    cr.placed = true
end

local function CreateIconFrame(name, spellID, draggable)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetFrameStrata("MEDIUM"); f:SetFrameLevel(150)
    f:EnableMouse(true) -- siempre, para captar click derecho (config) y drag en move mode
    f:Hide()

    local border = f:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -2, 2); border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0, 0, 0, 0.85)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local tex = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or BREZ_FALLBACK_ICON
    icon:SetTexture(tex)
    f.icon = icon

    -- Texto centrado: número/estado o countdown. El tamaño lo fija ApplyPlacement.
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER", f, "CENTER", 0, 0)
    label:SetShadowOffset(1, -1); label:SetShadowColor(0, 0, 0, 1)
    f.label = label

    if draggable then
        -- Highlight verde + hint visibles solo en modo mover.
        local hl = f:CreateTexture(nil, "OVERLAY")
        hl:SetPoint("TOPLEFT", -2, 2); hl:SetPoint("BOTTOMRIGHT", 2, -2)
        hl:SetColorTexture(0.2, 1, 0.2, 0.25)
        hl:Hide()
        f.moveHL = hl

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOP", f, "BOTTOM", 0, -2)
        hint:SetText(ns.L["Drag to move"])
        hint:SetTextColor(0.4, 1, 0.4)
        hint:Hide()
        f.moveHint = hint

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) if moveMode then self:StartMoving() end end)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            SaveDraggedPosition()
            ApplyPlacement()  -- normaliza anchors al CENTER+offset recién guardado
        end)
    end

    -- Click derecho → abre la config de esta feature. Solo fuera de combate (evita
    -- abrir la ventana en pleno pull y respeta el pedido de "solo OOC").
    f:SetScript("OnMouseUp", function(_, button)
        if button ~= "RightButton" then return end
        if InCombatLockdown and InCombatLockdown() then return end
        if ns.OpenConfigToPage then ns:OpenConfigToPage(ns.L["Miscellaneous"]) end
    end)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.L["Combat Resurrections"])
        GameTooltip:AddLine(ns.L["Right-click: open settings (out of combat)"], 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return f
end

-- Indicador de brez del grupo. Llamado por OnUpdate (poll) y por eventos.
local function UpdateCR()
    local f = crFrame
    if not f then return end
    local cr = GetCR()
    if not cr then f:Hide(); return end

    -- Modo mover: dummy "2" + bypassa el enable para poder ubicarlo antes de activar.
    if moveMode then
        f.icon:SetDesaturated(false)
        f.label:SetText("2")
        f.label:SetTextColor(0.4, 1, 0.4)
        if not f:IsShown() then f:Show() end
        return
    end

    -- Solo en raid / M+, pero SIEMPRE visible ahí (en o fuera de combate, haya
    -- boss activo o no). Fuera de ese contenido no hay pool de brez → oculto.
    if not cr.enabled or not InBrezContent() then f:Hide(); return end

    -- Aseguramos el tracker manual activo mientras estemos en el contenido (cubre
    -- /reload o eventos perdidos: si entramos sin que ningún evento lo activara).
    if not brez.active then BrezActivate() end

    local cur, max, start, dur = GetBrezCharges()
    if not cur then cur = 0 end  -- en content siempre mostramos; 0 → countdown

    if cur >= 1 then
        f.icon:SetDesaturated(false)
        f.label:SetText(tostring(cur))
        f.label:SetTextColor(0.4, 1, 0.4)
    else
        f.icon:SetDesaturated(true)
        local remaining = 0
        if start and dur and dur > 0 then
            remaining = (start + dur) - GetTime()
            if remaining < 0 then remaining = 0 end
        end
        f.label:SetText(FormatMMSS(remaining))
        f.label:SetTextColor(1, 0.45, 0.45)
    end

    if not f:IsShown() then f:Show() end
end

-- Indicador de Reencarnación (solo Chamán). Brillante = puede reencarnar;
-- apagado + countdown = cuánto falta para el próximo reencarnar.
local function UpdateReinc()
    local f = reincFrame
    if not f then return end
    local cr = GetCR()
    if not cr then f:Hide(); return end

    if moveMode then
        if HasReincarnation() and cr.showReincarnation ~= false then
            f.icon:SetDesaturated(false)
            f.label:SetText("")
            if not f:IsShown() then f:Show() end
        else
            f:Hide()
        end
        return
    end

    -- Igual que el de brez: solo en raid / M+, siempre visible ahí (regardless de
    -- combate). Requiere además conocer el hechizo de auto-res y no estar desactivado.
    if not cr.enabled or not InBrezContent() or not HasReincarnation() or cr.showReincarnation == false then
        f:Hide(); return
    end

    local start, dur = GetReincCooldown()
    local remaining = 0
    if type(start) == "number" and type(dur) == "number" and dur > 2 then
        remaining = (start + dur) - GetTime()
        if remaining < 0 then remaining = 0 end
    end

    if remaining > 0 then
        f.icon:SetDesaturated(true)
        f.label:SetText(FormatMMSS(remaining))
        f.label:SetTextColor(1, 0.45, 0.45)
    else
        f.icon:SetDesaturated(false)
        f.label:SetText("")
    end

    if not f:IsShown() then f:Show() end
end

local function UpdateAll()
    UpdateCR()
    UpdateReinc()
end

-- Reaplica placement + refresca contenido. Lo llama la config al mover sliders.
function ns:RefreshMiscCombatRes()
    ApplyPlacement()
    UpdateAll()
end

-- Activa/desactiva el modo mover (drag libre). En move: mouse on + highlight +
-- hint + dummy. Al fijar: guarda placed=true y vuelve al display normal.
function ns:SetMiscCombatResMove(on)
    moveMode = on and true or false
    if crFrame then
        -- Mouse queda siempre activo (para el click derecho); solo el SetMovable y
        -- el highlight dependen del modo mover.
        crFrame:SetMovable(moveMode)
        if crFrame.moveHL then crFrame.moveHL:SetShown(moveMode) end
        if crFrame.moveHint then crFrame.moveHint:SetShown(moveMode) end
    end
    if not moveMode then
        local cr = GetCR()
        if cr then cr.placed = true end  -- fijar cuenta como "ya ubicado"
    end
    ns:RefreshMiscCombatRes()
    return moveMode
end
function ns:ToggleMiscCombatResMove() return ns:SetMiscCombatResMove(not moveMode) end
function ns:IsMiscCombatResMoveShown() return moveMode end

function ns:InitMiscFeatures()
    crFrame = CreateIconFrame("HNZHealingToolsCombatResFrame", BREZ_SPELL_ID, true)
    reincFrame = CreateIconFrame("HNZHealingToolsReincFrame", REINC_SPELL_ID, false)
    ApplyPlacement()

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("SPELL_UPDATE_CHARGES")
    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("PLAYER_DEAD")
    ev:RegisterEvent("PLAYER_ALIVE")
    ev:RegisterEvent("PLAYER_UNGHOST")
    ev:RegisterEvent("GROUP_ROSTER_UPDATE")
    -- Estado del pool manual de brez:
    ev:RegisterEvent("ENCOUNTER_START")
    ev:RegisterEvent("ENCOUNTER_END")
    ev:RegisterEvent("CHALLENGE_MODE_START")
    ev:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    ev:RegisterEvent("CHALLENGE_MODE_RESET")
    ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    -- Aprender/olvidar el hechizo de auto-res o cambiar de spec puede cambiar si
    -- corresponde mostrar el icono de reinc → revalidar.
    ev:RegisterEvent("SPELLS_CHANGED")
    ev:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ev:SetScript("OnEvent", function(_, event)
        if event == "ENCOUNTER_START" then
            -- Pull de boss en raid: el pool se resetea a 1 carga.
            local _, itype = IsInInstance()
            if itype == "raid" then BrezActivate() end
        elseif event == "ENCOUNTER_END" then
            -- NO desactivamos: el icono debe seguir visible toda la estadía en el
            -- contenido. El pool sigue corriendo su recarga entre pulls.
        elseif event == "CHALLENGE_MODE_START" then
            BrezActivate()
        elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
            BrezDeactivate()
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Activa el pool al entrar a raid/M+ (cubre /reload mid-instancia) y lo
            -- desactiva al salir del contenido.
            if InBrezContent() then
                if not brez.active then BrezActivate() end
            else
                BrezDeactivate()
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if not brez.active then return end
            local _, sub, _, _, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
            if sub == "SPELL_RESURRECT" and spellID and BREZ_SPELLS[spellID] then
                BrezConsume()
            end
            return -- el poll de 0.25s repinta; no llamamos UpdateAll por cada línea de CLEU
        end
        UpdateAll()
    end)

    -- Poll de respaldo en el frame de eventos (NUNCA oculto). Los countdowns
    -- necesitan refrescarse continuo y los eventos de charges/cooldown no tickean
    -- cada segundo. Va aquí y no en los frames de icono porque OnUpdate no corre
    -- mientras un frame está Hide(). 0.25s, costo despreciable.
    local elapsed = 0
    ev:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.25 then
            elapsed = 0
            UpdateAll()
        end
    end)

    -- Primer arranque con esta funcionalidad: si la feature ya está activa pero el
    -- usuario nunca ubicó el icono (placed=false), abrimos el modo mover una vez
    -- para que lo posicione libremente. Marcamos placed=true en el acto para que
    -- el auto-unlock ocurra UNA sola vez (después se mueve con el botón).
    local cr = GetCR()
    if cr and cr.enabled and not cr.placed then
        cr.placed = true
        ns:SetMiscCombatResMove(true)
    else
        UpdateAll()
    end
end
