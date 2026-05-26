local addonName, ns = ...

ns.ADDON_NAME = addonName
local function _readVersion()
    local meta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    if type(meta) == "function" then
        local ok, v = pcall(meta, addonName, "Version")
        if ok and type(v) == "string" and v ~= "" then return v end
    end
    return "?"
end
ns.VERSION = _readVersion()

local DEFAULT_COLORS = {
    {r=0.2,g=0.8,b=1.0,a=1},{r=1.0,g=0.4,b=0.4,a=1},{r=0.4,g=1.0,b=0.4,a=1},
    {r=1.0,g=0.8,b=0.2,a=1},{r=0.8,g=0.4,b=1.0,a=1},{r=1.0,g=0.6,b=0.2,a=1},
}
ns.DEFAULT_COLORS = DEFAULT_COLORS

-- ============================================================
-- Migracion versionada + backup automatico (2026-05-10).
--
-- Cuando bumpees CURRENT_SCHEMA_VERSION agrega una entry nueva en MIGRATIONS:
-- una funcion que muta el perfil DESDE version-1 A version. MigrateProfile
-- aplica los steps en orden segun la version del perfil.
--
-- Antes de aplicar cualquier step, snapshotea el perfil entero a
-- HNZHealingToolsDB.profileBackups[name]. Si algun step falla (pcall), restaura
-- desde el backup y avisa por chat. La UI Profiles → Backups expone un boton
-- "Restore" para revertir manualmente.
--
-- Agregar un campo nuevo en PROFILE_DEFAULTS sigue siendo seguro y NO requiere
-- migracion: MergeDefaults lo rellena solo. Solo necesitas migration cuando:
--   * renombras un campo
--   * cambias el tipo (boolean -> string, etc.)
--   * eliminas un campo y necesitas convertir su valor a otra cosa
-- ============================================================

local CURRENT_SCHEMA_VERSION = 6

local function MigrateVisibilityField(cfg)
    if not cfg then return end
    if cfg.showOnlyInCombat ~= nil then
        if cfg.visibility == nil then
            cfg.visibility = cfg.showOnlyInCombat and "combat" or "always"
        end
        cfg.showOnlyInCombat = nil
    end
end

local MIGRATIONS = {
    [2] = function(p)
        -- showOnlyInCombat (boolean) -> visibility (enum "always"|"combat"|"ooc")
        MigrateVisibilityField(p.cursorDisplay)
        MigrateVisibilityField(p.ringDisplay)
        MigrateVisibilityField(p.cooldownPulse)
        if p.cursorRing then
            MigrateVisibilityField(p.cursorRing)
            MigrateVisibilityField(p.cursorRing.cast)
            MigrateVisibilityField(p.cursorRing.dot)
        end
    end,
    [3] = function(p)
        -- mrtTimeline: noteText (string unica) -> notes (lista por-encuentro).
        -- lingerAfter -> activeWindow (rename + default mas grande, 2s -> 10s).
        if not p.mrtTimeline then return end
        local mt = p.mrtTimeline
        if mt.notes == nil then mt.notes = {} end
        if mt.noteText and mt.noteText ~= "" then
            -- Preservar la nota existente como "Default" (id=0 = cualquier encuentro)
            table.insert(mt.notes, { id = 0, name = "Default", text = mt.noteText })
        end
        mt.noteText = nil
        if mt.lingerAfter then
            -- Conservar la intencion del usuario: si tenia un linger custom, usarlo
            -- como base; sino default 10s lo pondra MergeDefaults.
            mt.activeWindow = math.max(mt.lingerAfter, 3)
            mt.lingerAfter = nil
        end
    end,
    [4] = function(p)
        -- vendorRestock: rediseño completo de la feature antes de release.
        -- Reemplaza el modelo kind-based (targets por kind + extraItems +
        -- kindsEnabled, derivando items de readyCheckPanel.actionItems) por
        -- una lista explicita curada por el user con drag/search + target +
        -- maxPrice + lastPaid history. Dropear los campos viejos previene
        -- "ruido" de MergeDefaults conservandolos para siempre.
        if not p.vendorRestock then return end
        local vr = p.vendorRestock
        vr.targets = nil
        vr.kindsEnabled = nil
        vr.extraItems = nil
        if not vr.items then vr.items = {} end
    end,
    [5] = function(p)
        -- Vendor Restock UX cleanup: confirmAbove pasa de global -> per-entry
        -- (cada item tiene su propio threshold). Se eliminan tambien fields
        -- de UI que ya no se exponen: visibility (siempre always), buttonScale
        -- y opacity (hardcodeados). La posicion del boton se mantiene en
        -- offsetX/Y — ahora se setea solo arrastrando el boton.
        if not p.vendorRestock then return end
        local vr = p.vendorRestock
        local oldConfirm = vr.confirmAbove or 1000000  -- default historico 100g
        if vr.items then
            for _, e in ipairs(vr.items) do
                if e.confirmAbove == nil then
                    e.confirmAbove = oldConfirm
                end
            end
        end
        vr.confirmAbove = nil
        vr.visibility = nil
        vr.buttonScale = nil
        vr.opacity = nil
    end,
    [6] = function(p)
        -- Ready Check Panel: bumpeamos el width default 320 -> 420 porque las
        -- filas nuevas (talent loadout "Sin loadout asignado para Mazmorra / M+",
        -- talentos incorrectos con activeName + expectedName) no entraban en 320.
        -- Solo migramos cuando el user tenia exactamente el viejo default — si
        -- ya lo habia subido o bajado a algo distinto respetamos su preferencia.
        if p.readyCheckPanel and p.readyCheckPanel.width == 320 then
            p.readyCheckPanel.width = 420
        end
    end,
}

