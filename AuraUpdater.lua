local _, LUP = ...

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local eventFrame = CreateFrame("Frame")

-- If LiquidUpdater is loaded (the old version of this addon, prior to the name change), prompt the user to disable it
local function ShowLiquidUpdaterPopup()
    if C_AddOns.IsAddOnLoaded("LiquidUpdater") then
        LUP:ShowPopupWindow(
                "LiquidUpdater is active, and interferes with AuraUpdater.|n|nPlease disable it.",
                function()
                    C_AddOns.DisableAddOn("LiquidUpdater")

                    C_UI.Reload()
                end,
                0,
                150,
                false,
                "Disable and reload"
            )
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            local addOnName = ...

            if addOnName == "AuraUpdater" then
                if not LiquidUpdaterSaved then LiquidUpdaterSaved = {} end
                if not LiquidUpdaterSaved.minimap then LiquidUpdaterSaved.minimap = {} end
                if not LiquidUpdaterSaved.settings then LiquidUpdaterSaved.settings = {} end
                if not LiquidUpdaterSaved.settings.frames then LiquidUpdaterSaved.settings.frames = {} end
                if not LiquidUpdaterSaved.nicknames then LiquidUpdaterSaved.nicknames = {} end
                if LiquidUpdaterSaved.settings.readyCheckPopup == nil then LiquidUpdaterSaved.settings.readyCheckPopup = true end
                if LiquidUpdaterSaved.settings.disableBigWigsAssignments == nil then LiquidUpdaterSaved.settings.disableBigWigsAssignments = true end

                -- Minimap icon
                LUP.LDB = LDB:NewDataObject(
                    "Aura Updater",
                    {
                        type = "data source",
                        text = "Aura Updater",
                        icon = [[Interface\Addons\AuraUpdater\Media\Textures\minimap_logo.tga]],
                        OnClick = function() LUP.window:SetShown(not LUP.window:IsShown()) end
                    }
                )

                LDBIcon:Register("Aura Updater", LUP.LDB, LiquidUpdaterSaved.minimap)

                LUP:UpdateMinimapIconVisibility()

                LUP:InitializeNicknames()
                LUP:InitializeBigWigsDisabler()
                LUP:InitializeWeakAurasImporter()
                LUP:InitializeInterface()
                LUP:InitializeAuraUpdater()
                LUP:InitializeAuraChecker()
                LUP:InitializeOtherChecker()

                ShowLiquidUpdaterPopup()
            end
        end
    end
)

SLASH_AURAUPDATER1 = "/lu"
SLASH_AURAUPDATER2 = "/auraupdate"
SLASH_AURAUPDATER3 = "/auraupdater"
SLASH_AURAUPDATER4 = "/au"

function SlashCmdList.AURAUPDATER()
    LUP.window:SetShown(not LUP.window:IsShown())
end