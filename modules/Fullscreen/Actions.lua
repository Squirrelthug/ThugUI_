























local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen
local A = {}
FS.Actions = A

local UNBIND_DELAY = 0.5     
local BUTTON = "ThugUI_FSAction"



local TARGET_BUTTON = "ThugUI_FSTarget"
local STOP_BUTTONS = { stop = "ThugUI_FSStop", macro = "ThugUI_FSStopMacro" }


A.LEGEND_LINES = 4

local function Log(message, ...)
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("FULLSCREEN", message, ...)
    end
end

local function Later(fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, fn)
    else
        fn()
    end
end


local function G(name, fallback)
    local value = _G[name]
    if type(value) == "string" and value ~= "" then
        return value
    end
    return fallback
end

local function Readable(value)
    return not (issecretvalue and issecretvalue(value))
end




local function Combat()
    return InCombatLockdown() or A.combatSoon == true
end








local MSG_SWITCH = "In combat, close this window to use items from Blizzard's bag"
local MSG_NO_SLOT = "No free bag slot"
local MSG_REFUSED = "The game refused that"
local MSG_MOVED = "That item moved"
local MSG_NOT_NOW = "You can't do that in combat"

local function ArmorMessage()
    return G("ERR_NOT_IN_COMBAT", "You can't change armor in combat")
end



local function IsBagItem(item)
    return type(item) == "table" and item.kind == nil
        and type(item.bag) == "number" and type(item.slot) == "number"
end

local function MaxBag()
    return _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4
end

local function SideOf(item)
    return item and item.kind == "equip" and "plugin" or "bag"
end





local refusalCache = {}




local function IsRed(color)
    if type(color) ~= "table" or not Readable(color) then
        return false
    end
    local r, g, b = color.r, color.g, color.b
    if not (Readable(r) and Readable(g) and Readable(b)) then
        return false
    end
    return type(r) == "number" and type(g) == "number" and type(b) == "number"
        and r > 0.9 and g < 0.2 and b < 0.2
end

function FS.ClearRefusals()
    refusalCache = {}
end




function FS.Refusal(item)
    if not IsBagItem(item) then
        return nil
    end
    local c = _G.C_Container
    if not (c and c.GetContainerItemLink) then
        return nil
    end
    local okLink, link = pcall(c.GetContainerItemLink, item.bag, item.slot)
    if not okLink or type(link) ~= "string" or not Readable(link) then
        return nil
    end
    local cached = refusalCache[link]
    if cached ~= nil then
        return cached or nil
    end
    local tip = _G.C_TooltipInfo
    if not (tip and tip.GetBagItem) then
        return nil
    end
    local okData, data = pcall(tip.GetBagItem, item.bag, item.slot)
    if not okData or type(data) ~= "table" or type(data.lines) ~= "table" then
        
        return nil
    end
    local reason = false
    for index, line in ipairs(data.lines) do
        if index > 1 and type(line) == "table" and Readable(line) then
            local text = line.leftText
            if IsRed(line.leftColor) and type(text) == "string" and Readable(text) and text ~= "" then
                reason = text
                break
            end
        end
    end
    refusalCache[link] = reason
    return reason or nil
end





local function ActionLabel(kind, item)
    if kind == "use" and item and item.hasLoot then
        
        
        return G("OPEN", "Open")
    elseif kind == "use" then
        return G("CONTEXT_ACTION_LABEL_USE", "Use")
    elseif kind == "equip" then
        return G("CONTEXT_ACTION_LABEL_EQUIP", "Equip")
    end
    return "Unequip"
end

local function IsUsable(item)
    
    if item.hasSpell or item.hasLoot then
        return true
    end
    if C_Item and C_Item.IsUsableItem and item.itemID then
        local ok, usable = pcall(C_Item.IsUsableItem, item.itemID)
        return ok and usable and true or false
    end
    return false
end



function A.MainAction(item)
    if type(item) ~= "table" then
        return nil
    end
    if item.kind == "equip" then
        if item.itemID and type(item.slot) == "number" then
            return { kind = "unequip", label = ActionLabel("unequip"), slot = item.slot, itemID = item.itemID }
        end
        return nil
    end
    if not IsBagItem(item) or not item.itemID then
        return nil
    end
    
    
    if A.IsBag(item) then
        return A.BagAction(item)
    end
    local kind
    if item.equippable then
        kind = "equip"
    elseif IsUsable(item) then
        kind = "use"
    end
    if not kind then
        return nil
    end
    return {
        kind = kind, label = ActionLabel(kind, item), bag = item.bag, slot = item.slot,
        itemID = item.itemID, refusal = FS.Refusal(item),
    }
end



local function LockedLabel(action)
    if action.refusal then
        return action.label .. " (" .. G("LOCKED", "Locked") .. ")"
    end
    return action.label
end

function A.CanMenu(item)
    if type(item) ~= "table" then
        return false
    end
    if item.kind == "equip" then
        return item.itemID ~= nil
    end
    return IsBagItem(item) and item.itemID ~= nil
end


function A.Busy()
    if _G.CursorHasItem and _G.CursorHasItem() then
        return "Put down what is on your cursor first"
    end
    if _G.SpellIsTargeting and _G.SpellIsTargeting() then
        return "Finish choosing a target first"
    end
    return nil
end




function A.FreeSlot(exclude)
    local c = _G.C_Container
    if not (c and c.GetContainerNumFreeSlots and c.GetContainerNumSlots and c.GetContainerItemInfo) then
        return nil
    end
    for bag = 0, MaxBag() do
        local ok, free, family = pcall(c.GetContainerNumFreeSlots, bag)
        if bag ~= exclude and ok and type(free) == "number" and free > 0 and (family == nil or family == 0) then
            for slot = 1, c.GetContainerNumSlots(bag) or 0 do
                if not c.GetContainerItemInfo(bag, slot) then
                    return bag, slot
                end
            end
        end
    end
    return nil
end





local MSG_BACKPACK = "The backpack cannot be changed."
local MSG_BAGS_COMBAT = "Bags cannot be changed in combat."
local MSG_NO_EMPTY_SLOT = "No empty bag slot: Y to choose one to replace"
local MSG_BAG_INSIDE = "That bag is inside the bag you are replacing."
local MSG_NO_ROOM = "No free slot to put this bag in."



local function BagSlots()
    return _G.NUM_BAG_SLOTS or 4
end

local function ItemsText(count)
    return count == 1 and "1 item" or (count .. " items")
end




local function BagInfo(n)
    local c = _G.C_Container
    local size = c and c.GetContainerNumSlots and c.GetContainerNumSlots(n) or 0
    local free, family = 0, 0
    if size > 0 and c.GetContainerNumFreeSlots then
        local ok, f, fam = pcall(c.GetContainerNumFreeSlots, n)
        if ok then
            free, family = f or 0, fam or 0
        end
    end
    return size, free, family
end


local function InvID(n)
    local c = _G.C_Container
    local fn = (c and c.ContainerIDToInventoryID) or _G.ContainerIDToInventoryID
    if type(fn) ~= "function" then
        return nil
    end
    local ok, id = pcall(fn, n)
    return ok and type(id) == "number" and id or nil
end




function A.ItemFamily(itemID)
    local fn = (_G.C_Item and _G.C_Item.GetItemFamily) or _G.GetItemFamily
    if type(fn) ~= "function" or not itemID then
        return 0
    end
    local ok, family = pcall(fn, itemID)
    return ok and type(family) == "number" and family or 0
end

function A.BagTypeName(family)
    if family == 0 then
        return "Bag"
    elseif family == 1 then
        return "Quiver"
    elseif family == 2 then
        return "Ammo pouch"
    end
    return "Special bag"
end



function A.IsBag(item)
    if not IsBagItem(item) or not item.itemID then
        return false
    end
    return item.equipLoc == "INVTYPE_BAG" or item.equipLoc == "INVTYPE_QUIVER"
        or item.classID == 1 or item.classID == 11
end




local function SlotsPattern()
    local fmt = _G.CONTAINER_SLOTS
    if type(fmt) ~= "string" or not fmt:find("%d", 1, true) then
        return "^(%d+)%s+[Ss]lot"
    end
    local escaped = fmt:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    escaped = escaped:gsub("%%d", "(%%d+)", 1):gsub("%%s", ".+")
    return "^" .. escaped
end
A.SlotsPattern = SlotsPattern



function A.LooseBagSize(item)
    local tip = _G.C_TooltipInfo
    if not (tip and tip.GetBagItem) then
        return nil
    end
    local ok, data = pcall(tip.GetBagItem, item.bag, item.slot)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then
        return nil
    end
    for _, line in ipairs(data.lines) do
        local text = type(line) == "table" and line.leftText
        if type(text) == "string" and Readable(text) then
            local n = text:match(SlotsPattern())
            if n then
                return tonumber(n)
            end
        end
    end
    return nil
end






