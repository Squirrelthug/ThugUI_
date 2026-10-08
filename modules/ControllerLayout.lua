





































local ThugUI = _G.ThugUI
local CL = {}
ThugUI.ControllerLayout = CL
ThugUI:RegisterModule("ControllerLayout", CL)

ThugUI.defaults.ControllerLayout = {
    barPoint = nil,   
    barScale = 1,
    castPoint = nil,  
    castScale = nil,  
    xpPoint = nil,    
    buffPoint = nil,  
    debuffPoint = nil, 
    tooltipPoint = nil, 
    tooltipScale = nil, 
}

local function Cfg() return ThugUIDB.ControllerLayout end
local function Bar() return _G.GamepadMainActionBarFrame end






function CL:CastBars()
    local out = {}
    if _G.GamepadPlayerCastingBarFrame then table.insert(out, _G.GamepadPlayerCastingBarFrame) end
    if _G.PlayerCastingBarFrame then table.insert(out, _G.PlayerCastingBarFrame) end
    return out
end
local CastBars = CL.CastBars

local function Cast()
    local gamepadUI = ThugUI.ControllerMode and ThugUI.ControllerMode:IsGamepadUI()
    if gamepadUI and _G.GamepadPlayerCastingBarFrame then return _G.GamepadPlayerCastingBarFrame end
    return _G.PlayerCastingBarFrame
end

