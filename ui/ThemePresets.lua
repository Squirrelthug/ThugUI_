
























local ThugUI = _G.ThugUI
local T = ThugUI.Theme

local function H(hex, a)
    return { tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255,
        tonumber(hex:sub(5, 6), 16) / 255, a or 1 }
end
local function A(spec, a)
    local c = {}
    for k, v in pairs(spec) do c[k] = v end
    c.a, c[4] = a, nil
    if c[1] then c[4] = a end
    return c
end
local function Q(n) return { quality = n } end
local function C(class, mul, a) return { class = class, mul = mul, a = a } end



local PARTS = { H("73c7ff"), H("c79eff"), H("ffa84d"), H("73eb8c") }




local function Roles(p)
    local parts = p.parts or PARTS
    local rule = A(p.rule, 0.45)
    return {
        windowTitle = p.accent, windowVersion = p.muted,
        pageTitle = p.title, pageContext = p.muted, headerLabel = p.title,
        navCategory = p.title, navPage = p.nav, navNested = p.nested,
        navSelected = p.selected or p.text, navGlyph = p.title, navAccent = p.accent,
        selectedFill = A(p.text, 0.08), highlight = A(p.text, 0.10),
        
        tab = p.muted, tabSelected = p.title, subTab = p.muted, subTabSelected = p.accent2,
        tabFill = A(p.text, 0.05), tabSelectedFill = A(p.text, 0.12), tabHighlight = A(p.text, 0.08),
        tabAccent = p.accent,
        ruleHeader = rule, ruleSidebar = rule, ruleTabs = rule, ruleSubTabs = rule,
        ruleSection = rule, ruleGroup = A(p.rule, 0.35), ruleFrameSection = p.title,
        section = p.title, frameSectionFill = A(p.text, 0.04),
        partLayout = parts[1], partVisibility = parts[2], partAppearance = parts[3], partContent = parts[4],
        group = p.nav,
        label = p.text, value = p.text, note = p.muted, disabled = A(p.muted, 0.8),
        accent = p.accent, searchOutline = p.title,
        controlFill = A(p.surface, 0.9), controlBorder = p.rule, controlHighlight = A(p.text, 0.1),
        listTitle = p.title, listItem = p.text, swatchBorder = p.rule,
        listBackground = A(p.surface, 0.96), listBorder = p.rule,
        link = p.accent2, linkHover = p.text,
        ruleCategory = A(p.rule, 0.8), tileFill = A(p.surface, 0.95),
        tileTitle = p.title, tileDescription = p.text, tileState = p.title,
        border = { 1, 1, 1, 1 },
    }
end
T.PaletteRoles = Roles

T:RegisterPreset{ id = "default", name = "ThugUI (default)", colors = {} }





local function ColorPreset(id, name, p, bgAlpha)
    p.bg = p.bg or H("0b0b0e")
    T:RegisterPreset{
        id = id, name = name, kind = "color", group = "color", palette = p,
        colors = Roles(p),
        background = { kind = "color", color = p.bg, alpha = bgAlpha or 0.95 },
        border = p.border or "dialog",
    }
end




ColorPreset("quality", "Item quality", {
    bg = H("0b0b0e"), surface = H("17171c"),
    text = Q(1), muted = Q(0), nav = Q(1), nested = Q(0), selected = Q(2),
    title = Q(5), accent = Q(3), accent2 = Q(4), rule = Q(0),
    
    parts = { Q(2), Q(3), Q(4), Q(5) },
})












local CLASSES = {
    { "WARRIOR", "Warrior: Arms and iron",      H("8fb3d9"), { C("WARRIOR"), H("e05a4f"), H("8fb3d9"), H("7fcf7f") }, 7807951 },
    { "PALADIN", "Paladin: The Light",           H("ffd24d"), { H("ffd24d"), C("PALADIN"), H("8fc7ff"), H("b0e08f") }, 7808138 },
    { "HUNTER",  "Hunter: Leather and fletching", H("d9a066"), { C("HUNTER"), H("d9a066"), H("5fc9a8"), H("e8d590") }, 7808137 },
    { "ROGUE",   "Rogue: Poison and shadow",     H("78d957"), { H("78d957"), C("ROGUE"), H("e06060"), H("a8a4ff") }, 7808139 },
    { "PRIEST",  "Priest: Light and shadow",     H("a78bfa"), { H("ffe27a"), H("a78bfa"), H("8fd6ff"), H("f2a0c8") }, 7792321 },
    { "SHAMAN",  "Shaman: Storm and totem",      H("7fd4ff"), { H("e8763c"), H("7fd4ff"), H("6cc96c"), H("4d9fff") }, 4631383 },
    { "MAGE",    "Mage: Arcane",                 H("d08cff"), { H("d08cff"), H("ff8a4c"), C("MAGE"), H("7f9fff") }, 7808140 },
    { "WARLOCK", "Warlock: Fel fire",            H("8cff4d"), { H("8cff4d"), C("WARLOCK"), H("e0504d"), H("d9a0ff") }, 7808058 },
    { "DRUID",   "Druid: Wild growth",           H("6cc96c"), { C("DRUID"), H("6cc96c"), H("9fb8ff"), H("e8c070") }, 7808141 },
}
T.CLASS_PICTURES = {}
for _, c in ipairs(CLASSES) do T.CLASS_PICTURES[c[1] ] = c[5] end





