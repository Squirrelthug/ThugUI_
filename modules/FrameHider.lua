




ThugUI = ThugUI or {}
ThugUI_Config = ThugUI_Config or {}

local FrameHider = {}
ThugUI.FrameHider = FrameHider


FrameHider.applied = {}




local function Cfg()
    ThugUIDB.FrameHider = ThugUIDB.FrameHider or {}
    return ThugUIDB.FrameHider
end
FrameHider.Cfg = Cfg


















local pendingHides = {}
local regenWatcher

local function HideSecurely(frame)
    if pcall(RegisterStateDriver, frame, "visibility", "hide") then
        return true
    end
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("FRAMEHIDER", "state driver refused for %s; using Hide()",
            tostring(frame.GetName and frame:GetName() or frame))
    end
    if InCombatLockdown() then
        pendingHides[frame] = true
        if not regenWatcher then
            regenWatcher = CreateFrame("Frame")
            regenWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
            regenWatcher:SetScript("OnEvent", function()
                for f in pairs(pendingHides) do
                    pendingHides[f] = nil
                    f:Hide()
                end
            end)
        end
        return false
    end
    frame:Hide()
    return true
end
FrameHider.HideSecurely = HideSecurely















local trackerHolder
local trackerWatch
local TRACKER_LADDER = { 0.1, 0.5, 1, 2, 5 }

local function Tracker()
    return _G.ObjectiveTrackerFrame
end

local function TrackerHolder()
    if not trackerHolder then
        trackerHolder = CreateFrame("Frame", "ThugUI_FrameHiderHolder", UIParent)
        trackerHolder:Hide()
    end
    return trackerHolder
end

function FrameHider:OwnsObjectiveTracker()
    if ThugUI.controllerAtLoad then return false end
    return true
end

local function TrackerWantHidden()
    return Cfg().hideObjectiveTracker == true and FrameHider:OwnsObjectiveTracker()
end




local function ReassertTracker()
    if not TrackerWantHidden() then return end
    local t = Tracker()
    if not t or t:GetParent() == TrackerHolder() then return end
    if InCombatLockdown() then return end
    t:SetParent(TrackerHolder())
end
FrameHider.ReassertTracker = ReassertTracker

local function ScheduleTrackerReassert()
    ReassertTracker()
    if not (C_Timer and C_Timer.After) then return end
    for _, delay in ipairs(TRACKER_LADDER) do C_Timer.After(delay, ReassertTracker) end
end

local function EnsureTrackerWatch()
    if trackerWatch then return end
    trackerWatch = CreateFrame("Frame")
    trackerWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
    trackerWatch:RegisterEvent("PLAYER_REGEN_ENABLED")
    trackerWatch:SetScript("OnEvent", ScheduleTrackerReassert)
    
    
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            if C_Timer and C_Timer.After then C_Timer.After(0, ScheduleTrackerReassert)
            else ScheduleTrackerReassert() end
        end, FrameHider)
    end
end




function FrameHider:MigrateTrackerFromAcorns()
    if Cfg().hideObjectiveTracker ~= nil then return end
    local o = ThugUIDB and ThugUIDB.Acorns and ThugUIDB.Acorns.objectives
    if o and o.visible == false then Cfg().hideObjectiveTracker = true end
end










local trackerAlphaSet = false

function FrameHider:TrackerAlpha(alpha)
    local V = ThugUI.Visibility
    if Cfg().trackerInstanceCombat and V and V:InCombat()
        and type(IsInInstance) == "function" and IsInInstance() then
        return 0
    end
    return alpha or 1
end

function FrameHider:ApplyTrackerVisibility(alpha)
    if not self:OwnsObjectiveTracker() then return end
    local t = Tracker()
    if not t or not t.SetAlpha then return end
    local V = ThugUI.Visibility
    local default = (not V or V:IsDefault("objectives")) and not Cfg().trackerInstanceCombat
    if default then
        if trackerAlphaSet then t:SetAlpha(1); trackerAlphaSet = false end
        return
    end
    if alpha == nil then alpha = V and V:CurrentAlpha("objectives") or 1 end
    t:SetAlpha(self:TrackerAlpha(alpha))
    trackerAlphaSet = true
