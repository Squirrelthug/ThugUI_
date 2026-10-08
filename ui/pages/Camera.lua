









ThugUI = ThugUI or {}

local Page = { selectedKey = "dialogue" }

ThugUI.CameraPage = Page



local function Cfg()
    if not (ThugUIDB and ThugUIDB.Camera and ThugUIDB.Camera.situations) then
        ThugUIDB = ThugUIDB or {}
        ThugUI:InitializeDB()
    end
    return ThugUIDB.Camera
end

local function Sit()
    return Cfg().situations[Page.selectedKey]
end

local function LabelFor(key)
    local C = ThugUI.Camera
    for _, s in ipairs(C and C.SITUATIONS or {}) do
        if s.key == key then return s.label end
    end
    return key or "none"
end

local function ApplyGlobals()
    local C = ThugUI.Camera
    if C then C:ApplyGlobals(); C:Evaluate() end
end

local function ApplySituation()
    local C = ThugUI.Camera
    
    
    if C then C:ApplyGlobals(); C:ForceReapply() end
end

function Page:Select(key)
    self.selectedKey = key
    if self.panel then self.panel:Refresh() end
    self:RefreshLabels()
end

function Page:RefreshLabels()
    local C = ThugUI.Camera
    if self.activeLabel then
        self.activeLabel:SetText("Active now: |cffffffff"
            .. LabelFor(C and C:GetActiveSituation()) .. "|r")
    end
end

