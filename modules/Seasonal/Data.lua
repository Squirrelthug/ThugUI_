






















































ThugUI = ThugUI or {}

local Data = {}
ThugUI:RegisterModule("SeasonalData", Data)




local SCHEMA = 1
Data.SCHEMA = SCHEMA






local MIGRATIONS = {}

local db  










local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end




local function ContainsSecret(value, depth)
    depth = depth or 0
    if IsSecret(value) then return true end
    if type(value) == "table" and depth < 6 then
        for k, v in pairs(value) do
            if ContainsSecret(k, depth + 1) or ContainsSecret(v, depth + 1) then
                return true
            end
        end
    end
    return false
end




local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, ...)
    if not ok then return nil end
    return result
end





local function DeepCopy(value, depth)
    depth = depth or 0
    if type(value) ~= "table" or depth > 6 then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v, depth + 1)
    end
    return copy
end










local function SafeBuild(builder, oldValue)
    local ok, result = pcall(builder)
    if not ok then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("SEASONAL", "capture failed: %s", tostring(result))
        end
        return oldValue
    end
    if result == nil then return oldValue end
    if ContainsSecret(result) then return oldValue end
    return result
end










local SECONDS_PER_WEEK = 7 * 24 * 60 * 60

local function ComputeResetAt(capturedAt)
    local getSeconds = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset
    if type(getSeconds) == "function" then
        local ok, seconds = pcall(getSeconds)
        if ok and type(seconds) == "number" then
            return capturedAt + seconds
        end
    end
    
    
    
    
    
    return capturedAt + SECONDS_PER_WEEK
end










local function CaptureAvgItemLevel()
    if type(GetAverageItemLevel) ~= "function" then return nil end
    
    
    
    
    
    local _, equipped = GetAverageItemLevel()
    return equipped
end













local function CaptureVaultUnclaimed()
    if type(C_WeeklyRewards) ~= "table" then return nil end

    local fn = C_WeeklyRewards.HasAvailableRewards
    if type(fn) ~= "function" then return nil end

    local ok, has = pcall(fn)
    if not ok then return nil end
    return has and true or false
end

local function CaptureVault()
    local getActivities = C_WeeklyRewards and C_WeeklyRewards.GetActivities
    if type(getActivities) ~= "function" then return nil end
    local activities = getActivities()
    if type(activities) ~= "table" then return nil end

    local copy = DeepCopy(activities)

    for _, act in ipairs(copy) do
        if type(act) == "table" and type(act.type) == "number" and type(act.index) == "number" then
            
            if type(C_WeeklyRewards.GetActivityEncounterInfo) == "function" then
                local ok, encs = pcall(C_WeeklyRewards.GetActivityEncounterInfo, act.type, act.index)
                if ok and type(encs) == "table" and #encs > 0 then
                    local encList = {}
                    for _, enc in ipairs(encs) do
                        local name, instanceID, instanceName
                        if type(EJ_GetEncounterInfo) == "function" then
                            local eOk, eName, _, _, _, _, iID = pcall(EJ_GetEncounterInfo, enc.encounterID)
                            if eOk then name, instanceID = eName, iID end
                        end
                        if instanceID and type(EJ_GetInstanceInfo) == "function" then
                            local iOk, iName = pcall(EJ_GetInstanceInfo, instanceID)
                            if iOk then instanceName = iName end
                        end
                        table.insert(encList, {
                            encounterID = enc.encounterID,
                            bestDifficulty = enc.bestDifficulty,
                            uiOrder = enc.uiOrder,
                            name = name,
                            instanceID = instanceID,
                            instanceName = instanceName,
                        })
                    end
                    act.encounters = encList
                end
            end

            
            if type(C_WeeklyRewards.GetSortedProgressForActivity) == "function" then
                local ok, prog = pcall(C_WeeklyRewards.GetSortedProgressForActivity, act.type, true)
                if ok and type(prog) == "table" and #prog > 0 then
                    local progList = {}
                    for _, p in ipairs(prog) do
                        table.insert(progList, {
                            difficulty = p.difficulty,
                            numPoints = p.numPoints,
                        })
                    end
                    act.worldRuns = progList
                end
            end

            
            if type(C_WeeklyRewards.GetExampleRewardItemHyperlinks) == "function" then
                local ok, link = pcall(C_WeeklyRewards.GetExampleRewardItemHyperlinks, act.id)
                if ok and type(link) == "string" and link ~= "" then
                    act.hyperlink = link
                    if type(C_Item) == "table" and type(C_Item.GetDetailedItemLevelInfo) == "function" then
                        local iOk, ilvl = pcall(C_Item.GetDetailedItemLevelInfo, link)
                        if iOk and type(ilvl) == "number" then
                            act.itemLevel = ilvl
                            if type(ThugUI) == "table" and type(ThugUI.Seasonal) == "table" and type(ThugUI.Seasonal.TrackForItemLevel) == "function" then
                                act.trackName = ThugUI.Seasonal.TrackForItemLevel(ilvl)
                            end
                        end
                    end
                end
            end
        end
    end

    
    if type(C_MythicPlus) == "table" and type(C_MythicPlus.GetRunHistory) == "function" then
        local ok, runs = pcall(C_MythicPlus.GetRunHistory, false, true)
        if ok and type(runs) == "table" and #runs > 0 then
            local runList = {}
            for _, r in ipairs(runs) do
                local mapName
                if type(C_ChallengeMode) == "table" and type(C_ChallengeMode.GetMapUIInfo) == "function" then
                    local mOk, mName = pcall(C_ChallengeMode.GetMapUIInfo, r.mapChallengeModeID)
                    if mOk then mapName = mName end
                end
                table.insert(runList, {
                    level = r.level,
                    mapChallengeModeID = r.mapChallengeModeID,
                    mapName = mapName,
                })
            end
            for _, act in ipairs(copy) do
                act.runHistory = runList
            end
        end
    end

    return copy
