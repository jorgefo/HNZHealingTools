local _, ns = ...

-- AuctionRestock (archivo legacy llamado VendorRestock.lua para no romper
-- refs externos): cuando el player abre la casa de subastas
-- (AUCTION_HOUSE_SHOW), aparece un boton flotante "Restock" que busca los
-- items configurados via commodity API y muestra precios actuales. Click en
-- el boton dispara una busqueda de AH para los items con deficit — el user
-- compra via la UI estandar de Blizzard. Trackeamos COMMODITY_PURCHASE_SUCCEEDED
-- pasivamente para registrar lastPaid (precio pagado por unidad).
--
-- Por que NO auto-compramos:
-- - Commodity buy requiere confirmacion del server (StartCommoditiesPurchase
--   -> COMMODITY_PRICE_UPDATED -> ConfirmCommoditiesPurchase) y el flow
--   tiene timing constraints. La UI estandar maneja bien.
-- - Auto-buy multiple items en cola es fragil (precios cambian, items
--   indisponibles, errores intermitentes). Dejar que Blizzard valide.
-- - Tracking pasivo de lastPaid sigue funcionando: si el user compra via
--   la UI normal Y el itemID matchea uno configurado, persistimos el precio.
--
-- v2 podria agregar auto-buy. Por ahora: "asistente de busqueda + tracker".

local CreateFrame = CreateFrame
local UIParent = UIParent
local C_AuctionHouse = C_AuctionHouse
local GameTooltip = GameTooltip
local UnitAffectingCombat = UnitAffectingCombat
local GetCoinTextureString = GetCoinTextureString
local _GetItemCount = GetItemCount or (C_Item and C_Item.GetItemCount)
local function GetItemCount(id)
    if not (_GetItemCount and id) then return 0 end
    return _GetItemCount(id, false, false, false, false) or 0
end
local GetItemIcon = GetItemIcon or (C_Item and C_Item.GetItemIconByID)

local restockButton

-- ============================================================
-- Search cache
-- ============================================================
-- Por itemID: { unitPrice (cheapest), totalAvailable, resolvedAt (time()) }.
-- nil = nunca buscado, o no resuelto todavia. `_pendingSearches` marca que
-- enviamos una query y esperamos COMMODITY_SEARCH_RESULTS_UPDATED.
local _searchCache = {}
local _pendingSearches = {}

local function IsAuctionHouseAvailable()
    return C_AuctionHouse ~= nil
        and C_AuctionHouse.MakeItemKey ~= nil
        and C_AuctionHouse.SendSearchQuery ~= nil
end

local function IsAuctionHouseShown()
    local f = _G.AuctionHouseFrame
    return f and f:IsShown() and true or false
end

-- Envia query commodity para un itemID. Async — los results entran via
-- COMMODITY_SEARCH_RESULTS_UPDATED. No-op si ya hay query en vuelo para el
-- mismo itemID, si el AH no esta abierto, o si el throttle no esta listo
-- (mejor demorar que mandar y que el server dropee silenciosamente).
local function RequestSearchForItem(itemID)
    if not itemID or not IsAuctionHouseAvailable() then return end
    if not IsAuctionHouseShown() then return end
    if _pendingSearches[itemID] then return end
    -- Throttle check pre-send (SendSearchQuery NO es protegida, asi que es
    -- safe de llamar tanto desde click como desde event handler).
    if C_AuctionHouse.IsThrottledMessageSystemReady
       and not C_AuctionHouse.IsThrottledMessageSystemReady() then
        -- Reintentamos en 1s; AUCTION_HOUSE_THROTTLED_SYSTEM_READY tambien
        -- pateara a flush de pending searches.
        C_Timer.After(1, function() RequestSearchForItem(itemID) end)
        return
    end
    local key = C_AuctionHouse.MakeItemKey(itemID)
    local sorts
    if Enum and Enum.AuctionHouseSortOrder then
        sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } }
    end
    _pendingSearches[itemID] = true
    local ok = pcall(C_AuctionHouse.SendSearchQuery, key, sorts, true)
    if not ok then
        _pendingSearches[itemID] = false
    end
end

local function ReadSearchResults(itemID)
    if not C_AuctionHouse then return end
    local total = (C_AuctionHouse.GetCommoditySearchResultsQuantity
        and C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID)) or 0
    local cheapest = 0
    if total > 0 and C_AuctionHouse.GetCommoditySearchResultInfo then
        local info = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, 1)
        if info and info.unitPrice then
            cheapest = info.unitPrice
        end
    end
    _searchCache[itemID] = {
        unitPrice = cheapest,
        totalAvailable = total,
        resolvedAt = time and time() or 0,
    }
    _pendingSearches[itemID] = nil
end

-- Itera items configurados y manda una query por cada uno que necesita
-- restock. Sequencial — sendear todas en burst no acelera mucho porque el
-- server tiene rate limits propios, y secuencial es mas amigable.
local function RequestSearchForAllConfigured()
    local s = ns.db and ns.db.vendorRestock
    if not s or not s.items then return end
    for _, e in ipairs(s.items) do
        if e and e.itemID and e.enabled ~= false then
            local target = tonumber(e.target) or 0
            if target > 0 then
                local have = GetItemCount(e.itemID)
                if have < target then
                    RequestSearchForItem(e.itemID)
                end
            end
        end
    end
