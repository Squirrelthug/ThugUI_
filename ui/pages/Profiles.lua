















ThugUI = ThugUI or {}

local Page = {
    widgets = {},
}

if ThugUI.Profiles then
    ThugUI.Profiles.Page = Page
end

local function Warn(msg)
    print("|cffff0000ThugUI:|r " .. msg)
end

local REASONS = {
    empty = "enter a name first",
    exists = "a profile with that name already exists",
    unknown = "that profile no longer exists",
    default = "Default cannot be renamed or deleted",
    active = "the active profile cannot be deleted",
    same = "that is already this profile",
}

function Page:Build(host, panel)
    local P = ThugUI.Profiles
    if not P then return end
    
    
    
    Page.panel = panel

    panel:Header("Profiles")
    panel:Note("Settings are kept in named profiles; each character is assigned "
        .. "one; new characters start on Default; switching, copying into or "
        .. "resetting the active profile takes effect after a |cffffd100/reload|r.")

    
    panel:Section("This character")

    Page.widgets.active = panel:Dropdown{
        label = "Profile:",
        width = 200,
        options = function()
            local list = P:List()
            local opts = {}
            for _, name in ipairs(list) do
                table.insert(opts, { value = name, text = name })
            end
            return opts
        end,
        get = function() return P:Assigned() end,
        set = function(v) P:Switch(v) end,
    }

    Page.widgets.pending = panel:Label("")

    
    
    panel:Button{
        label = "Reload UI now",
        width = 150,
        tooltip = "Applies a pending profile switch, copy or reset.",
        onClick = function() P:PromptReload(P:Assigned()) end,
    }

    
    panel:Section("Create")

    panel:EditBox{
        label = "Name:",
        width = 200,
        get = function() return Page.newName or "" end,
        set = function(t) Page.newName = t end,
        onTextChanged = function(t) Page.newName = t end,
    }

    panel:Button{
        label = "Copy current profile",
        width = 180,
        onClick = function()
            local newName = Page.newName
            local ok, reason = P:Create(newName, P.active)
            if ok then
                P:Switch(newName)
                Page.newName = ""
                Page:Refresh()
            else
                Warn(REASONS[reason] or tostring(reason))
            end
        end,
    }

    panel:Button{
        label = "Start from defaults",
        width = 180,
        sameLine = true,
        onClick = function()
            local newName = Page.newName
            local ok, reason = P:Create(newName, nil)
            if ok then
                P:Switch(newName)
                Page.newName = ""
                Page:Refresh()
            else
                Warn(REASONS[reason] or tostring(reason))
            end
        end,
    }

    
    panel:Section("Active profile")

    Page.widgets.scopeNote = panel:Note("")

    panel:EditBox{
        label = "Rename to:",
        width = 200,
        get = function() return Page.renameTo or "" end,
        set = function(t) Page.renameTo = t end,
        onTextChanged = function(t) Page.renameTo = t end,
    }

    panel:Button{
        label = "Rename",
        sameLine = true,
        onClick = function()
            local ok, reason = P:Rename(P.active, Page.renameTo)
            if ok then
                Page.renameTo = ""
                Page:Refresh()
            else
                Warn(REASONS[reason] or tostring(reason))
            end
        end,
    }

    panel:Dropdown{
        label = "Copy settings from:",
        width = 200,
        options = function()
            local list = P:List()
            local opts = {}
            for _, name in ipairs(list) do
                if name ~= P.active then
                    table.insert(opts, { value = name, text = name })
                end
            end
            return opts
        end,
        get = function() return Page.copyFrom end,
        set = function(v) Page.copyFrom = v end,
    }

    panel:Button{
        label = "Copy into this profile",
        sameLine = true,
        onClick = function()
            if Page.copyFrom then
                StaticPopup_Show("THUGUI_PROFILE_OVERWRITE", P.active, Page.copyFrom)
            end
        end,
    }

    panel:Button{
        label = "Reset this profile to defaults",
        width = 220,
        onClick = function()
            StaticPopup_Show("THUGUI_PROFILE_RESET", P.active)
        end,
    }

    
    panel:Section("Delete")

    panel:Dropdown{
        label = "Profile:",
        width = 200,
        options = function()
            local list = P:List()
            local opts = {}
            for _, name in ipairs(list) do
                if name ~= P.DEFAULT and name ~= P.active then
                    table.insert(opts, { value = name, text = name })
                end
            end
            return opts
        end,
        get = function() return Page.deleteTarget end,
        set = function(v) Page.deleteTarget = v end,
    }

    panel:Button{
        label = "Delete",
        sameLine = true,
        onClick = function()
            if Page.deleteTarget then
                StaticPopup_Show("THUGUI_PROFILE_DELETE", Page.deleteTarget)
            end
        end,
    }

    
    panel:Section("Characters")

    Page.widgets.chars = panel:Label("")

    Page:Refresh()
