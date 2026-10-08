














local ThugUI = _G.ThugUI

ThugUI.defaults.Camera = {
    enabled = true,
    shoulderOffset = 0,
    dynamicPitch = false,
    focusEnemy = false,
    focusInteract = true,
    headMovement = false,
    maxZoomFactor = 2.6,
    zoomSpeed = 20,
    transitionTime = 0.8,
    rotateResumeDelay = 4,
    situations = {
        dialogue = { enabled = true,  zoom = 4,  overrideShoulder = true,  shoulder = 1.5, rotate = false, rotateSpeed = 6, fadeUI = true,  swing = 0, swingBack = true, restoreZoom = true  },
        taxi     = { enabled = true,  zoom = 20, overrideShoulder = false, shoulder = 0, rotate = true,  rotateSpeed = 4, fadeUI = true,  swing = 0, swingBack = true, restoreZoom = true  },
        fishing  = { enabled = true,  zoom = 8,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = true  },
        afk      = { enabled = true,  zoom = 10, overrideShoulder = false, shoulder = 0, rotate = true,  rotateSpeed = 5, fadeUI = true,  swing = 0, swingBack = true, restoreZoom = true  },
        combat   = { enabled = true,  zoom = 0,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = false },
        mounted  = { enabled = true,  zoom = 15, overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = true  },
        swimming = { enabled = false, zoom = 0,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = false },
        pvp      = { enabled = false, zoom = 0,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = false },
        instance = { enabled = false, zoom = 0,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = false },
        city     = { enabled = false, zoom = 0,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = false },
        indoors  = { enabled = true,  zoom = 8,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = true  },
        world    = { enabled = true,  zoom = 0,  overrideShoulder = false, shoulder = 0, rotate = false, rotateSpeed = 6, fadeUI = false, swing = 0, swingBack = true, restoreZoom = false },
    },
}

local Camera = CreateFrame("Frame")
ThugUI.Camera = Camera
ThugUI:RegisterModule("Camera", Camera)

local UnitOnTaxi = _G.UnitOnTaxi
local UnitChannelInfo = _G.UnitChannelInfo
local UnitIsAFK = _G.UnitIsAFK
local UnitAffectingCombat = _G.UnitAffectingCombat
local IsMounted = _G.IsMounted
local IsSwimming = _G.IsSwimming
local IsInInstance = _G.IsInInstance
local IsResting = _G.IsResting
local IsIndoors = _G.IsIndoors
local GetCameraZoom = _G.GetCameraZoom
local CameraZoomIn = _G.CameraZoomIn
local CameraZoomOut = _G.CameraZoomOut
local MoveViewRightStart = _G.MoveViewRightStart
local MoveViewRightStop = _G.MoveViewRightStop
local MoveViewLeftStart = _G.MoveViewLeftStart
local MoveViewLeftStop = _G.MoveViewLeftStop
local C_Timer = _G.C_Timer
local IsMouselooking = _G.IsMouselooking
local IsMouseButtonDown = _G.IsMouseButtonDown
local GetCVar = _G.GetCVar
local GetTime = _G.GetTime
local InCombatLockdown = _G.InCombatLockdown
local C_CVar = _G.C_CVar

local ownZoom = false
local RotationSpeed  
local isDialogueActive = false



local isMerchantOpen = false
local currentSituation = nil
local lastInputTime = 0
local isRotating = false
local savedReturnZoom = nil
local currentShoulder = 0
local shoulderTarget = 0
local shoulderEaseTime = 0
local uiFaded = false
local alphaEaseTime = 0



local function StopRotationFromHook()
    if isRotating and MoveViewRightStop then MoveViewRightStop() end
    isRotating = false
end




local FISHING_SPELL_IDS = {
    [131474] = true, [131476] = true, [131490] = true, [7620] = true,
    [110410] = true, [158743] = true, [377895] = true, [1224771] = true
}

local function IsFishing()
    if not UnitChannelInfo then return false end
    local name, _, _, _, _, _, _, spellID = UnitChannelInfo("player")
    if issecretvalue and (issecretvalue(spellID) or issecretvalue(name)) then return false end
    if spellID and FISHING_SPELL_IDS[spellID] then return true end
    local fName = _G.C_Spell and _G.C_Spell.GetSpellName and _G.C_Spell.GetSpellName(7620)
    if not (issecretvalue and issecretvalue(fName)) and fName and fName == name then return true end
    return false
end





local function Plain(v)
    if issecretvalue and issecretvalue(v) then return false end
    return v and true or false
