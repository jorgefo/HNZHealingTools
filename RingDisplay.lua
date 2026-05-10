local _, ns = ...

local displayAnchor
local ringPool = {}
local dataElapsed = 0
local isVisible = true

local function CreateRingFrame(parent, index)
    local db = ns.db.ringDisplay
    local radius = db.baseRadius + (index-1) * (db.ringThickness + db.ringSpacing)
    local numSegs = db.numSegments
    local thickness = db.ringThickness

    local ring = CreateFrame("Frame",nil,parent)
    ring:SetSize(radius*2+thickness, radius*2+thickness)
    ring:SetPoint("CENTER",parent,"CENTER")
    ring:EnableMouse(false)

    ring.lines = {}
    ring.radius = radius

    for i = 1, numSegs do
        local a1 = (i-1)*(2*math.pi/numSegs) - (math.pi/2)
        local a2 = i*(2*math.pi/numSegs) - (math.pi/2)
        local line = ring:CreateLine(nil,"ARTWORK",nil,index)
        line:SetThickness(thickness)
        line:SetStartPoint("CENTER",ring,math.cos(a1)*radius,math.sin(a1)*radius)
        line:SetEndPoint("CENTER",ring,math.cos(a2)*radius,math.sin(a2)*radius)
        line:SetColorTexture(1,1,1,1)
        ring.lines[i] = line
    end

    -- Icon at top
    local iconSize = math.max(thickness+4, 14)
    local iconFrame = CreateFrame("Frame",nil,ring)
    iconFrame:SetSize(iconSize,iconSize); iconFrame:SetPoint("CENTER",ring,"CENTER",0,radius)
    iconFrame:EnableMouse(false)
    local iconBg = iconFrame:CreateTexture(nil,"BACKGROUND"); iconBg:SetAllPoints(); iconBg:SetColorTexture(0,0,0,0.8)
    local iconTex = iconFrame:CreateTexture(nil,"ARTWORK")
    iconTex:SetPoint("TOPLEFT",1,-1); iconTex:SetPoint("BOTTOMRIGHT",-1,1); iconTex:SetTexCoord(0.08,0.92,0.08,0.92)
    ring.iconTex = iconTex; ring.iconFrame = iconFrame; iconFrame:Hide()

    ring:Hide()
    return ring
end

local function GetOrCreateRing(index)
    if ringPool[index] then return ringPool[index] end
    local ring = CreateRingFrame(displayAnchor, index)
    ringPool[index] = ring
    return ring
end

local function SetRingColor(ring, r, g, b, a)
    for _, line in ipairs(ring.lines) do line:SetColorTexture(r,g,b,a or 1) end
end

local function SetRingProgress(ring, progress)
    local n = #ring.lines
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end
    local pos = progress * n
    local full = math.floor(pos)
    local frac = pos - full
    for i = 1, n do
        local line = ring.lines[i]
        if i <= full then
            line:SetShown(true); line:SetAlpha(1)
        elseif i == full + 1 and frac > 0 then
            line:SetShown(true); line:SetAlpha(frac)
        else
            line:SetShown(false)
        end
    end
end

local function DestroyAllRings()
    for _, ring in pairs(ringPool) do
        for _, line in ipairs(ring.lines) do line:Hide() end
        ring:Hide(); ring:ClearAllPoints()
    end
    wipe(ringPool)
end

-- Reportado por UpdateRings: true si algun aura tiene timer ticking. El OnUpdate
-- lo usa para decidir entre fast poll (anillo cuenta atras visible) y idle poll.
local hasActiveTimer = false

local function UpdateRings()
    local db = ns.db
    local ringIndex = 0
    local anyTimer = false

    for i, entry in ipairs(db.ringAuras) do
        if entry.enabled and ns.IsEntryAllowedForCurrentSpec(entry) and ns.IsEntryAllowedForRequiredTalent(entry) then
            local status = ns:GetAuraStatus(entry.spellID, entry.unit, entry.filter, entry.manualDuration)
            if status.remaining and status.remaining > 0 then anyTimer = true end

            local showWhen = entry.showWhen or "ACTIVE"
            local show = false
            if showWhen=="ALWAYS" then show=true
            elseif showWhen=="ACTIVE" then show=(status.status=="ACTIVE")
            elseif showWhen=="MISSING" then show=(status.status=="MISSING")
            elseif showWhen=="BELOW_STACKS" then show=(status.status=="MISSING") or (status.stacks<(entry.minStacks or 0))
            end

            if show then
                ringIndex = ringIndex + 1
                local ring = GetOrCreateRing(ringIndex)
                local color = entry.color or {r=1,g=1,b=1,a=1}

                if status.status == "ACTIVE" then
                    SetRingColor(ring, color.r, color.g, color.b, color.a)
                    local progress = 1.0
                    local dur = status.duration or 0
                    local rem = status.remaining or 0
                    if dur > 0 and rem > 0 then
                        progress = rem / dur
                    elseif entry.manualDuration and entry.manualDuration > 0 then
                        -- Last-resort manual tracking from first time we saw it active
                        if not entry._manualStart then entry._manualStart = GetTime() end
                        local r2 = entry.manualDuration - (GetTime() - entry._manualStart)
                        if r2 < 0 then r2 = 0 end
                        progress = r2 / entry.manualDuration
                    end
                    SetRingProgress(ring, progress)
                else
                    entry._manualStart = nil
                    SetRingColor(ring, color.r*0.3, color.g*0.3, color.b*0.3, 0.3)
                    SetRingProgress(ring, 1.0)
                end

                if entry.showIcon then ring.iconTex:SetTexture(status.icon); ring.iconFrame:Show()
                else ring.iconFrame:Hide() end

                ring:Show()
            else
                entry._manualStart = nil
            end
        end
    end

    for i = ringIndex+1, #ringPool do if ringPool[i] then ringPool[i]:Hide() end end

    hasActiveTimer = anyTimer
