














ThugUI = ThugUI or {}

local GearFlags = {}
ThugUI.GearFlags = GearFlags



local SLOT_NAMES = {
    [INVSLOT_HEAD] = "Head",
    [INVSLOT_NECK] = "Neck",
    [INVSLOT_SHOULDER] = "Shoulder",
    [INVSLOT_CHEST] = "Chest",
    [INVSLOT_WAIST] = "Waist",
    [INVSLOT_LEGS] = "Legs",
    [INVSLOT_FEET] = "Feet",
    [INVSLOT_WRIST] = "Wrist",
    [INVSLOT_HAND] = "Hands",
    [INVSLOT_FINGER1] = "Finger 1",
    [INVSLOT_FINGER2] = "Finger 2",
    [INVSLOT_BACK] = "Back",
    [INVSLOT_MAINHAND] = "Main Hand",
    [INVSLOT_OFFHAND] = "Off Hand",
    [INVSLOT_RANGED] = "Ranged",
}















local SLOT_FRAME_NAMES = {
    [INVSLOT_HEAD] = "Head",                        
    [INVSLOT_NECK] = "Neck",                        
    [INVSLOT_SHOULDER] = "Shoulder",                
    [INVSLOT_BODY] = "Shirt",                       
    [INVSLOT_CHEST] = "Chest",                      
    [INVSLOT_WAIST] = "Waist",                      
    [INVSLOT_LEGS] = "Legs",                        
    [INVSLOT_FEET] = "Feet",                        
    [INVSLOT_WRIST] = "Wrist",                      
    [INVSLOT_HAND] = "Hands",                       
    [INVSLOT_FINGER1] = "Finger0",                  
    [INVSLOT_FINGER2] = "Finger1",                  
    [INVSLOT_TRINKET1] = "Trinket0",                
    [INVSLOT_TRINKET2] = "Trinket1",                
    [INVSLOT_BACK] = "Back",                        
    [INVSLOT_MAINHAND] = "MainHand",                
    [INVSLOT_OFFHAND] = "SecondaryHand",            
    
    [INVSLOT_TABARD] = "Tabard",                    
}

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.GearFlags = ThugUIDB.GearFlags or {}
    return ThugUIDB.GearFlags
end






local function MigrateConfig()
    local cfg = Cfg()
    
    
    
    
    
    
    local currentVersion = 2

    
    if not cfg.slotListVersion or cfg.slotListVersion < currentVersion then
        
        cfg.enchantSlots = {
            [INVSLOT_HEAD] = true,
            [INVSLOT_SHOULDER] = true,
            [INVSLOT_CHEST] = true,
            [INVSLOT_LEGS] = true,
            [INVSLOT_FEET] = true,
            [INVSLOT_FINGER1] = true,
            [INVSLOT_FINGER2] = true,
            [INVSLOT_MAINHAND] = true,
            [INVSLOT_OFFHAND] = true,
        }
        cfg.slotListVersion = currentVersion
    end

    
    
    
    
    
    
    
    if cfg.showGlow ~= nil then
        cfg.showFlagBorder = cfg.showGlow ~= false
        cfg.showGlow = nil
    end
    cfg.showCornerIcons = nil
end





local function HasEnchant(link)
    if not link then return false end
    local itemString = link:match("item:([%-?%d:]+)")
    if not itemString then return false end
    local _, enchantID = strsplit(":", itemString)
    return enchantID ~= nil and enchantID ~= "" and enchantID ~= "0"
end

local function HasEmptySocket(link)
    if not link then return false end
    local numSockets = C_Item.GetItemNumSockets(link)
    if not numSockets or numSockets == 0 then return false end
    for index = 1, numSockets do
        local gemID = C_Item.GetItemGemID(link, index)
        if not gemID then
            return true  
        end
    end
    return false
end












