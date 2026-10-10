
























local ThugUI = _G.ThugUI
local T = {}
ThugUI.Theme = T

local DEFAULTS = {
    
    windowTitle     = { 0.0, 1.0, 0.8, 1 },     
    windowVersion   = { 0.5, 0.5, 0.5, 1 },
    background      = { 0.04, 0.04, 0.06, 0.96 },
    border          = { 1, 1, 1, 1 },
    pageTitle       = { 1.0, 0.82, 0.0, 1 },
    pageContext     = { 0.5, 0.5, 0.5, 1 },     
    headerLabel     = { 1.0, 0.82, 0.0, 1 },    
    
    navCategory     = { 1.0, 0.82, 0.0, 1 },
    navPage         = { 0.75, 0.75, 0.75, 1 },
    navNested       = { 0.5, 0.5, 0.5, 1 },
    navSelected     = { 1, 1, 1, 1 },
    navGlyph        = { 1.0, 0.82, 0.0, 1 },
    navAccent       = { 0.0, 1.0, 0.8, 0.9 },
    selectedFill    = { 1, 1, 1, 0.08 },
    highlight       = { 1, 1, 1, 0.10 },
    
    tab             = { 0.75, 0.75, 0.75, 1 },
    tabSelected     = { 1.0, 0.82, 0.0, 1 },
    subTab          = { 0.75, 0.75, 0.75, 1 },
    subTabSelected  = { 1.0, 0.82, 0.0, 1 },
    tabFill         = { 1, 1, 1, 0.05 },
    tabSelectedFill = { 1, 1, 1, 0.12 },
    tabHighlight    = { 1, 1, 1, 0.08 },
    tabAccent       = { 0.0, 1.0, 0.8, 0.9 },
    
    ruleHeader      = { 0.4, 0.4, 0.4, 0.4 },   
    ruleSidebar     = { 0.4, 0.4, 0.4, 0.4 },   
    ruleTabs        = { 0.4, 0.4, 0.4, 0.4 },   
    ruleSubTabs     = { 0.4, 0.4, 0.4, 0.4 },   
    ruleSection     = { 0.5, 0.5, 0.5, 0.5 },
    ruleFrameSection = { 1.0, 0.82, 0.0, 1 },
    frameSectionDivider = { 1, 1, 1, 1 },      
    ruleGroup       = { 0.5, 0.5, 0.5, 0.35 },
    
    section         = { 1.0, 0.82, 0.0, 1 },
    frameSectionFill = { 1, 1, 1, 0.04 },
    
    partLayout      = { 0.45, 0.78, 1.0, 1 },   
    partVisibility  = { 0.78, 0.62, 1.0, 1 },   
    partAppearance  = { 1.0, 0.66, 0.30, 1 },   
    partContent     = { 0.45, 0.92, 0.55, 1 },  
    group           = { 0.85, 0.85, 0.85, 1 },  
    
    label           = { 1, 1, 1, 1 },
    value           = { 1, 1, 1, 1 },
    note            = { 0.5, 0.5, 0.5, 1 },
    disabled        = { 0.5, 0.5, 0.5, 1 },
    warning         = { 1.0, 0.35, 0.35, 1 },
    accent          = { 0.0, 1.0, 0.8, 0.9 },
    searchOutline   = { 1.0, 0.82, 0.0, 1 },
    
    controlFill     = { 0.1, 0.1, 0.1, 0.9 },
    controlBorder   = { 0.3, 0.3, 0.3, 1 },
    controlHighlight = { 1, 1, 1, 0.1 },
    listTitle       = { 1.0, 0.82, 0.0, 1 },
    listItem        = { 1, 1, 1, 1 },
    swatchBorder    = { 0.4, 0.4, 0.4, 1 },
    listBackground  = { 0, 0, 0, 0.95 },
    listBorder      = { 0.5, 0.5, 0.5, 0.9 },
    link            = { 1, 0.13, 0.13, 1 },
    linkHover       = { 1, 0.45, 0.45, 1 },
    
    ruleCategory    = { 0.45, 0.45, 0.5, 0.8 },
    tileFill        = { 0.10, 0.10, 0.12, 0.95 },
    tileHighlight   = { 1, 1, 1, 0.06 },
    tileTitle       = { 1.0, 0.82, 0.0, 1 },
    tileDescription = { 1, 1, 1, 1 },
    tileState       = { 1.0, 0.82, 0.0, 1 },
    tileSoonStamp   = { 1, 0.15, 0.15, 1 },
    tileOn          = { 0.25, 0.80, 0.35, 1 },
    tileOff         = { 0.35, 0.35, 0.35, 1 },
    tileSoon        = { 0.35, 0.35, 0.35, 1 },
    tileLocked      = { 0.45, 0.45, 0.55, 1 },
    tilePending     = { 1, 0.82, 0, 1 },
    tileSuspended   = { 0.30, 0.60, 1.00, 1 },
    
    gridFrame       = { 0, 0, 0, 0.55 },
    gridCellBorder  = { 0.35, 0.35, 0.4, 0.5 },
    gridCellFill    = { 0.08, 0.08, 0.10, 0.9 },
    gridSelected    = { 0, 1, 0.8, 0.35 },
    gridDim         = { 0, 0, 0, 0.45 },
    gridMarker      = { 0, 1, 0.8, 1 },
    gridArmed       = { 0, 1, 0.8, 0.25 },
    pickerFill      = { 0, 0, 0, 0.4 },
    pickerBorder    = { 0.3, 0.3, 0.3, 0.6 },
    guideHighlight  = { 1, 0.85, 0.1, 1 },
    guideGlow       = { 1, 0.85, 0.25, 1 },
}
T.DEFAULTS = DEFAULTS


