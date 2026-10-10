








ThugUI = ThugUI or {}

local Page = {}

local function Cfg()
    ThugUI_Config = ThugUI_Config or {}
    return ThugUI_Config
end

local function Hider()
    return ThugUI.FrameHider
end

function Page:Build(host, panel)
    panel:Header("Frame Hider")
    panel:Note("Hides default UI elements you never look at. Changes here take effect on "
        .. "the next |cffffd100/reload|r — the hiding runs through secure visibility state "
        .. "drivers, which cannot be lifted mid-session without tainting the frame.")

    panel:Section("Hide")

    panel:Checkbox{
        label = "Stance bar",
        get = function() return Cfg().hideStanceBar end,
        set = function(v)
            Cfg().hideStanceBar = v
            if v then local h = Hider(); if h then h:HideStanceBar() end end
        end,
    }
    panel:Checkbox{
        label = "Bag buttons",
        tooltip = "Backpack, reagent bag and the bag-bar expand toggle.",
        get = function() return Cfg().hideBagButtons end,
        set = function(v)
            Cfg().hideBagButtons = v
            if v then local h = Hider(); if h then h:HideBagButtons() end end
        end,
    }
    panel:Checkbox{
        label = "Player frame",
        tooltip = "Portrait, health and power. PlayerFrame is a secure unit button, so this "
            .. "unregisters its events and drives visibility rather than overriding Show().",
        get = function() return Cfg().hideCharacterFrame end,
        set = function(v)
            Cfg().hideCharacterFrame = v
            if v then local h = Hider(); if h then h:HideCharacterFrame() end end
        end,
    }
    panel:Checkbox{
        label = "Cast bar",
        tooltip = "PlayerCastingBarFrame. Uses Blizzard's own show-castbar flag rather "
            .. "than a state driver, so this one applies immediately and can be turned "
            .. "back on without a /reload.",
        get = function() return Cfg().hideCastBar end,
        set = function(v)
            Cfg().hideCastBar = v
            local h = Hider(); if h then h:SetCastBarHidden(v) end
        end,
    }


    panel:Section("Server restart notice")

    panel:Note("The blue \"server will restart\" message and the red button beside it "
        .. "(ShardTransferImminentFrame). Unlike the boxes above, these apply immediately.",
        { indent = 4 })

    panel:Checkbox{
        label = "Hide the server restart notice",
        tooltip = "Hides the notice and its minimize button whenever Blizzard shows them. "
            .. "Unticking lets the next notice show; one hidden now stays hidden until then.",
        get = function() return Cfg().hideShardNotice end,
        set = function(v)
            Cfg().hideShardNotice = v and true or false
            local h = Hider(); if h then h:ApplyShardNotice() end
        end,
    }
    panel:Checkbox{
        label = "Unlocked (drag to move)",
        tooltip = "Shows a placeholder where the notice appears. Drag it, then untick. "
            .. "The minimize button moves with the notice.",
        get = function() return Hider() and Hider().shardMover and Hider().shardMover:IsShown() end,
        set = function(v)
            local h = Hider(); if h then h:SetShardNoticeUnlocked(v) end
        end,
    }
    panel:Button{
        label = "Reset notice position",
        width = 220,
        onClick = function()
            local h = Hider(); if h then h:ResetShardNoticePosition() end
            print("|cff00ff00ThugUI:|r Restart notice position cleared -- the next notice "
                .. "appears where Blizzard puts it.")
        end,
    }

    
    
end

ThugUI.Window:RegisterPage{
    id = "framehider",
    category = "interface",
    order = 10,
    summary = "Turn off default elements you never look at.",
    title = "Frame Hider",
    build = function(host, panel) Page:Build(host, panel) end,
}

return Page
