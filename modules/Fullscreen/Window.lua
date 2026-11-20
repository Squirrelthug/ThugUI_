







local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen or {}
ThugUI.Fullscreen = FS
ThugUI:RegisterModule("Fullscreen", FS)


ThugUI.defaults.Fullscreen = {
    character = true, combatClose = true, textSize = 18, skin = true,
    
    
    
    
    
    
    iconsDoll = 100, iconsChest = 100, iconsGrid = 100, iconsStrip = 100, iconsSlots = 100,
}

local UI = {}

FS.UI = UI
local hooked = setmetatable({}, { __mode = "k" })


local RIGHT_REGIONS = { "info", "grid", "strip", "bagslots" }
local REGION_LISTS = {}
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MARGIN = 24
local GUTTER = 16


FS.GAP = 4




local SK = {
    MX = 24, MT = 48, MB = 24,      
    GUTTER = 24,                    
    INSET = 30,                     
    SIDE_MAX = 720, CENTRE_MAX = 640, 
    HEADER = 104,                   
    INFO_HEADER = 68,               
    TAB_H = 36,                     
    PLATE_H = 28,                   
    WELL_PAD = 8,                   
    SCROLL_W = 12, SCROLL_GAP = 6,  
    SPLIT_GAP = 16,                 
    CHIP_H = 32,                    
    ROW_GAP = 4,                    
}
FS.SK = SK
FS.TITLE_FONT = "Fonts\\MORPHEUS.ttf"
FS.TITLE_COLOUR = { 0.839, 0.690, 0.376 }   



function FS.Framed()
    return FS.Skin ~= nil and FS.Skin.Enabled()
end





function FS:IconSize(key, base)
    local pct = tonumber(self:Cfg()[key]) or 100
    pct = math.max(50, math.min(300, pct))
    return math.max(8, math.floor(base * pct / 100 + 0.5))
end


function FS.FitCount(width, cell)
    return math.max(1, math.floor((width + FS.GAP) / (cell + FS.GAP)))
end



function FS.HeaderHeight(size)
    if FS.Framed() then
        return SK.HEADER - SK.INSET
    end
    return size + 12
end


function FS.TabHeight(size)
    if FS.Framed() then
        return SK.TAB_H
    end
    return size + 10
end



function FS.StyleTitle(fontString, size)
    if FS.Framed() then
        fontString:SetFont(FS.TITLE_FONT, size)
        local c = FS.TITLE_COLOUR
        fontString:SetTextColor(c[1], c[2], c[3])
    else
        fontString:SetFont(STANDARD_TEXT_FONT, size)
    end
end
FS.GOLD = { 1, 0.82, 0 }


FS.MUTED = { r = 0.45, g = 0.45, b = 0.45 }

function FS:Cfg()
    ThugUIDB.Fullscreen = ThugUIDB.Fullscreen or {}
    local c = ThugUIDB.Fullscreen
    for key, value in pairs(ThugUI.defaults.Fullscreen) do
        if c[key] == nil then
            c[key] = value
        end
    end
    return c
end

function FS:Active()
    return ThugUI:IsModuleOn("fullscreen")
        and ThugUI.ControllerMode
        and ThugUI.ControllerMode:IsActive()
        and self:Cfg().character
end

local function Log(message, ...)
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("FULLSCREEN", message, ...)
    end
end

local function Later(fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, fn)
    else
        fn()
    end
end

local function OpenCondition()
    local bags = (_G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown())
        or (_G.ContainerFrame1 and _G.ContainerFrame1:IsShown())
    local paper = _G.CharacterFrame and _G.CharacterFrame:IsShown()
        and _G.PaperDollFrame and _G.PaperDollFrame:IsShown()
    
    
    
    
    
    local targeting = FS.Target and ((FS.Target.holdOpen and FS.Target.active) or FS.Target.castHold)
    return bags or paper or targeting
end







function FS.NewCell(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 2 })
    f:SetBackdropColor(0, 0, 0, 0.6)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", 2, -2)
    f.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    
    
    f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cooldown:SetAllPoints(f.icon)
    f.cooldown:Hide()
    
    
    f.over = CreateFrame("Frame", nil, f)
    f.over:SetAllPoints(f)
    f.over:SetFrameLevel(f.cooldown:GetFrameLevel() + 1)
    f.count = f.over:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.count:SetPoint("BOTTOMRIGHT", -3, 3)
    FS.cells[#FS.cells + 1] = f
    return f
end



FS.cells = FS.cells or {}




function FS.SizeCount(cell)
    local h = cell:GetHeight() or 0
    local size = math.max(12, math.floor(h * 0.32 + 0.5))
    if cell.countSize == size then
        return
    end
    local file = cell.countFile
    if not file then
        file = cell.count:GetFont() or _G.NumberFontNormal and _G.NumberFontNormal:GetFont() or STANDARD_TEXT_FONT
        cell.countFile = file
    end
    if pcall(cell.count.SetFont, cell.count, file, size, "THICKOUTLINE") then
        cell.countSize = size
    end
end




function FS.SetCellCooldown(cell, item)
    local cd = cell.cooldown
    if not cd then
        return
    end
    local start, duration, enable
    local ok = false
    if type(item) == "table" and item.itemID then
        local c = _G.C_Container
        if item.kind == nil and type(item.bag) == "number" and type(item.slot) == "number"
            and c and c.GetContainerItemCooldown then
            ok, start, duration, enable = pcall(c.GetContainerItemCooldown, item.bag, item.slot)
        elseif item.kind == "equip" and type(item.slot) == "number" and _G.GetInventoryItemCooldown then
            ok, start, duration, enable = pcall(_G.GetInventoryItemCooldown, "player", item.slot)
        end
    end
    if not ok or start == nil then
        cd:Hide()
        return
    end
    local set = _G.CooldownFrame_Set
    if type(set) == "function" then
        if not pcall(set, cd, start, duration, enable) then
            cd:Hide()
        end
    elseif not pcall(cd.SetCooldown, cd, start, duration) then
        cd:Hide()
    end
end


function FS:UpdateCooldowns()
    for _, cell in ipairs(FS.cells) do
        if cell:IsShown() and cell.item then
            FS.SetCellCooldown(cell, cell.item)
        end
    end
end








function FS.DressCell(cell)
    if not FS.Framed() then
        if cell.skin then
            for _, piece in pairs(cell.skin) do
                piece:Hide()
            end
            cell.icon:ClearAllPoints()
            cell.icon:SetPoint("TOPLEFT", 2, -2)
            cell.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        end
        return nil
    end
    if not cell.skin then
        local Skin = FS.Skin
        local skin = {}
        skin.socket = Skin.Piece(cell, "cmp_cell", "BACKGROUND", 1)
        skin.ring = Skin.Piece(cell, "cmp_cell_quality", "OVERLAY", 1)
        skin.selected = Skin.Piece(cell, "cmp_cell_selected", "OVERLAY", 2)
        skin.veil = Skin.Piece(cell, "cmp_cell_unavailable", "OVERLAY", 3)
        for _, piece in pairs(skin) do
            piece:Fill(cell)
        end
        cell.skin = skin
    end
    local inset = (cell:GetWidth() or 64) * 12 / 128
    cell.icon:ClearAllPoints()
    cell.icon:SetPoint("TOPLEFT", inset, -inset)
    cell.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    return cell.skin
end







function FS.PaintCell(cell, item)
    cell.item = item
    if FS.Target then
        FS.Target:PaintCastRing(cell, item)
    end
    cell.icon:SetTexture(item.iconFileID)
    local text = item.countText
    if text == nil and item.stackCount and item.stackCount > 1 then
        text = item.stackCount
    end
    cell.count:SetText(text or "")
    FS.SizeCount(cell)
    FS.SetCellCooldown(cell, item)
    local r, g, b = 0.45, 0.45, 0.45
    local qr, qg, qb = 0.45, 0.45, 0.45
    local color = item.quality and _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[item.quality]
    if color then
        qr, qg, qb = color.r, color.g, color.b
    end
    local selected = FS:IsSelected(item)
    if selected then
        r, g, b = FS.GOLD[1], FS.GOLD[2], FS.GOLD[3]
    elseif color then
        r, g, b = color.r, color.g, color.b
    end
    local skin = FS.DressCell(cell)
    
    local hideBorder = skin and skin.ring and (not selected or skin.selected)
    cell:SetBackdropBorderColor(r, g, b, hideBorder and 0 or 1)
    cell:SetBackdropColor(0, 0, 0, (skin and skin.socket) and 0 or 0.6)
    if skin then
        if skin.socket then
            skin.socket:Show()
        end
        if skin.ring then
            skin.ring:SetTint(qr, qg, qb, 1)
            skin.ring:Show()
        end
        if skin.selected then
            skin.selected:SetShown(selected)
        end
    end
    local alpha = 1
    if item.alpha then
        alpha = item.alpha
    elseif item.isLocked then
        alpha = 0.45
    elseif item.empty then
        alpha = 0.5
    end
    
    
    
    local refused = FS.Refusal and FS.Refusal(item) and true or false
    
    
    
    local match = FS.Target and FS.Target.Match(item)
    if match == "mismatch" then
        refused = true
    end
    if FS.Target then
        FS.Target.PaintTick(cell, match == "match")
    end
    cell.icon:SetDesaturated(refused)
    if refused then
        alpha = math.min(alpha, 0.6)
    end
    
    
    if skin and skin.veil then
        skin.veil:SetShown(refused or item.isLocked or item.kind == "noammo")
    end
    cell:SetAlpha(alpha)
    cell:Show()
end




function FS.EnsurePool(pool, n, parent)
    if InCombatLockdown() and #pool < n then
        return #pool, true
    end
    for i = #pool + 1, n do
        local cell = FS.NewCell(parent)
        cell:Hide()
        pool[i] = cell
    end
    return n, false
end



FS.Scroll = {}

function FS.Scroll.Ensure(state, index)
    
    
    if state.map then
        index = state.map[index] or index
    end
    local row = math.floor((index - 1) / state.cols)
    local before = state.offset
    if row < state.offset then
        state.offset = row
    elseif row >= state.offset + state.rows then
        state.offset = row - state.rows + 1
    end
    return state.offset ~= before
end

function FS.Scroll.Clamp(state, count)
    local totalRows = math.ceil(count / state.cols)
    local most = math.max(0, totalRows - state.rows)
    state.offset = math.max(0, math.min(state.offset, most))
end

local function ItemKey(item)
    if not item then
        return nil
    end
    
    
    return table.concat({ tostring(item.kind), tostring(item.bag), tostring(item.slot), tostring(item.itemID),
        tostring(item.key) }, ":")
end




local function StyleOutline(f, thickness, r, g, b, a)
    for i, t in ipairs(f.edges) do
        t:SetColorTexture(r, g, b, a)
        
        if i <= 2 then
            t:SetHeight(thickness)
        else
            t:SetWidth(thickness)
        end
    end
end

local WHITE_RGB = { 1, 1, 1 }



local function NewOutline(parent, thickness, r, g, b, a)
    local f = CreateFrame("Frame", nil, parent)
    f.edges = {}
    local function Edge(p1, p2)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetPoint(p1)
        t:SetPoint(p2)
        f.edges[#f.edges + 1] = t
    end
    Edge("TOPLEFT", "TOPRIGHT")
    Edge("BOTTOMLEFT", "BOTTOMRIGHT")
    Edge("TOPLEFT", "BOTTOMLEFT")
    Edge("TOPRIGHT", "BOTTOMRIGHT")
    StyleOutline(f, thickness, r, g, b, a)
    f:Hide()
    return f
end





local PANEL_INSET = 8
local PANEL_LIFT = 0.06
local PANEL_GREY = { 0.35, 0.35, 0.35, 1 }
local FALLBACK_ACCENT = { 0.2, 0.6, 1 }


local function AccentColour()
    if ThugUI.Theme and ThugUI.Theme.Color then
        local ok, r, g, b = pcall(ThugUI.Theme.Color, ThugUI.Theme, "accent")
        if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
            return r, g, b
        end
    end
    return FALLBACK_ACCENT[1], FALLBACK_ACCENT[2], FALLBACK_ACCENT[3]
end



local function NewPanel(parent, column)
    local p = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    p:SetFrameLevel(parent:GetFrameLevel())
    p:SetBackdrop({ bgFile = WHITE })
    p.column = column
    p.outline = NewOutline(p, 1, PANEL_GREY[1], PANEL_GREY[2], PANEL_GREY[3], PANEL_GREY[4])
    p.outline:SetAllPoints(p)
    p.outline:Show()
    return p
end



local function ColumnOf(region)
    if region == "paperdoll" or region == "armorchest" or region == "stats" or region == "upkeep" then
        return "left"
    end
    if region == "info" then
        return "info"
    end
    return "right"
end



local function SideOf(region)
    if region == "paperdoll" or region == "armorchest" or region == "stats" or region == "upkeep" then
        return "plugin"
    end
    if region == "info" then
        return nil
    end
    return "bag"
end










local DIMMED = 0.4



local function GlyphText(key, fallback, size)
    local hints = ThugUI.PadHints
    if hints and hints.Glyph then
        local ok, text = pcall(hints.Glyph, key, size)
        if ok and type(text) == "string" and text ~= "" then
            return text
        end
    end
    return fallback
end








local GLYPH_TEXT = { PADLSHOULDER = "L1", PADRSHOULDER = "R1" }



local function ShowGlyph(holder, key)
    local hints = ThugUI.PadHints
    local atlas
    if hints and hints.GlyphAtlas then
        local ok, name = pcall(hints.GlyphAtlas, key)
        if ok and type(name) == "string" and name ~= "" then
            atlas = name
        end
    end
    
    local accepted = false
    if atlas then
        local ok, result = pcall(holder.texture.SetAtlas, holder.texture, atlas, false)
        accepted = ok and result ~= false
    end
    if accepted then
        holder.texture:Show()
        holder.text:SetText("")
        holder.text:Hide()
        return atlas
    end
    holder.texture:Hide()
    holder.text:SetText(GLYPH_TEXT[key])
    holder.text:Show()
    return nil
end


function FS.RefreshTabGlyphs(pair)
    ShowGlyph(pair.left, "PADLSHOULDER")
    ShowGlyph(pair.right, "PADRSHOULDER")
end




function FS.TabGlyphs(parent)
    local pair = {}
    for _, side in ipairs({ "left", "right" }) do
        local holder = CreateFrame("Frame", nil, parent)
        holder.texture = holder:CreateTexture(nil, "OVERLAY")
        holder.texture:SetPoint("CENTER", holder, "CENTER", 0, 0)
        holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        holder.text:SetAllPoints(holder)
        holder.text:SetJustifyH("CENTER")
        holder.text:SetJustifyV("MIDDLE")
        holder.text:SetWordWrap(false)
        pair[side] = holder
    end
    FS.RefreshTabGlyphs(pair)
    
    
    
    pair.events = CreateFrame("Frame", nil, parent)
    local ok = pcall(pair.events.RegisterEvent, pair.events, "GAME_PAD_ACTIVE_CHANGED")
    if not ok then
        Log("GAME_PAD_ACTIVE_CHANGED could not be registered; glyphs keep their first art")
    end
    pair.events:SetScript("OnEvent", function()
        FS.RefreshTabGlyphs(pair)
    end)
    return pair
end



function FS.PlaceTabGlyphs(pair, parent, width, titleH, tabH, size)
    
    
    local glyphSize = tabH - 4
    local glyphW = glyphSize + 8
    pair.glyphSize = glyphSize
    for _, holder in ipairs({ pair.left, pair.right }) do
        holder.text:SetFont(STANDARD_TEXT_FONT, size)
        holder.texture:SetSize(glyphSize, glyphSize)
        holder:SetSize(glyphW, tabH)
        holder:ClearAllPoints()
    end
    pair.left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -titleH)
    pair.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -titleH)
    FS.RefreshTabGlyphs(pair)
    return glyphW + FS.GAP, width - glyphW - FS.GAP
