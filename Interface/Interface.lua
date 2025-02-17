local _, LUP = ...

-- Tooltip
CreateFrame("GameTooltip", "LRTooltip", UIParent, "GameTooltipTemplate")

LUP.Tooltip = _G["LRTooltip"]
LUP.Tooltip.TextLeft1:SetFontObject(AUFont13)

-- Main window
local windowWidth = 640
local windowHeight = 400

local updateButton, auraCheckButton, otherCheckButton

local function ResizeHeaderButtons(_, buttonFrameWidth)
    local combinedButtonWidth = buttonFrameWidth - 16

    updateButton:SetWidth(combinedButtonWidth / 3)
    auraCheckButton:SetWidth(combinedButtonWidth / 3)
end

function LUP:InitializeInterface()
    -- Window
    LUP.window = LUP:CreateWindow("Main", true, true, true)
    LUP.window:SetFrameStrata("HIGH")
    LUP.window:SetResizeBounds(windowWidth, windowHeight)
    LUP.window:SetPoint("CENTER")
    LUP.window:Hide()

    LUP.window:AddButton(
        "Interface\\Addons\\AuraUpdater\\Media\\Textures\\Cogwheel.tga",
        "Settings",
        function()
            LUP.settingsWindow:SetShown(not LUP.settingsWindow:IsShown())
        end
    )

    -- Button frame
    local buttonFrame = CreateFrame("Frame", nil, LUP.window)

    buttonFrame:SetPoint("TOPLEFT", LUP.window.moverFrame, "BOTTOMLEFT")
    buttonFrame:SetPoint("TOPRIGHT", LUP.window.moverFrame, "BOTTOMRIGHT")

    buttonFrame:SetHeight(32)
    buttonFrame:SetScript("OnSizeChanged", ResizeHeaderButtons)

    -- Update button
    updateButton = CreateFrame("Frame", nil, LUP.window)

    updateButton:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 4, -4)
    updateButton:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 4, 0)
    updateButton:EnableMouse(true)

    updateButton.highlight = updateButton:CreateTexture(nil, "HIGHLIGHT")
    updateButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    updateButton.highlight:SetAllPoints()

    updateButton.text = updateButton:CreateFontString(nil, "OVERLAY")
    updateButton.text:SetFontObject(AUFont17)
    updateButton.text:SetPoint("CENTER", updateButton, "CENTER")
    updateButton.text:SetText(string.format("|cff%sUpdate|r", LUP.gs.visual.colorStrings.white))

    updateButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Show()
            LUP.auraCheckWindow:Hide()
            LUP.otherCheckWindow:Hide()
        end
    )

    local borderColor = LUP.gs.visual.borderColor
    LUP:AddBorder(updateButton)
    updateButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Aura check button
    auraCheckButton = CreateFrame("Frame", nil, LUP.window)

    auraCheckButton:SetPoint("TOPLEFT", updateButton, "TOPRIGHT", 4, 0)
    auraCheckButton:SetPoint("BOTTOMLEFT", updateButton, "BOTTOMRIGHT", 4, 0)
    auraCheckButton:EnableMouse(true)

    auraCheckButton.highlight = auraCheckButton:CreateTexture(nil, "HIGHLIGHT")
    auraCheckButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    auraCheckButton.highlight:SetAllPoints()

    auraCheckButton.text = auraCheckButton:CreateFontString(nil, "OVERLAY")
    auraCheckButton.text:SetFontObject(AUFont17)
    auraCheckButton.text:SetPoint("CENTER", auraCheckButton, "CENTER")
    auraCheckButton.text:SetText(string.format("|cff%sAura check|r", LUP.gs.visual.colorStrings.white))

    auraCheckButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Hide()
            LUP.auraCheckWindow:Show()
            LUP.otherCheckWindow:Hide()
        end
    )

    LUP:AddBorder(auraCheckButton)
    auraCheckButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Other check button
    otherCheckButton = CreateFrame("Frame", nil, LUP.window)

    otherCheckButton:SetPoint("TOPLEFT", auraCheckButton, "TOPRIGHT", 4, 0)
    otherCheckButton:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", -4, 0)
    otherCheckButton:EnableMouse(true)

    otherCheckButton.highlight = otherCheckButton:CreateTexture(nil, "HIGHLIGHT")
    otherCheckButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    otherCheckButton.highlight:SetAllPoints()

    otherCheckButton.text = otherCheckButton:CreateFontString(nil, "OVERLAY")
    otherCheckButton.text:SetFontObject(AUFont17)
    otherCheckButton.text:SetPoint("CENTER", otherCheckButton, "CENTER")
    otherCheckButton.text:SetText(string.format("|cff%sOther check|r", LUP.gs.visual.colorStrings.white))

    otherCheckButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Hide()
            LUP.auraCheckWindow:Hide()
            LUP.otherCheckWindow:Show()
        end
    )

    LUP:AddBorder(otherCheckButton)
    otherCheckButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Sub windows
    LUP.updateWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.updateWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.updateWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.auraCheckWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.auraCheckWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.auraCheckWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.otherCheckWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.otherCheckWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.otherCheckWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.auraCheckWindow:Hide()
    LUP.otherCheckWindow:Hide()

    LUP.window:SetSize(windowWidth, windowHeight)

    LUP:InitializePopupWindow()
    LUP:InitializeSettings()

    -- When escape is pressed, cclose the main window
    LUP.window:SetScript(
        "OnKeyDown",
        function(_, key)
            if InCombatLockdown() then return end

            if key == "ESCAPE" then
                LUP.window:SetPropagateKeyboardInput(false)

                LUP.window:Hide()
            else
                LUP.window:SetPropagateKeyboardInput(true)
            end
        end
    )
end