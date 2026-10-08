










ThugUI = ThugUI or {}

local NP = {}
ThugUI.Nameplates = NP


NP.CVARS = {
    friendlyNameOnly = "nameplateShowOnlyNameForFriendlyPlayerUnits",
    friendlyClassNames = "nameplateUseClassColorForFriendlyPlayerUnitNames",
    friendlyClassBars = "nameplateShowFriendlyClassColor",
    friendlyNpcs = "nameplateShowFriendlyNpcs",
    enemyClassBars = "nameplateShowClassColor",
    style = "nameplateStyle",
    size = "nameplateSize",
    globalScale = "nameplateGlobalScale",
    occludedAlpha = "nameplateOccludedAlphaMult",
    minAlpha = "nameplateMinAlpha",
}


NP.inCombat = false


NP.plates = setmetatable({}, { __mode = "k" })     
NP.styled = setmetatable({}, { __mode = "k" })     
NP.targets = setmetatable({}, { __mode = "k" })    
NP.backdrops = setmetatable({}, { __mode = "k" })  
NP.outlines = setmetatable({}, { __mode = "k" })   
NP.levels = setmetatable({}, { __mode = "k" })     
NP.fullTouched = setmetatable({}, { __mode = "k" }) 


NP.borderTouched = setmetatable({}, { __mode = "k" })
NP.selectionTouched = setmetatable({}, { __mode = "k" })


NP.fullCurve = nil


NP.playerLevel = 1


NP.FONTS = {
    { value = "Fonts\\FRIZQT__.TTF", text = "Friz Quadrata" },
    { value = "Fonts\\ARIALN.TTF", text = "Arial Narrow" },
    { value = "Fonts\\MORPHEUS.TTF", text = "Morpheus" },
    { value = "Fonts\\SKURRI.TTF", text = "Skurri" },
}



local function HealthBarOf(uf)
    if type(uf) ~= "table" or type(uf.HealthBarsContainer) ~= "table" then return nil end
    local hb = uf.HealthBarsContainer.healthBar
    if type(hb) ~= "table" then return nil end
    return hb
end





function NP.HasCVar(name)
    local ok, result = pcall(function()
        return C_CVar and C_CVar.GetCVarInfo and C_CVar.GetCVarInfo(name) ~= nil
    end)
    return ok and result or false
end

function NP.GetCVarString(name)
    return GetCVar(name) or ""
end

function NP.GetCVarNumber(name, default)
    local val = GetCVar(name)
    return val and tonumber(val) or default or 0
end

function NP.GetCVarBool(name)
    return GetCVarBool(name) or false
end

function NP:SetCVarSafe(name, value)
    local ok, err = pcall(SetCVar, name, tostring(value))
    if not ok then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("NAMEPLATES", "SetCVar(%q, %q) failed: %s",
                name, tostring(value), tostring(err))
        end
        if self.inCombat then
            
            self._queuedCVarWrites = self._queuedCVarWrites or {}
            table.insert(self._queuedCVarWrites, { name, value })
        end
        return false
    end
    return true
end





function NP.LevelClass(classification)
    
    if classification == "worldboss" then
        return "boss"
    elseif classification == "rare" or classification == "rareelite" then
        return "rare"
    elseif classification == "elite" then
        return "elite"
    else
        return "normal"
    end
end

function NP.LevelText(level, classification)
    
    
    
    if type(level) ~= "number" or level < 1 then
        return "??"
    end
    local text = tostring(level)
    if classification == "elite" or classification == "rareelite" then
        text = text .. "+"
    end
    return text
end

function NP.LevelColor(playerLevel, level, canAttack)
    
    
    
    
    if type(level) ~= "number" or level < 1 then
        return 1, 0.1, 0.1
    end
    if canAttack and GetRelativeDifficultyColor then
        local color = GetRelativeDifficultyColor(playerLevel, level)
        if type(color) == "table" then
            return color.r or 1, color.g or 0, color.b or 0
        end
    end
    if UNIT_LEVEL_NON_ATTACKABLE then
        return UNIT_LEVEL_NON_ATTACKABLE.r or 1, UNIT_LEVEL_NON_ATTACKABLE.g or 0.82, UNIT_LEVEL_NON_ATTACKABLE.b or 0
    end
    return 1, 0.82, 0
