

































































ThugUI = ThugUI or {}

local Vault = {}
ThugUI:RegisterModule("SeasonalVault", Vault)

local W  












local STRINGS = {
    REFRESH_TITLE = "Refresh vault rewards",
    REFRESH_BODY = "The Great Vault only reveals what a slot gives you once "
        .. "you have opened it in-game. Once it has, this is remembered "
        .. "until the weekly reset. Click to check again now.",
}

















local BANDS = {
    { name = "Myth",       min = 318, max = 334 },
    { name = "Hero",       min = 305, max = 321 },
    { name = "Champion",   min = 292, max = 308 },
    { name = "Veteran",    min = 279, max = 295 },
    { name = "Adventurer", min = 266, max = 282 },
}




local TRACK_INDEX = { Adventurer = 1, Veteran = 2, Champion = 3, Hero = 4, Myth = 5 }






function Vault.TrackForItemLevel(ilvl)
    if type(ilvl) ~= "number" then return nil, nil end
    for _, band in ipairs(BANDS) do
        if ilvl >= band.min and ilvl <= band.max then
            return band.name, TRACK_INDEX[band.name]
        end
    end
    if ilvl < BANDS[#BANDS].min then
        local low = BANDS[#BANDS]  
        return low.name, TRACK_INDEX[low.name]
    end
    local high = BANDS[1]  
    return high.name, TRACK_INDEX[high.name]
end







local TRACK_QUALITY = {
    Adventurer = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor,
    Veteran    = Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon,
    Champion   = Enum and Enum.ItemQuality and Enum.ItemQuality.Rare,
    Hero       = Enum and Enum.ItemQuality and Enum.ItemQuality.Epic,
    Myth       = Enum and Enum.ItemQuality and Enum.ItemQuality.Legendary,
}















function Vault.ColorForTrack(trackName)
    local quality = trackName and TRACK_QUALITY[trackName]
    local data = quality ~= nil and type(ITEM_QUALITY_COLORS) == "table" and ITEM_QUALITY_COLORS[quality]
    if type(data) ~= "table" then return 0.5, 0.5, 0.5 end
    return data.r, data.g, data.b
end
















local ROW_ORDER = { "Raid", "Activities", "World" }











local function RowKeyForType(activityType)
    local T = Enum and Enum.WeeklyRewardChestThresholdType
    if type(T) ~= "table" then return nil end
    if activityType == T.Raid then return "Raid" end
    if activityType == T.Activities then return "Activities" end
    if activityType == T.World then return "World" end
    return nil
end






function Vault:BucketVault(vault)
    local buckets = { Raid = {}, Activities = {}, World = {} }
    if type(vault) ~= "table" then return buckets end

    for _, activity in ipairs(vault) do
        if type(activity) == "table" then
            local rowKey = RowKeyForType(activity.type)
            local index = activity.index
            if rowKey and type(index) == "number" and index >= 1 and index <= 3 then
                buckets[rowKey][index] = activity
            else
                
                
                
                
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:LogOnce(
                        "seasonal-vault-unhandled-" .. tostring(activity.id),
                        "SEASONAL",
                        "vault: unhandled activity type=%s id=%s index=%s threshold=%s",
                        tostring(activity.type), tostring(activity.id),
                        tostring(activity.index), tostring(activity.threshold))
                end
            end
        end
    end

    return buckets
end










local function EnsureWeeklyRewardsAddon()
    if type(C_AddOns) ~= "table" or type(C_AddOns.LoadAddOn) ~= "function" then return end
    pcall(C_AddOns.LoadAddOn, "Blizzard_WeeklyRewards")
end

local function ResolveExampleHyperlink(activityID)
    if type(activityID) ~= "number" then return nil end
    if type(C_WeeklyRewards) ~= "table"
            or type(C_WeeklyRewards.GetExampleRewardItemHyperlinks) ~= "function" then
        return nil
    end
    EnsureWeeklyRewardsAddon()
    local ok, hyperlink = pcall(C_WeeklyRewards.GetExampleRewardItemHyperlinks, activityID)
    if not ok or type(hyperlink) ~= "string" then return nil end
    return hyperlink
end







local function ResolveItemLevel(hyperlink)
    if type(C_Item) ~= "table" or type(C_Item.GetDetailedItemLevelInfo) ~= "function" then
        return nil
    end
    local ok, ilvl = pcall(C_Item.GetDetailedItemLevelInfo, hyperlink)
    if not ok or type(ilvl) ~= "number" then return nil end
    return ilvl
end













































function Vault:BuildBoxDescriptors(vault, key, isCurrent)
    local buckets = self:BucketVault(vault)
    local descriptors = {}

    local Data = ThugUI.Seasonal and ThugUI.Seasonal.Data
    local cachedBoxes = key and Data and Data:GetVaultBoxes(key)
    
    
    
    
    if not cachedBoxes and key and Data and type(Data.GetPendingVaultBoxes) == "function" then
        local pending = Data:GetPendingVaultBoxes(key)
        if pending then
            cachedBoxes = pending
            cachedBoxes.isPending = true
        end
    end
    
    
    
    
    local resolvedEntries

    for _, rowKey in ipairs(ROW_ORDER) do
        for index = 1, 3 do
            local activity = buckets[rowKey][index]
            local d = { rowKey = rowKey, index = index }

            if activity then
                local progress = type(activity.progress) == "number" and activity.progress or 0
                local threshold = type(activity.threshold) == "number" and activity.threshold or 0
                d.progress, d.threshold = progress, threshold
                d.activityID = activity.id
                
                
                
                
                
                
                
                
                
                d.activityType = activity.type
                d.level = activity.level
                d.activityTierID = activity.activityTierID
                d.encounters = activity.encounters
                d.runHistory = activity.runHistory
                d.worldRuns = activity.worldRuns
                if activity.itemLevel then d.itemLevel = activity.itemLevel end
                if activity.trackName then d.trackName = activity.trackName end

                if threshold > 0 then
                    
                    
                    
                    
                    
                    d.earned = progress >= threshold

                    
                    
                    
                    local boxIndex = #descriptors + 1

                    
                    
                    
                    
                    
                    
                    
                    
                    
                    local hyperlink = isCurrent and ResolveExampleHyperlink(activity.id)
                    local ilvl = hyperlink and ResolveItemLevel(hyperlink)
                    if hyperlink then d.hyperlink = hyperlink end

                    if ilvl then
                        
                        
                        
                        d.trackName, d.trackIndex = Vault.TrackForItemLevel(ilvl)
                        d.itemLevel = ilvl
                        resolvedEntries = resolvedEntries or {}
                        
                        
                        
                        
                        
                        resolvedEntries[boxIndex] = {
                            track = d.trackName,
                            ilvl = ilvl,
                            earned = d.earned,
                            hyperlink = hyperlink,
                        }
                    else
                        
                        
                        
                        
                        
                        
                        local cached = cachedBoxes and cachedBoxes[boxIndex]
                        if cached then
                            if type(cached.ilvl) == "number" then
                                d.trackName, d.trackIndex = Vault.TrackForItemLevel(cached.ilvl)
                                d.itemLevel = cached.ilvl
                            end
                            
                            
                            
                            if type(cached.hyperlink) == "string" then
                                d.hyperlink = cached.hyperlink
                            end
                            
                            
                            d.fromPreviousWeek = cachedBoxes.isPending or nil
                        end
                    end
                end
            end

            table.insert(descriptors, d)
        end
    end

    
    
    
    if key and isCurrent and Data and resolvedEntries then
        Data:MergeVaultBoxes(key, resolvedEntries)
    end

    return descriptors
end




function Vault:BuildBoxDescriptorsForKey(key)
    local Data = ThugUI.Seasonal and ThugUI.Seasonal.Data
    local row = Data and key and Data:GetCharacter(key)
    
    
    
    local isCurrent = Data ~= nil and key ~= nil and key == Data:GetCurrentKey()
    return self:BuildBoxDescriptors(row and row.vault, key, isCurrent)
end



















































local function GlobalString(name)
    local v = name and _G[name]
    if type(v) == "string" then return v end
    return nil
end







local LOCKED_DESCRIPTION = {
    Activities = {
        [1] = { name = "GREAT_VAULT_REWARDS_MYTHIC_INCOMPLETE",       formatRemaining = false },
        [2] = { name = "GREAT_VAULT_REWARDS_MYTHIC_COMPLETED_FIRST",  formatRemaining = true },
        [3] = { name = "GREAT_VAULT_REWARDS_MYTHIC_COMPLETED_SECOND", formatRemaining = true },
    },
    World = {
        [1] = { name = "GREAT_VAULT_REWARDS_WORLD_INCOMPLETE",       formatRemaining = true },
        [2] = { name = "GREAT_VAULT_REWARDS_WORLD_COMPLETED_FIRST",  formatRemaining = true },
        [3] = { name = "GREAT_VAULT_REWARDS_WORLD_COMPLETED_SECOND", formatRemaining = true },
    },
}






local function RaidLockedDescriptionName(progress)
    if progress == 0 then
        return "GREAT_VAULT_REWARDS_RAID_INCOMPLETE"
    end
    return "GREAT_VAULT_REWARDS_RAID_INPROGRESS"
end












local function EnsureWeeklyRewardsUtilAddon()
    if type(C_AddOns) ~= "table" or type(C_AddOns.LoadAddOn) ~= "function" then return end
    pcall(C_AddOns.LoadAddOn, "Blizzard_WeeklyRewardsUtil")
end







local function SafeCall(tbl, fnName, ...)
    if type(tbl) ~= "table" or type(tbl[fnName]) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(tbl[fnName], ...)
    if not ok then return nil end
    return a, b, c, d
end



local function SafeCallFn(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f
end




local function SafeFormat(fmt, ...)
    if type(fmt) ~= "string" then return nil end
    local ok, text = pcall(string.format, fmt, ...)
    if ok then return text end
    return nil
end






local function AddNormalLine(text)
    if text and type(GameTooltip_AddNormalLine) == "function" then
        GameTooltip_AddNormalLine(GameTooltip, text)
    end
end
local function AddHighlightLine(text)
    if text and type(GameTooltip_AddHighlightLine) == "function" then
        GameTooltip_AddHighlightLine(GameTooltip, text)
    end
end


local function AddColoredRGB(text, r, g, b)
    local Widgets = ThugUI.Widgets
    if Widgets and type(Widgets.AddColoredTooltipLine) == "function" then
        Widgets.AddColoredTooltipLine(text, r, g, b)
    elseif type(GameTooltip.AddLine) == "function" then
        GameTooltip:AddLine(text, r, g, b, true)
    end
end




local function AddColoredLine(text, color)
    if text and color and type(GameTooltip_AddColoredLine) == "function" then
        GameTooltip_AddColoredLine(GameTooltip, text, color)
    end
end
local function AddBlankLine()
    if type(GameTooltip_AddBlankLineToTooltip) == "function" then
        GameTooltip_AddBlankLineToTooltip(GameTooltip)
    end
end



local function EncountersSort(left, right)
    if left.instanceID ~= right.instanceID then
        return left.instanceID < right.instanceID
    end
    local leftCompleted = (left.bestDifficulty or 0) > 0
    local rightCompleted = (right.bestDifficulty or 0) > 0
    if leftCompleted ~= rightCompleted then
        return leftCompleted
    end
    return (left.uiOrder or 0) < (right.uiOrder or 0)
end







local function AddRaidCompletionInfoToGameTooltip(d)
    local encounters = d.encounters
    if type(encounters) ~= "table" and type(d.activityType) == "number" and type(d.index) == "number" then
        encounters = SafeCall(C_WeeklyRewards, "GetActivityEncounterInfo", d.activityType, d.index)
    end
    if type(encounters) ~= "table" then return end

    table.sort(encounters, EncountersSort)
    local lastInstanceID = nil
    for _, encounter in ipairs(encounters) do
        local name = encounter.name
        local instanceID = encounter.instanceID
        if not name or not instanceID then
            local eName, _, _, _, _, iID = SafeCallFn(EJ_GetEncounterInfo, encounter.encounterID)
            name = name or eName
            instanceID = instanceID or iID
        end
        if instanceID ~= lastInstanceID then
            local instanceName = encounter.instanceName or SafeCallFn(EJ_GetInstanceInfo, instanceID) or "Raid"
            AddBlankLine()
            AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_ENCOUNTER_LIST"), instanceName))
            lastInstanceID = instanceID
        end
        if name then
            if (encounter.bestDifficulty or 0) > 0 then
                local difficultyName = SafeCall(DifficultyUtil, "GetDifficultyName", encounter.bestDifficulty) or "Killed"
                AddColoredLine(SafeFormat(GlobalString("WEEKLY_REWARDS_COMPLETED_ENCOUNTER"), name, difficultyName),
                    GREEN_FONT_COLOR)
            else
                AddColoredLine(SafeFormat(GlobalString("DASH_WITH_TEXT"), name), DISABLED_FONT_COLOR)
            end
        end
    end
end






local function HasMultipleRaidInstances(d)
    local encounters = d.encounters
    if type(encounters) ~= "table" and type(d.activityType) == "number" and type(d.index) == "number" then
        encounters = SafeCall(C_WeeklyRewards, "GetActivityEncounterInfo", d.activityType, d.index)
    end
    if type(encounters) ~= "table" then return false end

    local lastInstanceID = nil
    for _, encounter in ipairs(encounters) do
        local instanceID = encounter.instanceID
        if not instanceID then
            local _, _, _, _, _, iID = SafeCallFn(EJ_GetEncounterInfo, encounter.encounterID)
            instanceID = iID
        end
        if not lastInstanceID then
            lastInstanceID = instanceID
        elseif lastInstanceID ~= instanceID then
            return true
        end
    end
    return false
end











local function RaidLockedSubtitle(d)
    if not HasMultipleRaidInstances(d) then return nil end
    return SafeCall(PVPUtil, "GetCurrentSeasonText")
end





local function AddTopRunsToTooltip(d)
    local threshold = d.threshold or 0
    AddBlankLine()
    AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_MYTHIC_TOP_RUNS"), threshold))

    local runHistory = d.runHistory
    if type(runHistory) ~= "table" then
        runHistory = SafeCall(C_MythicPlus, "GetRunHistory", false, true)
    end
    if type(runHistory) ~= "table" then runHistory = {} end
    if #runHistory > 0 then
        table.sort(runHistory, function(left, right)
            if left.level == right.level then
                local lMap = left.mapChallengeModeID or 0
                local rMap = right.mapChallengeModeID or 0
                return lMap < rMap
            end
            return left.level > right.level
        end)
        for i = 1, threshold do
            local run = runHistory[i]
            if run then
                local name = run.mapName or SafeCall(C_ChallengeMode, "GetMapUIInfo", run.mapChallengeModeID) or "Dungeon"
                AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_MYTHIC_RUN_INFO"), run.level, name))
            end
        end
    end

    local missingRuns = threshold - #runHistory
    if missingRuns > 0 then
        local numHeroic, numMythic = SafeCall(C_WeeklyRewards, "GetNumCompletedDungeonRuns")
        numHeroic, numMythic = numHeroic or 0, numMythic or 0
        EnsureWeeklyRewardsUtilAddon()
        local mythicLevel = type(WeeklyRewardsUtil) == "table" and WeeklyRewardsUtil.MythicLevel or nil
        while numMythic > 0 and missingRuns > 0 do
            if mythicLevel ~= nil then
                AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_MYTHIC"), mythicLevel))
            end
            numMythic, missingRuns = numMythic - 1, missingRuns - 1
        end
        while numHeroic > 0 and missingRuns > 0 do
            AddHighlightLine(GlobalString("WEEKLY_REWARDS_HEROIC"))
            numHeroic, missingRuns = numHeroic - 1, missingRuns - 1
        end
    end
end






local function AddMythicProgressLines(d)
    if (d.progress or 0) <= 0 then return end
    EnsureWeeklyRewardsUtilAddon()
    local lowestLevel = nil
    if type(WeeklyRewardsUtil) == "table"
            and type(WeeklyRewardsUtil.GetLowestLevelInTopDungeonRuns) == "function" then
        local ok, lvl = pcall(WeeklyRewardsUtil.GetLowestLevelInTopDungeonRuns, d.threshold or 0)
        if ok then lowestLevel = lvl end
    end

    AddBlankLine()
    if lowestLevel and lowestLevel == WeeklyRewardsUtil.HeroicLevel then
        AddNormalLine(SafeFormat(GlobalString("GREAT_VAULT_REWARDS_CURRENT_LEVEL_HEROIC"), d.threshold or 0))
    elseif lowestLevel then
        AddNormalLine(SafeFormat(GlobalString("GREAT_VAULT_REWARDS_CURRENT_LEVEL_MYTHIC"), d.threshold or 0, lowestLevel))
    end
    AddTopRunsToTooltip(d)
end








local function AddWorldRunsToTooltip(d)
    local desiredRuns = d.threshold or 0
    if desiredRuns <= 0 then return end

    AddBlankLine()
    AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_WORLD_TOP_ACTIVITIES"), desiredRuns))

    local activityTierProgress = d.worldRuns
    if type(activityTierProgress) ~= "table" and type(d.activityType) == "number" then
        local combineSharedDifficulty = true
        activityTierProgress = SafeCall(C_WeeklyRewards, "GetSortedProgressForActivity",
            d.activityType, combineSharedDifficulty)
    end
    if type(activityTierProgress) ~= "table" then return end

    for _, tierProgress in ipairs(activityTierProgress) do
        local numRuns = math.min(tierProgress.numPoints or 0, desiredRuns)
        if numRuns <= 0 then return end
        desiredRuns = desiredRuns - numRuns

        
        
        
        if (tierProgress.difficulty or 0) > 1 then
            AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_DELVE_TIER_INFO"),
                tierProgress.difficulty, numRuns))
        else
            AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_DELVE_TIER_AND_WORLD_INFO"),
                tierProgress.difficulty, numRuns))
        end
    end
