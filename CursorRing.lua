local _, ns = ...

-- CursorRing: anillo decorativo siguiendo al raton, opt-in. Opcionalmente
-- muestra un cast progress sub-anillo (180 cuñas rotadas que se iluminan
-- segun el avance de UnitCastingInfo / UnitChannelInfo).
-- Patron: Frame con textura, OnUpdate posiciona via GetCursorPosition()
-- convertido a coordenadas de UIParent.

local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
local UnitClass = UnitClass
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetTime = GetTime
local mathfloor = math.floor
local mathmax = math.max
local mathmin = math.min
local mathrad = math.rad
local mathabs = math.abs

local frame
local tex
local castFrame    -- sub-frame hijo de `frame`, hostea los wedges; tamaño independiente del ring base
local castSegments -- {[1..NUM_CAST_SEGMENTS] = texture}, lazy init
local dotTex       -- textura central, lazy init
local cachedUILeft, cachedUIBottom, cachedUIScale
local scaleEvt, combatEvt, castEvt
local inCombat = false
local castActive = false
local castStart, castEnd = 0, 0
local castIsChannel = false  -- channel "normal" -> progress se invierte (full -> empty)
local castIsEmpower = false  -- empowered (Evoker) -> tratado como cast normal (fill 0 -> 1)
local lastNumLit = 0  -- ultimo numero de wedges encendidos (para no rescribir alpha innecesariamente)
local cachedCastOpacity = 1  -- cache de cast.opacity actualizada por ApplyCastVisuals; los wedges encendidos usan este valor en SetAlpha
local cachedCastDirection = "right"  -- "right" = horario, "left" = antihorario; cambiar reinicia los wedges
-- Ultima posicion anclada del frame. Saltamos SetPoint cuando el cursor no
-- se ha movido apreciablemente; con el cursor quieto el OnUpdate se vuelve
-- casi gratis. Sentinel inicial muy negativo fuerza un primer SetPoint.
local lastAnchorX, lastAnchorY = -math.huge, -math.huge

local NUM_CAST_SEGMENTS = 180
local CAST_WEDGE_TEXTURE = "Interface\\AddOns\\HNZHealingTools\\Textures\\cast_wedge"
local DOT_TEXTURE = "Interface\\AddOns\\HNZHealingTools\\Textures\\dot"

-- Estado del "grow on movement" del dot. lastRawX/Y son las coordenadas crudas
-- (pre-scaling) del cursor, que es lo más estable para detectar movimiento real
-- independientemente del UI scale. dotCurrentScale interpola entre 1 y growScale
-- y se aplica multiplicativamente sobre dot.size en cada OnUpdate.
local lastRawX, lastRawY = 0, 0
local lastMoveTime = -math.huge
local dotCurrentScale = 1
local DOT_GROW_LERP = 14            -- mayor = transicion mas snappy entre tamaños
local DOT_MOVE_THRESHOLD_SQ = 1     -- (px raw)^2; <1 px de delta cuenta como quieto
local DOT_MOVE_LINGER = 0.06        -- s tras el ultimo movimiento para seguir "moving" (suaviza micro-pausas)

-- Settings cacheadas para evitar lookups en hot path. Se invalidan en
-- RefreshCursorRing/ApplyVisuals; las leemos cada frame solo como upvalues.
local cachedSize, cachedFracX, cachedFracY, cachedOffsetX, cachedOffsetY = 48, 0, 0, 0, 0

local DEFAULT_TEXTURE = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring"

