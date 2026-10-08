


ThugUI = ThugUI or {}
ThugUI.EssentialRings = {}

local ER = ThugUI.EssentialRings

local TrackerFrame = CreateFrame("Frame", "ThugUI_TrackerFrame", UIParent)
local LoaderFrame = CreateFrame("Frame")

local GCD_SPELL_ID = 61304
local _, _, _, interfaceVersion = GetBuildInfo()
local CURRENT_API = interfaceVersion


ER.GCDCooldownFrame = nil
ER.GCDBackgroundFrame = nil
ER.CastFrame = nil
ER.CastBackgroundFrame = nil


ER.currentGroupScale = 1.0
ER.lastGCDTime = 0
ER.isGCDAnimating = false
ER.isCasting = false


ER.ecvOriginalPoint = nil
ER.ecvAnchored = false
ER.ecvContainer = nil
ER.ecvIcons = {}
ER.ecvUpdateTimer = 0
ER.ecvUpdateInterval = 0.15





local DebugLog = {}
DebugLog.enabled = false
DebugLog.throttle = 1.0      
DebugLog.timer = 0
DebugLog.MAX_ENTRIES = 200

local function DLog(category, msg)
    if not DebugLog.enabled then return end
    if not ThugUI_DebugLog then ThugUI_DebugLog = {} end
    local t = GetTime()
    local combat = InCombatLockdown() and "COMBAT" or "NO_COMBAT"
    
    
    if not InCombatLockdown() and category ~= "TRANSITION" then return end
    local entry = string.format("[%.1f][%s][%s] %s", t, combat, category, msg)
    table.insert(ThugUI_DebugLog, entry)
    
    while #ThugUI_DebugLog > DebugLog.MAX_ENTRIES do
        table.remove(ThugUI_DebugLog, 1)
    end
end


local function SafeStr(val)
    if val == nil then return "nil" end
    if issecretvalue and issecretvalue(val) then return "SECRET("..type(val)..")" end
    local ok, s = pcall(tostring, val)
    if ok then return s end
    return "ERROR("..type(val)..")"
end


local function DumpAuraFields(auraData)
    if not auraData then return "nil" end
    local parts = {}
    for k, v in pairs(auraData) do
        table.insert(parts, k .. "=" .. SafeStr(v))
    end
    return table.concat(parts, ", ")
end



function ER:SetDebugMode(enabled)
    enabled = not not enabled
    ThugUI_Config = ThugUI_Config or {}
    ThugUI_Config.debugMode = enabled
    DebugLog.enabled = enabled
    if enabled then
        ThugUI_DebugLog = {}  
        DebugLog.didCombatDump = false  
        print("|cff00ff00ThugUI Debug:|r Debug mode ON — aura queries will be logged.")
        print("|cff00ff00ThugUI Debug:|r Enter combat with buffs, then /reload to save log; /thuglog to view.")
    else
        print("|cff00ff00ThugUI Debug:|r Debug mode OFF.")
    end
    if ER.debugModeCheckbox then
        ER.debugModeCheckbox:SetChecked(enabled)
    end
end

SLASH_THUGDEBUG1 = "/thugdebug"
SlashCmdList["THUGDEBUG"] = function()
    ER:SetDebugMode(not (ThugUI_Config and ThugUI_Config.debugMode))
end