end





local function ResolveExampleHyperlinks(activityID)
    if type(activityID) ~= "number" then return nil, nil end
    if type(C_WeeklyRewards) ~= "table"
            or type(C_WeeklyRewards.GetExampleRewardItemHyperlinks) ~= "function" then
        return nil, nil
    end
    EnsureWeeklyRewardsAddon()
    local ok, itemLink, upgradeItemLink = pcall(C_WeeklyRewards.GetExampleRewardItemHyperlinks, activityID)
    if not ok then return nil, nil end
    if type(itemLink) ~= "string" then itemLink = nil end
    if type(upgradeItemLink) ~= "string" then upgradeItemLink = nil end
    return itemLink, upgradeItemLink
end







local function HandlePreviewRaidRewardTooltip(d, itemLevel, upgradeItemLevel)
    local currentDifficultyID = d.level
    local currentDifficultyName = SafeCall(DifficultyUtil, "GetDifficultyName", currentDifficultyID)
    AddNormalLine(SafeFormat(GlobalString("WEEKLY_REWARDS_ITEM_LEVEL_RAID"), itemLevel, currentDifficultyName))
    AddBlankLine()
    if upgradeItemLevel then
        local nextDifficultyID = SafeCall(DifficultyUtil, "GetNextPrimaryRaidDifficultyID", currentDifficultyID)
        if nextDifficultyID then
            local difficultyName = SafeCall(DifficultyUtil, "GetDifficultyName", nextDifficultyID)
            AddColoredLine(SafeFormat(GlobalString("WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL"), upgradeItemLevel),
                GREEN_FONT_COLOR)
            AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_COMPLETE_RAID"), difficultyName))
            AddRaidCompletionInfoToGameTooltip(d)
        end
    end
