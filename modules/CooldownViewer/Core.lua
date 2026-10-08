















ThugUI = ThugUI or {}
ThugUI.CooldownViewer = ThugUI.CooldownViewer or {}

local CV = ThugUI.CooldownViewer
local Data = CV.Data

local UPDATE_INTERVAL = 0.15   
local CURSOR_GAP = 8           

CV.icons = {}          
CV.container = nil
CV.previewMode = false 





function CV:IsLegacyMode()
    return ThugUI_Config and ThugUI_Config.cvUseLegacy and true or false
end





function CV:CurrentProfile()
    if self.previewMode and self.overrideSpecID then
        return Data.GetProfile(self.overrideSpecID)
    end
    return Data.GetActiveProfile()
end



local function InCombat()
    local ER = ThugUI.EssentialRings
    if ER and ER.IsInCombat then return ER:IsInCombat() end
    return InCombatLockdown() or UnitAffectingCombat("player")
end













local function IsSpellAvailable(spellName)
    if not spellName then return false end
    local ok, info = pcall(C_Spell.GetSpellInfo, spellName)
    return (ok and info and info.spellID) and true or false
end





























local function Readable(v)
    if issecretvalue and issecretvalue(v) then return false end
    return v ~= nil
end















local function IsSpellReady(spellName)
    
    
    local ok, chargeInfo = pcall(C_Spell.GetSpellCharges, spellName)
    if ok and chargeInfo then
        
        
        
        
        
        local maxCharges = chargeInfo.maxCharges
        if not Readable(maxCharges) or maxCharges > 1 then
            local current = chargeInfo.currentCharges
            if Readable(current) then
                
                
                
                return current > 0, current, 1
            end

            
            
            
            
            
            
            if issecretvalue and issecretvalue(current) then
                return true, nil, current
            end
            
            
            return true, nil, 1
        end
    end

    local ok2, cdInfo = pcall(C_Spell.GetSpellCooldown, spellName)
    if ok2 and cdInfo then
        if cdInfo.isOnGCD then return true, nil, 1 end
        if cdInfo.isActive then return false, nil, 1 end
    end

    return true, nil, 1
end































local function ApplySweep(icon, spellName)
    local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, spellName)
    if not (ok and cdInfo and cdInfo.isActive and not cdInfo.isOnGCD) then
        icon.cooldown:Clear()
        return
    end

    if not (Readable(cdInfo.startTime) and Readable(cdInfo.duration)) then
        icon.cooldown:Clear()
        return
    end

    if not pcall(icon.cooldown.SetCooldown, icon.cooldown,
                 cdInfo.startTime, cdInfo.duration, cdInfo.modRate) then
        icon.cooldown:Clear()
    end
end





















local function IsItemAvailable(equipSlot)
    if not equipSlot or not ItemLocation or not ItemLocation.CreateFromEquipmentSlot then
        return false
    end
    
    
    
    
    
    
    
    local ok, loc = pcall(ItemLocation.CreateFromEquipmentSlot, ItemLocation, equipSlot)
    if not ok or not loc then return false end
    local ok2, valid = pcall(loc.IsValid, loc)
    return ok2 and valid and true or false
end


















local function IsItemReady(equipSlot)
    if not equipSlot or not GetInventoryItemCooldown then return true end

    local ok, startTime, duration = pcall(GetInventoryItemCooldown, "player", equipSlot)
    if not ok then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce(("item-cd-threw-%s"):format(tostring(equipSlot)),
                "CV", "GetInventoryItemCooldown threw for slot %s -- treating as ready",
                tostring(equipSlot))
        end
        return true
    end

    if not Readable(startTime) or not Readable(duration) then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce(("item-cd-unreadable-%s"):format(tostring(equipSlot)),
                "CV", "item cooldown for slot %s unreadable -- failing visible",
                tostring(equipSlot))
        end
        return true
    end

    return duration == 0
end







local function ApplyItemSweep(icon, equipSlot)
    if not equipSlot or not GetInventoryItemCooldown then
        icon.cooldown:Clear()
        return
    end

    local ok, startTime, duration = pcall(GetInventoryItemCooldown, "player", equipSlot)
    if not ok or not Readable(startTime) or not Readable(duration) or duration == 0 then
        icon.cooldown:Clear()
        return
    end

    if not pcall(icon.cooldown.SetCooldown, icon.cooldown, startTime, duration) then
        icon.cooldown:Clear()
    end
