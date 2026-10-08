


































ThugUI = ThugUI or {}

local Rewards = {}
ThugUI:RegisterModule("SeasonalRewards", Rewards)

local W  









local TITLE_HEIGHT  = 22   
local HEADER_HEIGHT = 18   
local ROW_HEIGHT    = 18   
local ROW_GAP       = 2
local NOTE_HEIGHT   = 16   
local TABLE_GAP     = 8    
local BODY_INDENT   = 14   
local COL_GAP       = 10

local STRIPE_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local STRIPE_ALPHA   = 0.05




local ACCENT = { r = 1.00, g = 0.82, b = 0.25 }

local YES    = { r = 0.40, g = 0.85, b = 0.45 }
local NO     = { r = 0.55, g = 0.55, b = 0.55 }











local function Track(track, text)
    return { text = text or track, track = track }
end


local function Tint(colour, text)
    return { text = text, colour = colour }
end



local function None()
    return { text = "\226\128\148", disabled = true }
end



local function Lines(...)
    return { lines = { ... } }
end









local CREST_SOURCES = {
    columns = {
        { key = "type",    label = "Type",    width = 96 },
        { key = "raid",    label = "Raid",    width = 110 },
        { key = "dungeon", label = "Dungeon", width = 140 },
        { key = "delves",  label = "Delves",  width = 150 },
    },
    rows = {
        { Track("Adventurer"), None(),   None(),            Lines("Tier 4") },
        { Track("Veteran"),    "LFR",    "Heroic",          Lines("Tiers 5-6", "Bountiful 4-5") },
        { Track("Champion"),   "Normal", "Mythic+ 0-3",     Lines("Tiers 8-10", "Bountiful 6-7") },
        { Track("Hero"),       "Heroic", "Mythic+ 4-8",     Lines("Tier 11", "Bountiful 8-11") },
        { Track("Myth"),       "Mythic", "Mythic+ 9+",      None() },
    },
}
Rewards.CREST_SOURCES = CREST_SOURCES








local RAID_BOSSES = {
    columns = {
        { key = "raid", label = "Raid",      width = 170 },
        { key = "boss", label = "Boss",      width = 190 },
        { key = "slot", label = "Tier Slot", width = 100 },
    },
    rows = {
        { "The Tidebound Grotto", "Nymrissa Wavecaller",    None() },
        { "The Venomous Abyss",   "Nek'zali the Soulcoiler", None() },
        { "The Venomous Abyss",   "Entombed Sentinels",     Tint(ACCENT, "Hands") },
        { "The Venomous Abyss",   "The Lost Explorers",     Tint(ACCENT, "Shoulder") },
        { "The Venomous Abyss",   "Vashnik the Malignant",  Tint(ACCENT, "Chest") },
        { "The Venomous Abyss",   "Sszorak",                Tint(ACCENT, "Legs") },
        { "The Venomous Abyss",   "The Twin Fangs",         Tint(ACCENT, "Head") },
        { "The Venomous Abyss",   "The Coiled Altar",       None() },
        { "The Venomous Abyss",   "Ula'tek",                Tint(ACCENT, "All") },
    },
}
Rewards.RAID_BOSSES = RAID_BOSSES








local SEASON_DUNGEONS = {
    columns = {
        { key = "dungeon", label = "Dungeon", width = 170 },
        { key = "bosses",  label = "Bosses",  width = 70 },
        { key = "timer",   label = "Timer",   width = 80 },
        { key = "route",   label = "Route",   width = 100 },
    },
    rows = {
        { "Altar of Fangs",      "3", "30:00", { text = "TBD", disabled = true } },
        { "Den of Nalorakk",     "3", "32:00", { text = "TBD", disabled = true } },
        { "Murder Row",          "4", "34:00", { text = "TBD", disabled = true } },
        { "The Blinding Vale",   "4", "31:00", { text = "TBD", disabled = true } },
        { "Voidscar Arena",      "3", "30:00", { text = "TBD", disabled = true } },
        { "King's Rest",         "4", "33:00", { text = "TBD", disabled = true } },
        { "Ruby Life Pools",     "3", "28:00", { text = "TBD", disabled = true } },
        { "Temple of Sethraliss","4", "33:00", { text = "TBD", disabled = true } },
    },
}
Rewards.SEASON_DUNGEONS = SEASON_DUNGEONS









