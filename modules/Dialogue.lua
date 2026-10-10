










local ThugUI = _G.ThugUI
local Dialogue = {}
ThugUI.Dialogue = Dialogue
ThugUI:RegisterModule("Dialogue", Dialogue)

ThugUI.defaults.Dialogue = {
    enabled       = true,
    revealInstant = false,
    revealSpeed   = 35,
    holdTime      = 4,
    fontSize      = 16,
    width         = 440,
    opacity       = 0.6,
    locked        = true,
    point = "RIGHT", x = -80, y = 0,
}

function Dialogue.SplitParagraphs(text)
    if not text or text == "" then return {} end
    local paragraphs = {}
    for p_raw in text:gmatch("[^\n]+") do
        local p = p_raw:match("^%s*(.-)%s*$")
        if p ~= "" then
            table.insert(paragraphs, p)
        end
    end
    return paragraphs
end




function Dialogue.VisibleLength(text)
    local len = 0
    local i = 1
    while i <= #text do
        local c = text:sub(i, i)
        if c == "|" then
            local n2 = text:sub(i+1, i+1)
            if n2 == "c" then i = i + 10
            elseif n2 == "r" or n2 == "n" or n2 == "h" then i = i + 2
            elseif n2 == "T" or n2 == "t" then
                local endT = text:find("|t", i)
                i = endT and (endT + 2) or (i + 2)
            elseif n2 == "H" then
                local endH = text:find("|h", i)
                i = endH and (endH + 2) or (i + 2)
            else
                len = len + 1
                i = i + 1
            end
        else
            local b = string.byte(c)
            local charBytes = 1
            if b >= 194 and b <= 223 then charBytes = 2
            elseif b >= 224 and b <= 239 then charBytes = 3
            elseif b >= 240 and b <= 244 then charBytes = 4 end
            len = len + 1
            i = i + charBytes
        end
    end
    return len
end

function Dialogue.RevealPrefix(text, n)
    local out = ""
    local visibleCount = 0
    local i = 1
    while i <= #text do
        local c = text:sub(i, i)
        local isVisible = false
        local tokenStr = ""
        local nextI = i
        
        if c == "|" then
            local n2 = text:sub(i+1, i+1)
            if n2 == "c" then
                tokenStr = text:sub(i, i+9)
                nextI = i + 10
            elseif n2 == "r" or n2 == "n" or n2 == "h" then
                tokenStr = text:sub(i, i+1)
                nextI = i + 2
            elseif n2 == "T" or n2 == "t" then
                local endT = text:find("|t", i)
                if endT then
                    tokenStr = text:sub(i, endT + 1)
                    nextI = endT + 2
                else
                    tokenStr = text:sub(i, i+1)
                    nextI = i + 2
                end
            elseif n2 == "H" then
                local endH = text:find("|h", i)
                if endH then
                    tokenStr = text:sub(i, endH + 1)
                    nextI = endH + 2
                else
                    tokenStr = text:sub(i, i+1)
                    nextI = i + 2
                end
            else
                isVisible = true
                tokenStr = c
                nextI = i + 1
            end
        else
            isVisible = true
            local b = string.byte(c)
            local charBytes = 1
            if b >= 194 and b <= 223 then charBytes = 2
            elseif b >= 224 and b <= 239 then charBytes = 3
            elseif b >= 240 and b <= 244 then charBytes = 4 end
            tokenStr = text:sub(i, i + charBytes - 1)
            nextI = i + charBytes
        end
        
        if isVisible then
            if visibleCount >= n then break end
            visibleCount = visibleCount + 1
        end
        out = out .. tokenStr
        i = nextI
    end
    return out
end

local frame = CreateFrame("Frame", "ThugUI_DialogueFrame", UIParent)
frame:SetFrameStrata("HIGH")
frame:Hide()


if frame.SetIgnoreParentAlpha then
    frame:SetIgnoreParentAlpha(true)
end

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()

local titleString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleString:SetPoint("TOPLEFT", 16, -16)
titleString:SetPoint("TOPRIGHT", -16, -16)
titleString:SetJustifyH("LEFT")






titleString:SetWordWrap(false)







local textScroll = CreateFrame("ScrollFrame", nil, frame)


textScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -48)
textScroll:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -48)

local textChild = CreateFrame("Frame", nil, textScroll)
textChild:SetSize(1, 1)
textScroll:SetScrollChild(textChild)

local textString = textChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
textString:SetPoint("TOPLEFT", textChild, "TOPLEFT", 0, 0)
textString:SetPoint("TOPRIGHT", textChild, "TOPRIGHT", 0, 0)
textString:SetJustifyH("LEFT")
textString:SetJustifyV("TOP")
textString:SetWordWrap(true)

local hitRect = CreateFrame("Button", nil, frame)
hitRect:SetPoint("TOPLEFT", textScroll)
hitRect:SetPoint("BOTTOMRIGHT", textScroll)

