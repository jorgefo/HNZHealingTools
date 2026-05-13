local addonName, ns = ...

-- ============================================================
-- "What's New" popup: cuando el usuario actualiza el addon, mostramos una vez
-- las notas de las versiones nuevas. Estado persistido en
-- HNZHealingToolsDB.lastSeenVersion (account-wide, NO por profile — asi un
-- usuario con varios alts no ve el popup 10 veces).
--
-- Para agregar notas al publicar una nueva version:
--   1. Bump del Version en HNZHealingTools.toc
--   2. Agregar entry nueva al frente de RELEASE_NOTES (mas reciente primero)
--   3. Update del CHANGELOG.md (por convencion)
-- El popup filtra por version > lastSeenVersion, asi entries viejas pueden
-- quedarse en la tabla sin re-mostrar.
-- ============================================================

local RELEASE_NOTES = {
    {
        version = "1.3.0",
        date = "2026-05-13",
        items = {
            "Live preview en el config para Ring, Pulse, Cursor Ring y Cursor Icons — todos los sliders se reflejan en vivo.",
            "Reordenar entries en Cursor Spells / Auras con flechas arriba/abajo en cada fila.",
            "Boton Test (T) por entry — fuerza el icono al cursor real durante 5s para previsualizar como se ve.",
            "Ventana de config redimensionable desde la esquina inferior derecha (tamano se persiste por profile).",
            "Texturas custom para las flechas de mover (incluidas en el addon, no dependen de built-ins).",
            "Editor de notas MRT/NSRT: el selector de formato ahora son 2 botones tipo radio (NSRT default).",
            "Fix: el pulse de MRT/NSRT ahora aparece aunque el Cooldown Pulse tenga visibility distinto a 'always'.",
            "Este popup de notas que aparece una sola vez al instalar una version nueva.",
        },
    },
}

-- Compara strings de version semver-style. Devuelve -1, 0, 1 (a<b, a==b, a>b).
local function CompareVersions(a, b)
    if not a then return -1 end
    if not b then return 1 end
    local function parts(v)
        local r = {}
        for n in tostring(v):gmatch("%d+") do r[#r+1] = tonumber(n) end
        return r
    end
    local pa, pb = parts(a), parts(b)
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x < y then return -1 end
        if x > y then return 1 end
    end
    return 0
end

local whatsNewFrame

local function CreateWhatsNewFrame()
    local f = CreateFrame("Frame", "HNZHealingToolsWhatsNew", UIParent, "BackdropTemplate")
    f:SetSize(540, 440)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetToplevel(true)
    f:Hide()
    table.insert(UISpecialFrames, "HNZHealingToolsWhatsNew")

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.07, 0.09, 0.96)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Drag region en el title bar.
    local tb = CreateFrame("Frame", nil, f); tb:SetHeight(30)
    tb:SetPoint("TOPLEFT", 0, 0); tb:SetPoint("TOPRIGHT", -30, 0)
    tb:EnableMouse(true); tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() f:StartMoving() end)
    tb:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 14, 0); title:SetPoint("TOP", 0, -8)
    title:SetText("HNZ Healing Tools — " .. (ns.L["What's New"] or "What's New"))
    title:SetTextColor(0.30, 0.85, 0.78)

    -- Close button (X).
    local cb = CreateFrame("Button", nil, f, "BackdropTemplate"); cb:SetSize(20, 20); cb:SetPoint("TOPRIGHT", -8, -5)
    cb:SetFrameLevel(tb:GetFrameLevel() + 5)
    cb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    cb:SetBackdropColor(0.1, 0.1, 0.12, 0.8); cb:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.5)
    local cbx = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal"); cbx:SetPoint("CENTER"); cbx:SetText("x")
    cbx:SetTextColor(0.8, 0.8, 0.8)
    cb:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(1, 0.3, 0.3, 1); cbx:SetTextColor(1, 0.3, 0.3) end)
    cb:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.5); cbx:SetTextColor(0.8, 0.8, 0.8) end)
    cb:SetScript("OnClick", function() f:Hide() end)

    -- ScrollFrame con el contenido.
    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 14, -36)
    sf:SetPoint("BOTTOMRIGHT", -32, 46)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(480, 100)
    sf:SetScrollChild(content)
    f.content = content
    f.scrollFrame = sf

    -- Boton OK al pie.
    local okBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    okBtn:SetSize(120, 26)
    okBtn:SetPoint("BOTTOM", 0, 12)
    okBtn:SetText(ns.L["Got it"] or "Got it")
    okBtn:SetScript("OnClick", function() f:Hide() end)

    return f