end

local function CaptureMythicPlus()
    if type(C_ChallengeMode) ~= "table" and type(C_MythicPlus) ~= "table" then
        return nil
    end

    local mplus = {}

    
    
    if type(C_ChallengeMode) == "table" and type(C_ChallengeMode.GetOverallDungeonScore) == "function" then
        mplus.score = C_ChallengeMode.GetOverallDungeonScore()
    end

    if type(C_MythicPlus) == "table" then
        if type(C_MythicPlus.GetOwnedKeystoneLevel) == "function" then
            mplus.ownedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
        end
        if type(C_MythicPlus.GetOwnedKeystoneChallengeMapID) == "function" then
            mplus.ownedKeystoneMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        end
        if type(C_MythicPlus.GetRunHistory) == "function" then
            
            
            
            
            
            
            local runs = C_MythicPlus.GetRunHistory(false, true, true)
            if type(runs) == "table" then
                mplus.runs = DeepCopy(runs)
            end
        end
    end

    
    
    
    
    
    
    if type(C_ChallengeMode) == "table" and type(C_ChallengeMode.GetMapTable) == "function"
            and type(C_MythicPlus) == "table" and type(C_MythicPlus.GetSeasonBestForMap) == "function" then
        local seasonBest = {}
        local ok, mapTable = pcall(C_ChallengeMode.GetMapTable)
        if ok and type(mapTable) == "table" then
            for _, mapID in ipairs(mapTable) do
                if type(mapID) == "number" then
                    local mapName
                    local ok2, mapInfo = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
                    if ok2 and type(mapInfo) == "string" then
                        mapName = mapInfo  
                    end

                    local intime, overtime
                    local ok3, intimeInfo, overtimeInfo = pcall(C_MythicPlus.GetSeasonBestForMap, mapID)
                    if ok3 then
                        if type(intimeInfo) == "table" and type(intimeInfo.level) == "number" then
                            intime = {
                                level = intimeInfo.level,
                                score = intimeInfo.dungeonScore,
                                durationSec = intimeInfo.durationSec,
                            }
                        end
                        if type(overtimeInfo) == "table" and type(overtimeInfo.level) == "number" then
                            overtime = {
                                level = overtimeInfo.level,
                                score = overtimeInfo.dungeonScore,
                                durationSec = overtimeInfo.durationSec,
                            }
                        end
                    end

                    seasonBest[mapID] = {
                        name = mapName,
                        intime = intime,
                        overtime = overtime,
                    }
                end
            end
        end
        if next(seasonBest) ~= nil then
            mplus.seasonBest = seasonBest
        end
    end

    if next(mplus) == nil then return nil end
    return mplus
end


















local SEASON_SET_IDS = {
    [2067] = true,  
    [2062] = true,  
    [2059] = true,  
    [2064] = true,  
    [2063] = true,  
    [2055] = true,  
    [2065] = true,  
    [2060] = true,  
    [2066] = true,  
    [2061] = true,  
    [2057] = true,  
    [2056] = true,  
    [2058] = true,  
}




local SET_SLOTS = {
    INVSLOT_HEAD,
    INVSLOT_SHOULDER,
    INVSLOT_CHEST,
    INVSLOT_LEGS,
    INVSLOT_HAND,
}











