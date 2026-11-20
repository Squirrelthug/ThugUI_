




































































local ThugUI = _G.ThugUI
local CS = {}
ThugUI.ControllerShortcuts = CS
ThugUI:RegisterModule("ControllerShortcuts", CS)

local FADE_OPACITY = 0.3 
local MAP_ICON = "Interface\\Icons\\INV_Misc_Map02"
CS.MAP_ICON = MAP_ICON 




local MAP_BINDING = "TOGGLEWORLDMAP"

local function Log(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("SHORTCUTS", fmt, ...) end
end

local function Combat() return InCombatLockdown and InCombatLockdown() or false end



local SWAP_CVARS = { gamepadswaptargetmodifiers = true, gamepadswapfriendlytargetactions = true,
                     gamepadswaphostiletargetactions = true }


local function Uses()
    return ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("shortcutCross") or false
end



local function Command() return ThugUI.PadLayout and ThugUI.PadLayout:Command("cross") end


local function RunsCode()
    local PL = ThugUI.PadLayout
    local CM = ThugUI.ControllerMode
    return PL ~= nil and CM ~= nil and CM:IsActive() and PL:CrossRun() ~= nil
end
local function Shows() return Uses() or RunsCode() end

local function Key() return _G.GAMEPAD_FACE_BOTTOM or "PAD1" end



CS.owner = CreateFrame("Frame", "ThugUI_MapShortcutOwner")
CS.plainOwner = CS.owner
CS.bound = false
CS.secureOK = false




CS.SNIPPET_LOOP = [[
local n = self:GetAttribute("n") or 0
for i = 1, n do
    local key = self:GetAttribute("key" .. i)
    local cmd = self:GetAttribute("cmd" .. i)
    if key and cmd then self:SetBinding(true, key, cmd) end
end
]]
CS.SNIPPET_SHOW = [[
if self:GetAttribute("mapOn") then
    self:SetBinding(true, self:GetAttribute("mapKey"), self:GetAttribute("mapAction"))
    self:SetAttribute("last", "shown")
    self:SetAttribute("seq", (self:GetAttribute("seq") or 0) + 1)
end
]] .. CS.SNIPPET_LOOP
CS.SNIPPET_HIDE = [[
self:ClearBindings()
self:SetAttribute("last", "hidden")
self:SetAttribute("seq", (self:GetAttribute("seq") or 0) + 1)
]]


CS.SNIPPET_PROBE = [[
self:SetBinding(true, self:GetAttribute("mapKey"), self:GetAttribute("mapAction"))
]] .. CS.SNIPPET_LOOP .. [[
self:ClearBindings()
self:SetAttribute("probe", "ok")
]]



function CS:Bind(on)
    local cmd = on and Command() or nil
    if on and not cmd then on = false end
    if on then
        
        
        
        if (CS.bound and not CS.secureOK and CS.boundCmd == cmd) or Combat() then return end
        local ok, err = pcall(SetOverrideBinding, CS.owner, true, Key(), cmd)
        if not ok then Log("bind refused: %s", tostring(err)) return end
        CS.bound, CS.boundCmd = true, cmd
        local okA, action = pcall(GetBindingAction, Key(), true)
        Log("cross bound; %s -> %s", Key(), okA and tostring(action) or "?")
    else
        if not CS.bound and not CS.secureOK then return end
        if Combat() then
            
            
            
            if not CS.secureOK then CS.clearPending = true end
            return
        end
        pcall(ClearOverrideBindings, CS.owner)
        CS.bound, CS.boundCmd = false, nil
        CS.clearPending = false
    end
end



local function BlizzardUses(btn)
    return btn and btn.IsEnabled and btn:IsEnabled() and true or false
end




function CS:BlizzardOwnsCross()
    local bar = ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar()
    return BlizzardUses(bar and bar.faceBottomButton)
end




function CS:SyncSecure(bar)
    if Combat() then return end
    
    
    CS:SyncBars()
    if not CS.secureOK then return end
    bar = bar or (ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar())
    local btn = bar and bar.faceBottomButton
    local on = Uses() and not BlizzardUses(btn)
    local cmd = Command()
    if cmd then pcall(CS.secure.SetAttribute, CS.secure, "mapAction", cmd) end
    pcall(CS.secure.SetAttribute, CS.secure, "mapOn", on and true or false)
    pcall(CS.secure.SetAttribute, CS.secure, "mapKey", Key())
end



function CS:BuildSecure(bar)
    if CS.secure or CS.secureTried or Combat() or not bar then return CS.secureOK end
    CS.secureTried = true
    if not (_G.SecureHandlerExecute and _G.CreateFrame) then
        Log("secure path unavailable (no SecureHandlerExecute); map shortcut works out of combat only")
        return false
    end
    local ok, err = pcall(function()
        local h = CreateFrame("Frame", "ThugUI_MapShortcutSecure", bar, "SecureHandlerShowHideTemplate")
        h:SetAttribute("mapKey", Key())
        h:SetAttribute("mapAction", MAP_BINDING)
        h:SetAttribute("mapOn", false)
        h:SetAttribute("_onshow", CS.SNIPPET_SHOW)
        h:SetAttribute("_onhide", CS.SNIPPET_HIDE)
        local logged = 0
        h:HookScript("OnAttributeChanged", function(self, name)
            if name == "seq" and logged < 20 then
                logged = logged + 1
                Log("secure %s ran (combat %s)", tostring(self:GetAttribute("last")), tostring(Combat()))
            end
        end)
        
        
        h:SetAttribute("n", 1)
        h:SetAttribute("key1", Key())
        h:SetAttribute("cmd1", MAP_BINDING)
        SecureHandlerExecute(h, CS.SNIPPET_PROBE)
        h:SetAttribute("n", 0)
        h:SetAttribute("key1", nil)
        h:SetAttribute("cmd1", nil)
        if h:GetAttribute("probe") ~= "ok" then error("probe snippet did not run") end
        h:HookScript("OnShow", function() CS:ArmedShown("shortcuts") end)
        h:HookScript("OnHide", function() CS:ArmedHidden("shortcuts") end)
        CS.secure = h
    end)
    if not ok then
        Log("secure path failed, map shortcut works out of combat only: %s", tostring(err))
        return false
    end
    pcall(ClearOverrideBindings, CS.plainOwner)
    CS.owner = CS.secure
    CS.secureOK = true
    CS.bound = false
    Log("secure path active: map shortcut also works in combat")
    return true
end





local BAR_NAMES = { "shortcuts", "friendly", "hostile" }
local BAR_SLOTS = { "l1right", "r1right", "l1r1top", "l1r1right", "l1r1left", "l1r1up", "l1r1down" }

local PROBE_KEY = "PADDRIGHT"




CS.bars = {}
local function BarState(name)
    local st = CS.bars[name]
    if not st then
        st = { live = {}, keys = {} }
        CS.bars[name] = st
    end
    return st
end



local function SecureOf(name)
    if name == "shortcuts" then return CS.secure, CS.secureOK == true end
    local st = BarState(name)
    return st.secure, st.ok == true
end

local function PLog(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("PADLAYOUT", fmt, ...) end
end




local function Wanted(name)
    local out = {}
    local PL, CM = ThugUI.PadLayout, ThugUI.ControllerMode
    if not (PL and PL.BarCommand and CM and CM:IsActive()) then return out end
    for _, id in ipairs(BAR_SLOTS) do
        if PL:BarOf(id) == name and PL:HasSlot(id) then
            local key, cmd = PL:KeyFor(id), PL:BarCommand(id)
            if key and cmd then out[#out + 1] = { key = key, cmd = cmd, slot = id } end
        end
    end
    return out
end



function CS:SyncBars()
    if Combat() then return end
    for _, name in ipairs(BAR_NAMES) do
        local st = BarState(name)
        local list = Wanted(name)
        st.keys = list
        local sf, ok = SecureOf(name)
        if sf and ok then
            local okSet, err = pcall(function()
                for i = 1, math.max(#list, st.written or 0) do
                    sf:SetAttribute("key" .. i, list[i] and list[i].key or nil)
                    sf:SetAttribute("cmd" .. i, list[i] and list[i].cmd or nil)
                end
                sf:SetAttribute("n", #list)
                st.written = #list
            end)
            if not okSet then PLog("bar %s attributes failed: %s", name, tostring(err)) end
        end
    end
end



local function LogShown(name)
    local st = BarState(name)
    local list = {}
    for _, e in ipairs(st.keys) do list[#list + 1] = e.key end
    if name == "shortcuts" and Uses() and Command() then list[#list + 1] = Key() end
    for _, key in ipairs(list) do
        local ok, action = pcall(GetBindingAction, key, true)
        PLog("bar %s shown: %s -> %s", name, key, ok and tostring(action) or "?")
    end
end


local function OwnerOf(name)
    local sf, ok = SecureOf(name)
    if sf and ok then return sf end
    local st = BarState(name)
    if not st.plain then st.plain = CreateFrame("Frame", "ThugUI_BarShortcutOwner_" .. name) end
    return st.plain
end




function CS:BindBar(name)
    if Combat() then return end
    local st = BarState(name)
    local owner = OwnerOf(name)
    local list = Wanted(name)
    st.keys = list
    local want = {}
    for _, e in ipairs(list) do want[e.key] = true end
    for key in pairs(st.live) do
        if not want[key] then
            pcall(SetOverrideBinding, owner, true, key, nil)
            st.live[key] = nil
        end
    end
    for _, e in ipairs(list) do
        local ok, err = pcall(SetOverrideBinding, owner, true, e.key, e.cmd)
        if ok then
            st.live[e.key] = true
        else
            PLog("bar %s bind refused for %s: %s", name, e.key, tostring(err))
        end
    end
end



function CS:UnbindBar(name)
    local st = BarState(name)
    if next(st.live) == nil then return end
    local _, ok = SecureOf(name)
    if Combat() then
        if not ok then st.clearPending = true end
        return
    end
    local owner = OwnerOf(name)
    for key in pairs(st.live) do pcall(SetOverrideBinding, owner, true, key, nil) end
    st.live = {}
    st.clearPending = false
end



function CS:ExtrasShown(name)
    local _, ok = SecureOf(name)
    if ok or Combat() then return end
    CS:BindBar(name)
    LogShown(name)
end

function CS:ExtrasHidden(name)
    local _, ok = SecureOf(name)
    if ok then return end
    CS:UnbindBar(name)
end



function CS:ArmedShown(name)
    local st = BarState(name)
    st.live = {}
    for _, e in ipairs(st.keys) do st.live[e.key] = true end
    LogShown(name)
end

function CS:ArmedHidden(name)
    BarState(name).live = {}
end



function CS:RefreshBars()
    if Combat() then return end
    for _, name in ipairs(BAR_NAMES) do
        local st = BarState(name)
        local bar = st.frame
        if bar and bar.IsShown and bar:IsShown() then
            CS:BindBar(name)
        else
            CS:UnbindBar(name)
        end
    end
end


function CS:DropFallbackBars()
    for _, name in ipairs(BAR_NAMES) do
        local _, ok = SecureOf(name)
        if not ok then CS:UnbindBar(name) end
    end
end





function CS:BuildBarSecure(name, bar)
    local st = BarState(name)
    if st.secure or st.tried or Combat() or not bar then return st.ok == true end
    st.tried = true
    if not (_G.SecureHandlerExecute and _G.CreateFrame) then
        PLog("bar %s: secure path unavailable (no SecureHandlerExecute); works out of combat only", name)
        return false
    end
    local ok, err = pcall(function()
        local h = CreateFrame("Frame", "ThugUI_BarSecure_" .. name, bar, "SecureHandlerShowHideTemplate")
        h:SetAttribute("mapKey", PROBE_KEY)
        h:SetAttribute("mapAction", MAP_BINDING)
        h:SetAttribute("mapOn", false)
        h:SetAttribute("n", 1)
        h:SetAttribute("key1", PROBE_KEY)
        h:SetAttribute("cmd1", MAP_BINDING)
        SecureHandlerExecute(h, CS.SNIPPET_PROBE)
        if h:GetAttribute("probe") ~= "ok" then error("probe snippet did not run") end
        h:SetAttribute("n", 0)
        h:SetAttribute("key1", nil)
        h:SetAttribute("cmd1", nil)
        h:SetAttribute("_onshow", CS.SNIPPET_SHOW)
        h:SetAttribute("_onhide", CS.SNIPPET_HIDE)
        h:HookScript("OnShow", function() CS:ArmedShown(name) end)
        h:HookScript("OnHide", function() CS:ArmedHidden(name) end)
        st.secure = h
    end)
    if not ok then
        PLog("bar %s: secure path failed, works out of combat only: %s", name, tostring(err))
        return false
    end
    st.ok = true
    return true
end



function CS:InstallBars()
    local PL = ThugUI.PadLayout
    if not (PL and PL.BarFrame) then return end
    for _, name in ipairs({ "friendly", "hostile" }) do
        local st = BarState(name)
        local bar = PL:BarFrame(name)
        if bar and st.frame ~= bar then
            st.frame = bar
            CS:BuildBarSecure(name, bar)
            local okHook, errHook = pcall(function()
                bar:HookScript("OnShow", function() CS:ExtrasShown(name) end)
                bar:HookScript("OnHide", function() CS:ExtrasHidden(name) end)
            end)
            if not okHook then PLog("bar %s hooks failed: %s", name, tostring(errHook)) end
            if bar.IsShown and bar:IsShown() then CS:ExtrasShown(name) end
        elseif not bar and not st.missingLogged then
            st.missingLogged = true
            PLog("bar %s not found; its slots are not installed", name)
        end
    end
end


function CS:BarsArmed()
    local n = 0
    for _, name in ipairs(BAR_NAMES) do
        local _, ok = SecureOf(name)
        if ok then n = n + 1 end
    end
    return n
end




function CS:Apply(bar)
    CS:SyncSecure(bar)
    local btn = bar and bar.faceBottomButton
    if not btn or not Shows() or BlizzardUses(btn) then return end
    
    
    if Combat() and not CS.secureOK and not RunsCode() then return end
    local PL = ThugUI.PadLayout
    local icon = PL and PL:Icon("cross")
    if not icon then
        CS:HideIcon(bar)
        return
    end
    pcall(function()
        btn:SetAlpha(1)
        btn.SpecialActionIcon:SetTexture(icon)
        btn.SpecialActionIcon:Show()
    end)
end


function CS:HideIcon(bar)
    local btn = bar and bar.faceBottomButton
    if not btn or BlizzardUses(btn) then return end
    pcall(function()
        btn:SetAlpha(FADE_OPACITY)
        btn.SpecialActionIcon:Hide()
    end)
end

function CS:Disable(bar)
    CS:SyncSecure(bar)
    self:Bind(false)
    self:HideIcon(bar)
end

function CS:OnBarShown(bar)
    self:CrossShown(bar)
    self:ExtrasShown("shortcuts")
end

function CS:CrossShown(bar)
    if not Shows() then return end
    if Combat() then
        
        
        
        if (CS.secureOK or RunsCode()) and not BlizzardUses(bar and bar.faceBottomButton) then
            self:Apply(bar)
        end
        return
    end
    if BlizzardUses(bar and bar.faceBottomButton) then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("shortcuts-blizzard-uses", "SHORTCUTS",
                "cross: Blizzard uses the button; the Cross choice is left off (Blizzard's own pass enabled it)")
        end
        return
    end
    self:Apply(bar)
    self:Bind(true)
end

function CS:OnBarHidden()
    self:Bind(false)
    self:ExtrasHidden("shortcuts")
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

    if not CS.secureTried then CS:BuildSecure(bar) end
    
    BarState("shortcuts").frame = bar
    CS:InstallBars()
    PLog("bars armed %d/3", CS:BarsArmed())
    CS:SyncBars()

    
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
    frame:SetScript("OnEvent", function(self, event, ...)
        if not ThugUI:IsModuleOn("controller") then
            CS:Bind(false)
            self:UnregisterAllEvents()
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            CS:Install()
        elseif event == "CVAR_UPDATE" then
            
            
            local cvar = ...
            if type(cvar) == "string" and SWAP_CVARS[cvar:lower()] then
                local PL = ThugUI.PadLayout
                if PL and PL.Notify then PL:Notify() else CS:SyncSecure() end
                CS:RefreshBars()
            end
        elseif event == "PLAYER_REGEN_DISABLED" then
            
            
            CS:DropFallbackBars()
            
            if not CS.secureOK then
                CS:Bind(false)
                
                if not RunsCode() then
                    CS:HideIcon(ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar())
                end
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            CS:SyncSecure()
            local bar = ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar()
            if bar and bar:IsShown() and Shows() then
                
                
                CS:OnBarShown(bar)
            end
            if CS.clearPending then CS:Bind(false) end
            
            CS:RefreshBars()
        end
    end)
    ThugUI.SafeRegisterEvent(frame, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_DISABLED")
    ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(frame, "CVAR_UPDATE")

    if C_Timer and C_Timer.After then
        C_Timer.After(3, function() CS:Install() end)
    end

    if ThugUI.ControllerMode then
        
        
        local function Refresh()
            if not CS.installed then return end
            local bar = ThugUI.ControllerMode:GetShortcutsBar()
            if Shows() then
                CS:Apply(bar)
                if bar and bar:IsShown() then CS:OnBarShown(bar) end
            else
                CS:Disable(bar)
            end
            CS:RefreshBars()
        end
        ThugUI.ControllerMode:RegisterFeatureCallback("shortcutCross", Refresh)
        ThugUI.ControllerMode:RegisterCallback(Refresh)
    end

    
    
    if ThugUI.PadLayout and ThugUI.PadLayout.RegisterCallback and not CS.padCallback then
        CS.padCallback = true
        ThugUI.PadLayout:RegisterCallback(function()
            CS:SyncSecure()
            CS:RefreshBars()
        end)
    end
end
