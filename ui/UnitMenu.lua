



















local ThugUI = _G.ThugUI
local W = {}
ThugUI.UnitMenuWindow = W

local ROW_H, PAD, ICON, MIN_W = 18, 8, 14, 150
local MACRO_POOL = 6

local function Paint(obj, role, how) return ThugUI.Theme:Paint(obj, role, how) end

local function Log(fmt, ...)
    if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then ThugUI.Diagnostics:Log("UNITMENU", fmt, ...) end
end

local function Combat() return InCombatLockdown and InCombatLockdown() or false end

local columns = {}      
local macros = {}       
local used = 0          
W.columns, W.macros = columns, macros



local function NewColumn(i)
    local f = CreateFrame("Frame", "ThugUI_UnitMenu" .. (i == 1 and "" or i), UIParent, "BackdropTemplate")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        Paint(f, "listBackground", "backdrop")
        Paint(f, "listBorder", "border")
    end
    f.rows = {}
    f:Hide()
    columns[i] = f
    return f
end

local function NewRow(col)
    local b = CreateFrame("Button", nil, col)
    b:SetHeight(ROW_H)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    Paint(hl, "highlight", "fill")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(ICON, ICON)
    b.icon:SetPoint("LEFT", b, "LEFT", PAD, 0)
    b.text = b:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall"))
    b.text:SetJustifyH("LEFT")
    b.arrow = b:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontHighlightSmall"))
    b.arrow:SetPoint("RIGHT", b, "RIGHT", -PAD, 0)
    b.arrow:SetText(">")
    Paint(b.arrow, "listItem")
    b:SetScript("OnClick", function(self) W:Click(self) end)
    b:SetScript("OnEnter", function(self) W:Enter(self) end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    col.rows[#col.rows + 1] = b
    return b
end

local function Macro(i)
    if macros[i] then return macros[i] end
    if Combat() then return nil end
    local m = CreateFrame("Button", "ThugUI_UnitMenuMacro" .. i, UIParent, "SecureActionButtonTemplate")
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:RegisterForClicks("AnyUp")
    m:SetAttribute("type1", "macro")
    m:SetAttribute("macrotext1", "")
    m:HookScript("PostClick", function()
        Log("macro row clicked")
        if C_Timer and C_Timer.After then C_Timer.After(0, function() W:Close() end) else W:Close() end
    end)
    m:HookScript("OnEnter", function(self) if self.row then W:Enter(self.row) end end)
    m:Hide()
    macros[i] = m
    return m
end




local function ReleaseMacros()
    if Combat() then
        if used > 0 then W.pendingRelease = true end
        return
    end
    for i = 1, #macros do
        local m = macros[i]
        m:SetAttribute("macrotext1", "")
        m.row = nil
        m:ClearAllPoints()
        m:Hide()
    end
    used = 0
    W.pendingRelease = false
end



local function Header(unit)
    local name = ThugUI.UnitMenu:Name(unit)
    if not name and UnitName then
        local ok, n = pcall(UnitName, unit)
        if ok and not (issecretvalue and issecretvalue(n)) then name = n end
    end
    return name or ""
end

local function ClassColor(unit)
    if not (UnitIsPlayer and UnitClass) then return nil end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or (issecretvalue and issecretvalue(isPlayer)) or not isPlayer then return nil end
    local ok2, _, class = pcall(UnitClass, unit)
    if not ok2 or type(class) ~= "string" then return nil end
    local c = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class)
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    return c
end


local function Fill(col, rows, header, unit)
    local n = 0
    local width = MIN_W
    local function Next()
        n = n + 1
        return col.rows[n] or NewRow(col)
    end
    if header then
        local b = Next()
        b.row, b.isHeader = nil, true
        b.icon:Hide()
        b.arrow:Hide()
        b.text:ClearAllPoints()
        b.text:SetPoint("LEFT", b, "LEFT", PAD, 0)
        b.text:SetText(header)
        Paint(b.text, "listTitle")
        local c = ClassColor(unit)
        if c then b.text:SetTextColor(c.r, c.g, c.b, 1) end 
        b:EnableMouse(false)
    end
    for _, row in ipairs(rows) do
        local b = Next()
        b.row, b.isHeader = row, false
        b:EnableMouse(row.title == nil)
        b.text:ClearAllPoints()
        if row.icon then
            b.icon:SetTexture(row.icon)
            b.icon:Show()
            b.text:SetPoint("LEFT", b.icon, "RIGHT", 4, 0)
        else
            b.icon:Hide()
            b.text:SetPoint("LEFT", b, "LEFT", PAD + (row.title and 0 or 6), 0)
        end
        local label = row.title or row.text
        if row.checked then label = label .. "  *" end
        b.text:SetText(label)
        b.arrow:SetShown(row.sub ~= nil)
        if row.title then
            Paint(b.text, "section")
        elseif W:IsUsable(row) then
            Paint(b.text, "listItem")
        else
            Paint(b.text, "disabled")
        end
        local sw = b.text.GetStringWidth and b.text:GetStringWidth() or 0
        if type(sw) == "number" then
            width = math.max(width, sw + PAD * 2 + (row.icon and ICON + 4 or 6) + (row.sub and 16 or 0))
        end
    end
    for i = 1, #col.rows do
        local b = col.rows[i]
        if i <= n then
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -PAD / 2 - (i - 1) * ROW_H)
            b:SetPoint("RIGHT", col, "RIGHT", 0, 0)
            b:Show()
        else
            b.row = nil
            b:Hide()
        end
    end
    col:SetSize(width, n * ROW_H + PAD)
    return n
