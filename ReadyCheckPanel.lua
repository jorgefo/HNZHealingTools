local _, ns = ...

-- ReadyCheckPanel: cuando alguien dispara /readycheck en el raid, mostramos un
-- panel flotante con un checklist visual del estado de preparacion del player
-- (Well Fed, Flask/Phial, Augment Rune, HP lleno, mana lleno). Cada check con
-- `kind` se acompania de sub-rows listando los items disponibles en bag para
-- ese kind (con icono, nombre, cantidad, tooltip, click-to-use). Auto-hide en
-- READY_CHECK_FINISHED.
--
-- i18n-safe: NO usamos string matching sobre nombres de items/spells/buffs
-- (WoW localiza eso). Para detection de buff aplicado seguimos usando match por
-- nombre porque C_UnitAuras devuelve nombres locales, pero la lista de items
-- para click-to-use es 100% por itemID hardcoded.

local CreateFrame = CreateFrame
local UIParent = UIParent
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitAffectingCombat = UnitAffectingCombat
local InCombatLockdown = InCombatLockdown
local GameTooltip = GameTooltip
local C_Timer = C_Timer
local C_Item = C_Item
local C_Container = C_Container
local _GetItemCount = GetItemCount or (C_Item and C_Item.GetItemCount)
-- Wrap explicito: 4 falses para includeBank/includeUses/includeReagentBank/
-- includeAccountBank. En Midnight 12.x el default del 5to arg puede incluir
-- warband bank — el user quiere conteo EXCLUSIVAMENTE de la bolsa. Args extra
-- ignorados silenciosamente en clientes viejos, asi que es safe pasarlos.
local function GetItemCount(id)
    if not (_GetItemCount and id) then return 0 end
    return _GetItemCount(id, false, false, false, false) or 0
end
local GetItemIcon = GetItemIcon or (C_Item and C_Item.GetItemIconByID)
local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
local GetItemSpell = GetItemSpell or (C_Item and C_Item.GetItemSpell)
local mathfloor = math.floor
local mathmax = math.max

local panelFrame
local inCombat = false

-- ============================================================
-- Click-to-use consumibles (i18n-safe)
-- ============================================================
-- Tres estrategias coexisten para que el panel funcione en TODOS los idiomas
-- y se autoactualice con cada nueva expansion:
--
-- 1) HARDCODED itemIDs en DEFAULT_USE_ITEMS por kind. Cubre items que el player
--    podria querer aunque NO esten en bag (p.ej. runas viejas que dejo de tener),
--    y sirven como base de spellIDs para buff detection.
--
-- 2) BAG SCAN por itemSubClassID (numerico, estable inter-idiomas):
--    - subclass 3 = Flask
--    - subclass 5 = Food & Drink
--    Esto detecta CUALQUIER item del kind en bag sin importar el idioma del
--    cliente ni si conocemos su itemID. Augment runes no tienen subclass
--    propia (caen en "Other Consumable") asi que para ese kind solo aplica
--    la lista hardcoded.
--
-- 3) BUFF DETECTION por spellID: extraemos GetItemSpell(itemID) para cada item
--    conocido (hardcoded + bag-scanned) y armamos un set de spellIDs por kind.
--    Cuando iteramos auras matcheamos por spellId (numero, i18n-safe). Esto
--    reemplaza el viejo match por aura.name == "Well Fed" que solo funcionaba
--    en cliente ingles.
local DEFAULT_USE_ITEMS = {
    -- Augment Runes: lista completa cubriendo Legion hasta Midnight current.
    -- Las viejas siguen aplicando el buff (dan menos stat) — el panel las muestra
    -- y son clickeables. Newest first asi click-to-use por default agarra la
    -- mas reciente.
    augmentRune = {
        259085, -- Void-Touched Augment Rune (Midnight 12.x)
        243191, -- Ethereal Augment Rune (Tazavesh, permanent)
        224572, -- Crystallized Augment Rune (TWW S2+)
        210796, -- Algari Crystallized Augment Rune (TWW S1)
        211495, -- Dreambound Augment Rune (Dragonflight S3)
        201325, -- Draconic Augment Rune (Dragonflight S1-S2)
        181468, -- Veiled Augment Rune (Shadowlands)
        160053, -- Battle-Scarred Augment Rune (Battle for Azeroth)
        140587, -- Defiled Augment Rune (Legion)
    },
    -- Flasks current Midnight + TWW. La lista es semilla — el bag scan
    -- captura los que falten via subclass 3.
    flask = {
        -- Midnight (Silvermoon/Dornogal alchemy)
        241326, -- Flask of the Shattered Sun (Crit)
        241324, -- Flask of the Blood Knights (Haste)
        241322, -- Flask of the Magisters (Mastery)
        241321, -- Flask of Thalassian Resistance (Versatility)
        -- TWW Khaz Algar
        212271, 212270, 212269, -- Flask of Tempered Aggression (Crit) R3/R2/R1
        212274, 212273, 212272, -- Flask of Tempered Swiftness (Haste)
        212277, 212276, 212275, -- Flask of Tempered Versatility
        212280, 212279, 212278, -- Flask of Tempered Mastery
    },
    -- Foods seed list — bag scan via subclass 5 captura cualquier food
    -- adicional que el player tenga. Items conjured (mage refreshment) se
    -- excluyen del scan via CONJURED_FOOD_IDS porque no aplican Well Fed —
    -- viven en recoveryMana kind.
    wellFed = {
        -- Midnight feasts
        255845, -- Silvermoon Parade
        255846, -- Harandar Celebration
        242272, -- Quel'dorei Medley
        242273, -- Blooming Feast
        266996, -- Midnight community/shared feast (reportado por user 2026-05-17)
        -- Midnight single-stat foods
        255847, -- Impossibly Royal Roast
        242275, -- Royal Roast
        242747, -- Hearty Royal Roast
        268679, -- Hearty Impossibly Royal Roast
        242284, -- Void-Kissed Fish Rolls
        242285, -- Warped Wise Wings
        -- TWW Khaz Algar feasts
        222728, 222729, 222730, 222731, 222732, 222733,
        -- TWW Khaz Algar single-stat foods
        222693, 222702, 222720, 222724, 222750,
        -- Dragonflight feasts (legacy compat)
        197788, 197789, 202351,
    },
    -- Recovery HP: items que restauran vida. Healthstones requieren warlock en
    -- grupo (filtrado en GetAvailableItems via HEALTHSTONE_IDS).
    recoveryHP = {
        -- Warlock Healthstones (filtered cuando no hay warlock en grupo)
        224464, -- Demonic Healthstone (TWW+) — 3 charges
        5512,   -- Healthstone (legacy)
        -- Healing Potions
        244839, -- Invigorating Healing Potion (TWW S3+)
        211880, -- Algari Healing Potion (TWW S1-S2)
        212942, -- Fleeting Algari Healing Potion (cheap)
    },
    -- Healthstone-only: row dedicada que aparece solo cuando hay warlock en
    -- grupo. Distinto de recoveryHP (que combina healthstones + pociones) —
    -- el user quiere saber especificamente si tiene la piedra del brujo + cuantas.
    healthstone = {
        224464, -- Demonic Healthstone (TWW+) — 3 charges
        5512,   -- Healthstone (legacy)
    },
    -- Recovery Mana: items que restauran mana / channel drink. Midnight 12.0.5
    -- nerfeo los vendor foods top-tier para NO dar mana — las teas crafteadas
    -- son la principal fuente actual.
    recoveryMana = {
        -- Midnight teas (Cooking profession; restauran ~8% mana/sec por 20s
        -- + bonus de Finesse + Speed). Las 3 son intercambiables.
        242298, -- Argentleaf Tea
        242299, -- Sanguithorn Tea
        249689, -- Ghostflower Tea with Sunfruit (vendor tea, Silvermoon)
        -- Mage Conjure Refreshment items (party food, restauran HP + mana
        -- channeling 20s). Sirven aunque no seas mage si tenes una mage en
        -- el party que invoca el Refreshment Table.
        113509, -- Conjured Mana Bun (current mage spawn)
        65499,  -- Conjured Mana Cake (legacy mage spawn)
    },
    -- Weapon enchants temporales (oils + runes). Aplica a TODAS las clases —
    -- el row "Weapon Imbue" ahora aparece siempre. Lista seed TWW; el user
    -- puede extender via Config actionItems.weaponImbue para los items que
    -- realmente carga (los IDs pueden cambiar por temporada).
    weaponImbue = {
        212111, -- Buzzing Rune (TWW Inscription)
        212279, -- Howling Rune (TWW Inscription)
        212301, -- Algari Deftness Oil (TWW Alchemy)
        212308, -- Algari Mana Oil
        212315, -- Algari Stat Oil
        -- Midnight weapon oils set (reportados por user 2026-05-17). IDs
        -- consecutivos sugieren que son las 4 variantes de stat oil de la
        -- expansion (mana/crit/haste/etc).
        243733,
        243734,
        243735,
        243736,
    },
}

-- Buff aura spellIDs conocidos por kind. Se agregan al mismo set que usa
-- CheckBuffByKind para matchear `aura.spellId`. Estos son los IDs del AURA
-- aplicada al player (no el cast spell del item) — necesarios cuando
-- GetItemSpell(food) devuelve el spell del cast (poner mesa/canalizar) y NO
-- el spellID del aura resultante "Well Fed" / "Flask of X" / etc.
local KNOWN_BUFF_SPELLIDS = {
    wellFed = {
        1232585, -- Well Fed aura desde food no listada (reportado 2026-05-17)
        1285644, -- Well Fed aura desde food no listada (reportado 2026-05-17)
    },
    flask = {},
    augmentRune = {},
    weaponImbue = {},
}

-- Set de itemIDs healthstone — para filtrar de recoveryHP cuando no hay
-- warlock en el grupo (el item solo se obtiene de warlock cast).
local HEALTHSTONE_IDS = {
    [224464] = true, -- Demonic Healthstone
    [5512]   = true, -- Healthstone (legacy)
}

-- Set de itemIDs conjured food/mana — se excluyen del bag scan de "wellFed"
-- (subclass 5) porque NO aplican Well Fed; van en recoveryMana en su lugar.
local CONJURED_FOOD_IDS = {
    [113509] = true,
    [65499]  = true,
}

-- ============================================================
-- Bag scan por itemSubClassID (i18n-safe)
-- ============================================================
-- GetItemInfoInstant retorna classID/subClassID numericos que son STABLES
-- inter-idiomas. Iteramos bags una vez, indexamos items detectados por kind
-- via subclass mapping. BAG_UPDATE_DELAYED invalida la cache.
--
-- Filtramos por requiredLevel >= 60 para excluir items vanilla (water vendor,
-- old food). El requiredLevel viene de GetItemInfo (15-tuple). Si el item no
-- esta cacheado todavia, lo pasamos por default (sin filtrar) — el proximo
-- refresh lo va a filtrar correctamente.

