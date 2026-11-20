




































local ThugUI = _G.ThugUI
local PH = { entries = {} }
ThugUI.PadHints = PH

local ROW_H, PAD, WIDTH, GLYPH = 24, 16, 260, 18

local GLYPH_FALLBACK = {
    PADFORWARD = "Start", PADBACK = "Select", PAD1 = "Cross", PAD2 = "Circle", PAD3 = "Square", PAD4 = "Triangle",
    PADLSHOULDER = "L1", PADRSHOULDER = "R1", PADLTRIGGER = "L2", PADRTRIGGER = "R2",
    PADLSTICK = "L3", PADRSTICK = "R3",
    PADDUP = "D-pad up", PADDDOWN = "D-pad down", PADDLEFT = "D-pad left", PADDRIGHT = "D-pad right",
}



function PH.GlyphAtlas(key)
    local util = _G.InputIconTextureSetUtility
    if util and util.GetNormalActiveInputIconButtonTexture then
        local ok, atlas = pcall(util.GetNormalActiveInputIconButtonTexture, key)
        if ok and type(atlas) == "string" and atlas ~= "" then
            return atlas
        end
    end
    return nil
end






function PH.KeyLabel(key)
    local PL = ThugUI.PadLayout
    local kind = PL and PL.Kind and PL:Kind()
    local keys = kind and PL.KEYS and PL.KEYS[kind]
    if keys then
        for slotId, k in pairs(keys) do
            local word = k == key and PL.LABELS[kind] and PL.LABELS[kind][slotId]
            if word then return word end
        end
    end
    return GLYPH_FALLBACK[key] or tostring(key)
end



local WORD_ONLY = { PADSOCIAL = true, PAD5 = true, PAD6 = true }



function PH.Glyph(key, size)
    if WORD_ONLY[key] then return PH.KeyLabel(key) end
    local atlas = CreateAtlasMarkup and PH.GlyphAtlas(key)
    if key == "PADSYSTEM" then
        
        
        if not (atlas and (atlas:find("pslogo", 1, true) or atlas:find("xblogo", 1, true))) then
            return PH.KeyLabel(key)
        end
    end
    if atlas then
        return CreateAtlasMarkup(atlas, size or GLYPH, size or GLYPH)
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



local function Field(v)
    if type(v) ~= "function" then return true, v end
    return pcall(v)
end





function PH:Rows(group)
    local plain, red = {}, {}
    for _, e in ipairs(self.entries) do
        if e.group == group then
            local ok, on = pcall(e.enabled or function() return true end)
            local keys = ok and on and e.keys
            if type(keys) == "function" then keys = keys() end
            if keys then
                local okT, text = Field(e.text)
                local okR, isRed = Field(e.red)
                if okT and type(text) == "string" then
                    local row = { keys = keys, text = text, red = okR and isRed == true }
                    local into = row.red and red or plain
                    into[#into + 1] = row
                end
            end
        end
    end
    for _, row in ipairs(red) do plain[#plain + 1] = row end
    return plain
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
            
            fs:SetWordWrap(false)
            f.rows[i] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -PAD - ROW_H * i)
        
        fs:SetText(r.keys == "" and r.text or (r.keys .. "  " .. r.text))
        
        ThugUI.Theme:Paint(fs, r.red and "warning" or "label")
        fs:Show()
    end
    for i = #rows + 1, #f.rows do f.rows[i]:Hide() end
    f:SetHeight(PAD * 2 + ROW_H * (#rows + 1))
    
    local legend = _G.GamepadPersistentInputLegend
    if type(legend) ~= "table" then f:Hide() return end
    local ok, w = pcall(legend.GetGroupWidth, legend, group)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", legend, "TOPLEFT", ((ok and tonumber(w)) or 300) + 8, 0)
    f:Show()
    self.shownGroup = group
end






function PH:Refresh()
    if self.legendGroup then self:ShowFor(self.legendGroup) end
end

function PH:Install()
    local legend = _G.GamepadPersistentInputLegend
    if self.installed or type(legend) ~= "table" or type(legend.ShowGroup) ~= "function" then return false end
    self.installed = true
    
    hooksecurefunc(legend, "HideAllGroups", function() PH.legendGroup = nil PH:ShowFor(nil) end)
    hooksecurefunc(legend, "ShowGroup", function(_, group) PH.legendGroup = group PH:ShowFor(group) end)
    return true
end




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




PH:Register{ id = "cross-l1r1", group = "MODIFIER",
    keys = function()
        local PL = ThugUI.PadLayout
        return PH.Glyph(PL and PL:KeyFor("cross"))
    end,
    text = function()
        local PL = ThugUI.PadLayout
        return PL and (PL:Describe("cross").label) or ""
    end,
    enabled = function()
        local PL, CS, CM = ThugUI.PadLayout, ThugUI.ControllerShortcuts, ThugUI.ControllerMode
        if not (PL and CS and CM) then return false end
        
        if not (CM:Uses("shortcutCross") or (CM:IsActive() and PL:CrossRun())) then return false end
        return PL:Get("cross") ~= nil and PL:HasSlot("cross")
            and not CS:BlizzardOwnsCross() and CM:GetShortcutsBar() ~= nil
    end }







for _, def in ipairs({
    { id = "l1right",   group = "GAMEPLAY", bumper = "PADLSHOULDER" },
    { id = "r1right",   group = "GAMEPLAY", bumper = "PADRSHOULDER" },
    { id = "l1r1top",   group = "MODIFIER" },
    { id = "l1r1right", group = "MODIFIER" },
    { id = "l1r1left",  group = "MODIFIER" },
    { id = "l1r1up",    group = "MODIFIER" },
    { id = "l1r1down",  group = "MODIFIER" },
}) do
    PH:Register{ id = "bumper-" .. def.id, group = def.group,
        keys = function()
            local PL = ThugUI.PadLayout
            local key = PL and PL:KeyFor(def.id)
            if not key then return nil end
            if def.bumper then return PH.Glyph(def.bumper) .. " + " .. PH.Glyph(key) end
            return PH.Glyph(key)
        end,
        text = function()
            local PL = ThugUI.PadLayout
            return PL and (PL:Describe(def.id).label) or ""
        end,
        enabled = function()
            local PL, CM = ThugUI.PadLayout, ThugUI.ControllerMode
            if not (PL and CM and CM:IsActive()) then return false end
            return PL:HasSlot(def.id) and not PL:Describe(def.id).isDefault
                and PL:BarFrame(PL:BarOf(def.id)) ~= nil
        end }
end


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
    
    
    if ThugUI.moduleOn and not ThugUI:IsModuleOn("controller") then self:UnregisterAllEvents() return end
    if event == "ADDON_LOADED" and name ~= "Blizzard_Gamepad" then return end
    local ok, err = pcall(PH.Install, PH)
    if not ok and ThugUI.Diagnostics then ThugUI.Diagnostics:Log("PADHINTS", "install failed: %s", tostring(err)) end
    if PH.installed then self:UnregisterAllEvents() end
end)
PH.loginFrame = login