end

-- ============================================================
-- Shopping list (basado en search cache + bag count)
-- ============================================================

-- Cada entry de salida:
--   { entry, itemID, name, need, status, unitPrice, totalAvailable,
--     affordableQuantity, estimatedCost }
-- status: "buyable" | "tooExpensive" | "unavailable" | "searching" | "pending"
local function ComputeShoppingList()
    local out = {}
    local s = ns.db and ns.db.vendorRestock
    if not s or not s.items then return out end
    for _, entry in ipairs(s.items) do
        if entry.enabled ~= false and entry.itemID then
            local target = tonumber(entry.target) or 0
            if target > 0 then
                local have = GetItemCount(entry.itemID)
                local need = target - have
                if need > 0 then
                    local row = {
                        entry = entry,
                        itemID = entry.itemID,
                        need = need,
                        name = (ns.GetItemDisplayInfo and ns.GetItemDisplayInfo(entry.itemID)) or ("item:" .. entry.itemID),
                    }
                    local cache = _searchCache[entry.itemID]
                    if cache then
                        row.unitPrice = cache.unitPrice
                        row.totalAvailable = cache.totalAvailable
                        if cache.totalAvailable == 0 then
                            row.status = "unavailable"
                        else
                            local affordable = math.min(need, cache.totalAvailable)
                            row.affordableQuantity = affordable
                            row.estimatedCost = cache.unitPrice * affordable
                            local maxP = tonumber(entry.maxPrice) or 0
                            if maxP > 0 and cache.unitPrice > maxP then
                                row.status = "tooExpensive"
                            else
                                row.status = "buyable"
                            end
                        end
                    else
                        row.status = _pendingSearches[entry.itemID] and "searching" or "pending"
                    end
                    table.insert(out, row)
                end
            end
        end
    end
    return out
end

-- ============================================================
-- lastPaid tracking (passive)
-- ============================================================
-- COMMODITY_PURCHASE_SUCCEEDED no incluye unitPrice/totalCost directos en su
-- payload — el ultimo COMMODITY_PRICE_UPDATED tiene los datos. Cacheamos el
-- ultimo price-update por itemID para mapear cuando el SUCCEEDED entra.
local _lastPriceUpdate = {}  -- itemID -> { unitPrice, totalPrice, quantity, at }

-- ============================================================
-- Auto-buy state machine
-- ============================================================
-- Solo UN purchase en flight a la vez (la commodity API tiene state global
-- de purchase, no se puede paralelizar). Cuando _autoBuy ~= nil:
--   phase = "awaitingPrice"  → esperamos COMMODITY_PRICE_UPDATED
--   phase = "awaitingConfirm"→ popup mostrado, esperando click del user
--   phase = "awaitingSuccess"→ ConfirmCommoditiesPurchase enviado
local _autoBuy = nil

local function ClearAutoBuy(reason)
    if _autoBuy and reason then
        local nm = ns.GetItemDisplayInfo and ns.GetItemDisplayInfo(_autoBuy.itemID) or "?"
        print(string.format("|cffff5555HNZ|r Auto-buy cancelado (%s): %s", reason, nm))
    end
    _autoBuy = nil
end

-- Tiempo relativo human-readable (ej. "5m", "3h", "2d"). Pensado para el
-- popup de confirmacion: muestra cuanto paso desde la ultima compra para
-- contextualizar el cambio de precio. ASCII-only — los locales raros (zhCN,
-- koKR) renderizan letras latinas correctamente pero algunos glifos no.
local function FormatRelativeTime(epoch)
    if not epoch or epoch <= 0 or not time then return nil end
    local secs = time() - epoch
    if secs < 0 then return nil end
    if secs < 60 then return string.format("%ds", secs) end
    if secs < 3600 then return string.format("%dm", math.floor(secs / 60)) end
    if secs < 86400 then return string.format("%dh", math.floor(secs / 3600)) end
    return string.format("%dd", math.floor(secs / 86400))
end