end

function NP.ReadLevel(unit)
    
    
    local level, classification, canAttack

    local ok1, lv = pcall(UnitLevel, unit)
    if ok1 and not issecretvalue(lv) then
        level = lv
    end

    local ok2, cls = pcall(UnitClassification, unit)
    if ok2 and not issecretvalue(cls) then
        classification = cls
    end

    local ok3, canAtk = pcall(UnitCanAttack, "player", unit)
    if ok3 and not issecretvalue(canAtk) then
        canAttack = canAtk
    end

    return level, classification, canAttack
end





function NP:SyncFriendlyCVar()
    local cfg = ThugUIDB.Nameplates or {}
    local friendly = cfg.friendly or {}
    if not friendly.nameOnlyOutOfCombat then
        return
    end

    local desired = self.inCombat and "0" or "1"
    self:SetCVarSafe(self.CVARS.friendlyNameOnly, desired)
end

function NP:SetFriendlyNameOnly(enabled)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.friendly then cfg.friendly = {} end

    if enabled then
        
        if cfg.friendly.savedShowOnlyNames == nil then
            cfg.friendly.savedShowOnlyNames = self.GetCVarString(self.CVARS.friendlyNameOnly)
        end
        cfg.friendly.nameOnlyOutOfCombat = true
        self:SyncFriendlyCVar()
    else
        cfg.friendly.nameOnlyOutOfCombat = false
        
        if cfg.friendly.savedShowOnlyNames ~= nil then
            self:SetCVarSafe(self.CVARS.friendlyNameOnly, cfg.friendly.savedShowOnlyNames)
            cfg.friendly.savedShowOnlyNames = nil
        end
    end
end





function NP.ShouldNameOnly(unit)
    local cfg = ThugUIDB.Nameplates or {}
    local enemy = cfg.enemy or {}

    if not enemy.nameOnlyOutOfCombat or NP.inCombat then
        return false
    end

    
    
    
    local ok, isPlayer = pcall(UnitIsUnit, unit, "player")
    if not ok or issecretvalue(isPlayer) or isPlayer then
        return false
    end

    
    
    local ok2, isFriend = pcall(UnitIsFriend, "player", unit)
    if not ok2 or issecretvalue(isFriend) then
        return false
    end

    return not isFriend
end

function NP:ApplyToUnit(unit)
    local base = C_NamePlate.GetNamePlateForUnit(unit)
    if not base or base:IsForbidden() then
        return
    end

    local uf = base.UnitFrame
    if not uf or uf:IsForbidden() then
        return
    end

    local nameOnly = self.ShouldNameOnly(unit)
    local wasNameOnly = self.plates[uf] == true

    
    
    
    
    if not nameOnly and not wasNameOnly then
        
        
        self:StylePlate(uf, unit)
        return
    end

    
    
    if type(uf.HealthBarsContainer) == "table" then
        uf.HealthBarsContainer:SetShown(not nameOnly)
    end
    if type(uf.CastBarsContainer) == "table" then
        uf.CastBarsContainer:SetShown(not nameOnly)
    end

    
    self.plates[uf] = nameOnly or nil

    
    if nameOnly then
        if type(uf.name) == "table" then
            uf.name:Show()
            local color = self.NameColorFor(uf)
            uf.name:SetTextColor(color[1], color[2], color[3])
        end
    else
        
        
        
        
        
        if type(uf.name) == "table" then
            local ok = pcall(CompactUnitFrame_UpdateName, uf)
            if not ok and ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("NAMEPLATES", "CompactUnitFrame_UpdateName threw for unit %q", unit)
            end
        end
    end

    
    self:StylePlate(uf, unit)
