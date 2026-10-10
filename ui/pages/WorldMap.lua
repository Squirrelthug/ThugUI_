








ThugUI = ThugUI or {}

local function Cfg()
    ThugUIDB.WorldMap = ThugUIDB.WorldMap or {}
    return ThugUIDB.WorldMap
end

local function Refresh()
    if ThugUI.WorldMapLabels then ThugUI.WorldMapLabels:Refresh() end
end

local function Build(panel)
    panel:FrameSection{
        title = "Zone labels",
        enabled = {
            get = function() return Cfg().enabled end,
            set = function(v) Cfg().enabled = v and true or false; Refresh() end,
        },
    }

    panel:Note("Hover a zone on the world map to see its name at the top. "
        .. "Level ranges are the Classic ones: Forever's client carries none of its own.")

    panel:Part("Appearance")
    panel:Checkbox{
        label = "Colour zone names by territory",
        tooltip = "Green friendly, red hostile, orange contested, blue sanctuary -- "
            .. "the colours Blizzard's zone text uses. The zone you are in is asked of the server; "
            .. "others come from the zone data.",
        get = function() return Cfg().colorNames end,
        set = function(v) Cfg().colorNames = v and true or false; Refresh() end,
    }
    panel:Checkbox{
        label = "Colour level ranges by difficulty",
        tooltip = "Grey well below you, green and yellow near your level, orange and red above it.",
        get = function() return Cfg().colorLevels end,
        set = function(v) Cfg().colorLevels = v and true or false; Refresh() end,
    }

    panel:Part("Content")
    panel:Checkbox{
        label = "Show level range",
        tooltip = "Adds the zone's level range in brackets, e.g. Westfall (10-20).",
        get = function() return Cfg().showLevels end,
        set = function(v) Cfg().showLevels = v and true or false; Refresh() end,
    }
end

ThugUI.Window:RegisterPage{
    id = "worldmap",
    
    scopeKeys = { "WorldMap" },
    category = "interface",
    order = 40,
    summary = "Level ranges and territory colours on the world map's zone names.",
    title = "World Map",
    build = function(host, panel) Build(panel) end,
}
