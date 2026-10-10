









local MODULE_NAME = "Acorns"
local MEDIA_PATH = "Interface\\AddOns\\ThugUI\\media\\"





local ORB_RING_TEXTURE = MEDIA_PATH .. "Ring_Main.tga"
local ORB_HIGHLIGHT_TEXTURE = MEDIA_PATH .. "Ring_Main.tga"

local Acorns = {}
ThugUI:RegisterModule(MODULE_NAME, Acorns)


local db
local dbChat
local dbObj
local chatAcornFrame
local objectivesAcornFrame
local streamChatFrame
local streamMessageFrame
local optionsMenuFrame


local CHAT_MODE_NORMAL = 1
local CHAT_MODE_STREAM = 2
local CHAT_MODE_HIDDEN = 3
















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
Acorns.STREAM_CHANNELS = CHANNEL_TOGGLES  


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
    if not ThugUI:IsModuleOn("acorns") then self:UnregisterAllEvents() return end
    if event == "PLAYER_REGEN_ENABLED" then
        for _, actionFunc in ipairs(pendingCombatActions) do
            actionFunc()
        end
        wipe(pendingCombatActions)
    end
end)




local function GetObjectivesTrackerFrame()
    return ObjectiveTrackerFrame or WatchFrame or QuestWatchFrame
end



local hiddenHolder
local function GetHiddenHolder()
    if not hiddenHolder then
        hiddenHolder = CreateFrame("Frame", "ThugUI_HiddenHolder", UIParent)
        hiddenHolder:Hide()
    end
    return hiddenHolder
end




function Acorns:CreateOrb(id, config, title, defaultIcon, onClick, onRightClick)
    local orbName = "ThugUI_Acorn_" .. id
    local acorn = CreateFrame("Button", orbName, UIParent)
    acorn.id = id
    acorn.config = config
    
    acorn:SetSize(config.size or 36, config.size or 36)
    acorn:SetPoint(config.point or "CENTER", UIParent, config.point or "CENTER", config.x or 0, config.y or 0)
    acorn:SetFrameStrata("HIGH")
    acorn:SetClampedToScreen(true)
    
    
    local bg = acorn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetAllPoints(acorn)
    bg:SetVertexColor(0.05, 0.05, 0.08, 0.85)
    acorn.bg = bg
    
    
    local ring = acorn:CreateTexture(nil, "ARTWORK")
    ring:SetTexture(ORB_RING_TEXTURE)
    ring:SetAllPoints(acorn)
    local c = config.color or {1, 1, 1, 0.9}
    ring:SetVertexColor(c[1], c[2], c[3], c[4] or 0.9)
    acorn.ring = ring

    
    local icon = acorn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    icon:SetPoint("CENTER", acorn, "CENTER", 0, 0)
    icon:SetText(defaultIcon or id)
    icon:SetTextColor(1, 1, 1, 0.95)
    acorn.icon = icon

    
    
    
    local art = acorn:CreateTexture(nil, "ARTWORK")
    art:SetPoint("CENTER", acorn, "CENTER", 0, 0)
    art:SetSize((config.size or 36) * 0.62, (config.size or 36) * 0.62)
    art:Hide()
    acorn.art = art

    acorn.SetArt = function(self, texturePath)
        if texturePath and texturePath ~= "" then
            self.art:SetTexture(texturePath)
            
            
            
            if texturePath:lower():find("interface\\icons\\", 1, true) then
                self.art:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            else
                self.art:SetTexCoord(0, 1, 0, 1)
            end
            self.art:Show()
            self.icon:Hide()
        else
            self.art:Hide()
            self.icon:Show()
        end
    end
    acorn:SetArt(config.iconTexture)

    
    local highlight = acorn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(ORB_HIGHLIGHT_TEXTURE)
    highlight:SetAllPoints(acorn)
    highlight:SetVertexColor(1, 1, 1, 0.4)
    acorn.highlight = highlight

    
    local label = acorn:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
    label:SetPoint("TOP", acorn, "BOTTOM", 0, -3)
    label:SetTextColor(0.8, 0.8, 0.8, 0.9)
    acorn.label = label
    
    
    acorn:SetMovable(true)
    acorn:EnableMouse(true)
    acorn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    acorn:RegisterForDrag("LeftButton")

    
    
    
    
    
    
    
    
    
    
    
    
    
    local function SetPressed(self, pressed)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("CENTER", self, "CENTER", 0, pressed and -1 or 0)
        if pressed then
            self.bg:SetVertexColor(0.15, 0.15, 0.20, 0.95)
        else
            self.bg:SetVertexColor(0.05, 0.05, 0.08, 0.85)
        end
    end
    acorn.SetPressed = SetPressed

    acorn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            SetPressed(self, true)
        end
    end)

    acorn:SetScript("OnMouseUp", function(self, button)
        SetPressed(self, false)
    end)

    acorn:SetScript("OnDragStart", function(self)
        if not db.locked or IsShiftKeyDown() then
            self:StartMoving()
            self.isDragging = true
        end
    end)

    acorn:SetScript("OnDragStop", function(self)
        SetPressed(self, false)
        if self.isDragging then
            self:StopMovingOrSizing()
            self.isDragging = false
            local point, _, relPoint, x, y = self:GetPoint()
            config.point = point
            config.x = math.floor(x + 0.5)
            config.y = math.floor(y + 0.5)
            
            
            Acorns:UpdateAnchors()
        end
    end)

    acorn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if onClick then onClick(self) end
        elseif button == "RightButton" then
            if onRightClick then onRightClick(self) end
        end
    end)

    
    acorn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 0, 1, 0.8)
        
        if self.GetTooltipText then
            self:GetTooltipText(GameTooltip)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Cycle Mode / Toggle", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Options", 0.7, 0.7, 0.7)
        if db.locked then
            GameTooltip:AddLine("|cffffaa00Shift + Left-Drag:|r Move Acorn", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("|cff00ff00Left-Drag:|r Move Acorn", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)

    acorn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        
        
        SetPressed(self, false)
    end)

    return acorn
