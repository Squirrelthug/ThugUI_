









ThugUI = ThugUI or {}

local Page = {}

local function C()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Acorns = ThugUIDB.Acorns or {}
    ThugUIDB.Acorns.chat = ThugUIDB.Acorns.chat or {}
    return ThugUIDB.Acorns.chat
end

local function Module()
    return ThugUI.ChatStream
end

local CHANNELS = {
    { key = "SAY",     label = "Say" },
    { key = "YELL",    label = "Yell" },
    { key = "EMOTE",   label = "Emote" },
    { key = "WHISPER", label = "Whisper" },
    { key = "PARTY",   label = "Party" },
    { key = "RAID",    label = "Raid" },
    { key = "GUILD",   label = "Guild" },
    { key = "OFFICER", label = "Officer" },
    { key = "CHANNEL", label = "Channels (Trade/General)" },
    { key = "SYSTEM",  label = "System" },
}

function Page:Build(host, panel)
    panel:Header("Chat stream")
    panel:Note("Chat as Blizzard's window, a see-through stream or hidden. Left-click the chat icon on "
        .. "the minimap to cycle them; right-click it to come here.")

    panel:FrameSection{ title = "Chat stream" }

    panel:SubSection("Chat")
    panel:Dropdown{
        label = "Chat shows:",
        width = 170,
        options = {
            { value = 1, text = "Blizzard chat" },
            { value = 2, text = "Stream" },
            { value = 3, text = "Hidden" },
        },
        get = function() return C().mode or 1 end,
        set = function(v)
            local m = Module()
            if m and m.SetChatMode then m:SetChatMode(v) else C().mode = v end
        end,
    }
    panel:Checkbox{
        label = "Unlock the chat's position (drag the handle)",
        tooltip = "Shows a handle where chat hangs from. Blizzard's chat and the stream both hang below it.",
        get = function() return C().anchorUnlocked == true end,
        set = function(v)
            local m = Module()
            if m and m.SetAnchorUnlocked then m:SetAnchorUnlocked(v) else C().anchorUnlocked = v and true or false end
        end,
    }
    panel:Button{
        label = "Put chat back on the left edge",
        onClick = function() local m = Module(); if m and m.ResetPosition then m:ResetPosition() end end,
    }

    panel:SubSection("Stream")
    panel:Checkbox{
        label = "Unlock the stream (drag it, size it from its corner)",
        get = function() return C().streamUnlocked end,
        set = function(v)
            local m = Module()
            if m and m.SetStreamUnlocked then m:SetStreamUnlocked(v) else C().streamUnlocked = v and true or false end
        end,
    }
    panel:Slider{
        label = "Stream width", min = 200, max = 1000, step = 10, format = "%d",
        get = function() return C().streamWidth or 420 end,
        set = function(v) local m = Module(); if m and m.SetStreamSize then m:SetStreamSize(v, nil) else C().streamWidth = v end end,
    }
    panel:Slider{
        label = "Stream height", min = 100, max = 800, step = 10, format = "%d",
        get = function() return C().streamHeight or 220 end,
        set = function(v) local m = Module(); if m and m.SetStreamSize then m:SetStreamSize(nil, v) else C().streamHeight = v end end,
    }
    panel:Button{
        label = "Reset stream position",
        onClick = function() local m = Module(); if m and m.ResetStream then m:ResetStream() end end,
    }
    panel:Slider{
        label = "Stream font size", min = 8, max = 28, step = 1, format = "%d",
        get = function() return C().fontSize or 14 end,
        set = function(v)
            local c = C()
            c.fontSize = v
            local messageFrame = _G["ThugUI_StreamChatMessageFrame"]
            if messageFrame then
                messageFrame:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", v, c.fontOutline or "OUTLINE")
            end
        end,
    }
    panel:Checkbox{
        label = "Show timestamps",
        get = function() return C().showTimestamp end,
        set = function(v)
            C().showTimestamp = v
            local m = Module()
            if m and m.RenderStream then m:RenderStream() end
        end,
    }

    panel:SubSection("Channels")
    panel:Label("Stream channels:")
    panel:Note("Anything unticked is left out of the stream. Trade/General is off by default because a "
        .. "city's Trade chat buries everything else. Chat is captured from login in every mode, so a "
        .. "tick takes effect at once, on everything said this session.")
    for i = 1, #CHANNELS, 2 do
        for offset = 0, 1 do
            local channel = CHANNELS[i + offset]
            if channel then
                panel:Checkbox{
                    label = channel.label,
                    indent = 12,
                    sameLine = offset == 1,
                    get = function() local c = C(); return c.channels and c.channels[channel.key] ~= false end,
                    set = function(v)
                        local m = Module()
                        if m and m.SetStreamChannel then m:SetStreamChannel(channel.key, v)
                        else local c = C(); c.channels = c.channels or {}; c.channels[channel.key] = v end
                    end,
                }
            end
        end
    end

    
    
    if ThugUI.Visibility then
        ThugUI.Visibility:AddControls(panel, "acornStream", { split = true,
            afterWhen = function(p)
                p:Group("Stream rules (these win over everything on these tabs)")
                p:Checkbox{
                    label = "Always show in combat",
                    tooltip = "In combat the stream is fully shown, whatever Show, resting or moving would hide.",
                    get = function() return C().streamShowInCombat == true end,
                    set = function(v)
                        C().streamShowInCombat = v and true or false
                        local m = Module()
                        if m and m.ApplyStreamVisibility then m:ApplyStreamVisibility() end
                    end,
                }
            end })
    end
end

ThugUI.Window:RegisterPage{
    id = "chatstream",
    scopeKeys = { "Acorns" },
    category = "interface",
    order = 20,
    summary = "Chat as Blizzard's window, a clear stream or hidden, from one icon on the minimap.",
    title = "Chat stream",
    build = function(host, panel) Page:Build(host, panel) end,
}

ThugUI.ChatStreamPage = Page
return Page
