



ThugUI = ThugUI or {}

local function DeepCopyTable(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = DeepCopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function GetMinimapControllerTable()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.MinimapPanel = ThugUIDB.MinimapPanel or {}
    return ThugUIDB.MinimapPanel
end

local function GetMinimapMouseTable()
    ThugUIDB = ThugUIDB or {}
    if ThugUIDB.MinimapMouse == nil then
        local seed = DeepCopyTable(ThugUI.defaults and ThugUI.defaults.MinimapPanel or {})
        if type(ThugUIDB.MinimapPanel) == "table" then
            for k, v in pairs(ThugUIDB.MinimapPanel) do
                seed[k] = DeepCopyTable(v)
            end
        end
        ThugUIDB.MinimapMouse = seed
    end
    return ThugUIDB.MinimapMouse
end

local function RegisterMinimapPage(opts)
    local targetMode = opts.targetMode
    local visKey = opts.visKey
    local getCfg = opts.getCfg
    local pageId = opts.id
    local category = opts.category

    local Page = {}

    local function Apply()
        if ThugUI.minimapMode == targetMode and ThugUI.MinimapPanel then
            ThugUI.MinimapPanel:ApplySettings()
        end
    end

    function Page:Build(host, panel)
        panel:Header("Minimap")
        panel:Note("Take over the minimap. Hides Blizzard's cluster elements around it "
            .. "and keeps the border. Addon buttons and Blizzard's icons go in one popup. "
            .. "Edit Mode's minimap entry no longer moves the map.")

        if ThugUI.minimapMode ~= targetMode then
            local modeName = (targetMode == "controller" and "controller mode" or "Minimap (mouse)")
            panel:Note("Note: These settings apply when " .. modeName .. " is active. "
                .. "Changes made here will take effect on the next load in that mode.")
        end

        panel:Section("Window")

        panel:Checkbox{
            label = "Take over the minimap",
            tooltip = "Applies on the next /reload.",
            get = function() return getCfg().enabled end,
            set = function(v) getCfg().enabled = v end,
        }

        panel:Checkbox{
            label = "Unlocked (drag to move)",
            get = function() return getCfg().unlocked end,
            set = function(v) getCfg().unlocked = v; Apply() end,
        }

        panel:Slider{
            label = "Scale",
            min = 0.5, max = 2.5, step = 0.05,
            get = function() return getCfg().scale or 1 end,
            set = function(v) getCfg().scale = v; Apply() end,
        }

        if ThugUI.Visibility then
            panel:Section("Visibility")
            ThugUI.Visibility:AddControls(panel, visKey)
        end

        panel:Checkbox{
            label = "Show the day/night ring",
            get = function() return getCfg().showDiel end,
            set = function(v) getCfg().showDiel = v; Apply() end,
        }

        panel:Slider{
            label = "Zone name height",
            tooltip = "How far above the top of the map the zone name sits. "
                .. "Negative values move it down onto the map.",
            min = -40, max = 60, step = 1, format = "%d",
            get = function() return getCfg().zoneTextOffset or 4 end,
            set = function(v)
                getCfg().zoneTextOffset = v
                if ThugUI.minimapMode == targetMode and ThugUI.MinimapPanel then
                    ThugUI.MinimapPanel:PlaceZoneText()
                end
            end,
        }

        
        if targetMode == "controller" and not (ThugUI.moduleOn and ThugUI.moduleOn.focusedquest == false) then
            panel:Slider{
                label = "Focused quest height",
                tooltip = "How far above the zone name the focused quest (controller mode) sits. "
                    .. "Only while it is at its default place above the minimap.",
                min = -40, max = 120, step = 1, format = "%d",
                get = function()
                    return ThugUIDB.FocusedQuest and ThugUIDB.FocusedQuest.heightOffset or 4
                end,
                set = function(v)
                    ThugUIDB.FocusedQuest = ThugUIDB.FocusedQuest or { enabled = true }
                    ThugUIDB.FocusedQuest.heightOffset = v
                    local FQ = ThugUI.modules and ThugUI.modules.FocusedQuest
                    if FQ and FQ.ApplySettings then FQ:ApplySettings() end
                end,
            }

            panel:Checkbox{
                label = "Unlock focused quest (drag to move)",
                tooltip = "Shows a box where the focused quest text goes. Drag it anywhere, then untick. "
                    .. "Reset puts it back above the minimap.",
                get = function()
                    local FQ = ThugUI.modules and ThugUI.modules.FocusedQuest
                    return FQ and FQ.unlocked
                end,
                set = function(v)
                    local FQ = ThugUI.modules and ThugUI.modules.FocusedQuest
                    if FQ and FQ.SetUnlocked then FQ:SetUnlocked(v) end
                end,
            }

            panel:Button{
                label = "Reset focused quest",
                onClick = function()
                    local FQ = ThugUI.modules and ThugUI.modules.FocusedQuest
                    if FQ and FQ.ResetPosition then FQ:ResetPosition() end
                end,
            }
        end

        panel:Slider{
            label = "Popup columns",
            min = 2, max = 8, step = 1, format = "%d",
            get = function() return getCfg().popupColumns or 4 end,
            set = function(v) getCfg().popupColumns = v; Apply() end,
        }

        panel:Button{
            label = "Reset position",
            onClick = function()
                local c = getCfg()
                c.point = nil
                Apply()
            end,
        }

        panel:Section("Collected Addon Buttons")
        panel:Note("Uncheck to hide a button from the popup.")

        self.addonListHost = CreateFrame("Frame", nil, panel.parent)
        panel:Place(self.addonListHost, 1, { width = panel.width })
        self.listTopY = panel.rowTopY
        self.panel = panel
    end

    function Page:Refresh(host, panel)
        local C = getCfg()
        C.hidden = C.hidden or {}
        local MP = ThugUI.MinimapPanel

        self.rows = self.rows or {}
        for _, r in ipairs(self.rows) do
            r:Hide()
        end

        local buttons = MP and MP:GetCollectedButtons() or {}
        table.sort(buttons, function(a, b) return (a:GetName() or "") < (b:GetName() or "") end)

        local yOffset = 0
        for i, btn in ipairs(buttons) do
            local name = btn:GetName()
            if name then
                local row = self.rows[i]
                if not row then
                    row = CreateFrame("CheckButton", nil, self.addonListHost, "UICheckButtonTemplate")
                    row:SetSize(24, 24)
                    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    text:SetPoint("LEFT", row, "RIGHT", 4, 0)
                    row.labelText = text
                    self.rows[i] = row
                end

                row:SetPoint("TOPLEFT", 10, -yOffset)
                row.labelText:SetText(name)
                row:SetChecked(not C.hidden[name])
                row:SetScript("OnClick", function(selfWidget)
                    local checked = selfWidget:GetChecked()
                    C.hidden[name] = not checked
                    if ThugUI.minimapMode == targetMode and MP then MP:RefreshPopup() end
                end)
                row:Show()
                yOffset = yOffset + 26
            end
        end

        local newHeight = math.max(1, yOffset)
        self.addonListHost:SetHeight(newHeight)

        local body = self.addonListHost:GetParent()
        local totalHeight = math.abs(self.listTopY or self.panel.cursorY) + newHeight + 20
        if body:GetHeight() < totalHeight then
            body:SetHeight(totalHeight)
        end
    end

    ThugUI.Window:RegisterPage{
        id = pageId,
        category = category,
        order = opts.order or 60,
        scopeKeys = opts.scopeKeys,
        summary = opts.summary,
        title = "Minimap",
        build = function(host, panel) Page:Build(host, panel) end,
        refresh = function(host, panel) Page:Refresh(host, panel) end,
    }
end

RegisterMinimapPage{
    id = "minimap",
    category = "controller",
    order = 60,
    scopeKeys = { "MinimapPanel" },
    summary = "The minimap window, its popup and collected addon buttons.",
    targetMode = "controller",
    visKey = "minimap",
    getCfg = GetMinimapControllerTable,
}

RegisterMinimapPage{
    id = "minimapmouse",
    category = "interface",
    order = 65,
    scopeKeys = { "MinimapMouse" },
    summary = "The minimap window for mouse play, its popup and collected addon buttons.",
    targetMode = "mouse",
    visKey = "minimapMouse",
    getCfg = GetMinimapMouseTable,
}
