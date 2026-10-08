




































ThugUI = ThugUI or {}

local RewardTables = {}
ThugUI:RegisterModule("SeasonalRewardTables", RewardTables)

local W  


local FILL_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local FILL_ALPHA   = 0.28







local MPLUS_DATA = {
    { "Heroic",         { "Adventurer", 4 }, "Veteran",   { "Veteran",   4 } },
    { "Mythic 0",       { "Champion",   1 }, "Champion", { "Champion",   4 } },
    { "+2",             { "Champion",   2 }, "Champion", { "Hero",       1 } },
    { "+3",             { "Champion",   2 }, "Champion", { "Hero",       1 } },
    { "+4",             { "Champion",   3 }, "Hero",     { "Hero",       2 } },
    { "+5",             { "Champion",   4 }, "Hero",     { "Hero",       2 } },
    { "+6",             { "Hero",       1 }, "Hero",     { "Hero",       3 } },
    { "+7",             { "Hero",       1 }, "Hero",     { "Hero",       4 } },
    { "+8",             { "Hero",       2 }, "Hero",     { "Hero",       4 } },
    { "+9",             { "Hero",       2 }, "Myth",     { "Hero",       4 } },
    { "+10",            { "Hero",       3 }, "Myth",     { "Myth",       1 } },
    { "+11",            { "Hero",       3 }, "Myth",     { "Myth",       1 } },
    { "+12 and higher", { "Hero",       3 }, "Myth",     { "Myth",       1 } },
}


RewardTables.MPLUS_DATA = MPLUS_DATA








local DELVE_DATA = {
    { 1,  { "Adventurer", 1 }, nil,                 { "Veteran",   1 } },
    { 2,  { "Adventurer", 2 }, nil,                 { "Veteran",   2 } },
    { 3,  { "Adventurer", 3 }, nil,                 { "Veteran",   3 } },
    { 4,  { "Adventurer", 4 }, { "Veteran",   2 },  { "Veteran",   4 } },
    { 5,  { "Veteran",    1 }, { "Veteran",   4 },  { "Champion",  1 } },
    { 6,  { "Veteran",    2 }, { "Champion",  2 },  { "Champion",  3 } },
    { 7,  { "Champion",   1 }, { "Champion",  4 },  { "Champion",  4 } },
    { 8,  { "Champion",   2 }, { "Hero",      1 },  { "Hero",      1 } },
    { 9,  { "Champion",   2 }, { "Hero",      1 },  { "Hero",      1 } },
    { 10, { "Champion",   2 }, { "Hero",      1 },  { "Hero",      1 } },
    { 11, { "Champion",   2 }, { "Hero",      1 },  { "Hero",      1 } },
}
RewardTables.DELVE_DATA = DELVE_DATA










local PREY_DATA = {
    { "Normal",    { "Adventurer", 1 }, { "Veteran",  1 }, "Fresh level-90 gear and outdoor progress" },
    { "Hard",      { "Veteran",    1 }, { "Champion", 1 }, "Alts and Champion-track bridge" },
    { "Nightmare", { "Champion",   1 }, { "Hero",     1 }, "Highest Prey Vault target and later Venomstone sources" },
}
RewardTables.PREY_DATA = PREY_DATA














local RAID_DATA = {
    { "LFR",     { "Veteran",  1 }, { "Champion", 1 } },
    { "Normal",  { "Champion", 1 }, { "Hero",     1 } },
    { "Heroic",  { "Hero",     1 }, { "Myth",     1 } },
    { "Mythic",  { "Myth",     1 }, { "Myth",     6 } },
}
RewardTables.RAID_DATA = RAID_DATA












local WORLD_DATA = {
    { "Repeatable outdoor events", "Adventurer" },
    { "Outdoor events",            "Veteran" },
    { "Weekly outdoor events",     "Champion" },
}
RewardTables.WORLD_DATA = WORLD_DATA