function Data.IsSeasonSetPiece(link)
    if not link then return false, true end
    if type(C_Item) ~= "table" or type(C_Item.GetItemInfo) ~= "function" then
        return false, false
    end

    
    
    
    local ok, itemName, setID = pcall(function()
        local name = C_Item.GetItemInfo(link)
        return name, select(16, C_Item.GetItemInfo(link))
    end)
    if not ok or itemName == nil then
        return false, false
    end

    return setID ~= nil and SEASON_SET_IDS[setID] == true, true
end







local function CaptureSetPieces()
    if type(C_Item) ~= "table" or type(C_Item.GetItemInfo) ~= "function" then
        return nil
    end

    local count, incomplete = 0, false

    for _, slotID in ipairs(SET_SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local isSet, cached = Data.IsSeasonSetPiece(link)
            if not cached then
                
                
                
                incomplete = true
            elseif isSet then
                count = count + 1
            end
        end
    end

    return { count = count, incomplete = incomplete }
end




















local function CaptureSeasonRaid(old)
    local thresholdType = Enum and Enum.WeeklyRewardChestThresholdType
    local raidType = thresholdType and thresholdType.Raid
    if raidType == nil then return old end
    if not (C_WeeklyRewards and type(C_WeeklyRewards.GetActivityEncounterInfo) == "function") then
        return old
    end

    
    
    
    
    local encounters
    for index = 1, 3 do
        local ok, result = pcall(C_WeeklyRewards.GetActivityEncounterInfo, raidType, index)
        if ok and type(result) == "table" and #result > 0 then
            encounters = result
            break
        end
    end
    
    
    
    if not encounters then return old end

    local instances, byID = {}, {}
    for _, encounter in ipairs(encounters) do
        
        
        
        
        
        
        
        
        
        
        
        
        local bossName = encounter.name
        local instanceID = encounter.instanceID
        if (not bossName or not instanceID) and encounter.encounterID
            and type(EJ_GetEncounterInfo) == "function" then
            local ok, resolvedName, _, _, _, _, resolvedInstanceID =
                pcall(EJ_GetEncounterInfo, encounter.encounterID)
            if ok then
                bossName = bossName or resolvedName
                instanceID = instanceID or resolvedInstanceID
            end
        end

        if instanceID and bossName then
            local instance = byID[instanceID]
            if not instance then
                local instanceName = encounter.instanceName
                if not instanceName and type(EJ_GetInstanceInfo) == "function" then
                    local ok, resolved = pcall(EJ_GetInstanceInfo, instanceID)
                    if ok then instanceName = resolved end
                end

                instance = {
                    instanceID = instanceID,
                    name = instanceName,
                    bosses = {},
                }
                byID[instanceID] = instance
                table.insert(instances, instance)
            end
            table.insert(instance.bosses, bossName)
        end
    end

    
    
    
    
    
    for index = #instances, 1, -1 do
        if not instances[index].name then table.remove(instances, index) end
    end

    if #instances == 0 then return old end
    return {
        capturedAt = Try(GetServerTime) or 0,
        instances = instances,
    }
end

local function CaptureLockouts()
    if type(GetNumSavedInstances) ~= "function" or type(GetSavedInstanceInfo) ~= "function" then
        return nil
    end

    local count = GetNumSavedInstances() or 0
    local lockouts = {}
    for index = 1, count do
        
        
        
        
        
        
        
        
        
        
        
        
        
        local name, _, reset, difficultyID, locked, extended, _, isRaid, _,
              difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(index)

        local encounters = {}
        if type(numEncounters) == "number" and type(GetSavedInstanceEncounterInfo) == "function" then
            for encounterIndex = 1, numEncounters do
                local bossName, _, isKilled = GetSavedInstanceEncounterInfo(index, encounterIndex)
                table.insert(encounters, { name = bossName, killed = isKilled and true or false })
            end
        end

        table.insert(lockouts, {
            name = name,
            difficultyID = difficultyID,
            difficultyName = difficultyName,
            isRaid = isRaid and true or false,
            locked = locked and true or false,
            extended = extended and true or false,
            resetSeconds = type(reset) == "number" and reset or nil,
            
            
            
            
            
            
            numEncounters = type(numEncounters) == "number" and numEncounters or nil,
            encounterProgress = type(encounterProgress) == "number" and encounterProgress or nil,
            encounters = encounters,
        })
    end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    if type(GetNumSavedWorldBosses) == "function" and type(GetSavedWorldBossInfo) == "function" then
        local worldCount = GetNumSavedWorldBosses() or 0
        for index = 1, worldCount do
            local name, _, reset = GetSavedWorldBossInfo(index)
            if name then
                table.insert(lockouts, {
                    name = name,
                    isRaid = true,
                    
                    
                    
                    isWorldBoss = true,
                    locked = true,
                    extended = false,
                    resetSeconds = type(reset) == "number" and reset or nil,
                    numEncounters = 1,
                    encounterProgress = 1,
                    encounters = { { name = name, killed = true } },
                })
            end
        end
    end

    return lockouts
end









local TARGET_CURRENCY_IDS = { 3028, 3310, 3316, 3465, 3418, 3509, 3442, 3443, 3444, 3445, 3446 }

local function CaptureCurrencies()
    local currencies = {}
    local listSize = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize
    local listInfo = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo

    if type(listSize) == "function" and type(listInfo) == "function" then
        local count = listSize() or 0
        for index = 1, count do
            local info = listInfo(index)
            if type(info) == "table" and not info.isHeader and type(info.currencyID) == "number" then
                currencies[info.currencyID] = {
                    quantity = info.quantity,
                    totalEarned = info.totalEarned,
                    maxQuantity = info.maxQuantity,
                    name = info.name,
                    iconFileID = info.iconFileID or info.icon,
                    description = info.description,
                    useTotalEarnedForMaxQty = info.useTotalEarnedForMaxQty,
                }
            end
        end
    end

    
    local getInfo = C_CurrencyInfo and (C_CurrencyInfo.GetCurrencyInfo or C_CurrencyInfo.GetCurrencyInfoByID or C_CurrencyInfo.GetBasicCurrencyInfo)
    if type(getInfo) == "function" then
        for _, id in ipairs(TARGET_CURRENCY_IDS) do
            if not currencies[id] then
                local ok, info = pcall(getInfo, id)
                if ok and type(info) == "table" then
                    currencies[id] = {
                        quantity = info.quantity or 0,
                        totalEarned = info.totalEarned or 0,
                        maxQuantity = info.maxQuantity or 0,
                        name = info.name,
                        iconFileID = info.iconFileID or info.icon,
                        description = info.description,
                        useTotalEarnedForMaxQty = info.useTotalEarnedForMaxQty,
                    }
                end
            end
        end
    end

    
    local troveCount = 0
    local troveItems = { 235588, 224407, 224408, 235589 }
    if type(C_Item) == "table" and type(C_Item.GetItemCount) == "function" then
        for _, itemID in ipairs(troveItems) do
            local ok, c = pcall(C_Item.GetItemCount, itemID, true)
            if ok and type(c) == "number" and c > 0 then
                troveCount = troveCount + c
            end
        end
    end
    currencies["trove"] = {
        quantity = troveCount,
        totalEarned = troveCount,
        maxQuantity = 1,
        name = "Trovehunter's Bounty",
        iconFileID = "Interface\\Icons\\inv_delve_bounty_map",
        description = "Delve bounty map that guarantees additional Bountiful Delve rewards.",
    }

    if next(currencies) == nil then return nil end
    return currencies
end




local CREST_TRACK_IDS = {
    [3442] = "Adventurer",
    [3443] = "Veteran",
    [3444] = "Champion",
    [3445] = "Hero",
    [3446] = "Myth",
}

local KNOWN_TRACK_NAMES = { "Adventurer", "Veteran", "Champion", "Hero", "Myth" }



local TRACK_BANDS = {
    { name = "Adventurer", ranks = { 266, 269, 272, 276, 279, 282 } },
    { name = "Veteran",    ranks = { 279, 282, 285, 289, 292, 295 } },
    { name = "Champion",   ranks = { 292, 295, 298, 302, 305, 308 } },
    { name = "Hero",       ranks = { 305, 308, 311, 315, 318, 321 } },
    { name = "Myth",       ranks = { 318, 321, 324, 328, 331, 334 } },
}


local function ResolveTrackFromText(text)
    if type(text) ~= "string" or IsSecret(text) then return nil end

    if type(C_CurrencyInfo) == "table" then
        local getInfo = C_CurrencyInfo.GetCurrencyInfo or C_CurrencyInfo.GetBasicCurrencyInfo
        if type(getInfo) == "function" then
            for currencyID, trackName in pairs(CREST_TRACK_IDS) do
                local ok, info = pcall(getInfo, currencyID)
                if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
                    if text:find(info.name, 1, true) then
                        return trackName
                    end
                end
            end
        end
    end

    for _, trackName in ipairs(KNOWN_TRACK_NAMES) do
        
        
        
        
        
        if text:find(trackName .. "%f[%A]") or text:lower():find(trackName:lower() .. "%f[%A]") then
            return trackName
        end
    end

    return nil
end


local function ResolveTrackName(text, ilvl, rank)
    local fromText = ResolveTrackFromText(text)
    if fromText then return fromText end

    if type(ilvl) == "number" and type(rank) == "number" then
        for _, band in ipairs(TRACK_BANDS) do
            if band.ranks[rank] == ilvl then
                return band.name
            end
        end
    end

    return nil
end






















local function ParseUpgradeLines(lines, ilvl)
    local trackOnly
    local looseRank, looseMaxRank

    for _, line in ipairs(lines) do
        if type(line) == "table" then
            if type(TooltipUtil) == "table" and type(TooltipUtil.SurfaceArgs) == "function" then
                pcall(TooltipUtil.SurfaceArgs, line)
            end

            local leftText = line.leftText
            if type(leftText) == "string" and not IsSecret(leftText) then
                local track = ResolveTrackFromText(leftText)
                local rankStr, maxRankStr = leftText:match("(%d+)/(%d+)")
                local rank, maxRank = tonumber(rankStr), tonumber(maxRankStr)

                if track and rank and maxRank then
                    return track, rank, maxRank
                elseif track and not trackOnly then
                    trackOnly = track
                elseif rank and maxRank and not looseRank then
                    looseRank, looseMaxRank = rank, maxRank
                end
            end
        end
    end

    
    
    
    if trackOnly then
        return trackOnly, nil, nil
    end

    if looseRank then
        local banded = ResolveTrackName(nil, ilvl, looseRank)
        if banded then
            return banded, looseRank, looseMaxRank
        end
    end

    return nil, nil, nil
end


local FIRST_SLOT, LAST_SLOT = 1, 19

local function CaptureGear()
    if type(GetInventoryItemLink) ~= "function" then return nil end

    local location = ItemLocation
    local getLevel = C_Item and C_Item.GetCurrentItemLevel

    local gear = {}
    for slot = FIRST_SLOT, LAST_SLOT do
        if slot ~= 4 and slot ~= 19 then
            local link = GetInventoryItemLink("player", slot)
            if link ~= nil then
                local entry = { itemLink = link, slot = slot }

                if type(location) == "table" and type(location.CreateFromEquipmentSlot) == "function"
                        and type(getLevel) == "function" then
                    local where = location.CreateFromEquipmentSlot(location, slot)
                    if where then
                        entry.itemLevel = getLevel(where)
                    end
                end

                
                
                
                
                if type(C_TooltipInfo) == "table" and type(C_TooltipInfo.GetInventoryItem) == "function" then
                    local ok, tooltipData = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)
                    if ok and type(tooltipData) == "table" and type(tooltipData.lines) == "table" then
                        if type(TooltipUtil) == "table" and type(TooltipUtil.SurfaceArgs) == "function" then
                            pcall(TooltipUtil.SurfaceArgs, tooltipData)
                        end
                        local track, rank, maxRank = ParseUpgradeLines(tooltipData.lines, entry.itemLevel)
                        entry.track = track
                        entry.rank = rank
                        entry.maxRank = maxRank
                    end
                end

                gear[slot] = entry
            end
        end
    end

    if next(gear) == nil then return nil end
    return gear
