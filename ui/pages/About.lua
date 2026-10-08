



ThugUI = ThugUI or {}

local Page = {}
ThugUI.AboutPage = Page





local function Version()
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    if get then
        local ok, v = pcall(get, "ThugUI", "Version")
        if ok and v then return v end
    end
    return ThugUI.version or "?"
end

local function ModuleState(entry)
    local M = ThugUI.Modules
    if entry.soon then return "coming soon" end
    if M:Suspended(entry.id) then return "suspended by Controller" end
    return M:Stored(entry.id) and "on" or "off"
end



Page.COMMANDS = {
    { "/thugui", "Open this window; /thugui <page id> opens that page. Also /thug and /tui." },
    { "/acorn", "Acorns: lock, unlock, chat normal|stream|hide, obj, objcombat, font <size>, icon <chat|obj> <icon>, reset. Also /acorns." },
    { "/thugwheel", "Open or close the controller wheel." },
    { "/thugchat", "Open or close the controller chat window." },
    { "/thugport", "Cast your hearthstone through the wheel's travel button." },
    { "/thugprep dump", "Log how every bag consumable was sorted for Prep, and count each section." },
    { "/thugfish", "Create or update the ThugFish macro and put it on your cursor." },
    { "/thugcv", "Cooldown grids: legacy (swap to the old ECV/BCV/GCV bars and back), import [force], probe, rebuild, status." },
    { "/thugdebug", "Turn verbose debug logging on or off." },
    { "/thuglog", "Print the debug log." },
    { "/thugbcv", "Capture your buffs and probe Balance spells into ThugUI_BCVDump." },
    { "/thugspell <name or id>", "Probe one spell's ID and texture into ThugUI_BCVDump." },
}

Page.CREDITS = "Developed by Squirrelthug.\n"
    .. "Acorn artwork is CC0 from Wikimedia Commons."

Page.LINKS = {
    { text = "lastattempt.net", icon = "Interface\\AddOns\\ThugUI\\media\\social\\lastattempt.tga", url = "https://lastattempt.net" },
    { text = "Spotify", icon = "Interface\\AddOns\\ThugUI\\media\\social\\spotify.tga", url = "https://open.spotify.com/show/7DeyxVjwhWHW4K7UyLCiZT" },
    { text = "Apple Podcasts", icon = "Interface\\AddOns\\ThugUI\\media\\social\\apple.tga", url = "https://podcasts.apple.com/us/podcast/last-attempt-a-world-of-warcraft-guildcast/id1876268344" },
    { text = "YouTube", icon = "Interface\\AddOns\\ThugUI\\media\\social\\youtube.tga", url = "https://www.youtube.com/@LastAttemptPod" },
    { text = "Discord", icon = "Interface\\AddOns\\ThugUI\\media\\social\\discord.tga", url = "https://discord.gg/7hrBH5G7Hf" },
    { text = "Twitch", icon = "Interface\\AddOns\\ThugUI\\media\\social\\twitch.tga", url = "https://www.twitch.tv/squirrelthug_" },
    { text = "Instagram", icon = "Interface\\AddOns\\ThugUI\\media\\social\\instagram.tga", url = "https://www.instagram.com/lastattemptpod/" },
    { text = "X", icon = "Interface\\AddOns\\ThugUI\\media\\social\\x.tga", url = "https://x.com/LastAttemptPod" },
    { text = "TikTok", icon = "Interface\\AddOns\\ThugUI\\media\\social\\tiktok.tga", url = "https://www.tiktok.com/@lastattemptpod" },
}

StaticPopupDialogs["THUGUI_COPY_LINK"] = {
    text = "Copy the link (Ctrl+C), then paste it in your browser.",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 350,
    
    
    OnShow = function(self, data)
        local eb = (self.GetEditBox and self:GetEditBox()) or self.editBox
        if eb then
            eb:SetText(data or "")
            if eb.HighlightText then eb:HighlightText() end
            if eb.SetFocus then eb:SetFocus() end
        end
    end,
    OnAccept = function() end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function Page:Build(host, panel)
    panel:Header("ThugUI")
    panel:Note("A UI suite for retail and WoW Forever, one module at a time. Version " .. Version() .. ".")

    panel:Section("Modules")
    panel:Note("Turned on and off on the Modules page.")

    
    Page.moduleNotes = {}
    for _, entry in ipairs(ThugUI.Modules:Visible()) do
        panel:Label("|cffffffff" .. entry.title .. "|r")
        local note = panel:Note(entry.desc .. " (" .. ModuleState(entry) .. ")", { indent = 12 })
        Page.moduleNotes[#Page.moduleNotes + 1] = { entry = entry, note = note }
    end

    panel:Section("Minimap")

    panel:Checkbox{
        label = "Show the acorn on the minimap",
        tooltip = "Left-click opens this window, right-click lists its pages, "
            .. "drag moves it around the rim. /thugui always works without it.",
        get = function()
            return not (ThugUIDB and ThugUIDB.MinimapButton and ThugUIDB.MinimapButton.hidden)
        end,
        set = function(v)
            if ThugUI.MinimapButton then ThugUI.MinimapButton:SetShown(v) end
        end,
    }

    panel:Section("Commands")

    for _, command in ipairs(Page.COMMANDS) do
        panel:Label("|cff00ffcc" .. command[1] .. "|r")
        panel:Note(command[2], { indent = 12 })
    end

    panel:Section("Last Attempt")

    local logoFrame = CreateFrame("Frame", nil, panel.parent)
    logoFrame:SetSize(96, 96)
    local logoTex = logoFrame:CreateTexture(nil, "ARTWORK")
    logoTex:SetAllPoints()
    logoTex:SetTexture("Interface\\AddOns\\ThugUI\\media\\social\\lastattempt.tga")
    panel:Place(logoFrame, 96)

    panel:Label("Last Attempt Guildcast")
    panel:Note("Warcraft, discussed by people who actually play it. A weekly guildcast with written commentary on Retail and WoW Forever.")

    for _, link in ipairs(Page.LINKS) do
        local rowFrame = CreateFrame("Frame", nil, panel.parent)
        rowFrame:SetSize(panel.width, 32)

        local iconTex = rowFrame:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(32, 32)
        iconTex:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
        iconTex:SetTexture(link.icon)

        local btn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
        btn:SetSize(180, 24)
        btn:SetPoint("LEFT", iconTex, "RIGHT", 10, 0)
        btn:SetText(link.text)
        btn.labelText = link.text
        panel:Index(link.text, btn, "control")

        local urlCopy = link.url
        btn:SetScript("OnClick", function()
            StaticPopup_Show("THUGUI_COPY_LINK", nil, nil, urlCopy)
        end)

        panel:Place(rowFrame, 32)
    end

    panel:Section("Credits")

    panel:Note(Page.CREDITS)
end


function Page:Refresh(host)
    for _, row in ipairs(Page.moduleNotes or {}) do
        if row.note and row.note.SetText then
            row.note:SetText(row.entry.desc .. " (" .. ModuleState(row.entry) .. ")")
        end
    end
end

ThugUI.Window:RegisterPage{
    id = "about",
    category = "general",
    order = 30,
    summary = "Version and addon info.",
    title = "About",
    build = function(host, panel) Page:Build(host, panel) end,
    refresh = function(host) Page:Refresh(host) end,
}

return Page