SLASH_THUGLOG1 = "/thuglog"
SlashCmdList["THUGLOG"] = function(msg)
    if not ThugUI_DebugLog or #ThugUI_DebugLog == 0 then
        print("|cff00ff00ThugUI Debug:|r No log entries. Use /thugdebug to enable.")
        return
    end
    local count = tonumber(msg) or 20
    local start = math.max(1, #ThugUI_DebugLog - count + 1)
    print("|cff00ff00ThugUI Debug:|r Showing " .. (#ThugUI_DebugLog - start + 1) .. " of " .. #ThugUI_DebugLog .. " entries:")
    for i = start, #ThugUI_DebugLog do
        print(ThugUI_DebugLog[i])
    end
end











local function ProbeSpell(query)
    local entry = { query = SafeStr(query) }

    entry.texture = SafeStr(C_Spell.GetSpellTexture(query))

    local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(query)
    if info then
        entry.resolvedName = SafeStr(info.name)
        entry.resolvedID = SafeStr(info.spellID)
    else
        entry.resolvedName = "nil"
        entry.resolvedID = "nil"
    end

    local resolvedID = (info and info.spellID) or (type(query) == "number" and query) or nil
    entry.known = resolvedID and SafeStr(IsPlayerSpell and IsPlayerSpell(resolvedID)) or "n/a"

    local okC, cd = pcall(C_Spell.GetSpellCooldown, query)
    if okC and cd then
        entry.cdIsActive = SafeStr(cd.isActive)
        entry.cdIsOnGCD  = SafeStr(cd.isOnGCD)
        entry.cdStart    = SafeStr(cd.startTime)
        entry.cdDuration = SafeStr(cd.duration)
    else
        entry.cooldown = okC and "nil" or ("pcall failed " .. SafeStr(cd))
    end

    local okCh, ch = pcall(C_Spell.GetSpellCharges, query)
    if okCh and ch then
        entry.chCurrent  = SafeStr(ch.currentCharges)
        entry.chMax      = SafeStr(ch.maxCharges)
        entry.chCdStart  = SafeStr(ch.cooldownStartTime)
        entry.chCdLength = SafeStr(ch.cooldownDuration)
    else
        entry.charges = okCh and "nil (not a charge spell)" or ("pcall failed " .. SafeStr(ch))
    end

    return entry
end





local function TestAuraRead(id)
    local r = { id = SafeStr(id) }
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
        r.result = "API missing"
        return r
    end
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
    if not ok then
        r.result = "pcall failed: " .. SafeStr(aura)
        return r
    end
    if not aura then
        r.result = "nil (not present, or blocked in combat)"
        return r
    end
    r.result      = "TABLE returned"
    r.nameSecret  = SafeStr(issecretvalue and issecretvalue(aura.name))
    r.iconSecret  = SafeStr(issecretvalue and issecretvalue(aura.icon))
    r.iconValue   = SafeStr(aura.icon)
    
    local eqOk = pcall(function() return aura.icon == 0 end)
    r.iconComparable = eqOk and "yes" or "no (secret)"
    return r
end




local AURA_READ_IDS = { 48517, 48518, 393944, 393942, 450360, 1126, 24858 }



local BCV_PROBE_LIST = {
    "Eclipse", "Eclipse (Solar)", "Eclipse (Lunar)",
    "Starweaver's Weft", "Starweaver's Warp", "Touch the Cosmos",
    "Starsurge", "Starfall",
    48517, 48518, 393944, 393942, 450360,
}




SLASH_THUGBCV1 = "/thugbcv"
SlashCmdList["THUGBCV"] = function()
    ThugUI_BCVDump = {
        capturedAt = date and date("%Y-%m-%d %H:%M:%S") or SafeStr(GetTime()),
        inCombat = InCombatLockdown() and "yes" or "no",
        buffs = {},
        spellProbes = {},
        auraReadTests = {},
    }

    
    local i = 1
    while i <= 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end
        table.insert(ThugUI_BCVDump.buffs, {
            index  = i,
            name   = SafeStr(aura.name),
            id     = SafeStr(aura.spellId),
            icon   = SafeStr(aura.icon),
            stacks = SafeStr(aura.applications),
        })
        i = i + 1
    end

    
    for _, q in ipairs(BCV_PROBE_LIST) do
        table.insert(ThugUI_BCVDump.spellProbes, ProbeSpell(q))
    end

    
    for _, id in ipairs(AURA_READ_IDS) do
        table.insert(ThugUI_BCVDump.auraReadTests, TestAuraRead(id))
    end

    print(string.format("|cff00ff00ThugUI BCV:|r captured %d buffs + %d probes to ThugUI_BCVDump. "
        .. "Now /reload (or log out) to write it to disk.",
        #ThugUI_BCVDump.buffs, #ThugUI_BCVDump.spellProbes))
end


SLASH_THUGSPELL1 = "/thugspell"
SlashCmdList["THUGSPELL"] = function(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""
    if msg == "" then
        print("|cff00ff00ThugUI Spell:|r usage — /thugspell <spell name or id>")
        return
    end
    ThugUI_BCVDump = ThugUI_BCVDump or { buffs = {}, spellProbes = {} }
    ThugUI_BCVDump.spellProbes = ThugUI_BCVDump.spellProbes or {}
    local query = tonumber(msg) or msg
    table.insert(ThugUI_BCVDump.spellProbes, ProbeSpell(query))
    print("|cff00ff00ThugUI Spell:|r probed '" .. msg .. "' into ThugUI_BCVDump. /reload to flush.")
end



ER.ecvSpellNames = {
    "Wild Growth",
    "Swiftmend",
    "Nature's Swiftness",
    "Ironbark",
    "Convoke the Spirits",
    "Tranquility",
}


ER.defaults = {
    scale = 1.0,
    innerRing = "GCD",
    mainRing = "Main Ring",
    outerRing = "Cast",
    
    
    reticleColorMode = "default",
    reticleCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    mainRingColorMode = "default",
    mainRingCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    gcdColorMode = "default",
    gcdCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    castColorMode = "default",
    castCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    
    showOnlyInCombat = false,
    hideGameCursor = false,
    reticle = "Dot",
    reticleScale = 1.5,
    transparency = 1.0,

    
    
    
    
    
    mainRingThickness = 18,
    gcdRingThickness = 18,
    castRingThickness = 18,
    resourceRingThickness = 18,
    
    
    gcdFillDrain = "fill",
    castFillDrain = "fill",
    gcdRotation = 12,
    castRotation = 12,
    
    
    showECV = false,
    anchorECVToCursor = false,
    ecvShowOnlyInCombat = false,
    ecvPoint = nil,  
    ecvScale = 1.0,
    ecvAnchorCorner = "TOPLEFT",  
    ecvShowAbundance = true,
    ecvAbundanceCorner = "TOPLEFT",
    ecvAbundanceScale = 1.0,
    ecvShowReforestation = true,
    ecvReforestationCorner = "TOPRIGHT",
    ecvReforestationScale = 1.0,
    ecvShowClearcasting = true,
    ecvClearcastingCorner = "BOTTOMLEFT",
    ecvClearcastingScale = 1.0,

    
    anchorBuffFrameToCursor = false,
    buffFrameCorner = "BOTTOMRIGHT",
    buffFrameScale = 1.0,

    
    
    
    
    
    
    
    
    
    
    
    
    

    
    
    showBCV = false,
    bcvShowOnlyInCombat = false,
    anchorBCVToCursor = false,
    bcvAnchorCorner = "TOPLEFT",
    bcvScale = 1.0,
    bcvPoint = nil,  
    bcvShowStarsurgeProc = true,

    
    
    showGCV = false,
    gcvShowOnlyInCombat = false,
    anchorGCVToCursor = false,
    gcvAnchorCorner = "TOPLEFT",
    gcvScale = 1.0,
    gcvPoint = nil,  

    
    
    
    
    showResourceRing = false,
    resourceRingColorMode = "power",  
    resourceRingCustomColor = {r = 0.3, g = 0.5, b = 0.9},
    resourceRingAlpha = 0.55,
    
    
    
    resourceRingVisibility = "always",
    
    
    
    
    
    
    
    
    
    
    resourceRingDrainDirection = "clockwise",
    
    
    
    
    
    
    
    
    resourceRingRotation = 12,

    
    testMode = false,

    
    
    debugMode = false,

    
    
    
    hideStanceBar = true,
    hideBagButtons = true,
    hideCharacterFrame = false,
    hideCastBar = false,

    
    hideShardNotice = false,
    shardNoticePoint = nil,  

}


function ER:IsInCombat()
    return InCombatLockdown() or (ThugUI_Config.testMode == true)
end







local DRUID_SPEC_BALANCE = 1
local DRUID_SPEC_GUARDIAN = 3
local DRUID_SPEC_RESTORATION = 4

function ER:IsDruid()
    local _, class = UnitClass("player")
    return class == "DRUID"
end

function ER:GetActiveSpecIndex()
    if not GetSpecialization then return nil end
    return GetSpecialization()
end

function ER:IsRestoSpec()
    return ER:IsDruid() and ER:GetActiveSpecIndex() == DRUID_SPEC_RESTORATION
end

function ER:IsBalanceSpec()
    return ER:IsDruid() and ER:GetActiveSpecIndex() == DRUID_SPEC_BALANCE
end

function ER:IsGuardianSpec()
    return ER:IsDruid() and ER:GetActiveSpecIndex() == DRUID_SPEC_GUARDIAN
end








function ER:LegacyBarsActive()
    return ThugUI_Config and ThugUI_Config.cvUseLegacy and true or false
end


ER.cursorHidden = false
ER.emptyCursorPath = "Interface\\AddOns\\ThugUI\\media\\Empty_Cursor"


ER.ringOptions = {
    "None",
    "Main Ring",
    "GCD",
    "Cast",
}


ER.reticleOptions = {
    "Dot",
    "Chevron",
    "Crosshair",
    "Diamond",
    "Flatline",
    "Star",
    "Ring",
    "Tech Arrow",
    "X",
    "No Reticle",
}

ER.reticleTextures = {
    ["Dot"] = { path = "Interface\\AddOns\\ThugUI\\media\\Reticle_Dot", scale = 0.5 },
    ["Chevron"] = { path = "uitools-icon-chevron-down", scale = 1.0, isAtlas = true },
    ["Crosshair"] = { path = "uitools-icon-plus", scale = 1.0, isAtlas = true },
    ["Diamond"] = { path = "UF-SoulShard-FX-FrameGlow", scale = 1.0, isAtlas = true },
    ["Flatline"] = { path = "uitools-icon-minus", scale = 1.0, isAtlas = true },
    ["Star"] = { path = "AftLevelup-WhiteStarBurst", scale = 2.0, isAtlas = true },
    ["Ring"] = { path = "Interface\\AddOns\\ThugUI\\media\\Reticle_Circle", scale = 1.0 },
    ["Tech Arrow"] = { path = "ProgLan-w-4", scale = 1.0, isAtlas = true },
    ["X"] = { path = "uitools-icon-close", scale = 1.0, isAtlas = true },
    ["No Reticle"] = { path = nil, scale = 1.0 },
}

function ER:GetClassColor(ringType)
    local colorMode = "default"
    local customColor = nil
    
    if ringType == "main" then
        colorMode = ThugUI_Config.mainRingColorMode or "default"
        customColor = ThugUI_Config.mainRingCustomColor
    elseif ringType == "gcd" then
        colorMode = ThugUI_Config.gcdColorMode or "default"
        customColor = ThugUI_Config.gcdCustomColor
    elseif ringType == "cast" then
        colorMode = ThugUI_Config.castColorMode or "default"
        customColor = ThugUI_Config.castCustomColor
    elseif ringType == "reticle" then
        colorMode = ThugUI_Config.reticleColorMode or "default"
        customColor = ThugUI_Config.reticleCustomColor
    end
    
    
    if colorMode == "custom" and customColor then
        return customColor.r or 1.0, customColor.g or 1.0, customColor.b or 1.0
    end
    
    
    if colorMode == "class" then
        local _, class = UnitClass("player")
        local classColor = C_ClassColor.GetClassColor(class)
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    end

    
    return 1.0, 1.0, 1.0
end














ER.RING_THICKNESS_DEFAULT = 18
ER.RING_THICKNESS_MIN, ER.RING_THICKNESS_MAX, ER.RING_THICKNESS_STEP = 6, 66, 3



ER.RING_THICKNESS_KEYS = {
    main = "mainRingThickness",
    gcd = "gcdRingThickness",
    cast = "castRingThickness",
    resource = "resourceRingThickness",
}


function ER:GetRingTexture(ring)
    local key = ER.RING_THICKNESS_KEYS[ring] or ER.RING_THICKNESS_KEYS.main
    
    
    
    local t = ThugUI_Config[key] or ThugUI_Config.ringThickness
    if not t or t == ER.RING_THICKNESS_DEFAULT then
        return "Interface\\AddOns\\ThugUI\\media\\Ring_Main"
    end
    
    
    
    t = math.floor((t - ER.RING_THICKNESS_MIN) / ER.RING_THICKNESS_STEP + 0.5)
        * ER.RING_THICKNESS_STEP + ER.RING_THICKNESS_MIN
    if t < ER.RING_THICKNESS_MIN then t = ER.RING_THICKNESS_MIN end
    if t > ER.RING_THICKNESS_MAX then t = ER.RING_THICKNESS_MAX end
    if t == ER.RING_THICKNESS_DEFAULT then
        return "Interface\\AddOns\\ThugUI\\media\\Ring_Main"
    end
    return string.format("Interface\\AddOns\\ThugUI\\media\\rings\\Ring_T%02d", t)
end




function ER:ApplyRingThickness()
    if ThugUI_CursorFrame and ThugUI_CursorFrame.MainRing then
        ThugUI_CursorFrame.MainRing:SetTexture(ER:GetRingTexture("main"))
    end
    local swipes = {
        GCDBackgroundFrame = "gcd", GCDCooldownFrame = "gcd",
        CastBackgroundFrame = "cast", CastFrame = "cast",
    }
    for key, ring in pairs(swipes) do
        local f = ER[key]
        if f and f.SetSwipeTexture then f:SetSwipeTexture(ER:GetRingTexture(ring)) end
    end
    if ThugUI.ResourceRing and ThugUI.ResourceRing.ApplyTexture then
        ThugUI.ResourceRing:ApplyTexture()
    end
end

function ER:ClockToRadians(clockPosition)
    
    
    local position = (clockPosition == 12) and 0 or clockPosition
    return (position * math.pi / 6)
end

function ER:UpdateRingColors()
    
    if ER.GCDCooldownFrame then
        local r, g, b = ER:GetClassColor("gcd")
        ER.GCDCooldownFrame:SetSwipeColor(r, g, b, 1.0)
    end

    
    if ER.CastFrame then
        local r, g, b = ER:GetClassColor("cast")
        ER.CastFrame:SetSwipeColor(r, g, b, 1.0)
    end

    
    if ThugUI_CursorFrame and ThugUI_CursorFrame.MainRing then
        local r, g, b = ER:GetClassColor("main")
        ThugUI_CursorFrame.MainRing:SetVertexColor(r, g, b, 1.0)
    end
end

function ER:UpdateReticle()
    if not ThugUI_CursorFrame or not ThugUI_CursorFrame.Reticle then return end
    
    local reticleName = ThugUI_Config.reticle or "Dot"
    local reticleInfo = ER.reticleTextures[reticleName]
    
    if not reticleInfo or not reticleInfo.path then
        
        ThugUI_CursorFrame.Reticle:Hide()
    else
        ThugUI_CursorFrame.Reticle:Show()
        
        if reticleInfo.isAtlas then
            ThugUI_CursorFrame.Reticle:SetAtlas(reticleInfo.path)
        else
            ThugUI_CursorFrame.Reticle:SetTexture(reticleInfo.path)
        end
        
        
        local globalScale = ThugUI_Config.reticleScale or 1.0
        ThugUI_CursorFrame.Reticle:SetScale(reticleInfo.scale * globalScale)
        
        
        local r, g, b = ER:GetClassColor("reticle")
        ThugUI_CursorFrame.Reticle:SetVertexColor(r, g, b, 1.0)
    end
end

function ER:SetGroupScale(scale)
    if type(scale) == "number" and scale > 0 then
        ER.currentGroupScale = scale
        ThugUI_CursorFrame:SetScale(scale)
    end
end

function ER:OnUpdate(elapsed)
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetScale()
    local groupScale = ER.currentGroupScale

    local correctedX = (cursorX / uiScale) / groupScale
    local correctedY = (cursorY / uiScale) / groupScale

    ThugUI_CursorFrame:ClearAllPoints()
    ThugUI_CursorFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", correctedX, correctedY)
    
    
    ER:UpdateECVPosition()
    
    ER:UpdateAbundancePosition()
    ER:UpdateReforestationPosition()
    ER:UpdateClearcastingPosition()
    
    ER:UpdateBuffFramePosition()
    
    ER:UpdateBCVPosition()
    
    ER:UpdateGCVPosition()

    
    
    ER.ecvUpdateTimer = ER.ecvUpdateTimer + elapsed
    if ER.ecvUpdateTimer >= ER.ecvUpdateInterval then
        ER.ecvUpdateTimer = 0

        
        DebugLog.timer = DebugLog.timer + ER.ecvUpdateInterval
        local wasEnabled = DebugLog.enabled
        if DebugLog.enabled and DebugLog.timer < DebugLog.throttle then
            DebugLog.enabled = false  
        elseif wasEnabled then
            DebugLog.timer = 0
            
            DLog("STATE", "container=" .. (ER.ecvContainer and (ER.ecvContainer:IsShown() and "SHOWN" or "HIDDEN") or "NIL")
                .. " testMode=" .. tostring(ThugUI_Config.testMode)
                .. " showECV=" .. tostring(ThugUI_Config.showECV)
                .. " combatOnly=" .. tostring(ThugUI_Config.ecvShowOnlyInCombat))
        end

        ER:UpdateECVCooldowns()
        ER:UpdateAbundanceStacks()
        ER:UpdateReforestationStacks()
        ER:UpdateClearcastingTimer()
        ER:UpdateBCVCooldowns()
        ER:UpdateGCVCooldowns()

        
        if wasEnabled then DebugLog.enabled = true end
    end

    
    ER:UpdateCursorVisibility()
end


function ER:UpdateCursorVisibility()
    if not ThugUI_Config.hideGameCursor then
        
        if ER.cursorHidden then
            ER:RestoreGameCursor()
        end
        return
    end
    
    
    local ringsVisible = ThugUI_CursorFrame and ThugUI_CursorFrame:IsShown()
    
    if ringsVisible and not ER.cursorHidden then
        ER:HideGameCursor()
    elseif not ringsVisible and ER.cursorHidden then
        ER:RestoreGameCursor()
    end
end

function ER:HideGameCursor()
    SetCursor(ER.emptyCursorPath)
    ER.cursorHidden = true
end

function ER:RestoreGameCursor()
    SetCursor(nil) 
    ER.cursorHidden = false
end








local function IsSpellReady(spellName)
    
    local ok, chargeInfo = pcall(C_Spell.GetSpellCharges, spellName)
    if ok and chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1 then
        local current = chargeInfo.currentCharges
        if current ~= nil and not (issecretvalue and issecretvalue(current)) then
            return current > 0
        end
        
    end

    
    local ok2, cdInfo = pcall(C_Spell.GetSpellCooldown, spellName)
    if ok2 and cdInfo then
        
        
        if cdInfo.isOnGCD then
            return true
        end
        if cdInfo.isActive then
            return false 
        end
    end

    return true
end

function ER:CreateECV()
    if ER.ecvContainer then return end

    
    
    
    
    
    
    
    
    local f = CreateFrame("Frame", "ThugUI_EssentialCooldownViewer", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)
    ER.ecvContainer = f

    local iconSize = 32
    local padding = 4
    local index = 0

    for _, spellName in ipairs(ER.ecvSpellNames) do
        local texture = C_Spell.GetSpellTexture(spellName)
        if texture then
            local icon = CreateFrame("Frame", nil, f)
            icon:SetSize(iconSize, iconSize)

            local bg = icon:CreateTexture(nil, "BACKGROUND")
            bg:SetPoint("TOPLEFT", -1, 1)
            bg:SetPoint("BOTTOMRIGHT", 1, -1)
            bg:SetColorTexture(0, 0, 0, 0.8)

            local tex = icon:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture(texture)
            tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            icon.tex = tex

            icon.spellName = spellName
            icon:SetPoint("TOPLEFT", f, "TOPLEFT",
                index * (iconSize + padding), 0)

            table.insert(ER.ecvIcons, icon)
            index = index + 1
        end
    end

    
    local totalW = math.max(index * (iconSize + padding) - padding, 1)
    f:SetSize(totalW, iconSize)

    
    local saved = ThugUI_Config.ecvPoint
    if saved then
        f:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
    end

    
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        
        local point, _, relPoint, x, y = self:GetPoint()
        ThugUI_Config.ecvPoint = {
            point = point, relPoint = relPoint,
            x = x, y = y,
        }
    end)

    
    local function CreateTrackerIcon(frameName, iconTexture, defaultScale)
        local size = 32
        local frame = CreateFrame("Frame", frameName, UIParent)
        frame:SetSize(size, size)
        frame:SetFrameStrata("HIGH")
        frame:SetFrameLevel(15)
        frame:SetScale(defaultScale or 1.0)

        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", -1, 1)
        bg:SetPoint("BOTTOMRIGHT", 1, -1)
        bg:SetColorTexture(0, 0, 0, 0.8)

        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(iconTexture)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        frame.tex = tex

        local cd = CreateFrame("Cooldown", frameName .. "Cooldown", frame, "CooldownFrameTemplate")
        cd:SetAllPoints()
        cd:SetDrawEdge(true)
        cd:SetDrawSwipe(true)
        cd:SetSwipeColor(0, 0, 0, 0.6)
        cd:SetHideCountdownNumbers(false)
        frame.cooldown = cd

        frame:Hide()
        return frame
    end

    
    ER.ecvAbundanceFrame = CreateTrackerIcon("ThugUI_AbundanceTracker", 132124,
        ThugUI_Config.ecvAbundanceScale or 1.0)

    
    ER.ecvReforestationFrame = CreateTrackerIcon("ThugUI_ReforestationTracker", 1416160,
        ThugUI_Config.ecvReforestationScale or 1.0)

    
    ER.ecvClearcastingFrame = CreateTrackerIcon("ThugUI_ClearcastingTracker", 136170,
        ThugUI_Config.ecvClearcastingScale or 1.0)

    
    f:SetScale(ThugUI_Config.ecvScale or 1.0)

    
    ER:UpdateECVVisibility()
end


local function PositionFrameAtCursor(frame, cornerSetting, gap)
    if not frame or not frame:IsShown() then return end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    local x = cursorX / uiScale
    local y = cursorY / uiScale

    local corner = cornerSetting or "TOPLEFT"
    gap = gap or 12

    local anchor, ofsX, ofsY
    if corner == "TOPLEFT" then
        anchor = "BOTTOMRIGHT"
        ofsX, ofsY = -gap, gap
    elseif corner == "TOPRIGHT" then
        anchor = "BOTTOMLEFT"
        ofsX, ofsY = gap, gap
    elseif corner == "BOTTOMLEFT" then
        anchor = "TOPRIGHT"
        ofsX, ofsY = -gap, -gap
    elseif corner == "BOTTOMRIGHT" then
        anchor = "TOPLEFT"
        ofsX, ofsY = gap, -gap
    end

    frame:ClearAllPoints()
    frame:SetPoint(anchor, UIParent, "BOTTOMLEFT", x + ofsX, y + ofsY)
end

function ER:UpdateAbundancePosition()
    PositionFrameAtCursor(ER.ecvAbundanceFrame, ThugUI_Config.ecvAbundanceCorner, 12)
end

function ER:UpdateReforestationPosition()
    PositionFrameAtCursor(ER.ecvReforestationFrame, ThugUI_Config.ecvReforestationCorner, 12)
end

function ER:UpdateClearcastingPosition()
    PositionFrameAtCursor(ER.ecvClearcastingFrame, ThugUI_Config.ecvClearcastingCorner, 12)
end
















function ER:UpdateBuffFramePosition()
    if not ThugUI_Config.anchorBuffFrameToCursor then return end

    local buffFrame = _G["BuffIconCooldownViewer"]
    if not buffFrame then return end

    
    if not ER:IsInCombat() then
        if ER.buffFrameAnchored then
            buffFrame:SetScale(1.0)
            
            if buffFrame.UpdateSystem then
                pcall(buffFrame.UpdateSystem, buffFrame)
            elseif EditModeManagerFrame and EditModeManagerFrame.LayoutApplied then
                pcall(EditModeManagerFrame.LayoutApplied, EditModeManagerFrame)
            end
            ER.buffFrameAnchored = false
        end
        return
    end

    local scale = ThugUI_Config.buffFrameScale or 1.0
    buffFrame:SetScale(scale)
    ER.buffFrameAnchored = true

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    
    local x = cursorX / uiScale / scale
    local y = cursorY / uiScale / scale

    local corner = ThugUI_Config.buffFrameCorner or "BOTTOMRIGHT"
    local gap = 16 / scale

    
    
    local anchor, ofsX, ofsY
    if corner == "TOPLEFT" then
        anchor = "BOTTOMRIGHT"; ofsX, ofsY = -gap, gap
    elseif corner == "TOPRIGHT" then
        anchor = "BOTTOMLEFT"; ofsX, ofsY = gap, gap
    elseif corner == "BOTTOMLEFT" then
        anchor = "TOPRIGHT"; ofsX, ofsY = -gap, -gap
    elseif corner == "BOTTOMRIGHT" then
        anchor = "TOPLEFT"; ofsX, ofsY = gap, -gap
    end

    buffFrame:ClearAllPoints()
    buffFrame:SetPoint(anchor, UIParent, "BOTTOMLEFT", x + ofsX, y + ofsY)
end














local function GetAuraInfo(spellID, spellName)
    local logging = DebugLog.enabled

    
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, auraData = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if logging then
            if not ok then
                DLog("AURA", spellName .. " M1-GetBySpellID: pcall FAILED, err=" .. SafeStr(auraData))
            elseif not auraData then
                DLog("AURA", spellName .. " M1-GetBySpellID: returned NIL (buff not active or blocked)")
            else
                DLog("AURA", spellName .. " M1-GetBySpellID: GOT DATA — " .. DumpAuraFields(auraData))
            end
        end
        if ok and auraData then
            return auraData.applications or 0, auraData.expirationTime or 0, true
        end
    end

    
    if spellName and AuraUtil and AuraUtil.FindAuraByName then
        local ok, name, icon, count, debuffType, duration, expirationTime =
            pcall(AuraUtil.FindAuraByName, spellName, "player", "HELPFUL")
        if logging then
            if not ok then
                DLog("AURA", spellName .. " M2-FindByName: pcall FAILED, err=" .. SafeStr(name))
            elseif not name then
                DLog("AURA", spellName .. " M2-FindByName: returned NIL")
            else
                DLog("AURA", spellName .. " M2-FindByName: name=" .. SafeStr(name)
                    .. " count=" .. SafeStr(count) .. " dur=" .. SafeStr(duration)
                    .. " exp=" .. SafeStr(expirationTime))
            end
        end
        if ok and name then
            return count or 0, expirationTime or 0, true
        end
    end

    
    if spellName and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local i = 1
        local foundAny = false
        
        local doDump = logging and InCombatLockdown() and not DebugLog.didCombatDump and (spellName == "Abundance")
        while i <= 40 do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not auraData then break end
            foundAny = true
            if doDump then
                DLog("DUMP", "Aura#" .. i .. ": " .. DumpAuraFields(auraData))
            end
            local nameOk, nameMatch = pcall(function()
                return auraData.name == spellName
            end)
            if nameOk and nameMatch then
                if logging then
                    DLog("AURA", spellName .. " M3-IndexScan: MATCH at i=" .. i .. " — " .. DumpAuraFields(auraData))
                end
                return auraData.applications or 0, auraData.expirationTime or 0, true
            end
            i = i + 1
        end
        if doDump then DebugLog.didCombatDump = true end
        if logging then
            DLog("AURA", spellName .. " M3-IndexScan: no match in " .. (i-1) .. " auras, foundAny=" .. tostring(foundAny))
        end
    end

    return 0, 0, false
end




ER.ABUNDANCE_SPELL_ID = 207640
ER.REFORESTATION_SPELL_ID = 392360
ER.CLEARCASTING_SPELL_ID = 16870



local TRACKER_ICONS = {
    [132124]  = { spellID = 207640, key = "abundance" },
    [1416160] = { spellID = 392360, key = "reforestation" },
    [136170]  = { spellID = 16870,  key = "clearcasting" },
}



local function GetTrackerAura(spellID, spellName, iconID)
    
    local apps, expTime, found = GetAuraInfo(spellID, spellName)
    if found then return apps, expTime, true end

    
    if iconID and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local i = 1
        while i <= 40 do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not auraData then break end
            local iconOk, iconMatch = pcall(function()
                return auraData.icon == iconID
            end)
            if iconOk and iconMatch then
                if DebugLog.enabled then
                    DLog("AURA", spellName .. " ICON-MATCH at i=" .. i .. " icon=" .. tostring(iconID)
                        .. " — " .. DumpAuraFields(auraData))
                end
                return auraData.applications or 0, auraData.expirationTime or 0, true
            end
            i = i + 1
        end
    end

    return 0, 0, false
end


local function UpdateTrackerIcon(frame, configShowKey, spellID, spellName, iconID)
    if not frame then return end

    if not ThugUI_Config[configShowKey] or not ThugUI_Config.showECV then
        frame:Hide()
        return
    end

    if not ER.ecvContainer or not ER.ecvContainer:IsShown() then
        frame:Hide()
        return
    end

    local apps, expTime, found = GetTrackerAura(spellID, spellName, iconID)

    if found then
        
        
        local cd = frame.cooldown
        if cd then
            local setOk = pcall(function()
                if expTime > 0 then
                    local now = GetTime()
                    local duration = expTime - now
                    if duration > 0 then
                        cd:SetCooldown(now, duration)
                        cd:Show()
                    else
                        cd:Hide()
                    end
                else
                    cd:Hide()
                end
            end)
            if not setOk then
                
                
                pcall(function()
                    cd:SetCooldown(expTime - (expTime - GetTime()), expTime - GetTime())
                end)
            end
        end
        frame:Show()
    else
        frame:Hide()
    end
end

function ER:UpdateAbundanceStacks()
    UpdateTrackerIcon(ER.ecvAbundanceFrame, "ecvShowAbundance",
        ER.ABUNDANCE_SPELL_ID, "Abundance", 132124)
end

function ER:UpdateReforestationStacks()
    UpdateTrackerIcon(ER.ecvReforestationFrame, "ecvShowReforestation",
        ER.REFORESTATION_SPELL_ID, "Reforestation", 1416160)
end

function ER:UpdateClearcastingTimer()
    UpdateTrackerIcon(ER.ecvClearcastingFrame, "ecvShowClearcasting",
        ER.CLEARCASTING_SPELL_ID, "Clearcasting", 136170)
end
















ER.bcvSpellDefs = {
    { key = "furyofelune",   name = "Fury of Elune",                spellID = 202770, mode = "cooldown", talentGated = true },
    { key = "forceofnature", name = "Force of Nature",              spellID = 205636, mode = "cooldown", talentGated = true },
    
    
    
    
    
    { key = "incarnation",        name = "Incarnation: Chosen of Elune", spellID = 102560, mode = "cooldown", talentGated = true, strictAvail = true },
    { key = "celestialalignment", name = "Celestial Alignment",          spellID = 194223, mode = "cooldown", talentGated = true, strictAvail = true },
    
    
    
    { key = "starweaversweft", name = "Starweaver's Weft", spellID = 393944, mode = "buff", talentGated = false,
      gateConfig = "bcvShowStarsurgeProc",
      buffAuras = { { name = "Starweaver's Weft", id = 393944, icon = 429383 } } },
    { key = "starweaverswarp", name = "Starweaver's Warp", spellID = 393942, mode = "buff", talentGated = false,
      gateConfig = "bcvShowStarsurgeProc",
      buffAuras = { { name = "Starweaver's Warp", id = 393942, icon = 1052602 } } },
    { key = "touchthecosmos",  name = "Touch the Cosmos",  spellID = 450360, mode = "buff", talentGated = false,
      gateConfig = "bcvShowStarsurgeProc",
      buffAuras = { { name = "Touch the Cosmos", id = 450360, icon = 1120185 } } },
}

local BCV_ICON_SIZE = 32
local BCV_PADDING = 4





local function ResolveDefSpellID(def)
    if def.spellID then return def.spellID end
    local ok, info = pcall(C_Spell.GetSpellInfo, def.name)
    return (ok and info and info.spellID) or nil
end


local function IsSpellAvailable(spellID)
    if not spellID then return true end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then return true end
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) then return true end
    return false
end



function ER:CreateBCV()
    if ER.bcvContainer then return end

    local f = CreateFrame("Frame", "ThugUI_BalanceCooldownViewer", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)
    ER.bcvContainer = f
    ER.bcvIcons = {}
    ER.bcvIconsByKey = {}

    local saved = ThugUI_Config.bcvPoint
    if saved then
        f:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 260)
    end

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ThugUI_Config.bcvPoint = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    f:SetScale(ThugUI_Config.bcvScale or 1.0)

    ER:EnsureBCVIcons()
    ER:UpdateBCVVisibility()
end


function ER:EnsureBCVIcons()
    if not ER.bcvContainer then return end
    ER.bcvIconsByKey = ER.bcvIconsByKey or {}

    for _, def in ipairs(ER.bcvSpellDefs) do
        if not ER.bcvIconsByKey[def.key] then
            local texture = (def.spellID and C_Spell.GetSpellTexture(def.spellID))
                or C_Spell.GetSpellTexture(def.name)
            if texture then
                local icon = CreateFrame("Frame", "ThugUI_BCV_" .. def.key, ER.bcvContainer)
                icon:SetSize(BCV_ICON_SIZE, BCV_ICON_SIZE)

                local bg = icon:CreateTexture(nil, "BACKGROUND")
                bg:SetPoint("TOPLEFT", -1, 1)
                bg:SetPoint("BOTTOMRIGHT", 1, -1)
                bg:SetColorTexture(0, 0, 0, 0.8)

                local tex = icon:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints()
                tex:SetTexture(texture)
                tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                icon.tex = tex
                icon.baseTexture = texture  

                
                
                local cd = CreateFrame("Cooldown", "ThugUI_BCV_" .. def.key .. "Cooldown", icon, "CooldownFrameTemplate")
                cd:SetAllPoints()
                cd:SetDrawEdge(true)
                cd:SetHideCountdownNumbers(false)
                icon.cooldown = cd

                
                
                local count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
                count:Hide()
                icon.count = count

                icon.def = def
                icon:Hide()
                ER.bcvIconsByKey[def.key] = icon
                table.insert(ER.bcvIcons, icon)
            end
        end
    end
end




local function GetBCVBuff(def)
    if not def.buffAuras then return false, 0, nil end
    for _, aura in ipairs(def.buffAuras) do
        local _, expTime, found = GetTrackerAura(aura.id, aura.name, aura.icon)
        if found then return true, expTime, aura end
    end
    return false, 0, nil
end

function ER:UpdateBCVCooldowns()
    if not ER.bcvContainer or not ER.bcvContainer:IsShown() then return end
    ER.bcvIconsByKey = ER.bcvIconsByKey or {}

    local visibleIndex = 0
    for _, def in ipairs(ER.bcvSpellDefs) do
        local icon = ER.bcvIconsByKey[def.key]
        if icon then
            local show = false

            
            
            
            local available
            if not def.talentGated then
                available = true
            elseif def.strictAvail then
                available = (IsPlayerSpell and IsPlayerSpell(def.spellID)) or false
            else
                available = IsSpellAvailable(def.spellID)
            end

            if not available then
                show = false
            elseif def.mode == "buff" then
                
                
                local gated = def.gateConfig and not ThugUI_Config[def.gateConfig]
                local found, expTime, aura = false, 0, nil
                if not gated then
                    found, expTime, aura = GetBCVBuff(def)
                end
                show = found
                if show then
                    if aura and aura.id and icon.tex then
                        local art = C_Spell.GetSpellTexture(aura.id)
                        icon.tex:SetTexture(art or icon.baseTexture)
                    end
                    local cd = icon.cooldown
                    if cd then
                        
                        local setOk = pcall(function()
                            if expTime > 0 then
                                local now = GetTime()
                                local duration = expTime - now
                                if duration > 0 then
                                    cd:SetCooldown(now, duration)
                                    cd:Show()
                                else
                                    cd:Hide()
                                end
                            else
                                cd:Hide()
                            end
                        end)
                        if not setOk then
                            pcall(function() cd:SetCooldown(GetTime(), expTime - GetTime()) end)
                        end
                    end
                elseif icon.cooldown then
                    icon.cooldown:Hide()
                end
            else
                
                
                
                show = IsSpellReady(def.name)
                if show and icon.count then
                    local ok, ch = pcall(C_Spell.GetSpellCharges, def.name)
                    local cur = ok and ch and ch.currentCharges
                    local maxc = ok and ch and ch.maxCharges
                    if cur ~= nil and maxc and maxc > 1
                        and not (issecretvalue and issecretvalue(cur)) then
                        icon.count:SetText(cur)
                        icon.count:Show()
                    else
                        icon.count:Hide()
                    end
                elseif icon.count then
                    icon.count:Hide()
                end
            end

            if show then
                icon:Show()
                icon:ClearAllPoints()
                icon:SetPoint("TOPLEFT", ER.bcvContainer, "TOPLEFT",
                    visibleIndex * (BCV_ICON_SIZE + BCV_PADDING), 0)
                visibleIndex = visibleIndex + 1
            else
                icon:Hide()
            end
        end
    end

    local totalW = math.max(visibleIndex * (BCV_ICON_SIZE + BCV_PADDING) - BCV_PADDING, 1)
    ER.bcvContainer:SetSize(totalW, BCV_ICON_SIZE)
end

function ER:UpdateBCVVisibility(inCombat)
    if not ER.bcvContainer then return end

    if not ER:LegacyBarsActive() then
        ER.bcvContainer:Hide()
        return
    end

    if not ThugUI_Config.showBCV or not ER:IsBalanceSpec() then
        ER.bcvContainer:Hide()
        return
    end

    
    ER:EnsureBCVIcons()

    if ThugUI_Config.bcvShowOnlyInCombat then
        if inCombat == nil then inCombat = ER:IsInCombat() end
        if not inCombat then
            ER.bcvContainer:Hide()
            return
        end
    end

    ER.bcvContainer:Show()
    ER:UpdateBCVCooldowns()
end

function ER:UpdateBCVPosition()
    if not ThugUI_Config.anchorBCVToCursor then return end
    if not ER:IsBalanceSpec() then return end
    if not ER:IsInCombat() then return end

    local f = ER.bcvContainer
    if not f or not f:IsShown() then return end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    local scale = f:GetScale()
    local scaledX = cursorX / uiScale / scale
    local scaledY = cursorY / uiScale / scale

    local corner = ThugUI_Config.bcvAnchorCorner or "TOPLEFT"
    local gap = 8 / scale
    local ofsX, ofsY = 0, 0
    if corner == "TOPLEFT" then
        ofsX, ofsY = gap, -gap
    elseif corner == "TOPRIGHT" then
        ofsX, ofsY = -gap, -gap
    elseif corner == "BOTTOMLEFT" then
        ofsX, ofsY = gap, gap
    elseif corner == "BOTTOMRIGHT" then
        ofsX, ofsY = -gap, gap
    end

    f:ClearAllPoints()
    f:SetPoint(corner, UIParent, "BOTTOMLEFT", scaledX + ofsX, scaledY + ofsY)
end



function ER:ReleaseBCVAnchor()
    if not ER.bcvContainer then return end
    local saved = ThugUI_Config.bcvPoint
    ER.bcvContainer:ClearAllPoints()
    if saved then
        ER.bcvContainer:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    else
        ER.bcvContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 260)
    end
end









ER.gcvSpellDefs = {
    { key = "mangle",    name = "Mangle",              spellID = 33917,  talentGated = false },
    { key = "thrash",    name = "Thrash",              spellID = 77758,  talentGated = false },
    { key = "convoke",   name = "Convoke the Spirits", spellID = 391528, talentGated = true },
    { key = "lunarbeam", name = "Lunar Beam",          spellID = 204066, talentGated = true },
    
    
    { key = "redmoon",   name = "Red Moon",                              talentGated = true },
}



function ER:CreateGCV()
    if ER.gcvContainer then return end

    local f = CreateFrame("Frame", "ThugUI_GuardianCooldownViewer", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)
    ER.gcvContainer = f
    ER.gcvIcons = {}
    ER.gcvIconsByKey = {}

    local saved = ThugUI_Config.gcvPoint
    if saved then
        f:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
    end

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ThugUI_Config.gcvPoint = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    f:SetScale(ThugUI_Config.gcvScale or 1.0)

    ER:EnsureGCVIcons()
    ER:UpdateGCVVisibility()
end


function ER:EnsureGCVIcons()
    if not ER.gcvContainer then return end
    ER.gcvIconsByKey = ER.gcvIconsByKey or {}

    for _, def in ipairs(ER.gcvSpellDefs) do
        if not ER.gcvIconsByKey[def.key] then
            local texture = (def.spellID and C_Spell.GetSpellTexture(def.spellID))
                or C_Spell.GetSpellTexture(def.name)
            if texture then
                local icon = CreateFrame("Frame", "ThugUI_GCV_" .. def.key, ER.gcvContainer)
                icon:SetSize(BCV_ICON_SIZE, BCV_ICON_SIZE)

                local bg = icon:CreateTexture(nil, "BACKGROUND")
                bg:SetPoint("TOPLEFT", -1, 1)
                bg:SetPoint("BOTTOMRIGHT", 1, -1)
                bg:SetColorTexture(0, 0, 0, 0.8)

                local tex = icon:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints()
                tex:SetTexture(texture)
                tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                icon.tex = tex

                icon.def = def
                icon:Hide()
                ER.gcvIconsByKey[def.key] = icon
                table.insert(ER.gcvIcons, icon)
            end
        end
    end
end

function ER:UpdateGCVCooldowns()
    if not ER.gcvContainer or not ER.gcvContainer:IsShown() then return end
    ER.gcvIconsByKey = ER.gcvIconsByKey or {}

    local visibleIndex = 0
    for _, def in ipairs(ER.gcvSpellDefs) do
        local icon = ER.gcvIconsByKey[def.key]
        if icon then
            
            
            
            
            local available
            if not def.talentGated then
                available = true
            else
                local spellID = ResolveDefSpellID(def)
                available = (spellID ~= nil) and IsSpellAvailable(spellID)
            end
            local show = available and IsSpellReady(def.name)

            if show then
                icon:Show()
                icon:ClearAllPoints()
                icon:SetPoint("TOPLEFT", ER.gcvContainer, "TOPLEFT",
                    visibleIndex * (BCV_ICON_SIZE + BCV_PADDING), 0)
                visibleIndex = visibleIndex + 1
            else
                icon:Hide()
            end
        end
    end

    local totalW = math.max(visibleIndex * (BCV_ICON_SIZE + BCV_PADDING) - BCV_PADDING, 1)
    ER.gcvContainer:SetSize(totalW, BCV_ICON_SIZE)
end

function ER:UpdateGCVVisibility(inCombat)
    if not ER.gcvContainer then return end

    if not ER:LegacyBarsActive() then
        ER.gcvContainer:Hide()
        return
    end

    if not ThugUI_Config.showGCV or not ER:IsGuardianSpec() then
        ER.gcvContainer:Hide()
        return
    end

    
    ER:EnsureGCVIcons()

    if ThugUI_Config.gcvShowOnlyInCombat then
        if inCombat == nil then inCombat = ER:IsInCombat() end
        if not inCombat then
            ER.gcvContainer:Hide()
            return
        end
    end

    ER.gcvContainer:Show()
    ER:UpdateGCVCooldowns()
end

function ER:UpdateGCVPosition()
    if not ThugUI_Config.anchorGCVToCursor then return end
    if not ER:IsGuardianSpec() then return end
    if not ER:IsInCombat() then return end

    local f = ER.gcvContainer
    if not f or not f:IsShown() then return end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    local scale = f:GetScale()
    local scaledX = cursorX / uiScale / scale
    local scaledY = cursorY / uiScale / scale

    local corner = ThugUI_Config.gcvAnchorCorner or "TOPLEFT"
    local gap = 8 / scale
    local ofsX, ofsY = 0, 0
    if corner == "TOPLEFT" then
        ofsX, ofsY = gap, -gap
    elseif corner == "TOPRIGHT" then
        ofsX, ofsY = -gap, -gap
    elseif corner == "BOTTOMLEFT" then
        ofsX, ofsY = gap, gap
    elseif corner == "BOTTOMRIGHT" then
        ofsX, ofsY = -gap, gap
    end

    f:ClearAllPoints()
    f:SetPoint(corner, UIParent, "BOTTOMLEFT", scaledX + ofsX, scaledY + ofsY)
end



function ER:ReleaseGCVAnchor()
    if not ER.gcvContainer then return end
    local saved = ThugUI_Config.gcvPoint
    ER.gcvContainer:ClearAllPoints()
    if saved then
        ER.gcvContainer:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    else
        ER.gcvContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
    end
end

function ER:UpdateECVVisibility(inCombat)
    if not ER.ecvContainer then return end

    if not ER:LegacyBarsActive() then
        ER.ecvContainer:Hide()
        return
    end

    
    
    if not ER:IsRestoSpec() then
        ER.ecvContainer:Hide()
        return
    end
    if not ThugUI_Config.showECV then
        ER.ecvContainer:Hide()
        return
    end

    if ThugUI_Config.ecvShowOnlyInCombat then
        if inCombat == nil then inCombat = ER:IsInCombat() end
        if not inCombat then
            ER.ecvContainer:Hide()
            return
        end
    end

    ER.ecvContainer:Show()
    ER:UpdateECVCooldowns()
end

function ER:UpdateECVCooldowns()
    if not ER.ecvContainer or not ER.ecvContainer:IsShown() then return end

    local iconSize = 32
    local padding = 4
    local visibleIndex = 0

    for _, icon in ipairs(ER.ecvIcons) do
        if IsSpellReady(icon.spellName) then
            icon:Show()
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", ER.ecvContainer, "TOPLEFT",
                visibleIndex * (iconSize + padding), 0)
            visibleIndex = visibleIndex + 1
        else
            icon:Hide()
        end
    end

    
    local totalW = math.max(visibleIndex * (iconSize + padding) - padding, 1)
    ER.ecvContainer:SetSize(totalW, iconSize)
end

function ER:UpdateECVPosition()
    if not ThugUI_Config.anchorECVToCursor then return end
    if not ER:IsInCombat() then return end

    local ecvFrame = ER.ecvContainer
    if not ecvFrame or not ecvFrame:IsShown() then return end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    local ecvScale = ecvFrame:GetScale()
    local scaledX = cursorX / uiScale / ecvScale
    local scaledY = cursorY / uiScale / ecvScale

    local corner = ThugUI_Config.ecvAnchorCorner or "TOPLEFT"
    local gap = 8 / ecvScale  

    
    local ofsX, ofsY = 0, 0
    if corner == "TOPLEFT" then
        ofsX, ofsY = gap, -gap
    elseif corner == "TOPRIGHT" then
        ofsX, ofsY = -gap, -gap
    elseif corner == "BOTTOMLEFT" then
        ofsX, ofsY = gap, gap
    elseif corner == "BOTTOMRIGHT" then
        ofsX, ofsY = -gap, gap
    end

    ecvFrame:ClearAllPoints()
    ecvFrame:SetPoint(corner, UIParent, "BOTTOMLEFT",
        scaledX + ofsX, scaledY + ofsY)
end

function ER:AnchorECVToCursor()
    if not ER.ecvContainer then return end

    
    if not ER.ecvOriginalPoint then
        local point, relativeTo, relativePoint, xOfs, yOfs = ER.ecvContainer:GetPoint()
        ER.ecvOriginalPoint = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs,
        }
    end

    ER.ecvAnchored = true
    ER:UpdateECVCooldowns()
