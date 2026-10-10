


























local ThugUI = _G.ThugUI
local Orbs = {}
Orbs.testMode = false
ThugUI.Orbs = Orbs
ThugUI:RegisterModule("Orbs", Orbs)

local KEYS = { "health", "resource" }
local pipsWereUnlocked = false

function Orbs:IsTestMode()
    return self.testMode == true
end

function Orbs:SetTestMode(on)
    on = on and true or false
    if self.testMode == on then return end
    self.testMode = on

    for _, key in ipairs(KEYS) do
        self:ApplyLock(key)
    end
    self:UpdateAlpha()

    if ThugUI.ResourcePips then
        local RP = ThugUI.ResourcePips
        if on then
            pipsWereUnlocked = RP.unlocked
            RP:Refresh()
            RP:SetUnlocked(true)
        else
            RP:Refresh()
            RP:SetUnlocked(pipsWereUnlocked)
        end
    end

    if on then
        local w = ThugUI.Window and ThugUI.Window.frame
        if w and not self.testHooked then
            self.testHooked = true
            
            w:HookScript("OnHide", function() Orbs:SetTestMode(false) end)
        end
    end

    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("ORBS", "test mode %s", on and "on" or "off")
        if on and ThugUI.ResourcePips and ThugUI.ResourcePips.DebugState then
            ThugUI.Diagnostics:Log("ORBS", "test pips: %s", ThugUI.ResourcePips:DebugState())
        end
    end
end

local MEDIA = "Interface\\AddOns\\ThugUI\\media\\orb\\"
local ORB_SIZE = 224                 


local DECOR_ATLAS = {
    gryphon = { left = "ui-hud-actionbar-gryphon-left", right = "ui-hud-actionbar-gryphon-right" },
    wyvern  = { left = "ui-hud-actionbar-wyvern-left",  right = "ui-hud-actionbar-wyvern-right" },
}

local function OrbDefaults(colorMode)
    return {
        enabled = true,
        direction = "up",
        bgAlpha = 0.6,
        glass = true,
        ring = true,         
        ringArt = "orb",
        ringBlend = "auto",
        ringAlpha = 1,
        ringScale = 1.0,     
        ringX = 0, ringY = 0,
        ringColor = { 1, 1, 1 },
        ringSpin = 0,
        ringDesat = false,
        colorMode = colorMode,
        customColor = { 1, 1, 1 },
        artPath = "",
        artSize = 160,
        artX = 0,
        artY = 0,
        oocAlpha = 1.0,
        
        scale = 0.55,
        
        
        orbShow = true, orbX = 0, orbY = 0, orbAlpha = 1,
        orbScale = 1.0,      
        locked = true,
        unitPoint = nil,     
        
        decor = "faction",   
        decorShow = true, decorAlpha = 1,
        decorScale = 1.0,    
        decorX = 0,
        decorY = 0,
        decorFront = false,  
        decorColor = { 1, 1, 1 },
        
        artShow = true, artScale = 1, artAlpha = 1,
        hideWhenFull = false,
        showInCombat = false, 
        
        
        
        
        
        timerOn = false,
        timerRing = "cast",
        timerFill = "fill",   
        timerTrack = 0.3,     
        timer2On = false,
        timer2 = "gcd",
        timer2Fill = "fill",
        timer2Art = "orb",
        timer2Scale = 1.15,   
        timer2Color = { 1, 1, 1 },
        timer2Alpha = 1,
        timer2Track = 0.25,   
        
        
        
        timerAlwaysShow = false,
    }
end



ThugUI.defaults.Orbs = {
    health = OrbDefaults("green"),
    resource = OrbDefaults("power"),
}

ThugUI.defaults.Orbs.health.decorX = -70
ThugUI.defaults.Orbs.resource.decorX = 70
ThugUI.defaults.Orbs.health.unitPoint = nil

local function Cfg(key) return ThugUIDB.Orbs[key] end
local frames = {}   
local units = {}    

local function InCombat()
    local ER = ThugUI.EssentialRings
    if ER and ER.IsInCombat then return ER:IsInCombat() end
    return InCombatLockdown()
end

