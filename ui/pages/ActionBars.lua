



ThugUI = ThugUI or {}

local Page = {}

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.ActionBars = ThugUIDB.ActionBars or {}
    ThugUIDB.ActionBars.bars = ThugUIDB.ActionBars.bars or {}
    return ThugUIDB.ActionBars
end








local function EditModeButton(panel)
    if InCombatLockdown and InCombatLockdown() then
        
        panel:Note("Open Edit Mode from the game menu to move and resize these.")
        return
    end
    local btn = CreateFrame("Button", nil, panel.parent, "SecureActionButtonTemplate,UIPanelButtonTemplate")
    btn:SetSize(220, 24)
    btn:SetText("Move/resize in Edit Mode")
    btn.labelText = "Move/resize in Edit Mode"
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("useOnKeyDown", false)
    btn:SetAttribute("macrotext", (_G.SLASH_EDITMODE1 or "/editmode"))
    panel:Place(btn, 28)
    if panel.Index then panel:Index("Move/resize in Edit Mode", btn, "control") end
    Page.editModeButtons = Page.editModeButtons or {}
    table.insert(Page.editModeButtons, btn)
    return btn
end

function Page:Build(host, panel)
    local AB = ThugUI.ActionBars
    if not AB then return end

    panel:Header("Action Bars")
    panel:Note("Edit Mode still positions every bar and its own settings "
        .. "(visibility, Icon Size) still apply on top. This page changes how the "
        .. "buttons are laid out inside the bar.")

    panel:Section("Action bars")

    EditModeButton(panel)

    
    panel:Dropdown{
        label = "Bar",
        options = function()
            local opts = {}
            for _, bar in ipairs(AB.BARS) do
                table.insert(opts, { value = bar.key, text = bar.label })
            end
            return opts
        end,
        get = function() return Page.selectedKey or "MainActionBar" end,
        set = function(v)
            Page.selectedKey = v
            ThugUI.Window:RefreshActivePage()
        end,
    }

    
    
    
    Page.widgets = Page.widgets or {}
    Page.widgets.enabled = panel:Checkbox{
        label = "Enable this bar (Blizzard's Action Bar setting)",
        tooltip = "The same switch as Options > Action Bars. The main bar is "
            .. "always on. Takes effect out of combat.",
        get = function()
            local enabled = AB.IsBarEnabled(Page.selectedKey or "MainActionBar")
            return enabled == true
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            if key == "MainActionBar" then return end
            AB:SetBarEnabled(key, v)
            ThugUI.Window:RefreshActivePage()
        end,
    }

    
    panel:Checkbox{
        label = "Manage this bar with ThugUI",
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].managed or false
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].managed = v
            AB:SetManaged(key, v)
        end,
    }

    
    panel:Dropdown{
        label = "Layout",
        options = {
            { value = false, text = "Rows (fill left to right)" },
            { value = true, text = "Columns (fill top to bottom)" },
        },
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].vertical or false
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].vertical = v
            AB:ApplyLayout(key)
        end,
    }

    
    Page.widgets.numButtons = panel:Slider{
        label = "Buttons shown",
        min = 1, max = 12, step = 1,
        format = "%d",
        tooltip = "Show only the first N buttons; the rest are hidden from the "
            .. "end of the bar. Six shows buttons 1-6 and hides 7-12.",
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].numButtons or 12
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].numButtons = v
            AB:ApplyLayout(key)
        end,
    }

    
    
    Page.widgets.perLine = panel:Slider{
        label = "Buttons per row / column",
        min = 1, max = 12, step = 1,
        format = "%d",
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].perLine or 12
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].perLine = v
            AB:ApplyLayout(key)
        end,
    }

    
    panel:Slider{
        label = "Button size",
        min = 20, max = 64, step = 1,
        format = "%d",
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].buttonSize or 45
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].buttonSize = v
            AB:ApplyLayout(key)
        end,
    }

    
    panel:Slider{
        label = "Spacing",
        min = 0, max = 12, step = 1,
        format = "%d",
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].spacing or 2
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].spacing = v
            AB:ApplyLayout(key)
        end,
    }

    
    local function TextToggle(label, option, tooltip)
        panel:Checkbox{
            label = label,
            tooltip = tooltip,
            get = function()
                local bars = Cfg().bars
                local cfg = bars[Page.selectedKey or "MainActionBar"]
                return cfg and cfg[option] == true
            end,
            set = function(v)
                local key = Page.selectedKey or "MainActionBar"
                local bars = Cfg().bars
                if not bars[key] then bars[key] = {} end
                bars[key][option] = v
                AB:ApplyLayout(key)
            end,
        }
    end
    TextToggle("Hide keybind text", "hideHotkey",
        "Also hides the red out-of-range dot, which Blizzard draws in the same place.")
    TextToggle("Hide macro name text", "hideMacroName")
    TextToggle("Hide stack and charge counts", "hideCount")

    
    panel:Checkbox{
        label = "Reverse button order",
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].reverse or false
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].reverse = v
            AB:ApplyLayout(key)
        end,
    }

    
    panel:Checkbox{
        label = "Lock this bar to its own page",
        tooltip = "Off, the main bar pages with stealth, forms and vehicles as Blizzard's does. "
            .. "On, it stays on page 1. Bars 2–8 never page, so this does nothing for them. "
            .. "Takes effect on the next form change or /reload if the client refuses the immediate refresh.",
        get = function()
            local bars = Cfg().bars
            return bars[Page.selectedKey or "MainActionBar"] and bars[Page.selectedKey or "MainActionBar"].lockPage or false
        end,
        set = function(v)
            local key = Page.selectedKey or "MainActionBar"
            local bars = Cfg().bars
            if not bars[key] then bars[key] = {} end
            bars[key].lockPage = v
            AB:ApplyPageLock(key)
        end,
    }

    panel:Note("Turning management off restores Blizzard's layout on the next "
        .. "/reload. The page lock is independent of management.")

    panel:Section("XP, micro menu & bags")

    EditModeButton(panel)

    if ThugUI.Visibility and ThugUI.Visibility.AddControls then
        panel:Group("XP bar")
        ThugUI.Visibility:AddControls(panel, "statusBar")

        panel:Group("Micro menu")
        ThugUI.Visibility:AddControls(panel, "microMenu")

        panel:Group("Bag bar")
        ThugUI.Visibility:AddControls(panel, "bagBar")
    end
end

Page.selectedKey = "MainActionBar"


ThugUI.ActionBars.Page = Page

ThugUI.Window:RegisterPage{
    id = "actionbars",
    category = "combat",
    order = 30,
    scopeKeys = { "ActionBars" },
    summary = "Blizzard's bars in your rows and columns, with a page lock.",
    title = "Action Bars",
    build = function(host, panel) Page:Build(host, panel) end,
    
    
    
}

return Page
