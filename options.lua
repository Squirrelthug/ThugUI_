

















ThugUI = ThugUI or {}

local OptionsMenu = {}
ThugUI.OptionsMenu = OptionsMenu

function OptionsMenu:Toggle(pageID)
    ThugUI.Window:Toggle(pageID)
end

function OptionsMenu:Open(pageID)
    ThugUI.Window:Open(pageID)
end

function ThugUI:ToggleOptions(pageID)
    ThugUI.Window:Toggle(pageID)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addon)
    if event ~= "ADDON_LOADED" or addon ~= "ThugUI" then return end

    SLASH_THUGUI1 = "/thugui"
    SLASH_THUGUI2 = "/thug"
    SLASH_THUGUI3 = "/tui"
    SlashCmdList["THUGUI"] = function(msg)
        msg = (msg or ""):lower():match("^%s*(.-)%s*$")
        
        
        ThugUI.Window:Toggle(msg ~= "" and msg or nil)
    end

    self:UnregisterEvent("ADDON_LOADED")
end)
