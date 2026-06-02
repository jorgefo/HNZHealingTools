local _, ns = ...

-- RaidHealerComms: cada healer broadcasts spells importantes via addon messages
-- (prefix HNZHC) al canal del grupo. Otros clientes que corren el addon
-- muestran un panel con una fila por healer + iconos de sus ultimos 5s de
-- casts. Pensado para coordinar cooldowns entre healers sin tener que mirar
-- bars o pedir por voice.
--
-- Decisiones de diseño:
-- - Solo broadcast si la spec actual es healer (evita spam de OS healers).
-- - Solo broadcast spells de TRACKED_SPELLS (cooldowns relevantes — no Flash
--   Heal ni Rejuvenation, seria ruido inmanejable).
-- - 5s rolling window; entries viejas se podan en un ticker de 0.5s.
-- - No persisto historial — solo memoria en sesion.
-- - Visible solo en grupo/raid. Oculto en solo.
-- - Channel: RAID si en raid, PARTY si en party, nada si solo. Las addon msgs
--   en INSTANCE_CHAT son redundantes con RAID/PARTY dentro de instancias.

local CreateFrame = CreateFrame
local UIParent = UIParent
local C_ChatInfo = C_ChatInfo
local C_Timer = C_Timer
local GameTooltip = GameTooltip
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local UnitName = UnitName
local UnitClass = UnitClass
local GetTime = GetTime
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local PREFIX = "HNZHC"
-- Cap maximo de edad de un cast antes de podarlo del historial. 10 min cubre
-- bien casts entre wipes/pulls sin acumular ruido eterno.
local MAX_CAST_AGE = 600
local PRUNE_INTERVAL = 0.5
local MAX_ICONS_PER_ROW = 6
-- Discovery / presence:
--   - Cada healer con el addon broadcasta H:hello al unirse + cada
--     HEARTBEAT_INTERVAL segundos. El receiver guarda el sender en
--     _addonHealers para mostrarlo en el panel aunque no haya casteado nada.
--   - Si pasan STALE_HEALER_TIMEOUT segundos sin recibir nada del healer,
--     se lo evicta (probablemente respeco a DPS, dropeo el addon, o left raid).
--   - Cuando recibimos hello/cast de alguien NUEVO, le respondemos con
--     nuestro hello asi nos descubre tambien (handshake bidireccional).
local HEARTBEAT_INTERVAL = 60
local STALE_HEALER_TIMEOUT = 180

-- Specs healer (retail 11.x):
--   65 Holy Paladin, 105 Resto Druid, 256 Disc Priest, 257 Holy Priest,
--   264 Resto Shaman, 270 Mistweaver Monk, 1468 Pres Evoker.
local HEALER_SPECS = {
    [65] = true, [105] = true, [256] = true, [257] = true,
    [264] = true, [270] = true, [1468] = true,
}