-- Bag scan deshabilitado por ambos kinds:
--
-- - subclass 5 (Food & Drink) agrupa Well Fed foods con items que solo
--   regeneran vida/mana sin Well Fed (agua, healing tonics, refreshment).
--   No hay forma i18n-safe de distinguir.
--
-- - subclass 3 (Flask) agrupa flasks de combate con PHIALS de profesion
--   (resourcefulness, finesse, etc) que NO sirven para encuentros. Sin
--   forma i18n-safe de filtrar.
--
-- Por eso flask Y wellFed dependen exclusivamente de DEFAULT_USE_ITEMS
-- (hardcoded, actualizable per-patch) + actionItems custom del usuario.
-- Recovery items (recoveryHP/recoveryMana) tambien son hardcoded only.
local KIND_FROM_SUBCLASS = {
    -- (vacio — todos los kinds usan whitelist explicita)
}
local MIN_LEVEL_FOR_BAG_SCAN = 60

local _bagScanCache = nil
local _bagScanDirty = true
local _knownSpellIDsCache = nil
local _knownSpellIDsDirty = true

local function MarkBagScanDirty()
    _bagScanDirty = true
    _knownSpellIDsDirty = true
end

local function RebuildBagScan()
    _bagScanCache = { flask = {} }
    _bagScanDirty = false
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID) then return end
    if not GetItemInfoInstant then return end

    local seen = { flask = {} }
    for bag = 0, 4 do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
                if classID == 0 then -- Consumable
                    local kind = KIND_FROM_SUBCLASS[subClassID]
                    if kind and not seen[kind][itemID] then
                        local _, _, _, _, reqLevel = GetItemInfo and GetItemInfo(itemID)
                        if not reqLevel or reqLevel >= MIN_LEVEL_FOR_BAG_SCAN then
                            table.insert(_bagScanCache[kind], itemID)
                            seen[kind][itemID] = true
                        end
                    end
                end
            end
        end
    end
end

-- HasClassInGroup: true si yo o algun miembro del party/raid es de la clase X.
-- Usado para gate Healthstone (solo si warlock presente) y para class buff
-- detection (solo trackear buffs de clases presentes).
local function HasClassInGroup(class)
    if not class then return false end
    local _, myClass = UnitClass("player")
    if myClass == class then return true end
    local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
    if n == 0 then return false end
    local prefix = (IsInRaid and IsInRaid()) and "raid" or "party"
    for i = 1, n do
        local _, c = UnitClass(prefix .. i)
        if c == class then return true end
    end
    return false
end

-- ============================================================
-- Known buff spellIDs por kind (para i18n-safe buff detection)
-- ============================================================
-- Set { spellID -> true } por kind. Construido desde GetItemSpell() de cada
-- itemID conocido (hardcoded + bag scan). Para foods/flasks el use-spell del
-- item suele coincidir con el spellID del buff aplicado — cuando coinciden,
-- detectamos el buff i18n-safe. Si no coinciden (algunos foods en realidad
-- aplican un buff con spellID diferente), el row queda rojo pero el sub-row
-- de bag items sigue funcionando.

local function RebuildKnownSpellIDs()
    _knownSpellIDsCache = { flask = {}, wellFed = {}, augmentRune = {}, weaponImbue = {} }
    _knownSpellIDsDirty = false
    if not GetItemSpell then return end

    local function addFromList(kind, list)
        if not list then return end
        for _, itemID in ipairs(list) do
            local _, spellID = GetItemSpell(itemID)
            if spellID then _knownSpellIDsCache[kind][spellID] = true end
        end
    end

    addFromList("flask",       DEFAULT_USE_ITEMS.flask)
    addFromList("wellFed",     DEFAULT_USE_ITEMS.wellFed)
    addFromList("augmentRune", DEFAULT_USE_ITEMS.augmentRune)
    addFromList("weaponImbue", DEFAULT_USE_ITEMS.weaponImbue)
    if _bagScanCache then
        addFromList("flask",   _bagScanCache.flask)
        addFromList("wellFed", _bagScanCache.wellFed)
    end
    -- User custom items (configurados via actionItems en Config) — los oils
    -- nuevos sin entry hardcoded suelen vivir aca, asi que el match por
    -- spellID los cubre tambien.
    local custom = ns.db and ns.db.readyCheckPanel and ns.db.readyCheckPanel.actionItems
    if custom then
        addFromList("flask",       custom.flask)
        addFromList("wellFed",     custom.wellFed)
        addFromList("augmentRune", custom.augmentRune)
        addFromList("weaponImbue", custom.weaponImbue)
    end
    -- Buff aura spellIDs directos (saltan GetItemSpell): IDs reportados por
    -- usuarios o documentados donde el aura difiere del cast spell del item.
    for kind, ids in pairs(KNOWN_BUFF_SPELLIDS) do
        local set = _knownSpellIDsCache[kind]
        if set and ids then
            for _, id in ipairs(ids) do set[id] = true end
        end
    end
end

local function GetKnownBuffSpellIDs(kind)
    if _bagScanDirty then RebuildBagScan() end
    if _knownSpellIDsDirty then RebuildKnownSpellIDs() end
    return _knownSpellIDsCache and _knownSpellIDsCache[kind] or {}
end

