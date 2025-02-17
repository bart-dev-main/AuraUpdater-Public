---@diagnostic disable: undefined-field
local _, LUP = ...

local CustomNames
local Grid2NicknameStatus

local presetNicknames = {
    ["Algo#2565"] = "Algo",
    ["Azortharion#2528"] = "Azor",
    ["Naemesis#2526"] = "Bart",
    ["Cavollir#2410"] = "Cav",
    ["Chaos#26157"] = "Chaos",
    ["c1nder#21466"] = "Cinder",
    ["khebul#2314"] = "Crt",
    ["Sors#2676"] = "Nick",
    ["EffyxWoW#2713"] = "Effy",
    ["Freddynqkken#2913"] = "Freddy",
    ["Jhonz#2356"] = "Jon",
    ["Kantom#2289"] = "Mini",
    ["Mytheos#1649"] = "Mytheos",
    ["Nightwanta#2473"] = "Night",
    ["Saunderz#2405"] = "Olly",
    ["Ottojj#2715"] = "Otto",
    ["Prebby#2112"] = "Prebby",
    ["Rose#22507"] = "Rose",
    ["Ryler#1217"] = "Ryler",
    ["Drarrven#2327"] = "Soul",
    ["Tonikor#2964"] = "Toni",
    ["Wrexad#21129"] = "Wrexa",
    ["Tínie#2208"] = "Tinie",
    ["jackazzem#2214"] = "Georg"
}

function LUP:GetPresetNickname()
    local _, battleTag = BNGetInfo()
    
    return battleTag and presetNicknames[battleTag]
end

local function RealmIncludedName(unit)
    local name, realm = UnitNameUnmodified(unit)

    if not realm then
        realm = GetNormalizedRealmName()
    end

    if not realm then return end -- Called before PLAYER_LOGIN

    return string.format("%s-%s", name, realm)
end

function LUP:UpdateNicknameForUnit(unit, nickname)
    local realmIncludedName = RealmIncludedName(unit)

    if not realmIncludedName then return end

    local oldNickname = LiquidUpdaterSaved.nicknames[realmIncludedName]

    nickname = nickname and strtrim(nickname)

    if nickname == "" then nickname = nil end

    LiquidUpdaterSaved.nicknames[realmIncludedName] = nickname

    if CustomNames then
        CustomNames:Set(unit, nickname)
    end

    -- If we are using Grid2, update the nickname on the character's unit frame
    if Grid2NicknameStatus then
        for groupUnit in LUP:IterateGroupMembers() do
            if UnitIsUnit(unit, groupUnit) then
                Grid2NicknameStatus:UpdateIndicators(groupUnit)

                break
            end
        end
    end

    -- If we are using Cell, update the nickname for this unit
    if Cell and CellDB and CellDB.nicknames then
        local oldEntry = oldNickname and string.format("%s:%s", realmIncludedName, oldNickname)
        local newEntry = nickname and string.format("%s:%s", realmIncludedName, nickname)

        local cellIndex -- Index in CellDB.nicknames.list of name:oldNickname (if any)

        if oldEntry then
            cellIndex = tIndexOf(CellDB.nicknames.list, oldEntry)
        end

        if cellIndex then -- Update existing nickname entry
            if newEntry then
                CellDB.nicknames.list[cellIndex] = newEntry
            else
                table.remove(CellDB.nicknames.list, cellIndex)
            end
        else -- Create new nickname entry
            table.insert(CellDB.nicknames.list, newEntry)
        end

        Cell:Fire("UpdateNicknames", "list-update", realmIncludedName, nickname)
    end
end

function AuraUpdater:GetNickname(unit)
    if not unit then return end
    if not UnitExists(unit) then return end
    if not UnitIsPlayer(unit) then return end

    local realmIncludedName = RealmIncludedName(unit)
    local nickname = LiquidUpdaterSaved.nicknames[realmIncludedName or ""]

    if not nickname then
        nickname = UnitNameUnmodified(unit)
    end

    local formatString = "%s"
    local classFileName = UnitClassBase(unit)

    if classFileName then
        formatString = string.format("|c%s%%s|r", RAID_CLASS_COLORS[classFileName].colorStr)
    end

    return nickname, formatString
end

-- Adds a status to Grid2 that displays nicknames for units
-- Can be found under Miscellaneous -> AuraUpdater Nickname
local function AddGrid2Status()
    local statusName = "AuraUpdater Nickname"

    Grid2NicknameStatus = Grid2.statusPrototype:new(statusName)
    Grid2NicknameStatus.IsActive = Grid2.statusLibrary.IsActive

    function Grid2NicknameStatus:UNIT_NAME_UPDATE(_, unit)
        self:UpdateIndicators(unit)
    end

    function Grid2NicknameStatus:OnEnable()
        self:RegisterEvent("UNIT_NAME_UPDATE")
    end

    function Grid2NicknameStatus:OnDisable()
        self:UnregisterEvent("UNIT_NAME_UPDATE")
    end

    function Grid2NicknameStatus:GetText(unit)
        return AuraUpdater:GetNickname(unit) or ""
    end

    local function Create(baseKey, dbx)
        Grid2:RegisterStatus(Grid2NicknameStatus, {"text"}, baseKey, dbx)

        return Grid2NicknameStatus
    end

    Grid2.setupFunc[statusName] = Create

    Grid2:DbSetStatusDefaultValue(statusName, {type = statusName})
