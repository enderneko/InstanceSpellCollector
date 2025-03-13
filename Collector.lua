local _, ISC = ...
local P = ISC.pixelPerfectFuncs

local C_TooltipInfo_GetUnitDebuff = C_TooltipInfo and C_TooltipInfo.GetUnitDebuff
local UnitIsFriend = UnitIsFriend
local UnitInPartyIsAI = UnitInPartyIsAI or function() end
local UnitPlayerControlled = UnitPlayerControlled
local UnitName = UnitName
local UnitGUID = UnitGUID
local IsInInstance = IsInInstance
local UnitIsPlayer = UnitIsPlayer
local UnitPlayerOrPetInRaid = UnitPlayerOrPetInRaid
local UnitPlayerOrPetInParty = UnitPlayerOrPetInParty
local GetSpellDescription = GetSpellDescription
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local CombatLog_Object_IsA = CombatLog_Object_IsA
local COMBATLOG_FILTER_HOSTILE_UNITS = COMBATLOG_FILTER_HOSTILE_UNITS

local GetTheSpellInfo
if C_Spell and C_Spell.GetSpellInfo then
    GetTheSpellInfo = function(spellId)
        local info = C_Spell.GetSpellInfo(spellId)
        return info.name, info.iconID or 134400, info.castTime
    end
else
    GetTheSpellInfo = function(spellId)
        local name, _, icon, castTime = GetSpellInfo(spellId)
        return name, icon or 134400, castTime
    end
end

local AI_FOLLOWERS = {}

---------------------------------------------------------------------
-- debuff type color
---------------------------------------------------------------------
local DebuffTypeColor = {
    -- ["Bleed"] = {1, 0.2, 0.6},
    ["Disease"] = {0.6, 0.4, 0},
    ["Poison"] = {0, 0.6, 0},
    ["Curse"] = {0.6, 0, 1},
    ["Magic"] = {0.2, 0.6, 1},
}

---------------------------------------------------------------------
-- InstanceSpellCollectorFrame
---------------------------------------------------------------------
local currentInstanceName, currentInstanceID
local currentEncounterID, currentEncounterName = "* ", nil
local AddCurrentInstance, LoadInstances, LoadEnemies, LoadAuras, LoadCasts, Export, NpcsToString, AurasToString, CastsToString
local RegisterEvents, UnregisterEvents

local collectorFrame = CreateFrame("Frame", "InstanceSpellCollectorFrame", UIParent, "BackdropTemplate")
collectorFrame:Hide()

collectorFrame:SetSize(825, 419)
collectorFrame:SetPoint("CENTER")
collectorFrame:SetFrameStrata("HIGH")
collectorFrame:SetMovable(true)
collectorFrame:SetUserPlaced(true)
collectorFrame:SetClampedToScreen(true)
collectorFrame:SetClampRectInsets(500, -500, 0, 300)
collectorFrame:SetIgnoreParentScale(true)
-- tinsert(UISpecialFrames, "InstanceSpellCollectorFrame")

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

-- title
local title = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_TITLE")
title:SetPoint("TOP", 0, -3)
title:SetText("Instance Spell Collector")
title:SetTextColor(1, 0.19, 0.19)

local init
collectorFrame:SetScript("OnShow", function()
    if not init then
        init = true
        LoadInstances()
    end
    P:PixelPerfectPoint(collectorFrame)
    title:SetText("Instance Spell Collector " .. ISC.version)
end)
-- collectorFrame:SetScript("OnHide", function()
--     ISCTooltip:Hide()
-- end)

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
local addBtn = ISC:CreateButton(collectorFrame, "Add Current Instance", "red", {200, 20})
addBtn:SetPoint("TOPLEFT", 5, -45)
addBtn:SetScript("OnClick", function()
    if currentInstanceName and currentInstanceID then
        if not ISC_Data[currentInstanceID] then
            AddCurrentInstance()
        end
    end
end)

-- tips
local tips = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
tips:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
tips:SetText("[Right-Click] track/untrack, [Ctrl-Click] delete")

-------------------------------------------------
-- list button
-------------------------------------------------
local function CreateListButton(parent)
    local b = ISC:CreateButton(parent, " ", "red-hover", {20, 20}, true)
    b:RegisterForClicks("AnyUp")
    b:GetFontString():ClearAllPoints()
    b:GetFontString():SetPoint("LEFT", 5, 0)
    b:GetFontString():SetPoint("RIGHT", -5, 0)
    b:GetFontString():SetJustifyH("LEFT")
    return b
end

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
ISC:StylizeFrame(currentInstanceHighlight, {0, 0, 0, 0}, {0.2, 1, 0.2})

