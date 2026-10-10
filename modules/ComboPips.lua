







































ThugUI = ThugUI or {}
ThugUI_Config = ThugUI_Config or {}

local CP = {}
ThugUI.ComboPips = CP

CP.frame = nil
CP.pips = {}
CP.lastCount = nil
CP.lastMax = nil
CP.lastToken = nil

local DEFAULT_SIZE = 9
local DEFAULT_OFFSET = 7
local DEFAULT_DIM = 0.25









local CLASS_POWER = {
    ROGUE   = { power = "ComboPoints",    token = "COMBO_POINTS" },
    DRUID   = { power = "ComboPoints",    token = "COMBO_POINTS", catOnly = true },
    PALADIN = { power = "HolyPower",      token = "HOLY_POWER" },
    WARLOCK = { power = "SoulShards",     token = "SOUL_SHARDS" },
    MONK    = { power = "Chi",            token = "CHI" },
    MAGE    = { power = "ArcaneCharges",  token = "ARCANE_CHARGES" },
    EVOKER  = { power = "Essence",        token = "ESSENCE" },
}


function CP:GetPowerType()
    local _, class = UnitClass("player")
    local entry = CLASS_POWER[class]
    if not entry then return nil end

    local powerType = Enum and Enum.PowerType and Enum.PowerType[entry.power]
    if powerType == nil then return nil end

    
    
    
    if entry.catOnly then
        local energy = Enum.PowerType.Energy
        local primary = UnitPowerType and UnitPowerType("player")
        if energy == nil or primary ~= energy then return nil end
    end

    return powerType, entry.token
end



function CP:GetColor(powerToken, _index)
    return self:ResolveColor(ThugUI_Config.comboPipColorMode or "power",
        ThugUI_Config.comboPipCustomColor, powerToken)
end




function CP:ResolveColor(mode, custom, powerToken)
    mode = mode or "power"

    if mode == "class" then
        local _, class = UnitClass("player")
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
        return 1, 1, 1
    end

    if mode == "custom" then
        local c = custom
        if c then return c.r or c[1] or 1, c.g or c[2] or 1, c.b or c[3] or 1 end
        return 1, 1, 1
    end

    local color = powerToken and PowerBarColor and PowerBarColor[powerToken]
    if color and color.r then return color.r, color.g, color.b end
    return 1, 0.85, 0.3
end





function CP:EnsureFrame()
    if self.frame then return self.frame end
    if not ThugUI_CursorFrame then return nil end

    
    
    
    
    local f = CreateFrame("Frame", "ThugUI_ComboPips", UIParent)
    f:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    f:SetSize(1, 1)
    
    f:SetFrameStrata("HIGH")
    f:Hide()

    self.frame = f
    return f
end




function CP:AcquirePip(index)
    local existing = self.pips[index]
    if existing then return existing end

    local f = self:EnsureFrame()
    if not f then return nil end

    local pip = f:CreateTexture(nil, "OVERLAY")
    pip:SetTexture("Interface\\AddOns\\ThugUI\\media\\Reticle_Dot")
    self.pips[index] = pip
    return pip
end



function CP:Layout(count)
    local f = self:EnsureFrame()
    if not f then return end

    local ER = ThugUI.EssentialRings
    local cast = ER and ER.CastFrame
    local diameter = 90
    if cast and cast.GetSize then
        local width = cast:GetSize()
        if width and width > 0 then diameter = width end
    end

    local size = ThugUI_Config.comboPipSize or DEFAULT_SIZE
    local radius = diameter / 2 + (ThugUI_Config.comboPipOffset or DEFAULT_OFFSET)

    
    
    
    
    
    if radius < 0 then radius = 0 end

    local start = 0
    if ER and ER.ClockToRadians then
        start = ER:ClockToRadians(ThugUI_Config.castRotation or 12)
    end

    for i = 1, count do
        local pip = self:AcquirePip(i)
        if pip then
            
            
            local angle = start + (i - 1) * (2 * math.pi / count)
            pip:SetSize(size, size)
            pip:ClearAllPoints()
            pip:SetPoint("CENTER", f, "CENTER",
                math.sin(angle) * radius, math.cos(angle) * radius)
            pip:Show()
        end
    end

    
    for i = count + 1, #self.pips do
        self.pips[i]:Hide()
    end
end


function CP:Paint(filled, powerToken, max)
    local dim = ThugUI_Config.comboPipDimAlpha or DEFAULT_DIM

    for i = 1, max do
        local pip = self.pips[i]
        if pip then
            local r, g, b = self:GetColor(powerToken, i)
            pip:SetVertexColor(r, g, b)
            pip:SetAlpha(i <= filled and 1 or dim)
        end
    end
end





local function InCombat()
    local ER = ThugUI.EssentialRings
    if ER and ER.IsInCombat then return ER:IsInCombat() end
    return InCombatLockdown()
end

function CP:ShouldShow()
    
    
    
    if not ThugUI:IsModuleOn("rings") then return false end
    if not ThugUI_Config.showComboPips then return false end
    if not ThugUI_CursorFrame then return false end

    local mode = ThugUI_Config.comboPipVisibility or "combat"
    if mode == "rings" then return ThugUI_CursorFrame:IsShown() end
    if mode == "combat" then return InCombat() end
    return true
end






function CP:Read()
    local powerType, powerToken = self:GetPowerType()
    if not powerType then
        
        
        return "none"
    end

    local current = UnitPower("player", powerType)
    local maximum = UnitPowerMax("player", powerType)

    
    
    if issecretvalue and (issecretvalue(current) or issecretvalue(maximum)) then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("pips-secret", "PIPS",
                "UnitPower unreadable (secret value) for %s — secondary resources "
                .. "are expected to become readable in 12.1", tostring(powerToken))
        end
        return "secret", nil, nil, powerToken
    end

    current = current or 0
    maximum = maximum or 0
    if maximum <= 0 then return "none" end
    if current < 0 then current = 0 elseif current > maximum then current = maximum end
    return "ok", current, maximum, powerToken
end

function CP:Update()
    local f = self:EnsureFrame()
    if not f then return end

    if not self:ShouldShow() then
        f:Hide()
        return
    end

    local kind, current, maximum, powerToken = self:Read()

    if kind == "none" then
        f:Hide()
        self.lastCount, self.lastMax = nil, nil
        return
    end

    if kind == "secret" then
        
        
        
        if self.lastMax then
            f:Show()
        else
            f:Hide()
        end
        return
    end

    
    
    if self.lastMax ~= maximum then
        self.lastMax = maximum
        self:Layout(maximum)
        self.lastCount = nil
    end

    if self.lastCount ~= current or self.lastToken ~= powerToken then
        self.lastCount = current
        self.lastToken = powerToken
        self:Paint(current, powerToken, maximum)
    end

    f:Show()
end



function CP:Refresh()
    self.lastCount, self.lastMax, self.lastToken = nil, nil, nil
    self:Update()
end





local driver = CreateFrame("Frame", "ThugUI_ComboPipsDriver")
CP.driver = driver



driver:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
driver:RegisterUnitEvent("UNIT_MAXPOWER", "player")
driver:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")


driver:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
ThugUI.SafeRegisterEvent(driver, "PLAYER_SPECIALIZATION_CHANGED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")

driver:SetScript("OnEvent", function(_, event)
    if event == "UNIT_DISPLAYPOWER" or event == "UPDATE_SHAPESHIFT_FORM"
        or event == "PLAYER_SPECIALIZATION_CHANGED" then
        
        CP:Refresh()
        return
    end
    CP:Update()
end)

function CP:Initialize()
    self:EnsureFrame()
    self:Update()
end

return CP
