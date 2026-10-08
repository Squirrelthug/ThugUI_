














































ThugUI = ThugUI or {}

local P = {}
ThugUI.Profiles = P
P.DEFAULT = "Default"









P.LEGACY_GLOBALS = { "ThugUI_Config", "ThugUIDB" }
function P:EmptyLegacyGlobals()
    for _, name in ipairs(self.LEGACY_GLOBALS) do
        local real = _G[name]
        if type(real) == "table" then
            _G[name] = setmetatable({}, { __index = real, __newindex = real })
        end
    end
end

do
    local logout = CreateFrame("Frame")
    logout:RegisterEvent("PLAYER_LOGOUT")
    logout:SetScript("OnEvent", function() P:EmptyLegacyGlobals() end)
end

function P.CharKey()
    local name = UnitName("player")
    if not name or name == "" then return nil end
    local realm = GetRealmName() or "Unknown"
    return name .. "-" .. realm
end




function P:Store()
    _G.ThugUI_Profiles = _G.ThugUI_Profiles or {}
    local s = _G.ThugUI_Profiles
    if type(s) ~= "table" then
        s = {}
        _G.ThugUI_Profiles = s
    end
    if type(s.profiles) ~= "table" then s.profiles = {} end
    if type(s.chars) ~= "table" then s.chars = {} end
    if type(s.version) ~= "number" then s.version = 1 end
    return s
end


function P:CharStore()
    if type(_G.ThugUI_Character) ~= "table" then
        _G.ThugUI_Character = {}
    end
    return _G.ThugUI_Character
end




local function Assign(self, name)
    self:CharStore().profile = name
    local s = self:Store()
    s.lastActive = name
    local key = self.CharKey()
    if key then s.chars[key] = name end
end


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











function P:LayerFor(scope)
    if scope == "shared" or not scope then return nil end
    local s = self:Store()
    s.layers = s.layers or {}
    s.layers.faction = s.layers.faction or {}
    s.layers.char = s.layers.char or {}
    
    if scope == "faction" then
        if not self.factionAtLoad then return nil end
        s.layers.faction[self.factionAtLoad] = s.layers.faction[self.factionAtLoad] or {}
        return s.layers.faction[self.factionAtLoad]
    elseif scope == "character" then
        if not self.charKeyAtLoad then return nil end
        s.layers.char[self.charKeyAtLoad] = s.layers.char[self.charKeyAtLoad] or {}
        return s.layers.char[self.charKeyAtLoad]
    end
    return nil
end






local RENAMED_KEYS = { OrbAnchors = "Acorns" }
local RENAMED_INNER = { Acorns = { chatOrb = "chat", objectivesOrb = "objectives" } }



local function RenameKey(t, old, new)
    if type(t) ~= "table" or t[old] == nil then return false end
    if t[new] == nil then t[new] = t[old] end
    t[old] = nil
    return true
end



function P:MigrateKeys()
    local count = 0
    for _, profile in pairs(self:Store().profiles) do
        local changed = false
        if type(profile) == "table" then
            for old, new in pairs(RENAMED_KEYS) do
                if RenameKey(profile.db, old, new) then changed = true end
                if RenameKey(profile.scopes, old, new) then changed = true end
            end
            if type(profile.db) == "table" then
                for parent, inner in pairs(RENAMED_INNER) do
                    for old, new in pairs(inner) do
                        if RenameKey(profile.db[parent], old, new) then changed = true end
                    end
                end
            end
        end
        if changed then count = count + 1 end
    end
    return count
end