local function IsPoint(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
end

local function Unpack3(t, a, b, c)
    if type(t) == "table" then return t[1] or a, t[2] or b, t[3] or c end
    return a, b, c
end






function Orbs:SeedRingFromRim(c)
    if not c or c.ringSeeded == true then return end
    
    
    if c.ring ~= true then
        c.ring = (c.rim ~= false)
        c.ringArt = "orb"
        c.ringScale = 1.0
        c.ringX, c.ringY = 0, 0
        if type(c.rimColor) == "table" and type(c.rimColor[1]) == "number" and type(c.rimColor[2]) == "number" and type(c.rimColor[3]) == "number" then
            c.ringColor = { c.rimColor[1], c.rimColor[2], c.rimColor[3] }
        else
            c.ringColor = { 1, 1, 1 }
        end
        c.ringBlend = "auto"
        c.ringAlpha = 1
        c.ringSpin = 0
    end
    c.ringSeeded = true
    c.rim, c.rimColor = nil, nil
end








local CORNER = { health = "BOTTOMLEFT", resource = "BOTTOMRIGHT" }

function Orbs:ApplyPosition(key)
    local u = units[key]
    if not u then return end
    if InCombatLockdown() then
        u.pendingPosition = true
        return
    end
    u.pendingPosition = false
    local c = Cfg(key)
    local s = tonumber(c.scale) or 1
    if s <= 0 then s = 1 end
    u:SetScale(s)
    
    
    local p = IsPoint(c.unitPoint) and c.unitPoint or { x = 90, y = 20 }
    local corner = CORNER[key]
    local sx = (corner == "BOTTOMRIGHT") and -1 or 1
    u:ClearAllPoints()
    u:SetPoint(corner, UIParent, corner, sx * p.x / s, p.y / s)
end


local function MeasureUnit(key)
    local u = units[key]
    local s = u:GetScale() or 1
    local left, bottom, right = u:GetLeft(), u:GetBottom(), u:GetRight()
    if not (left and bottom and right) then return nil end
    if CORNER[key] == "BOTTOMRIGHT" then
        return { x = (UIParent:GetWidth() or 0) - right * s, y = bottom * s }
    end
    return { x = left * s, y = bottom * s }
end
Orbs.MeasureUnit = MeasureUnit

function Orbs:ResetPosition(key)
    Cfg(key).unitPoint = nil
    self:ApplyPosition(key)
end



function Orbs:ApplyLock(key)
    local u = units[key]
    if not u then return end
    local locked = Cfg(key).locked ~= false and not self.testMode
    u:EnableMouse(not locked)
    u:SetMovable(not locked)
    if locked then
        u:RegisterForDrag()
        u.outline:Hide()
    else
        u:RegisterForDrag("LeftButton")
        u.outline:Show()
    end
end

function Orbs:SetLocked(key, locked)
    Cfg(key).locked = locked and true or false
    self:ApplyLock(key)
end





function Orbs:ApplySettings(key)
    local f, u = frames[key], units[key]
    if not f or not u then return end
    local c = Cfg(key)
    
    
    
    f.lastPowerToken = nil

    if not c.enabled then
        u:Hide()
        return
    end
    u:Show()

    if InCombatLockdown() then
        u.pendingSettings = true
        self:Update(key)
        return
    end
    u.pendingSettings = false

    self:ApplyDecor(key)

    
    
    
    
    
    
    local orbScale = tonumber(c.orbScale) or 1
    if orbScale <= 0 then orbScale = 1 end
    f:SetScale(orbScale)
    
    
    f:ClearAllPoints()
    f:SetPoint("CENTER", u, "CENTER", (tonumber(c.orbX) or 0) / orbScale, (tonumber(c.orbY) or 0) / orbScale)

    f.bg:SetColorTexture(0, 0, 0, c.bgAlpha or 0.6)
    f.glass:SetShown(c.glass ~= false)
    
    
    f.body:SetShown(c.orbShow ~= false)

    self:ApplyTimerRings(key)

    if c.ring ~= false then
        local ringScale = tonumber(c.ringScale)
        if not ringScale or ringScale <= 0 then ringScale = 1.0 end
        local rSize = ORB_SIZE * ringScale
        f.ring:SetSize(rSize, rSize)
        f.ring:ClearAllPoints()
        f.ring:SetPoint("CENTER", f.ringFrame, "CENTER", 0, 0)
        f.ringFrame:ClearAllPoints()
        f.ringFrame:SetPoint("CENTER", f, "CENTER", c.ringX or 0, c.ringY or 0)
        ThugUI.RingArt:Apply(f.ring, {
            art = c.ringArt,
            blend = c.ringBlend,
            color = c.ringColor,
            alpha = tonumber(c.ringAlpha) or 1,
            spin = tonumber(c.ringSpin) or 0,
            desat = c.ringDesat,
        })
        f.ring:Show()
        f.ringFrame:Show()
    else
        f.ring:Hide()
        f.ringFrame:Hide()
        if f.ring.ringGroup then f.ring.ringGroup:Stop() end
    end

    if type(c.artPath) == "string" and c.artPath ~= "" and c.artShow ~= false then
        f.art:SetTexture(c.artPath)
        f.art:SetSize(c.artSize or 160, c.artSize or 160)
        local artScale = tonumber(c.artScale) or 1
        if artScale <= 0 then artScale = 1 end
        f.artFrame:SetScale(artScale)
        f.artFrame:ClearAllPoints()
        f.artFrame:SetPoint("CENTER", f, "CENTER", (c.artX or 0) / artScale, (c.artY or 0) / artScale)
        f.art:Show()
        f.artFrame:Show()
    else
        f.art:Hide()
        f.artFrame:Hide()
    end

    
    
    if f.fill.SetRenderMode and Enum.StatusBarRenderMode then
        pcall(f.fill.SetRenderMode, f.fill, Enum.StatusBarRenderMode.Linear)
    end
    local standard = Enum.StatusBarFillStyle and Enum.StatusBarFillStyle.Standard or 0
    local center = Enum.StatusBarFillStyle and Enum.StatusBarFillStyle.Center or 2
    local dir = c.direction or "up"
    local orient, reverse, style = "VERTICAL", false, standard
    if dir == "down" then reverse = true
    elseif dir == "right" then orient = "HORIZONTAL"
    elseif dir == "left" then orient, reverse = "HORIZONTAL", true
    elseif dir == "center" then style = center
    end
    f.fill:SetOrientation(orient)
    if f.fill.SetReverseFill then pcall(f.fill.SetReverseFill, f.fill, reverse) end
    if f.fill.SetFillStyle then pcall(f.fill.SetFillStyle, f.fill, style) end

    self:ApplyPosition(key)
    self:ApplyLock(key)
    self:UpdateAlpha()
    self:Update(key)
end





function Orbs:ApplyDecor(key)
    local u = units[key]
    if not u then return end
    local c = Cfg(key)
    local kind = c.decor or "faction"
    if kind == "faction" then
        kind = (UnitFactionGroup and UnitFactionGroup("player") == "Horde") and "wyvern" or "gryphon"
    end
    local set = DECOR_ATLAS[kind]
    local atlas = set and set[key == "resource" and "right" or "left"]
    local info = atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    
    
    if not self["loggedDecor_" .. key] and ThugUI.Diagnostics then
        self["loggedDecor_" .. key] = true
        ThugUI.Diagnostics:Log("ORBS", "decor %s: setting=%s kind=%s atlas=%s info=%s scale=%s at %s,%s front=%s",
            key, tostring(c.decor), tostring(kind), tostring(atlas), info and "yes" or "NO",
            tostring(c.decorScale), tostring(c.decorX), tostring(c.decorY), tostring(c.decorFront))
    end
    if not info or c.decorShow == false then
        u.decorFrame:Hide()
        u.decor:Hide()
        return
    end
    local scale = tonumber(c.decorScale) or 1
    u.decor:SetAtlas(atlas)
    u.decor:SetSize((info.width or 128) * scale, (info.height or 128) * scale)
    u.decor:ClearAllPoints()
    u.decor:SetPoint("CENTER", u.decorFrame, "CENTER", c.decorX or 0, c.decorY or 0)
    u.decor:SetVertexColor(Unpack3(c.decorColor, 1, 1, 1))
    
    local orb = frames[key]
    if c.decorFront and orb and orb.artFrame then
        u.decorFrame:SetFrameLevel(orb.artFrame:GetFrameLevel() + 1)
    else
        u.decorFrame:SetFrameLevel(u:GetFrameLevel())
    end
    u.decor:Show()
    u.decorFrame:Show()
end



local VKEY = { health = "orbHealth", resource = "orbResource" }






local function CombatForced(key)
    if not Cfg(key).showInCombat then return false end
    local V = ThugUI.Visibility
    if V then return V:InCombat() end
    return InCombat()
end

function Orbs:UpdateAlpha()
    for _, key in ipairs(KEYS) do
        if frames[key] and Cfg(key).enabled then self:ApplyAlpha(key) end
    end
end





local function SetBar(bar, current, maximum)
    bar:SetMinMaxValues(0, maximum)
    local ease = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
    if ease then bar:SetValue(current, ease) else bar:SetValue(current) end
end



local REST_AT_EMPTY = {
    RAGE = true, RUNIC_POWER = true, LUNAR_POWER = true, MAELSTROM = true,
    INSANITY = true, FURY = true, PAIN = true,
}

local function LogOnce(flag, fmt, ...)
    if Orbs[flag] then return end
    Orbs[flag] = true
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("ORBS", fmt, ...) end
end








local function Step(points)
    local curve = C_CurveUtil.CreateCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    curve:SetPoints(points)
    return curve
end

local restCurves = {}   
Orbs.restCurves = restCurves

local function RestCurve(key, atEmpty, restAlpha)
    local set = restCurves[key]
    if not set then return nil end
    if atEmpty then
        if set.emptyY ~= restAlpha then
            set.empty = Step({ { x = 0, y = restAlpha }, { x = 0.005, y = 1 } })
            set.emptyY = restAlpha
        end
        return set.empty
    end
    if set.fullY ~= restAlpha then
        set.full = Step({ { x = 0, y = 1 }, { x = 1, y = restAlpha } })
        set.fullY = restAlpha
    end
    return set.full
end





local function Flag(fn)
    if not fn then return false end
    local ok, v = pcall(fn, "player")
    if not ok or (issecretvalue and issecretvalue(v)) then return false end
    return v and true or false
end

local function Suppressed()
    return Flag(UnitIsDeadOrGhost) or Flag(UnitOnTaxi)
end
Orbs.Suppressed = Suppressed













function Orbs:ApplyAlpha(key)
    self:ApplyAlphaRaw(key)
    self:ApplyTimerVisibility(key)
end








function Orbs:ApplyTimerVisibility(key)
    local f = frames[key]
    if not (f and f.timerCD) then return end
    local c = Cfg(key)
    local always = c.timerAlwaysShow == true and not self.testMode
    local one = always and f.timerCD:IsShown() and true or false
    local two = always and f.timer2CD:IsShown() and true or false
    local function Ignore(frame, on)
        frame.thugIgnoreParent = on
        if frame.SetIgnoreParentAlpha then pcall(frame.SetIgnoreParentAlpha, frame, on) end
    end
    Ignore(f.ringFrame, one)
    Ignore(f.timer2Frame, two)
    
    
    if one then f.ringFrame:SetAlpha(1) end
end

function Orbs:ApplyAlphaRaw(key)
    local f, u = frames[key], units[key]
    if not (f and u) then return end
    local c = Cfg(key)
    local decor = u.decorFrame
    local V = ThugUI.Visibility

    
    
    
    
    local K = (key == "health") and "Health" or "Resource"
    local visDecor = V and V:Alpha("orb" .. K .. "Decor") or 1
    local visOrb   = V and V:Alpha("orb" .. K .. "Orb") or 1
    local visRing  = V and V:Alpha("orb" .. K .. "Ring") or 1
    local visArt   = V and V:Alpha("orb" .. K .. "Art") or 1

    local decorAlpha = (tonumber(c.decorAlpha) or 1) * visDecor
    local orbAlpha   = (tonumber(c.orbAlpha) or 1) * visOrb
    local artAlpha   = (tonumber(c.artAlpha) or 1) * visArt
    
    local ringAlpha  = visRing

    
    if self.testMode then
        u:SetAlpha(1)
        f.body:SetAlpha(tonumber(c.orbAlpha) or 1)
        if decor then decor:SetAlpha(tonumber(c.decorAlpha) or 1) end
        f.ringFrame:SetAlpha(1)
        if f.artFrame then f.artFrame:SetAlpha(tonumber(c.artAlpha) or 1) end
        return
    end

    if Suppressed() then
        u:SetAlpha(0)
        return
    end

    local vis = V and V:Alpha(VKEY[key]) or 1
    local override = V and V:IsOverrideShown(VKEY[key]) or false

    local unitAlpha = vis
    if CombatForced(key) then
        unitAlpha = 1
    elseif c.hideWhenFull then
        local atEmpty = false
        if key == "resource" then
            local _, token = ThugUI.ResourceRing:GetPowerType()
            atEmpty = REST_AT_EMPTY[token] and true or false
        end
        
        
        
        local curve = RestCurve(key, atEmpty, override and vis or 0)
        if curve then
            local ok, alpha
            if key == "health" then
                ok, alpha = pcall(UnitHealthPercent, "player", true, curve)
            else
                local pt = ThugUI.ResourceRing:GetPowerType()
                ok, alpha = pcall(UnitPowerPercent, "player", pt, false, curve)
            end
            
            
            if ok and pcall(u.SetAlpha, u, alpha) then
                f.body:SetAlpha(orbAlpha)
                if decor then decor:SetAlpha(decorAlpha) end
                f.ringFrame:SetAlpha(ringAlpha)
                if f.artFrame then f.artFrame:SetAlpha(artAlpha) end
                return
            end
            LogOnce("loggedCurveErr", "percent API refused the curve: %s", tostring(alpha))
        end
    end
    u:SetAlpha(unitAlpha)
    f.body:SetAlpha(orbAlpha)
    if decor then decor:SetAlpha(decorAlpha) end
    f.ringFrame:SetAlpha(ringAlpha)
    if f.artFrame then f.artFrame:SetAlpha(artAlpha) end
end

function Orbs:Update(key)
    local f = frames[key]
    if not f then return end
    local c = Cfg(key)
    if not c.enabled then return end
    
    
    
    
    if ThugUI.moduleOn and ThugUI.UnitFrames and not self.testMode and not ThugUI.UnitFrames:Active() then
        f:Hide()
        return
    end

    if key == "health" then
        local max = UnitHealthMax("player")
        if not (issecretvalue and issecretvalue(max)) and (max or 0) <= 0 then
            f:Hide()
            return
        end
        SetBar(f.fill, UnitHealth("player"), max)
        if f.lastPowerToken ~= "HEALTH" then
            f.lastPowerToken = "HEALTH"
            local r, g, b = 0.1, 0.8, 0.1
            if c.colorMode == "class" then
                local _, class = UnitClass("player")
                local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                if rc then r, g, b = rc.r, rc.g, rc.b end
            elseif c.colorMode == "custom" then
                r, g, b = Unpack3(c.customColor, 1, 1, 1)
            end
            f.fill:SetStatusBarColor(r, g, b)
        end
        f:Show()
    else
        local pt, token = ThugUI.ResourceRing:GetPowerType()
        local max = UnitPowerMax("player", pt)
        if not (issecretvalue and issecretvalue(max)) and (max or 0) <= 0 then
            f:Hide()
            return
        end
        SetBar(f.fill, UnitPower("player", pt), max)
        if token ~= f.lastPowerToken then
            f.lastPowerToken = token
            local r, g, b = ThugUI.ResourceRing:GetColor(token)
            if c.colorMode == "class" then
                local _, class = UnitClass("player")
                local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                if rc then r, g, b = rc.r, rc.g, rc.b end
            elseif c.colorMode == "custom" then
                r, g, b = Unpack3(c.customColor, 1, 1, 1)
            end
            f.fill:SetStatusBarColor(r, g, b)
        end
        f:Show()
    end

    self:ApplyAlpha(key)
end

function Orbs:ForceColor(key)
    if frames[key] then frames[key].lastPowerToken = nil end
    self:Update(key)
end





function Orbs:Build(key)
    if frames[key] then return frames[key] end
    local right = (key == "resource")

    
    local u = CreateFrame("Frame", right and "ThugUI_OrbUnit_Resource" or "ThugUI_OrbUnit_Health", UIParent)
    u:SetSize(ORB_SIZE, ORB_SIZE)
    u:SetFrameStrata("MEDIUM")
    u:SetClampedToScreen(true)
    u:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    u:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p = MeasureUnit(key)
        if p then Cfg(key).unitPoint = p end
        Orbs:ApplyPosition(key)
    end)

    
    local decorFrame = CreateFrame("Frame", nil, u)
    decorFrame:SetAllPoints(u)
    local decor = decorFrame:CreateTexture(nil, "ARTWORK")
    u.decorFrame, u.decor = decorFrame, decor

    
    local outline = CreateFrame("Frame", nil, u, "BackdropTemplate")
    outline:SetAllPoints(u)
    if outline.SetBackdrop then
        outline:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
        outline:SetBackdropBorderColor(1, 0.82, 0, 0.9)
    end
    outline:Hide()
    u.outline = outline

    
    local f = CreateFrame("Frame", right and "ThugUI_Orb_Resource" or "ThugUI_Orb_Health", u)
    
    
    f:SetSize(ORB_SIZE, ORB_SIZE)
    f:SetPoint("CENTER", u, "CENTER", 0, 0)
    f:SetFrameLevel(u:GetFrameLevel() + 2)

    local body = CreateFrame("Frame", nil, f)
    body:SetAllPoints(f)
    body:SetFrameLevel(f:GetFrameLevel() + 1)
    f.body = body

    local mask = body:CreateMaskTexture()
    local atlasInfo = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("CircleMaskScalable")
    if atlasInfo then
        mask:SetAtlas("CircleMaskScalable")
    else
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIONAL", "CLAMPTOBLACKADDITIONAL")
    end
    mask:SetAllPoints(f)
    f.mask = mask

    local bg = body:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    if bg.AddMaskTexture then bg:AddMaskTexture(mask) end
    f.bg = bg

    local fill = CreateFrame("StatusBar", nil, body)
    fill:SetAllPoints(f)
    fill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local tex = fill:GetStatusBarTexture()
    if tex and tex.AddMaskTexture then tex:AddMaskTexture(mask) end
    f.fill = fill

    
    
    local overlay = CreateFrame("Frame", nil, body)
    overlay:SetAllPoints(f)
    
    overlay:SetFrameLevel(fill:GetFrameLevel() + 10)
    f.overlay = overlay

    local glass = overlay:CreateTexture(nil, "ARTWORK")
    glass:SetAllPoints(f)
    glass:SetTexture(MEDIA .. "orb_glass")
    f.glass = glass

    
    
    local ringFrame = CreateFrame("Frame", nil, f)
    ringFrame:SetSize(ORB_SIZE, ORB_SIZE)
    ringFrame:SetPoint("CENTER", f, "CENTER", 0, 0)
    ringFrame:SetFrameLevel(overlay:GetFrameLevel() + 1)
    f.ringFrame = ringFrame
    f.ring = ThugUI.RingArt:NewRing(ringFrame, "ARTWORK")

    
    
    
    local function TimerCD(parent)
        local cd = CreateFrame("Cooldown", nil, parent)
        cd:SetPoint("CENTER", parent, "CENTER", 0, 0)
        cd:SetFrameLevel(parent:GetFrameLevel() + 1)
        cd:SetHideCountdownNumbers(true)
        if cd.SetDrawEdge then cd:SetDrawEdge(false) end
        if cd.SetDrawBling then cd:SetDrawBling(false) end
        cd:Hide()
        cd:SetScript("OnCooldownDone", function(self)
            self:Hide()
            Orbs:TimerIdle(key, self)
        end)
        return cd
    end
    f.timerCD = TimerCD(ringFrame)
    local timer2Frame = CreateFrame("Frame", nil, f)
    timer2Frame:SetSize(ORB_SIZE, ORB_SIZE)
    timer2Frame:SetPoint("CENTER", f, "CENTER", 0, 0)
    timer2Frame:SetFrameLevel(overlay:GetFrameLevel() + 1)
    f.timer2Frame = timer2Frame
    f.timer2 = timer2Frame:CreateTexture(nil, "ARTWORK")
    f.timer2:SetPoint("CENTER", timer2Frame, "CENTER", 0, 0)
    f.timer2CD = TimerCD(timer2Frame)

    local artFrame = CreateFrame("Frame", nil, f)
    artFrame:SetSize(ORB_SIZE, ORB_SIZE)
    artFrame:SetPoint("CENTER", f, "CENTER", 0, 0)
    artFrame:SetFrameLevel(overlay:GetFrameLevel() + 2)
    local art = artFrame:CreateTexture(nil, "ARTWORK")
    art:SetPoint("CENTER", artFrame, "CENTER", 0, 0)
    f.art = art
    f.artFrame = artFrame

    frames[key] = f
    units[key] = u
    self:ApplySettings(key)
    return f
