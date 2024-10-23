---@diagnostic disable: undefined-field
local _, LUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

function LUP:InitializeWeakAurasImporter()
    if not LiquidUpdaterSaved.WeakAuras then LiquidUpdaterSaved.WeakAuras = {} end

    for _, auraData in ipairs(LUP.WeakAuras) do
        local displayName = auraData.displayName
        local version = auraData.version
        local importedVersion = LiquidUpdaterSaved.WeakAuras[displayName] and LiquidUpdaterSaved.WeakAuras[displayName].d and LiquidUpdaterSaved.WeakAuras[displayName].d.liquidVersion

        if not importedVersion or importedVersion < version then
            local toDecode = auraData.data:match("!WA:2!(.+)")

            if toDecode then
                local decoded = LibDeflate:DecodeForPrint(toDecode)

                if decoded then
                    local decompressed = LibDeflate:DecompressDeflate(decoded)

                    if decompressed then
                        local success, data = LibSerialize:Deserialize(decompressed)

                        data.d.liquidVersion = version
                        data.d.url = nil
                        data.d.wagoID = nil
                        data.d.preferToUpdate = true
                        
                        if data.c then
                            for _, childData in pairs(data.c) do
                                childData.url = nil
                                childData.wagoID = nil
                            end
                        end

                        if success then
                            LiquidUpdaterSaved.WeakAuras[displayName] = data
                        else
                            LUP:ErrorPrint(string.format("could not deserialize aura data for [%s]", displayName))
                        end
                    else
                        LUP:ErrorPrint(string.format("could not decompress aura data for [%s]", displayName))
                    end
                else
                    LUP:ErrorPrint(string.format("could not decode aura data for [%s]", displayName))
                end
            else
                LUP:ErrorPrint(string.format("aura data for [%s] does not start with a valid prefix", displayName))
            end
        end
    end
end