local function IsSeasonSetPiece(link)
    if not link then return false end
    local data = ThugUI.modules and ThugUI.modules.SeasonalData
    if type(data) ~= "table" or type(data.IsSeasonSetPiece) ~= "function" then
        return false
    end
    
    
    local isSet = data.IsSeasonSetPiece(link)
    return isSet == true
end






local FLAG_THICKNESS = 3
local SET_THICKNESS = 3
local FLAG_COLOR = { 1, 0.1, 0.1 }    
local SET_COLOR = { 1, 0.82, 0 }      



local visualsByButton = setmetatable({}, { __mode = "k" })


function GearFlags:GetVisualsForTest(button)
    return visualsByButton[button]
end

local function GetSlotFrameName(slotID)
    
    
    local fragment = SLOT_FRAME_NAMES[slotID]
    if not fragment then return nil end
    return "Character" .. fragment .. "Slot"
end

local function GetSlotFrame(slotID)
    local frameName = GetSlotFrameName(slotID)
    if not frameName then return nil end
    return _G[frameName]
end

local function GetOrCreateVisuals(button)
    if not visualsByButton[button] then
        visualsByButton[button] = {}
    end
    return visualsByButton[button]
end










local function BuildBorder(button, key, thickness, color, outset, pulses)
    local visuals = GetOrCreateVisuals(button)
    if visuals[key] then
        return visuals[key]
    end

    local frame = CreateFrame("Frame", nil, button)
    frame:SetPoint("TOPLEFT", button, "TOPLEFT", -outset, outset)
    frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", outset, -outset)
    
    
    frame:SetFrameLevel((button:GetFrameLevel() or 0) + 5)

    local edges = {}
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local texture = frame:CreateTexture(nil, "OVERLAY")
        
        
        texture:SetColorTexture(color[1], color[2], color[3], 1)
        edges[edge] = texture
    end

    
    
    edges.TOP:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edges.TOP:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edges.TOP:SetHeight(thickness)
    edges.BOTTOM:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges.BOTTOM:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges.BOTTOM:SetHeight(thickness)
    edges.LEFT:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -thickness)
    edges.LEFT:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, thickness)
    edges.LEFT:SetWidth(thickness)
    edges.RIGHT:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -thickness)
    edges.RIGHT:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, thickness)
    edges.RIGHT:SetWidth(thickness)

    if pulses then
        local anim = frame:CreateAnimationGroup()
        anim:SetLooping("REPEAT")
        local alpha = anim:CreateAnimation("Alpha")
        alpha:SetDuration(0.8)
        alpha:SetFromAlpha(0.45)
        alpha:SetToAlpha(1.0)
        alpha:SetSmoothing("IN_OUT")
        
        
        frame.__animation = anim
    end

    frame:Hide()
    visuals[key] = frame
    return frame
end

local function BuildFlagBorder(button)
    return BuildBorder(button, "flagBorder", FLAG_THICKNESS, FLAG_COLOR, 0, true)
end



local function BuildSetBorder(button)
    return BuildBorder(button, "setBorder", SET_THICKNESS, SET_COLOR, FLAG_THICKNESS, false)
end

local function ShowBorder(border, shown)
    if not border then return end
    if shown then
        border:Show()
        if border.__animation then border.__animation:Play() end
    else
        border:Hide()
        if border.__animation then border.__animation:Stop() end
    end
end

local function HideAllBorders(visuals)
    if not visuals then return end
    ShowBorder(visuals.flagBorder, false)
    ShowBorder(visuals.setBorder, false)
end





