





local ThugUI = _G.ThugUI
local RA = {}
ThugUI.RingArt = RA






RA.ART = {
    { "orb",         "Orb rim (matches the orbs)",  "Interface\\AddOns\\ThugUI\\media\\orb\\orb_rim", false },
    { "rune",        "Rune ring",                   165630, true },  
    { "runeb",       "Rune ring B",                 165631, true },  
    { "runea",       "Rune ring A",                 165638, true },  
    { "fade",        "Soft fade ring",              167062, true },  
    { "glow",        "Glow",                        165423, true },  
    { "portal",      "Portal glow",                 197006, true },  
    { "auraruneb2",  "Rune: aura rune B (alt)",     165639, true },  
    { "roguerune",   "Rune: rogue rune",            241004, true },  
    { "naturerune",  "Rune: nature rune",           166606, true },  
    { "whitecircle", "Circle: white circle",        167203, true },  
    { "gradcircle",  "Circle: gradient circle",     132039, false }, 
    { "ping",        "Circle: minimap ping",        136439, false }, 
    { "aura01",      "Circle: aura",                165623, true },  
    { "shockgrey",   "Shockwave: grey",             166870, true },  
    { "shock4",      "Shockwave: 4",                166863, true },  
    { "shockblue",   "Shockwave: blue",             191091, true },  
    { "glow64",      "Glow: small",                 166232, true },  
    { "nether",      "Glow: twisted nether",        197067, true },  
    { "moonglare",   "Glow: moon glare",            186182, true },  
    { "moonglare2",  "Glow: moon glare 2",          186181, true },  
    { "lightning",   "Effect: lightning",           240948, true },  
    { "leaves",      "Effect: treant leaves",       167138, true },  
    { "splash",      "Effect: splash",              220021, true },  
    { "stoneearth",  "Stone: shaman earth",         200026, false }, 
    { "stoneair",    "Stone: shaman air",           200025, false }, 
    { "stonewater",  "Stone: shaman water",         200029, false }, 
    { "stonefire",   "Stone: shaman fire",          200027, false }, 
    { "stones",      "Stone: Eversong stones",      187303, false }, 
    { "vortex",      "Sky: Auchindoun vortex",      130444, true },  
    { "deathvortex", "Sky: death vortex",           235312, true },  
    { "dwclouds",    "Sky: Deathwing clouds",       527512, true },  
    { "dwparticles", "Sky: Deathwing particles",    536776, true },  
    { "icecrown1",   "Sky: Icecrown clouds 1",      130539, true },  
    { "icecrown2",   "Sky: Icecrown clouds 2",      130540, true },  
    { "wintergrasp", "Sky: Wintergrasp clouds",     235378, true },  
    { "worgen",      "Sky: Worgen clouds",          313249, true },  
    { "nebula",      "Sky: Deepholm nebula",        378269, true },  
    { "galaxy",      "Sky: galaxy",                 130505, true },  
    { "planetblue",  "Planet: Hellfire blue",       130521, true },  
    { "planetred",   "Planet: Hellfire red",        130523, true },  
    { "planet3",     "Planet: Hellfire",            130518, true },  
    { "planetbe",    "Planet: Blade's Edge",        130472, true },  
    { "parchment",   "Parchment",                   130662, false }, 
    { "parchmenth",  "Parchment (wide)",            130661, false }, 
}

function RA:Find(key)
    if key then
        for _, row in ipairs(RA.ART) do
            if row[1] == key then
                return row
            end
        end
    end
    return RA.ART[1]
end

function RA:Options()
    local opts = {}
    for _, row in ipairs(RA.ART) do
        table.insert(opts, { text = row[2], value = row[1] })
    end
    return opts
end

RA.BLEND_OPTIONS = {
    { text = "Auto (suits the art)", value = "auto" },
    { text = "Normal", value = "normal" },
    { text = "Additive (black turns clear)", value = "add" },
    { text = "Multiply (darkens)", value = "mod" },
    { text = "Alpha key (hard edge)", value = "alphakey" },
}


function RA:BlendMode(artKey, blend)
    if blend == "add" then return "ADD" end
    if blend == "normal" then return "BLEND" end
    if blend == "mod" then return "MOD" end
    if blend == "alphakey" then return "ALPHAKEY" end
    local row = self:Find(artKey)
    return row[4] and "ADD" or "BLEND"
end

function RA:NewRing(parent, layer)
    layer = layer or "ARTWORK"
    local tex = parent:CreateTexture(nil, layer)
    local g = tex:CreateAnimationGroup()
    g:SetLooping("REPEAT")
    local rot = g:CreateAnimation("Rotation")
    tex.ringGroup = g
    tex.ringRotation = rot
    return tex
end

function RA:Apply(tex, o)
    if not tex then return end
    o = o or {}
    local row = self:Find(o.art)
    tex:SetTexture(row[3])
    tex:SetBlendMode(self:BlendMode(o.art, o.blend))
    if tex.SetDesaturated then
        tex:SetDesaturated(o.desat and true or false)
    end
    local color = o.color or { 1, 1, 1 }
    tex:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1)
    tex:SetAlpha(o.alpha or 1)

    local group = tex.ringGroup
    local rot = tex.ringRotation
    if group and rot then
        local spin = tonumber(o.spin) or 0
        if spin == 0 then
            group:Stop()
        else
            rot:SetDegrees(spin > 0 and -360 or 360)
            rot:SetDuration(math.abs(spin))
            if not group:IsPlaying() then
                group:Play()
            end
        end
    end
end

return RA