T.PART_ROLE = {
    ["Size & position"] = "partLayout",
    ["Visibility"] = "partVisibility",
    ["Appearance"] = "partAppearance",
    ["Content"] = "partContent",
}

local colors = DEFAULTS
local registry = setmetatable({}, { __mode = "k" })   













local MODS_DEFAULT = { textTint = 0.2, groupShade = 0.4, nestedShade = 0.4 }
T.MODS_DEFAULT = MODS_DEFAULT
local mods = { textTint = 0.2, groupShade = 0.4, nestedShade = 0.4 }

local function Mix(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t, a[4] or 1 }
end

local function Shade(c, k)
    if k >= 0 then return { c[1] + (1 - c[1]) * k, c[2] + (1 - c[2]) * k, c[3] + (1 - c[3]) * k, c[4] or 1 } end
    k = -k
    return { c[1] * (1 - k), c[2] * (1 - k), c[3] * (1 - k), c[4] or 1 }
end
T.Mix, T.Shade = Mix, Shade









local LIFT_MIN = {
    label = 4.5, listItem = 4.5, value = 4.5, navSelected = 4.5, tileDescription = 4.5,
    pageTitle = 3, section = 3, note = 3, pageContext = 3, headerLabel = 3,
    navPage = 3, navNested = 3, navCategory = 3, group = 3,
    tab = 3, tabSelected = 3, subTab = 3, subTabSelected = 3,
    partLayout = 3, partVisibility = 3, partAppearance = 3, partContent = 3,
    listTitle = 3, tileTitle = 3, windowVersion = 3,
}
T.LIFT_MIN = LIFT_MIN
local textSurface = nil

local function Lin(v) if v <= 0.03928 then return v / 12.92 end return ((v + 0.055) / 1.055) ^ 2.4 end
local function Lum(c) return 0.2126 * Lin(c[1]) + 0.7152 * Lin(c[2]) + 0.0722 * Lin(c[3]) end
local function Ratio(a, b)
    local la, lb = Lum(a), Lum(b)
    if la < lb then la, lb = lb, la end
    return (la + 0.05) / (lb + 0.05)
end



local function Lift(c, surface, min)
    if not (c and surface and min) or Ratio(c, surface) >= min then return c end
    local want = min + 0.05
    for i = 1, 40 do
        local l = Shade(c, i / 40)
        if Ratio(l, surface) >= want then return l end
    end
    return { 1, 1, 1, c[4] or 1 }
end
T.Lift = Lift



local function Distinct(a, b)
    local d = math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
    return d >= 0.25 or Ratio(a, b) >= 1.5
end


local LIFT_PAIRS = {
    { "pageTitle", "pageContext" }, { "tabSelected", "tab" }, { "subTabSelected", "subTab" },
    { "navPage", "navNested" }, { "navSelected", "navNested" },
    { "partLayout", "partVisibility" }, { "partLayout", "partAppearance" }, { "partLayout", "partContent" },
    { "partVisibility", "partAppearance" }, { "partVisibility", "partContent" }, { "partAppearance", "partContent" },
}
local function KeepApart(out)
    for _, pr in ipairs(LIFT_PAIRS) do
        local a, b = out[pr[1] ], out[pr[2] ]
        if a and b and not Distinct(a, b) then
            for i = 1, 40 do
                local l = Shade(a, i / 40)
                if Distinct(l, b) then a = l break end
            end
            out[pr[1] ] = a
        end
    end