end




















local function ResolveCategoryItem(categoryID)
    if not categoryID or not C_Spell or not C_Spell.GetLastCategoryCooldownSource then
        return nil
    end

    local ok, spellID, itemID = pcall(C_Spell.GetLastCategoryCooldownSource, categoryID)
    if not ok then return nil end

    
    
    
    if not Readable(spellID) or not Readable(itemID) then return nil end
    return itemID
end







local function IsCategoryReady(itemID)
    if not itemID or not C_Item or not C_Item.GetItemCooldown then return true end

    local ok, startTime, duration = pcall(C_Item.GetItemCooldown, itemID)
    if not ok or not Readable(startTime) or not Readable(duration) then return true end

    return duration == 0
end






local function ApplyCategorySweep(icon, itemID)
    if not itemID or not C_Item or not C_Item.GetItemCooldown then
        icon.cooldown:Clear()
        return
    end

    local ok, startTime, duration = pcall(C_Item.GetItemCooldown, itemID)
    if not ok or not Readable(startTime) or not Readable(duration) or duration == 0 then
        icon.cooldown:Clear()
        return
    end

    if not pcall(icon.cooldown.SetCooldown, icon.cooldown, startTime, duration) then
        icon.cooldown:Clear()
    end
end







local function GetPlayerCastAura(spellID, spellName)
    if not spellID or not C_UnitAuras then return nil end

    
    
    
    
    
    
    
    
    
    
    
    local function Mine(aura)
        if not aura then return nil end

        local source = aura.sourceUnit
        if source == nil then return aura end
        if issecretvalue and issecretvalue(source) then return aura end

        return source == "player" and aura or nil
    end

    
    
    
    
    
    
    
    
    
    local function Note(stage)
        if ThugUI.Diagnostics then
            local inCombat = InCombat()
            ThugUI.Diagnostics:LogOnce(
                ("aura-%s-%s-%s"):format(tostring(spellID), stage, tostring(inCombat)),
                "AURA", "lookup for %s: %s (combat=%s)",
                tostring(spellID), stage, tostring(inCombat))
        end
    end

    if C_UnitAuras.GetUnitAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "player", spellID)
        if not ok then
            Note("api-threw")
        elseif aura == nil then
            Note("api-returned-nothing")
        elseif not Mine(aura) then
            Note("rejected-by-source-check")
        else
            Note("found")
            return aura
        end
    end

    if C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and Mine(aura) then
            Note("found-via-fallback")
            return Mine(aura)
        end
        Note("fallback-empty")
    end

    
    
    
    
    
    
    
    
    
    if C_UnitAuras.GetAuraDataByIndex then
        local name = spellName
        if not name and C_Spell and C_Spell.GetSpellInfo then
            local infoOK, info = pcall(C_Spell.GetSpellInfo, spellID)
            name = infoOK and info and info.name or nil
        end

        
        
        
        
        
        
        
        local seen, unreadable = 0, 0

        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not aura then break end
            seen = seen + 1

            local idOK, idMatch = pcall(function() return aura.spellId == spellID end)
            local nameOK, nameMatch = false, false
            if name then
                nameOK, nameMatch = pcall(function() return aura.name == name end)
            end

            if not idOK and not nameOK then unreadable = unreadable + 1 end

            if ((idOK and idMatch) or (nameOK and nameMatch)) and Mine(aura) then
                Note("found-by-index")
                return aura
            end
        end

        if seen == 0 then
            Note("index-scan-saw-no-auras")
        elseif unreadable > 0 then
            Note(("index-scan-%d-auras-%d-unreadable"):format(seen, unreadable))
        else
            Note(("index-scan-%d-auras-none-matched"):format(seen))
        end
    end
    return nil
end


















local function IsOverlayed(spellID)
    if not spellID or not C_SpellActivationOverlay then return false end
    local ok, overlayed = pcall(C_SpellActivationOverlay.IsSpellOverlayed, spellID)
    return ok and overlayed or false
end



local function FallbackGlow(icon, shown)
    if not shown and not icon.glowFallback then return end

    if not icon.glowFallback then
        local glow = icon:CreateTexture(nil, "OVERLAY")
        glow:SetPoint("TOPLEFT", -3, 3)
        glow:SetPoint("BOTTOMRIGHT", 3, -3)
        glow:SetColorTexture(1, 0.85, 0.25, 0.35)
        glow:SetBlendMode("ADD")
        icon.glowFallback = glow
    end
    icon.glowFallback:SetShown(shown)
