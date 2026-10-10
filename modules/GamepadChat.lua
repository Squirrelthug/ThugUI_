


















local ThugUI = _G.ThugUI
local GamepadChat = {}
ThugUI.GamepadChat = GamepadChat
ThugUI:RegisterModule("GamepadChat", GamepadChat)

ThugUI.defaults.GamepadChat = {
    point = nil,
    width = 520,
    height = 260,
    fontSize = 14,
    toast = true,
    unlocked = false,
    autoChannelTabs = true,
    timestamps = false,
    bgAlpha = 0.8,
    maxLines = 500,
    fadeIdle = false,
    fadeAfter = 20,
    enabled = true,   
}

local GC = GamepadChat
GC.active = false

local hookedFrames = setmetatable({}, {__mode = "k"})
local hookedAddMessage = setmetatable({}, {__mode = "k"})
local editBoxOriginals = setmetatable({}, {__mode = "k"})
local seen = setmetatable({}, {__mode = "k"})
local accepted = {}
local lastGetTime = 0

local reverseChatType = {}
local function BuildReverseChatType()
    wipe(reverseChatType)
    if _G.ChatTypeInfo then
        for chatType, info in pairs(_G.ChatTypeInfo) do
            if type(info) == "table" and info.id then
                reverseChatType[info.id] = chatType
            end
        end
    end
end

local CATEGORY_OF = {
    SAY = "say", YELL = "say", EMOTE = "say", TEXT_EMOTE = "say",
    WHISPER = "whisper", WHISPER_INFORM = "whisper", BN_WHISPER = "whisper", BN_WHISPER_INFORM = "whisper", AFK = "whisper", DND = "whisper",
    PARTY = "party", PARTY_LEADER = "party", INSTANCE_CHAT = "party", INSTANCE_CHAT_LEADER = "party",
    RAID = "raid", RAID_LEADER = "raid", RAID_WARNING = "raid",
    GUILD = "guild", OFFICER = "guild",
    SYSTEM = "system",
    LOOT = "loot", CURRENCY = "loot", MONEY = "loot", TRADESKILLS = "loot", OPENING = "loot",
    COMBAT_XP_GAIN = "progress", COMBAT_HONOR_GAIN = "progress", COMBAT_FACTION_CHANGE = "progress", SKILL = "progress",
    ACHIEVEMENT = "achievement", GUILD_ACHIEVEMENT = "achievement",
    MONSTER_SAY = "npc", MONSTER_YELL = "npc", MONSTER_EMOTE = "npc", MONSTER_WHISPER = "npc", RAID_BOSS_EMOTE = "npc", RAID_BOSS_WHISPER = "npc"
}











local function BaseChannelName(name)
    if type(name) ~= "string" then return name end
    local base = string.match(name, "^(.-)%s+%-%s+.+$") or name
    return string.match(base, "^(.-)%s+%b()$") or base
end
GC.BaseChannelName = BaseChannelName



local function IsCommunityChannel(name)
    return type(name) == "string" and string.sub(name, 1, 10) == "Community:"
end
GC.IsCommunityChannel = IsCommunityChannel



local function ChannelSet(channels)
    local set = {}
    for name, on in pairs(channels or {}) do
        if on then set[BaseChannelName(name)] = true end
    end
    return set
end

local tabObjects = {}
GC.tabObjects = tabObjects
local activeTab = "All"









local FALLBACK_FONT = "Fonts\\FRIZQT__.TTF"
local function ChatFont()
    local obj = _G.ChatFontNormal
    if obj and obj.GetFont then
        local path, _, flags = obj:GetFont()
        if type(path) == "string" then return path, flags or "" end
    end
    return FALLBACK_FONT, ""
end

local function UpdateTabVisibility()
    for _, tab in ipairs(GC.liveTabs) do
        if tab.name == activeTab then
            tab.smf:Show()
            ThugUI.Theme:Paint(tab.label, "tabSelected")
        else
            tab.smf:Hide()
            if tab.unread then
                ThugUI.Theme:Paint(tab.label, "label")  
            else
                ThugUI.Theme:Paint(tab.label, "disabled")
            end
        end
    end
