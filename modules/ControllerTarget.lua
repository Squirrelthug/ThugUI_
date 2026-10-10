













local ThugUI = _G.ThugUI
local CT = {}
ThugUI.ControllerTarget = CT
ThugUI:RegisterModule("ControllerTarget", CT)

ThugUI.defaults.ControllerTarget = {
    unlocked = false,
    target = {
        enabled = true, point = nil, width = 220, healthHeight = 20, powerHeight = 6,
        showPower = true, healthText = "percent", showName = true, showLevel = true,
        showFaction = true, showRole = true, auras = "below", auraSize = 22, auraMax = 16, auraPerRow = 8,
        scale = 1, textScale = 1, iconScale = 1, auraTextScale = 1, auraTimers = true, showDebuffs = true, showBuffs = true,
        dim = true, dimAmount = 0.5,  
    },
    tot = {
        enabled = true, point = nil, width = 140, healthHeight = 14, powerHeight = 4,
        showPower = true, healthText = "percent", showName = true, showLevel = false,
        showFaction = false, showRole = true, auras = "below", auraSize = 16, auraMax = 6, auraPerRow = 6,
        scale = 1, textScale = 1, iconScale = 1, auraTextScale = 1, auraTimers = true, showDebuffs = true, showBuffs = true,
        dim = true, dimAmount = 0.5,  
    }
}

local function Cfg() return ThugUIDB.ControllerTarget end

function CT:IsActive()
    if not ThugUI:IsModuleOn("targetframes") then return false end
    if ThugUI.UnitFrames then
        return ThugUI.UnitFrames:Active()
    end
    return ThugUI.ControllerMode ~= nil and ThugUI.ControllerMode:IsActive() and true or false
end














local hiddenParent = CreateFrame("Frame", nil, UIParent)
hiddenParent:Hide()

local blizzOff = false        
local reloadNoted = false     
local parkPending = false     
local hookedSetParent = false

local function EditModeOpen()
    local em = _G.EditModeManagerFrame
    return em and em.IsShown and em:IsShown() or false
end

local function Unreg(f)
    if type(f) == "table" and f.UnregisterAllEvents then f:UnregisterAllEvents() end
end




local function Repark()
    local tf = _G.TargetFrame
    if not tf or tf:GetParent() == hiddenParent then
        parkPending = false
        return
    end
    if InCombatLockdown() or EditModeOpen() then
        if not parkPending then
            parkPending = true
            C_Timer.After(0.25, function()
                parkPending = false
                Repark()
            end)
        end
        return
    end
    parkPending = false
    tf:SetParent(hiddenParent)
end

local function SwitchOffBlizzardTarget()
    local tf = _G.TargetFrame
    if not tf or blizzOff then return end
    if InCombatLockdown() then return end   
    blizzOff = true
    
    
    Unreg(tf)
    Unreg(tf.healthbar or tf.healthBar or tf.HealthBar
        or (tf.HealthBarsContainer and tf.HealthBarsContainer.healthBar))
    Unreg(tf.manabar or tf.ManaBar)
    Unreg(tf.spellbar or tf.castBar)
    Unreg(tf.powerBarAlt or tf.PowerBarAlt)
    Unreg(tf.BuffFrame or tf.AurasFrame)
    Unreg(tf.DebuffFrame)
    Unreg(tf.totFrame)
    tf:Hide()
    if not hookedSetParent then
        hookedSetParent = true
        hooksecurefunc(tf, "SetParent", function(_, parent)
            if parent ~= hiddenParent and blizzOff then
                
                C_Timer.After(0, Repark)
            end
        end)
    end
    Repark()
end

local pendingParking = false



local function NoControllerHere()
    local M = ThugUI.Modules
    return M and M.ForClient and not M:ForClient(M:Entry("controller")) or false
end

local function UsesFrame(which)
    local CM = ThugUI.ControllerMode
    if CM and CM:IsActive() then
        return CM:Uses(which)
    end
    
    
    if (ThugUI.UnitFrames and ThugUI.UnitFrames:IsMouseLayer()) or NoControllerHere() then
        local c = Cfg()
        return not (c and c[which] and c[which].enabled == false)
    end
    return false
end

