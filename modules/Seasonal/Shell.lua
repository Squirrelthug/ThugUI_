
















ThugUI = ThugUI or {}











local Seasonal = ThugUI.Seasonal or {}
ThugUI.Seasonal = Seasonal
ThugUI:RegisterModule("Seasonal", Seasonal)

local W  





local WINDOW_WIDTH, WINDOW_HEIGHT = 840, 520
local TITLEBAR_HEIGHT = 24
local NAV_HEIGHT      = 26
local RAIL_WIDTH      = 210
local HEADER_HEIGHT   = 92






local RAIL_ROW_WIDTH  = RAIL_WIDTH - 32


local RAIL_FOOTER_HEIGHT = 54

local VAULT_BOX_SIZE, VAULT_BOX_GAP = 26, 4







local TRAY_ICON_SIZE, TRAY_ICON_GAP = 24, 6
local TRAY_ICONS_PER_ROW = 8




local TRAY_LEFT = 8 + 3 * (VAULT_BOX_SIZE + VAULT_BOX_GAP) + 44
local TRAY_CURRENCY_LEFT = TRAY_LEFT + TRAY_ICON_SIZE + TRAY_ICON_GAP





Seasonal.LAYOUT = {
    headerHeight = HEADER_HEIGHT,
    trayIconSize = TRAY_ICON_SIZE,
    trayIconGap = TRAY_ICON_GAP,
    trayIconsPerRow = TRAY_ICONS_PER_ROW,
    trayLeft = TRAY_LEFT,
    trayCurrencyLeft = TRAY_CURRENCY_LEFT,
}

local ROW_HEIGHT    = 22  
local BODY_HEIGHT    = 18  
local BODY_INDENT    = 14
local SECTION_GAP    = 4









local SECTIONS = {
    { id = "mplus",  label = "Mythic+" },
    { id = "raid",   label = "Raid" },
    { id = "delves", label = "Delves" },
    { id = "prey",   label = "Prey" },
    { id = "gear",   label = "Gear" },
}
Seasonal.SECTIONS = SECTIONS










local NAV_ONLY_SECTIONS = {
    { id = "suggested", label = "Suggested" },
    { id = "rewards", label = "Rewards" },
}
Seasonal.NAV_ONLY_SECTIONS = NAV_ONLY_SECTIONS




local ALL_SECTIONS = {}
for _, def in ipairs(SECTIONS) do ALL_SECTIONS[#ALL_SECTIONS + 1] = def end
for _, def in ipairs(NAV_ONLY_SECTIONS) do ALL_SECTIONS[#ALL_SECTIONS + 1] = def end
Seasonal.ALL_SECTIONS = ALL_SECTIONS

local NAV_TABS = {
    { id = "main",      label = "Main" },
    { id = "suggested", label = "Suggested" },
    { id = "gear",      label = "Gear" },
    { id = "mplus",     label = "Mythic+" },
    { id = "raid",      label = "Raid" },
    { id = "delves",    label = "Delves" },
    { id = "prey",      label = "Prey" },
    { id = "rewards",   label = "Rewards" },
}
Seasonal.NAV_TABS = NAV_TABS








Seasonal.refreshCallbacks = {}
function Seasonal:RegisterRefresh(fn)
    table.insert(self.refreshCallbacks, fn)
end

local db  

















local function EnsureDB()
    if not db then
        ThugUIDB = ThugUIDB or {}
        ThugUIDB.Seasonal = ThugUIDB.Seasonal or {}
        db = ThugUIDB.Seasonal
        db.collapsed = db.collapsed or {}
        if db.autoOpenWithCharacterFrame == nil then
            db.autoOpenWithCharacterFrame = true
        end
    end
    return db
end






local function SavePosition(f)
    local point, _, _, x, y = f:GetPoint()
    EnsureDB()
    db.window = db.window or {}
    db.window.point = point
    db.window.x = math.floor((x or 0) + 0.5)
    db.window.y = math.floor((y or 0) + 0.5)
end

local function RestorePosition(f)
    local pos = EnsureDB().window or {}
    f:ClearAllPoints()
    f:SetPoint(pos.point or "CENTER", UIParent, pos.point or "CENTER", pos.x or 0, pos.y or 0)
end

Seasonal.refreshCallbacks = Seasonal.refreshCallbacks or {}

function Seasonal:RegisterRefresh(fn)
    if type(fn) == "function" then
        table.insert(self.refreshCallbacks, fn)
    end
end

function Seasonal:RefreshCurrentNav()
    if type(self.refreshCallbacks) == "table" then
        for _, fn in ipairs(self.refreshCallbacks) do
            fn(self.selectedCharacterKey)
        end
    end
end

function Seasonal:SelectNav(id)
    id = id or "main"
    self.selectedNav = id
    self.activeNav = id
    for navID, btn in pairs(self.navButtons) do
        local selected = (navID == id)
        btn.selectedBG:SetShown(selected)
        local shade = selected and 1 or 0.75
        btn.label:SetTextColor(shade, shade, shade)
    end

    local isMain = (id == "main" or id == "" or id == nil)

    if isMain then
        if self.header then self.header:Show() end
        if self.bodyHost and self.header then
            self.bodyHost:ClearAllPoints()
            self.bodyHost:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -6)
            self.bodyHost:SetPoint("BOTTOMRIGHT", self.contentArea, "BOTTOMRIGHT", 0, 0)
        end
    else
        if self.header then self.header:Hide() end
        if self.bodyHost and self.contentArea then
            self.bodyHost:ClearAllPoints()
            self.bodyHost:SetPoint("TOPLEFT", self.contentArea, "TOPLEFT", 0, 0)
            self.bodyHost:SetPoint("BOTTOMRIGHT", self.contentArea, "BOTTOMRIGHT", 0, 0)
        end
    end

    self:PaintRail()
    self:RelayoutBody()
    self:RefreshCurrentNav()
end

function Seasonal:BuildNav(navRow)
    self.navButtons = {}

    local x = 4
    local tabWidth = 84
    for _, def in ipairs(NAV_TABS) do
        local btn = CreateFrame("Button", nil, navRow)
        btn:SetSize(tabWidth, NAV_HEIGHT - 4)
        btn:SetPoint("LEFT", navRow, "LEFT", x, 0)
        x = x + tabWidth + 4

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, 0.10)
        bg:Hide()
        btn.selectedBG = bg

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("CENTER")
        label:SetText(def.label)
        btn.label = label

        btn:SetScript("OnClick", function() Seasonal:SelectNav(def.id) end)
        W.AttachTooltip(btn, def.label, "View " .. def.label .. " section.")

        self.navButtons[def.id] = btn
    end

    self:SelectNav("main")
end





local function GetClassColor(classFileName)
    if type(classFileName) == "string" then
        local upper = classFileName:upper()
        if _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[upper] then
            local c = _G.RAID_CLASS_COLORS[upper]
            return c.r, c.g, c.b
        end
    end
    return 0.8, 0.8, 0.8
end

