


































local ThugUI = _G.ThugUI
local AW = {}
ThugUI.AuraWindow = AW
ThugUI:RegisterModule("AuraWindow", AW)

ThugUI.defaults.AuraWindow = {
    iconSize = 36,
    spacing = 4,
    perRow = 16,
    scale = 1,
    order = "buffs",        
    sort = "game",          
    showPermanent = true,   
    showTimers = true,
    showCounts = true,
    showLabels = true,
    bgAlpha = 0.96,
    
}

local MAX_PER_SECTION = 40
local MARGIN = 16
local LABEL_WIDTH = 70
local TITLE_HEIGHT = 50
local FOOTER_HEIGHT = 36
local SECTION_GAP = 10
local SAMPLE_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local UI = {}
local auras = { buffs = {}, debuffs = {} }
AW.rows = auras
AW.row = "buffs"
AW.col = 1
AW.openedFromShortcut = false
AW.testMode = false
local hookedShortcuts = {}

local function CheckSecret(val)
    return issecretvalue and issecretvalue(val)
end

local function Readable(val)
    return val ~= nil and not CheckSecret(val)
end

function AW:Cfg()
    ThugUIDB.AuraWindow = ThugUIDB.AuraWindow or {}
    local c = ThugUIDB.AuraWindow
    for k, v in pairs(ThugUI.defaults.AuraWindow) do
        if c[k] == nil then c[k] = v end
    end
    return c
end

local function SectionOrder()
    local c = AW:Cfg()
    if c.order == "debuffs" then return { "debuffs", "buffs" } end
    return { "buffs", "debuffs" }
end
AW.SectionOrder = SectionOrder








local function ApplyRules(list)
    local c = AW:Cfg()
    if not c.showPermanent then
        for i = #list, 1, -1 do
            local d = list[i].duration
            if Readable(d) and d == 0 then table.remove(list, i) end
        end
    end
    if c.sort == "shortest" or c.sort == "longest" then
        for i, a in ipairs(list) do a.__order = i end
        local function Key(a)
            local d, e = a.duration, a.expirationTime
            if Readable(d) and Readable(e) and d > 0 then return e end
            return nil
        end
        local longest = c.sort == "longest"
        table.sort(list, function(a, b)
            local ka, kb = Key(a), Key(b)
            if ka and kb and ka ~= kb then
                if longest then return ka > kb end
                return ka < kb
            end
            if ka and not kb then return true end
            if kb and not ka then return false end
            return a.__order < b.__order
        end)
    end
end
AW.ApplyRules = ApplyRules

function AW:Collect()
    table.wipe(auras.buffs)
    table.wipe(auras.debuffs)

    if self.testMode then
        self:CollectSamples()
        return
    end

    local function CollectData(targetTable, apiFunc)
        for i = 1, MAX_PER_SECTION do
            local ok, aura = pcall(apiFunc, "player", i)
            if not ok or not aura then break end

            table.insert(targetTable, {
                auraInstanceID = aura.auraInstanceID,
                icon = aura.icon,
                applications = aura.applications,
                duration = aura.duration,
                expirationTime = aura.expirationTime,
            })
        end
    end

    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        CollectData(auras.buffs, C_UnitAuras.GetBuffDataByIndex)
    end
    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        CollectData(auras.debuffs, C_UnitAuras.GetDebuffDataByIndex)
    end
    ApplyRules(auras.buffs)
    ApplyRules(auras.debuffs)
end



AW.SAMPLE_BUFFS = 12
AW.SAMPLE_DEBUFFS = 4
function AW:CollectSamples()
    local now = GetTime and GetTime() or 0
    local function Fill(list, n, base)
        for i = 1, n do
            local permanent = (i % 5 == 0)
            table.insert(list, {
                sample = true,
                icon = SAMPLE_ICON,
                applications = (i % 3 == 0) and i or 0,
                duration = permanent and 0 or (60 * i),
                expirationTime = permanent and 0 or (now + 60 * i - base * i),
            })
        end
    end
    Fill(auras.buffs, self.SAMPLE_BUFFS, 7)
    Fill(auras.debuffs, self.SAMPLE_DEBUFFS, 3)
    ApplyRules(auras.buffs)
    ApplyRules(auras.debuffs)
