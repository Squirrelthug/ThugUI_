


ThugUI = ThugUI or {}
ThugUI.modules = {}


ThugUI.Dialogs = ThugUI.Dialogs or {}


ThugUI.name = "ThugUI"


do
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local ok, v = false, nil
    if get then ok, v = pcall(get, "ThugUI", "Version") end
    ThugUI.version = (ok and type(v) == "string" and v ~= "") and v or "2.1.0"
end





local _, _, _, interfaceNumber = GetBuildInfo()
ThugUI.client = (tonumber(interfaceNumber) or 0) < 100000 and "forever" or "retail"






if ThugUI.client ~= "forever" then
    ThugUI_Profiles, ThugUI_Packs, ThugUI_DebugLog, ThugUI_BCVDump, ThugUI_Character = nil, nil, nil, nil, nil
    ThugUI_Config, ThugUIDB = nil, nil
end


ThugUIDB = ThugUIDB or {}


ThugUI.defaults = {
    CursorCooldowns = {
        enabled = true,
        showOnlyInCombat = true,
        updateFrequency = 0.016,  
        
        
        gcdRingSize = 36,
        gcdRingColor = {1, 1, 1, 0.9},
        useClassColor = true,
        
        
        castRingSize = 48,
        castRingColor = {0.2, 0.8, 1, 0.9},
        
        
        centerDotSize = 8,
        centerDotColor = {1, 1, 1, 1},
        
        
        anchorEssentialCooldowns = true,
        essentialCooldownsFrameName = "EssentialCooldownViewer",
        essentialCooldownsOffsetY = 50,
        essentialCooldownsScale = 1.0,
    },
    Acorns = {
        enabled = true,
        
        
        
        
        
        locked = true,
        chat = {
            enabled = true,
            mode = 1, 
            
            
            iconTexture = "Interface\\AddOns\\ThugUI\\media\\Acorn.tga",
            point = "BOTTOMLEFT",
            x = 25,
            y = 220,
            size = 36,
            color = {0.2, 0.7, 1.0, 0.9},
            streamWidth = 420,
            streamHeight = 220,
            fontSize = 14,
            fontOutline = "OUTLINE",
            showTimestamp = false,
            
            
            
            
            
            channels = {
                SAY = true,
                EMOTE = true,
                YELL = true,
                WHISPER = true,
                PARTY = true,   
                RAID = true,
                GUILD = true,
                OFFICER = true,
                CHANNEL = false,
                SYSTEM = false,
            },
        },
        objectives = {
            enabled = true,
            visible = true, 
            
            
            
            
            iconTexture = "Interface\\AddOns\\ThugUI\\media\\Acorn.tga",
            point = "TOPRIGHT",
            x = -260,
            y = -220,
            size = 36,
            color = {1.0, 0.82, 0.2, 0.9},
        },
    },
    
    
    
    MinimapButton = {
        angle = 225,
        hidden = false,
    },
    
    
    
    
    
    Seasonal = {
        window = { point = "CENTER", x = 0, y = 0 },
        collapsed = {},
    },
    Automation = {
        sellJunk = true,
        sellJunkBlacklist = {},
        autoRepair = true,
        preferGuildRepair = true,
        announce = true,
    },
    ActionBars = {
        enabled = true,
        bars = {
            MainActionBar = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
            MultiBarBottomLeft = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
            MultiBarBottomRight = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
            MultiBarRight = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
            MultiBarLeft = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
            MultiBar5 = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
            MultiBar6 = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
            MultiBar7 = {
                managed = false,
                vertical = false,
                perLine = 12,
                numButtons = 12,     
                hideHotkey = false,  
                hideMacroName = false,
                hideCount = false,   
                buttonSize = 45,
                spacing = 2,
                reverse = false,
                lockPage = false,
            },
        },
    },
    Nameplates = {
        enabled = true,
        friendly = {
            nameOnlyOutOfCombat = false,
            
            
            savedShowOnlyNames = nil,
        },
        enemy = {
            nameOnlyOutOfCombat = false,
            nameOnlyColor = { 1.0, 0.25, 0.25 },   
        },
        bars = {
            hideBorder = false,     
            hideWhenFull = false,   
        },
        target = {
            highlight = true,       
            color = { 1.0, 0.82, 0.0 },   
            thickness = 2,          
        },
        level = {
            show = true,
            size = 10,              
            fonts = {
                normal = "Fonts\\FRIZQT__.TTF",
                elite  = "Fonts\\FRIZQT__.TTF",
                rare   = "Fonts\\MORPHEUS.TTF",
                boss   = "Fonts\\SKURRI.TTF",
            },
        },
    },
    
    GearFlags = {
        enabled = true,
        flagMissingEnchant = true,
        flagEmptySocket = true,
        
        
        
        showFlagBorder = true,
        showSetBorder = true,
        
        
        
        
        enchantSlots = {
            [INVSLOT_HEAD] = true,
            [INVSLOT_SHOULDER] = true,
            [INVSLOT_CHEST] = true,
            [INVSLOT_LEGS] = true,
            [INVSLOT_FEET] = true,
            [INVSLOT_FINGER1] = true,
            [INVSLOT_FINGER2] = true,
            [INVSLOT_MAINHAND] = true,
            [INVSLOT_OFFHAND] = true,
        },
        
        
        slotListVersion = 2,
    },
}


