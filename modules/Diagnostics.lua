


























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
        
        store.taint = {}
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
        
        table.insert(store.taint, {
            when = Now(),
            date = Stamp("%Y-%m-%d"),
            event = event,
            func = funcName,
            combat = InCombatLockdown() and true or false,
            stack = debugstack(2, 12, 0),
            crumbs = crumbsCopy
        })
        
        while #store.taint > 20 do
            table.remove(store.taint, 1)
        end
        
        D:Log("TAINT", "%s blocked %s; last control: %s", event, funcName, lastCrumbText)
        
        if not taintPrinted then
            taintPrinted = true
            print("|cffff5555ThugUI|r: Blizzard blocked " .. (funcName or "?") .. " because ThugUI code was in the call chain. Last ThugUI control used: " .. lastCrumbText .. ". Buttons may stop responding until you /reload. Details in ThugUI_DebugLog.taint.")
        end
    end)
end)


D.loadMark = #Store().events

return D
