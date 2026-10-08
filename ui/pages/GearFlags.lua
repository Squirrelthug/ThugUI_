



ThugUI = ThugUI or {}

local Page = {}

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.GearFlags = ThugUIDB.GearFlags or {}
    
    if not ThugUIDB.GearFlags.enchantSlots then
        
        
        
        
        ThugUIDB.GearFlags.enchantSlots = {
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
    end
    return ThugUIDB.GearFlags
end


local SLOT_NAMES = {
    [INVSLOT_HEAD] = "Head",
    [INVSLOT_NECK] = "Neck",
    [INVSLOT_SHOULDER] = "Shoulder",
    [INVSLOT_CHEST] = "Chest",
    [INVSLOT_WAIST] = "Waist",
    [INVSLOT_LEGS] = "Legs",
    [INVSLOT_FEET] = "Feet",
    [INVSLOT_WRIST] = "Wrist",
    [INVSLOT_HAND] = "Hand",
    [INVSLOT_FINGER1] = "Finger 1",
    [INVSLOT_FINGER2] = "Finger 2",
    [INVSLOT_BACK] = "Back",
    [INVSLOT_MAINHAND] = "Main Hand",
    [INVSLOT_OFFHAND] = "Off Hand",
    [INVSLOT_RANGED] = "Ranged",
}

function Page:Refresh()
    local GF = ThugUI.GearFlags
    if not GF then return end

    
    if GF.Sweep then
        GF:Sweep()
    end
end

function Page:Build(host, panel)
    local GF = ThugUI.GearFlags
    if not GF then return end

    panel:Header("Gear Flags")
    panel:Note("Draw a red border on equipped slots that are missing an enchant or "
        .. "have an empty gem socket, and a gold border on this season's class set pieces.")

    
    
    
    panel:Section("Flags")

    panel:Checkbox{
        label = "Enable gear flags",
        tooltip = "Turn gear flag detection on or off.",
        get = function() return Cfg().enabled end,
        set = function(v)
            Cfg().enabled = v
            Page:Refresh()
        end,
    }

    panel:Checkbox{
        label = "Flag missing enchants",
        tooltip = "Flag equipped slots in the enchant list that have no enchant applied.",
        get = function() return Cfg().flagMissingEnchant end,
        set = function(v)
            Cfg().flagMissingEnchant = v
            Page:Refresh()
        end,
    }

    panel:Checkbox{
        label = "Flag empty gem sockets",
        tooltip = "Flag equipped slots with empty gem sockets.",
        get = function() return Cfg().flagEmptySocket end,
        set = function(v)
            Cfg().flagEmptySocket = v
            Page:Refresh()
        end,
    }

    panel:Checkbox{
        label = "Red border on flagged slots",
        tooltip = "Draw a pulsing red border on a slot that is missing an enchant "
            .. "or has an empty gem socket. Hover the slot to see which.",
        get = function() return Cfg().showFlagBorder end,
        set = function(v)
            Cfg().showFlagBorder = v
            Page:Refresh()
        end,
    }

    panel:Checkbox{
        label = "Gold border on set pieces",
        tooltip = "Draw a gold border on each equipped piece of the current "
            .. "season's class set. Sits outside the red border, so a set piece "
            .. "that still needs an enchant shows both.",
        get = function() return Cfg().showSetBorder end,
        set = function(v)
            Cfg().showSetBorder = v
            Page:Refresh()
        end,
    }

    
    
    
    panel:Section("Slots that should be enchanted")

    panel:Note("This list changes between expansions and patches. Uncheck any slot "
        .. "that should not be enchanted on the current patch.")

    
    panel:Button{
        label = "Reset to defaults",
        width = 120,
        onClick = function()
            
            
            
            
            local defaultSlots = {
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
            Cfg().enchantSlots = defaultSlots
            Page:Refresh()
        end,
    }

    panel:Gap(12)

    
    local slotOrder = {
        INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BACK,
        INVSLOT_CHEST, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET,
        INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_FINGER1, INVSLOT_FINGER2,
        INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED,
    }

    for _, slotID in ipairs(slotOrder) do
        if slotID ~= INVSLOT_BODY and slotID ~= INVSLOT_TABARD then
            panel:Checkbox{
                label = SLOT_NAMES[slotID] or ("Slot " .. slotID),
                get = function() return Cfg().enchantSlots[slotID] end,
                set = function(v)
                    if v then
                        Cfg().enchantSlots[slotID] = true
                    else
                        Cfg().enchantSlots[slotID] = nil
                    end
                    Page:Refresh()
                end,
            }
        end
    end
end

ThugUI.Window:RegisterPage{
    id = "gearflags",
    category = "interface",
    scopeKeys = { "GearFlags" },
    summary = "Missing enchants and gems flagged on your character sheet.",
    title = "Gear Flags",
    order = 70,
    build = function(host, panel) Page:Build(host, panel) end,
    refresh = function(host, panel) Page:Refresh() end,
}

return Page