function CT:ApplyParking()
    if InCombatLockdown() then
        pendingParking = true
        return
    end
    pendingParking = false

    
    
    local useTarget = UsesFrame("target")
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("TARGET", "parking: useTarget=%s blizzOff=%s active=%s",
            tostring(useTarget), tostring(blizzOff), tostring(CT:IsActive()))
    end
    if useTarget then
        SwitchOffBlizzardTarget()
    end
    if not useTarget then
        if blizzOff and not reloadNoted then
            reloadNoted = true
            
            
            
            print("|cff33ff99ThugUI|r: type |cffffd100/reload|r to bring Blizzard's target frame back.")
        end
    end
end

local frames = {}
local movers = {}

local function IsPoint(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
end







local function Num(v, fallback)
    return type(v) == "number" and v > 0 and v or fallback
end
local function FrameScale(c) return Num(c.scale, 1) end

local function DefaultPoint(key)
    local x = (UIParent:GetWidth() or 0) / 2
    local y = (UIParent:GetHeight() or 0) - 160
    if key == "tot" then x = x + 220 end
    return x, y
end



local baseFont = setmetatable({}, { __mode = "k" })
local function ScaleFont(fs, textScale)
    local b = baseFont[fs]
    if not b then
        local path, size, flags = fs:GetFont()
        if type(path) ~= "string" or type(size) ~= "number" then return end
        b = { path, size, flags }
        baseFont[fs] = b
    end
    fs:SetFont(b[1], b[2] * textScale, b[3])
end

local function MakeMover(key, label)
    local m = CreateFrame("Frame", "ThugUI_CTMover_" .. key, UIParent, "BackdropTemplate")
    m:SetFrameStrata("DIALOG")
    m:SetClampedToScreen(true)
    m:SetMovable(true)
    m:EnableMouse(true)
    m:RegisterForDrag("LeftButton")
    if m.SetBackdrop then
        m:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        
        
        m:SetBackdropColor(0, 0, 0, 0)
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
        if x then
            local k = (self:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
            Cfg()[key].point = { x = x * k, y = y * k }
            CT:Layout(key)
        end
    end)
    m:Hide()
    movers[key] = m
    return m
end

local function PlaceMover(m, key)
    local c = Cfg()[key]
    local s = FrameScale(c)
    m:SetSize(c.width * s, (c.healthHeight + (c.showPower and c.powerHeight or 0)) * s)
    m:ClearAllPoints()
    if IsPoint(c.point) then
        m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", c.point.x, c.point.y)
    else
        local x, y = DefaultPoint(key)
        m:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
end

function CT:ResetPosition(key)
    Cfg()[key].point = nil
    self:Layout(key)
    if self.unlocked then PlaceMover(movers[key], key) end
end

local function AuraPool_Acquire(pool)
    for _, btn in ipairs(pool) do
        if not btn:IsShown() and not btn.inUse then
            btn.inUse = true
            return btn
        end
    end
    local btn = CreateFrame("Frame", nil, pool.container)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints()
    btn.cooldown:SetDrawEdge(false)
    btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.count:SetPoint("BOTTOMRIGHT", 2, -2)
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetAllPoints()
    btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    btn.border:Hide()
    table.insert(pool, btn)
    btn.inUse = true
    return btn
end

local function UpdateAuras(f, unit, c)
    for _, btn in ipairs(f.auraPool) do
        btn.inUse = false
        btn:Hide()
    end
    
    if c.auras == "none" then
        f.auraContainer:Hide()
        return
    end
    
    f.auraContainer:Show()
    
    local function AddAuras(filter, isDebuff)
        if f.auraCount >= c.auraMax then return end
        
        
        
        
        
        
        
        
        local ok, result = pcall(function()
            for i = 1, 40 do
                if f.auraCount >= c.auraMax then break end
                local data = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
                if not data then break end
                do
                    local btn = AuraPool_Acquire(f.auraPool)
                    btn:SetSize(c.auraSize, c.auraSize)
                    
                    
                    
                    
                    
                    local ats = Num(c.auraTextScale, 1)
                    ScaleFont(btn.count, ats)
                    if btn.cooldown.SetHideCountdownNumbers then
                        btn.cooldown:SetHideCountdownNumbers(c.auraTimers == false)
                    end
                    if btn.cooldown.GetCountdownFontString then
                        local cfs = btn.cooldown:GetCountdownFontString()
                        if type(cfs) == "table" and cfs.GetFont then ScaleFont(cfs, ats) end
                    end
                    btn.icon:SetTexture(data.icon)
                    local countText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, data.auraInstanceID, 2, 999)
                    btn.count:SetText(countText)
                    local duration = C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID)
                    if duration then
                        btn.cooldown:SetCooldownFromDurationObject(duration)
                    else
                        btn.cooldown:Clear()
                    end
                    if isDebuff then
                        btn.border:SetVertexColor(1, 0, 0)
                        btn.border:Show()
                    else
                        btn.border:Hide()
                    end
                    btn:Show()
                    
                    local row = math.floor(f.auraCount / c.auraPerRow)
                    local col = f.auraCount % c.auraPerRow
                    
                    btn:ClearAllPoints()
                    if c.auras == "below" then
                        btn:SetPoint("TOPLEFT", f.auraContainer, "TOPLEFT", col * (c.auraSize + 2), -row * (c.auraSize + 2))
                    else
                        btn:SetPoint("BOTTOMLEFT", f.auraContainer, "BOTTOMLEFT", col * (c.auraSize + 2), row * (c.auraSize + 2))
                    end
                    
                    f.auraCount = f.auraCount + 1
                end
            end
        end)
        
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("ControllerTarget", "Aura update failed: " .. tostring(result))
        end
    end
    
    f.auraCount = 0
    if c.showDebuffs ~= false then AddAuras("HARMFUL", true) end
    if c.showBuffs ~= false then AddAuras("HELPFUL", false) end