local rewardsContainer = CreateFrame("Frame", nil, frame)
rewardsContainer:SetPoint("TOPLEFT", textScroll, "BOTTOMLEFT", 0, -16)
rewardsContainer:SetPoint("TOPRIGHT", textScroll, "BOTTOMRIGHT", 0, -16)
rewardsContainer:SetHeight(1)

local optionsContainer = CreateFrame("Frame", nil, frame)
optionsContainer:SetPoint("TOPLEFT", rewardsContainer, "BOTTOMLEFT", 0, -16)
optionsContainer:SetPoint("TOPRIGHT", rewardsContainer, "BOTTOMRIGHT", 0, -16)
optionsContainer:SetHeight(1)

local legendString = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
legendString:SetPoint("TOPLEFT", optionsContainer, "BOTTOMLEFT", 0, -16)
legendString:SetPoint("TOPRIGHT", optionsContainer, "BOTTOMRIGHT", 0, -16)
legendString:SetJustifyH("LEFT")
legendString:Hide()

frame.__hitRect = hitRect
frame.__textScroll = textScroll
frame.__textString = textString
frame.__rewardsContainer = rewardsContainer
frame.__optionsContainer = optionsContainer
frame.__legendString = legendString

local state = {
    panel = nil,
    paragraphs = {},
    paragraphIndex = 1,
    phase = "hidden",
    textLen = 0,
    revealCount = 0,
    holdTimer = 0,
    rewardChoice = 0,
    closeGen = 0,
    
    
    manualScroll = false,
}





local REWARD_ROW = 0
local selectedLine = 1
local padFocus = 0
local gamepadActive = false

function Dialogue:GetState()
    return state.panel, state.paragraphIndex, state.phase
end

function Dialogue:GetSelectedLine()
    return selectedLine
end

function Dialogue:GetPadFocus()
    return padFocus
end




local function Readable(v)
    return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end

local function TitleHeight()
    return (ThugUIDB.Dialogue.fontSize or 14) + 2
end

local function BoxHeight()
    return (ThugUIDB.Dialogue.fontSize or 14) * 6
end