end













local function IsCompletedAtHeroicLevel(d)
    local difficultyID = SafeCall(C_WeeklyRewards, "GetDifficultyIDForActivityTier", d.activityTierID)
    local heroicID = type(DifficultyUtil) == "table" and type(DifficultyUtil.ID) == "table"
        and DifficultyUtil.ID.DungeonHeroic
    return difficultyID ~= nil and difficultyID == heroicID
end







local function HandlePreviewMythicRewardTooltip(d, itemLevel, upgradeItemLevel, nextLevel)
    local isHeroicLevel = IsCompletedAtHeroicLevel(d)
    if isHeroicLevel then
        AddNormalLine(SafeFormat(GlobalString("WEEKLY_REWARDS_ITEM_LEVEL_HEROIC"), itemLevel))
    else
        AddNormalLine(SafeFormat(GlobalString("WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC"), itemLevel, d.level or 0))
    end
    AddBlankLine()
    if upgradeItemLevel then
        AddColoredLine(SafeFormat(GlobalString("WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL"), upgradeItemLevel),
            GREEN_FONT_COLOR)
        if (d.threshold or 0) == 1 then
            if isHeroicLevel then
                AddHighlightLine(GlobalString("WEEKLY_REWARDS_COMPLETE_HEROIC_SHORT"))
            else
                AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT"), nextLevel))
            end
        else
            AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_COMPLETE_MYTHIC"), nextLevel, d.threshold))
            AddTopRunsToTooltip(d)
        end
    end
