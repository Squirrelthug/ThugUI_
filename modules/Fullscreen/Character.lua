






local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen
local C = { id = "character", title = "Character", regions = { "paperdoll", "armorchest" } }
FS.Character = C



local TABS = { "gear", "stats", "upkeep" }
local TAB_LABELS = { gear = "Gear", stats = "Stats", upkeep = "Upkeep" }


local TAB_REGIONS = { gear = { "paperdoll", "armorchest" }, stats = { "stats" }, upkeep = { "upkeep" } }
C.tab = "gear"


function C:Regions()
    return TAB_REGIONS[self.tab] or TAB_REGIONS.gear
end



local names = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
    "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
    "MainHandSlot", "SecondaryHandSlot", "RangedSlot", "AmmoSlot",
}
local LEFT_IDS = { 1, 2, 3, 15, 5, 4, 19, 9 }
local RIGHT_IDS = { 10, 6, 7, 8, 11, 12, 13, 14 }
local BOTTOM_IDS = { 16, 17, 18, 0 }
local SLOT_LABELS = { MainHandSlot = "Main hand", SecondaryHandSlot = "Off hand" }
local ROW_GAP = 6
local CHEST_ROWS = 2
local SHORT_MESSAGE = "Bags will refresh after combat"


local MODEL_ASPECT = 1.385
C.ModelAspect = MODEL_ASPECT



local SHEET_SCENE_ID = 595

local function Log(message, ...)
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("FULLSCREEN", message, ...)
    end
end


















local function SetUpScene(scene, actorOnly)
    if not actorOnly then
        local transition, discard = _G.CAMERA_TRANSITION_TYPE_IMMEDIATE, _G.CAMERA_MODIFICATION_TYPE_DISCARD
        local ok, err = pcall(scene.TransitionToModelSceneID, scene, SHEET_SCENE_ID, transition, discard, true)
        if not ok then
            return false, err
        end
    end
    local okActor, actor = pcall(scene.GetPlayerActor, scene)
    if not okActor or not actor then
        return false, actor or "no player actor"
    end
    local okModel, errModel = pcall(actor.SetModelByUnit, actor, "player", false, true, false, true)
    if not okModel then
        return false, errModel
    end
    return true
end



function C:BuildModel()
    if self.modelTried or not self.frame then
        return
    end
    self.modelTried = true
    local okModel, model = pcall(CreateFrame, "PlayerModel", nil, self.frame)
    local why
    if okModel and model then
        local okUnit, errUnit = pcall(model.SetUnit, model, "player")
        if okUnit then
            self.model, self.modelKind = model, "PlayerModel"
            pcall(model.Hide, model)
            return
        end
        pcall(model.Hide, model)
        why = tostring(errUnit)
    else
        why = tostring(model)
    end
    local okScene, scene = pcall(CreateFrame, "ModelScene", nil, self.frame)
    if okScene and scene then
        local okSetup, errSetup = SetUpScene(scene)
        if okSetup then
            self.model, self.modelKind = scene, "ModelScene"
            pcall(scene.Hide, scene)
            return
        end
        pcall(scene.Hide, scene)
        Log("no player model: PlayerModel failed (%s), ModelScene failed (%s); the centre stays text", why, tostring(errSetup))
        return
    end
    Log("no player model: PlayerModel failed (%s), ModelScene failed (%s); the centre stays text", why, tostring(scene))
end


function C:RefreshModel()
    local model = self.model
    if not model then
        return
    end
    if self.modelKind == "ModelScene" then
        
        SetUpScene(model, true)
        return
    end
    pcall(model.SetUnit, model, "player")
    
    if model.SetFacing then
        pcall(model.SetFacing, model, 0)
    end
end



function C:LayoutModel(width, top, rowStep, cell)
    local model = self.model
    if not model then
        return
    end
    local left = cell + 12
    local boxW = width - 2 * left
    local boxH = 8 * rowStep - ROW_GAP
    local w, h = boxW, boxW * MODEL_ASPECT
    if h > boxH then
        h = boxH
        w = boxH / MODEL_ASPECT
    end
    w, h = math.max(w, 1), math.max(h, 1)
    local x = left + (boxW - w) / 2
    local y = top + (boxH - h) / 2
    pcall(model.ClearAllPoints, model)
    pcall(model.SetSize, model, w, h)
    pcall(model.SetPoint, model, "TOPLEFT", self.frame, "TOPLEFT", x, -y)
    self.modelRect = { x = x, y = y, w = w, h = h }
end



function C.SlotLabel(slotName)
    if not slotName then
        return "Slot"
    end
    if SLOT_LABELS[slotName] then
        return SLOT_LABELS[slotName]
    end
    local base = (slotName:gsub("Slot$", ""))
    local word, digit = base:match("^(%a+)(%d+)$")
    if word then
        return word .. " " .. (tonumber(digit) + 1)
    end
    return base
end




local NAME_BY_ID = {
    [0] = "AmmoSlot", [1] = "HeadSlot", [2] = "NeckSlot", [3] = "ShoulderSlot", [4] = "ShirtSlot",
    [5] = "ChestSlot", [6] = "WaistSlot", [7] = "LegsSlot", [8] = "FeetSlot", [9] = "WristSlot",
    [10] = "HandsSlot", [11] = "Finger0Slot", [12] = "Finger1Slot", [13] = "Trinket0Slot",
    [14] = "Trinket1Slot", [15] = "BackSlot", [16] = "MainHandSlot", [17] = "SecondaryHandSlot",
    [18] = "RangedSlot", [19] = "TabardSlot",
}


function C.SlotName(id)
    local cell = C.byID and C.byID[id]
    return cell and cell.slotName or NAME_BY_ID[id]
end










local function Pack(...)
    return { n = select("#", ...), ... }
end

local function AnySecret(list)
    for i = 1, list.n do
        if issecretvalue and issecretvalue(list[i]) then
            return true
        end
    end
    return false
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown() and true or false
end



local function SafeFormat(text, ...)
    if type(text) ~= "string" then
        return nil
    end
    local ok, result = pcall(string.format, text, ...)
    if ok then
        return result
    end
    return nil
end

local function Round(v)
    return math.floor(v + 0.5)
end



local function Num(v)
    local n = Round(v)
    if BreakUpLargeNumbers then
        local ok, text = pcall(BreakUpLargeNumbers, n)
        if ok and type(text) == "string" then
            return text
        end
    end
    return tostring(n)
end


local function Pct(v)
    return string.format("%.2f%%", v)
end

local function PlayerClass()
    local _, class = UnitClass("player")
    return class
end





local CASTERS = { MAGE = true, WARLOCK = true, PRIEST = true, DRUID = true, SHAMAN = true, PALADIN = true }
local RANGED_CLASSES = { WARRIOR = true, HUNTER = true, ROGUE = true }

local function IsCaster()
    return CASTERS[PlayerClass()] == true
end

local function UsesMana()
    local mana = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0
    local max = UnitPowerMax("player", mana)
    if issecretvalue and issecretvalue(max) then
        
        
        return true
    end
    return max > 0
end








