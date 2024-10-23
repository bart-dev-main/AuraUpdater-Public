---@diagnostic disable: undefined-field
local addOnName, LUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local AceComm = LibStub("AceComm-3.0")

local serializedTable
local spacing = 4
local lastUpdate = 0
local updateQueued = false

local auraImportElementPool = {}
local UIDToID = {} -- Installed aura UIDs to ID (ID is required for WeakAuras.GetData call)
local auraUIDs = {} -- Imported aura UIDs

local allAurasUpdatedText

local function SerializeVersionsTable()
    local versionsTable = {
        AuraUpdater = tonumber(C_AddOns.GetAddOnMetadata(addOnName, "Version")) -- AddOn version
    }

    for displayName, auraData in pairs(LiquidUpdaterSaved.WeakAuras) do
        local uid = auraData.d.uid
        local installedAuraID = uid and UIDToID[uid]
        local installedVersion = installedAuraID and WeakAuras.GetData(installedAuraID).liquidVersion or 0

        versionsTable[displayName] = installedVersion
    end

    local serialized = LibSerialize:Serialize(versionsTable)
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

    serializedTable = encoded

    if not serializedTable then
        LUP:ErrorPrint("could not serialize version table")
    end
end

local function BroadcastVersions()
    if not serializedTable then return end

    AceComm:SendCommMessage("LU_Versions", serializedTable, "GUILD")
end

local function BuildAuraImportElements()
    lastUpdate = GetTime()
    updateQueued = false

    SerializeVersionsTable()

    -- Check which auras require updates
    local aurasToUpdate = {}

    for displayName, highestSeenVersion in pairs(LUP.highestSeenVersionsTable) do
        local auraData = LiquidUpdaterSaved.WeakAuras[displayName]
        local uid = auraData and auraData.d.uid
        local importedVersion = auraData and auraData.d.liquidVersion or 0
        local installedAuraID = uid and UIDToID[uid]
        local installedVersion = installedAuraID and WeakAuras.GetData(installedAuraID).liquidVersion or 0

        if installedVersion < importedVersion then
            table.insert(
                aurasToUpdate,
                {
                    displayName = displayName,
                    installedVersion = installedVersion,
                    importedVersion = importedVersion,
                    highestSeenVersion = highestSeenVersion
                }
            )
        end
    end

    table.sort(
        aurasToUpdate,
        function(auraData1, auraData2)
            local versionsBehind1 = auraData1.highestSeenVersion - auraData1.installedVersion
            local versionsBehind2 = auraData2.highestSeenVersion - auraData2.installedVersion

            if versionsBehind1 ~= versionsBehind2 then
                return versionsBehind1 > versionsBehind2
            else
                return auraData1.displayName < auraData2.displayName
            end
        end
    )

    -- Build the aura import elements
    local parent = LUP.updateWindow

    for _, element in ipairs(auraImportElementPool) do
        element:Hide()
    end

    for i, auraData in ipairs(aurasToUpdate) do
        local auraImportFrame = auraImportElementPool[i] or LUP:CreateAuraImportElement(parent)

        auraImportFrame:SetDisplayName(auraData.displayName)
        auraImportFrame:SetVersionsBehind(auraData.highestSeenVersion - auraData.installedVersion)
        auraImportFrame:SetRequiresAddOnUpdate(auraData.highestSeenVersion > auraData.importedVersion)

        auraImportFrame:Show()
        auraImportFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing, -(i - 1) * (auraImportFrame.height + spacing) - spacing)
        auraImportFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -spacing, -(i - 1) * (auraImportFrame.height + spacing) - spacing)

        auraImportElementPool[i] = auraImportFrame
    end

    if next(aurasToUpdate) then
        LUP.LDB.icon = [[Interface\Addons\AuraUpdater\Media\Textures\minimap_logo_red.tga]]

        allAurasUpdatedText:Hide()
    else
        LUP.LDB.icon = [[Interface\Addons\AuraUpdater\Media\Textures\minimap_logo.tga]]

        allAurasUpdatedText:Show()
    end

    BroadcastVersions()
end

