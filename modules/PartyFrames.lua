
















































local ThugUI = _G.ThugUI
local PF = {}
ThugUI.PartyFrames = PF
ThugUI:RegisterModule("PartyFrames", PF)

PF.RING_THICKNESSES = { 6, 10, 14, 18, 24 }   
local MEDIA = "Interface\\AddOns\\ThugUI\\media\\party\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local SLOTS = 5

ThugUI.defaults.PartyFrames = {
    unlocked = false, point = nil,
    shape = "bars",            
    growth = "down",           
    
    
    selThickness = 2,
    showInCombat = false,      
    spacing = 8, scale = 1, showSelf = true,   
    
    width = 160, healthHeight = 24, powerHeight = 6, showHealth = true, showPower = true,
    
    size = 56, showResource = true, edge = 4, ring = 10, gap = 2,
    icon = "role",             
    iconScale = 1, iconX = 0, iconY = 0, iconRound = true,
    
    
    
    bgSource = "health", bgColor = "auto",
    ring1Source = "power", ring1Color = "auto",          
    ring2On = false, ring2Source = "heals", ring2Color = "auto", ring2Edge = 3, ring2Ring = 6, ring2Gap = 2,
    
    showName = true, healthText = "none", textScale = 1, classColor = true,
    dim = false, dimAmount = 0.3,
    rangeFade = true, rangeAlpha = 0.45,
}

local function Cfg()
    ThugUIDB.PartyFrames = ThugUIDB.PartyFrames or {}
    local c = ThugUIDB.PartyFrames
    
    
    
    
    if c.showSelfOnce == nil then
        c.showSelf = true
        c.showSelfOnce = true
    end
    for k, v in pairs(ThugUI.defaults.PartyFrames) do
        if c[k] == nil and v ~= nil then c[k] = v end
    end
    return c
end
PF.Cfg = Cfg








local LOOK_KEYS = {}
for _, k in ipairs({ "shape", "size", "width", "healthHeight", "powerHeight", "showHealth", "showPower",
    "classColor", "showResource", "edge", "ring", "gap", "icon", "iconScale", "iconX", "iconY", "iconRound",
    "bgSource", "bgColor", "bgRGB", "ring1Source", "ring1Color", "ring1RGB",
    "ring2On", "ring2Source", "ring2Color", "ring2RGB", "ring2Edge", "ring2Ring", "ring2Gap" }) do
    LOOK_KEYS[k] = true
end
PF.LOOK_KEYS = LOOK_KEYS
PF.ROLES = { "TANK", "HEALER", "DAMAGER" }


function PF:RoleCfg(role)
    local c = Cfg()
    if type(c.roles) ~= "table" then c.roles = {} end
    local r = c.roles[role]
    if type(r) ~= "table" then
        r = { on = false }
        c.roles[role] = r
    end
    return r
end



function PF:SetRoleOn(role, on)
    local r = self:RoleCfg(role)
    if on and not r.seeded then
        local c = Cfg()
        for k in pairs(LOOK_KEYS) do
            if r[k] == nil then
                local v = c[k]
                if type(v) == "table" then
                    local copy = {}
                    for kk, vv in pairs(v) do copy[kk] = vv end
                    v = copy
                end
                r[k] = v
            end
        end
        r.seeded = true
    end
    r.on = on and true or false
    self:Layout()
end



function PF:LookFor(role)
    local c = Cfg()
    local r = role and type(c.roles) == "table" and c.roles[role]
    if type(r) ~= "table" or r.on ~= true then return c end
    return setmetatable({}, { __index = function(_, k)
        if LOOK_KEYS[k] then
            local v = r[k]
            if v ~= nil then return v end
        end
        return c[k]
    end })
end

local function Num(v, d) v = tonumber(v) if v == nil then return d end return v end