end

function ER:ReleaseECVAnchor()
    if not ER.ecvContainer then return end

    
    if ER.ecvOriginalPoint then
        local op = ER.ecvOriginalPoint
        ER.ecvContainer:ClearAllPoints()
        ER.ecvContainer:SetPoint(op.point, op.relativeTo or UIParent,
            op.relativePoint, op.xOfs, op.yOfs)
    end

    ER.ecvAnchored = false
end

function ER:StartGCDAnimation(startTime, duration)
    if not ER.GCDCooldownFrame then return end
    if not ER.enableGCD then return end
    
    ER.isGCDAnimating = true
    
    local fillDrain = ThugUI_Config.gcdFillDrain or "fill"
    ER.GCDCooldownFrame:SetReverse(fillDrain == "fill")
    
    ER.GCDCooldownFrame:SetCooldown(startTime, duration)
    ER.GCDCooldownFrame:Show()
end

function ER:StartCastAnimation(startTime, duration)
    if not ER.CastFrame then return end
    if not ER.enableCast then return end
    
    ER.isCasting = true
    
    
    local isChanneling = UnitChannelInfo("player") ~= nil
    
    local fillDrain = ThugUI_Config.castFillDrain or "fill"
    local shouldReverse = (fillDrain == "fill")
    
    
    if isChanneling then
        shouldReverse = not shouldReverse
    end
    
    ER.CastFrame:SetReverse(shouldReverse)
    ER.CastFrame:SetCooldown(startTime, duration)
    ER.CastFrame:Show()
