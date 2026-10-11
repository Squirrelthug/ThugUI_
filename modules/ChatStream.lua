




























local MODULE_NAME = "ChatStream"
local MEDIA_PATH = "Interface\\AddOns\\ThugUI\\media\\"

local CS = {}
ThugUI.ChatStream = CS
ThugUI:RegisterModule(MODULE_NAME, CS)


local db
local dbChat
local anchorFrame
local streamChatFrame
local streamMessageFrame


local CHAT_MODE_NORMAL = 1
local CHAT_MODE_STREAM = 2
local CHAT_MODE_HIDDEN = 3
CS.MODE = { NORMAL = CHAT_MODE_NORMAL, STREAM = CHAT_MODE_STREAM, HIDDEN = CHAT_MODE_HIDDEN }
















local CHANNEL_KEY_BY_EVENT = {
    CHAT_MSG_SAY                  = "SAY",
    CHAT_MSG_YELL                 = "YELL",
    CHAT_MSG_EMOTE                = "EMOTE",
    CHAT_MSG_TEXT_EMOTE           = "EMOTE",
    CHAT_MSG_WHISPER              = "WHISPER",
    CHAT_MSG_WHISPER_INFORM       = "WHISPER",
    CHAT_MSG_BN_WHISPER           = "WHISPER",
    CHAT_MSG_BN_WHISPER_INFORM    = "WHISPER",
    CHAT_MSG_PARTY                = "PARTY",
    CHAT_MSG_PARTY_LEADER         = "PARTY",
    CHAT_MSG_INSTANCE_CHAT        = "PARTY",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "PARTY",
    CHAT_MSG_RAID                 = "RAID",
    CHAT_MSG_RAID_LEADER          = "RAID",
    CHAT_MSG_RAID_WARNING         = "RAID",
    CHAT_MSG_GUILD                = "GUILD",
    CHAT_MSG_OFFICER              = "OFFICER",
    CHAT_MSG_CHANNEL              = "CHANNEL",
    CHAT_MSG_SYSTEM               = "SYSTEM",
}










local CHANNEL_LABEL = {
    SAY     = "Say",
    YELL    = "Yell",
    EMOTE   = "Emote",
    WHISPER = "Whisper",
    PARTY   = "Party",
    RAID    = "Raid",
    GUILD   = "Guild",
    OFFICER = "Officer",
    SYSTEM  = "System",
}


local FALLBACK_COLOR = { r = 1, g = 1, b = 1 }








local function GetChatColor(event, channelIndex)
    local info
    local chatType = event and event:sub(10) 
    
    
    local types = _G.ChatTypeInfo or {}

    if chatType == "CHANNEL" and channelIndex and channelIndex > 0 then
        info = types["CHANNEL" .. channelIndex]
    end
    if not info and chatType then
        info = types[chatType]
    end

    info = info or FALLBACK_COLOR
    return info.r or 1, info.g or 1, info.b or 1
end









local issecret = _G.issecretvalue
local canaccess = _G.canaccessvalue

local function IsUsable(value)
    if value == nil then return false end
    if issecret and issecret(value) then return false end
    if canaccess and not canaccess(value) then return false end
    return true
end


local CHANNEL_TOGGLES = {
    { key = "SAY",     label = "Say" },
    { key = "EMOTE",   label = "Emote" },
    { key = "YELL",    label = "Yell" },
    { key = "WHISPER", label = "Whisper" },
    { key = "PARTY",   label = "Party" },
    { key = "RAID",    label = "Raid" },
    { key = "GUILD",   label = "Guild" },
    { key = "OFFICER", label = "Officer" },
    { key = "CHANNEL", label = "Trade/Gen" },
    { key = "SYSTEM",  label = "System" },
}
CS.STREAM_CHANNELS = CHANNEL_TOGGLES  


local pendingCombatActions = {}

local function QueueCombatAction(actionFunc)
    if InCombatLockdown() then
        table.insert(pendingCombatActions, actionFunc)
        return true
    end
    actionFunc()
    return false
end