end

function NP:ApplyAll()
    local plates = C_NamePlate.GetNamePlates()
    if not plates then
        return
    end

    for _, base in ipairs(plates) do
        local unit = base.namePlateUnitToken or (base.GetUnit and base:GetUnit())
        if unit then
            self:ApplyToUnit(unit)
        end
        
        
        if type(base.UnitFrame) == "table" then
            self:StylePlate(base.UnitFrame, unit)
        end
    end
end

function NP:SetEnemyNameOnly(enabled)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.enemy then cfg.enemy = {} end
    cfg.enemy.nameOnlyOutOfCombat = enabled
    self:ApplyAll()
end

function NP:SetEnemyNameOnlyColor(r, g, b)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.enemy then cfg.enemy = {} end
    cfg.enemy.nameOnlyColor = {r, g, b}
    self:ApplyAll()
end





function NP.NameColorFor(uf)
    
    
    
    if NP.targets[uf] then
        local cfg = ThugUIDB.Nameplates or {}
        local target = cfg.target or {}
        if target.highlight then
            return target.color
        end
    end
    local cfg = ThugUIDB.Nameplates or {}
    local enemy = cfg.enemy or {}
    return enemy.nameOnlyColor or {1.0, 0.25, 0.25}
end

local function LayoutOutline(hb, thickness)
    
    local outlines = NP.outlines[hb]
    if not outlines then return end

    local top, bottom, left, right = outlines.top, outlines.bottom, outlines.left, outlines.right
    local t = thickness or 2

    
    if top then
        top:ClearAllPoints()
        top:SetPoint("TOPLEFT", hb, "TOPLEFT", -t, t)
        top:SetPoint("TOPRIGHT", hb, "TOPRIGHT", t, t)
        top:SetHeight(t)
    end

    
    if bottom then
        bottom:ClearAllPoints()
        bottom:SetPoint("BOTTOMLEFT", hb, "BOTTOMLEFT", -t, -t)
        bottom:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", t, -t)
        bottom:SetHeight(t)
    end

    
    if left then
        left:ClearAllPoints()
        left:SetPoint("TOPLEFT", hb, "TOPLEFT", -t, t)
        left:SetPoint("BOTTOMLEFT", hb, "BOTTOMLEFT", -t, -t)
        left:SetWidth(t)
    end

    
    if right then
        right:ClearAllPoints()
        right:SetPoint("TOPRIGHT", hb, "TOPRIGHT", t, t)
        right:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", t, -t)
        right:SetWidth(t)
    end
end

function NP:StylePlate(uf, unit)
    
    
    
    local hb = HealthBarOf(uf)
    if not hb then return end

    
    if not NP.styled[hb] then
        
        
        
        local backdrop = hb:CreateTexture(nil, "BACKGROUND", nil, -1)
        backdrop:SetAllPoints(hb)
        backdrop:SetColorTexture(0, 0, 0, 0.6)
        backdrop:Hide()
        NP.backdrops[hb] = backdrop

        
        local top = hb:CreateTexture(nil, "OVERLAY", nil, 7)
        local bottom = hb:CreateTexture(nil, "OVERLAY", nil, 7)
        local left = hb:CreateTexture(nil, "OVERLAY", nil, 7)
        local right = hb:CreateTexture(nil, "OVERLAY", nil, 7)
        top:Hide()
        bottom:Hide()
        left:Hide()
        right:Hide()
        NP.outlines[hb] = { top = top, bottom = bottom, left = left, right = right }
        local cfg = ThugUIDB.Nameplates or {}
        LayoutOutline(hb, (cfg.target and cfg.target.thickness) or 2)

        
        
        if type(hb.SetIsTarget) == "function" then
            hooksecurefunc(hb, "SetIsTarget", function(_, isTarget)
                NP:OnTargetChanged(uf, hb, isTarget)
            end)
        elseif ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("NAMEPLATES", "SetIsTarget method not found on health bar")
        end

        
        NP.targets[uf] = (hb.isTarget == true)

        
        local levelText = hb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        levelText:SetJustifyH("RIGHT")
        levelText:SetPoint("RIGHT", hb, "RIGHT", -4, 0)
        NP.levels[hb] = levelText

        NP.styled[hb] = true
    end

    
    self:ApplyBorder(hb)
    self:UpdateTargetLook(uf, hb)
    self:UpdateLevel(uf, hb, unit)
    self:UpdateFullHide(uf, unit)