local sotredInstances = {}
local instanceButtons = {}
local selectedInstance
LoadInstances = function(scroll)
    wipe(sotredInstances)
    instanceListFrame.scrollFrame:Reset()

    for id in pairs(ISC_Data) do
        tinsert(sotredInstances, id)
    end
    table.sort(sotredInstances)

    local last
    for i, id in pairs(sotredInstances) do
        if not instanceButtons[i] then
            instanceButtons[i] = CreateListButton(instanceListFrame.scrollFrame.content)
        else
            instanceButtons[i]:ClearAllPoints()
            instanceButtons[i]:SetParent(instanceListFrame.scrollFrame.content)
            instanceButtons[i]:Show()
        end

        local b = instanceButtons[i]

        if ISC_Data[id]["enabled"] then
            b:GetFontString():SetTextColor(1, 1, 1)
        else
            b:GetFontString():SetTextColor(0.4, 0.4, 0.4)
        end

        b:SetText(id .. " " .. ISC_Data[id]["name"])

        if last then
            b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
        else
            b:SetPoint("TOPLEFT", 1, -1)
        end
        b:SetPoint("RIGHT", -1, 0)
        last = b

        b:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                currentInstanceHighlight:Hide()
                currentInstanceHighlight:ClearAllPoints()
                if IsControlKeyDown() then -- delete
                    if id == currentInstanceID then
                        statusText:SetText("")
                        UnregisterEvents()
                        if ISC_Data[id]["enabled"] then print("|cffff7700STOP TRACKING SPELLS!") end
                    end
                    ISC_Data[id] = nil
                    LoadInstances(instanceListFrame.scrollFrame:GetVerticalScroll())
                    if selectedInstance == id then
                        LoadEnemies()
                    end
                else -- show enemies
                    selectedInstance = id
                    currentInstanceHighlight:Show()
                    currentInstanceHighlight:SetAllPoints(b)
                    currentInstanceHighlight:SetParent(b)
                    LoadEnemies(ISC_Data[id]["data"])
                end
                LoadAuras()
                LoadCasts()
                Export()
            elseif button == "RightButton" then -- track/untrack
                ISC_Data[id]["enabled"] = not ISC_Data[id]["enabled"]
                if ISC_Data[id]["enabled"] then
                    b:GetFontString():SetTextColor(1, 1, 1, 1)
                else
                    b:GetFontString():SetTextColor(0.4, 0.4, 0.4, 1)
                end

                if id == currentInstanceID then
                    if ISC_Data[id]["enabled"] then
                        statusText:SetText("|cff55ff55TRACKING")
                        print("|cff77ff00[ISC] START TRACKING!")
                        RegisterEvents()
                    else
                        statusText:SetText("")
                        print("|cffff7700[ISC] STOP TRACKING!")
                        UnregisterEvents()
                    end
                end
            end
        end)
    end

    instanceListFrame.scrollFrame:SetContentHeight(20, #sotredInstances, -1)
    instanceListFrame.scrollFrame:VerticalScroll(scroll or 0)
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
ISC:StylizeFrame(currentEnemyHighlight, {0, 0, 0, 0}, {0.2, 1, 0.2})

local sortedEnemies = {}
local enemyButtons = {}
LoadEnemies = function(data, scorll)
    wipe(sortedEnemies)
    enemyListFrame.scrollFrame:Reset()
    currentEnemyHighlight:Hide()
    currentEnemyHighlight:ClearAllPoints()

    if not data then return end

    -- sort
    local enemies = {}
    for k in pairs(data) do
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
    for i, enemy in ipairs(sortedEnemies) do
        if not enemyButtons[i] then
            enemyButtons[i] = CreateListButton(enemyListFrame.scrollFrame.content)

            -- tooltip
            enemyButtons[i]:HookScript("OnEnter", function()
                if enemyButtons[i].npcId then
                    ISCTooltip:SetOwner(collectorFrame, "ANCHOR_NONE")
                    ISCTooltip:SetPoint("TOPLEFT", enemyButtons[i], "TOPRIGHT", 1, 0)
                    ISCTooltip:AddLine("npcID: " .. "|cffffffff" .. enemyButtons[i].npcId)
                    ISCTooltip:Show()
                end
            end)

            enemyButtons[i]:HookScript("OnLeave", function()
                ISCTooltip:Hide()
            end)
        else
            enemyButtons[i]:ClearAllPoints()
            enemyButtons[i]:SetParent(enemyListFrame.scrollFrame.content)
            enemyButtons[i]:Show()
        end

        local b = enemyButtons[i]
        b.enemy = enemy
        b.npcId = data[enemy]["npcId"]

        b:SetText(enemy)

        if last then
            b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
        else
            b:SetPoint("TOPLEFT", 1, -1)
        end
        b:SetPoint("RIGHT", -1, 0)
        last = b

        b:SetScript("OnClick", function(self, button)
            if IsControlKeyDown() then
                currentEnemyHighlight:Hide()
                currentEnemyHighlight:ClearAllPoints()
                data[enemy] = nil
                LoadEnemies(data, enemyListFrame.scrollFrame:GetVerticalScroll())
                LoadAuras()
                LoadCasts()
            else
                currentEnemyHighlight:Show()
                currentEnemyHighlight:SetAllPoints(b)
                currentEnemyHighlight:SetParent(b)
                LoadAuras(data[enemy]["auras"])
                LoadCasts(data[enemy]["casts"])

                if data[enemy]["encounterId"] then
                    Export("eName: " .. data[enemy]["encounterName"], "eId: " .. data[enemy]["encounterId"] .. "\n", NpcsToString(data[enemy]["npcs"]), AurasToString(data[enemy]["auras"]), CastsToString(data[enemy]["casts"]))
                elseif data[enemy]["npcId"] then
                    Export("npcName: " .. data[enemy]["npcName"], "npcID: " .. data[enemy]["npcId"] .. "\n", AurasToString(data[enemy]["auras"]), CastsToString(data[enemy]["casts"]))
                else -- UNKNOWN / MOBS
                    Export(enemy .. "\n", AurasToString(data[enemy]["auras"]), CastsToString(data[enemy]["casts"]))
                end
            end
        end)
    end

    enemyListFrame.scrollFrame:SetContentHeight(20, #sortedEnemies, -1)
    enemyListFrame.scrollFrame:VerticalScroll(scroll or 0)
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
ISC:StylizeFrame(currentDebuffHighlight, {0, 0, 0, 0}, {0.2, 1, 0.2})

local sortedDebuffs = {}
local debuffButtons = {}
LoadAuras = function(auras, scroll)
    wipe(sortedDebuffs)
    debuffListFrame.scrollFrame:Reset()
    currentDebuffHighlight:Hide()
    currentDebuffHighlight:ClearAllPoints()
    ISCTooltip:Hide()

    if not auras then return end

    for id in pairs(auras) do
        tinsert(sortedDebuffs, id)
    end
    table.sort(sortedDebuffs, function(a, b)
        if ISC_Spell[a] and not ISC_Spell[b] then
            return true
        end
        if not ISC_Spell[a] and ISC_Spell[b] then
            return false
        end
        if ISC_Spell[a]["auraType"] ~= ISC_Spell[b]["auraType"] then
            return ISC_Spell[a]["auraType"] == "buff"
        end
        -- if ISC_Spell[a]["auraDispelType"] ~= ISC_Spell[b]["auraDispelType"] then
        --     if ISC_Spell[a]["auraDispelType"] and ISC_Spell[b]["auraDispelType"] then
        --         return ISC_Spell[a]["auraDispelType"] < ISC_Spell[b]["auraDispelType"]
        --     end
        -- end
        return a < b
    end)

    local last
    for i, id in ipairs(sortedDebuffs) do
        if not debuffButtons[i] then
            debuffButtons[i] = CreateListButton(debuffListFrame.scrollFrame.content)

            -- tooltip
            debuffButtons[i]:HookScript("OnEnter", function()
                ISCTooltip:SetOwner(collectorFrame, "ANCHOR_NONE")
                ISCTooltip:SetPoint("TOPLEFT", debuffButtons[i], "TOPRIGHT", 1, 0)
                ISCTooltip:SetSpellByID(debuffButtons[i].id)
                ISCTooltip:SetExtraTip(debuffButtons[i].auraDesc)
                ISCTooltip:Show()
            end)

            debuffButtons[i]:HookScript("OnLeave", function()
                ISCTooltip:Hide()
            end)
        else
            debuffButtons[i]:ClearAllPoints()
            debuffButtons[i]:SetParent(debuffListFrame.scrollFrame.content)
            debuffButtons[i]:Show()
        end

        if ISC_Spell[id] and ISC_Spell[id]["icon"] and ISC_Spell[id]["name"] then
            local b = debuffButtons[i]
            b.id = id
            b.auraDesc = ISC_Spell[id]["auraDesc"]

            if ISC_Spell[id]["auraType"] == "debuff" and ISC_Spell[id]["auraDispelType"] and DebuffTypeColor[ISC_Spell[id]["auraDispelType"]] then
                -- b:GetFontString():SetTextColor(unpack(DebuffTypeColor[ISC_Spell[id]["auraType"]]))
                b:SetText("|T" .. ISC_Spell[id]["icon"] .. ":16:16:0:0:16:16|t " .. id .. (ISC_Spell[id]["auraStackable"] and "+ " or " ") ..
                    "|TInterface\\AddOns\\!InstanceSpellCollector\\Media\\" .. ISC_Spell[id]["auraDispelType"] .. ":0|t" .. ISC_Spell[id]["name"])
            else
                -- b:GetFontString():SetTextColor(1, 1, 1)
                b:SetText("|T" .. ISC_Spell[id]["icon"] .. ":16:16:0:0:16:16|t " .. id .. (ISC_Spell[id]["auraStackable"] and "+ " or " ") .. ISC_Spell[id]["name"])
            end

            if ISC_Spell[id]["auraType"] == "buff" then
                b:GetFontString():SetTextColor(0.7, 1, 0.7)
            else
                b:GetFontString():SetTextColor(1, 1, 1)
            end

            if last then
                b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
            else
                b:SetPoint("TOPLEFT", 1, -1)
            end
            b:SetPoint("RIGHT", -1, 0)
            last = b

            b:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    currentDebuffHighlight:Hide()
                    currentDebuffHighlight:ClearAllPoints()
                    if IsControlKeyDown() then
                        auras[id] = nil
                        LoadAuras(auras, debuffListFrame.scrollFrame:GetVerticalScroll())
                    else
                        currentDebuffHighlight:Show()
                        currentDebuffHighlight:SetAllPoints(b)
                        currentDebuffHighlight:SetParent(b)

                        local str = id .. ", -- " .. ISC_Spell[id]["name"]

                        local info = ""

                        if ISC_Spell[id]["auraType"] then
                            info = info .. "\ntype: " .. ISC_Spell[id]["auraType"]
                        end

                        if ISC_Spell[id]["auraDispelType"] and ISC_Spell[id]["auraDispelType"] ~= "" then
                            info = info .. "\ndispelType: " .. ISC_Spell[id]["auraDispelType"]
                        end

                        if ISC_Spell[id]["auraDuration"] then
                            info = info .. "\nduration: " .. ISC_Spell[id]["auraDuration"]
                        end

                        if ISC_Spell[id]["auraStackable"] then
                            info = info .. "\nstackable: true"
                        end

                        if info ~= "" then
                            str = str .. "\n" .. info
                        end

                        if type(ISC_Spell[id]["sources"]) == "table" then
                            local source = "\n\nsource:"
                            for id, name in pairs(ISC_Spell[id]["sources"]) do
                                source = source .. "\n" .. tostring(id) .. " " .. tostring(name)
                            end
                            if source ~= "\n\nsource:" then
                                str = str .. source
                            end
                        end

                        if ISC_Spell[id]["desc"] and ISC_Spell[id]["desc"] ~= "" then
                            str = str .. "\n\ndescription:\n" .. ISC_Spell[id]["desc"]
                        end

                        if ISC_Spell[id]["auraDesc"] and ISC_Spell[id]["auraDesc"] ~= "" then
                            str = str .. "\n\naura description:\n" .. ISC_Spell[id]["auraDesc"]
                        end

                        Export(str)
                    end
                end
            end)
        end
    end

    debuffListFrame.scrollFrame:SetContentHeight(20, #sortedDebuffs, -1)
    debuffListFrame.scrollFrame:VerticalScroll(scroll or 0)
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
ISC:StylizeFrame(currentCastHighlight, {0, 0, 0, 0}, {0.2, 1, 0.2})

local sortedCasts = {}
local castButtons = {}
local castOrder = {
    ["cast"] = 1,
    ["channel"] = 2,
    ["instant"] = 3,
}
LoadCasts = function(casts, scorll)
    wipe(sortedCasts)
    castListFrame.scrollFrame:Reset()
    currentCastHighlight:Hide()
    currentCastHighlight:ClearAllPoints()
    ISCTooltip:Hide()

    if not casts then return end

    for id in pairs(casts) do
        tinsert(sortedCasts, id)
    end
    table.sort(sortedCasts, function(a, b)
        if ISC_Spell[a] and not ISC_Spell[b] then
            return true
        end
        if not ISC_Spell[a] and ISC_Spell[b] then
            return false
        end
        if ISC_Spell[a]["castType"] ~= ISC_Spell[b]["castType"] then
            if ISC_Spell[a]["castType"] and ISC_Spell[a]["castType"] then
                return castOrder[ISC_Spell[a]["castType"]] < castOrder[ISC_Spell[b]["castType"]]
            end
        end
        return a < b
    end)

    local last
    for i, id in ipairs(sortedCasts) do
        if not castButtons[i] then
            castButtons[i] = CreateListButton(castListFrame.scrollFrame.content)

            -- tooltip
            castButtons[i]:HookScript("OnEnter", function()
                ISCTooltip:SetOwner(collectorFrame, "ANCHOR_NONE")
                ISCTooltip:SetPoint("TOPLEFT", castButtons[i], "TOPRIGHT", 1, 0)
                ISCTooltip:SetSpellByID(castButtons[i].id)
                ISCTooltip:Show()
            end)

            castButtons[i]:HookScript("OnLeave", function()
                ISCTooltip:Hide()
            end)
        else
            castButtons[i]:ClearAllPoints()
            castButtons[i]:SetParent(castListFrame.scrollFrame.content)
            castButtons[i]:Show()
        end

        if ISC_Spell[id] and ISC_Spell[id]["icon"] and ISC_Spell[id]["name"] then
            local b = castButtons[i]
            b.id = id

            b:SetText("|T" .. ISC_Spell[id]["icon"] .. ":16:16:0:0:16:16|t " .. id .. " " .. ISC_Spell[id]["name"])

            if ISC_Spell[id]["castType"] == "channel" then
                b:GetFontString():SetTextColor(1, 1, 0.5)
            elseif ISC_Spell[id]["castType"] == "instant" then
                b:GetFontString():SetTextColor(0.5, 0.5, 0.5)
            else
                b:GetFontString():SetTextColor(1, 1, 1)
            end

            if last then
                b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 1)
            else
                b:SetPoint("TOPLEFT", 1, -1)
            end
            b:SetPoint("RIGHT", -1, 0)
            last = b

            b:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    currentCastHighlight:Hide()
                    currentCastHighlight:ClearAllPoints()
                    if IsControlKeyDown() then
                        casts[id] = nil
                        LoadCasts(casts, castListFrame.scrollFrame:GetVerticalScroll())
                    else
                        currentCastHighlight:Show()
                        currentCastHighlight:SetAllPoints(b)
                        currentCastHighlight:SetParent(b)

                        local str = id .. ", -- " .. ISC_Spell[id]["name"]

                        str = str .. "\n\n" .. "castType: " .. ISC_Spell[id]["castType"]

                        if ISC_Spell[id]["castTime"] then
                            str = str .. "\n" .. "castTime: " .. (ISC_Spell[id]["castTime"] / 1000)
                        end

                        if type(ISC_Spell[id]["sources"]) == "table" then
                            local source = "\n\nsource:"
                            for id, name in pairs(ISC_Spell[id]["sources"]) do
                                source = source .. "\n" .. tostring(id) .. " " .. tostring(name)
                            end
                            if source ~= "\n\nsource:" then
                                str = str .. source
                            end
                        end

                        if ISC_Spell[id]["desc"] and ISC_Spell[id]["desc"] ~= "" then
                            str = str .. "\n\n" .. "description:\n" .. ISC_Spell[id]["desc"]
                        end

                        Export(str)
                    end
                end
            end)
        end
    end

    castListFrame.scrollFrame:SetContentHeight(20, #sortedCasts, -1)
    castListFrame.scrollFrame:VerticalScroll(scroll or 0)
end

-------------------------------------------------
-- export
-------------------------------------------------
local exportFrame = CreateFrame("Frame", nil, collectorFrame, "BackdropTemplate")
ISC:StylizeFrame(exportFrame)
exportFrame:SetPoint("TOPLEFT", castListFrame, "TOPRIGHT", 10, 0)
exportFrame:SetPoint("BOTTOMRIGHT", castListFrame, "BOTTOMRIGHT", 270, 0)
exportFrame:Hide()

local exportFrameEditBox = ISC:CreateScrollEditBox(exportFrame)
exportFrameEditBox:SetPoint("TOPLEFT", 5, -5)
exportFrameEditBox:SetPoint("BOTTOMRIGHT", -5, 5)
exportFrameEditBox.eb:SetSpacing(2)

exportFrame:SetScript("OnHide", function()
    exportFrame:Hide()
end)

local exportFrameCloseBtn = ISC:CreateButton(exportFrame, "", "red", {20, 20})
exportFrameCloseBtn:SetTexture("Interface/AddOns/!InstanceSpellCollector/close.tga", {15, 15}, {"CENTER", 0, 0})
exportFrameCloseBtn:SetPoint("BOTTOMRIGHT", exportFrame, "TOPRIGHT", 0, -1)
exportFrameCloseBtn:SetScript("OnClick", function()
    exportFrame:Hide()
end)

NpcsToString = function(data)
    local result = "-- npcs\n"

    if data then
        local sorted = {}
        for id in pairs(data) do
            tinsert(sorted, id)
        end
        table.sort(sorted)

        for _, id in ipairs(sorted) do
            result = result .. id .. "-- " .. data[id] .. "\n"
        end
    end

    return result
end

AurasToString = function(data)
    local result = ""

    if data then
        local sorted = {}
        for id in pairs(data) do
            tinsert(sorted, id)
        end
        table.sort(sorted)

        local buffs = {}
        local debuffs = {}

        for _, id in ipairs(sorted) do
            if ISC_Spell[id] then
                if ISC_Spell[id]["auraType"] == "buff" then
                    tinsert(buffs, id .. ", -- " .. ISC_Spell[id]["name"])
                else
                    tinsert(debuffs, id .. ", -- " .. ISC_Spell[id]["name"])
                end
            else
                tinsert(debuffs, id .. ", -- " .. (GetTheSpellInfo(id) or "INVALID"))
            end
        end

        if #buffs ~= 0 then
            result = result .. "-- buffs\n"
            for _, buff in pairs(buffs) do
                result = result .. buff .. "\n"
            end
        end

        if #debuffs ~= 0 then
            if result ~= "" then result = result .. "\n" end
            result = result .. "-- debuffs\n"
            for _, debuff in pairs(debuffs) do
                result = result .. debuff .. "\n"
            end
        end
    end

    return result
end

CastsToString = function(data)
    local result = ""

    if data then
        local sorted = {}
        for id in pairs(data) do
            tinsert(sorted, id)
        end
        table.sort(sorted)

        local casts = {}
        local channels = {}
        local instants = {}

        for _, id in ipairs(sorted) do
            if ISC_Spell[id] then
                if ISC_Spell[id]["castType"] == "instant" then
                    tinsert(instants, id .. ", -- " .. ISC_Spell[id]["name"])
                elseif ISC_Spell[id]["castType"] == "channel" then
                    tinsert(channels, id .. ", -- " .. ISC_Spell[id]["name"])
                else
                    tinsert(casts, id .. ", -- " .. ISC_Spell[id]["name"])
                end
            else
                tinsert(casts, id .. ", -- " .. (GetTheSpellInfo(id) or "INVALID"))
            end
        end

        if #casts ~= 0 then
            result = result .. "-- casts\n"
            for _, cast in pairs(casts) do
                result = result .. cast .. "\n"
            end
        end

        if #channels ~= 0 then
            if result ~= "" then result = result .. "\n" end
            result = result .. "-- channels\n"
            for _, channel in pairs(channels) do
                result = result .. channel .. "\n"
            end
        end

        if #instants ~= 0 then
            if result ~= "" then result = result .. "\n" end
            result = result .. "-- instants\n"
            for _, instant in pairs(instants) do
                result = result .. instant .. "\n"
            end
        end
    end

    return result
end

Export = function(...)
    local n = select("#", ...)
    if n == 0 then
        exportFrame:Hide()
        return
    end

    exportFrame:Show()

    local result = ""

    for i = 1, n do
        local data = select(i, ...)
        if data ~= "" then
            result = result .. data .. "\n"
        end
    end

    exportFrameEditBox:SetText(result)

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

local auraTip = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
auraTip:SetPoint("TOPLEFT", debuffListFrame, "BOTTOMLEFT", 0, -7)
auraTip:SetText("Auras: [spellID spellName]")
auraTip:SetTextColor(0.77, 0.77, 0.77)

local castTip = collectorFrame:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
castTip:SetPoint("TOPLEFT", castListFrame, "BOTTOMLEFT", 0, -7)
castTip:SetText("Casts: [spellID spellName]")
castTip:SetTextColor(0.77, 0.77, 0.77)

-------------------------------------------------
-- dialog
-------------------------------------------------
local dialogTip = "Enable |cFFFF3030ISC|r for current instance?"

local dialog = CreateFrame("Frame", "InstanceSpellCollectorDialog", UIParent, "BackdropTemplate")
P:Size(dialog, 320, 120)
dialog:SetPoint("BOTTOM", UIParent, "CENTER")
dialog:SetFrameStrata("FULLSCREEN_DIALOG")
dialog:EnableMouse(true)
dialog:SetIgnoreParentScale(true)
dialog:Hide()

dialog:SetScript("OnShow", function()
    P:PixelPerfectPoint(dialog)
end)

local dialogText = dialog:CreateFontString(nil, "OVERLAY", "ISC_FONT_TITLE")
dialogText:SetPoint("TOP", 0, -10)
dialogText:SetPoint("LEFT", 10, 0)
dialogText:SetPoint("RIGHT", -10, 0)
dialogText:SetSpacing(5)
dialogText:SetText(dialogTip)

local yesBtn = ISC:CreateButton(dialog, "Yes", "green", {100, 20})
P:Point(yesBtn, "BOTTOMLEFT", 5, 5)
yesBtn:SetScript("OnClick", function()
    AddCurrentInstance()
    dialog:Hide()
end)

local noBtn = ISC:CreateButton(dialog, "No", "red", {100, 20})
P:Point(noBtn, "BOTTOMLEFT", yesBtn, "BOTTOMRIGHT", 5, 0)
noBtn:SetScript("OnClick", function()
    dialog:Hide()
end)

local neverBtn = ISC:CreateButton(dialog, "Never", "red", {100, 20})
P:Point(neverBtn, "BOTTOMLEFT", noBtn, "BOTTOMRIGHT", 5, 0)
neverBtn:SetScript("OnClick", function()
    ISC_Ignore[currentInstanceID] = currentInstanceName
    dialog:Hide()
end)

function dialog:UpdatePixelPerfect()
    dialog:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = P:Scale(1)})
    dialog:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    dialog:SetBackdropBorderColor(0, 0, 0, 1)

    dialog:SetSize(P:Scale(100) * 3 + P:Scale(5) * 4, 120)
    yesBtn:UpdatePixelPerfect()
    noBtn:UpdatePixelPerfect()
    neverBtn:UpdatePixelPerfect()
