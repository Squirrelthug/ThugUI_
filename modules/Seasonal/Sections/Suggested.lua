








































ThugUI = ThugUI or {}

local Suggested = {}
ThugUI:RegisterModule("SeasonalSuggested", Suggested)

local W  










local PROFICIENCY_OPTIONS = {
    { id = "notproficient", label = "Not proficient", delta = 5 },
    { id = "normal",        label = "Normal",          delta = 10 },
    { id = "proficient",    label = "Proficient",      delta = 15 },
}
local DEFAULT_PROFICIENCY = "normal"  
    

local function EnsureProficiencyDB()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Seasonal = ThugUIDB.Seasonal or {}
    ThugUIDB.Seasonal.proficiency = ThugUIDB.Seasonal.proficiency or {}
    return ThugUIDB.Seasonal.proficiency
end

local function GetProficiencyID(key)
    local db = EnsureProficiencyDB()
    return (key and db[key]) or DEFAULT_PROFICIENCY
end

local function SetProficiencyID(key, id)
    if not key then return end
    EnsureProficiencyDB()[key] = id
end

local function GetProficiencyOption(id)
    for _, opt in ipairs(PROFICIENCY_OPTIONS) do
        if opt.id == id then return opt end
    end
    return PROFICIENCY_OPTIONS[2]  
end














local function BuildRaidRows(RT)
    local rows = {}
    for _, row in ipairs(RT.RAID_DATA) do
        local label, direct, vault = row[1], row[2], row[3]
        rows[#rows + 1] = {
            label = label,
            track = direct[1], rank = direct[2],
            vaultTrack = vault[1], vaultRank = vault[2],
        }
    end
    return rows
end

local function BuildMplusRows(RT)
    local rows = {}
    for _, row in ipairs(RT.MPLUS_DATA) do
        
        
        
        local label, direct, vault = row[1], row[2], row[4]
        rows[#rows + 1] = {
            label = label,
            track = direct[1], rank = direct[2],
            vaultTrack = vault[1], vaultRank = vault[2],
        }
    end
    return rows
end

local function BuildDelveRows(RT)
    local rows = {}
    for _, row in ipairs(RT.DELVE_DATA) do
        
        
        
        
        local tier, bountiful, vault = row[1], row[2], row[4]
        rows[#rows + 1] = {
            label = "Tier " .. tier,
            track = bountiful[1], rank = bountiful[2],
            vaultTrack = vault[1], vaultRank = vault[2],
        }
    end
    return rows
end

local function BuildPreyRows(RT)
    local rows = {}
    for _, row in ipairs(RT.PREY_DATA) do
        
        local label, direct, vault = row[1], row[2], row[3]
        rows[#rows + 1] = {
            label = label,
            track = direct[1], rank = direct[2],
            vaultTrack = vault[1], vaultRank = vault[2],
        }
    end
    return rows
end

