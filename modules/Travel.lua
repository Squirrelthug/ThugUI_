















local ThugUI = _G.ThugUI
local T = {}
ThugUI.Travel = T
ThugUI:RegisterModule("Travel", T)

ThugUI.defaults.Travel = {}

local MACRO_NAME = "ThugPort"




local classSpells = {
    MAGE = {
        Alliance = {
            3561, 
            3562, 
            3565, 
            32271, 
            49359, 
            33690, 
            53140, 
            88342, 
            132621, 
            120145, 
            176248, 
            224869, 
            193759, 
            281403, 
            344587, 
            395277, 
            446540, 
            1259190, 
            10059, 
            11416, 
            11419, 
            32266, 
            49360, 
            33691, 
            53142, 
            88345, 
            120146, 
            132620, 
            176246, 
            224871, 
            281400, 
            344597, 
            395289, 
            446534, 
            1259194, 
        },
        Horde = {
            3563, 
            3566, 
            3567, 
            32272, 
            49358, 
            35715, 
            53140, 
            88344, 
            132627, 
            120145, 
            176242, 
            224869, 
            193759, 
            281404, 
            344587, 
            395277, 
            446540, 
            1259190, 
            11418, 
            11420, 
            11417, 
            32267, 
            49361, 
            35717, 
            53142, 
            88346, 
            120146, 
            132626, 
            176244, 
            224871, 
            281402, 
            344597, 
            395289, 
            446534, 
            1259194, 
        }
    },
    DRUID = {
        18960, 
        147420, 
        193753, 
    },
    SHAMAN = {
        556, 
    },
    DEATHKNIGHT = {
        50977, 
    },
    MONK = {
        126892, 
        126895, 
    },
}

local scrolls = {
    6948 
}

local heartstones = {
    
    28585, 
    
    37118, 
    44314, 
    44315, 
    54452, 
    64488, 
    93672, 
    142298, 
    142542, 
    162973, 
    163045, 
    165669, 
    165670, 
    165802, 
    166746, 
    166747, 
    168907, 
    172179, 
    180290, 
    182773, 
    183716, 
    184353, 
    184871, 
    188952, 
    190196, 
    190237, 
    193588, 
    206195, 
    200630, 
    208704, 
    209035, 
    210455, 
    212337, 
    228940, 
    235016, 
    236687, 
    243056, 
    245970, 
    246565, 
    260221  
}

local engineeringItems = {
    
    18984, 
    18986, 
    30542, 
    30544, 
    48933, 
    87215, 
    112059, 
    151652, 
    168807, 
    168808, 
    172924, 
    198156, 
    221966, 
    132523, 
    144341, 
    248485, 
}

local itemsList = {
    
    40585, 
    40586, 
    44934, 
    44935, 
    45688, 
    45689, 
    45690, 
    45691, 
    48954, 
    48955, 
    48956, 
    48957, 
    51557, 
    51558, 
    51559, 
    51560, 
    139599, 
    
    21711, 
    37863, 
    
    17690, 
    17691, 
    17900, 
    17901, 
    17902, 
    17903, 
    17904, 
    17905, 
    17906, 
    17907, 
    17908, 
    17909, 
    22631, 
    32757, 
    35230, 
    43824, 
    46874, 
    50287, 
    52251, 
    58487, 
    61379, 
    63206, 
    63207, 
    63352, 
    63353, 
    63378, 
    63379, 
    64457, 
    65274, 
    65360, 
    95050, 
    95051, 
    95567, 
    95568, 
    87548, 
    103678, 
    110560, 
    118662, 
    118663, 
    118907, 
    128353, 
    128502, 
    128503, 
    136849, 
    139590, 
    140192, 
    140324, 
    142469, 
    144391, 
    144392, 
    151016, 
    166559, 
    202046, 
    230850, 
    248131, 
}