end






local function HandlePreviewWorldRewardTooltip(d, itemLevel, upgradeItemLevel, nextLevel)
    AddNormalLine(SafeFormat(GlobalString("WEEKLY_REWARDS_ITEM_LEVEL_WORLD"), itemLevel, d.level or 0))
    AddBlankLine()
    if upgradeItemLevel then
        AddColoredLine(SafeFormat(GlobalString("WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL"), upgradeItemLevel),
            GREEN_FONT_COLOR)
        AddHighlightLine(SafeFormat(GlobalString("WEEKLY_REWARDS_COMPLETE_WORLD"), nextLevel))
    end
    AddWorldRunsToTooltip(d)
end















local function ShowUnlockedTooltip(owner, d, isCurrent, isStale)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")

    local title = WEEKLY_REWARDS_CURRENT_REWARD or "Great Vault Reward"
    if title and type(GameTooltip_SetTitle) == "function" then
        GameTooltip_SetTitle(GameTooltip, title)
    else
        GameTooltip:AddLine(title, 1, 1, 1)
    end

    if isCurrent then
        local itemLink, upgradeItemLink = ResolveExampleHyperlinks(d.activityID)
        local itemLevel = itemLink and ResolveItemLevel(itemLink)
        local upgradeItemLevel = upgradeItemLink and ResolveItemLevel(upgradeItemLink)

        if not itemLevel then
            local retrieving = RETRIEVING_ITEM_INFO
            if retrieving and type(GameTooltip_AddErrorLine) == "function" then
                GameTooltip_AddErrorLine(GameTooltip, retrieving)
            elseif retrieving then
                GameTooltip:AddLine(retrieving, 1, 0.2, 0.2)
            end
            owner.UpdateTooltip = function(self) ShowUnlockedTooltip(self, d, isCurrent, isStale) end
        else
            owner.UpdateTooltip = nil

            if d.rowKey == "Raid" then
                HandlePreviewRaidRewardTooltip(d, itemLevel, upgradeItemLevel)
            elseif d.rowKey == "Activities" then
                local hasData, _, nextLevel, nextItemLevel =
                    SafeCall(C_WeeklyRewards, "GetNextActivitiesIncrease", d.activityTierID, d.level)
                if hasData then
                    upgradeItemLevel = nextItemLevel
                else
                    EnsureWeeklyRewardsUtilAddon()
                    if type(WeeklyRewardsUtil) == "table"
                            and type(WeeklyRewardsUtil.GetNextMythicLevel) == "function" then
                        local ok, computedNextLevel = pcall(WeeklyRewardsUtil.GetNextMythicLevel, d.level or 0)
                        if ok then nextLevel = computedNextLevel end
                    end
                end
                HandlePreviewMythicRewardTooltip(d, itemLevel, upgradeItemLevel, nextLevel)
            elseif d.rowKey == "World" then
                local hasData, _, nextLevel, nextItemLevel =
                    SafeCall(C_WeeklyRewards, "GetNextActivitiesIncrease", d.activityTierID, d.level)
                if hasData then
                    upgradeItemLevel = nextItemLevel
                else
                    nextLevel = (d.level or 0) + 1
                end
                HandlePreviewWorldRewardTooltip(d, itemLevel, upgradeItemLevel, nextLevel)
            end

            if not upgradeItemLevel then
                local maxed = WEEKLY_REWARDS_MAXED_REWARD
                if maxed and type(GameTooltip_AddColoredLine) == "function" and GREEN_FONT_COLOR then
                    GameTooltip_AddColoredLine(GameTooltip, maxed, GREEN_FONT_COLOR)
                elseif maxed and type(GameTooltip_AddNormalLine) == "function" then
                    GameTooltip_AddNormalLine(GameTooltip, maxed)
                end
            end
        end
    else
        owner.UpdateTooltip = nil
        if d.trackName then
            local r, g, b = Vault.ColorForTrack(d.trackName)
            AddColoredRGB(d.trackName .. " Track", r, g, b)
        end
        if d.progress and d.threshold then
            GameTooltip:AddLine(string.format("Completed: %d/%d", d.progress, d.threshold), 0.9, 0.9, 0.9)
        end
        if (d.runHistory or d.worldRuns or d.encounters) then
            if d.rowKey == "Activities" then
                AddTopRunsToTooltip(d)
            elseif d.rowKey == "World" then
                AddWorldRunsToTooltip(d)
            elseif d.rowKey == "Raid" then
                AddRaidCompletionInfoToGameTooltip(d)
            end
        end
        if not isStale then
            AddColoredRGB("Earned Vault Reward", 0.0, 1.0, 0.8)
        end
    end

    if isStale then
        AddColoredRGB("Pending / Unclaimed Vault Reward (from prior week)", 1.0, 0.67, 0.0)
    end

    GameTooltip:Show()
