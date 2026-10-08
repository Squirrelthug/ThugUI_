
















ThugUI = ThugUI or {}

local Window = {}
ThugUI.Window = Window

local W  






local WINDOW_WIDTH   = 1040
local WINDOW_HEIGHT  = 720
local ROW_HEIGHT = 26  
local SIDEBAR_WIDTH  = 170
local HEADER_HEIGHT  = 44



Window.CONTENT_HEIGHT = WINDOW_HEIGHT - (HEADER_HEIGHT + 8) - 14

Window.pages = {}
Window.pagesByID = {}
Window.activePageID = nil




Window.categories = {}
Window.categoriesByID = {}
Window.collapsed = {}

function Window:RegisterCategory(def)
    assert(def and def.id and def.title and def.order)
    if self.categoriesByID[def.id] then return end
    self.categoriesByID[def.id] = def
    table.insert(self.categories, def)
    table.sort(self.categories, function(a, b) return a.order < b.order end)

    
    
    
    
    
    
    
    
    local OVERVIEW_ROW = 32
    self.pagesByID["cat:" .. def.id] = {
        id = "cat:" .. def.id,
        title = def.title,
        build = function(host, panel)
            panel:Header(def.title)
            local box = CreateFrame("Frame", nil, panel.parent)
            box:SetWidth(panel.width)
            box:SetHeight(math.max(#Window:VisiblePages(def.id), 1) * OVERVIEW_ROW)
            host.overviewBox = box
            host.overviewRows = {}
            host.overviewWidth = panel.width
            panel:Place(box, box:GetHeight())
        end,
        refresh = function(host)
            local box = host.overviewBox
            if not box then return end
            local pages = Window:VisiblePages(def.id)
            for i, page in ipairs(pages) do
                local row = host.overviewRows[i]
                if not row then
                    local btn = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
                    btn:SetSize(180, 24)
                    local note = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    note:SetPoint("LEFT", btn, "RIGHT", 12, 0)
                    note:SetWidth(host.overviewWidth - 200)
                    note:SetJustifyH("LEFT")
                    row = { btn = btn, note = note }
                    host.overviewRows[i] = row
                end
                row.btn:ClearAllPoints()
                row.btn:SetPoint("TOPLEFT", box, "TOPLEFT", 0, -(i - 1) * OVERVIEW_ROW)
                row.btn:SetText(page.title)
                row.btn:SetScript("OnClick", function() Window:SelectPage(page.id) end)
                row.page = page
                row.note:SetText(page.summary or "")
                row.btn:Show()
                row.note:Show()
            end
            for i = #pages + 1, #host.overviewRows do
                host.overviewRows[i].page = nil
                host.overviewRows[i].btn:Hide()
                host.overviewRows[i].note:Hide()
            end
            box:SetHeight(math.max(#pages, 1) * OVERVIEW_ROW)
        end,
    }
end





function Window:VisiblePages(catID)
    local list = {}
    for _, def in ipairs(self.pages) do
        if def.category == catID and not (ThugUI.Modules and not ThugUI.Modules:PageOn(def.id)) then
            list[#list + 1] = def
        end
    end
    return list
end

Window:RegisterCategory{ id = "general", title = "General", order = 1 }
Window:RegisterCategory{ id = "controller", title = "Controller", order = 2 }
Window:RegisterCategory{ id = "combat", title = "Combat HUD", order = 3 }
Window:RegisterCategory{ id = "ui", title = "UI", order = 3.5 }
Window:RegisterCategory{ id = "interface", title = "Interface", order = 4 }
Window:RegisterCategory{ id = "orbeffects", title = "Orb effects", order = 5 }














function Window:RegisterPage(def)
    assert(def and def.id and def.title and def.build, "ThugUI: bad page definition")
    if self.pagesByID[def.id] then return end

    def.order = def.order or 100
    def.category = def.category or "general"
    if not self.categoriesByID[def.category] then def.category = "general" end

    self.pagesByID[def.id] = def
    table.insert(self.pages, def)
    table.sort(self.pages, function(a, b)
        local catA = self.categoriesByID[a.category]
        local catB = self.categoriesByID[b.category]
        local catOrderA = catA and catA.order or 999
        local catOrderB = catB and catB.order or 999
        if catOrderA ~= catOrderB then return catOrderA < catOrderB end
        if a.order == b.order then return a.title < b.title end
        return a.order < b.order
    end)

    
    if self.frame then self:RebuildSidebar() end
end





local function CreateNavButton(parent, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(SIDEBAR_WIDTH - 20, 26)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.08)
    bg:Hide()
    btn.selectedBG = bg

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.10)

    local accent = btn:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(3)
    accent:SetColorTexture(0.0, 1.0, 0.8, 0.9)
    accent:Hide()
    btn.accent = accent

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 12, 0)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    btn.label = label

    function btn:SetSelected(selected)
        self.selectedBG:SetShown(selected)
        self.accent:SetShown(selected)
        if selected then
            self.label:SetTextColor(1, 1, 1)
        else
            self.label:SetTextColor(0.75, 0.75, 0.75)
        end
    end
    btn:SetSelected(false)

    return btn
end





function Window:CreateWindow()
    if self.frame then return self.frame end
    W = W or ThugUI.Widgets

    local f = CreateFrame("Frame", "ThugUI_ConfigWindow", UIParent, "BackdropTemplate")
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("settings", function() return f:IsShown() end, function() Window:Close() end)
    end
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetBackdropColor(0.04, 0.04, 0.06, 0.96)

    
    tinsert(UISpecialFrames, "ThugUI_ConfigWindow")

    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -16)
    title:SetText("|cff00ffccThugUI|r")

    local version = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    version:SetPoint("LEFT", title, "RIGHT", 8, -1)
    version:SetText("v" .. (ThugUI.version or "1.0.0"))

    local headerRule = f:CreateTexture(nil, "ARTWORK")
    headerRule:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    headerRule:SetHeight(1)
    headerRule:SetPoint("TOPLEFT", 14, -HEADER_HEIGHT)
    headerRule:SetPoint("TOPRIGHT", -14, -HEADER_HEIGHT)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    
    
    
    
    
    close:SetScript("OnClick", function() Window:Close() end)

    
    
    
    
    
    
    
    
    
    
    
    
    local search = CreateFrame("EditBox", "ThugUI_ConfigSearch", f, "SearchBoxTemplate")
    search:SetSize(220, 22)
    search:SetPoint("RIGHT", close, "LEFT", -44, 0)
    search:SetScript("OnTextChanged", function(self, userInput)
        
        
        
        if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
        Window:OnSearchChanged(self:GetText())
    end)
    search:SetScript("OnEscapePressed", function(self)
        
        
        
        
        if SearchBoxTemplate_ClearText then
            SearchBoxTemplate_ClearText(self)
        else
            self:SetText("")
            self:ClearFocus()
        end
    end)
    f.searchBox = search

    
    local scopeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scopeLabel:SetText("Scope")
    scopeLabel:SetPoint("RIGHT", search, "LEFT", -180, 0)
    f.scopeLabel = scopeLabel

    local scopeDropdown = W.CreateDropdown(f, 160, function()
        return {
            { text = ThugUI.Profiles:ScopeLabel("shared"), value = "shared" },
            { text = ThugUI.Profiles:ScopeLabel("faction"), value = "faction" },
            { text = ThugUI.Profiles:ScopeLabel("character"), value = "character" },
        }
    end, function()
        local def = Window.pagesByID[Window.activePageID]
        if def and def.scopeKeys then
            return ThugUI.Profiles:ScopeOf(def.scopeKeys[1])
        end
        return "shared"
    end, function(val)
        local def = Window.pagesByID[Window.activePageID]
        if not def or not def.scopeKeys then return end
        
        if val == "shared" then
            StaticPopup_Show("THUGUI_SCOPE_SHARED", nil, nil, def.scopeKeys)
        else
            for _, key in ipairs(def.scopeKeys) do
                local ok, err = ThugUI.Profiles:SetScope(key, val)
                if not ok and err == "unresolved" then
                    print("ThugUI: your faction is not known yet; try again after login.")
                end
            end
            if f.scopeDropdown then
                f.scopeDropdown:Refresh()
            end
        end
    end)
    scopeDropdown:SetPoint("LEFT", scopeLabel, "RIGHT", 8, -1)
    W.AttachTooltip(scopeDropdown, "Scope", "Shared settings apply to every character on this profile. Faction or character keeps your own copy of this page, for example a layout that fits the other faction's bar art.")
    f.scopeDropdown = scopeDropdown

    
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", 14, -(HEADER_HEIGHT + 8))
    sidebar:SetPoint("BOTTOMLEFT", 14, 14)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    f.sidebar = sidebar

    
    
    
    
    local sidebarScroll = CreateFrame("ScrollFrame", nil, sidebar)
    sidebarScroll:SetAllPoints(sidebar)
    local sidebarList = CreateFrame("Frame", nil, sidebarScroll)
    sidebarList:SetSize(SIDEBAR_WIDTH, 1)
    sidebarScroll:SetScrollChild(sidebarList)
    sidebarScroll:EnableMouseWheel(true)
    sidebarScroll:SetScript("OnMouseWheel", function(_, delta)
        Window:ScrollSidebar(-delta * ROW_HEIGHT * 2)
    end)
    f.sidebarScroll, f.sidebarList = sidebarScroll, sidebarList

    local sidebarRule = f:CreateTexture(nil, "ARTWORK")
    sidebarRule:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    sidebarRule:SetWidth(1)
    sidebarRule:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 6, 0)
    sidebarRule:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 6, 0)

    
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 14, 0)
    content:SetPoint("BOTTOMRIGHT", -14, 14)
    f.content = content

    self.frame = f
    self:RebuildSidebar()
    return f