end

local inCombat = false

local function ApplyRingVisibility()
    if not displayAnchor then return end
    local shouldShow = isVisible and ns.db.ringDisplay.enabled
        and ns.MatchesVisibility(ns.db.ringDisplay.visibility, inCombat)
    displayAnchor:SetShown(shouldShow and true or false)
end

function ns:InitRingDisplay()
    displayAnchor = CreateFrame("Frame","HNZHealingToolsRingFrame",UIParent)
    displayAnchor:SetFrameStrata("BACKGROUND"); displayAnchor:SetFrameLevel(1)
    displayAnchor:SetSize(2,2)
    displayAnchor:SetPoint("CENTER",UIParent,"CENTER",ns.db.ringDisplay.offsetX,ns.db.ringDisplay.offsetY)
    displayAnchor:SetAlpha(ns.db.ringDisplay.opacity); displayAnchor:EnableMouse(false)

    inCombat = UnitAffectingCombat("player") and true or false
    ApplyRingVisibility()

    -- Track combat state from the events themselves, not InCombatLockdown(): the
    -- lockdown flag only "roughly" matches PLAYER_REGEN_DISABLED/ENABLED and can
    -- briefly disagree, leaving the display stuck hidden after combat starts.
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    combatFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then inCombat = false
        elseif event == "PLAYER_ENTERING_WORLD" then inCombat = UnitAffectingCombat("player") and true or false
        end
        ApplyRingVisibility()
    end)

    displayAnchor:SetScript("OnUpdate", function(self, elapsed)
        if not isVisible or not ns.db.ringDisplay.enabled then return end
        if #ns.db.ringAuras == 0 then return end
        dataElapsed = dataElapsed + elapsed
        -- Polling event-driven: antes UpdateRings corria a updateInterval (default
        -- 0.05s = 20 Hz) recorriendo todas las ringAuras y llamando GetAuraStatus
        -- (que llama C_Spell.GetSpellInfo + UnitAura) cada tick, incluso sin auras
        -- activas y sin que ningun evento UNIT_AURA hubiera disparado. Ahora:
        --   - Si auraDirty o algun aura ticking => poll a updateInterval
        --   - Idle => 1 Hz fallback
        local interval = (ns._auraDirtyRing or hasActiveTimer)
            and ns.db.ringDisplay.updateInterval or 1.0
        if dataElapsed >= interval then
            dataElapsed = 0
            ns._auraDirtyRing = false
            UpdateRings()
        end
    end)
end

function ns:ToggleRingDisplay() isVisible = not isVisible; ApplyRingVisibility() end

function ns:RefreshRingDisplay()
    if displayAnchor then
        displayAnchor:SetAlpha(ns.db.ringDisplay.opacity)
        displayAnchor:ClearAllPoints()
        displayAnchor:SetPoint("CENTER",UIParent,"CENTER",ns.db.ringDisplay.offsetX,ns.db.ringDisplay.offsetY)
    end
    ApplyRingVisibility()
end

function ns:RebuildRingDisplay() DestroyAllRings(); ns:MarkAuraDirty() end

function ns:DumpRingStatus()
    print("|cff00ccff[SAT ring]|r")
    if not displayAnchor then print("  displayAnchor: nil (not initialized)"); return end
    print(string.format("  displayAnchor:IsShown=%s  IsVisible=%s  alpha=%.2f",
        tostring(displayAnchor:IsShown()), tostring(displayAnchor:IsVisible()), displayAnchor:GetAlpha()))
    print(string.format("  isVisible(local)=%s  enabled=%s  visibility=%s  inCombat(local)=%s  InCombatLockdown=%s  UnitAffectingCombat=%s",
        tostring(isVisible), tostring(ns.db.ringDisplay.enabled),
        tostring(ns.db.ringDisplay.visibility), tostring(inCombat),
        tostring(InCombatLockdown()), tostring(UnitAffectingCombat("player"))))
    print(string.format("  ringPool=%d  ringAuras=%d  dataElapsed=%.3f  updateInterval=%.3f",
        #ringPool, #ns.db.ringAuras, dataElapsed, ns.db.ringDisplay.updateInterval))
end
