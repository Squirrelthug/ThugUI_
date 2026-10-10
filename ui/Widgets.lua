




















ThugUI = ThugUI or {}

local W = {}
ThugUI.Widgets = W



local function Paint(obj, role, how) return ThugUI.Theme:Paint(obj, role, how) end
W.Paint = Paint




local sliderSerial = 0
local function NextSliderName()
    sliderSerial = sliderSerial + 1
    return "ThugUI_Slider" .. sliderSerial
end

local FONT_HEADER  = ThugUI.Theme:Font("GameFontNormalLarge")
local FONT_SECTION = ThugUI.Theme:Font("GameFontNormal")
local FONT_LABEL   = ThugUI.Theme:Font("GameFontHighlight")
local FONT_NOTE    = ThugUI.Theme:Font("GameFontDisable")



local function ApplyDarkBorder(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Paint(bg, "controlFill", "fill")
    
    local t = frame:CreateTexture(nil, "BORDER")
    Paint(t, "controlBorder", "fill")
    t:SetPoint("TOPLEFT", 0, 0)
    t:SetPoint("TOPRIGHT", 0, 0)
    t:SetHeight(1)
    
    local b = frame:CreateTexture(nil, "BORDER")
    Paint(b, "controlBorder", "fill")
    b:SetPoint("BOTTOMLEFT", 0, 0)
    b:SetPoint("BOTTOMRIGHT", 0, 0)
    b:SetHeight(1)
    
    local l = frame:CreateTexture(nil, "BORDER")
    Paint(l, "controlBorder", "fill")
    l:SetPoint("TOPLEFT", 0, -1)
    l:SetPoint("BOTTOMLEFT", 0, 1)
    l:SetWidth(1)
    
    local r = frame:CreateTexture(nil, "BORDER")
    Paint(r, "controlBorder", "fill")
    r:SetPoint("TOPRIGHT", 0, -1)
    r:SetPoint("BOTTOMRIGHT", 0, 1)
    r:SetWidth(1)
end


local TAB_HEIGHT = 22
local TAB_GAP = 4

function W.CreateTabButton(parent, text, kind)
    
    local role, selRole = "tab", "tabSelected"
    if kind == "subTab" then role, selRole = "subTab", "subTabSelected" end
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(TAB_HEIGHT)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Paint(bg, "tabFill", "fill")

    local sel = btn:CreateTexture(nil, "BORDER")
    sel:SetAllPoints()
    Paint(sel, "tabSelectedFill", "fill")
    sel:Hide()
    btn.selectedBG = sel

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    Paint(hl, "tabHighlight", "fill")

    local accent = btn:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT")
    accent:SetPoint("BOTTOMRIGHT")
    accent:SetHeight(2)
    Paint(accent, "tabAccent", "fill")
    accent:Hide()
    btn.accent = accent

    local label = Paint(btn:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), role)
    label:SetPoint("CENTER")
    label:SetText(text)
    btn.label = label
    btn.labelText = text
    btn:SetWidth((label:GetStringWidth() or 60) + 24)

    function btn:SetSelected(selected)
        self.selectedBG:SetShown(selected)
        self.accent:SetShown(selected)
        Paint(self.label, selected and selRole or role)
    end
    btn:SetSelected(false)
    return btn
end





























function W.AddColoredTooltipLine(text, r, g, b)
    if not text then return end
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return end

    if type(CreateColor) == "function" and type(GameTooltip_AddColoredLine) == "function" then
        local ok, color = pcall(CreateColor, r, g, b)
        if ok and color then
            GameTooltip_AddColoredLine(GameTooltip, text, color)
            return
        end
    end

    if type(GameTooltip.AddLine) == "function" then
        GameTooltip:AddLine(text, r, g, b, true)
    end
end