end

function NP:ApplyBorder(hb)
    
    if not hb or type(hb) ~= "table" then
        return
    end

    local cfg = ThugUIDB.Nameplates or {}
    local bars = cfg.bars or {}
    local hideBorder = bars.hideBorder

    
    
    if not hideBorder and not NP.borderTouched[hb] then
        return
    end

    local backdrop = NP.backdrops[hb]
    if hideBorder then
        
        if type(hb.bgTexture) == "table" then
            hb.bgTexture:SetAlpha(0)
            NP.borderTouched[hb] = true
        end
        if backdrop then
            backdrop:Show()
        end
    else
        
        if type(hb.bgTexture) == "table" then
            hb.bgTexture:SetAlpha(1)
        end
        if backdrop then
            backdrop:Hide()
        end
    end
end

function NP:OnTargetChanged(uf, hb, isTarget)
    
    
    if issecretvalue(isTarget) then
        return
    end

    NP.targets[uf] = (isTarget == true)
    self:UpdateTargetLook(uf, hb)
    
    
    
    if type(uf) == "table" and uf.HealthBarsContainer then
        local unit = uf.namePlateUnitToken
        if unit then
            self:UpdateFullHide(uf, unit)
        end
    end
end

function NP:UpdateTargetLook(uf, hb)
    
    
    if not hb or type(hb) ~= "table" then
        return
    end

    local cfg = ThugUIDB.Nameplates or {}
    local target = cfg.target or {}
    local isTarget = NP.targets[uf]
    local isNameOnly = NP.plates[uf]

    
    local outlines = NP.outlines[hb]
    if outlines and not isNameOnly then
        
        local show = target.highlight and isTarget
        local color = target.color or {1.0, 0.82, 0.0}
        for _, texture in pairs(outlines) do
            if show then
                texture:SetColorTexture(color[1], color[2], color[3], 1)
                texture:Show()
            else
                texture:Hide()
            end
        end
    end

    
    
    
    local shouldHideSelectedBorder = target.highlight and isTarget and not isNameOnly
    if type(hb.selectedBorder) == "table" then
        if shouldHideSelectedBorder then
            hb.selectedBorder:SetAlpha(0)
            NP.selectionTouched[hb] = true
        elseif NP.selectionTouched[hb] then
            hb.selectedBorder:SetAlpha(1)
        end
    end

    
    if isNameOnly and type(uf.name) == "table" then
        local color = NP.NameColorFor(uf)
        uf.name:SetTextColor(color[1], color[2], color[3])
    end
end

function NP:UpdateLevel(uf, hb, unit)
    
    
    
    if not hb or type(hb) ~= "table" then
        return
    end

    local cfg = ThugUIDB.Nameplates or {}
    local level = cfg.level or {}

    
    if not level.show then
        local text = NP.levels[hb]
        if text then
            text:Hide()
        end
        if type(uf.LevelFrame) == "table" then
            uf.LevelFrame:SetAlpha(1)
        end
        return
    end

    
    local lvl, classification, canAttack = NP.ReadLevel(unit)

    
    if lvl == nil and classification == nil then
        local text = NP.levels[hb]
        if text then
            text:Hide()
        end
        return
    end

    
    local text = NP.levels[hb]
    if not text then
        return
    end

    local cls = NP.LevelClass(classification)
    local fontPath = level.fonts and level.fonts[cls] or "Fonts\\FRIZQT__.TTF"
    local fontSize = level.size or 10

    text:SetFont(fontPath, fontSize, "OUTLINE")
    text:SetText(NP.LevelText(lvl, classification))
    local r, g, b = NP.LevelColor(NP.playerLevel, lvl, canAttack)
    text:SetTextColor(r, g, b)
    text:Show()

    
    if type(uf.LevelFrame) == "table" then
        uf.LevelFrame:SetAlpha(0)
    end
