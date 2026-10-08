
















local ThugUI = _G.ThugUI
local RP = {}
ThugUI.ResourcePips = RP
ThugUI:RegisterModule("ResourcePips", RP)

ThugUI.defaults.ResourcePips = {
    enabled = true,
    show = "controller",          
    layout = "ring",              
    size = 12,                    
    radius = 36,                  
    spread = 1,                   
    start = 12,                   
    gap = 4,                      
    orientation = "horizontal",   
    scale = 1,
    point = nil,                  
    colorMode = "power",          
    customColor = { 1, 0.85, 0.3 },
    dimAlpha = 0.25,              
    ring = false,                 
    ringArt = "orb",              
    ringBlend = "auto",           
    ringAlpha = 1,                
    ringUnlitAlpha = 0,           
    ringScale = 1.6,              
    ringX = 0, ringY = 0,         
    ringColor = { 1, 1, 1 },
    ringSpin = 0,                 
    ringDesat = false,
}

local MIN_SPREAD = 0.25

local function Testing()
    return ThugUI.Orbs ~= nil and ThugUI.Orbs:IsTestMode()
end


RP.RING_ART = ThugUI.RingArt.ART

local function Cfg() return ThugUIDB.ResourcePips end

local function IsPoint(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
end



local function DefaultPoint()
    return (UIParent:GetWidth() or 0) / 2 + 160, 220
end






function RP.Positions(c, n)
    local size = tonumber(c.size) or 12
    local out = {}
    if n <= 0 then return out, size, size end

    if c.layout == "bar" then
        local pitch = size + math.max(0, tonumber(c.gap) or 0)
        local vertical = c.orientation == "vertical"
        for i = 1, n do
            
            
            local o = (i - (n + 1) / 2) * pitch
            out[i] = vertical and { x = 0, y = o } or { x = o, y = 0 }
        end
        local long = n * size + (n - 1) * (pitch - size)
        if vertical then return out, size, long end
        return out, long, size
    end

    local radius = math.max(0, tonumber(c.radius) or 36)
    local spread = math.min(1, math.max(MIN_SPREAD, tonumber(c.spread) or 1))
    
    
    local clock = tonumber(c.start) or 12
    local centre = (clock % 12) * math.pi / 6
    
    
    
    local step = (2 * math.pi * spread) / n
    for i = 1, n do
        local a = centre + (i - (n + 1) / 2) * step
        out[i] = { x = math.sin(a) * radius, y = math.cos(a) * radius }
    end
    local d = 2 * radius + size
    return out, d, d
end





local frame
local pips = {}
RP.pips = pips  
RP.lastMax, RP.lastCount, RP.lastToken = nil, nil, nil

function RP:Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "ThugUI_ResourcePips", UIParent)
    f:SetFrameStrata("HIGH") 
    f:Hide()
    frame = f
    RP.frame = f
    return f
end

local rings = {}
RP.rings = rings  

local function Ring(i, ringFrame)
    if rings[i] then return rings[i] end
    local t = ThugUI.RingArt:NewRing(ringFrame, "BACKGROUND")
    rings[i] = t
    return t
end

function RP:BuildRing()
    if RP.ringFrame then return RP.ringFrame end
    local pipsFrame = self:Build()
    local level = pipsFrame:GetFrameLevel() - 1
    if level < 0 then level = 0 end
    local r = CreateFrame("Frame", "ThugUI_ResourcePipsRing", UIParent)
    r:SetFrameStrata("HIGH")
    r:SetFrameLevel(level)
    r:SetPoint("CENTER", pipsFrame, "CENTER")
    r:EnableMouse(false)

    RP.ringFrame = r
    return r
end

local pipHolders = {}
local pipCanvases = {}


local function Pip(i)
    if pips[i] then return pips[i], pipHolders[i], pipCanvases[i] end
    
    local h = CreateFrame("Frame", nil, frame)
    pipHolders[i] = h
    
    local canvas = ThugUI.OrbArt:NewCanvas(h, { kind = "pip" })
    pipCanvases[i] = canvas
    
    local t = frame:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\AddOns\\ThugUI\\media\\Reticle_Dot")
    t:SetBlendMode("BLEND")
    pips[i] = t
    
    return t, h, canvas
end

