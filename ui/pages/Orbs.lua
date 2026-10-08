






local ThugUI = _G.ThugUI

local Page = {}
local selected = "health"

local function Cfg(key)
    if not ThugUIDB or not ThugUIDB.Orbs then return {} end
    return ThugUIDB.Orbs[key] or {}
end

local function Call(key)
    local orbs = ThugUI.Orbs
    if orbs and orbs.ApplySettings then orbs:ApplySettings(key) end
end




local function OrbSection(panel, key, label)
    panel:FrameSection{
        title = label,
        tooltip = "Unlock to drag the whole unit (orb and decoration); lock to let clicks "
            .. "pass through to the world. Reset puts it back in its corner.",
        enabled = {
            get = function() return Cfg(key).enabled end,
            set = function(v) Cfg(key).enabled = v; Call(key) end,
        },
        unlock = {
            get = function() return Cfg(key).locked == false end,
            set = function(v)
                if ThugUI.Orbs and ThugUI.Orbs.SetLocked then ThugUI.Orbs:SetLocked(key, not v) end
            end,
        },
        reset = function()
            if ThugUI.Orbs and ThugUI.Orbs.ResetPosition then ThugUI.Orbs:ResetPosition(key) end
        end,
    }

    panel:Part("Size & position")
    panel:Slider{
        label = "Scale", min = 0.3, max = 1.5, step = 0.05, format = "%.2f",
        tooltip = "Sizes the orb and its decoration together.",
        get = function() return Cfg(key).scale or 0.55 end,
        set = function(v) Cfg(key).scale = v; Call(key) end,
    }

    panel:Part("Visibility")
    if ThugUI.Visibility then
        ThugUI.Visibility:AddControls(panel, key == "health" and "orbHealth" or "orbResource")
    end
    panel:Group("Orb rules (these win over everything above)")
    panel:Checkbox{
        label = key == "health" and "Only show when not full" or "Only show when not at rest (full, or empty for rage)",
        tooltip = "Ticked, this outranks the settings above: whenever the orb is not full it "
            .. "is fully shown, whatever Show, resting or the opacities say. When full it hides, "
            .. "unless a target or soft target shows it at that opacity.",
        get = function() return Cfg(key).hideWhenFull end,
        set = function(v) Cfg(key).hideWhenFull = v; Call(key) end,
    }
    panel:Checkbox{
        label = "Always show in combat",
        tooltip = "In combat the orb, its decoration and its art are fully shown, whatever "
            .. "the visibility settings above or \"only when not full\" would hide.",
        get = function() return Cfg(key).showInCombat end,
        set = function(v) Cfg(key).showInCombat = v and true or false; Call(key) end,
    }

    panel:Part("Appearance")
    panel:Group("Fill")
    panel:Dropdown{
        label = "Direction", width = 150,
        options = {
            { value = "up", text = "Up" },
            { value = "down", text = "Down" },
            { value = "left", text = "Left" },
            { value = "right", text = "Right" },
            { value = "center", text = "Center" },
        },
        get = function() return Cfg(key).direction or "up" end,
        set = function(v) Cfg(key).direction = v; Call(key) end,
    }
    local colorOptions
    if key == "health" then
        colorOptions = {
            { value = "green", text = "Green" },
            { value = "class", text = "Class colour" },
            { value = "custom", text = "Custom colour" },
        }
    else
        colorOptions = {
            { value = "power", text = "Match the resource" },
            { value = "class", text = "Class colour" },
            { value = "custom", text = "Custom colour" },
        }
    end
    panel:Dropdown{
        label = "Colour mode", width = 150,
        options = colorOptions,
        get = function() return Cfg(key).colorMode or (key == "health" and "green" or "power") end,
        set = function(v) Cfg(key).colorMode = v; Call(key) end,
    }
    panel:Color{
        get = function()
            local c = Cfg(key).customColor
            if not c then return 1, 1, 1 end
            return unpack(c)
        end,
        set = function(r, g, b)
            Cfg(key).customColor = { r, g, b }
            Call(key)
        end,
        sameLine = true,
    }
    panel:Slider{
        label = "Backing opacity", min = 0, max = 1.0, step = 0.05, format = "%.2f",
        get = function() return Cfg(key).bgAlpha or 0.6 end,
        set = function(v) Cfg(key).bgAlpha = v; Call(key) end,
    }

    panel:Group("Glass")
    panel:Checkbox{
        label = "Glass",
        get = function() return Cfg(key).glass end,
        set = function(v) Cfg(key).glass = v; Call(key) end,
    }

    
    panel:Group("Decoration")
    panel:Dropdown{
        label = "Decoration", width = 170,
        options = {
            { value = "faction", text = "Match my faction" },
            { value = "gryphon", text = "Gryphon" },
            { value = "wyvern",  text = "Wyvern" },
            { value = "none",    text = "None" },
        },
        get = function() return Cfg(key).decor or "faction" end,
        set = function(v) Cfg(key).decor = v; Call(key) end,
    }
    panel:Color{
        get = function()
            local c = Cfg(key).decorColor
            if not c then return 1, 1, 1 end
            return unpack(c)
        end,
        set = function(r, g, b)
            Cfg(key).decorColor = { r, g, b }
            Call(key)
        end,
        sameLine = true,
    }
    panel:Slider{
        label = "Decoration scale", min = 0.2, max = 3.0, step = 0.05, format = "%.2f",
        tooltip = "Sizes the decoration on its own; the orb's Scale sizes both.",
        get = function() return Cfg(key).decorScale or 1 end,
        set = function(v) Cfg(key).decorScale = v; Call(key) end,
    }
    panel:Slider{
        label = "Decoration X", min = -400, max = 400, step = 1, format = "%d",
        get = function() return Cfg(key).decorX or 0 end,
        set = function(v) Cfg(key).decorX = v; Call(key) end,
    }
    panel:Slider{
        label = "Decoration Y", min = -400, max = 400, step = 1, format = "%d",
        get = function() return Cfg(key).decorY or 0 end,
        set = function(v) Cfg(key).decorY = v; Call(key) end,
    }
    panel:Checkbox{
        label = "Decoration in front of the orb",
        get = function() return Cfg(key).decorFront end,
        set = function(v) Cfg(key).decorFront = v and true or false; Call(key) end,
    }

    panel:Group("Your own art")
    panel:EditBox{
        label = "Art path",
        get = function() return Cfg(key).artPath or "" end,
        set = function(v) Cfg(key).artPath = v; Call(key) end,
    }
    panel:Slider{
        label = "Art size", min = 30, max = 300, step = 1, format = "%d",
        get = function() return Cfg(key).artSize or 160 end,
        set = function(v) Cfg(key).artSize = v; Call(key) end,
    }
    panel:Slider{
        label = "Art X", min = -150, max = 150, step = 1, format = "%d",
        get = function() return Cfg(key).artX or 0 end,
        set = function(v) Cfg(key).artX = v; Call(key) end,
    }
    panel:Slider{
        label = "Art Y", min = -150, max = 150, step = 1, format = "%d",
        get = function() return Cfg(key).artY or 0 end,
        set = function(v) Cfg(key).artY = v; Call(key) end,
    }