local function SafeSecret(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

function PF:IsActive()
    if not ThugUI:IsModuleOn("partyframes") then return false end
    if ThugUI.UnitFrames then return ThugUI.UnitFrames:Active() end
    return true
end


function PF.RingTexture(t)
    local best = PF.RING_THICKNESSES[1]
    for _, v in ipairs(PF.RING_THICKNESSES) do
        if math.abs(v - Num(t, 10)) < math.abs(best - Num(t, 10)) then best = v end
    end
    return ("%sRing_T%02d"):format(MEDIA, best), best
end





local hiddenParent = CreateFrame("Frame", nil, UIParent)
hiddenParent:Hide()
local parked = {}           
local parkPending = false

local function EditModeOpen()
    local em = _G.EditModeManagerFrame
    return em and em.IsShown and em:IsShown() or false
end

local function Unreg(f)
    if type(f) == "table" and f.UnregisterAllEvents then pcall(f.UnregisterAllEvents, f) end
end

local function Repark()
    if InCombatLockdown() or EditModeOpen() then
        if not parkPending then
            parkPending = true
            C_Timer.After(0.25, function() parkPending = false Repark() end)
        end
        return
    end
    for f in pairs(parked) do
        if f:GetParent() ~= hiddenParent then f:SetParent(hiddenParent) end
    end
end

local function Park(f)
    if type(f) ~= "table" or parked[f] then return end
    parked[f] = true
    Unreg(f)
    
    local pool = rawget(f, "PartyMemberFramePool")
    if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
        for m in pool:EnumerateActive() do
            Unreg(m)
            Unreg(m.HealthBar or m.healthbar)
            Unreg(m.ManaBar or m.manabar)
        end
    end
    f:Hide()
    hooksecurefunc(f, "SetParent", function(_, parent)
        if parent ~= hiddenParent then C_Timer.After(0, Repark) end
    end)
    
    hooksecurefunc(f, "Show", function(self)
        C_Timer.After(0, function() if not InCombatLockdown() then self:Hide() end end)
    end)
end

local parkHooked = false
function PF:SwitchOffBlizzard()
    if InCombatLockdown() then self.pendingPark = true return end
    self.pendingPark = false
    Park(_G.PartyFrame)
    if _G.CompactPartyFrame then Park(_G.CompactPartyFrame) end
    if not parkHooked and type(_G.CompactPartyFrame_Generate) == "function" then
        parkHooked = true
        
        hooksecurefunc("CompactPartyFrame_Generate", function()
            C_Timer.After(0, function() PF:SwitchOffBlizzard() end)
        end)
    end
    Repark()
end











local managerParent         
local managerHooked = false

function PF:WantsManagerHidden()
    if not self:IsActive() then return false end
    local ok, inGroup = pcall(IsInGroup)
    local ok2, inRaid = pcall(IsInRaid)
    return ok and inGroup == true and not (ok2 and inRaid == true)
end

function PF:SyncRaidManager()
    local m = _G.CompactRaidFrameManager
    if type(m) ~= "table" or not m.SetParent then return end
    if InCombatLockdown() then self.pendingManager = true return end
    self.pendingManager = false
    if self:WantsManagerHidden() then
        if m:GetParent() ~= hiddenParent then
            managerParent = managerParent or m:GetParent()
            m:SetParent(hiddenParent)
            if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("PARTY", "raid manager hidden (party)") end
        end
        if not managerHooked then
            managerHooked = true
            hooksecurefunc(m, "SetParent", function(_, parent)
                if parent ~= hiddenParent and PF:WantsManagerHidden() then
                    C_Timer.After(0, function() PF:SyncRaidManager() end)
                end
            end)
        end
    elseif managerParent and m:GetParent() == hiddenParent then
        m:SetParent(managerParent)
        if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("PARTY", "raid manager back") end
    end
end





local holder
local members = {}          
PF.members = members

local function Units()
    local c = Cfg()
    local list = {}
    if c.showSelf then list[#list + 1] = "player" end
    for i = 1, 4 do list[#list + 1] = "party" .. i end
    return list
end
PF.Units = Units

local function StatusBar(parent, texture)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetStatusBarTexture(texture or WHITE)
    b:SetMinMaxValues(0, 1)
    b:SetValue(1)
    return b
end


local function Radial(parent)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetAllPoints()
    if Enum and Enum.StatusBarRenderMode and b.SetRenderMode then
        b:SetRenderMode(Enum.StatusBarRenderMode.Radial)
        b.radial = true
    end
    return b
end

local function MakeHolder()
    if holder then return holder end
    holder = CreateFrame("Frame", "ThugUI_PartyFrames", UIParent, "BackdropTemplate")
    holder:SetFrameStrata("LOW")
    holder:SetClampedToScreen(true)
    holder:SetMovable(true)
    holder:RegisterForDrag("LeftButton")
    holder:SetScript("OnDragStart", function(self)
        if Cfg().unlocked and not InCombatLockdown() then self:StartMoving() end
    end)
    holder:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if x then
            local k = (self:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
            Cfg().point = { x = x * k, y = y * k }
            PF:Layout()
        end
    end)
    holder.label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    holder.label:SetPoint("BOTTOM", holder, "TOP", 0, 4)
    holder.label:SetText("Party frames\n|cffffffffdrag to move|r")
    holder.label:Hide()
    PF.holder = holder
    return holder
end




local function Edges(parent)
    local E = {}
    for i, spec in ipairs({
        { "HORIZONTAL", false }, { "VERTICAL", true }, { "HORIZONTAL", true }, { "VERTICAL", false },
    }) do
        local e = StatusBar(parent)
        e:SetOrientation(spec[1])
        e:SetReverseFill(spec[2])
        e:SetMinMaxValues((i - 1) * 25, i * 25)
        e.bg = e:CreateTexture(nil, "BACKGROUND")
        e.bg:SetAllPoints()
        E[i] = e
    end
    return E
end

local function BuildMember(slot)
    if members[slot] then return members[slot] end
    local f = CreateFrame("Frame", "ThugUI_PartyMember" .. slot, MakeHolder())
    f.slot = slot
    local level = f:GetFrameLevel()

    
    f.bars = CreateFrame("Frame", nil, f)
    f.bars:SetAllPoints()
    f.healthBar = StatusBar(f.bars)
    f.healthBar.bg = f.healthBar:CreateTexture(nil, "BACKGROUND")
    f.healthBar.bg:SetAllPoints()
    f.healthBar.bg:SetColorTexture(0, 0, 0, 0.6)
    f.powerBar = StatusBar(f.bars)
    f.powerBar.bg = f.powerBar:CreateTexture(nil, "BACKGROUND")
    f.powerBar.bg:SetAllPoints()
    f.powerBar.bg:SetColorTexture(0, 0, 0, 0.6)

    
    
    
    
    f.square = CreateFrame("Frame", nil, f)
    f.square:SetAllPoints()
    f.square.bg = f.square:CreateTexture(nil, "BACKGROUND")
    f.square.bg:SetAllPoints()
    f.square.bg:SetColorTexture(0, 0, 0, 0.6)
    f.square.health = StatusBar(f.square)
    f.square.health:SetOrientation("VERTICAL")
    f.square.health2 = StatusBar(f.square)
    f.square.health2:SetOrientation("VERTICAL")
    f.square.health2:SetAllPoints(f.square.health)
    f.square.health2:SetFrameLevel(f.square.health:GetFrameLevel() + 1)
    f.edges = Edges(f.square)
    f.edges2 = Edges(f.square)

    
    f.circle = CreateFrame("Frame", nil, f)
    f.circle:SetAllPoints()
    f.circle.bg = f.circle:CreateTexture(nil, "BACKGROUND")
    f.circle.bg:SetTexture(MEDIA .. "Disc")
    f.circle.bg:SetVertexColor(0, 0, 0, 0.6)
    f.circle.health = StatusBar(f.circle, MEDIA .. "Disc")
    f.circle.health:SetOrientation("VERTICAL")
    f.circle.health2 = StatusBar(f.circle, MEDIA .. "Disc")
    f.circle.health2:SetOrientation("VERTICAL")
    f.circle.health2:SetAllPoints(f.circle.health)
    f.circle.health2:SetFrameLevel(f.circle.health:GetFrameLevel() + 1)
    f.ringHost = CreateFrame("Frame", nil, f.circle)
    f.ringBg = f.ringHost:CreateTexture(nil, "BORDER")
    f.ringBg:SetAllPoints()
    f.ring = Radial(f.ringHost)
    f.ringB = Radial(f.ringHost)
    f.ringB:SetFrameLevel(f.ring:GetFrameLevel() + 1)
    f.ring2Host = CreateFrame("Frame", nil, f.circle)
    f.ring2Host:SetAllPoints()
    f.ring2Bg = f.ring2Host:CreateTexture(nil, "BORDER")
    f.ring2Bg:SetAllPoints()
    f.ring2 = Radial(f.ring2Host)
    f.ring2B = Radial(f.ring2Host)
    f.ring2B:SetFrameLevel(f.ring2:GetFrameLevel() + 1)

    
    f.over = CreateFrame("Frame", nil, f)
    f.over:SetAllPoints()
    f.over:SetFrameLevel(level + 6)
    f.shade = f.over:CreateTexture(nil, "BACKGROUND")
    f.shade:SetColorTexture(0, 0, 0, 0.3)
    
    
    
    
    f.selGlow = f.over:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.selGlow:SetColorTexture(1, 1, 1, 0.2)
    if f.selGlow.SetBlendMode then f.selGlow:SetBlendMode("ADD") end
    f.selGlow:Hide()
    f.selEdges = {}
    for i = 1, 4 do
        local t = f.over:CreateTexture(nil, "BORDER")
        t:SetColorTexture(1, 0.82, 0, 1)
        t:Hide()
        f.selEdges[i] = t
    end
    f.selRing = f.over:CreateTexture(nil, "BORDER")
    f.selRing:SetTexture(MEDIA .. "Ring_T06")
    f.selRing:SetVertexColor(1, 0.82, 0, 1)
    f.selRing:Hide()
    f.icon = f.over:CreateTexture(nil, "ARTWORK")
    
    
    if f.over.CreateMaskTexture then
        f.iconMask = f.over:CreateMaskTexture()
        f.iconMask:SetTexture(MEDIA .. "Disc", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        f.iconMask:SetAllPoints(f.icon)
    end
    f.name = f.over:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.name:SetWordWrap(false)
    f.name:SetShadowOffset(1, -1)
    f.healthText = f.over:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.healthText:SetShadowOffset(1, -1)
    f.status = f.over:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.status:SetShadowOffset(1, -1)

    members[slot] = f
    return f
end



local clicks = {}
PF.clicks = clicks

local function ClickButton(slot)
    if clicks[slot] then return clicks[slot] end
    if InCombatLockdown() then return nil end
    local b = CreateFrame("Button", "ThugUI_PartyClick" .. slot, UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyDown", "AnyUp")
    b:SetAttribute("useOnKeyDown", true)
    b:SetAttribute("type1", "macro")
    b:SetAttribute("macrotext1", "")
    b:SetFrameStrata("LOW")
    b:HookScript("OnEnter", function(self)
        if self.unit and GameTooltip_SetDefaultAnchor then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            pcall(GameTooltip.SetUnit, GameTooltip, self.unit)
            GameTooltip:Show()
        end
    end)
    b:HookScript("OnLeave", function() GameTooltip:Hide() end)
    
    
    
    b:HookScript("OnClick", function(self, button, down)
        if button == "RightButton" and not down and self.unit and ThugUI.UnitMenuWindow then
            ThugUI.UnitMenuWindow:Open(self.unit, self)
        end
    end)
    b:Hide()
    clicks[slot] = b
    return b
end

function PF:SyncClicks()
    if InCombatLockdown() then self.pendingClicks = true return end
    self.pendingClicks = false
    for slot = 1, SLOTS do
        local f, b = members[slot], nil
        local want = holder and holder:IsShown() and f and f:IsShown() and f.unit and not f.sample
        if want then b = ClickButton(slot) else b = clicks[slot] end
        if b then
            if want then
                b.unit = f.unit
                b:SetAttribute("macrotext1", "/target " .. f.unit)
                b:ClearAllPoints()
                b:SetAllPoints(f)
                b:Show()
            else
                b.unit = nil
                b:Hide()
            end
        end
    end
end







local baseFont = setmetatable({}, { __mode = "k" })
local function ScaleFont(fs, scale)
    local b = baseFont[fs]
    if not b then
        local path, size, flags = fs:GetFont()
        if type(path) ~= "string" or type(size) ~= "number" then return end
        b = { path, size, flags }
        baseFont[fs] = b
    end
    fs:SetFont(b[1], b[2] * scale, b[3])
end


local function MemberSize(c)
    if c.shape == "bars" then
        local h = (c.showHealth ~= false and Num(c.healthHeight, 24) or 0)
            + (c.showPower ~= false and Num(c.powerHeight, 6) or 0)
        return Num(c.width, 160), math.max(h, 4)
    end
    local s = Num(c.size, 56)
    return s, s
end
PF.MemberSize = MemberSize


local function PlaceEdges(E, inset, thick, shown)
    local t = math.max(thick, 1)
    for _, e in ipairs(E) do e:SetShown(shown) e:ClearAllPoints() end
    E[1]:SetPoint("TOPLEFT", inset, -inset) E[1]:SetPoint("TOPRIGHT", -inset, -inset) E[1]:SetHeight(t)
    E[2]:SetPoint("TOPRIGHT", -inset, -inset) E[2]:SetPoint("BOTTOMRIGHT", -inset, inset) E[2]:SetWidth(t)
    E[3]:SetPoint("BOTTOMLEFT", inset, inset) E[3]:SetPoint("BOTTOMRIGHT", -inset, inset) E[3]:SetHeight(t)
    E[4]:SetPoint("TOPLEFT", inset, -inset) E[4]:SetPoint("BOTTOMLEFT", inset, inset) E[4]:SetWidth(t)
end



local function DressRing(bar, extra, bg, tex, shown)
    for _, b in ipairs({ bar, extra }) do
        b:SetStatusBarTexture(tex)
        b:SetShown(shown and b.radial == true)
        local rt = b:GetStatusBarTexture()
        if rt and rt.SetRadialProgressBarStartOffset then rt:SetRadialProgressBarStartOffset(0.5) end
    end
    bg:SetTexture(tex)
    bg:SetShown(shown)
end


local function RingOn(c, which)
    if which == 1 then return c.showResource ~= false end
    return c.ring2On == true
end
PF.RingOn = RingOn



local function LayoutMember(f, c, shared)
    shared = shared or c
    local w, h = MemberSize(c)
    f:SetSize(w, h)
    f.bars:SetShown(c.shape == "bars")
    f.square:SetShown(c.shape == "square")
    f.circle:SetShown(c.shape == "circle")
    local ts = Num(shared.textScale, 1)
    ScaleFont(f.name, ts)
    ScaleFont(f.healthText, ts)
    ScaleFont(f.status, ts)
    f.icon:ClearAllPoints()
    f.name:ClearAllPoints()
    f.healthText:ClearAllPoints()
    f.status:ClearAllPoints()
    f.shade:ClearAllPoints()
    local ix, iy = Num(c.iconX, 0), Num(c.iconY, 0)

    if c.shape == "bars" then
        local showH, showP = c.showHealth ~= false, c.showPower ~= false
        local hh, ph = Num(c.healthHeight, 24), Num(c.powerHeight, 6)
        f.healthBar:SetShown(showH)
        f.healthBar:ClearAllPoints()
        f.healthBar:SetPoint("TOPLEFT")
        f.healthBar:SetPoint("TOPRIGHT")
        f.healthBar:SetHeight(hh)
        f.powerBar:SetShown(showP)
        f.powerBar:ClearAllPoints()
        if showH then
            f.powerBar:SetPoint("TOPLEFT", f.healthBar, "BOTTOMLEFT")
            f.powerBar:SetPoint("TOPRIGHT", f.healthBar, "BOTTOMRIGHT")
        else
            f.powerBar:SetPoint("TOPLEFT")
            f.powerBar:SetPoint("TOPRIGHT")
        end
        f.powerBar:SetHeight(ph)
        local main = showH and f.healthBar or f.powerBar
        
        local isz = h * Num(c.iconScale, 1)
        f.icon:SetSize(isz, isz)
        f.icon:SetPoint("RIGHT", f, "LEFT", -3 + ix, iy)
        if showH then
            f.name:SetPoint("LEFT", f.healthBar, "LEFT", 4, 0)
            f.name:SetPoint("RIGHT", f.healthText, "LEFT", -4, 0)
            f.healthText:SetPoint("RIGHT", f.healthBar, "RIGHT", -4, 0)
        else
            f.name:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2)
            f.name:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 2)
            f.healthText:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 2)
        end
        f.name:SetJustifyH("LEFT")
        f.status:SetPoint("CENTER", main, "CENTER")
        f.shade:SetAllPoints(f)
    else
        local s = Num(c.size, 56)
        local on1, on2 = RingOn(c, 1), RingOn(c, 2)
        local gap1, gap2 = Num(c.gap, 2), Num(c.ring2Gap, 2)
        local inset
        if c.shape == "square" then
            
            local e2 = on2 and Num(c.ring2Edge, 3) or 0
            local out2 = on2 and (e2 + gap2) or 0
            local e1 = on1 and Num(c.edge, 4) or 0
            PlaceEdges(f.edges2, 0, e2, on2)
            PlaceEdges(f.edges, out2, e1, on1)
            inset = out2 + (on1 and (e1 + gap1) or 0)
            f.square.health:ClearAllPoints()
            f.square.health:SetPoint("TOPLEFT", inset, -inset)
            f.square.health:SetPoint("BOTTOMRIGHT", -inset, inset)
        else
            
            
            local tex2, t2 = PF.RingTexture(c.ring2Ring or 6)
            local out2 = on2 and (s * t2 / 100 + gap2) or 0
            DressRing(f.ring2, f.ring2B, f.ring2Bg, tex2, on2)
            f.ringHost:ClearAllPoints()
            f.ringHost:SetPoint("TOPLEFT", out2, -out2)
            f.ringHost:SetPoint("BOTTOMRIGHT", -out2, out2)
            local tex1, t1 = PF.RingTexture(c.ring)
            DressRing(f.ring, f.ringB, f.ringBg, tex1, on1)
            inset = out2 + (on1 and ((s - out2 * 2) * t1 / 100 + gap1) or 0)
            f.circle.bg:ClearAllPoints()
            f.circle.bg:SetPoint("TOPLEFT", inset, -inset)
            f.circle.bg:SetPoint("BOTTOMRIGHT", -inset, inset)
            f.circle.health:ClearAllPoints()
            f.circle.health:SetPoint("TOPLEFT", inset, -inset)
            f.circle.health:SetPoint("BOTTOMRIGHT", -inset, inset)
        end
        local inner = s - inset * 2
        local isz = inner * 0.55 * Num(c.iconScale, 1)
        f.icon:SetSize(isz, isz)
        f.icon:SetPoint("CENTER", ix, iy)
        f.name:SetPoint("TOP", f, "BOTTOM", 0, -2)
        f.name:SetWidth(math.max(s + 24, 40))
        f.name:SetJustifyH("CENTER")
        f.healthText:SetPoint("BOTTOM", f, "BOTTOM", 0, inset + 2)
        f.status:SetPoint("CENTER")
        f.shade:SetPoint("TOPLEFT", inset, -inset)
        f.shade:SetPoint("BOTTOMRIGHT", -inset, inset)
    end
    
    local round = c.shape == "circle" and c.iconRound ~= false and f.iconMask ~= nil
    if round ~= (f.iconMasked == true) and f.icon.AddMaskTexture then
        if round then f.icon:AddMaskTexture(f.iconMask) else f.icon:RemoveMaskTexture(f.iconMask) end
        f.iconMasked = round
    end
    
    f.selGlow:ClearAllPoints()
    f.selGlow:SetAllPoints(f)
    
    local th = math.max(1, Num(shared.selThickness, 2))
    local sr, sg, sb = 1, 0.82, 0
    if type(shared.selColor) == "table" then
        local t = shared.selColor
        sr, sg, sb = Num(t.r or t[1], 1), Num(t.g or t[2], 0.82), Num(t.b or t[3], 0)
    end
    local E = f.selEdges
    for _, t in ipairs(E) do t:ClearAllPoints() t:SetColorTexture(sr, sg, sb, 1) end
    
    local o = th + 1
    E[1]:SetPoint("BOTTOMLEFT", f, "TOPLEFT", -o, 1) E[1]:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", o, 1) E[1]:SetHeight(th)
    E[3]:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -o, -1) E[3]:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", o, -1) E[3]:SetHeight(th)
    E[4]:SetPoint("TOPRIGHT", f, "TOPLEFT", -1, 1) E[4]:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -1, -1) E[4]:SetWidth(th)
    E[2]:SetPoint("TOPLEFT", f, "TOPRIGHT", 1, 1) E[2]:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 1, -1) E[2]:SetWidth(th)
    
    
    
    
    local tex, t = PF.RingTexture(th / (w + 2 * th) * 100)
    local pad = (t / 100) * w / (1 - 2 * t / 100)
    f.selRing:SetTexture(tex)
    f.selRing:SetVertexColor(sr, sg, sb, 1)
    f.selRing:ClearAllPoints()
    f.selRing:SetPoint("TOPLEFT", -pad, pad)
    f.selRing:SetPoint("BOTTOMRIGHT", pad, -pad)
    f.shade:SetShown(shared.dim == true)
    
    
    local dimA = math.max(0, math.min(0.9, Num(shared.dimAmount, 0.3)))
    if c.shape == "circle" then
        f.shade:SetTexture(MEDIA .. "Disc")
        f.shade:SetVertexColor(0, 0, 0, dimA)
    else
        f.shade:SetVertexColor(1, 1, 1, 1)
        f.shade:SetColorTexture(0, 0, 0, dimA)
    end
    f.laidLook = c