function W.AttachTooltip(frame, title, body)
    if not title and not body then return end
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if title then GameTooltip:SetText(title, 1, 1, 1) end
        if body then GameTooltip:AddLine(body, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end









local function ResolveOptions(options)
    if type(options) == "function" then return options() or {} end
    return options or {}
end

local function OptionText(options, value)
    for _, opt in ipairs(ResolveOptions(options)) do
        if opt.value == value then return opt.text end
    end
    return nil
end

local dropdownList
local dropdownCatcher
local listRows = {}
local listOffset = 0
local listData = {}
local listAnchor

local function UpdateList()
    if not dropdownList then return end
    local maxVisible = 12
    local numData = #listData
    local shownCount = math.min(maxVisible, numData)
    
    dropdownList:SetHeight(shownCount * 20 + 2)
    
    if listOffset < 0 then listOffset = 0 end
    if listOffset > numData - maxVisible then listOffset = numData - maxVisible end
    if listOffset < 0 then listOffset = 0 end
    
    for i = 1, maxVisible do
        local row = listRows[i]
        local dataIndex = i + listOffset
        if dataIndex <= numData then
            local data = listData[dataIndex]
            row:Show()
            row.text:SetText(data.text)
            if data.isTitle then
                Paint(row.text, "listTitle")
                row.text:SetPoint("LEFT", 8, 0)
                row.check:Hide()
                row.isTitle = true
            else
                Paint(row.text, "listItem")
                row.text:SetPoint("LEFT", 20, 0)
                row.check:SetShown(data.checked)
                row.isTitle = false
            end
            row.onClick = data.onClick
        else
            row:Hide()
        end
    end

    
    
    
    if not dropdownList.moreUp then
        local up = dropdownList:CreateTexture(nil, "OVERLAY")
        up:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        up:SetSize(14, 14)
        up:SetPoint("TOPRIGHT", -4, -3)
        local down = dropdownList:CreateTexture(nil, "OVERLAY")
        down:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
        down:SetSize(14, 14)
        down:SetPoint("BOTTOMRIGHT", -4, 3)
        Paint(up, "accent", "vertex")
        Paint(down, "accent", "vertex")
        dropdownList.moreUp, dropdownList.moreDown = up, down
    end
    dropdownList.moreUp:SetShown(listOffset > 0)
    dropdownList.moreDown:SetShown(listOffset + maxVisible < numData)
end
W.ListState = function() return listOffset, #listData, dropdownList end

function W.ShowList(anchor, rows, width)
    if not ThugUI.CombatClose:Allow("dropdown") then return end
    if dropdownList and dropdownList:IsShown() and listAnchor == anchor then
        W.HideList()
        return
    end

    if not dropdownList then
        dropdownCatcher = CreateFrame("Button", "ThugUI_DropdownCatcher", UIParent)
        dropdownCatcher:SetFrameStrata("FULLSCREEN")
        dropdownCatcher:SetAllPoints(UIParent)
        dropdownCatcher:RegisterForClicks("AnyUp")
        dropdownCatcher:SetScript("OnClick", function()
            W.HideList()
        end)
        
        dropdownList = CreateFrame("Frame", "ThugUI_DropdownList", UIParent)
        if ThugUI.CombatClose then
            ThugUI.CombatClose:Register("dropdown", function() return dropdownList and dropdownList:IsShown() end, function() W.HideList() end)
        end
        dropdownList:SetFrameStrata("FULLSCREEN_DIALOG")
        dropdownList:SetClampedToScreen(true)
        dropdownList:EnableMouse(true)
        
        ApplyDarkBorder(dropdownList)
        
        dropdownList:SetScript("OnMouseWheel", function(self, delta)
            if delta > 0 then
                listOffset = listOffset - 1
            else
                listOffset = listOffset + 1
            end
            UpdateList()
        end)
        
        for i = 1, 12 do
            local row = CreateFrame("Button", nil, dropdownList)
            row:SetHeight(20)
            row:SetPoint("TOPLEFT", 1, -1 - (i - 1) * 20)
            row:SetPoint("TOPRIGHT", -1, -1 - (i - 1) * 20)
            
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            Paint(hl, "controlHighlight", "fill")
            row:SetHighlightTexture(hl)
            
            local text = Paint(row:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlightSmall")), "listItem")
            text:SetPoint("LEFT", 20, 0)
            row.text = text
            
            local check = row:CreateTexture(nil, "ARTWORK")
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:SetSize(16, 16)
            check:SetPoint("LEFT", 2, 0)
            row.check = check
            
            row:SetScript("OnEnter", function(self)
                if self.isTitle then
                    self:GetHighlightTexture():Hide()
                else
                    self:GetHighlightTexture():Show()
                end
            end)
            
            row:SetScript("OnClick", function(self)
                if self.isTitle then return end
                if self.onClick then self.onClick() end
                W.HideList()
            end)
            
            listRows[i] = row
        end
    end
    
    listData = rows
    listOffset = 0
    listAnchor = anchor
    
    dropdownList:SetWidth(width)
    dropdownList:ClearAllPoints()
    dropdownList:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    
    UpdateList()
    
    dropdownList:Show()
    dropdownCatcher:Show()
end

function W.HideList()
    if dropdownList then dropdownList:Hide() end
    if dropdownCatcher then dropdownCatcher:Hide() end
    listAnchor = nil
end

function W.CreateDropdown(parent, width, options, get, set)
    local dd = CreateFrame("Button", nil, parent)
    dd:SetHeight(24)
    dd:SetWidth(width or 160)
    
    ApplyDarkBorder(dd)
    
    local text = Paint(dd:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlightSmall")), "value")
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -20, 0)
    text:SetJustifyH("LEFT")
    dd.text = text
    
    local arrow = dd:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    arrow:SetSize(16, 16)
    arrow:SetPoint("RIGHT", -4, 0)
    
    local hl = dd:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    Paint(hl, "controlHighlight", "fill")
    
    dd:HookScript("OnHide", function(self)
        if listAnchor == self then
            W.HideList()
        end
    end)
    
    dd:SetScript("OnClick", function(self)
        local resolvedOptions = ResolveOptions(options)
        local rows = {}
        for _, opt in ipairs(resolvedOptions) do
            table.insert(rows, {
                text = opt.text,
                checked = get() == opt.value,
                isTitle = false,
                onClick = function()
                    if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
                        if self.labelText then
                            ThugUI.Diagnostics:Breadcrumb("Dropdown: " .. self.labelText .. " = " .. opt.text)
                        else
                            ThugUI.Diagnostics:Breadcrumb("Dropdown: " .. opt.text)
                        end
                    end
                    set(opt.value)
                    self:Refresh()
                end
            })
        end
        W.ShowList(self, rows, self:GetWidth())
    end)

    
    function dd:Choose(value)
        set(value)
        self:Refresh()
    end

    function dd:Refresh()
        self.text:SetText(OptionText(options, get()) or "")
    end
    
    function dd:SetText(t)
        self.text:SetText(t)
    end
    function dd:GetText()
        return self.text:GetText()
    end
    
    dd:Refresh()
    return dd
end










local PANEL_BUTTON = "Interface\\Buttons\\UI-Panel-Button-"
local PANEL_BUTTON_COORDS = {
    Left = { 0, 0.09375, 0, 0.6875 },
    Middle = { 0.09375, 0.53125, 0, 0.6875 },
    Right = { 0.53125, 0.625, 0, 0.6875 },
}

function W.CreateStateButton(parent, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(22)
    for _, part in ipairs({ "Left", "Middle", "Right" }) do
        local t = b:CreateTexture(nil, "BACKGROUND")
        local c = PANEL_BUTTON_COORDS[part]
        t:SetTexCoord(c[1], c[2], c[3], c[4])
        b[part] = t
    end
    b.Left:SetSize(12, 22)
    b.Left:SetPoint("TOPLEFT")
    b.Left:SetPoint("BOTTOMLEFT")
    b.Right:SetSize(12, 22)
    b.Right:SetPoint("TOPRIGHT")
    b.Right:SetPoint("BOTTOMRIGHT")
    b.Middle:SetPoint("TOPLEFT", b.Left, "TOPRIGHT")
    b.Middle:SetPoint("BOTTOMRIGHT", b.Right, "BOTTOMLEFT")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    hl:SetBlendMode("ADD")
    hl:SetTexCoord(0, 0.625, 0, 0.6875)
    hl:SetAllPoints()
    local label = Paint(b:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "disabled")
    label:SetPoint("CENTER")
    label:SetText(text)
    b.label = label
    local w = label.GetStringWidth and label:GetStringWidth() or 0
    if type(w) ~= "number" or w <= 0 then w = #text * 7 end
    b:SetWidth(math.max(60, w + 28))

    local function PaintArt(self, pressed)
        local file = PANEL_BUTTON .. (self.active and "Up" or "Disabled")
        if pressed then file = PANEL_BUTTON .. (self.active and "Down" or "Disabled-Down") end
        for _, part in ipairs({ "Left", "Middle", "Right" }) do self[part]:SetTexture(file) end
        self.label:SetFontObject(self.active and ThugUI.Theme:Font("GameFontHighlight") or ThugUI.Theme:Font("GameFontDisable"))
        Paint(self.label, self.active and "label" or "disabled")
    end
    function b:SetActive(active)
        self.active = active and true or false
        PaintArt(self, false)
    end
    b:SetScript("OnMouseDown", function(self) PaintArt(self, true) end)
    b:SetScript("OnMouseUp", function(self) PaintArt(self, false) end)
    b:SetActive(false)
    return b
end





local colorEditor

function W.ShowColorEditor(anchor, r, g, b, onChange, title)
    if not ThugUI.CombatClose:Allow("colorEditor") then return end
    if not colorEditor then
        colorEditor = CreateFrame("Frame", "ThugUI_ColorEditor", UIParent)
        if ThugUI.CombatClose then
            ThugUI.CombatClose:Register("colorEditor", function() return colorEditor and colorEditor:IsShown() end, function() colorEditor:Hide() end)
        end
        colorEditor:SetFrameStrata("FULLSCREEN_DIALOG")
        colorEditor:SetSize(260, 190)
        ApplyDarkBorder(colorEditor)
        colorEditor:SetClampedToScreen(true)
        colorEditor:EnableMouse(true)
        colorEditor:SetMovable(true)
        colorEditor:RegisterForDrag("LeftButton")
        colorEditor:SetScript("OnDragStart", function(self) self:StartMoving() end)
        colorEditor:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        local titleText = Paint(colorEditor:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlight")), "label")
        titleText:SetPoint("TOP", 0, -10)
        colorEditor.title = titleText
        
        local preview = colorEditor:CreateTexture(nil, "ARTWORK")
        preview:SetSize(40, 40)
        preview:SetPoint("TOPLEFT", 15, -35)
        preview:SetColorTexture(1, 1, 1) 
        colorEditor.preview = preview
        
        local previewBorder = colorEditor:CreateTexture(nil, "BACKGROUND")
        previewBorder:SetPoint("TOPLEFT", preview, "TOPLEFT", -1, 1)
        previewBorder:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", 1, -1)
        Paint(previewBorder, "swatchBorder", "fill")

        local function CreateEditorSlider(name, labelText, yOff)
            local slider = CreateFrame("Slider", name, colorEditor, "OptionsSliderTemplate")
            slider:SetSize(130, 16)
            slider:SetPoint("TOPLEFT", 90, yOff)
            slider:SetMinMaxValues(0, 1)
            slider:SetValueStep(0.01)
            slider:SetObeyStepOnDrag(true)
            
            
            local low, high, label = _G[name .. "Low"], _G[name .. "High"], _G[name .. "Text"]
            if low then low:Hide() end
            if high then high:Hide() end
            if label then
                label:SetText(labelText)
                label:ClearAllPoints()
                label:SetPoint("RIGHT", slider, "LEFT", -5, 0)
            end
            return slider
        end

        local sliderR = CreateEditorSlider("ThugUI_ColorEditor_R", "R", -35)
        local sliderG = CreateEditorSlider("ThugUI_ColorEditor_G", "G", -55)
        local sliderB = CreateEditorSlider("ThugUI_ColorEditor_B", "B", -75)
        
        colorEditor.sliders = {r = sliderR, g = sliderG, b = sliderB}
        
        local function UpdateFromSliders()
            if colorEditor.isUpdating then return end
            local nr = sliderR:GetValue()
            local ng = sliderG:GetValue()
            local nb = sliderB:GetValue()
            preview:SetVertexColor(nr, ng, nb) 
            if colorEditor.onChange then
                colorEditor.onChange(nr, ng, nb)
            end
        end
        
        sliderR:SetScript("OnValueChanged", UpdateFromSliders)
        sliderG:SetScript("OnValueChanged", UpdateFromSliders)
        sliderB:SetScript("OnValueChanged", UpdateFromSliders)
        
        
        local presets = {
            {1, 1, 1},       
            {0.5, 0.5, 0.5}, 
            {1, 0, 0},       
            {1, 0.5, 0},     
            {1, 0.82, 0},    
            {0, 1, 0},       
            {0, 1, 1},       
            {0, 0, 1}        
        }
        
        
        if ThugUI.GetClassColor then
            local cr, cg, cb = ThugUI:GetClassColor()
            if type(cr) == "number" then
                table.insert(presets, { cr, cg, cb })
            end
        end
        
        for i, color in ipairs(presets) do
            local btn = CreateFrame("Button", nil, colorEditor)
            btn:SetSize(16, 16)
            btn:SetPoint("TOPLEFT", 15 + ((i-1) * 22), -115)
            
            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetColorTexture(color[1], color[2], color[3]) 
            
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetPoint("TOPLEFT", -1, 1)
            bg:SetPoint("BOTTOMRIGHT", 1, -1)
            Paint(bg, "swatchBorder", "fill")
            
            btn:SetScript("OnClick", function()
                colorEditor.isUpdating = true
                sliderR:SetValue(color[1])
                sliderG:SetValue(color[2])
                sliderB:SetValue(color[3])
                colorEditor.isUpdating = false
                UpdateFromSliders()
            end)
        end
        
        local btnDone = CreateFrame("Button", nil, colorEditor, "UIPanelButtonTemplate")
        btnDone:SetSize(80, 24)
        btnDone:SetPoint("BOTTOMRIGHT", -10, 10)
        btnDone:SetText("Done")
        btnDone:SetScript("OnClick", function()
            colorEditor:Hide()
        end)
        
        local btnCancel = CreateFrame("Button", nil, colorEditor, "UIPanelButtonTemplate")
        btnCancel:SetSize(80, 24)
        btnCancel:SetPoint("RIGHT", btnDone, "LEFT", -10, 0)
        btnCancel:SetText("Cancel")
        btnCancel:SetScript("OnClick", function()
            if colorEditor.onChange then
                colorEditor.onChange(colorEditor.originalR, colorEditor.originalG, colorEditor.originalB)
            end
            colorEditor:Hide()
        end)
    end
    
    if colorEditor:IsShown() and colorEditor.anchor == anchor then
        colorEditor:Hide()
        return
    end
    
    colorEditor.anchor = anchor
    colorEditor.onChange = onChange
    colorEditor.originalR = r or 1
    colorEditor.originalG = g or 1
    colorEditor.originalB = b or 1
    
    colorEditor.isUpdating = true
    colorEditor.sliders.r:SetValue(colorEditor.originalR)
    colorEditor.sliders.g:SetValue(colorEditor.originalG)
    colorEditor.sliders.b:SetValue(colorEditor.originalB)
    colorEditor.preview:SetVertexColor(colorEditor.originalR, colorEditor.originalG, colorEditor.originalB) 
    colorEditor.title:SetText(title or "Colour")
    colorEditor.isUpdating = false
    
    colorEditor:ClearAllPoints()
    colorEditor:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
    colorEditor:Show()
end

function W.CreateColorSwatch(parent, get, set)
    local button = CreateFrame("Button", nil, parent)
    button.isColorSwatch = true  
    button:SetSize(18, 18)

    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    Paint(border, "swatchBorder", "fill")

    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetAllPoints()
    swatch:SetColorTexture(1, 1, 1) 

    function button:Refresh()
        local r, g, b = get()
        swatch:SetVertexColor(r or 1, g or 1, b or 1) 
    end

    button:SetScript("OnClick", function(self)
        local r, g, b = get()
        r, g, b = r or 1, g or 1, b or 1
        W.ShowColorEditor(button, r, g, b, function(nr, ng, nb)
            if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
                ThugUI.Diagnostics:Breadcrumb("Color: " .. (button.labelText or "(unlabelled)"))
            end
            set(nr, ng, nb)
            self:Refresh()
        end, button.labelText)
    end)

    button:Refresh()
    return button
end






function W.CreateScrollArea(parent, insetRight)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -(insetRight or 28), 4)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    return scroll, content
end





local Panel = {}
Panel.__index = Panel



local LABEL_WIDTH = 180
W.LABEL_WIDTH = LABEL_WIDTH





local GRID_MIN_WIDTH = 500
W.GRID_MIN_WIDTH = GRID_MIN_WIDTH

function Panel:IsGrid()
    return self.width >= GRID_MIN_WIDTH
end





function Panel:RowLabel(text, o, height)
    if not self:IsGrid() then
        self:Label(text, { indent = o.indent, sameLine = o.sameLine, yAdjust = o.yAdjust })
        return nil
    end
    local lbl = Paint(self.parent:CreateFontString(nil, "OVERLAY", FONT_LABEL), self:TextRole())
    lbl:SetWidth(LABEL_WIDTH)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(text)
    self:Place(lbl, height, { indent = o.indent, sameLine = o.sameLine, width = LABEL_WIDTH })
    return 0
end



function W.NewPanel(parent, opts)
    opts = opts or {}
    local panel = setmetatable({
        parent  = parent,
        originX = opts.x or 16,
        originY = -(opts.y or 14),
        width   = opts.width or (parent:GetWidth() - 32),
        cursorY = -(opts.y or 14),
        rowTopY = -(opts.y or 14),
        lastX   = opts.x or 16,
        lastW   = 0,
        widgets = {},
        
        
        
        
        searchIndex = {},
        currentSection = nil,
    }, Panel)

    
    
    
    
    
    
    
    
    parent.__thugPanels = parent.__thugPanels or {}
    table.insert(parent.__thugPanels, panel)

    return panel
end










function Panel:ActiveIf(fn)
    self.activeIf = fn
    if fn and not self.gated then self.gated = {} end
end

function Panel:ApplyGates()
    for _, g in ipairs(self.gated or {}) do
        local on = g.fn() and true or false
        local f = g.frame
        f:SetAlpha(on and 1 or 0.35)
        if f.SetEnabled then f:SetEnabled(on)
        elseif f.EnableMouse and f.GetObjectType and f:GetObjectType() ~= "FontString" then f:EnableMouse(on) end
        if f.valueBox and f.valueBox.SetEnabled then f.valueBox:SetEnabled(on) end
    end
end



function Panel:TextRole()
    if self.currentPartRole then return "label:" .. self.currentPartRole end
    return "label"
end

function Panel:Place(frame, height, o)
    o = o or {}
    if self.activeIf then
        self.gated[#self.gated + 1] = { frame = frame, fn = self.activeIf }
    end
    local indent = o.indent or 0

    if o.sameLine then
        self.openCheckboxPair = false
        local x = self.lastX + self.lastW + (o.gap or 12)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.parent, "TOPLEFT", x, self.rowTopY + (o.yAdjust or 0))
        self.lastX = x
        self.lastW = o.width or frame:GetWidth() or 0
        
        local bottom = self.rowTopY - height
        if bottom < self.cursorY then self.cursorY = bottom end
    elseif o.isCheckboxPair and self.openCheckboxPair then
        
        
        
        local colWidth = math.floor(self.width / 2)
        local x = self.originX + colWidth
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.parent, "TOPLEFT", x, self.rowTopY + (o.yAdjust or 0))
        self.lastX = x
        self.lastW = o.width or frame:GetWidth() or 0
        local bottom = self.rowTopY - height
        if bottom < self.cursorY then self.cursorY = bottom end
        self.openCheckboxPair = false
    else
        self.cursorY = self.cursorY - (o.gap or 6)
        self.rowTopY = self.cursorY
        local x = self.originX + indent
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.parent, "TOPLEFT", x, self.cursorY + (o.yAdjust or 0))
        self.lastX = x
        self.lastW = o.width or frame:GetWidth() or 0
        self.cursorY = self.cursorY - height
        
        if o.isCheckboxPair then
            self.openCheckboxPair = true
        else
            self.openCheckboxPair = false
        end
    end

    return frame
end

function Panel:Register(widget)
    if widget and widget.Refresh then
        table.insert(self.widgets, widget)
    end
    return widget
end

function Panel:Refresh()
    for _, widget in ipairs(self.widgets) do
        widget:Refresh()
    end
    self:ApplyGates()
end

function Panel:GetHeight()
    return math.abs(self.cursorY) + 20
end

function Panel:Gap(px)
    self.openCheckboxPair = false
    self.cursorY = self.cursorY - (px or 10)
    self.rowTopY = self.cursorY
    return self
end










function Panel:Index(text, frame, kind)
    if type(text) ~= "string" or text == "" then return end
    table.insert(self.searchIndex, {
        text = text,
        frame = frame,
        
        
        section = kind ~= "section" and self.currentSection or nil,
        kind = kind,
        
        
        tab = self.currentTab,
        subTab = self.currentSubTab,
    })
end

function Panel:Header(text)
    local fs = Paint(self.parent:CreateFontString(nil, "ARTWORK", FONT_HEADER), "pageTitle")
    fs:SetText(text)
    self:Place(fs, 22, { gap = 0 })
    self:Index(text, fs, "section")
    return fs
end






function Panel:Section(text)
    if self.FinalizeSubTabs then self:FinalizeSubTabs() end
    self.currentPartRole = nil
    if self.tabHandler then
        local tab = self.tabHandler(self, text)
        self:Index(text, tab.button, "section")
        self.currentSection = text
        self.inTabbedFrameSection = false
        return tab.button.label
    end
    self:Gap(12)
    local fs = Paint(self.parent:CreateFontString(nil, "ARTWORK", FONT_SECTION), "section")
    fs:SetText(text)
    self:Place(fs, 16, { gap = 0 })
    self:Index(text, fs, "section")
    self.currentSection = text

    
    
    
    local line = self.parent:CreateTexture(nil, "ARTWORK")
    Paint(line, "ruleSection", "fill")
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    line:SetWidth(math.max(1, self.width - fs:GetStringWidth() - 6))

    self:Gap(4)
    return fs
end


function Panel:Note(text, o)
    o = o or {}
    local fs = Paint(self.parent:CreateFontString(nil, "ARTWORK", FONT_NOTE), "note")
    fs:SetWidth(o.width or (self.width - (o.indent or 0)))
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    self:Place(fs, fs:GetStringHeight() + 4, o)
    return fs
end

function Panel:Label(text, o)
    local fs = Paint(self.parent:CreateFontString(nil, "ARTWORK", FONT_LABEL), self:TextRole())
    fs:SetText(text)
    self:Place(fs, 16, o)
    return fs
end




function Panel:Checkbox(opts)
    local cb = CreateFrame("CheckButton", nil, self.parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)

    local label = Paint(cb:CreateFontString(nil, "OVERLAY", FONT_LABEL), self:TextRole())
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(opts.label)
    
    
    
    cb.labelText = opts.label
    cb.get = opts.get
    cb.set = opts.set

    cb:SetScript("OnClick", function(self)
        if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
            ThugUI.Diagnostics:Breadcrumb("Checkbox: " .. (opts.label or "(unlabelled)"))
        end
        opts.set(self:GetChecked() and true or false)
    end)

    function cb:Refresh()
        self:SetChecked(opts.get() and true or false)
    end
    cb:Refresh()

    W.AttachTooltip(cb, opts.label, opts.tooltip)
    self:Index(opts.label, cb, "control")
    
    local cbWidth = 28 + label:GetStringWidth()
    local colWidth = math.floor(self.width / 2)
    local isCheckboxPair = self:IsGrid() and (not opts.sameLine) and (not opts.indent) and (not opts.fullRow) and (cbWidth <= colWidth)

    self:Place(cb, 26, {
        indent = opts.indent,
        sameLine = opts.sameLine,
        width = cbWidth,
        isCheckboxPair = isCheckboxPair
    })
    return self:Register(cb)
end


function Panel:Slider(opts)
    local name = NextSliderName()
    local slider = CreateFrame("Slider", name, self.parent, "OptionsSliderTemplate")
    slider:SetWidth(opts.width or 160)
    slider:SetMinMaxValues(opts.min, opts.max)
    slider:SetValueStep(opts.step)
    slider:SetObeyStepOnDrag(true)

    local fmt = opts.format or "%.2f"
    local low, high = _G[name .. "Low"], _G[name .. "High"]
    if low then low:SetText(string.format(fmt, opts.min)) end
    if high then high:SetText(string.format(fmt, opts.max)) end
    
    
    
    if _G[name .. "Text"] then _G[name .. "Text"]:SetText("") end
    
    slider.labelText = opts.label
    slider.get = opts.get
    slider.set = opts.set

    
    
    local valueBox = CreateFrame("EditBox", nil, slider, "InputBoxTemplate")
    valueBox:SetSize(56, 22)
    valueBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueBox:SetAutoFocus(false)
    slider.valueBox = valueBox
    
    
    
    
    local updating = false

    valueBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        local v = tonumber(text)
        if not v then
            self:SetText(string.format(fmt, slider:GetValue()))
        else
            if v < opts.min then v = opts.min end
            if v > opts.max then v = opts.max end
            local steps = math.floor(v / opts.step + 0.5)
            local snapped = steps * opts.step
            self:ClearFocus()
            slider:SetValue(snapped)
            
            
            self:SetText(string.format(fmt, slider:GetValue()))
        end
    end)
    valueBox:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format(fmt, slider:GetValue()))
        self:ClearFocus()
    end)
    valueBox:SetScript("OnEditFocusLost", function(self)
        self:SetText(string.format(fmt, slider:GetValue()))
    end)

    slider:SetScript("OnValueChanged", function(self, raw)
        local steps = math.floor(raw / opts.step + 0.5)
        local snapped = steps * opts.step
        valueBox:SetText(string.format(fmt, snapped))
        if not updating then
            if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
                ThugUI.Diagnostics:Breadcrumb("Slider: " .. (opts.label or "(unlabelled)"))
            end
            opts.set(snapped)
        end
    end)

    function slider:Refresh()
        updating = true
        local v = opts.get() or opts.min
        self:SetValue(v)
        valueBox:SetText(string.format(fmt, v))
        updating = false
    end
    slider:Refresh()

    W.AttachTooltip(slider, opts.label, opts.tooltip)
    self:Index(opts.label, slider, "control")
    
    if opts.sameLine or not self:IsGrid() then
        if _G[name .. "Text"] then _G[name .. "Text"]:SetText(opts.label) end
        self:Place(slider, 42, {
            indent = opts.indent,
            sameLine = opts.sameLine,
            yAdjust = -14,
            width = (opts.width or 160) + 72,
        })
    else
        
        
        local rowLabel = Paint(self.parent:CreateFontString(nil, "OVERLAY", FONT_LABEL), self:TextRole())
        rowLabel:SetWidth(LABEL_WIDTH)
        rowLabel:SetJustifyH("LEFT")
        rowLabel:SetText(opts.label)
        
        self:Place(rowLabel, 32, { indent = opts.indent, width = LABEL_WIDTH })
        self:Place(slider, 32, { sameLine = true, gap = 0, yAdjust = -4, width = (opts.width or 160) + 72 })
    end
    
    return self:Register(slider)