end



function T:PictureSurface(bg)
    if type(bg) ~= "table" or bg.kind ~= "image" then return nil end
    local c = self:Resolve(bg.color or { 0.04, 0.04, 0.06 }) or { 0.04, 0.04, 0.06 }
    local dim = tonumber(bg.dim) or 0.7
    return { c[1] * dim + 0.5 * (1 - dim), c[2] * dim + 0.5 * (1 - dim), c[3] * dim + 0.5 * (1 - dim) }
end

local function Plain(role)
    local c = colors[role] or DEFAULTS[role]
    if not c then return nil end
    return { c[1], c[2], c[3], c[4] or 1 }
end

local DerivedRaw
local function Derived(role)
    local c = DerivedRaw(role)
    if c and textSurface then
        local base = role:match("^([%w]+):")
        c = Lift(c, textSurface, LIFT_MIN[base])
    end
    return c
end

function DerivedRaw(role)
    local base, parent = role:match("^([%w]+):([%w]+)$")
    if not base then return nil end
    local p = Plain(parent)
    if not p then return nil end
    if base == "group" then
        local c = Shade(p, mods.groupShade)
        c[4] = 1
        return c
    elseif base == "navNested" then
        local page = Mix(Plain("navPage"), p, mods.textTint)
        return Shade(page, -math.abs(mods.nestedShade))
    end
    local b = Plain(base)
    if not b then return nil end
    return Mix(b, p, mods.textTint)
end

function T:IsRole(role)
    return (colors[role] or DEFAULTS[role] or (type(role) == "string" and Derived(role))) and true or false
end

function T:Color(role)
    local c = colors[role] or DEFAULTS[role] or (type(role) == "string" and Derived(role))
    if not c then error("ThugUI.Theme: unknown role " .. tostring(role)) end
    return c[1], c[2], c[3], c[4] or 1
end


function T:Mods() return mods end

local function Apply(obj, role, how)
    local r, g, b, a = T:Color(role)
    if how == "fill" then
        obj:SetColorTexture(r, g, b, a)
    elseif how == "vertex" then
        obj:SetVertexColor(r, g, b, a)
    elseif how == "backdrop" then
        obj:SetBackdropColor(r, g, b, a)
    elseif how == "border" then
        obj:SetBackdropBorderColor(r, g, b, a)
    else
        obj:SetTextColor(r, g, b, a)
    end
end

function T:Paint(obj, role, how)
    if not obj then return obj end
    how = how or "text"
    if not self:IsRole(role) then error("ThugUI.Theme: unknown role " .. tostring(role)) end
    registry[obj] = { role, how }
    Apply(obj, role, how)
    return obj
end


function T:RoleOf(obj)
    local e = registry[obj]
    return e and e[1], e and e[2]
end


function T:SetColors(t, m)
    textSurface = type(t) == "table" and rawget(t, "__surface") or nil
    colors = setmetatable({}, { __index = DEFAULTS })
    for role, c in pairs(t or {}) do
        if DEFAULTS[role] and type(c) == "table" then colors[role] = c end
    end
    for k, v in pairs(MODS_DEFAULT) do
        local x = m and tonumber(m[k])
        mods[k] = x ~= nil and x or v
    end
    for obj, e in pairs(registry) do Apply(obj, e[1], e[2]) end
end

function T:Roles()
    local list = {}
    for role in pairs(DEFAULTS) do list[#list + 1] = role end
    table.sort(list)
    return list
end




















ThugUI.defaults = ThugUI.defaults or {}
ThugUI.defaults.Theme = {
    preset = "default",
    colors = {},            
    background = {
        kind = "color",     
        color = { 0.04, 0.04, 0.06 },
        alpha = 0.96,
        image = "",         
        mode = "cover",     
        imageAlpha = 1,
        tint = { 1, 1, 1 },
        dim = 0.7,          
        zoom = 1,           
        offsetX = 0, offsetY = 0,  
        aspect = 4 / 3,     
    },
    border = "dialog",      
    
    textTint = nil, groupShade = nil, nestedShade = nil,
    windowScale = 1,
    textSize = 1,           
    resizable = false,
}


local QUALITY_FALLBACK = {
    [0] = { 0.616, 0.616, 0.616 }, [1] = { 1, 1, 1 }, [2] = { 0.118, 1, 0 },
    [3] = { 0, 0.439, 0.867 }, [4] = { 0.639, 0.208, 0.933 }, [5] = { 1, 0.502, 0 },
}
local CLASS_FALLBACK = {
    WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 }, HUNTER = { 0.67, 0.83, 0.45 },
    ROGUE = { 1, 0.96, 0.41 }, PRIEST = { 1, 1, 1 }, SHAMAN = { 0, 0.44, 0.87 },
    MAGE = { 0.25, 0.78, 0.92 }, WARLOCK = { 0.53, 0.53, 0.93 }, DRUID = { 1, 0.49, 0.04 },
}
T.QUALITY_FALLBACK, T.CLASS_FALLBACK = QUALITY_FALLBACK, CLASS_FALLBACK

