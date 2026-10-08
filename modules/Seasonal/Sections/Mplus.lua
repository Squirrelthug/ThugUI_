

































ThugUI = ThugUI or {}

local Mplus = {}
ThugUI:RegisterModule("SeasonalMplus", Mplus)

local W  




local STRINGS = {
    EMPTY_NO_CHARACTER = "No character selected.",
    EMPTY_NO_SNAPSHOT  = "No data captured for this character yet.",
    EMPTY_NO_RUNS      = "No Mythic+ runs this season.",
    STALE_FORMAT       = "Captured %s ago.",
    NO_RUNS_YET        = "no runs yet",
    COLUMN_DUNGEON     = "Dungeon",
    COLUMN_TIMED       = "Timed",
    COLUMN_OVER        = "Over",
    COLUMN_SCORE       = "Score",
    ROW_SEASON_SCORE   = "Season score",
}


local HEADING_HEIGHT = 16
local ROW_HEIGHT     = 15
local ROW_GAP        = 1
local TABLE_GAP      = 10
local LABEL_WIDTH    = 150   
local COL_WIDTH      = 50    
local COLUMN_GAP     = 4
local FILL_TEXTURE   = "Interface\\Buttons\\WHITE8x8"

local NOT_DONE_COLOR = { 0.26, 0.26, 0.26 }
local BORDER_ALPHA   = 0.55
local FILL_ALPHA     = 0.85
local EM_DASH        = "\226\128\148"  








local function BestLevel(intime, overtime)
    local intimeLevel = intime and intime.level or nil
    local overtimeLevel = overtime and overtime.level or nil

    if not intimeLevel and not overtimeLevel then return nil, nil end
    if not intimeLevel then return overtimeLevel, overtime.score end
    if not overtimeLevel then return intimeLevel, intime.score end

    
    if intimeLevel > overtimeLevel then
        return intimeLevel, intime.score
    elseif overtimeLevel > intimeLevel then
        return overtimeLevel, overtime.score
    else
        
        return intimeLevel, intime.score
    end
end








function Mplus.HighestKey(seasonBest)
    local bestLevel, bestName, bestTieInfo

    for mapID, entry in pairs(seasonBest or {}) do
        if type(entry) == "table" then
            local level, score = BestLevel(entry.intime, entry.overtime)
            if level then
                if not bestLevel or level > bestLevel then
                    bestLevel = level
                    bestName = entry.name
                    bestTieInfo = { hasIntime = entry.intime ~= nil }
                elseif level == bestLevel then
                    
                    local thisHasIntime = entry.intime ~= nil
                    local thisName = entry.name or ""
                    local bestNameStr = bestName or ""

                    local shouldUse = false
                    if bestTieInfo.hasIntime and not thisHasIntime then
                        
                        shouldUse = false
                    elseif not bestTieInfo.hasIntime and thisHasIntime then
                        
                        shouldUse = true
                    else
                        
                        if thisName < bestNameStr then
                            shouldUse = true
                        end
                    end

                    if shouldUse then
                        bestName = entry.name
                        bestTieInfo = { hasIntime = thisHasIntime }
                    end
                end
            end
        end
    end

    return bestLevel, bestName
end






function Mplus.BuildRows(seasonBest, score)
    if not seasonBest or type(seasonBest) ~= "table" then
        return {}, score
    end

    local rows = {}
    local dungeons = {}

    
    for mapID, entry in pairs(seasonBest) do
        if type(entry) == "table" and type(entry.name) == "string" and entry.name ~= "" then
            table.insert(dungeons, { name = entry.name, mapID = mapID, entry = entry })
        end
    end

    
    table.sort(dungeons, function(left, right) return (left.name or "") < (right.name or "") end)

    
    for _, dungeon in ipairs(dungeons) do
        local entry = dungeon.entry
        local timedLevel = entry.intime and entry.intime.level or nil
        local overtimeLevel = entry.overtime and entry.overtime.level or nil
        local bestLvl, bestScore = BestLevel(entry.intime, entry.overtime)

        table.insert(rows, {
            name = entry.name,
            timedLevel = timedLevel,
            overtimeLevel = overtimeLevel,
            score = bestScore,
        })
    end

    return rows, score
end



local function AcquireRow(self, parent, index)
    self.rows = self.rows or {}
    local row = self.rows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    row.dungeonText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.dungeonText:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.dungeonText:SetWidth(LABEL_WIDTH)
    row.dungeonText:SetJustifyH("LEFT")
    if row.dungeonText.SetWordWrap then row.dungeonText:SetWordWrap(false) end

    row.timedText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.timedText:SetPoint("LEFT", row, "LEFT", LABEL_WIDTH + COLUMN_GAP, 0)
    row.timedText:SetWidth(COL_WIDTH)
    row.timedText:SetJustifyH("CENTER")

    row.overtimeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.overtimeText:SetPoint("LEFT", row, "LEFT", LABEL_WIDTH + COLUMN_GAP + COL_WIDTH + COLUMN_GAP, 0)
    row.overtimeText:SetWidth(COL_WIDTH)
    row.overtimeText:SetJustifyH("CENTER")

    row.scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.scoreText:SetPoint("LEFT", row, "LEFT", LABEL_WIDTH + COLUMN_GAP + COL_WIDTH * 2 + COLUMN_GAP * 2, 0)
    row.scoreText:SetWidth(COL_WIDTH)
    row.scoreText:SetJustifyH("CENTER")

    self.rows[index] = row
    return row
