













local ThugUI = _G.ThugUI
local S = {}
ThugUI.WorldMapStrip = S
ThugUI:RegisterModule("WorldMapStrip", S)

local function Cfg()
    local db = ThugUIDB and ThugUIDB.WorldMap or ThugUI.defaults.WorldMap
    
    if db.stripButton == nil then return true end
    return db.stripButton
end

function S:Strip()
    local map = _G.WorldMapFrame
    if not map or not map:IsShown() or self.stripped then return end

    self.alphas = self.alphas or {}
    
    local frames = {
        map.BorderFrame,
        
        
        map.BorderFrame and map.BorderFrame.Bg,
        map.OverscrollBG,
        map.QuestLog
    }
    
    if map.overlayFrames then
        for _, f in ipairs(map.overlayFrames) do
            table.insert(frames, f)
        end
    end
    
    local logged = self.loggedFrames or {}
    self.loggedFrames = logged
    
    for _, f in ipairs(frames) do
        if f then
            if not logged[f] then
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("WORLDMAP", "Stripping frame: " .. tostring(f:GetName() or type(f)))
                end
                logged[f] = true
            end
            
            self.alphas[f] = f:GetAlpha()
            f:SetAlpha(0)
        end
    end
    
    self.blockerTitle:Show()
    if map.QuestLog and map.QuestLog:IsShown() then
        self.blockerQuestLog:Show()
    else
        self.blockerQuestLog:Hide()
    end
    
    self.stripped = true
    self:UpdateButtonIcon()
end

function S:Restore()
    if not self.stripped then return end
    
    if self.alphas then
        for f, alpha in pairs(self.alphas) do
            f:SetAlpha(alpha)
        end
        table.wipe(self.alphas)
    end
    
    self.blockerTitle:Hide()
    self.blockerQuestLog:Hide()
    
    self.stripped = false
    self:UpdateButtonIcon()
end

function S:Toggle()
    if self.stripped then
        self:Restore()
    else
        self:Strip()
    end
end

function S:UpdateButtonIcon()
    if not self.button then return end
    if self.stripped then
        self.button.icon:SetAtlas("common-button-list-collapseExpand", true)
        self.button.tooltip = "Show the map's frame"
    else
        self.button.icon:SetAtlas("common-button-list-collapseExpand", true)
        self.button.tooltip = "Hide the map's frame"
    end
end

function S:Refresh()
    if not self.button then return end
    local show = Cfg()
    if not show and self.stripped then
        self:Restore()
    end
    self.button:SetShown(show)
end

function S:Hook()
    local map = _G.WorldMapFrame
    if not map then return false end
    if self.hooked then return true end
    
    
    self.blockerTitle = CreateFrame("Frame", nil, map)
    self.blockerTitle:EnableMouse(true)
    self.blockerTitle:SetFrameStrata("DIALOG")
    self.blockerTitle:SetPoint("TOPLEFT", map, "TOPLEFT")
    self.blockerTitle:SetPoint("BOTTOMRIGHT", map:GetCanvasContainer(), "TOPRIGHT")
    self.blockerTitle:SetScript("OnMouseWheel", function() end)
    self.blockerTitle:Hide()

    
    self.blockerQuestLog = CreateFrame("Frame", nil, map)
    self.blockerQuestLog:EnableMouse(true)
    self.blockerQuestLog:SetFrameStrata("DIALOG")
    if map.QuestLog then
        self.blockerQuestLog:SetAllPoints(map.QuestLog)
    end
    self.blockerQuestLog:SetScript("OnMouseWheel", function() end)
    self.blockerQuestLog:Hide()
    
    
    self.button = CreateFrame("Button", nil, map)
    self.button:SetFrameStrata("DIALOG")
    self.button:SetFrameLevel(self.blockerTitle:GetFrameLevel() + 10)
    self.button:SetSize(24, 24)
    self.button:SetPoint("TOPRIGHT", map:GetCanvasContainer(), "TOPRIGHT", -4, -4)
    
    self.button.icon = self.button:CreateTexture(nil, "ARTWORK")
    self.button.icon:SetAllPoints()
    self.button.icon:SetAtlas("common-button-list-collapseExpand", true)
    
    self.button:SetScript("OnClick", function() self:Toggle() end)
    self.button:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(btn.tooltip or "Hide the map's frame")
        GameTooltip:Show()
    end)
    self.button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    map:HookScript("OnHide", function() self:Restore() end)
    
    self.hooked = true
    self:UpdateButtonIcon()
    self:Refresh()
    return true
end

function S:Initialize()
    if self:Hook() then return end
    
    local f = CreateFrame("Frame")
    ThugUI.SafeRegisterEvent(f, "ADDON_LOADED")
    f:SetScript("OnEvent", function(frame, event, addon)
        if addon == "Blizzard_WorldMap" then
            if S:Hook() then
                frame:UnregisterEvent("ADDON_LOADED")
            end
        end
    end)
end