end





local function NewCell(parent)
    local cell = CreateFrame("Frame", nil, parent)
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetAllPoints()
    cell.cooldown = CreateFrame("Cooldown", nil, cell, "CooldownFrameTemplate")
    cell.cooldown:SetAllPoints()
    cell.count = cell:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    cell.count:SetPoint("BOTTOMRIGHT", -2, 2)
    cell.highlight = cell:CreateTexture(nil, "OVERLAY")
    cell.highlight:SetAllPoints()
    cell.highlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    cell.highlight:SetBlendMode("ADD")
    cell.highlight:Hide()
    cell:Hide()
    return cell
end

local function MakeSection(parent, labelText)
    local r = CreateFrame("Frame", nil, parent)
    r.label = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.label:SetPoint("TOPLEFT", 0, -4)
    r.label:SetText(labelText)
    
    r.cells = {}
    for i = 1, MAX_PER_SECTION do r.cells[i] = NewCell(r) end
    return r
end

local function SavePosition(f)
    local c = AW:Cfg()
    local s = f:GetScale() or 1
    local cx, cy = f:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not (cx and cy and ux and uy) then return end
    c.point = { cx * s - ux, cy * s - uy }
end
AW.SavePosition = SavePosition

function AW:ApplyPosition()
    local f = UI.frame
    if not f then return end
    local c = self:Cfg()
    local s = c.scale or 1
    f:SetScale(s)
    f:ClearAllPoints()
    local p = c.point
    if type(p) == "table" and type(p[1]) == "number" and type(p[2]) == "number" then
        
        f:SetPoint("CENTER", UIParent, "CENTER", p[1] / s, p[2] / s)
    else
        f:SetPoint("CENTER")
    end
end

function AW:ResetPosition()
    self:Cfg().point = nil
    self:ApplyPosition()
end

function AW:Build()
    if UI.frame then return end

    local f = CreateFrame("Frame", "ThugUI_AuraWindow", UIParent, "BackdropTemplate")
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("auras", function() return f and f:IsShown() end, function() AW:Close() end)
    end
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if AW.testMode and not InCombatLockdown() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
        AW:ApplyPosition()
    end)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Auras")
    UI.title = title

    UI.buffRow = MakeSection(f, "Buffs")
    UI.debuffRow = MakeSection(f, "Debuffs")
    UI.sections = { buffs = UI.buffRow, debuffs = UI.debuffRow }

    UI.noAuras = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.noAuras:SetPoint("CENTER")
    UI.noAuras:SetText("No auras.")

    UI.footer = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    UI.footer:SetPoint("BOTTOM", 0, 15)

    f:SetScript("OnEvent", function(self, event, unit)
        if not ThugUI:IsModuleOn("auras") then self:UnregisterAllEvents() return end
        if event == "UNIT_AURA" and unit == "player" and self:IsShown() then
            AW:Refresh()
        end
    end)

    f:SetScript("OnGamePadButtonDown", function(self, button)
        AW:OnButton(button)
    end)

    
    
    

    f:Hide()
    UI.frame = f
    AW.frame = f
    AW.ui = UI
    self:ApplyPosition()
end



