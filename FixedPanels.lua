local addonName, ns = ...

-- ============================================================
-- Fixed Panels
--
-- Paneles de iconos anclados a puntos fijos de pantalla (movibles por drag), con
-- la MISMA logica de tracking/render que el Cursor Display pero SIN seguir al
-- mouse. Cada panel (ns.db.fixedPanels.panels[i]) agrupa sus propias listas
-- panel.spells / panel.auras (mismo schema que cursorSpells/cursorAuras) y tiene
-- su propia posicion y ajustes de grid.
--
-- Reuso: el render por-icono (charges, stacks, status colors, aviso de
-- expiracion, overrides per-entry) y la decision de "que mostrar + status" viven
-- en CursorDisplay.lua y se exponen como:
--   ns.CreateTrackedIconFrame(parent, cfg)
--   ns.RenderTrackedIcon(iconFrame, data, entry, expiring, cfg)
--   ns.EvalCursorSpellEntry(entry, inCombat) -> status, show
--   ns.EvalCursorAuraEntry(entry, inCombat)  -> status, show, expiring
-- `cfg` aqui es el panel mismo (provee iconSize/fontSize/opacity).
--
-- Posicion: offset desde el CENTER de UIParent (panel.x / panel.y), mismo
-- contrato que el fixed display del MRT — estable ante cambios de resolucion.
-- ============================================================

local function GetCfg() return ns.db and ns.db.fixedPanels end

local driverFrame                 -- master OnUpdate (cadencia event-driven)
local states = {}                 -- panel(table) -> { frame, iconPool, unlocked }
local dataElapsed = 0
local inCombat = false
local masterVisible = true        -- toggle global (ns:ToggleFixedPanels)

-- Forward decls (se referencian dentro de closures definidos antes).
local PositionPanelFrame

-- ---------- helpers de campos del panel (defensivos con defaults) ----------
local function P_iconSize(p)    return tonumber(p.iconSize)    or 36 end
local function P_iconSpacing(p) return tonumber(p.iconSpacing) or 4 end
local function P_maxColumns(p)  return math.max(1, tonumber(p.maxColumns) or 8) end

-- ============================================================
-- Frame + mover por panel
-- ============================================================
local function EnsurePanelFrame(panel)
    local st = states[panel]
    if st then return st end

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(1, 1)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(false)
    f:SetAlpha(1)  -- el alpha real se aplica per-icono (override global/per-entry)

    -- Chrome visible solo en modo unlocked: caja translucida + borde + label, asi
    -- el panel se puede ver y arrastrar aunque no tenga iconos visibles ahora.
    f.moverBg = f:CreateTexture(nil, "BACKGROUND")
    f.moverBg:SetAllPoints(f)
    f.moverBg:SetColorTexture(0.1, 0.6, 1.0, 0.30)
    f.moverBg:Hide()
    f.moverBorder = f:CreateTexture(nil, "BORDER")
    f.moverBorder:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
    f.moverBorder:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
    f.moverBorder:SetColorTexture(0.3, 0.8, 1.0, 0.9)
    f.moverBorder:Hide()
    f.moverLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.moverLabel:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.moverLabel:Hide()

    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local pcx, pcy = UIParent:GetCenter()
        if cx and pcx then
            panel.x = math.floor((cx - pcx) + 0.5)
            panel.y = math.floor((cy - pcy) + 0.5)
        end
        -- StartMoving cambia el anchor a BOTTOMLEFT; re-anclar al contrato
        -- CENTER+offset para que el guardado quede consistente.
        local s = states[panel]
        if s then PositionPanelFrame(s, panel) end
    end)

    st = { frame = f, iconPool = {}, unlocked = false }
    states[panel] = st
    return st
end

function PositionPanelFrame(st, panel)  -- asigna al forward-decl local de arriba
    st.frame:ClearAllPoints()
    st.frame:SetPoint("CENTER", UIParent, "CENTER", tonumber(panel.x) or 0, tonumber(panel.y) or 0)
end

local function ApplyPanelMover(st, panel)
    local on = st.unlocked
    local f = st.frame
    f:EnableMouse(on)
    f.moverBg:SetShown(on)
    f.moverBorder:SetShown(on)
    f.moverLabel:SetShown(on)
    if on then
        f.moverLabel:SetText(panel.name or ns.L["Panel"] or "Panel")
        -- Garantizar un area agarrable aunque el panel no tenga iconos visibles.
        local min = P_iconSize(panel)
        if (f:GetWidth() or 0) < min or (f:GetHeight() or 0) < min then
            f:SetSize(min, min)
        end
        f:Show()
    end
end