end



function W:IsUsable(row)
    if not row or row.title then return false end
    if row.enabled == false then return false end
    if row.macro and Combat() then return false end
    return true
end

local function Reason(row)
    if row.macro and Combat() then return "Out of combat only." end
    return row.reason
end


local function PlaceMacros(col)
    if Combat() then return end
    for _, b in ipairs(col.rows) do
        local row = b:IsShown() and b.row
        if row and row.macro and W:IsUsable(row) then
            local m = Macro(used + 1)
            if m then
                used = used + 1
                m:SetAttribute("macrotext1", ThugUI.UnitMenu:MacroText(row))
                m.row = b
                m:ClearAllPoints()
                m:SetAllPoints(b)
                m:SetFrameLevel((col:GetFrameLevel() or 1) + 10)
                m:Show()
            end
        end
    end
end




local events = CreateFrame("Frame")


function W:Open(unit, owner)
    if not unit or not ThugUI.UnitMenu then return false end
    if ThugUI.CombatClose and not ThugUI.CombatClose:Allow("unitmenu") then return false end
    self:Close()
    local rows, which = ThugUI.UnitMenu:Entries(unit)
    if not which then return false end
    local col = columns[1] or NewColumn(1)
    self.unit, self.owner = unit, owner
    Fill(col, rows, Header(unit), unit)
    local x, y = 0, 0
    if GetCursorPosition then x, y = GetCursorPosition() end
    local s = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if type(s) ~= "number" or s <= 0 then s = 1 end
    col:ClearAllPoints()
    col:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x or 0) / s, (y or 0) / s)
    col:Show()
    PlaceMacros(col)
    ThugUI.SafeRegisterEvent(events, "GLOBAL_MOUSE_DOWN")
    ThugUI.SafeRegisterEvent(events, "PLAYER_TARGET_CHANGED")
    ThugUI.SafeRegisterEvent(events, "GROUP_ROSTER_UPDATE")
    Log("opened for %s (%s, %d rows, combat=%s)", tostring(unit), tostring(which), #rows, tostring(Combat()))
    return true
end

function W:IsOpen() return columns[1] ~= nil and columns[1]:IsShown() end

function W:CloseSub()
    local sub = columns[2]
    if sub and sub:IsShown() then
        sub:Hide()
        
        ReleaseMacros()
        if columns[1] and columns[1]:IsShown() then PlaceMacros(columns[1]) end
    end
    self.subOf = nil
end

function W:Close()
    if columns[2] then columns[2]:Hide() end
    if columns[1] then columns[1]:Hide() end
    self.subOf = nil
    ReleaseMacros()
    events:UnregisterAllEvents()
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    if GameTooltip then GameTooltip:Hide() end
end



function W:Enter(b)
    local row = b and b.row
    if not row then return end
    if GameTooltip and not W:IsUsable(row) and Reason(row) then
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
        GameTooltip:SetText(Reason(row), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
    
    if b:GetParent() ~= columns[1] then return end
    if row.sub and W:IsUsable(row) then
        if self.subOf ~= b then self:OpenSub(b) end
    elseif self.subOf then
        self:CloseSub()
    end
end

function W:OpenSub(b)
    self:CloseSub()
    local col = columns[2] or NewColumn(2)
    Fill(col, b.row.sub)
    col:ClearAllPoints()
    col:SetPoint("TOPLEFT", b, "TOPRIGHT", 2, PAD / 2)
    col:Show()
    self.subOf = b
    PlaceMacros(col)
end

function W:Click(b)
    local row = b and b.row
    if not row or row.title then return end
    
    
    
    Log("clicked %s (usable=%s)", tostring(row.key), tostring(W:IsUsable(row)))
    if not W:IsUsable(row) then return end
    if row.sub then self:OpenSub(b) return end
    
    
    if row.macro then return end
    self:Close()
    if row.confirm then
        if ThugUI.Dialog and ThugUI.Dialogs[row.confirm] then ThugUI.Dialog:Show(row.confirm) end
    elseif row.run then
        local ok, err = pcall(row.run)
        if ok then Log("%s ran", tostring(row.key)) else Log("%s failed: %s", tostring(row.key), tostring(err)) end
    end
end

local function Over(f) return f and f:IsShown() and MouseIsOver and MouseIsOver(f) end

events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if W.pendingRelease and not W:IsOpen() then ReleaseMacros() end
    elseif event == "GLOBAL_MOUSE_DOWN" then
        if Over(columns[1]) or Over(columns[2]) then return end
        for i = 1, used do if Over(macros[i]) then return end end
        
        
        Log("closed by a click outside")
        W:Close()
    elseif W:IsOpen() and type(W.unit) == "string" then
        
        local u = W.unit
        local targetish = u == "target" or u == "targettarget"
        local groupish = u:find("^party") or u:find("^raid")
        if (event == "PLAYER_TARGET_CHANGED" and targetish) or (event == "GROUP_ROSTER_UPDATE" and groupish) then
            W:Close()
        end
    end
end)

if ThugUI.CombatClose then
    ThugUI.CombatClose:Register("unitmenu", function() return W:IsOpen() end,
        function() W:Close() end, { reopenInCombat = true })
end

if UISpecialFrames then
    tinsert(UISpecialFrames, "ThugUI_UnitMenu")
end

NewColumn(1):SetScript("OnHide", function()
    if columns[2] then columns[2]:Hide() end
    W.subOf = nil
    ReleaseMacros()
end)
