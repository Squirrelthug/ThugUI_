














































local ThugUI = _G.ThugUI
local XB = {}
ThugUI.XPBar = XB
ThugUI:RegisterModule("XPBar", XB)

ThugUI.defaults.XPBar = {
    enabled = true,
    show = "controller",         
    orientation = "horizontal",  
    length = 400,
    thickness = 10,
    point = nil,                  
    showText = true,
    color = { 0.58, 0.0, 0.55 },
    restedColor = { 0.0, 0.39, 0.88, 0.6 },
    hideBlizzard = true,
}

local function Cfg() return ThugUIDB.XPBar end

local function IsPoint(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
end



local function DefaultPoint()
    return (UIParent:GetWidth() or 0) / 2, 14
end

local frame







function XB:Build()
    if frame then return frame end

    local f = CreateFrame("Frame", "ThugUI_XPBar", UIParent)
    f:SetFrameStrata("MEDIUM")

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    local border = f:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0, 0, 0, 1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)

    
    
    f.restedBar = CreateFrame("StatusBar", nil, f)
    f.restedBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    f.restedBar:SetFrameLevel((f:GetFrameLevel() or 0) + 1)

    f.xpBar = CreateFrame("StatusBar", nil, f)
    f.xpBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    f.xpBar:SetFrameLevel((f:GetFrameLevel() or 0) + 2)

    
    
    
    f.textLayer = CreateFrame("Frame", nil, f)
    f.textLayer:SetAllPoints(f)
    f.textLayer:SetFrameLevel((f:GetFrameLevel() or 0) + 3)
    f.percentText = f.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.percentText:SetJustifyH("CENTER")

    frame = f
    XB.frame = f
    self:ApplyColors()
    return f
end



function XB:ApplyColors()
    local f = frame
    if not f then return end
    local c = Cfg()
    local col = c.color or { 0.58, 0.0, 0.55 }
    local rc = c.restedColor or { 0.0, 0.39, 0.88, 0.6 }
    f.xpBar:SetStatusBarColor(col[1], col[2], col[3])
    f.restedBar:SetStatusBarColor(rc[1], rc[2], rc[3], rc[4])
end








local pendingLayout = false

function XB:Layout()
    local f = self:Build()

    if InCombatLockdown() then
        pendingLayout = true
        self:Update()
        return
    end
    pendingLayout = false

    local c = Cfg()
    local length = tonumber(c.length) or 400
    local thickness = tonumber(c.thickness) or 10
    local vertical = c.orientation == "vertical"
    local scale = tonumber(c.scale) or 1
    if scale <= 0 then scale = 1 end
    local w = vertical and thickness or length
    local h = vertical and length or thickness
    f:SetSize(w, h)
    f:SetScale(scale)

    f:ClearAllPoints()
    local x, y
    if IsPoint(c.point) then
        x, y = c.point.x, c.point.y
    else
        x, y = DefaultPoint()
    end
    
    
    
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

    
    
    
    local orient = vertical and "VERTICAL" or "HORIZONTAL"
    f.restedBar:ClearAllPoints()
    f.restedBar:SetAllPoints(f)
    f.restedBar:SetOrientation(orient)
    f.xpBar:ClearAllPoints()
    f.xpBar:SetAllPoints(f)
    f.xpBar:SetOrientation(orient)

    f.percentText:ClearAllPoints()
    if vertical then
        f.percentText:SetPoint("BOTTOM", f, "TOP", 0, 2)
    else
        f.percentText:SetPoint("CENTER", f, "CENTER", 0, 0)
    end

    self:Update()
    
    
    if self.unlocked then self:SetUnlocked(true) end
end









local weSetAlpha = false

local function ApplyBlizzardAlpha()
    local mgr = _G.StatusTrackingBarManager
    if not mgr then return end
    local c = Cfg()
    
    local vAlpha = 1
    local vDefault = true
    if ThugUI.Visibility then
        vAlpha = ThugUI.Visibility:Alpha("blizzXP")
        vDefault = ThugUI.Visibility:IsDefault("blizzXP")
    end
    
    if frame and frame:IsShown() and c.hideBlizzard then
        mgr:SetAlpha(0)
        weSetAlpha = true
    elseif not vDefault then
        mgr:SetAlpha(vAlpha)
        weSetAlpha = true
    elseif weSetAlpha then
        mgr:SetAlpha(1)
        weSetAlpha = false
    end
end