end




function FS.SetTabGlyphsLit(pair, lit)
    local alpha = lit and 1 or DIMMED
    pair.left:SetAlpha(alpha)
    pair.right:SetAlpha(alpha)
end



local function ScreenSize()
    local w = tonumber(UIParent:GetWidth()) or 0
    local h = tonumber(UIParent:GetHeight()) or 0
    if w < 400 or h < 300 then
        return 1920, 1080
    end
    return w, h
end




local function PaintBackground(f)
    f:SetBackdrop({ bgFile = WHITE })
    ThugUI.Theme:Paint(f, "listBackground", "backdrop")
    local r, g, b = f:GetBackdropColor()
    f:SetBackdropColor(r, g, b, 1)
end

function FS:ArmInput()
    if self.inputArmed then
        return true
    end
    if InCombatLockdown() then
        return false
    end
    self:Build()
    local input = UI.input
    local prop = pcall(input.SetPropagateKeyboardInput, input, false)
    local button = pcall(input.EnableGamePadButton, input, true)
    
    
    pcall(input.EnableGamePadStick, input, false)
    self.inputArmed = prop and button
    return self.inputArmed
end



function FS:NewHalf(name)
    local half = { name = name, lines = {} }
    half.frame = CreateFrame("Frame", nil, UI.infoColumn)
    half.title = half.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    half.title:SetPoint("TOPLEFT", half.frame, "TOPLEFT", 0, 0)
    half.title:SetJustifyH("LEFT")
    half.title:SetWordWrap(false)
    half.scroll = CreateFrame("ScrollFrame", nil, half.frame)
    half.scroll:Show()
    half.content = CreateFrame("Frame", nil, half.scroll)
    half.scroll:SetScrollChild(half.content)
    half.message = half.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    half.message:SetPoint("TOPLEFT", half.content, "TOPLEFT", 0, 0)
    half.message:SetJustifyH("LEFT")
    half.message:SetWordWrap(true)
    half.message:Hide()
    return half
end

function FS:Build()
    if UI.frame then
        return UI.frame
    end
    local f = CreateFrame("Frame", "ThugUI_Fullscreen", UIParent, "BackdropTemplate")
    f:SetAllPoints(UIParent)
    
    
    
    
    
    
    
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(1000)
    f:EnableMouse(true)
    PaintBackground(f)
    f:SetAlpha(1)
    f:Hide()
    UI.frame = f
    self.frame = f

    UI.left = CreateFrame("Frame", nil, f)
    UI.infoColumn = CreateFrame("Frame", nil, f)
    UI.right = CreateFrame("Frame", nil, f)
    UI.panels = {
        left = NewPanel(f, UI.left),
        info = NewPanel(f, UI.infoColumn),
        right = NewPanel(f, UI.right),
    }

    
    
    UI.halves = { bag = self:NewHalf("bag"), plugin = self:NewHalf("plugin") }
    
    UI.infoTitle = UI.halves.bag.title
    UI.info = UI.halves.bag.scroll
    UI.infoContent = UI.halves.bag.content
    UI.message = UI.halves.bag.message
    UI.lines = UI.halves.bag.lines

    
    UI.footer = CreateFrame("Frame", nil, UI.infoColumn)
    
    
    
    UI.legendChips = {}

    
    
    UI.highlight = NewOutline(f, 2, 1, 1, 1, 1)
    UI.highlight:SetFrameLevel(f:GetFrameLevel() + 30)
    
    
    UI.highlight:SetScript("OnUpdate", function(frame, elapsed)
        if FS.Target then
            FS.Target:Pulse(frame, elapsed)
        end
    end)
    UI.halfOutline =NewOutline(f, 2, 1, 1, 1, 1)
    UI.halfOutline:SetFrameLevel(f:GetFrameLevel() + 30)

    
    
    
    UI.input = CreateFrame("Frame", nil, UIParent)
    UI.input:SetAllPoints(f)
    UI.input:SetFrameStrata("TOOLTIP")
    UI.input:SetFrameLevel(f:GetFrameLevel() + 40)
    UI.input:Hide()
    UI.input:SetScript("OnGamePadButtonDown", function(_, button)
        FS:OnButtonDown(button)
    end)
    UI.input:SetScript("OnGamePadButtonUp", function(_, button)
        FS:OnButtonUp(button)
    end)
    
    UI.input:SetScript("OnUpdate", function(_, elapsed)
        FS:OnInputUpdate(elapsed)
    end)
    self.input = UI.input

    
    
    
    
    f:SetScript("OnUpdate", function(_, elapsed)
        if not UI.input:IsShown() then
            FS:PollPopups(elapsed)
        end
    end)

    self.Character:build(UI.left)
    self.Bags:Build(UI.right)
    self:Layout()
    return f
end








function FS:Layout()
    if not UI.frame then
        return
    end
    local size = self:Cfg().textSize
    local sw, sh = ScreenSize()
    local framed = FS.Framed()
    self.framed = framed
    local leftW, centreW, rightW, height, originX, originY, gutter, inset
    if framed then
        inset = SK.INSET
        gutter = SK.GUTTER + 2 * inset
        local usable = sw - 2 * SK.MX - 2 * SK.GUTTER
        local lw = math.min(SK.SIDE_MAX, math.floor(usable * 0.36))
        local cw = math.min(SK.CENTRE_MAX, math.floor(usable * 0.28))
        local rw = math.min(SK.SIDE_MAX, math.floor(usable * 0.36))
        local spare = usable - (lw + cw + rw)
        originX = SK.MX + math.floor(spare / 2) + inset
        originY = SK.MT + inset
        leftW, centreW, rightW = lw - 2 * inset, cw - 2 * inset, rw - 2 * inset
        height = sh - SK.MT - SK.MB - 2 * inset
    else
        inset = PANEL_INSET
        gutter = GUTTER
        originX, originY = MARGIN, MARGIN
        local usable = sw - 2 * MARGIN - 2 * GUTTER
        leftW = math.floor(usable * 0.36)
        centreW = math.floor(usable * 0.28)
        rightW = math.floor(usable * 0.36)
        height = sh - 2 * MARGIN
    end
    self.panelInset = inset
    
    
    
    
    
    
    local gridW = framed and (rightW - 2 * SK.WELL_PAD - SK.SCROLL_W - SK.SCROLL_GAP) or rightW
    local cell = math.floor(math.min(64, (gridW - 7 * FS.GAP) / 8))
    cell = math.max(cell, 8)
    self.cell = cell

    UI.left:ClearAllPoints()
    UI.left:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", originX, -originY)
    UI.left:SetSize(leftW, height)
    UI.infoColumn:ClearAllPoints()
    UI.infoColumn:SetPoint("TOPLEFT", UI.left, "TOPRIGHT", gutter, 0)
    UI.infoColumn:SetSize(centreW, height)
    UI.right:ClearAllPoints()
    UI.right:SetPoint("TOPLEFT", UI.infoColumn, "TOPRIGHT", gutter, 0)
    UI.right:SetSize(rightW, height)

    
    
    
    
    local titleH = size + 12
    local footerH, split, infoHead
    if framed then
        infoHead = SK.INFO_HEADER - inset
        local rows = math.ceil(FS.Actions.LEGEND_LINES / 2)
        footerH = rows * (SK.CHIP_H + FS.GAP)
        split = SK.SPLIT_GAP
    else
        infoHead = 0
        footerH = FS.Actions.LEGEND_LINES * (size + FS.GAP) + 8
        split = 8
    end
    self.footerHeight = footerH
    self.infoHead = infoHead
    self.halfGap = split
    UI.footer:ClearAllPoints()
    UI.footer:SetPoint("BOTTOMLEFT", UI.infoColumn, "BOTTOMLEFT", 0, 0)
    UI.footer:SetSize(centreW, footerH)
    UI.legendWidth = centreW
    local halfH = math.floor((height - infoHead - footerH - 2 * split) / 2)
    self.halfHeight = halfH
    self.contentWidth = centreW
    self.titleHeight = titleH
    local offset = infoHead
    for _, name in ipairs({ "bag", "plugin" }) do
        local half = UI.halves[name]
        half.frame:ClearAllPoints()
        half.frame:SetPoint("TOPLEFT", UI.infoColumn, "TOPLEFT", 0, -offset)
        half.title:SetFont(STANDARD_TEXT_FONT, size + 6)
        half.message:SetFont(STANDARD_TEXT_FONT, size)
        offset = offset + halfH + split
    end
    self:ApplyHalves()
    for _, name in ipairs({ "left", "info", "right" }) do
        local panel = UI.panels[name]
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", panel.column, "TOPLEFT", -inset, inset)
        panel:SetPoint("BOTTOMRIGHT", panel.column, "BOTTOMRIGHT", inset, -inset)
        panel.w = panel.column:GetWidth() + 2 * inset
        panel.h = height + 2 * inset
    end

    
    self:ApplySkin(sw, sh)
    self.Character:Layout(leftW, height, size, cell)
    self.Bags:Layout(rightW, height, size, cell)
    
    self.Character:Skin()
    self.Bags:Skin()
    self:UpdatePanels()
    if UI.frame:IsShown() then
        self:Refresh()
    end