function FS.CanPlaceBag(bagItem, n)
    if Combat() then
        return false, MSG_BAGS_COMBAT
    end
    if n == 0 then
        return false, MSG_BACKPACK
    end
    if type(n) ~= "number" or n < 1 or n > BagSlots() then
        return false, "That bag slot cannot be changed."
    end
    if not A.IsBag(bagItem) then
        return false, "That is not a bag."
    end
    local size, free = BagInfo(n)
    if bagItem.bag == n then
        return false, MSG_BAG_INSIDE
    end
    if size > 0 and size - free > 0 then
        return false, "Empty this bag first: it holds " .. ItemsText(size - free) .. "."
    end
    local family = A.ItemFamily(bagItem.itemID)
    if family == 1 or family == 2 then
        for other = 1, BagSlots() do
            if other ~= n then
                local _, _, otherFamily = BagInfo(other)
                if otherFamily == family then
                    return false, family == 1 and G("ERR_ONLY_ONE_QUIVER", "You can only use one quiver or ammo pouch.")
                        or G("ERR_ONLY_ONE_AMMO", "You can only use one quiver or ammo pouch.")
                end
            end
        end
    end
    return true
end


function FS.CanRemoveBag(n)
    if Combat() then
        return false, MSG_BAGS_COMBAT
    end
    if n == 0 then
        return false, MSG_BACKPACK
    end
    if type(n) ~= "number" or n < 1 or n > BagSlots() then
        return false, "That bag slot cannot be changed."
    end
    local size, free = BagInfo(n)
    if size == 0 then
        return false, "That slot is empty."
    end
    if size - free > 0 then
        return false, "Empty this bag first: it holds " .. ItemsText(size - free) .. "."
    end
    if not A.FreeSlot(n) then
        return false, MSG_NO_ROOM
    end
    return true
end


function A.FirstEmptyBagSlot()
    for n = 1, BagSlots() do
        if (BagInfo(n)) == 0 then
            return n
        end
    end
    return nil
end



function A.BagAction(item)
    local n = A.FirstEmptyBagSlot()
    local refusal
    if not n then
        refusal = MSG_NO_EMPTY_SLOT
    else
        local ok, why = FS.CanPlaceBag(item, n)
        if not ok then
            refusal = why
        end
    end
    return {
        kind = "bag", label = "Equip bag", bag = item.bag, slot = item.slot,
        itemID = item.itemID, bagSlot = n, refusal = refusal or FS.Refusal(item),
    }
end


function A.LooseBags()
    local list = {}
    local c = _G.C_Container
    if not (c and c.GetContainerNumSlots) then
        return list
    end
    for bag = 0, MaxBag() do
        for slot = 1, c.GetContainerNumSlots(bag) or 0 do
            local info = FS.Classify.Read(bag, slot)
            if A.IsBag(info) then
                list[#list + 1] = info
            end
        end
    end
    return list
end







function A:Build()
    if self.button then
        return true
    end
    if InCombatLockdown() then
        return false
    end
    local ok, button = pcall(CreateFrame, "Button", BUTTON, UIParent, "SecureActionButtonTemplate")
    if not ok or not button then
        Log("action button not built: %s", tostring(button))
        return false
    end
    pcall(button.SetAttribute, button, "type", "item")
    
    
    pcall(button.RegisterForClicks, button, "AnyDown", "AnyUp")
    pcall(button.Hide, button)
    pcall(button.HookScript, button, "OnClick", function()
        A:AfterClick()
    end)
    self.button = button
    self.owner = CreateFrame("Frame")
    return true
end


A.luaEquip = nil

local function EquipMode()
    if A.luaEquip == true then
        return "lua"
    end
    if A.luaEquip == nil and A.EquipProbe then
        return "probe"
    end
    return "secure"
end





function A:Wanted()
    local frame = FS.UI and FS.UI.frame
    if not (frame and frame:IsShown()) then
        return nil
    end
    local T = FS.Target
    if T and T.active then
        
        
        
        if self.panel then
            return nil
        end
        local at = A.TargetOf(FS:Focused())
        if not at then
            return nil
        end
        return {
            key = T.APPLY_KEY, target = true, bag = at.bag, slot = at.slot,
            action = { kind = "target", bag = at.bag, slot = at.slot },
        }
    end
    local action, key
    if self.panel then
        local row = self.panel.rows[self.panel.row]
        action = row and row.secure and row.action
        key = "PAD1"
    else
        action = A.MainAction(FS:Focused())
        key = "PAD3"
    end
    if not action or action.refusal or (action.kind ~= "use" and action.kind ~= "equip") then
        return nil
    end
    if action.kind == "equip" and EquipMode() == "lua" then
        return nil
    end
    return { key = key, action = action }
end



function A:Sync()
    if Combat() then
        self.pending = true
        return
    end
    self:SyncStop()
    local want = self:Wanted()
    if not (want and want.target) then
        self:DisarmTarget()
    end
    if not want then
        self:Disarm(false)
        return
    end
    if want.target then
        
        self:Disarm(true)
        self:ArmTarget(want)
        return
    end
    if not self:Build() then
        return
    end
    local a = want.action
    local ok, err = pcall(self.button.SetAttribute, self.button, "item", a.bag .. " " .. a.slot)
    if not ok then
        Log("action attribute refused: %s", tostring(err))
        return
    end
    
    
    
    
    
    
    
    
    
    if self.boundKey == want.key and not self:Owns(want.key) then
        Log("binding retaken from %s", tostring(self:Holder(want.key)))
        pcall(ClearOverrideBindings, self.owner)
        self.boundKey = nil
    end
    if self.boundKey ~= want.key then
        if self.boundKey then
            pcall(ClearOverrideBindings, self.owner)
            self.boundKey = nil
        end
        local okBind, bindErr = pcall(SetOverrideBindingClick, self.owner, true, want.key, BUTTON, "LeftButton")
        if okBind then
            self.boundKey = want.key
        else
            Log("action binding refused: %s", tostring(bindErr))
            return
        end
    end
    self.armed = { bag = a.bag, slot = a.slot, itemID = a.itemID }
end








function A.TargetOf(item)
    if type(item) ~= "table" or not item.itemID then
        return nil
    end
    if item.kind == "equip" then
        if type(item.slot) == "number" then
            return { slot = item.slot }
        end
        return nil
    end
    if IsBagItem(item) then
        return { bag = item.bag, slot = item.slot }
    end
    return nil
end







function A:BuildTarget()
    if self.targetButton then
        return true
    end
    if InCombatLockdown() then
        return false
    end
    local ok, button = pcall(CreateFrame, "Button", TARGET_BUTTON, UIParent, "SecureActionButtonTemplate")
    if not ok or not button then
        Log("apply button not built: %s", tostring(button))
        return false
    end
    pcall(button.RegisterForClicks, button, "AnyDown", "AnyUp")
    pcall(button.Hide, button)
    pcall(button.HookScript, button, "OnClick", function()
        A:AfterTargetClick()
    end)
    self.targetButton = button
    self.targetOwner = CreateFrame("Frame")
    return true
end




function A:BuildStop()
    if self.stopButtons then
        return true
    end
    if InCombatLockdown() then
        return false
    end
    local made = {}
    for mode, name in pairs(STOP_BUTTONS) do
        local ok, button = pcall(CreateFrame, "Button", name, UIParent, "SecureActionButtonTemplate")
        if not ok or not button then
            Log("stop button %s not built: %s", name, tostring(button))
            return false
        end
        if mode == "stop" then
            pcall(button.SetAttribute, button, "type", "stop")
        else
            pcall(button.SetAttribute, button, "type", "macro")
            pcall(button.SetAttribute, button, "macrotext", "/stopspelltarget")
        end
        pcall(button.RegisterForClicks, button, "AnyDown", "AnyUp")
        pcall(button.Hide, button)
        pcall(button.HookScript, button, "OnClick", function()
            if FS.Target then
                FS.Target:AfterStop(mode)
            end
        end)
        made[mode] = button
    end
    self.stopButtons = made
    self.stopOwner = CreateFrame("Frame")
    return true
end




local function TakeKey(self, field, owner, key, buttonName)
    if self[field] == key and not self:Owns(key, buttonName) then
        Log("binding retaken from %s", tostring(self:Holder(key)))
        pcall(ClearOverrideBindings, owner)
        self[field] = nil
    end
    if self[field] ~= key then
        if self[field] then
            pcall(ClearOverrideBindings, owner)
            self[field] = nil
        end
        local ok, err = pcall(SetOverrideBindingClick, owner, true, key, buttonName, "LeftButton")
        if not ok then
            Log("binding %s refused: %s", buttonName, tostring(err))
            return false
        end
        self[field] = key
    end
    return true
end


function A:ArmTarget(want)
    if not self:BuildTarget() then
        return
    end
    local b = self.targetButton
    
    
    
    
    
    local ok, err = pcall(function()
        b:SetAttribute("target-slot", want.slot)
        b:SetAttribute("target-bag", want.bag)
        b:SetAttribute("*target-slot", nil)
        b:SetAttribute("*target-bag", nil)
    end)
    if not ok then
        Log("apply attribute refused: %s", tostring(err))
        return
    end
    if TakeKey(self, "targetBoundKey", self.targetOwner, want.key, TARGET_BUTTON) then
        self.armedTarget = { bag = want.bag, slot = want.slot }
    end
end

function A:DisarmTarget()
    if not self.targetBoundKey then
        return
    end
    if Combat() then
        self.pending = true
        return
    end
    pcall(ClearOverrideBindings, self.targetOwner)
    if self.targetButton then
        pcall(self.targetButton.SetAttribute, self.targetButton, "target-slot", nil)
        pcall(self.targetButton.SetAttribute, self.targetButton, "target-bag", nil)
        pcall(self.targetButton.SetAttribute, self.targetButton, "*target-slot", nil)
        pcall(self.targetButton.SetAttribute, self.targetButton, "*target-bag", nil)
    end
    self.targetBoundKey = nil
    self.armedTarget = nil
end


function A:SyncStop()
    local T = FS.Target
    local frame = FS.UI and FS.UI.frame
    if not (T and T.active and frame and frame:IsShown()) then
        self:DisarmStop()
        return
    end
    if not self:BuildStop() then
        return
    end
    local mode = T.STOP_MODE == "macro" and "macro" or "stop"
    local name = STOP_BUTTONS[mode]
    if self.stopName and self.stopName ~= name and self.stopBoundKey then
        
        pcall(ClearOverrideBindings, self.stopOwner)
        self.stopBoundKey = nil
    end
    self.stopName = name
    TakeKey(self, "stopBoundKey", self.stopOwner, T.CANCEL_KEY, name)
end

function A:DisarmStop()
    if not self.stopBoundKey then
        return
    end
    if Combat() then
        self.pending = true
        return
    end
    pcall(ClearOverrideBindings, self.stopOwner)
    self.stopBoundKey = nil
end



function A:AfterTargetClick()
    local T = FS.Target
    if T and T.active then
        T:NoteApply("click")
        T:AfterApply()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.6, function()
            A:Sync()
        end)
    end