end

local function AddGrid2Options()
    if Grid2NicknameStatus then
        Grid2Options:RegisterStatusOptions("AuraUpdater Nickname", "misc", function() end)
    end
end

local function UpdateCellNicknames()
    if not CellDB then return end
    if not CellDB.nicknames then return end

    -- Insert nicknames
    for name, nickname in pairs(LiquidUpdaterSaved.nicknames) do
        local cellFormat = string.format("%s:%s", name, nickname)

        -- Insert nickname if it doesn't already exist, and refresh unit frame if necessary
        if tInsertUnique(CellDB.nicknames.list, cellFormat) then
            Cell:Fire("UpdateNicknames", "list-update", name, nickname)
        end
    end
end

-- Add a nickname tag to ElvUI
-- Use "nickname-lenX" for shortened names
local function AddElvTag()
    if ElvUF and ElvUF.Tags then
        ElvUF.Tags.Events["nickname"] = "UNIT_NAME_UPDATE"
        ElvUF.Tags.Methods["nickname"] = function(unit)
            return AuraUpdater:GetNickname(unit) or ""
        end

        for i = 1, 12 do
            ElvUF.Tags.Events["nickname-len" .. i] = "UNIT_NAME_UPDATE"
            ElvUF.Tags.Methods["nickname-len" .. i] = function(unit)
                local nickname = AuraUpdater:GetNickname(unit)

                return nickname and nickname:sub(1, i) or ""
            end
        end
    end
end

-- Overrides WeakAuras' GetName(etc.) functions
-- This should only be done if CustomNames addon is not loaded, since that override them too, and has priority
local function OverrideWeakAurasFunctions()
    if WeakAuras.GetName then
        WeakAuras.GetName = function(name)
            if not name then return end

            return AuraUpdater:GetNickname(name) or name
        end
    end

    if WeakAuras.UnitName then
        WeakAuras.UnitName = function(unit)
            if not unit then return end

            local name, realm = UnitName(unit)

            if not name then return end

            return AuraUpdater:GetNickname(unit) or name, realm
        end
    end

    if WeakAuras.GetUnitName then
        WeakAuras.GetUnitName = function(unit, showServerName)
            if not unit then return end

            if not UnitIsPlayer(unit) then
                return GetUnitName(unit)
            end

            local name = UnitNameUnmodified(unit)
            local nameRealm = GetUnitName(unit, showServerName)
            local suffix = nameRealm:match(".+(%s%(%*%))") or nameRealm:match(".+(%-.+)") or ""

            return string.format("%s%s", AuraUpdater:GetNickname(unit) or name, suffix)
        end
    end

    if WeakAuras.UnitFullName then
        WeakAuras.UnitFullName = function(unit)
            if not unit then return end

            local name, realm = UnitFullName(unit)

            if not name then return end

            return AuraUpdater:GetNickname(unit) or name, realm
        end
    end
end

function LUP:InitializeNicknames()
    CustomNames = C_AddOns.IsAddOnLoaded("CustomNames") and LibStub("CustomNames")

    -- WeakAuras functions
    if WeakAuras and not CustomNames and not LiquidAPI then
        OverrideWeakAurasFunctions()
    end

    -- Grid2 status
    if C_AddOns.IsAddOnLoaded("Grid2") then
        AddGrid2Status()
    end
    
    -- Elv tag
    if C_AddOns.IsAddOnLoaded("ElvUI") then
        AddElvTag()
    end

    -- Cell
    if C_AddOns.IsAddOnLoaded("Cell") then
        UpdateCellNicknames()
    end

    -- MRT
    if C_AddOns.IsAddOnLoaded("MRT") and GMRT and GMRT.F then
        GMRT.F:RegisterCallback(
            "RaidCooldowns_Bar_TextName",
            function(_, _, gsubData)
                if gsubData and gsubData.name then
                    gsubData.name = AuraUpdater:GetNickname(gsubData.name) or gsubData.name
                end
            end
        )
    end
end

-- When Grid2Options loads, add an empty set of options for AuraUpdater Nicknames
-- If this is not done, viewing the status throws a Lua error
local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

f:SetScript(
    "OnEvent",
    function(_, _, addOnName)
        if addOnName == "Grid2Options" then
            AddGrid2Options()
        end
    end
)