end

function Orbs:GetFrame(key)
    return frames[key]
end






local function TimerMode(v)
    if v == "cast" or v == "gcd" then return v end
    return "off"
end


local function RingMode(c, n)
    if n == 1 then return c.timerOn and TimerMode(c.timerRing) or "off" end
    return c.timer2On and TimerMode(c.timer2) or "off"
end
Orbs.RingMode = RingMode



function Orbs:ApplyTimerRings(key)
    local f = frames[key]
    if not f or not f.timerCD then return end
    local c = Cfg(key)
    local RA = ThugUI.RingArt
    local mode1, mode2 = RingMode(c, 1), RingMode(c, 2)
    if mode1 ~= "off" or mode2 ~= "off" then
        if ThugUI.CastTimer then ThugUI.CastTimer:Start() end
    end

    local ringScale = tonumber(c.ringScale)
    if not ringScale or ringScale <= 0 then ringScale = 1.0 end
    local rSize = ORB_SIZE * ringScale
    f.timerCD:SetSize(rSize, rSize)
    f.timerCD:SetSwipeTexture(RA:Find(c.ringArt)[3])
    local r, g, b = Unpack3(c.ringColor, 1, 1, 1)
    f.timerCD:SetSwipeColor(r, g, b, tonumber(c.ringAlpha) or 1)
    if mode1 == "off" or c.ring == false then
        f.timerCD:Hide()
    end

    local s2 = tonumber(c.timer2Scale)
    if not s2 or s2 <= 0 then s2 = 1.15 end
    local size2 = ORB_SIZE * s2
    f.timer2Frame:ClearAllPoints()
    f.timer2Frame:SetPoint("CENTER", f, "CENTER", c.ringX or 0, c.ringY or 0)
    f.timer2:SetSize(size2, size2)
    f.timer2CD:SetSize(size2, size2)
    local art2 = RA:Find(c.timer2Art)
    f.timer2:SetTexture(art2[3])
    f.timer2:SetBlendMode(RA:BlendMode(c.timer2Art, "auto"))
    local r2, g2, b2 = Unpack3(c.timer2Color, 1, 1, 1)
    f.timer2:SetVertexColor(r2, g2, b2)
    f.timer2CD:SetSwipeTexture(art2[3])
    f.timer2CD:SetSwipeColor(r2, g2, b2, tonumber(c.timer2Alpha) or 1)
    if mode2 == "off" then
        f.timer2:Hide()
        f.timer2CD:Hide()
        f.timer2Frame:Hide()
    else
        f.timer2Frame:Show()
        f.timer2:Show()
        if not f.timer2CD:IsShown() then
            f.timer2:SetAlpha((tonumber(c.timer2Track) or 0.25) * (tonumber(c.timer2Alpha) or 1))
        end
    end