end


function A:Holder(key)
    local ok, action = pcall(GetBindingAction, key, true)
    return ok and action or nil
end



function A:Owns(key, name)
    if type(GetBindingAction) ~= "function" then
        return true
    end
    return self:Holder(key) == "CLICK " .. (name or BUTTON) .. ":LeftButton"
end




function A:Disarm(force)
    if not self.boundKey then
        return
    end
    if Combat() then
        self.pending = true
        return
    end
    local now = GetTime and GetTime() or 0
    if not force and self.pressAt and now - self.pressAt < UNBIND_DELAY then
        
        
        C_Timer.After(UNBIND_DELAY, function()
            if not A:Wanted() then
                A:Disarm(true)
            end
        end)
        return
    end
    pcall(ClearOverrideBindings, self.owner)
    if self.button then
        pcall(self.button.SetAttribute, self.button, "item", nil)
    end
    self.boundKey = nil
end

function A:OnCombatStart()
    self.combatSoon = true
    
    
    if self.panel then
        self:ClosePanel()
    end
    
    
    if self.owner then
        pcall(ClearOverrideBindings, self.owner)
    end
    self.boundKey = nil
    
    if self.targetOwner then
        pcall(ClearOverrideBindings, self.targetOwner)
    end
    self.targetBoundKey = nil
    self.armedTarget = nil
    if self.stopOwner then
        pcall(ClearOverrideBindings, self.stopOwner)
    end
    self.stopBoundKey = nil
end

function A:OnCombatEnd()
    self.combatSoon = nil
    if self.pending then
        self.pending = nil
        self:Sync()
    end
end

function A:AfterClick()
    
    
    if C_Timer and C_Timer.After then
        C_Timer.After(0.6, function()
            A:Sync()
        end)
    end
    if self.panel and self.panel.id == "menu" then
        Later(function()
            A:ClosePanel()
        end)
    end
end




function A:ShouldPass(button)
    local T = FS.Target
    if T and T.active then
        
        if Combat() then
            return false
        end
        if button == T.CANCEL_KEY and self.stopBoundKey == button then
            return true
        end
        local want = self:Wanted()
        return (want and want.target and self.targetBoundKey == button and want.key == button) and true or false
    end
    if not self.boundKey or button ~= self.boundKey or Combat() then
        return false
    end
    local want = self:Wanted()
    if not want or want.key ~= button then
        return false
    end
    if want.action.kind == "equip" and EquipMode() ~= "secure" then
        return false
    end
    return true
end






function A:LogPress(button)
    local T = FS.Target
    if T and T.active then
        
        
        local item = FS:Focused()
        local at = A.TargetOf(item)
        local okBind, bound = pcall(GetBindingAction, button, true)
        local what = "none"
        if button == T.CANCEL_KEY then
            what = "back"
        elseif at and at.bag then
            what = "apply bag=" .. at.bag .. " slot=" .. at.slot
        elseif at then
            what = "equip slot=" .. at.slot
        end
        local name = TARGET_BUTTON
        if button == T.CANCEL_KEY then
            name = STOP_BUTTONS[self.stopName == STOP_BUTTONS.macro and "macro" or "stop"]
        end
        T.Log("press %s: %s | buttonOwned=%s binding=%s combat=%s", button, what,
            tostring(self:Owns(button, name)), okBind and tostring(bound) or "?", tostring(Combat()))
        if button ~= T.CANCEL_KEY then
            T.Log("match %s", tostring(T.Match(item) or "DoesNotApply"))
        end
        return
    end
    local want = self:Wanted()
    local action = A.MainAction(FS:Focused())
    local okBind, bound = pcall(GetBindingAction, button, true)
    Log("press %s: bound=%s game=%s want=%s kind=%s refusal=%s panel=%s combat=%s passing=%s armed=%s",
        button, tostring(self.boundKey), okBind and tostring(bound) or "?",
        want and (want.key .. " " .. want.action.bag .. " " .. want.action.slot) or "nil",
        action and tostring(action.kind) or "nil", action and tostring(action.refusal) or "nil",
        self.panel and tostring(self.panel.id) or "nil", tostring(Combat()), tostring(self.passing),
        self.armed and (self.armed.bag .. " " .. self.armed.slot) or "nil")
end

function A:BeginPass(button)
    self:EndPass()
    self.pressAt = GetTime and GetTime() or 0
    self.passing = button
    local T = FS.Target
    if T and T.active and button == T.APPLY_KEY then
        T:NoteApply("press")
    end
    local input = FS.UI.input
    if input then
        pcall(input.SetPropagateKeyboardInput, input, true)
    end
end



function A:EndPass()
    if not self.passing then
        return
    end
    self.passing = nil
    local input = FS.UI.input
    if input and not InCombatLockdown() then
        pcall(input.SetPropagateKeyboardInput, input, false)
    end
end






function A.EquipProbe(action)
    local c = _G.C_Container
    local frame = A.probeFrame
    if not frame then
        frame = CreateFrame("Frame")
        A.probeFrame = frame
    end
    A.probeBlocked = nil
    frame:SetScript("OnEvent", function(_, event, addon, func)
        if event == "ADDON_ACTION_BLOCKED" and (addon == nil or addon == "ThugUI") then
            A.probeBlocked = "ADDON_ACTION_BLOCKED " .. tostring(func)
        end
    end)
    local watching = pcall(frame.RegisterEvent, frame, "ADDON_ACTION_BLOCKED")
    local function Verdict()
        pcall(frame.UnregisterEvent, frame, "ADDON_ACTION_BLOCKED")
        if A.probeBlocked then
            A.luaEquip = false
            Log("Lua equip blocked: %s", tostring(A.probeBlocked))
            FS:Message("The game refused that. Press again to equip.", "bag")
        else
            A.luaEquip = true
            Log("Lua equip ok")
        end
        A:Sync()
    end
    local ok, err = pcall(c.UseContainerItem, action.bag, action.slot)
    if not ok then
        A.probeBlocked = tostring(err)
        Verdict()
        return
    end
    if not watching then
        Log("ADDON_ACTION_BLOCKED could not be watched; the probe trusts the call")
    end
    C_Timer.After(1, Verdict)
end





local function Cursor()
    return _G.CursorHasItem and _G.CursorHasItem()
end

local function ClearCursorSafe()
    if _G.ClearCursor then
        pcall(_G.ClearCursor)
    end
end


function A:Unequip(action)
    if Combat() then
        FS:Message(ArmorMessage(), "plugin")
        return false
    end
    local bag, slot = A.FreeSlot()
    if not bag then
        FS:Message(MSG_NO_SLOT, "plugin")
        return false
    end
    ClearCursorSafe()
    local ok, err = pcall(_G.PickupInventoryItem, action.slot)
    if not ok or (_G.CursorHasItem and not Cursor()) then
        Log("unequip blocked at pickup: %s", tostring(err))
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "plugin")
        return false
    end
    local okPut, errPut = pcall(C_Container.PickupContainerItem, bag, slot)
    if not okPut or Cursor() then
        Log("unequip blocked at place: %s", tostring(errPut))
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "plugin")
        return false
    end
    return true
end