local function IsPoint(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
end








local function ScaleRatio(f)
    local k = (f:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
    if k == 0 then k = 1 end
    return k
end


local function AnchorFrame(f, point, p)
    local k = ScaleRatio(f)
    f:ClearAllPoints()
    f:SetPoint(point, UIParent, "BOTTOMLEFT", p.x / k, p.y / k)
end







local methodHooked = setmetatable({}, { __mode = "k" })
local function HookMethodOnce(f, method, callback)
    if not f or type(f[method]) ~= "function" then return end
    methodHooked[f] = methodHooked[f] or {}
    if methodHooked[f][method] then return end
    methodHooked[f][method] = true
    hooksecurefunc(f, method, callback)
end

local function HookOnce(f, hooked, key, callback)
    if hooked[key] or not f or type(f.ApplySystemAnchor) ~= "function" then return end
    hooked[key] = true
    hooksecurefunc(f, "ApplySystemAnchor", callback)
end





local pendingBar = false

function CL:ApplyBar()
    local bar = Bar()
    if not bar then return end
    if InCombatLockdown() then
        pendingBar = true
        return
    end
    pendingBar = false
    local c = Cfg()
    local s = tonumber(c.barScale) or 1
    bar:SetScale(s)
    if IsPoint(c.barPoint) then
        bar:ClearAllPoints()
        bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", c.barPoint.x / s, c.barPoint.y / s)
    end
end





local castHooked, castScaleHooked, reanchoring = {}, {}, false







local function CastScale()
    local s = Cfg().castScale
    return type(s) == "number" and s > 0 and s or nil
end

function CL:ApplyCast()
    if reanchoring then return end
    local s = CastScale()
    local p = Cfg().castPoint
    if not s and not IsPoint(p) then return end
    reanchoring = true
    for _, cast in ipairs(CastBars()) do
        
        
        if s then cast:SetScale(s) end
        if IsPoint(p) then AnchorFrame(cast, "CENTER", p) end
    end
    reanchoring = false
end

local function HookCast()
    for _, cast in ipairs(CastBars()) do
        HookOnce(cast, castHooked, cast, function() CL:ApplyCast() end)
        if not castScaleHooked[cast] and type(cast.UpdateSystemSettingBarSize) == "function" then
            castScaleHooked[cast] = true
            hooksecurefunc(cast, "UpdateSystemSettingBarSize", function() CL:ApplyCast() end)
        end
    end
end

function CL:SetCastScale(s)
    Cfg().castScale = s
    HookCast()
    self:ApplyCast()
    
    if self.unlocked then self:SetUnlocked(true) end
end













local function XPContainer() return _G.MainStatusTrackingBarContainer end
local xpHooked, xpReanchoring = {}, false

function CL:ApplyXP()
    local f = XPContainer()
    if not f or xpReanchoring then return end
    
    local c = Cfg()
    local p = c.xpPoint
    local scale = c.xpScale
    if not IsPoint(p) and not scale then return end
    
    xpReanchoring = true
    if scale then f:SetScale(scale) end
    if IsPoint(p) then AnchorFrame(f, "CENTER", p) end
    xpReanchoring = false
end




local function HookXP()
    local f = XPContainer()
    HookOnce(f, xpHooked, "xp", function() CL:ApplyXP() end)
    HookMethodOnce(f, "UpdateSystemSetting", function() CL:ApplyXP() end)
end

function CL:ResetXP()
    Cfg().xpPoint = nil
    Cfg().xpScale = nil
    local f = XPContainer()
    if f then
        
        
        local size = Enum and Enum.EditModeStatusTrackingBarSetting
            and Enum.EditModeStatusTrackingBarSetting.Size
        local ok, val = false, nil
        if size and f.GetSettingValue then ok, val = pcall(f.GetSettingValue, f, size) end
        
        
        f:SetScale(ok and type(val) == "number" and val > 0 and val / 100 or 1)
        if type(f.ApplySystemAnchor) == "function" then
            pcall(f.ApplySystemAnchor, f)
        end
    end
    if self.unlocked then self:SetUnlocked(true) end
end













local AURA = {
    buff   = { global = "BuffFrame",   field = "buffPoint" },
    debuff = { global = "DebuffFrame", field = "debuffPoint" },
}
local auraHooked, auraReanchoring, auraPending = {}, {}, {}








local function EditModeOpacity(f)
    if not (f.GetSettingValue and Enum and Enum.EditModeAuraFrameSetting
        and Enum.EditModeAuraFrameSetting.Opacity) then return 1 end
    local ok, val = pcall(f.GetSettingValue, f, Enum.EditModeAuraFrameSetting.Opacity)
    if ok and type(val) == "number" and val > 0 then return val / 100 end
    return 1
end

local auraAlphaSet = {}

function CL:ApplyAura(key)
    local info = AURA[key]
    local f = info and _G[info.global]
    if not f or auraReanchoring[key] then return end

    local c = Cfg()
    local p = c[info.field]
    local scale = key == "buff" and c.buffScale or c.debuffScale
    local vKey = key == "buff" and "buffs" or "debuffs"
    local V = ThugUI.Visibility

    
    
    
    
    
    local CM = ThugUI.ControllerMode
    if CM and CM:Uses("auras") then
        f:SetAlpha(0)
        auraAlphaSet[key] = true
    elseif V and not V:IsDefault(vKey) then
        f:SetAlpha(EditModeOpacity(f) * V:Alpha(vKey))
        auraAlphaSet[key] = true
    elseif auraAlphaSet[key] then
        f:SetAlpha(EditModeOpacity(f))
        auraAlphaSet[key] = nil
    end

    if not IsPoint(p) and not scale then return end
    if InCombatLockdown() and f.IsProtected and f:IsProtected() then
        auraPending[key] = true
        return
    end
    auraPending[key] = nil
    auraReanchoring[key] = true
    
    if scale then f:SetScale(scale) end
    if IsPoint(p) then AnchorFrame(f, "TOPRIGHT", p) end
    auraReanchoring[key] = false
end

local function HookAura(key)
    local f = _G[AURA[key].global]
    HookOnce(f, auraHooked, key, function() CL:ApplyAura(key) end)
    
    
    
    HookMethodOnce(f, "UpdateSystemSettingOpacity", function() CL:ApplyAura(key) end)
end

function CL:ResetAura(key)
    local info = AURA[key]
    local c = Cfg()
    c[info.field] = nil
    if key == "buff" then c.buffScale = nil else c.debuffScale = nil end
    local f = _G[info.global]
    if f then
        f:SetScale(1)
        if type(f.UpdateSystemSettingIconSize) == "function" then
            pcall(f.UpdateSystemSettingIconSize, f)
        end
        if type(f.UpdateSystemSettingOpacity) == "function" then
            pcall(f.UpdateSystemSettingOpacity, f)
        else
            f:SetAlpha(1)
        end
        if type(f.ApplySystemAnchor) == "function" then
            pcall(f.ApplySystemAnchor, f)
        end
    end
    if self.unlocked then self:SetUnlocked(true) end
end











local tooltipHooked = false






local defaultAnchored = setmetatable({}, { __mode = "k" })
local scaleBefore = setmetatable({}, { __mode = "k" })
local scriptsHooked = setmetatable({}, { __mode = "k" })



local function HiddenByVisibility()
    local V = ThugUI.Visibility
    return V ~= nil and V:Alpha("tooltip") == 0
end




local function HookTooltipScripts(tooltip)
    if scriptsHooked[tooltip] or type(tooltip.HookScript) ~= "function" then return end
    scriptsHooked[tooltip] = true
    tooltip:HookScript("OnShow", function(self)
        if defaultAnchored[self] and HiddenByVisibility() then self:Hide() end
    end)
    tooltip:HookScript("OnHide", function(self)
        defaultAnchored[self] = nil
        if scaleBefore[self] then
            self:SetScale(scaleBefore[self])
            scaleBefore[self] = nil
        end
    end)
end

function CL:ApplyTooltip(tooltip)
    if not tooltip then return end
    HookTooltipScripts(tooltip)
    defaultAnchored[tooltip] = true
    
    local s = tonumber(Cfg().tooltipScale)
    if s and s > 0 then
        if not scaleBefore[tooltip] then scaleBefore[tooltip] = tooltip:GetScale() or 1 end
        tooltip:SetScale(s)
    end
    local p = Cfg().tooltipPoint
    if not IsPoint(p) then return end
    AnchorFrame(tooltip, "BOTTOMRIGHT", p)
end

function CL:SetTooltipScale(s)
    Cfg().tooltipScale = s
end



function CL:ApplyTooltipVisibility()
    for tooltip in pairs(defaultAnchored) do
        if tooltip.IsShown and tooltip:IsShown() and HiddenByVisibility() then tooltip:Hide() end
    end
end




local function HookTooltip()
    if tooltipHooked or type(_G.GameTooltip_SetDefaultAnchor) ~= "function" then return end
    tooltipHooked = true
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip) CL:ApplyTooltip(tooltip) end)
end