local function BuildWorldRows(RT)
    local rows = {}
    for _, row in ipairs(RT.WORLD_DATA) do
        local label, track = row[1], row[2]
        
        
        
        
        
        
        rows[#rows + 1] = { label = label, track = track, rank = 1 }
    end
    return rows
end

local CONTENT_TYPES = {
    { id = "raid",   label = "Raid",    build = BuildRaidRows },
    { id = "mplus",  label = "Mythic+", build = BuildMplusRows },
    { id = "delves", label = "Delves",  build = BuildDelveRows },
    { id = "prey",   label = "Prey",    build = BuildPreyRows },
    { id = "world",  label = "World",   build = BuildWorldRows },
}







local function ItemLevelFor(GearTrack, trackName, rank)
    if not trackName or not rank then return nil end
    for _, track in ipairs(GearTrack.SEASON_TRACKS) do
        if track.name == trackName then
            return track.ranks[rank]
        end
    end
    return nil
end

local function FormatReward(GearTrack, row)
    local ilvl = ItemLevelFor(GearTrack, row.track, row.rank)
    return string.format("%s  %s %d/6", tostring(ilvl or "?"), row.track, row.rank)
end

















local function MakePicker(GearTrack)
    local function ItemLevel(trackName, rank)
        return ItemLevelFor(GearTrack, trackName, rank)
    end

    local function Pick(rows, target)
        local best, stretch
        for _, row in ipairs(rows) do
            local lv = ItemLevel(row.track, row.rank)
            if lv <= target then
                if not best then
                    best = row
                else
                    local bestLv = ItemLevel(best.track, best.rank)
                    if lv > bestLv then
                        best = row
                    elseif lv == bestLv then
                        local a = row.vaultTrack and ItemLevel(row.vaultTrack, row.vaultRank) or 0
                        local b = best.vaultTrack and ItemLevel(best.vaultTrack, best.vaultRank) or 0
                        if a > b then best = row end
                    end
                end
            elseif not stretch then
                stretch = row
            end
        end
        return best, stretch
    end

    return Pick
end










local PROF_BTN_WIDTH, PROF_BTN_HEIGHT, PROF_BTN_GAP = 108, 20, 4
local LINE_HEIGHT = 16
local SECTION_GAP = 8
local BLOCK_GAP = 6
local COL1_X, COL2_X, COL3_X = 4, 78, 230

local function BuildProficiencyRow(self, body)
    W = W or ThugUI.Widgets

    local row = CreateFrame("Frame", nil, body)
    row:SetSize(1, PROF_BTN_HEIGHT)
    row:SetPoint("TOPLEFT", body, "TOPLEFT", COL1_X, 0)

    self.profButtons = {}
    local x = 0
    for _, opt in ipairs(PROFICIENCY_OPTIONS) do
        local btn = CreateFrame("Button", nil, row)
        btn:SetSize(PROF_BTN_WIDTH, PROF_BTN_HEIGHT)
        btn:SetPoint("LEFT", row, "LEFT", x, 0)
        x = x + PROF_BTN_WIDTH + PROF_BTN_GAP

        
        
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, 0.10)
        bg:Hide()
        btn.selectedBG = bg

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("CENTER")
        label:SetText(opt.label .. " (+" .. opt.delta .. ")")
        btn.label = label

        btn:SetScript("OnClick", function()
            
            
            
            
            SetProficiencyID(self.currentKey, opt.id)
            self:Render(self.currentKey)
        end)

        if W and type(W.AttachTooltip) == "function" then
            W.AttachTooltip(btn, opt.label,
                "Suggest content assuming this character is " .. opt.label:lower() .. " for its item level.")
        end

        self.profButtons[opt.id] = btn
    end

    return row
end




local function HideBlock(block)
    block.typeLabel:Hide()
    block.primaryLabel:Hide()
    block.primaryReward:Hide()
    block.stretchLabel:Hide()
    block.stretchReward:Hide()
    block.noneLabel:Hide()
end

local function EnsureFrames(self, body)
    if self.built then return end
    self.built = true

    self.profRow = BuildProficiencyRow(self, body)

    self.targetText = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.targetText:SetPoint("TOPLEFT", body, "TOPLEFT", COL1_X, -(PROF_BTN_HEIGHT + SECTION_GAP))
    self.targetText:Hide()

    self.noGearText = body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    self.noGearText:SetPoint("TOPLEFT", body, "TOPLEFT", COL1_X, -(PROF_BTN_HEIGHT + SECTION_GAP))
    self.noGearText:SetText("No gear data for this character yet -- log in on them once.")
    self.noGearText:Hide()

    self.blocks = {}
    local y = PROF_BTN_HEIGHT + SECTION_GAP + LINE_HEIGHT + SECTION_GAP
    for _, ct in ipairs(CONTENT_TYPES) do
        local block = {}

        block.typeLabel = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        block.typeLabel:SetPoint("TOPLEFT", body, "TOPLEFT", COL1_X, -y)
        block.typeLabel:SetText(ct.label)

        block.primaryLabel = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        block.primaryLabel:SetPoint("TOPLEFT", body, "TOPLEFT", COL2_X, -y)

        block.primaryReward = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        block.primaryReward:SetPoint("TOPLEFT", body, "TOPLEFT", COL3_X, -y)

        block.noneLabel = body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        block.noneLabel:SetPoint("TOPLEFT", body, "TOPLEFT", COL2_X, -y)
        block.noneLabel:SetText("nothing in range")

        y = y + LINE_HEIGHT

        block.stretchLabel = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        block.stretchLabel:SetPoint("TOPLEFT", body, "TOPLEFT", COL2_X, -y)

        block.stretchReward = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        block.stretchReward:SetPoint("TOPLEFT", body, "TOPLEFT", COL3_X, -y)

        y = y + LINE_HEIGHT + BLOCK_GAP

        HideBlock(block)
        self.blocks[ct.id] = block
    end

    
    
    
    self.contentHeight = y