local function GetColorForIlvl(ilvl)
    if type(ilvl) ~= "number" or ilvl <= 0 then
        return 0.7, 0.7, 0.7, "b0b0b0"
    end

    local tr, tg, tb
    local fnTrack = Seasonal.TrackForItemLevel or (Seasonal.Vault and Seasonal.Vault.TrackForItemLevel)
    local fnColor = Seasonal.ColorForTrack or (Seasonal.Vault and Seasonal.Vault.ColorForTrack)
    if type(fnTrack) == "function" and type(fnColor) == "function" then
        local trackName = fnTrack(ilvl)
        if trackName then
            tr, tg, tb = fnColor(trackName)
        end
    end

    if not tr or not tg or not tb then
        if ilvl >= 318 then
            tr, tg, tb = 1.0, 0.5, 0.0
        elseif ilvl >= 305 then
            tr, tg, tb = 0.64, 0.21, 0.93
        elseif ilvl >= 292 then
            tr, tg, tb = 0.0, 0.44, 0.87
        elseif ilvl >= 279 then
            tr, tg, tb = 0.12, 1.0, 0.0
        elseif ilvl >= 266 then
            tr, tg, tb = 0.6, 0.6, 0.6
        else
            tr, tg, tb = 0.5, 0.5, 0.5
        end
    end

    local hexColor = string.format("%02x%02x%02x", math.floor(tr * 255 + 0.5), math.floor(tg * 255 + 0.5), math.floor(tb * 255 + 0.5))
    return tr, tg, tb, hexColor
end













function Seasonal:GetDisplayKey(explicitKey)
    return explicitKey or self.selectedCharacterKey or (self.Data and self.Data:GetCurrentKey())
end

function Seasonal:PaintHeader(key)
    key = self:GetDisplayKey(key)
    self:PaintTray(key)
    self:PaintCacheBadge(key)
    if self.Vault and type(self.Vault.Render) == "function" then
        self.Vault:Render(key)
    end
end

