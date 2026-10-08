






local ThugUI = _G.ThugUI
local P = ThugUI.Prep

local function Build(panel)
    panel:Note("The wheel's Prep page fills itself from your bags. Add an item here if it lands in the wrong place or not at all; hide one you never want on the wheel. /thugprep dump logs how each item was sorted.")

    panel.sections = {}

    for _, s in ipairs(P.SECTIONS) do
        panel:FrameSection{ title = P.TITLES[s] }
        
        local note = panel:Note("")
        
        local btnPool = {}
        for i = 1, 12 do
            local btn = panel:Button{
                label = "",
                width = 200,
                onClick = function() end
            }
            table.insert(btnPool, btn)
        end
        
        
        
        panel:EditBox{
            label = "Add item (ID or name)",
            width = 200,
            get = function() return "" end,
            set = function(text)
                if text and text ~= "" then
                    local id, msg = P:Resolve(text)
                    if id then
                        P:Add(s, id)
                    else
                        print("ThugUI: " .. msg)
                    end
                end
                panel:Refresh()
            end
        }
        
        panel.sections[s] = {
            note = note,
            btnPool = btnPool,
        }
    end

    panel:FrameSection{ title = "Hidden" }
    panel.hiddenBtnPool = {}
    for i = 1, 12 do
        local btn = panel:Button{
            label = "",
            width = 200,
            onClick = function() end
        }
        table.insert(panel.hiddenBtnPool, btn)
    end
end

local function Refresh(panel)
    local entries = P:Scan()
    local cfg = ThugUIDB and ThugUIDB.Prep or ThugUI.defaults.Prep

    for _, s in ipairs(P.SECTIONS) do
        local sec = panel.sections[s]
        
        local foundTexts = {}
        local btnIdx = 1
        
        for _, e in ipairs(entries) do
            if e.section == s and e.count > 0 then
                table.insert(foundTexts, (e.name or ("Item " .. e.id)) .. " x" .. e.count)
                
                if btnIdx <= 12 then
                    local btn = sec.btnPool[btnIdx]
                    btn:SetText("Hide " .. (e.name or ("Item " .. e.id)))
                    btn:SetScript("OnClick", function()
                        P:Hide(e.id)
                        panel:Refresh()
                    end)
                    btn:Show()
                    btnIdx = btnIdx + 1
                end
            end
        end
        
        if cfg.manual and cfg.manual[s] then
            for _, id in ipairs(cfg.manual[s]) do
                if btnIdx <= 12 then
                    local btn = sec.btnPool[btnIdx]
                    btn:SetText("Remove " .. P.ItemName(id))
                    btn:SetScript("OnClick", function()
                        P:Remove(s, id)
                        panel:Refresh()
                    end)
                    btn:Show()
                    btnIdx = btnIdx + 1
                end
            end
        end
        
        for i = btnIdx, 12 do
            sec.btnPool[i]:Hide()
        end
        
        if #foundTexts > 0 then
            sec.note:SetText(table.concat(foundTexts, "\n"))
        else
            sec.note:SetText("None in your bags.")
        end
    end

    local hIdx = 1
    if cfg.hidden then
        for _, id in ipairs(cfg.hidden) do
            if hIdx <= 12 then
                local btn = panel.hiddenBtnPool[hIdx]
                btn:SetText("Unhide " .. P.ItemName(id))
                btn:SetScript("OnClick", function()
                    P:Unhide(id)
                    panel:Refresh()
                end)
                btn:Show()
                hIdx = hIdx + 1
            end
        end
    end
    for i = hIdx, 12 do
        panel.hiddenBtnPool[i]:Hide()
    end
end

ThugUI.Window:RegisterPage{
    id = "prep",
    category = "general",
    order = 75,
    scopeKeys = { "Prep" },
    title = "Prep",
    summary = "Elixirs, scrolls and campfire food on the wheel.",
    build = function(host, panel)
        Build(panel)
    end,
    refresh = function(host, panel)
        Refresh(panel)
    end
}