end

local function CaptureFactions()
    local getIDs = C_MajorFactions and C_MajorFactions.GetMajorFactionIDs
    local getData = C_MajorFactions and C_MajorFactions.GetMajorFactionData
    if type(getIDs) ~= "function" or type(getData) ~= "function" then return nil end

    local ids = getIDs()
    if type(ids) ~= "table" then return nil end

    local factions = {}
    for _, id in ipairs(ids) do
        local data = getData(id)
        if type(data) == "table" then
            
            
            
            
            factions[id] = {
                renownLevel = data.renownLevel,
                earned = data.renownReputationEarned,
                threshold = data.renownLevelThreshold,
            }
        end
    end

    if next(factions) == nil then return nil end
    return factions
end

































local WEEKLY_CACHE_CAP = 2







Data.WEEKLY_CACHE_QUEST_IDS = {}
Data.WEEKLY_CACHE_CAP = WEEKLY_CACHE_CAP










function Data:CountWeeklyCaches()
    local ids = self.WEEKLY_CACHE_QUEST_IDS
    if type(ids) ~= "table" or #ids == 0 then return nil end

    local isFlagged = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    if type(isFlagged) ~= "function" then return nil end

    local opened = 0
    for _, questID in ipairs(ids) do
        if Try(isFlagged, questID) == true then
            opened = opened + 1
        end
    end
    return opened
