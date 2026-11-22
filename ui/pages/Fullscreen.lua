






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



local function Range(name, fallback)
    return FS() and FS()[name] or fallback
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
        
        
        local function SetOn(value)
            Cfg().character = value and true or false
            local fs = FS()
            if not value and fs and fs.frame and fs.frame:IsShown() and fs.Close then
                fs:Close(false)
            end
            panel:Refresh()
        end
        panel:FrameSection{ title = "Full-screen inventory", enabled = { get = Get("character", false), set = SetOn } }
        panel:Note("In controller mode, opening Character or your bags shows ThugUI's inventory window instead of Blizzard's panels. "
            .. "It shows your character and bags with large readable item text. It is off until you turn it on.")
        local toggle
        local function ToggleLabel()
            return Cfg().character and "Turn off the inventory window" or "Turn on the inventory window"
        end
        toggle = panel:Button{ label = ToggleLabel(), width = 280, height = 32,
            tooltip = "Off: Character and your bags open Blizzard's own frames.",
            onClick = function()
                SetOn(not Cfg().character)
                toggle:SetText(ToggleLabel())
            end }
        
        local refresh = toggle.Refresh
        function toggle:Refresh()
            if refresh then refresh(self) end
            self:SetText(ToggleLabel())
        end
        panel:Register(toggle)
        
        
        
        
        panel:Part("Size & position")
        
        
        panel:Checkbox{ label = "Window mode", tooltip = "Off: the window fills the screen. On: drag it by any empty part to move it, "
            .. "and drag its bottom-right corner to resize it.", get = Get("windowed", false), set = Set("windowed") }
        panel:Slider{ label = "Window scale", tooltip = "Scales the whole window, in both modes. Lower it to fit more on a small screen.",
            min = Range("SCALE_MIN", 30), max = Range("SCALE_MAX", 200), step = 5, format = "%d%%",
            get = Get("winScale", 100), set = Set("winScale") }
        panel:Slider{ label = "Cover the rest of the screen", tooltip = "Window mode only. How dark the screen around the window is. "
            .. "Blizzard's bag frames stay open behind the window, so at 0% you see them.",
            min = 0, max = 100, step = 5, format = "%d%%", get = Get("cover", 100), set = Set("cover") }
        panel:Button{ label = "Reset window position", width = 200, tooltip = "Centres the window and sets it back to 1280 by 800.",
            onClick = function()
                local c = Cfg()
                c.winLeft, c.winTop, c.winW, c.winH = -1, -1, 1280, 800
                if FS() and FS().Layout then FS():Layout() end
            end }
        panel:Note("Icon size per section. 100% is the standard size. Bigger icons fit fewer per row; the extra rows scroll.")
        local function Icons(label, key, tooltip)
            panel:Slider{ label = label, tooltip = tooltip, min = Range("ICON_MIN", 25), max = Range("ICON_MAX", 400), step = 5,
                format = "%d%%", get = Get(key, 100), set = Set(key) }
        end
        Icons("Equipped items", "iconsDoll", "The paper doll's slots. Stops growing where the doll would leave the column.")
        Icons("Armor chest", "iconsChest")
        Icons("Inventory tabs", "iconsGrid", "The bag grid: Inventory, Quest, Usable and Armor.")
        Icons("Reagents & ammo", "iconsStrip")
        Icons("Bag slots", "iconsSlots", "The backpack and bag slots bar.")
        panel:Part("Appearance")
        panel:Slider{ label = "Info text size", min = Range("TEXT_MIN", 8), max = Range("TEXT_MAX", 48), step = 1, format = "%d", get = Get("textSize", 18), set = Set("textSize") }
        
        
        panel:Checkbox{ label = "Framed look", tooltip = "Off: the plain panels, for comparison or if a texture misbehaves.", get = Get("skin", true), set = Set("skin") }
        panel:Part("Content")
        panel:Checkbox{ label = "Close when combat starts", get = Get("combatClose", true), set = Set("combatClose") }
    end,
}