local combatEventFrame = CreateFrame("Frame")
combatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEventFrame:SetScript("OnEvent", function(self, event)
    if not ThugUI:IsModuleOn("chatstream") then self:UnregisterAllEvents() return end
    if event == "PLAYER_REGEN_ENABLED" then
        for _, actionFunc in ipairs(pendingCombatActions) do
            actionFunc()
        end
        wipe(pendingCombatActions)
    end
end)



function CS:CreateStreamChatFrame()
    if streamChatFrame then return end

    local frame = CreateFrame("Frame", "ThugUI_StreamChatFrame", UIParent)
    frame:SetSize(dbChat.streamWidth or 420, dbChat.streamHeight or 220)
    frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10)
    frame:SetFrameStrata("BACKGROUND")
    
    
    
    
    

    
    local smf = CreateFrame("ScrollingMessageFrame", "ThugUI_StreamChatMessageFrame", frame)
    smf:SetAllPoints(frame)
    
    local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    smf:SetFont(fontPath, dbChat.fontSize or 14, dbChat.fontOutline or "OUTLINE")
    smf:SetShadowColor(0, 0, 0, 0.9)
    smf:SetShadowOffset(1, -1)
    smf:SetMaxLines(250)
    smf:SetFading(false)
    smf:SetJustifyH("LEFT")
    smf:EnableMouseWheel(true)
    
    smf:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            if IsShiftKeyDown() then
                self:ScrollToTop()
            else
                self:ScrollUp()
            end
        else
            if IsShiftKeyDown() then
                self:ScrollToBottom()
            else
                self:ScrollDown()
            end
        end
    end)

    
    
    local resizeGrip = CreateFrame("Button", nil, frame)
    frame.resizeGrip = resizeGrip
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resizeGrip:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
            frame.isResizing = true
        end
    end)
    
    resizeGrip:SetScript("OnMouseUp", function(self, button)
        if frame.isResizing then
            frame:StopMovingOrSizing()
            frame.isResizing = false
            local w, h = frame:GetSize()
            dbChat.streamWidth = math.floor(w + 0.5)
            dbChat.streamHeight = math.floor(h + 0.5)
        end
    end)
    
    frame:SetResizable(true)
    
    
    
    
    frame:SetResizeBounds(200, 100, 1000, 800)

    
    
    local outline = frame:CreateTexture(nil, "BACKGROUND")
    outline:SetAllPoints()
    outline:SetColorTexture(0.2, 1.0, 0.5, 0.12)
    outline:Hide()
    frame.unlockFill = outline

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p1, _, p2, x, y = self:GetPoint()
        dbChat.streamPoint = { p1, p2, x, y }
        self:SetUserPlaced(false)
    end)

    streamChatFrame = frame
    streamMessageFrame = smf

    self:ApplyStreamLock()
    self:ApplyStreamVisibility()
    
    self:RenderStream()
end



local function AnchorStream()
    if not streamChatFrame then return end
    streamChatFrame:ClearAllPoints()
    local p = dbChat and dbChat.streamPoint
    if p then
        streamChatFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        streamChatFrame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10)
    end
end
CS.AnchorStream = AnchorStream



function CS:ApplyStreamLock()
    local frame = streamChatFrame
    if not frame then return end
    local unlocked = dbChat and dbChat.streamUnlocked and true or false
    if frame.resizeGrip then frame.resizeGrip:SetShown(unlocked) end
    if frame.unlockFill then frame.unlockFill:SetShown(unlocked) end
    frame:SetMovable(unlocked)
    frame:EnableMouse(unlocked)
    if unlocked then frame:RegisterForDrag("LeftButton") else frame:RegisterForDrag() end
end

function CS:SetStreamUnlocked(on)
    dbChat.streamUnlocked = on and true or false
    self:ApplyStreamLock()
    self:ApplyStreamVisibility()
end







function CS:StreamAlpha(alpha)
    if dbChat and dbChat.streamUnlocked then return 1 end
    local V = ThugUI.Visibility
    if dbChat and dbChat.streamShowInCombat == true and V and V:InCombat() then return 1 end
    return alpha or 1
end

function CS:ApplyStreamVisibility()
    if not streamChatFrame then return end
    local V = ThugUI.Visibility
    streamChatFrame:SetAlpha(self:StreamAlpha(V and V:CurrentAlpha("acornStream") or 1))
end

