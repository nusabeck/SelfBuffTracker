local addonName, addon = ...
local L = addon.L

local function CleanSpellName(input)
    if not input then return "" end
    local nameFromLink = input:match("%[(.-)%]")
    if nameFromLink then
        return nameFromLink
    end
    return input
end

SLASH_SELFBUFFTRACKER1 = "/sbt"
SLASH_SELFBUFFTRACKER2 = "/buff"
SlashCmdList["SELFBUFFTRACKER"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = args[1] and args[1]:lower() or ""

    if cmd == "add" and args[2] then
        table.remove(args, 1)
        local rawSpell = table.concat(args, " ")
        local spell = CleanSpellName(rawSpell)

        SelfBuffTrackerDB.trackedSpells[spell] = true
        print("|cff00ff00[SBT]|r " .. string.format(L.CMD_ADDED, spell))
        addon.CheckBuffs()
        if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end

    elseif cmd == "remove" and args[2] then
        table.remove(args, 1)
        local rawSpell = table.concat(args, " ")
        local spell = CleanSpellName(rawSpell)

        SelfBuffTrackerDB.trackedSpells[spell] = nil
        if addon.RemoveSpellFromAllGroups then addon.RemoveSpellFromAllGroups(spell) end
        print("|cff00ff00[SBT]|r " .. string.format(L.CMD_REMOVED, spell))
        addon.CheckBuffs()
        if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end

    elseif cmd == "list" then
        print("|cff00ff00[SBT] " .. L.CMD_TRACKED_HEADER .. "|r")
        local groupedSpells = {}
        print("|cffffaa00" .. L.CMD_GROUP_LIST_HEADER .. "|r")
        for groupName, group in pairs(SelfBuffTrackerDB.buffGroups) do
            print(" - " .. groupName .. ":")
            for _, member in ipairs(group.members) do
                if SelfBuffTrackerDB.trackedSpells[member] then
                    groupedSpells[member] = true
                    print("     - " .. member)
                end
            end
        end
        print("|cff00ff00" .. L.CMD_UNGROUPED_HEADER .. "|r")
        for spell, enabled in pairs(SelfBuffTrackerDB.trackedSpells) do
            if enabled and not groupedSpells[spell] then print(" - " .. spell) end
        end

    elseif cmd == "group" then
        local subCmd = args[2] and args[2]:lower() or ""
        table.remove(args, 1)
        table.remove(args, 1)

        if subCmd == "create" and args[1] then
            local groupName = table.concat(args, " ")
            if SelfBuffTrackerDB.buffGroups[groupName] then
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_EXISTS, groupName))
            else
                SelfBuffTrackerDB.buffGroups[groupName] = { members = {} }
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_CREATED, groupName))
                addon.CheckBuffs()
                if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
            end

        elseif subCmd == "delete" and args[1] then
            local groupName = table.concat(args, " ")
            if not SelfBuffTrackerDB.buffGroups[groupName] then
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_NOT_FOUND, groupName))
            else
                SelfBuffTrackerDB.buffGroups[groupName] = nil
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_DELETED, groupName))
                addon.CheckBuffs()
                if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
            end

        elseif subCmd == "add" and args[1] and args[2] then
            local groupName = table.remove(args, 1)
            local spell = CleanSpellName(table.concat(args, " "))
            local group = SelfBuffTrackerDB.buffGroups[groupName]
            if not group then
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_NOT_FOUND, groupName))
            else
                SelfBuffTrackerDB.trackedSpells[spell] = true
                if addon.RemoveSpellFromAllGroups then addon.RemoveSpellFromAllGroups(spell) end
                table.insert(group.members, spell)
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_ADDED, spell, groupName))
                addon.CheckBuffs()
                if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
            end

        elseif subCmd == "remove" and args[1] and args[2] then
            local groupName = table.remove(args, 1)
            local spell = CleanSpellName(table.concat(args, " "))
            local group = SelfBuffTrackerDB.buffGroups[groupName]
            if not group then
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_NOT_FOUND, groupName))
            else
                for i = #group.members, 1, -1 do
                    if group.members[i] == spell then
                        table.remove(group.members, i)
                    end
                end
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_GROUP_REMOVED, spell, groupName))
                addon.CheckBuffs()
                if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
            end

        elseif subCmd == "list" then
            print("|cff00ff00" .. L.CMD_GROUP_LIST_HEADER .. "|r")
            for groupName, group in pairs(SelfBuffTrackerDB.buffGroups) do
                print(" - " .. groupName .. ":")
                for _, member in ipairs(group.members) do
                    print("     - " .. member)
                end
            end

        else
            print("|cff00ff00[SBT]|r " .. L.CMD_GROUP_USAGE)
        end

    elseif cmd == "lock" or cmd == "unlock" then
        addon.LockContainer()
        print("|cff00ff00[SBT]|r " .. string.format(L.CMD_POSITION, SelfBuffTrackerDB.isLocked))
        addon.CheckBuffs()
        if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
    elseif cmd == "unlock" then
        addon.ULockContainer()
        print("|cff00ff00[SBT]|r " .. string.format(L.CMD_POSITION, SelfBuffTrackerDB.isLocked))
        addon.CheckBuffs()
        if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
    elseif cmd == "sound" then
        SelfBuffTrackerDB.soundEnabled = not SelfBuffTrackerDB.soundEnabled
        local status = SelfBuffTrackerDB.soundEnabled and L.CMD_SOUND_ON or L.CMD_SOUND_OFF
        print("|cff00ff00[SBT]|r " .. string.format(L.CMD_SOUND_STATUS, status))
        if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end

    elseif cmd == "size" and tonumber(args[2]) then
        if args[2] == nil or args[2] <= 1 or args[2] > 301 then
            print('|cff00ff00[SBT]|r ' .. L.CMD_SIZE_INVALID)
        else
            SelfBuffTrackerDB.iconSize = tonumber(args[2])
            print("|cff00ff00[SBT]|r " .. string.format(L.CMD_SIZE_SET, args[2]))
            addon.CheckBuffs()
            if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
        end

    elseif cmd == "options" or cmd == "config" then
        if addon.OpenOptionsPanel then
            addon.OpenOptionsPanel()
        end

    elseif cmd == "warning" and args[2] and args[2]:lower() == "list" then
        print("|cff00ff00[SBT] " .. L.CMD_SOUND_LIST_HEADER .. "|r")
        for _, preset in ipairs(addon.SoundPresets) do
            print(" - " .. preset.key .. " (" .. preset.label .. ")")
        end
        print("|cffffaa00" .. L.CMD_SOUND_CUSTOM_HINT .. "|r")

    elseif cmd == "warning" and args[2] and tonumber(args[2]) == nil then
        local presetKey = args[2]:lower()
        local found
        for _, preset in ipairs(addon.SoundPresets) do
            if preset.key == presetKey then
                found = preset
                break
            end
        end

        if not found or not SOUNDKIT[found.kit] then
            print("|cff00ff00[SBT]|r " .. string.format(L.CMD_SOUND_UNKNOWN, args[2]))
        else
            SelfBuffTrackerDB.soundKit = found.kit
            PlaySound(SOUNDKIT[found.kit], "Master")
            print("|cff00ff00[SBT]|r " .. string.format(L.CMD_SOUND_SET, found.label))
            if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
        end

    elseif cmd == "warning" then
        local soundID = tonumber(args[2])
        if not soundID then
            print("|cff00ff00[SBT]|r " .. L.CMD_SOUND_INVALID)
        else
            local willPlay = PlaySoundFile(soundID, "Master")
            if not willPlay then
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_SOUND_NOT_FOUND, soundID))
            else
                SelfBuffTrackerDB.soundFile = soundID
                SelfBuffTrackerDB.soundKit = nil
                print("|cff00ff00[SBT]|r " .. string.format(L.CMD_SOUND_ID_SET, soundID))
                if addon.RefreshOptionsPanel then addon.RefreshOptionsPanel() end
            end
        end
    elseif cmd == "cols" and tonumber(args[2]) then
        SelfBuffTrackerDB.columns = tonumber(args[2])
        print("|cff00ff00[SBT]|r Počet sloupců nastaven na: " .. args[2])
        addon.CheckBuffs()

    elseif cmd == "debugspell" and tonumber(args[2]) then
        local spellID = tonumber(args[2])
        print("|cff00ff00[SBT DEBUG]|r spellID " .. spellID)
        if addon.DebugSpellPicker then
            for _, line in ipairs(addon.DebugSpellPicker(spellID)) do
                print("  " .. line)
            end
        end
    else
        print("|cff00ff00" .. L.HELP_HEADER .. "|r")
        print("|cffffaa00" .. L.HELP_ADD .. "|r")
        print("|cffffaa00" .. L.HELP_REMOVE .. "|r")
        print("|cffffaa00" .. L.HELP_LIST .. "|r")
        print("|cffffaa00" .. L.HELP_LOCK .. "|r")
        print("|cffffaa00" .. L.HELP_SOUND .. "|r")
        print("|cffffaa00" .. L.HELP_SIZE .. "|r")
        print("|cffffaa00" .. L.HELP_WARNING .. "|r")
        print("https://www.wowhead.com/sounds")
        print("|cffffaa00" .. L.HELP_OPTIONS .. "|r")
        print("|cffffaa00" .. L.HELP_GROUP .. "|r")
    end
end