end

function Window:RebuildSidebar()
    local f = self.frame
    if not f then return end

    f.navButtons = f.navButtons or {}
    f.categoryButtons = f.categoryButtons or {}
    for _, btn in pairs(f.navButtons) do btn:Hide() end
    for _, btn in pairs(f.categoryButtons) do btn:Hide() end

    local row = 0
    for _, cat in ipairs(self.categories) do
        
        
        local visible = self:VisiblePages(cat.id)
        if #visible > 0 then
        local catBtn = f.categoryButtons[cat.id]
        if not catBtn then
            catBtn = CreateFrame("Button", nil, f.sidebarList)
            catBtn:SetSize(150, 26) 
            
            local bg = catBtn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(1, 1, 1, 0.08)
            bg:Hide()
            catBtn.selectedBG = bg

            local hl = catBtn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.10)

            local glyphBtn = CreateFrame("Button", nil, catBtn)
            glyphBtn:SetSize(20, 26)
            glyphBtn:SetPoint("LEFT", 0, 0)
            local glyph = glyphBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            glyph:SetPoint("LEFT", 4, 0)
            catBtn.glyph = glyph
            catBtn.toggle = glyphBtn  
            
            glyphBtn:SetScript("OnClick", function()
                Window.collapsed[cat.id] = not Window.collapsed[cat.id]
                Window:RebuildSidebar()
            end)

            local label = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", 20, 0)
            label:SetJustifyH("LEFT")
            catBtn.label = label
            
            catBtn:SetScript("OnClick", function()
                Window.collapsed[cat.id] = false
                Window:SelectPage("cat:" .. cat.id)
                Window:RebuildSidebar()
            end)

            function catBtn:SetSelected(selected)
                self.selectedBG:SetShown(selected)
            end

            f.categoryButtons[cat.id] = catBtn
        end
        
        local isCollapsed = Window.collapsed[cat.id]
        if isCollapsed == nil then
            isCollapsed = false
            Window.collapsed[cat.id] = false
        end

        catBtn.glyph:SetText(isCollapsed and "+" or "-")
        catBtn.label:SetText(cat.title)
        catBtn:ClearAllPoints()
        catBtn:SetPoint("TOPLEFT", f.sidebarList, "TOPLEFT", 10, -(row * ROW_HEIGHT))
        catBtn:SetSelected(self.activePageID == "cat:" .. cat.id)
        catBtn:Show()
        row = row + 1

        if not isCollapsed then
            for _, def in ipairs(visible) do
                do
                    local btn = f.navButtons[def.id]
                    if not btn then
                        btn = CreateNavButton(f.sidebarList, def.title)
                        btn:SetScript("OnClick", function()
                            Window:SelectPage(def.id)
                        end)
                        f.navButtons[def.id] = btn
                    end
                    btn.label:SetText(def.title)
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", f.sidebarList, "TOPLEFT", 22, -(row * ROW_HEIGHT))
                    btn:SetSelected(def.id == self.activePageID)
                    btn:Show()
                    row = row + 1
                end
            end
        end
        end
    end

    f.sidebarRows = row
    f.sidebarList:SetHeight(math.max(row * ROW_HEIGHT, 1))
    self:ScrollSidebar(0)
