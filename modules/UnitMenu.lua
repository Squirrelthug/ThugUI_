































local ThugUI = _G.ThugUI
local UM = {}
ThugUI.UnitMenu = UM

local function LogOnce(key, fmt, ...)
    if ThugUI.Diagnostics and ThugUI.Diagnostics.LogOnce then
        ThugUI.Diagnostics:LogOnce("unitmenu-" .. key, "UNITMENU", fmt, ...)
    end
end


local function Ask(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, ...)
    if not ok then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

local function Yes(fn, ...) return Ask(fn, ...) and true or false end


local function Try(key, fn, ...)
    if type(fn) ~= "function" then
        LogOnce("missing-" .. key, "%s: the API is missing on this client", key)
        return false
    end
    local ok, err = pcall(fn, ...)
    if not ok then LogOnce("fail-" .. key, "%s failed: %s", key, tostring(err)) end
    return ok
end

local function Text(global, fallback)
    local v = _G[global]
    if type(v) == "string" and v ~= "" then return v end
    return fallback
end



function UM:Name(unit)
    return Ask(GetUnitName, unit, true)
end

local function IsSelf(unit) return Yes(UnitIsUnit, unit, "player") end
local function IsHuman(unit)
    if UnitIsHumanPlayer then return Yes(UnitIsHumanPlayer, unit) end
    return Yes(UnitIsPlayer, unit)
end
local function CanCoop(unit) return Yes(UnitCanCooperate, "player", unit) end
local function CanAttack(unit) return Yes(UnitCanAttack, "player", unit) end
local function Leader() return Yes(UnitIsGroupLeader, "player") end
local function Assist() return Yes(UnitIsGroupAssistant, "player") end
local function InGroup(cat) return Yes(IsInGroup, cat) end
local function InRaid() return Yes(IsInRaid) end
local function InPvP()
    if type(IsInInstance) ~= "function" then return false end
    local ok, _, t = pcall(IsInInstance)
    return ok and (t == "pvp" or t == "arena")
end
local function NoControlOrDead(unit)
    if HasFullControl and not Yes(HasFullControl) then return false end
    if Yes(UnitIsDeadOrGhost, "player") then return false end
    return not Yes(UnitIsDeadOrGhost, unit)
end

local function Combat() return InCombatLockdown and InCombatLockdown() or false end





function UM:Which(unit)
    if not unit or not Yes(UnitExists, unit) then return nil end
    if IsSelf(unit) then return "SELF" end
    if Yes(UnitIsUnit, unit, "vehicle") then return "VEHICLE" end
    if Yes(UnitIsUnit, unit, "pet") then return "PET" end
    if Yes(UnitIsOtherPlayersPet, unit) then return "OTHERPET" end
    if Yes(UnitIsPlayer, unit) then
        if Yes(UnitInRaid, unit) then return "RAID_PLAYER" end
        if Yes(UnitInParty, unit) then return "PARTY" end
        if not Yes(UnitIsMercenary, "player") then
            return CanCoop(unit) and "PLAYER" or "ENEMY_PLAYER"
        end
        return CanAttack(unit) and "ENEMY_PLAYER" or "PLAYER"
    end
    return "TARGET"
end










local ACTIONS = {}

local function Row(key, text, t)
    t = t or {}
    t.key, t.text = key, text
    if t.enabled == nil then t.enabled = true end
    return t
end


local function WithName(unit, key, text, fn)
    local name = UM:Name(unit)
    if not name then
        return Row(key, text, { enabled = false, reason = "Not available right now." })
    end
    return Row(key, text, { run = function() Try(key, fn, name) end })
end

local MARK_TEX = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"

ACTIONS.UnitPopupRaidTargetButtonMixin = function(unit)
    local cur = Ask(GetRaidTargetIndex, unit) or 0
    local sub = {}
    
    for i = 8, 1, -1 do
        sub[#sub + 1] = Row("mark" .. i, Text("RAID_TARGET_" .. i, "Mark " .. i), {
            icon = MARK_TEX .. i, checked = cur == i,
            run = function() Try("SetRaidTarget", SetRaidTarget, unit, i) end,
        })
    end
    sub[#sub + 1] = Row("mark0", Text("RAID_TARGET_NONE", "None"), {
        checked = cur == 0,
        run = function() Try("SetRaidTarget", SetRaidTarget, unit, 0) end,
    })
    return Row("raidtarget", Text("RAID_TARGET_ICON", "Target marker icon"), { sub = sub })