end

local function SafeSecret(val)
    if issecretvalue and issecretvalue(val) then return nil end
    return val
end



local function UpdateUnit(f, key, skipAuras)
    
    if not f then return end
    local unit = f.unit
    local c = Cfg()[key]
    
    local exists = false
    local exRes = UnitExists(unit)
    if issecretvalue and issecretvalue(exRes) then
        exists = true
    else
        exists = exRes
    end
    
    if not (CT:IsActive() and c.enabled) then
        
        
        
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("ct-hide-" .. key .. tostring(CT:IsActive()) .. tostring(c.enabled),
                "TARGET", "%s hidden: active=%s enabled=%s mouseLayer=%s",
                key, tostring(CT:IsActive()), tostring(c.enabled), tostring(ThugUI.unitFramesMouse))
        end
        f:Hide()
        return
    end
    
    if not exists then
        if Cfg().unlocked then
            f.healthText:SetText(key == "target" and "Target" or "Target of target")
            f:Show()
        else
            f:Hide()
        end
        return
    end
    
    f:Show()
    
    
    local hMax = UnitHealthMax(unit)
    local hVal = UnitHealth(unit)
    f.healthBar:SetMinMaxValues(0, hMax)
    f.healthBar:SetValue(hVal)
    
    local r, g, b = 1, 1, 1
    local sIsPlayer = SafeSecret(UnitIsPlayer(unit))
    if sIsPlayer then
        local _, classFile = UnitClass(unit)
        local sClass = SafeSecret(classFile)
        local rc = sClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[sClass]
        if rc then r, g, b = rc.r, rc.g, rc.b end
    else
        local sCtrl = SafeSecret(UnitPlayerControlled(unit))
        local sTap = SafeSecret(UnitIsTapDenied(unit))
        if sCtrl == false and sTap == true then
            r, g, b = 0.5, 0.5, 0.5
        else
            local selColor = { UnitSelectionColor(unit) }
            if selColor[1] and not (issecretvalue and issecretvalue(selColor[1])) then
                r, g, b = unpack(selColor)
            end
        end
    end
    f.healthBar:SetStatusBarColor(r, g, b)
    
    
    if c.showPower then
        local _, token = UnitPowerType(unit)
        local sToken = SafeSecret(token)
        local pr, pg, pb = 0, 0.55, 1
        if sToken and PowerBarColor and PowerBarColor[sToken] then
            pr, pg, pb = PowerBarColor[sToken].r, PowerBarColor[sToken].g, PowerBarColor[sToken].b
        end
        f.powerBar:SetStatusBarColor(pr, pg, pb)
        f.powerBar:SetMinMaxValues(0, UnitPowerMax(unit))
        f.powerBar:SetValue(UnitPower(unit))
    end
    
    
    if c.showName then
        f.nameText:SetText(UnitName(unit))
    else
        f.nameText:SetText("")
    end
    
    if c.healthText == "percent" and UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        f.healthText:SetFormattedText("%d%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
    elseif c.healthText == "number" and AbbreviateLargeNumbers then
        f.healthText:SetText(AbbreviateLargeNumbers(hVal))
    else
        f.healthText:SetText("")
    end
    
    if c.showLevel then
        local lvl = UnitEffectiveLevel(unit)
        if issecretvalue and issecretvalue(lvl) then
            f.levelText:SetText(lvl)
            f.levelText:SetTextColor(1, 1, 1)
        elseif type(lvl) == "number" and lvl > 0 then
            f.levelText:SetText(lvl)
            local sAttack = SafeSecret(UnitCanAttack("player", unit))
            if sAttack and C_PlayerInfo and C_PlayerInfo.GetContentDifficultyCreatureForPlayer and GetDifficultyColor then
                local dc = GetDifficultyColor(C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unit))
                if dc then f.levelText:SetTextColor(dc.r, dc.g, dc.b) end
            else
                f.levelText:SetTextColor(1, 0.82, 0)
            end
        else
            f.levelText:SetText("??")
            f.levelText:SetTextColor(1, 0.1, 0.1)
        end
    else
        f.levelText:SetText("")
    end
    
    
    local iconOffset = 0
    f.roleIcon:Hide()
    f.factionIcon:Hide()
    
    if c.showRole then
        local role = UnitGroupRolesAssigned(unit)
        local sRole = SafeSecret(role)
        if sRole and sRole ~= "NONE" and GetMicroIconForRole then
            f.roleIcon:SetAtlas(GetMicroIconForRole(sRole))
            f.roleIcon:Show()
            f.roleIcon:ClearAllPoints()
            f.roleIcon:SetPoint("RIGHT", f.healthBar, "LEFT", -iconOffset - 2, 0)
            iconOffset = iconOffset + f.roleIcon:GetWidth() + 2
        end
    end
    
    if c.showFaction then
        local fac = UnitFactionGroup(unit)
        local sFac = SafeSecret(fac)
        if sFac == "Horde" then
            f.factionIcon:SetAtlas("UI-HUD-UnitFrame-Player-PVP-HordeIcon")
            f.factionIcon:Show()
            f.factionIcon:ClearAllPoints()
            f.factionIcon:SetPoint("RIGHT", f.healthBar, "LEFT", -iconOffset - 2, 0)
        elseif sFac == "Alliance" then
            f.factionIcon:SetAtlas("UI-HUD-UnitFrame-Player-PVP-AllianceIcon")
            f.factionIcon:Show()
            f.factionIcon:ClearAllPoints()
            f.factionIcon:SetPoint("RIGHT", f.healthBar, "LEFT", -iconOffset - 2, 0)
        end
    end
    
    
    if not skipAuras then UpdateAuras(f, unit, c) end
