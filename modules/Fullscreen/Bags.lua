






local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen
local B = {}
FS.Bags = B

local TABS = { "inventory", "quest", "usable" }


B.TABS = TABS
local TAB_LABELS = { inventory = "Inventory", quest = "Quest", usable = "Usable" }
local EMPTY_BAG = "Interface\\Icons\\INV_Misc_Bag_08"


local COLS = 8
local STRIP_ROWS = 2
local SHORT_MESSAGE = "Bags will refresh after combat"

local function MaxBag()
    return _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4
end




local MAX_GAUGES = 6
local GAUGE_H = 22
local GAUGE_ROW_GAP = 10


function B.GaugeRowCounts(n)
    n = math.min(n or 0, MAX_GAUGES)
    if n <= 0 then
        return {}
    end
    if n <= 3 then
        return { n }
    end
    if n == 4 then
        return { 2, 2 }
    end
    return { 3, n - 3 }
end


function B:GaugeRows()
    return math.max(1, #B.GaugeRowCounts(#(self.space or {})))
end

local function EmptyItems()
    return { inventory = {}, quest = {}, usable = {}, armor = {}, reagent = {}, ammo = {} }
end

function B:Build(column)
    if self.frame then
        return
    end
    self.frame = CreateFrame("Frame", nil, column)
    self.frame:SetAllPoints(column)
    self.cells = {}
    self.strip = {}
    self.slots = {}
    self.tabs = {}
    self.items = EmptyItems()
    self.used = 0
    self.total = 0
    self.entries = { grid = {}, strip = {}, bagslots = {} }
    self.scroll = { offset = 0, rows = 1, cols = COLS }
    
    
    self.stripScroll = { offset = 0, rows = STRIP_ROWS, cols = COLS }
    self.stripList = {}
    self.activeTab = "inventory"
    
    self.cellSize = 48
    self.stripCell = 48
    self.gridTop = 66
    self.stripBottom = 90
    self.slotSize = 28

    self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetText("Bags")
    
    self.money = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.money:SetJustifyH("LEFT")
    self.money:SetWordWrap(false)
    for _, tab in ipairs(TABS) do
        local b = CreateFrame("Frame", nil, self.frame)
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.label:SetAllPoints(b)
        b.underline = b:CreateTexture(nil, "OVERLAY")
        b.underline:SetColorTexture(FS.GOLD[1], FS.GOLD[2], FS.GOLD[3], 1)
        b.underline:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
        b.underline:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
        b.underline:SetHeight(2)
        self.tabs[tab] = b
    end
    
    
    self.spaceRow = CreateFrame("Frame", nil, self.frame)
    self.gauges = {}
    self.slotBar = CreateFrame("Frame", nil, self.frame)
    
    self.glyphs = FS.TabGlyphs(self.frame)
end





local COIN_COLOURS = {
    { "GOLD_AMOUNT_SYMBOL", "ffd70a" },
    { "SILVER_AMOUNT_SYMBOL", "c7c7cf" },
    { "COPPER_AMOUNT_SYMBOL", "eda55f" },
}

local function CoinColour(i)
    local symbol = _G[COIN_COLOURS[i][1] ]
    local hex = type(symbol) == "string" and symbol:match("|c%x%x(%x%x%x%x%x%x)")
    return hex or COIN_COLOURS[i][2]
end




local function GroupThousands(n)
    if type(_G.BreakUpLargeNumbers) == "function" then
        return _G.BreakUpLargeNumbers(n)
    end
    local s = tostring(n)
    local out
    repeat
        s, out = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until out == 0
    return s
end






function B.MoneyText(copper)
    copper = math.floor(tonumber(copper) or 0)
    if copper < 0 then
        copper = 0
    end
    local amounts = { math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100 }
    local parts = {}
    for i = 1, 3 do
        if amounts[i] > 0 or #parts > 0 or i == 3 then
            local text = i == 1 and GroupThousands(amounts[i]) or tostring(amounts[i])
            parts[#parts + 1] = "|cff" .. CoinColour(i) .. text .. "|r"
        end
    end
    return table.concat(parts, " ")
end


function B:UpdateMoney()
    if self.money then
        self.money:SetText(B.MoneyText(GetMoney and GetMoney() or 0))
    end
end




local MONEY_GAP = 10

local function Columns(inner, base, size)
    return math.min(FS.FitCount(inner, size), FS.FitCount(COLS * base + (COLS - 1) * FS.GAP, size))
end









function B:Layout(width, height, size, cell)
    if not self.frame then
        return
    end
    local gap = FS.GAP
    local small = math.max(size - 4, 8)
    local framed = FS.Framed()
    local SK = FS.SK
    local titleH = FS.HeaderHeight(size)
    
    local gridCell = FS:IconSize("iconsGrid", cell)
    local stripCell = FS:IconSize("iconsStrip", cell)
    self.cellSize = gridCell
    self.stripCell = stripCell
    self.framed = framed

    self.title:SetFont(STANDARD_TEXT_FONT, size + 6)
    self.title:ClearAllPoints()
    if not (framed and FS:TitleOnPlate(self.title, "right", size + 6)) then
        self.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    end
    
    
    
    
    
    self.money:SetFont(STANDARD_TEXT_FONT, size)
    self.money:ClearAllPoints()
    local panel = FS.UI and FS.UI.panels and FS.UI.panels.right
    local plate = framed and panel and panel.skin and panel.skin.plate and panel.skin.plateHolder
    local titleW = self.title:GetStringWidth() or 0
    local room
    if plate then
        self.money:SetPoint("LEFT", plate, "RIGHT", MONEY_GAP, 0)
        room = width / 2 - (plate:GetWidth() or 0) / 2
    else
        self.money:SetPoint("LEFT", self.title, "RIGHT", MONEY_GAP, 0)
        room = framed and (width / 2 - titleW / 2) or (width - titleW)
    end
    self.money:SetWidth(math.max(1, math.floor(room - MONEY_GAP)))
    self:UpdateMoney()

    local tabH = FS.TabHeight(size)
    
    local first, last = FS.PlaceTabGlyphs(self.glyphs, self.frame, width, titleH, tabH, size)
    local tabW = math.floor((last - first - (#TABS - 1) * gap) / #TABS)
    for i, tab in ipairs(TABS) do
        local b = self.tabs[tab]
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", self.frame, "TOPLEFT", first + (i - 1) * (tabW + gap), -titleH)
        b:SetSize(tabW, tabH)
        b.label:SetFont(STANDARD_TEXT_FONT, size)
    end

    
    
    local slotCount = MaxBag() + 1
    local barW = framed and (width - 2 * FS.SK.WELL_PAD - 4) or width
    local slotMost = math.floor((barW - 2 * gap * (slotCount - 1)) / slotCount)
    self.slotSize = math.max(8, math.min(math.max(24, math.floor(FS:IconSize("iconsSlots", cell) * 0.6)), slotMost))
    local stripH = STRIP_ROWS * stripCell + (STRIP_ROWS - 1) * gap
    
    
    local inner = framed and (width - 2 * SK.WELL_PAD - SK.SCROLL_W - SK.SCROLL_GAP) or width
    self.scroll.cols = Columns(inner, cell, gridCell)
    self.stripScroll.cols = Columns(inner, cell, stripCell)
    self.stripScroll.rows = STRIP_ROWS
    if not framed then
        self.gridTop = titleH + tabH + 8
        local barH = self.slotSize + small + 4
        self.slotBar:ClearAllPoints()
        self.slotBar:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
        self.slotBar:SetSize(width, barH)
        local rows = self:GaugeRows()
        self.gaugeRows = rows
        local rowH = rows * (small + 8) + (rows - 1) * GAUGE_ROW_GAP
        self.spaceRow:ClearAllPoints()
        self.spaceRow:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, barH + 6)
        self.spaceRow:SetSize(width, rowH)
        self.spaceFont = small
        self.stripBottom = barH + 6 + rowH + 6
        self.cellX0 = 0
        self.stripX0 = 0
        local gridH = height - self.gridTop - self.stripBottom - stripH - 8
        self.scroll.rows = math.max(1, math.floor((gridH + gap) / (gridCell + gap)))
        self.rects = nil
        return
    end

    
    local wp = SK.WELL_PAD
    local barH = self.slotSize + small + 4 + 2 * wp
    local rows = self:GaugeRows()
    self.gaugeRows = rows
    local footerH = rows * GAUGE_H + (rows - 1) * GAUGE_ROW_GAP + 6
    local stripWellH = stripH + 2 * wp
    local footerBottom = barH + 8
    local stripWellBottom = footerBottom + footerH + 8
    local gridWellBottom = stripWellBottom + stripWellH + 24
    local gridWellTop = titleH + tabH + 6
    local gridWellH = math.max(2 * wp + gridCell, height - gridWellBottom - gridWellTop)
    local function FromTop(bottom, h)
        return height - bottom - h
    end
    self.rects = {
        grid = { 0, gridWellTop, width, gridWellH },
        divider = { 0, gridWellTop + gridWellH + 6, width, 12 },
        strip = { 0, FromTop(stripWellBottom, stripWellH), width, stripWellH },
        footer = { 0, FromTop(footerBottom, footerH), width, footerH },
        bar = { 0, FromTop(0, barH), width, barH },
    }
    self.gridTop = gridWellTop + wp
    self.stripBottom = stripWellBottom + wp
    
    local function RowX0(cols, c)
        return wp + math.floor((inner - (cols * c + (cols - 1) * gap)) / 2)
    end
    self.cellX0 = RowX0(self.scroll.cols, gridCell)
    self.stripX0 = RowX0(self.stripScroll.cols, stripCell)
    self.slotBar:ClearAllPoints()
    self.slotBar:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", wp + 2, wp)
    self.slotBar:SetSize(width - 2 * wp - 4, barH - 2 * wp)
    
    self.spaceRow:ClearAllPoints()
    self.spaceRow:SetPoint("LEFT", self.frame, "BOTTOMLEFT", 24, footerBottom + footerH / 2)
    self.spaceRow:SetSize(math.max(40, width - 48), footerH - 6)
    self.spaceFont = small
    self.scroll.rows = math.max(1, math.floor((gridWellH - 2 * wp + gap) / (gridCell + gap)))
end





function B:Skin()
    if not self.frame then
        return
    end
    local framed = FS.Framed() and self.rects ~= nil
    local Skin = FS.Skin
    local SK = FS.SK
    if framed and not self.wells then
        local wells = {}
        local function Well(key)
            local w = { holder = CreateFrame("Frame", nil, self.frame) }
            w.bg = Skin.Piece(self.frame, "bg_well", "BACKGROUND", 1)
            w.inset = Skin.Piece(self.frame, "frame_inset", "BORDER", 1)
            if w.bg then
                w.bg:Fill(w.holder)
            end
            if w.inset then
                w.inset:Fill(w.holder)
            end
            wells[key] = w
        end
        Well("grid")
        Well("strip")
        Well("bar")
        wells.divider = { holder = CreateFrame("Frame", nil, self.frame) }
        wells.divider.line = Skin.Piece(self.frame, "frame_divider", "ARTWORK", 1)
        if wells.divider.line then
            wells.divider.line:Fill(wells.divider.holder)
        end
        
        
        wells.footer = { holder = CreateFrame("Frame", nil, self.frame) }
        wells.footer.bar = Skin.Piece(self.frame, "cmp_footer_bar", "BACKGROUND", 1)
        if wells.footer.bar then
            wells.footer.bar:Fill(wells.footer.holder)
        end
        self.wells = wells
        self.gridBar = Skin.Scrollbar(self.frame)
        self.stripBar = Skin.Scrollbar(self.frame)
    end
    local wells = self.wells
    if not wells then
        return
    end
    for key, w in pairs(wells) do
        local rect = framed and self.rects[key]
        if rect then
            w.holder:ClearAllPoints()
            w.holder:SetPoint("TOPLEFT", self.frame, "TOPLEFT", rect[1], -rect[2])
            w.holder:SetSize(rect[3], rect[4])
        end
        for _, piece in pairs(w) do
            if type(piece) == "table" and piece.parts then
                piece:SetShown(framed)
            end
        end
        if w.bg and framed then
            w.bg:Tile(rect[3], rect[4])
        end
    end
    if framed then
        if self.gridBar then
            local grid = self.rects.grid
            self.gridBar:Anchor(self.frame, grid[3] - SK.WELL_PAD - SK.SCROLL_W, -(grid[2] + SK.WELL_PAD),
                grid[4] - 2 * SK.WELL_PAD)
        end
        if self.stripBar then
            local strip = self.rects.strip
            self.stripBar:Anchor(self.frame, strip[3] - SK.WELL_PAD - SK.SCROLL_W, -(strip[2] + SK.WELL_PAD),
                strip[4] - 2 * SK.WELL_PAD)
        end
        self:UpdateBar()
    else
        
        if self.gridBar and self.gridBar.holder then
            self.gridBar.holder:Hide()
        end
        if self.stripBar and self.stripBar.holder then
            self.stripBar.holder:Hide()
        end
    end
    self:RenderSpace()
end


function B:UpdateBar()
    if not (FS.Framed() and self.rects) then
        return
    end
    if self.gridBar and self.gridBar.holder then
        local total = math.ceil(#self.entries.grid / self.scroll.cols)
        self.gridBar:Update(self.scroll.offset, self.scroll.rows, total)
    end
    if self.stripBar and self.stripBar.holder then
        local total = math.ceil(#self.entries.strip / self.stripScroll.cols)
        self.stripBar:Update(self.stripScroll.offset, self.stripScroll.rows, total)
    end
end





















function B.BagKindName(bag, subtypeOnly)
    local c = _G.C_Container
    local toInv = (c and c.ContainerIDToInventoryID) or _G.ContainerIDToInventoryID
    local okInv, inv = pcall(toInv or error, bag)
    local id = okInv and type(inv) == "number" and GetInventoryItemID and GetInventoryItemID("player", inv)
    local instant = (_G.C_Item and _G.C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if id and instant then
        local ok, _, _, subType = pcall(instant, id)
        if ok and type(subType) == "string" and subType ~= "" then
            return subType
        end
    end
    if subtypeOnly then
        return nil
    end
    local name = c and c.GetBagName and c.GetBagName(bag)
    return (type(name) == "string" and name ~= "") and name or nil
end


function B.BagIcon(bag)
    local c = _G.C_Container
    local toInv = (c and c.ContainerIDToInventoryID) or _G.ContainerIDToInventoryID
    local okInv, inv = pcall(toInv or error, bag)
    local tex = okInv and type(inv) == "number" and GetInventoryItemTexture and GetInventoryItemTexture("player", inv)
    return tex or EMPTY_BAG
end



local function KindKey(bag, family)
    if bag > (_G.NUM_BAG_SLOTS or 4) then
        return "reagent"
    end
    if not family or family == 0 then
        return "plain"
    end
    return tostring(family)
end





local function AddSpace(space, bag, n, used)
    if n <= 0 then
        return
    end
    local family = 0
    if C_Container and C_Container.GetContainerNumFreeSlots then
        local ok, _, fam = pcall(C_Container.GetContainerNumFreeSlots, bag)
        if ok then
            family = tonumber(fam) or 0
        end
    end
    local free = math.max(0, n - used)
    local key = KindKey(bag, family)
    local entry = space.byKey[key]
    if not entry then
        local label = key == "plain" and "Bags" or B.BagKindName(bag)
            or (key == "reagent" and "Reagent bag" or "Special bag")
        entry = { key = key, label = label, free = 0, total = 0, icons = {} }
        space.byKey[key] = entry
        
        space[#space + 1] = entry
    end
    entry.free = entry.free + free
    entry.total = entry.total + n
    
    
    if key == "plain" then
        entry.icons[1] = EMPTY_BAG
    else
        entry.icons[#entry.icons + 1] = B.BagIcon(bag)
    end
end












local GAUGE_GAP = 16
local ICON_BAR_GAP = 4
local FULL_RED = { 0.80, 0.18, 0.12 }

local function MakeGauge(row)
    local g = { icons = {} }
    g.holder = CreateFrame("Frame", nil, row)
    g.bar = CreateFrame("Frame", nil, g.holder)
    
    
    g.fillHolder = CreateFrame("Frame", nil, g.bar)
    g.flatTrack = g.bar:CreateTexture(nil, "BACKGROUND")
    g.flatTrack:SetAllPoints(g.bar)
    g.flatTrack:SetColorTexture(0, 0, 0, 0.55)
    g.flatFill = g.bar:CreateTexture(nil, "ARTWORK")
    g.flatFill:SetAllPoints(g.fillHolder)
    g.label = g.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    g.label:SetJustifyH("LEFT")
    g.label:SetWordWrap(false)
    g.left = g.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    g.left:SetJustifyH("RIGHT")
    return g
end


local function GaugeArt(g)
    if g.artTried then
        return
    end
    g.artTried = true
    local Skin = FS.Skin
    g.track = Skin and Skin.Piece(g.bar, "cmp_progress_bar_track", "BORDER", 1)
    g.fill = Skin and Skin.Piece(g.bar, "cmp_progress_bar_fill", "ARTWORK", 2)
    if g.track then
        g.track:Fill(g.bar)
    end
    if g.fill then
        g.fill:Fill(g.fillHolder)
    end
end

local function GaugeIcon(g, i)
    local t = g.icons[i]
    if not t then
        t = g.holder:CreateTexture(nil, "ARTWORK", nil, math.min(i, 7))
        g.icons[i] = t
    end
    return t
end


function B.GaugeWords(e)
    if e.free <= 0 then
        return e.label, "Full"
    end
    return e.label, e.free .. " left"
end


function B:RenderSpace()
    local row = self.spaceRow
    if not row then
        return
    end
    local space = self.space or {}
    local rowW, rowH = row:GetWidth() or 0, row:GetHeight() or 0
    local font = self.spaceFont or 10
    local framed = FS.Framed() and self.rects ~= nil
    local counts = B.GaugeRowCounts(#space)
    local nRows = math.max(1, #counts)
    local gaugeH = math.max(8, math.floor((rowH - (nRows - 1) * GAUGE_ROW_GAP) / nRows))
    local iconSize = gaugeH
    local step = math.floor(iconSize / 2)
    local shown = 0
    for r, perRow in ipairs(counts) do
        
        local w = math.floor((rowW - (perRow - 1) * GAUGE_GAP) / perRow)
        local y = (r - 1) * (gaugeH + GAUGE_ROW_GAP)
        for c = 1, perRow do
            shown = shown + 1
            local i = shown
            local e = space[i]
            local x = (c - 1) * (w + GAUGE_GAP)
            local g = self.gauges[i] or MakeGauge(row)
            self.gauges[i] = g
            local n = math.max(1, #e.icons)
            e.iconsW = iconSize + (n - 1) * step
            local barW = math.max(24, w - e.iconsW - ICON_BAR_GAP)
            g.holder:ClearAllPoints()
            g.holder:SetPoint("TOPLEFT", row, "TOPLEFT", x, -y)
            g.holder:SetSize(w, gaugeH)
            g.holder:Show()
            
            for j, tex in ipairs(e.icons) do
                local t = GaugeIcon(g, j)
                t:SetTexture(tex)
                t:ClearAllPoints()
                t:SetPoint("LEFT", g.holder, "LEFT", (j - 1) * step, 0)
                t:SetSize(iconSize, iconSize)
                t:Show()
            end
            for j = #e.icons + 1, #g.icons do
                g.icons[j]:Hide()
            end
            
            local barH = math.max(8, gaugeH - 4)
            g.bar:ClearAllPoints()
            g.bar:SetPoint("LEFT", g.holder, "LEFT", e.iconsW + ICON_BAR_GAP, 0)
            g.bar:SetSize(barW, barH)
            local used = math.max(0, e.total - e.free)
            local frac = e.total > 0 and math.min(1, used / e.total) or 0
            local fillW = math.floor(barW * frac)
            g.fillW = fillW
            g.fillHolder:ClearAllPoints()
            g.fillHolder:SetPoint("LEFT", g.bar, "LEFT", 0, 0)
            g.fillHolder:SetSize(math.max(fillW, 1), barH)
            local c = e.free <= 0 and FULL_RED or FS.GOLD
            if framed then
                GaugeArt(g)
            end
            local art = (framed and g.track and g.fill) and true or false
            if g.track then
                g.track:SetShown(art)
            end
            if g.fill then
                g.fill:SetTint(c[1], c[2], c[3], 1)
                
                g.fill:SetShown(art and fillW >= 16)
            end
            g.flatTrack:SetShown(not art)
            g.flatFill:SetColorTexture(c[1], c[2], c[3], 0.85)
            g.flatFill:SetShown(not art and fillW >= 1)
            
            local name, left = B.GaugeWords(e)
            g.label:SetFont(STANDARD_TEXT_FONT, font, "OUTLINE")
            g.left:SetFont(STANDARD_TEXT_FONT, font, "OUTLINE")
            g.left:SetText(left)
            g.left:ClearAllPoints()
            g.left:SetPoint("RIGHT", g.bar, "RIGHT", -6, 0)
            local leftW = (g.left.GetStringWidth and g.left:GetStringWidth()) or 0
            if type(leftW) ~= "number" then
                leftW = 0
            end
            g.label:SetText(name)
            g.label:ClearAllPoints()
            g.label:SetPoint("LEFT", g.bar, "LEFT", 6, 0)
            g.label:SetWidth(math.max(1, barW - 12 - leftW - 6))
            g.entry = e
        end
    end
    for i = shown + 1, #self.gauges do
        self.gauges[i].holder:Hide()
    end
end

function B:Collect()
    self.items = EmptyItems()
    self.space = { byKey = {} }
    local used = 0
    local total = 0
    for bag = 0, MaxBag() do
        local n = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag)) or 0
        total = total + n
        local inBag = 0
        for slot = 1, n do
            local info = FS.Classify.Read(bag, slot)
            if info then
                used = used + 1
                inBag = inBag + 1
                local place = FS.Classify.Place(info)
                local list = self.items[place]
                list[#list + 1] = info
            end
        end
        AddSpace(self.space, bag, n, inBag)
    end
    self.used = used
    self.total = total
end



local function StripItems(items)
    local list = {}
    local byID = {}
    for _, group in ipairs({ items.reagent, items.ammo }) do
        for _, item in ipairs(group) do
            local rep = item.itemID and byID[item.itemID]
            if rep then
                rep.stackCount = rep.stackCount + (item.stackCount or 1)
            else
                rep = {}
                for k, v in pairs(item) do
                    rep[k] = v
                end
                rep.stackCount = item.stackCount or 1
                if item.itemID then
                    byID[item.itemID] = rep
                end
                list[#list + 1] = rep
            end
        end
    end
    local ranged = GetInventoryItemID and GetInventoryItemID("player", 18)
    if ranged and #items.ammo == 0 then
        local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", 0)
        if not texture then
            local ok, _, empty = pcall(GetInventorySlotInfo, "AmmoSlot")
            texture = ok and empty or nil
        end
        list[#list + 1] = { kind = "noammo", name = "Ammo", iconFileID = texture, alpha = 0.35 }
    end
    return list
end



function B:Render()
    local state = self.scroll
    local entries = self.entries.grid
    local gap = FS.GAP
    local first = state.offset * state.cols + 1
    local last = math.min(#entries, first + state.rows * state.cols - 1)
    local needed = math.max(0, last - first + 1)
    local usable, short = FS.EnsurePool(self.cells, needed, self.frame)
    for _, entry in ipairs(entries) do
        entry.cell = nil
    end
    local shown = 0
    for i = first, last do
        local k = i - first + 1
        if k > usable then
            break
        end
        local cell = self.cells[k]
        local step = self.cellSize + gap
        cell:ClearAllPoints()
        cell:SetSize(self.cellSize, self.cellSize)
        cell:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (self.cellX0 or 0) + ((k - 1) % state.cols) * step,
            -(self.gridTop + math.floor((k - 1) / state.cols) * step))
        FS.PaintCell(cell, entries[i].item)
        entries[i].cell = cell
        shown = k
    end
    for k = shown + 1, #self.cells do
        self.cells[k]:Hide()
        self.cells[k].item = nil
    end
    self:UpdateBar()
    return short
end





function B:RenderStrip(list)
    if list then
        self.stripList = list
        self.entries.strip = {}
        for i, item in ipairs(list) do
            self.entries.strip[i] = { item = item }
        end
        FS.Scroll.Clamp(self.stripScroll, #list)
    end
    local entries = self.entries.strip
    local state = self.stripScroll
    local gap = FS.GAP
    local first = state.offset * state.cols + 1
    local last = math.min(#entries, first + state.rows * state.cols - 1)
    local needed = math.max(0, last - first + 1)
    local usable, short = FS.EnsurePool(self.strip, needed, self.frame)
    for _, entry in ipairs(entries) do
        entry.cell = nil
    end
    local size = self.stripCell or self.cellSize
    local step = size + gap
    local shown = 0
    for i = first, last do
        local k = i - first + 1
        if k > usable then
            break
        end
        local cell = self.strip[k]
        local row = math.floor((k - 1) / state.cols)
        cell:ClearAllPoints()
        cell:SetSize(size, size)
        
        cell:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", (self.stripX0 or self.cellX0 or 0) + ((k - 1) % state.cols) * step,
            self.stripBottom + (STRIP_ROWS - 1 - row) * step)
        FS.PaintCell(cell, entries[i].item)
        entries[i].cell = cell
        shown = k
    end
    for k = shown + 1, #self.strip do
        self.strip[k]:Hide()
        self.strip[k].item = nil
    end
    self:UpdateBar()
    return short
end

function B:RenderSlots()
    local gap = FS.GAP
    local small = math.max(FS:Cfg().textSize - 4, 8)
    local count = MaxBag() + 1
    local usable, short = FS.EnsurePool(self.slots, count, self.slotBar)
    self.entries.bagslots = {}
    for bag = 0, math.min(count, usable) - 1 do
        local cell = self.slots[bag + 1]
        local slots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag)) or 0
        local id = C_Container and C_Container.ContainerIDToInventoryID and C_Container.ContainerIDToInventoryID(bag)
        local texture = id and GetInventoryItemTexture and GetInventoryItemTexture("player", id)
        local item = {
            kind = "bagslot", bag = bag, slots = slots,
            iconFileID = texture or EMPTY_BAG, empty = slots == 0,
        }
        if not cell.under then
            cell.under = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cell.under:SetPoint("TOP", cell, "BOTTOM", 0, -2)
        end
        cell.under:SetFont(STANDARD_TEXT_FONT, small)
        cell.under:SetText(slots)
        cell:ClearAllPoints()
        cell:SetSize(self.slotSize, self.slotSize)
        cell:SetPoint("TOPLEFT", self.slotBar, "TOPLEFT", bag * (self.slotSize + 2 * gap), 0)
        FS.PaintCell(cell, item)
        self.entries.bagslots[bag + 1] = { item = item, cell = cell }
    end
    return short
end



function B:Update()
    if not self.frame then
        return
    end
    
    
    if self.gaugeRows and self.gaugeRows ~= self:GaugeRows() and FS.Layout then
        FS:Layout()
    end
    local tab = self.activeTab or "inventory"
    local list = self.items[tab] or {}
    for name, button in pairs(self.tabs) do
        local count = #(self.items[name] or {})
        button.label:SetText(TAB_LABELS[name] .. " (" .. count .. ")")
        button.label:SetAlpha(name == tab and 1 or (count == 0 and 0.35 or 0.65))
        button.underline:SetShown(name == tab)
        FS.PaintTab(button, name == tab)
    end
    self.entries.grid = {}
    for i, item in ipairs(list) do
        self.entries.grid[i] = { item = item }
    end
    FS.Scroll.Clamp(self.scroll, #list)
    local short = self:Render()
    if self:RenderStrip(StripItems(self.items)) then
        short = true
    end
    self:RenderSpace()
    self:UpdateMoney()
    if self:RenderSlots() then
        short = true
    end
    if short then
        FS:Message(SHORT_MESSAGE, "bag")
    end
end

function B:Refresh()
    if not self.frame then
        return
    end
    self:Collect()
    self:Update()
end

function B:Focusables(region)
    return self.entries and self.entries[region] or {}
end



function B:DescribeSlot(item)
    local bag = item.bag
    local name = C_Container and C_Container.GetBagName and C_Container.GetBagName(bag)
    if not name or name == "" then
        name = bag == 0 and "Backpack" or ("Bag " .. bag)
    end
    local free = 0
    local family = 0
    if C_Container and C_Container.GetContainerNumFreeSlots then
        local ok, f, fam = pcall(C_Container.GetContainerNumFreeSlots, bag)
        if ok then
            free = f or 0
            family = fam or 0
        end
    end
    local slots = C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag)
    slots = slots or item.slots or 0
    
    
    local kind = family == 0 and "Bag" or ((B.BagKindName(bag, true) or "Special bag") .. ": holds only its own kind")
    local lines = {
        { leftText = name },
        { leftText = slots .. " slots, " .. free .. " free" },
        { leftText = kind },
    }
    
    
    if bag >= 1 and bag <= (_G.NUM_BAG_SLOTS or 4) then
        lines[#lines + 1] = { leftText = "A: choose a bag" }
    end
    return name, lines
end

function B:NextTab(delta)
    local p = 1
    for i, v in ipairs(TABS) do
        if v == self.activeTab then
            p = i
        end
    end
    self.activeTab = TABS[((p - 1 + delta) % #TABS) + 1]
    self.scroll.offset = 0
    
    
    if FS:CurrentRegion() == "grid" then
        FS.focusIndex = 1
    end
    self:Update()
    FS:Refocus()
end



function B:SetTab(name)
    local known
    for _, v in ipairs(TABS) do
        if v == name then
            known = true
        end
    end
    if not known or self.activeTab == name then
        return false
    end
    self.activeTab = name
    self.scroll.offset = 0
    if FS:CurrentRegion() == "grid" then
        FS.focusIndex = 1
    end
    self:Update()
    FS:Refocus()
    return true
end
