



























































local ThugUI = _G.ThugUI
local PL = {}
ThugUI.PadLayout = PL
ThugUI:RegisterModule("PadLayout", PL)






ThugUI.defaults.PadLayout = { version = 0, padOverride = "", slots = {}, resetFrom = {} }

local function Log(fmt, ...)
    if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then ThugUI.Diagnostics:Log("PADLAYOUT", fmt, ...) end
end

local function Cfg() return ThugUIDB and ThugUIDB.PadLayout end





PL.XBOX = ThugUI.StickReload and ThugUI.StickReload.XBOX or "xbox"
PL.PLAYSTATION = ThugUI.StickReload and ThugUI.StickReload.PLAYSTATION or "playstation"
local XBOX, PLAYSTATION = PL.XBOX, PL.PLAYSTATION





PL.pending = false
PL.refused = {}
PL.listen = {}
PL.applied = {}
PL.ours = {}


PL.lent = {}
PL.yieldingRadial = false
PL.yieldKeys = {}
PL.doublePress = nil





PL.SLOTS = {
    { id = "start",    title = "Start button" },
    { id = "starttwice", title = "Start twice" },
    { id = "view",     title = "View button" },
    { id = "viewtwice", title = "Select twice" },
    { id = "share",    title = "Share button" },
    { id = "logo",     title = "Logo button" },
    { id = "logohold", title = "Logo hold" },
    { id = "touchpad", title = "Touchpad click" },
    
    { id = "cross",    title = "L1+R1+bottom button" },
    
    
    
    { id = "l1right",   title = "L1 + D-pad right" },
    { id = "r1right",   title = "R1 + D-pad right" },
    { id = "l1r1top",   title = "L1+R1+top button" },
    { id = "l1r1right", title = "L1+R1+right button" },
    { id = "l1r1left",  title = "L1+R1+left button" },
    { id = "l1r1up",    title = "L1+R1+D-pad up" },
    { id = "l1r1down",  title = "L1+R1+D-pad down" },
}
PL.SLOT_BY_ID = {}
for _, slot in ipairs(PL.SLOTS) do PL.SLOT_BY_ID[slot.id] = slot end
local SLOT_BY_ID = PL.SLOT_BY_ID




PL.TWICE_OF = { starttwice = "start", viewtwice = "view" }
local TWICE_OF = PL.TWICE_OF
PL.HOLD_OF = { logohold = "logo" }
local HOLD_OF = PL.HOLD_OF

local function ParentOf(slotId) return TWICE_OF[slotId] or HOLD_OF[slotId] end
local function IsTwice(slotId) return TWICE_OF[slotId] ~= nil end
local function IsHold(slotId) return HOLD_OF[slotId] ~= nil end
local function IsSharedKeySlot(slotId) return ParentOf(slotId) ~= nil end


local CROSS_KEY = _G.GAMEPAD_FACE_BOTTOM or "PAD1"

















local RIGHT_KEY  = _G.GAMEPAD_FACE_RIGHT or "PAD2"
local LEFT_KEY   = _G.GAMEPAD_FACE_LEFT or "PAD3"
local TOP_KEY    = _G.GAMEPAD_FACE_TOP or "PAD4"
local DRIGHT_KEY = _G.GAMEPAD_DPAD_RIGHT or "PADDRIGHT"
local DTOP_KEY   = _G.GAMEPAD_DPAD_TOP or "PADDUP"
local DBOTTOM_KEY = _G.GAMEPAD_DPAD_BOTTOM or "PADDDOWN"
PL.KEYS = {
    [PLAYSTATION] = { start = "PADFORWARD", view = "PADSOCIAL", share = "PAD5",      touchpad = "PADBACK", logo = "PADSYSTEM", cross = CROSS_KEY,
                      l1right = DRIGHT_KEY, r1right = DRIGHT_KEY, l1r1top = TOP_KEY, l1r1right = RIGHT_KEY,
                      l1r1left = LEFT_KEY, l1r1up = DTOP_KEY, l1r1down = DBOTTOM_KEY },
    [XBOX]        = { start = "PADFORWARD", view = "PADBACK",   share = "PADSOCIAL",                       logo = "PADSYSTEM", cross = CROSS_KEY,
                      l1right = DRIGHT_KEY, r1right = DRIGHT_KEY, l1r1top = TOP_KEY, l1r1right = RIGHT_KEY,
                      l1r1left = LEFT_KEY, l1r1up = DTOP_KEY, l1r1down = DBOTTOM_KEY },
}



PL.LABELS = {
    [PLAYSTATION] = { start = "Options", view = "Create", share = "Mute", touchpad = "Touchpad", logo = "PS button",   cross = "Cross",
                      l1right = "D-pad right", r1right = "D-pad right", l1r1top = "Triangle", l1r1right = "Circle",
                      l1r1left = "Square", l1r1up = "D-pad up", l1r1down = "D-pad down" },
    [XBOX]        = { start = "Menu",    view = "View",   share = "Share",                       logo = "Xbox button", cross = "A",
                      l1right = "D-pad right", r1right = "D-pad right", l1r1top = "Y", l1r1right = "B",
                      l1r1left = "X", l1r1up = "D-pad up", l1r1down = "D-pad down" },
}

local function KnownKind(v) return v == XBOX or v == PLAYSTATION end








































local function Job(action, title, index) return { action = action, title = title, unkeyed = true, barButton = index } end
local ASSIST = Job("ASSISTTARGET", "Assist target", 3)
PL.BAR_JOBS = {
    shortcuts = {
        Job("BARJOB_PAGE_PREV", "Previous action bar page", 1),   
        Job("BARJOB_OBJECTIVES", "Quest tracker focus", 2),       
        Job("BARJOB_PAGE_NEXT", "Next action bar page", 3),       
        Job("BARJOB_CHAT", "Chat focus", 4),                      
        Job("TOGGLESHEATH", "Sheathe / draw weapon", 5),          
        Job("BARJOB_BUFFS", "Buffs focus", 6),                    
        Job("BARJOB_BAGS", "Open bags", 7),                       
        Job("TARGETFOCUS", "Target focus", 8),                    
    },
    friendly = {
        
        swapped = { Job("BARJOB_FRIENDLY_PET", "Target pet", 1), Job("BARJOB_FRIENDLY_MARKER", "Raid marker: next", 2),
                    ASSIST, Job("BARJOB_FRIENDLY_SELF", "Target self", 4),
                    Job("BARJOB_FRIENDLY_LEFT", "Party / raid: left", 5), Job("BARJOB_FRIENDLY_UP", "Party / raid: up", 6),
                    Job("BARJOB_FRIENDLY_RIGHT", "Party / raid: right", 7), Job("BARJOB_FRIENDLY_DOWN", "Party / raid: down", 8) },
        
        plain = { Job("BARJOB_FRIENDLY_LEFT", "Party / raid: left", 1), Job("BARJOB_FRIENDLY_UP", "Party / raid: up", 2),
                  Job("BARJOB_FRIENDLY_RIGHT", "Party / raid: right", 3), Job("BARJOB_FRIENDLY_DOWN", "Party / raid: down", 4),
                  Job("BARJOB_FRIENDLY_PET", "Target pet", 5), Job("BARJOB_FRIENDLY_MARKER", "Raid marker: next", 6),
                  Job("ASSISTTARGET", "Assist target", 7), Job("BARJOB_FRIENDLY_SELF", "Target self", 8) },
    },
    hostile = {
        
        swapped = { Job("BARJOB_HOSTILE_SHOOT", "Ranged attack", 1), Job("BARJOB_HOSTILE_MARKER", "Raid marker: previous", 2),
                    ASSIST, Job("BARJOB_HOSTILE_LAST", "Target last enemy", 4), false, false, false, false },
        plain = { false, false, false, false,
                  Job("BARJOB_HOSTILE_SHOOT", "Ranged attack", 5), Job("BARJOB_HOSTILE_MARKER", "Raid marker: previous", 6),
                  Job("ASSISTTARGET", "Assist target", 7), Job("BARJOB_HOSTILE_LAST", "Target last enemy", 8) },
    },
}
PL.BAR_ONLY = {}
for _, group in pairs(PL.BAR_JOBS) do
    for _, list in pairs(group.swapped and group or { group }) do
        if type(list) == "table" then
            for _, job in pairs(list) do
                if type(job) == "table" and job.action:sub(1, 7) == "BARJOB_" then PL.BAR_ONLY[job.action] = true end
            end
        end
    end
