






local ThugUI = _G.ThugUI
local W = ThugUI.Widgets










local CATEGORIES = {
    { id = "say",         title = "Say / Yell / Emote", tip = "SAY, YELL, EMOTE, TEXT_EMOTE" },
    { id = "whisper",     title = "Whisper",            tip = "WHISPER, WHISPER_INFORM, BN_WHISPER, BN_WHISPER_INFORM, AFK, DND" },
    { id = "party",       title = "Party / Instance",   tip = "PARTY, PARTY_LEADER, INSTANCE_CHAT, INSTANCE_CHAT_LEADER" },
    { id = "raid",        title = "Raid",               tip = "RAID, RAID_LEADER, RAID_WARNING" },
    { id = "guild",       title = "Guild / Communities", tip = "GUILD, OFFICER, and community channels" },
    { id = "system",      title = "System",             tip = "SYSTEM, addon messages, error messages, anything unmapped" },
    { id = "loot",        title = "Loot / Money",       tip = "LOOT, CURRENCY, MONEY, TRADESKILLS, OPENING" },
    { id = "progress",    title = "XP / Reputation",    tip = "COMBAT_XP_GAIN, COMBAT_HONOR_GAIN, COMBAT_FACTION_CHANGE, SKILL" },
    { id = "achievement", title = "Achievements",       tip = "ACHIEVEMENT, GUILD_ACHIEVEMENT" },
    { id = "npc",         title = "NPC speech",         tip = "MONSTER_SAY, MONSTER_YELL, MONSTER_EMOTE, MONSTER_WHISPER, RAID_BOSS_EMOTE, RAID_BOSS_WHISPER" },
}

local UI = {}   

local function Tabs()
    if not ThugUIDB.GamepadChat then ThugUIDB.GamepadChat = {} end
    ThugUIDB.GamepadChat.tabs = ThugUIDB.GamepadChat.tabs or {}
    return ThugUIDB.GamepadChat and ThugUIDB.GamepadChat.tabs
end

local function Rebuild()
    if ThugUI.GamepadChat and ThugUI.GamepadChat.RebuildTabs then ThugUI.GamepadChat:RebuildTabs() end
end



