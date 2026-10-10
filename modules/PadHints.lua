

























local ThugUI = _G.ThugUI
local PH = { entries = {} }
ThugUI.PadHints = PH

local ROW_H, PAD, WIDTH, GLYPH = 24, 16, 260, 18

local GLYPH_FALLBACK = {
    PADFORWARD = "Start", PADBACK = "Select", PAD1 = "Cross", PAD2 = "Circle", PAD3 = "Square", PAD4 = "Triangle",
    PADLSHOULDER = "L1", PADRSHOULDER = "R1", PADLTRIGGER = "L2", PADRTRIGGER = "R2",
    PADDUP = "D-pad up", PADDDOWN = "D-pad down", PADDLEFT = "D-pad left", PADDRIGHT = "D-pad right",
}


function PH.Glyph(key)
    local util = _G.InputIconTextureSetUtility
    if util and util.GetNormalActiveInputIconButtonTexture and CreateAtlasMarkup then
        local ok, atlas = pcall(util.GetNormalActiveInputIconButtonTexture, key)
        if ok and type(atlas) == "string" and atlas ~= "" then
            return CreateAtlasMarkup(atlas, GLYPH, GLYPH)
        end
    end
    return GLYPH_FALLBACK[key] or tostring(key)
end



function PH.BindingGlyphs(binding)
    if type(binding) ~= "string" or binding == "" then return nil end
    local out = {}
    for part in binding:gmatch("[^%-]+") do
        if not part:match("^PAD") then return nil end
        out[#out + 1] = PH.Glyph(part)
    end
    return table.concat(out, " + ")
end



function PH:Register(e)
    for i, old in ipairs(self.entries) do
        if old.id == e.id then self.entries[i] = e return end
    end
    self.entries[#self.entries + 1] = e
end


function PH:Rows(group)
    local rows = {}
    for _, e in ipairs(self.entries) do
        if e.group == group then
            local ok, on = pcall(e.enabled or function() return true end)
            local keys = ok and on and e.keys and e.keys()
            if keys then rows[#rows + 1] = { keys = keys, text = e.text } end
        end
    end
    return rows
end

local HEADERS = {
    GAMEPLAY = "ThugUI",
    MODIFIER = "ThugUI, while L1 + R1 are held",
}

local function Build()
    if PH.frame then return PH.frame end
    local f = CreateFrame("Frame", "ThugUI_PadHints", UIParent, "BackdropTemplate")
    f:SetFrameStrata("LOW")
    f:SetSize(WIDTH, 60)
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 } })
        ThugUI.Theme:Paint(f, "listBackground", "backdrop")
        ThugUI.Theme:Paint(f, "border", "border")
    end
    f.header = ThugUI.Theme:Paint(f:CreateFontString(nil, "OVERLAY", "GameFontNormal"), "section")
    f.header:SetPoint("TOPLEFT", PAD, -PAD)
    f.rows = {}
    f:Hide()
    PH.frame = f
    return f
end


function PH:ShowFor(group)
    local f = Build()
    local rows = group and HEADERS[group] and self:Rows(group) or {}
    if #rows == 0 then
        f:Hide()
        self.shownGroup = nil
        return
    end
    f.header:SetText(HEADERS[group])
    for i, r in ipairs(rows) do
        local fs = f.rows[i]
        if not fs then
            fs = ThugUI.Theme:Paint(f:CreateFontString(nil, "OVERLAY", "GameFontHighlight"), "label")
            fs:SetJustifyH("LEFT")
            fs:SetWidth(WIDTH - PAD * 2)
            f.rows[i] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -PAD - ROW_H * i)
        fs:SetText(r.keys .. "  " .. r.text)
        fs:Show()
    end
    for i = #rows + 1, #f.rows do f.rows[i]:Hide() end
    f:SetHeight(PAD * 2 + ROW_H * (#rows + 1))
    
    local legend = _G.GamepadPersistentInputLegend
    local ok, w = pcall(legend.GetGroupWidth, legend, group)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", legend, "TOPLEFT", ((ok and tonumber(w)) or 300) + 8, 0)
    f:Show()
    self.shownGroup = group
end

function PH:Install()
    local legend = _G.GamepadPersistentInputLegend
    if self.installed or type(legend) ~= "table" or type(legend.ShowGroup) ~= "function" then return false end
    self.installed = true
    
    hooksecurefunc(legend, "HideAllGroups", function() PH:ShowFor(nil) end)
    hooksecurefunc(legend, "ShowGroup", function(_, group) PH:ShowFor(group) end)
    return true
end





PH:Register{ id = "radial-start", group = "GAMEPLAY", text = "ThugUI menu (press twice)",
    keys = function()
        local key = GetBindingKey and GetBindingKey("OPENRADIAL")
        if type(key) ~= "string" or key == "" then key = "PADFORWARD" end
        local g = PH.Glyph(key)
        return g .. " " .. g
    end,
    enabled = function()
        local R = ThugUI.ControllerRadial
        return R and R.IsListening and R:IsListening()
    end }


PH:Register{ id = "radial-binding", group = "GAMEPLAY", text = "ThugUI menu",
    keys = function() return PH.BindingGlyphs(GetBindingKey and GetBindingKey("THUGUI_WHEEL")) end,
    enabled = function()
        local R = ThugUI.ControllerRadial
        return R and R.IsListening and R:IsListening()
    end }




PH:Register{ id = "radial-triangle", group = "GAMEPLAY", text = "Target options",
    keys = function() return PH.Glyph(_G.GAMEPAD_FACE_TOP or "PAD4") end,
    enabled = function()
        local R, CT = ThugUI.ControllerRadial, ThugUI.ControllerTarget
        return R and R.triangleHooked == true and CT and CT:IsActive()
    end }



PH:Register{ id = "map-shortcut", group = "MODIFIER", text = "World map",
    keys = function() return PH.Glyph(_G.GAMEPAD_FACE_BOTTOM or "PAD1") end,
    enabled = function()
        local CS = ThugUI.ControllerShortcuts
        return not (CS and CS.PAUSED) and ThugUI.ControllerMode and ThugUI.ControllerMode:Uses("mapShortcut")
    end }


PH:Register{ id = "fishing-double", group = "GAMEPLAY", text = "Cast fishing (press twice)",
    keys = function()
        local c = ThugUIDB and ThugUIDB.Fishing
        local g = PH.BindingGlyphs(c and c.doubleKey)
        return g and (g .. " " .. g)
    end,
    enabled = function() return not (ThugUI.moduleOn and ThugUI.moduleOn.fishing == false) end }


local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:RegisterEvent("ADDON_LOADED")
login:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_Gamepad" then return end
    local ok, err = pcall(PH.Install, PH)
    if not ok and ThugUI.Diagnostics then ThugUI.Diagnostics:Log("PADHINTS", "install failed: %s", tostring(err)) end
    if PH.installed then self:UnregisterAllEvents() end
end)
PH.loginFrame = login
