


























ThugUI = ThugUI or {}

local D = {}
ThugUI.Diagnostics = D







local MAX_EVENTS = 300

local function Store()
    ThugUI_DebugLog = ThugUI_DebugLog or {}
    ThugUI_DebugLog.events = ThugUI_DebugLog.events or {}
    return ThugUI_DebugLog
end



local function Stamp(format)
    if type(date) ~= "function" then return "?" end
    local ok, value = pcall(date, format)
    return ok and value or "?"
end

local function Now()
    return Stamp("%H:%M:%S")
end




function D:Log(category, message, ...)
    local ok, text = pcall(string.format, message, ...)
    if not ok then text = tostring(message) end

    local store = Store()
    table.insert(store.events, ("[%s] %s: %s"):format(Now(), category, text))

    
    
    while #store.events > MAX_EVENTS do
        table.remove(store.events, 1)
    end
end









local function CaptureProfiles()
    local CV = ThugUI.CooldownViewer
    local Data = CV and CV.Data
    if not Data then return nil end

    local out = {}
    local specID = Data.GetActiveSpecID()
    
    
    
    
    
    if not specID or specID == 0 then return nil end

    local profile = Data.GetProfile(specID)
    local icons = {}

    for _, placement in ipairs(Data.GetPlacements(profile)) do
        
        
        
        
        local info = placement.spellID and C_Spell and C_Spell.GetSpellInfo(placement.spellID)
        local cooldownInfo = Data.GetCooldownInfoForSpell(placement.spellID)
        local linked = cooldownInfo and cooldownInfo.linkedSpellIDs or {}

        table.insert(icons, ("%s  %-28s id=%-9s mode=%-9s linked=%d%s")
            :format(placement.key,
                    (info and info.name) or (placement.categoryID and ("category " .. placement.categoryID)) or "?",
                    tostring(placement.spellID or placement.categoryID),
                    placement.mode,
                    #linked,
                    cooldownInfo and ("  cat=" .. tostring(cooldownInfo.category)) or "  (no entry)"))
    end

    out[specID] = {
        spec = Data.GetSpecName(specID),
        enabled = profile.enabled,
        onlyInCombat = profile.onlyInCombat,
        followCursor = profile.followCursor,
        locked = profile.locked,
        collapse = profile.collapse,
        collapseDirection = profile.collapseDirection,
        anchor = ("col %d, row %d"):format(profile.anchorCol or 0, profile.anchorRow or 0),
        showing = CV.container and CV.container:IsShown() or false,
        icons = icons,
    }
    return out
end













function D:CaptureState()
    local store = Store()
    local _, class = UnitClass("player")

    store.version = ThugUI.version
    store.interface = select(4, GetBuildInfo())
    store.lastUpdated = Stamp("%Y-%m-%d %H:%M:%S")

    local profiles = CaptureProfiles()

    store.state = store.state or {}
    store.state.class = class
    store.state.legacyCooldownViewer = ThugUI_Config and ThugUI_Config.cvUseLegacy or false
    store.state.resourceRing = ThugUI_Config and ThugUI_Config.showResourceRing or false

    
    
    if profiles then
        store.state.profiles = profiles
        store.state.profilesCapturedAt = Stamp("%Y-%m-%d %H:%M:%S")
    end

    
    
    local ok, specInfo = pcall(function()
        local Data = ThugUI.CooldownViewer and ThugUI.CooldownViewer.Data
        if not Data then return {} end

        local specList = Data.GetPlayerSpecs()
        local specs = {}
        for _, spec in ipairs(specList) do
            table.insert(specs, { specID = spec.specID, name = spec.name })
        end

        return {
            hasGlobal = GetSpecialization ~= nil,
            hasC = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) ~= nil,
            activeKey = Data.GetActiveSpecID() or nil,
            specs = specs,
        }
    end)
    if ok then
        store.specAPI = specInfo
    end
end

















