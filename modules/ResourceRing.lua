








































ThugUI = ThugUI or {}
ThugUI_Config = ThugUI_Config or {}

local RR = {}
ThugUI.ResourceRing = RR

RR.frame = nil



RR.radialUnsupported = nil
RR.lastPowerToken = nil




RR.lastDrainDirection = nil














local POWER_OVERRIDES = {
    DRUID = function()
        local formID = GetShapeshiftFormID and GetShapeshiftFormID()
        local lunar = Enum and Enum.PowerType and Enum.PowerType.LunarPower
        if lunar and MOONKIN_FORM and formID == MOONKIN_FORM then
            return lunar, "LUNAR_POWER"
        end
        
        
        return nil
    end,
}


function RR:GetPowerType()
    local _, class = UnitClass("player")

    local override = POWER_OVERRIDES[class]
    if override then
        local powerType, token = override()
        if powerType then return powerType, token end
    end

    local powerType, token = UnitPowerType("player")
    return powerType, token
end



function RR:GetColor(powerToken)
    local mode = ThugUI_Config.resourceRingColorMode or "power"

    if mode == "class" then
        local _, class = UnitClass("player")
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
        return 1, 1, 1
    end

    if mode == "custom" then
        local c = ThugUI_Config.resourceRingCustomColor
        if c then return c.r, c.g, c.b end
        return 1, 1, 1
    end

    local color = powerToken and PowerBarColor and PowerBarColor[powerToken]
    if color and color.r then return color.r, color.g, color.b end
    return 0.3, 0.5, 0.9
end









function RR:EnsureFrame()
    if self.frame then return self.frame end
    if self.radialUnsupported then return nil end
    if not ThugUI_CursorFrame then return nil end

    
    
    
    
    
    
    
    
    
    
    
    
    local f = CreateFrame("StatusBar", "ThugUI_RESOURCE_RING_RADIAL", UIParent)

    
    
    
    
    if not (Enum and Enum.StatusBarRenderMode) or not f.SetRenderMode then
        self.radialUnsupported = true
        f:Hide()
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("resource-ring-radial-unsupported", "RING",
                "StatusBarRenderMode.Radial unavailable on this client -- "
                .. "the resource ring cannot draw. Requires 12.1 or later")
        end
        return nil
    end

    
    
    f:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    f:SetFrameStrata("MEDIUM")
    f:SetRenderMode(Enum.StatusBarRenderMode.Radial)
    f:SetStatusBarTexture(RR:GetRingTexturePath())
    f:Hide()

    self.frame = f
    self.lastPowerToken = nil
    self.lastDrainDirection = nil
    self:SyncGeometry()
    return f
end



function RR:GetRingTexturePath()
    local ER = ThugUI.EssentialRings
    if ER and ER.GetRingTexture then return ER:GetRingTexture("resource") end
    return "Interface\\AddOns\\ThugUI\\media\\Ring_Main"
end



function RR:ApplyTexture()
    local f = self.frame
    if not f then return end
    f:SetStatusBarTexture(RR:GetRingTexturePath())
    self:UpdateColor()
end



function RR:SyncGeometry()
    local f = self.frame
    if not f then return end

    local ER = ThugUI.EssentialRings
    local cast = ER and ER.CastFrame

    if cast then
        f:SetSize(cast:GetSize())
    else
        f:SetSize(90, 90)
    end

    self:ApplyStartAngle(f)
end






















function RR:ApplyStartAngle(f)
    f = f or self.frame
    if not f then return end

    local tex = f.GetStatusBarTexture and f:GetStatusBarTexture()
    if not tex then return end

    local clock = ThugUI_Config.resourceRingRotation or 12
    local turns = ((clock - 6) % 12) / 12

    if tex.SetRadialProgressBarStartOffset then
        tex:SetRadialProgressBarStartOffset(turns)
        return
    end

    
    
    
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:LogOnce("resource-ring-no-start-offset", "RING",
            "SetRadialProgressBarStartOffset unavailable -- falling back to "
            .. "texture rotation for the resource ring's start angle")
    end
    if tex.SetRotation then
        tex:SetRotation(turns * 2 * math.pi)
    end
end














function RR:ApplyDrainDirection(f)
    local want = ThugUI_Config.resourceRingDrainDirection or "clockwise"
    if want == self.lastDrainDirection then return end

    local tex = f.GetStatusBarTexture and f:GetStatusBarTexture()
    if not (tex and tex.SetRadialProgressBarReverse) then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("resource-ring-no-reverse", "RING",
                "SetRadialProgressBarReverse unavailable -- resource ring "
                .. "drain direction cannot be changed on this client")
        end
        
        self.lastDrainDirection = want
        return
    end

    tex:SetRadialProgressBarReverse(want == "counterclockwise")
    self.lastDrainDirection = want
end






local function InCombat()
    local ER = ThugUI.EssentialRings
    if ER and ER.IsInCombat then return ER:IsInCombat() end
    return InCombatLockdown()
end

function RR:ShouldShow()
    
    
    
    
    if not ThugUI:IsModuleOn("rings") then return false end
    if not ThugUI_Config.showResourceRing then return false end
    if not ThugUI_CursorFrame then return false end

    
    
    
    local mode = ThugUI_Config.resourceRingVisibility or "always"
    if mode == "rings" then return ThugUI_CursorFrame:IsShown() end
    if mode == "combat" then return InCombat() end
    return true
end

function RR:Update()
    local f = self:EnsureFrame()
    if not f then return end

    if not self:ShouldShow() then
        f:Hide()
        return
    end

    local powerType, powerToken = self:GetPowerType()
    local current = UnitPower("player", powerType)
    local maximum = UnitPowerMax("player", powerType)

    self:UpdateRadial(f, current, maximum, powerToken)
end







function RR:UpdateRadial(f, current, maximum, powerToken)
    
    
    
    
    
    
    local maxUnreadable = issecretvalue and issecretvalue(maximum)
    if not maxUnreadable then
        local m = maximum or 0
        if m <= 0 then
            f:Hide()
            return
        end
        maximum = m
    end

    
    
    if powerToken ~= self.lastPowerToken then
        self.lastPowerToken = powerToken
        local r, g, b = self:GetColor(powerToken)
        f:SetStatusBarColor(r, g, b, ThugUI_Config.resourceRingAlpha or 0.55)
    end

    
    
    
    
    self:ApplyDrainDirection(f)

    
    
    
    
    f:SetMinMaxValues(0, maximum)
    f:SetValue(current)

    f:Show()
end

function RR:UpdateColor()
    
    self.lastPowerToken = nil
    self:Update()
end





local driver = CreateFrame("Frame", "ThugUI_ResourceRingDriver")
RR.driver = driver




driver:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
driver:RegisterUnitEvent("UNIT_MAXPOWER", "player")

driver:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
driver:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")

driver:SetScript("OnEvent", function(self, event)
    
    
    if ThugUI.moduleOn and not ThugUI:IsModuleOn("rings") then
        if RR.frame then RR.frame:Hide() end
        self:UnregisterAllEvents()
        return
    end
    if event == "UNIT_DISPLAYPOWER" or event == "UPDATE_SHAPESHIFT_FORM" then
        
        RR:UpdateColor()
        return
    end
    RR:Update()
end)

function RR:Initialize()
    self:EnsureFrame()
    self:Update()
end

return RR
