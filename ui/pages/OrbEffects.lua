








local ThugUI = _G.ThugUI

local OEPage = {}

local TITLES = { health = "Health", mana = "Mana", rage = "Rage", energy = "Energy", pips = "Combo pips" }

function OEPage.RegisterFor(classFile)
    local OE = ThugUI.OrbEffects
    local keys = { "health" }
    for _, r in ipairs(OE.CLASS_RESOURCES[classFile] or { "mana" }) do table.insert(keys, r) end
    if OE.PIP_CLASSES[classFile] then table.insert(keys, "pips") end

    for i, key in ipairs(keys) do
        local title = TITLES[key]
        ThugUI.Window:RegisterPage{
            id = "orbfx_" .. key,
            category = "orbeffects",
            order = i,
            scopeKeys = { "OrbEffects" },
            title = title,
            summary = "Animated look for " .. title,
            build = function(host, panel)
                panel:Note("|cffff3333Extra feature: these effects add animated layers to your orbs and pips and lower performance. Turn them off if your frame rate drops.|r")

                
                
                local function C() return ThugUIDB.OrbEffects[key] end
                local selected  

                local function LayerOptions()
                    local stack = OE:Stack(key)
                    local rows = {}
                    for _, l in ipairs(stack and stack.layers or {}) do
                        rows[#rows + 1] = { text = l.name, value = l.name }
                    end
                    if #rows == 0 then rows[1] = { text = "(no layers)", value = "" } end
                    return rows
                end
                
                
                local function Selected()
                    local rows = LayerOptions()
                    for _, r in ipairs(rows) do
                        if r.value == selected then return selected end
                    end
                    selected = rows[1].value
                    return selected
                end
                local function GetAdj(field, default)
                    local adj = C().adjust and C().adjust[Selected()]
                    if adj and adj[field] ~= nil then return adj[field] end
                    return default
                end
                local function SetAdj(field, v)
                    if Selected() == "" then return end
                    OE:Adjust(key, selected, field, v)
                end

                panel:FrameSection{ title = title .. " look" }
                panel:Part("Appearance")
                panel:Dropdown{
                    label = "Look",
                    options = function() return OE:Packs(key) end,
                    get = function() return C().pack or "default" end,
                    set = function(v)
                        OE:Choose(key, v)
                        panel:Refresh()
                    end,
                }

                panel:Group("Pack layers")
                panel:Dropdown{
                    label = "Layer",
                    options = LayerOptions,
                    get = Selected,
                    set = function(v)
                        selected = v
                        panel:Refresh()
                    end,
                }
                panel:Slider{
                    label = "X", min = -100, max = 100, step = 1,
                    get = function() return GetAdj("x", 0) end,
                    set = function(v) SetAdj("x", v) end,
                }
                panel:Slider{
                    label = "Y", min = -100, max = 100, step = 1,
                    get = function() return GetAdj("y", 0) end,
                    set = function(v) SetAdj("y", v) end,
                }
                panel:Slider{
                    label = "Scale", min = 0.25, max = 3, step = 0.05,
                    get = function() return GetAdj("scale", 1) end,
                    set = function(v) SetAdj("scale", v) end,
                }
                panel:Button{
                    label = "Reset layer adjustments",
                    onClick = function()
                        C().adjust = {}
                        OE:Refresh(key)
                        panel:Refresh()
                    end,
                }
                panel:Note("Packs are designed in the Thug Asset Browser. Default is the orb's own look from the Orbs page.")
            end,
        }
    end
end

if UnitClass then
    local _, classFile = UnitClass("player")
    OEPage.RegisterFor(classFile)
end


ThugUI.OEPage = OEPage
