

























local ThugUI = _G.ThugUI
local ControllerRadial = {}
ThugUI.ControllerRadial = ControllerRadial
ThugUI:RegisterModule("ControllerRadial", ControllerRadial)

ThugUI.defaults.ControllerRadial = {}


local PAD_CONFIRM = GAMEPAD_FACE_BOTTOM or "PAD1"
local PAD_BACK = GAMEPAD_FACE_RIGHT or "PAD2"
local PAD_SQUARE = GAMEPAD_FACE_LEFT or "PAD3"
local PAD_LEFT = GAMEPAD_DPAD_LEFT or "PADDLEFT"
local PAD_RIGHT = GAMEPAD_DPAD_RIGHT or "PADDRIGHT"
local PAD_PREV = GAMEPAD_SHOULDER_LEFT or "PADLSHOULDER"
local PAD_NEXT = GAMEPAD_SHOULDER_RIGHT or "PADRSHOULDER"



local SEGMENTS = 8

local atan2 = math.atan2 or math.atan
local SEGMENT_ANGLE = 360 / SEGMENTS
local HIGHLIGHT_ROTATION_CORRECTION = 270
local HIGHLIGHT_DISTANCE = 150
local ATLAS_ICON_DISTANCE = 50
local ICON_DISTANCE = 20
local DEADZONE_SQ = 0.04
local THRESHOLD_SQ = 0.25
local LABEL_ANCHOR = {
    { 60, 0 }, { 30, 45 }, { 0, 60 }, { -30, 45 },
    { -60, 0 }, { -30, -45 }, { 0, -60 }, { 30, -45 },
}

local ACORN = "Interface\\AddOns\\ThugUI\\media\\Acorn.tga"

