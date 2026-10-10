













































ThugUI = ThugUI or {}

local GearTrack = {}
ThugUI:RegisterModule("SeasonalGearTrack", GearTrack)

local W  

























local comparisonSaved
local comparisonHooked = false

local function RestoreComparison()
    if type(GameTooltip) ~= "table" then return end
    if comparisonSaved == nil then return end
    GameTooltip.supportsItemComparison = comparisonSaved.value
    comparisonSaved = nil
end

local function SuppressComparison()
    if type(GameTooltip) ~= "table" then return end

    
    
    
    
    
    
    if GameTooltip.supportsItemComparison ~= false then
        comparisonSaved = { value = GameTooltip.supportsItemComparison }
    end
    GameTooltip.supportsItemComparison = false

    
    
    
    
    if not comparisonHooked and type(GameTooltip.HookScript) == "function" then
        comparisonHooked = true
        GameTooltip:HookScript("OnHide", RestoreComparison)
    end
end



GearTrack.SuppressItemComparison = SuppressComparison
GearTrack.RestoreItemComparison = RestoreComparison












































local SEASON_TRACKS = {
    { name = "Adventurer", ranks = { 266, 269, 272, 276, 279, 282 } },
    { name = "Veteran",    ranks = { 279, 282, 285, 289, 292, 295 } },
    { name = "Champion",   ranks = { 292, 295, 298, 302, 305, 308 } },
    { name = "Hero",       ranks = { 305, 308, 311, 315, 318, 321 } },
    { name = "Myth",       ranks = { 318, 321, 324, 328, 331, 334 } },
}
GearTrack.SEASON_TRACKS = SEASON_TRACKS  
    
    

local RANKS_PER_TRACK = 6















local FILL_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local FILL_ALPHA   = 0.28




























