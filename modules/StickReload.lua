





























local ThugUI = _G.ThugUI
local StickReload = {}
ThugUI.StickReload = StickReload





local RELOAD_BUTTONS = {
    PADSOCIAL = "Select",
    PADBACK = "Select",
}


local TAP_WINDOW = 0.4


local BLOCK_WINDOW = 0.5

local NOTICE_SECONDS = 6

local function Log(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("RELOAD", fmt, ...) end
end

local listener, cue
local tapAt          
local tapButton      
local noticeUntil    
local reloadAt       

function StickReload:IsEnabled()
    local c = ThugUIDB and ThugUIDB.ControllerMode
    
    
    return not (c and c.stickReload == false)
end

function StickReload:IsWanted()
    local CM = ThugUI.ControllerMode
    return CM ~= nil and CM:IsActive() and self:IsEnabled()
end

function StickReload:IsListening() return listener ~= nil and listener.listening == true end
function StickReload:GetListener() return listener end
function StickReload:GetCue() return cue end





local function HideCue()
    if cue then
        cue.text:SetText("")
        cue:Hide()
    end
end

local function CueUpdate()
    local now = GetTime()
    if tapAt then
        if now - tapAt <= TAP_WINDOW then
            cue.text:SetText("Tap again to reload")
            return
        end
        
        tapAt, tapButton = nil, nil
    end
    if noticeUntil and now < noticeUntil then
        cue.text:SetText("Type /reload")
    else
        noticeUntil = nil
        HideCue()
    end
end

local function BuildCue()
    if cue then return cue end
    cue = CreateFrame("Frame", "ThugUI_StickReloadCue", UIParent)
    cue:SetSize(300, 30)
    cue:SetPoint("TOP", UIParent, "TOP", 0, -120)
    cue:SetFrameStrata("TOOLTIP")
    cue.text = cue:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cue.text:SetPoint("CENTER")
    cue.text:SetText("")
    
    
    cue:SetScript("OnUpdate", CueUpdate)
    cue:Hide()
    return cue
end

local function ShowNotice()
    BuildCue()
    noticeUntil = GetTime() + NOTICE_SECONDS
    cue.text:SetText("Type /reload")
    cue:Show()
end





local function DoReload(button)
    Log("%s double-tapped, reloading", RELOAD_BUTTONS[button])
    reloadAt = GetTime()
    local ok, err = pcall(ReloadUI)
    if not ok then
        reloadAt = nil
        Log("ReloadUI refused: %s", tostring(err))
        ShowNotice()
    end
end



local function OnDown(_, button)
    if RELOAD_BUTTONS[button] then
        Log("down %s", button)
        local now = GetTime()
        local waiting = tapAt and now - tapAt <= TAP_WINDOW
        if waiting and button == tapButton then
            
            tapAt, tapButton = nil, nil
            HideCue()
            DoReload(button)
        elseif waiting then
            
            tapAt, tapButton = nil, nil
            HideCue()
        else
            
            
            tapAt, tapButton = now, button
            noticeUntil = nil
            BuildCue().text:SetText("Tap again to reload")
            cue:Show()
        end
    elseif tapAt then
        
        tapAt, tapButton = nil, nil
        HideCue()
    end
end








local function Start()
    if listener and listener.listening then return true end
    if InCombatLockdown() then return false end
    if not listener then
        listener = CreateFrame("Frame", "ThugUI_StickReloadListener", UIParent)
        listener:SetSize(1, 1)
        listener:SetPoint("TOPLEFT")
        listener:SetScript("OnGamePadButtonDown", OnDown)
    end
    listener:Show()
    local ok, err = pcall(listener.SetPropagateKeyboardInput, listener, true)
    if not ok then
        Log("listener: SetPropagateKeyboardInput refused: %s", tostring(err))
        return false
    end
    if not listener.EnableGamePadButton then
        Log("listener: no EnableGamePadButton on this client")
        return false
    end
    ok, err = pcall(listener.EnableGamePadButton, listener, true)
    if not ok then
        Log("listener: EnableGamePadButton refused: %s", tostring(err))
        return false
    end
    listener.listening = true
    Log("listener on")
    return true
end

local function Stop()
    if not (listener and listener.listening) then return end
    if InCombatLockdown() then return end
    pcall(listener.EnableGamePadButton, listener, false)
    listener.listening = false
    tapAt, tapButton = nil, nil
    HideCue()
    Log("listener off")
end



function StickReload:Refresh()
    if InCombatLockdown() then return end
    if self:IsWanted() then Start() else Stop() end
end





local events = CreateFrame("Frame", "ThugUI_StickReloadEvents")
events:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        if addonName == "ThugUI" and reloadAt and GetTime() - reloadAt <= BLOCK_WINDOW then
            reloadAt = nil
            Log("ReloadUI blocked (%s)", event)
            ShowNotice()
        end
    else
        
        StickReload:Refresh()
    end
end)
ThugUI.SafeRegisterEvent(events, "PLAYER_LOGIN")
ThugUI.SafeRegisterEvent(events, "PLAYER_REGEN_ENABLED")
ThugUI.SafeRegisterEvent(events, "ADDON_ACTION_BLOCKED")
ThugUI.SafeRegisterEvent(events, "ADDON_ACTION_FORBIDDEN")

if ThugUI.ControllerMode then
    ThugUI.ControllerMode:RegisterCallback(function() StickReload:Refresh() end)
end