local LS = "Interface\\Glues\\LoadingScreens\\"
T.GALLERY = {
    { name = "Molten Core",        file = 131851 },
    { name = "Blackwing Lair",     file = 131827 },
    { name = "Naxxramas",          file = 131854 },
    { name = "Ahn'Qiraj",          file = 131819 },
    { name = "Ruins of Ahn'Qiraj", file = 131818 },
    { name = "Zul'Gurub",          file = 131886 },
    { name = "Scholomance",        file = 131868 },
    { name = "Blackrock Depths",   file = 131824 },
    { name = "Blackrock Spire",    file = 131825 },
    { name = "Maraudon",           file = 131850 },
    { name = "The Deadmines",      file = 131833 },
    { name = "Sunken Temple",      file = 131872 },
    { name = "Dire Maul",          file = 131835 },
    { name = "Uldaman",            file = 131876 },
    { name = "Wailing Caverns",    file = 131882 },
    { name = "Zul'Farrak",         file = 131885 },
    { name = "Gnomeregan",         file = 131841 },
    { name = "Shadowfang Keep",    file = 131869 },
    { name = "Kalimdor",           file = 131848 },
    { name = "Eastern Kingdoms",   file = 131839 },
    
    
    { name = "Eastern Kingdoms (Forever)", file = 7963776 },
    { name = "Kalimdor (Forever)",         file = 7963779 },
}

local function ImagePreset(id, name, image, p, group)
    T:RegisterPreset{
        id = id, name = name, kind = "image", group = group or "image", palette = p,
        colors = Roles(p),
        
        
        mods = { nestedShade = p.nestedShade or 0.25 },
        
        
        background = { kind = "image", image = image, color = p.bg, alpha = 0.96,
            dim = p.dim or 0.65, mode = "cover", aspect = 4 / 3 },
        border = p.border or "dialog",
    }
end

for _, c in ipairs(CLASSES) do
    local class = c[1]
    ImagePreset("class_" .. class:lower(), c[2], c[5], {
        bg = C(class, 0.07), surface = C(class, 0.14),
        text = H("f2f2f2"), muted = H("8c8c8c"), nav = H("cfcfcf"), nested = H("858585"),
        
        title = class == "PRIEST" and c[3] or C(class),
        accent = C(class), accent2 = c[3], rule = H("5a5a5a"), parts = c[4], dim = 0.45,
    }, "class")
end





ImagePreset("alliance", "Alliance", 7963776, {
    bg = H("0c1424"), surface = H("18243a"), text = H("eef1f5"), muted = H("9aa5b4"),
    nav = H("ccd4de"), nested = H("8d97a6"), title = H("c4ccd8"), accent = H("3f7fe0"), accent2 = H("8fb8ff"),
    rule = H("4a5668"), parts = { H("5c9cff"), H("b0bccc"), H("e6c35c"), H("6fd6a8") },
})
ImagePreset("horde", "Horde", 7963779, {
    bg = H("180a09"), surface = H("2c1412"), text = H("f3e8e2"), muted = H("ab968e"),
    nav = H("dccac2"), nested = H("978279"), title = H("e8564a"), accent = H("c8302a"), accent2 = H("e6b850"),
    rule = H("5c3a34"), parts = { H("ff6a5a"), H("e6c35c"), H("b4aca4"), H("8fd06a") },
})