end
Camera.Plain = Plain

Camera.SITUATIONS = {
    { key = "dialogue", label = "NPC dialogue and vendors", test = function() return isDialogueActive end },
    { key = "taxi", label = "Flight path", test = function() return UnitOnTaxi and UnitOnTaxi("player") end },
    { key = "fishing", label = "Fishing", test = IsFishing },
    { key = "afk", label = "AFK", test = function() return UnitIsAFK and Plain(UnitIsAFK("player")) end },
    
    { key = "combat", label = "Combat", test = function()
        local v = UnitAffectingCombat and UnitAffectingCombat("player")
        if issecretvalue and issecretvalue(v) then return InCombatLockdown and InCombatLockdown() or false end
        return v and true or false
    end },
    { key = "mounted", label = "Mounted", test = function() return IsMounted and IsMounted() end },
    { key = "swimming", label = "Swimming", test = function() return IsSwimming and IsSwimming() end },
    { key = "pvp", label = "Battleground / arena", test = function()
        if not IsInInstance then return false end
        local _, type = IsInInstance()
        return type == "pvp" or type == "arena"
    end },
    { key = "instance", label = "Dungeon / raid", test = function()
        if not IsInInstance then return false end
        local _, type = IsInInstance()
        return type == "party" or type == "raid" or type == "scenario"
    end },
    { key = "city", label = "City / resting", test = function() return IsResting and IsResting() end },
    { key = "indoors", label = "Indoors", test = function() return IsIndoors and IsIndoors() end },
    { key = "world", label = "Outdoors", test = function() return true end },
}




local function SetCVarSafe(name, value)
    if not C_CVar or not C_CVar.GetCVarInfo then return false end
    if not C_CVar.GetCVarInfo(name) then
        if not Camera.loggedCVars then Camera.loggedCVars = {} end
        if not Camera.loggedCVars[name] then
            Camera.loggedCVars[name] = true
            ThugUI.Diagnostics:Log("CAMERA", "Unknown CVar: " .. name)
        end
        return false
    end
    local cur = C_CVar.GetCVar(name)
    if cur ~= tostring(value) then
        local ok, err = pcall(C_CVar.SetCVar, name, tostring(value))
        if not ok then
            ThugUI.Diagnostics:Log("CAMERA", "Refused SetCVar " .. name .. ": " .. tostring(err))
            if not Camera.pendingCVars then Camera.pendingCVars = {} end
            Camera.pendingCVars[name] = tostring(value)
        end
    end
    return true
end

function Camera:ApplyGlobals()
    local cfg = ThugUIDB.Camera
    if not cfg.enabled then return end
    
    SetCVarSafe("test_cameraDynamicPitch", cfg.dynamicPitch and 1 or 0)
    SetCVarSafe("test_cameraTargetFocusEnemyEnable", cfg.focusEnemy and 1 or 0)
    SetCVarSafe("test_cameraTargetFocusInteractEnable", cfg.focusInteract and 1 or 0)
    if not cfg.headMovement then SetCVarSafe("test_cameraHeadMovementStrength", 0) end
    SetCVarSafe("cameraDistanceMaxZoomFactor", cfg.maxZoomFactor)
    SetCVarSafe("cameraZoomSpeed", cfg.zoomSpeed)
    
    
    
    
    local anyShoulder = false
    if cfg.shoulderOffset ~= 0 then anyShoulder = true end
    for _, sit in pairs(cfg.situations) do
        if sit.overrideShoulder and sit.shoulder ~= 0 then anyShoulder = true end
    end
    
    if anyShoulder then
        if not cfg.saved then
            cfg.saved = {
                CameraKeepCharacterCentered = GetCVar and GetCVar("CameraKeepCharacterCentered") or "1",
                CameraReduceUnexpectedMovement = GetCVar and GetCVar("CameraReduceUnexpectedMovement") or "1"
            }
        end
        SetCVarSafe("CameraKeepCharacterCentered", 0)
        SetCVarSafe("CameraReduceUnexpectedMovement", 0)
    else
        if cfg.saved then
            SetCVarSafe("CameraKeepCharacterCentered", cfg.saved.CameraKeepCharacterCentered or "1")
            SetCVarSafe("CameraReduceUnexpectedMovement", cfg.saved.CameraReduceUnexpectedMovement or "1")
            cfg.saved = nil
        end
    end
end