function Seasonal:PaintRail()
    local Data = self.Data
    
    
    
    
    
    
    
    
    
    
    self.selectedRosterKeys = self.selectedRosterKeys or {}

    local onMain = (self.activeNav == nil or self.activeNav == "" or self.activeNav == "main")
    if not onMain then
        self.isEditMode = false
    end

    if self.editOrderButton then
        self.editOrderButton:SetShown(onMain)
        self.editOrderButton:SetText(self.isEditMode and "Done" or "Edit Order")
    end

    local roster = Data and Data:GetRoster(self.isEditMode) or {}
    if #roster == 0 and Data and type(Data.GetCurrentKey) == "function" then
        roster = { Data:GetCurrentKey() }
    end

    local loggedInKey = Data and Data:GetCurrentKey()
    if loggedInKey and not self.selectedRosterKeysInitialized then
        self.selectedRosterKeys[loggedInKey] = true
        self.selectedRosterKeysInitialized = true
    end

    
    
    
    
    
    
    
    local inRoster = {}
    for _, key in ipairs(roster) do inRoster[key] = true end
    for key in pairs(self.selectedRosterKeys) do
        if not inRoster[key] then self.selectedRosterKeys[key] = nil end
    end
    if self.selectedCharacterKey and not inRoster[self.selectedCharacterKey] then
        self.selectedCharacterKey = nil
    end

    if self.showLowLevelCB then
        self.showLowLevelCB:SetChecked(Data and type(Data.ShowLowLevel) == "function" and Data:ShowLowLevel() or false)
    end

    self.railButtons = self.railButtons or {}
    local rail = self.railFrame
    if not rail then return end
    
    
    
    local host = self.railContent or rail

    local yOffset = -8
    local ENTRY_HEIGHT = 52
    local ENTRY_GAP = 6

    for i, charKey in ipairs(roster) do
        local btn = self.railButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, host, "BackdropTemplate")
            btn:SetSize(RAIL_ROW_WIDTH, ENTRY_HEIGHT)
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            local iconSlot = CreateFrame("Frame", nil, btn, "BackdropTemplate")
            iconSlot:SetSize(36, 36)
            iconSlot:SetPoint("LEFT", btn, "LEFT", 4, 0)
            iconSlot:SetBackdrop({
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 8,
            })
            iconSlot:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

            local icon = iconSlot:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", 2, -2)
            icon:SetPoint("BOTTOMRIGHT", -2, 2)
            btn.icon = icon

            local glow = iconSlot:CreateTexture(nil, "OVERLAY")
            glow:SetPoint("TOPLEFT", -4, 4)
            glow:SetPoint("BOTTOMRIGHT", 4, -4)
            glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            glow:SetBlendMode("ADD")
            glow:SetVertexColor(0.0, 0.9, 1.0, 1.0)
            glow:Hide()
            btn.glowRing = glow

            
            local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameText:SetPoint("TOPLEFT", iconSlot, "TOPRIGHT", 8, 2)
            nameText:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -20, 2)
            nameText:SetJustifyH("LEFT")
            btn.nameText = nameText

            
            local row2Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row2Text:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
            row2Text:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -20, -14)
            row2Text:SetJustifyH("LEFT")
            btn.row2Text = row2Text

            
            local row3Text = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            row3Text:SetPoint("TOPLEFT", row2Text, "BOTTOMLEFT", 0, -2)
            row3Text:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -20, -28)
            row3Text:SetJustifyH("LEFT")
            btn.row3Text = row3Text

            local upBtn = CreateFrame("Button", nil, btn)
            upBtn:SetSize(14, 14)
            upBtn:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
            local upText = upBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            upText:SetPoint("CENTER")
            upText:SetText("▲")
            btn.upBtn = upBtn

            local downBtn = CreateFrame("Button", nil, btn)
            downBtn:SetSize(14, 14)
            downBtn:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
            local downText = downBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            downText:SetPoint("CENTER")
            downText:SetText("▼")
            btn.downBtn = downBtn

            self.railButtons[i] = btn
        end

        
        
        
        
        
        if btn:GetParent() ~= host then
            btn:SetParent(host)
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", host, "TOPLEFT", 0, yOffset)
        btn:SetWidth(RAIL_ROW_WIDTH)
        yOffset = yOffset - (ENTRY_HEIGHT + ENTRY_GAP)

        btn.key = charKey

        local char = Data and Data:GetCharacter(charKey) or {}
        local charName = char.name or charKey:match("^(.-)-") or charKey
        local charRealm = char.realm or charKey:match("^.-%-(.*)$") or ""
        local charClass = char.classFileName or char.class or ""

        local r, g, b = GetClassColor(charClass)
        if charClass ~= "" and _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[charClass:upper()] then
            btn.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes")
            btn.icon:SetTexCoord(unpack(_G.CLASS_ICON_TCOORDS[charClass:upper()]))
        else
            btn.icon:SetTexture("Interface\\Icons\\inv_misc_groupneedmore")
            btn.icon:SetTexCoord(0, 1, 0, 1)
        end

        
        local displayName = charName
        if charRealm ~= "" and charRealm ~= "?" then
            displayName = charName .. " - " .. charRealm
        end
        btn.nameText:SetText(displayName)
        btn.nameText:SetTextColor(r, g, b)

        
        local specStr = char.specName or ""
        if not specStr or specStr == "" then
            if charKey == (Data and Data:GetCurrentKey()) and type(GetSpecialization) == "function" and type(GetSpecializationInfo) == "function" then
                local specIdx = GetSpecialization()
                if specIdx and specIdx > 0 then
                    _, specStr = GetSpecializationInfo(specIdx)
                end
            end
        end
        local ilvlVal = char.equippedIlvl or char.avgItemLevel or char.ilvl or char.averageItemLevel
        if (not ilvlVal or ilvlVal == 0) and charKey == (Data and Data:GetCurrentKey()) and type(GetAverageItemLevel) == "function" then
            _, ilvlVal = GetAverageItemLevel()
        end
        local _, _, _, hexColor = GetColorForIlvl(ilvlVal)
        local ilvlStr = (type(ilvlVal) == "number" and ilvlVal > 0) and string.format("%.1f", ilvlVal) or ""
        local coloredIlvlStr = (ilvlStr ~= "") and string.format("|cff%s%s|r", hexColor, ilvlStr) or ""

        local line2 = ""
        if specStr ~= "" and coloredIlvlStr ~= "" then
            line2 = specStr .. " (" .. coloredIlvlStr .. ")"
        elseif coloredIlvlStr ~= "" then
            line2 = coloredIlvlStr .. " iLvl"
        elseif specStr ~= "" then
            line2 = specStr
        else
            line2 = "iLvl --"
        end
        btn.row2Text:SetText(line2)
        btn.row2Text:SetTextColor(0.85, 0.85, 0.85)

        
        local lvl = char.level or (charKey == (Data and Data:GetCurrentKey()) and UnitLevel and UnitLevel("player")) or 80
        local classTitle = char.class or charClass
        if classTitle == "" then classTitle = "Character" end
        btn.row3Text:SetText(string.format("Lvl %s %s", tostring(lvl), classTitle))
        btn.row3Text:SetTextColor(0.65, 0.65, 0.65)

        local isSelected = false
        if onMain then
            
            
            
            
            
            
            
            isSelected = (charKey == self:GetDisplayKey())
        else
            isSelected = (self.selectedRosterKeys[charKey] == true)
        end

        if isSelected then
            btn.glowRing:Show()
        else
            btn.glowRing:Hide()
        end

        
        if self.isEditMode then
            btn.upBtn:SetShown(i > 1)
            btn.downBtn:SetShown(i < #roster)
            btn.upBtn:SetScript("OnClick", function()
                if Data and type(Data.ReorderMasterRoster) == "function" then
                    Data:ReorderMasterRoster(charKey, -1)
                end
                self:PaintRail()
                self:RefreshCurrentNav()
            end)
            btn.downBtn:SetScript("OnClick", function()
                if Data and type(Data.ReorderMasterRoster) == "function" then
                    Data:ReorderMasterRoster(charKey, 1)
                end
                self:PaintRail()
                self:RefreshCurrentNav()
            end)
        else
            btn.upBtn:Hide()
            btn.downBtn:Hide()
        end

        
        btn:SetScript("OnEnter", function(selfFrame)
            if type(GameTooltip) ~= "table" then return end
            GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")

            local k = selfFrame.key
            local cData = Data and Data:GetCharacter(k) or {}
            local nStr = cData.name or k:match("^(.-)-") or k
            local rStr = cData.realm or k:match("^.-%-(.*)$") or ""
            local titleStr = (rStr ~= "" and rStr ~= "?") and (nStr .. " - " .. rStr) or nStr
            local cClass = cData.classFileName or cData.class

            local cr, cg, cb = GetClassColor(cClass)
            GameTooltip:AddLine(titleStr, cr, cg, cb)

            local lvlVal = cData.level or (k == (Data and Data:GetCurrentKey()) and UnitLevel and UnitLevel("player")) or 80
            GameTooltip:AddLine(string.format("Level: |cffffffff%s|r", tostring(lvlVal)), 0.9, 0.9, 0.9)

            local ilvlVal = cData.equippedIlvl or cData.avgItemLevel or cData.ilvl or cData.averageItemLevel
            if (not ilvlVal or ilvlVal == 0) and k == (Data and Data:GetCurrentKey()) and type(GetAverageItemLevel) == "function" then
                _, ilvlVal = GetAverageItemLevel()
            end
            local _, _, _, tHex = GetColorForIlvl(ilvlVal)
            local ilvlText = (type(ilvlVal) == "number" and ilvlVal > 0) and string.format("|cff%s%.1f|r", tHex, ilvlVal) or "Unknown"
            GameTooltip:AddLine(string.format("Item Level: %s", ilvlText), 0.9, 0.9, 0.9)

            local sName = cData.specName
            if not sName and k == (Data and Data:GetCurrentKey()) and type(GetSpecialization) == "function" and type(GetSpecializationInfo) == "function" then
                local sIdx = GetSpecialization()
                if sIdx and sIdx > 0 then
                    _, sName = GetSpecializationInfo(sIdx)
                end
            end
            sName = (type(sName) == "string" and sName ~= "") and sName or "Unknown"
            GameTooltip:AddLine(string.format("Last Spec: |cffffffff%s|r", sName), 0.9, 0.9, 0.9)

            if Data and k == Data:GetCurrentKey() then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00ffcc(Logged-in Character)|r")
            end

            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function()
            if type(GameTooltip) == "table" and type(GameTooltip.Hide) == "function" then
                GameTooltip:Hide()
            end
        end)

        btn:SetScript("OnClick", function(_, mouseButton)
            local targetKey = btn.key
            local currentNav = self.activeNav
            local isMainNav = (currentNav == nil or currentNav == "" or currentNav == "main")

            if mouseButton == "LeftButton" then
                if isMainNav then
                    if self.selectedCharacterKey == targetKey then
                        
                        
                        
                        
                        
                        
                        
                        
                        self.selectedCharacterKey = nil
                        self.selectedRosterKeys = {}
                    else
                        self.selectedCharacterKey = targetKey
                        self.selectedRosterKeys = { [targetKey] = true }
                    end
                    self:PaintHeader(self.selectedCharacterKey)
                    self:RelayoutBody()
                    self:RefreshCurrentNav()
                else
                    if self.selectedRosterKeys[targetKey] then
                        self.selectedRosterKeys[targetKey] = nil
                    else
                        self.selectedRosterKeys[targetKey] = true
                    end
                    self:RefreshCurrentNav()
                end
                self:PaintRail()
            elseif mouseButton == "RightButton" then
                if not isMainNav then
                    self.selectedRosterKeys[targetKey] = nil
                    self:RefreshCurrentNav()
                    self:PaintRail()
                end
            end
        end)

        btn:Show()
    end

    for i = #roster + 1, #self.railButtons do
        if self.railButtons[i] then
            self.railButtons[i]:Hide()
        end
    end

    
    
    
    
    if self.railContent then
        local contentHeight = 8 + #roster * (ENTRY_HEIGHT + ENTRY_GAP)
        self.railContent:SetSize(RAIL_ROW_WIDTH, math.max(contentHeight, 1))
    end
end

function Seasonal:BuildRail(rail)
    self.railFrame = rail
    W = W or ThugUI.Widgets

    local editBtn = CreateFrame("Button", nil, rail, "UIPanelButtonTemplate")
    editBtn:SetSize(84, 20)
    editBtn:SetPoint("BOTTOMLEFT", rail, "BOTTOMLEFT", 6, 6)
    editBtn:SetText("Edit Order")
    editBtn:SetScript("OnClick", function()
        Seasonal.isEditMode = not Seasonal.isEditMode
        Seasonal:PaintRail()
        Seasonal:RefreshCurrentNav()
    end)
    if W and type(W.AttachTooltip) == "function" then
        W.AttachTooltip(editBtn, "Edit Roster Order", "Toggle edit mode to reorder your account-wide master character list.")
    end
    self.editOrderButton = editBtn

    
    
    
    local lowLevelCB = CreateFrame("CheckButton", nil, rail, "UICheckButtonTemplate")
    lowLevelCB:SetSize(18, 18)
    lowLevelCB:SetPoint("BOTTOMLEFT", editBtn, "TOPLEFT", 0, 6)

    local lowLevelLabel = lowLevelCB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lowLevelLabel:SetPoint("LEFT", lowLevelCB, "RIGHT", 2, 0)
    lowLevelLabel:SetText("Show low-level alts")
    lowLevelCB.labelText = lowLevelLabel

    local Data = self.Data
    lowLevelCB:SetChecked(Data and type(Data.ShowLowLevel) == "function" and Data:ShowLowLevel() or false)
    lowLevelCB:SetScript("OnClick", function(cbSelf)
        local D = Seasonal.Data
        if D and type(D.SetShowLowLevel) == "function" then
            D:SetShowLowLevel(cbSelf:GetChecked())
        end
        Seasonal:PaintRail()
        Seasonal:PaintHeader(Seasonal.selectedCharacterKey)
        Seasonal:RefreshCurrentNav()
    end)
    if W and type(W.AttachTooltip) == "function" then
        local maxLevel = (Data and type(Data.GetMaxLevel) == "function") and Data:GetMaxLevel() or nil
        W.AttachTooltip(lowLevelCB, "Show Low-Level Alts",
            maxLevel
                and string.format("Off by default: characters below level %d are hidden, since they have no vault, keystone or lockouts to report. The character you are logged in on is always shown.", maxLevel)
                or "Off by default: characters below max level are hidden, since they have no vault, keystone or lockouts to report. The character you are logged in on is always shown.")
    end
    self.showLowLevelCB = lowLevelCB

    
    
    
    local scrollHost = CreateFrame("Frame", nil, rail)
    scrollHost:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, 0)
    scrollHost:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", 0, RAIL_FOOTER_HEIGHT)
    self.railScrollHost = scrollHost

    if W and type(W.CreateScrollArea) == "function" then
        local scroll, content = W.CreateScrollArea(scrollHost, 24)
        content:SetSize(RAIL_ROW_WIDTH, 1)
        self.railScroll = scroll
        self.railContent = content
    end

    self:PaintRail()
