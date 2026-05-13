local addonName, ns = ...

function ns:InitConfig()
    SLASH_HNZHEALINGTOOLS1 = "/hht"
    SLASH_HNZHEALINGTOOLS2 = "/hnz"
    SlashCmdList["HNZHEALINGTOOLS"] = function(msg)
        local cmd, rest = msg:match("^(%S+)%s*(.*)$")
        cmd = cmd and cmd:lower() or ""
        if cmd == "toggle" then ns:ToggleCursorDisplay(); ns:ToggleRingDisplay()
        elseif cmd == "debug" then ns:DebugSpell(rest)
        elseif cmd == "auradebug" then ns:DebugAura(rest)
        elseif cmd == "cdm" then ns:DumpCdm()
        elseif cmd == "status" then ns:DumpCursorStatus(); ns:DumpRingStatus()
        elseif cmd == "minimap" then if ns.ToggleMinimapButton then ns:ToggleMinimapButton() end
        else ns:ToggleConfigWindow() end
    end
    ns:CreateConfigWindow()
end

-- ============================================================
-- Add helpers
-- ============================================================

function ns:AddCursorSpell(input)
    local spellID, name = ns.GetSpellIDFromInput(input)
    if not spellID then return false, ns.L["Spell not found: "]..tostring(input) end
    if ns.FindSpellEntry(ns.db.cursorSpells, spellID) then return false, name..ns.L[" already monitored."] end
    table.insert(ns.db.cursorSpells, {spellID=spellID, enabled=true})
    ns:MarkSpellDirty()
    return true, name
end

function ns:AddCursorAura(input, unit, filter, showWhen, minStacks, manualDuration)
    local spellID, name = ns.GetSpellIDFromInput(input)
    if not spellID then return false, ns.L["Spell not found: "]..tostring(input) end
    if ns.FindSpellEntry(ns.db.cursorAuras, spellID) then return false, name..ns.L[" already monitored."] end
    table.insert(ns.db.cursorAuras, {spellID=spellID, unit=unit or "target", filter=filter or "HELPFUL", enabled=true, showWhen=showWhen or "ALWAYS", minStacks=minStacks or 0, manualDuration=manualDuration or 0})
    ns:MarkAuraDirty()
    return true, name
end

function ns:AddRingAura(input, unit, filter, showWhen, minStacks, color, manualDuration, showIcon)
    local spellID, name = ns.GetSpellIDFromInput(input)
    if not spellID then return false, ns.L["Spell not found: "]..tostring(input) end
    if ns.FindSpellEntry(ns.db.ringAuras, spellID) then return false, name..ns.L[" already monitored."] end
    table.insert(ns.db.ringAuras, {spellID=spellID, unit=unit or "player", filter=filter or "HELPFUL", enabled=true,
        showWhen=showWhen or "ACTIVE", minStacks=minStacks or 0, color=color or ns:GetNextRingColor(),
        manualDuration=manualDuration or 0, showIcon=showIcon or false})
    ns:MarkAuraDirty()
    return true, name
end

function ns:AddPulseSpell(input)
    local spellID, name = ns.GetSpellIDFromInput(input)
    if not spellID then return false, ns.L["Spell not found: "]..tostring(input) end
    ns.db.pulseSpells = ns.db.pulseSpells or {}
    if ns.FindSpellEntry(ns.db.pulseSpells, spellID) then return false, name..ns.L[" already monitored."] end
    table.insert(ns.db.pulseSpells, {spellID=spellID, enabled=true, soundEnabled=false, soundName="Default", soundChannel="Master"})
    return true, name
end

function ns:AddPulseAura(input, unit, filter)
    local spellID, name = ns.GetSpellIDFromInput(input)
    if not spellID then return false, ns.L["Spell not found: "]..tostring(input) end
    ns.db.pulseAuras = ns.db.pulseAuras or {}
    if ns.FindSpellEntry(ns.db.pulseAuras, spellID) then return false, name..ns.L[" already monitored."] end
    table.insert(ns.db.pulseAuras, {spellID=spellID, unit=unit or "player", filter=filter or "HELPFUL", enabled=true, soundEnabled=false, soundName="Default", soundChannel="Master"})
    return true, name
end

-- ============================================================
-- DandersFrames-inspired theming (paleta + helpers)
-- ============================================================

local C_BG       = {r=0.08, g=0.08, b=0.08, a=0.97}
local C_PANEL    = {r=0.12, g=0.12, b=0.12, a=1}
local C_ELEMENT  = {r=0.18, g=0.18, b=0.18, a=1}
local C_BORDER   = {r=0.25, g=0.25, b=0.25, a=1}
local C_HOVER    = {r=0.22, g=0.22, b=0.22, a=1}
local C_ACCENT   = {r=0.20, g=0.82, b=0.68, a=1}  -- teal/mint, distinto al violeta de DandersFrames
local C_TEXT     = {r=0.90, g=0.90, b=0.90, a=1}
local C_TEXT_DIM = {r=0.60, g=0.60, b=0.60, a=1}
ns._theme = {BG=C_BG, PANEL=C_PANEL, ELEMENT=C_ELEMENT, BORDER=C_BORDER, HOVER=C_HOVER, ACCENT=C_ACCENT, TEXT=C_TEXT, TEXT_DIM=C_TEXT_DIM}

-- Lista de sonidos disponibles para "Sonar al activarse" (per-aura).
-- IDs estables de Blizzard SOUNDKIT; el usuario puede añadir más editando esta tabla.
local SOUND_OPTIONS = {
    {label="Ready Check",    value=8959},
    {label="Raid Warning",   value=8960},
    {label="Achievement",    value=12867},
    {label="Bell",           value=8174},
    {label="Auction Open",   value=4115},
    {label="Quest Add",      value=6192},
    {label="Map Ping",       value=1115},
    {label="Level Up",       value=888},
}
ns.SOUND_OPTIONS = SOUND_OPTIONS

local function PanelBackdrop(f)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    f:SetBackdropColor(C_BG.r, C_BG.g, C_BG.b, C_BG.a)
    f:SetBackdropBorderColor(0, 0, 0, 1)
end

local function SubPanelBackdrop(f, alpha)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    f:SetBackdropColor(C_PANEL.r, C_PANEL.g, C_PANEL.b, alpha or 0.5)
    f:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.5)
end

local function ElementBackdrop(f)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    f:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, C_ELEMENT.a)
    f:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.5)
end

local function StyleScrollBar(scrollFrame)
    local sb = scrollFrame.ScrollBar
    if not sb then return end
    if sb.Background then sb.Background:Hide() end
    if sb.Track then
        if sb.Track.Begin then sb.Track.Begin:Hide() end
        if sb.Track.End then sb.Track.End:Hide() end
        if sb.Track.Middle then sb.Track.Middle:Hide() end
    end
    if sb.Thumb then
        if sb.Thumb.Begin then sb.Thumb.Begin:Hide() end
        if sb.Thumb.End then sb.Thumb.End:Hide() end
        if sb.Thumb.Middle then sb.Thumb.Middle:Hide() end
        if not sb.Thumb._satBg then
            local t = sb.Thumb:CreateTexture(nil, "ARTWORK")
            t:SetAllPoints(); t:SetColorTexture(0.4, 0.4, 0.4, 0.8)
            sb.Thumb._satBg = t
        end
    end
    if sb.Back then sb.Back:Hide(); sb.Back:SetSize(1,1) end
    if sb.Forward then sb.Forward:Hide(); sb.Forward:SetSize(1,1) end
    sb:SetWidth(10)
end

-- Show the scrollbar only when content overflows (visualmente más limpio).
local function AutoHideScrollBar(scrollFrame)
    local sb = scrollFrame.ScrollBar
    if not sb then return end
    local function update()
        local range = scrollFrame:GetVerticalScrollRange() or 0
        if range > 0.5 then sb:Show() else sb:Hide() end
    end
    scrollFrame:HookScript("OnScrollRangeChanged", function(_, _, _) update() end)
    scrollFrame:HookScript("OnSizeChanged", update)
    C_Timer.After(0, update)
end

-- Recorta la altura del scroll-child al contenido real. Se usa en OnShow del page
-- scrollframe para que el cálculo se haga cuando GetTop()/GetBottom() ya devuelven
-- coordenadas válidas (las páginas ocultas las devuelven nil).
local function FitScrollChildHeightNow(pc, pad)
    local pcTop = pc:GetTop()
    if not pcTop then return false end
    local lowest = pcTop
    for _, child in ipairs({pc:GetChildren()}) do
        if child.IsShown and child:IsShown() and child.GetBottom then
            local b = child:GetBottom()
            if b and b < lowest then lowest = b end
        end
    end
    for i = 1, pc:GetNumRegions() do
        local r = select(i, pc:GetRegions())
        if r and r.IsShown and r:IsShown() and r.GetBottom then
            local b = r:GetBottom()
            if b and b < lowest then lowest = b end
        end
    end
    local h = pcTop - lowest + (pad or 20)
    if h > 50 then pc:SetHeight(h) end
    return true
end

-- ============================================================
-- Skinners para templates Blizzard (UIPanelButton, InputBox, UICheckButton, OptionsSlider)
-- ============================================================

-- En Retail moderno UIPanelButtonTemplate usa atlas, no fileID — hay que limpiar
-- texture Y atlas en cada estado para que el botón quede realmente plano.
local function StripTextures(frame)
    local function clear(tex)
        if tex then
            if tex.SetTexture then tex:SetTexture(nil) end
            if tex.SetAtlas then tex:SetAtlas(nil) end
            if tex.SetVertexColor then tex:SetVertexColor(1,1,1,0) end
        end
    end
    if frame.GetNormalTexture   then clear(frame:GetNormalTexture())   end
    if frame.GetPushedTexture   then clear(frame:GetPushedTexture())   end
    if frame.GetHighlightTexture then clear(frame:GetHighlightTexture()) end
    if frame.GetDisabledTexture then clear(frame:GetDisabledTexture()) end
    if frame.GetCheckedTexture  then clear(frame:GetCheckedTexture())  end
    if frame.GetDisabledCheckedTexture then clear(frame:GetDisabledCheckedTexture()) end
    for i = 1, frame:GetNumRegions() do
        local r = select(i, frame:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "Texture" then
            if r.SetTexture then r:SetTexture(nil) end
            if r.SetAtlas then r:SetAtlas(nil) end
        end
    end
end

-- ===== Botón plano desde cero (sin template Blizzard) =====
-- Usar este factory en vez de skinear UIPanelButtonTemplate: en Retail Midnight el
-- template usa 9-slice + atlas que no se quitan del todo y reaparecen.
local function MakeButton(parent, w, h, label)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    if w and h then b:SetSize(w, h) end
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    b:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
    b:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER")
    fs:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    b:SetFontString(fs)
    if label then b:SetText(label) end

    b:SetScript("OnEnter", function(s) if s:IsEnabled() then s:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 1); s:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9) end end)
    b:SetScript("OnLeave", function(s) if s:IsEnabled() then s:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1); s:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7) end end)
    b:SetScript("OnMouseDown", function(s) if s:IsEnabled() then fs:ClearAllPoints(); fs:SetPoint("CENTER", 1, -1) end end)
    b:SetScript("OnMouseUp", function(s) fs:ClearAllPoints(); fs:SetPoint("CENTER", 0, 0) end)

    local origEnable, origDisable = b.Enable, b.Disable
    b.Enable = function(self)
        origEnable(self)
        fs:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
        self:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
        self:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7)
    end
    b.Disable = function(self)
        origDisable(self)
        fs:SetTextColor(0.45, 0.45, 0.45)
        self:SetBackdropColor(C_BG.r, C_BG.g, C_BG.b, 0.5)
        self:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.3)
    end
    return b
end

-- ===== EditBox plano desde cero =====
local function MakeEditBox(parent, w, h)
    local e = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    e:SetSize(w or 180, h or 20)
    e:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    e:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
    e:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.6)
    e:SetAutoFocus(false)
    e:SetFontObject("ChatFontNormal")
    e:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    e:SetTextInsets(6, 6, 0, 0)
    e:SetScript("OnEditFocusGained", function(s) s:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1) end)
    e:SetScript("OnEditFocusLost", function(s) s:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.6) end)
    e:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    return e
end

-- Compatibilidad: SkinButton/SkinEditBox quedan como no-op para llamadas legacy.
local function SkinButton(b) end
local function SkinEditBox(e) end

local function SkinCheck(ck)
    if not ck then return end
    StripTextures(ck)
    if not ck.SetBackdrop then Mixin(ck, BackdropTemplateMixin) end
    ck:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    ck:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
    ck:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7)
    if not ck._satCheckMark then
        local m = ck:CreateTexture(nil, "OVERLAY")
        m:SetPoint("TOPLEFT", 4, -4); m:SetPoint("BOTTOMRIGHT", -4, 4)
        m:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
        ck._satCheckMark = m
    end
    local function Apply() ck._satCheckMark:SetShown(ck:GetChecked() and true or false) end
    Apply()
    -- El click toggle del CheckButton ocurre en C++ y no llama el método Lua SetChecked,
    -- así que hooksecurefunc(SetChecked) no se dispara con clicks. Y un HookScript("OnClick")
    -- puede quedar fuera del flujo si el call site usa SetScript("OnClick", ...) después.
    -- PostClick siempre corre tras el OnClick handler y no lo sobreescribe nadie.
    ck:SetScript("PostClick", Apply)
    hooksecurefunc(ck, "SetChecked", Apply)
    ck:HookScript("OnEnter", function(s) s:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1) end)
    ck:HookScript("OnLeave", function(s) s:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7) end)
end

local function SkinSlider(s)
    if not s then return end
    if not s.SetBackdrop then Mixin(s, BackdropTemplateMixin) end
    s:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    s:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
    s:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.6)
    local thumb = s:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
        thumb:SetVertexColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
        thumb:SetSize(8, 16)
    end
    if s.Low then s.Low:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b) end
    if s.High then s.High:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b) end
    if s.Text then s.Text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b) end
end

ns._skin = {Button=SkinButton, EditBox=SkinEditBox, Check=SkinCheck, Slider=SkinSlider}

-- ============================================================
-- Shared UI Widgets
-- ============================================================

local function CreateSlider(parent, label, min, max, step, getValue, setValue)
    local c = CreateFrame("Frame",nil,parent); c:SetSize(280,45)
    local t = c:CreateFontString(nil,"OVERLAY","GameFontNormal"); t:SetPoint("TOPLEFT",0,0); t:SetText(label)
    t:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local s = CreateFrame("Slider",nil,c,"OptionsSliderTemplate"); s:SetPoint("TOPLEFT",0,-18); s:SetSize(200,12)
    s:SetMinMaxValues(min,max); s:SetValueStep(step); s:SetObeyStepOnDrag(true); s:SetValue(getValue())
    s.Low:SetText(min); s.High:SetText(max)
    SkinSlider(s)
    local v = c:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); v:SetPoint("LEFT",s,"RIGHT",8,0)
    v:SetText(string.format(step<1 and "%.2f" or "%d",getValue()))
    v:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)
    s:SetScript("OnValueChanged",function(self,val) val=math.floor(val/step+0.5)*step; setValue(val)
        v:SetText(string.format(step<1 and "%.2f" or "%d",val)) end)
    c.Refresh=function(self) s:SetValue(getValue()); v:SetText(string.format(step<1 and "%.2f" or "%d",getValue())) end
    return c
end

local function CreateCheckbox(parent, label, getValue, setValue)
    local ck = CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate"); ck:SetSize(18,18)
    SkinCheck(ck)
    ck.text = ck:CreateFontString(nil,"OVERLAY","GameFontNormal"); ck.text:SetPoint("LEFT",ck,"RIGHT",6,0); ck.text:SetText(label)
    ck.text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    ck:SetChecked(getValue()); ck:SetScript("OnClick",function(self) setValue(self:GetChecked()) end)
    ck.Refresh=function(self) self:SetChecked(getValue()) end
    return ck
end

-- Caja de texto multilínea con scroll, pensada para pegar/copiar strings largos
-- (export/import de perfiles). Devuelve un Frame con `.editbox` y `.scroll` accesibles.
local function MultilineBox(parent, w, h)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(w, h)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    frame:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
    frame:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.6)

    local sf = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 4, -4); sf:SetPoint("BOTTOMRIGHT", -22, 4)
    StyleScrollBar(sf); AutoHideScrollBar(sf)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    eb:SetWidth(w - 30)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self)
        frame:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        frame:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.6)
    end)
    sf:SetScrollChild(eb)

    -- click en cualquier zona del marco → enfoca el editbox
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function() eb:SetFocus() end)

    frame.editbox = eb
    frame.scroll = sf
    return frame
end

local function H(parent, text) local h=parent:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); h:SetText(text); h:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b); return h end
local function SubH(parent, text) local h=parent:CreateFontString(nil,"OVERLAY","GameFontNormal"); h:SetText(text); h:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b); return h end
local function Btn(parent, text, w, h) return MakeButton(parent, w or 80, h or 22, text) end
local function EditBox(parent, w) return MakeEditBox(parent, w or 180, 20) end

-- Attach a suggestions popup to a spell-name EditBox: while it has focus and a
-- non-numeric query is typed, show known player spells whose name contains it.
-- Click a row to fill the editbox with the spell name.
local function AttachSpellAutocomplete(eb)
    local popup = CreateFrame("Frame", nil, eb, "BackdropTemplate")
    PanelBackdrop(popup)
    local w = math.max(eb:GetWidth() + 14, 280)
    popup:SetSize(w, 220)
    popup:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", -8, -4)
    popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetToplevel(true); popup:EnableMouse(true)
    -- Frame level explicito muy alto: sin esto el popup compartia FULLSCREEN_DIALOG
    -- con los dropdowns Unit/Type/Show del editor (creados despues del EditBox), y
    -- al estar en el mismo strata + nivel, los botones de los dropdowns se
    -- renderizaban encima de las filas del autocomplete. Subiendo el nivel a 500
    -- garantiza que el popup quede por encima de cualquier hermano del editor.
    popup:SetFrameLevel(500)
    popup:Hide()

    local sf = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6); sf:SetPoint("BOTTOMRIGHT", -16, 6)
    StyleScrollBar(sf); AutoHideScrollBar(sf)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(w-22, 1); sf:SetScrollChild(content)

    local rowPool = {}
    local lastShown = 0
    local suppressNext = false

    local function Refresh()
        if suppressNext then suppressNext=false; popup:Hide(); return end
        -- Si el usuario editó el texto desde la última selección, invalidar el ID
        -- resuelto para que el callsite vuelva al lookup por nombre.
        if eb._satResolvedName and eb:GetText() ~= eb._satResolvedName then
            eb._satResolvedID = nil; eb._satResolvedName = nil
        end
        if not eb:HasFocus() or not eb:IsEnabled() then popup:Hide(); return end
        local q = (eb:GetText() or ""):lower():gsub("^%s+",""):gsub("%s+$","")
        if q == "" or tonumber(q) then popup:Hide(); return end
        local spells = ns.GetPlayerSpells and ns.GetPlayerSpells() or {}
        local n, y = 0, 0
        for _, s in ipairs(spells) do
            if (s.lowerName or s.name:lower()):find(q, 1, true) then
                n = n + 1
                if n > 50 then break end
                local b = rowPool[n]
                if not b then
                    b = CreateFrame("Button", nil, content); b:SetSize(w-26, 22)
                    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(0.3,0.5,0.8,0.3)
                    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(18,18); b.icon:SetPoint("LEFT", 4, 0); b.icon:SetTexCoord(0.08,0.92,0.08,0.92)
                    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0); b.text:SetPoint("RIGHT", -4, 0); b.text:SetJustifyH("LEFT")
                    rowPool[n] = b
                end
                b.icon:SetTexture(s.icon)
                local tail = (s.source ~= "" and (" |cff666666[" .. ns.L[s.source] .. "]|r") or "") .. " |cff555555#" .. s.spellID .. "|r"
                b.text:SetText(s.name .. tail)
                b.spell = s
                b:SetScript("OnClick", function(self)
                    suppressNext = true
                    eb:SetText(self.spell.name)
                    -- Memorizamos el spellID confirmado por el autocomplete: C_Spell.GetSpellInfo
                    -- por nombre falla con spells que el jugador no conoce (Pulse Auras suele
                    -- monitorear debuffs del enemigo) o con nombres con tildes/diacríticos.
                    eb._satResolvedID = self.spell.spellID
                    eb._satResolvedName = self.spell.name
                    eb:ClearFocus()
                    popup:Hide()
                end)
                b:SetPoint("TOPLEFT", 4, -y); b:Show()
                y = y + 24
            end
        end
        for i = n + 1, lastShown do
            local b = rowPool[i]; if b then b:Hide() end
        end
        lastShown = n
        content:SetHeight(math.max(1, y))
        if n == 0 then
            popup:Hide()
        else
            -- Altura dinamica: minimo entre 220 y el contenido + 12 px de padding.
            -- Asi con pocas sugerencias el popup no tapa los botones del modal.
            popup:SetHeight(math.min(220, y + 12))
            popup:Show()
        end
    end

    eb:HookScript("OnTextChanged", Refresh)
    eb:HookScript("OnEditFocusGained", Refresh)
    eb:HookScript("OnEscapePressed", function() popup:Hide() end)
    eb:HookScript("OnEditFocusLost", function()
        C_Timer.After(0.15, function()
            if not popup:IsMouseOver() and not eb:HasFocus() then popup:Hide() end
        end)
    end)
end