end

function Page:Build(host, panel)
    panel:Header("Health & resource orbs")
    if ThugUI.UnitFrames and ThugUI.UnitFrames:IsMouseLayer() then
        panel:Note("Mouse play: changes here are stored as differences from your controller setup.")
        panel:Button{
            label = "Reset to controller",
            onClick = function()
                ThugUI.UnitFrames:Reset("Orbs")
                ThugUI.UnitFrames:Reset("ResourcePips")
                ThugUI.UnitFrames:Reset("Visibility")
            end,
        }
    end
    panel:Note("Each orb and its decoration are one unit you unlock, drag and "
        .. "scale. The health unit hangs off the bottom-left corner of the screen, the "
        .. "resource unit off the bottom-right. The fill direction can be up, down, left, "
        .. "right or from the centre, not an arbitrary angle: Blizzard's bars cannot rotate "
        .. "their fill. Your own art goes in the art path and draws over the orb.")

    panel:Checkbox{
        label = "Test mode: show and unlock the orbs and pips",
        tooltip = "While ticked, both orbs, the resource pips and the pip ring are fully shown and can "
            .. "be dragged, ignoring their visibility settings. Nothing is saved; it turns off when "
            .. "this window closes.",
        get = function() return ThugUI.Orbs and ThugUI.Orbs:IsTestMode() end,
        set = function(v) if ThugUI.Orbs then ThugUI.Orbs:SetTestMode(v) end end,
    }

    OrbSection(panel, "health", "Health Orb")
    OrbSection(panel, "resource", "Resource Orb")

    Page:BuildPips(panel)
    Page:BuildRingArt(panel)
end



local function Pips() return ThugUIDB.ResourcePips end
local function PipsRefresh() if ThugUI.ResourcePips then ThugUI.ResourcePips:Refresh() end end
local function PipsSetting(key)
    return function() return Pips()[key] end, function(v) Pips()[key] = v; PipsRefresh() end
end

