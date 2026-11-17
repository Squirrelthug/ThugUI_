






ThugUI = ThugUI or {}

local function FS()
    return ThugUI.Fullscreen
end

local function Cfg()
    return FS() and FS():Cfg() or (ThugUIDB.Fullscreen or {})
end

local function Get(key, fallback)
    return function()
        local value = Cfg()[key]
        if value == nil then
            return fallback
        end
        return value
    end
end

local function Set(key)
    return function(value)
        Cfg()[key] = value
        if FS() and FS().Layout then
            
            FS():Layout()
            FS():Describe()
        end
    end
end

ThugUI.Window:RegisterPage{
    
    
    id = "fullscreen", category = "controller", order = 55.5,
    scopeKeys = { "Fullscreen" }, title = "Full-screen inventory",
    summary = "Controller inventory window: character, bags and readable item information.",
    build = function(_, panel)
        panel:FrameSection{ title = "Full-screen inventory" }
        panel:Note("In controller mode, opening Character or your bags covers Blizzard's panels with one full-screen view. "
            .. "It shows your character and bags with large readable item text; phase 1 is read only.")
        
        
        
        
        panel:Part("Size & position")
        panel:Note("Icon size per section. 100% is the standard size. Bigger icons fit fewer per row; the extra rows scroll.")
        local function Icons(label, key, tooltip)
            panel:Slider{ label = label, tooltip = tooltip, min = 75, max = 200, step = 5, format = "%d%%",
                get = Get(key, 100), set = Set(key) }
        end
        Icons("Equipped items", "iconsDoll", "The paper doll's slots. Stops growing where the doll would leave the column.")
        Icons("Armor chest", "iconsChest")
        Icons("Inventory tabs", "iconsGrid", "The bag grid: Inventory, Quest, Usable and Armor.")
        Icons("Reagents & ammo", "iconsStrip")
        Icons("Bag slots", "iconsSlots", "The backpack and bag slots bar.")
        panel:Part("Appearance")
        panel:Slider{ label = "Info text size", min = 14, max = 28, step = 1, format = "%d", get = Get("textSize", 18), set = Set("textSize") }
        
        
        panel:Checkbox{ label = "Framed look", tooltip = "Off: the plain panels, for comparison or if a texture misbehaves.", get = Get("skin", true), set = Set("skin") }
        panel:Part("Content")
        panel:Checkbox{ label = "Character window", tooltip = "When off, Blizzard's Character and bag frames are untouched.", get = Get("character", true), set = Set("character") }
        panel:Checkbox{ label = "Close when combat starts", get = Get("combatClose", true), set = Set("combatClose") }
    end,
}