function CL:ResetTooltip()
    Cfg().tooltipPoint = nil
    Cfg().tooltipScale = nil
    if self.unlocked then self:SetUnlocked(true) end
end





local movers = {}

local function CenterInUIParent(frame)
    local x, y = frame:GetCenter()
    if not x then return nil end
    local k = ScaleRatio(frame)
    return x * k, y * k
end

local function MakeMover(key, label, w, h, onSave)
    local m = CreateFrame("Frame", "ThugUI_ControllerMover_" .. key, UIParent, "BackdropTemplate")
    m:SetSize(w, h)
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
    text:SetText(label .. "\n|cffffffffdrag to move|r")
    m:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if x then onSave({ x = x, y = y }) end
    end)
    m:Hide()
    movers[key] = m
    return m
end


local function MakeCornerMover(key, label, onSave)
    local m = MakeMover(key, label, 300, 90, function() end)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local r, t = self:GetRight(), self:GetTop()
        if type(r) == "number" and type(t) == "number" then onSave({ x = r, y = t }) end
    end)
    return m
end

local function PlaceCornerMover(m, frame, saved)
    m:ClearAllPoints()
    local w, h = 300, 90
    local k = 1
    if frame then
        k = ScaleRatio(frame)
        local fw, fh = frame:GetWidth(), frame:GetHeight()
        if fw and fw > 10 then w = fw * k end
        if fh and fh > 10 then h = fh * k end
    end
    m:SetSize(w, h)
    if IsPoint(saved) then
        m:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
        return
    end
    local r, t = frame and frame:GetRight(), frame and frame:GetTop()
    if type(r) == "number" and type(t) == "number" then
        m:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", r * k, t * k)
    else
        m:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -20)
    end