end

function Page:Refresh()
    local P = ThugUI.Profiles
    if not P then return end

    
    
    
    if Page.panel then Page.panel:Refresh() end

    local assigned = P:Assigned()
    local active = P.active
    if Page.widgets.pending then
        if active ~= assigned then
            Page.widgets.pending:SetText("Reload pending: loaded " .. tostring(active) .. ", assigned " .. tostring(assigned))
            Page.widgets.pending:Show()
        else
            Page.widgets.pending:SetText("")
            Page.widgets.pending:Hide()
        end
    end

    if Page.widgets.scopeNote then
        local scoped = P:ScopedKeysHere()
        if scoped and #scoped > 0 then
            Page.widgets.scopeNote:SetText("This character keeps its own: " .. table.concat(scoped, ", "))
        else
            Page.widgets.scopeNote:SetText("This character uses the shared settings for every page.")
        end
    end

    if Page.widgets.chars then
        local s = P:Store()
        local charKeys = {}
        for ck in pairs(s.chars or {}) do
            table.insert(charKeys, ck)
        end
        table.sort(charKeys)

        local lines = {}
        for _, ck in ipairs(charKeys) do
            table.insert(lines, ck .. "  \226\128\148  " .. tostring(s.chars[ck]))
        end
        local text = table.concat(lines, "\n")
        Page.widgets.chars:SetText(text)
        if #lines > 0 then
            Page.widgets.chars:SetHeight(14 * #lines)
        end
    end
end



StaticPopupDialogs["THUGUI_PROFILE_OVERWRITE"] = {
    text = "Overwrite every setting in |cffffd100%s|r with a copy of |cffffd100%s|r? This cannot be undone.",
    button1 = "Overwrite",
    button2 = "Cancel",
    OnAccept = function()
        local P = ThugUI.Profiles
        if P and P.active and Page.copyFrom then
            local ok, reason = P:CopyInto(P.active, Page.copyFrom)
            if not ok then Warn(REASONS[reason] or tostring(reason)) end
            Page:Refresh()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["THUGUI_PROFILE_RESET"] = {
    text = "Reset every setting in |cffffd100%s|r to defaults? This cannot be undone.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        local P = ThugUI.Profiles
        if P and P.active then
            P:Reset(P.active)
            Page:Refresh()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["THUGUI_PROFILE_DELETE"] = {
    text = "Delete the profile |cffffd100%s|r? Characters assigned to it will move to Default.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function()
        local P = ThugUI.Profiles
        if P and Page.deleteTarget then
            local ok, reason = P:Delete(Page.deleteTarget)
            if not ok then Warn(REASONS[reason] or tostring(reason)) end
            Page.deleteTarget = nil
            Page:Refresh()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

ThugUI.Window:RegisterPage{
    id = "profiles",
    category = "general",
    order = 10,
    summary = "Manage addon profiles and settings.",
    title = "Profiles",
    build = function(host, panel) Page:Build(host, panel) end,
    refresh = function() Page:Refresh() end,
}

return Page