-- GetAvailableItems: retorna lista de { itemID, count } para todos los items
-- del kind que el player tiene en bag. Combina:
-- 1) User custom (actionItems[kind])
-- 2) Bag scan results (i18n-safe via subclass)
-- 3) Defaults hardcoded
-- Dedupe por itemID. Para kind "recoveryHP", filtramos healthstones si no
-- hay warlock en el grupo (no hace sentido mostrar item que no podes obtener).
local function GetAvailableItems(kind)
    if not GetItemCount then return {} end
    if _bagScanDirty then RebuildBagScan() end

    local out = {}
    local seen = {}
    local hasWarlock = (kind == "recoveryHP") and HasClassInGroup("WARLOCK") or false

    local function tryAdd(id)
        if seen[id] then return end
        if kind == "recoveryHP" and HEALTHSTONE_IDS[id] and not hasWarlock then return end
        local count = GetItemCount(id)
        if count and count > 0 then
            out[#out + 1] = { itemID = id, count = count }
            seen[id] = true
        end
    end

    local s = ns.db and ns.db.readyCheckPanel
    local custom = s and s.actionItems and s.actionItems[kind]
    if custom then
        for _, id in ipairs(custom) do tryAdd(id) end
    end

    local scanned = _bagScanCache and _bagScanCache[kind]
    if scanned then
        for _, id in ipairs(scanned) do tryAdd(id) end
    end

    local defaults = DEFAULT_USE_ITEMS[kind]
    if defaults then
        for _, id in ipairs(defaults) do tryAdd(id) end
    end

    return out
end

-- ============================================================
-- Check definitions
-- ============================================================

-- i18n-safe buff detection: iteramos auras y matcheamos por spellId (numero
-- estable inter-idiomas) contra el set de spellIDs conocidos del kind. El set
-- se construye desde GetItemSpell de cada item hardcoded + bag-scanned.
-- Fallback opcional por nombre solo se usa si el item del buff no esta en
-- ninguna de nuestras listas (compatibilidad amplia con cliente ingles).
local function CheckBuffByKind(kind, nameFallbackPredicate)
    if not (C_UnitAuras and C_UnitAuras.GetBuffDataByIndex) then return false end
    local spellIDs = GetKnownBuffSpellIDs(kind)
    local i = 1
    while true do
        local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        if aura.spellId and spellIDs[aura.spellId] then
            return { ok = true, icon = aura.icon, expirationTime = aura.expirationTime, spellID = aura.spellId }
        end
        if nameFallbackPredicate and aura.name and nameFallbackPredicate(aura.name) then
            return { ok = true, icon = aura.icon, expirationTime = aura.expirationTime, spellID = aura.spellId }
        end
        i = i + 1
    end
    return false
end

local function CheckWellFed()
    return CheckBuffByKind("wellFed",
        function(n) return n == "Well Fed" end) -- fallback enUS
end

local function CheckFlask()
    return CheckBuffByKind("flask",
        function(n) return n:find("^Phial of") ~= nil or n:find("^Flask of") ~= nil end) -- fallback enUS
end

-- Resuelve la categoria de contenido actual a partir del estado del juego.
-- Devuelve "raid" / "mplus" / "dungeon" / "pvp" / "delve" / nil.
--
-- M+ requiere chequear C_ChallengeMode (un dungeon comun es instanceType
-- "party"; un M+ activo agrega un keystone que se detecta con
-- GetActiveChallengeMapID > 0).
-- Delves: en TWW+ son scenarios pero comparten ese flag con otros scenarios
-- (e.g., follower dungeons). C_DelvesUI.IsInActiveDelveTier no siempre existe
-- en Midnight, asi que usamos "scenario" como heuristica simple. El user
-- puede desactivar la categoria Delve si la deteccion da falsos positivos.
local function GetCurrentContentType()
    if not GetInstanceInfo then return nil end
    local _, itype = GetInstanceInfo()
    if not itype or itype == "none" then return nil end
    if itype == "raid" then return "raid" end
    if itype == "pvp" or itype == "arena" then return "pvp" end
    if itype == "party" then
        local cm = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID
            and C_ChallengeMode.GetActiveChallengeMapID()
        if cm and cm > 0 then return "mplus" end
        return "dungeon"
    end
    if itype == "scenario" then return "delve" end
    return nil
end

-- CheckTalentLoadout: solo aparece dentro de instancia. Retorna info del
-- loadout activo vs el configurado para la categoria de contenido actual.
--   { ok = true, mode = "neutral", activeName = X }  — sin config p/ esta categoria
--   { ok = true, mode = "match",   activeName = X }  — activo == configurado
--   { ok = false, mode = "wrong",  activeName = X, expectedName = Y, expectedID = N }
-- nil cuando no aplica (fuera de instancia, sin spec, etc) y la row se skipea.
local function CheckTalentLoadout()
    local contentType = GetCurrentContentType()
    if not contentType then return nil end

    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex or not GetSpecializationInfo then return nil end
    local specID = select(1, GetSpecializationInfo(specIndex))
    if not specID then return nil end

    local activeID = C_ClassTalents and C_ClassTalents.GetLastSelectedSavedConfigID
        and C_ClassTalents.GetLastSelectedSavedConfigID(specID) or nil
    local activeName
    if activeID and C_Traits and C_Traits.GetConfigInfo then
        local info = C_Traits.GetConfigInfo(activeID)
        activeName = info and info.name
    end
    activeName = activeName or "?"

    -- Lookup: iteramos loadouts del spec actual, buscamos el primero cuyo flag
    -- para `contentType` este encendido. Si dos loadouts comparten la misma
    -- categoria es ambiguo — gana el primero.
    local stored = ns.db and ns.db.readyCheckPanel and ns.db.readyCheckPanel.talentLoadouts or {}
    local expectedID
    local configs = C_ClassTalents and C_ClassTalents.GetConfigIDsBySpecID
        and C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
    for _, cid in ipairs(configs) do
        local data = stored[tostring(cid)]
        if type(data) == "table" and data[contentType] == true then
            expectedID = cid
            break
        end
    end

    if not expectedID then
        return { ok = true, mode = "neutral", activeName = activeName }
    end
    if expectedID == activeID then
        return { ok = true, mode = "match", activeName = activeName }
    end
    local expectedName
    if C_Traits and C_Traits.GetConfigInfo then
        local info = C_Traits.GetConfigInfo(expectedID)
        expectedName = info and info.name
    end
    return {
        ok = false, mode = "wrong",
        activeName = activeName,
        expectedName = expectedName or "?",
        expectedID = expectedID,
    }
end

local function CheckHealthstone()
    -- Row visible solo cuando hay warlock en el grupo (incluye al player).
    -- Verifica presencia en bolsa, no buff — el sub-row mostrara cantidad.
    if not HasClassInGroup("WARLOCK") then return nil end
    if not GetItemCount then return false end
    for _, id in ipairs(DEFAULT_USE_ITEMS.healthstone) do
        local c = GetItemCount(id)
        if c and c > 0 then return true end
    end
    return false
end

local function CheckAugmentRune()
    return CheckBuffByKind("augmentRune",
        function(n) return n:find("Augment Rune") ~= nil end) -- fallback enUS
end

local RESOURCE_FULL_THRESHOLD = 0.95

-- Cache de HP/mana actualizado via eventos UNIT_HEALTH/UNIT_POWER_UPDATE. Durante
-- READY_CHECK el contexto restringido hace que UnitHealth/UnitPower retornen
-- SecureNumber que ni ToPublic ni SiphonNumber siempre logran convertir. Pero
-- esos eventos fire CONTINUAMENTE fuera de restricted context (incluso mientras
-- el ready check esta activo), asi que cacheamos el ultimo valor "limpio" que
-- pudimos leer. Inicializamos con 0 — primer render post-PLAYER_ENTERING_WORLD
-- ya tiene valores reales.
local _stats = { hp = 0, hpMax = 0, mana = 0, manaMax = 0 }

local function ReadResourceNumber(val)
    local pub = ns.ToPublic and ns.ToPublic(val)
    if type(pub) == "number" then return pub end
    if ns.SiphonNumber then
        local sn = ns.SiphonNumber(val)
        if type(sn) == "number" then return sn end
    end
    return nil
end

local function RefreshPlayerStats()
    local hp = ReadResourceNumber(UnitHealth("player"))
    if hp then _stats.hp = hp end
    local hpMax = ReadResourceNumber(UnitHealthMax("player"))
    if hpMax then _stats.hpMax = hpMax end
    local mana = ReadResourceNumber(UnitPower("player", 0))
    if mana then _stats.mana = mana end
    local manaMax = ReadResourceNumber(UnitPowerMax("player", 0))
    if manaMax then _stats.manaMax = manaMax end
end

-- Clases que NO usan mana — para esas la row de mana se skipea totalmente.
-- El resto (mage/priest/warlock/druid/shaman/paladin/evoker) muestra row mana.
local CLASSES_WITHOUT_MANA = {
    WARRIOR     = true,
    ROGUE       = true,
    HUNTER      = true,
    DEATHKNIGHT = true,
    MONK        = true,
    DEMONHUNTER = true,
}

local function CheckHpFull()
    RefreshPlayerStats()
    if _stats.hpMax > 0 then
        return (_stats.hp / _stats.hpMax) >= RESOURCE_FULL_THRESHOLD
    end
    -- Fallback: no pudimos leer el valor (SecureNumber irrecuperable en
    -- contexto restringido). En lugar de skipear la row, la mostramos como
    -- reminder estatico — el user al menos ve "te conviene revisar vida" +
    -- las opciones de potion/healthstone disponibles.
    return false
end

local function CheckResourceFull()
    -- Mana row es un recordatorio estatico siempre visible. En contexto
    -- restringido del READY_CHECK no podemos leer UnitPower de forma confiable
    -- (SecureNumber), asi que NO conditionamos sobre el valor actual ni sobre
    -- la clase — "como no se puede obtener, no se puede tener" condicion. Si el
    -- user esta en una clase sin mana (warrior/rogue/etc) puede desactivar la
    -- row desde Config (toggle checkResourceFull).
    return true
end

local function GetTalentBannerData()
    local data = {}

    local specID
    if GetSpecialization and GetSpecializationInfo then
        local idx = GetSpecialization()
        if idx then
            local id, name = GetSpecializationInfo(idx)
            specID = id
            data.specName = name
        end
    end

    -- GetActiveConfigID devuelve el scratch config ("Default"). El nombre del
    -- loadout guardado lo da GetLastSelectedSavedConfigID(specID).
    if specID and C_ClassTalents and C_ClassTalents.GetLastSelectedSavedConfigID then
        local savedID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
        if savedID and C_Traits and C_Traits.GetConfigInfo then
            local info = C_Traits.GetConfigInfo(savedID)
            if info and info.name and info.name ~= "" then
                data.loadoutName = info.name
            end
        end
    end

    local activeConfigID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
                           and C_ClassTalents.GetActiveConfigID()
    if C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec then
        local subTreeID = C_ClassTalents.GetActiveHeroTalentSpec()
        if subTreeID and activeConfigID and C_Traits and C_Traits.GetSubTreeInfo then
            local subInfo = C_Traits.GetSubTreeInfo(activeConfigID, subTreeID)
            if subInfo then
                data.heroName = subInfo.name
                data.heroIcon = subInfo.iconElementID or subInfo.icon
            end
        end
    end

    if not (data.loadoutName or data.specName or data.heroName) then
        return nil
    end
    return data
end

local CHECKS = {
    { key = "checkWellFed",      labelKey = "Well Fed",       fn = CheckWellFed,     kind = "wellFed",     category = "items" },
    { key = "checkFlask",        labelKey = "Flask / Phial",  fn = CheckFlask,       kind = "flask",       category = "items" },
    { key = "checkAugmentRune",  labelKey = "Augment Rune",   fn = CheckAugmentRune, kind = "augmentRune", category = "items" },
}

-- ============================================================
-- Class buff checks (party-aware)
-- ============================================================
-- Para cada raid buff, verificamos primero si la clase que lo provee esta en
-- el grupo (player incluido). Si si, verificamos si tengo el buff activo.
-- Si la clase no esta presente, el check retorna nil y el row se skipea
-- (no tiene sentido mostrar "te falta Skyfury" si no hay shaman).

-- enName SIEMPRE en ingles — se usa en el whisper "Could you cast <enName>".
-- El label visible se resuelve via C_Spell.GetSpellInfo(spellID).name en el
-- idioma del cliente. enName mantenido aparte para garantizar que el whisper
-- llegue legible al receptor sin importar su locale.
local CLASS_BUFF_CHECKS = {
    { class = "PRIEST",  spellID = 21562,  labelKey = "Power Word: Fortitude", enName = "Power Word: Fortitude" },
    { class = "MAGE",    spellID = 1459,   labelKey = "Arcane Intellect",      enName = "Arcane Intellect"      },
    { class = "WARRIOR", spellID = 6673,   labelKey = "Battle Shout",          enName = "Battle Shout"          },
    { class = "DRUID",   spellID = 1126,   labelKey = "Mark of the Wild",      enName = "Mark of the Wild"      },
    { class = "SHAMAN",  spellID = 462854, labelKey = "Skyfury",               enName = "Skyfury"               },
    { class = "EVOKER",  spellID = 364342, labelKey = "Blessing of the Bronze",enName = "Blessing of the Bronze"},
}

-- Encuentra un miembro de la clase X en mi party/raid. Si yo soy de esa clase,
-- retorna "SELF" (sentinel) para que el caller sepa que se debe ofrecer "cast"
-- en lugar de "ask".
local function FindClassMember(class)
    if not class then return nil end
    local _, myClass = UnitClass("player")
    if myClass == class then return "SELF" end
    local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
    if n == 0 then return nil end
    local prefix = (IsInRaid and IsInRaid()) and "raid" or "party"
    for i = 1, n do
        local unit = prefix .. i
        local _, c = UnitClass(unit)
        if c == class then
            -- GetUnitName(unit, true) devuelve "Name-Realm" para cross-realm,
            -- "Name" si mismo realm. Eso funciona como target de /w.
            return (GetUnitName and GetUnitName(unit, true)) or UnitName(unit)
        end
    end
    return nil
end

local function MakeClassBuffCheckFn(class, spellID)
    return function()
        if not HasClassInGroup(class) then return nil end -- skip row
        -- 1) Exact match contra spellID del cast (funciona para buffs donde
        --    cast spellID == aura spellID, p.ej. Mark of the Wild 1126).
        if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
            if aura then
                return { ok = true, icon = aura.icon, expirationTime = aura.expirationTime, spellID = aura.spellId or spellID }
            end
        end
        -- 2) Fallback por nombre: cuando el aura aplicado tiene spellID distinto
        --    al cast (Blessing of the Bronze 364342 cast → aura spellID varia
        --    por clase del target: 381732/381746/381748/381749/381750/381751/
        --    381756). Tomamos el nombre del spell del cast via C_Spell.GetSpellInfo
        --    (que devuelve el nombre LOCALIZADO al cliente — "Bendicion del
        --    bronce" en esES) y matcheamos contra aura.name. i18n-safe porque
        --    ambos extremos vienen del mismo API en el mismo idioma.
        local buffName
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            buffName = info and info.name
        end
        if buffName and C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
            local i = 1
            while true do
                local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
                if not aura then break end
                if aura.name == buffName then
                    return { ok = true, icon = aura.icon, expirationTime = aura.expirationTime, spellID = aura.spellId or spellID }
                end
                i = i + 1
            end
        end
        return false
    end
end

-- ============================================================
-- Class weapon imbue check (Shaman / Rogue self-cast spells)
-- ============================================================
-- Algunas clases tienen spells que aplican imbues temporales al arma (Shaman
-- weapon enchants, Rogue poisons). El imbue expira o falta antes del pull —
-- queremos detectarlo y ofrecer al player cast self.
--
-- Mapping per-spec: cada spec tiene su imbue propio. Solo aparece la row si:
--   - El player es de una clase con imbue
--   - El spec activo tiene un imbue definido
--   - El player APRENDIO el spell (IsPlayerSpell — algunos talents son opcionales)
--
-- Spell IDs estables historicos:
--   382021 Earthliving Weapon       (Restoration Shaman)
--   33757  Windfury Weapon          (Enhancement Shaman)
--   318038 Flametongue Weapon       (Elemental Shaman)
--   2823   Deadly Poison            (Assassination Rogue)
--   8679   Wound Poison             (Outlaw/Subtlety Rogue)

local CLASS_IMBUE_BY_SPEC = {
    [264] = 382021, -- Resto Shaman
    [263] = 33757,  -- Enhancement Shaman (Windfury)
    [262] = 318038, -- Elemental Shaman (Flametongue)
    [259] = 2823,   -- Assassination Rogue (Deadly Poison)
    [260] = 8679,   -- Outlaw Rogue (Wound Poison)
    [261] = 8679,   -- Subtlety Rogue (Wound Poison)
}

local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local IsPlayerSpell = IsPlayerSpell

local function GetCurrentClassImbueSpellID()
    if not (GetSpecialization and GetSpecializationInfo) then return nil end
    local idx = GetSpecialization()
    if not idx then return nil end
    local specID = GetSpecializationInfo(idx)
    if not specID then return nil end
    local spellID = CLASS_IMBUE_BY_SPEC[specID]
    if not spellID then return nil end
    if IsPlayerSpell and not IsPlayerSpell(spellID) then return nil end
    return spellID
end

local function CheckClassImbue()
    -- Universal weapon enchant check: aplica a TODAS las clases. Si el spec
    -- tiene un self-cast imbue (Shaman/Rogue), spellID se incluye y el row
    -- ofrece boton "Cast". Si no (Monk/Druid/Mage/etc.), spellID=nil — no
    -- hay boton de cast pero igual aparece la row con sub-rows clickeables
    -- de aceites/runas del inventario via kind="weaponImbue".
    local spellID = GetCurrentClassImbueSpellID()
    local icon
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then icon = info.iconID end
    end

    -- Path 1: weapon enchant temporal clasico (oils Midnight como Thalassian
    -- Phoenix Oil 243733-734 / Oil of Dawn 243735-736, runas, class self-cast
    -- imbues). Chequeamos AMBAS manos — Monk/Rogue dual-wield, y el aceite
    -- puede estar en offhand. La row queda OK si CUALQUIER mano tiene enchant.
    if GetWeaponEnchantInfo then
        local hasMH, mhExpMs, _, _, hasOH, ohExpMs = GetWeaponEnchantInfo()
        if hasMH or hasOH then
            local expMs = (hasMH and mhExpMs) or (hasOH and ohExpMs) or nil
            local expirationTime = expMs and expMs > 0 and (GetTime() + expMs / 1000) or nil
            return { ok = true, icon = icon, expirationTime = expirationTime, spellID = spellID }
        end
    end

    -- Path 2: algunos "aceites" Midnight aplican un PLAYER AURA en vez de un
    -- weapon enchant temporal — GetWeaponEnchantInfo no los ve. Buscamos el
    -- aura via CheckBuffByKind("weaponImbue") que usa el set de spellIDs
    -- conocidos (derivado de GetItemSpell sobre DEFAULT_USE_ITEMS.weaponImbue +
    -- custom + KNOWN_BUFF_SPELLIDS.weaponImbue).
    local auraResult = CheckBuffByKind("weaponImbue")
    if auraResult and auraResult.ok then
        return {
            ok = true,
            icon = auraResult.icon or icon,
            expirationTime = auraResult.expirationTime,
            spellID = auraResult.spellID or spellID,
        }
    end

    return { ok = false, icon = icon, spellID = spellID }
end

-- Append weapon imbue check ANTES de class buffs para que aparezca arriba
-- en la lista (es self-cast, prioridad de player). kind="weaponImbue" hace
-- que GetAvailableItems devuelva los aceites/runas del inventario como
-- sub-rows clickeables.
table.insert(CHECKS, {
    key          = "checkClassImbue",
    fn           = CheckClassImbue,
    labelKey     = "Weapon Imbue",
    isClassImbue = true, -- flag para el action button (Cast self) — solo se muestra si result.spellID ~= nil
    kind         = "weaponImbue",
    category     = "items",
})

-- Append class buff checks al CHECKS. Todos comparten el mismo toggle key
-- `checkClassBuffs` — un solo switch master para todos los raid buffs. Las
-- funciones fn ya devuelven nil cuando la clase no esta en el grupo, asi que
-- los rows aparecen / desaparecen dinamicamente segun composicion.
--
-- spellID se pasa al CHECK para que Render() pueda resolver el label via
-- C_Spell.GetSpellInfo(spellID).name — eso devuelve el NOMBRE OFICIAL del
-- spell en el idioma actual del cliente (Skyfury -> "Abrasacielos" en esES,
-- "Sturmgewalt" en deDE, etc.). Las traducciones literales manuales son
-- inconsistentes con como Blizzard nombra los spells in-game; mejor consultar
-- la API i18n-safe.
for _, def in ipairs(CLASS_BUFF_CHECKS) do
    table.insert(CHECKS, {
        key           = "checkClassBuffs",
        spellID       = def.spellID,
        labelKey      = def.labelKey,    -- fallback solo si GetSpellInfo retorna nil
        enName        = def.enName,      -- usado en el whisper en ingles
        providerClass = def.class,       -- clase que provee, para action button
        fn            = MakeClassBuffCheckFn(def.class, def.spellID),
        category      = "items",
        -- sin kind: no hay item asociado (el buff lo castea otro player)
    })
end

-- Healthstone check: aparece solo cuando hay un warlock en el grupo. Pass/fail
-- por presencia de la piedra en la bolsa (no es un buff). Sub-rows muestran
-- las piedras + cantidad disponible (click-to-use).
table.insert(CHECKS, {
    key      = "checkHealthstone",
    labelKey = "Healthstone",
    fn       = CheckHealthstone,
    kind     = "healthstone",
    category = "items",
})

-- Talent loadout validation: solo aparece dentro de instancia. Muestra el
-- loadout activo. Si esta configurado un loadout para esa instancia y el
-- activo no matchea, ofrece boton Switch.
table.insert(CHECKS, {
    key             = "checkTalentLoadout",
    labelKey        = "Loadout",
    fn              = CheckTalentLoadout,
    isTalentLoadout = true,
    category        = "talents",
})

-- Mana reminder al final de todo: row blanca neutral "Revisa tu mana" + sub-rows
-- con las comidas/pociones de mana siempre visibles. No es pass/fail; es un
-- recordatorio + acceso click-to-use a los items de recuperacion. Va ultimo
-- porque es el item "menos urgente" visualmente (sin X roja) y queremos que
-- los buffs faltantes destaquen arriba.
table.insert(CHECKS, {
    key             = "checkResourceFull",
    labelKey        = "Check your mana",
    fn              = CheckResourceFull,
    kind            = "recoveryMana",
    isManaReminder  = true,
    category        = "items",
})

local function GetSettings()
    return ns.db and ns.db.readyCheckPanel
end

-- ============================================================
-- Font scale helpers
-- ============================================================
-- Cada fontString registrado con su tamaño base; ApplyFontScale aplica
-- (base * scale) preservando font file y flags. Esto permite re-scalar
-- dinamicamente cuando el user cambia el slider en config.

local function RegisterScalable(fs, baseSize)
    fs._baseSize = baseSize
    return fs
end

local function ApplyFontScale(fs, scale)
    if not fs or not fs._baseSize then return end
    local fontFile, _, flags = fs:GetFont()
    if fontFile then
        fs:SetFont(fontFile, mathfloor(fs._baseSize * scale + 0.5), flags or "")
    end
end

-- ============================================================
-- UI: panel + rows + sub-rows
-- ============================================================

local READY_TEX     = "Interface\\RaidFrame\\ReadyCheck-Ready"
local NOT_READY_TEX = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local UNKNOWN_ITEM_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Formato compacto del tiempo restante. >1h: "1h23m"; >1m: "23m"; sino "45s".
-- Devuelve "" si no hay expirationTime o ya expiro.
local function FormatTimeRemaining(expirationTime)
    if not expirationTime or expirationTime == 0 then return "" end
    local remaining = expirationTime - GetTime()
    if remaining <= 0 then return "" end
    if remaining >= 3600 then
        local h = mathfloor(remaining / 3600)
        local m = mathfloor((remaining % 3600) / 60)
        return string.format("%dh%02dm", h, m)
    elseif remaining >= 60 then
        return string.format("%dm", mathfloor(remaining / 60))
    else
        return string.format("%ds", mathfloor(remaining))
    end
end

-- _kindExpanded[kind] = true cuando el user expandio manualmente los sub-rows
-- de un check con buff OK. Estado per-session (no persiste). Cuando el buff
-- falta, los sub-rows se muestran siempre ignorando este flag.
local _kindExpanded = {}

-- _eatingState[kind] = { finish = GetTime()+N, itemID = clickedItem }. Cuando
-- el user clickea un sub-row para comer/beber, arrancamos un countdown de 10s
-- y NO asumimos que el buff esta OK — esperamos a que el channel termine y
-- el aura aparezca de verdad. Solo aplica a kinds channeled (wellFed,
-- recoveryMana); flasks/runas/healthstones son instant.
local _eatingState = {}

-- Channels que disparan countdown al click. Flask/Aug Rune/Healthstone son
-- instant (1.5s GCD) y el buff aparece casi inmediato — no necesitan timer.
local CHANNELED_KINDS = {
    wellFed = true,
    recoveryMana = true,
}

local EATING_DURATION = 10  -- channel typico de food/drink

local function StartEatingTimer(kind, itemID)
    if not CHANNELED_KINDS[kind] then return end
    _eatingState[kind] = { finish = GetTime() + EATING_DURATION, itemID = itemID }
end

-- Aura comun de food/drink channel: cuando esta presente en el player, sabemos
-- que esta comiendo/bebiendo (sin importar si dispar via click en nuestro
-- subRow o desde una action bar / drag del item). Si la aura existe, devolvemos
-- su expirationTime — el caller la trata como un eating-state aura-derivado.
local EATING_AURA_SPELLID = 1232065
local function GetEatingAuraExpiration()
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return nil end
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(EATING_AURA_SPELLID)
    return aura and aura.expirationTime or nil
end

-- Forward decl: Render se define mas abajo, pero CreateRow lo necesita para
-- el OnClick del toggle button. Asignamos sin `local` despues para evitar
-- shadow del forward decl.
local Render

local function ForceRender() if panelFrame and panelFrame:IsShown() then Render() end end

-- Row principal: display de estado del check (verde/rojo). Ya no es clickeable
-- por si mismo — el click-to-use vive en los sub-rows. Pero el toggle button
-- (▶/▼) si es clickeable para expandir/colapsar sub-rows cuando buff esta OK.
local function CreateRow(parent)
    local row = CreateFrame("Frame", nil, parent)

    -- Icono envuelto en un Frame mouse-enabled para soportar tooltip on hover.
    -- El render setea row.iconFrame._spellID (buff/spell tooltip) o ._itemID
    -- (item tooltip) segun el dispatch; OnEnter resuelve segun el que este
    -- definido. Limpiados a nil entre frames cuando no aplica (X roja, mana
    -- reminder neutral) para evitar tooltips heredados de frames anteriores.
    local iconFrame = CreateFrame("Frame", nil, row)
    iconFrame:SetSize(16, 16)
    iconFrame:SetPoint("LEFT", row, "LEFT", 8, 0)
    iconFrame:EnableMouse(true)
    iconFrame:SetScript("OnEnter", function(self)
        if self._spellID and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self._spellID)
            GameTooltip:Show()
        elseif self._itemID and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self._itemID)
            GameTooltip:Show()
        end
    end)
    iconFrame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    row.iconFrame = iconFrame

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(iconFrame)
    row.icon = icon

    -- Toggle button con texturas estandar de WoW (PlusButton/MinusButton).
    -- Las versiones unicode ▶/▼ no renderizaban bien con las fuentes del juego.
    -- PlusButton/MinusButton son texturas universales 32x32 que se escalan
    -- limpias al tamaño 16x16 que usamos.
    local toggleBtn = CreateFrame("Button", nil, row)
    toggleBtn:SetSize(16, 16)
    toggleBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    local arrow = toggleBtn:CreateTexture(nil, "OVERLAY")
    arrow:SetAllPoints()
    arrow:SetTexture("Interface\\Buttons\\UI-PlusButton-Up") -- collapsed default
    toggleBtn.arrow = arrow
    -- Highlight overlay para feedback hover.
    local toggleHl = toggleBtn:CreateTexture(nil, "HIGHLIGHT")
    toggleHl:SetAllPoints()
    toggleHl:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    toggleHl:SetBlendMode("ADD")
    toggleBtn:SetHighlightTexture(toggleHl)
    toggleBtn:SetScript("OnClick", function(self)
        local kind = self._kind
        if not kind then return end
        _kindExpanded[kind] = not _kindExpanded[kind]
        ForceRender()
    end)
    toggleBtn:Hide()
    row.toggleBtn = toggleBtn

    -- Action button (Cast / Ask) para class buffs missing. SecureActionButton
    -- para que pueda castear spells (type="spell") O mandar whisper (type="macro"
    -- con macrotext="/w name msg"). Solapado en posicion con toggleBtn — solo
    -- uno visible a la vez segun el contexto del row.
    local actionBtn = CreateFrame("Button", nil, row, "SecureActionButtonTemplate")
    actionBtn:SetSize(46, 16)
    actionBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    actionBtn:RegisterForClicks("AnyUp", "AnyDown")
    local actionBg = actionBtn:CreateTexture(nil, "BACKGROUND")
    actionBg:SetAllPoints()
    actionBg:SetColorTexture(0.2, 0.4, 0.65, 0.4)
    actionBtn.bg = actionBg
    local actionBorder = actionBtn:CreateTexture(nil, "BORDER")
    actionBorder:SetAllPoints()
    actionBorder:SetColorTexture(0.4, 0.6, 1.0, 0.6)
    actionBtn.border = actionBorder
    local actionLabel = actionBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    actionLabel:SetPoint("CENTER")
    actionLabel:SetTextColor(1, 1, 1)
    RegisterScalable(actionLabel, 10)
    actionBtn.label = actionLabel
    local actionHl = actionBtn:CreateTexture(nil, "HIGHLIGHT")
    actionHl:SetAllPoints()
    actionHl:SetColorTexture(1, 1, 1, 0.15)
    actionHl:SetBlendMode("ADD")
    actionBtn:SetHighlightTexture(actionHl)
    actionBtn:Hide()
    row.actionBtn = actionBtn

    -- Switch button: usado SOLO por la row de talent loadout. Boton normal
    -- (no SecureAction) porque C_ClassTalents.LoadConfig es Lua puro, no
    -- requiere proteccion. Posicion solapada con actionBtn — solo uno visible
    -- a la vez segun el def del row.
    local switchBtn = CreateFrame("Button", nil, row)
    switchBtn:SetSize(60, 16)
    switchBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    local sBg = switchBtn:CreateTexture(nil, "BACKGROUND")
    sBg:SetAllPoints()
    sBg:SetColorTexture(0.55, 0.25, 0.20, 0.5)
    local sBorder = switchBtn:CreateTexture(nil, "BORDER")
    sBorder:SetAllPoints()
    sBorder:SetColorTexture(0.9, 0.5, 0.4, 0.7)
    local sLabel = switchBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sLabel:SetPoint("CENTER")
    sLabel:SetTextColor(1, 1, 1)
    RegisterScalable(sLabel, 10)
    switchBtn.label = sLabel
    local sHl = switchBtn:CreateTexture(nil, "HIGHLIGHT")
    sHl:SetAllPoints()
    sHl:SetColorTexture(1, 1, 1, 0.15)
    sHl:SetBlendMode("ADD")
    switchBtn:SetHighlightTexture(sHl)
    switchBtn:SetScript("OnClick", function(self)
        local cid = self._configID
        if not (cid and C_ClassTalents and C_ClassTalents.LoadConfig) then return end
        if InCombatLockdown() then
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff5555HNZ:|r " ..
                    (ns.L["Can't switch loadout in combat."] or "Can't switch loadout in combat."))
            end
            return
        end
        -- LoadConfig devuelve un Enum.LoadConfigResult:
        --   Error / NoChangesNecessary / LoadInProgress / Ready
        -- "Ready" significa que el load termino pero todavia falta commitear los
        -- traits con C_Traits.CommitConfig — sin ese segundo paso, los talentos
        -- quedan SELECCIONADOS en el editor pero no APLICADOS al char (el bug
        -- que el user reportaba).
        local loadResult = C_ClassTalents.LoadConfig(cid, true)
        if Enum and Enum.LoadConfigResult and loadResult == Enum.LoadConfigResult.Ready then
            if C_Traits and C_Traits.CommitConfig then
                C_Traits.CommitConfig(cid)
            end
        end
        -- Update last-selected: necesario para que GetLastSelectedSavedConfigID
        -- en la proxima render del panel devuelva el nuevo configID activo
        -- (sino el panel seguiria mostrando el loadout viejo como "active").
        if C_ClassTalents.UpdateLastSelectedSavedConfigID then
            local specIndex = GetSpecialization and GetSpecialization()
            if specIndex and GetSpecializationInfo then
                local specID = select(1, GetSpecializationInfo(specIndex))
                if specID then
                    C_ClassTalents.UpdateLastSelectedSavedConfigID(specID, cid)
                end
            end
        end
    end)
    switchBtn:Hide()
    row.switchBtn = switchBtn

    local time = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    time:SetPoint("RIGHT", toggleBtn, "LEFT", -4, 0)
    time:SetJustifyH("RIGHT")
    time:SetTextColor(0.65, 0.85, 1.0)
    RegisterScalable(time, 10)
    row.time = time

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    label:SetPoint("RIGHT", time, "LEFT", -6, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    RegisterScalable(label, 12)
    row.label = label

    return row
end

local function SetRowState(row, ok, labelText)
    row.label:SetText(labelText)
    if row.time then row.time:SetText("") end -- HP/Mana no tienen expiration
    row.icon:SetTexCoord(0, 1, 0, 1)
    row.icon:SetVertexColor(1, 1, 1)
    if ok then
        row.icon:SetTexture(READY_TEX)
        row.label:SetTextColor(0.55, 1.0, 0.55)
    else
        row.icon:SetTexture(NOT_READY_TEX)
        row.label:SetTextColor(1.0, 0.45, 0.45)
    end
end

local function SetRowBuff(row, ok, icon, labelText, expirationTime)
    row.label:SetText(labelText)
    row.icon:SetVertexColor(1, 1, 1)
    if ok then
        -- Icon disponible (e.g., class buff con spellID conocido) -> icono del
        -- spell. Si no hay icon (Monk con aceite aplicado pero sin self-cast
        -- imbue de clase => spellID nil), fallback a READY_TEX (check verde
        -- generico). Antes la condicion `ok and icon` caia al else en este
        -- caso y pintaba X roja aunque el buff estaba activo.
        if icon then
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.icon:SetTexture(icon)
        else
            row.icon:SetTexCoord(0, 1, 0, 1)
            row.icon:SetTexture(READY_TEX)
        end
        row.label:SetTextColor(0.55, 1.0, 0.55)
        if row.time then
            row.time:SetText(FormatTimeRemaining(expirationTime))
        end
    else
        row.icon:SetTexCoord(0, 1, 0, 1)
        row.icon:SetTexture(NOT_READY_TEX)
        row.label:SetTextColor(1.0, 0.45, 0.45)
        if row.time then row.time:SetText("") end
    end
end

-- Sub-row: lista un item disponible bajo un row principal de kind.
-- SecureActionButton (click-to-use), tooltip on hover, indented from main row.
local function CreateItemSubRow(parent)
    local row = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    row:RegisterForClicks("AnyUp", "AnyDown")
    row:EnableMouse(false)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", row, "LEFT", 28, 0)  -- indented vs main row icon at 8
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -36, 0)  -- reservamos espacio para el count
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetTextColor(0.85, 0.85, 0.85)
    RegisterScalable(label, 10)
    row.label = label

    local count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    count:SetJustifyH("RIGHT")
    count:SetTextColor(0.9, 0.9, 0.5)  -- amarillo claro para destacar la cantidad
    RegisterScalable(count, 10)
    row.count = count

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetColorTexture(1, 1, 1, 0.10)
    hl:SetBlendMode("ADD")
    row:SetHighlightTexture(hl)
    row:GetHighlightTexture():Hide()

    -- Tooltip: anchor a la derecha del row porque el panel suele estar centro/top.
    row:SetScript("OnEnter", function(self)
        if not self._itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self._itemID)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- PostClick fires DESPUES del secure action (que dispara /use item:ID).
    -- Iniciamos el countdown 10s solo para kinds channeled. Despues del
    -- countdown el panel valida si el buff aparecio (si no, vuelve a rojo).
    row:SetScript("PostClick", function(self)
        if self._kind and self._itemID then
            StartEatingTimer(self._kind, self._itemID)
            ForceRender()
        end
    end)

    return row