-- Attach a suggestions popup to the encounter-ID EditBox in the MRT note editor.
-- Si el usuario tipea letras (no numeros), buscamos encuentros del Encounter
-- Journal por substring del nombre y mostramos hasta 30 sugerencias. Click en
-- una fila llena el ID box con el numero y el nameBox con el nombre del jefe.
local function AttachEncounterAutocomplete(eb, nameBox)
    local popup = CreateFrame("Frame", nil, eb, "BackdropTemplate")
    PanelBackdrop(popup)
    local w = math.max(eb:GetWidth() + 220, 360)
    popup:SetSize(w, 240)
    popup:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", 0, -4)
    popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetToplevel(true); popup:EnableMouse(true)
    popup:SetFrameLevel(500); popup:Hide()

    local sf = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6); sf:SetPoint("BOTTOMRIGHT", -16, 6)
    StyleScrollBar(sf); AutoHideScrollBar(sf)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(w - 22, 1); sf:SetScrollChild(content)

    local rowPool = {}
    local lastShown = 0
    local suppressNext = false

    local function Refresh()
        if suppressNext then suppressNext = false; popup:Hide(); return end
        if not eb:HasFocus() then popup:Hide(); return end
        local q = (eb:GetText() or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        -- Texto vacio O numerico -> no autocomplete (el usuario esta tipeando ID).
        if q == "" or tonumber(q) then popup:Hide(); return end
        local results = (ns.SearchEncounters and ns.SearchEncounters(q, 30)) or {}
        local n, y = 0, 0
        for _, e in ipairs(results) do
            n = n + 1
            local b = rowPool[n]
            if not b then
                b = CreateFrame("Button", nil, content); b:SetSize(w - 26, 22)
                local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(0.3, 0.5, 0.8, 0.3)
                b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                b.text:SetPoint("LEFT", 6, 0); b.text:SetPoint("RIGHT", -4, 0); b.text:SetJustifyH("LEFT")
                rowPool[n] = b
            end
            b.text:SetText(("%s |cff888888— %s|r |cff555555(#%d)|r"):format(e.name, e.instance or "?", e.id))
            b.encounter = e
            b:SetScript("OnClick", function(self)
                suppressNext = true
                eb:SetText(tostring(self.encounter.id))
                if nameBox then nameBox:SetText(self.encounter.name) end
                eb:ClearFocus()
                popup:Hide()
            end)
            b:SetPoint("TOPLEFT", 4, -y); b:Show()
            y = y + 24
        end
        for i = n + 1, lastShown do
            local b = rowPool[i]; if b then b:Hide() end
        end
        lastShown = n
        content:SetHeight(math.max(1, y))
        if n == 0 then
            popup:Hide()
        else
            popup:SetHeight(math.min(240, y + 12))
            popup:Show()
        end
    end

    eb:HookScript("OnTextChanged", Refresh)
    eb:HookScript("OnEditFocusGained", Refresh)
    eb:HookScript("OnEscapePressed", function() popup:Hide() end)
    eb:HookScript("OnEditFocusLost", function()
        C_Timer.After(0.15, function()
            if not popup:IsMouseOver() and not eb:HasFocus() then popup:Hide() end
        end)
    end)
end

-- Multi-checkbox row for the player's class specs. Empty selection (or all checked) = no restriction.
local function SpecChecklist(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.checkboxes = {}
    local specs = ns.GetClassSpecs()
    local x = 0
    for _, spec in ipairs(specs) do
        local ck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        ck:SetSize(16, 16); ck:SetPoint("LEFT", x, 0)
        SkinCheck(ck)
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", ck, "RIGHT", 4, 0); lbl:SetText(spec.name)
        lbl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
        local labelW = lbl:GetStringWidth()
        x = x + 20 + labelW + 10
        f.checkboxes[spec.id] = ck
    end
    f:SetSize(math.max(x, 50), 22)
    function f:GetSpecs()
        local out, total, checked = {}, 0, 0
        for id, ck in pairs(self.checkboxes) do
            total = total + 1
            if ck:GetChecked() then checked = checked + 1; table.insert(out, id) end
        end
        if total == 0 or checked == total then return {} end
        return out
    end
    function f:SetSpecs(list)
        local set = {}
        local hasList = list and #list > 0
        if hasList then for _, id in ipairs(list) do set[id] = true end end
        for id, ck in pairs(self.checkboxes) do
            if not hasList then ck:SetChecked(true) else ck:SetChecked(set[id] and true or false) end
        end
    end
    return f
end

-- TalentPicker: button + popup with searchable list of talents from the active loadout.
-- Stores a single spellID via GetSpellID/SetSpellID. Empty = no talent gate.
local function TalentPicker(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(240, 22)
    f.spellID = nil

    local btn = MakeButton(f, 216, 22)
    btn:SetPoint("LEFT", 0, 0)
    local fs = btn:GetFontString()
    if fs then fs:ClearAllPoints(); fs:SetPoint("LEFT", 22, 0); fs:SetPoint("RIGHT", -4, 0); fs:SetJustifyH("LEFT") end
    local btnIcon = btn:CreateTexture(nil, "ARTWORK")
    btnIcon:SetSize(16, 16); btnIcon:SetPoint("LEFT", 4, 0); btnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92); btnIcon:Hide()

    local clearBtn = CreateFrame("Button", nil, f)
    clearBtn:SetSize(20, 20); clearBtn:SetPoint("LEFT", btn, "RIGHT", 2, 0)
    local cx = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontRed"); cx:SetAllPoints(); cx:SetText("X")
    local ch = clearBtn:CreateTexture(nil, "HIGHLIGHT"); ch:SetAllPoints(); ch:SetColorTexture(0.8, 0.2, 0.2, 0.3)

    local function UpdateLabel()
        if f.spellID then
            local info = C_Spell.GetSpellInfo(f.spellID)
            if info and info.name then
                btnIcon:SetTexture(info.iconID or 134400); btnIcon:Show()
                btn:SetText(info.name)
            else
                btnIcon:Hide(); btn:SetText(ns.L["ID: "] .. f.spellID)
            end
            clearBtn:Show()
        else
            btnIcon:Hide(); btn:SetText(ns.L["[No talent]"]); clearBtn:Hide()
        end
    end
    UpdateLabel()

    clearBtn:SetScript("OnClick", function() f.spellID = nil; UpdateLabel() end)

    local popup
    local function BuildPopup()
        local p = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        SubPanelBackdrop(p, 0.97); p:SetBackdropColor(C_BG.r, C_BG.g, C_BG.b, 0.97); p:SetBackdropBorderColor(0,0,0,1)
        p:SetSize(320, 380); p:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        p:SetFrameStrata("FULLSCREEN_DIALOG"); p:SetToplevel(true); p:EnableMouse(true)
        p:Hide()

        local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 12, -10); title:SetText(ns.L["Select a talent"])
        title:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)

        local search = MakeEditBox(p, 240, 20)
        search:SetPoint("TOPLEFT", 16, -32)

        local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        hint:SetPoint("LEFT", search, "RIGHT", 6, 0); hint:SetText(ns.L["search"])
        hint:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)

        local sf = CreateFrame("ScrollFrame", nil, p, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 8, -60); sf:SetPoint("BOTTOMRIGHT", -28, 36)
        StyleScrollBar(sf); AutoHideScrollBar(sf)
        local content = CreateFrame("Frame", nil, sf); content:SetSize(280, 1); sf:SetScrollChild(content)

        local cancel = MakeButton(p, 80, 22, ns.L["Close"])
        cancel:SetPoint("BOTTOMRIGHT", -16, 8)
        cancel:SetScript("OnClick", function() p:Hide() end)

        local empty = p:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        empty:SetPoint("CENTER", sf, "CENTER", 0, 0); empty:SetText(ns.L["(no talents in this loadout)"]); empty:Hide()

        local rowPool = {}

        local function Refresh()
            for _, b in ipairs(rowPool) do b:Hide() end
            local talents = ns.GetClassTalents() or {}
            local q = (search:GetText() or ""):lower()
            local y, n = 0, 0
            for _, t in ipairs(talents) do
                if q == "" or t.name:lower():find(q, 1, true) then
                    n = n + 1
                    local b = rowPool[n]
                    if not b then
                        b = CreateFrame("Button", nil, content); b:SetSize(270, 22)
                        local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(0.3, 0.5, 0.8, 0.3)
                        b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(18, 18); b.icon:SetPoint("LEFT", 4, 0); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0); b.text:SetPoint("RIGHT", -4, 0); b.text:SetJustifyH("LEFT")
                        rowPool[n] = b
                    end
                    b.icon:SetTexture(t.icon)
                    b.text:SetText(t.name .. " |cff666666[" .. ns.L[t.tree] .. "]|r")
                    b:SetScript("OnClick", function()
                        f.spellID = t.spellID; UpdateLabel(); p:Hide()
                    end)
                    b:SetPoint("TOPLEFT", 4, -y); b:Show()
                    y = y + 24
                end
            end
            content:SetHeight(math.max(1, y))
            empty:SetShown(n == 0)
        end

        search:SetScript("OnTextChanged", Refresh)
        p.Refresh = Refresh
        return p
    end

    btn:SetScript("OnClick", function()
        if popup and popup:IsShown() then popup:Hide(); return end
        if not popup then popup = BuildPopup() end
        popup:Refresh()
        popup:Show()
    end)

    function f:GetSpellID() return self.spellID end
    function f:SetSpellID(id) self.spellID = (type(id) == "number" and id > 0) and id or nil; UpdateLabel() end
    function f:HidePopup() if popup then popup:Hide() end end
    return f
end

-- SoundPicker: botón + popup buscable con TODOS los sonidos de LibSharedMedia
-- (más una entrada "Default") + botón ♪ por fila para preescuchar. Almacena
-- el NOMBRE del sonido como string en `f.soundName`; "Default" usa 8959.
-- `onChange` opcional: callback(name) llamado cuando el usuario selecciona uno
-- nuevo desde el popup (no se dispara al setear programaticamente via
-- SetSoundName, que se usa para hidratar desde savedvars).
local function SoundPicker(parent, width, onChange)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width or 160, 22)
    f.soundName = "Default"

    local btn = MakeButton(f, width or 160, 22)
    btn:SetAllPoints()
    local fs = btn:GetFontString()
    if fs then fs:ClearAllPoints(); fs:SetPoint("LEFT", 8, 0); fs:SetPoint("RIGHT", -8, 0); fs:SetJustifyH("LEFT") end

    local function SetLabel() btn:SetText(f.soundName or "Default") end
    SetLabel()

    local function CollectSounds()
        local list, seen = {}, {}
        local function add(n) if n and n ~= "" and not seen[n] then list[#list+1]=n; seen[n]=true end end
        add("Default")
        local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
        if lsm then
            local lsmList = lsm:List("sound") or {}
            for i = 1, #lsmList do add(lsmList[i]) end
        end
        if SOUND_OPTIONS then
            for _, opt in ipairs(SOUND_OPTIONS) do add(opt.label) end
        end
        return list
    end

    local popup
    local function BuildPopup()
        local p = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        PanelBackdrop(p)
        p:SetSize(320, 380); p:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        p:SetFrameStrata("FULLSCREEN_DIALOG"); p:SetToplevel(true); p:EnableMouse(true)
        p:Hide()

        local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 12, -10); title:SetText(ns.L["Select a sound"])
        title:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)

        local search = MakeEditBox(p, 240, 20)
        search:SetPoint("TOPLEFT", 16, -32)
        local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        hint:SetPoint("LEFT", search, "RIGHT", 6, 0); hint:SetText(ns.L["search"])
        hint:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)

        local sf = CreateFrame("ScrollFrame", nil, p, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 8, -60); sf:SetPoint("BOTTOMRIGHT", -28, 36)
        StyleScrollBar(sf); AutoHideScrollBar(sf)
        local content = CreateFrame("Frame", nil, sf); content:SetSize(280, 1); sf:SetScrollChild(content)

        local cancel = MakeButton(p, 80, 22, ns.L["Close"])
        cancel:SetPoint("BOTTOMRIGHT", -16, 8)
        cancel:SetScript("OnClick", function() p:Hide() end)

        local rowPool = {}
        local function Refresh()
            for _, b in ipairs(rowPool) do b:Hide() end
            local sounds = CollectSounds()
            local q = (search:GetText() or ""):lower()
            local y, n = 0, 0
            for _, name in ipairs(sounds) do
                if q == "" or name:lower():find(q, 1, true) then
                    n = n + 1
                    local row = rowPool[n]
                    if not row then
                        row = CreateFrame("Button", nil, content); row:SetSize(264, 22)
                        local hl = row:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.25)
                        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        row.text:SetPoint("LEFT", 8, 0); row.text:SetPoint("RIGHT", -32, 0); row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(false)
                        row.test = MakeButton(row, 24, 18, ">")
                        row.test:SetPoint("RIGHT", -2, 0)
                        rowPool[n] = row
                    end
                    row.text:SetText(name)
                    row.text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
                    if name == f.soundName then row.text:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b) end
                    row:SetScript("OnClick", function()
                        f.soundName = name; SetLabel(); p:Hide()
                        if onChange then onChange(name) end
                    end)
                    row.test:SetScript("OnClick", function() ns.PlayAuraSound(name) end)
                    row:SetPoint("TOPLEFT", 4, -y); row:Show()
                    y = y + 24
                end
            end
            content:SetHeight(math.max(1, y))
        end

        search:SetScript("OnTextChanged", Refresh)
        p:SetScript("OnShow", Refresh)
        return p
    end

    btn:SetScript("OnClick", function()
        if not popup then popup = BuildPopup() end
        if popup:IsShown() then popup:Hide() else popup:Show() end
    end)

    function f:GetSoundName() return self.soundName end
    function f:SetSoundName(name) self.soundName = (type(name) == "string" and name ~= "") and name or "Default"; SetLabel() end
    function f:HidePopup() if popup then popup:Hide() end end
    return f
end

local function Dropdown(parent, width, items, defaultValue, onChange)
    local c=CreateFrame("Frame",nil,parent); c:SetSize(width,24)
    local b=MakeButton(c); b:SetAllPoints(); b.selectedValue=defaultValue or items[1].value
    local function UL() for _,it in ipairs(items) do if it.value==b.selectedValue then b:SetText(it.label); return end end end; UL()
    local mf
    b:SetScript("OnClick",function(self)
        if mf and mf:IsShown() then mf:Hide(); return end
        mf=CreateFrame("Frame",nil,self,"BackdropTemplate")
        mf:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
        mf:SetBackdropColor(C_BG.r, C_BG.g, C_BG.b, 0.97); mf:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.9)
        mf:SetFrameStrata("FULLSCREEN_DIALOG"); mf:SetToplevel(true)
        mf:SetPoint("TOP",self,"BOTTOM",0,-2); mf:SetSize(width,#items*22+8)
        for i,it in ipairs(items) do
            local ib=CreateFrame("Button",nil,mf); ib:SetSize(width-8,20); ib:SetPoint("TOPLEFT",4,-4-(i-1)*22)
            local t=ib:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); t:SetPoint("LEFT",6,0); t:SetText(it.label); t:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
            local hl=ib:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.25)
            ib:SetScript("OnClick",function() b.selectedValue=it.value; UL(); mf:Hide(); if onChange then onChange(it.value) end end)
        end
        mf:SetScript("OnLeave",function(m) C_Timer.After(0.3,function() if m and m:IsShown() and not m:IsMouseOver() then m:Hide() end end) end)
    end)
    function c:GetValue() return b.selectedValue end
    function c:SetValue(v) b.selectedValue=v; UL() end
    return c
end

-- Helper: dropdown 3-options (Always / Only in combat / Only out of combat).
-- Reemplazo del legacy checkbox "Show only in combat" en cada feature, mas las
-- nuevas visibilidades por sub-feature (trail, grow, sparkle). El caller pasa
-- getter/setter directos al campo `visibility` (o el especifico, e.g.
-- `trailVisibility`); este helper no asume el nombre del campo.
local function VisibilityDropdown(parent, getter, setter)
    return Dropdown(parent, 160,
        {{label=ns.L["Always"],             value="always"},
         {label=ns.L["Only in combat"],     value="combat"},
         {label=ns.L["Only out of combat"], value="ooc"}},
        getter() or "always",
        function(v) setter(v) end)
end

local function ColorSwatch(parent, ct, onChange)
    local sw=CreateFrame("Button",nil,parent); sw:SetSize(22,22)
    local bg=sw:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0,0,0,1)
    local tx=sw:CreateTexture(nil,"ARTWORK"); tx:SetPoint("TOPLEFT",1,-1); tx:SetPoint("BOTTOMRIGHT",-1,1)
    tx:SetColorTexture(ct.r,ct.g,ct.b,ct.a or 1); sw.colorTex=tx
    sw:SetScript("OnClick",function()
        local info={r=ct.r,g=ct.g,b=ct.b,hasOpacity=true,opacity=ct.a or 1}
        info.swatchFunc=function() local r,g,b=ColorPickerFrame:GetColorRGB(); ct.r,ct.g,ct.b=r,g,b; tx:SetColorTexture(r,g,b,ct.a or 1); if onChange then onChange() end end
        info.opacityFunc=function() ct.a=ColorPickerFrame:GetColorAlpha(); tx:SetColorTexture(ct.r,ct.g,ct.b,ct.a); if onChange then onChange() end end
        info.cancelFunc=function(p) ct.r,ct.g,ct.b,ct.a=p.r,p.g,p.b,p.opacity; tx:SetColorTexture(p.r,p.g,p.b,p.opacity); if onChange then onChange() end end
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    function sw:UpdateColor() tx:SetColorTexture(ct.r,ct.g,ct.b,ct.a or 1) end
    return sw
end

local function ResolveSpellID(info1)
    local si = C_Spell.GetSpellInfo(info1)
    if si then return si.spellID end
    if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
        local bi = C_SpellBook.GetSpellBookItemInfo(info1, Enum.SpellBookSpellBank.Player)
        if bi and bi.spellID then return bi.spellID end
        bi = C_SpellBook.GetSpellBookItemInfo(info1, Enum.SpellBookSpellBank.Pet)
        if bi and bi.spellID then return bi.spellID end
    end
    return nil
end

local function DropZone(parent, w, h, onDrop)
    local z=CreateFrame("Button",nil,parent,"BackdropTemplate"); z:SetSize(w,h)
    z:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=2,right=2,top=2,bottom=2}})
    z:SetBackdropColor(0.15,0.15,0.2,0.9); z:SetBackdropBorderColor(0.5,0.5,0.6,0.8)
    local t=z:CreateFontString(nil,"OVERLAY","GameFontDisable"); t:SetPoint("CENTER"); t:SetText(ns.L["Drag a spell here"])
    local hl=z:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(0.2,0.5,0.8,0.25)
    z:RegisterForDrag("LeftButton")
    local function HandleDrop() local it,i1=GetCursorInfo(); if it=="spell" then local id=ResolveSpellID(i1); ClearCursor(); if id and onDrop then onDrop(id) end end end
    z:SetScript("OnReceiveDrag",HandleDrop); z:SetScript("OnClick",HandleDrop)
    return z
end

local SHOW_LABELS = setmetatable({}, {__index=function(_,k)
    if k=="ALWAYS" then return ns.L["Always"]
    elseif k=="ACTIVE" then return ns.L["Active only"]
    elseif k=="MISSING" then return ns.L["Missing only"]
    elseif k=="BELOW_STACKS" then return ns.L["Below stacks"]
    end
end})

-- ============================================================
-- Row widgets
-- ============================================================

-- Helper: agrega botones de mover (↑/↓) a la izquierda de `anchorRight`. Retorna
-- el upBtn (extremo izquierdo) para que el caller pueda anclar lo que sigue a su
-- izquierda. `canUp`/`canDown` controlan si la accion esta disponible (primer
-- elemento no puede subir, ultimo no puede bajar) — boton inhabilitado se ve dim.
-- Usa una sola textura rotada 180° para la flecha de bajar; asi ambas tienen el
-- mismo tamaño y aspecto por construccion (los glifos "^"/"v" del font se ven
-- desbalanceados porque tienen alturas distintas en la mayoria de fonts).
local function AddRowMoveButtons(row, anchorRight, onMoveUp, onMoveDown, canUp, canDown)
    local function MakeArrow(direction, enabled, onClick, tooltip)
        local b = CreateFrame("Button", nil, row); b:SetSize(16, 20)
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetSize(12, 12); tex:SetPoint("CENTER")
        -- Textura propia del addon (Textures/arrow_up.tga): triangulo blanco
        -- antialiased centrado en 64x64. Rotamos 180° para la flecha de bajar
        -- asi ambas son identicas en tamaño/forma por construccion.
        tex:SetTexture("Interface\\AddOns\\HNZHealingTools\\Textures\\arrow_up")
        if direction == "down" then tex:SetRotation(math.pi) end
        if enabled then
            tex:SetVertexColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, 1)
            local h = b:CreateTexture(nil, "HIGHLIGHT"); h:SetAllPoints(); h:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.2)
            b:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:AddLine(tooltip); GameTooltip:Show() end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            b:SetScript("OnClick", onClick)
        else
            tex:SetVertexColor(0.35, 0.35, 0.4, 0.6)
            b:EnableMouse(false)
        end
        return b
    end
    local downBtn = MakeArrow("down", canDown, function() if onMoveDown then onMoveDown() end end, ns.L["Move down"])
    downBtn:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
    local upBtn = MakeArrow("up", canUp, function() if onMoveUp then onMoveUp() end end, ns.L["Move up"])
    upBtn:SetPoint("RIGHT", downBtn, "LEFT", -2, 0)
    return upBtn
end

-- Boton Test (T) — fuerza el icono a aparecer junto al cursor real durante unos
-- segundos para previsualizar como se va a ver. Anchor LEFT respecto a `anchorRight`.
-- Usa font glyph "T" en GameFontNormal (font universal del cliente) con tint verde
-- para que se distinga de los otros botones de la fila.
local function AddRowTestButton(row, anchorRight, onTest)
    local b = CreateFrame("Button", nil, row); b:SetSize(16, 20)
    b:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); t:SetAllPoints(); t:SetText("T")
    t:SetTextColor(0.4, 1.0, 0.5, 1)
    local h = b:CreateTexture(nil, "HIGHLIGHT"); h:SetAllPoints(); h:SetColorTexture(0.3, 0.9, 0.3, 0.2)
    b:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:AddLine(ns.L["Test"]); GameTooltip:Show() end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function() if onTest then onTest() end end)
    return b
end

local function SpellRow(parent, entry, index, listLen, onRemove, onEdit, onMoveUp, onMoveDown)
    local r=CreateFrame("Frame",nil,parent,"BackdropTemplate"); r:SetSize(parent:GetWidth()-6,34)
    r:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=2,right=2,top=2,bottom=2}})
    r:SetBackdropColor(0.1,0.1,0.15,0.7); r:SetBackdropBorderColor(0.4,0.4,0.5,0.6)
    local nm, ic = ns.GetSpellDisplayInfo(entry.spellID)
    if nm == tostring(entry.spellID) then nm = ns.L["Unknown"] end
    local icon=r:CreateTexture(nil,"ARTWORK"); icon:SetSize(24,24); icon:SetPoint("LEFT",5,0); icon:SetTexture(ic); icon:SetTexCoord(0.08,0.92,0.08,0.92)
    local ck=CreateFrame("CheckButton",nil,r,"UICheckButtonTemplate"); ck:SetSize(18,18); ck:SetPoint("LEFT",icon,"RIGHT",6,0); ck:SetChecked(entry.enabled)
    SkinCheck(ck)
    ck:SetScript("OnClick",function(self) entry.enabled=self:GetChecked() end)
    local nt=r:CreateFontString(nil,"OVERLAY","GameFontNormal"); nt:SetPoint("LEFT",ck,"RIGHT",6,0); nt:SetWidth(150); nt:SetJustifyH("LEFT"); nt:SetWordWrap(false); nt:SetText(nm)
    nt:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local badges={}
    if entry.minCharges and entry.minCharges>0 then table.insert(badges,"|cffff9900"..ns.L["Min:"]..entry.minCharges.."|r") end
    if entry.hideOnCooldown then table.insert(badges,"|cffaaaaff"..ns.L["Hide CD"].."|r") end
    if entry.cdPulse then table.insert(badges,"|cff66ffcc"..ns.L["Pulse"].."|r"..(entry.cdPulseSound and " |A:voicechat-icon-speaker:12:12|a" or "")) end
    if entry.specs and #entry.specs>0 then table.insert(badges,"|cff88ccff"..ns.L["Specs:"]..#entry.specs.."|r") end
    if entry.requiredTalentSpellID then table.insert(badges,"|cffcc88ff"..ns.L["Talent"].."|r") end
    local dt=table.concat(badges," ")
    if dt~="" then dt=dt.." " end
    dt=dt.."|cff666666"..ns.L["ID:"]..entry.spellID.."|r"
    local dtx=r:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); dtx:SetPoint("LEFT",nt,"RIGHT",6,0); dtx:SetPoint("RIGHT",-86,0); dtx:SetJustifyH("LEFT"); dtx:SetWordWrap(false); dtx:SetText(dt)
    local rb=CreateFrame("Button",nil,r); rb:SetSize(20,20); rb:SetPoint("RIGHT",-5,0)
    local rt=rb:CreateFontString(nil,"OVERLAY","GameFontRed"); rt:SetAllPoints(); rt:SetText("X")
    local rh=rb:CreateTexture(nil,"HIGHLIGHT"); rh:SetAllPoints(); rh:SetColorTexture(0.8,0.2,0.2,0.3)
    rb:SetScript("OnClick",function() if onRemove then onRemove(entry.spellID) end end)
    local eb=CreateFrame("Button",nil,r); eb:SetSize(20,20); eb:SetPoint("RIGHT",rb,"LEFT",-2,0)
    local pic=eb:CreateTexture(nil,"ARTWORK"); pic:SetSize(14,14); pic:SetPoint("CENTER")
    pic:SetTexture("Interface\\GossipFrame\\BinderGossipIcon")
    pic:SetVertexColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    local eh=eb:CreateTexture(nil,"HIGHLIGHT"); eh:SetAllPoints(); eh:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.25)
    eb:SetScript("OnEnter",function(s) GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:AddLine(ns.L["Edit"]); GameTooltip:Show() end)
    eb:SetScript("OnLeave",function() GameTooltip:Hide() end)
    eb:SetScript("OnClick",function() if onEdit then onEdit(entry) end end)
    AddRowMoveButtons(r, eb, onMoveUp, onMoveDown, index and index > 1, index and listLen and index < listLen)
    return r
end

