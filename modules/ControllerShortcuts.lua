












local ThugUI = _G.ThugUI
local CS = {}
ThugUI.ControllerShortcuts = CS
ThugUI:RegisterModule("ControllerShortcuts", CS)

local FADE_OPACITY = 0.3 
local MAP_ICON = "Interface\\Icons\\INV_Misc_Map02"

local hookedShortcuts = {}


local pendingCombat = nil

function CS:Apply(bar)
    if not bar or not bar.faceBottomButton then return end

    local use = ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("mapShortcut")
    if not use then return end

    if InCombatLockdown() then
        pendingCombat = "apply"
        return
    end

    local btn = bar.faceBottomButton
    local ok, err = pcall(function()
        btn:SetEnabled(true)
        btn:SetAlpha(1)
        btn.SpecialActionIcon:SetTexture(MAP_ICON)
        btn.SpecialActionIcon:Show()
    end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SHORTCUTS", "Apply refused: %s", tostring(err))
    end
end

function CS:Disable(bar)
    if not bar or not bar.faceBottomButton then return end
    if InCombatLockdown() then
        pendingCombat = "disable"
        return
    end

    
    local btn = bar.faceBottomButton
    local ok, err = pcall(function()
        btn:SetEnabled(false)
        btn:SetAlpha(FADE_OPACITY)
        btn.SpecialActionIcon:Hide()
    end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SHORTCUTS", "Disable refused: %s", tostring(err))
    end
end

function CS:Install()
    local bar = ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar()
    if not bar then
        if not CS.missingLogged then
            CS.missingLogged = true
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("SHORTCUTS", "shortcuts bar not found; map shortcut not installed yet")
            end
        end
        return false
    end

    if _G.GamepadShortcutsActionBarMixin and rawget(_G.GamepadShortcutsActionBarMixin, "SetUpFaceBottom") ~= nil then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("SHORTCUTS", "Blizzard now uses the bottom face button; map shortcut not installed")
        end
        return false
    end

    if CS.installed then return true end
    CS.installed = true

    
    hooksecurefunc(bar, "SetUpFaceBottom", function(b) CS:Apply(b) end)

    
    for _, side in ipairs({ bar.Left, bar.Right }) do
        local b = side and side.ActionButton4
        if b and not hookedShortcuts[b] and b.HookScript then
            hookedShortcuts[b] = true
            b:HookScript("PostClick", function(self, _, down)
                if not down or self ~= bar.faceBottomButton then return end
                local use = ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("mapShortcut")
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("SHORTCUTS", "shortcut map button pressed; %s",
                        use and "toggling world map" or "map shortcut not in use")
                end
                if use and _G.ToggleWorldMap then _G.ToggleWorldMap() end
            end)
        end
    end

    CS:Apply(bar)
    return true
end

function CS:Initialize()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event)
        if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
        if event == "PLAYER_ENTERING_WORLD" then
            CS:Install()
        elseif event == "PLAYER_REGEN_ENABLED" then
            local todo = pendingCombat
            pendingCombat = nil
            local bar = ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar()
            if todo == "apply" then
                CS:Apply(bar)
            elseif todo == "disable" then
                CS:Disable(bar)
            end
        end
    end)
    ThugUI.SafeRegisterEvent(frame, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_ENABLED")

    if C_Timer and C_Timer.After then
        C_Timer.After(3, function() CS:Install() end)
    end

    if ThugUI.ControllerMode then
        
        
        local function Refresh()
            if not CS.installed then return end
            local bar = ThugUI.ControllerMode:GetShortcutsBar()
            if ThugUI.ControllerMode:Uses("mapShortcut") then
                CS:Apply(bar)
            else
                CS:Disable(bar)
            end
        end
        ThugUI.ControllerMode:RegisterFeatureCallback("mapShortcut", Refresh)
        ThugUI.ControllerMode:RegisterCallback(Refresh)
    end
end