function GearTrack.DeriveLayout(tracks)
    local seen, columns = {}, {}
    for _, track in ipairs(tracks) do
        for _, ilvl in ipairs(track.ranks) do
            if not seen[ilvl] then
                seen[ilvl] = true
                columns[#columns + 1] = ilvl
            end
        end
    end
    table.sort(columns)

    local columnOf = {}
    for col, ilvl in ipairs(columns) do
        columnOf[ilvl] = col
    end

    local cellsByColumn = {}
    for trackIndex, track in ipairs(tracks) do
        for rank, ilvl in ipairs(track.ranks) do
            local col = columnOf[ilvl]
            cellsByColumn[col] = cellsByColumn[col] or {}
            table.insert(cellsByColumn[col], {
                trackIndex = trackIndex,
                trackName  = track.name,
                rank       = rank,
                ilvl       = ilvl,
            })
        end
    end

    return {
        columns       = columns,
        columnOf      = columnOf,
        numColumns    = #columns,
        cellsByColumn = cellsByColumn,
    }
end









































local function PaintRowColours(cells)
    local ColorForTrack = ThugUI.Seasonal and ThugUI.Seasonal.ColorForTrack
    for trackIndex, track in ipairs(SEASON_TRACKS) do
        local row = cells.rows[trackIndex]
        if row then
            local r, g, b, a = 0.4, 0.4, 0.4, 0.5
            if type(ColorForTrack) == "function" then
                local ok, cr, cg, cb = pcall(ColorForTrack, track.name)
                if ok and cr then
                    r, g, b, a = cr, cg, cb, 1
                end
            end
            for _, cell in pairs(row) do
                cell:SetBackdropColor(r, g, b, FILL_ALPHA)
                cell:SetBackdropBorderColor(r, g, b, a)
            end
        end
    end
end














































local ROW_LABEL_WIDTH   = 74
local CELL_WIDTH         = 19
local CELL_GAP           = 3
local CELL_HEIGHT        = 16
local HEADER_ROW_HEIGHT  = 24  


local SET_LINE_HEIGHT    = 16
local HEADER_STRIDE      = CELL_WIDTH + CELL_GAP  
local HEADER_TEXT_WIDTH  = 2 * HEADER_STRIDE      
    
    
local SCROLL_STEP         = 40  
    
    















local SET_PIECES_MAX = 4

local SetPiecesText

function SetPiecesText(charRow)
    local sp = charRow and charRow.setPieces
    if type(sp) ~= "table" or type(sp.count) ~= "number" then return nil end
    return string.format("%d/%d", math.min(sp.count, SET_PIECES_MAX), SET_PIECES_MAX), sp.count
end



function GearTrack.SetPiecesTextForTest(charRow)
    return SetPiecesText(charRow)
end









local function CreateCells(body, topInset)
    if body.__gearCells then return body.__gearCells end
    topInset = topInset or 0

    
    
    
    
    if body.text then body.text:Hide() end

    local layout = GearTrack.DeriveLayout(SEASON_TRACKS)
    local gridHeight = HEADER_ROW_HEIGHT + CELL_GAP
        + #SEASON_TRACKS * (CELL_HEIGHT + CELL_GAP)
        + topInset
    local gridWidth = ROW_LABEL_WIDTH + layout.numColumns * CELL_WIDTH
        + math.max(layout.numColumns - 1, 0) * CELL_GAP

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    local available = body:GetWidth() or 0
    local content = body
    local viewport

    if available > 0 and gridWidth > available then
        viewport = CreateFrame("Frame", nil, body)
        viewport:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
        viewport:SetSize(available, gridHeight)
        viewport:SetClipsChildren(true)

        content = CreateFrame("Frame", nil, viewport)
        content:SetSize(gridWidth, gridHeight)
        content:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, 0)

        
        
        
        
        
        
        
        pcall(function()
            viewport:EnableMouseWheel(true)
            viewport:SetScript("OnMouseWheel", function(vp, delta)
                local maxOffset = math.max(gridWidth - available, 0)
                local offset = (vp.__scrollOffset or 0) - delta * SCROLL_STEP
                if offset < 0 then offset = 0 end
                if offset > maxOffset then offset = maxOffset end
                vp.__scrollOffset = offset
                content:SetPoint("TOPLEFT", vp, "TOPLEFT", -offset, 0)
            end)
        end)
    end

    local cells = { headers = {}, rows = {}, rowLabels = {}, layout = layout, scrollViewport = viewport }
    local y = topInset

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    for col = 1, layout.numColumns do
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local centerX = ROW_LABEL_WIDTH + (col - 1) * HEADER_STRIDE + CELL_WIDTH / 2
        
        
        
        local row = (col % 2 == 1) and 1 or 2
        local lineY = (row == 1) and 0 or -(HEADER_ROW_HEIGHT / 2)
        header:SetPoint("TOP", content, "TOPLEFT", centerX, y + lineY)
        header:SetWidth(HEADER_TEXT_WIDTH)
        header:SetJustifyH("CENTER")
        header:SetText(tostring(layout.columns[col]))
        header.column = col
        header.row = row
        cells.headers[col] = header
    end
    y = y - HEADER_ROW_HEIGHT - CELL_GAP

    for trackIndex, track in ipairs(SEASON_TRACKS) do
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        label:SetWidth(ROW_LABEL_WIDTH - CELL_GAP)
        label:SetText(track.name)
        table.insert(cells.rowLabels, label)

        cells.rows[trackIndex] = {}
        for rank = 1, RANKS_PER_TRACK do
            local ilvl = track.ranks[rank]
            local col = layout.columnOf[ilvl]

            local cell = CreateFrame("Frame", nil, content, "BackdropTemplate")
            cell:SetSize(CELL_WIDTH, CELL_HEIGHT)
            cell:SetPoint("TOPLEFT", content, "TOPLEFT",
                ROW_LABEL_WIDTH + (col - 1) * HEADER_STRIDE, y)
            
            
            
            
            
            
            
            cell:SetBackdrop({
                bgFile = FILL_TEXTURE,
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 4,
            })
            
            
            
            
            cell:SetBackdropColor(0.4, 0.4, 0.4, FILL_ALPHA)
            cell:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)

            
            
            
            
            
            
            
            
            
            
            cell.ilvl = ilvl
            cell.trackName = track.name
            cell.rank = rank
            cell.column = col  
                
                

            cells.rows[trackIndex][rank] = cell
        end

        y = y - CELL_HEIGHT - CELL_GAP
    end

    body.__gearCells = cells
    
    
    
    
    
    body:SetHeight(math.abs(y) + 4)
    return cells
end





