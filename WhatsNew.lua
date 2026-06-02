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

-- Items de cada release se buildean en GetReleaseNotes() (deferred): wrappear
-- ns.L[...] al top-level no funciona porque este archivo carga antes que los
-- locale files registren sus tablas. La lookup en GetReleaseNotes() pasa por
-- la metatable de ns.L y cae al key (ingles) si no hay traduccion.
local function GetReleaseNotes()
    return {
        {
            version = "1.10.1",
            date = "2026-06-01",
            items = {
                ns.L["Hotfix: the pre-recorded voice files for MRT/NSRT spell announcements are now bundled with the addon (they were missing from the package), so the audio reminders work without relying on the in-game TTS engine."],
            },
        },
        {
            version = "1.10.0",
            date = "2026-06-01",
            items = {
                ns.L["Miscellaneous: new sidebar section for small features. First one is a Combat Resurrection tracker that shows the group's shared battle-res charges in raids and Mythic+ — it works on any class (it does not depend on you having a brez). When charges are available it shows the count; when empty the icon dims and counts down to the next charge. Shamans also get a companion Reincarnation indicator (bright when ready, or a countdown to the next self-res)."],
                ns.L["Miscellaneous: the combat-res icons are always visible in raid and Mythic+ (in or out of combat). Drag them anywhere with the 'Move icon' button (it auto-unlocks the first time you enable the feature), tune icon/text size, and right-click an icon out of combat to open its settings."],
                ns.L["Raid Spells (A): the panel now only shows spells with a base cooldown over 30 seconds, so short-cooldown casts no longer clutter the healer cooldown list."],
                ns.L["Ready Check Panel: class-buff rows are now group-aware for the provider. If you are the one who casts a raid buff (e.g. Skyfury), the row stays red until every connected, alive group member actually has it — so you know to recast without checking each unit frame."],
                ns.L["Cursor: stack and charge counts now display from 1 (previously only at 2 or more), so you can always see how many stacks or charges are available."],
                ns.L["Fix: the character ring no longer resets and loops back to the start when you enter combat for buffs whose duration the game hides in combat (e.g. Astral Shift)."],
                ns.L["Fix: buying at the auction house no longer throws an 'invalid option in format' error when the confirmation popup includes a price-change indicator."],
            },
        },
        {
            version = "1.9.0",
            date = "2026-05-26",
            items = {
                ns.L["Raid Spells (A): the panel now lists every healer in your raid who has the addon enabled, not just those who cast something in the last 5 seconds. Discovery is automatic via a hello protocol broadcast on group join and every 60s; stale entries are pruned after 3 minutes of silence."],
                ns.L["Raid Spells (A): each cast icon now shows a compact age label (5s / 2m / 1h) under it. Replaces the age-based alpha fade — the elapsed time is communicated explicitly."],
                ns.L["Raid Spells (A): panel only shows inside a raid instance by default (it was incorrectly visible in the open world when in a raid group during world events / world bosses)."],
                ns.L["Raid Spells (A): drag works correctly — fixed a regression where the 0.5s refresh ticker re-anchored the panel mid-drag and snapped it back to the saved position."],
                ns.L["Ready Check Panel: talent build row now shows an explicit warning when no loadout is assigned for the current content type (yellow text + red X) instead of a silent neutral state. Configure assignments in Config → Ready Check → Talents."],
                ns.L["Ready Check Panel: Dungeon and Mythic+ talent loadout categories merged into a single 'Dungeon / M+' checkbox. The ready check fires in the lobby before the keystone is inserted, so the distinction wasn't useful. Existing 'mplus=true' assignments still work as a synonym for 'dungeon'."],
                ns.L["Ready Check Panel: default panel width bumped 320 → 420px so the longer status texts (e.g. 'No loadout assigned for Dungeon / M+') no longer get clipped. Slider max raised to 700. Migration v6 auto-bumps profiles still on the old default."],
                ns.L["Ready Check Panel: removed the 'Use' button from the healthstone cell — healthstones are combat-only and the ready check fires out of combat, so the click did nothing. Icon + count remain to indicate you have stones."],
                ns.L["Ready Check Panel: cauldron-cast Phial aura 1235108 added to the known flask aura list (was reported as missing)."],
                ns.L["Aura tracking: fixed the 'ring stays active after the buff expired' bug for spells with known durations (e.g. Barkskin). When the Cooldown Manager cache has a stale entry whose appliedAt + duration is in the past, we now evict it and report MISSING instead of leaving the ring lit indefinitely. Also clears the CDM cache on zone changes (PLAYER_ENTERING_WORLD full updates)."],
                ns.L["Simulated Auras (A): new sidebar entry, currently 'Coming Soon'. The underlying state machine works via /hnzsim <spellID> and tracks an apply-then-consume aura pattern (for spells whose aura is hidden from the WoW API). UI integration with Cursor/Ring display is still in testing."],
            },
        },
        {
            version = "1.8.0",
            date = "2026-05-21",
            items = {
                ns.L["Auction Restock: floating button at the auction house that searches commodities for items in your curated list and starts a guided purchase via the standard AH flow. Per-item target quantity, max unit price, and a confirm-above threshold. lastPaid history persists per item, with up/down indicators in the tooltip and confirmation popup."],
                ns.L["Detailed buy confirmation popup: icon + name, quantity × unit = total, bag delta (have → after, vs target), price change vs lastPaid (^ +X% or v -X%), time since last purchase, and a 'price spike' warning if the unit price jumped 50% or more."],
                ns.L["Global confirm threshold: extra safety-net popup if the total cost exceeds a global gold amount, even when the per-item threshold doesn't trigger. Configurable in Config → Auction House."],
                ns.L["Stuck-ring fix: the character ring auras now re-validate at known checkpoints (combat start, combat end, ready check). Speculative CLEU-based state is wiped and the authoritative AuraUtil scan re-populates the cache — fixes the random 'ring stays visible after the buff expired' bug."],
                ns.L["Ready Check Panel can now be moved by clicking and dragging the panel (no Shift needed). Position persists across sessions."],
                ns.L["Talent loadout row renamed 'Loadout' → 'Talent Build' for clarity."],
                ns.L["Drag the Auction Restock floating button directly to reposition it (Shift no longer required). Position is auto-saved."],
                ns.L["Fix: AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED no longer cancels in-flight commodity purchases. The event is system-wide and doesn't identify which message was dropped, so reacting to it was a false-positive that aborted purchases the server actually completed."],
                ns.L["Fix: reduced AH search query spam on Restock click — only the target item is refreshed, not the whole list, cutting throttle contention."],
                ns.L["AH/COMMODITY debug prints (SENT/RESPONSE/QUEUED/DROPPED, search/price updates) are gated behind a debug flag, default off. Toggle on with /run HNZHealingToolsDB.profile.vendorRestock.debug = true if you need to diagnose."],
            },
        },
        {
            version = "1.7.0",
            date = "2026-05-18",
            items = {
                ns.L["Ready Check Panel: floating checklist that appears on /readycheck and auto-hides when you respond (or on combat start, or via the new X close button). Tracks Well Fed, Flask, Augment Rune, Weapon Imbue, party-aware Class Buffs (Skyfury / Power Word: Fortitude / Mark of the Wild / Arcane Intellect / Battle Shout / Blessing of the Bronze), Healthstone (only when a Warlock is in the group), a mana reminder, and your active Talent Loadout. Bag oils / runes / foods / flasks / mana drinks / healthstones appear as clickable sub-rows."],
                ns.L["Talent Loadout per content type: in Config → Ready Check → Talents, assign each saved loadout to one or more categories (Raid, Mythic+, Dungeon, PvP, Delve). The panel warns when the active loadout doesn't match the current content and offers a Switch button that applies the saved loadout for you (out of combat only)."],
                ns.L["Universal weapon imbue detection: works for every class, both hands. Class self-casters (Shaman / Rogue) get a Cast button; other classes get the bag oils as click-to-use sub-rows. Eating channel is auto-detected via the food/drink aura — no need to click the addon's sub-row first."],
                ns.L["Habilitar Funciones (General page): master enable per feature (Cursor, Ring, Pulse, Cursor Ring, MRT / NSRT, Ready Check). Disabling a feature grays its sidebar entry and locks its config page behind a translucent overlay. Per-page Enable X checkboxes were removed in favor of this central control."],
                ns.L["Sidebar reorganized: General moved to the top. Hover the icon of any green (OK) check row in the panel to see the native spell or item tooltip."],
                ns.L["/hnz oildiag slash command: dumps weapon enchant state + player auras for diagnosing weapon imbue detection per patch."],
                ns.L["Fix: weapon imbue on classes without a self-cast spell (Monk, Druid, etc.) was rendered as red X even with the oil applied — the row now correctly shows green check."],
                ns.L["Fix: Blessing of the Bronze and other class buffs whose aura spellID differs from the cast spellID are now detected via name fallback."],
                ns.L["Fix: Talent loadout Switch now actually applies the talents (LoadConfig + CommitConfig). Previously it only selected them in the editor."],
                ns.L["Fix: item counts in sub-rows are now bag-only (warband / account bank excluded)."],
                ns.L["Fix: Cursor Ring master toggle now hides the dot and cast wedges too — previously it only hid the decorative ring."],
            },
        },
        {
            version = "1.6.0",
            date = "2026-05-16",
            items = {
                ns.L["Macro trigger system: every aura, pulse, and item editor has a new 'Trigger key' field. Fire any configured display from a macro with /hht trigger <key> or from another addon via HNZHealingTools.Trigger(key). Multiple entries can share a key — one keybind fires them all at once."],
                ns.L["New Macros help page in the config sidebar with copy-pasteable macro examples and Lua snippets."],
                ns.L["Floating preview popup: 'Show preview' button at the top of pages with a Live Preview block (Cursor / Ring / Pulse settings + Cursor Ring sub-tabs). Opens to the right of the config window, single-active across pages, inherits position when switching."],
                ns.L["Stack count now displays correctly for fully-restricted auras tracked by Blizzard's Cooldown Manager (e.g. Mana Tea). The addon now reads the stack count via the same SetText/GetText technique Blizzard's own CDM viewer uses, so SecureNumber values are no longer lost in combat."],
                ns.L["Restricted auras visible in the Cooldown Manager but invisible to addon APIs now synthesize ACTIVE state from the CDM hook (stacks + appliedAt) — icon + count + optional timer render correctly even when all 6 detection paths fail."],
                ns.L["/hht auradebug now reports inCombat status, CDM-captured stack count, and the full list of FontStrings on the matching CDM frame — useful for diagnosing in-combat detection failures."],
                ns.L["Public API namespace _G.HNZHealingTools exposed for macros and other addons (.version, .Trigger(key))."],
            },
        },
        {
            version = "1.5.0",
            date = "2026-05-15",
            items = {
                ns.L["Track items as cooldowns: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New 'Add Item...' button + drag-and-drop dispatches by type (spell vs item) and opens the right editor."],
                ns.L["Item editors with full tabs (mirror of the Spell editor): General + Display + Effects for cursor items; General + Sound for pulse items. Visual overrides, hide flags, pulse on ready, sound — all available."],
                ns.L["Per-entry instance-type filter on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP (Arena/BG), Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances."],
                ns.L["Aura detection paths 6 + 7: slot iteration (catches semi-restricted auras Midnight hides from name/ID lookups) + manual trigger workaround (for fully-restricted auras like consumable buffs — configure a trigger spell or item ID and the addon synthesizes the ACTIVE state on cast/use)."],
                ns.L["New /hht listauras command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID of a buff when the guessed one isn't detected."],
                ns.L["Config window no longer closes when opening the Spellbook (PlayerSpellsFrame). ESC still closes it via a custom handler that doesn't break other keybinds."],
                ns.L["Fix: comparing SecureNumber spellId in slot iteration tainted the addon ('attempt to compare a secret number value'). Wrapped in ToPublic + pcall — fully restricted auras are skipped safely instead of crashing the whole frame."],
                ns.L["Fix: ApplyRingVisibility nil call when a ring test entry expired (forward declaration bug, latent since 1.3.0)."],
            },
        },
        {
            version = "1.4.0",
            date = "2026-05-14",
            items = {
                ns.L["Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically."],
                ns.L["Per-entry visibility for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility)."],
                ns.L["Per-entry visual overrides for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely)."],
                ns.L["Tabbed editor modals: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound."],
                ns.L["Changelog button (?) in the config window title bar — opens this popup with all release notes on demand."],
                ns.L["Fix: 'Spell not found' when adding via the autocomplete dropdown for spells/auras the character does not know. The autocomplete-resolved spell ID is now preferred over name lookup."],
                ns.L["Fix: creating or switching profiles left some menus showing the old profile's values. Config pages are now rebuilt against the active profile on every switch."],
            },
        },
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
end

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
    BuildContent(whatsNewFrame.content, GetReleaseNotes())
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

    local releaseNotes = GetReleaseNotes()
    -- Que notas mostrar:
    --   - Primera instalacion (lastSeen == nil): solo la latest entry.
    --   - Upgrade: todas las versiones entre lastSeen (exclusive) y current (inclusive).
    local toShow = {}
    if not lastSeen then
        if releaseNotes[1] and CompareVersions(releaseNotes[1].version, currentVersion) <= 0 then
            table.insert(toShow, releaseNotes[1])
        end
    else
        for _, n in ipairs(releaseNotes) do
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
