local addonName, addon = ...
local frame = CreateFrame("Frame", "SelfBuffTrackerFrame", UIParent)
local L = addon.L

addon.defaultConfig = {
    trackedSpells = {
    },
    buffGroups = {
    },
    spellConditions = {
    },
    iconSize = 50,
    spacing = 10,
    columns = 3,
    soundEnabled = true,
    soundFile = 567400,
    soundKit = "RAID_WARNING",
    soundReminderInterval = 10,
    locale = "auto",
    anchorPosition = { "CENTER", nil, "CENTER", 0, 150 },
    isLocked = false,
    isFlasksAllowed = false,
}
local defaultConfig = addon.defaultConfig



local iconPool = {}

local function CreateBuffIcon()
    local btn = CreateFrame("Button", nil, addon.container, "BackdropTemplate")
    btn:SetSize(SelfBuffTrackerDB.iconSize, SelfBuffTrackerDB.iconSize)
    
    local tex = btn:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(btn)
    btn.texture = tex

    btn:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    btn:SetBackdropBorderColor(1, 0, 0, 1)

    btn:SetScript("OnEnter", function(self)
        if not self.tooltipTitle then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.tooltipTitle)
        if self.tooltipLines then
            for _, line in ipairs(self.tooltipLines) do
                GameTooltip:AddLine(line, 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return btn
end

local function GetSpellTexture(spellName)
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    if spellInfo and spellInfo.iconID then
        return spellInfo.iconID
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetSpellDisplayName(spellInput)
    local spellID = tonumber(spellInput)
    if spellID then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name
        end
    end
    local info = C_Spell.GetSpellInfo(spellInput)
    if info and info.name then
        return info.name
    end
    return tostring(spellInput)
end
addon.GetSpellDisplayName = GetSpellDisplayName

local function FindGroupForSpell(spellKey)
    local groups = SelfBuffTrackerDB and SelfBuffTrackerDB.buffGroups
    if not groups then return nil end
    for groupName, group in pairs(groups) do
        for _, member in ipairs(group.members) do
            if member == spellKey then
                return groupName
            end
        end
    end
    return nil
end
addon.FindGroupForSpell = FindGroupForSpell

local function RemoveSpellFromAllGroups(spellKey)
    local groups = SelfBuffTrackerDB and SelfBuffTrackerDB.buffGroups
    if not groups then return end
    for _, group in pairs(groups) do
        for i = #group.members, 1, -1 do
            if group.members[i] == spellKey then
                table.remove(group.members, i)
            end
        end
    end
end
addon.RemoveSpellFromAllGroups = RemoveSpellFromAllGroups

local function IsConditionMet(condition)
    if not condition or condition == "always" then return true end
    if condition == "combat" then return UnitAffectingCombat("player") end
    if condition == "nocombat" then return not UnitAffectingCombat("player") end
    if condition == "resting" then return IsResting() end
    if condition == "noresting" then return not IsResting() end
    return true
end

local function IsSpellActiveNow(spellInput)
    if not SelfBuffTrackerDB.trackedSpells[spellInput] then return false end
    local condition = SelfBuffTrackerDB.spellConditions and SelfBuffTrackerDB.spellConditions[spellInput]
    return IsConditionMet(condition)
end

local function IsSpellPresent(spellInput)
    local isPresent = false
    local targetName = spellInput:lower()
    local spellID = tonumber(spellInput)

    if spellID and C_UnitAuras.GetPlayerAuraBySpellID(spellID) then
        isPresent = true
    end

    if not isPresent and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellInput)
        if info and info.spellID and C_UnitAuras.GetPlayerAuraBySpellID(info.spellID) then
            isPresent = true
        end
    end

    if not isPresent and C_UnitAuras.GetAuraDataBySpellName then
        local aura = C_UnitAuras.GetAuraDataBySpellName("player", spellInput, "HELPFUL")
            or C_UnitAuras.GetAuraDataBySpellName("player", targetName, "HELPFUL")
        if aura then
            isPresent = true
        end
    end

    return isPresent