end

ACTIONS.UnitPopupSetFocusButtonMixin = function(unit)
    return Row("focus", Text("SET_FOCUS", "Set focus"), { macro = "/focus " .. unit })
end

ACTIONS.UnitPopupClearFocusButtonMixin = function()
    return Row("clearfocus", Text("CLEAR_FOCUS", "Clear focus"), { macro = "/clearfocus" })
end

ACTIONS.UnitPopupAddFriendButtonMixin = function(unit)
    if IsSelf(unit) or not IsHuman(unit) or not CanCoop(unit) then return nil end
    if C_FriendList and C_FriendList.IsLegacyFriendSystemEnabled
        and not Yes(C_FriendList.IsLegacyFriendSystemEnabled) then return nil end
    return WithName(unit, "addfriend", Text("ADD_FRIEND", "Add friend"), function(name)
        C_FriendList.AddFriend(name)
    end)
end

ACTIONS.UnitPopupWhisperButtonMixin = function(unit)
    if IsSelf(unit) or not IsHuman(unit) then return nil end
    local row = WithName(unit, "whisper", Text("WHISPER", "Whisper"), function(name)
        if ChatFrameUtil and ChatFrameUtil.SendTell then
            ChatFrameUtil.SendTell(name)
        else
            ChatFrame_SendTell(name)
        end
    end)
    if row.enabled and not Yes(UnitIsConnected, unit) then
        row.enabled, row.reason = false, "Offline."
    end
    return row
end

ACTIONS.UnitPopupInspectButtonMixin = function(unit)
    if IsSelf(unit) or CanAttack(unit) or not IsHuman(unit) then return nil end
    local row = Row("inspect", Text("INSPECT", "Inspect"), {
        run = function() Try("InspectUnit", InspectUnit, unit) end,
    })
    if Yes(UnitIsDeadOrGhost, "player") or (CanInspect and not Yes(CanInspect, unit)) then
        row.enabled, row.reason = false, "Too far away to inspect."
    end
    return row
end

ACTIONS.UnitPopupTradeButtonMixin = function(unit)
    if IsSelf(unit) or not CanCoop(unit) or not IsHuman(unit) then return nil end
    local row = Row("trade", Text("TRADE", "Trade"), {
        run = function() Try("InitiateTrade", InitiateTrade, unit) end,
    })
    
    
    
    if not NoControlOrDead(unit) then
        row.enabled, row.reason = false, "Not while dead or out of control."
    elseif not Combat() and CheckInteractDistance and not Yes(CheckInteractDistance, unit, 2) then
        row.enabled, row.reason = false, "Too far away to trade."
    end
    return row
end

ACTIONS.UnitPopupFollowButtonMixin = function(unit)
    if IsSelf(unit) or not CanCoop(unit) or not IsHuman(unit) then return nil end
    local row = Row("follow", Text("FOLLOW", "Follow"), { macro = "/follow " .. unit })
    if Yes(UnitIsDead, "player") then row.enabled, row.reason = false, "You are dead." end
    return row
end

ACTIONS.UnitPopupDuelButtonMixin = function(unit)
    if IsSelf(unit) or CanAttack(unit) or not IsHuman(unit) then return nil end
    local row = Row("duel", Text("DUEL", "Duel"), {
        run = function() Try("StartDuel", StartDuel, unit, true) end,
    })
    if not NoControlOrDead(unit) then row.enabled, row.reason = false, "Not while dead or out of control." end
    return row
end

ACTIONS.UnitPopupInviteButtonMixin = function(unit)
    if IsSelf(unit) or not CanCoop(unit) or not IsHuman(unit) then return nil end
    if not Yes(UnitIsConnected, unit) then return nil end
    local row = WithName(unit, "invite", Text("PARTY_INVITE", "Invite"), function(name)
        if C_PartyInfo and C_PartyInfo.InviteUnit then C_PartyInfo.InviteUnit(name) else InviteUnit(name) end
    end)
    if Yes(UnitInParty, unit) or Yes(UnitInRaid, unit) then
        row.enabled, row.reason = false, "Already in your group."
    end
    return row
end