end




function Acorns:CreateStreamChatFrame()
    if streamChatFrame then return end

    local frame = CreateFrame("Frame", "ThugUI_StreamChatFrame", UIParent)
    frame:SetSize(dbChat.streamWidth or 420, dbChat.streamHeight or 220)
    frame:SetPoint("TOPLEFT", chatAcornFrame, "BOTTOMLEFT", 0, -10)
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
        streamChatFrame:SetPoint("TOPLEFT", chatAcornFrame, "BOTTOMLEFT", 0, -10)
    end
end
Acorns.AnchorStream = AnchorStream



function Acorns:ApplyStreamLock()
    local frame = streamChatFrame
    if not frame then return end
    local unlocked = dbChat and dbChat.streamUnlocked and true or false
    if frame.resizeGrip then frame.resizeGrip:SetShown(unlocked) end
    if frame.unlockFill then frame.unlockFill:SetShown(unlocked) end
    frame:SetMovable(unlocked)
    frame:EnableMouse(unlocked)
    if unlocked then frame:RegisterForDrag("LeftButton") else frame:RegisterForDrag() end
end

function Acorns:SetStreamUnlocked(on)
    dbChat.streamUnlocked = on and true or false
    self:ApplyStreamLock()
    self:ApplyStreamVisibility()
end







function Acorns:StreamAlpha(alpha)
    if dbChat and dbChat.streamUnlocked then return 1 end
    local V = ThugUI.Visibility
    if dbChat and dbChat.streamShowInCombat == true and V and V:InCombat() then return 1 end
    return alpha or 1
end

function Acorns:ApplyStreamVisibility()
    if not streamChatFrame then return end
    local V = ThugUI.Visibility
    streamChatFrame:SetAlpha(self:StreamAlpha(V and V:CurrentAlpha("acornStream") or 1))
end

function Acorns:SetStreamSize(w, h)
    if w then dbChat.streamWidth = w end
    if h then dbChat.streamHeight = h end
    if streamChatFrame then
        streamChatFrame:SetSize(dbChat.streamWidth or 420, dbChat.streamHeight or 220)
    end
end


function Acorns:ResetStream()
    dbChat.streamPoint = nil
    dbChat.streamWidth, dbChat.streamHeight = 420, 220
    if streamChatFrame then
        streamChatFrame:SetSize(420, 220)
        AnchorStream()
    end
end

















local STREAM_LOG_MAX = 500
local streamLog = {}
Acorns.streamLog = streamLog  

local function StreamChannelOn(key)
    return not (dbChat and dbChat.channels and dbChat.channels[key] == false)