end





local function CaptureWeeklyCaches()
    local opened = Data:CountWeeklyCaches()
    if type(opened) ~= "number" then return nil end
    return { opened = opened, cap = WEEKLY_CACHE_CAP }
end





local function BuildSnapshot(old)
    old = old or {}
    local row = {}

    row.name = Try(UnitName, "player") or old.name
    row.realm = Try(GetRealmName) or old.realm

    do
        local ok, localizedClass, classFile = pcall(UnitClass, "player")
        if ok then
            row.class = localizedClass
            row.classFile = classFile
        else
            row.class, row.classFile = old.class, old.classFile
        end
    end

    row.level = Try(UnitLevel, "player") or old.level

    do
        local specIndex = Try(GetSpecialization)
        if type(specIndex) == "number" and specIndex > 0 then
            local id, name = Try(GetSpecializationInfo, specIndex)
            row.spec = id or old.spec
            row.specName = name or old.specName
        else
            row.spec = old.spec
            row.specName = old.specName
        end
    end

    row.capturedAt = Try(GetServerTime) or old.capturedAt or 0
    row.resetAt = ComputeResetAt(row.capturedAt)
    row.schema = SCHEMA

    row.avgItemLevel = SafeBuild(CaptureAvgItemLevel, old.avgItemLevel)
    row.vault = SafeBuild(CaptureVault, old.vault)
    row.mplus = SafeBuild(CaptureMythicPlus, old.mplus)
    row.setPieces = SafeBuild(CaptureSetPieces, old.setPieces)
    row.lockouts = SafeBuild(CaptureLockouts, old.lockouts)
    
    
    row.vaultUnclaimed = SafeBuild(CaptureVaultUnclaimed, old.vaultUnclaimed)
    row.currencies = SafeBuild(CaptureCurrencies, old.currencies)
    row.gear = SafeBuild(CaptureGear, old.gear)
    row.factions = SafeBuild(CaptureFactions, old.factions)
    row.weeklyCaches = SafeBuild(CaptureWeeklyCaches, old.weeklyCaches)

    return row
