






















































ThugUI = ThugUI or {}
ThugUI_Config = ThugUI_Config or {}

local CV = ThugUI.CooldownViewer
if not CV then return end

local BB = {}
CV.BlizzBuffs = BB













local VIEWER_NAMES = {
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

BB.adopted = {}   
BB.taken = {}     
BB.lowered = {}   




local weak = { __mode = "k" }
local hookedViewers = setmetatable({}, weak)  



local baseWidth     = setmetatable({}, weak)  
local homeAnchor    = setmetatable({}, weak)  
local iconStrata    = setmetatable({}, weak)  





local function InCombat()
    local ER = ThugUI.EssentialRings
    if ER and ER.IsInCombat then return ER:IsInCombat() end
    return InCombatLockdown() or UnitAffectingCombat("player")
end




local function SpellLabel(icon)
    if icon.spellName then
        return ("%s (ID %s)"):format(tostring(icon.spellName), tostring(icon.spellID))
    end
    return ("ID %s"):format(tostring(icon.spellID))
end

function BB:IsEnabled()
    
    
    
    
    return ThugUI_Config.cvUseBlizzardBuffs ~= false
end













local chargeSpell = {}



function BB:ResetChargeCache()
    wipe(chargeSpell)
end






local function DetectChargeSpell(icon)
    local query = icon.spellName or icon.spellID
    if not query then return false end

    local ok, info = pcall(C_Spell.GetSpellCharges, query)
    if not ok or not info then return false end

    
    
    local maxCharges = info.maxCharges
    if issecretvalue and issecretvalue(maxCharges) then return nil end
    if maxCharges == nil then return false end
    return maxCharges > 1
end

function BB:IsChargeSpell(icon)
    local id = icon.spellID
    if not id then return false end

    local known = chargeSpell[id]
    if known ~= nil then return known end

    local detected = DetectChargeSpell(icon)
    if detected == nil then return false end
    chargeSpell[id] = detected
    return detected
end





































function BB:ShouldAdopt(icon)
    if not icon.spellID then return false end
    if icon.mode == "proc" then return false end
    if icon.mode == "recharging" then return false end
    if icon.mode == "aura" or icon.mode == "always" then return true end
    return false
end





local function Viewers()
    local out = {}
    for _, name in ipairs(VIEWER_NAMES) do
        local frame = _G[name]
        if frame then out[#out + 1] = frame end
    end
    return out
end






local function ItemFrames(viewer)
    local out = {}

    local pool = viewer.itemFramePool
    if pool and pool.EnumerateActive then
        local ok = pcall(function()
            for item in pool:EnumerateActive() do out[#out + 1] = item end
        end)
        if ok and #out > 0 then return out end
    end

    if viewer.GetItemFrames then
        local ok, frames = pcall(viewer.GetItemFrames, viewer)
        if ok and type(frames) == "table" then
            for _, item in ipairs(frames) do out[#out + 1] = item end
        end
    end

    return out
end






function BB:ItemsByCooldownID()
    local map = {}

    for _, viewer in ipairs(Viewers()) do
        self:HookViewer(viewer)

        for _, item in ipairs(ItemFrames(viewer)) do
            if item.GetCooldownID then
                local ok, id = pcall(item.GetCooldownID, item)
                if ok and id then map[id] = item end
            end
        end
    end

    return map
end








function BB:ItemForCooldownID(cooldownID)
    if not cooldownID then return nil end
    return self:ItemsByCooldownID()[cooldownID]
end















local function LowerIcon(icon, viewer)
    if iconStrata[icon] == nil then
        iconStrata[icon] = icon:GetFrameStrata() or false
    end
    icon:SetFrameStrata(viewer:GetFrameStrata())
end

local function RestoreIcon(icon)
    local strata = iconStrata[icon]
    if strata then icon:SetFrameStrata(strata) end
    iconStrata[icon] = nil
end






local function RememberHome(item)
    if homeAnchor[item] ~= nil then return end

    local point, relativeTo, relativePoint, x, y = item:GetPoint()
    homeAnchor[item] = point and { point, relativeTo, relativePoint, x, y } or false
end

















local function FitItem(item, iconSize, cell)
    
    
    
    
    
    if not baseWidth[item] then
        local width = item:GetWidth()
        if not width or width <= 0 then return end
        baseWidth[item] = width
    end

    if not iconSize or not cell then return end

    local parent = item:GetParent()
    local theirs = (parent and parent:GetEffectiveScale()) or 1
    local ours = cell:GetEffectiveScale() or 1
    if theirs <= 0 then return end

    local scale = (iconSize * ours) / (baseWidth[item] * theirs)
    item:SetScale(scale)

    
    
    
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:LogOnce("blizzbuffs-fit", "CVBUFF",
            "fit: base=%.1f icon=%d ours=%.3f theirs=%.3f -> scale=%.3f",
            baseWidth[item], iconSize, ours, theirs, scale)
    end
end


local function ReleaseItem(item)
    if baseWidth[item] ~= nil then
        item:SetScale(1)
        baseWidth[item] = nil
    end

    local home = homeAnchor[item]
    if home then
        item:ClearAllPoints()
        item:SetPoint(home[1], home[2], home[3], home[4], home[5])
    end
    homeAnchor[item] = nil
end





function BB:AdoptedItem(icon)
    return self.adopted[icon]
end























function BB:ItemIsShown(item)
    if not item or not item.IsShown then return nil end

    local ok, shown = pcall(item.IsShown, item)
    if not ok then return nil end

    
    
    if not issecretvalue then return nil end
    if issecretvalue(shown) then return nil end

    return shown and true or false
end


function BB:Release()
    if not next(self.adopted) and not next(self.taken) and not next(self.lowered) then
        return
    end

    for item in pairs(self.taken) do ReleaseItem(item) end
    for icon in pairs(self.lowered) do RestoreIcon(icon) end

    wipe(self.adopted)
    wipe(self.taken)
    wipe(self.lowered)
end



function BB:Apply()
    local container = CV.container

    
    
    
    if not self:IsEnabled() or not container or not container:IsShown() then
        self:Release()
        return
    end

    local Data = CV.Data
    if not Data then return end

    local profile = CV:CurrentProfile()
    local _, _, iconSize = CV:GetCellSize(profile)

    local map = self:ItemsByCooldownID()
    local stillTaken, stillLowered = {}, {}
    local count = 0

    
    
    
    if next(map) == nil and ThugUI.Diagnostics then
        ThugUI.Diagnostics:LogOnce("blizzbuffs-no-items", "CVBUFF",
            "no Blizzard cooldown-viewer item frames found — is the Cooldown Manager "
            .. "enabled and are these spells tracked in Edit Mode?")
    end

    wipe(self.adopted)

    for _, icon in pairs(CV.icons) do
        if self:ShouldAdopt(icon) then
            local info = Data.GetCooldownInfoForSpell(icon.spellID)

            
            
            
            
            
            
            
            local item
            for _, cooldownID in ipairs(Data.GetCooldownIDsForSpell(icon.spellID)) do
                item = map[cooldownID]
                if item then break end
            end
            
            
            if not item then
                item = info and info.cooldownID and map[info.cooldownID]
            end

            if item then
                local viewer = item:GetParent()
                if viewer then
                    LowerIcon(icon, viewer)
                    stillLowered[icon] = true
                end

                RememberHome(item)
                
                
                FitItem(item, iconSize, icon)
                item:ClearAllPoints()
                item:SetPoint("CENTER", icon, "CENTER", 0, 0)

                self.adopted[icon] = item
                stillTaken[item] = true
                count = count + 1

                
                
                
                
                
                
                
                
                
                
                if count == 1 and ThugUI.Diagnostics then
                    local inCombat = InCombat()
                    local shown = self:ItemIsShown(item)
                    ThugUI.Diagnostics:LogOnce(
                        ("blizzbuffs-shown-readable-%s"):format(tostring(inCombat)),
                        "CVBUFF", "spell %s: item IsShown %s (combat=%s)",
                        SpellLabel(icon),
                        shown == nil and "unreadable" or ("readable = " .. tostring(shown)),
                        tostring(inCombat))
                end
            else
                if ThugUI.Diagnostics then
                    local spellStr = SpellLabel(icon)
                    if not info then
                        ThugUI.Diagnostics:LogOnce(("blizzbuffs-no-info-%s"):format(tostring(icon.spellID)), "CVBUFF",
                            "spell %s: no Cooldown Manager entry", spellStr)
                    elseif #Data.GetCooldownIDsForSpell(icon.spellID) == 0
                            and not info.cooldownID then
                        ThugUI.Diagnostics:LogOnce(("blizzbuffs-no-cdid-%s"):format(tostring(icon.spellID)), "CVBUFF",
                            "spell %s: entry has no cooldown ID", spellStr)
                    else
                        
                        
                        
                        
                        ThugUI.Diagnostics:LogOnce(("blizzbuffs-no-item-%s"):format(tostring(icon.spellID)), "CVBUFF",
                            "spell %s: no matching item frame for any of its %d cooldown ids — either it is "
                            .. "not in Tracked Buffs, Tracked Bars, Essential Cooldowns or Utility "
                            .. "Cooldowns, or that viewer is not currently drawing it",
                            spellStr, #Data.GetCooldownIDsForSpell(icon.spellID))
                    end
                end
            end
        end
    end

    
    for item in pairs(self.taken) do
        if not stillTaken[item] then ReleaseItem(item) end
    end
    for icon in pairs(self.lowered) do
        if not stillLowered[icon] then RestoreIcon(icon) end
    end
    self.taken, self.lowered = stillTaken, stillLowered

    
    
    
    if count > 0 and ThugUI.Diagnostics then
        ThugUI.Diagnostics:LogOnce("blizzbuffs-adopted", "CVBUFF",
            "adopted %d Blizzard cooldown-viewer item(s) into grid cells", count)
    end
end







function BB:Queue()
    if self.queued then return end
    self.queued = true

    if not C_Timer or type(C_Timer.After) ~= "function" then
        self.queued = false
        self:Refresh()
        return
    end

    C_Timer.After(0, function()
        self.queued = false
        self:Refresh()
    end)
end

function BB:Refresh()
    
    
    
    if self.applying then return end
    self.applying = true
    local ok, err = pcall(function() self:Apply() end)
    if not ok and ThugUI.Diagnostics then
        pcall(function()
            ThugUI.Diagnostics:LogOnce(("blizzbuffs-err-%s"):format(tostring(err)), "CVBUFF",
                "Apply failed: %s", tostring(err))
        end)
    end
    self.applying = false
end

function BB:HookViewer(viewer)
    if hookedViewers[viewer] then return end
    hookedViewers[viewer] = true

    if type(viewer.RefreshLayout) == "function" then
        hooksecurefunc(viewer, "RefreshLayout", function() BB:Queue() end)
    end

    
    
    local container = viewer
    if type(viewer.GetItemContainerFrame) == "function" then
        local ok, frame = pcall(viewer.GetItemContainerFrame, viewer)
        if ok and frame then container = frame end
    end

    if container ~= viewer and type(container.Layout) == "function" then
        hooksecurefunc(container, "Layout", function() BB:Queue() end)
    elseif type(viewer.Layout) == "function" then
        hooksecurefunc(viewer, "Layout", function() BB:Queue() end)
    end
end









local driver = CreateFrame("Frame", "ThugUI_BlizzBuffsDriver")
BB.driver = driver

driver:RegisterEvent("PLAYER_ENTERING_WORLD")
ThugUI.SafeRegisterEvent(driver, "PLAYER_SPECIALIZATION_CHANGED")
driver:RegisterEvent("PLAYER_TALENT_UPDATE")
driver:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")

driver:SetScript("OnEvent", function(self)
    if not ThugUI:IsModuleOn("cooldowns") then self:UnregisterAllEvents() return end
    BB:Queue()
end)

return BB
