







ThugUI = ThugUI or {}

local function PL() return ThugUI.PadLayout end
local Page = {}
ThugUI.PadLayoutPage = Page

local XBOX, PLAYSTATION = "xbox", "playstation"
local TABS = { "Face buttons", "L1 / R1 + right", "Both bumpers", "Menu buttons" }
Page.TABS = TABS
Page.FACE_LISTS = { macros = true, spells = true, thug = false, blizzard = true }

ThugUI.Dialogs = ThugUI.Dialogs or {}
ThugUI.Dialogs["THUGUI_PADLAYOUT_RESET"] = {
    text = "Put every Pad layout button back on Blizzard's default? This clears your choices for the buttons on this page.",
    button1 = "Put them back", button2 = "Cancel",
    OnAccept = function()
        if ThugUI.PadChooser then ThugUI.PadChooser:Close() end
        if ThugUI.PadLayout then ThugUI.PadLayout:ResetAll("page") end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function KindName(kind)
    if kind == XBOX then return "Xbox" end
    if kind == PLAYSTATION then return "PlayStation" end
    return "unknown"
end

local function Detected()
    local SR = ThugUI.StickReload
    if not (SR and SR.PadKind) then return nil end
    local ok, kind = pcall(SR.PadKind, SR)
    return ok and (kind == XBOX or kind == PLAYSTATION) and kind or nil
end

local function Playing()
    local bar = _G.GamepadMainActionBarFrame
    local unit = bar and bar.PageUnit
    if not (unit and unit.GetCurrentPage) then return nil end
    local ok, page = pcall(unit.GetCurrentPage, unit)
    return ok and type(page) == "number" and page or nil
end

local function FaceChoice(page, faceId)
    local FB = ThugUI.FaceButtons
    if not (FB and FB.FACES and FB.Get) then return nil end
    local face
    for _, entry in ipairs(FB.FACES) do if entry.id == faceId then face = entry end end
    if not face then return nil end
    local value = FB:Get(page, faceId)
    if not value then return face.default .. " (default)", true, face end
    local text = value
    local ok, rows = pcall(FB.Options, FB, page, face)
    if ok and type(rows) == "table" then
        for _, row in ipairs(rows) do if row.value == value then text = row.text end end
    end
    return text, false, face
end

local function Build(host, panel)
    local W, PS = ThugUI.Widgets, ThugUI.PadSilhouette
    local Paint, parent, width = W.Paint, panel.parent, panel.width
    local items = {}
    local activeTab, layout = Page.activeTab or 1, Page.layout or 1
    local pictures, selected = {}, nil

    local function Rec(frame, height, options, skip)
        items[#items + 1] = { frame = frame, height = height, options = options, skip = skip }
    end
    local function Note(text, skip)
        local fs = panel:Note(text)
        Rec(fs, function() return fs:GetStringHeight() + 4 end, nil, skip)
        return fs
    end
    local function Heading(text)
        local fs = panel:Label(text, { gap = 14 })
        panel:Index(text, fs, "section")
        Rec(fs, 16, { gap = 14 })
        return fs
    end
    local function Relayout()
        panel.cursorY, panel.rowTopY = panel.originY, panel.originY
        panel.lastX, panel.lastW, panel.openCheckboxPair = panel.originX, 0, false
        for _, item in ipairs(items) do
            if item.skip and item.skip() then
                item.frame:Hide()
            else
                item.frame:Show()
                local h = type(item.height) == "function" and item.height() or item.height
                panel:Place(item.frame, h, item.options)
            end
        end
        local floor = ThugUI.Window and ThugUI.Window.frame and ThugUI.Window.frame.content
        parent:SetHeight(math.max(panel:GetHeight(), floor and floor:GetHeight() or 0))
    end

    Note("This page only changes what Blizzard's own binding screen cannot. Your own bindings are respected.")

    
    local band = CreateFrame("Frame", nil, parent)
    band:SetSize(width, 1)
    band.fill = band:CreateTexture(nil, "BACKGROUND")
    band.fill:SetAllPoints(); Paint(band.fill, "warning", "fill"); band.fill:SetAlpha(0.15)
    band.edge = band:CreateTexture(nil, "BORDER")
    band.edge:SetPoint("TOPLEFT"); band.edge:SetPoint("BOTTOMLEFT"); band.edge:SetWidth(3); Paint(band.edge, "warning", "fill")
    band.heading = Paint(band:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "warning")
    band.heading:SetPoint("TOPLEFT", 12, -8)
    band.rows, band.active, band.h = {}, false, 0
    Rec(band, function() return band.h end, nil, function() return not band.active end)
    local BAND_ROW = 24
    local function BandRow(i)
        if band.rows[i] then return band.rows[i] end
        local row = {}
        row.text = Paint(band:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlight")), "label")
        row.text:SetPoint("TOPLEFT", 12, -(34 + (i - 1) * BAND_ROW)); row.text:SetWidth(width - 160); row.text:SetJustifyH("LEFT")
        row.button = CreateFrame("Button", nil, band, "UIPanelButtonTemplate")
        row.button:SetSize(110, 20); row.button:SetText("Put it back")
        row.button:SetPoint("TOPRIGHT", -10, -(32 + (i - 1) * BAND_ROW))
        row.button:SetScript("OnClick", function() if row.action and PL() then PL():Restore(row.action) end end)
        band.rows[i] = row
        return row
    end
    local movedNote = Note("", function() return not (Page.movedText and Page.movedText ~= "") end)

    Heading("My controller")
    local padButtons = {}
    for i, choice in ipairs({ { "", "Detected" }, { XBOX, "Xbox" }, { PLAYSTATION, "PlayStation" } }) do
        local b = W.CreateStateButton(parent, choice[2]); b.value = choice[1]
        b:SetScript("OnClick", function() if PL() then PL():SetPadOverride(b.value) end end)
        padButtons[#padButtons + 1] = b; Rec(b, 26, { sameLine = i > 1 })
    end
    local detected = Note("")

    
    local tabRow = CreateFrame("Frame", nil, parent); tabRow:SetSize(width, 26)
    local tabButtons = {}
    local cursor = 0
    for i, title in ipairs(TABS) do
        local b = W.CreateTabButton(tabRow, title, "subTab")
        b:SetPoint("TOPLEFT", tabRow, "TOPLEFT", cursor, 0)
        cursor = cursor + b:GetWidth() + 4
        tabButtons[i] = b
    end
    Rec(tabRow, 26, { gap = 12 })

    local layoutRow = CreateFrame("Frame", nil, parent); layoutRow:SetSize(width, 26)
    local layoutButtons = {}
    for i = 1, 3 do
        local b = W.CreateStateButton(layoutRow, "Layout " .. i .. " (playing)")
        b.label:SetText("Layout " .. i); b.page = i
        b:SetPoint("TOPLEFT", layoutRow, "TOPLEFT", (i - 1) * (b:GetWidth() + 4), 0)
        layoutButtons[i] = b
    end
    Rec(layoutRow, 26, nil, function() return activeTab ~= 1 end)
    local layoutNote = Note("The face buttons are set for each layout.", function() return activeTab ~= 1 end)

    local function PictureWrap(tab)
        local display = math.min(width, 640)
        local wrap = CreateFrame("Frame", nil, parent); wrap:SetSize(display, display / 2)
        local pic = PS:Build(wrap); pic:SetDisplayWidth(display); pic:SetPoint("TOPLEFT")
        pictures[tab] = { wrap = wrap, left = pic }
        Rec(wrap, display / 2, { width = display }, function() return activeTab ~= tab end)
    end
    PictureWrap(1)
    local half = (width - 16) / 2
    local two = CreateFrame("Frame", nil, parent); two:SetSize(width, 18 + half / 2)
    local leftLabel = Paint(two:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "label")
    leftLabel:SetPoint("TOPLEFT", 0, 0)
    local rightLabel = Paint(two:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "label")
    rightLabel:SetPoint("TOPLEFT", half + 16, 0)
    local left = PS:Build(two); left:SetDisplayWidth(half); left:SetPoint("TOPLEFT", 0, -18)
    local right = PS:Build(two); right:SetDisplayWidth(half); right:SetPoint("TOPLEFT", half + 16, -18)
    pictures[2] = { wrap = two, left = left, right = right, leftLabel = leftLabel, rightLabel = rightLabel }
    Rec(two, 18 + half / 2, { width = width }, function() return activeTab ~= 2 end)
    PictureWrap(3); PictureWrap(4)

    Heading("Selected button")
    local ro = CreateFrame("Frame", nil, parent); ro:SetSize(width, 132)
    ro.name = Paint(ro:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontNormal")), "section")
    ro.name:SetPoint("TOPLEFT", 0, 0)
    ro.icon = ro:CreateTexture(nil, "ARTWORK"); ro.icon:SetSize(22, 22); ro.icon:SetPoint("TOPLEFT", 0, -22); ro.icon:Hide()
    ro.choice = Paint(ro:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlight")), "label"); ro.choice:SetPoint("TOPLEFT", 28, -26)
    ro.default = Paint(ro:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontDisable")), "note"); ro.default:SetPoint("TOPLEFT", 0, -52)
    ro.off = Paint(ro:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontDisable")), "note"); ro.off:SetPoint("TOPLEFT", 0, -70)
    ro.twice = Paint(ro:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlight")), "label"); ro.twice:SetPoint("TOPLEFT", 0, -92)
    ro.twiceNote = Paint(ro:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontDisable")), "note"); ro.twiceNote:SetPoint("TOPLEFT", 0, -110)
    for _, fs in ipairs({ ro.name, ro.choice, ro.default, ro.off, ro.twice, ro.twiceNote }) do fs:SetJustifyH("LEFT"); fs:SetWidth(width - 150) end
    ro.change = CreateFrame("Button", nil, ro, "UIPanelButtonTemplate"); ro.change:SetSize(120, 24); ro.change:SetText("Change..."); ro.change:SetPoint("TOPRIGHT", 0, -22); ro.change:Disable()
    ro.twiceChange = CreateFrame("Button", nil, ro, "UIPanelButtonTemplate"); ro.twiceChange:SetSize(120, 24); ro.twiceChange:SetText("Change..."); ro.twiceChange:SetPoint("TOPRIGHT", 0, -88); ro.twiceChange:Disable(); ro.twiceChange:Hide()
    W.AttachTooltip(ro.change, "Change...", "Pick what this button does")
    Rec(ro, 132)
    local pendingNote = Note("Applies when combat ends", function() return not Page.pendingShown end)
    local reset = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    reset:SetSize(220, 24); reset:SetText("Back to Blizzard's defaults")
    reset:SetScript("OnClick", function() ThugUI.Dialog:Show("THUGUI_PADLAYOUT_RESET") end)
    W.AttachTooltip(reset, "Back to Blizzard's defaults", "Clears your choices for every button on this page")
    Rec(reset, 30, { gap = 12 })

    local function CurrentPic() return selected and selected.pic or nil end
    local function ChoiceText(slot)
        local desc = PL():Describe(slot)
        if desc.isDefault then
            local d = PL():DefaultOf(slot)
            return ((d and d.title) or "Nothing") .. " (default)", desc
        end
        return desc.label, desc
    end
    local function Target()
        if not selected then return nil end
        if activeTab == 1 then return { face = selected.slot, page = layout } end
        return { slot = selected.slot }
    end
    local function TwiceTarget()
        if not selected or activeTab ~= 4 then return nil end
        local twice = selected.slot == "start" and "starttwice" or selected.slot == "view" and "viewtwice" or nil
        return twice and { slot = twice } or nil
    end
    local function HoldTarget()
        if not selected or activeTab ~= 4 or selected.slot ~= "logo" then return nil end
        return { slot = "logohold" }
    end
    local function SameTarget(a, b)
        return a and b and a.slot == b.slot and a.face == b.face and a.page == b.page
    end
    local function UpdateReadout()
        ro.icon:Hide(); ro.choice:SetText(""); ro.default:SetText(""); ro.off:SetText(""); ro.twice:SetText(""); ro.twiceNote:SetText(""); ro.twiceChange:Hide(); ro.twiceChange:Disable()
        if not selected then ro.name:SetText("Click a coloured button on the picture to see what it does."); return end
        if activeTab == 1 then
            local text, _, face = FaceChoice(layout, selected.slot)
            ro.name:SetText(((face and face.title) or selected.slot) .. " (layout " .. layout .. ")")
            ro.choice:SetText(text or ""); ro.default:SetText("Blizzard's default here: " .. ((face and face.default) or "nothing"))
            return
        end
        local slot = selected.slot
        ro.name:SetText(PL():Label(slot))
        local text, desc = ChoiceText(slot); ro.choice:SetText(text)
        if desc.icon then ro.icon:SetTexture(desc.icon); ro.icon:Show() end
        local default = PL():DefaultOf(slot); ro.default:SetText("Blizzard's default here: " .. (default and default.title or "nothing"))
        local twice, hold = TwiceTarget(), HoldTarget()
        if twice then
            local allowed = PL():SingleIsWindow(slot)
            ro.twice:SetText("Twice: " .. PL():Describe(twice.slot).label)
            ro.twiceNote:SetText(allowed and "" or "Needs a window on the single press")
            ro.twiceChange:SetShown(true)
            if allowed then ro.twiceChange:Enable() else ro.twiceChange:Disable() end
        elseif hold then
            local allowed = PL():LogoSingleAllowed()
            local note = allowed and "" or "Needs a ThugUI action, macro or spell on the single press"
            if allowed and PL():Get(hold.slot) == "thug:hideui" and not PL().hideuiAvailable then
                note = "Toggle user interface: not available on this client"
            end
            ro.twice:SetText("Hold: " .. PL():Describe(hold.slot).label)
            ro.twiceNote:SetText(note)
            ro.twiceChange:SetShown(true)
            if allowed then ro.twiceChange:Enable() else ro.twiceChange:Disable() end
        end
        if slot == "cross" then
            local CS = ThugUI.ControllerShortcuts
            if CS and CS.BlizzardOwnsCross and CS:BlizzardOwnsCross() then ro.off:SetText("Blizzard uses this button on your build: your choice is off") end
        end
    end
    local function UpdateBand()
        local lost, moved = PL():Lost(), PL():MovedDefaults()
        local rows = {}
        for _, entry in ipairs(lost) do
            if entry.kind == "blizzard" then rows[#rows + 1] = { text = entry.title .. ": " .. PL():Label(entry.slot) .. " now runs " .. tostring(entry.by), action = entry.action }
            else rows[#rows + 1] = { text = "Your binding " .. entry.title .. " is covered by " .. tostring(entry.by) } end
        end
        local blizzard = false
        for _, entry in ipairs(lost) do if entry.kind == "blizzard" then blizzard = true end end
        band.heading:SetText(blizzard and "Blizzard defaults with no button" or "Your own bindings these cover")
        for i, entry in ipairs(rows) do
            local row = BandRow(i); row.action = entry.action; row.text:SetText(entry.text); row.text:Show(); row.button:SetShown(entry.action ~= nil)
        end
        for i = #rows + 1, #band.rows do band.rows[i].text:Hide(); band.rows[i].button:Hide() end
        band.active, band.h = #rows > 0, #rows > 0 and (34 + #rows * BAND_ROW + 8) or 0
        band:SetHeight(math.max(1, band.h))
        local lines = {}; for _, entry in ipairs(moved) do lines[#lines + 1] = entry.title .. " now on " .. PL():Label(entry.slot) end
        Page.movedText = table.concat(lines, "\n"); movedNote:SetText(Page.movedText)
        return lost
    end
    local function UpdatePictures(kind, lost)
        local function Update(pic)
            pic:SetKind(kind); pic:SetNeedsController(PL():Kind() == nil); pic:SetTab(activeTab, pic == pictures[2].right and "right" or "left")
            for part, slot in pairs(pic.editable) do
                local bad = false
                if activeTab ~= 1 then for _, entry in ipairs(lost) do if entry.slot == slot then bad = true end end end
                pic:SetBadge(part, bad)
                local caption, default
                if activeTab == 1 then
                    caption = FaceChoice(layout, slot)
                    local _, _, face = FaceChoice(layout, slot)
                    default = face and face.default or "nothing"
                    pic:SetTitle(part, ((face and face.title) or slot) .. " (layout " .. layout .. ")")
                else
                    caption = ChoiceText(slot)
                    local entry = PL():DefaultOf(slot)
                    default = entry and entry.title or "nothing"
                    pic:SetTitle(part, PL():Label(slot))
                end
                pic:SetCaption(part, caption)
                pic:SetTooltip(part, { caption, "Blizzard's default here: " .. default })
                pic:SetSelected(selected and selected.pic == pic and selected.part or nil)
            end
        end
        if activeTab == 2 then Update(pictures[2].left); Update(pictures[2].right) else Update(pictures[activeTab].left) end
    end
    local function Refresh()
        if not (PL() and Page.built) then return end
        local kind = PL():Kind() or PLAYSTATION
        for _, b in ipairs(padButtons) do b:SetActive(b.value == (ThugUIDB.PadLayout and ThugUIDB.PadLayout.padOverride or "")) end
        local det = Detected()
        detected:SetText(det and ("Detected: " .. KindName(det)) or "Not recognised: pick yours above.")
        for i, b in ipairs(tabButtons) do b:SetSelected(i == activeTab) end
        local playing = Playing()
        for i, b in ipairs(layoutButtons) do b.label:SetText("Layout " .. i .. (playing == i and " (playing)" or "")); b:SetActive(i == layout) end
        pictures[2].leftLabel:SetText(kind == XBOX and "Hold LB" or "Hold L1")
        pictures[2].rightLabel:SetText(kind == XBOX and "Hold RB" or "Hold R1")
        local lost = UpdateBand(); UpdatePictures(kind, lost); UpdateReadout()
        local target, twice, hold = Target(), TwiceTarget(), HoldTarget(); if target then ro.change:Enable() else ro.change:Disable() end
        local chooser = ThugUI.PadChooser
        if chooser and chooser:IsShown() and not SameTarget(chooser.target, target) and not SameTarget(chooser.target, twice) and not SameTarget(chooser.target, hold) then chooser:Close() end
        local FB = ThugUI.FaceButtons
        Page.pendingShown = (InCombatLockdown and InCombatLockdown() or false) and (PL().pending == true or (FB and FB.pending == true)) or false
        Relayout()
    end
    local function Select(pic, part, slot)
        selected = { pic = pic, part = part, slot = slot }
        for _, set in pairs(pictures) do
            if set.left and set.left ~= pic then set.left:SetSelected(nil) end
            if set.right and set.right ~= pic then set.right:SetSelected(nil) end
        end
        Refresh()
    end
    for _, set in pairs(pictures) do
        if set.left then set.left:OnSelect(function(part, slot) Select(set.left, part, slot) end) end
        if set.right then set.right:OnSelect(function(part, slot) Select(set.right, part, slot) end) end
        if set.left then set.left:OnDoubleClick(function(part, slot)
            Select(set.left, part, slot); if ThugUI.PadChooser then ThugUI.PadChooser:Open(Target()) end
        end) end
        if set.right then set.right:OnDoubleClick(function(part, slot)
            Select(set.right, part, slot); if ThugUI.PadChooser then ThugUI.PadChooser:Open(Target()) end
        end) end
    end
    for i, b in ipairs(tabButtons) do
        b:SetScript("OnClick", function() activeTab = i; selected = nil; Page.activeTab = activeTab; Refresh() end)
    end
    for _, b in ipairs(layoutButtons) do
        b:SetScript("OnClick", function() layout = b.page; Page.layout = layout; selected = nil; Refresh() end)
    end
    ro.change:SetScript("OnClick", function() local target = Target(); if target and ThugUI.PadChooser then ThugUI.PadChooser:Open(target) end end)
    ro.twiceChange:SetScript("OnClick", function()
        local target = TwiceTarget() or HoldTarget()
        if target and ThugUI.PadChooser then ThugUI.PadChooser:Open(target) end
    end)

    if not Page.hooked then
        Page.hooked = true
        local function Close() if ThugUI.PadChooser then ThugUI.PadChooser:Close() end end
        hooksecurefunc(ThugUI.Window, "SelectPage", function(_, id) if id ~= "padlayout" then Close() end end)
        hooksecurefunc(ThugUI.Window, "Close", Close); host:HookScript("OnHide", Close)
        local ev = CreateFrame("Frame"); ThugUI.SafeRegisterEvent(ev, "PLAYER_REGEN_ENABLED")
        ev:SetScript("OnEvent", function() if Page.Refresh then Page.Refresh() end end); Page.events = ev
    end
    Page.pic, Page.pictures, Page.band, Page.readout, Page.panel = pictures[1].left, pictures, band, ro, panel
    Page.tabButtons, Page.layoutButtons, Page.padButtons, Page.detected = tabButtons, layoutButtons, padButtons, detected
    Page.change, Page.twiceChange, Page.pendingNote, Page.movedNote, Page.reset, Page.Refresh, Page.Relayout = ro.change, ro.twiceChange, pendingNote, movedNote, reset, Refresh, Relayout
    Page.built = true
    if PL().RegisterCallback and not Page.registered then Page.registered = true; PL():RegisterCallback(function() if Page.Refresh then Page.Refresh() end end) end
    Refresh()
end

ThugUI.Window:RegisterPage{
    id = "padlayout", category = "controller", order = 15, scopeKeys = { "PadLayout", "FaceButtons" },
    title = "Pad layout", summary = "Four pictures of your controller's editable buttons.",
    build = function(host, panel) Build(host, panel) end,
    refresh = function() if Page.Refresh then Page.Refresh() end end,
}
