










ThugUI = ThugUI or {}

local function CL() return ThugUI.ControllerLayout end

local function Build(panel)
    panel:FrameSection{
        title = "Move frames",
        tooltip = "Shows a placeholder for the controller buttons, the cast bar, the tooltip, "
            .. "Blizzard's experience-bar container, our own experience bar, the buffs "
            .. "and the debuffs. Drag them, then untick.",
        unlock = {
            get = function() return CL() and CL().unlocked end,
            set = function(v) if CL() then CL():SetUnlocked(v) end end,
        },
    }
    panel:Note("Every frame here can be dragged while Unlocked. The positions apply "
        .. "on mouse and keyboard both, and each Reset gives the frame back to "
        .. "Blizzard's own position.")

    
    local frames = {
        { title = "Controller buttons", reset = function() CL():ResetBar() end,
          min = 0.5, max = 1.5, key = "barScale",
          setScale = function(v) CL():SetBarScale(v) end,
          vis = "controllerButtons", macroNames = true },
        { title = "Cast bar", reset = function() CL():ResetCast() end,
          min = 0.5, max = 2.5, key = "castScale",
          setScale = function(v) CL():SetCastScale(v) end,
          vis = "castBar", visOpts = { noOpacity = true } },
        { title = "Buffs", reset = function() CL():ResetAura("buff") end,
          min = 0.5, max = 2.5, key = "buffScale",
          setScale = function(v) CL():SetAuraScale("buff", v) end,
          vis = "buffs" },
        { title = "Debuffs", reset = function() CL():ResetAura("debuff") end,
          min = 0.5, max = 2.5, key = "debuffScale",
          setScale = function(v) CL():SetAuraScale("debuff", v) end,
          vis = "debuffs" },
        
        
        
        
        
        
        { title = "Tooltip", reset = function() CL():ResetTooltip() end,
          min = 0.5, max = 2, key = "tooltipScale",
          setScale = function(v) CL():SetTooltipScale(v) end,
          vis = "tooltip", visOpts = { noOpacity = true },
          note = "For unit and world tooltips, the ones that sit in the corner. Tooltips on "
              .. "buttons and bags are left alone. Drag its placeholder while Unlock "
              .. "(top of the page) is ticked; Reset gives back position and scale." },
    }

    for _, fr in ipairs(frames) do
        panel:FrameSection{
            title = fr.title,
            reset = function() if CL() then fr.reset() end end,
        }
        
        if fr.note then panel:Note(fr.note) end
        if fr.key then
            panel:Part("Size & position")
            panel:Slider{
                label = "Scale",
                min = fr.min, max = fr.max, step = 0.05,
                get = function()
                    return ThugUIDB.ControllerLayout and ThugUIDB.ControllerLayout[fr.key] or 1
                end,
                set = function(v) if CL() then fr.setScale(v) end end,
            }
        end
        if fr.vis and ThugUI.Visibility then
            panel:Part("Visibility")
            ThugUI.Visibility:AddControls(panel, fr.vis, fr.visOpts)
        end
        if fr.macroNames then
            
            panel:Part("Appearance")
            panel:Checkbox{
                label = "Hide macro names",
                tooltip = "Hides the macro name printed on controller bar buttons. "
                    .. "The Action Bars page has its own switch for the mouse and keyboard bars.",
                get = function() return ThugUIDB.ControllerLayout and ThugUIDB.ControllerLayout.hideMacroName == true end,
                set = function(v) if CL() then CL():SetHideMacroName(v) end end,
            }
        end
    end
end

ThugUI.Window:RegisterPage{
    id = "controllerlayout",
    category = "controller",
    order = 20,
    title = "Move frames",
    scopeKeys = { "ControllerLayout" },
    summary = "Move, scale and show the controller buttons, cast bar, auras and tooltip.",
    build = function(host, panel) Build(panel) end,
}
