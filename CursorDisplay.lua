local _, ns = ...

local displayFrame
local iconPool = {}
local dataElapsed = 0
local isVisible = true

-- Caches del hot path OnUpdate. Antes leiamos ns.db y llamabamos
-- UIParent:GetEffectiveScale() en cada frame; con el ring + display ambos
-- atados al cursor eso suma muy rapido (vimos 2% CPU sostenido). Estas
-- variables se invalidan en RefreshCursorDisplay y por eventos de scale.
-- No cacheamos #cursorSpells/#cursorAuras porque el flujo de Add* no llama
-- siempre a RefreshCursorDisplay y la invalidacion seria fragil; el costo
-- de esos `#` es trivial comparado con SetPoint.
local cachedScale          -- nil = recompute on next frame
local cachedOffsetX = 0
local cachedOffsetY = 0
local cachedUpdateInterval = 0.1
local cachedEnabled = false
-- Ultima posicion seteada en el frame; saltamos SetPoint cuando el cursor
-- no se ha movido apreciablemente (cursor quieto = 0 trabajo).
local lastSetX, lastSetY = -math.huge, -math.huge

local STATUS_COLORS = {
    READY={0,1,0}, ACTIVE={0,1,0}, COOLDOWN={1,0,0}, OUT_OF_RANGE={1,1,0},
    NO_POWER={0.5,0.5,1}, UNUSABLE={0.5,0.5,0.5}, MISSING={1,0.3,0.3},
}

local function ApplyFontSize(fontString, size)
    local font, _, flags = fontString:GetFont()
    if font then fontString:SetFont(font, size, flags or "OUTLINE") end
end