end


local function PlaceMover(m, frame, saved, fallbackW, fallbackH)
    m:ClearAllPoints()
    local w, h = fallbackW, fallbackH
    if frame then
        local k = ScaleRatio(frame)
        local fw, fh = frame:GetWidth(), frame:GetHeight()
        if fw and fw > 10 then w = fw * k end
        if fh and fh > 10 then h = fh * k end
    end
    m:SetSize(w, h)
    if IsPoint(saved) then
        m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", saved.x, saved.y)
        return
    end
    local x, y
    if frame then x, y = CenterInUIParent(frame) end
    if x then
        m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    else
        m:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end
end




local function MakeTooltipMover(onSave)
    local m = MakeMover("tooltip", "Tooltip", 220, 90, function() end)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local r, b = self:GetRight(), self:GetBottom()
        if type(r) == "number" and type(b) == "number" then onSave({ x = r, y = b }) end
    end)
    return m
end

local function PlaceTooltipMover(m, saved)
    m:ClearAllPoints()
    m:SetSize(220, 90)
    if IsPoint(saved) then
        m:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        m:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -100, 100)
    end
end

function CL:SetUnlocked(unlocked)
    self.unlocked = unlocked and true or false
    local bm = movers.bar or MakeMover("bar", "Controller buttons", 420, 160, function(p)
        Cfg().barPoint = p
        CL:ApplyBar()
    end)
    local cm = movers.cast or MakeMover("cast", "Cast bar", 208, 24, function(p)
        Cfg().castPoint = p
        HookCast()
        CL:ApplyCast()
    end)
    local xm = movers.xp or MakeMover("xp", "Experience bar", 570, 20, function(p)
        Cfg().xpPoint = p
        HookXP()
        CL:ApplyXP()
    end)
    local tm = movers.tooltip or MakeTooltipMover(function(p)
        Cfg().tooltipPoint = p
        HookTooltip()
    end)
    local am = {}
    for key, info in pairs(AURA) do
        am[key] = movers[key] or MakeCornerMover(key, key == "buff" and "Buffs" or "Debuffs", function(p)
            Cfg()[info.field] = p
            HookAura(key)
            CL:ApplyAura(key)
        end)
    end
    if self.unlocked then
        PlaceMover(bm, Bar(), Cfg().barPoint, 420, 160)
        PlaceMover(cm, Cast(), Cfg().castPoint, 208, 24)
        PlaceMover(xm, XPContainer(), Cfg().xpPoint, 570, 20)
        PlaceTooltipMover(tm, Cfg().tooltipPoint)
        for key, info in pairs(AURA) do
            PlaceCornerMover(am[key], _G[info.global], Cfg()[info.field])
            am[key]:Show()
        end
        bm:Show(); cm:Show(); xm:Show(); tm:Show()
    else
        bm:Hide(); cm:Hide(); xm:Hide(); tm:Hide()
        for key in pairs(AURA) do am[key]:Hide() end
    end
    if ThugUI.XPBar and ThugUI.XPBar.SetUnlocked then
        ThugUI.XPBar:SetUnlocked(self.unlocked)
    end
end

function CL:SetBarScale(s)
    Cfg().barScale = s
    self:ApplyBar()
end

function CL:ResetBar()
    local c = Cfg()
    c.barPoint = nil
    c.barScale = 1
    
    local bar = Bar()
    if bar and not InCombatLockdown() then
        bar:SetScale(1)
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 110)
    end
    if self.unlocked then self:SetUnlocked(true) end
end