end

-- Configura el sub-row con un item especifico. En combate los secure attrs
-- estan lockeados — dejamos lo que estaba del ultimo refresh out-of-combat.
local function ConfigureSubRow(row, itemID, count)
    if not row then return end
    row._itemID = itemID

    -- Icon: primero intentamos GetItemIcon (sync, no requiere item cacheado).
    -- Si falla, fallback al placeholder.
    local iconFile = GetItemIcon and GetItemIcon(itemID)
    row.icon:SetTexture(iconFile or UNKNOWN_ITEM_ICON)

    -- Name: GetItemInfo retorna nil si el item no esta cacheado todavia. En
    -- ese caso disparamos un request async y mostramos "Item #ID" placeholder.
    -- Proximo Render() (poll 0.5s) ya tendra el name cacheado.
    local name = GetItemInfo and select(1, GetItemInfo(itemID))
    if not name then
        if C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, itemID)
        end
        name = "Item #" .. itemID
    end
    row.label:SetText(name)
    row.count:SetText("x" .. count)

    if not InCombatLockdown() then
        row:SetAttribute("type", "item")
        row:SetAttribute("item", "item:" .. itemID)
        row:EnableMouse(true)
    end
    if row:GetHighlightTexture() then row:GetHighlightTexture():Show() end
