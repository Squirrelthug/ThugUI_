

































local ThugUI = _G.ThugUI
local FB = {}
ThugUI.FaceButtons = FB
ThugUI:RegisterModule("FaceButtons", FB)

ThugUI.defaults.FaceButtons = { p1 = {}, p2 = {}, p3 = {} }

FB.PAGES = 3


FB.FACES = {
    { id = "bottom", title = "Bottom button", key = _G.GAMEPAD_FACE_BOTTOM or "PAD1", default = "Jump", index = 8 },
    { id = "right",  title = "Right button",  key = _G.GAMEPAD_FACE_RIGHT or "PAD2",  default = "Back", index = 7 },
    { id = "left",   title = "Left button",   key = _G.GAMEPAD_FACE_LEFT or "PAD3",   default = "Interact", index = 5 },
    { id = "top",    title = "Top button",    key = _G.GAMEPAD_FACE_TOP or "PAD4",    default = "Inspect", index = 6 },
}

local function Log(fmt, ...)
    if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then ThugUI.Diagnostics:Log("FACE", fmt, ...) end
end

local function Cfg() return ThugUIDB.FaceButtons end
local function Combat() return InCombatLockdown and InCombatLockdown() or false end



function FB:Get(page, faceId)
    local p = Cfg() and Cfg()["p" .. page]
    return p and p[faceId] or nil
end


function FB:Set(page, faceId, value)
    local key = "p" .. page
    Cfg()[key] = Cfg()[key] or {}
    Cfg()[key][faceId] = value
    self:Apply()
end

local function Parse(value)
    if type(value) ~= "string" then return nil end
    local kind, rest = value:match("^(%a+):(.+)$")
    if kind == "spell" then return "spell", tonumber(rest) end
    if kind == "macro" then return "macro", rest end
    return nil
end
FB.Parse = Parse

local function Label(value)
    local kind, what = Parse(value)
    if kind == "spell" then
        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(what)
        return name or ("Spell " .. tostring(what))
    elseif kind == "macro" then
        return "Macro: " .. what
    end
    return tostring(value)
end