end

function PF:Layout()
    local c = Cfg()
    local h = MakeHolder()
    local s = Num(c.scale, 1)
    h:SetScale(s)
    for slot = 1, SLOTS do BuildMember(slot) end
    h:ClearAllPoints()
    local p = c.point
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        h:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x / s, p.y / s)
    else
        h:SetPoint("LEFT", UIParent, "LEFT", 40 / s, 80 / s)
    end
    self:ApplyUnlocked()
    self:UpdateAll()
end





function PF:Position()
    if InCombatLockdown() then self.pendingPosition = true return end
    self.pendingPosition = false
    local c = Cfg()
    local h = MakeHolder()
    local spacing = Num(c.spacing, 8)
    
    local shown, cellW, cellH = {}, 0, 0
    for slot = 1, SLOTS do
        local f = BuildMember(slot)
        local look = self:LookFor(f.role)
        f.look = look
        LayoutMember(f, look, c)
        local w, mh = MemberSize(look)
        
        local extra = (look.shape ~= "bars" and c.showName ~= false) and 14 or 0
        f.cellW, f.cellH = w, mh + extra
        f:ClearAllPoints()
        if f.unit then
            shown[#shown + 1] = f
            cellW, cellH = math.max(cellW, w), math.max(cellH, mh + extra)
        else
            f:SetPoint("TOPLEFT", h, "TOPLEFT", 0, 0)   
        end
    end
    if #shown == 0 then
        local w, mh = MemberSize(c)
        h:SetSize(w, mh)
        return
    end
    if c.shape ~= "bars" then
        
        
        
        
        
        local fill, per = PF.GridOf(c)
        local cols, rows = 0, 0
        for i, f in ipairs(shown) do
            local k = i - 1
            local col, row
            if fill == "rows" then
                col, row = k % per, math.floor(k / per)
            else
                col, row = math.floor(k / per), k % per
            end
            f:SetPoint("TOPLEFT", h, "TOPLEFT", col * (cellW + spacing), -row * (cellH + spacing))
            cols, rows = math.max(cols, col + 1), math.max(rows, row + 1)
        end
        h:SetSize(cols * cellW + (cols - 1) * spacing, rows * cellH + (rows - 1) * spacing)
        return
    end
    
    local x, y = 0, 0
    for _, f in ipairs(shown) do
        if c.growth == "right" then
            f:SetPoint("TOPLEFT", h, "TOPLEFT", x, 0)
            x = x + f.cellW + spacing
        else
            f:SetPoint("TOPLEFT", h, "TOPLEFT", 0, -y)
            y = y + f.cellH + spacing
        end
    end
    if c.growth == "right" then
        h:SetSize(x - spacing, cellH)
    else
        h:SetSize(cellW, y - spacing)
    end
end




function PF.GridOf(c)
    local fill = c.gridFill
    if fill ~= "rows" and fill ~= "columns" then fill = c.growth == "right" and "rows" or "columns" end
    local per = math.floor(Num(c.perLine, SLOTS))
    if per < 1 then per = 1 elseif per > SLOTS then per = SLOTS end
    return fill, per
end

function PF:ApplyUnlocked()
    local h = MakeHolder()
    local on = Cfg().unlocked == true
    h:EnableMouse(on)
    h.label:SetShown(on)
    if h.SetBackdrop then
        if on then
            h:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
            h:SetBackdropColor(0.8, 0.05, 0.05, 0.25)
            h:SetBackdropBorderColor(1, 0.82, 0, 1)
        else
            h:SetBackdrop(nil)
        end
    end
end

function PF:SetUnlocked(v)
    Cfg().unlocked = v and true or false
    self:Layout()
end

function PF:ResetPosition()
    Cfg().point = nil
    self:Layout()
end





local CLASS_ICONS = "Interface\\TargetingFrame\\UI-Classes-Circles"

local RACE_ATLAS_NAME = { Scourge = "undead", HighmountainTauren = "highmountain",
    LightforgedDraenei = "lightforged", ZandalariTroll = "zandalari", KulTiran = "kultiran",
    DarkIronDwarf = "darkirondwarf", MagharOrc = "magharorc", VoidElf = "voidelf",
    NightElf = "nightelf", BloodElf = "bloodelf" }

local function SetIcon(f, unit, c, sample)
    local tex = f.icon
    tex:SetTexCoord(0, 1, 0, 1)
    local kind = c.icon or "role"
    if kind == "none" then tex:Hide() return end
    local ok = false
    if kind == "role" then
        local role = sample and "DAMAGER" or SafeSecret(UnitGroupRolesAssigned(unit))
        if role and role ~= "NONE" and GetMicroIconForRole then
            ok = pcall(tex.SetAtlas, tex, GetMicroIconForRole(role))
        end
    elseif kind == "class" then
        local _, class = UnitClass(sample and "player" or unit)
        class = SafeSecret(class)
        local coords = class and _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[class]
        if coords then
            tex:SetTexture(CLASS_ICONS)
            tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            ok = true
        end
    elseif kind == "race" then
        local _, race = UnitRace(sample and "player" or unit)
        race = SafeSecret(race)
        local sex = SafeSecret(UnitSex(sample and "player" or unit))
        if race then
            local name = RACE_ATLAS_NAME[race] or race:lower()
            ok = pcall(tex.SetAtlas, tex, ("raceicon128-%s-%s"):format(name, sex == 3 and "female" or "male"))
        end
    elseif kind == "faction" then
        local fac = SafeSecret(UnitFactionGroup(sample and "player" or unit))
        if fac == "Horde" or fac == "Alliance" then
            ok = pcall(tex.SetAtlas, tex, "UI-HUD-UnitFrame-Player-PVP-" .. fac .. "Icon")
        end
    end
    tex:SetShown(ok and true or false)
end

local function PowerColor(unit)
    local _, token = UnitPowerType(unit)
    token = SafeSecret(token)
    local pc = token and PowerBarColor and PowerBarColor[token]
    if pc then return pc.r, pc.g, pc.b end
    return 0, 0.55, 1
end

local function ClassColor(unit)
    local _, class = UnitClass(unit)
    class = SafeSecret(class)
    local rc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if rc then return rc.r, rc.g, rc.b end
    return nil
end

local GREEN = { 0.2, 0.8, 0.25 }
local HEALS = { 0.25, 0.9, 0.45 }
local ABSORBS = { 0.85, 0.9, 1 }

local function HealthColor(unit, c)
    if c.classColor ~= false then
        local r, g, b = ClassColor(unit)
        if r then return r, g, b end
    end
    return GREEN[1], GREEN[2], GREEN[3]
end




local function LayerColor(mode, source, unit, c, rgb)
    if mode == "custom" and type(rgb) == "table" then
        return Num(rgb.r or rgb[1], 1), Num(rgb.g or rgb[2], 1), Num(rgb.b or rgb[3], 1)
    elseif mode == "class" then
        local r, g, b = ClassColor(unit)
        if r then return r, g, b end
        return GREEN[1], GREEN[2], GREEN[3]
    elseif mode == "power" then
        return PowerColor(unit)
    end
    if source == "power" then return PowerColor(unit) end
    if source == "heals" then return HEALS[1], HEALS[2], HEALS[3] end
    return HealthColor(unit, c)
end
PF.LayerColor = LayerColor



local function V(v)
    if issecretvalue and issecretvalue(v) then return v end
    return v or 0
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, ...)
    if ok then return v end
    return nil