function C.PaneText(globalName)
    local label = globalName and _G[globalName]
    if type(label) ~= "string" then
        return nil
    end
    local box = _G.CharacterStatsPaneScrollBox
    local target = box and box.ScrollBox and box.ScrollBox.ScrollTarget
    if not target or not target.GetChildren then
        return nil
    end
    local ok, children = pcall(function()
        return { target:GetChildren() }
    end)
    if not ok then
        return nil
    end
    local want = SafeFormat(_G.STAT_FORMAT or "%s:", label)
    for _, child in ipairs(children) do
        local labelText = child.Label and child.Label.GetText and child.Label:GetText()
        
        if type(labelText) == "string" and not (issecretvalue and issecretvalue(labelText)) and labelText == want then
            local value = child.Value and child.Value.GetText and child.Value:GetText()
            if type(value) == "string" then
                if issecretvalue and issecretvalue(value) then
                    return value
                end
                if value ~= "" then
                    return value
                end
            end
            return nil
        end
    end
    return nil
end














local SECTIONS = {
    { key = "general", title = "General", color = { 0.70, 0.70, 0.70 } },
    { key = "attributes", title = "Attributes", color = { 0.90, 0.70, 0.20 } },
    { key = "modifiers", title = "Modifiers", color = { 0.40, 0.80, 0.40 } },
    { key = "weapons", title = "Weapons", color = { 0.80, 0.30, 0.30 } },
    { key = "defense", title = "Defense", color = { 0.29, 0.46, 0.90 } },
}
C.SECTIONS = SECTIONS