function T:Entries()
    local entries = {}
    local added = {}

    local _, class = UnitClass and UnitClass("player") or nil, "MAGE"
    if UnitClass then _, class = UnitClass("player") end
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "Alliance"

    local cSpells = classSpells[class]
    if cSpells then
        local list = cSpells
        if class == "MAGE" then
            list = cSpells[faction] or {}
        end

        for _, id in ipairs(list) do
            local isKnown = false
            if C_SpellBook and C_SpellBook.IsSpellKnown then
                isKnown = C_SpellBook.IsSpellKnown(id)
            else
                isKnown = IsPlayerSpell and IsPlayerSpell(id)
            end

            if isKnown and not added["spell_"..id] then
                local name, icon
                name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
                icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)

                if name then
                    table.insert(entries, { kind = "spell", id = id, name = name, icon = icon })
                    added["spell_"..id] = true
                end
            end
        end
    end

    local function AddItems(list)
        for _, id in ipairs(list) do
            if not added["item_"..id] then
                local count = 0
                count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(id) or 0

                if count > 0 then
                    local name, icon
                    name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
                    icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
                    if not name then name = "Item " .. id end
                    table.insert(entries, { kind = "item", id = id, name = name, icon = icon })
                    added["item_"..id] = true
                end
            end
        end
    end

    AddItems(scrolls)
    AddItems(heartstones)
    AddItems(engineeringItems)
    AddItems(itemsList)

    return entries
end

function T:Cooldown(entry)
    local start, duration, enable
    if entry.kind == "spell" then
        if C_Spell and C_Spell.GetSpellCooldown then
            local ok, cd = pcall(C_Spell.GetSpellCooldown, entry.id)
            if ok and cd then
                start = cd.startTime
                duration = cd.duration
            else
                return 0
            end
        elseif GetSpellCooldown then
            local ok, s, d, e = pcall(GetSpellCooldown, entry.id)
            if ok then
                start = s
                duration = d
                enable = e
            else
                return 0
            end
        else
            return 0
        end
    else
        
        if C_Container and C_Container.GetItemCooldown then
            local ok, s, d, e = pcall(C_Container.GetItemCooldown, entry.id)
            if ok then
                start, duration, enable = s, d, e
            else
                return 0
            end
        elseif GetItemCooldown then
            local ok, s, d, e = pcall(GetItemCooldown, entry.id)
            if ok then
                start, duration, enable = s, d, e
            else
                return 0
            end
        else
            return 0
        end
    end

    if issecretvalue and (issecretvalue(start) or issecretvalue(duration)) then
        return 0
    end

    if not start or not duration or duration <= 1.5 then
        return 0
    end

    local now = GetTime()
    local left = (start + duration) - now
    if left > 0 then
        return left
    end
    return 0
end

function T.FormatCooldown(sec)
    if sec <= 0 then return "" end
    if sec < 60 then
        return string.format("%ds", math.ceil(sec))
    elseif sec < 3600 then
        return string.format("%dm", math.ceil(sec / 60))
    else
        return string.format("%dh", math.ceil(sec / 3600))
    end
end

function T:Body(entry)
    
    if entry.kind == "macro" then return nil end
    if entry.kind == "spell" then
        local name
        name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(entry.id)
        if not name then return nil end
        return "#showtooltip\n/cast " .. name
    else
        return "#showtooltip item:" .. entry.id .. "\n/use item:" .. entry.id
    end
end

function T:Choose(entry)
    if InCombatLockdown and InCombatLockdown() or (UnitAffectingCombat and UnitAffectingCombat("player")) then
        if UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage("Can't set travel in combat.", 1, 0.1, 0.1, 1)
        end
        return false
    end

    if not entry then
        entry = { kind = "item", id = 6948 }
    end

    local body = self:Body(entry)
    if not body then return false end

    if not GetMacroIndexByName or not CreateMacro or not PickupMacro then return false end

    local index = GetMacroIndexByName(MACRO_NAME)
    if index == 0 then
        local numGlobal, numChar = GetNumMacros()
        if numChar >= (MAX_CHARACTER_MACROS or 18) then
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage("Character macros are full.", 1, 0.1, 0.1, 1)
            end
            return false
        end
        CreateMacro(MACRO_NAME, "INV_MISC_QUESTIONMARK", body, true)
        PickupMacro(MACRO_NAME)
        if UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage("ThugPort is on your cursor: put it on a bar slot.", 1, 0.82, 0)
        end
    else
        local _, _, existingBody = GetMacroInfo(index)
        if existingBody ~= body then
            EditMacro(index, nil, nil, body)
        end
    end

    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        local dispName = entry.name
        if not dispName then
            if entry.kind == "spell" then
                dispName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(entry.id)
            else
                dispName = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(entry.id)) or "Item " .. entry.id
            end
        end
        UIErrorsFrame:AddMessage("Travel: " .. (dispName or "") .. ". Press ThugPort.", 1, 0.82, 0)
    end

    if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
        ThugUI.Diagnostics:Log("TRAVEL", "ThugPort -> %s %d", entry.kind, entry.id)
    end

    return true