end

local function StreamLine(entry)
    if dbChat and dbChat.showTimestamp then
        return "|cff888888" .. entry.stamp .. "|r " .. entry.text
    end
    return entry.text
end



function Acorns:RenderStream()
    if not streamMessageFrame then return end
    streamMessageFrame:Clear()
    for _, entry in ipairs(streamLog) do
        if StreamChannelOn(entry.key) then
            streamMessageFrame:AddMessage(StreamLine(entry), entry.r, entry.g, entry.b)
        end
    end
end


function Acorns:SetStreamChannel(key, on)
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
function Acorns:RegisterChatEvents()
    if chatEventFrame then return end
    local eventFrame = CreateFrame("Frame")
    chatEventFrame = eventFrame
    Acorns.chatEventFrame = eventFrame  

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
Acorns.SetChatExtrasHidden = SetChatExtrasHidden  

function Acorns:SetChatMode(mode)
    
    
    
    dbChat.mode = mode

    QueueCombatAction(function()
        local chatFrame1 = ChatFrame1
        local dock = GeneralDockManager

        if mode == CHAT_MODE_NORMAL then
            
            if chatFrame1 then
                chatFrame1:Show()
                chatFrame1:ClearAllPoints()
                chatFrame1:SetPoint("TOPLEFT", chatAcornFrame, "BOTTOMLEFT", 0, -10)
            end
            if dock then dock:Show() end
            if streamChatFrame then streamChatFrame:Hide() end
            SetChatExtrasHidden(false)

            chatAcornFrame.ring:SetVertexColor(0.2, 0.7, 1.0, 0.9)
            chatAcornFrame.icon:SetText("CHAT")
            chatAcornFrame.label:SetText("Normal")
            
            
            chatAcornFrame.art:SetDesaturated(false)
            chatAcornFrame.art:SetVertexColor(0.55, 0.82, 1.00, 1)

        elseif mode == CHAT_MODE_STREAM then
            
            if chatFrame1 then chatFrame1:Hide() end
            if dock then dock:Hide() end
            SetChatExtrasHidden(true)

            Acorns:CreateStreamChatFrame()
            streamChatFrame:Show()
            AnchorStream()

            chatAcornFrame.ring:SetVertexColor(0.2, 1.0, 0.5, 0.9)
            chatAcornFrame.icon:SetText("STRM")
            chatAcornFrame.label:SetText("Stream")
            chatAcornFrame.art:SetDesaturated(false)
            chatAcornFrame.art:SetVertexColor(0.55, 1.00, 0.72, 1)

        elseif mode == CHAT_MODE_HIDDEN then
            
            if chatFrame1 then chatFrame1:Hide() end
            if dock then dock:Hide() end
            if streamChatFrame then streamChatFrame:Hide() end
            SetChatExtrasHidden(true)

            chatAcornFrame.ring:SetVertexColor(0.5, 0.5, 0.5, 0.5)
            chatAcornFrame.icon:SetText("OFF")
            chatAcornFrame.label:SetText("Hidden")
            
            
            chatAcornFrame.art:SetDesaturated(true)
            chatAcornFrame.art:SetVertexColor(0.55, 0.55, 0.58, 0.85)
        end
    end)
end

function Acorns:CycleChatMode()
    local nextMode = dbChat.mode + 1
    if nextMode > CHAT_MODE_HIDDEN then
        nextMode = CHAT_MODE_NORMAL
    end
    self:SetChatMode(nextMode)
end




















local objectivesCombatDimmed = false
local objectivesAlphaBeforeCombat


local function ShouldDimForCombat()
    if not dbObj or not dbObj.hideInCombat then return false end
    
    
    
    if dbObj.visible == false then return false end
    if type(IsInInstance) ~= "function" then return false end
    local inInstance = IsInInstance()
    return inInstance and true or false
end

local function SetObjectivesCombatDim(dim)
    local tracker = GetObjectivesTrackerFrame()
    if not tracker then return end

    if dim then
        if objectivesCombatDimmed then return end
        objectivesAlphaBeforeCombat = tracker.GetAlpha and tracker:GetAlpha() or 1
        objectivesCombatDimmed = true
        tracker:SetAlpha(0)
    else
        if not objectivesCombatDimmed then return end
        objectivesCombatDimmed = false
        tracker:SetAlpha(objectivesAlphaBeforeCombat or 1)
        objectivesAlphaBeforeCombat = nil
    end
