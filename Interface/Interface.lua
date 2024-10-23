local addOnName, LUP = ...

-- Tooltip
CreateFrame("GameTooltip", "LRTooltip", UIParent, "GameTooltipTemplate")

LUP.Tooltip = _G["LRTooltip"]
LUP.Tooltip.TextLeft1:SetFont(LUP.gs.visual.font, 13)

-- Main window
local windowWidth = 600
local windowHeight = 400

function LUP:InitializeInterface()
    local screenWidth, screenHeight = GetPhysicalScreenSize()

    -- Window
    LUP.window = LUP:CreateWindow("Main", true, true, true)
    LUP.window:SetFrameStrata("HIGH")
    LUP.window:SetResizeBounds(windowWidth, windowHeight) -- Height is set based on timeine data
    LUP.window:Hide()

    -- Button frame
    local buttonFrame = CreateFrame("Frame", nil, LUP.window)

    buttonFrame:SetPoint("TOPLEFT", LUP.window.moverFrame, "BOTTOMLEFT")
    buttonFrame:SetPoint("TOPRIGHT", LUP.window.moverFrame, "BOTTOMRIGHT")

    buttonFrame:SetHeight(32)

    -- Update button
    local updateButton = CreateFrame("Frame", nil, LUP.window)

    updateButton:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 4, -4)
    updateButton:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOM", -2, 0)
    updateButton:EnableMouse(true)

    updateButton.highlight = updateButton:CreateTexture(nil, "HIGHLIGHT")
    updateButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    updateButton.highlight:SetAllPoints()

    updateButton.text = updateButton:CreateFontString(nil, "OVERLAY")
    updateButton.text:SetFont(LUP.gs.visual.font, 17, LUP.gs.visual.fontFlags)
    updateButton.text:SetPoint("CENTER", updateButton, "CENTER")
    updateButton.text:SetText(string.format("|cff%sUpdate|r", LUP.gs.visual.colorStrings.white))

    updateButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Show()
            LUP.checkWindow:Hide()
        end
    )

    local borderColor = LUP.gs.visual.borderColor
    LUP:AddBorder(updateButton)
    updateButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Check button
    local checkButton = CreateFrame("Frame", nil, LUP.window)

    checkButton:SetPoint("TOPRIGHT", buttonFrame, "TOPRIGHT", -4, -4)
    checkButton:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOM", 2, 0)
    checkButton:EnableMouse(true)

    checkButton.highlight = checkButton:CreateTexture(nil, "HIGHLIGHT")
    checkButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    checkButton.highlight:SetAllPoints()

    checkButton.text = checkButton:CreateFontString(nil, "OVERLAY")
    checkButton.text:SetFont(LUP.gs.visual.font, 17, LUP.gs.visual.fontFlags)
    checkButton.text:SetPoint("CENTER", checkButton, "CENTER")
    checkButton.text:SetText(string.format("|cff%sCheck|r", LUP.gs.visual.colorStrings.white))

    checkButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Hide()
            LUP.checkWindow:Show()
        end
    )

    LUP:AddBorder(checkButton)
    checkButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Sub windows
    LUP.updateWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.updateWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.updateWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.checkWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.checkWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.checkWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.checkWindow:Hide()

    -- If there's no saved position/size settings for the main window yet, apply some default values
    local windowSettings = LiquidUpdaterSaved.settings.frames["Main"]

    if not windowSettings or not windowSettings.points then
        LUP.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (screenWidth - windowWidth) / 2, -(screenHeight - windowHeight) / 2)
    end

    if not windowSettings or not windowSettings.width then
        LUP.window:SetSize(windowWidth, windowHeight)
    end
end