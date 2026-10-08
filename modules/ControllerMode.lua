










local ThugUI = _G.ThugUI
local ControllerMode = {}
ThugUI.ControllerMode = ControllerMode
ThugUI:RegisterModule("ControllerMode", ControllerMode)

ThugUI.defaults.ControllerMode = {
    override = "auto",
}

local callbacks = {}
local active = false
local evaluated = false

function ControllerMode:IsGamepadUI()
    local ok, res = pcall(function()
        return C_InputInterfaceStyle and C_InputInterfaceStyle.GetCurrentStyle
            and Enum.InputDeviceInterfaceType and C_InputInterfaceStyle.GetCurrentStyle() == Enum.InputDeviceInterfaceType.Gamepad
    end)
    return ok and res or false
end

function ControllerMode:IsActive()
    if not ThugUI:IsModuleOn("controller") then return false end
    local override = ThugUIDB.ControllerMode and ThugUIDB.ControllerMode.override or "auto"
    if override == "on" then return true end
    if override == "off" then return false end
    return self:IsGamepadUI()
end




function ControllerMode:RegisterCallback(fn)
    table.insert(callbacks, fn)
    if evaluated then
        local ok, err = pcall(fn, active)
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CONTROLLERMODE", "late callback failed: %s", tostring(err))
        end
    end
end









local FEATURES = {
    chat = function()
        local c = ThugUIDB.GamepadChat
        return not (c and c.enabled == false)
    end,
    mapShortcut = function()
        local c = ThugUIDB.ControllerMode
        return not (c and c.mapShortcut == false)
    end,
    target = function()
        local c = ThugUIDB.ControllerTarget
        return not (c and c.target and c.target.enabled == false)
    end,
    tot = function()
        local c = ThugUIDB.ControllerTarget
        return not (c and c.tot and c.tot.enabled == false)
    end,
    
    
    objectives = function()
        local c = ThugUIDB.Acorns and ThugUIDB.Acorns.objectives
        return not (c and c.controllerHide == false)
    end,
    auras = function()
        local c = ThugUIDB.AuraWindow
        return not (c and c.enabled == false)
    end,
}

function ControllerMode:Uses(feature)
    local on = FEATURES[feature]
    if not on then error("Unknown controller feature: " .. tostring(feature)) end
    return self:IsActive() and on() and true or false
end







function ControllerMode:GetShortcutsBar()
    local main = _G.GamepadMainActionBarFrame
    local unit = main and main.PageUnit
    return unit and unit.ShortcutsActionBar or nil
end



local featureCallbacks = {}

function ControllerMode:RegisterFeatureCallback(feature, fn)
    featureCallbacks[feature] = featureCallbacks[feature] or {}
    table.insert(featureCallbacks[feature], fn)
end

function ControllerMode:NotifyFeature(feature)
    for i, fn in ipairs(featureCallbacks[feature] or {}) do
        local ok, err = pcall(fn, self:Uses(feature))
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CONTROLLERMODE", "%s feature callback %d failed: %s",
                feature, i, tostring(err))
        end
    end
end

function ControllerMode:SetOverride(v)
    ThugUIDB.ControllerMode.override = v
    self:Evaluate()
end

function ControllerMode:Evaluate()
    local old = active
    active = self:IsActive()
    if active ~= old or not evaluated then
        evaluated = true
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CONTROLLERMODE", "Active state changed to " .. tostring(active))
        end
        
        
        for i, cb in ipairs(callbacks) do
            local ok, err = pcall(cb, active)
            if not ok and ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("CONTROLLERMODE", "callback %d failed: %s", i, tostring(err))
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, cvar)
    if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
    if event == "PLAYER_LOGIN" then
        ControllerMode:Evaluate()
    elseif event == "CVAR_UPDATE" and type(cvar) == "string" and cvar:lower() == "inputdeviceinterfacestyle" then
        ControllerMode:Evaluate()
    end
end)





function ControllerMode:Initialize()
    ThugUI.SafeRegisterEvent(frame, "PLAYER_LOGIN")
    ThugUI.SafeRegisterEvent(frame, "CVAR_UPDATE")
end