-- ============================================================
-- Render de un panel: misma logica del cursor, anclada al frame fijo.
-- Devuelve true si algun icono tiene timer activo (para la cadencia del driver).
-- ============================================================
local function GetPanelIcon(st, index)
    local ic = st.iconPool[index]
    if ic then return ic end
    -- Pasamos el panel como cfg para que el tamaño/fuente inicial sea el del panel.
    ic = ns.CreateTrackedIconFrame(st.frame, st._cfgPanel)
    st.iconPool[index] = ic
    return ic
end

local function UpdatePanel(st, panel)
    st._cfgPanel = panel  -- usado por GetPanelIcon para el tamaño inicial
    local iconIndex = 0
    local anyTimer = false

    for _, entry in ipairs(panel.spells or {}) do
        local status, show = ns.EvalCursorSpellEntry(entry, inCombat)
        if status and status.cooldownRemaining and status.cooldownRemaining > 0 then anyTimer = true end
        if show then
            iconIndex = iconIndex + 1
            ns.RenderTrackedIcon(GetPanelIcon(st, iconIndex), status, entry, nil, panel)
        end
    end
    for _, entry in ipairs(panel.auras or {}) do
        local status, show, expiring = ns.EvalCursorAuraEntry(entry, inCombat)
        if status and status.remaining and status.remaining > 0 then anyTimer = true end
        if show then
            iconIndex = iconIndex + 1
            ns.RenderTrackedIcon(GetPanelIcon(st, iconIndex), status, entry, expiring, panel)
        end
    end

    -- Ocultar sobrantes del pool.
    for i = iconIndex + 1, #st.iconPool do st.iconPool[i]:Hide() end

    -- Layout grid (mismo esquema que el cursor): grid TOPLEFT col/row + detached
    -- (useCustomPosition) posicionados con offsetX/Y relativos al BOTTOMLEFT.
    local size = P_iconSize(panel)
    local spacing = P_iconSpacing(panel)
    local maxCols = P_maxColumns(panel)

    if iconIndex == 0 then
        -- Sin iconos: si esta unlocked dejamos un handle agarrable, si no 1x1.
        if not st.unlocked then st.frame:SetSize(1, 1) end
        return anyTimer
    end

    local gridCount = 0
    for i = 1, iconIndex do
        local e = st.iconPool[i]._entry
        if not (e and e.useCustomPosition) then gridCount = gridCount + 1 end
    end
    if gridCount > 0 then
        local cols = math.min(gridCount, maxCols)
        local rows = math.ceil(gridCount / maxCols)
        st.frame:SetSize(cols*(size+spacing)-spacing, rows*(size+spacing)-spacing)
    elseif not st.unlocked then
        st.frame:SetSize(1, 1)
    end

    local gridSlot = 0
    for i = 1, iconIndex do
        local ic = st.iconPool[i]
        local e = ic._entry
        ic:ClearAllPoints()
        if e and e.useCustomPosition then
            local ox = tonumber(e.offsetX) or 0
            local oy = tonumber(e.offsetY) or 0
            ic:SetPoint("BOTTOMLEFT", st.frame, "BOTTOMLEFT", ox, oy)
        else
            local col = gridSlot % maxCols
            local row = math.floor(gridSlot / maxCols)
            ic:SetPoint("TOPLEFT", st.frame, "TOPLEFT", col*(size+spacing), -row*(size+spacing))
            gridSlot = gridSlot + 1
        end
    end
    return anyTimer
end

-- ¿El panel debe mostrarse ahora? (master + enable feature + visibility del panel)
local function PanelShouldRender(panel)
    local cfg = GetCfg()
    if not (masterVisible and cfg and cfg.enabled) then return false end
    if panel.enabled == false then return false end
    return ns.MatchesVisibility(panel.visibility, inCombat)
end

-- ============================================================
-- Driver: recorre los paneles en la cadencia event-driven.
-- ============================================================
local function UpdateAll()
    local cfg = GetCfg()
    if not cfg then return false end
    local anyTimer = false
    for _, panel in ipairs(cfg.panels or {}) do
        local st = EnsurePanelFrame(panel)
        if PanelShouldRender(panel) then
            if UpdatePanel(st, panel) then anyTimer = true end
            st.frame:Show()
        else
            -- Oculto por visibility/enable: ocultar iconos y el frame (salvo que el
            -- usuario lo este moviendo — el mover manda).
            for _, ic in ipairs(st.iconPool) do ic:Hide() end
            if not st.unlocked then st.frame:Hide() end
        end
    end
    return anyTimer
end

local hasActiveTimer = false