end


function Window:SidebarRange()
    local f = self.frame
    if not f then return 0 end
    local visible = f.sidebarScroll:GetHeight() or 0
    if visible <= 0 then visible = Window.CONTENT_HEIGHT end
    return math.max(0, (f.sidebarRows or 0) * ROW_HEIGHT - visible)
end




function Window:ScrollSidebar(by)
    local f = self.frame
    if not f then return end
    local cur = f.sidebarScroll:GetVerticalScroll() or 0
    local target = math.min(math.max(cur + (by or 0), 0), self:SidebarRange())
    f.sidebarScroll:SetVerticalScroll(target)
end





















local TAB_HEIGHT = 22
local TAB_GAP = 4

local function CreateTabButton(parent, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(TAB_HEIGHT)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.05)

    local sel = btn:CreateTexture(nil, "BORDER")
    sel:SetAllPoints()
    sel:SetColorTexture(1, 1, 1, 0.12)
    sel:Hide()
    btn.selectedBG = sel

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)

    
    local accent = btn:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT")
    accent:SetPoint("BOTTOMRIGHT")
    accent:SetHeight(2)
    accent:SetColorTexture(0.0, 1.0, 0.8, 0.9)
    accent:Hide()
    btn.accent = accent

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(text)
    btn.label = label
    btn.labelText = text
    btn:SetWidth((label:GetStringWidth() or 60) + 24)

    function btn:SetSelected(selected)
        self.selectedBG:SetShown(selected)
        self.accent:SetShown(selected)
        if selected then
            self.label:SetTextColor(1, 0.82, 0)
        else
            self.label:SetTextColor(0.75, 0.75, 0.75)
        end
    end
    btn:SetSelected(false)
    return btn