end

function ER:StopCastAnimation()
    if not ER.CastFrame then return end
    
    ER.isCasting = false
    ER.CastFrame:Clear()
    ER.CastFrame:Hide()
end

function ER:GCDCastHandler(self, event, unit, spellName, spellId)
    
    
    
    
    
    if unit and unit ~= "player" then return end

    if GetTime() - ER.lastGCDTime < 0.1 then return end

    ER.lastGCDTime = GetTime()

    local GCDInfo = C_Spell.GetSpellCooldown(GCD_SPELL_ID)

    if GCDInfo and GCDInfo.duration > 0 then
        ER:StartGCDAnimation(GCDInfo.startTime, GCDInfo.duration)
    end
end

function ER:CastEventHandler(self, event, unit)
    
    
    
    if unit and unit ~= "player" then return end

    local startTime, endTime, infoValid = nil, nil, false

    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
        
        
        local cName, cRank, cTarget, cStartTime, cEndTime = UnitCastingInfo("player")
        startTime, endTime = cStartTime, cEndTime
        infoValid = true

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        
        
        local chName, chRank, chTarget, chStartTime, chEndTime, isMoving = UnitChannelInfo("player")
        startTime, endTime = chStartTime, chEndTime
        infoValid = true

    elseif event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_FAILED"
    then
        ER:StopCastAnimation()
        return
    end

    if infoValid then
        if not (startTime and endTime) then
            
            
            ER:StopCastAnimation()
            return
        end

        local duration = (endTime - startTime) / 1000
        if duration > 0.1 then
            ER:StartCastAnimation(startTime / 1000, duration)
        end
    end
