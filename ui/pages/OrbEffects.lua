









local ThugUI = _G.ThugUI

local OEPage = {}




function OEPage.AddControls(panel, target)
    local OE = ThugUI.OrbEffects
    if not OE then return end

    
    
    local M = ThugUI.Modules
    local entry = M and M.Entry and M:Entry("orbeffects")
    if entry and entry.soon then return end
    if not ThugUI:IsModuleOn("orbeffects") then
        panel:Note("Turn on Orb effects on the Modules page to use preset looks.")
        return
    end

    local kind = string.lower(target)
    if kind == "pips" then
        local _, classFile = UnitClass("player")
        if not OE.PIP_CLASSES[classFile] then return end
    end

    panel:Note("|cffff3333Preset looks add animated layers and lower performance. "
        .. "Pick Default if your frame rate drops.|r")

    local state = {}   

    
    
    
    local function Target()
        if kind ~= "resource" then return kind end
        return state.resource
    end

    if kind == "resource" then
        local res = OE:Resources()
        local _, token = ThugUI.ResourceRing:GetPowerType()
        token = token and string.lower(token)
        state.resource = res[1]
        for _, r in ipairs(res) do
            if r == token then state.resource = r end
        end
        if #res > 1 then
            local options = {}
            for _, r in ipairs(res) do
                options[#options + 1] = { text = (r:gsub("^%l", string.upper)), value = r }
            end
            panel:Dropdown{
                label = "Resource",
                tooltip = "Which resource's look the controls below change.",
                options = options,
                get = function() return state.resource end,
                set = function(v)
                    state.resource = v
                    state.layer = nil
                    panel:Refresh()
                end,
            }
        end
    end

    
    
    local function C()
        ThugUIDB.OrbEffects = ThugUIDB.OrbEffects or {}
        local t = Target()
        ThugUIDB.OrbEffects[t] = ThugUIDB.OrbEffects[t] or { pack = "default", adjust = {} }
        return ThugUIDB.OrbEffects[t]
    end

    local function LayerOptions()
        local stack = OE:Stack(Target())
        local rows = {}
        for _, l in ipairs(stack and stack.layers or {}) do
            rows[#rows + 1] = { text = l.name, value = l.name }
        end
        if #rows == 0 then rows[1] = { text = "(no layers)", value = "" } end
        return rows
    end
    
    
    local function Selected()
        local rows = LayerOptions()
        for _, r in ipairs(rows) do
            if r.value == state.layer then return state.layer end
        end
        state.layer = rows[1].value
        return state.layer
    end
    local function GetAdj(field, default)
        local adj = C().adjust and C().adjust[Selected()]
        if adj and adj[field] ~= nil then return adj[field] end
        return default
    end
    local function SetAdj(field, v)
        if Selected() == "" then return end
        OE:Adjust(Target(), state.layer, field, v)
    end

    panel:Dropdown{
        label = "Look",
        options = function() return OE:Packs(Target()) end,
        get = function() return C().pack or "default" end,
        set = function(v)
            OE:Choose(Target(), v)
            panel:Refresh()
        end,
    }

    panel:Group("Preset layers")
    panel:Dropdown{
        label = "Layer",
        options = LayerOptions,
        get = Selected,
        set = function(v)
            state.layer = v
            panel:Refresh()
        end,
    }
    panel:Slider{
        label = "X", min = -100, max = 100, step = 1,
        get = function() return GetAdj("x", 0) end,
        set = function(v) SetAdj("x", v) end,
    }
    panel:Slider{
        label = "Y", min = -100, max = 100, step = 1,
        get = function() return GetAdj("y", 0) end,
        set = function(v) SetAdj("y", v) end,
    }
    panel:Slider{
        label = "Scale", min = 0.25, max = 3, step = 0.05,
        get = function() return GetAdj("scale", 1) end,
        set = function(v) SetAdj("scale", v) end,
    }
    panel:Button{
        label = "Reset layer adjustments",
        onClick = function()
            C().adjust = {}
            OE:Refresh(Target())
            panel:Refresh()
        end,
    }
    panel:Note("Packs are designed in the Thug Asset Browser. Default is the orb's own look.")
end

ThugUI.OEPage = OEPage
return OEPage
