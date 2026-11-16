







local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen or {}
ThugUI.Fullscreen = FS
FS.Classify = FS.Classify or {}
local C = FS.Classify









local CLASS_REAGENTS = {
    [2892] = "ROGUE", 
    [2893] = "ROGUE", 
    [3775] = "ROGUE", 
    [3776] = "ROGUE", 
    [5060] = "ROGUE", 
    [5140] = "ROGUE", 
    [5175] = "SHAMAN", 
    [5176] = "SHAMAN", 
    [5177] = "SHAMAN", 
    [5178] = "SHAMAN", 
    [5237] = "ROGUE", 
    [5530] = "ROGUE", 
    [5565] = "WARLOCK", 
    [6265] = "WARLOCK", 
    [6947] = "ROGUE", 
    [6949] = "ROGUE", 
    [6950] = "ROGUE", 
    [6951] = "ROGUE", 
    [8926] = "ROGUE", 
    [8927] = "ROGUE", 
    [8928] = "ROGUE", 
    [8984] = "ROGUE", 
    [8985] = "ROGUE", 
    [9186] = "ROGUE", 
    [10918] = "ROGUE", 
    [10920] = "ROGUE", 
    [10921] = "ROGUE", 
    [10922] = "ROGUE", 
    [16583] = "WARLOCK", 
    [17020] = "MAGE", 
    [17021] = "DRUID", 
    [17026] = "DRUID", 
    [17028] = "PRIEST", 
    [17029] = "PRIEST", 
    [17030] = "SHAMAN", 
    [17031] = "MAGE", 
    [17032] = "MAGE", 
    [17033] = "PALADIN", 
    [17034] = "DRUID", 
    [17035] = "DRUID", 
    [17036] = "DRUID", 
    [17037] = "DRUID", 
    [17038] = "DRUID", 
    [17056] = "MAGE,PRIEST", 
    [17057] = "SHAMAN", 
    [17058] = "SHAMAN", 
    [20844] = "ROGUE", 
    [21177] = "PALADIN", 
}


local function IsOwnClassReagent(itemID)
    if type(itemID) ~= "number" or (issecretvalue and issecretvalue(itemID)) then
        return false
    end
    local classes = CLASS_REAGENTS[itemID]
    if not classes or not UnitClass then
        return false
    end
    local _, mine = UnitClass("player")
    if type(mine) ~= "string" then
        return false
    end
    for class in classes:gmatch("[^,]+") do
        if class == mine then
            return true
        end
    end
    return false
end



function C.Place(info)
    if info.equippable and info.equipLoc and info.equipLoc ~= ""
        and info.equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE"
        and info.equipLoc ~= "INVTYPE_BAG"
        and info.equipLoc ~= "INVTYPE_QUIVER"
        and info.equipLoc ~= "INVTYPE_AMMO" then
        return "armor"
    end
    if info.equipLoc == "INVTYPE_AMMO" or info.classID == 6 then
        return "ammo"
    end
    if info.classID == 5 or (info.classID == 15 and info.subclassID == 1) or IsOwnClassReagent(info.itemID) then
        return "reagent"
    end
    if info.classID == 12 or info.bindType == 4 or info.isQuestItem or info.questID ~= nil then
        return "quest"
    end
    if info.hasSpell then
        return "usable"
    end
    return "inventory"
end

local function Call(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, a, b, c, d, e, f, g, h, i, j, k, l, m, n = pcall(fn, ...)
    if ok then
        return a, b, c, d, e, f, g, h, i, j, k, l, m, n
    end
end

function C.Read(bag, slot)
    local ci = Call(C_Container and C_Container.GetContainerItemInfo, bag, slot)
    if not ci or not ci.itemID then
        return nil
    end
    local _, _, _, equipLoc, _, classID, subclassID = Call(C_Item and C_Item.GetItemInfoInstant, ci.itemID)
    local name, _, _, _, _, _, _, _, _, _, _, _, _, bindType = Call(C_Item and C_Item.GetItemInfo, ci.itemID)
    local equippable = Call(C_Item and C_Item.IsEquippableItem, ci.itemID)
    local spell = Call(C_Item and C_Item.GetItemSpell, ci.itemID)
    local quest = Call(C_Container and C_Container.GetContainerItemQuestInfo, bag, slot)
    return {
        bag = bag, slot = slot, itemID = ci.itemID, stackCount = ci.stackCount or 1,
        isLocked = ci.isLocked, quality = ci.quality, iconFileID = ci.iconFileID,
        name = name, equipLoc = equipLoc, classID = classID, subclassID = subclassID,
        bindType = bindType, equippable = equippable and true or false,
        hasSpell = spell ~= nil, isQuestItem = quest and quest.isQuestItem,
        questID = quest and quest.questID,
    }
end