end




function Window:SelectTab(def, index)
    local tabs = def.tabList
    if not tabs or not tabs[index] then return end
    for i, tab in ipairs(tabs) do
        tab.scroll:SetShown(i == index)
        tab.button:SetSelected(i == index)
    end
    def.activeTab = index
    def.host = tabs[index].host
    def.scrollFrame = tabs[index].scroll
end

function Window:BuildTabbedPage(def, container)
    local contentW = self.frame.content:GetWidth()
    local childW = contentW - 34
    local panelWidth = childW - 32

    
    
    
    
    local preamble = CreateFrame("Frame", nil, container)
    preamble:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -4)
    preamble:SetSize(childW, 1)

    local tabBar = CreateFrame("Frame", nil, container)
    tabBar:SetSize(childW, TAB_HEIGHT)
    tabBar:Hide()
    def.tabBar = tabBar

    local panel = W.NewPanel(preamble, { width = panelWidth })
    def.panel = panel
    def.host = preamble

    local tabs = {}
    def.tabList = tabs
    local preambleH = 0

    panel.tabHandler = function(p, title)
        if #tabs == 0 then
            
            preambleH = (p.cursorY < p.originY) and p:GetHeight() or 0
        else
            tabs[#tabs].height = p:GetHeight()
        end
        local scroll, child = W.CreateScrollArea(container)
        child:SetWidth(childW)
        scroll:Hide()
        local tab = { title = title, scroll = scroll, host = child, index = #tabs + 1 }
        tab.button = CreateTabButton(tabBar, title)
        tab.button:SetScript("OnClick", function() Window:SelectTab(def, tab.index) end)
        tabs[#tabs + 1] = tab

        
        p.parent = child
        p.cursorY, p.rowTopY = p.originY, p.originY
        p.lastX, p.lastW = p.originX, 0
        p.openCheckboxPair = false
        p.partIndex = nil
        p.currentTab = tab
        return tab
    end

    def.build(preamble, panel)
    panel.tabHandler = nil

    local fullH = self.frame.content:GetHeight()
    if #tabs == 0 then
        local scroll = W.CreateScrollArea(container)
        preamble:SetParent(scroll)
        preamble:ClearAllPoints()
        scroll:SetScrollChild(preamble)
        preamble:SetHeight(math.max(panel:GetHeight(), fullH))
        def.scrollFrame = scroll
        return container
    end
    tabs[#tabs].height = panel:GetHeight()

    
    local top = 4
    preamble:SetHeight(math.max(preambleH, 1))
    if preambleH > 0 then
        top = top + preambleH
        preamble:Show()
    else
        preamble:Hide()
    end

    
    local x, row = 16, 0
    for _, tab in ipairs(tabs) do
        local w = tab.button:GetWidth()
        if x > 16 and x + w > childW - 16 then
            x, row = 16, row + 1
        end
        tab.button:ClearAllPoints()
        tab.button:SetPoint("TOPLEFT", tabBar, "TOPLEFT", x, -(row * (TAB_HEIGHT + TAB_GAP)))
        x = x + w + TAB_GAP
    end
    local barH = (row + 1) * (TAB_HEIGHT + TAB_GAP)
    tabBar:SetHeight(barH)
    tabBar:ClearAllPoints()
    tabBar:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -top)
    tabBar:Show()
    top = top + barH

    local rule = container:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -top)
    rule:SetPoint("TOPRIGHT", container, "TOPRIGHT", -4, -top)
    top = top + 4

    for _, tab in ipairs(tabs) do
        tab.scroll:ClearAllPoints()
        tab.scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -top)
        tab.scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -28, 4)
        tab.host:SetHeight(math.max(tab.height, fullH - top))
    end

    self:SelectTab(def, def.activeTab or 1)
    return container
