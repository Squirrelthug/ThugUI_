






local ThugUI = _G.ThugUI
local UF = {}
ThugUI.UnitFrames = UF

UF.TABLES = { "Orbs", "ResourcePips", "ControllerTarget", "Visibility", "PartyFrames" }
UF.base = {}
UF.reset = {}

local NIL_SENTINEL = "\0nil"

local function DeepCopy(orig, copies)
    copies = copies or {}
    if type(orig) ~= "table" then return orig end
    if copies[orig] then return copies[orig] end
    local copy = {}
    copies[orig] = copy
    for k, v in pairs(orig) do
        copy[DeepCopy(k, copies)] = DeepCopy(v, copies)
    end
    return copy
end
UF.DeepCopy = DeepCopy

local function IsArray(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for k in pairs(t) do
        count = count + 1
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
            return false
        end
    end
    return count == #t
end

local function DeepEqual(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do
        if not DeepEqual(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function Merge(dst, diff)
    if type(diff) ~= "table" then return diff end
    dst = type(dst) == "table" and dst or {}
    for k, v in pairs(diff) do
        if v == NIL_SENTINEL then
            dst[k] = nil
        elseif type(v) == "table" then
            dst[k] = Merge(dst[k], v)
        else
            dst[k] = v
        end
    end
    return dst
end
UF.Merge = Merge

local function Diff(cur, base)
    if cur == nil and base == nil then return nil end
    if cur == nil then return NIL_SENTINEL end
    if base == nil then return DeepCopy(cur) end
    if type(cur) ~= "table" or type(base) ~= "table" then
        if cur == base then return nil else return cur end
    end

    if IsArray(cur) and IsArray(base) then
        if DeepEqual(cur, base) then
            return nil
        else
            return DeepCopy(cur)
        end
    end

    local diff = nil
    for k, v in pairs(cur) do
        if base[k] == nil then
            diff = diff or {}
            diff[k] = DeepCopy(v)
        elseif type(v) == "table" and type(base[k]) == "table" then
            if IsArray(v) and IsArray(base[k]) then
                if not DeepEqual(v, base[k]) then
                    diff = diff or {}
                    diff[k] = DeepCopy(v)
                end
            else
                local sub = Diff(v, base[k])
                if sub ~= nil then
                    diff = diff or {}
                    diff[k] = sub
                end
            end
        elseif v ~= base[k] then
            diff = diff or {}
            diff[k] = v
        end
    end
    for k in pairs(base) do
        if cur[k] == nil then
            diff = diff or {}
            diff[k] = NIL_SENTINEL
        end
    end
    return diff
end
UF.Diff = Diff

local function CountLeaves(t)
    if type(t) ~= "table" then return 1 end
    if IsArray(t) then return 1 end
    local count = 0
    for k, v in pairs(t) do
        if type(v) == "table" and not IsArray(v) then
            count = count + CountLeaves(v)
        else
            count = count + 1
        end
    end
    return count
end

function UF:IsMouseLayer()
    return ThugUI.unitFramesMouse == true
end

function UF:Active()
    if ThugUI.unitFramesMouse then
        return true
    end
    
    
    local M = ThugUI.Modules
    if M and not M:ForClient(M:Entry("controller")) then
        return true
    end
    if ThugUI:IsModuleOn("controller") and ThugUI.ControllerMode and ThugUI.ControllerMode.IsActive then
        local ok, active = pcall(ThugUI.ControllerMode.IsActive, ThugUI.ControllerMode)
        if ok and active then
            return true
        end
    end
    return false
end

function UF:OnLogout()
    if not ThugUI.unitFramesMouse then return end
    ThugUIDB.UnitFramesMouse = ThugUIDB.UnitFramesMouse or {}
    for _, name in ipairs(UF.TABLES) do
        if UF.reset[name] then
            ThugUIDB.UnitFramesMouse[name] = nil
        elseif UF.base[name] and ThugUIDB[name] then
            ThugUIDB.UnitFramesMouse[name] = Diff(ThugUIDB[name], UF.base[name])
        end
        
        
        
        if UF.base[name] then ThugUIDB[name] = UF.base[name] end
    end
    if next(ThugUIDB.UnitFramesMouse) == nil then
        ThugUIDB.UnitFramesMouse = nil
    end
end

function UF:ApplyLayer()
    if not ThugUI.unitFramesMouse then
        if self.logoutFrame then
            self.logoutFrame:UnregisterEvent("PLAYER_LOGOUT")
        end
        self.logoutRegistered = false
        if not self.loggedController then
            self.loggedController = true
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("UNITFRAMES", "controller layer (base)")
            end
        end
        return
    end

    UF.base = UF.base or {}
    ThugUIDB.UnitFramesMouse = ThugUIDB.UnitFramesMouse or {}

    local leafCount = 0
    for _, name in ipairs(UF.TABLES) do
        if UF.base[name] == nil then
            UF.base[name] = ThugUIDB[name]
        end
        local mouseDiff = ThugUIDB.UnitFramesMouse[name]
        ThugUIDB[name] = Merge(DeepCopy(UF.base[name] or {}), mouseDiff or {})
        if mouseDiff then
            leafCount = leafCount + CountLeaves(mouseDiff)
        end
    end

    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("UNITFRAMES", string.format("mouse layer, %d differences", leafCount))
    end

    if not self.logoutFrame then
        self.logoutFrame = CreateFrame("Frame")
        self.logoutFrame:SetScript("OnEvent", function()
            UF:OnLogout()
        end)
    end
    self.logoutFrame:RegisterEvent("PLAYER_LOGOUT")
    self.logoutRegistered = true
end

function UF:Reset(name)
    if ThugUIDB and ThugUIDB.UnitFramesMouse then
        ThugUIDB.UnitFramesMouse[name] = nil
    end
    UF.reset[name] = true
    ThugUI.Dialog:Show("THUGUI_UNITFRAMES_RELOAD")
end

ThugUI.Dialogs["THUGUI_UNITFRAMES_RELOAD"] = {
    text = "ThugUI: reload to put these frames back to the controller setup?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