local function QueueUpdate()
    if updateQueued then return end

    -- Don't update more than once per second
    -- This is mostly to prevent the update function from running when a large number of auras get added simultaneously
    local timeSinceLastUpdate = GetTime() - lastUpdate

    if timeSinceLastUpdate > 1 then
        BuildAuraImportElements()
    else
        updateQueued = true

        C_Timer.After(1 - timeSinceLastUpdate, BuildAuraImportElements)
    end
end

local function RequestVersions(chatType)
    AceComm:SendCommMessage("LU_Request", " ", chatType or "GUILD")
end

local function ReceiveVersions(_, payload, _, sender)
    local shouldFullRebuild = false -- Whether all check elements should be rebuilt. Only happens if a new version is seen.
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)

    if not decoded then
        LUP:ErrorPrint(string.format("could not decode version table received from %s", sender))

        return
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)

    if not decoded then
        LUP:ErrorPrint(string.format("could not decompress version table received from %s", sender))

        return
    end

    local success, versionsTable = LibSerialize:Deserialize(decompressed)

    if not success then
        LUP:ErrorPrint(string.format("could not deserialize version table received from %s", sender))

        return
    end

    for displayName, version in pairs(versionsTable) do
        local highestSeenVersion = LUP.highestSeenVersionsTable[displayName]

        if not highestSeenVersion or highestSeenVersion < version then
            LUP.highestSeenVersionsTable[displayName] = version

            shouldFullRebuild = true
        end
    end

    if shouldFullRebuild then
        BuildAuraImportElements()

        LUP:RebuildAllCheckElements()
    else
        LUP:UpdateCheckElementForUnit(sender, versionsTable)
    end
end

function LUP:InitializeAuraUpdater()
    LUP.highestSeenVersionsTable = {
        AuraUpdater = tonumber(C_AddOns.GetAddOnMetadata(addOnName, "Version")) -- AddOn version
    }

    AceComm:RegisterComm("LU_Request", BroadcastVersions)
    AceComm:RegisterComm("LU_Versions", ReceiveVersions)

    for displayName, auraData in pairs(LiquidUpdaterSaved.WeakAuras) do
        auraUIDs[auraData.d.uid] = true

        LUP.highestSeenVersionsTable[displayName] = auraData.d.liquidVersion
    end

    if WeakAuras and WeakAurasSaved and WeakAurasSaved.displays then
        for id, auraData in pairs(WeakAurasSaved.displays) do
            UIDToID[auraData.uid] = id
        end

        hooksecurefunc(
            WeakAuras,
            "Add",
            function(data)
                local uid = data.uid

                for _, auraData in pairs(LiquidUpdaterSaved.WeakAuras) do
                    if uid == auraData.d.uid then
                        data.information.test = "test"

                        break
                    end
                end
                

                if uid and auraUIDs[uid] then
                    UIDToID[uid] = data.id
                    
                    QueueUpdate()
                end
            end
        )

        hooksecurefunc(
            WeakAuras,
            "Rename",
            function(data, newID)
                local uid = data.uid

                if uid and auraUIDs[uid] then
                    UIDToID[uid] = newID
                end
            end
        )

        hooksecurefunc(
            WeakAuras,
            "Delete",
            function(data)
                local uid = data.uid

                if UIDToID[uid] then
                    UIDToID[uid] = nil
                    
                    QueueUpdate()
                end
            end
        )
    end

    allAurasUpdatedText = LUP.updateWindow:CreateFontString(nil, "OVERLAY")

    allAurasUpdatedText:SetFont(LUP.gs.visual.font, 21, LUP.gs.visual.fontFlags)
    allAurasUpdatedText:SetPoint("CENTER", LUP.updateWindow, "CENTER")
    allAurasUpdatedText:SetText(string.format("|cff%sAll auras up to date!|r", LUP.gs.visual.colorStrings.green))

    BuildAuraImportElements()
    RequestVersions()
end

local function OnEvent(_, event)
    if event == "GROUP_ROSTER_UPDATE" then
        LUP:RemoveCheckElementsForInvalidUnits()
        LUP:AddCheckElementsForNewUnits()
    elseif event == "GROUP_JOINED" then
        local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"

        RequestVersions(chatType)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("GROUP_JOINED")
f:SetScript("OnEvent", OnEvent)