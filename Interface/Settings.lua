local _, LUP = ...

local windowWidth = 250
local windowHeight = 157

local padding = 8
local spacing = 4 -- Spacing between UI elements
local checkButtons = {}
local nicknameEditBox

local function AddCheckButton(title, tooltip, isChecked, OnValueChanged)
    local checkButton = LUP:CreateCheckButton(
        LUP.settingsWindow,
        title,
        OnValueChanged
    )

    if next(checkButtons) then
        checkButton:SetPoint("TOPLEFT", checkButtons[#checkButtons], "BOTTOMLEFT", 0, -spacing)
    else
        checkButton:SetPoint("TOPLEFT", LUP.settingsWindow, "TOPLEFT", padding, -padding)
    end

    checkButton:SetChecked(isChecked)
    checkButton:SetSize(20, 20)
    checkButton.title:SetFontObject(AUFont15)

    LUP:AddTooltip(checkButton, tooltip)
    LUP:AddTooltip(checkButton.title, tooltip)

    table.insert(checkButtons, checkButton)
end

-- This can be set from the popup window, so needs a generic function that can be used in both places
function LUP:SetNotifyOnReadyCheck(checked)
    checkButtons[2]:SetChecked(checked)
end

function LUP:InitializeSettings()
    LUP.settingsWindow = LUP:CreateWindow("Settings")
    LUP.settingsWindow:SetParent(LUP.window)
    LUP.settingsWindow:SetPoint("TOPLEFT", LUP.window, "TOPRIGHT", 4, 0)
    LUP.settingsWindow:SetSize(windowWidth, windowHeight)
    LUP.settingsWindow:Hide()

    AddCheckButton(
        "Hide minimap icon when up to date",
        "Hides the minimap icon when all your auras (and the addon itself) are up to date.",
        LiquidUpdaterSaved.settings.hideMinimapIcon,
        function(hideMinimapIcon)
            LiquidUpdaterSaved.settings.hideMinimapIcon = hideMinimapIcon
            
            LUP:UpdateMinimapIconVisibility()
        end
    )

    AddCheckButton(
        "Notify on ready check",
        "If your addon or any of your auras are out of date, show a popup window on ready check.",
        LiquidUpdaterSaved.settings.readyCheckPopup,
        function(readyCheckPopup)
            LiquidUpdaterSaved.settings.readyCheckPopup = readyCheckPopup
        end
    )

    -- To check options for a module, make sure it's loaded (by going into its options), then dump BigWigs:GetBossModule(moduleName).db
    AddCheckButton(
        "Disable BigWigs assignments",
        "When checked, automatically disables BigWigs assignments (and marks) that clash with Liquid WeakAura assignments.|n|n" ..
        "The following options are disabled:|n|n" ..
        CreateTextureMarkup(5770809, 64, 64, 0, 0, 5/64, 59/64, 5/64, 59/64) .. " |cff1998faNerub-ar Palace|r|n" ..
        "- Experimental Dosage assignments|n" ..
        "- Voracious Worm marking|n" ..
        "- Reactive Toxin assignments",
        LiquidUpdaterSaved.settings.disableBigWigsAssignments,
        function(disableBigWigsAssignments)
            LiquidUpdaterSaved.settings.disableBigWigsAssignments = disableBigWigsAssignments

            if disableBigWigsAssignments then
                LUP:RegisterBigWigsDisabler()
            else
                LUP:UnregisterBigWigsDisabler()
            end
        end
    )

    nicknameEditBox = LUP:CreateEditBox(
        LUP.settingsWindow,
        "Nickname",
        function(nickname)
            LUP:QueueNicknameUpdate(nickname)
        end
    )

    nicknameEditBox:SetPoint("TOPLEFT", checkButtons[#checkButtons], "BOTTOMLEFT", 0, -32)
    nicknameEditBox:SetSize(155, 20)
    nicknameEditBox:SetAlphabeticOnly(true)
    nicknameEditBox:SetMaxLetters(12)

    local nicknameTooltips = "Set a nickname for yourself that your group members can see.|n|n" ..
    "Nicknames show instead of character names in several places, such as WeakAuras, unit frames, and AuraUpdater.|n|n" ..
    "They can also be used in MRT assignments, or for MRT reminders."

    LUP:AddTooltip(nicknameEditBox, nicknameTooltips)

    -- If the user has a preset nickname, don't allow them to change their nickname manually
    local presetNickname = LUP:GetPresetNickname()

    if false and presetNickname then
        nicknameEditBox:SetText(presetNickname)

        nicknameEditBox:SetScript(
            "OnCursorChanged",
            function()
                nicknameEditBox:ClearHighlightText()
                nicknameEditBox:ClearFocus()
            end
        )

        nicknameEditBox:SetScript(
            "OnTextChanged",
            function()
                nicknameEditBox:SetText(presetNickname)
                nicknameEditBox:ClearHighlightText()
                nicknameEditBox:ClearFocus()
            end
        )

        nicknameEditBox.secondaryTooltipText = string.format("|cff%sA preset nickname is associated with your battle.net account, so you cannot set one yourself.|r", LUP.gs.visual.colorStrings.red)
    else
        nicknameEditBox:SetText(LiquidUpdaterSaved.nickname or "")
    end

    -- Nickname warning
    local warningIcon = CreateFrame("Button", nil, nicknameEditBox)

    warningIcon:SetSize(15, 15)
    warningIcon:SetNormalAtlas("services-icon-warning")
    warningIcon:SetHighlightAtlas("services-icon-warning", "ADD")
    warningIcon:SetPoint("BOTTOMRIGHT", nicknameEditBox, "TOPRIGHT")
    
    LUP:AddTooltip(
        warningIcon,
        string.format("|cff%sWarning|r|n|n", LUP.gs.visual.colorStrings.red) ..
        "Your nickname should be unique within your group. If it's the same as someone else's nickname/character name, it may cause assignment issues."
    )

    -- ElvUI nickname info
    local elvInfoTooltip = "To show nicknames on ElvUI frames:|n|n" ..
    "- Open ElvUI settings|n" ..
    "- UnitFrames > Group Units|n" ..
    "- Party (repeat for raid1 etc.) > Name|n" ..
    "- Replace the name tag with [nickname-len12]|n|n" ..
    "To shorten the name that is displayed, replace the 12 by a lower number."
    
    local elvInfoButton = CreateFrame("Button", nil, LUP.settingsWindow)

    elvInfoButton:SetSize(16, 16)
    elvInfoButton:SetPoint("TOPLEFT", nicknameEditBox, "BOTTOMLEFT", 0, -6)
    elvInfoButton:SetHighlightTexture("Interface\\AddOns\\AuraUpdater\\Media\\Textures\\Help-i-highlight.tga", "ADD")
    elvInfoButton:SetMouseMotionEnabled(true)

    elvInfoButton.tex = elvInfoButton:CreateTexture()
    elvInfoButton.tex:SetAllPoints(elvInfoButton)
    elvInfoButton.tex:SetTexture("Interface\\AddOns\\AuraUpdater\\Media\\Textures\\Help-i.tga")

    LUP:AddTooltip(elvInfoButton, elvInfoTooltip)

    local elvInfoTitle = elvInfoButton:CreateFontString(nil, "OVERLAY")

    elvInfoTitle:SetFontObject(AUFont15)
    elvInfoTitle:SetText(string.format("|cff%sElvUI|r", LUP.gs.visual.colorStrings.white))
    elvInfoTitle:SetPoint("LEFT", elvInfoButton, "RIGHT", 2, -1)

    -- Grid2 nickname info
    local gridInfoTooltip = "To show nicknames on Grid2 frames:|n|n" ..
    "- Open Grid2 settings|n" ..
    "- Go to statuses|n" ..
    "- Disable Miscellaneous > name|n" ..
    "- Enable miscellaneous > AuraUpdater Nickname"

    local gridInfoButton = CreateFrame("Button", nil, LUP.settingsWindow)

    gridInfoButton:SetSize(15, 15)
    gridInfoButton:SetPoint("LEFT", elvInfoTitle, "RIGHT", 8, 1)
    gridInfoButton:SetHighlightTexture("Interface\\AddOns\\AuraUpdater\\Media\\Textures\\Help-i-highlight.tga", "ADD")
    gridInfoButton:SetMouseMotionEnabled(true)

    gridInfoButton.tex = gridInfoButton:CreateTexture()
    gridInfoButton.tex:SetAllPoints(gridInfoButton)
    gridInfoButton.tex:SetTexture("Interface\\AddOns\\AuraUpdater\\Media\\Textures\\Help-i.tga")

    LUP:AddTooltip(gridInfoButton, gridInfoTooltip)

    local gridInfoTitle = gridInfoButton:CreateFontString(nil, "OVERLAY")

    gridInfoTitle:SetFontObject(AUFont15)
    gridInfoTitle:SetText(string.format("|cff%sGrid2|r", LUP.gs.visual.colorStrings.white))
    gridInfoTitle:SetPoint("LEFT", gridInfoButton, "RIGHT", 2, -1)

    -- Cell nickname info
    local cellInfoTooltip = "To show nicknames on Cell frames:|n|n" ..
    "- Open Cell settings|n" ..
    "- General > Nickname > Custom Nicknames|n" ..
    "- Check \"Custom Nicknames\" (top left)"

    local cellInfoButton = CreateFrame("Button", nil, LUP.settingsWindow)

    cellInfoButton:SetSize(15, 15)
    cellInfoButton:SetPoint("LEFT", gridInfoTitle, "RIGHT", 8, 1)
    cellInfoButton:SetHighlightTexture("Interface\\AddOns\\AuraUpdater\\Media\\Textures\\Help-i-highlight.tga", "ADD")
    cellInfoButton:SetMouseMotionEnabled(true)

    cellInfoButton.tex = cellInfoButton:CreateTexture()
    cellInfoButton.tex:SetAllPoints(cellInfoButton)
    cellInfoButton.tex:SetTexture("Interface\\AddOns\\AuraUpdater\\Media\\Textures\\Help-i.tga")

    LUP:AddTooltip(cellInfoButton, cellInfoTooltip)

    local cellInfoTitle = cellInfoButton:CreateFontString(nil, "OVERLAY")

    cellInfoTitle:SetFontObject(AUFont15)
    cellInfoTitle:SetText(string.format("|cff%sCell|r", LUP.gs.visual.colorStrings.white))
    cellInfoTitle:SetPoint("LEFT", cellInfoButton, "RIGHT", 2, -1)
end