end







local frameOf = setmetatable({}, { __mode = "k" })
local freeTabs = {}

local function NewTabFrame()
    local tab = {}
    local btn = CreateFrame("Button", nil, GC.window.tabContainer)
    btn:SetHeight(20)
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    tab.label = label
    tab.btn = btn

    local smf = CreateFrame("ScrollingMessageFrame", nil, GC.window.content)
    smf:SetPoint("TOPLEFT")
    smf:SetPoint("BOTTOMRIGHT")
    
    smf:SetJustifyH("LEFT")
    smf:SetHyperlinksEnabled(true)
    
    smf:EnableMouse(true)
    smf:EnableMouseWheel(true)
    smf:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    
    
    
    smf:SetScript("OnHyperlinkClick", function(self, link, text, button)
        if button ~= "LeftButton" then return end
        if issecretvalue and issecretvalue(link) then return end
        if string.sub(link, 1, 7) == "player:" or string.sub(link, 1, 8) == "BNplayer" then
            return
        end
        if _G.SetItemRef then _G.SetItemRef(link, text, "LeftButton") end
    end)
    smf:SetScript("OnHyperlinkEnter", function(self, link)
        if issecretvalue and issecretvalue(link) then return end
        if _G.GameTooltip then
            _G.GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            pcall(_G.GameTooltip.SetHyperlink, _G.GameTooltip, link)
            _G.GameTooltip:Show()
        end
    end)
    smf:SetScript("OnHyperlinkLeave", function()
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    tab.smf = smf
    table.insert(tabObjects, tab)
    return tab
end

function GC:RebuildTabs()
    if not GC.window then return end

    local allTabs = {}
    for _, ct in ipairs(ThugUIDB.GamepadChat.tabs or {}) do table.insert(allTabs, ct) end
    GC.sessionTabs = GC.sessionTabs or {}
    for _, st in ipairs(GC.sessionTabs) do table.insert(allTabs, st) end

    local previous = GC.liveTabs or {}
    local used = {}
    GC.liveTabs = {}
    local activeTabExists = false
    local prev

    for i, tData in ipairs(allTabs) do
        local tab = frameOf[tData]
        if not tab then
            tab = table.remove(freeTabs)
            if tab then
                if tab.smf.Clear then tab.smf:Clear() end
            else
                tab = NewTabFrame()
            end
            tab.unread = false
            frameOf[tData] = tab
        end
        used[tab] = true

        tab.name = tData.name
        tab.all = tData.all
        tab.show = tData.show or {}
        tab.channels = ChannelSet(tData.channels)
        tab.smf:SetMaxLines(ThugUIDB.GamepadChat.maxLines or 500)
        local font, flags = ChatFont()
        tab.smf:SetFont(font, ThugUIDB.GamepadChat.fontSize or 14, flags)

        tab.label:SetText(tData.name)
        tab.btn:SetWidth(tab.label:GetStringWidth() + 16)
        tab.btn:SetScript("OnClick", function()
            activeTab = tab.name
            tab.unread = false
            UpdateTabVisibility()
        end)
        tab.btn:ClearAllPoints()
        if not prev then
            tab.btn:SetPoint("LEFT", GC.window.tabContainer, "LEFT", 4, 0)
        else
            tab.btn:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        end
        prev = tab.btn
        tab.btn:Show()

        if tData.name == activeTab then activeTabExists = true end
        GC.liveTabs[i] = tab
    end

    for _, tab in ipairs(previous) do
        if not used[tab] then
            tab.btn:Hide()
            tab.smf:Hide()
            for k, v in pairs(frameOf) do
                if v == tab then frameOf[k] = nil end
            end
            table.insert(freeTabs, tab)
        end
    end

    if not activeTabExists then activeTab = "All" end
    UpdateTabVisibility()
end


local function ActiveTabObject()
    for _, tab in ipairs(GC.liveTabs or {}) do
        if tab.name == activeTab then return tab end
    end
end
GC.ActiveTabObject = ActiveTabObject



local function AddToCategory(category, text, r, g, b)
    for _, tab in ipairs(GC.liveTabs or {}) do
        if tab.all or (tab.show and tab.show[category]) then
            tab.smf:AddMessage(text, r, g, b)
            if activeTab ~= tab.name then tab.unread = true end
        end
    end
    UpdateTabVisibility()
end




GC.lineListeners = GC.lineListeners or {}
function GC:AddLineListener(fn)
    table.insert(self.lineListeners, fn)
end

local function RouteMessage(text, r, g, b, infoID)
    if issecretvalue and issecretvalue(infoID) then infoID = nil end
    local chatType = nil
    local via = "none"
    if infoID then
        if not reverseChatType[infoID] then BuildReverseChatType() end
        chatType = reverseChatType[infoID]
        if chatType then via = "table" end
        
        
        
        
        
        
        if not chatType and C_ChatInfo and C_ChatInfo.GetChatTypeName then
            local ok, name = pcall(C_ChatInfo.GetChatTypeName, infoID)
            if ok and type(name) == "string" and not (issecretvalue and issecretvalue(name)) then
                chatType = name
                via = "api"
            end
        end
    end
    
    local category = "system"
    local channelName = nil
    if chatType then
        category = CATEGORY_OF[chatType] or "system"
        if string.match(chatType, "^CHANNEL(%d+)$") then
            
            
            
            
            category = "channel"
            local num = tonumber(string.match(chatType, "^CHANNEL(%d+)$"))
            local ok, _, name = pcall(GetChannelName, num)
            if ok and name and not (issecretvalue and issecretvalue(name)) then
                if IsCommunityChannel(name) then
                    category = "guild"
                else
                    channelName = BaseChannelName(name)
                end
            end
        end
    end
    
    
    
    
    GC.routeLogged = (GC.routeLogged or 0) + 1
    if GC.routeLogged <= 40 and ThugUI.Diagnostics then
        local reverseCount = 0
        for _ in pairs(reverseChatType) do reverseCount = reverseCount + 1 end
        ThugUI.Diagnostics:Log("CHAT", "line %d: infoID=%s type=%s via=%s (table has %d) category=%s channel=%s",
            GC.routeLogged, type(infoID) == "number" and tostring(infoID) or type(infoID),
            tostring(chatType), via, reverseCount, tostring(category), tostring(channelName))
    end

    for i, fn in ipairs(GC.lineListeners) do
        local ok, err = pcall(fn, text, r, g, b, category, channelName)
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("chat-listener-" .. i .. "-" .. tostring(err), "CHAT",
                "line listener %d failed: %s", i, tostring(err))
        end
    end

    local isSecretText = type(text) ~= "string" or (issecretvalue and issecretvalue(text))
    local outText = text
    if ThugUIDB.GamepadChat.timestamps and not isSecretText then
        outText = date("%H:%M ") .. text
    end

    local handledChannel = false

    for _, tab in ipairs(GC.liveTabs) do
        local showLine = false
        if tab.all then
            showLine = true
        elseif tab.show and tab.show[category] then
            showLine = true
        elseif channelName and tab.channels and tab.channels[channelName] then
            showLine = true
        end
        
        if showLine then
            tab.smf:AddMessage(outText, r or 1, g or 1, b or 1)
            if activeTab ~= tab.name then
                tab.unread = true
            end
            if channelName and tab.channels and tab.channels[channelName] then
                handledChannel = true
            end
        end
    end
    
    if channelName and not handledChannel and ThugUIDB.GamepadChat.autoChannelTabs then
        GC.sessionChannels = GC.sessionChannels or {}
        GC.sessionTabs = GC.sessionTabs or {}
        if not GC.sessionChannels[channelName] then
            GC.sessionChannels[channelName] = true
            
            
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("CHAT", "auto tab created for channel %q", channelName)
            end
            table.insert(GC.sessionTabs, { name = channelName, channels = { [channelName] = true }, show = {} })
            GC:RebuildTabs()
            
            for _, tab in ipairs(GC.liveTabs) do
                if tab.name == channelName then
                    tab.smf:AddMessage(outText, r or 1, g or 1, b or 1)
                    if activeTab ~= tab.name then
                        tab.unread = true
                    end
                end
            end
        end
    end
    
    UpdateTabVisibility()
    
    if ThugUIDB.GamepadChat.toast and category == "whisper" and not GC.window:IsShown() then
        GC.toast.text:SetText(text)
        GC.toast.timer = 6
        GC.toast:Show()
    end
end
local function OnAddMessage(self, text, r, g, b, infoID)
    GC.hookCalls = (GC.hookCalls or 0) + 1
    if GC.hookCalls <= 5 and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("CHAT", "AddMessage on %s (call %d)",
            tostring(self.GetName and self:GetName()), GC.hookCalls)
    end
    local t = GetTime()
    if t ~= lastGetTime then
        wipe(seen)
        wipe(accepted)
        lastGetTime = t
    end
    
    if issecretvalue and issecretvalue(infoID) then infoID = nil end
    local key = (infoID or "print") .. "@" .. tostring(t)
    
    if not seen[self] then seen[self] = {} end
    seen[self][key] = (seen[self][key] or 0) + 1
    local currentAccept = accepted[key] or 0
    
    if seen[self][key] > currentAccept then
        accepted[key] = seen[self][key]
        RouteMessage(text, r, g, b, infoID)
    end
end

local function HookChatFrame(f)
    if not hookedFrames[f] then
        hookedFrames[f] = true
        f:HookScript("OnShow", function(self)
            if GC.active then self:Hide() end
        end)
        if GC.active then f:Hide() end
    end
end

local function HookAddMessage(f)
    if not hookedAddMessage[f] then
        hookedAddMessage[f] = true
        hooksecurefunc(f, "AddMessage", OnAddMessage)
    end
end

local function CheckCHAT_FRAMES()
    if _G.CHAT_FRAMES then
        for _, name in ipairs(_G.CHAT_FRAMES) do
            local f = _G[name]
            if f then
                HookChatFrame(f)
                HookAddMessage(f)
            end
        end
    end
end




local function Adopt(editBox)
    if not editBox or not GC.window then return end
    if not editBoxOriginals[editBox] then
        local pts = {}
        for i = 1, editBox:GetNumPoints() do
            local point, relTo, relPoint, x, y = editBox:GetPoint(i)
            table.insert(pts, {point, relTo, relPoint, x, y})
        end
        editBoxOriginals[editBox] = { parent = editBox:GetParent(), points = pts }
    end
    if editBox:GetParent() ~= GC.window.editContainer then
        editBox:SetParent(GC.window.editContainer)
        editBox:ClearAllPoints()
        editBox:SetPoint("LEFT", 4, 0)
        editBox:SetPoint("RIGHT", -4, 0)
    end
end







function GC:AdoptEditBoxes()
    if not GC.active or not GC.window or not _G.CHAT_FRAMES then return end
    for _, name in ipairs(_G.CHAT_FRAMES) do
        Adopt(_G[name .. "EditBox"])
    end
end

local function SetupHooks()
    if GC.hooksInstalled then return end
    GC.hooksInstalled = true
    
    CheckCHAT_FRAMES()
    
    local others = {"GeneralDockManager", "ChatFrameMenuButton", "ChatFrameChannelButton", "QuickJoinToastButton", "TextToSpeechButtonFrame"}
    for _, name in ipairs(others) do
        local f = _G[name]
        if f then HookChatFrame(f) end
    end
    
    if _G.FCF_OpenTemporaryWindow then
        hooksecurefunc("FCF_OpenTemporaryWindow", function(...)
            CheckCHAT_FRAMES()
            if GC.active then GC:AdoptEditBoxes() end
        end)
    end
    
    if _G.ChatFrameUtil then
        if _G.ChatFrameUtil.ActivateChat then
            hooksecurefunc(_G.ChatFrameUtil, "ActivateChat", function(editBox)
                if not GC.active then return end
                Adopt(editBox)
                GC.window.editContainer:Show()
                
                if not GC.window:IsShown() then
                    GC.window.openedByTyping = true
                    GC.window:Show()
                end
                GC:UpdateSettings()
            end)
        end
        if _G.ChatFrameUtil.DeactivateChat then
            hooksecurefunc(_G.ChatFrameUtil, "DeactivateChat", function(editBox)
                if not GC.active then return end
                if editBox:GetParent() ~= GC.window.editContainer then return end
                
                
                
                
                GC.window.editContainer:Hide()
                if GC.window.openedByTyping then
                    GC.window:Hide()
                end
                GC.window.openedByTyping = false
                GC:UpdateSettings()
            end)
        end
    end
end


function GC:Open()
    if not ThugUI.CombatClose:Allow("chat") then return end
    if not GC.window or GC.window:IsShown() then return end
    GC.window.openedByTyping = false
    GC.window:Show()
    GC:UpdateSettings()
end











local hookedShortcuts = {}
function GC:HookShortcuts()
    local bar = ThugUI.ControllerMode and ThugUI.ControllerMode:GetShortcutsBar()
    if not bar then
        if ThugUI.Diagnostics and not GC.shortcutsMissingLogged then
            GC.shortcutsMissingLogged = true
            ThugUI.Diagnostics:Log("CHAT", "shortcuts bar not found; D-pad down not hooked yet")
        end
        return false
    end
    for _, side in ipairs({ bar.Left, bar.Right }) do
        local b = side and side.ActionButton4
        if b and not hookedShortcuts[b] and b.HookScript then
            local ok = pcall(b.HookScript, b, "PostClick", function(self, _, down)
                if not down or self ~= bar.dpadBottomButton then return end
                local use = ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("chat")
                
                
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("CHAT", "shortcut chat button pressed; %s",
                        use and "opening the controller chat" or "controller chat not in use")
                end
                if use then GC:Open() end
            end)
            if ok then
                hookedShortcuts[b] = true
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("CHAT", "shortcuts D-pad down hook installed on %s",
                        side == bar.Left and "Left" or "Right")
                end
            end
        end
    end
    return true
end











local radialHooked = false
function GC:HookRadialChat()
    if radialHooked then return true end
    local radial = _G.GamepadRadial
    local opts = radial and radial.segmentOptions
    local chat = opts and opts.chat
    if type(chat) ~= "table" or type(chat.action) ~= "function" then return false end
    local ok = pcall(hooksecurefunc, chat, "action", function()
        local use = ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("chat")
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CHAT", "radial chat picked; %s",
                use and "opening the controller chat" or "controller chat not in use")
        end
        if use then GC:Open() end
    end)
    radialHooked = ok and true or false
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("CHAT", "radial chat hook %s", radialHooked and "installed" or "failed")
    end
    return radialHooked