local function Num(v, d) v = tonumber(v) if v == nil then return d end return v end


function T:Resolve(spec)
    if type(spec) ~= "table" then return nil end
    local r, g, b
    if spec.quality ~= nil then
        local q = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[spec.quality]
        if q and q.r then
            r, g, b = q.r, q.g, q.b
        else
            local f = QUALITY_FALLBACK[spec.quality]
            if not f then return nil end
            r, g, b = f[1], f[2], f[3]
        end
    elseif spec.class then
        local c
        if _G.C_ClassColor and _G.C_ClassColor.GetClassColor then
            local ok, cc = pcall(_G.C_ClassColor.GetClassColor, spec.class)
            if ok then c = cc end
        end
        if c and c.r then
            r, g, b = c.r, c.g, c.b
        else
            local f = CLASS_FALLBACK[spec.class]
            if not f then return nil end
            r, g, b = f[1], f[2], f[3]
        end
    elseif type(spec[1]) == "number" then
        r, g, b = spec[1], spec[2] or 0, spec[3] or 0
    else
        return nil
    end
    local mul = Num(spec.mul, 1)
    return { r * mul, g * mul, b * mul, Num(spec.a, Num(spec[4], 1)) }
end

T.presets = {}        
T.presetOrder = {}

function T:RegisterPreset(p)
    if not self.presets[p.id] then self.presetOrder[#self.presetOrder + 1] = p.id end
    self.presets[p.id] = p
end

local function CopyDeep(v)
    if type(v) ~= "table" then return v end
    local c = {}
    for k, vv in pairs(v) do c[k] = CopyDeep(vv) end
    return c
end

function T:Settings()
    if type(ThugUIDB) ~= "table" then return ThugUI.defaults.Theme end
    ThugUIDB.Theme = ThugUIDB.Theme or {}
    local s = ThugUIDB.Theme
    for k, v in pairs(ThugUI.defaults.Theme) do
        if s[k] == nil then s[k] = CopyDeep(v) end
    end
    for k, v in pairs(ThugUI.defaults.Theme.background) do
        if s.background[k] == nil then s.background[k] = CopyDeep(v) end
    end
    return s
end





function T:BuildColors(presetID, own, bg)
    local out = {}
    local p = self.presets[presetID or "default"]
    local surface = self:PictureSurface(bg or (p and p.background))
    for role, spec in pairs(p and p.colors or {}) do
        local c = self:Resolve(spec)
        if c and DEFAULTS[role] then
            if surface and LIFT_MIN[role] then c = Lift(c, surface, LIFT_MIN[role]) end
            out[role] = c
        end
    end
    if surface then KeepApart(out) end
    for role, spec in pairs(own or {}) do
        local c = self:Resolve(spec)
        if c and DEFAULTS[role] then out[role] = c end
    end
    out.__surface = surface
    return out
end



function T:BuildMods(presetID, s)
    local p = self.presets[presetID or "default"]
    local pm = p and p.mods or {}
    local out = {}
    for k, v in pairs(MODS_DEFAULT) do
        local own = s and tonumber(s[k])
        out[k] = own ~= nil and own or (tonumber(pm[k]) or v)
    end
    return out
end

function T:ApplySaved()
    local s = self:Settings()
    self:SetColors(self:BuildColors(s.preset, s.colors, s.background), self:BuildMods(s.preset, s))
    if self.SetTextScale then self:SetTextScale(tonumber(s.textSize) or 1) end
    local f = ThugUI.Window and ThugUI.Window.frame
    if f then self:ApplyChrome(f) end
end



function T:UsePreset(id)
    local p = self.presets[id]
    if not p then return false end
    local s = self:Settings()
    s.preset = id
    s.savedTheme = nil
    s.colors = {}
    s.textTint, s.groupShade, s.nestedShade = nil, nil, nil
    local bg = CopyDeep(ThugUI.defaults.Theme.background)
    for k, v in pairs(p.background or {}) do bg[k] = CopyDeep(v) end
    s.background = bg
    s.border = p.border or "dialog"
    self:ApplySaved()
    return true
end


T.BORDERS = {
    { value = "dialog", text = "Dialog (Blizzard's panel edge)",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, inset = 6 },
    { value = "tooltip", text = "Tooltip edge",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, inset = 4 },
    { value = "thin", text = "Thin line",
      edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, inset = 1 },
    { value = "none", text = "None", inset = 0 },
}
function T:BorderDef(style)
    for _, b in ipairs(T.BORDERS) do if b.value == style then return b end end
    return T.BORDERS[1]
end




function T.ImageCoords(mode, aspect, w, h, zoom, ox, oy)
    if mode ~= "cover" or not (w and h and h > 0 and aspect and aspect > 0) then
        return 0, 1, 0, 1
    end
    local frameAspect = w / h
    local spanX, spanY = 1, 1
    if frameAspect > aspect then
        spanY = aspect / frameAspect      
    else
        spanX = frameAspect / aspect      
    end
    zoom = math.max(1, math.min(2, Num(zoom, 1)))
    spanX, spanY = spanX / zoom, spanY / zoom
    local function Place(span, offset)
        local free = 1 - span
        local start = free / 2 + (math.max(-1, math.min(1, Num(offset, 0))) * free / 2)
        return start, start + span
    end
    local l, r = Place(spanX, ox)
    local t, b = Place(spanY, -(Num(oy, 0)))
    return l, r, t, b
end



local function FitInsets(aspect, w, h)
    if not (w and h and h > 0 and aspect and aspect > 0) then return 0, 0 end
    if w / h > aspect then
        return (w - h * aspect) / 2, 0
    end
    return 0, (h - w / aspect) / 2
end








function T:Picks()
    _G.ThugUI_Packs = _G.ThugUI_Packs or {}
    _G.ThugUI_Packs.gallery = _G.ThugUI_Packs.gallery or {}
    return _G.ThugUI_Packs.gallery
end


function T:AddGalleryImage(name, file, kind)
    if file == nil then return false end
    local picks = self:Picks()
    for _, e in ipairs(picks) do if e.file == file then return false end end
    picks[#picks + 1] = { name = tostring(name or file), file = file, kind = kind }
    
    
    return true
end

function T:RemoveGalleryImage(file)
    local picks = self:Picks()
    for i = #picks, 1, -1 do if picks[i].file == file then table.remove(picks, i) end end
end


function T:GalleryAll()
    local out = {}
    for _, g in ipairs(T.GALLERY or {}) do out[#out + 1] = g end
    for _, e in ipairs(self:Picks()) do
        out[#out + 1] = { name = e.name, file = e.file, kind = e.kind, pick = true }
    end
    return out
end


function T:UseBackgroundImage(file)
    local bg = self:Settings().background
    bg.kind, bg.image, bg.aspect = "image", file, 4 / 3
    self:ApplySaved()
    if ThugUI.ThemesPage and ThugUI.ThemesPage.RefreshGallery then ThugUI.ThemesPage:RefreshGallery() end
end

T.IMAGE_SUBLEVEL = 1


function T:ApplyChrome(f)
    local s = self:Settings()
    local bg = s.background or {}
    local def = self:BorderDef(s.border)
    local inset = def.inset or 0
    
    local hasImage = bg.kind == "image" and ((type(bg.image) == "string" and bg.image ~= "") or type(bg.image) == "number")
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = def.edgeFile,
            tile = false, edgeSize = def.edgeSize or 0,
            insets = { left = inset, right = inset, top = inset, bottom = inset },
        })
    end
    
    
    local c = self:Resolve(bg.color) or { 0.04, 0.04, 0.06, 1 }
    colors = colors == DEFAULTS and setmetatable({}, { __index = DEFAULTS }) or colors
    colors.background = { c[1], c[2], c[3], Num(bg.alpha, 0.96) }
    self:Paint(f, "background", "backdrop")
    self:Paint(f, "border", "border")

    if not f.bgImage then
        f.bgImage = f:CreateTexture(nil, "BACKGROUND")
        f.bgDim = f:CreateTexture(nil, "BACKGROUND")
    end
    local img, dim = f.bgImage, f.bgDim
    
    
    
    
    
    
    img:SetDrawLayer("BACKGROUND", T.IMAGE_SUBLEVEL)
    dim:SetDrawLayer("BACKGROUND", T.IMAGE_SUBLEVEL + 1)
    if hasImage then
        local w, h = (f:GetWidth() or 0) - inset * 2, (f:GetHeight() or 0) - inset * 2
        local fx, fy = 0, 0
        if bg.mode == "fit" then fx, fy = FitInsets(Num(bg.aspect, 4 / 3), w, h) end
        img:ClearAllPoints()
        img:SetPoint("TOPLEFT", f, "TOPLEFT", inset + fx, -(inset + fy))
        img:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(inset + fx), inset + fy)
        img:SetTexture(bg.image)
        img:SetTexCoord(T.ImageCoords(bg.mode, Num(bg.aspect, 4 / 3), w, h, bg.zoom, bg.offsetX, bg.offsetY))
        local tint = self:Resolve(bg.tint) or { 1, 1, 1, 1 }
        img:SetVertexColor(tint[1], tint[2], tint[3]) 
        img:SetAlpha(Num(bg.imageAlpha, 1))
        img:Show()
        dim:ClearAllPoints()
        dim:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
        dim:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
        dim:SetColorTexture(c[1], c[2], c[3], Num(bg.dim, 0.7)) 
        dim:Show()
    else
        img:Hide()
        dim:Hide()
    end
end




local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local ok, err = pcall(T.ApplySaved, T)
    if not ok and ThugUI.Diagnostics then ThugUI.Diagnostics:Log("THEME", "apply at login failed: %s", tostring(err)) end
end)
T.loginFrame = loginFrame