function CS:SetStreamSize(w, h)
    if w then dbChat.streamWidth = w end
    if h then dbChat.streamHeight = h end
    if streamChatFrame then
        streamChatFrame:SetSize(dbChat.streamWidth or 420, dbChat.streamHeight or 220)
    end
end


function CS:ResetStream()
    dbChat.streamPoint = nil
    dbChat.streamWidth, dbChat.streamHeight = 420, 220
    if streamChatFrame then
        streamChatFrame:SetSize(420, 220)
        AnchorStream()
    end
end

















local STREAM_LOG_MAX = 500
local streamLog = {}
CS.streamLog = streamLog  

local function StreamChannelOn(key)
    return not (dbChat and dbChat.channels and dbChat.channels[key] == false)
end

local function StreamLine(entry)
    if dbChat and dbChat.showTimestamp then
        return "|cff888888" .. entry.stamp .. "|r " .. entry.text
    end
    return entry.text
end



function CS:RenderStream()
    if not streamMessageFrame then return end
    streamMessageFrame:Clear()
    for _, entry in ipairs(streamLog) do
        if StreamChannelOn(entry.key) then
            streamMessageFrame:AddMessage(StreamLine(entry), entry.r, entry.g, entry.b)
        end
    end
end


function CS:SetStreamChannel(key, on)
    dbChat.channels = dbChat.channels or {}
    dbChat.channels[key] = on and true or false
    self:RenderStream()
end

local function PushStreamEntry(entry)
    table.insert(streamLog, entry)
    if #streamLog > STREAM_LOG_MAX then table.remove(streamLog, 1) end
    if streamMessageFrame and StreamChannelOn(entry.key) then
        streamMessageFrame:AddMessage(StreamLine(entry), entry.r, entry.g, entry.b)
    end
end





local chatEventFrame
function CS:RegisterChatEvents()
    if chatEventFrame then return end
    local eventFrame = CreateFrame("Frame")
    chatEventFrame = eventFrame
    CS.chatEventFrame = eventFrame  

    for ev in pairs(CHANNEL_KEY_BY_EVENT) do
        ThugUI.SafeRegisterEvent(eventFrame, ev)
    end

    
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        local channelKey = CHANNEL_KEY_BY_EVENT[event]
        if not channelKey then return end

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        local discard, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12

        if ChatFrameUtil and ChatFrameUtil.ProcessMessageEventFilters then
            discard, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12 =
                ChatFrameUtil.ProcessMessageEventFilters(ChatFrame1, event, ...)
            if discard then return end 
        else
            a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12 = ...
        end

        local message         = a1
        local sender          = a2
        local channelName     = a4
        local channelIndex    = a8
        local channelBaseName = a9
        local lineID          = a11
        local guid            = a12

        if not IsUsable(message) then return end

        
        
        
        
        
        
        
        local npcLine
        local TRP3 = _G.TRP3_API
        if message == " " and TRP3 and TRP3.chat and TRP3.chat.getNPCMessageID then
            if TRP3.chat.getNPCMessageID() == lineID then
                local npcName = TRP3.chat.getNPCMessageName and TRP3.chat.getNPCMessageName()
                if IsUsable(npcName) and npcName ~= "" then
                    npcLine = npcName
                end
            end
        end

        
        
        
        local shortSender = "Unknown"
        if IsUsable(sender) then
            shortSender = sender:match("([^%-]+)") or sender
        end

        local colorHex
        if IsUsable(guid) then
            local ok, _, class = pcall(GetPlayerInfoByGUID, guid)
            if ok and IsUsable(class) and ThugUI.classColors[class] then
                local r, g, b = unpack(ThugUI.classColors[class])
                colorHex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
            end
        end

        local displaySender = colorHex
            and string.format("|cff%s%s|r", colorHex, shortSender)
            or shortSender

        
        
        
        local tag = ""
        if channelKey == "CHANNEL" then
            
            local name = IsUsable(channelBaseName) and channelBaseName
                      or IsUsable(channelName) and channelName
                      or "Chan"
            
            
            
            local GC = ThugUI.GamepadChat
            if GC and GC.BaseChannelName then name = GC.BaseChannelName(name) end
            tag = string.format("[%s] ", name)
        elseif CHANNEL_LABEL[channelKey] then
            tag = string.format("[%s] ", CHANNEL_LABEL[channelKey])
        end

        
        
        local timestamp = ""

        
        
        
        
        
        
        
        local formattedMsg
        if npcLine then
            formattedMsg = string.format("%s%s%s", timestamp, tag, npcLine)
        elseif event == "CHAT_MSG_TEXT_EMOTE" or event == "CHAT_MSG_SYSTEM" then
            formattedMsg = string.format("%s%s%s", timestamp, tag, message)
        elseif event == "CHAT_MSG_EMOTE" then
            formattedMsg = string.format("%s%s%s %s", timestamp, tag, displaySender, message)
        else
            formattedMsg = string.format("%s%s%s: %s", timestamp, tag, displaySender, message)
        end

        
        
        
        
        local index = IsUsable(channelIndex) and tonumber(channelIndex) or nil
        local r, g, b = GetChatColor(event, index)
        PushStreamEntry({ key = channelKey, text = formattedMsg, r = r, g = g, b = b,
            stamp = date("%H:%M") })
    end)