local function CursorAuraRow(parent, entry, index, listLen, onRemove, onEdit, onMoveUp, onMoveDown)
    local r=CreateFrame("Frame",nil,parent,"BackdropTemplate"); r:SetSize(parent:GetWidth()-6,34)
    r:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=2,right=2,top=2,bottom=2}})
    r:SetBackdropColor(0.1,0.1,0.15,0.7); r:SetBackdropBorderColor(0.4,0.4,0.5,0.6)
    local nm, ic = ns.GetSpellDisplayInfo(entry.spellID)
    if nm == tostring(entry.spellID) then nm = ns.L["Unknown"] end
    local notInCDM = not ns:IsAuraInCDM(entry.spellID)
    local icon=r:CreateTexture(nil,"ARTWORK"); icon:SetSize(24,24); icon:SetPoint("LEFT",5,0); icon:SetTexture(ic); icon:SetTexCoord(0.08,0.92,0.08,0.92)
    if notInCDM then icon:SetDesaturated(true) end
    local ck=CreateFrame("CheckButton",nil,r,"UICheckButtonTemplate"); ck:SetSize(18,18); ck:SetPoint("LEFT",icon,"RIGHT",6,0); ck:SetChecked(entry.enabled)
    SkinCheck(ck)
    ck:SetScript("OnClick",function(self) entry.enabled=self:GetChecked() end)
    local nt=r:CreateFontString(nil,"OVERLAY","GameFontNormal"); nt:SetPoint("LEFT",ck,"RIGHT",6,0); nt:SetWidth(120); nt:SetJustifyH("LEFT"); nt:SetWordWrap(false); nt:SetText(nm)
    nt:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    if notInCDM then nt:SetTextColor(0.55,0.55,0.55) end
    local fc=entry.filter=="HELPFUL" and "|cff00cc00"..ns.L["Buff"].."|r" or "|cffcc0000"..ns.L["Debuff"].."|r"
    local sl=SHOW_LABELS[entry.showWhen or "ALWAYS"] or ns.L["Always"]
    local dt="|cffaaaaaa"..entry.unit.."|r "..fc.." |cffcccccc"..sl.."|r |cff666666"..ns.L["ID:"]..entry.spellID.."|r"
    if entry.manualDuration and entry.manualDuration>0 then dt=dt.." |cffff9900"..entry.manualDuration..ns.L["s"].."|r" end
    if entry.cdPulse then dt=dt.." |cff66ffcc"..ns.L["Pulse"].."|r" end
    if entry.specs and #entry.specs>0 then dt=dt.." |cff88ccff"..ns.L["Specs:"]..#entry.specs.."|r" end
    if entry.requiredTalentSpellID then dt=dt.." |cffcc88ff"..ns.L["Talent"].."|r" end
    if notInCDM then dt=dt.." |cffaaaaaa"..ns.L["!CDM"].."|r" end
    local dtx=r:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); dtx:SetPoint("LEFT",nt,"RIGHT",6,0); dtx:SetPoint("RIGHT",-86,0); dtx:SetJustifyH("LEFT"); dtx:SetWordWrap(false); dtx:SetText(dt)
    local rb=CreateFrame("Button",nil,r); rb:SetSize(20,20); rb:SetPoint("RIGHT",-5,0)
    local rt=rb:CreateFontString(nil,"OVERLAY","GameFontRed"); rt:SetAllPoints(); rt:SetText("X")
    local rh=rb:CreateTexture(nil,"HIGHLIGHT"); rh:SetAllPoints(); rh:SetColorTexture(0.8,0.2,0.2,0.3)
    rb:SetScript("OnClick",function() if onRemove then onRemove(entry.spellID) end end)
    local eb=CreateFrame("Button",nil,r); eb:SetSize(20,20); eb:SetPoint("RIGHT",rb,"LEFT",-2,0)
    local pic=eb:CreateTexture(nil,"ARTWORK"); pic:SetSize(14,14); pic:SetPoint("CENTER")
    pic:SetTexture("Interface\\GossipFrame\\BinderGossipIcon")
    pic:SetVertexColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    local eh=eb:CreateTexture(nil,"HIGHLIGHT"); eh:SetAllPoints(); eh:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.25)
    eb:SetScript("OnEnter",function(s) GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:AddLine(ns.L["Edit"]); GameTooltip:Show() end)
    eb:SetScript("OnLeave",function() GameTooltip:Hide() end)
    eb:SetScript("OnClick",function() if onEdit then onEdit(entry) end end)
    AddRowMoveButtons(r, eb, onMoveUp, onMoveDown, index and index > 1, index and listLen and index < listLen)
    return r
end

local function RingAuraRow(parent, entry, index, onRemove, onEdit, onTest)
    local r=CreateFrame("Frame",nil,parent,"BackdropTemplate"); r:SetSize(parent:GetWidth()-6,40)
    r:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=2,right=2,top=2,bottom=2}})
    r:SetBackdropColor(0.1,0.1,0.15,0.7); r:SetBackdropBorderColor(0.4,0.4,0.5,0.6)
    local nm, ic = ns.GetSpellDisplayInfo(entry.spellID)
    if nm == tostring(entry.spellID) then nm = ns.L["Unknown"] end
    local notInCDM = not ns:IsAuraInCDM(entry.spellID)
    local nt2=r:CreateFontString(nil,"OVERLAY","GameFontNormal"); nt2:SetPoint("LEFT",6,0); nt2:SetText("|cff888888#"..index.."|r")
    local sw=ColorSwatch(r,entry.color,function() ns:MarkAuraDirty() end); sw:SetSize(22,22); sw:SetPoint("LEFT",nt2,"RIGHT",5,0)
    local icon=r:CreateTexture(nil,"ARTWORK"); icon:SetSize(26,26); icon:SetPoint("LEFT",sw,"RIGHT",5,0); icon:SetTexture(ic); icon:SetTexCoord(0.08,0.92,0.08,0.92)
    if notInCDM then icon:SetDesaturated(true) end
    local nt=r:CreateFontString(nil,"OVERLAY","GameFontNormal"); nt:SetPoint("LEFT",icon,"RIGHT",6,0); nt:SetWidth(130); nt:SetJustifyH("LEFT"); nt:SetWordWrap(false); nt:SetText(nm)
    if notInCDM then nt:SetTextColor(0.55,0.55,0.55) end
    local fc=entry.filter=="HELPFUL" and "|cff00cc00"..ns.L["Buff"].."|r" or "|cffcc0000"..ns.L["Debuff"].."|r"
    local sl=SHOW_LABELS[entry.showWhen or "ACTIVE"] or ns.L["Active only"]
    local ds="|cffaaaaaa"..entry.unit.."|r "..fc.." |cffcccccc"..sl.."|r"
    if entry.manualDuration and entry.manualDuration>0 then ds=ds.." |cffff9900"..entry.manualDuration..ns.L["s"].."|r" end
    if entry.showIcon then ds=ds.." |cff88aacc"..ns.L["[icon]"].."|r" end
    if entry.cdPulse then ds=ds.." |cff66ffcc"..ns.L["Pulse"].."|r" end
    if entry.specs and #entry.specs>0 then ds=ds.." |cff88ccff"..ns.L["Specs:"]..#entry.specs.."|r" end
    if entry.requiredTalentSpellID then ds=ds.." |cffcc88ff"..ns.L["Talent"].."|r" end
    if notInCDM then ds=ds.." |cffaaaaaa"..ns.L["!CDM"].."|r" end
    ds=ds.." |cff666666"..ns.L["ID:"]..entry.spellID.."|r"
    local dtx=r:CreateFontString(nil,"OVERLAY","GameFontNormal"); dtx:SetPoint("LEFT",nt,"RIGHT",6,0); dtx:SetPoint("RIGHT",-78,0); dtx:SetJustifyH("LEFT"); dtx:SetWordWrap(false); dtx:SetText(ds)
    local rb=CreateFrame("Button",nil,r); rb:SetSize(22,22); rb:SetPoint("RIGHT",-6,0)
    local rt=rb:CreateFontString(nil,"OVERLAY","GameFontRed"); rt:SetAllPoints(); rt:SetText("X")
    local rhl=rb:CreateTexture(nil,"HIGHLIGHT"); rhl:SetAllPoints(); rhl:SetColorTexture(0.8,0.2,0.2,0.3)
    rb:SetScript("OnClick",function() if onRemove then onRemove(entry.spellID) end end)
    local eb=CreateFrame("Button",nil,r); eb:SetSize(22,22); eb:SetPoint("RIGHT",rb,"LEFT",-2,0)
    local pic=eb:CreateTexture(nil,"ARTWORK"); pic:SetSize(14,14); pic:SetPoint("CENTER")
    pic:SetTexture("Interface\\GossipFrame\\BinderGossipIcon")
    pic:SetVertexColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    local eh=eb:CreateTexture(nil,"HIGHLIGHT"); eh:SetAllPoints(); eh:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.25)
    eb:SetScript("OnEnter",function(s) GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:AddLine(ns.L["Edit"]); GameTooltip:Show() end)
    eb:SetScript("OnLeave",function() GameTooltip:Hide() end)
    eb:SetScript("OnClick",function() if onEdit then onEdit(entry) end end)
    if onTest then AddRowTestButton(r, eb, onTest) end
    return r
end

-- ============================================================
-- Editor Modals
-- ============================================================

local function CreateEditorFrame(globalName, title, width, height)
    local f=CreateFrame("Frame",globalName,UIParent,"BackdropTemplate")
    f:SetSize(width,height); f:SetPoint("CENTER")
    PanelBackdrop(f)
    f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetToplevel(true)
    f:SetMovable(true); f:SetClampedToScreen(true)
    f:EnableMouse(true); f:Hide()
    tinsert(UISpecialFrames,globalName)

    local tb=CreateFrame("Frame",nil,f); tb:SetHeight(30); tb:SetPoint("TOPLEFT",0,0); tb:SetPoint("TOPRIGHT",-30,0)
    tb:EnableMouse(true); tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart",function() f:StartMoving() end); tb:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
    f.title=tb:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.title:SetPoint("LEFT",12,0); f.title:SetText(title)
    f.title:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)

    local cb=CreateFrame("Button",nil,f,"BackdropTemplate"); cb:SetSize(20,20); cb:SetPoint("TOPRIGHT",-8,-5)
    cb:SetFrameLevel(tb:GetFrameLevel()+5)
    ElementBackdrop(cb)
    local cbX=cb:CreateFontString(nil,"OVERLAY","GameFontNormal"); cbX:SetPoint("CENTER"); cbX:SetText("x"); cbX:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
    cb:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(1,0.3,0.3,1); cbX:SetTextColor(1,0.3,0.3) end)
    cb:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.5); cbX:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b) end)
    cb:SetScript("OnClick",function() f:Hide() end)

    f.content=CreateFrame("Frame",nil,f); f.content:SetPoint("TOPLEFT",10,-34); f.content:SetPoint("BOTTOMRIGHT",-10,42)
    return f
end

local function CreateCursorSpellEditor()
    local f=CreateEditorFrame("HNZHealingToolsCursorSpellEditor",ns.L["Cursor Spell"],500,440)
    local p=f.content
    local editingEntry

    local nl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); nl:SetPoint("TOPLEFT",4,-4); nl:SetText(ns.L["Spell name or ID:"])
    local eb=EditBox(p,360); eb:SetPoint("TOPLEFT",4,-22)
    AttachSpellAutocomplete(eb)

    local mcl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); mcl:SetPoint("TOPLEFT",4,-52); mcl:SetText(ns.L["Show only when charges >=  (0=always):"])
    local mce=EditBox(p,50); mce:SetPoint("TOPLEFT",4,-70); mce:SetText("0"); mce:SetNumeric(true)
    local sfl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sfl:SetPoint("LEFT",mce,"RIGHT",14,0); sfl:SetText(ns.L["Stack text size (0=default):"])
    local sfe=EditBox(p,40); sfe:SetPoint("LEFT",sfl,"RIGHT",4,0); sfe:SetText("0"); sfe:SetNumeric(true)

    local hcdCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); hcdCk:SetSize(18,18); hcdCk:SetPoint("TOPLEFT",2,-100); SkinCheck(hcdCk)
    local hcdLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); hcdLabel:SetPoint("LEFT",hcdCk,"RIGHT",6,0); hcdLabel:SetText(ns.L["Hide while on cooldown"]); hcdLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local hsoCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); hsoCk:SetSize(18,18); hsoCk:SetPoint("TOPLEFT",2,-124); SkinCheck(hsoCk)
    local hsoLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); hsoLabel:SetPoint("LEFT",hsoCk,"RIGHT",6,0); hsoLabel:SetText(ns.L["Hide status overlay"]); hsoLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local htCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); htCk:SetSize(18,18); htCk:SetPoint("TOPLEFT",2,-148); SkinCheck(htCk)
    local htLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); htLabel:SetPoint("LEFT",htCk,"RIGHT",6,0); htLabel:SetText(ns.L["Hide cooldown / duration timer"]); htLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    -- Cooldown pulse (centro de pantalla cuando pasa a READY)
    local cpCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); cpCk:SetSize(18,18); cpCk:SetPoint("TOPLEFT",2,-176); SkinCheck(cpCk)
    local cpLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); cpLabel:SetPoint("LEFT",cpCk,"RIGHT",6,0); cpLabel:SetText(ns.L["Pulse icon at screen center on ready"]); cpLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local cpsCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); cpsCk:SetSize(18,18); cpsCk:SetPoint("TOPLEFT",2,-200); SkinCheck(cpsCk)
    local cpsLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); cpsLabel:SetPoint("LEFT",cpsCk,"RIGHT",6,0); cpsLabel:SetText(ns.L["Play sound on ready"]); cpsLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local cpsPick=SoundPicker(p,170); cpsPick:SetPoint("LEFT",cpsLabel,"RIGHT",10,0)
    local cpsTest=Btn(p,ns.L["Test"],60,18); cpsTest:SetPoint("LEFT",cpsPick,"RIGHT",6,0)
    cpsTest:SetScript("OnClick",function()
        local sid=ns.GetSpellIDFromInput and ns.GetSpellIDFromInput(eb:GetText():trim()) or tonumber(eb:GetText())
        local info=sid and C_Spell.GetSpellInfo(sid) or nil
        ns:ShowPulse(info and info.iconID or 134400, info and info.name or ns.L["Test"], cpsCk:GetChecked() and true or false, cpsPick:GetSoundName())
    end)

    local spLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); spLabel:SetPoint("TOPLEFT",4,-232); spLabel:SetText(ns.L["Specs:"])
    local spChk=SpecChecklist(p); spChk:SetPoint("TOPLEFT",4,-248)
    local tlLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); tlLabel:SetPoint("TOPLEFT",4,-280); tlLabel:SetText(ns.L["Required talent:"])
    local tlPick=TalentPicker(p); tlPick:SetPoint("TOPLEFT",4,-296)

    local fb=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); fb:SetPoint("BOTTOMLEFT",4,4); fb:SetPoint("BOTTOMRIGHT",-4,4); fb:SetJustifyH("LEFT")

    local saveBtn=Btn(f,ns.L["Save"],100,26); saveBtn:SetPoint("BOTTOMRIGHT",-110,8)
    local cancelBtn=Btn(f,ns.L["Cancel"],90,26); cancelBtn:SetPoint("BOTTOMRIGHT",-8,8)
    cancelBtn:SetScript("OnClick",function() f:Hide() end)

    local function ApplyToEntry(e)
        e.hideOnCooldown=hcdCk:GetChecked() and true or false
        e.hideStatusOverlay=hsoCk:GetChecked() and true or false
        e.hideTimer=htCk:GetChecked() and true or false
        e.minCharges=tonumber(mce:GetText()) or 0
        e.stackFontSize=tonumber(sfe:GetText()) or 0
        e.cdPulse=cpCk:GetChecked() and true or false
        e.cdPulseSound=cpsCk:GetChecked() and true or false
        e.cdPulseSoundName=cpsPick:GetSoundName()
        e.specs=spChk:GetSpecs()
        e.requiredTalentSpellID=tlPick:GetSpellID()
    end

    saveBtn:SetScript("OnClick",function()
        if editingEntry then
            ApplyToEntry(editingEntry); ns:MarkSpellDirty()
            f:Hide(); if ns.RefreshSpellList then ns.RefreshSpellList() end
            return
        end
        local input=eb:GetText():trim()
        if input=="" then fb:SetTextColor(1,0.3,0.3); fb:SetText(ns.L["Enter a name/ID."]); return end
        local ok,msg=ns:AddCursorSpell(input)
        if ok then
            local sid=ns.GetSpellIDFromInput(input)
            if sid then local _,added=ns.FindSpellEntry(ns.db.cursorSpells,sid); if added then ApplyToEntry(added) end end
            f:Hide(); if ns.RefreshSpellList then ns.RefreshSpellList() end
        else fb:SetTextColor(1,0.3,0.3); fb:SetText(msg) end
    end)
    eb:SetScript("OnEnterPressed",function() saveBtn:Click() end)

    local function Reset()
        editingEntry=nil; eb:SetText(""); eb:Enable()
        hcdCk:SetChecked(false); hsoCk:SetChecked(false); htCk:SetChecked(false)
        cpCk:SetChecked(false); cpsCk:SetChecked(false); cpsPick:SetSoundName("Default")
        mce:SetText("0"); sfe:SetText("0"); spChk:SetSpecs(nil); tlPick:SetSpellID(nil); fb:SetText("")
    end

    local editor={}
    function editor:OpenAdd()
        Reset(); f.title:SetText("|cff00ccff"..ns.L["New Cursor Spell"].."|r"); saveBtn:SetText(ns.L["Add"]); f:Show(); eb:SetFocus()
    end
    function editor:OpenWithSpellID(id)
        Reset(); eb:SetText(tostring(id)); f.title:SetText("|cff00ccff"..ns.L["New Cursor Spell"].."|r"); saveBtn:SetText(ns.L["Add"]); f:Show()
    end
    function editor:OpenEdit(entry)
        Reset(); editingEntry=entry
        local info=C_Spell.GetSpellInfo(entry.spellID)
        eb:SetText(tostring(entry.spellID)); eb:Disable()
        hcdCk:SetChecked(entry.hideOnCooldown and true or false)
        hsoCk:SetChecked(entry.hideStatusOverlay and true or false)
        htCk:SetChecked(entry.hideTimer and true or false)
        cpCk:SetChecked(entry.cdPulse and true or false)
        cpsCk:SetChecked(entry.cdPulseSound and true or false)
        cpsPick:SetSoundName(entry.cdPulseSoundName or "Default")
        mce:SetText(tostring(entry.minCharges or 0))
        sfe:SetText(tostring(entry.stackFontSize or 0))
        spChk:SetSpecs(entry.specs); tlPick:SetSpellID(entry.requiredTalentSpellID)
        f.title:SetText("|cff00ccff"..ns.L["Editing: "]..(info and info.name or "?").."|r")
        saveBtn:SetText(ns.L["Update"]); f:Show()
    end
    return editor
end

local function CreateCursorAuraEditor()
    local f=CreateEditorFrame("HNZHealingToolsCursorAuraEditor",ns.L["Cursor Aura"],500,460)
    local p=f.content
    local editingEntry

    local nl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); nl:SetPoint("TOPLEFT",4,-4); nl:SetText(ns.L["Aura name or ID:"])
    local eb=EditBox(p,380); eb:SetPoint("TOPLEFT",4,-22)
    AttachSpellAutocomplete(eb)

    local ul=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); ul:SetPoint("TOPLEFT",4,-52); ul:SetText(ns.L["Unit:"])
    local ud=Dropdown(p,100,{{label=ns.L["Target"],value="target"},{label=ns.L["Player"],value="player"},{label=ns.L["Focus"],value="focus"},{label=ns.L["Mouseover"],value="mouseover"},{label=ns.L["Pet"],value="pet"}},"target")
    ud:SetPoint("TOPLEFT",4,-70)
    local fl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); fl:SetPoint("LEFT",ud,"RIGHT",14,0); fl:SetText(ns.L["Type:"])
    local fd=Dropdown(p,80,{{label=ns.L["Buff"],value="HELPFUL"},{label=ns.L["Debuff"],value="HARMFUL"}},"HELPFUL"); fd:SetPoint("LEFT",fl,"RIGHT",4,0)

    local swl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); swl:SetPoint("TOPLEFT",4,-100); swl:SetText(ns.L["Show:"])
    local swd=Dropdown(p,140,{{label=ns.L["Always"],value="ALWAYS"},{label=ns.L["Only missing"],value="MISSING"},{label=ns.L["Only active"],value="ACTIVE"},{label=ns.L["Below stacks"],value="BELOW_STACKS"}},"ALWAYS")
    swd:SetPoint("TOPLEFT",4,-118)
    local skl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); skl:SetPoint("LEFT",swd,"RIGHT",14,0); skl:SetText(ns.L["Min stacks:"])
    local ske=EditBox(p,40); ske:SetPoint("LEFT",skl,"RIGHT",4,0); ske:SetText("0"); ske:SetNumeric(true)

    local dl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); dl:SetPoint("TOPLEFT",4,-150); dl:SetText(ns.L["Duration (sec, 0=auto):"])
    local de=EditBox(p,50); de:SetPoint("TOPLEFT",4,-168); de:SetText("0"); de:SetNumeric(true)
    local sfl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sfl:SetPoint("LEFT",de,"RIGHT",14,0); sfl:SetText(ns.L["Stack text size (0=default):"])
    local sfe=EditBox(p,40); sfe:SetPoint("LEFT",sfl,"RIGHT",4,0); sfe:SetText("0"); sfe:SetNumeric(true)

    local hsoCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); hsoCk:SetSize(18,18); hsoCk:SetPoint("TOPLEFT",2,-200); SkinCheck(hsoCk)
    local hsoLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); hsoLabel:SetPoint("LEFT",hsoCk,"RIGHT",6,0); hsoLabel:SetText(ns.L["Hide status overlay"]); hsoLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local htCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); htCk:SetSize(18,18); htCk:SetPoint("LEFT",hsoLabel,"RIGHT",14,0); SkinCheck(htCk)
    local htLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); htLabel:SetPoint("LEFT",htCk,"RIGHT",6,0); htLabel:SetText(ns.L["Hide timer"]); htLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local cpCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); cpCk:SetSize(18,18); cpCk:SetPoint("TOPLEFT",2,-224); SkinCheck(cpCk)
    local cpLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); cpLabel:SetPoint("LEFT",cpCk,"RIGHT",6,0); cpLabel:SetText(ns.L["Pulse icon at screen center on activation"]); cpLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local sndCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); sndCk:SetSize(18,18); sndCk:SetPoint("TOPLEFT",2,-248); SkinCheck(sndCk)
    local sndLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sndLabel:SetPoint("LEFT",sndCk,"RIGHT",6,0); sndLabel:SetText(ns.L["Play sound on activation"]); sndLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local sndPick=SoundPicker(p,170); sndPick:SetPoint("LEFT",sndLabel,"RIGHT",10,0)
    local sndTest=Btn(p,ns.L["Test"],60,18); sndTest:SetPoint("LEFT",sndPick,"RIGHT",6,0)
    sndTest:SetScript("OnClick",function() ns.PlayAuraSound(sndPick:GetSoundName()) end)

    local spLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); spLabel:SetPoint("TOPLEFT",4,-280); spLabel:SetText(ns.L["Specs:"])
    local spChk=SpecChecklist(p); spChk:SetPoint("TOPLEFT",4,-296)
    local tlLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); tlLabel:SetPoint("TOPLEFT",4,-328); tlLabel:SetText(ns.L["Required talent:"])
    local tlPick=TalentPicker(p); tlPick:SetPoint("TOPLEFT",4,-344)

    local fb=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); fb:SetPoint("BOTTOMLEFT",4,4); fb:SetPoint("BOTTOMRIGHT",-4,4); fb:SetJustifyH("LEFT")
    local saveBtn=Btn(f,ns.L["Save"],100,26); saveBtn:SetPoint("BOTTOMRIGHT",-110,8)
    local cancelBtn=Btn(f,ns.L["Cancel"],90,26); cancelBtn:SetPoint("BOTTOMRIGHT",-8,8)
    cancelBtn:SetScript("OnClick",function() f:Hide() end)

    local function ApplyToEntry(e)
        e.unit=ud:GetValue(); e.filter=fd:GetValue()
        e.showWhen=swd:GetValue(); e.minStacks=tonumber(ske:GetText()) or 0
        e.manualDuration=tonumber(de:GetText()) or 0
        e.stackFontSize=tonumber(sfe:GetText()) or 0
        e.hideStatusOverlay=hsoCk:GetChecked() and true or false
        e.hideTimer=htCk:GetChecked() and true or false
        e.cdPulse=cpCk:GetChecked() and true or false
        e.playSound=sndCk:GetChecked() and true or false
        e.soundName=sndPick:GetSoundName()
        e.soundID=nil  -- legacy field cleared cuando ya hay soundName
        e.specs=spChk:GetSpecs(); e.requiredTalentSpellID=tlPick:GetSpellID()
    end

    saveBtn:SetScript("OnClick",function()
        if editingEntry then
            ApplyToEntry(editingEntry); ns:MarkAuraDirty()
            f:Hide(); if ns.RefreshCursorAuraList then ns.RefreshCursorAuraList() end
            return
        end
        local input=eb:GetText():trim()
        if input=="" then fb:SetTextColor(1,0.3,0.3); fb:SetText(ns.L["Enter a name/ID."]); return end
        local ok,msg=ns:AddCursorAura(input,ud:GetValue(),fd:GetValue(),swd:GetValue(),tonumber(ske:GetText()) or 0,tonumber(de:GetText()) or 0)
        if ok then
            local sid=ns.GetSpellIDFromInput(input)
            if sid then local _,added=ns.FindSpellEntry(ns.db.cursorAuras,sid); if added then ApplyToEntry(added) end end
            f:Hide(); if ns.RefreshCursorAuraList then ns.RefreshCursorAuraList() end
        else fb:SetTextColor(1,0.3,0.3); fb:SetText(msg) end
    end)
    eb:SetScript("OnEnterPressed",function() saveBtn:Click() end)

    local function Reset()
        editingEntry=nil; eb:SetText(""); eb:Enable()
        ud:SetValue("target"); fd:SetValue("HELPFUL")
        swd:SetValue("ALWAYS"); ske:SetText("0"); de:SetText("0"); sfe:SetText("0")
        hsoCk:SetChecked(false); htCk:SetChecked(false); cpCk:SetChecked(false)
        sndCk:SetChecked(false); sndPick:SetSoundName("Default")
        spChk:SetSpecs(nil); tlPick:SetSpellID(nil); fb:SetText("")
    end

    local editor={}
    function editor:OpenAdd()
        Reset(); f.title:SetText(ns.L["New Cursor Aura"]); saveBtn:SetText(ns.L["Add"]); f:Show(); eb:SetFocus()
    end
    function editor:OpenWithSpellID(id)
        Reset(); eb:SetText(tostring(id)); f.title:SetText(ns.L["New Cursor Aura"]); saveBtn:SetText(ns.L["Add"]); f:Show()
    end
    function editor:OpenEdit(entry)
        Reset(); editingEntry=entry
        local info=C_Spell.GetSpellInfo(entry.spellID)
        eb:SetText(tostring(entry.spellID)); eb:Disable()
        ud:SetValue(entry.unit or "target"); fd:SetValue(entry.filter or "HELPFUL")
        swd:SetValue(entry.showWhen or "ALWAYS"); ske:SetText(tostring(entry.minStacks or 0))
        de:SetText(tostring(entry.manualDuration or 0)); sfe:SetText(tostring(entry.stackFontSize or 0))
        hsoCk:SetChecked(entry.hideStatusOverlay and true or false)
        htCk:SetChecked(entry.hideTimer and true or false)
        cpCk:SetChecked(entry.cdPulse and true or false)
        sndCk:SetChecked(entry.playSound and true or false)
        sndPick:SetSoundName(entry.soundName or (entry.soundID and tostring(entry.soundID)) or "Default")
        spChk:SetSpecs(entry.specs); tlPick:SetSpellID(entry.requiredTalentSpellID)
        f.title:SetText(ns.L["Editing: "]..(info and info.name or "?"))
        saveBtn:SetText(ns.L["Update"]); f:Show()
    end
    return editor
