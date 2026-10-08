








ThugUI = ThugUI or {}

local function Build(panel)
    panel:FrameSection{
        title = "Experience bar",
        enabled = {
            get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.enabled end,
            set = function(v)
                ThugUIDB.XPBar.enabled = v and true or false
                if ThugUI.XPBar then ThugUI.XPBar:Update() end
            end,
        },
        
        
        unlock = {
            get = function() return ThugUI.XPBar and ThugUI.XPBar.unlocked end,
            set = function(v)
                if ThugUI.XPBar then ThugUI.XPBar:SetUnlocked(v) end
            end,
        },
        reset = function() if ThugUI.XPBar then ThugUI.XPBar:ResetPosition() end end,
    }

    panel:Note("Our own bar, horizontal or vertical. Tick Unlock above to drag it. "
        .. "Blizzard's own experience bar (and its container, above) still exists "
        .. "and can still be moved -- this is a second, vertical-capable bar.")

    panel:Part("Size & position")
    panel:Slider{
        label = "Scale",
        min = 0.5, max = 2.5, step = 0.05,
        get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.scale or 1 end,
        set = function(v)
            ThugUIDB.XPBar.scale = v
            if ThugUI.XPBar then ThugUI.XPBar:Layout() end
        end,
    }
    panel:Slider{
        label = "Length",
        min = 100, max = 1200, step = 10, format = "%d",
        get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.length or 400 end,
        set = function(v)
            ThugUIDB.XPBar.length = v
            if ThugUI.XPBar then ThugUI.XPBar:Layout() end
        end,
    }
    panel:Slider{
        label = "Thickness",
        min = 4, max = 40, step = 1, format = "%d",
        get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.thickness or 10 end,
        set = function(v)
            ThugUIDB.XPBar.thickness = v
            if ThugUI.XPBar then ThugUI.XPBar:Layout() end
        end,
    }
    panel:Dropdown{
        label = "Orientation",
        options = {
            { text = "Horizontal", value = "horizontal" },
            { text = "Vertical", value = "vertical" },
        },
        get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.orientation or "horizontal" end,
        set = function(v)
            ThugUIDB.XPBar.orientation = v
            if ThugUI.XPBar then ThugUI.XPBar:Layout() end
        end,
    }

    panel:Part("Visibility")
    panel:Dropdown{
        label = "Show",
        options = {
            { text = "In controller mode", value = "controller" },
            { text = "Always", value = "always" },
        },
        get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.show or "controller" end,
        set = function(v)
            ThugUIDB.XPBar.show = v
            if ThugUI.XPBar then ThugUI.XPBar:Update() end
        end,
    }
    if ThugUI.Visibility then ThugUI.Visibility:AddControls(panel, "xpBar") end

    panel:Part("Appearance")
    panel:Color{
        label = "Bar colour",
        get = function()
            local c = ThugUIDB.XPBar and ThugUIDB.XPBar.color or { 0.58, 0.0, 0.55 }
            return c[1], c[2], c[3]
        end,
        set = function(r, g, b)
            ThugUIDB.XPBar.color = { r, g, b }
            if ThugUI.XPBar then ThugUI.XPBar:ApplyColors() end
        end,
    }
    panel:Color{
        label = "Rested colour",
        get = function()
            local c = ThugUIDB.XPBar and ThugUIDB.XPBar.restedColor or { 0.0, 0.39, 0.88, 0.6 }
            return c[1], c[2], c[3]
        end,
        set = function(r, g, b)
            
            
            
            local existing = ThugUIDB.XPBar.restedColor
            local a = (existing and existing[4]) or 0.6
            ThugUIDB.XPBar.restedColor = { r, g, b, a }
            if ThugUI.XPBar then ThugUI.XPBar:ApplyColors() end
        end,
    }
    panel:Checkbox{
        label = "Percent text",
        get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.showText end,
        set = function(v)
            ThugUIDB.XPBar.showText = v and true or false
            if ThugUI.XPBar then ThugUI.XPBar:Update() end
        end,
    }

    panel:Part("Content")
    panel:Checkbox{
        label = "Hide Blizzard's XP and reputation bars while shown",
        get = function() return ThugUIDB.XPBar and ThugUIDB.XPBar.hideBlizzard end,
        set = function(v)
            ThugUIDB.XPBar.hideBlizzard = v and true or false
            if ThugUI.XPBar then ThugUI.XPBar:Update() end
        end,
    }
end

ThugUI.Window:RegisterPage{
    id = "xpbar",
    category = "controller",
    order = 50,
    scopeKeys = { "XPBar" },
    summary = "Our own experience bar, horizontal or vertical.",
    title = "Experience bar",
    build = function(host, panel) Build(panel) end,
}
