
























ThugUI = ThugUI or {}
ThugUI_Config = ThugUI_Config or {}

ThugUI.CooldownViewer = ThugUI.CooldownViewer or {}
local CV = ThugUI.CooldownViewer

local Data = {}
CV.Data = Data

Data.GRID_COLS = 10
Data.GRID_ROWS = 10

















Data.MODES = {
    { value = "cooldown",   text = "Show when ready" },
    { value = "recharging", text = "Show while recharging" },
    { value = "proc",       text = "Show when ready and procced" },
    { value = "always",     text = "Always show (with sweep)" },
    { value = "aura",       text = "Show while buff active" },
}




















Data.COLLAPSE_MODES = {
    { value = "none",    text = "Leave the gap" },
    { value = "rows",    text = "Rows collapse sideways" },
    { value = "columns", text = "Columns collapse vertically" },
    { value = "both",    text = "Both — keep the smallest shape" },
}




local COLLAPSE_DIRECTIONS = {
    rows = {
        { value = "auto",  text = "Auto (from anchor)" },
        { value = "left",  text = "Always left" },
        { value = "right", text = "Always right" },
    },
    columns = {
        { value = "auto", text = "Auto (from anchor)" },
        { value = "up",   text = "Always up" },
        { value = "down", text = "Always down" },
    },
    
    both = {
        { value = "auto",        text = "Auto (from anchor)" },
        { value = "topleft",     text = "Toward top-left" },
        { value = "topright",    text = "Toward top-right" },
        { value = "bottomleft",  text = "Toward bottom-left" },
        { value = "bottomright", text = "Toward bottom-right" },
    },
}

function Data.GetCollapseDirections(mode)
    return COLLAPSE_DIRECTIONS[mode] or COLLAPSE_DIRECTIONS.rows
end


function Data.IsDirectionValid(mode, direction)
    if direction == "auto" then return true end
    for _, option in ipairs(Data.GetCollapseDirections(mode)) do
        if option.value == direction then return true end
    end
    return false
end












local function AutoAxesFromPlacements(profile)
    local anchorCol = profile.anchorCol or 0
    local anchorRow = profile.anchorRow or 0

    local left, right, above, below = 0, 0, 0, 0

    for key in pairs(profile.placements or {}) do
        local row, col = Data.ParseCellKey(key)
        if row and col then
            if col <= anchorCol then left = left + 1 else right = right + 1 end
            if row <= anchorRow then above = above + 1 else below = below + 1 end
        end
    end

    
    
    local packRight, packDown
    if left ~= right then packRight = left > right end
    if above ~= below then packDown  = above > below end

    return packRight, packDown
end
















function Data.ResolveAutoAxes(profile)
    local fromShape, fromShapeDown = AutoAxesFromPlacements(profile)

    local autoRight = fromShape
    local autoDown  = fromShapeDown

    if autoRight == nil then
        autoRight = (profile.anchorCol or 0) >= Data.GRID_COLS / 2
    end
    if autoDown == nil then
        autoDown = (profile.anchorRow or 0) >= Data.GRID_ROWS / 2
    end

    return autoRight, autoDown
end






function Data.ResolveCollapseDirection(profile)
    local mode = profile.collapse or "none"
    local direction = profile.collapseDirection or "auto"

    if mode == "columns" then
        if direction == "up" or direction == "down" then return direction end
        local _, down = Data.ResolveCollapseAxes(profile)
        return down and "down" or "up"
    end

    if direction == "left" or direction == "right" then return direction end
    local right = Data.ResolveCollapseAxes(profile)
    return right and "right" or "left"
end









function Data.ResolveCollapseAxes(profile)
    local mode = profile.collapse or "none"
    local direction = profile.collapseDirection or "auto"

    local autoRight, autoDown = Data.ResolveAutoAxes(profile)

    if mode == "both" then
        if direction == "topleft"     then return false, false end
        if direction == "topright"    then return true,  false end
        if direction == "bottomleft"  then return false, true  end
        if direction == "bottomright" then return true,  true  end
        return autoRight, autoDown
    end

    if mode == "columns" then
        local down = autoDown
        if direction == "up" then down = false
        elseif direction == "down" then down = true end
        return autoRight, down
    end

    local right = autoRight
    if direction == "left" then right = false
    elseif direction == "right" then right = true end
    return right, autoDown
end


