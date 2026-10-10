







































local ThugUI = _G.ThugUI
local V = {}
ThugUI.Visibility = V
ThugUI.defaults.Visibility = {}

local DEFAULTS = {
    mode = "always",     
    hideResting = false,
    oocAlpha = 1,
    showSoft = false,
    softAlpha = 0.5,
    showTarget = false,  
    targetAlpha = 1,
    fadeMoving = false,  
    movingAlpha = 0.3,
    movingFadeTime = 0,  
    
    
    
    padReveal = false,
    padHold = 1.5,
    padFadeTime = 3,
    padIdleAlpha = 0,
    movingCity = false,
    movingWorld = true,
    movingInstance = false,
    movingPvp = false,
    movingCombat = false,
}



local KEYS = {
    orbHealth = true, orbResource = true, target = true, tot = true,
    controllerButtons = true, castBar = true, xpBar = true,
    blizzXP = true, buffs = true, debuffs = true, minimap = true,
    resourcePips = true,  
    resourcePipsRing = true,  
    orbHealthDecor = true, orbHealthOrb = true, orbHealthRing = true, orbHealthArt = true,
    orbResourceDecor = true, orbResourceOrb = true, orbResourceRing = true, orbResourceArt = true,
    resourcePipsBody = true,
    tooltip = true,       
    party = true,         
    
    
    controllerStream = true, acornStream = true,
}

local callbacks = {}



local inCombat = false
local isResting = false
local isMoving = false
local movingSince = 0     
local MAX_FADE_TIME = 20
local lastPadInput = -math.huge   



local function CurrentZone()
    local ok, inInstance, instanceType = pcall(IsInInstance)
    if ok and inInstance then
        if instanceType == "pvp" or instanceType == "arena" then return "pvp" end
        return "instance"
    end
    if isResting then return "city" end
    return "world"
end
V.CurrentZone = CurrentZone

local ZONE_FIELD = { city = "movingCity", world = "movingWorld", instance = "movingInstance", pvp = "movingPvp" }

local function MovingFadeApplies(s)
    if not (s.fadeMoving and isMoving) then return false end
    if inCombat then return s.movingCombat and true or false end
    return s[ZONE_FIELD[CurrentZone()] ] and true or false
end

V.driver = CreateFrame("Frame")




local function Read(key)
    if not KEYS[key] then error("Invalid Visibility key: " .. tostring(key)) end
    local t = ThugUIDB.Visibility and ThugUIDB.Visibility[key]
    if not t then return DEFAULTS end
    return setmetatable({}, { __index = function(_, k)
        local v = t[k]
        if v == nil then return DEFAULTS[k] end
        return v
    end })
end


function V:Get(key)
    if not KEYS[key] then error("Invalid Visibility key: " .. tostring(key)) end
    ThugUIDB.Visibility = ThugUIDB.Visibility or {}
    local t = ThugUIDB.Visibility[key]
    if not t then
        t = {}
        ThugUIDB.Visibility[key] = t
    end
    for k, v in pairs(DEFAULTS) do
        if t[k] == nil then t[k] = v end
    end
    return t
end



function V:HasSoftTarget()
    local okE, hasE = pcall(UnitExists, "softenemy")
    local okF, hasF = pcall(UnitExists, "softfriend")
    return (okE and hasE or okF and hasF) and true or false
end

function V:HasTarget()
    local ok, has = pcall(UnitExists, "target")
    return ok and has and true or false
end


local function Override(self, s)
    if s.showTarget and self:HasTarget() then return "target" end
    if s.showSoft and self:HasSoftTarget() then return "soft" end
    return nil
end



function V:IsOverrideShown(key)
    return Override(self, Read(key)) ~= nil
end

V.IsSoftShown = V.IsOverrideShown

function V:Alpha(key)
    local s = Read(key)
    local o = Override(self, s)
    if o == "target" then return tonumber(s.targetAlpha) or 1 end
    if o == "soft" then return tonumber(s.softAlpha) or 0.5 end
    local a
    if inCombat then
        a = s.mode == "nocombat" and 0 or 1
    elseif isResting and s.hideResting then
        a = 0
    elseif s.mode == "combat" then
        a = 0
    else
        a = tonumber(s.oocAlpha) or 1
    end
    if a > 0 and MovingFadeApplies(s) then
        a = math.min(a, tonumber(s.movingAlpha) or 0.3)
    end
    return a
