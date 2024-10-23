local _, LUP = ...

-- Element variables
local nameFrameWidth = 150
local versionFramePaddingLeft = 10
local versionFramePaddingRight = 40
local elementHeight = 32

local scrollFrame, scrollBar, dataProvider, scrollView, labelFrame
local labels = {} -- Label fontstrings
local guidToVersionsTable = {}

-- Checks a unit's new version table against their known one
-- Returns true if something changed
local function ShouldUpdate(GUID, newVersionsTable)
    local oldVersionsTable = guidToVersionsTable[GUID]

    if not oldVersionsTable then return true end
    if not newVersionsTable then return false end

    for k, v in pairs(oldVersionsTable) do
        if v ~= newVersionsTable[k] then return true end
    end

    for k, v in pairs(newVersionsTable) do
        if v ~= oldVersionsTable[k] then return true end
    end

    return false
end

local function PositionAuraLabels(_, width)
    local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
    local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
    local versionFrameSpacing = versionFramesTotalWidth / (#labels - 1)

    for i, versionFrame in ipairs(labels) do
        versionFrame:SetPoint("BOTTOM", labelFrame, "BOTTOMLEFT", firstVersionFrameX + (i - 1) * versionFrameSpacing + 0.5 * elementHeight, 0)
    end
end

local function BuildAuraLabels()
    if not labelFrame then
        labelFrame = CreateFrame("Frame", nil, LUP.checkWindow)
        labelFrame:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 4)
        labelFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "TOPRIGHT", 0, 4)
        labelFrame:SetHeight(24)

        labelFrame:SetScript("OnSizeChanged", PositionAuraLabels)
    end

    local sortedLabelTable = {}

    for displayName in pairs(LUP.highestSeenVersionsTable) do
        table.insert(sortedLabelTable, displayName)
    end

    -- Sort the labels (addon version is always first)
    table.sort(
        sortedLabelTable,
        function(dispalyName1, displayName2)
            local isAddOn1 = dispalyName1 == "AuraUpdater"
            local isAddOn2 = displayName2 == "AuraUpdater"

            if isAddOn1 ~= isAddOn2 then
                return isAddOn1
            else
                return dispalyName1 < displayName2
            end
        end
    )

    for i, displayName in ipairs(sortedLabelTable) do
        if not labels[i] then
            labels[i] = labelFrame:CreateFontString(nil, "OVERLAY")

            labels[i]:SetFont(LUP.gs.visual.font, 15, LUP.gs.visual.fontFlags)
        end

        labels[i]:SetText(string.format("|cff%s%s|r", LUP.gs.visual.colorStrings.white, displayName))
    end

    PositionAuraLabels(nil, scrollFrame:GetWidth())
end

function LUP:UpdateCheckElementForUnit(unit, versionsTable)
    local GUID = UnitGUID(unit)

    if not GUID then return end
    if not ShouldUpdate(GUID, versionsTable) then return end

    guidToVersionsTable[GUID] = versionsTable or {} -- Save for use in RebuildAllCheckElements()

    -- If this unit already has an element, remove it
    dataProvider:RemoveByPredicate(
        function(elementData)
            return elementData.GUID == GUID
        end
    )

    -- Create new data
    local _, class, _, _, _, name = GetPlayerInfoByGUID(GUID)

    if not (class and name) then return end

    local colorStr = RAID_CLASS_COLORS[class].colorStr
    local coloredName = string.format("|c%s%s|r", colorStr, name)

    local data = {
        GUID = GUID,
        unit = unit,
        name = name, -- Used for sorting
        coloredName = coloredName,
        versionsBehindTable = {}
    }

    -- Compare unit's versions against the highest ones we've seen so far
    -- Set version to -1 if no version table was provided (i.e. we have no info for this unit)
    for displayName, highestVersion in pairs(LUP.highestSeenVersionsTable) do
        local version = versionsTable and versionsTable[displayName] or 0
        local versionsBehind = versionsTable and highestVersion - version or -1

        table.insert(
            data.versionsBehindTable,
            {
                displayName = displayName,
                versionsBehind = versionsBehind
            }
        )
    end

    -- Sort the aura versions so they match the labels
    table.sort(
        data.versionsBehindTable,
        function(info1, info2)
            local isAddOn1 = info1.displayName == "AuraUpdater"
            local isAddOn2 = info2.displayName == "AuraUpdater"

            if isAddOn1 ~= isAddOn2 then
                return isAddOn1
            else
                return info1.displayName < info2.displayName
            end
        end
    )

    dataProvider:Insert(data)
end

function LUP:AddCheckElementsForNewUnits()
    for unit in LUP:IterateGroupMembers() do
        local GUID = UnitGUID(unit)

        if not guidToVersionsTable[GUID] then
            LUP:UpdateCheckElementForUnit(unit)
        end
    end
end

-- Iterates existing elements, and removes those whose units are no longer in our group
function LUP:RemoveCheckElementsForInvalidUnits()
    for i, data in dataProvider:ReverseEnumerate() do
        local unit = data.unit

        if not UnitExists(unit) then
            guidToVersionsTable[data.GUID] = nil

            dataProvider:RemoveIndex(i)
        end
    end
end

function LUP:RebuildAllCheckElements()
    for unit in LUP:IterateGroupMembers() do
        local GUID = UnitGUID(unit)
        local versionsTable = guidToVersionsTable[GUID]

        LUP:UpdateCheckElementForUnit(unit, versionsTable)
    end

    BuildAuraLabels()
end

