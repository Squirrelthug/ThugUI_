


























local ThugUI = _G.ThugUI
local CO = {}
ThugUI.ControllerObjectives = CO
ThugUI:RegisterModule("ControllerObjectives", CO)

ThugUI.defaults.ControllerObjectives = {
    enabled = true,   
}

local function Log(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("OBJECTIVES", fmt, ...) end
end

local function GetTracker()
    return _G.ObjectiveTrackerFrame
end

local function Taking()
    local CM = ThugUI.ControllerMode
    return CM and CM:Uses("objectives") or false
end



local pending = {}
local function OutOfCombat(fn)
    if InCombatLockdown and InCombatLockdown() then
        table.insert(pending, fn)
    else
        fn()
    end
end




local shield
local ghostActive = false
local alphaBeforeGhost
local revealed = false

local function GetShield(tracker)
    if not shield then
        shield = CreateFrame("Frame", "ThugUI_TrackerShield", UIParent)
        shield:EnableMouse(true)
        shield:Hide()
    end
    shield:ClearAllPoints()
    shield:SetAllPoints(tracker)
    if tracker.GetFrameStrata then shield:SetFrameStrata(tracker:GetFrameStrata()) end
    if tracker.GetFrameLevel then shield:SetFrameLevel(tracker:GetFrameLevel() + 50) end
    return shield
end


local function ApplyGhost(ghost)
    local tracker = GetTracker()
    if not tracker then return end
    if tracker:GetParent() ~= UIParent then
        
        
        
        OutOfCombat(function()
            if Taking() and tracker:GetParent() ~= UIParent then
                tracker:SetParent(UIParent)
            end
        end)
    end
    if ghost then
        if not ghostActive then
            alphaBeforeGhost = tracker.GetAlpha and tracker:GetAlpha() or 1
            if alphaBeforeGhost == 0 then alphaBeforeGhost = 1 end
            ghostActive = true
        end
        tracker:SetAlpha(0)
        GetShield(tracker):Show()
    else
        tracker:SetAlpha(ghostActive and alphaBeforeGhost or 1)
        if shield then shield:Hide() end
    end
end
CO.ApplyGhost = ApplyGhost


local function ClearGhost()
    local tracker = GetTracker()
    if ghostActive and tracker then tracker:SetAlpha(alphaBeforeGhost or 1) end
    ghostActive = false
    alphaBeforeGhost = nil
    revealed = false
    if shield then shield:Hide() end
end




local function TrackerHasFocus(tracker)
    local GM = _G.GamepadMode
    local fcm = GM and GM.FrameControlsManager
    if not fcm or not fcm.isUIFocused then return false end
    local ok, active = pcall(fcm.GetActiveFrame, fcm)
    return ok and active == tracker
end

function CO:OnGamepadFocusChanged()
    local tracker = GetTracker()
    if not tracker or not Taking() then
        revealed = false
        return
    end
    local want = TrackerHasFocus(tracker)
    if want == revealed then return end
    revealed = want
    ApplyGhost(not want)
    Log(want and "tracker shown: gamepad focus is on it" or "tracker transparent again: focus left it")
end










local hooked = {}

local function PressState(tracker)
    return ("shown=%s visible=%s alpha=%s parent=%s"):format(
        tostring(tracker:IsShown()), tostring(tracker.IsVisible and tracker:IsVisible()),
        tostring(tracker.GetAlpha and tracker:GetAlpha()),
        tracker:GetParent() == UIParent and "UIParent" or "other")
end

function CO:HookShortcuts()
    local CM = ThugUI.ControllerMode
    local bar = CM and CM.GetShortcutsBar and CM:GetShortcutsBar()
    if not bar then return false end
    for _, side in ipairs({ bar.Left, bar.Right }) do
        local b = side and side.ActionButton2
        if b and not hooked[b] and b.HookScript then
            local ok1 = pcall(b.HookScript, b, "PreClick", function(self, _, down)
                if not down or self ~= bar.dpadTopButton or not Taking() then return end
                local tracker = GetTracker()
                if not tracker then return end
                if not revealed then ApplyGhost(true) end
                Log("shortcut objectives pressed; tracker %s", PressState(tracker))
            end)
            local ok2 = pcall(b.HookScript, b, "PostClick", function(self, _, down)
                if not down or self ~= bar.dpadTopButton or not Taking() then return end
                local tracker = GetTracker()
                if tracker then
                    Log("after Blizzard's handler: focus %s",
                        TrackerHasFocus(tracker) and "is on the tracker" or "is NOT on the tracker")
                end
            end)
            if ok1 and ok2 then
                hooked[b] = true
                Log("shortcuts D-pad up hook installed on %s", side == bar.Left and "Left" or "Right")
            end
        end
    end
    return true
end







local function Reassert()
    if not Taking() then return end
    ApplyGhost(not revealed)
end

local LADDER = { 0.1, 0.5, 1, 2, 5 }
local function ScheduleReassert()
    Reassert()
    if not (C_Timer and C_Timer.After) then return end
    for _, delay in ipairs(LADDER) do C_Timer.After(delay, Reassert) end
end
CO.ScheduleReassert = ScheduleReassert




local taken = nil
local function ApplyTakeover()
    local take = Taking()
    if take ~= taken then
        Log("tracker takeover %s", take and "starts" or "ends")
        taken = take
    end
    revealed = false
    if take then
        ApplyGhost(true)
        CO:HookShortcuts()
    else
        ClearGhost()
    end
end
CO.ApplyTakeover = ApplyTakeover





local function Migrate()
    local acorns = ThugUIDB.Acorns
    local old = acorns and acorns.objectives and acorns.objectives.controllerHide
    if old == nil then return end
    ThugUIDB.ControllerObjectives = ThugUIDB.ControllerObjectives or {}
    ThugUIDB.ControllerObjectives.enabled = old ~= false
    acorns.objectives.controllerHide = nil
    Log("moved the tracker switch from the objectives acorn: enabled=%s",
        tostring(ThugUIDB.ControllerObjectives.enabled))
end

local driver = CreateFrame("Frame")
driver:SetScript("OnEvent", function(self, event)
    if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
    if event == "PLAYER_REGEN_ENABLED" then
        local queued = pending
        pending = {}
        for _, fn in ipairs(queued) do fn() end
        ScheduleReassert()
    elseif event == "PLAYER_ENTERING_WORLD" then
        
        if Taking() then CO:HookShortcuts() end
        ScheduleReassert()
    elseif event == "EDIT_MODE_LAYOUTS_UPDATED" then
        ScheduleReassert()
    end
end)

function CO:Initialize()
    ThugUIDB.ControllerObjectives = ThugUIDB.ControllerObjectives or { enabled = true }
    Migrate()

    ThugUI.SafeRegisterEvent(driver, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(driver, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(driver, "EDIT_MODE_LAYOUTS_UPDATED")

    local CM = ThugUI.ControllerMode
    if CM then
        CM:RegisterCallback(ApplyTakeover)
        CM:RegisterFeatureCallback("objectives", ApplyTakeover)
    end

    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("Gamepad.RefreshFrameFocus", function()
            CO:OnGamepadFocusChanged()
        end, CO)
        
        local function Deferred()
            if C_Timer and C_Timer.After then C_Timer.After(0, ScheduleReassert) else ScheduleReassert() end
        end
        EventRegistry:RegisterCallback("EditMode.Exit", Deferred, CO)
        EventRegistry:RegisterCallback("UI.TopLevelParentShown", Deferred, CO)
    end
end