local function RestoreInPlace(target, snapshot)
    -- Pisa target con el contenido de snapshot SIN romper la referencia (ns.db
    -- y otros consumidores apuntan a target). DeepCopy previo para que mutaciones
    -- futuras del perfil no afecten al backup.
    local copy = ns.DeepCopy(snapshot)
    for k in pairs(target) do target[k] = nil end
    for k, v in pairs(copy) do target[k] = v end
end

local function MigrateProfile(p, name)
    if not p then return end
    local from = p._schemaVersion or 1
    if from >= CURRENT_SCHEMA_VERSION then return end

    -- Snapshot pre-migracion. Sobrescribe backup anterior si lo habia (mantenemos
    -- solo el ultimo). El usuario puede restaurar via UI antes del proximo login.
    HNZHealingToolsDB.profileBackups = HNZHealingToolsDB.profileBackups or {}
    HNZHealingToolsDB.profileBackups[name] = {
        data = ns.DeepCopy(p),
        schemaVersion = from,
        timestamp = time(),
        addonVersion = ns.VERSION,
    }

    for v = from + 1, CURRENT_SCHEMA_VERSION do
        local step = MIGRATIONS[v]
        if step then
            local ok, err = pcall(step, p)
            if not ok then
                RestoreInPlace(p, HNZHealingToolsDB.profileBackups[name].data)
                print(("|cffff5555HNZ Healing Tools|r: migration v%d failed for profile '%s': %s. Restored from backup."):format(v, name, tostring(err)))
                return
            end
        end
    end
    p._schemaVersion = CURRENT_SCHEMA_VERSION
end

ns.MigrateProfile = MigrateProfile

function ns.HasBackup(name)
    return HNZHealingToolsDB and HNZHealingToolsDB.profileBackups
        and HNZHealingToolsDB.profileBackups[name] ~= nil
end

function ns.GetBackupInfo(name)
    if not ns.HasBackup(name) then return nil end
    local b = HNZHealingToolsDB.profileBackups[name]
    return {
        schemaVersion = b.schemaVersion,
        timestamp = b.timestamp,
        addonVersion = b.addonVersion,
    }
end

