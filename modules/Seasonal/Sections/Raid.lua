




































































































ThugUI = ThugUI or {}

local Raid = {}
ThugUI:RegisterModule("SeasonalRaid", Raid)

local W  





local STRINGS = {
    EMPTY_NO_CHARACTER = "No character selected.",
    EMPTY_NO_SNAPSHOT  = "No data captured for this character yet.",
    EMPTY_NO_LOCKOUTS  = "No raid lockouts this week.",
    SEASON_UNKNOWN     = "Waiting for the client to name this season's raid.",
    STALE_FORMAT       = "Captured %s ago.",
    PROGRESS_FORMAT    = "%d/%d",
    TOOLTIP_LOCKED   = "Locked",
    TOOLTIP_UNLOCKED = "Not locked",
    TOOLTIP_EXTENDED = "Lockout extended",
    TOOLTIP_RESET    = "Resets in %s",
    TOOLTIP_EXPIRED  = "Lockout has reset since this snapshot.",
    TOOLTIP_NO_LOCKOUT = "No lockout at this difficulty.",
    BOSS_DEFEATED = "Defeated",
    BOSS_ALIVE    = "Alive",
}


local HEADING_HEIGHT = 16
local ROW_HEIGHT     = 15
local ROW_GAP        = 1
local TABLE_GAP      = 10
local LABEL_WIDTH    = 190   
local PIP_SIZE       = 11
local PIP_GAP        = 4
local PIP_STRIDE     = PIP_SIZE + PIP_GAP
local PIPS_LEFT      = LABEL_WIDTH + 8
local FILL_TEXTURE   = "Interface\\Buttons\\WHITE8x8"

local NOT_DONE_COLOR = { 0.26, 0.26, 0.26 }
local BORDER_ALPHA   = 0.55
local FILL_ALPHA     = 0.85



















local DIFFICULTY_COLUMNS = {
    { id = 17, done = { 0.45, 0.62, 0.48 } },  
    { id = 14, done = { 0.20, 0.75, 0.32 } },  
    { id = 15, done = { 0.25, 0.55, 0.95 } },  
    { id = 16, done = { 0.70, 0.40, 0.90 } },  
}















local WORLD_COLUMNS = {
    { id = 250, done = { 0.72, 0.58, 0.38 } },  
    { id = 14,  done = { 0.20, 0.75, 0.32 } },  
    { id = 15,  done = { 0.25, 0.55, 0.95 } },  
    { id = 16,  done = { 0.70, 0.40, 0.90 } },  
}











local WORLD_DIFFICULTY_ID = 250




local function ClientString(globalName, fallback)
    local value = _G and _G[globalName]
    if type(value) == "string" and value ~= "" then return value end
    return fallback
end




local function DifficultyName(difficultyID, lockout)
    if DifficultyUtil and type(DifficultyUtil.GetDifficultyName) == "function" then
        local ok, name = pcall(DifficultyUtil.GetDifficultyName, difficultyID)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return lockout and lockout.difficultyName or nil
end








local function RemainingSeconds(lockout, capturedAt)
    if type(lockout.resetSeconds) ~= "number" then return nil end
    if type(capturedAt) ~= "number" or capturedAt <= 0 then return lockout.resetSeconds end

    local now = type(GetServerTime) == "function" and GetServerTime() or nil
    if type(now) ~= "number" then return lockout.resetSeconds end

    local remaining = lockout.resetSeconds - (now - capturedAt)
    if remaining < 0 then return 0 end
    return remaining
end







local function IsExpired(lockout, capturedAt)
    return RemainingSeconds(lockout, capturedAt) == 0
end




local function ProgressFor(lockout)
    local encounters = lockout.encounters or {}

    local total = lockout.numEncounters
    if type(total) ~= "number" or total <= 0 then total = #encounters end

    local killed = lockout.encounterProgress
    if type(killed) ~= "number" then
        killed = 0
        for _, boss in ipairs(encounters) do
            if boss.killed then killed = killed + 1 end
        end
    end

    return killed, total
