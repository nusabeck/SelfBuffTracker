local addonName, addon = ...

local category
local spellRows = {}

StaticPopupDialogs["SELFBUFFTRACKER_DELETE_PROFILE"] = {
    text = addon.L and addon.L.PROFILE_CONFIRM_DELETE,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if not addon.DeleteProfile then return end
        local L = addon.L
        if addon.DeleteProfile(data) then
            print("|cff00ff00[SBT]|r " .. string.format(L.PROFILE_DELETED, data))
        else
            print("|cff00ff00[SBT]|r " .. L.PROFILE_CANNOT_DELETE_LAST)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["SELFBUFFTRACKER_IMPORT_PROFILE"] = {
    text = addon.L and addon.L.PROFILE_CONFIRM_IMPORT,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if not addon.CopyProfileDataInto then return end
        local L = addon.L
        if addon.CopyProfileDataInto(data) then
            print("|cff00ff00[SBT]|r " .. string.format(L.PROFILE_IMPORTED, data))
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function CreateTrackedBuffsSubcategory(parentCategory)
    local L = addon.L

    local panel = CreateFrame("Frame", "SelfBuffTrackerBuffsPanel", UIParent)
    panel.name = L.TRACKED_BUFFS

    local profilesLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    profilesLabel:SetPoint("TOPLEFT", 16, -16)
    profilesLabel:SetText(L.PROFILES_TITLE)
    addon.ApplyFont(profilesLabel, "normalLarge")

    local activeProfileLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    activeProfileLabel:SetPoint("TOPLEFT", profilesLabel, "BOTTOMLEFT", 0, -8)
    addon.ApplyFont(activeProfileLabel, "normal")

    local profileNameEditBox = CreateFrame("EditBox", "SelfBuffTrackerOptionsProfileEditBox", panel, "InputBoxTemplate")
    profileNameEditBox:SetAutoFocus(false)
    profileNameEditBox:SetSize(160, 20)
    profileNameEditBox:SetPoint("TOPLEFT", activeProfileLabel, "BOTTOMLEFT", 8, -12)

    local createProfileButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    createProfileButton:SetSize(140, 22)
    createProfileButton:SetText(L.PROFILE_CREATE_BUTTON)
    createProfileButton:SetPoint("LEFT", profileNameEditBox, "RIGHT", 8, 0)
    addon.ApplyFont(createProfileButton, "highlight")

    local profileSelectDropdown = CreateFrame("Frame", "SelfBuffTrackerOptionsProfileDropdown", panel, "UIDropDownMenuTemplate")
    profileSelectDropdown:SetPoint("TOPLEFT", profileNameEditBox, "BOTTOMLEFT", -16, -8)
    UIDropDownMenu_SetWidth(profileSelectDropdown, 160)

    local switchProfileButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    switchProfileButton:SetSize(90, 22)
    switchProfileButton:SetText(L.PROFILE_SWITCH_BUTTON)
    switchProfileButton:SetPoint("LEFT", profileSelectDropdown, "RIGHT", 8, 2)
    addon.ApplyFont(switchProfileButton, "highlight")

    local importProfileButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importProfileButton:SetSize(110, 22)
    importProfileButton:SetText(L.PROFILE_IMPORT_BUTTON)
    importProfileButton:SetPoint("LEFT", switchProfileButton, "RIGHT", 8, 0)
    addon.ApplyFont(importProfileButton, "highlight")

    local deleteProfileButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deleteProfileButton:SetSize(90, 22)
    deleteProfileButton:SetText(L.PROFILE_DELETE_BUTTON)
    deleteProfileButton:SetPoint("LEFT", importProfileButton, "RIGHT", 8, 0)
    addon.ApplyFont(deleteProfileButton, "highlight")

    local selectedProfileName

    local function RefreshProfileDropdown()
        activeProfileLabel:SetText(string.format(L.PROFILE_ACTIVE_LABEL,
            (addon.GetActiveProfileName and addon.GetActiveProfileName()) or "Default"))

        selectedProfileName = nil
        UIDropDownMenu_SetText(profileSelectDropdown, L.PROFILE_NONE)

        UIDropDownMenu_Initialize(profileSelectDropdown, function(dropdown, level)
            for _, name in ipairs(addon.GetProfileNames and addon.GetProfileNames() or {}) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.func = function()
                    selectedProfileName = name
                    UIDropDownMenu_SetText(profileSelectDropdown, name)
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end

    createProfileButton:SetScript("OnClick", function()
        local text = strtrim(profileNameEditBox:GetText() or "")
        if text == "" then return end
        if addon.CreateProfile and addon.CreateProfile(text) then
            profileNameEditBox:SetText("")
            print("|cff00ff00[SBT]|r " .. string.format(L.PROFILE_CREATED, text))
        else
            print("|cff00ff00[SBT]|r " .. string.format(L.PROFILE_NAME_TAKEN, text))
        end
    end)
    profileNameEditBox:SetScript("OnEnterPressed", function(self)
        createProfileButton:Click()
        self:ClearFocus()
    end)

    switchProfileButton:SetScript("OnClick", function()
        if selectedProfileName and addon.SwitchProfile then
            addon.SwitchProfile(selectedProfileName)
            print("|cff00ff00[SBT]|r " .. string.format(L.PROFILE_SWITCHED, selectedProfileName))
        end
    end)

    importProfileButton:SetScript("OnClick", function()
        if selectedProfileName then
            StaticPopup_Show("SELFBUFFTRACKER_IMPORT_PROFILE",
                (addon.GetActiveProfileName and addon.GetActiveProfileName()) or "Default",
                selectedProfileName, selectedProfileName)
        end
    end)

    deleteProfileButton:SetScript("OnClick", function()
        if selectedProfileName then
            StaticPopup_Show("SELFBUFFTRACKER_DELETE_PROFILE", selectedProfileName, nil, selectedProfileName)
        end
    end)

    local groupsLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    groupsLabel:SetPoint("TOPLEFT", profileSelectDropdown, "BOTTOMLEFT", 16, -20)
    groupsLabel:SetText(L.BUFF_GROUPS)
    addon.ApplyFont(groupsLabel, "normalLarge")

    local groupNameEditBox = CreateFrame("EditBox", "SelfBuffTrackerOptionsGroupEditBox", panel, "InputBoxTemplate")
    groupNameEditBox:SetAutoFocus(false)
    groupNameEditBox:SetSize(160, 20)
    groupNameEditBox:SetPoint("TOPLEFT", groupsLabel, "BOTTOMLEFT", 8, -12)

    local createGroupButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    createGroupButton:SetSize(120, 22)
    createGroupButton:SetText(L.GROUP_CREATE_BUTTON)
    createGroupButton:SetPoint("LEFT", groupNameEditBox, "RIGHT", 8, 0)
    addon.ApplyFont(createGroupButton, "highlight")

    local groupSelectDropdown = CreateFrame("Frame", "SelfBuffTrackerOptionsGroupDropdown", panel, "UIDropDownMenuTemplate")
    groupSelectDropdown:SetPoint("TOPLEFT", groupNameEditBox, "BOTTOMLEFT", -16, -8)
    UIDropDownMenu_SetWidth(groupSelectDropdown, 160)

    local deleteGroupButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deleteGroupButton:SetSize(120, 22)
    deleteGroupButton:SetText(L.GROUP_DELETE_TOOLTIP)
    deleteGroupButton:SetPoint("LEFT", groupSelectDropdown, "RIGHT", 8, 2)
    addon.ApplyFont(deleteGroupButton, "highlight")

    local groupIconLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    groupIconLabel:SetPoint("TOPLEFT", groupSelectDropdown, "BOTTOMLEFT", 16, -24)
    groupIconLabel:SetText(L.GROUP_ICON_LABEL)
    addon.ApplyFont(groupIconLabel, "normal")

    local groupIconDropdown = CreateFrame("Frame", "SelfBuffTrackerOptionsGroupIconDropdown", panel, "UIDropDownMenuTemplate")
    groupIconDropdown:SetPoint("LEFT", groupIconLabel, "RIGHT", 8, -2)
    UIDropDownMenu_SetWidth(groupIconDropdown, 160)

    local selectedGroupName

    local function RefreshGroupIconDropdown()
        local group = selectedGroupName and SelfBuffTrackerDB.buffGroups[selectedGroupName]

        UIDropDownMenu_Initialize(groupIconDropdown, function(dropdown, level)
            if not group then return end
            for _, member in ipairs(group.members) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = (addon.GetSpellDisplayName and addon.GetSpellDisplayName(member)) or member
                info.func = function()
                    group.iconSpell = member
                    UIDropDownMenu_SetText(groupIconDropdown, info.text)
                    CloseDropDownMenus()
                    addon.CheckBuffs()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        if group then
            local current = group.iconSpell or group.members[1]
            local currentText = current and ((addon.GetSpellDisplayName and addon.GetSpellDisplayName(current)) or current) or L.GROUP_NONE
            UIDropDownMenu_SetText(groupIconDropdown, currentText)
            UIDropDownMenu_EnableDropDown(groupIconDropdown)
        else
            UIDropDownMenu_SetText(groupIconDropdown, L.GROUP_NONE)
            UIDropDownMenu_DisableDropDown(groupIconDropdown)
        end
    end

    local function RefreshGroupDropdown()
        selectedGroupName = nil
        UIDropDownMenu_SetText(groupSelectDropdown, L.GROUP_NONE)
        RefreshGroupIconDropdown()

        UIDropDownMenu_Initialize(groupSelectDropdown, function(dropdown, level)
            for groupName in pairs(SelfBuffTrackerDB.buffGroups) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = groupName
                info.func = function()
                    selectedGroupName = groupName
                    UIDropDownMenu_SetText(groupSelectDropdown, groupName)
                    CloseDropDownMenus()
                    RefreshGroupIconDropdown()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end

    local spellsLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    spellsLabel:SetPoint("TOPLEFT", groupIconDropdown, "BOTTOMLEFT", 16, -20)
    spellsLabel:SetText(L.TRACKED_BUFFS)
    addon.ApplyFont(spellsLabel, "normalLarge")

    local spellEditBox = CreateFrame("EditBox", "SelfBuffTrackerOptionsSpellEditBox", panel, "InputBoxTemplate")
    spellEditBox:SetAutoFocus(false)
    spellEditBox:SetSize(200, 20)
    spellEditBox:SetPoint("TOPLEFT", spellsLabel, "BOTTOMLEFT", 8, -12)

    local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addButton:SetSize(80, 22)
    addButton:SetText(L.ADD_BUTTON)
    addButton:SetPoint("LEFT", spellEditBox, "RIGHT", 8, 0)
    addon.ApplyFont(addButton, "highlight")

    local spellbookButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    spellbookButton:SetSize(150, 22)
    spellbookButton:SetText(L.SPELLBOOK_BUTTON)
    spellbookButton:SetPoint("LEFT", addButton, "RIGHT", 8, 0)
    addon.ApplyFont(spellbookButton, "highlight")
    spellbookButton:SetScript("OnClick", function()
        if addon.ToggleSpellPicker then
            addon.ToggleSpellPicker()
        end
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "SelfBuffTrackerOptionsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", spellEditBox, "BOTTOMLEFT", -4, -12)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 16)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local ROW_HEIGHT = 64

    local CONDITION_OPTIONS = {
        { value = nil, label = L.CONDITION_ALWAYS },
        { value = "combat", label = L.CONDITION_COMBAT },
        { value = "nocombat", label = L.CONDITION_NOCOMBAT },
        { value = "resting", label = L.CONDITION_RESTING },
        { value = "noresting", label = L.CONDITION_NORESTING },
    }

    local function GetSpellIcon(spellName)
        local info = C_Spell.GetSpellInfo(spellName)
        if info and info.iconID then
            return info.iconID
        end
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    local function RefreshSpellList()
        for _, row in ipairs(spellRows) do row:Hide() end

        local spells = {}
        for spell, enabled in pairs(SelfBuffTrackerDB.trackedSpells) do
            if enabled then table.insert(spells, spell) end
        end
        table.sort(spells)

        scrollChild:SetSize(scrollFrame:GetWidth(), math.max(#spells * ROW_HEIGHT, 1))

        for i, spell in ipairs(spells) do
            local row = spellRows[i]
            if not row then
                row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                row:SetHeight(ROW_HEIGHT)
                row:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                })
                row:SetBackdropColor(1, 1, 1, 0.05)
                row:SetBackdropBorderColor(1, 1, 1, 0.08)
                row:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 1, 1, 0.12) end)
                row:SetScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0.05) end)

                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(22, 22)
                row.icon:SetPoint("TOPLEFT", 6, -6)
                row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                row.removeButton = CreateFrame("Button", nil, row)
                row.removeButton:SetSize(18, 18)
                row.removeButton:SetPoint("TOPRIGHT", -8, -6)
                row.removeButton:SetNormalAtlas("common-icon-redx")
                row.removeButton:SetPushedAtlas("common-icon-redx")
                row.removeButton:SetHighlightAtlas("common-icon-redx", "ADD")

                row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)
                row.text:SetPoint("RIGHT", row.removeButton, "LEFT", -8, 0)
                row.text:SetJustifyH("LEFT")
                addon.ApplyFont(row.text, "highlight")

                row.groupDropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
                row.groupDropdown:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", -16, -6)
                UIDropDownMenu_SetWidth(row.groupDropdown, 140)

                row.conditionDropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
                row.conditionDropdown:SetPoint("LEFT", row.groupDropdown, "RIGHT", -20, 0)
                UIDropDownMenu_SetWidth(row.conditionDropdown, 130)

                spellRows[i] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
            row:SetWidth(scrollFrame:GetWidth())
            row.icon:SetTexture(GetSpellIcon(spell))
            row.text:SetText(spell)
            row.removeButton:SetScript("OnClick", function()
                SelfBuffTrackerDB.trackedSpells[spell] = nil
                if SelfBuffTrackerDB.spellConditions then SelfBuffTrackerDB.spellConditions[spell] = nil end
                if addon.RemoveSpellFromAllGroups then addon.RemoveSpellFromAllGroups(spell) end
                addon.CheckBuffs()
                RefreshSpellList()
                RefreshGroupIconDropdown()
            end)

            UIDropDownMenu_Initialize(row.groupDropdown, function(dropdown, level)
                local noneInfo = UIDropDownMenu_CreateInfo()
                noneInfo.text = L.GROUP_NONE
                noneInfo.func = function()
                    if addon.RemoveSpellFromAllGroups then addon.RemoveSpellFromAllGroups(spell) end
                    addon.CheckBuffs()
                    RefreshSpellList()
                    RefreshGroupIconDropdown()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(noneInfo, level)

                for groupName, group in pairs(SelfBuffTrackerDB.buffGroups) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = groupName
                    info.func = function()
                        if addon.RemoveSpellFromAllGroups then addon.RemoveSpellFromAllGroups(spell) end
                        table.insert(group.members, spell)
                        addon.CheckBuffs()
                        RefreshSpellList()
                        RefreshGroupIconDropdown()
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end)
            UIDropDownMenu_SetText(row.groupDropdown, (addon.FindGroupForSpell and addon.FindGroupForSpell(spell)) or L.GROUP_NONE)

            UIDropDownMenu_Initialize(row.conditionDropdown, function(dropdown, level)
                for _, option in ipairs(CONDITION_OPTIONS) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = option.label
                    info.func = function()
                        SelfBuffTrackerDB.spellConditions[spell] = option.value
                        UIDropDownMenu_SetText(row.conditionDropdown, option.label)
                        CloseDropDownMenus()
                        addon.CheckBuffs()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end)

            local currentCondition = SelfBuffTrackerDB.spellConditions and SelfBuffTrackerDB.spellConditions[spell]
            local currentConditionLabel = L.CONDITION_ALWAYS
            for _, option in ipairs(CONDITION_OPTIONS) do
                if option.value == currentCondition then
                    currentConditionLabel = option.label
                    break
                end
            end
            UIDropDownMenu_SetText(row.conditionDropdown, currentConditionLabel)

            row:Show()
        end
    end

    addButton:SetScript("OnClick", function()
        local text = strtrim(spellEditBox:GetText() or "")
        if text ~= "" then
            SelfBuffTrackerDB.trackedSpells[text] = true
            spellEditBox:SetText("")
            addon.CheckBuffs()
            RefreshSpellList()
        end
    end)
    spellEditBox:SetScript("OnEnterPressed", function(self)
        addButton:Click()
        self:ClearFocus()
    end)

    createGroupButton:SetScript("OnClick", function()
        local text = strtrim(groupNameEditBox:GetText() or "")
        if text ~= "" and not SelfBuffTrackerDB.buffGroups[text] then
            SelfBuffTrackerDB.buffGroups[text] = { members = {} }
            groupNameEditBox:SetText("")
            addon.CheckBuffs()
            RefreshGroupDropdown()
            RefreshSpellList()
        end
    end)
    groupNameEditBox:SetScript("OnEnterPressed", function(self)
        createGroupButton:Click()
        self:ClearFocus()
    end)

    deleteGroupButton:SetScript("OnClick", function()
        if selectedGroupName then
            SelfBuffTrackerDB.buffGroups[selectedGroupName] = nil
            addon.CheckBuffs()
            RefreshGroupDropdown()
            RefreshSpellList()
        end
    end)

    local function RefreshValues()
        RefreshProfileDropdown()
        RefreshGroupDropdown()
        RefreshSpellList()
    end

    panel:SetScript("OnShow", RefreshValues)
    addon.RefreshOptionsPanel = RefreshValues

    Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name)
    RefreshValues()