end

local function SetGlow(icon, shown)
    if icon.glowing == shown then return end
    icon.glowing = shown

    local manager = ActionButtonSpellAlertManager
    if shown then
        if manager and pcall(manager.ShowAlert, manager, icon) then
            FallbackGlow(icon, false)
        else
            FallbackGlow(icon, true)
        end
    else
        if manager then pcall(manager.HideAlert, manager, icon) end
        FallbackGlow(icon, false)
    end
end



local function ShouldGlow(icon)
    if IsOverlayed(icon.spellID) then return true end

    if icon.spellName then
        local info = C_Spell.GetSpellInfo(icon.spellName)
        if info and info.spellID ~= icon.spellID and IsOverlayed(info.spellID) then
            return true
        end
    end
    return false
end











local function ResolveAura(icon)
    local aura = GetPlayerCastAura(icon.spellID, icon.spellName)
    if aura then return aura, icon.spellID end

    for _, linkedID in ipairs(icon.linkedSpellIDs or {}) do
        aura = GetPlayerCastAura(linkedID)
        if aura then return aura, linkedID end
    end
    return nil
end




















local function AdoptedCellWanted(icon, item)
    local shown = CV.BlizzBuffs and CV.BlizzBuffs:ItemIsShown(item)
    if shown ~= nil then return shown end

    
    
    
    if InCombat() then return true end

    
    
    
    
    
    if icon.mode ~= "aura" then return true end

    return ResolveAura(icon) ~= nil
end





function CV:GetCellSize(profile)
    local size = profile.iconSize or 32
    local pad = profile.padding or 4
    return size + pad, size + pad, size, pad
end




function CV:GetGridSize(profile)
    local cellW, cellH = self:GetCellSize(profile)
    return Data.GRID_COLS * cellW, Data.GRID_ROWS * cellH
end





function CV:EnsureContainer()
    if self.container then return self.container end

    local f = CreateFrame("Frame", "ThugUI_CooldownViewer", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)
    f:Hide()

    
    
    
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        local profile = CV:CurrentProfile()
        profile.point = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 1, 0.8, 0.10)
    bg:Hide()
    f.previewBG = bg

    
    
    
    
    
    
    
    
    local border = CreateFrame("Frame", nil, f)
    border:SetAllPoints()
    
    
    
    
    border:SetFrameLevel(f:GetFrameLevel() + 5)
    border:Hide()

    local function BorderLine()
        local line = border:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(0, 1, 0.8, 0.6)
        return line
    end

    local top = BorderLine()
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(1)

    local bottom = BorderLine()
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(1)

    local left = BorderLine()
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(1)

    local right = BorderLine()
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(1)

    f.dragBorder = border

    self.container = f
    return f
end




CV.iconPool = {}

local function AcquireIcon(parent)
    for _, icon in ipairs(CV.iconPool) do
        if not icon.inUse then
            icon.inUse = true
            return icon
        end
    end

    local icon = CreateFrame("Frame", nil, parent)

    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.tex = tex

    local cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(true)
    cd:SetHideCountdownNumbers(false)
    icon.cooldown = cd

    local count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", -2, 2)
    count:Hide()
    icon.count = count

    icon:Hide()
    icon.inUse = true
    table.insert(CV.iconPool, icon)
    return icon
end



