








ThugUI = ThugUI or {}

local PS = {}
ThugUI.PadSilhouette = PS

PS.WIDTH, PS.HEIGHT = 1024, 512

local XBOX, PLAYSTATION = "xbox", "playstation"
local PARTS = {
    "body", "face_top", "face_right", "face_bottom", "face_left",
    "dpad_up", "dpad_right", "dpad_down", "dpad_left", "l1", "r1",
    "l2", "r2", "start", "select", "share", "logo", "touchpad",
    "lstick", "rstick",
}



local TABS = {
    [1] = {
        slots = { face_top = "top", face_right = "right", face_bottom = "bottom", face_left = "left" },
    },
    [2] = {
        left = { slots = { dpad_right = "l1right" }, held = { l1 = true } },
        right = { slots = { dpad_right = "r1right" }, held = { r1 = true } },
    },
    [3] = {
        slots = {
            face_top = "l1r1top", face_right = "l1r1right", face_left = "l1r1left",
            face_bottom = "cross", dpad_up = "l1r1up", dpad_down = "l1r1down",
        },
        held = { l1 = true, r1 = true },
    },
    [4] = {
        slots = { start = "start", select = "view", share = "share", logo = "logo", touchpad = "touchpad" },
    },
}
PS.TABS = TABS

local NEEDS_CONTROLLER = { select = true, share = true, touchpad = true }
local DIM_ALPHA, HELD_ALPHA = 0.42, 0.6

local function Paint(texture, role)
    return ThugUI.Theme:Paint(texture, role, "vertex")
end

local function TabSpec(tab, side)
    local spec = TABS[tab]
    if not spec then return nil end
    if tab == 2 then return spec[side == "right" and "right" or "left"] end
    return spec
end

local function PartTitle(part)
    local titles = {
        face_top = "Top face button", face_right = "Right face button", face_bottom = "Bottom face button",
        face_left = "Left face button", dpad_up = "D-pad up", dpad_right = "D-pad right",
        dpad_down = "D-pad down", start = "Start", select = "Create / View", share = "Mute / Share",
        logo = "Logo button", touchpad = "Touchpad", l1 = "L1 / LB", r1 = "R1 / RB",
    }
    return titles[part] or part
end

