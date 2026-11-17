






local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen
local B = {}
FS.Bags = B

local TABS = { "inventory", "quest", "usable" }
local TAB_LABELS = { inventory = "Inventory", quest = "Quest", usable = "Usable" }
local EMPTY_BAG = "Interface\\Icons\\INV_Misc_Bag_08"


local COLS = 8
local STRIP_ROWS = 2
local SHORT_MESSAGE = "Bags will refresh after combat"

local function MaxBag()
    return _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4
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
    self.counts = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.slotBar = CreateFrame("Frame", nil, self.frame)
    
    self.glyphs = FS.TabGlyphs(self.frame)
end




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
        self.counts:SetFont(STANDARD_TEXT_FONT, small)
        self.counts:ClearAllPoints()
        self.counts:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, barH + 6)
        self.stripBottom = barH + 6 + small + 4 + 6
        self.cellX0 = 0
        self.stripX0 = 0
        local gridH = height - self.gridTop - self.stripBottom - stripH - 8
        self.scroll.rows = math.max(1, math.floor((gridH + gap) / (gridCell + gap)))
        self.rects = nil
        return
    end

    
    local wp = SK.WELL_PAD
    local barH = self.slotSize + small + 4 + 2 * wp
    local footerH = 28
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
    self.counts:SetFont(STANDARD_TEXT_FONT, small)
    self.counts:ClearAllPoints()
    self.counts:SetPoint("LEFT", self.frame, "BOTTOMLEFT", 28, footerBottom + footerH / 2)
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
        wells.footer.track = Skin.Piece(self.frame, "cmp_progress_bar_track", "ARTWORK", 1)
        wells.footer.fill = Skin.Piece(self.frame, "cmp_progress_bar_fill", "ARTWORK", 2)
        wells.footer.meter = CreateFrame("Frame", nil, self.frame)
        wells.footer.fillHolder = CreateFrame("Frame", nil, self.frame)
        if wells.footer.bar then
            wells.footer.bar:Fill(wells.footer.holder)
        end
        if wells.footer.track then
            wells.footer.track:Fill(wells.footer.meter)
        end
        if wells.footer.fill then
            wells.footer.fill:Fill(wells.footer.fillHolder)
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
        
        wells.footer.meter:ClearAllPoints()
        wells.footer.meter:SetPoint("RIGHT", wells.footer.holder, "RIGHT", -24, 0)
        wells.footer.meter:SetSize(96, 20)
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
        self:UpdateMeter()
        self:UpdateBar()
    else
        
        if self.gridBar and self.gridBar.holder then
            self.gridBar.holder:Hide()
        end
        if self.stripBar and self.stripBar.holder then
            self.stripBar.holder:Hide()
        end
    end
end



function B:UpdateMeter()
    local footer = self.wells and self.wells.footer
    if not (footer and footer.fill and FS.Framed() and self.rects) then
        return
    end
    local frac = self.total > 0 and math.min(1, self.used / self.total) or 0
    local w = math.floor(96 * frac)
    footer.fill:SetTint(FS.GOLD[1], FS.GOLD[2], FS.GOLD[3], 1)
    footer.meterWidth = w
    footer.fill:SetShown(w >= 16)
    footer.fillHolder:ClearAllPoints()
    footer.fillHolder:SetPoint("LEFT", footer.meter, "LEFT", 0, 0)
    footer.fillHolder:SetSize(math.max(w, 1), 20)
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

function B:Collect()
    self.items = EmptyItems()
    local used = 0
    local total = 0
    for bag = 0, MaxBag() do
        local n = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag)) or 0
        total = total + n
        for slot = 1, n do
            local info = FS.Classify.Read(bag, slot)
            if info then
                used = used + 1
                local place = FS.Classify.Place(info)
                local list = self.items[place]
                list[#list + 1] = info
            end
        end
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
    local armor = #self.items.armor
    self.counts:SetText(string.format("%d of %d slots used%s", self.used, self.total,
        armor > 0 and (", " .. armor .. " by armor chest") or ""))
    self:UpdateMeter()
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
    local kind = family == 0 and "Bag" or ("Special bag (family " .. family .. ")")
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