end

local function FadeTime(s)
    local t = tonumber(s.movingFadeTime) or 0
    if t < 0 then return 0 end
    if t > MAX_FADE_TIME then return MAX_FADE_TIME end
    return t
end



local function FadeProgress(s)
    local t = FadeTime(s)
    if t <= 0 then return 1 end
    local p = (GetTime() - movingSince) / t
    if p >= 1 then return 1 end
    if p <= 0 then return 0 end
    return p
end



local function Clamp(v, lo, hi, d)
    v = tonumber(v) or d
    if v < lo then return lo elseif v > hi then return hi end
    return v
end




local function PadRevealAlpha(self, s, target)
    if not s.padReveal or Override(self, s) ~= nil then return target end
    if isMoving then return target end
    local since = GetTime() - lastPadInput
    local hold = Clamp(s.padHold, 0, 10, 1.5)
    if since <= hold then return target end
    local low = math.min(target, Clamp(s.padIdleAlpha, 0, 1, 0))
    local fade = Clamp(s.padFadeTime, 0, MAX_FADE_TIME, 3)
    if fade <= 0 then return low end
    local p = (since - hold) / fade
    if p >= 1 then return low end
    return target + (low - target) * p
end


local function PadRevealBusy(s)
    if not s.padReveal or isMoving then return false end
    local since = GetTime() - lastPadInput
    return since < Clamp(s.padHold, 0, 10, 1.5) + Clamp(s.padFadeTime, 0, MAX_FADE_TIME, 3)
end

function V:CurrentAlpha(key)
    local s = Read(key)
    if s.padReveal then return PadRevealAlpha(self, s, self:Alpha(key)) end
    local target = self:Alpha(key)
    if not (MovingFadeApplies(s) and Override(self, s) == nil) then return target end
    local p = FadeProgress(s)
    if p >= 1 then return target end
    
    local wasMoving = isMoving
    isMoving = false
    local usual = self:Alpha(key)
    isMoving = wasMoving
    if target >= usual then return target end
    return usual + (target - usual) * p
end

function V:IsMoving()
    return isMoving
end



function V:IsDefault(key)
    local s = Read(key)
    return s.mode == "always" and not s.hideResting and s.oocAlpha == 1 and not s.showSoft
        and not s.showTarget and not s.fadeMoving and not s.padReveal
end

function V:InCombat()
    return inCombat
end


local function Fire(key)
    local list = callbacks[key]
    if not list then return end
    local alpha = V:CurrentAlpha(key)
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, alpha)
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("VISIBILITY", "%s callback failed: %s", key, tostring(err))
        end
    end
end

local function FireAll()
    for key in pairs(callbacks) do Fire(key) end
end



local function FireMoving()
    for key in pairs(callbacks) do
        local t = ThugUIDB.Visibility and ThugUIDB.Visibility[key]
        if t and t.fadeMoving then Fire(key) end
    end
end



local FADE_STEP = 1 / 30
local fadeElapsed = 0
local function FadeTick(_, elapsed)
    fadeElapsed = fadeElapsed + (elapsed or 0)
    if fadeElapsed < FADE_STEP then return end
    fadeElapsed = 0
    local busy = false
    if isMoving then
        for key in pairs(callbacks) do
            local t = ThugUIDB.Visibility and ThugUIDB.Visibility[key]
            if t and t.fadeMoving and FadeTime(Read(key)) > 0 then
                Fire(key)
                if FadeProgress(Read(key)) < 1 then busy = true end
            end
        end
    end
    
    for key in pairs(callbacks) do
        local t = ThugUIDB.Visibility and ThugUIDB.Visibility[key]
        if t and t.padReveal then
            local s = Read(key)
            local wasBusy = PadRevealBusy(s)
            Fire(key)
            if wasBusy then busy = true end
        end
    end
    if not busy then V.driver:SetScript("OnUpdate", nil) end
end

function V:Register(key, fn)
    if not KEYS[key] then error("Invalid Visibility key: " .. tostring(key)) end
    callbacks[key] = callbacks[key] or {}
    table.insert(callbacks[key], fn)
end

function V:Set(key, field, value)
    self:Get(key)[field] = value
    Fire(key)
end

