---@diagnostic disable: deprecated
local _, LUP = ...

local bytetoB64 = {
    [0]="a","b","c","d","e","f","g","h",
    "i","j","k","l","m","n","o","p",
    "q","r","s","t","u","v","w","x",
    "y","z","A","B","C","D","E","F",
    "G","H","I","J","K","L","M","N",
    "O","P","Q","R","S","T","U","V",
    "W","X","Y","Z","0","1","2","3",
    "4","5","6","7","8","9","(",")"
}

-- Generates a unique random 11 digit number in base64
-- Taken from WeakAuras
function LUP:GenerateUniqueID()
    local s = {}

    for _ = 1, 11 do
        tinsert(s, bytetoB64[math.random(0, 63)])
    end

    return table.concat(s)
end

-- Rounds a value, optionally to a certain number of decimals
function LUP:Round(value, decimals)
    if not decimals then decimals = 0 end
    
    local p = math.pow(10, decimals)
    
    value = value * p
    value = Round(value)
    value = value / p
    
    return value
end

-- Same as the game's SecondsToClock, except adds a single decimal to the seconds
function LUP:SecondsToClock(seconds, displayZeroHours)
	local units = ConvertSecondsToUnits(seconds)

	if units.hours > 0 or displayZeroHours then
		return format("%.2d:%.2d:%04.1f", units.hours, units.minutes, units.seconds + units.milliseconds)
	else
		return format("%.2d:%04.1f", units.minutes, units.seconds + units.milliseconds)
	end
end

-- Iterates group units
-- Usage: <for unit in LRP:IterateGroupMembers() do>
-- Taken from WeakAuras
function LUP:IterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and IsInRaid()) and "raid" or "party"
    local numGroupMembers = unit == "party" and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == "party" and 0 or 1)

    return function()
        local ret

        if i == 0 and unit == "party" then
            ret = "player"
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end

        i = i + (reversed and -1 or 1)

        return ret
    end
end

-- Adds a tooltip to a frame
-- Can be called repeatedly to change the tooltip
function LUP:AddTooltip(frame, tooltipText, secondaryTooltipText) 
    if not tooltipText then tooltipText = "" end

    frame.secondaryTooltipText = secondaryTooltipText -- Used for stuff like warnings/additional info that shouldn't change the main tooltip text

    -- If this frame already has a tooltip applied to it, simply change the tooltip text
    if frame.tooltipText then
        frame.tooltipText = tooltipText
    else
        frame.tooltipText = tooltipText

        -- The tooltip should be handled in a hook, in case the OnEnter/OnLeave script changes later on
        -- If there is no OnEnter/OnLeave script present, add an empty one
        if not frame:HasScript("OnEnter") then
            frame:SetScript("OnEnter", function() end)
        end

        if not frame:HasScript("OnLeave") then
            frame:SetScript("OnLeave", function() end)
        end

        frame:HookScript(
            "OnEnter",
            function()
                if not frame.tooltipText or frame.tooltipText == "" then return end
                
                LUP.Tooltip:Hide()
                LUP.Tooltip:SetOwner(frame, "ANCHOR_RIGHT")

                if frame.secondaryTooltipText and frame.secondaryTooltipText ~= "" then
                    LUP.Tooltip:SetText(string.format("%s|n|n%s", frame.tooltipText, frame.secondaryTooltipText), 0.9, 0.9, 0.9, 1, true)
                else
                    LUP.Tooltip:SetText(frame.tooltipText, 0.9, 0.9, 0.9, 1, true)
                end

                LUP.Tooltip:Show()
            end
        )

        frame:HookScript(
            "OnLeave",
            function()
                LUP.Tooltip:Hide()
            end
        )
    end
end

-- Refreshes the tooltip that is currently showing
function LUP:RefreshTooltip()
    if LUP.Tooltip:IsVisible() then
        local frame = LUP.Tooltip:GetOwner()

        if frame and frame.tooltipText then
            if frame.secondaryTooltipText and frame.secondaryTooltipText ~= "" then
                LUP.Tooltip:SetText(string.format("%s|n|n%s", frame.tooltipText, frame.secondaryTooltipText), 0.9, 0.9, 0.9, 1, true)
            else
                LUP.Tooltip:SetText(frame.tooltipText, 0.9, 0.9, 0.9, 1, true)
            end
        end
    end
