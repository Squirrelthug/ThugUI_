










































local ThugUI = _G.ThugUI
local WML = {}
ThugUI.WorldMapLabels = WML
ThugUI:RegisterModule("WorldMapLabels", WML)

ThugUI.defaults.WorldMap = {
    enabled = true,
    stripButton = true,  
    showLevels = true,   
    colorLevels = true,  
    colorNames = true,   
}




local ZONES = {
    [1411] = { min = 1, max = 10, side = "Horde" }, 
    [1412] = { min = 1, max = 10, side = "Horde" }, 
    [1413] = { min = 10, max = 25, side = "Horde" }, 
    [1416] = { min = 30, max = 40, side = "contested" }, 
    [1417] = { min = 30, max = 40, side = "contested" }, 
    [1418] = { min = 35, max = 45, side = "contested" }, 
    [1419] = { min = 45, max = 55, side = "contested" }, 
    [1420] = { min = 1, max = 10, side = "Horde" }, 
    [1421] = { min = 10, max = 20, side = "Horde" }, 
    [1422] = { min = 51, max = 58, side = "contested" }, 
    [1423] = { min = 53, max = 60, side = "contested" }, 
    [1424] = { min = 20, max = 35, side = "contested" }, 
    [1425] = { min = 40, max = 50, side = "contested" }, 
    [1426] = { min = 1, max = 10, side = "Alliance" }, 
    [1427] = { min = 45, max = 50, side = "contested" }, 
    [1428] = { min = 50, max = 58, side = "contested" }, 
    [1429] = { min = 1, max = 10, side = "Alliance" }, 
    [1430] = { min = 55, max = 60, side = "contested" }, 
    [1431] = { min = 18, max = 30, side = "contested" }, 
    [1432] = { min = 10, max = 20, side = "Alliance" }, 
    [1433] = { min = 15, max = 25, side = "contested" }, 
    [1434] = { min = 30, max = 45, side = "contested" }, 
    [1435] = { min = 35, max = 45, side = "contested" }, 
    [1436] = { min = 10, max = 20, side = "Alliance" }, 
    [1437] = { min = 20, max = 30, side = "contested" }, 
    [1438] = { min = 1, max = 10, side = "Alliance" }, 
    [1439] = { min = 10, max = 20, side = "Alliance" }, 
    [1440] = { min = 18, max = 30, side = "contested" }, 
    [1441] = { min = 25, max = 35, side = "contested" }, 
    [1442] = { min = 15, max = 27, side = "contested" }, 
    [1443] = { min = 30, max = 40, side = "contested" }, 
    [1444] = { min = 40, max = 50, side = "contested" }, 
    [1445] = { min = 35, max = 45, side = "contested" }, 
    [1446] = { min = 40, max = 50, side = "contested" }, 
    [1447] = { min = 45, max = 55, side = "contested" }, 
    [1448] = { min = 48, max = 55, side = "contested" }, 
    [1449] = { min = 48, max = 55, side = "contested" }, 
    [1450] = { min = 55, max = 60, side = "contested" }, 
    [1451] = { min = 55, max = 60, side = "contested" }, 
    [1452] = { min = 53, max = 60, side = "contested" }, 
    [1453] = { side = "Alliance" }, 
    [1454] = { side = "Horde" }, 
    [1455] = { side = "Alliance" }, 
    [1456] = { side = "Horde" }, 
    [1457] = { side = "Alliance" }, 
    [1458] = { side = "Horde" }, 
}
WML.ZONES = ZONES


local TERRITORY_COLOR = {
    sanctuary = "ff69ccf0", 
    friendly  = "ff19ff19", 
    hostile   = "ffff1919", 
    contested = "ffffb200", 
    combat    = "ffff1919",
    arena     = "ffff1919",
}
WML.TERRITORY_COLOR = TERRITORY_COLOR

local function Cfg()
    return ThugUIDB and ThugUIDB.WorldMap or ThugUI.defaults.WorldMap
end

local function Usable(v)
    return v ~= nil and not (issecretvalue and issecretvalue(v))
end

local function Hex(c)
    if type(c) ~= "table" then return nil end
    return string.format("ff%02x%02x%02x",
        math.floor((c.r or 1) * 255 + 0.5),
        math.floor((c.g or 1) * 255 + 0.5),
        math.floor((c.b or 1) * 255 + 0.5))
end



function WML:GetTerritory(mapID)
    
    
    local okMap, here = pcall(C_Map.GetBestMapForUnit, "player")
    if okMap and Usable(here) and here == mapID and C_PvP and C_PvP.GetZonePVPInfo then
        local ok, pvpType = pcall(C_PvP.GetZonePVPInfo)
        if ok and Usable(pvpType) and TERRITORY_COLOR[pvpType] then
            return pvpType
        end
    end

    local zone = ZONES[mapID]
    if not zone or not zone.side then return nil end
    if zone.side == "contested" then return "contested" end
    local mine = UnitFactionGroup("player")
    if not Usable(mine) then return nil end
    return zone.side == mine and "friendly" or "hostile"
end