end











function T:CastText(entry)
    if not entry then return nil end
    local text
    if entry.kind == "spell" then
        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(entry.id)
        if not name then return nil end
        text = "/cast " .. name
    elseif entry.kind == "item" then
        text = "/use item:" .. entry.id
    elseif entry.kind == "macro" then
        
        
        
        if not entry.text or entry.text == "" then return nil end
        return "/stopmacro [combat]\n" .. entry.text
    elseif entry.kind == "prep" then
        
        local t = "/stopmacro [combat]\n/use item:" .. entry.id
        if entry.slot then
            t = t .. "\n/use " .. entry.slot
        end
        return t
    else
        return nil
    end
    local _, class = UnitClass("player")
    if class == "DRUID" then
        text = "/stand\n/dismount\n/cancelform\n" .. text
    end
    
    
    return "/stopmacro [combat]\n" .. text
end

local castButton
function T:GetCastButton()
    if InCombatLockdown and InCombatLockdown() then return nil end
    if not castButton then
        
        
        
        
        castButton = CreateFrame("Button", "ThugUI_TravelCast", UIParent, "SecureActionButtonTemplate")
        castButton:SetSize(1, 1)
        castButton:SetAlpha(0)
        castButton:EnableMouse(false)
        castButton:Show()
        castButton:RegisterForClicks("AnyDown", "AnyUp")
        castButton:SetAttribute("type", "macro")
        castButton:SetAttribute("useOnKeyDown", true)
        castButton:SetAttribute("macrotext", "")

        
        
        castButton:HookScript("PostClick", function(_, _, down)
            if down then
                if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
                    local id = T.armed and T.armed.id or "nil"
                    local kind = T.armed and T.armed.kind or "nil"
                    if kind == "macro" then
                        ThugUI.Diagnostics:Log("GROUP", "macro pressed")
                    else
                        ThugUI.Diagnostics:Log("TRAVEL", "cast %s %s via wheel", kind, tostring(id))
                    end
                end
                T.castSeen = true
            else
                if ThugUI.ControllerRadial and ThugUI.ControllerRadial.FinishCast then
                    ThugUI.ControllerRadial:FinishCast()
                end
            end
        end)
    end
    return castButton
end



function T:Arm(entry)
    if InCombatLockdown and InCombatLockdown() then return false end
    local btn = self:GetCastButton()
    if not btn then return false end
    local text = self:CastText(entry)
    if not entry or not text then
        btn:SetAttribute("macrotext", "")
        T.armed = nil
        return false
    else
        btn:SetAttribute("macrotext", text)
        T.armed = entry
        return true
    end
end

local altButton
function T:GetAltButton()
    if InCombatLockdown and InCombatLockdown() then return nil end
    if not altButton then
        altButton = CreateFrame("Button", "ThugUI_PrepAlt", UIParent, "SecureActionButtonTemplate")
        altButton:SetSize(1, 1)
        altButton:SetAlpha(0)
        altButton:EnableMouse(false)
        altButton:Show()
        altButton:RegisterForClicks("AnyDown", "AnyUp")
        altButton:SetAttribute("type", "macro")
        altButton:SetAttribute("useOnKeyDown", true)
        altButton:SetAttribute("macrotext", "")

        altButton:HookScript("PostClick", function(_, _, down)
            if down then
                if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
                    local id = T.armedAlt and T.armedAlt.id or "nil"
                    local kind = T.armedAlt and T.armedAlt.kind or "nil"
                    ThugUI.Diagnostics:Log("TRAVEL", "cast alt %s %s via wheel", kind, tostring(id))
                end
                T.castSeen = true
            else
                if ThugUI.ControllerRadial and ThugUI.ControllerRadial.FinishCast then
                    ThugUI.ControllerRadial:FinishCast()
                end
            end
        end)
    end
    return altButton