end


function Panel:Dropdown(opts)
    if opts.label then
        local gap = self:RowLabel(opts.label, { indent = opts.indent, sameLine = opts.sameLine, yAdjust = -6 }, 26)
        opts = setmetatable({ sameLine = true, gap = gap }, { __index = opts })
    end

    local dd = W.CreateDropdown(self.parent, opts.width or 160, opts.options, opts.get, opts.set)
    dd.labelText = opts.label
    self:Index(opts.label, dd, "control")
    self:Place(dd, 26, {
        indent = opts.indent,
        sameLine = opts.sameLine,
        gap = opts.gap,
        yAdjust = opts.yAdjust,
        width = opts.width or 160,
    })
    return self:Register(dd)
end






local MODIFIER_KEYS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true }
W.MODIFIER_KEYS = MODIFIER_KEYS

function W.BindingFromKey(key)
    local prefix = ""
    if IsAltKeyDown and IsAltKeyDown() then prefix = prefix .. "ALT-" end
    if IsControlKeyDown and IsControlKeyDown() then prefix = prefix .. "CTRL-" end
    if IsShiftKeyDown and IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
    return prefix .. key
end

function Panel:KeyBind(opts)
    if opts.label then
        local gap = self:RowLabel(opts.label, { indent = opts.indent, yAdjust = -6 }, 26)
        opts = setmetatable({ sameLine = true, gap = gap }, { __index = opts })
    end
    local width = opts.width or 160
    local btn = CreateFrame("Button", nil, self.parent)
    btn:SetSize(width, 24)
    ApplyDarkBorder(btn)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    Paint(hl, "controlHighlight", "fill")
    local text = Paint(btn:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlightSmall")), "value")
    text:SetPoint("CENTER")
    btn.text = text
    btn.labelText = opts.label
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    function btn:Refresh()
        if self.listening then
            self.text:SetText("Press a key...")
        else
            local k = opts.get()
            self.text:SetText((type(k) == "string" and k ~= "") and k or "Not set")
        end
    end
    local function Stop(self)
        self.listening = false
        self:EnableKeyboard(false)
        self:Refresh()
    end
    btn:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            Stop(self)
            opts.set(nil)
            self:Refresh()
            return
        end
        self.listening = true
        self:EnableKeyboard(true)
        self:Refresh()
    end)
    btn:SetScript("OnKeyDown", function(self, key)
        if not self.listening then return end
        if key == "ESCAPE" then Stop(self) return end
        if MODIFIER_KEYS[key] then return end
        local binding = W.BindingFromKey(key)
        Stop(self)
        opts.set(binding)
        self:Refresh()
    end)
    btn:SetScript("OnHide", function(self) if self.listening then Stop(self) end end)
    W.AttachTooltip(btn, opts.label, (opts.tooltip and (opts.tooltip .. " ") or "")
        .. "Click, then press the key. Right-click clears it.")
    self:Index(opts.label, btn, "control")
    self:Place(btn, 26, { indent = opts.indent, sameLine = opts.sameLine, gap = opts.gap, width = width })
    btn:Refresh()
    return self:Register(btn)