-- Construye el texto multilinea del popup HNZ_AH_BUY_CONFIRM. Pinta:
--   1) Icono + nombre del item (highlight color)
--   2) quantity × unitPrice = totalPrice
--   3) Bag delta: cuantos hay ahora vs cuantos habra (target del entry)
--   4) Comparacion contra lastPaid: %, direccion y tiempo desde la compra
--   5) Warning si el precio subio >=50%
-- Toda la data viene de `_autoBuy` (snapshot al click) — asi el popup queda
-- coherente aunque el user borre la entry o el inventario cambie entre el
-- click y la llegada de COMMODITY_PRICE_UPDATED.
local function BuildBuyConfirmText(itemID, unitPrice, totalPrice, quantity)
    local data = _autoBuy or {}
    local lines = {}

    -- 1: icono + nombre (highlight)
    local name = data.name or (ns.GetItemDisplayInfo and ns.GetItemDisplayInfo(itemID)) or ("item:" .. tostring(itemID))
    local icon = GetItemIcon and GetItemIcon(itemID)
    local iconStr = icon and ("|T" .. icon .. ":20:20:0:0|t ") or ""
    table.insert(lines, iconStr .. "|cffffd200" .. name .. "|r")

    -- 2: cantidad × unit = total
    local unitStr = GetCoinTextureString and GetCoinTextureString(unitPrice or 0) or tostring(unitPrice or 0)
    local totalStr = GetCoinTextureString and GetCoinTextureString(totalPrice or 0) or tostring(totalPrice or 0)
    table.insert(lines, string.format("%d  x  %s  =  %s", quantity or 0, unitStr, totalStr))

    -- 3: bag delta (skip si target=0, no es informativo)
    local have = data.haveAtStart
    if not have and GetItemCount then have = GetItemCount(itemID) end
    have = have or 0
    local after = have + (quantity or 0)
    local targetN = data.target or 0
    if targetN > 0 then
        table.insert(lines, string.format("%s: %d -> %d  (%s: %d)",
            (ns.L and ns.L["In bag"]) or "In bag", have, after,
            (ns.L and ns.L["target"]) or "target", targetN))
    end

    -- 4: comparacion contra lastPaid
    local lastPaid = data.lastPaid or 0
    if lastPaid > 0 and unitPrice and unitPrice > 0 then
        local delta = unitPrice - lastPaid
        local pct = math.abs(delta) / lastPaid * 100
        local lastStr = GetCoinTextureString and GetCoinTextureString(lastPaid) or tostring(lastPaid)
        local sinceStr = FormatRelativeTime(data.lastPaidAt)
        local sinceSuffix = sinceStr and ("  (" .. sinceStr .. ")") or ""
        local indicator
        if delta > 0 then
            indicator = string.format("|cffff7777^ +%.0f%%|r", pct)
        elseif delta < 0 then
            indicator = string.format("|cff77ff77v -%.0f%%|r", pct)
        else
            indicator = "|cffaaaaaa= " .. ((ns.L and ns.L["same"]) or "same") .. "|r"
        end
        table.insert(lines, string.format("%s: %s   %s%s",
            (ns.L and ns.L["Previous"]) or "Previous", lastStr, indicator, sinceSuffix))

        -- 5: spike warning si subio >= 50%
        if delta > 0 and pct >= 50 then
            table.insert(lines, "|cffff5555! " .. ((ns.L and ns.L["Price spike — verify before buying."]) or "Price spike - verify before buying.") .. "|r")
        end
    else
        table.insert(lines, "|cff888888" .. ((ns.L and ns.L["No previous purchase recorded."]) or "No previous purchase recorded.") .. "|r")
    end

    return table.concat(lines, "\n")
end