end





function Suggested:Render(key)
    local Seasonal = ThugUI.Seasonal
    local entry = Seasonal and Seasonal.sectionFrames and Seasonal.sectionFrames["suggested"]
    if not entry or not entry.body then return end
    local body = entry.body

    
    
    
    
    
    if body.text then body.text:Hide() end

    EnsureFrames(self, body)

    
    
    key = (Seasonal.GetDisplayKey and Seasonal:GetDisplayKey(key)) or key
    self.currentKey = key

    local profID = GetProficiencyID(key)
    for id, btn in pairs(self.profButtons) do
        btn.selectedBG:SetShown(id == profID)
    end

    local GearTrack = Seasonal.GearTrack
    local RT = Seasonal.RewardTables
    if not GearTrack or not GearTrack.SEASON_TRACKS or not RT or not RT.MPLUS_DATA then
        
        
        
        
        return
    end

    local Data = Seasonal.Data
    local row = key and Data and Data.GetCharacter and Data:GetCharacter(key)
    local equipped = row and row.avgItemLevel

    if type(equipped) ~= "number" then
        
        
        
        
        
        self.targetText:Hide()
        for _, block in pairs(self.blocks) do HideBlock(block) end
        self.noGearText:Show()
        body:SetHeight(math.max(40, PROF_BTN_HEIGHT + SECTION_GAP + LINE_HEIGHT + 8))
        Seasonal:RelayoutBody()
        return
    end

    self.noGearText:Hide()

    local opt = GetProficiencyOption(profID)
    
    
    
    
    local equippedRounded = math.floor(equipped + 0.5)
    local target = equippedRounded + opt.delta

    self.targetText:SetText(string.format("Equipped %d  ->  target %d", equippedRounded, target))
    self.targetText:Show()

    local Pick = MakePicker(GearTrack)

    for _, ct in ipairs(CONTENT_TYPES) do
        local block = self.blocks[ct.id]
        local rows = ct.build(RT)
        local best, stretch = Pick(rows, target)

        block.typeLabel:Show()

        if not best then
            
            
            
            block.primaryLabel:Hide()
            block.primaryReward:Hide()
            block.stretchLabel:Hide()
            block.stretchReward:Hide()
            block.noneLabel:Show()
        else
            block.noneLabel:Hide()
            block.primaryLabel:SetText(best.label)
            block.primaryReward:SetText(FormatReward(GearTrack, best))
            block.primaryLabel:Show()
            block.primaryReward:Show()

            if stretch then
                block.stretchLabel:SetText("stretch: " .. stretch.label)
                block.stretchReward:SetText(FormatReward(GearTrack, stretch))
                block.stretchLabel:Show()
                block.stretchReward:Show()
            else
                
                
                block.stretchLabel:Hide()
                block.stretchReward:Hide()
            end
        end
    end

    
    
    
    body:SetHeight(math.max(40, self.contentHeight or 40))
    Seasonal:RelayoutBody()
end





function Suggested:Initialize()
    local Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal = Seasonal

    
    
    Seasonal:CreateWindow()
    Seasonal.Suggested = self

    Seasonal:RegisterRefresh(function(key) self:Render(key) end)

    
    local ok, err = pcall(function() self:Render() end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SEASONAL", "suggested content initial render failed: %s", tostring(err))
    end
end

return Suggested