function WML:GetLevels(mapID)
    if C_Map.GetMapLevels then
        local ok, lo, hi = pcall(C_Map.GetMapLevels, mapID)
        if ok and Usable(lo) and Usable(hi) and lo > 0 and hi > 0 then
            return lo, hi, "client"
        end
    end
    local zone = ZONES[mapID]
    if zone and zone.min then return zone.min, zone.max, "table" end
end





function WML:GetLevelColor(lo, hi)
    local level = UnitLevel("player")
    if not Usable(level) or not GetQuestDifficultyColor then return nil end
    if level < lo then
        return Hex(GetQuestDifficultyColor(lo))
    elseif level > hi then
        return Hex(GetQuestDifficultyColor(hi - 2))
    end
    local difficult = QuestDifficultyColors and QuestDifficultyColors["difficult"]
    return Hex(difficult) or "ffffff00"
end


function WML:BuildText(mapID, name)
    local cfg = Cfg()
    local text = name
    local decorated = false

    if cfg.colorNames then
        local territory = self:GetTerritory(mapID)
        if territory then
            text = "|c" .. TERRITORY_COLOR[territory] .. name .. "|r"
            decorated = true
        end
    end

    if cfg.showLevels then
        local lo, hi = self:GetLevels(mapID)
        if lo then
            local range = lo == hi and ("(" .. hi .. ")") or ("(" .. lo .. "-" .. hi .. ")")
            local color = cfg.colorLevels and self:GetLevelColor(lo, hi)
            if color then range = "|c" .. color .. range .. "|r" end
            text = text .. " " .. range
            decorated = true
        end
    end

    return decorated and text or nil
end




local function ZoneUnderCursor(map)
    local mapID = map:GetMapID()
    local x, y
    local gamepad = InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()
        and (map:HasGamepadCursorInput() or not map:IsCanvasMouseFocusOrPinFocus())
    if gamepad then
        x, y = map:GetNormalizedGamepadCursorPosition()
    else
        x, y = map:GetNormalizedCursorPosition()
    end
    if not (x and y) then return nil end
    local info = C_Map.GetMapInfoAtPosition(mapID, x, y)
    if info and info.mapID ~= mapID then return info end
end








local lastPlain, lastWritten
local logged = 0

local function ApplyTint(label)
    
    
    if Cfg().colorNames then
        label.Name:SetVertexColor(1, 1, 1)
    elseif AREA_NAME_FONT_COLOR then
        label.Name:SetVertexColor(AREA_NAME_FONT_COLOR:GetRGB())
    end
end

local function PostEvaluate(label)
    if not Cfg().enabled then return end
    local info = label:GetHighestPriorityLabelInfo()
    local areaType = MAP_AREA_LABEL_TYPE and MAP_AREA_LABEL_TYPE.AREA_NAME
    if not info or not areaType or info ~= label.labelInfoByType[areaType] then return end

    local shown = label.Name:GetText()
    if not Usable(shown) or (lastWritten and shown == lastWritten) then return end

    
    if shown == lastPlain then
        if lastWritten then
            label.Name:SetText(lastWritten)
            ApplyTint(label)
        end
        return
    end

    lastPlain, lastWritten = shown, nil
    local map = label.dataProvider and label.dataProvider:GetMap()
    if not map then return end
    local zone = ZoneUnderCursor(map)
    
    
    if not zone or not Usable(zone.name) or type(info.name) ~= "string"
        or info.name:sub(1, #zone.name) ~= zone.name then
        return
    end

    local text = WML:BuildText(zone.mapID, zone.name)
    if not text then return end
    label.Name:SetText(text)
    ApplyTint(label)
    lastWritten = text

    logged = logged + 1
    if logged <= 10 and ThugUI.Diagnostics then
        local lo, hi, src = WML:GetLevels(zone.mapID)
        ThugUI.Diagnostics:Log("WORLDMAP", "label %d: map %d territory=%s levels=%s-%s from %s",
            logged, zone.mapID, tostring(WML:GetTerritory(zone.mapID)),
            tostring(lo), tostring(hi), tostring(src))
    end
end




local function FindAreaLabel()
    local map = _G.WorldMapFrame
    if not (map and map.dataProviders) then return nil end
    for provider in pairs(map.dataProviders) do
        local label = type(provider) == "table" and provider.Label
        if label and label.EvaluateLabels and label.labelInfoByType and label.Name then
            return label
        end
    end
end

function WML:Hook()
    if self.hooked then return true end
    local label = FindAreaLabel()
    if not label then return false end
    hooksecurefunc(label, "EvaluateLabels", function(l)
        local ok, err = pcall(PostEvaluate, l)
        if not ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:LogOnce("worldmap-label", "WORLDMAP", "label update failed: %s", tostring(err))
        end
    end)
    self.hooked = true
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("WORLDMAP", "zone label hooked")
    end
    return true
end


function WML:Refresh()
    lastPlain, lastWritten = nil, nil
end

function WML:Initialize()
    
    
    local watch = CreateFrame("Frame")
    ThugUI.SafeRegisterEvent(watch, "PLAYER_LEVEL_UP")
    ThugUI.SafeRegisterEvent(watch, "ZONE_CHANGED_NEW_AREA")
    watch:SetScript("OnEvent", function() WML:Refresh() end)

    if self:Hook() then return end
    
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(frame)
        if WML:Hook() then frame:UnregisterEvent("ADDON_LOADED") end
    end)
end