local function CheckElementInitializer(frame, data)
    local versionFrameCount = #data.versionsBehindTable

    -- Create version frames
    if not frame.versionFrames then frame.versionFrames = {} end

    for i = 1, versionFrameCount do
        local subFrame = frame.versionFrames[i] or CreateFrame("Frame", nil, frame)

        subFrame:SetSize(elementHeight, elementHeight)

        frame.versionFrames[i] = subFrame
    end

    if not frame.coloredName then
        frame.coloredName = frame:CreateFontString(nil, "OVERLAY")

        frame.coloredName:SetFont(LUP.gs.visual.font, 21, LUP.gs.visual.fontFlags)
        frame.coloredName:SetPoint("LEFT", frame, "LEFT", 8, 0)
    end

    frame.coloredName:SetText(string.format("|cff%s%s|r", LUP.gs.visual.colorStrings.white, data.coloredName))

    for i, versionInfo in ipairs(data.versionsBehindTable) do
        local versionsBehind = versionInfo.versionsBehind
        local versionFrame = frame.versionFrames[i]

        if not versionFrame.versionsBehindText then
            versionFrame.versionsBehindText = versionFrame:CreateFontString(nil, "OVERLAY")

            versionFrame.versionsBehindText:SetFont(LUP.gs.visual.font, 21, LUP.gs.visual.fontFlags)
            versionFrame.versionsBehindText:SetPoint("CENTER", versionFrame, "CENTER")
        end

        if not versionFrame.versionsBehindIcon then
            versionFrame.versionsBehindIcon = CreateFrame("Frame", nil, versionFrame)
            versionFrame.versionsBehindIcon:SetSize(24, 24)
            versionFrame.versionsBehindIcon:SetPoint("CENTER", versionFrame, "CENTER")

            versionFrame.versionsBehindIcon.tex = versionFrame.versionsBehindIcon:CreateTexture(nil, "BACKGROUND")
            versionFrame.versionsBehindIcon.tex:SetAllPoints()
        end

        if versionsBehind == 0 then
            versionFrame.versionsBehindText:Hide()
            versionFrame.versionsBehindIcon:Show()

            versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-checkmark")

            LUP:AddTooltip(
                versionFrame,
                "This player's aura is up to date."
            )
        elseif versionsBehind == -1 then
            versionFrame.versionsBehindText:Hide()
            versionFrame.versionsBehindIcon:Show()

            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            LUP:AddTooltip(
                versionFrame,
                "No info has been received for this player's auras.|n|nThey may not have AuraUpdater installed."
            )
        else
            versionFrame.versionsBehindText:Show()
            versionFrame.versionsBehindIcon:Hide()

            versionFrame.versionsBehindText:SetText(string.format("|cff%s%d|r", LUP.gs.visual.colorStrings.red, versionsBehind))

            LUP:AddTooltip(
                versionFrame,
                string.format("This player's aura is %d version(s) behind.", versionsBehind)
            )
        end
    end

    if not frame.PositionVersionFrames then
        function frame.PositionVersionFrames(_, width)
            local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
            local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
            local versionFrameSpacing = versionFramesTotalWidth / (#frame.versionFrames - 1)

            for i, versionFrame in ipairs(frame.versionFrames) do
                versionFrame:SetPoint("LEFT", frame, "LEFT", firstVersionFrameX + (i - 1) * versionFrameSpacing, 0)
            end
        end
    end

    frame.PositionVersionFrames(nil, frame:GetWidth())

    frame:SetScript("OnSizechanged", frame.PositionVersionFrames)
end

function LUP:InitializeAuraChecker()
    scrollFrame = CreateFrame("Frame", nil, LUP.checkWindow, "WowScrollBoxList")
    scrollFrame:SetPoint("TOPLEFT", LUP.checkWindow, "TOPLEFT", 4, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", LUP.checkWindow, "BOTTOMRIGHT", -24, 4)

    scrollBar = CreateFrame("EventFrame", nil, LUP.checkWindow, "MinimalScrollBar")
    scrollBar:SetPoint("TOP", scrollFrame, "TOPRIGHT", 12, 0)
    scrollBar:SetPoint("BOTTOM", scrollFrame, "BOTTOMRIGHT", 12, 16)

    dataProvider = CreateDataProvider()
    scrollView = CreateScrollBoxListLinearView()
    scrollView:SetDataProvider(dataProvider)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollFrame, scrollBar, scrollView)

    -- The first argument here can either be a frame type or frame template. We're just passing the "UIPanelButtonTemplate" template here
    scrollView:SetElementExtent(elementHeight)
    scrollView:SetElementInitializer("Frame", CheckElementInitializer)

    dataProvider:SetSortComparator(
        function(data1, data2)
            local hasInfo1 = next(data1.versionsBehindTable)
            local hasInfo2 = next(data2.versionsBehindTable)

            local versionsBehindCount1 = 0
            local versionsBehindCount2 = 0

            for _, versionInfo in ipairs(data1.versionsBehindTable) do
                versionsBehindCount1 = versionsBehindCount1 + versionInfo.versionsBehind
            end

            for _, versionInfo in ipairs(data2.versionsBehindTable) do
                versionsBehindCount2 = versionsBehindCount2 + versionInfo.versionsBehind
            end

            if hasInfo1 ~= hasInfo2 then
                return hasInfo1
            elseif versionsBehindCount1 ~= versionsBehindCount2 then
                return versionsBehindCount1 > versionsBehindCount2
            else
                return data1.name < data2.name
            end
        end
    )

    -- Border
    local borderColor = LUP.gs.visual.borderColor
    LUP:AddBorder(scrollFrame)
    scrollFrame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    LUP:RebuildAllCheckElements()
end