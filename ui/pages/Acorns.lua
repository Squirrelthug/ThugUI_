







ThugUI = ThugUI or {}

local Page = {}

local function DB()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Acorns = ThugUIDB.Acorns or {}
    local db = ThugUIDB.Acorns
    db.chat = db.chat or {}
    db.objectives = db.objectives or {}
    return db, db.chat, db.objectives
end

local function Module()
    return ThugUI.modules and ThugUI.modules.Acorns
end

local function ApplyAnchors()
    local module = Module()
    if module and module.UpdateAnchors then module:UpdateAnchors() end
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
    panel:Header("Acorns")
    panel:Note("Floating acorns that stand in for hidden UI elements. Click one to toggle "
        .. "its element; shift-drag to move it. Each acorn has its own page below this one.")

    panel:Section("General")

    panel:Checkbox{
        label = "Enable acorns",
        get = function() return DB().enabled end,
        set = function(v) local d = DB(); d.enabled = v; ApplyAnchors() end,
    }
    panel:Checkbox{
        label = "Lock acorn positions",
        tooltip = "Locked, a plain left-click always toggles and shift-drag moves. "
            .. "Unlocked, a few pixels of movement get eaten as a drag and the click never lands.",
        get = function() return DB().locked end,
        set = function(v) DB().locked = v end,
    }

    panel:Gap(8)
    panel:Button{
        label = "Reset acorn positions",
        onClick = function()
            local _, c, o = DB()
            c.point, c.x, c.y = "BOTTOMLEFT", 25, 220
            o.point, o.x, o.y = "TOPRIGHT", -260, -220
            ApplyAnchors()
            print("|cff00ff00ThugUI:|r Acorn positions reset.")
        end,
    }

end



function Page:BuildChat(host, panel)
    panel:Header("Chat acorn")
    panel:Note("Stands in for the chat window. Left-click it to cycle the chat between the normal "
        .. "window, a see-through stream box and hidden; right-click for its options.")

    panel:FrameSection{
        title = "Chat acorn",
        enabled = {
            get = function() local _, c = DB(); return c.enabled end,
            set = function(v) local _, c = DB(); c.enabled = v end,
        },
    }

    panel:SubSection("Acorn")
    panel:Dropdown{
        label = "Chat mode:",
        width = 170,
        options = {
            { value = 1, text = "Normal chat" },
            { value = 2, text = "Stream text box" },
            { value = 3, text = "Hidden" },
        },
        get = function() local _, c = DB(); return c.mode or 1 end,
        set = function(v)
            local _, c = DB()
            c.mode = v
            local module = Module()
            if module and module.SetChatMode then module:SetChatMode(v) end
        end,
    }

    panel:Slider{
        label = "Chat acorn size", min = 20, max = 64, step = 2, format = "%d",
        get = function() local _, c = DB(); return c.size or 36 end,
        set = function(v) local _, c = DB(); c.size = v; ApplyAnchors() end,
    }
    panel:Color{
        label = "Chat acorn colour:",
        get = function()
            local _, c = DB()
            local col = c.color or {}
            return col[1], col[2], col[3]
        end,
        set = function(r, g, b)
            local _, c = DB()
            c.color = { r, g, b, (c.color and c.color[4]) or 0.9 }
            ApplyAnchors()
        end,
    }


    panel:SubSection("Stream")
    panel:Checkbox{
        label = "Unlock the stream (drag it, size it from its corner)",
        get = function() local _, c = DB(); return c.streamUnlocked end,
        set = function(v)
            local module = Module()
            if module and module.SetStreamUnlocked then module:SetStreamUnlocked(v)
            else local _, c = DB(); c.streamUnlocked = v and true or false end
        end,
    }
    panel:Slider{
        label = "Stream width", min = 200, max = 1000, step = 10, format = "%d",
        get = function() local _, c = DB(); return c.streamWidth or 420 end,
        set = function(v) local module = Module(); if module and module.SetStreamSize then module:SetStreamSize(v, nil) end end,
    }
    panel:Slider{
        label = "Stream height", min = 100, max = 800, step = 10, format = "%d",
        get = function() local _, c = DB(); return c.streamHeight or 220 end,
        set = function(v) local module = Module(); if module and module.SetStreamSize then module:SetStreamSize(nil, v) end end,
    }
    panel:Button{
        label = "Reset stream position",
        onClick = function() local module = Module(); if module and module.ResetStream then module:ResetStream() end end,
    }

    panel:Slider{
        label = "Stream font size", min = 8, max = 28, step = 1, format = "%d",
        get = function() local _, c = DB(); return c.fontSize or 14 end,
        set = function(v)
            local _, c = DB()
            c.fontSize = v
            local messageFrame = _G["ThugUI_StreamChatMessageFrame"]
            if messageFrame then
                messageFrame:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", v, c.fontOutline or "OUTLINE")
            end
        end,
    }

    panel:Checkbox{
        label = "Show timestamps",
        get = function() local _, c = DB(); return c.showTimestamp end,
        set = function(v)
            local _, c = DB(); c.showTimestamp = v
            local module = Module()
            if module and module.RenderStream then module:RenderStream() end
        end,
    }


    panel:SubSection("Channels")
    panel:Label("Stream box channels:")
    panel:Note("Anything unticked is filtered out of the stream box. Trade/General is off "
        .. "by default because a city's Trade chat buries everything else. Chat is "
        .. "captured from login in every mode, so a tick takes effect at once, on "
        .. "everything said this session.")

    
    
    for i = 1, #CHANNELS, 2 do
        for offset = 0, 1 do
            local channel = CHANNELS[i + offset]
            if channel then
                panel:Checkbox{
                    label = channel.label,
                    indent = 12,
                    sameLine = offset == 1,
                    get = function()
                        local _, c = DB()
                        return c.channels and c.channels[channel.key] ~= false
                    end,
                    set = function(v)
                        
                        local module = Module()
                        if module and module.SetStreamChannel then
                            module:SetStreamChannel(channel.key, v)
                        else
                            local _, c = DB()
                            c.channels = c.channels or {}
                            c.channels[channel.key] = v
                        end
                    end,
                }
            end
        end
    end

    
    
    
    if ThugUI.Visibility then
        ThugUI.Visibility:AddControls(panel, "acornStream", { split = true, moving = true, padReveal = true,
            afterWhen = function(p)
                p:Group("Stream rules (these win over everything on these tabs)")
                p:Checkbox{
                    label = "Always show in combat",
                    tooltip = "In combat the stream box is fully shown, whatever Show, resting, moving or gamepad input would hide.",
                    get = function() local _, c = DB(); return c.streamShowInCombat == true end,
                    set = function(v)
                        local _, c = DB(); c.streamShowInCombat = v and true or false
                        local module = Module()
                        if module and module.ApplyStreamVisibility then module:ApplyStreamVisibility() end
                    end,
                }
            end })
    end