-- Spells por defecto a broadcast. Cooldowns relevantes — no spammeamos heals
-- basicos (Flash Heal, Rejuvenation, Holy Light) porque seria ruido. Solo
-- raid CDs, externals y emergency tools.
--
-- Curado para retail Midnight 12.0 con CDs que vienen estables desde DF/TWW
-- (no hardcodeamos spellIDs nuevos de Hero Talents 12.0 que pueden mover
-- entre patches — TODO agregar despues de verificar cada uno via /run).
-- Estructura plana spellID -> true; lookup O(1) en el hot path del broadcast.
-- Editable via ns.db.raidHealerComms.spells (futuro: UI para custom list).
--
-- Para confirmar un spellID en juego: /run print(GetSpellLink(SPELLID))
local DEFAULT_TRACKED_SPELLS = {
    -- ===== Holy Paladin =====
    [31884]  = true,  -- Avenging Wrath
    [31821]  = true,  -- Aura Mastery
    [633]    = true,  -- Lay on Hands (emergency externo)
    [1022]   = true,  -- Blessing of Protection
    [6940]   = true,  -- Blessing of Sacrifice
    [498]    = true,  -- Divine Protection (self)
    [375576] = true,  -- Divine Toll (talent core, estable desde SL)

    -- ===== Restoration Druid =====
    [740]    = true,  -- Tranquility
    [197721] = true,  -- Flourish
    [391528] = true,  -- Convoke the Spirits
    [33891]  = true,  -- Incarnation: Tree of Life
    [102342] = true,  -- Ironbark (externo)
    [29166]  = true,  -- Innervate (utility mana cooldown)

    -- ===== Discipline Priest =====
    [62618]  = true,  -- Power Word: Barrier
    [33206]  = true,  -- Pain Suppression (externo)
    [246287] = true,  -- Evangelism (reworked en Midnight: no extiende Atonements,
                      --             ahora aplica 5 + instantizes next 2 Radiance)
    [447444] = true,  -- Entropic Rift (Voidweaver Hero Talent, ~1min CD —
                      -- mezcla DPS/heal via Atonement; util para Disc, ruido
                      -- para Holy. Considerar mover a opcional si se queja)
    -- Removidos en Midnight 12.0: Rapture (47536), Symbol of Hope (64901).

    -- ===== Holy Priest =====
    [64843]  = true,  -- Divine Hymn
    [265202] = true,  -- Holy Word: Salvation
    [200183] = true,  -- Apotheosis
    [47788]  = true,  -- Guardian Spirit (externo)
    -- Symbol of Hope removido en Midnight 12.0 (ver Disc arriba).

    -- ===== Restoration Shaman =====
    [108280] = true,  -- Healing Tide Totem
    [98008]  = true,  -- Spirit Link Totem
    [114052] = true,  -- Ascendance
    [444995] = true,  -- Surging Totem (Totemic Hero Talent, ~2min CD —
                      -- heal+damage totem, broadcast-worthy)
    -- Removidos: Mana Tide Totem (16191) en Midnight 12.0,
    --            Ancestral Guidance (108281) en 11.1.0.

    -- ===== Mistweaver Monk =====
    [115310] = true,  -- Revival
    [322118] = true,  -- Invoke Yu'lon, the Jade Serpent
    [388615] = true,  -- Restoral (talent — Revival reskin)
    [205406] = true,  -- Sheilun's Gift (era 388193 que es Jadefire Stomp, bug)
    [116849] = true,  -- Life Cocoon (externo)
    [443028] = true,  -- Celestial Conduit (Conduit of the Celestials Hero
                      -- Talent, ~90s CD — big healing burst, broadcast-worthy)

    -- ===== Preservation Evoker =====
    [363534] = true,  -- Rewind
    [370960] = true,  -- Emerald Communion
    [367226] = true,  -- Spiritbloom
    [359816] = true,  -- Dream Flight
    [357170] = true,  -- Time Dilation (externo)

    -- Hero Talents Midnight 12.0 — auditados 2026-05-22. Solo los que añaden
    -- un *active* CD broadcast-worthy quedaron incluidos (arriba, en su spec):
    --   - Voidweaver Priest: Entropic Rift (447444)
    --   - Totemic Shaman: Surging Totem (444995)
    --   - Conduit of the Celestials MW: Celestial Conduit (443028)
    -- El resto de Hero Talents solo aporta passives/procs, no actives con CD:
    -- Archon (Halo enhance + Resonant Energy), Wildstalker (Implant + Bloodseeker
    -- Vines), Keeper of the Grove (Treants of the Moon), Lightsmith (Holy Bulwark
    -- + Sacred Weapon procs), Herald of the Sun (Dawnlight + Aurora procs),
    -- Stormbringer (Tempest procs), Master of Harmony (Aspect of Harmony passive),
    -- Chronowarden (Temporal Burst proc). Si alguno gana un active en futuros
    -- patches, agregar acá con el spellID confirmado via C_Spell.GetSpellLink.
}
ns.RAID_HEALER_COMMS_DEFAULT_SPELLS = DEFAULT_TRACKED_SPELLS

