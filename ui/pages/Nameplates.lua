



ThugUI = ThugUI or {}

local Page = {}

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Nameplates = ThugUIDB.Nameplates or {}
    return ThugUIDB.Nameplates
end






function Page.EnumOptions(enumTable)
    local options = {}
    if type(enumTable) ~= "table" then return options end
    for name, value in pairs(enumTable) do
        if type(value) == "number" then
            table.insert(options, { value = value, text = name })
        end
    end
    table.sort(options, function(a, b) return a.value < b.value end)
    return options
end



function Page.MissingCVars()
    local NP = ThugUI.Nameplates
    local missing = {}
    for _, cvarName in pairs(NP.CVARS) do
        if not NP.HasCVar(cvarName) then
            table.insert(missing, cvarName)
        end
    end
    table.sort(missing)
    return missing
end

function Page:Build(host, panel)
    local NP = ThugUI.Nameplates
    if not NP then return end

    panel:Header("Nameplates")
    panel:Note("Blizzard's own Options → Nameplates still applies; this page is "
        .. "the handful of things it does not offer plus the knobs behind them. "
        .. "Controls marked (CVar) write Blizzard's setting directly and survive "
        .. "a reset of this addon's saved variables.")

    
    
    
    panel:Section("Allies")

    panel:Checkbox{
        label = "Show names only while out of combat",
        tooltip = "Applies to friendly players — it drives Blizzard's own "
            .. "name-only mode, which is player-only. Health bars return the "
            .. "moment you enter combat.",
        get = function()
            return Cfg().friendly and Cfg().friendly.nameOnlyOutOfCombat or false
        end,
        set = function(v)
            NP:SetFriendlyNameOnly(v)
        end,
    }

    if NP.HasCVar(NP.CVARS.friendlyClassNames) then
        panel:Checkbox{
            label = "Class-colour ally names (CVar)",
            get = function() return NP.GetCVarBool(NP.CVARS.friendlyClassNames) end,
            set = function(v) NP:SetCVarSafe(NP.CVARS.friendlyClassNames, v and "1" or "0") end,
        }
    end

    if NP.HasCVar(NP.CVARS.friendlyClassBars) then
        panel:Checkbox{
            label = "Class-colour ally health bars (CVar)",
            get = function() return NP.GetCVarBool(NP.CVARS.friendlyClassBars) end,
            set = function(v) NP:SetCVarSafe(NP.CVARS.friendlyClassBars, v and "1" or "0") end,
        }
    end

    if NP.HasCVar(NP.CVARS.friendlyNpcs) then
        panel:Checkbox{
            label = "Show friendly NPC nameplates (CVar)",
            get = function() return NP.GetCVarBool(NP.CVARS.friendlyNpcs) end,
            set = function(v) NP:SetCVarSafe(NP.CVARS.friendlyNpcs, v and "1" or "0") end,
        }
    end

    
    
    
    panel:Section("Enemies")

    panel:Checkbox{
        label = "Show names only while out of combat",
        tooltip = "Hides the health and cast bars on hostile plates until combat "
            .. "starts; the name stays clickable.",
        get = function()
            return Cfg().enemy and Cfg().enemy.nameOnlyOutOfCombat or false
        end,
        set = function(v)
            NP:SetEnemyNameOnly(v)
        end,
    }

    panel:Color{
        label = "Name colour in name-only mode",
        get = function()
            local color = Cfg().enemy and Cfg().enemy.nameOnlyColor or {1.0, 0.25, 0.25}
            return color[1], color[2], color[3]
        end,
        set = function(r, g, b)
            NP:SetEnemyNameOnlyColor(r, g, b)
        end,
    }

    if NP.HasCVar(NP.CVARS.enemyClassBars) then
        panel:Checkbox{
            label = "Class-colour enemy player health bars (CVar)",
            get = function() return NP.GetCVarBool(NP.CVARS.enemyClassBars) end,
            set = function(v) NP:SetCVarSafe(NP.CVARS.enemyClassBars, v and "1" or "0") end,
        }
    end

    
    
    
    panel:Section("Target")

    panel:Checkbox{
        label = "Outline my current target",
        tooltip = "Draws a coloured outline around the target's health bar and "
            .. "hides Blizzard's white one; on a name-only plate the name takes "
            .. "the colour instead.",
        get = function()
            
            
            local t = Cfg().target
            if t and t.highlight ~= nil then return t.highlight end
            return true
        end,
        set = function(v)
            NP:SetTargetHighlight(v)
        end,
    }

    panel:Color{
        label = "Outline colour",
        get = function()
            local color = Cfg().target and Cfg().target.color or {1.0, 0.82, 0.0}
            return color[1], color[2], color[3]
        end,
        set = function(r, g, b)
            NP:SetTargetColor(r, g, b)
        end,
    }

    panel:Slider{
        label = "Outline thickness",
        min = 1, max = 4, step = 1,
        format = "%d",
        get = function()
            return Cfg().target and Cfg().target.thickness or 2
        end,
        set = function(v)
            NP:SetTargetThickness(v)
        end,
    }

    
    
    
    panel:Section("Level")

    panel:Checkbox{
        label = "Show the unit's level inside the bar",
        tooltip = "Displays the unit's level as text at the right end of the health bar. "
            .. "Coloured like the default UI's target frame: grey for higher level, "
            .. "green for lower level, yellow for equal, orange to red for harder, "
            .. "and gold for non-attackable. Shows ?? when the level is unknown.",
        get = function()
            return Cfg().level and Cfg().level.show or false
        end,
        set = function(v)
            NP:SetLevelShown(v)
        end,
    }

    panel:Slider{
        label = "Size",
        min = 8, max = 16, step = 1,
        format = "%d",
        get = function()
            return Cfg().level and Cfg().level.size or 10
        end,
        set = function(v)
            NP:SetLevelSize(v)
        end,
    }

    
    panel:Dropdown{
        label = "Normal font",
        options = NP.FONTS,
        get = function()
            return Cfg().level and Cfg().level.fonts and Cfg().level.fonts.normal or "Fonts\\FRIZQT__.TTF"
        end,
        set = function(v)
            NP:SetLevelFont("normal", v)
        end,
    }

    panel:Dropdown{
        label = "Elite font",
        options = NP.FONTS,
        get = function()
            return Cfg().level and Cfg().level.fonts and Cfg().level.fonts.elite or "Fonts\\FRIZQT__.TTF"
        end,
        set = function(v)
            NP:SetLevelFont("elite", v)
        end,
    }

    panel:Dropdown{
        label = "Rare font",
        options = NP.FONTS,
        get = function()
            return Cfg().level and Cfg().level.fonts and Cfg().level.fonts.rare or "Fonts\\MORPHEUS.TTF"
        end,
        set = function(v)
            NP:SetLevelFont("rare", v)
        end,
    }

    panel:Dropdown{
        label = "Boss font",
        options = NP.FONTS,
        get = function()
            return Cfg().level and Cfg().level.fonts and Cfg().level.fonts.boss or "Fonts\\SKURRI.TTF"
        end,
        set = function(v)
            NP:SetLevelFont("boss", v)
        end,
    }

    
    
    
    panel:Section("Bars")

    panel:Checkbox{
        label = "Hide the border frame around health bars",
        tooltip = "Replaces Blizzard's bar frame with a flat dark backdrop the "
            .. "size of the bar.",
        get = function()
            return Cfg().bars and Cfg().bars.hideBorder or false
        end,
        set = function(v)
            NP:SetHideBorder(v)
        end,
    }

    
    if NP.fullCurve then
        panel:Checkbox{
            label = "Hide the health bar while the unit is at full health",
            tooltip = "The bar fades in the moment health changes and out again at full; "
                .. "your current target's bar always shows.",
            get = function()
                return Cfg().bars and Cfg().bars.hideWhenFull or false
            end,
            set = function(v)
                NP:SetHideWhenFull(v)
            end,
        }
    else
        panel:Checkbox{
            label = "Hide the health bar while the unit is at full health (unavailable on this client)",
            tooltip = "",
            get = function()
                return false
            end,
            set = function(v)
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("NAMEPLATES", "hideWhenFull is unavailable: C_CurveUtil or Enum.LuaCurveType missing")
                end
            end,
        }
    end

    
    if NP.HasCVar(NP.CVARS.style) then
        local styleOptions = Page.EnumOptions(Enum and Enum.NamePlateStyle)
        if #styleOptions > 0 then
            panel:Dropdown{
                label = "Style (CVar)",
                options = styleOptions,
                get = function()
                    return NP.GetCVarNumber(NP.CVARS.style, 0)
                end,
                set = function(v)
                    NP:SetCVarSafe(NP.CVARS.style, v)
                end,
            }
        end
    end

    
    if NP.HasCVar(NP.CVARS.size) then
        local sizeOptions = Page.EnumOptions(Enum and Enum.NamePlateSize)
        if #sizeOptions > 0 then
            panel:Dropdown{
                label = "Size (CVar)",
                options = sizeOptions,
                get = function()
                    return NP.GetCVarNumber(NP.CVARS.size, 0)
                end,
                set = function(v)
                    NP:SetCVarSafe(NP.CVARS.size, v)
                end,
            }
        end
    end

    if NP.HasCVar(NP.CVARS.globalScale) then
        panel:Slider{
            label = "Global scale (CVar)",
            min = 0.5, max = 2.0, step = 0.05,
            format = "%.2f",
            get = function()
                return NP.GetCVarNumber(NP.CVARS.globalScale, 1.0)
            end,
            set = function(v)
                NP:SetCVarSafe(NP.CVARS.globalScale, v)
            end,
        }
    end

    if NP.HasCVar(NP.CVARS.occludedAlpha) then
        panel:Slider{
            label = "Faded (occluded) alpha (CVar)",
            min = 0, max = 1, step = 0.05,
            format = "%.2f",
            get = function()
                return NP.GetCVarNumber(NP.CVARS.occludedAlpha, 0.5)
            end,
            set = function(v)
                NP:SetCVarSafe(NP.CVARS.occludedAlpha, v)
            end,
        }
    end

    if NP.HasCVar(NP.CVARS.minAlpha) then
        panel:Slider{
            label = "Minimum alpha (CVar)",
            min = 0, max = 1, step = 0.05,
            format = "%.2f",
            get = function()
                return NP.GetCVarNumber(NP.CVARS.minAlpha, 0.1)
            end,
            set = function(v)
                NP:SetCVarSafe(NP.CVARS.minAlpha, v)
            end,
        }
    end

    
    local missingCVars = Page.MissingCVars()
    if #missingCVars > 0 then
        panel:Note("CVars not found on this client: " .. table.concat(missingCVars, ", "))
    end
end

ThugUI.Nameplates.Page = Page

ThugUI.Window:RegisterPage{
    id = "nameplates",
    category = "combat",
    order = 40,
    summary = "Name-only plates out of combat, class colours, level text.",
    title = "Nameplates",
    build = function(host, panel) Page:Build(host, panel) end,
}
