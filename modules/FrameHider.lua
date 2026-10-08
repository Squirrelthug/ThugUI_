




ThugUI = ThugUI or {}
ThugUI_Config = ThugUI_Config or {}

local FrameHider = {}
ThugUI.FrameHider = FrameHider


FrameHider.applied = {}


















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
    ThugUI_Config.hideCastBar = hidden
    self:RefreshCastBar()
end





function FrameHider:WantCastBar()
    local show = not ThugUI_Config.hideCastBar
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
            ThugUI_Config.shardNoticePoint = { x = left, y = top - UIParent:GetHeight() }
        end
        FrameHider:PlaceShardNotice()
    end)
    mover:Hide()

    self.shardMover = mover
    return mover
end




local function PositionMover(mover)
    mover:ClearAllPoints()
    local saved = ThugUI_Config.shardNoticePoint
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
    local saved = ThugUI_Config.shardNoticePoint
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
    ThugUI_Config.shardNoticePoint = nil
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
            if ThugUI_Config.hideShardNotice then
                f:Hide()
            else
                FrameHider:PlaceShardNotice()
            end
        end)
        if minimize then
            minimize:HookScript("OnShow", function(m)
                if ThugUI_Config.hideShardNotice then m:Hide() end
            end)
        end
    end

    if ThugUI_Config.hideShardNotice then
        frame:Hide()
        if minimize then minimize:Hide() end
    else
        self:PlaceShardNotice()
    end
end





function FrameHider:ApplyAll()
    if ThugUI_Config.hideStanceBar then
        self:HideStanceBar()
    end
    if ThugUI_Config.hideBagButtons then
        self:HideBagButtons()
    end
    if ThugUI_Config.hideCharacterFrame then
        self:HideCharacterFrame()
    end
    if ThugUI_Config.hideCastBar then
        self:SetCastBarHidden(true)
    end
    self:ApplyShardNotice()

    
    
    
    
    ThugUI_Config.movePreyCrystal = nil
    ThugUI_Config.preyCrystalPoint = nil
end



