






























ThugUI = ThugUI or {}

local C = {}
ThugUI.PadChooser = C

local W_WIDTH, W_HEIGHT = 380, 346

local NOTE_H = 46
local TITLE_H, PIN_H, TAB_H = 28, 28, 26
local ROW_PLAIN, ROW_NOTE = 28, 42


local TABS = {
    { key = "macros",   word = "Macros" },
    { key = "spells",   word = "Spells" },
    { key = "thug",     word = "ThugUI" },
    { key = "blizzard", word = "Blizzard" },
}
C.TABS = TABS

local EMPTY = {
    macros = "No macros yet. Make one in the game's macro window.",
    other = "Nothing here yet for this button.",
}

local FACE_OFF = "Not on face buttons yet"

local function PL() return ThugUI.PadLayout end
local function FB() return ThugUI.FaceButtons end
local function Paint(obj, role, how) return ThugUI.Theme:Paint(obj, role, how) end

local function Log(fmt, ...)
    if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then ThugUI.Diagnostics:Log("PADLAYOUT", fmt, ...) end
end




local function IconOf(value)
    local fb = FB()
    local kind, what = fb and fb.Parse and fb.Parse(value)
    local ok, icon = pcall(function()
        if kind == "spell" then
            return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(what)
        elseif kind == "macro" and GetMacroInfo then
            local _, tex = GetMacroInfo(what)
            return tex
        end
    end)
    return ok and icon or nil
end




local function FaceData(target)
    local fb = FB()
    local face
    for _, f in ipairs(fb and fb.FACES or {}) do
        if f.id == target.face then face = f end
    end
    if not face then return nil end
    local page = tonumber(target.page) or 1
    local saved = fb:Get(page, face.id)
    local current = saved or ""
    local data = { title = face.title .. " (layout " .. page .. ")", face = face, page = page,
                   lists = { macros = {}, spells = {}, thug = {}, blizzard = {} }, off = {}, shown = {} }
    local ok, rows = pcall(fb.Options, fb, page, face)
    if not (ok and type(rows) == "table") then
        Log("chooser: FaceButtons:Options failed: %s", tostring(rows))
        rows = { { text = "Default: " .. face.default, value = "" } }
    end
    local flags = ThugUI.PadLayoutPage and ThugUI.PadLayoutPage.FACE_LISTS or {}
    data.default = { text = rows[1] and rows[1].text or ("Default: " .. face.default), value = "",
                     selected = current == "" }
    for i = 2, #rows do
        local row = rows[i]
        local kind = fb.Parse(row.value)
        local list = kind == "macro" and data.lists.macros or kind == "spell" and data.lists.spells or nil
        if list then
            list[#list + 1] = { text = (row.text:gsub("^Macro: ", "")), value = row.value,
                                icon = IconOf(row.value), selected = row.value == current }
        end
    end
    
    if flags.blizzard ~= false then
        data.lists.blizzard[1] = { text = data.default.text, value = "", selected = current == "" }
    end
    for _, t in ipairs(TABS) do
        data.shown[t.key] = true                 
        if flags[t.key] == false then data.off[t.key] = FACE_OFF end
    end
    return data
end

local function SlotData(target)
    local pl = PL()
    if not (pl and pl.Catalogue) then return nil end
    local slot = target.slot
    local cat = pl:Catalogue(slot)
    local data = { title = pl:Label(slot), slot = slot, default = cat.default,
                   lists = { macros = cat.macros, spells = cat.spells, thug = cat.thug, blizzard = cat.blizzard },
                   off = {}, shown = {} }
    if slot == "cross" then
        
        
        
        local d = pl:DefaultOf(slot)
        data.notes = {
            default = "Default: " .. ((d and d.title) or "nothing")
                .. " (ThugUI binds it while the shortcuts bar is up; Blizzard has no key for it on your build)",
        }
        local CS = ThugUI.ControllerShortcuts
        local line = (CS and CS.secureOK) and "Runs from the shortcuts bar; works in combat once set."
            or "Works out of combat only."
        data.notes.macros, data.notes.spells = line, line
    end
    local flags = pl.LISTS and pl.LISTS[slot]
    for _, t in ipairs(TABS) do
        
        data.shown[t.key] = not flags or flags[t.key] ~= false
    end
    return data