end


function Panel:Button(opts)
    local btn = CreateFrame("Button", nil, self.parent, "UIPanelButtonTemplate")
    btn:SetSize(opts.width or 150, opts.height or 24)
    btn:SetText(opts.label)
    btn:SetScript("OnClick", function(self)
        if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
            ThugUI.Diagnostics:Breadcrumb("Button: " .. (opts.label or "(unlabelled)"))
        end
        opts.onClick(self)
    end)
    W.AttachTooltip(btn, opts.label, opts.tooltip)
    self:Index(opts.label, btn, "control")

    self:Place(btn, (opts.height or 24) + 4, {
        indent = opts.indent,
        sameLine = opts.sameLine,
        width = opts.width or 150,
    })
    return btn
end


function Panel:Color(opts)
    if opts.label then
        local gap = self:RowLabel(opts.label, { indent = opts.indent, sameLine = opts.sameLine }, 22)
        opts = setmetatable({ sameLine = true, gap = gap }, { __index = opts })
    end

    local swatch = W.CreateColorSwatch(self.parent, opts.get, opts.set)
    swatch.labelText = opts.label
    self:Index(opts.label, swatch, "control")
    self:Place(swatch, 22, { indent = opts.indent, sameLine = opts.sameLine, gap = opts.gap, width = 18 })
    return self:Register(swatch)