end




PL.BAR_SLOT = {
    l1right   = { bar = "L1",   index = 3 },
    r1right   = { bar = "R1",   index = 3 },
    l1r1top   = { bar = "BOTH", index = 6 },
    l1r1right = { bar = "BOTH", index = 7 },
    l1r1left  = { bar = "BOTH", index = 5 },
    l1r1up    = { bar = "BOTH", index = 2 },
    l1r1down  = { bar = "BOTH", index = 4 },
}
local BAR_SLOT = PL.BAR_SLOT



local function CVarOn(name)
    local ok, v
    if C_CVar and C_CVar.GetCVarBool then
        ok, v = pcall(C_CVar.GetCVarBool, name)
    elseif type(GetCVarBool) == "function" then
        ok, v = pcall(GetCVarBool, name)
    end
    if ok and v ~= nil then return v and true or false end
    return nil
end





function PL:BarOf(slotId)
    local spec = BAR_SLOT[slotId]
    if not spec then return nil end
    if spec.bar == "BOTH" then return "shortcuts" end
    local swapMods = CVarOn("GamepadSwapTargetModifiers") == true
    local leftIsFriendly = not swapMods
    if spec.bar == "L1" then return leftIsFriendly and "friendly" or "hostile" end
    return leftIsFriendly and "hostile" or "friendly"
end


function PL:BarFrame(name)
    if name == "shortcuts" then
        local CM = ThugUI.ControllerMode
        return CM and CM.GetShortcutsBar and CM:GetShortcutsBar() or nil
    end
    local main = _G.GamepadMainActionBarFrame
    local unit = main and main.PageUnit
    local all = unit and unit.actionBars
    if name == "friendly" then return (all and all.friendlyTargetingBar) or (unit and unit.FriendlyTargetingActionBar) or nil end
    if name == "hostile" then return (all and all.hostileTargetingBar) or (unit and unit.HostileTargetingActionBar) or nil end
    return nil
end


function PL:BarShown(slotId)
    local bar = self:BarFrame(self:BarOf(slotId))
    return bar ~= nil and bar.IsShown ~= nil and bar:IsShown() and true or false
end




local function BarJobOf(slotId)
    local spec = BAR_SLOT[slotId]
    local bar = spec and PL:BarOf(slotId)
    local jobs = bar and PL.BAR_JOBS[bar]
    if not jobs then return nil, false end
    if bar == "shortcuts" then return jobs[spec.index], true end
    local swapped = CVarOn(bar == "friendly" and "GamepadSwapFriendlyTargetActions" or "GamepadSwapHostileTargetActions")
    if swapped == nil then return nil, false end
    local job = jobs[swapped and "swapped" or "plain"][spec.index]
    return job or nil, true
end






function PL:Kind()
    local cfg = Cfg()
    local override = cfg and cfg.padOverride
    if KnownKind(override) then return override end
    local SR = ThugUI.StickReload
    if SR and SR.PadKind then
        
        
        local ok, kind = pcall(SR.PadKind, SR)
        if ok and KnownKind(kind) then return kind end
    end
    return nil
end



function PL:KeyFor(slotId)
    if not SLOT_BY_ID[slotId] then return nil end
    slotId = ParentOf(slotId) or slotId
    local kind = self:Kind()
    if kind then
        local keys = PL.KEYS[kind]
        return keys and keys[slotId] or nil
    end
    
    local a, b = PL.KEYS[XBOX][slotId], PL.KEYS[PLAYSTATION][slotId]
    if a ~= nil and a == b then return a end
    return nil
end







function PL:SlotForKey(key, barName)
    if type(key) ~= "string" then return nil end
    for _, slot in ipairs(PL.SLOTS) do
        local onBar = BAR_SLOT[slot.id] ~= nil
        if not IsSharedKeySlot(slot.id) and (not onBar or (barName ~= nil and self:BarOf(slot.id) == barName))
            and self:KeyFor(slot.id) == key then
            return slot.id
        end
    end
    return nil
end


function PL:Label(slotId)
    local parent = ParentOf(slotId)
    if parent then return self:Label(parent) .. (IsHold(slotId) and " hold" or " twice") end
    local kind = self:Kind()
    local labels = kind and PL.LABELS[kind]
    local word = labels and labels[slotId]
    if word then return word end
    local slot = SLOT_BY_ID[slotId]
    return slot and slot.title or tostring(slotId)
end



function PL:HasSlot(slotId)
    if not SLOT_BY_ID[slotId] then return false end
    slotId = ParentOf(slotId) or slotId
    local kind = self:Kind()
    if not kind then return true end
    local keys = PL.KEYS[kind]
    return keys ~= nil and keys[slotId] ~= nil
end



function PL:SetPadOverride(v)
    if v ~= "" and not KnownKind(v) then
        Log("SetPadOverride ignored: %s", tostring(v))
        return false
    end
    local cfg = Cfg()
    if not cfg then return false end
    cfg.padOverride = v
    if self.Apply then self:Apply() end
    self:Notify()
    return true
end



















PL.DEFAULTS = {
    start    = { all = { action = "OPENRADIAL", title = "Radial menu" } },
    view     = { [XBOX] = { action = "TOGGLEUIFOCUS", title = "Focus UI" } },        
    touchpad = { [PLAYSTATION] = { action = "TOGGLEUIFOCUS", title = "Focus UI" } },
    cross    = { all = { action = "TARGETFOCUS", title = "Target focus", unkeyed = true } },
    share = {}, logo = {},
    
    
    
    
    
    l1right   = { all = PL.BAR_JOBS.friendly.swapped[3] },
    r1right   = { all = PL.BAR_JOBS.friendly.swapped[3] },
    l1r1top   = { all = PL.BAR_JOBS.shortcuts[6] },
    l1r1right = { all = PL.BAR_JOBS.shortcuts[7] },
    l1r1left  = { all = PL.BAR_JOBS.shortcuts[5] },
    l1r1up    = { all = PL.BAR_JOBS.shortcuts[2] },
    l1r1down  = { all = PL.BAR_JOBS.shortcuts[4] },
}

local function EntryOf(slotId)
    local d = PL.DEFAULTS[slotId]
    if not d then return nil end
    if BAR_SLOT[slotId] then
        local job, known = BarJobOf(slotId)
        if known then return job end
    end
    local kind = PL:Kind()
    return d.all or (kind and d[kind]) or nil
end


function PL:DefaultOf(slotId)
    local e = EntryOf(slotId)
    if not e then return nil end
    return { action = e.action, title = e.title }
end




function PL:LiveKeyOf(action)
    if type(GetBindingKey) ~= "function" then return nil end
    local ok, key = pcall(GetBindingKey, action)
    if ok and type(key) == "string" and key ~= "" then return key end
    return nil
end