end


function Orbs:TimerIdle(key, cd)
    local f = frames[key]
    if not f then return end
    local c = Cfg(key)
    if cd == f.timerCD then
        f.ring:SetAlpha(tonumber(c.ringAlpha) or 1)
    elseif cd == f.timer2CD then
        f.timer2:SetAlpha((tonumber(c.timer2Track) or 0.25) * (tonumber(c.timer2Alpha) or 1))
    end
    
    self:ApplyAlpha(key)
end

local function RunSweep(cd, fillMode, start, duration, channel, obj)
    
    
    local reverse = fillMode ~= "drain"
    if channel then reverse = not reverse end
    cd:SetReverse(reverse)
    
    
    if obj and cd.SetCooldownFromDurationObject then
        cd:SetCooldownFromDurationObject(obj)
    elseif start and duration then
        cd:SetCooldown(start, duration)
    else
        return
    end
    cd:Show()
end


function Orbs:OnTimer(kind, start, duration, channel, obj)
    for _, key in ipairs({ "health", "resource" }) do
        local f = frames[key]
        local c = f and Cfg(key)
        if c and c.enabled then
            local rings = {
                { cd = f.timerCD, mode = RingMode(c, 1), fill = c.timerFill, usable = c.ring ~= false,
                  dim = function() f.ring:SetAlpha((tonumber(c.ringAlpha) or 1) * (tonumber(c.timerTrack) or 0.3)) end },
                { cd = f.timer2CD, mode = RingMode(c, 2), fill = c.timer2Fill, usable = true,
                  dim = function() f.timer2:SetAlpha((tonumber(c.timer2Track) or 0.25) * (tonumber(c.timer2Alpha) or 1)) end },
            }
            for _, ring in ipairs(rings) do
                if ring.usable and ring.mode ~= "off" then
                    if kind == ring.mode then
                        ring.dim()
                        RunSweep(ring.cd, ring.fill, start, duration, channel, obj)
                        Orbs:ApplyTimerVisibility(key)
                    elseif kind == "caststop" and ring.mode == "cast" then
                        if ring.cd.Clear then ring.cd:Clear() end
                        ring.cd:Hide()
                        Orbs:TimerIdle(key, ring.cd)
                    end
                end
            end
        end
    end