StaticPopupDialogs["HNZ_AH_BUY_CONFIRM"] = {
    text = "",
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    -- Left-align via OnShow: el contenido tiene multiples lineas de distinto
    -- ancho (icono+nombre, total, bag delta, comparacion de precio); con el
    -- default center-aligned cada linea queda desfasada y se lee mal.
    OnShow = function(self)
        if self.text and self.text.SetJustifyH then
            self.text:SetJustifyH("LEFT")
        end
    end,
    OnAccept = function(_, data)
        if not data or not data.itemID then ClearAutoBuy(); return end
        if not C_AuctionHouse or not C_AuctionHouse.ConfirmCommoditiesPurchase then
            ClearAutoBuy("API missing"); return
        end
        _autoBuy = _autoBuy or {}
        _autoBuy.phase = "awaitingSuccess"
        pcall(C_AuctionHouse.ConfirmCommoditiesPurchase, data.itemID, data.quantity)
        -- Timeout: si no entra SUCCEEDED/FAILED en 15s, abortar state.
        C_Timer.After(15, function()
            if _autoBuy and _autoBuy.phase == "awaitingSuccess" then
                ClearAutoBuy("timeout en confirm")
            end
        end)
    end,
    OnCancel = function() ClearAutoBuy() end,
    timeout = 30,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- COMMODITY_PRICE_UPDATED signature en Retail: (unitPrice, totalPrice). NO
-- incluye itemID — el contexto del purchase activo lo damos via _autoBuy.itemID
-- (solo puede haber UN purchase en flight a la vez, asi que el contexto es
-- inequivoco mientras _autoBuy ~= nil).
local function OnCommodityPriceUpdated(unitPrice, totalPrice)
    if not _autoBuy then return end
    local itemID = _autoBuy.itemID
    if not itemID then return end

    -- Tracking pasivo para lastPaid (este es nuestro purchase, no de Blizzard UI).
    _lastPriceUpdate[itemID] = {
        unitPrice = unitPrice or 0,
        totalPrice = totalPrice or 0,
        quantity = _autoBuy.quantity or 0,
        at = time and time() or 0,
    }

    if _autoBuy.phase ~= "awaitingPrice" then return end

    -- Verificar contra maxPrice (puede haber cambiado entre query y quote).
    local maxP = _autoBuy.maxPrice or 0
    if maxP > 0 and (unitPrice or 0) > maxP then
        print(string.format("|cffff5555HNZ|r %s: %dg > %s %dg",
            (ns.L and ns.L["Price changed"]) or "Price changed",
            math.floor((unitPrice or 0)/10000),
            (ns.L and ns.L["max"]) or "max",
            math.floor(maxP/10000)))
        ClearAutoBuy()
        return
    end

    -- Gate dual (per-item + global). Cualquiera de los dos thresholds que se
    -- supere -> popup. Threshold = 0 significa "este gate desactivado". Logica:
    --   - entry.confirmAbove > 0 y totalPrice > entry.confirmAbove
    --   - global.confirmAbove > 0 y totalPrice > global.confirmAbove
    -- El global actua como red de seguridad por encima del per-item, util para
    -- frenar compras anomalas grandes (precio spike, item inesperadamente caro)
    -- aunque el user no haya configurado threshold per-item.
    local entryThreshold = _autoBuy.confirmAbove or 0
    local globalThreshold = (ns.db and ns.db.vendorRestock and tonumber(ns.db.vendorRestock.confirmAbove)) or 0
    local total = totalPrice or 0
    local needsConfirm =
        (entryThreshold > 0 and total > entryThreshold)
        or (globalThreshold > 0 and total > globalThreshold)

    if not needsConfirm then
        if not C_AuctionHouse or not C_AuctionHouse.ConfirmCommoditiesPurchase then
            ClearAutoBuy("API missing"); return
        end
        _autoBuy.phase = "awaitingSuccess"
        pcall(C_AuctionHouse.ConfirmCommoditiesPurchase, itemID, _autoBuy.quantity)
        C_Timer.After(15, function()
            if _autoBuy and _autoBuy.phase == "awaitingSuccess" then
                ClearAutoBuy("timeout en confirm")
            end
        end)
        return
    end

    _autoBuy.phase = "awaitingConfirm"
    StaticPopupDialogs["HNZ_AH_BUY_CONFIRM"].text =
        BuildBuyConfirmText(itemID, unitPrice, totalPrice, _autoBuy.quantity)
    StaticPopup_Show("HNZ_AH_BUY_CONFIRM", nil, nil, {
        itemID = itemID,
        quantity = _autoBuy.quantity,
    })
end

-- Cuando una compra commodity termina, buscamos el ultimo price update para
-- ese item. Si esta dentro de los ultimos ~30s, lo aceptamos como "lo que se
-- pago". Persistimos en la entry configurada (si existe).
local function OnCommodityPurchaseSucceeded(itemID)
    if not itemID then return end
    local s = ns.db and ns.db.vendorRestock
    if not s or not s.items then return end
    local update = _lastPriceUpdate[itemID]
    if not update or update.unitPrice <= 0 then return end
    local age = (time and time() or 0) - (update.at or 0)
    if age > 30 then return end  -- stale, ignore
    for _, e in ipairs(s.items) do
        if e.itemID == itemID then
            e.lastPaid = update.unitPrice
            e.lastPaidAt = time and time() or 0
            break
        end
    end
    -- Bag count cambio post-compra; refresh para que el counter baje.
    if ns.RefreshVendorRestockButton then ns:RefreshVendorRestockButton() end
    if ns.RefreshVendorList then ns.RefreshVendorList() end
end

-- ============================================================
-- Button UI
-- ============================================================

local ApplyButtonPosition

-- Status -> color de borde del row del tooltip. Solo informativo.
local STATUS_COLOR = {
    buyable      = { 0.4, 1.0, 0.4 },
    tooExpensive = { 1.0, 0.6, 0.3 },
    unavailable  = { 0.7, 0.7, 0.7 },
    searching    = { 0.5, 0.7, 1.0 },
    pending      = { 0.7, 0.7, 0.7 },
}

local STATUS_LABEL_KEY = {
    buyable      = "OK",
    tooExpensive = "price > max",
    unavailable  = "not on AH",
    searching    = "searching...",
    pending      = "queued",
}

local function BuildTooltipText(list)
    local lines = {}
    for _, e in ipairs(list) do
        local icon = GetItemIcon and GetItemIcon(e.itemID)
        local iconStr = icon and ("|T" .. icon .. ":14:14:0:0|t ") or ""
        local nm = e.name or ("item:" .. e.itemID)
        local statusKey = STATUS_LABEL_KEY[e.status] or e.status
        local statusStr = (ns.L and ns.L[statusKey]) or statusKey
        local right
        if e.status == "buyable" or e.status == "tooExpensive" then
            local priceStr = GetCoinTextureString and GetCoinTextureString(e.unitPrice) or tostring(e.unitPrice)
            local arrow = ""
            if e.entry.lastPaid and e.entry.lastPaid > 0 then
                if e.unitPrice < e.entry.lastPaid then arrow = " |cff66ff66v|r"
                elseif e.unitPrice > e.entry.lastPaid then arrow = " |cffff6666^|r"
                else arrow = " |cff888888=|r" end
            end
            right = priceStr .. arrow
        else
            right = statusStr
        end
        table.insert(lines, {
            left = string.format("%s%s x%d", iconStr, nm, e.need),
            right = right,
            status = e.status,
        })
    end
    return lines
end

local function BuildButton()
    if restockButton then return restockButton end
    local b = CreateFrame("Button", "HNZVendorRestockButton", UIParent, "BackdropTemplate")
    b:SetSize(160, 32)
    b:SetFrameStrata("HIGH")
    b:SetClampedToScreen(true)
    b:SetMovable(true)
    b:RegisterForDrag("LeftButton")
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    b:SetBackdropColor(0.08, 0.32, 0.16, 0.92)
    b:SetBackdropBorderColor(0.30, 0.85, 0.45, 1)

    local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", 0, 1); label:SetTextColor(1, 1, 1, 1)
    b.Label = label
    local sub = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOP", b, "BOTTOM", 0, -2); sub:SetTextColor(0.8, 0.8, 0.8, 1)
    b.Sub = sub

    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.45, 0.22, 0.95)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine((ns.L and ns.L["Auction Restock"]) or "Auction Restock")

        if self._configEmpty then
            GameTooltip:AddLine((ns.L and ns.L["No items configured yet. Click to open Config."]) or "No items configured yet. Click to open Config.",
                0.8, 0.8, 0.8, true)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine((ns.L and ns.L["Drag to move."]) or "Drag to move.",
                0.6, 0.6, 0.6, true)
            GameTooltip:Show()
            return
        end

        if self._allStocked then
            GameTooltip:AddLine((ns.L and ns.L["All items at or above target. Nothing to restock."]) or "All items at or above target. Nothing to restock.",
                0.6, 1.0, 0.6, true)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine((ns.L and ns.L["Drag to move."]) or "Drag to move.",
                0.6, 0.6, 0.6, true)
            GameTooltip:Show()
            return
        end

        local lines = BuildTooltipText(self._list or {})
        for _, ln in ipairs(lines) do
            local c = STATUS_COLOR[ln.status] or { 1, 1, 1 }
            GameTooltip:AddDoubleLine(ln.left, ln.right, 1, 1, 1, c[1], c[2], c[3])
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine((ns.L and ns.L["Click to refresh search & jump to the first item. Buy via standard AH UI."]) or "Click to refresh search & jump to the first item. Buy via standard AH UI.",
            0.6, 0.6, 0.6, true)
        GameTooltip:AddLine((ns.L and ns.L["Drag to move."]) or "Drag to move.",
            0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.32, 0.16, 0.92)
        GameTooltip:Hide()
    end)

    -- Drag directo con LeftButton (sin modificador). RegisterForDrag separa
    -- click corto (OnClick) de drag (OnDragStart) automaticamente, asi que
    -- el click del boton sigue funcionando aunque sea draggable.
    b:SetScript("OnDragStart", function(self)
        self:StartMoving(); self._isDragging = true
    end)
    b:SetScript("OnDragStop", function(self)
        if self._isDragging then
            self:StopMovingOrSizing(); self._isDragging = false
            local cx, cy = self:GetCenter()
            local pcx, pcy = UIParent:GetCenter()
            if cx and pcx and ns.db and ns.db.vendorRestock then
                ns.db.vendorRestock.offsetX = math.floor((cx - pcx) + 0.5)
                ns.db.vendorRestock.offsetY = math.floor((cy - pcy) + 0.5)
                ApplyButtonPosition(self)
            end
        end
    end)

    b:SetScript("OnClick", function(self, _)
        if self._configEmpty then
            if ns.ToggleConfigWindow then
                if not _G.HNZHealingToolsConfigWindow
                    or not _G.HNZHealingToolsConfigWindow:IsShown() then
                    ns:ToggleConfigWindow()
                end
                print("|cff00ccffHNZ|r " .. ((ns.L and ns.L["Open Config > Auction House to add items."]) or "Open Config > Auction House to add items."))
            end
            return
        end
        if not IsAuctionHouseShown() then
            print("|cffff5555HNZ|r " .. ((ns.L and ns.L["Open the auction house first."]) or "Open the auction house first."))
            return
        end
        if not C_AuctionHouse or not C_AuctionHouse.StartCommoditiesPurchase then
            print("|cffff5555HNZ|r Commodity buy API not available.")
            return
        end
        if _autoBuy then
            print("|cffffcc44HNZ|r " .. ((ns.L and ns.L["Another purchase already in progress."]) or "Another purchase already in progress."))
            return
        end
        -- Buscar el primer item "buyable" en la lista. NO re-buscamos toda la
        -- lista aca: aumenta throttle pressure y puede causar que el siguiente
        -- StartCommoditiesPurchase sea dropeado. La cache se llena en
        -- AUCTION_HOUSE_SHOW y se mantiene fresca via search-results events;
        -- si un item esta "pending" lo dejamos en pending hasta el proximo
        -- ciclo de THROTTLED_SYSTEM_READY.
        local list = self._list or {}
        local target
        for _, e in ipairs(list) do
            if e.status == "buyable" then target = e; break end
        end

        if not target then
            print("|cffffcc44HNZ|r " .. ((ns.L and ns.L["No items available to auto-buy right now."]) or "No items available to auto-buy right now."))
            return
        end

        -- Start commodity purchase. Server respondera con COMMODITY_PRICE_UPDATED
        -- — OnCommodityPriceUpdated va a mostrar el popup de confirmacion.
        _autoBuy = {
            itemID = target.itemID,
            quantity = target.need,
            -- Snapshot del entry + estado de inventario AL CLICK. El popup se
            -- construye con esto (no con db.items vivos) para que sea coherente
            -- aunque el user mute la entry o el inventario cambie entre el
            -- click y la llegada de COMMODITY_PRICE_UPDATED.
            name = target.name,
            target = tonumber(target.entry.target) or 0,
            maxPrice = tonumber(target.entry.maxPrice) or 0,
            confirmAbove = tonumber(target.entry.confirmAbove) or 0,
            lastPaid = tonumber(target.entry.lastPaid) or 0,
            lastPaidAt = tonumber(target.entry.lastPaidAt) or 0,
            haveAtStart = (GetItemCount and GetItemCount(target.itemID)) or 0,
            startedAt = time and time() or 0,
            phase = "awaitingPrice",
        }
        print(string.format("|cff00ccffHNZ|r %s: %s x%d (id=%d)",
            (ns.L and ns.L["Quoting"]) or "Quoting",
            target.name or "?", target.need, target.itemID))

        -- Refrescar search results inmediatamente antes de start. La "purchase
        -- prep" server-side usa los resultados commodity recientes para el
        -- itemID; si la cache esta stale, el server dropea la peticion sin
        -- responder con PRICE_UPDATED. Tanto Refresh como Start son protegidas
        -- (requieren hardware event), pero estamos en el OnClick chain — OK.
        if C_AuctionHouse.RefreshCommoditySearchResults then
            pcall(C_AuctionHouse.RefreshCommoditySearchResults, target.itemID)
        end

        local ok, err = pcall(C_AuctionHouse.StartCommoditiesPurchase, target.itemID, target.need)
        if not ok then
            print("|cffff5555HNZ debug|r StartCommoditiesPurchase error: " .. tostring(err))
            ClearAutoBuy("API error")
            return
        end
        if ns.db and ns.db.vendorRestock and ns.db.vendorRestock.debug then
            print("|cff888888HNZ debug|r StartCommoditiesPurchase invoked (waiting for PRICE_UPDATED...)")
        end

        -- Timeout: si no entra COMMODITY_PRICE_UPDATED dentro de 10s, abortar.
        local boughtItem = target.itemID
        C_Timer.After(10, function()
            if _autoBuy and _autoBuy.itemID == boughtItem and _autoBuy.phase == "awaitingPrice" then
                ClearAutoBuy("timeout esperando price quote")
            end
        end)
        ns:RefreshVendorRestockButton()
    end)

    b:Hide()
    restockButton = b
    return b