local _isHealerSpec = false
local _recentCasts = {}  -- name -> { {spellID=N, at=time}, ... } most recent first
local _classByName = {}  -- name -> class token para color (legacy; ahora vive en _addonHealers)
-- _addonHealers[name] = { class = "DRUID", lastPing = GetTime() }
-- Tabla de healers conocidos por tener el addon habilitado. Se popula con
-- cualquier mensaje recibido (hello O cast) y se prunea por inactividad.
local _addonHealers = {}
-- Timestamp del ultimo hello que mandamos. Usado para gatear el heartbeat
-- a HEARTBEAT_INTERVAL (sin esto mandariamos cada PRUNE_INTERVAL tick).
local _lastHelloSent = 0
-- _testMode: true cuando el user clickea Test desde Config (preview solo).
-- Bypasses el group-check de ShouldShow y skipea el pruning para que los casts
-- fake queden visibles indefinidamente. Hide test los limpia.
local _testMode = false

local panel
local pruneTicker

-- Forward decl: Broadcast usa RecordCast (definida mas abajo). Declarar local
-- aca evita que la asignacion futura cree un global por accidente.
local RecordCast
local SendHello

-- Channel resolution: en instancias usamos INSTANCE_CHAT (necesario para
-- LFR y cross-realm — RAID/PARTY no rutean bien entre realms). Fuera de
-- instancias usamos RAID/PARTY estandar.
local function ResolveChannel()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "raid" or instanceType == "party" or instanceType == "pvp") then
        return "INSTANCE_CHAT"
    end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

local function UpdateHealerSpec()
    local spec = GetSpecialization and GetSpecialization()
    if not spec then _isHealerSpec = false; return end
    local id = GetSpecializationInfo and GetSpecializationInfo(spec)
    _isHealerSpec = HEALER_SPECS[id] == true
end

local function ShouldShow()
    if _testMode then return true end
    local s = ns.db and ns.db.raidHealerComms
    if not s or s.enabled == false then return false end
    -- Gate por contexto de instancia. `IsInRaid()` devuelve true por estar en
    -- grupo de banda incluso en mundo abierto (eventos, world bosses), por eso
    -- chequeamos `IsInInstance()` y el tipo. Default: solo banda. Toggle off
    -- amplia a cualquier instancia grupal (dungeon/M+/arena).
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return false end
    if s.showOnlyInRaid ~= false then
        if instanceType ~= "raid" then return false end
    else
        if instanceType ~= "raid" and instanceType ~= "party" and instanceType ~= "pvp" then
            return false
        end
    end
    -- Por default solo mostramos panel si la spec activa es healer. El toggle
    -- showOnlyForHealers permite forzar visible (raid leader healer que respeca
    -- a DPS pero quiere seguir viendo el panel, p.ej.).
    if s.showOnlyForHealers ~= false and not _isHealerSpec then return false end
    return true
end

local function GetTrackedSpells()
    local s = ns.db and ns.db.raidHealerComms
    return (s and s.spells) or DEFAULT_TRACKED_SPELLS
end

-- Lazy-init de la lista custom. Mientras `spells` es nil, GetTrackedSpells
-- devuelve DEFAULT_TRACKED_SPELLS (el set base curado). En el momento que el
-- user agrega/remueve algo, copiamos los defaults a una tabla mutable en el
-- profile para que el set base no se pierda con el primer remove. ResetSpells
-- vuelve a poner nil para reactivar el fallback (asi el user recupera
-- automaticamente cualquier spell que agreguemos en futuros patches).
local function GetOrCreateCustomSpells()
    local s = ns.db and ns.db.raidHealerComms
    if not s then return nil end
    if not s.spells then
        s.spells = {}
        for sid, v in pairs(DEFAULT_TRACKED_SPELLS) do s.spells[sid] = v end
    end
    return s.spells
end

-- API publica para la Config UI. Devuelven:
--   Add: ok, spellID|errMsg, name (cuando ok=true se entrega spellID y name;
--        cuando ok=false el segundo retorno es el msg de error localizado)
--   Remove: ok
--   Reset: nada
function ns:AddRaidHealerCommsSpell(input)
    if input == nil or input == "" then
        return false, (ns.L and ns.L["Enter a spell ID or name."]) or "Enter a spell ID or name."
    end
    local spellID, name
    if ns.GetSpellIDFromInput then
        spellID, name = ns.GetSpellIDFromInput(input)
    else
        spellID = tonumber(input)
    end
    if not spellID then
        return false, (ns.L and ns.L["Unknown spell — check the ID or name."]) or "Unknown spell — check the ID or name."
    end
    local list = GetOrCreateCustomSpells()
    if not list then return false, "db not ready" end
    if list[spellID] then
        return false, (ns.L and ns.L["Spell already tracked."]) or "Spell already tracked."
    end
    list[spellID] = true
    if ns.RefreshRaidHealerCommsPanel then ns:RefreshRaidHealerCommsPanel() end
    return true, spellID, name
