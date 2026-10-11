






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







function UF:OnLogout() end

function UF:ApplyLayer()
    if self.logged then return end
    self.logged = true
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("UNITFRAMES", ThugUI.unitFramesMouse and "mouse copy" or "controller copy (or retail)")
    end
end



function UF:Reset(name)
    local P = ThugUI.Profiles
    local live = ThugUIDB and ThugUIDB[name]
    if P and type(live) == "table" and not (P.liveModes and P.liveModes[name]) then
        local p = P:Store().profiles[P.active]
        local scope = P.liveScopes and P.liveScopes[name]
        local bucket = scope and P:LayerFor(scope) or (p and p.db)
        local src = bucket and bucket[name .. P.PAD_SUFFIX]
        if type(src) == "table" then
            local copy = DeepCopy(src)
            wipe(live)
            for k, v in pairs(copy) do live[k] = v end
        end
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
