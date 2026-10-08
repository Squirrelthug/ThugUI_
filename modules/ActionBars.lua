







ThugUI = ThugUI or {}

local AB = {}
ThugUI.ActionBars = AB






AB.BARS = {
    { key = "MainActionBar",       label = "Action Bar 1 (main)" },
    { key = "MultiBarBottomLeft",  label = "Action Bar 2", setting = "PROXY_SHOW_ACTIONBAR_2" },
    { key = "MultiBarBottomRight", label = "Action Bar 3", setting = "PROXY_SHOW_ACTIONBAR_3" },
    { key = "MultiBarRight",       label = "Action Bar 4", setting = "PROXY_SHOW_ACTIONBAR_4" },
    { key = "MultiBarLeft",        label = "Action Bar 5", setting = "PROXY_SHOW_ACTIONBAR_5" },
    { key = "MultiBar5",           label = "Action Bar 6", setting = "PROXY_SHOW_ACTIONBAR_6" },
    { key = "MultiBar6",           label = "Action Bar 7", setting = "PROXY_SHOW_ACTIONBAR_7" },
    { key = "MultiBar7",           label = "Action Bar 8", setting = "PROXY_SHOW_ACTIONBAR_8" },
}



local state = {}




local textTouched = setmetatable({}, { __mode = "k" })





local TEXT_REGIONS = {
    { key = "HotKey", option = "hideHotkey" },
    { key = "Name",   option = "hideMacroName" },
    { key = "Count",  option = "hideCount" },
}



local function ApplyButtonText(button, cfg, force)
    for _, region in ipairs(TEXT_REGIONS) do
        local fs = button[region.key]
        if type(fs) == "table" then
            local hide = (not force) and cfg[region.option] == true
            local touched = textTouched[button]
            if hide then
                fs:SetAlpha(0)
                textTouched[button] = textTouched[button] or {}
                textTouched[button][region.key] = true
            elseif touched and touched[region.key] then
                fs:SetAlpha(1)
                touched[region.key] = nil
            end
        end
    end
end
AB.ApplyButtonText = ApplyButtonText



local parked = setmetatable({}, { __mode = "k" })
local hiddenParent










local function ParkContainer(container, park, bar)
    if park then
        if parked[container] then return end
        if not hiddenParent then
            hiddenParent = CreateFrame("Frame", nil, UIParent)
            hiddenParent:Hide()
        end
        parked[container] = container:GetParent() or bar
        container:SetParent(hiddenParent)
    elseif parked[container] then
        container:SetParent(parked[container])
        parked[container] = nil
    end
end
AB.ParkContainer = ParkContainer



local function BarButtons(bar, key)
    if type(bar.actionButtons) == "table" and #bar.actionButtons == 12 then
        return bar.actionButtons
    end
    local buttons = {}
    for i = 1, 12 do
        buttons[i] = _G[key .. "Button" .. i]
    end
    return buttons
end




local function HideDividers(bar)
    for _, poolName in ipairs({ "HorizontalDividersPool", "VerticalDividersPool" }) do
        local pool = bar[poolName]
        if type(pool) == "table" and pool.EnumerateActive then
            for divider in pool:EnumerateActive() do
                divider:Hide()
            end
        end
    end
end

function AB.BarInfo(key)
    for _, bar in ipairs(AB.BARS) do
        if bar.key == key then return bar end
    end
    return nil
end




function AB.IsBarEnabled(key)
    local info = AB.BarInfo(key)
    if not info then return nil end
    if not info.setting then return true end
    if not (Settings and Settings.GetValue) then return nil end
    local ok, value = pcall(Settings.GetValue, info.setting)
    if not ok then return nil end
    return value and true or false
end





function AB:SetBarEnabled(key, enabled)
    local info = AB.BarInfo(key)
    if not info or not info.setting then return false end
    if not (Settings and Settings.SetValue) then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("ACTIONBARS", "Settings.SetValue missing; cannot enable %s", key)
        end
        return false
    end
    if InCombatLockdown() then
        state[key] = state[key] or {}
        state[key].pendingEnable = enabled and true or false
        return false
    end
    local ok, err = pcall(Settings.SetValue, info.setting, enabled and true or false)
    if not ok then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("ACTIONBARS", "Settings.SetValue(%s) refused: %s", info.setting, tostring(err))
        end
        return false
    end
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("ACTIONBARS", "%s %s via %s", key, enabled and "enabled" or "disabled", info.setting)
    end
    
    
    if enabled then self:ApplyLayout(key) end
    return true
end







function AB.ShownCount(cfg)
    return math.max(1, math.min(12, cfg.numButtons or 12))
end






