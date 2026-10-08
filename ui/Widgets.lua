




















ThugUI = ThugUI or {}

local W = {}
ThugUI.Widgets = W




local sliderSerial = 0
local function NextSliderName()
    sliderSerial = sliderSerial + 1
    return "ThugUI_Slider" .. sliderSerial
end

local FONT_HEADER  = "GameFontNormalLarge"
local FONT_SECTION = "GameFontNormal"
local FONT_LABEL   = "GameFontHighlight"
local FONT_NOTE    = "GameFontDisable"

local GOLD = {1.0, 0.82, 0.0}


local function ApplyDarkBorder(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    
    local t = frame:CreateTexture(nil, "BORDER")
    t:SetColorTexture(0.3, 0.3, 0.3, 1)
    t:SetPoint("TOPLEFT", 0, 0)
    t:SetPoint("TOPRIGHT", 0, 0)
    t:SetHeight(1)
    
    local b = frame:CreateTexture(nil, "BORDER")
    b:SetColorTexture(0.3, 0.3, 0.3, 1)
    b:SetPoint("BOTTOMLEFT", 0, 0)
    b:SetPoint("BOTTOMRIGHT", 0, 0)
    b:SetHeight(1)
    
    local l = frame:CreateTexture(nil, "BORDER")
    l:SetColorTexture(0.3, 0.3, 0.3, 1)
    l:SetPoint("TOPLEFT", 0, -1)
    l:SetPoint("BOTTOMLEFT", 0, 1)
    l:SetWidth(1)
    
    local r = frame:CreateTexture(nil, "BORDER")
    r:SetColorTexture(0.3, 0.3, 0.3, 1)
    r:SetPoint("TOPRIGHT", 0, -1)
    r:SetPoint("BOTTOMRIGHT", 0, 1)
    r:SetWidth(1)
end

local TEAL = {0.0, 1.0, 0.8}





























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
                row.text:SetTextColor(unpack(GOLD))
                row.text:SetPoint("LEFT", 8, 0)
                row.check:Hide()
                row.isTitle = true
            else
                row.text:SetTextColor(1, 1, 1)
                row.text:SetPoint("LEFT", 20, 0)
                row.check:SetShown(data.checked)
                row.isTitle = false
            end
            row.onClick = data.onClick
        else
            row:Hide()
        end
    end
end

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
            hl:SetColorTexture(1, 1, 1, 0.1)
            row:SetHighlightTexture(hl)
            
            local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
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
    
    local text = dd:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
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
    hl:SetColorTexture(1, 1, 1, 0.1)
    
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
        
        local titleText = colorEditor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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
        previewBorder:SetColorTexture(0.5, 0.5, 0.5)

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
            bg:SetColorTexture(0.5, 0.5, 0.5)
            
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
    border:SetColorTexture(0.4, 0.4, 0.4)

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
    local lbl = self.parent:CreateFontString(nil, "OVERLAY", FONT_LABEL)
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






function Panel:Place(frame, height, o)
    o = o or {}
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
    })
end

function Panel:Header(text)
    local fs = self.parent:CreateFontString(nil, "ARTWORK", FONT_HEADER)
    fs:SetText(text)
    self:Place(fs, 22, { gap = 0 })
    self:Index(text, fs, "section")
    return fs
end






function Panel:Section(text)
    if self.tabHandler then
        local tab = self.tabHandler(self, text)
        self:Index(text, tab.button, "section")
        self.currentSection = text
        return tab.button.label
    end
    self:Gap(12)
    local fs = self.parent:CreateFontString(nil, "ARTWORK", FONT_SECTION)
    fs:SetText(text)
    fs:SetTextColor(unpack(GOLD))
    self:Place(fs, 16, { gap = 0 })
    self:Index(text, fs, "section")
    self.currentSection = text

    
    
    
    local line = self.parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    line:SetWidth(math.max(1, self.width - fs:GetStringWidth() - 6))

    self:Gap(4)
    return fs
end


function Panel:Note(text, o)
    o = o or {}
    local fs = self.parent:CreateFontString(nil, "ARTWORK", FONT_NOTE)
    fs:SetWidth(o.width or (self.width - (o.indent or 0)))
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    self:Place(fs, fs:GetStringHeight() + 4, o)
    return fs
end

function Panel:Label(text, o)
    local fs = self.parent:CreateFontString(nil, "ARTWORK", FONT_LABEL)
    fs:SetText(text)
    self:Place(fs, 16, o)
    return fs
end




function Panel:Checkbox(opts)
    local cb = CreateFrame("CheckButton", nil, self.parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)

    local label = cb:CreateFontString(nil, "OVERLAY", FONT_LABEL)
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
        
        
        local rowLabel = self.parent:CreateFontString(nil, "OVERLAY", FONT_LABEL)
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





function Panel:FrameSection(opts)
    
    
    if self.tabHandler then self.tabHandler(self, opts.title) end
    self.openCheckboxPair = false
    self:Gap(12)
    local band = self.parent:CreateTexture(nil, "BACKGROUND")
    band:SetColorTexture(1, 1, 1, 0.04)
    band:SetHeight(30)
    
    
    
    band:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.originX - 4, self.cursorY)
    band:SetWidth(self.width + 8)

    local title = self.parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(opts.title)
    title:SetTextColor(unpack(GOLD))
    title:SetPoint("LEFT", band, "LEFT", 12, 0)
    
    
    
    
    local divider = self.parent:CreateTexture(nil, "ARTWORK")
    local atlasInfo = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Options_HorizontalDivider")
    if atlasInfo then
        divider:SetAtlas("Options_HorizontalDivider")
        divider:SetHeight(atlasInfo.height)
    else
        divider:SetColorTexture(unpack(GOLD))
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
        local lbl = cb:CreateFontString(nil, "OVERLAY", FONT_LABEL)
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
        local lbl = cb:CreateFontString(nil, "OVERLAY", FONT_LABEL)
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
    local fs = self.parent:CreateFontString(nil, "ARTWORK", FONT_SECTION)
    fs:SetText(name)
    fs:SetTextColor(unpack(GOLD))
    self:Place(fs, 16, { gap = 0 })
    self:Index(name, fs, "control")
    self:Rule(fs, 0.85, 0.7, 0.2, 0.5)
    self:Gap(4)
    return fs
end



function Panel:Rule(fs, r, g, b, a)
    local line = self.parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(r, g, b, a)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    line:SetWidth(math.max(1, self.width - (fs:GetStringWidth() or 0) - 6))
    return line
end




function Panel:Group(name)
    self.openCheckboxPair = false
    self:Gap(10)
    local fs = self.parent:CreateFontString(nil, "ARTWORK", FONT_LABEL)
    fs:SetText(name)
    fs:SetTextColor(0.85, 0.85, 0.85)
    self:Place(fs, 14, { gap = 0, indent = 4 })
    self:Index(name, fs, "control")
    self:Rule(fs, 0.5, 0.5, 0.5, 0.35)
    self:Gap(2)
    return fs
end

return W