local function GetItemTexture(slot, link, isCurrent)
    if isCurrent and type(GetInventoryItemTexture) == "function" and type(slot) == "number" then
        local ok, tex = pcall(GetInventoryItemTexture, "player", slot)
        if ok and tex then return tex end
    end
    if link then
        if type(C_Item) == "table" and type(C_Item.GetItemIconByID) == "function" then
            local ok, tex = pcall(C_Item.GetItemIconByID, link)
            if ok and tex then return tex end
        end
        if type(GetItemIcon) == "function" then
            local ok, tex = pcall(GetItemIcon, link)
            if ok and tex then return tex end
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function GearTrack:PaintGearIconsForCharacter(cells, key, isCurrent)
    if not cells or not cells.rows then return end

    cells.iconPool = cells.iconPool or {}
    for _, icon in ipairs(cells.iconPool) do
        icon:Hide()
    end

    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    local character = Data and key and Data:GetCharacter(key)
    if not character or type(character.gear) ~= "table" then return end

    local itemsByCell = {}
    local cellOrder = {}

    for slot = 1, 19 do
        if slot ~= 4 and slot ~= 19 then
            local item = character.gear[slot]
            if type(item) == "table" then
                local targetCell = nil

                if item.track and type(item.rank) == "number" and item.rank >= 1 and item.rank <= 6 then
                    local trackIndex = nil
                    for idx, track in ipairs(SEASON_TRACKS) do
                        if track.name == item.track or track.name:lower() == item.track:lower() then
                            trackIndex = idx
                            break
                        end
                    end
                    if trackIndex and cells.rows[trackIndex] then
                        targetCell = cells.rows[trackIndex][item.rank]
                    end
                end

                if not targetCell and type(item.itemLevel) == "number" then
                    local TrackForItemLevel = (Seasonal and Seasonal.TrackForItemLevel)
                        or (ThugUI.modules and ThugUI.modules.SeasonalVault and ThugUI.modules.SeasonalVault.TrackForItemLevel)
                    if type(TrackForItemLevel) == "function" then
                        local _, trackIndex = TrackForItemLevel(item.itemLevel)
                        if trackIndex and cells.rows[trackIndex] then
                            local bestRank = 1
                            local minDiff = math.huge
                            for r = 1, RANKS_PER_TRACK do
                                local c = cells.rows[trackIndex][r]
                                if c and c.ilvl then
                                    local diff = math.abs(c.ilvl - item.itemLevel)
                                    if diff < minDiff then
                                        minDiff = diff
                                        bestRank = r
                                    end
                                end
                            end
                            targetCell = cells.rows[trackIndex][bestRank]
                        end
                    end
                end

                if targetCell then
                    if not itemsByCell[targetCell] then
                        itemsByCell[targetCell] = {}
                        table.insert(cellOrder, targetCell)
                    end
                    table.insert(itemsByCell[targetCell], item)
                end
            end
        end
    end

    local ICON_SIZE = 12
    local iconIndex = 0

    for _, targetCell in ipairs(cellOrder) do
        local itemList = itemsByCell[targetCell]
        local count = #itemList
        for i, item in ipairs(itemList) do
            iconIndex = iconIndex + 1
            local icon = cells.iconPool[iconIndex]
            if not icon then
                icon = CreateFrame("Button", nil, targetCell)
                icon.tex = icon:CreateTexture(nil, "ARTWORK")
                icon.tex:SetAllPoints()
                cells.iconPool[iconIndex] = icon
            else
                icon:SetParent(targetCell)
            end

            icon:SetSize(ICON_SIZE, ICON_SIZE)
            icon:SetFrameLevel(targetCell:GetFrameLevel() + 2 + i)

            local xOffset = 3.5
            if count > 1 then
                xOffset = 1 + (i - 1) * (14 / (count - 1))
            end
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", targetCell, "TOPLEFT", xOffset, -2)

            local texPath = GetItemTexture(item.slot, item.itemLink, isCurrent)
            icon.tex:SetTexture(texPath)

            local slot = item.slot
            local link = item.itemLink
            icon:SetScript("OnEnter", function(selfFrame)
                if type(GameTooltip) ~= "table" then return end
                GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
                GameTooltip.suppressAutomaticCompareItem = true
                GameTooltip.hideShoppingTooltips = true
                SuppressComparison()
                if type(TooltipComparisonManager) == "table" and type(TooltipComparisonManager.Clear) == "function" then
                    pcall(TooltipComparisonManager.Clear, TooltipComparisonManager, GameTooltip)
                end
                if type(ShoppingTooltip1) == "table" and type(ShoppingTooltip1.Hide) == "function" then
                    ShoppingTooltip1:Hide()
                end
                if type(ShoppingTooltip2) == "table" and type(ShoppingTooltip2.Hide) == "function" then
                    ShoppingTooltip2:Hide()
                end
                if isCurrent and type(GameTooltip.SetInventoryItem) == "function" and slot then
                    local ok = pcall(GameTooltip.SetInventoryItem, GameTooltip, "player", slot)
                    if not ok and link and type(GameTooltip.SetHyperlink) == "function" then
                        pcall(GameTooltip.SetHyperlink, GameTooltip, link)
                    end
                elseif link and type(GameTooltip.SetHyperlink) == "function" then
                    pcall(GameTooltip.SetHyperlink, GameTooltip, link)
                end
                GameTooltip:Show()
            end)

            icon:SetScript("OnLeave", function()
                if type(GameTooltip) == "table" then
                    GameTooltip.suppressAutomaticCompareItem = nil
                    GameTooltip.hideShoppingTooltips = nil
                    RestoreComparison()
                    if type(GameTooltip.Hide) == "function" then
                        GameTooltip:Hide()
                    end
                end
                if type(TooltipComparisonManager) == "table" and type(TooltipComparisonManager.Clear) == "function" then
                    pcall(TooltipComparisonManager.Clear, TooltipComparisonManager, GameTooltip)
                end
                if type(ShoppingTooltip1) == "table" and type(ShoppingTooltip1.Hide) == "function" then
                    ShoppingTooltip1:Hide()
                end
                if type(ShoppingTooltip2) == "table" and type(ShoppingTooltip2.Hide) == "function" then
                    ShoppingTooltip2:Hide()
                end
            end)

            icon:Show()
        end
    end