end

function FrameHider:SetTrackerInstanceCombat(on)
    Cfg().trackerInstanceCombat = on and true or false
    self:ApplyTrackerVisibility()
end


function FrameHider:MigrateTrackerCombatFromAcorns()
    if Cfg().trackerInstanceCombat ~= nil then return end
    local o = ThugUIDB and ThugUIDB.Acorns and ThugUIDB.Acorns.objectives
    if o and o.hideInCombat == true then Cfg().trackerInstanceCombat = true end
end


function FrameHider:SetObjectiveTrackerHidden(hidden)
    Cfg().hideObjectiveTracker = hidden and true or false
    if not self:OwnsObjectiveTracker() then return end
    local t = Tracker()
    if not t then return end
    if hidden then
        EnsureTrackerWatch()
        ScheduleTrackerReassert()
    elseif t:GetParent() == trackerHolder and not InCombatLockdown() then
        t:SetParent(UIParent)
        t:Show()
    end
end


function FrameHider:HideStanceBar()
    if self.applied.stanceBar then return end
    if not StanceBar then return end

    HideSecurely(StanceBar)
    self.applied.stanceBar = true
end


function FrameHider:HideBagButtons()
    if self.applied.bagButtons then return end

    if MainMenuBarBackpackButton then
        HideSecurely(MainMenuBarBackpackButton)
    end
    if CharacterReagentBag0Slot then
        HideSecurely(CharacterReagentBag0Slot)
    end
    if BagBarExpandToggle then
        HideSecurely(BagBarExpandToggle)
    end

    self.applied.bagButtons = true
end











function FrameHider:HideCharacterFrame()
    if self.applied.characterFrame then return end
    if not PlayerFrame then return end

    PlayerFrame:UnregisterAllEvents()
    HideSecurely(PlayerFrame)

    self.applied.characterFrame = true
end

















function FrameHider:SetCastBarHidden(hidden)
    Cfg().hideCastBar = hidden
    self:RefreshCastBar()
end





function FrameHider:WantCastBar()
    
    
    
    local show = not (ThugUI:IsModuleOn("framehider") and Cfg().hideCastBar)
    if show and ThugUI.Visibility then
        show = ThugUI.Visibility:Alpha("castBar") > 0
    end
    return show
end










function FrameHider:RefreshCastBar()
    local CL = ThugUI.ControllerLayout
    local bars = CL and CL.CastBars and CL:CastBars()
    if not bars then
        local frame = PlayerCastingBarFrame
        if frame then bars = { frame } else return end
    end

    local show = self:WantCastBar()
    local last = self.applied.castBarShown
    if last == nil then last = true end
    if show == last then return end
    self.applied.castBarShown = show

    for _, frame in ipairs(bars) do
        if frame.SetAndUpdateShowCastbar then
            self.applied.castBarHooks = self.applied.castBarHooks or {}
            if not self.applied.castBarHooks[frame] then
                self.applied.castBarHooks[frame] = true
                
                
                local reasserting = false
                hooksecurefunc(frame, "SetAndUpdateShowCastbar", function(f, s)
                    if reasserting or not s or FrameHider:WantCastBar() then return end
                    reasserting = true
                    f:SetAndUpdateShowCastbar(false)
                    reasserting = false
                end)
            end
            frame:SetAndUpdateShowCastbar(show)
        elseif not show then
            
            
            frame:Hide()
        end
    end
end



























local SHARD_DEFAULT_WIDTH, SHARD_DEFAULT_HEIGHT = 250, 50

local function ShardFrames()
    return _G.ShardTransferImminentFrame, _G.ShardTransferImminentMinimizeButton
end

