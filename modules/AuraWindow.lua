

























local ThugUI = _G.ThugUI
local AW = {}
ThugUI.AuraWindow = AW
ThugUI:RegisterModule("AuraWindow", AW)

ThugUI.defaults.AuraWindow = {
    enabled = true,
}

local UI = {}
local auras = { buffs = {}, debuffs = {} }
AW.rows = auras
AW.row = "buffs"
AW.col = 1
AW.openedFromShortcut = false
local hookedShortcuts = {}

local function CheckSecret(val)
    return issecretvalue and issecretvalue(val)
end

function AW:Collect()
    table.wipe(auras.buffs)
    table.wipe(auras.debuffs)

    local function CollectData(targetTable, apiFunc)
        for i = 1, 40 do
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
end

function AW:Build()
    if UI.frame then return end

    local f = CreateFrame("Frame", "ThugUI_AuraWindow", UIParent, "BackdropTemplate")
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("auras", function() return f and f:IsShown() end, function() AW:Close() end)
    end
    f:SetFrameStrata("DIALOG")
    
    f:SetSize(740, 200)
    f:SetPoint("CENTER")

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetBackdropColor(0.04, 0.04, 0.06, 0.96)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Auras")

    local function MakeRow(parent, yOffset, labelText)
        local r = CreateFrame("Frame", nil, parent)
        r:SetSize(720, 50)
        r:SetPoint("TOP", 0, yOffset)

        local label = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", 10, 0)
        label:SetText(labelText)

        r.cells = {}
        for i = 1, 16 do
            local cell = CreateFrame("Frame", nil, r)
            cell:SetSize(36, 36)
            cell:SetPoint("LEFT", label, "RIGHT", 10 + (i - 1) * 40, 0)

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

            r.cells[i] = cell
        end
        return r
    end

    UI.buffRow = MakeRow(f, -60, "Buffs")
    UI.debuffRow = MakeRow(f, -120, "Debuffs")

    UI.noAuras = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.noAuras:SetPoint("CENTER")
    UI.noAuras:SetText("No auras.")

    local footer = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOM", 0, 15)
    footer:SetText("Square: remove buff   Circle: close")

    f:SetScript("OnEvent", function(self, event, unit)
        if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
        if event == "UNIT_AURA" and unit == "player" and self:IsShown() then
            AW:Refresh()
        end
    end)

    f:SetScript("OnGamePadButtonDown", function(self, button)
        AW:OnButton(button)
    end)

    f:SetScript("OnGamePadStick", function(self, stick, x, y)
        if stick ~= "Movement" then return end

        
        if math.abs(x) < 0.3 and math.abs(y) < 0.3 then
            AW.stickReady = true
            return
        end

        if not AW.stickReady then return end

        if x > 0.5 then
            AW:MoveSelection(0, 1)
            AW.stickReady = false
        elseif x < -0.5 then
            AW:MoveSelection(0, -1)
            AW.stickReady = false
        elseif y > 0.5 then
            AW:MoveSelection(-1, 0)
            AW.stickReady = false
        elseif y < -0.5 then
            AW:MoveSelection(1, 0)
            AW.stickReady = false
        end
    end)

    f:Hide()
    UI.frame = f
end

function AW:UpdateDisplay()
    local hasAny = false

    local function UpdateRow(rowFrame, data)
        for i = 1, 16 do
            local cell = rowFrame.cells[i]
            local aura = data[i]

            if aura then
                hasAny = true
                cell.icon:SetTexture(aura.icon)
                cell.icon:Show()

                if not CheckSecret(aura.applications) and aura.applications and aura.applications > 1 then
                    cell.count:SetText(aura.applications)
                else
                    cell.count:SetText("")
                end

                if not CheckSecret(aura.duration) and not CheckSecret(aura.expirationTime) and aura.duration and aura.duration > 0 then
                    cell.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                else
                    cell.cooldown:Clear()
                end

                if AW.row == (rowFrame == UI.buffRow and "buffs" or "debuffs") and AW.col == i then
                    cell.highlight:Show()

                    GameTooltip:SetOwner(cell, "ANCHOR_BOTTOM")
                    local ok
                    if AW.row == "buffs" then
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

    UpdateRow(UI.buffRow, auras.buffs)
    UpdateRow(UI.debuffRow, auras.debuffs)

    if not hasAny then
        UI.noAuras:Show()
        UI.buffRow:Hide()
        UI.debuffRow:Hide()
        GameTooltip:Hide()
    else
        UI.noAuras:Hide()
        UI.buffRow:Show()
        UI.debuffRow:Show()
    end
end

function AW:MoveSelection(dRow, dCol)
    if #auras.buffs == 0 and #auras.debuffs == 0 then return end

    local newRow = AW.row
    local newCol = AW.col + dCol

    if dRow ~= 0 then
        newRow = AW.row == "buffs" and "debuffs" or "buffs"
    end

    local targetList = auras[newRow]
    if #targetList == 0 then
        
        newRow = AW.row
        targetList = auras[newRow]
    end

    if newCol < 1 then newCol = 1 end
    if newCol > #targetList then newCol = #targetList end
    if newCol > 16 then newCol = 16 end

    AW.row = newRow
    AW.col = newCol

    self:UpdateDisplay()
end

function AW:RemoveSelected()
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
        for i = 1, 40 do
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

function AW:Open()
    if not ThugUI.CombatClose:Allow("auras") then return end
    self:Build()
    self:Collect()

    if #auras.buffs > 0 then
        AW.row = "buffs"
        AW.col = 1
    elseif #auras.debuffs > 0 then
        AW.row = "debuffs"
        AW.col = 1
    else
        AW.row = "buffs"
        AW.col = 1
    end

    AW.stickReady = true

    pcall(function()
        UI.frame:EnableGamePadButton(true)
        UI.frame:EnableGamePadStick(true)
    end)

    if not InCombatLockdown() then
        UI.frame:SetPropagateKeyboardInput(false)
    end

    pcall(function()
        UI.frame:RegisterUnitEvent("UNIT_AURA", "player")
    end)

    UI.frame:Show()
    self:UpdateDisplay()
end

function AW:Close()
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
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event)
        if not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
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
            if not ThugUI.ControllerMode:Uses("auras") then
                AW:Close()
            end
        end
        ThugUI.ControllerMode:RegisterFeatureCallback("auras", CheckFeature)
        ThugUI.ControllerMode:RegisterCallback(CheckFeature)
    end
end