function Page:BuildPips(panel)
    ThugUIDB.ResourcePips = ThugUIDB.ResourcePips or {}
    local RP = function() return ThugUI.ResourcePips end
    panel:FrameSection{
        title = "Resource pips",
        tooltip = "Drag the pips while this is ticked, then untick.",
        enabled = { get = function() return Pips().enabled end,
                    set = function(v) Pips().enabled = v and true or false; PipsRefresh() end },
        unlock = { get = function() return RP() and RP().unlocked end,
                   set = function(v) if RP() then RP():SetUnlocked(v) end end },
        reset = function() if RP() then RP():ResetPosition() end end,
    }
    panel:Note("Your class's secondary resource (combo points, Holy Power, Chi, "
        .. "Soul Shards, Arcane Charges, Essence) as pips you can place anywhere. "
        .. "The cursor ring's own pips are set on Cursor Rings.")

    local g, s
    panel:Part("Size & position")
    g, s = PipsSetting("scale")
    panel:Slider{ label = "Scale", min = 0.5, max = 3, step = 0.05, get = g, set = s }
    g, s = PipsSetting("size")
    panel:Slider{ label = "Pip size", min = 4, max = 40, step = 1, format = "%d", get = g, set = s }
    g, s = PipsSetting("layout")
    panel:Dropdown{ label = "Layout", get = g, set = s, options = {
        { text = "Ring", value = "ring" }, { text = "Bar", value = "bar" } } }
    g, s = PipsSetting("radius")
    panel:Slider{ label = "Ring: radius", min = 8, max = 200, step = 1, format = "%d", get = g, set = s }
    g, s = PipsSetting("spread")
    panel:Slider{ label = "Ring: share of the circle", min = 0.25, max = 1, step = 0.05,
        tooltip = "0.25 packs the pips into a quarter of the ring, side by side; "
            .. "1 spreads them round the whole circle.", get = g, set = s }
    g, s = PipsSetting("start")
    panel:Slider{ label = "Ring: centred at (o'clock)", min = 1, max = 12, step = 1, format = "%d", get = g, set = s }
    g, s = PipsSetting("gap")
    panel:Slider{ label = "Bar: space between pips", min = 0, max = 40, step = 1, format = "%d",
        tooltip = "0 puts the pips side by side.", get = g, set = s }
    g, s = PipsSetting("orientation")
    panel:Dropdown{ label = "Bar: direction", get = g, set = s, options = {
        { text = "Horizontal", value = "horizontal" }, { text = "Vertical", value = "vertical" } } }

    panel:Part("Visibility")
    g, s = PipsSetting("show")
    panel:Dropdown{ label = "Show", get = g, set = s, options = {
        { text = "In controller mode", value = "controller" }, { text = "Always", value = "always" } } }
    if ThugUI.Visibility then ThugUI.Visibility:AddControls(panel, "resourcePips") end

    panel:Part("Appearance")
    g, s = PipsSetting("colorMode")
    panel:Dropdown{ label = "Colour", get = g, set = s, options = {
        { text = "Resource colour", value = "power" }, { text = "Class colour", value = "class" },
        { text = "Custom", value = "custom" } } }
    panel:Color{
        label = "Custom colour",
        get = function()
            local c = Pips().customColor or { 1, 0.85, 0.3 }
            return c[1], c[2], c[3]
        end,
        set = function(r, gg, b) Pips().customColor = { r, gg, b }; PipsRefresh() end,
    }
    g, s = PipsSetting("dimAlpha")
    panel:Slider{ label = "Unlit pip opacity", min = 0, max = 1, step = 0.05, get = g, set = s }
end

