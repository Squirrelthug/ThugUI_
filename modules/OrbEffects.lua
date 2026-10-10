





local ThugUI = _G.ThugUI
local OE = {}
ThugUI.OrbEffects = OE
ThugUI:RegisterModule("OrbEffects", OE)

OE.CLASS_RESOURCES = {
    WARRIOR = { "rage" },
    ROGUE = { "energy" },
    DRUID = { "mana", "rage", "energy" }
}
OE.PIP_CLASSES = { ROGUE = true, DRUID = true }

function OE:Resources()
    local _, classFile = UnitClass("player")
    return OE.CLASS_RESOURCES[classFile] or { "mana" }
end

function OE.BlendFor(blend)
    if blend == "normal" then return "BLEND" end
    if blend == "mod" then return "MOD" end
    if blend == "alphakey" then return "ALPHAKEY" end
    return "ADD"
end

ThugUI.defaults.OrbEffects = {
    health = { pack = "default", adjust = {} },
    mana = { pack = "default", adjust = {} },
    rage = { pack = "default", adjust = {} },
    energy = { pack = "default", adjust = {} },
    pips = { pack = "default", adjust = {} }
}

OE.DRAFT = "(draft)"

function OE:PackStore()
    if not _G.ThugUI_Packs then
        _G.ThugUI_Packs = { health = {}, mana = {}, rage = {}, energy = {}, pips = {} }
    end
    for _, t in ipairs({"health", "mana", "rage", "energy", "pips"}) do
        if not _G.ThugUI_Packs[t] then _G.ThugUI_Packs[t] = {} end
    end
    return _G.ThugUI_Packs
end

function OE:Packs(target)
    self:Migrate()
    local rows = { { text = "Default", value = "default" } }
    local presets = ThugUI.OrbPacks and ThugUI.OrbPacks[target] or {}
    local pkeys = {}
    for k in pairs(presets) do table.insert(pkeys, k) end
    table.sort(pkeys)
    for _, k in ipairs(pkeys) do
        table.insert(rows, { text = (presets[k].name or k), value = "preset:" .. k })
    end
    
    local ukeys = {}
    local store = self:PackStore()[target]
    for k in pairs(store) do
        if k ~= OE.DRAFT then table.insert(ukeys, k) end
    end
    table.sort(ukeys)
    for _, k in ipairs(ukeys) do
        table.insert(rows, { text = (store[k].name or k) .. " (yours)", value = "user:" .. k })
    end
    
    if store[OE.DRAFT] then
        table.insert(rows, { text = "Draft (designer)", value = "user:" .. OE.DRAFT })
    end
    return rows
end

function OE:Stack(target)
    self:Migrate()
    local c = ThugUIDB.OrbEffects[target]
    local pack = c and c.pack
    if not pack or pack == "default" then return nil end
    local pType, pId = string.match(pack, "^(.-):(.*)$")
    local stack
    if pType == "preset" then
        local p = ThugUI.OrbPacks and ThugUI.OrbPacks[target] and ThugUI.OrbPacks[target][pId]
        if p then stack = p.stack end
    elseif pType == "user" then
        local store = self:PackStore()[target]
        local p = store[pId]
        if p then stack = p.stack end
    end
    
    if not stack then
        if not OE.loggedMissingPack then OE.loggedMissingPack = {} end
        if not OE.loggedMissingPack[pack] then
            if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("ORBFX", "pack %s missing, default look", pack) end
            OE.loggedMissingPack[pack] = true
        end
        return nil
    end
    
    local kind = target == "pips" and "pip" or "orb"
    local clean, dropped = ThugUI.OrbArt.Sanitize(stack, kind)
    return clean
end

function OE:Choose(target, id)
    self:Migrate()
    ThugUIDB.OrbEffects[target].pack = id
    self:Refresh(target)
end

function OE:Adjust(target, name, field, value)
    local adj = ThugUIDB.OrbEffects[target].adjust
    if not adj then
        adj = {}
        ThugUIDB.OrbEffects[target].adjust = adj
    end
    if not adj[name] then adj[name] = {} end
    adj[name][field] = value
    self:Refresh(target)
