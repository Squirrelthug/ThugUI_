

























local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen
local T = { active = false, openedIt = false, holdOpen = false }
FS.Target = T





T.APPLY_KEY = "PAD3"

T.CANCEL_KEY = "PAD2"




T.TARGET_COLOR = { 0.25, 0.85, 1.0 }
T.PULSE_SPEED = 3.2      
T.PULSE_LOW = 0.45       


T.SHOW_ELIGIBILITY = true


T.CLOSE_IF_OPENED = true



T.STOP_MODE = "stop"

T.ERROR_WINDOW = 0.5



T.CAST_WINDOW = 1
T.CAST_FLASH = 0.3


local function Log(message, ...)
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("ITEMTARGET", message, ...)
    end
end
T.Log = Log

local function Later(fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, fn)
    else
        fn()
    end
end

local function Combat()
    return InCombatLockdown() or (FS.Actions and FS.Actions.combatSoon == true)
end

local function Shown()
    return FS.UI and FS.UI.frame and FS.UI.frame:IsShown() and true or false
end

local function Now()
    return GetTime and GetTime() or 0
end

local function Secret(value)
    return issecretvalue and issecretvalue(value)
end





local missLogged = {}



local function Ask(name)
    local fn = _G[name]
    if type(fn) ~= "function" then
        if not missLogged[name] then
            missLogged[name] = true
            Log("%s is not available on this client", name)
        end
        return false
    end
    local ok, value = pcall(fn)
    if not ok then
        if not missLogged[name] then
            missLogged[name] = true
            Log("%s threw: %s", name, tostring(value))
        end
        return false
    end
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return value and true or false
end




function T.Detect()
    return Ask("SpellCanTargetItem") or Ask("SpellCanTargetItemID")
end


local function SpellQuestion(name)
    local c = _G.C_Spell
    if type(c) ~= "table" or type(c[name]) ~= "function" then
        return nil
    end
    local ok, value = pcall(c[name])
    if not ok or (issecretvalue and issecretvalue(value)) then
        return nil
    end
    return value
end


function T.HeaderText()
    if SpellQuestion("TargetSpellIsEnchanting") then
        return "Choose an item to enchant..."
    end
    if SpellQuestion("TargetSpellChecksItemCondition") then
        return "Choose an item..."
    end
    return "Choose an item to use it on..."
end



function T.Match(item)
    if not (T.active and T.SHOW_ELIGIBILITY) or type(item) ~= "table" or not item.itemID then
        return nil
    end
    local util = _G.ItemButtonUtil
    if type(util) ~= "table" or type(util.GetItemContextMatchResultForItem) ~= "function"
        or type(util.ItemContextMatchResult) ~= "table" or not _G.ItemLocation then
        return nil
    end
    local location
    if item.kind == "equip" and type(item.slot) == "number" then
        local ok, made = pcall(_G.ItemLocation.CreateFromEquipmentSlot, _G.ItemLocation, item.slot)
        location = ok and made or nil
    elseif item.kind == nil and type(item.bag) == "number" and type(item.slot) == "number" then
        local ok, made = pcall(_G.ItemLocation.CreateFromBagAndSlot, _G.ItemLocation, item.bag, item.slot)
        location = ok and made or nil
    end
    if not location then
        return nil
    end
    local ok, result = pcall(util.GetItemContextMatchResultForItem, location)
    if not ok or (issecretvalue and issecretvalue(result)) then
        return nil
    end
    local enum = util.ItemContextMatchResult
    if result ~= nil and result == enum.Match then
        return "match"
    elseif result ~= nil and result == enum.Mismatch then
        return "mismatch"
    end
    return nil
end



function T.PaintTick(cell, on)
    local tick = cell.targetTick
    if not tick then
        if not on then
            return
        end
        tick = cell:CreateTexture(nil, "OVERLAY")
        tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        tick:SetSize(18, 18)
        tick:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -1, 1)
        tick:SetVertexColor(T.TARGET_COLOR[1], T.TARGET_COLOR[2], T.TARGET_COLOR[3], 1)
        cell.targetTick = tick
    end
    tick:SetShown(on and true or false)