end

function ER:UpdateVisibility(forceState)
    if not ThugUI_CursorFrame then return end

    local inCombat = forceState
    if inCombat == nil then
        inCombat = ER:IsInCombat()
    end

    local ringsVisible = false
    
    if ThugUI_Config.showOnlyInCombat then
        if inCombat then
            ThugUI_CursorFrame:Show()
            ringsVisible = true
        else
            ThugUI_CursorFrame:Hide()
            ringsVisible = false
        end
    else
        ThugUI_CursorFrame:Show()
        ringsVisible = true
    end
    
    
    if ThugUI_Config.hideGameCursor then
        if ringsVisible then
            ER:HideGameCursor()
        else
            ER:RestoreGameCursor()
        end
    end
    
    
    if ThugUI_Config.anchorECVToCursor then
        if inCombat then
            ER:AnchorECVToCursor()
        else
            ER:ReleaseECVAnchor()
        end
    end

    
    
    if ThugUI_Config.anchorBCVToCursor and not inCombat then
        ER:ReleaseBCVAnchor()
    end

    
    
    if ThugUI_Config.anchorGCVToCursor and not inCombat then
        ER:ReleaseGCVAnchor()
    end

    
    ER:UpdateECVVisibility(inCombat)
    ER:UpdateBCVVisibility(inCombat)
    ER:UpdateGCVVisibility(inCombat)

    
    
    if ThugUI.ResourceRing then
        ThugUI.ResourceRing:Update()
    end
