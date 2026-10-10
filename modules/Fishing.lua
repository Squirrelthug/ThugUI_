











local ThugUI = _G.ThugUI
local F = CreateFrame("Frame")
ThugUI.Fishing = F
ThugUI:RegisterModule("Fishing", F)

ThugUI.defaults.Fishing = {
    smartCast = true,
    applyLures = true,
    gearButton = true,
    enhanceSounds = false,
    soundScale = 1,
    
    doubleClick = false,
    doubleClickButton = "RightButton",  
    doubleKey = nil,                    
    doubleWindow = 0.4,                 
    doubleNeedsPole = true,
}

local MAIN = INVSLOT_MAINHAND or 16
local WEAPON_CLASS = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
local FISHING_POLE = Enum and Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole or 20

local MACRO_NAME = "ThugFish"















local LURES = {
    118391, 68049, 46006, 34861, 6533, 62673, 7307, 6532, 6530, 6811, 6529, 67404
}



local FISHING_SPELL_IDS = {
    [131474] = true, [131476] = true, [131490] = true, [7620] = true,
    [110410] = true, [158743] = true, [377895] = true, [1224771] = true
}

local function IsFishingChannel()
    if not UnitChannelInfo then return false end
    local name, _, _, _, _, _, _, spellID = UnitChannelInfo("player")
    if issecretvalue and (issecretvalue(spellID) or issecretvalue(name)) then return false end
    if spellID and FISHING_SPELL_IDS[spellID] then return true end
    local fName = _G.C_Spell and _G.C_Spell.GetSpellName and _G.C_Spell.GetSpellName(7620)
    if not (issecretvalue and issecretvalue(fName)) and fName and fName == name then return true end
    return false
end

function F.IsPole(item)
    if not item or not (C_Item and C_Item.GetItemInfoInstant) then return false end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(item)
    return classID == WEAPON_CLASS and subclassID == FISHING_POLE
end

function F.PoleEquipped()
    return F.IsPole(GetInventoryItemID("player", MAIN))
end

function F.BestLure()
    if not C_Item or not C_Item.GetItemCount then return nil end
    for _, id in ipairs(LURES) do
        if C_Item.GetItemCount(id) > 0 then
            return id
        end
    end
    return nil
end

function F.PoleHasLure()
    if not GetWeaponEnchantInfo then return true end
    local hasMainHandEnchant = GetWeaponEnchantInfo()
    if issecretvalue and issecretvalue(hasMainHandEnchant) then
        return true
    end
    return hasMainHandEnchant
end

function F:DesiredBody()
    local cfg = ThugUIDB.Fishing
    if cfg.smartCast and cfg.applyLures and F.PoleEquipped() and not F.PoleHasLure() then
        local lureID = F.BestLure()
        if lureID then
            return "#showtooltip item:" .. lureID .. "\n/use item:" .. lureID .. "\n/use 16"
        end
    end
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(7620)
    if not name then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("FISHING_SPELL_NAME", "FISHING", "Could not resolve spell 7620")
        end
        return ""
    end
    return "#showtooltip\n/cast " .. name
end




local timerGeneration = 0

function F:Update()
    if InCombatLockdown and InCombatLockdown() then
        self.pending = true
        return
    end

    local desired = self:DesiredBody()
    if desired == "" then return end
    
    F:ArmCastButtons(desired)

    if not GetMacroIndexByName or not GetMacroBody then return end
    local index = GetMacroIndexByName(MACRO_NAME)
    if not index or index == 0 then return end

    local current = GetMacroBody(index)
    if current ~= desired then
        if EditMacro then
            EditMacro(index, nil, nil, desired)
            if ThugUI.Diagnostics then
                if desired:find("/use item:") then
                    local id = desired:match("/use item:(%d+)")
                    ThugUI.Diagnostics:Log("FISHING", "macro -> lure " .. tostring(id))
                else
                    ThugUI.Diagnostics:Log("FISHING", "macro -> fish")
                end
            end
        end
    end

    timerGeneration = timerGeneration + 1
    if F.PoleHasLure() then
        if GetWeaponEnchantInfo then
            local _, expiration = GetWeaponEnchantInfo()
            if issecretvalue and issecretvalue(expiration) then return end
            if type(expiration) == "number" and expiration > 0 then
                local currentGen = timerGeneration
                C_Timer.After((expiration / 1000) + 1, function()
                    if timerGeneration == currentGen then
                        F:Update()
                    end
                end)
            end
        end
    end
end