end

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

AddCurrentInstance = function()
    ISC_Data[currentInstanceID] = {
        ["name"] = currentInstanceName,
        ["enabled"] = true,
        ["data"] = {},
    }
    ISC_Ignore[currentInstanceID] = nil
    LoadInstances()
    collectorFrame:PLAYER_ENTERING_WORLD()
end

local queue = {}

local function GetAuraIndex(unit, id)
    local index = 1
    local auraIndex
    AuraUtil.ForEachAura(unit, "HARMFUL", nil, function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId)
        if spellId == id then
            auraIndex = index
        end
        index = index + 1
    end)
    return auraIndex
end

local function GetAuraDesc(unit, id)
    local index = GetAuraIndex(unit, id)
    if index then
        local data = C_TooltipInfo_GetUnitDebuff(unit, index)
        queue[data.dataInstanceID] = {unit, id}
        if data["lines"] and data["lines"][2] then
            -- print("GET", id, data["lines"][2]["leftText"])
            return data["lines"][2]["leftText"]
        end
    end
end

local function SaveData(index, sourceGUID, sourceName, spellId)
    local t = ISC_Data[currentInstanceID]["data"]
    local npcId = sourceGUID and select(6, strsplit("-", sourceGUID)) or nil
    if npcId then npcId = tonumber(npcId) end

    -- save enemy-spell ---------------------------------------------------------------------------
    local enemy = currentEncounterID .. sourceName
    if not t[enemy] then
        -- local _, _, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", sourceGUID)
        t[enemy] = {
            ["npcId"] = npcId,
            ["npcName"] = sourceName,
            ["auras"] = {},
            ["casts"] = {},
        }
    end
    t[enemy][index][spellId] = true
    -----------------------------------------------------------------------------------------------

    if currentEncounterID and currentEncounterName then
        -- save encounter-spell
        local currentEncounter = "|cff27ffff" .. currentEncounterID .. currentEncounterName .. "|r"
        if not t[currentEncounter] then
            t[currentEncounter] = {
                ["encounterName"] = currentEncounterName,
                ["encounterId"] = tonumber(currentEncounterID),
                ["npcs"] = {},
                ["auras"] = {},
                ["casts"] = {},
            }
        end

        if npcId then
            t[currentEncounter]["npcs"][npcId] = sourceName
        end

        if type(t[currentEncounter][index][spellId]) ~= "table" then t[currentEncounter][index][spellId] = {} end
        t[currentEncounter][index][spellId][npcId or 0] = sourceName
    else
        -- save mobs-spell
        local mobs = "|cff27ffff* MOBS|r"
        if not t[mobs] then
            t[mobs] = {
                ["auras"] = {},
                ["casts"] = {},
            }
        end

        if type(t[mobs][index][spellId]) ~= "table" then t[mobs][index][spellId] = {} end
        t[mobs][index][spellId][npcId or 0] = sourceName
    end