end

function OE:Draft(target)
    local store = self:PackStore()[target]
    if not store[OE.DRAFT] then
        local st = self:Stack(target)
        store[OE.DRAFT] = { name = "Draft", stack = st or {} }
    end
    return store[OE.DRAFT]
end

function OE:SavePack(target, name)
    if not name or name == "" or name == OE.DRAFT then
        return false, "Invalid pack name"
    end
    local store = self:PackStore()[target]
    local draft = store[OE.DRAFT]
    if not draft then return false, "No draft to save" end
    store[name] = { name = name, stack = ThugUI.OrbArt.Copy(draft.stack) }
    return true
end

function OE:LoadPack(target, id)
    local c = ThugUIDB.OrbEffects[target]
    local oldPack = c.pack
    c.pack = id
    local stack = self:Stack(target)
    c.pack = oldPack
    
    local store = self:PackStore()[target]
    if stack then
        store[OE.DRAFT] = { name = "Draft", stack = ThugUI.OrbArt.Copy(stack) }
    else
        store[OE.DRAFT] = { name = "Draft", stack = { layers = {} } }
    end
end

function OE:DeletePack(target, name)
    if name == OE.DRAFT then return end
    local store = self:PackStore()[target]
    store[name] = nil
    
    
    
    local cfg = ThugUIDB.OrbEffects[target]
    if cfg and cfg.pack == "user:" .. name then
        cfg.pack = "default"
        self:Refresh(target)
    end
end

function OE:CopyDesign(from, to)
    local sStore = self:PackStore()[from]
    local dStore = self:PackStore()[to]
    if not sStore or not sStore[OE.DRAFT] then return 0 end
    local kind = to == "pips" and "pip" or "orb"
    local clean, dropped = ThugUI.OrbArt.Sanitize(sStore[OE.DRAFT].stack, kind)
    dStore[OE.DRAFT] = { name = "Draft", stack = clean }
    return dropped
end

OE._canvas = {}

function OE:Apply(orbKey)
    local target = orbKey
    if target ~= "health" then
        local _, token = ThugUI.ResourceRing:GetPowerType()
        if token then
            local tkey = string.lower(token)
            local res = self:Resources()
            for _, r in ipairs(res) do
                if r == tkey then
                    target = tkey
                    break
                end
            end
        end
    end

    local f = ThugUI.Orbs:GetFrame(orbKey)
    local stack = target and self:Stack(target) or nil
    local active = ThugUI:IsModuleOn("orbeffects") and ThugUI:IsModuleOn("orbs") and f and stack

    if not active then
        local canvas = self._canvas[orbKey]
        if canvas then canvas:Hide() end
        if f then
            f.fill:SetAlpha(1)
            f.bg:SetAlpha(1)
        end
        return
    end

    local canvas = self._canvas[orbKey]
    if not canvas then
        
        
        canvas = ThugUI.OrbArt:NewCanvas(f.body or f, { kind = "orb", mask = f.mask, baseLevel = f.fill:GetFrameLevel() })
        self._canvas[orbKey] = canvas
    end
    
    f.fill:SetAlpha(0)
    f.bg:SetAlpha(stack.background and 0 or 1)
    
    local c = ThugUIDB.OrbEffects[target]
    local adjust = c.adjust or {}
    local dir = ThugUIDB.Orbs[orbKey].direction or "up"
    canvas:Apply(stack, adjust, dir)
    self:UpdateValue(orbKey)
end

function OE:UpdateValue(orbKey)
    local canvas = self._canvas[orbKey]
    if not canvas then return end
    
    local cur, max
    if orbKey == "health" then
        cur = UnitHealth("player")
        max = UnitHealthMax("player")
    else
        local pt = ThugUI.ResourceRing:GetPowerType()
        cur = UnitPower("player", pt)
        max = UnitPowerMax("player", pt)
    end
    
    canvas:SetValue(cur, max)
end