local MPLUS_AFFIXES = {
    columns = {
        { key = "key",     label = "Keystone", width = 90 },
        { key = "rotates", label = "Rotates",  width = 80 },
        { key = "affix",   label = "Affix",    width = 280 },
    },
    rows = {
        { "4",  Tint(YES, "Yes"), Tint(ACCENT, "Xal'atath's Bargain: Ascendant") },
        { "4",  Tint(YES, "Yes"), Tint(ACCENT, "Xal'atath's Bargain: Voidbound") },
        { "4",  Tint(YES, "Yes"), Tint(ACCENT, "Xal'atath's Bargain: Pulsar") },
        { "4",  Tint(YES, "Yes"), Tint(ACCENT, "Xal'atath's Bargain: Devour") },
        { "7",  Tint(YES, "Yes"), Tint(ACCENT, "Tyrannical") },
        { "7",  Tint(YES, "Yes"), Tint(ACCENT, "Fortified") },
        { "10", Tint(NO,  "No"),  Tint(ACCENT, "Fortified & Tyrannical") },
        { "12", Tint(NO,  "No"),  Tint(ACCENT, "Xal'atath's Guile") },
    },
}
Rewards.MPLUS_AFFIXES = MPLUS_AFFIXES





local CRAFTED_GEAR = {
    columns = {
        { key = "mats", label = "Materials",  width = 200 },
        { key = "ilvl", label = "Item Level", width = 120 },
    },
    rows = {
        { "Spark of Tides",              "292-305" },
        { Track("Hero", "Hero Mistcrest x80"), "305-318" },
        { Track("Myth", "Myth Mistcrest x80"), "318-331" },
    },
}
Rewards.CRAFTED_GEAR = CRAFTED_GEAR








local function SeasonTracks()
    local GearTrack = ThugUI.Seasonal and ThugUI.Seasonal.GearTrack
    return GearTrack and GearTrack.SEASON_TRACKS
end

local function ItemLevel(trackName, rank)
    local tracks = SeasonTracks()
    if not tracks then return nil end
    for _, track in ipairs(tracks) do
        if track.name == trackName then return track.ranks[rank] end
    end
    return nil
end




local function Reward(pair)
    if not pair then return None() end
    local ilvl = ItemLevel(pair[1], pair[2])
    if not ilvl then return None() end
    return Track(pair[1], pair[1] .. " " .. ilvl)
end