end







local function CreatePlaceholderSlot(parent, size)
    local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    slot:SetSize(size, size)
    slot:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
    })
    slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.6)

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
    icon:SetDesaturated(true)
    slot.icon = icon

    local count = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOM", slot, "BOTTOM", 3, 1)
    count:SetJustifyH("CENTER")
    slot.count = count

    return slot
end





























local TRAY_SLOT_DEFAULTS = {
    [1] = { defaultID = 3028 },
    [2] = { defaultID = 3310 },
    [3] = { defaultID = 3316 },
    [4] = { defaultID = 3465 },
    [5] = { defaultID = 3418 },
    [6] = { crests = { 3446, 3445, 3444, 3443, 3442 }, defaultID = 3442 },
}










local CREST_TO_TRACK = {
    [3446] = "Myth",
    [3445] = "Hero",
    [3444] = "Champion",
    [3443] = "Veteran",
    [3442] = "Adventurer",
}



local TROVE_TRACK = "Hero"




local COFFER_TRACK = "Champion"

local TRACK_CREST_ORDER = {
    { track = "Adventurer", id = 3442 },
    { track = "Veteran",    id = 3443 },
    { track = "Champion",   id = 3444 },
    { track = "Hero",       id = 3445 },
    { track = "Myth",       id = 3446 },
}

local function GlobalString(name, default)
    local v = name and _G[name]
    if type(v) == "string" and v ~= "" then return v end
    return default
end

function Seasonal:GetTrayCurrencies(currencies, gear)
    currencies = currencies or {}
    local result = {}

    
    
    
    
    
    local upgradableTracks = {}
    if type(gear) == "table" then
        for _, item in pairs(gear) do
            if type(item) == "table" and item.track and type(item.rank) == "number" and type(item.maxRank) == "number" then
                if item.rank < item.maxRank then
                    upgradableTracks[item.track] = true
                end
            end
        end
    end

    
    
    
    
    if upgradableTracks[COFFER_TRACK] then
        table.insert(result, 3028) 
        table.insert(result, 3310) 
    end

    table.insert(result, 3316) 
    table.insert(result, 3509) 

    
    
    
    
    
    table.insert(result, 3465) 
    table.insert(result, 3418) 

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    if currencies["trove"] and upgradableTracks[TROVE_TRACK] then
        table.insert(result, "trove")
    end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    local crestAdded = false
    for _, entry in ipairs(TRACK_CREST_ORDER) do
        if upgradableTracks[entry.track] then
            table.insert(result, entry.id)
            crestAdded = true
        end
    end

    
    
    if not crestAdded then
        table.insert(result, 3444)
    end

    return result
end

function Seasonal:ResolveTraySlotCurrencyID(slotIndex, currencies, gear)
    local list = self:GetTrayCurrencies(currencies, gear)
    return list[slotIndex] or (TRAY_SLOT_DEFAULTS[slotIndex] and TRAY_SLOT_DEFAULTS[slotIndex].defaultID)
end











local STRINGS = {
    CATALYST_DESCRIPTION = "Used at the Revival Catalyst to transform eligible gear into Tier set pieces.",
    VOIDCORE_DESCRIPTION = "Transmuted at the Voidforge into gear after a raid boss, Mythic+ dungeon, Bountiful Delve or Nightmare Prey Hunt.",
    TROVE_NAME = "Trovehunter's Bounty",
    TROVE_DESCRIPTION = "Delve bounty map that guarantees additional Bountiful Delve rewards.",
    TROVE_STATUS_ABSENT = "Status: Absent",
    TROVE_STATUS_HELD = "Status: Held",
    
    
    
    
    
    
    
    CACHE_TITLE = "Weekly Pinnacle Caches",
    CACHE_DESCRIPTION = "Gear from these caches is limited to %d per week.",
    CACHE_OPENED = "Opened this week: %d of %d",
    CACHE_UNKNOWN = "Opened this week: not yet detectable.",
    CACHE_UNKNOWN_WHY = "The hidden weekly quest flag for this season has not been identified, and this badge will not guess one. Run /thugseason sweep, open a cache, then run it again -- the difference names the flag.",
    CACHE_ALT_UNKNOWN = "This character has no snapshot of its cache count. Log in on them once after the weekly flag has been identified.",
}

