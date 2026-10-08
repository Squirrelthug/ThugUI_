











local ThugUI = _G.ThugUI
local P = {}
ThugUI.Prep = P
ThugUI:RegisterModule("Prep", P)

ThugUI.defaults.Prep = {
    manual = { elixir = {}, scroll = {}, food = {} },
    hidden = {}
}

P.SECTIONS = { "elixir", "scroll", "food" }
P.TITLES = {
    elixir = "Elixirs & flasks",
    scroll = "Scrolls",
    food = "Campfire food",
}

P.cache = {}
P.dirty = true



local function ItemName(id, slotInfo)
    local n = slotInfo and slotInfo.itemName
    if not n and C_Item and C_Item.GetItemNameByID then n = C_Item.GetItemNameByID(id) end
    return n or ("Item " .. id)
end
P.ItemName = ItemName

local function InList(list, val)
    for _, v in ipairs(list or {}) do
        if v == val then return true end
    end
    return false
end


function P.Classify(info)
    local id, name, classID, subClassID, useText = info.id, info.name, info.classID, info.subClassID, info.useText

    
    local cfg = ThugUIDB and ThugUIDB.Prep or ThugUI.defaults.Prep
    if InList(cfg.hidden, id) then return nil end

    for _, s in ipairs(P.SECTIONS) do
        if InList(cfg.manual and cfg.manual[s], id) then
            return s
        end
    end

    local useLower = string.lower(useText or "")
    local hasDuration = false
    if string.match(useLower, "for %d+ min") or
       string.match(useLower, "for %d+ sec") or
       string.match(useLower, "for %d+ hour") or
       string.match(useLower, "lasts %d+") or
       string.match(useLower, "lasts for %d+") then
        hasDuration = true
    end

    local cConsumable = Enum and Enum.ItemClass and Enum.ItemClass.Consumable or 0
    local scGeneric = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Generic or 0
    local scPotion = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Potion or 1
    local scElixir = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Elixir or 2
    local scFlasksphials = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Flasksphials or 3
    local scScroll = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Scroll or 4
    local scFooddrink = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Fooddrink or 5
    local scItemenhancement = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Itemenhancement or 6
    local scOther = Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Other or 8

    
    
    
    local isWeapon = false
    if string.match(useLower, "weapon") and hasDuration then
        isWeapon = true
    elseif classID == cConsumable and subClassID == scItemenhancement then
        isWeapon = true
    end
    if isWeapon then return nil end

    
    if classID ~= cConsumable then return nil end

    
    if string.match(useLower, "well fed") then return "food" end

    
    if subClassID == scScroll or string.sub(name or "", 1, 10) == "Scroll of " then return "scroll" end

    
    if subClassID == scElixir or subClassID == scFlasksphials then return "elixir" end
    if (subClassID == scPotion or subClassID == scGeneric or subClassID == scOther) and hasDuration then return "elixir" end

    
    return nil
end

function P:Scan()
    local entries = {}
    local sums = {}
    local icons = {}
    local names = {}
    
    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local slots = C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemID, stackCount, iconFileID, info
            if C_Container and C_Container.GetContainerItemInfo then
                info = C_Container.GetContainerItemInfo(bag, slot)
                if info then
                    itemID = info.itemID
                    stackCount = info.stackCount
                    iconFileID = info.iconFileID
                end
            end
            if itemID then
                sums[itemID] = (sums[itemID] or 0) + (stackCount or 1)
                icons[itemID] = iconFileID
                if not names[itemID] then
                    local classID, subClassID
                    if C_Item and C_Item.GetItemInfoInstant then
                        local _, _, _, _, _, cid, sid = C_Item.GetItemInfoInstant(itemID)
                        classID = cid
                        subClassID = sid
                    end
                    names[itemID] = ItemName(itemID, info)
                    
                    if not P.cache[itemID] then
                        local useText = ""
                        if C_TooltipInfo and C_TooltipInfo.GetBagItem then
                            local tooltip = C_TooltipInfo.GetBagItem(bag, slot)
                            if tooltip and tooltip.lines then
                                for i = 1, #tooltip.lines do
                                    local txt = tooltip.lines[i].leftText
                                    if txt and string.match(txt, "^Use:") then
                                        useText = txt
                                        break
                                    end
                                end
                            end
                        end
                        P.cache[itemID] = { classID = classID, subClassID = subClassID, useText = useText }
                    end
                end
            end
        end
    end

    local cfg = ThugUIDB and ThugUIDB.Prep or ThugUI.defaults.Prep

    if cfg.manual then
        for _, s in ipairs(P.SECTIONS) do
            for _, id in ipairs(cfg.manual[s] or {}) do
                if not sums[id] then
                    sums[id] = 0
                    local iconFileID, classID, subClassID
                    if C_Item and C_Item.GetItemInfoInstant then
                        local _, _, _, _, icon, cid, sid = C_Item.GetItemInfoInstant(id)
                        iconFileID = icon
                        classID = cid
                        subClassID = sid
                    end
                    names[id] = ItemName(id)
                    icons[id] = iconFileID
                    
                    if not P.cache[id] then
                        P.cache[id] = { classID = classID, subClassID = subClassID, useText = "" }
                    end
                end
            end
        end
    end

    P.lastSeen = {}
    for id, count in pairs(sums) do
        local c = P.cache[id]
        if count > 0 then P.lastSeen[id] = { name = names[id], count = count } end
        local section = P.Classify({ id = id, name = names[id], classID = c.classID, subClassID = c.subClassID, useText = c.useText })
        if section then
            table.insert(entries, { kind = "prep", id = id, name = names[id], icon = icons[id], count = count, section = section })
        end
    end

    return entries