function CV:Rebuild()
    local f = self:EnsureContainer()
    local profile = CV:CurrentProfile()

    
    
    
    
    
    
    
    Data.ResolveCategoryArt()

    for _, icon in ipairs(self.iconPool) do
        icon.inUse = false
        icon:Hide()
    end
    wipe(self.icons)

    local cellW, cellH, iconSize, pad = self:GetCellSize(profile)
    f:SetSize(self:GetGridSize(profile))
    f:SetScale(profile.scale or 1.0)

    for _, placement in ipairs(Data.GetPlacements(profile)) do
        local icon = AcquireIcon(f)
        icon:SetParent(f)
        icon:SetSize(iconSize, iconSize)

        
        
        
        
        
        
        
        
        
        
        local texture
        if placement.categoryID then
            local entry = Data.CategoryEntry(placement.categoryID)
            texture = entry and entry.icon
        else
            texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(placement.spellID)
        end
        icon.tex:SetTexture(texture)
        
        
        
        
        icon.tex:SetAlpha(1)
        
        icon.baseTexture = texture
        icon.spellID = placement.spellID
        
        
        
        
        icon.categoryID = placement.categoryID

        
        
        
        
        
        local cooldownInfo = Data.GetCooldownInfoForSpell(placement.spellID)
        icon.linkedSpellIDs = cooldownInfo and cooldownInfo.linkedSpellIDs or nil
        
        
        
        
        icon.equipSlot = cooldownInfo and cooldownInfo.equipSlot or nil
        
        
        
        
        
        local spellInfo = placement.spellID and C_Spell and C_Spell.GetSpellInfo
            and C_Spell.GetSpellInfo(placement.spellID)
        icon.spellName = spellInfo and spellInfo.name
        icon.mode = placement.mode
        icon.row, icon.col = placement.row, placement.col
        
        
        
        icon.wanted = true
        icon.cooldown:Clear()
        icon.count:Hide()

        self.icons[placement.key] = icon
    end

    self:ApplyLayout()
    self:UpdateVisibility()
    self:UpdateState()
end