end



















local function ShowLockedTooltip(owner, d, isCurrent, isStale)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")

    local title = WEEKLY_REWARDS_UNLOCK_REWARD
    if title and type(GameTooltip_SetTitle) == "function" then
        GameTooltip_SetTitle(GameTooltip, title)
    end

    
    
    
    
    
    if isCurrent and d.rowKey == "Raid" then
        local subTitle = RaidLockedSubtitle(d)
        if subTitle then
            AddBlankLine()
            AddHighlightLine(subTitle)
        end
    end

    local entry
    if d.rowKey == "Activities" then
        entry = LOCKED_DESCRIPTION.Activities[d.index]
    elseif d.rowKey == "World" then
        entry = LOCKED_DESCRIPTION.World[d.index]
    elseif d.rowKey == "Raid" then
        entry = { name = RaidLockedDescriptionName(d.progress or 0), formatRemaining = true }
    end

    local description = entry and GlobalString(entry.name)
    if description and type(GameTooltip_AddNormalLine) == "function" then
        local text = description
        if entry.formatRemaining then
            
            
            local ok, formatted = pcall(string.format, description, (d.threshold or 0) - (d.progress or 0))
            if ok then text = formatted end
        end
        GameTooltip_AddNormalLine(GameTooltip, text)
    end

    
    
    
    
    
    
    if isCurrent then
        if d.rowKey == "Activities" then
            AddMythicProgressLines(d)
        elseif d.rowKey == "World" and (d.progress or 0) > 0 then
            AddWorldRunsToTooltip(d)
        elseif d.rowKey == "Raid" then
            AddRaidCompletionInfoToGameTooltip(d)
        end
    else
        
        
        
        
        if d.earned then
            if d.trackName then
                local r, g, b = Vault.ColorForTrack(d.trackName)
                local label = d.trackName .. " Track"
                if type(d.itemLevel) == "number" then
                    label = ("%s (item level %d)"):format(label, d.itemLevel)
                end
                AddColoredRGB(label, r, g, b)
            end
            AddColoredRGB("Earned Vault Reward", 0.0, 1.0, 0.8)
        end
    end

    if isStale then
        if d.earned then
            AddColoredRGB("Pending / Unclaimed Vault Reward (from prior week)", 1.0, 0.67, 0.0)
        else
            AddColoredRGB("(Stale Data - Log in to update)", 0.6, 0.6, 0.6)
        end
    end

    GameTooltip:Show()
