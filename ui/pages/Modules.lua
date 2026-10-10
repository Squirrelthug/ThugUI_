






ThugUI.Window:RegisterPage({
    id = "modules",
    category = "general",
    order = 1,
    title = "Modules",
    
    build = function(self, panel)
        self.panel = panel
        panel:Header("Modules")
        panel:Note("Turn whole features on or off. Changes take effect after a reload.")
        
        local statusRow = CreateFrame("Frame", nil, panel.parent)
        self.statusRow = statusRow
        local statusText = ThugUI.Theme:Paint(statusRow:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlight")), "label")
        statusText:SetPoint("LEFT", statusRow, "LEFT", 0, 0)
        self.statusText = statusText
        
        local reloadBtn = CreateFrame("Button", nil, statusRow, "UIPanelButtonTemplate")
        reloadBtn:SetSize(120, 26)
        reloadBtn:SetPoint("LEFT", statusText, "RIGHT", 10, 0)
        reloadBtn:SetText("Reload now")
        reloadBtn:SetScript("OnClick", function()
            if not InCombatLockdown() then
                ReloadUI()
            end
        end)
        self.reloadBtn = reloadBtn
        
        panel:Place(statusRow, 32)
        
        local M = ThugUI.Modules
        local registry = M:Visible()
        local gap = 12
        local tileHeight = 180
        local tileWidth = math.floor((panel.width - 24) / 3)
        
        local grid = CreateFrame("Frame", nil, panel.parent)
        grid:SetWidth(panel.width)
        self.tiles = {}
        
        self.separators = {}

        local currentY = 0
        
        for _, cat in ipairs(ThugUI.Window.categories) do
            local groupEntries = {}
            for _, entry in ipairs(registry) do
                local entryCat = entry.category or "general"
                if entryCat == cat.id then
                    table.insert(groupEntries, entry)
                end
            end
            
            if #groupEntries > 0 then
                local sep = CreateFrame("Frame", nil, grid)
                sep:SetSize(panel.width, 28)
                sep:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -currentY)
                
                local text = ThugUI.Theme:Paint(sep:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormalLarge")), "section")
                text:SetPoint("CENTER")
                text:SetText(cat.title)
                
                local leftLine = sep:CreateTexture(nil, "BACKGROUND")
                leftLine:SetHeight(1)
                ThugUI.Theme:Paint(leftLine, "ruleCategory", "fill")
                leftLine:SetPoint("LEFT", sep, "LEFT", 0, 0)
                leftLine:SetPoint("RIGHT", text, "LEFT", -12, 0)
                
                local rightLine = sep:CreateTexture(nil, "BACKGROUND")
                rightLine:SetHeight(1)
                ThugUI.Theme:Paint(rightLine, "ruleCategory", "fill")
                rightLine:SetPoint("LEFT", text, "RIGHT", 12, 0)
                rightLine:SetPoint("RIGHT", sep, "RIGHT", 0, 0)
                
                self.separators[#self.separators + 1] = { frame = sep, text = text, category = cat.id, y = currentY, count = #groupEntries }
                currentY = currentY + 28

                for i, entry in ipairs(groupEntries) do
                    local tile = CreateFrame("Button", nil, grid)
                    tile:SetSize(tileWidth, tileHeight)
                    
                    local row = math.floor((i - 1) / 3)
                    local col = (i - 1) % 3
                    tile:SetPoint("TOPLEFT", grid, "TOPLEFT", col * (tileWidth + gap), -(currentY + row * (tileHeight + gap)))
                    
                    local bg = tile:CreateTexture(nil, "BACKGROUND")
                    bg:SetAllPoints()
                    ThugUI.Theme:Paint(bg, "tileFill", "fill")
                    
                    local hl = tile:CreateTexture(nil, "HIGHLIGHT")
                    hl:SetAllPoints()
                    ThugUI.Theme:Paint(hl, "tileHighlight", "fill")
                    
                    local borderTop = tile:CreateTexture(nil, "BORDER")
                    borderTop:SetPoint("TOPLEFT")
                    borderTop:SetPoint("TOPRIGHT")
                    borderTop:SetHeight(2)
                    local borderBottom = tile:CreateTexture(nil, "BORDER")
                    borderBottom:SetPoint("BOTTOMLEFT")
                    borderBottom:SetPoint("BOTTOMRIGHT")
                    borderBottom:SetHeight(2)
                    local borderLeft = tile:CreateTexture(nil, "BORDER")
                    borderLeft:SetPoint("TOPLEFT")
                    borderLeft:SetPoint("BOTTOMLEFT")
                    borderLeft:SetWidth(2)
                    local borderRight = tile:CreateTexture(nil, "BORDER")
                    borderRight:SetPoint("TOPRIGHT")
                    borderRight:SetPoint("BOTTOMRIGHT")
                    borderRight:SetWidth(2)
                    tile.borders = { borderTop, borderBottom, borderLeft, borderRight }
                    
                    local icon = tile:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(72, 72)
                    icon:SetPoint("TOP", tile, "TOP", 0, -18)
                    icon:SetTexture(entry.icon)
                    tile.icon = icon
                    
                    local titleText = ThugUI.Theme:Paint(tile:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormalLarge")), "tileTitle")
                    titleText:SetPoint("TOP", icon, "BOTTOM", 0, -6)
                    titleText:SetText(entry.title)
                    
                    local descText = ThugUI.Theme:Paint(tile:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall")), "tileDescription")
                    descText:SetPoint("TOP", titleText, "BOTTOM", 0, -4)
                    descText:SetWidth(tileWidth - 20)
                    descText:SetJustifyH("CENTER")
                    descText:SetWordWrap(true)
                    descText:SetMaxLines(3)
                    descText:SetText(entry.desc)
                    
                    local stateLine = ThugUI.Theme:Paint(tile:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormalSmall")), "tileState")
                    stateLine:SetPoint("BOTTOM", tile, "BOTTOM", 0, 10)
                    tile.stateLine = stateLine
        
                    local soonText = ThugUI.Theme:Paint(tile:CreateFontString(nil, "ARTWORK", nil, 7), "tileSoonStamp")
                    soonText:SetPoint("CENTER", tile, "CENTER", 0, 0)
                    soonText:SetFont("Fonts\\FRIZQT__.TTF", 46, "THICKOUTLINE")
                    ThugUI.Theme:Paint(soonText, "tileSoonStamp", "text")
                    soonText:SetText("SOON\226\132\162")
                    if soonText.SetRotation then
                        pcall(soonText.SetRotation, soonText, math.rad(20))
                    end
                    tile.soonText = soonText
                    
                    tile.entry = entry
                    
                    tile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    tile:SetScript("OnClick", function(t, button)
                        if entry.soon then return end
                        if button == "RightButton" then
                            local pageId = entry.pages[1]
                            if not pageId then
                                print("ThugUI: " .. entry.title .. " has no settings page.")
                            elseif not ThugUI.Modules:PageOn(pageId) then
                                print("ThugUI: " .. entry.title .. " is not loaded. Turn it on and reload to see its settings.")
                            else
                                ThugUI.Window:SelectPage(pageId)
                            end
                        else
                            if entry.locked then return end
                            M:Set(entry.id, not M:Stored(entry.id))
                            ThugUI.Window.pagesByID.modules.refresh(self)
                            if ThugUI.Window.RebuildSidebar then ThugUI.Window:RebuildSidebar() end
                        end
                    end)
                    
                    tile:SetScript("OnEnter", function(t)
                        GameTooltip:SetOwner(t, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(entry.title)
                        GameTooltip:AddLine(entry.desc, 1, 1, 1, true)
                        if entry.soon then
                            GameTooltip:AddLine("Not available yet.", 0.6, 0.6, 0.6)
                            GameTooltip:Show()
                            return
                        end
                        local pageTitles = {}
                        for _, pageId in ipairs(entry.pages) do
                            local pDef = ThugUI.Window.pagesByID[pageId]
                            if pDef and pDef.title then
                                table.insert(pageTitles, pDef.title)
                            end
                        end
                        if #pageTitles > 0 then
                            GameTooltip:AddLine("Pages: " .. table.concat(pageTitles, ", "), 1, 0.82, 0, true)
                        end
                        if entry.locked then
                            GameTooltip:AddLine("A switch for this comes in a later update.", 0.45, 0.45, 0.55)
                        end
                        if entry.id == "controller" and entry.conflicts then
                            local conflictTitles = {}
                            if entry.conflicts then
                                for _, conflictId in ipairs(entry.conflicts) do
                                    local conflictEntry = M:Entry(conflictId)
                                    if conflictEntry then
                                        table.insert(conflictTitles, conflictEntry.title)
                                    end
                                end
                            end
                            if #conflictTitles > 0 then
                                GameTooltip:AddLine("Replaces: " .. table.concat(conflictTitles, ", "), 0.30, 0.60, 1.00, true)
                            end
                        end
                        if M:Suspended(entry.id) then
                            GameTooltip:AddLine("Off while controller mode is active. Back when you play with mouse and keyboard.", 0.30, 0.60, 1.00, true)
                        end
                        GameTooltip:AddLine("Left-click: turn on or off (needs a reload). Right-click: open its settings.", 0.6, 0.6, 0.6)
                        GameTooltip:Show()
                    end)
                    
                    tile:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                    
                    table.insert(self.tiles, tile)
                end
                
                local rows = math.ceil(#groupEntries / 3)
                currentY = currentY + rows * tileHeight + math.max(0, rows - 1) * gap + 24
            end
        end
        
        grid:SetHeight(currentY - 24)
        panel:Place(grid, grid:GetHeight())
    end,
    
    refresh = function(self)
        local M = ThugUI.Modules
        local pendingCount = M:PendingCount()
        
        
        
        
        if pendingCount == 0 then
            self.statusText:SetText("No changes pending.")
            self.reloadBtn:Disable()
        elseif pendingCount == 1 then
            self.statusText:SetText("1 change takes effect after a reload.")
            self.reloadBtn:Enable()
        else
            self.statusText:SetText(pendingCount .. " changes take effect after a reload.")
            self.reloadBtn:Enable()
        end
        
        for _, tile in ipairs(self.tiles) do
            local entry = tile.entry
            local stored = M:Stored(entry.id)
            local pending = M:Pending(entry.id)
            local suspended = M:Suspended(entry.id)
            
            
            local role
            if entry.soon then
                role = "tileSoon"
                tile.stateLine:SetText("Coming soon")
                tile.soonText:Show()
            else
                tile.soonText:Hide()
                if entry.locked then
                    role = "tileLocked"
                    tile.stateLine:SetText("Always on for now")
                elseif pending then
                    role = "tilePending"
                    if suspended and stored then
                        tile.stateLine:SetText("Suspended by Controller")
                    else
                        tile.stateLine:SetText(stored and "On after reload" or "Off after reload")
                    end
                elseif suspended and stored then
                    role = "tileSuspended"
                    tile.stateLine:SetText("Suspended by Controller")
                elseif stored then
                    role = "tileOn"
                    tile.stateLine:SetText("On")
                else
                    role = "tileOff"
                    tile.stateLine:SetText("Off")
                end
            end
            
            for _, border in ipairs(tile.borders) do
                ThugUI.Theme:Paint(border, role, "fill")
            end
            
            if entry.soon then
                tile.icon:SetDesaturated(true)
                tile.icon:SetAlpha(0.35)
            elseif not stored or (suspended and stored) then
                tile.icon:SetDesaturated(true)
                tile.icon:SetAlpha(0.5)
            else
                tile.icon:SetDesaturated(false)
                tile.icon:SetAlpha(1)
            end
        end
    end
})