local fonts, fontBase = {}, {}
local textScale = 1
T.TEXT_MIN, T.TEXT_MAX = 0.8, 1.25

local function ScaleFont(name)
    local fo, b = fonts[name], fontBase[name]
    if fo and b and type(b[2]) == "number" then fo:SetFont(b[1], b[2] * textScale, b[3]) end
end


function T:Font(name)
    if fonts[name] then return "ThugUI_" .. name end
    if not (CreateFont and _G[name]) then return name end
    local fo = CreateFont("ThugUI_" .. name)
    fo:CopyFontObject(_G[name])
    fontBase[name] = { fo:GetFont() }
    fonts[name] = fo
    ScaleFont(name)
    return "ThugUI_" .. name
end

function T:SetTextScale(k)
    k = tonumber(k) or 1
    if k < T.TEXT_MIN then k = T.TEXT_MIN elseif k > T.TEXT_MAX then k = T.TEXT_MAX end
    textScale = k
    for name in pairs(fonts) do ScaleFont(name) end
end

function T:TextScale() return textScale end









local function Copy(v)
    if type(v) ~= "table" then return v end
    local c = {}
    for k, vv in pairs(v) do c[k] = Copy(vv) end
    return c
end

function T:SavedThemes()
    _G.ThugUI_Packs = _G.ThugUI_Packs or {}
    _G.ThugUI_Packs.themes = _G.ThugUI_Packs.themes or {}
    return _G.ThugUI_Packs.themes