end

ApplyButtonPosition = function(b)
    local s = ns.db and ns.db.vendorRestock
    if not s then return end
    b:ClearAllPoints()
    b:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or -80)
    -- Scale/opacity hardcoded — la UI ya no expone sliders para tunearlos.
    b:SetScale(1.0)
    b:SetAlpha(0.95)
end

-- Visibility se simplifico a solo "enabled". La feature de subasta solo opera
-- fuera de combate (la UI del AH se cierra al entrar en combate), asi que el
-- toggle de visibilidad combat/ooc no aportaba nada.
local function ShouldShowByVisibility()
    local s = ns.db and ns.db.vendorRestock
    return s and s.enabled and true or false
end

-- ============================================================
-- Public refresh
-- ============================================================

function ns:RefreshVendorRestockButton()
    if not restockButton then return end
    if not IsAuctionHouseShown() then
        restockButton:Hide()
        return
    end
    if not ShouldShowByVisibility() then
        restockButton:Hide()
        return
    end

    local s = ns.db.vendorRestock
    local hasItems = s and s.items and #s.items > 0

    restockButton._configEmpty = false
    restockButton._allStocked = false

    if not hasItems then
        restockButton._configEmpty = true
        restockButton._list = {}
        restockButton:SetBackdropColor(0.18, 0.18, 0.22, 0.88)
        restockButton:SetBackdropBorderColor(0.45, 0.45, 0.55, 1)
        restockButton.Label:SetText((ns.L and ns.L["Configure restock"]) or "Configure restock")
        restockButton.Sub:SetText((ns.L and ns.L["click to open config"]) or "click to open config")
        ApplyButtonPosition(restockButton)
        restockButton:Show()
        return
    end

    local list = ComputeShoppingList()
    restockButton._list = list

    if #list == 0 then
        -- Todos los items al target. Boton dim/positivo en vez de hidden — el
        -- user sabe que la feature esta on y trackeando.
        restockButton._allStocked = true
        restockButton:SetBackdropColor(0.12, 0.30, 0.18, 0.85)
        restockButton:SetBackdropBorderColor(0.40, 0.70, 0.45, 1)
        restockButton.Label:SetText((ns.L and ns.L["All stocked"]) or "All stocked")
        restockButton.Sub:SetText("")
        ApplyButtonPosition(restockButton)
        restockButton:Show()
        return
    end

    local buyable, expensive, unavail, searching = 0, 0, 0, 0
    for _, e in ipairs(list) do
        if e.status == "buyable" then buyable = buyable + 1
        elseif e.status == "tooExpensive" then expensive = expensive + 1
        elseif e.status == "unavailable" then unavail = unavail + 1
        else searching = searching + 1 end
    end

    if buyable > 0 then
        restockButton:SetBackdropColor(0.08, 0.32, 0.16, 0.92)
        restockButton:SetBackdropBorderColor(0.30, 0.85, 0.45, 1)
        restockButton.Label:SetText(string.format("%s (%d)",
            (ns.L and ns.L["Restock"]) or "Restock", buyable))
        local parts = {}
        if expensive > 0 then table.insert(parts, string.format("%d %s", expensive, (ns.L and ns.L["too pricey"]) or "too pricey")) end
        if unavail > 0 then table.insert(parts, string.format("%d %s", unavail, (ns.L and ns.L["unavail"]) or "unavail")) end
        if searching > 0 then table.insert(parts, string.format("%d %s", searching, (ns.L and ns.L["pending"]) or "pending")) end
        restockButton.Sub:SetText(table.concat(parts, " · "))
    elseif expensive > 0 and (searching + unavail) == 0 then
        restockButton:SetBackdropColor(0.30, 0.22, 0.10, 0.88)
        restockButton:SetBackdropBorderColor(0.85, 0.55, 0.25, 1)
        restockButton.Label:SetText((ns.L and ns.L["Price too high"]) or "Price too high")
        restockButton.Sub:SetText(string.format("%d %s", expensive, (ns.L and ns.L["item types"]) or "item types"))
    elseif searching > 0 then
        restockButton:SetBackdropColor(0.15, 0.18, 0.30, 0.88)
        restockButton:SetBackdropBorderColor(0.40, 0.55, 0.90, 1)
        restockButton.Label:SetText((ns.L and ns.L["Searching..."]) or "Searching...")
        restockButton.Sub:SetText(string.format("%d %s", searching, (ns.L and ns.L["pending"]) or "pending"))
    else
        restockButton:SetBackdropColor(0.20, 0.20, 0.20, 0.85)
        restockButton:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)
        restockButton.Label:SetText((ns.L and ns.L["Nothing on AH"]) or "Nothing on AH")
        restockButton.Sub:SetText(string.format("%d %s", unavail, (ns.L and ns.L["item types"]) or "item types"))
    end
    ApplyButtonPosition(restockButton)
    restockButton:Show()