function OE:Refresh(target)
    if target == "pips" then
        if ThugUI.ResourcePips then ThugUI.ResourcePips:Refresh() end
    else
        local orbKey = target == "health" and "health" or "resource"
        self:Apply(orbKey)
    end
end

function OE:PipStack()
    if not ThugUI:IsModuleOn("orbeffects") then return nil end
    return self:Stack("pips")
end






function OE:Migrate()
    local store = self:PackStore()
    for _, target in ipairs({"health", "mana", "rage", "energy", "pips"}) do
        local c = ThugUIDB.OrbEffects[target]
        if c and (c.effectKind or c.fillColor or c.texture) then
            local draft = store[target][OE.DRAFT]
            if not draft then
                local stack = {}
                if target == "pips" then
                    if c.texture and c.texture ~= "" and c.texture ~= 0 then
                        stack.layers = {
                            {
                                name = "Effect",
                                kind = "texture",
                                file = c.texture,
                                blend = c.blend or "auto",
                                scale = c.sizeScale or 1,
                                drain = false
                            }
                        }
                    end
                else
                    stack.fill = {
                        file = c.fillTexture or "",
                        color = ThugUI.OrbArt.Copy(c.fillColor) or {1, 1, 1},
                        alpha = c.fillAlpha or 1,
                        blend = "normal"
                    }
                    if c.effectFile and c.effectFile ~= "" and c.effectFile ~= 0 then
                        stack.layers = {
                            {
                                name = "Effect",
                                kind = c.effectKind or "model",
                                file = c.effectFile,
                                path = c.effectPath or "",
                                blend = c.effectBlend or "auto",
                                color = ThugUI.OrbArt.Copy(c.effectColor) or {1, 1, 1},
                                alpha = c.effectAlpha or 1,
                                scale = 1,
                                drain = true,
                                camDist = c.modelDist or 1,
                                camX = c.modelX or 0,
                                camY = c.modelY or 0,
                                camZ = c.modelZ or 0,
                                facing = c.modelFacing or 0,
                                x = 0, y = 0
                            }
                        }
                    end
                end
                
                local kind = target == "pips" and "pip" or "orb"
                local clean = ThugUI.OrbArt.Sanitize(stack, kind)
                store[target][OE.DRAFT] = { name = "Draft", stack = clean }
            end
            
            c.pack = c.enabled and "user:(draft)" or "default"
            c.adjust = {}
            
            c.effectKind, c.effectFile, c.effectPath, c.effectAlpha = nil, nil, nil, nil
            c.effectBlend, c.effectColor = nil, nil
            c.modelDist, c.modelX, c.modelY, c.modelZ, c.modelFacing = nil, nil, nil, nil, nil
            c.fillColor, c.fillAlpha, c.fillTexture = nil, nil, nil
            c.enabled, c.texture, c.blend, c.sizeScale = nil, nil, nil, nil
            
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("ORBFX", "migrated %s (pack %s)", target, c.pack)
            end
        end
    end
end

function OE:Initialize()
    self:Migrate()
    hooksecurefunc(ThugUI.Orbs, "Update", function(_, key) OE:UpdateValue(key) end)
    hooksecurefunc(ThugUI.Orbs, "ApplySettings", function(_, key) OE:Apply(key) end)
    
    local function UpdateResource()
        if not ThugUI:IsModuleOn("orbeffects") then return end
        OE:Apply("resource")
    end
    
    local driver = CreateFrame("Frame")
    driver:SetScript("OnEvent", function(_, event, unit)
        if not ThugUI:IsModuleOn("orbeffects") then return end
        if event == "UNIT_DISPLAYPOWER" and unit == "player" then
            UpdateResource()
        elseif event == "UPDATE_SHAPESHIFT_FORM" then
            UpdateResource()
        end
    end)
    pcall(driver.RegisterUnitEvent, driver, "UNIT_DISPLAYPOWER", "player")
    ThugUI.SafeRegisterEvent(driver, "UPDATE_SHAPESHIFT_FORM")

    OE:Apply("health")
    OE:Apply("resource")
end