local PAD_KEYS = {
    "PAD1", "PAD2", "PAD3", "PAD4", "PAD5", "PAD6",
    "PADDUP", "PADDDOWN", "PADDLEFT", "PADDRIGHT",
    "PADLSHOULDER", "PADRSHOULDER", "PADLTRIGGER", "PADRTRIGGER",
    "PADLSTICK", "PADRSTICK",
    "PADLSTICKUP", "PADLSTICKDOWN", "PADLSTICKLEFT", "PADLSTICKRIGHT",
    "PADRSTICKUP", "PADRSTICKDOWN", "PADRSTICKLEFT", "PADRSTICKRIGHT",
    "PADFORWARD", "PADBACK", "PADSOCIAL", "PADSYSTEM",
    "PADPADDLE1", "PADPADDLE2", "PADPADDLE3", "PADPADDLE4",
}




local MOD_PREFIXES = {
    "ALT-", "CTRL-", "SHIFT-", "ALT-CTRL-", "ALT-SHIFT-", "CTRL-SHIFT-", "ALT-CTRL-SHIFT-",
}




local PAD_ACTIONS = {
    "OPENRADIAL", "TOGGLEUIFOCUS", "TOGGLEPINGSYSTEM",
    "GAMEPADLEFTMOD", "GAMEPADRIGHTMOD",
    "GAMEPADLEFTTARGETMODIFIER", "GAMEPADRIGHTTARGETMODIFIER",
    "GAMEPADACTIONBUTTON1", "GAMEPADACTIONBUTTON2", "GAMEPADACTIONBUTTON3", "GAMEPADACTIONBUTTON4",
    "GAMEPADACTIONBUTTON5", "GAMEPADACTIONBUTTON6", "GAMEPADACTIONBUTTON7", "GAMEPADACTIONBUTTON8",
    "INTERACTSOFTTARGET",
    "TOGGLEPINGLISTENER", "PINGATTACK", "PINGWARNING", "PINGONMYWAY", "PINGASSIST", "TOGGLEPINGTARGET",
    "TOGGLEAUTORUN", "TOGGLESHEATH", "TARGETFOCUS", "FOCUSTARGET", "ASSISTTARGET",
    "SCREENSHOT", "TOGGLEUI",
}




local PAD_CVARS = {
    "GamepadUsePartyTargeting",
    "GamepadSwapTargetModifiers", "GamepadSwapFriendlyTargetActions", "GamepadSwapHostileTargetActions",
    "GamepadShowPersistentInputLegend", "GamepadHudModifierUsesToggle",
    "GamepadTabFriendlyTargetAction", "GamepadTabHostileTargetAction",
    "GamepadRaidTargetingHoverMode", "GamepadStanceBarOverride",
    "GamePadEmulateShift", "GamePadEmulateCtrl", "GamePadEmulateAlt", "GamePadEmulateCmd",
    "GamePadTurnWithCamera",
}




local ATLAS_STEMS = {
    "gamepad-xbox1-buttona", "gamepad-xbox1-buttonb", "gamepad-xbox1-buttonx", "gamepad-xbox1-buttony",
    "gamepad-xbox1-dpadall", "gamepad-xbox1-dpadup", "gamepad-xbox1-dpaddown",
    "gamepad-xbox1-dpadleft", "gamepad-xbox1-dpadright",
    "gamepad-xbox1-dpadupdown", "gamepad-xbox1-dpadleftright",
    "gamepad-xbox1-trigger-lb", "gamepad-xbox1-trigger-rb",
    "gamepad-xbox1-trigger-lt", "gamepad-xbox1-trigger-rt",
    "gamepad-xbox1-stick-l", "gamepad-xbox1-stick-l3", "gamepad-xbox1-stick-r", "gamepad-xbox1-stick-r3",
    "gamepad-xbox1-stick-updown", "gamepad-xbox1-stickr-leftright",
    "gamepad-xbox1-menu", "gamepad-xbox1-view", "gamepad-xbox1-xblogo",
    "gamepad-ps-buttoncrox", "gamepad-ps-buttoncircle", "gamepad-ps-buttonsquare", "gamepad-ps-buttontriangle",
    "gamepad-ps-dpadall", "gamepad-ps-dpadup", "gamepad-ps-dpaddown",
    "gamepad-ps-dpadleft", "gamepad-ps-dpadright",
    "gamepad-ps-dpadupdown", "gamepad-ps-dpadleftright",
    "gamepad-ps-triggerl1", "gamepad-ps-triggerr1", "gamepad-ps-triggerl2", "gamepad-ps-triggerr2",
    "gamepad-ps-stickl", "gamepad-ps-stickl3", "gamepad-ps-stickr", "gamepad-ps-stickr3",
    "gamepad-ps-stickr-updown", "gamepad-ps-stickr-leftright",
    "gamepad-ps-menu", "gamepad-ps-touchpad", "gamepad-ps-pslogo",
}
local ATLAS_SUFFIXES = { "", "-normal", "-over", "-down", "-focus", "-disabled", "-flat-normal" }