end


function Page:BuildObjectives(host, panel)
    panel:Header("Objectives acorn")
    panel:Note("Stands in for Blizzard's quest and objectives tracker. Left-click the acorn to show "
        .. "or hide the tracker; it stays where you put it, so the tracker is one click away. "
        .. "Right-click for its options.")

    panel:Section("Objectives acorn")

    panel:Checkbox{
        label = "Enable objectives acorn",
        get = function() local _, _, o = DB(); return o.enabled end,
        set = function(v) local _, _, o = DB(); o.enabled = v end,
    }

    panel:Checkbox{
        label = "Objective tracker visible",
        tooltip = "Hiding reparents the tracker to a never-shown frame. Blizzard re-Show()s "
            .. "the tracker constantly, so plain Hide() and visibility state drivers both "
            .. "lose the argument; a child of a hidden parent simply never draws.",
        get = function() local _, _, o = DB(); return o.visible end,
        set = function(v)
            local module = Module()
            if module and module.SetObjectivesVisibility then
                module:SetObjectivesVisibility(v)
            else
                local _, _, o = DB()
                o.visible = v
            end
        end,
    }

    panel:Checkbox{
        label = "Dim the tracker in combat (instances only)",
        tooltip = "In dungeons, raids, scenarios and battlegrounds, fade the objectives "
            .. "tracker out while you are in combat and bring it back when the fight ends.\n\n"
            .. "Fades rather than hides: reparenting the tracker is a protected action and "
            .. "combat has already started by the time we are told about it, so a real hide "
            .. "could not run until the fight was over. Alpha still works in combat. The "
            .. "tracker keeps its footprint for the mouse while faded.",
        get = function() local _, _, o = DB(); return o.hideInCombat end,
        set = function(v)
            local module = Module()
            if module and module.SetObjectivesCombatHide then
                module:SetObjectivesCombatHide(v)
            else
                local _, _, o = DB()
                o.hideInCombat = v
            end
        end,
    }

    panel:Slider{
        label = "Objectives acorn size", min = 20, max = 64, step = 2, format = "%d",
        get = function() local _, _, o = DB(); return o.size or 36 end,
        set = function(v) local _, _, o = DB(); o.size = v; ApplyAnchors() end,
    }
    panel:Color{
        label = "Objectives acorn colour:",
        get = function()
            local _, _, o = DB()
            local col = o.color or {}
            return col[1], col[2], col[3]
        end,
        set = function(r, g, b)
            local _, _, o = DB()
            o.color = { r, g, b, (o.color and o.color[4]) or 0.9 }
            ApplyAnchors()
        end,
    }

end

ThugUI.Window:RegisterPage{
    id = "acorns",
    
    scopeKeys = { "Acorns" },
    category = "interface",
    order = 20,
    summary = "Acorns standing in for the hidden chat and objective tracker.",
    title = "Acorns",
    build = function(host, panel) Page:Build(host, panel) end,
}

ThugUI.Window:RegisterPage{
    id = "acorns_chat",
    
    scopeKeys = { "Acorns" },
    parent = "acorns",
    category = "interface",
    order = 21,
    summary = "The chat acorn: chat mode, the stream box and its channels.",
    title = "Chat acorn",
    build = function(host, panel) Page:BuildChat(host, panel) end,
}

ThugUI.Window:RegisterPage{
    id = "acorns_objectives",
    
    scopeKeys = { "Acorns" },
    parent = "acorns",
    category = "interface",
    order = 22,
    summary = "The objectives acorn: the quest tracker on a click.",
    title = "Objectives acorn",
    build = function(host, panel) Page:BuildObjectives(host, panel) end,
}

return Page
