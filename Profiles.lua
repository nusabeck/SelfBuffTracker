local addonName, addon = ...

local PROFILE_FIELDS = { "trackedSpells", "buffGroups", "iconSize", "spacing", "soundEnabled", "soundFile", "soundKit", "soundReminderInterval" }

local function GetCharacterKey()
    return GetRealmName() .. "-" .. UnitName("player")
end
addon.GetCharacterKey = GetCharacterKey

local function CopyProfileFields(source, dest)
    for _, field in ipairs(PROFILE_FIELDS) do
        local value = source[field]
        if value ~= nil then
            dest[field] = type(value) == "table" and CopyTable(value) or value
        end
    end
end

local function NewProfileFromDefaults()
    local profile = {}
    CopyProfileFields(addon.defaultConfig, profile)
    return profile
end

-- Converts the old per-character snapshot storage (flat keys on
-- SelfBuffTrackerAccountDB, one per "Realm-Name") into named, shareable
-- profiles. Runs once; safe to call on every ADDON_LOADED after that.
function addon.MigrateLegacyProfiles()
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    local account = SelfBuffTrackerAccountDB
    if account.migratedToProfiles then return end

    account.profiles = account.profiles or {}
    account.characterProfiles = account.characterProfiles or {}

    local myKey = GetCharacterKey()

    if not account.profiles["Default"] then
        local profile = {}
        if SelfBuffTrackerDB then
            CopyProfileFields(SelfBuffTrackerDB, profile)
        else
            CopyProfileFields(addon.defaultConfig, profile)
        end
        account.profiles["Default"] = profile
    end
    account.characterProfiles[myKey] = account.characterProfiles[myKey] or "Default"

    local legacyKeys = {}
    for key, value in pairs(account) do
        if key ~= "profiles" and key ~= "characterProfiles" and key ~= "migratedToProfiles"
            and type(value) == "table" and value.trackedSpells ~= nil then
            table.insert(legacyKeys, key)
        end
    end

    for _, key in ipairs(legacyKeys) do
        local snapshot = account[key]
        if key ~= myKey then
            local profileName = snapshot.name or key
            local suffix = 2
            while account.profiles[profileName] do
                profileName = (snapshot.name or key) .. " " .. suffix
                suffix = suffix + 1
            end
            local profile = {}
            CopyProfileFields(snapshot, profile)
            account.profiles[profileName] = profile
            account.characterProfiles[key] = profileName
        end
        account[key] = nil
    end

    account.migratedToProfiles = true
end

function addon.GetActiveProfileName()
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    SelfBuffTrackerAccountDB.characterProfiles = SelfBuffTrackerAccountDB.characterProfiles or {}
    return SelfBuffTrackerAccountDB.characterProfiles[GetCharacterKey()] or "Default"
end

function addon.GetProfileNames()
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    local names = {}
    for name in pairs(SelfBuffTrackerAccountDB.profiles or {}) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function addon.LoadActiveProfileIntoLive()
    if not SelfBuffTrackerDB then return end
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    SelfBuffTrackerAccountDB.profiles = SelfBuffTrackerAccountDB.profiles or {}

    local name = addon.GetActiveProfileName()
    local profile = SelfBuffTrackerAccountDB.profiles[name]
    if not profile then
        profile = NewProfileFromDefaults()
        SelfBuffTrackerAccountDB.profiles[name] = profile
    end

    CopyProfileFields(profile, SelfBuffTrackerDB)
end

function addon.SaveActiveProfile()
    if not SelfBuffTrackerDB then return end
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    SelfBuffTrackerAccountDB.profiles = SelfBuffTrackerAccountDB.profiles or {}

    local name = addon.GetActiveProfileName()
    local profile = SelfBuffTrackerAccountDB.profiles[name] or {}
    CopyProfileFields(SelfBuffTrackerDB, profile)
    SelfBuffTrackerAccountDB.profiles[name] = profile
end

function addon.SwitchProfile(name)
    if not name or name == "" then return false end
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    SelfBuffTrackerAccountDB.characterProfiles = SelfBuffTrackerAccountDB.characterProfiles or {}

    SelfBuffTrackerAccountDB.characterProfiles[GetCharacterKey()] = name
    addon.LoadActiveProfileIntoLive()
    addon.CheckBuffs()
    if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
    return true
end

function addon.CreateProfile(name)
    name = name and strtrim(name) or ""
    if name == "" then return false end

    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    SelfBuffTrackerAccountDB.profiles = SelfBuffTrackerAccountDB.profiles or {}
    if SelfBuffTrackerAccountDB.profiles[name] then return false end

    SelfBuffTrackerAccountDB.profiles[name] = NewProfileFromDefaults()
    addon.SwitchProfile(name)
    return true
end

function addon.DeleteProfile(name)
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    local profiles = SelfBuffTrackerAccountDB.profiles or {}
    if not name or not profiles[name] then return false end

    local count = 0
    for _ in pairs(profiles) do count = count + 1 end
    if count <= 1 then return false end

    profiles[name] = nil

    local characterProfiles = SelfBuffTrackerAccountDB.characterProfiles or {}
    local wasActive = false
    for key, profileName in pairs(characterProfiles) do
        if profileName == name then
            characterProfiles[key] = "Default"
            if key == GetCharacterKey() then wasActive = true end
        end
    end

    if not profiles["Default"] then
        profiles["Default"] = NewProfileFromDefaults()
    end

    if wasActive then
        addon.LoadActiveProfileIntoLive()
        addon.CheckBuffs()
    end
    if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
    return true
end

function addon.CopyProfileDataInto(sourceName)
    SelfBuffTrackerAccountDB = SelfBuffTrackerAccountDB or {}
    local profiles = SelfBuffTrackerAccountDB.profiles or {}
    local source = profiles[sourceName]
    if not source then return false end

    CopyProfileFields(source, SelfBuffTrackerDB)
    addon.SaveActiveProfile()
    addon.CheckBuffs()
    if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
    return true
end