local dialogueGen = 0
local function UpdateDialogueFlag(show)
    if show then
        isDialogueActive = true
        dialogueGen = dialogueGen + 1
        Camera:Evaluate()
    else
        local gen = dialogueGen
        C_Timer.After(0.3, function()
            if gen == dialogueGen then
                isDialogueActive = false
                Camera:Evaluate()
            end
        end)
    end
end

Camera:SetScript("OnEvent", function(self, event, ...)
    if not ThugUI:IsModuleOn("camera") then self:UnregisterAllEvents() return end
    if event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
        UpdateDialogueFlag(true)
    elseif event == "GOSSIP_CLOSED" or event == "QUEST_FINISHED" then
        UpdateDialogueFlag(false)
    
    
    
    elseif event == "MERCHANT_SHOW" then
        isMerchantOpen = true
        UpdateDialogueFlag(true)
        Camera:ReapplyFade()
    elseif event == "MERCHANT_CLOSED" then
        
        
        isMerchantOpen = false
        UpdateDialogueFlag(false)
    elseif event == "PLAYER_REGEN_DISABLED" then
        if uiFaded or UIParent:GetAlpha() < 1 then UIParent:SetAlpha(1) end
        uiFaded = false
        alphaEaseTime = 0
        Camera:Evaluate()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.pendingCVars then
            for k, v in pairs(self.pendingCVars) do
                SetCVarSafe(k, v)
            end
            self.pendingCVars = nil
        end
        Camera:Evaluate()
        Camera:ReapplyFade()
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit == "player" then Camera:Evaluate() end
    else
        Camera:Evaluate()
    end
end)

local pollTimer = 0
Camera:SetScript("OnUpdate", function(self, elapsed)
    local cfg = ThugUIDB.Camera
    if not cfg or not cfg.enabled then return end
    
    pollTimer = pollTimer + elapsed
    if pollTimer >= 0.5 then
        pollTimer = 0
        Camera:Evaluate()
    end
    
    
    
    
    if isRotating then
        local input = false
        if IsMouselooking and IsMouselooking() then input = true end
        if IsMouseButtonDown and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")) then input = true end
        
        if input then
            if MoveViewRightStop then MoveViewRightStop() end
            isRotating = false
            lastInputTime = GetTime and GetTime() or 0
        end
    elseif currentSituation and cfg.situations[currentSituation] and cfg.situations[currentSituation].rotate
        and not swingEnd then
        local input = false
        if IsMouselooking and IsMouselooking() then input = true end
        if IsMouseButtonDown and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")) then input = true end
        
        if input then
            lastInputTime = GetTime and GetTime() or 0
        elseif GetTime and GetTime() - lastInputTime >= cfg.rotateResumeDelay then
            if MoveViewRightStart then
                MoveViewRightStart(RotationSpeed(cfg.situations[currentSituation]))
                isRotating = true
            end
        end
    end
    
    if shoulderEaseTime > 0 then
        shoulderEaseTime = shoulderEaseTime - elapsed
        if shoulderEaseTime <= 0 then
            currentShoulder = shoulderTarget
            SetCVarSafe("test_cameraOverShoulder", currentShoulder)
        else
            local diff = shoulderTarget - currentShoulder
            local rate = diff / (shoulderEaseTime + elapsed)
            currentShoulder = currentShoulder + rate * elapsed
            SetCVarSafe("test_cameraOverShoulder", currentShoulder)
        end
    end
    
    if alphaEaseTime > 0 then
        alphaEaseTime = alphaEaseTime - elapsed
        if not InCombatLockdown or not InCombatLockdown() then
            local targetAlpha = uiFaded and 0 or 1
            if alphaEaseTime <= 0 then
                UIParent:SetAlpha(targetAlpha)
            else
                local cur = UIParent:GetAlpha()
                local diff = targetAlpha - cur
                local rate = diff / (alphaEaseTime + elapsed)
                UIParent:SetAlpha(cur + rate * elapsed)
            end
        end
    end
end)







local function MoveZoomTo(target)
    if not (GetCameraZoom and CameraZoomIn and CameraZoomOut) then return end
    local delta = target - GetCameraZoom()
    ownZoom = true
    if delta > 0 then CameraZoomOut(delta)
    elseif delta < 0 then CameraZoomIn(-delta) end
    ownZoom = false
end















local swingOffset = 0
local swingRate, swingStart, swingEnd = 0, nil, nil
local swingToken = 0

local function YawSpeed()
    local yaw = tonumber(GetCVar and GetCVar("cameraYawMoveSpeed")) or 180
    return yaw > 0 and yaw or 180
end