end



local function StyleRow(row, data)
    row.data = data
    row.name:SetText(data.text or "")
    Paint(row.name, data.disabled and "disabled" or "listItem")
    if data.note and data.note ~= "" then
        row.note:SetText(data.note)
        row.note:Show()
    else
        row.note:SetText("")
        row.note:Hide()
    end
    if data.icon then
        row.icon:SetTexture(data.icon)
        row.icon:Show()
    else
        row.icon:Hide()
    end
    row.check:SetShown(data.selected == true)
    row.icon:SetAlpha(data.disabled and 0.4 or 1)
end

local function MakeRow(parent, width)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, ROW_PLAIN)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    Paint(hl, "controlHighlight", "fill")
    row.check = row:CreateTexture(nil, "ARTWORK")
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetSize(16, 16)
    row.check:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", row, "LEFT", 22, 0)
    row.name = Paint(row:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlightSmall")), "listItem")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 48, -6)
    row.name:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.name:SetJustifyH("LEFT")
    row.note = Paint(row:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontDisableSmall")), "note")
    row.note:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    row.note:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.note:SetJustifyH("LEFT")
    row:SetScript("OnClick", function(self)
        local d = self.data
        if not d or d.disabled then return end
        C:Choose(d.value)
    end)
    return row
end

function C:Build()
    if self.frame then return self.frame end
    local W = ThugUI.Widgets

    
    
    local catcher = CreateFrame("Button", "ThugUI_PadChooserCatcher", UIParent)
    catcher:SetFrameStrata("DIALOG")
    catcher:SetFrameLevel(1)
    catcher:SetAllPoints(UIParent)
    catcher:RegisterForClicks("AnyUp")
    catcher:SetScript("OnClick", function() C:Close() end)
    catcher:Hide()

    local f = CreateFrame("Frame", "ThugUI_PadChooser", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(20)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetSize(W_WIDTH, W_HEIGHT)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        Paint(f, "listBackground", "backdrop")
        Paint(f, "border", "border")
    end
    f:Hide()

    f.title = Paint(f:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "section")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
    f.title:SetPoint("RIGHT", f, "RIGHT", -12, 0)
    f.title:SetJustifyH("LEFT")

    local inner = W_WIDTH - 24
    f.pinned = MakeRow(f, inner)
    f.pinned:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -(TITLE_H + 4))

    
    f.tabs = {}
    for i, t in ipairs(TABS) do
        local b = W.CreateStateButton(f, t.word .. " (99)")
        b.key, b.word = t.key, t.word
        b:SetScript("OnClick", function() C:ShowTab(t.key) end)
        f.tabs[i] = b
    end

    f.body = CreateFrame("Frame", nil, f)
    f.body:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -(TITLE_H + 4 + PIN_H + 6 + TAB_H + 6))
    f.body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12 + NOTE_H)

    f.note = Paint(f:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontDisableSmall")), "note")
    f.note:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 10)
    f.note:SetWidth(W_WIDTH - 24)
    f.note:SetJustifyH("LEFT")
    f.note:SetJustifyV("BOTTOM")
    local scroll, content = W.CreateScrollArea(f.body, 24)
    f.scroll, f.content = scroll, content

    f.empty = Paint(f.body:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontDisableSmall")), "note")
    f.empty:SetPoint("TOPLEFT", f.body, "TOPLEFT", 8, -10)
    f.empty:SetPoint("RIGHT", f.body, "RIGHT", -8, 0)
    f.empty:SetJustifyH("LEFT")

    f.rows = {}
    self.frame, self.catcher = f, catcher
    self.rowFrames = f.rows
    return f
end




local function LayoutTabs(f, data)
    local x = 12
    for i, t in ipairs(TABS) do
        local b = f.tabs[i]
        local list = data.lists[t.key]
        b.label:SetText(t.word .. " (" .. #list .. ")")
        if data.shown[t.key] then
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -(TITLE_H + 4 + PIN_H + 6))
            b:SetHeight(TAB_H)
            b:Show()
            x = x + b:GetWidth() + 4
        else
            b:Hide()
        end
    end
end


function C:ShowTab(key)
    local f, data = self.frame, self.data
    if not (f and data and data.lists[key] and data.shown[key]) then return false end
    self.tab = key
    for i, t in ipairs(TABS) do f.tabs[i]:SetActive(t.key == key) end
    
    local notes = data.notes or {}
    local lines = {}
    if notes.default then lines[#lines + 1] = notes.default end
    if notes[key] then lines[#lines + 1] = notes[key] end
    f.note:SetText(table.concat(lines, "\n"))
    local list = data.lists[key]
    local y = 0
    for i, row in ipairs(list) do
        local frame = f.rows[i]
        if not frame then
            frame = MakeRow(f.content, W_WIDTH - 24 - 28)
            f.rows[i] = frame
        end
        StyleRow(frame, row)
        local h = (row.note and row.note ~= "") and ROW_NOTE or ROW_PLAIN
        frame:SetHeight(h)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, -y)
        frame:Show()
        y = y + h
    end
    for i = #list + 1, #f.rows do
        f.rows[i].data = nil
        f.rows[i]:Hide()
    end
    f.content:SetSize(W_WIDTH - 24 - 28, math.max(y, 1))
    if f.scroll.SetVerticalScroll then f.scroll:SetVerticalScroll(0) end
    if #list == 0 then
        f.empty:SetText(data.off[key] or (key == "macros" and EMPTY.macros) or EMPTY.other)
        f.empty:Show()
    else
        f.empty:SetText("")
        f.empty:Hide()
    end
    return true
end


local function StartTab(data)
    for _, t in ipairs(TABS) do
        if data.shown[t.key] then
            for _, row in ipairs(data.lists[t.key]) do
                if row.selected then return t.key end
            end
        end
    end
    for _, t in ipairs(TABS) do
        if data.shown[t.key] then return t.key end
    end
    return nil
end


function C:Open(target)
    if type(target) ~= "table" then return false end
    local data
    if target.slot then data = SlotData(target) elseif target.face then data = FaceData(target) end
    if not data then
        Log("chooser: nothing to open for %s", tostring(target.slot or target.face))
        return false
    end
    local f = self:Build()
    self.target, self.data = target, data
    f.title:SetText(data.title)
    StyleRow(f.pinned, { text = data.default.text, value = "", selected = data.default.selected })
    LayoutTabs(f, data)

    
    local page = ThugUI.PadLayoutPage
    local anchor = page and page.pic
    f:ClearAllPoints()
    if anchor then
        f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 12, 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    self.catcher:Show()
    f:Show()
    self:ShowTab(StartTab(data))
    return true
end

function C:Close()
    self.target, self.data, self.tab = nil, nil, nil
    if self.frame then self.frame:Hide() end
    if self.catcher then self.catcher:Hide() end
end

function C:IsShown()
    return self.frame ~= nil and self.frame:IsShown() and self.target ~= nil
end



function C:Choose(value)
    local target = self.target
    if not target then return false end
    value = value or ""
    self:Close()
    if target.slot then
        local pl = PL()
        if not pl then return false end
        local stored = pl:Set(target.slot, value)
        if stored then
            Log("page: %s -> %s (chooser)", target.slot, value ~= "" and value or "default")
        end
        return stored
    end
    local fb = FB()
    if not fb then return false end
    fb:Set(tonumber(target.page) or 1, target.face, value ~= "" and value or nil)
    
    local pl = PL()
    if pl and pl.Notify then pl:Notify() end
    Log("page: face %s layout %s -> %s (chooser)", target.face, tostring(target.page), value ~= "" and value or "default")
    return true
end