end















local editBoxHost

local function EnsureEditBoxHost()
    if editBoxHost then return editBoxHost end
    editBoxHost = CreateFrame("Frame", nil, UIParent)
    editBoxHost:SetAllPoints(UIParent)
    editBoxHost:Hide()

    if ChatFrameUtil and ChatFrameUtil.ActivateChat then
        hooksecurefunc(ChatFrameUtil, "ActivateChat", function(editBox)
            if editBox and editBox:GetParent() == editBoxHost then editBoxHost:Show() end
        end)
    end
    if ChatFrameUtil and ChatFrameUtil.DeactivateChat then
        hooksecurefunc(ChatFrameUtil, "DeactivateChat", function(editBox)
            if editBox and editBox:GetParent() == editBoxHost then editBoxHost:Hide() end
        end)
    end
    return editBoxHost
end




local function SetChatExtrasHidden(hidden)
    if hidden then
        local host = EnsureEditBoxHost()
        for _, name in ipairs(_G.CHAT_FRAMES or {}) do
            local box = _G[name .. "EditBox"]
            if box and box:GetParent() == UIParent then box:SetParent(host) end
        end
        if QuickJoinToastButton then QuickJoinToastButton:Hide() end
    else
        for _, name in ipairs(_G.CHAT_FRAMES or {}) do
            local box = _G[name .. "EditBox"]
            if box and editBoxHost and box:GetParent() == editBoxHost then box:SetParent(UIParent) end
        end
        if QuickJoinToastButton then QuickJoinToastButton:Show() end
    end
end
CS.SetChatExtrasHidden = SetChatExtrasHidden  

function CS:SetChatMode(mode)
    
    
    
    dbChat.mode = mode

    QueueCombatAction(function()
        local chatFrame1 = ChatFrame1
        local dock = GeneralDockManager

        if mode == CHAT_MODE_NORMAL then
            
            if chatFrame1 then
                chatFrame1:Show()
                chatFrame1:ClearAllPoints()
                chatFrame1:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10)
            end
            if dock then dock:Show() end
            if streamChatFrame then streamChatFrame:Hide() end
            SetChatExtrasHidden(false)

        elseif mode == CHAT_MODE_STREAM then
            
            if chatFrame1 then chatFrame1:Hide() end
            if dock then dock:Hide() end
            SetChatExtrasHidden(true)

            CS:CreateStreamChatFrame()
            streamChatFrame:Show()
            AnchorStream()

        elseif mode == CHAT_MODE_HIDDEN then
            
            if chatFrame1 then chatFrame1:Hide() end
            if dock then dock:Hide() end
            if streamChatFrame then streamChatFrame:Hide() end
            SetChatExtrasHidden(true)
        end
    end)
    
    
    CS:UpdateButton()
end

function CS:CycleChatMode()
    local nextMode = dbChat.mode + 1
    if nextMode > CHAT_MODE_HIDDEN then
        nextMode = CHAT_MODE_NORMAL
    end
    self:SetChatMode(nextMode)
end