end

local function ClearSubRow(row)
    if not row then return end
    row._itemID = nil
    if not InCombatLockdown() then
        row:SetAttribute("type", nil)
        row:SetAttribute("item", nil)
        row:EnableMouse(false)
    end
    if row:GetHighlightTexture() then row:GetHighlightTexture():Hide() end
    row:Hide()
end

local function CreatePanelFrame()
    local s = GetSettings() or {}
    local f = CreateFrame("Frame", "HNZHealingToolsReadyCheckPanel", UIParent, "BackdropTemplate")
    f:SetFrameStrata("HIGH"); f:SetFrameLevel(180)
    f:SetSize(s.width or 280, 100)
    f:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 200)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.7)
    f:SetBackdropBorderColor(0.4, 0.6, 1.0, 0.9)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -6)
    title:SetText(ns.L["Ready Check"])
    title:SetTextColor(0.6, 0.85, 1.0)
    RegisterScalable(title, 12)
    f.title = title

    -- Close button (X) en la esquina superior derecha. Fallback manual cuando
    -- el panel queda pegado por algun motivo (event miss, /reload mid-check,
    -- etc.) sin tener que esperar READY_CHECK_FINISHED.
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    f.closeBtn = closeBtn

    -- Banner de talentos: bloque alto con hero-spec icon + loadout name MUY
    -- prominente. Texto base mas grande que antes (16pt vs 14pt) para que el
    -- nombre del loadout sea lo primero que el ojo agarra cuando aparece el
    -- panel. fontScale del config multiplica todo esto.
    local banner = CreateFrame("Frame", nil, f)
    banner:Hide()

    local heroIcon = banner:CreateTexture(nil, "ARTWORK")
    heroIcon:SetSize(40, 40)
    heroIcon:SetPoint("LEFT", banner, "LEFT", 6, 0)
    heroIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    banner.heroIcon = heroIcon

    local iconBg = banner:CreateTexture(nil, "BACKGROUND")
    iconBg:SetPoint("TOPLEFT", heroIcon, "TOPLEFT", -1, 1)
    iconBg:SetPoint("BOTTOMRIGHT", heroIcon, "BOTTOMRIGHT", 1, -1)
    iconBg:SetColorTexture(0, 0, 0, 0.6)
    banner.iconBg = iconBg

    -- Glow detras del loadout text para destacarlo aun mas como el dato clave
    -- del panel. Solo backdrop sutil; el texto en si va con color amarillo
    -- brillante + font size grande.
    local loadoutText = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    loadoutText:SetPoint("TOPLEFT", heroIcon, "TOPRIGHT", 10, -2)
    loadoutText:SetPoint("RIGHT", banner, "RIGHT", -6, 0)
    loadoutText:SetJustifyH("LEFT")
    loadoutText:SetWordWrap(false)
    loadoutText:SetTextColor(1.0, 0.92, 0.35)  -- amarillo dorado mas saturado
    RegisterScalable(loadoutText, 18)  -- base 18 (grande), scale-able hasta 36
    banner.loadoutText = loadoutText

    local specText = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    specText:SetPoint("BOTTOMLEFT", heroIcon, "BOTTOMRIGHT", 10, 2)
    specText:SetPoint("RIGHT", banner, "RIGHT", -6, 0)
    specText:SetJustifyH("LEFT")
    specText:SetWordWrap(false)
    specText:SetTextColor(0.75, 0.85, 1.0)
    RegisterScalable(specText, 11)
    banner.specText = specText

    f.banner = banner

    f.rows = {}
    f.subRows = {}
    return f