end

local function CreateRingAuraEditor()
    local f=CreateEditorFrame("HNZHealingToolsRingAuraEditor",ns.L["Ring Aura"],500,460)
    local p=f.content
    local editingEntry
    local pc=ns.DeepCopy(ns.DEFAULT_COLORS[1])

    local nl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); nl:SetPoint("TOPLEFT",4,-4); nl:SetText(ns.L["Aura name or ID:"])
    local eb=EditBox(p,380); eb:SetPoint("TOPLEFT",4,-22)
    AttachSpellAutocomplete(eb)

    local ul=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); ul:SetPoint("TOPLEFT",4,-52); ul:SetText(ns.L["Unit:"])
    local ud=Dropdown(p,100,{{label=ns.L["Player"],value="player"},{label=ns.L["Target"],value="target"},{label=ns.L["Focus"],value="focus"},{label=ns.L["Mouseover"],value="mouseover"},{label=ns.L["Pet"],value="pet"}},"player")
    ud:SetPoint("TOPLEFT",4,-70)
    local fl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); fl:SetPoint("LEFT",ud,"RIGHT",14,0); fl:SetText(ns.L["Type:"])
    local fd=Dropdown(p,80,{{label=ns.L["Buff"],value="HELPFUL"},{label=ns.L["Debuff"],value="HARMFUL"}},"HELPFUL"); fd:SetPoint("LEFT",fl,"RIGHT",4,0)

    local swl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); swl:SetPoint("TOPLEFT",4,-100); swl:SetText(ns.L["Show:"])
    local swd=Dropdown(p,140,{{label=ns.L["Active only"],value="ACTIVE"},{label=ns.L["Always"],value="ALWAYS"},{label=ns.L["Missing only"],value="MISSING"},{label=ns.L["Below stacks"],value="BELOW_STACKS"}},"ACTIVE")
    swd:SetPoint("TOPLEFT",4,-118)
    local skl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); skl:SetPoint("LEFT",swd,"RIGHT",14,0); skl:SetText(ns.L["Min stacks:"])
    local ske=EditBox(p,40); ske:SetPoint("LEFT",skl,"RIGHT",4,0); ske:SetText("0"); ske:SetNumeric(true)

    local dl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); dl:SetPoint("TOPLEFT",4,-150); dl:SetText(ns.L["Duration (sec, 0=auto):"])
    local de=EditBox(p,50); de:SetPoint("TOPLEFT",4,-168); de:SetText("0"); de:SetNumeric(true)
    local cl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); cl:SetPoint("LEFT",de,"RIGHT",16,0); cl:SetText(ns.L["Color:"])
    local cs=ColorSwatch(p,pc,function() ns:MarkAuraDirty() end); cs:SetPoint("LEFT",cl,"RIGHT",6,0)

    local sic=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); sic:SetSize(18,18); sic:SetPoint("TOPLEFT",2,-200); sic:SetChecked(true); SkinCheck(sic)
    local sil=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sil:SetPoint("LEFT",sic,"RIGHT",6,0); sil:SetText(ns.L["Show icon on ring"]); sil:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local cpCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); cpCk:SetSize(18,18); cpCk:SetPoint("TOPLEFT",2,-224); SkinCheck(cpCk)
    local cpLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); cpLabel:SetPoint("LEFT",cpCk,"RIGHT",6,0); cpLabel:SetText(ns.L["Pulse icon at screen center on activation"]); cpLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local sndCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); sndCk:SetSize(18,18); sndCk:SetPoint("TOPLEFT",2,-248); SkinCheck(sndCk)
    local sndLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sndLabel:SetPoint("LEFT",sndCk,"RIGHT",6,0); sndLabel:SetText(ns.L["Play sound on activation"]); sndLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local sndPick=SoundPicker(p,170); sndPick:SetPoint("LEFT",sndLabel,"RIGHT",10,0)
    local sndTest=Btn(p,ns.L["Test"],60,18); sndTest:SetPoint("LEFT",sndPick,"RIGHT",6,0)
    sndTest:SetScript("OnClick",function() ns.PlayAuraSound(sndPick:GetSoundName()) end)

    local spLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); spLabel:SetPoint("TOPLEFT",4,-280); spLabel:SetText(ns.L["Specs:"])
    local spChk=SpecChecklist(p); spChk:SetPoint("TOPLEFT",4,-296)
    local tlLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); tlLabel:SetPoint("TOPLEFT",4,-328); tlLabel:SetText(ns.L["Required talent:"])
    local tlPick=TalentPicker(p); tlPick:SetPoint("TOPLEFT",4,-344)

    local fb=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); fb:SetPoint("BOTTOMLEFT",4,4); fb:SetPoint("BOTTOMRIGHT",-4,4); fb:SetJustifyH("LEFT")
    local saveBtn=Btn(f,ns.L["Save"],100,26); saveBtn:SetPoint("BOTTOMRIGHT",-110,8)
    local cancelBtn=Btn(f,ns.L["Cancel"],90,26); cancelBtn:SetPoint("BOTTOMRIGHT",-8,8)
    cancelBtn:SetScript("OnClick",function() f:Hide() end)

    local function ApplyToEntry(e)
        e.unit=ud:GetValue(); e.filter=fd:GetValue()
        e.showWhen=swd:GetValue(); e.minStacks=tonumber(ske:GetText()) or 0
        e.manualDuration=tonumber(de:GetText()) or 0
        e.showIcon=sic:GetChecked() and true or false
        e.cdPulse=cpCk:GetChecked() and true or false
        e.playSound=sndCk:GetChecked() and true or false
        e.soundName=sndPick:GetSoundName()
        e.soundID=nil
        e.color={r=pc.r,g=pc.g,b=pc.b,a=pc.a}
        e.specs=spChk:GetSpecs(); e.requiredTalentSpellID=tlPick:GetSpellID()
    end

    saveBtn:SetScript("OnClick",function()
        if editingEntry then
            ApplyToEntry(editingEntry); ns:MarkAuraDirty(); ns:RebuildRingDisplay()
            f:Hide(); if ns.RefreshRingAuraList then ns.RefreshRingAuraList() end
            return
        end
        local input=eb:GetText():trim()
        if input=="" then fb:SetTextColor(1,0.3,0.3); fb:SetText(ns.L["Enter a name/ID."]); return end
        local ok,msg=ns:AddRingAura(input,ud:GetValue(),fd:GetValue(),swd:GetValue(),tonumber(ske:GetText()) or 0,ns.DeepCopy(pc),tonumber(de:GetText()) or 0,sic:GetChecked() and true or false)
        if ok then
            local sid=ns.GetSpellIDFromInput(input)
            if sid then local _,added=ns.FindSpellEntry(ns.db.ringAuras,sid); if added then added.specs=spChk:GetSpecs(); added.requiredTalentSpellID=tlPick:GetSpellID() end end
            ns:RebuildRingDisplay()
            f:Hide(); if ns.RefreshRingAuraList then ns.RefreshRingAuraList() end
        else fb:SetTextColor(1,0.3,0.3); fb:SetText(msg) end
    end)
    eb:SetScript("OnEnterPressed",function() saveBtn:Click() end)

    local function Reset(useNextColor)
        editingEntry=nil; eb:SetText(""); eb:Enable()
        ud:SetValue("player"); fd:SetValue("HELPFUL")
        swd:SetValue("ACTIVE"); ske:SetText("0"); de:SetText("0"); sic:SetChecked(true)
        cpCk:SetChecked(false); sndCk:SetChecked(false); sndPick:SetSoundName("Default")
        spChk:SetSpecs(nil); tlPick:SetSpellID(nil); fb:SetText("")
        if useNextColor then
            local nc=ns:GetNextRingColor()
            pc.r,pc.g,pc.b,pc.a=nc.r,nc.g,nc.b,nc.a; cs:UpdateColor()
        end
    end

    local editor={}
    function editor:OpenAdd()
        Reset(true); f.title:SetText(ns.L["New Ring Aura"]); saveBtn:SetText(ns.L["Add"]); f:Show(); eb:SetFocus()
    end
    function editor:OpenWithSpellID(id)
        Reset(true); eb:SetText(tostring(id)); f.title:SetText(ns.L["New Ring Aura"]); saveBtn:SetText(ns.L["Add"]); f:Show()
    end
    function editor:OpenEdit(entry)
        Reset(false); editingEntry=entry
        local info=C_Spell.GetSpellInfo(entry.spellID)
        eb:SetText(tostring(entry.spellID)); eb:Disable()
        ud:SetValue(entry.unit or "player"); fd:SetValue(entry.filter or "HELPFUL")
        swd:SetValue(entry.showWhen or "ACTIVE"); ske:SetText(tostring(entry.minStacks or 0))
        de:SetText(tostring(entry.manualDuration or 0)); sic:SetChecked(entry.showIcon and true or false)
        cpCk:SetChecked(entry.cdPulse and true or false)
        sndCk:SetChecked(entry.playSound and true or false)
        sndPick:SetSoundName(entry.soundName or (entry.soundID and tostring(entry.soundID)) or "Default")
        if entry.color then pc.r=entry.color.r; pc.g=entry.color.g; pc.b=entry.color.b; pc.a=entry.color.a; cs:UpdateColor() end
        spChk:SetSpecs(entry.specs); tlPick:SetSpellID(entry.requiredTalentSpellID)
        f.title:SetText(ns.L["Editing: "]..(info and info.name or "?"))
        saveBtn:SetText(ns.L["Update"]); f:Show()
    end
    return editor
end

local SOUND_CHANNEL_OPTIONS = {
    {label="Master",   value="Master"},
    {label="SFX",      value="SFX"},
    {label="Music",    value="Music"},
    {label="Ambience", value="Ambience"},
    {label="Dialog",   value="Dialog"},
}

-- Constantes compartidas entre los editors modales y los Pulse rows.
-- Deben declararse aquí (antes de CreatePulseAuraEditor) para que se resuelvan
-- como upvalue del closure del editor; declararlas más abajo daba un nil global.
local PULSE_UNITS = {
    {label="player", value="player"}, {label="target", value="target"},
    {label="focus", value="focus"}, {label="pet", value="pet"},
}
local PULSE_FILTERS = {
    {label="HELPFUL", value="HELPFUL"},
    {label="HARMFUL", value="HARMFUL"},
}

local function CreatePulseSpellEditor()
    local f=CreateEditorFrame("HNZHealingToolsPulseSpellEditor",ns.L["Pulse Spell"],460,260)
    local p=f.content
    local editingEntry

    local nl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); nl:SetPoint("TOPLEFT",4,-4); nl:SetText(ns.L["Spell name or ID:"])
    local eb=EditBox(p,360); eb:SetPoint("TOPLEFT",4,-22)
    AttachSpellAutocomplete(eb)

    local sndCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); sndCk:SetSize(18,18); sndCk:SetPoint("TOPLEFT",2,-58); SkinCheck(sndCk)
    local sndLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sndLabel:SetPoint("LEFT",sndCk,"RIGHT",6,0); sndLabel:SetText(ns.L["Play sound on ready"]); sndLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local sl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sl:SetPoint("TOPLEFT",4,-92); sl:SetText(ns.L["Sound:"])
    local sndPick=SoundPicker(p,200); sndPick:SetPoint("TOPLEFT",4,-110)
    local cl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); cl:SetPoint("LEFT",sndPick,"RIGHT",16,0); cl:SetText(ns.L["Channel:"])
    local chDD=Dropdown(p,110,SOUND_CHANNEL_OPTIONS,"Master"); chDD:SetPoint("LEFT",cl,"RIGHT",6,0)
    local testBtn=Btn(p,ns.L["Test"],60,22); testBtn:SetPoint("TOPLEFT",sndPick,"BOTTOMLEFT",0,-8)
    testBtn:SetScript("OnClick",function()
        local sid = ns.GetResolvedSpellID(eb)
        local nm, ic = ns.GetSpellDisplayInfo(sid)
        ns:ShowPulse(ic, nm, sndCk:GetChecked() and true or false, sndPick:GetSoundName(), chDD:GetValue())
    end)

    local fb=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); fb:SetPoint("BOTTOMLEFT",4,4); fb:SetPoint("BOTTOMRIGHT",-4,4); fb:SetJustifyH("LEFT"); fb:SetWordWrap(true)

    local saveBtn=Btn(f,ns.L["Save"],100,26); saveBtn:SetPoint("BOTTOMRIGHT",-110,8)
    local cancelBtn=Btn(f,ns.L["Cancel"],90,26); cancelBtn:SetPoint("BOTTOMRIGHT",-8,8)
    cancelBtn:SetScript("OnClick",function() f:Hide() end)

    local function ApplyToEntry(e)
        e.soundEnabled=sndCk:GetChecked() and true or false
        e.soundName=sndPick:GetSoundName() or "Default"
        e.soundChannel=chDD:GetValue() or "Master"
    end

    saveBtn:SetScript("OnClick",function()
        if editingEntry then
            ApplyToEntry(editingEntry); f:Hide(); if ns.RefreshPulseSpellList then ns.RefreshPulseSpellList() end; return
        end
        local txt=(eb:GetText() or ""):trim()
        if txt=="" then fb:SetTextColor(1,0.3,0.3); fb:SetText(ns.L["Enter a name/ID."]); return end
        -- Preferimos el spellID memorizado por el autocomplete: GetSpellInfo(name)
        -- falla con spells que el jugador no conoce.
        local sid = ns.GetResolvedSpellID(eb)
        local addInput = sid and tostring(sid) or txt
        local ok,msg=ns:AddPulseSpell(addInput)
        if ok then
            sid = sid or ns.GetSpellIDFromInput(addInput)
            if sid then local _,added=ns.FindSpellEntry(ns.db.pulseSpells,sid); if added then ApplyToEntry(added) end end
            f:Hide(); if ns.RefreshPulseSpellList then ns.RefreshPulseSpellList() end
        else fb:SetTextColor(1,0.3,0.3); fb:SetText(msg) end
    end)
    eb:SetScript("OnEnterPressed",function() saveBtn:Click() end)

    local function Reset()
        editingEntry=nil; eb:SetText(""); eb:Enable()
        sndCk:SetChecked(false); sndPick:SetSoundName("Default")
        chDD:SetValue("Master"); fb:SetText("")
    end

    local editor={}
    function editor:OpenAdd()
        Reset(); f.title:SetText("|cff00ccff"..ns.L["New Pulse Spell"].."|r"); saveBtn:SetText(ns.L["Add"]); f:Show(); eb:SetFocus()
    end
    function editor:OpenWithSpellID(id)
        Reset(); eb:SetText(tostring(id)); f.title:SetText("|cff00ccff"..ns.L["New Pulse Spell"].."|r"); saveBtn:SetText(ns.L["Add"]); f:Show()
    end
    function editor:OpenEdit(entry)
        Reset(); editingEntry=entry
        eb:SetText(tostring(entry.spellID)); eb:Disable()
        sndCk:SetChecked(entry.soundEnabled and true or false)
        sndPick:SetSoundName(entry.soundName or "Default")
        chDD:SetValue(entry.soundChannel or "Master")
        f.title:SetText("|cff00ccff"..ns.L["Edit Pulse Spell"].."|r"); saveBtn:SetText(ns.L["Save"]); f:Show()
    end
    return editor
end

local function CreatePulseAuraEditor()
    local f=CreateEditorFrame("HNZHealingToolsPulseAuraEditor",ns.L["Pulse Aura"],460,300)
    local p=f.content
    local editingEntry

    local nl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); nl:SetPoint("TOPLEFT",4,-4); nl:SetText(ns.L["Spell name or ID:"])
    local eb=EditBox(p,360); eb:SetPoint("TOPLEFT",4,-22)
    AttachSpellAutocomplete(eb)

    local ul=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); ul:SetPoint("TOPLEFT",4,-58); ul:SetText(ns.L["Unit:"])
    local udd=Dropdown(p,90,PULSE_UNITS,"player"); udd:SetPoint("LEFT",ul,"RIGHT",6,0)
    local fl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); fl:SetPoint("LEFT",udd,"RIGHT",16,0); fl:SetText(ns.L["Filter:"])
    local fdd=Dropdown(p,90,PULSE_FILTERS,"HELPFUL"); fdd:SetPoint("LEFT",fl,"RIGHT",6,0)

    local sndCk=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); sndCk:SetSize(18,18); sndCk:SetPoint("TOPLEFT",2,-100); SkinCheck(sndCk)
    local sndLabel=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sndLabel:SetPoint("LEFT",sndCk,"RIGHT",6,0); sndLabel:SetText(ns.L["Play sound on gain"]); sndLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local sl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sl:SetPoint("TOPLEFT",4,-130); sl:SetText(ns.L["Sound:"])
    local sndPick=SoundPicker(p,200); sndPick:SetPoint("TOPLEFT",4,-148)
    local cl=p:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); cl:SetPoint("LEFT",sndPick,"RIGHT",16,0); cl:SetText(ns.L["Channel:"])
    local chDD=Dropdown(p,110,SOUND_CHANNEL_OPTIONS,"Master"); chDD:SetPoint("LEFT",cl,"RIGHT",6,0)
    local testBtn=Btn(p,ns.L["Test"],60,22); testBtn:SetPoint("TOPLEFT",sndPick,"BOTTOMLEFT",0,-8)
    testBtn:SetScript("OnClick",function()
        local sid = ns.GetResolvedSpellID(eb)
        local nm, ic = ns.GetSpellDisplayInfo(sid)
        ns:ShowPulse(ic, nm, sndCk:GetChecked() and true or false, sndPick:GetSoundName(), chDD:GetValue())
    end)

    local fb=p:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); fb:SetPoint("BOTTOMLEFT",4,4); fb:SetPoint("BOTTOMRIGHT",-4,4); fb:SetJustifyH("LEFT"); fb:SetWordWrap(true)

    local saveBtn=Btn(f,ns.L["Save"],100,26); saveBtn:SetPoint("BOTTOMRIGHT",-110,8)
    local cancelBtn=Btn(f,ns.L["Cancel"],90,26); cancelBtn:SetPoint("BOTTOMRIGHT",-8,8)
    cancelBtn:SetScript("OnClick",function() f:Hide() end)

    local function ApplyToEntry(e)
        e.unit=udd:GetValue() or "player"
        e.filter=fdd:GetValue() or "HELPFUL"
        e.soundEnabled=sndCk:GetChecked() and true or false
        e.soundName=sndPick:GetSoundName() or "Default"
        e.soundChannel=chDD:GetValue() or "Master"
    end

    saveBtn:SetScript("OnClick",function()
        if editingEntry then
            ApplyToEntry(editingEntry); f:Hide(); if ns.RefreshPulseAuraList then ns.RefreshPulseAuraList() end; return
        end
        local txt=(eb:GetText() or ""):trim()
        if txt=="" then fb:SetTextColor(1,0.3,0.3); fb:SetText(ns.L["Enter a name/ID."]); return end
        local sid = ns.GetResolvedSpellID(eb)
        local addInput = sid and tostring(sid) or txt
        local ok,msg=ns:AddPulseAura(addInput, udd:GetValue(), fdd:GetValue())
        if ok then
            sid = sid or ns.GetSpellIDFromInput(addInput)
            if sid then local _,added=ns.FindSpellEntry(ns.db.pulseAuras,sid); if added then ApplyToEntry(added) end end
            f:Hide(); if ns.RefreshPulseAuraList then ns.RefreshPulseAuraList() end
        else fb:SetTextColor(1,0.3,0.3); fb:SetText(msg) end
    end)
    eb:SetScript("OnEnterPressed",function() saveBtn:Click() end)

    local function Reset()
        editingEntry=nil; eb:SetText(""); eb:Enable()
        udd:SetValue("player"); fdd:SetValue("HELPFUL")
        sndCk:SetChecked(false); sndPick:SetSoundName("Default")
        chDD:SetValue("Master"); fb:SetText("")
    end

    local editor={}
    function editor:OpenAdd()
        Reset(); f.title:SetText("|cff00ccff"..ns.L["New Pulse Aura"].."|r"); saveBtn:SetText(ns.L["Add"]); f:Show(); eb:SetFocus()
    end
    function editor:OpenWithSpellID(id)
        Reset(); eb:SetText(tostring(id)); f.title:SetText("|cff00ccff"..ns.L["New Pulse Aura"].."|r"); saveBtn:SetText(ns.L["Add"]); f:Show()
    end
    function editor:OpenEdit(entry)
        Reset(); editingEntry=entry
        eb:SetText(tostring(entry.spellID)); eb:Disable()
        udd:SetValue(entry.unit or "player"); fdd:SetValue(entry.filter or "HELPFUL")
        sndCk:SetChecked(entry.soundEnabled and true or false)
        sndPick:SetSoundName(entry.soundName or "Default")
        chDD:SetValue(entry.soundChannel or "Master")
        f.title:SetText("|cff00ccff"..ns.L["Edit Pulse Aura"].."|r"); saveBtn:SetText(ns.L["Save"]); f:Show()
    end
    return editor
end

local cursorSpellEditor, cursorAuraEditor, ringAuraEditor, pulseSpellEditor, pulseAuraEditor
local function GetCursorSpellEditor() if not cursorSpellEditor then cursorSpellEditor=CreateCursorSpellEditor() end; return cursorSpellEditor end
local function GetCursorAuraEditor() if not cursorAuraEditor then cursorAuraEditor=CreateCursorAuraEditor() end; return cursorAuraEditor end
local function GetRingAuraEditor() if not ringAuraEditor then ringAuraEditor=CreateRingAuraEditor() end; return ringAuraEditor end
local function GetPulseSpellEditor() if not pulseSpellEditor then pulseSpellEditor=CreatePulseSpellEditor() end; return pulseSpellEditor end
local function GetPulseAuraEditor() if not pulseAuraEditor then pulseAuraEditor=CreatePulseAuraEditor() end; return pulseAuraEditor end

-- ============================================================
-- Page Builders
-- ============================================================

local allSliders, allCheckboxes = {}, {}
local spellListC, cursorAuraListC, ringAuraListC
local mrtNotesC          -- scroll container con la lista de notas MRT
local mrtNoteEditor      -- modal lazy-creado para add/edit de notas
local mrtNoteViewer      -- modal lazy-creado para ver lista de entries de una nota