local function Log(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("WHEEL", fmt, ...) end
end

local function Crumb(text)
    if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
        ThugUI.Diagnostics:Breadcrumb("wheel: " .. text)
    end
end

local function Refuse(msg)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(msg, 1, 0.1, 0.1, 1)
    end
end







local GLYPH_SIZE = 18
local GLYPH_FALLBACK = {
    [PAD_CONFIRM] = "the confirm button",
    [PAD_SQUARE] = "the left face button",
}
local function ButtonGlyph(key)
    local util = InputIconTextureSetUtility
    if util and util.GetNormalActiveInputIconButtonTexture and CreateAtlasMarkup then
        local ok, atlas = pcall(util.GetNormalActiveInputIconButtonTexture, key)
        if ok and type(atlas) == "string" and atlas ~= "" then
            return CreateAtlasMarkup(atlas, GLYPH_SIZE, GLYPH_SIZE)
        end
    end
    return GLYPH_FALLBACK[key] or key
end

local function TravelHint()
    return ("Select then press %s to cast\n%s sets ThugPort"):format(ButtonGlyph(PAD_CONFIRM), ButtonGlyph(PAD_SQUARE))
end


local function Safe(fn)
    return function()
        local ok, res = pcall(fn)
        return ok and res and true or false
    end
end

local function TargetName()
    return GetUnitName("target", true)
end

local function TargetIsOtherPlayer()
    return UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player")
end


local function TargetInGroup()
    return UnitInParty("target") or UnitInRaid("target")
end

local function IsLeader()
    return UnitIsGroupLeader("player")
end





local function MarkerFallback()
    Log("GROUP: Cross reached the wheel, not the cast button")
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage("Hold the stick on it and press the confirm button.", 1, 0.82, 0)
    end
end


local function PlainMark()
    local ok, v = pcall(GetRaidTargetIndex, "target")
    if not ok then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end







local SKULL = 8

local GROUP = {
    header = "Group",
    buttons = {
        [1] = {
            label = "Invite target",
            isEnabled = Safe(function() return TargetIsOtherPlayer() and not TargetInGroup() end),
            disabledMsg = "Target a player who is not in your group.",
            action = function()
                local name = TargetName()
                if C_PartyInfo and C_PartyInfo.InviteUnit then
                    C_PartyInfo.InviteUnit(name)
                else
                    InviteUnit(name)
                end
            end,
        },
        
        
        [3] = {
            label = "Mark target",
            isEnabled = Safe(function() return UnitExists("target") end),
            disabledMsg = "You have no target.",
            action = function() ControllerRadial:EnterSub("marks") end,
            stayOpen = true,
        },
        [4] = {
            label = "Clear mark",
            isEnabled = Safe(function() return UnitExists("target") end),
            disabledMsg = "You have no target.",
            action = function()
                local ok, err = pcall(SetRaidTarget, "target", 0)
                if not ok then Log("GROUP: SetRaidTarget refused: %s", tostring(err)) end
            end,
        },
        [5] = {
            label = "Leave group",
            isEnabled = Safe(function() return (IsInGroup and IsInGroup() or (UnitInParty("player") or UnitInRaid("player"))) end),
            disabledMsg = "You are not in a group.",
            action = function()
                if C_PartyInfo and C_PartyInfo.LeaveParty then
                    C_PartyInfo.LeaveParty()
                else
                    LeaveParty()
                end
            end,
        },
        [6] = {
            label = "Remove target",
            isEnabled = Safe(function()
                return (IsLeader() or UnitIsGroupAssistant("player")) and TargetIsOtherPlayer() and TargetInGroup()
            end),
            disabledMsg = "You must lead or assist and target a member.",
            action = function() UninviteUnit(TargetName()) end,
        },
        [7] = {
            label = "Raid",
            action = function() ControllerRadial:EnterSub("raid") end,
        },
        [8] = {
            label = "Markers",
            isEnabled = Safe(function() return not (InCombatLockdown and InCombatLockdown()) end),
            disabledMsg = "Out of combat only.",
            action = function() ControllerRadial:EnterSub("markers") end,
        },
    },
}


GROUP.buttons[1].icon = "Interface\\Icons\\Spell_Holy_PrayerofSpirit"
GROUP.buttons[3].icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
GROUP.buttons[4].icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
GROUP.buttons[5].icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield"
GROUP.buttons[6].icon = "Interface\\Icons\\Ability_Rogue_FeignDeath"
GROUP.buttons[7].icon = "Interface\\Icons\\INV_Misc_GroupLooking"
GROUP.buttons[8].icon = "GM-raidMarker1"
GROUP.buttons[8].iconAtlas = true


















local MAIN = INVSLOT_MAINHAND or 16
local OFF = INVSLOT_OFFHAND or 17

local WEAPON_CLASS = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
local FISHING_POLE = Enum and Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole or 20



local OFFHAND_WAIT, OFFHAND_TRIES = 0.1, 20

local function IsPole(item)
    if ThugUI.Fishing and ThugUI.Fishing.IsPole then
        return ThugUI.Fishing.IsPole(item)
    end
    return false
end

local function PoleEquipped()
    return IsPole(GetInventoryItemID("player", MAIN))
end

local function ItemGUID(location)
    if not (location and C_Item and C_Item.GetItemGUID) then return nil end
    local ok, guid = pcall(C_Item.GetItemGUID, location)
    return ok and guid or nil
end


local function FindInBags(test)
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
    for bag = 0, last do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and test(info, bag, slot) then return bag, slot, info end
        end
    end
end

local function FindPole()
    return FindInBags(function(info) return IsPole(info.itemID) end)
end


local function FindWeapon(rec)
    local bag, slot = FindInBags(function(_, b, s)
        return ItemGUID(ItemLocation:CreateFromBagAndSlot(b, s)) == rec.guid
    end)
    if bag or not rec.guid then
        return bag, slot
    end
    return FindInBags(function(info) return info.itemID == rec.id end)
end

local function Remembered()
    ThugUIDB.ControllerRadial = ThugUIDB.ControllerRadial or {}
    local db = ThugUIDB.ControllerRadial
    db.weapons = db.weapons or {}
    return db.weapons, UnitGUID("player") or "player"
end

local function HandRecord(slot)
    local id = GetInventoryItemID("player", slot)
    if not id then return false end
    return {
        id = id,
        guid = ItemGUID(ItemLocation:CreateFromEquipmentSlot(slot)),
        link = GetInventoryItemLink("player", slot),
    }
end

local function RememberedSet()
    local all, key = Remembered()
    local set = all[key]
    if set and (set.main or set.off) then return set end
end

local function EquipFromBag(bag, slot, invSlot)
    C_Container.PickupContainerItem(bag, slot)
    if not CursorHasItem() then
        Log("bag %s:%s would not lift (locked?)", tostring(bag), tostring(slot))
        return false
    end
    PickupInventoryItem(invSlot)
    if CursorHasItem() then
        
        ClearCursor()
        Log("slot %s refused bag %s:%s", tostring(invSlot), tostring(bag), tostring(slot))
        return false
    end
    return true
end

function ControllerRadial:EquipPole()
    if CursorHasItem() then return Refuse("Put down the item on your cursor first.") end
    local bag, slot = FindPole()
    if not bag then return Refuse("No fishing pole in your bags.") end
    local all, key = Remembered()
    all[key] = { main = HandRecord(MAIN), off = HandRecord(OFF) }
    Log("pole from %s:%s; remembered main %s, off %s", bag, slot,
        tostring(all[key].main and all[key].main.link), tostring(all[key].off and all[key].off.link))
    EquipFromBag(bag, slot, MAIN)
end

function ControllerRadial:EquipWeapons()
    if CursorHasItem() then return Refuse("Put down the item on your cursor first.") end
    local set = RememberedSet()
    if not set then return Refuse("No weapons remembered. Equip the pole from the wheel first.") end
    local mainBag, mainSlot
    if set.main then
        mainBag, mainSlot = FindWeapon(set.main)
        if not mainBag then return Refuse("Your main-hand weapon is not in your bags.") end
    end
    local function Off()
        if not set.off then return end
        local bag, slot = FindWeapon(set.off)
        if not bag then return Refuse("Your off-hand is not in your bags.") end
        EquipFromBag(bag, slot, OFF)
    end
    if not set.main then
        
        return Off()
    end
    if not EquipFromBag(mainBag, mainSlot, MAIN) or not set.off then return end
    local tries = 0
    local function WaitForMain()
        if GetInventoryItemID("player", MAIN) == set.main.id and not IsInventoryItemLocked(MAIN) then
            return Off()
        end
        tries = tries + 1
        if tries > OFFHAND_TRIES then
            Log("main hand never showed %s; off-hand left in the bags", tostring(set.main.link))
            return Refuse("Your off-hand could not be equipped.")
        end
        C_Timer.After(OFFHAND_WAIT, WaitForMain)
    end
    WaitForMain()
end

local function ItemIcon(item)
    if not item then return nil end
    local _, _, _, _, icon = C_Item.GetItemInfoInstant(item)
    return icon
end



local TRACKING_ATLAS = {
    [43308] = "professions_tracking_fish",
    [2580] = "professions_tracking_ore",
    [8388] = "professions_tracking_ore",
    [2383] = "professions_tracking_herb",
    [8387] = "professions_tracking_herb",
}




function ControllerRadial:TrackingEntries()
    local entries = {}
    if not (C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo) then
        return entries
    end
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        local ok, info = pcall(C_Minimap.GetTrackingInfo, i)
        if ok and info and info.type == "spell" then
            local index = i
            local atlas = info.spellID and TRACKING_ATLAS[info.spellID]
            table.insert(entries, {
                label = info.name,
                icon = atlas or info.texture,
                iconAtlas = atlas and true or false,
                stayOpen = true,
                isActive = function()
                    local okA, now = pcall(C_Minimap.GetTrackingInfo, index)
                    return okA and now and now.active and true or false
                end,
                action = function()
                    local okA, now = pcall(C_Minimap.GetTrackingInfo, index)
                    local on = not (okA and now and now.active)
                    
                    
                    
                    C_Minimap.SetTracking(index, on)
                    Log("tracking %q -> %s (spell %s)", tostring(info.name), tostring(on), tostring(info.spellID))
                end,
            })
        end
    end
    return entries
end







function ControllerRadial:UtilityPage()
    local page = { header = "Utility", buttons = {} }

    
    page.buttons[1] = {
        label = "Auras",
        icon = "gamepad-radial-icon-viewbuffs",
        iconAtlas = true,
        isEnabled = Safe(function() return ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("auras") end),
        disabledMsg = "Aura window is off (Mode & chat page).",
        action = function()
            if ThugUI.AuraWindow then
                ThugUI.AuraWindow:Open()
            end
        end,
    }

    
    if ThugUI:IsModuleOn("travel") then
        page.buttons[3] = {
            label = "Travel",
            icon = function()
                local entries = ThugUI.Travel:Entries()
                if entries[1] then
                    return entries[1].icon
                end
                return C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(6948)
            end,
            isEnabled = function() return #(ThugUI.Travel:Entries()) > 0 end,
            disabledMsg = "No travel options found.",
            action = function() ControllerRadial:EnterTravel() end,
            stayOpen = true,
        }
    end

    
    if ThugUI:IsModuleOn("fishing") and not (ThugUIDB.Fishing and ThugUIDB.Fishing.gearButton == false) then
        page.buttons[5] = {
            label = function() return PoleEquipped() and "Equip weapons" or "Equip fishing pole" end,
            icon = function()
                if PoleEquipped() then
                    local set = RememberedSet()
                    local hand = set and (set.main or set.off)
                    return hand and ItemIcon(hand.id)
                end
                local _, _, info = FindPole()
                return info and info.iconFileID
            end,
            isEnabled = Safe(function()
                if PoleEquipped() then return RememberedSet() ~= nil end
                return FindPole() ~= nil
            end),
            disabledMsg = function()
                return PoleEquipped() and "No weapons remembered. Equip the pole from the wheel first."
                    or "No fishing pole in your bags."
            end,
            action = function()
                if PoleEquipped() then ControllerRadial:EquipWeapons() else ControllerRadial:EquipPole() end
            end,
        }
    end

    
    
    
    
    
    
    
    
    
    
    
    page.buttons[6] = {
        label = "Trade",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        isEnabled = Safe(function()
            return TargetIsOtherPlayer() and UnitCanCooperate("player", "target")
                and not UnitIsDeadOrGhost("player") and not UnitIsDeadOrGhost("target")
                
                
                
                
                and (InCombatLockdown() or CheckInteractDistance("target", 2))
        end),
        disabledMsg = "Target a friendly player close enough to trade.",
        action = function() InitiateTrade("target") end,
    }
    page.buttons[8] = {
        label = "Inspect",
        icon = "Interface\\Icons\\INV_Misc_Spyglass_02",
        isEnabled = Safe(function()
            return TargetIsOtherPlayer() and not UnitCanAttack("player", "target")
                and not UnitIsDeadOrGhost("player")
                and (not CanInspect or CanInspect("target"))
        end),
        disabledMsg = "Target a friendly player close enough to inspect.",
        action = function()
            if not InspectUnit then return Refuse("The inspect window is not available.") end
            InspectUnit("target")
        end,
    }

    
    local tracking = self:TrackingEntries()
    local freeSlots = { 2, 4, 7 }
    if #tracking <= #freeSlots then
        for i, entry in ipairs(tracking) do
            page.buttons[freeSlots[i] ] = entry
        end
    else
        page.buttons[7] = {
            label = "Tracking",
            icon = "professions_tracking_herb",
            iconAtlas = true,
            stayOpen = true,
            action = function() ControllerRadial:EnterTracking() end,
        }
    end

    return page
end








local PREP_SLOTS = { elixir = 3, scroll = 1, food = 7 }
local PREP_ICONS = { elixir = 134821, scroll = 134937, food = 133971 }

function ControllerRadial:PrepPage()
    local page = { header = "Prep", buttons = {} }
    local P = ThugUI.Prep
    for _, s in ipairs(P.SECTIONS) do
        page.buttons[PREP_SLOTS[s] ] = {
            label = function() return P.TITLES[s] .. "\n" .. #P:Entries(s) end,
            icon = function()
                local first = P:Entries(s)[1]
                return first and first.icon or PREP_ICONS[s]
            end,
            isEnabled = function() return #P:Entries(s) > 0 end,
            disabledMsg = "No " .. P.TITLES[s]:lower() .. " in your bags.",
            stayOpen = true,
            action = function() ControllerRadial:EnterSub("prep_" .. s) end,
        }
    end
    return page
end


function ControllerRadial:BuildPages()
    local pages = { GROUP, self:UtilityPage() }
    if ThugUI:IsModuleOn("prep") and ThugUI.Prep then
        table.insert(pages, self:PrepPage())
    end
    self.pages = pages
    return pages
end







local function IsPrepSub(sub)
    return type(sub) == "string" and sub:sub(1, 5) == "prep_"
end

local function IsCastSub(sub)
    return sub == "travel" or sub == "markers" or IsPrepSub(sub)
end

local function ResetSubDial(self)
    if self.sub then
        if IsCastSub(self.sub) then
            ThugUI.Travel:BindCross(false)
            ThugUI.Travel:Arm(nil)
            
            
        end

        self.pages = self.savedPages or self.pages
        self.savedPages = nil
        self.sub = nil
        self.handPick = nil
        self.inTravelMode = false
        self.pageIndex = self.savedPageIndex or 1
        self.savedPageIndex = nil
    end
end

function ControllerRadial:EnterSub(kind)
    self.savedPages = self.pages
    self.savedPageIndex = self.pageIndex
    self.sub = kind
    self.inTravelMode = (kind == "travel")
    self.pageIndex = 1
    self.selected = nil
    self:RebuildSubPages()
    self:Draw()
    if IsCastSub(kind) and not (InCombatLockdown and InCombatLockdown()) then
        ThugUI.Travel:BindCross(true)
        
        if kind == "prep_weapon" then ThugUI.Travel:BindSquare(true) end
    end
end

function ControllerRadial:LeaveSub()
    ResetSubDial(self)
    self:Draw()
end

function ControllerRadial:RebuildSubPages()
    local pages = {}
    if self.sub == "marks" then
        local page = { header = "Marks", buttons = {} }
        for k = 1, 8 do
            page.buttons[k] = {
                label = _G["RAID_TARGET_" .. k] or ("Mark " .. k),
                icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. k,
                isEnabled = Safe(function() return UnitExists("target") end),
                isActive = function() return PlainMark() == k end,
                action = function()
                    local cur = PlainMark()
                    local ok, err = pcall(SetRaidTarget, "target", cur == k and 0 or k)
                    if not ok then Log("GROUP: SetRaidTarget refused: %s", tostring(err)) end
                end,
            }
        end
        table.insert(pages, page)
    elseif self.sub == "raid" then
        local page = { header = "Raid", buttons = {} }
        page.buttons[1] = {
            label = "Ready check",
            isEnabled = Safe(function() return (IsInGroup and IsInGroup() or (UnitInParty("player") or UnitInRaid("player"))) and (IsLeader() or UnitIsGroupAssistant("player")) end),
            action = function()
                local ok, err = pcall(DoReadyCheck)
                if not ok then Log("GROUP: DoReadyCheck refused: %s", tostring(err)) end
            end,
        }
        page.buttons[2] = {
            label = function() return (IsInRaid and IsInRaid() or UnitInRaid("player")) and "Convert to party" or "Convert to raid" end,
            isEnabled = Safe(function() return IsLeader() end),
            action = function()
                if (IsInRaid and IsInRaid() or UnitInRaid("player")) then
                    local ok, err = pcall(C_PartyInfo and C_PartyInfo.ConvertToParty or ConvertToParty)
                    if not ok then Log("GROUP: ConvertToParty refused: %s", tostring(err)) end
                else
                    local ok, err = pcall(C_PartyInfo and C_PartyInfo.ConvertToRaid or ConvertToRaid)
                    if not ok then Log("GROUP: ConvertToRaid refused: %s", tostring(err)) end
                end
            end,
        }
        page.buttons[3] = {
            label = function()
                local ok, isAssist = pcall(UnitIsGroupAssistant, "target")
                if not ok or (issecretvalue and issecretvalue(isAssist)) then
                    return "Toggle assist"
                end
                return isAssist and "Remove assist" or "Promote to assist"
            end,
            isEnabled = Safe(function() return (IsInRaid and IsInRaid() or UnitInRaid("player")) and IsLeader() and TargetInGroup() and TargetIsOtherPlayer() end),
            action = function()
                local ok, isAssist = pcall(UnitIsGroupAssistant, "target")
                if ok and not (issecretvalue and issecretvalue(isAssist)) and isAssist then
                    local okDemote, err = pcall(DemoteAssistant, "target")
                    if not okDemote then Log("GROUP: DemoteAssistant refused: %s", tostring(err)) end
                else
                    local okPromote, err = pcall(PromoteToAssistant, "target")
                    if not okPromote then Log("GROUP: PromoteToAssistant refused: %s", tostring(err)) end
                end
            end,
        }
        
        page.buttons[4] = {
            label = "Promote to leader",
            icon = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
            isEnabled = Safe(function() return IsLeader() and TargetIsOtherPlayer() and TargetInGroup() end),
            disabledMsg = "You must lead the group and target a member.",
            action = function() PromoteToLeader("target") end,
        }
        table.insert(pages, page)
    elseif self.sub == "markers" then
        local WORLD_MARKER_ATLAS = {
            [1] = "GM-raidMarker3",
            [2] = "GM-raidMarker5",
            [3] = "GM-raidMarker6",
            [4] = "GM-raidMarker2",
            [5] = "GM-raidMarker8",
            [6] = "GM-raidMarker7",
            [7] = "GM-raidMarker4",
            [8] = "GM-raidMarker1",
        }
        local page1 = { header = "World markers", buttons = {}, hint = TravelHint }
        for k = 1, 8 do
            local slash = _G["SLASH_WORLD_MARKER1"] or "/wm"
            page1.buttons[k] = {
                label = "Marker " .. k,
                icon = WORLD_MARKER_ATLAS[k],
                iconAtlas = true,
                action = MarkerFallback,
                travelEntry = { kind = "macro", text = slash .. " " .. k, name = "Marker " .. k },
            }
        end
        table.insert(pages, page1)
        
        local page2 = { header = "Roles", buttons = {}, hint = TravelHint }
        local clearSlash = _G["SLASH_CLEAR_WORLD_MARKER1"] or "/cwm"
        page2.buttons[1] = {
            label = "Clear world markers",
            icon = "Interface\\Icons\\Spell_ChargePositive",
            action = MarkerFallback,
            travelEntry = { kind = "macro", text = clearSlash .. " " .. (_G.ALL or "all"), name = "Clear markers" },
        }
        
        local function RoleEnabled()
            return (IsInRaid and IsInRaid() or UnitInRaid("player")) and TargetInGroup() and TargetIsOtherPlayer() and (IsLeader() or UnitIsGroupAssistant("player"))
        end
        
        page2.buttons[2] = {
            label = "Main tank",
            isEnabled = Safe(RoleEnabled),
            action = MarkerFallback,
            travelEntry = { kind = "macro", text = (_G["SLASH_MAINTANKON1"] or "/maintankon"), name = "Main tank" },
        }
        page2.buttons[3] = {
            label = "Main tank off",
            isEnabled = Safe(RoleEnabled),
            action = MarkerFallback,
            travelEntry = { kind = "macro", text = (_G["SLASH_MAINTANKOFF1"] or "/maintankoff"), name = "Main tank off" },
        }
        page2.buttons[4] = {
            label = "Main assist",
            isEnabled = Safe(RoleEnabled),
            action = MarkerFallback,
            travelEntry = { kind = "macro", text = (_G["SLASH_MAINASSISTON1"] or "/mainassiston"), name = "Main assist" },
        }
        page2.buttons[5] = {
            label = "Main assist off",
            isEnabled = Safe(RoleEnabled),
            action = MarkerFallback,
            travelEntry = { kind = "macro", text = (_G["SLASH_MAINASSISTOFF1"] or "/mainassistoff"), name = "Main assist off" },
        }
        
        table.insert(pages, page2)
    elseif self.sub == "travel" then
        local entries = ThugUI.Travel:Entries()
        for n = 1, math.max(1, math.ceil(#entries / SEGMENTS)) do
            local page = { header = n == 1 and "Travel" or ("Travel " .. n), buttons = {}, hint = TravelHint }
            for k = 1, SEGMENTS do
                local e = entries[(n - 1) * SEGMENTS + k]
                if e then
                    page.buttons[k] = {
                        label = function()
                            local cd = ThugUI.Travel:Cooldown(e)
                            local msg = ThugUI.Travel.FormatCooldown(cd)
                            if cd > 0 and msg ~= "" then
                                return e.name .. "\n" .. msg
                            else
                                return e.name
                            end
                        end,
                        
                        
                        
                        icon = e.icon,
                        disabledMsg = function()
                            local cd = ThugUI.Travel:Cooldown(e)
                            local msg = ThugUI.Travel.FormatCooldown(cd)
                            if cd > 0 and msg ~= "" then
                                return "On cooldown: " .. msg .. " left."
                            end
                            return nil
                        end,
                        isEnabled = function() return ThugUI.Travel:Cooldown(e) == 0 end,
                        action = function()
                            ThugUI.Travel:Choose(e)
                        end,
                        travelEntry = e,
                    }
                end
            end
            if #entries == 0 then
                page.empty = "No travel options found."
            end
            table.insert(pages, page)
        end
    elseif IsPrepSub(self.sub) then
        local section = self.sub:sub(6)
        local P = ThugUI.Prep
        local title = P.TITLES[section] or section
        local weapon = section == "weapon"
        local function Hint()
            if weapon then
                return ("%s free hand first   %s off hand"):format(ButtonGlyph(PAD_CONFIRM), ButtonGlyph(PAD_SQUARE))
            end
            return ("%s use"):format(ButtonGlyph(PAD_CONFIRM))
        end
        local entries = P:Entries(section)
        if weapon and self.handPick then
            
            
            local e = self.handPick
            local page = { header = e.name, buttons = {},
                hint = function() return ("%s replaces the lit hand's enchant   %s back"):format(ButtonGlyph(PAD_CONFIRM), ButtonGlyph(PAD_BACK)) end }
            local function Hand(slot, label)
                local entry = { kind = "prep", id = e.id, name = e.name, icon = e.icon, slot = slot }
                return {
                    label = function()
                        local id = P.WeaponIn(slot)
                        local name = id and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
                        return label .. (name and ("\n" .. name) or "")
                    end,
                    icon = function() return GetInventoryItemTexture and GetInventoryItemTexture("player", slot) or e.icon end,
                    isEnabled = function() return P.WeaponIn(slot) ~= nil end,
                    disabledMsg = "No weapon in that hand.",
                    action = function() Refuse("Press Cross to use it.") end,
                    travelEntry = entry,
                }
            end
            page.buttons[5] = Hand(P.MAIN, "Main hand")
            page.buttons[1] = Hand(P.OFF, "Off hand")
            table.insert(pages, page)
            self.pages = pages
            self.pageIndex = 1
            return
        end
        for n = 1, math.max(1, math.ceil(#entries / SEGMENTS)) do
            local page = { header = n == 1 and title or (title .. " " .. n), buttons = {}, hint = Hint }
            for k = 1, SEGMENTS do
                local e = entries[(n - 1) * SEGMENTS + k]
                if e then
                    
                    
                    local main = { kind = "prep", id = e.id, name = e.name, icon = e.icon }
                    local alt, hand
                    if weapon then
                        
                        
                        
                        hand = P:PickHand()
                        main.slot = hand
                        alt = { kind = "prep", id = e.id, name = e.name, icon = e.icon, slot = P.OFF }
                    end
                    local cast = (not weapon or hand) and main or nil
                    page.buttons[k] = {
                        label = function()
                            local text = e.name .. " x" .. e.count
                            if weapon then
                                text = text .. "\n" .. (hand == P.MAIN and "-> main hand"
                                    or hand == P.OFF and "-> off hand" or "both hands enchanted")
                            end
                            local cd = ThugUI.Travel:Cooldown(main)
                            local msg = ThugUI.Travel.FormatCooldown(cd)
                            if cd > 0 and msg ~= "" then text = text .. "\n" .. msg end
                            return text
                        end,
                        icon = e.icon,
                        isEnabled = function() return ThugUI.Travel:Cooldown(main) == 0 end,
                        disabledMsg = "On cooldown.",
                        
                        
                        
                        action = cast and function() Refuse("Press Cross to use it.") end
                            or function()
                                ControllerRadial.handPick = e
                                ControllerRadial:RebuildSubPages()
                            end,
                        stayOpen = not cast,
                        travelEntry = cast,
                        altEntry = alt,
                    }
                end
            end
            if #entries == 0 then
                page.empty = "Nothing found. Add items on the Prep page."
            end
            table.insert(pages, page)
        end
    elseif self.sub == "tracking" then
        local entries = self:TrackingEntries()
        for n = 1, math.max(1, math.ceil(#entries / SEGMENTS)) do
            local page = { header = n == 1 and "Tracking" or ("Tracking " .. n), buttons = {} }
            for k = 1, SEGMENTS do
                page.buttons[k] = entries[(n - 1) * SEGMENTS + k]
            end
            if #entries == 0 then
                page.empty = "No tracking abilities known."
            end
            table.insert(pages, page)
        end
    end
    self.pages = pages
    self.pageIndex = math.min(self.pageIndex, #self.pages)
    self.pageIndex = math.max(self.pageIndex, 1)
end

function ControllerRadial:EnterTravel()
    self:EnterSub("travel")
end

function ControllerRadial:LeaveTravel()
    self:LeaveSub()
end

function ControllerRadial:RebuildTravelPages()
    if self.sub == "travel" then
        self:RebuildSubPages()
    end
end

function ControllerRadial:EnterTracking()
    self:EnterSub("tracking")
end




local function Value(v)
    if type(v) ~= "function" then return v end
    local ok, res = pcall(v)
    return ok and res or nil
end

local function IsEnabled(entry)
    return entry and entry.action and (not entry.isEnabled or entry.isEnabled()) and true or false
end



local frame, segments

local function SegmentAngle(i)
    return (i - 1) * SEGMENT_ANGLE
end

local function BuildFrame()
    frame = CreateFrame("Frame", "ThugUI_Wheel", UIParent)
    frame:SetSize(400, 590)
    frame:SetPoint("CENTER", 312, 0)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    frame.Background = frame:CreateTexture(nil, "OVERLAY", nil, -3)
    frame.Background:SetAtlas("gamepad-radial-menu-wheelbg", true)
    frame.Background:SetPoint("CENTER", 0, 10)

    frame.Highlight = frame:CreateTexture(nil, "OVERLAY", nil, -2)
    frame.Highlight:SetAtlas("gamepad-radial-menu-selected", true)
    frame.Highlight:Hide()

    frame.Header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.Header:SetPoint("BOTTOM", frame, "TOP", 0, 25)
    frame.Header:SetTextColor(1, 1, 1)

    frame.HeaderBar = frame:CreateTexture(nil, "OVERLAY", nil, -2)
    frame.HeaderBar:SetAtlas("gamepad-radial-menu-toptext", true)
    frame.HeaderBar:SetPoint("TOP", frame.Header, "BOTTOM", 0, 4)

    frame.Empty = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Empty:SetPoint("CENTER", frame.Background, "CENTER")

    frame.Hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Hint:SetPoint("TOP", frame.Background, "BOTTOM", 0, -10)

    
    frame.Hub = frame:CreateTexture(nil, "OVERLAY")
    frame.Hub:SetTexture(ACORN)
    frame.Hub:SetSize(40, 40)
    frame.Hub:SetPoint("CENTER", frame.Background, "CENTER")

    frame.dots = {}

    segments = {}
    for i = 1, SEGMENTS do
        local deg = SegmentAngle(i)
        local x = HIGHLIGHT_DISTANCE * math.cos(math.rad(deg))
        local y = HIGHLIGHT_DISTANCE * math.sin(math.rad(deg))
        local s = CreateFrame("Frame", nil, frame)
        s:SetSize(60, 60)
        s:SetPoint("CENTER", frame.Background, "CENTER", x, y)
        s.x, s.y, s.rot = x, y, math.rad(deg - HIGHLIGHT_ROTATION_CORRECTION)

        s.Disabled = s:CreateTexture(nil, "OVERLAY", nil, -1)
        s.Disabled:SetAtlas("gamepad-radial-menu-disabled", true)
        s.Disabled:SetPoint("CENTER", frame.Background, "CENTER", x, y)
        s.Disabled:SetRotation(s.rot)

        s.Active = s:CreateTexture(nil, "OVERLAY", nil, -2)
        s.Active:SetAtlas("gamepad-radial-menu-selected", true)
        s.Active:SetPoint("CENTER", frame.Background, "CENTER", x, y)
        s.Active:SetRotation(s.rot)
        s.Active:SetVertexColor(0.3, 1, 0.3)
        s.Active:SetAlpha(0.45)

        s.Icon = s:CreateTexture(nil, "OVERLAY")
        s.Label = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        s.Label:SetSize(80, 40)
        s.Label:SetWordWrap(true)
        segments[i] = s
    end
end

local function DrawSegment(i, entry)
    local s = segments[i]
    if not entry then
        s:Hide()
        return
    end
    s:Show()
    local deg = SegmentAngle(i)
    local dist = entry.iconAtlas and ATLAS_ICON_DISTANCE or ICON_DISTANCE
    s.Icon:ClearAllPoints()
    s.Icon:SetPoint("CENTER", -dist * math.cos(math.rad(deg)), -dist * math.sin(math.rad(deg)))
    if entry.iconAtlas then
        s.Icon:SetAtlas(entry.icon)
        s.Icon:SetSize(57, 57)
    else
        s.Icon:SetTexture(Value(entry.icon) or ACORN)
        s.Icon:SetSize(38, 38)
    end
    local enabled = IsEnabled(entry)
    s.Icon:SetDesaturated(not enabled)
    s.Disabled:SetShown(not enabled)
    s.Active:SetShown(entry.isActive and entry.isActive() or false)
    local lx, ly = LABEL_ANCHOR[i][1], LABEL_ANCHOR[i][2]
    s.Label:ClearAllPoints()
    s.Label:SetPoint("CENTER", s.Icon, "CENTER", lx, ly)
    s.Label:SetText(Value(entry.label) or "")
    if enabled then
        s.Label:SetTextColor(1, 0.82, 0)
    else
        s.Label:SetTextColor(0.5, 0.5, 0.5)
    end
end

function ControllerRadial:Draw()
    local page = self.pages[self.pageIndex]
    frame.Header:SetText(page.header)
    frame.Empty:SetText(page.empty or "")
    frame.Hint:SetText(Value(page.hint) or "")
    frame.Hub:SetShown(not page.empty)
    for i = 1, SEGMENTS do DrawSegment(i, page.buttons[i]) end

    for i = 1, math.max(#self.pages, #frame.dots) do
        local dot = frame.dots[i]
        if not dot and i <= #self.pages then
            dot = frame:CreateTexture(nil, "OVERLAY")
            dot:SetSize(15, 15)
            frame.dots[i] = dot
        end
        if dot then
            dot:SetShown(i <= #self.pages)
            dot:ClearAllPoints()
            dot:SetPoint("TOP", frame.Header, "BOTTOM", (i - (#self.pages + 1) / 2) * 20, -24)
            dot:SetAtlas("gamepad-radialgamemenu-cursorbg-" .. (i == self.pageIndex and "neutral" or "inactive"))
        end
    end
    self:Highlight(self.selected)
end

function ControllerRadial:Highlight(i)
    self.selected = i
    local s = i and segments[i]
    if not s then
        frame.Highlight:Hide()
        if IsCastSub(self.sub) and ThugUI.Travel.armed ~= nil then
            ThugUI.Travel:Arm(nil)
        end
        return
    end
    frame.Highlight:ClearAllPoints()
    frame.Highlight:SetPoint("CENTER", frame.Background, "CENTER", s.x, s.y)
    frame.Highlight:SetRotation(s.rot)
    local entry = self.pages[self.pageIndex].buttons[i]
    local isEnabled = IsEnabled(entry)
    frame.Highlight:SetDesaturated(not isEnabled)
    frame.Highlight:Show()

    
    
    if IsCastSub(self.sub) then
        if isEnabled and entry and entry.travelEntry then
            if ThugUI.Travel.armed ~= entry.travelEntry then
                ThugUI.Travel:Arm(entry.travelEntry)
            end
        else
            if ThugUI.Travel.armed ~= nil then
                ThugUI.Travel:Arm(nil)
            end
        end
        
        if ThugUI.Travel.ArmAlt then
            local alt = isEnabled and entry and entry.altEntry or nil
            if ThugUI.Travel.armedAlt ~= alt then
                ThugUI.Travel:ArmAlt(alt)
            end
        end
    end
end



function ControllerRadial:Pick(i)
    local entry = i and self.pages[self.pageIndex].buttons[i]
    if not entry then return false end
    if not IsEnabled(entry) then
        local msg = Value(entry.disabledMsg) or "Not available right now."
        Log("refused %q: %s", tostring(Value(entry.label)), msg)
        Refuse(msg)
        return false
    end
    local label = Value(entry.label)
    Crumb(tostring(label))
    Log("picked %q on %s (combat=%s)", tostring(label),
        tostring(self.pages[self.pageIndex].header), tostring(InCombatLockdown()))
    local ok, err = pcall(entry.action)
    if not ok then Log("%q failed: %s", tostring(label), tostring(err)) end
    if entry.stayOpen then
        self:Draw()
    else
        self:Close()
    end
    return true
end

function ControllerRadial:Turn(page)
    local n = #self.pages
    self.pageIndex = ((self.pageIndex - 1 + page) % n) + 1
    self.selected = nil
    self:Draw()
end


function ControllerRadial:Step(delta)
    local buttons = self.pages[self.pageIndex].buttons
    local at = self.selected or (delta > 0 and 0 or 1)
    for _ = 1, SEGMENTS do
        at = ((at - 1 + delta) % SEGMENTS) + 1
        if buttons[at] then
            self:Highlight(at)
            return
        end
    end
end




function ControllerRadial:Stick(x, y)
    local d = x * x + y * y
    if d < DEADZONE_SQ then
        if self.stickSelected and self.selected then
            self.stickSelected = false
            
            
            if not IsCastSub(self.sub) then
                self:Pick(self.selected)
                
                
                
                if frame and frame:IsShown() then self:Highlight(nil) end
            end
        end
        return
    end
    if d > THRESHOLD_SQ then
        local degrees = math.deg(atan2(y, x))
        if degrees < -SEGMENT_ANGLE / 2 then degrees = 360 + degrees end
        local i = math.floor(((degrees + SEGMENT_ANGLE) / SEGMENT_ANGLE) + 0.5)
        if i > SEGMENTS then i = 1 end
        
        
        
        
        
        self.stickSelected = true
        if i ~= self.selected then self:Highlight(i) end
    end
end

















local held = {}


function ControllerRadial:GetTrigger()
    local key = GetBindingKey and GetBindingKey("THUGUI_WHEEL")
    if type(key) ~= "string" or key == "" then return nil end
    local parts = { strsplit("-", key) }
    local button = table.remove(parts)
    return button, parts
end

function ControllerRadial:IsTrigger(button)
    local want, mods = self:GetTrigger()
    if not want or button ~= want then return false end
    for _, m in ipairs(mods) do
        local test = (m == "SHIFT" and IsShiftKeyDown) or (m == "CTRL" and IsControlKeyDown)
            or (m == "ALT" and IsAltKeyDown)
        if test then
            if not test() then return false end
        elseif not held[m] then
            return false
        end
    end
    return true
end








local DOUBLE_TAP = 0.4
local lastStart = nil


function ControllerRadial:IsStart(button)
    local key = GetBindingKey and GetBindingKey("OPENRADIAL")
    if type(key) ~= "string" or key == "" then key = "PADFORWARD" end
    return button == key
end

function ControllerRadial:OnStart()
    local now = GetTime()
    local radial = _G.GamepadRadial
    local open = radial and radial:IsShown()
    if open and lastStart and now - lastStart <= DOUBLE_TAP then
        lastStart = nil
        Crumb("start double-tap")
        C_Timer.After(0, function() ControllerRadial:Open() end)
    else
        lastStart = now
    end
end

local listener




function ControllerRadial:StartListener()
    if listener and listener.listening then return true end
    if InCombatLockdown() then return false end
    if not listener then
        listener = CreateFrame("Frame", "ThugUI_WheelListener", UIParent)
        listener:SetSize(1, 1)
        listener:SetPoint("TOPLEFT")
        listener:SetScript("OnGamePadButtonDown", function(_, button)
            held[button] = true
            if button == PAD_CONFIRM and IsCastSub(ControllerRadial.sub) then
                Log("TRAVEL: listener saw Cross")
            end
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:LogOnce("wheel-pad-" .. tostring(button), "WHEEL", "pad button seen: %s", tostring(button))
            end
            if ControllerRadial:IsTrigger(button) then
                Crumb("pad trigger " .. tostring(button))
                ControllerRadial:Open()
            elseif ControllerRadial:IsStart(button) then
                ControllerRadial:OnStart()
            end
        end)
        listener:SetScript("OnGamePadButtonUp", function(_, button) held[button] = nil end)
    end
    listener:Show()
    local ok, err = pcall(listener.SetPropagateKeyboardInput, listener, true)
    if not ok then
        Log("listener: SetPropagateKeyboardInput refused: %s", tostring(err))
        return false
    end
    if not listener.EnableGamePadButton then
        Log("listener: no EnableGamePadButton on this client")
        return false
    end
    ok, err = pcall(listener.EnableGamePadButton, listener, true)
    if not ok then
        Log("listener: EnableGamePadButton refused: %s", tostring(err))
        return false
    end
    listener.listening = true
    local button, mods = self:GetTrigger()
    Log("listener on; trigger %s", button and (table.concat(mods, "-") .. (#mods > 0 and "-" or "") .. button) or "unbound")
    return true
end

function ControllerRadial:GetListener() return listener end

local function OnButton(_, button)
    local self = ControllerRadial
    held[button] = true
    if self:IsTrigger(button) then
        self:Close()
    elseif button == PAD_BACK then
        if self.handPick then
            
            self.handPick = nil
            self:RebuildSubPages()
            self:Draw()
        elseif self.sub then
            self:LeaveSub()
        else
            self:Close()
        end
    elseif button == PAD_CONFIRM then
        if IsCastSub(self.sub) then
            
            
            
            local entry = self.selected and self.pages[self.pageIndex].buttons[self.selected]
            Log("TRAVEL: Cross on wheel: slot=%s entry=%s enabled=%s armed=%s match=%s bound=%s combat=%s",
                tostring(self.selected), entry and entry.travelEntry and tostring(entry.travelEntry.name) or "nil",
                tostring(IsEnabled(entry)), ThugUI.Travel.armed and tostring(ThugUI.Travel.armed.name) or "nil",
                tostring(entry ~= nil and ThugUI.Travel.armed == entry.travelEntry),
                tostring(ThugUI.Travel.crossBound), tostring(InCombatLockdown and InCombatLockdown() or false))
        end
        if IsCastSub(self.sub) and not (InCombatLockdown and InCombatLockdown()) and ThugUI.Travel.crossBound then
            local entry = self.selected and self.pages[self.pageIndex].buttons[self.selected]
            
            
            
            if entry and entry.travelEntry and IsEnabled(entry) and ThugUI.Travel.armed == entry.travelEntry then
                
                
                
                
                pcall(frame.SetPropagateKeyboardInput, frame, true)
                self.casting = true
                ThugUI.Travel.castSeen = false
                C_Timer.After(1, function()
                    if self.casting and not ThugUI.Travel.castSeen then
                        self:CastFailed()
                    end
                end)
                return
            end
        end
        self:Pick(self.selected)
    elseif button == PAD_SQUARE and self.sub == "prep_weapon" then
        
        
        if ThugUI.Travel.squareBound and not (InCombatLockdown and InCombatLockdown()) then
            local entry = self.selected and self.pages[self.pageIndex].buttons[self.selected]
            if entry and IsEnabled(entry) and entry.altEntry and ThugUI.Travel.armedAlt == entry.altEntry then
                pcall(frame.SetPropagateKeyboardInput, frame, true)
                self.casting = true
                ThugUI.Travel.castSeen = false
                C_Timer.After(1, function()
                    if self.casting and not ThugUI.Travel.castSeen then
                        self:CastFailed()
                    end
                end)
                return
            end
        end
    elseif button == PAD_SQUARE then
        
        
        
        if self.sub == "travel" then
            local entry = self.selected and self.pages[self.pageIndex].buttons[self.selected]
            if entry and IsEnabled(entry) then
                ThugUI.Travel:Choose(entry.travelEntry)
                self:Close()
            end
        end
    elseif button == PAD_PREV then
        self:Turn(-1)
    elseif button == PAD_NEXT then
        self:Turn(1)
    elseif button == PAD_LEFT then
        self:Step(1)
    elseif button == PAD_RIGHT then
        self:Step(-1)
    end
end







local POINTING_STICK = "Camera"
local seenSticks = {}

local function OnStick(_, stick, x, y)
    if not seenSticks[stick] then
        seenSticks[stick] = true
        Log("stick seen: %s%s", tostring(stick), stick == POINTING_STICK and " (points)" or " (ignored)")
    end
    if stick ~= POINTING_STICK then return end
    ControllerRadial:Stick(x or 0, y or 0)
end

local function SetInput(on)
    if frame.EnableGamePadButton then
        local ok, err = pcall(frame.EnableGamePadButton, frame, on)
        if not ok then Log("EnableGamePadButton(%s) refused: %s", tostring(on), tostring(err)) end
    end
    if frame.EnableGamePadStick then
        local ok, err = pcall(frame.EnableGamePadStick, frame, on)
        if not ok then Log("EnableGamePadStick(%s) refused: %s", tostring(on), tostring(err)) end
    end
end

function ControllerRadial:Open()
    if not frame then
        BuildFrame()
        
        
        if ThugUI.CombatClose then
            ThugUI.CombatClose:Register("wheel", function() return frame and frame:IsShown() end,
                function() ControllerRadial:Close() end, { reopenInCombat = true })
        end
        frame:SetScript("OnGamePadButtonDown", OnButton)
        frame:SetScript("OnGamePadStick", OnStick)
        
        frame:SetScript("OnGamePadButtonUp", function(_, button) held[button] = nil end)
        frame:SetScript("OnHide", function() SetInput(false) end)
        frame.timeSinceDraw = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
            if ControllerRadial.inTravelMode then
                self.timeSinceDraw = self.timeSinceDraw + elapsed
                if self.timeSinceDraw >= 1.0 then
                    self.timeSinceDraw = 0
                    ControllerRadial:RebuildTravelPages()
                    ControllerRadial:Draw()
                end
            end
        end)
    end
    if not InCombatLockdown() and not self.propagationSet then
        self.propagationSet = pcall(frame.SetPropagateKeyboardInput, frame, false)
    end
    ResetSubDial(self)
    self:BuildPages()
    self.pageIndex = self.pageIndex and math.min(self.pageIndex, #self.pages) or 1
    self.selected, self.stickSelected = nil, false
    self:Draw()
    frame:Show()
    SetInput(true)
    Crumb("open")
    Log("opened on %s, %d page(s), combat=%s", tostring(self.pages[self.pageIndex].header),
        #self.pages, tostring(InCombatLockdown()))
end

function ControllerRadial:Close()
    if frame and frame:IsShown() then
        frame:Hide()
        ResetSubDial(self)
        Crumb("close")
    end
end

function ControllerRadial:Toggle()
    if not ThugUI:IsModuleOn("controller") then
        print("ThugUI: Controller is turned off on the Modules page.")
        return
    end
    if frame and frame:IsShown() then self:Close() else self:Open() end
end

function ControllerRadial:GetFrame() return frame end

function ControllerRadial:FinishCast()
    if self.casting then
        self.casting = false
        if not (InCombatLockdown and InCombatLockdown()) then
            pcall(frame.SetPropagateKeyboardInput, frame, false)
        end
        self:Close()
    end
end

function ControllerRadial:CastFailed()
    self.casting = false
    if frame then pcall(frame.SetPropagateKeyboardInput, frame, false) end
    Log("TRAVEL: Cross did not reach ThugUI_TravelCast (override lost or no propagation)")
    Refuse("Direct cast didn't fire: " .. ButtonGlyph(PAD_SQUARE) .. " sets ThugPort.")
end




function ControllerRadial:OnCombatStart()
    self.casting = false
    if frame then pcall(frame.SetPropagateKeyboardInput, frame, false) end
end

function ControllerRadial:Initialize()
    _G.BINDING_HEADER_THUGUI = _G.BINDING_HEADER_THUGUI or "ThugUI"
    _G.BINDING_NAME_THUGUI_WHEEL = "Controller wheel"

    
    local f = CreateFrame("Frame")
    ThugUI.SafeRegisterEvent(f, "MINIMAP_UPDATE_TRACKING")
    
    
    ThugUI.SafeRegisterEvent(f, "SPELL_UPDATE_COOLDOWN")
    ThugUI.SafeRegisterEvent(f, "BAG_UPDATE_COOLDOWN")
    ThugUI.SafeRegisterEvent(f, "PLAYER_EQUIPMENT_CHANGED")
    ThugUI.SafeRegisterEvent(f, "BAG_UPDATE_DELAYED")
    
    
    ThugUI.SafeRegisterEvent(f, "PLAYER_LOGIN")
    ThugUI.SafeRegisterEvent(f, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(f, "UPDATE_BINDINGS")
    f:SetScript("OnEvent", function(self, event)
        if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
        if event == "MINIMAP_UPDATE_TRACKING" or event == "PLAYER_EQUIPMENT_CHANGED"
            or event == "BAG_UPDATE_DELAYED" then
            if frame and frame:IsShown() then ControllerRadial:Draw() end
        elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
            if frame and frame:IsShown() and ControllerRadial.inTravelMode then ControllerRadial:RebuildTravelPages(); ControllerRadial:Draw() end
        elseif event == "UPDATE_BINDINGS" then
            local button, mods = ControllerRadial:GetTrigger()
            Log("wheel binding now %s", button and (table.concat(mods, "-") .. (#mods > 0 and "-" or "") .. button) or "unbound")
        else
            ControllerRadial:StartListener()
        end
    end)

    _G.SLASH_THUGWHEEL1 = "/thugwheel"
    SlashCmdList["THUGWHEEL"] = function() ControllerRadial:Toggle() end
end