end

if ThugUI.CastTimer then
    ThugUI.CastTimer:Register(function(kind, start, duration, channel, obj)
        if ThugUI.IsModuleOn and not ThugUI:IsModuleOn("orbs") then return end
        Orbs:OnTimer(kind, start, duration, channel, obj)
    end)
end





local driver = CreateFrame("Frame")
driver:SetScript("OnEvent", function(_, event, unit)
    if not ThugUI:IsModuleOn("orbs") then _:UnregisterAllEvents() return end
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        if event == "PLAYER_REGEN_ENABLED" then
            for _, key in ipairs(KEYS) do
                local u = units[key]
                if u and u.pendingSettings then Orbs:ApplySettings(key) end
                if u and u.pendingPosition then Orbs:ApplyPosition(key) end
            end
        end
        Orbs:UpdateAlpha()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Orbs:UpdateAlpha()
        Orbs:Update("health")
        Orbs:Update("resource")
    elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        Orbs:UpdateAlpha()
    elseif event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" then
        
        
        Orbs:UpdateAlpha()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function() Orbs:UpdateAlpha() end)
        end
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        Orbs:ForceColor("resource")
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if unit == "player" then
            Orbs:Update("health")
        end
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        if unit == "player" then
            if event == "UNIT_DISPLAYPOWER" then Orbs:ForceColor("resource") end
            Orbs:Update("resource")
        end
    end
