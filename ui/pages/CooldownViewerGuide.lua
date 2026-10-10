

























ThugUI = ThugUI or {}

local CV = ThugUI.CooldownViewer
local W = ThugUI.Widgets

local Guide = {}
CV.BuffGuide = Guide

local MEDIA = "Interface\\AddOns\\ThugUI\\media\\"

local SHOTS = {
    options = {
        file = "blizzard_menu_with_gameplay_enhancements_highlighted",
        u = 1.0000, v = 0.7871, aspect = 1.270,
    },
    cdmOption = {
        file = "blizzard_menu_with_cooldown_manager_highlighted",
        u = 0.9980, v = 0.7871, aspect = 1.268,
    },
    
    
    
    escMenu = {
        file = "blizzard_escape_menu_with_edit_mode_highlighted",
        u = 0.5059, v = 1.0000, aspect = 0.506, scale = 0.56,
    },
    editModeTick = {
        file = "HUD_edit_mode_with_cooldown_manager_box_checked_and_highlighted",
        u = 0.8906, v = 1.0000, aspect = 0.891,
    },
    clickToEdit = {
        file = "buff_bar_with_click_to_edit_printed_on_bar",
        u = 0.3594, v = 0.1836, aspect = 1.957,
    },
    advArrow = {
        file = "HUD_edit_mode_with_arrow_to_advanced_options",
        u = 1.0000, v = 0.7227, aspect = 1.384,
    },
    advButton = {
        file = "Tracked_buff_settings_window_with_Advanced_Cooldown_Settings_button_highlighted",
        u = 0.7266, v = 1.0000, aspect = 0.727,
    },
    buffsTab = {
        file = "advanced_cooldown_settings_window_with_buffs_tab_highlighted_and_both_"
            .. "the_tracked_buffs_and_tracked_bars_areas_highlighted",
        u = 0.7305, v = 1.0000, aspect = 0.730,
    },
    visibility = {
        file = "tracked_buffs_settings_window_with_visibility_dropdown_highlighted_and_"
            .. "arrows_to_both_correct_options",
        u = 0.7227, v = 1.0000, aspect = 0.723,
    },
    asIcon = {
        file = "buff_as_icon_with_counter",
        u = 0.6094, v = 0.4883, aspect = 1.248,
    },
    asBar = {
        file = "buff_as_icon_with_timer_bar",
        u = 0.6992, v = 0.5352, aspect = 1.307,
    },
}















local STEPS = {
    {
        text = "|cffffd100Use Blizzard's buff frames|r -- the tick just above. It shows "
            .. "the setting as it stands, so make sure it is on. Everything below this "
            .. "happens in the game's own settings, not in ThugUI.",
    },
    {
        text = "|cffffd100Esc > Edit Mode.|r",
        shots = { "escMenu" },
        caption = "Edit Mode lives in the game menu",
    },
    {
        text = "|cffffd100Open Advanced Options|r, and make sure |cffffd100Cooldown "
            .. "Manager|r is ticked. The buff frames do not exist until it is.",
        shots = { "advArrow", "editModeTick" },
        caption = "Advanced Options, then the Cooldown Manager tick",
    },
    {
        text = "|cffffd100Click the buff bar|r to edit it, then |cffffd100Advanced "
            .. "Cooldown Settings|r.",
        shots = { "clickToEdit", "advButton" },
        caption = "Click the bar itself, then Advanced Cooldown Settings",
    },
    
    
    
    {
        text = "|cffffd100Set the frame's visibility|r to |cffffd100Always Show|r or "
            .. "|cffffd100In Combat|r, whichever option you like. The icon is pulled from "
            .. "this frame, so one that is never displayed has nothing to pull.",
        shots = { "visibility" },
        caption = "Either highlighted option works",
    },
    {
        text = "|cffffd100Buffs tab - drag the buff into Tracked Buffs or Tracked Bars.|r "
            .. "Either list works. ThugUI can only place a buff that is in one of them.",
        shots = { "buffsTab" },
        caption = "Both areas are highlighted. Drag any buff you want on the grid into one of them",
    },
    
    
    
    
    
    
    {
        text = "|cffffd100Done.|r The two |cffffd100Tracked Buffs|r or |cffffd100Tracked Bars|r areas render the buff in the cell in two "
            .. "different ways, exactly as the default UI draws it.",
        shots = { "asIcon", "asBar" },
        layout = "row",
        caption = "Tracked Buffs on the left, Tracked Bars on the right - both in one ThugUI cell",
    },
}