function Seasonal:PaintTraySlot(slot, currencyID, currencies, isCurrent)
    if not slot or not currencyID then return end
    local snap = currencies and currencies[currencyID]

    local name, iconFileID, quantity, totalEarned, maxQuantity, description

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    if type(currencyID) == "number" then
        local getInfo = C_CurrencyInfo and (C_CurrencyInfo.GetCurrencyInfo or C_CurrencyInfo.GetCurrencyInfoByID or C_CurrencyInfo.GetBasicCurrencyInfo)
        if type(getInfo) == "function" then
            local ok, liveInfo = pcall(getInfo, currencyID)
            if ok and type(liveInfo) == "table" then
                
                name = liveInfo.name
                iconFileID = liveInfo.iconFileID or liveInfo.icon
                description = liveInfo.description
                maxQuantity = liveInfo.maxQuantity

                
                if isCurrent then
                    quantity = liveInfo.quantity
                    totalEarned = liveInfo.totalEarned
                end
            end
        end
    end

    if snap then
        name = name or snap.name
        iconFileID = iconFileID or snap.iconFileID
        quantity = quantity or snap.quantity
        totalEarned = totalEarned or snap.totalEarned
        maxQuantity = maxQuantity or snap.maxQuantity
        description = description or snap.description
    end

    quantity = quantity or 0
    totalEarned = totalEarned or 0
    maxQuantity = maxQuantity or 0

    
    
    
    
    
    
    local isTrove = (currencyID == "trove")
    
    
    
    
    
    
    local isTroveAbsent = isTrove and (quantity == 0)

    if isTrove then
        name = STRINGS.TROVE_NAME
        iconFileID = iconFileID or "Interface\\Icons\\inv_delve_bounty_map"
        description = STRINGS.TROVE_DESCRIPTION
    end

    
    
    
    
    local tex = iconFileID or "Interface\\Buttons\\UI-EmptySlot"
    slot.icon:SetTexture(tex)

    if isTroveAbsent then
        slot.icon:SetDesaturated(true)
        slot.icon:SetVertexColor(0.5, 0.5, 0.5)
        slot:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
    else
        slot.icon:SetDesaturated(false)
        slot.icon:SetVertexColor(1, 1, 1)
        slot:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    end

    
    
    
    
    
    local countText = ""
    if isTroveAbsent then
        countText = "|cff8888880|r"
    else
        countText = tostring(quantity)
    end
    if slot.count then
        slot.count:SetText(countText)
    end

    slot:EnableMouse(true)
    slot:SetScript("OnEnter", function(selfFrame)
        if type(GameTooltip) ~= "table" then return end
        GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
        GameTooltip.suppressAutomaticCompareItem = true
        GameTooltip.hideShoppingTooltips = true
        
        
        
        
        
        if type(TooltipComparisonManager) == "table" and type(TooltipComparisonManager.Clear) == "function" then
            pcall(TooltipComparisonManager.Clear, TooltipComparisonManager, GameTooltip)
        end
        if type(ShoppingTooltip1) == "table" and type(ShoppingTooltip1.Hide) == "function" then
            ShoppingTooltip1:Hide()
        end
        if type(ShoppingTooltip2) == "table" and type(ShoppingTooltip2.Hide) == "function" then
            ShoppingTooltip2:Hide()
        end

        if isCurrent and currencyID and not isTrove and type(GameTooltip.SetCurrencyByID) == "function" then
            local ok = pcall(GameTooltip.SetCurrencyByID, GameTooltip, currencyID)
            if ok then
                GameTooltip:Show()
                return
            end
        end

        local titleText = name or ("Currency " .. (currencyID or ""))
        if type(GameTooltip_SetTitle) == "function" then
            GameTooltip_SetTitle(GameTooltip, titleText)
        else
            GameTooltip:AddLine(titleText, 1, 1, 1)
        end

        if isTrove then
            if isTroveAbsent then
                if type(GameTooltip_AddColoredLine) == "function" then
                    W.AddColoredTooltipLine(STRINGS.TROVE_STATUS_ABSENT, 0.6, 0.6, 0.6)
                else
                    GameTooltip:AddLine(STRINGS.TROVE_STATUS_ABSENT, 0.6, 0.6, 0.6)
                end
            else
                if type(GameTooltip_AddColoredLine) == "function" then
                    W.AddColoredTooltipLine(STRINGS.TROVE_STATUS_HELD, 0.0, 1.0, 0.8)
                else
                    GameTooltip:AddLine(STRINGS.TROVE_STATUS_HELD, 0.0, 1.0, 0.8)
                end
            end
        else
            local qtyFormat = GlobalString("CURRENCY_QUANTITY", "Quantity: %d")
            local qtyLine = string.format(qtyFormat, quantity)
            if type(GameTooltip_AddNormalLine) == "function" then
                GameTooltip_AddNormalLine(GameTooltip, qtyLine)
            else
                GameTooltip:AddLine(qtyLine, 1, 1, 1)
            end
        end

        if maxQuantity > 0 or totalEarned > 0 then
            local earnedVal = totalEarned > 0 and totalEarned or quantity
            local totalText
            if maxQuantity > 0 then
                local fmt = GlobalString("CURRENCY_TOTAL_EARNED_MAX", GlobalString("CURRENCY_TOTAL_MAX", "Total Earned: %d / %d"))
                totalText = string.format(fmt, earnedVal, maxQuantity)
            else
                local fmt = GlobalString("CURRENCY_TOTAL_EARNED", "Total Earned: %d")
                totalText = string.format(fmt, earnedVal)
            end
            if type(GameTooltip_AddNormalLine) == "function" then
                GameTooltip_AddNormalLine(GameTooltip, totalText)
            else
                GameTooltip:AddLine(totalText, 1, 1, 1)
            end
        end

        local descText = description
        
        
        
        if (not descText or descText == "") and currencyID == 3465 then
            descText = STRINGS.CATALYST_DESCRIPTION
        elseif (not descText or descText == "") and currencyID == 3418 then
            descText = STRINGS.VOIDCORE_DESCRIPTION
        elseif (not descText or descText == "") and isTrove then
            descText = STRINGS.TROVE_DESCRIPTION
        end

        if type(descText) == "string" and descText ~= "" then
            if type(GameTooltip_AddBlankLineToTooltip) == "function" then
                GameTooltip_AddBlankLineToTooltip(GameTooltip)
            end
            if type(GameTooltip_AddNormalLine) == "function" then
                GameTooltip_AddNormalLine(GameTooltip, descText)
            else
                GameTooltip:AddLine(descText, 0.8, 0.8, 0.8, true)
            end
        end

        GameTooltip:Show()
    end)

    slot:SetScript("OnLeave", function()
        if type(GameTooltip) == "table" then
            GameTooltip.suppressAutomaticCompareItem = nil
            GameTooltip.hideShoppingTooltips = nil
            if type(GameTooltip.Hide) == "function" then
                GameTooltip:Hide()
            end
        end
        if type(TooltipComparisonManager) == "table" and type(TooltipComparisonManager.Clear) == "function" then
            pcall(TooltipComparisonManager.Clear, TooltipComparisonManager, GameTooltip)
        end
        if type(ShoppingTooltip1) == "table" and type(ShoppingTooltip1.Hide) == "function" then
            ShoppingTooltip1:Hide()
        end
        if type(ShoppingTooltip2) == "table" and type(ShoppingTooltip2.Hide) == "function" then
            ShoppingTooltip2:Hide()
        end
    end)
end

function Seasonal:PaintTray(key)
    local Data = ThugUI.Seasonal and ThugUI.Seasonal.Data
    key = self:GetDisplayKey(key)
    local isCurrent = Data ~= nil and key ~= nil and key == Data:GetCurrentKey()

    local row = Data and key and Data:GetCharacter(key)
    local currencies = row and row.currencies or {}
    local gear = row and row.gear or {}

    local targetCurrencies = self:GetTrayCurrencies(currencies, gear)

    self.trayIcons = self.trayIcons or {}
    local header = self.header

    for i = 1, #targetCurrencies do
        if not self.trayIcons[i] and header then
            local icon = CreatePlaceholderSlot(header, TRAY_ICON_SIZE)
            table.insert(self.trayIcons, icon)
        end
    end

    for i, icon in ipairs(self.trayIcons) do
        if i <= #targetCurrencies then
            local currencyID = targetCurrencies[i]
            local colIdx = (i - 1) % TRAY_ICONS_PER_ROW
            local rowIdx = math.floor((i - 1) / TRAY_ICONS_PER_ROW)
            icon:SetPoint("TOPLEFT", header, "TOPLEFT",
                TRAY_CURRENCY_LEFT + colIdx * (TRAY_ICON_SIZE + TRAY_ICON_GAP),
                -8 - rowIdx * (TRAY_ICON_SIZE + TRAY_ICON_GAP))
            icon:Show()
            self:PaintTraySlot(icon, currencyID, currencies, isCurrent)
        else
            icon:Hide()
        end
    end