function ns.GetProfilesWithBackups()
    local out = {}
    if not (HNZHealingToolsDB and HNZHealingToolsDB.profileBackups) then return out end
    for name in pairs(HNZHealingToolsDB.profileBackups) do
        if HNZHealingToolsDB.profiles[name] then table.insert(out, name) end
    end
    table.sort(out)
    return out
end

-- Restaura el perfil a su estado pre-migracion. NO re-migra (eso pasaria en el
-- proximo login, generando un nuevo backup). El backup se borra para evitar el
-- ciclo restore-migrate-restore en la misma sesion.
function ns.RestoreFromBackup(name)
    if not ns.HasBackup(name) then return false end
    local target = HNZHealingToolsDB.profiles[name]
    if not target then return false end
    RestoreInPlace(target, HNZHealingToolsDB.profileBackups[name].data)
    HNZHealingToolsDB.profileBackups[name] = nil
    return true
end

ns.PROFILE_DEFAULTS = {
    -- Tamaño persistido de la ventana de config. Se actualiza cuando el usuario
    -- arrastra la esquina de resize. Min/max clampeados por SetResizeBounds en
    -- Config.lua (no aceptes valores de aqui sin sanitar).
    configWindow = {
        width = 900,
        height = 560,
    },
    -- Cursor display
    cursorSpells = {},
    cursorAuras = {},
    cursorDisplay = {
        iconSize = 28,
        iconSpacing = 2,
        offsetX = 20,
        offsetY = -20,
        updateInterval = 0.1,
        visibility = "always",  -- "always" | "combat" | "ooc"
        opacity = 0.9,
        maxColumns = 8,
        fontSize = 12,
        enabled = true,
    },
    -- Ring display
    ringAuras = {},
    ringDisplay = {
        baseRadius = 60,
        ringThickness = 6,
        ringSpacing = 4,
        numSegments = 72,
        offsetX = 0,
        offsetY = 0,
        updateInterval = 0.05,
        opacity = 0.8,
        visibility = "always",
        enabled = true,
    },
    -- Cooldown pulse (estilo CDPulse): icono central al pasar a READY
    cooldownPulse = {
        enabled = true,
        visibility = "always",
        iconSize = 80,
        offsetX = 0,
        offsetY = 120,
        opacity = 1.0,
        holdDuration = 0.55,
    },
    -- Listas independientes para Pulse (separadas de cursor). Cada entry:
    --   spellID, enabled, soundEnabled, soundName  (auras: + unit, filter)
    pulseSpells = {},
    pulseAuras = {},
    -- MRT Timeline Reminders: lee VMRT.Note.Text1 y muestra iconos de hechizos
    -- cerca del cursor cuando se acerca el tiempo configurado en la nota.
    mrtTimeline = {
        enabled = true,
        iconSize = 40,
        offsetX = 0,
        offsetY = 60,
        leadTime = 3,        -- segundos antes del trigger time -> icono dimmed + countdown
        activeWindow = 10,   -- segundos que el icono queda "activo" tras el trigger antes
                             -- de auto-hide (o hasta que el player castee el spell).
        notes = {},          -- lista de notas por-encuentro: {{id=N, name=str, text=str}, ...}
                             -- id=0 = aplica a cualquier encuentro (fallback default).
        -- Integraciones con otros modulos de visualizacion. Cada uno se activa
        -- desde el Config page del modulo correspondiente. Cursor on por default
        -- (es el comportamiento original); ring/pulse off por default.
        showInCursor = true,
        showInRing = false,
        showInPulse = false,
        ringIconSize = 36,   -- diametro del icono spell en el centro del ring overlay
        -- Sonido cuando la entry pasa a ACTIVE phase (trigger time alcanzado).
        soundEnabled = false,
        soundName = "Default",
        soundChannel = "Master",
        -- TTS / Audio announce: dice el nombre del hechizo X segundos antes del
        -- trigger. Cadena de fallback en MrtTimeline.lua:
        --   1) WAV pre-grabado en Sounds/Spells/<lang>/<spellID>.wav
        --   2) C_VoiceChat.SpeakText (mudo si Vivox no inicia)
        ttsEnabled = false,
        ttsLeadTime = 1,     -- segundos antes del trigger en los que se anuncia
        ttsLanguage = "auto",-- "auto" (segun GetLocale), "esES", o "enUS"
        ttsVoiceID = 0,      -- voice del SO para fallback TTS; 0 = primer disponible
        ttsRate = 0,         -- -10..10 (0 = normal); solo aplica a TTS
        ttsVolume = 100,     -- 0..100; solo aplica a TTS
    },
    -- Ready Check preparation panel: cuando alguien dispara un /readycheck, el
    -- addon muestra un panel flotante con un checklist visual del estado del
    -- player (food, flask, runa, HP/mana lleno). Auto-hide en READY_CHECK_FINISHED.
    -- Cada `check*` es un toggle on/off para que el usuario apague items que no
    -- aplican a su clase (p.ej. checkResourceFull para specs sin mana). Pensado
    -- para healers pero util para cualquier rol.
    readyCheckPanel = {
        enabled = true,
        visibility = "always",       -- "always" | "combat" | "ooc"
        -- Posicion: si positionUserSet=false anclamos a TOP del UIParent con
        -- offsetY default (-40). Si el user dragea el panel o el anchor, se
        -- pasa a "custom" (positionUserSet=true) y usamos offsetX/offsetY
        -- desde el CENTER del UIParent, como antes. Existing users sin el
        -- field (nil) caen al default top-center — comportamiento intencional.
        positionUserSet = false,
        offsetX = 0,
        offsetY = 200,               -- usado solo cuando positionUserSet=true
        width = 420,                 -- mas ancho para acomodar sub-rows de items con nombre + count + bumped 2026-05-25 para que el texto del talent loadout "unassigned" no se corte
        rowHeight = 22,
        subRowHeight = 18,           -- alto de los sub-rows que listan items en bag
        opacity = 0.95,
        fontScale = 1.0,             -- escala global de texto del panel; user-controlled via slider
        -- Items del checklist. Toggles independientes asi el usuario apaga lo
        -- que no le aplica (p.ej. mana para una spec sin mana). El orden de
        -- evaluacion esta hardcoded en ReadyCheckPanel.lua (no es configurable
        -- en v1; agregar editor de orden seria v2).
        infoTalents = true,          -- info row: spec activa + loadout de talentos
        checkWellFed = true,
        checkFlask = true,           -- matchea "Phial of" o "Flask of"
        checkAugmentRune = true,     -- matchea aura cuyo nombre contiene "Augment Rune"
        checkResourceFull = true,    -- row "Revisa tu mana" + comidas; clases sin mana se omiten
        checkClassBuffs = true,      -- raid buffs party-aware (Arcane Intellect, Skyfury, etc)
        checkClassImbue = true,      -- weapon imbue self-cast (Shaman/Rogue spec spell)
        checkHealthstone = true,     -- row con piedra del brujo + cantidad; solo si hay warlock en grupo
        checkTalentLoadout = true,   -- row "Loadout: X" dentro de instancia; advierte si activo != configurado
        -- Master toggles per categoria (tabs). Si una categoria esta off, el
        -- tab correspondiente sale en plomo en Config y los checks de esa
        -- categoria se skipean en el panel runtime (incluso aunque los toggles
        -- individuales esten on).
        categoriesEnabled = {
            items = true,
            talents = true,
        },
        -- Click-to-use: cuando un check falla y hay un item del kind en bags,
        -- el row se vuelve clickeable y usa el item directamente (SecureActionButton
        -- "/use item:ID"). Lista per-kind con itemIDs custom (prepended a los
        -- defaults). Sin custom items y sin defaults, el row se muestra rojo
        -- pero no es clickeable. Kinds: wellFed, flask, augmentRune, recoveryHP,
        -- recoveryMana.
        actionItems = {
            wellFed = {},
            flask = {},
            augmentRune = {},
            recoveryHP = {},
            recoveryMana = {},
            healthstone = {},
            weaponImbue = {},
        },
        -- talentLoadouts[tostring(configID)] = "Manaforge, Theatre of Pain"
        -- CSV de nombres de instancia (case-insensitive substring match) donde
        -- ese loadout deberia estar activo. Si el nombre actual matchea un
        -- loadout y el activo es distinto, el panel ofrece switch.
        talentLoadouts = {},
    },
    -- Vendor Restock: cuando el player abre un vendor (MERCHANT_SHOW), aparece
    -- un boton flotante "Restock" que compra los items configurados hasta
    -- alcanzar el target de bag count por entry. La lista es 100% user-curated
    -- (drag desde bag/inventario o search por nombre/id/link). Cada entry
    -- guarda lastPaid + lastPaidAt para que el tooltip muestre si el precio
    -- subio o bajo respecto a la ultima compra.
    -- Auto-hide al cerrar el vendor (MERCHANT_CLOSED).
    vendorRestock = {
        enabled = true,
        -- Posicion movable del boton (anclado a UIParent CENTER + offsets).
        -- Drag con LeftButton para moverlo; persistido aqui. No hay UI de
        -- sliders — la posicion se setea solo arrastrando el boton.
        offsetX = 0,
        offsetY = -80,
        -- Posicion del panel "Shopping list" (UIParent CENTER + offsets). Default
        -- 0,40 cuando ambos son nil; el user los setea arrastrando el panel.
        panelOffsetX = nil,
        panelOffsetY = nil,
        -- Lista de items que el user quiere stockpilear. Cada entry:
        --   itemID       — el item
        --   target       — cantidad deseada en bag (default 1)
        --   maxPrice     — precio max por unidad en copper (0 = sin tope)
        --   confirmAbove — copper; si totalPrice del purchase supera N, se
        --                  muestra popup de confirmacion. 0 = auto-confirm.
        --                  Default 100g (1000000 copper).
        --   enabled      — toggle por entry (default true)
        --   lastPaid     — copper pagado por unidad la ultima vez
        --   lastPaidAt   — time() del ultimo pago
        items = {},
        -- Umbral global de confirmacion (copper). Red de seguridad por encima
        -- del threshold per-item: si totalPrice supera este monto, se muestra
        -- popup aunque el entry.confirmAbove no lo dispare. 0 = desactivado.
        -- Default 1000g — pensado para frenar compras anomalas grandes (item
        -- caro inesperadamente, spike de precio) sin molestar en compras chicas.
        confirmAbove = 10000000,
        -- Cuando true, imprime al chat todos los eventos del sistema de throttle
        -- del AH y los COMMODITY_* (search/price). Off por default — son muy
        -- ruidosos. Toggle con:
        --   /run HNZHealingToolsDB.profile.vendorRestock.debug = true
        debug = false,
    },
    -- RaidHealerComms: broadcast/receive de spells importantes lanzadas por
    -- healers en el grupo. Panel separado, posicion arrastrable.
    raidHealerComms = {
        enabled = true,
        offsetX = 200,
        offsetY = 200,
        -- Cuando true, el panel se oculta si no hay casts recientes (5s).
        -- false = siempre visible (con "Esperando casts..." al inicio).
        hideWhenEmpty = false,
        -- Por default solo healers ven el panel — un tank/DPS no necesita
        -- monitorear casts de healers ajenos. El broadcast sigue funcionando
        -- para todos (cualquier healer que tenga el addon emite); este toggle
        -- solo controla el RENDER del panel local.
        showOnlyForHealers = true,
        -- Por default panel solo en raids. Un party de 5 (M+/dungeon/ciudad)
        -- no necesita panel multi-healer. Toggle off para verlo en cualquier
        -- grupo (util si sos healer en M+ con la party pre-armada en ciudad).
        showOnlyInRaid = true,
        -- spells = nil hace que el modulo use DEFAULT_TRACKED_SPELLS (curado
        -- por spec). Cuando agreguemos UI para custom list, se llenara aqui.
        spells = nil,
    },
    -- SimulatedAuras: estado sintetico para auras que la API restringe. Cada
    -- entry: { spellID, label, initialStacks, duration }. El cast del spell
    -- (detectado via UNIT_SPELLCAST_SUCCEEDED) aplica los stacks; casts
    -- subsecuentes consumen 1. Tambien se puede disparar manual via /hnzsim.
    -- Una vez registrado, el spellID se puede agregar a Cursor/Ring/Pulse
    -- como cualquier otra aura — AuraMonitor consulta el state simulado.
    simulatedAuras = {
        enabled = true,
        entries = {},
    },
    -- Cursor ring: anillo decorativo siguiendo al raton (estilo CursorRing)
    cursorRing = {
        enabled = true,
        size = 48,
        opacity = 0.8,
        offsetX = 0,
        offsetY = 0,
        visibility = "always",
        useClassColor = false,
        color = { r = 1, g = 0.82, b = 0.20, a = 1 },
        texture = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring",
        -- Cast progress sub-ring: 180 cuñas rotadas que se iluminan según el avance del cast
        cast = {
            enabled = false,
            visibility = "always",
            color = { r = 0.20, g = 0.82, b = 0.68, a = 1 },  -- teal/mint
            size = 48,        -- diametro absoluto en px (independiente del ring base)
            opacity = 1.0,
            direction = "right",  -- "right" = horario (default), "left" = antihorario
        },
        -- Punto central sobre el cursor (opcional)
        dot = {
            enabled = false,
            visibility = "always",        -- gate del dot mismo
            size = 6,
            color = { r = 1, g = 1, b = 1, a = 1 },
            -- Grow on movement: pulsar el dot cuando el cursor se mueve.
            growOnMovement = false,
            growScale = 2.5,
            growVisibility = "always",
            -- FX: trail (rastro fade-out detras del cursor en movimiento) y
            -- sparkle (destellos pequeños alrededor del cursor). Off por
            -- default, ambos pueden activarse independientes uno del otro.
            -- Cada efecto tiene su propio color, tunable y combat-gate; no
            -- heredan del dot.
            trail = false,
            trailColor = { r = 1, g = 1, b = 1, a = 1 },
            trailLength = 0.45,           -- segundos de fade (lifetime del trail)
            trailVisibility = "always",
            sparkle = false,
            sparkleColor = { r = 1, g = 1, b = 1, a = 1 },
            sparkleSize = 1.0,            -- multiplicador del tamaño del destello
            sparkleShape = "dot",         -- ver SPARKLE_SHAPE_TEXTURES en CursorRing.lua
            sparkleVisibility = "always",
        },
    },
}