end

function CT:Build(key)
    if frames[key] then return frames[key] end
    
    local f = CreateFrame("Frame", key == "target" and "ThugUI_CTarget" or "ThugUI_CTargetTarget", UIParent)
    f:SetFrameStrata("LOW")
    f.unit = key == "target" and "target" or "targettarget"

    
    
    
    
    
    f:EnableMouse(true)
    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and not CT.unlocked and ThugUI.UnitMenuWindow then
            ThugUI.UnitMenuWindow:Open(self.unit, self)
        end
    end)
    f:SetScript("OnEnter", function(self)
        if GameTooltip_SetDefaultAnchor and UnitExists(self.unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            pcall(GameTooltip.SetUnit, GameTooltip, self.unit)
            GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f.healthBar = CreateFrame("StatusBar", nil, f)
    f.healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local bg = f.healthBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    local border = f.healthBar:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0, 0, 0, 1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    
    f.powerBar = CreateFrame("StatusBar", nil, f)
    f.powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")

    
    
    
    
    
    local level = f:GetFrameLevel()
    f.healthBar:SetFrameLevel(level + 1)
    f.powerBar:SetFrameLevel(level + 1)
    f.shadeFrame = CreateFrame("Frame", nil, f)
    f.shadeFrame:SetAllPoints(f)
    f.shadeFrame:SetFrameLevel(level + 2)
    f.shade = f.shadeFrame:CreateTexture(nil, "ARTWORK")
    f.shade:SetAllPoints()
    f.textFrame = CreateFrame("Frame", nil, f)
    f.textFrame:SetAllPoints(f)
    f.textFrame:SetFrameLevel(level + 3)

    f.levelText = f.textFrame:CreateFontString(nil, "OVERLAY", key == "tot" and "GameFontHighlightSmall" or "GameFontHighlight")
    f.levelText:SetJustifyH("LEFT")
    f.levelText:SetShadowOffset(1, -1)
    
    f.nameText = f.textFrame:CreateFontString(nil, "OVERLAY", key == "tot" and "GameFontHighlightSmall" or "GameFontHighlight")
    f.nameText:SetJustifyH("LEFT")
    f.nameText:SetWordWrap(false)
    f.nameText:SetShadowOffset(1, -1)
    
    f.healthText = f.textFrame:CreateFontString(nil, "OVERLAY", key == "tot" and "GameFontHighlightSmall" or "GameFontHighlight")
    f.healthText:SetJustifyH("RIGHT")
    f.healthText:SetShadowOffset(1, -1)
    
    f.roleIcon = f:CreateTexture(nil, "ARTWORK")
    f.roleIcon:SetSize(key == "target" and 16 or 12, key == "target" and 16 or 12)
    f.factionIcon = f:CreateTexture(nil, "ARTWORK")
    f.factionIcon:SetSize(key == "target" and 16 or 12, key == "target" and 16 or 12)
    
    f.auraContainer = CreateFrame("Frame", nil, f)
    f.auraPool = {}
    f.auraContainer:SetSize(1, 1)
    
    f.auraPool.container = f.auraContainer
    
    frames[key] = f
    return f
end






local SHADE_UNLOCKED = { 0.8, 0.05, 0.05, 0.5 }

local function ApplyShade(f, key, unlocked)
    if not (f and f.shade) then return end
    if unlocked then
        local c = SHADE_UNLOCKED
        f.shade:SetColorTexture(c[1], c[2], c[3], c[4])
        f.shade:Show()
        return
    end
    local c = Cfg()[key] or {}
    if c.dim == false then
        f.shade:Hide()
        return
    end
    local amount = tonumber(c.dimAmount) or 0.5
    if amount < 0 then amount = 0 elseif amount > 0.9 then amount = 0.9 end
    f.shade:SetColorTexture(0, 0, 0, amount)
    f.shade:Show()
end
CT.ApplyShade = ApplyShade

function CT:Layout(key)
    local f = frames[key]
    if not f then return end
    local c = Cfg()[key]
    
    local s = FrameScale(c)
    f:SetScale(s)
    f:SetSize(c.width, c.healthHeight + (c.showPower and c.powerHeight or 0))
    f:ClearAllPoints()
    local x, y
    if IsPoint(c.point) then
        x, y = c.point.x, c.point.y
    else
        x, y = DefaultPoint(key)
    end
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)

    local ts = Num(c.textScale, 1)
    ScaleFont(f.levelText, ts)
    ScaleFont(f.nameText, ts)
    ScaleFont(f.healthText, ts)
    local icon = (key == "target" and 16 or 12) * Num(c.iconScale, 1)
    f.roleIcon:SetSize(icon, icon)
    f.factionIcon:SetSize(icon, icon)
    
    f.healthBar:SetSize(c.width, c.healthHeight)
    f.healthBar:ClearAllPoints()
    f.healthBar:SetPoint("TOP", f, "TOP", 0, 0)
    
    if c.showPower then
        f.powerBar:Show()
        f.powerBar:SetSize(c.width, c.powerHeight)
        f.powerBar:ClearAllPoints()
        f.powerBar:SetPoint("TOP", f.healthBar, "BOTTOM", 0, 0)
    else
        f.powerBar:Hide()
    end
    
    f.healthText:SetPoint("RIGHT", f.healthBar, "RIGHT", -2, 0)
    
    f.levelText:ClearAllPoints()
    f.levelText:SetPoint("LEFT", f.healthBar, "LEFT", 2, 0)
    f.nameText:ClearAllPoints()
    f.nameText:SetPoint("LEFT", f.levelText, "RIGHT", 4, 0)
    f.nameText:SetPoint("RIGHT", f.healthText, "LEFT", -4, 0)
    
    ApplyShade(f, key, CT.unlocked)

    f.auraContainer:ClearAllPoints()
    if c.auras == "below" then
        if c.showPower then
            f.auraContainer:SetPoint("TOPLEFT", f.powerBar, "BOTTOMLEFT", 0, -2)
        else
            f.auraContainer:SetPoint("TOPLEFT", f.healthBar, "BOTTOMLEFT", 0, -2)
        end
    elseif c.auras == "above" then
        f.auraContainer:SetPoint("BOTTOMLEFT", f.healthBar, "TOPLEFT", 0, 2)
    end
    
    UpdateUnit(f, key)
end


function CT:SetUnlocked(unlocked)
    Cfg().unlocked = unlocked and true or false
    self.unlocked = unlocked
    for _, key in ipairs({"target", "tot"}) do
        if not movers[key] then MakeMover(key, key == "target" and "Target" or "Target of target") end
        ApplyShade(frames[key], key, self.unlocked)
        if self.unlocked then
            PlaceMover(movers[key], key)
            movers[key]:Show()
        else
            movers[key]:Hide()
        end
        UpdateUnit(frames[key], key)
    end
end

function CT:ApplyAll()
    self:Build("target")
    self:Build("tot")
    self:Layout("target")
    self:Layout("tot")
    self:ApplyParking()
    self:SetUnlocked(Cfg().unlocked)
end

local BAR_EVENTS = {
    UNIT_HEALTH = true, UNIT_MAXHEALTH = true, UNIT_POWER_UPDATE = true,
    UNIT_MAXPOWER = true, UNIT_DISPLAYPOWER = true,
}

local driver = CreateFrame("Frame")
driver.timeSince = 0

driver:SetScript("OnEvent", function(self, event, unit)
    if not ThugUI:IsModuleOn("targetframes") then self:UnregisterAllEvents() self:SetScript("OnUpdate", nil) return end
    
    
    if unit ~= nil and event:sub(1, 5) == "UNIT_" and unit ~= "target" then return end
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingParking then CT:ApplyParking() end
        if frames["target"] then UpdateUnit(frames["target"], "target") end
        if frames["tot"] then UpdateUnit(frames["tot"], "tot") end
    elseif event == "PLAYER_ENTERING_WORLD" then
        
        
        
        
        
        if not frames["target"] and CT:IsActive() then CT:ApplyAll() end
        if frames["target"] then UpdateUnit(frames["target"], "target") end
        if frames["tot"] then UpdateUnit(frames["tot"], "tot") end
    elseif event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
        if frames["target"] then UpdateUnit(frames["target"], "target") end
        if frames["tot"] then UpdateUnit(frames["tot"], "tot") end
    elseif event == "UNIT_TARGET" then
        if frames["tot"] then UpdateUnit(frames["tot"], "tot") end
    elseif BAR_EVENTS[event] then
        if frames["target"] then UpdateUnit(frames["target"], "target", true) end
    else
        if frames["target"] then UpdateUnit(frames["target"], "target") end
    end
end)



driver:SetScript("OnUpdate", function(self, elapsed)
    if frames["tot"] and frames["tot"]:IsShown() and CT:IsActive() and Cfg().tot.enabled then
        self.timeSince = self.timeSince + elapsed
        if self.timeSince > 0.2 then
            UpdateUnit(frames["tot"], "tot")
            self.timeSince = 0
        end
    end
end)

function CT:Initialize()
    ThugUI.ControllerMode:RegisterCallback(function()
        CT:ApplyAll()
    end)
    
    ThugUI.SafeRegisterEvent(driver, "PLAYER_TARGET_CHANGED")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(driver, "GROUP_ROSTER_UPDATE")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_ROLES_ASSIGNED")
    
    pcall(driver.RegisterUnitEvent, driver, "UNIT_HEALTH", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_MAXHEALTH", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_POWER_UPDATE", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_MAXPOWER", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_DISPLAYPOWER", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_AURA", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_NAME_UPDATE", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_LEVEL", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_FACTION", "target")
    pcall(driver.RegisterUnitEvent, driver, "UNIT_TARGET", "target")
    
    if ThugUI.Visibility then
        ThugUI.Visibility:Register("target", function(alpha)
            if frames["target"] then frames["target"]:SetAlpha(alpha) end
        end)
        ThugUI.Visibility:Register("tot", function(alpha)
            if frames["tot"] then frames["tot"]:SetAlpha(alpha) end
        end)
    end
end


CT.movers = movers
CT.frames = frames
CT.driver = driver
CT.hiddenParent = hiddenParent
CT.UpdateUnit = UpdateUnit
function CT:IsBlizzardTargetOff() return blizzOff end
