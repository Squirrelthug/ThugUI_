















local ThugUI = _G.ThugUI
local MP = {}
ThugUI.MinimapPanel = MP
ThugUI:RegisterModule("MinimapPanel", MP)

ThugUI.defaults.MinimapPanel = {
    enabled = true,
    scale = 1,
    unlocked = false,
    showDiel = true,
    popupColumns = 4,
    zoneTextOffset = 4,  
    hidden = {}
}

local function DeepCopyTable(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = DeepCopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function GetMinimapMode()
    if ThugUI.moduleOn ~= nil then
        return ThugUI.minimapMode
    end
    if ThugUI.minimapMode ~= nil then
        return ThugUI.minimapMode
    end
    if ThugUI.IsModuleOn then
        if ThugUI:IsModuleOn("controller") then
            return "controller"
        elseif ThugUI:IsModuleOn("minimapmouse") then
            return "mouse"
        end
    end
    return nil
end

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    local mode = GetMinimapMode()
    if mode == "mouse" then
        if ThugUIDB.MinimapMouse == nil then
            local seed = DeepCopyTable(ThugUI.defaults and ThugUI.defaults.MinimapPanel or {})
            if type(ThugUIDB.MinimapPanel) == "table" then
                for k, v in pairs(ThugUIDB.MinimapPanel) do
                    seed[k] = DeepCopyTable(v)
                end
            end
            ThugUIDB.MinimapMouse = seed
        end
        return ThugUIDB.MinimapMouse
    end
    return ThugUIDB.MinimapPanel
end

function MP:GetVisibilityKey()
    return GetMinimapMode() == "mouse" and "minimapMouse" or "minimap"
end


local PAD_BACK = GAMEPAD_FACE_RIGHT or "PAD2"



local LOW_PRIORITY_TRACKING_SPELLS = {
    [261764] = true, 
}
local TRACKING_SPELL_OVERRIDE_ATLAS = {
    [43308] = "professions_tracking_fish",
    [2580] = "professions_tracking_ore",
    [8388] = "professions_tracking_ore",
    [2383] = "professions_tracking_herb",
    [8387] = "professions_tracking_herb",
    [122026] = "WildBattlePetCapturable",
}

local collectedButtons = {}
local hookedButtons = {}


local cellOf = setmetatable({}, { __mode = "k" })


function MP.CellOf(frame) return cellOf[frame] end

function MP:GetCollectedButtons()
    return collectedButtons
end

local function ReanchorAddonButton(button)
    if MP.reanchoring then return end
    if button:GetParent() ~= MP.popup then return end
    MP.reanchoring = true
    button:ClearAllPoints()
    button:SetPoint("CENTER", cellOf[button], "CENTER")
    MP.reanchoring = false
end

local function HookAddonButton(button)
    if hookedButtons[button] then return end
    hookedButtons[button] = true
    
    button:SetScript("OnDragStart", nil)
    button:SetScript("OnDragStop", nil)
    hooksecurefunc(button, "SetPoint", function(self)
        if self:GetParent() == MP.popup and cellOf[self] then
            ReanchorAddonButton(self)
        end
    end)
end

local skipNames = {
    ["MinimapBackdrop"] = true,
    ["ExpansionLandingPageMinimapButton"] = true,
    ["GameTimeFrame"] = true,
    ["ThugUI_MinimapPopupButton"] = true,
    ["ThugUI_MinimapHolder"] = true,
}

local function IsAddonButton(child)
    if Minimap and (child == Minimap.ZoomIn or child == Minimap.ZoomOut or child == Minimap.ZoomHitArea) then return false end
    local name = child:GetName()
    if type(name) ~= "string" then return false end
    if skipNames[name] then return false end
    if name:find("^Minimap") or name:find("^MiniMap") then return false end
    if Minimap and (child == Minimap.ZoomIn or child == Minimap.ZoomOut or child == Minimap.ZoomHitArea) then return false end
    local oType = child:GetObjectType()
    if oType ~= "Button" and oType ~= "Frame" then return false end
    if not child:IsMouseEnabled() then return false end
    return true
end

function MP:CollectAddonButtons()
    if not Minimap then return end
    local children = {Minimap:GetChildren()}
    if MinimapCluster and MinimapCluster.MinimapContainer then
        local c2 = {MinimapCluster.MinimapContainer:GetChildren()}
        for _, c in ipairs(c2) do table.insert(children, c) end
    end
    local backdrop = Minimap.MinimapBackdrop or _G.MinimapBackdrop
    if type(backdrop) == "table" and backdrop.GetChildren then
        local c3 = {backdrop:GetChildren()}
        for _, c in ipairs(c3) do table.insert(children, c) end
    end
    
    for _, child in ipairs(children) do
        if IsAddonButton(child) then
            local already = false
            for _, btn in ipairs(collectedButtons) do
                if btn == child then already = true; break end
            end
            if not already then
                table.insert(collectedButtons, child)
                HookAddonButton(child)
                if child:GetName() == "ThugUI_MinimapButton" and ThugUI.MinimapButton then
                    ThugUI.MinimapButton:SetDocked(true)
                end
            end
        end
    end
end

local popupCells = {}

local function ReanchorIndicatorChildren()
    if MinimapCluster and MinimapCluster.IndicatorFrame then
        local mail = MinimapCluster.IndicatorFrame.MailFrame
        local crafting = MinimapCluster.IndicatorFrame.CraftingOrderFrame
        if mail and cellOf[mail] and mail:GetParent() == MP.popup then
            mail:ClearAllPoints()
            mail:SetPoint("CENTER", cellOf[mail], "CENTER")
        end
        if crafting and cellOf[crafting] and crafting:GetParent() == MP.popup then
            crafting:ClearAllPoints()
            crafting:SetPoint("CENTER", cellOf[crafting], "CENTER")
        end
    end
end

function MP:RefreshPopup()
    if not self.popup then return end
    
    local c = Cfg()
    local popupColumns = c.popupColumns or 4
    local cellSize = 32
    
    local visibleItems = {}
    
    local function AddToGrid(frame)
        if frame and frame:IsShown() then
            table.insert(visibleItems, frame)
        end
    end
    
    
    if not MP.trackingBtn then
        local btn = CreateFrame("Button", nil, self.popup)
        btn:SetSize(cellSize, cellSize)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("ui-hud-minimap-tracking-up")
        if info then
            tex:SetAtlas("ui-hud-minimap-tracking-up")
        else
            tex:SetTexture("Interface\\Minimap\\Tracking\\None")
        end
        btn:SetScript("OnClick", function()
            if MP.trackingWindow:IsShown() then
                MP.trackingWindow:Hide()
            else
                if not ThugUI.CombatClose:Allow("minimapTracking") then return end
                MP.trackingWindow:Show()
            end
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(TRACKING or "Tracking", 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        MP.trackingBtn = btn
    end
    table.insert(visibleItems, MP.trackingBtn)
    
    
    if MinimapCluster and MinimapCluster.IndicatorFrame then
        local mail = MinimapCluster.IndicatorFrame.MailFrame
        local crafting = MinimapCluster.IndicatorFrame.CraftingOrderFrame
        if mail then
            mail:SetParent(self.popup)
            AddToGrid(mail)
        end
        if crafting then
            crafting:SetParent(self.popup)
            AddToGrid(crafting)
        end
    end
    if MinimapCluster and MinimapCluster.InstanceDifficulty then
        MinimapCluster.InstanceDifficulty:SetParent(self.popup)
        AddToGrid(MinimapCluster.InstanceDifficulty)
    end
    if GameTimeFrame then
        GameTimeFrame:SetParent(self.popup)
        AddToGrid(GameTimeFrame)
    end
    
    
    local sortedAddons = {}
    for _, btn in ipairs(collectedButtons) do
        if not c.hidden[btn:GetName()] then
            table.insert(sortedAddons, btn)
        end
    end
    table.sort(sortedAddons, function(a, b) return (a:GetName() or "") < (b:GetName() or "") end)
    for _, btn in ipairs(sortedAddons) do
        btn:SetParent(self.popup)
        AddToGrid(btn)
    end
    
    
    if not MP.compartmentPool then MP.compartmentPool = {} end
    for _, btn in ipairs(MP.compartmentPool) do btn:Hide() end
    
    local poolIdx = 1
    if AddonCompartmentFrame and AddonCompartmentFrame.registeredAddons then
        for _, data in ipairs(AddonCompartmentFrame.registeredAddons) do
            local btn = MP.compartmentPool[poolIdx]
            if not btn then
                btn = CreateFrame("Button", nil, self.popup)
                btn:SetSize(cellSize, cellSize)
                local tex = btn:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints()
                btn.icon = tex
                MP.compartmentPool[poolIdx] = btn
            end
            
            if data.icon then
                local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(data.icon)
                if info then
                    btn.icon:SetAtlas(data.icon)
                else
                    btn.icon:SetTexture(data.icon)
                end
            end
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(data.text or "", 1, 1, 1)
                if data.funcOnEnter then
                    pcall(data.funcOnEnter, self)
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                if data.funcOnLeave then
                    pcall(data.funcOnLeave, self)
                end
            end)
            btn:SetScript("OnClick", function(self, mouseButton)
                if data.func then
                    pcall(data.func, self, { buttonName = mouseButton }, data)
                end
            end)
            
            btn:Show()
            table.insert(visibleItems, btn)
            poolIdx = poolIdx + 1
        end
    end
    
    
    local rows = math.ceil(#visibleItems / popupColumns)
    if rows == 0 then rows = 1 end
    
    local margin = 6
    local spacing = 4
    self.popup:SetWidth(margin * 2 + popupColumns * cellSize + (popupColumns - 1) * spacing)
    self.popup:SetHeight(margin * 2 + rows * cellSize + (rows - 1) * spacing)
    
    for i, item in ipairs(visibleItems) do
        local r = math.floor((i - 1) / popupColumns)
        local cIdx = (i - 1) % popupColumns
        
        local cell = popupCells[i]
        if not cell then
            cell = CreateFrame("Frame", nil, self.popup)
            cell:SetSize(cellSize, cellSize)
            popupCells[i] = cell
        end
        cell:SetPoint("TOPLEFT", self.popup, "TOPLEFT", margin + cIdx * (cellSize + spacing), -(margin + r * (cellSize + spacing)))
        cell:Show()
        
        cellOf[item] = cell
        item:ClearAllPoints()
        item:SetPoint("CENTER", cell, "CENTER")
    end
    for i = #visibleItems + 1, #popupCells do
        popupCells[i]:Hide()
    end
    
    ReanchorIndicatorChildren()
    
    
    self.popup:ClearAllPoints()
    local cx = UIParent:GetWidth() / 2
    local hx = self.holder:GetCenter()
    if hx and hx < cx then
        self.popup:SetPoint("LEFT", self.holder, "RIGHT", 10, 0)
        self.trackingWindow:SetPoint("LEFT", self.popup, "RIGHT", 10, 0)
    else
        self.popup:SetPoint("RIGHT", self.holder, "LEFT", -10, 0)
        self.trackingWindow:SetPoint("RIGHT", self.popup, "LEFT", -10, 0)
    end
end

function MP:CreatePopup()
    local popupButton = CreateFrame("Button", "ThugUI_MinimapPopupButton", self.holder)
    self.popupButton = popupButton
    popupButton:SetSize(20, 20)
    popupButton:SetPoint("CENTER", Minimap, "BOTTOMRIGHT", -18, 18)
    
    
    
    popupButton:SetFrameStrata("MEDIUM")
    popupButton:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 20)
    
    local tex = popupButton:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\AddOns\\ThugUI\\media\\Acorn.tga")
    tex:SetDesaturated(true)
    
    popupButton:SetAlpha(0)
    
    local lastCheck = 0
    self.holder:SetScript("OnUpdate", function(self, elapsed)
        lastCheck = lastCheck + elapsed
        if lastCheck >= 0.1 then
            lastCheck = 0
            if self:IsMouseOver(8, -8, -8, 8) or (MP.popup and MP.popup:IsShown()) then
                popupButton:SetAlpha(1)
            else
                popupButton:SetAlpha(0)
            end
        end
    end)
    
    local popup = CreateFrame("Frame", "ThugUI_MinimapPopup", UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    popup:SetBackdropColor(0.04, 0.04, 0.06, 0.96)
    popup:Hide()
    self.popup = popup
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("minimapPopup", function() return self.popup and self.popup:IsShown() end, function() self.popup:Hide() end)
    end
    
    
    
    
    popup.Layout = function()
        if popup:IsShown() then MP:RefreshPopup() end
    end
    
    popupButton:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
        else
            if not ThugUI.CombatClose:Allow("minimapPopup") then return end
            MP:CollectAddonButtons()
            MP:RefreshPopup()
            popup:Show()
        end
    end)
    
    popup:SetScript("OnShow", function(self)
        if not InCombatLockdown() then
            self:EnableKeyboard(true)
            if self.EnableGamePadButton then
                pcall(self.EnableGamePadButton, self, true)
            end
        end
        MP:CollectAddonButtons()
        MP:RefreshPopup()
    end)
    popup:SetScript("OnHide", function(self)
        
        if MP.trackingWindow then MP.trackingWindow:Hide() end
        self:EnableKeyboard(false)
        if self.EnableGamePadButton then
            pcall(self.EnableGamePadButton, self, false)
        end
    end)
    popup:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self:EnableKeyboard(false)
            if self.EnableGamePadButton then
                pcall(self.EnableGamePadButton, self, false)
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if self:IsShown() then
                self:EnableKeyboard(true)
                if self.EnableGamePadButton then
                    pcall(self.EnableGamePadButton, self, true)
                end
            end
        end
    end)
    popup:RegisterEvent("PLAYER_REGEN_DISABLED")
    popup:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    
    
    
    
    
    
    local function Back(self)
        if MP.trackingWindow and MP.trackingWindow:IsShown() then
            MP.trackingWindow:Hide()
        else
            self:Hide()
        end
    end
    popup:SetScript("OnKeyDown", function(self, key)
        
        
        if InCombatLockdown() then return end
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            Back(self)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    popup:SetScript("OnGamePadButtonDown", function(self, btn)
        if InCombatLockdown() then return end
        if btn == PAD_BACK then
            self:SetPropagateKeyboardInput(false)
            Back(self)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    
    hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", ReanchorIndicatorChildren)
    if _G.MiniMapIndicatorFrame_UpdatePosition then
        hooksecurefunc("MiniMapIndicatorFrame_UpdatePosition", ReanchorIndicatorChildren)
    end
end

local function CanDisplayTrackingInfo(index)
    if not C_Minimap.GetTrackingFilter then return true end
    local filter = C_Minimap.GetTrackingFilter(index)
    if not filter then return false end
    if MinimapConstants and MinimapConstants.OPTIONAL_FILTERS then
        return MinimapConstants.OPTIONAL_FILTERS[filter.filterID] or filter.spellID
    end
    return filter.spellID
end

local twRows = {}
function MP:GetTrackingRows() return twRows end
function MP:RefreshTrackingWindow()
    local tw = self.trackingWindow
    if not tw or not tw:IsShown() then return end
    
    for _, row in ipairs(twRows) do row:Hide() end
    
    local yOffset = -20
    local function GetRow(idx)
        if not twRows[idx] then
            local btn = CreateFrame("Button", nil, tw)
            btn:SetSize(180, 20)
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", 4, 0)
            btn.icon = icon
            
            local name = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            name:SetPoint("LEFT", icon, "RIGHT", 4, 0)
            name:SetPoint("RIGHT", -20, 0)
            name:SetJustifyH("LEFT")
            btn.name = name
            
            local check = btn:CreateTexture(nil, "OVERLAY")
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:SetSize(16, 16)
            check:SetPoint("RIGHT", -4, 0)
            btn.check = check
            
            twRows[idx] = btn
        end
        return twRows[idx]
    end
    
    local rowIdx = 1
    
    local uncheckRow = GetRow(rowIdx)
    rowIdx = rowIdx + 1
    uncheckRow.icon:SetTexture(nil)
    uncheckRow.name:SetText(UNCHECK_ALL or "Uncheck All")
    uncheckRow.name:SetTextColor(1, 1, 1)
    uncheckRow.check:Hide()
    uncheckRow:SetPoint("TOPLEFT", tw, "TOPLEFT", 10, yOffset)
    uncheckRow:SetScript("OnClick", function()
        if C_Minimap.ClearAllTracking then
            C_Minimap.ClearAllTracking()
        end
        if MinimapConstants and MinimapConstants.ALWAYS_ON_FILTERS then
            for index = 1, C_Minimap.GetNumTrackingTypes() do
                local filter = C_Minimap.GetTrackingFilter(index)
                if filter and (MinimapConstants.ALWAYS_ON_FILTERS[filter.filterID] or (MinimapConstants.CONDITIONAL_FILTERS and MinimapConstants.CONDITIONAL_FILTERS[filter.filterID])) then
                    if C_Minimap.SetTracking then
                        C_Minimap.SetTracking(index, true)
                    end
                end
            end
        end
        MP:RefreshTrackingWindow()
    end)
    uncheckRow:EnableMouse(true)
    uncheckRow:Show()
    yOffset = yOffset - 24
    
    local showAll = false
    if GetCVarBool then showAll = GetCVarBool("minimapTrackingShowAll") end
    local class = select(2, UnitClass("player"))
    local isHunterClass = class == "HUNTER"
    
    local hunterInfo = {}
    local townfolkInfo = {}
    local regularInfo = {}
    
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        if showAll or CanDisplayTrackingInfo(i) then
            local info = C_Minimap.GetTrackingInfo(i)
            if info then
                info.index = i
                if isHunterClass and info.subType == (_G.HUNTER_TRACKING or 1) then
                    table.insert(hunterInfo, info)
                elseif info.subType == (_G.TOWNSFOLK_TRACKING or 2) then
                    table.insert(townfolkInfo, info)
                else
                    table.insert(regularInfo, info)
                end
            end
        end
    end
    
    local function SortFunc(a, b)
        local filterA = C_Minimap.GetTrackingFilter(a.index)
        local filterB = C_Minimap.GetTrackingFilter(b.index)
        local lowA = filterA and LOW_PRIORITY_TRACKING_SPELLS[filterA.spellID] or false
        local lowB = filterB and LOW_PRIORITY_TRACKING_SPELLS[filterB.spellID] or false
        if lowA ~= lowB then return not lowA end
        return a.index < b.index
    end
    table.sort(hunterInfo, SortFunc)
    table.sort(townfolkInfo, SortFunc)
    table.sort(regularInfo, SortFunc)
    
    local function AddHeaderRow(text)
        local row = GetRow(rowIdx)
        rowIdx = rowIdx + 1
        row.icon:SetTexture(nil)
        row.name:SetText(text)
        row.name:SetTextColor(1, 0.82, 0)
        row.check:Hide()
        row:SetPoint("TOPLEFT", tw, "TOPLEFT", 10, yOffset)
        row:SetScript("OnClick", nil)
        row:EnableMouse(false)
        row:Show()
        yOffset = yOffset - 20
    end
    
    local function AddTypeRow(info)
        local row = GetRow(rowIdx)
        rowIdx = rowIdx + 1
        
        
        
        local atlas = info.spellID and TRACKING_SPELL_OVERRIDE_ATLAS[info.spellID]
        row.icon:SetTexCoord(0, 1, 0, 1)
        if atlas then
            row.icon:SetAtlas(atlas)
        else
            row.icon:SetTexture(info.texture)
            if info.type == "spell" then
                row.icon:SetTexCoord(0.0625, 0.9, 0.0625, 0.9)
            end
        end
        row.name:SetText(info.name)
        row.name:SetTextColor(1, 1, 1)
        row.check:SetShown(info.active)
        row:SetPoint("TOPLEFT", tw, "TOPLEFT", 10, yOffset)
        row:EnableMouse(true)
        
        
        
        
        
        
        row:SetScript("OnClick", function()
            if C_Minimap.SetTracking then
                C_Minimap.SetTracking(info.index, not info.active)
                info.active = not info.active
                row.check:SetShown(info.active)
            end
        end)
        row:Show()
        yOffset = yOffset - 20
    end
    
    if #hunterInfo > 0 then
        if #hunterInfo > 1 then AddHeaderRow(HUNTER_TRACKING_TEXT or "Hunter Tracking") end
        for _, info in ipairs(hunterInfo) do AddTypeRow(info) end
    end
    if #townfolkInfo > 0 then
        if showAll then AddHeaderRow(TOWNSFOLK_TRACKING_TEXT or "Townsfolk") end
        for _, info in ipairs(townfolkInfo) do AddTypeRow(info) end
    end
    for _, info in ipairs(regularInfo) do AddTypeRow(info) end
    
    tw:SetHeight(math.abs(yOffset) + 20)
end

function MP:CreateTrackingWindow()
    local tw = CreateFrame("Frame", "ThugUI_MinimapTracking", UIParent, "BackdropTemplate")
    tw:SetFrameStrata("DIALOG")
    tw:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    tw:SetBackdropColor(0.04, 0.04, 0.06, 0.96)
    tw:SetWidth(200)
    tw:Hide()
    self.trackingWindow = tw
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("minimapTracking", function() return self.trackingWindow and self.trackingWindow:IsShown() end, function() self.trackingWindow:Hide() end)
    end
    
    
    tw:SetScript("OnShow", function(self)
        self:RegisterEvent("MINIMAP_UPDATE_TRACKING")
        MP:RefreshTrackingWindow()
    end)
    tw:SetScript("OnHide", function(self)
        self:UnregisterEvent("MINIMAP_UPDATE_TRACKING")
    end)
    tw:SetScript("OnEvent", function(self, event)
        if event == "MINIMAP_UPDATE_TRACKING" then
            MP:RefreshTrackingWindow()
        end
    end)
end







local ZONE_COLORS = {
    sanctuary = { 0.41, 0.8, 0.94 },
    arena     = { 1.0, 0.1, 0.1 },
    friendly  = { 0.1, 1.0, 0.1 },
    hostile   = { 1.0, 0.1, 0.1 },
    contested = { 1.0, 0.7, 0.0 },
    combat    = { 1.0, 0.1, 0.1 },
}

function MP:UpdateZoneText()
    self.zoneText:SetText(GetMinimapZoneText())
    local pvpType = C_PvP and C_PvP.GetZonePVPInfo and C_PvP.GetZonePVPInfo()
    local c = type(pvpType) == "string" and ZONE_COLORS[pvpType]
    if c then
        self.zoneText:SetTextColor(c[1], c[2], c[3])
    else
        local n = NORMAL_FONT_COLOR or { r = 1.0, g = 0.82, b = 0.0 }
        self.zoneText:SetTextColor(n.r, n.g, n.b)
    end
end





function MP:PlaceHolder()
    local c = Cfg()
    local holder = self.holder
    local s = holder:GetScale() or 1
    holder:ClearAllPoints()
    local p = c.point
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        holder:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x / s, p.y / s)
    else
        holder:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function MP:SaveHolderPoint()
    local x, y = self.holder:GetCenter()
    if not x then return end
    local s = self.holder:GetScale() or 1
    Cfg().point = { x = x * s, y = y * s }
end



function MP:PlaceZoneText()
    if not self.zoneText then return end
    local y = tonumber(Cfg().zoneTextOffset) or 4
    self.zoneText:ClearAllPoints()
    self.zoneText:SetPoint("BOTTOM", Minimap, "TOP", 0, y)
end

function MP:ApplySettings()
    local c = Cfg()
    if not self.active then return end
    if self.holder then
        self.holder:SetScale(c.scale or 1)
        if c.unlocked then
            self.holder:RegisterForDrag("LeftButton")
            self.overlay:Show()
            self.holder.outline:Show()
        else
            self.holder:RegisterForDrag()
            self.holder:SetScript("OnDragStart", nil)
            self.holder:SetScript("OnDragStop", nil)
            self.overlay:Hide()
            self.holder.outline:Hide()
        end
        
        self:PlaceHolder()
        
        if MinimapCluster and MinimapCluster.DielFrame then
            if c.showDiel then
                MinimapCluster.DielFrame:Show()
            else
                MinimapCluster.DielFrame:Hide()
            end
        end
    end
    self:PlaceZoneText()
    self:RefreshPopup()
end

function MP:TakeOver()
    if self.active then return end
    if not GetMinimapMode() then return end
    if not Cfg().enabled then return end
    if not Minimap or not MinimapCluster then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("MINIMAP", "Minimap or MinimapCluster missing")
        end
        return
    end

    self.active = true
    
    local holder = CreateFrame("Frame", "ThugUI_MinimapHolder", UIParent)
    holder:SetSize(Minimap:GetWidth(), Minimap:GetHeight())
    holder:SetFrameStrata("LOW")
    self.holder = holder
    
    
    
    
    local mx, my = Minimap:GetCenter()
    if type(Cfg().point) ~= "table" or type(Cfg().point.x) ~= "number" then
        Cfg().point = nil
        if mx and my then
            local k = (Minimap:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
            Cfg().point = { x = mx * k, y = my * k }
        end
    end
    
    Minimap:SetParent(holder)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER")
    
    if MinimapCluster.DielFrame then
        MinimapCluster.DielFrame:SetParent(holder)
        MinimapCluster.DielFrame:ClearAllPoints()
        MinimapCluster.DielFrame:SetPoint("CENTER", Minimap, "CENTER", 63, 72)
        if not Cfg().showDiel then MinimapCluster.DielFrame:Hide() end
        
        hooksecurefunc(MinimapCluster, "SetEditModeScale", function()
            if MinimapCluster.DielFrame:GetParent() == holder then
                MinimapCluster.DielFrame:ClearAllPoints()
                MinimapCluster.DielFrame:SetPoint("CENTER", Minimap, "CENTER", 63, 72)
            end
        end)
    end
    
    MinimapCluster:Hide()
    MinimapCluster:HookScript("OnShow", function(f)
        if MP.active then f:Hide() end
    end)
    
    
    
    
    
    local zoneFrame = CreateFrame("Frame", nil, holder)
    zoneFrame:SetAllPoints(holder)
    zoneFrame:SetFrameStrata("MEDIUM")
    zoneFrame:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 20)
    self.zoneFrame = zoneFrame
    local zoneText = zoneFrame:CreateFontString("ThugUI_MinimapZoneText", "OVERLAY", "GameFontNormal")
    self.zoneText = zoneText
    self:PlaceZoneText()
    
    holder:RegisterEvent("ZONE_CHANGED")
    holder:RegisterEvent("ZONE_CHANGED_INDOORS")
    holder:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    
    
    
    holder:RegisterEvent("PLAYER_ENTERING_WORLD")
    ThugUI.SafeRegisterEvent(holder, "SETTINGS_LOADED")
    holder:SetScript("OnEvent", function() MP:UpdateZoneText() end)
    self:UpdateZoneText()
    
    local outline = CreateFrame("Frame", nil, holder, "BackdropTemplate")
    outline:SetAllPoints(Minimap)
    outline:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    outline:SetBackdropBorderColor(1, 0.82, 0, 1)
    outline:Hide()
    holder.outline = outline
    
    local overlay = CreateFrame("Button", nil, holder)
    overlay:SetAllPoints(Minimap)
    overlay:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetScript("OnDragStart", function() holder:StartMoving() end)
    overlay:SetScript("OnDragStop", function()
        holder:StopMovingOrSizing()
        MP:SaveHolderPoint()
        MP:PlaceHolder()
    end)
    overlay:Hide()
    self.overlay = overlay
    
    holder:SetMovable(true)

    
    
    
    if ThugUI.Visibility then self:ApplyVisibility(ThugUI.Visibility:Alpha(MP:GetVisibilityKey())) end
    self:CreatePopup()
    self:CreateTrackingWindow()
    self:ApplySettings()
    
    
    
    
    local function CollectAndPlace()
        MP:CollectAddonButtons()
        MP:RefreshPopup()
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("MINIMAP", "collected %d addon button(s)", #collectedButtons)
        end
    end
    CollectAndPlace()
    C_Timer.After(5, CollectAndPlace)
end













local function NotifyFocusedQuest()
    local FQ = ThugUI.modules and ThugUI.modules.FocusedQuest
    if FQ and FQ.ApplySettings then pcall(FQ.ApplySettings, FQ) end
end

function MP:SetHiddenForCombat(hidden)
    hidden = hidden and true or false
    if not self.holder then return end
    if self.hiddenForCombat == hidden then return end
    self.hiddenForCombat = hidden
    if hidden then
        self.holder:Hide()
        if self.popup then self.popup:Hide() end
        if self.trackingWindow then self.trackingWindow:Hide() end
    else
        self.holder:Show()
    end
    NotifyFocusedQuest()
end








function MP:MigrateCombatToggle()
    local c = Cfg()
    if c.hideInCombat ~= true then return end
    c.hideInCombat = nil
    local visKey = MP:GetVisibilityKey()
    if ThugUI.Visibility and not (ThugUIDB.Visibility and ThugUIDB.Visibility[visKey]) then
        ThugUI.Visibility:Get(visKey).mode = "nocombat"
    end
end

function MP:ApplyVisibility(alpha)
    if not (self.active and self.holder) then return end
    if alpha == 0 then
        self:SetHiddenForCombat(true)
    else
        self:SetHiddenForCombat(false)
        self.holder:SetAlpha(alpha)
    end
end



if ThugUI.Visibility then
    if ThugUI.Visibility.KEYS then
        ThugUI.Visibility.KEYS.minimapMouse = true
    end
    ThugUI.Visibility:Register("minimap", function(alpha)
        if GetMinimapMode() == "controller" then MP:ApplyVisibility(alpha) end
    end)
    ThugUI.Visibility:Register("minimapMouse", function(alpha)
        if GetMinimapMode() == "mouse" then MP:ApplyVisibility(alpha) end
    end)
end

local loginFrame = CreateFrame("Frame")
loginFrame:SetScript("OnEvent", function(self, event)
    if not GetMinimapMode() then self:UnregisterAllEvents() return end
    if event == "PLAYER_LOGIN" or event == "PLAYER_REGEN_ENABLED" then
        if InCombatLockdown() then
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        self:UnregisterAllEvents()
        MP:TakeOver()
    end
end)

MP.loginFrame = loginFrame  

function MP:Initialize()
    if IsLoggedIn and IsLoggedIn() then
        loginFrame:GetScript("OnEvent")(loginFrame, "PLAYER_LOGIN")
    else
        loginFrame:RegisterEvent("PLAYER_LOGIN")
    end
    
    self:MigrateCombatToggle()

end