end


local function FormatLevel(level)
    if type(level) == "number" then
        return "+" .. tostring(level)
    end
    return EM_DASH
end


local function PaintRow(row, dungeon, timedLevel, overtimeLevel, score)
    row.dungeonText:SetText(dungeon or "")
    row.timedText:SetText(FormatLevel(timedLevel))
    row.overtimeText:SetText(FormatLevel(overtimeLevel))

    if type(score) == "number" then
        row.scoreText:SetText(tostring(score))
    else
        row.scoreText:SetText(EM_DASH)
    end

    row:Show()
end


local function PaintScoreRow(row, score)
    row.dungeonText:SetText(STRINGS.ROW_SEASON_SCORE)
    row.timedText:SetText("")
    row.overtimeText:SetText("")

    if type(score) == "number" then
        row.scoreText:SetText(tostring(score))
        
        
        local ok, colorMixin
        if type(C_ChallengeMode) == "table" and type(C_ChallengeMode.GetDungeonScoreRarityColor) == "function" then
            ok, colorMixin = pcall(C_ChallengeMode.GetDungeonScoreRarityColor, score)
        end
        if ok and colorMixin and type(colorMixin.GetRGB) == "function" then
            local r, g, b = colorMixin:GetRGB()
            row.scoreText:SetTextColor(r, g, b)
        else
            row.scoreText:SetTextColor(1, 1, 1)  
        end
    else
        row.scoreText:SetText(EM_DASH)
        row.scoreText:SetTextColor(1, 1, 1)
    end

    row:Show()
end


local function PaintHeading(heading)
    heading:SetText(STRINGS.COLUMN_DUNGEON)
    heading:Show()
end

function Mplus:Render(key)
    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    local entry = Seasonal and Seasonal.sectionFrames and Seasonal.sectionFrames["mplus"]
    if not entry then return end

    local body = entry.body
    local header = entry.header
    if not body or not header then return end

    
    if body.text then body.text:Hide() end

    W = W or ThugUI.Widgets

    key = (Seasonal and Seasonal.GetDisplayKey and Seasonal:GetDisplayKey(key)) or key
    if not key then
        if header.seasonBestText then header.seasonBestText:Hide() end
        if header.text then header.text:Hide() end
        return
    end

    local snapshot = Data and Data:GetCharacter(key)
    if type(snapshot) ~= "table" then
        if header.seasonBestText then header.seasonBestText:Hide() end
        return
    end

    local mplus = snapshot.mplus
    if not mplus or type(mplus) ~= "table" then
        if header.seasonBestText then header.seasonBestText:Hide() end
        return
    end

    local seasonBest = mplus.seasonBest
    local score = mplus.score

    
    if header then
        local bestLevel, bestName = Mplus.HighestKey(seasonBest)

        if not header.seasonBestText then
            header.seasonBestText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            header.seasonBestText:SetPoint("TOPRIGHT", header, "TOPRIGHT", -4, 0)
        end

        if bestLevel and bestName then
            header.seasonBestText:SetText("+" .. tostring(bestLevel) .. " " .. tostring(bestName))
            header.seasonBestText:SetTextColor(1, 1, 1)
        else
            header.seasonBestText:SetText(STRINGS.NO_RUNS_YET)
            header.seasonBestText:SetTextColor(0.5, 0.5, 0.5)  
        end
        header.seasonBestText:Show()
    end

    
    local rows, displayScore = Mplus.BuildRows(seasonBest, score)

    if #rows == 0 then
        
        if body.emptyText then body.emptyText:Hide() end
        body:SetHeight(ROW_HEIGHT + 4)
        for _, row in ipairs(self.rows or {}) do row:Hide() end
        if self.headingText then self.headingText:Hide() end
        return
    end

    if self.emptyText then self.emptyText:Hide() end

    
    if not self.headingText then
        self.headingText = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.headingText:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    end
    PaintHeading(self.headingText)

    local y = -HEADING_HEIGHT

    
    for index, rowData in ipairs(rows) do
        local row = AcquireRow(self, body, index)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y)

        PaintRow(row, rowData.name, rowData.timedLevel, rowData.overtimeLevel, rowData.score)

        y = y - ROW_HEIGHT - ROW_GAP
    end

    
    local scoreRow = AcquireRow(self, body, #rows + 1)
    scoreRow:ClearAllPoints()
    scoreRow:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    scoreRow:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y)

    PaintScoreRow(scoreRow, displayScore)

    y = y - ROW_HEIGHT - ROW_GAP

    
    for index = #rows + 2, #(self.rows or {}) do
        self.rows[index]:Hide()
    end

    body:SetHeight(math.max(ROW_HEIGHT, math.abs(y) + 4))
    Seasonal:RelayoutBody()
end

function Mplus:Initialize()
    local Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal = Seasonal

    
    Seasonal:CreateWindow()
    Seasonal.Mplus = self

    Seasonal:RegisterRefresh(function(key) self:Render(key) end)

    local ok, err = pcall(function() self:Render() end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SEASONAL", "mplus section initial render failed: %s", tostring(err))
    end
end

return Mplus