end

function ns:RemoveRaidHealerCommsSpell(spellID)
    if not spellID then return false end
    local list = GetOrCreateCustomSpells()
    if not list then return false end
    list[spellID] = nil
    if ns.RefreshRaidHealerCommsPanel then ns:RefreshRaidHealerCommsPanel() end
    return true
end

function ns:ResetRaidHealerCommsSpells()
    local s = ns.db and ns.db.raidHealerComms
    if not s then return end
    s.spells = nil
    if ns.RefreshRaidHealerCommsPanel then ns:RefreshRaidHealerCommsPanel() end
end

-- Devuelve la tabla efectiva (custom o defaults). Wrapper publico del local
-- GetTrackedSpells — la Config UI lo usa para renderizar la lista actual.
function ns:GetRaidHealerCommsTrackedSpells()
    return GetTrackedSpells()
end

-- Payload formats:
--   "C:<spellID>"  cast broadcast (sender lanzo spell)
--   "H:1"          hello / heartbeat (sender tiene el addon, version 1)
local function EncodeCast(spellID)
    return "C:" .. tostring(spellID)
end

local function EncodeHello()
    return "H:1"
end

-- Devuelve { kind = "C"|"H", spellID = N or nil }, o nil si malformado.
local function Decode(msg)
    if not msg then return nil end
    local kind, body = msg:match("^([^:]+):(.+)$")
    if not kind then return nil end
    if kind == "C" then
        local sid = tonumber(body)
        return sid and { kind = "C", spellID = sid } or nil
    end
    if kind == "H" then return { kind = "H" } end
    return nil
end

local function StripRealm(name)
    if not name then return "?" end
    local short = name:match("^([^-]+)")
    return short or name
end

-- Marca al healer como vivo en _addonHealers (capta class para color en el
-- panel + lastPing para el pruning de stale). Devuelve true si era un nombre
-- nuevo (el caller responde con su propio hello para handshake bidireccional).
local function MarkHealerAlive(senderFull)
    if not senderFull then return false end
    local name = StripRealm(senderFull)
    local existed = _addonHealers[name] ~= nil
    if not existed then
        _addonHealers[name] = {}
    end
    _addonHealers[name].lastPing = GetTime()
    if not _addonHealers[name].class then
        local _, cls = UnitClass(name)
        if cls then _addonHealers[name].class = cls end
    end
    -- Mantenemos _classByName por compat con codigo viejo que aun lo lee.
    if not _classByName[name] and _addonHealers[name].class then
        _classByName[name] = _addonHealers[name].class
    end
    return not existed
end

-- Definicion (forward-declared como local arriba).
SendHello = function()
    if not _isHealerSpec then return end
    local s = ns.db and ns.db.raidHealerComms
    if not s or s.enabled == false then return end
    local channel = ResolveChannel()
    if not channel then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        pcall(C_ChatInfo.SendAddonMessage, PREFIX, EncodeHello(), channel)
    end
    _lastHelloSent = GetTime()
end

-- Umbral de cooldown: solo se muestran/transmiten hechizos con CD base > 30s.
-- GetSpellBaseCooldown devuelve el CD base en ms (sin reducciones de talento), lo
-- que da un criterio consistente entre jugadores. Fail-open: si no se puede
-- determinar el CD, dejamos pasar el hechizo para no romper el tracking.
local CAST_MIN_COOLDOWN_MS = 30000
local function MeetsCooldownThreshold(spellID)
    if not spellID then return false end
    local baseMS
    if type(GetSpellBaseCooldown) == "function" then
        local ok, ms = pcall(GetSpellBaseCooldown, spellID)
        if ok and type(ms) == "number" then baseMS = ms end
    end
    if baseMS == nil then return true end -- CD desconocido → fail-open (mostrar)
    return baseMS > CAST_MIN_COOLDOWN_MS
end