end

-- Takes an icon ID and returns an in-line icon string
function LUP:IconString(iconID)
    return CreateTextureMarkup(iconID, 64, 64, 0, 0, 5/64, 59/64, 5/64, 59/64)
end

-- Save the size/position of a frame in SavedVariables, keyed by some name
function LUP:SaveSize(frame, name)
    if not LiquidUpdaterSaved.settings.frames[name] then
        LiquidUpdaterSaved.settings.frames[name] = {}
    end

    local width, height = frame:GetSize()

    LiquidUpdaterSaved.settings.frames[name].width = width
    LiquidUpdaterSaved.settings.frames[name].height = height
end

function LUP:SavePosition(frame, name)
    if not LiquidUpdaterSaved.settings.frames[name] then
        LiquidUpdaterSaved.settings.frames[name] = {}
    end

    LiquidUpdaterSaved.settings.frames[name].points = {}

    local numPoints = frame:GetNumPoints()

    for i = 1, numPoints do
        local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint(i)

        if relativeTo == nil or relativeTo == UIParent then -- Only consider points relative to UIParent
            table.insert(
                LiquidUpdaterSaved.settings.frames[name].points,
                {
                    point = point,
                    relativePoint = relativePoint,
                    offsetX = offsetX,
                    offsetY = offsetY
                }
            )
        end
    end
end

-- Restore and apply saved size/position to a frame, keyed by some name
function LUP:RestoreSize(frame, name)
    local settings = LiquidUpdaterSaved.settings.frames[name]

    if not settings then return end
    if not settings.width then return end
    if not settings.height then return end

    frame:SetSize(settings.width, settings.height)
end

function LUP:RestorePosition(frame, name)
    local settings = LiquidUpdaterSaved.settings.frames[name]

    if not (settings and settings.points) then return end

    for _, pointInfo in ipairs(settings.points) do
        frame:SetPoint(pointInfo.point, UIParent, pointInfo.relativePoint, pointInfo.offsetX, pointInfo.offsetY)
    end
end

-- Adds a 1 pixel border to a frame
function LUP:AddBorder(parent, thickness, horizontalOffset, verticalOffset)
    if not thickness then thickness = 1 end
    if not horizontalOffset then horizontalOffset = 0 end
    if not verticalOffset then verticalOffset = 0 end
    
    parent.border = {
        top = parent:CreateTexture(nil, "BORDER"),
        bottom = parent:CreateTexture(nil, "BORDER"),
        left = parent:CreateTexture(nil, "BORDER"),
        right = parent:CreateTexture(nil, "BORDER"),
    }

    parent.border.top:SetHeight(thickness)
    parent.border.top:SetPoint("TOPLEFT", parent, "TOPLEFT", -horizontalOffset, verticalOffset)
    parent.border.top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", horizontalOffset, verticalOffset)

    parent.border.bottom:SetHeight(thickness)
    parent.border.bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -horizontalOffset, -verticalOffset)
    parent.border.bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", horizontalOffset, -verticalOffset)

    parent.border.left:SetWidth(thickness)
    parent.border.left:SetPoint("TOPLEFT", parent, "TOPLEFT", -horizontalOffset, verticalOffset)
    parent.border.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -horizontalOffset, -verticalOffset)

    parent.border.right:SetWidth(thickness)
    parent.border.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", horizontalOffset, verticalOffset)
    parent.border.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", horizontalOffset, -verticalOffset)

    function parent:SetBorderColor(r, g, b)
        for _, tex in pairs(parent.border) do
            tex:SetColorTexture(r, g, b)
        end
    end

    function parent:ShowBorder()
        for _, tex in pairs(parent.border) do
            tex:Show()
        end
    end

    function parent:HideBorder()
        for _, tex in pairs(parent.border) do
            tex:Hide()
        end
    end

    function parent:SetBorderShown(shown)
        if shown then
            parent:ShowBorder()
        else
            parent:HideBorder()
        end
    end

    parent:SetBorderColor(0, 0, 0)
end

function LUP:ErrorPrint(text)
    print(string.format("AuraUpdater |cffff0000ERROR|r: %s", text))
end