end

local function ApplyHeroIcon(tex, asset)
    if not asset then
        tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
        return
    end
    if type(asset) == "string" then
        local ok = pcall(tex.SetAtlas, tex, asset, false)
        if ok then return end
    end
    if type(asset) == "number" then
        tex:SetTexture(asset)
        return
    end
    tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
end

-- Acquire helpers para pools de rows / sub-rows. Se reusan entre Render() calls
-- — hide el surplus en lugar de destruir frames. SecureActionButton no se puede
-- crear in-combat asi que el pool crece on-demand pero solo out-of-combat.
local function AcquireRow(panel, index)
    local row = panel.rows[index]
    if not row then
        -- CreateRow incluye SecureActionButton children (actionBtn) — la
        -- creacion de secure frames esta lockeada in-combat. Si in-combat y
        -- el row no existe todavia, retornamos nil y el caller skipea ese
        -- check silently. Ready check tipico llega out-of-combat asi que esto
        -- raramente sucede.
        if InCombatLockdown() then return nil end
        row = CreateRow(panel)
        panel.rows[index] = row
    end
    return row
end

local function AcquireSubRow(panel, index)
    local row = panel.subRows[index]
    if not row then
        if InCombatLockdown() then return nil end  -- secure frames creation lockeada
        row = CreateItemSubRow(panel)
        panel.subRows[index] = row
    end
    return row
end

local MAX_SUBROWS_PER_KIND = 5