local function CreateIconFrame(parent, index)
    local size = ns.db.cursorDisplay.iconSize
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size); f:EnableMouse(false)

    local border = f:CreateTexture(nil,"BACKGROUND"); border:SetAllPoints(); border:SetColorTexture(0,0,0,1)
    f.border = border

    local icon = f:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("TOPLEFT",1,-1); icon:SetPoint("BOTTOMRIGHT",-1,1); icon:SetTexCoord(0.08,0.92,0.08,0.92)
    f.icon = icon

    local text = f:CreateFontString(nil,"OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, ns.db.cursorDisplay.fontSize or 12, "OUTLINE")
    text:SetPoint("CENTER",0,0); text:SetJustifyH("CENTER"); text:SetShadowOffset(1,-1)
    f.text = text

    local chargeText = f:CreateFontString(nil,"OVERLAY")
    chargeText:SetFont(STANDARD_TEXT_FONT, ns.db.cursorDisplay.fontSize or 12, "OUTLINE")
    chargeText:SetPoint("BOTTOMRIGHT",-1,1); chargeText:SetJustifyH("RIGHT"); chargeText:SetShadowOffset(1,-1)
    f.chargeText = chargeText

    local statusBorder = f:CreateTexture(nil,"OVERLAY")
    statusBorder:SetAllPoints(); statusBorder:SetColorTexture(1,1,1,0.3); statusBorder:SetBlendMode("ADD")
    f.statusBorder = statusBorder

    f:Hide()
    iconPool[index] = f
    return f
end

local function GetOrCreateIcon(index)
    if iconPool[index] then return iconPool[index] end
    return CreateIconFrame(displayFrame, index)
end

local function UpdateIconAppearance(iconFrame, data, entry)
    local size = ns.db.cursorDisplay.iconSize
    local fontSize = ns.db.cursorDisplay.fontSize or 12
    local stackFontSize = (entry and entry.stackFontSize and entry.stackFontSize > 0) and entry.stackFontSize or fontSize
    iconFrame:SetSize(size, size)
    iconFrame.icon:SetTexture(data.icon)

    local desat = (data.status=="UNUSABLE" or data.status=="MISSING" or data.status=="NO_POWER")
    iconFrame.icon:SetDesaturated(desat)

    local color = STATUS_COLORS[data.status] or STATUS_COLORS.UNUSABLE
    local overlayAlpha = (entry and entry.hideStatusOverlay) and 0 or 0.3
    iconFrame.statusBorder:SetColorTexture(color[1],color[2],color[3],overlayAlpha)

    ApplyFontSize(iconFrame.text, fontSize)
    ApplyFontSize(iconFrame.chargeText, stackFontSize)

    iconFrame.text:SetText("")
    iconFrame.chargeText:SetText(""); iconFrame.chargeText:Hide()

    if data.maxCharges and data.maxCharges > 1 then
        -- Multi-charge spell:
        --   Center = recharge timer ONLY when 0 charges (with charges available, timer is noise).
        --   Corner = charges count, only when > 1 (same style as aura stacks).
        -- Use ToPublic only — never fall back to raw value, which may be a SecureNumber
        -- that taints arithmetic (`> 0` throws "secret number value" and aborts the OnUpdate).
        local pubCharges = ns.ToPublic(data.charges)
        -- In combat, currentCharges sometimes arrives as a SecureNumber (ToPublic→nil) even
        -- though maxCharges stays public. When chargesFull is true we know current==max, so
        -- borrow pubMax as the displayable count instead of leaving the corner empty.
        if type(pubCharges) ~= "number" and data.chargesFull and type(data.maxCharges) == "number" then
            pubCharges = data.maxCharges
        end
        local hasCharges = type(pubCharges) == "number" and pubCharges > 0
        if not hasCharges and data.cooldownRemaining and data.cooldownRemaining > 0 then
            iconFrame.text:SetText(ns.FormatDuration(data.cooldownRemaining))
        end
        if type(pubCharges) == "number" and pubCharges > 1 then
            iconFrame.chargeText:SetText(pubCharges); iconFrame.chargeText:Show()
        end
    else
        if data.cooldownRemaining and data.cooldownRemaining > 0 then
            iconFrame.text:SetText(ns.FormatDuration(data.cooldownRemaining))
        elseif data.remaining and data.remaining > 0 then
            iconFrame.text:SetText(ns.FormatDuration(data.remaining))
        end
        if data.stacks and data.stacks > 1 then
            iconFrame.chargeText:SetText(data.stacks); iconFrame.chargeText:Show()
        end
    end
    if entry and entry.hideTimer then iconFrame.text:SetText("") end
    iconFrame:Show()
end

-- Reportado por UpdateData: true si algun spell/aura tiene timer ticking
-- (cooldownRemaining > 0 o aura.remaining > 0). El OnUpdate lo usa para decidir
-- si polea a fast rate (timer visible cuenta atras) o a slow rate (1 Hz idle).
local hasActiveTimer = false

local function UpdateData()
    local db = ns.db
    local iconIndex = 0
    local anyTimer = false

    for _, entry in ipairs(db.cursorSpells) do
        if entry.enabled and ns.IsEntryAllowedForCurrentSpec(entry) and ns.IsEntryAllowedForRequiredTalent(entry) then
            local status = ns:GetSpellStatus(entry.spellID)
            if status.cooldownRemaining and status.cooldownRemaining > 0 then anyTimer = true end
            local hide = entry.hideOnCooldown and status.status == "COOLDOWN"
            if not hide and entry.minCharges and entry.minCharges > 0 then
                local pubCharges = ns.ToPublic(status.charges)
                local pubMax = ns.ToPublic(status.maxCharges)
                if type(pubCharges) == "number" then
                    -- Best case: we have a public count.
                    if pubCharges < entry.minCharges then hide = true end
                elseif status.hasCharges and status.chargesFull ~= nil then
                    -- SN-tainted count, but isActive (public bool) is reliable:
                    -- chargesFull=true => current==max; chargesFull=false => current<max.
                    if status.chargesFull then
                        -- Full. If we know max publicly, gate on max>=minCharges; if not,
                        -- assume the user configured a sane minCharges and show.
                        if type(pubMax) == "number" and pubMax < entry.minCharges then hide = true end
                    else
                        -- At least one charge missing. We can only be sure to show when
                        -- minCharges <= max-1; without pubMax, hide to be safe (otherwise
                        -- a user with minCharges=2 on a 2-charge spell sees the icon at 1/2).
                        if type(pubMax) == "number" then
                            if entry.minCharges > (pubMax - 1) then hide = true end
                        else
                            hide = true
                        end
                    end
                end
                -- else: no charges info at all (single-target spell w/o charges) — leave as is.
            end
            if not hide then
                iconIndex = iconIndex + 1
                UpdateIconAppearance(GetOrCreateIcon(iconIndex), status, entry)
            end
        end
    end

    for _, entry in ipairs(db.cursorAuras) do
        if entry.enabled and ns.IsEntryAllowedForCurrentSpec(entry) and ns.IsEntryAllowedForRequiredTalent(entry) then
            local status = ns:GetAuraStatus(entry.spellID, entry.unit, entry.filter, entry.manualDuration)
            if status.remaining and status.remaining > 0 then anyTimer = true end
            local showWhen = entry.showWhen or "ALWAYS"
            local show = false
            if showWhen=="ALWAYS" then show=true
            elseif showWhen=="MISSING" then show=(status.status=="MISSING")
            elseif showWhen=="ACTIVE" then show=(status.status=="ACTIVE")
            elseif showWhen=="BELOW_STACKS" then show=(status.status=="MISSING") or (status.stacks<(entry.minStacks or 0))
            end
            if show then
                iconIndex = iconIndex + 1
                UpdateIconAppearance(GetOrCreateIcon(iconIndex), status, entry)
            end
        end
    end

    for i = iconIndex+1, #iconPool do iconPool[i]:Hide() end

    hasActiveTimer = anyTimer

    if iconIndex == 0 then displayFrame:SetSize(1,1); return end

    local size = db.cursorDisplay.iconSize
    local spacing = db.cursorDisplay.iconSpacing
    local maxCols = db.cursorDisplay.maxColumns
    local cols = math.min(iconIndex, maxCols)
    local rows = math.ceil(iconIndex / maxCols)
    displayFrame:SetSize(cols*(size+spacing)-spacing, rows*(size+spacing)-spacing)

    for i = 1, iconIndex do
        local col = (i-1) % maxCols
        local row = math.floor((i-1) / maxCols)
        local f = iconPool[i]
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", col*(size+spacing), -row*(size+spacing))
    end
end

local inCombat = false

-- Recarga todos los caches del hot path desde ns.db. Se llama cuando algo
-- relevante cambia (config refresh, add/remove de spells/auras).
local function RefreshHotCaches()
    local d = ns.db and ns.db.cursorDisplay
    if not d then return end
    cachedOffsetX = d.offsetX or 0
    cachedOffsetY = d.offsetY or 0
    cachedUpdateInterval = d.updateInterval or 0.1
    cachedEnabled = d.enabled and true or false
    -- Force re-anchor en el siguiente frame (offsets pueden haber cambiado).
    lastSetX, lastSetY = -math.huge, -math.huge
end

ns.RefreshCursorDisplayHotCaches = RefreshHotCaches

local function ApplyCursorVisibility()
    if not displayFrame then return end
    local shouldShow = isVisible and ns.db.cursorDisplay.enabled
        and ns.MatchesVisibility(ns.db.cursorDisplay.visibility, inCombat)
    displayFrame:SetShown(shouldShow and true or false)
end

function ns:InitCursorDisplay()
    displayFrame = CreateFrame("Frame","HNZHealingToolsCursorFrame",UIParent)
    displayFrame:SetFrameStrata("TOOLTIP"); displayFrame:SetFrameLevel(100)
    displayFrame:SetSize(1,1); displayFrame:EnableMouse(false)
    displayFrame:SetAlpha(ns.db.cursorDisplay.opacity)

    -- Anchor inicial via SetPoint (sin ClearAllPoints): los SetPoint sucesivos
    -- en el OnUpdate reemplazan este punto in-place.
    displayFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)

    inCombat = UnitAffectingCombat("player") and true or false
    RefreshHotCaches()
    ApplyCursorVisibility()

    -- Cache de UI scale invalidado por eventos en lugar de UIParent:GetEffectiveScale()
    -- en cada frame (era una de las llamadas calientes).
    local scaleFrame = CreateFrame("Frame")
    scaleFrame:RegisterEvent("UI_SCALE_CHANGED")
    scaleFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    scaleFrame:SetScript("OnEvent", function() cachedScale = nil end)

    -- Track combat state from the events themselves, not InCombatLockdown(): the
    -- lockdown flag only "roughly" matches PLAYER_REGEN_DISABLED/ENABLED and can
    -- briefly disagree, leaving the display stuck hidden after combat starts.
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    combatFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then inCombat = false
        elseif event == "PLAYER_ENTERING_WORLD" then inCombat = UnitAffectingCombat("player") and true or false
        end
        ApplyCursorVisibility()
    end)

    displayFrame:SetScript("OnUpdate", function(self, elapsed)
        if not isVisible or not cachedEnabled then return end
        local cs, ca = ns.db.cursorSpells, ns.db.cursorAuras
        if (not cs or #cs == 0) and (not ca or #ca == 0) then return end

        if not cachedScale then
            cachedScale = UIParent:GetEffectiveScale()
            if not cachedScale or cachedScale == 0 then cachedScale = nil; return end
        end
        local cx, cy = GetCursorPosition()
        cx = cx / cachedScale + cachedOffsetX
        cy = cy / cachedScale + cachedOffsetY

        -- Skip SetPoint cuando el cursor no se ha movido (>= 0.5 px). Los SetPoint
        -- triggean re-layout interno; con el cursor quieto este OnUpdate ya no
        -- toca el frame y el costo cae a casi 0.
        local dx, dy = cx - lastSetX, cy - lastSetY
        if dx >= 0.5 or dx <= -0.5 or dy >= 0.5 or dy <= -0.5 then
            self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx, cy)
            lastSetX, lastSetY = cx, cy
        end

        -- Polling event-driven: antes UpdateData corria a cachedUpdateInterval (10 Hz)
        -- haciendo ~7 API calls por hechizo en cada tick, incluso cuando todo estaba
        -- READY y ningun evento habia ocurrido. Los flags spellDirty/auraDirty se
        -- activaban en eventos pero NO se consumian aqui. Ahora:
        --   - Si dirty o hay timer en curso (CD/aura ticking) => poll a cachedUpdateInterval
        --   - Idle (READY estatico): poll a IDLE_INTERVAL (1 Hz) como fallback para
        --     range checks (que no disparan eventos fiables)
        -- Resultado: fuera de combate, sin CDs, ~10x menos work.
        dataElapsed = dataElapsed + elapsed
        local interval = (ns._spellDirtyCursor or ns._auraDirtyCursor or hasActiveTimer)
            and cachedUpdateInterval or 1.0
        if dataElapsed >= interval then
            dataElapsed = 0
            ns._spellDirtyCursor = false
            ns._auraDirtyCursor = false
            UpdateData()
        end
    end)