function Page:BuildRingArt(panel)
    panel:FrameSection{
        title = "Ring art",
        tooltip = "One ring per orb (it starts as the orb's rim) and one around each pip. Pick the ring to edit.",
        reset = function()
            if selected == "pips" then
                ThugUIDB.ResourcePips = ThugUIDB.ResourcePips or {}
                local p = ThugUIDB.ResourcePips
                p.ring = false
                p.ringArt = "orb"
                p.ringBlend = "auto"
                p.ringAlpha = 1
                p.ringScale = 1.6
                p.ringX = 0
                p.ringY = 0
                p.ringColor = { 1, 1, 1 }
                p.ringSpin = 0
                p.ringUnlitAlpha = 0
                p.ringDesat = false
                if ThugUI.ResourcePips then ThugUI.ResourcePips:UpdateRing() end
            else
                local o = Cfg(selected)
                local def = ThugUI.defaults.Orbs and ThugUI.defaults.Orbs[selected] or {}
                o.ring = def.ring ~= false
                o.ringArt = def.ringArt or "orb"
                o.ringBlend = def.ringBlend or "auto"
                o.ringAlpha = def.ringAlpha or 1
                o.ringScale = def.ringScale or 1.0
                o.ringX = def.ringX or 0
                o.ringY = def.ringY or 0
                o.ringColor = def.ringColor and { unpack(def.ringColor) } or { 1, 1, 1 }
                o.ringSpin = def.ringSpin or 0
                o.ringDesat = def.ringDesat == true
                if ThugUI.Orbs then ThugUI.Orbs:ApplySettings(selected) end
            end
            panel:Refresh()
        end,
    }

    panel:Note("One ring per orb (it starts as the orb's rim) and one around each pip. Pick the ring to edit.")

    panel:Dropdown{
        label = "Ring",
        options = {
            { text = "Health orb", value = "health" },
            { text = "Resource orb", value = "resource" },
            { text = "Pips", value = "pips" },
        },
        get = function() return selected end,
        set = function(v)
            selected = v
            panel:Refresh()
        end,
    }

    local function Get(k)
        if selected == "pips" then
            ThugUIDB.ResourcePips = ThugUIDB.ResourcePips or {}
            return ThugUIDB.ResourcePips[k]
        end
        return Cfg(selected)[k]
    end

    local function Set(k, v)
        if selected == "pips" then
            ThugUIDB.ResourcePips = ThugUIDB.ResourcePips or {}
            ThugUIDB.ResourcePips[k] = v
            if ThugUI.ResourcePips then ThugUI.ResourcePips:UpdateRing() end
        else
            Cfg(selected)[k] = v
            Call(selected)
        end
    end

    panel:Checkbox{
        label = "Show ring",
        get = function()
            local v = Get("ring")
            if selected == "pips" then
                return v == true
            else
                return v ~= false
            end
        end,
        set = function(v) Set("ring", v and true or false) end,
    }

    panel:Part("Size & position")
    panel:Slider{
        label = "Ring size (x the orb or pip)", min = 0.5, max = 4.0, step = 0.05, format = "%.2f",
        get = function()
            local v = Get("ringScale")
            return tonumber(v) or (selected == "pips" and 1.6 or 1.0)
        end,
        set = function(v) Set("ringScale", v) end,
    }
    panel:Slider{
        label = "Ring X", min = -100, max = 100, step = 1, format = "%d",
        get = function() return tonumber(Get("ringX")) or 0 end,
        set = function(v) Set("ringX", v) end,
    }
    panel:Slider{
        label = "Ring Y", min = -100, max = 100, step = 1, format = "%d",
        get = function() return tonumber(Get("ringY")) or 0 end,
        set = function(v) Set("ringY", v) end,
    }

    panel:Part("Visibility")
    panel:Slider{
        label = "Pips: unlit ring opacity", min = 0, max = 1.0, step = 0.05, format = "%.2f",
        tooltip = "Applies to pips only.",
        get = function()
            if selected ~= "pips" then return 0 end
            return tonumber(Get("ringUnlitAlpha")) or 0
        end,
        set = function(v)
            if selected == "pips" then Set("ringUnlitAlpha", v) end
        end,
    }
    panel:Note("Pips only: when the pip rings show at all. The orb rings follow their orb.")
    if ThugUI.Visibility then
        ThugUI.Visibility:AddControls(panel, "resourcePipsRing")
    end

    panel:Part("Appearance")
    panel:Dropdown{
        label = "Ring art",
        options = ThugUI.RingArt:Options(),
        get = function() return Get("ringArt") or "orb" end,
        set = function(v) Set("ringArt", v) end,
    }
    panel:Dropdown{
        label = "Blend",
        tooltip = "Auto picks additive for Blizzard's glow, rune and sky art, which is white or coloured on black. Multiply darkens what is under it; Alpha key draws hard edges.",
        options = ThugUI.RingArt.BLEND_OPTIONS,
        get = function() return Get("ringBlend") or "auto" end,
        set = function(v) Set("ringBlend", v) end,
    }
    panel:Checkbox{
        label = "Desaturate (let the tint recolour it)",
        get = function() return Get("ringDesat") == true end,
        set = function(v) Set("ringDesat", v and true or false) end,
    }
    panel:Color{
        label = "Ring tint",
        get = function()
            local c = Get("ringColor")
            if type(c) ~= "table" then return 1, 1, 1 end
            return c[1] or 1, c[2] or 1, c[3] or 1
        end,
        set = function(r, g, b) Set("ringColor", { r, g, b }) end,
    }
    panel:Slider{
        label = "Ring opacity", min = 0, max = 1.0, step = 0.05, format = "%.2f",
        get = function() return tonumber(Get("ringAlpha")) or 1 end,
        set = function(v) Set("ringAlpha", v) end,
    }
    panel:Slider{
        label = "Ring spin (seconds per turn, 0 = still, negative = the other way)",
        min = -30, max = 30, step = 1, format = "%d",
        get = function() return tonumber(Get("ringSpin")) or 0 end,
        set = function(v) Set("ringSpin", v) end,
    }
end

ThugUI.Window:RegisterPage{
    id = "orbs",
    category = "ui",
    order = 30,
    scopeKeys = { "Orbs" },
    summary = "Health and resource orbs.",
    title = "Orbs",
    build = function(host, panel) Page:Build(host, panel) end,
}

return Page