local function Broadcast(spellID)
    if not _isHealerSpec then return end
    local s = ns.db and ns.db.raidHealerComms
    if not s or s.enabled == false then return end
    local channel = ResolveChannel()
    if not channel then return end
    if not GetTrackedSpells()[spellID] then return end
    -- Solo cooldowns "grandes": ignoramos hechizos con CD base <= 30s.
    if not MeetsCooldownThreshold(spellID) then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        pcall(C_ChatInfo.SendAddonMessage, PREFIX, EncodeCast(spellID), channel)
    end
    -- Tambien lo registramos local: el sender no recibe su propio CHAT_MSG_ADDON
    -- en algunos clientes y queremos verlo en nuestro propio panel.
    local me = UnitName and UnitName("player")
    if me then
        MarkHealerAlive(me)
        RecordCast(me, spellID)
    end
end

-- Definicion (forward-declared como local arriba).
RecordCast = function(senderFull, spellID)
    if not senderFull or not spellID then return end
    -- Filtro de visibilidad: solo registramos hechizos con CD base > 30s. Cubre
    -- casts recibidos de otros clientes (incluso versiones viejas sin el filtro).
    if not MeetsCooldownThreshold(spellID) then return end
    local name = StripRealm(senderFull)
    local list = _recentCasts[name]
    if not list then list = {}; _recentCasts[name] = list end
    table.insert(list, 1, { spellID = spellID, at = GetTime() })
    -- Cap a 16 entries — el panel solo muestra MAX_ICONS_PER_ROW pero
    -- mantenemos buffer por si la ventana se aumenta a futuro.
    while #list > 16 do table.remove(list) end
    ns:RefreshRaidHealerCommsPanel()
end

-- Combina pruning de casts (>MAX_CAST_AGE) + stale healers + heartbeat hello.
-- Pre-merge eran 2 funciones separadas (PruneOld + heartbeat); juntos evitan
-- iterar las mismas tablas dos veces y centralizan la mantencion periodica.
local function PruneAndHeartbeat()
    -- En test mode los entries son "frozen" — no prune para que el preview
    -- quede estable. Hide test los limpia explicitamente.
    if _testMode then return false end
    local now = GetTime()
    local anyChanged = false

    -- Stale healers: dropeamos los que no respondieron en STALE_HEALER_TIMEOUT.
    -- Tambien limpiamos sus casts asociados (no tendria sentido mostrar casts
    -- huerfanos cuyo healer ya no esta en la lista).
    for name, info in pairs(_addonHealers) do
        if (now - (info.lastPing or 0)) > STALE_HEALER_TIMEOUT then
            _addonHealers[name] = nil
            _recentCasts[name] = nil
            anyChanged = true
        end
    end

    -- Casts viejos: capamos por edad. Mantenemos el resto para que el user
    -- vea historial reciente (no solo la ventana de 5s del modelo anterior).
    for name, list in pairs(_recentCasts) do
        local kept = {}
        for _, e in ipairs(list) do
            if (now - e.at) <= MAX_CAST_AGE then table.insert(kept, e) end
        end
        if #kept ~= #list then anyChanged = true end
        if #kept == 0 then _recentCasts[name] = nil
        else _recentCasts[name] = kept end
    end

    -- Heartbeat: re-broadcast nuestro hello cada HEARTBEAT_INTERVAL. Asi healers
    -- que joineen tarde a la raid nos detectan sin tener que esperar al
    -- siguiente cast nuestro.
    if (now - _lastHelloSent) >= HEARTBEAT_INTERVAL then
        SendHello()
    end

    return anyChanged
end

-- ============================================================
-- Panel UI
-- ============================================================

local ICON_SIZE = 24
local TIME_LABEL_H = 10
-- Row: icono (24) + gap (2) + time label (10) + padding (4) = ~40px
local ROW_H = 40
local NAME_WIDTH = 110
local PANEL_W = NAME_WIDTH + 16 + (ICON_SIZE + 2) * MAX_ICONS_PER_ROW + 12
local HEADER_H = 18

local function GetClassColor(class)
    if not class then return 1, 1, 1 end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if not c then return 1, 1, 1 end
    return c.r, c.g, c.b
end

