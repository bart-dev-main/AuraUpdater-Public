local SharedMedia = LibStub("LibSharedMedia-3.0")

AuraUpdater = {}

local anchorSettings = {}
local updateAnchorFunctions = {}
local applyAnchorFunctions = {}

local function PositionAuras(settings, newPositions, activeRegions)
    local nextPosition = {0, 0}
    local limit = settings.limit or #activeRegions
    local directionX = settings.grow == "RIGHT" and 1 or settings.grow == "LEFT" and -1 or 0
    local directionY = settings.grow == "UP" and 1 or settings.grow == "DOWN" and -1 or 0

    for regionCount, regionData in ipairs(activeRegions) do
        if regionCount > limit then
            newPositions[regionCount] = {0, 0, false}
        else
            local skipPosition = regionData.region.state.skipPosition

            newPositions[regionCount] = nextPosition

            if not skipPosition then
                local width = settings.width or regionData.region.width
                local height = settings.height or regionData.region.height

                nextPosition = {
                    nextPosition[1] + directionX * (width + settings.space),
                    nextPosition[2] + directionY * (height + settings.space)
                }
            end
        end
    end
end

local function ResizeAura(settings, region)
    region:SetRegionWidth(settings.width)
    region:SetRegionHeight(settings.height)
end

local function ApplySubtextSettings(settings, region)
    local subtextCount = 0

    for _, subRegion in ipairs(region.subRegions) do
        if subRegion.type == "subtext" then
            subtextCount = subtextCount + 1

            local subtextSettings = settings.subtexts[subtextCount]

            if not subtextSettings then break end

            subRegion.text:SetFont(subtextSettings.fontPath, subtextSettings.size, subtextSettings.type)
        end
    end
end

local function ApplyBarTexture(settings, region)
    region.texture = settings.texture
    region.textureInput = settings.textureInput
    region.textureSource = settings.textureSource

    region:UpdateStatusBarTexture()
end

local function ResizeTicks(settings, region)
    for _, subRegion in ipairs(region.subRegions) do
        if subRegion.type == "subtick" then
            subRegion:SetAutomaticLength(false)
            subRegion:SetTickLength(settings.height)
        end
    end
end

local function ResizeSpark(settings, region)
    region:SetSparkHeight(settings.height)
end

-- Generic functions
-- Bars
local function GetBarSettings(groupName, auraName)
    local groupData = WeakAuras.GetData(groupName)
    local auraData = WeakAuras.GetData(auraName)

    if not (groupData and auraData) then return end

    local settings = {
        subtexts = {}
    }

    settings.grow = groupData.grow
    settings.limit = groupData.useLimit and groupData.limit or 100
    settings.space = groupData.space

    settings.width = auraData.width
    settings.height = auraData.height

    settings.texture = auraData.texture
    settings.textureInput = auraData.textureInput
    settings.textureSource = auraData.textureSource

    for _, subRegion in ipairs(auraData.subRegions) do
        if subRegion.type == "subtext" then
            table.insert(
                settings.subtexts,
                {
                    fontPath = SharedMedia:Fetch("font", subRegion.text_font),
                    size = subRegion.text_fontSize,
                    type = subRegion.text_fontType
                }
            )
        end
    end

    return settings
end

local function ApplyBarSettings(settings, newPositions, activeRegions)
    if not settings then return end

    PositionAuras(settings, newPositions, activeRegions)

    for _, regionData in ipairs(activeRegions) do
        local region = regionData.region

        if region.regionType == "aurabar" then
            ResizeAura(settings, region)
            ApplyBarTexture(settings, region)
            ApplySubtextSettings(settings, region)
            ResizeTicks(settings, region)
            ResizeSpark(settings, region)
        end
    end
end

-- Icons
local function GetIconSettings(groupName, auraName)
    local groupData = WeakAuras.GetData(groupName)
    local auraData = WeakAuras.GetData(auraName)

    if not (groupData and auraData) then return end

    local settings = {
        subtexts = {}
    }

    settings.grow = groupData.grow
    settings.limit = groupData.useLimit and groupData.limit or 100
    settings.space = groupData.space

    settings.width = auraData.width
    settings.height = auraData.height

    for _, subRegion in ipairs(auraData.subRegions) do
        if subRegion.type == "subtext" then
            table.insert(
                settings.subtexts,
                {
                    fontPath = SharedMedia:Fetch("font", subRegion.text_font),
                    size = subRegion.text_fontSize,
                    type = subRegion.text_fontType
                }
            )
        end
    end

    return settings
end

local function ApplyIconSettings(settings, newPositions, activeRegions)
    if not settings then return end

    PositionAuras(settings, newPositions, activeRegions)

    for _, regionData in ipairs(activeRegions) do
        local region = regionData.region

        if region.regionType == "icon" then
            ResizeAura(settings, region)
            ApplySubtextSettings(settings, region)
        end
    end