end






local function SetCellsShown(cells, shown)
    if type(cells) ~= "table" then return end
    if cells.scrollViewport then
        cells.scrollViewport:SetShown(shown)
    end
    if type(cells.rowLabels) == "table" then
        for _, lbl in pairs(cells.rowLabels) do
            lbl:SetShown(shown)
        end
    end
    if type(cells.headers) == "table" then
        for _, h in pairs(cells.headers) do
            h:SetShown(shown)
        end
    end
    if type(cells.rows) == "table" then
        for _, row in pairs(cells.rows) do
            if type(row) == "table" then
                for _, cell in pairs(row) do
                    cell:SetShown(shown)
                end
            end
        end
    end
    if type(cells.iconPool) == "table" then
        for _, icon in pairs(cells.iconPool) do
            if not shown then icon:Hide() end
        end
    end
end

function GearTrack:Render(key)
    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    local entry = Seasonal and Seasonal.sectionFrames and Seasonal.sectionFrames["gear"]
    if not entry or not entry.body then return end
    local body = entry.body

    local roster = Data and Data:GetRoster(Seasonal and Seasonal.selectedCharacterKey) or {}
    local selectedKeys = Seasonal and Seasonal.selectedRosterKeys or {}

    local activeChars = {}
    if key and key ~= Data:GetCurrentKey() and not selectedKeys[key] then
        local charObj = Data and Data:GetCharacter(key) or { key = key, name = key:match("^(.-)-") or key }
        charObj.key = key
        table.insert(activeChars, charObj)
    else
        for _, item in ipairs(roster) do
            local charKey = (type(item) == "table") and item.key or item
            if selectedKeys[charKey] then
                local charObj = Data and Data:GetCharacter(charKey) or { key = charKey, name = charKey:match("^(.-)-") or charKey }
                charObj.key = charKey
                table.insert(activeChars, charObj)
            end
        end
    end

    if #activeChars == 0 then
        key = key or (Data and Data:GetCurrentKey())
        local charObj = Data and key and Data:GetCharacter(key) or { key = key or "Player-Realm", name = UnitName("player") or "Player" }
        charObj.key = charObj.key or key
        table.insert(activeChars, charObj)
    end

    
    if #activeChars <= 1 then
        if self.characterTables then
            for _, c in ipairs(self.characterTables) do c:Hide() end
        end

        local charRow = activeChars[1] or {}
        local charKey = charRow.key or key or (Data and Data:GetCurrentKey())
        if body.__gearCells and body.__gearCells.availableWidth ~= body:GetWidth() then
            SetCellsShown(body.__gearCells, false)
            body.__gearCells = nil
        end
        
        self.cells = body.__gearCells or CreateCells(body, SET_LINE_HEIGHT)

        
        
        
        
        local setLine = body.__setLine
        if not setLine then
            setLine = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            setLine:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
            body.__setLine = setLine
        end
        local setText, rawCount = SetPiecesText(charRow)
        setLine:SetText("Season set: " .. (setText or "0/" .. SET_PIECES_MAX))
        if rawCount and rawCount >= SET_PIECES_MAX then
            setLine:SetTextColor(0.1, 1.0, 0.1)
        else
            setLine:SetTextColor(NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.r or 1,
                NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.g or 0.82,
                NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.b or 0)
        end
        setLine:Show()
        self.cells.availableWidth = body:GetWidth()
        SetCellsShown(self.cells, true)
        self.layout = self.cells.layout
        PaintRowColours(self.cells)
        local isCurrent = (Data ~= nil and charKey ~= nil and charKey == Data:GetCurrentKey())
        self:PaintGearIconsForCharacter(self.cells, charKey, isCurrent)
        Seasonal:RelayoutBody()
        return
    end

    
    if body.__gearCells then
        SetCellsShown(body.__gearCells, false)
    end

    self.characterTables = self.characterTables or {}

    local yOffset = 0
    local TABLE_GAP = 12

    for i, charRow in ipairs(activeChars) do
        local container = self.characterTables[i]
        if not container then
            container = CreateFrame("Frame", nil, body)

            local headerText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            headerText:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            container.headerText = headerText

            local gridHost = CreateFrame("Frame", nil, container)
            gridHost:SetPoint("TOPLEFT", headerText, "BOTTOMLEFT", 0, -4)
            container.gridHost = gridHost

            self.characterTables[i] = container
        end

        container:ClearAllPoints()
        container:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -yOffset)
        container.gridHost:SetWidth(body:GetWidth() > 0 and body:GetWidth() or 560)

        local r, g, b = 0.8, 0.8, 0.8
        if charRow.classFileName and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[charRow.classFileName:upper()] then
            local c = _G.RAID_CLASS_COLORS[charRow.classFileName:upper()]
            r, g, b = c.r, c.g, c.b
        end

        local specStr = charRow.specName or ""
        local ilvlVal = charRow.equippedIlvl or charRow.ilvl or charRow.averageItemLevel
        local ilvlStr = (type(ilvlVal) == "number" and ilvlVal > 0) and string.format("%.1f", ilvlVal) or ""

        local headerLine = charRow.name or charRow.key
        if specStr ~= "" and ilvlStr ~= "" then
            headerLine = headerLine .. " - " .. specStr .. " (iLvl " .. ilvlStr .. ")"
        elseif ilvlStr ~= "" then
            headerLine = headerLine .. " (iLvl " .. ilvlStr .. ")"
        elseif specStr ~= "" then
            headerLine = headerLine .. " - " .. specStr
        end

        
        
        
        
        local setText, rawCount = SetPiecesText(charRow)
        if setText and rawCount and rawCount > 0 then
            headerLine = headerLine .. " 9483 Set " .. setText
        end

        container.headerText:SetText(headerLine)
        container.headerText:SetTextColor(r, g, b)

        container.cells = CreateCells(container.gridHost)
        PaintRowColours(container.cells)

        local isCurrent = (Data ~= nil and charRow.key ~= nil and charRow.key == Data:GetCurrentKey())
        self:PaintGearIconsForCharacter(container.cells, charRow.key, isCurrent)

        if i == 1 then
            self.cells = container.cells
            self.layout = container.cells.layout
        end

        local gridWidth = container.cells.derivedWidth or 550
        local containerHeight = 24 + 160
        container:SetSize(gridWidth, containerHeight)
        container:Show()

        yOffset = yOffset + containerHeight + TABLE_GAP
    end

    for i = #activeChars + 1, #self.characterTables do
        if self.characterTables[i] then
            self.characterTables[i]:Hide()
        end
    end

    body:SetHeight(math.max(40, yOffset - TABLE_GAP))
    Seasonal:RelayoutBody()
end

function GearTrack:Initialize()
    local Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal = Seasonal

    
    
    Seasonal:CreateWindow()
    Seasonal.GearTrack = self

    
    
    
    Seasonal:RegisterRefresh(function(key) self:Render(key) end)

    
    local ok, err = pcall(function() self:Render() end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SEASONAL", "gear track initial render failed: %s", tostring(err))
    end
end

return GearTrack