end

function P:Entries(section)
    if P.dirty then
        P.entries = P:Scan()
        P.dirty = false
    end
    local ret = {}
    for _, e in ipairs(P.entries or {}) do
        if e.section == section and e.count > 0 then
            table.insert(ret, e)
        end
    end
    table.sort(ret, function(a, b) return (a.name or "") < (b.name or "") end)
    return ret
end

local frame = CreateFrame("Frame")
ThugUI.SafeRegisterEvent(frame, "BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function(self, event)
    if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
    if event == "BAG_UPDATE_DELAYED" then
        P.dirty = true
    end
end)

SlashCmdList["THUGPREP"] = function(msg)
    if msg == "dump" then
        
        
        P:Scan()
        local counts = { elixir = 0, scroll = 0, food = 0 }
        local cConsumable = Enum and Enum.ItemClass and Enum.ItemClass.Consumable or 0
        for id, seen in pairs(P.lastSeen or {}) do
            local c = P.cache[id] or {}
            local section = P.Classify({ id = id, name = seen.name, classID = c.classID, subClassID = c.subClassID, useText = c.useText })
            if c.classID == cConsumable or section then
                if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
                    ThugUI.Diagnostics:Log("PREP", "item %d %s class=%s sub=%s bucket=%s use=%s", id, tostring(seen.name), tostring(c.classID), tostring(c.subClassID), tostring(section), tostring(c.useText))
                end
            end
            if section then counts[section] = counts[section] + 1 end
        end
        for _, s in ipairs(P.SECTIONS) do
            print("Prep " .. s .. ": " .. counts[s] .. " items.")
        end
    end
end
SLASH_THUGPREP1 = "/thugprep"















local MAIN, OFF = 16, 17
P.MAIN, P.OFF = MAIN, OFF


function P.HasTempEnchant(slot)
    if C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo then
        local ok, info = pcall(C_PaperDollInfo.GetTemporaryEnchantmentInfo, slot)
        if not ok then return nil end
        return info ~= nil
    end
    if GetWeaponEnchantInfo then
        local ok, hasMain, _, _, _, hasOff = pcall(GetWeaponEnchantInfo)
        if not ok then return nil end
        local v = (slot == MAIN) and hasMain or hasOff
        if issecretvalue and issecretvalue(v) then return nil end
        return v and true or false
    end
    return nil
end



function P.WeaponIn(slot)
    local id = GetInventoryItemID and GetInventoryItemID("player", slot)
    if not id then return nil end
    local classID
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, _, cid = C_Item.GetItemInfoInstant(id)
        classID = cid
    end
    local weapon = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
    if classID == weapon then return id end
    return nil
end



function P:PickHand()
    if P.WeaponIn(MAIN) and P.HasTempEnchant(MAIN) == false then return MAIN end
    if P.WeaponIn(OFF) and P.HasTempEnchant(OFF) == false then return OFF end
    return nil
end

local function RemoveFromTable(tbl, val)
    for i = #tbl, 1, -1 do
        if tbl[i] == val then
            table.remove(tbl, i)
        end
    end
end

function P:Resolve(text)
    if not text or text == "" then return nil, "Unknown item. Carry it, or type its item ID." end
    
    if string.match(text, "^%d+$") then
        local id = tonumber(text)
        if C_Item and C_Item.GetItemInfoInstant then
            local n = C_Item.GetItemInfoInstant(id)
            if n then return id end
        end
    end

    local lowerText = string.lower(text)
    local entries = P:Scan()
    for _, e in ipairs(entries) do
        if e.count > 0 and e.name and string.lower(e.name) == lowerText then
            return e.id
        end
    end

    if C_Item and C_Item.GetItemInfoInstant then
        local ok, n = pcall(C_Item.GetItemInfoInstant, text)
        if ok and n then
            return n 
        end
    end

    return nil, "Unknown item. Carry it, or type its item ID."
end

function P:Add(section, id)
    local cfg = ThugUIDB and ThugUIDB.Prep or ThugUI.defaults.Prep
    if not ThugUIDB.Prep then ThugUIDB.Prep = cfg end
    
    RemoveFromTable(cfg.hidden, id)
    for _, s in ipairs(P.SECTIONS) do
        RemoveFromTable(cfg.manual[s], id)
    end
    table.insert(cfg.manual[section], id)
    P.cache = {}
    P.dirty = true
end

function P:Remove(section, id)
    local cfg = ThugUIDB and ThugUIDB.Prep or ThugUI.defaults.Prep
    if cfg.manual and cfg.manual[section] then
        RemoveFromTable(cfg.manual[section], id)
    end
    P.cache = {}
    P.dirty = true
end

function P:Hide(id)
    local cfg = ThugUIDB and ThugUIDB.Prep or ThugUI.defaults.Prep
    if not ThugUIDB.Prep then ThugUIDB.Prep = cfg end
    
    if not InList(cfg.hidden, id) then
        table.insert(cfg.hidden, id)
    end
    P.cache = {}
    P.dirty = true
end

function P:Unhide(id)
    local cfg = ThugUIDB and ThugUIDB.Prep or ThugUI.defaults.Prep
    if cfg.hidden then
        RemoveFromTable(cfg.hidden, id)
    end
    P.cache = {}
    P.dirty = true
end