local function EstimateTextHeight()
    local text = textString:GetText()
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return 0 end
    local fs = ThugUIDB.Dialogue.fontSize or 14
    local perLine = math.max(1, math.floor(((ThugUIDB.Dialogue.width or 500) - 32) / (fs * 0.5)))
    local lines = 0
    for seg in (text .. "\n"):gmatch("(.-)\n") do
        lines = lines + math.max(1, math.ceil(#seg / perLine))
    end
    return lines * fs * 1.2
end

local function TextHeight()
    local h = textString:GetStringHeight()
    if Readable(h) then return h end
    return EstimateTextHeight()
end

local function ScrollPos()
    local pos = textScroll:GetVerticalScroll()
    return Readable(pos) and pos or 0
end




local function OverflowHeight()
    local textH = TextHeight()
    textChild:SetHeight(math.max(textH, 1))
    local over = textH - BoxHeight()
    return over > 0 and over or 0
end



local function SetBodyText(text, fromTop)
    textString:SetText(text)
    if fromTop then
        state.manualScroll = false
        textScroll:SetVerticalScroll(0)
    end
    OverflowHeight()
end




local function FollowReveal()
    if state.manualScroll or ThugUIDB.Dialogue.revealInstant then return end
    textScroll:SetVerticalScroll(OverflowHeight())
end






local function ScrollDuringHold(elapsed)
    if state.manualScroll then return true end
    local over = OverflowHeight()
    local pos = ScrollPos()
    if pos >= over then return true end
    local textH = TextHeight()
    local pace = 30
    if state.textLen and state.textLen > 0 and textH > 0 then
        pace = ThugUIDB.Dialogue.revealSpeed * textH / state.textLen
    end
    textScroll:SetVerticalScroll(math.min(over, pos + pace * elapsed))
    return false
end



hitRect:EnableMouseWheel(true)
hitRect:SetScript("OnMouseWheel", function(_, delta)
    local over = OverflowHeight()
    if over <= 0 then return end
    state.manualScroll = true
    local step = (ThugUIDB.Dialogue.fontSize or 14) * 2
    local pos = ScrollPos() - delta * step
    textScroll:SetVerticalScroll(math.max(0, math.min(over, pos)))
end)

local function UpdateHeight()
    local h = 16
    h = h + TitleHeight() + 16
    h = h + BoxHeight() + 16
    
    local function Add(region, fallback)
        local v = region:GetHeight()
        h = h + (Readable(v) and v or fallback) + 16
    end
    if rewardsContainer:IsShown() then Add(rewardsContainer, 0) end
    if optionsContainer:IsShown() then Add(optionsContainer, 0) end
    if legendString:IsShown() then Add(legendString, (ThugUIDB.Dialogue.fontSize or 14)) end
    frame:SetHeight(h)
end

function Dialogue:ApplyLayout()
    local cfg = ThugUIDB.Dialogue
    frame:SetWidth(cfg.width)
    
    local tr, tg, tb = ThugUI.Theme:Color("background")
    bg:SetColorTexture(tr, tg, tb, cfg.opacity)
    
    local font, _, flags = titleString:GetFont()
    titleString:SetFont(font, cfg.fontSize - 2, flags)
    ThugUI.Theme:Paint(titleString, "pageTitle")
    titleString:SetHeight(TitleHeight())
    local top = -(16 + TitleHeight() + 16)
    textScroll:ClearAllPoints()
    textScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, top)
    textScroll:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, top)
    
    local font2, _, flags2 = textString:GetFont()
    textString:SetFont(font2, cfg.fontSize, flags2)
    
    textScroll:SetHeight(cfg.fontSize * 6)
    
    textChild:SetWidth(cfg.width - 32)
    OverflowHeight()
    
    
    
    frame:ClearAllPoints()
    frame:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)
    
    
    
    
    
    
    
    local function DragStart()
        frame:StartMoving()
    end
    local function DragStop()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint()
        cfg.point = point
        cfg.x = x
        cfg.y = y
        frame:SetUserPlaced(false)
    end
    if cfg.locked then
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:RegisterForDrag()
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
        hitRect:RegisterForDrag()
        hitRect:SetScript("OnDragStart", nil)
        hitRect:SetScript("OnDragStop", nil)
    else
        frame:SetMovable(true)
        frame:SetClampedToScreen(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", DragStart)
        frame:SetScript("OnDragStop", DragStop)
        hitRect:RegisterForDrag("LeftButton")
        hitRect:SetScript("OnDragStart", DragStart)
        hitRect:SetScript("OnDragStop", DragStop)
    end
    
    if frame:IsShown() then
        UpdateHeight()
    end
end

local function AdvanceParagraph()
    if state.phase == "revealing" then
        state.revealCount = state.textLen
        SetBodyText(state.paragraphs[state.paragraphIndex])
        state.phase = "holding"
        state.holdTimer = 0
    elseif state.phase == "holding" then
        state.paragraphIndex = state.paragraphIndex + 1
        if state.paragraphIndex > #state.paragraphs then
            state.paragraphIndex = 1
        end
        state.phase = "revealing"
        state.revealCount = 0
        state.holdTimer = 0
        
        local p = state.paragraphs[state.paragraphIndex]
        if p then
            state.textLen = Dialogue.VisibleLength(p)
        end
        SetBodyText("", true)
    end
end

hitRect:SetScript("OnClick", AdvanceParagraph)

frame:SetScript("OnUpdate", function(self, elapsed)
    if state.phase == "revealing" then
        if #state.paragraphs == 0 then
            state.phase = "holding"
            return
        end
        
        local cfg = ThugUIDB.Dialogue
        local p = state.paragraphs[state.paragraphIndex]
        
        if cfg.revealInstant then
            state.revealCount = state.textLen
        else
            state.revealCount = state.revealCount + (cfg.revealSpeed * elapsed)
        end
        
        if state.revealCount >= state.textLen then
            SetBodyText(p)
            FollowReveal()
            state.phase = "holding"
            state.holdTimer = 0
        else
            SetBodyText(Dialogue.RevealPrefix(p, math.floor(state.revealCount)))
            FollowReveal()
        end
    elseif state.phase == "holding" then
        if #state.paragraphs == 0 then return end
        
        local cfg = ThugUIDB.Dialogue
        
        if not ScrollDuringHold(elapsed) then return end
        state.holdTimer = state.holdTimer + elapsed
        if state.holdTimer >= cfg.holdTime then
            state.paragraphIndex = state.paragraphIndex + 1
            if state.paragraphIndex > #state.paragraphs then
                state.paragraphIndex = 1
            end
            state.phase = "revealing"
            state.revealCount = 0
            state.holdTimer = 0
            
            local p = state.paragraphs[state.paragraphIndex]
            if p then
                state.textLen = Dialogue.VisibleLength(p)
            end
            SetBodyText("", true)
        end
    end
end)

local optionsLinesPool = {}
local function GetOptionLine(i)
    if not optionsLinesPool[i] then
        local btn = CreateFrame("Button", nil, optionsContainer)
        btn:SetHeight(20)
        btn:SetPoint("LEFT")
        btn:SetPoint("RIGHT")
        if i == 1 then
            btn:SetPoint("TOP")
        else
            btn:SetPoint("TOP", optionsLinesPool[i-1], "BOTTOM", 0, -4)
        end
        
        local hl = btn:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        ThugUI.Theme:Paint(hl, "selectedFill", "fill")
        hl:Hide()
        btn.padHighlight = hl
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT")
        text:SetPoint("RIGHT")
        text:SetJustifyH("LEFT")
        btn:SetFontString(text)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetDisabledFontObject("GameFontDisable")
        optionsLinesPool[i] = btn
        
        btn:SetScript("OnClick", function(self)
            if self.action then self.action() end
        end)
    end
    return optionsLinesPool[i]
end

local function ClearOptions()
    for _, btn in ipairs(optionsLinesPool) do
        btn:Hide()
        btn.action = nil
        btn:Enable()
    end
end

local rewardItemsPool = {}
frame.__rewardItems = rewardItemsPool
local function ClearRewards()
    for _, item in ipairs(rewardItemsPool) do
        item:Hide()
        item.type = nil
        item.index = nil
        if item.highlight then item.highlight:Hide() end
        if item.padFocus then item.padFocus:Hide() end
    end
    rewardsContainer:Hide()
end



local UpdateSelection

local function EvaluateCompleteLine()
    for _, btn in ipairs(optionsLinesPool) do
        if btn.isCompleteLine then
            if GetNumQuestChoices and GetNumQuestChoices() > 1 and state.rewardChoice == 0 then
                btn:Disable()
            else
                btn:Enable()
            end
        end
    end
    if UpdateSelection then UpdateSelection() end
end

local PAD_CONFIRM = GAMEPAD_FACE_BOTTOM or "PAD1"
local PAD_BACK = GAMEPAD_FACE_RIGHT or "PAD2"
local PAD_UP = GAMEPAD_DPAD_TOP or "PADDUP"
local PAD_DOWN = GAMEPAD_DPAD_BOTTOM or "PADDDOWN"
local PAD_LEFT = GAMEPAD_DPAD_LEFT or "PADDLEFT"
local PAD_RIGHT = GAMEPAD_DPAD_RIGHT or "PADDRIGHT"
local PAD_NEXT = GAMEPAD_SHOULDER_RIGHT or "PADRSHOULDER"




local rewardTooltip
local function RewardTooltip()
    if not rewardTooltip then
        local ok, tip = pcall(CreateFrame, "GameTooltip", "ThugUI_DialogueTooltip", frame, "GameTooltipTemplate")
        rewardTooltip = ok and tip or GameTooltip
    end
    return rewardTooltip
end

local function ShowRewardTooltip(item)
    local tip = RewardTooltip()
    if tip and item.type and item.index and tip.SetQuestItem then
        tip:SetOwner(item, "ANCHOR_RIGHT")
        tip:SetQuestItem(item.type, item.index)
    end
end

local function HideRewardTooltip()
    if rewardTooltip then rewardTooltip:Hide() end
end

local function ChoiceItem(index)
    for _, item in ipairs(rewardItemsPool) do
        if item.type == "choice" and item.index == index and item:IsShown() then
            return item
        end
    end
end

local function NumChoiceItems()
    local n = 0
    for _, item in ipairs(rewardItemsPool) do
        if item.type == "choice" and item:IsShown() then n = n + 1 end
    end
    return n
end



local function PadStops()
    local stops = {}
    if NumChoiceItems() > 0 then
        table.insert(stops, REWARD_ROW)
    end
    for i, btn in ipairs(optionsLinesPool) do
        if btn:IsShown() and btn:IsEnabled() then
            table.insert(stops, i)
        end
    end
    return stops
end

function UpdateSelection()
    if not gamepadActive then return end

    local stops = PadStops()
    local found = false
    for _, s in ipairs(stops) do
        if s == selectedLine then found = true break end
    end
    if not found and stops[1] then
        selectedLine = stops[1]
    end
    if selectedLine == REWARD_ROW and not ChoiceItem(padFocus) then
        padFocus = (state.rewardChoice > 0) and state.rewardChoice or 1
    end

    for i, btn in ipairs(optionsLinesPool) do
        if btn:IsShown() and btn:IsEnabled() and i == selectedLine then
            if btn.padHighlight then btn.padHighlight:Show() end
        elseif btn.padHighlight then
            btn.padHighlight:Hide()
        end
    end

    
    
    local onRow = selectedLine == REWARD_ROW
    for _, item in ipairs(rewardItemsPool) do
        if item.padFocus then
            item.padFocus:SetShown(onRow and item.type == "choice" and item.index == padFocus and item:IsShown())
        end
    end
    local focused = onRow and ChoiceItem(padFocus)
    if focused then
        ShowRewardTooltip(focused)
    else
        HideRewardTooltip()
    end

    if InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled() then
        local function GetKeyText(key)
            if GetBindingText then
                local text = GetBindingText(key, true)
                if text and text ~= "" then return text end
            end
            return key
        end
        local legend = string.format("<%s> Choose   <%s> Close   <%s> Next", GetKeyText(PAD_CONFIRM), GetKeyText(PAD_BACK), GetKeyText(PAD_NEXT))
        if NumChoiceItems() > 1 then
            legend = legend .. string.format("   <%s/%s> Reward", GetKeyText(PAD_LEFT), GetKeyText(PAD_RIGHT))
        end
        legendString:SetText(legend)
        legendString:Show()
    else
        legendString:Hide()
    end

    if frame:IsShown() then
        UpdateHeight()
    end
end



local function PickChoice(index)
    state.rewardChoice = index
    padFocus = index
    for _, item in ipairs(rewardItemsPool) do
        if item.type == "choice" then
            if item.index == state.rewardChoice then
                item.highlight:Show()
            else
                item.highlight:Hide()
            end
        end
    end
    EvaluateCompleteLine()
end

local function GetRewardItem(i)
    if not rewardItemsPool[i] then
        local btn = CreateFrame("Button", nil, rewardsContainer)
        btn:SetSize(32, 32)
        if i == 1 then
            btn:SetPoint("TOPLEFT")
        else
            btn:SetPoint("LEFT", rewardItemsPool[i-1], "RIGHT", 8, 0)
        end
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        btn.icon = tex
        
        local hl = btn:CreateTexture(nil, "OVERLAY")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        hl:SetBlendMode("ADD")
        hl:Hide()
        btn.highlight = hl

        
        
        local focus = btn:CreateTexture(nil, "BACKGROUND")
        focus:SetPoint("TOPLEFT", -3, 3)
        focus:SetPoint("BOTTOMRIGHT", 3, -3)
        ThugUI.Theme:Paint(focus, "accent", "fill")
        focus:Hide()
        btn.padFocus = focus

        btn:SetScript("OnEnter", ShowRewardTooltip)
        btn:SetScript("OnLeave", HideRewardTooltip)
        btn:SetScript("OnClick", function(self)
            if self.type == "choice" then
                PickChoice(self.index)
            end
        end)
        
        rewardItemsPool[i] = btn
    end
    return rewardItemsPool[i]
end



local function MoneyText(copper)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(copper)
    elseif GetMoneyString then
        return GetMoneyString(copper)
    elseif GetCoinTextureString then
        return GetCoinTextureString(copper)
    end
    return tostring(math.floor(copper / 10000)) .. "g"
end

local function AddRewards()
    ClearRewards()
    local count = 0
    
    if GetNumQuestChoices then
        local numChoices = GetNumQuestChoices()
        for i = 1, numChoices do
            if GetQuestItemInfo then
                local _, texture = GetQuestItemInfo("choice", i)
                if texture then
                    count = count + 1
                    local btn = GetRewardItem(count)
                    btn.icon:SetTexture(texture)
                    btn.type = "choice"
                    btn.index = i
                    btn:Show()
                end
            end
        end
    end
    
    if GetNumQuestRewards then
        local numRewards = GetNumQuestRewards()
        for i = 1, numRewards do
            if GetQuestItemInfo then
                local _, texture = GetQuestItemInfo("reward", i)
                if texture then
                    count = count + 1
                    local btn = GetRewardItem(count)
                    btn.icon:SetTexture(texture)
                    btn.type = "reward"
                    btn.index = i
                    btn:Show()
                end
            end
        end
    end
    
    
    if not rewardsContainer.moneyText then
        rewardsContainer.moneyText = rewardsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    end
    rewardsContainer.moneyText:Hide()
    
    local extras = {}
    if GetRewardMoney and GetRewardMoney() > 0 then
        table.insert(extras, MoneyText(GetRewardMoney()))
    end
    if GetRewardXP and GetRewardXP() > 0 then
        table.insert(extras, GetRewardXP() .. " XP")
    end
    if #extras > 0 then
        rewardsContainer.moneyText:SetText(table.concat(extras, "   "))
        
        
        rewardsContainer.moneyText:ClearAllPoints()
        if count > 0 then
            rewardsContainer.moneyText:SetPoint("LEFT", rewardItemsPool[count], "RIGHT", 16, 0)
        else
            rewardsContainer.moneyText:SetPoint("TOPLEFT")
        end
        rewardsContainer.moneyText:Show()
        count = math.max(1, count)
    end
    
    if count > 0 then
        rewardsContainer:SetHeight(32)
        rewardsContainer:Show()
    else
        rewardsContainer:Hide()
    end
end

local function ShowPanel(panelName, title, paragraphs, options, panelType)
    
    if not ThugUI.CombatClose:Allow("dialogue") then return end
    state.closeGen = state.closeGen + 1
    state.panel = panelName
    state.paragraphs = paragraphs
    state.paragraphIndex = 1
    state.phase = "revealing"
    state.revealCount = 0
    state.holdTimer = 0
    state.rewardChoice = 0
    
    if paragraphs[1] then
        state.textLen = Dialogue.VisibleLength(paragraphs[1])
        SetBodyText("", true)
    else
        state.phase = "holding"
        SetBodyText("", true)
    end
    
    titleString:SetText(title or "")
    
    if panelType == "detail" or panelType == "complete" then
        AddRewards()
    else
        ClearRewards()
    end
    
    ClearOptions()
    if #options > 0 then
        for i, opt in ipairs(options) do
            local btn = GetOptionLine(i)
            local prefix = (i <= 9) and (i .. ". ") or ""
            btn:SetText(prefix .. opt.text)
            btn.action = opt.action
            btn.isCompleteLine = opt.isCompleteLine
            if opt.disabled then btn:Disable() end
            btn:Show()
        end
        optionsContainer:SetHeight(#options * 24)
        optionsContainer:Show()
    else
        optionsContainer:Hide()
    end
    
    EvaluateCompleteLine()

    
    
    padFocus = 0
    selectedLine = 1
    if NumChoiceItems() > 1 then
        selectedLine = REWARD_ROW
        padFocus = 1
    else
        for i, btn in ipairs(optionsLinesPool) do
            if btn:IsShown() and btn:IsEnabled() then
                selectedLine = i
                break
            end
        end
    end
    UpdateSelection()
    
    if not frame:IsShown() then
        Dialogue:ApplyLayout()
        frame:Show()
        UpdateHeight()
    else
        UpdateHeight()
    end
    
    if not InCombatLockdown() then
        frame:EnableKeyboard(true)
        if frame.EnableGamePadButton then
            pcall(frame.EnableGamePadButton, frame, true)
        end
        frame:SetPropagateKeyboardInput(false)
    end
end



local function CloseDialogue()
    if state.panel == "preview" then
        frame:Hide()
    elseif state.panel == "gossip" and C_GossipInfo and C_GossipInfo.CloseGossip then
        C_GossipInfo.CloseGossip()
    elseif CloseQuest then
        CloseQuest()
    end
end

local function HandleClose()
    state.closeGen = state.closeGen + 1
    local gen = state.closeGen
    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, function()
            if state.closeGen == gen then
                frame:Hide()
                if frame.EnableKeyboard then
                    pcall(frame.EnableKeyboard, frame, false)
                end
                if frame.EnableGamePadButton then
                    pcall(frame.EnableGamePadButton, frame, false)
                end
            end
        end)
    else
        frame:Hide()
        if frame.EnableKeyboard then
            pcall(frame.EnableKeyboard, frame, false)
        end
        if frame.EnableGamePadButton then
            pcall(frame.EnableGamePadButton, frame, false)
        end
    end
end




frame:SetScript("OnKeyDown", function(self, key)
    if InCombatLockdown() then return end
    
    if key == "ESCAPE" then
        CloseDialogue()
        self:SetPropagateKeyboardInput(false)
        return
    elseif key == "SPACE" then
        local btn = optionsLinesPool[1]
        if btn and btn:IsShown() and btn:IsEnabled() and btn.action then
            btn.action()
        end
        self:SetPropagateKeyboardInput(false)
        return
    end
    
    local num = tonumber(key)
    if not num then
        local numpad = key:match("^NUMPAD(%d)$")
        if numpad then num = tonumber(numpad) end
    end
    
    if num and num >= 1 and num <= 9 then
        local btn = optionsLinesPool[num]
        if btn and btn:IsShown() and btn:IsEnabled() and btn.action then
            btn.action()
        end
        self:SetPropagateKeyboardInput(false)
        return
    end
    
    self:SetPropagateKeyboardInput(true)
end)






frame:SetScript("OnGamePadButtonDown", function(self, button)
    if InCombatLockdown() then return end
    
    if not gamepadActive then
        gamepadActive = true
        UpdateSelection()
    end
    
    if button == PAD_UP or button == PAD_DOWN then
        local stops = PadStops()
        if #stops > 0 then
            local at = 0
            for k, s in ipairs(stops) do
                if s == selectedLine then at = k break end
            end
            local delta = button == PAD_DOWN and 1 or -1
            
            
            local k = ((at + delta - 1) % #stops) + 1
            if at == 0 and delta < 0 then k = #stops end
            selectedLine = stops[k]
            UpdateSelection()
        end
        self:SetPropagateKeyboardInput(false)
        return
    elseif button == PAD_CONFIRM then
        if selectedLine == REWARD_ROW then
            
            
            if ChoiceItem(padFocus) then
                PickChoice(padFocus)
                for i, btn in ipairs(optionsLinesPool) do
                    if btn.isCompleteLine and btn:IsShown() and btn:IsEnabled() then
                        selectedLine = i
                        break
                    end
                end
                UpdateSelection()
            end
        else
            local btn = optionsLinesPool[selectedLine]
            if btn and btn:IsShown() and btn:IsEnabled() and btn.action then
                btn.action()
            end
        end
        self:SetPropagateKeyboardInput(false)
        return
    elseif button == PAD_BACK then
        CloseDialogue()
        self:SetPropagateKeyboardInput(false)
        return
    elseif button == PAD_NEXT then
        AdvanceParagraph()
        self:SetPropagateKeyboardInput(false)
        return
    elseif button == PAD_LEFT or button == PAD_RIGHT then
        
        
        local maxChoice = NumChoiceItems()
        if maxChoice > 0 then
            if selectedLine ~= REWARD_ROW then
                selectedLine = REWARD_ROW
                if not ChoiceItem(padFocus) then
                    padFocus = (state.rewardChoice > 0) and state.rewardChoice or 1
                end
            else
                local delta = button == PAD_RIGHT and 1 or -1
                local nextChoice = padFocus + delta
                if nextChoice > maxChoice then
                    nextChoice = 1
                elseif nextChoice < 1 then
                    nextChoice = maxChoice
                end
                padFocus = nextChoice
            end
            UpdateSelection()
            self:SetPropagateKeyboardInput(false)
            return
        end
    end
    
    self:SetPropagateKeyboardInput(true)
end)

local function GetEventOptions(event)
    local options = {}
    if event == "GOSSIP_SHOW" then
        if C_GossipInfo then
            if C_GossipInfo.GetAvailableQuests then
                for _, q in ipairs(C_GossipInfo.GetAvailableQuests()) do
                    table.insert(options, {
                        text = "|cffffd100!|r " .. (q.title or ""),
                        action = function() if C_GossipInfo.SelectAvailableQuest then C_GossipInfo.SelectAvailableQuest(q.questID) end end
                    })
                end
            end
            if C_GossipInfo.GetActiveQuests then
                for _, q in ipairs(C_GossipInfo.GetActiveQuests()) do
                    local prefix = q.isComplete and "|cffffd100?|r" or "|cff808080?|r"
                    table.insert(options, {
                        text = prefix .. " " .. (q.title or ""),
                        action = function() if C_GossipInfo.SelectActiveQuest then C_GossipInfo.SelectActiveQuest(q.questID) end end
                    })
                end
            end
            
            
            if C_GossipInfo.GetOptions then
                local gossipOptions = C_GossipInfo.GetOptions() or {}
                table.sort(gossipOptions, function(l, r)
                    return (l.orderIndex or 0) < (r.orderIndex or 0)
                end)
                for _, o in ipairs(gossipOptions) do
                    table.insert(options, {
                        text = o.name or "",
                        action = function()
                            if C_GossipInfo.SelectOptionByIndex and o.orderIndex then
                                C_GossipInfo.SelectOptionByIndex(o.orderIndex)
                            elseif C_GossipInfo.SelectOption then
                                C_GossipInfo.SelectOption(o.gossipOptionID)
                            end
                        end
                    })
                end
            end
        end
        table.insert(options, {
            text = "Goodbye",
            action = function() if C_GossipInfo and C_GossipInfo.CloseGossip then C_GossipInfo.CloseGossip() end end
        })
    elseif event == "QUEST_GREETING" then
        if GetNumActiveQuests and GetActiveTitle then
            for i = 1, GetNumActiveQuests() do
                table.insert(options, {
                    text = "|cffffd100?|r " .. GetActiveTitle(i),
                    action = function() if SelectActiveQuest then SelectActiveQuest(i) end end
                })
            end
        end
        if GetNumAvailableQuests and GetAvailableTitle then
            for i = 1, GetNumAvailableQuests() do
                table.insert(options, {
                    text = "|cffffd100!|r " .. GetAvailableTitle(i),
                    action = function() if SelectAvailableQuest then SelectAvailableQuest(i) end end
                })
            end
        end
        table.insert(options, {
            text = "Goodbye",
            action = function() if CloseQuest then CloseQuest() end end
        })
    elseif event == "QUEST_DETAIL" then
        
        
        
        table.insert(options, {
            text = "Accept",
            action = function()
                if QuestGetAutoAccept and QuestGetAutoAccept() then
                    if AcknowledgeAutoAcceptQuest then AcknowledgeAutoAcceptQuest() end
                else
                    if AcceptQuest then AcceptQuest() end
                end
            end
        })
        table.insert(options, {
            text = "Decline",
            action = function() if DeclineQuest then DeclineQuest() end end
        })
    elseif event == "QUEST_PROGRESS" then
        local completeable = false
        if IsQuestCompletable then completeable = IsQuestCompletable() end
        table.insert(options, {
            text = "Continue",
            disabled = not completeable,
            action = function() if CompleteQuest then CompleteQuest() end end
        })
        table.insert(options, {
            text = "Goodbye",
            action = function() if CloseQuest then CloseQuest() end end
        })
    elseif event == "QUEST_COMPLETE" then
        
        
        
        
        local label = "Complete quest"
        local cost = GetQuestMoneyToGet and GetQuestMoneyToGet() or 0
        if cost > 0 then
            label = "Complete quest (costs " .. MoneyText(cost) .. ")"
        end
        table.insert(options, {
            text = label,
            isCompleteLine = true,
            action = function()
                local numChoices = GetNumQuestChoices and GetNumQuestChoices() or 0
                local choice = state.rewardChoice
                if numChoices == 1 then choice = 1 end
                
                
                if numChoices > 0 and choice == 0 then return end
                if GetQuestReward then GetQuestReward(choice) end
            end
        })
        table.insert(options, {
            text = "Goodbye",
            action = function() if CloseQuest then CloseQuest() end end
        })
    end
    return options
end

frame:SetScript("OnEvent", function(self, event, ...)
    if not ThugUI:IsModuleOn("dialogue") then self:UnregisterAllEvents() self:SetScript("OnUpdate", nil) return end
    local cfg = ThugUIDB.Dialogue
    if not cfg.enabled then return end
    
    if event == "PLAYER_REGEN_DISABLED" then
        pcall(frame.EnableKeyboard, frame, false)
        if frame.EnableGamePadButton then pcall(frame.EnableGamePadButton, frame, false) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if frame:IsShown() then
            pcall(frame.EnableKeyboard, frame, true)
            if frame.EnableGamePadButton then pcall(frame.EnableGamePadButton, frame, true) end
            pcall(frame.SetPropagateKeyboardInput, frame, false)
        end
    elseif event == "GOSSIP_CLOSED" or event == "QUEST_FINISHED" then
        HandleClose()
    elseif event == "GOSSIP_SHOW" then
        local title = UnitName("npc") or "NPC"
        local text = ""
        if C_GossipInfo and C_GossipInfo.GetText then text = C_GossipInfo.GetText() end
        local paragraphs = Dialogue.SplitParagraphs(text)
        local options = GetEventOptions(event)
        ShowPanel("gossip", title, paragraphs, options, "gossip")
    elseif event == "QUEST_GREETING" then
        local title = UnitName("npc") or "NPC"
        local text = ""
        if GetGreetingText then text = GetGreetingText() end
        local paragraphs = Dialogue.SplitParagraphs(text)
        local options = GetEventOptions(event)
        ShowPanel("greeting", title, paragraphs, options, "greeting")
    elseif event == "QUEST_DETAIL" then
        local title = ""
        if GetTitleText then title = GetTitleText() end
        local text = ""
        if GetQuestText then text = GetQuestText() end
        local paragraphs = Dialogue.SplitParagraphs(text)
        if GetObjectiveText and GetObjectiveText() ~= "" then
            table.insert(paragraphs, "Objectives: " .. GetObjectiveText())
        end
        local options = GetEventOptions(event)
        ShowPanel("detail", title, paragraphs, options, "detail")
    elseif event == "QUEST_PROGRESS" then
        local title = ""
        if GetTitleText then title = GetTitleText() end
        local text = ""
        if GetProgressText then text = GetProgressText() end
        local paragraphs = Dialogue.SplitParagraphs(text)
        local options = GetEventOptions(event)
        ShowPanel("progress", title, paragraphs, options, "progress")
    elseif event == "QUEST_COMPLETE" then
        local title = ""
        if GetTitleText then title = GetTitleText() end
        local text = ""
        if GetRewardText then text = GetRewardText() end
        local paragraphs = Dialogue.SplitParagraphs(text)
        local options = GetEventOptions(event)
        ShowPanel("complete", title, paragraphs, options, "complete")
    end
end)

function Dialogue:Initialize()
    if ThugUI.CombatClose then
        ThugUI.CombatClose:Register("dialogue", function() return frame and frame:IsShown() end, function() CloseDialogue() end)
    end
    local cfg = ThugUIDB.Dialogue
    if cfg.enabled then
        
        
        
        
        
        if CustomGossipFrameManager and CustomGossipFrameManager.UnregisterEvent then
            CustomGossipFrameManager:UnregisterEvent("GOSSIP_SHOW")
            CustomGossipFrameManager:UnregisterEvent("GOSSIP_CLOSED")
            ThugUI.Diagnostics:Log("DIALOGUE", "Unregistered GOSSIP_SHOW, GOSSIP_CLOSED from CustomGossipFrameManager")
        end
        if GossipFrame and GossipFrame.UnregisterEvent then
            GossipFrame:UnregisterEvent("GOSSIP_SHOW")
            GossipFrame:UnregisterEvent("GOSSIP_CLOSED")
            ThugUI.Diagnostics:Log("DIALOGUE", "Unregistered GOSSIP_SHOW, GOSSIP_CLOSED from GossipFrame")
        end
        if QuestFrame and QuestFrame.UnregisterAllEvents then
            QuestFrame:UnregisterAllEvents()
            ThugUI.Diagnostics:Log("DIALOGUE", "Unregistered all events from QuestFrame")
        end
        
        ThugUI.SafeRegisterEvent(frame, "GOSSIP_SHOW")
        ThugUI.SafeRegisterEvent(frame, "GOSSIP_CLOSED")
        ThugUI.SafeRegisterEvent(frame, "QUEST_GREETING")
        ThugUI.SafeRegisterEvent(frame, "QUEST_DETAIL")
        ThugUI.SafeRegisterEvent(frame, "QUEST_PROGRESS")
        ThugUI.SafeRegisterEvent(frame, "QUEST_COMPLETE")
        ThugUI.SafeRegisterEvent(frame, "QUEST_FINISHED")
        ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_DISABLED")
        ThugUI.SafeRegisterEvent(frame, "PLAYER_REGEN_ENABLED")
    end
end

function Dialogue:Preview()
    local title = "Preview NPC"
    local paragraphs = {
        "This is a preview of the ThugUI dialogue window.",
        "It reveals text one paragraph at a time, just like a real quest or gossip would.",
        "You can adjust the speed, text size, and background opacity in the settings."
    }
    local options = {
        {
            text = "Close preview",
            action = function() frame:Hide() end
        }
    }
    ShowPanel("preview", title, paragraphs, options, "gossip")
end