end



local function ReadUnit(unit, sample, slot, wantsPct)
    local d = {}
    if sample then
        d.hMax, d.hVal = 100, 70 + slot * 5
        d.pMax, d.pVal = 100, 50 + slot * 10
        d.hPct, d.pPct = d.hVal, d.pVal
        d.heal, d.absorb = 20, 10
        return d
    end
    d.hMax, d.hVal = UnitHealthMax(unit), UnitHealth(unit)
    d.pMax, d.pVal = UnitPowerMax(unit), UnitPower(unit)
    d.heal = Call(UnitGetIncomingHeals, unit)
    d.absorb = Call(UnitGetTotalAbsorbs, unit)
    if wantsPct and CurveConstants and CurveConstants.ScaleTo100 then
        if UnitPowerPercent then d.pPct = Call(UnitPowerPercent, unit, nil, false, CurveConstants.ScaleTo100) end
        if UnitHealthPercent then d.hPct = Call(UnitHealthPercent, unit, true, CurveConstants.ScaleTo100) end
        
        
        if d.pPct == nil and ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("party-no-powerpercent", "PARTY",
                "UnitPowerPercent with CurveConstants.ScaleTo100 unavailable: the square's resource line stays empty")
        end
    end
    return d
end


local function Feed(bar, extra, source, d, r, g, b)
    if source == "power" then
        bar:SetMinMaxValues(0, d.pMax)
        bar:SetValue(V(d.pVal))
    elseif source == "heals" then
        bar:SetMinMaxValues(0, d.hMax)
        bar:SetValue(V(d.heal))
    else
        bar:SetMinMaxValues(0, d.hMax)
        bar:SetValue(V(d.hVal))
    end
    bar:SetStatusBarColor(r, g, b)
    if extra then
        if source == "heals" then
            extra:SetMinMaxValues(0, d.hMax)
            extra:SetValue(V(d.absorb))
            extra:SetStatusBarColor(ABSORBS[1], ABSORBS[2], ABSORBS[3], 0.85)
            extra:Show()
        else
            extra:Hide()
        end
    end