local function StopSwingTurn()
    if MoveViewRightStop then MoveViewRightStop() end
    if MoveViewLeftStop then MoveViewLeftStop() end
end



local function SettleSwing()
    if not swingEnd then return end
    local now = GetTime and GetTime() or swingEnd
    local turned = (math.min(now, swingEnd) - swingStart) * swingRate
    swingOffset = swingOffset + turned
    swingEnd, swingStart = nil, nil
    swingToken = swingToken + 1  
    StopSwingTurn()
end



local function StartSwing(angle, duration, onDone)
    SettleSwing()
    if math.abs(angle) < 1 or not (C_Timer and C_Timer.After) then
        if onDone then onDone() end
        return
    end
    local start = angle > 0 and MoveViewRightStart or MoveViewLeftStart
    if not start then
        if onDone then onDone() end
        return
    end
    duration = math.max(duration, 0.2)
    swingRate = angle / duration
    start(math.abs(swingRate) / YawSpeed())
    swingStart = GetTime and GetTime() or 0
    swingEnd = swingStart + duration
    local token = swingToken
    C_Timer.After(duration, function()
        if token ~= swingToken then return end
        SettleSwing()
        if onDone then onDone() end
    end)
end

function Camera:IsSwinging()
    return swingEnd ~= nil
end

function Camera:GetSwingOffset()
    return swingOffset
end

function RotationSpeed(sit)
    local yaw = tonumber(GetCVar and GetCVar("cameraYawMoveSpeed")) or 180
    if yaw <= 0 then yaw = 180 end
    return sit.rotateSpeed / yaw
end

local function StopRotation()
    if isRotating and MoveViewRightStop then MoveViewRightStop() end
    isRotating = false
end





local function WantsFade(key, sit)
    if not sit.fadeUI then return false end
    if key == "dialogue" then
        if isMerchantOpen then return false end
        return ThugUI.Dialogue ~= nil and ThugUIDB.Dialogue ~= nil
            and ThugUIDB.Dialogue.enabled == true
    end
    return true
end



local function ApplyFade(key, sit, cfg)
    local want = WantsFade(key, sit)
    if InCombatLockdown and InCombatLockdown() then
        if uiFaded or UIParent:GetAlpha() < 1 then UIParent:SetAlpha(1) end
        uiFaded = false
        alphaEaseTime = 0
        return
    end
    if want ~= uiFaded then
        uiFaded = want
        alphaEaseTime = math.max(cfg.transitionTime, 0.01)
    end
end



local function ApplyLive(key, sit, cfg)
    shoulderTarget = sit.overrideShoulder and sit.shoulder or cfg.shoulderOffset
    if currentShoulder ~= shoulderTarget then
        shoulderEaseTime = math.max(cfg.transitionTime, 0.01)
    end
    ApplyFade(key, sit, cfg)
    StopRotation()
    lastInputTime = 0
    
    
    if sit.rotate and MoveViewRightStart and not swingEnd then
        MoveViewRightStart(RotationSpeed(sit))
        isRotating = true
    end
end



local function AfterSwing()
    local cfg = ThugUIDB.Camera
    local sit = cfg and currentSituation and cfg.situations[currentSituation]
    if sit and sit.rotate and MoveViewRightStart and not isRotating then
        MoveViewRightStart(RotationSpeed(sit))
        isRotating = true
    end
end

function Camera:Evaluate()
    local cfg = ThugUIDB.Camera
    if not cfg or not cfg.enabled then return end

    local newKey = "world"
    for _, s in ipairs(Camera.SITUATIONS) do
        local sc = cfg.situations[s.key]
        if s.key == "world" or (sc and sc.enabled and Plain(s.test())) then
            newKey = s.key
            break
        end
    end
    if newKey == currentSituation then return end


    local oldCfg = currentSituation and cfg.situations[currentSituation]
    local newCfg = cfg.situations[newKey]
    currentSituation = newKey

    
    
    
    
    local restoreTo = oldCfg and oldCfg.restoreZoom and savedReturnZoom or nil
    savedReturnZoom = nil
    local target = restoreTo
    if newCfg.zoom > 0 then
        savedReturnZoom = restoreTo or (GetCameraZoom and GetCameraZoom()) or nil
        target = newCfg.zoom
    end
    if target then MoveZoomTo(target) end

    
    
    
    SettleSwing()
    local back = (oldCfg and oldCfg.swingBack ~= false) and -swingOffset or 0
    swingOffset = -back
    StartSwing(back + (tonumber(newCfg.swing) or 0), cfg.transitionTime, AfterSwing)

    ApplyLive(newKey, newCfg, cfg)