local function Promote(unit)
    if C_PartyInfo and C_PartyInfo.PromoteToLeader then
        Try("PromoteToLeader", C_PartyInfo.PromoteToLeader, unit, true)
    else
        Try("PromoteToLeader", PromoteToLeader, unit)
    end
end

ACTIONS.UnitPopupPromoteButtonMixin = function(unit)
    if IsSelf(unit) or not Leader() or not IsHuman(unit) then return nil end
    local row = Row("promote", Text("PARTY_PROMOTE", "Promote to leader"), { run = function() Promote(unit) end })
    if not Yes(UnitIsConnected, unit) then row.enabled, row.reason = false, "Offline." end
    return row
end

local function Uninvite(unit)
    local name = UM:Name(unit)
    if not name then return end
    if C_PartyInfo and C_PartyInfo.UninviteUnit then
        Try("UninviteUnit", C_PartyInfo.UninviteUnit, name)
    else
        Try("UninviteUnit", UninviteUnit, name)
    end
end

ACTIONS.UnitPopupUninviteButtonMixin = function(unit)
    if IsSelf(unit) or not IsHuman(unit) or not Leader() or InPvP() then return nil end
    return Row("uninvite", Text("PARTY_UNINVITE", "Remove from group"), { run = function() Uninvite(unit) end })
end

ACTIONS.UnitPopupSetRaidLeaderButtonMixin = function(unit)
    if IsSelf(unit) or not IsHuman(unit) or not Leader() or Yes(UnitIsGroupLeader, unit) then return nil end
    return Row("raidleader", Text("SET_RAID_LEADER", "Make leader"), { run = function() Promote(unit) end })
end

ACTIONS.UnitPopupSetRaidAssistButtonMixin = function(unit)
    if IsSelf(unit) or not IsHuman(unit) or not Leader() then return nil end
    if Yes(IsEveryoneAssistant) or Yes(UnitIsGroupAssistant, unit) then return nil end
    return Row("raidassist", Text("SET_RAID_ASSISTANT", "Make assistant"), {
        run = function()
            local fn = C_PartyInfo and C_PartyInfo.PromoteToAssistant or PromoteToAssistant
            Try("PromoteToAssistant", fn, unit, true)
        end,
    })
end




local function CanAssign(unit)
    return not IsSelf(unit) and IsHuman(unit) and (Leader() or Assist())
end

ACTIONS.UnitPopupSetRaidMainTankButtonMixin = function(unit)
    if not CanAssign(unit) or Yes(GetPartyAssignment, "MAINTANK", unit) then return nil end
    return Row("maintank", Text("SET_MAIN_TANK", "Set main tank"), { macro = "/maintank " .. unit })
end

ACTIONS.UnitPopupSetRaidMainAssistButtonMixin = function(unit)
    if not CanAssign(unit) or Yes(GetPartyAssignment, "MAINASSIST", unit) then return nil end
    return Row("mainassist", Text("SET_MAIN_ASSIST", "Set main assist"), { macro = "/mainassist " .. unit })
end

ACTIONS.UnitPopupSetRaidDemoteButtonMixin = function(unit)
    if IsSelf(unit) or not IsHuman(unit) or not (Leader() or Assist()) then return nil end
    local text = Text("DEMOTE", "Demote")
    if Yes(GetPartyAssignment, "MAINTANK", unit) then
        return Row("demote", text, { macro = "/maintankoff " .. unit })
    elseif Yes(GetPartyAssignment, "MAINASSIST", unit) then
        return Row("demote", text, { macro = "/mainassistoff " .. unit })
    end
    if not Leader() or Yes(UnitIsGroupLeader, unit) or not Yes(UnitIsGroupAssistant, unit)
        or Yes(IsEveryoneAssistant) then
        return nil
    end
    return Row("demote", text, {
        run = function()
            local fn = C_PartyInfo and C_PartyInfo.DemoteAssistant or DemoteAssistant
            Try("DemoteAssistant", fn, unit, true)
        end,
    })
end

ACTIONS.UnitPopupSetRaidRemoveButtonMixin = function(unit)
    if IsSelf(unit) or not IsHuman(unit) or InPvP() then return nil end
    local can = Leader() or (Assist() and not Yes(UnitIsGroupAssistant, unit) and not Yes(UnitIsGroupLeader, unit))
    if not can then return nil end
    return Row("raidremove", Text("REMOVE", "Remove"), { run = function() Uninvite(unit) end })