local function GetItemLevelForTrackAndRank(trackName, rank)
    local GearTrack = ThugUI.Seasonal and ThugUI.Seasonal.GearTrack
    local tracks = GearTrack and GearTrack.SEASON_TRACKS
    if not tracks then return nil end

    for _, track in ipairs(tracks) do
        if track.name == trackName then
            return track.ranks[rank]
        end
    end
    return nil
end





local function GetTrackColour(trackName)
    local ColorForTrack = ThugUI.Seasonal and ThugUI.Seasonal.ColorForTrack
    if type(ColorForTrack) == "function" then
        local ok, r, g, b = pcall(ColorForTrack, trackName)
        if ok and r then
            return r, g, b
        end
    end
    
    return 0.5, 0.5, 0.5
end










local function RecordGrid(frame, rowIndex, columnKey, entry)
    if not rowIndex or not columnKey then return end
    frame.__grid[rowIndex] = frame.__grid[rowIndex] or {}
    frame.__grid[rowIndex][columnKey] = entry
end





local function CreateTooltipFrame()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetFrameStrata("TOOLTIP")
    frame:SetToplevel(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = 4,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.1, 0.9)
    frame:SetBackdropBorderColor(1, 1, 1, 0.6)
    frame:Hide()
    return frame
end








local function PaintRewardTable(frame, data, mode)
    
    for i = 1, #(frame.__fontStrings or {}) do
        frame.__fontStrings[i]:Hide()
    end
    for i = 1, #(frame.__cells or {}) do
        frame.__cells[i]:Hide()
    end
    frame.__fontStrings = {}
    frame.__cells = {}
    frame.__grid = {}

    local GearTrack = ThugUI.Seasonal and ThugUI.Seasonal.GearTrack
    if not GearTrack or not GearTrack.SEASON_TRACKS then
        return  
    end

    local y = 8
    local x = 8
    local fontHeight = 14
    local rowGap = 6
    local cellHeight = 20

    
    
    
    
    
    local col1Width = 120  
    local col2Width = 130  
    local col3Width = 130  
    local col4Width = 130  
    local colGap = 12
    local bestUseWidth = 0  

    local function CreateFontString(text, template, xPos, yPos, rowIndex, columnKey)
        local fs = frame:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", frame, "TOPLEFT", xPos, -yPos)
        fs:SetText(text)
        table.insert(frame.__fontStrings, fs)
        RecordGrid(frame, rowIndex, columnKey, { kind = "text", text = fs })
        return fs
    end

    local function CreateCell(xPos, yPos, width, trackName, rank, ilvl, rowIndex, columnKey)
        local cell = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        cell:SetSize(width, cellHeight)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", xPos, -yPos)
        cell:SetBackdrop({
            bgFile = FILL_TEXTURE,
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 4,
        })

        local r, g, b = GetTrackColour(trackName)
        cell:SetBackdropColor(r, g, b, FILL_ALPHA)
        cell:SetBackdropBorderColor(r, g, b, 0.9)

        
        local ilvlText
        local text = ilvl and tostring(ilvl) or ""
        if text ~= "" then
            ilvlText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            ilvlText:SetPoint("CENTER", cell, "CENTER")
            ilvlText:SetText(text)
            ilvlText:SetTextColor(r, g, b)
        end

        
        local trackText
        if trackName and rank then
            trackText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            trackText:SetPoint("CENTER", cell, "CENTER", 0, -6)
            trackText:SetText(trackName .. " " .. rank .. "/6")
            trackText:SetTextColor(r, g, b)
        end

        
        
        
        cell.__row = rowIndex
        cell.__col = columnKey
        cell.__ilvlText = ilvlText
        cell.__trackText = trackText

        table.insert(frame.__cells, cell)
        RecordGrid(frame, rowIndex, columnKey,
            { kind = "cell", cell = cell, ilvlText = ilvlText, trackText = trackText })
        return cell
    end

    local function CreateMistcrestCell(xPos, yPos, width, trackName, rowIndex, columnKey)
        
        
        local fs = CreateFontString(trackName, "GameFontNormalSmall", xPos, yPos, rowIndex, columnKey)
        local r, g, b = GetTrackColour(trackName)
        fs:SetTextColor(r, g, b)
        fs:SetWidth(width)
        return fs
    end

    
    local headers
    if mode == "delve" then
        headers = { "Tier", "Bountiful Delve", "Trovehunter's Bounty", "Great Vault" }
    elseif mode == "prey" then
        headers = { "Prey difficulty", "Direct reward", "Great Vault", "Best use" }
    else
        headers = { "Difficulty", "End of run", "Mistcrest", "Great Vault" }
    end

    for i, headerText in ipairs(headers) do
        local xPos = x
        if i == 2 then
            xPos = x + col1Width + colGap
        elseif i == 3 then
            xPos = x + col1Width + colGap + col2Width + colGap
        elseif i == 4 then
            xPos = x + col1Width + colGap + col2Width + colGap + col3Width + colGap
        end
        CreateFontString(headerText, "GameFontNormal", xPos, y)
    end
    y = y + fontHeight + rowGap

    
    for rowIndex, row in ipairs(data) do
        if mode == "delve" then
            
            local tier, bountiful, bounty, vault = row[1], row[2], row[3], row[4]

            CreateFontString(tostring(tier), "GameFontNormalSmall", x, y, rowIndex, "label")

            
            if bountiful then
                local ilvl = GetItemLevelForTrackAndRank(bountiful[1], bountiful[2])
                CreateCell(x + col1Width + colGap, y, col2Width, bountiful[1], bountiful[2], ilvl, rowIndex, "bountiful")
            end

            
            if bounty then
                local ilvl = GetItemLevelForTrackAndRank(bounty[1], bounty[2])
                CreateCell(x + col1Width + colGap + col2Width + colGap, y, col3Width, bounty[1], bounty[2], ilvl, rowIndex, "bounty")
            else
                CreateFontString("—", "GameFontNormalSmall", x + col1Width + colGap + col2Width + colGap, y, rowIndex, "bounty")
            end

            
            local ilvl = GetItemLevelForTrackAndRank(vault[1], vault[2])
            CreateCell(x + col1Width + colGap + col2Width + colGap + col3Width + colGap, y, col4Width, vault[1], vault[2], ilvl, rowIndex, "vault")

        elseif mode == "prey" then
            
            local difficulty, direct, vault, bestUse = row[1], row[2], row[3], row[4]

            CreateFontString(difficulty, "GameFontNormalSmall", x, y, rowIndex, "label")

            
            local ilvl = GetItemLevelForTrackAndRank(direct[1], direct[2])
            CreateCell(x + col1Width + colGap, y, col2Width, direct[1], direct[2], ilvl, rowIndex, "direct")

            
            ilvl = GetItemLevelForTrackAndRank(vault[1], vault[2])
            CreateCell(x + col1Width + colGap + col2Width + colGap, y, col3Width, vault[1], vault[2], ilvl, rowIndex, "vault")

            
            
            
            
            
            
            
            local bestUseFS = CreateFontString(bestUse, "GameFontDisable",
                x + col1Width + colGap + col2Width + colGap + col3Width + colGap, y, rowIndex, "bestUse")
            local w = bestUseFS.GetStringWidth and bestUseFS:GetStringWidth() or 0
            if w and w > bestUseWidth then
                bestUseWidth = w
            end

        else
            
            local difficulty, endOfRun, mistcrest, vault = row[1], row[2], row[3], row[4]

            CreateFontString(difficulty, "GameFontNormalSmall", x, y, rowIndex, "label")

            
            local ilvl = GetItemLevelForTrackAndRank(endOfRun[1], endOfRun[2])
            CreateCell(x + col1Width + colGap, y, col2Width, endOfRun[1], endOfRun[2], ilvl, rowIndex, "endOfRun")

            
            CreateMistcrestCell(x + col1Width + colGap + col2Width + colGap, y, col3Width, mistcrest, rowIndex, "mistcrest")

            
            ilvl = GetItemLevelForTrackAndRank(vault[1], vault[2])
            CreateCell(x + col1Width + colGap + col2Width + colGap + col3Width + colGap, y, col4Width, vault[1], vault[2], ilvl, rowIndex, "vault")
        end

        y = y + cellHeight + rowGap
    end

    
    
    
    
    if mode == "prey" and bestUseWidth > col4Width then
        col4Width = bestUseWidth
    end
    local totalWidth = col1Width + colGap + col2Width + colGap + col3Width + colGap + col4Width + 16
    local totalHeight = y + 8
    frame:SetSize(totalWidth, totalHeight)

    
    local screenWidth = UIParent:GetWidth() or 1024
    local screenHeight = UIParent:GetHeight() or 768