end

local spells = {}

local function UpdateAura(unit, source, spellId, auraDuration, isDebuff, auraDispelType, count)
    -- print("UpdateAura", unit, source, spellId, auraDuration, isDebuff, auraDispelType)

    if not ISC_Spell[spellId] then
        ISC_Spell[spellId] = {
            ["sources"] = {},
            ["encounters"] = {},
        }
    end

    ISC_Spell[spellId]["build"] = ISC.build

    local spell = spells[spellId] or Spell:CreateFromSpellID(spellId)
    spells[spellId] = spell

    if spell:IsSpellDataCached() then
        ISC_Spell[spellId]["name"] = spell:GetSpellName()
        ISC_Spell[spellId]["icon"] = spell:GetSpellTexture()
        ISC_Spell[spellId]["desc"] = spell:GetSpellDescription()
    else
        spell:ContinueOnSpellLoad(function()
            ISC_Spell[spellId]["name"] = spell:GetSpellName()
            ISC_Spell[spellId]["icon"] = spell:GetSpellTexture()
            ISC_Spell[spellId]["desc"] = spell:GetSpellDescription()
        end)
    end

    if auraDispelType then
        ISC_Spell[spellId]["auraDispelType"] = auraDispelType
    end
    ISC_Spell[spellId]["auraType"] = isDebuff and "debuff" or "buff"

    if ISC.isRetail and unit and not ISC_Spell[spellId]["auraDesc"] then
        ISC_Spell[spellId]["auraDesc"] = GetAuraDesc(unit, spellId)
    end

    if auraDuration then
        ISC_Spell[spellId]["auraDuration"] = auraDuration
    end

    if count and count > 1 then
        ISC_Spell[spellId]["auraStackable"] = true
    end

    if source then
        local guid = UnitGUID(source)
        local name = UnitName(source)
        local id = guid and select(6, strsplit("-", guid)) or nil
        if id then id = tonumber(id) end
        if id then
            ISC_Spell[spellId]["sources"][id] = name
        end
    end

    if currentEncounterID and currentEncounterName then
        ISC_Spell[spellId]["encounters"][tonumber(currentEncounterID)] = currentEncounterName
    end
