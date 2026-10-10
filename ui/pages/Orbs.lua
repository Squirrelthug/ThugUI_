











local ThugUI = _G.ThugUI

local Page = {}

local function Cfg(key)
    if not ThugUIDB or not ThugUIDB.Orbs then return {} end
    return ThugUIDB.Orbs[key] or {}
end

local function Call(key)
    local orbs = ThugUI.Orbs
    if orbs and orbs.ApplySettings then orbs:ApplySettings(key) end
end

local function GetOrbSpec(key, prefix, vkey, defaultScale)
    return {
        get = function(f) return Cfg(key)[f] end,
        set = function(f, v)
            Cfg(key)[f] = v
            Call(key)
        end,
        fields = {
            show = prefix == "ring" and "ring" or prefix .. "Show",
            x = prefix .. "X",
            y = prefix .. "Y",
            scale = prefix .. "Scale",
            alpha = prefix .. "Alpha",
        },
        vkey = vkey,
        defaultScale = defaultScale or 1,
        defaultShow = true,
    }
end

local function GetPipsSpec(prefix, vkey, defaultScale, defaultShow)
    return {
        get = function(f) return (ThugUIDB.ResourcePips or {})[f] end,
        set = function(f, v)
            ThugUIDB.ResourcePips = ThugUIDB.ResourcePips or {}
            ThugUIDB.ResourcePips[f] = v
            if ThugUI.ResourcePips then ThugUI.ResourcePips:Refresh() end
        end,
        fields = {
            show = prefix == "ring" and "ring" or prefix .. "Show",
            x = prefix .. "X",
            y = prefix .. "Y",
            scale = prefix .. "Scale",
            alpha = prefix .. "Alpha",
        },
        vkey = vkey,
        defaultScale = defaultScale or 1,
        defaultShow = defaultShow ~= false,
    }
end