end




local function FeedEdges(E, source, d, r, g, b)
    local pct = (source == "health" and d.hPct) or d.pPct
    for _, e in ipairs(E) do
        if pct ~= nil then e:SetValue(pct) end
        e:SetStatusBarColor(r, g, b)
        e.bg:SetColorTexture(r, g, b, 0.2)
    end
end



local function UpdateBars(f, unit, c, sample)
    local cu = sample and "player" or unit
    local d = ReadUnit(unit, sample, f.slot, c.shape == "square")
    if c.shape == "bars" then
        local hr, hg, hb = HealthColor(cu, c)
        Feed(f.healthBar, nil, "health", d, hr, hg, hb)
        local pr, pg, pb = PowerColor(cu)
        Feed(f.powerBar, nil, "power", d, pr, pg, pb)
        return
    end
    local bgSource = c.bgSource or "health"
    local br, bg, bb = LayerColor(c.bgColor, bgSource, cu, c, c.bgRGB)
    local s1, s2 = c.ring1Source or "power", c.ring2Source or "heals"
    
    
    if c.shape == "square" then
        if s1 == "heals" then s1 = "power" end
        if s2 == "heals" then s2 = "power" end
    end
    local r1, g1, b1 = LayerColor(c.ring1Color, s1, cu, c, c.ring1RGB)
    local r2, g2, b2 = LayerColor(c.ring2Color, s2, cu, c, c.ring2RGB)
    if c.shape == "square" then
        Feed(f.square.health, f.square.health2, bgSource, d, br, bg, bb)
        if RingOn(c, 1) then FeedEdges(f.edges, s1, d, r1, g1, b1) end
        if RingOn(c, 2) then FeedEdges(f.edges2, s2, d, r2, g2, b2) end
    else
        Feed(f.circle.health, f.circle.health2, bgSource, d, br, bg, bb)
        if RingOn(c, 1) then
            Feed(f.ring, f.ringB, s1, d, r1, g1, b1)
            f.ringBg:SetVertexColor(r1, g1, b1, 0.2)
        end
        if RingOn(c, 2) then
            Feed(f.ring2, f.ring2B, s2, d, r2, g2, b2)
            f.ring2Bg:SetVertexColor(r2, g2, b2, 0.2)
        end
    end
