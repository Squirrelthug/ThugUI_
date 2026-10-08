



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

    
    
    panel:FrameSection{ title = "Controller wheel" }
    panel:Checkbox{
        label = "Fishing pole slot on the wheel",
        tooltip = "The wheel's Utility page: Equip fishing pole / Equip weapons.",
        get = function() return Cfg().gearButton end,
        set = function(v) Cfg().gearButton = v and true or false end,
    }

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
    category = "general",
    order = 25,
    summary = "Fishing macro and sound settings.",
    title = "Fishing",
    build = function(host, panel) Build(panel) end,
}