end

local function UpdateCast(source, spellId, castTime, castType)
    -- print("UpdateCast", source, spellId, castTime, castType)

    if not ISC_Spell[spellId] then
        ISC_Spell[spellId] = {
            ["sources"] = {},
            ["encounters"] = {},
        }
    end

    ISC_Spell[spellId]["build"] = ISC.build

    local spell = spells[spellId] or Spell:CreateFromSpellID(spellId)
    spells[spellId] = spell

    if spell:IsSpellDataCached() then
        ISC_Spell[spellId]["name"] = spell:GetSpellName()
        ISC_Spell[spellId]["icon"] = spell:GetSpellTexture()
        ISC_Spell[spellId]["desc"] = spell:GetSpellDescription()
    else
        spell:ContinueOnSpellLoad(function()
            ISC_Spell[spellId]["name"] = spell:GetSpellName()
            ISC_Spell[spellId]["icon"] = spell:GetSpellTexture()
            ISC_Spell[spellId]["desc"] = spell:GetSpellDescription()
        end)
    end

    if not (castTime or castType) then
        if not (ISC_Spell[spellId]["castType"] or ISC_Spell[spellId]["castTime"]) then
            ISC_Spell[spellId]["castType"] = "instant"
        end
    else
        ISC_Spell[spellId]["castType"] = castType
        ISC_Spell[spellId]["castTime"] = castTime
    end

    if source then
        local guid = UnitGUID(source)
        local name = UnitName(source)
        local id = guid and select(6, strsplit("-", guid)) or nil
        if id then id = tonumber(id) end
        if id then
            ISC_Spell[spellId]["sources"][id] = name
        end
    end

    if currentEncounterID and currentEncounterName then
        ISC_Spell[spellId]["encounters"][tonumber(currentEncounterID)] = currentEncounterName
    end