end








function Data:EnsureSchema()
    local stored = db.schema

    if stored == nil then
        
        
        db.schema = SCHEMA
        return
    end

    if stored < SCHEMA then
        local ok = true
        for version = stored + 1, SCHEMA do
            local migrate = MIGRATIONS[version]
            if migrate then
                local migrateOK, err = pcall(migrate, db)
                if not migrateOK then
                    ok = false
                    if ThugUI.Diagnostics then
                        ThugUI.Diagnostics:Log("SEASONAL", "migration to v%d failed: %s",
                            version, tostring(err))
                    end
                    break
                end
            end
        end
        if ok then db.schema = SCHEMA end
        
        
        return
    end

    if stored > SCHEMA then
        
        
        
        db.newerSchemaDetected = true
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("SEASONAL",
                "ThugUIDB.Seasonal.schema (%d) is newer than this build's (%d) -- not touching saved data",
                stored, SCHEMA)
        end
    end
end









function Data:Snapshot(reason)
    if InCombatLockdown and InCombatLockdown() then
        
        
        
        
        self.pendingReason = reason or "combat"
        return false
    end

    local key = self:GetCurrentKey()
    local old = db.characters[key]
    db.characters[key] = BuildSnapshot(old)

    
    
    
    
    db.seasonRaid = CaptureSeasonRaid(db.seasonRaid)

    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("SEASONAL", "snapshot taken for %s (%s)", key, tostring(reason))
    end
    return true
end




local SNAPSHOT_EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "UPDATE_INSTANCE_INFO",
    "WEEKLY_REWARDS_UPDATE",
    "CHALLENGE_MODE_MAPS_UPDATE",
    "CURRENCY_DISPLAY_UPDATE",
}





local DEBOUNCE_SECONDS = 2




local LOCKOUT_REFRESH_THROTTLE_SECONDS = 3
local lastLockoutRefreshTime = -999999  





local function IsGearDataComplete()
    if db == nil or db.characters == nil then return true end

    local key = Data:GetCurrentKey()
    local row = db.characters[key]
    if not row or not row.gear then return true end

    for slot, entry in pairs(row.gear) do
        if type(entry) == "table" and entry.itemLink and not entry.track then
            
            return false
        end
    end
    return true
end







local function RequestLockoutRefresh()
    if type(RequestRaidInfo) ~= "function" then return end

    
    local now = Try(GetTime) or 0
    if now - lastLockoutRefreshTime < LOCKOUT_REFRESH_THROTTLE_SECONDS then
        return
    end
    lastLockoutRefreshTime = now

    
    
    
    
    pcall(RequestRaidInfo)

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(2, function() pcall(RequestRaidInfo) end)
        C_Timer.After(10, function() pcall(RequestRaidInfo) end)
    end
