












ThugUI = ThugUI or {}

local MB = {}
ThugUI.MinimapButton = MB

local ICON = "Interface\\AddOns\\ThugUI\\media\\Acorn.tga"
local BUTTON_SIZE = 32
local ICON_SIZE = 20




local RIM_OFFSET = 5

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.MinimapButton = ThugUIDB.MinimapButton or {}
    return ThugUIDB.MinimapButton
end


function MB.PositionForAngle(angle, minimapWidth)
    local radius = (minimapWidth or 140) / 2 + RIM_OFFSET
    local rad = math.rad(angle)
    return radius * math.cos(rad), radius * math.sin(rad)
end



local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end


function MB.AngleTo(cx, cy, px, py)
    return math.deg(atan2(py - cy, px - cx))
end

function MB:SetDocked(docked)
    self.docked = docked
end

function MB:UpdatePosition()
    if self.docked then return end
    if not self.button or not Minimap then return end
    local angle = Cfg().angle or 225
    local x, y = MB.PositionForAngle(angle, Minimap:GetWidth())
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end




local function OnDragUpdate(button)
    if MB.docked then return end
    local mx, my = Minimap:GetCenter()
    if not mx then return end
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if scale and scale > 0 then
        px, py = px / scale, py / scale
    end
    Cfg().angle = MB.AngleTo(mx, my, px, py)
    MB:UpdatePosition()
end

function MB:OpenMenu()
    if not ThugUI.Window then return end
    local W = ThugUI.Widgets
    if not W then return end
    
    local rows = {}
    table.insert(rows, { text = "ThugUI", isTitle = true })
    
    for _, def in ipairs(ThugUI.Window.pages or {}) do
        local id = def.id
        
        
        if not (ThugUI.Modules and not ThugUI.Modules:PageOn(id)) then
        table.insert(rows, {
            text = def.title or id,
            isTitle = false,
            onClick = function()
                if ThugUI.Diagnostics and ThugUI.Diagnostics.Breadcrumb then
                    ThugUI.Diagnostics:Breadcrumb("Minimap menu: " .. (def.title or id))
                end
                ThugUI.Window:Open(id)
            end
        })
        end
    end
    
    W.ShowList(self.button, rows, 180)
end

function MB:Create()
    if self.button then return self.button end
    if not Minimap then
        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("MINIMAP", "no Minimap frame; button not created")
        end
        return nil
    end

    local button = CreateFrame("Button", "ThugUI_MinimapButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)

    
    
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    button.border = border

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(ICON_SIZE, ICON_SIZE)
    background:SetPoint("TOPLEFT", 6, -6)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", 6, -6)
    local r, g, b = ThugUI:GetClassColor()
    icon:SetVertexColor(r, g, b)
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetAllPoints(button)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            MB:OpenMenu()
        else
            ThugUI.Window:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ThugUI")
        GameTooltip:AddLine("Left-click: open the config window", 1, 1, 1)
        GameTooltip:AddLine("Right-click: jump to a page", 1, 1, 1)
        GameTooltip:AddLine("Drag: move around the minimap", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.button = button
    self:UpdatePosition()
    return button
end

function MB:SetShown(shown)
    Cfg().hidden = not shown
    if self.button then self.button:SetShown(shown) end
end

function MB:Initialize()
    local button = self:Create()
    if button and Cfg().hidden then button:Hide() end
end

ThugUI:RegisterModule("MinimapButton", MB)