end

-------------------------------------------------
-- event
-------------------------------------------------
collectorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

RegisterEvents = function()
    collectorFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    collectorFrame:RegisterEvent("ENCOUNTER_START")
    collectorFrame:RegisterEvent("ENCOUNTER_END")
    collectorFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    collectorFrame:RegisterEvent("UNIT_SPELLCAST_START")
    collectorFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    collectorFrame:RegisterEvent("UNIT_AURA")
    collectorFrame:RegisterEvent("UNIT_COMBAT")
    if ISC.isRetail then
        collectorFrame:RegisterEvent("TOOLTIP_DATA_UPDATE")
        -- collectorFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
    end
end

UnregisterEvents = function()
    collectorFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    collectorFrame:UnregisterEvent("ENCOUNTER_START")
    collectorFrame:UnregisterEvent("ENCOUNTER_END")
    collectorFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    collectorFrame:UnregisterEvent("UNIT_SPELLCAST_START")
    collectorFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    collectorFrame:UnregisterEvent("UNIT_AURA")
    collectorFrame:UnregisterEvent("UNIT_COMBAT")
    if ISC.isRetail then
        collectorFrame:UnregisterEvent("TOOLTIP_DATA_UPDATE")
        -- collectorFrame:UnregisterEvent("UPDATE_INSTANCE_INFO")
    end
