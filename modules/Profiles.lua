


























































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












local function Layers(profile)
    if type(profile.layers) ~= "table" then profile.layers = {} end
    local l = profile.layers
    if type(l.faction) ~= "table" then l.faction = {} end
    if type(l.char) ~= "table" then l.char = {} end
    return l
end
P.Layers = Layers



function P:LayerFor(scope, name)
    if scope == "shared" or not scope then return nil end
    local profile = self:Store().profiles[name or self.active]
    if type(profile) ~= "table" then return nil end
    local l = Layers(profile)
    if scope == "faction" then
        if not self.factionAtLoad then return nil end
        l.faction[self.factionAtLoad] = l.faction[self.factionAtLoad] or {}
        return l.faction[self.factionAtLoad]
    elseif scope == "character" then
        if not self.charKeyAtLoad then return nil end
        l.char[self.charKeyAtLoad] = l.char[self.charKeyAtLoad] or {}
        return l.char[self.charKeyAtLoad]
    end
    return nil
end





function P:MoveLegacyLayers()
    local s = self:Store()
    local old = s.layers
    if type(old) ~= "table" then return false end
    for _, profile in pairs(s.profiles) do
        if type(profile) == "table" then
            local l = Layers(profile)
            for _, group in ipairs({ "faction", "char" }) do
                for who, bucket in pairs(type(old[group]) == "table" and old[group] or {}) do
                    if type(bucket) == "table" then
                        l[group][who] = l[group][who] or {}
                        for k, v in pairs(bucket) do
                            if l[group][who][k] == nil then l[group][who][k] = DeepCopy(v) end
                        end
                    end
                end
            end
        end
    end
    s.layers = nil
    return true
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
            local tables = { profile.db }
            if type(profile.layers) == "table" then
                for _, group in pairs(profile.layers) do
                    for _, bucket in pairs(type(group) == "table" and group or {}) do
                        if type(bucket) == "table" then
                            tables[#tables + 1] = bucket
                            for old, new in pairs(RENAMED_KEYS) do
                                if RenameKey(bucket, old, new) then changed = true end
                            end
                        end
                    end
                end
            end
            for _, t in ipairs(tables) do
                if type(t) == "table" then
                    for parent, inner in pairs(RENAMED_INNER) do
                        for old, new in pairs(inner) do
                            if RenameKey(t[parent], old, new) then changed = true end
                        end
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
    
    
    
    if self.freshInstall and d.scopes.Orbs == nil then d.scopes.Orbs = "faction" end

    
    
    self.layersMoved = self:MoveLegacyLayers()

    
    
    
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
    
    self.active = name

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
                bucket[k] = {}
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
            bucket[key] = {}
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
    
    
    return true
end









local function HereID(self, key)
    local here = self:ScopeOf(key)
    if here == "faction" then return "faction:" .. tostring(self.factionAtLoad) end
    if here == "character" then return "char:" .. tostring(self.charKeyAtLoad) end
    return "shared"
end

local function SourceTable(self, key, id)
    local s = self:Store()
    if id == "shared" then
        local p = s.profiles[self.active]
        return p and p.db and p.db[key] or {}
    end
    local profile = s.profiles[self.active]
    local layers = profile and Layers(profile) or {}
    local f = id:match("^faction:(.+)$")
    if f then return layers.faction and layers.faction[f] and layers.faction[f][key] end
    local ck = id:match("^char:(.+)$")
    if ck then return layers.char and layers.char[ck] and layers.char[ck][key] end
    return nil
end



function P:CopySources(key)
    local list = {}
    if not self.active then return list end
    local hereID = HereID(self, key)
    local function Add(id, text)
        if id ~= hereID then list[#list + 1] = { value = id, text = text } end
    end
    Add("shared", "Shared (all characters)")
    local profile = self:Store().profiles[self.active]
    local layers = profile and Layers(profile) or {}
    for _, group in ipairs({ { "faction", "Faction: " }, { "char", "" } }) do
        local names = {}
        for name, bucket in pairs(layers[group[1] ] or {}) do
            if type(bucket) == "table" and bucket[key] ~= nil then names[#names + 1] = name end
        end
        table.sort(names)
        for _, name in ipairs(names) do Add(group[1] .. ":" .. name, group[2] .. name) end
    end
    return list
end



function P:CopyFrom(key, id)
    if not self.active then return false, "unknown" end
    if id == HereID(self, key) then return false, "same" end
    local src = SourceTable(self, key, id)
    if type(src) ~= "table" then return false, "empty" end
    local here = self:ScopeOf(key)
    local dest
    if here == "shared" then
        local p = self:Store().profiles[self.active]
        p.db = p.db or {}
        p.db[key] = p.db[key] or {}
        dest = p.db[key]
    else
        local bucket = self:LayerFor(here)
        if not bucket then return false, "unresolved" end
        bucket[key] = bucket[key] or {}
        dest = bucket[key]
    end
    local copy = DeepCopy(src)
    wipe(dest)
    for k, v in pairs(copy) do dest[k] = v end
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
            layers = DeepCopy(src.layers or {}),
        }
    else
        s.profiles[name] = {
            config = {},
            db = {},
            scopes = {},
            layers = {},
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
    local copiedLayers = DeepCopy(source.layers or {})
    for k, v in pairs(copiedConfig) do target.config[k] = v end
    for k, v in pairs(copiedDB) do target.db[k] = v end
    for k, v in pairs(copiedScopes) do target.scopes[k] = v end
    target.layers = target.layers or {}
    wipe(target.layers)
    for k, v in pairs(copiedLayers) do target.layers[k] = v end

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
    
    
    if type(p.layers) == "table" then wipe(p.layers) end

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




function P:SwitchAndReload(name)
    if self:Store().profiles[name] == nil then return false, "unknown" end
    Assign(self, name)
    if InCombatLockdown and InCombatLockdown() then
        self:PromptReload(name)
    else
        ReloadUI()
    end
    return true
end

local regenFrame




local function ShowReloadPopup(which, arg)
    if InCombatLockdown and InCombatLockdown() then
        if not regenFrame then
            regenFrame = CreateFrame("Frame")
        end
        regenFrame.pendingWhich, regenFrame.pendingProfile = which, arg
        regenFrame:SetScript("OnEvent", function(f, event)
            if event == "PLAYER_REGEN_ENABLED" then
                f:UnregisterEvent("PLAYER_REGEN_ENABLED")
                if f.pendingProfile then
                    ThugUI.Dialog:Show(f.pendingWhich or "THUGUI_PROFILE_RELOAD", f.pendingProfile)
                    f.pendingProfile, f.pendingWhich = nil, nil
                end
            end
        end)
        regenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        ThugUI.Dialog:Show(which, arg)
    end
end


function P:PromptReload(name)
    ShowReloadPopup("THUGUI_PROFILE_RELOAD", name)
end










function P:ScopeButtonName(scope)
    
    
    if scope == "faction" then return "Faction" end
    if scope == "character" then return "Character" end
    return "Shared"
end

local GOLD = "|cffffd100%s|r"
local function Gold(s) return GOLD:format(tostring(s)) end


function P:PromptScopeReload(pageTitle, scope)
    ShowReloadPopup("THUGUI_SCOPE_RELOAD", ("%s now uses its %s settings in profile %s. Reload the UI to apply it?")
        :format(Gold(pageTitle or "This page"), Gold(self:ScopeButtonName(scope)), Gold(self.active or "?")))
end


function P:PromptCopyReload(pageTitle, sourceText, scope)
    ShowReloadPopup("THUGUI_SCOPE_RELOAD", ("Copied %s into the %s settings of %s (profile %s). Reload the UI to apply it?")
        :format(Gold(sourceText or "the settings"), Gold(self:ScopeButtonName(scope)),
            Gold(pageTitle or "this page"), Gold(self.active or "?")))
end






ThugUI.Dialogs["THUGUI_SCOPE_RELOAD"] = {
    text = "%s",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

ThugUI.Dialogs["THUGUI_PROFILE_RELOAD"] = {
    text = "ThugUI: this character now uses the profile |cffffd100%s|r. Reload the UI to apply it?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}



























P.SHARE_TAG = "THUG"

P.CLIENT_LETTER = { retail = "R", forever = "F" }
local LETTER_CLIENT = { R = "retail", F = "forever" }

function P.ShareTag()
    return P.SHARE_TAG .. P.Major() .. (P.CLIENT_LETTER[ThugUI.client] or "R")
end

function P.Major()
    return tonumber(tostring(ThugUI.version or "2"):match("^(%d+)")) or 2
end

local function Encoding()
    local E = _G.C_EncodingUtil
    if not (E and E.SerializeCBOR and E.DeserializeCBOR and E.CompressString
        and E.DecompressString and E.EncodeBase64 and E.DecodeBase64) then
        return nil
    end
    return E
end



local function PlainCopy(v, seen)
    local t = type(v)
    if t == "string" or t == "number" or t == "boolean" then return v end
    if t ~= "table" then return nil end
    seen = seen or {}
    if seen[v] then return nil end
    seen[v] = true
    local out = {}
    for k, vv in pairs(v) do
        local kt = type(k)
        if kt == "string" or kt == "number" then
            local c = PlainCopy(vv, seen)
            if c ~= nil then out[k] = c end
        end
    end
    seen[v] = nil
    return out
end
P.PlainCopy = PlainCopy


function P:Export()
    local E = Encoding()
    if not E then return nil, "unsupported" end
    local s = self:Store().profiles[self.active]
    local db = {}
    for k, v in pairs(_G.ThugUIDB or {}) do
        if type(k) == "string" then db[k] = PlainCopy(v) end
    end
    local payload = {
        app = "ThugUI",
        major = P.Major(),
        version = tostring(ThugUI.version or ""),
        
        
        
        
        client = ThugUI.client,
        name = self.active,
        config = PlainCopy(_G.ThugUI_Config or {}),
        db = db,
        
        
        
        scopes = PlainCopy((s and s.scopes) or {}),
    }
    local ok, out = pcall(function()
        return E.EncodeBase64(E.CompressString(E.SerializeCBOR(payload)))
    end)
    if not ok or type(out) ~= "string" then return nil, "encode" end
    return P.ShareTag() .. ":" .. out
end



function P:DecodeShare(text)
    if type(text) ~= "string" then return nil, "empty" end
    text = text:gsub("%s", "")
    if text == "" then return nil, "empty" end
    local major, letter, body = text:match("^" .. P.SHARE_TAG .. "(%d+)([RF]):(.+)$")
    if not major then return nil, "notours" end
    major = tonumber(major)
    if major ~= P.Major() then return nil, "major", major end
    
    if LETTER_CLIENT[letter] ~= ThugUI.client then return nil, "client", LETTER_CLIENT[letter] end
    local E = Encoding()
    if not E then return nil, "unsupported" end
    local ok, payload = pcall(function()
        return E.DeserializeCBOR(E.DecompressString(E.DecodeBase64(body)))
    end)
    if not ok or type(payload) ~= "table" then return nil, "corrupt" end
    if payload.app ~= "ThugUI" or type(payload.config) ~= "table" or type(payload.db) ~= "table" then
        return nil, "corrupt"
    end
    if payload.client ~= ThugUI.client then return nil, "client", payload.client end
    return payload
end



function P:Import(text, name)
    local payload, reason, major = self:DecodeShare(text)
    if not payload then return nil, reason, major end
    local s = self:Store()
    local base = (type(name) == "string" and not name:match("^%s*$")) and name
        or ((type(payload.name) == "string" and payload.name ~= "" and payload.name or "Shared") .. " (imported)")
    local final, n = base, 2
    while s.profiles[final] ~= nil do
        final = base .. " " .. n
        n = n + 1
    end
    local profile = { config = PlainCopy(payload.config), db = PlainCopy(payload.db), scopes = {}, layers = {} }
    
    
    if type(payload.scopes) == "table" then
        for k, scope in pairs(payload.scopes) do
            if type(k) == "string" and (scope == "faction" or scope == "character") then
                profile.scopes[k] = scope
            end
        end
    end
    s.profiles[final] = profile
    for k, scope in pairs(profile.scopes) do
        local bucket = self:LayerFor(scope, final)
        if bucket and type(profile.db[k]) == "table" then bucket[k] = DeepCopy(profile.db[k]) end
    end
    return final
end

P.SHARE_REASONS = {
    empty = "Paste a ThugUI profile string first.",
    notours = "That is not a ThugUI profile string (they start with THUG, a number and R or F, like THUG2R:).",
    unsupported = "This game client cannot read profile strings (C_EncodingUtil is missing).",
    corrupt = "The string is damaged or incomplete. Copy it again in full.",
    encode = "The profile could not be turned into a string.",
}
local CLIENT_NAME = { retail = "retail (the main game)", forever = "WoW Forever" }
P.CLIENT_NAME = CLIENT_NAME

function P:ShareReasonText(reason, major)
    if reason == "client" then
        return ("That string was made on %s, and this is %s. Profiles only move between the same game.")
            :format(CLIENT_NAME[major] or "another game", CLIENT_NAME[ThugUI.client] or tostring(ThugUI.client))
    end
    if reason == "major" then
        return ("That string was made with ThugUI %d.x and this is ThugUI %d.x. Settings move between "
            .. "versions with the same first number only."):format(major or 0, P.Major())
    end
    return P.SHARE_REASONS[reason] or tostring(reason)
end

return P
