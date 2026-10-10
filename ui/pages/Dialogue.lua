








ThugUI = ThugUI or {}

local Page = {}

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Dialogue = ThugUIDB.Dialogue or {}
    return ThugUIDB.Dialogue
end

local function Apply()
    local D = ThugUI.Dialogue
    if D then D:ApplyLayout() end
end

function Page:Build(host, panel)
    local D = ThugUI.Dialogue
    if not D then return end

    panel:Header("Dialogue")
    panel:Note("Quest and gossip text, one paragraph at a time: revealed, held, "
        .. "cleared, and looped until you pick a line. Keys 1-9 pick a line, Space "
        .. "picks the first, Esc closes (out of combat; click works in combat). "
        .. "Camera framing is on the Camera page under \"NPC dialogue\".")

    panel:Section("Window")

    panel:Checkbox{
        label = "Use the ThugUI dialogue window",
        tooltip = "Takes over Blizzard's quest and gossip windows. Applies on the "
            .. "next /reload.",
        get = function() return Cfg().enabled end,
        set = function(v) Cfg().enabled = v end,
    }
    panel:Note("Turning this on or off takes effect on the next |cffffd100/reload|r.")

    panel:Checkbox{
        label = "Unlocked (drag to move)",
        get = function() return not Cfg().locked end,
        set = function(v) Cfg().locked = not v; Apply() end,
    }

    panel:Button{
        label = "Reset position",
        onClick = function()
            local d = ThugUI.defaults.Dialogue
            local c = Cfg()
            c.point, c.x, c.y = d.point, d.x, d.y
            Apply()
        end,
    }

    panel:Slider{
        label = "Window width",
        min = 300, max = 700, step = 10, format = "%d",
        get = function() return Cfg().width end,
        set = function(v) Cfg().width = v; Apply() end,
    }
    panel:Slider{
        label = "Font size",
        min = 12, max = 24, step = 1, format = "%d",
        get = function() return Cfg().fontSize end,
        set = function(v) Cfg().fontSize = v; Apply() end,
    }
    panel:Slider{
        label = "Background opacity",
        min = 0, max = 1, step = 0.05,
        get = function() return Cfg().opacity end,
        set = function(v) Cfg().opacity = v; Apply() end,
    }

    panel:Section("Text")

    panel:Checkbox{
        label = "Reveal instantly",
        get = function() return Cfg().revealInstant end,
        set = function(v) Cfg().revealInstant = v end,
    }
    panel:Slider{
        label = "Reveal speed (characters/s)",
        min = 5, max = 120, step = 5, format = "%d",
        get = function() return Cfg().revealSpeed end,
        set = function(v) Cfg().revealSpeed = v end,
    }
    panel:Slider{
        label = "Hold each paragraph (seconds)",
        min = 1, max = 15, step = 1, format = "%d",
        get = function() return Cfg().holdTime end,
        set = function(v) Cfg().holdTime = v end,
    }

    
    panel:Button{
        label = "Preview",
        onClick = function() D:Preview() end,
    }
end

ThugUI.Window:RegisterPage{
    id = "dialogue",
    
    scopeKeys = { "Dialogue" },
    category = "ui",
    order = 70,
    summary = "Our own NPC dialogue window, one paragraph at a time.",
    title = "Dialogue",
    build = function(host, panel) Page:Build(host, panel) end,
}