end

function NP:UpdateFullHide(uf, unit)
    
    
    local container = uf.HealthBarsContainer
    if type(container) ~= "table" then
        return
    end

    local cfg = ThugUIDB.Nameplates or {}
    local bars = cfg.bars or {}

    
    
    if not bars.hideWhenFull or not NP.fullCurve then
        if NP.fullTouched[uf] then
            container:SetAlpha(1)
            NP.fullTouched[uf] = nil
        end
        return
    end

    
    if NP.targets[uf] then
        container:SetAlpha(1)
        NP.fullTouched[uf] = true
        return
    end

    
    
    local ok, alpha = pcall(UnitHealthPercent, unit, true, NP.fullCurve)
    if ok then
        container:SetAlpha(alpha)
        NP.fullTouched[uf] = true
    elseif ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("NAMEPLATES", "UnitHealthPercent failed for unit %q", unit)
    end
end

function NP:SetHideBorder(v)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.bars then cfg.bars = {} end
    cfg.bars.hideBorder = v
    self:ApplyAll()
end

function NP:SetHideWhenFull(v)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.bars then cfg.bars = {} end
    cfg.bars.hideWhenFull = v
    self:ApplyAll()
end

function NP:SetTargetHighlight(v)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.target then cfg.target = {} end
    cfg.target.highlight = v
    self:ApplyAll()
end

function NP:SetTargetColor(r, g, b)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.target then cfg.target = {} end
    cfg.target.color = {r, g, b}
    self:ApplyAll()
end

function NP:SetTargetThickness(n)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.target then cfg.target = {} end
    cfg.target.thickness = n

    
    local plates = C_NamePlate.GetNamePlates()
    if plates then
        for _, base in ipairs(plates) do
            if type(base.UnitFrame) == "table" then
                local hb = HealthBarOf(base.UnitFrame)
                if hb and NP.styled[hb] then
                    LayoutOutline(hb, n)
                end
            end
        end
    end

    self:ApplyAll()
end

function NP:SetLevelShown(v)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.level then cfg.level = {} end
    cfg.level.show = v
    self:ApplyAll()
end

function NP:SetLevelSize(n)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.level then cfg.level = {} end
    cfg.level.size = n
    self:ApplyAll()
end

function NP:SetLevelFont(cls, path)
    local cfg = ThugUIDB.Nameplates or {}
    if not cfg.level then cfg.level = {} end
    if not cfg.level.fonts then cfg.level.fonts = {} end
    cfg.level.fonts[cls] = path
    self:ApplyAll()
end





