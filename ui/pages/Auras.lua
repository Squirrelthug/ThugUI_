








ThugUI = ThugUI or {}

local function AW() return ThugUI.AuraWindow end
local function Cfg() return AW() and AW():Cfg() or (ThugUIDB.AuraWindow or {}) end
local function Apply() if AW() then AW():ApplySettings() end end

local function Set(key)
    return function(v)
        Cfg()[key] = v
        Apply()
    end
end

local function Get(key, fallback)
    return function()
        local v = Cfg()[key]
        if v == nil then return fallback end
        return v
    end
end

local function Build(panel)
    panel:FrameSection{
        title = "Buff window",
        reset = function() if AW() then AW():ResetPosition() end end,
    }

    panel:Note("In controller mode, Blizzard's buff and debuff frames are hidden and this "
        .. "window takes their place: open it from the wheel's Auras slice or L1+L2 "
        .. "view-buffs. Move across the icons with the D-pad, read the tooltip, and "
        .. "Square removes a buff (out of combat). Switch the whole feature off with "
        .. "the Buff window tile on the Modules page.")

    panel:Checkbox{
        label = "Test mode: show the window with sample icons and drag it",
        tooltip = "Shows the window with sample icons so you can place it and judge the "
            .. "layout. Drag it with the mouse. Nothing here is saved except the position; "
            .. "it turns off when this settings window closes.",
        get = function() return AW() and AW():IsTestMode() end,
        set = function(v) if AW() then AW():SetTestMode(v) end end,
    }

    panel:Part("Size & position")
    panel:Slider{
        label = "Scale",
        min = 0.5, max = 2.5, step = 0.05,
        get = Get("scale", 1), set = Set("scale"),
    }
    panel:Slider{
        label = "Icon size",
        min = 20, max = 64, step = 1, format = "%d",
        get = Get("iconSize", 36), set = Set("iconSize"),
    }
    panel:Slider{
        label = "Space between icons",
        min = 0, max = 20, step = 1, format = "%d",
        get = Get("spacing", 4), set = Set("spacing"),
    }
    panel:Slider{
        label = "Icons per row",
        min = 4, max = 20, step = 1, format = "%d",
        get = Get("perRow", 16), set = Set("perRow"),
    }

    panel:Part("Appearance")
    panel:Slider{
        label = "Background opacity",
        min = 0, max = 1, step = 0.05,
        get = Get("bgAlpha", 0.96), set = Set("bgAlpha"),
    }
    panel:Checkbox{
        label = "Show the title and section names",
        get = Get("showLabels", true), set = Set("showLabels"),
    }
    panel:Checkbox{
        label = "Show timers",
        tooltip = "The cooldown sweep over each icon.",
        get = Get("showTimers", true), set = Set("showTimers"),
    }
    panel:Checkbox{
        label = "Show stack counts",
        get = Get("showCounts", true), set = Set("showCounts"),
    }

    panel:Part("Content")
    panel:Dropdown{
        label = "On top",
        options = {
            { text = "Buffs, then debuffs", value = "buffs" },
            { text = "Debuffs, then buffs", value = "debuffs" },
        },
        get = Get("order", "buffs"), set = Set("order"),
    }
    panel:Dropdown{
        label = "Sort",
        options = {
            { text = "As the game lists them", value = "game" },
            { text = "Ending soonest first", value = "shortest" },
            { text = "Ending last first", value = "longest" },
        },
        get = Get("sort", "game"), set = Set("sort"),
    }
    panel:Checkbox{
        label = "Show auras with no duration",
        tooltip = "Off hides permanent auras (no timer), such as forms and passive buffs.",
        get = Get("showPermanent", true), set = Set("showPermanent"),
    }
end

ThugUI.Window:RegisterPage{
    id = "auras",
    category = "controller",
    order = 55,
    scopeKeys = { "AuraWindow" },
    summary = "The buff window: test mode, size, layout and which auras show.",
    title = "Buff window",
    build = function(host, panel) Build(panel) end,
}