end

local ROLES = {
    { "TANK", "TANK", "Tank" }, { "HEALER", "HEALER", "Healer" },
    { "DAMAGER", "DAMAGER", "Damage" }, { "NONE", "NO_ROLE", "No role" },
}

ACTIONS.UnitPopupSelectRoleButtonMixin = function(unit)
    if not InGroup() then return nil end
    if C_Scenario and C_Scenario.IsInScenario and Yes(C_Scenario.IsInScenario) then return nil end
    if not (Leader() or Assist() or IsSelf(unit)) then return nil end
    local cur = Ask(UnitGroupRolesAssigned, unit)
    local sub = {}
    for _, r in ipairs(ROLES) do
        sub[#sub + 1] = Row("role" .. r[1], Text(r[2], r[3]), {
            checked = cur == r[1],
            run = function() Try("UnitSetRole", UnitSetRole, unit, r[1]) end,
        })
    end
    return Row("role", Text("SET_ROLE", "Set role"), { sub = sub })
end

ACTIONS.UnitPopupPartyLeaveButtonMixin = function()
    if not InGroup() or InGroup(LE_PARTY_CATEGORY_INSTANCE) or InPvP() then return nil end
    return Row("leave", Text("PARTY_LEAVE", "Leave group"), {
        run = function() Try("LeaveParty", C_PartyInfo and C_PartyInfo.LeaveParty or LeaveParty) end,
    })
end



ACTIONS.UnitPopupPartyInstanceLeaveButtonMixin = function()
    if not (PartyUtil and PartyUtil.CanLeaveInstance and Yes(PartyUtil.CanLeaveInstance)) then return nil end
    return Row("leaveinstance", Text("INSTANCE_PARTY_LEAVE", "Leave instance group"), {
        confirm = "THUGUI_LEAVE_INSTANCE_GROUP",
    })
end

ACTIONS.UnitPopupConvertToRaidButtonMixin = function()
    if InRaid() or InGroup(LE_PARTY_CATEGORY_INSTANCE) or not Leader() then return nil end
    return Row("toraid", Text("CONVERT_TO_RAID", "Convert to raid"), {
        run = function() Try("ConvertToRaid", C_PartyInfo and C_PartyInfo.ConvertToRaid or ConvertToRaid) end,
    })
end

ACTIONS.UnitPopupConvertToPartyButtonMixin = function()
    if not InRaid() or InGroup(LE_PARTY_CATEGORY_INSTANCE) or not Leader() then return nil end
    local row = Row("toparty", Text("CONVERT_TO_PARTY", "Convert to party"), {
        run = function() Try("ConvertToParty", C_PartyInfo and C_PartyInfo.ConvertToParty or ConvertToParty) end,
    })
    local n = Ask(GetNumGroupMembers)
    if n and n > (MEMBERS_PER_RAID_GROUP or 5) then
        row.enabled, row.reason = false, "Too many members for a party."
    end
    return row
end

ACTIONS.UnitPopupResetInstancesButtonMixin = function()
    if Yes(IsInInstance) then return nil end
    if InGroup() and not Leader() then return nil end
    return Row("resetinstances", Text("RESET_INSTANCES", "Reset all instances"), {
        confirm = "THUGUI_RESET_INSTANCES",
    })
end

ACTIONS.UnitPopupVehicleLeaveButtonMixin = function()
    if not Yes(CanExitVehicle) then return nil end
    return Row("vehicleleave", Text("VEHICLE_LEAVE", "Leave vehicle"), {
        run = function() Try("VehicleExit", VehicleExit) end,
    })
end



ACTIONS.UnitPopupPetDismissButtonMixin = function()
    if not Yes(PetCanBeDismissed) then return nil end
    local text = Text("PET_DISMISS", "Dismiss pet")
    if Yes(PetCanBeAbandoned) then
        local id = Constants and Constants.SpellBookSpellIDs and Constants.SpellBookSpellIDs.SPELL_ID_DISMISS_PET
        local name = id and C_Spell and C_Spell.GetSpellName and Ask(C_Spell.GetSpellName, id)
        if not name then return nil end
        return Row("petdismiss", text, { macro = "/cast " .. name })
    end
    return Row("petdismiss", text, { run = function() Try("PetDismiss", PetDismiss) end })
