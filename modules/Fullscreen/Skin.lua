













local ThugUI = _G.ThugUI
local FS = ThugUI.Fullscreen or {}
ThugUI.Fullscreen = FS

local S = {}
FS.Skin = S

S.THEME = "ironember"

S.used = {}

local ROOT = "Interface\\AddOns\\ThugUI\\media\\fullscreen\\"



function S.Path(id)
    return ROOT .. S.THEME .. "\\" .. id
end

local function Log(message, ...)
    if ThugUI.Diagnostics then
        ThugUI.Diagnostics:Log("FULLSCREEN", message, ...)
    end
end


function S.Enabled()
    local c = ThugUIDB and ThugUIDB.Fullscreen
    return not c or c.skin ~= false
end









local SPEC = {}
S.SPEC = SPEC

local function Add(ids, spec)
    for id in ids:gmatch("%S+") do
        local copy = {}
        for k, v in pairs(spec) do
            copy[k] = v
        end
        SPEC[id] = copy
    end
end

Add("bg_screen bg_panel", { kind = "tile", w = 512, h = 512 })
Add("bg_well", { kind = "tile", w = 256, h = 256 })
Add("bg_doll_scene", { kind = "cover", w = 1024, h = 1024 })
Add("frame_panel", { kind = "nine", w = 256, h = 256, m = { 48, 48, 48, 48 }, tiled = true })
Add("frame_inset", { kind = "nine", w = 64, h = 64, m = { 16, 16, 16, 16 } })
Add("frame_doll", { kind = "nine", w = 128, h = 128, m = { 32, 32, 32, 32 }, tiled = true })
Add("frame_region_focus", { kind = "nine", w = 64, h = 64, m = { 24, 24, 24, 24 }, blend = "ADD" })
Add("cmp_prompt_block", { kind = "nine", w = 256, h = 256, m = { 48, 48, 48, 48 } })
Add("frame_divider", { kind = "three", w = 256, h = 32, m = { 48, 0, 48, 0 }, tiled = true, art = { 0, 4, 256, 24 } })
Add("orn_title_plate", { kind = "three", w = 512, h = 128, m = { 96, 0, 96, 0 }, art = { 0, 24, 512, 80 } })
Add("orn_subtitle_plate", { kind = "three", w = 256, h = 64, m = { 48, 0, 48, 0 }, art = { 0, 4, 256, 56 } })
Add("orn_nameplate", { kind = "three", w = 512, h = 128, m = { 48, 0, 48, 0 }, art = { 0, 8, 512, 112 } })
Add("cmp_tab_normal cmp_tab_active", { kind = "three", w = 256, h = 128, m = { 32, 0, 32, 0 }, art = { 0, 28, 256, 72 } })
Add("cmp_menu_row_normal cmp_menu_row_focused cmp_menu_row_disabled cmp_menu_row_danger cmp_menu_row_danger_focused",
    { kind = "three", w = 1024, h = 128, m = { 48, 0, 48, 0 }, art = { 0, 20, 1024, 88 } })
Add("cmp_message_banner", { kind = "three", w = 512, h = 128, m = { 48, 0, 48, 0 }, art = { 0, 32, 512, 64 } })
Add("cmp_footer_bar", { kind = "three", w = 512, h = 64, m = { 48, 0, 48, 0 }, art = { 0, 4, 512, 56 } })
Add("cmp_category_header_normal cmp_category_header_focused",
    { kind = "three", w = 512, h = 64, m = { 48, 0, 48, 0 }, art = { 0, 8, 512, 48 } })
Add("cmp_hint_chip_normal cmp_hint_chip_thin cmp_hint_chip_disabled",
    { kind = "three", w = 512, h = 128, m = { 64, 0, 32, 0 }, art = { 0, 32, 512, 64 } })
Add("cmp_list_row_normal cmp_list_row_alternate cmp_list_row_focused",
    { kind = "three", w = 512, h = 64, m = { 24, 0, 24, 0 }, art = { 0, 4, 512, 56 } })
Add("cmp_progress_bar_track cmp_progress_bar_fill",
    { kind = "three", w = 512, h = 64, m = { 32, 0, 32, 0 }, art = { 0, 12, 512, 40 } })