end

local function BuildContent(content, notesToShow)
    -- Limpia children y regions del rebuild anterior.
    for _, child in pairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    for _, region in pairs({content:GetRegions()}) do region:Hide() end

    content:SetWidth(480)
    local width = 480
    local y = -4
    for _, note in ipairs(notesToShow) do
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", 8, y)
        header:SetText("v" .. note.version .. (note.date and (" |cff888888(" .. note.date .. ")|r") or ""))
        header:SetTextColor(0.30, 0.85, 0.78)
        y = y - 24

        for _, item in ipairs(note.items) do
            local bullet = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            bullet:SetPoint("TOPLEFT", 20, y)
            bullet:SetWidth(width - 28)
            bullet:SetJustifyH("LEFT")
            bullet:SetWordWrap(true)
            bullet:SetText("• " .. item)
            local h = bullet:GetStringHeight()
            if not h or h < 14 then h = 14 end
            y = y - h - 4
        end
        y = y - 8
    end

    -- Altura final del scroll child (positivo).
    content:SetHeight(math.max(120, math.abs(y) + 8))
end

function ns:ShowWhatsNew()
    -- API publica: fuerza mostrar el popup con TODAS las release notes (para
    -- comando slash o boton manual). No toca lastSeenVersion.
    if not whatsNewFrame then whatsNewFrame = CreateWhatsNewFrame() end
    BuildContent(whatsNewFrame.content, RELEASE_NOTES)
    whatsNewFrame:Show()
end

function ns:ShowWhatsNewIfNeeded()
    if not HNZHealingToolsDB then return end
    local currentVersion
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        currentVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")
    elseif GetAddOnMetadata then
        currentVersion = GetAddOnMetadata(addonName, "Version")
    end
    if not currentVersion or currentVersion == "" then return end

    local lastSeen = HNZHealingToolsDB.lastSeenVersion

    -- No-op si ya vimos esta version (o una mas nueva).
    if lastSeen and CompareVersions(currentVersion, lastSeen) <= 0 then return end

    -- Que notas mostrar:
    --   - Primera instalacion (lastSeen == nil): solo la latest entry.
    --   - Upgrade: todas las versiones entre lastSeen (exclusive) y current (inclusive).
    local toShow = {}
    if not lastSeen then
        if RELEASE_NOTES[1] and CompareVersions(RELEASE_NOTES[1].version, currentVersion) <= 0 then
            table.insert(toShow, RELEASE_NOTES[1])
        end
    else
        for _, n in ipairs(RELEASE_NOTES) do
            if CompareVersions(n.version, lastSeen) > 0 and CompareVersions(n.version, currentVersion) <= 0 then
                table.insert(toShow, n)
            end
        end
        table.sort(toShow, function(a, b) return CompareVersions(a.version, b.version) > 0 end)
    end

    -- Siempre persistir current, incluso si toShow esta vacio (bumps sin notas).
    HNZHealingToolsDB.lastSeenVersion = currentVersion

    if #toShow == 0 then return end

    if not whatsNewFrame then whatsNewFrame = CreateWhatsNewFrame() end
    BuildContent(whatsNewFrame.content, toShow)
    whatsNewFrame:Show()
end