function ns:InitFixedPanels()
    driverFrame = CreateFrame("Frame")
    inCombat = UnitAffectingCombat("player") and true or false

    -- Construir frames para los paneles existentes y posicionarlos.
    local cfg = GetCfg()
    if cfg then
        for _, panel in ipairs(cfg.panels or {}) do
            local st = EnsurePanelFrame(panel)
            PositionPanelFrame(st, panel)
        end
    end

    -- Estado de combate desde los eventos (no InCombatLockdown): igual que
    -- CursorDisplay, para que la visibility por-panel cambie al instante.
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then inCombat = false
        elseif event == "PLAYER_ENTERING_WORLD" then inCombat = UnitAffectingCombat("player") and true or false
        end
        if ns.MarkSpellDirty then ns:MarkSpellDirty() end
        if ns.MarkAuraDirty then ns:MarkAuraDirty() end
    end)

    driverFrame:SetScript("OnUpdate", function(_, elapsed)
        local c = GetCfg()
        if not (masterVisible and c and c.enabled) then return end
        if not c.panels or #c.panels == 0 then return end

        dataElapsed = dataElapsed + elapsed
        -- dirty o timer ticking => 0.1s; idle => 1s (fallback range checks).
        local interval = (ns._spellDirtyFixed or ns._auraDirtyFixed or hasActiveTimer) and 0.1 or 1.0
        if dataElapsed >= interval then
            dataElapsed = 0
            ns._spellDirtyFixed = false
            ns._auraDirtyFixed = false
            hasActiveTimer = UpdateAll()
        end
    end)
end

-- ============================================================
-- API publica para el Config
-- ============================================================

-- Reconstruye estados: poda paneles borrados, asegura frames nuevos, reposiciona
-- y fuerza un UpdateData. Llamar tras add/remove/reorder de paneles o entries.
function ns.RebuildFixedPanels()
    local cfg = GetCfg()
    if not cfg then return end
    -- Set de paneles vigentes para podar estados huerfanos.
    local live = {}
    for _, panel in ipairs(cfg.panels or {}) do
        live[panel] = true
        local st = EnsurePanelFrame(panel)
        PositionPanelFrame(st, panel)
    end
    for panel, st in pairs(states) do
        if not live[panel] then
            st.frame:Hide(); st.frame:SetParent(nil)
            states[panel] = nil
        end
    end
    if ns.MarkSpellDirty then ns:MarkSpellDirty() end
    if ns.MarkAuraDirty then ns:MarkAuraDirty() end
end

-- Mover on/off de UN panel (toggle). Devuelve el nuevo estado (true=unlocked).
function ns.FixedPanelToggleMover(panel)
    local st = EnsurePanelFrame(panel)
    st.unlocked = not st.unlocked
    PositionPanelFrame(st, panel)
    ApplyPanelMover(st, panel)
    if not st.unlocked then
        -- Al bloquear, re-renderizar para que el frame recupere su tamaño de grid.
        if ns.MarkSpellDirty then ns:MarkSpellDirty() end
        if ns.MarkAuraDirty then ns:MarkAuraDirty() end
    end
    return st.unlocked
end

function ns.FixedPanelIsUnlocked(panel)
    local st = states[panel]
    return st and st.unlocked or false
end

-- Bloquea todos los movers (al cerrar el Config, por prolijidad).
function ns.FixedPanelLockAll()
    for panel, st in pairs(states) do
        if st.unlocked then
            st.unlocked = false
            ApplyPanelMover(st, panel)
        end
    end
    if ns.MarkSpellDirty then ns:MarkSpellDirty() end
    if ns.MarkAuraDirty then ns:MarkAuraDirty() end
end

-- Re-aplica posicion desde panel.x/y (sliders del Config en vivo).
function ns.FixedPanelRefreshPos(panel)
    local st = states[panel]
    if st and not st.unlocked then PositionPanelFrame(st, panel) end
end

-- Llamado por el toggle de "Habilitar Funciones" (General). Aplica enable/disable
-- al instante: al deshabilitar, oculta los frames ya mostrados (el driver hace
-- early-out cuando esta off, asi que no los ocultaria por si mismo); al habilitar,
-- marca dirty para renderizar en el proximo tick.
function ns.RefreshFixedPanels()
    local cfg = GetCfg()
    if not cfg or not cfg.enabled then
        for _, st in pairs(states) do
            for _, ic in ipairs(st.iconPool) do ic:Hide() end
            if not st.unlocked then st.frame:Hide() end
        end
        return
    end
    if ns.MarkSpellDirty then ns:MarkSpellDirty() end
    if ns.MarkAuraDirty then ns:MarkAuraDirty() end
end

function ns:ToggleFixedPanels()
    masterVisible = not masterVisible
    if not masterVisible then
        for _, st in pairs(states) do st.frame:Hide() end
    else
        if ns.MarkSpellDirty then ns:MarkSpellDirty() end
        if ns.MarkAuraDirty then ns:MarkAuraDirty() end
    end
end