end

local function ColourTable(c)
    return { r = c[1], g = c[2], b = c[3] }
end




function T:DecorateLines(lines, item, headerFirst)
    local out = {}
    for i, line in ipairs(lines) do
        out[i] = line
    end
    local at = (headerFirst or #out == 0) and 1 or 2
    local extra = { { leftText = T.HeaderText(), leftColor = ColourTable(T.TARGET_COLOR) } }
    local match = item and T.Match(item)
    if match == "match" then
        extra[#extra + 1] = { leftText = "Eligible", leftColor = ColourTable(T.TARGET_COLOR) }
    elseif match == "mismatch" then
        extra[#extra + 1] = { leftText = "Not eligible", leftColor = FS.MUTED }
    end
    for i, line in ipairs(extra) do
        table.insert(out, at + i - 1, line)
    end
    return out
end







function T:Pulse(frame, elapsed)
    self:UpdateCastRing()
    if not self.active then
        if self.pulsing then
            self.pulsing = nil
            frame:SetAlpha(1)
        end
        return
    end
    self.pulsing = true
    self.pulseClock = (self.pulseClock or 0) + (elapsed or 0)
    local low = self.PULSE_LOW
    frame:SetAlpha(low + (1 - low) * (0.5 + 0.5 * math.sin(self.pulseClock * self.PULSE_SPEED)))
end








local RING_THICKNESS = 6


local RING_TRACK_THICKNESS = RING_THICKNESS
local SWEEP_ALPHA = 0.75
local sweepMissLogged = {}

local function SameItem(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if a.bag ~= nil or b.bag ~= nil then
        return a.bag == b.bag and a.slot == b.slot
    end
    return a.slot == b.slot
end

local function SweepCall(sweep, method, ...)
    local fn = sweep and sweep[method]
    if type(fn) ~= "function" then
        if not sweepMissLogged[method] then
            sweepMissLogged[method] = true
            Log("cast sweep %s is not available on this client", method)
        end
        return false
    end
    local ok, err = pcall(fn, sweep, ...)
    if not ok then
        local key = method .. ":" .. tostring(err)
        if not sweepMissLogged[key] then
            sweepMissLogged[key] = true
            Log("cast sweep %s failed: %s", method, tostring(err))
        end
        return false
    end
    return true
end

local function HideRing(ring)
    if not ring then return end
    for _, edge in ipairs(ring.edges) do edge:Hide() end
    for _, track in ipairs(ring.tracks) do track:Hide() end
end

local function HideSweep(ring)
    if not (ring and ring.sweep) then return end
    SweepCall(ring.sweep, "Clear")
    ring.sweep:Hide()
end

local function HideCastVisuals(ring)
    HideRing(ring)
    HideSweep(ring)
end

local function PaintSweep(ring, cast)
    local sweep = ring and ring.sweep
    if not sweep or not cast then return end
    local duration = (cast.endMS - cast.startMS) / 1000
    if duration <= 0 then
        HideSweep(ring)
        return
    end
    
    
    
    if SweepCall(sweep, "SetCooldown", cast.startMS / 1000, duration) then
        sweep:Show()
    else
        sweep:Hide()
    end
end

local function RingFor(cell)
    if cell.castRing then return cell.castRing end
    local ring = { edges = {}, tracks = {} }
    
    
    local sweep = CreateFrame("Cooldown", nil, cell, "CooldownFrameTemplate")
    sweep:SetAllPoints(cell.icon or cell)
    sweep:SetFrameLevel((cell.cooldown and cell.cooldown:GetFrameLevel() or cell:GetFrameLevel()) + 1)
    SweepCall(sweep, "SetDrawSwipe", true)
    SweepCall(sweep, "SetSwipeColor", 0, 0, 0, SWEEP_ALPHA)
    SweepCall(sweep, "SetReverse", false)
    SweepCall(sweep, "SetDrawEdge", false)
    SweepCall(sweep, "SetDrawBling", false)
    SweepCall(sweep, "SetHideCountdownNumbers", true)
    sweep:Hide()
    ring.sweep = sweep
    ring.frame = CreateFrame("Frame", nil, cell)
    ring.frame:SetAllPoints(cell)
    ring.frame:SetFrameLevel(sweep:GetFrameLevel() + 1)
    for i = 1, 4 do
        local track = ring.frame:CreateTexture(nil, "OVERLAY", nil, 1)
        track:SetTexture("Interface\\Buttons\\WHITE8X8")
        track:SetVertexColor(0, 0, 0, 0.6)
        ring.tracks[i] = track
        
        local edge = ring.frame:CreateTexture(nil, "OVERLAY", nil, 2)
        edge:SetTexture("Interface\\Buttons\\WHITE8X8")
        edge:SetVertexColor(T.TARGET_COLOR[1], T.TARGET_COLOR[2], T.TARGET_COLOR[3], 1)
        ring.edges[i] = edge
    end
    cell.castRing = ring
    return ring
end




function T:DrawCastRing(progress)
    local cast = self.cast
    local ring = cast and cast.ring
    if not ring then return end
    progress = math.max(0, math.min(1, progress or 0))
    local cell = ring.cell
    local width, height = cell:GetWidth() or 0, cell:GetHeight() or 0
    local perimeter = 2 * (width + height)
    if perimeter <= 0 then HideRing(ring); return end
    local left = progress * perimeter
    local lengths = { math.min(width, left), 0, 0, 0 }
    left = math.max(0, left - width)
    lengths[2] = math.min(height, left)
    left = math.max(0, left - height)
    lengths[3] = math.min(width, left)
    left = math.max(0, left - width)
    lengths[4] = math.min(height, left)
    local e = ring.edges
    local track = ring.tracks
    track[1]:ClearAllPoints(); track[1]:SetPoint("TOPLEFT", cell, "TOPLEFT"); track[1]:SetSize(width, RING_TRACK_THICKNESS)
    track[2]:ClearAllPoints(); track[2]:SetPoint("TOPRIGHT", cell, "TOPRIGHT"); track[2]:SetSize(RING_TRACK_THICKNESS, height)
    track[3]:ClearAllPoints(); track[3]:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT"); track[3]:SetSize(width, RING_TRACK_THICKNESS)
    track[4]:ClearAllPoints(); track[4]:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT"); track[4]:SetSize(RING_TRACK_THICKNESS, height)
    e[1]:ClearAllPoints(); e[1]:SetPoint("TOPLEFT", cell, "TOPLEFT"); e[1]:SetSize(lengths[1], RING_THICKNESS)
    e[2]:ClearAllPoints(); e[2]:SetPoint("TOPRIGHT", cell, "TOPRIGHT"); e[2]:SetSize(RING_THICKNESS, lengths[2])
    e[3]:ClearAllPoints(); e[3]:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT"); e[3]:SetSize(lengths[3], RING_THICKNESS)
    e[4]:ClearAllPoints(); e[4]:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT"); e[4]:SetSize(RING_THICKNESS, lengths[4])
    for _, side in ipairs(track) do side:Show() end
    for _, edge in ipairs(e) do edge:SetShown(true) end
end




function T:PaintCastRing(cell, item)
    local cast = self.cast
    if not cast then
        if cell.castRing then HideCastVisuals(cell.castRing) end
        return
    end
    if not SameItem(cast.target, item) then
        if cell.castRing then HideCastVisuals(cell.castRing) end
        return
    end
    if cast.ring and cast.ring ~= cell.castRing then HideCastVisuals(cast.ring) end
    local ring = RingFor(cell)
    ring.cell = cell
    cast.ring = ring
    if cast.flashing then
        HideSweep(ring)
    else
        PaintSweep(ring, cast)
    end
    self:DrawCastRing(cast.flashing and 1 or (Now() * 1000 - cast.startMS) / (cast.endMS - cast.startMS))
end

function T:UpdateCastRing()
    local cast = self.cast
    if not cast or cast.flashing then return end
    local duration = cast.endMS - cast.startMS
    if duration <= 0 then return end
    self:DrawCastRing((Now() * 1000 - cast.startMS) / duration)
end

function T:FinishCastRing()
    local cast = self.cast
    if not cast then return end
    HideCastVisuals(cast.ring)
    self.cast = nil
    self.castHold = nil
    local close = self.closeAfterRing
    self.closeAfterRing = nil
    if close and Shown() then
        self.openedIt = false
        FS:Close(false)
    end
end

function T:EndCastRing(why)
    local cast = self.cast
    if not cast then return end
    Log("cast ring end %s", tostring(why))
    if why == "succeeded" then
        cast.flashing = true
        HideSweep(cast.ring)
        self:DrawCastRing(1)
        if C_Timer and C_Timer.After then
            C_Timer.After(self.CAST_FLASH, function()
                if T.cast == cast then T:FinishCastRing() end
            end)
        else
            self:FinishCastRing()
        end
    else
        self:FinishCastRing()
    end
end

local function CastTimes(fn)
    if type(fn) ~= "function" then return nil end
    local ok, _, _, _, startMS, endMS, _, _, _, spellID = pcall(fn, "player")
    if not ok or Secret(startMS) or Secret(endMS) or Secret(spellID) then return nil end
    if type(startMS) ~= "number" or type(endMS) ~= "number" or endMS <= startMS then return nil end
    return startMS, endMS, spellID
end

function T:StartCastRing()
    local target = self.applyTarget
    if not target or not self.applyAt or Now() - self.applyAt > self.CAST_WINDOW then return end
    local startMS, endMS, spellID = CastTimes(_G.UnitCastingInfo)
    if not startMS then startMS, endMS, spellID = CastTimes(_G.UnitChannelInfo) end
    if not startMS then
        if not self.castReadMiss then
            self.castReadMiss = true
            Log("cast ring not drawn: cast timing was unreadable")
        end
        return
    end
    self.castReadMiss = nil
    self.cast = { target = { bag = target.bag, slot = target.slot }, startMS = startMS, endMS = endMS }
    self.castHold = true
    Log("cast ring start %s on bag=%s slot=%s", tostring(spellID), tostring(target.bag), tostring(target.slot))
    if Shown() then FS:ScheduleRefresh() end
end





local function Bool(value)
    return tostring(value and true or false)
end

local function BagsShown()
    return (_G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown())
        or (_G.ContainerFrame1 and _G.ContainerFrame1:IsShown()) or false
end

local function CharShown()
    return (_G.CharacterFrame and _G.CharacterFrame:IsShown()) or false
end


local function LogContext()
    local id = SpellQuestion("GetTargetSpellID")
    Log("ctx enchanting=%s checksCondition=%s targetSpellID=%s",
        tostring(SpellQuestion("TargetSpellIsEnchanting")), tostring(SpellQuestion("TargetSpellChecksItemCondition")),
        tostring(id))
end




function T:Refresh(source)
    local now = FS:Active() and T.Detect() or false
    if now == self.active then
        return
    end
    if now then
        self:Enter(source)
    else
        self:Leave(source)
    end
end

function T:Enter(source)
    self.active = true
    local shown = Shown()
    self.windowWasOpen = shown
    self.openedIt = not shown
    self.tabPending = true
    self.pulseClock = 0
    Log("targeting started (%s) canTargetItem=true isTargeting=%s windowShown=%s bagsShown=%s charShown=%s combat=%s",
        tostring(source), Bool(_G.SpellIsTargeting and _G.SpellIsTargeting()), Bool(shown), Bool(BagsShown()),
        Bool(CharShown()), Bool(Combat()))
    LogContext()
    if self.events then
        ThugUI.SafeRegisterEvent(self.events, "UI_ERROR_MESSAGE")
    end
    if shown then
        FS:Refresh()
        self:PickTab()
        return
    end
    if Combat() then
        Log("item targeting in combat: window not opened")
        return
    end
    
    
    Later(function()
        T:EnsureOpen("fallback")
    end)
end




function T:EnsureOpen(why)
    if not self.active or Shown() then
        return
    end
    if Combat() then
        Log("item targeting in combat: window not opened")
        return
    end
    if not FS:Active() or FS.interacting then
        return
    end
    self.openedIt = true
    self.holdOpen = true
    FS:Open()
    if not Shown() then
        self.holdOpen = false
        Log("window did not open (%s)", tostring(why))
    end
end

function T:Leave(source)
    local close = self.CLOSE_IF_OPENED and self.openedIt and Shown()
    Log("targeting ended (%s) canTargetItem=false", tostring(source))
    self.active = false
    self.holdOpen = false
    
    
    
    
    
    
    local pending = not self.cast and self.applyAt and Now() - self.applyAt <= self.CAST_WINDOW
    if not pending then self.applyAt = nil end
    self.tabPending = nil
    if self.events then
        pcall(self.events.UnregisterEvent, self.events, "UI_ERROR_MESSAGE")
    end
    if pending then
        self.castHold = true
        self.closeAfterRing = close
        local at = self.applyAt
        local function GiveUp()
            if T.cast or T.applyAt ~= at then return end
            Log("no cast followed the apply; window released")
            T.applyAt, T.castHold = nil, nil
            local shut = T.closeAfterRing
            T.closeAfterRing = nil
            if shut and Shown() then
                T.openedIt = false
                FS:Close(false)
            elseif Shown() then
                FS:Refresh()
            end
        end
        if C_Timer and C_Timer.After then C_Timer.After(self.CAST_WINDOW, GiveUp) else GiveUp() end
        if Shown() then FS:Refresh() end
        return
    end
    if self.cast then
        
        
        
        self.closeAfterRing = close
        if Shown() then FS:Refresh() end
        return
    end
    if close then
        Log("closed because targeting ended; windowWasOpenBefore=%s", Bool(self.windowWasOpen))
        self.openedIt = false
        
        FS:Close(false)
        return
    end
    self.openedIt = false
    if Shown() then
        
        
        FS:Refresh()
    end
end




function T:PickTab()
    if not (self.active and self.tabPending and Shown()) then
        return
    end
    local B = FS.Bags
    if not (B and B.items and B.TABS and B.SetTab) then
        return
    end
    self.tabPending = nil
    local function HasMatch(tab)
        for _, item in ipairs(B.items[tab] or {}) do
            if T.Match(item) == "match" then
                return true
            end
        end
        return false
    end
    if HasMatch(B.activeTab) then
        return
    end
    for _, tab in ipairs(B.TABS) do
        if tab ~= B.activeTab and HasMatch(tab) then
            Log("tab %s has no match; showing %s", tostring(B.activeTab), tab)
            B:SetTab(tab)
            return
        end
    end
end


function T:OnOpen(by)
    if not self.active then
        return
    end
    local name
    if by then
        local ok, found = pcall(by.GetName, by)
        name = ok and found or nil
    end
    Log("opened by %s", tostring(name or (self.holdOpen and "self-fallback") or "unknown"))
    self:PickTab()
end


function T:Poll()
    self:Refresh("poll")
end





function T:OnEvent(event, arg1, arg2)
    if event == "UI_ERROR_MESSAGE" then
        self:OnError(arg1, arg2)
        return
    end
    if event == "CURRENT_SPELL_CAST_CHANGED" then
        local shown, bags, char = Shown(), BagsShown(), CharShown()
        
        
        if shown or bags or char or self.active then
            Log("event CURRENT_SPELL_CAST_CHANGED canTargetItem=%s isTargeting=%s windowShown=%s bagsShown=%s charShown=%s combat=%s",
                Bool(T.Detect()), Bool(_G.SpellIsTargeting and _G.SpellIsTargeting()), Bool(shown), Bool(bags),
                Bool(char), Bool(Combat()))
        end
    end
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if arg1 == "player" then self:StartCastRing() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if arg1 == "player" then self:EndCastRing("succeeded") end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        if arg1 == "player" then self:EndCastRing("interrupted") end
    elseif event == "UNIT_SPELLCAST_FAILED" then
        if arg1 == "player" then self:EndCastRing("failed") end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if arg1 == "player" then self:EndCastRing("stopped") end
    end
    self:Refresh(event)
    if event == "UPDATE_SPELL_TARGET_ITEM_CONTEXT" then
        
        if self.active and Shown() then
            FS:ScheduleRefresh()
        end
    elseif event == "PLAYER_REGEN_ENABLED" and self.active then
        self:EnsureOpen("left combat")
    end
end

function T:Initialize()
    if self.events then
        return
    end
    local f = CreateFrame("Frame")
    self.events = f
    f:SetScript("OnEvent", function(_, event, a, b)
        T:OnEvent(event, a, b)
    end)
    ThugUI.SafeRegisterEvent(f, "CURRENT_SPELL_CAST_CHANGED")
    
    ThugUI.SafeRegisterEvent(f, "UPDATE_SPELL_TARGET_ITEM_CONTEXT")
    ThugUI.SafeRegisterEvent(f, "PLAYER_REGEN_ENABLED")
    
    for _, event in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
        local ok, err = pcall(f.RegisterUnitEvent, f, event, "player")
        if not ok then Log("%s registration failed: %s", event, tostring(err)) end
    end
end






function T:NoteApply(how)
    local now = Now()
    
    
    local fresh = not self.applyAt or now - self.applyAt > 0.2
    self.applyAt = now
    local target = FS.Actions and FS.Actions.TargetOf and FS.Actions.TargetOf(FS:Focused())
    self.applyTarget = target and { bag = target.bag, slot = target.slot } or nil
    if fresh then
        Log("apply (%s)", tostring(how))
    end
end


function T:AfterApply()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.3, function()
            local still = T.Detect()
            Log("after click: stillTargeting=%s", Bool(still))
            T:Refresh("after click")
        end)
    end
end


function T:AfterStop(mode)
    Log("stop button (%s): pressed", tostring(mode))
    if C_Timer and C_Timer.After then
        C_Timer.After(0.3, function()
            Log("stop button (%s): pressed, SpellCanTargetItem after = %s", tostring(mode), Bool(T.Detect()))
            T:Refresh("after stop")
        end)
    end
end



function T:OnError(errType, message)
    if not self.active or not self.applyAt then
        return
    end
    
    if issecretvalue and (issecretvalue(message) or issecretvalue(errType)) then
        return
    end
    if Now() - self.applyAt > self.ERROR_WINDOW then
        return
    end
    if type(message) ~= "string" or message == "" then
        return
    end
    Log("error after apply: %s", message)
    FS:Message(message, "bag")
end








function T.Probe()
    if not T.active then
        Log("probe: not targeting an item")
        return
    end
    if Combat() then
        Log("probe: in combat")
        return
    end
    local at = FS.Actions and FS.Actions.TargetOf and FS.Actions.TargetOf(FS:Focused())
    if not (at and at.bag) then
        Log("probe: focus a bag item first")
        return
    end
    local blocked
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, event, addon, func)
        if event == "ADDON_ACTION_BLOCKED" and (addon == nil or addon == "ThugUI") then
            blocked = "ADDON_ACTION_BLOCKED " .. tostring(func)
        end
    end)
    pcall(frame.RegisterEvent, frame, "ADDON_ACTION_BLOCKED")
    local ok, err = pcall(_G.C_Container.UseContainerItem, at.bag, at.slot)
    pcall(frame.UnregisterEvent, frame, "ADDON_ACTION_BLOCKED")
    if not ok then
        blocked = tostring(err)
    end
    Log("probe: UseContainerItem(%s, %s) %s", tostring(at.bag), tostring(at.slot), blocked or "ok (no block raised)")
end

if _G.SlashCmdList then
    _G.SLASH_THUGFS1 = "/thugfs"
    _G.SlashCmdList["THUGFS"] = function(msg)
        if type(msg) == "string" and msg:lower():match("^%s*targetprobe%s*$") then
            T.Probe()
        else
            print("/thugfs targetprobe: while the game waits for an item, try UseContainerItem from Lua on the focused bag item and log the answer")
        end
    end
end