Add("cmp_scrollbar_track cmp_scrollbar_thumb", { kind = "three", w = 32, h = 256, m = { 0, 24, 0, 24 } })
Add("cmp_cell cmp_cell_quality cmp_cell_selected cmp_cell_unavailable cmp_cell_new", { kind = "fixed", w = 128, h = 128 })
Add("cmp_cell_focus", { kind = "fixed", w = 256, h = 256, art = { 32, 32, 192, 192 }, blend = "ADD" })
Add("orn_crest", { kind = "fixed", w = 256, h = 256, art = { 32, 32, 192, 192 } })
Add("orn_divider_jewel", { kind = "fixed", w = 128, h = 64, art = { 24, 12, 80, 40 } })
Add("orn_corner", { kind = "fixed", w = 128, h = 128, art = { 0, 0, 96, 96 }, anchor = { 24, 24 } })
Add("orn_emblems", { kind = "atlas", w = 512, h = 512, cell = 128 })
Add("icon_sheet cmp_cell_badges", { kind = "atlas", w = 256, h = 256, cell = 64 })


function S.AllIds()
    local list = {}
    for id in pairs(SPEC) do
        list[#list + 1] = id
    end
    table.sort(list)
    return list
end





local exists = {}
S.exists = exists


local function Probe()
    if not S.probe then
        local frame = CreateFrame("Frame", nil, UIParent)
        S.probe = frame:CreateTexture(nil, "BACKGROUND")
    end
    return S.probe
end





function S.Exists(id)
    if exists[id] ~= nil then
        return exists[id]
    end
    local ok, result = pcall(function()
        local tex = Probe()
        local set = tex:SetTexture(S.Path(id))
        if set == false then
            return false
        end
        return tex:GetTexture() ~= nil
    end)
    local found = ok and result and true or false
    exists[id] = found
    if not found then
        Log("skin missing %s", id)
    end
    return found
end


function S.Reset()
    for k in pairs(exists) do
        exists[k] = nil
    end
    S.logged = nil
end





local Piece = {}
Piece.__index = Piece

local function Texture(parent, layer, sub)
    return parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
end



local function SliceAvailable(tex)
    if S.sliceAPI ~= nil then
        return S.sliceAPI
    end
    return type(tex.SetTextureSliceMargins) == "function"
end






S.MARGIN_UNIT = "image pixels (delivery pixels, unscaled)"
local function LogMarginUnit()
    if not S.logged then
        S.logged = true
        Log("skin slice margins passed as %s", S.MARGIN_UNIT)
    end
end




function S.Piece(parent, id, layer, sub)
    if not S.Enabled() then
        return nil
    end
    local spec = SPEC[id]
    if not spec then
        return nil
    end
    S.used[id] = true
    if not S.Exists(id) then
        return nil
    end
    local ok, piece = pcall(function()
        local p = setmetatable({ id = id, spec = spec, parent = parent, layer = layer, sub = sub, parts = {} }, Piece)
        p:Build()
        return p
    end)
    if not ok then
        Log("skin piece %s failed: %s", id, tostring(piece))
        return nil
    end
    return piece
end

function Piece:Build()
    local spec = self.spec
    local first = Texture(self.parent, self.layer, self.sub)
    first:SetTexture(S.Path(self.id))
    self.parts[1] = first
    if spec.blend then
        first:SetBlendMode(spec.blend)
    end
    if spec.kind == "tile" then
        first:SetTexture(S.Path(self.id), "REPEAT", "REPEAT")
        pcall(first.SetHorizTile, first, true)
        pcall(first.SetVertTile, first, true)
    elseif spec.kind == "nine" or spec.kind == "three" then
        self:Slice(first)
    end
end


function Piece:Slice(tex)
    local spec = self.spec
    local m = spec.m
    self.margins = m
    if SliceAvailable(tex) then
        LogMarginUnit()
        local okM = pcall(tex.SetTextureSliceMargins, tex, m[1], m[2], m[3], m[4])
        if okM then
            
            
            local mode = spec.tiled and Enum and Enum.UITextureSliceMode and Enum.UITextureSliceMode.Tiled or nil
            if mode ~= nil then
                pcall(tex.SetTextureSliceMode, tex, mode)
            end
            self.sliced = true
            return
        end
    end
    self.sliced = false
    self:BuildNine(tex)
end




function Piece:BuildNine(first)
    local spec = self.spec
    local l, t, r, b = spec.m[1], spec.m[2], spec.m[3], spec.m[4]
    local w, h = spec.w, spec.h
    local u0, u1, u2, u3 = 0, l / w, 1 - r / w, 1
    local v0, v1, v2, v3 = 0, t / h, 1 - b / h, 1
    
    local cuts = {
        { u0, u1 }, { u1, u2 }, { u2, u3 },
    }
    local rows = {
        { v0, v1 }, { v1, v2 }, { v2, v3 },
    }
    self.nine = {}
    for row = 1, 3 do
        for col = 1, 3 do
            local tex = (row == 1 and col == 1) and first or Texture(self.parent, self.layer, self.sub)
            tex:SetTexture(S.Path(self.id))
            tex:SetTexCoord(cuts[col][1], cuts[col][2], rows[row][1], rows[row][2])
            if spec.blend then
                tex:SetBlendMode(spec.blend)
            end
            self.nine[row * 3 + col - 3] = tex
            if not (row == 1 and col == 1) then
                self.parts[#self.parts + 1] = tex
            end
        end
    end
end

local function Half(n)
    return n / 2
end




function Piece:Fill(frame, left, top, right, bottom)
    left, top, right, bottom = left or 0, top or 0, right or 0, bottom or 0
    local spec = self.spec
    local art = spec.art or { 0, 0, spec.w, spec.h }
    local padL, padT = Half(art[1]), Half(art[2])
    local padR, padB = Half(spec.w - art[1] - art[3]), Half(spec.h - art[2] - art[4])
    local x1, y1 = -left - padL, top + padT
    local x2, y2 = right + padR, -bottom - padB
    self.frame = frame
    if self.nine then
        
        local l, t, r, b = Half(spec.m[1]), Half(spec.m[2]), Half(spec.m[3]), Half(spec.m[4])
        local n = self.nine
        for _, tex in ipairs(n) do
            tex:ClearAllPoints()
        end
        n[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", x1, y1)
        n[1]:SetSize(l, t)
        n[3]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", x2, y1)
        n[3]:SetSize(r, t)
        n[7]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x1, y2)
        n[7]:SetSize(l, b)
        n[9]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", x2, y2)
        n[9]:SetSize(r, b)
        n[2]:SetPoint("TOPLEFT", n[1], "TOPRIGHT", 0, 0)
        n[2]:SetPoint("BOTTOMRIGHT", n[3], "BOTTOMLEFT", 0, 0)
        n[4]:SetPoint("TOPLEFT", n[1], "BOTTOMLEFT", 0, 0)
        n[4]:SetPoint("BOTTOMRIGHT", n[7], "TOPRIGHT", 0, 0)
        n[6]:SetPoint("TOPLEFT", n[3], "BOTTOMLEFT", 0, 0)
        n[6]:SetPoint("BOTTOMRIGHT", n[9], "TOPRIGHT", 0, 0)
        n[8]:SetPoint("TOPLEFT", n[7], "TOPRIGHT", 0, 0)
        n[8]:SetPoint("BOTTOMRIGHT", n[9], "TOPLEFT", 0, 0)
        n[5]:SetPoint("TOPLEFT", n[1], "BOTTOMRIGHT", 0, 0)
        n[5]:SetPoint("BOTTOMRIGHT", n[9], "TOPLEFT", 0, 0)
        return self
    end
    local tex = self.parts[1]
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", x1, y1)
    tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", x2, y2)
    return self
end




function Piece:Tile(w, h)
    local unit = Half(self.spec.w)
    local unitV = Half(self.spec.h)
    self.parts[1]:SetTexCoord(0, w / unit, 0, h / unitV)
    return self
end



function Piece:Cover(w, h)
    local aspect = (w > 0 and h > 0) and (w / h) or 1
    local l, r, t, b = 0, 1, 0, 1
    if aspect > 1 then
        local keep = 1 / aspect
        t, b = (1 - keep) / 2, 1 - (1 - keep) / 2
    else
        local keep = aspect
        l, r = (1 - keep) / 2, 1 - (1 - keep) / 2
    end
    self.parts[1]:SetTexCoord(l, r, t, b)
    return self
end




function Piece:Place(point, rel, relPoint, x, y, scale)
    local spec = self.spec
    scale = scale or 1
    local tex = self.parts[1]
    tex:ClearAllPoints()
    tex:SetSize(Half(spec.w) * scale, Half(spec.h) * scale)
    tex:SetPoint(point, rel, relPoint or point, x or 0, y or 0)
    return self
end



function Piece:Fit(frame, size)
    return self:Place("CENTER", frame, "CENTER", 0, 0, size / 64)
end




function Piece:Corner(frame, which, scale)
    scale = scale or 1
    local spec = self.spec
    local tex = self.parts[1]
    local ax, ay = Half(spec.anchor[1]) * scale, Half(spec.anchor[2]) * scale
    local flipX = which == "TOPRIGHT" or which == "BOTTOMRIGHT"
    local flipY = which == "BOTTOMLEFT" or which == "BOTTOMRIGHT"
    tex:ClearAllPoints()
    tex:SetSize(Half(spec.w) * scale, Half(spec.h) * scale)
    tex:SetPoint(which, frame, which, (flipX and 1 or -1) * ax, (flipY and -1 or 1) * ay)
    tex:SetTexCoord(flipX and 1 or 0, flipX and 0 or 1, flipY and 1 or 0, flipY and 0 or 1)
    self.mirror = { flipX, flipY }
    return self
end



function Piece:Cell(index, columns)
    columns = columns or (self.spec.w / self.spec.cell)
    local col, row = (index - 1) % columns, math.floor((index - 1) / columns)
    local size = 1 / columns
    self.parts[1]:SetTexCoord(col * size, (col + 1) * size, row * size, (row + 1) * size)
    self.cellIndex = index
    return self
end


function Piece:SetState(id)
    if id == self.id then
        return true
    end
    if not SPEC[id] then
        return false
    end
    S.used[id] = true
    if not S.Exists(id) then
        return false
    end
    self.id = id
    for _, tex in ipairs(self.parts) do
        tex:SetTexture(S.Path(id))
    end
    return true
end



function Piece:SetSize(w, h)
    self.parts[1]:SetSize(w, h)
    return self
end

function Piece:SetShown(shown)
    shown = shown and true or false
    self.shown = shown
    for _, tex in ipairs(self.parts) do
        tex:SetShown(shown)
    end
end

function Piece:Show()
    self:SetShown(true)
end

function Piece:Hide()
    self:SetShown(false)
end

function Piece:SetTint(r, g, b, a)
    self.tint = { r, g, b, a }
    for _, tex in ipairs(self.parts) do
        tex:SetVertexColor(r, g, b, a or 1)
    end
end

function Piece:SetAlpha(a)
    for _, tex in ipairs(self.parts) do
        tex:SetAlpha(a)
    end
end



function S.InGameHeight(id)
    local spec = SPEC[id]
    if not spec then
        return 0
    end
    local art = spec.art or { 0, 0, spec.w, spec.h }
    return art[4] / 2
end





local CAP = 12




function S.Scrollbar(parent)
    local track = S.Piece(parent, "cmp_scrollbar_track", "ARTWORK", 1)
    local thumb = S.Piece(parent, "cmp_scrollbar_thumb", "ARTWORK", 2)
    if not track or not thumb then
        return nil
    end
    local bar = { track = track, thumb = thumb, parent = parent, height = 0 }
    function bar:Anchor(frame, x, y, height)
        self.frame, self.height = frame, height
        self.holder = self.holder or CreateFrame("Frame", nil, frame)
        self.holder:ClearAllPoints()
        self.holder:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
        self.holder:SetSize(12, height)
        track:Fill(self.holder)
        thumb:Fill(self.holder, 0, 0, 0, -(height - CAP * 2))
    end
    
    function bar:Update(first, visible, total)
        if not self.holder then
            return
        end
        if total <= visible or total <= 0 then
            self.holder:Hide()
            track:Hide()
            thumb:Hide()
            self.shownThumb = nil
            return
        end
        self.holder:Show()
        track:Show()
        thumb:Show()
        local h = self.height
        local size = math.max(CAP * 2, h * visible / total)
        local most = total - visible
        local at = (h - size) * math.max(0, math.min(1, first / most))
        self.thumbHeight, self.thumbY = size, at
        thumb:Fill(self.holder, 0, -at, 0, -(h - at - size))
    end
    return bar
end

return S