function A:PlaceBag(item, n)
    local ok, why = FS.CanPlaceBag(item, n)
    if not ok then
        FS:Message(why, "bag")
        return false
    end
    local c = _G.C_Container
    local info = c.GetContainerItemInfo(item.bag, item.slot)
    if not info or info.itemID ~= item.itemID then
        FS:Message(MSG_MOVED, "bag")
        return false
    end
    local inv = InvID(n)
    local put = _G.PutItemInBag
    if not inv or type(put) ~= "function" then
        Log("bag equip unavailable: inventory id %s, PutItemInBag %s", tostring(inv), type(put))
        FS:Message(MSG_REFUSED, "bag")
        return false
    end
    local oldID = _G.GetInventoryItemID and _G.GetInventoryItemID("player", inv)
    ClearCursorSafe()
    local okPick, errPick = pcall(c.PickupContainerItem, item.bag, item.slot)
    if not okPick or (_G.CursorHasItem and not Cursor()) then
        Log("bag pickup blocked: %s", tostring(errPick))
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "bag")
        return false
    end
    local okPut, errPut = pcall(put, inv)
    local refused = not okPut
    if okPut and _G.GetCursorInfo and Cursor() then
        
        
        local okInfo, kind, id = pcall(_G.GetCursorInfo)
        refused = okInfo and kind == "item" and id == item.itemID and oldID ~= item.itemID
    end
    if refused then
        Log("bag equip blocked: %s", tostring(errPut))
    end
    if Cursor() then
        
        
        pcall(c.PickupContainerItem, item.bag, item.slot)
        if Cursor() then
            local bag, slot = A.FreeSlot()
            if bag then
                pcall(c.PickupContainerItem, bag, slot)
            end
        end
    end
    if refused or Cursor() then
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "bag")
        return false
    end
    return true
end



function A:RemoveBag(n)
    local ok, why = FS.CanRemoveBag(n)
    if not ok then
        FS:Message(why, "bag")
        return false
    end
    local inv = InvID(n)
    local pick = _G.PickupBagFromSlot
    if not inv or type(pick) ~= "function" then
        Log("bag removal unavailable: inventory id %s, PickupBagFromSlot %s", tostring(inv), type(pick))
        FS:Message(MSG_REFUSED, "bag")
        return false
    end
    ClearCursorSafe()
    local okPick, errPick = pcall(pick, inv)
    if not okPick or (_G.CursorHasItem and not Cursor()) then
        Log("bag removal blocked: %s", tostring(errPick))
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "bag")
        return false
    end
    local bag, slot = A.FreeSlot(n)
    if bag then
        pcall(C_Container.PickupContainerItem, bag, slot)
    end
    if Cursor() then
        Log("bag removal found no place for the bag")
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "bag")
        return false
    end
    return true
end


function A:LuaUse(action)
    local ok, err = pcall(C_Container.UseContainerItem, action.bag, action.slot)
    if not ok then
        A.luaEquip = false
        Log("Lua equip blocked: %s", tostring(err))
        FS:Message(MSG_REFUSED, "bag")
        A:Sync()
    end
end



function A:RunAction(action, item)
    local side = SideOf(item)
    if action.refusal then
        FS:Message(action.refusal, side)
        return false
    end
    if Combat() then
        if action.kind == "use" then
            FS:Message(MSG_SWITCH, side)
        elseif action.kind == "bag" then
            FS:Message(MSG_BAGS_COMBAT, side)
        else
            
            
            FS:Message(ArmorMessage(), side)
        end
        return false
    end
    local busy = A.Busy()
    if busy then
        FS:Message(busy, side)
        return false
    end
    if action.kind == "unequip" then
        return self:Unequip(action)
    end
    if action.kind == "bag" then
        return self:PlaceBag(item, action.bagSlot)
    end
    if action.kind == "equip" then
        local mode = EquipMode()
        if mode == "probe" then
            A.EquipProbe(action)
            return true
        elseif mode == "lua" then
            self:LuaUse(action)
            return true
        end
    end
    
    
    Log("press not passed to the secure button for %s %s %s", tostring(action.kind), tostring(action.bag), tostring(action.slot))
    FS:Message(MSG_REFUSED, side)
    return false
end


function A:PressMain()
    local item = FS:Focused()
    local T = FS.Target
    if T and T.active then
        
        
        local side = SideOf(item)
        if Combat() then
            FS:Message(MSG_SWITCH, side)
        elseif A.TargetOf(item) then
            Log("press not passed to the apply button for %s", tostring(item.bag))
            FS:Message(MSG_REFUSED, side)
        else
            FS:Message("Nothing here to use it on", side)
        end
        return
    end
    local action = A.MainAction(item)
    if not action then
        return
    end
    self:RunAction(action, item)
end





local RED = { 1, 0.45, 0.4 }

function A:BuildPanelUI()
    if self.ui then
        return self.ui
    end
    local half = FS.UI.halves.plugin
    local ui = { rows = {} }
    ui.text = half.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.text:SetJustifyH("LEFT")
    ui.text:SetJustifyV("TOP")
    ui.text:SetWordWrap(true)
    ui.text:Hide()
    self.ui = ui
    return ui
end

local function NewPanelRow(half)
    local row = CreateFrame("Frame", nil, half.frame, "BackdropTemplate")
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    row:SetBackdropColor(0, 0, 0, 0.6)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:Hide()
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", row, "LEFT", 12, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row:Hide()
    return row
end




local function PlateName(p)
    if p.id == "menu" then
        return "Options"
    elseif p.id == "destroy" then
        return "Confirm"
    elseif p.id == "split" then
        return "Split stack"
    elseif p.id == "bind" then
        return "Bind to controller button"
    end
    return p.title
end
A.PlateName = PlateName



local function RowState(data, focused)
    if data.enabled == false then
        return "cmp_menu_row_disabled"
    elseif data.color == "red" then
        return focused and "cmp_menu_row_danger_focused" or "cmp_menu_row_danger"
    end
    return focused and "cmp_menu_row_focused" or "cmp_menu_row_normal"
end
A.RowState = RowState







