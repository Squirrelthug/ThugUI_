







local ThugUI = _G.ThugUI
local CC = {}
ThugUI.CombatClose = CC

local registry = {}
local names = {}

function CC:Register(name, isOpen, close, opts)
    if not registry[name] then
        table.insert(names, name)
    end
    registry[name] = {
        isOpen = isOpen,
        close = close,
        opts = opts
    }
end

function CC:Allow(name)
    local entry = registry[name]
    if (not InCombatLockdown()) or (entry and entry.opts and entry.opts.reopenInCombat) then
        return true
    end
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage("Not in combat.", 1, 0.1, 0.1, 1)
    end
    return false
end

local function LogMsg(msg)
    if ThugUI.Diagnostics and ThugUI.Diagnostics.Log then
        ThugUI.Diagnostics:Log("COMBAT", msg)
    else
        print("COMBAT: " .. msg)
    end
end

function CC:CloseAll()
    for _, name in ipairs(names) do
        local entry = registry[name]
        local ok, open = pcall(entry.isOpen)
        if ok and open then
            local cOk, cErr = pcall(entry.close)
            if cOk then
                LogMsg("closed " .. name)
            else
                LogMsg("close " .. name .. " failed: " .. tostring(cErr))
            end
        end
    end
end

local frame = CreateFrame("Frame", "ThugUI_CombatCloseEventFrame")
ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_DISABLED")
local firstFire = true
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        if firstFire then
            firstFire = false
            LogMsg("lockdown at REGEN_DISABLED = " .. tostring(InCombatLockdown()))
        end
        CC:CloseAll()
    end
end)
