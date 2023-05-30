local _, ISC = ...
local P = ISC.pixelPerfectFuncs

local currentInstanceName, currentInstanceID
local LoadInstances, LoadEnemies, LoadDebuffs, LoadCasts, Export
local RegisterEvents, UnregisterEvents

local collectorFrame = CreateFrame("Frame", "InstanceSpellCollectorFrame", UIParent, "BackdropTemplate")
collectorFrame:Hide()

collectorFrame:SetSize(825, 419)
collectorFrame:SetPoint("CENTER")
collectorFrame:SetFrameStrata("HIGH")
collectorFrame:SetMovable(true)
collectorFrame:SetUserPlaced(true)
collectorFrame:SetClampedToScreen(true)
collectorFrame:SetIgnoreParentScale(true)
tinsert(UISpecialFrames, "InstanceSpellCollectorFrame")

collectorFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
collectorFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
collectorFrame:SetBackdropBorderColor(0, 0, 0, 1)

collectorFrame:EnableMouse(true)
collectorFrame:RegisterForDrag("LeftButton")
collectorFrame:SetScript("OnDragStart", function()
    collectorFrame:StartMoving()
end)
collectorFrame:SetScript("OnDragStop", function()
    collectorFrame:StopMovingOrSizing()
    P:PixelPerfectPoint(collectorFrame)
end)


local init
collectorFrame:SetScript("OnShow", function()
    if not init then
        init = true
        LoadInstances()
    end
    P:PixelPerfectPoint(collectorFrame)
end)
-- collectorFrame:SetScript("OnHide", function()
--     ISCTooltip:Hide()
-- end)

-- title
local title = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_TITLE")
title:SetPoint("TOP", 0, -3)
title:SetText("Instance Spell Collector")
title:SetTextColor(1, 0.19, 0.19)

local instanceIDText = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
instanceIDText:SetPoint("TOPLEFT", 5, -25)

local instanceNameText = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
instanceNameText:SetPoint("LEFT", instanceIDText, "RIGHT", 10, 0)

local statusText = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
statusText:SetPoint("LEFT", instanceNameText, "RIGHT", 10, 0)

-- close
local closeBtn = ISC:CreateButton(collectorFrame, "", "red", {20, 20})
closeBtn:SetTexture("Interface/AddOns/!InstanceSpellCollector/close.tga", {15, 15}, {"CENTER", 0, 0})
closeBtn:SetPoint("TOPRIGHT")
closeBtn:SetScript("OnClick", function()
    collectorFrame:Hide()
end)

-- reset
local resetBtn = ISC:CreateButton(collectorFrame, "Reset", "magenta", {50, 20})
resetBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", 1, 0)
resetBtn:RegisterForClicks("MiddleButtonUp")
resetBtn:SetScript("OnClick", function()
    if IsControlKeyDown() then
        ISC_Config = nil
        ISC_Data = nil
        ReloadUI()
    end
end)

resetBtn:HookScript("OnEnter", function()
    ISCTooltip:SetOwner(resetBtn, "ANCHOR_NONE")
    ISCTooltip:SetPoint("BOTTOMRIGHT", resetBtn, "TOPRIGHT", 0, 1)
    ISCTooltip:AddLine("Ctrl + Middle-Click to reset & reload")
    ISCTooltip:Show()
end)
resetBtn:HookScript("OnLeave", function()
    ISCTooltip:Hide()
end)

-- scale slider
local scaleSlider = ISC:CreateSlider("", collectorFrame, 0.5, 3, 50, 0.25, nil, function(value)
    ISC_Config.scale = value
    ISC:Fire("UpdateScale")
end)
scaleSlider:SetPoint("TOPRIGHT", resetBtn, "TOPLEFT", -5, -5)
scaleSlider.currentEditBox:Hide()
scaleSlider.lowText:Hide()
scaleSlider.highText:Hide()

ISC:RegisterCallback("AddonLoaded", "Collector_AddonLoaded", function()
    scaleSlider:SetValue(ISC_Config.scale)
end)

-- add & track
local addBtn = ISC:CreateButton(collectorFrame, "Add Current Instance", "red", {175, 20})
addBtn:SetPoint("TOPLEFT", 5, -45)
addBtn:SetScript("OnClick", function()
    if currentInstanceName and currentInstanceID then
        if not ISC_Data["instances"][currentInstanceID] then
            ISC_Data["instances"][currentInstanceID] = {["name"]=currentInstanceName, ["enabled"]=true}
            ISC_Data["debuffs"][currentInstanceID] = {}
            ISC_Data["casts"][currentInstanceID] = {}
            LoadInstances()
            collectorFrame:PLAYER_ENTERING_WORLD()
        end
    end
end)

