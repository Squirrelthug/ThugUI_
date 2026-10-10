




ThugUI = ThugUI or {}

local Page = {}

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.ControllerTarget = ThugUIDB.ControllerTarget or {}
    return ThugUIDB.ControllerTarget
end

function Page:Build(host, panel)
    local CT = ThugUI.ControllerTarget
    if not CT then return end
    
    panel:Header("Target frames")
    if ThugUI.UnitFrames and ThugUI.UnitFrames:IsMouseLayer() then
        panel:Note("Mouse play: changes here are stored as differences from your controller setup.")
        panel:Button{
            label = "Reset to controller",
            onClick = function()
                ThugUI.UnitFrames:Reset("ControllerTarget")
            end,
        }
    end
    panel:Note("These frames replace Blizzard's target and target-of-target frames. "
        .. "Blizzard's target frame is switched off while they run (it throws when left running out of sight), "
        .. "so switching the tile off needs a /reload to bring it back. The target cast bar goes with Blizzard's frame."
        .. (ThugUI.client == "forever" and " (In controller mode they replace them as well.)" or ""))
    
    panel:Checkbox{
        label = "Unlocked (drag to move)",
        get = function() return Cfg().unlocked or false end,
        set = function(v)
            CT:SetUnlocked(v)
        end,
    }
    
    local textOptions = {
        { value = "percent", text = "Percent" },
        { value = "number", text = "Number" },
        { value = "none", text = "Off" }
    }
    
    local auraOptions = {
        { value = "below", text = "Below" },
        { value = "above", text = "Above" },
        { value = "none", text = "Off" }
    }
    
    
    
    local function FrameSection(key, title)
        local function GetC(prop, default)
            local c = Cfg()[key]
            if c and c[prop] ~= nil then return c[prop] end
            return default
        end

        local function SetC(prop, v)
            if not Cfg()[key] then Cfg()[key] = {} end
            Cfg()[key][prop] = v
            CT:ApplyAll()
        end

        panel:FrameSection{
            title = title,
            enabled = {
                get = function() return GetC("enabled", true) end,
                set = function(v) SetC("enabled", v) end,
            },
        }

        
        panel:SubSection("Size & bars")
        panel:Part("Size & position")
        
        
        panel:Slider{
            label = "Scale",
            min = 0.5, max = 4, step = 0.05, format = "%.2f",
            get = function() return GetC("scale", 1) end,
            set = function(v) SetC("scale", v) end,
        }
        panel:Slider{
            label = "Width",
            min = 80, max = 1000, step = 1, format = "%d",
            get = function() return GetC("width", key == "target" and 220 or 140) end,
            set = function(v) SetC("width", v) end,
        }
        panel:Slider{
            label = "Health height",
            min = 6, max = 120, step = 1, format = "%d",
            get = function() return GetC("healthHeight", key == "target" and 20 or 14) end,
            set = function(v) SetC("healthHeight", v) end,
        }
        panel:Checkbox{
            label = "Resource bar",
            get = function() return GetC("showPower", true) end,
            set = function(v) SetC("showPower", v); panel:Refresh() end,
        }
        panel:ActiveIf(function() return GetC("showPower", true) ~= false end)
        panel:Slider{
            label = "Resource height",
            min = 2, max = 60, step = 1, format = "%d",
            get = function() return GetC("powerHeight", key == "target" and 6 or 4) end,
            set = function(v) SetC("powerHeight", v) end,
        }
        panel:ActiveIf(nil)
        panel:Button{
            label = "Reset position",
            onClick = function() CT:ResetPosition(key) end,
        }

        
        panel:SubSection("Text & auras")
        panel:Part("Content")
        panel:Slider{
            label = "Text size",
            min = 0.5, max = 3, step = 0.05, format = "%.2f",
            get = function() return GetC("textScale", 1) end,
            set = function(v) SetC("textScale", v) end,
        }
        panel:Slider{
            label = "Icon size",
            min = 0.5, max = 3, step = 0.05, format = "%.2f",
            get = function() return GetC("iconScale", 1) end,
            set = function(v) SetC("iconScale", v) end,
        }
        panel:Dropdown{
            label = "Health text",
            options = textOptions,
            get = function() return GetC("healthText", "percent") end,
            set = function(v) SetC("healthText", v) end,
        }
        panel:Checkbox{
            label = "Name",
            get = function() return GetC("showName", true) end,
            set = function(v) SetC("showName", v) end,
        }
        panel:Checkbox{
            label = "Level",
            get = function() return GetC("showLevel", key == "target") end,
            set = function(v) SetC("showLevel", v) end,
        }
        panel:Checkbox{
            label = "Faction icon",
            get = function() return GetC("showFaction", key == "target") end,
            set = function(v) SetC("showFaction", v) end,
        }
        panel:Checkbox{
            label = "Role icon",
            get = function() return GetC("showRole", true) end,
            set = function(v) SetC("showRole", v) end,
        }
        panel:Group("Auras")
        panel:Dropdown{
            label = "Auras",
            options = auraOptions,
            get = function() return GetC("auras", "below") end,
            set = function(v) SetC("auras", v); panel:Refresh() end,
        }
        
        panel:ActiveIf(function() return GetC("auras", "below") ~= "none" end)
        panel:Checkbox{
            label = "Show debuffs",
            get = function() return GetC("showDebuffs", true) ~= false end,
            set = function(v) SetC("showDebuffs", v and true or false) end,
        }
        panel:Checkbox{
            label = "Show buffs",
            get = function() return GetC("showBuffs", true) ~= false end,
            set = function(v) SetC("showBuffs", v and true or false) end,
        }
        panel:Slider{
            label = "Aura size",
            min = 10, max = 80, step = 1, format = "%d",
            get = function() return GetC("auraSize", key == "target" and 22 or 16) end,
            set = function(v) SetC("auraSize", v) end,
        }
        panel:Slider{
            label = "Aura text size",
            min = 0.3, max = 2, step = 0.05, format = "%.2f",
            get = function() return GetC("auraTextScale", 1) end,
            set = function(v) SetC("auraTextScale", v) end,
        }
        panel:Checkbox{
            label = "Aura timers",
            get = function() return GetC("auraTimers", true) ~= false end,
            set = function(v) SetC("auraTimers", v and true or false) end,
        }
        panel:Slider{
            label = "Aura count",
            min = 0, max = 40, step = 1, format = "%d",
            get = function() return GetC("auraMax", key == "target" and 16 or 6) end,
            set = function(v) SetC("auraMax", v) end,
        }
        panel:Slider{
            label = "Auras per row",
            min = 1, max = 20, step = 1, format = "%d",
            get = function() return GetC("auraPerRow", key == "target" and 8 or 6) end,
            set = function(v) SetC("auraPerRow", v) end,
        }
        panel:ActiveIf(nil)

        
        panel:SubSection("Tint & visibility")
        panel:Group("Darken")
        panel:Checkbox{
            label = "Darken the bars",
            tooltip = "A dark layer over the health and resource bars; the text stays bright above it. "
                .. "While the frames are unlocked it turns red whatever this says.",
            get = function() return GetC("dim", true) ~= false end,
            set = function(v) SetC("dim", v and true or false); panel:Refresh() end,
        }
        panel:ActiveIf(function() return GetC("dim", true) ~= false end)
        panel:Slider{
            label = "Darkness",
            tooltip = "0 is no darkening, 0.9 is nearly black. 0.5 is how it has always looked.",
            min = 0, max = 0.9, step = 0.05, format = "%.2f",
            get = function() return tonumber(GetC("dimAmount", 0.5)) or 0.5 end,
            set = function(v) SetC("dimAmount", v) end,
        }
        panel:ActiveIf(nil)
        if ThugUI.Visibility then
            panel:Part("Visibility")
            ThugUI.Visibility:AddControls(panel, key)
        end
    end
    
    FrameSection("target", "Target")
    FrameSection("tot", "Target of target")
end

ThugUI.ControllerTarget.Page = Page

ThugUI.Window:RegisterPage{
    id = "controllertarget",
    category = "ui",
    order = 40,
    scopeKeys = { "ControllerTarget" },
    summary = "Our own target and target-of-target frames.",
    title = "Target frames",
    build = function(host, panel) Page:Build(host, panel) end,
}