-- Dirty flags por-consumidor. Los modulos consumidores (CursorDisplay,
-- RingDisplay, etc.) los chequean en su OnUpdate para decidir si vale la pena
-- llamar GetSpellStatus/GetAuraStatus (caros: ~7 API calls por hechizo). Sin
-- per-consumer split el primero en correr en el frame "se robaba" el dirty del
-- otro. Las funciones MarkAuraDirty / MarkSpellDirty se llaman desde el codigo
-- que detecta cambios (events de aura/cooldown, edits de config).
function ns:MarkAuraDirty()
    ns._auraDirtyCursor = true
    ns._auraDirtyRing = true
    ns._auraDirtyPulse = true
end
function ns:MarkSpellDirty()
    ns._spellDirtyCursor = true
    ns._spellDirtyPulse = true
end
-- Estado inicial: todo dirty para forzar primer UpdateData/UpdateRings tras login.
ns._auraDirtyCursor = true
ns._auraDirtyRing = true
ns._auraDirtyPulse = true
ns._spellDirtyCursor = true
ns._spellDirtyPulse = true

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local function GetCharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "Unknown"
    return name .. " - " .. realm
end
ns.GetCharacterKey = GetCharacterKey

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not HNZHealingToolsDB then
            HNZHealingToolsDB = { profiles = { Default = ns.DeepCopy(ns.PROFILE_DEFAULTS) } }
        end
        if not HNZHealingToolsDB.profiles then HNZHealingToolsDB.profiles = {} end
        if not HNZHealingToolsCharDB then HNZHealingToolsCharDB = {} end
        -- Settings cuenta-globales (no van por perfil): idioma override, etc.
        if not HNZHealingToolsDB.general then HNZHealingToolsDB.general = {} end
        -- Aplicar locale ahora que SavedVariables estan disponibles. Locales.lua
        -- corrio antes que los archivos por-idioma, asi que el primer apply en
        -- carga era prematuro: aqui la tabla LocaleTables ya esta poblada.
        if ns.ApplyLocale then ns.ApplyLocale() end
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        local charKey = GetCharacterKey()

        -- Helper: cuando un char no tiene perfil propio, copiar del mejor source
        -- disponible en vez de crear defaults frescos. Asi alts nuevos heredan
        -- una config existente y no llegan en blanco. Orden de preferencia:
        --   1) profile referenciado por la legacy account-wide activeProfile
        --   2) cualquier perfil existente (orden alfabetico)
        --   3) defaults de fabrica
        local function SeedProfile(targetName)
            if HNZHealingToolsDB.profiles[targetName] then return end
            local source
            local legacy = HNZHealingToolsDB.activeProfile
            if legacy and HNZHealingToolsDB.profiles[legacy] then
                source = legacy
            else
                for n in pairs(HNZHealingToolsDB.profiles) do
                    if not source or n < source then source = n end
                end
            end
            if source then
                HNZHealingToolsDB.profiles[targetName] = ns.DeepCopy(HNZHealingToolsDB.profiles[source])
            else
                HNZHealingToolsDB.profiles[targetName] = ns.DeepCopy(ns.PROFILE_DEFAULTS)
            end
        end

        -- First time this character loads with per-char support: bootstrap its profile
        if not HNZHealingToolsCharDB.activeProfile then
            SeedProfile(charKey)
            HNZHealingToolsCharDB.activeProfile = charKey
        end

        -- Drop legacy account-wide activeProfile so it can't override per-char selection
        HNZHealingToolsDB.activeProfile = nil

        -- Guard against the character's profile being deleted: en vez de crear
        -- defaults frescos, intentamos recuperar copiando de cualquier perfil
        -- existente. El usuario que pierde la referencia no pierde tambien la
        -- configuracion compartida con otros chars.
        local active = HNZHealingToolsCharDB.activeProfile
        if not HNZHealingToolsDB.profiles[active] then
            SeedProfile(charKey)
            active = charKey
            HNZHealingToolsCharDB.activeProfile = active
        end

        ns.globalDB = HNZHealingToolsDB
        ns.charDB = HNZHealingToolsCharDB
        ns.db = HNZHealingToolsDB.profiles[active]

        -- Migrar TODOS los perfiles (no solo el activo) y aplicar defaults a
        -- cada uno. Asi al hacer SwitchProfile mid-session el perfil destino
        -- ya esta al dia y no necesita migracion (que de fallar dejaria al
        -- usuario sin sus settings sin posibilidad de revertir hasta /reload).
        for pname, prof in pairs(HNZHealingToolsDB.profiles) do
            ns.MigrateProfile(prof, pname)
            ns.MergeDefaults(prof, ns.PROFILE_DEFAULTS)
        end

        ns:InitCursorDisplay()
        ns:InitRingDisplay()
        ns:InitSpellMonitor()
        ns:InitAuraMonitor()
        ns:InitCooldownPulse()
        ns:InitCursorRing()
        ns:InitMrtTimeline()
        ns:InitReadyCheckPanel()
        ns:InitVendorRestock()
        ns:InitRaidHealerComms()
        ns:InitSimulatedAuras()
        ns:InitConfig()
        ns:InitMinimapButton()
        ns:InitPublicAPI()
        print(string.format("|cff00ccffHNZ Healing Tools|r %s. %s |cff00ff00%s|r. %s |cff00ff00/hht|r %s.",
            ns.L["loaded"], ns.L["Profile:"], active, ns.L["Type"], ns.L["for options"]))
        -- Defer al final del flujo de login para que el popup salga despues del
        -- mensaje de "loaded", y solo una vez todos los modulos esten listos.
        if ns.ShowWhatsNewIfNeeded then
            C_Timer.After(1.5, function() ns:ShowWhatsNewIfNeeded() end)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