end

function Window:BuildPage(def)
    if def.container then return def.container end
    W = W or ThugUI.Widgets

    local container = CreateFrame("Frame", nil, self.frame.content)
    container:SetAllPoints()
    container:Hide()
    def.container = container

    if def.scroll ~= false and def.tabs ~= false and not def.id:match("^cat:") then
        return self:BuildTabbedPage(def, container)
    end

    local host, panelWidth
    if def.scroll == false then
        host = container
        panelWidth = self.frame.content:GetWidth() - 32
    else
        local scroll, scrollContent = W.CreateScrollArea(container)
        
        scrollContent:SetWidth(self.frame.content:GetWidth() - 34)
        def.scrollFrame = scroll
        host = scrollContent
        panelWidth = scrollContent:GetWidth() - 32
    end
    def.host = host

    local panel = W.NewPanel(host, { width = panelWidth })
    def.panel = panel

    def.build(host, panel)

    if def.scroll ~= false then
        
        
        
        
        
        
        local tallest = panel:GetHeight()
        for _, p in ipairs(host.__thugPanels or {}) do
            if p:GetHeight() > tallest then tallest = p:GetHeight() end
        end
        host:SetHeight(math.max(tallest, self.frame.content:GetHeight()))
    end

    return container
end

function Window:SelectPage(id)
    if ThugUI.Modules and not ThugUI.Modules:PageOn(id) then
        id = "modules"
    end
    local def = self.pagesByID[id]
    if not def then return end

    self:CreateWindow()

    
    
    if def.category then
        self.collapsed[def.category] = false
    end
    if id:match("^cat:") then
        local cid = id:sub(5)
        self.collapsed[cid] = false
    end

    
    
    
    
    if self.resultsContainer and self.resultsContainer:IsShown() then
        self.searchPreviousPageID = nil
        self.resultsContainer:Hide()
        for _, btn in pairs(self.frame.navButtons or {}) do btn:SetAlpha(1) end
        for _, btn in pairs(self.frame.categoryButtons or {}) do btn:SetAlpha(1) end
        if self.frame.searchBox then self.frame.searchBox:SetText("") end
    end

    for _, other in ipairs(self.pages) do
        if other.container and other.id ~= id then
            other.container:Hide()
        end
    end
    for k, other in pairs(self.pagesByID) do
        if k:match("^cat:") and other.container and k ~= id then
            other.container:Hide()
        end
    end

    self:BuildPage(def)
    self.activePageID = id

    if self.frame.scopeDropdown and self.frame.scopeLabel then
        if def.scopeKeys then
            self.frame.scopeDropdown:Show()
            self.frame.scopeLabel:Show()
            self.frame.scopeDropdown:Refresh()
        else
            self.frame.scopeDropdown:Hide()
            self.frame.scopeLabel:Hide()
        end
    end

    
    
    if def.panel then def.panel:Refresh() end
    if def.refresh then def.refresh(def.host, def.panel) end

    def.container:Show()
    
    
    self:RebuildSidebar()