end



















function Seasonal:GetWeeklyCacheState(key)
    local Data = self.Data or (ThugUI.Seasonal and ThugUI.Seasonal.Data)
    key = self:GetDisplayKey(key)

    local cap = (Data and Data.WEEKLY_CACHE_CAP) or 2
    local isCurrent = Data ~= nil and key ~= nil and key == Data:GetCurrentKey()

    
    
    
    
    
    if not isCurrent then
        local row = Data and key and Data:GetCharacter(key)
        local snap = row and row.weeklyCaches
        if type(snap) ~= "table" or type(snap.opened) ~= "number" then
            return nil, cap, "nosnapshot"
        end
        return snap.opened, snap.cap or cap, nil
    end

    local opened = Data and Data:CountWeeklyCaches()
    if type(opened) ~= "number" then
        return nil, cap, "unidentified"
    end
    return opened, cap, nil
end

function Seasonal:PaintCacheBadge(key)
    local badge = self.cacheBadge
    if not badge then return end

    local opened, cap, reason = self:GetWeeklyCacheState(key)

    
    
    
    
    badge.icon:SetTexture("Interface\\Icons\\inv_misc_treasurechest01")

    local exhausted = (type(opened) == "number" and opened >= cap)

    if opened == nil or exhausted then
        
        
        
        
        badge.icon:SetDesaturated(true)
        badge.icon:SetVertexColor(0.6, 0.6, 0.6)
        badge:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
    else
        badge.icon:SetDesaturated(false)
        badge.icon:SetVertexColor(1, 1, 1)
        badge:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.9)
    end

    if badge.count then
        if opened == nil then
            badge.count:SetText(string.format("|cff888888?/%d|r", cap))
        elseif exhausted then
            badge.count:SetText(string.format("|cff888888%d/%d|r", opened, cap))
        else
            badge.count:SetText(string.format("%d/%d", opened, cap))
        end
    end

    badge:EnableMouse(true)
    badge:SetScript("OnEnter", function(selfFrame)
        if type(GameTooltip) ~= "table" then return end
        GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")

        if type(GameTooltip_SetTitle) == "function" then
            GameTooltip_SetTitle(GameTooltip, STRINGS.CACHE_TITLE)
        else
            GameTooltip:AddLine(STRINGS.CACHE_TITLE, 1, 1, 1)
        end

        local AddNormal = function(text, r, g, b)
            if type(GameTooltip_AddNormalLine) == "function" then
                GameTooltip_AddNormalLine(GameTooltip, text)
            else
                GameTooltip:AddLine(text, r or 1, g or 1, b or 1, true)
            end
        end

        AddNormal(string.format(STRINGS.CACHE_DESCRIPTION, cap))

        if type(GameTooltip_AddBlankLineToTooltip) == "function" then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
        else
            GameTooltip:AddLine(" ")
        end

        if opened == nil then
            AddNormal(STRINGS.CACHE_UNKNOWN, 0.6, 0.6, 0.6)
            AddNormal(reason == "nosnapshot" and STRINGS.CACHE_ALT_UNKNOWN
                or STRINGS.CACHE_UNKNOWN_WHY, 0.8, 0.8, 0.8)
        else
            AddNormal(string.format(STRINGS.CACHE_OPENED, opened, cap))
        end

        GameTooltip:Show()
    end)

    badge:SetScript("OnLeave", function()
        if type(GameTooltip) == "table" and type(GameTooltip.Hide) == "function" then
            GameTooltip:Hide()
        end
    end)
end

function Seasonal:PaintVoidcoreReminder(earnedCount)
    local reminder = self.voidcoreReminder
    if not reminder then return end

    earnedCount = math.max(0, tonumber(earnedCount) or 0)
    local displayCount = math.min(earnedCount, 3)

    local iconTex = "Interface\\Icons\\inv_1205_voidforge_fluctuatingvoidcores_green"
    reminder.icon:SetTexture(iconTex)

    if earnedCount == 0 then
        reminder.icon:SetDesaturated(true)
        reminder.icon:SetVertexColor(0.7, 0.7, 0.7)
        reminder:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
    else
        reminder.icon:SetDesaturated(false)
        reminder.icon:SetVertexColor(1, 1, 1)
        reminder:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.9)
    end

    if reminder.count then
        reminder.count:SetText(string.format("%d/3", displayCount))
    end

    reminder:EnableMouse(true)
    reminder:SetScript("OnEnter", function(selfFrame)
        if type(GameTooltip) ~= "table" then return end

        if not _G.WeeklyRewardsFrame then
            if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
                pcall(C_AddOns.LoadAddOn, "Blizzard_WeeklyRewards")
            elseif type(LoadAddOn) == "function" then
                pcall(LoadAddOn, "Blizzard_WeeklyRewards")
            end
        end

        GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
        GameTooltip.suppressAutomaticCompareItem = true
        GameTooltip.hideShoppingTooltips = true

        local concessions = _G.WeeklyRewardsFrame and _G.WeeklyRewardsFrame.ConcessionsFrame
        local cFrame = concessions and concessions.Rewards and (concessions.Rewards.ConcessionFrame2 or concessions.Rewards.ConcessionFrame1)
        if not cFrame and concessions and type(concessions.GetChildren) == "function" then
            local children = { concessions:GetChildren() }
            for _, child in ipairs(children) do
                if child and (child.RewardsFrame or child.Text) then
                    cFrame = child
                    break
                end
            end
        end

        local onEnter = cFrame and type(cFrame.GetScript) == "function" and cFrame:GetScript("OnEnter")
        if type(onEnter) == "function" then
            local ok = pcall(onEnter, cFrame)
            if ok then
                if type(GameTooltip_AddBlankLineToTooltip) == "function" then
                    GameTooltip_AddBlankLineToTooltip(GameTooltip)
                else
                    GameTooltip:AddLine(" ")
                end
                local statusLine = string.format("Great Vault Slots Filled: %d/3", displayCount)
                if type(GameTooltip_AddNormalLine) == "function" then
                    GameTooltip_AddNormalLine(GameTooltip, statusLine)
                else
                    GameTooltip:AddLine(statusLine, 0.0, 0.8, 1.0)
                end
                GameTooltip:Show()
                return
            end
        end

        local titleStr = "Great Vault Concession"
        if cFrame and cFrame.info and type(cFrame.info.name) == "string" and cFrame.info.name ~= "" then
            titleStr = cFrame.info.name
        elseif type(_G["WEEKLY_REWARDS_CONCESSION_TITLE"]) == "string" and _G["WEEKLY_REWARDS_CONCESSION_TITLE"] ~= "" then
            titleStr = _G["WEEKLY_REWARDS_CONCESSION_TITLE"]
        end

        if type(GameTooltip.SetText) == "function" then
            GameTooltip:SetText(titleStr, 1, 1, 1)
        elseif type(GameTooltip_SetTitle) == "function" then
            GameTooltip_SetTitle(GameTooltip, titleStr)
        else
            GameTooltip:AddLine(titleStr, 1, 1, 1)
        end

        local bodyText
        if cFrame and cFrame.RewardsFrame and cFrame.RewardsFrame.Text and type(cFrame.RewardsFrame.Text.GetText) == "function" then
            bodyText = cFrame.RewardsFrame.Text:GetText()
        end
        if (not bodyText or bodyText == "") and cFrame and cFrame.Text and type(cFrame.Text.GetText) == "function" then
            bodyText = cFrame.Text:GetText()
        end
        if (not bodyText or bodyText == "") and cFrame and cFrame.info and type(cFrame.info.description) == "string" then
            bodyText = cFrame.info.description
        end
        if not bodyText or bodyText == "" then
            bodyText = _G["WEEKLY_REWARDS_CONCESSION_DESCRIPTION"] or _G["WEEKLY_REWARDS_UNLOCKED_CONCESSION"] or "If you do not select a piece of gear from the Great Vault, you may choose Nebulous Voidcores or Concession Tokens instead."
        end

        if type(GameTooltip_AddNormalLine) == "function" then
            GameTooltip_AddNormalLine(GameTooltip, bodyText)
        else
            GameTooltip:AddLine(bodyText, 0.8, 0.8, 0.8, true)
        end

        if type(GameTooltip_AddBlankLineToTooltip) == "function" then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
        else
            GameTooltip:AddLine(" ")
        end
        local statusLine = string.format("Great Vault Slots Filled: %d/3", displayCount)
        if type(GameTooltip_AddNormalLine) == "function" then
            GameTooltip_AddNormalLine(GameTooltip, statusLine)
        else
            GameTooltip:AddLine(statusLine, 0.0, 0.8, 1.0)
        end
        GameTooltip:Show()
    end)
    reminder:SetScript("OnLeave", function()
        if type(GameTooltip) == "table" and type(GameTooltip.Hide) == "function" then
            GameTooltip:Hide()
        end
    end)