local DEFS = {}
C.DEFS = DEFS
local function Def(def)
    DEFS[#DEFS + 1] = def
    return def
end

local function G(name, fallback)
    local v = _G[name]
    if type(v) == "string" then
        return v
    end
    return fallback
end



Def{ section = "general", key = "health", name = "Health", pane = "HEALTH",
    read = function() return UnitHealthMax("player") end,
    fmt = Num,
    zero = function(v) return v == 0 end,
    static = function() return _G.STAT_HEALTH_TOOLTIP end,
    tip = function() return { _G.STAT_HEALTH_TOOLTIP } end,
}



local function PowerToken()
    local _, token = UnitPowerType("player")
    return token
end
Def{ section = "general", key = "power",
    name = function()
        local token = PowerToken()
        return token and (G(token, token:sub(1, 1) .. token:sub(2):lower())) or "Power"
    end,
    read = function() return UnitPowerMax("player") end,
    fmt = Num,
    zero = function(v) return v == 0 end,
    static = function()
        local token = PowerToken()
        return token and _G["STAT_" .. token .. "_TOOLTIP"] or nil
    end,
    tip = function()
        local token = PowerToken()
        return { token and _G["STAT_" .. token .. "_TOOLTIP"] or nil }
    end,
}

Def{ section = "general", key = "manaregen", name = "Mana Regen", pane = "MANA_REGEN",
    applies = UsesMana,
    
    
    read = function() return GetManaRegen() end,
    fmt = function(base, combat)
        return Num(math.floor(combat * 5)) .. " / " .. Num(math.floor(base * 5))
    end,
    zero = function(base) return base == 0 end,
    tip = function(_, combat)
        return { SafeFormat(_G.MANA_REGEN_FROM_SPIRIT, Num(math.floor(combat * 5))) }
    end,
}

Def{ section = "general", key = "movespeed", name = "Movement Speed", pane = "STAT_MOVEMENT_SPEED",
    
    read = function()
        local _, run, flight, swim = GetUnitSpeed("player")
        local swimming = IsSwimming and IsSwimming("player")
        local flying = IsFlying and IsFlying()
        return run, flight, swim, swimming and true or false, flying and true or false
    end,
    fmt = function(run, flight, swim, swimming, flying)
        local base = _G.BASE_MOVEMENT_SPEED or 7
        local speed = run
        if swimming then
            speed = swim
        elseif flying then
            speed = flight
        end
        return string.format("%.0f%%", speed / base * 100)
    end,
    zero = function(run) return run == 0 end,
}






local ATTRIBUTES = {
    { 1, "ITEM_MOD_STRENGTH_SHORT", "STRENGTH", "Strength" },
    { 2, "ITEM_MOD_AGILITY_SHORT", "AGILITY", "Agility" },
    { 3, "ITEM_MOD_STAMINA_SHORT", "STAMINA", "Stamina" },
    { 4, "ITEM_MOD_INTELLECT_SHORT", "INTELLECT", "Intellect" },
    { 5, "ITEM_MOD_SPIRIT_SHORT", "SPIRIT", "Spirit" },
}



local function AttributeArgs(index, class, effective)
    if index == 1 then
        return { GetAttackPowerForStat(index, effective), math.floor(effective / 20) }
    elseif index == 2 then
        local dodge = GetDodgeChanceFromAttribute() * 100
        local armor = effective * 2
        local crit = GetCritChanceFromStat(index, effective) * 100
        local ap = GetAttackPowerForStat(index, effective)
        local rap = GetRangedAttackPowerForStat(index, effective)
        if class == "ROGUE" or class == "HUNTER" then
            return { crit, ap, rap, armor, dodge }
        elseif class == "DRUID" then
            return { crit, effective, armor, dodge }
        elseif class == "WARRIOR" then
            return { crit, rap, armor, dodge }
        end
        return { crit, armor, dodge }
    elseif index == 3 then
        local bonus = math.min(_G.STAMINA_BREAK, effective)
        bonus = bonus + (math.max(_G.STAMINA_BREAK, effective) - _G.STAMINA_BREAK) * UnitHPPerStamina("player")
        return { tostring(bonus) }
    elseif index == 4 then
        local spellCrit = GetSpellCritChanceFromStat(index, effective) * 100
        if class == "WARRIOR" or class == "ROGUE" then
            return { spellCrit }
        end
        local mana = math.min(_G.INTELLECT_BREAK, effective)
        mana = mana + (math.max(_G.INTELLECT_BREAK, effective) - _G.INTELLECT_BREAK) * _G.MANA_PER_INTELLECT
        return { tostring(mana), spellCrit }
    end
    local healthFromSpirit = GetHealthRegenFromSpirit() * 0.75
    local manaFromSpirit = GetManaRegenFromSpirit()
    if class == "WARRIOR" or class == "ROGUE" then
        return { healthFromSpirit * 5, GetHealthRegen() * 5 }
    end
    return { healthFromSpirit * 5, manaFromSpirit * 5, GetHealthRegen() * 5, GetManaRegen() * 5 }
end

for _, attr in ipairs(ATTRIBUTES) do
    local index, paneName, word, fallback = attr[1], attr[2], attr[3], attr[4]
    Def{ section = "attributes", key = "attr_" .. word:lower(),
        name = function() return G(paneName, fallback) end,
        pane = paneName,
        read = function()
            local _, effective = UnitStat("player", index)
            return effective
        end,
        fmt = Num,
        zero = function(v) return v == 0 end,
        tip = function(effective)
            local class = PlayerClass()
            
            
            local text = _G[tostring(class) .. "_" .. word .. "_TOOLTIP"] or _G["DEFAULT_" .. word .. "_TOOLTIP"]
            local ok, args = pcall(AttributeArgs, index, class, effective)
            local lines = {}
            lines[1] = ok and SafeFormat(text, unpack(args)) or nil
            if index == 5 and lines[1] then
                lines[2] = _G.SPIRIT_STANDING_WARNING
            end
            return lines
        end,
    }
end



Def{ section = "modifiers", key = "spellpower", name = "Spell Power", pane = "STAT_SPELLPOWER",
    
    
    applies = function() return IsCaster() or C.PaneText("STAT_SPELLPOWER") ~= nil end,
    read = function()
        local list = {}
        for school = 2, _G.MAX_SPELL_SCHOOLS or 7 do
            list[#list + 1] = GetSpellBonusDamage(school)
        end
        return unpack(list)
    end,
    fmt = function(...) return Num(math.min(...)) end,
    zero = function(...) return math.min(...) == 0 end,
    tip = function(...) return { SafeFormat(_G.STAT_SPELLPOWER_TOOLTIP, math.max(...)) } end,
}

Def{ section = "modifiers", key = "spellhealing", name = "Spell Healing", pane = "STAT_SPELLHEALING",
    applies = IsCaster,
    read = function() return GetSpellBonusHealing() end,
    fmt = Num,
    zero = function(v) return v == 0 end,
    tip = function(v) return { SafeFormat(_G.STAT_SPELLHEALING_TOOLTIP, v) } end,
}

Def{ section = "modifiers", key = "attackpower", name = "Attack Power", pane = "STAT_ATTACK_POWER",
    read = function() return UnitAttackPower("player") end,
    fmt = function(base, pos, neg) return Num(math.max(base + pos + neg, 0)) end,
    zero = function(base, pos, neg) return base + pos + neg == 0 end,
    tip = function(base, pos, neg)
        local text = _G[tostring(PlayerClass()) .. "_MELEE_ATTACK_POWER_TOOLTIP"] or _G.MELEE_ATTACK_POWER_TOOLTIP
        return { SafeFormat(text, Num(math.max(base + pos + neg, 0) / (_G.ATTACK_POWER_MAGIC_NUMBER or 14))) }
    end,
}

Def{ section = "modifiers", key = "rangedpower", name = "Ranged Attack Power", pane = "RANGED_ATTACK_POWER",
    applies = function() return not IsCaster() end,
    read = function() return UnitRangedAttackPower("player") end,
    fmt = function(base, pos, neg) return Num(math.max(base + pos + neg, 0)) end,
    zero = function(base, pos, neg) return base + pos + neg == 0 end,
    tip = function(base, pos, neg)
        return { SafeFormat(_G.RANGED_ATTACK_POWER_TOOLTIP,
            Num(math.max(base + pos + neg, 0) / (_G.ATTACK_POWER_MAGIC_NUMBER or 14))) }
    end,
}



local function CritDef(key, name, api, applies, tipGlobal)
    Def{ section = "modifiers", key = key, name = name, pane = "STAT_CRITICAL_STRIKE",
        applies = applies,
        read = function() return api() end,
        fmt = Pct,
        zero = function(v) return v == 0 end,
        tip = function(v)
            local bonus = _G["STAT_" .. tostring(PlayerClass()) .. "_CRIT_BONUS"] or _G.STAT_CRIT_BONUS
            return { SafeFormat(_G[tipGlobal], v), type(bonus) == "string" and bonus or nil }
        end,
    }
end
CritDef("crit_melee", "Melee Crit", function() return GetCritChance() end,
    function() return not IsCaster() end, "STAT_CRIT_MELEE")
CritDef("crit_ranged", "Ranged Crit", function() return GetRangedCritChance() end,
    function() return RANGED_CLASSES[PlayerClass()] == true end, "STAT_CRIT_RANGED")
CritDef("crit_spell", "Spell Crit", function() return GetSpellCritChance() end,
    IsCaster, "STAT_CRIT_SPELL")

Def{ section = "modifiers", key = "hit", name = "Hit", pane = "STAT_HIT_CHANCE",
    
    
    read = function()
        return GetCombatRatingBonus(_G.CR_HIT_MELEE) + GetHitModifier(),
            GetCombatRatingBonus(_G.CR_HIT_RANGED) + GetRangedHitModifier(),
            GetCombatRatingBonus(_G.CR_HIT_SPELL) + GetSpellHitModifier()
    end,
    fmt = function(...) return Pct(math.max(...)) end,
    zero = function(...) return math.max(...) == 0 end,
    tip = function(melee, ranged, spell)
        local lines = {}
        if melee > 0 then lines[#lines + 1] = SafeFormat(_G.CR_HIT_MELEE_TOOLTIP, melee) end
        if ranged > 0 and RANGED_CLASSES[PlayerClass()] then
            lines[#lines + 1] = SafeFormat(_G.CR_HIT_RANGED_TOOLTIP, ranged)
        end
        if spell > 0 then lines[#lines + 1] = SafeFormat(_G.CR_HIT_SPELL_TOOLTIP, spell) end
        local cap = _G["CR_" .. tostring(PlayerClass()) .. "_HIT_CAP_TOOLTIP"] or _G.CR_DEFAULT_HIT_CAP_TOOLTIP
        lines[#lines + 1] = SafeFormat(cap, UnitLevel("player"))
        return lines
    end,
}

Def{ section = "modifiers", key = "haste", name = "Haste", pane = "STAT_HASTE",
    
    read = function()
        local rangedBase, ammo = GetRangedHaste()
        return GetMeleeHaste(), rangedBase + ammo, UnitSpellHaste("player")
    end,
    fmt = function(...) return Pct(math.max(...)) end,
    zero = function(...) return math.max(...) == 0 end,
    tip = function(melee, ranged, spell)
        return { SafeFormat(_G.CR_HASTE_MELEE_TOOLTIP, melee),
            RANGED_CLASSES[PlayerClass()] and SafeFormat(_G.CR_HASTE_RANGED_TOOLTIP, ranged) or nil,
            SafeFormat(_G.CR_HASTE_SPELL_TOOLTIP, spell) }
    end,
}

Def{ section = "modifiers", key = "expertise", name = "Expertise", pane = "STAT_EXPERTISE",
    applies = function() return not IsCaster() end,
    read = function() return GetExpertise() end,
    fmt = function(...) return Pct(math.max(...)) end,
    zero = function(...) return math.max(...) == 0 end,
    tip = function(main, off, ranged)
        local text = PlayerClass() == "HUNTER" and _G.CR_RANGED_EXPERTISE_TOOLTIP or _G.CR_EXPERTISE_TOOLTIP
        return { SafeFormat(text, Pct(math.max(main, off, ranged))) }
    end,
}

Def{ section = "modifiers", key = "armorpen", name = "Armor Penetration", pane = "STAT_ARMOR_PENETRATION",
    applies = function() return not IsCaster() end,
    read = function() return GetArmorPenetration() end,
    fmt = Num,
    zero = function(v) return v == 0 end,
    tip = function(v) return { SafeFormat(_G.ARMOR_PENETRATION_TOOLTIP, v) } end,
}

Def{ section = "modifiers", key = "spellpen", name = "Spell Penetration", pane = "STAT_SPELL_PENETRATION",
    applies = IsCaster,
    read = function() return GetSpellPenetration() end,
    fmt = Num,
    zero = function(v) return v == 0 end,
    tip = function(pen)
        local average = pen * 0.75 / (UnitLevel("player") * 5)
        return { SafeFormat(_G.SPELL_PENETRATION_TOOLTIP, pen, average, average / 2) }
    end,
}





local function DamageText(min, max)
    return math.max(math.floor(min), 1) .. " - " .. math.max(math.ceil(max), 1)
end

local function DamageTip(min, max, speed)
    local lines = {}
    if type(speed) == "number" and speed > 0 then
        local format = _G.STAT_FORMAT or "%s:"
        lines[1] = SafeFormat(format, G("ATTACK_SPEED_SECONDS", "Attack Speed (seconds)")) .. " "
            .. string.format("%.2f", speed)
        lines[2] = SafeFormat(format, G("STAT_DPS_SHORT", "DPS")) .. " "
            .. string.format("%.1f", (min + max) / (2 * speed))
    end
    return lines
end

Def{ section = "weapons", key = "attackspeed", name = "Attack Speed",
    read = function() return UnitAttackSpeed("player") end,
    fmt = function(main, off)
        local text = string.format("%.2f", main)
        if off then
            text = text .. " / " .. string.format("%.2f", off)
        end
        return text
    end,
    zero = function(main) return main == 0 end,
    tip = function() return { SafeFormat(_G.STAT_ATTACK_SPEED_BASE_TOOLTIP, Num(GetMeleeHaste())) } end,
}

Def{ section = "weapons", key = "mainhand", name = "Main Hand Damage", pane = "INVTYPE_WEAPONMAINHAND",
    read = function()
        local min, max = UnitDamage("player")
        return min, max, (UnitAttackSpeed("player"))
    end,
    fmt = function(min, max) return DamageText(min, max) end,
    zero = function(_, max) return max == 0 end,
    tip = DamageTip,
}

Def{ section = "weapons", key = "offhand", name = "Off Hand Damage", pane = "INVTYPE_WEAPONOFFHAND",
    applies = function() return IsDualWielding() end,
    read = function()
        local _, _, min, max = UnitDamage("player")
        local _, speed = UnitAttackSpeed("player")
        return min, max, speed
    end,
    fmt = function(min, max) return DamageText(min, max) end,
    zero = function(_, max) return max == 0 end,
    tip = DamageTip,
}

Def{ section = "weapons", key = "ranged", name = "Ranged Damage", pane = "INVTYPE_RANGED",
    applies = function() return IsRangedWeapon() end,
    read = function()
        local speed, min, max = UnitRangedDamage("player")
        return min, max, speed
    end,
    fmt = function(min, max) return DamageText(min, max) end,
    zero = function(_, max) return max == 0 end,
    tip = DamageTip,
}



Def{ section = "defense", key = "defense", name = "Defense", pane = "DEFENSE",
    read = function() return UnitDefenseSkill("player") end,
    fmt = function(base, modifier) return Num(math.max(0, base + modifier)) end,
    zero = function(base, modifier) return math.max(0, base + modifier) == 0 end,
    tip = function(base, modifier)
        local beyond = math.max(math.max(0, base + modifier) - UnitLevel("player") * 5, 0)
        return { SafeFormat(_G.DEFAULT_STATDEFENSE_TOOLTIP, beyond * 0.04, beyond * 0.04) }
    end,
}

Def{ section = "defense", key = "armor", name = "Armor", pane = "STAT_ARMOR",
    read = function()
        local _, effective = UnitArmor("player")
        return effective
    end,
    fmt = Num,
    zero = function(v) return v == 0 end,
    tip = function(effective)
        local reduction = PaperDollFrame_GetArmorReduction(effective, UnitEffectiveLevel("player"))
        return { SafeFormat(_G.STAT_ARMOR_TOOLTIP, reduction) }
    end,
}

Def{ section = "defense", key = "dodge", name = "Dodge", pane = "STAT_DODGE",
    read = function() return GetDodgeChance() end,
    fmt = Pct,
    zero = function(v) return v == 0 end,
    tip = function(v) return { SafeFormat(_G.CR_DODGE_BASE_STAT_TOOLTIP, v) } end,
}

Def{ section = "defense", key = "parry", name = "Parry", pane = "STAT_PARRY",
    read = function() return GetParryChance() end,
    fmt = Pct,
    zero = function(v) return v == 0 end,
    tip = function(v) return { SafeFormat(_G.CR_PARRY_BASE_STAT_TOOLTIP, v) } end,
}

Def{ section = "defense", key = "block", name = "Block", pane = "STAT_BLOCK",
    read = function() return GetBlockChance() end,
    fmt = Pct,
    zero = function(v) return v == 0 end,
    tip = function(v) return { SafeFormat(_G.STAT_BLOCK_VALUE_FLAT_TOOLTIP, v, GetShieldBlock()) } end,
}




for _, school in ipairs({ { 6, "Arcane" }, { 2, "Fire" }, { 4, "Frost" }, { 3, "Nature" }, { 5, "Shadow" } }) do
    local id, fallback = school[1], school[2]
    Def{ section = "defense", key = "resist_" .. id,
        name = function() return G("DAMAGE_SCHOOL" .. (id + 1), fallback) end,
        read = function()
            local _, total = UnitResistance("player", id)
            return total
        end,
        fmt = Num,
        zero = function(v) return v == 0 end,
        tip = function(total)
            local level = UnitLevel("player")
            return { SafeFormat(_G.RESISTANCE_TOOLTIP_SUBTEXT, _G["RESISTANCE_TYPE" .. id], level,
                math.floor(ExpectedSpellResistance(level, total) * 100)) }
        end,
    }
end

local function DefName(def)
    if type(def.name) == "function" then
        local ok, name = pcall(def.name)
        return ok and name or nil
    end
    return def.name
end



function C.EvalStat(def)
    local name = DefName(def)
    if not name then
        return nil
    end
    if def.applies then
        local ok, yes = pcall(def.applies)
        if not ok or not yes then
            return nil
        end
    end
    local raw, text
    local secret = InCombat()
    if not secret then
        local got = Pack(pcall(def.read))
        if not got[1] then
            return nil
        end
        raw = Pack(unpack(got, 2, got.n))
        secret = AnySecret(raw)
    end
    if secret then
        
        text = C.PaneText(def.pane) or "-"
        raw = nil
    else
        local okFmt, formatted = pcall(def.fmt, unpack(raw, 1, raw.n))
        if not okFmt or type(formatted) ~= "string" then
            return nil
        end
        local okZero, isZero = pcall(def.zero, unpack(raw, 1, raw.n))
        if not okZero or isZero then
            return nil
        end
        text = formatted
    end
    return {
        label = name, value = text,
        item = { kind = "stat", key = def.key, name = name, text = text, secret = secret, def = def, raw = raw,
            section = def.section },
    }
end




function C:DescribeStat(item)
    local lines = {}
    local section
    for _, candidate in ipairs(SECTIONS) do
        if candidate.key == item.section then
            section = candidate
        end
    end
    
    
    if not item.secret then
        local c = section and section.color
        lines[#lines + 1] = { leftText = item.text, leftColor = c and { r = c[1], g = c[2], b = c[3] } or nil }
    end
    local def = item.def
    local texts = {}
    if item.secret then
        if def.static then
            local ok, text = pcall(def.static)
            texts = ok and { text } or {}
        end
    else
        local ok, list = pcall(def.tip or function() return {} end, unpack(item.raw, 1, item.raw.n))
        texts = ok and list or {}
    end
    for i = 1, 8 do
        local text = texts[i]
        
        
        if type(text) == "string" and text ~= "" and not (item.secret and text:find("%%[^%%]")) then
            for part in (text .. "\n"):gmatch("(.-)\n") do
                lines[#lines + 1] = { leftText = part }
            end
        end
    end
    if #lines == 0 then
        lines[1] = { leftText = "-", leftColor = FS.MUTED }
    end
    return item.name, lines
end






function C:BuildStats()
    local entries, lines, map = {}, {}, {}
    for _, section in ipairs(SECTIONS) do
        local rows = {}
        for _, def in ipairs(DEFS) do
            if def.section == section.key then
                local entry = C.EvalStat(def)
                if entry then
                    rows[#rows + 1] = entry
                end
            end
        end
        if #rows > 0 then
            lines[#lines + 1] = { header = section.title, color = section.color }
            for i, entry in ipairs(rows) do
                lines[#lines + 1] = { entry = entry }
                entries[#entries + 1] = entry
                map[#entries] = i == 1 and #lines - 1 or #lines
            end
        end
    end
    return { entries = entries, lines = lines, map = map }
end






local RED = { 1, 0.1, 0.1 }
local ORANGE = { 1, 0.5, 0 }
local WHITE_TEXT = { 1, 1, 1 }



function C.Durability(slot)
    if not GetInventoryItemDurability then
        return nil
    end
    local ok, cur, max = pcall(GetInventoryItemDurability, slot)
    if not ok or type(cur) ~= "number" or type(max) ~= "number" then
        return nil
    end
    if issecretvalue and (issecretvalue(cur) or issecretvalue(max)) then
        return nil
    end
    if max <= 0 then
        return nil
    end
    return cur / max * 100
end


function C.DurabilityColour(pct)
    if pct < 20 then
        return RED
    elseif pct < 50 then
        return ORANGE
    end
    return WHITE_TEXT
end

local function Coin(amount, icon, color)
    return string.format("|cff%s%d|r|TInterface\\MoneyFrame\\%s:0:0:0:0|t", color, amount, icon)
end



function C.Money(cost)
    cost = math.floor(cost)
    local gold, silver, copper = math.floor(cost / 10000), math.floor((cost % 10000) / 100), cost % 100
    local out = {}
    if gold > 0 then out[#out + 1] = Coin(gold, "UI-GoldIcon", "ffd700") end
    if silver > 0 then out[#out + 1] = Coin(silver, "UI-SilverIcon", "ffffff") end
    if copper > 0 or #out == 0 then out[#out + 1] = Coin(copper, "UI-CopperIcon", "eda55f") end
    return table.concat(out, " ")
end


function C.EnchantTime(ms)
    local seconds = math.max(0, math.floor(ms / 1000))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end




local function RepairCost(slots)
    if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then
        return nil
    end
    local total = 0
    for _, slot in ipairs(slots) do
        local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)
        local cost = ok and type(data) == "table" and data.repairCost
        if type(cost) == "number" and not (issecretvalue and issecretvalue(cost)) then
            total = total + cost
        end
    end
    if total > 0 then
        return total
    end
    return nil
end

local function SlotItemID(slot)
    return GetInventoryItemID and GetInventoryItemID("player", slot) or nil
end




function C:BuildUpkeep()
    local entries, lines = {}, {}
    local function Add(entry)
        entries[#entries + 1] = entry
        lines[#lines + 1] = { entry = entry }
    end
    local worn = {}
    for slot = 1, 18 do
        local pct = C.Durability(slot)
        
        
        
        if pct and pct < 100 then
            worn[#worn + 1] = { slot = slot, pct = pct }
        end
    end
    table.sort(worn, function(a, b)
        if a.pct ~= b.pct then
            return a.pct < b.pct
        end
        return a.slot < b.slot
    end)
    local slots = {}
    for _, info in ipairs(worn) do
        slots[#slots + 1] = info.slot
        local name = C.SlotLabel(C.SlotName(info.slot))
        Add{
            label = name, value = string.format("%d %%", math.floor(info.pct)), valueColor = C.DurabilityColour(info.pct),
            item = { kind = "upkeep", key = "durability" .. info.slot, name = name, equipSlot = info.slot,
                itemID = SlotItemID(info.slot), slot = info.slot },
        }
    end
    local cost = RepairCost(slots)
    if cost then
        Add{
            label = "Repair cost", value = C.Money(cost),
            item = { kind = "upkeep", key = "repair", name = "Repair cost", text = C.Money(cost) },
        }
    end
    if GetWeaponEnchantInfo then
        local ok, hasMain, mainMs, _, _, hasOff, offMs = pcall(GetWeaponEnchantInfo)
        if ok then
            for _, e in ipairs({ { 16, hasMain, mainMs }, { 17, hasOff, offMs } }) do
                local slot, has, ms = e[1], e[2], e[3]
                if has and type(ms) == "number" and not (issecretvalue and issecretvalue(ms)) then
                    
                    
                    
                    local name = C.SlotLabel(C.SlotName(slot)) .. ": Temporary enchant"
                    Add{
                        label = name, value = C.EnchantTime(ms),
                        item = { kind = "upkeep", key = "enchant" .. slot, name = name, enchantSlot = slot,
                            text = C.EnchantTime(ms) },
                    }
                end
            end
        end
    end
    if SlotItemID(18) then
        local count = GetInventoryItemCount and GetInventoryItemCount("player", 0)
        if SlotItemID(0) and type(count) == "number" and count > 0 then
            Add{
                label = "Ammo", value = tostring(count),
                item = { kind = "upkeep", key = "ammo", name = "Ammo", equipSlot = 0, itemID = SlotItemID(0), slot = 0 },
            }
        else
            Add{
                label = "Ammo", value = "No ammo", valueColor = RED,
                item = { kind = "upkeep", key = "ammo", name = "Ammo", noAmmo = true },
            }
        end
    end
    return { entries = entries, lines = lines }
end



function C:DescribeUpkeep(item)
    if item.equipSlot then
        return FS:Lines({ kind = "equip", slot = item.equipSlot, itemID = item.itemID,
            slotName = C.SlotName(item.equipSlot) })
    end
    if item.noAmmo then
        return "Ammo", { { leftText = "No ammo equipped" } }
    end
    if item.enchantSlot then
        return item.name, {
            { leftText = "Temporary enchant" },
            { leftText = "Time left " .. item.text },
            { leftText = C.SlotLabel(C.SlotName(item.enchantSlot)), leftColor = FS.MUTED },
        }
    end
    return item.name, { { leftText = item.text or item.name } }
end


function C:DescribeRow(item)
    if item.kind == "stat" then
        return self:DescribeStat(item)
    end
    return self:DescribeUpkeep(item)
end

function C:build(column)
    if self.frame then
        return
    end
    self.frame = CreateFrame("Frame", nil, column)
    self.frame:SetAllPoints(column)
    self.cells = {}
    self.byID = {}
    self.entries = {}
    self.chestCells = {}
    self.chestEntries = {}
    self.chestScroll = { offset = 0, rows = CHEST_ROWS, cols = 6 }
    self.cell = 44
    self.chestTop = 500
    self.glyphs = nil
    self.tabs = {}
    self.rows = {}
    self.lists = { stats = { entries = {}, lines = {} }, upkeep = { entries = {}, lines = {} } }
    
    
    self.listScroll = { offset = 0, rows = 10, cols = 1 }
    self.listTop = 80
    self.rowHeight = 26

    self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetText("Character")
    self.name = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.level = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.ilvl = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    for _, fontString in ipairs({ self.name, self.level, self.ilvl }) do
        fontString:SetJustifyH("CENTER")
        fontString:SetWordWrap(false)
    end
    self.chestTitle = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.noGear = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.noGear:SetText("No spare gear.")
    self.empty = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.empty:SetTextColor(FS.MUTED.r, FS.MUTED.g, FS.MUTED.b)
    self.empty:SetJustifyH("LEFT")
    self.empty:Hide()

    
    
    for _, tab in ipairs(TABS) do
        local b = CreateFrame("Frame", nil, self.frame)
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.label:SetAllPoints(b)
        b.label:SetText(TAB_LABELS[tab])
        b.underline = b:CreateTexture(nil, "OVERLAY")
        b.underline:SetColorTexture(FS.GOLD[1], FS.GOLD[2], FS.GOLD[3], 1)
        b.underline:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
        b.underline:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
        b.underline:SetHeight(2)
        self.tabs[tab] = b
    end
    self.glyphs = FS.TabGlyphs(self.frame)

    
    
    for _, name in ipairs(names) do
        local ok, id, empty = pcall(GetInventorySlotInfo, name)
        if ok and id ~= nil then
            local b = FS.NewCell(self.frame)
            b.id = id
            b.slotName = name
            b.emptyTexture = empty
            
            
            
            
            
            b.ilvlText = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            b.ilvlText:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
            b.pip = b:CreateTexture(nil, "OVERLAY")
            b.pip:SetSize(8, 8)
            b.pip:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
            b.pip:Hide()
            b:Show()
            self.cells[#self.cells + 1] = b
            self.byID[id] = b
        end
    end
    self:BuildModel()
end

local function Place(b, parent, x, y, size)
    if not b then
        return
    end
    b:ClearAllPoints()
    b:SetSize(size, size)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
end




function C:Layout(width, height, size, cell)
    if not self.frame then
        return
    end
    local gap = FS.GAP
    local framed = FS.Framed()
    local SK = FS.SK
    
    
    local rowGap = framed and SK.ROW_GAP or ROW_GAP
    local rowStep = cell + rowGap
    local titleH = FS.HeaderHeight(size)
    local small = math.max(size - 4, 8)
    self.cell = cell
    self.framed = framed
    self.rowGap = rowGap

    self.title:SetFont(STANDARD_TEXT_FONT, size + 6)
    self.title:ClearAllPoints()
    if not (framed and FS:TitleOnPlate(self.title, "left", size + 6)) then
        self.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    end

    
    local tabH = FS.TabHeight(size)
    local first, last = FS.PlaceTabGlyphs(self.glyphs, self.frame, width, titleH, tabH, size)
    local tabW = math.floor((last - first - (#TABS - 1) * gap) / #TABS)
    for i, tab in ipairs(TABS) do
        local b = self.tabs[tab]
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", self.frame, "TOPLEFT", first + (i - 1) * (tabW + gap), -titleH)
        b:SetSize(tabW, tabH)
        b.label:SetFont(STANDARD_TEXT_FONT, size)
    end
    local top = titleH + tabH + (framed and 6 or 8)
    self.size = size
    self.rowHeight = size + 8
    
    
    local wp = framed and SK.WELL_PAD or 0
    self.listX0 = wp
    self.listTop = top + wp
    self.listScroll.rows = math.max(1, math.floor((height - top - 2 * wp) / self.rowHeight))
    self.width = width - 2 * wp - (framed and (SK.SCROLL_W + SK.SCROLL_GAP) or 0)
    self.empty:SetFont(STANDARD_TEXT_FONT, size)
    self.empty:ClearAllPoints()
    self.empty:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4 + wp, -(top + wp))
    local tiny = math.max(size - 6, 9)
    for _, b in ipairs(self.cells) do
        b.ilvlText:SetFont(STANDARD_TEXT_FONT, tiny, "OUTLINE")
    end

    for row = 1, 8 do
        local y = -(top + (row - 1) * rowStep)
        Place(self.byID[LEFT_IDS[row] ], self.frame, 0, y, cell)
        Place(self.byID[RIGHT_IDS[row] ], self.frame, width - cell, y, cell)
    end
    local bottomWidth = 4 * cell + 3 * rowGap
    local bottomX = math.floor((width - bottomWidth) / 2)
    for i, id in ipairs(BOTTOM_IDS) do
        Place(self.byID[id], self.frame, bottomX + (i - 1) * rowStep, -(top + 8 * rowStep), cell)
    end

    
    
    
    self:LayoutModel(width, top, rowStep, cell)
    local sideWidth = math.max(bottomX - 8, 1)
    local textY = -(top + 8 * rowStep)
    self.name:SetFont(STANDARD_TEXT_FONT, size + 6)
    self.level:SetFont(STANDARD_TEXT_FONT, size)
    self.ilvl:SetFont(STANDARD_TEXT_FONT, size)
    self.name:SetJustifyH("RIGHT")
    self.level:SetJustifyH("RIGHT")
    self.ilvl:SetJustifyH("LEFT")
    self.name:ClearAllPoints()
    self.name:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, textY)
    self.name:SetWidth(sideWidth)
    self.level:ClearAllPoints()
    self.level:SetPoint("TOPLEFT", self.name, "BOTTOMLEFT", 0, -4)
    self.level:SetWidth(sideWidth)
    self.ilvl:ClearAllPoints()
    self.ilvl:SetPoint("TOPLEFT", self.frame, "TOPLEFT", bottomX + bottomWidth + 8, textY)
    self.ilvl:SetWidth(sideWidth)

    local dollBottom = top + 9 * rowStep
    self.chestTitle:SetFont(STANDARD_TEXT_FONT, size)
    self.chestTitle:ClearAllPoints()
    if not framed then
        self.chestTitle:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -(dollBottom + gap))
        self.chestTop = dollBottom + gap + size + 8
        self.chestX0 = 0
        self.noGear:SetFont(STANDARD_TEXT_FONT, small)
        self.noGear:ClearAllPoints()
        self.noGear:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -self.chestTop)
        self.chestScroll.cols = math.max(1, math.floor((width + gap) / (cell + gap)))
        self.chestScroll.rows = CHEST_ROWS
        self.rects = nil
        return
    end
    
    
    local dividerY = top + 9 * rowStep + 4
    local plateY = dividerY + 18
    local wellTop = plateY + SK.PLATE_H + 6
    local wellH = CHEST_ROWS * cell + (CHEST_ROWS - 1) * gap + 2 * wp
    self.rects = {
        doll = { cell + 12, top, width - 2 * cell - 24, 8 * rowStep - rowGap },
        divider = { 0, dividerY, width, 12 },
        plate = { 0, plateY, math.min(220, width), SK.PLATE_H },
        chest = { 0, wellTop, width, wellH },
        list = { 0, top, width, height - top },
    }
    self.chestTop = wellTop + wp
    self.chestX0 = wp
    self.chestTitle:SetPoint("LEFT", self.frame, "TOPLEFT", 24, -(plateY + SK.PLATE_H / 2))
    self.noGear:SetFont(STANDARD_TEXT_FONT, small)
    self.noGear:ClearAllPoints()
    self.noGear:SetPoint("TOPLEFT", self.frame, "TOPLEFT", wp + 4, -self.chestTop)
    self.chestScroll.cols = math.max(1, math.floor((width - 2 * wp - SK.SCROLL_W - SK.SCROLL_GAP + gap) / (cell + gap)))
    self.chestScroll.rows = CHEST_ROWS
end





function C:Skin()
    if not self.frame then
        return
    end
    local framed = FS.Framed() and self.rects ~= nil
    local Skin = FS.Skin
    local SK = FS.SK
    if framed and not self.skin then
        local sk = {}
        local function Holder()
            return CreateFrame("Frame", nil, self.frame)
        end
        sk.doll = { holder = Holder() }
        sk.doll.scene = Skin.Piece(self.frame, "bg_doll_scene", "BACKGROUND", 1)
        sk.doll.frame = Skin.Piece(self.frame, "frame_doll", "BORDER", 1)
        sk.divider = { holder = Holder() }
        sk.divider.line = Skin.Piece(self.frame, "frame_divider", "ARTWORK", 1)
        sk.divider.jewel = Skin.Piece(self.frame, "orn_divider_jewel", "ARTWORK", 2)
        sk.plate = { holder = Holder() }
        sk.plate.plate = Skin.Piece(self.frame, "orn_subtitle_plate", "ARTWORK", 1)
        sk.chest = { holder = Holder() }
        sk.chest.bg = Skin.Piece(self.frame, "bg_well", "BACKGROUND", 1)
        sk.chest.inset = Skin.Piece(self.frame, "frame_inset", "BORDER", 1)
        sk.list = { holder = Holder() }
        sk.list.bg = Skin.Piece(self.frame, "bg_well", "BACKGROUND", 1)
        sk.list.inset = Skin.Piece(self.frame, "frame_inset", "BORDER", 1)
        for _, group in pairs(sk) do
            for _, piece in pairs(group) do
                if type(piece) == "table" and piece.parts then
                    piece:Fill(group.holder)
                end
            end
        end
        if sk.divider.jewel then
            sk.divider.jewel:Place("CENTER", sk.divider.holder, "CENTER", 0, 0, 1)
        end
        sk.chestBar = Skin.Scrollbar(self.frame)
        sk.listBar = Skin.Scrollbar(self.frame)
        self.skin = sk
    end
    local sk = self.skin
    if not sk then
        return
    end
    local gear = self.tab == "gear"
    for key, group in pairs(sk) do
        local rect = framed and self.rects[key]
        if key ~= "chestBar" and key ~= "listBar" and type(group) == "table" and group.holder then
            if rect then
                group.holder:ClearAllPoints()
                group.holder:SetPoint("TOPLEFT", self.frame, "TOPLEFT", rect[1], -rect[2])
                group.holder:SetSize(rect[3], rect[4])
            end
            local on = framed and (key == "list" and not gear or key ~= "list" and gear)
            for _, piece in pairs(group) do
                if type(piece) == "table" and piece.parts then
                    piece:SetShown(on)
                end
            end
            if group.bg and rect and on then
                group.bg:Tile(rect[3], rect[4])
            end
            if key == "doll" and group.scene and rect and on then
                group.scene:Cover(rect[3], rect[4])
            end
        end
    end
    self.chestTitle:SetShown(gear)
    if framed then
        local rect = self.rects.chest
        if sk.chestBar then
            sk.chestBar:Anchor(self.frame, rect[3] - SK.WELL_PAD - SK.SCROLL_W, -(rect[2] + SK.WELL_PAD), rect[4] - 2 * SK.WELL_PAD)
            if not gear then
                sk.chestBar.holder:Hide()
            end
        end
        local list = self.rects.list
        if sk.listBar then
            sk.listBar:Anchor(self.frame, list[3] - SK.WELL_PAD - SK.SCROLL_W, -(list[2] + SK.WELL_PAD), list[4] - 2 * SK.WELL_PAD)
            if gear then
                sk.listBar.holder:Hide()
            end
        end
        self:UpdateBars()
    else
        for _, bar in ipairs({ sk.chestBar or false, sk.listBar or false }) do
            if bar and bar.holder then
                bar.holder:Hide()
            end
        end
    end
end


function C:UpdateBars()
    local sk = self.skin
    if not (sk and FS.Framed() and self.rects) then
        return
    end
    if self.tab == "gear" then
        if sk.chestBar then
            sk.chestBar:Update(self.chestScroll.offset, self.chestScroll.rows, math.ceil(#self.chestEntries / self.chestScroll.cols))
        end
    elseif sk.listBar then
        local built = self.lists[self.tab]
        sk.listBar:Update(self.listScroll.offset, self.listScroll.rows, built and #built.lines or 0)
    end
end




function C:StyleRow(row, focused)
    local pieces = row.skinRowOn and row.skinRow
    if not pieces then
        return
    end
    local header = row.isHeader
    local which = header and pieces.head or pieces.list
    local other = header and pieces.list or pieces.head
    if other then
        other:Hide()
    end
    if which then
        local id
        if header then
            id = focused and "cmp_category_header_focused" or "cmp_category_header_normal"
        else
            id = focused and "cmp_list_row_focused" or (row.alt and "cmp_list_row_alternate" or "cmp_list_row_normal")
        end
        which:SetState(id)
        which:Show()
    end
end



function C:RenderChest()
    local state = self.chestScroll
    local entries = self.chestEntries
    local gap = FS.GAP
    local first = state.offset * state.cols + 1
    local last = math.min(#entries, first + state.rows * state.cols - 1)
    local needed = math.max(0, last - first + 1)
    local usable, short = FS.EnsurePool(self.chestCells, needed, self.frame)
    for _, entry in ipairs(entries) do
        entry.cell = nil
    end
    local shown = 0
    local step = self.cell + gap
    for i = first, last do
        local k = i - first + 1
        if k > usable then
            break
        end
        local cell = self.chestCells[k]
        cell:ClearAllPoints()
        cell:SetSize(self.cell, self.cell)
        cell:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (self.chestX0 or 0) + ((k - 1) % state.cols) * step,
            -(self.chestTop + math.floor((k - 1) / state.cols) * step))
        FS.PaintCell(cell, entries[i].item)
        entries[i].cell = cell
        shown = k
    end
    for k = shown + 1, #self.chestCells do
        self.chestCells[k]:Hide()
        self.chestCells[k].item = nil
    end
    self:UpdateBars()
    if short then
        
        
        FS:Message(SHORT_MESSAGE, "bag")
    end
end




local function SlotItemLevel(slot)
    if not (GetInventoryItemLink and C_Item and C_Item.GetDetailedItemLevelInfo) then
        return nil
    end
    local link = GetInventoryItemLink("player", slot)
    if not link then
        return nil
    end
    local ok, level = pcall(C_Item.GetDetailedItemLevelInfo, link)
    if ok and type(level) == "number" and not (issecretvalue and issecretvalue(level)) and level > 0 then
        return tostring(math.floor(level))
    end
    return nil
end



function C:ApplyTab()
    local gear = self.tab == "gear"
    for _, b in ipairs(self.cells) do
        b:SetShown(gear)
    end
    self.name:SetShown(gear)
    self.level:SetShown(gear)
    self.chestTitle:SetShown(gear)
    
    
    if self.model then
        pcall(self.model.SetShown, self.model, gear)
    end
    if not gear then
        self.ilvl:Hide()
        self.noGear:Hide()
        for _, cell in ipairs(self.chestCells) do
            cell:Hide()
        end
    end
    for tab, b in pairs(self.tabs) do
        b.label:SetAlpha(tab == self.tab and 1 or 0.65)
        b.underline:SetShown(tab == self.tab)
        FS.PaintTab(b, tab == self.tab)
    end
    
    
    self:Skin()
end




function C:NextTab(delta)
    local p = 1
    for i, tab in ipairs(TABS) do
        if tab == self.tab then
            p = i
        end
    end
    self.tab = TABS[((p - 1 + delta) % #TABS) + 1]
    self.listScroll.offset = 0
    FS.regionIndex = 1
    FS.focusIndex = 1
    FS.topItem = nil
    self:refresh()
    FS:FocusChanged()
end

function C:refresh()
    if not self.frame then
        return
    end
    self:ApplyTab()
    if self.tab == "gear" then
        self:RefreshGear()
        for _, row in ipairs(self.rows) do
            row:Hide()
        end
        self.empty:Hide()
    else
        self:RefreshList()
    end
end

function C:RefreshGear()
    local level = UnitLevel and UnitLevel("player")
    local class = UnitClass and UnitClass("player")
    self.name:SetText(UnitName("player") or "")
    self.level:SetText("Level " .. tostring(level or "?") .. (class and (" " .. class) or ""))
    if GetAverageItemLevel then
        local _, equipped = GetAverageItemLevel()
        self.ilvl:SetText("Item level " .. math.floor(equipped or 0))
        self.ilvl:Show()
    else
        self.ilvl:Hide()
    end

    self.entries = {}
    for _, b in ipairs(self.cells) do
        local id = b.id
        local itemID = GetInventoryItemID and GetInventoryItemID("player", id)
        local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", id)
        local item = {
            kind = "equip", slot = id, slotName = b.slotName, itemID = itemID,
            iconFileID = texture or b.emptyTexture,
            quality = itemID and GetInventoryItemQuality and GetInventoryItemQuality("player", id),
            empty = itemID == nil,
        }
        if id == 0 and itemID and GetInventoryItemCount then
            item.countText = GetInventoryItemCount("player", 0)
        end
        FS.PaintCell(b, item)
        
        b.ilvlText:SetText(itemID and id ~= 0 and SlotItemLevel(id) or "")
        
        
        local pct = itemID and C.Durability(id)
        local lowColour = pct and pct < 50 and C.DurabilityColour(pct) or nil
        if lowColour then
            b.pip:SetColorTexture(lowColour[1], lowColour[2], lowColour[3], 1)
            b.pip:Show()
        else
            b.pip:Hide()
        end
        
        
        
        self:DressPip(b, lowColour)
        self.entries[#self.entries + 1] = { item = item, cell = b }
    end

    local gear = FS.Bags and FS.Bags.items and FS.Bags.items.armor or {}
    self.chestTitle:SetText("Armor chest (" .. #gear .. ")")
    self.noGear:SetShown(#gear == 0)
    self.chestEntries = {}
    for i, item in ipairs(gear) do
        self.chestEntries[i] = { item = item }
    end
    FS.Scroll.Clamp(self.chestScroll, #gear)
    self:RenderChest()
end

function C:DressPip(b, colour)
    local framed = FS.Framed()
    if framed and b.pipSkin == nil then
        local piece = FS.Skin.Piece(b, "cmp_cell_badges", "OVERLAY", 4)
        if piece then
            
            piece:Cell(13)
            piece:Place("TOPRIGHT", b, "TOPRIGHT", -2, -2, 1)
            piece:SetSize(20 * (b:GetWidth() or 64) / 64, 20 * (b:GetWidth() or 64) / 64)
        end
        b.pipSkin = piece or false
    end
    local piece = b.pipSkin
    if framed and piece then
        b.pip:SetAlpha(0)
        if colour then
            piece:SetTint(colour[1], colour[2], colour[3], 1)
            piece:Show()
        else
            piece:Hide()
        end
    else
        b.pip:SetAlpha(1)
        if piece then
            piece:Hide()
        end
    end
end



function C:RefreshList()
    local tab = self.tab
    local built = tab == "stats" and self:BuildStats() or self:BuildUpkeep()
    self.lists[tab] = built
    self.listScroll.map = built.map
    FS.Scroll.Clamp(self.listScroll, #built.lines)
    self.empty:SetText(tab == "stats" and "No stats to show." or "Nothing needs attention.")
    self.empty:SetShown(#built.entries == 0)
    self:RenderList()
end

local function NewRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row.left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.left:SetPoint("LEFT", row, "LEFT", 4, 0)
    
    row.left:SetJustifyH("LEFT")
    row.left:SetWordWrap(false)
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.right:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.right:SetJustifyH("RIGHT")
    row.right:SetWordWrap(false)
    row:Hide()
    return row
end



function C:RenderList()
    local built = self.lists[self.tab]
    if not built or self.tab == "gear" then
        return
    end
    local state = self.listScroll
    local first = state.offset + 1
    local last = math.min(#built.lines, state.offset + state.rows)
    local needed = math.max(0, last - first + 1)
    for i = #self.rows + 1, needed do
        self.rows[i] = NewRow(self.frame)
    end
    for _, entry in ipairs(built.entries) do
        entry.cell = nil
    end
    local size = self.size or 18
    for k = 1, needed do
        local row = self.rows[k]
        local line = built.lines[first + k - 1]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.listX0 or 0, -(self.listTop + (k - 1) * self.rowHeight))
        row:SetSize(self.width or 300, self.rowHeight)
        row.isHeader = line.header ~= nil
        row.alt = k % 2 == 0
        self:DressRow(row)
        row.left:SetFont(STANDARD_TEXT_FONT, size)
        row.right:SetFont(STANDARD_TEXT_FONT, size)
        if line.header then
            row.left:SetText(line.header)
            row.left:SetTextColor(line.color[1], line.color[2], line.color[3])
            row.right:SetText("")
        else
            local entry = line.entry
            row.left:SetText(entry.label)
            row.left:SetTextColor(1, 1, 1)
            
            
            row.right:SetText(entry.value)
            local c = entry.valueColor or WHITE_TEXT
            row.right:SetTextColor(c[1], c[2], c[3])
            entry.cell = row
        end
        row:Show()
        self:StyleRow(row, FS.focusRow == row)
    end
    for k = needed + 1, #self.rows do
        self.rows[k]:Hide()
    end
    self:UpdateBars()
end



function C:DressRow(row)
    local framed = FS.Framed()
    if framed and row.skinRow == nil then
        local list = FS.Skin.Piece(row, "cmp_list_row_normal", "BACKGROUND", 1)
        local head = FS.Skin.Piece(row, "cmp_category_header_normal", "BACKGROUND", 2)
        if list then
            list:Fill(row)
        end
        if head then
            head:Fill(row)
        end
        row.skinRow = (list or head) and { list = list, head = head } or false
    end
    local on = framed and row.skinRow or nil
    if not on and row.skinRow then
        for _, piece in pairs(row.skinRow) do
            piece:Hide()
        end
    end
    row.left:ClearAllPoints()
    row.right:ClearAllPoints()
    local inset = on and 12 or 4
    row.left:SetPoint("LEFT", row, "LEFT", inset, 0)
    row.right:SetPoint("RIGHT", row, "RIGHT", -inset, 0)
    
    row.skinRowOn = on and true or nil
end



function C:describe(focus)
    if focus and focus.kind == "equip" and not focus.itemID then
        return { { leftText = C.SlotLabel(focus.slotName) }, { leftText = "Empty" } }
    end
end

function C:Focusables(region)
    if region == "paperdoll" then
        return self.entries
    end
    if region == "armorchest" then
        return self.chestEntries
    end
    if region == "stats" or region == "upkeep" then
        local built = self.lists and self.lists[region]
        return built and built.entries or {}
    end
    return {}
end