local ATLAS_BODY_GUESSES = {
    "gamepad-xbox1-controller", "gamepad-ps-controller", "gamepad-controller",
    "gamepad-xbox1-body", "gamepad-ps-body", "gamepad-xbox1-outline", "gamepad-ps-outline",
    "gamepad-xbox1-silhouette", "gamepad-ps-silhouette", "gamepad-xbox1-all", "gamepad-ps-all",
    "gamepad-xbox1-share", "gamepad-ps-share", "gamepad-ps-create", "gamepad-ps-mute",
    "gamepad-ps-micmute", "gamepad-ps-touchpadl", "gamepad-ps-touchpadr",
    "gamepad-switch-controller", "controller", "controller-xbox", "controller-ps",
}

local function PadValue(fn)
    local ok, a = pcall(fn)
    if not ok then return "(error) " .. tostring(a) end
    if a == nil then return "(nil)" end
    return tostring(a)
end


local function KeysOf(action)
    local f = _G.GetBindingKey
    if type(f) ~= "function" then return "(no GetBindingKey)" end
    local ok, packed = pcall(function() return { f(action) } end)
    if not ok then return "(error) " .. tostring(packed) end
    if #packed == 0 then return "(none)" end
    return table.concat(packed, ", ")
end

local function ActionOf(key, checkOverride)
    local f = _G.GetBindingAction
    if type(f) ~= "function" then return "(no GetBindingAction)" end
    local ok, a = pcall(f, key, checkOverride)
    if not ok then return "(error) " .. tostring(a) end
    if a == nil or a == "" then return "(none)" end
    return tostring(a)
end

local function DumpBindings(dump)
    
    
    
    dump.keys, dump.keysOverride = {}, {}
    for _, key in ipairs(PAD_KEYS) do
        dump.keys[key] = ActionOf(key, false)
        dump.keysOverride[key] = ActionOf(key, true)
    end

    
    
    dump.modKeys = {}
    for _, prefix in ipairs(MOD_PREFIXES) do
        for _, key in ipairs(PAD_KEYS) do
            local full = prefix .. key
            local a = ActionOf(full, false)
            local b = ActionOf(full, true)
            if a ~= "(none)" or b ~= "(none)" then
                dump.modKeys[full] = a .. (a ~= b and (" | override: " .. b) or "")
            end
        end
    end

    dump.actions = {}
    for _, action in ipairs(PAD_ACTIONS) do
        dump.actions[action] = KeysOf(action)
    end
end

