










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
        local c = ThugUIDB.ControllerObjectives
        return not (c and c.enabled == false)
    end,
    
    auras = function()
        return ThugUI:IsModuleOn("auras") and true or false
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















function ControllerMode:GamepadUIMacro()
    local enum = Enum and Enum.InputDeviceInterfaceType
    if not (enum and enum.Gamepad ~= nil) then return nil end
    return "/console InputDeviceInterfaceStyle " .. tostring(enum.Gamepad)
end



function ControllerMode:NeedsReload()
    
    return ThugUI.controllerAtLoad == false and self:IsActive()
end

local secureButtons = {}

local function RefreshSecureButton(btn)
    if InCombatLockdown and InCombatLockdown() then return end
    if ControllerMode:NeedsReload() then
        btn:SetAttribute("macrotext", "/reload")
        btn:SetText("Reload to finish")
    elseif ControllerMode:IsGamepadUI() then
        btn:SetAttribute("macrotext", "")
        btn:SetText("Gamepad UI is on")
    else
        btn:SetAttribute("macrotext", ControllerMode:GamepadUIMacro() or "")
        btn:SetText("Turn on Gamepad UI")
    end
end




function ControllerMode:CreateGamepadUIButton(parent, width)
    if InCombatLockdown and InCombatLockdown() then return nil end
    if not self:GamepadUIMacro() then return nil end
    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate,UIPanelButtonTemplate")
    btn:SetSize(width or 200, 24)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("useOnKeyDown", false)
    table.insert(secureButtons, btn)
    RefreshSecureButton(btn)
    return btn
end

local function RefreshSecureButtons()
    for _, btn in ipairs(secureButtons) do RefreshSecureButton(btn) end
end






local prompt

local function WantsPrompt()
    local c = ThugUIDB.ControllerMode or {}
    if c.promptGamepadUI == false then return false end
    if (c.override or "auto") ~= "auto" then return false end
    return not ControllerMode:IsGamepadUI()
end

local function HidePrompt()
    if not prompt or not prompt:IsShown() then return end
    if InCombatLockdown and InCombatLockdown() and prompt:IsProtected() then return end
    prompt:Hide()
end

local function BuildPrompt()
    if prompt then return prompt end
    local f = CreateFrame("Frame", "ThugUI_GamepadUIPrompt", UIParent, "BackdropTemplate")
    f:SetSize(380, 112)
    f:SetPoint("TOP", UIParent, "TOP", 0, -160)
    f:SetFrameStrata("DIALOG")
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        f:SetBackdropColor(0, 0, 0, 0.85)
        f:SetBackdropBorderColor(0, 1, 0.8, 0.8)
    end
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 14, -14)
    text:SetPoint("TOPRIGHT", -14, -14)
    text:SetJustifyH("LEFT")
    text:SetText("ThugUI's Controller module is on, but Blizzard's Gamepad UI is off.")
    f.text = text

    local go = ControllerMode:CreateGamepadUIButton(f, 160)
    if go then go:SetPoint("BOTTOMLEFT", 14, 14) end
    f.go = go

    local later = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    later:SetSize(90, 24)
    later:SetText("Not now")
    later:SetPoint("BOTTOMLEFT", 182, 14)
    later:SetScript("OnClick", function() f:Hide() end)

    local never = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    never:SetSize(90, 24)
    never:SetText("Don't ask")
    never:SetPoint("LEFT", later, "RIGHT", 6, 0)
    never:SetScript("OnClick", function()
        ThugUIDB.ControllerMode = ThugUIDB.ControllerMode or {}
        ThugUIDB.ControllerMode.promptGamepadUI = false
        f:Hide()
    end)
    f:Hide()
    prompt = f
    return f
end

function ControllerMode:MaybePrompt()
    if not ThugUI:IsModuleOn("controller") then return end
    if InCombatLockdown and InCombatLockdown() then
        self.promptAfterCombat = true
        return
    end
    self.promptAfterCombat = nil
    if not WantsPrompt() then return end
    local f = BuildPrompt()
    if not f.go then return end
    f.text:SetText("ThugUI's Controller module is on, but Blizzard's Gamepad UI is off.")
    f:Show()
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("CONTROLLERMODE", "gamepad UI off at login: prompt shown")
    end
end



local function OnGamepadUIChanged()
    RefreshSecureButtons()
    if not prompt or not prompt:IsShown() then return end
    if ControllerMode:NeedsReload() then
        prompt.text:SetText("Gamepad UI is on. Reload to switch ThugUI to controller play.")
    elseif ControllerMode:IsGamepadUI() then
        HidePrompt()
    end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, cvar)
    if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
    if event == "PLAYER_LOGIN" then
        ControllerMode:Evaluate()
        
        
        C_Timer.After(2, function() ControllerMode:MaybePrompt() end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        RefreshSecureButtons()
        if ControllerMode.promptAfterCombat then ControllerMode:MaybePrompt() end
    elseif event == "CVAR_UPDATE" and type(cvar) == "string" and cvar:lower() == "inputdeviceinterfacestyle" then
        ControllerMode:Evaluate()
        OnGamepadUIChanged()
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CONTROLLERMODE", "gamepad UI now %s; reload needed=%s",
                tostring(ControllerMode:IsGamepadUI()), tostring(ControllerMode:NeedsReload()))
        end
    end
end)





function ControllerMode:Initialize()
    ThugUI.SafeRegisterEvent(frame, "PLAYER_LOGIN")
    ThugUI.SafeRegisterEvent(frame, "CVAR_UPDATE")
    ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_ENABLED")
end
