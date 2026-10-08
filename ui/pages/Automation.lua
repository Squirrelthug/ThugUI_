



ThugUI = ThugUI or {}

local Page = {}

local ROW_H = 20

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Automation = ThugUIDB.Automation or {}
    ThugUIDB.Automation.sellJunkBlacklist = ThugUIDB.Automation.sellJunkBlacklist or {}
    return ThugUIDB.Automation
end

function Page:Build(host, panel)
    local A = ThugUI.Automation
    if not A then return end

    panel:Header("Automation")
    panel:Note("Automatically sells grey items and repairs equipment the moment "
        .. "you open a vendor window.")

    panel:Section("Vendor")

    panel:Checkbox{
        label = "Sell junk automatically at vendors",
        tooltip = "Every poor-quality (grey) item in your bags is sold when you "
            .. "open a vendor, except anything on the blacklist below.",
        get = function() return Cfg().sellJunk end,
        set = function(v) Cfg().sellJunk = v end,
    }

    panel:Checkbox{
        label = "Repair automatically at vendors",
        get = function() return Cfg().autoRepair end,
        set = function(v) Cfg().autoRepair = v end,
    }

    panel:Checkbox{
        label = "Prefer guild funds when available",
        indent = 24,
        tooltip = "Repairs from the guild bank when your guild allows it and "
            .. "has enough. Falls back to your own gold otherwise, so you "
            .. "always leave the vendor repaired.",
        get = function() return Cfg().preferGuildRepair end,
        set = function(v) Cfg().preferGuildRepair = v end,
    }

    panel:Checkbox{
        label = "Announce what was sold and repaired in chat",
        get = function() return Cfg().announce end,
        set = function(v) Cfg().announce = v end,
    }

    panel:Section("Junk blacklist")

    panel:Note("Items whose name contains any of these are never sold. Matching "
        .. "ignores capitals, so \"lockbox\" protects every lockbox you own.", { width = 320 })

    
    
    Page.host = panel.parent

    
    panel:Gap(12)

    panel:Label("Add to blacklist:")

    local editBox = panel:EditBox{
        width = 240,
        get = function() return Page.editBoxText or "" end,
        set = function(v) Page.editBoxText = v end,
    }

    local function TryAddEntry()
        local text = editBox:GetText()
        local success, reason = A:AddBlacklistEntry(text)
        if success then
            editBox:SetText("")
            Page.editBoxText = ""
            Page:Relayout()
        else
            if reason == "empty" then
                print("|cff00ff00ThugUI:|r Blacklist entry cannot be empty.")
            elseif reason == "duplicate" then
                print("|cff00ff00ThugUI:|r Entry already on blacklist.")
            end
        end
    end

    
    editBox:SetScript("OnEnterPressed", function(self)
        TryAddEntry()
        self:ClearFocus()
    end)

    
    panel:Button{
        label = "Add",
        width = 80,
        onClick = TryAddEntry,
        sameLine = true,
        gap = 8,
    }

    
    
    
    
    
    
    
    local container = CreateFrame("Frame", nil, panel.parent)
    
    
    container:SetWidth(panel.width)
    Page.container = container

    
    panel:Place(container, 0)
    local listTop = panel:GetHeight()
    Page.listTop = listTop

    
    Page.rows = {}
end

function Page:Relayout()
    local A = ThugUI.Automation
    if not A then return end

    local blacklist = A:GetBlacklist()
    local container = Page.container

    
    for i = 1, #blacklist do
        if not Page.rows[i] then
            
            local row = CreateFrame("Frame", nil, container)
            row:SetHeight(ROW_H)
            
            
            
            row:SetWidth(container:GetWidth())

            
            
            
            
            
            
            
            local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            removeBtn:SetSize(18, 18)
            removeBtn:SetText("X")
            removeBtn:SetPoint("TOPRIGHT", 0, 0)

            local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            name:SetPoint("TOPLEFT", 0, 0)
            
            
            name:SetPoint("RIGHT", removeBtn, "LEFT", -6, 0)
            name:SetHeight(ROW_H)
            name:SetJustifyH("LEFT")
            row.nameText = name

            function row:UpdateContent(entry)
                name:SetText(entry)
            end

            function row:SetRemoveCallback(callback)
                removeBtn:SetScript("OnClick", function()
                    callback()
                end)
            end

            Page.rows[i] = row
        end

        local row = Page.rows[i]
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row:Show()
        row:UpdateContent(blacklist[i])
        row:SetRemoveCallback(function()
            A:RemoveBlacklistEntry(i)
            Page:Relayout()
        end)
    end

    
    for i = #blacklist + 1, #Page.rows do
        Page.rows[i]:Hide()
    end

    
    local containerH = #blacklist * ROW_H
    container:SetHeight(containerH)

    
    local minH = (ThugUI.Window.frame and ThugUI.Window.frame.content
                  and ThugUI.Window.frame.content:GetHeight()) or 400
    Page.host:SetHeight(math.max(Page.listTop + #blacklist * ROW_H + 20, minH))
end

ThugUI.Window:RegisterPage{
    id = "automation",
    category = "general",
    order = 20,
    summary = "Automatic vendor and repair options.",
    title = "Automation",
    build = function(host, panel) Page:Build(host, panel) end,
    refresh = function(host, panel) Page:Relayout() end,
}

return Page