end





function Window:Open(pageID)
    if not ThugUI.CombatClose:Allow("settings") then return end
    self:CreateWindow()
    self:SelectPage(pageID or self.activePageID or (self.pages[1] and self.pages[1].id))
    self.frame:Show()
end

function Window:Close()
    if self.frame then self.frame:Hide() end
end

function Window:Toggle(pageID)
    self:CreateWindow()
    if self.frame:IsShown() and not pageID then
        self.frame:Hide()
    else
        if not ThugUI.CombatClose:Allow("settings") then return end
        self:Open(pageID)
    end
end



function Window:RefreshActivePage()
    if not self.frame or not self.frame:IsShown() then return end
    local def = self.pagesByID[self.activePageID]
    if not def or not def.container then return end
    if def.panel then def.panel:Refresh() end
    if def.refresh then def.refresh(def.host, def.panel) end
end












local RESULTS_CAP = 50
local RESULT_ROW_HEIGHT = 36






function Window:BuildAllPages()
    self:CreateWindow()
    for _, def in ipairs(self.pages) do
        self:BuildPage(def)
    end
end









function Window:Search(text)
    local results = {}

    local words = {}
    for word in (text or ""):lower():gmatch("%S+") do
        table.insert(words, word)
    end
    if #words == 0 then return results end

    local function MatchesAll(haystack)
        for _, word in ipairs(words) do
            if not haystack:find(word, 1, true) then return false end
        end
        return true
    end

    for _, def in ipairs(self.pages) do
        if not (ThugUI.Modules and not ThugUI.Modules:PageOn(def.id)) then
            if #results >= RESULTS_CAP then break end
            local title = def.title or ""
            if MatchesAll(title:lower()) then
                table.insert(results, {
                    pageID = def.id, pageTitle = title, section = nil,
                    text = title, frame = nil, kind = "page",
                })
            end
        end
    end

    for _, def in ipairs(self.pages) do
        if not (ThugUI.Modules and not ThugUI.Modules:PageOn(def.id)) then
            if #results >= RESULTS_CAP then break end
            local panels = (def.host and def.host.__thugPanels) or { def.panel }
            for _, panel in ipairs(panels) do
                if #results >= RESULTS_CAP then break end
                for _, entry in ipairs((panel and panel.searchIndex) or {}) do
                    if #results >= RESULTS_CAP then break end
                    local haystack = ((def.title or "") .. " " .. (entry.section or "") .. " " .. entry.text):lower()
                    if MatchesAll(haystack) then
                        table.insert(results, {
                            pageID = def.id, pageTitle = def.title, section = entry.section,
                            text = entry.text, frame = entry.frame, kind = entry.kind,
                            tab = entry.tab,
                        })
                    end
                end
            end
        end
    end

    return results
