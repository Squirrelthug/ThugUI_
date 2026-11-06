






ThugUI = ThugUI or {}

local function FB() return ThugUI.FaceButtons end

local function Rows(panel, page)
    for _, face in ipairs(FB().FACES) do
        panel:Dropdown{
            label = face.title,
            width = 240,
            options = function() return FB():Options(page, face) end,
            get = function() return FB():Get(page, face.id) or "" end,
            set = function(v) FB():Set(page, face.id, v ~= "" and v or nil) end,
        }
    end
end

local function Build(panel)
    panel:Note("Experimental. Sets the four face buttons with no trigger or bumper held, separately "
        .. "on each layout. Hold both bumpers and press left or right on the D-pad to change layout.")
    panel:Note("Holding a trigger or bumper still uses those bars as normal. A button you set "
        .. "shows your spell or macro's icon, without a cooldown sweep for now. Setting the top "
        .. "button replaces the unit wheel on that layout. Changes made in combat land when it ends.")
    for page = 1, FB().PAGES do
        panel:FrameSection{ title = "Layout " .. page }
        Rows(panel, page)
    end
end

ThugUI.Window:RegisterPage{
    id = "facebuttons",
    category = "controller",
    order = 56,
    scopeKeys = { "FaceButtons" },
    title = "Face buttons",
    summary = "Experimental: the four face buttons, set for each layout.",
    build = function(host, panel) Build(panel) end,
}