end)

function Orbs:Initialize()
    for _, key in ipairs(KEYS) do
        local c = Cfg(key)
        self:SeedRingFromRim(c)
        
        
        
        if c.timerRing == "off" then c.timerRing = "cast" end
        if c.timer2 == "off" then c.timer2 = "gcd" end

        
        
        
        if type(c.oocAlpha) == "number" and c.oocAlpha ~= 1 and ThugUI.Visibility
            and not (ThugUIDB.Visibility and ThugUIDB.Visibility[VKEY[key] ]) then
            ThugUI.Visibility:Get(VKEY[key]).oocAlpha = c.oocAlpha
        end
    end

    
    
    
    for k in pairs(restCurves) do restCurves[k] = nil end
    if C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        for _, key in ipairs(KEYS) do restCurves[key] = {} end
    else
        LogOnce("loggedNoCurve", "C_CurveUtil not found; 'only when not full' is inert")
    end

    
    
    
    if ThugUI.Visibility and not Orbs.visRegistered then
        Orbs.visRegistered = true
        for key, vKey in pairs(VKEY) do
            ThugUI.Visibility:Register(vKey, function()
                Orbs:UpdateAlpha()
                Orbs:Update(key)
            end)
        end
        
        local layerKeys = {
            "orbHealthDecor", "orbHealthOrb", "orbHealthRing", "orbHealthArt",
            "orbResourceDecor", "orbResourceOrb", "orbResourceRing", "orbResourceArt"
        }
        for _, lKey in ipairs(layerKeys) do
            ThugUI.Visibility:Register(lKey, function()
                Orbs:UpdateAlpha()
            end)
        end
    end

    self:Build("health")
    self:Build("resource")

    pcall(driver.RegisterUnitEvent, driver, "UNIT_HEALTH", "player")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_MAXHEALTH", "player")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_POWER_UPDATE", "player")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_MAXPOWER", "player")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_DISPLAYPOWER", "player")
    ThugUI.SafeRegisterEvent(driver, "UPDATE_SHAPESHIFT_FORM")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_REGEN_DISABLED")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_REGEN_ENABLED")
    
    ThugUI.SafeRegisterEvent(driver, "PLAYER_DEAD")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_ALIVE")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_UNGHOST")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_CONTROL_LOST")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_CONTROL_GAINED")
end

Orbs.frames = frames
Orbs.units = units
Orbs.driver = driver

return Orbs