end

function T:SavedThemeNames()
    local names = {}
    for name in pairs(self:SavedThemes()) do names[#names + 1] = name end
    table.sort(names)
    return names
end


function T:SaveTheme(name)
    if type(name) ~= "string" or name:match("^%s*$") then return false end
    local s = self:Settings()
    self:SavedThemes()[name] = {
        preset = s.preset, colors = Copy(s.colors), background = Copy(s.background), border = s.border,
        textTint = s.textTint, groupShade = s.groupShade, nestedShade = s.nestedShade, textSize = s.textSize,
    }
    return true
end

function T:UseSavedTheme(name)
    local t = self:SavedThemes()[name]
    if not t then return false end
    local s = self:Settings()
    s.preset, s.colors, s.background, s.border = t.preset or "default", Copy(t.colors or {}), Copy(t.background or {}), t.border or "dialog"
    s.textTint, s.groupShade, s.nestedShade, s.textSize = t.textTint, t.groupShade, t.nestedShade, t.textSize
    
    for k, v in pairs(ThugUI.defaults.Theme.background) do
        if s.background[k] == nil then s.background[k] = Copy(v) end
    end
    s.savedTheme = name
    self:ApplySaved()
    return true
end

function T:DeleteSavedTheme(name)
    self:SavedThemes()[name] = nil
    local s = self:Settings()
    if s.savedTheme == name then s.savedTheme = nil end
end