end

function Seasonal:BuildHeader(header)
    self.vaultBoxes = {}
    for row = 1, 3 do
        for col = 1, 3 do
            local box = CreatePlaceholderSlot(header, VAULT_BOX_SIZE)
            box:SetPoint("TOPLEFT", header, "TOPLEFT",
                8 + (col - 1) * (VAULT_BOX_SIZE + VAULT_BOX_GAP),
                -8 - (row - 1) * (VAULT_BOX_SIZE + VAULT_BOX_GAP))
            table.insert(self.vaultBoxes, box)
        end
    end

    
    local reminder = CreatePlaceholderSlot(header, VAULT_BOX_SIZE)
    reminder:SetPoint("TOPLEFT", header, "TOPLEFT",
        8 + 3 * (VAULT_BOX_SIZE + VAULT_BOX_GAP) + 8,
        -8 - 1 * (VAULT_BOX_SIZE + VAULT_BOX_GAP))
    self.voidcoreReminder = reminder

    
    
    
    local cacheBadge = CreatePlaceholderSlot(header, TRAY_ICON_SIZE)
    cacheBadge:SetPoint("TOPLEFT", header, "TOPLEFT", TRAY_LEFT, -8)
    self.cacheBadge = cacheBadge

    self.trayIcons = {}
    for i = 1, TRAY_ICONS_PER_ROW do
        local icon = CreatePlaceholderSlot(header, TRAY_ICON_SIZE)
        icon:SetPoint("TOPLEFT", header, "TOPLEFT",
            TRAY_CURRENCY_LEFT + (i - 1) * (TRAY_ICON_SIZE + TRAY_ICON_GAP), -8)
        table.insert(self.trayIcons, icon)
    end

    local rule = header:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    rule:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)

    self:PaintTray()
    self:PaintCacheBadge()
    self:PaintVoidcoreReminder(0)
end













function Seasonal:RelayoutBody()
    if not self.bodyContent or not self.sectionFrames then return end

    local isMain = (self.activeNav == "main" or self.activeNav == "" or self.activeNav == nil)

    if isMain then
        if self.expandAllButton then self.expandAllButton:Show() end
        if self.collapseAllButton then self.collapseAllButton:Show() end

        local y = -4
        for _, def in ipairs(SECTIONS) do
            local entry = self.sectionFrames[def.id]
            if entry then
                entry.header:ClearAllPoints()
                entry.header:SetPoint("TOPLEFT", self.bodyContent, "TOPLEFT", 4, y)
                entry.header:SetPoint("TOPRIGHT", self.bodyContent, "TOPRIGHT", -4, y)
                entry.header:Show()
                y = y - ROW_HEIGHT

                entry.body:ClearAllPoints()
                if entry.collapsed then
                    entry.body:Hide()
                else
                    entry.body:SetPoint("TOPLEFT", self.bodyContent, "TOPLEFT", 4 + BODY_INDENT, y)
                    entry.body:SetPoint("TOPRIGHT", self.bodyContent, "TOPRIGHT", -4, y)
                    entry.body:Show()
                    y = y - entry.body:GetHeight()
                end
                y = y - SECTION_GAP
            end
        end

        
        
        
        for _, def in ipairs(NAV_ONLY_SECTIONS) do
            local entry = self.sectionFrames[def.id]
            if entry then
                entry.header:Hide()
                entry.body:Hide()
            end
        end

        self.bodyContent:SetHeight(math.abs(y) + 10)
    else
        if self.expandAllButton then self.expandAllButton:Hide() end
        if self.collapseAllButton then self.collapseAllButton:Hide() end

        for _, def in ipairs(ALL_SECTIONS) do
            local entry = self.sectionFrames[def.id]
            if entry then
                if def.id == self.activeNav then
                    entry.header:Hide()
                    entry.body:ClearAllPoints()
                    entry.body:SetPoint("TOPLEFT", self.bodyContent, "TOPLEFT", 4, -4)
                    entry.body:SetPoint("TOPRIGHT", self.bodyContent, "TOPRIGHT", -4, -4)
                    entry.body:Show()
                else
                    entry.header:Hide()
                    entry.body:Hide()
                end
            end
        end
        local activeEntry = self.sectionFrames[self.activeNav]
        local h = activeEntry and activeEntry.body and activeEntry.body:GetHeight() or 300
        self.bodyContent:SetHeight(h + 20)
    end
end



function Seasonal:SetSectionCollapsed(id, collapsed, skipLayout)
    local entry = self.sectionFrames[id]
    if not entry then return end

    collapsed = collapsed and true or false
    entry.collapsed = collapsed
    entry.arrow:SetText(collapsed and "+" or "-")
    EnsureDB().collapsed[id] = collapsed

    if not skipLayout then self:RelayoutBody() end
end

function Seasonal:ExpandAll()
    for _, def in ipairs(SECTIONS) do
        self:SetSectionCollapsed(def.id, false, true)
    end
    self:RelayoutBody()
end

function Seasonal:CollapseAll()
    for _, def in ipairs(SECTIONS) do
        self:SetSectionCollapsed(def.id, true, true)
    end
    self:RelayoutBody()
end