-- Limpia tanto frames hijos (filas) como regiones (el FontString del placeholder
-- "No spells. Add one below."). GetChildren() solo devuelve frames, así que sin
-- este segundo paso el placeholder queda vivo y se solapa con la primera fila
-- cuando la lista pasa de vacía a poblada.
local function ClearListContainer(c)
    for _,child in pairs({c:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    for _,region in pairs({c:GetRegions()}) do region:Hide() end
end

-- Intercambia dos entries de una lista del db. Marca dirty para que la siguiente
-- pasada de UpdateData del cursor display tome el nuevo orden y re-layoutee los
-- iconos en la grid.
local function SwapListEntries(list, i, j)
    if not list[i] or not list[j] or i == j then return end
    list[i], list[j] = list[j], list[i]
    ns:MarkSpellDirty(); ns:MarkAuraDirty()
end

local function RefreshSpellList()
    if not spellListC then return end
    ClearListContainer(spellListC)
    local list = ns.db.cursorSpells
    if #list==0 then
        local e=spellListC:CreateFontString(nil,"OVERLAY","GameFontDisable"); e:SetPoint("TOPLEFT",5,-8); e:SetText(ns.L["No spells. Use 'Add Cursor Spell...' below."])
        spellListC:SetHeight(30)
    else
        local n = #list
        for i,entry in ipairs(list) do
            local row=SpellRow(spellListC,entry,i,n,
                function(id) ns.RemoveSpellEntry(list,id); RefreshSpellList() end,
                function(e) GetCursorSpellEditor():OpenEdit(e) end,
                function() SwapListEntries(list, i, i-1); RefreshSpellList() end,
                function() SwapListEntries(list, i, i+1); RefreshSpellList() end)
            row:SetPoint("TOPLEFT",3,-3-(i-1)*38)
        end
        spellListC:SetHeight(n*38+6)
    end
end

local function RefreshCursorAuraList()
    if not cursorAuraListC then return end
    ClearListContainer(cursorAuraListC)
    local list = ns.db.cursorAuras
    if #list==0 then
        local e=cursorAuraListC:CreateFontString(nil,"OVERLAY","GameFontDisable"); e:SetPoint("TOPLEFT",5,-8); e:SetText(ns.L["No auras. Use 'Add Cursor Aura...' below."])
        cursorAuraListC:SetHeight(30)
    else
        local n = #list
        for i,entry in ipairs(list) do
            local row=CursorAuraRow(cursorAuraListC,entry,i,n,
                function(id) ns.RemoveSpellEntry(list,id); RefreshCursorAuraList() end,
                function(e) GetCursorAuraEditor():OpenEdit(e) end,
                function() SwapListEntries(list, i, i-1); RefreshCursorAuraList() end,
                function() SwapListEntries(list, i, i+1); RefreshCursorAuraList() end)
            row:SetPoint("TOPLEFT",3,-3-(i-1)*38)
        end
        cursorAuraListC:SetHeight(n*38+6)
    end
end

local function RefreshRingAuraList()
    if not ringAuraListC then return end
    ClearListContainer(ringAuraListC)
    if #ns.db.ringAuras==0 then
        local e=ringAuraListC:CreateFontString(nil,"OVERLAY","GameFontDisable"); e:SetPoint("TOPLEFT",5,-8); e:SetText(ns.L["No ring auras. Use 'Add Ring Aura...' below."])
        ringAuraListC:SetHeight(30)
    else
        local rh=44
        for i,entry in ipairs(ns.db.ringAuras) do
            local row=RingAuraRow(ringAuraListC,entry,i,
                function(id) ns.RemoveSpellEntry(ns.db.ringAuras,id); ns:RebuildRingDisplay(); RefreshRingAuraList() end,
                function(e) GetRingAuraEditor():OpenEdit(e) end,
                function() if ns.TestRingEntry then ns:TestRingEntry(entry, 5) end end)
            row:SetPoint("TOPLEFT",3,-3-(i-1)*rh)
        end
        ringAuraListC:SetHeight(#ns.db.ringAuras*rh+6)
    end
end

-- ==================== MRT Note List ====================
-- Forward decls: los modales se crean lazy mas abajo (despues de los otros
-- modales). Usados aqui solo dentro de closures.
local GetMrtNoteEditor, GetMrtNoteViewer

local function MrtNoteRow(parent, note, idx, onEdit, onDelete, onTest, onView)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(36)
    SubPanelBackdrop(row, 0.6)

    -- Toggle manual: el usuario decide si esta nota esta "activa" en runtime.
    -- backwards-compat: note.enabled nil = true (notas viejas activas por default).
    -- Click toggle no requiere abrir editor — pensado para alternar segun compo
    -- del raid sin perder la nota.
    local toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    toggle:SetSize(20, 20); toggle:SetPoint("LEFT", 6, 0)
    SkinCheck(toggle)
    toggle:SetChecked(note.enabled ~= false)

    -- Encounter Journal lookup: portrait + raid name. Si el encuentro no esta
    -- en el journal (id=0 o id invalido), display==nil y mostramos fallback.
    local display = ns.GetEncounterDisplay and ns.GetEncounterDisplay(note.id)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30); icon:SetPoint("LEFT", toggle, "RIGHT", 6, 0)
    local iconHasArt = display and display.icon
    if iconHasArt then
        icon:SetTexture(display.icon)
    else
        icon:SetTexture("Interface\\Icons\\Achievement_Boss_Generic")
    end

    -- Texto: "Nombre |cff888888(ID N) — Raid|r  [LFR/N/H/M]"
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    fs:SetWidth(310); fs:SetJustifyH("LEFT")
    local raidPart = (display and display.raid) and ("  |cff888888— " .. display.raid .. "|r") or ""
    -- Badge de dificultades: nil = legacy / sin filtro (no mostramos), todas marcadas
    -- tampoco aporta info, asi que solo mostramos si el usuario filtro algo.
    local diffPart = ""
    local d = note.difficulties
    if d and not (d.lfr and d.normal and d.heroic and d.mythic) then
        local tags = {}
        if d.lfr    then table.insert(tags, "R") end
        if d.normal then table.insert(tags, "N") end
        if d.heroic then table.insert(tags, "H") end
        if d.mythic then table.insert(tags, "M") end
        if #tags > 0 then
            diffPart = "  |cffffc83d[" .. table.concat(tags, "/") .. "]|r"
        end
    end
    fs:SetText(("%s |cff888888(ID %d)|r%s%s"):format(note.name or "?", note.id or 0, raidPart, diffPart))

    -- Dim/normal visuals segun enabled. Aplicado tambien al inicio asi notas
    -- importadas como disabled aparecen grises desde el principio.
    local function UpdateEnabledVisuals()
        local on = note.enabled ~= false
        if on then
            fs:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
            if iconHasArt then icon:SetVertexColor(1, 1, 1, 1)
            else icon:SetVertexColor(0.5, 0.5, 0.5, 1) end
        else
            fs:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
            icon:SetVertexColor(0.35, 0.35, 0.35, 1)
        end
    end
    UpdateEnabledVisuals()
    toggle:SetScript("OnClick", function(self)
        note.enabled = self:GetChecked() and true or false
        UpdateEnabledVisuals()
    end)

    local testBtn = Btn(row, ns.L["Test"], 56, 20); testBtn:SetPoint("RIGHT", -200, 0)
    testBtn:SetScript("OnClick", function() if onTest then onTest(idx) end end)
    local viewBtn = Btn(row, ns.L["View"], 56, 20); viewBtn:SetPoint("RIGHT", -140, 0)
    viewBtn:SetScript("OnClick", function() if onView then onView(idx) end end)
    local editBtn = Btn(row, ns.L["Edit"], 56, 20); editBtn:SetPoint("RIGHT", -80, 0)
    editBtn:SetScript("OnClick", function() if onEdit then onEdit(idx) end end)

    local delBtn = CreateFrame("Button", nil, row); delBtn:SetSize(20, 20); delBtn:SetPoint("RIGHT", -8, 0)
    local dt = delBtn:CreateFontString(nil, "OVERLAY", "GameFontRed"); dt:SetAllPoints(); dt:SetText("X")
    local dh = delBtn:CreateTexture(nil, "HIGHLIGHT"); dh:SetAllPoints(); dh:SetColorTexture(0.8, 0.2, 0.2, 0.3)
    delBtn:SetScript("OnClick", function() if onDelete then onDelete(idx) end end)
    return row
end

local function RefreshMrtNotes()
    if not mrtNotesC then return end
    ClearListContainer(mrtNotesC)
    ns.db.mrtTimeline.notes = ns.db.mrtTimeline.notes or {}
    local notes = ns.db.mrtTimeline.notes
    if #notes == 0 then
        local e = mrtNotesC:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        e:SetPoint("TOPLEFT", 5, -8)
        e:SetText(ns.L["No notes. Use 'Import note...' below."])
        mrtNotesC:SetHeight(30)
        return
    end
    local rh = 40
    for i, n in ipairs(notes) do
        local row = MrtNoteRow(mrtNotesC, n, i,
            function(idx) GetMrtNoteEditor():OpenEdit(idx, RefreshMrtNotes) end,
            function(idx) table.remove(notes, idx); RefreshMrtNotes() end,
            function(idx)
                if ns.MrtTimelineTest then ns:MrtTimelineTest(idx) end
            end,
            function(idx) GetMrtNoteViewer():Open(notes[idx]) end)
        row:SetPoint("TOPLEFT", 3, -3 - (i-1)*rh)
        row:SetPoint("TOPRIGHT", -3, -3 - (i-1)*rh)
    end
    mrtNotesC:SetHeight(#notes * rh + 6)
end

local function RefreshAllSpellLists()
    RefreshSpellList(); RefreshCursorAuraList(); RefreshRingAuraList()
end

ns.RefreshSpellList = RefreshSpellList
ns.RefreshCursorAuraList = RefreshCursorAuraList
ns.RefreshRingAuraList = RefreshRingAuraList

local function ScrollList(parent, yOffset, height)
    local lf=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    lf:SetPoint("TOPLEFT",8,yOffset); lf:SetPoint("TOPRIGHT",-8,yOffset); lf:SetHeight(height)
    SubPanelBackdrop(lf, 0.5)
    local ls=CreateFrame("ScrollFrame",nil,lf,"UIPanelScrollFrameTemplate"); ls:SetPoint("TOPLEFT",4,-4); ls:SetPoint("BOTTOMRIGHT",-16,4)
    StyleScrollBar(ls); AutoHideScrollBar(ls)
    local lc=CreateFrame("Frame",nil,ls); lc:SetWidth(500); lc:SetHeight(30); ls:SetScrollChild(lc)
    -- El scroll-child arranca con un width fijo porque al construirse `ls` aún no
    -- conoce su ancho final. En cuanto el ScrollFrame se mide, sincronizamos para
    -- que las filas (que toman parent:GetWidth() - 16) aprovechen la ventana entera.
    ls:HookScript("OnSizeChanged", function(self, w)
        if w and w > 0 then lc:SetWidth(w) end
    end)
    return lc
end

-- Page 1: Cursor Spells
local function BuildCursorSpellsPage(p)
    local y=-8
    local hd=H(p,ns.L["Cursor Spells"]); hd:SetPoint("TOPLEFT",8,y); y=y-18
    local ht=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); ht:SetPoint("TOPLEFT",8,y); ht:SetText(ns.L["Spells shown as icons near the mouse cursor. Click the gear to edit."]); y=y-16

    spellListC = ScrollList(p, y, 360); y=y-368

    local addBtn=Btn(p,ns.L["Add Cursor Spell..."],170,26); addBtn:SetPoint("TOPLEFT",8,y)
    addBtn:SetScript("OnClick",function() GetCursorSpellEditor():OpenAdd() end)

    local dzLabel=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); dzLabel:SetText(ns.L["or drag a spell here:"])
    dzLabel:SetPoint("LEFT",addBtn,"RIGHT",10,0)
    local dz=DropZone(p,260,26,function(id) GetCursorSpellEditor():OpenWithSpellID(id) end)
    dz:SetPoint("LEFT",dzLabel,"RIGHT",6,0)

    RefreshSpellList()
end

-- Page 2: Cursor Auras
local function BuildCursorAurasPage(p)
    local y=-8
    local hd=H(p,ns.L["Cursor Auras"]); hd:SetPoint("TOPLEFT",8,y); y=y-18
    local ht=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); ht:SetPoint("TOPLEFT",8,y); ht:SetText(ns.L["Auras shown as icons near the mouse cursor. Click the gear to edit."]); y=y-16

    cursorAuraListC = ScrollList(p, y, 380); y=y-388

    local addBtn=Btn(p,ns.L["Add Cursor Aura..."],170,26); addBtn:SetPoint("TOPLEFT",8,y)
    addBtn:SetScript("OnClick",function() GetCursorAuraEditor():OpenAdd() end)

    local dzLabel=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); dzLabel:SetText(ns.L["or drag a spell here:"])
    dzLabel:SetPoint("LEFT",addBtn,"RIGHT",10,0)
    local dz=DropZone(p,260,26,function(id) GetCursorAuraEditor():OpenWithSpellID(id) end)
    dz:SetPoint("LEFT",dzLabel,"RIGHT",6,0)

    RefreshCursorAuraList()
end

-- Page 3: Ring Auras
local function BuildRingAurasPage(p)
    local y=-8
    local hd=H(p,ns.L["Ring Auras"]); hd:SetPoint("TOPLEFT",8,y); y=y-18
    local ht=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); ht:SetPoint("TOPLEFT",8,y); ht:SetText(ns.L["Auras shown as circular rings around the character. Click the gear to edit, click color to change."]); y=y-16

    ringAuraListC = ScrollList(p, y, 380); y=y-388

    local addBtn=Btn(p,ns.L["Add Ring Aura..."],170,26); addBtn:SetPoint("TOPLEFT",8,y)
    addBtn:SetScript("OnClick",function() GetRingAuraEditor():OpenAdd() end)

    local dzLabel=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); dzLabel:SetText(ns.L["or drag a spell here:"])
    dzLabel:SetPoint("LEFT",addBtn,"RIGHT",10,0)
    local dz=DropZone(p,260,26,function(id) GetRingAuraEditor():OpenWithSpellID(id) end)
    dz:SetPoint("LEFT",dzLabel,"RIGHT",6,0)

    RefreshRingAuraList()
end

-- Page 4: Cursor Settings
local function BuildCursorSettingsPage(p)
    local C1,C2=20,340; local y=-8
    local hd=H(p,ns.L["Cursor Display Settings"]); hd:SetPoint("TOPLEFT",8,y); y=y-28

    -- Enable + visibility dropdown en la misma linea, Enable primero (regla
    -- del usuario para layout consistente entre todas las paginas).
    local ec=CreateCheckbox(p,ns.L["Enable cursor display"],function() return ns.db.cursorDisplay.enabled end,function(v) ns.db.cursorDisplay.enabled=v; ns:RefreshCursorDisplay() end)
    ec:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,ec)
    local cc=VisibilityDropdown(p,
        function() return ns.db.cursorDisplay.visibility end,
        function(v) ns.db.cursorDisplay.visibility=v; ns:RefreshCursorDisplay() end)
    cc:SetPoint("TOPLEFT",C2,y)
    y=y-32

    -- Integracion con MRT/NSRT timeline: cuando una entry triggerea, mostramos
    -- icono cerca del cursor (comportamiento original del modulo MRT). Toggle
    -- duplicado aqui asi el usuario activa la integracion desde el menu del
    -- modulo que la consume; cambios escriben en mrtTimeline.showInCursor.
    local mrtCk=CreateCheckbox(p,ns.L["Show MRT/NSRT triggers"],
        function() return ns.db.mrtTimeline and ns.db.mrtTimeline.showInCursor end,
        function(v) ns.db.mrtTimeline.showInCursor=v end)
    mrtCk:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,mrtCk)
    y=y-32

    local sh=SubH(p,ns.L["Size & Layout"]); sh:SetPoint("TOPLEFT",C1,y); local c1y=y-20
    local defs1={
        {ns.L["Icon Size"],16,48,2,function() return ns.db.cursorDisplay.iconSize end,function(v) ns.db.cursorDisplay.iconSize=v end},
        {ns.L["Icon Spacing"],0,10,1,function() return ns.db.cursorDisplay.iconSpacing end,function(v) ns.db.cursorDisplay.iconSpacing=v end},
        {ns.L["Max Columns"],1,12,1,function() return ns.db.cursorDisplay.maxColumns end,function(v) ns.db.cursorDisplay.maxColumns=v end},
        {ns.L["Font Size"],6,24,1,function() return ns.db.cursorDisplay.fontSize end,function(v) ns.db.cursorDisplay.fontSize=v end},
    }
    for _,d in ipairs(defs1) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C1,c1y); table.insert(allSliders,s); c1y=c1y-48 end

    local ph=SubH(p,ns.L["Position"]); ph:SetPoint("TOPLEFT",C2,y); local c2y=y-20
    local defs2={
        {ns.L["Offset X"],-100,100,5,function() return ns.db.cursorDisplay.offsetX end,function(v) ns.db.cursorDisplay.offsetX=v; ns:RefreshCursorDisplay() end},
        {ns.L["Offset Y"],-100,100,5,function() return ns.db.cursorDisplay.offsetY end,function(v) ns.db.cursorDisplay.offsetY=v; ns:RefreshCursorDisplay() end},
        {ns.L["Opacity"],0.1,1.0,0.1,function() return ns.db.cursorDisplay.opacity end,function(v) ns.db.cursorDisplay.opacity=v; ns:RefreshCursorDisplay() end},
        {ns.L["Update Interval"],0.05,0.5,0.05,function() return ns.db.cursorDisplay.updateInterval end,function(v) ns.db.cursorDisplay.updateInterval=v; ns:RefreshCursorDisplay() end},
    }
    for _,d in ipairs(defs2) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C2,c2y); table.insert(allSliders,s); c2y=c2y-48 end

    -- Live preview: cursor virtual con grid de iconos sample (3 spells + 2 auras).
    local previewY = math.min(c1y, c2y) - 12
    local ph2 = SubH(p, ns.L["Live preview"]); ph2:SetPoint("TOPLEFT", C1, previewY); previewY = previewY - 20

    local previewBox = CreateFrame("Frame", nil, p, "BackdropTemplate")
    previewBox:SetPoint("TOPLEFT", C1, previewY)
    previewBox:SetPoint("TOPRIGHT", p, "TOPRIGHT", -16, previewY)
    previewBox:SetHeight(240)
    SubPanelBackdrop(previewBox, 0.25)

    local preview = ns:CreateCursorDisplayPreview(previewBox)
    preview.container:SetAllPoints(previewBox)
end

-- Page 5: Ring Settings
local function BuildRingSettingsPage(p)
    local C1,C2=20,340; local y=-8
    local hd=H(p,ns.L["Ring Display Settings"]); hd:SetPoint("TOPLEFT",8,y); y=y-28

    -- Enable + visibility dropdown en la misma linea, Enable primero.
    local ec=CreateCheckbox(p,ns.L["Enable ring display"],function() return ns.db.ringDisplay.enabled end,function(v) ns.db.ringDisplay.enabled=v; ns:RefreshRingDisplay() end)
    ec:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,ec)
    local cc=VisibilityDropdown(p,
        function() return ns.db.ringDisplay.visibility end,
        function(v) ns.db.ringDisplay.visibility=v; ns:RefreshRingDisplay() end)
    cc:SetPoint("TOPLEFT",C2,y)
    y=y-32

    -- Integracion con MRT/NSRT: durante PRE phase de una entry, mostramos un ring
    -- overlay centrado con el spell icon + countdown. Frame vive en MrtTimeline.lua;
    -- aqui solo el toggle (escribe en mrtTimeline.showInRing).
    local mrtCk=CreateCheckbox(p,ns.L["Show MRT/NSRT triggers"],
        function() return ns.db.mrtTimeline and ns.db.mrtTimeline.showInRing end,
        function(v) ns.db.mrtTimeline.showInRing=v end)
    mrtCk:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,mrtCk)
    y=y-32

    local sh=SubH(p,ns.L["Size"]); sh:SetPoint("TOPLEFT",C1,y); local c1y=y-20
    local defs1={
        {ns.L["Base Radius"],20,200,5,function() return ns.db.ringDisplay.baseRadius end,function(v) ns.db.ringDisplay.baseRadius=v; ns:RebuildRingDisplay() end},
        {ns.L["Ring Thickness"],2,20,1,function() return ns.db.ringDisplay.ringThickness end,function(v) ns.db.ringDisplay.ringThickness=v; ns:RebuildRingDisplay() end},
        {ns.L["Ring Spacing"],1,20,1,function() return ns.db.ringDisplay.ringSpacing end,function(v) ns.db.ringDisplay.ringSpacing=v; ns:RebuildRingDisplay() end},
    }
    for _,d in ipairs(defs1) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C1,c1y); table.insert(allSliders,s); c1y=c1y-48 end
    local ph=SubH(p,ns.L["Position"]); ph:SetPoint("TOPLEFT",C1,c1y); c1y=c1y-20
    local defs1b={
        {ns.L["Offset X"],-500,500,5,function() return ns.db.ringDisplay.offsetX end,function(v) ns.db.ringDisplay.offsetX=v; ns:RefreshRingDisplay() end},
        {ns.L["Offset Y"],-500,500,5,function() return ns.db.ringDisplay.offsetY end,function(v) ns.db.ringDisplay.offsetY=v; ns:RefreshRingDisplay() end},
    }
    for _,d in ipairs(defs1b) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C1,c1y); table.insert(allSliders,s); c1y=c1y-48 end

    local ah=SubH(p,ns.L["Appearance"]); ah:SetPoint("TOPLEFT",C2,y); local c2y=y-20
    local defs2={
        {ns.L["Segments (smooth)"],24,120,12,function() return ns.db.ringDisplay.numSegments end,function(v) ns.db.ringDisplay.numSegments=v; ns:RebuildRingDisplay() end},
        {ns.L["Opacity"],0.1,1.0,0.05,function() return ns.db.ringDisplay.opacity end,function(v) ns.db.ringDisplay.opacity=v; ns:RefreshRingDisplay() end},
        {ns.L["Update Interval"],0.01,0.2,0.01,function() return ns.db.ringDisplay.updateInterval end,function(v) ns.db.ringDisplay.updateInterval=v end},
    }
    for _,d in ipairs(defs2) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C2,c2y); table.insert(allSliders,s); c2y=c2y-48 end

    -- Live preview: 3 anillos de muestra renderizados con el ringDisplay actual.
    -- Reacciona automaticamente a cualquier slider via ns._notifyRingPreviews()
    -- disparado desde Rebuild/RefreshRingDisplay.
    local previewY = math.min(c1y, c2y) - 12
    local ph2 = SubH(p, ns.L["Live preview"]); ph2:SetPoint("TOPLEFT", C1, previewY); previewY = previewY - 20

    local previewBox = CreateFrame("Frame", nil, p, "BackdropTemplate")
    previewBox:SetPoint("TOPLEFT", C1, previewY)
    previewBox:SetPoint("TOPRIGHT", p, "TOPRIGHT", -16, previewY)
    previewBox:SetHeight(240)
    SubPanelBackdrop(previewBox, 0.25)

    local preview = ns:CreateRingPreview(previewBox)
    preview.container:SetAllPoints(previewBox)
end

-- ============================================================
-- ============================================================

local pulseSpellListC, pulseAuraListC

-- Filas Pulse simplificadas (toda la edición vive en el modal). Solo pintamos:
-- icon + name + ID + badges + Edit + Remove. Botones idénticos al patrón de las
-- filas Cursor/Ring: × roja para remove, engranaje teal para edit.
local function AddRowEditRemoveButtons(row, entry, onRemove, onEdit, onTest)
    local rb = CreateFrame("Button", nil, row); rb:SetSize(20, 20); rb:SetPoint("RIGHT", -5, 0)
    local rt = rb:CreateFontString(nil, "OVERLAY", "GameFontRed"); rt:SetAllPoints(); rt:SetText("X")
    local rh = rb:CreateTexture(nil, "HIGHLIGHT"); rh:SetAllPoints(); rh:SetColorTexture(0.8, 0.2, 0.2, 0.3)
    rb:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:AddLine(ns.L["Remove"] or "Remove"); GameTooltip:Show() end)
    rb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rb:SetScript("OnClick", function() if onRemove then onRemove(entry.spellID) end end)

    local eb = CreateFrame("Button", nil, row); eb:SetSize(20, 20); eb:SetPoint("RIGHT", rb, "LEFT", -2, 0)
    local pic = eb:CreateTexture(nil, "ARTWORK"); pic:SetSize(14, 14); pic:SetPoint("CENTER")
    pic:SetTexture("Interface\\GossipFrame\\BinderGossipIcon")
    pic:SetVertexColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    local eh = eb:CreateTexture(nil, "HIGHLIGHT"); eh:SetAllPoints(); eh:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.25)
    eb:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:AddLine(ns.L["Edit"]); GameTooltip:Show() end)
    eb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    eb:SetScript("OnClick", function() if onEdit then onEdit(entry) end end)

    local tb
    if onTest then tb = AddRowTestButton(row, eb, onTest) end
    return eb, rb, tb
end

local function PulseSpellRow(parent, entry, onRemove, onEdit, onTest)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(32)
    row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    SubPanelBackdrop(row, 0.4)

    local name, icon = ns.GetSpellDisplayInfo(entry.spellID)
    local ic = row:CreateTexture(nil, "ARTWORK"); ic:SetSize(24, 24); ic:SetPoint("LEFT", 4, 0)
    ic:SetTexture(icon); ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local nm = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nm:SetPoint("LEFT", ic, "RIGHT", 8, 0); nm:SetJustifyH("LEFT")
    -- Badge de "sound": el carácter Unicode ♪ (U+266A) no está en la fuente del
    -- cliente en algunas locales y aparece como un cuadrado verde sólido (placeholder
    -- tintado por el código de color que lo envuelve). Usamos un atlas inline que
    -- siempre se renderiza correctamente en Retail.
    local sndTag = entry.soundEnabled and " |A:voicechat-icon-speaker:14:14|a" or ""
    nm:SetText(name .. sndTag .. " |cff888888(" .. entry.spellID .. ")|r")
    nm:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local editBtn, _, testBtn = AddRowEditRemoveButtons(row, entry, onRemove, onEdit, onTest)
    nm:SetPoint("RIGHT", testBtn or editBtn, "LEFT", -8, 0)
    return row
