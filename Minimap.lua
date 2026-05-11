local addonName, ns = ...

local BUTTON_NAME   = "HNZHealingToolsMinimapButton"
local ICON_TEXTURE  = "Interface\\Icons\\Spell_Nature_HealingTouch"
local DEFAULT_ANGLE = 210
local RADIUS        = 80

local function GetMinimapDB()
    HNZHealingToolsDB.minimap = HNZHealingToolsDB.minimap or {}
    local m = HNZHealingToolsDB.minimap
    if m.angle == nil then m.angle = DEFAULT_ANGLE end
    if m.hide  == nil then m.hide  = false end
    return m
end
ns.GetMinimapDB = GetMinimapDB

local function UpdatePosition(button)
    local angle = math.rad(GetMinimapDB().angle)
    local x = math.cos(angle) * RADIUS
    local y = math.sin(angle) * RADIUS
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate(self)
    local mx, my = Minimap:GetCenter()
    if not mx then return end
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    local angle = math.deg(math.atan2(py - my, px - mx))
    GetMinimapDB().angle = angle
    UpdatePosition(self)
end

local function ShowTooltip(self)
    local L = ns.L
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff34d0afHNZ Healing Tools|r")
    GameTooltip:AddLine("|cffffffff" .. L["Left click:"] .. "|r " .. L["open/close config"], 1, 1, 1)
    GameTooltip:AddLine("|cffffffff" .. L["Right click:"] .. "|r " .. L["toggle cursor + ring icons"], 1, 1, 1)
    GameTooltip:AddLine("|cffffffff" .. L["Drag:"] .. "|r " .. L["move icon"], 1, 1, 1)
    GameTooltip:Show()
end

function ns:InitMinimapButton()
    if _G[BUTTON_NAME] then return end
    local db = GetMinimapDB()

    local b = CreateFrame("Button", BUTTON_NAME, Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetMovable(true)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20); bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17); icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture(ICON_TEXTURE)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local accent = ns._theme and ns._theme.ACCENT or {r=0.20, g=0.82, b=0.68}
    icon:SetVertexColor(accent.r, accent.g, accent.b, 1)
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53); border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    b:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then
            if ns.ToggleConfigWindow then ns:ToggleConfigWindow() end
        elseif btn == "RightButton" then
            if ns.ToggleCursorDisplay then ns:ToggleCursorDisplay() end
            if ns.ToggleRingDisplay  then ns:ToggleRingDisplay()  end
        end
    end)

    b:SetScript("OnEnter", ShowTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", OnDragUpdate)
        GameTooltip:Hide()
    end)
    b:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    UpdatePosition(b)
    if db.hide then b:Hide() end
    ns.minimapButton = b
end

function ns:ShowMinimapButton()
    GetMinimapDB().hide = false
    if ns.minimapButton then ns.minimapButton:Show() end
end

function ns:HideMinimapButton()
    GetMinimapDB().hide = true
    if ns.minimapButton then ns.minimapButton:Hide() end
end

function ns:ToggleMinimapButton()
    if GetMinimapDB().hide then ns:ShowMinimapButton() else ns:HideMinimapButton() end
end