function Data.DescribeCollapse(profile)
    local packRight, packDown = Data.ResolveCollapseAxes(profile)
    return packRight and "right" or "left", packDown and "down" or "up"
end

function Data.ModeText(mode)
    for _, m in ipairs(Data.MODES) do
        if m.value == mode then return m.text end
    end
    return mode or "?"
end





function Data.CellKey(row, col)
    return row .. ":" .. col
end

function Data.ParseCellKey(key)
    local row, col = key:match("^(%d+):(%d+)$")
    return tonumber(row), tonumber(col)
end















local function ClassKey()
    local _, class = UnitClass("player")
    return class and ("class:" .. class) or nil
end


local function SpecIndex()
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        local ok, index = pcall(C_SpecializationInfo.GetSpecialization)
        if ok and type(index) == "number" and index > 0 then return index end
    end
    if GetSpecialization then
        local index = GetSpecialization()
        if type(index) == "number" and index > 0 then return index end
    end
    return nil
end


local function SpecInfo(index)
    local fn = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo)
        or GetSpecializationInfo
    if not fn then return nil end
    local ok, specID, name, _, icon = pcall(fn, index)
    if not ok then return nil end
    return specID, name, icon
end




function Data.GetActiveSpecID()
    local index = SpecIndex()
    if index then
        local specID, name, icon = SpecInfo(index)
        if specID and specID > 0 then return specID end
        
        
        if specID == 0 then return nil end
    end
    return ClassKey()
end



function Data.GetPlayerSpecs()
    local specs = {}

    
    for index = 1, 4 do
        local specID, name, icon = SpecInfo(index)
        if specID then
            table.insert(specs, { specID = specID, name = name, icon = icon, index = index })
        end
    end

    
    if #specs == 0 then
        
        
        
        local localized, class = UnitClass("player")
        if class then
            specs = { { specID = ClassKey(), name = localized or class, icon = nil, index = 1 } }
        end
    end

    return specs
end


function Data.GetSpecName(specID)
    if not specID then return "Unknown" end

    
    if type(specID) == "string" and specID:match("^class:") then
        local localized, class = UnitClass("player")
        return localized or class or "Unknown"
    end

    
    if type(specID) == "number" then
        
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID then
            local ok, id, name = pcall(C_SpecializationInfo.GetSpecializationInfoByID, specID)
            if ok and name then return name end
        end

        
        if GetSpecializationInfoByID then
            local _, name = GetSpecializationInfoByID(specID)
            if name then return name end
        end

        
        return "Spec " .. specID
    end

    return "Unknown"
end





local function DefaultProfile()
    return {
        enabled = false,
        onlyInCombat = true,
        followCursor = true,
        iconSize = 32,
        padding = 4,
        scale = 1.0,
        collapse = "rows",
        collapseDirection = "auto",
        showProcGlow = true,
        
        
        anchorCol = 0,
        anchorRow = 0,
        point = nil,
        
        
        
        
        
        
        locked = true,
        placements = {},
    }
end

Data.DefaultProfile = DefaultProfile

local function Store()
    ThugUI_Config.cv = ThugUI_Config.cv or {}
    ThugUI_Config.cv.profiles = ThugUI_Config.cv.profiles or {}
    return ThugUI_Config.cv
end






function Data.GetProfile(specID)
    specID = specID or Data.GetActiveSpecID()
    if not specID or specID == 0 then return DefaultProfile() end

    local store = Store()
    local profile = store.profiles[specID]
    if not profile then
        profile = DefaultProfile()
        store.profiles[specID] = profile
    else
        
        for k, v in pairs(DefaultProfile()) do
            if profile[k] == nil then profile[k] = v end
        end
        profile.placements = profile.placements or {}
    end
    return profile
end

function Data.GetActiveProfile()
    return Data.GetProfile(Data.GetActiveSpecID())
end



function Data.GetPlacements(profile)
    local list = {}
    for key, placement in pairs(profile.placements) do
        local row, col = Data.ParseCellKey(key)
        
        
        
        
        if row and col and placement and (placement.spellID or placement.categoryID) then
            table.insert(list, {
                row = row, col = col, key = key,
                spellID = placement.spellID,
                categoryID = placement.categoryID,
                mode = placement.mode or "cooldown",
            })
        end
    end
    table.sort(list, function(a, b)
        if a.row == b.row then return a.col < b.col end
        return a.row < b.row
    end)
    return list
end