end

local function PulseAuraRow(parent, entry, onRemove, onEdit, onTest)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(32)
    row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    SubPanelBackdrop(row, 0.4)

    local name, icon = ns.GetSpellDisplayInfo(entry.spellID)
    local ic = row:CreateTexture(nil, "ARTWORK"); ic:SetSize(24, 24); ic:SetPoint("LEFT", 4, 0)
    ic:SetTexture(icon); ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local nm = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nm:SetPoint("LEFT", ic, "RIGHT", 8, 0); nm:SetJustifyH("LEFT")
    local unitTag = "|cff88ccff[" .. (entry.unit or "player") .. "]|r"
    local filterTag = (entry.filter == "HARMFUL") and "|cffff8888[debuff]|r" or "|cff88ff88[buff]|r"
    local sndTag = entry.soundEnabled and " |A:voicechat-icon-speaker:14:14|a" or ""
    nm:SetText(name .. " " .. unitTag .. filterTag .. sndTag .. " |cff888888(" .. entry.spellID .. ")|r")
    nm:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local editBtn, _, testBtn = AddRowEditRemoveButtons(row, entry, onRemove, onEdit, onTest)
    nm:SetPoint("RIGHT", testBtn or editBtn, "LEFT", -8, 0)
    return row
end

local function RefreshPulseSpellList()
    if not pulseSpellListC then return end
    ClearListContainer(pulseSpellListC)
    ns.db.pulseSpells = ns.db.pulseSpells or {}
    local list = ns.db.pulseSpells
    if #list == 0 then
        local e = pulseSpellListC:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        e:SetPoint("TOPLEFT", 5, -8); e:SetText(ns.L["No pulse spells. Add one below."])
        pulseSpellListC:SetHeight(30)
    else
        for i, entry in ipairs(list) do
            local row = PulseSpellRow(pulseSpellListC, entry,
                function(id) ns.RemoveSpellEntry(list, id); RefreshPulseSpellList() end,
                function(e) GetPulseSpellEditor():OpenEdit(e) end,
                function() if ns.TestPulseEntry then ns:TestPulseEntry(entry) end end)
            row:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 36)
        end
        pulseSpellListC:SetHeight(#list * 36 + 6)
    end
end

local function RefreshPulseAuraList()
    if not pulseAuraListC then return end
    ClearListContainer(pulseAuraListC)
    ns.db.pulseAuras = ns.db.pulseAuras or {}
    local list = ns.db.pulseAuras
    if #list == 0 then
        local e = pulseAuraListC:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        e:SetPoint("TOPLEFT", 5, -8); e:SetText(ns.L["No pulse auras. Add one below."])
        pulseAuraListC:SetHeight(30)
    else
        for i, entry in ipairs(list) do
            local row = PulseAuraRow(pulseAuraListC, entry,
                function(id) ns.RemoveSpellEntry(list, id); RefreshPulseAuraList() end,
                function(e) GetPulseAuraEditor():OpenEdit(e) end,
                function() if ns.TestPulseEntry then ns:TestPulseEntry(entry) end end)
            row:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 36)
        end
        pulseAuraListC:SetHeight(#list * 36 + 6)
    end
end

ns.RefreshPulseSpellList = RefreshPulseSpellList
ns.RefreshPulseAuraList = RefreshPulseAuraList

local function BuildPulseSpellsPage(p)
    local y = -8
    local hd = H(p, ns.L["Pulse Spells"]); hd:SetPoint("TOPLEFT", 8, y); y = y - 18
    local ht = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ht:SetPoint("TOPLEFT", 8, y); ht:SetText(ns.L["Spells that trigger a central icon pulse when their cooldown finishes."]); y = y - 16

    pulseSpellListC = ScrollList(p, y, 360); y = y - 368

    local addBtn = Btn(p, ns.L["Add Pulse Spell..."], 170, 26); addBtn:SetPoint("TOPLEFT", 8, y)
    addBtn:SetScript("OnClick", function() GetPulseSpellEditor():OpenAdd() end)

    local dzLabel=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); dzLabel:SetText(ns.L["or drag a spell here:"])
    dzLabel:SetPoint("LEFT",addBtn,"RIGHT",10,0)
    local dz=DropZone(p,260,26,function(id) GetPulseSpellEditor():OpenWithSpellID(id) end)
    dz:SetPoint("LEFT",dzLabel,"RIGHT",6,0)

    RefreshPulseSpellList()
end

local function BuildPulseAurasPage(p)
    local y = -8
    local hd = H(p, ns.L["Pulse Auras"]); hd:SetPoint("TOPLEFT", 8, y); y = y - 18
    local ht = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ht:SetPoint("TOPLEFT", 8, y); ht:SetText(ns.L["Auras that trigger a central icon pulse when gained."]); y = y - 16

    pulseAuraListC = ScrollList(p, y, 360); y = y - 368

    local addBtn = Btn(p, ns.L["Add Pulse Aura..."], 170, 26); addBtn:SetPoint("TOPLEFT", 8, y)
    addBtn:SetScript("OnClick", function() GetPulseAuraEditor():OpenAdd() end)

    local dzLabel=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); dzLabel:SetText(ns.L["or drag a spell here:"])
    dzLabel:SetPoint("LEFT",addBtn,"RIGHT",10,0)
    local dz=DropZone(p,260,26,function(id) GetPulseAuraEditor():OpenWithSpellID(id) end)
    dz:SetPoint("LEFT",dzLabel,"RIGHT",6,0)

    RefreshPulseAuraList()
end

local function BuildCooldownPulsePage(p)
    local C1,C2=20,340; local y=-8
    local hd=H(p,ns.L["Pulse Display Settings"]); hd:SetPoint("TOPLEFT",8,y); y=y-28

    -- Enable + visibility dropdown misma linea, primero (regla del usuario para
    -- layout consistente entre todas las paginas con feature toggle + combat-gate).
    local ec=CreateCheckbox(p,ns.L["Enable cooldown pulse"],function() return ns.db.cooldownPulse.enabled end,function(v) ns.db.cooldownPulse.enabled=v end)
    ec:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,ec)
    local cc=VisibilityDropdown(p,
        function() return ns.db.cooldownPulse.visibility end,
        function(v) ns.db.cooldownPulse.visibility=v end)
    cc:SetPoint("TOPLEFT",C2,y)
    y=y-32

    -- Integracion con MRT/NSRT: cuando una entry pasa a ACTIVE phase (trigger
    -- time alcanzado), disparamos un pulse con el spell icon. Bypasea el toggle
    -- enabled del cooldownPulse module (ver ShowPulse en CooldownPulse.lua).
    local mrtCk=CreateCheckbox(p,ns.L["Show MRT/NSRT triggers"],
        function() return ns.db.mrtTimeline and ns.db.mrtTimeline.showInPulse end,
        function(v) ns.db.mrtTimeline.showInPulse=v end)
    mrtCk:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,mrtCk)
    y=y-32

    local sh=SubH(p,ns.L["Size & Timing"]); sh:SetPoint("TOPLEFT",C1,y); local c1y=y-20
    local defs1={
        {ns.L["Icon Size"],32,200,4,function() return ns.db.cooldownPulse.iconSize end,function(v) ns.db.cooldownPulse.iconSize=v; ns:RefreshCooldownPulse() end},
        {ns.L["Hold Duration"],0.1,3.0,0.05,function() return ns.db.cooldownPulse.holdDuration end,function(v) ns.db.cooldownPulse.holdDuration=v end},
        {ns.L["Opacity"],0.1,1.0,0.05,function() return ns.db.cooldownPulse.opacity end,function(v) ns.db.cooldownPulse.opacity=v; ns:RefreshCooldownPulse() end},
    }
    for _,d in ipairs(defs1) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C1,c1y); table.insert(allSliders,s); c1y=c1y-48 end

    local ph=SubH(p,ns.L["Position"]); ph:SetPoint("TOPLEFT",C2,y); local c2y=y-20
    local defs2={
        {ns.L["Offset X"],-600,600,5,function() return ns.db.cooldownPulse.offsetX end,function(v) ns.db.cooldownPulse.offsetX=v; ns:RefreshCooldownPulse() end},
        {ns.L["Offset Y"],-400,400,5,function() return ns.db.cooldownPulse.offsetY end,function(v) ns.db.cooldownPulse.offsetY=v; ns:RefreshCooldownPulse() end},
    }
    for _,d in ipairs(defs2) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C2,c2y); table.insert(allSliders,s); c2y=c2y-48 end

    local btnY=math.min(c1y,c2y)-4
    local anchorBtn=Btn(p,ns.L["Show anchor"],130,24); anchorBtn:SetPoint("TOPLEFT",C1,btnY)
    local function RefreshAnchorLabel()
        anchorBtn:SetText(ns:IsCooldownPulseAnchorShown() and ns.L["Hide anchor"] or ns.L["Show anchor"])
    end
    anchorBtn:SetScript("OnClick",function() ns:ToggleCooldownPulseAnchor(); RefreshAnchorLabel() end)
    RefreshAnchorLabel()

    local testBtn=Btn(p,ns.L["Test pulse"],130,24); testBtn:SetPoint("LEFT",anchorBtn,"RIGHT",10,0)
    testBtn:SetScript("OnClick",function() ns:TestCooldownPulse() end)

    -- Live preview: pulse de muestra que se repite usando iconSize/holdDuration/
    -- opacity actuales. Reacciona a sliders via ns._notifyCooldownPulsePreviews.
    local previewY = btnY - 36
    local ph2 = SubH(p, ns.L["Live preview"]); ph2:SetPoint("TOPLEFT", C1, previewY); previewY = previewY - 20

    local previewBox = CreateFrame("Frame", nil, p, "BackdropTemplate")
    previewBox:SetPoint("TOPLEFT", C1, previewY)
    previewBox:SetPoint("TOPRIGHT", p, "TOPRIGHT", -16, previewY)
    previewBox:SetHeight(240)
    SubPanelBackdrop(previewBox, 0.25)

    local preview = ns:CreateCooldownPulsePreview(previewBox)
    preview.container:SetAllPoints(previewBox)
end

-- Page 7: Cursor Ring (anillo decorativo siguiendo al raton)
-- Catalogo de texturas vive en CursorRing.lua (ns.CURSOR_RING_TEXTURES) para
-- mantener junto el dato de calibracion por textura. Aqui solo lo consumimos.
-- Dividido en 3 sub-tabs (Ring / Cast / Dot) para que cada feature tenga su
-- propio enable y ajustes sin solapar layouts en una sola pagina larga.

-- Sub-tab 1: anillo decorativo principal (size, position, texture, color, combat).
local function BuildCursorRingMainPage(p)
    local C1,C2=20,340; local y=-8
    local hd=H(p,ns.L["Cursor Ring"]); hd:SetPoint("TOPLEFT",8,y); y=y-28

    -- Enable + visibility dropdown en la misma linea, Enable primero (regla
    -- del usuario para layout consistente entre todas las paginas).
    local ec=CreateCheckbox(p,ns.L["Enable cursor ring"],
        function() return ns.db.cursorRing.enabled end,
        function(v) ns.db.cursorRing.enabled=v; ns:RefreshCursorRing() end)
    ec:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,ec)
    local cb=VisibilityDropdown(p,
        function() return ns.db.cursorRing.visibility end,
        function(v) ns.db.cursorRing.visibility=v; ns:RefreshCursorRing() end)
    cb:SetPoint("TOPLEFT",C2,y)
    y=y-32

    local sh=SubH(p,ns.L["Size & Position"]); sh:SetPoint("TOPLEFT",C1,y); local c1y=y-20
    local defs1={
        {ns.L["Size"],16,128,2,function() return ns.db.cursorRing.size end,function(v) ns.db.cursorRing.size=v; ns:RefreshCursorRing() end},
        {ns.L["Opacity"],0.1,1.0,0.05,function() return ns.db.cursorRing.opacity end,function(v) ns.db.cursorRing.opacity=v; ns:RefreshCursorRing() end},
        {ns.L["Offset X"],-100,100,1,function() return ns.db.cursorRing.offsetX or 0 end,function(v) ns.db.cursorRing.offsetX=v; ns:RefreshCursorRing() end},
        {ns.L["Offset Y"],-100,100,1,function() return ns.db.cursorRing.offsetY or 0 end,function(v) ns.db.cursorRing.offsetY=v; ns:RefreshCursorRing() end},
    }
    for _,d in ipairs(defs1) do local s=CreateSlider(p,d[1],d[2],d[3],d[4],d[5],d[6]); s:SetPoint("TOPLEFT",C1,c1y); table.insert(allSliders,s); c1y=c1y-48 end

    local ah=SubH(p,ns.L["Appearance"]); ah:SetPoint("TOPLEFT",C2,y); local c2y=y-20

    local tl=p:CreateFontString(nil,"OVERLAY","GameFontHighlight"); tl:SetPoint("TOPLEFT",C2,c2y); tl:SetText(ns.L["Texture & thickness"])
    tl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local th=p:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); th:SetPoint("TOPLEFT",tl,"BOTTOMLEFT",0,-2)
    th:SetText(ns.L["Each option uses a different stroke width"])
    local dd=Dropdown(p, 220, ns.CURSOR_RING_TEXTURES,
        ns.db.cursorRing.texture or ns.CURSOR_RING_TEXTURES[1].value,
        function(v) ns.db.cursorRing.texture=v; ns:RefreshCursorRing() end)
    dd:SetPoint("TOPLEFT", th, "BOTTOMLEFT", 0, -4)
    c2y = c2y - 70

    local cl=p:CreateFontString(nil,"OVERLAY","GameFontHighlight"); cl:SetPoint("TOPLEFT",C2,c2y); cl:SetText(ns.L["Ring color"])
    cl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local sw=ColorSwatch(p, ns.db.cursorRing.color, function() ns:RefreshCursorRing() end)
    sw:SetSize(22,22); sw:SetPoint("LEFT", cl, "RIGHT", 8, 0)
    c2y = c2y - 28

    local by=math.min(c1y,c2y)-4
    local cc=CreateCheckbox(p,ns.L["Use class color"],
        function() return ns.db.cursorRing.useClassColor end,
        function(v) ns.db.cursorRing.useClassColor=v; ns:RefreshCursorRing() end)
    cc:SetPoint("TOPLEFT",C1,by); table.insert(allCheckboxes,cc)

    -- Live preview: cursor virtual moviendose con ring + cast + dot + FX. En
    -- esta sub-tab el ring se ve full opacity y cast/dot al 30% (focus="ring").
    local previewY = by - 36
    local ph2 = SubH(p, ns.L["Live preview"]); ph2:SetPoint("TOPLEFT", C1, previewY); previewY = previewY - 20

    local previewBox = CreateFrame("Frame", nil, p, "BackdropTemplate")
    previewBox:SetPoint("TOPLEFT", C1, previewY)
    previewBox:SetPoint("TOPRIGHT", p, "TOPRIGHT", -16, previewY)
    previewBox:SetHeight(240)
    SubPanelBackdrop(previewBox, 0.25)

    local preview = ns:CreateCursorRingPreview(previewBox, "ring")
    preview.container:SetAllPoints(previewBox)
end

-- Sub-tab 2: cast progress ring.
local function BuildCursorRingCastPage(p)
    local C1,C2=20,340; local y=-8
    local hd=H(p,ns.L["Cast progress ring"]); hd:SetPoint("TOPLEFT",8,y); y=y-28

    ns.db.cursorRing.cast = ns.db.cursorRing.cast or {}
    local cast = ns.db.cursorRing.cast
    cast.color = cast.color or {r=0.20, g=0.82, b=0.68, a=1}

    -- Enable + visibility dropdown misma linea (regla del usuario).
    local castCk=CreateCheckbox(p,ns.L["Show cast progress ring"],
        function() return cast.enabled end,
        function(v) cast.enabled=v; ns:RefreshCursorRing() end)
    castCk:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,castCk)
    local castVisDD=VisibilityDropdown(p,
        function() return cast.visibility end,
        function(v) cast.visibility=v; ns:RefreshCursorRing() end)
    castVisDD:SetPoint("TOPLEFT",C2,y)
    y=y-32

    local clbl=p:CreateFontString(nil,"OVERLAY","GameFontHighlight"); clbl:SetPoint("TOPLEFT",C1,y); clbl:SetText(ns.L["Cast color"])
    clbl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local csw=ColorSwatch(p, cast.color, function() ns:RefreshCursorRing() end)
    csw:SetSize(22,22); csw:SetPoint("LEFT", clbl, "RIGHT", 8, 0)
    y=y-30

    local castSizeSlider=CreateSlider(p,ns.L["Cast size"],8,256,1,
        function() return cast.size or 48 end,
        function(v) cast.size=v; ns:RefreshCursorRing() end)
    castSizeSlider:SetPoint("TOPLEFT",C1,y); table.insert(allSliders,castSizeSlider)

    local opSlider=CreateSlider(p,ns.L["Cast opacity"],0.1,1.0,0.05,
        function() return cast.opacity or 1 end,
        function(v) cast.opacity=v; ns:RefreshCursorRing() end)
    opSlider:SetPoint("TOPLEFT",C2,y); table.insert(allSliders,opSlider)
    y=y-50

    local dirLbl=p:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    dirLbl:SetPoint("TOPLEFT",C1,y); dirLbl:SetText(ns.L["Cast direction"])
    dirLbl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local dirDD=Dropdown(p, 160,
        {{label=ns.L["Clockwise (right)"], value="right"},
         {label=ns.L["Counter-clockwise (left)"], value="left"}},
        cast.direction or "right",
        function(v) cast.direction=v; ns:RefreshCursorRing() end)
    dirDD:SetPoint("TOPLEFT", dirLbl, "BOTTOMLEFT", 0, -4)

    -- Live preview: en esta sub-tab el cast se ve full opacity, ring/dot al 30%.
    local previewY = y - 60
    local ph2 = SubH(p, ns.L["Live preview"]); ph2:SetPoint("TOPLEFT", C1, previewY); previewY = previewY - 20

    local previewBox = CreateFrame("Frame", nil, p, "BackdropTemplate")
    previewBox:SetPoint("TOPLEFT", C1, previewY)
    previewBox:SetPoint("TOPRIGHT", p, "TOPRIGHT", -16, previewY)
    previewBox:SetHeight(240)
    SubPanelBackdrop(previewBox, 0.25)

    local preview = ns:CreateCursorRingPreview(previewBox, "cast")
    preview.container:SetAllPoints(previewBox)
end

-- Sub-tab 3: punto central.
local function BuildCursorRingDotPage(p)
    local C1,C2=20,340; local y=-8
    local hd=H(p,ns.L["Center dot"]); hd:SetPoint("TOPLEFT",8,y); y=y-28

    ns.db.cursorRing.dot = ns.db.cursorRing.dot or {}
    local dot = ns.db.cursorRing.dot
    dot.color = dot.color or {r=1, g=1, b=1, a=1}

    -- Enable + combat-gate independiente del dot, en la misma linea (regla del usuario).
    local dotCk=CreateCheckbox(p,ns.L["Show center dot"],
        function() return dot.enabled end,
        function(v) dot.enabled=v; ns:RefreshCursorRing() end)
    dotCk:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,dotCk)
    local dotVisDD=VisibilityDropdown(p,
        function() return dot.visibility end,
        function(v) dot.visibility=v; ns:RefreshCursorRing() end)
    dotVisDD:SetPoint("TOPLEFT",C2,y)
    y=y-32

    -- (la H "Center dot" del page header ya sirve como title de la primera
    -- seccion; no agregamos un SubH duplicado).
    local dlbl=p:CreateFontString(nil,"OVERLAY","GameFontHighlight"); dlbl:SetPoint("TOPLEFT",C1,y); dlbl:SetText(ns.L["Dot color"])
    dlbl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local dsw=ColorSwatch(p, dot.color, function() ns:RefreshCursorRing() end)
    dsw:SetSize(22,22); dsw:SetPoint("LEFT", dlbl, "RIGHT", 8, 0)
    y=y-30

    local dotSizeSlider=CreateSlider(p,ns.L["Dot size"],1,32,1,
        function() return dot.size or 6 end,
        function(v) dot.size=v; ns:RefreshCursorRing() end)
    dotSizeSlider:SetPoint("TOPLEFT",C1,y); table.insert(allSliders,dotSizeSlider)
    y=y-56

    -- La visibilidad del dot vive en la linea 1 (junto al Enable). Este gate
    -- es independiente del combat-gate global del anillo: el dot puede ocultarse
    -- fuera de combate aunque el anillo decorativo siga visible.
    -- Section H (mismo estilo que el page header) para separar Grow / Effects.
    local growSh=H(p,ns.L["Grow dot when moving"]); growSh:SetPoint("TOPLEFT",C1,y); y=y-26

    local growCk=CreateCheckbox(p,ns.L["Enable"],
        function() return dot.growOnMovement end,
        function(v) dot.growOnMovement=v; ns:RefreshCursorRing() end)
    growCk:SetPoint("TOPLEFT",C1,y); table.insert(allCheckboxes,growCk)

    -- Multiplicador del tamaño del dot mientras el cursor se mueve. 1.5..5.0
    -- cubre desde "ligero pulso" hasta "destaca mucho para encontrar el cursor".
    local growScaleSlider=CreateSlider(p,ns.L["Grow scale"],1.5,5.0,0.1,
        function() return dot.growScale or 2.5 end,
        function(v) dot.growScale=v end)
    growScaleSlider:SetPoint("TOPLEFT",C2,y); table.insert(allSliders,growScaleSlider)
    y=y-28

    -- Visibilidad del grow effect (independiente del gate del dot mismo): permite
    -- que el dot exista siempre pero solo crezca en combate, etc.
    local gvl=p:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    gvl:SetPoint("TOPLEFT",C1,y); gvl:SetText(ns.L["Show grow"])
    gvl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local growVisDD=VisibilityDropdown(p,
        function() return dot.growVisibility end,
        function(v) dot.growVisibility=v end)
    growVisDD:SetPoint("LEFT", gvl, "RIGHT", 8, 0)
    y=y-40

    -- ==================== Mouse trail + sparkle FX ====================
    -- Layout en dos columnas (Trail | Sparkle), inspirado en addon CursorRing:
    -- fila 1: enable checkbox, fila 2: color, fila 3: slider (length / size).
    -- Implementacion del FX vive en CursorRing.lua y lee color/length/size del
    -- dot config en cada spawn (no requiere RefreshCursorRing al editar).
    local fxh = H(p, ns.L["Effects"]); fxh:SetPoint("TOPLEFT", C1, y); y = y - 26

    local trailCk = CreateCheckbox(p, ns.L["Mouse trail"],
        function() return dot.trail end,
        function(v) dot.trail = v end)
    trailCk:SetPoint("TOPLEFT", C1, y); table.insert(allCheckboxes, trailCk)
    local sparkleCk = CreateCheckbox(p, ns.L["Sparkle effect"],
        function() return dot.sparkle end,
        function(v) dot.sparkle = v end)
    sparkleCk:SetPoint("TOPLEFT", C2, y); table.insert(allCheckboxes, sparkleCk)
    y = y - 28

    local tcl = p:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    tcl:SetPoint("TOPLEFT", C1, y); tcl:SetText(ns.L["Mouse trail color"])
    tcl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local tcsw = ColorSwatch(p, dot.trailColor, function() end)
    tcsw:SetSize(22,22); tcsw:SetPoint("LEFT", tcl, "RIGHT", 8, 0)
    local scl = p:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    scl:SetPoint("TOPLEFT", C2, y); scl:SetText(ns.L["Sparkle color"])
    scl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local scsw = ColorSwatch(p, dot.sparkleColor, function() end)
    scsw:SetSize(22,22); scsw:SetPoint("LEFT", scl, "RIGHT", 8, 0)
    y = y - 30

    local trailLenSlider = CreateSlider(p, ns.L["Mouse trail length"], 0.15, 1.5, 0.05,
        function() return dot.trailLength or 0.45 end,
        function(v) dot.trailLength = v end)
    trailLenSlider:SetPoint("TOPLEFT", C1, y); table.insert(allSliders, trailLenSlider)
    local sparkleSizeSlider = CreateSlider(p, ns.L["Sparkle size"], 0.5, 3.0, 0.1,
        function() return dot.sparkleSize or 1.0 end,
        function(v) dot.sparkleSize = v end)
    sparkleSizeSlider:SetPoint("TOPLEFT", C2, y); table.insert(allSliders, sparkleSizeSlider)
    y = y - 50

    -- Sparkle: forma + visibilidad (combat gate). Solo afecta a sparkles, no al
    -- trail. Las texturas del dropdown viven en CursorRing.lua/SPARKLE_SHAPE_TEXTURES.
    local shl = p:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    shl:SetPoint("TOPLEFT", C2, y); shl:SetText(ns.L["Sparkle shape"])
    shl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local shapeDD = Dropdown(p, 130,
        {{label=ns.L["Dot"], value="dot"},
         {label=ns.L["Ring (thin)"], value="ring_thin"},
         {label=ns.L["Ring (thick)"], value="ring_thick"},
         {label=ns.L["Wedge"], value="wedge"},
         {label=ns.L["Mixed"], value="mixed"}},
        dot.sparkleShape or "dot",
        function(v) dot.sparkleShape = v end)
    shapeDD:SetPoint("LEFT", shl, "RIGHT", 8, 0)
    y = y - 28

    local svl = p:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    svl:SetPoint("TOPLEFT", C2, y); svl:SetText(ns.L["Show sparkles"])
    svl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local visDD = Dropdown(p, 130,
        {{label=ns.L["Always"], value="always"},
         {label=ns.L["Only in combat"], value="combat"},
         {label=ns.L["Only out of combat"], value="ooc"}},
        dot.sparkleVisibility or "always",
        function(v) dot.sparkleVisibility = v end)
    visDD:SetPoint("LEFT", svl, "RIGHT", 8, 0)

    -- Trail visibility en columna izquierda, alineado con la fila de sparkle
    -- visibility para que ambas dropdowns queden a la misma altura.
    local tvl = p:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    tvl:SetPoint("TOPLEFT", C1, y); tvl:SetText(ns.L["Show trail"])
    tvl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local trailVisDD = VisibilityDropdown(p,
        function() return dot.trailVisibility end,
        function(v) dot.trailVisibility = v end)
    trailVisDD:SetPoint("LEFT", tvl, "RIGHT", 8, 0)

    -- Live preview: en esta sub-tab el dot + FX se ven full opacity, ring/cast al 30%.
    local previewY = y - 40
    local ph2 = SubH(p, ns.L["Live preview"]); ph2:SetPoint("TOPLEFT", C1, previewY); previewY = previewY - 20

    local previewBox = CreateFrame("Frame", nil, p, "BackdropTemplate")
    previewBox:SetPoint("TOPLEFT", C1, previewY)
    previewBox:SetPoint("TOPRIGHT", p, "TOPRIGHT", -16, previewY)
    previewBox:SetHeight(240)
    SubPanelBackdrop(previewBox, 0.25)

    local preview = ns:CreateCursorRingPreview(previewBox, "dot")
    preview.container:SetAllPoints(previewBox)