function ns:GetNextRingColor()
    local index = (#ns.db.ringAuras % #DEFAULT_COLORS) + 1
    local c = DEFAULT_COLORS[index]
    return {r=c.r, g=c.g, b=c.b, a=c.a}
end

function ns:GetActiveProfile()
    return ns.charDB and ns.charDB.activeProfile
end

function ns:SwitchProfile(name)
    if not ns.globalDB.profiles[name] then return end
    ns.charDB.activeProfile = name
    ns.db = ns.globalDB.profiles[name]
    -- No migracion aqui: PLAYER_LOGIN ya migro todos los perfiles. MergeDefaults
    -- es idempotente, lo dejamos como cinturon-y-tirantes.
    ns.MergeDefaults(ns.db, ns.PROFILE_DEFAULTS)
    ns:RebuildRingDisplay()
    ns:RefreshRingDisplay()
    ns:RefreshCursorDisplay()
    if ns.RefreshCooldownPulse then ns:RefreshCooldownPulse() end
    if ns.ResetCooldownPulseCache then ns:ResetCooldownPulseCache() end
    if ns.RefreshCursorRing then ns:RefreshCursorRing() end
    ns:MarkSpellDirty()
    ns:MarkAuraDirty()
end

function ns:CreateProfile(name)
    if ns.globalDB.profiles[name] then return false end
    ns.globalDB.profiles[name] = ns.DeepCopy(ns.PROFILE_DEFAULTS)
    return true
end

function ns:DeleteProfile(name)
    if name == ns.charDB.activeProfile then return false end
    if not ns.globalDB.profiles[name] then return false end
    ns.globalDB.profiles[name] = nil
    return true
end

function ns:CopyProfile(from, to)
    if not ns.globalDB.profiles[from] then return false end
    ns.globalDB.profiles[to] = ns.DeepCopy(ns.globalDB.profiles[from])
    return true
end

function ns:GetProfileList()
    local list = {}
    for name in pairs(ns.globalDB.profiles) do table.insert(list, name) end
    table.sort(list)
    return list
end

function ns:ExportProfile(name)
    local profile = ns.globalDB.profiles[name or ns.charDB.activeProfile]
    if not profile then return nil end
    return ns.Serialize(profile)
end

function ns:ImportProfile(name, dataStr)
    local data = ns.Deserialize(dataStr)
    if not data then return false, "Invalid data format." end
    -- Asignamos primero asi MigrateProfile puede crear el backup keyed por name
    -- (el backup-store vive en HNZHealingToolsDB.profileBackups[name]).
    ns.globalDB.profiles[name] = data
    ns.MigrateProfile(data, name)
    ns.MergeDefaults(data, ns.PROFILE_DEFAULTS)
    return true
end

-- ============================================================
-- Public API: _G.HNZHealingTools
-- ============================================================
-- Namespace expuesto para que macros / otros addons interactuen con el addon
-- sin tener que tocar el namespace privado `ns`. Mantenelo MINIMO y estable —
-- agregar metodos es libre, sacarlos rompe consumidores externos.
function ns:InitPublicAPI()
    local api = {}
    api.version = ns.VERSION

    -- Trigger(key): dispara todas las entries cursorAura/ringAura cuyo
    -- entry.triggerKey coincida (case-insensitive). Para usar en macros:
    --   /run HNZHealingTools.Trigger("ohshit")
    -- o equivalentemente /hht trigger ohshit.
    -- Devuelve la cantidad de entries que matchearon (0 = ninguna).
    function api.Trigger(key)
        return ns:FireExternalTrigger(key)
    end

    _G.HNZHealingTools = api
end