end



function Camera:ForceReapply()
    local cfg = ThugUIDB.Camera
    if not cfg or not cfg.enabled then return end
    if not currentSituation then return self:Evaluate() end
    local sit = cfg.situations[currentSituation]
    if sit.zoom > 0 then MoveZoomTo(sit.zoom) end
    
    SettleSwing()
    StartSwing((tonumber(sit.swing) or 0) - swingOffset, cfg.transitionTime, AfterSwing)
    ApplyLive(currentSituation, sit, cfg)
    self:Evaluate()
end


function Camera:ReapplyFade()
    local cfg = ThugUIDB.Camera
    if not cfg or not cfg.enabled or not currentSituation then return end
    ApplyFade(currentSituation, cfg.situations[currentSituation], cfg)
end

function Camera:Initialize()
    local cfg = ThugUIDB.Camera
    if not cfg.enabled then
        ThugUI.Diagnostics:Log("CAMERA", "Module disabled")
        return
    end
    
    ThugUI.SafeRegisterEvent(self, "PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(self, "PLAYER_REGEN_DISABLED")
    ThugUI.SafeRegisterEvent(self, "PLAYER_REGEN_ENABLED")
    ThugUI.SafeRegisterEvent(self, "PLAYER_MOUNT_DISPLAY_CHANGED")
    ThugUI.SafeRegisterEvent(self, "PLAYER_FLAGS_CHANGED")
    ThugUI.SafeRegisterEvent(self, "PLAYER_UPDATE_RESTING")
    ThugUI.SafeRegisterEvent(self, "ZONE_CHANGED_NEW_AREA")
    ThugUI.SafeRegisterEvent(self, "ZONE_CHANGED_INDOORS")
    ThugUI.SafeRegisterEvent(self, "GOSSIP_SHOW")
    ThugUI.SafeRegisterEvent(self, "GOSSIP_CLOSED")
    ThugUI.SafeRegisterEvent(self, "QUEST_GREETING")
    ThugUI.SafeRegisterEvent(self, "QUEST_DETAIL")
    ThugUI.SafeRegisterEvent(self, "QUEST_PROGRESS")
    ThugUI.SafeRegisterEvent(self, "QUEST_COMPLETE")
    ThugUI.SafeRegisterEvent(self, "QUEST_FINISHED")
    
    ThugUI.SafeRegisterEvent(self, "MERCHANT_SHOW")
    ThugUI.SafeRegisterEvent(self, "MERCHANT_CLOSED")

    pcall(self.RegisterUnitEvent, self, "UNIT_SPELLCAST_CHANNEL_START", "player")
    pcall(self.RegisterUnitEvent, self, "UNIT_SPELLCAST_CHANNEL_STOP", "player")
    
    
    
    if not Camera.zoomHooked then
        Camera.zoomHooked = true
        local function OnPlayerZoom()
            if ownZoom then return end
            lastInputTime = GetTime and GetTime() or 0
            StopRotationFromHook()
        end
        hooksecurefunc("CameraZoomIn", OnPlayerZoom)
        hooksecurefunc("CameraZoomOut", OnPlayerZoom)
    end
    
    currentShoulder = tonumber(C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("test_cameraOverShoulder") or "0") or 0
    
    self:ApplyGlobals()
    self:Evaluate()
end

function Camera:SetEnabled(enabled)
    local cfg = ThugUIDB.Camera
    cfg.enabled = enabled
    if enabled then
        self:Initialize()
    else
        if MoveViewRightStop then MoveViewRightStop() end
        isRotating = false
        
        
        SettleSwing()
        swingOffset = 0
        UIParent:SetAlpha(1)
        uiFaded = false
        alphaEaseTime = 0
        shoulderEaseTime = 0
        SetCVarSafe("test_cameraOverShoulder", 0)
        
        if cfg.saved then
            SetCVarSafe("CameraKeepCharacterCentered", cfg.saved.CameraKeepCharacterCentered or "1")
            SetCVarSafe("CameraReduceUnexpectedMovement", cfg.saved.CameraReduceUnexpectedMovement or "1")
            cfg.saved = nil
        end
        
        self:UnregisterAllEvents()
        currentSituation = nil
    end
end

function Camera:GetActiveSituation()
    return currentSituation
end

function Camera:IsUIFaded()
    return uiFaded
end

function Camera:IsDialogueActive()
    return isDialogueActive
end