function Data.GetPlacement(profile, row, col)
    return profile.placements[Data.CellKey(row, col)]
end

function Data.SetPlacement(profile, row, col, spellID, mode)
    if row < 1 or row > Data.GRID_ROWS or col < 1 or col > Data.GRID_COLS then return end
    profile.placements[Data.CellKey(row, col)] = spellID
        and { spellID = spellID, mode = mode or "cooldown" }
        or nil
end







function Data.SetCategoryPlacement(profile, row, col, categoryID, mode)
    if row < 1 or row > Data.GRID_ROWS or col < 1 or col > Data.GRID_COLS then return end
    profile.placements[Data.CellKey(row, col)] = categoryID
        and { categoryID = categoryID, mode = mode or "cooldown" }
        or nil
end

function Data.ClearPlacement(profile, row, col)
    profile.placements[Data.CellKey(row, col)] = nil
end

function Data.MovePlacement(profile, fromRow, fromCol, toRow, toCol)
    local from = Data.CellKey(fromRow, fromCol)
    local to = Data.CellKey(toRow, toCol)
    if from == to then return end
    profile.placements[to], profile.placements[from] = profile.placements[from], profile.placements[to]
end




















function Data.IsSpellPlaced(profile, spellID, mode)
    for _, placement in pairs(profile.placements) do
        if Data.PlacementKey(placement) == spellID then
            if mode == nil then return true end
            local placementMode = placement.mode or "cooldown"
            local isAura = placementMode == "aura"
            if mode == "aura" and isAura then return true end
            if mode == "other" and not isAura then return true end
        end
    end
    return false
end











Data.SOURCES = {
    { value = "essential",  text = "Essential cooldowns" },
    { value = "utility",    text = "Utility cooldowns" },
    { value = "buffs",      text = "Tracked buffs" },
    { value = "spellbook",  text = "Spellbook (all)" },
    { value = "all",        text = "Everything" },
}



















local CATEGORIES_BY_SOURCE = {
    essential = { "Essential" },
    utility   = { "Utility" },
    buffs     = { "TrackedBuff", "TrackedBar" },
}



















local function CooldownViewerCategories()
    local categories = {}
    if not Enum or not Enum.CooldownViewerCategory then
        return categories
    end

    for name, value in pairs(Enum.CooldownViewerCategory) do
        if type(value) == "number" and value >= 0 then
            table.insert(categories, { name = name, value = value })
        end
    end

    table.sort(categories, function(a, b) return a.value < b.value end)
    return categories
end

















local function CooldownViewerSpellIDs(categoryName)
    if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
        return {}
    end
    local category = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory[categoryName]
    if category == nil then return {} end

    local ok, cooldownIDs = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, category)
    if not ok or type(cooldownIDs) ~= "table" then return {} end

    local spellIDs = {}
    for _, cooldownID in ipairs(cooldownIDs) do
        local infoOK, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
        if infoOK and info then
            local spellID = Data.PickerSpellIDFor(info)
            if spellID then table.insert(spellIDs, spellID) end
        end
    end
    return spellIDs
end






local function CooldownViewerCategoryIDs(categoryName)
    if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
        return {}
    end
    local category = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory[categoryName]
    if category == nil then return {} end

    local ok, cooldownIDs = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, category)
    if not ok or type(cooldownIDs) ~= "table" then return {} end

    local categoryIDs = {}
    for _, cooldownID in ipairs(cooldownIDs) do
        local infoOK, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
        if infoOK and info and info.spellCategoryID and not Data.PickerSpellIDFor(info) then
            table.insert(categoryIDs, info.spellCategoryID)
        end
    end
    return categoryIDs
end








function Data.PickerSpellIDFor(info)
    if not info then return nil end
    return info.overrideSpellID
        or info.spellID
        or info.overrideTooltipSpellID
        or (info.linkedSpellIDs and info.linkedSpellIDs[1])
end








function Data.PlacementKey(p)
    if not p then return nil end
    if p.spellID then return p.spellID end
    if p.categoryID then return "cat:" .. p.categoryID end
    return nil
end



local cooldownInfoCache, cooldownInfoCacheSpec

























local cooldownIDsBySpell









local function Preferred(existing, candidate)
    if not existing then return candidate end

    local have = existing.linkedSpellIDs and #existing.linkedSpellIDs or 0
    local want = candidate.linkedSpellIDs and #candidate.linkedSpellIDs or 0
    if want ~= have then
        return want > have and candidate or existing
    end

    if candidate.hasAura and not existing.hasAura then return candidate end
    return existing
