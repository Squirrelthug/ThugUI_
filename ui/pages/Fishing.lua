



local ThugUI = ThugUI or {}

local function Cfg()
    return ThugUIDB.Fishing or {}
end

local function Build(panel)
    panel:FrameSection{
        title = "Smart cast",
        enabled = {
            get = function() return Cfg().smartCast end,
            set = function(v) Cfg().smartCast = v and true or false; ThugUI.Fishing:Update() end,
        },
    }

    panel:Checkbox{
        label = "Apply lures first",
        tooltip = "When your pole has no lure and one is in your bags, the macro applies the best one "
            .. "(highest fishing bonus first). The next press fishes.",
        get = function() return Cfg().applyLures end,
        set = function(v) Cfg().applyLures = v and true or false; ThugUI.Fishing:Update() end,
    }

    panel:Button{
        label = "Create the ThugFish macro",
        width = 200,
        onClick = function() ThugUI.Fishing:CreateMacro() end,
    }

    panel:Gap(10)
    panel:Note("Put the macro on a bar slot or key. The first press puts on a lure if one is missing, and the next press fishes.", { indent = 12 })

    
    panel:FrameSection{ title = "Double press" }
    panel:Note("Double-click in the world, or double-press a key, to cast Fishing. It uses the same "
        .. "lure-first logic as the ThugFish macro. Out of combat only.")
    panel:Checkbox{
        label = "Double-click to cast",
        get = function() return Cfg().doubleClick end,
        set = function(v) Cfg().doubleClick = v and true or false end,
    }
    panel:Dropdown{
        label = "Mouse button",
        options = {
            { text = "Right button", value = "RightButton" },
            { text = "Left button", value = "LeftButton" },
        },
        get = function() return Cfg().doubleClickButton or "RightButton" end,
        set = function(v) Cfg().doubleClickButton = v end,
    }
    panel:KeyBind{
        label = "Double-press key",
        tooltip = "While a key is set here it only fishes: its normal action is off.",
        get = function() return Cfg().doubleKey end,
        set = function(v) ThugUI.Fishing:SetDoubleKey(v) end,
    }
    panel:Slider{
        label = "Double-press window",
        tooltip = "How quickly the second press must follow the first.",
        min = 0.15, max = 1.0, step = 0.05, format = "%.2f s",
        get = function() return tonumber(Cfg().doubleWindow) or 0.4 end,
        set = function(v) Cfg().doubleWindow = v end,
    }
    panel:Checkbox{
        label = "Only with a fishing pole equipped",
        get = function() return Cfg().doubleNeedsPole ~= false end,
        set = function(v) Cfg().doubleNeedsPole = v and true or false end,
    }
    panel:Note("A key set here loses its normal action while it is set. Right-click the key box to clear it.")

    
    
    panel:FrameSection{ title = "Gamepad" }
    panel:Checkbox{
        label = "Gamepad Radial Menu Button",
        tooltip = "The wheel's Utility page: Equip fishing pole / Equip weapons.",
        get = function() return Cfg().gearButton end,
        set = function(v) Cfg().gearButton = v and true or false end,
    }
    
    
    panel:Note("Adds a button to the Utility page of the radial menu you open with a gamepad. "
        .. "It swaps your weapons for your fishing pole, and back again. Gamepad play only.",
        { indent = 12 })

    panel:FrameSection{
        title = "Sound",
        enabled = {
            get = function() return Cfg().enhanceSounds end,
            set = function(v) Cfg().enhanceSounds = v and true or false end,
        },
    }
    panel:Note("Louder fishing sounds: while you fish, everything but sound effects goes quiet and effects "
        .. "play at the level below. Your sound settings come back when the cast ends.")
    panel:Slider{
        label = "Sound effect level",
        min = 0.1,
        max = 1,
        step = 0.1,
        get = function() return Cfg().soundScale end,
        set = function(v) Cfg().soundScale = v end,
    }
end

ThugUI.Window:RegisterPage{
    id = "fishing",
    
    scopeKeys = { "Fishing" },
    category = "general",
    order = 25,
    summary = "Fishing macro and sound settings.",
    title = "Fishing",
    build = function(host, panel) Build(panel) end,
}