end

local function ShouldShowUnlockedTooltip(d, isCurrent)
    if not (d and d.earned) then return false end
    if not isCurrent then return false end
    if type(C_WeeklyRewards) ~= "table" or type(C_WeeklyRewards.CanClaimRewards) ~= "function" then
        return false
    end
    local ok, canClaim = pcall(C_WeeklyRewards.CanClaimRewards)
    return ok and not canClaim
end

function Vault:ShowSlotTooltip(owner, d, isCurrent)
    if not (owner and d) then return end
    GameTooltip.suppressAutomaticCompareItem = true
    GameTooltip.hideShoppingTooltips = true
    
    
    
    
    
    if type(TooltipComparisonManager) == "table" and type(TooltipComparisonManager.Clear) == "function" then
        pcall(TooltipComparisonManager.Clear, TooltipComparisonManager, GameTooltip)
    end
    if type(ShoppingTooltip1) == "table" and type(ShoppingTooltip1.Hide) == "function" then
        ShoppingTooltip1:Hide()
    end
    if type(ShoppingTooltip2) == "table" and type(ShoppingTooltip2.Hide) == "function" then
        ShoppingTooltip2:Hide()
    end

    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    
    
    local targetKey = Seasonal and Seasonal:GetDisplayKey()
    local isStale = (targetKey and Data and type(Data.IsStale) == "function" and Data:IsStale(targetKey)) or false

    if ShouldShowUnlockedTooltip(d, isCurrent) then
        ShowUnlockedTooltip(owner, d, isCurrent, isStale)
    else
        ShowLockedTooltip(owner, d, isCurrent, isStale)
    end