end


















local function IndexableSpellIDs(info)
    local ids = {}

    local function Add(id)
        if id then ids[#ids + 1] = id end
    end

    Add(info.spellID)
    Add(info.overrideSpellID)
    Add(info.overrideTooltipSpellID)
    for _, id in ipairs(info.linkedSpellIDs or {}) do
        Add(id)
    end

    return ids
end

local function BuildCooldownInfoCache()
    local cache = {}
    cooldownIDsBySpell = {}
    if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
        return cache
    end

    for _, item in ipairs(CooldownViewerCategories()) do
        local categoryName = item.name
        local category = item.value
        if category ~= nil then
            local ok, cooldownIDs = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, category)
            if ok and type(cooldownIDs) == "table" then
                for _, cooldownID in ipairs(cooldownIDs) do
                    local infoOK, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
                    if infoOK and info then
                        
                        
                        for _, id in ipairs(IndexableSpellIDs(info)) do
                            cache[id] = Preferred(cache[id], info)

                            
                            
                            
                            
                            
                            if info.cooldownID then
                                local ids = cooldownIDsBySpell[id]
                                if not ids then
                                    ids = {}
                                    cooldownIDsBySpell[id] = ids
                                end
                                local seen = false
                                for _, existing in ipairs(ids) do
                                    if existing == info.cooldownID then seen = true break end
                                end
                                if not seen then ids[#ids + 1] = info.cooldownID end
                            end
                        end
                    end
                end
            end
        end
    end
    return cache
end




function Data.GetCooldownInfoForSpell(spellID)
    if not spellID then return nil end

    local specID = Data.GetActiveSpecID()
    if not cooldownInfoCache or cooldownInfoCacheSpec ~= specID then
        cooldownInfoCache = BuildCooldownInfoCache()
        cooldownInfoCacheSpec = specID

        
        
        
        local count = 0
        for _ in pairs(cooldownInfoCache) do count = count + 1 end
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("CV", "cooldown cache built for %s: %d indexed spell ids",
                Data.GetSpecName(specID), count)
        end
    end
    return cooldownInfoCache[spellID]
end









function Data.GetCooldownIDsForSpell(spellID)
    if not spellID then return {} end
    
    
    
    Data.GetCooldownInfoForSpell(spellID)
    return (cooldownIDsBySpell and cooldownIDsBySpell[spellID]) or {}
end



















local categoryInfoCache, categoryInfoCacheSpec

function Data.InvalidateCooldownInfoCache()
    cooldownInfoCache, cooldownInfoCacheSpec = nil, nil
    cooldownIDsBySpell = nil
    categoryInfoCache, categoryInfoCacheSpec = nil, nil
end







local function BuildCategoryInfoCache()
    local cache = {}
    if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
        return cache
    end

    for _, item in ipairs(CooldownViewerCategories()) do
        local category = item.value
        local ok, cooldownIDs = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, category)
        if ok and type(cooldownIDs) == "table" then
            for _, cooldownID in ipairs(cooldownIDs) do
                local infoOK, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
                if infoOK and info and info.spellCategoryID and not Data.PickerSpellIDFor(info) then
                    if not cache[info.spellCategoryID] then
                        cache[info.spellCategoryID] = info
                    end
                end
            end
        end
    end
    return cache
end



function Data.GetCategoryInfo(categoryID)
    if not categoryID then return nil end

    local specID = Data.GetActiveSpecID()
    if not categoryInfoCache or categoryInfoCacheSpec ~= specID then
        categoryInfoCache = BuildCategoryInfoCache()
        categoryInfoCacheSpec = specID
    end
    return categoryInfoCache[categoryID]
end






function Data.DiscoverCategoryIDs()
    local ids = {}
    for categoryID in pairs(BuildCategoryInfoCache()) do
        table.insert(ids, categoryID)
    end
    table.sort(ids)
    return ids
end





local GENERIC_CATEGORY_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"









local function CategoryArtCache()
    ThugUI_Config.cvCategoryArt = ThugUI_Config.cvCategoryArt or {}
    return ThugUI_Config.cvCategoryArt
end








