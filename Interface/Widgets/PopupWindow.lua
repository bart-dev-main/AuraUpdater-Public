local _, LUP = ...

local windowWidth = 240
local spacing = 8
local window, confirmButton, title, textWrapper, dontShowAgainCheckButton
local dontShowAgain = false

local function UpdateWindowSize()
    C_Timer.After(
        0,
        function()
            window:SetHeight(title:GetHeight() + 2 * spacing + 64 + (dontShowAgainCheckButton:IsShown() and 32 or 0))
        end
    )
end

function LUP:ShowPopupWindow(text, onConfirm, xOffset, yOffset, dontShowAgainCheck, confirmButtonOverride)
    if window:IsShown() then
        window:Hide()
    end

    window:Show()
    window:ClearAllPoints()
    window:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    window:SetFrameStrata("DIALOG")
    
    title:SetText(text)

    confirmButton:SetScript(
        "OnClick",
        function()
            onConfirm(dontShowAgain)

            window:Hide()
        end
    )

    dontShowAgainCheckButton:SetShown(dontShowAgainCheck)
    dontShowAgainCheckButton:SetChecked(false)

    if confirmButtonOverride then
        confirmButton:SetText(string.format("|cff%s%s|r", LUP.gs.visual.colorStrings.green, confirmButtonOverride))
    else
        confirmButton:SetText(string.format("|cff%sOK|r", LUP.gs.visual.colorStrings.green))
    end

    UpdateWindowSize()
end

function LUP:InitializePopupWindow()
    window = LUP:CreateWindow(nil, true, true)
    LUP.popupWindow = window

    window:SetWidth(windowWidth)
    window:SetIgnoreParentAlpha(true)
    window:SetFrameStrata("DIALOG")
    window:Hide()

    confirmButton = LUP:CreateButton(window, "|cff00ff00OK|r", function() end)
    confirmButton:SetPoint("BOTTOM", window, "BOTTOM", 0, 10)

    dontShowAgainCheckButton = LUP:CreateCheckButton(
        window,
        "Don't show again",
        function(checked)
            dontShowAgain = checked
        end
    )

    dontShowAgainCheckButton:SetPoint("BOTTOM", confirmButton, "TOP", -54, 10)

    LUP:AddTooltip(dontShowAgainCheckButton, "You can change this option in the settings menu.")
    LUP:AddTooltip(dontShowAgainCheckButton.title, "You can change this option in the settings menu.")

    title = window:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", window.moverFrame, "BOTTOM", 0, -spacing)
    title:SetFontObject(AUFont16)
    title:SetWordWrap(true)
    title:SetWidth(windowWidth - 2 * spacing)

    textWrapper = CreateFrame("Frame")
    textWrapper:SetAllPoints(title)
    textWrapper:SetScript("OnSizeChanged", UpdateWindowSize)
end