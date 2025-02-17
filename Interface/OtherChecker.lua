local _, LUP = ...

LUP.otherChecker = {}

-- Element variables
local nameFrameWidth = 150
local versionFramePaddingLeft = 10
local versionFramePaddingRight = 40
local elementHeight = 32

-- Version tables for GUIDs, used for comparison against their new table
-- Updates are only done if something changed
local cachedVersionsTables = {}

local scrollFrame, scrollBar, dataProvider, scrollView, labelFrame
local labels = {} -- Label fontstrings
local labelTitles = {
    "MRT note",
    "Ignore list",
    "RCLC"
}

LUP.highestSeenRCLCVersion = "0.0.0"
local mrtNoteHash

local dummyData = {}

local function GenerateDummyData()
    local nameToClass = {
        Max = "DRUID",
        Atlas = "DEATHKNIGHT",
        Nick = "PRIEST",
        Xesevi = "DRUID",
        Chilldrill = "SHAMAN",
        Lip = "PALADIN",
        Maevey = "SHAMAN",
        Splat = "WARLOCK",
        Thd = "WARLOCK",
        Scott = "DEMONHUNTER",
        Driney = "PALADIN",
        Riku = "WARRIOR",
        Rivenz = "PRIEST",
        Sang = "EVOKER",
        Malarkus = "HUNTER",
        Ksp = "MAGE",
        Imfiredup = "MAGE",
        Goop = "DRUID",
        Cere = "PRIEST",
        Smacked = "MONK",
        Trill = "MONK",
        Jpc = "ROGUE",
        Avade = "DEMONHUNTER",
        Yipz = "PALADIN",
        Kingfly = "PRIEST",
        Impec = "SHAMAN"
    }

    local dummyVersionsTable = {
        addOn = 9,
        auras = {
            ["LiquidWeakAuras"] = 9,
            ["Liberation of Undermine"] = 23,
            ["Liquid Anchors"] = 5
        },
        mrtNoteHash = "",
        ignores = {},
        RCLC = C_AddOns.GetAddOnMetadata("RCLootCouncil", "Version")
    }

    for name, class in pairs(nameToClass) do
        dummyData[name] = {
            class = class,
            versionsTable = CopyTable(dummyVersionsTable),
            GUID = LUP:GenerateUniqueID()
        }
    end

    dummyData["Max"].versionsTable.ignores = {
        "Driney"
    }
end

-- Compares two RCLC TOC versions
-- Returns -1 if version1 is higher, 0 if they are equal, 1 if version2 is higher
function LUP:CompareRCLCVersions(version1, version2)
    return 0
end

-- Checks a unit's new version table against their known one
-- Returns true if something changed
local function ShouldUpdate(GUID, newVersionsTable)
    local oldVersionsTable = cachedVersionsTables[GUID]

    if not oldVersionsTable then return true end
    if not newVersionsTable then return false end

    return not tCompare(oldVersionsTable, newVersionsTable, 3)
end

local function PositionLabels(_, width)
    local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
    local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
    local versionFrameSpacing = versionFramesTotalWidth / (#labels - 1)

    for i, versionFrame in ipairs(labels) do
        versionFrame:SetPoint("BOTTOM", labelFrame, "BOTTOMLEFT", firstVersionFrameX + (i - 1) * versionFrameSpacing + 0.5 * elementHeight, 0)
    end
end

local function BuildLabels()
    if not labelFrame then
        labelFrame = CreateFrame("Frame", nil, LUP.otherCheckWindow)
        labelFrame:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 4)
        labelFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "TOPRIGHT", 0, 4)
        labelFrame:SetHeight(24)

        labelFrame:SetScript("OnSizeChanged", PositionLabels)
    end

    for i, displayName in ipairs(labelTitles) do
        if not labels[i] then
            labels[i] = labelFrame:CreateFontString(nil, "OVERLAY")

            labels[i]:SetFontObject(AUFont15)
        end

        labels[i]:SetText(string.format("|cff%s%s|r", LUP.gs.visual.colorStrings.white, displayName))
    end

    PositionLabels(nil, scrollFrame:GetWidth())
end

