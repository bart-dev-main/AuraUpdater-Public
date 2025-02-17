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

    frame.displayName:SetFontObject(AUFont17)
    frame.displayName:SetPoint("LEFT", frame, "LEFT", 8, 0)

    function frame:SetDisplayName(displayName)
        frame.displayName:SetText(string.format("|cff%s%s|r", LUP.gs.visual.colorStrings.white, displayName))

        -- If this element shows an addon update instead of an aura update, don't add an update button script
        -- Icon is also hardcoded, rather than taken from aura data (there is no aura)
        if displayName == "AuraUpdater" then
            frame.icon.tex:SetTexture("Interface\\Addons\\AuraUpdater\\Media\\Textures\\Bart.tga")
            frame.icon:Show()
            frame.displayName:SetPoint("LEFT", frame, "LEFT", 38, 0)
        else
            local auraData = LiquidUpdaterSaved.WeakAuras[displayName]

            frame.importButton:SetScript(
                "OnClick",
                function()
                    -- This should only be necessary if the user manually imported a version of the aura with a different UID, after logging in
                    -- Do it anyway just to be sure
                    LUP:MatchInstalledUID(auraData.d)

                    -- Apply existing "load: never" settings to the aura data before importing
                    local modifiedAuraData = CopyTable(auraData)

                    LUP:ApplyLoadSettings(modifiedAuraData.d)

                    if modifiedAuraData.c then
                        for _, childAuraData in pairs(modifiedAuraData.c) do
                            LUP:ApplyLoadSettings(childAuraData)
                        end
                    end

                    WeakAuras.Import(
                        modifiedAuraData,
                        nil,
                        function(success, id)
                            if not success then return end

                            local data = WeakAuras.GetData(id)
                            local version = LiquidUpdaterSaved.WeakAuras[displayName].d.liquidVersion

                            data.liquidVersion = version

                            LUP:OnUpdateAura()
                        end
                    )
                end
            )

            local icon = auraData.d.groupIcon

            if icon then
                frame.icon.tex:SetTexture(icon)
            end

            frame.icon:SetShown(icon)
            frame.displayName:SetPoint("LEFT", frame, "LEFT", icon and 38 or 8, 0)
        end
    end

    -- Version count
    frame.versionCount = frame:CreateFontString(nil, "OVERLAY")

    frame.versionCount:SetFontObject(AUFont17)
    frame.versionCount:SetPoint("CENTER", frame, "CENTER")
    
    function frame:SetVersionsBehind(count)
        frame.versionCount:SetText(string.format("|cff%s%d version(s)|r", LUP.gs.visual.colorStrings.red, count))
    end

    -- Import button
    frame.importButton = LUP:CreateButton(frame, "Update", function() end)

    frame.importButton :SetNormalFontObject(AUFont15)
    frame.importButton :SetHighlightFontObject(AUFont15)
    frame.importButton :SetDisabledFontObject(AUFont15)

    frame.importButton:SetPoint("RIGHT", frame, "RIGHT", -8, 0)

    -- Requires addon update text
    frame.requiresUpdateText = frame:CreateFontString(nil, "OVERLAY")

    frame.requiresUpdateText:SetFontObject(AUFont17)
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