function AB.ComputeLayout(cfg)
    local n = AB.ShownCount(cfg)
    local step = cfg.buttonSize + cfg.spacing
    local perLine = math.max(1, math.min(12, cfg.perLine or 12))
    local lines = math.ceil(n / perLine)

    local layout = {}

    for p = 1, n do
        local line = math.floor((p - 1) / perLine)
        local slot = (p - 1) % perLine

        local x, y
        if cfg.vertical then
            x = line * step
            y = slot * step
        else
            x = slot * step
            y = line * step
        end

        local index = cfg.reverse and (n + 1 - p) or p

        layout[p] = {
            index = index,
            x = x,
            y = y,
        }
    end

    
    local w, h
    if cfg.vertical then
        w = lines * cfg.buttonSize + (lines - 1) * cfg.spacing
        h = math.min(n, perLine) * cfg.buttonSize + (math.min(n, perLine) - 1) * cfg.spacing
    else
        w = math.min(n, perLine) * cfg.buttonSize + (math.min(n, perLine) - 1) * cfg.spacing
        h = lines * cfg.buttonSize + (lines - 1) * cfg.spacing
    end

    return layout, w, h
end





function AB:ApplyLayout(key)
    if not key then return end

    local cfg = ThugUIDB.ActionBars and ThugUIDB.ActionBars.bars and ThugUIDB.ActionBars.bars[key]
    if not cfg or not cfg.managed then
        return
    end

    if InCombatLockdown() then
        state[key] = state[key] or {}
        state[key].pending = true
        return
    end

    local bar = _G[key]
    if not bar then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("ACTIONBARS", "bar %q not found", key)
        end
        return
    end

    local buttons = BarButtons(bar, key)

    
    local layout, w, h = self.ComputeLayout(cfg)

    
    local s = cfg.buttonSize / 45
    local shown = AB.ShownCount(cfg)
    for position = 1, shown do
        local buttonIndex = layout[position].index
        local button = buttons[buttonIndex]
        if not button then break end

        local container = button.container or button:GetParent()
        if not container then break end
        ParkContainer(container, false, bar)
        container:Show()

        local x = layout[position].x
        local y = layout[position].y

        
        
        
        
        
        
        container:SetScale(s)
        container:ClearAllPoints()
        container:SetPoint("TOPLEFT", bar, "TOPLEFT", x / s, -y / s)
    end

    
    
    
    
    for i = shown + 1, 12 do
        local button = buttons[i]
        local container = button and (button.container or button:GetParent())
        if container then
            ParkContainer(container, true, bar)
            container:Hide()
        end
    end

    
    
    for i = 1, 12 do
        if buttons[i] then ApplyButtonText(buttons[i], cfg, false) end
    end

    
    bar:SetSize(w, h)

    
    if key == "MainActionBar" then
        if type(bar.BorderArt) == "table" then bar.BorderArt:Hide() end
        if type(bar.EndCaps) == "table" then bar.EndCaps:Hide() end
        HideDividers(bar)

        
        if type(bar.UpdateEndCaps) == "function" then
            if not state[key] then state[key] = {} end
            if not state[key].endCapsHooked then
                hooksecurefunc(bar, "UpdateEndCaps", function()
                    if type(bar.BorderArt) == "table" then bar.BorderArt:Hide() end
                    if type(bar.EndCaps) == "table" then bar.EndCaps:Hide() end
                end)
                state[key].endCapsHooked = true
            end
        end

        
        if type(bar.UpdateDividers) == "function" then
            if not state[key] then state[key] = {} end
            if not state[key].dividersHooked then
                hooksecurefunc(bar, "UpdateDividers", function()
                    HideDividers(bar)
                end)
                state[key].dividersHooked = true
            end
        end
    end

    
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("ACTIONBARS", "applied layout to %s: %d x %d", key, w, h)
    end
end





function AB:ApplyPageLock(key)
    if not key then return end

    local cfg = ThugUIDB.ActionBars and ThugUIDB.ActionBars.bars and ThugUIDB.ActionBars.bars[key]
    if not cfg then return end

    if InCombatLockdown() then
        state[key] = state[key] or {}
        state[key].pendingLock = true
        return
    end

    local bar = _G[key]
    if not bar then return end

    local buttons = BarButtons(bar, key)

    
    local homePage
    if key == "MainActionBar" then
        homePage = 1
    else
        homePage = bar:GetAttribute("actionpage")
        if not homePage then
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("ACTIONBARS", "bar %q has no actionpage attribute, lock skipped", key)
            end
            return
        end
    end

    
    if cfg.lockPage then
        for i = 1, 12 do
            if buttons[i] then
                buttons[i]:SetAttribute("actionpage", homePage)
            end
        end
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("ACTIONBARS", "locked %s to page %d", key, homePage)
        end
    else
        for i = 1, 12 do
            if buttons[i] then
                buttons[i]:SetAttribute("actionpage", nil)
            end
        end
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("ACTIONBARS", "unlocked %s", key)
        end
    end

    
    
    
    
    
    
    if not (C_ActionBar and C_ActionBar.ForceUpdateAction) then return end
    local currentPage = (C_ActionBar.GetActionBarPage and C_ActionBar.GetActionBarPage()) or 1

    for _, page in ipairs({ homePage, currentPage }) do
        for i = 1, 12 do
            local slot = (page - 1) * 12 + i
            local ok, err = pcall(C_ActionBar.ForceUpdateAction, slot)
            if not ok then
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("ACTIONBARS", "ForceUpdateAction(%d) refused: %s", slot, tostring(err))
                end
                return
            end
        end
    end