end


function Acorns:SetObjectivesCombatHide(enabled)
    dbObj.hideInCombat = enabled and true or false

    
    
    if not dbObj.hideInCombat then
        SetObjectivesCombatDim(false)
    elseif InCombatLockdown() and ShouldDimForCombat() then
        SetObjectivesCombatDim(true)
    end
end




local function ApplyObjectivesVisibility(visible)
    local tracker = GetObjectivesTrackerFrame()

    QueueCombatAction(function()
        if not tracker then return end

        if visible then
            tracker:SetParent(UIParent)
            tracker:Show()
            tracker:ClearAllPoints()
            tracker:SetPoint("TOPRIGHT", objectivesAcornFrame, "BOTTOMRIGHT", 0, -10)

            
            
            
            
            
            
            SetObjectivesCombatDim(false)

            objectivesAcornFrame.ring:SetVertexColor(1.0, 0.82, 0.2, 0.9)
            objectivesAcornFrame.icon:SetText("OBJ")
            objectivesAcornFrame.label:SetText("Shown")
            
            
            objectivesAcornFrame.art:SetDesaturated(false)
            objectivesAcornFrame.art:SetVertexColor(0.95, 0.80, 0.45, 1)
        else
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            tracker:SetParent(GetHiddenHolder())

            objectivesAcornFrame.ring:SetVertexColor(0.5, 0.5, 0.5, 0.5)
            objectivesAcornFrame.icon:SetText("OFF")
            objectivesAcornFrame.label:SetText("Hidden")
            objectivesAcornFrame.art:SetDesaturated(true)
            objectivesAcornFrame.art:SetVertexColor(0.55, 0.55, 0.58, 0.85)
        end
    end)
end

function Acorns:SetObjectivesVisibility(visible)
    dbObj.visible = visible
    ApplyObjectivesVisibility(visible)
end

function Acorns:ToggleObjectivesVisibility()
    self:SetObjectivesVisibility(not dbObj.visible)
end





















local function ObjectivesWantHidden()
    if not dbObj then return false end
    return dbObj.visible == false
end

local function ReassertObjectivesVisibility()
    if not ObjectivesWantHidden() then return end

    local tracker = GetObjectivesTrackerFrame()
    if not tracker then return end
    if tracker:GetParent() == GetHiddenHolder() then return end

    
    
    
    
    
    
    QueueCombatAction(function()
        
        
        
        
        
        if not ObjectivesWantHidden() then return end
        tracker:SetParent(GetHiddenHolder())
    end)
end























local REASSERT_LADDER = { 0.1, 0.5, 1, 2, 5 }

local function ScheduleObjectivesReassert()
    ReassertObjectivesVisibility()

    if not (C_Timer and type(C_Timer.After) == "function") then return end
    for _, delay in ipairs(REASSERT_LADDER) do
        C_Timer.After(delay, ReassertObjectivesVisibility)
    end
end




function Acorns:UpdateAnchors()
    QueueCombatAction(function()
        if chatAcornFrame then
            chatAcornFrame:ClearAllPoints()
            chatAcornFrame:SetPoint(dbChat.point or "BOTTOMLEFT", UIParent, dbChat.point or "BOTTOMLEFT", dbChat.x or 25, dbChat.y or 220)
            
            if dbChat.mode == CHAT_MODE_NORMAL and ChatFrame1 then
                ChatFrame1:ClearAllPoints()
                ChatFrame1:SetPoint("TOPLEFT", chatAcornFrame, "BOTTOMLEFT", 0, -10)
            elseif dbChat.mode == CHAT_MODE_STREAM and streamChatFrame then
                AnchorStream()
            end
        end

        if objectivesAcornFrame then
            objectivesAcornFrame:ClearAllPoints()
            objectivesAcornFrame:SetPoint(dbObj.point or "TOPRIGHT", UIParent, dbObj.point or "TOPRIGHT", dbObj.x or -260, dbObj.y or -220)

            local tracker = GetObjectivesTrackerFrame()
            if tracker and dbObj.visible then
                tracker:ClearAllPoints()
                tracker:SetPoint("TOPRIGHT", objectivesAcornFrame, "BOTTOMRIGHT", 0, -10)
            end
        end
    end)
end