function RP:Layout(n)
    local f = self:Build()
    local c = Cfg()
    n = n or self.lastMax or 0

    local scale = tonumber(c.scale) or 1
    if scale <= 0 then scale = 1 end
    local positions, w, h = RP.Positions(c, n)
    local size = tonumber(c.size) or 12
    f:SetScale(scale)
    f:SetSize(math.max(w, 1), math.max(h, 1))

    f:ClearAllPoints()
    local x, y
    if IsPoint(c.point) then x, y = c.point.x, c.point.y else x, y = DefaultPoint() end
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

    local stack = ThugUI.OrbEffects and ThugUI.OrbEffects:PipStack()
    local adjust = ThugUIDB.OrbEffects and ThugUIDB.OrbEffects.pips and ThugUIDB.OrbEffects.pips.adjust or {}

    for i, p in ipairs(positions) do
        local t, h, canvas = Pip(i)
        t:SetSize(size, size)
        t:ClearAllPoints()
        t:SetPoint("CENTER", f, "CENTER", p.x, p.y)
        
        h:SetSize(size, size)
        h:ClearAllPoints()
        h:SetPoint("CENTER", f, "CENTER", p.x, p.y)

        if stack then
            t:Hide()
            h:Show()
            canvas:Apply(stack, adjust)
        else
            h:Hide()
            t:Show()
        end
    end
    for i = #positions + 1, #pips do 
        pips[i]:Hide() 
        pipHolders[i]:Hide()
    end
    self:UpdateRing()
end

function RP:UpdateRingAlphas(filledCount)
    local c = Cfg()
    local ringAlpha = tonumber(c and c.ringAlpha) or 1
    local unlitAlpha = tonumber(c and c.ringUnlitAlpha) or 0
    local count = filledCount or self.lastCount or 0
    for i = 1, #rings do
        if rings[i]:IsShown() then
            local a = (i <= count) and ringAlpha or (ringAlpha * unlitAlpha)
            rings[i]:SetAlpha(a)
        end
    end
end

function RP:UpdateRing()
    local r = self:BuildRing()
    local c = Cfg()
    local pipsFrame = self:Build()

    if not c.enabled or not c.ring or not pipsFrame:IsShown() then
        r:Hide()
        for i = 1, #rings do
            rings[i]:Hide()
            if rings[i].ringGroup then
                rings[i].ringGroup:Stop()
            end
        end
        return
    end

    local n = self.lastMax or 0
    local scale = tonumber(c.scale) or 1
    if scale <= 0 then scale = 1 end
    local positions, w, h = RP.Positions(c, n)
    local pipSize = tonumber(c.size) or 12

    r:SetScale(scale)
    r:SetSize(math.max(w, 1), math.max(h, 1))
    r:ClearAllPoints()
    r:SetPoint("CENTER", pipsFrame, "CENTER")

    local ringScale = tonumber(c.ringScale)
    if not ringScale or ringScale <= 0 then ringScale = 1.6 end
    local ringDiameter = pipSize * ringScale

    local ringX = tonumber(c.ringX) or 0
    local ringY = tonumber(c.ringY) or 0

    local applyOpt = {
        art = c.ringArt,
        blend = c.ringBlend,
        color = c.ringColor,
        alpha = tonumber(c.ringAlpha) or 1,
        spin = tonumber(c.ringSpin) or 0,
        desat = c.ringDesat,
    }

    for i, p in ipairs(positions) do
        local t = Ring(i, r)
        t:SetSize(ringDiameter, ringDiameter)
        t:ClearAllPoints()
        t:SetPoint("CENTER", r, "CENTER", p.x + ringX, p.y + ringY)
        ThugUI.RingArt:Apply(t, applyOpt)
        t:Show()
    end

    for i = #positions + 1, #rings do
        rings[i]:Hide()
        if rings[i].ringGroup then
            rings[i].ringGroup:Stop()
        end
    end

    if Testing() then
        r:SetAlpha(1)
    elseif ThugUI.Visibility then
        r:SetAlpha(ThugUI.Visibility:Alpha("resourcePipsRing"))
    end
    r:Show()
    self:UpdateRingAlphas()
end

function RP:Paint(filled, token, n)
    local c = Cfg()
    local CP = ThugUI.ComboPips
    local dim = tonumber(c.dimAlpha) or 0.25
    local r, g, b = 1, 0.85, 0.3
    if CP and CP.ResolveColor then r, g, b = CP:ResolveColor(c.colorMode, c.customColor, token) end
    for i = 1, n do
        local t = pips[i]
        local h = pipHolders[i]
        if t then
            t:SetVertexColor(r, g, b)
            local a = i <= filled and 1 or dim
            t:SetAlpha(a)
            if h then h:SetAlpha(a) end
        end
    end
    self:UpdateRingAlphas(filled)
end





function RP:ShouldShow()
    local c = Cfg()
    if not c or not c.enabled then return false end
    if Testing() then return true end
    if c.show == "controller" then
        if ThugUI.UnitFrames then
            return ThugUI.UnitFrames:Active()
        end
        return ThugUI.ControllerMode ~= nil and ThugUI.ControllerMode:IsActive() and true or false
    end
    return true
end