-- Catalogo de texturas: 6 anillos propios del addon (carpeta Textures/) ordenados
-- por grosor de stroke. Todos comparten outer radius (62/128 del canvas) así que
-- intercambiarlos solo cambia el grosor visible, no el diametro aparente. Centro
-- exacto en el frame (fracX/Y = 0) — el campo se mantiene por compatibilidad.
ns.CURSOR_RING_TEXTURES = {
    { label = "Thin Ring — 2 px",      value = "Interface\\AddOns\\HNZHealingTools\\Textures\\thin_ring",     fracX = 0, fracY = 0 },
    { label = "Medium Ring — 4 px",    value = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring_med",      fracX = 0, fracY = 0 },
    { label = "Ring — 6 px",           value = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring",          fracX = 0, fracY = 0 },
    { label = "Thick Ring — 10 px",    value = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring_thick",    fracX = 0, fracY = 0 },
    { label = "Thicker Ring — 14 px",  value = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring_thicker",  fracX = 0, fracY = 0 },
    { label = "Thickest Ring — 18 px", value = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring_thickest", fracX = 0, fracY = 0 },
}

-- Si la textura guardada (savedvars) no existe en el catalogo actual (e.g. una
-- built-in retirada en v1.0.20), devuelve la default. Garantiza que el dropdown
-- siempre muestre una opcion valida.
local function ResolveTexture(value)
    if not value then return DEFAULT_TEXTURE end
    for _, t in ipairs(ns.CURSOR_RING_TEXTURES) do
        if t.value == value then return value end
    end
    return DEFAULT_TEXTURE
end

local function GetCalibration(textureValue)
    for _, t in ipairs(ns.CURSOR_RING_TEXTURES) do
        if t.value == textureValue then
            return t.fracX or 0, t.fracY or 0
        end
    end
    return 0, 0
end

local function GetEffectiveColor(s)
    if s.useClassColor then
        local _, class = UnitClass("player")
        local rgb = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if rgb then return rgb.r, rgb.g, rgb.b end
    end
    local c = s.color or { r = 1, g = 1, b = 1 }
    return c.r or 1, c.g or 1, c.b or 1
end

-- Devuelve si una sub-feature debe estar efectivamente visible ahora mismo.
-- Cada sub-feature tiene su propio `enabled` y `visibility` que se evaluan
-- independientemente: el dot puede estar visible aunque el ring decorativo
-- este oculto por su combat-gate, y viceversa.
local function FeatureShouldShow(featureCfg)
    if not featureCfg or not featureCfg.enabled then return false end
    return ns.MatchesVisibility(featureCfg.visibility, inCombat)
end

local function RingShouldShow(s)
    -- Ring decorativo: usa `s.enabled` y `s.visibility` directos en `s` (estos
    -- campos viven al nivel raiz, no en s.ring.*).
    if not s.enabled then return false end
    return ns.MatchesVisibility(s.visibility, inCombat)
end

local function ApplyVisuals()
    if not frame then return end
    local s = ns.db and ns.db.cursorRing
    if not s then return end
    local size = s.size or 48
    frame:SetSize(size, size)
    if tex then
        if RingShouldShow(s) then
            tex:Show()
            tex:SetTexture(s.texture or DEFAULT_TEXTURE)
            local r, g, b = GetEffectiveColor(s)
            tex:SetVertexColor(r, g, b, s.opacity or 1)
        else
            tex:Hide()
        end
    end
    cachedSize = size
    cachedFracX, cachedFracY = GetCalibration(s.texture or DEFAULT_TEXTURE)
    cachedOffsetX, cachedOffsetY = s.offsetX or 0, s.offsetY or 0
    -- Invalidar el anchor cacheado: tamaño/offset/textura pueden haber cambiado,
    -- el siguiente OnUpdate debe re-anclar aunque el cursor no se mueva.
    lastAnchorX, lastAnchorY = -math.huge, -math.huge
end

local function ShouldBeShown(s)
    -- El frame padre se muestra si CUALQUIER sub-feature deberia estar visible
    -- ahora mismo, considerando cada combat-gate por separado. Asi el dot puede
    -- mostrarse incluso si el ring decorativo esta oculto por su propio gate.
    return RingShouldShow(s) or FeatureShouldShow(s.cast) or FeatureShouldShow(s.dot)
end

-- Construye las 180 cuñas anulares solo la primera vez que se necesitan.
-- Cada wedge cubre 2° del anillo; SetRotation hace que la i-esima quede en (i-1)*2°.
-- La textura está dibujada centrada en 270° (top, "12 en punto") así que la cuña 1
-- (rotación 0°) cae arriba y la progresión va horario. Los wedges viven en `castFrame`,
-- un sub-frame del ring base con tamaño independiente para que el cast progress pueda
-- estar en un radio distinto al del anillo decorativo (separation slider).
local function EnsureCastSegments()
    if castSegments or not frame then return end
    castFrame = CreateFrame("Frame", nil, frame)
    castFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
    castFrame:EnableMouse(false)
    castSegments = {}
    for i = 1, NUM_CAST_SEGMENTS do
        local seg = castFrame:CreateTexture(nil, "OVERLAY")
        seg:SetTexture(CAST_WEDGE_TEXTURE)
        seg:SetAllPoints()
        seg:SetBlendMode("BLEND")
        seg:SetRotation(mathrad((i - 1) * (360 / NUM_CAST_SEGMENTS)))
        seg:SetAlpha(0)
        castSegments[i] = seg
    end
end

local function HideAllCastSegments()
    if not castSegments then return end
    for i = 1, NUM_CAST_SEGMENTS do
        castSegments[i]:SetAlpha(0)
    end
    lastNumLit = 0
end

-- Devuelve el indice del wedge a iluminar en la posicion k (1-based) segun la direccion.
-- "right" (horario): k → k                       (wedge 1, 2, 3, ..., 180 en orden)
-- "left"  (antihorario): k=1 → 1, k>1 → 182-k    (wedge 1, 180, 179, ..., 2 en orden)
-- Ambos arrancan en wedge 1 (12 en punto) y cubren los 180 wedges; solo cambia el sentido.
local function WedgeAt(k)
    if cachedCastDirection == "left" and k > 1 then
        return NUM_CAST_SEGMENTS - k + 2
    end
    return k
end

local function ApplyCastVisuals()
    if not castSegments then return end
    local s = ns.db and ns.db.cursorRing
    local cast = s and s.cast
    if not cast then return end
    local c = cast.color or { r = 0.20, g = 0.82, b = 0.68 }
    cachedCastOpacity = cast.opacity or 1
    local newDir = cast.direction or "right"
    if newDir ~= "left" then newDir = "right" end
    if newDir ~= cachedCastDirection then
        cachedCastDirection = newDir
        HideAllCastSegments()
    end
    -- El alpha del wedge va por SetAlpha (pipeline unica), no por vertex alpha.
    -- Antes mezclábamos vertex alpha (opacity) con region alpha (1=lit / 0=hide)
    -- y el slider de opacity no producía cambios visibles porque el vertex alpha
    -- quedaba enmascarado por SetAlpha. Vertex color ahora solo lleva rgb (alpha=1)
    -- y el slider modifica directamente el SetAlpha de los wedges encendidos.
    for i = 1, NUM_CAST_SEGMENTS do
        castSegments[i]:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, 1)
    end
    -- Re-aplicar la opacidad a los wedges actualmente encendidos para que el
    -- cambio de slider sea inmediato durante un cast en curso. Usa WedgeAt para
    -- respetar la direccion (los lit wedges no son siempre 1..lastNumLit).
    for i = 1, lastNumLit do
        castSegments[WedgeAt(i)]:SetAlpha(cachedCastOpacity)
    end
    if castFrame then
        local castSize = cast.size or s.size or 48
        if castSize < 4 then castSize = 4 end
        castFrame:SetSize(castSize, castSize)
    end
end

local function EnsureDot()
    if dotTex or not frame then return end
    dotTex = frame:CreateTexture(nil, "OVERLAY")
    dotTex:SetTexture(DOT_TEXTURE)
    dotTex:SetPoint("CENTER", frame, "CENTER", 0, 0)
    dotTex:SetBlendMode("BLEND")
    dotTex:Hide()
end

local function ApplyDotVisuals()
    local s = ns.db and ns.db.cursorRing
    local dot = s and s.dot
    if not FeatureShouldShow(dot) then
        if dotTex then dotTex:Hide() end
        return
    end
    EnsureDot()
    if not dotTex then return end
    local size = dot.size or 6
    if size < 1 then size = 1 end
    -- El tamaño aplicado lleva la escala dinamica (1 cuando el cursor está quieto
    -- o cuando growOnMovement está off; growScale al moverse). OnUpdate ajusta
    -- dotCurrentScale frame-a-frame; aquí solo lo aplicamos.
    dotTex:SetSize(size * dotCurrentScale, size * dotCurrentScale)
    local c = dot.color or { r = 1, g = 1, b = 1, a = 1 }
    dotTex:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    dotTex:Show()
end

-- Actualiza dotCurrentScale segun si el cursor se está moviendo y aplica el
-- nuevo tamaño al dot. Llamado desde OnUpdate con coords crudas y elapsed.
local function UpdateDotMovement(rawX, rawY, elapsed)
    if not dotTex or not dotTex:IsShown() then
        lastRawX, lastRawY = rawX, rawY
        return
    end
    local s = ns.db and ns.db.cursorRing
    local dot = s and s.dot
    if not dot then return end

    local target
    if dot.growOnMovement and ns.MatchesVisibility(dot.growVisibility, inCombat) then
        local dx = rawX - lastRawX
        local dy = rawY - lastRawY
        if (dx * dx + dy * dy) >= DOT_MOVE_THRESHOLD_SQ then
            lastMoveTime = GetTime()
        end
        local isMoving = (GetTime() - lastMoveTime) < DOT_MOVE_LINGER
        target = isMoving and (dot.growScale or 2.5) or 1
    else
        target = 1
    end

    local lerpFactor = mathmin(1, (elapsed or 0) * DOT_GROW_LERP)
    local newScale = dotCurrentScale + (target - dotCurrentScale) * lerpFactor
    -- Snap a target cuando la diferencia es despreciable: evita micro-updates de
    -- tamaño que no se notan visualmente pero generan SetSize cada frame.
    if mathabs(newScale - target) < 0.005 then newScale = target end
    if newScale ~= dotCurrentScale then
        dotCurrentScale = newScale
        local baseSize = dot.size or 6
        if baseSize < 1 then baseSize = 1 end
        local px = baseSize * dotCurrentScale
        dotTex:SetSize(px, px)
    end
    lastRawX, lastRawY = rawX, rawY
end

-- ============================================================
-- Trail + sparkle FX (estilo CursorRing addon).
-- Las texturas viven en un frame ANCLADO A UIParent (no al ring frame que
-- sigue al cursor) para que cada FX se quede fija en el mundo mientras el
-- cursor se mueve. Pool reusable para evitar GC en cada spawn.
-- ============================================================

local fxFrame
local fxPool = {}

local TRAIL_LIFETIME = 0.45
local TRAIL_SPAWN_INTERVAL = 0.02     -- s entre spawns mientras el cursor se mueve
local TRAIL_MIN_MOVE_SQ = 4           -- (px)^2 minimo de delta para spawn nuevo
local SPARKLE_LIFETIME = 0.5
local SPARKLE_SPAWN_INTERVAL = 0.05   -- s entre tandas de destellos
local SPARKLE_MAX_RADIUS = 14         -- px radio del jitter alrededor del cursor
local SPARKLE_PATH_SPACING = 18       -- px deseados entre sparkles a lo largo del path
local SPARKLE_MAX_PER_TICK = 8        -- cap de sparkles spawneados en un solo tick
local SPARKLE_RESET_GAP = 0.4         -- s sin spawn -> tratar como inicio fresco (no path-fill)

-- Catalogo de formas para sparkles. Reusa texturas que ya envia el addon en
-- Textures/ (sin nuevos assets). "mixed" elige uno al azar por spawn entre las
-- formas listadas en SPARKLE_MIXED_KEYS.
local SPARKLE_SHAPE_TEXTURES = {
    dot        = "Interface\\AddOns\\HNZHealingTools\\Textures\\dot",
    ring_thin  = "Interface\\AddOns\\HNZHealingTools\\Textures\\thin_ring",
    ring_thick = "Interface\\AddOns\\HNZHealingTools\\Textures\\ring_thick",
    wedge      = "Interface\\AddOns\\HNZHealingTools\\Textures\\cast_wedge",
}
local SPARKLE_MIXED_KEYS = { "dot", "ring_thin", "ring_thick", "wedge" }

local function PickSparkleTexture(shape)
    if shape == "mixed" then
        local k = SPARKLE_MIXED_KEYS[math.random(1, #SPARKLE_MIXED_KEYS)]
        return SPARKLE_SHAPE_TEXTURES[k]
    end
    return SPARKLE_SHAPE_TEXTURES[shape] or SPARKLE_SHAPE_TEXTURES.dot
end

local lastTrailTime = 0
local lastTrailX, lastTrailY = -math.huge, -math.huge
local lastSparkleTime = 0
local lastSparkleX, lastSparkleY = -math.huge, -math.huge

local function EnsureFXFrame()
    if fxFrame then return end
    fxFrame = CreateFrame("Frame", "HNZHealingToolsCursorRingFX", UIParent)
    fxFrame:SetFrameStrata("TOOLTIP")
    fxFrame:SetFrameLevel(99)
    fxFrame:EnableMouse(false)
    fxFrame:SetAllPoints(UIParent)
end

local function AcquireFX()
    EnsureFXFrame()
    for i = 1, #fxPool do
        local e = fxPool[i]
        if not e.tex:IsShown() then return e end
    end
    local e = {}
    e.tex = fxFrame:CreateTexture(nil, "OVERLAY")
    e.tex:SetTexture(DOT_TEXTURE)
    e.tex:SetBlendMode("ADD")
    e.tex:Hide()
    table.insert(fxPool, e)
    return e
end

local function HideAllFX()
    for i = 1, #fxPool do fxPool[i].tex:Hide() end
end

local function SpawnTrail(x, y, dot)
    local e = AcquireFX()
    e.kind = "trail"
    e.born = GetTime()
    e.lifetime = dot.trailLength or TRAIL_LIFETIME
    local size = (dot.size or 6) * 1.2 * (dotCurrentScale or 1)
    e.startSize = size
    e.tex:SetSize(size, size)
    e.tex:ClearAllPoints()
    e.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    -- Forzar textura: el FX object viene de un pool compartido con sparkles, que
    -- pueden setear cualquier shape. Sin este reset un pool entry reciclado de
    -- sparkle dejaria al trail con la textura "wrong" (e.g. wedge).
    e.tex:SetTexture(DOT_TEXTURE)
    local c = dot.trailColor or dot.color or { r = 1, g = 1, b = 1, a = 1 }
    e.tex:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    e.tex:SetAlpha(1)
    e.tex:SetRotation(0)
    e.tex:Show()
end

local function SpawnSparkle(x, y, dot)
    local e = AcquireFX()
    e.kind = "sparkle"
    e.born = GetTime()
    e.lifetime = SPARKLE_LIFETIME
    local ang = math.random() * 6.2831853
    local dist = math.random() * SPARKLE_MAX_RADIUS
    local sx = x + math.cos(ang) * dist
    local sy = y + math.sin(ang) * dist
    local base = dot.size or 6
    local mult = dot.sparkleSize or 1.0
    e.startSize = base * 0.6 * mult
    e.endSize = base * 1.6 * mult
    e.tex:SetSize(e.startSize, e.startSize)
    e.tex:ClearAllPoints()
    e.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", sx, sy)
    e.tex:SetTexture(PickSparkleTexture(dot.sparkleShape or "dot"))
    local c = dot.sparkleColor or dot.color or { r = 1, g = 1, b = 1, a = 1 }
    e.tex:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    e.tex:SetAlpha(1)
    e.tex:SetRotation(math.random() * 6.2831853)
    e.tex:Show()
end

local function UpdateFX()
    local now = GetTime()
    for i = 1, #fxPool do
        local e = fxPool[i]
        if e.tex:IsShown() then
            local age = now - e.born
            if age >= e.lifetime then
                e.tex:Hide()
            else
                local p = age / e.lifetime
                if e.kind == "trail" then
                    e.tex:SetAlpha(1 - p)
                    local sz = e.startSize * (1 - 0.5 * p)
                    e.tex:SetSize(sz, sz)
                else
                    local sz = e.startSize + (e.endSize - e.startSize) * p
                    e.tex:SetSize(sz, sz)
                    e.tex:SetAlpha(1 - p)
                end
            end
        end
    end
end

local function MaybeSpawnFX(x, y)
    local s = ns.db and ns.db.cursorRing
    local dot = s and s.dot
    if not dot then return end
    -- FX gated por las mismas reglas de visibilidad del dot (el FX vive cuando
    -- el dot es visible: ring habilitado + combat-gate + dot habilitado/gated).
    if not FeatureShouldShow(s) or not FeatureShouldShow(dot) then return end
    local now = GetTime()
    if dot.trail and ns.MatchesVisibility(dot.trailVisibility, inCombat) then
        local dx = x - lastTrailX
        local dy = y - lastTrailY
        if (dx * dx + dy * dy) >= TRAIL_MIN_MOVE_SQ
           and (now - lastTrailTime) >= TRAIL_SPAWN_INTERVAL then
            SpawnTrail(x, y, dot)
            lastTrailX, lastTrailY = x, y
            lastTrailTime = now
        end
    end
    if dot.sparkle and ns.MatchesVisibility(dot.sparkleVisibility, inCombat)
       and (now - lastSparkleTime) >= SPARKLE_SPAWN_INTERVAL then
        -- Rellenar el path: entre tick y tick el cursor puede haber recorrido
        -- mucho; si solo spawneamos 1 sparkle en la posicion actual los del
        -- rastro lejano quedan muy separados. Spawneamos N sparkles evenly-
        -- spaced entre la ultima posicion y la actual (cap a SPARKLE_MAX_PER_TICK
        -- para evitar bursts si el cursor pega un salto). Cuando el cursor esta
        -- quieto dx=dy=0 -> n=1 -> 1 sparkle cerca del cursor (comportamiento
        -- previo). Si paso mucho desde el ultimo spawn tratamos como inicio
        -- fresco para no spawnear una linea entre posiciones obsoletas.
        if lastSparkleX <= -math.huge or (now - lastSparkleTime) > SPARKLE_RESET_GAP then
            SpawnSparkle(x, y, dot)
        else
            local dx = x - lastSparkleX
            local dy = y - lastSparkleY
            local dist = math.sqrt(dx * dx + dy * dy)
            local n = math.floor(dist / SPARKLE_PATH_SPACING) + 1
            if n < 1 then n = 1 end
            if n > SPARKLE_MAX_PER_TICK then n = SPARKLE_MAX_PER_TICK end
            for i = 1, n do
                local t = i / n
                SpawnSparkle(lastSparkleX + dx * t, lastSparkleY + dy * t, dot)
            end
        end
        lastSparkleX, lastSparkleY = x, y
        lastSparkleTime = now
    end
end

local function UpdateCastProgress()
    if not castActive or not castSegments then return end
    local total = castEnd - castStart
    if total <= 0 then HideAllCastSegments(); return end
    local progress = (GetTime() - castStart) / total
    -- Solo el "channel" tradicional drena (full -> empty). Los empowered
    -- (Evoker) cargan progresivamente como un cast normal.
    if castIsChannel and not castIsEmpower then progress = 1 - progress end
    progress = mathmax(0, mathmin(1, progress))
    local numLit = mathfloor(progress * NUM_CAST_SEGMENTS + 0.5)
    if numLit == lastNumLit then return end
    if numLit > lastNumLit then
        -- Wedge encendido = SetAlpha(opacity); apagado = SetAlpha(0). Vertex color
        -- ya tiene rgb correcto (alpha=1), así que el slider de opacidad funciona.
        for i = lastNumLit + 1, numLit do castSegments[WedgeAt(i)]:SetAlpha(cachedCastOpacity) end
    else
        for i = numLit + 1, lastNumLit do castSegments[WedgeAt(i)]:SetAlpha(0) end
    end
    lastNumLit = numLit
end

-- Lee el cast actual del player. `mode` define qué API consultar y cómo
-- interpretar el progreso. Devuelve startMs, endMs o nil si no hay cast válido.
-- "cast"    -> UnitCastingInfo, fill 0->1
-- "channel" -> UnitChannelInfo, fill 1->0 (drena como una barra de canalización)
-- "empower" -> UnitChannelInfo, fill 0->1 (los empowered cargan, no drenan)
local function ReadCastTimes(mode)
    if mode == "channel" or mode == "empower" then
        local _, _, _, st, en = UnitChannelInfo("player")
        return st, en
    end
    local _, _, _, st, en = UnitCastingInfo("player")
    return st, en
end

local function StartCast(mode)
    local s = ns.db and ns.db.cursorRing and ns.db.cursorRing.cast
    -- FeatureShouldShow gatea por enabled + visibility. Si la visibilidad no
    -- permite mostrar ahora, no encendemos los wedges; ahorra el coste de
    -- iniciar el ciclo de cast progress.
    if not FeatureShouldShow(s) then return end
    local startMs, endMs = ReadCastTimes(mode)
    -- Fallback defensivo: algunos hechizos disparan START de un tipo pero los
    -- datos solo están disponibles en la otra API (p.ej. cuando un canal
    -- coexiste con un hardcast del monje). Probamos la opuesta antes de rendirnos.
    if not (startMs and endMs and endMs > startMs) then
        if mode == "cast" then
            startMs, endMs = ReadCastTimes("channel")
            if startMs and endMs and endMs > startMs then mode = "channel" end
        elseif mode == "channel" or mode == "empower" then
            startMs, endMs = ReadCastTimes("cast")
            if startMs and endMs and endMs > startMs then mode = "cast" end
        end
    end
    if not (startMs and endMs and endMs > startMs) then return end
    EnsureCastSegments()
    ApplyCastVisuals()
    -- Limpieza defensiva: si hubo un STOP perdido o dos casts solapados, los
    -- wedges del cast anterior pueden seguir encendidos. Reset a 0 antes de
    -- pintar el nuevo progreso evita "ring lleno al instante" en re-entrada.
    HideAllCastSegments()
    castStart, castEnd = startMs / 1000, endMs / 1000
    castIsChannel = (mode == "channel" or mode == "empower")
    castIsEmpower = (mode == "empower")
    castActive = true
    lastNumLit = 0
end

-- Refresca solo los tiempos del cast en curso (cast delayed, channel update,
-- empower update). No cambia el modo ni reinicia los wedges.
local function RefreshCastTimes()
    if not castActive then return end
    local mode
    if castIsEmpower then mode = "empower"
    elseif castIsChannel then mode = "channel"
    else mode = "cast" end
    local startMs, endMs = ReadCastTimes(mode)
    if not (startMs and endMs and endMs > startMs) then return end
    castStart, castEnd = startMs / 1000, endMs / 1000
end

local function StopCast()
    castActive = false
    castIsChannel = false
    castIsEmpower = false
    HideAllCastSegments()
end

local function CreateRingFrame()
    if frame then return end
    frame = CreateFrame("Frame", "HNZHealingToolsCursorRingFrame", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(100)
    frame:EnableMouse(false)
    frame:SetClampedToScreen(false)

    tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetBlendMode("BLEND")

    ApplyVisuals()

    frame:SetScript("OnUpdate", function(self, elapsed)
        if not cachedUILeft then
            cachedUILeft, cachedUIBottom = UIParent:GetRect()
            if not cachedUILeft then return end
        end
        if not cachedUIScale then
            cachedUIScale = UIParent:GetEffectiveScale()
            if not cachedUIScale or cachedUIScale == 0 then cachedUIScale = nil; return end
        end
        local rawX, rawY = GetCursorPosition()
        local x = rawX / cachedUIScale - cachedUILeft + cachedSize * cachedFracX + cachedOffsetX
        local y = rawY / cachedUIScale - cachedUIBottom + cachedSize * cachedFracY + cachedOffsetY
        -- Skip SetPoint cuando el cursor no se ha movido (>= 0.5 px). Cada
        -- SetPoint dispara re-layout interno; con el cursor quieto este path
        -- se vuelve casi gratis. Las cuñas del cast siguen actualizandose.
        local dx, dy = x - lastAnchorX, y - lastAnchorY
        if dx >= 0.5 or dx <= -0.5 or dy >= 0.5 or dy <= -0.5 then
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            lastAnchorX, lastAnchorY = x, y
        end
        if castActive then UpdateCastProgress() end
        -- Las coords crudas van a la deteccion de movimiento del dot porque son
        -- estables ante cambios de UI scale (no se reescalean entre frames).
        UpdateDotMovement(rawX, rawY, elapsed)
        -- Trail y sparkle: spawn condicional + tick global de fade-out. Update
        -- corre siempre para que las particulas en vuelo sigan desvaneciendose
        -- aunque se acabe de apagar la opcion (no se quedan congeladas).
        MaybeSpawnFX(x, y)
        UpdateFX()
    end)
end

-- Forward decl: definido al final del archivo. RefreshCursorRing lo invoca para
-- que cualquier preview embebido en el config se sincronice con los sliders.
local NotifyCursorRingPreviews

function ns:RefreshCursorRing()
    local s = ns.db and ns.db.cursorRing
    if not s then return end
    -- Migracion: texturas built-in retiradas en v1.0.20 → fallback a la SAT default
    s.texture = ResolveTexture(s.texture)
    if not ShouldBeShown(s) then
        if frame then frame:Hide() end
        HideAllFX()
        return
    end
    if not frame then CreateRingFrame() end
    ApplyVisuals()
    -- Cast progress: el `castFrame` (subframe parent de los wedges) se muestra
    -- segun FeatureShouldShow(cast). Hide a nivel de subframe oculta los wedges
    -- aunque haya un cast activo (ej. combat-gate disparado mid-cast); cuando se
    -- vuelve a mostrar el OnUpdate retoma el progreso correcto.
    local cast = s.cast
    if FeatureShouldShow(cast) then
        EnsureCastSegments()
        ApplyCastVisuals()
        if castFrame then castFrame:Show() end
        if not castActive then HideAllCastSegments() end
    else
        if castFrame then castFrame:Hide() end
    end
    ApplyDotVisuals()
    frame:Show()
    if NotifyCursorRingPreviews then NotifyCursorRingPreviews() end
end

function ns:ToggleCursorRing()
    if not ns.db or not ns.db.cursorRing then return end
    ns.db.cursorRing.enabled = not ns.db.cursorRing.enabled
    ns:RefreshCursorRing()
end

function ns:InitCursorRing()
    if not scaleEvt then
        scaleEvt = CreateFrame("Frame")
        scaleEvt:RegisterEvent("UI_SCALE_CHANGED")
        scaleEvt:RegisterEvent("DISPLAY_SIZE_CHANGED")
        scaleEvt:SetScript("OnEvent", function()
            cachedUILeft, cachedUIBottom, cachedUIScale = nil, nil, nil
            -- Tras recachear escala/rect, las coords cambian aunque el cursor
            -- este quieto. Forzamos re-anchor invalidando el sentinel.
            lastAnchorX, lastAnchorY = -math.huge, -math.huge
        end)
    end
    if not combatEvt then
        combatEvt = CreateFrame("Frame")
        combatEvt:RegisterEvent("PLAYER_REGEN_ENABLED")
        combatEvt:RegisterEvent("PLAYER_REGEN_DISABLED")
        combatEvt:SetScript("OnEvent", function(_, e)
            inCombat = (e == "PLAYER_REGEN_DISABLED")
            ns:RefreshCursorRing()
        end)
    end
    if not castEvt then
        castEvt = CreateFrame("Frame")
        -- Hardcasts
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
        -- DELAYED dispara cuando el cast se empuja hacia atrás (pushback por daño,
        -- por ej.); sin esto el progreso se desincroniza y el ring se llena antes
        -- de tiempo o se queda quieto al final.
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player")
        -- Channels tradicionales
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
        -- CHANNEL_UPDATE refresca duración cuando un canal se extiende (mecanicas
        -- como Soothing Mist + Enveloping Mist del monje, donde un instant amplia
        -- el canal en curso). Sin esto el progreso queda apuntando al endTime viejo.
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
        -- Empowered casts (Evoker). Son canalizados pero llenan en lugar de drenar,
        -- y reportan la duración via UnitChannelInfo igual que un canal normal.
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "player")
        castEvt:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
        castEvt:SetScript("OnEvent", function(_, e)
            if e == "UNIT_SPELLCAST_START" then
                StartCast("cast")
            elseif e == "UNIT_SPELLCAST_CHANNEL_START" then
                StartCast("channel")
            elseif e == "UNIT_SPELLCAST_EMPOWER_START" then
                StartCast("empower")
            elseif e == "UNIT_SPELLCAST_DELAYED"
                or e == "UNIT_SPELLCAST_CHANNEL_UPDATE"
                or e == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
                RefreshCastTimes()
            else
                StopCast()
            end
        end)
    end
    inCombat = InCombatLockdown()
    ns:RefreshCursorRing()
end

-- ============================================================
-- Live preview: simula un cursor virtual moviendose dentro del frame del preview
-- y renderiza ring + cast (animacion ciclica) + dot + trail + sparkle con los
-- settings actuales de ns.db.cursorRing. Auto-contenido — su FX pool y todas
-- las texturas son locales al preview, no tocan el frame/fxPool reales.
-- ============================================================

local previewRegistry = {}

local function BuildPreviewSurface(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:EnableMouse(false)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints()
    f.tex:SetBlendMode("BLEND")

    f.castFrame = CreateFrame("Frame", nil, f)
    f.castFrame:SetPoint("CENTER", f, "CENTER")
    f.castFrame:EnableMouse(false)
    f.castSegments = {}
    for i = 1, NUM_CAST_SEGMENTS do
        local seg = f.castFrame:CreateTexture(nil, "OVERLAY")
        seg:SetTexture(CAST_WEDGE_TEXTURE)
        seg:SetAllPoints()
        seg:SetBlendMode("BLEND")
        seg:SetRotation(mathrad((i - 1) * (360 / NUM_CAST_SEGMENTS)))
        seg:SetAlpha(0)
        f.castSegments[i] = seg
    end

    f.dotTex = f:CreateTexture(nil, "OVERLAY")
    f.dotTex:SetTexture(DOT_TEXTURE)
    f.dotTex:SetPoint("CENTER", f, "CENTER")
    f.dotTex:SetBlendMode("BLEND")
    f.dotTex:Hide()

    return f
end

-- focus puede ser "ring", "cast", o "dot": pinta esa feature al 100% y las otras
-- dos al 30% para que se vea claro cual sub-tab esta editando el usuario. Si no
-- se pasa, todo va al 100% (comportamiento original).
local FOCUS_DIM = 0.30
local FOCUS_MASKS = {
    ring = { ring = 1.0,       cast = FOCUS_DIM, dot = FOCUS_DIM },
    cast = { ring = FOCUS_DIM, cast = 1.0,       dot = FOCUS_DIM },
    dot  = { ring = FOCUS_DIM, cast = FOCUS_DIM, dot = 1.0       },
}

function ns:CreateCursorRingPreview(parent, focus)
    local container = CreateFrame("Frame", nil, parent)
    container:EnableMouse(false)
    local focusMask = FOCUS_MASKS[focus] or { ring = 1, cast = 1, dot = 1 }

    -- FX frame anclado al container (trail/sparkles se quedan dentro de la caja
    -- en vez de seguir al cursor real). Pool propio para evitar conflictos con
    -- el FX pool real del modulo.
    local fxF = CreateFrame("Frame", nil, container)
    fxF:SetAllPoints()
    fxF:SetFrameLevel((container:GetFrameLevel() or 1) + 5)
    fxF:EnableMouse(false)
    local fxPool = {}

    local function AcquireFX()
        for i = 1, #fxPool do
            if not fxPool[i].tex:IsShown() then return fxPool[i] end
        end
        local e = {}
        e.tex = fxF:CreateTexture(nil, "OVERLAY")
        e.tex:SetTexture(DOT_TEXTURE)
        e.tex:SetBlendMode("ADD")
        e.tex:Hide()
        fxPool[#fxPool+1] = e
        return e
    end

    local ringF = BuildPreviewSurface(container)
    ringF:SetFrameLevel((container:GetFrameLevel() or 1) + 8)

    local startTime = GetTime()
    local lastTrailX, lastTrailY = -math.huge, -math.huge
    local lastTrailTime = 0
    local lastSparkleX, lastSparkleY = -math.huge, -math.huge
    local lastSparkleTime = 0
    local lastNumLit = 0
    local castDirection = "right"

    local preview = { container = container, ringFrame = ringF }

    local function PreviewWedgeAt(k)
        if castDirection == "left" and k > 1 then
            return NUM_CAST_SEGMENTS - k + 2
        end
        return k
    end

    local function GetVirtualCursor(t)
        local cw, ch = container:GetWidth() or 1, container:GetHeight() or 1
        local margin = 24
        local rx = mathmax(8, (cw  - margin*2) / 2)
        local ry = mathmax(8, (ch - margin*2) / 2)
        local r = mathmin(rx, ry) * 0.85
        local cx, cy = cw/2, ch/2
        -- Lissajous: speeds distintos en x/y para variar el path y que el
        -- trail/sparkle se vean ondulando, no solo girando en circulo.
        local x = cx + r * math.sin(t * 0.8)
        local y = cy + r * math.sin(t * 1.3) * 0.7
        return x, y
    end

    local function ApplyAll()
        local s = ns.db and ns.db.cursorRing
        if not s then return end

        -- Ring decorativo. La alpha final = opacity * focusMask.ring para dim de
        -- las features no enfocadas (configurable via FOCUS_MASKS).
        local size = s.size or 48
        ringF:SetSize(size, size)
        if s.enabled then
            ringF.tex:Show()
            ringF.tex:SetTexture(ResolveTexture(s.texture or DEFAULT_TEXTURE))
            local r, g, b = GetEffectiveColor(s)
            ringF.tex:SetVertexColor(r, g, b, (s.opacity or 1) * focusMask.ring)
        else
            ringF.tex:Hide()
        end

        -- Cast. SetAlpha en castFrame multiplica todas las wedges hijas, asi el
        -- dim afecta tanto a las "lit" (alpha=castOpacity) como a las "off" (0).
        local cast = s.cast or {}
        local cc = cast.color or { r=0.2, g=0.82, b=0.68 }
        for i = 1, NUM_CAST_SEGMENTS do
            ringF.castSegments[i]:SetVertexColor(cc.r or 1, cc.g or 1, cc.b or 1, 1)
        end
        local castSize = cast.size or size
        if castSize < 4 then castSize = 4 end
        ringF.castFrame:SetSize(castSize, castSize)
        ringF.castFrame:SetAlpha(focusMask.cast)
        if cast.enabled then ringF.castFrame:Show() else ringF.castFrame:Hide() end

        local newDir = cast.direction or "right"
        if newDir ~= "left" then newDir = "right" end
        if newDir ~= castDirection then
            castDirection = newDir
            for i = 1, NUM_CAST_SEGMENTS do ringF.castSegments[i]:SetAlpha(0) end
            lastNumLit = 0
        end

        -- Dot + FX (trail/sparkle): comparten focusMask.dot. SetAlpha en fxF
        -- multiplica todas las particulas vivas; el fade per-particula sigue
        -- funcionando (su SetAlpha animado se multiplica).
        local dot = s.dot or {}
        if dot.enabled then
            local dsize = dot.size or 6
            if dsize < 1 then dsize = 1 end
            ringF.dotTex:SetSize(dsize, dsize)
            local dc = dot.color or { r=1, g=1, b=1, a=1 }
            ringF.dotTex:SetVertexColor(dc.r or 1, dc.g or 1, dc.b or 1, (dc.a or 1) * focusMask.dot)
            ringF.dotTex:Show()
        else
            ringF.dotTex:Hide()
        end
        fxF:SetAlpha(focusMask.dot)
    end

    preview.Refresh = ApplyAll

    container:SetScript("OnUpdate", function()
        local s = ns.db and ns.db.cursorRing
        if not s then return end

        local t = GetTime() - startTime
        local x, y = GetVirtualCursor(t)

        ringF:ClearAllPoints()
        ringF:SetPoint("CENTER", container, "BOTTOMLEFT", x, y)

        local dot = s.dot or {}
        local now = GetTime()

        -- Trail
        if dot.enabled and dot.trail then
            local dx = x - lastTrailX
            local dy = y - lastTrailY
            if (dx*dx + dy*dy) >= TRAIL_MIN_MOVE_SQ and (now - lastTrailTime) >= TRAIL_SPAWN_INTERVAL then
                local e = AcquireFX()
                e.kind = "trail"
                e.born = now
                e.lifetime = dot.trailLength or TRAIL_LIFETIME
                local sz = (dot.size or 6) * 1.2
                e.startSize = sz
                e.tex:SetSize(sz, sz)
                e.tex:ClearAllPoints()
                e.tex:SetPoint("CENTER", container, "BOTTOMLEFT", x, y)
                e.tex:SetTexture(DOT_TEXTURE)
                local c = dot.trailColor or dot.color or {r=1,g=1,b=1,a=1}
                e.tex:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
                e.tex:SetAlpha(1); e.tex:SetRotation(0); e.tex:Show()
                lastTrailX, lastTrailY = x, y
                lastTrailTime = now
            end
        end

        -- Sparkle
        if dot.enabled and dot.sparkle and (now - lastSparkleTime) >= SPARKLE_SPAWN_INTERVAL then
            local function SpawnAt(sx, sy)
                local e = AcquireFX()
                e.kind = "sparkle"
                e.born = now
                e.lifetime = SPARKLE_LIFETIME
                local ang = math.random() * 6.2831853
                local dist = math.random() * SPARKLE_MAX_RADIUS
                local fx, fy = sx + math.cos(ang) * dist, sy + math.sin(ang) * dist
                local base = dot.size or 6
                local mult = dot.sparkleSize or 1.0
                e.startSize = base * 0.6 * mult
                e.endSize = base * 1.6 * mult
                e.tex:SetSize(e.startSize, e.startSize)
                e.tex:ClearAllPoints()
                e.tex:SetPoint("CENTER", container, "BOTTOMLEFT", fx, fy)
                e.tex:SetTexture(PickSparkleTexture(dot.sparkleShape or "dot"))
                local c = dot.sparkleColor or dot.color or {r=1,g=1,b=1,a=1}
                e.tex:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
                e.tex:SetAlpha(1)
                e.tex:SetRotation(math.random() * 6.2831853)
                e.tex:Show()
            end
            if lastSparkleX <= -math.huge or (now - lastSparkleTime) > SPARKLE_RESET_GAP then
                SpawnAt(x, y)
            else
                local dx = x - lastSparkleX
                local dy = y - lastSparkleY
                local dist = math.sqrt(dx*dx + dy*dy)
                local n = mathfloor(dist / SPARKLE_PATH_SPACING) + 1
                if n < 1 then n = 1 end
                if n > SPARKLE_MAX_PER_TICK then n = SPARKLE_MAX_PER_TICK end
                for i = 1, n do
                    local tt = i / n
                    SpawnAt(lastSparkleX + dx * tt, lastSparkleY + dy * tt)
                end
            end
            lastSparkleX, lastSparkleY = x, y
            lastSparkleTime = now
        end

        -- FX fade (todos los entries del pool)
        for i = 1, #fxPool do
            local e = fxPool[i]
            if e.tex:IsShown() then
                local age = now - e.born
                if age >= e.lifetime then
                    e.tex:Hide()
                else
                    local p = age / e.lifetime
                    if e.kind == "trail" then
                        e.tex:SetAlpha(1 - p)
                        local sz = e.startSize * (1 - 0.5 * p)
                        e.tex:SetSize(sz, sz)
                    else
                        local sz = e.startSize + (e.endSize - e.startSize) * p
                        e.tex:SetSize(sz, sz)
                        e.tex:SetAlpha(1 - p)
                    end
                end
            end
        end

        -- Cast progress simulation: cycle de 10s = cast 3s -> idle 2s -> channel
        -- drain 3s -> idle 2s. Demuestra fill clockwise/counter y drain.
        local cast = s.cast or {}
        if cast.enabled then
            local cycle = 10
            local phase = t % cycle
            local progress, lit
            if phase < 3 then
                progress = phase / 3; lit = true
            elseif phase < 5 then
                progress = 0; lit = false
            elseif phase < 8 then
                progress = 1 - ((phase - 5) / 3); lit = true
            else
                progress = 0; lit = false
            end
            if not lit then
                if lastNumLit > 0 then
                    for i = 1, NUM_CAST_SEGMENTS do ringF.castSegments[i]:SetAlpha(0) end
                    lastNumLit = 0
                end
            else
                local castOpacity = cast.opacity or 1
                local numLit = mathfloor(progress * NUM_CAST_SEGMENTS + 0.5)
                if numLit ~= lastNumLit then
                    if numLit > lastNumLit then
                        for i = lastNumLit + 1, numLit do ringF.castSegments[PreviewWedgeAt(i)]:SetAlpha(castOpacity) end
                    else
                        for i = numLit + 1, lastNumLit do ringF.castSegments[PreviewWedgeAt(i)]:SetAlpha(0) end
                    end
                    lastNumLit = numLit
                end
            end
        else
            if lastNumLit > 0 then
                for i = 1, NUM_CAST_SEGMENTS do ringF.castSegments[i]:SetAlpha(0) end
                lastNumLit = 0
            end
        end
    end)

    container:HookScript("OnSizeChanged", ApplyAll)
    container:HookScript("OnShow", ApplyAll)
    table.insert(previewRegistry, preview)

    C_Timer.After(0, ApplyAll)
    return preview
end

NotifyCursorRingPreviews = function()
    for _, p in ipairs(previewRegistry) do
        if p.container:IsShown() then p.Refresh() end
    end
end