end

ACTIONS.UnitPopupPetAbandonButtonMixin = function()
    if not Yes(PetCanBeAbandoned) or not Yes(PetHasActionBar) then return nil end
    return Row("petabandon", Text("RELEASE_PET_BUTTON_LABEL", Text("PET_ABANDON", "Abandon pet")), {
        confirm = "THUGUI_ABANDON_PET",
    })
end

ACTIONS.UnitPopupPetRenameButtonMixin = function()
    if not Yes(PetCanBeAbandoned) then return nil end
    if PetCanBeRenamed and not Yes(PetCanBeRenamed) then return nil end
    return Row("petrename", Text("PET_RENAME", "Rename pet"), { confirm = "THUGUI_RENAME_PET" })
end

UM.ACTIONS = ACTIONS

local TITLES = {
    UnitPopupInteractSubsectionTitle = { "UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_INTERACT", "Interact" },
    UnitPopupOtherSubsectionTitle = { "UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_OTHER", "Other options" },
    UnitPopupLootSubsectionTitle = { "UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_LOOT", "Loot" },
    UnitPopupInstanceSubsectionTitle = { "UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_INSTANCE", "Instance" },
}
UM.TITLES = TITLES


ThugUI.Dialogs = ThugUI.Dialogs or {}
ThugUI.Dialogs.THUGUI_RESET_INSTANCES = {
    text = Text("CONFIRM_RESET_INSTANCES", "Do you really want to reset all of your instances?"),
    button1 = Text("YES", "Yes"), button2 = Text("NO", "No"),
    OnAccept = function() Try("ResetInstances", ResetInstances) end,
}
ThugUI.Dialogs.THUGUI_LEAVE_INSTANCE_GROUP = {
    text = Text("INSTANCE_PARTY_LEAVE", "Leave instance group") .. "?",
    button1 = Text("YES", "Yes"), button2 = Text("NO", "No"),
    OnAccept = function() Try("LeaveParty", C_PartyInfo and C_PartyInfo.LeaveParty or LeaveParty) end,
}
ThugUI.Dialogs.THUGUI_ABANDON_PET = {
    text = "Abandon your pet? It will be gone for good.",
    button1 = Text("YES", "Yes"), button2 = Text("NO", "No"),
    OnAccept = function() Try("PetAbandon", C_PetInfo and C_PetInfo.PetAbandon or PetAbandon) end,
}
ThugUI.Dialogs.THUGUI_RENAME_PET = {
    text = "Rename your pet:",
    button1 = Text("ACCEPT", "Accept"), button2 = Text("CANCEL", "Cancel"),
    hasEditBox = true,
    OnAccept = function(self)
        local box = self.GetEditBox and self:GetEditBox()
        local name = box and box:GetText()
        if type(name) == "string" and name ~= "" then
            Try("PetRename", C_PetInfo and C_PetInfo.PetRename or PetRename, name)
        end
    end,
}





