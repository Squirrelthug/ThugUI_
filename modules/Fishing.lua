











local ThugUI = _G.ThugUI
local F = CreateFrame("Frame")
ThugUI.Fishing = F
ThugUI:RegisterModule("Fishing", F)

ThugUI.defaults.Fishing = {
    smartCast = true,
    applyLures = true,
    gearButton = true,
    enhanceSounds = false,
    soundScale = 1
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

    if not GetMacroIndexByName or not GetMacroBody then return end
    local index = GetMacroIndexByName(MACRO_NAME)
    if not index or index == 0 then return end

    local desired = self:DesiredBody()
    if desired == "" then return end

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
        end
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