function RP:Update()
    local f = self:Build()
    if not self:ShouldShow() or not ThugUI.ComboPips then
        self.preview = false
        f:Hide()
        self:UpdateRing()
        return
    end

    local kind, current, maximum, token = ThugUI.ComboPips:Read()
    if Testing() and (kind == "none" or (kind == "secret" and self.lastMax == nil)) then
        self.preview = true
        maximum = 5
        token = nil
    else
        self.preview = false
        if kind == "none" then
            f:Hide()
            self.lastMax, self.lastCount = nil, nil
            self:UpdateRing()
            return
        end
        if kind == "secret" then
            
            f:SetShown(self.lastMax ~= nil)
            self:UpdateRing()
            return
        end
    end

    
    
    
    if Testing() then current = maximum end

    if self.lastMax ~= maximum then
        self.lastMax = maximum
        self:Layout(maximum)
        self.lastCount = nil
    end
    if self.lastCount ~= current or self.lastToken ~= token then
        self.lastCount, self.lastToken = current, token
        self:Paint(current, token, maximum)
    end

    if Testing() then
        f:SetAlpha(1)
    elseif ThugUI.Visibility then
        f:SetAlpha(ThugUI.Visibility:Alpha("resourcePips"))
    end
    f:Show()
    self:UpdateRing()
end



function RP:DebugState()
    local f = frame
    local function C(r)
        if not (r and r.GetCenter) then return "-" end
        local x, y = r:GetCenter()
        if not x then return "?" end
        local s = r.GetEffectiveScale and r:GetEffectiveScale() or 1
        return ("%.0f,%.0f"):format(x * s, y * s)
    end
    return ("max=%s count=%s preview=%s shown=%s alpha=%.2f pip1=%s alpha1=%.2f ring1=%s ringShown=%s"):format(
        tostring(self.lastMax), tostring(self.lastCount), tostring(self.preview),
        tostring(f and f:IsShown()), f and f:GetAlpha() or -1,
        C(pips[1]), pips[1] and pips[1]:GetAlpha() or -1,
        C(RP.rings and RP.rings[1]), tostring(RP.ringFrame and RP.ringFrame:IsShown()))
end


function RP:Refresh()
    self.lastMax, self.lastCount, self.lastToken = nil, nil, nil
    self:Update()
    if self.unlocked then self:SetUnlocked(true) end
end





local mover

local function MakeMover()
    local m = CreateFrame("Frame", "ThugUI_ResourcePipsMover", UIParent, "BackdropTemplate")
    m:SetFrameStrata("DIALOG")
    m:SetClampedToScreen(true)
    m:SetMovable(true)
    m:EnableMouse(true)
    m:RegisterForDrag("LeftButton")
    if m.SetBackdrop then
        m:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        m:SetBackdropColor(0, 0, 0, 0.5)
        m:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
    local text = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("Resource pips")
    m:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if x then
            Cfg().point = { x = x, y = y }
            RP:Layout()
        end
    end)
    m:Hide()
    mover = m
    RP.mover = m
    return m
end

function RP:SetUnlocked(unlocked)
    self.unlocked = unlocked and true or false
    local m = mover or MakeMover()
    if not self.unlocked then
        m:Hide()
        return
    end
    local c = Cfg()
    
    
    local _, w, h = RP.Positions(c, self.lastMax or 5)
    local scale = tonumber(c.scale) or 1
    m:SetSize(math.max(w, 40) * scale, math.max(h, 20) * scale)
    m:ClearAllPoints()
    local x, y
    if IsPoint(c.point) then x, y = c.point.x, c.point.y else x, y = DefaultPoint() end
    m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    if m.SetBackdropColor then
        m:SetBackdropColor(0, 0, 0, Testing() and 0.15 or 0.5)
    end
    m:Show()
end

function RP:ResetPosition()
    Cfg().point = nil
    self:Layout()
    if self.unlocked then self:SetUnlocked(true) end
end





local driver = CreateFrame("Frame")
RP.driver = driver
driver:SetScript("OnEvent", function(_, event)
    if not ThugUI:IsModuleOn("orbs") then _:UnregisterAllEvents() return end
    if event == "UNIT_DISPLAYPOWER" or event == "UPDATE_SHAPESHIFT_FORM"
        or event == "PLAYER_SPECIALIZATION_CHANGED" then
        RP:Refresh()
        return
    end
    RP:Update()
end)

function RP:Initialize()
    self:Build()
    driver:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    driver:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    driver:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    driver:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_SPECIALIZATION_CHANGED")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")

    if ThugUI.Visibility then
        ThugUI.Visibility:Register("resourcePips", function(alpha)
            if frame then frame:SetAlpha(Testing() and 1 or alpha) end
        end)
        ThugUI.Visibility:Register("resourcePipsRing", function(alpha)
            if RP.ringFrame then RP.ringFrame:SetAlpha(Testing() and 1 or alpha) end
        end)
    end
    if ThugUI.ControllerMode then
        ThugUI.ControllerMode:RegisterCallback(function() RP:Update() end)
    end
    self:Update()
end

return RP