end


function Panel:EditBox(opts)
    if opts.label then
        local gap = self:RowLabel(opts.label, { indent = opts.indent, sameLine = opts.sameLine }, 26)
        opts = setmetatable({ sameLine = true, gap = gap }, { __index = opts })
    end

    local box = CreateFrame("EditBox", nil, self.parent, "InputBoxTemplate")
    box:SetSize(opts.width or 160, 22)
    box:SetAutoFocus(false)
    box:SetNumeric(opts.numeric and true or false)

    box:SetScript("OnEnterPressed", function(self)
        if opts.set then
            if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
                ThugUI.Diagnostics:Breadcrumb("EditBox: " .. (opts.label or "(unlabelled)"))
            end
            opts.set(self:GetText())
        end
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if self.Refresh then self:Refresh() end
    end)
    if opts.onTextChanged then
        box:SetScript("OnTextChanged", function(self, userInput)
            if userInput then opts.onTextChanged(self:GetText()) end
        end)
    end

    function box:Refresh()
        if opts.get then self:SetText(opts.get() or "") end
    end
    box:Refresh()

    self:Index(opts.label, box, "control")
    self:Place(box, 26, {
        indent = opts.indent,
        sameLine = opts.sameLine,
        gap = opts.gap,
        width = opts.width or 160,
    })
    return self:Register(box)