end

function T:ArmAlt(entry)
    if InCombatLockdown and InCombatLockdown() then return false end
    local btn = self:GetAltButton()
    if not btn then return false end
    local text = self:CastText(entry)
    if not entry or not text then
        btn:SetAttribute("macrotext", "")
        T.armedAlt = nil
        return false
    else
        btn:SetAttribute("macrotext", text)
        T.armedAlt = entry
        return true
    end
end







local bindOwner = CreateFrame("Frame", "ThugUI_TravelBindOwner")



function T:BindCross(on)
    local isCombat = InCombatLockdown and InCombatLockdown() or false
    if on then
        if isCombat then return end
        local btn = self:GetCastButton()
        if not btn then return end
        SetOverrideBindingClick(bindOwner, true, GAMEPAD_FACE_BOTTOM or "PAD1", "ThugUI_TravelCast", "LeftButton")
        T.crossBound = true
        if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
            
            
            
            local key = GAMEPAD_FACE_BOTTOM or "PAD1"
            local function Owner()
                local ok, action = pcall(GetBindingAction, key, true)
                return ok and tostring(action) or ("error " .. tostring(action))
            end
            ThugUI.Diagnostics:Log("TRAVEL", "cross bound; %s -> %s", key, Owner())
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, function()
                    if T.crossBound then
                        ThugUI.Diagnostics:Log("TRAVEL", "0.5s later %s -> %s", key, Owner())
                    end
                end)
            end
        end
    else
        local ok, err = false, "InCombatLockdown"
        if not isCombat then
            ok, err = pcall(ClearOverrideBindings, bindOwner)
        end
        if not ok then
            T.clearPending = true
            if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
                ThugUI.Diagnostics:Log("TRAVEL", "unbind refused: " .. tostring(err) .. " (lockdown=" .. tostring(isCombat) .. ")")
            end
        else
            T.crossBound = false
            T.squareBound = false
            self:ArmAlt(nil)
            if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
                ThugUI.Diagnostics:Log("TRAVEL", "cross unbound")
            end
        end
    end
end

function T:BindSquare(on)
    local isCombat = InCombatLockdown and InCombatLockdown() or false
    if on then
        if isCombat then return end
        local btn = self:GetAltButton()
        if not btn then return end
        SetOverrideBindingClick(bindOwner, true, GAMEPAD_FACE_LEFT or "PAD3", "ThugUI_PrepAlt", "LeftButton")
        T.squareBound = true
        if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
            ThugUI.Diagnostics:Log("TRAVEL", "square bound")
        end
    else
        
        
        
        
        local ok = false
        if not isCombat then
            ok = pcall(SetOverrideBinding, bindOwner, true, GAMEPAD_FACE_LEFT or "PAD3", nil)
        end
        if not ok then
            T.clearSquarePending = true
            if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
                ThugUI.Diagnostics:Log("TRAVEL", "square unbind refused")
            end
        else
            T.squareBound = false
            if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
                ThugUI.Diagnostics:Log("TRAVEL", "square unbound")
            end
        end
    end
end




local frame = CreateFrame("Frame", "ThugUI_TravelEventFrame")
ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_DISABLED")
ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event)
    if not ThugUI:IsModuleOn("travel") then self:UnregisterAllEvents() return end
    if event == "PLAYER_REGEN_DISABLED" then
        T:BindCross(false)
        T:Arm(nil)
        if ThugUI.ControllerRadial and ThugUI.ControllerRadial.OnCombatStart then
            ThugUI.ControllerRadial:OnCombatStart()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if T.clearPending then
            T.clearPending = false
            T:BindCross(false)
        end
        if T.clearSquarePending then
            T.clearSquarePending = false
            T:BindSquare(false)
        end
    end
end)

SlashCmdList["THUGPORT"] = function()
    if not ThugUI:IsModuleOn("travel") then
        print("ThugUI: Travel comes with Controller, which is turned off on the Modules page.")
        return
    end
    local entries = T:Entries()
    local found = nil
    for _, e in ipairs(entries) do
        if e.kind == "item" and e.id == 6948 then
            found = e
            break
        end
    end
    T:Choose(found)
end
SLASH_THUGPORT1 = "/thugport"