function Page:Build(host, panel)
    local C = ThugUI.Camera
    if not C then return end
    self.panel = panel

    panel:Header("Camera")
    panel:Note("Situations are checked in priority order and the first that "
        .. "applies wins: NPC dialogue, flight path, fishing, AFK, combat, mounted, "
        .. "swimming, battleground/arena, dungeon/raid, city, indoors, outdoors. "
        .. "The first time an Action Cam setting takes effect Blizzard shows a "
        .. "one-time \"experimental features\" warning -- accept it.")

    panel:Checkbox{
        label = "Enable the camera module",
        get = function() return Cfg().enabled end,
        set = function(v) C:SetEnabled(v) end,
    }

    panel:Section("Action Cam (always on)")

    panel:Slider{
        label = "Shoulder offset", min = -2, max = 2, step = 0.1, format = "%.1f",
        tooltip = "Moves the camera sideways. Situations can override it.",
        get = function() return Cfg().shoulderOffset end,
        set = function(v) Cfg().shoulderOffset = v; ApplySituation() end,
    }
    panel:Slider{
        label = "Max zoom factor", min = 1.0, max = 2.6, step = 0.1, format = "%.1f",
        get = function() return Cfg().maxZoomFactor end,
        set = function(v) Cfg().maxZoomFactor = v; ApplyGlobals() end,
    }
    panel:Slider{
        label = "Zoom speed", min = 1, max = 50, step = 1, format = "%d",
        get = function() return Cfg().zoomSpeed end,
        set = function(v) Cfg().zoomSpeed = v; ApplyGlobals() end,
    }
    panel:Slider{
        label = "Transition time (s)", min = 0, max = 3, step = 0.1, format = "%.1f",
        tooltip = "How long shoulder offset and the UI fade take to change.",
        get = function() return Cfg().transitionTime end,
        set = function(v) Cfg().transitionTime = v end,
    }
    panel:Slider{
        label = "Resume rotation after (s)", min = 1, max = 15, step = 1, format = "%d",
        tooltip = "Slow rotation stops when you move the camera and starts again "
            .. "after this long without camera input.",
        get = function() return Cfg().rotateResumeDelay end,
        set = function(v) Cfg().rotateResumeDelay = v end,
    }
    panel:Checkbox{
        label = "Dynamic pitch",
        get = function() return Cfg().dynamicPitch end,
        set = function(v) Cfg().dynamicPitch = v; ApplyGlobals() end,
    }
    panel:Checkbox{
        label = "Turn toward enemies",
        get = function() return Cfg().focusEnemy end,
        set = function(v) Cfg().focusEnemy = v; ApplyGlobals() end,
    }
    panel:Checkbox{
        label = "Turn toward NPCs you talk to",
        get = function() return Cfg().focusInteract end,
        set = function(v) Cfg().focusInteract = v; ApplyGlobals() end,
    }
    panel:Checkbox{
        label = "Head movement",
        get = function() return Cfg().headMovement end,
        set = function(v) Cfg().headMovement = v; ApplyGlobals() end,
    }

    panel:Section("Situations")

    local options = {}
    for _, s in ipairs(C.SITUATIONS) do
        table.insert(options, { value = s.key, text = s.label })
    end
    panel:Dropdown{
        label = "Situation to edit",
        width = 200,
        options = options,
        get = function() return Page.selectedKey end,
        set = function(v) Page:Select(v) end,
    }
    self.activeLabel = panel:Label("Active now:")

    
    
    panel:Checkbox{
        label = "Use this situation (Outdoors is always on)",
        get = function() return Page.selectedKey == "world" or Sit().enabled end,
        set = function(v)
            if Page.selectedKey ~= "world" then Sit().enabled = v end
            ApplySituation()
        end,
    }
    panel:Slider{
        label = "Zoom distance (0 = don't change)", min = 0, max = 39, step = 1, format = "%d",
        get = function() return Sit().zoom end,
        set = function(v) Sit().zoom = v; ApplySituation() end,
    }
    panel:Checkbox{
        label = "Override shoulder offset",
        get = function() return Sit().overrideShoulder end,
        set = function(v) Sit().overrideShoulder = v; ApplySituation() end,
    }
    panel:Slider{
        label = "Shoulder offset (this situation)", min = -2, max = 2, step = 0.1, format = "%.1f",
        indent = 24,
        get = function() return Sit().shoulder end,
        set = function(v) Sit().shoulder = v; ApplySituation() end,
    }
    panel:Checkbox{
        label = "Rotate slowly",
        get = function() return Sit().rotate end,
        set = function(v) Sit().rotate = v; ApplySituation() end,
    }
    panel:Slider{
        label = "Rotation speed (degrees/s)", min = 1, max = 30, step = 1, format = "%d",
        indent = 24,
        get = function() return Sit().rotateSpeed end,
        set = function(v) Sit().rotateSpeed = v; ApplySituation() end,
    }
    panel:Slider{
        label = "Swing (degrees: - left, + right)", min = -180, max = 180, step = 5, format = "%d",
        tooltip = "Turns the camera round by this much when the situation starts, "
            .. "over the transition time. About 75 on NPC dialogue pulls round to "
            .. "show you and the NPC; the zoom and shoulder offset frame the shot.",
        get = function() return Sit().swing or 0 end,
        set = function(v) Sit().swing = v; ApplySituation() end,
    }
    panel:Checkbox{
        label = "Swing back when it ends",
        indent = 24,
        get = function() return Sit().swingBack ~= false end,
        set = function(v) Sit().swingBack = v and true or false; ApplySituation() end,
    }
    panel:Checkbox{
        label = "Fade the UI",
        tooltip = "Never in combat. NPC dialogue only fades while the ThugUI "
            .. "dialogue window is in use, or Blizzard's own window would vanish.",
        get = function() return Sit().fadeUI end,
        set = function(v) Sit().fadeUI = v; ApplySituation() end,
    }
    panel:Checkbox{
        label = "Return to previous zoom on exit",
        get = function() return Sit().restoreZoom end,
        set = function(v) Sit().restoreZoom = v; ApplySituation() end,
    }

    self:RefreshLabels()
end

ThugUI.Window:RegisterPage{
    id = "camera",
    category = "ui",
    order = 80,
    scopeKeys = { "Camera" },
    summary = "Action Cam settings and fixed camera situations.",
    title = "Camera",
    build = function(host, panel) Page:Build(host, panel) end,
    refresh = function() Page:RefreshLabels() end,
}