local function KnownSpells(out)
    local book = C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    if not (book and book.GetNumSpellBookSkillLines and bank) then return end
    local seen, found = {}, {}
    for line = 1, book.GetNumSpellBookSkillLines() do
        local info = book.GetSpellBookSkillLineInfo(line)
        if info and not info.shouldHide and not info.offSpecID then
            for i = 1, info.numSpellBookItems do
                local item = book.GetSpellBookItemInfo(info.itemIndexOffset + i, bank)
                if item and item.itemType == spellType and item.spellID and not item.isPassive
                    and not item.isOffSpec and not seen[item.spellID] then
                    seen[item.spellID] = true
                    found[#found + 1] = { text = item.name, value = "spell:" .. item.spellID }
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.text < b.text end)
    for _, row in ipairs(found) do out[#out + 1] = row end
end

local function Macros(out)
    if not (GetNumMacros and GetMacroInfo) then return end
    local global, character = GetNumMacros()
    
    local first = (_G.MAX_ACCOUNT_MACROS or 120) + 1
    local function Add(i)
        local name = GetMacroInfo(i)
        if name then out[#out + 1] = { text = "Macro: " .. name, value = "macro:" .. name } end
    end
    for i = 1, global or 0 do Add(i) end
    for i = first, first + (character or 0) - 1 do Add(i) end
end



function FB:Options(page, face)
    local rows = { { text = "Default: " .. face.default, value = "" } }
    local ok, err = pcall(KnownSpells, rows)
    if not ok then Log("spell list failed: %s", tostring(err)) end
    ok, err = pcall(Macros, rows)
    if not ok then Log("macro list failed: %s", tostring(err)) end
    local saved = self:Get(page, face.id)
    if saved then
        local listed = false
        for _, row in ipairs(rows) do
            if row.value == saved then listed = true end
        end
        if not listed then rows[#rows + 1] = { text = Label(saved), value = saved } end
    end
    return rows
end









FB.PRE_CLICK = [[
    if down then
        local active
        for i = 1, owner:GetAttribute("bars") do
            if owner:GetFrameRef("bar" .. i):GetFrameLevel() == 5 then
                active = i
                break
            end
        end
        local id = owner:GetFrameRef("paged"):GetID()
        local page = (id == owner:GetAttribute("id1") and 1)
            or (id == owner:GetAttribute("id2") and 2)
            or (id == owner:GetAttribute("id3") and 3)
        local attr = active == 1 and page and self:GetAttribute("p" .. page .. "-attr")
        self:SetAttribute("macro", nil)
        self:SetAttribute("macrotext", nil)
        self:SetAttribute("type", "macro")
        self:SetAttribute("useOnKeyDown", true)
        if attr then
            self:SetAttribute("held-up", nil)
            self:SetAttribute(attr, self:GetAttribute("p" .. page .. "-value"))
        else
            local to = active and ("bar" .. active) or "forward"
            self:SetAttribute("held-up", self:GetAttribute(to .. "-up"))
            self:SetAttribute("macrotext", self:GetAttribute(to .. "-down"))
        end
    else
        local up = self:GetAttribute("held-up")
        self:SetAttribute("macro", nil)
        self:SetAttribute("macrotext", up)
        self:SetAttribute("type", up and "macro" or nil)
        self:SetAttribute("useOnKeyDown", false)
    end
]]

local bindOwner = CreateFrame("Frame", "ThugUI_FaceBindOwner")
local header
local buttons = {}
FB.buttons = buttons



local BAR_KEYS = { "topBar", "leftBar", "rightBar", "bottomBar", "possessBar", "stanceBar",
                   "friendlyTargetingBar", "hostileTargetingBar", "shortcutsBar" }

local function Bars()
    local bar = _G.GamepadMainActionBarFrame
    local all = bar and bar.PageUnit and bar.PageUnit.actionBars
    if not (all and all.topBar) then return nil end
    local out = {}
    for _, key in ipairs(BAR_KEYS) do
        if all[key] then out[#out + 1] = all[key] end
    end
    return out
end

local function ButtonName(face) return "ThugUI_Face_" .. face.id end





local overlays = {}
FB.overlays = overlays

local function BuildIcons(bar)
    for _, face in ipairs(FB.FACES) do
        local button = bar:GetActionButtonByIndex(face.index)
        local o = CreateFrame("Frame", nil, button)
        o:SetAllPoints(button.icon or button)
        o:SetFrameLevel(button:GetFrameLevel() + 1)
        o:EnableMouse(false)
        o.texture = o:CreateTexture(nil, "ARTWORK")
        o.texture:SetAllPoints()
        
        local mask = o:CreateMaskTexture()
        mask:SetAllPoints(o.texture)
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        o.texture:AddMaskTexture(mask)
        o:Hide()
        overlays[face.id] = o
    end
end

local function IconFor(value)
    local kind, what = Parse(value)
    if kind == "spell" then
        return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(what)
    elseif kind == "macro" and GetMacroInfo then
        local _, icon = GetMacroInfo(what)
        return icon
    end
    return nil
end


function FB:UpdateIcons()
    local bar = _G.GamepadMainActionBarFrame
    local unit = bar and bar.PageUnit
    local page = unit and unit:GetCurrentPage()
    for _, face in ipairs(self.FACES) do
        local o = overlays[face.id]
        if o then
            local icon = page and IconFor(self:Get(page, face.id))
            if icon then
                o.texture:SetTexture(icon)
                o:Show()
            else
                o:Hide()
            end
        end
    end
end

local logged = 0
local function NewButton(face, bars)
    local b = CreateFrame("Button", ButtonName(face), UIParent, "SecureActionButtonTemplate")
    b:SetSize(1, 1)
    b:SetAlpha(0)
    b:EnableMouse(false)
    b:RegisterForClicks("AnyDown", "AnyUp")
    local function Route(prefix, name)
        b:SetAttribute(prefix .. "-down", "/click " .. name .. " LeftButton 1")
        b:SetAttribute(prefix .. "-up", "/click " .. name .. " LeftButton")
    end
    Route("forward", "InputFunctionBindingButton_" .. face.key)
    for i, bar in ipairs(bars) do
        local target = bar:GetActionButtonByIndex(face.index)
        if target and target:GetName() then Route("bar" .. i, target:GetName()) end
    end
    
    b:SetAttribute("type", "macro")
    b:SetAttribute("useOnKeyDown", true)
    b:SetAttribute("macrotext", b:GetAttribute("bar1-down"))
    SecureHandlerWrapScript(b, "OnClick", header, FB.PRE_CLICK)
    
    b:HookScript("PostClick", function(self, _, down)
        if down and logged < 30 then
            logged = logged + 1
            Log("%s press: %s (combat %s)", face.id,
                tostring(self:GetAttribute("macrotext") or self:GetAttribute("macro")), tostring(Combat()))
        end
    end)
    return b
end

local function Build()
    if header then return true end
    local bars = Bars()
    local util = _G.GamepadActionBarBindingUtil
    if not (bars and util) then return false end
    local ok, err = pcall(function()
        local h = CreateFrame("Frame", "ThugUI_FaceHeader", UIParent, "SecureHandlerBaseTemplate")
        SecureHandlerSetFrameRef(h, "paged", bars[1].Left.ActionButton1)
        for i, bar in ipairs(bars) do SecureHandlerSetFrameRef(h, "bar" .. i, bar) end
        h:SetAttribute("bars", #bars)
        for page = 1, FB.PAGES do
            h:SetAttribute("id" .. page, util.GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID(page, 1))
        end
        header = h
        for _, face in ipairs(FB.FACES) do buttons[face.id] = NewButton(face, bars) end
    end)
    if not ok then
        header = nil
        Log("build failed, Blizzard keeps the buttons: %s", tostring(err))
        return false
    end
    
    local okIcons, errIcons = pcall(function()
        BuildIcons(bars[1])
        hooksecurefunc(_G.GamepadMainActionBarFrame.PageUnit, "SetCurrentPage", function() FB:UpdateIcons() end)
    end)
    if not okIcons then Log("icons failed: %s", tostring(errIcons)) end
    return true
end

local function InUse(face)
    for page = 1, FB.PAGES do
        if Parse(FB:Get(page, face.id)) then return true end
    end
    return false
end




local function Action(value)
    local kind, what = Parse(value)
    if kind == "macro" then return "macro", what end
    if kind == "spell" then
        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(what)
        if name then return "macrotext", "/cast " .. name end
        Log("no name for spell %s yet", tostring(what))
    end
    return nil, nil
end
FB.Action = Action

local function Ready()
    return ThugUI:IsModuleOn("controller") and ThugUI.ControllerMode and ThugUI.ControllerMode:IsActive()
end

local function Bind()
    ClearOverrideBindings(bindOwner)
    for _, face in ipairs(FB.FACES) do
        if InUse(face) then
            SetOverrideBindingClick(bindOwner, true, face.key, ButtonName(face), "LeftButton")
        end
    end
end



function FB:Apply()
    if Combat() then
        self.pending = true
        return
    end
    self.pending = false
    if not Ready() or not Build() then return end
    for _, face in ipairs(self.FACES) do
        local b = buttons[face.id]
        for page = 1, self.PAGES do
            local attr, value = Action(self:Get(page, face.id))
            b:SetAttribute("p" .. page .. "-attr", attr)
            b:SetAttribute("p" .. page .. "-value", value)
        end
    end
    Bind()
    self:UpdateIcons()
end





function FB:Reassert()
    if Combat() then
        self.pending = true
        return
    end
    if not header then return end
    local manager = _G.GamepadSharedUtility and _G.GamepadSharedUtility.InputBindingManager
    if manager and manager.IsOnlyCoreBindingSetActive and not manager:IsOnlyCoreBindingSetActive() then return end
    for _, face in ipairs(self.FACES) do
        if InUse(face) then
            local action = GetBindingAction(face.key, true)
            if not (type(action) == "string" and action:upper():find("THUGUI", 1, true)) then
                Bind()
                return
            end
        end
    end
end

function FB:Initialize()
    local f = CreateFrame("Frame")
    ThugUI.SafeRegisterEvent(f, "PLAYER_LOGIN")
    ThugUI.SafeRegisterEvent(f, "PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" or FB.pending then FB:Apply() end
    end)
    local manager = _G.GamepadSharedUtility and _G.GamepadSharedUtility.InputBindingManager
    if manager and manager.SetNewActiveKey then
        local queued = false
        hooksecurefunc(manager, "SetNewActiveKey", function()
            if queued then return end
            queued = true
            C_Timer.After(0, function()
                queued = false
                FB:Reassert()
            end)
        end)
    end
end
