





















local ThugUI = _G.ThugUI
local CS = {}
ThugUI.ControllerStream = CS
ThugUI:RegisterModule("ControllerStream", CS)

ThugUI.defaults.ControllerStream = {
    enabled = true,
    width = 420,
    height = 150,
    fontSize = 13,
    bgAlpha = 0,
    timestamps = false,
    fade = true,
    fadeAfter = 20,       
    maxLines = 100,
    
    
    show = { say = true, whisper = true, party = true, raid = true, guild = true,
             system = true, achievement = true, npc = true },
    showInCombat = false, 
    allChannels = true,   
    channels = {},        
    
}

local frame, smf
CS.unlocked = false

function CS:Cfg()
    ThugUIDB.ControllerStream = ThugUIDB.ControllerStream or {}
    local c = ThugUIDB.ControllerStream
    for k, v in pairs(ThugUI.defaults.ControllerStream) do
        if c[k] == nil then
            if type(v) == "table" then
                local copy = {}
                for kk, vv in pairs(v) do copy[kk] = vv end
                c[k] = copy
            else
                c[k] = v
            end
        end
    end
    return c
end



function CS:Wants(category, channelName)
    local c = self:Cfg()
    if category == "channel" then
        if c.allChannels then return true end
        return channelName ~= nil and c.channels[channelName] and true or false
    end
    return c.show[category] and true or false
end





local function Place()
    if not frame then return end
    local c = CS:Cfg()
    frame:ClearAllPoints()
    local p = c.point
    if type(p) == "table" and type(p[1]) == "number" and type(p[2]) == "number" then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", p[1], p[2])
    else
        
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 260)
    end
end

local function SavePoint()
    local l, b = frame:GetLeft(), frame:GetBottom()
    if not (l and b) then return end
    CS:Cfg().point = { l, b }
end

function CS:Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "ThugUI_ControllerStream", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("LOW")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if CS.unlocked and not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePoint()
        Place()
    end)
    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    end

    smf = CreateFrame("ScrollingMessageFrame", nil, frame)
    smf:SetPoint("TOPLEFT", 6, -6)
    smf:SetPoint("BOTTOMRIGHT", -6, 6)
    smf:SetJustifyH("LEFT")
    smf:SetInsertMode("BOTTOM")
    
    smf:EnableMouse(false)
    smf:EnableMouseWheel(false)

    frame:Hide()
    CS.frame, CS.smf = frame, smf
    self:ApplySettings()
    return frame
end

function CS:ApplySettings()
    if not frame then return end
    local c = self:Cfg()
    frame:SetSize(c.width or 420, c.height or 150)
    Place()
    
    
    
    local font = (ChatFontNormal and ChatFontNormal.GetFont and select(1, ChatFontNormal:GetFont()))
        or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    smf:SetFont(font, c.fontSize or 13, "OUTLINE")
    smf:SetMaxLines(c.maxLines or 100)
    smf:SetFading(c.fade and true or false)
    smf:SetTimeVisible(c.fadeAfter or 20)
    local unlocked = self.unlocked
    self:ApplyVisibility()
    
    
    frame:EnableMouse(unlocked)
    if frame.SetBackdropColor then
        frame:SetBackdropColor(0, 0, 0, unlocked and math.max(c.bgAlpha or 0, 0.35) or (c.bgAlpha or 0))
        frame:SetBackdropBorderColor(1, 0.82, 0, unlocked and 0.9 or 0)
    end
    self:UpdateShown()
end



function CS:WantShown()
    if not frame then return false end
    if self.unlocked then return true end
    local c = self:Cfg()
    if not c.enabled then return false end
    local CM = ThugUI.ControllerMode
    if not (CM and CM:Uses("chat")) then return false end
    local GC = ThugUI.GamepadChat
    if GC and GC.window and GC.window:IsShown() then return false end
    return true
end







function CS:RuledAlpha(alpha)
    if self.unlocked then return 1 end
    local V = ThugUI.Visibility
    if self:Cfg().showInCombat == true and V and V:InCombat() then return 1 end
    return alpha or 1
end

function CS:ApplyVisibility()
    if not frame then return end
    local V = ThugUI.Visibility
    frame:SetAlpha(self:RuledAlpha(V and V:CurrentAlpha("controllerStream") or 1))
end

function CS:UpdateShown()
    if not frame then return end
    frame:SetShown(self:WantShown())
end

function CS:SetUnlocked(on)
    self.unlocked = on and true or false
    self:Build()
    self:ApplySettings()
    
    
    
    local w = ThugUI.Window and ThugUI.Window.frame
    if self.unlocked and w and w.HookScript and not self.hookedSettings then
        self.hookedSettings = true
        w:HookScript("OnHide", function() if CS.unlocked then CS:SetUnlocked(false) end end)
    end
end

function CS:ResetPosition()
    self:Cfg().point = nil
    Place()
end





function CS:OnLine(text, r, g, b, category, channelName)
    if not smf then return end
    if not self:Cfg().enabled then return end
    if not self:Wants(category, channelName) then return end
    local out = text
    if self:Cfg().timestamps and type(text) == "string" and not (issecretvalue and issecretvalue(text)) then
        out = date("%H:%M ") .. text
    end
    smf:AddMessage(out, r or 1, g or 1, b or 1)
end

function CS:Initialize()
    self:Cfg()
    self:Build()
    if ThugUI.Visibility then
        ThugUI.Visibility:Register("controllerStream", function(alpha)
            if frame then frame:SetAlpha(CS:RuledAlpha(alpha)) end
        end)
    end
    local GC = ThugUI.GamepadChat
    if GC and GC.AddLineListener then
        GC:AddLineListener(function(...) CS:OnLine(...) end)
    end
    
    local function Hook()
        if CS.hookedWindow or not (GC and GC.window) then return end
        CS.hookedWindow = true
        GC.window:HookScript("OnShow", function() CS:UpdateShown() end)
        GC.window:HookScript("OnHide", function() CS:UpdateShown() end)
    end
    Hook()
    local CM = ThugUI.ControllerMode
    if CM then
        CM:RegisterCallback(function() Hook(); CS:UpdateShown() end)
        CM:RegisterFeatureCallback("chat", function() CS:UpdateShown() end)
    end
end