Guide.SHOTS = SHOTS
Guide.STEPS = STEPS

local PANEL_WIDTH = 260
local PANEL_INSET = 16
local SHOT_WIDTH  = 420   
local SHOT_GAP    = 8
local SHOT_PAD    = 12




local SHOT_STACK_GAP = 22




local CAPTION_WIDTH = 190
local CAPTION_PAD   = 10











function Guide:EnsurePopout()
    if self.popout then return self.popout end
    if not self.panel then return nil end

    local popout = CreateFrame("Frame", "ThugUI_BuffGuideShot", self.panel, "BackdropTemplate")
    
    
    popout:SetFrameStrata("DIALOG")
    popout:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    ThugUI.Theme:Paint(popout, "listBackground", "backdrop")
    ThugUI.Theme:Paint(popout, "listBorder", "border")
    popout:Hide()

    
    
    popout.shots = {}
    for i = 1, 2 do
        local tex = popout:CreateTexture(nil, "ARTWORK")
        tex:Hide()
        popout.shots[i] = tex
    end

    
    
    
    
    local box = CreateFrame("Frame", "ThugUI_BuffGuideCaption", popout, "BackdropTemplate")
    box:SetFrameStrata("DIALOG")
    box:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    ThugUI.Theme:Paint(box, "listBackground", "backdrop")
    ThugUI.Theme:Paint(box, "listBorder", "border")
    popout.captionBox = box

    
    
    
    
    
    
    
    
    ThugUI.Theme:Paint(box, "guideHighlight", "border")

    local glow = box:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", -4, 4)
    glow:SetPoint("BOTTOMRIGHT", 4, -4)
    ThugUI.Theme:Paint(glow, "guideGlow", "fill")
    glow:SetBlendMode("ADD")
    box.glow = glow

    
    
    
    box:SetScript("OnUpdate", function(self, elapsed)
        self.pulse = (self.pulse or 0) + (elapsed or 0)
        self.glow:SetAlpha(0.30 + 0.35 * math.abs(math.sin(self.pulse * 2.2)))
    end)

    local caption = ThugUI.Theme:Paint(box:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall")), "note")
    caption:SetPoint("TOPLEFT", box, "TOPLEFT", CAPTION_PAD, -CAPTION_PAD)
    caption:SetWidth(CAPTION_WIDTH - CAPTION_PAD * 2)
    caption:SetJustifyH("LEFT")
    popout.caption = caption

    self.popout = popout
    return popout
end

function Guide:HideShot()
    if self.popout then self.popout:Hide() end
end



function Guide:ShowShot(row, step)
    if not row or not step or not step.shots or #step.shots == 0 then
        self:HideShot()
        return
    end

    local popout = self:EnsurePopout()
    if not popout then return end

    
    
    
    local sideBySide = step.layout == "row" and #step.shots > 1
    local width = SHOT_WIDTH
    if sideBySide then
        width = (SHOT_WIDTH - SHOT_GAP * (#step.shots - 1)) / #step.shots
    end

    local y = -SHOT_PAD
    local x = SHOT_PAD
    local rowHeight = 0
    local contentWidth = 0

    for i, tex in ipairs(popout.shots) do
        local shot = step.shots[i] and SHOTS[step.shots[i] ]
        if shot then
            
            
            
            local shotWidth = width * (shot.scale or 1)
            local height = shotWidth / shot.aspect
            tex:SetTexture(MEDIA .. shot.file)
            
            
            tex:SetTexCoord(0, shot.u, 0, shot.v)
            tex:SetSize(shotWidth, height)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", popout, "TOPLEFT", x, y)
            tex:Show()

            if sideBySide then
                
                
                x = x + shotWidth + SHOT_GAP
                rowHeight = math.max(rowHeight, height)
                contentWidth = x - SHOT_GAP - SHOT_PAD
            else
                y = y - height - SHOT_STACK_GAP
                contentWidth = math.max(contentWidth, shotWidth)
            end
        else
            tex:Hide()
        end
    end

    if sideBySide then y = y - rowHeight - SHOT_GAP end

    
    
    
    local trailingGap = sideBySide and SHOT_GAP or SHOT_STACK_GAP
    popout:SetSize(contentWidth + SHOT_PAD * 2, -y - trailingGap + SHOT_PAD)

    
    
    local box = popout.captionBox
    popout.caption:SetText(step.caption or "")
    box:SetSize(CAPTION_WIDTH,
        popout.caption:GetStringHeight() + CAPTION_PAD * 2)
    box:ClearAllPoints()
    box:SetPoint("TOPRIGHT", popout, "TOPLEFT", -SHOT_GAP, 0)
    box:SetShown((step.caption or "") ~= "")
    
    
    
    
    
    popout:ClearAllPoints()
    popout:SetPoint("RIGHT", row, "LEFT", -8, 0)
    popout:Show()
end







function Guide:Ensure()
    if self.panel then return self.panel end

    local window = ThugUI.Window and ThugUI.Window.frame
    if not window then return nil end

    
    
    local panel = CreateFrame("Frame", "ThugUI_BuffGuidePanel", window, "BackdropTemplate")
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("cvGuide", function() return panel and panel:IsShown() end, function() Guide:Hide() end)
    end
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint("TOPLEFT", window, "TOPRIGHT", 0, 0)
    panel:SetPoint("BOTTOMLEFT", window, "BOTTOMRIGHT", 0, 0)
    panel:EnableMouse(true)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    ThugUI.Theme:Paint(panel, "background", "backdrop")
    panel:Hide()
    self.panel = panel

    local title = ThugUI.Theme:Paint(panel:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "section")
    title:SetPoint("TOPLEFT", PANEL_INSET, -16)
    
    
    title:SetText("|cff00ffccPROTECTED BUFF WORKAROUND|r")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() Guide:Hide() end)

    local intro = ThugUI.Theme:Paint(panel:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontDisable")), "note")
    intro:SetPoint("TOPLEFT", PANEL_INSET, -38)
    intro:SetWidth(PANEL_WIDTH - PANEL_INSET * 2)
    intro:SetJustifyH("LEFT")
    
    
    
    
    
    
    
    
    Guide.INTRO = "The buff icon in your cell is |cffffd100Blizzard's own|r. In combat "
        .. "the game will not tell an addon which aura is up, so ThugUI BORROWS "
        .. "Blizzard's buff frame and puts it in the cell you assigned.\n\n"
        .. "It has to have something to borrow. Until the buff is tracked in the "
        .. "|cffffd100Cooldown Manager|r the cell simply stays empty\n\n"
        .. "|cffffd100Buffs only.|r Everything else on the grid ThugUI draws itself, "
        .. "in combat, with nothing set up here."
    intro:SetText(Guide.INTRO)

    
    
    
    
    
    
    local useBlizzardBuffs = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    useBlizzardBuffs:SetSize(24, 24)
    useBlizzardBuffs:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -10)

    local cbLabel = ThugUI.Theme:Paint(useBlizzardBuffs:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall")), "label")
    cbLabel:SetPoint("LEFT", useBlizzardBuffs, "RIGHT", 4, 0)
    cbLabel:SetText("Use Blizzard's buff frames")

    useBlizzardBuffs:SetScript("OnClick", function(self)
        CV.Page:SetUseBlizzardBuffs(self:GetChecked() and true or false)
    end)

    
    
    
    function useBlizzardBuffs:Refresh()
        self:SetChecked(ThugUI_Config.cvUseBlizzardBuffs ~= false)
    end
    useBlizzardBuffs:Refresh()

    W.AttachTooltip(useBlizzardBuffs, "Use Blizzard's frames",
        "A buff cannot be drawn by an addon during combat: the game will not say which "
            .. "aura is up while you are fighting. With this on, Blizzard's own buff "
            .. "frame is placed in the cell you assigned it instead, so it works in "
            .. "combat.\n\n"
            .. "This covers buff cells, and any cell set to \"show always\" -- that mode "
            .. "has no readiness signal of its own but Blizzard's sweep. Spells with "
            .. "charges, items and ordinary cooldowns are unaffected: ThugUI draws all "
            .. "of those correctly in combat itself.\n\n"
            .. "Needs the Cooldown Manager turned on, with those buffs tracked in "
            .. "Edit Mode. Turn this off to go back to ThugUI's own icons, which only "
            .. "draw out of combat.")

    self.blizzBuffsCB = useBlizzardBuffs

    self.rows = {}
    local previous = useBlizzardBuffs

    for i, step in ipairs(STEPS) do
        local row = CreateFrame("Button", nil, panel)
        row:SetWidth(PANEL_WIDTH - PANEL_INSET * 2)
        row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -8)

        local number = ThugUI.Theme:Paint(row:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontNormalSmall")), "listTitle")
        number:SetPoint("TOPLEFT", 0, -1)
        number:SetWidth(16)
        number:SetJustifyH("LEFT")
        number:SetText(i .. ".")

        local text = ThugUI.Theme:Paint(row:CreateFontString(nil, "ARTWORK", ThugUI.Theme:Font("GameFontHighlightSmall")), "listItem")
        text:SetPoint("TOPLEFT", 18, 0)
        text:SetWidth(PANEL_WIDTH - PANEL_INSET * 2 - 18)
        text:SetJustifyH("LEFT")
        text:SetText(step.text)

        
        
        row:SetHeight(math.max(text:GetStringHeight() + 6, 18))
        row:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        row:SetScript("OnEnter", function(self) Guide:ShowShot(self, step) end)
        row:SetScript("OnLeave", function() Guide:HideShot() end)

        self.rows[i] = row
        previous = row
    end

    
    
    
    window:HookScript("OnHide", function() Guide:Hide() end)

    return panel
end

function Guide:IsShown()
    return (self.panel and self.panel:IsShown()) and true or false
end

function Guide:Show()
    if not ThugUI.CombatClose:Allow("cvGuide") then return end
    local panel = self:Ensure()
    if panel then panel:Show() end
    
    
    
    if self.blizzBuffsCB then self.blizzBuffsCB:Refresh() end
end

function Guide:Hide()
    self:HideShot()
    if self.panel then self.panel:Hide() end
end

function Guide:Toggle()
    if self:IsShown() then self:Hide() else self:Show() end
end





function Guide:CreateLink(panel)
    local host = panel.parent

    local link = CreateFrame("Button", nil, host)
    local label = ThugUI.Theme:Paint(link:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormal")), "link")
    label:SetPoint("LEFT", link, "LEFT", 0, 0)
    label:SetText("[WORKAROUND]")
    ThugUI.Theme:Paint(label, "link", "text")
    link:SetSize(label:GetStringWidth() + 6, 18)
    link:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    link:SetScript("OnEnter", function() ThugUI.Theme:Paint(label, "linkHover", "text") end)
    link:SetScript("OnLeave", function() ThugUI.Theme:Paint(label, "link", "text") end)
    link:SetScript("OnClick", function() Guide:Toggle() end)

    if W and W.AttachTooltip then
        W.AttachTooltip(link, "Buff workaround",
            "The settings this needs in Blizzard's own UI, step by step, with pictures. "
            .. "Opens beside this window.")
    end

    panel:Place(link, 22, { gap = 2, width = link:GetWidth() })
    return link
end

return Guide