function CV:ApplyLayout()
    local f = self.container
    if not f then return end

    local profile = CV:CurrentProfile()
    local cellW, cellH, _, pad = self:GetCellSize(profile)

    local mode = profile.collapse or "none"

    
    
    
    local pos = {}
    for _, icon in pairs(self.icons) do
        pos[icon] = { row = icon.row, col = icon.col }
    end

    local function Commit()
        for icon, p in pairs(pos) do
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", f, "TOPLEFT",
                (p.col - 1) * cellW + pad / 2,
                -((p.row - 1) * cellH + pad / 2))

            
            
            
            
            
            
            
            if icon.mode == "aura" and icon.loggedShown ~= icon.wanted then
                icon.loggedShown = icon.wanted
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("CV", "buff icon %s: %s at cell %d:%d (combat=%s)",
                        tostring(icon.spellName),
                        icon.wanted and "SHOWN" or "hidden",
                        p.row, p.col, tostring(InCombat()))
                end
            end
        end
    end

    if mode == "none" then
        Commit()
        return
    end

    
    
    
    
    local function Slot(i, n, first, last, packHigh)
        if packHigh then return last - (n - i) end
        return first + i - 1
    end

    
    
    
    
    
    
    
    
    local function Pass(major, minor, packMinorHigh, packMajorHigh)
        local groups, majors = {}, {}
        for icon in pairs(pos) do
            local key = pos[icon][major]
            if not groups[key] then
                groups[key] = {}
                table.insert(majors, key)
            end
            table.insert(groups[key], icon)
        end
        table.sort(majors)

        local liveGroups = {}
        for _, key in ipairs(majors) do
            table.sort(groups[key], function(a, b) return pos[a][minor] < pos[b][minor] end)
            for _, icon in ipairs(groups[key]) do
                if icon.wanted then
                    table.insert(liveGroups, key)
                    break
                end
            end
        end

        local firstMajor, lastMajor = majors[1], majors[#majors]

        for i, key in ipairs(liveGroups) do
            local group = groups[key]
            
            
            local majorSlot = Slot(i, #liveGroups, firstMajor, lastMajor, packMajorHigh)

            
            
            local firstMinor = pos[group[1] ][minor]
            local lastMinor = pos[group[#group] ][minor]

            local live = {}
            for _, icon in ipairs(group) do
                if icon.wanted then table.insert(live, icon) end
            end

            for j, icon in ipairs(live) do
                pos[icon][major] = majorSlot
                pos[icon][minor] = Slot(j, #live, firstMinor, lastMinor, packMinorHigh)
            end
        end
    end

    local packRight, packDown = Data.ResolveCollapseAxes(profile)

    if mode == "rows" or mode == "both" then
        Pass("row", "col", packRight, packDown)
    end
    if mode == "columns" or mode == "both" then
        Pass("col", "row", packDown, packRight)
    end

    Commit()

    
    
    
    if self.BlizzBuffs then self.BlizzBuffs:Refresh() end
end





function CV:UpdateState()
    if not self.container or not self.container:IsShown() then return end

    local glowEnabled = CV:CurrentProfile().showProcGlow ~= false

    
    
    
    if self.previewMode then
        for _, icon in pairs(self.icons) do
            icon.cooldown:Clear()
            icon.count:Hide()
            icon.wanted = true
            icon:Show()
            SetGlow(icon, false)
        end
        
        
        
        self:ApplyLayout()
        return
    end

    for _, icon in pairs(self.icons) do
        local spellID = icon.spellID
        local spellName = icon.spellName
        local show = false
        
        local procced = ShouldGlow(icon)

        
        
        
        
        
        
        
        
        icon:SetAlpha(1)

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        local adopted = self.BlizzBuffs and self.BlizzBuffs:AdoptedItem(icon)

        if adopted then
            show = AdoptedCellWanted(icon, adopted)
            icon.tex:SetAlpha(0)
            icon.cooldown:Clear()
            icon.count:Hide()
        elseif icon.equipSlot then
            
            
            
            
            
            
            
            if not IsItemAvailable(icon.equipSlot) then
                show = false
                icon.cooldown:Clear()
                icon.count:Hide()
            else
                local ready = IsItemReady(icon.equipSlot)

                if icon.mode == "always" then
                    show = true
                    ApplyItemSweep(icon, icon.equipSlot)
                elseif icon.mode == "recharging" then
                    
                    
                    show = not ready
                    ApplyItemSweep(icon, icon.equipSlot)
                elseif icon.mode == "proc" then
                    show = (ready and procced) and true or false
                    icon.cooldown:Clear()
                else
                    
                    show = ready and true or false
                    icon.cooldown:Clear()
                end
                
                icon.count:Hide()
            end
        elseif icon.categoryID then
            
            
            
            
            
            
            
            

            
            
            
            
            
            
            
            
            
            
            
            local entry = Data.CategoryEntry(icon.categoryID)
            local texture = entry and entry.icon
            if texture and texture ~= icon.baseTexture then
                icon.tex:SetTexture(texture)
                icon.baseTexture = texture
            end

            local itemID = ResolveCategoryItem(icon.categoryID)

            if not itemID then
                show = true
                icon.cooldown:Clear()
                icon.count:Hide()
            else
                local ready = IsCategoryReady(itemID)

                if icon.mode == "always" then
                    show = true
                    ApplyCategorySweep(icon, itemID)
                elseif icon.mode == "recharging" then
                    show = not ready
                    ApplyCategorySweep(icon, itemID)
                elseif icon.mode == "proc" then
                    show = (ready and procced) and true or false
                    icon.cooldown:Clear()
                else
                    show = ready and true or false
                    icon.cooldown:Clear()
                end
                icon.count:Hide()
            end
        elseif not IsSpellAvailable(spellName) then
            show = false
        elseif icon.mode == "aura" then
            local aura, auraSpellID = ResolveAura(icon)
            show = aura ~= nil

            
            
            
            
            if aura and auraSpellID ~= icon.spellID then
                icon.tex:SetTexture(C_Spell.GetSpellTexture(auraSpellID))
            else
                icon.tex:SetTexture(icon.baseTexture)
            end

            
            
            
            
            
            
            
            
            
            
            local swept = false
            if aura then
                local ok, didSweep = pcall(function()
                    if aura.expirationTime and aura.duration and aura.duration > 0 then
                        icon.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                        return true
                    end
                    return false
                end)
                swept = ok and didSweep
            end
            if not swept then icon.cooldown:Clear() end

            local stacked = false
            if aura then
                local ok, didStack = pcall(function()
                    if aura.applications and aura.applications > 1 then
                        icon.count:SetText(aura.applications)
                        icon.count:Show()
                        return true
                    end
                    return false
                end)
                stacked = ok and didStack
            end
            if not stacked then icon.count:Hide() end
        else
            local ready, charges, alpha = IsSpellReady(spellName)

            if icon.mode == "always" then
                show = true
                ApplySweep(icon, spellName)
            elseif icon.mode == "proc" then
                
                
                
                show = (ready and procced) and true or false
                icon.cooldown:Clear()
                
                
                
                
                icon:SetAlpha(alpha)
            elseif icon.mode == "recharging" then
                
                
                
                
                
                
                
                
                
                
                show = not ready
                ApplySweep(icon, spellName)
            else
                
                
                
                
                
                
                
                show = ready and true or false
                icon.cooldown:Clear()
                icon:SetAlpha(alpha)
            end

            if charges then
                icon.count:SetText(charges)
                icon.count:Show()
            else
                icon.count:Hide()
            end
        end

        icon.wanted = show
        icon:SetShown(show)

        
        
        SetGlow(icon, show and glowEnabled and procced or false)
    end

    self:ApplyLayout()
end


function CV:ShouldShow(forceCombat)
    if self:IsLegacyMode() then return false end
    if self.previewMode then return true end

    local profile = CV:CurrentProfile()
    if not profile.enabled then return false end
    if next(profile.placements) == nil then return false end

    local inCombat = forceCombat
    if inCombat == nil then inCombat = InCombat() end
    if profile.onlyInCombat and not inCombat then return false end
    return true
end






function CV:UpdateVisibility(forceCombat)
    local f = self.container
    if not f then return end

    if not self:ShouldShow(forceCombat) then
        f:Hide()
        self.anchoredToCursor = nil
        
        
        
        
        if self.BlizzBuffs then self.BlizzBuffs:Refresh() end
        return
    end

    local profile = CV:CurrentProfile()
    f:SetScale(profile.scale or 1.0)

    f.previewBG:SetShown(self.previewMode)

    
    
    
    
    
    
    
    
    
    local draggable = not profile.followCursor
        and (self.previewMode or (not profile.locked and not InCombatLockdown()))
    f:EnableMouse(draggable)
    f.dragBorder:SetShown(draggable)

    f:Show()

    local inCombat = forceCombat
    if inCombat == nil then inCombat = InCombat() end

    
    
    
    local wantCursor = profile.followCursor and (self.previewMode or inCombat)
    if wantCursor then
        self:UpdateCursorPosition()
        self.anchoredToCursor = true
    elseif self.anchoredToCursor ~= false then
        self:ReleaseAnchor()
        self.anchoredToCursor = false
    end
end






function CV:UpdateCursorPosition()
    local f = self.container
    if not f or not f:IsShown() then return end

    local profile = CV:CurrentProfile()
    local scale = f:GetScale()
    if scale == 0 then return end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    local x = cursorX / uiScale / scale
    local y = cursorY / uiScale / scale

    local cellW, cellH = self:GetCellSize(profile)
    local anchorOffsetX = (profile.anchorCol or 0) * cellW
    local anchorOffsetY = (profile.anchorRow or 0) * cellH

    
    
    
    
    
    
    
    
    
    local gap = CURSOR_GAP / scale
    local packRight, packDown = Data.ResolveAutoAxes(profile)
    local gapX = packRight and -gap or gap
    local gapY = packDown and gap or -gap

    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
        x - anchorOffsetX + gapX,
        y + anchorOffsetY + gapY)
end


function CV:ReleaseAnchor()
    local f = self.container
    if not f then return end

    local profile = CV:CurrentProfile()
    f:ClearAllPoints()
    if profile.point then
        f:SetPoint(profile.point.point, UIParent, profile.point.relPoint, profile.point.x, profile.point.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
end




function CV:SetPreview(enabled, specID)
    self.previewMode = enabled and true or false
    self.overrideSpecID = self.previewMode and specID or nil
    self:Rebuild()
end





local driver = CreateFrame("Frame", "ThugUI_CooldownViewerDriver")
CV.driver = driver

local elapsedSinceUpdate = 0

driver:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate >= UPDATE_INTERVAL then
        elapsedSinceUpdate = 0

        
        
        
        
        
        
        
        if not CV:IsLegacyMode() then
            CV:UpdateVisibility()
            CV:UpdateState()
        end
    end

    if not CV.container or not CV.container:IsShown() then return end

    
    local profile = CV:CurrentProfile()
    if profile.followCursor and (CV.previewMode or InCombat()) then
        CV:UpdateCursorPosition()
    end
end)





driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
ThugUI.SafeRegisterEvent(driver, "PLAYER_SPECIALIZATION_CHANGED")
driver:RegisterEvent("PLAYER_TALENT_UPDATE")
driver:RegisterEvent("SPELL_UPDATE_COOLDOWN")
driver:RegisterEvent("SPELL_UPDATE_CHARGES")
driver:RegisterEvent("SPELLS_CHANGED")
driver:RegisterEvent("UNIT_AURA")


driver:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
driver:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")

driver:SetScript("OnEvent", function(_, event, arg1)
    if not ThugUI:IsModuleOn("cooldowns") then _:UnregisterAllEvents() _:SetScript("OnUpdate", nil) return end
    if CV:IsLegacyMode() then
        if CV.container then CV.container:Hide() end
        return
    end

    if event == "PLAYER_LOGIN" then
        CV:Initialize()
        return
    end

    if event == "UNIT_AURA" then
        if arg1 == "player" then CV:UpdateState() end
        return
    end

    if event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "SPELLS_CHANGED"
        or event == "PLAYER_TALENT_UPDATE"
    then
        
        
        
        
        
        Data.InvalidateCooldownInfoCache()

        
        
        if CV.BlizzBuffs then CV.BlizzBuffs:ResetChargeCache() end

        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            
            
            
            
            Data.MigrateSpec(Data.GetActiveSpecID())
            if CV.Page then
                CV.Page.editSpecID = nil
                CV.Page.selectedKey = nil
            end
        end
        CV:Rebuild()
        if ThugUI.Window then ThugUI.Window:RefreshActivePage() end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        
        
        
        CV:UpdateVisibility(event == "PLAYER_REGEN_DISABLED")
        
        
        
        
        
        
        
        Data.ResolveCategoryArt()
        CV:UpdateState()
        return
    end

    CV:UpdateState()
end)





function CV:Initialize()
    Data.MigrateLegacyBars()
    self:EnsureContainer()
    self:Rebuild()
end



SLASH_THUGCV1 = "/thugcv"
SlashCmdList["THUGCV"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "legacy" then
        ThugUI_Config.cvUseLegacy = not ThugUI_Config.cvUseLegacy
        local ER = ThugUI.EssentialRings
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CV", "legacy bars %s",
                ThugUI_Config.cvUseLegacy and "ENABLED" or "disabled")
        end
        if ThugUI_Config.cvUseLegacy then
            if CV.container then CV.container:Hide() end
            print("|cff00ff00ThugUI:|r cooldown viewer switched to the |cffffd100legacy|r ECV/BCV/GCV bars.")
        else
            CV:Rebuild()
            print("|cff00ff00ThugUI:|r cooldown viewer switched to the |cff00ffccgrid|r engine.")
        end
        if ER and ER.UpdateVisibility then ER:UpdateVisibility() end
        return
    end

    
    
    
    if msg == "import" or msg == "import force" then
        local force = (msg == "import force")
        local specID = Data.GetActiveSpecID()
        local profile = Data.GetProfile(specID)

        if next(profile.placements) and not force then
            print("|cff00ff00ThugUI:|r " .. Data.GetSpecName(specID)
                .. " already has a layout. |cffffd100/thugcv import force|r to replace it.")
            return
        end

        if Data.MigrateSpec(specID, true) then
            CV:Rebuild()
            if ThugUI.Window then ThugUI.Window:RefreshActivePage() end
            print("|cff00ff00ThugUI:|r imported the old bar for "
                .. Data.GetSpecName(specID) .. ".")
        else
            print("|cff00ff00ThugUI:|r no old bar exists for "
                .. Data.GetSpecName(specID) .. " (only Balance, Guardian and "
                .. "Restoration ever had one).")
        end
        return
    end

    
    
    
    
    if msg == "probe" then
        ThugUI_BCVDump = ThugUI_BCVDump or {}
        ThugUI_BCVDump.cooldownViewer = {
            capturedAt = date("%Y-%m-%d %H:%M:%S"),
            spec = Data.GetSpecName(Data.GetActiveSpecID()),
            entries = Data.DumpCooldownViewer(),
        }
        local count = #ThugUI_BCVDump.cooldownViewer.entries
        print(("|cff00ff00ThugUI:|r probed %d cooldown entries into ThugUI_BCVDump. "
            .. "|cffffd100/reload|r to flush it to disk."):format(count))

        
        for _, entry in ipairs(ThugUI_BCVDump.cooldownViewer.entries) do
            if entry.linkedSpellIDs ~= "" then
                print(("  |cff00ffcc%s|r [%s] spellID=%s linked: %s")
                    :format(entry.name or "(no base spell)", entry.category,
                            tostring(entry.spellID), entry.linkedSpellIDs))
            end
        end
        return
    end

    if msg == "rebuild" then
        CV:Rebuild()
        print("|cff00ff00ThugUI:|r cooldown viewer rebuilt.")
        return
    end

    
    
    
    
    if msg == "status" then
        
        
        
        
        
        
        
        
        local print = function(...)
            local parts = {}
            for i = 1, select("#", ...) do
                parts[#parts + 1] = tostring((select(i, ...)))
            end
            local line = table.concat(parts, " ")
            _G.print(line)
            if ThugUI.Diagnostics then
                
                
                ThugUI.Diagnostics:Log("STATUS", "%s",
                    line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
            end
        end

        local specID = Data.GetActiveSpecID()
        local profile = Data.GetActiveProfile()
        local placed = 0
        for _ in pairs(profile.placements) do placed = placed + 1 end

        local function YesNo(value, goodIsTrue)
            local good = goodIsTrue and value or not value
            return (good and "|cff40ff40" or "|cffff4040") .. tostring(value and "yes" or "no") .. "|r"
        end

        print("|cff00ffccThugUI cooldown viewer|r")
        print(("  spec: %s (%s)"):format(Data.GetSpecName(specID), tostring(specID)))
        if not specID then
            print("  |cffff4040No spec ID — edits are not being saved. Relog.|r")
        end
        print("  legacy mode:      " .. YesNo(CV:IsLegacyMode(), false))
        print("  enabled:          " .. YesNo(profile.enabled, true))
        print("  icons placed:     " .. (placed > 0
            and ("|cff40ff40" .. placed .. "|r")
            or "|cffff40400|r"))
        print("  only in combat:   " .. tostring(profile.onlyInCombat)
            .. "   in combat now: " .. YesNo(InCombat(), true))
        print("  follow cursor:    " .. tostring(profile.followCursor))
        print("  locked:           " .. tostring(profile.locked))
        print("  preview forced:   " .. tostring(CV.previewMode))
        print("  collapse:         " .. tostring(profile.collapse)
            .. " (" .. Data.ResolveCollapseDirection(profile) .. ")")
        print("  |cffffd100would draw right now: " .. YesNo(CV:ShouldShow(), true) .. "|r")

        if not profile.enabled then
            print("  |cffffd100-> 'Enabled' is off for this spec. Tick it on the "
                .. "Cooldown Viewer page; preview ignores it, combat does not.|r")
        end

        local unknown = {}
        for _, placement in pairs(profile.placements) do
            
            
            
            if placement.spellID then
                local info = C_Spell.GetSpellInfo(placement.spellID)
                if not IsSpellAvailable(info and info.name) then
                    table.insert(unknown, (info and info.name or placement.spellID))
                end
            end
        end
        if #unknown > 0 then
            print(("  |cffffd100-> %d placed spell(s) do not resolve in this spec and will "
                .. "never draw: %s|r"):format(#unknown, table.concat(unknown, ", ")))
        end
        print("  container shown: " .. tostring(CV.container and CV.container:IsShown()))

        
        
        
        
        local auraIcons = {}
        for _, icon in pairs(CV.icons) do
            if icon.mode == "aura" then table.insert(auraIcons, icon) end
        end

        if #auraIcons > 0 then
            print("  |cff00ffccbuff-mode icons|r")
            for _, icon in ipairs(auraIcons) do
                local spellInfo = C_Spell.GetSpellInfo(icon.spellID)
                local linked = icon.linkedSpellIDs or {}
                local aura, auraSpellID = ResolveAura(icon)

                print(("    %s (%d): %d linked, %s")
                    :format(spellInfo and spellInfo.name or "?", icon.spellID, #linked,
                            aura and ("|cff40ff40active via " .. tostring(auraSpellID) .. "|r")
                                 or "|cffff4040no buff found|r"))

                if #linked == 0 then
                    print("      |cffffd100-> no linked spells: this entry was not matched to a "
                        .. "Cooldown Manager cooldown. Run /thugcv probe.|r")
                elseif not aura then
                    
                    local names = {}
                    for _, id in ipairs(linked) do
                        local info = C_Spell.GetSpellInfo(id)
                        table.insert(names, (info and info.name or "?") .. "(" .. id .. ")")
                    end
                    print("      looked for: " .. table.concat(names, ", "))
                end
            end
        end
        return
    end

    
    
    
    
    
    if msg ~= "" then
        print("|cff00ff00ThugUI:|r unknown /thugcv command '" .. msg .. "'. Try: "
            .. "|cffffd100status|r (what the viewer thinks it is doing, including "
            .. "buff-mode icons), |cffffd100probe|r, |cffffd100rebuild|r, "
            .. "|cffffd100import|r, |cffffd100import force|r, |cffffd100legacy|r.")
        return
    end

    ThugUI:ToggleOptions("cooldownviewer")
end

return CV