end

function PF:UpdateMember(f)
    if not f then return end
    local c = Cfg()
    local unit, sample = f.unit, f.sample
    if not unit then f:Hide() return end
    f:Show()
    
    
    local look = f.laidLook or c
    UpdateBars(f, unit, look, sample)
    SetIcon(f, unit, look, sample)

    if c.showName ~= false then
        if sample then f.name:SetText("Party " .. f.slot) else f.name:SetText(UnitName(unit)) end
        f.name:Show()
    else
        f.name:Hide()
    end
    if c.healthText == "percent" and not sample and UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        f.healthText:SetFormattedText("%d%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
        f.healthText:Show()
    elseif c.healthText == "percent" and sample then
        f.healthText:SetText("75%")
        f.healthText:Show()
    else
        f.healthText:Hide()
    end

    
    local status
    if not sample then
        if SafeSecret(UnitIsConnected(unit)) == false then
            status = "Offline"
        elseif SafeSecret(UnitIsDeadOrGhost(unit)) == true then
            status = SafeSecret(UnitIsGhost(unit)) == true and "Ghost" or "Dead"
        end
    end
    f.status:SetText(status or "")
    f.status:SetShown(status ~= nil)

    
    local isTarget = not sample and SafeSecret(UnitIsUnit(unit, "target")) == true
    local shape = look.shape
    f.selGlow:SetShown(isTarget and shape == "bars")
    for _, t in ipairs(f.selEdges) do t:SetShown(isTarget and shape == "square") end
    f.selRing:SetShown(isTarget and shape == "circle")

    self:UpdateRange(f)
end



function PF:UpdateRange(f)
    local c = Cfg()
    if f.sample or not f.unit or c.rangeFade == false or f.unit == "player" then
        f:SetAlpha(1)
        return
    end
    local inRange, checked = UnitInRange(f.unit)
    if f.SetAlphaFromBoolean and issecretvalue and issecretvalue(inRange) then
        f:SetAlphaFromBoolean(inRange, 1, Num(c.rangeAlpha, 0.45))
        return
    end
    if SafeSecret(checked) == false then f:SetAlpha(1) return end
    f:SetAlpha(inRange == false and Num(c.rangeAlpha, 0.45) or 1)
end



local SAMPLE_ROLE = { "TANK", "HEALER", "DAMAGER", "DAMAGER", "DAMAGER" }

function PF:AssignUnits()
    local c = Cfg()
    local units = Units()
    local inParty = IsInGroup() and not IsInRaid()
    local sampleAll = c.unlocked == true and not inParty
    for slot = 1, SLOTS do
        local f = BuildMember(slot)
        local unit = units[slot]
        f.sample = nil
        f.role = nil
        if sampleAll and unit then
            f.unit, f.sample = unit, true
            
            f.role = SAMPLE_ROLE[slot]
        elseif unit and inParty and SafeSecret(UnitExists(unit)) ~= false then
            f.unit = unit
            local role = SafeSecret(UnitGroupRolesAssigned(unit))
            if role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGER" then role = nil end
            f.role = role
        else
            f.unit = nil
        end
    end
end

function PF:ShouldShow()
    if not (self:IsActive()) then return false end
    if Cfg().unlocked then return true end
    return IsInGroup() and not IsInRaid()
end

function PF:UpdateAll()
    self:SyncRaidManager()
    local h = MakeHolder()
    if not self:ShouldShow() then
        h:Hide()
        self:SyncClicks()
        return
    end
    h:Show()
    self:AssignUnits()
    self:Position()
    for slot = 1, SLOTS do self:UpdateMember(members[slot]) end
    self:SyncClicks()
end

function PF:ApplyAll()
    if not self:IsActive() then
        if holder then holder:Hide() end
        self:SyncClicks()
        self:SyncRaidManager()
        return
    end
    self:SwitchOffBlizzard()
    self:Layout()
end





local UNIT_EVENTS = {
    UNIT_HEALTH = true, UNIT_MAXHEALTH = true, UNIT_POWER_UPDATE = true, UNIT_MAXPOWER = true,
    UNIT_DISPLAYPOWER = true, UNIT_NAME_UPDATE = true, UNIT_CONNECTION = true, UNIT_FLAGS = true,
    
    UNIT_HEAL_PREDICTION = true, UNIT_ABSORB_AMOUNT_CHANGED = true,
}

local driver = CreateFrame("Frame")
PF.driver = driver
driver.since = 0

local function MemberFor(unit)
    for slot = 1, SLOTS do
        local f = members[slot]
        if f and f.unit == unit and not f.sample then return f end
    end
end

driver:SetScript("OnEvent", function(self, event, unit)
    if not PF:IsActive() then return end
    if UNIT_EVENTS[event] then
        local f = MemberFor(unit)
        if f then PF:UpdateMember(f) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        PF:ApplyAll()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if PF.pendingPark then PF:SwitchOffBlizzard() end
        PF:UpdateAll()
    else
        PF:UpdateAll()
    end
end)


driver:SetScript("OnUpdate", function(self, elapsed)
    self.since = self.since + elapsed
    if self.since < 0.5 then return end
    self.since = 0
    if holder and holder:IsShown() then
        for slot = 1, SLOTS do
            local f = members[slot]
            if f and f:IsShown() then PF:UpdateRange(f) end
        end
    end
end)

function PF:Initialize()
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE",
        "PLAYER_TARGET_CHANGED", "PLAYER_ROLES_ASSIGNED" }) do
        ThugUI.SafeRegisterEvent(driver, e)
    end
    for e in pairs(UNIT_EVENTS) do ThugUI.SafeRegisterEvent(driver, e) end
    if ThugUI.ControllerMode and ThugUI.ControllerMode.RegisterCallback then
        ThugUI.ControllerMode:RegisterCallback(function() PF:ApplyAll() end)
    end
    if ThugUI.Visibility then
        ThugUI.Visibility:Register("party", function(alpha)
            if holder then holder:SetAlpha(PF:RuledAlpha(alpha)) end
        end)
    end
end







function PF:RuledAlpha(alpha)
    local V = ThugUI.Visibility
    if Cfg().showInCombat == true and V and V:InCombat() then return 1 end
    return alpha
end


function PF:ApplyVisibility()
    local V = ThugUI.Visibility
    if holder and V then holder:SetAlpha(self:RuledAlpha(V:CurrentAlpha("party"))) end
end

PF.hiddenParent = hiddenParent
PF.parked = parked