function PL:DriftReport()
    local report = {}
    for _, slot in ipairs(PL.SLOTS) do
        local e = EntryOf(slot.id)
        local expected = self:KeyFor(slot.id)
        
        
        if e and not e.unkeyed and not BAR_SLOT[slot.id] and expected and not self.lent[expected] then
            local live = self:LiveKeyOf(e.action)
            if live ~= expected then
                report[#report + 1] = { slot = slot.id, action = e.action, expected = expected, live = live }
            end
        end
    end
    return report
end





local function ParseValue(value)
    if type(value) ~= "string" then return nil end
    local kind, rest = value:match("^(%a+):(.+)$")
    if kind == "spell" then
        local id = tonumber(rest)
        if id then return "spell", id end
        return nil
    end
    if kind == "macro" or kind == "thug" or kind == "blizz" then return kind, rest end
    return nil
end


function PL:Parse(value) return ParseValue(value) end

local badLogged = {}
local function BadValue(value)
    local text = tostring(value)
    if badLogged[text] then return end
    badLogged[text] = true
    Log("bad value %s, treated as the default", text)
end



local function Resolve(value)
    if value == nil or value == "" then return nil end
    local kind, what = ParseValue(value)
    local ok = false
    if kind == "spell" or kind == "macro" then
        ok = true
    elseif kind == "thug" then
        ok = PL:GetAction(what) ~= nil
    elseif kind == "blizz" then
        ok = PL.BLIZZARD_BY_ACTION[what] ~= nil
    end
    if not ok then
        BadValue(value)
        return nil
    end
    return kind, what
end

local function IsDefaultValue(slotId, value)
    local d = PL:DefaultOf(slotId)
    return d ~= nil and value == "blizz:" .. d.action
end



function PL:Get(slotId)
    local cfg = Cfg()
    local slots = cfg and cfg.slots
    return slots and slots[slotId] or nil
end

local callbacks = {}
PL.callbacks = callbacks


function PL:RegisterCallback(fn)
    if type(fn) == "function" then callbacks[#callbacks + 1] = fn end
end

function PL:Notify()
    for _, fn in ipairs(callbacks) do
        local ok, err = pcall(fn, self)
        if not ok then Log("callback failed: %s", tostring(err)) end
    end
    
    
    local PH = ThugUI.PadHints
    if PH and PH.Refresh then
        local ok, err = pcall(PH.Refresh, PH)
        if not ok then Log("legend refresh failed: %s", tostring(err)) end
    end
end



local function NotifyCross()
    local CM = ThugUI.ControllerMode
    if not (CM and CM.NotifyFeature) then return end
    local ok, err = pcall(CM.NotifyFeature, CM, "shortcutCross")
    if not ok then Log("cross notify failed: %s", tostring(err)) end
end




function PL:Set(slotId, value)
    if not SLOT_BY_ID[slotId] then
        Log("Set ignored: unknown slot %s", tostring(slotId))
        return false
    end
    if not self:HasSlot(slotId) then
        Log("Set ignored: no %s on this pad", slotId)
        return false
    end
    local cfg = Cfg()
    if not cfg then return false end
    if value ~= nil and type(value) ~= "string" then
        BadValue(value)
        value = nil
    end
    if IsTwice(slotId) then
        if value == "" then value = nil end
        if value ~= nil then
            local kind, what = Resolve(value)
            
            
            local action = kind == "thug" and self:GetAction(what) or nil
            if not (action and action.double) then
                Log("Set refused %s %s: double press only allows ThugUI menu, reload or screenshot", slotId, tostring(value))
                return false
            end
        end
    end
    
    
    if IsHold(slotId) then
        if value == "" then value = nil end
        if value ~= nil and value ~= "thug:wheel" and value ~= "thug:escmenu" and value ~= "thug:hideui" then
            Log("Set refused %s %s: logo hold only allows ThugUI menu, Escape menu or Toggle user interface", slotId, tostring(value))
            return false
        end
    end
    if value == "" or (value ~= nil and IsDefaultValue(slotId, value)) then
        value = nil
    elseif value ~= nil and not IsHold(slotId) and not Resolve(value) then
        value = nil
    end
    if type(cfg.slots) ~= "table" then cfg.slots = {} end
    local before = cfg.slots[slotId]
    cfg.slots[slotId] = value
    if self.Apply then self:Apply() end
    self:Notify()
    
    
    if slotId == "cross" and before ~= value then NotifyCross() end
    return true
end



PL.ACTIONS = {}
local ACTION_BY_ID = {}
PL.ACTION_BY_ID = ACTION_BY_ID





function PL:RegisterAction(def)
    if type(def) ~= "table" or type(def.id) ~= "string" or def.id == ""
        or type(def.title) ~= "string" then
        Log("RegisterAction refused: needs an id and a title")
        return false
    end
    if (def.binding ~= nil) == (def.run ~= nil) then
        Log("RegisterAction refused %s: exactly one of binding and run", def.id)
        return false
    end
    if def.binding ~= nil and type(def.binding) ~= "string" then
        Log("RegisterAction refused %s: binding is not a name", def.id)
        return false
    end
    if def.run ~= nil and type(def.run) ~= "function" then
        Log("RegisterAction refused %s: run is not a function", def.id)
        return false
    end
    if ACTION_BY_ID[def.id] then
        Log("RegisterAction refused %s: already registered", def.id)
        return false
    end
    local action = { id = def.id, title = def.title, binding = def.binding, run = def.run,
                     defer = def.defer and true or nil, window = def.window and true or nil,
                     windowOrder = def.windowOrder, allSlots = def.allSlots ~= false,
                     double = def.double and true or nil }
    PL.ACTIONS[#PL.ACTIONS + 1] = action
    ACTION_BY_ID[action.id] = action
    return true
end

function PL:GetAction(id) return ACTION_BY_ID[id] end













PL:RegisterAction{ id = "map", title = "World map", binding = "TOGGLEWORLDMAP", window = true, windowOrder = 2 }
PL:RegisterAction{ id = "groupfinder", title = "Group Finder", binding = "TOGGLEGROUPFINDER", window = true, windowOrder = 9 }
PL:RegisterAction{ id = "spellbook", title = "Spellbook", binding = "TOGGLESPELLBOOK", window = true, windowOrder = 5 }
PL:RegisterAction{ id = "professions", title = "Professions", binding = "TOGGLEPROFESSIONBOOK", window = true, windowOrder = 8 }
PL:RegisterAction{ id = "toggleui", title = "Toggle user interface", binding = "TOGGLEUI" }
PL:RegisterAction{ id = "wheel", title = "ThugUI menu", window = true, windowOrder = 1,
    run = function(key) ThugUI.ControllerRadial:Toggle(key) end, double = true }


PL:RegisterAction{ id = "reload", title = "Reload the interface",
    run = function() ReloadUI() end, double = true }


PL:RegisterAction{ id = "screenshot", title = "Screenshot",
    run = function() Screenshot() end, defer = true, double = true }



PL:RegisterAction{ id = "character", title = "Character", binding = "TOGGLECHARACTER0", window = true, windowOrder = 3, allSlots = false }
PL:RegisterAction{ id = "bags", title = "Bags", binding = "OPENALLBAGS", window = true, windowOrder = 4, allSlots = false }
PL:RegisterAction{ id = "talents", title = "Talents", binding = "TOGGLETALENTS", window = true, windowOrder = 6, allSlots = false }
PL:RegisterAction{ id = "questlog", title = "Quest log", binding = "TOGGLEQUESTLOG", window = true, windowOrder = 7, allSlots = false }
PL:RegisterAction{ id = "gamemenu", title = "Game menu", binding = "TOGGLEGAMEMENU", window = true, windowOrder = 10, allSlots = false }












function PL:Command(slotId)
    if IsSharedKeySlot(slotId) then return nil end
    local stored = self:Get(slotId)
    if BAR_SLOT[slotId] and IsDefaultValue(slotId, stored) then return nil end
    local kind, what = Resolve(stored)
    if kind == "thug" then
        local a = ACTION_BY_ID[what]
        return a and a.binding or nil
    elseif kind == "blizz" then
        return what
    elseif kind == "macro" or kind == "spell" then
        return "CLICK ThugUI_Pad_" .. slotId .. ":LeftButton"
    end
    if slotId == "cross" then
        local d = self:DefaultOf("cross")
        return d and d.action or nil
    end
    return nil
end



function PL:RunOf(slotId)
    local kind, what = Resolve(self:Get(slotId))
    if kind ~= "thug" then return nil end
    local a = ACTION_BY_ID[what]
    return a and a.run and not a.binding and a or nil
end


function PL:CrossRun() return self:RunOf("cross") end

PL.SINK_COMMAND = "CLICK ThugUI_PadSink:LeftButton"






function PL:BarCommand(slotId)
    local cmd = self:Command(slotId)
    if cmd then return cmd end
    if BAR_SLOT[slotId] and self:RunOf(slotId) then return PL.SINK_COMMAND end
    return nil
end














PL.BLIZZARD = {
    { action = "OPENRADIAL",         title = "Radial menu",             hidden = true, window = true },
    { action = "TOGGLEUIFOCUS",      title = "Focus UI",                hidden = true, window = true },
    { action = "TARGETFOCUS",        title = "Target focus" },
    { action = "FOCUSTARGET",        title = "Set focus" },
    { action = "ASSISTTARGET",       title = "Assist target" },
    { action = "INTERACTSOFTTARGET", title = "Interact with soft target", hidden = true },
    { action = "TOGGLEAUTORUN",      title = "Auto-run" },
    { action = "TOGGLESHEATH",       title = "Sheathe / draw weapon" },
    { action = "TOGGLEUI",           title = "Hide the interface" },
    { action = "SCREENSHOT",         title = "Screenshot (Blizzard's)" },
    { action = "PINGATTACK",         title = "Ping: attack" },
    { action = "PINGWARNING",        title = "Ping: warning" },
    { action = "PINGONMYWAY",        title = "Ping: on my way" },
    { action = "PINGASSIST",         title = "Ping: assist" },
    { action = "TOGGLEPINGTARGET",   title = "Ping target" },
    { action = "TOGGLEPINGLISTENER", title = "Ping (listener)" },
}
PL.BLIZZARD_BY_ACTION = {}
for _, b in ipairs(PL.BLIZZARD) do PL.BLIZZARD_BY_ACTION[b.action] = b end
local BLIZZARD_BY_ACTION = PL.BLIZZARD_BY_ACTION




























PL.KIND_OF = { start = "menu", starttwice = "twice", view = "menu", viewtwice = "twice", share = "menu", logo = "menu", logohold = "hold", touchpad = "menu", cross = "cross",
               l1right = "dpad", r1right = "dpad",
               l1r1top = "cross", l1r1right = "cross", l1r1left = "cross", l1r1up = "cross", l1r1down = "cross" }
PL.CURATED = {
    menu  = { "OPENRADIAL", "TOGGLEUIFOCUS", "TOGGLEUI", "SCREENSHOT", "TOGGLEAUTORUN", "TOGGLESHEATH" },
    face  = {},
    dpad  = { "ASSISTTARGET", "TARGETFOCUS", "FOCUSTARGET", "INTERACTSOFTTARGET", "TOGGLEPINGTARGET" },
    cross = { "TARGETFOCUS", "FOCUSTARGET", "ASSISTTARGET", "INTERACTSOFTTARGET", "TOGGLEAUTORUN" },
    twice = {},
    hold = {},
}





PL.LISTS = {
    
    
    
    start = { macros = false, spells = false, windowsOnly = true },
    view = { macros = false, spells = false, windowsOnly = true },
    
    
    starttwice = { macros = false, spells = false, blizzard = false, doubleOnly = true },
    viewtwice = { macros = false, spells = false, blizzard = false, doubleOnly = true },
    
    
    logohold = { macros = false, spells = false, blizzard = false, holdOnly = true },
}

local function ListAllowed(slotId, list)
    local flags = PL.LISTS[slotId]
    return not flags or flags[list] ~= false
end

local function WindowsOnly(slotId)
    local flags = PL.LISTS[slotId]
    return flags and flags.windowsOnly == true
end

local function DoubleOnly(slotId)
    local flags = PL.LISTS[slotId]
    return flags and flags.doubleOnly == true
end

local function HoldOnly(slotId)
    local flags = PL.LISTS[slotId]
    return flags and flags.holdOnly == true
end

local HIDDEN_NOTE = "Runs Blizzard's own action; confirm it works on your build"

local function DefaultText(d)
    return d and ("Default: " .. d.title) or "Default: nothing"
end


local function IconFor(value)
    local kind, what = ParseValue(value)
    if kind == "spell" then
        return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(what)
    elseif kind == "macro" and GetMacroInfo then
        local _, icon = GetMacroInfo(what)
        return icon
    end
    return nil
end

local function SafeIcon(value)
    local ok, icon = pcall(IconFor, value)
    if ok then return icon end
    return nil
end

local GENERIC_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"





function PL:Icon(slotId)
    local stored = self:Get(slotId)
    local kind, what = Resolve(stored)
    if kind == "thug" and what == "map" then
        local CS = ThugUI.ControllerShortcuts
        return (CS and CS.MAP_ICON) or GENERIC_ICON
    elseif kind == "macro" or kind == "spell" then
        return SafeIcon(stored)
    end
    return GENERIC_ICON
end

local function SpellName(id)
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
    return name or ("Spell " .. tostring(id))
end



function PL:Describe(slotId)
    local stored = self:Get(slotId)
    if IsHold(slotId) then
        local labels = { ["thug:wheel"] = "ThugUI menu", ["thug:escmenu"] = "Escape menu",
                         ["thug:hideui"] = "Toggle user interface" }
        local label = labels[stored]
        return label and { value = stored, kind = "thug", label = label, isDefault = false, icon = nil }
            or { value = "", kind = "default", label = "Default: nothing", isDefault = true, icon = nil }
    end
    local kind, what = Resolve(stored)
    if kind and IsDefaultValue(slotId, stored) then kind = nil end
    if not kind then
        return { value = "", kind = "default", label = DefaultText(self:DefaultOf(slotId)),
                 isDefault = true, icon = nil }
    end
    local label
    if kind == "spell" then
        label = SpellName(what)
    elseif kind == "macro" then
        label = "Macro: " .. what
    elseif kind == "thug" then
        label = ACTION_BY_ID[what].title
    else
        label = BLIZZARD_BY_ACTION[what].title
    end
    return { value = stored, kind = kind, label = label, isDefault = false, icon = SafeIcon(stored) }
end




function PL:RadialKey()
    for _, slot in ipairs(PL.SLOTS) do
        if self:Get(slot.id) == "blizz:OPENRADIAL" then
            local key = self:KeyFor(slot.id)
            if key then return key end
        end
    end
    for _, slot in ipairs(PL.SLOTS) do
        local default = self:DefaultOf(slot.id)
        if default and default.action == "OPENRADIAL" and self:Describe(slot.id).isDefault then
            local key = self:KeyFor(slot.id)
            if key then return key end
        end
    end
    return nil
end



local function RowForValue(value)
    local kind, what = Resolve(value)
    if not kind then return nil end
    if kind == "spell" then
        return { text = SpellName(what), value = value, icon = SafeIcon(value) }
    elseif kind == "macro" then
        return { text = what, value = value, icon = SafeIcon(value) }
    elseif kind == "thug" then
        return { text = ACTION_BY_ID[what].title, value = value }
    end
    local b = BLIZZARD_BY_ACTION[what]
    return { text = b.title, value = value, note = b.hidden and HIDDEN_NOTE or nil }
end



local function PlainRows(fnName, label)
    local FB = ThugUI.FaceButtons
    local fn = FB and FB[fnName]
    local out = {}
    if not fn then
        Log("%s list failed: FaceButtons.%s is not there", label, fnName)
        return out
    end
    local raw = {}
    local ok, err = pcall(fn, raw)
    if not ok then
        Log("%s list failed: %s", label, tostring(err))
        return out
    end
    return raw
end

local function BlizzardRows(slotId, d)
    local rows = {}
    local windowsOnly = WindowsOnly(slotId)
    if d then
        
        rows[1] = { text = "Default: " .. d.title, value = "" }
    end
    local list = PL.KIND_OF[slotId] and PL.CURATED[PL.KIND_OF[slotId] ] or {}
    for _, action in ipairs(list) do
        local b = BLIZZARD_BY_ACTION[action]
        if b and (not windowsOnly or b.window) and not (d and d.action == action) then
            rows[#rows + 1] = { text = b.title, value = "blizz:" .. action,
                                note = b.hidden and HIDDEN_NOTE or nil }
        end
    end
    
    
    
    local have = {}
    local known = false
    for _, s in ipairs(PL.SLOTS) do if s.id == slotId then known = true end end
    for _, row in ipairs(rows) do have[row.value] = true end
    for _, s in ipairs((not windowsOnly and known) and PL.SLOTS or {}) do
        
        
        
        for _, e in pairs(not BAR_SLOT[s.id] and PL.DEFAULTS[s.id] or {}) do
            local b = BLIZZARD_BY_ACTION[e.action]
            local value = "blizz:" .. e.action
            if b and not have[value] and not (d and d.action == e.action) then
                have[value] = true
                rows[#rows + 1] = { text = b.title, value = value, note = b.hidden and HIDDEN_NOTE or nil }
            end
        end
    end
    return rows
end






function PL:Catalogue(slotId)
    if IsHold(slotId) then
        local stored = self:Get(slotId) or ""
        local cat = { default = { text = "Default: nothing", value = "" }, macros = {}, spells = {}, blizzard = {},
            thug = { { text = "ThugUI menu", value = "thug:wheel" }, { text = "Escape menu", value = "thug:escmenu" },
                     { text = "Toggle user interface", value = "thug:hideui" } } }
        if stored == "" then cat.default.selected = true end
        for _, row in ipairs(cat.thug) do if row.value == stored then row.selected = true end end
        return cat
    end
    local d = self:DefaultOf(slotId)
    local stored = self:Get(slotId)
    local savedKind = Resolve(stored)
    if savedKind and IsDefaultValue(slotId, stored) then stored, savedKind = nil, nil end
    local cat = { default = { text = DefaultText(d), value = "" },
                  macros = {}, spells = {}, thug = {}, blizzard = {} }

    if ListAllowed(slotId, "macros") then
        for _, row in ipairs(PlainRows("Macros", "macro")) do
            
            cat.macros[#cat.macros + 1] = { text = (row.text:gsub("^Macro: ", "")),
                                            value = row.value, icon = SafeIcon(row.value) }
        end
    end
    if ListAllowed(slotId, "spells") then
        for _, row in ipairs(PlainRows("KnownSpells", "spell")) do
            cat.spells[#cat.spells + 1] = { text = row.text, value = row.value, icon = SafeIcon(row.value) }
        end
    end
    if ListAllowed(slotId, "thug") then
        for _, a in ipairs(PL.ACTIONS) do
            if (DoubleOnly(slotId) and a.double) or (WindowsOnly(slotId) and a.window)
                or (not WindowsOnly(slotId) and not DoubleOnly(slotId) and a.allSlots) then
                cat.thug[#cat.thug + 1] = { text = a.title, value = "thug:" .. a.id }
            end
        end
        if WindowsOnly(slotId) then
            table.sort(cat.thug, function(a, b)
                return (ACTION_BY_ID[a.value:sub(6)].windowOrder or 999) < (ACTION_BY_ID[b.value:sub(6)].windowOrder or 999)
            end)
        end
    end
    if ListAllowed(slotId, "blizzard") then
        cat.blizzard = BlizzardRows(slotId, d)
    end

    if savedKind then
        local list = ({ spell = cat.spells, macro = cat.macros, thug = cat.thug, blizz = cat.blizzard })[savedKind]
        local listed = false
        for _, row in ipairs(list) do
            if row.value == stored then listed = true end
        end
        if not listed then list[#list + 1] = RowForValue(stored) end
    end

    local current = stored or ""
    if cat.default.value == current then cat.default.selected = true end
    for _, list in ipairs({ cat.macros, cat.spells, cat.thug, cat.blizzard }) do
        for _, row in ipairs(list) do
            if row.value == current then row.selected = true end
        end
    end
    return cat
end











local function Combat() return InCombatLockdown and InCombatLockdown() or false end

local function Ready()
    return ThugUI:IsModuleOn("controller") and ThugUI.ControllerMode and ThugUI.ControllerMode:IsActive()
end

local SINGLE = { "start", "view", "share", "logo", "touchpad" }





PL.buttons = {}

local function MakeSecure(name)
    local b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:SetSize(1, 1)
    b:SetAlpha(0)
    b:EnableMouse(false)
    b:RegisterForClicks("AnyDown", "AnyUp")
    return b
end

PL.HOLD_TIME = 0.5
PL.HOLD_LOST_TIME = 10
PL.logoHoldDown = nil
PL.hideuiAvailable = false
PL.hideuiLogged = false



PL.HIDEUI_SNIPPET = [[
    if self:GetAttribute("thugui-logo-hold") then
        local ui = owner:GetFrameRef("ui")
        if ui:IsShown() then ui:Hide() else ui:Show() end
    end
]]

function PL:InstallHideUISnippet(button)
    button = button or PL.logoHoldButton
    local ok, err = pcall(function()
        local header = PL.logoHoldHeader or CreateFrame("Frame", "ThugUI_LogoHoldHeader", UIParent, "SecureHandlerBaseTemplate")
        SecureHandlerSetFrameRef(header, "ui", UIParent)
        SecureHandlerWrapScript(button, "OnClick", header, PL.HIDEUI_SNIPPET)
        PL.logoHoldHeader = header
    end)
    PL.hideuiAvailable = ok and true or false
    if not ok then Log("hideui snippet unavailable: %s", tostring(err)) end
    return PL.hideuiAvailable
end

do
    local ok, err = pcall(function() PL.owner = CreateFrame("Frame", "ThugUI_PadOwner", UIParent) end)
    if not ok then Log("owner frame failed, every slot stays Blizzard's: %s", tostring(err)) end
    
    
    
    
    
    for _, id in ipairs({ "start", "view", "share", "logo", "touchpad", "cross",
                          "l1right", "r1right", "l1r1top", "l1r1right", "l1r1left", "l1r1up", "l1r1down" }) do
        ok, err = pcall(function()
            local b = MakeSecure("ThugUI_Pad_" .. id)
            
            
            b:SetAttribute("type", "macro")
            b:SetAttribute("useOnKeyDown", true)
            PL.buttons[id] = b
        end)
        if not ok then Log("button %s failed, that slot stays Blizzard's: %s", id, tostring(err)) end
    end
    ok, err = pcall(function()
        local b = MakeSecure("ThugUI_LogoHold")
        b:SetAttribute("useOnKeyDown", true)
        b:HookScript("PreClick", function(self, _, down) PL:LogoHoldClick(self, down) end)
        b:HookScript("PostClick", function(self, _, down)
            if self:GetAttribute("thugui-logo-hold") and not PL.hideuiLogged then
                PL.hideuiLogged = true
                Log("hideui snippet -> shown=%s", tostring(UIParent:IsShown()))
            end
            
            
            
            if not down and not Combat() then PL:ConfigureLogoHold() end
        end)
        PL.logoHoldButton = b
        PL:InstallHideUISnippet(b)
    end)
    if not ok then Log("logo hold button failed, the logo keeps its single press: %s", tostring(err)) end
    
    
    
    ok, err = pcall(function() PL.sink = MakeSecure("ThugUI_PadSink") end)
    if not ok then Log("sink button failed, ThugUI actions that run code stay Blizzard's: %s", tostring(err)) end
end







local function RunAction(action, button)
    local ok, err = pcall(action.run, button)
    if not ok then Log("action %s failed: %s", action.id, tostring(err)) end
end

function PL:LogoSingleAllowed()
    local kind, what = Resolve(self:Get("logo"))
    if not kind then return true end
    if kind == "macro" or kind == "spell" then return true end
    return kind == "thug" and ACTION_BY_ID[what] and ACTION_BY_ID[what].run ~= nil
end

local function LogoRun(value, key)
    local kind, what = Resolve(value)
    local action = kind == "thug" and ACTION_BY_ID[what] or nil
    if action and action.run then
        if action.defer then C_Timer.After(0, function() RunAction(action, key) end) else RunAction(action, key) end
    end
end

local function LogoClearAction(button)
    button:SetAttribute("type", nil)
    button:SetAttribute("macro", nil)
    button:SetAttribute("macrotext", nil)
    button:SetAttribute("clickbutton", nil)
    button:SetAttribute("thugui-logo-hold", nil)
    button:SetAttribute("useOnKeyDown", false)
end



function PL:LogoHoldClick(button, down)
    local now = GetTime()
    if down then
        self.logoHoldDown = now
        if not Combat() then
            local kind = Resolve(self:Get("logo"))
            if kind == "macro" or kind == "spell" then LogoClearAction(button) end
        end
        C_Timer.After(self.HOLD_LOST_TIME, function()
            if self.logoHoldDown == now then
                self.logoHoldDown = nil
                if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
                    ThugUI.Diagnostics:LogOnce("padlayout-logo-hold-lost", "PADLAYOUT", "logo hold release missing")
                else
                    Log("logo hold release missing")
                end
            end
        end)
        return
    end
    local started = self.logoHoldDown
    self.logoHoldDown = nil
    if not started then return end
    local held = now - started
    local single = self:Get("logo")
    if held < self.HOLD_TIME then
        local kind = Resolve(single)
        if kind == "thug" then LogoRun(single, self:KeyFor("logo"))
        elseif (kind == "macro" or kind == "spell") and not Combat() then
            local FB = ThugUI.FaceButtons
            local attr, text
            if FB and FB.Action then attr, text = FB.Action(single) end
            LogoClearAction(button)
            if attr then button:SetAttribute(attr, text); button:SetAttribute("type", "macro") end
        end
        return
    end
    local hold = self:Get("logohold")
    if hold == "thug:wheel" then
        LogoRun(hold, self:KeyFor("logo"))
    elseif hold == "thug:escmenu" then
        if Combat() then
            Log("Escape menu: not in combat")
            return
        end
        LogoClearAction(button)
        button:SetAttribute("type", "click")
        button:SetAttribute("clickbutton", _G.MainMenuMicroButton)
    elseif hold == "thug:hideui" then
        if Combat() then
            Log("Toggle user interface: not in combat")
        elseif not self.hideuiAvailable then
            Log("Toggle user interface: not available on this client")
        else
            LogoClearAction(button)
            button:SetAttribute("thugui-logo-hold", true)
        end
    end
end




function PL:SingleIsWindow(slotId)
    local parent = ParentOf(slotId) or slotId
    local value = self:Get(parent)
    local kind, what = Resolve(value)
    if not kind then
        local d = self:DefaultOf(parent)
        local b = d and BLIZZARD_BY_ACTION[d.action]
        return b and b.window == true or false
    end
    if kind == "thug" then
        local action = ACTION_BY_ID[what]
        return action and action.window == true or false
    end
    if kind == "blizz" then
        local b = BLIZZARD_BY_ACTION[what]
        return b and b.window == true or false
    end
    return false
end




function PL:NotePress(key)
    local parent = self:SlotForKey(key)
    if parent ~= "start" and parent ~= "view" then
        self.doublePress = nil
        return false
    end
    local now = GetTime()
    local last = self.doublePress
    if last and last.key == key and now - last.time <= self.DOUBLE_WINDOW then
        self.doublePress = nil       
        local twice = parent .. "twice"
        local kind, what = Resolve(self:Get(twice))
        local action = kind == "thug" and ACTION_BY_ID[what] or nil
        if not (action and action.double) then return false end
        if not self:SingleIsWindow(parent) then
            if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
                ThugUI.Diagnostics:LogOnce("padlayout-double-off-" .. twice, "PADLAYOUT",
                    "double press off: %s single is not a window", twice)
            else
                Log("double press off: %s single is not a window", twice)
            end
            return false
        end
        if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
            ThugUI.Diagnostics:LogOnce("padlayout-double-" .. twice .. "-" .. action.id, "PADLAYOUT",
                "%s double -> %s", twice, action.id)
        end
        if action.defer then
            C_Timer.After(0, function() RunAction(action, key) end)
        else
            
            RunAction(action, key)
        end
        return true
    end
    self.doublePress = { key = key, time = now }
    return false
end




function PL:CancelDouble() self.doublePress = nil end

PL.DOUBLE_WINDOW = 0.4






local function CrossAction(button)
    if button ~= PL:KeyFor("cross") then return nil end
    local action = PL:CrossRun()
    if not action then return nil end
    local CM = ThugUI.ControllerMode
    local bar = CM and CM.GetShortcutsBar and CM:GetShortcutsBar()
    if not (bar and bar:IsShown()) then return nil end
    return action, "cross"
end





local BAR_RUN_SLOTS = { "l1right", "r1right", "l1r1top", "l1r1right", "l1r1left", "l1r1up", "l1r1down" }
local function BarSlotAction(button)
    for _, id in ipairs(BAR_RUN_SLOTS) do
        local action = PL:RunOf(id)
        if action and button == PL:KeyFor(id) and PL:BarShown(id) then return action, id end
    end
    return nil
end

local function OnDown(_, button)
    
    
    
    
    if PL.lent[button] then
        PL:CancelDouble()
        local CR = ThugUI.ControllerRadial
        if CR and CR.QueueOpenAfterRadial then CR:QueueOpenAfterRadial(button) end
        return
    end
    PL:NotePress(button)
    local action, slotId = PL.listen[button], nil
    if not action then action, slotId = CrossAction(button) end
    if not action then action, slotId = BarSlotAction(button) end
    if not action then return end
    if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
        ThugUI.Diagnostics:LogOnce("padlayout-pressed-" .. tostring(button) .. "-" .. action.id .. "-" .. tostring(slotId), "PADLAYOUT",
            "%s pressed -> %s", tostring(slotId or PL:SlotForKey(button)), action.id)
    end
    if action.defer then
        C_Timer.After(0, function() RunAction(action, button) end)
    else
        RunAction(action, button)
    end
end

do
    local ok, err = pcall(function()
        local l = CreateFrame("Frame", "ThugUI_PadListener", UIParent)
        l:SetSize(1, 1)
        l:SetPoint("TOPLEFT")
        l:SetScript("OnGamePadButtonDown", OnDown)
        PL.listener = l
    end)
    if not ok then Log("listener frame failed, ThugUI actions that run code stay Blizzard's: %s", tostring(err)) end
end






function PL:Start()
    local l = PL.listener
    if not l then return false end
    if l.listening then return true end
    if Combat() then return false end
    l:Show()
    local ok, err = pcall(l.SetPropagateKeyboardInput, l, true)
    if not ok then
        Log("listener: SetPropagateKeyboardInput refused: %s", tostring(err))
        return false
    end
    if not l.EnableGamePadButton then
        Log("listener: no EnableGamePadButton on this client")
        return false
    end
    ok, err = pcall(l.EnableGamePadButton, l, true)
    if not ok then
        Log("listener: EnableGamePadButton refused: %s", tostring(err))
        return false
    end
    l.listening = true
    Log("listener on")
    return true
end

function PL:Stop()
    local l = PL.listener
    if not (l and l.listening) then return end
    if Combat() then return end
    pcall(l.EnableGamePadButton, l, false)
    l.listening = false
    self.doublePress = nil
    Log("listener off")
end




local function Refuse(self, id, value, why)
    Log("refused %s %s: %s", id, tostring(value), why)
    self.refused[id] = true
end

local function Unbind(key)
    pcall(SetOverrideBinding, PL.owner, true, key, nil)
end





local function BindByName(self, id, key, action)
    local ok, err = pcall(SetOverrideBinding, PL.owner, true, key, action)
    if not ok then
        Unbind(key)
        Refuse(self, id, action, "SetOverrideBinding failed: " .. tostring(err))
        return false
    end
    local okA, got = pcall(GetBindingAction, key, true)
    if not (okA and got == action) then
        Unbind(key)
        Refuse(self, id, action, "got " .. tostring(okA and got or "an error"))
        return false
    end
    self.ours[key] = action
    return true
end





local function BindByClick(self, id, key, buttonName, value)
    local ok, err = pcall(SetOverrideBindingClick, PL.owner, true, key, buttonName, "LeftButton")
    if not ok then
        Unbind(key)
        Refuse(self, id, value, "SetOverrideBindingClick failed: " .. tostring(err))
        return false
    end
    local okA, got = pcall(GetBindingAction, key, true)
    if not (okA and type(got) == "string" and got ~= "" and got:sub(1, 5) == "CLICK") then
        Unbind(key)
        Refuse(self, id, value, "got " .. tostring(okA and got or "an error"))
        return false
    end
    self.ours[key] = got
    return true
end


local function BindSlot(self, id, key, value)
    local kind, what = self:Parse(value)
    if kind == "macro" or kind == "spell" then
        local FB = ThugUI.FaceButtons
        local attr, text
        if FB and FB.Action then attr, text = FB.Action(value) end
        local button = self.buttons[id]
        if not attr then
            Log("refused %s %s: no name for it yet, the slot stays Blizzard's (the choice is kept)", id, value)
            return false
        end
        if not button then
            Refuse(self, id, value, "no button")
            return false
        end
        
        
        local okSet, errSet = pcall(function()
            button:SetAttribute("macro", nil)
            button:SetAttribute("macrotext", nil)
            button:SetAttribute(attr, text)
        end)
        if not okSet then
            Refuse(self, id, value, "attributes: " .. tostring(errSet))
            return false
        end
        return BindByClick(self, id, key, "ThugUI_Pad_" .. id, value)
    end
    if kind == "thug" then
        local action = self:GetAction(what)
        if not action then
            Refuse(self, id, value, "no such ThugUI action")
            return false
        end
        if action.binding then return BindByName(self, id, key, action.binding) end
        if not self.sink then
            Refuse(self, id, value, "no sink button")
            return false
        end
        if not BindByClick(self, id, key, "ThugUI_PadSink", value) then return false end
        self.listen[key] = action
        return true
    end
    if kind == "blizz" then
        local cmd = self:Command(id)
        if not cmd then
            Refuse(self, id, value, "not a Blizzard action this build knows")
            return false
        end
        return BindByName(self, id, key, cmd)
    end
    Refuse(self, id, value, "not a value this build understands")
    return false
end

function PL:ConfigureLogoHold()
    local self = PL
    local button = self.logoHoldButton
    if not button then return false end
    LogoClearAction(button)
    local value = self:Get("logo")
    local kind = Resolve(value)
    if kind == "macro" or kind == "spell" then
        local FB = ThugUI.FaceButtons
        local attr, text
        if FB and FB.Action then attr, text = FB.Action(value) end
        if not attr then
            Log("refused logo hold %s: no name for it yet", tostring(value))
            return false
        end
        button:SetAttribute(attr, text)
        button:SetAttribute("type", "macro")
        button:SetAttribute("useOnKeyDown", true)
    end
    return true
end

local function BindLogoHold(self, key)
    if not self:LogoSingleAllowed() then
        Refuse(self, "logohold", self:Get("logohold"), "Needs a ThugUI action, macro or spell on the single press")
        return false
    end
    if not self:ConfigureLogoHold() then return false end
    return BindByClick(self, "logohold", key, "ThugUI_LogoHold", self:Get("logohold"))
end





local function LendToRadial(self, key)
    local name = "InputFunctionBindingButton_" .. (_G.GAMEPAD_FACE_RIGHT or "PAD2")
    if not _G[name] then
        Log("radial lend refused %s: Blizzard B button %s is not ready", tostring(key), name)
        return false
    end
    local ok, err = pcall(SetOverrideBindingClick, PL.owner, true, key, name, "LeftButton")
    local okA, got = pcall(GetBindingAction, key, true)
    if ok and okA and type(got) == "string" and got:find(name, 1, true) then
        self.ours[key] = got
        self.lent[key] = true
        return true
    end
    Unbind(key)
    local id = self:SlotForKey(key)
    if id then
        local value = self:Get(id)
        if value and BindSlot(self, id, key, value) then self.applied[id] = true end
    end
    Log("radial lend refused %s: %s", tostring(key), tostring(ok and (okA and got or "GetBindingAction failed") or err))
    return false
end

local function ApplyRadialYield(self)
    wipe(self.lent)
    if not self.yieldingRadial then return end
    for key in pairs(self.yieldKeys) do LendToRadial(self, key) end
end





local function ConfigureSlot(self, id)
    local button = self.buttons[id]
    if not button then return end
    local value = self:Get(id)
    local kind = self:Parse(value)
    local FB = ThugUI.FaceButtons
    local attr, text
    if (kind == "macro" or kind == "spell") and FB and FB.Action then attr, text = FB.Action(value) end
    local ok, err = pcall(function()
        button:SetAttribute("macro", nil)
        button:SetAttribute("macrotext", nil)
        if attr then button:SetAttribute(attr, text) end
    end)
    if not ok then Log("%s button attributes failed: %s", id, tostring(err)) end
end



local function ConfigureBarSlots(self)
    for _, id in ipairs(BAR_RUN_SLOTS) do ConfigureSlot(self, id) end
end






function PL:Apply()
    if Combat() then
        self.pending = true
        return
    end
    self.pending = false
    local owner = self.owner
    if owner then
        local ok, err = pcall(ClearOverrideBindings, owner)
        if not ok then Log("ClearOverrideBindings failed: %s", tostring(err)) end
    end
    self.listen, self.applied, self.ours = {}, {}, {}
    wipe(self.refused)
    ConfigureSlot(self, "cross")
    ConfigureBarSlots(self)
    if not owner or not Ready() then return end
    for _, id in ipairs(SINGLE) do
        local key = self:KeyFor(id)
        local value = self:Get(id)
        
        
        local held = id == "logo" and self:Get("logohold") ~= nil and self:LogoSingleAllowed()
        if key and held then
            local ok = BindLogoHold(self, key)
            if ok then self.applied[id] = true end
            Log("apply logohold %s %s -> %s", key, tostring(self:Get("logohold")), ok and "ok" or "refused")
        elseif key and value then
            local ok = BindSlot(self, id, key, value)
            if ok then self.applied[id] = true end
            Log("apply %s %s -> %s %s", id, key, value, ok and "ok" or "refused")
        end
    end
    ApplyRadialYield(self)
end




function PL:YieldToRadial(on, keys)
    if Combat() then
        
        
        
        self.yieldingRadial = on and true or false
        if not on then wipe(self.yieldKeys) end
        self.pending = true
        return false
    end
    self.yieldingRadial = on and true or false
    wipe(self.yieldKeys)
    if on then
        for _, key in ipairs(keys or {}) do
            if type(key) == "string" and key ~= "" then self.yieldKeys[key] = true end
        end
    end
    self:Apply()
    return true
end



function PL:OverridesKey(key)
    local id = self:SlotForKey(key)
    return id ~= nil and self.applied[id] == true
end


function PL:Refresh()
    if Ready() then self:Start() else self:Stop() end
    self:Apply()
end







function PL:Reassert()
    if Combat() then
        self.pending = true
        return
    end
    local manager = _G.GamepadSharedUtility and _G.GamepadSharedUtility.InputBindingManager
    if manager and manager.IsOnlyCoreBindingSetActive and not manager:IsOnlyCoreBindingSetActive() then return end
    for key, ours in pairs(self.ours) do
        if not self.lent[key] then
        local ok, got = pcall(GetBindingAction, key, true)
        if not (ok and got == ours) then
            self:Apply()
            return
        end
        end
    end
end



local function Copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = Copy(x) end
    return out
end








function PL:ResetAll(reason)
    local cfg = Cfg()
    if not cfg then return false end
    if type(cfg.slots) ~= "table" then cfg.slots = {} end
    local crossBefore = cfg.slots.cross
    for _, slot in ipairs(PL.SLOTS) do cfg.slots[slot.id] = nil end
    
    
    if type(cfg.resetFrom) ~= "table" then cfg.resetFrom = {} end
    cfg.resetFrom.faces = Copy(ThugUIDB.FaceButtons)
    local faces = ThugUIDB.FaceButtons
    if type(faces) == "table" then
        for p = 1, 3 do
            if type(faces["p" .. p]) == "table" then wipe(faces["p" .. p]) end
        end
    end
    Log("reset all: %s", tostring(reason))
    local FB = ThugUI.FaceButtons
    if FB and FB.Apply then
        local ok, err = pcall(FB.Apply, FB)
        if not ok then Log("reset: FaceButtons:Apply failed: %s", tostring(err)) end
    end
    self:Apply()
    self:Notify()
    if crossBefore ~= nil then NotifyCross() end
    return true
end




function PL:FirstRun()
    local cfg = Cfg()
    if not cfg or (tonumber(cfg.version) or 0) >= 1 then return end
    if type(cfg.resetFrom) ~= "table" then cfg.resetFrom = {} end
    local mode = ThugUIDB.ControllerMode
    cfg.resetFrom.faces = Copy(ThugUIDB.FaceButtons)
    cfg.resetFrom.mapShortcut = mode and mode.mapShortcut
    self:ResetAll("first run")
    
    
    
    cfg.version = 1
    Log("first run: slots and face buttons reset (kept in PadLayout.resetFrom)")
    print("ThugUI: Pad layout is new. Every controller button is back on Blizzard's default. Change them on the Pad layout page.")
end





local function CarriedBy(action)
    for _, slot in ipairs(PL.SLOTS) do
        if not IsSharedKeySlot(slot.id) and PL:Get(slot.id) == "blizz:" .. action then return slot.id end
    end
    return nil
end








local function OnAnyKey(self, action)
    if CarriedBy(action) then return true end
    local own = {}
    
    
    local askKeys = not PL.BAR_ONLY[action]
    for _, slot in ipairs(PL.SLOTS) do
        if not IsSharedKeySlot(slot.id) then
            local d = self:DefaultOf(slot.id)
            if d and d.action == action and self:Describe(slot.id).isDefault then return true end
            local key = self:KeyFor(slot.id)
            if key then own[key] = true end
        end
    end
    if askKeys and type(GetBindingKey) == "function" then
        local ok, k1, k2, k3, k4 = pcall(GetBindingKey, action)
        if ok then
            for _, key in ipairs({ k1, k2, k3, k4 }) do
                if type(key) == "string" and key ~= "" and not own[key] then return true end
            end
        end
    end
    return false
end




















function PL:Lost()
    local out = {}
    for _, slot in ipairs(PL.SLOTS) do
        if not IsSharedKeySlot(slot.id) then
            local d = self:DefaultOf(slot.id)
            local desc = self:Describe(slot.id)
            if d and not desc.isDefault and not OnAnyKey(self, d.action) then
                out[#out + 1] = { kind = "blizzard", action = d.action, title = d.title, slot = slot.id,
                                  key = self:KeyFor(slot.id), by = desc.label }
                if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
                    local pair = slot.id .. "=" .. tostring(self:Get(slot.id))
                    ThugUI.Diagnostics:LogOnce("padlayout-lost-" .. d.action .. "-" .. pair, "PADLAYOUT",
                        "lost %s by %s", d.action, pair)
                end
            end
        end
    end
    for _, slot in ipairs(PL.SLOTS) do
        if not IsSharedKeySlot(slot.id) then
            local key = self:KeyFor(slot.id)
            local desc = self:Describe(slot.id)
            if key and not desc.isDefault and self.applied[slot.id] then
                local ok, action = pcall(GetBindingAction, key, false)
                if ok and type(action) == "string" and action ~= "" then
                    local title = action
                    if type(GetBindingName) == "function" then
                        local okN, name = pcall(GetBindingName, action)
                        if okN and type(name) == "string" and name ~= "" then title = name end
                    end
                    out[#out + 1] = { kind = "yours", action = action, title = title, slot = slot.id,
                                      key = key, by = desc.label }
                end
            end
        end
    end
    return out
end




function PL:Restore(action)
    for _, e in ipairs(self:Lost()) do
        if e.action == action then
            self:Set(e.slot, nil)
            return true
        end
    end
    return false
end




function PL:MovedDefaults()
    local out = {}
    for _, slot in ipairs(PL.SLOTS) do
        if not IsSharedKeySlot(slot.id) then
            local d = self:DefaultOf(slot.id)
            if d and not self:Describe(slot.id).isDefault then
                local home = CarriedBy(d.action)
                if home then
                    out[#out + 1] = { action = d.action, title = d.title, slot = home, from = slot.id }
                end
            end
        end
    end
    return out
end



local events = CreateFrame("Frame", "ThugUI_PadEvents")
events:SetScript("OnEvent", function() PL:Refresh() end)
PL.events = events

local hooked, registered, watching









function PL:Initialize()
    local okFirst, errFirst = pcall(self.FirstRun, self)
    if not okFirst then Log("first run failed: %s", tostring(errFirst)) end

    if not registered then
        registered = true
        
        for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "GAME_PAD_CONNECTED",
                                 "GAME_PAD_DISCONNECTED", "GAME_PAD_ACTIVE_CHANGED" }) do
            ThugUI.SafeRegisterEvent(events, event)
        end
    end
    local CM = ThugUI.ControllerMode
    if not watching and CM and CM.RegisterCallback then
        watching = true
        CM:RegisterCallback(function() PL:Refresh() end)
    end
    local manager = _G.GamepadSharedUtility and _G.GamepadSharedUtility.InputBindingManager
    if manager and manager.SetNewActiveKey and hooked ~= manager then
        hooked = manager
        local queued = false
        local ok, err = pcall(hooksecurefunc, manager, "SetNewActiveKey", function()
            if queued then return end
            queued = true
            C_Timer.After(0, function()
                queued = false
                PL:Reassert()
            end)
        end)
        if not ok then Log("SetNewActiveKey hook failed: %s", tostring(err)) end
    end

    local ok, report = pcall(self.DriftReport, self)
    if not ok then
        Log("default drift check failed: %s", tostring(report))
        return
    end
    if #report == 0 then
        Log("defaults match the live keys")
        return
    end
    local parts = {}
    for _, r in ipairs(report) do
        parts[#parts + 1] = string.format("%s %s expected %s live %s", r.slot, r.action,
            tostring(r.expected), tostring(r.live))
    end
    Log("default drift: %s", table.concat(parts, "; "))
end













do
    local PH = ThugUI.PadHints
    
    
    local function L() return ThugUI.PadLayout end
    if PH and PH.Register then
        for _, slot in ipairs(PL.SLOTS) do
            local id = slot.id
            PH:Register{ id = "padlayout-" .. id, group = "GAMEPLAY",
                keys = function() return PH.Glyph(L():KeyFor(id)) end,
                
                text = function()
                    local label = L():Describe(id).label
                    return IsSharedKeySlot(id) and (L():Label(id) .. ": " .. label) or label
                end,
                enabled = function()
                    if IsSharedKeySlot(id) then
                        return L():KeyFor(id) ~= nil and not L():Describe(id).isDefault
                    end
                    return L():KeyFor(id) ~= nil and not L():Describe(id).isDefault and L().applied[id] == true
                end }
        end

        
        
        local function CurrentPage()
            local bar = _G.GamepadMainActionBarFrame
            local unit = bar and bar.PageUnit
            return unit and unit.GetCurrentPage and unit:GetCurrentPage()
        end
        local function FaceValue(faceId)
            local FB = ThugUI.FaceButtons
            local page = CurrentPage()
            return FB and page and FB:Get(page, faceId) or nil
        end
        
        
        
        local function FaceKey(faceId)
            local FB = ThugUI.FaceButtons
            for _, face in ipairs(FB and FB.FACES or {}) do
                if face.id == faceId then return face.key end
            end
            return nil
        end
        local function FaceLabel(value)
            local kind, what = ParseValue(value)
            if kind == "spell" then return SpellName(what) end
            if kind == "macro" then return "Macro: " .. what end
            return nil
        end
        for _, faceId in ipairs({ "bottom", "right", "left", "top" }) do
            PH:Register{ id = "padlayout-face-" .. faceId, group = "GAMEPLAY",
                keys = function() return PH.Glyph(FaceKey(faceId)) end,
                text = function() return FaceLabel(FaceValue(faceId)) end,
                enabled = function() return FaceKey(faceId) ~= nil and FaceLabel(FaceValue(faceId)) ~= nil end }
        end

        
        
        
        local seen = {}
        local function RegisterLost(e)
            if seen[e.action] then return end
            seen[e.action] = true
            PH:Register{ id = "padlayout-lost-" .. e.action, group = "GAMEPLAY", red = true, keys = "",
                text = e.title .. ": no button",
                enabled = function()
                    for _, lost in ipairs(L():Lost()) do
                        if lost.kind == "blizzard" and lost.action == e.action then return true end
                    end
                    return false
                end }
        end
        for _, slot in ipairs(PL.SLOTS) do
            for _, e in pairs(PL.DEFAULTS[slot.id] or {}) do RegisterLost(e) end
        end
        for _, bar in pairs(PL.BAR_JOBS) do
            for _, list in pairs(bar.swapped and bar or { bar }) do
                if type(list) == "table" then
                    for _, job in pairs(list) do
                        if type(job) == "table" then RegisterLost(job) end
                    end
                end
            end
        end

        local function YoursFor(id)
            for _, lost in ipairs(L():Lost()) do
                if lost.kind == "yours" and lost.slot == id then return lost end
            end
            return nil
        end
        for _, slot in ipairs(PL.SLOTS) do
            local id = slot.id
            PH:Register{ id = "padlayout-yours-" .. id, group = "GAMEPLAY", red = true, keys = "",
                text = function() return YoursFor(id).title .. " (yours) is covered" end,
                enabled = function() return YoursFor(id) ~= nil end }
        end
    end
end