end






function Window:EnsureResultsView()
    if self.resultsContainer then return end
    W = W or ThugUI.Widgets

    local container = CreateFrame("Frame", nil, self.frame.content)
    container:SetAllPoints()
    container:Hide()
    self.resultsContainer = container

    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 16, -14)
    self.resultsHeader = header

    local scroll, scrollContent = W.CreateScrollArea(container)
    scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -36)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    scrollContent:SetWidth(self.frame.content:GetWidth() - 34)
    self.resultsScroll = scroll
    self.resultsList = scrollContent
    self.resultsRows = {}
end

function Window:GetResultRow(i)
    local row = self.resultsRows[i]
    if row then return row end

    row = CreateFrame("Button", nil, self.resultsList)
    row:SetPoint("TOPLEFT", self.resultsList, "TOPLEFT", 0, -((i - 1) * RESULT_ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", self.resultsList, "TOPRIGHT", 0, -((i - 1) * RESULT_ROW_HEIGHT))
    row:SetHeight(RESULT_ROW_HEIGHT)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 4, -4)
    label:SetJustifyH("LEFT")
    row.label = label

    local subtitle = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    subtitle:SetJustifyH("LEFT")
    row.subtitle = subtitle

    row:SetScript("OnClick", function()
        if row.result then Window:JumpTo(row.result) end
    end)

    self.resultsRows[i] = row
    return row
end



function Window:ShowResults(results)
    self:EnsureResultsView()

    self.resultsHeader:SetText(#results > 0 and "Search results" or "Nothing found")

    for i, result in ipairs(results) do
        local row = self:GetResultRow(i)
        row.result = result
        if result.kind == "page" then
            row.label:SetText("Open page: " .. result.pageTitle)
            row.subtitle:SetText("")
        else
            row.label:SetText(result.text)
            if result.section and result.section ~= "" then
                row.subtitle:SetText(result.pageTitle .. " \226\128\186 " .. result.section)
            else
                row.subtitle:SetText(result.pageTitle)
            end
        end
        row:Show()
    end
    for i = #results + 1, #self.resultsRows do
        self.resultsRows[i]:Hide()
    end

    self.resultsList:SetHeight(math.max(#results, 1) * RESULT_ROW_HEIGHT)
    self.resultsContainer:Show()
end







function Window:OnSearchChanged(text)
    local trimmed = (text or ""):match("^%s*(.-)%s*$")

    if trimmed == "" then
        if self.resultsContainer then self.resultsContainer:Hide() end
        local restoreID = self.searchPreviousPageID or self.activePageID
        self.searchPreviousPageID = nil
        if restoreID then
            local def = self.pagesByID[restoreID]
            if def and def.container then def.container:Show() end
            self.activePageID = restoreID
        end
        for _, btn in pairs(self.frame.navButtons or {}) do btn:SetAlpha(1) end
        for _, btn in pairs(self.frame.categoryButtons or {}) do btn:SetAlpha(1) end
        return
    end

    
    
    if not self.searchPreviousPageID then
        self.searchPreviousPageID = self.activePageID
    end

    self:BuildAllPages()

    local active = self.pagesByID[self.activePageID]
    if active and active.container then active.container:Hide() end

    local results = self:Search(trimmed)
    self:ShowResults(results)

    local matched = {}
    local matchedCat = {}
    for _, r in ipairs(results) do 
        matched[r.pageID] = true
        local pdef = self.pagesByID[r.pageID]
        if pdef and pdef.category then
            matchedCat[pdef.category] = true
        end
    end
    for pageID, btn in pairs(self.frame.navButtons or {}) do
        btn:SetAlpha(matched[pageID] and 1 or 0.4)
    end
    for catID, btn in pairs(self.frame.categoryButtons or {}) do
        btn:SetAlpha(matchedCat[catID] and 1 or 0.4)
    end
end






function Window:OutlineFrame(target, hostFrame)
    if not self.searchOutline then
        local outline = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
        outline:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
        outline:SetBackdropBorderColor(1, 0.82, 0, 1)
        outline:Hide()
        self.searchOutline = outline
    end

    local outline = self.searchOutline
    outline:SetParent(hostFrame or self.frame)
    outline:ClearAllPoints()
    local w = (type(target.GetWidth) == "function" and target:GetWidth() or 100) + 4
    local h = (type(target.GetHeight) == "function" and target:GetHeight() or 100) + 4
    outline:SetSize(w, h)
    outline:SetPoint("CENTER", target, "CENTER", 0, 0)
    
    local base = hostFrame and type(hostFrame.GetFrameLevel) == "function" and hostFrame:GetFrameLevel()
    if type(base) == "number" then outline:SetFrameLevel(base + 20) end
    outline:Show()

    
    
    
    self.searchOutlineToken = (self.searchOutlineToken or 0) + 1
    local token = self.searchOutlineToken
    C_Timer.After(1.5, function()
        if Window.searchOutlineToken == token then
            outline:Hide()
        end
    end)
end




function Window:JumpTo(result)
    if self.frame and self.frame.searchBox then
        self.frame.searchBox:SetText("")
    end

    self:SelectPage(result.pageID)

    local def = self.pagesByID[result.pageID]
    
    
    if def and result.tab and result.tab.index then
        self:SelectTab(def, result.tab.index)
    end
    if result.frame and def and def.scrollFrame then
        local hostTop = def.host and type(def.host.GetTop) == "function" and def.host:GetTop()
        local frameTop = type(result.frame.GetTop) == "function" and result.frame:GetTop()
        if type(hostTop) == "number" and type(frameTop) == "number" then
            local target = math.max(0, (hostTop - frameTop) - 40)
            local range = type(def.scrollFrame.GetVerticalScrollRange) == "function"
                and def.scrollFrame:GetVerticalScrollRange()
            if type(range) == "number" then
                target = math.min(target, range)
            end
            def.scrollFrame:SetVerticalScroll(target)
        end
    end

    if result.frame then
        self:OutlineFrame(result.frame, def and def.host)
    end
end





StaticPopupDialogs["THUGUI_SCOPE_SHARED"] = {
    text = "Go back to the shared settings for this page?",
    button1 = "Use shared",
    button2 = "Cancel",
    button3 = "Make mine shared",
    OnAccept = function(self, data)
        for _, key in ipairs(data) do ThugUI.Profiles:SetScope(key, "shared", "discard") end
        if ThugUI.Window.frame and ThugUI.Window.frame.scopeDropdown then ThugUI.Window.frame.scopeDropdown:Refresh() end
    end,
    OnAlt = function(self, data)
        for _, key in ipairs(data) do ThugUI.Profiles:SetScope(key, "shared", "promote") end
        if ThugUI.Window.frame and ThugUI.Window.frame.scopeDropdown then ThugUI.Window.frame.scopeDropdown:Refresh() end
    end,
    OnCancel = function(self, data)
        if ThugUI.Window.frame and ThugUI.Window.frame.scopeDropdown then ThugUI.Window.frame.scopeDropdown:Refresh() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function ThugUI:ToggleOptions(pageID)
    Window:Toggle(pageID)
end

return Window