end

function ER:ResetCooldownFrames()
    ER.isGCDAnimating = false
    ER.isCasting = false
    
    
    if ER.GCDCooldownFrame then
        ER.GCDCooldownFrame:Hide()
        ER.GCDCooldownFrame:SetParent(nil)
        ER.GCDCooldownFrame = nil
    end
    if ER.GCDBackgroundFrame then
        ER.GCDBackgroundFrame:Hide()
        ER.GCDBackgroundFrame:SetParent(nil)
        ER.GCDBackgroundFrame = nil
    end
    
    
    if ER.CastFrame then
        ER.CastFrame:Hide()
        ER.CastFrame:SetParent(nil)
        ER.CastFrame = nil
    end
    if ER.CastBackgroundFrame then
        ER.CastBackgroundFrame:Hide()
        ER.CastBackgroundFrame:SetParent(nil)
        ER.CastBackgroundFrame = nil
    end
    
    
    local gcdBgFrame = CreateFrame("Cooldown", nil, ThugUI_CursorFrame)
    gcdBgFrame:SetSize(70, 70)
    gcdBgFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    gcdBgFrame:SetFrameLevel(2)
    ER.GCDBackgroundFrame = gcdBgFrame
    gcdBgFrame:SetSwipeTexture(ER:GetRingTexture("gcd"))
    gcdBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    gcdBgFrame:SetReverse(false)
    gcdBgFrame:SetHideCountdownNumbers(true)
    gcdBgFrame:SetCooldown(GetTime() - 1, 0.01)
    gcdBgFrame:Hide()

    
    local cooldownFrame = CreateFrame("Cooldown", nil, ThugUI_CursorFrame)
    cooldownFrame:SetSize(50, 50)
    cooldownFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    cooldownFrame:SetFrameLevel(3)
    ER.GCDCooldownFrame = cooldownFrame
    cooldownFrame:SetSwipeTexture(ER:GetRingTexture("gcd"))
    local r, g, b = ER:GetClassColor("gcd")
    cooldownFrame:SetSwipeColor(r, g, b, 1.0)
    cooldownFrame:SetHideCountdownNumbers(true)
    
    local gcdRotation = ThugUI_Config.gcdRotation or 12
    cooldownFrame:SetRotation(ER:ClockToRadians(gcdRotation))
    cooldownFrame:Hide()

    
    local castBgFrame = CreateFrame("Cooldown", nil, ThugUI_CursorFrame)
    castBgFrame:SetSize(70, 70)
    castBgFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    castBgFrame:SetFrameLevel(2)
    ER.CastBackgroundFrame = castBgFrame
    castBgFrame:SetSwipeTexture(ER:GetRingTexture("cast"))
    castBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    castBgFrame:SetReverse(false)
    castBgFrame:SetHideCountdownNumbers(true)
    castBgFrame:SetCooldown(GetTime() - 1, 0.01)
    castBgFrame:Hide()

    
    local castFrame = CreateFrame("Cooldown", nil, ThugUI_CursorFrame)
    castFrame:SetSize(90, 90)
    castFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    castFrame:SetFrameLevel(3)
    ER.CastFrame = castFrame
    castFrame:SetSwipeTexture(ER:GetRingTexture("cast"))
    r, g, b = ER:GetClassColor("cast")
    castFrame:SetSwipeColor(r, g, b, 1.0)
    castFrame:SetHideCountdownNumbers(true)
    
    local castRotation = ThugUI_Config.castRotation or 12
    castFrame:SetRotation(ER:ClockToRadians(castRotation))
    castFrame:Hide()
    
    if ER.ApplySettings then
        ER:ApplySettings()
    end
