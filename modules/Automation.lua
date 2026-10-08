





ThugUI = ThugUI or {}

local Automation = {}
ThugUI.Automation = Automation

local SELL_BATCH = 8

local function Cfg()
    ThugUIDB = ThugUIDB or {}
    ThugUIDB.Automation = ThugUIDB.Automation or {}
    ThugUIDB.Automation.sellJunkBlacklist = ThugUIDB.Automation.sellJunkBlacklist or {}
    return ThugUIDB.Automation
end





function Automation:GetBlacklist()
    return Cfg().sellJunkBlacklist
end

function Automation:AddBlacklistEntry(text)
    
    local trimmed = text:match("^%s*(.-)%s*$")

    
    if not trimmed or trimmed == "" then
        return false, "empty"
    end

    
    local lowered = trimmed:lower()

    
    local blacklist = self:GetBlacklist()
    for _, entry in ipairs(blacklist) do
        if entry:lower() == lowered then
            return false, "duplicate"
        end
    end

    table.insert(blacklist, lowered)
    return true
end

function Automation:RemoveBlacklistEntry(i)
    local blacklist = self:GetBlacklist()
    if blacklist[i] then
        table.remove(blacklist, i)
    end
end

function Automation:IsBlacklisted(itemName)
    if not itemName or itemName == "" then
        return false
    end

    local haystack = itemName:lower()
    local blacklist = self:GetBlacklist()

    for _, entry in ipairs(blacklist) do
        
        
        
        if entry ~= "" and haystack:find(entry, 1, true) then
            return true
        end
    end

    return false
end





function Automation:BuildSellList()
    if not Cfg().sellJunk then
        return {}
    end

    local list = {}

    
    local maxBag = NUM_BAG_SLOTS or 4

    for bag = 0, maxBag do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info then
                    
                    
                    
                    
                    
                    if info.quality == Enum.ItemQuality.Poor
                        and not info.hasNoValue
                        and not info.isLocked
                        and not self:IsBlacklisted(info.itemName) then
                        table.insert(list, {
                            bag = bag,
                            slot = slot,
                            name = info.itemName,
                        })
                    end
                end
            end
        end
    end

    return list
end

function Automation:SellBatch(list, from)
    local to = math.min(from + SELL_BATCH - 1, #list)

    for i = from, to do
        local entry = list[i]
        C_Container.UseContainerItem(entry.bag, entry.slot)
    end

    return to + 1
end

function Automation:StartSell()
    local list = self:BuildSellList()
    if #list == 0 then
        self:TryRepair()
        return
    end

    self.selling = true
    self.sellList = list
    self.sellIndex = 1

    self:ContinueSell()
end

function Automation:ContinueSell()
    if not self.selling then
        return
    end

    local nextIndex = self:SellBatch(self.sellList, self.sellIndex)

    if nextIndex > #self.sellList then
        
        
        
        
        local soldCount = #self.sellList
        self.selling = false
        self.sellList = nil
        self.sellIndex = nil
        self:OnSellComplete(soldCount)
    else
        
        self.sellIndex = nextIndex
        C_Timer.After(0.2, function() self:ContinueSell() end)
    end
end

function Automation:OnSellComplete(soldCount)
    soldCount = soldCount or 0
    
    
    
    local initialMoney = self.startMoney or GetMoney()

    local function DoReportAndRepair()
        local moneySold = GetMoney() - initialMoney

        if Cfg().announce and soldCount > 0 then
            local fmt = GetCoinTextureString or tostring
            print("|cff00ff00ThugUI:|r sold " .. soldCount .. " item(s), " .. fmt(moneySold) .. ".")
        end

        if ThugUI.Diagnostics then
            ThugUI.Diagnostics:Log("AUTOMATION", "sold %d items, earned %d copper", soldCount, moneySold)
        end

        self:TryRepair()
    end

    if soldCount > 0 and GetMoney() == initialMoney and self.eventFrame then
        
        
        
        
        
        local reported = false
        local function report()
            if reported then return end
            reported = true
            if self.reportEarnings == report then
                self.reportEarnings = nil
                self.eventFrame:UnregisterEvent("PLAYER_MONEY")
            end
            DoReportAndRepair()
        end
        self.reportEarnings = report
        self.eventFrame:RegisterEvent("PLAYER_MONEY")
        C_Timer.After(2, report)
    else
        DoReportAndRepair()
    end
end





function Automation:TryRepair()
    if not Cfg().autoRepair then return end
    if not CanMerchantRepair() then return end

    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost <= 0 then return end

    local usedGuild = false
    if Cfg().preferGuildRepair and CanGuildBankRepair() then
        local limit = GetGuildBankWithdrawMoney()
        local available
        if limit == -1 then
            
            available = GetGuildBankMoney() or 0
        else
            available = math.min(limit or 0, GetGuildBankMoney() or 0)
        end
        if available >= cost then
            RepairAllItems(true)
            usedGuild = true
        end
    end

    if not usedGuild then
        if GetMoney() >= cost then
            RepairAllItems()
        else
            
            if Cfg().announce then
                local fmt = GetCoinTextureString or tostring
                print("|cff00ff00ThugUI:|r could not afford repair (" .. fmt(cost) .. ").")
            end
            if ThugUI.Diagnostics then
                ThugUI.Diagnostics:Log("AUTOMATION", "could not afford repair (%d copper)", cost)
            end
            return
        end
    end

    if Cfg().announce then
        local fmt = GetCoinTextureString or tostring
        local suffix = usedGuild and " (guild funds)" or ""
        print("|cff00ff00ThugUI:|r repaired " .. fmt(cost) .. suffix .. ".")
    end

    if ThugUI.Diagnostics then
        local method = usedGuild and "guild" or "personal"
        ThugUI.Diagnostics:Log("AUTOMATION", "repaired for %d copper using %s funds", cost, method)
    end
end










function Automation:OnTradeShow()
    if OpenAllBags then OpenAllBags(_G.TradeFrame) end
end

function Automation:OnTradeClosed()
    if CloseAllBags then CloseAllBags(_G.TradeFrame) end
end

function Automation:Initialize()
    local frame = CreateFrame("Frame")
    Automation.eventFrame = frame

    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("TRADE_SHOW")
    frame:RegisterEvent("TRADE_CLOSED")

    frame:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_SHOW" then
            Automation.startMoney = GetMoney()
            Automation:StartSell()
        elseif event == "MERCHANT_CLOSED" then
            Automation.selling = false
            Automation.sellList = nil
            Automation.sellIndex = nil
        elseif event == "TRADE_SHOW" then
            Automation:OnTradeShow()
        elseif event == "TRADE_CLOSED" then
            Automation:OnTradeClosed()
        elseif event == "PLAYER_MONEY" then
            if Automation.reportEarnings then
                Automation.reportEarnings()
            end
        end
    end)
end

ThugUI:RegisterModule("Automation", Automation)