function P:Bootstrap()
    local s = self:Store()
    local migrated = false

    
    
    
    if s.profiles[self.DEFAULT] == nil then
        s.profiles[self.DEFAULT] = {
            config = _G.ThugUI_Config or {},
            db = _G.ThugUIDB or {},
            scopes = {},
        }
        migrated = true
    end
    
    
    local d = s.profiles[self.DEFAULT]
    self.freshInstall = migrated and next(d.config) == nil and next(d.db) == nil

    
    
    
    self.keysRenamed = self:MigrateKeys()

    
    
    
    local function valid(n) return type(n) == "string" and s.profiles[n] ~= nil end
    local key = self.CharKey()
    self.keyAtLoad = key
    local name = self:CharStore().profile
    if not valid(name) then name = key and s.chars[key] end
    if not valid(name) then name = s.lastActive end
    if not valid(name) then name = self.DEFAULT end

    
    if type(s.profiles[name].config) ~= "table" then s.profiles[name].config = {} end
    if type(s.profiles[name].db) ~= "table" then s.profiles[name].db = {} end
    if type(s.profiles[name].scopes) ~= "table" then s.profiles[name].scopes = {} end
    _G.ThugUI_Config = s.profiles[name].config
    
    local db = s.profiles[name].db
    local scopes = s.profiles[name].scopes or {}

    self.charKeyAtLoad = self.CharKey()
    local factionOK, faction = pcall(UnitFactionGroup, "player")
    if not factionOK or faction == "Neutral" then faction = nil end
    self.factionAtLoad = faction

    local live = {}
    for k, v in pairs(db) do
        rawset(live, k, v)
    end
    
    self.unresolved = {}
    self.liveScopes = {}
    
    for k, scope in pairs(scopes) do
        local bucket = self:LayerFor(scope)
        if bucket == nil then
            table.insert(self.unresolved, k)
            if ThugUI.Diagnostics and type(ThugUI.Diagnostics.Log) == "function" then
                ThugUI.Diagnostics:Log("PROFILES", "scope %s for %s unresolved at load, using shared", tostring(scope), tostring(k))
            end
        else
            if bucket[k] == nil then
                bucket[k] = DeepCopy(db[k] or {})
            end
            rawset(live, k, bucket[k])
            self.liveScopes[k] = scope
        end
    end
    
    setmetatable(live, {
        __index = db,
        __newindex = function(t, k, v)
            rawset(t, k, v)
            local scope = self.liveScopes[k]
            if scope then
                local bucket = self:LayerFor(scope)
                if bucket then
                    bucket[k] = v
                end
            else
                db[k] = v
            end
        end
    })
    
    _G.ThugUIDB = live
    self.live = live

    
    
    
    self.active = name
    self.migrated = migrated
    self:CharStore().profile = name

    
    
    
    
    
    if not self.loginFrame then
        self.loginFrame = CreateFrame("Frame")
        self.loginFrame:RegisterEvent("PLAYER_LOGIN")
        self.loginFrame:SetScript("OnEvent", function(f)
            f:UnregisterEvent("PLAYER_LOGIN")
            P:OnLogin()
        end)
    end
end



function P:OnLogin()
    local key = self.CharKey()
    local s = self:Store()
    if ThugUI.Diagnostics and type(ThugUI.Diagnostics.Log) == "function" then
        ThugUI.Diagnostics:Log("PROFILES", "loaded %q; name at ADDON_LOADED=%s, at login=%s; map=%s; migrated=%s",
            tostring(self.active), tostring(self.keyAtLoad), tostring(key),
            tostring(key and s.chars[key]), tostring(self.migrated))
        if (self.keysRenamed or 0) > 0 then
            ThugUI.Diagnostics:Log("PROFILES", "renamed keys in %d profile(s)", self.keysRenamed)
        end
    end
    if not key then return end
    
    local factionOK, faction = pcall(UnitFactionGroup, "player")
    if not factionOK or faction == "Neutral" then faction = nil end

    if self.unresolved and #self.unresolved > 0 then
        local needReload = false
        local activeScopes = s.profiles[self.active] and s.profiles[self.active].scopes or {}
        for _, k in ipairs(self.unresolved) do
            local scope = activeScopes[k]
            if (scope == "character" and key) or (scope == "faction" and faction) then
                needReload = true
                break
            end
        end
        if needReload then
            if ThugUI.Diagnostics and type(ThugUI.Diagnostics.Log) == "function" then
                ThugUI.Diagnostics:Log("PROFILES", "Identity resolved at login, reloading for scoped keys")
            end
            self:PromptReload(self.active)
            return
        end
    end

    
    
    
    local wanted = s.chars[key]
    if type(wanted) == "string" and wanted ~= self.active and s.profiles[wanted] then
        Assign(self, wanted)
        self:PromptReload(wanted)
        return
    end
    Assign(self, self.active)
end

function P:ScopeOf(key)
    if not self.active then return "shared" end
    local p = self:Store().profiles[self.active]
    if p and p.scopes and p.scopes[key] then
        return p.scopes[key]
    end
    return "shared"
end

function P:SetScope(key, scope, mode)
    if not self.active then return false, "unknown" end
    local p = self:Store().profiles[self.active]
    if not p then return false, "unknown" end
    p.scopes = p.scopes or {}
    local currentScope = p.scopes[key] or "shared"
    if currentScope == scope then return false, "same" end
    
    if scope == "faction" or scope == "character" then
        local bucket = self:LayerFor(scope)
        if not bucket then return false, "unresolved" end
        if bucket[key] == nil then
            bucket[key] = DeepCopy(_G.ThugUIDB[key] or {})
        end
        p.scopes[key] = scope
    elseif scope == "shared" then
        if mode == "discard" then
            local oldBucket = self:LayerFor(currentScope)
            if oldBucket then
                oldBucket[key] = nil
            end
        elseif mode == "promote" then
            p.db[key] = p.db[key] or {}
            wipe(p.db[key])
            local copy = DeepCopy(_G.ThugUIDB[key] or {})
            for k, v in pairs(copy) do p.db[key][k] = v end
            local oldBucket = self:LayerFor(currentScope)
            if oldBucket then
                oldBucket[key] = nil
            end
        end
        p.scopes[key] = nil
    else
        return false, "invalid scope"
    end
    
    self:PromptReload(self.active)
    return true
