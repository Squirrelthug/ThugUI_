














ThugUI = ThugUI or {}

local CW = {}
ThugUI.CopyWindow = CW

local W = ThugUI.Widgets
local function Paint(obj, role, how) return ThugUI.Theme:Paint(obj, role, how) end
local function Font(name) return ThugUI.Theme:Font(name) end

local WIDTH, HEIGHT = 640, 380
local ROW_HEIGHT = 20
local MAX_ROWS = 11                    
local COLS = { { "Mode", 0 }, { "Scope", 130 }, { "Who", 210 }, { "Changed from defaults", 300 } }
local MODE_NAME = { m = "Mouse & keyboard", p = "Controller" }

CW.rowsData = {}                      





local function Text(parent, role, template)
    return Paint(parent:CreateFontString(nil, "OVERLAY", Font(template or "GameFontHighlightSmall")), role)
end

function CW:Build()
    if self.frame then return self.frame end
    local Window = ThugUI.Window

    
    
    local cover = CreateFrame("Button", nil, Window.frame)
    cover:SetAllPoints(Window.frame)
    cover:SetFrameLevel((Window.frame:GetFrameLevel() or 0) + 50)
    cover:EnableMouse(true)
    cover:RegisterForClicks("AnyUp")
    cover:SetScript("OnClick", function() end)
    local dim = cover:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints()
    Paint(dim, "modalDim", "fill")
    cover:Hide()
    self.cover = cover

    local f = CreateFrame("Frame", "ThugUI_CopyWindow", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        Paint(f, "listBackground", "backdrop")
        Paint(f, "listBorder", "border")
    end
    f:Hide()
    self.frame = f

    
    local title = Text(f, "windowTitle", "GameFontNormal")
    title:SetPoint("TOPLEFT", 14, -12)
    self.title = title
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    
    
    close:SetScript("OnClick", function() CW:Close() end)
    self.closeButton = close
    local rule = f:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", 12, -36)
    rule:SetPoint("TOPRIGHT", -12, -36)
    Paint(rule, "ruleHeader", "fill")

    
    local from = CreateFrame("Frame", nil, f, "BackdropTemplate")
    from:SetPoint("TOPLEFT", 12, -46)
    from:SetSize(430, 262)
    if from.SetBackdrop then
        from:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        Paint(from, "controlFill", "backdrop")
        Paint(from, "controlBorder", "border")
    end
    local fromTitle = Text(from, "headerLabel", "GameFontNormal")
    fromTitle:SetPoint("TOPLEFT", 8, -6)
    fromTitle:SetText("From")
    self.headers = {}
    for i, col in ipairs(COLS) do
        local h = Text(from, "note")
        h:SetPoint("TOPLEFT", 8 + col[2], -26)
        h:SetText(col[1])
        self.headers[i] = h
    end
    self.from = from

    local list = CreateFrame("ScrollFrame", nil, from)
    list:SetPoint("TOPLEFT", 4, -42)
    list:SetPoint("BOTTOMRIGHT", -4, 4)
    local child = CreateFrame("Frame", nil, list)
    child:SetSize(420, 1)
    list:SetScrollChild(child)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(selfList, delta)
        local max = math.max(0, child:GetHeight() - selfList:GetHeight())
        local v = math.min(max, math.max(0, (selfList:GetVerticalScroll() or 0) - delta * ROW_HEIGHT * 2))
        selfList:SetVerticalScroll(v)
    end)
    self.list, self.listChild = list, child
    self.rowFrames = {}

    
    local arrow = f:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    arrow:SetSize(28, 28)
    arrow:SetPoint("LEFT", from, "RIGHT", 6, 0)

    
    local to = CreateFrame("Frame", nil, f, "BackdropTemplate")
    to:SetPoint("TOPLEFT", from, "TOPRIGHT", 40, 0)
    to:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 60)
    if to.SetBackdrop then
        to:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        Paint(to, "controlFill", "backdrop")
        Paint(to, "controlBorder", "border")
    end
    local toTitle = Text(to, "headerLabel", "GameFontNormal")
    toTitle:SetPoint("TOPLEFT", 8, -6)
    toTitle:SetText("To (this page, where you are)")
    toTitle:SetPoint("RIGHT", -6, 0)
    toTitle:SetJustifyH("LEFT")
    
    self.toLines = {}
    for i = 1, 3 do
        local l = Text(to, "note")
        l:SetPoint("TOPLEFT", 8, -30 - (i - 1) * 18)
        local v = Text(to, "headerLabel")
        v:SetPoint("LEFT", l, "RIGHT", 6, 0)
        v:SetPoint("RIGHT", to, "RIGHT", -8, 0)
        v:SetJustifyH("LEFT")
        self.toLines[i] = { label = l, value = v }
    end
    local toWarn = Text(to, "warning")
    toWarn:SetPoint("TOPLEFT", 8, -30 - 3 * 18 - 8)
    toWarn:SetPoint("RIGHT", -8, 0)
    toWarn:SetJustifyH("LEFT")
    toWarn:SetText("Replaces these settings.\nThe source is not changed.")
    self.to = to

    
    local foot = Text(f, "note")
    foot:SetPoint("BOTTOMLEFT", 14, 20)
    foot:SetPoint("RIGHT", f, "RIGHT", -200, 0)
    foot:SetJustifyH("LEFT")
    self.footNote = foot
    local copy = W.CreateStateButton(f, "Copy")
    copy:SetWidth(90)
    copy:SetPoint("BOTTOMRIGHT", -14, 14)
    copy:SetScript("OnClick", function() CW:Copy() end)
    self.copyButton = copy
    local cancel = W.CreateStateButton(f, "Cancel")
    cancel:SetWidth(90)
    cancel:SetActive(true)
    cancel:SetPoint("RIGHT", copy, "LEFT", -8, 0)
    cancel:SetScript("OnClick", function() CW:Close() end)
    self.cancelButton = cancel

    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("copyWindow", function() return f:IsShown() end, function() CW:Close() end)
    end
    return f