Render = function()
    if not panelFrame then panelFrame = CreatePanelFrame() end
    local s = GetSettings() or {}
    local rowH = s.rowHeight or 22
    local subRowH = s.subRowHeight or 18
    local width = s.width or 280
    local fontScale = s.fontScale or 1.0
    if fontScale < 0.8 then fontScale = 0.8 end
    if fontScale > 2.5 then fontScale = 2.5 end

    panelFrame:SetWidth(width)
    panelFrame:SetAlpha(s.opacity or 0.95)
    panelFrame:ClearAllPoints()
    panelFrame:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 200)
    panelFrame.title:SetText(ns.L["Ready Check"])
    ApplyFontScale(panelFrame.title, fontScale)

    -- Banner: dimensionamos en funcion del fontScale para que crezca con el
    -- loadout text. base 50px; scale=1.5 -> 64px; scale=2 -> 80px aprox.
    local bannerOffset = 0
    local categoriesEnabled = s.categoriesEnabled or {}
    local talentsCategoryOn = categoriesEnabled.talents ~= false
    if s.infoTalents ~= false and talentsCategoryOn then
        local data = GetTalentBannerData()
        if data then
            local banner = panelFrame.banner
            banner.loadoutText:SetText(data.loadoutName or data.specName or "")
            local sub
            if data.specName and data.heroName then
                sub = data.specName .. "  ·  " .. data.heroName
            else
                sub = data.specName or data.heroName or ""
            end
            banner.specText:SetText(sub)
            ApplyHeroIcon(banner.heroIcon, data.heroIcon)
            ApplyFontScale(banner.loadoutText, fontScale)
            ApplyFontScale(banner.specText, fontScale)

            -- Hero icon size sube con scale para no desentonar con texto grande.
            local heroSize = mathfloor(40 * mathmax(1.0, fontScale * 0.85) + 0.5)
            banner.heroIcon:SetSize(heroSize, heroSize)

            local bannerHeight = mathfloor(50 * mathmax(1.0, fontScale * 0.85) + 0.5)
            banner:ClearAllPoints()
            banner:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 8, -24)
            banner:SetPoint("RIGHT", panelFrame, "RIGHT", -8, 0)
            banner:SetHeight(bannerHeight)
            banner:Show()
            bannerOffset = bannerHeight + 4
        else
            panelFrame.banner:Hide()
        end
    else
        panelFrame.banner:Hide()
    end

    -- Layout dinamico: yOffset acumula altura consumida desde el top del area
    -- bajo el banner. Cada row principal y cada sub-row avanza yOffset.
    local yOffset = 0
    local rowIndex = 0
    local subRowIndex = 0
    local effectiveRowH = mathfloor(rowH * mathmax(1.0, fontScale * 0.9) + 0.5)
    local effectiveSubRowH = mathfloor(subRowH * mathmax(1.0, fontScale * 0.9) + 0.5)

    for _, def in ipairs(CHECKS) do
        local categoryOn = (not def.category) or (categoriesEnabled[def.category] ~= false)
        if s[def.key] ~= false and categoryOn then
            local result = def.fn()
            if result ~= nil then
                rowIndex = rowIndex + 1
                local row = AcquireRow(panelFrame, rowIndex)

                -- Label resolution: usamos C_Spell.GetSpellInfo(spellID).name
                -- (i18n-safe). El spellID puede venir del def estatico (class
                -- buffs) o del result table dinamico (class imbue, donde el
                -- spell depende del spec activo).
                local resolveSpellID = def.spellID
                if def.isClassImbue and type(result) == "table" and result.spellID then
                    resolveSpellID = result.spellID
                end
                local label
                if resolveSpellID and C_Spell and C_Spell.GetSpellInfo then
                    local info = C_Spell.GetSpellInfo(resolveSpellID)
                    if info and info.name and info.name ~= "" then
                        label = info.name
                    end
                end
                if not label then
                    label = ns.L[def.labelKey] or def.labelKey
                end
                local t = type(result)
                local isOk = false
                if t == "boolean" then isOk = (result == true)
                elseif t == "table" then isOk = (result.ok == true) end

                -- Todas las rows usan el mismo tamaño base. El mana reminder
                -- (def.isManaReminder) es recordatorio neutral, NO escala. Las
                -- rows missing siguen siendo del mismo tamaño que las OK —
                -- la diferencia visual es el icono (check verde vs X roja).
                local rowHThis = effectiveRowH
                local rowScaleThis = fontScale
                local rowIconSize = 16

                row:SetSize(width - 16, rowHThis)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 8, -24 - bannerOffset - yOffset)
                row:Show()
                row.iconFrame:SetSize(rowIconSize, rowIconSize)
                row.icon:SetSize(rowIconSize, rowIconSize)
                -- Reset tooltip targets cada frame — branches relevantes los
                -- vuelven a setear; los que no aplican (X roja, manaReminder
                -- neutral, status string) los dejan limpios.
                row.iconFrame._spellID = nil
                row.iconFrame._itemID = nil

                -- Eating state: cuando el user clickeo una comida hace <10s y
                -- el buff todavia no esta activo, mostramos countdown en lugar
                -- de "missing". Auto-clear cuando el buff aparece (early exit)
                -- o cuando el timer expira (timeout — el buff no llego por
                -- algun motivo, channel interrumpido).
                local eating = def.kind and _eatingState[def.kind] or nil
                local nowT = GetTime()
                -- Si no hay eating-state desde click pero el aura de canalizar
                -- comida/bebida esta activa en el player, sintetizamos eating-state
                -- desde el aura (sin itemID conocido). Aplica solo a kinds que
                -- canalizan (wellFed, recoveryMana) — flask/runa son instant.
                if not eating and def.kind and CHANNELED_KINDS[def.kind] then
                    local exp = GetEatingAuraExpiration()
                    if exp and exp > nowT then
                        eating = { finish = exp, itemID = nil }
                    end
                end
                if eating then
                    if isOk or nowT >= eating.finish then
                        _eatingState[def.kind] = nil
                        eating = nil
                    end
                end

                if eating then
                    -- Override del display: countdown "eating" en lugar de
                    -- pass/fail. Icon = el item especifico que se clickeo
                    -- (visual feedback de "estas comiendo ESTO").
                    row.label:SetText(label .. "  " .. (ns.L["(eating)"] or "(eating)"))
                    row.label:SetTextColor(1.0, 0.85, 0.4) -- amarillo "in progress"
                    local iconID = eating.itemID and GetItemIcon and GetItemIcon(eating.itemID)
                    if iconID then
                        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        row.icon:SetTexture(iconID)
                        row.icon:SetVertexColor(1, 1, 1)
                        row.iconFrame._itemID = eating.itemID
                    else
                        row.icon:SetTexCoord(0, 1, 0, 1)
                        row.icon:SetTexture("Interface\\Icons\\INV_Misc_Food_15")
                        row.icon:SetVertexColor(1, 1, 1)
                    end
                    if row.time then
                        row.time:SetText(math.ceil(eating.finish - nowT) .. "s")
                    end
                elseif def.isManaReminder then
                    -- Mana reminder: row neutral blanca, no pass/fail. Icono
                    -- generico de bebida + texto "Revisa tu mana". Las
                    -- sub-rows con items de mana se renderizan abajo siempre
                    -- (showSubRows forzado a true para este def).
                    row.label:SetText(ns.L["Check your mana"] or "Check your mana")
                    row.label:SetTextColor(1, 1, 1)
                    if row.time then row.time:SetText("") end
                    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    row.icon:SetTexture("Interface\\Icons\\INV_Drink_07")
                    row.icon:SetVertexColor(1, 1, 1)
                elseif def.isTalentLoadout and t == "table" then
                    if row.time then row.time:SetText("") end
                    row.icon:SetTexCoord(0, 1, 0, 1)
                    if result.mode == "wrong" then
                        row.label:SetText((ns.L["Wrong loadout"] or "Wrong loadout")
                            .. ": " .. result.activeName .. " \194\187 " .. result.expectedName)
                        row.label:SetTextColor(1.0, 0.7, 0.35)
                        row.icon:SetTexture(NOT_READY_TEX)
                        row.icon:SetVertexColor(1, 1, 1)
                    elseif result.mode == "match" then
                        row.label:SetText((ns.L["Loadout"] or "Loadout") .. ": " .. result.activeName)
                        row.label:SetTextColor(0.55, 1.0, 0.55)
                        row.icon:SetTexture(READY_TEX)
                        row.icon:SetVertexColor(1, 1, 1)
                    else
                        row.label:SetText((ns.L["Loadout"] or "Loadout") .. ": " .. result.activeName)
                        row.label:SetTextColor(1, 1, 1)
                        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        row.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_07")
                        row.icon:SetVertexColor(1, 1, 1)
                    end
                elseif t == "string" then
                    row.label:SetText(label .. ": " .. result)
                    if row.time then row.time:SetText("") end
                    row.icon:SetTexCoord(0, 1, 0, 1)
                    row.icon:SetTexture(READY_TEX)
                    row.icon:SetVertexColor(0.55, 0.75, 1.0)
                    row.label:SetTextColor(0.85, 0.9, 1.0)
                elseif t == "table" then
                    SetRowBuff(row, result.ok, result.icon, label, result.expirationTime)
                    if result.ok and result.spellID then
                        row.iconFrame._spellID = result.spellID
                    end
                else
                    SetRowState(row, result, label)
                end
                ApplyFontScale(row.label, rowScaleThis)
                if row.time then ApplyFontScale(row.time, rowScaleThis) end

                yOffset = yOffset + rowHThis

                -- isOk ya fue computado arriba (antes del dispatch eating/normal).
                -- Configurar el toggle button del row. Solo lo mostramos cuando:
                --   - el check tiene kind (HP/Mana/Well Fed/Flask/AugmentRune)
                --   - hay items disponibles para listar (sino no hay nada que toggle)
                --   - el buff esta OK (cuando falla, sub-rows siempre visibles, no
                --     necesitamos toggle — el user ya esta viendo sus opciones).
                local items = def.kind and GetAvailableItems(def.kind) or nil
                local hasItems = items and #items > 0
                local expanded = _kindExpanded[def.kind] == true
                -- Mana reminder fuerza sub-rows siempre visibles (es un
                -- recordatorio: queremos que las comidas/pociones de mana
                -- esten siempre a un click, sin requerir expandir el toggle).
                local showSubRows = hasItems and (not isOk or expanded or def.isManaReminder)

                if row.toggleBtn then
                    if def.kind and hasItems and isOk and not def.isManaReminder then
                        row.toggleBtn._kind = def.kind
                        if expanded then
                            row.toggleBtn.arrow:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
                        else
                            row.toggleBtn.arrow:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
                        end
                        -- Escalar el boton con fontScale para que crezca con el resto del texto.
                        local btnSize = mathfloor(16 * mathmax(1.0, fontScale * 0.9) + 0.5)
                        row.toggleBtn:SetSize(btnSize, btnSize)
                        row.toggleBtn:Show()
                    else
                        row.toggleBtn._kind = nil
                        row.toggleBtn:Hide()
                    end
                end

                -- Action button: solo para class buffs (def.providerClass) cuando
                -- el buff esta missing (isOk == false). Cast si yo provee, Ask
                -- (whisper en ingles) si otro miembro de la clase provee. Si la
                -- clase no esta en grupo, el check fn ya devolvio nil y no entramos
                -- aqui — pero igual hacemos el find por seguridad.
                if row.actionBtn then
                    local actionConfigured = false

                    -- Class imbue: Cast self, spellID viene del result (per-spec).
                    if def.isClassImbue and not isOk and type(result) == "table" and result.spellID then
                        if not InCombatLockdown() then
                            row.actionBtn:SetAttribute("type", "spell")
                            row.actionBtn:SetAttribute("spell", result.spellID)
                            row.actionBtn:SetAttribute("macrotext", nil)
                        end
                        row.actionBtn.label:SetText(ns.L["Cast"] or "Cast")
                        row.actionBtn.bg:SetColorTexture(0.25, 0.55, 0.20, 0.5)
                        row.actionBtn.border:SetColorTexture(0.5, 0.9, 0.4, 0.7)
                        ApplyFontScale(row.actionBtn.label, fontScale)
                        row.actionBtn:Show()
                        actionConfigured = true
                    elseif def.providerClass and not isOk and t ~= "string" then
                        local target = FindClassMember(def.providerClass)
                        if target == "SELF" then
                            if not InCombatLockdown() then
                                row.actionBtn:SetAttribute("type", "spell")
                                row.actionBtn:SetAttribute("spell", def.spellID)
                                row.actionBtn:SetAttribute("macrotext", nil)
                            end
                            row.actionBtn.label:SetText(ns.L["Cast"] or "Cast")
                            row.actionBtn.bg:SetColorTexture(0.25, 0.55, 0.20, 0.5)
                            row.actionBtn.border:SetColorTexture(0.5, 0.9, 0.4, 0.7)
                            ApplyFontScale(row.actionBtn.label, fontScale)
                            row.actionBtn:Show()
                            actionConfigured = true
                        elseif target then
                            if not InCombatLockdown() then
                                row.actionBtn:SetAttribute("type", "macro")
                                row.actionBtn:SetAttribute("spell", nil)
                                -- Mensaje generico en ingles — el receptor sabe
                                -- que buff provee (su clase tiene uno solo en
                                -- esta lista). Usamos la palabra "Buff" en
                                -- lugar del nombre del spell para que sea
                                -- breve, universal y no asuma idioma del target.
                                local msg = "Could you Buff me please?"
                                row.actionBtn:SetAttribute("macrotext", "/w " .. target .. " " .. msg)
                            end
                            row.actionBtn.label:SetText(ns.L["Ask"] or "Ask")
                            row.actionBtn.bg:SetColorTexture(0.2, 0.4, 0.65, 0.4)
                            row.actionBtn.border:SetColorTexture(0.4, 0.6, 1.0, 0.6)
                            ApplyFontScale(row.actionBtn.label, fontScale)
                            row.actionBtn:Show()
                            actionConfigured = true
                        end
                    end
                    if not actionConfigured then
                        if not InCombatLockdown() then
                            row.actionBtn:SetAttribute("type", nil)
                            row.actionBtn:SetAttribute("spell", nil)
                            row.actionBtn:SetAttribute("macrotext", nil)
                        end
                        row.actionBtn:Hide()
                    end
                end

                -- Switch button: solo para la row de talent loadout cuando hay
                -- mismatch (mode=="wrong"). El click llama C_ClassTalents.LoadConfig
                -- con el configID esperado para esta instancia.
                if row.switchBtn then
                    if def.isTalentLoadout and type(result) == "table"
                       and result.mode == "wrong" and result.expectedID then
                        row.switchBtn._configID = result.expectedID
                        row.switchBtn.label:SetText(ns.L["Switch"] or "Switch")
                        ApplyFontScale(row.switchBtn.label, fontScale)
                        row.switchBtn:Show()
                    else
                        row.switchBtn._configID = nil
                        row.switchBtn:Hide()
                    end
                end

                -- Reposiciono row.time despues de decidir que boton se muestra
                -- (toggle / action / switch / ninguno). El time se anchora al borde
                -- izquierdo del boton visible, o al row right si todos hidden.
                if row.time then
                    row.time:ClearAllPoints()
                    if row.actionBtn and row.actionBtn:IsShown() then
                        row.time:SetPoint("RIGHT", row.actionBtn, "LEFT", -4, 0)
                    elseif row.switchBtn and row.switchBtn:IsShown() then
                        row.time:SetPoint("RIGHT", row.switchBtn, "LEFT", -4, 0)
                    elseif row.toggleBtn and row.toggleBtn:IsShown() then
                        row.time:SetPoint("RIGHT", row.toggleBtn, "LEFT", -4, 0)
                    else
                        row.time:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                    end
                end

                -- Sub-rows usan el mismo tamaño base que el resto (el mana
                -- reminder ya NO escala 1.55x — el user pidio mismo tamaño
                -- que los otros items para mantener look uniforme).
                local thisSubRowH = effectiveSubRowH
                local thisScale = fontScale

                if def.kind and showSubRows then

                    local shown = 0
                    for i = 1, mathmax(0, #items) do
                        if shown >= MAX_SUBROWS_PER_KIND then break end
                        local entry = items[i]
                        subRowIndex = subRowIndex + 1
                        local subRow = AcquireSubRow(panelFrame, subRowIndex)
                        if subRow then
                            subRow:SetSize(width - 16, thisSubRowH)
                            subRow:ClearAllPoints()
                            subRow:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 8, -24 - bannerOffset - yOffset)
                            subRow:Show()
                            subRow._kind = def.kind  -- usado por PostClick para iniciar eating timer
                            ConfigureSubRow(subRow, entry.itemID, entry.count)
                            if subRow.icon then
                                subRow.icon:SetSize(14, 14)
                            end
                            ApplyFontScale(subRow.label, thisScale)
                            ApplyFontScale(subRow.count, thisScale)
                            yOffset = yOffset + thisSubRowH
                            shown = shown + 1
                        end
                    end
                    if #items > MAX_SUBROWS_PER_KIND then
                        subRowIndex = subRowIndex + 1
                        local subRow = AcquireSubRow(panelFrame, subRowIndex)
                        if subRow then
                            subRow:SetSize(width - 16, thisSubRowH)
                            subRow:ClearAllPoints()
                            subRow:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 8, -24 - bannerOffset - yOffset)
                            subRow:Show()
                            subRow._itemID = nil
                            subRow.icon:SetTexture("")
                            local more = (#items - MAX_SUBROWS_PER_KIND)
                            subRow.label:SetText("    +" .. more .. " " .. (ns.L["more"] or "more"))
                            subRow.count:SetText("")
                            ApplyFontScale(subRow.label, thisScale)
                            ApplyFontScale(subRow.count, thisScale)
                            if not InCombatLockdown() then
                                subRow:SetAttribute("type", nil)
                                subRow:SetAttribute("item", nil)
                                subRow:EnableMouse(false)
                            end
                            if subRow:GetHighlightTexture() then subRow:GetHighlightTexture():Hide() end
                            yOffset = yOffset + thisSubRowH
                        end
                    end
                end

                -- Empty state: buff falta Y no hay items en bag para usar. El
                -- user necesita saber que le falta el recurso aunque no pueda
                -- arreglarlo desde el panel (no tiene items). Sub-row rojo
                -- explicativo. Aplica a todos los kinds (wellFed/flask/runa)
                -- y al mana reminder (cuando no hay comidas/pociones de mana
                -- en la bolsa), pero el reminder usa colores neutrales en
                -- lugar de rojo para no contradecir su tono "recordatorio".
                local showEmptyState = def.kind and not eating and not hasItems
                    and (def.isManaReminder or not isOk)
                if showEmptyState then
                    subRowIndex = subRowIndex + 1
                    local subRow = AcquireSubRow(panelFrame, subRowIndex)
                    if subRow then
                        subRow:SetSize(width - 16, thisSubRowH)
                        subRow:ClearAllPoints()
                        subRow:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 8, -24 - bannerOffset - yOffset)
                        subRow:Show()
                        subRow._itemID = nil
                        subRow._kind = nil
                        subRow.icon:SetTexture(NOT_READY_TEX)
                        subRow.icon:SetTexCoord(0, 1, 0, 1)
                        subRow.icon:SetVertexColor(1, 1, 1)
                        if subRow.icon then
                            subRow.icon:SetSize(14, 14)
                        end
                        subRow.label:SetText("    " .. (ns.L["No items in bag"] or "No items in bag"))
                        if def.isManaReminder then
                            subRow.label:SetTextColor(1, 1, 1)
                            subRow.icon:SetTexture("Interface\\Icons\\INV_Drink_07")
                            subRow.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        else
                            subRow.label:SetTextColor(1.0, 0.55, 0.55)
                        end
                        subRow.count:SetText("")
                        ApplyFontScale(subRow.label, thisScale)
                        ApplyFontScale(subRow.count, thisScale)
                        if not InCombatLockdown() then
                            subRow:SetAttribute("type", nil)
                            subRow:SetAttribute("item", nil)
                            subRow:EnableMouse(false)
                        end
                        if subRow:GetHighlightTexture() then subRow:GetHighlightTexture():Hide() end
                        yOffset = yOffset + thisSubRowH
                    end
                end
            end
        end
    end

    -- Hide rows/sub-rows del pool que no se usaron este Render
    for i = rowIndex + 1, #panelFrame.rows do
        panelFrame.rows[i]:Hide()
    end
    for i = subRowIndex + 1, #panelFrame.subRows do
        ClearSubRow(panelFrame.subRows[i])
    end

    local height = 24 + bannerOffset + mathmax(effectiveRowH, yOffset) + 8
    panelFrame:SetHeight(height)