function F:CreateMacro()
    if InCombatLockdown and InCombatLockdown() then
        if UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage("Cannot create macro in combat.", 1, 0.1, 0.1, 1)
        end
        return
    end
    if not GetMacroIndexByName or not CreateMacro or not PickupMacro then return end

    local index = GetMacroIndexByName(MACRO_NAME)
    if index == 0 then
        local numGlobal, numChar = GetNumMacros()
        if numChar >= (MAX_CHARACTER_MACROS or 18) then
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage("Character macro slots are full.", 1, 0.1, 0.1, 1)
            end
            return
        end
        local desired = self:DesiredBody()
        if desired == "" then return end
        CreateMacro(MACRO_NAME, "INV_MISC_QUESTIONMARK", desired, true)
    end
    self:Update()
    PickupMacro(MACRO_NAME)
end






















local castMouse, castKey, keyWatch
local bindOwner = CreateFrame("Frame")
local mouseBound, keyArmed, clearAfterCombat = false, false, false
local lastMouse, mouseGen, keyGen = 0, 0, 0

local function Cfg() return ThugUIDB.Fishing or {} end
local function InCombat() return InCombatLockdown and InCombatLockdown() end

local function Window()
    local w = tonumber(Cfg().doubleWindow) or 0.4
    if w < 0.15 then w = 0.15 elseif w > 1 then w = 1 end
    return w
end

local function Allowed()
    if not ThugUI:IsModuleOn("fishing") or InCombat() then return false end
    if Cfg().doubleNeedsPole ~= false and not F.PoleEquipped() then return false end
    return true
end

local function MakeCastButton(name, onDown)
    local b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:SetSize(1, 1)
    b:SetAlpha(0)
    b:EnableMouse(false)
    b:Show()
    if onDown then
        b:RegisterForClicks("AnyDown")
        b:SetAttribute("useOnKeyDown", true)
    else
        b:RegisterForClicks("AnyUp")
        b:SetAttribute("useOnKeyDown", false)
    end
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", "")
    return b
end


function F:GetCastButtons()
    if not castMouse and not InCombat() then
        castMouse = MakeCastButton("ThugUI_FishCast", false)
        castKey = MakeCastButton("ThugUI_FishCastKey", true)
        castMouse:HookScript("PostClick", function() F:ClearMouseBinding(true) end)
        castKey:HookScript("PostClick", function() F:RestoreKeyWatcher(true) end)
    end
    return castMouse, castKey
end

function F:ArmCastButtons(body)
    if InCombat() then self.pending = true return end
    local m, k = self:GetCastButtons()
    if m then m:SetAttribute("macrotext", body) end
    if k then k:SetAttribute("macrotext", body) end
end



function F:ClearMouseBinding(deferred)
    if not mouseBound then return end
    local function Clear()
        if not mouseBound then return end
        if InCombat() then clearAfterCombat = true return end
        mouseBound = false
        ClearOverrideBindings(bindOwner)
        
        F:ApplyKeyBinding()
    end
    if deferred then C_Timer.After(0, Clear) else Clear() end
end

function F:OnWorldMouseDown(button)
    local c = Cfg()
    if not c.doubleClick or button ~= (c.doubleClickButton or "RightButton") then return end
    if not Allowed() then return end
    
    if GetNumLootItems and (GetNumLootItems() or 0) > 0 then return end
    local now = GetTime()
    local diff = now - lastMouse
    lastMouse = now
    if diff > 0.05 and diff < Window() then
        lastMouse = 0
        local m = self:GetCastButtons()
        if not m then return end
        if IsMouselooking and IsMouselooking() and MouselookStop then MouselookStop() end
        SetOverrideBindingClick(bindOwner, true, button == "LeftButton" and "BUTTON1" or "BUTTON2", "ThugUI_FishCast")
        mouseBound = true
        mouseGen = mouseGen + 1
        local gen = mouseGen
        C_Timer.After(Window() + 0.5, function()
            if gen == mouseGen then F:ClearMouseBinding(false) end
        end)
    end
end




function F:ApplyKeyBinding()
    if InCombat() then self.pending = true return end
    if not mouseBound then ClearOverrideBindings(bindOwner) end
    keyArmed = false
    local key = Cfg().doubleKey
    if type(key) ~= "string" or key == "" or not ThugUI:IsModuleOn("fishing") then return end
    if not keyWatch then
        keyWatch = CreateFrame("Button", "ThugUI_FishKeyWatch", UIParent)
        keyWatch:RegisterForClicks("AnyDown")
        keyWatch:SetScript("OnClick", function() F:OnKeyFirstPress() end)
    end
    self:GetCastButtons()
    SetOverrideBindingClick(bindOwner, true, key, "ThugUI_FishKeyWatch")
end

function F:OnKeyFirstPress()
    if not Allowed() then return end
    local key = Cfg().doubleKey
    if type(key) ~= "string" or key == "" then return end
    SetOverrideBindingClick(bindOwner, true, key, "ThugUI_FishCastKey")
    keyArmed = true
    keyGen = keyGen + 1
    local gen = keyGen
    C_Timer.After(Window(), function()
        if gen == keyGen then F:RestoreKeyWatcher(false) end
    end)