end

function P:ScopeLabel(scope)
    if scope == "faction" then
        return "This faction (" .. (self.factionAtLoad or "?") .. ")"
    elseif scope == "character" then
        return "This character"
    end
    return "Shared (all characters)"
end

function P:ScopedKeysHere()
    local list = {}
    for k, scope in pairs(self.liveScopes or {}) do
        table.insert(list, k .. " (" .. scope .. ")")
    end
    table.sort(list)
    return list
end


function P:List()
    local s = self:Store()
    local list = {}
    for name in pairs(s.profiles) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end



function P:Assigned()
    local name = self:CharStore().profile
    if type(name) ~= "string" or self:Store().profiles[name] == nil then
        return self.DEFAULT
    end
    return name
end




function P:Create(name, fromName)
    if not name or name:match("^%s*$") then
        return false, "empty"
    end
    local s = self:Store()
    if s.profiles[name] ~= nil then
        return false, "exists"
    end
    if fromName ~= nil and s.profiles[fromName] == nil then
        return false, "unknown"
    end

    if fromName ~= nil then
        local src = s.profiles[fromName]
        s.profiles[name] = {
            config = DeepCopy(src.config),
            db = DeepCopy(src.db),
            scopes = DeepCopy(src.scopes or {}),
        }
    else
        s.profiles[name] = {
            config = {},
            db = {},
            scopes = {},
        }
    end
    return true
end


function P:Delete(name)
    if name == self.DEFAULT then
        return false, "default"
    end
    if name == self.active then
        return false, "active"
    end
    local s = self:Store()
    if s.profiles[name] == nil then
        return false, "unknown"
    end

    s.profiles[name] = nil
    for ck, pv in pairs(s.chars) do
        if pv == name then
            s.chars[ck] = self.DEFAULT
        end
    end
    
    
    if self:CharStore().profile == name then
        self:CharStore().profile = self.DEFAULT
    end
    if s.lastActive == name then s.lastActive = self.DEFAULT end
    return true
end


function P:Rename(old, new)
    if old == self.DEFAULT then
        return false, "default"
    end
    local s = self:Store()
    if s.profiles[old] == nil then
        return false, "unknown"
    end
    if not new or new:match("^%s*$") then
        return false, "empty"
    end
    if s.profiles[new] ~= nil then
        return false, "exists"
    end

    s.profiles[new] = s.profiles[old]
    s.profiles[old] = nil

    for ck, pv in pairs(s.chars) do
        if pv == old then
            s.chars[ck] = new
        end
    end
    if self:CharStore().profile == old then
        self:CharStore().profile = new
    end
    if s.lastActive == old then s.lastActive = new end

    if self.active == old then
        self.active = new
    end

    return true
end




function P:CopyInto(targetName, sourceName)
    if targetName == sourceName then
        return false, "same"
    end
    local s = self:Store()
    local target = s.profiles[targetName]
    local source = s.profiles[sourceName]
    if not target or not source then
        return false, "unknown"
    end

    wipe(target.config)
    wipe(target.db)
    target.scopes = target.scopes or {}
    wipe(target.scopes)

    local copiedConfig = DeepCopy(source.config)
    local copiedDB = DeepCopy(source.db)
    local copiedScopes = DeepCopy(source.scopes or {})
    for k, v in pairs(copiedConfig) do target.config[k] = v end
    for k, v in pairs(copiedDB) do target.db[k] = v end
    for k, v in pairs(copiedScopes) do target.scopes[k] = v end

    if targetName == self.active then
        self:PromptReload(targetName)
    end
    return true
end



function P:Reset(name)
    local s = self:Store()
    local p = s.profiles[name]
    if not p then
        return false, "unknown"
    end

    wipe(p.config)
    wipe(p.db)

    if name == self.active then
        self:PromptReload(name)
    end
    return true
end



function P:Switch(name)
    local s = self:Store()
    if s.profiles[name] == nil then
        return false, "unknown"
    end

    Assign(self, name)
    self:PromptReload(name)
    return true
end

local regenFrame




function P:PromptReload(name)
    if InCombatLockdown and InCombatLockdown() then
        if not regenFrame then
            regenFrame = CreateFrame("Frame")
        end
        regenFrame.pendingProfile = name
        regenFrame:SetScript("OnEvent", function(f, event)
            if event == "PLAYER_REGEN_ENABLED" then
                f:UnregisterEvent("PLAYER_REGEN_ENABLED")
                if f.pendingProfile then
                    StaticPopup_Show("THUGUI_PROFILE_RELOAD", f.pendingProfile)
                    f.pendingProfile = nil
                end
            end
        end)
        regenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        StaticPopup_Show("THUGUI_PROFILE_RELOAD", name)
    end
end






StaticPopupDialogs["THUGUI_PROFILE_RELOAD"] = {
    text = "ThugUI: this character now uses the profile |cffffd100%s|r. Reload the UI to apply it?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

return P