end

function addon.DebugBuffState(spellInput)
    local lines = {}
    table.insert(lines, "tracked: " .. tostring(SelfBuffTrackerDB.trackedSpells[spellInput]))
    local condition = SelfBuffTrackerDB.spellConditions and SelfBuffTrackerDB.spellConditions[spellInput]
    table.insert(lines, "condition: " .. tostring(condition))
    table.insert(lines, "UnitAffectingCombat: " .. tostring(UnitAffectingCombat("player")))
    table.insert(lines, "IsResting: " .. tostring(IsResting()))
    table.insert(lines, "IsSpellActiveNow (passes condition): " .. tostring(IsSpellActiveNow(spellInput)))
    table.insert(lines, "IsSpellPresent (aura up right now): " .. tostring(IsSpellPresent(spellInput)))
    table.insert(lines, "group: " .. tostring(FindGroupForSpell(spellInput)))

    table.insert(lines, "--- presence check breakdown ---")
    local targetName = spellInput:lower()
    local spellID = tonumber(spellInput)
    table.insert(lines, "tonumber(input): " .. tostring(spellID))
    table.insert(lines, "GetPlayerAuraBySpellID(numeric id): "
        .. tostring(spellID and C_UnitAuras.GetPlayerAuraBySpellID(spellID) ~= nil))

    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellInput)
    table.insert(lines, "C_Spell.GetSpellInfo(name).spellID: " .. tostring(info and info.spellID))
    table.insert(lines, "GetPlayerAuraBySpellID(name-resolved id): "
        .. tostring(info and info.spellID and C_UnitAuras.GetPlayerAuraBySpellID(info.spellID) ~= nil))

    if C_UnitAuras.GetAuraDataBySpellName then
        local auraExact = C_UnitAuras.GetAuraDataBySpellName("player", spellInput, "HELPFUL")
        local auraLower = C_UnitAuras.GetAuraDataBySpellName("player", targetName, "HELPFUL")
        table.insert(lines, "GetAuraDataBySpellName(exact case): " .. tostring(auraExact ~= nil))
        table.insert(lines, "GetAuraDataBySpellName(lowercase): " .. tostring(auraLower ~= nil))
    else
        table.insert(lines, "GetAuraDataBySpellName: not available on this client")
    end

    table.insert(lines, "--- your current buffs (exact names) ---")
    local foundAny = false
    if AuraUtil and AuraUtil.ForEachAura then
        local ok, err = pcall(AuraUtil.ForEachAura, "player", "HELPFUL", nil, function(aura)
            if aura then
                foundAny = true
                table.insert(lines, "'" .. tostring(aura.name) .. "' (spellID=" .. tostring(aura.spellId) .. ")")
            end
        end, true)
        if not ok then
            table.insert(lines, "AuraUtil.ForEachAura failed: " .. tostring(err))
        end
    end
    if not foundAny and UnitAura then
        local i = 1
        while true do
            local name, _, _, _, _, _, _, _, _, auraSpellID = UnitAura("player", i, "HELPFUL")
            if not name then break end
            foundAny = true
            table.insert(lines, i .. ": '" .. name .. "' (spellID=" .. tostring(auraSpellID) .. ")")
            i = i + 1
            if i > 40 then break end
        end
    end
    if not foundAny then
        table.insert(lines, "no aura enumeration method available or returned no results")
    end

    table.insert(lines, "--- full last CheckBuffs() render (" .. (addon.lastMissingSpells and #addon.lastMissingSpells or 0) .. " icons) ---")
    if addon.lastMissingSpells then
        for i, entry in ipairs(addon.lastMissingSpells) do
            table.insert(lines, i .. ": key=" .. tostring(entry.key) .. " isGroup=" .. tostring(entry.isGroup)
                .. " representative=" .. tostring(entry.representative))
        end
    else
        table.insert(lines, "CheckBuffs has not run yet")
    end

    return lines
end

local lastSoundTime = 0
local previouslyMissing = {}

addon.LockContainer = function ()
    SelfBuffTrackerDB.isLocked = true
    addon.container:SetBackdropColor(0, 0, 0, 0)
    addon.container:SetBackdropBorderColor(0, 0, 0, 0)
    addon.containerTitle:Hide()
end

addon.UnLockContainer = function ()
    SelfBuffTrackerDB.isLocked = false
    addon.container:SetBackdropColor(0, 0, 0, 0.6)
    addon.container:SetBackdropBorderColor(1, 1, 1, 1)
    addon.containerTitle:Show()
end

local function CheckBuffs()
    if not SelfBuffTrackerDB then return end

    if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then
        addon.container:Hide()
        return
    end

    local spellPresence = {}
    for spellInput in pairs(SelfBuffTrackerDB.trackedSpells) do
        if IsSpellActiveNow(spellInput) then
            spellPresence[spellInput] = IsSpellPresent(spellInput)
        end
    end

    local spellToGroup = {}
    for groupName, group in pairs(SelfBuffTrackerDB.buffGroups or {}) do
        for _, member in ipairs(group.members) do
            spellToGroup[member] = groupName
        end
    end

    local missingSpells = {}
    local processedGroups = {}
    for spellInput in pairs(SelfBuffTrackerDB.trackedSpells) do
        if IsSpellActiveNow(spellInput) then
            local groupName = spellToGroup[spellInput]
            if groupName then
                if not processedGroups[groupName] then
                    processedGroups[groupName] = true
                    local group = SelfBuffTrackerDB.buffGroups[groupName]
                    local anyPresent = false
                    local representative = nil
                    local preferredIconValid = false
                    for _, member in ipairs(group.members) do
                        if IsSpellActiveNow(member) then
                            representative = representative or member
                            if member == group.iconSpell then
                                preferredIconValid = true
                            end
                            if spellPresence[member] then
                                anyPresent = true
                            end
                        end
                    end
                    if preferredIconValid then
                        representative = group.iconSpell
                    end
                    if not anyPresent and representative then
                        table.insert(missingSpells, {
                            key = groupName,
                            isGroup = true,
                            representative = representative,
                            members = group.members,
                        })
                    end
                end
            elseif not spellPresence[spellInput] then
                table.insert(missingSpells, { key = spellInput, isGroup = false })
            end
        end
    end

    addon.lastMissingSpells = missingSpells

    for _, icon in ipairs(iconPool) do
        icon:Hide()
    end

    local numMissing = #missingSpells
    if numMissing > 0 then
        addon.container:Show()

        if SelfBuffTrackerDB.isLocked then
            addon.container:SetBackdropColor(0, 0, 0, 0)
            addon.container:SetBackdropBorderColor(0, 0, 0, 0)
            addon.containerTitle:Hide()
        else
            addon.container:SetBackdropColor(0, 0, 0, 0.6)
            addon.container:SetBackdropBorderColor(1, 1, 1, 1)
            addon.containerTitle:Show()
        end

        local iconSize = SelfBuffTrackerDB.iconSize
        local spacing = SelfBuffTrackerDB.spacing
        local cols = SelfBuffTrackerDB.columns or 3
        if cols <= 0 then cols = numMissing end
        local numRows = math.ceil(numMissing / cols)
        local numCols = math.min(numMissing, cols)

        local totalWidth = (numCols * iconSize) + ((numCols - 1) * spacing)
        local totalHeight = (numRows * iconSize) + ((numRows - 1) * spacing)

        --local totalWidth = math.max((numMissing * iconSize) + ((numMissing - 1) * spacing), 100)
        addon.container:SetSize(math.max(totalWidth, 100), totalHeight + 10)

        for i, entry in ipairs(missingSpells) do
            if not iconPool[i] then
                iconPool[i] = CreateBuffIcon()
            end

            local icon = iconPool[i]
            icon:SetSize(iconSize, iconSize)
            icon.texture:SetTexture(GetSpellTexture(entry.isGroup and entry.representative or entry.key))
            icon:ClearAllPoints()

            if entry.isGroup then
                icon.tooltipTitle = entry.key
                local lines = {}
                for _, member in ipairs(entry.members) do
                    table.insert(lines, GetSpellDisplayName(member))
                end
                icon.tooltipLines = lines
            else
                icon.tooltipTitle = GetSpellDisplayName(entry.key)
                icon.tooltipLines = nil
            end

            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)

            local xOffset = col * (iconSize + spacing)
            local yOffset = -row * (iconSize + spacing)
            
            icon:SetPoint("TOPLEFT", addon.container, "TOPLEFT", xOffset, yOffset)
            --local xOffset = (i - 1) * (iconSize + spacing)
            --icon:SetPoint("LEFT", container, "LEFT", xOffset, 0)
            icon:Show()
        end

        if SelfBuffTrackerDB.soundEnabled then
            local now = GetTime()
            local hasNewlyMissing = false
            for _, entry in ipairs(missingSpells) do
                if not previouslyMissing[entry.key] then
                    hasNewlyMissing = true
                    break
                end
            end

            if hasNewlyMissing or (now - lastSoundTime) > SelfBuffTrackerDB.soundReminderInterval then
                addon.PlayWarningSound()
                lastSoundTime = now
            end
        end

        previouslyMissing = {}
        for _, entry in ipairs(missingSpells) do
            previouslyMissing[entry.key] = true
        end
    else
        previouslyMissing = {}
        if not SelfBuffTrackerDB.isLocked then
            addon.container:Show()
            addon.container:SetBackdropColor(0, 0, 0, 0.6)
            addon.container:SetBackdropBorderColor(1, 1, 1, 1)
            addon.containerTitle:Show()
            addon.container:SetSize(120, SelfBuffTrackerDB.iconSize + 10)
        else
            addon.container:Hide()
        end
    end
end
addon.CheckBuffs = CheckBuffs

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_UPDATE_RESTING")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")
frame:RegisterEvent("PLAYER_ENTER_COMBAT")
frame:RegisterEvent("PLAYER_CONTROL_GAINED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "ADDON_LOADED" and unit == addonName then
        if not SelfBuffTrackerDB then
            SelfBuffTrackerDB = CopyTable(defaultConfig)
        else
            for k, v in pairs(defaultConfig) do
                if SelfBuffTrackerDB[k] == nil then
                    SelfBuffTrackerDB[k] = v
                end
            end
        end

        if addon.MigrateLegacyProfiles then
            addon.MigrateLegacyProfiles()
        end
        if addon.LoadActiveProfileIntoLive then
            addon.LoadActiveProfileIntoLive()
        end

        addon.container:ClearAllPoints()
        if SelfBuffTrackerDB.anchorPosition and #SelfBuffTrackerDB.anchorPosition == 5 then
            addon.container:SetPoint(unpack(SelfBuffTrackerDB.anchorPosition))
        else
            addon.container:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        end
        self:UnregisterEvent("ADDON_LOADED")

        if addon.RefreshLocale then
            addon.RefreshLocale()
        end

        if addon.SaveActiveProfile then
            addon.SaveActiveProfile()
        end

        if addon.InitOptionsPanel then
            addon.InitOptionsPanel()
        end
    elseif event == "PLAYER_LOGOUT" then
        if addon.SaveActiveProfile then
            addon.SaveActiveProfile()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or (event == "UNIT_AURA" and unit == "player") or event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_UPDATE_RESTING"
        or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" or event == "PLAYER_ENTER_COMBAT"
        or event == "PLAYER_CONTROL_GAINED" then
        CheckBuffs()
    end
end)