end






function FS:HalfMetrics(name)
    local size = self:Cfg().textSize
    local half = UI.halves and UI.halves[name]
    
    
    local headed = not (half and half.noHeading)
    if not self.framed then
        return 0, headed and self.titleHeight or 0, self.contentWidth
    end
    local top = SK.PLATE_H + 4 + SK.WELL_PAD
    if name == "bag" and headed then
        top = top + size + 12
    end
    local width = self.contentWidth - 2 * SK.WELL_PAD - SK.SCROLL_W - SK.SCROLL_GAP
    return SK.WELL_PAD, top, width
end




function FS:ApplyHalves()
    local halfH = self.halfHeight
    if not halfH or not UI.halves then
        return
    end
    local show = self.bottomShown ~= false
    local bagH = show and halfH or (2 * halfH + (self.halfGap or 8))
    local bag, plugin = UI.halves.bag, UI.halves.plugin
    bag.frame:SetSize(self.contentWidth, bagH)
    plugin.frame:SetSize(self.contentWidth, halfH)
    for _, pair in ipairs({ { bag, bagH }, { plugin, halfH } }) do
        local half, h = pair[1], pair[2]
        local x, top, width = self:HalfMetrics(half.name)
        half.textX, half.headH, half.textW = x, top, width
        half.scroll:ClearAllPoints()
        half.scroll:SetPoint("TOPLEFT", half.frame, "TOPLEFT", x, -top)
        half.scroll:SetSize(width, h - top - (self.framed and SK.WELL_PAD or 0))
        half.content:SetWidth(width)
        half.title:ClearAllPoints()
        if self.framed and half.name == "bag" then
            half.title:SetPoint("TOPLEFT", half.frame, "TOPLEFT", x, -(SK.PLATE_H + 4 + SK.WELL_PAD))
            half.title:SetWidth(width)
        else
            half.title:SetPoint("TOPLEFT", half.frame, "TOPLEFT", 0, 0)
            half.title:SetWidth(self.contentWidth)
        end
        
        half.title:SetShown(not half.noHeading
            and not (self.framed and half.name == "plugin" and half.skin and half.skin.plate))
    end
    plugin.frame:SetShown(show)
    self:ApplyHalfSkin()
end



function FS:SetBottomShown(show)
    show = show and true or false
    if (self.bottomShown ~= false) == show and self.bottomShown ~= nil then
        return
    end
    self.bottomShown = show
    if not show then
        self.activeHalf = "bag"
    end
    self:ApplyHalves()
end

function FS:IsSelected(item)
    local s = self.selected
    return item and s and item.itemID == s.itemID and item.bag == s.bag
        and item.slot == s.slot and item.kind == s.kind
end

function FS:Focusables(region)
    if region == "paperdoll" or region == "armorchest" or region == "stats" or region == "upkeep" then
        return self.Character:Focusables(region)
    end
    if region == "grid" or region == "strip" or region == "bagslots" then
        return self.Bags:Focusables(region)
    end
    if region == "info" then
        return { UI.info }
    end
    return {}
end