end




function Panel:TextArea(opts)
    if opts.label then self:Label(opts.label) end
    local width, height = opts.width or self.width - 20, opts.height or 90
    local holder = CreateFrame("Frame", nil, self.parent)
    holder:SetSize(width, height)
    ApplyDarkBorder(holder)
    local scroll = CreateFrame("ScrollFrame", nil, holder, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ThugUI.Theme:Font("ChatFontNormal"))
    edit:SetWidth(width - 36)
    edit:SetHeight(height)
    Paint(edit, "value")
    scroll:SetScrollChild(edit)
    holder.edit = edit
    holder.labelText = opts.label
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        if opts.readOnly then
            holder:Refresh()
            self:HighlightText()
        elseif opts.onTextChanged then
            opts.onTextChanged(self:GetText())
        end
    end)
    
    if opts.readOnly then
        edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    end
    holder:EnableMouse(true)
    holder:SetScript("OnMouseDown", function() edit:SetFocus() end)
    function holder:Refresh()
        if opts.get then self.edit:SetText(opts.get() or "") end
    end
    function holder:SetText(t) self.edit:SetText(t or "") end
    function holder:GetText() return self.edit:GetText() end
    holder:Refresh()
    if opts.tooltip then W.AttachTooltip(holder, opts.label, opts.tooltip) end
    self:Index(opts.label, holder, "control")
    self:Place(holder, height + 4, { width = width })
    return self:Register(holder)
end