function UI.JoinedChannels()
    local out = {}
    if type(GetChannelList) ~= "function" then return out end
    local list = { GetChannelList() }
    for i = 1, #list, 3 do
        local name = list[i + 1]
        if type(name) == "string" and not (issecretvalue and issecretvalue(name)) then
            out[#out + 1] = name
        end
    end
    return out
end




function UI.Join(name)
    if type(name) ~= "string" or name == "" then return end
    local frame = _G.DEFAULT_CHAT_FRAME or _G.ChatFrame1
    local id = frame and frame.GetID and frame:GetID() or 1
    if type(JoinPermanentChannel) == "function" then
        JoinPermanentChannel(name, nil, id, 1)
    end
    if frame and frame.AddChannel then frame:AddChannel(name) end
end

function UI.Leave(name)
    if type(LeaveChannelByName) == "function" then LeaveChannelByName(name) end
end

local function Button(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Check(parent, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local label = ThugUI.Theme:Paint(cb:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall")), "label")
    label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label = label
    cb:SetScript("OnClick", onClick)
    return cb
end

local function TabRow(i)
    UI.tabRows = UI.tabRows or {}
    local row = UI.tabRows[i]
    if row then return row end
    row = {}
    row.name = CreateFrame("EditBox", nil, UI.host, "InputBoxTemplate")
    row.name:SetSize(130, 22)
    row.name:SetAutoFocus(false)
    row.name:SetScript("OnEnterPressed", function(self)
        local t = Tabs()[row.index]
        local text = self:GetText()
        if t and text ~= "" then t.name = text; Rebuild() end
        self:ClearFocus()
        UI.Layout()
    end)
    row.name:SetScript("OnEscapePressed", function(self) self:ClearFocus(); UI.Layout() end)
    local function Swap(a, b)
        local tabs = Tabs()
        
        if a < 2 or b < 2 or a > #tabs or b > #tabs then return end
        tabs[a], tabs[b] = tabs[b], tabs[a]
        if UI.editing == a then UI.editing = b elseif UI.editing == b then UI.editing = a end
        Rebuild(); UI.Layout()
    end
    row.up = Button(UI.host, "Up", 44, function() Swap(row.index, row.index - 1) end)
    row.down = Button(UI.host, "Down", 52, function() Swap(row.index, row.index + 1) end)
    row.edit = Button(UI.host, "Edit", 48, function()
        UI.editing = (UI.editing == row.index) and nil or row.index
        UI.Layout()
    end)
    row.delete = Button(UI.host, "Delete", 60, function()
        local tabs = Tabs()
        if row.index < 2 or row.index > #tabs then return end
        table.remove(tabs, row.index)
        if UI.editing == row.index then UI.editing = nil
        elseif UI.editing and UI.editing > row.index then UI.editing = UI.editing - 1 end
        Rebuild(); UI.Layout()
    end)
    UI.tabRows[i] = row
    return row
end

local function ChannelCheck(i)
    UI.chanChecks = UI.chanChecks or {}
    local cb = UI.chanChecks[i]
    if cb then return cb end
    cb = Check(UI.host, function(self)
        local t = Tabs()[UI.editing]
        if not t or not self.channel then return end
        t.channels = t.channels or {}
        t.channels[self.channel] = self:GetChecked() and true or nil
        Rebuild()
    end)
    UI.chanChecks[i] = cb
    return cb
end

local function ChannelRow(i)
    UI.chanRows = UI.chanRows or {}
    local row = UI.chanRows[i]
    if row then return row end
    row = {}
    row.label = ThugUI.Theme:Paint(UI.host:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlight")), "label")
    row.leave = Button(UI.host, "Leave", 60, function()
        if row.channel then UI.Leave(row.channel) end
        
    end)
    UI.chanRows[i] = row
    return row
end



function UI.Layout()
    local host = UI.host
    if not host then return end
    local tabs = Tabs()
    local y = 0
    local function At(frame, x, dy)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", host, "TOPLEFT", x, -(y + (dy or 0)))
        frame:Show()
    end

    
    for i, t in ipairs(tabs) do
        local row = TabRow(i)
        row.index = i
        if not row.name:HasFocus() then row.name:SetText(t.name or "") end
        At(row.name, 6, 0)
        At(row.up, 142, 0); At(row.down, 188, 0); At(row.edit, 242, 0); At(row.delete, 292, 0)
        
        row.up:SetEnabled(i > 2); row.down:SetEnabled(i > 1 and i < #tabs)
        row.edit:SetEnabled(not t.all); row.delete:SetEnabled(i > 1)
        row.edit:SetText(UI.editing == i and "Done" or "Edit")
        y = y + 26
    end
    for i = #tabs + 1, #(UI.tabRows or {}) do
        local row = UI.tabRows[i]
        row.name:Hide(); row.up:Hide(); row.down:Hide(); row.edit:Hide(); row.delete:Hide()
    end
    At(UI.addTab, 6, 2)
    y = y + 32

    
    local t = UI.editing and tabs[UI.editing]
    if t and not t.all then
        UI.editTitle:SetText("What \"" .. (t.name or "") .. "\" shows")
        At(UI.editTitle, 6, 4)
        y = y + 22
        for k, cat in ipairs(CATEGORIES) do
            local cb = UI.catChecks[k]
            local col, rowN = (k - 1) % 2, math.floor((k - 1) / 2)
            cb:ClearAllPoints()
            cb:SetPoint("TOPLEFT", host, "TOPLEFT", 6 + col * 200, -(y + rowN * 24))
            cb:SetChecked(t.show and t.show[cat.id] and true or false)
            cb:Show()
        end
        y = y + math.ceil(#CATEGORIES / 2) * 24 + 4
        local joined = UI.JoinedChannels()
        for k, name in ipairs(joined) do
            local cb = ChannelCheck(k)
            cb.channel = name
            cb.label:SetText(name)
            local col, rowN = (k - 1) % 2, math.floor((k - 1) / 2)
            cb:ClearAllPoints()
            cb:SetPoint("TOPLEFT", host, "TOPLEFT", 6 + col * 200, -(y + rowN * 24))
            cb:SetChecked(t.channels and t.channels[name] and true or false)
            cb:Show()
        end
        for k = #joined + 1, #(UI.chanChecks or {}) do UI.chanChecks[k]:Hide() end
        y = y + math.ceil(#joined / 2) * 24 + 8
    else
        UI.editTitle:Hide()
        for _, cb in ipairs(UI.catChecks) do cb:Hide() end
        for _, cb in ipairs(UI.chanChecks or {}) do cb:Hide() end
    end

    
    At(UI.chanTitle, 6, 6)
    y = y + 26
    local joined = UI.JoinedChannels()
    for k, name in ipairs(joined) do
        local row = ChannelRow(k)
        row.channel = name
        row.label:SetText(name)
        At(row.label, 10, 4); At(row.leave, 220, 0)
        y = y + 26
    end
    for k = #joined + 1, #(UI.chanRows or {}) do
        UI.chanRows[k].label:Hide(); UI.chanRows[k].leave:Hide()
    end
    At(UI.joinBox, 10, 2); At(UI.joinButton, 150, 2)
    y = y + 30
    At(UI.chanNote, 6, 2)
    y = y + (UI.chanNote:GetStringHeight() or 28) + 10

    host:SetHeight(y)
    
    
    local page = host:GetParent()
    if UI.hostTopY and page then
        local need = math.abs(UI.hostTopY) + y + 20
        if (page:GetHeight() or 0) < need then page:SetHeight(need) end
    end
end

local function BuildTabsUI(panel)
    panel:Section("Tabs")
    panel:Note("All shows everything. Add tabs and tick what each shows; Up/Down "
        .. "reorders, Edit opens what it shows. A channel with no tab gets one of its "
        .. "own the first time it speaks, if the box below is ticked.")
    panel:Checkbox{
        label = "Auto tab for a new channel",
        get = function() return ThugUIDB.GamepadChat and ThugUIDB.GamepadChat.autoChannelTabs end,
        set = function(v) ThugUIDB.GamepadChat.autoChannelTabs = v and true or false end,
    }

    local host = CreateFrame("Frame", nil, panel.parent)
    host:SetSize(panel.width, 10)
    panel:Place(host, 10, { width = panel.width })
    
    UI.hostTopY = panel.rowTopY
    UI.host, UI.panel = host, panel

    UI.addTab = Button(host, "Add tab", 90, function()
        table.insert(Tabs(), { name = "New tab", show = {}, channels = {} })
        UI.editing = #Tabs()
        Rebuild(); UI.Layout()
    end)
    UI.editTitle = ThugUI.Theme:Paint(host:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "section")
    UI.catChecks = {}
    for k, cat in ipairs(CATEGORIES) do
        local cb = Check(host, function(self)
            local t = Tabs()[UI.editing]
            if not t then return end
            t.show = t.show or {}
            t.show[cat.id] = self:GetChecked() and true or nil
            Rebuild()
        end)
        cb.label:SetText(cat.title)
        if W and W.AttachTooltip then W.AttachTooltip(cb, cat.title, cat.tip) end
        UI.catChecks[k] = cb
    end
    UI.chanTitle = ThugUI.Theme:Paint(host:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "section")
    UI.chanTitle:SetText("Channels")
    UI.joinBox = CreateFrame("EditBox", nil, host, "InputBoxTemplate")
    UI.joinBox:SetSize(130, 22)
    UI.joinBox:SetAutoFocus(false)
    local function DoJoin()
        UI.Join(UI.joinBox:GetText())
        UI.joinBox:SetText("")
        UI.joinBox:ClearFocus()
    end
    UI.joinBox:SetScript("OnEnterPressed", DoJoin)
    UI.joinBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    UI.joinButton = Button(host, "Join", 60, DoJoin)
    UI.chanNote = ThugUI.Theme:Paint(host:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontDisableSmall")), "note")
    UI.chanNote:SetWidth(panel.width - 20)
    UI.chanNote:SetJustifyH("LEFT")
    UI.chanNote:SetText("Joining adds the channel to chat window 1, as /join does, so its "
        .. "lines reach this window. A tab only fills with what Blizzard's chat windows receive.")

    ThugUI.SafeRegisterEvent(host, "CHANNEL_UI_UPDATE")
    host:SetScript("OnEvent", function() if host:IsVisible() then UI.Layout() end end)
    UI.Layout()
end


ThugUI.ChatPageUI = UI



local function Build(panel)
    
    
    
    
    
    
    
    ThugUIDB.GamepadChat = ThugUIDB.GamepadChat or {}
    panel:FrameSection{ title = "Controller mode" }
    panel:Note("The controller chat window replaces the native chat when Controller Mode is active. The channel you type to is chosen the Blizzard way (/g, /p, /1, Tab).")
    panel:Part("Content")
    panel:Dropdown{
        label = "Controller mode",
        options = {
            
            { text = "Auto (follow Blizzard's gamepad UI)", value = "auto" },
            { text = "Always", value = "on" },
            { text = "Never", value = "off" }
        },
        get = function() return ThugUIDB.ControllerMode and ThugUIDB.ControllerMode.override or "auto" end,
        set = function(v)
            if ThugUI.ControllerMode then ThugUI.ControllerMode:SetOverride(v) end
        end,
    }

    local activeState = ThugUI.ControllerMode and ThugUI.ControllerMode:IsActive() and "ON" or "OFF"
    local statusNote = panel:Note("Controller mode is " .. activeState .. " right now.")
    
    if ThugUI.ControllerMode then
        ThugUI.ControllerMode:RegisterCallback(function(active)
            if statusNote and statusNote.SetText then
                statusNote:SetText("Controller mode is " .. (active and "ON" or "OFF") .. " right now.")
            end
        end)
    end

    
    
    
    local gp = ThugUI.ControllerMode and ThugUI.ControllerMode:CreateGamepadUIButton(panel.parent, 220)
    if gp then
        gp.labelText = "Turn on Gamepad UI"
        panel:Place(gp, 28)
        if panel.Index then panel:Index("Turn on Blizzard's Gamepad UI", gp, "control") end
    else
        panel:Note("Turn Blizzard's Gamepad UI on in Options > Gamepad > Enable Gamepad UI.")
    end

    
    
    
    
    
    
    
    panel:Note("Compact action bar (only the active button set): Blizzard moved it into Edit Mode. "
        .. "With the Gamepad UI on, open Edit Mode, select the controller action bar and tick Compact.")
    if not (InCombatLockdown and InCombatLockdown()) then
        local em = CreateFrame("Button", nil, panel.parent, "SecureActionButtonTemplate,UIPanelButtonTemplate")
        em:SetSize(220, 24)
        em:SetText("Open Edit Mode")
        em.labelText = "Open Edit Mode"
        em:RegisterForClicks("AnyUp", "AnyDown")
        em:SetAttribute("type", "macro")
        em:SetAttribute("useOnKeyDown", false)
        em:SetAttribute("macrotext", (_G.SLASH_EDITMODE1 or "/editmode"))
        panel:Place(em, 28)
        if panel.Index then panel:Index("Compact action bar (Edit Mode)", em, "control") end
    end

    
    
    
    panel:Checkbox{
        label = "Use the controller chat window",
        tooltip = "Off: the chat acorn manages chat again, or Blizzard's chat if the acorn is off.",
        get = function() return ThugUIDB.GamepadChat.enabled ~= false end,
        set = function(v)
            ThugUIDB.GamepadChat.enabled = v and true or false
            if ThugUI.ControllerMode then ThugUI.ControllerMode:NotifyFeature("chat") end
        end,
    }
    local function TargetSwitch(key, label, tooltip)
        panel:Checkbox{
            label = label,
            tooltip = tooltip,
            get = function()
                local c = ThugUIDB.ControllerTarget and ThugUIDB.ControllerTarget[key]
                return not (c and c.enabled == false)
            end,
            set = function(v)
                local db = ThugUIDB.ControllerTarget
                db[key] = db[key] or {}
                db[key].enabled = v and true or false
                if ThugUI.ControllerTarget then ThugUI.ControllerTarget:ApplyAll() end
            end,
        }
    end
    TargetSwitch("target", "Use the controller target frame",
        "Off: Blizzard's target frame is left alone. If ThugUI already switched it off this session, /reload brings it back.")
    panel:Checkbox{
        label = "Hide the objective tracker",
        tooltip = "The tracker stays invisible until you select it with D-pad up "
            .. "on the L1+R1 shortcuts, and the focused quest above the minimap stands "
            .. "in for it. Off: Blizzard's tracker shows as normal.",
        
        
        get = function()
            local c = ThugUIDB.ControllerObjectives
            return not (c and c.enabled == false)
        end,
        set = function(v)
            ThugUIDB.ControllerObjectives = ThugUIDB.ControllerObjectives or {}
            ThugUIDB.ControllerObjectives.enabled = v and true or false
            if ThugUI.ControllerMode then ThugUI.ControllerMode:NotifyFeature("objectives") end
        end,
    }
    TargetSwitch("tot", "Use the controller target-of-target frame",
        "Off: your own Target of Target frame (its page) takes over again, or Blizzard's if that is off.")
    
    
    
    if not (ThugUI.ControllerShortcuts and ThugUI.ControllerShortcuts.PAUSED) then
        panel:Checkbox{
            label = "Map on the shortcuts' bottom face button",
            tooltip = "Blizzard leaves that button empty on the shortcuts bar; this makes it open the world map. "
                .. "Off: the button is disabled again, as Blizzard has it.",
            
            
            get = function() return not (ThugUIDB.ControllerMode and ThugUIDB.ControllerMode.mapShortcut == false) end,
            set = function(v)
                ThugUIDB.ControllerMode = ThugUIDB.ControllerMode or {}
                ThugUIDB.ControllerMode.mapShortcut = v and true or false
                if ThugUI.ControllerMode then ThugUI.ControllerMode:NotifyFeature("mapShortcut") end
            end,
        }
    end
    
    


    
    
    panel:FrameSection{
        title = "Chat window",
        enabled = {
            get = function() return ThugUIDB.GamepadChat.enabled ~= false end,
            set = function(v)
                ThugUIDB.GamepadChat.enabled = v and true or false
                if ThugUI.ControllerMode then ThugUI.ControllerMode:NotifyFeature("chat") end
            end,
        },
        unlock = {
            get = function() return ThugUIDB.GamepadChat.unlocked end,
            set = function(val)
                ThugUIDB.GamepadChat.unlocked = val
                if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
            end,
        },
        reset = function()
            ThugUIDB.GamepadChat.point = nil
            if ThugUI.GamepadChat and ThugUI.GamepadChat.window then
                ThugUI.GamepadChat.window:ClearAllPoints()
                ThugUI.GamepadChat.window:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 100)
            end
        end,
    }
    panel:Part("Size & position")
    panel:Slider{
        label = "Window width",
        min = 300, max = 1000, step = 10, format = "%d",
        get = function() return ThugUIDB.GamepadChat.width end,
        set = function(val)
            ThugUIDB.GamepadChat.width = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }

    panel:Slider{
        label = "Window height",
        min = 100, max = 800, step = 10, format = "%d",
        get = function() return ThugUIDB.GamepadChat.height end,
        set = function(val)
            ThugUIDB.GamepadChat.height = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }

    panel:Part("Appearance")
    panel:Slider{
        label = "Font size",
        min = 10, max = 24, step = 1, format = "%d",
        get = function() return ThugUIDB.GamepadChat.fontSize end,
        set = function(val)
            ThugUIDB.GamepadChat.fontSize = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }

    panel:Slider{
        label = "Background opacity",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return ThugUIDB.GamepadChat.bgAlpha or 0.8 end,
        set = function(val)
            ThugUIDB.GamepadChat.bgAlpha = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }
    
    panel:Checkbox{
        label = "Timestamps",
        get = function() return ThugUIDB.GamepadChat.timestamps end,
        set = function(val)
            ThugUIDB.GamepadChat.timestamps = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }
    
    panel:Part("Content")
    panel:Checkbox{
        label = "Show whisper toast",
        get = function() return ThugUIDB.GamepadChat.toast end,
        set = function(val) ThugUIDB.GamepadChat.toast = val end,
    }

    panel:Slider{
        label = "Lines kept per tab",
        min = 100, max = 2000, step = 100, format = "%d",
        get = function() return ThugUIDB.GamepadChat.maxLines or 500 end,
        set = function(val)
            ThugUIDB.GamepadChat.maxLines = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }
    
    panel:Checkbox{
        label = "Fade when idle",
        get = function() return ThugUIDB.GamepadChat.fadeIdle end,
        set = function(val)
            ThugUIDB.GamepadChat.fadeIdle = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }
    
    panel:Slider{
        label = "Fade after (seconds)",
        min = 5, max = 120, step = 5, format = "%d",
        get = function() return ThugUIDB.GamepadChat.fadeAfter or 20 end,
        set = function(val)
            ThugUIDB.GamepadChat.fadeAfter = val
            if ThugUI.GamepadChat then ThugUI.GamepadChat:UpdateSettings() end
        end,
    }

    
    
    
    local function CS() return ThugUI.ControllerStream end
    local function SCfg() return CS() and CS():Cfg() or (ThugUIDB.ControllerStream or {}) end
    local function SApply() if CS() then CS():ApplySettings() end end
    panel:FrameSection{
        title = "Chat stream",
        enabled = {
            get = function() return SCfg().enabled ~= false end,
            set = function(v) SCfg().enabled = v and true or false; SApply() end,
        },
        unlock = {
            get = function() return CS() and CS().unlocked end,
            set = function(v) if CS() then CS():SetUnlocked(v) end end,
        },
        reset = function() if CS() then CS():ResetPosition() end end,
    }
    
    
    panel:SubSection("Size & look")
    panel:Note("Recent chat lines while the controller chat window is closed; it hides while the "
        .. "window is open. Tick Unlock to drag it into place. Separate from the chat acorn's stream.")
    panel:Part("Size & position")
    panel:Slider{
        label = "Stream width",
        min = 200, max = 900, step = 10, format = "%d",
        get = function() return SCfg().width or 420 end,
        set = function(v) SCfg().width = v; SApply() end,
    }
    panel:Slider{
        label = "Stream height",
        min = 60, max = 600, step = 10, format = "%d",
        get = function() return SCfg().height or 150 end,
        set = function(v) SCfg().height = v; SApply() end,
    }
    panel:Part("Appearance")
    panel:Slider{
        label = "Stream font size",
        min = 9, max = 24, step = 1, format = "%d",
        get = function() return SCfg().fontSize or 13 end,
        set = function(v) SCfg().fontSize = v; SApply() end,
    }
    panel:Slider{
        label = "Stream background opacity",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return SCfg().bgAlpha or 0 end,
        set = function(v) SCfg().bgAlpha = v; SApply() end,
    }
    panel:SubSection("Lines")
    panel:Part("Content")
    panel:Checkbox{
        label = "Stream timestamps",
        get = function() return SCfg().timestamps end,
        set = function(v) SCfg().timestamps = v and true or false end,
    }
    panel:Checkbox{
        label = "Lines fade",
        get = function() return SCfg().fade ~= false end,
        set = function(v) SCfg().fade = v and true or false; SApply() end,
    }
    panel:Slider{
        label = "Lines fade after (seconds)",
        min = 5, max = 120, step = 5, format = "%d",
        get = function() return SCfg().fadeAfter or 20 end,
        set = function(v) SCfg().fadeAfter = v; SApply() end,
    }
    panel:SubSection("What shows")
    panel:Part("Content")
    for _, cat in ipairs(CATEGORIES) do
        local id = cat.id
        panel:Checkbox{
            label = "Stream: " .. cat.title,
            tooltip = cat.tip,
            get = function() return SCfg().show and SCfg().show[id] end,
            set = function(v) SCfg().show = SCfg().show or {}; SCfg().show[id] = v and true or false end,
        }
    end
    panel:Checkbox{
        label = "Stream: every channel (Trade, General...)",
        tooltip = "Off: only the channels ticked below.",
        get = function() return SCfg().allChannels ~= false end,
        set = function(v) SCfg().allChannels = v and true or false end,
    }
    local okList, list = pcall(function() return { GetChannelList() } end)
    if okList and type(list) == "table" then
        
        
        for i = 2, #list, 3 do
            local name = list[i]
            if type(name) == "string" and not (issecretvalue and issecretvalue(name)) then
                panel:Checkbox{
                    label = "Stream channel: " .. name,
                    get = function() return SCfg().channels and SCfg().channels[name] end,
                    set = function(v) SCfg().channels = SCfg().channels or {}; SCfg().channels[name] = v and true or nil end,
                }
            end
        end
    end
    
    
    
    if ThugUI.Visibility then
        ThugUI.Visibility:AddControls(panel, "controllerStream", { split = true, moving = true, padReveal = true,
            afterWhen = function(p)
                p:Group("Stream rules (these win over everything on these tabs)")
                p:Checkbox{
                    label = "Always show in combat",
                    tooltip = "In combat the stream is fully shown, whatever Show, resting, moving or gamepad input would hide.",
                    get = function() return SCfg().showInCombat == true end,
                    set = function(v) SCfg().showInCombat = v and true or false; if CS() then CS():ApplyVisibility() end end,
                }
            end })
    end

    BuildTabsUI(panel)
end

ThugUI.Window:RegisterPage{
    id = "chat",
    
    scopeKeys = { "GamepadChat", "ControllerStream", "ControllerObjectives" },
    category = "controller",
    order = 10,
    title = "Mode & chat",
    summary = "Controller mode, which takeovers it uses, and the controller chat window.",
    build = function(host, panel) Build(panel) end,
    refresh = function() if UI.Layout then UI.Layout() end end,
}