-- tips
local tips = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
tips:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
tips:SetText("[Right-Click] track/untrack, [Ctrl-Click] delete")

-------------------------------------------------
-- instance list
-------------------------------------------------
local instanceListFrame = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
ISC:StylizeFrame(instanceListFrame)
instanceListFrame:SetPoint("TOPLEFT", addBtn, "BOTTOMLEFT", 0, -5)
instanceListFrame:SetPoint("BOTTOMRIGHT", collectorFrame, "BOTTOMLEFT", 205, 5)

ISC:CreateScrollFrame(instanceListFrame)
local currentInstanceHighlight = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
currentInstanceHighlight:SetFrameLevel(10)
ISC:StylizeFrame(currentInstanceHighlight, {0,0,0,0}, {0.2, 1, 0.2})

local sotredInstances = {}
local instanceButtons = {}
local selectedInstance
LoadInstances = function()
    wipe(sotredInstances)
    wipe(instanceButtons)
    instanceListFrame.scrollFrame:Reset()

    for id in pairs(ISC_Data["instances"]) do
        tinsert(sotredInstances, id)
    end
    table.sort(sotredInstances)

    local last
    for _, id in pairs(sotredInstances) do
        local b = ISC:CreateButton(instanceListFrame.scrollFrame.content, id.." "..ISC_Data["instances"][id]["name"], "red-hover", {20, 20}, true)
        tinsert(instanceButtons, b)

        b:GetFontString():ClearAllPoints()
        b:GetFontString():SetPoint("LEFT", 5, 0)
        b:GetFontString():SetPoint("RIGHT", -5, 0)
        b:GetFontString():SetJustifyH("LEFT")

        if not ISC_Data["instances"][id]["enabled"] then
            b:GetFontString():SetTextColor(0.4, 0.4, 0.4, 1)
        end

        if last then
            b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
        else
            b:SetPoint("TOPLEFT", 1, -1)
        end
        b:SetPoint("RIGHT", -1, 0)

        last = b

        b:RegisterForClicks("AnyUp")
        b:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                currentInstanceHighlight:Hide()
                currentInstanceHighlight:ClearAllPoints()
                if IsControlKeyDown() then -- delete
                    if id == currentInstanceID then
                        statusText:SetText("")
                        collectorFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                        if ISC_Data["instances"][id]["enabled"] then print("|cffff7700STOP TRACKING SPELLS!") end
                    end
                    ISC_Data["instances"][id] = nil
                    ISC_Data["debuffs"][id] = nil
                    ISC_Data["casts"][id] = nil
                    LoadInstances()
                    if selectedInstance == id then
                        LoadEnemies()
                    end
                else -- show enemies
                    selectedInstance = id
                    currentInstanceHighlight:Show()
                    currentInstanceHighlight:SetAllPoints(b)
                    currentInstanceHighlight:SetParent(b)
                    LoadEnemies(ISC_Data["debuffs"][id], ISC_Data["casts"][id])
                end
                LoadDebuffs()
                LoadCasts()
                Export()
            elseif button == "RightButton" then -- track/untrack
                ISC_Data["instances"][id]["enabled"] = not ISC_Data["instances"][id]["enabled"]
                if ISC_Data["instances"][id]["enabled"] then
                    b:GetFontString():SetTextColor(1, 1, 1, 1)
                else
                    b:GetFontString():SetTextColor(0.4, 0.4, 0.4, 1)
                end

                if id == currentInstanceID then
                    if ISC_Data["instances"][id]["enabled"] then
                        statusText:SetText("|cff55ff55TRACKING")
                        print("|cff77ff00START TRACKING SPELLS!")
                        RegisterEvents()
                    else
                        statusText:SetText("")
                        print("|cffff7700STOP TRACKING SPELLS!")
                        UnregisterEvents()
                    end
                end
            end
        end)
    end

    instanceListFrame.scrollFrame:SetContentHeight(20, #instanceButtons, -1)
end

-------------------------------------------------
-- enemy list
-------------------------------------------------
local enemyListFrame = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
ISC:StylizeFrame(enemyListFrame)
enemyListFrame:SetPoint("TOPLEFT", instanceListFrame, "TOPRIGHT", 5, 0)
enemyListFrame:SetPoint("BOTTOMRIGHT", instanceListFrame, "BOTTOMRIGHT", 205, 0)

ISC:CreateScrollFrame(enemyListFrame)
local currentEnemyHighlight = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
currentEnemyHighlight:SetFrameLevel(10)
ISC:StylizeFrame(currentEnemyHighlight, {0,0,0,0}, {0.2, 1, 0.2})

local sortedEnemies = {}
local enemyButtons = {}
LoadEnemies = function(debuffs, casts)
    wipe(enemyButtons)
    wipe(sortedEnemies)
    enemyListFrame.scrollFrame:Reset()
    currentEnemyHighlight:Hide()
    currentEnemyHighlight:ClearAllPoints()

    if not (debuffs and casts) then return end

    -- sort
    local enemies = {}
    for k in pairs(debuffs) do
        enemies[k] = true
    end
    for k in pairs(casts) do
        enemies[k] = true
    end
    for k in pairs(enemies) do
        tinsert(sortedEnemies, k)
    end
    table.sort(sortedEnemies, function(a, b)
        if strfind(a, "|cff") and not strfind(b, "|cff") then
            return true
        elseif not strfind(a, "|cff") and strfind(b, "|cff") then
            return false
        elseif strfind(a, "*") and not strfind(b, "*") then
            return false
        elseif not strfind(a, "*") and strfind(b, "*") then
            return true
        else
            return a < b
        end
    end)

    local last
    for _, enemy in ipairs(sortedEnemies) do
        local b = ISC:CreateButton(enemyListFrame.scrollFrame.content, enemy, "red-hover", {20, 20}, true)
        tinsert(enemyButtons, b)

        b:GetFontString():ClearAllPoints()
        b:GetFontString():SetPoint("LEFT", 5, 0)
        b:GetFontString():SetPoint("RIGHT", -5, 0)
        b:GetFontString():SetJustifyH("LEFT")

        if last then
            b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
        else
            b:SetPoint("TOPLEFT", 1, -1)
        end
        b:SetPoint("RIGHT", -1, 0)

        last = b

        b:RegisterForClicks("AnyUp")
        b:SetScript("OnClick", function(self, button)
            if IsControlKeyDown() then
                currentEnemyHighlight:Hide()
                currentEnemyHighlight:ClearAllPoints()
                debuffs[enemy] = nil
                LoadEnemies(debuffs, casts)
                LoadDebuffs()
                LoadCasts()
            else
                currentEnemyHighlight:Show()
                currentEnemyHighlight:SetAllPoints(b)
                currentEnemyHighlight:SetParent(b)
                LoadDebuffs(debuffs[enemy])
                LoadCasts(casts[enemy])
            end
            Export(debuffs[enemy], casts[enemy])
        end)
    end

    enemyListFrame.scrollFrame:SetContentHeight(20, #enemyButtons, -1)
end

-------------------------------------------------
-- debuff list
-------------------------------------------------
local debuffListFrame = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
ISC:StylizeFrame(debuffListFrame)
debuffListFrame:SetPoint("TOPLEFT", enemyListFrame, "TOPRIGHT", 5, 0)
debuffListFrame:SetPoint("BOTTOMRIGHT", enemyListFrame, "BOTTOMRIGHT", 205, 0)

ISC:CreateScrollFrame(debuffListFrame)
local currentDebuffHighlight = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
currentDebuffHighlight:SetFrameLevel(10)
ISC:StylizeFrame(currentDebuffHighlight, {0,0,0,0}, {0.2, 1, 0.2})

local sortedDebuffs = {}
local debuffButtons = {}
LoadDebuffs = function(debuffs)
    wipe(debuffButtons)
    wipe(sortedDebuffs)
    debuffListFrame.scrollFrame:Reset()
    currentDebuffHighlight:Hide()
    currentDebuffHighlight:ClearAllPoints()
    ISCTooltip:Hide()

    if not debuffs then return end

    for id in pairs(debuffs) do
        tinsert(sortedDebuffs, id)
    end
    table.sort(sortedDebuffs)

    local last
    for _, id in ipairs(sortedDebuffs) do
        local icon = select(3, GetSpellInfo(id))
        local b = ISC:CreateButton(debuffListFrame.scrollFrame.content, "|T"..icon..":16:16:0:0:16:16|t "..id.." "..debuffs[id], "red-hover", {20, 20}, true)
        tinsert(debuffButtons, b)

        b:GetFontString():ClearAllPoints()
        b:GetFontString():SetPoint("LEFT", 5, 0)
        b:GetFontString():SetPoint("RIGHT", -5, 0)
        b:GetFontString():SetJustifyH("LEFT")

        if last then
            b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
        else
            b:SetPoint("TOPLEFT", 1, -1)
        end
        b:SetPoint("RIGHT", -1, 0)

        last = b

        b:RegisterForClicks("AnyUp")
        b:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                currentDebuffHighlight:Hide()
                currentDebuffHighlight:ClearAllPoints()
                if IsControlKeyDown() then
                    debuffs[id] = nil
                    LoadDebuffs(debuffs)
                else
                    currentDebuffHighlight:Show()
                    currentDebuffHighlight:SetAllPoints(b)
                    currentDebuffHighlight:SetParent(b)
                    Export(id..", -- "..debuffs[id])
                end
            end
        end)

        -- tooltip
        b:HookScript("OnEnter", function()
            ISCTooltip:SetOwner(collectorFrame, "ANCHOR_NONE")
            ISCTooltip:SetPoint("TOPLEFT", b, "TOPRIGHT", 1, 0)
            ISCTooltip:SetSpellByID(id)
            ISCTooltip:Show()
        end)

        b:HookScript("OnLeave", function()
            ISCTooltip:Hide()
        end)
    end

    debuffListFrame.scrollFrame:SetContentHeight(20, #debuffButtons, -1)
end

-------------------------------------------------
-- cast list
-------------------------------------------------
local castListFrame = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
ISC:StylizeFrame(castListFrame)
castListFrame:SetPoint("TOPLEFT", debuffListFrame, "TOPRIGHT", 5, 0)
castListFrame:SetPoint("BOTTOMRIGHT", debuffListFrame, "BOTTOMRIGHT", 205, 0)

ISC:CreateScrollFrame(castListFrame)
local currentCastHighlight = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
currentCastHighlight:SetFrameLevel(10)
ISC:StylizeFrame(currentCastHighlight, {0,0,0,0}, {0.2, 1, 0.2})

local sortedCasts = {}
local castButtons = {}
LoadCasts = function(casts)
    wipe(sortedCasts)
    wipe(castButtons)
    castListFrame.scrollFrame:Reset()
    currentCastHighlight:Hide()
    currentCastHighlight:ClearAllPoints()
    ISCTooltip:Hide()

    if not casts then return end

    for id in pairs(casts) do
        tinsert(sortedCasts, id)
    end
    table.sort(sortedCasts)

    local last
    for _, id in ipairs(sortedCasts) do
        local icon = select(3, GetSpellInfo(id))
        local b = ISC:CreateButton(castListFrame.scrollFrame.content, "|T"..icon..":16:16:0:0:16:16|t "..id.." "..casts[id], "red-hover", {20, 20}, true)
        tinsert(castButtons, b)

        b:GetFontString():ClearAllPoints()
        b:GetFontString():SetPoint("LEFT", 5, 0)
        b:GetFontString():SetPoint("RIGHT", -5, 0)
        b:GetFontString():SetJustifyH("LEFT")

        if last then
            b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
        else
            b:SetPoint("TOPLEFT", 1, -1)
        end
        b:SetPoint("RIGHT", -1, 0)

        last = b

        b:RegisterForClicks("AnyUp")
        b:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                currentCastHighlight:Hide()
                currentCastHighlight:ClearAllPoints()
                if IsControlKeyDown() then
                    casts[id] = nil
                    LoadCasts(casts)
                else
                    currentCastHighlight:Show()
                    currentCastHighlight:SetAllPoints(b)
                    currentCastHighlight:SetParent(b)
                    Export(id..", -- "..casts[id])
                end
            end
        end)

        -- tooltip
        b:HookScript("OnEnter", function()
            ISCTooltip:SetOwner(collectorFrame, "ANCHOR_NONE")
            ISCTooltip:SetPoint("TOPLEFT", b, "TOPRIGHT", 1, 0)
            ISCTooltip:SetSpellByID(id)
            ISCTooltip:Show()
        end)

        b:HookScript("OnLeave", function()
            ISCTooltip:Hide()
        end)
    end

    castListFrame.scrollFrame:SetContentHeight(20, #castButtons, -1)
end

-------------------------------------------------
-- export
-------------------------------------------------
local exportFrame = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
ISC:StylizeFrame(exportFrame)
exportFrame:SetPoint("TOPLEFT", castListFrame, "TOPRIGHT", 10, 0)
exportFrame:SetPoint("BOTTOMRIGHT", castListFrame, "BOTTOMRIGHT", 220, 0)
exportFrame:Hide()

local exportFrameEditBox = ISC:CreateScrollEditBox(exportFrame)
exportFrameEditBox:SetPoint("TOPLEFT", 5, -5)
exportFrameEditBox:SetPoint("BOTTOMRIGHT", -5, 5)

exportFrame:SetScript("OnHide", function()
    exportFrame:Hide()
end)

local exportFrameCloseBtn = ISC:CreateButton(exportFrame, "", "red", {20, 20})
exportFrameCloseBtn:SetTexture("Interface/AddOns/!InstanceSpellCollector/close.tga", {15, 15}, {"CENTER", 0, 0})
exportFrameCloseBtn:SetPoint("BOTTOMRIGHT", exportFrame, "TOPRIGHT", 0, -1)
exportFrameCloseBtn:SetScript("OnClick", function()
    exportFrame:Hide()
end)

local function ToString(data1, data2)
    local sorted = {}
    local result

    if data1 then
        for id in pairs(data1) do
            tinsert(sorted, id)
        end
        table.sort(sorted)

        result = "-- debuffs\n"
        for _, id in ipairs(sorted) do
            result = result..id..", -- "..data1[id].."\n"
        end
    end

    if data2 then
        wipe(sorted)
        for id in pairs(data2) do
            tinsert(sorted, id)
        end
        table.sort(sorted)

        if result then
            result = result .. "\n-- casts\n"
        else
            result = "-- casts\n"
        end

        for _, id in ipairs(sorted) do
            result = result..id..", -- "..data2[id].."\n"
        end
    end

    return result
end

Export = function(data1, data2)
    if data1 then
        exportFrame:Show()
    else
        exportFrame:Hide()
        return
    end

    if type(data1) == "string" then
        exportFrameEditBox:SetText(data1)
    else
        exportFrameEditBox:SetText(ToString(data1, data2))
    end

    C_Timer.After(0.1, function()
        exportFrameEditBox.scrollFrame:SetVerticalScroll(0)
    end)
end

-------------------------------------------------
-- tips
-------------------------------------------------
local instanceTip = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
instanceTip:SetPoint("TOPLEFT", instanceListFrame, "BOTTOMLEFT", 0, -7)
instanceTip:SetText("[instanceID instanceName]")
instanceTip:SetTextColor(0.77, 0.77, 0.77)

local enemyTip = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
enemyTip:SetPoint("TOPLEFT", enemyListFrame, "BOTTOMLEFT", 0, -7)
enemyTip:SetText("[encounterID enemyName]")
enemyTip:SetTextColor(0.77, 0.77, 0.77)

local debuffTip = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
debuffTip:SetPoint("TOPLEFT", debuffListFrame, "BOTTOMLEFT", 0, -7)
debuffTip:SetText("Debuffs: [spellID spellName]")
debuffTip:SetTextColor(0.77, 0.77, 0.77)

local castTip = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
castTip:SetPoint("TOPLEFT", castListFrame, "BOTTOMLEFT", 0, -7)
castTip:SetText("Casts: [spellID spellName]")
castTip:SetTextColor(0.77, 0.77, 0.77)

-------------------------------------------------
-- functions
-------------------------------------------------
-- https://wowpedia.fandom.com/wiki/UnitFlag
local OBJECT_AFFILIATION_MINE = 0x00000001
local OBJECT_AFFILIATION_PARTY = 0x00000002
local OBJECT_AFFILIATION_RAID = 0x00000004
local OBJECT_REACTION_HOSTILE = 0x00000040
local OBJECT_REACTION_NEUTRAL = 0x00000020

local function IsFriend(unitFlags)
    if not unitFlags then return false end
    return (bit.band(unitFlags, OBJECT_AFFILIATION_MINE) ~= 0) or (bit.band(unitFlags, OBJECT_AFFILIATION_RAID) ~= 0) or (bit.band(unitFlags, OBJECT_AFFILIATION_PARTY) ~= 0)
end

local function IsEnemy(unitFlags)
    if not unitFlags then return false end
    return (bit.band(unitFlags, OBJECT_REACTION_HOSTILE) ~= 0) or (bit.band(unitFlags, OBJECT_REACTION_NEUTRAL) ~= 0)
end

-------------------------------------------------
-- event
-------------------------------------------------
collectorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

RegisterEvents = function()
    collectorFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    collectorFrame:RegisterEvent("ENCOUNTER_START")
    collectorFrame:RegisterEvent("ENCOUNTER_END")
    collectorFrame:RegisterEvent("UNIT_SPELLCAST_START")
    collectorFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
end

UnregisterEvents = function()
    collectorFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    collectorFrame:UnregisterEvent("ENCOUNTER_START")
    collectorFrame:UnregisterEvent("ENCOUNTER_END")
    collectorFrame:UnregisterEvent("UNIT_SPELLCAST_START")
    collectorFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
end

function collectorFrame:PLAYER_ENTERING_WORLD()
    if IsInInstance() then
        local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
        instanceIDText:SetText("ID: |cffff5500"..instanceID)
        instanceNameText:SetText("Name: |cffff5500"..name)
        currentInstanceName, currentInstanceID = name, instanceID
        if ISC_Data["instances"][currentInstanceID] and ISC_Data["instances"][currentInstanceID]["enabled"] then
            statusText:SetText("|cff55ff55TRACKING")
            print("|cff77ff00START TRACKING SPELLS!")
            RegisterEvents()
        else
            statusText:SetText("")
            UnregisterEvents()
        end
    else
        currentInstanceName, currentInstanceID = nil, nil
        instanceNameText:SetText("Name:")
        instanceIDText:SetText("ID:")
        statusText:SetText("")
        UnregisterEvents()
    end
end

local currentEncounterID, currentEncounterName = "* ", nil
function collectorFrame:ENCOUNTER_START(encounterID, encounterName)
    currentEncounterID = encounterID.." "
    currentEncounterName = encounterName
end

function collectorFrame:ENCOUNTER_END()
    currentEncounterID = "* "
    currentEncounterName = nil
end

local function Save(index, sourceName, spellId, spellName)
    -- save enemy-spell
    sourceName = currentEncounterID..sourceName
    if type(ISC_Data[index][currentInstanceID][sourceName]) ~= "table" then
        ISC_Data[index][currentInstanceID][sourceName] = {}
    end
    ISC_Data[index][currentInstanceID][sourceName][spellId] = spellName

    if currentEncounterID and currentEncounterName then
        -- save encounter-spell
        local currentEncounter = "|cff27ffff"..currentEncounterID..currentEncounterName
        if type(ISC_Data[index][currentInstanceID][currentEncounter]) ~= "table" then
            ISC_Data[index][currentInstanceID][currentEncounter] = {}
        end
        ISC_Data[index][currentInstanceID][currentEncounter][spellId] = spellName
    else
        -- save mobs-spell
        local mobs = "|cff27ffff* MOBS"
        if type(ISC_Data[index][currentInstanceID][mobs]) ~= "table" then
            ISC_Data[index][currentInstanceID][mobs] = {}
        end
        ISC_Data[index][currentInstanceID][mobs][spellId] = spellName
    end
end

--! CASTS
function collectorFrame:UNIT_SPELLCAST_START(unit, _, spellId)
    if not (currentInstanceName and currentInstanceID and spellId) then return end
    if not UnitIsEnemy("player", unit) then return end
    -- if not (UnitIsEnemy("player", unit) and UnitIsFriend("player", unit.."target")) then return end
    
    local sourceName = UnitName(unit)
    if not sourceName then return end

    Save("casts", sourceName, spellId, GetSpellInfo(spellId))
end

function collectorFrame:UNIT_SPELLCAST_CHANNEL_START(unit, _, spellId)
    collectorFrame:UNIT_SPELLCAST_START(unit, _, spellId)
end

--! DEBUFFS
function collectorFrame:COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount = ...
    if event ~= "SPELL_AURA_APPLIED" or auraType ~= "DEBUFF" then return end

    if not (currentInstanceName and currentInstanceID and spellId) then return end

    -- !NOTE: some debuffs are SELF-APPLIED but caster == nil
    if (IsEnemy(sourceFlags) or (sourceFlags == 1297 and not sourceName)) and IsFriend(destFlags) then
        if not sourceName then sourceName = "UNKNOWN" end
        Save("debuffs", sourceName, spellId, spellName)
    end
end

collectorFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:COMBAT_LOG_EVENT_UNFILTERED(CombatLogGetCurrentEventInfo())
    else
        self[event](self, ...)
    end
end)