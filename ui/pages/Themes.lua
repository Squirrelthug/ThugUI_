









local ThugUI = _G.ThugUI
local T = ThugUI.Theme
local Page = {}
ThugUI.ThemesPage = Page

local function S() return T:Settings() end
local function BG() return S().background end
local function Apply() T:ApplySaved() end

local function Unpack3(c, r, g, b)
    if type(c) ~= "table" then return r, g, b end
    local res = T:Resolve(c)
    if not res then return r, g, b end
    return res[1], res[2], res[3]
end





local THUMB_W, THUMB_H, THUMB_GAP, PER_ROW = 148, 104, 10, 4

local function BuildGallery(panel)
    local entries = { { name = "No image (colour only)", file = "" } }
    for _, g in ipairs(T:GalleryAll()) do entries[#entries + 1] = g end
    local rows = math.ceil(#entries / PER_ROW)
    local holder = CreateFrame("Frame", nil, panel.parent)
    holder:SetSize(PER_ROW * (THUMB_W + THUMB_GAP), rows * (THUMB_H + 22 + THUMB_GAP))
    holder.thumbs = {}
    for i, e in ipairs(entries) do
        local col, row = (i - 1) % PER_ROW, math.floor((i - 1) / PER_ROW)
        local b = CreateFrame("Button", nil, holder)
        b:SetSize(THUMB_W, THUMB_H)
        b:SetPoint("TOPLEFT", holder, "TOPLEFT", col * (THUMB_W + THUMB_GAP), -row * (THUMB_H + 22 + THUMB_GAP))
        local sel = b:CreateTexture(nil, "BACKGROUND")
        sel:SetPoint("TOPLEFT", -3, 3)
        sel:SetPoint("BOTTOMRIGHT", 3, -3)
        T:Paint(sel, "accent", "fill")
        sel:Hide()
        b.selected = sel
        local img = b:CreateTexture(nil, "ARTWORK")
        img:SetAllPoints()
        if e.file ~= "" and e.file ~= nil then
            img:SetTexture(e.file)
            img:SetTexCoord(T.ImageCoords("cover", 4 / 3, THUMB_W, THUMB_H, 1, 0, 0))
        else
            T:Paint(img, "controlFill", "fill")
        end
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        T:Paint(hl, "controlHighlight", "fill")
        local name = T:Paint(b:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall")), "label")
        name:SetPoint("TOP", b, "BOTTOM", 0, -4)
        name:SetWidth(THUMB_W)
        name:SetText(e.name)
        b.file = e.file
        b.labelText = e.name
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        if e.pick then
            ThugUI.Widgets.AttachTooltip(b, e.name, "Your pick (from the asset browser). Right-click to remove it.")
        end
        b:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "RightButton" then
                if e.pick then T:RemoveGalleryImage(e.file) end
                return
            end
            local bg = BG()
            if e.file == "" or e.file == nil then
                bg.kind = "color"
            else
                bg.kind, bg.image, bg.aspect = "image", e.file, 4 / 3
            end
            Apply()
            Page:RefreshGallery()
            if panel.Refresh then panel:Refresh() end
        end)
        holder.thumbs[#holder.thumbs + 1] = b
        panel:Index(e.name, b, "control")
    end
    panel:Place(holder, holder:GetHeight(), { width = holder:GetWidth() })
    Page.gallery = holder
    Page:RefreshGallery()
end

function Page:RefreshGallery()
    local holder = self.gallery
    if not holder then return end
    local bg = BG()
    local current = bg.kind == "image" and bg.image or ""
    for _, b in ipairs(holder.thumbs) do b.selected:SetShown(b.file == current) end
end








local function UsePreset(panel, id)
    T:UsePreset(id)
    ThugUI.Window:ApplyWindowTheme()
    Page:RefreshGallery()
    Page:RefreshPresetTiles()
    panel:Refresh()
end

local function PresetTile(panel, holder, id, w, h)
    local p = T.presets[id]
    local b = CreateFrame("Button", nil, holder)
    b:SetSize(w, h)
    local sel = b:CreateTexture(nil, "BACKGROUND")
    sel:SetPoint("TOPLEFT", -3, 3)
    sel:SetPoint("BOTTOMRIGHT", 3, -3)
    T:Paint(sel, "accent", "fill")
    sel:Hide()
    b.selected = sel
    local face = b:CreateTexture(nil, "ARTWORK")
    face:SetAllPoints()
    local bg = p.background or {}
    if p.kind == "image" and bg.image then
        face:SetTexture(bg.image)
        face:SetTexCoord(T.ImageCoords("cover", 4 / 3, w, h, 1, 0, 0))
    else
        
        local c = T:Resolve(bg.color) or { 0.04, 0.04, 0.06 }
        face:SetColorTexture(c[1], c[2], c[3], 1) 
        local parts = { "partLayout", "partVisibility", "partAppearance", "partContent" }
        for i, role in ipairs(parts) do
            local spec = p.colors and p.colors[role]
            local pc = T:Resolve(spec) or { T:Color(role) }
            local sw = b:CreateTexture(nil, "OVERLAY")
            sw:SetSize((w - 16) / 4 - 2, 5)
            sw:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 8 + (i - 1) * ((w - 16) / 4), 6)
            sw:SetColorTexture(pc[1], pc[2], pc[3], 1) 
        end
    end
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    T:Paint(hl, "controlHighlight", "fill")
    local name = T:Paint(b:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall")), "label")
    if p.kind == "image" then
        name:SetPoint("TOP", b, "BOTTOM", 0, -4)
    else
        name:SetPoint("TOP", b, "TOP", 0, -8)
    end
    name:SetWidth(w - 8)
    name:SetText(p.name)
    b.id, b.labelText = id, p.name
    b:SetScript("OnClick", function() UsePreset(panel, id) end)
    panel:Index(p.name, b, "control")
    return b
end

local function TileGrid(panel, ids, w, h, perRow, gapY)
    local rows = math.ceil(#ids / perRow)
    local holder = CreateFrame("Frame", nil, panel.parent)
    holder:SetSize(perRow * (w + 10), rows * (h + gapY))
    for i, id in ipairs(ids) do
        local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
        local b = PresetTile(panel, holder, id, w, h)
        b:SetPoint("TOPLEFT", holder, "TOPLEFT", col * (w + 10), -row * (h + gapY))
        Page.presetTiles[#Page.presetTiles + 1] = b
    end
    panel:Place(holder, holder:GetHeight(), { width = holder:GetWidth() })
end




local SAVED_SLOTS = 8

local function SavedTile(panel, holder, i, w, h)
    local b = CreateFrame("Button", nil, holder)
    b:SetSize(w, h)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local sel = b:CreateTexture(nil, "BACKGROUND")
    sel:SetPoint("TOPLEFT", -3, 3)
    sel:SetPoint("BOTTOMRIGHT", 3, -3)
    T:Paint(sel, "accent", "fill")
    sel:Hide()
    b.selected = sel
    b.face = b:CreateTexture(nil, "ARTWORK")
    b.face:SetAllPoints()
    b.swatches = {}
    for k = 1, 4 do
        local sw = b:CreateTexture(nil, "OVERLAY")
        sw:SetSize((w - 16) / 4 - 2, 5)
        sw:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 8 + (k - 1) * ((w - 16) / 4), 6)
        b.swatches[k] = sw
    end
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    T:Paint(hl, "controlHighlight", "fill")
    b.label = T:Paint(b:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall")), "label")
    b.label:SetPoint("TOP", b, "TOP", 0, -8)
    b.label:SetWidth(w - 8)
    b:SetScript("OnClick", function(self, mouseButton)
        if not self.themeName then return end
        if mouseButton == "RightButton" then
            ThugUI.Dialog:Show("THUGUI_THEME_DELETE", self.themeName, nil, self.themeName)
            return
        end
        T:UseSavedTheme(self.themeName)
        ThugUI.Window:ApplyWindowTheme()
        Page:RefreshGallery()
        Page:RefreshPresetTiles()
        panel:Refresh()
    end)
    ThugUI.Widgets.AttachTooltip(b, "Your theme", "Click to use it. Right-click to delete it.")
    return b
end

function Page:RefreshSavedTiles()
    local names = T:SavedThemeNames()
    local current = S().savedTheme
    for i, b in ipairs(Page.savedTiles or {}) do
        local name = names[i]
        b.themeName = name
        if name then
            local t = T:SavedThemes()[name]
            local bg = T:Resolve(t.background and t.background.color) or { 0.04, 0.04, 0.06 }
            
            b.face:SetColorTexture(bg[1], bg[2], bg[3], 1) 
            local roles = T:BuildColors(t.preset, t.colors)
            for k, role in ipairs({ "partLayout", "partVisibility", "partAppearance", "partContent" }) do
                local c = roles[role] or { T:Color(role) }
                b.swatches[k]:SetColorTexture(c[1], c[2], c[3], 1) 
                b.swatches[k]:Show()
            end
            b.label:SetText(name)
            b.selected:SetShown(name == current)
            b:Show()
        else
            b:Hide()
        end
    end
    if Page.savedEmpty then Page.savedEmpty:SetShown(#names == 0) end
end

function Page:BuildSavedThemes(panel)
    panel:Group("Your themes")
    Page.savedEmpty = panel:Note("None yet. Make the window look the way you like, name it below and save it.")
    local w, h, perRow = 148, 46, 4
    local holder = CreateFrame("Frame", nil, panel.parent)
    holder:SetSize(perRow * (w + 10), math.ceil(SAVED_SLOTS / perRow) * (h + 10))
    Page.savedTiles = {}
    for i = 1, SAVED_SLOTS do
        local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
        local b = SavedTile(panel, holder, i, w, h)
        b:SetPoint("TOPLEFT", holder, "TOPLEFT", col * (w + 10), -row * (h + 10))
        Page.savedTiles[i] = b
    end
    panel:Place(holder, holder:GetHeight(), { width = holder:GetWidth() })
    panel:EditBox{
        label = "Theme name",
        width = 200,
        get = function() return Page.themeName or "" end,
        set = function(v) Page.themeName = v end,
        onTextChanged = function(v) Page.themeName = v end,
    }
    panel:Button{
        label = "Save current as theme",
        width = 200,
        tooltip = "Keeps the colours, background, border, tint and text size under this name, for every character.",
        onClick = function()
            local name = Page.themeName
            if type(name) ~= "string" or name:match("^%s*$") then
                print("|cffff0000ThugUI:|r give the theme a name first.")
                return
            end
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            if T:SavedThemes()[name] then
                ThugUI.Dialog:Show("THUGUI_THEME_OVERWRITE", name, nil, name)
                return
            end
            if #T:SavedThemeNames() >= SAVED_SLOTS then
                print("|cffff0000ThugUI:|r eight saved themes is the most; delete one first (right-click it).")
                return
            end
            T:SaveTheme(name)
            S().savedTheme = name
            Page:RefreshSavedTiles()
        end,
    }
    Page:RefreshSavedTiles()
end

ThugUI.Dialogs["THUGUI_THEME_OVERWRITE"] = {
    text = "A theme called %s already exists. Replace it with the current look?",
    button1 = "Replace",
    button2 = "Cancel",
    OnAccept = function(_, name)
        T:SaveTheme(name)
        S().savedTheme = name
        Page:RefreshSavedTiles()
    end,
}

ThugUI.Dialogs["THUGUI_THEME_DELETE"] = {
    text = "Delete your theme %s? The look you have now stays as it is.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(_, name)
        T:DeleteSavedTheme(name)
        Page:RefreshSavedTiles()
    end,
}

function Page:BuildPresetTiles(panel)
    Page:BuildSavedThemes(panel)
    Page.presetTiles = {}
    
    
    local ids = { color = {}, class = {}, image = {} }
    for _, id in ipairs(T.presetOrder) do
        local list = ids[T.presets[id].group or "color"] or ids.color
        list[#list + 1] = id
    end
    panel:Group("Colour themes")
    TileGrid(panel, ids.color, 148, 46, 4, 10)
    panel:Group("Class themes")
    TileGrid(panel, ids.class, 148, 96, 4, 28)
    panel:Group("Place themes")
    TileGrid(panel, ids.image, 148, 96, 4, 28)
    Page:RefreshPresetTiles()
end

function Page:RefreshPresetTiles()
    if Page.RefreshSavedTiles then Page:RefreshSavedTiles() end
    
    local current = (not S().savedTheme) and (S().preset or "default") or nil
    for _, b in ipairs(Page.presetTiles or {}) do b.selected:SetShown(b.id == current) end
end





local ROLE_GROUPS = {
    { "Page", {
        { "pageTitle", "Page title" }, { "pageContext", "Line under the title" },
        { "section", "Section headings" }, { "label", "Settings text (before the tint)" }, { "note", "Notes" },
        { "value", "Values (dropdowns, numbers)" } } },
    { "Separators", {
        { "partLayout", "Size & position" }, { "partVisibility", "Visibility" },
        { "partAppearance", "Appearance" }, { "partContent", "Content" }, { "group", "Named groups outside a separator" },
        { "ruleHeader", "Line under the header" }, { "ruleTabs", "Line under the tabs" },
        { "ruleSubTabs", "Line under nested tabs" } } },
    { "Sidebar", {
        { "navCategory", "Categories" }, { "navPage", "Pages (before the tint)" },
        { "navSelected", "Selected page" }, { "navAccent", "Selected marker" } } },
    { "Tabs", {
        { "tab", "Tabs" }, { "tabSelected", "Selected tab" }, { "subTab", "Nested tabs" },
        { "subTabSelected", "Selected nested tab" }, { "tabAccent", "Tab marker" } } },
    { "Window", {
        { "windowTitle", "Window title" }, { "headerLabel", "Header labels" }, { "accent", "Accent" },
        { "border", "Border tint" } } },
}

function Page:Build(host, panel)
    panel:Header("Themes")
    panel:Note("How this window looks. Start from a preset, then change any part of it. "
        .. "Changes show at once and are kept per scope, like any page.")

    
    panel:FrameSection{ title = "Presets" }
    panel:Note("Choose a theme to start from. It sets the colours, the background and the border "
        .. "together, and replaces your own colour changes.")
    Page:BuildPresetTiles(panel)
    panel:Note("Item quality uses the game's own rarity colours. Each class theme uses its class colour "
        .. "over its talent background. The place themes put a loading screen behind the window: "
        .. "Alliance and Horde in their faction colours, the dungeons and raids with colours drawn "
        .. "from popular code-editor themes.")
    panel:Button{
        label = "Reset to the preset",
        width = 180,
        tooltip = "Puts back the preset's colours, background and border.",
        onClick = function()
            UsePreset(panel, S().preset or "default")
        end,
    }

    
    panel:FrameSection{ title = "Background" }
    panel:SubSection("Gallery")
    panel:Note("Pick an image for the window's background, or none for a plain colour. "
        .. "Fit, opacity and dimming are on the Adjust tab.")
    BuildGallery(panel)

    panel:SubSection("Adjust")
    panel:Dropdown{
        label = "Background",
        options = { { text = "Colour", value = "color" }, { text = "Image", value = "image" } },
        get = function() return BG().kind end,
        set = function(v)
            BG().kind = v
            if v == "image" and (BG().image == nil or BG().image == "") and T.GALLERY and T.GALLERY[1] then
                BG().image = T.GALLERY[1].file
            end
            Apply()
            Page:RefreshGallery()
        end,
    }
    panel:Color{
        label = "Background colour",
        get = function() return Unpack3(BG().color, 0.04, 0.04, 0.06) end,
        set = function(r, g, b) BG().color = { r, g, b }; Apply() end,
    }
    panel:Slider{
        label = "Background opacity",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return tonumber(BG().alpha) or 0.96 end,
        set = function(v) BG().alpha = v; Apply() end,
    }
    panel:Group("Image")
    panel:Dropdown{
        label = "How the image fits",
        tooltip = "Cover fills the window and crops the edges; Fit shows the whole image with the colour around it; Stretch fills and distorts.",
        options = {
            { text = "Cover (crop to fill)", value = "cover" },
            { text = "Fit (whole image)", value = "fit" },
            { text = "Stretch", value = "stretch" },
        },
        get = function() return BG().mode or "cover" end,
        set = function(v) BG().mode = v; Apply() end,
    }
    panel:Slider{
        label = "Image opacity",
        min = 0, max = 1, step = 0.05, format = "%.2f",
        get = function() return tonumber(BG().imageAlpha) or 1 end,
        set = function(v) BG().imageAlpha = v; Apply() end,
    }
    panel:Slider{
        label = "Dim the image",
        tooltip = "A layer of the background colour over the image, so text stays readable. Higher is darker.",
        min = 0, max = 0.95, step = 0.05, format = "%.2f",
        get = function() return tonumber(BG().dim) or 0.7 end,
        set = function(v) BG().dim = v; Apply() end,
    }
    panel:Color{
        label = "Image tint",
        get = function() return Unpack3(BG().tint, 1, 1, 1) end,
        set = function(r, g, b) BG().tint = { r, g, b }; Apply() end,
    }
    panel:Slider{
        label = "Zoom",
        tooltip = "Cover only: crop further into the image.",
        min = 1, max = 2, step = 0.05, format = "%.2f",
        get = function() return tonumber(BG().zoom) or 1 end,
        set = function(v) BG().zoom = v; Apply() end,
    }
    panel:Slider{
        label = "Horizontal position",
        tooltip = "Cover only: which part of the cropped image shows, left to right.",
        min = -1, max = 1, step = 0.05, format = "%.2f",
        get = function() return tonumber(BG().offsetX) or 0 end,
        set = function(v) BG().offsetX = v; Apply() end,
    }
    panel:Slider{
        label = "Vertical position",
        tooltip = "Cover only: which part of the cropped image shows, bottom to top.",
        min = -1, max = 1, step = 0.05, format = "%.2f",
        get = function() return tonumber(BG().offsetY) or 0 end,
        set = function(v) BG().offsetY = v; Apply() end,
    }

    
    panel:FrameSection{ title = "Window" }
    panel:Checkbox{
        label = "Allow resizing",
        tooltip = "Shows a grip in the bottom-right corner: drag it to change the window's width and height. "
            .. "It cannot get smaller than the size the pages are laid out for.",
        get = function() return S().resizable == true end,
        set = function(v) S().resizable = v and true or false; ThugUI.Window:ApplyWindowTheme() end,
    }
    panel:Slider{
        label = "Window scale",
        tooltip = "Scales the whole window, text and all, evenly. Separate from the width and height the grip sets.",
        min = ThugUI.Window.MIN_SCALE, max = ThugUI.Window.MAX_SCALE, step = 0.05, format = "%.2f",
        get = function() return tonumber(S().windowScale) or 1 end,
        set = function(v) ThugUI.Window:SetWindowScale(v) end,
    }
    panel:Slider{
        label = "Text size",
        tooltip = "The size of all text in this window. Kept between 0.8 and 1.25 so rows do not crowd.",
        min = T.TEXT_MIN, max = T.TEXT_MAX, step = 0.05, format = "%.2f",
        get = function() return tonumber(S().textSize) or 1 end,
        set = function(v) S().textSize = v; T:SetTextScale(v) end,
    }
    local borders = {}
    for _, b in ipairs(T.BORDERS) do borders[#borders + 1] = { text = b.text, value = b.value } end
    panel:Dropdown{
        label = "Border", width = 220,
        options = borders,
        get = function() return S().border or "dialog" end,
        set = function(v) S().border = v; Apply() end,
    }

    
    panel:FrameSection{ title = "Text colours" }
    panel:Note("Every piece of text and every line in this window has a role, and each role has one "
        .. "colour, so a colour means the same thing on every page.")
    
    
    panel:Group("Taken from the colour above")
    local function ModSlider(key, label, tooltip, min, max)
        panel:Slider{
            label = label, tooltip = tooltip,
            min = min, max = max, step = 0.05, format = "%.2f",
            get = function() return T:BuildMods(S().preset, S())[key] end,
            set = function(v) S()[key] = v; Apply() end,
        }
    end
    ModSlider("textTint", "Text tint from separator",
        "How far settings text leans towards the colour of the separator above it (and sidebar pages towards "
            .. "their category). 0 keeps the plain text colour.", 0, 0.6)
    ModSlider("groupShade", "Nested separator shade",
        "Named groups under a separator (e.g. When to show under Visibility) are a shade of its colour: "
            .. "below 0 darker, above 0 lighter.", -0.8, 0.8)
    ModSlider("nestedShade", "Nested pages shade",
        "How much darker nested sidebar pages are than the pages above them.", 0, 0.8)
    for _, group in ipairs(ROLE_GROUPS) do
        panel:Group(group[1])
        for _, r in ipairs(group[2]) do
            local role = r[1]
            panel:Color{
                label = r[2],
                get = function() local cr, cg, cb = T:Color(role) return cr, cg, cb end,
                set = function(cr, cg, cb)
                    local _, _, _, a = T:Color(role)
                    S().colors[role] = { cr, cg, cb, a }
                    Apply()
                end,
            }
        end
    end
    panel:Button{
        label = "Reset text colours",
        width = 180,
        tooltip = "Back to the preset's colours.",
        onClick = function()
            S().colors = {}
            S().textTint, S().groupShade, S().nestedShade = nil, nil, nil
            Apply()
            panel:Refresh()
        end,
    }
end

ThugUI.Window:RegisterPage{
    id = "themes",
    category = "general",
    order = 15,
    title = "Themes",
    summary = "How this window looks: presets, background, size and colours.",
    scopeKeys = { "Theme" },
    build = function(host, panel) Page:Build(host, panel) end,
    refresh = function() Page:RefreshGallery(); Page:RefreshPresetTiles() end,
}

return Page