local function DumpBindingSet(dump)
    local set = {}
    set.current = PadValue(function() return _G.GetCurrentBindingSet() end)
    
    set.names = PadValue(function()
        local names = {}
        for name, value in pairs(_G.Enum.BindingSet) do
            names[#names + 1] = name .. "=" .. tostring(value)
        end
        table.sort(names)
        return table.concat(names, ", ")
    end)
    set.modConstants = PadValue(function()
        return ("GAMEPAD_MOD_LEFT=%s GAMEPAD_MOD_RIGHT=%s GAMEPAD_MOD_LEFT_AND_RIGHT=%s"):format(
            tostring(_G.GAMEPAD_MOD_LEFT), tostring(_G.GAMEPAD_MOD_RIGHT),
            tostring(_G.GAMEPAD_MOD_LEFT_AND_RIGHT))
    end)
    dump.bindingSet = set
end

local function DumpCVars(dump)
    dump.cvars = {}
    for _, name in ipairs(PAD_CVARS) do
        dump.cvars[name] = PadValue(function() return _G.GetCVar(name) end)
    end
end

local function DumpAtlases(dump)
    local present, missing = {}, {}
    local function Probe(name)
        local ok, info = pcall(function() return _G.C_Texture.GetAtlasInfo(name) end)
        if not ok then
            missing[#missing + 1] = name .. " (error)"
        elseif info ~= nil then
            present[#present + 1] = ("%s %sx%s"):format(name, tostring(info.width), tostring(info.height))
        else
            missing[#missing + 1] = name
        end
    end
    for _, stem in ipairs(ATLAS_STEMS) do
        for _, suffix in ipairs(ATLAS_SUFFIXES) do
            Probe(stem .. suffix)
        end
    end
    local bodyHits = {}
    for _, name in ipairs(ATLAS_BODY_GUESSES) do
        local ok, info = pcall(function() return _G.C_Texture.GetAtlasInfo(name) end)
        bodyHits[name] = ok and (info ~= nil) or false
    end
    dump.atlasPresent, dump.atlasMissing, dump.atlasBodyGuesses = present, missing, bodyHits
end

local function DumpPad(dump)
    local SR = ThugUI.StickReload
    dump.padKind = PadValue(function()
        if not (SR and SR.IdentifyPad) then return nil end
        return SR:IdentifyPad()
    end)

    
    
    local gp = _G.C_GamePad
    local lines = {}
    if gp then
        lines[#lines + 1] = "active=" .. PadValue(function() return gp.GetActiveDeviceID() end)
        local ids = {}
        pcall(function() ids = gp.GetAllDeviceIDs() or {} end)
        for _, id in ipairs(ids) do
            local raw = {}
            pcall(function() raw = gp.GetDeviceRawState(id) or {} end)
            local mapped = {}
            pcall(function() mapped = gp.GetDeviceMappedState(id) or {} end)
            lines[#lines + 1] = ("id=%s name=%s vendor=%s product=%s labelStyle=%s"):format(
                tostring(id), tostring(raw.name or mapped.name), tostring(raw.vendorID),
                tostring(raw.productID), tostring(mapped.labelStyle))
        end
    else
        lines[1] = "(no C_GamePad)"
    end
    dump.devices = lines

    dump.iconSet = PadValue(function()
        return _G.InputDeviceIconSetManager:GetActiveInputDeviceIconSet()
    end)
end


function D:DumpPadState()
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff5555ThugUI|r: /thugpad is not run in combat. Try again out of combat.")
        return false
    end

    local dump = {
        when = Stamp("%Y-%m-%d %H:%M:%S"),
        version = ThugUI.version,
        interface = select(4, GetBuildInfo()),
        errors = {},
    }
    
    for name, fn in pairs({
        bindings = DumpBindings, bindingSet = DumpBindingSet, cvars = DumpCVars,
        atlases = DumpAtlases, pad = DumpPad,
    }) do
        local ok, err = pcall(fn, dump)
        if not ok then dump.errors[name] = tostring(err) end
    end

    Store().padDump = dump
    D:Log("PAD", "pad dump written (%s); errors: %s", dump.when,
        next(dump.errors) and "yes, see padDump.errors" or "none")
    print("|cff66ccffThugUI|r: pad dump saved. Type /reload to write it to disk (ThugUI_DebugLog.padDump).")
    return true
end

SLASH_THUGPAD1 = "/thugpad"
SlashCmdList["THUGPAD"] = function() pcall(D.DumpPadState, D) end





local driver = CreateFrame("Frame", "ThugUI_DiagnosticsDriver")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_LOGOUT")
ThugUI.SafeRegisterEvent(driver, "PLAYER_SPECIALIZATION_CHANGED")



driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")

driver:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        
        
        local store = Store()
        local kept = {}
        for i = (D.loadMark or #store.events) + 1, #store.events do
            kept[#kept + 1] = store.events[i]
        end
        store.events = kept
        
        store.taint, store.taintLast, store.taintCounts = {}, {}, {}
        store.sessionStarted = Stamp("%Y-%m-%d %H:%M:%S")

        local _, class = UnitClass("player")
        D:Log("SESSION", "login as %s, ThugUI v%s, interface %s",
            tostring(class), tostring(ThugUI.version), tostring(select(4, GetBuildInfo())))
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local Data = ThugUI.CooldownViewer and ThugUI.CooldownViewer.Data
        D:Log("SPEC", "changed to %s",
            Data and Data.GetSpecName(Data.GetActiveSpecID()) or "?")
        return
    end

    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
        pcall(function() D:CaptureState() end)
        return
    end

    if event == "PLAYER_LOGOUT" then
        
        
        
        pcall(function() D:CaptureState() end)
    end
end)




local seen = {}
function D:LogOnce(key, category, message, ...)
    if seen[key] then return end
    seen[key] = true
    self:Log(category, message, ...)
end

local breadcrumbs = {}
function D:Breadcrumb(text)
    table.insert(breadcrumbs, { t = GetTime(), text = text })
    while #breadcrumbs > 10 do
        table.remove(breadcrumbs, 1)
    end
end

local taintPrinted = false
local taintWatcher = CreateFrame("Frame", "ThugUI_TaintWatcher")

if ThugUI.SafeRegisterEvent then
    ThugUI.SafeRegisterEvent(taintWatcher, "ADDON_ACTION_BLOCKED")
    ThugUI.SafeRegisterEvent(taintWatcher, "ADDON_ACTION_FORBIDDEN")
else
    pcall(taintWatcher.RegisterEvent, taintWatcher, "ADDON_ACTION_BLOCKED")
    pcall(taintWatcher.RegisterEvent, taintWatcher, "ADDON_ACTION_FORBIDDEN")
    D:Log("TAINT", "SafeRegisterEvent absent at file scope; fell back to pcall")
end

taintWatcher:SetScript("OnEvent", function(_, event, addonName, funcName)
    pcall(function()
        if addonName ~= "ThugUI" then return end
        
        local store = Store()
        store.taint = store.taint or {}
        
        local crumbsCopy = {}
        local lastCrumbText = "none"
        for _, crumb in ipairs(breadcrumbs) do
            local age = GetTime() - crumb.t
            table.insert(crumbsCopy, string.format("%.1fs ago: %s", age, crumb.text))
            lastCrumbText = crumb.text
        end
        
        local entry = {
            when = Now(),
            date = Stamp("%Y-%m-%d"),
            event = event,
            func = funcName,
            combat = InCombatLockdown() and true or false,
            stack = debugstack(2, 12, 0),
            crumbs = crumbsCopy
        }
        
        
        
        
        if #store.taint < 10 then
            table.insert(store.taint, entry)
        else
            store.taintLast = store.taintLast or {}
            table.insert(store.taintLast, entry)
            while #store.taintLast > 10 do table.remove(store.taintLast, 1) end
        end

        
        
        store.taintCounts = store.taintCounts or {}
        local key = tostring(event) .. " " .. tostring(funcName)
        store.taintCounts[key] = (store.taintCounts[key] or 0) + 1
        if store.taintCounts[key] == 1 then
            D:Log("TAINT", "%s blocked %s; last control: %s (repeats counted in taintCounts)", event, funcName, lastCrumbText)
        end
        
        if not taintPrinted then
            taintPrinted = true
            print("|cffff5555ThugUI|r: Blizzard blocked " .. (funcName or "?") .. " because ThugUI code was in the call chain. Last ThugUI control used: " .. lastCrumbText .. ". Buttons may stop responding until you /reload. Details in ThugUI_DebugLog.taint.")
        end
    end)
end)


D.loadMark = #Store().events

return D