end

function ns:RefreshVendorRestockPosition()
    if restockButton then ApplyButtonPosition(restockButton) end
end

function ns:TestVendorRestockButton()
    local b = restockButton or BuildButton()
    b._configEmpty = false
    b._allStocked = false
    b._list = {
        { itemID = 0, need = 5, name = "Test", status = "searching", entry = {} },
    }
    b.Label:SetText("Restock (test)")
    b.Sub:SetText("preview")
    ApplyButtonPosition(b)
    b:Show()
end

function ns:HideVendorRestockTest()
    if restockButton and not IsAuctionHouseShown() then
        restockButton:Hide()
    end
end

-- ============================================================
-- Items list helpers (usado desde Config.lua)
-- ============================================================

function ns.FindVendorItemEntry(itemID)
    local s = ns.db and ns.db.vendorRestock
    if not s or not s.items or not itemID then return nil end
    for i, e in ipairs(s.items) do
        if e.itemID == itemID then return i, e end
    end
    return nil
end

function ns:AddVendorRestockItem(input)
    local id = ns.GetItemIDFromInput and ns.GetItemIDFromInput(input)
    if not id then return false, (ns.L and ns.L["Item not found: "] or "Item not found: ") .. tostring(input) end
    if ns.FindVendorItemEntry(id) then
        local n = ns.GetItemDisplayInfo and ns.GetItemDisplayInfo(id) or ("item:" .. id)
        return false, n .. ((ns.L and ns.L[" already in restock list."]) or " already in restock list.")
    end
    ns.db.vendorRestock.items = ns.db.vendorRestock.items or {}
    local e = {
        itemID = id,
        target = 1,
        maxPrice = 0,
        confirmAbove = 1000000,  -- 100g default; user lo ajusta por entry
        enabled = true,
    }
    table.insert(ns.db.vendorRestock.items, e)
    local n = ns.GetItemDisplayInfo and ns.GetItemDisplayInfo(id) or ("item:" .. id)
    return true, e, n