function Acorns:OpenOptionsMenu(acorn)
    
    if not ThugUI.CombatClose:Allow("orbMenu") then return end
    if not optionsMenuFrame then
        local menu = CreateFrame("Frame", "ThugUI_AcornOptionsMenu", UIParent, "BackdropTemplate")
        optionsMenuFrame = menu
        
        
        if ThugUI.CombatClose then
            ThugUI.CombatClose:Register("orbMenu", function() return optionsMenuFrame and optionsMenuFrame:IsShown() end,
                function() optionsMenuFrame:Hide() end)
        end
        menu:SetSize(220, 240)
        menu:SetFrameStrata("DIALOG")
        menu:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        ThugUI.Theme:Paint(menu, "listBackground", "backdrop")

        local title = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", menu, "TOP", 0, -12)
        title:SetText("ThugUI Acorn Settings")
        menu.title = title

        
        local closeBtn = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -2, -2)
        
        
        closeBtn:SetScript("OnClick", function() menu:Hide() end)

        
        local lockBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        lockBtn:SetSize(190, 22)
        lockBtn:SetPoint("TOP", title, "BOTTOM", 0, -12)
        lockBtn:SetScript("OnClick", function()
            db.locked = not db.locked
            menu:UpdateButtons()
            print("|cff00ff00ThugUI:|r Acorns are now " .. (db.locked and "|cffff4040Locked|r" or "|cff40ff40Unlocked|r"))
        end)
        menu.lockBtn = lockBtn

        
        local fontLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fontLabel:SetPoint("TOPLEFT", lockBtn, "BOTTOMLEFT", 0, -14)
        fontLabel:SetText("Stream Font Size:")
        menu.fontLabel = fontLabel

        local fontDec = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        fontDec:SetSize(28, 20)
        fontDec:SetPoint("LEFT", fontLabel, "RIGHT", 10, 0)
        fontDec:SetText("-")
        fontDec:SetScript("OnClick", function()
            dbChat.fontSize = math.max(8, (dbChat.fontSize or 14) - 1)
            if streamMessageFrame then
                local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
                streamMessageFrame:SetFont(fontPath, dbChat.fontSize, dbChat.fontOutline or "OUTLINE")
            end
            menu:UpdateButtons()
        end)

        local fontVal = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fontVal:SetPoint("LEFT", fontDec, "RIGHT", 8, 0)
        menu.fontVal = fontVal

        local fontInc = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        fontInc:SetSize(28, 20)
        fontInc:SetPoint("LEFT", fontVal, "RIGHT", 8, 0)
        fontInc:SetText("+")
        fontInc:SetScript("OnClick", function()
            dbChat.fontSize = math.min(32, (dbChat.fontSize or 14) + 1)
            if streamMessageFrame then
                local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
                streamMessageFrame:SetFont(fontPath, dbChat.fontSize, dbChat.fontOutline or "OUTLINE")
            end
            menu:UpdateButtons()
        end)

        
        
        
        local chanLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        chanLabel:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -16)
        chanLabel:SetText("Stream Channels:")
        menu.chanLabel = chanLabel

        menu.channelChecks = {}
        for i, ch in ipairs(CHANNEL_TOGGLES) do
            local row = math.floor((i - 1) / 2)
            local col = (i - 1) % 2

            local cb = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", chanLabel, "BOTTOMLEFT", 2 + col * 100, -4 - row * 22)

            local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            text:SetText(ch.label)

            cb.channelKey = ch.key
            cb:SetScript("OnClick", function(self)
                Acorns:SetStreamChannel(self.channelKey, self:GetChecked())
            end)

            menu.channelChecks[i] = cb
        end

        menu.channelRows = math.ceil(#CHANNEL_TOGGLES / 2)

        
        local resetBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        resetBtn:SetSize(190, 22)
        resetBtn:SetPoint("BOTTOM", menu, "BOTTOM", 0, 14)
        resetBtn:SetText("Reset Acorn Positions")
        resetBtn:SetScript("OnClick", function()
            dbChat.point = "BOTTOMLEFT"
            dbChat.x = 25
            dbChat.y = 220
            dbObj.point = "TOPRIGHT"
            dbObj.x = -260
            dbObj.y = -220
            Acorns:UpdateAnchors()
            print("|cff00ff00ThugUI:|r Reset Acorn positions to default.")
        end)

        menu.fontDec = fontDec
        menu.fontInc = fontInc

        
        
        
        function menu:UpdateButtons(forChatAcorn)
            lockBtn:SetText(db.locked and "Unlock Acorns (Allow Drag)" or "Lock Acorns (Prevent Drag)")
            fontVal:SetText(tostring(dbChat.fontSize or 14))

            local streamWidgets = {
                self.fontLabel, self.fontDec, self.fontVal, self.fontInc, self.chanLabel,
            }
            for _, w in ipairs(streamWidgets) do
                w:SetShown(forChatAcorn)
            end

            for _, cb in ipairs(self.channelChecks) do
                cb:SetShown(forChatAcorn)
                
                cb:SetChecked(not (dbChat.channels and dbChat.channels[cb.channelKey] == false))
            end

            if forChatAcorn then
                self:SetHeight(120 + self.channelRows * 22 + 56)
            else
                self:SetHeight(130)
            end
        end

    end

    optionsMenuFrame:ClearAllPoints()
    optionsMenuFrame:SetPoint("TOPLEFT", acorn, "TOPRIGHT", 10, 0)
    optionsMenuFrame:UpdateButtons(acorn.id == "Chat")
    optionsMenuFrame:Show()
end




function Acorns:Initialize()
    db = ThugUIDB.Acorns
    if not db or not db.enabled then return end

    
    dbChat = db.chat
    self:RegisterChatEvents()
    if ThugUI.Visibility then
        ThugUI.Visibility:Register("acornStream", function(alpha)
            if streamChatFrame then streamChatFrame:SetAlpha(Acorns:StreamAlpha(alpha)) end
        end)
    end

    dbChat = db.chat
    dbObj = db.objectives

    
    chatAcornFrame = self:CreateOrb(
        "Chat",
        dbChat,
        "|cff00ccffChat acorn|r",
        "CHAT",
        function() Acorns:CycleChatMode() end,
        function(acorn) Acorns:OpenOptionsMenu(acorn) end
    )
    chatAcornFrame.GetTooltipText = function(self, tooltip)
        local modeStr = "Normal Chat"
        if dbChat.mode == CHAT_MODE_STREAM then modeStr = "Stream Box (Transparent)"
        elseif dbChat.mode == CHAT_MODE_HIDDEN then modeStr = "Hidden" end
        tooltip:AddLine("Current Mode: |cffffd100" .. modeStr .. "|r")
    end

    
    objectivesAcornFrame = self:CreateOrb(
        "Objectives",
        dbObj,
        "|cffffd100Objectives acorn|r",
        "OBJ",
        function() Acorns:ToggleObjectivesVisibility() end,
        function(acorn) Acorns:OpenOptionsMenu(acorn) end
    )
    objectivesAcornFrame.GetTooltipText = function(self, tooltip)
        local statusStr = dbObj.visible and "Shown" or "Hidden"
        tooltip:AddLine("Tracker Status: |cffffd100" .. statusStr .. "|r")
        
        
        
        
        if objectivesCombatDimmed then
            tooltip:AddLine("|cff909090Dimmed for combat|r")
        elseif dbObj.hideInCombat then
            tooltip:AddLine("|cff909090Dims in combat while in an instance|r")
        end
    end

    
    
    

    
    
    
    
    
    
    
    
    
    
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    
    
    initFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    
    
    
    
    initFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    initFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if ShouldDimForCombat() then SetObjectivesCombatDim(true) end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            Acorns:SetChatMode(dbChat.mode or CHAT_MODE_NORMAL)
            Acorns:SetObjectivesVisibility(dbObj.visible ~= false)
            Acorns:UpdateAnchors()
            
            
            
            
            
            
            
            
            
            if not (InCombatLockdown() and ShouldDimForCombat()) then
                SetObjectivesCombatDim(false)
            end
            
            
            
            ScheduleObjectivesReassert()
        else
            
            
            
            if event == "PLAYER_REGEN_ENABLED" then
                SetObjectivesCombatDim(false)
            end
            ScheduleObjectivesReassert()
        end
    end)

    
    
    
    
    
    
    
    
    
    
    
    
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            
            
            
            
            if C_Timer and C_Timer.After then
                C_Timer.After(0, ScheduleObjectivesReassert)
            else
                ScheduleObjectivesReassert()
            end
        end, Acorns)

    end

    
    
    SLASH_THUGUI_ACORNS1 = "/acorn"
    SLASH_THUGUI_ACORNS2 = "/acorns"
    SlashCmdList["THUGUI_ACORNS"] = function(msg)
        local cmd, arg = msg:match("^(%S*)%s*(.-)$")
        cmd = cmd:lower()

        if cmd == "lock" or cmd == "unlock" then
            db.locked = (cmd == "lock")
            print("|cff00ff00ThugUI:|r Acorns are now " .. (db.locked and "|cffff4040Locked|r" or "|cff40ff40Unlocked|r"))
        elseif cmd == "chat" then
            if arg == "normal" or arg == "1" then Acorns:SetChatMode(CHAT_MODE_NORMAL)
            elseif arg == "stream" or arg == "2" then Acorns:SetChatMode(CHAT_MODE_STREAM)
            elseif arg == "hide" or arg == "3" then Acorns:SetChatMode(CHAT_MODE_HIDDEN)
            else Acorns:CycleChatMode() end
        elseif cmd == "obj" or cmd == "objectives" then
            if arg == "show" or arg == "1" then Acorns:SetObjectivesVisibility(true)
            elseif arg == "hide" or arg == "0" then Acorns:SetObjectivesVisibility(false)
            else Acorns:ToggleObjectivesVisibility() end
        elseif cmd == "objcombat" then
            if arg == "on" or arg == "1" then Acorns:SetObjectivesCombatHide(true)
            elseif arg == "off" or arg == "0" then Acorns:SetObjectivesCombatHide(false)
            else Acorns:SetObjectivesCombatHide(not dbObj.hideInCombat) end
            print("|cff00ff00ThugUI:|r Objectives tracker dims in instanced combat: "
                .. (dbObj.hideInCombat and "|cff40ff40On|r" or "|cffff4040Off|r"))
        elseif cmd == "font" and tonumber(arg) then
            dbChat.fontSize = tonumber(arg)
            if streamMessageFrame then
                local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
                streamMessageFrame:SetFont(fontPath, dbChat.fontSize, dbChat.fontOutline or "OUTLINE")
            end
            print("|cff00ff00ThugUI:|r Stream Chat Font Size set to " .. dbChat.fontSize)
        elseif cmd == "icon" then
            
            local which, name = arg:match("^(%S*)%s*(.-)$")
            which = (which or ""):lower()

            local target, targetDB
            if which == "obj" or which == "objectives" then
                target, targetDB = objectivesAcornFrame, dbObj
            elseif which == "chat" then
                target, targetDB = chatAcornFrame, dbChat
            else
                print("|cff00ff00ThugUI:|r Usage: /acorn icon <chat|obj> <iconName|none>")
                print("  e.g. /acorn icon obj INV_Misc_Food_02")
                return
            end

            if name == "" or name:lower() == "none" then
                
                
                
                targetDB.iconTexture = false
                target:SetArt(false)
                print("|cff00ff00ThugUI:|r " .. which .. " acorn reverted to text badge.")
            else
                
                local path = name:find("\\") and name or ("Interface\\ICONS\\" .. name)
                targetDB.iconTexture = path
                target:SetArt(path)
                print("|cff00ff00ThugUI:|r " .. which .. " acorn icon set to " .. path)
                print("  If the acorn went blank, that icon name does not exist.")
            end
        elseif cmd == "reset" then
            dbChat.point = "BOTTOMLEFT"
            dbChat.x = 25
            dbChat.y = 220
            dbObj.point = "TOPRIGHT"
            dbObj.x = -260
            dbObj.y = -220
            Acorns:UpdateAnchors()
            print("|cff00ff00ThugUI:|r Acorn positions reset to defaults.")
        else
            print("|cff00ff00ThugUI Acorn Commands:|r")
            print("  /acorn lock | unlock - Lock or unlock acorn dragging")
            print("  /acorn chat [normal|stream|hide] - Switch Chat Mode")
            print("  /acorn obj [show|hide] - Toggle Objectives Tracker")
            print("  /acorn objcombat [on|off] - Dim the tracker in combat, in instances")
            print("  /acorn font <size> - Set Stream Chat Font Size")
            print("  /acorn icon <chat|obj> <iconName|none> - Use artwork instead of letters")
            print("  /acorn reset - Reset Acorn positions")
        end
    end
end