end



function Data:TestResetLockoutRefreshThrottle()
    lastLockoutRefreshTime = -999999
end

function Data:CreateDriver()
    if self.driver then return self.driver end

    local driver = CreateFrame("Frame", "ThugUI_SeasonalDataDriver")
    self.driver = driver

    for _, event in ipairs(SNAPSHOT_EVENTS) do
        driver:RegisterEvent(event)
    end
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")

    
    
    
    pcall(driver.RegisterEvent, driver, "ENCOUNTER_END")
    pcall(driver.RegisterEvent, driver, "BOSS_KILL")

    local requestedOnLogin = false
    local generation = 0
    local reSnapshotGeneration = 0

    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if self.pendingReason then
                local reason = self.pendingReason
                self.pendingReason = nil
                
                
                
                self:Snapshot(reason)
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            if not requestedOnLogin then
                requestedOnLogin = true
                
                
                
                
                
                if type(RequestRaidInfo) == "function" then pcall(RequestRaidInfo) end
                if type(C_MythicPlus) == "table" and type(C_MythicPlus.RequestMapInfo) == "function" then
                    pcall(C_MythicPlus.RequestMapInfo)
                end
                if type(C_CurrencyInfo) == "table"
                        and type(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters) == "function" then
                    pcall(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters)
                end

                
                
                
                
                
                
                
                
                
                reSnapshotGeneration = reSnapshotGeneration + 1
                local thisGen = reSnapshotGeneration

                if C_Timer and type(C_Timer.After) == "function" then
                    
                    C_Timer.After(5, function()
                        if thisGen ~= reSnapshotGeneration then return end
                        if IsGearDataComplete() then
                            reSnapshotGeneration = thisGen + 1
                            return
                        end
                        self:Snapshot("post-login-retry")
                    end)

                    
                    C_Timer.After(15, function()
                        if thisGen ~= reSnapshotGeneration then return end
                        if IsGearDataComplete() then
                            reSnapshotGeneration = thisGen + 1
                            return
                        end
                        self:Snapshot("post-login-retry")
                    end)

                    
                    C_Timer.After(30, function()
                        if thisGen ~= reSnapshotGeneration then return end
                        if not IsGearDataComplete() then
                            self:Snapshot("post-login-retry")
                        end
                    end)
                end
            end
            
            
            RequestLockoutRefresh()
        end

        
        
        
        
        
        if event == "ENCOUNTER_END" or event == "BOSS_KILL" then
            RequestLockoutRefresh()
            return
        end

        
        
        
        
        generation = generation + 1
        local myGeneration = generation
        if C_Timer and type(C_Timer.After) == "function" then
            C_Timer.After(DEBOUNCE_SECONDS, function()
                if myGeneration == generation then
                    self:Snapshot(event)
                end
            end)
        else
            
            self:Snapshot(event)
        end
    end)

    return driver
end





function Data:GetCurrentKey()
    local name = Try(UnitName, "player") or "?"
    local realm = Try(GetRealmName) or "?"
    return name .. "-" .. realm
end












function Data:GetMaxLevel()
    if type(GetMaxLevelForPlayerExpansion) == "function" then
        local ok, level = pcall(GetMaxLevelForPlayerExpansion)
        if ok and type(level) == "number" and level > 0 then
            return level
        end
    end

    if type(GetMaxPlayerLevel) == "function" then
        local ok, level = pcall(GetMaxPlayerLevel)
        if ok and type(level) == "number" and level > 0 then
            return level
        end
    end

    if type(MAX_PLAYER_LEVEL) == "number" and MAX_PLAYER_LEVEL > 0 then
        return MAX_PLAYER_LEVEL
    end

    return 90
end

function Data:ShowLowLevel()
    db = db or EnsureDB()
    db.settings = db.settings or {}
    return db.settings.showLowLevel == true
end

function Data:SetShowLowLevel(enabled)
    db = db or EnsureDB()
    db.settings = db.settings or {}
    db.settings.showLowLevel = (enabled == true)
end
















function Data:IsRosterVisible(key, showLowLevel)
    if key == self:GetCurrentKey() then
        return true
    end

    db = db or EnsureDB()
    local row = type(db.characters) == "table" and db.characters[key] or nil
    if not row or type(row.level) ~= "number" then
        return true
    end

    if row.level >= self:GetMaxLevel() then
        return true
    end

    return showLowLevel == true