end

function GC:Toggle()
    if not ThugUI:IsModuleOn("controller") then
        print("ThugUI: Controller is turned off on the Modules page.")
        return
    end
    if GC.window:IsShown() then
        GC.window:Hide()
    else
        if not ThugUI.CombatClose:Allow("chat") then return end
        GC.window.openedByTyping = false
        GC.window:Show()
        GC:UpdateSettings()
    end
end

SlashCmdList["THUGUICHAT"] = function() GC:Toggle() end

function GC:Apply(active)
    GC.active = active
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("CHAT", "controller chat %s; %d chat frame(s)",
            active and "on" or "off", _G.CHAT_FRAMES and #_G.CHAT_FRAMES or -1)
    end
    if active then
        SetupHooks()
        GC:HookShortcuts()
        GC:HookRadialChat()
        CheckCHAT_FRAMES()
        GC:AdoptEditBoxes()
        
        
        if _G.CHAT_FRAMES then
            for _, name in ipairs(_G.CHAT_FRAMES) do
                if _G[name] then _G[name]:Hide() end
            end
        end
        local others = {"GeneralDockManager", "ChatFrameMenuButton", "ChatFrameChannelButton", "QuickJoinToastButton", "TextToSpeechButtonFrame"}
        for _, name in ipairs(others) do
            local f = _G[name]
            if f then f:Hide() end
        end
    else
        if _G.ChatFrame1 then _G.ChatFrame1:Show() end
        for _, name in ipairs({"GeneralDockManager", "ChatFrameMenuButton", "ChatFrameChannelButton", "QuickJoinToastButton"}) do
            if _G[name] then _G[name]:Show() end
        end
        GC.window:Hide()
        
        for editBox, orig in pairs(editBoxOriginals) do
            if editBox:GetParent() == GC.window.editContainer then
                editBox:SetParent(orig.parent)
                editBox:ClearAllPoints()
                for _, p in ipairs(orig.points) do
                    editBox:SetPoint(p[1], p[2], p[3], p[4], p[5])
                end
            end
        end
    end
end


local function CycleTab(step)
    if not GC.liveTabs or #GC.liveTabs == 0 then return end
    local idx = 1
    for i, tab in ipairs(GC.liveTabs) do
        if tab.name == activeTab then
            idx = i
            break
        end
    end
    idx = idx + step
    if idx < 1 then idx = #GC.liveTabs elseif idx > #GC.liveTabs then idx = 1 end
    activeTab = GC.liveTabs[idx].name
    GC.liveTabs[idx].unread = false
    UpdateTabVisibility()
end

local function WindowPad(self, button)
    if InCombatLockdown() then return end
    local handled = false
    if button == (GAMEPAD_SHOULDER_LEFT or "PADLSHOULDER") or button == (GAMEPAD_DPAD_LEFT or "PADDLEFT") then
        CycleTab(-1)
        handled = true
    elseif button == (GAMEPAD_SHOULDER_RIGHT or "PADRSHOULDER") or button == (GAMEPAD_DPAD_RIGHT or "PADDRIGHT") then
        CycleTab(1)
        handled = true
    elseif button == (GAMEPAD_DPAD_TOP or "PADDUP") then
        local tab = ActiveTabObject()
        if tab then tab.smf:ScrollUp() end
        handled = true
    elseif button == (GAMEPAD_DPAD_BOTTOM or "PADDDOWN") then
        local tab = ActiveTabObject()
        if tab then tab.smf:ScrollDown() end
        handled = true
    elseif button == (GAMEPAD_FACE_RIGHT or "PAD2") then
        local editActive = false
        for editBox, _ in pairs(editBoxOriginals) do
            if editBox:GetParent() == GC.window.editContainer and editBox:HasFocus() then
                editActive = true
                break
            end
        end
        if not editActive then
            GC.window:Hide()
            handled = true
        end
    end
    
    if not handled then
        self:SetPropagateKeyboardInput(true)
    else
        self:SetPropagateKeyboardInput(false)
    end
end

function GC:Initialize()
    _G.BINDING_HEADER_THUGUI = "ThugUI"
    _G.BINDING_NAME_THUGUI_TOGGLECHAT = "Toggle controller chat"
    _G.SLASH_THUGUICHAT1 = "/thugchat"

    BuildReverseChatType()
    
    local w = CreateFrame("Frame", "ThugUI_GamepadChatFrame", UIParent)
    GC.window = w
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("chat", function() return GC.window and GC.window:IsShown() end, function() GC.window:Hide() end)
    end
    w:SetFrameStrata("DIALOG")
    w:SetSize(ThugUIDB.GamepadChat.width, ThugUIDB.GamepadChat.height)
    if ThugUIDB.GamepadChat.point then
        local p = ThugUIDB.GamepadChat.point
        w:SetPoint(p[1], UIParent, p[2], p[3], p[4])  
    else
        w:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 100)
    end
    
    local bg = w:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    
    local tr, tg, tb = ThugUI.Theme:Color("background")
    bg:SetColorTexture(tr, tg, tb, ThugUIDB.GamepadChat.bgAlpha or 0.8)
    w.bg = bg
    
    w.tabContainer = CreateFrame("Frame", nil, w)
    w.tabContainer:SetPoint("TOPLEFT")
    w.tabContainer:SetPoint("TOPRIGHT")
    w.tabContainer:SetHeight(24)
    
    local gear = CreateFrame("Button", nil, w.tabContainer)
    gear:SetSize(20, 20)
    gear:SetPoint("RIGHT", w.tabContainer, "RIGHT", -4, 0)
    gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    gear:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
    gear:EnableMouse(true)
    gear:SetScript("OnClick", function()
        ThugUI.Window:Open("chat")
    end)
    gear:SetScript("OnEnter", function(self)
        if _G.GameTooltip then
            _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            _G.GameTooltip:SetText("Chat settings")
            _G.GameTooltip:Show()
        end
    end)
    gear:SetScript("OnLeave", function()
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    
    w.editContainer = CreateFrame("Frame", nil, w)
    w.editContainer:SetPoint("BOTTOMLEFT")
    w.editContainer:SetPoint("BOTTOMRIGHT")
    w.editContainer:SetHeight(28)
    w.editContainer:Hide()
    
    w.content = CreateFrame("Frame", nil, w)
    w.content:SetPoint("TOPLEFT", w.tabContainer, "BOTTOMLEFT", 8, -4)
    w.content:SetPoint("BOTTOMRIGHT", w.editContainer, "TOPRIGHT", -8, 4)
    
    w:EnableMouseWheel(true)
    w:SetScript("OnMouseWheel", function(self, delta)
        local tab = ActiveTabObject()
        if tab then
            if delta > 0 then tab.smf:ScrollUp() else tab.smf:ScrollDown() end
        end
    end)
    
    w:Hide()
    
    if type(ThugUIDB.GamepadChat.tabs) ~= "table" then
        
        ThugUIDB.GamepadChat.tabs = {
            { name = "All", all = true, show = {}, channels = {} },
            { name = "Say", show = { say = true }, channels = {} },
            { name = "Whisper", show = { whisper = true }, channels = {} },
            { name = "Party", show = { party = true, raid = true }, channels = {} },
            { name = "Guild", show = { guild = true }, channels = {} }
        }
    end
    GC.sessionTabs = {}
    GC.sessionChannels = {}
    GC:RebuildTabs()
    
    local toast = CreateFrame("Button", "ThugUI_GamepadChatToast", UIParent)
    GC.toast = toast
    toast:SetSize(300, 60)
    toast:SetPoint("BOTTOM", w, "TOP", 0, 10)
    local tbg = toast:CreateTexture(nil, "BACKGROUND")
    tbg:SetAllPoints()
    ThugUI.Theme:Paint(tbg, "listBackground", "fill")
    local ttitle = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ttitle:SetPoint("TOPLEFT", 8, -8)
    ttitle:SetText("New whisper")
    toast.text = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toast.text:SetPoint("TOPLEFT", ttitle, "BOTTOMLEFT", 0, -4)
    toast.text:SetPoint("RIGHT", -8, 0)
    toast.text:SetJustifyH("LEFT")
    toast:Hide()
    toast:SetScript("OnClick", function()
        toast:Hide()
        if not GC.window:IsShown() then
            GC.window.openedByTyping = false
            GC.window:Show()
        end
        for _, tab in ipairs(GC.liveTabs or {}) do
            if not tab.all and tab.show and tab.show.whisper then
                activeTab = tab.name
                tab.unread = false
                break
            end
        end
        UpdateTabVisibility()
    end)
    toast:SetScript("OnUpdate", function(self, elapsed)
        if self.timer then
            self.timer = self.timer - elapsed
            if self.timer <= 0 then
                self:Hide()
            end
        end
    end)
    
    w:SetScript("OnShow", function(self)
        if not InCombatLockdown() then
            if self.EnableGamePadButton then pcall(self.EnableGamePadButton, self, true) end
            self:SetPropagateKeyboardInput(false)
        end
    end)
    w:SetScript("OnHide", function(self)
        if not InCombatLockdown() then
            if self.EnableGamePadButton then pcall(self.EnableGamePadButton, self, false) end
        end
    end)
    w:SetScript("OnGamePadButtonDown", WindowPad)
    
    ThugUI.SafeRegisterEvent(w, "PLAYER_REGEN_DISABLED")
    ThugUI.SafeRegisterEvent(w, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(w, "UI_ERROR_MESSAGE")
    w:HookScript("OnEvent", function(self, event, arg1, arg2)
        if event == "PLAYER_REGEN_DISABLED" then
            if self.EnableGamePadButton then pcall(self.EnableGamePadButton, self, false) end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if self:IsShown() then
                if self.EnableGamePadButton then pcall(self.EnableGamePadButton, self, true) end
                self:SetPropagateKeyboardInput(false)
            end
        elseif event == "UI_ERROR_MESSAGE" then
            if arg2 then AddToCategory("system", arg2, 1, 0.1, 0.1) end
        end
    end)
    
    GC:UpdateSettings()

    
    
    if C_Timer and C_Timer.After then
        local probe = CreateFrame("Frame")
        probe:RegisterEvent("PLAYER_LOGIN")
        probe:SetScript("OnEvent", function(self)
            if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
            self:UnregisterAllEvents()
            C_Timer.After(3, function()
                
                
                if GC.active then GC:HookShortcuts() end
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("CHAT", "3s after login: active=%s ChatFrame1 shown=%s",
                        tostring(GC.active), tostring(_G.ChatFrame1 and _G.ChatFrame1:IsShown()))
                end
            end)
        end)
    end

    if _G.EventRegistry and _G.EventRegistry.RegisterCallback then
        _G.EventRegistry:RegisterCallback("Gamepad.ShowMainMenu", function()
            GC:HookRadialChat()
        end, GC)
    end

    if ThugUI.ControllerMode then
        
        
        ThugUI.ControllerMode:RegisterFeatureCallback("chat", function(on) GC:Apply(on) end)
        ThugUI.ControllerMode:RegisterCallback(function()
            GC:Apply(ThugUI.ControllerMode:Uses("chat"))
        end)
    end
end


GC.WindowPad = WindowPad
function GC:GetActiveTab() return activeTab end

function GC:UpdateSettings()
    if not GC.window then return end
    GC.window:SetSize(ThugUIDB.GamepadChat.width, ThugUIDB.GamepadChat.height)
    if GC.window.bg then
        local tr, tg, tb = ThugUI.Theme:Color("background")
        GC.window.bg:SetColorTexture(tr, tg, tb, ThugUIDB.GamepadChat.bgAlpha or 0.8)
    end
    if ThugUIDB.GamepadChat.unlocked then
        GC.window:SetMovable(true)
        GC.window:EnableMouse(true)
        GC.window:RegisterForDrag("LeftButton")
        GC.window:SetScript("OnDragStart", function(self) self:StartMoving() end)
        GC.window:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local p1, _, p2, x, y = self:GetPoint()
            ThugUIDB.GamepadChat.point = {p1, p2, x, y}
            self:SetUserPlaced(false)
        end)
    else
        GC.window:SetMovable(false)
        GC.window:EnableMouse(false)
        GC.window:RegisterForDrag()
        GC.window:SetScript("OnDragStart", nil)
        GC.window:SetScript("OnDragStop", nil)
    end
    if GC.liveTabs then
        for _, tab in pairs(GC.liveTabs) do
            local font, flags = ChatFont()
            tab.smf:SetFont(font, ThugUIDB.GamepadChat.fontSize or 14, flags)
            tab.smf:SetMaxLines(ThugUIDB.GamepadChat.maxLines or 500)
            
            
            if ThugUIDB.GamepadChat.fadeIdle and GC.window:IsShown() and not GC.window.openedByTyping then
                tab.smf:SetFading(true)
                tab.smf:SetTimeVisible(ThugUIDB.GamepadChat.fadeAfter or 20)
            else
                tab.smf:SetFading(false)
            end
        end
    end
end