function Data.CategoryEntry(categoryID)
    if not categoryID then return nil end

    local cached = CategoryArtCache()[categoryID]
    if cached then
        return { categoryID = categoryID, name = cached.name, icon = cached.icon }
    end

    return {
        categoryID = categoryID,
        name = ("Consumable (category %d)"):format(categoryID),
        icon = GENERIC_CATEGORY_ICON,
    }
end















































local function CategoriesNeedingArt()
    local seen, ids = {}, {}

    local function add(categoryID)
        if categoryID and not seen[categoryID] then
            seen[categoryID] = true
            table.insert(ids, categoryID)
        end
    end

    for _, categoryID in ipairs(Data.DiscoverCategoryIDs()) do add(categoryID) end

    local profile = CV.CurrentProfile and CV:CurrentProfile()
    if profile and profile.placements then
        for _, placement in ipairs(Data.GetPlacements(profile)) do
            add(placement.categoryID)
        end
    end

    return ids
end

function Data.ResolveCategoryArt()
    local cache = CategoryArtCache()

    for _, categoryID in ipairs(CategoriesNeedingArt()) do
        if not cache[categoryID] then
            local resolved

            local info = Data.GetCategoryInfo(categoryID)
            local cooldownID = info and info.cooldownID
            if cooldownID and CV.BlizzBuffs and CV.BlizzBuffs.ItemForCooldownID then
                local item = CV.BlizzBuffs:ItemForCooldownID(cooldownID)
                if item then
                    local texture
                    if item.GetSpellCategoryIcon then
                        local ok, tex = pcall(item.GetSpellCategoryIcon, item)
                        if ok and tex then texture = tex end
                    end
                    if not texture then
                        local ok, tex = pcall(item.GetSpellTexture, item)
                        if ok and tex then texture = tex end
                    end
                    local nameOK, name = pcall(item.GetNameText, item)
                    if texture and nameOK and name and name ~= "" then
                        resolved = { name = name, icon = texture }
                    end
                end
            end

            if not resolved and C_Spell and C_Spell.GetLastCategoryCooldownSource then
                local ok, spellID, itemID = pcall(C_Spell.GetLastCategoryCooldownSource, categoryID)
                
                
                
                local secret = issecretvalue and (issecretvalue(spellID) or issecretvalue(itemID))
                if ok and not secret and spellID and itemID then
                    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
                    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)
                    if name and icon then
                        resolved = { name = name, icon = icon }
                    end
                end
            end

            if resolved then
                cache[categoryID] = resolved
            end
        end
    end
end


function Data.DumpCooldownViewer()
    local dump = {}
    if not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCategorySet then
        return dump
    end

    for _, item in ipairs(CooldownViewerCategories()) do
        local categoryName = item.name
        local category = item.value
        if category ~= nil then
            local ok, ids = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, category)
            if ok and type(ids) == "table" then
                for _, cooldownID in ipairs(ids) do
                    local infoOK, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
                    if infoOK and info then
                        local names = {}
                        for _, id in ipairs(info.linkedSpellIDs or {}) do
                            local spellInfo = C_Spell.GetSpellInfo(id)
                            table.insert(names, id .. "=" .. ((spellInfo and spellInfo.name) or "?"))
                        end
                        local baseInfo = info.spellID and C_Spell.GetSpellInfo(info.spellID)
                        table.insert(dump, {
                            category = categoryName,
                            cooldownID = cooldownID,
                            spellID = info.spellID,
                            name = baseInfo and baseInfo.name,
                            overrideSpellID = info.overrideSpellID,
                            overrideTooltipSpellID = info.overrideTooltipSpellID,
                            hasAura = info.hasAura,
                            selfAura = info.selfAura,
                            charges = info.charges,
                            isKnown = info.isKnown,
                            linkedSpellIDs = table.concat(names, ", "),
                            
                            
                            
                            
                            
                            
                            
                            
                            equipSlot = info.equipSlot,
                            spellCategoryID = info.spellCategoryID,
                            buffSlot = info.buffSlot,
                            isInvisible = info.isInvisible,
                        })
                    end
                end
            end
        end
    end
    return dump
end