end









function RewardTables:PaintSectionBodies()
    local Seasonal = ThugUI.Seasonal
    if not Seasonal or not Seasonal.sectionFrames then return end

    
    local BODY_PAINT_SPECS = {
        delves = { data = DELVE_DATA, mode = "delve" },
        prey = { data = PREY_DATA, mode = "prey" },
    }

    
    
    
    
    
    
    
    for sectionId, spec in pairs(BODY_PAINT_SPECS) do
        local entry = Seasonal.sectionFrames[sectionId]
        if entry and entry.body then
            
            entry.body.__fontStrings = entry.body.__fontStrings or {}
            entry.body.__cells = entry.body.__cells or {}
            entry.body.__grid = entry.body.__grid or {}

            
            
            
            
            
            
            PaintRewardTable(entry.body, spec.data, spec.mode)

            
            
            
            
            
            
            
            
            
            
            
            
            
            
            if entry.body.text then
                if #entry.body.__fontStrings > 0 then
                    entry.body.text:Hide()
                else
                    entry.body.text:Show()
                end
            end
        end
    end

    
    Seasonal:RelayoutBody()
end













local TIP_BUTTON_SECTIONS = {
    { id = "mplus",  frameField = "mplusFrame",  data = MPLUS_DATA, mode = "mplus" },
}