end

function Data:GetRoster(inEditMode)
    db = db or EnsureDB()
    db.settings = db.settings or {}
    db.settings.masterRosterOrder = db.settings.masterRosterOrder or db.settings.rosterOrder or {}
    local master = db.settings.masterRosterOrder

    local currentKey = self:GetCurrentKey()

    local allKeysMap = {}
    if type(db.characters) == "table" then
        for key in pairs(db.characters) do
            allKeysMap[key] = true
        end
    end
    allKeysMap[currentKey] = true

    local seen = {}
    local validMaster = {}
    for _, key in ipairs(master) do
        if allKeysMap[key] and not seen[key] then
            table.insert(validMaster, key)
            seen[key] = true
        end
    end

    local unlisted = {}
    for key in pairs(allKeysMap) do
        if not seen[key] then
            table.insert(unlisted, key)
        end
    end
    table.sort(unlisted)
    for _, key in ipairs(unlisted) do
        table.insert(validMaster, key)
        seen[key] = true
    end

    db.settings.masterRosterOrder = validMaster
    db.settings.rosterOrder = validMaster
    master = validMaster

    if inEditMode then
        return master
    end

    
    
    
    
    
    
    local roster = { currentKey }
    local showLowLevel = self:ShowLowLevel()
    for _, key in ipairs(master) do
        if key ~= currentKey and self:IsRosterVisible(key, showLowLevel) then
            table.insert(roster, key)
        end
    end

    return roster
end

function Data:ReorderMasterRoster(key, delta)
    db = db or EnsureDB()
    db.settings = db.settings or {}
    db.settings.masterRosterOrder = db.settings.masterRosterOrder or db.settings.rosterOrder or {}
    local master = db.settings.masterRosterOrder

    local idx
    for i, k in ipairs(master) do
        if k == key then idx = i break end
    end

    if not idx then return end
    local targetIdx = idx + delta
    if targetIdx < 1 or targetIdx > #master then return end

    master[idx], master[targetIdx] = master[targetIdx], master[idx]
end

function Data:ReorderRoster(key, delta)
    self:ReorderMasterRoster(key, delta)
end

function Data:GetCharacter(key)
    return db.characters[key]
end





function Data:IsStale(key)
    local row = db.characters[key]
    if not row then return true end
    local now = Try(GetServerTime) or 0
    return now >= (row.resetAt or 0)
end

function Data:GetAgeSeconds(key)
    local row = db.characters[key]
    if not row then return nil end
    local now = Try(GetServerTime) or 0
    return now - (row.capturedAt or now)
end





































function Data:MergeVaultBoxes(key, entries)
    if type(entries) ~= "table" or next(entries) == nil then return end
    local row = db.characters[key]
    if not row then return end

    
    
    
    
    
    local resolvedBy = self:GetCurrentKey()

    local cache = row.vaultBoxes
    if type(cache) ~= "table"
            or cache.resetAt ~= row.resetAt
            or cache.resolvedBy ~= resolvedBy then
        
        
        
        
        
        
        
        
        if type(cache) == "table"
                and cache.resolvedBy == resolvedBy
                and cache.resetAt ~= row.resetAt
                and row.vaultUnclaimed then
            row.vaultBoxesPending = cache
        end
        cache = { resetAt = row.resetAt }
    end

    for index, entry in pairs(entries) do
        cache[index] = entry
    end
    cache.resolvedAt = Try(GetServerTime) or cache.resolvedAt or 0
    cache.resolvedBy = resolvedBy

    row.vaultBoxes = cache
end









function Data:GetSeasonRaid()
    return db and db.seasonRaid
end

function Data:GetVaultBoxes(key)
    local row = db.characters[key]
    local cache = row and row.vaultBoxes
    if type(cache) ~= "table" then return nil end
    if cache.resetAt ~= row.resetAt then return nil end
    
    
    
    
    if cache.resolvedBy ~= key then return nil end
    return cache
end









function Data:GetPendingVaultBoxes(key)
    local row = db.characters[key]
    local pending = row and row.vaultBoxesPending
    if type(pending) ~= "table" then return nil end
    if pending.resolvedBy ~= key then return nil end

    
    if row.vaultUnclaimed == false then
        row.vaultBoxesPending = nil
        return nil
    end

    return pending
end



function Data:Forget(key)
    db.characters[key] = nil
end





function Data:Initialize()
    db = ThugUIDB.Seasonal
    db.characters = db.characters or {}
    db.settings = db.settings or {}
    self:EnsureSchema()

    
    
    ThugUI.Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal.Data = self

    self:CreateDriver()
end

return Data