end


local function RowFrame(self, i)
    local r = self.rowFrames[i]
    if r then return r end
    r = CreateFrame("Button", nil, self.listChild)
    r:SetSize(420, ROW_HEIGHT)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    r.fill = r:CreateTexture(nil, "BACKGROUND")
    r.fill:SetAllPoints()
    Paint(r.fill, "selectedFill", "fill")
    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetAllPoints()
    Paint(r.hl, "highlight", "fill")
    r.cells = {}
    for c, col in ipairs(COLS) do
        local t = Text(r, "listItem")
        t:SetPoint("LEFT", 4 + col[2], 0)
        r.cells[c] = t
    end
    r.group = Text(r, "copyGroup", "GameFontNormalSmall")
    r.group:SetPoint("LEFT", 4, 0)
    r:SetScript("OnClick", function(btn)
        if btn.row and not btn.row.here then CW:Select(btn.row.id) end
    end)
    self.rowFrames[i] = r
    return r
end





function CW:Fill()
    local P = ThugUI.Profiles
    local keys = self.def.scopeKeys
    local rows = P:CopyRows(keys)
    local withModes = P:PageHasModes(keys)
    self.withModes = withModes
    self.rowsData = rows
    
    self.headers[1]:SetShown(withModes)

    local drawn, lastMode = {}, nil
    for _, row in ipairs(rows) do
        if withModes and row.mode ~= lastMode then
            drawn[#drawn + 1] = { groupTitle = MODE_NAME[row.mode] }
            lastMode = row.mode
        end
        drawn[#drawn + 1] = row
    end
    self.drawn = drawn
    for i, d in ipairs(drawn) do
        local r = RowFrame(self, i)
        r.row = d.id and d or nil
        r:Show()
        if d.groupTitle then
            r.group:SetText(d.groupTitle)
            r.group:Show()
            for _, c in ipairs(r.cells) do c:SetText("") end
            r.fill:Hide()
            r:EnableMouse(false)
        else
            r.group:Hide()
            r.cells[1]:SetText(withModes and MODE_NAME[d.mode] or "")
            r.cells[2]:SetText(d.scope)
            r.cells[3]:SetText(d.who .. (d.here and " (you are here)" or ""))
            r.cells[4]:SetText(d.here and "-" or (d.changed and "Yes" or "No"))
            for _, c in ipairs(r.cells) do Paint(c, d.here and "disabled" or "listItem") end
            r.fill:SetShown(self.selected == d.id)
            r:EnableMouse(not d.here)
        end
    end
    for i = #drawn + 1, #self.rowFrames do self.rowFrames[i]:Hide() end
    self.listChild:SetHeight(math.max(1, #drawn * ROW_HEIGHT))

    
    local k = keys[1]
    local scope = P:ScopeOf(k)
    local where = scope == "character" and ("Character - " .. (tostring(P.charKeyAtLoad or "?"):match("^([^%-]+)") or "?"))
        or scope == "faction" and ("Faction - " .. tostring(P.factionAtLoad or "?"))
        or ('Shared - Profile "' .. tostring(P.active) .. '"')
    local lines = { { "Page:", tostring(self.def.title) } }
    if withModes then lines[#lines + 1] = { "Mode:", P.padAtLoad and MODE_NAME.p or MODE_NAME.m } end
    lines[#lines + 1] = { "Scope:", where }
    self.toText = {}
    for i, pair in ipairs(self.toLines) do
        local line = lines[i]
        pair.label:SetText(line and line[1] or "")
        pair.value:SetText(line and line[2] or "")
        if line then self.toText[#self.toText + 1] = line[1] .. " " .. line[2] end
    end
    self.footNote:SetText("Only " .. tostring(self.def.title) .. " settings are copied. Nothing stays linked afterwards.")
    self.copyButton:SetActive(self.selected ~= nil)
end

function CW:Select(id)
    self.selected = id
    self:Fill()
end






function CW:Open(def)
    if not (def and def.scopeKeys) then return end
    if ThugUI.CombatClose and not ThugUI.CombatClose:Allow("copyWindow") then return end
    local f = self:Build()
    self.def = def
    self.selected = nil
    self.title:SetText("Copy settings: " .. tostring(def.title))
    self:Fill()
    f:ClearAllPoints()
    f:SetPoint("CENTER", ThugUI.Window.frame, "CENTER")
    self.cover:Show()
    f:Show()
end

function CW:IsOpen()
    return self.frame ~= nil and self.frame:IsShown()
end

function CW:Close()
    if self.frame then self.frame:Hide() end
    if self.cover then self.cover:Hide() end
end

function CW:Copy()
    if not self.selected or not self.def then return end
    local P = ThugUI.Profiles
    local id, def = self.selected, self.def
    local sourceText
    for _, row in ipairs(self.rowsData) do
        if row.id == id then
            sourceText = (self.withModes and (MODE_NAME[row.mode] .. ", ") or "") .. row.scope .. " (" .. row.who .. ")"
        end
    end
    local copied = false
    for _, key in ipairs(def.scopeKeys) do
        if P:CopyFromSource(key, id) then copied = true end
    end
    self:Close()
    if copied then
        P:PromptCopyReload(def.title, sourceText or id, P:ScopeOf(def.scopeKeys[1]))
    end
end

return CW