function RewardTables:AddTipButtons()
    local Seasonal = ThugUI.Seasonal
    if not Seasonal or not Seasonal.sectionFrames then return end

    W = W or ThugUI.Widgets

    for _, spec in ipairs(TIP_BUTTON_SECTIONS) do
        local entry = Seasonal.sectionFrames[spec.id]
        if entry and entry.header then
            
            
            if not self[spec.frameField] then
                self[spec.frameField] = CreateTooltipFrame()
            end
            local tooltipFrame = self[spec.frameField]

            if not entry.header.__rewardButton then
                local btn = CreateFrame("Button", nil, entry.header)
                btn:SetSize(16, 16)
                btn:SetPoint("RIGHT", entry.header, "RIGHT", -6, 0)

                local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("CENTER", btn, "CENTER")
                fs:SetText("?")
                fs:SetTextColor(1, 1, 1)

                btn:SetScript("OnEnter", function()
                    PaintRewardTable(tooltipFrame, spec.data, spec.mode)
                    tooltipFrame:SetPoint("TOPLEFT", btn, "BOTTOMRIGHT", 4, -4)
                    tooltipFrame:Show()
                end)
                btn:SetScript("OnLeave", function()
                    tooltipFrame:Hide()
                end)
                btn:SetScript("OnClick", function() end)  

                entry.header.__rewardButton = btn
            end
        end
    end
end





function RewardTables:Render(key)
    
    
end





function RewardTables:Initialize()
    local Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal = Seasonal

    
    
    Seasonal:CreateWindow()
    Seasonal.RewardTables = self

    
    
    Seasonal:RegisterRefresh(function(key) self:Render(key) end)
    Seasonal:RegisterRefresh(function(key) self:PaintSectionBodies() end)

    
    local ok, err = pcall(function() self:AddTipButtons() end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SEASONAL", "reward tables button creation failed: %s", tostring(err))
    end
end

return RewardTables