function A:RenderPanel()
    local p = self.panel
    local half = FS.UI.halves.plugin
    local ui = self:BuildPanelUI()
    local size = FS:Cfg().textSize
    local framed = FS.Framed() and FS.framed
    local x0 = framed and (half.textX or 0) or 0
    local width = framed and (half.textW or 300) or (FS.contentWidth or 300)
    local halfH = FS.halfHeight or 400
    local titleH = framed and (half.headH or (size + 12)) or (size + 12)
    half.title:SetFont(STANDARD_TEXT_FONT, size + 6)
    half.title:SetText(p.title)
    FS:SetPlateText(half, PlateName(p))
    half.scroll:Hide()
    local y = titleH
    local sk = half.skin
    if p.text then
        ui.text:SetFont(STANDARD_TEXT_FONT, size)
        local pad = framed and 24 or 0
        ui.text:SetWidth(width - 2 * pad)
        ui.text:ClearAllPoints()
        ui.text:SetPoint("TOPLEFT", half.frame, "TOPLEFT", x0 + pad, -(y + (framed and 16 or 0)))
        ui.text:SetText(p.text)
        ui.text:Show()
        if framed then
            ui.block = ui.block == nil and (FS.Skin.Piece(half.frame, "cmp_prompt_block", "ARTWORK", 1) or false) or ui.block
            if ui.block then
                ui.blockHolder = ui.blockHolder or CreateFrame("Frame", nil, half.frame)
                local blockH = math.max(ui.text:GetStringHeight() + 32, 56)
                ui.blockHolder:ClearAllPoints()
                ui.blockHolder:SetPoint("TOPLEFT", half.frame, "TOPLEFT", x0, -y)
                ui.blockHolder:SetSize(width, blockH)
                ui.block:Fill(ui.blockHolder)
                
                if p.id == "destroy" then
                    ui.block:SetTint(0.85, 0.35, 0.3, 1)
                else
                    ui.block:SetTint(1, 1, 1, 1)
                end
                ui.block:Show()
                y = y + blockH + 8
            else
                y = y + ui.text:GetStringHeight() + 8
            end
        else
            if ui.block then
                ui.block:Hide()
            end
            y = y + ui.text:GetStringHeight() + 8
        end
    else
        ui.text:Hide()
        if ui.block then
            ui.block:Hide()
        end
    end
    local rowH = math.max(math.floor(halfH / 5), size + 12)
    if framed then
        rowH = 44 + FS.GAP
    end
    p.rowHeight = rowH
    local visible = math.max(1, math.floor((halfH - y - (framed and FS.SK.WELL_PAD or 0)) / rowH))
    p.scroll.rows = visible
    FS.Scroll.Clamp(p.scroll, #p.rows)
    FS.Scroll.Ensure(p.scroll, p.row)
    for k = #ui.rows + 1, visible do
        ui.rows[k] = NewPanelRow(half)
    end
    local gold = FS.GOLD
    for k, row in ipairs(ui.rows) do
        local index = p.scroll.offset + k
        local data = k <= visible and p.rows[index] or nil
        if data then
            row.data, row.index = data, index
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", half.frame, "TOPLEFT", x0, -(y + (k - 1) * rowH))
            row:SetSize(width, rowH - 4)
            row.label:SetFont(STANDARD_TEXT_FONT, size + 2)
            
            row.label:ClearAllPoints()
            if data.icon then
                row.icon:SetSize(rowH - 12, rowH - 12)
                row.icon:ClearAllPoints()
                row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
                row.icon:SetTexture(data.icon)
                row.icon:Show()
                row.label:SetPoint("LEFT", row, "LEFT", rowH, 0)
            else
                row.icon:Hide()
                row.label:SetPoint("LEFT", row, "LEFT", 12, 0)
            end
            row.label:SetPoint("RIGHT", row, "RIGHT", -12, 0)
            
            
            row.label:SetText(data.enabled == false and (data.label .. " (" .. G("LOCKED", "Locked") .. ")") or data.label)
            if data.color == "red" then
                row.label:SetTextColor(RED[1], RED[2], RED[3])
            elseif data.enabled == false then
                row.label:SetTextColor(0.55, 0.55, 0.55)
            else
                row.label:SetTextColor(1, 1, 1)
            end
            local focused = index == p.row
            if focused then
                row:SetBackdropBorderColor(gold[1], gold[2], gold[3], 1)
            else
                row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            end
            
            
            
            if framed and row.skinRow == nil then
                row.skinRow = FS.Skin.Piece(row, "cmp_menu_row_normal", "BACKGROUND", 1) or false
                if row.skinRow then
                    row.skinRow:Fill(row)
                end
            end
            local piece = framed and row.skinRow or nil
            if piece then
                piece:SetState(RowState(data, focused))
                piece:Show()
                row:SetBackdropBorderColor(focused and gold[1] or 0.3, focused and gold[2] or 0.3, focused and gold[3] or 0.3, 0)
                row:SetBackdropColor(0, 0, 0, 0)
                row.label:ClearAllPoints()
                row.label:SetPoint("LEFT", row, "LEFT", 24, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -24, 0)
            else
                if row.skinRow then
                    row.skinRow:Hide()
                end
                row:SetBackdropColor(0, 0, 0, 0.6)
                row.label:ClearAllPoints()
                row.label:SetPoint("LEFT", row, "LEFT", 12, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -12, 0)
            end
            row:Show()
        else
            row.data, row.index = nil, nil
            row:Hide()
        end
    end
    if framed and sk and sk.bar then
        sk.bar:Update(p.scroll.offset, visible, #p.rows)
    end
end


function A:HidePanel()
    local ui = self.ui
    if not ui then
        return
    end
    ui.text:Hide()
    if ui.block then
        ui.block:Hide()
    end
    for _, row in ipairs(ui.rows) do
        row:Hide()
    end
    FS.UI.halves.plugin.scroll:Show()
end





function A:ShowPanel(spec)
    local p = {
        id = spec.id, title = spec.title, text = spec.text, rows = spec.rows,
        onBack = spec.onBack, scroll = { offset = 0, rows = 1, cols = 1 },
    }
    p.row = spec.row
    if not p.row then
        p.row = 1
        for i, row in ipairs(p.rows) do
            if row.enabled ~= false then
                p.row = i
                break
            end
        end
    end
    self.panel = p
    
    if p.id ~= "bind" then
        self.bind = nil
    end
    self:Sync()
    FS:Refocus()
end


function A:ClosePanel()
    
    
    self.stash = nil
    self.popupSig = nil
    if not self.panel then
        return
    end
    self.panel = nil
    self.menu = nil
    self.picker = nil
    self.bind = nil
    self:HidePanel()
    self:Sync()
    if FS.UI.frame and FS.UI.frame:IsShown() then
        FS:Refocus()
    end
end

function A:PanelMove(delta)
    local p = self.panel
    local row = math.max(1, math.min(#p.rows, p.row + delta))
    if row == p.row then
        return
    end
    p.row = row
    self:Sync()
    FS:Refocus()
    
    local data = p.rows[row]
    if data and data.enabled == false and data.reason then
        FS:Message(data.reason, "bag")
    end
end

function A:PanelBack()
    local p = self.panel
    if p and p.onBack then
        p.onBack()
    else
        self:ClosePanel()
    end
end


function A:PanelRun()
    local p = self.panel
    local row = p.rows[p.row]
    if not row then
        return
    end
    if row.enabled == false then
        if row.reason then
            FS:Message(row.reason, "bag")
        end
        return
    end
    if row.run then
        row.run(row)
    end
end



function A:OnPad(button)
    if not self.panel then
        return false
    end
    if self.panel.id == "bind" and self.bind then
        self:BindPad(button)
        return true
    end
    if button == "PADDUP" then
        self:PanelMove(-1)
    elseif button == "PADDDOWN" then
        self:PanelMove(1)
    elseif button == "PADDLEFT" or button == "PADDRIGHT" then
        local row = self.panel.rows[self.panel.row]
        if row and row.onSide then
            row.onSide(button == "PADDLEFT" and -1 or 1)
        end
    elseif button == "PAD1" then
        self:PanelRun()
    elseif button == "PAD2" then
        self:PanelBack()
    elseif button == "PAD4" and not self.panel.popup then
        
        self:ClosePanel()
    end
    return true
end

























local POPUP_COUNT = 4
local MSG_GAME_BUTTONS = "Answer with the game's own buttons"
A.popupBack = {}


local function Field(obj, key)
    if type(obj) ~= "table" then
        return nil
    end
    local ok, value = pcall(function() return obj[key] end)
    if ok then
        return value
    end
    return nil
end


local function Ask(obj, method)
    local fn = Field(obj, method)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, value = pcall(fn, obj)
    if ok then
        return value
    end
    return nil
end

local function TextOf(region)
    if type(region) ~= "table" then
        return nil
    end
    local text = Ask(region, "GetText")
    if type(text) == "string" and Readable(text) and text ~= "" then
        return text
    end
    return nil
end


local function PopupButton(f, index, n)
    local container = Field(f, "ButtonContainer")
    local list = Field(container, "Buttons")
    return Field(list, n)
        or Field(container, "Button" .. n)
        or Field(f, "button" .. n)
        or Field(f, "Button" .. n)
        or _G["StaticPopup" .. index .. "Button" .. n]
end



function A.ReadPopup(index)
    local name = "StaticPopup" .. index
    local f = _G[name]
    if type(f) ~= "table" or not Ask(f, "IsShown") then
        return nil
    end
    local text = TextOf(Field(f, "Text")) or TextOf(Field(f, "text")) or TextOf(_G[name .. "Text"])
    local popup = { index = index, name = name, frame = f, text = text or "", buttons = {} }
    for n = 1, POPUP_COUNT do
        local button = PopupButton(f, index, n)
        if button and Ask(button, "IsShown") then
            local label = TextOf(button) or TextOf(Field(button, "Text")) or TextOf(_G[name .. "Button" .. n .. "Text"])
            popup.buttons[#popup.buttons + 1] = {
                n = n, button = button, label = label or ("Option " .. n),
                enabled = Ask(button, "IsEnabled") ~= false,
            }
        end
    end
    return popup
end





function A:WatchPopupClick()
    local frame = self.popupWatch
    if not frame then
        frame = CreateFrame("Frame")
        self.popupWatch = frame
        frame:SetScript("OnEvent", function(_, event, addon, func)
            if A.popupWatching and addon == "ThugUI" then
                A.popupWatching = nil
                FS.popupClickBlocked = true
                Log("popup click blocked: %s %s; the pad yields to the popup from now on", tostring(event), tostring(func))
            end
        end)
    end
    self.popupWatchToken = (self.popupWatchToken or 0) + 1
    local token = self.popupWatchToken
    self.popupWatching = true
    local watched = false
    for _, event in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
        if pcall(frame.RegisterEvent, frame, event) then
            watched = true
        end
    end
    if not watched then
        Log("popup click could not be watched (no ADDON_ACTION events)")
    end
    C_Timer.After(1, function()
        if A.popupWatchToken == token then
            A.popupWatching = nil
            pcall(frame.UnregisterEvent, frame, "ADDON_ACTION_BLOCKED")
            pcall(frame.UnregisterEvent, frame, "ADDON_ACTION_FORBIDDEN")
        end
    end)
end


function A:PopupClick(index, entry)
    local name = "StaticPopup" .. index
    local f = _G[name]
    local button = entry.button
    
    if not (f and Ask(f, "IsShown") and Ask(button, "IsShown") and Ask(button, "IsEnabled") ~= false) then
        return
    end
    self:WatchPopupClick()
    local click = Field(button, "Click")
    local ok, err = false, "no Click"
    if type(click) == "function" then
        ok, err = pcall(click, button)
    end
    Log("popup %s button %d clicked", name, entry.n)
    if not ok then
        A.popupWatching = nil
        FS.popupClickBlocked = true
        Log("popup click failed: %s; the pad yields to the popup from now on", tostring(err))
    end
end



function A:PopupBack(index)
    self.popupBack[index] = true
    self.popupSig = nil
    FS:PollPopups(1)
end

local function PopupRows(popup)
    local rows = {}
    for _, entry in ipairs(popup.buttons) do
        rows[#rows + 1] = {
            id = "popup" .. entry.n, label = entry.label, enabled = entry.enabled,
            reason = MSG_GAME_BUTTONS,
            run = function() A:PopupClick(popup.index, entry) end,
        }
    end
    return rows
end



function A:ShowPopupPanel(popup, mode)
    local text = popup.text
    local rows = {}
    if mode == "mirror" then
        rows = PopupRows(popup)
    elseif mode == "glyphs" then
        local lines = { text, "" }
        for _, entry in ipairs(popup.buttons) do
            local glyph = ThugUI.PadHints and ThugUI.PadHints.Glyph and ThugUI.PadHints.Glyph("PAD" .. entry.n) or ("PAD" .. entry.n)
            lines[#lines + 1] = glyph .. "  " .. entry.label
        end
        text = table.concat(lines, "\n")
    elseif mode == "blocked" then
        text = text .. "\n\n" .. MSG_GAME_BUTTONS
    end
    local keep = self.panel and self.panel.popup and self.panel.row or nil
    if self.panel and not self.panel.popup then
        self.stash = self.panel
    end
    local index = popup.index
    self:ShowPanel({
        id = "popup", title = "Game prompt", text = text, rows = rows,
        row = keep and math.max(1, math.min(keep, #rows)) or nil,
        onBack = function() A:PopupBack(index) end,
    })
    self.panel.popup = true
end



function A:EndPopupPanel()
    self.popupSig = nil
    self.popupMode = nil
    if not (self.panel and self.panel.popup) then
        return
    end
    local stash = self.stash
    self.stash = nil
    self.panel = stash
    if not stash then
        self.menu = nil
        self:HidePanel()
    end
    self:Sync()
    if FS.UI.frame and FS.UI.frame:IsShown() then
        FS:Refocus()
        if stash then
            
            self:Validate()
        end
    end
end









function A:PollPopup()
    local first, anyShown
    for i = 1, POPUP_COUNT do
        local f = _G["StaticPopup" .. i]
        if type(f) == "table" and Ask(f, "IsShown") then
            anyShown = true
            if not first and not self.popupBack[i] then
                first = i
            end
        else
            
            
            self.popupBack[i] = nil
        end
    end
    if not anyShown then
        self:EndPopupPanel()
        return false
    end
    local popup = first and A.ReadPopup(first)
    if not popup then
        self:EndPopupPanel()
        return true
    end
    
    
    
    
    
    
    
    
    
    local mode = _G.GamepadPopupHandler and "glyphs" or "mirror"
    if Combat() then
        mode = "combat"
    elseif FS.popupClickBlocked then
        mode = "blocked"
    elseif #popup.buttons == 0 then
        
        
        mode = "nobuttons"
    end
    local parts = { mode, tostring(first), popup.text }
    for _, entry in ipairs(popup.buttons) do
        parts[#parts + 1] = entry.n .. ":" .. entry.label .. ":" .. tostring(entry.enabled)
    end
    local sig = table.concat(parts, "|")
    local shown = self.panel and self.panel.popup
    if sig ~= self.popupSig or not shown then
        if self.popupMode ~= mode or not shown then
            Log("popup %s %s", popup.name, mode == "mirror" and "mirrored" or ("shown as text (" .. mode .. ")"))
        end
        self.popupMode = mode
        self:ShowPopupPanel(popup, mode)
        self.popupSig = sig
    end
    return mode ~= "mirror"
end







local function Capture(item)
    local t = {}
    if item.kind == "equip" then
        local id = GetInventoryItemID and GetInventoryItemID("player", item.slot)
        if not id then
            return nil
        end
        t.equipSlot, t.itemID = item.slot, id
        t.link = GetInventoryItemLink and GetInventoryItemLink("player", item.slot)
    else
        local info = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(item.bag, item.slot)
        if not info or not info.itemID then
            return nil
        end
        t.bag, t.slot, t.itemID = item.bag, item.slot, info.itemID
        t.link = C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(item.bag, item.slot)
    end
    t.name = type(t.link) == "string" and t.link:match("%[(.-)%]") or item.name or "Item"
    return t
end



function A:Recheck()
    local m = self.menu
    if not m then
        return nil
    end
    local t = m.target
    local info, id
    if t.bag then
        info = C_Container.GetContainerItemInfo(t.bag, t.slot)
        id = info and info.itemID
    else
        id = GetInventoryItemID and GetInventoryItemID("player", t.equipSlot)
    end
    if id ~= t.itemID then
        self:ClosePanel()
        FS:Message(MSG_MOVED, "bag")
        return nil
    end
    return info or true
end



function A.LinkToChat(link)
    local inserted = false
    local util = _G.ChatFrameUtil
    if util and type(util.InsertLink) == "function" then
        local ok, result = pcall(util.InsertLink, link)
        inserted = ok and result and true or false
    elseif type(_G.ChatEdit_InsertLink) == "function" then
        local ok, result = pcall(_G.ChatEdit_InsertLink, link)
        inserted = ok and result and true or false
    end
    if inserted then
        return "insert"
    end
    if util and type(util.OpenChat) == "function" then
        pcall(util.OpenChat, link)
        return "open"
    elseif type(_G.ChatFrame_OpenChat) == "function" then
        pcall(_G.ChatFrame_OpenChat, link)
        return "open"
    end
    return nil
end

function A:MenuRows()
    local m = self.menu
    local t = m.target
    local item = m.item
    local rows = {}
    local action = A.MainAction(item)
    if action then
        rows[#rows + 1] = {
            id = "main", label = action.label, enabled = not action.refusal, reason = action.refusal,
            secure = action.kind == "use" or action.kind == "equip", action = action,
            legend = action.label, run = function() A:RunMenuMain(action) end,
        }
    end
    
    if A.IsBag(item) then
        for n = 1, BagSlots() do
            local size, free = BagInfo(n)
            if size > 0 then
                local ok, why = FS.CanPlaceBag(item, n)
                rows[#rows + 1] = {
                    id = "replace" .. n, enabled = ok, reason = why,
                    label = "Replace bag " .. n .. " (" .. size .. " slots, holds " .. ItemsText(size - free) .. ")",
                    legend = "Replace bag " .. n, run = function() A:RunMenuReplace(n) end,
                }
            end
        end
    end
    
    
    local bind = A.BindRow(item, t)
    if bind then
        rows[#rows + 1] = bind
    end
    local info = t.bag and C_Container.GetContainerItemInfo(t.bag, t.slot)
    if info and (info.stackCount or 0) > 1 and not info.isLocked then
        rows[#rows + 1] = {
            id = "split", label = G("CONTEXT_ACTION_LABEL_SPLIT_ITEM_STACK", "Split Stack"),
            run = function() A:PromptSplit() end,
        }
    end
    if type(t.link) == "string" then
        rows[#rows + 1] = { id = "link", label = "Link to chat", run = function() A:RunLink() end }
    end
    if t.bag and FS.CompareSlots(item) then
        rows[#rows + 1] = { id = "compare", label = "Compare", run = function() A:RunCompare() end }
    end
    if t.bag then
        rows[#rows + 1] = {
            id = "destroy", label = G("CONTEXT_ACTION_LABEL_DESTROY_ITEM", "Destroy"), color = "red",
            run = function() A:PromptDestroy() end,
        }
    end
    return rows
end
















local BIND_WATCH_SECONDS = 120






function A.BindRow(item, target)
    if not (IsBagItem(item) and target and target.bag and target.itemID) then
        return nil
    end
    if type(_G.InRepairMode) == "function" and _G.InRepairMode() then
        return nil
    end
    if not IsUsable(item) then
        return nil
    end
    
    
    local reason
    if Combat() then
        reason = MSG_NOT_NOW
    elseif _G.CursorHasItem and _G.CursorHasItem() then
        reason = "Put down what is on your cursor first"
    end
    return {
        id = "bind", label = G("CONTEXT_ACTION_LABEL_BIND_TO_GAMEPAD_ACTION_BAR", "Bind to controller button"),
        enabled = reason == nil, reason = reason, legend = "Bind to controller button",
        run = function() A:RunMenuBind() end,
    }
end





function A:WatchBind()
    local frame = self.bindWatch
    if not frame then
        frame = CreateFrame("Frame")
        self.bindWatch = frame
        frame:SetScript("OnEvent", function(_, event, addon, func)
            if A.bindWatching and addon == "ThugUI" then
                FS.bindTainted = true
                A.bindHit = true
                Log("bind: TAINT %s %s", tostring(event), tostring(func))
            end
        end)
    end
    self.bindWatchToken = (self.bindWatchToken or 0) + 1
    local token = self.bindWatchToken
    self.bindWatching = true
    self.bindHit = nil
    local watched = false
    for _, event in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
        if pcall(frame.RegisterEvent, frame, event) then
            watched = true
        end
    end
    if not watched then
        Log("bind: could not be watched (no ADDON_ACTION events)")
    end
    C_Timer.After(BIND_WATCH_SECONDS, function()
        if A.bindWatchToken == token then
            A.bindWatching = nil
            pcall(frame.UnregisterEvent, frame, "ADDON_ACTION_BLOCKED")
            pcall(frame.UnregisterEvent, frame, "ADDON_ACTION_FORBIDDEN")
            if not A.bindHit then
                Log("bind: clean after 120 s")
            end
        end
    end)
end

local BIND_ACTION_BUTTONS = 8
local BIND_BARS = { none = "topBar", lt = "leftBar", rt = "rightBar", both = "bottomBar" }
local MSG_BIND_KEPT = "That button is kept for the game's own actions. Try another, or hold a trigger."
local MSG_BIND_FAILED = "The game didn't take it there. Try another button."

local function BindGlyph(key)
    local PH = ThugUI.PadHints
    return PH and PH.Glyph and PH.Glyph(key) or key
end



local function BindKeys()
    local keys = {}
    for index = 1, BIND_ACTION_BUTTONS do
        local key = _G.GetBindingKey and _G.GetBindingKey("GAMEPADACTIONBUTTON" .. index, 1)
        if key then
            keys[key] = index
        end
    end
    return keys
end

local function BindKeyList(keys)
    local list = {}
    for key, index in pairs(keys) do
        list[#list + 1] = { key = key, index = index }
    end
    table.sort(list, function(x, y) return x.index < y.index end)
    for i, entry in ipairs(list) do
        list[i] = entry.key .. ":" .. entry.index
    end
    return table.concat(list, ",")
end


local function BindSlot(bar, index)
    local main = _G.GamepadMainActionBarFrame
    local unit = type(main) == "table" and main.PageUnit
    local bars = type(unit) == "table" and unit.actionBars
    local one = type(bars) == "table" and bars[bar]
    local buttons = type(one) == "table" and one.actionButtons
    local button = type(buttons) == "table" and buttons[index]
    if type(button) ~= "table" or type(button.GetID) ~= "function" then
        return nil
    end
    local ok, slot = pcall(button.GetID, button)
    if ok and type(slot) == "number" and slot > 0 then
        return slot
    end
    return nil
end

local function SameList(a, b)
    if #a ~= #b then
        return false
    end
    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end
    return true
end



local function BindPlace(itemID, slot)
    ClearCursorSafe()
    _G.C_Item.PickupItem(itemID)
    local before = { _G.GetCursorInfo() }
    if #before == 0 then
        return false, "nothing on the cursor"
    end
    A:WatchBind()
    _G.PlaceAction(slot)
    local after = { _G.GetCursorInfo() }
    ClearCursorSafe()
    local kind, id = _G.GetActionInfo(slot)
    if (kind == "item" and id == itemID) or not SameList(before, after) then
        return true
    end
    return false, ("slot %s: %s %s"):format(tostring(slot), tostring(kind), tostring(id))
end

function A:BindModifier()
    local held = self.bind and self.bind.held or {}
    if held.PADLTRIGGER and held.PADRTRIGGER then
        return "both"
    end
    return held.PADLTRIGGER and "lt" or (held.PADRTRIGGER and "rt" or "none")
end

function A:BindBarLine()
    local modifier = self:BindModifier()
    local lt, rt = BindGlyph("PADLTRIGGER"), BindGlyph("PADRTRIGGER")
    if modifier == "both" then
        return "Bar: " .. lt .. " + " .. rt
    elseif modifier == "lt" then
        return "Bar: " .. lt
    elseif modifier == "rt" then
        return "Bar: " .. rt
    end
    return "Bar: no trigger held"
end


function A:BindText()
    local state = self.bind
    local text = "Press the button to put it on. Hold " .. BindGlyph("PADLTRIGGER") .. ", "
        .. BindGlyph("PADRTRIGGER") .. " or both for the other bars.\n\n" .. self:BindBarLine()
    if state and state.note then
        text = text .. "\n\n|cffff7366" .. state.note .. "|r"
    end
    return text
end


function A:BindRefresh()
    local p = self.panel
    if not (self.bind and p and p.id == "bind") then
        return
    end
    p.text = self:BindText()
    self:Sync()
    FS:Refocus()
end


local function BindTitle(itemID, fallback)
    local name, quality
    if _G.C_Item and _G.C_Item.GetItemInfo then
        local ok, n, _, q = pcall(_G.C_Item.GetItemInfo, itemID)
        if ok then
            name, quality = n, q
        end
    end
    name = name or fallback or tostring(itemID)
    local color = quality and _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]
    if color and color.r then
        name = ("|cff%02x%02x%02x%s|r"):format(color.r * 255, color.g * 255, color.b * 255, name)
    end
    local icon = _G.C_Item and _G.C_Item.GetItemIconByID and _G.C_Item.GetItemIconByID(itemID)
    if icon then
        name = "|T" .. tostring(icon) .. ":20|t " .. name
    end
    return name
end


function A:OpenBindPicker(target)
    local main = _G.GamepadMainActionBarFrame
    if not (type(main) == "table" and type(main.PageUnit) == "table" and type(main.PageUnit.actionBars) == "table") then
        Log("bind: refused no controller action bars")
        FS:Message("The controller action bars are not available", "bag")
        return
    end
    local keys = BindKeys()
    local held = {}
    
    for _, trigger in ipairs({ "PADLTRIGGER", "PADRTRIGGER" }) do
        if FS.held and FS.held[trigger] then
            held[trigger] = true
        end
    end
    self.bind = { itemID = target.itemID, keys = keys, held = held, name = target.name }
    Log("bind: picker open %s keys=%s", tostring(target.itemID), BindKeyList(keys))
    self:ShowPanel({
        id = "bind", title = BindTitle(target.itemID, target.name), text = self:BindText(),
        rows = {}, row = 1, onBack = function() A:BackToMenu() end,
    })
end


function A:BindPad(button)
    local state = self.bind
    if button == "PADLTRIGGER" or button == "PADRTRIGGER" then
        state.held[button] = true
        self:BindRefresh()
        return
    end
    local index = state.keys[button]
    if not index and button ~= "PAD2" then
        return
    end
    if Combat() then
        Log("bind: refused in combat")
        self:ClosePanel()
        FS:Message(MSG_NOT_NOW, "bag")
        return
    end
    local modifier = self:BindModifier()
    local bar = BIND_BARS[modifier]
    
    
    if button == "PAD2" and not (index and BindSlot(bar, index)) and modifier == "none" then
        self:BackToMenu()
        return
    end
    local slot = index and BindSlot(bar, index)
    Log("bind: press %s bar=%s index=%s slot=%s", button, bar, tostring(index), tostring(slot))
    if not slot then
        Log("bind: refused no slot")
        state.note = MSG_BIND_KEPT
        self:BindRefresh()
        return
    end
    local itemID = state.itemID
    local valid = _G.C_GamepadUI and _G.C_GamepadUI.IsValidGamepadActionStorageSlotIndex
    if valid then
        local okValid, isValid = pcall(valid, slot)
        if okValid and not isValid then
            Log("bind: refused slot %s not valid", tostring(slot))
            state.note = MSG_BIND_FAILED
            self:BindRefresh()
            return
        end
    end
    local ok, placed, why = pcall(BindPlace, itemID, slot)
    if not ok then
        Log("bind: refused error %s", tostring(placed))
        ClearCursorSafe()
        placed = false
    elseif why then
        Log("bind: refused %s", tostring(why))
    end
    if placed then
        Log("bind: placed %s in slot %s", tostring(itemID), tostring(slot))
        local prefix = ""
        if modifier == "lt" or modifier == "both" then
            prefix = prefix .. BindGlyph("PADLTRIGGER") .. " + "
        end
        if modifier == "rt" or modifier == "both" then
            prefix = prefix .. BindGlyph("PADRTRIGGER") .. " + "
        end
        local text = (state.name or tostring(itemID)) .. " is now on " .. prefix .. BindGlyph(button) .. "."
        self:ClosePanel()
        FS:Message(text, "bag")
        print("|cff00ff00ThugUI:|r " .. text)
    else
        state.note = MSG_BIND_FAILED
        self:BindRefresh()
    end
end


function A:OnPadUp(button)
    if not (self.bind and self.panel and self.panel.id == "bind") then
        return
    end
    if (button == "PADLTRIGGER" or button == "PADRTRIGGER") and self.bind.held[button] then
        self.bind.held[button] = nil
        self:BindRefresh()
    end
end


function A:RunMenuBind()
    if Combat() then
        FS:Message(MSG_NOT_NOW, "bag")
        return
    end
    if _G.CursorHasItem and _G.CursorHasItem() then
        FS:Message("Put down what is on your cursor first", "bag")
        return
    end
    if not self:Recheck() then
        return
    end
    self:OpenBindPicker(self.menu.target)
end

function A:RunMenuReplace(n)
    if not self:Recheck() then
        return
    end
    local item = self.menu.item
    self:ClosePanel()
    self:PlaceBag(item, n)
end






function A:PickerRows(n)
    local rows = {}
    for _, item in ipairs(A.LooseBags()) do
        local ok, why = FS.CanPlaceBag(item, n)
        local size = A.LooseBagSize(item)
        local label = item.name or "Bag"
        if size then
            label = label .. ", " .. size .. " slots"
        end
        label = label .. ", " .. A.BagTypeName(A.ItemFamily(item.itemID))
        rows[#rows + 1] = {
            id = "bag", label = label, enabled = ok, reason = why, icon = item.iconFileID,
            legend = "Equip bag", bagItem = item, run = function() A:RunPickerPlace(item, n) end,
        }
    end
    if (BagInfo(n)) > 0 then
        local ok, why = FS.CanRemoveBag(n)
        rows[#rows + 1] = {
            id = "remove", label = "Remove", enabled = ok, reason = why,
            run = function() A:RunPickerRemove(n) end,
        }
    end
    return rows
end

function A:PickerSpec(n)
    local rows = self:PickerRows(n)
    local text
    if #rows == 0 then
        text = "No bags in your bags to put here."
        rows[1] = { id = "back", label = G("FRAME_ACTION_BACK", "Back"), run = function() A:ClosePanel() end }
    end
    return {
        id = "bagpicker", title = "Bag slot " .. n, text = text, rows = rows,
        onBack = function() A:ClosePanel() end,
    }
end




function A:OpenBagPicker(slotItem)
    local n = slotItem.bag
    if n == 0 then
        FS:Message(MSG_BACKPACK, "bag")
        return true
    end
    if type(n) ~= "number" or n > BagSlots() then
        return false
    end
    if Combat() then
        FS:Message(MSG_BAGS_COMBAT, "bag")
        return true
    end
    local busy = A.Busy()
    if busy then
        FS:Message(busy, "bag")
        return true
    end
    self.menu = nil
    self.picker = { n = n }
    self:ShowPanel(self:PickerSpec(n))
    return true
end




function A:RunPickerPlace(item, n)
    self:ClosePanel()
    self:PlaceBag(item, n)
end

function A:RunPickerRemove(n)
    self:ClosePanel()
    self:RemoveBag(n)
end

function A:MenuSpec()
    local m = self.menu
    return {
        id = "menu", title = m.target.name, rows = self:MenuRows(),
        onBack = function() A:ClosePanel() end,
    }
end

function A:OpenMenu()
    local item = FS:Focused()
    if not A.CanMenu(item) then
        return
    end
    if Combat() then
        FS:Message(MSG_NOT_NOW, SideOf(item))
        return
    end
    local busy = A.Busy()
    if busy then
        FS:Message(busy, SideOf(item))
        return
    end
    local target = Capture(item)
    if not target then
        FS:Message(MSG_MOVED, SideOf(item))
        return
    end
    
    FS.pinned = nil
    self.menu = { item = item, target = target }
    self:ShowPanel(self:MenuSpec())
end


function A:BackToMenu()
    if not self.menu then
        return
    end
    self:ShowPanel(self:MenuSpec())
end

function A:RunMenuMain(action)
    local busy = A.Busy()
    if busy then
        FS:Message(busy, "bag")
        return
    end
    if not self:Recheck() then
        return
    end
    local item = self.menu.item
    local done = self:RunAction(action, item)
    if done and self.menu then
        self:ClosePanel()
    end
end

function A:RunLink()
    if not self:Recheck() then
        return
    end
    local link = self.menu.target.link
    local how = A.LinkToChat(link)
    self:ClosePanel()
    FS:Message(how and "Link sent to chat" or MSG_REFUSED, "bag")
end

function A:RunCompare()
    if not self:Recheck() then
        return
    end
    local t = self.menu.target
    FS.pinned = { bag = t.bag, slot = t.slot, itemID = t.itemID, kind = nil, name = t.name }
    self:ClosePanel()
end


function A:PromptSplit()
    local info = self:Recheck()
    if not info or info == true then
        return
    end
    local max = info.stackCount or 1
    if max < 2 then
        return
    end
    local t = self.menu.target
    local amount = math.max(1, math.floor(max / 2))
    local amountRow
    local function Label()
        return "<  " .. amount .. " / " .. max .. "  >"
    end
    amountRow = {
        id = "amount", label = Label(),
        onSide = function(delta)
            amount = math.max(1, math.min(max - 1, amount + delta))
            amountRow.label = Label()
            amountRow.amount = amount
            FS:Refocus()
        end,
        run = function() A:RunSplit(amountRow.amount or amount, max) end,
    }
    amountRow.amount = amount
    self:ShowPanel({
        id = "split", title = t.name, text = "Split stack: choose how many to take",
        rows = { amountRow, { id = "cancel", label = CANCEL or "Cancel", run = function() A:BackToMenu() end } },
        row = 1, onBack = function() A:BackToMenu() end,
    })
end

function A:RunSplit(amount)
    local info = self:Recheck()
    if not info or info == true then
        return
    end
    local t = self.menu.target
    local busy = A.Busy()
    if info.isLocked or busy then
        self:ClosePanel()
        FS:Message(busy or "This item is busy", "bag")
        return
    end
    amount = math.min(amount, (info.stackCount or 1) - 1)
    if amount < 1 then
        self:ClosePanel()
        return
    end
    local ok, err = pcall(C_Container.SplitContainerItem, t.bag, t.slot, amount)
    self:ClosePanel()
    if not ok or (_G.CursorHasItem and not Cursor()) then
        Log("split blocked: %s", tostring(err))
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "bag")
        return
    end
    local bag, slot = A.FreeSlot()
    if not bag then
        ClearCursorSafe()
        FS:Message(MSG_NO_SLOT, "bag")
        return
    end
    local okPut, errPut = pcall(C_Container.PickupContainerItem, bag, slot)
    if not okPut then
        Log("split placement blocked: %s", tostring(errPut))
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "bag")
    end
end




function A:PromptDestroy()
    local info = self:Recheck()
    if not info or info == true then
        return
    end
    local t = self.menu.target
    local count = info.stackCount or 1
    self:ShowPanel({
        id = "destroy", title = t.name,
        text = "Destroy " .. tostring(t.link or t.name) .. " x" .. count .. "? This cannot be undone.",
        rows = {
            { id = "destroy", label = "Destroy", color = "red", run = function() A:RunDestroy() end },
            { id = "cancel", label = CANCEL or "Cancel", run = function() A:BackToMenu() end },
        },
        row = 2, onBack = function() A:BackToMenu() end,
    })
end

function A:RunDestroy()
    local info = self:Recheck()
    if not info or info == true then
        return
    end
    local t = self.menu.target
    local busy = A.Busy()
    self:ClosePanel()
    if busy then
        FS:Message(busy, "bag")
        return
    end
    ClearCursorSafe()
    local ok1, e1 = pcall(C_Container.PickupContainerItem, t.bag, t.slot)
    local ok2, e2 = false, nil
    if ok1 and (not _G.CursorHasItem or Cursor()) then
        ok2, e2 = pcall(_G.DeleteCursorItem)
    end
    
    
    
    if not ok1 or not ok2 or (_G.CursorHasItem and Cursor()) then
        Log("destroy blocked: %s", tostring(e1 or e2))
        ClearCursorSafe()
        FS:Message(MSG_REFUSED, "bag")
    end
end



function A:Validate()
    
    
    local p = self.panel
    if self.picker and p and p.id == "bagpicker" then
        local spec = self:PickerSpec(self.picker.n)
        p.rows, p.text = spec.rows, spec.text
        p.row = math.max(1, math.min(p.row, #p.rows))
        return
    end
    if not self.menu then
        return
    end
    
    
    if self.panel and self.panel.popup then
        return
    end
    if not self:Recheck() then
        return
    end
    if p and p.id == "menu" then
        p.rows = self:MenuRows()
        p.row = math.max(1, math.min(p.row, #p.rows))
    end
end

function A:OnClose()
    self.panel = nil
    self.menu = nil
    self.picker = nil
    self.bind = nil
    self.stash = nil
    self.popupSig = nil
    self.popupMode = nil
    self.popupBack = {}
    self:HidePanel()
    self:EndPass()
    self:Disarm(true)
    self:DisarmTarget()
    self:DisarmStop()
    FS.pinned = nil
    FS.ClearRefusals()
end







function FS.Legend()
    local out = {}
    local function Add(key, label, muted)
        out[#out + 1] = { key = key, label = label, muted = muted }
    end
    local p = A.panel
    if p and p.id == "bind" then
        Add("PAD2", CANCEL or "Cancel")
        return out
    end
    if p then
        local row = p.rows[p.row]
        Add("PAD1", row and row.legend or G("ACTION_LABEL_SELECT", "Select"))
        Add("PAD2", G("FRAME_ACTION_BACK", "Back"))
        return out
    end
    local item = FS:Focused()
    local T = FS.Target
    if T and T.active then
        
        
        
        if type(item) == "table" and item.kind ~= "stat" and item.kind ~= "upkeep" then
            Add("PAD1", G("ACTION_LABEL_SELECT", "Select"))
        end
        if A.TargetOf(item) then
            Add(T.APPLY_KEY, ActionLabel("use"))
        end
        Add(T.CANCEL_KEY, CANCEL or "Cancel")
        return out
    end
    if type(item) == "table" and item.kind ~= "stat" and item.kind ~= "upkeep" then
        Add("PAD1", G("ACTION_LABEL_SELECT", "Select"))
        local action = A.MainAction(item)
        if action then
            Add("PAD3", LockedLabel(action), action.refusal and true or false)
        end
        if A.CanMenu(item) then
            Add("PAD4", G("CONTEXT_ACTION_LABEL_MORE_ACTIONS", "More Actions"))
        end
    end
    Add("PAD2", G("FRAME_ACTION_CLOSE", "Close"))
    return out
end