local FALLBACK = {
    SELF = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin",
        "UnitPopupLootSubsectionTitle", "UnitPopupInstanceSubsectionTitle",
        "UnitPopupConvertToRaidButtonMixin", "UnitPopupConvertToPartyButtonMixin",
        "UnitPopupResetInstancesButtonMixin", "UnitPopupOtherSubsectionTitle",
        "UnitPopupSelectRoleButtonMixin", "UnitPopupPartyInstanceLeaveButtonMixin",
        "UnitPopupPartyLeaveButtonMixin" },
    PARTY = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin",
        "UnitPopupAddFriendButtonMixin", "UnitPopupInteractSubsectionTitle",
        "UnitPopupPromoteButtonMixin", "UnitPopupWhisperButtonMixin", "UnitPopupInspectButtonMixin",
        "UnitPopupTradeButtonMixin", "UnitPopupFollowButtonMixin", "UnitPopupDuelButtonMixin",
        "UnitPopupOtherSubsectionTitle", "UnitPopupSelectRoleButtonMixin", "UnitPopupUninviteButtonMixin" },
    RAID_PLAYER = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin",
        "UnitPopupAddFriendButtonMixin", "UnitPopupInteractSubsectionTitle",
        "UnitPopupSetRaidLeaderButtonMixin", "UnitPopupSetRaidAssistButtonMixin",
        "UnitPopupSetRaidDemoteButtonMixin", "UnitPopupWhisperButtonMixin", "UnitPopupInspectButtonMixin",
        "UnitPopupTradeButtonMixin", "UnitPopupFollowButtonMixin", "UnitPopupDuelButtonMixin",
        "UnitPopupOtherSubsectionTitle", "UnitPopupSelectRoleButtonMixin", "UnitPopupSetRaidRemoveButtonMixin" },
    PLAYER = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin",
        "UnitPopupAddFriendButtonMixin", "UnitPopupInteractSubsectionTitle",
        "UnitPopupInviteButtonMixin", "UnitPopupWhisperButtonMixin", "UnitPopupInspectButtonMixin",
        "UnitPopupTradeButtonMixin", "UnitPopupFollowButtonMixin", "UnitPopupDuelButtonMixin" },
    ENEMY_PLAYER = { "UnitPopupSetFocusButtonMixin", "UnitPopupInteractSubsectionTitle",
        "UnitPopupDuelButtonMixin" },
    PET = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin",
        "UnitPopupInteractSubsectionTitle", "UnitPopupPetRenameButtonMixin",
        "UnitPopupPetDismissButtonMixin", "UnitPopupPetAbandonButtonMixin" },
    OTHERPET = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin" },
    VEHICLE = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin",
        "UnitPopupOtherSubsectionTitle", "UnitPopupVehicleLeaveButtonMixin" },
    TARGET = { "UnitPopupRaidTargetButtonMixin", "UnitPopupSetFocusButtonMixin",
        "UnitPopupAddFriendButtonMixin" },
}
UM.FALLBACK = FALLBACK



local function NameOf()
    local map = {}
    for name in pairs(ACTIONS) do
        local m = _G[name]
        if type(m) == "table" then map[m] = name end
    end
    for name in pairs(TITLES) do
        local m = _G[name]
        if type(m) == "table" then map[m] = name end
    end
    return map
end





local function Flatten(list, out, depth)
    for _, e in ipairs(list) do
        if type(e) == "table" and e.AssembleMenuEntries and type(e.GetEntries) == "function" and depth < 3 then
            local ok, kids = pcall(e.GetEntries, e)
            if ok and type(kids) == "table" then Flatten(kids, out, depth + 1) end
        else
            out[#out + 1] = e
        end
    end
    return out
end



function UM:Names(which)
    local menus = rawget(_G, "UnitPopupMenus")
    local menu = type(menus) == "table" and menus[which]
    if type(menu) ~= "table" or type(menu.GetEntries) ~= "function" then
        LogOnce("fallback-" .. tostring(which), "%s: Blizzard's menu list not available, using our copy", tostring(which))
        return FALLBACK[which] or {}
    end
    local ok, list = pcall(menu.GetEntries, menu)
    if not ok or type(list) ~= "table" then
        LogOnce("fallback-" .. tostring(which), "%s: GetEntries failed (%s), using our copy", tostring(which), tostring(list))
        return FALLBACK[which] or {}
    end
    local map, names, skipped = NameOf(), {}, 0
    for _, e in ipairs(Flatten(list, {}, 0)) do
        local name = map[e]
        if name then names[#names + 1] = name else skipped = skipped + 1 end
    end
    LogOnce("skipped-" .. which, "%s: %d entries we do not offer", which, skipped)
    return names
end



function UM:Entries(unit)
    local which = self:Which(unit)
    if not which then return {} end
    local rows, pendingTitle = {}, nil
    for _, name in ipairs(self:Names(which)) do
        local t = TITLES[name]
        if t then
            pendingTitle = { title = Text(t[1], t[2]) }
        elseif ACTIONS[name] then
            local ok, row = pcall(ACTIONS[name], unit)
            if not ok then
                LogOnce("build-" .. name, "%s: %s", name, tostring(row))
            elseif row then
                if pendingTitle then rows[#rows + 1] = pendingTitle; pendingTitle = nil end
                rows[#rows + 1] = row
            end
        end
    end
    return rows, which
end



function UM:MacroText(row)
    if not row or type(row.macro) ~= "string" or row.macro == "" then return nil end
    return "/stopmacro [combat]\n" .. row.macro
end