function FS:Regions()
    local tab = self.Character.tab
    local list = REGION_LISTS[tab]
    if not list then
        list = {}
        for _, name in ipairs(self.Character:Regions()) do
            list[#list + 1] = name
        end
        for _, name in ipairs(RIGHT_REGIONS) do
            list[#list + 1] = name
        end
        REGION_LISTS[tab] = list
    end
    return list
end

function FS:RegionAvailable(region)
    
    
    
    if region == "stats" or region == "upkeep" then
        return true
    end
    
    if region == "info" then
        return #self:ScrollableHalves() > 0
    end
    return #self:Focusables(region) > 0
end




function FS:ScrollableHalves()
    local list = {}
    for _, name in ipairs({ "bag", "plugin" }) do
        local half = UI.halves[name]
        local shown = name == "bag" or (self.bottomShown ~= false and not self.Actions.panel)
        if shown and half.content:GetHeight() > half.scroll:GetHeight() then
            list[#list + 1] = name
        end
    end
    return list
end

function FS:CurrentRegion()
    local list = self:Regions()
    return list[self.regionIndex or 1] or list[1]
end


function FS:RegionState(region)
    if region == "armorchest" then
        return self.Character.chestScroll
    end
    if region == "stats" or region == "upkeep" then
        return self.Character.listScroll
    end
    if region == "grid" then
        return self.Bags.scroll
    end
    if region == "strip" then
        return self.Bags.stripScroll
    end
    return nil
end

function FS:Columns(region)
    if region == "stats" or region == "upkeep" then
        return 1
    end
    if region == "armorchest" then
        return self.Character.chestScroll.cols
    end
    if region == "grid" then
        return self.Bags.scroll.cols
    end
    
    if region == "strip" then
        return self.Bags.stripScroll.cols
    end
    if region == "bagslots" then
        return math.max(1, #self:Focusables(region))
    end
    return 1
end

function FS:RenderRegion(region)
    if region == "armorchest" then
        self.Character:RenderChest()
    elseif region == "stats" or region == "upkeep" then
        self.Character:RenderList()
    elseif region == "grid" then
        self.Bags:Render()
    elseif region == "strip" then
        self.Bags:RenderStrip()
    end
end

function FS:FocusedEntry()
    return self:Focusables(self:CurrentRegion())[self.focusIndex or 1]
end

function FS:Focused()
    local entry = self:FocusedEntry()
    return entry and entry.item
end





local COLUMN_TITLE = { left = "Character", right = "Bags", info = "Info" }

local COLUMN_EMBLEM = { left = 1, right = 2 }


local function PlateText(parent, point, rel, size)
    local text = parent:CreateFontString(nil, "OVERLAY")
    FS.StyleTitle(text, size)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)
    text:SetPoint(point, rel, point, 0, 0)
    return text
end






function FS:DressPanel(name, panel)
    local Skin = FS.Skin
    local framed = FS.Framed()
    local sk = panel.skin
    if not framed then
        if sk then
            for _, piece in ipairs(sk.pieces) do
                piece:Hide()
            end
            sk.title:Hide()
        end
        return
    end
    if not sk then
        sk = { pieces = {}, corners = {} }
        local function Add(key, piece)
            if piece then
                sk[key] = piece
                sk.pieces[#sk.pieces + 1] = piece
            end
            return piece
        end
        Add("bg", Skin.Piece(panel, "bg_panel", "BACKGROUND", 1))
        Add("frame", Skin.Piece(panel, "frame_panel", "BORDER", 1))
        Add("glow", Skin.Piece(panel, "frame_region_focus", "OVERLAY", 0))
        for _, which in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
            local corner = Skin.Piece(panel, "orn_corner", "OVERLAY", 1)
            if corner then
                corner:Corner(panel, which)
                sk.corners[#sk.corners + 1] = corner
                sk.pieces[#sk.pieces + 1] = corner
            end
        end
        if sk.bg then
            sk.bg:Fill(panel)
        end
        if sk.frame then
            sk.frame:Fill(panel)
        end
        if sk.glow then
            
            sk.glow:Fill(panel, 6, 6, 6, 6)
            sk.glow:Hide()
        end
        
        
        sk.plateHolder = CreateFrame("Frame", nil, panel)
        sk.plateHolder:SetSize(256, 40)
        sk.plateHolder:SetPoint("TOP", panel, "TOP", 0, name == "info" and -10 or -52)
        Add("plate", Skin.Piece(panel, "orn_title_plate", "ARTWORK", 1))
        if sk.plate then
            sk.plate:Fill(sk.plateHolder)
        end
        if COLUMN_EMBLEM[name] then
            
            
            Add("crest", Skin.Piece(panel, "orn_crest", "ARTWORK", 2))
            if sk.crest then
                sk.crest:Place("CENTER", panel, "TOP", 0, 0, 1)
            end
            Add("emblem", Skin.Piece(panel, "orn_emblems", "ARTWORK", 3))
            if sk.emblem then
                sk.emblem:Place("CENTER", panel, "TOP", 0, 0, 1)
                sk.emblem:SetSize(56, 56)
                sk.emblem:Cell(COLUMN_EMBLEM[name])
            end
        end
        
        
        sk.title = PlateText(panel, "CENTER", sk.plateHolder, self:Cfg().textSize + 6)
        sk.title:SetText(COLUMN_TITLE[name])
        panel.skin = sk
    end
    for _, piece in ipairs(sk.pieces) do
        if piece ~= sk.glow then
            piece:Show()
        end
    end
    if sk.bg and panel.w then
        sk.bg:Tile(panel.w, panel.h)
    end
    FS.StyleTitle(sk.title, self:Cfg().textSize + 6)
    
    
    sk.title:SetShown(name == "info" and sk.plate ~= nil)
end



function FS:TitleOnPlate(fontString, panelName, size)
    local panel = UI.panels and UI.panels[panelName]
    local sk = panel and panel.skin
    if not (FS.Framed() and sk and sk.plate and sk.plateHolder) then
        return false
    end
    FS.StyleTitle(fontString, size)
    fontString:SetJustifyH("CENTER")
    fontString:ClearAllPoints()
    fontString:SetPoint("CENTER", sk.plateHolder, "CENTER", 0, 0)
    return true
end




function FS:ApplyHalfSkin()
    if not UI.halves or not UI.infoColumn then
        return
    end
    local Skin = FS.Skin
    local framed = self.framed and FS.Framed()
    for _, half in pairs(UI.halves) do
        if framed and half.skin == nil then
            local sk = {}
            half.wellHolder = CreateFrame("Frame", nil, half.frame)
            half.plateHolder = CreateFrame("Frame", nil, half.frame)
            half.bannerHolder = CreateFrame("Frame", nil, half.content)
            sk.bg = Skin.Piece(half.frame, "bg_well", "BACKGROUND", 1)
            sk.inset = Skin.Piece(half.frame, "frame_inset", "BORDER", 1)
            sk.plate = Skin.Piece(half.frame, "orn_subtitle_plate", "ARTWORK", 1)
            sk.glow = Skin.Piece(half.frame, "frame_region_focus", "OVERLAY", 0)
            sk.banner = Skin.Piece(half.content, "cmp_message_banner", "BACKGROUND", 2)
            sk.bar = Skin.Scrollbar(half.frame)
            if sk.bg then
                sk.bg:Fill(half.wellHolder)
            end
            if sk.inset then
                sk.inset:Fill(half.wellHolder)
            end
            if sk.plate then
                sk.plate:Fill(half.plateHolder)
            end
            if sk.glow then
                sk.glow:Fill(half.wellHolder, 6, 6, 6, 6)
                sk.glow:Hide()
            end
            if sk.banner then
                sk.banner:Fill(half.bannerHolder)
                sk.banner:Hide()
            end
            half.plateText = half.frame:CreateFontString(nil, "OVERLAY")
            half.plateText:SetJustifyH("LEFT")
            half.plateText:SetWordWrap(false)
            half.skin = sk
        end
        local sk = half.skin
        if sk then
            local w = self.contentWidth or 300
            local topH = SK.PLATE_H + 4
            half.wellHolder:ClearAllPoints()
            half.wellHolder:SetPoint("TOPLEFT", half.frame, "TOPLEFT", 0, -topH)
            half.wellHolder:SetPoint("BOTTOMRIGHT", half.frame, "BOTTOMRIGHT", 0, 0)
            half.plateHolder:ClearAllPoints()
            half.plateHolder:SetPoint("TOPLEFT", half.frame, "TOPLEFT", 0, 0)
            half.plateHolder:SetSize(math.min(220, w), SK.PLATE_H)
            local frameH = half.frame:GetHeight() or 0
            for _, key in ipairs({ "bg", "inset", "plate" }) do
                if sk[key] then
                    sk[key]:SetShown(framed)
                end
            end
            if sk.bg then
                sk.bg:Tile(w, math.max(1, frameH - topH))
            end
            if not framed then
                if sk.glow then
                    sk.glow:Hide()
                end
                if sk.banner then
                    sk.banner:Hide()
                end
                if sk.bar then
                    sk.bar.holder:Hide()
                end
            elseif sk.bar then
                local scrollH = half.scroll:GetHeight() or 0
                sk.bar:Anchor(half.frame, w - SK.WELL_PAD - SK.SCROLL_W, -(half.headH or topH), scrollH)
            end
            local size = self:Cfg().textSize
            FS.StyleTitle(half.plateText, math.max(size - 2, 12))
            half.plateText:SetJustifyH("LEFT")
            half.plateText:ClearAllPoints()
            half.plateText:SetPoint("LEFT", half.plateHolder, "LEFT", 24, 0)
            half.plateText:SetWidth(math.min(220, w) - 48)
            half.plateText:SetShown(framed and sk.plate ~= nil)
        end
    end
    
    
    local bottom = self.bottomShown ~= false
    local div = UI.divider
    if framed and div == nil then
        div = {}
        div.holder = CreateFrame("Frame", nil, UI.infoColumn)
        div.line = Skin.Piece(UI.infoColumn, "frame_divider", "ARTWORK", 1)
        div.jewel = Skin.Piece(UI.infoColumn, "orn_divider_jewel", "ARTWORK", 2)
        if div.line then
            div.line:Fill(div.holder)
        end
        if div.jewel then
            div.jewel:Place("CENTER", div.holder, "CENTER", 0, 0, 1)
        end
        UI.divider = div
    end
    if UI.divider then
        div = UI.divider
        local halfH = self.halfHeight or 0
        div.holder:ClearAllPoints()
        div.holder:SetPoint("TOPLEFT", UI.infoColumn, "TOPLEFT", 0, -((self.infoHead or 0) + halfH + (SK.SPLIT_GAP - 12) / 2))
        div.holder:SetSize(self.contentWidth or 300, 12)
        local on = framed and bottom
        if div.line then
            div.line:SetShown(on)
        end
        if div.jewel then
            div.jewel:SetShown(on)
        end
    end
    self:UpdateHalfBars()
end



function FS:SetPlateText(half, text)
    if half.plateText then
        half.plateText:SetText(text or "")
    end
    half.plateName = text
end


function FS:UpdateHalfBar(half)
    local sk = half.skin
    if not (sk and sk.bar and self.framed) then
        return
    end
    local visible = half.scroll:GetHeight() or 0
    local total = half.content:GetHeight() or 0
    sk.bar:Update(half.scroll:GetVerticalScroll() or 0, visible, total)
end

function FS:UpdateHalfBars()
    for _, half in pairs(UI.halves or {}) do
        self:UpdateHalfBar(half)
    end
end






function FS:ApplySkin(sw, sh)
    local Skin = FS.Skin
    local framed = FS.Framed()
    if framed then
        if UI.screen == nil then
            UI.screen = Skin.Piece(UI.frame, "bg_screen", "BACKGROUND", 1) or false
            if UI.screen then
                UI.screen:Fill(UI.frame)
            end
        end
        if UI.screen then
            UI.screen:Tile(sw, sh)
            UI.screen:Show()
        end
    elseif UI.screen then
        UI.screen:Hide()
    end
    for name, panel in pairs(UI.panels) do
        self:DressPanel(name, panel)
    end
    if framed and UI.highlight.glow == nil then
        UI.highlight.glow = Skin.Piece(UI.highlight, "cmp_cell_focus", "OVERLAY", 1) or false
    end
    self:ApplyHalfSkin()
end




function FS.PaintTab(tab, active)
    local framed = FS.Framed()
    if framed then
        if tab.skinTab == nil then
            tab.skinTab = FS.Skin.Piece(tab, "cmp_tab_normal", "BACKGROUND", 1) or false
            if tab.skinTab then
                tab.skinTab:Fill(tab)
            end
        end
        local piece = tab.skinTab
        if piece then
            local drawn = piece:SetState(active and "cmp_tab_active" or "cmp_tab_normal")
            piece:Show()
            
            tab.underline:SetAlpha((active and not drawn) and 1 or 0)
            return
        end
    elseif tab.skinTab then
        tab.skinTab:Hide()
    end
    tab.underline:SetAlpha(1)
end





function FS:GlowColumn()
    if self.Actions and self.Actions.panel then
        return "info"
    end
    return ColumnOf(self:CurrentRegion())
end







function FS:UpdatePanels()
    if not UI.panels or not UI.frame then
        return
    end
    local r, g, b = UI.frame:GetBackdropColor()
    r = math.min(1, (tonumber(r) or 0) + PANEL_LIFT)
    g = math.min(1, (tonumber(g) or 0) + PANEL_LIFT)
    b = math.min(1, (tonumber(b) or 0) + PANEL_LIFT)
    local focused = ColumnOf(self:CurrentRegion())
    local glowOn = self:GlowColumn()
    local ar, ag, ab = AccentColour()
    local framed = FS.Framed()
    for name, panel in pairs(UI.panels) do
        local sk = panel.skin
        local skinned = framed and sk and sk.frame
        panel:SetBackdropColor(r, g, b, (skinned and sk.bg) and 0 or 1)
        if skinned and sk.glow then
            panel.outline:Hide()
            sk.glow:SetShown(name == glowOn)
        elseif skinned then
            
            panel.outline:SetShown(name == glowOn)
            StyleOutline(panel.outline, 2, ar, ag, ab, 1)
        else
            panel.outline:Show()
            if sk and sk.glow then
                sk.glow:Hide()
            end
            if name == focused then
                StyleOutline(panel.outline, 2, ar, ag, ab, 1)
            else
                StyleOutline(panel.outline, 1, PANEL_GREY[1], PANEL_GREY[2], PANEL_GREY[3], PANEL_GREY[4])
            end
        end
    end
end



function FS:UpdateHalfGlow(region)
    local active
    if self.Actions and self.Actions.panel then
        active = "plugin"
    elseif region == "info" then
        active = self.bottomShown ~= false and self.activeHalf or "bag"
    end
    for name, half in pairs(UI.halves) do
        local glow = half.skin and half.skin.glow
        if glow then
            glow:SetShown(FS.Framed() and name == active)
        end
    end
end



function FS:SetRowFocus(row)
    if self.focusRow == row then
        return
    end
    local old = self.focusRow
    self.focusRow = row
    local C = self.Character
    if old and C and C.StyleRow then
        C:StyleRow(old, false)
    end
    if row and C and C.StyleRow then
        C:StyleRow(row, true)
    end
end







function FS:UpdateHighlight()
    if not UI.highlight then
        return
    end
    local region = self:CurrentRegion()
    self:UpdatePanels()
    self:UpdateHalfGlow(region)
    if self.Bags and self.Bags.glyphs then
        FS.SetTabGlyphsLit(self.Bags.glyphs, SideOf(region) == "bag")
    end
    
    if self.Character and self.Character.glyphs then
        FS.SetTabGlyphsLit(self.Character.glyphs, ColumnOf(region) == "left")
    end
    if region == "info" then
        local half = UI.halves[self.bottomShown ~= false and self.activeHalf or "bag"]
        UI.halfOutline:ClearAllPoints()
        UI.halfOutline:SetPoint("TOPLEFT", half.frame, "TOPLEFT", -3, 3)
        UI.halfOutline:SetPoint("BOTTOMRIGHT", half.frame, "BOTTOMRIGHT", 3, -3)
        UI.halfOutline:Show()
    else
        UI.halfOutline:Hide()
    end
    
    
    local halfGlow = false
    for _, half in pairs(UI.halves) do
        if half.skin and half.skin.glow and FS.Framed() then
            halfGlow = true
        end
    end
    UI.halfOutline:SetAlpha(halfGlow and 0 or 1)
    local entry = nil
    if region ~= "info" then
        entry = self:FocusedEntry()
    end
    local cell = entry and entry.cell
    if not cell or not cell:IsShown() then
        UI.highlight:Hide()
        self:SetRowFocus(nil)
        return
    end
    UI.highlight:ClearAllPoints()
    UI.highlight:SetPoint("TOPLEFT", cell, "TOPLEFT", -2, 2)
    UI.highlight:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 2, -2)
    UI.highlight:Show()
    local framed = FS.Framed()
    local isCell = cell.icon ~= nil
    local glow = UI.highlight.glow
    
    
    
    local target = self.Target and self.Target.active
    local tc = target and self.Target.TARGET_COLOR or WHITE_RGB
    StyleOutline(UI.highlight, 2, tc[1], tc[2], tc[3], 1)
    if glow and glow.SetTint then
        glow:SetTint(tc[1], tc[2], tc[3], 1)
    end
    local hideEdges = false
    if framed and isCell and glow then
        glow:Place("CENTER", cell, "CENTER", 0, 0, (cell:GetWidth() or 64) / 64)
        glow:Show()
        hideEdges = true
    elseif glow then
        glow:Hide()
    end
    if framed and not isCell and cell.skinRowOn then
        hideEdges = true
    end
    for _, edge in ipairs(UI.highlight.edges) do
        edge:SetAlpha(hideEdges and 0 or 1)
    end
    self:SetRowFocus(not isCell and cell or nil)
end



local function NewChip(index)
    local chip = {}
    chip.holder = CreateFrame("Frame", nil, UI.footer)
    chip.piece = FS.Skin.Piece(chip.holder, "cmp_hint_chip_normal", "BACKGROUND", 1)
    if chip.piece then
        chip.piece:Fill(chip.holder)
    end
    chip.glyph = chip.holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chip.glyph:SetPoint("LEFT", chip.holder, "LEFT", 6, 0)
    chip.glyph:SetJustifyH("CENTER")
    chip.label = chip.holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chip.label:SetPoint("LEFT", chip.holder, "LEFT", 36, 0)
    chip.label:SetPoint("RIGHT", chip.holder, "RIGHT", -8, 0)
    chip.label:SetJustifyH("LEFT")
    chip.label:SetWordWrap(false)
    return chip
end

local THIN_KEYS = { PADLSHOULDER = true, PADRSHOULDER = true, PADLTRIGGER = true, PADRTRIGGER = true }




function FS:UpdateChips(entries)
    local framed = FS.Framed()
    UI.chips = UI.chips or {}
    local drawn = false
    if framed then
        local size = self:Cfg().textSize
        local w = (self.contentWidth or 300)
        local chipW = math.floor((w - FS.GAP) / 2)
        for i, e in ipairs(entries) do
            local chip = UI.chips[i]
            if not chip then
                chip = NewChip(i)
                UI.chips[i] = chip
            end
            if chip.piece then
                drawn = true
                local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
                chip.holder:ClearAllPoints()
                chip.holder:SetPoint("TOPLEFT", UI.footer, "TOPLEFT", col * (chipW + FS.GAP), -row * (SK.CHIP_H + FS.GAP))
                chip.holder:SetSize(chipW, SK.CHIP_H)
                chip.piece:SetState(e.muted and "cmp_hint_chip_disabled" or (THIN_KEYS[e.key] and "cmp_hint_chip_thin" or "cmp_hint_chip_normal"))
                chip.glyph:SetFont(STANDARD_TEXT_FONT, size)
                chip.glyph:SetText(GlyphText(e.key, e.key))
                chip.label:SetFont(STANDARD_TEXT_FONT, math.max(size - 2, 10))
                chip.label:SetText(e.label)
                chip.label:SetTextColor(e.muted and 0.5 or 1, e.muted and 0.5 or 1, e.muted and 0.5 or 1)
                chip.holder:Show()
            end
        end
    end
    for i = (drawn and #entries or 0) + 1, #UI.chips do
        UI.chips[i].holder:Hide()
    end
    for _, plain in ipairs(UI.legendChips or {}) do
        plain:SetAlpha(drawn and 0 or 1)
    end
end

local CHIP_SPACING = 14





function FS:UpdateLegend()
    if not UI.legendChips or not UI.footer then
        return
    end
    local entries = FS.Legend()
    self.legend = entries
    local rowWidth = UI.legendWidth or 400
    local size = self:Cfg().textSize
    local lineH = size + FS.GAP
    local x, y = 0, 0
    for i, e in ipairs(entries) do
        local chip = UI.legendChips[i]
        if not chip then
            chip = UI.footer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            chip:SetJustifyH("LEFT")
            chip:SetJustifyV("TOP")
            UI.legendChips[i] = chip
        end
        local text = GlyphText(e.key, e.key) .. " " .. e.label
        if e.muted then
            text = "|cff808080" .. text .. "|r"
        end
        chip:SetFont(STANDARD_TEXT_FONT, size)
        chip:SetWordWrap(false)
        chip:SetWidth(1000)
        chip:SetText(text)
        
        
        local w = math.ceil(chip:GetStringWidth()) + 2
        local tall = false
        if w > rowWidth then
            chip:SetWordWrap(true)
            w = rowWidth
            tall = true
        end
        chip:SetWidth(w)
        if x > 0 and x + w > rowWidth then
            x = 0
            y = y + lineH
        end
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", UI.footer, "TOPLEFT", x, -y)
        chip:Show()
        x = x + w + CHIP_SPACING
        if tall then
            
            x = rowWidth
            y = y + math.max(0, (tonumber(chip:GetStringHeight()) or lineH) - lineH)
        end
    end
    for i = #entries + 1, #UI.legendChips do
        UI.legendChips[i]:SetText("")
        UI.legendChips[i]:Hide()
    end
    
    
    self:UpdateChips(entries)
end


function FS:Refocus()
    self:Describe()
    self:UpdateHighlight()
    self:UpdateLegend()
    self.Actions:Sync()
end

function FS:FocusChanged()
    self:HideMessage()
    self:Refocus()
end



local COLUMN_ORDER = { "left", "info", "right" }





function FS:ColumnLanding(column)
    local regions = self:Regions()
    local memory = self.colMemory and self.colMemory[column]
    if memory then
        for i, name in ipairs(regions) do
            
            
            if name == memory.region and ColumnOf(name) == column and self:RegionAvailable(name) then
                local count = #self:Focusables(name)
                return i, math.max(1, math.min(memory.index or 1, count))
            end
        end
    end
    for i, name in ipairs(regions) do
        if ColumnOf(name) == column and self:RegionAvailable(name) then
            return i, 1
        end
    end
    return nil
end



function FS:Cycle(delta)
    local here = self:CurrentRegion()
    local from = 1
    for i, column in ipairs(COLUMN_ORDER) do
        if column == ColumnOf(here) then
            from = i
        end
    end
    self.colMemory = self.colMemory or {}
    self.colMemory[ColumnOf(here)] = { region = here, index = self.focusIndex or 1 }
    for n = 1, #COLUMN_ORDER - 1 do
        local column = COLUMN_ORDER[((from - 1 + delta * n) % #COLUMN_ORDER) + 1]
        local regionIndex, focusIndex = self:ColumnLanding(column)
        if regionIndex then
            self.regionIndex = regionIndex
            self.focusIndex = focusIndex
            local region = self:CurrentRegion()
            if region == "info" then
                self.activeHalf = self:ScrollableHalves()[1] or "bag"
            end
            local state = self:RegionState(region)
            if state and FS.Scroll.Ensure(state, focusIndex) then
                self:RenderRegion(region)
            end
            self:FocusChanged()
            return
        end
    end
end




local function DollTarget(i, row, col, count)
    local target = i
    if col ~= 0 then
        if i >= 17 then
            
            target = math.max(17, i + col)
        else
            
            local pair = (i - 1) % 8
            target = col < 0 and pair + 1 or pair + 9
        end
    elseif row == 1 then
        if i == 8 then
            target = 17
        elseif i == 16 then
            target = 19
        elseif i < 17 then
            target = i + 1
        end
    elseif row == -1 then
        if i >= 17 then
            target = i <= 18 and 8 or 16
        elseif i ~= 1 and i ~= 9 then
            target = i - 1
        end
    end
    return math.max(1, math.min(target, count))
end

local function GridTarget(i, row, col, count, columns)
    local target = i + col + row * columns
    if col ~= 0 then
        local sameRow = math.floor((target - 1) / columns) == math.floor((i - 1) / columns)
        if target < 1 or target > count or not sameRow then
            return i
        end
        return target
    end
    if target < 1 then
        return i
    end
    if target > count then
        
        
        local lastRow = math.floor((count - 1) / columns)
        if row > 0 and lastRow > math.floor((i - 1) / columns) then
            return count
        end
        return i
    end
    return target
end



local function CenterX(entry)
    local cell = entry and entry.cell
    if not cell or not cell.GetCenter then
        return nil
    end
    local ok, x = pcall(cell.GetCenter, cell)
    if ok and type(x) == "number" then
        return x
    end
    return nil
end




local function NearestIndex(entries, indexes, from, fromPlace)
    local fx = CenterX(from)
    local best, bestGap
    if fx then
        for _, i in ipairs(indexes) do
            local x = CenterX(entries[i])
            if x and (not bestGap or math.abs(x - fx) < bestGap) then
                best, bestGap = i, math.abs(x - fx)
            end
        end
    end
    return best or indexes[math.max(1, math.min(fromPlace or 1, #indexes))]
end



local function RowIndexes(window, region, which)
    local count = #window:Focusables(region)
    local cols = window:Columns(region)
    local state = window:RegionState(region)
    local lastItemRow = math.floor((count - 1) / cols)
    local row
    if which == "first" then
        row = state and state.offset or 0
    else
        row = math.min(lastItemRow, state and (state.offset + state.rows - 1) or lastItemRow)
    end
    local out = {}
    for i = row * cols + 1, math.min(count, (row + 1) * cols) do
        out[#out + 1] = i
    end
    return out
end


function FS:GoTo(region, index)
    for i, name in ipairs(self:Regions()) do
        if name == region then
            self.regionIndex = i
        end
    end
    self.focusIndex = index
    local state = self:RegionState(region)
    if state and FS.Scroll.Ensure(state, index) then
        self:RenderRegion(region)
    end
    self:FocusChanged()
end





function FS:Handoff(region, i, row)
    local list = self:Focusables(region)
    local cols = self:Columns(region)
    local myRow = math.floor((i - 1) / cols)
    local lastRow = math.floor((#list - 1) / cols)
    local function Into(target, which)
        local entries = self:Focusables(target)
        if #entries == 0 then
            return nil
        end
        local indexes
        if target == "paperdoll" then
            indexes = {}
            for n = 17, #entries do
                indexes[#indexes + 1] = n
            end
        else
            indexes = RowIndexes(self, target, which)
        end
        return target, NearestIndex(entries, indexes, list[i], (i - 1) % cols + 1)
    end
    if region == "paperdoll" then
        if row > 0 and i >= 17 then
            return Into("armorchest", "first")
        end
    elseif region == "armorchest" then
        if row < 0 and myRow == 0 then
            return Into("paperdoll")
        end
    elseif region == "grid" then
        if row > 0 and myRow == lastRow then
            
            local target, index = Into("strip", "first")
            if not target then
                target, index = Into("bagslots", "first")
            end
            return target, index
        end
    elseif region == "strip" then
        if row > 0 and myRow == lastRow then
            return Into("bagslots", "first")
        elseif row < 0 and myRow == 0 then
            return Into("grid", "last")
        end
    elseif region == "bagslots" then
        if row < 0 then
            local target, index = Into("strip", "last")
            if not target then
                target, index = Into("grid", "last")
            end
            return target, index
        end
    end
    return nil
end


function FS:ScrollInfo(row)
    if row == 0 then
        return
    end
    local half = UI.halves[self.bottomShown ~= false and self.activeHalf or "bag"]
    local step = self:Cfg().textSize + FS.GAP
    local limit = math.max(0, half.content:GetHeight() - half.scroll:GetHeight())
    local target = (half.scroll:GetVerticalScroll() or 0) + row * step
    half.scroll:SetVerticalScroll(math.max(0, math.min(target, limit)))
    self:UpdateHalfBar(half)
end

function FS:Move(row, col)
    local region = self:CurrentRegion()
    if region == "info" then
        self:ScrollInfo(row)
        return
    end
    local list = self:Focusables(region)
    if #list == 0 then
        return
    end
    local old = self.focusIndex or 1
    if row ~= 0 then
        local target, index = self:Handoff(region, old, row)
        if target then
            self:GoTo(target, index)
            return
        end
    end
    local i
    if region == "paperdoll" then
        i = DollTarget(old, row, col, #list)
    else
        i = GridTarget(old, row, col, #list, self:Columns(region))
    end
    self.focusIndex = i
    local state = self:RegionState(region)
    if state and FS.Scroll.Ensure(state, i) then
        self:RenderRegion(region)
    end
    if i ~= old then
        self:FocusChanged()
    end
end

function FS:Select()
    local item = self:Focused()
    
    
    if not item or item.kind == "stat" or item.kind == "upkeep" then
        return
    end
    
    if item.kind == "bagslot" and self.Actions:OpenBagPicker(item) then
        return
    end
    if item.isLocked then
        self:Message("This item is busy")
        return
    end
    if self:IsSelected(item) then
        self.selected = nil
    else
        self.selected = {
            itemID = item.itemID, bag = item.bag, slot = item.slot,
            kind = item.kind, slotName = item.slotName,
        }
    end
    self:Refresh()
end









function FS:Message(text, side)
    
    
    
    side = "bag"
    self.messageGen = (self.messageGen or 0) + 1
    local gen = self.messageGen
    self.messageText = text
    self.messageSide = side
    if UI.halves then
        for name, half in pairs(UI.halves) do
            if name == side then
                half.message:SetFont(STANDARD_TEXT_FONT, self:Cfg().textSize)
                half.message:SetText(text)
                half.message:Show()
            else
                half.message:Hide()
            end
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(4, function()
            if FS.messageGen == gen and FS.messageText then
                FS:HideMessage()
                FS:Describe()
            end
        end)
    end
    self:Describe()
end

function FS:HideMessage()
    self.messageGen = (self.messageGen or 0) + 1
    self.messageText = nil
    self.messageSide = nil
    if UI.halves then
        for _, half in pairs(UI.halves) do
            half.message:Hide()
        end
    end
end

local function GetLine(half, i)
    local line = half.lines[i]
    if not line then
        line = {}
        line.left = half.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        line.left:SetJustifyH("LEFT")
        line.left:SetJustifyV("TOP")
        line.left:SetWordWrap(true)
        line.right = half.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        line.right:SetJustifyH("RIGHT")
        line.right:SetWordWrap(false)
        half.lines[i] = line
    end
    return line
end

local function TooltipData(fn, a, b)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, data = pcall(fn, a, b)
    if ok then
        return data
    end
    return nil
end



function FS:Lines(item)
    if item.kind == "bagslot" then
        return self.Bags:DescribeSlot(item)
    end
    if item.kind == "noammo" then
        return "Ammo", { { leftText = "No ammo in your bags" } }
    end
    if item.kind == "stat" or item.kind == "upkeep" then
        return self.Character:DescribeRow(item)
    end
    local lines
    local title = item.name
    if item.kind == "equip" then
        if item.itemID then
            local data = TooltipData(C_TooltipInfo and C_TooltipInfo.GetInventoryItem, "player", item.slot)
            lines = data and data.lines
        else
            lines = self.Character:describe(item)
            title = lines and lines[1].leftText
        end
    elseif item.bag then
        local data = TooltipData(C_TooltipInfo and C_TooltipInfo.GetBagItem, item.bag, item.slot)
        lines = data and data.lines
    end
    if not lines then
        if item.itemID and C_Item and C_Item.RequestLoadItemData then
            pcall(C_Item.RequestLoadItemData, item.itemID)
        end
        local name = title
        if not name and item.itemID and C_Item and C_Item.GetItemInfo then
            local ok, found = pcall(C_Item.GetItemInfo, item.itemID)
            name = ok and found or nil
        end
        title = name
        lines = { { leftText = name or "Loading..." } }
    end
    if not title and lines[1] then
        title = lines[1].leftText
    end
    return title, lines
end

local function Colour(fontString, color)
    fontString:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
end



local HINT_TOP = "Move onto something to see it here"





function FS.CompareSlots(item)
    if not item or item.kind == "bagslot" or item.kind == "noammo" or item.kind == "equip" then
        return nil
    end
    if not item.bag or not item.slot then
        return nil
    end
    if not (C_Container and C_Container.GetContainerItemLink and C_Item and C_Item.GetItemInfoInstant) then
        return nil
    end
    local ok, link = pcall(C_Container.GetContainerItemLink, item.bag, item.slot)
    if not ok or not link then
        return nil
    end
    
    
    local ok2, _, _, _, equipLoc = pcall(C_Item.GetItemInfoInstant, link)
    if not ok2 or type(equipLoc) ~= "string" or equipLoc == "" then
        return nil
    end
    return ThugUI.EquipSlots and ThugUI.EquipSlots[equipLoc] or nil
end

local function GoldColour()
    return { r = FS.GOLD[1], g = FS.GOLD[2], b = FS.GOLD[3] }
end






local function ComparisonItem(makeLocation, link)
    local guid
    if ItemLocation and C_Item and C_Item.GetItemGUID then
        local okLoc, location = pcall(makeLocation)
        if okLoc and location then
            local okGuid, found = pcall(C_Item.GetItemGUID, location)
            guid = okGuid and found or nil
        end
    end
    local okLink, hyperlink = pcall(link)
    hyperlink = okLink and hyperlink or nil
    if not guid and not hyperlink then
        return nil
    end
    return { guid = guid, hyperlink = hyperlink }
end












local function StatChanges(item, slot)
    if not (item and item.bag and item.slot) then
        return nil
    end
    if not (C_TooltipComparison and C_TooltipComparison.GetItemComparisonDelta) then
        return nil
    end
    local bagItem = ComparisonItem(function()
        return ItemLocation:CreateFromBagAndSlot(item.bag, item.slot)
    end, function()
        return C_Container.GetContainerItemLink(item.bag, item.slot)
    end)
    local wornItem = ComparisonItem(function()
        return ItemLocation:CreateFromEquipmentSlot(slot)
    end, function()
        return GetInventoryItemLink("player", slot)
    end)
    if not (bagItem and wornItem) then
        return nil
    end
    local ok, delta = pcall(C_TooltipComparison.GetItemComparisonDelta, bagItem, wornItem, nil, false)
    if not ok or type(delta) ~= "table" then
        return nil
    end
    local out = {}
    for _, text in ipairs(delta) do
        if type(text) == "string" and text ~= "" then
            out[#out + 1] = text
        end
    end
    return #out > 0 and out or nil
end





function FS:CompareLines(slots, item)
    local lines = {}
    local function AddChanges(slot)
        local changes = StatChanges(item, slot)
        if not changes then
            return
        end
        lines[#lines + 1] = { leftText = _G.ITEM_DELTA_DESCRIPTION
            or "If you replace this item, the following stat changes will occur:", leftColor = GoldColour() }
        for _, text in ipairs(changes) do
            
            
            lines[#lines + 1] = { leftText = text, leftColor = not text:find("|c", 1, true) and { r = 1, g = 1, b = 1 } or nil }
        end
        lines[#lines + 1] = { leftText = "" }
    end
    for i, slot in ipairs(slots) do
        if i > 1 then
            lines[#lines + 1] = { leftText = "" }
        end
        local label = self.Character.SlotLabel(self.Character.SlotName(slot))
        local data = TooltipData(C_TooltipInfo and C_TooltipInfo.GetInventoryItem, "player", slot)
        local worn = data and data.lines
        if worn and #worn > 0 then
            lines[#lines + 1] = { leftText = label, leftColor = GoldColour() }
            AddChanges(slot)
            for _, line in ipairs(worn) do
                lines[#lines + 1] = line
            end
        elseif GetInventoryItemID and GetInventoryItemID("player", slot) then
            
            lines[#lines + 1] = { leftText = label, leftColor = GoldColour() }
            AddChanges(slot)
            lines[#lines + 1] = { leftText = "Loading..." }
        else
            lines[#lines + 1] = { leftText = "Nothing equipped: " .. label, leftColor = FS.MUTED }
        end
    end
    return lines
end





function FS:PlaceMessage(half, width)
    half.message:ClearAllPoints()
    local banner = half.skin and half.skin.banner
    if not half.message:IsShown() then
        if banner then
            banner:Hide()
        end
        half.message:SetPoint("TOPLEFT", half.content, "TOPLEFT", 0, 0)
        return 0
    end
    if not (self.framed and banner) then
        if banner then
            banner:Hide()
        end
        half.message:SetPoint("TOPLEFT", half.content, "TOPLEFT", 0, 0)
        half.message:SetWidth(width)
        return half.message:GetStringHeight() + 8
    end
    local pad = 14
    half.message:SetPoint("TOPLEFT", half.content, "TOPLEFT", pad, -8)
    half.message:SetWidth(width - 2 * pad)
    local height = half.message:GetStringHeight() + 16
    half.bannerHolder:ClearAllPoints()
    half.bannerHolder:SetPoint("TOPLEFT", half.content, "TOPLEFT", 0, 0)
    half.bannerHolder:SetSize(width, height)
    banner:SetTint(0.62, 0.16, 0.13, 1)
    banner:Show()
    return height + 8
end




local function HeadingRepeats(title, lines)
    local first = lines and lines[1] and lines[1].leftText
    if type(title) ~= "string" or type(first) ~= "string" or title == "" then
        return false
    end
    local function stripCodes(text)
        return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    title, first = stripCodes(title), stripCodes(first)
    return first:find(title, 1, true) ~= nil or title:find(first, 1, true) ~= nil
end




function FS:RenderHalf(half, title, lines, key)
    local size = self:Cfg().textSize
    half.title:SetFont(STANDARD_TEXT_FONT, size + 6)
    half.title:SetText(title)
    if half.name == "bag" then
        local repeats = HeadingRepeats(title, lines)
        if repeats ~= (half.noHeading or false) then
            half.noHeading = repeats
            self:ApplyHalves()
        end
    end
    
    self:SetPlateText(half, half.name == "bag" and (self.sourceLabel or "Info") or title)
    if key ~= half.key then
        half.key = key
        half.scroll:SetVerticalScroll(0)
    end

    local width = half.textW or self.contentWidth or 300
    local y = self:PlaceMessage(half, width)
    for i, data in ipairs(lines) do
        local line = GetLine(half, i)
        line.left:SetFont(STANDARD_TEXT_FONT, size)
        line.right:SetFont(STANDARD_TEXT_FONT, size)
        local rightWidth = 0
        line.right:ClearAllPoints()
        if data.rightText and data.rightText ~= "" then
            line.right:SetText(data.rightText)
            Colour(line.right, data.rightColor)
            rightWidth = line.right:GetStringWidth() + 8
            line.right:SetPoint("TOPRIGHT", half.content, "TOPRIGHT", 0, -y)
            line.right:Show()
        else
            line.right:SetText("")
            line.right:Hide()
        end
        line.left:ClearAllPoints()
        line.left:SetPoint("TOPLEFT", half.content, "TOPLEFT", 0, -y)
        line.left:SetWidth(math.max(40, width - rightWidth))
        line.left:SetText(data.leftText or "")
        Colour(line.left, data.leftColor)
        line.left:Show()
        
        
        local height = math.max(line.left:GetStringHeight(), rightWidth > 0 and line.right:GetStringHeight() or 0)
        if height < 1 then
            height = size
        end
        y = y + height + FS.GAP
    end
    for i = #lines + 1, #half.lines do
        half.lines[i].left:Hide()
        half.lines[i].right:Hide()
    end
    half.content:SetHeight(math.max(1, y + 12))
    self:UpdateHalfBar(half)
end




function FS:SourceLabel(item, region, focused)
    if item.kind == "equip" then
        local C = self.Character
        return "Worn: " .. C.SlotLabel(item.slotName or C.SlotName(item.slot))
    elseif item.kind == "stat" then
        return "Stats"
    elseif item.kind == "upkeep" then
        return "Upkeep"
    elseif item.kind == "bagslot" then
        return "Bag slots"
    elseif focused and region == "armorchest" then
        return "Armor chest"
    end
    return "Bags"
end













function FS:Describe()
    if not UI.frame then
        return
    end
    local region = self:CurrentRegion()
    local top
    if region == "info" then
        top = self.topItem
    else
        top = self:Focused()
        local selected = self.selected
        if selected then
            local onBagSide = selected.kind ~= "equip"
            
            
            if (onBagSide == (SideOf(region) == "bag")) and (onBagSide or self.Character.tab == "gear") then
                top = selected
            elseif not top then
                top = selected
            end
        end
        self.topItem = top
    end

    
    local pin = self.pinned
    if pin then
        local now = self.Classify.Read(pin.bag, pin.slot)
        if not now or now.itemID ~= pin.itemID then
            self.pinned = nil
            pin = nil
        end
    end
    
    if region ~= "info" then
        self.sourceLabel = top and self:SourceLabel(top, region, top == self:Focused()) or "Info"
    end
    local panel = self.Actions.panel
    local slots = top and FS.CompareSlots(top) or nil
    self:SetBottomShown(panel ~= nil or pin ~= nil or slots ~= nil)

    local bag = UI.halves.bag
    
    
    local T = self.Target
    local targeting = T and T.active
    if top then
        local title, lines = self:Lines(top)
        lines = lines or {}
        if targeting then
            lines = T:DecorateLines(lines, top)
        end
        self:RenderHalf(bag, title or "Info", lines, ItemKey(top))
    else
        local hint = { { leftText = HINT_TOP, leftColor = FS.MUTED } }
        if targeting then
            hint = T:DecorateLines(hint, nil, true)
        end
        self:RenderHalf(bag, "Info", hint, "hint")
    end

    if panel then
        self.Actions:RenderPanel()
        return
    end
    self.Actions:HidePanel()
    if self.bottomShown == false then
        return
    end
    local plugin = UI.halves.plugin
    if pin then
        self:RenderHalf(plugin, "Equipped (Pinned)", self:CompareLines(FS.CompareSlots(pin) or {}, pin),
            "pinned:" .. tostring(ItemKey(pin)))
    else
        self:RenderHalf(plugin, "Equipped", self:CompareLines(slots or {}, top), "compare:" .. tostring(ItemKey(top)))
    end
end













function FS:SettleEmptyGrid()
    if self:CurrentRegion() ~= "grid" or #self:Focusables("grid") > 0 then
        return false
    end
    for i, name in ipairs(self:Regions()) do
        if (name == "strip" or name == "bagslots") and #self:Focusables(name) > 0 then
            self.regionIndex = i
            self.focusIndex = 1
            return true
        end
    end
    return false
end

function FS:RestoreFocus(region, key)
    if region == "info" then
        return
    end
    local regions = self:Regions()
    local list = self:Focusables(region)
    local index
    if key then
        for i, entry in ipairs(list) do
            if ItemKey(entry.item) == key then
                index = i
                break
            end
        end
    end
    if index then
        self.focusIndex = index
    elseif #list > 0 then
        self.focusIndex = math.max(1, math.min(self.focusIndex or 1, #list))
    elseif region == "stats" or region == "upkeep" then
        
        
        self.focusIndex = 1
        return
    elseif region == "grid" and self:SettleEmptyGrid() then
        
        return
    else
        local start = 1
        for i, name in ipairs(regions) do
            if name == region then
                start = i
            end
        end
        
        
        for n = 1, #regions - 1 do
            local i = ((start - 1 - n) % #regions) + 1
            local earlier = regions[i]
            local entries = earlier ~= "info" and self:Focusables(earlier) or {}
            if #entries > 0 then
                self.regionIndex = i
                self.focusIndex = #entries
                region = earlier
                break
            end
        end
        if #list == 0 and region == regions[start] then
            return
        end
    end
    local state = self:RegionState(region)
    if state and FS.Scroll.Ensure(state, self.focusIndex) then
        self:RenderRegion(region)
    end
end

function FS:Refresh()
    if not UI.frame or not UI.frame:IsShown() then
        return
    end
    local region = self:CurrentRegion()
    local focusKey = ItemKey(self:Focused())
    local old = self.selected
    if old then
        local gone
        if old.bag then
            local present = self.Classify.Read(old.bag, old.slot)
            gone = not present or present.itemID ~= old.itemID
        elseif old.kind == "equip" then
            local id = GetInventoryItemID and GetInventoryItemID("player", old.slot)
            gone = id ~= old.itemID
        end
        if gone then
            self.selected = nil
            self:Message("That item moved or is gone.")
        end
    end
    self.Bags:Refresh()
    self.Character:refresh()
    self:RestoreFocus(region, focusKey)
    self.Actions:Validate()
    self:Refocus()
end

function FS:ScheduleRefresh()
    if self.refreshPending then
        return
    end
    self.refreshPending = true
    Later(function()
        FS.refreshPending = nil
        FS:Refresh()
    end)
end

function FS:RegisterRefresh(on)
    local f = UI.frame
    if not f then
        return
    end
    local events = {
        "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "ITEM_LOCK_CHANGED", "PLAYER_MONEY",
        "ITEM_DATA_LOAD_RESULT", "GET_ITEM_INFO_RECEIVED",
        
        "BAG_UPDATE_COOLDOWN",
        "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED",
    }
    for _, e in ipairs(events) do
        if on then
            ThugUI.SafeRegisterEvent(f, e)
        else
            f:UnregisterEvent(e)
        end
    end
    
    
    
    
    if on then
        pcall(f.RegisterUnitEvent, f, "UNIT_INVENTORY_CHANGED", "player")
        pcall(f.RegisterUnitEvent, f, "UNIT_MODEL_CHANGED", "player")
    else
        f:UnregisterEvent("UNIT_INVENTORY_CHANGED")
        f:UnregisterEvent("UNIT_MODEL_CHANGED")
    end
end







local REPEAT_DELAY = 0.35
local REPEAT_RATE = 0.09
local SWALLOW_LIMIT = 2
local DPAD = { PADDUP = true, PADDDOWN = true, PADDLEFT = true, PADDRIGHT = true }
local WATCHED = {
    "PAD1", "PAD2", "PAD3", "PAD4", "PAD5", "PAD6",
    "PADDUP", "PADDDOWN", "PADDLEFT", "PADDRIGHT",
    "PADLSHOULDER", "PADRSHOULDER", "PADLTRIGGER", "PADRTRIGGER",
    "PADLSTICK", "PADRSTICK", "PADFORWARD", "PADBACK", "PADSYSTEM", "PADSOCIAL",
}




local function ReadHeld()
    local pad = _G.C_GamePad
    if not (pad and pad.GetActiveDeviceID and pad.GetDeviceMappedState and pad.ButtonBindingToIndex) then
        return nil
    end
    local okDevice, device = pcall(pad.GetActiveDeviceID)
    if not okDevice then
        return nil
    end
    local okState, state = pcall(pad.GetDeviceMappedState, device)
    if not okState or type(state) ~= "table" or type(state.buttons) ~= "table" then
        return nil
    end
    local held = {}
    for _, name in ipairs(WATCHED) do
        local okIndex, index = pcall(pad.ButtonBindingToIndex, name)
        if okIndex and type(index) == "number" and state.buttons[index + 1] == true then
            held[name] = true
        end
    end
    return held
end



function FS:StartInput()
    self.held = {}
    self.repeatButton = nil
    local down = ReadHeld()
    if not down then
        if not self.heldApiLogged then
            self.heldApiLogged = true
            Log("held-at-open: the gamepad state could not be read, no button is treated as held")
        end
        down = {}
    end
    self.ignored = down
end





local ABOVE_US_CAP = 30
local ABOVE_US_STRATA = { TOOLTIP = true, FULLSCREEN_DIALOG = true }












function FS:LogGlyphStrings()
    if self.glyphStringsLogged then
        return
    end
    self.glyphStringsLogged = true
    local function Raw(text)
        if type(text) ~= "string" then
            return tostring(text)
        end
        return (text:gsub("|", "||"))
    end
    local PH = ThugUI.PadHints
    for _, key in ipairs({ "PADLSHOULDER", "PADRSHOULDER", "PAD1" }) do
        local ok, glyph = pcall(function() return PH and PH.Glyph and PH.Glyph(key) end)
        Log("glyph %s = %s", key, ok and Raw(glyph) or ("error " .. tostring(glyph)))
    end
    
    
    local probe = UIParent and UIParent.CreateTexture and UIParent:CreateTexture(nil, "BACKGROUND")
    for _, key in ipairs({ "PADLSHOULDER", "PADRSHOULDER" }) do
        local okAtlas, atlas = pcall(function() return PH and PH.GlyphAtlas and PH.GlyphAtlas(key) end)
        local accepted = "no atlas"
        if okAtlas and atlas and probe then
            local okSet, result = pcall(probe.SetAtlas, probe, atlas, false)
            accepted = okSet and ("SetAtlas returned " .. tostring(result)) or ("SetAtlas error " .. tostring(result))
        end
        Log("glyph atlas %s = %s (%s)", key, okAtlas and tostring(atlas) or ("error " .. tostring(atlas)), accepted)
    end
    if probe and probe.Hide then
        probe:Hide()
    end
    Log("ACTION_LABEL_SELECT = %s", Raw(_G.ACTION_LABEL_SELECT))
end

function FS:LogAboveUs()
    if type(EnumerateFrames) ~= "function" then
        Log("above us: EnumerateFrames is missing on this client")
        return 0
    end
    local logged = 0
    local frame = EnumerateFrames()
    while frame do
        local ok, line = pcall(function()
            if frame == UI.frame or (frame.IsForbidden and frame:IsForbidden()) then
                return nil
            end
            if frame.IsVisible and not frame:IsVisible() then
                return nil
            end
            local strata = frame.GetFrameStrata and frame:GetFrameStrata()
            if not ABOVE_US_STRATA[strata] then
                return nil
            end
            local name = frame.GetName and frame:GetName()
            local kind = frame.GetObjectType and frame:GetObjectType()
            local text = string.format("above us: %s (%s) strata %s level %s", tostring(name or "<unnamed>"),
                tostring(kind), tostring(strata), tostring(frame.GetFrameLevel and frame:GetFrameLevel()))
            if frame.GetOwner then
                local okOwner, owner = pcall(frame.GetOwner, frame)
                if okOwner and owner then
                    local ownerName = owner.GetName and owner:GetName()
                    text = text .. " owner " .. tostring(ownerName or "<unnamed>")
                end
            end
            return text
        end)
        if ok and line then
            logged = logged + 1
            Log("%s", line)
            if logged >= ABOVE_US_CAP then
                break
            end
        end
        local okNext, nextFrame = pcall(EnumerateFrames, frame)
        frame = okNext and nextFrame or nil
    end
    return logged
end


local function IsOurs(frame)
    local depth = 0
    while frame and depth < 30 do
        if frame == UI.frame then
            return true
        end
        frame = frame.GetParent and frame:GetParent() or nil
        depth = depth + 1
    end
    return false
end






function FS:InstallTooltipGuard()
    if self.tooltipGuard or not _G.GameTooltip or not _G.GameTooltip.HookScript then
        return
    end
    self.tooltipGuard = true
    local logged = false
    local ok, err = pcall(_G.GameTooltip.HookScript, _G.GameTooltip, "OnShow", function(tip)
        if not UI.frame or not UI.frame:IsShown() then
            return
        end
        local okOwner, owner = pcall(tip.GetOwner, tip)
        if okOwner and owner and IsOurs(owner) then
            return
        end
        if not logged then
            logged = true
            Log("a foreign GameTooltip was hidden while the window was shown (owner %s)",
                tostring(okOwner and owner and owner.GetName and owner:GetName() or "?"))
        end
        tip:Hide()
    end)
    if not ok then
        self.tooltipGuard = nil
        Log("GameTooltip OnShow hook failed: %s", tostring(err))
    end
end

function FS:Open()
    if not self:Active() or self.interacting or not OpenCondition() or (UI.frame and UI.frame:IsShown()) then
        return
    end
    
    
    
    
    
    if InCombatLockdown() or self.Actions.combatSoon then
        Log("in combat: Blizzard's own window left to it")
        return
    end
    if not self:ArmInput() and InCombatLockdown() then
        Log("not opened in combat (input not armed)")
        return
    end
    self:Build()
    PaintBackground(UI.frame)
    self.regionIndex = 1
    self.focusIndex = 1
    
    self.colMemory = {}
    
    self.topItem = nil
    self.activeHalf = "bag"
    self.pinned = nil
    self.bottomShown = true
    
    self.popupUp = nil
    self.Actions:OnClose()
    self:ApplyHalves()
    
    self:EndSwallow()
    self:StartInput()
    self:Layout()
    UI.frame:Show()
    UI.input:Show()
    self:RegisterRefresh(true)
    self:Refresh()
    
    
    local regionIndex, focusIndex = self:ColumnLanding(self:OpeningColumn())
    if regionIndex and regionIndex ~= self.regionIndex then
        self.regionIndex, self.focusIndex = regionIndex, focusIndex
        self:FocusChanged()
    end
    if self.Target then
        
        self.Target:OnOpen(self.openedBy)
    end
    self.openedBy = nil
    
    self.Character:RefreshModel()
    self:LogAboveUs()
    self:LogGlyphStrings()
end




function FS:BeginSwallow(keys)
    if next(keys) == nil or InCombatLockdown() then
        self:EndSwallow()
        return
    end
    self.swallow = { keys = keys, clock = 0 }
end

function FS:EndSwallow()
    self.swallow = nil
    if UI.input and not (UI.frame and UI.frame:IsShown()) then
        UI.input:Hide()
    end
end

function FS:Close(propagate)
    if not UI.frame or not UI.frame:IsShown() then
        return
    end
    
    
    if self.Target then
        self.Target.holdOpen = false
    end
    if propagate and not InCombatLockdown() then
        UI.input:SetPropagateKeyboardInput(true)
        Log("Back out of combat: closed and propagated")
        Later(function()
            if UI.input then
                UI.input:SetPropagateKeyboardInput(false)
            end
        end)
    elseif propagate then
        Log("Back in combat: closed without propagation")
    end
    local carry = {}
    for key in pairs(self.held or {}) do
        carry[key] = true
    end
    for key in pairs(self.ignored or {}) do
        carry[key] = true
    end
    
    
    if propagate and self.pressing then
        carry[self.pressing] = nil
    end
    self.held = {}
    self.ignored = {}
    self.repeatButton = nil
    UI.frame:Hide()
    self.Actions:OnClose()
    self:RegisterRefresh(false)
    self:HideMessage()
    self:BeginSwallow(carry)
end

function FS:Evaluate()
    if not self:Active() or self.interacting then
        return self:Close(false)
    end
    if UI.frame and UI.frame:IsShown() and not OpenCondition() then
        return self:Close(false)
    end
    if not UI.frame or not UI.frame:IsShown() then
        self:Open()
    end
end





function FS:PollPopups(elapsed)
    self.popupClock = (self.popupClock or 0) + (elapsed or 0.1)
    if self.popupClock < 0.1 then
        return
    end
    self.popupClock = 0
    if not UI.frame or not UI.frame:IsShown() then
        return
    end
    
    
    if self.Target then
        self.Target:Poll()
    end
    local up =self.Actions:PollPopup() and true or false
    if up ~= (self.popupUp and true or false) then
        self.popupUp = up
        UI.input:SetShown(not up)
        if up then
            
            
            self.repeatButton = nil
            self.held = {}
            self.ignored = {}
        end
        Log(up and "popup up, pad yielded" or "popup down, pad taken back")
    end
end



function FS:Shoulder(delta)
    local region = self:CurrentRegion()
    if region == "info" then
        
        
        local list = self:ScrollableHalves()
        if #list > 1 then
            self.activeHalf = self.activeHalf == "plugin" and "bag" or "plugin"
        elseif #list == 1 then
            self.activeHalf = list[1]
        end
        self:UpdateHighlight()
    elseif SideOf(region) == "bag" then
        self.Bags:NextTab(delta)
        
        
        if self:SettleEmptyGrid() then
            self:FocusChanged()
        end
    elseif SideOf(region) == "plugin" then
        self.Character:NextTab(delta)
    end
end

function FS:OnButton(button)
    
    if self.Actions:OnPad(button) then
        return
    end
    if button == "PADRTRIGGER" then
        self:Cycle(1)
    elseif button == "PADLTRIGGER" then
        self:Cycle(-1)
    elseif button == "PADRSHOULDER" then
        self:Shoulder(1)
    elseif button == "PADLSHOULDER" then
        self:Shoulder(-1)
    elseif button == "PADDUP" then
        self:Move(-1, 0)
    elseif button == "PADDDOWN" then
        self:Move(1, 0)
    elseif button == "PADDLEFT" then
        self:Move(0, -1)
    elseif button == "PADDRIGHT" then
        self:Move(0, 1)
    elseif button == "PAD1" then
        self:Select()
    elseif button == "PAD3" then
        self.Actions:PressMain()
    elseif button == "PAD4" then
        self.Actions:OpenMenu()
    elseif button == "PAD2" then
        self:Close(true)
    end
end




function FS:OnButtonDown(button)
    if not UI.frame or not UI.frame:IsShown() then
        return
    end
    self.held = self.held or {}
    self.ignored = self.ignored or {}
    if self.ignored[button] then
        return
    end
    
    
    self.Actions:EndPass()
    
    if button == "PAD3" or button == "PAD1" or (button == "PAD2" and self.Target and self.Target.active) then
        self.Actions:LogPress(button)
        
        
        self.Actions:Sync()
    end
    if self.Actions:ShouldPass(button) then
        self.Actions:BeginPass(button)
        return
    end
    self.held[button] = true
    self.pressing = button
    self:OnButton(button)
    self.pressing = nil
    if DPAD[button] and UI.frame:IsShown() then
        self.repeatButton = button
        self.repeatClock = 0
        self.repeatStarted = false
    end
end

function FS:OnButtonUp(button)
    if self.Actions.passing == button then
        
        local actions = self.Actions
        Later(function()
            if actions.passing == button then
                actions:EndPass()
            end
        end)
        return
    end
    
    self.Actions:OnPadUp(button)
    if self.ignored then
        self.ignored[button] = nil
    end
    if self.held then
        self.held[button] = nil
    end
    if self.repeatButton == button then
        self.repeatButton = nil
    end
    if self.swallow then
        self.swallow.keys[button] = nil
        if next(self.swallow.keys) == nil then
            self:EndSwallow()
        end
    end
end



function FS:OnInputUpdate(elapsed)
    self:PollPopups(elapsed)
    elapsed = elapsed or 0
    if self.swallow then
        self.swallow.clock = self.swallow.clock + elapsed
        if self.swallow.clock >= SWALLOW_LIMIT or InCombatLockdown() then
            self:EndSwallow()
        end
        return
    end
    if not self.repeatButton or self.popupUp or not UI.frame or not UI.frame:IsShown() then
        return
    end
    self.repeatClock = (self.repeatClock or 0) + elapsed
    local need = self.repeatStarted and REPEAT_RATE or REPEAT_DELAY
    if self.repeatClock >= need then
        
        self.repeatClock = 0
        self.repeatStarted = true
        self:OnButton(self.repeatButton)
    end
end

local function Hook(frame)
    if not frame or hooked[frame] then
        return
    end
    hooked[frame] = true
    pcall(frame.HookScript, frame, "OnShow", function()
        
        
        FS.openedBy = frame
        Later(function()
            FS:Evaluate()
        end)
    end)
    pcall(frame.HookScript, frame, "OnHide", function()
        Later(function()
            FS:Evaluate()
        end)
    end)
end






function FS:OpeningColumn()
    
    if self.Target and self.Target.active then
        return "right"
    end
    local by = self.openedBy
    if by and (by == _G.ContainerFrameCombinedBags or by == _G.ContainerFrame1) then
        return "right"
    end
    return "left"
end

function FS:InstallHooks()
    Hook(_G.CharacterFrame)
    Hook(_G.ContainerFrameCombinedBags)
    Hook(_G.ContainerFrame1)
    Hook(_G.PaperDollFrame)
    if _G.LootFrame and not self.lootHooked then
        self.lootHooked = true
        pcall(_G.LootFrame.HookScript, _G.LootFrame, "OnShow", function()
            FS:Close(false)
        end)
    end
    if not self.panelCallback then
        self.panelCallback = function(_, frame)
            if frame ~= _G.CharacterFrame then
                FS:Close(false)
            end
        end
    end
    if EventRegistry and EventRegistry.RegisterCallback and not self.panelHooked then
        self.panelHooked = true
        pcall(EventRegistry.RegisterCallback, EventRegistry, "UIParentPanelManager.ShowUIPanel", self.panelCallback, self)
    end
end

local function OnEvent(_, event, unit)
    if event == "PLAYER_LOGIN" then
        FS:ArmInput()
    elseif event == "PLAYER_REGEN_DISABLED" then
        FS.Actions:OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        
        FS:ArmInput()
        FS.Actions:OnCombatEnd()
        FS:ScheduleRefresh()
    elseif event == "UNIT_MODEL_CHANGED" then
        if unit == "player" then
            FS.Character:RefreshModel()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        FS.Character:RefreshModel()
        FS:ScheduleRefresh()
    elseif event == "PLAYER_MONEY" then
        FS.Bags:UpdateMoney()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        
        FS:UpdateCooldowns()
    elseif event == "BAG_UPDATE_DELAYED" then
        
        FS.ClearRefusals()
        FS:ScheduleRefresh()
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        FS.interacting = true
        FS:Close(false)
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        FS.interacting = false
    elseif event == "PLAYER_DEAD" or event == "PLAYER_LEAVING_WORLD" then
        FS:Close(false)
    elseif event == "UNIT_ENTERED_VEHICLE" then
        if unit == "player" then
            FS:Close(false)
        end
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        
        Later(function()
            if UI.frame:IsShown() then
                FS:Layout()
            end
        end)
    else
        FS:ScheduleRefresh()
    end
end

function FS:Initialize()
    self:Cfg()
    self:Build()
    self:InstallHooks()
    self:InstallTooltipGuard()
    if self.Target then
        self.Target:Initialize()
    end
    self.eventFrame = UI.frame
    UI.frame:SetScript("OnEvent", OnEvent)
    local events = {
        "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
        "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", "PLAYER_DEAD", "PLAYER_LEAVING_WORLD",
    }
    for _, event in ipairs(events) do
        ThugUI.SafeRegisterEvent(UI.frame, event)
    end
    pcall(UI.frame.RegisterUnitEvent, UI.frame, "UNIT_ENTERED_VEHICLE", "player")
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("fullscreen", function()
            return UI.frame and UI.frame:IsShown()
        end, function()
            if FS:Cfg().combatClose then
                FS:Close(false)
            end
        end)
    end
    if ThugUI.ControllerMode and ThugUI.ControllerMode.RegisterCallback then
        self.controllerCallback = function()
            if not FS:Active() then
                FS:Close(false)
            end
        end
        ThugUI.ControllerMode:RegisterCallback(self.controllerCallback)
    end
    if ThugUI.PadHints then
        local function Shown()
            return UI.frame and UI.frame:IsShown()
        end
        ThugUI.PadHints:Register{
            id = "fullscreen-regions", group = "GAMEPLAY", text = "Switch side",
            keys = function()
                return ThugUI.PadHints.Glyph("PADLTRIGGER") .. "/" .. ThugUI.PadHints.Glyph("PADRTRIGGER")
            end,
            enabled = Shown,
        }
        
        ThugUI.PadHints:Register{
            id = "fullscreen-dpad", group = "GAMEPLAY", text = "Move inside a column (doll to armor chest, grid to strip)",
            keys = function()
                return ThugUI.PadHints.Glyph("PADDUP") .. "/" .. ThugUI.PadHints.Glyph("PADDDOWN")
            end,
            enabled = Shown,
        }
        ThugUI.PadHints:Register{
            id = "fullscreen-tabs", group = "GAMEPLAY", text = "Tabs (bags, Character)",
            keys = function()
                return ThugUI.PadHints.Glyph("PADLSHOULDER") .. "/" .. ThugUI.PadHints.Glyph("PADRSHOULDER")
            end,
            enabled = Shown,
        }
        
        ThugUI.PadHints:Register{
            id = "fullscreen-main-action", group = "GAMEPLAY", text = "Item: use, equip or unequip",
            keys = function()
                return ThugUI.PadHints.Glyph("PAD3")
            end,
            enabled = Shown,
        }
        ThugUI.PadHints:Register{
            id = "fullscreen-item-menu", group = "GAMEPLAY", text = "Item menu (split, link, compare, destroy)",
            keys = function()
                return ThugUI.PadHints.Glyph("PAD4")
            end,
            enabled = Shown,
        }
        
        
        ThugUI.PadHints:Register{
            id = "fullscreen-halves", group = "GAMEPLAY", text = "Info half (info region)",
            keys = function()
                return ThugUI.PadHints.Glyph("PADLSHOULDER") .. "/" .. ThugUI.PadHints.Glyph("PADRSHOULDER")
            end,
            enabled = Shown,
        }
    end
end