end

-- MRT Timeline Reminders: dos sub-tabs.
--   Encounters: lista de notas por encuentro con Test/Edit/Delete por fila, +
--                boton Import note al pie que abre el modal editor.
--   Config:     sliders de display/posicion + toggle Enable.
local function BuildMrtEncountersPage(p)
    local y = -8
    local hd = H(p, ns.L["MRT / NSRT Timeline Reminders"]); hd:SetPoint("TOPLEFT", 8, y); y = y - 28

    local ec = CreateCheckbox(p, ns.L["Enable MRT / NSRT timeline"],
        function() return ns.db.mrtTimeline.enabled end,
        function(v) ns.db.mrtTimeline.enabled = v end)
    ec:SetPoint("TOPLEFT", 20, y); table.insert(allCheckboxes, ec)
    y = y - 32

    local LIST_HEIGHT = 320
    mrtNotesC = ScrollList(p, y, LIST_HEIGHT); y = y - (LIST_HEIGHT + 12)
    ns.db.mrtTimeline.notes = ns.db.mrtTimeline.notes or {}
    RefreshMrtNotes()

    local importBtn = Btn(p, ns.L["Import note..."], 180, 24)
    importBtn:SetPoint("TOPLEFT", 20, y)
    importBtn:SetScript("OnClick", function()
        GetMrtNoteEditor():OpenAdd(RefreshMrtNotes)
    end)
end

local function BuildMrtConfigPage(p)
    local C1, C2 = 20, 340
    local y = -8
    local hd = H(p, ns.L["Display configuration"]); hd:SetPoint("TOPLEFT", 8, y); y = y - 28

    local sh = SubH(p, ns.L["Display"]); sh:SetPoint("TOPLEFT", C1, y); local c1y = y - 20
    local defs1 = {
        {ns.L["Icon Size"], 16, 96, 2,
            function() return ns.db.mrtTimeline.iconSize end,
            function(v) ns.db.mrtTimeline.iconSize = v end},
        {ns.L["Lead time (s)"], 0, 30, 1,
            function() return ns.db.mrtTimeline.leadTime end,
            function(v) ns.db.mrtTimeline.leadTime = v end},
        {ns.L["Active window (s)"], 1, 60, 1,
            function() return ns.db.mrtTimeline.activeWindow end,
            function(v) ns.db.mrtTimeline.activeWindow = v end},
        {ns.L["Ring icon size"], 16, 80, 2,
            function() return ns.db.mrtTimeline.ringIconSize end,
            function(v) ns.db.mrtTimeline.ringIconSize = v end},
    }
    for _, d in ipairs(defs1) do
        local s = CreateSlider(p, d[1], d[2], d[3], d[4], d[5], d[6])
        s:SetPoint("TOPLEFT", C1, c1y); table.insert(allSliders, s); c1y = c1y - 48
    end

    local ph = SubH(p, ns.L["Position"]); ph:SetPoint("TOPLEFT", C2, y); local c2y = y - 20
    local defs2 = {
        {ns.L["Offset X"], -200, 200, 5,
            function() return ns.db.mrtTimeline.offsetX end,
            function(v) ns.db.mrtTimeline.offsetX = v end},
        {ns.L["Offset Y"], -200, 200, 5,
            function() return ns.db.mrtTimeline.offsetY end,
            function(v) ns.db.mrtTimeline.offsetY = v end},
    }
    for _, d in ipairs(defs2) do
        local s = CreateSlider(p, d[1], d[2], d[3], d[4], d[5], d[6])
        s:SetPoint("TOPLEFT", C2, c2y); table.insert(allSliders, s); c2y = c2y - 48
    end

    -- ==================== Sound on trigger ====================
    -- Fila Sound: checkbox enable + SoundPicker (LSM-aware) + channel + Test.
    -- Mismo patron que usa Pulse para sus sonidos de ready. Se dispara al pasar
    -- a ACTIVE phase (mismo momento que el pulse, justo cuando el spell deberia
    -- castearse). Pre-llenamos picker/channel con lo que el usuario tenga guardado.
    local soundY = math.min(c1y, c2y) - 12
    local sh2 = SubH(p, ns.L["Sound"]); sh2:SetPoint("TOPLEFT", C1, soundY); soundY = soundY - 22

    local sndCk = CreateCheckbox(p, ns.L["Play sound on trigger"],
        function() return ns.db.mrtTimeline.soundEnabled end,
        function(v) ns.db.mrtTimeline.soundEnabled = v end)
    sndCk:SetPoint("TOPLEFT", C1, soundY); table.insert(allCheckboxes, sndCk)
    soundY = soundY - 30

    local sl = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sl:SetPoint("TOPLEFT", C1, soundY); sl:SetText(ns.L["Sound:"])
    sl:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local sndPick = SoundPicker(p, 200, function(name)
        ns.db.mrtTimeline.soundName = name or "Default"
    end)
    sndPick:SetPoint("LEFT", sl, "RIGHT", 6, 0)
    sndPick:SetSoundName(ns.db.mrtTimeline.soundName or "Default")

    local chLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chLabel:SetPoint("LEFT", sndPick, "RIGHT", 14, 0); chLabel:SetText(ns.L["Channel:"])
    chLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local chDD = Dropdown(p, 110, SOUND_CHANNEL_OPTIONS, ns.db.mrtTimeline.soundChannel or "Master",
        function(v) ns.db.mrtTimeline.soundChannel = v end)
    chDD:SetPoint("LEFT", chLabel, "RIGHT", 6, 0)
    soundY = soundY - 30

    local testBtn = Btn(p, ns.L["Test"], 80, 22); testBtn:SetPoint("TOPLEFT", C1, soundY)
    testBtn:SetScript("OnClick", function()
        local snd = sndPick:GetSoundName() or "Default"
        if ns.PlayAuraSound then ns.PlayAuraSound(snd, ns.db.mrtTimeline.soundChannel or "Master") end
    end)
end

-- General settings: ajustes account-wide que no pertenecen a un perfil. Hoy
-- contiene solo el override de idioma — los strings se resuelven via ns.L
-- al construir cada widget, asi que cambiar idioma necesita /reload para
-- refrescar los textos ya pintados (por eso ofrecemos boton de Reload UI).
local function BuildGeneralPage(p)
    HNZHealingToolsDB.general = HNZHealingToolsDB.general or {}
    local g = HNZHealingToolsDB.general

    local C1 = 16; local y = -8
    local hd = H(p, ns.L["General Settings"]); hd:SetPoint("TOPLEFT", 8, y); y = y - 28

    local langLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    langLabel:SetPoint("TOPLEFT", C1, y); langLabel:SetText(ns.L["Language:"])
    langLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local clientLoc = (GetLocale and GetLocale()) or "enUS"
    local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", langLabel, "RIGHT", 8, 0)
    hint:SetText(ns.L["Detected client:"] .. " " .. clientLoc)
    y = y - 22

    local opts = ns.LOCALE_OPTIONS or { { value = "auto", label = "Auto" } }
    local current = g.language or "auto"
    local dd = Dropdown(p, 220, opts, current, function(v)
        g.language = v
        if ns.ApplyLocale then ns.ApplyLocale() end
    end)
    dd:SetPoint("TOPLEFT", C1, y); y = y - 36

    local note = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", C1, y); note:SetWidth(560); note:SetJustifyH("LEFT")
    note:SetText(ns.L["Most labels are read once when the panel is built. Reload UI to refresh all text."])
    y = y - 26

    local reloadBtn = Btn(p, ns.L["Reload UI"], 130, 24); reloadBtn:SetPoint("TOPLEFT", C1, y)
    reloadBtn:SetScript("OnClick", function() if ReloadUI then ReloadUI() end end)
end

-- Modales de Export / Import de perfiles. Se construyen lazy y se reutilizan
-- para que el panel de Profiles solo muestre dos botones limpios en lugar de
-- los multiline boxes inline. Reciben un callback opcional via Open() para
-- que la pagina pueda refrescar su lista despues de un import exitoso.
local profileExportModal, profileImportModal

local function CreateProfileExportModal()
    local f = CreateEditorFrame("HNZHealingToolsProfileExportModal", ns.L["Export Profile"], 540, 320)
    local p = f.content

    local label = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 4, -4); label:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 4, -22); hint:SetText(ns.L["Ready: Ctrl+C to copy"])

    local boxFrame = MultilineBox(p, 510, 200); boxFrame:SetPoint("TOPLEFT", 4, -42)
    local box = boxFrame.editbox

    local closeBtn = Btn(f, ns.L["Close"], 90, 26); closeBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local modal = {}
    function modal:Open()
        local name = (ns.charDB and ns.charDB.activeProfile) or "Default"
        label:SetText(ns.L["Profile:"] .. " |cff00ff00" .. name .. "|r")
        local data = ns:ExportProfile(name) or ""
        box:SetText(data)
        f:Show()
        box:SetFocus()
        box:HighlightText()
    end
    return modal
end

local function CreateProfileImportModal()
    local f = CreateEditorFrame("HNZHealingToolsProfileImportModal", ns.L["Import Profile"], 540, 360)
    local p = f.content
    local onDone

    local nameLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 4, -6); nameLabel:SetText(ns.L["Name:"])
    nameLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local nameBox = EditBox(p, 220); nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)

    local pasteHint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pasteHint:SetPoint("TOPLEFT", 4, -38); pasteHint:SetText(ns.L["(paste below and press Import)"])

    local boxFrame = MultilineBox(p, 510, 200); boxFrame:SetPoint("TOPLEFT", 4, -56)
    local box = boxFrame.editbox

    local fb = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fb:SetPoint("BOTTOMLEFT", 4, 4); fb:SetPoint("BOTTOMRIGHT", -4, 4)
    fb:SetJustifyH("LEFT"); fb:SetWordWrap(true)

    local importBtn = Btn(f, ns.L["Import"], 100, 26); importBtn:SetPoint("BOTTOMRIGHT", -110, 8)
    local cancelBtn = Btn(f, ns.L["Cancel"], 90, 26); cancelBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    importBtn:SetScript("OnClick", function()
        local n = (nameBox:GetText() or ""):trim()
        if n == "" then fb:SetTextColor(1, 0.3, 0.3); fb:SetText(ns.L["Give the profile a name."]); return end
        local data = (box:GetText() or ""):trim()
        if data == "" then fb:SetTextColor(1, 0.3, 0.3); fb:SetText(ns.L["Paste the exported string in the box."]); return end
        local ok, msg = ns:ImportProfile(n, data)
        if ok then
            f:Hide()
            if onDone then onDone(n) end
        else
            fb:SetTextColor(1, 0.3, 0.3); fb:SetText(msg or ns.L["Import failed."])
        end
    end)
    nameBox:SetScript("OnEnterPressed", function() importBtn:Click() end)

    local modal = {}
    function modal:Open(cb)
        onDone = cb
        nameBox:SetText(""); box:SetText(""); fb:SetText("")
        f:Show(); nameBox:SetFocus()
    end
    return modal
end

local function GetProfileExportModal() if not profileExportModal then profileExportModal = CreateProfileExportModal() end; return profileExportModal end
local function GetProfileImportModal() if not profileImportModal then profileImportModal = CreateProfileImportModal() end; return profileImportModal end

-- ============================================================
-- MRT Note Editor modal
--
-- Un solo modal usado en dos modos: OpenAdd (crea nota nueva) y OpenEdit
-- (edita una existente). El usuario elige formato (MRT/NSRT) via dropdown;
-- cuando es NSRT y pega texto con header EncounterID:N, autocompletamos ID y
-- Name. Para MRT (que no tiene encounter ID en el formato), el usuario debe
-- entrar manualmente el ID del jefe (Wowhead url o 0 para cualquier encuentro).
-- ============================================================
local function CreateMrtNoteEditor()
    local f = CreateEditorFrame("HNZHealingToolsMrtNoteEditor", ns.L["MRT / NSRT note editor"], 600, 540)
    local p = f.content

    local editingIdx  -- nil = add mode
    local onDone

    -- Row 1: Format selector. Dos botones tipo radio (NSRT activo por defecto)
    -- en lugar de dropdown: como solo hay 2 valores, un toggle visible es mas
    -- claro y de un click. El boton seleccionado pinta con C_ACCENT; OnEnter
    -- respeta el estado para que el hover no "robe" el resaltado del activo.
    local fmtLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fmtLabel:SetPoint("TOPLEFT", 4, -8); fmtLabel:SetText(ns.L["Format:"])
    fmtLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 4, -38); hint:SetWidth(560); hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)

    local function UpdateHint(fmt)
        if fmt == "nsrt" then
            hint:SetText(ns.L["NSRT: ID and Name are auto-detected from the header. You can override below — type a boss name to search."])
        else
            hint:SetText(ns.L["MRT: paste the note. Type the boss name in the ID field to search, or enter ID 0 for any encounter."])
        end
    end

    local selectedFmt = "nsrt"
    local nsrtBtn = Btn(p, "NSRT", 70, 22)
    local mrtBtn  = Btn(p, "MRT",  70, 22)
    nsrtBtn:SetPoint("LEFT", fmtLabel, "RIGHT", 8, 0)
    mrtBtn:SetPoint("LEFT", nsrtBtn, "RIGHT", 4, 0)
    local function PaintFmt()
        local sel, unsel = (selectedFmt == "nsrt") and nsrtBtn or mrtBtn, (selectedFmt == "nsrt") and mrtBtn or nsrtBtn
        sel:SetBackdropColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
        sel:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
        unsel:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
        unsel:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7)
    end
    local function MakeFmtHandlers(btn, value)
        btn:SetScript("OnEnter", function(s)
            if selectedFmt == value then return end
            s:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 1)
            s:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9)
        end)
        btn:SetScript("OnLeave", PaintFmt)
        btn:SetScript("OnClick", function()
            selectedFmt = value; PaintFmt(); UpdateHint(value)
        end)
    end
    MakeFmtHandlers(nsrtBtn, "nsrt")
    MakeFmtHandlers(mrtBtn, "mrt")
    local fmtDD = { GetValue = function() return selectedFmt end,
                    SetValue = function(_, v) selectedFmt = (v == "mrt") and "mrt" or "nsrt"; PaintFmt(); UpdateHint(selectedFmt) end }
    PaintFmt()

    -- Row 2: ID + Name inputs
    local idLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    idLabel:SetPoint("TOPLEFT", 4, -76); idLabel:SetText(ns.L["Encounter ID:"])
    idLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local idBox = EditBox(p, 220); idBox:SetPoint("LEFT", idLabel, "RIGHT", 8, 0)
    local nameLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", idBox, "RIGHT", 14, 0); nameLabel:SetText(ns.L["Name:"])
    nameLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    local nameBox = EditBox(p, 200); nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)

    -- Autocomplete: tipear nombre del jefe en el ID box muestra una lista de
    -- encuentros del Encounter Journal. Click llena ID + Name automaticamente.
    AttachEncounterAutocomplete(idBox, nameBox)

    -- Row 3: difficulty filter. Cada nota declara en cuales dificultades aplica;
    -- en ENCOUNTER_START se filtra contra la dificultad actual. State local
    -- (selectedDiffs) que se commitea a note.difficulties en Save.
    local diffLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    diffLabel:SetPoint("TOPLEFT", 4, -106); diffLabel:SetText(ns.L["Difficulties:"])
    diffLabel:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    local selectedDiffs = { lfr = true, normal = true, heroic = true, mythic = true }
    local diffKeys = { "lfr", "normal", "heroic", "mythic" }
    local diffLabels = { lfr = ns.L["LFR"], normal = ns.L["Normal"], heroic = ns.L["Heroic"], mythic = ns.L["Mythic"] }
    local diffChecks = {}
    local prevAnchor
    for _, key in ipairs(diffKeys) do
        local ck = CreateCheckbox(p, diffLabels[key],
            function() return selectedDiffs[key] end,
            function(v) selectedDiffs[key] = v and true or false end)
        if prevAnchor then
            ck:SetPoint("LEFT", prevAnchor, "RIGHT", 70, 0)
        else
            ck:SetPoint("LEFT", diffLabel, "RIGHT", 12, 0)
        end
        diffChecks[key] = ck
        prevAnchor = ck
    end

    -- Row 4: paste box
    local pasteHint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pasteHint:SetPoint("TOPLEFT", 4, -136); pasteHint:SetText(ns.L["(paste below)"])
    local boxFrame = MultilineBox(p, 560, 240); boxFrame:SetPoint("TOPLEFT", 4, -152)
    local box = boxFrame.editbox

    -- Auto-detect en NSRT cuando se pega texto y los inputs estan vacios
    box:SetScript("OnTextChanged", function()
        if fmtDD:GetValue() ~= "nsrt" then return end
        local txt = box:GetText() or ""
        if (idBox:GetText() or ""):trim() == "" then
            local detectedID = ns.MrtParseEncounterID and ns.MrtParseEncounterID(txt)
            if detectedID then idBox:SetText(tostring(detectedID)) end
        end
        if (nameBox:GetText() or ""):trim() == "" then
            local detectedName = ns.MrtParseEncounterName and ns.MrtParseEncounterName(txt)
            if detectedName then nameBox:SetText(detectedName) end
        end
    end)

    -- Feedback
    local fb = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fb:SetPoint("BOTTOMLEFT", 4, 4); fb:SetPoint("BOTTOMRIGHT", -4, 4); fb:SetJustifyH("LEFT")

    -- Action buttons
    local saveBtn = Btn(f, ns.L["Save"], 100, 26); saveBtn:SetPoint("BOTTOMRIGHT", -110, 8)
    local cancelBtn = Btn(f, ns.L["Cancel"], 90, 26); cancelBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    saveBtn:SetScript("OnClick", function()
        local idText = (idBox:GetText() or ""):trim()
        local nameText = (nameBox:GetText() or ""):trim()
        local noteText = box:GetText() or ""
        if noteText == "" then
            fb:SetTextColor(1, 0.3, 0.3); fb:SetText(ns.L["Paste the note text first."]); return
        end
        -- Validar dificultades: al menos una marcada (si no, la nota nunca dispara).
        if not (selectedDiffs.lfr or selectedDiffs.normal or selectedDiffs.heroic or selectedDiffs.mythic) then
            fb:SetTextColor(1, 0.3, 0.3); fb:SetText(ns.L["Select at least one difficulty."]); return
        end
        local id = tonumber(idText)
        if not id then
            if fmtDD:GetValue() == "nsrt" then
                id = ns.MrtParseEncounterID and ns.MrtParseEncounterID(noteText)
            end
        end
        if not id then id = 0 end
        if nameText == "" then
            if fmtDD:GetValue() == "nsrt" then
                nameText = (ns.MrtParseEncounterName and ns.MrtParseEncounterName(noteText)) or ""
            end
            if nameText == "" then
                nameText = (id == 0) and (ns.L["Default"] or "Default") or ((ns.L["Encounter"] or "Encounter") .. " " .. id)
            end
        end

        local diffs = {
            lfr = selectedDiffs.lfr and true or false,
            normal = selectedDiffs.normal and true or false,
            heroic = selectedDiffs.heroic and true or false,
            mythic = selectedDiffs.mythic and true or false,
        }
        local notes = ns.db.mrtTimeline.notes
        if editingIdx and notes[editingIdx] then
            notes[editingIdx].id = id
            notes[editingIdx].name = nameText
            notes[editingIdx].text = noteText
            notes[editingIdx].difficulties = diffs
            -- preserva enabled (toggle manual desde la row); no se toca aqui
        else
            table.insert(notes, { id = id, name = nameText, text = noteText, difficulties = diffs, enabled = true })
        end
        f:Hide()
        if onDone then onDone() end
    end)

    local function ApplyDiffs(d)
        -- d nil = legacy nota sin filtro = todas las dificultades habilitadas.
        for _, key in ipairs(diffKeys) do
            selectedDiffs[key] = (d == nil) or (d[key] == true)
        end
        for _, ck in pairs(diffChecks) do ck:Refresh() end
    end

    local modal = {}
    function modal:OpenAdd(cb)
        editingIdx = nil; onDone = cb
        f.title:SetText(ns.L["Import note"])
        saveBtn:SetText(ns.L["Import"])
        fmtDD:SetValue("nsrt"); UpdateHint("nsrt")
        idBox:SetText(""); nameBox:SetText(""); box:SetText(""); fb:SetText("")
        ApplyDiffs(nil)  -- new note default = all 4 difficulties
        f:Show(); box:SetFocus()
    end
    function modal:OpenEdit(idx, cb)
        editingIdx = idx; onDone = cb
        local n = ns.db.mrtTimeline.notes[idx]
        if not n then return end
        f.title:SetText(ns.L["Edit note"])
        saveBtn:SetText(ns.L["Save"])
        local fmt = (n.text and n.text:find("EncounterID:", 1, true)) and "nsrt" or "mrt"
        fmtDD:SetValue(fmt); UpdateHint(fmt)
        idBox:SetText(tostring(n.id or 0))
        nameBox:SetText(n.name or "")
        box:SetText(n.text or "")
        fb:SetText("")
        ApplyDiffs(n.difficulties)
        f:Show()
    end
    return modal
end

GetMrtNoteEditor = function()
    if not mrtNoteEditor then mrtNoteEditor = CreateMrtNoteEditor() end
    return mrtNoteEditor
end