function FrameHider:GetShardMover()
    if self.shardMover then return self.shardMover end

    local mover = CreateFrame("Frame", "ThugUI_ShardNoticeMover", UIParent, "BackdropTemplate")
    mover:SetSize(SHARD_DEFAULT_WIDTH, SHARD_DEFAULT_HEIGHT)
    mover:SetFrameStrata("DIALOG")
    mover:SetClampedToScreen(true)
    mover:SetMovable(true)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    if mover.SetBackdrop then
        mover:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        mover:SetBackdropColor(0, 0, 0, 0.6)
        mover:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
    local label = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText("Server restart notice\n|cffffffffdrag to move|r")

    mover:SetScript("OnDragStart", function(m)
        if not InCombatLockdown() then m:StartMoving() end
    end)
    mover:SetScript("OnDragStop", function(m)
        m:StopMovingOrSizing()
        local left, top = m:GetLeft(), m:GetTop()
        if left and top then
            Cfg().shardNoticePoint = { x = left, y = top - UIParent:GetHeight() }
        end
        FrameHider:PlaceShardNotice()
    end)
    mover:Hide()

    self.shardMover = mover
    return mover
end




local function PositionMover(mover)
    mover:ClearAllPoints()
    local saved = Cfg().shardNoticePoint
    if saved and saved.x and saved.y then
        mover:SetPoint("TOPLEFT", UIParent, "TOPLEFT", saved.x, saved.y)
        return
    end
    local frame = ShardFrames()
    local left, top = frame and frame:GetLeft(), frame and frame:GetTop()
    if left and top then
        mover:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    else
        mover:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 60, 260)
    end
end

function FrameHider:PlaceShardNotice()
    local frame = ShardFrames()
    if not frame then return end
    local saved = Cfg().shardNoticePoint
    if not (saved and saved.x and saved.y) then return end
    local mover = self:GetShardMover()
    PositionMover(mover)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", mover, "TOPLEFT", 0, 0)
end

function FrameHider:SetShardNoticeUnlocked(unlocked)
    local mover = self:GetShardMover()
    if unlocked then
        PositionMover(mover)
        mover:Show()
    else
        mover:Hide()
    end
end

function FrameHider:ResetShardNoticePosition()
    Cfg().shardNoticePoint = nil
    if self.shardMover and self.shardMover:IsShown() then
        PositionMover(self.shardMover)
    end
end



function FrameHider:ApplyShardNotice()
    local frame, minimize = ShardFrames()
    if not frame then return end

    if not self.applied.shardHooks then
        self.applied.shardHooks = true
        frame:HookScript("OnShow", function(f)
            if Cfg().hideShardNotice then
                f:Hide()
            else
                FrameHider:PlaceShardNotice()
            end
        end)
        if minimize then
            minimize:HookScript("OnShow", function(m)
                if Cfg().hideShardNotice then m:Hide() end
            end)
        end
    end

    if Cfg().hideShardNotice then
        frame:Hide()
        if minimize then minimize:Hide() end
    else
        self:PlaceShardNotice()
    end
end





function FrameHider:ApplyAll()
    if Cfg().hideStanceBar then
        self:HideStanceBar()
    end
    if Cfg().hideBagButtons then
        self:HideBagButtons()
    end
    if Cfg().hideCharacterFrame then
        self:HideCharacterFrame()
    end
    if Cfg().hideCastBar then
        self:SetCastBarHidden(true)
    end
    self:MigrateTrackerFromAcorns()
    self:MigrateTrackerCombatFromAcorns()
    if Cfg().hideObjectiveTracker then
        self:SetObjectiveTrackerHidden(true)
    end
    
    
    if ThugUI.Visibility and not self.trackerRegistered then
        self.trackerRegistered = true
        ThugUI.Visibility:Register("objectives", function(alpha) FrameHider:ApplyTrackerVisibility(alpha) end)
    end
    self:ApplyTrackerVisibility()
    self:ApplyShardNotice()

    
    
    
    
    ThugUI_Config.movePreyCrystal = nil
    ThugUI_Config.preyCrystalPoint = nil
end