function LUP.otherChecker:UpdateCheckElementForUnit(unit, versionsTable, force)
    local GUID = UnitGUID(unit)

    if not GUID then
        GUID = dummyData[unit] and dummyData[unit].GUID
    end

    if not (force or ShouldUpdate(GUID, versionsTable)) then return end

    -- If this is the player's version table, and the mrt note hash is different, rebuild all elements (not just the player's)
    if UnitIsUnit(unit, "player") and versionsTable and versionsTable.mrtNoteHash and (not mrtNoteHash or mrtNoteHash ~= versionsTable.mrtNoteHash) then
        mrtNoteHash = versionsTable.mrtNoteHash
        LUP.otherChecker:RebuildAllCheckElements()

        return
    end

    cachedVersionsTables[GUID] = CopyTable(versionsTable or {})

    -- If this unit already has an element, remove it
    dataProvider:RemoveByPredicate(
        function(elementData)
            return elementData.GUID == GUID
        end
    )

    -- Create new data
    local _, class, _, _, _, name = GetPlayerInfoByGUID(GUID)

    if not name then name = unit end
    if not class then class = dummyData[unit] and dummyData[unit].class end

    name = AuraUpdater:GetNickname(unit) or name -- If this unit has a nickname, use that instead

    local colorStr = RAID_CLASS_COLORS[class].colorStr
    local coloredName = string.format("|c%s%s|r", colorStr, name)

    local data = {
        GUID = GUID,
        unit = unit,
        name = name, -- Used for sorting
        coloredName = coloredName
    }

    if versionsTable then
        data.auraUpdater = true -- Whether AuraUpdater is active
        data.mrtNoteHash = versionsTable.mrtNoteHash
        data.ignores = versionsTable.ignores
        data.RCLC = versionsTable.RCLC
    end
    
    dataProvider:Insert(data)
end

function LUP.otherChecker:AddCheckElementsForNewUnits()
    for unit in LUP:IterateGroupMembers() do
        local GUID = UnitGUID(unit)

        if not LUP:GetVersionsTableForGUID(GUID) then
            LUP.otherChecker:UpdateCheckElementForUnit(unit)
        end
    end

    for unit in pairs(dummyData) do
        LUP.otherChecker:UpdateCheckElementForUnit(unit)
    end
end

-- Iterates existing elements, and removes those whose units are no longer in our group
function LUP.otherChecker:RemoveCheckElementsForInvalidUnits()

end

function LUP.otherChecker:RebuildAllCheckElements()
    for unit in LUP:IterateGroupMembers() do
        local GUID = UnitGUID(unit)
        local versionsTable = LUP:GetVersionsTableForGUID(GUID)

        LUP.otherChecker:UpdateCheckElementForUnit(unit, versionsTable, true)
    end

    for unit, data in pairs(dummyData) do
        LUP.otherChecker:UpdateCheckElementForUnit(unit, data.versionsTable, true)
    end

    BuildLabels()
end