function Seasonal:BuildBody(host)
    local buttonRow = CreateFrame("Frame", nil, host)
    buttonRow:SetPoint("TOPLEFT")
    buttonRow:SetPoint("TOPRIGHT")
    buttonRow:SetHeight(26)
    self.buttonRow = buttonRow

    local expandAll = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    expandAll:SetSize(90, 20)
    expandAll:SetPoint("LEFT", buttonRow, "LEFT", 0, 0)
    expandAll:SetText("Expand All")
    expandAll:SetScript("OnClick", function() Seasonal:ExpandAll() end)
    self.expandAllButton = expandAll

    local collapseAll = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    collapseAll:SetSize(90, 20)
    collapseAll:SetPoint("LEFT", expandAll, "RIGHT", 6, 0)
    collapseAll:SetText("Collapse All")
    collapseAll:SetScript("OnClick", function() Seasonal:CollapseAll() end)
    self.collapseAllButton = collapseAll

    
    
    local scrollHost = CreateFrame("Frame", nil, host)
    scrollHost:SetPoint("TOPLEFT", buttonRow, "BOTTOMLEFT", 0, -4)
    scrollHost:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT")
    self.scrollHost = scrollHost

    local scroll, content = W.CreateScrollArea(scrollHost)
    content:SetWidth(scrollHost:GetWidth() - 34)
    self.bodyScroll = scroll
    self.bodyContent = content

    self.sectionFrames = {}
    for _, def in ipairs(ALL_SECTIONS) do
        local header = CreateFrame("Button", nil, content)
        header:SetHeight(ROW_HEIGHT)
        
        
        
        header.labelText = def.label

        local arrow = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        arrow:SetPoint("LEFT", header, "LEFT", 2, 0)

        local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
        label:SetText(def.label)

        local body = CreateFrame("Frame", nil, content)
        body:SetHeight(BODY_HEIGHT)
        local text = body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        text:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
        text:SetText(def.label .. " -- content arrives in a later task")
        
        
        
        body.text = text

        local entry = {
            id = def.id,
            header = header,
            arrow = arrow,
            body = body,
            collapsed = (EnsureDB().collapsed[def.id] == true),
        }
        self.sectionFrames[def.id] = entry
        arrow:SetText(entry.collapsed and "+" or "-")

        header:SetScript("OnClick", function()
            Seasonal:SetSectionCollapsed(def.id, not entry.collapsed)
        end)
        W.AttachTooltip(header, def.label, "Click to expand or collapse.")
    end

    self:RelayoutBody()
end





function Seasonal:CreateWindow()
    if self.window then return self.window end
    W = W or ThugUI.Widgets

    local f = CreateFrame("Frame", "ThugUI_SeasonalWindow", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    
    
    f:Hide()
    RestorePosition(f)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetBackdropColor(0.04, 0.04, 0.06, 0.96)

    
    
    tinsert(UISpecialFrames, "ThugUI_SeasonalWindow")

    
    
    
    
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:SetHeight(TITLEBAR_HEIGHT)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SavePosition(f)
    end)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    title:SetText("|cff00ffccSeasonal|r")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() f:Hide() end)

    local autoOpenCB = CreateFrame("CheckButton", nil, titleBar, "UICheckButtonTemplate")
    autoOpenCB:SetSize(18, 18)
    autoOpenCB:SetPoint("RIGHT", close, "LEFT", -170, 0)
    self.autoOpenCB = autoOpenCB

    local autoOpenLabel = autoOpenCB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoOpenLabel:SetPoint("LEFT", autoOpenCB, "RIGHT", 2, 0)
    autoOpenLabel:SetText("Auto-open with Character Sheet")
    self.autoOpenLabel = autoOpenLabel

    autoOpenCB:SetChecked(EnsureDB().autoOpenWithCharacterFrame ~= false)
    autoOpenCB:SetScript("OnClick", function(cbSelf)
        EnsureDB().autoOpenWithCharacterFrame = cbSelf:GetChecked() and true or false
    end)
    W = W or ThugUI.Widgets
    if W and type(W.AttachTooltip) == "function" then
        W.AttachTooltip(autoOpenCB, "Auto-Open with Character Sheet", "Automatically open and close the Seasonal window when you open or close your Character Sheet (C).")
    end

    
    local navRow = CreateFrame("Frame", nil, f)
    navRow:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    navRow:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
    navRow:SetHeight(NAV_HEIGHT)
    self:BuildNav(navRow)

    
    local rail = CreateFrame("Frame", nil, f)
    rail:SetPoint("TOPLEFT", navRow, "BOTTOMLEFT", 0, -6)
    rail:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 8)
    rail:SetWidth(RAIL_WIDTH)
    self:BuildRail(rail)

    
    local contentArea = CreateFrame("Frame", nil, f)
    contentArea:SetPoint("TOPLEFT", rail, "TOPRIGHT", 6, 0)
    contentArea:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
    self.contentArea = contentArea

    local header = CreateFrame("Frame", nil, contentArea)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER_HEIGHT)
    self.header = header
    self:BuildHeader(header)

    local bodyHost = CreateFrame("Frame", nil, contentArea)
    bodyHost:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    bodyHost:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    self.bodyHost = bodyHost
    self:BuildBody(bodyHost)

    self.window = f
    return f
end













function Seasonal:CreateCharacterButton()
    if self.characterButton then return self.characterButton end
    W = W or ThugUI.Widgets

    local btn = CreateFrame("Button", "ThugUI_SeasonalCharacterButton", CharacterFrame, "UIPanelButtonTemplate")
    btn:SetSize(120, 22)
    
    
    
    
    
    
    
    btn:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 8, -8)
    btn:SetText("Seasonal")
    btn:SetScript("OnClick", function() Seasonal:Toggle() end)
    W.AttachTooltip(btn, "Seasonal Progress", "What this season still has to give you.")

    self.characterButton = btn
    return btn
end





function Seasonal:Show()
    self:CreateWindow()

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    self:PaintRail()

    
    
    
    
    for _, fn in ipairs(self.refreshCallbacks) do
        fn()
    end
    self.window:Show()
end

function Seasonal:Hide()
    if self.window then self.window:Hide() end
end





function Seasonal:Toggle()
    self:CreateWindow()
    if self.window:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end





function Seasonal:Initialize()
    
    
    EnsureDB()

    self:CreateWindow()
    self:CreateCharacterButton()

    if CharacterFrame and type(CharacterFrame.HookScript) == "function" then
        CharacterFrame:HookScript("OnShow", function()
            if EnsureDB().autoOpenWithCharacterFrame ~= false then
                Seasonal:Show()
            end
        end)
        CharacterFrame:HookScript("OnHide", function()
            if EnsureDB().autoOpenWithCharacterFrame ~= false then
                Seasonal:Hide()
            end
        end)
    end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    self:RegisterRefresh(function(key)
        self:PaintTray(key)
        self:PaintCacheBadge(key)
    end)

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    local trayEvents = CreateFrame("Frame")
    trayEvents:SetScript("OnEvent", function()
        if Seasonal.window and Seasonal.window:IsShown() then
            Seasonal:PaintTray()
            Seasonal:PaintCacheBadge()
        end
    end)
    for _, event in ipairs({ "CURRENCY_DISPLAY_UPDATE", "BAG_UPDATE_DELAYED" }) do
        
        
        
        
        
        pcall(trayEvents.RegisterEvent, trayEvents, event)
    end
    self.trayEvents = trayEvents

    
    
    
    
    
    SLASH_THUGSEASON1 = "/thugseason"
    SlashCmdList["THUGSEASON"] = function(msg)
        local arg, rest = tostring(msg or ""):lower():match("^%s*(%S*)%s*(.*)$")

        if arg == "sweep" then
            local probe = ThugUI.SeasonProbe
            if probe and type(probe.SweepQuestFlags) == "function" then
                local lo, hi = tostring(rest or ""):match("(%d+)%s+(%d+)")
                probe:SweepQuestFlags(tonumber(lo), tonumber(hi))
            else
                print("|cff00ccffThugUI|r: the season probe is not loaded, so there is nothing to sweep.")
            end
            return
        end

        if arg == "quest" then
            local probe = ThugUI.SeasonProbe
            if probe and type(probe.DumpQuestRewardTooltips) == "function" then
                probe:DumpQuestRewardTooltips()
            else
                print("|cff00ccffThugUI|r: the season probe is not loaded.")
            end
            return
        end

        Seasonal:Toggle()
    end
end

return Seasonal