end

function ns:RemoveVendorRestockItem(itemID)
    local s = ns.db and ns.db.vendorRestock
    if not s or not s.items then return false end
    for i, e in ipairs(s.items) do
        if e.itemID == itemID then
            table.remove(s.items, i)
            return true
        end
    end
    return false
end

-- ============================================================
-- Init
-- ============================================================

function ns:InitVendorRestock()
    BuildButton()

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("AUCTION_HOUSE_SHOW")
    ev:RegisterEvent("AUCTION_HOUSE_CLOSED")
    -- COMMODITY_SEARCH_RESULTS_UPDATED fires con itemID cuando los resultados
    -- de un commodity search llegan. Refrescamos cache y button.
    ev:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
    -- Tracking pasivo de compras commodity para registrar lastPaid:
    ev:RegisterEvent("COMMODITY_PRICE_UPDATED")
    ev:RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
    -- Failure paths del flow auto-buy:
    ev:RegisterEvent("COMMODITY_PURCHASE_FAILED")
    ev:RegisterEvent("COMMODITY_PRICE_UNAVAILABLE")
    -- AH throttle system: el server limita N msgs/segundo; si excedemos, los
    -- mensajes se dropean. Registramos los events para reintentar cuando el
    -- sistema vuelve a quedar listo.
    ev:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
    ev:RegisterEvent("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
    ev:RegisterEvent("AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED")
    ev:RegisterEvent("AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED")
    ev:RegisterEvent("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT")
    ev:RegisterEvent("BAG_UPDATE_DELAYED")
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    ev:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
        if event == "AUCTION_HOUSE_SHOW" then
            -- NO limpiamos cache: si tenemos resultados previos validos (de
            -- la sesion anterior al close), los reusamos hasta que entren los
            -- frescos. Limpiar aca causaba que el boton quedara "Searching..."
            -- si nuestras queries se dropeaban por throttle al competir con las
            -- queries iniciales de Blizzard al abrir el AH.
            _pendingSearches = {}
            -- Delay mas largo (2s) para dejar que Blizzard termine sus queries
            -- iniciales antes de que nosotros pidamos las nuestras — reduce
            -- mucho el throttle contention. Igual chequeamos IsThrottledMessageSystemReady
            -- antes de enviar cada una.
            C_Timer.After(2.0, function()
                if IsAuctionHouseShown() then
                    RequestSearchForAllConfigured()
                    ns:RefreshVendorRestockButton()
                end
            end)
            ns:RefreshVendorRestockButton()
        elseif event == "AUCTION_HOUSE_CLOSED" then
            if restockButton then restockButton:Hide() end
        elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
            local itemID = arg1
            if ns.db and ns.db.vendorRestock and ns.db.vendorRestock.debug then
                print(string.format("|cff888888HNZ debug|r COMMODITY_SEARCH_RESULTS_UPDATED itemID=%s",
                    tostring(itemID)))
            end
            if itemID then
                ReadSearchResults(itemID)
                ns:RefreshVendorRestockButton()
            end
        elseif event == "COMMODITY_PRICE_UPDATED" then
            -- Retail signature: (unitPrice, totalPrice). No itemID en payload.
            if ns.db and ns.db.vendorRestock and ns.db.vendorRestock.debug then
                print(string.format("|cff888888HNZ debug|r COMMODITY_PRICE_UPDATED unitPrice=%s totalPrice=%s",
                    tostring(arg1), tostring(arg2)))
            end
            OnCommodityPriceUpdated(arg1, arg2)
        elseif event == "COMMODITY_PURCHASE_SUCCEEDED" then
            -- No itemID en payload — usamos el context del purchase activo.
            local itemID = _autoBuy and _autoBuy.itemID or nil
            if itemID then
                OnCommodityPurchaseSucceeded(itemID)
                print(string.format("|cff66ff66HNZ|r %s: %s",
                    (ns.L and ns.L["Purchase complete"]) or "Purchase complete",
                    (ns.GetItemDisplayInfo and ns.GetItemDisplayInfo(itemID)) or ("item:"..tostring(itemID))))
            end
            ClearAutoBuy()
        elseif event == "COMMODITY_PURCHASE_FAILED" then
            print("|cffff5555HNZ debug|r COMMODITY_PURCHASE_FAILED")
            ClearAutoBuy("server purchase failed")
        elseif event == "COMMODITY_PRICE_UNAVAILABLE" then
            print("|cffff5555HNZ debug|r COMMODITY_PRICE_UNAVAILABLE")
            ClearAutoBuy("server price unavailable")
        elseif event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
            -- NO cancelamos autoBuy aqui: el evento es global del sistema de
            -- throttle del AH y NO indica que mensaje fue dropeado. Si el
            -- dropped fue una busqueda, cancelar nuestro purchase es un
            -- false-positive (el purchase puede seguir en vuelo y completar).
            -- Confiamos en COMMODITY_PURCHASE_FAILED / COMMODITY_PRICE_UNAVAILABLE
            -- y en el timeout de 10s de awaitingPrice para detectar fallas reales.
            if ns.db and ns.db.vendorRestock and ns.db.vendorRestock.debug then
                print("|cffff5555HNZ debug|r AH msg DROPPED (throttled)")
            end
        elseif event == "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED" then
            if ns.db and ns.db.vendorRestock and ns.db.vendorRestock.debug then
                print("|cffffcc44HNZ debug|r AH msg QUEUED (throttled, will retry)")
            end
        elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
            -- StartCommoditiesPurchase es protegida — NO la llamamos aca.
            -- Pero SendSearchQuery NO es protegida, asi que aprovechamos para
            -- re-disparar searches de items que todavia no tienen cache.
            if IsAuctionHouseShown() then
                local s = ns.db and ns.db.vendorRestock
                if s and s.items then
                    for _, e in ipairs(s.items) do
                        if e and e.itemID and e.enabled ~= false
                           and not _searchCache[e.itemID] then
                            RequestSearchForItem(e.itemID)
                        end
                    end
                end
            end
        elseif event == "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT" then
            -- Estos eventos disparan para TODO mensaje AH del sistema,
            -- incluyendo los de Blizzard al cargar la UI del AH. Sin gate
            -- son puro ruido en el chat.
            if ns.db and ns.db.vendorRestock and ns.db.vendorRestock.debug then
                print("|cff888888HNZ debug|r AH msg SENT")
            end
        elseif event == "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED" then
            if ns.db and ns.db.vendorRestock and ns.db.vendorRestock.debug then
                print("|cff888888HNZ debug|r AH msg RESPONSE")
            end
        elseif event == "BAG_UPDATE_DELAYED" then
            ns:RefreshVendorRestockButton()
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            ns:RefreshVendorRestockButton()
        end
    end)
end