function XB:Update()
    local f = frame
    if not f then return end
    local c = Cfg()

    if not c.enabled then
        f:Hide()
        ApplyBlizzardAlpha()
        return
    end
    if c.show == "controller" and not (ThugUI.ControllerMode and ThugUI.ControllerMode:IsActive()) then
        f:Hide()
        ApplyBlizzardAlpha()
        return
    end
    if type(IsXPUserDisabled) == "function" and IsXPUserDisabled() then
        f:Hide()
        ApplyBlizzardAlpha()
        return
    end
    if GameRulesUtil and type(GameRulesUtil.IsPlayerAtEffectiveMaxLevel) == "function"
        and GameRulesUtil.IsPlayerAtEffectiveMaxLevel() then
        f:Hide()
        ApplyBlizzardAlpha()
        return
    end

    
    
    
    local xp, max = UnitXP("player"), UnitXPMax("player")
    f.xpBar:SetMinMaxValues(0, max)
    f.xpBar:SetValue(xp)

    if (issecretvalue and issecretvalue(xp)) or (issecretvalue and issecretvalue(max)) then
        f.restedBar:Hide()
        f.percentText:SetText("")
        f:Show()
        ApplyBlizzardAlpha()
        return
    end

    if type(max) ~= "number" or max <= 0 then
        f:Hide()
        ApplyBlizzardAlpha()
        return
    end

    f:Show()

    local ex = GetXPExhaustion()
    local rested = type(ex) == "number" and ex > 0
    if rested then
        f.restedBar:SetMinMaxValues(0, max)
        f.restedBar:SetValue(math.min(xp + ex, max))
        f.restedBar:Show()
    else
        f.restedBar:Hide()
    end

    if c.showText then
        local text = ("%d%%"):format(math.floor(xp / max * 100))
        if rested then
            text = text .. (" +%d%% rested"):format(math.floor(ex / max * 100))
        end
        f.percentText:SetText(text)
    else
        f.percentText:SetText("")
    end

    ApplyBlizzardAlpha()
end






local movers = {}

local function MakeMover()
    local m = CreateFrame("Frame", "ThugUI_XPBarMover", UIParent, "BackdropTemplate")
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
    text:SetText("Experience bar\n|cffffffffdrag to move|r")
    m:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if x then
            Cfg().point = { x = x, y = y }
            XB:Layout()
        end
    end)
    m:Hide()
    movers.bar = m
    return m
end

function XB:SetUnlocked(unlocked)
    self.unlocked = unlocked and true or false
    local m = movers.bar or MakeMover()
    if self.unlocked then
        local c = Cfg()
        local vertical = c.orientation == "vertical"
        local length = tonumber(c.length) or 400
        local thickness = tonumber(c.thickness) or 10
        local scale = tonumber(c.scale) or 1
        local w = (vertical and thickness or length) * scale
        local h = (vertical and length or thickness) * scale
        m:SetSize(w, h)
        m:ClearAllPoints()
        if IsPoint(c.point) then
            m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", c.point.x, c.point.y)
        else
            local x, y = DefaultPoint()
            m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        end
        m:Show()
    else
        m:Hide()
    end
end

function XB:ResetPosition()
    Cfg().point = nil
    self:Layout()
    if self.unlocked then self:SetUnlocked(true) end
end


XB.movers = movers





local driver = CreateFrame("Frame")
driver:SetScript("OnEvent", function(_, event)
    if not ThugUI:IsModuleOn("controller") then _:UnregisterAllEvents() return end
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingLayout then XB:Layout() end
    else
        XB:Update()
    end
end)
XB.driver = driver

function XB:Initialize()
    ThugUI.SafeRegisterEvent(driver, "PLAYER_XP_UPDATE")
    ThugUI.SafeRegisterEvent(driver, "UPDATE_EXHAUSTION")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_LEVEL_UP")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(driver, "ENABLE_XP_GAIN")
    ThugUI.SafeRegisterEvent(driver, "DISABLE_XP_GAIN")

    self:Layout()

    if ThugUI.Visibility then
        ThugUI.Visibility:Register("xpBar", function(alpha)
            if frame then frame:SetAlpha(alpha) end
        end)
        ThugUI.Visibility:Register("blizzXP", function()
            ApplyBlizzardAlpha()
        end)
    end

    if ThugUI.ControllerMode then
        ThugUI.ControllerMode:RegisterCallback(function() XB:Update() end)
    end
end