function NP:Initialize()
    
    
    if C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        local curve = C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)          
        curve:SetPoints({ { x = 0, y = 1 }, { x = 1, y = 0 } })
        NP.fullCurve = curve
    end

    
    if _G.CompactUnitFrame_UpdateName then
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            if NP.plates[frame] then
                if type(frame.name) == "table" then
                    frame.name:Show()
                    local color = NP.NameColorFor(frame)
                    frame.name:SetTextColor(color[1], color[2], color[3])
                end
            end
        end)
    end

    
    local eventFrame = CreateFrame("Frame")

    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "NAME_PLATE_UNIT_ADDED" then
            NP:ApplyToUnit(arg1)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            local base = C_NamePlate.GetNamePlateForUnit(arg1)
            
            
            if base and type(base.UnitFrame) == "table" then
                local uf = base.UnitFrame
                if NP.plates[uf] then
                    if type(uf.HealthBarsContainer) == "table" then
                        uf.HealthBarsContainer:Show()
                    end
                    if type(uf.CastBarsContainer) == "table" then
                        uf.CastBarsContainer:Show()
                    end
                    NP.plates[uf] = nil
                end
                
                
                if NP.fullTouched[uf] then
                    if type(uf.HealthBarsContainer) == "table" then
                        uf.HealthBarsContainer:SetAlpha(1)
                    end
                    NP.fullTouched[uf] = nil
                end
                
                local hb = HealthBarOf(uf)
                if hb then
                    local outlines = NP.outlines[hb]
                    if outlines then
                        for _, texture in pairs(outlines) do
                            texture:Hide()
                        end
                    end
                end
                NP.targets[uf] = nil
            end
        elseif event == "PLAYER_REGEN_DISABLED" then
            NP.inCombat = true
            NP:SyncFriendlyCVar()
            NP:ApplyAll()
        elseif event == "PLAYER_REGEN_ENABLED" then
            NP.inCombat = false
            
            if NP._queuedCVarWrites then
                for _, entry in ipairs(NP._queuedCVarWrites) do
                    NP:SetCVarSafe(entry[1], entry[2])
                end
                NP._queuedCVarWrites = {}
            end
            NP:SyncFriendlyCVar()
            NP:ApplyAll()
        elseif event == "PLAYER_ENTERING_WORLD" then
            NP.inCombat = InCombatLockdown()
            
            local ok, lv = pcall(UnitLevel, "player")
            if ok and not issecretvalue(lv) then
                NP.playerLevel = lv
            end
            NP:SyncFriendlyCVar()
            NP:ApplyAll()
        elseif event == "PLAYER_LEVEL_UP" then
            
            if type(arg1) == "number" then
                NP.playerLevel = arg1
            end
            NP:ApplyAll()
        elseif event == "PLAYER_TARGET_CHANGED" then
            
            NP:ApplyAll()
        elseif event == "UNIT_LEVEL" then
            
            if arg1 and arg1:match("^nameplate") then
                local base = C_NamePlate.GetNamePlateForUnit(arg1)
                if base and type(base.UnitFrame) == "table" then
                    local hb = HealthBarOf(base.UnitFrame)
                    if hb then
                        NP:UpdateLevel(base.UnitFrame, hb, arg1)
                    end
                end
            end
        elseif event == "UNIT_CLASSIFICATION_CHANGED" then
            
            if arg1 and arg1:match("^nameplate") then
                local base = C_NamePlate.GetNamePlateForUnit(arg1)
                if base and type(base.UnitFrame) == "table" then
                    local hb = HealthBarOf(base.UnitFrame)
                    if hb then
                        NP:UpdateLevel(base.UnitFrame, hb, arg1)
                    end
                end
            end
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            
            
            if arg1 and arg1:match("^nameplate") then
                local base = C_NamePlate.GetNamePlateForUnit(arg1)
                
                
                if base and not base:IsForbidden() and type(base.UnitFrame) == "table"
                    and not base.UnitFrame:IsForbidden() then
                    NP:UpdateFullHide(base.UnitFrame, arg1)
                end
            end
        end
    end)

    
    ThugUI.SafeRegisterEvent(eventFrame, "NAME_PLATE_UNIT_ADDED")
    ThugUI.SafeRegisterEvent(eventFrame, "NAME_PLATE_UNIT_REMOVED")
    ThugUI.SafeRegisterEvent(eventFrame, "PLAYER_LEVEL_UP")
    ThugUI.SafeRegisterEvent(eventFrame, "UNIT_LEVEL")
    ThugUI.SafeRegisterEvent(eventFrame, "UNIT_CLASSIFICATION_CHANGED")
    ThugUI.SafeRegisterEvent(eventFrame, "UNIT_HEALTH")
    ThugUI.SafeRegisterEvent(eventFrame, "UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
end

ThugUI:RegisterModule("Nameplates", NP)