end

function F:RestoreKeyWatcher(deferred)
    if not keyArmed then return end
    local function Restore()
        if not keyArmed then return end
        if InCombat() then clearAfterCombat = true return end
        keyGen = keyGen + 1
        F:ApplyKeyBinding()
    end
    if deferred then C_Timer.After(0, Restore) else Restore() end
end


function F:SetDoubleKey(key)
    Cfg().doubleKey = key
    self:ApplyKeyBinding()
end

local hooked = false
function F:InitDoublePress()
    if not hooked and WorldFrame and WorldFrame.HookScript then
        hooked = true
        WorldFrame:HookScript("OnMouseDown", function(_, button) F:OnWorldMouseDown(button) end)
    end
    if not InCombat() then
        self:GetCastButtons()
        self:ApplyKeyBinding()
    end
end

function F:OnRegenDoublePress()
    if clearAfterCombat then
        clearAfterCombat = false
        mouseBound = false
        keyArmed = false
        self:ApplyKeyBinding()
    end
end


F.bindOwner = bindOwner
function F:DoublePressState() return mouseBound, keyArmed end

SlashCmdList["THUGFISH"] = function()
    if not ThugUI:IsModuleOn("fishing") then
        print("ThugUI: Fishing is turned off on the Modules page.")
        return
    end
    F:CreateMacro()
end
SLASH_THUGFISH1 = "/thugfish"





local soundCVars = {
    "Sound_MasterVolume", "Sound_SFXVolume", "Sound_EnableAmbience", "Sound_MusicVolume",
    "Sound_EnableAllSound", "Sound_EnablePetSounds", "Sound_EnableSoundWhenGameIsInBG", "Sound_EnableSFX",
}




local function SaveSounds()
    local cfg = ThugUIDB.Fishing
    if not cfg.soundSnapshot then
        cfg.soundSnapshot = {}
        for _, cvar in ipairs(soundCVars) do
            cfg.soundSnapshot[cvar] = GetCVar(cvar)
        end
    end
end

local function SetCVarSafe(name, value)
    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, name, tostring(value))
    else
        SetCVar(name, tostring(value))
    end
end

local function ApplyFishingSounds()
    local cfg = ThugUIDB.Fishing
    if not cfg.enhanceSounds then return end
    SaveSounds()
    for _, cvar in ipairs(soundCVars) do
        SetCVarSafe(cvar, "0")
    end
    SetCVarSafe("Sound_EnableSFX", "1")
    SetCVarSafe("Sound_EnableSoundWhenGameIsInBG", "1")
    SetCVarSafe("Sound_EnableAllSound", "1")
    SetCVarSafe("Sound_SFXVolume", tostring(cfg.soundScale))
    SetCVarSafe("Sound_MasterVolume", tostring(cfg.soundScale))
end

local function RestoreFishingSounds()
    local cfg = ThugUIDB.Fishing
    if cfg and cfg.soundSnapshot then
        for k, v in pairs(cfg.soundSnapshot) do
            SetCVarSafe(k, v)
        end
        cfg.soundSnapshot = nil
    end
end

F:SetScript("OnEvent", function(self, event, ...)
    if not ThugUI:IsModuleOn("fishing") then self:UnregisterAllEvents() return end
    if event == "PLAYER_ENTERING_WORLD" or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
        if event == "UNIT_INVENTORY_CHANGED" then
            local unit = ...
            if unit ~= "player" then return end
        end
        self:Update()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.pending then
            self.pending = false
            self:Update()
            
            self:ApplyKeyBinding()
        end
        self:OnRegenDoublePress()
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit == "player" and IsFishingChannel() then
            ApplyFishingSounds()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit == "player" then
            RestoreFishingSounds()
        end
    elseif event == "PLAYER_LOGIN" then
        RestoreFishingSounds()
        self:InitDoublePress()
    end
end)

function F:Initialize()
    ThugUI.SafeRegisterEvent(self, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(self, "BAG_UPDATE_DELAYED")
    ThugUI.SafeRegisterEvent(self, "PLAYER_EQUIPMENT_CHANGED")
    ThugUI.SafeRegisterEvent(self, "UNIT_INVENTORY_CHANGED")
    ThugUI.SafeRegisterEvent(self, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(self, "PLAYER_LOGIN")
    pcall(self.RegisterUnitEvent, self, "UNIT_SPELLCAST_CHANNEL_START", "player")
    pcall(self.RegisterUnitEvent, self, "UNIT_SPELLCAST_CHANNEL_STOP", "player")
    RestoreFishingSounds()
end