end





function AB:SetManaged(key, managed)
    if not key then return end

    local cfg = ThugUIDB.ActionBars and ThugUIDB.ActionBars.bars and ThugUIDB.ActionBars.bars[key]
    if not cfg then return end

    cfg.managed = managed

    if managed then
        self:ApplyLayout(key)
    else
        
        
        
        
        if InCombatLockdown() then
            state[key] = state[key] or {}
            state[key].pendingUnmanage = true
            return
        end

        local bar = _G[key]
        if bar then
            local buttons = BarButtons(bar, key)
            for i = 1, 12 do
                if buttons[i] then
                    local container = buttons[i].container or buttons[i]:GetParent()
                    if container then
                        ParkContainer(container, false, bar)
                        container:SetScale(1)
                        container:Show()
                    end
                    ApplyButtonText(buttons[i], cfg, true)
                end
            end
        end

        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("ACTIONBARS", "unmanaged %s", key)
        end
    end
end








function AB:ApplyAll()
    local bars = ThugUIDB.ActionBars and ThugUIDB.ActionBars.bars
    if not bars then return end
    for _, bar in ipairs(AB.BARS) do
        local cfg = bars[bar.key]
        if cfg and cfg.managed then
            self:ApplyLayout(bar.key)
        end
        if cfg and cfg.lockPage then
            self:ApplyPageLock(bar.key)
        end
    end
end

function AB:Initialize()
    local frame = CreateFrame("Frame")

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            
            
            
            
            AB:ApplyAll()
        elseif event == "PLAYER_REGEN_ENABLED" then
            for _, bar in ipairs(AB.BARS) do
                local key = bar.key
                local s = state[key]

                if s and s.pending then
                    s.pending = nil
                    AB:ApplyLayout(key)
                end

                if s and s.pendingLock then
                    s.pendingLock = nil
                    AB:ApplyPageLock(key)
                end

                if s and s.pendingUnmanage then
                    s.pendingUnmanage = nil
                    AB:SetManaged(key, false)
                end

                if s and s.pendingEnable ~= nil then
                    local enabled = s.pendingEnable
                    s.pendingEnable = nil
                    AB:SetBarEnabled(key, enabled)
                end
            end
        end
    end)

    
    for _, bar in ipairs(AB.BARS) do
        local key = bar.key
        local barFrame = _G[key]
        if barFrame and type(barFrame.UpdateGridLayout) == "function" then
            hooksecurefunc(barFrame, "UpdateGridLayout", function()
                AB:ApplyLayout(key)
            end)
            
            
            
            if type(barFrame.UpdateShownButtons) == "function" then
                hooksecurefunc(barFrame, "UpdateShownButtons", function()
                    AB:ApplyLayout(key)
                end)
            end
        else
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("ACTIONBARS", "could not hook UpdateGridLayout on %s", key)
            end
        end
    end

    local V = ThugUI.Visibility
    if V then
        local function UpdateFrameAlpha(frameOrName, fallbackName, key)
            local frame = type(frameOrName) == "string" and _G[frameOrName] or frameOrName
            if not frame and fallbackName then
                frame = _G[fallbackName]
            end
            if not frame or type(frame.SetAlpha) ~= "function" then return end

            local inController = ThugUI.ControllerMode and ThugUI.ControllerMode.IsActive and ThugUI.ControllerMode:IsActive()
            local abOn = ThugUI:IsModuleOn("actionbars")

            if abOn and not inController then
                frame:SetAlpha(V:Alpha(key))
            else
                frame:SetAlpha(1)
            end
        end

        AB.UpdateVisibilityFrames = function()
            UpdateFrameAlpha("StatusTrackingBarManager", nil, "statusBar")
            UpdateFrameAlpha("MicroMenuContainer", "MicroButtonAndBagsBar", "microMenu")
            UpdateFrameAlpha("BagsBar", nil, "bagBar")
        end

        V:Register("statusBar", function() AB.UpdateVisibilityFrames() end)
        V:Register("microMenu", function() AB.UpdateVisibilityFrames() end)
        V:Register("bagBar", function() AB.UpdateVisibilityFrames() end)

        AB.UpdateVisibilityFrames()
    end
end

if ThugUI.Visibility and ThugUI.Visibility.KEYS then
    ThugUI.Visibility.KEYS.statusBar = true
    ThugUI.Visibility.KEYS.microMenu = true
    ThugUI.Visibility.KEYS.bagBar = true
end

ThugUI:RegisterModule("ActionBars", AB)