-- Formatea edad en segundos a label compacto: "Xs" / "Xm" / "Xh".
local function FormatAge(age)
    if age < 1 then return "<1s" end
    if age < 60 then return string.format("%ds", math.floor(age)) end
    if age < 3600 then return string.format("%dm", math.floor(age / 60)) end
    return string.format("%dh", math.floor(age / 3600))
end

local function AcquireRow(parent, index)
    parent._rows = parent._rows or {}
    local r = parent._rows[index]
    if r then return r end
    r = CreateFrame("Frame", nil, parent)
    r:SetSize(PANEL_W - 8, ROW_H)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("LEFT", 4, 2); r.name:SetJustifyH("LEFT")
    r.name:SetSize(NAME_WIDTH, 16)
    r.name:SetWordWrap(false)
    r.icons = {}
    for i = 1, MAX_ICONS_PER_ROW do
        local btn = CreateFrame("Frame", nil, r)
        btn:SetSize(ICON_SIZE, ICON_SIZE)
        -- Anclamos al TOP del row para que el time label entre debajo.
        btn:SetPoint("TOPLEFT", r, "TOPLEFT", NAME_WIDTH + 8 + (i - 1) * (ICON_SIZE + 2), -2)
        btn.tex = btn:CreateTexture(nil, "ARTWORK")
        btn.tex:SetAllPoints()
        btn.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn:EnableMouse(true)
        btn:SetScript("OnEnter", function(self)
            if not self._spellID then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetSpellByID(self._spellID)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Time label debajo del icono. Mismo anchor X para centrar bajo el icono.
        btn.timeText = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        btn.timeText:SetPoint("TOP", btn, "BOTTOM", 0, -1)
        btn.timeText:SetTextColor(0.75, 0.75, 0.85)
        btn:Hide()
        r.icons[i] = btn
    end
    parent._rows[index] = r
    return r
end

local function BuildPanel()
    if panel then return panel end
    local f = CreateFrame("Frame", "HNZRaidHealerCommsPanel", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, 60)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.75)
    f:SetBackdropBorderColor(0.30, 0.30, 0.40, 1)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 6, -4)
    title:SetText((ns.L and ns.L["Raid Spells"]) or "Raid Spells (A)")
    title:SetTextColor(0.7, 0.7, 0.85)
    f.title = title

    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local pcx, pcy = UIParent:GetCenter()
        if cx and pcx and ns.db and ns.db.raidHealerComms then
            ns.db.raidHealerComms.offsetX = math.floor((cx - pcx) + 0.5)
            ns.db.raidHealerComms.offsetY = math.floor((cy - pcy) + 0.5)
        end
    end)
    f:Hide()
    panel = f
    return f
end

local function ApplyPanelPosition(f)
    local s = ns.db and ns.db.raidHealerComms
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER",
        (s and s.offsetX) or 200, (s and s.offsetY) or 200)
end