local function ShowTooltip(f, part)
    local title, line = f.titles[part] or PartTitle(part), nil
    if f.needsPad and NEEDS_CONTROLLER[part] then
        line = "Needs your controller"
    elseif not f.editable[part] then
        line = f.held[part] and "Held" or "Not edited on this tab"
    elseif f.captions[part] and f.captions[part] ~= "" then
        line = f.captions[part]
    end
    GameTooltip:SetOwner(f.hotspots[part], "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if line then GameTooltip:AddLine(line, 0.8, 0.8, 0.8, true) end
    GameTooltip:Show()
end

function PS:Build(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(640, 320)
    f.kind, f.tab, f.side = PLAYSTATION, 1, nil
    f.selected, f.needsPad = nil, false
    f.textures, f.hotspots, f.outlines = {}, {}, {}
    f.editable, f.held, f.badges, f.captions = {}, {}, {}, {}
    f.titles, f.tooltipLines = {}, {}

    
    for _, part in ipairs(PARTS) do
        local texture = f:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(f)
        f.textures[part] = texture
    end

    local onSelect, onDoubleClick

    local function ResizeBox(frame, box, inset)
        inset = inset or 0
        local scale = f:GetWidth() / PS.WIDTH
        frame:SetSize((box.w - inset * 2) * scale, (box.h - inset * 2) * scale)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", f, "TOPLEFT", (box.x + inset) * scale, -(box.y + inset) * scale)
    end

    local function Outline(part, show)
        local outline = f.outlines[part]
        if outline then outline:SetShown(show) end
    end

    local function Repaint()
        for _, part in ipairs(PARTS) do
            local texture = f.textures[part]
            if part == "body" then
                Paint(texture, "border")
                texture:SetAlpha(1)
            elseif f.editable[part] then
                Paint(texture, "accent")
                texture:SetAlpha(1)
            elseif f.held[part] then
                Paint(texture, "accent")
                texture:SetAlpha(HELD_ALPHA)
            else
                Paint(texture, "disabled")
                texture:SetAlpha(DIM_ALPHA)
            end
            local hot = f.hotspots[part]
            if hot then
                hot.live = f.editable[part] and not (part == "touchpad" and f.kind == XBOX) and not (f.needsPad and NEEDS_CONTROLLER[part])
                hot.dim = f.needsPad and NEEDS_CONTROLLER[part] and "pad" or nil
                hot.badgeOn = f.badges[part] == true
                hot.outlined = f.selected == part and f.editable[part]
                hot:SetShown(hot.live)
                hot:SetAlpha(hot.live and 1 or DIM_ALPHA)
                hot.badge:SetShown(hot.badgeOn and hot:IsShown())
            end
            Outline(part, f.selected == part and f.editable[part])
        end
    end

    local function BuildHotspot(part)
        if f.hotspots[part] then return f.hotspots[part] end
        local hot = CreateFrame("Button", nil, f)
        hot.part = part
        hot:SetScript("OnClick", function()
            if not f.editable[part] or (f.needsPad and NEEDS_CONTROLLER[part]) then return end
            f:SetSelected(part)
            if onSelect then onSelect(part, f.editable[part]) end
        end)
        hot:SetScript("OnDoubleClick", function()
            if f.editable[part] and not (f.needsPad and NEEDS_CONTROLLER[part]) and onDoubleClick then onDoubleClick(part, f.editable[part]) end
        end)
        hot:SetScript("OnEnter", function() ShowTooltip(f, part) end)
        hot:SetScript("OnLeave", function() GameTooltip:Hide() end)
        hot.badge = Paint(hot:CreateFontString(nil, "OVERLAY", ThugUI.Theme:Font("GameFontNormalLarge")), "warning")
        hot.badge:SetText("!")
        hot.badge:SetPoint("TOPRIGHT", hot, "TOPRIGHT", 2, 2)
        hot.badge:Hide()
        f.hotspots[part] = hot

        local outline = CreateFrame("Frame", nil, f)
        outline.edges = {}
        for _, edge in ipairs({
            { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
            { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false },
        }) do
            local line = outline:CreateTexture(nil, "OVERLAY")
            Paint(line, "label")
            line:SetPoint(edge[1])
            line:SetPoint(edge[2])
            if edge[3] then line:SetHeight(2) else line:SetWidth(2) end
            outline.edges[#outline.edges + 1] = line
        end
        outline:Hide()
        f.outlines[part] = outline
        return hot
    end

    local function LayoutBoxes()
        local boxes = ThugUI.PadParts and ThugUI.PadParts[f.kind]
        if not boxes then return end
        for part, hot in pairs(f.hotspots) do
            local box = boxes[part]
            if box then
                ResizeBox(hot, box, 4)
                ResizeBox(f.outlines[part], box)
            end
        end
    end

    function f:SetDisplayWidth(px)
        px = math.max(1, tonumber(px) or 1)
        f:SetSize(px, px / 2)
        LayoutBoxes()
        Repaint()
    end

    function f:SetKind(kind)
        if kind ~= XBOX and kind ~= PLAYSTATION then return false end
        f.kind = kind
        for _, part in ipairs(PARTS) do
            local texture = f.textures[part]
            if part == "touchpad" and kind == XBOX then
                texture:Hide()
            else
                texture:SetTexture("Interface\\AddOns\\ThugUI\\media\\padlayout\\" .. kind .. "\\" .. part)
                texture:Show()
            end
        end
        LayoutBoxes()
        Repaint()
        return true
    end
    function f:GetKind() return f.kind end

    function f:SetTab(tab, side)
        local spec = TabSpec(tab, side)
        if not spec then return false end
        f.tab, f.side = tab, side
        f.editable, f.held = {}, {}
        for part, slot in pairs(spec.slots or {}) do
            if not (part == "touchpad" and f.kind == XBOX) then
                f.editable[part] = slot
                BuildHotspot(part)
            end
        end
        for part in pairs(spec.held or {}) do f.held[part] = true end
        if not f.editable[f.selected] then f.selected = nil end
        LayoutBoxes()
        Repaint()
        return true
    end
    function f:GetTab() return f.tab, f.side end

    
    function f:SetLayer(layer)
        local n = tonumber(tostring(layer):match("%d")) or 1
        return f:SetTab(n)
    end
    function f:GetLayer() return "tab" .. tostring(f.tab) end
    function f:GetPage() return "page1" end

    function f:SetSelected(part)
        if part ~= nil and not f.editable[part] then part = nil end
        f.selected = part
        Repaint()
    end
    function f:GetSelected() return f.selected end

    function f:SetBadge(part, on)
        f.badges[part] = on and true or nil
    end
    function f:SetCaption(part, text) f.captions[part] = text end
    function f:SetTitle(part, text) f.titles[part] = text end
    function f:SetTooltip(part, lines) f.tooltipLines[part] = lines end
    function f:SetNeedsController(on) f.needsPad = on and true or false; Repaint() end
    function f:OnSelect(fn) onSelect = fn end
    function f:Hotspot(part)
        if part == "touchpad" and f.kind == XBOX then return nil end
        return f.hotspots[part]
    end
    function f:Click(part)
        local hot = f.hotspots[part]
        if not hot or not f.editable[part] or (f.needsPad and NEEDS_CONTROLLER[part]) then return false end
        f:SetSelected(part)
        if onSelect then onSelect(part, f.editable[part]) end
        return true
    end
    function f:DoubleClick(part)
        local hot = f:Hotspot(part)
        if not hot or not f.editable[part] or (f.needsPad and NEEDS_CONTROLLER[part]) then return false end
        if onDoubleClick then onDoubleClick(part, f.editable[part]); return true end
        return false
    end
    function f:Tooltip(part)
        if f.needsPad and NEEDS_CONTROLLER[part] then return f.titles[part] or PartTitle(part), { "Needs your controller" } end
        local lines = f.tooltipLines[part] or {}
        if #lines == 0 and f.captions[part] and f.captions[part] ~= "" then lines = { f.captions[part] } end
        return f.titles[part] or PartTitle(part), lines
    end
    function f:OnDoubleClick(fn) onDoubleClick = fn end

    f:SetKind(PLAYSTATION)
    f:SetTab(1)
    return f
end
