






ThugUI_Config = ThugUI_Config or {}

ThugUI = ThugUI or {}
local ER = ThugUI.EssentialRings





function ER:InitializeSettings()
    if not ThugUI_Config then
        ThugUI_Config = {}
    end

    for key, value in pairs(ER.defaults) do
        if ThugUI_Config[key] == nil then
            ThugUI_Config[key] = value
        end
    end
end

function ER:GetConfig()
    return ThugUI_Config
end






function ER:ApplySettings()
    if ThugUI_Config.scale then
        ER:SetGroupScale(ThugUI_Config.scale)
    end

    if ThugUI_CursorFrame then
        ThugUI_CursorFrame:SetAlpha(ER:CursorAlpha())
    end

    
    if ER.GCDCooldownFrame then ER.GCDCooldownFrame:Hide() end
    if ER.GCDBackgroundFrame then ER.GCDBackgroundFrame:Hide() end
    if ER.CastFrame then ER.CastFrame:Hide() end
    if ER.CastBackgroundFrame then ER.CastBackgroundFrame:Hide() end
    if ThugUI_CursorFrame and ThugUI_CursorFrame.MainRing then ThugUI_CursorFrame.MainRing:Hide() end

    ER.enableGCD = false
    ER.enableCast = false

    local slots = {
        {config = ThugUI_Config.innerRing, size = 50},
        {config = ThugUI_Config.mainRing, size = 70},
        {config = ThugUI_Config.outerRing, size = 90},
    }

    for _, slot in ipairs(slots) do
        local ringType = slot.config
        local size = slot.size

        if ringType == "Main Ring" then
            if ThugUI_CursorFrame and ThugUI_CursorFrame.MainRing then
                ThugUI_CursorFrame.MainRing:SetSize(size, size)
                ThugUI_CursorFrame.MainRing:Show()
            end

        elseif ringType == "GCD" then
            if ER.GCDCooldownFrame then
                ER.GCDCooldownFrame:SetSize(size, size)
                ER.GCDCooldownFrame:Show()
                ER.enableGCD = true
            end
            if size == 70 and ER.GCDBackgroundFrame then
                ER.GCDBackgroundFrame:SetSize(size, size)
                ER.GCDBackgroundFrame:Show()
            end

        elseif ringType == "Cast" then
            if ER.CastFrame then
                ER.CastFrame:SetSize(size, size)
                ER.CastFrame:Show()
                ER.enableCast = true
            end
            if size == 70 and ER.CastBackgroundFrame then
                ER.CastBackgroundFrame:SetSize(size, size)
                ER.CastBackgroundFrame:Show()
            end
        end
    end

    
    
    
    
    
    
    
    
    
    
    
    
    local CAST_EVENTS = {
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
        
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_FAILED",
    }

    if ER.TrackerFrame then
        if ER.enableGCD then
            ER.TrackerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
        else
            ER.TrackerFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
        end

        for _, event in ipairs(CAST_EVENTS) do
            if ER.enableCast then
                ER.TrackerFrame:RegisterUnitEvent(event, "player")
            else
                ER.TrackerFrame:UnregisterEvent(event)
            end
        end
    end

    ER:UpdateRingColors()
    ER:UpdateVisibility()
    ER:UpdateReticle()

    
    
    if ThugUI.ResourceRing then
        ThugUI.ResourceRing:SyncGeometry()
        ThugUI.ResourceRing:Update()
    end
end
