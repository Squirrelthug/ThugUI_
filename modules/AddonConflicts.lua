



























local ThugUI = _G.ThugUI
local AC = {}
ThugUI.AddonConflicts = AC






AC.LIST = {
    { addon = "ElvUI", label = "ElvUI",
      targets = { "actionbars", "nameplates", "minimapmouse", "chatstream", "targetframes", "partyframes" },
      message = "ElvUI replaces much of the same UI as ThugUI's %s. Turn ours off, or turn off those parts in ElvUI's own settings." },
    { addon = "Bartender4", label = "Bartender4", targets = { "actionbars" } },
    { addon = "Dominos", label = "Dominos", targets = { "actionbars" } },
    { addon = "Plater", label = "Plater Nameplates", targets = { "nameplates" } },
    { addon = "Kui_Nameplates", label = "KUI Nameplates", targets = { "nameplates" } },
    { addon = "TidyPlates", label = "TidyPlates", targets = { "nameplates" } },
    { addon = "TidyPlates_ThreatPlates", label = "TidyPlates ThreatPlates", targets = { "nameplates" } },
    { addon = "Platynator", label = "Platynator", targets = { "nameplates" } },
    { addon = "SexyMap", label = "SexyMap", targets = { "minimapmouse" } },
    { addon = "Leatrix_Plus", label = "Leatrix Plus", targets = { "chatstream", "minimapmouse" },
      message = "Leatrix Plus has chat and minimap options that clash with ThugUI's %s. Turn ours off, or turn off Leatrix's chat and minimap options." },
    { addon = "Prat-3.0", label = "Prat", targets = { "chatstream" } },
    { addon = "Chatter", label = "Chatter", targets = { "chatstream" } },
    { addon = "Chattynator", label = "Chattynator", targets = { "chatstream" } },
    { addon = "Glass", label = "Glass", targets = { "chatstream" } },
    { addon = "UnhaltedUnitFrames", label = "Unhalted Unit Frames", targets = { "targetframes", "partyframes" } },
    
    { addon = "ShadowedUnitFrames", label = "Shadowed Unit Frames", targets = { "targetframes", "partyframes" } },
    { addon = "PitBull4", label = "PitBull 4", targets = { "targetframes", "partyframes" } },
    { addon = "Immersion", label = "Immersion", targets = { "dialogue" } },
    { addon = "DialogueUI", label = "DialogueUI", targets = { "dialogue" } },
    
    
}

local function IsLoaded(name)
    local api = C_AddOns and C_AddOns.IsAddOnLoaded or _G.IsAddOnLoaded
    if not api then return false end
    local ok, loaded = pcall(api, name)
    return ok and loaded and true or false
end

local function Store()
    ThugUIDB.AddonConflicts = ThugUIDB.AddonConflicts or {}
    local s = ThugUIDB.AddonConflicts
    s.dismissed = s.dismissed or {}
    return s
end

local function Log(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("CONFLICTS", fmt, ...) end
end


function AC:Affected(entry)
    local M, list = ThugUI.Modules, {}
    if entry.moduleCheck then
        local ok, on = pcall(entry.moduleCheck)
        if not (ok and on) then return list end
    end
    for _, id in ipairs(entry.targets) do
        local reg = M:Entry(id)
        if reg and M:ForClient(reg) and ThugUI.moduleOn and ThugUI.moduleOn[id] then
            list[#list + 1] = id
        end
    end
    return list
end


function AC:Pending()
    local dismissed, out = Store().dismissed, {}
    for _, entry in ipairs(self.LIST) do
        if not dismissed[entry.addon] and IsLoaded(entry.addon) then
            local affected = self:Affected(entry)
            if #affected > 0 then out[#out + 1] = { entry = entry, affected = affected } end
        end
    end
    return out
end

local function Titles(ids)
    local names = {}
    for _, id in ipairs(ids) do
        local reg = ThugUI.Modules:Entry(id)
        names[#names + 1] = reg and reg.title or id
    end
    if #names <= 1 then return names[1] or "" end
    return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end
AC.Titles = Titles

function AC:Text(item)
    local entry, titles = item.entry, Titles(item.affected)
    local body
    if entry.message then
        body = string.format(entry.message, titles)
    else
        body = string.format("%s and ThugUI's %s both handle the same thing. Running both can cause errors or odd behaviour.\n\nTurn ours off to let %s handle it, or turn %s off in the AddOns list.",
            entry.label, titles, entry.label, entry.label)
    end
    return "|cffffd100Another addon does this too|r\n\n" .. body
end



local function Next()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() AC:ShowNext() end)
    else
        AC:ShowNext()
    end
end

function AC:ShowNext()
    self.index = (self.index or 0) + 1
    local item = self.queue and self.queue[self.index]
    if not item then
        self.queue = nil
        if self.turnedOff and #self.turnedOff > 0 then
            ThugUI.Dialog:Show("THUGUI_CONFLICT_RELOAD", Titles(self.turnedOff))
        end
        return
    end
    ThugUI.Dialog:Show("THUGUI_ADDON_CONFLICT", self:Text(item), nil, item)
end


function AC:TurnOursOff(item)
    self.turnedOff = self.turnedOff or {}
    for _, id in ipairs(item.affected) do
        if ThugUI.Modules:Set(id, false) then
            self.turnedOff[#self.turnedOff + 1] = id
        end
    end
    Log("%s: turned ours off (%s)", item.entry.addon, table.concat(item.affected, ","))
end

function AC:Dismiss(item)
    Store().dismissed[item.entry.addon] = true
    Log("%s: don't show again", item.entry.addon)
end


function AC:Run(force)
    if self.ran and not force then return end
    if InCombatLockdown() then
        self.waitCombat = true
        self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self.ran = true
    self.queue, self.index, self.turnedOff = self:Pending(), 0, nil
    local names = {}
    for _, item in ipairs(self.queue) do names[#names + 1] = item.entry.addon .. ">" .. table.concat(item.affected, ",") end
    Log("check: %s", #names > 0 and table.concat(names, " ") or "none")
    self:ShowNext()
end

ThugUI.Dialogs["THUGUI_ADDON_CONFLICT"] = {
    text = "%s",
    button1 = "Turn ours off",
    button2 = "OK",
    button3 = "Don't show again",
    
    padFocus = 2,
    OnAccept = function(_, item) AC:TurnOursOff(item) Next() end,
    OnCancel = function() Next() end,
    OnAlt = function(_, item) AC:Dismiss(item) Next() end,
}

ThugUI.Dialogs["THUGUI_CONFLICT_RELOAD"] = {
    text = "ThugUI: reload now so %s turns off?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
}



AC.events = CreateFrame("Frame")
AC.events:RegisterEvent("PLAYER_LOGIN")
AC.events:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        if C_Timer and C_Timer.After then
            C_Timer.After(3, function() AC:Run() end)
        else
            AC:Run()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        if AC.waitCombat then
            AC.waitCombat = false
            AC:Run()
        end
    end
end)