ImagePreset("mc", "Molten Core (Monokai)", 131851, {
    bg = H("272822"), surface = H("3e3d32"), text = H("f8f8f2"), muted = H("a59f85"),
    nav = H("cfcfc2"), nested = H("8f8a73"), title = H("fd971f"), accent = H("f92672"), accent2 = H("e6db74"),
    rule = H("75715e"), parts = { H("f92672"), H("fd971f"), H("e6db74"), H("a6e22e") },
})
ImagePreset("bwl", "Blackwing Lair (Dracula)", 131827, {
    bg = H("282a36"), surface = H("44475a"), text = H("f8f8f2"), muted = H("8a93c2"),
    nav = H("d6d6e6"), nested = H("8a93c2"), title = H("ff79c6"), accent = H("bd93f9"), accent2 = H("ff5555"),
    rule = H("6272a4"), parts = { H("ff5555"), H("ffb86c"), H("ff79c6"), H("bd93f9") },
})
ImagePreset("naxx", "Naxxramas (Nord)", 131854, {
    bg = H("2e3440"), surface = H("3b4252"), text = H("eceff4"), muted = H("9aa5b8"),
    nav = H("d8dee9"), nested = H("8c96a8"), title = H("ebcb8b"), accent = H("8fbcbb"), accent2 = H("e88a92"),
    rule = H("4c566a"), parts = { H("a3be8c"), H("88c0d0"), H("c895c0"), H("d08770") },
})
ImagePreset("aq", "Ahn'Qiraj (Solarized)", 131819, {
    bg = H("002b36"), surface = H("073642"), text = H("eee8d5"), muted = H("93a1a1"),
    nav = H("d6d0bd"), nested = H("839496"), title = H("b58900"), accent = H("2aa198"), accent2 = H("e86aa6"),
    rule = H("586e75"), parts = { H("e8743b"), H("2aa198"), H("e86aa6"), H("859900") },
})
ImagePreset("zg", "Zul'Gurub (Everforest)", 131886, {
    bg = H("2d353b"), surface = H("343f44"), text = H("d3c6aa"), muted = H("9da9a0"),
    nav = H("c5b99e"), nested = H("859289"), title = H("dbbc7f"), accent = H("83c092"), accent2 = H("e67e80"),
    rule = H("5c6a72"), parts = { H("7fbf5f"), H("f08850"), H("c47fd5"), H("7fa8e0") },
})
ImagePreset("scholo", "Scholomance (Tokyo Night)", 131868, {
    bg = H("1a1b26"), surface = H("24283b"), text = H("c0caf5"), muted = H("8189b0"),
    nav = H("a9b1d6"), nested = H("737aa2"), title = H("7aa2f7"), accent = H("bb9af7"), accent2 = H("f7768e"),
    rule = H("414868"), parts = { H("9d7cd8"), H("9ece6a"), H("ff7a93"), H("7dcfff") },
})
ImagePreset("brd", "Blackrock Depths (Gruvbox)", 131824, {
    bg = H("282828"), surface = H("3c3836"), text = H("ebdbb2"), muted = H("a89984"),
    nav = H("d5c4a1"), nested = H("928374"), title = H("fabd2f"), accent = H("8ec07c"), accent2 = H("fb4934"),
    rule = H("665c54"), parts = { H("fb4934"), H("fabd2f"), H("b8bb26"), H("83a598") },
})
ImagePreset("mara", "Maraudon (Rose Pine)", 131850, {
    bg = H("191724"), surface = H("26233a"), text = H("e0def4"), muted = H("908caa"),
    nav = H("cfcbe6"), nested = H("8f8aa8"), title = H("ebbcba"), accent = H("eb6f92"), accent2 = H("f6c177"),
    rule = H("524f67"), parts = { H("8bd5a0"), H("eb6f92"), H("f6c177"), H("c4a7e7") },
})
ImagePreset("vc", "The Deadmines (One Dark)", 131833, {
    bg = H("282c34"), surface = H("2f343f"), text = H("d7dae0"), muted = H("8b919c"),
    nav = H("abb2bf"), nested = H("868c97"), title = H("e5c07b"), accent = H("61afef"), accent2 = H("e06c75"),
    rule = H("4b5263"), parts = { H("e5c07b"), H("e06c75"), H("56b6c2"), H("98c379") },
})
ImagePreset("st", "Sunken Temple (Kanagawa)", 131872, {
    bg = H("1f1f28"), surface = H("2a2a37"), text = H("dcd7ba"), muted = H("8f8b78"),
    nav = H("c8c093"), nested = H("8a8978"), title = H("e6c384"), accent = H("7e9cd8"), accent2 = H("e46876"),
    rule = H("54546d"), parts = { H("98bb6c"), H("7fb4ca"), H("e46876"), H("ffa066") },
})