function Panel:FrameSection(opts)
    if self.FinalizeSubTabs then self:FinalizeSubTabs() end
    
    
    if self.tabHandler then
        self.tabHandler(self, opts.title)
        self.inTabbedFrameSection = true
    end
    self.openCheckboxPair = false
    self:Gap(12)
    local band = self.parent:CreateTexture(nil, "BACKGROUND")
    Paint(band, "frameSectionFill", "fill")
    band:SetHeight(30)
    
    
    
    band:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.originX - 4, self.cursorY)
    band:SetWidth(self.width + 8)

    local title = Paint(self.parent:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontNormalLarge")), "section")
    title:SetText(opts.title)
    title:SetPoint("LEFT", band, "LEFT", 12, 0)
    
    
    
    
    local divider = self.parent:CreateTexture(nil, "ARTWORK")
    local atlasInfo = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Options_HorizontalDivider")
    if atlasInfo then
        divider:SetAtlas("Options_HorizontalDivider")
        divider:SetHeight(atlasInfo.height)
        Paint(divider, "frameSectionDivider", "vertex")
    else
        Paint(divider, "ruleFrameSection", "fill")
        divider:SetHeight(1)
    end
    divider:SetPoint("TOPLEFT", band, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT", 0, 0)

    self.currentSection = opts.title
    self:Index(opts.title, title, "section")
    
    local rightX = -12
    if opts.reset then
        local btn = CreateFrame("Button", nil, self.parent, "UIPanelButtonTemplate")
        btn:SetSize(70, 24)
        btn:SetText("Reset")
        btn:SetPoint("RIGHT", band, "RIGHT", rightX, 0)
        btn:SetScript("OnClick", function(self) opts.reset(self) end)
        btn.labelText = "Reset"
        btn.sectionTitle = opts.title
        W.AttachTooltip(btn, "Reset", opts.tooltip)
        self:Index("Reset", btn, "control")
        rightX = rightX - 70 - 12
    end
    if opts.unlock then
        local cb = CreateFrame("CheckButton", nil, self.parent, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        local lbl = Paint(cb:CreateFontString(nil, "OVERLAY", FONT_LABEL), "label")
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        lbl:SetText("Unlock")
        cb.labelText = "Unlock"
        cb.sectionTitle = opts.title
        W.AttachTooltip(cb, "Unlock", opts.tooltip)
        
        cb:SetScript("OnClick", function(self)
            opts.unlock.set(self:GetChecked() and true or false)
        end)
        function cb:Refresh()
            self:SetChecked(opts.unlock.get() and true or false)
        end
        cb:Refresh()
        
        local cbWidth = 28 + lbl:GetStringWidth()
        cb:SetPoint("RIGHT", band, "RIGHT", rightX - cbWidth + 24, 0)
        rightX = rightX - cbWidth - 12
        self:Register(cb)
        self:Index("Unlock", cb, "control")
    end
    if opts.enabled then
        local cb = CreateFrame("CheckButton", nil, self.parent, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        local lbl = Paint(cb:CreateFontString(nil, "OVERLAY", FONT_LABEL), "label")
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        lbl:SetText("Enabled")
        cb.labelText = "Enabled"
        cb.sectionTitle = opts.title
        
        cb:SetScript("OnClick", function(self)
            opts.enabled.set(self:GetChecked() and true or false)
        end)
        function cb:Refresh()
            self:SetChecked(opts.enabled.get() and true or false)
        end
        cb:Refresh()
        
        local cbWidth = 28 + lbl:GetStringWidth()
        cb:SetPoint("RIGHT", band, "RIGHT", rightX - cbWidth + 24, 0)
        self:Register(cb)
        self:Index("Enabled", cb, "control")
    end

    self.cursorY = self.cursorY - 30 - (atlasInfo and atlasInfo.height or 1) - 12
    self.rowTopY = self.cursorY
    self.partIndex = 0
    self.currentPartRole = nil
    return title
end




function Panel:Part(name)
    self.openCheckboxPair = false
    local parts = { ["Size & position"] = 1, ["Visibility"] = 2, ["Appearance"] = 3, ["Content"] = 4 }
    local pIdx = parts[name]
    if not pIdx then error("ThugUI: unknown Part name: " .. tostring(name)) end
    if not self.partIndex then error("ThugUI: Part called before FrameSection") end
    if pIdx <= self.partIndex then error("ThugUI: Part called out of order: " .. tostring(name)) end
    self.partIndex = pIdx

    
    
    
    self:Gap(18)
    
    
    
    local partRole = ThugUI.Theme.PART_ROLE[name]
    self.currentPartRole = partRole
    local fs = Paint(self.parent:CreateFontString(nil, "ARTWORK", FONT_SECTION), partRole)
    fs:SetText(name)
    self:Place(fs, 16, { gap = 0 })
    self:Index(name, fs, "control")
    self:Rule(fs, partRole, 0.5)
    self:Gap(4)
    return fs
end



function Panel:Rule(fs, role, alpha)
    local line = self.parent:CreateTexture(nil, "ARTWORK")
    Paint(line, role, "fill")
    if alpha then line:SetAlpha(alpha) end
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    line:SetWidth(math.max(1, self.width - (fs:GetStringWidth() or 0) - 6))
    return line
end




function Panel:Group(name)
    self.openCheckboxPair = false
    self:Gap(10)
    
    
    
    local groupRole = self.currentPartRole and ("group:" .. self.currentPartRole) or "group"
    local fs = Paint(self.parent:CreateFontString(nil, "ARTWORK", FONT_LABEL), groupRole)
    fs:SetText(name)
    self:Place(fs, 14, { gap = 0, indent = 4 })
    self:Index(name, fs, "control")
    if self.currentPartRole then self:Rule(fs, groupRole, 0.5) else self:Rule(fs, "ruleGroup") end
    self:Gap(2)
    return fs
end












local SUBTAB_ROW = 26   




function W.SelectSubTab(tabState, index)
    local subTabs = tabState.subTabs
    if not subTabs or not subTabs[index] then return end
    for i, st in ipairs(subTabs) do
        st.host:SetShown(i == index)
        st.button:SetSelected(i == index)
    end
    tabState.activeSubTab = index
    if tabState.pageDef then
        tabState.pageDef.subTabSelections = tabState.pageDef.subTabSelections or {}
        tabState.pageDef.subTabSelections[tabState.index] = index
    end
    
    
    if tabState.bodyHost then
        local h = subTabs[index].height or 0
        tabState.contentHeight = h
        tabState.bodyHost:SetHeight(math.max(h, tabState.bodyMinHeight or 0))
        if tabState.scroll and tabState.scroll.SetVerticalScroll then tabState.scroll:SetVerticalScroll(0) end
        return
    end
    local h = (tabState.subBodyTop or 0) + (subTabs[index].height or 0)
    tabState.contentHeight = h
    tabState.host:SetHeight(math.max(h, tabState.minHeight or 0))
end

function Panel:SubSection(title)
    
    
    
    
    if not self.partIndex then
        error("ThugUI: SubSection outside a FrameSection")
    end
    if not self.inTabbedFrameSection or not self.currentTab then
        local fs = self:Group(title)
        self.partIndex = 0
    self.currentPartRole = nil
        return fs
    end
    local tabState = self.currentTab

    if not tabState.subTabs then
        tabState.subTabs = {}
        tabState.subTabBarY = self.cursorY
        local bar = CreateFrame("Frame", nil, tabState.host)
        bar:SetSize(self.width, SUBTAB_ROW)
        bar:SetPoint("TOPLEFT", tabState.host, "TOPLEFT", self.originX, self.cursorY)
        tabState.subTabBar = bar
        local rule = tabState.host:CreateTexture(nil, "ARTWORK")
        Paint(rule, "ruleSubTabs", "fill")
        rule:SetHeight(1)
        tabState.subTabRule = rule
    else
        
        tabState.subTabs[#tabState.subTabs].height = self:GetHeight()
    end

    local body = CreateFrame("Frame", nil, tabState.host)
    body:SetWidth(self.originX * 2 + self.width)
    body:SetHeight(1)
    body:Hide()
    local subTab = { title = title, host = body, index = #tabState.subTabs + 1, group = tabState }
    tabState.subTabs[subTab.index] = subTab

    subTab.button = W.CreateTabButton(tabState.subTabBar, title, "subTab")
    subTab.button:SetScript("OnClick", function() W.SelectSubTab(tabState, subTab.index) end)

    
    self.parent = body
    self.cursorY, self.rowTopY = self.originY, self.originY
    self.lastX, self.lastW = self.originX, 0
    self.openCheckboxPair = false
    self.partIndex = 0
    self.currentPartRole = nil
    self.currentSubTab = subTab
    
    self:Index(title, subTab.button, "subtab")
    return subTab.button.label
end















function Panel:Switch(o)
    self.openCheckboxPair = false
    if o.label then self:Group(o.label) end
    local row = CreateFrame("Frame", nil, self.parent)
    row:SetSize(self.width, TAB_HEIGHT)
    self:Place(row, TAB_HEIGHT, { gap = 6 })
    local sw = { options = o.options, get = o.get, set = o.set, cases = {}, buttons = {}, row = row }
    local x = 0
    for _, opt in ipairs(o.options) do
        local btn = W.CreateTabButton(row, opt.text, "subTab")
        btn:SetPoint("TOPLEFT", row, "TOPLEFT", x, 0)
        x = x + btn:GetWidth() + 4
        btn.value = opt.value
        local panel = self
        btn:SetScript("OnClick", function()
            o.set(opt.value)
            panel:Refresh()
        end)
        self:Index(opt.text, btn, "control")
        sw.buttons[#sw.buttons + 1] = btn
    end
    
    function row:SetEnabled(on)
        for _, b in ipairs(sw.buttons) do if b.SetEnabled then b:SetEnabled(on) end end
    end
    function sw:Refresh()
        local v = self.get()
        for _, b in ipairs(self.buttons) do b:SetSelected(b.value == v) end
        for value, body in pairs(self.cases) do body:SetShown(value == v) end
    end
    
    sw.saved = { parent = self.parent, cursorY = self.cursorY - 6 }
    self.switchStack = self.switchStack or {}
    self.switchStack[#self.switchStack + 1] = sw
    self:Register(sw)
    return sw
end


function Panel:Case(value)
    local sw = self.switchStack and self.switchStack[#self.switchStack]
    if not sw then error("ThugUI: Case outside a Switch") end
    if sw.current then sw.current.height = -self.cursorY end
    local body = CreateFrame("Frame", nil, sw.saved.parent)
    body:SetWidth(self.originX * 2 + self.width)
    body:SetHeight(1)
    body:SetPoint("TOPLEFT", sw.saved.parent, "TOPLEFT", 0, sw.saved.cursorY)
    body:Hide()
    sw.cases[value] = body
    sw.current = body
    self.parent = body
    self.cursorY, self.rowTopY = 0, 0
    self.lastX, self.lastW = self.originX, 0
    self.openCheckboxPair = false
    return body
end


function Panel:EndSwitch()
    local sw = self.switchStack and table.remove(self.switchStack)
    if not sw then error("ThugUI: EndSwitch without a Switch") end
    if sw.current then sw.current.height = -self.cursorY end
    local tallest = 0
    for _, body in pairs(sw.cases) do
        local h = body.height or 0
        body:SetHeight(math.max(h, 1))
        if h > tallest then tallest = h end
    end
    self.parent = sw.saved.parent
    self.cursorY = sw.saved.cursorY - tallest
    self.rowTopY = self.cursorY
    self.lastX, self.lastW = self.originX, 0
    self.openCheckboxPair = false
    sw.current = nil
    sw:Refresh()
    return sw
end





function Panel:FinalizeSubTabs()
    local tabState = self.currentTab
    if not tabState or not tabState.subTabs or tabState.subTabsFinalized then return end
    tabState.subTabsFinalized = true
    tabState.subTabs[#tabState.subTabs].height = self:GetHeight()

    local x, row = 0, 0
    for _, st in ipairs(tabState.subTabs) do
        local w = st.button:GetWidth()
        if x > 0 and x + w > self.width then
            x, row = 0, row + 1
        end
        st.button:ClearAllPoints()
        st.button:SetPoint("TOPLEFT", tabState.subTabBar, "TOPLEFT", x, -(row * SUBTAB_ROW))
        x = x + w + 4
    end
    local barH = (row + 1) * SUBTAB_ROW
    tabState.subTabBar:SetHeight(barH)

    local ruleY = tabState.subTabBarY - barH
    tabState.subTabRule:SetPoint("TOPLEFT", tabState.host, "TOPLEFT", self.originX - 4, ruleY)
    tabState.subTabRule:SetWidth(self.width + 8)

    local bodyY = ruleY - 4
    for _, st in ipairs(tabState.subTabs) do
        st.host:ClearAllPoints()
        st.host:SetPoint("TOPLEFT", tabState.host, "TOPLEFT", 0, bodyY)
    end
    tabState.subBodyTop = -bodyY

    local saved = tabState.pageDef and tabState.pageDef.subTabSelections
        and tabState.pageDef.subTabSelections[tabState.index]
    W.SelectSubTab(tabState, (saved and tabState.subTabs[saved]) and saved or 1)

    self.currentSubTab = nil
    self.inTabbedFrameSection = false
end

return W