local DEFAULT_POINT, DEFAULT_X, DEFAULT_Y = "BOTTOMLEFT", 25, 220

local function AnchorSize()
    return (dbChat and dbChat.size) or 36
end



local function BoxHeight()
    if dbChat and dbChat.mode == CHAT_MODE_STREAM then return dbChat.streamHeight or 220 end
    local h = ChatFrame1 and ChatFrame1.GetHeight and ChatFrame1:GetHeight()
    if type(h) ~= "number" or h <= 0 then h = 120 end
    return h
end






function CS.CentredLeftY(size, height)
    return math.floor(size / 2 + 10 + height / 2 + 0.5)
end

local function PlaceAnchor()
    if not anchorFrame then return end
    local size = AnchorSize()
    anchorFrame:SetSize(size, size)
    anchorFrame:ClearAllPoints()
    local p = dbChat.point or DEFAULT_POINT
    anchorFrame:SetPoint(p, UIParent, p, dbChat.x or DEFAULT_X, dbChat.y or DEFAULT_Y)
end



function CS:UpdateAnchors()
    QueueCombatAction(function()
        PlaceAnchor()
        if dbChat.mode == CHAT_MODE_NORMAL and ChatFrame1 then
            ChatFrame1:ClearAllPoints()
            ChatFrame1:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10)
        elseif dbChat.mode == CHAT_MODE_STREAM and streamChatFrame then
            AnchorStream()
        end
    end)
end



function CS:ApplyAnchorLock()
    if not anchorFrame then return end
    local on = dbChat.anchorUnlocked == true
    anchorFrame:EnableMouse(on)
    anchorFrame:SetMovable(on)
    if on then anchorFrame:RegisterForDrag("LeftButton") else anchorFrame:RegisterForDrag() end
    anchorFrame.fill:SetShown(on)
    anchorFrame.label:SetShown(on)
end

function CS:SetAnchorUnlocked(on)
    dbChat.anchorUnlocked = on and true or false
    self:ApplyAnchorLock()
end


function CS:ResetPosition()
    dbChat.point, dbChat.x = "LEFT", 20
    dbChat.y = CS.CentredLeftY(AnchorSize(), BoxHeight())
    self:UpdateAnchors()
end

local function CreateAnchor()
    if anchorFrame then return anchorFrame end
    local a = CreateFrame("Frame", "ThugUI_ChatStreamAnchor", UIParent)
    a:SetFrameStrata("HIGH")
    a:SetClampedToScreen(true)
    a.fill = a:CreateTexture(nil, "BACKGROUND")
    a.fill:SetAllPoints()
    a.fill:SetColorTexture(0.2, 0.7, 1.0, 0.35)
    a.label = a:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    a.label:SetPoint("BOTTOMLEFT", a, "TOPLEFT", 0, 2)
    a.label:SetText("Chat\n|cffffffffdrag to move|r")
    a:SetScript("OnDragStart", function(self) self:StartMoving() end)
    a:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        dbChat.point = point
        dbChat.x = math.floor(x + 0.5)
        dbChat.y = math.floor(y + 0.5)
        self:SetUserPlaced(false)
        CS:UpdateAnchors()
    end)
    anchorFrame = a
    CS.anchor = a
    PlaceAnchor()
    CS:ApplyAnchorLock()
    return a
end





local BUTTON_SIZE, ICON_SIZE, RIM_OFFSET = 32, 20, 5
local DEFAULT_ANGLE = 200
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end



local TINT = {
    [CHAT_MODE_NORMAL] = { 0.55, 0.82, 1.00, 1 },
    [CHAT_MODE_STREAM] = { 0.55, 1.00, 0.72, 1 },
    [CHAT_MODE_HIDDEN] = { 0.55, 0.55, 0.58, 0.85 },
}
CS.TINT = TINT
local MODE_NAME = { [CHAT_MODE_NORMAL] = "Blizzard chat", [CHAT_MODE_STREAM] = "Stream", [CHAT_MODE_HIDDEN] = "Hidden" }



local function Docked(button)
    return button:GetParent() ~= Minimap
end