end

local function ShowPanel()
    local s = GetSettings()
    if not s or s.enabled == false then return end
    Render()
    panelFrame:Show()
end

local function HidePanel()
    if panelFrame then panelFrame:Hide() end
end

local function PollWhileShown(self, e)
    self._acc = (self._acc or 0) + e
    if self._acc < 0.5 then return end
    self._acc = 0
    if panelFrame and panelFrame:IsShown() then
        Render()
    end
end

-- ============================================================
-- Public hooks
-- ============================================================

function ns:RefreshReadyCheckPanel()
    if panelFrame and panelFrame:IsShown() then Render() end
    if ns._readyCheckAnchor and ns._readyCheckAnchor:IsShown() then
        ns:RefreshReadyCheckPanelAnchor()
    end
end

function ns:TestReadyCheckPanel()
    local s = GetSettings()
    if not s then return end
    Render()
    if not panelFrame then return end
    panelFrame:Show()
    C_Timer.After(8, function()
        if panelFrame and panelFrame:IsShown() then HidePanel() end
    end)
end

-- ============================================================
-- Anchor draggable
-- ============================================================

local function CreateAnchor()
    local s = GetSettings() or {}
    local a = CreateFrame("Frame", "HNZHealingToolsReadyCheckAnchor", UIParent, "BackdropTemplate")
    a:SetSize(s.width or 280, 60)
    a:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 200)
    a:SetFrameStrata("HIGH"); a:SetFrameLevel(150)
    a:SetMovable(true); a:EnableMouse(true); a:RegisterForDrag("LeftButton")
    a:SetClampedToScreen(true)
    a:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    a:SetBackdropColor(0, 0.4, 0.7, 0.45)
    a:SetBackdropBorderColor(0.4, 0.6, 1.0, 0.9)

    local label = a:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(ns.L["Ready Check"])
    label:SetTextColor(1, 1, 1)

    local hint = a:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOP", a, "BOTTOM", 0, -4)
    hint:SetText(ns.L["Drag to move"])
    hint:SetTextColor(0.8, 0.8, 0.8)

    a:SetScript("OnDragStart", function(self) self:StartMoving() end)
    a:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        local sx, sy = self:GetCenter()
        if cx and sx then
            local d = ns.db and ns.db.readyCheckPanel
            if d then
                d.offsetX = mathfloor(sx - cx + 0.5)
                d.offsetY = mathfloor(sy - cy + 0.5)
            end
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", d and d.offsetX or 0, d and d.offsetY or 0)
            if panelFrame then
                panelFrame:ClearAllPoints()
                panelFrame:SetPoint("CENTER", UIParent, "CENTER", d and d.offsetX or 0, d and d.offsetY or 0)
            end
        end
    end)

    return a
end

function ns:RefreshReadyCheckPanelAnchor()
    if not ns._readyCheckAnchor then return end
    local s = GetSettings() or {}
    ns._readyCheckAnchor:SetWidth(s.width or 280)
    ns._readyCheckAnchor:ClearAllPoints()
    ns._readyCheckAnchor:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 200)
end

function ns:ShowReadyCheckPanelAnchor()
    if not ns._readyCheckAnchor then ns._readyCheckAnchor = CreateAnchor() end
    ns:RefreshReadyCheckPanelAnchor()
    ns._readyCheckAnchor:Show()
end

function ns:HideReadyCheckPanelAnchor()
    if ns._readyCheckAnchor then ns._readyCheckAnchor:Hide() end
end

function ns:ToggleReadyCheckPanelAnchor()
    if ns._readyCheckAnchor and ns._readyCheckAnchor:IsShown() then
        ns:HideReadyCheckPanelAnchor()
        return false
    end
    ns:ShowReadyCheckPanelAnchor()
    return true
end

function ns:IsReadyCheckPanelAnchorShown()
    return ns._readyCheckAnchor and ns._readyCheckAnchor:IsShown() or false
end

-- ============================================================
-- Init: events + polling
-- ============================================================

function ns:InitReadyCheckPanel()
    inCombat = UnitAffectingCombat("player") and true or false

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("READY_CHECK")
    ev:RegisterEvent("READY_CHECK_FINISHED")
    -- READY_CHECK_CONFIRM fires cuando CUALQUIER player responde — filtramos
    -- por unit == "player" para ocultar el panel cuando NOSOTROS aceptamos
    -- (o declinamos) sin esperar a que todos los demas respondan o expire
    -- el timer (que es cuando dispara READY_CHECK_FINISHED).
    ev:RegisterEvent("READY_CHECK_CONFIRM")
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    -- Bag changes invalidan el bag scan + el set de buff spellIDs.
    ev:RegisterEvent("BAG_UPDATE_DELAYED")
    -- Refresh HP/Mana cache via eventos out-of-restricted-context. Mas
    -- confiable que leer durante el ready check donde la API esta tainted.
    ev:RegisterUnitEvent("UNIT_HEALTH", "player")
    ev:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    ev:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    ev:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- Stats inicial al cargar
    RefreshPlayerStats()
    ev:SetScript("OnEvent", function(_, event, arg1)
        if event == "READY_CHECK" then
            ShowPanel()
        elseif event == "READY_CHECK_FINISHED" then
            HidePanel()
        elseif event == "READY_CHECK_CONFIRM" and arg1 == "player" then
            HidePanel()
        elseif event == "PLAYER_REGEN_DISABLED" then
            inCombat = true
            -- Auto-hide al entrar en combate. Si el ready check todavia esta
            -- en curso (sin _FINISHED disparado) el panel quedaria pegado toda
            -- la pelea — el user no tiene contexto util durante combate.
            HidePanel()
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false
        elseif event == "BAG_UPDATE_DELAYED" then
            MarkBagScanDirty()
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
            or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER"
            or event == "PLAYER_ENTERING_WORLD" then
            RefreshPlayerStats()
        end
    end)

    local poll = CreateFrame("Frame")
    poll:SetScript("OnUpdate", PollWhileShown)
end
