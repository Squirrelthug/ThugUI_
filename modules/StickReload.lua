








local ThugUI = _G.ThugUI
local StickReload = {}
ThugUI.StickReload = StickReload

local function Log(fmt, ...)
    if ThugUI.Diagnostics then ThugUI.Diagnostics:Log("RELOAD", fmt, ...) end
end













local XBOX, PLAYSTATION = "xbox", "playstation"


StickReload.XBOX, StickReload.PLAYSTATION = XBOX, PLAYSTATION
local VENDORS = { [0x045E] = XBOX, [0x054C] = PLAYSTATION }
local padKind      
local padSummary   

local function KindFromName(name)
    if type(name) ~= "string" then return nil end
    local n = name:lower()
    if n:find("xbox", 1, true) or n:find("xinput", 1, true) then return XBOX end
    if n:find("dualsense", 1, true) or n:find("dualshock", 1, true)
        or n:find("playstation", 1, true) or n:find("ps4", 1, true) or n:find("ps5", 1, true) then
        return PLAYSTATION
    end
    return nil
end



local function DescribeDevice(gp, id)
    local name, style, vendor, product
    if gp.GetDeviceRawState then
        local ok, raw = pcall(gp.GetDeviceRawState, id)
        if ok and type(raw) == "table" then
            name, vendor, product = raw.name, raw.vendorID, raw.productID
        end
    end
    if gp.GetDeviceMappedState then
        local ok, mapped = pcall(gp.GetDeviceMappedState, id)
        if ok and type(mapped) == "table" then
            name = name or mapped.name
            style = mapped.labelStyle
        end
    end
    local kind = (type(vendor) == "number" and VENDORS[vendor]) or KindFromName(name)
    local text = string.format("id=%s name=%s labelStyle=%s vendor=%s product=%s kind=%s",
        tostring(id), tostring(name), tostring(style),
        type(vendor) == "number" and string.format("0x%04X", vendor) or tostring(vendor),
        type(product) == "number" and string.format("0x%04X", product) or tostring(product),
        tostring(kind))
    return kind, text
end




function StickReload:IdentifyPad()
    local gp = _G.C_GamePad
    if not gp then
        padKind = nil
        return nil
    end
    local okActive, active = false, nil
    if gp.GetActiveDeviceID then
        okActive, active = pcall(gp.GetActiveDeviceID)
    end
    local ids = {}
    if gp.GetAllDeviceIDs then
        local ok, all = pcall(gp.GetAllDeviceIDs)
        if ok and type(all) == "table" then ids = all end
    end
    local kind, lines = nil, {}
    if okActive and active ~= nil then
        local k, text = DescribeDevice(gp, active)
        kind = k
        lines[#lines + 1] = "active " .. text
    end
    for _, id in ipairs(ids) do
        if id ~= active then
            local k, text = DescribeDevice(gp, id)
            kind = kind or k
            lines[#lines + 1] = text
        end
    end
    padKind = kind
    local summary = table.concat(lines, " | ")
    if summary ~= padSummary then
        padSummary = summary
        Log("pad: %s", summary ~= "" and summary or "no device")
        Log("pad kind: %s", tostring(kind))
    end
    return kind
end



function StickReload:PadKind()
    if padKind == nil then self:IdentifyPad() end
    return padKind
end



function StickReload:Refresh()
    return self:IdentifyPad()
end


function StickReload:ForgetPad()
    padKind, padSummary = nil, nil
end





local events = CreateFrame("Frame", "ThugUI_StickReloadEvents")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "GAME_PAD_CONNECTED" or event == "GAME_PAD_DISCONNECTED"
        or event == "GAME_PAD_ACTIVE_CHANGED" then
        StickReload:IdentifyPad()
    end
end)
ThugUI.SafeRegisterEvent(events, "PLAYER_LOGIN")
ThugUI.SafeRegisterEvent(events, "GAME_PAD_CONNECTED")
ThugUI.SafeRegisterEvent(events, "GAME_PAD_DISCONNECTED")
ThugUI.SafeRegisterEvent(events, "GAME_PAD_ACTIVE_CHANGED")
