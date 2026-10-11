

























local ThugUI = _G.ThugUI
local CS = {}
ThugUI.ControllerShortcuts = CS
ThugUI:RegisterModule("ControllerShortcuts", CS)

local FADE_OPACITY = 0.3 
local MAP_ICON = "Interface\\Icons\\INV_Misc_Map02"
local MAP_BINDING = "TOGGLEWORLDMAP"

local function Log(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("SHORTCUTS", fmt, ...) end
end

local function Combat() return InCombatLockdown and InCombatLockdown() or false end

local function Uses()
    return ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("mapShortcut") or false
end

local function Key() return _G.GAMEPAD_FACE_BOTTOM or "PAD1" end


CS.owner = CreateFrame("Frame", "ThugUI_MapShortcutOwner")
CS.bound = false


function CS:Bind(on)
    if on then
        if CS.bound or Combat() then return end
        local ok, err = pcall(SetOverrideBinding, CS.owner, true, Key(), MAP_BINDING)
        if not ok then Log("bind refused: %s", tostring(err)) return end
        CS.bound = true
        local okA, action = pcall(GetBindingAction, Key(), true)
        Log("map bound; %s -> %s", Key(), okA and tostring(action) or "?")
    else
        if not CS.bound then return end
        if Combat() then
            
            
            CS.clearPending = true
            return
        end
        pcall(ClearOverrideBindings, CS.owner)
        CS.bound = false
        CS.clearPending = false
    end
end



local function BlizzardUses(btn)
    return btn and btn.IsEnabled and btn:IsEnabled() and true or false
end


function CS:Apply(bar)
    local btn = bar and bar.faceBottomButton
    if not btn or not Uses() or BlizzardUses(btn) then return end
    pcall(function()
        btn:SetAlpha(1)
        btn.SpecialActionIcon:SetTexture(MAP_ICON)
        btn.SpecialActionIcon:Show()
    end)
end


function CS:Disable(bar)
    self:Bind(false)
    local btn = bar and bar.faceBottomButton
    if not btn or BlizzardUses(btn) then return end
    pcall(function()
        btn:SetAlpha(FADE_OPACITY)
        btn.SpecialActionIcon:Hide()
    end)
end

function CS:OnBarShown(bar)
    if not Uses() or Combat() then return end
    if BlizzardUses(bar and bar.faceBottomButton) then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("shortcuts-blizzard-uses", "SHORTCUTS",
                "Blizzard's own pass enabled the bottom face button; map shortcut left off")
        end
        return
    end
    self:Apply(bar)
    self:Bind(true)
end

function CS:OnBarHidden()
    self:Bind(false)
end

function CS:Install()
    local bar = ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar()
    if not bar then
        if not CS.missingLogged then
            CS.missingLogged = true
            Log("shortcuts bar not found; map shortcut not installed yet")
        end
        return false
    end
    if CS.installed then return true end
    CS.installed = true

    
    if bar.SetUpFaceBottom then
        hooksecurefunc(bar, "SetUpFaceBottom", function(b) CS:Apply(b) end)
    end
    bar:HookScript("OnShow", function(b) CS:OnBarShown(b) end)
    bar:HookScript("OnHide", function() CS:OnBarHidden() end)
    CS:Apply(bar)
    if bar:IsShown() then CS:OnBarShown(bar) end
    return true
end

function CS:Initialize()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event)
        if not ThugUI:IsModuleOn("controller") then
            CS:Bind(false)
            self:UnregisterAllEvents()
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            CS:Install()
        elseif event == "PLAYER_REGEN_DISABLED" then
            
            CS:Bind(false)
        elseif event == "PLAYER_REGEN_ENABLED" then
            if CS.clearPending then CS:Bind(false) end
        end
    end)
    ThugUI.SafeRegisterEvent(frame, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_DISABLED")
    ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_ENABLED")

    if C_Timer and C_Timer.After then
        C_Timer.After(3, function() CS:Install() end)
    end

    if ThugUI.ControllerMode then
        
        
        local function Refresh()
            if not CS.installed then return end
            local bar = ThugUI.ControllerMode:GetShortcutsBar()
            if Uses() then
                CS:Apply(bar)
                if bar and bar:IsShown() then CS:OnBarShown(bar) end
            else
                CS:Disable(bar)
            end
        end
        ThugUI.ControllerMode:RegisterFeatureCallback("mapShortcut", Refresh)
        ThugUI.ControllerMode:RegisterCallback(Refresh)
    end
end