end

function collectorFrame:PLAYER_ENTERING_WORLD()
    if IsInInstance() then
        local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
        instanceIDText:SetText("ID: |cffff5500" .. instanceID)
        instanceNameText:SetText("Name: |cffff5500" .. name)
        currentInstanceName, currentInstanceID = name, instanceID

        if ISC_Data[instanceID] and ISC_Data[instanceID]["enabled"] then
            statusText:SetText("|cff55ff55TRACKING")
            print("|cff77ff00[ISC] START TRACKING!")
            RegisterEvents()
        else
            if not ISC_Data[instanceID] and not ISC_Ignore[instanceID] and (instanceType == "raid" or instanceType == "party") then
                dialogText:SetText(dialogTip .. "\n|cFFFFD100" .. instanceID .. "\n" .. name)
                dialog:Show()
            end

            statusText:SetText("")
            UnregisterEvents()
        end
    else
        currentInstanceName, currentInstanceID = nil, nil
        instanceNameText:SetText("Name:")
        instanceIDText:SetText("ID:")
        statusText:SetText("")
        UnregisterEvents()
        wipe(queue)
    end
end

-- function collectorFrame:UPDATE_INSTANCE_INFO()
--     wipe(AI_FOLLOWERS)
--     -- dungeon AI
--     if GetDungeonDifficultyID() == 205 then
--         local unit, guid
--         for i = 1, 4 do
--             unit = "party" .. i
--             if UnitInPartyIsAI(unit) then
--                 guid = UnitGUID(unit)
--                 if guid then
--                     AI_FOLLOWERS[guid] = true
--                 end
--             end
--         end
--     end
--     -- TODO: raid AI
-- end

function collectorFrame:TOOLTIP_DATA_UPDATE(dataInstanceID)
    if queue[dataInstanceID] then
        local unit, id = queue[dataInstanceID][1], queue[dataInstanceID][2]
        queue[dataInstanceID] = nil

        local index = GetAuraIndex(unit, id)
        if index then
            local data = C_TooltipInfo_GetUnitDebuff(unit, index)
            if data["lines"] and data["lines"][2] then
                -- print("UPDATE", id, data["lines"][2]["leftText"])
                ISC_Spell[id]["auraDesc"] = data["lines"][2]["leftText"]
            end
        end
    end
end

local handledUnits = {}

function collectorFrame:ENCOUNTER_START(encounterID, encounterName)
    print("|cff0077ff[ISC] ENCOUNTER_START|r", encounterID, encounterName)
    wipe(handledUnits)
    currentEncounterID = encounterID .. " "
    currentEncounterName = encounterName
end

function collectorFrame:ENCOUNTER_END(encounterID, encounterName)
    print("|cff0077ff[ISC] ENCOUNTER_END|r", encounterID, encounterName)
    wipe(handledUnits)
    currentEncounterID = "* "
    currentEncounterName = nil
end

local AURA_BLACKLIST = {
    [1604] = true, -- 眩晕下坐骑
    -- general
    [160029] = true, -- 正在复活
    [452831] = true, -- 觅心生命注射器
    [57724] = true, -- 心满意足
    [57723] = true, -- 筋疲力尽
    [390435] = true, -- 筋疲力尽
    [80354] = true, -- 时空错位
    [264689] = true, -- 疲倦
    [460536] = true, -- 枯竭星光
    [313015] = true, -- 新近触发
    [440389] = true, -- 影缚仪式刻刃
    [472170] = true, -- 废料场9001型正在充能
    [206151] = true, -- 挑战者的负担
    -- death knight
    [48743] = true, -- 天灾契约
    [326809] = true, -- 餍足
    [123981] = true, -- 永劫不复
    [116888] = true, -- 炼狱蔽体
    [374609] = true, -- 抽血
    -- druid
    [451803] = true, -- 皎月风暴
    -- evoker
    [370665] = true, -- 营救
    -- hunter
    [382912] = true, -- 精确本能
    [472710] = true, -- 龟壳庇护
    -- mage
    [41425] = true, -- 低温
    [87023] = true, -- 灸灼
    -- monk
    [124275] = true, -- 轻度醉拳
    [124274] = true, -- 中度醉拳
    [124273] = true, -- 重度醉拳
    -- paladin
    [387441] = true, -- 苍穹之遗
    [25771] = true, -- 自律
    [448005] = true, -- 殉道者之光
    [157131] = true, -- 最近刚刚获得圣光的救赎
    [393879] = true, -- 金色瓦格里的礼物
    -- priest
    [114216] = true, -- 天使壁垒
    [211319] = true, -- 代偿
    [341291] = true, -- 黑暗弥漫
    -- rogue
    [45181] = true, -- 装死
    -- shaman
    [378277] = true, -- 元素均衡
    [225080] = true, -- 复生
    -- warlock
    [387847] = true, -- 邪甲术
    [113942] = true, -- 恶魔传送门
    -- warrior
    [458386] = true, -- 终有极限
    [456447] = true, -- 历战老兵
}

local function IsValidTarget(target)
    return UnitPlayerOrPetInRaid(target) or UnitPlayerOrPetInParty(target) or UnitIsPlayer(target)
end

local function IsValidSource(source)
    return not (UnitPlayerOrPetInRaid(source) or UnitPlayerOrPetInParty(source) or UnitIsPlayer(source)) -- or UnitPlayerControlled(source))
end

--! encounter npcs
function collectorFrame:UNIT_COMBAT(unit)
    if not (currentEncounterID and currentEncounterName) then return end

    local guid = UnitGUID(unit)
    if guid and not handledUnits[guid] then
        handledUnits[guid] = true
        if IsValidSource(unit) then
            local npcId = guid and select(6, strsplit("-", guid)) or nil
            if npcId then npcId = tonumber(npcId) end
            if npcId then
                local t = ISC_Data[currentInstanceID]["data"]
                local currentEncounter = "|cff27ffff" .. currentEncounterID .. currentEncounterName .. "|r"

                if not t[currentEncounter] then
                    t[currentEncounter] = {
                        ["encounterName"] = currentEncounterName,
                        ["encounterId"] = tonumber(currentEncounterID),
                        ["npcs"] = {},
                        ["auras"] = {},
                        ["casts"] = {},
                    }
                end
                t[currentEncounter]["npcs"][npcId] = UnitName(unit)
            end
        end
    end