end

-- Texts
local function GetTextSettings(groupName, auraName)
    local groupData = WeakAuras.GetData(groupName)
    local auraData = WeakAuras.GetData(auraName)

    if not (groupData and auraData) then return end

    local settings = {}

    settings.grow = groupData.grow
    settings.limit = groupData.useLimit and groupData.limit or 100
    settings.space = groupData.space

    settings.fontPath = SharedMedia:Fetch("font", auraData.font)
    settings.height = auraData.fontSize
    settings.fontType = auraData.outline

    return settings
end

local function ApplyTextSettings(settings, newPositions, activeRegions)
    if not settings then return end

    PositionAuras(settings, newPositions, activeRegions)

    -- Apply font settings
    for _, regionData in ipairs(activeRegions) do
        local region = regionData.region

        if region.regionType == "text" then
            region.text:SetFont(settings.fontPath, settings.height, settings.fontType)

            -- Required to force text positioning when no text replacements are present
            region:SetHeight(settings.height)
            region:SetWidth(region.text:GetWidth())
        end
    end
end

-- Specific functions
-- Bars
updateAnchorFunctions.Bars = function()
    anchorSettings.bars = GetBarSettings(
        "Liquid Anchor - Bars",
        "Liquid Anchor - Bar"
    )
end

applyAnchorFunctions.Bars = function(newPositions, activeRegions)
    ApplyBarSettings(anchorSettings.bars, newPositions, activeRegions)
end

-- Special Bars
updateAnchorFunctions.SpecialBars = function()
    anchorSettings.specialBars = GetBarSettings(
        "Liquid Anchor - Special Bars",
        "Liquid Anchor - Special Bar"
    )
end

applyAnchorFunctions.SpecialBars = function(newPositions, activeRegions)
    ApplyBarSettings(anchorSettings.specialBars, newPositions, activeRegions)
end

-- Lists
updateAnchorFunctions.Lists = function()
    anchorSettings.lists = GetBarSettings(
        "Liquid Anchor - Lists",
        "Liquid Anchor - List"
    )
end

applyAnchorFunctions.Lists = function(newPositions, activeRegions)
    ApplyBarSettings(anchorSettings.lists, newPositions, activeRegions)
end

-- Raid Leader Lists
updateAnchorFunctions.RaidLeaderLists = function()
    anchorSettings.raidLeaderLists = GetBarSettings(
        "Liquid Anchor - Raid Leader Lists",
        "Liquid Anchor - Raid Leader List"
    )
end

applyAnchorFunctions.RaidLeaderLists = function(newPositions, activeRegions)
    ApplyBarSettings(anchorSettings.raidLeaderLists, newPositions, activeRegions)
end

-- Big Icons
updateAnchorFunctions.BigIcons = function()
    anchorSettings.bigIcons = GetIconSettings(
        "Liquid Anchor - Big Icons",
        "Liquid Anchor - Big Icon"
    )
end

applyAnchorFunctions.BigIcons = function(newPositions, activeRegions)
    ApplyIconSettings(anchorSettings.bigIcons, newPositions, activeRegions)
end

-- Icons
updateAnchorFunctions.Icons = function()
    anchorSettings.icons = GetIconSettings(
        "Liquid Anchor - Icons",
        "Liquid Anchor - Icon"
    )
end

applyAnchorFunctions.Icons = function(newPositions, activeRegions)
    ApplyIconSettings(anchorSettings.icons, newPositions, activeRegions)
end

-- Circles
updateAnchorFunctions.Circles = function()
    local groupData = WeakAuras.GetData("Liquid Anchor - Circles")
    local auraData = WeakAuras.GetData("Liquid Anchor - Circle")

    if not (groupData and auraData) then return end

    local settings = {
        subtexts = {}
    }

    settings.width = auraData.width
    settings.height = auraData.height

    for _, subRegion in ipairs(auraData.subRegions) do
        if subRegion.type == "subtext" then
            table.insert(
                settings.subtexts,
                {
                    fontPath = SharedMedia:Fetch("font", subRegion.text_font),
                    size = subRegion.text_fontSize,
                    type = subRegion.text_fontType
                }
            )
        end
    end

    anchorSettings.circles = settings
end

applyAnchorFunctions.Circles = function(newPositions, activeRegions)
    local settings = anchorSettings.circles

    if not settings then return end

    for regionCount, regionData in ipairs(activeRegions) do
        local region = regionData.region

        -- Circles are fairly unique in that they should always appear on the character, so they are not positioned "dynamically"
        -- This is the reason that we don't use PositionAuras() for circles
        newPositions[regionCount] = {0, 0}

        ResizeAura(settings, region)
        ApplySubtextSettings(settings, region)
    end