function CS:UpdateButtonPosition()
    local b = self.button
    if not b or not Minimap or Docked(b) then return end
    local angle = dbChat.iconAngle or DEFAULT_ANGLE
    local radius = (Minimap:GetWidth() or 140) / 2 + RIM_OFFSET
    local rad = math.rad(angle)
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", radius * math.cos(rad), radius * math.sin(rad))
end

local function OnDragUpdate(button)
    if Docked(button) then return end
    local mx, my = Minimap:GetCenter()
    if not mx then return end
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if scale and scale > 0 then px, py = px / scale, py / scale end
    dbChat.iconAngle = math.deg(atan2(py - my, px - mx))
    CS:UpdateButtonPosition()
end

function CS:UpdateButton()
    local b = self.button
    if not b then return end
    local t = TINT[dbChat.mode] or TINT[CHAT_MODE_NORMAL]
    b.icon:SetVertexColor(t[1], t[2], t[3], t[4])
    b.icon:SetDesaturated(dbChat.mode == CHAT_MODE_HIDDEN)
end

function CS:CreateButton()
    if self.button then return self.button end
    if not Minimap then return nil end
    local button = CreateFrame("Button", "ThugUI_ChatStreamButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(ICON_SIZE, ICON_SIZE)
    background:SetPoint("TOPLEFT", 6, -6)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(MEDIA_PATH .. "Acorn.tga")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", 6, -6)
    button.icon = icon
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetAllPoints(button)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if ThugUI.Window then ThugUI.Window:Open("chatstream") end
        else
            CS:CycleChatMode()
        end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDragUpdate) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Chat stream")
        GameTooltip:AddLine("Now: |cffffd100" .. (MODE_NAME[dbChat.mode] or "?") .. "|r", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Blizzard chat, stream, hidden", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Chat stream settings", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.button = button
    self:UpdateButtonPosition()
    self:UpdateButton()
    return button
end






function CS:Prepare()
    ThugUIDB.Acorns = ThugUIDB.Acorns or {}
    db = ThugUIDB.Acorns
    db.chat = db.chat or {}
    dbChat = db.chat
    if dbChat.mode == nil then dbChat.mode = CHAT_MODE_NORMAL end
    
    
    if ThugUI.Profiles and ThugUI.Profiles.freshInstall and not dbChat.placedFresh then
        dbChat.point, dbChat.x = "LEFT", 20
        dbChat.y = CS.CentredLeftY(AnchorSize(), BoxHeight())
        dbChat.placedFresh = true
    end
end

function CS:Initialize()
    self:Prepare()

    
    self:RegisterChatEvents()
    if ThugUI.Visibility then
        ThugUI.Visibility:Register("acornStream", function(alpha)
            if streamChatFrame then streamChatFrame:SetAlpha(CS:StreamAlpha(alpha)) end
        end)
    end

    CreateAnchor()
    self:CreateButton()

    
    
    
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    initFrame:SetScript("OnEvent", function()
        CS:SetChatMode(dbChat.mode or CHAT_MODE_NORMAL)
        CS:UpdateAnchors()
    end)
    CS.initFrame = initFrame

    SLASH_THUGUI_CHATSTREAM1 = "/thugchat"
    SlashCmdList["THUGUI_CHATSTREAM"] = function(msg)
        local cmd = (msg or ""):match("^(%S*)") or ""
        cmd = cmd:lower()
        if cmd == "normal" or cmd == "1" then CS:SetChatMode(CHAT_MODE_NORMAL)
        elseif cmd == "stream" or cmd == "2" then CS:SetChatMode(CHAT_MODE_STREAM)
        elseif cmd == "hide" or cmd == "3" then CS:SetChatMode(CHAT_MODE_HIDDEN)
        elseif cmd == "unlock" or cmd == "lock" then
            CS:SetAnchorUnlocked(cmd == "unlock")
            print("|cff00ff00ThugUI:|r chat position " .. (cmd == "unlock" and "unlocked: drag the handle" or "locked"))
        elseif cmd == "reset" then
            CS:ResetPosition()
            print("|cff00ff00ThugUI:|r chat back on the left edge.")
        elseif cmd == "" then CS:CycleChatMode()
        else
            print("|cff00ff00ThugUI chat:|r /thugchat [normal|stream|hide] (no word cycles), lock | unlock, reset")
        end
    end
end

return CS