end

--! CASTS
function collectorFrame:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellId, castTime, castType)
    if not (currentInstanceName and currentInstanceID and spellId) then return end
    if UnitIsPlayer(unit) or UnitInPartyIsAI(unit) or UnitPlayerOrPetInRaid(unit) or UnitPlayerOrPetInParty(unit) then return end
    -- if not (UnitIsEnemy("player", unit) and UnitIsFriend("player", unit.."target")) then return end

    local sourceName = UnitName(unit)
    local sourceGUID = UnitGUID(unit)
    if sourceName and sourceGUID then
        SaveData("casts", sourceGUID, sourceName, spellId)
        UpdateCast(unit, spellId, castTime, castType)
    end
end

function collectorFrame:UNIT_SPELLCAST_START(unit, _, spellId)
    local _, _, _, startTimeMS, endTimeMS = UnitCastingInfo(unit)
    if startTimeMS and endTimeMS then
        collectorFrame:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellId, endTimeMS - startTimeMS, "cast")
    end
end

function collectorFrame:UNIT_SPELLCAST_CHANNEL_START(unit, _, spellId)
    local _, _, _, startTimeMS, endTimeMS = UnitChannelInfo(unit)
    if startTimeMS and endTimeMS then
        collectorFrame:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellId, endTimeMS - startTimeMS, "channel")
    end
end

--! AURAS (COMBAT_LOG_EVENT_UNFILTERED)
function collectorFrame:COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount = ...
    if event ~= "SPELL_AURA_APPLIED" then return end

    if not (currentInstanceName and currentInstanceID and spellId) then return end
    if AURA_BLACKLIST[spellId] then return end

    -- if sourceGUID and AI_FOLLOWERS[sourceGUID] then return end

    -- !NOTE: some debuffs are SELF-APPLIED but caster == nil
    -- https://warcraft.wiki.gg/wiki/UnitFlag
    -- PLAYER_SELF_APPLIED: 1297 (0x511)
    -- if (not IsFriend(sourceFlags) or (sourceFlags == 1297 and not sourceName)) and IsFriend(destFlags) then
    if CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_HOSTILE_UNITS) then
        SaveData("auras", sourceGUID, sourceName or "UNKNOWN", spellId)
        UpdateAura(nil, nil, spellId, nil, auraType == "DEBUFF")
    end
end

--! AURAS (UNIT_AURA)
local function IsFriendUnit(unit)
    return UnitIsPlayer(unit) or UnitPlayerOrPetInRaid(unit) or UnitPlayerOrPetInParty(unit)
end

---@param target string always friend unit
---@return boolean? isValid
---@return string? sourceGUID
---@return string sourceName
local function GetAuraInfo(spellId, isHarmful, source, target)
    if AURA_BLACKLIST[spellId] then return end

    if not source then
        return true, nil, "UNKNOWN"
    end

    if source == target then
        if IsFriendUnit(source) then
            -- self applied debuffs
            return isHarmful, nil, "SELF"
        else
            -- enemy to enemy buffs/debuffs
            return true, UnitGUID(source), UnitName(source) or "UNKNOWN"
        end
    else
        if IsFriendUnit(source) then
            -- friend to friend debuffs
            return isHarmful, nil, "PLAYER"
        else
            -- enemy to friend buffs/debuffs
            return true, UnitGUID(source), UnitName(source) or "UNKNOWN"
        end
    end
end

if ISC.isRetail then
    local GetAuraDataByAuraInstanceID = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID

    function collectorFrame:UNIT_AURA(unit, updateInfo)
        if not (currentInstanceName and currentInstanceID and updateInfo) then return end
        if not IsValidTarget(unit) then return end

        if updateInfo.addedAuras then
            for _, data in pairs(updateInfo.addedAuras) do
                local isValid, sourceGUID, sourceName = GetAuraInfo(data.spellId, data.isHarmful, data.sourceUnit, unit)
                if isValid then
                    SaveData("auras", sourceGUID, sourceName, data.spellId)
                    UpdateAura(unit, data.sourceUnit, data.spellId, data.duration, data.isHarmful, data.dispelName, data.applications)
                end
            end
        end

        if updateInfo.updatedAuraInstanceIDs then
            for _, id in pairs(updateInfo.updatedAuraInstanceIDs) do
                local data = GetAuraDataByAuraInstanceID(unit, id)
                if data then
                    local isValid, sourceGUID, sourceName = GetAuraInfo(data.spellId, data.isHarmful, data.sourceUnit, unit)
                    if isValid then
                        UpdateAura(unit, data.sourceUnit, data.spellId, data.duration, data.isHarmful, data.dispelName, data.applications)
                    end
                end
            end
        end
    end
else
    local UnitBuff, UnitDebuff = UnitBuff, UnitDebuff

    function collectorFrame:UNIT_AURA(unit)
        if not (currentInstanceName and currentInstanceID) then return end
        if not IsValidTarget(unit) then return end

        for i = 1, 40 do
            local name, icon, count, dispelType, duration, expirationTime, source, _, _, spellId = UnitDebuff(unit, i)
            if not name then
                break
            end

            local isValid, sourceGUID, sourceName = GetAuraInfo(spellId, true, source, unit)
            if isValid then
                SaveData("auras", sourceGUID, sourceName, spellId)
                UpdateAura(unit, source, spellId, duration, true, dispelType, count)
            end
        end

        for i = 1, 40 do
            local name, icon, count, dispelType, duration, expirationTime, source, _, _, spellId = UnitBuff(unit, i)
            if not name then
                break
            end

            local isValid, sourceGUID, sourceName = GetAuraInfo(spellId, false, source, unit)
            if isValid then
                SaveData("auras", sourceGUID, sourceName, spellId)
                UpdateAura(unit, source, spellId, duration, false, dispelType, count)
            end
        end
    end
end

collectorFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:COMBAT_LOG_EVENT_UNFILTERED(CombatLogGetCurrentEventInfo())
    else
        self[event](self, ...)
    end
end)