ThugUI.classColors = {
    WARRIOR = {0.78, 0.61, 0.43},
    PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45},
    ROGUE = {1.00, 0.96, 0.41},
    PRIEST = {1.00, 1.00, 1.00},
    DEATHKNIGHT = {0.77, 0.12, 0.23},
    SHAMAN = {0.00, 0.44, 0.87},
    MAGE = {0.41, 0.80, 0.94},
    WARLOCK = {0.58, 0.51, 0.79},
    MONK = {0.00, 1.00, 0.59},
    DRUID = {1.00, 0.49, 0.04},
    DEMONHUNTER = {0.64, 0.19, 0.79},
    EVOKER = {0.20, 0.58, 0.50},
}

function ThugUI:GetClassColor()
    local _, class = UnitClass("player")
    if class and self.classColors[class] then
        return unpack(self.classColors[class])
    end
    return 1, 1, 1
end


local function DeepMergeDefaults(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            DeepMergeDefaults(target[k], v)
        elseif target[k] == nil then
            if type(v) == "table" then
                target[k] = {}
                DeepMergeDefaults(target[k], v)
            else
                target[k] = v
            end
        end
    end
end


function ThugUI:InitializeDB()
    for moduleName, moduleDefaults in pairs(self.defaults) do
        if not ThugUIDB[moduleName] then
            ThugUIDB[moduleName] = {}
        end
        DeepMergeDefaults(ThugUIDB[moduleName], moduleDefaults)
    end
end


function ThugUI:RegisterModule(name, module)
    self.modules[name] = module
end





function ThugUI.SafeRegisterEvent(frame, event)
    local ok, err = pcall(frame.RegisterEvent, frame, event)
    if not ok then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("INIT", "RegisterEvent(%q) failed: %s", event, tostring(err))
        end
        return false
    end
    return true
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ThugUI" then
        
        
        
        
        if ThugUI.Profiles then ThugUI.Profiles:Bootstrap() end

        ThugUI:InitializeDB()
        
        
        if ThugUI.Modules then ThugUI.Modules:Snapshot() end

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        for name, module in pairs(ThugUI.modules) do
            if ThugUI.Modules and not ThugUI.Modules:ModuleNameOn(name) then
                if ThugUI.Diagnostics then
                    ThugUI.Diagnostics:Log("MODULES", string.format("%s off, not initialised", tostring(name)))
                end
            elseif module.Initialize then
                local ok, err = pcall(module.Initialize, module)
                if not ok then
                    
                    
                    
                    if ThugUI.Diagnostics then
                        ThugUI.Diagnostics:Log("INIT", "module %s failed to initialise: %s",
                            tostring(name), tostring(err))
                    end
                    print("|cffff0000ThugUI|r: module '" .. tostring(name)
                        .. "' failed to initialise. Other modules were unaffected.")
                end
            end
        end
        
        print("|cff00ff00ThugUI|r v" .. ThugUI.version .. " loaded.")
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