local function BuildUpgradeTracks()
    local rows = {}
    for _, track in ipairs(SeasonTracks() or {}) do
        local ranks = track.ranks
        rows[#rows + 1] = {
            Track(track.name),
            tostring(#ranks),
            Track(track.name, ranks[1] .. "-" .. ranks[#ranks]),
        }
    end
    return rows
end








local SKIP_MPLUS_ROWS = { ["Heroic"] = true, ["Mythic 0"] = true }

local function BuildMplusRewards()
    local source = ThugUI.Seasonal and ThugUI.Seasonal.RewardTables
    local data = source and source.MPLUS_DATA
    if not data then return {} end

    local rows = {}
    for _, row in ipairs(data) do
        local label, endOfRun, crest, vault = row[1], row[2], row[3], row[4]
        if not SKIP_MPLUS_ROWS[label] then
            rows[#rows + 1] = {
                (label:gsub("^%+", "")):gsub(" and higher", "+"),
                Track(crest),
                Reward(endOfRun),
                Reward(vault),
            }
        end
    end
    return rows
end



local function BuildDelveRewards()
    local source = ThugUI.Seasonal and ThugUI.Seasonal.RewardTables
    local data = source and source.DELVE_DATA
    if not data then return {} end

    local rows = {}
    for _, row in ipairs(data) do
        rows[#rows + 1] = {
            tostring(row[1]),
            Reward(row[2]),
            row[3] and Reward(row[3]) or None(),
            Reward(row[4]),
        }
    end
    return rows
end









local BLOCKS = {
    {
        id = "crests", title = "Crests",
        columns = CREST_SOURCES.columns, rows = CREST_SOURCES.rows,
    },
    {
        id = "tracks", title = "Upgrade Tracks",
        columns = {
            { key = "track", label = "Track",      width = 110 },
            { key = "ranks", label = "Ranks",      width = 70 },
            { key = "ilvl",  label = "Item Level", width = 120 },
        },
        rows = BuildUpgradeTracks,
        note = "Upgrading equipment costs 20 mistcrests per rank.",
    },
    {
        id = "raidbosses", title = "Raid Bosses",
        columns = RAID_BOSSES.columns, rows = RAID_BOSSES.rows,
    },
    {
        id = "mplusrewards", title = "Mythic+ Rewards",
        columns = {
            { key = "key",   label = "Keystone",    width = 90 },
            { key = "crest", label = "Crests",      width = 100 },
            { key = "gear",  label = "Equipment",   width = 140 },
            { key = "vault", label = "Great Vault", width = 140 },
        },
        rows = BuildMplusRewards,
    },
    {
        id = "dungeons", title = "Seasonal Dungeons",
        columns = SEASON_DUNGEONS.columns, rows = SEASON_DUNGEONS.rows,
    },
    {
        id = "affixes", title = "Mythic+ Affixes",
        columns = MPLUS_AFFIXES.columns, rows = MPLUS_AFFIXES.rows,
    },
    {
        id = "delverewards", title = "Delve Rewards",
        columns = {
            { key = "tier",   label = "Tier",                 width = 70 },
            { key = "coffer", label = "Bountiful Coffer",     width = 150 },
            { key = "bounty", label = "Trovehunter's Bounty", width = 160 },
            { key = "vault",  label = "Great Vault",          width = 140 },
        },
        rows = BuildDelveRewards,
    },
    {
        id = "crafted", title = "Crafted Equipment",
        columns = CRAFTED_GEAR.columns, rows = CRAFTED_GEAR.rows,
    },
}
Rewards.BLOCKS = BLOCKS










local function CollapsedStore()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Seasonal = ThugUIDB.Seasonal or {}
    ThugUIDB.Seasonal.collapsed = ThugUIDB.Seasonal.collapsed or {}
    return ThugUIDB.Seasonal.collapsed
end

local function StoreKey(id)
    return "rewards:" .. id
end

local function IsCollapsed(id)
    return CollapsedStore()[StoreKey(id)] == true
end

local function SetCollapsed(id, collapsed)
    CollapsedStore()[StoreKey(id)] = collapsed and true or false
end





local function TrackColour(trackName)
    local ColorForTrack = ThugUI.Seasonal and ThugUI.Seasonal.ColorForTrack
    if type(ColorForTrack) == "function" then
        local ok, r, g, b = pcall(ColorForTrack, trackName)
        if ok and r then return r, g, b end
    end
    return 0.5, 0.5, 0.5
end




local function ResolveCell(cell)
    if cell == nil then
        return { "" }, 0.8, 0.8, 0.8
    end
    if type(cell) == "string" then
        return { cell }, 0.85, 0.85, 0.85
    end
    if cell.lines then
        return cell.lines, 0.85, 0.85, 0.85
    end
    if cell.track then
        local r, g, b = TrackColour(cell.track)
        return { cell.text }, r, g, b
    end
    if cell.colour then
        return { cell.text }, cell.colour.r, cell.colour.g, cell.colour.b
    end
    if cell.disabled then
        return { cell.text }, 0.45, 0.45, 0.45
    end
    return { cell.text or "" }, 0.85, 0.85, 0.85
end



local function RowLineCount(row)
    local most = 1
    for _, cell in ipairs(row) do
        if type(cell) == "table" and cell.lines and #cell.lines > most then
            most = #cell.lines
        end
    end
    return most
end









local function BuildBlock(parent, spec)
    local block = { id = spec.id, spec = spec }

    local title = CreateFrame("Button", nil, parent)
    title:SetHeight(TITLE_HEIGHT)
    title.labelText = spec.title

    local arrow = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow:SetPoint("LEFT", title, "LEFT", 2, 0)

    local label = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
    label:SetText(spec.title)

    block.title = title
    block.arrow = arrow

    local body = CreateFrame("Frame", nil, parent)
    block.body = body
    block.stripes = {}
    block.fontStrings = {}

    title:SetScript("OnClick", function()
        SetCollapsed(spec.id, not IsCollapsed(spec.id))
        Rewards:Layout()
    end)
    W = W or ThugUI.Widgets
    if W and type(W.AttachTooltip) == "function" then
        W.AttachTooltip(title, spec.title, "Click to expand or collapse.")
    end

    return block
end





local function PaintBlock(block)
    local spec = block.spec
    local body = block.body

    for _, fs in ipairs(block.fontStrings) do fs:Hide() end
    for _, tex in ipairs(block.stripes) do tex:Hide() end
    local used, stripesUsed = 0, 0

    
    
    
    
    
    block.grid = {}
    local function RecordCell(rowIndex, columnIndex, entry)
        block.grid[rowIndex] = block.grid[rowIndex] or {}
        block.grid[rowIndex][columnIndex] = entry
    end

    local function Line(text, template, x, y, r, g, b, width)
        used = used + 1
        local fs = block.fontStrings[used]
        if not fs then
            fs = body:CreateFontString(nil, "OVERLAY", template)
            block.fontStrings[used] = fs
        end
        
        
        if fs.__template ~= template then
            
            
            
            fs:SetFontObject(_G[template] or template)
            fs.__template = template
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", body, "TOPLEFT", x, -y)
        fs:SetWidth(width or 0)
        
        
        
        fs:SetWordWrap(false)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        fs:SetTextColor(r or 0.85, g or 0.85, b or 0.85)
        fs:Show()
        return fs
    end

    local function Stripe(y, height)
        stripesUsed = stripesUsed + 1
        local tex = block.stripes[stripesUsed]
        if not tex then
            tex = body:CreateTexture(nil, "BACKGROUND")
            tex:SetTexture(STRIPE_TEXTURE)
            tex:SetVertexColor(1, 1, 1, STRIPE_ALPHA)
            block.stripes[stripesUsed] = tex
        end
        tex:ClearAllPoints()
        tex:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
        tex:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -y)
        tex:SetHeight(height)
        tex:Show()
    end

    local rows = spec.rows
    if type(rows) == "function" then rows = rows() end
    rows = rows or {}

    
    local xs, x = {}, 0
    for i, col in ipairs(spec.columns) do
        xs[i] = x
        x = x + col.width + COL_GAP
    end

    local y = 0
    for i, col in ipairs(spec.columns) do
        Line(col.label, "GameFontNormalSmall", xs[i], y, 1, 0.82, 0.25, col.width)
    end
    y = y + HEADER_HEIGHT

    for rowIndex, row in ipairs(rows) do
        local lineCount = RowLineCount(row)
        local rowHeight = ROW_HEIGHT + (lineCount - 1) * (ROW_HEIGHT - 4)

        
        
        
        if rowIndex % 2 == 0 then
            Stripe(y - 1, rowHeight)
        end

        for i, col in ipairs(spec.columns) do
            local lines, r, g, b = ResolveCell(row[i])
            local first
            for lineIndex, text in ipairs(lines) do
                local fs = Line(text, "GameFontHighlightSmall", xs[i],
                    y + (lineIndex - 1) * (ROW_HEIGHT - 4), r, g, b, col.width)
                first = first or fs
            end
            RecordCell(rowIndex, i, { lines = lines, r = r, g = g, b = b, fs = first })
        end

        y = y + rowHeight + ROW_GAP
    end

    if spec.note then
        y = y + 2
        Line(spec.note, "GameFontDisableSmall", 0, y, nil, nil, nil, x)
        y = y + NOTE_HEIGHT
    end

    for i = used + 1, #block.fontStrings do block.fontStrings[i]:Hide() end
    for i = stripesUsed + 1, #block.stripes do block.stripes[i]:Hide() end

    body:SetHeight(math.max(y, 1))
    return y
end





function Rewards:Layout()
    if not self.host then return end

    local y = 4
    for _, block in ipairs(self.blocks) do
        local collapsed = IsCollapsed(block.id)
        block.arrow:SetText(collapsed and "+" or "-")

        block.title:ClearAllPoints()
        block.title:SetPoint("TOPLEFT", self.host, "TOPLEFT", 0, -y)
        block.title:SetPoint("TOPRIGHT", self.host, "TOPRIGHT", 0, -y)
        block.title:Show()
        y = y + TITLE_HEIGHT

        block.body:ClearAllPoints()
        if collapsed then
            block.body:Hide()
        else
            local height = PaintBlock(block)
            block.body:SetPoint("TOPLEFT", self.host, "TOPLEFT", BODY_INDENT, -y)
            block.body:SetPoint("TOPRIGHT", self.host, "TOPRIGHT", 0, -y)
            block.body:Show()
            y = y + height
        end
        y = y + TABLE_GAP
    end

    self.host:SetHeight(y + 4)

    
    
    
    
    local Seasonal = ThugUI.Seasonal
    if Seasonal and type(Seasonal.RelayoutBody) == "function" and Seasonal.activeNav == "rewards" then
        Seasonal:RelayoutBody()
    end
end





function Rewards:Render(key)
    
    
    
    if not self.host then return end
    self:Layout()
end

function Rewards:Initialize()
    local Seasonal = ThugUI.Seasonal or {}
    ThugUI.Seasonal = Seasonal

    
    Seasonal:CreateWindow()
    Seasonal.Rewards = self

    local entry = Seasonal.sectionFrames and Seasonal.sectionFrames["rewards"]
    if entry and entry.body then
        
        
        
        if entry.body.text then entry.body.text:Hide() end

        self.host = entry.body
        self.blocks = {}
        for _, spec in ipairs(BLOCKS) do
            self.blocks[#self.blocks + 1] = BuildBlock(entry.body, spec)
        end
        self:Layout()
    end

    Seasonal:RegisterRefresh(function(key) self:Render(key) end)
end

return Rewards
