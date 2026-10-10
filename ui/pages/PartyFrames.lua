











local ThugUI = _G.ThugUI
local Page = {}

local function PF() return ThugUI.PartyFrames end
local function Get(k) return PF().Cfg()[k] end
local function Set(k, v) PF().Cfg()[k] = v; PF():ApplyAll() end

local ROLE_TITLES = {
    TANK = { tab = "Tanks", plural = "tanks" },
    HEALER = { tab = "Healers", plural = "healers" },
    DAMAGER = { tab = "Damage", plural = "damage dealers" },
}

local SOURCES = {
    { value = "health", text = "Health" },
    { value = "power", text = "Resource" },
    { value = "heals", text = "Heals & absorbs" },
}

local EDGE_SOURCES = {
    { value = "health", text = "Health" },
    { value = "power", text = "Resource" },
}
local COLORS = {
    { value = "auto", text = "Automatic" },
    { value = "class", text = "Class colour" },
    { value = "power", text = "Resource colour" },
    { value = "custom", text = "Custom" },
}

local function RGB(t)
    if type(t) ~= "table" then return 1, 1, 1 end
    return t.r or t[1] or 1, t.g or t[2] or 1, t.b or t[3] or 1
end



local function Editor(panel, S)
    local ui = { bars = "health", square = "bg", circle = "bg" }   
    local function Gate(fn)
        panel:ActiveIf(function() return S.active() and (not fn or fn()) end)
    end
    Gate()

    local function SourceAndColour(srcKey, colKey, rgbKey, sources, shape)
        panel:Dropdown{
            label = "Shows", options = sources,
            
            get = function()
                local v = S.get(srcKey)
                if shape == "square" and v == "heals" and srcKey ~= "bgSource" then return "power" end
                return v
            end,
            set = function(v) S.set(srcKey, v) end,
        }
        panel:Dropdown{
            label = "Colour", options = COLORS,
            tooltip = "Automatic: class colour for health, the resource's own colour, green for heals.",
            get = function() return S.get(colKey) or "auto" end,
            set = function(v) S.set(colKey, v); panel:Refresh() end,
        }
        Gate(function() return S.get(colKey) == "custom" end)
        panel:Color{
            label = "Custom colour",
            get = function() return RGB(S.get(rgbKey)) end,
            set = function(r, g, b) S.set(rgbKey, { r = r, g = g, b = b }) end,
        }
        Gate()
    end

    local function Icon(round)
        panel:Note("A picture in the middle. Nudge it with X and Y if it sits off-centre at your size.")
        panel:Dropdown{
            label = "Icon",
            options = {
                { value = "role", text = "Role" }, { value = "class", text = "Class" },
                { value = "race", text = "Race" }, { value = "faction", text = "Faction" },
                { value = "none", text = "None" },
            },
            get = function() return S.get("icon") end,
            set = function(v) S.set("icon", v) end,
        }
        panel:Slider{
            label = "Icon size", min = 0.3, max = 2, step = 0.05, format = "%.2f",
            get = function() return S.get("iconScale") end,
            set = function(v) S.set("iconScale", v) end,
        }
        panel:Slider{
            label = "Icon X", min = -30, max = 30, step = 1, format = "%d",
            get = function() return S.get("iconX") or 0 end,
            set = function(v) S.set("iconX", v) end,
        }
        panel:Slider{
            label = "Icon Y", min = -30, max = 30, step = 1, format = "%d",
            get = function() return S.get("iconY") or 0 end,
            set = function(v) S.set("iconY", v) end,
        }
        if round then
            panel:Checkbox{
                label = "Round icon",
                tooltip = "Clips square pictures (race, class) to a circle.",
                get = function() return S.get("iconRound") ~= false end,
                set = function(v) S.set("iconRound", v) end,
            }
        end
    end

    
    local function Layered(shape)
        local isCircle = shape == "circle"
        local ringWord = isCircle and "Ring" or "Line"
        panel:Note(isCircle
            and "Health fills the disc; two rings can run round it. Pick a part to set it up."
            or "Health fills the square; two lines can run round its edge, clockwise from the top left. "
                .. "Pick a part to set it up.")
        panel:Slider{
            label = "Size", min = 24, max = 160, step = 1, format = "%d",
            get = function() return S.get("size") end,
            set = function(v) S.set("size", v) end,
        }
        panel:Switch{
            options = {
                { value = "bg", text = "Background" }, { value = "ring1", text = ringWord .. " 1" },
                { value = "ring2", text = ringWord .. " 2" }, { value = "icon", text = "Icon" },
            },
            get = function() return ui[shape] end,
            set = function(v) ui[shape] = v end,
        }
        panel:Case("bg")
        panel:Note(isCircle and "The fill inside the rings." or "The fill inside the lines.")
        SourceAndColour("bgSource", "bgColor", "bgRGB", SOURCES, shape)

        panel:Case("ring1")
        panel:Note(isCircle and "The inner ring, round the background." or "The inner line, round the background.")
        panel:Checkbox{
            label = "Show " .. ringWord:lower() .. " 1",
            get = function() return S.get("showResource") ~= false end,
            set = function(v) S.set("showResource", v); panel:Refresh() end,
        }
        Gate(function() return S.get("showResource") ~= false end)
        SourceAndColour("ring1Source", "ring1Color", "ring1RGB", isCircle and SOURCES or EDGE_SOURCES, shape)
        if isCircle then
            panel:Slider{
                label = "Thickness", tooltip = "As a share of the circle.",
                min = 6, max = 24, step = 1, format = "%d%%",
                get = function() return S.get("ring") end,
                set = function(v) local _, t = PF().RingTexture(v); S.set("ring", t) end,
            }
        else
            panel:Slider{
                label = "Thickness", tooltip = "In pixels.", min = 1, max = 12, step = 1, format = "%d",
                get = function() return S.get("edge") end,
                set = function(v) S.set("edge", v) end,
            }
        end
        panel:Slider{
            label = "Gap", tooltip = "Space between it and the background.",
            min = 0, max = 8, step = 1, format = "%d",
            get = function() return S.get("gap") end,
            set = function(v) S.set("gap", v) end,
        }
        Gate()

        panel:Case("ring2")
        panel:Note(isCircle
            and "An extra ring outside ring 1. Off unless you turn it on."
            or "An extra line outside line 1. Off unless you turn it on. Lines show health or the resource; "
                .. "heals & absorbs need the circle.")
        panel:Checkbox{
            label = "Show " .. ringWord:lower() .. " 2",
            get = function() return S.get("ring2On") == true end,
            set = function(v) S.set("ring2On", v); panel:Refresh() end,
        }
        Gate(function() return S.get("ring2On") == true end)
        SourceAndColour("ring2Source", "ring2Color", "ring2RGB", isCircle and SOURCES or EDGE_SOURCES, shape)
        if isCircle then
            panel:Slider{
                label = "Thickness", tooltip = "As a share of the circle.",
                min = 6, max = 24, step = 1, format = "%d%%",
                get = function() return S.get("ring2Ring") end,
                set = function(v) local _, t = PF().RingTexture(v); S.set("ring2Ring", t) end,
            }
        else
            panel:Slider{
                label = "Thickness", tooltip = "In pixels.", min = 1, max = 12, step = 1, format = "%d",
                get = function() return S.get("ring2Edge") end,
                set = function(v) S.set("ring2Edge", v) end,
            }
        end
        panel:Slider{
            label = "Gap", tooltip = "Space between it and " .. ringWord:lower() .. " 1.",
            min = 0, max = 8, step = 1, format = "%d",
            get = function() return S.get("ring2Gap") end,
            set = function(v) S.set("ring2Gap", v) end,
        }
        Gate()

        panel:Case("icon")
        Icon(isCircle)
        panel:EndSwitch()
    end

    panel:Switch{
        options = {
            { value = "bars", text = "Bars" }, { value = "square", text = "Square" }, { value = "circle", text = "Circle" },
        },
        get = function() return S.get("shape") end,
        set = function(v) S.set("shape", v) end,
    }

    panel:Case("bars")
    panel:Note("A health bar with the resource under it. Pick a part to set it up.")
    panel:Switch{
        options = {
            { value = "health", text = "Health bar" }, { value = "power", text = "Resource bar" },
            { value = "icon", text = "Icon" },
        },
        get = function() return ui.bars end,
        set = function(v) ui.bars = v end,
    }
    panel:Case("health")
    panel:Slider{
        label = "Width", min = 60, max = 400, step = 1, format = "%d",
        get = function() return S.get("width") end,
        set = function(v) S.set("width", v) end,
    }
    panel:Checkbox{
        label = "Health bar",
        get = function() return S.get("showHealth") ~= false end,
        set = function(v) S.set("showHealth", v); panel:Refresh() end,
    }
    Gate(function() return S.get("showHealth") ~= false end)
    panel:Slider{
        label = "Health height", min = 4, max = 80, step = 1, format = "%d",
        get = function() return S.get("healthHeight") end,
        set = function(v) S.set("healthHeight", v) end,
    }
    panel:Checkbox{
        label = "Class colour",
        tooltip = "Off: green for everyone. Also what Automatic means for health on a square or circle.",
        get = function() return S.get("classColor") ~= false end,
        set = function(v) S.set("classColor", v) end,
    }
    Gate()
    panel:Case("power")
    panel:Checkbox{
        label = "Resource bar",
        get = function() return S.get("showPower") ~= false end,
        set = function(v) S.set("showPower", v); panel:Refresh() end,
    }
    Gate(function() return S.get("showPower") ~= false end)
    panel:Slider{
        label = "Resource height", min = 2, max = 40, step = 1, format = "%d",
        get = function() return S.get("powerHeight") end,
        set = function(v) S.set("powerHeight", v) end,
    }
    Gate()
    panel:Case("icon")
    Icon(false)
    panel:EndSwitch()

    panel:Case("square")
    Layered("square")
    panel:Case("circle")
    Layered("circle")
    panel:EndSwitch()
    panel:ActiveIf(nil)
