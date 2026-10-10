





















local ThugUI = _G.ThugUI
ThugUI.Dialogs = ThugUI.Dialogs or {}
local D = {}
ThugUI.Dialog = D

local WIDTH, PAD, BUTTON_W, BUTTON_H = 420, 18, 130, 24
local frame

local function Paint(obj, role, how) return ThugUI.Theme:Paint(obj, role, how) end

local function Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "ThugUI_Dialog", UIParent, "BackdropTemplate")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    f:SetSize(WIDTH, 120)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false, edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        Paint(f, "listBackground", "backdrop")
        Paint(f, "border", "border")
    end
    f:Hide()

    local text = Paint(f:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlight")), "label")
    text:SetPoint("TOP", f, "TOP", 0, -PAD)
    text:SetWidth(WIDTH - PAD * 2)
    text:SetJustifyH("CENTER")
    f.text = text

    local edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    edit:SetSize(300, 22)
    edit:SetAutoFocus(false)
    edit:Hide()
    f.editBox = edit
    function f:GetEditBox() return self.editBox end

    f.buttons = {}
    for i = 1, 3 do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(BUTTON_W, BUTTON_H)
        b:Hide()
        b.index = i
        b:SetScript("OnClick", function(self) D:Click(self.index) end)
        f.buttons[i] = b
    end

    
    f:SetScript("OnHide", function(self)
        local def, data, handled = self.def, self.data, self.handled
        self.def, self.data, self.handled = nil, nil, nil
        if def and not handled and def.OnCancel then
            pcall(def.OnCancel, self, data, "escape")
        end
    end)
    
    tinsert(UISpecialFrames, "ThugUI_Dialog")
    frame = f
    return f
end

local function Format(fmt, a1, a2)
    if type(fmt) ~= "string" then return "" end
    if not fmt:find("%%s") then return fmt end
    local ok, out = pcall(string.format, fmt, a1 ~= nil and tostring(a1) or "", a2 ~= nil and tostring(a2) or "")
    return ok and out or fmt
end


function D:Show(which, a1, a2, data)
    local def = ThugUI.Dialogs[which]
    if not def then error("ThugUI.Dialog: unknown dialog " .. tostring(which)) end
    local f = Build()
    
    if f:IsShown() then f:Hide() end
    self.serial = (self.serial or 0) + 1
    self.last = { which = which, text_arg1 = a1, text_arg2 = a2, data = data }
    f.which, f.def, f.data, f.handled = which, def, data, false

    f.text:SetText(Format(def.text, a1, a2))
    local textH = (f.text.GetStringHeight and f.text:GetStringHeight()) or 14
    if type(textH) ~= "number" or textH <= 0 then textH = 14 end
    local y = PAD + textH + 12

    local edit = f.editBox
    if def.hasEditBox then
        edit:SetWidth(def.editBoxWidth or 300)
        edit:ClearAllPoints()
        edit:SetPoint("TOP", f, "TOP", 0, -y)
        edit:SetText("")
        edit:SetScript("OnEnterPressed", function(self)
            if def.EditBoxOnEnterPressed then def.EditBoxOnEnterPressed(self, f.data) else D:Click(1) end
        end)
        edit:SetScript("OnEscapePressed", function(self)
            if def.EditBoxOnEscapePressed then def.EditBoxOnEscapePressed(self, f.data) else f:Hide() end
        end)
        edit:Show()
        y = y + 22 + 12
    else
        edit:Hide()
    end

    local labels = {}
    for i = 1, 3 do
        local label = def["button" .. i]
        if label then labels[#labels + 1] = { i = i, text = label } end
    end
    local total = #labels * BUTTON_W + (#labels - 1) * 8
    local x = -total / 2
    for i = 1, 3 do f.buttons[i]:Hide() end
    for _, l in ipairs(labels) do
        local b = f.buttons[l.i]
        b:SetText(l.text)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f, "TOP", x, -y)
        b:Show()
        x = x + BUTTON_W + 8
    end
    y = y + BUTTON_H + PAD
    f:SetHeight(y)
    f:Show()
    if def.OnShow then pcall(def.OnShow, f, data) end
    return f
end


function D:Click(index)
    local f = frame
    if not (f and f.def) then return end
    local def, data = f.def, f.data
    local fn = (index == 1 and def.OnAccept) or (index == 2 and def.OnCancel) or (index == 3 and def.OnAlt)
    local keep = false
    local serial = self.serial
    
    
    
    f.handled = true
    if fn then
        local ok, res = pcall(fn, f, data, index == 2 and "clicked" or nil)
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("DIALOG", "%s button %d failed: %s", tostring(f.which), index, tostring(res))
        end
        keep = ok and res == true
    end
    
    
    
    if self.serial ~= serial then return end
    if keep then
        f.handled = false
    else
        f:Hide()
    end
end

function D:IsShown(which)
    return frame and frame:IsShown() and (which == nil or frame.which == which) or false
end

function D:Hide()
    if frame and frame:IsShown() then frame:Hide() end
end

D.Frame = function() return frame end
