
























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
}



local KEYS = {
    orbHealth = true, orbResource = true, target = true, tot = true,
    controllerButtons = true, castBar = true, xpBar = true,
    blizzXP = true, buffs = true, debuffs = true, minimap = true,
    resourcePips = true,  
    resourcePipsRing = true,  
    tooltip = true,       
}

local callbacks = {}



local inCombat = false
local isResting = false

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
    if inCombat then
        return s.mode == "nocombat" and 0 or 1
    end
    if isResting and s.hideResting then return 0 end
    if s.mode == "combat" then return 0 end
    return tonumber(s.oocAlpha) or 1
end



function V:IsDefault(key)
    local s = Read(key)
    return s.mode == "always" and not s.hideResting and s.oocAlpha == 1 and not s.showSoft
        and not s.showTarget
end

function V:InCombat()
    return inCombat
end


local function Fire(key)
    local list = callbacks[key]
    if not list then return end
    local alpha = V:Alpha(key)
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
    elseif event == "PLAYER_ENTERING_WORLD" then
        inCombat = InCombatLockdown() and true or false
        isResting = IsResting() and true or false
    end
    
    FireAll()
end)

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
end



local MODE_OPTIONS = {
    
    { text = "Always", value = "always" },
    { text = "Only in combat", value = "combat" },
    { text = "Only out of combat", value = "nocombat" },
}

function V:AddControls(panel, key, opts)
    opts = opts or {}
    
    
    if panel.Group then panel:Group("When to show") end
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
    if panel.Group then panel:Group("Targets (these win over the above)") end
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
end

V.KEYS = KEYS  
ThugUI:RegisterModule("Visibility", V)