function CL:SetAuraScale(key, s)
    Cfg()[key == "buff" and "buffScale" or "debuffScale"] = s
    HookAura(key)
    self:ApplyAura(key)
    if self.unlocked then self:SetUnlocked(true) end
end

function CL:SetXPScale(s)
    Cfg().xpScale = s
    HookXP()
    self:ApplyXP()
    if self.unlocked then self:SetUnlocked(true) end
end

function CL:ResetCast()
    Cfg().castPoint = nil
    Cfg().castScale = nil
    
    
    for _, cast in ipairs(CastBars()) do
        if type(cast.UpdateSystemSettingBarSize) == "function" then
            pcall(cast.UpdateSystemSettingBarSize, cast)
        else
            cast:SetScale(1)
        end
        if type(cast.ApplySystemAnchor) == "function" then
            pcall(cast.ApplySystemAnchor, cast)
        end
    end
    if self.unlocked then self:SetUnlocked(true) end
end


CL.movers = movers

local nameTouched = setmetatable({}, { __mode = "k" })




function CL:ApplyMacroNames()
    local root = _G.GamepadMainActionBarFrame
    if not root then return end

    local hide = Cfg().hideMacroName == true
    local visited = {}

    local function Walk(frame)
        if not frame or visited[frame] then return end
        visited[frame] = true

        local fs = frame.Name
        if type(fs) == "table" and type(fs.GetObjectType) == "function" and fs:GetObjectType() == "FontString" then
            if hide then
                fs:SetAlpha(0)
                nameTouched[fs] = true
            elseif nameTouched[fs] then
                fs:SetAlpha(1)
                nameTouched[fs] = nil
            end
        end

        if type(frame.GetChildren) == "function" then
            local children = { frame:GetChildren() }
            for _, child in ipairs(children) do
                Walk(child)
            end
        end
    end

    Walk(root)
end

function CL:SetHideMacroName(v)
    Cfg().hideMacroName = v and true or nil
    self:ApplyMacroNames()
end





local driver = CreateFrame("Frame")
driver:SetScript("OnEvent", function(self, event)
    if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
    if event == "PLAYER_LOGIN" then
        HookCast()
        HookXP()
        HookTooltip()
        CL:ApplyBar()
        CL:ApplyCast()
        CL:ApplyXP()
        CL:ApplyMacroNames()
        for key in pairs(AURA) do
            HookAura(key)
            CL:ApplyAura(key)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingBar then CL:ApplyBar() end
        for key in pairs(AURA) do
            if auraPending[key] then CL:ApplyAura(key) end
        end
    end
end)
CL.driver = driver

function CL:Initialize()
    ThugUI.SafeRegisterEvent(driver, "PLAYER_LOGIN")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_REGEN_ENABLED")

    if ThugUI.Visibility then
        ThugUI.Visibility:Register("controllerButtons", function(alpha)
            local bar = Bar()
            if bar then bar:SetAlpha(alpha) end
        end)
        ThugUI.Visibility:Register("castBar", function()
            if ThugUI.FrameHider and ThugUI.FrameHider.RefreshCastBar then
                ThugUI.FrameHider:RefreshCastBar()
            end
        end)
        ThugUI.Visibility:Register("buffs", function() CL:ApplyAura("buff") end)
        ThugUI.Visibility:Register("debuffs", function() CL:ApplyAura("debuff") end)
        ThugUI.Visibility:Register("tooltip", function() CL:ApplyTooltipVisibility() end)
    end

    if ThugUI.ControllerMode then
        local function RefreshAuras()
            CL:ApplyAura("buff")
            CL:ApplyAura("debuff")
        end
        local function RefreshMacroNames()
            CL:ApplyMacroNames()
        end
        ThugUI.ControllerMode:RegisterFeatureCallback("auras", RefreshAuras)
        ThugUI.ControllerMode:RegisterCallback(RefreshAuras)
        ThugUI.ControllerMode:RegisterCallback(RefreshMacroNames)
    end
end