V.driver:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
    elseif event == "PLAYER_UPDATE_RESTING" then
        isResting = IsResting() and true or false
    elseif event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STOPPED_MOVING" then
        isMoving = event == "PLAYER_STARTED_MOVING"
        if isMoving then
            movingSince = GetTime()
            fadeElapsed = 0
            V.driver:SetScript("OnUpdate", FadeTick)
        else
            V.driver:SetScript("OnUpdate", nil)
            
            
            V:PadActivity()
        end
        FireMoving()
        return
    elseif event == "PLAYER_ENTERING_WORLD" then
        inCombat = InCombatLockdown() and true or false
        isResting = IsResting() and true or false
        
        local ok, moving = pcall(IsPlayerMoving)
        isMoving = ok and moving and true or false
    end
    
    
    FireAll()
end)



function V:PadActivity()
    lastPadInput = GetTime()
    local any = false
    for key in pairs(callbacks) do
        local t = ThugUIDB.Visibility and ThugUIDB.Visibility[key]
        if t and t.padReveal then Fire(key); any = true end
    end
    if any then
        fadeElapsed = 0
        V.driver:SetScript("OnUpdate", FadeTick)
    end
end







function V:EnsurePadListener()
    if self.padListener or not ThugUI:IsModuleOn("controller") then return end
    if InCombatLockdown and InCombatLockdown() then return end   
    local f = CreateFrame("Frame", "ThugUI_VisibilityPadListener", UIParent)
    f:SetSize(1, 1)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    f:EnableGamePadButton(true)
    f:SetPropagateKeyboardInput(true)
    f:SetScript("OnGamePadButtonDown", function() V:PadActivity() end)
    f:Show()
    self.padListener = f
end

function V:Initialize()
    inCombat = InCombatLockdown() and true or false
    isResting = IsResting and IsResting() and true or false
    
    
    
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_REGEN_DISABLED")
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_UPDATE_RESTING")
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_SOFT_ENEMY_CHANGED")
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_SOFT_FRIEND_CHANGED")
    
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_TARGET_CHANGED")
    
    
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_STARTED_MOVING")
    ThugUI.SafeRegisterEvent(V.driver, "PLAYER_STOPPED_MOVING")
    ThugUI.SafeRegisterEvent(V.driver, "ZONE_CHANGED_NEW_AREA")
    
    
    pcall(V.EnsurePadListener, V)
end



local MODE_OPTIONS = {
    
    { text = "Always", value = "always" },
    { text = "Only in combat", value = "combat" },
    { text = "Only out of combat", value = "nocombat" },
}





local function Head(panel, opts, heading, tab)
    if opts and opts.split and panel.SubSection and panel.inTabbedFrameSection and panel.partIndex then
        panel:SubSection(tab)
        if panel.Part then panel:Part("Visibility") end
        return
    end
    if panel.Group then panel:Group(heading) end
end
V.Head = Head

function V:AddControls(panel, key, opts)
    opts = opts or {}
    
    
    Head(panel, opts, "When to show", "When to show")
    panel:Dropdown{
        label = "Show",
        options = MODE_OPTIONS,
        get = function() return Read(key).mode end,
        set = function(val) V:Set(key, "mode", val) end,
    }
    panel:Checkbox{
        label = "Hide while resting (inns and cities)",
        get = function() return Read(key).hideResting end,
        set = function(val) V:Set(key, "hideResting", val and true or false) end,
    }
    if not opts.noOpacity then
        panel:Slider{
            label = "Out-of-combat opacity",
            tooltip = "How visible the frame is out of combat when nothing above hides it. "
                .. "At 0 it is invisible out of combat even with Show set to Always.",
            min = 0, max = 1, step = 0.05, format = "%.2f",
            get = function() return Read(key).oocAlpha end,
            set = function(val) V:Set(key, "oocAlpha", val) end,
        }
    end
    
    
    
    if opts.afterWhen then opts.afterWhen(panel) end
    Head(panel, opts, "Targets (these win over the above)", "Targets")
    panel:Checkbox{
        label = "Show with a target",
        tooltip = "While you have a target (not just a soft target), the frame shows, "
            .. "whatever else it is set to hide for.",
        get = function() return Read(key).showTarget end,
        set = function(val) V:Set(key, "showTarget", val and true or false) end,
    }
    if not opts.noOpacity then
        panel:Slider{
            label = "Target opacity",
            min = 0, max = 1, step = 0.05, format = "%.2f",
            get = function() return Read(key).targetAlpha end,
            set = function(val) V:Set(key, "targetAlpha", val) end,
        }
    end
    panel:Checkbox{
        label = "Show with a soft target",
        tooltip = "While the game has a soft target for you, the frame shows, "
            .. "whatever else it is set to hide for. A real target wins over this.",
        get = function() return Read(key).showSoft end,
        set = function(val) V:Set(key, "showSoft", val and true or false) end,
    }
    if not opts.noOpacity then
        panel:Slider{
            label = "Soft-target opacity",
            min = 0, max = 1, step = 0.05, format = "%.2f",
            get = function() return Read(key).softAlpha end,
            set = function(val) V:Set(key, "softAlpha", val) end,
        }
    end
    if opts.moving then V:AddMovingControls(panel, key, opts) end
    if opts.padReveal then V:AddPadRevealControls(panel, key, opts) end
