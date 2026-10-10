













ThugUI.ModuleRegistry = {
    { id = "controller", title = "Controller", icon = "Interface\\Icons\\INV_Misc_Gear_01",
      desc = "Gamepad play: wheel, chat, layout, XP bar, minimap, focused quest.",
      modules = { "ControllerMode","GamepadChat","ControllerShortcuts","ControllerRadial",
                  "ControllerLayout","XPBar","MinimapPanel","FocusedQuest","Travel","Prep","ControllerStream",
                  "ControllerObjectives" },
      pages = { "chat","controllerlayout","xpbar","minimap","prep" },
      
      
      
      conflicts = { "actionbars","rings","minimapmouse","acorns" },
      category = "controller", defaultOff = true,
      
      
      
      clients = { forever = true } },
    
    
    
    
    
    
    { id = "auras", title = "Buff window", icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
      desc = "Controller: hides Blizzard's buffs and debuffs; the wheel and L1+L2 open your own buff window.",
      modules = { "AuraWindow" }, pages = { "auras" },
      category = "controller", defaultOff = true,
      clients = { forever = true } },
    { id = "cooldowns",  title = "Cooldown viewer", icon = "Interface\\Icons\\Spell_Nature_TimeStop",
      desc = "Per-spec cooldown grids on the cursor.", modules = {}, pages = { "cooldownviewer" }, category = "combat" },
    { id = "rings",      title = "Cursor rings",   icon = "Interface\\Icons\\Spell_Holy_MagicalSentry",
      desc = "GCD, cast, resource ring and combo pips around the cursor.", modules = {}, pages = { "cursorrings" }, category = "combat" },
    { id = "actionbars", title = "Action bars", icon = "Interface\\Icons\\INV_Misc_Book_09",
      desc = "Blizzard's bars in your rows and columns.", modules = { "ActionBars" }, pages = { "actionbars", "actionbars_xp", "actionbars_micro", "actionbars_bags" }, category = "combat", defaultOff = true },
    { id = "nameplates", title = "Nameplates", icon = "Interface\\Icons\\INV_Misc_Note_01",
      desc = "Name-only plates out of combat.", modules = { "Nameplates" }, pages = { "nameplates" }, category = "combat", defaultOff = true },
    { id = "camera",     title = "Camera", icon = "Interface\\Icons\\INV_Misc_Spyglass_03",
      desc = "Action Cam and camera situations.", modules = { "Camera" }, pages = { "camera" }, category = "ui", defaultOff = true },
    { id = "dialogue",   title = "Dialogue", icon = "Interface\\Icons\\INV_Scroll_03",
      desc = "Quest and gossip text one paragraph at a time.", modules = { "Dialogue" }, pages = { "dialogue" }, category = "ui", defaultOff = true },
    { id = "orbs", title = "Orbs", icon = "Interface\\Icons\\Spell_Holy_SealOfWisdom",
      desc = "Diablo style health and resource orbs, with the resource pips.",
      modules = { "Orbs", "ResourcePips" }, pages = { "orbs" }, category = "ui" },
    { id = "targetframes", title = "Target frames", icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
      desc = "Target and target-of-target frames in place of Blizzard's.",
      modules = { "ControllerTarget" }, pages = { "controllertarget" }, category = "ui" },
    
    
    
    { id = "partyframes", title = "Party frames", icon = "Interface\\Icons\\INV_Misc_GroupNeedMore",
      desc = "Party frames in place of Blizzard's: bars, squares or circles.",
      modules = { "PartyFrames" }, pages = { "partyframes" }, category = "ui" },
    { id = "minimapmouse", title = "Minimap", icon = "Interface\\Icons\\INV_Misc_Map_01",
      desc = "The ThugUI minimap panel for mouse play, with its own settings.",
      modules = {}, pages = { "minimapmouse" }, category = "interface", defaultOff = true },
    { id = "orbeffects", title = "Orb effects", icon = "Interface\\Icons\\Spell_Nature_WispSplode",
      desc = "Animated effects in the orbs and pips. Costs frame rate.", modules = { "OrbEffects" },
      pages = {}, defaultOff = true, soon = true, category = "ui" },
    { id = "acorns",     title = "Acorns", icon = "Interface\\AddOns\\ThugUI\\media\\Acorn",
      desc = "Acorns standing in for hidden chat and tracker.", modules = { "Acorns" }, pages = { "acorns", "acorns_chat", "acorns_objectives" }, category = "interface" },
    { id = "framehider", title = "Frame hider", icon = "Interface\\Icons\\Spell_Nature_Invisibilty",
      desc = "Turn off Blizzard frames you never look at.", modules = {}, pages = { "framehider" }, category = "interface" },
    { id = "automation", title = "Automation", icon = "Interface\\Icons\\INV_Misc_Coin_01",
      desc = "Sell junk and repair at vendors.", modules = { "Automation" }, pages = { "automation" }, category = "general" },
    { id = "fishing",    title = "Fishing", icon = "Interface\\Icons\\INV_Fishingpole_02",
      desc = "The ThugFish macro and fishing sound.", modules = { "Fishing" }, pages = { "fishing" }, category = "general", defaultOff = true },
    
    
    
    { id = "seasonal",   title = "Seasonal", icon = "Interface\\Icons\\Achievement_ChallengeMode_Gold",
      desc = "Mythic+, raid, vault, delves and rewards for this season in one window (/thugseason).",
      modules = { "SeasonalData","Seasonal","SeasonalVault","SeasonalGearTrack","SeasonalRewardTables",
                  "SeasonalSuggested","SeasonalRewards","SeasonalRaid","SeasonalMplus" },
      pages = {}, clients = { retail = true }, category = "general" },
    { id = "gearflags",  title = "Gear flags", icon = "Interface\\Icons\\INV_Misc_Gem_01",
      desc = "Flags equipped slots missing an enchant or gem, and marks set pieces.",
      modules = { "GearFlags" }, pages = { "gearflags" }, clients = { retail = true }, category = "interface" },
    { id = "worldmap",   title = "World map", icon = "Interface\\Icons\\INV_Misc_Map_01",
      desc = "Zone labels on the world map.", modules = { "WorldMapLabels" }, pages = { "worldmap" }, category = "interface", defaultOff = true },
    { id = "slimmap",   title = "Travel map", icon = "Interface\\Icons\\INV_Misc_Map02",
      desc = "A borderless travel map with slim art: nothing past the coastlines.", modules = { "WorldMapStrip" }, pages = {}, soon = true, category = "interface" },
}