-- ============================================================
-- MRT Note Viewer modal
--
-- Read-only: dada una nota, parsea sus entries con el filtro del player y las
-- muestra como tabla (tiempo formateado | icono spell | nombre del spell). Es
-- lo que el sistema va a disparar durante el encuentro — para que el usuario
-- pueda verificar antes que coincida con lo que espera.
-- ============================================================
local function CreateMrtNoteViewer()
    local f = CreateEditorFrame("HNZHealingToolsMrtNoteViewer", ns.L["Note entries"], 520, 480)
    local p = f.content

    local titleFS = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFS:SetPoint("TOPLEFT", 4, -4)
    titleFS:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)

    local subFS = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subFS:SetPoint("TOPLEFT", 4, -26)

    local listC = ScrollList(p, -48, 360)

    local closeBtn = Btn(f, ns.L["Close"], 90, 26); closeBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Formatea tiempo en M:SS o M:SS.t (con decimal solo si el tiempo lo tiene).
    local function FormatTime(t)
        local m = math.floor(t / 60)
        local s = t - m * 60
        if math.abs(s - math.floor(s + 0.5)) < 0.05 then
            return ("%d:%02d"):format(m, math.floor(s + 0.5))
        end
        return ("%d:%05.2f"):format(m, s)
    end

    local function GetSpellTex(spellID)
        if C_Spell and C_Spell.GetSpellTexture then
            local tex = C_Spell.GetSpellTexture(spellID)
            if tex and tex ~= 0 then return tex end
        end
        return 134400
    end

    local function GetSpellName(spellID)
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            if info and info.name then return info.name end
        end
        return "Spell " .. tostring(spellID)
    end

    local modal = {}
    function modal:Open(note)
        if not note then return end
        local entries = (ns.MrtParseNote and ns.MrtParseNote(note.text)) or {}
        titleFS:SetText(("%s  |cff888888(ID %d)|r"):format(note.name or "?", note.id or 0))
        subFS:SetText(("%s: %d"):format(ns.L["Entries for you"], #entries))
        subFS:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)

        ClearListContainer(listC)
        local rh = 22
        if #entries == 0 then
            local e = listC:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            e:SetPoint("TOPLEFT", 5, -8)
            e:SetText(ns.L["No entries match your player name."])
            listC:SetHeight(30)
        else
            for i, e in ipairs(entries) do
                local row = CreateFrame("Frame", nil, listC)
                row:SetHeight(rh - 2)
                row:SetPoint("TOPLEFT", 4, -3 - (i-1)*rh)
                row:SetPoint("TOPRIGHT", -4, -3 - (i-1)*rh)
                local timeFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                timeFS:SetPoint("LEFT", 4, 0); timeFS:SetWidth(70); timeFS:SetJustifyH("LEFT")
                timeFS:SetText(FormatTime(e.time))
                timeFS:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)
                local tex = row:CreateTexture(nil, "ARTWORK")
                tex:SetSize(18, 18); tex:SetPoint("LEFT", timeFS, "RIGHT", 4, 0)
                tex:SetTexture(GetSpellTex(e.spellID))
                local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                nameFS:SetPoint("LEFT", tex, "RIGHT", 6, 0)
                nameFS:SetText(("%s |cff888888(%d)|r"):format(GetSpellName(e.spellID), e.spellID))
                nameFS:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
            end
            listC:SetHeight(#entries * rh + 6)
        end
        f:Show()
    end
    return modal
end

GetMrtNoteViewer = function()
    if not mrtNoteViewer then mrtNoteViewer = CreateMrtNoteViewer() end
    return mrtNoteViewer
end

-- Page 8: Profiles
local function BuildProfilesPage(p)
    -- y-acumulador con offsets fijos: la lista de perfiles vive dentro de un
    -- ScrollList de altura fija para que las secciones de abajo (Create / Copy /
    -- Import-Export) no se desplacen al crecer la lista.
    local y = -8
    local hd = H(p, ns.L["Profile Manager"]); hd:SetPoint("TOPLEFT", 8, y); y = y - 22
    local cl = p:CreateFontString(nil, "OVERLAY", "GameFontNormal"); cl:SetPoint("TOPLEFT", 12, y); y = y - 22
    cl:SetText(ns.L["Active: "].."|cff00ff00"..(ns.charDB.activeProfile or "Default").."|r")

    local PL_HEIGHT = 160  -- ~5 perfiles visibles antes de scrollear
    local plc = ScrollList(p, y, PL_HEIGHT); y = y - (PL_HEIGHT + 12)
    local ROW_H = 32

    local function RefreshPL()
        ClearListContainer(plc)
        -- El perfil activo siempre va primero; el resto queda alfabetico (orden
        -- natural de GetProfileList) para que el usuario lo encuentre arriba sin
        -- importar como se llame.
        local profiles = ns:GetProfileList()
        local active = ns.charDB and ns.charDB.activeProfile
        if active then
            table.sort(profiles, function(a, b)
                if a == active then return true end
                if b == active then return false end
                return a < b
            end)
        end
        for i, name in ipairs(profiles) do
            local row = CreateFrame("Frame", nil, plc, "BackdropTemplate")
            row:SetHeight(28)
            row:SetPoint("TOPLEFT", plc, "TOPLEFT", 3, -3 - (i-1)*ROW_H)
            row:SetPoint("TOPRIGHT", plc, "TOPRIGHT", -3, -3 - (i-1)*ROW_H)
            SubPanelBackdrop(row, 0.6)
            local isA = (name == ns.charDB.activeProfile)
            if isA then
                row:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9)
            end
            local nt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal"); nt:SetPoint("LEFT", 10, 0)
            if isA then
                nt:SetText(name.." |cff888888"..ns.L["(active)"].."|r")
                nt:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)
            else
                nt:SetText(name)
                nt:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
            end
            if not isA then
                local lb = Btn(row, ns.L["Load"], 50, 20); lb:SetPoint("RIGHT", -70, 0)
                lb:SetScript("OnClick", function()
                    ns:SwitchProfile(name); cl:SetText(ns.L["Active: "].."|cff00ff00"..name.."|r"); RefreshPL()
                    RefreshAllSpellLists()
                    for _, s in ipairs(allSliders) do s:Refresh() end
                    for _, c in ipairs(allCheckboxes) do c:Refresh() end
                end)
                local db = CreateFrame("Button", nil, row); db:SetSize(20, 20); db:SetPoint("RIGHT", -8, 0)
                local dt = db:CreateFontString(nil, "OVERLAY", "GameFontRed"); dt:SetAllPoints(); dt:SetText("X")
                local dh = db:CreateTexture(nil, "HIGHLIGHT"); dh:SetAllPoints(); dh:SetColorTexture(0.8, 0.2, 0.2, 0.3)
                db:SetScript("OnClick", function() ns:DeleteProfile(name); RefreshPL() end)
            end
        end
        plc:SetHeight(math.max(PL_HEIGHT, #profiles * ROW_H + 6))
    end
    RefreshPL()

    -- ==================== CREATE ====================
    local nh = SubH(p, ns.L["Create New Profile"]); nh:SetPoint("TOPLEFT", 8, y); y = y - 22
    local ne = EditBox(p, 200); ne:SetPoint("TOPLEFT", 8, y)
    local cb = Btn(p, ns.L["Create"], 80, 24); cb:SetPoint("LEFT", ne, "RIGHT", 8, 0)
    local pf = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); pf:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    y = y - 30
    cb:SetScript("OnClick", function()
        local n = ne:GetText():trim(); if n == "" then pf:SetTextColor(1, 0.3, 0.3); pf:SetText(ns.L["Enter a name."]); return end
        if ns:CreateProfile(n) then pf:SetTextColor(0, 1, 0); pf:SetText(ns.L["Created: "]..n); ne:SetText(""); RefreshPL()
        else pf:SetTextColor(1, 0.3, 0.3); pf:SetText(ns.L["Already exists."]) end
    end)
    ne:SetScript("OnEnterPressed", function() cb:Click() end)

    -- ==================== COPY ====================
    local ch = SubH(p, ns.L["Copy From Profile"]); ch:SetPoint("TOPLEFT", 8, y); y = y - 22
    local profiles = ns:GetProfileList(); local ci = {}
    for _, n in ipairs(profiles) do table.insert(ci, {label=n, value=n}) end
    if #ci == 0 then table.insert(ci, {label="Default", value="Default"}) end
    local cd = Dropdown(p, 150, ci, profiles[1]); cd:SetPoint("TOPLEFT", 8, y)
    local cpb = Btn(p, ns.L["Copy to current"], 120, 24); cpb:SetPoint("LEFT", cd, "RIGHT", 8, 0)
    local cpf = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); cpf:SetPoint("LEFT", cpb, "RIGHT", 8, 0)
    y = y - 32
    cpb:SetScript("OnClick", function()
        local from = cd:GetValue(); local to = ns.charDB.activeProfile
        if from == to then cpf:SetTextColor(1, 0.3, 0.3); cpf:SetText(ns.L["Can't copy to itself."]); return end
        if ns:CopyProfile(from, to) then
            ns.db = ns.globalDB.profiles[to]; ns:RebuildRingDisplay(); ns:RefreshRingDisplay(); ns:RefreshCursorDisplay()
            RefreshAllSpellLists()
            for _, s in ipairs(allSliders) do s:Refresh() end; for _, c in ipairs(allCheckboxes) do c:Refresh() end
            cpf:SetTextColor(0, 1, 0); cpf:SetText(ns.L["Copied from "]..from)
        end
    end)

    -- ==================== RESTORE FROM BACKUP ====================
    -- Cada migracion savedvars (Core.lua MigrateProfile) snapshotea el perfil
    -- ANTES de aplicar cambios. Aqui exponemos un dropdown con los perfiles
    -- que tienen backup, y un boton para revertirlos a su estado pre-migracion.
    -- Util si una migracion futura tiene un bug y rompe la config.
    local bh = SubH(p, ns.L["Restore from backup"]); bh:SetPoint("TOPLEFT", 8, y); y = y - 22

    -- Dropdown de perfiles con backup. Si no hay, ponemos un placeholder y
    -- deshabilitamos el boton. Reconstruimos en cada Refresh para reflejar
    -- restores que vacian el slot.
    local backupItems = {}
    local function BuildBackupItems()
        wipe(backupItems)
        local backed = ns.GetProfilesWithBackups()
        for _, n in ipairs(backed) do table.insert(backupItems, {label=n, value=n}) end
        if #backupItems == 0 then
            table.insert(backupItems, {label=ns.L["(no backups)"], value=""})
        end
    end
    BuildBackupItems()

    local infoFS = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoFS:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)

    local function RenderInfo(sel)
        if not sel or sel == "" then infoFS:SetText(""); return end
        local info = ns.GetBackupInfo(sel)
        if not info then infoFS:SetText(""); return end
        infoFS:SetText(("v%d  •  %s  •  addon %s"):format(
            info.schemaVersion or 0,
            date("%Y-%m-%d %H:%M", info.timestamp or 0),
            info.addonVersion or "?"))
    end

    local bd = Dropdown(p, 200, backupItems, backupItems[1].value, RenderInfo)
    bd:SetPoint("TOPLEFT", 8, y)
    local restoreBtn = Btn(p, ns.L["Restore"], 100, 24); restoreBtn:SetPoint("LEFT", bd, "RIGHT", 8, 0)
    infoFS:SetPoint("LEFT", restoreBtn, "RIGHT", 12, 0)
    RenderInfo(backupItems[1].value)
    y = y - 32

    restoreBtn:SetScript("OnClick", function()
        local sel = bd:GetValue()
        if not sel or sel == "" then return end
        if not ns.RestoreFromBackup(sel) then
            infoFS:SetTextColor(1, 0.3, 0.3); infoFS:SetText(ns.L["Restore failed."])
            return
        end
        -- Si restauramos el perfil activo, refrescar el runtime ahora. Los campos
        -- viejos del perfil (e.g. showOnlyInCombat boolean) no van a tomar efecto
        -- hasta /reload porque el codigo de runtime ya solo lee los campos nuevos
        -- (visibility, etc.). Avisamos en chat.
        if sel == ns.charDB.activeProfile then
            ns.db = ns.globalDB.profiles[sel]
            ns:RebuildRingDisplay(); ns:RefreshRingDisplay(); ns:RefreshCursorDisplay()
            if ns.RefreshCooldownPulse then ns:RefreshCooldownPulse() end
            if ns.RefreshCursorRing then ns:RefreshCursorRing() end
            for _, s in ipairs(allSliders) do s:Refresh() end
            for _, c in ipairs(allCheckboxes) do c:Refresh() end
            RefreshAllSpellLists()
        end
        print(("|cff00ccffHNZ Healing Tools|r: %s '%s'. %s"):format(
            ns.L["Restored profile"], sel, ns.L["Type /reload to fully apply old field formats."]))
        BuildBackupItems()
        bd:SetValue(backupItems[1].value)
        RefreshPL()
        RenderInfo(backupItems[1].value)
    end)

    -- ==================== IMPORT / EXPORT ====================
    -- Dos botones que abren modales dedicados. Mantiene la pagina compacta y
    -- evita que multiline boxes vacias ocupen espacio cuando no se usan.
    local ieh = SubH(p, ns.L["Import / Export"]); ieh:SetPoint("TOPLEFT", 8, y); y = y - 22
    local exportBtn = Btn(p, ns.L["Export current profile..."], 200, 24)
    exportBtn:SetPoint("TOPLEFT", 8, y)
    exportBtn:SetScript("OnClick", function() GetProfileExportModal():Open() end)
    local importBtn = Btn(p, ns.L["Import profile..."], 160, 24)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    importBtn:SetScript("OnClick", function()
        GetProfileImportModal():Open(function() RefreshPL() end)
    end)
end

-- ============================================================
-- Main Window
-- ============================================================

local mainWindow
local pages, menuButtons = {}, {}

function ns:CreateConfigWindow()
    -- Tamaño persistido en el profile (PROFILE_DEFAULTS lo inicializa 900x560).
    -- Sanity-clamped contra los limites de SetResizeBounds abajo, por si un
    -- profile importado trae valores fuera de rango.
    local cw = ns.db and ns.db.configWindow or {}
    local MIN_W, MIN_H = 720, 420
    local MAX_W, MAX_H = 1600, 1080
    local MW = math.max(MIN_W, math.min(MAX_W, cw.width or 900))
    local MH = math.max(MIN_H, math.min(MAX_H, cw.height or 560))
    local MENUW=150

    mainWindow=CreateFrame("Frame","HNZHealingToolsConfigWindow",UIParent,"BackdropTemplate")
    mainWindow:SetSize(MW,MH); mainWindow:SetPoint("CENTER")
    PanelBackdrop(mainWindow)
    mainWindow:SetFrameStrata("DIALOG"); mainWindow:SetMovable(true); mainWindow:SetClampedToScreen(true)
    mainWindow:EnableMouse(true); mainWindow:SetToplevel(true); mainWindow:Hide()
    mainWindow:SetResizable(true)
    mainWindow:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
    table.insert(UISpecialFrames,"HNZHealingToolsConfigWindow")

    -- Title bar (drag region)
    local tb=CreateFrame("Frame",nil,mainWindow); tb:SetHeight(30); tb:SetPoint("TOPLEFT",0,0); tb:SetPoint("TOPRIGHT",-30,0)
    tb:EnableMouse(true); tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart",function() mainWindow:StartMoving() end)
    tb:SetScript("OnDragStop",function() mainWindow:StopMovingOrSizing() end)
    local tt=tb:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); tt:SetPoint("LEFT",12,0); tt:SetText("HNZ Healing Tools")
    tt:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)

    -- Custom flat close button (top-right). Va por encima del title bar para que reciba clics.
    local cb=CreateFrame("Button",nil,mainWindow,"BackdropTemplate"); cb:SetSize(20,20); cb:SetPoint("TOPRIGHT",-8,-5)
    cb:SetFrameLevel(tb:GetFrameLevel()+5)
    ElementBackdrop(cb)
    local cbX=cb:CreateFontString(nil,"OVERLAY","GameFontNormal"); cbX:SetPoint("CENTER"); cbX:SetText("x")
    cbX:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
    cb:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(1,0.3,0.3,1); cbX:SetTextColor(1,0.3,0.3) end)
    cb:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.5); cbX:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b) end)
    cb:SetScript("OnClick",function() mainWindow:Hide() end)

    -- Resize grip en la esquina inferior derecha. Usa las texturas estandar de
    -- chat-frame para que sea reconocible. StartSizing("BOTTOMRIGHT") mantiene
    -- la esquina TOPLEFT anclada (el SetPoint("CENTER") inicial se ignora una
    -- vez que el usuario arrastra). OnMouseUp persiste el nuevo tamaño en
    -- ns.db.configWindow para que sobreviva entre sesiones.
    local rg=CreateFrame("Button",nil,mainWindow); rg:SetSize(16,16); rg:SetPoint("BOTTOMRIGHT",-2,2)
    rg:SetFrameLevel(mainWindow:GetFrameLevel()+10)
    rg:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    rg:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    rg:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    rg:SetScript("OnMouseDown",function() mainWindow:StartSizing("BOTTOMRIGHT") end)
    rg:SetScript("OnMouseUp",function()
        mainWindow:StopMovingOrSizing()
        if ns.db.configWindow then
            ns.db.configWindow.width = math.floor(mainWindow:GetWidth() + 0.5)
            ns.db.configWindow.height = math.floor(mainWindow:GetHeight() + 0.5)
        end
    end)

    -- Scale +/- compactos en la barra de título (mismo z-bump que el cerrar)
    local curScale=100
    local function MakeScaleBtn(label)
        local b=CreateFrame("Button",nil,mainWindow,"BackdropTemplate"); b:SetSize(20,20)
        b:SetFrameLevel(tb:GetFrameLevel()+5)
        ElementBackdrop(b)
        local fs=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); fs:SetPoint("CENTER"); fs:SetText(label)
        fs:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
        b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9) end)
        b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.5) end)
        return b
    end
    local sp=MakeScaleBtn("+"); sp:SetPoint("RIGHT",cb,"LEFT",-4,0)
    local sl=mainWindow:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); sl:SetPoint("RIGHT",sp,"LEFT",-4,0); sl:SetText("100%")
    sl:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
    local sm=MakeScaleBtn("-"); sm:SetPoint("RIGHT",sl,"LEFT",-4,0)
    local function AS(v) curScale=math.max(60,math.min(150,v)); mainWindow:SetScale(curScale/100); sl:SetText(curScale.."%") end
    sm:SetScript("OnClick",function() AS(curScale-10) end); sp:SetScript("OnClick",function() AS(curScale+10) end)

    -- Sidebar (panel plano, sin recuadros por botón)
    local mbg=CreateFrame("Frame",nil,mainWindow,"BackdropTemplate")
    mbg:SetPoint("TOPLEFT",10,-36); mbg:SetPoint("BOTTOMLEFT",10,10); mbg:SetWidth(MENUW)
    SubPanelBackdrop(mbg, 0.5)

    -- Content area (panel plano sutil)
    local ca=CreateFrame("Frame",nil,mainWindow,"BackdropTemplate")
    ca:SetPoint("TOPLEFT",mbg,"TOPRIGHT",8,0); ca:SetPoint("BOTTOMRIGHT",-10,10)
    SubPanelBackdrop(ca, 0.3)

    local pageDefs={
        {name=ns.L["Cursor"], subtabs={
            {name=ns.L["Spells"], builder=BuildCursorSpellsPage},
            {name=ns.L["Auras"],  builder=BuildCursorAurasPage},
            {name=ns.L["Config"], builder=BuildCursorSettingsPage},
        }},
        {name=ns.L["Ring"], subtabs={
            {name=ns.L["Auras"],  builder=BuildRingAurasPage},
            {name=ns.L["Config"], builder=BuildRingSettingsPage},
        }},
        {name=ns.L["Pulse"], subtabs={
            {name=ns.L["Spells"], builder=BuildPulseSpellsPage},
            {name=ns.L["Auras"],  builder=BuildPulseAurasPage},
            {name=ns.L["Config"], builder=BuildCooldownPulsePage},
        }},
        {name=ns.L["Cursor Ring"], subtabs={
            {name=ns.L["Ring"], builder=BuildCursorRingMainPage},
            {name=ns.L["Cast"], builder=BuildCursorRingCastPage},
            {name=ns.L["Dot"],  builder=BuildCursorRingDotPage},
        }},
        {name=ns.L["MRT / NSRT"], subtabs={
            {name=ns.L["Encounters"], builder=BuildMrtEncountersPage},
            {name=ns.L["Config"],     builder=BuildMrtConfigPage},
        }},
        {name=ns.L["General"],       builder=BuildGeneralPage},
        {name=ns.L["Profiles"],      builder=BuildProfilesPage},
    }

    -- Helper: build a ScrollFrame inside `parentArea` containing the page produced
    -- by `builder`. `topOffset` lets us reserve vertical space for a subtab bar above.
    local function MakeScrollPage(parentArea, builder, topOffset)
        topOffset = topOffset or 0
        local ps=CreateFrame("ScrollFrame",nil,parentArea,"UIPanelScrollFrameTemplate")
        ps:SetPoint("TOPLEFT",8,-8-topOffset); ps:SetPoint("BOTTOMRIGHT",-8,8); ps:Hide()
        StyleScrollBar(ps); AutoHideScrollBar(ps)
        local pc=CreateFrame("Frame",nil,ps); pc:SetWidth(parentArea:GetWidth() or 620); pc:SetHeight(1000); ps:SetScrollChild(pc)
        builder(pc)
        ps:HookScript("OnShow", function(self)
            C_Timer.After(0, function() FitScrollChildHeightNow(pc, 24) end)
        end)
        -- Sync pc width con parentArea cuando la ventana se redimensiona. Los
        -- elementos que usan TOPRIGHT (previews, etc.) se reflejnean solos via
        -- anchors; los rows que usan SetSize(parent:GetWidth()-6, ...) quedan
        -- con el ancho del momento de su build — aceptable, no rompe layout.
        parentArea:HookScript("OnSizeChanged", function(_, w, h)
            pc:SetWidth(w)
        end)
        return ps
    end

    local function StyleSubBtn(b, active)
        if active then
            b:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 0.7)
            b:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9)
            b.Text:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)
        else
            b:SetBackdropColor(C_PANEL.r, C_PANEL.g, C_PANEL.b, 0.4)
            b:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.6)
            b.Text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
        end
    end

    for i,def in ipairs(pageDefs) do
        if def.subtabs then
            -- Container that hosts a horizontal sub-tab bar plus one ScrollFrame per subtab
            local container=CreateFrame("Frame",nil,ca)
            container:SetPoint("TOPLEFT",0,0); container:SetPoint("BOTTOMRIGHT",0,0); container:Hide()

            local SUBBAR_H=22
            local subBar=CreateFrame("Frame",nil,container)
            subBar:SetPoint("TOPLEFT",8,-8); subBar:SetPoint("TOPRIGHT",-8,-8); subBar:SetHeight(SUBBAR_H)

            local subPages, subBtns = {}, {}
            for j,sub in ipairs(def.subtabs) do
                subPages[j]=MakeScrollPage(container, sub.builder, SUBBAR_H+8)
            end

            local function ShowSubPage(idx)
                for k,sp in ipairs(subPages) do sp:SetShown(k==idx) end
                for k,sb in ipairs(subBtns) do StyleSubBtn(sb, k==idx) end
            end

            local btnX=0
            for j,sub in ipairs(def.subtabs) do
                local sb=CreateFrame("Button",nil,subBar,"BackdropTemplate")
                sb:SetSize(96,SUBBAR_H); sb:SetPoint("LEFT",subBar,"LEFT",btnX,0)
                sb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
                sb.Text=sb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sb.Text:SetPoint("CENTER"); sb.Text:SetText(sub.name)
                sb:SetScript("OnClick",function() ShowSubPage(j) end)
                subBtns[j]=sb
                StyleSubBtn(sb, j==1)
                btnX=btnX+100
            end

            container:HookScript("OnShow", function() ShowSubPage(1) end)
            ShowSubPage(1)
            pages[i]=container
        else
            pages[i]=MakeScrollPage(ca, def.builder, 0)
        end
    end

    local function StyleMenuBtn(btn, active)
        if active then
            btn:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 0.6)
            if btn.accent then btn.accent:Show() end
            btn.Text:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)
        else
            btn:SetBackdropColor(0,0,0,0)
            if btn.accent then btn.accent:Hide() end
            btn.Text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
        end
    end

    local function ShowPage(idx)
        for i,pg in ipairs(pages) do pg:SetShown(i==idx) end
        for i,btn in ipairs(menuButtons) do StyleMenuBtn(btn, i==idx) end
    end

    for i,def in ipairs(pageDefs) do
        local btn=CreateFrame("Button",nil,mbg,"BackdropTemplate")
        btn:SetHeight(26); btn:SetPoint("TOPLEFT",0,-6-(i-1)*28); btn:SetPoint("TOPRIGHT",0,-6-(i-1)*28)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"})
        btn:SetBackdropColor(0,0,0,0)
        -- Barra de acento a la izquierda (visible cuando la pestaña está activa)
        btn.accent=btn:CreateTexture(nil,"OVERLAY"); btn.accent:SetPoint("TOPLEFT",0,0); btn.accent:SetPoint("BOTTOMLEFT",0,0); btn.accent:SetWidth(3)
        btn.accent:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1); btn.accent:Hide()
        btn.Text=btn:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); btn.Text:SetPoint("LEFT",14,0); btn.Text:SetText(def.name)
        btn.Text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
        btn:SetScript("OnEnter",function(s) if not s._active then s:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 0.4) end end)
        btn:SetScript("OnLeave",function(s) if not s._active then s:SetBackdropColor(0,0,0,0) end end)
        btn:SetScript("OnClick",function()
            for j,b in ipairs(menuButtons) do b._active=(j==i) end
            ShowPage(i)
        end)
        menuButtons[i]=btn
    end

    mainWindow:SetScript("OnShow",function()
        for j,b in ipairs(menuButtons) do b._active=(j==1) end
        ShowPage(1); RefreshAllSpellLists()
    end)
    menuButtons[1]._active=true
    ShowPage(1)
end

function ns:ToggleConfigWindow() if mainWindow:IsShown() then mainWindow:Hide() else mainWindow:Show() end end