local function LayerBlock(panel, spec)
    panel:Part("Size & position")
    panel:Checkbox{
        label = "Show",
        get = function()
            local v = spec.get(spec.fields.show)
            if v == nil then return spec.defaultShow end
            return v ~= false
        end,
        set = function(v) spec.set(spec.fields.show, v) end,
    }
    panel:Slider{
        label = "X", min = -400, max = 400, step = 1, format = "%d",
        get = function() return tonumber(spec.get(spec.fields.x)) or 0 end,
        set = function(v) spec.set(spec.fields.x, v) end,
    }
    panel:Slider{
        label = "Y", min = -400, max = 400, step = 1, format = "%d",
        get = function() return tonumber(spec.get(spec.fields.y)) or 0 end,
        set = function(v) spec.set(spec.fields.y, v) end,
    }
    panel:Slider{
        label = "Size", min = 0.2, max = 3.0, step = 0.05, format = "%.2f",
        get = function() return tonumber(spec.get(spec.fields.scale)) or spec.defaultScale end,
        set = function(v) spec.set(spec.fields.scale, v) end,
    }

    panel:Part("Visibility")
    panel:Slider{
        label = "Opacity", min = 0, max = 1.0, step = 0.05, format = "%.2f",
        tooltip = "Always applied, on top of the rules below.",
        get = function() return tonumber(spec.get(spec.fields.alpha)) or 1 end,
        set = function(v) spec.set(spec.fields.alpha, v) end,
    }
    if ThugUI.Visibility then
        ThugUI.Visibility:AddControls(panel, spec.vkey)
    end
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

    panel:SubSection("Unit")
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

    panel:SubSection("Faction art")
    LayerBlock(panel, GetOrbSpec(key, "decor", key == "health" and "orbHealthDecor" or "orbResourceDecor"))
    panel:Part("Appearance")
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
    panel:Checkbox{
        label = "Decoration in front of the orb",
        get = function() return Cfg(key).decorFront end,
        set = function(v) Cfg(key).decorFront = v and true or false; Call(key) end,
    }

    panel:SubSection("Orb")
    LayerBlock(panel, GetOrbSpec(key, "orb", key == "health" and "orbHealthOrb" or "orbResourceOrb"))
    panel:Part("Appearance")
    panel:Group("Fill")
    if ThugUI.OEPage then
        ThugUI.OEPage.AddControls(panel, key == "health" and "Health" or "Resource")
    end
    panel:Dropdown{
        label = "Direction", width = 150,
        tooltip = "Up, down, left, right or from the centre, not an arbitrary angle: "
            .. "Blizzard's bars cannot rotate their fill.",
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
    local colorOptions = key == "health" and {
        { value = "green", text = "Green" },
        { value = "class", text = "Class colour" },
        { value = "custom", text = "Custom colour" },
    } or {
        { value = "power", text = "Match the resource" },
        { value = "class", text = "Class colour" },
        { value = "custom", text = "Custom colour" },
    }
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

    panel:SubSection("Ring")
    LayerBlock(panel, GetOrbSpec(key, "ring", key == "health" and "orbHealthRing" or "orbResourceRing"))
    panel:Part("Appearance")
    panel:Dropdown{
        label = "Ring art",
        options = ThugUI.RingArt:Options(),
        get = function() return Cfg(key).ringArt or "orb" end,
        set = function(v) Cfg(key).ringArt = v; Call(key) end,
    }
    panel:Dropdown{
        label = "Blend",
        tooltip = "Auto picks additive for Blizzard's glow, rune and sky art, which is white or coloured on black. Multiply darkens what is under it; Alpha key draws hard edges.",
        options = ThugUI.RingArt.BLEND_OPTIONS,
        get = function() return Cfg(key).ringBlend or "auto" end,
        set = function(v) Cfg(key).ringBlend = v; Call(key) end,
    }
    panel:Checkbox{
        label = "Desaturate (let the tint recolour it)",
        get = function() return Cfg(key).ringDesat == true end,
        set = function(v) Cfg(key).ringDesat = v and true or false; Call(key) end,
    }
    panel:Color{
        label = "Ring tint",
        get = function()
            local c = Cfg(key).ringColor
            if type(c) ~= "table" then return 1, 1, 1 end
            return unpack(c)
        end,
        set = function(r, g, b) Cfg(key).ringColor = { r, g, b }; Call(key) end,
    }
    panel:Slider{
        label = "Ring spin (seconds per turn, 0 = still, negative = the other way)",
        min = -30, max = 30, step = 1, format = "%d",
        get = function() return tonumber(Cfg(key).ringSpin) or 0 end,
        set = function(v) Cfg(key).ringSpin = v; Call(key) end,
    }

    panel:Button{
        label = "Reset ring",
        onClick = function()
            local o = Cfg(key)
            local def = ThugUI.defaults.Orbs and ThugUI.defaults.Orbs[key] or {}
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
            Call(key)
            panel:Refresh()
        end,
    }
    panel:SubSection("Own art")
    LayerBlock(panel, GetOrbSpec(key, "art", key == "health" and "orbHealthArt" or "orbResourceArt"))
    panel:Part("Appearance")
    panel:EditBox{
        label = "Art path",
        get = function() return Cfg(key).artPath or "" end,
        set = function(v) Cfg(key).artPath = v; Call(key) end,
    }
    panel:Slider{
        label = "Art size", min = 30, max = 300, step = 1, format = "%d",
        tooltip = "The art's own size in pixels. Size above scales it from there.",
        get = function() return Cfg(key).artSize or 160 end,
        set = function(v) Cfg(key).artSize = v; Call(key) end,
    }
end

local function Pips() return ThugUIDB.ResourcePips or {} end
local function PipsRefresh() if ThugUI.ResourcePips then ThugUI.ResourcePips:Refresh() end end
local function PipsSetting(key)
    return function() return Pips()[key] end,
           function(v)
               ThugUIDB.ResourcePips = ThugUIDB.ResourcePips or {}
               ThugUIDB.ResourcePips[key] = v
               PipsRefresh()
           end
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

    panel:SubSection("Unit")
    panel:Part("Size & position")
    local g, s = PipsSetting("scale")
    panel:Slider{ label = "Scale", min = 0.5, max = 3, step = 0.05, get = g, set = s }

    panel:Part("Visibility")
    g, s = PipsSetting("show")
    panel:Dropdown{ label = "Show", get = g, set = s, options = {
        { text = "In controller mode", value = "controller" }, { text = "Always", value = "always" } } }
    if ThugUI.Visibility then ThugUI.Visibility:AddControls(panel, "resourcePips") end

    panel:SubSection("Pips")
    LayerBlock(panel, GetPipsSpec("pips", "resourcePipsBody"))
    panel:Part("Appearance")
    g, s = PipsSetting("size")
    panel:Slider{ label = "Pip size", min = 4, max = 40, step = 1, format = "%d", get = g, set = s }
    g, s = PipsSetting("layout")
    panel:Dropdown{ label = "Layout", get = g, set = s, options = {
        { text = "Ring", value = "ring" }, { text = "Bar", value = "bar" } } }
    g, s = PipsSetting("radius")
    panel:Slider{ label = "Ring radius", min = 8, max = 200, step = 1, format = "%d", get = g, set = s }
    g, s = PipsSetting("spread")
    panel:Slider{ label = "Share of the circle", min = 0.25, max = 1, step = 0.05,
        tooltip = "0.25 packs the pips into a quarter of the ring, side by side; "
            .. "1 spreads them round the whole circle.", get = g, set = s }
    g, s = PipsSetting("start")
    panel:Slider{ label = "Centred at (o'clock)", min = 1, max = 12, step = 1, format = "%d", get = g, set = s }
    g, s = PipsSetting("gap")
    panel:Slider{ label = "Bar spacing", min = 0, max = 40, step = 1, format = "%d",
        tooltip = "0 puts the pips side by side.", get = g, set = s }
    g, s = PipsSetting("orientation")
    panel:Dropdown{ label = "Bar direction", get = g, set = s, options = {
        { text = "Horizontal", value = "horizontal" }, { text = "Vertical", value = "vertical" } } }

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

    if ThugUI.OEPage then
        ThugUI.OEPage.AddControls(panel, "Pips")
    end

    panel:SubSection("Ring")
    LayerBlock(panel, GetPipsSpec("ring", "resourcePipsRing", 1.6, false))
    panel:Part("Appearance")
    panel:Dropdown{
        label = "Ring art",
        options = ThugUI.RingArt:Options(),
        get = function() return Pips().ringArt or "orb" end,
        set = function(v) Pips().ringArt = v; PipsRefresh() end,
    }
    panel:Dropdown{
        label = "Blend",
        tooltip = "Auto picks additive for Blizzard's glow, rune and sky art, which is white or coloured on black. Multiply darkens what is under it; Alpha key draws hard edges.",
        options = ThugUI.RingArt.BLEND_OPTIONS,
        get = function() return Pips().ringBlend or "auto" end,
        set = function(v) Pips().ringBlend = v; PipsRefresh() end,
    }
    panel:Checkbox{
        label = "Desaturate (let the tint recolour it)",
        get = function() return Pips().ringDesat == true end,
        set = function(v) Pips().ringDesat = v and true or false; PipsRefresh() end,
    }
    panel:Color{
        label = "Ring tint",
        get = function()
            local c = Pips().ringColor
            if type(c) ~= "table" then return 1, 1, 1 end
            return c[1] or 1, c[2] or 1, c[3] or 1
        end,
        set = function(r, gg, b) Pips().ringColor = { r, gg, b }; PipsRefresh() end,
    }
    panel:Slider{
        label = "Ring spin (seconds per turn, 0 = still, negative = the other way)",
        min = -30, max = 30, step = 1, format = "%d",
        get = function() return tonumber(Pips().ringSpin) or 0 end,
        set = function(v) Pips().ringSpin = v; PipsRefresh() end,
    }
    panel:Slider{
        label = "Unlit ring opacity", min = 0, max = 1.0, step = 0.05, format = "%.2f",
        get = function() return tonumber(Pips().ringUnlitAlpha) or 0 end,
        set = function(v) Pips().ringUnlitAlpha = v; PipsRefresh() end,
    }
    panel:Button{
        label = "Reset ring",
        onClick = function()
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
            PipsRefresh()
            panel:Refresh()
        end,
    }
end










local RING_FIELDS = {
    { on = "timerOn", mode = "timerRing", fill = "timerFill", art = "ringArt",
      scale = "ringScale", color = "ringColor", alpha = "ringAlpha", track = "timerTrack",
      defaults = { mode = "cast", scale = 1.0, alpha = 1, track = 0.3 } },
    { on = "timer2On", mode = "timer2", fill = "timer2Fill", art = "timer2Art",
      scale = "timer2Scale", color = "timer2Color", alpha = "timer2Alpha", track = "timer2Track",
      defaults = { mode = "gcd", scale = 1.15, alpha = 1, track = 0.25 } },
}
Page.RING_FIELDS = RING_FIELDS
Page.ringChoice = { health = 1, resource = 1 }

local function TimerRingTab(panel, key)
    local function F() return RING_FIELDS[Page.ringChoice[key] or 1] end
    local function Get(field, default)
        local v = Cfg(key)[F()[field] ]
        if v == nil then return default end
        return v
    end
    local function Set(field, v) Cfg(key)[F()[field] ] = v; Call(key) end

    
    panel:Checkbox{
        label = "Show the timer even when the orb is hidden",
        tooltip = "While a ring is sweeping, it and the ring behind the sweep stay visible whatever the "
            .. "orb's visibility settings are doing. When the timer ends they follow the orb again.",
        get = function() return Cfg(key).timerAlwaysShow == true end,
        set = function(v) Cfg(key).timerAlwaysShow = v and true or false; Call(key) end,
    }
    panel:Dropdown{
        label = "Ring", width = 200,
        tooltip = "The first ring is the orb's own ring. The second sits round it. Both have the same settings.",
        options = { { text = "First ring (the orb's ring)", value = 1 }, { text = "Second ring", value = 2 } },
        get = function() return Page.ringChoice[key] or 1 end,
        set = function(v) Page.ringChoice[key] = v; panel:Refresh() end,
    }
    panel:Checkbox{
        label = "Show a timer on this ring",
        get = function() return Get("on", false) == true end,
        set = function(v) Set("on", v and true or false); panel:Refresh() end,
    }
    
    panel:ActiveIf(function() return Get("on", false) == true end)
    panel:Dropdown{
        label = "Shows",
        tooltip = "Cast follows casts and channels; Global cooldown follows the short lockout after most abilities.",
        options = { { text = "Cast", value = "cast" }, { text = "Global cooldown", value = "gcd" } },
        get = function() return Get("mode", F().defaults.mode) end,
        set = function(v) Set("mode", v) end,
    }
    panel:Dropdown{
        label = "Direction",
        options = { { text = "Fill up", value = "fill" }, { text = "Drain", value = "drain" } },
        get = function() return Get("fill", "fill") end,
        set = function(v) Set("fill", v) end,
    }
    panel:Dropdown{
        label = "Art",
        tooltip = "For the first ring this is the orb's ring art, the same setting as on the Ring tab.",
        options = ThugUI.RingArt:Options(),
        get = function() return Get("art", "orb") end,
        set = function(v) Set("art", v) end,
    }
    panel:Slider{
        label = "Size (x the orb)",
        min = 0.5, max = 1.6, step = 0.01, format = "%.2f",
        get = function() return tonumber(Get("scale", F().defaults.scale)) or F().defaults.scale end,
        set = function(v) Set("scale", v) end,
    }
    panel:Color{
        label = "Tint",
        get = function()
            local c = Get("color", nil)
            if type(c) ~= "table" then return 1, 1, 1 end
            return unpack(c)
        end,
        set = function(r, g, b) Set("color", { r, g, b }) end,
    }
    panel:Slider{
        label = "Opacity",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return tonumber(Get("alpha", 1)) or 1 end,
        set = function(v) Set("alpha", v) end,
    }
    panel:Slider{
        label = "Opacity behind the sweep",
        tooltip = "How visible the ring is under the part that has not filled yet. The second ring also shows at this between timers; 0 hides it until one starts.",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return tonumber(Get("track", F().defaults.track)) or F().defaults.track end,
        set = function(v) Set("track", v) end,
    }
    panel:ActiveIf(nil)
end

function Page:BuildTimerRings(panel)
    panel:FrameSection{ title = "Cast & GCD" }
    panel:Note("Each orb's ring can fill or drain as your cast bar or global cooldown runs, and a "
        .. "second ring round it can follow the other one. Pick the ring to set up with the dropdown.")
    panel:SubSection("Health orb")
    TimerRingTab(panel, "health")
    panel:SubSection("Resource orb")
    TimerRingTab(panel, "resource")
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
    panel:Note("Each orb is a unit: a box you unlock, drag and scale, holding layers. "
        .. "The Unit tab moves and scales the whole box; each layer's tab places, sizes and "
        .. "fades that layer inside it. The ring and your own art sit on the orb and move "
        .. "with it. The health unit hangs off the bottom-left corner of the screen, the "
        .. "resource unit off the bottom-right.")

    panel:Checkbox{
        label = "Test mode: show and unlock the orbs and pips",
        tooltip = "While ticked, both orbs, the resource pips and the pip ring are fully shown and can "
            .. "be dragged, ignoring their visibility settings. Nothing is saved; it turns off when "
            .. "this window closes.",
        get = function() return ThugUI.Orbs and ThugUI.Orbs:IsTestMode() end,
        set = function(v) if ThugUI.Orbs then ThugUI.Orbs:SetTestMode(v) end end,
    }

    OrbSection(panel, "health", "Health orb")
    OrbSection(panel, "resource", "Resource orb")
    Page:BuildTimerRings(panel)

    Page:BuildPips(panel)
end


ThugUI.OrbsPage = Page

ThugUI.Window:RegisterPage{
    id = "orbs",
    category = "ui",
    order = 30,
    scopeKeys = { "Orbs" },
    title = "Orbs",
    summary = "Health and resource orbs.",
    build = function(host, panel)
        Page:Build(host, panel)
    end,
}

return Page