end



function V:AddPadRevealControls(panel, key, opts)
    Head(panel, opts, "Gamepad input", "Gamepad input")
    panel:Checkbox{
        label = "Show only on gamepad input",
        tooltip = "Hidden until you press a gamepad button or move; then it shows at once. "
            .. "When you stop, it waits, then fades to the opacity below.",
        get = function() return Read(key).padReveal end,
        set = function(val) V:Set(key, "padReveal", val and true or false); if panel.Refresh then panel:Refresh() end end,
    }
    if panel.ActiveIf then panel:ActiveIf(function() return Read(key).padReveal == true end) end
    panel:Slider{
        label = "Stay for",
        tooltip = "Seconds the frame stays fully shown after your last press, before it starts to fade.",
        min = 0, max = 10, step = 0.5, format = "%.1f s",
        get = function() return Read(key).padHold end,
        set = function(val) V:Set(key, "padHold", val) end,
    }
    panel:Slider{
        label = "Fade time",
        tooltip = "Seconds to fade from shown to the opacity below. 0 hides it at once.",
        min = 0, max = MAX_FADE_TIME, step = 0.5, format = "%.1f s",
        get = function() return Read(key).padFadeTime end,
        set = function(val) V:Set(key, "padFadeTime", val) end,
    }
    panel:Slider{
        label = "Opacity when idle",
        tooltip = "0 hides it completely between inputs.",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return Read(key).padIdleAlpha end,
        set = function(val) V:Set(key, "padIdleAlpha", val) end,
    }
    if panel.ActiveIf then panel:ActiveIf(nil) end
end



function V:AddMovingControls(panel, key, opts)
    Head(panel, opts, "While moving", "While moving")
    panel:Checkbox{
        label = "Fade while moving",
        tooltip = "While your character moves, the frame drops to the opacity below, "
            .. "but only where a box below is ticked. A target still shows it.",
        get = function() return Read(key).fadeMoving end,
        set = function(val) V:Set(key, "fadeMoving", val and true or false) end,
    }
    panel:Slider{
        label = "Opacity while moving",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return Read(key).movingAlpha end,
        set = function(val) V:Set(key, "movingAlpha", val) end,
    }
    panel:Slider{
        label = "Fade time",
        tooltip = "Seconds to fade down to the opacity above once you start moving. "
            .. "0 drops at once. Stopping always brings the frame straight back.",
        min = 0, max = MAX_FADE_TIME, step = 0.5, format = "%.1f s",
        get = function() return Read(key).movingFadeTime end,
        set = function(val) V:Set(key, "movingFadeTime", val) end,
    }
    local boxes = {
        { "movingCity", "In a city", "Cities and inns: wherever the game says you are resting." },
        { "movingWorld", "In the world", "Outside any dungeon, raid or battleground, and not resting." },
        { "movingInstance", "In a dungeon or raid", "Includes scenarios." },
        { "movingPvp", "In a battleground or arena", nil },
        { "movingCombat", "In combat", "In a fight only this box counts, and it wins over the zone boxes: "
            .. "ticked, moving fades the frame wherever you are; unticked, combat shows it as usual." },
    }
    for _, b in ipairs(boxes) do
        local field = b[1]
        panel:Checkbox{
            label = b[2],
            tooltip = b[3],
            get = function() return Read(key)[field] end,
            set = function(val) V:Set(key, field, val and true or false) end,
        }
    end
end

V.KEYS = KEYS  
ThugUI:RegisterModule("Visibility", V)