local function CheckElementInitializer(frame, data)
    local versionFrameCount = #labelTitles

    -- Create version frames
    if not frame.versionFrames then frame.versionFrames = {} end

    for i = 1, versionFrameCount do
        local subFrame = frame.versionFrames[i] or CreateFrame("Frame", nil, frame)

        if not subFrame.versionsBehindIcon then
            subFrame.versionsBehindIcon = CreateFrame("Frame", nil, subFrame)
            subFrame.versionsBehindIcon:SetSize(24, 24)
            subFrame.versionsBehindIcon:SetPoint("CENTER", subFrame, "CENTER")

            subFrame.versionsBehindIcon.tex = subFrame.versionsBehindIcon:CreateTexture(nil, "BACKGROUND")
            subFrame.versionsBehindIcon.tex:SetAllPoints()
        end

        subFrame:SetSize(elementHeight, elementHeight)

        frame.versionFrames[i] = subFrame
    end

    if not frame.coloredName then
        frame.coloredName = frame:CreateFontString(nil, "OVERLAY")

        frame.coloredName:SetFontObject(AUFont21)
        frame.coloredName:SetPoint("LEFT", frame, "LEFT", 8, 0)
    end

    frame.coloredName:SetText(string.format("|cff%s%s|r", LUP.gs.visual.colorStrings.white, data.coloredName))

    -- MRT Note
    local versionFrame = frame.versionFrames[1]

    if data.mrtNoteHash == "" then
        versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-checkmark")

        LUP:AddTooltip(
            versionFrame,
            "MRT note is the same as yours."
        )
    elseif not data.mrtNoteHash then
        if data.auraUpdater then
            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            LUP:AddTooltip(
                versionFrame,
                "No information about MRT note received.|n|nUser is running an outdated AuraUpdater version, or has MRT disabled."
            )
        else
            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            LUP:AddTooltip(
                versionFrame,
                "No information about MRT note received.|n|nUser is not running AuraUpdater."
            )
        end
    elseif mrtNoteHash == data.mrtNoteHash then
        versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-checkmark")

        LUP:AddTooltip(
            versionFrame,
            "MRT note is the same as yours."
        )
    else
        versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-redx")

        LUP:AddTooltip(
            versionFrame,
            "MRT note is different than yours."
        )
    end

    -- Ignore list
    versionFrame = frame.versionFrames[2]

    if not data.ignores then
        if data.auraUpdater then
            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            LUP:AddTooltip(
                versionFrame,
                "No information about ignored players received.|n|nUser is running an outdated AuraUpdater version."
            )
        else
            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            LUP:AddTooltip(
                versionFrame,
                "No information about ignored players received.|n|nUser is not running AuraUpdater."
            )
        end
    elseif next(data.ignores) then
        versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-redx")

        local ignoredPlayers = ""

        for _, ignoredPlayer in ipairs(data.ignores) do
            ignoredPlayers = string.format("%s|n%s", ignoredPlayers, "|cFFF48CBADriney|r")
        end

        LUP:AddTooltip(
            versionFrame,
            string.format("Players on ignore:%s", ignoredPlayers)
        )
    else
        versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-checkmark")

        LUP:AddTooltip(
            versionFrame,
            "No group members on ignore."
        )
    end

    -- RCLC
    versionFrame = frame.versionFrames[3]

    if data.oldVersion then
        versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

        LUP:AddTooltip(
            versionFrame,
            "No information about RCLC version received.|n|nUser is running an outdated AuraUpdater version."
        )
    elseif not data.RCLC then
        if data.auraUpdater then
            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            LUP:AddTooltip(
                versionFrame,
                "No information about RCLC received.|n|nUser is running an outdated AuraUpdater version, or has RCLC disabled."
            )
        else
            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            LUP:AddTooltip(
                versionFrame,
                "No information about RCLC note received.|n|nUser is not running AuraUpdater."
            )
        end
    elseif LUP:CompareRCLCVersions(LUP.highestSeenRCLCVersion, data.RCLC) == -1 then
        versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-redx")

        LUP:AddTooltip(
            versionFrame,
            string.format("User has an outdated RCLC version.|n|nNewest version: %s|n%s's version: %s", LUP.highestSeenRCLCVersion, data.coloredName, data.RCLC)
        )
    else
        versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-checkmark")

        LUP:AddTooltip(
            versionFrame,
            "RCLC version is up to date."
        )
    end

    if not frame.PositionVersionFrames then
        function frame.PositionVersionFrames(_, width)
            local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
            local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
            local versionFrameSpacing = versionFramesTotalWidth / (#labelTitles - 1)

            for i, vFrame in ipairs(frame.versionFrames) do
                vFrame:SetPoint("LEFT", frame, "LEFT", firstVersionFrameX + (i - 1) * versionFrameSpacing, 0)
            end
        end
    end

    frame.PositionVersionFrames(nil, frame:GetWidth())

    frame:SetScript("OnSizechanged", frame.PositionVersionFrames)
end

function LUP:InitializeOtherChecker()
    GenerateDummyData()

    scrollFrame = CreateFrame("Frame", nil, LUP.otherCheckWindow, "WowScrollBoxList")
    scrollFrame:SetPoint("TOPLEFT", LUP.otherCheckWindow, "TOPLEFT", 4, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", LUP.otherCheckWindow, "BOTTOMRIGHT", -24, 4)

    scrollBar = CreateFrame("EventFrame", nil, LUP.otherCheckWindow, "MinimalScrollBar")
    scrollBar:SetPoint("TOP", scrollFrame, "TOPRIGHT", 12, 0)
    scrollBar:SetPoint("BOTTOM", scrollFrame, "BOTTOMRIGHT", 12, 16)

    dataProvider = CreateDataProvider()
    scrollView = CreateScrollBoxListLinearView()
    scrollView:SetDataProvider(dataProvider)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollFrame, scrollBar, scrollView)

    scrollView:SetElementExtent(elementHeight)
    scrollView:SetElementInitializer("Frame", CheckElementInitializer)

    dataProvider:SetSortComparator(
        function(data1, data2)
            local noteOK1 = data1.mrtNoteHash == "" or (data1.mrtNoteHash and data1.mrtNoteHash == mrtNoteHash)
            local noteOK2 = data2.mrtNoteHash == "" or (data2.mrtNoteHash and data2.mrtNoteHash == mrtNoteHash)

            local ignoresOK1 = data1.ignores and not next(data1.ignores)
            local ignoresOK2 = data2.ignores and not next(data2.ignores)

            local rclcOK1 = data1.RCLC and data1.RCLC == LUP.highestSeenRCLCVersion
            local rclcOK2 = data2.RCLC and data2.RCLC == LUP.highestSeenRCLCVersion

            if noteOK1 ~= noteOK2 then
                return noteOK2
            elseif ignoresOK1 ~= ignoresOK2 then
                return ignoresOK2
            elseif rclcOK1 ~= rclcOK2 then
                return rclcOK2
            else
                return data1.name < data2.name
            end
        end
    )

    -- Border
    local borderColor = LUP.gs.visual.borderColor
    LUP:AddBorder(scrollFrame)
    scrollFrame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    LUP.otherChecker:RebuildAllCheckElements()
end