end




























function Raid.BuildTables(lockouts, seasonRaid, capturedAt)
    local raidLockouts, world = {}, {}

    
    
    
    
    local expired = {}

    
    
    
    
    
    
    
    
    
    
    
    
    local isWorldBossName = {}
    for _, lockout in ipairs(lockouts or {}) do
        if lockout.isRaid
                and (lockout.isWorldBoss or lockout.difficultyID == WORLD_DIFFICULTY_ID) then
            isWorldBossName[lockout.name or ""] = true
        end
    end

    for _, lockout in ipairs(lockouts or {}) do
        if lockout.isRaid then
            local isDead = IsExpired(lockout, capturedAt)
            expired[lockout] = isDead

            if isWorldBossName[lockout.name or ""] then
                
                table.insert(world, lockout)
            else
                table.insert(raidLockouts, lockout)
            end
        end
        
        
        
    end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    local bossOrder, order, seen = {}, {}, {}
    local seasonKnown = false
    if seasonRaid and type(seasonRaid.instances) == "table" then
        for _, instance in ipairs(seasonRaid.instances) do
            if instance.name and type(instance.bosses) == "table" and #instance.bosses > 0 then
                seasonKnown = true
                bossOrder[instance.name] = instance.bosses
                if not seen[instance.name] then
                    seen[instance.name] = true
                    table.insert(order, instance.name)
                end
            end
        end
    end

    
    
    local byInstance = {}
    for _, lockout in ipairs(raidLockouts) do
        
        
        
        if bossOrder[lockout.name] then
            byInstance[lockout.name] = byInstance[lockout.name] or {}
            table.insert(byInstance[lockout.name], lockout)
        end
    end

    local raids = {}
    for _, name in ipairs(order) do
        local instanceLockouts = byInstance[name]
        if instanceLockouts and #instanceLockouts > 0 then
            local byDifficulty = {}
            for _, lockout in ipairs(instanceLockouts) do
                byDifficulty[lockout.difficultyID] = lockout
            end

            local columns = {}
            for _, column in ipairs(DIFFICULTY_COLUMNS) do
                local lockout = byDifficulty[column.id]
                byDifficulty[column.id] = nil
                table.insert(columns, {
                    difficultyID = column.id,
                    doneColor = column.done,
                    lockout = lockout,
                    
                    
                    
                    expired = (lockout ~= nil) and expired[lockout] or false,
                    difficultyName = DifficultyName(column.id, lockout),
                })
            end
            
            
            for difficultyID, lockout in pairs(byDifficulty) do
                table.insert(columns, {
                    difficultyID = difficultyID,
                    doneColor = DIFFICULTY_COLUMNS[#DIFFICULTY_COLUMNS].done,
                    lockout = lockout,
                    expired = expired[lockout] or false,
                    difficultyName = DifficultyName(difficultyID, lockout),
                })
            end

            local bosses = {}
            for index, bossName in ipairs(bossOrder[name]) do
                local killed = {}
                for columnIndex, column in ipairs(columns) do
                    local isKilled = false
                    
                    
                    
                    if column.lockout and not column.expired then
                        for _, boss in ipairs(column.lockout.encounters or {}) do
                            if boss.name == bossName then
                                isKilled = boss.killed and true or false
                                break
                            end
                        end
                    end
                    killed[columnIndex] = isKilled
                end
                bosses[index] = { name = bossName, killed = killed }
            end

            table.insert(raids, { name = name, columns = columns, bosses = bosses })
        end
    end

    
    
    
    
    
    
    local worldByInstance = {}
    for _, lockout in ipairs(world) do
        local name = lockout.name or ""
        worldByInstance[name] = worldByInstance[name] or {}
        table.insert(worldByInstance[name], lockout)
    end

    world = {}
    for _, instanceLockouts in pairs(worldByInstance) do
        if instanceLockouts and #instanceLockouts > 0 then
            local name = instanceLockouts[1].name or ""
            local byDifficulty = {}
            for _, lockout in ipairs(instanceLockouts) do
                
                
                
                local diffID = lockout.difficultyID or WORLD_DIFFICULTY_ID
                local existing = byDifficulty[diffID]
                if not existing then
                    byDifficulty[diffID] = lockout
                else
                    
                    
                    
                    
                    
                    local existingDead = expired[existing]
                    local lockoutDead = expired[lockout]
                    if existingDead and not lockoutDead then
                        byDifficulty[diffID] = lockout
                    elseif not lockoutDead then
                        
                        local existingHasEncounters = #(existing.encounters or {}) > 0
                        local lockoutHasEncounters = #(lockout.encounters or {}) > 0
                        if lockoutHasEncounters and not existingHasEncounters then
                            byDifficulty[diffID] = lockout
                        end
                    end
                end
            end

            local columns = {}
            for _, column in ipairs(WORLD_COLUMNS) do
                local lockout = byDifficulty[column.id]
                byDifficulty[column.id] = nil
                table.insert(columns, {
                    difficultyID = column.id,
                    doneColor = column.done,
                    lockout = lockout,
                    
                    
                    
                    expired = (lockout ~= nil) and expired[lockout] or false,
                    difficultyName = DifficultyName(column.id, lockout),
                })
            end
            
            
            for difficultyID, lockout in pairs(byDifficulty) do
                table.insert(columns, {
                    difficultyID = difficultyID,
                    doneColor = WORLD_COLUMNS[#WORLD_COLUMNS].done,
                    lockout = lockout,
                    expired = expired[lockout] or false,
                    difficultyName = DifficultyName(difficultyID, lockout),
                })
            end

            
            
            
            
            
            
            
            
            local bosses = {}
            local bossNames = bossOrder[name]
            if bossNames and type(bossNames) == "table" and #bossNames > 0 then
                for index, bossName in ipairs(bossNames) do
                    local killed = {}
                    for columnIndex, column in ipairs(columns) do
                        local isKilled = false
                        
                        
                        
                        if column.lockout and not column.expired then
                            for _, boss in ipairs(column.lockout.encounters or {}) do
                                if boss.name == bossName then
                                    isKilled = boss.killed and true or false
                                    break
                                end
                            end
                        end
                        killed[columnIndex] = isKilled
                    end
                    bosses[index] = { name = bossName, killed = killed }
                end
            else
                
                
                local longestBosses = {}
                for _, lockout in ipairs(instanceLockouts) do
                    if lockout.encounters and #lockout.encounters > #longestBosses then
                        longestBosses = lockout.encounters
                    end
                end

                if #longestBosses > 0 then
                    for index, bossEntry in ipairs(longestBosses) do
                        local killed = {}
                        for columnIndex, column in ipairs(columns) do
                            local isKilled = false
                            if column.lockout and not column.expired then
                                for _, boss in ipairs(column.lockout.encounters or {}) do
                                    if boss.name == bossEntry.name then
                                        isKilled = boss.killed and true or false
                                        break
                                    end
                                end
                            end
                            killed[columnIndex] = isKilled
                        end
                        bosses[index] = { name = bossEntry.name, killed = killed }
                    end
                else
                    
                    
                    
                    local killed = {}
                    for columnIndex, column in ipairs(columns) do
                        killed[columnIndex] = (column.lockout and not column.expired) and true or false
                    end
                    bosses[1] = { name = name, killed = killed }
                end
            end

            table.insert(world, { name = name, columns = columns, bosses = bosses })
        end
    end

    table.sort(world, function(left, right) return (left.name or "") < (right.name or "") end)

    return { raids = raids, world = world, seasonKnown = seasonKnown }
end










local function AcquireHeading(self, parent, index)
    self.headings = self.headings or {}
    local heading = self.headings[index]
    if not heading then
        heading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.headings[index] = heading
    end
    return heading
end

local function AcquireRow(self, parent, index)
    self.rows = self.rows or {}
    local row = self.rows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetWidth(LABEL_WIDTH)
    row.label:SetJustifyH("LEFT")
    
    
    if row.label.SetWordWrap then row.label:SetWordWrap(false) end

    row.pips = {}
    self.rows[index] = row
    return row
end

local function AcquirePip(row, index)
    local pip = row.pips[index]
    if pip then return pip end

    pip = CreateFrame("Frame", nil, row, "BackdropTemplate")
    pip:SetSize(PIP_SIZE, PIP_SIZE)
    
    
    
    pip:SetBackdrop({
        bgFile = FILL_TEXTURE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 4,
    })
    row.pips[index] = pip
    return pip
end


local function LockoutTooltipBody(lockout, capturedAt)
    if not lockout then return STRINGS.TOOLTIP_NO_LOCKOUT end

    local remaining = RemainingSeconds(lockout, capturedAt)
    local body = lockout.locked and STRINGS.TOOLTIP_LOCKED or STRINGS.TOOLTIP_UNLOCKED
    if lockout.extended then
        body = body .. " - " .. STRINGS.TOOLTIP_EXTENDED
    end
    if remaining == 0 then
        
        
        
        return body .. "\n" .. STRINGS.TOOLTIP_EXPIRED
    elseif type(remaining) == "number" and type(SecondsToTime) == "function" then
        body = body .. "\n" .. STRINGS.TOOLTIP_RESET:format(SecondsToTime(remaining))
    end

    local killed, total = ProgressFor(lockout)
    return body .. "\n" .. STRINGS.PROGRESS_FORMAT:format(killed, total)
end









local function ShowEmpty(self, body, message)
    if not self.emptyText then
        self.emptyText = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        self.emptyText:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -2)
    end
    self.emptyText:SetText(message)
    self.emptyText:Show()

    for _, row in ipairs(self.rows or {}) do row:Hide() end
    for _, heading in ipairs(self.headings or {}) do heading:Hide() end
    if self.staleText then self.staleText:Hide() end
    if self.seasonText then self.seasonText:Hide() end

    body:SetHeight(ROW_HEIGHT + 4)
end


local function PaintBossRow(row, bossName, killed, columns, capturedAt)
    row.label:SetText(bossName or "")

    for index, column in ipairs(columns) do
        local pip = AcquirePip(row, index)
        pip:ClearAllPoints()
        pip:SetPoint("LEFT", row, "LEFT", PIPS_LEFT + (index - 1) * PIP_STRIDE, 0)

        local isDone = killed[index]
        local color = isDone and column.doneColor or NOT_DONE_COLOR
        pip:SetBackdropColor(color[1], color[2], color[3], FILL_ALPHA)
        pip:SetBackdropBorderColor(color[1], color[2], color[3], BORDER_ALPHA)

        
        
        local title = column.difficultyName or bossName or ""
        local state = isDone and ClientString("BOSS_DEAD", STRINGS.BOSS_DEFEATED)
                              or ClientString("BOSS_ALIVE", STRINGS.BOSS_ALIVE)
        W.AttachTooltip(pip, title,
            state .. "\n" .. LockoutTooltipBody(column.lockout, capturedAt))
        pip:Show()
    end

    for index = #columns + 1, #row.pips do
        row.pips[index]:Hide()
    end
end

function Raid:Render(key)
    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    local entry = Seasonal and Seasonal.sectionFrames and Seasonal.sectionFrames["raid"]
    if not entry or not entry.body then return end
    local body = entry.body

    
    
    if body.text then body.text:Hide() end

    W = W or ThugUI.Widgets

    
    
    
    key = (Seasonal and Seasonal.GetDisplayKey and Seasonal:GetDisplayKey(key)) or key
    if not key then return ShowEmpty(self, body, STRINGS.EMPTY_NO_CHARACTER) end

    local snapshot = Data and Data:GetCharacter(key)
    if type(snapshot) ~= "table" then
        return ShowEmpty(self, body, STRINGS.EMPTY_NO_SNAPSHOT)
    end

    local seasonRaid = Data.GetSeasonRaid and Data:GetSeasonRaid()
    local tables = Raid.BuildTables(snapshot.lockouts, seasonRaid, snapshot.capturedAt)
    if #tables.raids == 0 and #tables.world == 0 then
        
        
        
        
        return ShowEmpty(self, body,
            tables.seasonKnown and STRINGS.EMPTY_NO_LOCKOUTS or STRINGS.SEASON_UNKNOWN)
    end
    if self.emptyText then self.emptyText:Hide() end

    local capturedAt = snapshot.capturedAt
    local y = 0

    
    
    if Data.IsStale and Data:IsStale(key) then
        if not self.staleText then
            self.staleText = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        end
        local age = Data.GetAgeSeconds and Data:GetAgeSeconds(key)
        local ageText = (type(age) == "number" and type(SecondsToTime) == "function")
            and SecondsToTime(age) or tostring(age or "?")
        self.staleText:ClearAllPoints()
        self.staleText:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        self.staleText:SetText(STRINGS.STALE_FORMAT:format(ageText))
        self.staleText:Show()
        y = y - ROW_HEIGHT
    elseif self.staleText then
        self.staleText:Hide()
    end

    
    
    
    if not tables.seasonKnown then
        if not self.seasonText then
            self.seasonText = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        end
        self.seasonText:ClearAllPoints()
        self.seasonText:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        self.seasonText:SetText(STRINGS.SEASON_UNKNOWN)
        self.seasonText:Show()
        y = y - ROW_HEIGHT
    elseif self.seasonText then
        self.seasonText:Hide()
    end

    local headingIndex, rowIndex = 0, 0

    for _, raid in ipairs(tables.raids) do
        headingIndex = headingIndex + 1
        local heading = AcquireHeading(self, body, headingIndex)
        heading:ClearAllPoints()
        heading:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        heading:SetText(raid.name)     
        heading:Show()
        y = y - HEADING_HEIGHT

        for _, boss in ipairs(raid.bosses) do
            rowIndex = rowIndex + 1
            local row = AcquireRow(self, body, rowIndex)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y)

            PaintBossRow(row, boss.name, boss.killed, raid.columns, capturedAt)

            row:Show()
            y = y - ROW_HEIGHT - ROW_GAP
        end

        y = y - TABLE_GAP
    end

    
    
    
    
    
    
    for _, worldEntry in ipairs(tables.world) do
        headingIndex = headingIndex + 1
        local heading = AcquireHeading(self, body, headingIndex)
        heading:ClearAllPoints()
        heading:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        heading:SetText(worldEntry.name or "")
        heading:Show()
        y = y - HEADING_HEIGHT

        for _, boss in ipairs(worldEntry.bosses) do
            rowIndex = rowIndex + 1
            local row = AcquireRow(self, body, rowIndex)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y)

            PaintBossRow(row, boss.name, boss.killed, worldEntry.columns, capturedAt)

            row:Show()
            y = y - ROW_HEIGHT - ROW_GAP
        end

        y = y - TABLE_GAP
    end

    for index = rowIndex + 1, #(self.rows or {}) do
        self.rows[index]:Hide()
    end
    for index = headingIndex + 1, #(self.headings or {}) do
        self.headings[index]:Hide()
    end

    
    
    body:SetHeight(math.max(ROW_HEIGHT, math.abs(y) + 4))
    Seasonal:RelayoutBody()
end

function Raid:Initialize()
    local Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal = Seasonal

    
    Seasonal:CreateWindow()
    Seasonal.Raid = self

    Seasonal:RegisterRefresh(function(key) self:Render(key) end)

    local ok, err = pcall(function() self:Render() end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SEASONAL", "raid section initial render failed: %s", tostring(err))
    end
end

return Raid