end

-- Texts
updateAnchorFunctions.Texts = function()
    anchorSettings.texts = GetTextSettings(
        "Liquid Anchor - Texts",
        "Liquid Anchor - Text"
    )
end

applyAnchorFunctions.Texts = function(newPositions, activeRegions)
    ApplyTextSettings(anchorSettings.texts, newPositions, activeRegions)
end

-- Assignments
updateAnchorFunctions.Assignments = function()
    anchorSettings.assignments = GetTextSettings(
        "Liquid Anchor - Assignments",
        "Liquid Anchor - Assignment"
    )
end

applyAnchorFunctions.Assignments = function(newPositions, activeRegions)
    ApplyTextSettings(anchorSettings.assignments, newPositions, activeRegions)
end

-- Tank Warnings
updateAnchorFunctions.TankWarningsBars = function()
    anchorSettings.tankWarningsBars = GetBarSettings(
        "Liquid Anchor - Tank Warnings",
        "Liquid Anchor - Tank Warning Bar"
    )
end

updateAnchorFunctions.TankWarningsTexts = function()
    anchorSettings.tankWarningsTexts = GetTextSettings(
        "Liquid Anchor - Tank Warnings",
        "Liquid Anchor - Tank Warning Text"
    )
end

applyAnchorFunctions.TankWarnings = function(newPositions, activeRegions)
    local barSettings = anchorSettings.tankWarningsBars
    local textSettings = anchorSettings.tankWarningsTexts

    if not (barSettings and textSettings) then return end

    -- Position is not done using PositionAuras(), since tank warnings are unique in that they have both bars and texts
    -- Both barSettings and textSettings contains identical group settings data. We just use barSettings to fetch things like limit, spacing, etc.
    local nextPosition = {0, 0}
    local limit = barSettings.limit or #activeRegions
    local directionX = barSettings.grow == "RIGHT" and 1 or barSettings.grow == "LEFT" and -1 or 0
    local directionY = barSettings.grow == "UP" and 1 or barSettings.grow == "DOWN" and -1 or 0

    for regionCount, regionData in ipairs(activeRegions) do
        local region = regionData.region
        local regionType = region.regionType

        if regionCount > limit then
            newPositions[regionCount] = {0, 0, false}
        else
            local skipPosition = region.state.skipPosition

            newPositions[regionCount] = nextPosition

            if not skipPosition then
                local width = regionType == "aurabar" and barSettings.width or regionType == "text" and textSettings.width or regionData.region.width
                local height = regionType == "aurabar" and barSettings.height or regionType == "text" and textSettings.height or regionData.region.height

                nextPosition = {
                    nextPosition[1] + directionX * (width + barSettings.space),
                    nextPosition[2] + directionY * (height + barSettings.space)
                }
            end
        end
    end

    -- Applying bar/text settings
    for _, regionData in ipairs(activeRegions) do
        local region = regionData.region

        if region.regionType == "aurabar" then
            ResizeAura(barSettings, region)
            ApplyBarTexture(barSettings, region)
            ApplySubtextSettings(barSettings, region)
        elseif region.regionType == "text" then
            region.text:SetFont(textSettings.fontPath, textSettings.height, textSettings.fontType)

            -- Required to force text positioning when no text replacements are present
            region:SetHeight(textSettings.height)
            region:SetWidth(region.text:GetWidth())
        end
    end
end

-- Tank Icons
updateAnchorFunctions.TankIcons = function()
    anchorSettings.tankIcons = GetIconSettings(
        "Liquid Anchor - Tank Icons",
        "Liquid Anchor - Tank Icon"
    )
end

applyAnchorFunctions.TankIcons = function(newPositions, activeRegions)
    ApplyIconSettings(anchorSettings.tankIcons, newPositions, activeRegions)
end

-- Co-Tank Icons
updateAnchorFunctions.CoTankIcons = function()
    anchorSettings.coTankIcons = GetIconSettings(
        "Liquid Anchor - Co-Tank Icons",
        "Liquid Anchor - Co-Tank Icon"
    )
end

applyAnchorFunctions.CoTankIcons = function(newPositions, activeRegions)
    ApplyIconSettings(anchorSettings.coTankIcons, newPositions, activeRegions)
end

function AuraUpdater:UpdateAnchorSettings(anchorType)
    if not updateAnchorFunctions[anchorType] then return end

    updateAnchorFunctions[anchorType]()
end

function AuraUpdater:ApplyAnchorSettings(anchorType, newPositions, activeRegions)
    if not applyAnchorFunctions[anchorType] then return end

    applyAnchorFunctions[anchorType](newPositions, activeRegions)
end