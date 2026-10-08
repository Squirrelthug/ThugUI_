









local MODULE_NAME = "FocusedQuest"
local FocusedQuest = {}
ThugUI:RegisterModule(MODULE_NAME, FocusedQuest)

local db
local frame
local isDirty = false

local UpdateContent

local function QueueUpdate()
    if isDirty then return end
    isDirty = true
    C_Timer.After(0, function()
        if not isDirty then return end
        isDirty = false
        UpdateContent()
    end)
end

ThugUI.defaults.FocusedQuest = {
    enabled = true,
    heightOffset = 4,  
    
    
    
    point = nil,
}

function FocusedQuest:Initialize()
    db = ThugUIDB.FocusedQuest
    self.db = db
    frame = CreateFrame("Frame", "ThugUI_FocusedQuestFrame", UIParent)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetJustifyH("CENTER")
    title:SetWidth(260)
    title:SetWordWrap(true)
    title:SetPoint("TOP", frame, "TOP", 0, 0)
    frame.title = title

    local objectives = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    objectives:SetJustifyH("CENTER")
    objectives:SetWidth(260)
    objectives:SetWordWrap(true)
    objectives:SetPoint("TOP", title, "BOTTOM", 0, -2)
    frame.objectives = objectives

    if ThugUI.ControllerMode then
        ThugUI.ControllerMode:RegisterCallback(function(isActive)
            FocusedQuest:UpdateVisibility()
        end)
        ThugUI.ControllerMode:RegisterFeatureCallback("objectives", function()
            FocusedQuest:UpdateVisibility()
        end)
    end

    local events = {
        "SUPER_TRACKING_CHANGED",
        "QUEST_LOG_UPDATE",
        "QUEST_WATCH_UPDATE",
        "QUEST_TURNED_IN",
        "QUEST_REMOVED",
        "ZONE_CHANGED_NEW_AREA"
    }
    for _, event in ipairs(events) do
        
        
        ThugUI.SafeRegisterEvent(frame, event)
    end

    frame:SetScript("OnEvent", function(self, event)
        if not ThugUI:IsModuleOn("controller") then
            self:UnregisterAllEvents()
            self:Hide()
            return
        end
        QueueUpdate()
    end)

    self:UpdateVisibility()
end

function FocusedQuest:UpdateVisibility()
    
    
    if db.enabled and ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("objectives") then
        QueueUpdate()
    else
        frame:Hide()
    end
end

local issecret = _G.issecretvalue
local canaccess = _G.canaccessvalue

local function IsUsable(value)
    if value == nil then return false end
    if issecret and issecret(value) then return false end
    if canaccess and not canaccess(value) then return false end
    return true
end

function FocusedQuest:GetLines()
    local questID = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID()
    if not IsUsable(questID) or questID == 0 then return nil, {} end

    local title = C_QuestLog.GetTitleForQuestID(questID)
    if not IsUsable(title) or title == "" then return nil, {} end

    local lines = {}
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    if objectives then
        for _, obj in ipairs(objectives) do
            
            if IsUsable(obj.text) and obj.text ~= "" then
                table.insert(lines, obj.text)
            end
        end
    end

    if #lines == 0 and C_QuestLog.IsComplete(questID) then
        local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        local compText = logIndex and type(GetQuestLogCompletionText) == "function"
            and GetQuestLogCompletionText(logIndex)
        if IsUsable(compText) and compText ~= "" then
            table.insert(lines, compText)
        else
            table.insert(lines, _G.QUEST_WATCH_QUEST_READY or "Ready for turn-in")
        end
    end

    return title, lines
end

function UpdateContent()
    
    local MP = ThugUI.MinimapPanel
    if MP and MP.hiddenForCombat then
        frame:Hide()
        return
    end
    if not db.enabled or not ThugUI.ControllerMode or not ThugUI.ControllerMode:Uses("objectives") then
        frame:Hide()
        return
    end

    local title, lines = FocusedQuest:GetLines()
    if not title then
        frame:Hide()
        return
    end

    frame.title:SetText(title)
    
    if #lines > 0 then
        frame.objectives:SetText(table.concat(lines, "\n"))
        frame.objectives:Show()
    else
        frame.objectives:SetText("")
        frame.objectives:Hide()
    end

    local totalHeight = frame.title:GetHeight()
    if #lines > 0 then
        totalHeight = totalHeight + 2 + frame.objectives:GetHeight()
    end
    frame:SetHeight(totalHeight)
    frame:SetWidth(260)

    frame:ClearAllPoints()
    local p = db.point
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        
        frame:SetPoint("TOP", UIParent, "BOTTOMLEFT", p.x, p.y)
        frame:Show()
        return
    end
    
    local y = tonumber(db.heightOffset) or 4
    local zoneText = _G.ThugUI_MinimapZoneText
    local minCluster = _G.MinimapCluster
    local minimap = _G.Minimap

    if zoneText and zoneText:IsShown() then
        frame:SetPoint("BOTTOM", zoneText, "TOP", 0, y)
    elseif minCluster then
        frame:SetPoint("BOTTOM", minCluster, "TOP", 0, y)
    elseif minimap then
        frame:SetPoint("BOTTOM", minimap, "TOP", 0, y)
    end

    frame:Show()
end

function FocusedQuest:ApplySettings()
    self:UpdateVisibility()
end








local mover

local function EnsureMover()
    if mover then return mover end
    mover = CreateFrame("Frame", "ThugUI_FocusedQuestMover", UIParent, "BackdropTemplate")
    mover:SetSize(260, 60)
    mover:SetFrameStrata("DIALOG")
    mover:SetClampedToScreen(true)
    mover:SetMovable(true)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    if mover.SetBackdrop then
        mover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        mover:SetBackdropColor(0, 0, 0, 0.5)
        mover:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
    local text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("Focused quest\n|cffffffffdrag to move|r")
    mover:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, top = self:GetCenter(), self:GetTop()
        if type(x) == "number" and type(top) == "number" then
            db.point = { x = x, y = top }
            UpdateContent()
        end
    end)
    mover:Hide()
    FocusedQuest.mover = mover
    return mover
end

function FocusedQuest:SetUnlocked(unlocked)
    self.unlocked = unlocked and true or false
    local m = EnsureMover()
    if not self.unlocked then
        m:Hide()
        return
    end
    m:ClearAllPoints()
    local p = db.point
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        m:SetPoint("TOP", UIParent, "BOTTOMLEFT", p.x, p.y)
    else
        
        local anchor = (_G.ThugUI_MinimapZoneText and _G.ThugUI_MinimapZoneText:IsShown()
            and _G.ThugUI_MinimapZoneText) or _G.MinimapCluster or _G.Minimap
        if anchor then
            m:SetPoint("BOTTOM", anchor, "TOP", 0, tonumber(db.heightOffset) or 4)
        else
            m:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        end
    end
    m:Show()
end

function FocusedQuest:ResetPosition()
    db.point = nil
    if self.unlocked then self:SetUnlocked(true) end
    self:UpdateVisibility()
end