end

local function AddCheckbox(cat, variableKey, name, defaultValue, getValue, setValue)
    local setting = Settings.RegisterProxySetting(cat, variableKey, Settings.VarType.Boolean, name, defaultValue, getValue, setValue)
    Settings.CreateCheckbox(cat, setting)
    return setting
end

local function AddSlider(cat, variableKey, name, minValue, maxValue, step, defaultValue, getValue, setValue)
    local setting = Settings.RegisterProxySetting(cat, variableKey, Settings.VarType.Number, name, defaultValue, getValue, setValue)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return tostring(math.floor(value + 0.5))
    end)
    Settings.CreateSlider(cat, setting, options)
    return setting
end

local function AddDropdown(cat, variableKey, name, defaultValue, getValue, setValue, getOptionsList)
    local setting = Settings.RegisterProxySetting(cat, variableKey, Settings.VarType.String, name, defaultValue, getValue, setValue)
    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        for _, entry in ipairs(getOptionsList()) do
            container:Add(entry.value, entry.text)
        end
        return container:GetData()
    end
    Settings.CreateDropdown(cat, setting, GetOptions)
    return setting
end

local function BuildNativeSettingsPanel()
    local L = addon.L

    category = Settings.RegisterVerticalLayoutCategory(L.OPTIONS_TITLE)

    AddDropdown(category, "SBT_Language", L.LANGUAGE_LABEL, "auto",
        function() return SelfBuffTrackerDB.locale or "auto" end,
        function(value)
            SelfBuffTrackerDB.locale = value
            addon.RefreshLocale()
            print("|cff00ff00[SBT]|r " .. addon.L.RELOAD_HINT)
        end,
        function()
            local list = {}
            for _, entry in ipairs(addon.AvailableLocales) do
                table.insert(list, { value = entry.code, text = entry.name })
            end
            return list
        end)

    AddCheckbox(category, "SBT_SoundEnabled", L.SOUND_ENABLED, true,
        function() return SelfBuffTrackerDB.soundEnabled end,
        function(value) SelfBuffTrackerDB.soundEnabled = value end)

    AddCheckbox(category, "SBT_Locked", L.LOCKED_POSITION, false,
        function() return SelfBuffTrackerDB.isLocked end,
        function(value)
            SelfBuffTrackerDB.isLocked = value
            addon.CheckBuffs()
        end)

    AddSlider(category, "SBT_IconSize", L.ICON_SIZE, 20, 100, 1, 50,
        function() return SelfBuffTrackerDB.iconSize end,
        function(value)
            SelfBuffTrackerDB.iconSize = value
            addon.CheckBuffs()
        end)

    AddSlider(category, "SBT_Spacing", L.ICON_SPACING, 0, 30, 1, 10,
        function() return SelfBuffTrackerDB.spacing end,
        function(value)
            SelfBuffTrackerDB.spacing = value
            addon.CheckBuffs()
        end)

    AddSlider(category, "SBT_ReminderInterval", L.REMINDER_INTERVAL, 3, 180, 1, 10,
        function() return SelfBuffTrackerDB.soundReminderInterval end,
        function(value) SelfBuffTrackerDB.soundReminderInterval = value end)

    AddDropdown(category, "SBT_SoundKit", L.SOUND_LABEL, "RAID_WARNING",
        function() return SelfBuffTrackerDB.soundKit end,
        function(value)
            SelfBuffTrackerDB.soundKit = value
            local kitID = SOUNDKIT[value]
            if kitID then PlaySound(kitID, "Master") end
        end,
        function()
            local list = {}
            for _, preset in ipairs(addon.SoundPresets) do
                table.insert(list, { value = preset.kit, text = preset.label })
            end
            return list
        end)

    Settings.RegisterAddOnCategory(category)

    CreateTrackedBuffsSubcategory(category)

    addon.OpenOptionsPanel = function()
        Settings.OpenToCategory(category:GetID())
    end
end

function addon.InitOptionsPanel()
    if category then return end

    local ok, err = pcall(BuildNativeSettingsPanel)
    if not ok then
        category = nil
        print("|cffff0000[SBT]|r Initialization error: " .. tostring(err))
    end
end