local function UpdateSlot(slotID)
    if not Cfg().enabled then return end

    local button = GetSlotFrame(slotID)
    if not button then return end

    
    if slotID == INVSLOT_BODY or slotID == INVSLOT_TABARD then
        return
    end

    local link = GetInventoryItemLink("player", slotID)

    
    if not link then
        HideAllBorders(visualsByButton[button])
        return
    end

    
    local flagBorder = BuildFlagBorder(button)
    local setBorder = BuildSetBorder(button)

    
    local missingEnchant = false
    if Cfg().flagMissingEnchant and Cfg().enchantSlots[slotID] then
        
        
        if slotID == INVSLOT_OFFHAND then
            
            
            
            
            local _, _, _, _, _, itemClass = C_Item.GetItemInfoInstant(link)
            if itemClass and itemClass == Enum.ItemClass.Weapon then
                if not HasEnchant(link) then
                    missingEnchant = true
                end
            end
        elseif not HasEnchant(link) then
            missingEnchant = true
        end
    end

    
    local emptySocket = false
    if Cfg().flagEmptySocket then
        if HasEmptySocket(link) then
            emptySocket = true
        end
    end

    
    
    ShowBorder(flagBorder, Cfg().showFlagBorder and (missingEnchant or emptySocket) or false)

    ShowBorder(setBorder, Cfg().showSetBorder and IsSeasonSetPiece(link) or false)
end

function GearFlags:Sweep()
    for slotID = 1, 19 do
        local button = GetSlotFrame(slotID)
        if button then
            if Cfg().enabled then
                UpdateSlot(slotID)
            else
                HideAllBorders(visualsByButton[button])
            end
        end
    end
end





local function AttachSlotTooltip(button, slotID)
    
    
    if not button then return end

    
    
    
    
    local visuals = GetOrCreateVisuals(button)
    if visuals.tooltipHooked then return end
    visuals.tooltipHooked = true

    button:HookScript("OnEnter", function()
        if not Cfg().enabled then return end

        local link = GetInventoryItemLink("player", slotID)
        if not link then return end

        local lines = {}
        if Cfg().flagMissingEnchant and Cfg().enchantSlots[slotID] and not HasEnchant(link) then
            table.insert(lines, "Missing enchant")
        end
        if Cfg().flagEmptySocket and HasEmptySocket(link) then
            table.insert(lines, "Empty gem socket")
        end

        if #lines > 0 then
            for _, line in ipairs(lines) do
                GameTooltip:AddLine(line, 1, 0, 0)
            end
            GameTooltip:Show()
        end
    end)
end










local function HandleItemLoad(slotID)
    return function()
        UpdateSlot(slotID)
    end
end

local function QueueSlotForLoad(slotID)
    local item = Item:CreateFromEquipmentSlot(slotID)
    if not item or item:IsItemEmpty() then return end
    item:ContinueOnItemLoad(HandleItemLoad(slotID))
end





local eventFrame = nil

function GearFlags:Initialize()
    
    MigrateConfig()

    eventFrame = CreateFrame("Frame")

    
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    eventFrame:RegisterEvent("SOCKET_INFO_UPDATE")

    
    if CharacterFrame then
        CharacterFrame:HookScript("OnShow", function()
            GearFlags:Sweep()
        end)
    end

    eventFrame:SetScript("OnEvent", function(self, event, unit)
        if not Cfg().enabled then return end

        if event == "PLAYER_ENTERING_WORLD" then
            GearFlags:Sweep()
            
            for slotID = 1, 19 do
                QueueSlotForLoad(slotID)
            end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            
            UpdateSlot(unit)
            QueueSlotForLoad(unit)
            AttachSlotTooltip(GetSlotFrame(unit), unit)
        elseif event == "UNIT_INVENTORY_CHANGED" and unit == "player" then
            GearFlags:Sweep()
            for slotID = 1, 19 do
                QueueSlotForLoad(slotID)
            end
        elseif event == "SOCKET_INFO_UPDATE" then
            GearFlags:Sweep()
        end
    end)

    
    for slotID = 1, 19 do
        local button = GetSlotFrame(slotID)
        if button then
            AttachSlotTooltip(button, slotID)
        end
    end

    
    GearFlags:Sweep()
end

ThugUI:RegisterModule("GearFlags", GearFlags)
