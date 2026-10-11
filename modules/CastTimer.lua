



























local ThugUI = _G.ThugUI
local CT = {}
ThugUI.CastTimer = CT

local GCD_SPELL_ID = 61304
local listeners = {}
local lastGCD = 0
CT.cast = nil   
CT.gcd = nil    

function CT:Register(fn)
    listeners[#listeners + 1] = fn
end

local function Notify(kind, start, duration, channel, obj)
    for i, fn in ipairs(listeners) do
        local ok, err = pcall(fn, kind, start, duration, channel, obj)
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CASTTIMER", "listener %d failed: %s", i, tostring(err))
        end
    end
end


local function Plain(v)
    if v == nil then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    return type(v) == "number" and v or nil
end

local function PlainBool(v)
    if v == nil then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    return v and true or false
end








local lastSpellID

local function GCDSpell()
    
    if not (C_Spell and C_Spell.GetSpellInfo) then return GCD_SPELL_ID, false end
    local ok, known = pcall(C_Spell.GetSpellInfo, GCD_SPELL_ID)
    if not ok or known then return GCD_SPELL_ID, false end
    if lastSpellID then return lastSpellID, true end
    return GCD_SPELL_ID, false
end




function CT:ReadGCD()
    local spellID, fromCast = GCDSpell()
    local obj
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local ok, o = pcall(C_Spell.GetSpellCooldownDuration, spellID)
        if ok then obj = o end
    end
    local running, start, duration = nil, nil, nil
    local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
    if ok and type(info) == "table" and fromCast then
        
        
        
        local onGCD = PlainBool(info.isOnGCD)
        start, duration = Plain(info.startTime), Plain(info.duration)
        if onGCD == nil and start and duration then
            onGCD = duration > 0 and duration <= 1.5
        end
        running = onGCD == true
        if not running then start, duration, obj = nil, nil, nil end
        return running, start, duration, obj
    end
    if ok and type(info) == "table" then
        start, duration = Plain(info.startTime), Plain(info.duration)
        if start and duration then
            running = duration > 0
        else
            local active, onGCD = PlainBool(info.isActive), PlainBool(info.isOnGCD)
            if active ~= nil or onGCD ~= nil then
                running = (active == true) or (onGCD == true)
            end
        end
    end
    
    
    if running == nil then running = obj ~= nil end
    return running, start, duration, obj
end






function CT:OnGCD()
    local now = GetTime()
    if now - lastGCD < 0.1 then return end
    local running, start, duration, obj = self:ReadGCD()
    if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
        local spellID, fromCast = GCDSpell()
        ThugUI.Diagnostics:LogOnce("casttimer-gcd-" .. tostring(running) .. "-" .. tostring(start ~= nil) .. "-" .. tostring(obj ~= nil) .. "-" .. tostring(fromCast),
            "CASTTIMER", "GCD read: running=%s plain=%s obj=%s combat=%s spell=%s fromCast=%s",
            tostring(running), tostring(start ~= nil), tostring(obj ~= nil), tostring(InCombatLockdown()),
            tostring(spellID), tostring(fromCast))
    end
    if not running then return end
    if not obj and not (start and duration) then return end
    lastGCD = now
    CT.gcd = { start = start, duration = duration, obj = obj }
    Notify("gcd", start, duration, false, obj)
end

function CT:OnCast(event)
    local startMS, endMS, channel
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
        local _, _, _, s, e = UnitCastingInfo("player")
        startMS, endMS = Plain(s), Plain(e)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        local _, _, _, s, e = UnitChannelInfo("player")
        startMS, endMS, channel = Plain(s), Plain(e), true
    else
        CT.cast = nil
        Notify("caststop")
        return
    end
    
    
    if not (startMS and endMS) then
        CT.cast = nil
        Notify("caststop")
        return
    end
    local duration = (endMS - startMS) / 1000
    if duration > 0.1 then
        CT.cast = { start = startMS / 1000, duration = duration, channel = channel or false }
        Notify("cast", startMS / 1000, duration, channel or false)
    end
end

local CAST_EVENTS = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED",
}

CT.driver = CreateFrame("Frame")



CT.sentWatch = CreateFrame("Frame")
CT.sentWatch:SetScript("OnEvent", function(_, _, unit, _, _, spellID)
    if unit and unit ~= "player" then return end
    lastSpellID = Plain(spellID) or lastSpellID
end)
pcall(CT.sentWatch.RegisterUnitEvent, CT.sentWatch, "UNIT_SPELLCAST_SENT", "player")

CT.driver:SetScript("OnEvent", function(_, event, unit, _, _, spellID)
    
    
    if unit and unit ~= "player" then return end
    
    
    if event == "UNIT_SPELLCAST_SENT" then lastSpellID = Plain(spellID) or lastSpellID end
    
    
    if event == "UNIT_SPELLCAST_SENT" or event == "SPELL_UPDATE_COOLDOWN" then
        CT:OnGCD()
    else
        CT:OnCast(event)
    end
end)


local started = false
function CT:Start()
    if started then return end
    started = true
    pcall(CT.driver.RegisterUnitEvent, CT.driver, "UNIT_SPELLCAST_SENT", "player")
    ThugUI.SafeRegisterEvent(CT.driver, "SPELL_UPDATE_COOLDOWN")
    for _, e in ipairs(CAST_EVENTS) do
        pcall(CT.driver.RegisterUnitEvent, CT.driver, e, "player")
    end
end
