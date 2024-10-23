local _, LUP = ...

function LUP:CreateAuraImportElement(parent)
    -- Outer frame
    local frame = CreateFrame("Frame", nil, parent)

    frame.height = 40

    frame:SetHeight(frame.height)

    -- Icon
    frame.icon = CreateFrame("Frame", nil, frame)

    frame.icon:SetSize(24, 24)
    frame.icon:Hide()
    frame.icon:SetPoint("LEFT", frame, "LEFT", 8, 0)

    frame.icon.tex = frame.icon:CreateTexture(nil, "BACKGROUND")
    frame.icon.tex:SetAllPoints(frame.icon)
    frame.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Display name
    frame.displayName = frame:CreateFontString(nil, "OVERLAY")

    frame.displayName:SetFont(LUP.gs.visual.font, 17, LUP.gs.visual.fontFlags)
    frame.displayName:SetPoint("LEFT", frame, "LEFT", 8, 0)
    
    function frame:SetDisplayName(displayName)
        frame.displayName:SetText(string.format("|cff%s%s|r", LUP.gs.visual.colorStrings.white, displayName))

        local auraData = LiquidUpdaterSaved.WeakAuras[displayName]

        frame.importButton:SetScript(
            "OnClick",
            function()
                WeakAuras.Import(auraData)
            end
        )

        local icon = auraData.d.groupIcon

        if icon then
            frame.icon.tex:SetTexture(icon)
        end

        frame.icon:SetShown(icon)
        frame.displayName:SetPoint("LEFT", frame, "LEFT", icon and 38 or 8, 0)
    end

    -- Version count
    frame.versionCount = frame:CreateFontString(nil, "OVERLAY")

    frame.versionCount:SetFont(LUP.gs.visual.font, 17, LUP.gs.visual.fontFlags)
    frame.versionCount:SetPoint("CENTER", frame, "CENTER")
    
    function frame:SetVersionsBehind(count)
        frame.versionCount:SetText(string.format("|cff%s%d version(s)|r", LUP.gs.visual.colorStrings.red, count))
    end

    -- Import button
    frame.importButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")

    frame.importButton:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    frame.importButton:SetText("Update")
    frame.importButton:GetFontString():SetFont(LUP.gs.visual.font, 13)

    C_Timer.After(0, function() frame.importButton:SetSize(frame.importButton:GetTextWidth() + 20, 32) end)

    -- Requires addon update text
    frame.requiresUpdateText = frame:CreateFontString(nil, "OVERLAY")

    frame.requiresUpdateText:SetFont(LUP.gs.visual.font, 17, LUP.gs.visual.fontFlags)
    frame.requiresUpdateText:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    frame.requiresUpdateText:SetText(string.format("|cff%sUpdate addon!|r", LUP.gs.visual.colorStrings.red))
    frame.requiresUpdateText:Hide()

    LUP:AddTooltip(frame.requiresUpdateText, "A newer version of this aura is available. Update the addon to receive it.")

    -- Border
    LUP:AddBorder(frame)

    local borderColor = LUP.gs.visual.borderColor

    frame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    function frame:SetRequiresAddOnUpdate(requiresUpdate)
        frame.importButton:SetShown(not requiresUpdate)
        frame.requiresUpdateText:SetShown(requiresUpdate)
    end

    return frame
end