end















local FILL_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local EMPTY_TEXTURE = "Interface\\Buttons\\UI-EmptySlot"




function Vault:PaintHeader(descriptors, isCurrent)
    local Seasonal = ThugUI.Seasonal
    local boxes = Seasonal and Seasonal.vaultBoxes
    if type(boxes) ~= "table" then return end

    for i, box in ipairs(boxes) do
        local d = descriptors[i]

        if d and d.threshold and d.threshold > 0 then
            local r, g, b = Vault.ColorForTrack(d.trackName)
            box:SetBackdropBorderColor(r, g, b, 1)

            if d.earned then
                box.icon:SetTexture(FILL_TEXTURE)
                box.icon:SetVertexColor(r, g, b)
                box.icon:SetDesaturated(false)
            else
                box.icon:SetTexture(EMPTY_TEXTURE)
                box.icon:SetVertexColor(1, 1, 1)
                box.icon:SetDesaturated(true)
            end

            box:EnableMouse(true)
            box:SetScript("OnEnter", function(self)
                
                
                
                Vault:ShowSlotTooltip(self, d, isCurrent)
            end)
            box:SetScript("OnLeave", function(self)
                
                
                
                self.UpdateTooltip = nil
                if type(GameTooltip) == "table" then
                    GameTooltip.suppressAutomaticCompareItem = nil
                    GameTooltip.hideShoppingTooltips = nil
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
        else
            
            
            
            
            box:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.6)
            box.icon:SetTexture(EMPTY_TEXTURE)
            box.icon:SetVertexColor(1, 1, 1)
            box.icon:SetDesaturated(true)
            box:EnableMouse(false)
            box:SetScript("OnEnter", nil)
            box:SetScript("OnLeave", nil)
        end
    end

    local earnedCount = 0
    if type(descriptors) == "table" then
        for _, d in ipairs(descriptors) do
            if d and d.earned then
                earnedCount = earnedCount + 1
            end
        end
    end
    if Seasonal and type(Seasonal.PaintVoidcoreReminder) == "function" then
        Seasonal:PaintVoidcoreReminder(earnedCount)
    end
end




























local function InteractWithVault()
    if type(C_WeeklyRewards) ~= "table" or type(C_WeeklyRewards.OnUIInteract) ~= "function" then
        return
    end
    pcall(C_WeeklyRewards.OnUIInteract)