ThugUI.Modules = {}
local M = ThugUI.Modules

function M:Entry(id)
    for i = 1, #ThugUI.ModuleRegistry do
        if ThugUI.ModuleRegistry[i].id == id then
            return ThugUI.ModuleRegistry[i]
        end
    end
    return nil
end





function M:ForClient(entry)
    if not entry or not entry.clients then return true end
    return entry.clients[ThugUI.client] == true
end



function M:Visible()
    local list = {}
    for i = 1, #ThugUI.ModuleRegistry do
        local entry = ThugUI.ModuleRegistry[i]
        if M:ForClient(entry) then list[#list + 1] = entry end
    end
    return list
end

function M:Stored(id)
    local entry = M:Entry(id)
    if entry and not M:ForClient(entry) then
        return false
    end
    if entry and entry.soon then
        return false
    end
    if entry and entry.locked then
        return true
    end
    if ThugUIDB and ThugUIDB.Modules and ThugUIDB.Modules[id] ~= nil then
        return ThugUIDB.Modules[id]
    end
    if entry and entry.defaultOff then
        return false
    end
    return true
end








M.DEFAULTS_VERSION = 2
M.ON_BEFORE_V2 = { "controller", "actionbars", "nameplates", "camera", "dialogue",
                   "minimapmouse", "worldmap", "fishing" }
function M:PinOldDefaults()
    if not ThugUIDB or (ThugUIDB.ModulesDefaults or 1) >= M.DEFAULTS_VERSION then return end
    if not (ThugUI.Profiles and ThugUI.Profiles.freshInstall) then
        ThugUIDB.Modules = ThugUIDB.Modules or {}
        for _, id in ipairs(M.ON_BEFORE_V2) do
            if ThugUIDB.Modules[id] == nil then ThugUIDB.Modules[id] = true end
        end
    end
    ThugUIDB.ModulesDefaults = M.DEFAULTS_VERSION
end





function M:MigrateAuraTile()
    if not ThugUIDB then return end
    ThugUIDB.Modules = ThugUIDB.Modules or {}
    if ThugUIDB.Modules.auras ~= nil then return end
    if ThugUI.Profiles and ThugUI.Profiles.freshInstall then return end
    local old = ThugUIDB.AuraWindow and ThugUIDB.AuraWindow.enabled
    ThugUIDB.Modules.auras = old ~= false
    if ThugUIDB.AuraWindow then ThugUIDB.AuraWindow.enabled = nil end
end

function M:Snapshot()
    if ThugUIDB and ThugUIDB.Modules and ThugUIDB.Modules.unitframes ~= nil then
        
        
        local controllerEntry = M:Entry("controller")
        local wasOn = (ThugUIDB.Modules.unitframes ~= false) or (controllerEntry and M:ForClient(controllerEntry) and M:Stored("controller"))
        if not wasOn then
            if ThugUIDB.Modules.orbs == nil then ThugUIDB.Modules.orbs = false end
            if ThugUIDB.Modules.targetframes == nil then ThugUIDB.Modules.targetframes = false end
        end
        ThugUIDB.Modules.unitframes = nil
    end
    if ThugUIDB and ThugUIDB.ControllerTarget and ThugUIDB.ControllerTarget.enabled == false then
        
        ThugUIDB.Modules = ThugUIDB.Modules or {}
        if ThugUIDB.Modules.targetframes == nil then
            ThugUIDB.Modules.targetframes = false
        end
        ThugUIDB.ControllerTarget.enabled = nil
    end

    M:PinOldDefaults()
    M:MigrateAuraTile()

    ThugUI.moduleOn = {}
    ThugUI.moduleBase = {}
    for i = 1, #ThugUI.ModuleRegistry do
        local id = ThugUI.ModuleRegistry[i].id
        local stored = M:Stored(id)
        ThugUI.moduleOn[id] = stored
        ThugUI.moduleBase[id] = stored
    end

    local isControllerModeActive = false
    if ThugUI.ControllerMode and ThugUI.ControllerMode.IsActive then
        local ok, active = pcall(ThugUI.ControllerMode.IsActive, ThugUI.ControllerMode)
        if ok and active then
            isControllerModeActive = true
        end
    end
    ThugUI.controllerAtLoad = ThugUI.moduleOn.controller and isControllerModeActive
    ThugUI.moduleSuspended = {}
    
    local suspendedList = {}
    if ThugUI.controllerAtLoad then
        local controllerEntry = M:Entry("controller")
        for _, id in ipairs(controllerEntry.conflicts) do
            if ThugUI.moduleOn[id] then
                ThugUI.moduleOn[id] = false
                ThugUI.moduleSuspended[id] = true
                table.insert(suspendedList, id)
            end
        end
    end

    if ThugUI.Diagnostics then
        local suspendedStr = #suspendedList > 0 and table.concat(suspendedList, ", ") or "none"
        ThugUI.Diagnostics:Log("MODULES", string.format("controller at load=%s; suspended: %s", tostring(ThugUI.controllerAtLoad), suspendedStr))
    end

    
    ThugUI.moduleOn.travel = ThugUI.moduleOn.controller
    ThugUI.moduleOn.prep = ThugUI.moduleOn.controller
    ThugUI.moduleOn.focusedquest = ThugUI.moduleOn.controller

    
    ThugUI.unitFramesMouse = (ThugUI.moduleOn.orbs or ThugUI.moduleOn.targetframes or ThugUI.moduleOn.partyframes) and M:ForClient(M:Entry("controller")) and not ThugUI.controllerAtLoad
    if ThugUI.UnitFrames then ThugUI.UnitFrames:ApplyLayer() end

    
    
    if ThugUI.controllerAtLoad then
        ThugUI.minimapMode = "controller"
    elseif ThugUI.moduleOn and ThugUI.moduleOn.minimapmouse then
        ThugUI.minimapMode = "mouse"
    else
        ThugUI.minimapMode = nil
    end
end

function ThugUI:IsModuleOn(id)
    if not ThugUI.moduleOn then
        return M:Stored(id)
    end
    if ThugUI.moduleOn[id] == nil then
        
        
        M.warned = M.warned or {}
        if ThugUI.Diagnostics and not M.warned[id] then
            M.warned[id] = true
            ThugUI.Diagnostics:Log("MODULES", string.format("unknown module id %q", id))
        end
        return true
    end
    return ThugUI.moduleOn[id]
end

function M:Set(id, on)
    local entry = M:Entry(id)
    if not entry or entry.locked or entry.soon or not M:ForClient(entry) then
        return false
    end
    ThugUIDB.Modules = ThugUIDB.Modules or {}
    
    
    
    local def = not entry.defaultOff
    if on == def then
        ThugUIDB.Modules[id] = nil
    else
        ThugUIDB.Modules[id] = on
    end
    return true
end

function M:Pending(id)
    if not ThugUI.moduleBase then return false end
    if ThugUI.moduleBase[id] == nil then return false end
    return M:Stored(id) ~= ThugUI.moduleBase[id]
end

function M:Suspended(id)
    if ThugUI.moduleSuspended and ThugUI.moduleSuspended[id] == true then
        return true
    end
    return false
end

function M:PendingCount()
    if not ThugUI.moduleOn then return 0 end
    local count = 0
    for i = 1, #ThugUI.ModuleRegistry do
        if M:Pending(ThugUI.ModuleRegistry[i].id) then
            count = count + 1
        end
    end
    return count
end

function M:ModuleNameOn(registerName)
    if registerName == "MinimapPanel" then
        if ThugUI.moduleOn then
            return not not (ThugUI.moduleOn.controller or ThugUI.moduleOn.minimapmouse)
        end
        return true
    end
    if registerName == "FocusedQuest" then
        if ThugUI.moduleOn and ThugUI.moduleOn.focusedquest == false then
            return false
        end
        return true
    end
    for i = 1, #ThugUI.ModuleRegistry do
        local entry = ThugUI.ModuleRegistry[i]
        for j = 1, #entry.modules do
            if entry.modules[j] == registerName then
                if not M:ForClient(entry) then return false end
                if ThugUI.moduleOn and ThugUI.moduleOn[entry.id] == false then
                    return false
                end
                return true
            end
        end
    end
    return true
end





local function PageModuleOn(id)
    if ThugUI.moduleOn and ThugUI.moduleOn[id] == false then return false end
    return M:Stored(id) and true or false
end

function M:PageOn(pageId)
    if pageId == "modules" then return true end
    for i = 1, #ThugUI.ModuleRegistry do
        local entry = ThugUI.ModuleRegistry[i]
        for j = 1, #entry.pages do
            if entry.pages[j] == pageId then
                return PageModuleOn(entry.id)
            end
        end
    end
    return true
end

ThugUI.Dialogs["THUGUI_MODULES_RELOAD"] = {
    text = "ThugUI: controller mode changed. Reload so the modules it replaces switch %s?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local driftPrompted = {}
local driftRegenFrame = CreateFrame("Frame")
function M:CheckControllerDrift()
    if not ThugUI.moduleOn or not ThugUI.moduleOn.controller then return end
    if not ThugUI.ControllerMode or not ThugUI.ControllerMode.IsActive then return end
    
    local ok, active = pcall(ThugUI.ControllerMode.IsActive, ThugUI.ControllerMode)
    if not ok then return end
    
    if active ~= ThugUI.controllerAtLoad then
        if driftPrompted[active] then return end
        
        local hasConflictOn = false
        local controllerEntry = M:Entry("controller")
        for _, id in ipairs(controllerEntry.conflicts) do
            if ThugUI.moduleBase and ThugUI.moduleBase[id] then
                hasConflictOn = true
                break
            end
        end
        
        if not hasConflictOn then return end
        
        driftPrompted[active] = true
        local switchText = active and "off" or "back on"
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("MODULES", string.format("controller now %s (was %s at load); reload prompted", tostring(active), tostring(ThugUI.controllerAtLoad)))
        end
        
        if InCombatLockdown() then
            driftRegenFrame.pendingReload = switchText
            driftRegenFrame:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_REGEN_ENABLED" then
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    if self.pendingReload then
                        ThugUI.Dialog:Show("THUGUI_MODULES_RELOAD", self.pendingReload)
                        self.pendingReload = nil
                    end
                end
            end)
            driftRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        else
            ThugUI.Dialog:Show("THUGUI_MODULES_RELOAD", switchText)
        end
    end
end

local driftLoginFrame = CreateFrame("Frame")
driftLoginFrame:RegisterEvent("PLAYER_LOGIN")
driftLoginFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if ThugUI.ControllerMode and ThugUI.ControllerMode.RegisterCallback then
            ThugUI.ControllerMode:RegisterCallback(function()
                M:CheckControllerDrift()
            end)
        end
    end
end)