end
Page.Editor = Editor

local function Always() return true end

function Page:Build(host, panel)
    if not PF() then return end
    panel:Header("Party frames")
    if ThugUI.UnitFrames and ThugUI.UnitFrames:IsMouseLayer() then
        panel:Note("Mouse play: changes here are stored as differences from your controller setup.")
        panel:Button{ label = "Reset to controller", onClick = function() ThugUI.UnitFrames:Reset("PartyFrames") end }
    end
    panel:Note("These replace Blizzard's party frames while you are in a party (not a raid). Turning the tile "
        .. "off needs a /reload to bring Blizzard's back.")

    
    panel:Section("Frames")
    panel:Note("Where the frames sit and how they line up. Unlock to drag them; out of a party, samples "
        .. "show (a tank, a healer, then damage). Click a frame to target, right-click for options.")
    panel:Checkbox{
        label = "Unlocked (drag to move)",
        get = function() return Get("unlocked") == true end,
        set = function(v) PF():SetUnlocked(v) end,
    }
    panel:Checkbox{
        label = "Show yourself first",
        get = function() return Get("showSelf") == true end,
        set = function(v) Set("showSelf", v) end,
    }
    panel:ActiveIf(function() return Get("shape") == "bars" end)
    panel:Dropdown{
        label = "Direction",
        tooltip = "Bars only. Squares and circles use the grid below.",
        options = { { value = "down", text = "Downwards" }, { value = "right", text = "To the right" } },
        get = function() return Get("growth") end,
        set = function(v) Set("growth", v) end,
    }
    panel:ActiveIf(nil)
    panel:Slider{
        label = "Scale", min = 0.5, max = 3, step = 0.05, format = "%.2f",
        get = function() return Get("scale") end,
        set = function(v) Set("scale", v) end,
    }
    panel:Slider{
        label = "Spacing", min = 0, max = 60, step = 1, format = "%d",
        get = function() return Get("spacing") end,
        set = function(v) Set("spacing", v) end,
    }
    panel:Button{ label = "Reset position", onClick = function() PF():ResetPosition() end }

    
    panel:Group("Grid (square and circle)")
    panel:Note("Lay squares or circles out like an action bar: in rows or columns, so many to each.")
    panel:ActiveIf(function() return Get("shape") ~= "bars" end)
    panel:Dropdown{
        label = "Layout",
        options = {
            { value = "rows", text = "Rows (fill left to right)" },
            { value = "columns", text = "Columns (fill top to bottom)" },
        },
        get = function() return (PF().GridOf(PF().Cfg())) end,
        set = function(v) Set("gridFill", v) end,
    }
    panel:Slider{
        label = "Frames per row / column", min = 1, max = 5, step = 1, format = "%d",
        get = function() local _, per = PF().GridOf(PF().Cfg()) return per end,
        set = function(v) Set("perLine", v) end,
    }
    panel:ActiveIf(nil)
    panel:Group("Your target")
    panel:Note("Marks the member you have targeted: a trim round a square, a ring round a circle. Bars brighten instead.")
    panel:Color{
        label = "Colour",
        get = function()
            local t = Get("selColor")
            if type(t) ~= "table" then return 1, 0.82, 0 end
            return t.r or 1, t.g or 0.82, t.b or 0
        end,
        set = function(r, g, b) Set("selColor", { r = r, g = g, b = b }) end,
    }
    panel:Slider{
        label = "Thickness", min = 1, max = 8, step = 1, format = "%d",
        tooltip = "In pixels. The circle's ring comes in steps, so on a big circle it cannot go below the thinnest one.",
        get = function() return Get("selThickness") end,
        set = function(v) Set("selThickness", v) end,
    }

    
    panel:Section("Shape")
    panel:Note("How every party member is drawn. Pick a shape, then a part of it.")
    Editor(panel, { get = Get, set = Set, active = Always })

    
    panel:FrameSection{ title = "Roles" }
    panel:Note("Exceptions: draw one role differently. Turn a role on and its members use the shape set "
        .. "on its tab; everyone else keeps the Shape tab. Text, range fade and position stay shared.")
    for _, role in ipairs(PF().ROLES) do
        local t = ROLE_TITLES[role]
        panel:SubSection(t.tab)
        local function On() return PF():RoleCfg(role).on == true end
        panel:Checkbox{
            label = "Give " .. t.plural .. " their own look",
            tooltip = "Starts as a copy of the Shape tab. Off: " .. t.plural .. " look like everyone else.",
            get = On,
            set = function(v) PF():SetRoleOn(role, v); panel:Refresh() end,
        }
        Editor(panel, {
            get = function(k)
                local v = PF():RoleCfg(role)[k]
                if v == nil then return Get(k) end
                return v
            end,
            set = function(k, v) PF():RoleCfg(role)[k] = v; PF():ApplyAll() end,
            active = On,
        })
    end

    
    panel:Section("Text & colour")
    panel:Note("Names, health text, darkening and range fade, shared by every role.")
    panel:Checkbox{
        label = "Name",
        get = function() return Get("showName") ~= false end,
        set = function(v) Set("showName", v) end,
    }
    panel:Dropdown{
        label = "Health text",
        options = { { value = "percent", text = "Percent" }, { value = "none", text = "Off" } },
        get = function() return Get("healthText") end,
        set = function(v) Set("healthText", v) end,
    }
    panel:Slider{
        label = "Text size", min = 0.5, max = 2.5, step = 0.05, format = "%.2f",
        get = function() return Get("textScale") end,
        set = function(v) Set("textScale", v) end,
    }
    panel:Group("Darken")
    panel:Checkbox{
        label = "Darken the frames",
        tooltip = "A dark layer over the health; text and icons stay bright above it.",
        get = function() return Get("dim") == true end,
        set = function(v) Set("dim", v); panel:Refresh() end,
    }
    panel:ActiveIf(function() return Get("dim") == true end)
    panel:Slider{
        label = "Darkness", min = 0, max = 0.9, step = 0.05, format = "%.2f",
        get = function() return Get("dimAmount") end,
        set = function(v) Set("dimAmount", v) end,
    }
    panel:ActiveIf(nil)
    panel:Group("Out of range")
    panel:Checkbox{
        label = "Fade players out of range",
        get = function() return Get("rangeFade") ~= false end,
        set = function(v) Set("rangeFade", v); panel:Refresh() end,
    }
    panel:ActiveIf(function() return Get("rangeFade") ~= false end)
    panel:Slider{
        label = "Opacity out of range", min = 0.1, max = 1, step = 0.05, format = "%.2f",
        get = function() return Get("rangeAlpha") end,
        set = function(v) Set("rangeAlpha", v) end,
    }
    panel:ActiveIf(nil)

    
    if ThugUI.Visibility then
        panel:FrameSection{ title = "Visibility" }
        panel:Note("When the party frames show, as for the orbs and the minimap: by combat and resting "
            .. "(with the party's own rule), for targets, while moving, and on gamepad input.")
        
        
        ThugUI.Visibility:AddControls(panel, "party", { split = true, moving = true, padReveal = true,
            afterWhen = function(p)
                p:Group("Party rules (these win over everything on these tabs)")
                p:Checkbox{
                    label = "Always show in combat",
                    tooltip = "In combat the party frames are fully shown, whatever Show, resting, "
                        .. "moving or gamepad input would hide.",
                    get = function() return Get("showInCombat") == true end,
                    set = function(v)
                        Set("showInCombat", v and true or false)
                        PF():ApplyVisibility()
                    end,
                }
            end })
    end
end

ThugUI.PartyFramesPage = Page

ThugUI.Window:RegisterPage{
    id = "partyframes",
    category = "ui",
    order = 45,
    scopeKeys = { "PartyFrames" },
    summary = "Our own party frames: bars, squares or circles, with a look per role.",
    title = "Party frames",
    build = function(host, panel) Page:Build(host, panel) end,
}