end





local AUTO_INTERACT_DELAY_SECONDS = 5

















function Vault:MaybeAutoInteract()
    if self.autoInteractDone then return end

    if InCombatLockdown and InCombatLockdown() then
        
        
        
        
        self.autoInteractPending = true
        return
    end
    self.autoInteractPending = nil

    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    if not Data then return end  

    local key = Data:GetCurrentKey()
    if Data:GetVaultBoxes(key) then
        
        self.autoInteractDone = true
        return
    end

    self.autoInteractDone = true
    InteractWithVault()
end








function Vault:OnEnteringWorld()
    if self.enteringWorldHandled then return end
    self.enteringWorldHandled = true

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(AUTO_INTERACT_DELAY_SECONDS, function() self:MaybeAutoInteract() end)
    else
        
        
        
        self:MaybeAutoInteract()
    end
end























function Vault:CreateRefreshButton()
    if self.refreshButton then return self.refreshButton end
    local Seasonal = ThugUI.Seasonal
    local header = Seasonal and Seasonal.header
    if not header then return nil end

    W = W or ThugUI.Widgets
    local btn = CreateFrame("Button", nil, header, "RefreshButtonTemplate")
    btn:SetSize(20, 20)
    btn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -6, -6)
    
    
    
    
    
    
    
    
    
    btn:SetScript("OnClick", function()
        InteractWithVault()
        Vault:Render()
    end)
    W.AttachTooltip(btn, STRINGS.REFRESH_TITLE, STRINGS.REFRESH_BODY)

    self.refreshButton = btn
    return btn
end

























local ITEM_INFO_THROTTLE_SECONDS = 3



function Vault:OnGetItemInfoReceived()
    local now = type(GetServerTime) == "function" and GetServerTime() or nil
    if type(now) ~= "number" then return end
    if now - (self.lastItemInfoResolve or 0) < ITEM_INFO_THROTTLE_SECONDS then return end
    self.lastItemInfoResolve = now
    self:Render()
end
















function Vault:CaptureRewardFacts()
    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    if not Data or type(Data.GetCurrentKey) ~= "function" then return false end

    local key = Data:GetCurrentKey()
    if not key then return false end

    local row = type(Data.GetCharacter) == "function" and Data:GetCharacter(key)
    if not row or type(row.vault) ~= "table" then return false end

    
    
    
    
    self:BuildBoxDescriptors(row.vault, key, true)
    return true
end

function Vault:CreateRefreshDriver()
    if self.refreshDriver then return self.refreshDriver end

    local driver = CreateFrame("Frame", "ThugUI_SeasonalVaultRefreshDriver")
    self.refreshDriver = driver
    driver:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    driver:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    driver:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    
    
    
    
    
    
    driver:RegisterEvent("PLAYER_LOGOUT")
    
    
    
    
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")

    driver:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGOUT" then
            
            
            
            
            pcall(function() self:CaptureRewardFacts() end)
        elseif event == "WEEKLY_REWARDS_UPDATE" or event == "CURRENCY_DISPLAY_UPDATE" then
            
            
            
            
            self:CaptureRewardFacts()
            self:Render()
        elseif event == "GET_ITEM_INFO_RECEIVED" then
            self:OnGetItemInfoReceived(...)
        elseif event == "PLAYER_ENTERING_WORLD" then
            self:OnEnteringWorld()
        elseif event == "PLAYER_REGEN_ENABLED" then
            if self.autoInteractPending then
                self:MaybeAutoInteract()
            end
        end
    end)

    return driver
end









function Vault:Render(key)
    local Seasonal = ThugUI.Seasonal
    local Data = Seasonal and Seasonal.Data
    
    
    key = (Seasonal and Seasonal:GetDisplayKey(key)) or key
    
    
    
    
    local isCurrent = Data ~= nil and key ~= nil and key == Data:GetCurrentKey()

    
    
    
    
    
    
    
    local descriptors = self:BuildBoxDescriptorsForKey(key)
    self:PaintHeader(descriptors, isCurrent)
end


function Vault:Initialize()
    local Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal = Seasonal

    
    
    Seasonal:CreateWindow()
    Seasonal.Vault = self

    
    
    Seasonal.TrackForItemLevel = Vault.TrackForItemLevel
    
    Seasonal.ColorForTrack = Vault.ColorForTrack

    
    
    self:CreateRefreshButton()

    
    
    self:CreateRefreshDriver()

    
    
    
    
    Seasonal:RegisterRefresh(function() self:Render() end)

    
    
    
    
    local ok, err = pcall(function() self:Render() end)
    if not ok and ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SEASONAL", "vault initial render failed: %s", tostring(err))
    end
end

return Vault