end

function ns:ToggleCursorDisplay()
    isVisible = not isVisible
    ApplyCursorVisibility()
end

function ns:RefreshCursorDisplay()
    if displayFrame then displayFrame:SetAlpha(ns.db.cursorDisplay.opacity) end
    RefreshHotCaches()
    ApplyCursorVisibility()
end

function ns:DumpCursorStatus()
    print("|cff00ccff[SAT cursor]|r")
    if not displayFrame then print("  displayFrame: nil (not initialized)"); return end
    print(string.format("  displayFrame:IsShown=%s  IsVisible=%s  IsProtected=%s",
        tostring(displayFrame:IsShown()), tostring(displayFrame:IsVisible()), tostring(displayFrame:IsProtected())))
    print(string.format("  parent=%s  parentShown=%s  strata=%s  level=%d  alpha=%.2f",
        tostring(displayFrame:GetParent() and displayFrame:GetParent():GetName() or "?"),
        tostring(displayFrame:GetParent() and displayFrame:GetParent():IsShown()),
        displayFrame:GetFrameStrata(), displayFrame:GetFrameLevel(), displayFrame:GetAlpha()))
    print(string.format("  isVisible(local)=%s  enabled=%s  visibility=%s  inCombat(local)=%s  InCombatLockdown=%s  UnitAffectingCombat=%s",
        tostring(isVisible), tostring(ns.db.cursorDisplay.enabled),
        tostring(ns.db.cursorDisplay.visibility), tostring(inCombat),
        tostring(InCombatLockdown()), tostring(UnitAffectingCombat("player"))))
    local visible = 0
    for i, f in ipairs(iconPool) do if f:IsShown() then visible = visible + 1 end end
    print(string.format("  iconPool=%d  visibleIcons=%d  cursorSpells=%d  cursorAuras=%d",
        #iconPool, visible, #ns.db.cursorSpells, #ns.db.cursorAuras))
    print(string.format("  dataElapsed=%.3f  updateInterval=%.3f  hasOnUpdate=%s",
        dataElapsed, ns.db.cursorDisplay.updateInterval, tostring(displayFrame:GetScript("OnUpdate") ~= nil)))
    local cx, cy = GetCursorPosition()
    print(string.format("  cursor=(%d,%d)  uiScale=%.3f", cx or -1, cy or -1, UIParent:GetEffectiveScale()))
end