local function SpellbookSpellIDs()
    local spellIDs = {}
    if not C_SpellBook or not C_SpellBook.GetNumSpellBookSkillLines then return spellIDs end

    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    local numLines = C_SpellBook.GetNumSpellBookSkillLines() or 0

    for line = 1, numLines do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if lineInfo and lineInfo.itemIndexOffset and lineInfo.numSpellBookItems then
            for i = 1, lineInfo.numSpellBookItems do
                local slot = lineInfo.itemIndexOffset + i
                local ok, itemInfo = pcall(C_SpellBook.GetSpellBookItemInfo, slot, bank)
                if ok and itemInfo
                    and not itemInfo.isPassive
                    and not itemInfo.isOffSpec
                    and itemInfo.spellID
                then
                    table.insert(spellIDs, itemInfo.spellID)
                end
            end
        end
    end
    return spellIDs
end

local function SpellEntry(spellID)
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    local name = info and info.name
    local icon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID))
        or (info and info.iconID)
    if not name or not icon then return nil end
    return { spellID = spellID, name = name, icon = icon }
end


local function IsBuffCategory(categoryName)
    for _, name in ipairs(CATEGORIES_BY_SOURCE.buffs or {}) do
        if name == categoryName then return true end
    end
    return false
end









function Data.BuffsAvailable()
    return ThugUI_Config.cvUseBlizzardBuffs ~= false
end


local function IsKnownCategory(categoryName)
    for _, categoryNames in pairs(CATEGORIES_BY_SOURCE) do
        for _, name in ipairs(categoryNames) do
            if name == categoryName then return true end
        end
    end
    return false
end




function Data.BuildSpellList(source, search)
    local ids = {}
    
    
    
    
    local categoryIDs = {}

    local function collect(list)
        for _, id in ipairs(list) do table.insert(ids, id) end
    end
    local function collectCategories(list)
        for _, id in ipairs(list) do table.insert(categoryIDs, id) end
    end

    
    
    
    local buffsAvailable = Data.BuffsAvailable()

    if source == "spellbook" then
        collect(SpellbookSpellIDs())
    elseif source == "all" then
        for _, item in ipairs(CooldownViewerCategories()) do
            local categoryName = item.name
            if not IsKnownCategory(categoryName) then
                if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
                    ThugUI.Diagnostics:LogOnce("cv-unrecognized-cat-" .. categoryName, "CV",
                        "Unrecognized CooldownViewerCategory '%s' in Enum", categoryName)
                end
            end
            local isBuff = IsBuffCategory(categoryName)
            if buffsAvailable or not isBuff then
                collect(CooldownViewerSpellIDs(categoryName))
                collectCategories(CooldownViewerCategoryIDs(categoryName))
            end
        end
        collect(SpellbookSpellIDs())
    else
        local withheld = false
        for _, categoryName in ipairs(CATEGORIES_BY_SOURCE[source] or {}) do
            if not buffsAvailable and IsBuffCategory(categoryName) then
                withheld = true
            else
                collect(CooldownViewerSpellIDs(categoryName))
                collectCategories(CooldownViewerCategoryIDs(categoryName))
            end
        end
        
        
        
        
        
        if #ids == 0 and #categoryIDs == 0 and not withheld then collect(SpellbookSpellIDs()) end
    end

    if search and search ~= "" then search = search:lower() else search = nil end

    local seen, entries = {}, {}
    for _, id in ipairs(ids) do
        if not seen[id] then
            seen[id] = true
            local entry = SpellEntry(id)
            if entry and (not search or entry.name:lower():find(search, 1, true)) then
                table.insert(entries, entry)
            end
        end
    end
    
    
    
    
    
    if #categoryIDs > 0 then Data.ResolveCategoryArt() end

    for _, categoryID in ipairs(categoryIDs) do
        local key = Data.PlacementKey({ categoryID = categoryID })
        if not seen[key] then
            seen[key] = true
            local entry = Data.CategoryEntry(categoryID)
            if entry and (not search or entry.name:lower():find(search, 1, true)) then
                table.insert(entries, entry)
            end
        end
    end

    table.sort(entries, function(a, b) return a.name < b.name end)
    return entries
end











local DRUID_SPEC_IDS = {
    balance     = 102,
    feral       = 103,
    guardian    = 104,
    restoration = 105,
}




local function CornerToIntersection(corner, count)
    if corner == "TOPRIGHT" then return count, 0 end
    if corner == "BOTTOMLEFT" then return 0, 1 end
    if corner == "BOTTOMRIGHT" then return count, 1 end
    return 0, 0  
end