function AW:Layout()
    local f = UI.frame
    if not f then return end
    local c = self:Cfg()
    local size = math.max(16, c.iconSize or 36)
    local gap = math.max(0, c.spacing or 4)
    local perRow = math.max(1, math.min(MAX_PER_SECTION, c.perRow or 16))
    local labelW = c.showLabels and LABEL_WIDTH or 0

    
    local tr, tg, tb = ThugUI.Theme:Color("background")
    f:SetBackdropColor(tr, tg, tb, c.bgAlpha or 0.96)
    UI.title:SetShown(c.showLabels and true or false)

    local widest = 0
    for _, key in ipairs({ "buffs", "debuffs" }) do
        local n = math.min(#auras[key], MAX_PER_SECTION)
        widest = math.max(widest, math.min(n, perRow))
    end
    widest = math.max(widest, 4)

    local top = c.showLabels and TITLE_HEIGHT or MARGIN
    local y = -top
    for _, key in ipairs(SectionOrder()) do
        local sec = UI.sections[key]
        local n = math.min(#auras[key], MAX_PER_SECTION)
        sec.label:SetShown(c.showLabels and true or false)
        if n > 0 then
            local rows = math.ceil(n / perRow)
            local h = rows * size + (rows - 1) * gap
            sec:ClearAllPoints()
            sec:SetPoint("TOPLEFT", f, "TOPLEFT", MARGIN, y)
            sec:SetSize(labelW + perRow * (size + gap), h)
            sec.layoutY = y
            for i = 1, MAX_PER_SECTION do
                local cell = sec.cells[i]
                cell:SetSize(size, size)
                cell:ClearAllPoints()
                local r = math.floor((i - 1) / perRow)
                local col = (i - 1) % perRow
                cell:SetPoint("TOPLEFT", sec, "TOPLEFT", labelW + col * (size + gap), -r * (size + gap))
                cell.layoutX, cell.layoutY = labelW + col * (size + gap), -r * (size + gap)
            end
            sec:Show()
            y = y - h - SECTION_GAP
        else
            sec:Hide()
        end
    end

    local contentH = -y - top - SECTION_GAP
    if contentH < size then contentH = size end
    local width = MARGIN * 2 + labelW + widest * (size + gap) - gap
    f:SetSize(math.max(width, 220), top + contentH + FOOTER_HEIGHT + MARGIN)
end

function AW:UpdateDisplay()
    local c = self:Cfg()
    local hasAny = false

    local function UpdateRow(key)
        local rowFrame = UI.sections[key]
        local data = auras[key]
        for i = 1, MAX_PER_SECTION do
            local cell = rowFrame.cells[i]
            local aura = data[i]

            if aura then
                hasAny = true
                cell.icon:SetTexture(aura.icon)
                cell.icon:Show()

                if c.showCounts and Readable(aura.applications) and aura.applications > 1 then
                    cell.count:SetText(aura.applications)
                else
                    cell.count:SetText("")
                end

                if c.showTimers and Readable(aura.duration) and Readable(aura.expirationTime) and aura.duration > 0 then
                    cell.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                else
                    cell.cooldown:Clear()
                end

                if not AW.testMode and AW.row == key and AW.col == i then
                    cell.highlight:Show()

                    GameTooltip:SetOwner(cell, "ANCHOR_BOTTOM")
                    local ok
                    if key == "buffs" then
                        ok = pcall(function() GameTooltip:SetUnitBuffByAuraInstanceID("player", aura.auraInstanceID) end)
                    else
                        ok = pcall(function() GameTooltip:SetUnitDebuffByAuraInstanceID("player", aura.auraInstanceID) end)
                    end
                    if ok then GameTooltip:Show() else GameTooltip:Hide() end
                else
                    cell.highlight:Hide()
                end

                cell:Show()
            else
                cell:Hide()
            end
        end
    end

    UpdateRow("buffs")
    UpdateRow("debuffs")
    self:Layout()

    if self.testMode then
        UI.footer:SetText("Test mode: drag to move. Untick Test mode to finish.")
    else
        UI.footer:SetText("Square: remove buff   Circle: close")
    end

    if not hasAny then
        UI.noAuras:Show()
        UI.buffRow:Hide()
        UI.debuffRow:Hide()
        GameTooltip:Hide()
    else
        UI.noAuras:Hide()
    end
end








function AW:MoveSelection(dRow, dCol)
    if #auras.buffs == 0 and #auras.debuffs == 0 then return end
    local perRow = math.max(1, self:Cfg().perRow or 16)
    local list = auras[AW.row]
    local idx = AW.col

    if dCol ~= 0 then
        idx = math.max(1, math.min(#list, idx + dCol))
    end

    if dRow ~= 0 then
        local myRow = math.floor((idx - 1) / perRow)
        local lastRow = math.floor((math.max(#list, 1) - 1) / perRow)
        local col = (idx - 1) % perRow + 1
        local targetRow = myRow + dRow
        if targetRow >= 0 and targetRow <= lastRow then
            idx = math.min(targetRow * perRow + col, #list)
        else
            
            local order = SectionOrder()
            local pos = (order[1] == AW.row) and 1 or 2
            local otherKey = order[pos + dRow]
            local other = otherKey and auras[otherKey]
            if other and #other > 0 then
                AW.row = otherKey
                list = other
                if dRow > 0 then
                    idx = math.min(col, #list)
                else
                    local startLast = math.floor((#list - 1) / perRow) * perRow
                    idx = math.min(startLast + col, #list)
                end
            end
        end
    end

    if idx > #list then idx = #list end
    if idx < 1 then idx = 1 end
    AW.col = idx

    self:UpdateDisplay()
end

function AW:RemoveSelected()
    if self.testMode then return end
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("Can't remove buffs in combat.", 1, 0.1, 0.1)
        return
    end

    if AW.row == "debuffs" then
        UIErrorsFrame:AddMessage("Debuffs can't be removed.", 1, 0.1, 0.1)
        return
    end

    local aura = auras.buffs[AW.col]
    if not aura then return end

    local targetID = aura.auraInstanceID
    local foundIndex = nil

    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        for i = 1, MAX_PER_SECTION do
            local ok, currentAura = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
            if not ok or not currentAura then break end

            if not CheckSecret(currentAura.auraInstanceID) and currentAura.auraInstanceID == targetID then
                foundIndex = i
                break
            end
        end
    end

    if foundIndex then
        local ok = pcall(CancelUnitBuff, "player", foundIndex, "HELPFUL")
        if ok and ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("AURAS", "cancel %d", foundIndex)
        end
    else
        AW:Refresh()
    end
end

function AW:OnButton(button)
    if button == "PAD2" then
        self:Close()
    elseif button == "PADDLEFT" then
        self:MoveSelection(0, -1)
    elseif button == "PADDRIGHT" then
        self:MoveSelection(0, 1)
    elseif button == "PADDUP" then
        self:MoveSelection(-1, 0)
    elseif button == "PADDDOWN" then
        self:MoveSelection(1, 0)
    elseif button == "PAD3" or button == "GAMEPAD_FACE_LEFT" then
        self:RemoveSelected()
    end
    
end

function AW:Refresh()
    local oldTarget = auras[AW.row] and auras[AW.row][AW.col] and auras[AW.row][AW.col].auraInstanceID

    self:Collect()

    local found = false
    if oldTarget and not CheckSecret(oldTarget) then
        for i, a in ipairs(auras[AW.row]) do
            if not CheckSecret(a.auraInstanceID) and a.auraInstanceID == oldTarget then
                AW.col = i
                found = true
                break
            end
        end
    end

    if not found then
        if #auras[AW.row] < AW.col then
            AW.col = math.max(1, #auras[AW.row])
        end
    end

    if #auras[AW.row] == 0 then
        AW.row = AW.row == "buffs" and "debuffs" or "buffs"
        AW.col = 1
    end

    self:UpdateDisplay()
end



function AW:ApplySettings()
    if not UI.frame then return end
    self:ApplyPosition()
    if UI.frame:IsShown() then self:Refresh() end
end





function AW:Open()
    if not ThugUI.CombatClose:Allow("auras") then return end
    if self.testMode then self:SetTestMode(false) end
    self:Build()
    self:Collect()

    local first = SectionOrder()[1]
    if #auras[first] > 0 then
        AW.row = first
    elseif #auras.buffs > 0 then
        AW.row = "buffs"
    elseif #auras.debuffs > 0 then
        AW.row = "debuffs"
    else
        AW.row = first
    end
    AW.col = 1

    pcall(function()
        UI.frame:EnableGamePadButton(true)
        UI.frame:EnableGamePadStick(false)
    end)

    if not InCombatLockdown() then
        UI.frame:SetPropagateKeyboardInput(false)
    end

    pcall(function()
        UI.frame:RegisterUnitEvent("UNIT_AURA", "player")
    end)

    UI.frame:EnableMouse(false)
    UI.frame:Show()
    self:UpdateDisplay()
end

function AW:Close()
    if self.testMode then
        self:SetTestMode(false)
        return
    end
    if not UI.frame or not UI.frame:IsShown() then return end

    
    
    
    if self.openedFromShortcut then
        self.openedFromShortcut = false
        if not InCombatLockdown() then
            UI.frame:SetPropagateKeyboardInput(true)
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function() UI.frame:SetPropagateKeyboardInput(false) end)
            end
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("AURAS", "circle out of combat: closed and propagated")
            end
        else
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("AURAS", "circle in combat: closed without propagation")
            end
        end
    end

    UI.frame:Hide()
    pcall(function()
        UI.frame:EnableGamePadButton(false)
        UI.frame:EnableGamePadStick(false)
        UI.frame:UnregisterEvent("UNIT_AURA")
    end)

    GameTooltip:Hide()
end







function AW:IsTestMode()
    return self.testMode and true or false
end

function AW:SetTestMode(on)
    on = on and true or false
    if on and InCombatLockdown() then return end
    if self.testMode == on then return end
    self:Build()
    local f = UI.frame

    if on then
        
        if f:IsShown() then self:Close() end
        self.testMode = true
        self:Collect()
        AW.row, AW.col = SectionOrder()[1], 1
        pcall(function()
            f:EnableGamePadButton(false)
            f:EnableGamePadStick(false)
        end)
        f:EnableMouse(true)
        f:Show()
        self:UpdateDisplay()
        local w = ThugUI.Window and ThugUI.Window.frame
        if w and not self.testHooked then
            self.testHooked = true
            w:HookScript("OnHide", function() AW:SetTestMode(false) end)
        end
    else
        self.testMode = false
        f:EnableMouse(false)
        f:Hide()
        table.wipe(auras.buffs)
        table.wipe(auras.debuffs)
    end
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("AURAS", "test mode %s", on and "on" or "off")
    end
end






function AW:HookShortcuts()
    local CM = ThugUI.ControllerMode
    local bar = CM and CM:GetShortcutsBar()

    if not bar then return false end

    if AW.installed then return true end
    AW.installed = true

    for _, side in ipairs({ bar.Left, bar.Right }) do
        local b = side and side.ActionButton2
        if b and not hookedShortcuts[b] and b.HookScript then
            hookedShortcuts[b] = true
            b:HookScript("PostClick", function(self, _, down)
                if not down or self ~= bar.faceTopButton then return end
                if CM and CM:Uses("auras") then
                    AW.openedFromShortcut = true
                    AW:Open()
                end
            end)
        end
    end

    return true
end

function AW:Initialize()
    self:Cfg()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event)
        if not ThugUI:IsModuleOn("auras") then self:UnregisterAllEvents() return end
        if event == "PLAYER_ENTERING_WORLD" then
            AW:HookShortcuts()
        end
    end)
    ThugUI.SafeRegisterEvent(frame, "PLAYER_ENTERING_WORLD")

    if C_Timer and C_Timer.After then
        C_Timer.After(3, function() AW:HookShortcuts() end)
    end

    if ThugUI.ControllerMode then
        local function CheckFeature()
            if not ThugUI.ControllerMode:Uses("auras") and not AW.testMode then
                AW:Close()
            end
        end
        ThugUI.ControllerMode:RegisterFeatureCallback("auras", CheckFeature)
        ThugUI.ControllerMode:RegisterCallback(CheckFeature)
    end
end