function ns:RefreshRaidHealerCommsPanel()
    if not panel then return end
    if not ShouldShow() then panel:Hide(); return end

    -- Render desde _addonHealers (no _recentCasts) — asi mostramos a TODOS los
    -- healers que tienen el addon habilitado aunque todavia no hayan casteado
    -- nada. La cantidad de filas es la cantidad de healers conocidos.
    local names = {}
    for n in pairs(_addonHealers) do table.insert(names, n) end
    table.sort(names)

    -- hideWhenEmpty ahora significa "ocultar si no se detecto ningun healer"
    -- (mas significativo que "ningun cast en 5s" del modelo anterior).
    if #names == 0 then
        local s = ns.db and ns.db.raidHealerComms
        if s and s.hideWhenEmpty then
            panel:Hide()
            return
        end
    end

    -- Solo aplicamos la posicion en la transicion hidden→shown. Llamarlo en
    -- cada refresh hace que el pruning ticker (0.5s) pise el drag en curso —
    -- ClearAllPoints + SetPoint mientras el user arrastra causa snap-back.
    if not panel:IsShown() then ApplyPanelPosition(panel) end
    panel:Show()

    local now = GetTime()
    local y = HEADER_H
    for i, name in ipairs(names) do
        local r = AcquireRow(panel, i)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -y)
        r:Show()

        local info = _addonHealers[name]
        local cls = (info and info.class) or _classByName[name]
        local cr, cg, cb = GetClassColor(cls)
        r.name:SetText(name)
        r.name:SetTextColor(cr, cg, cb)

        local list = _recentCasts[name] or {}
        for k = 1, MAX_ICONS_PER_ROW do
            local btn = r.icons[k]
            local cast = list[k]
            if cast then
                local _, icon = ns.GetSpellDisplayInfo(cast.spellID)
                btn.tex:SetTexture(icon)
                btn._spellID = cast.spellID
                btn:SetAlpha(1.0)
                btn.timeText:SetText(FormatAge(now - cast.at))
                btn.timeText:Show()
                btn:Show()
            else
                btn._spellID = nil
                btn.timeText:Hide()
                btn:Hide()
            end
        end

        y = y + ROW_H
    end

    -- Hide rows del pool sin uso
    if panel._rows then
        for j = #names + 1, #panel._rows do panel._rows[j]:Hide() end
    end

    if #names == 0 then
        if not panel.emptyText then
            local t = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            t:SetPoint("LEFT", panel, "LEFT", 8, -2)
            panel.emptyText = t
        end
        panel.emptyText:SetText((ns.L and ns.L["Waiting for healer casts..."]) or "Waiting for healer casts...")
        panel.emptyText:Show()
        panel:SetHeight(HEADER_H + 24)
    else
        if panel.emptyText then panel.emptyText:Hide() end
        panel:SetHeight(HEADER_H + #names * ROW_H + 6)
    end
end

function ns:RefreshRaidHealerComms()
    UpdateHealerSpec()
    if not panel then return end
    if ShouldShow() then
        ApplyPanelPosition(panel)
        ns:RefreshRaidHealerCommsPanel()
    else
        panel:Hide()
    end
end

-- ============================================================
-- Init + events
-- ============================================================

function ns:InitRaidHealerComms()
    BuildPanel()

    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end

    UpdateHealerSpec()

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ev:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    ev:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    ev:RegisterEvent("CHAT_MSG_ADDON")
    ev:RegisterEvent("GROUP_ROSTER_UPDATE")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
        if event == "PLAYER_SPECIALIZATION_CHANGED"
           or event == "ACTIVE_TALENT_GROUP_CHANGED" then
            UpdateHealerSpec()
            -- Si recien nos volvimos healer, mandamos hello para anunciar
            -- presencia inmediatamente (sin esperar al heartbeat).
            SendHello()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- arg1=unit, arg2=castGUID, arg3=spellID
            if arg1 == "player" then
                Broadcast(arg3)
            end
        elseif event == "CHAT_MSG_ADDON" then
            -- arg1=prefix, arg2=message, arg3=channel, arg4=sender
            if arg1 ~= PREFIX then return end
            local decoded = Decode(arg2)
            if not decoded then return end
            -- Ignorar nuestros propios mensajes (ya los grabamos local).
            local me = UnitName and UnitName("player")
            if me and StripRealm(arg4) == me then return end
            -- Marcamos al sender como vivo (lo agrega a _addonHealers si era
            -- nuevo). Si era nuevo, respondemos con nuestro hello para
            -- handshake bidireccional.
            local wasNew = MarkHealerAlive(arg4)
            if wasNew then SendHello() end
            if decoded.kind == "C" and decoded.spellID then
                RecordCast(arg4, decoded.spellID)
            end
            -- Refresh para que el nuevo healer (si era nuevo) aparezca aunque
            -- no haya casteado nada todavia.
            ns:RefreshRaidHealerCommsPanel()
        elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            -- Re-check spec en PLAYER_ENTERING_WORLD por si Init corrio antes
            -- que GetSpecialization tenga data (caso tipico post-loadscreen).
            UpdateHealerSpec()
            -- Anunciar presencia en el nuevo contexto (group join, zone change
            -- a instancia, etc.) — asi healers ya en la raid nos detectan.
            SendHello()
            ns:RefreshRaidHealerComms()
        end
    end)

    -- Tick periodico: stale prune + cast age cap + heartbeat hello + repintado
    -- para que los time labels se actualicen.
    if not pruneTicker then
        pruneTicker = C_Timer.NewTicker(PRUNE_INTERVAL, function()
            PruneAndHeartbeat()
            -- Repintamos siempre para refrescar los "Xs"/"Xm" labels aunque
            -- no haya cambios estructurales.
            if panel and panel:IsShown() then ns:RefreshRaidHealerCommsPanel() end
        end)
    end

    -- Initial hello: damos un pequeño delay para que el group context este
    -- listo si entramos a la raid recien logueado. Despues el heartbeat lo
    -- mantiene re-anunciandose.
    C_Timer.After(2, function() SendHello() end)

    ns:RefreshRaidHealerComms()