end






function ER:CursorAlpha()
    if not ThugUI:IsModuleOn("rings") then
        return 0
    end
    return ThugUI_Config.transparency or 1.0
end

function ER:SetupUI()
    ThugUI_CursorFrame:SetAlpha(ER:CursorAlpha())
    ThugUI_CursorFrame:SetFrameStrata("HIGH")
    ThugUI_CursorFrame:SetToplevel(false)
    ThugUI_CursorFrame:Show()
    ER:SetGroupScale(ER.currentGroupScale)
    ThugUI_CursorFrame.MainRing:Show()
    
    ER:UpdateReticle()

    
    local gcdBgFrame = CreateFrame("Cooldown", "ThugUI_GCD_BG_COOLDOWN", ThugUI_CursorFrame)
    gcdBgFrame:SetSize(70, 70)
    gcdBgFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    gcdBgFrame:SetFrameLevel(2)
    ER.GCDBackgroundFrame = gcdBgFrame
    gcdBgFrame:SetSwipeTexture(ER:GetRingTexture("gcd"))
    gcdBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    gcdBgFrame:SetReverse(false)
    gcdBgFrame:SetHideCountdownNumbers(true)
    gcdBgFrame:SetCooldown(GetTime() - 1, 0.01)
    gcdBgFrame:Hide()

    
    local cooldownFrame = CreateFrame("Cooldown", "ThugUI_GCD_COOLDOWN", ThugUI_CursorFrame)
    cooldownFrame:SetSize(50, 50)
    cooldownFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    cooldownFrame:SetFrameLevel(3)
    ER.GCDCooldownFrame = cooldownFrame
    cooldownFrame:SetSwipeTexture(ER:GetRingTexture("gcd"))
    local r, g, b = ER:GetClassColor("gcd")
    cooldownFrame:SetSwipeColor(r, g, b, 1.0)
    cooldownFrame:SetHideCountdownNumbers(true)
    
    local gcdRotation = ThugUI_Config.gcdRotation or 12
    cooldownFrame:SetRotation(ER:ClockToRadians(gcdRotation))
    cooldownFrame:Hide()

    
    local castBgFrame = CreateFrame("Cooldown", "ThugUI_CAST_BG_COOLDOWN", ThugUI_CursorFrame)
    castBgFrame:SetSize(70, 70)
    castBgFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    castBgFrame:SetFrameLevel(2)
    ER.CastBackgroundFrame = castBgFrame
    castBgFrame:SetSwipeTexture(ER:GetRingTexture("cast"))
    castBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    castBgFrame:SetReverse(false)
    castBgFrame:SetHideCountdownNumbers(true)
    castBgFrame:SetCooldown(GetTime() - 1, 0.01)
    castBgFrame:Hide()

    
    local castFrame = CreateFrame("Cooldown", "ThugUI_CAST_COOLDOWN", ThugUI_CursorFrame)
    castFrame:SetSize(90, 90)
    castFrame:SetPoint("CENTER", ThugUI_CursorFrame, "CENTER")
    castFrame:SetFrameLevel(3)
    ER.CastFrame = castFrame
    castFrame:SetSwipeTexture(ER:GetRingTexture("cast"))
    r, g, b = ER:GetClassColor("cast")
    castFrame:SetSwipeColor(r, g, b, 1.0)
    castFrame:SetHideCountdownNumbers(true)
    
    local castRotation = ThugUI_Config.castRotation or 12
    castFrame:SetRotation(ER:ClockToRadians(castRotation))
    castFrame:Hide()

    if ER.ApplySettings then
        ER:ApplySettings()
    end

    
    ER:CreateECV()

    
    ER:CreateBCV()

    
    ER:CreateGCV()

    
    
    if ThugUI.ResourceRing then
        ThugUI.ResourceRing:Initialize()
    end

    
    if ThugUI.ComboPips then
        ThugUI.ComboPips:Initialize()
    end

    TrackerFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function ER:OnInitialize()
    ER.TrackerFrame = TrackerFrame

    TrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    TrackerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    TrackerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    TrackerFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    
    ThugUI.SafeRegisterEvent(TrackerFrame, "PLAYER_SPECIALIZATION_CHANGED")
    TrackerFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    TrackerFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

    TrackerFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            if ThugUI_CursorFrame then
                ER:SetupUI()
            end

        elseif event == "UNIT_SPELLCAST_SENT" then
            
            
            
            ER:GCDCastHandler(self, event, ...)

        elseif event:match("^UNIT_SPELLCAST_") then
            ER:CastEventHandler(self, event, ...)

        elseif event == "PLAYER_REGEN_DISABLED" then
            DLog("TRANSITION", ">>> ENTERING COMBAT — container="
                .. (ER.ecvContainer and (ER.ecvContainer:IsShown() and "SHOWN" or "HIDDEN") or "NIL")
                .. " testMode=" .. tostring(ThugUI_Config.testMode)
                .. " showECV=" .. tostring(ThugUI_Config.showECV)
                .. " combatOnly=" .. tostring(ThugUI_Config.ecvShowOnlyInCombat))
            ER:UpdateVisibility(true)
            DLog("TRANSITION", ">>> AFTER UpdateVisibility(true) — container="
                .. (ER.ecvContainer and (ER.ecvContainer:IsShown() and "SHOWN" or "HIDDEN") or "NIL"))
        elseif event == "PLAYER_REGEN_ENABLED" then
            DLog("TRANSITION", "<<< LEAVING COMBAT — container="
                .. (ER.ecvContainer and (ER.ecvContainer:IsShown() and "SHOWN" or "HIDDEN") or "NIL"))
            ER:UpdateVisibility(false)
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            ER:UpdateECVCooldowns()
            ER:UpdateBCVCooldowns()
            ER:UpdateGCVCooldowns()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED"
            or event == "ACTIVE_TALENT_GROUP_CHANGED"
            or event == "TRAIT_CONFIG_UPDATED" then
            
            ER:EnsureBCVIcons()
            ER:EnsureGCVIcons()
            ER:UpdateVisibility()
        end
    end)

    TrackerFrame:SetScript("OnUpdate", function(self, elapsed)
        ER:OnUpdate(elapsed)
    end)
    TrackerFrame:Show()
    ER:OnUpdate(0)
end

LoaderFrame:SetScript("OnEvent", function(self, event, addon)
    if ThugUI_Config and ThugUI_Config.debugMode then
        print("ThugUI: ADDON_LOADED fired for: " .. tostring(addon))
    end
    if event == "ADDON_LOADED" and addon == "ThugUI" then
        ThugUI_DebugLog = ThugUI_DebugLog or {}
        ER:OnInitialize()
        ER:InitializeSettings()
        
        DebugLog.enabled = ThugUI_Config.debugMode and true or false
        if ThugUI_Config.debugMode then
            print("ThugUI: Initializing Essential Rings...")
        end
        if ThugUI.FrameHider then
            if ThugUI:IsModuleOn("framehider") then
                ThugUI.FrameHider:ApplyAll()
            end
        end
        if ThugUI_Config.debugMode then
            print("ThugUI: Initialization complete!")
        end
        self:UnregisterAllEvents()
    end
end)
LoaderFrame:RegisterEvent("ADDON_LOADED")
