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

local CURRENT_SCHEMA_VERSION = 3

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
        enabled = false,
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
    },
    -- Cursor ring: anillo decorativo siguiendo al raton (estilo CursorRing)
    cursorRing = {
        enabled = false,
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
        ns:InitConfig()
        ns:InitMinimapButton()
        print(string.format("|cff00ccffHNZ Healing Tools|r %s. %s |cff00ff00%s|r. %s |cff00ff00/hht|r %s.",
            ns.L["loaded"], ns.L["Profile:"], active, ns.L["Type"], ns.L["for options"]))
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