end

-- ============================================================
-- Test helper (para previsualizar el panel sin grupo real)
-- ============================================================
function ns:TestRaidHealerComms()
    BuildPanel()
    _testMode = true
    -- Mix de healers con casts recientes + uno sin casts (Discreta) para que
    -- el preview demuestre el comportamiento nuevo: la fila aparece aunque
    -- el healer no haya casteado nada (solo se anuncio con hello).
    local fakeData = {
        { name = "Probadora",  class = "PRIEST",  spells = { { 64843, 0 }, { 265202, 12 }, { 200183, 45 } } },
        { name = "Compañera",  class = "DRUID",   spells = { { 740, 3 }, { 197721, 90 } } },
        { name = "Sheilun",    class = "MONK",    spells = { { 388193, 1 }, { 322118, 25 }, { 115310, 180 } } },
        { name = "Tempora",    class = "EVOKER",  spells = { { 363534, 7 }, { 367226, 60 } } },
        { name = "Discreta",   class = "PALADIN", spells = {} }, -- healer sin casts aun
    }
    -- Wipe entries reales para no mezclar con el preview, pero conservar la
    -- estructura para que el refresh los muestre.
    _recentCasts = {}
    _addonHealers = {}
    local now = GetTime()
    for _, fd in ipairs(fakeData) do
        _addonHealers[fd.name] = { class = fd.class, lastPing = now }
        _classByName[fd.name] = fd.class
        if #fd.spells > 0 then
            _recentCasts[fd.name] = {}
            for _, entry in ipairs(fd.spells) do
                local sid, ageAgo = entry[1], entry[2]
                -- at = now - ageAgo para preview con times variados.
                -- _testMode skipea prune, asi que no expiran.
                table.insert(_recentCasts[fd.name], { spellID = sid, at = now - ageAgo })
            end
        end
    end
    ApplyPanelPosition(panel)
    panel:Show()
    ns:RefreshRaidHealerCommsPanel()
    print("|cff00ccffHNZ|r " .. ((ns.L and ns.L["Healer comms test preview shown. Click Hide to clear."]) or "Healer comms test preview shown. Click Hide to clear."))
end

function ns:HideRaidHealerCommsTest()
    _testMode = false
    _recentCasts = {}
    _addonHealers = {}
    if panel then panel:Hide() end
end

-- ============================================================
-- Debug helpers (consumidos por /hht healers en Config.lua)
-- ============================================================

-- Snapshot de _addonHealers con conteo de casts recientes inlineado. Devuelto
-- como tabla nueva para que el caller no pueda mutar el state interno.
ns._RaidHealerCommsDumpHealers = function()
    local out = {}
    for name, info in pairs(_addonHealers) do
        out[name] = {
            class = info.class,
            lastPing = info.lastPing,
            casts = _recentCasts[name] and #_recentCasts[name] or 0,
        }
    end
    return out
end

-- Force-send hello bypassing el rate-limit del heartbeat. Devuelve (ok, reason).
-- Util para troubleshooting: si el receiver no nos detecta, mandamos hello "ya"
-- y vemos si aparece en su /hht healers.
ns._RaidHealerCommsForceHello = function()
    if not _isHealerSpec then return false, "not healer spec" end
    local s = ns.db and ns.db.raidHealerComms
    if not s or s.enabled == false then return false, "disabled in config" end
    local channel = ResolveChannel()
    if not channel then return false, "not in group/instance" end
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return false, "C_ChatInfo unavailable" end
    local ok = pcall(C_ChatInfo.SendAddonMessage, PREFIX, EncodeHello(), channel)
    _lastHelloSent = GetTime()
    return ok and true or false, ok and channel or "SendAddonMessage failed"
end