local function MigrateBar(specID, spellIDs, legacy, force)
    if #spellIDs == 0 then return false end

    local profile = Data.GetProfile(specID)
    if next(profile.placements) and not force then
        return false  
    end
    wipe(profile.placements)

    for i, spellID in ipairs(spellIDs) do
        if i <= Data.GRID_COLS then
            Data.SetPlacement(profile, 1, i, spellID, legacy.modes and legacy.modes[i] or "cooldown")
        end
    end

    profile.enabled      = legacy.show and true or false
    profile.onlyInCombat = legacy.onlyInCombat and true or false
    profile.followCursor = legacy.follow and true or false
    profile.scale        = legacy.scale or 1.0
    profile.point        = legacy.point
    profile.anchorCol, profile.anchorRow =
        CornerToIntersection(legacy.corner, math.min(#spellIDs, Data.GRID_COLS))

    return true
end










local ECV_FALLBACK_IDS = {
    ["Wild Growth"]          = 48438,
    ["Swiftmend"]            = 18562,
    ["Nature's Swiftness"]   = 132158,
    ["Ironbark"]             = 102342,
    ["Convoke the Spirits"]  = 391528,
    ["Tranquility"]          = 740,
}

local function ResolveECVSpellIDs(ER)
    local ids = {}
    for _, name in ipairs(ER.ecvSpellNames or {}) do
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
        local id = (info and info.spellID) or ECV_FALLBACK_IDS[name]
        if id then table.insert(ids, id) end
    end
    return ids
end


local function LegacyBarFor(specID)
    local cfg = ThugUI_Config
    local ER = ThugUI.EssentialRings
    if not ER then return nil end

    
    local function IDsAndModes(defs)
        local ids, modes = {}, {}
        for _, def in ipairs(defs or {}) do
            if def.spellID then
                table.insert(ids, def.spellID)
                
                table.insert(modes, def.mode == "buff" and "aura" or "cooldown")
            end
        end
        return ids, modes
    end

    if specID == DRUID_SPEC_IDS.restoration then
        return ResolveECVSpellIDs(ER), {
            show = cfg.showECV, onlyInCombat = cfg.ecvShowOnlyInCombat,
            follow = cfg.anchorECVToCursor, scale = cfg.ecvScale,
            corner = cfg.ecvAnchorCorner, point = cfg.ecvPoint,
        }
    end

    if specID == DRUID_SPEC_IDS.balance then
        local ids, modes = IDsAndModes(ER.bcvSpellDefs)
        return ids, {
            show = cfg.showBCV, onlyInCombat = cfg.bcvShowOnlyInCombat,
            follow = cfg.anchorBCVToCursor, scale = cfg.bcvScale,
            corner = cfg.bcvAnchorCorner, point = cfg.bcvPoint, modes = modes,
        }
    end

    if specID == DRUID_SPEC_IDS.guardian then
        local ids, modes = IDsAndModes(ER.gcvSpellDefs)
        return ids, {
            show = cfg.showGCV, onlyInCombat = cfg.gcvShowOnlyInCombat,
            follow = cfg.anchorGCVToCursor, scale = cfg.gcvScale,
            corner = cfg.gcvAnchorCorner, point = cfg.gcvPoint, modes = modes,
        }
    end

    return nil
end




function Data.MigrateSpec(specID, force)
    if not specID or specID == 0 then return false end

    local store = Store()
    store.migratedSpecs = store.migratedSpecs or {}
    if store.migratedSpecs[specID] and not force then return false end

    local spellIDs, legacy = LegacyBarFor(specID)
    if not spellIDs then
        store.migratedSpecs[specID] = true  
        return false
    end

    local wrote = MigrateBar(specID, spellIDs, legacy, force)
    
    
    if wrote then store.migratedSpecs[specID] = true end

    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("MIGRATE", "%s: %d legacy spell(s) resolved, %s",
            Data.GetSpecName(specID), #spellIDs,
            wrote and "imported" or "nothing written")
    end
    return wrote
end


function Data.MigrateLegacyBars()
    local store = Store()
    store.migratedSpecs = store.migratedSpecs or {}

    
    
    
    for _, specID in pairs(DRUID_SPEC_IDS) do
        local profile = Store().profiles[specID]
        if profile and next(profile.placements) then
            store.migratedSpecs[specID] = true
        end
    end

    for _, specID in pairs(DRUID_SPEC_IDS) do
        Data.MigrateSpec(specID)
    end

    
    
    if Store().profiles[0] then Store().profiles[0] = nil end
end

Data.DRUID_SPEC_IDS = DRUID_SPEC_IDS

return Data
