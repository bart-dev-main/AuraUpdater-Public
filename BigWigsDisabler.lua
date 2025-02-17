local _, LUP = ...

local moduleSettingsTable = {}

-- Disables certain settings in a BigWigs boss module that clash with WeakAuras assignments
-- Tries to be as safe as possible with it, by making sure the options actually exist and are the same type
local function DisableBigWigsSettings(module)
    local moduleName = module.moduleName
    local optionsToDisable = moduleSettingsTable[moduleName]

    if not optionsToDisable then return end
    
    for optionKey, optionValue in pairs(optionsToDisable) do
        local optionExists = module.db.profile[optionKey] ~= nil
        local optionMatchesType = type(module.db.profile[optionKey]) == type(optionValue)

        if optionExists and optionMatchesType then
            if type(optionValue) == "boolean" then -- Turning it off completely
                module.db.profile[optionKey] = optionValue
            elseif type(optionValue) == "number" then -- Turning off suboptions
                module.db.profile[optionKey] = bit.band(
                    module.db.profile[optionKey],
                    optionValue
                )
            end
        end
    end
end

function LUP:RegisterBigWigsDisabler()
    if not BigWigsLoader then return end

    BigWigsLoader.RegisterMessage(
        "AuraUpdaterDisabler",
        "BigWigs_OnBossEngage",
        function(_, module)
            if not module then return end
            if not module.moduleName then return end
            if not module.db then return end
            if not module.db.profile then return end

            DisableBigWigsSettings(module)
        end
    )
end

function LUP:UnregisterBigWigsDisabler()
    if not BigWigsLoader then return end

    BigWigsLoader.UnregisterMessage("AuraUpdaterDisabler", "BigWigs_OnBossEngage")
end

function LUP:InitializeBigWigsDisabler()
    if not BigWigs then return end

    moduleSettingsTable = {
        ["Broodtwister Ovi'nax"] = {
            ["custom_on_experimental_dosage_marks"] = false, -- Experimental dosage assignments
            ["custom_off_442526"] = false, -- Experimental Dosage marking
            ["custom_off_-28999"] = false, -- Voracious Worm marking
        },
        ["Queen Ansurek"] = {
            ["custom_on_437592"] = false, -- Reactive Toxin assignments
            [437592] = bit.bnot(bit.bor(BigWigs.C.SAY, BigWigs.C.COUNTDOWN)) -- Reactive Toxin say/countdown
        },
    }
end

-- Wait for BigWigs_Core to load before initialization, because we want to reference the C.SAY/C.COUNTDOWN values
local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

f:SetScript(
    "OnEvent",
    function(_, _, addOnName)
        if addOnName == "BigWigs_Core" then
            LUP:InitializeBigWigsDisabler()
        end
    end
)