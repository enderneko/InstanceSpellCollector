local addonName, ISC = ...
local P = ISC.pixelPerfectFuncs

ISC.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ISC.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
ISC.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

local version, build = GetBuildInfo()
ISC.build = version .. "." .. build

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

function eventFrame:ADDON_LOADED(arg1)
    if arg1 == addonName then
        eventFrame:UnregisterEvent("ADDON_LOADED")

        ISC.version = GetAddOnMetadata(addonName, "version")

        if type(ISC_Config) ~= "table" then ISC_Config = {} end

        -- scale
        if type(ISC_Config.scale) ~= "number" then
            local pScale = P:GetPixelPerfectScale()
            local scale
            if pScale >= 0.7 then
                scale = 1
            elseif pScale >= 0.5 then
                scale = 1.4
            else
                scale = 2
            end
            ISC_Config.scale = scale
        end
        P:SetRelativeScale(ISC_Config.scale)
        ISC:Fire("UpdateScale")

        -- data table
        if type(ISC_Data) ~= "table" then
            ISC_Data = {
                -- [instanceId] = {
                --     [instanceName] = (string),
                --     ["enabled"] = (boolean),
                --     ["data"] = {
                --         [encounterDisplayName] = {
                --             ["encounterId"] = (number),
                --             ["encounterName"] = (string),
                --             ["npcs"] = {
                --                 [npcId] = npcName,
                --             },
                --             ["auras"] = {
                --                 [id] = (number) sourceNpcId / (string) "UNKNOWN" / true,
                --             },
                --             ["casts"] = {
                --                 [id] = (number) sourceNpcId / (string) "UNKNOWN" / true,
                --             },
                --         },
                --         [npcDisplayName] = {
                --             ["npcId"] = (number),
                --             ["npcName"] = (string),
                --             ["auras"] = {
                --                 [id] = true,
                --             },
                --             ["casts"] = {
                --                 [id] = true,
                --             },
                --         },
                --     }
                -- }
            }
        end

        -- store all spell data
        if type(ISC_Spell) ~= "table" then
            ISC_Spell = {
                -- [id] = {
                --     ["name"] = (string),
                --     ["icon"] = (number),
                --     ["desc"] = (string),
                --     ["sources"] = {
                --         [npcId] = npcName,
                --     },
                --     ["encounters"] = {
                --         [encounterId] = encounterName,
                --     },
                --     -- aura
                --     ["auraDesc"] = (string),
                --     ["auraDuration"] = (number),
                --     ["auraType"] = "buff" / "debuff",
                --     ["auraDispelType"] = "Curse" / "Disease" / "Magic" / "Poison",
                --     ["auraStackable"] = true / nil,
                --     -- cast
                --     ["castType"] = "cast" / "channel" / "instant",
                --     ["castTime"] = (number),
                -- }
            }
        end

        -- aura descriptions
        -- if type(ISC_AuraDesc) ~= "table" then
        --     ISC_AuraDesc = {
        --         -- [auraId] = "auraDescription"
        --     }
        -- end

        -- npc id
        -- if type(ISC_NpcId) ~= "table" then
        --     ISC_NpcId = {
        --         -- [instanceId] = {
        --         --     [name] = id
        --         -- }
        --     }
        -- end

        -- revise ---------------------------------------------------
        -- for id in pairs(ISC_Data["instances"]) do
        --     if not ISC_NpcId[id] then ISC_NpcId[id] = {} end
        -- end

        if ISC_AuraDesc and ISC_NpcId then
            local data_temp = {}
            local spell_temp = {}

            for _, index in pairs({"debuffs", "casts"}) do
                for instanceId, instanceTbl in pairs(ISC_Data[index]) do
                    if not data_temp[instanceId] then
                        data_temp[instanceId] = {
                            ["name"] = ISC_Data["instances"][instanceId]["name"],
                            ["enabled"] = ISC_Data["instances"][instanceId]["enabled"],
                            ["data"] = {},
                        }
                    end

                    local t = data_temp[instanceId]["data"]

                    for source, tbl in pairs(instanceTbl) do
                        if strfind(source, "^|cff") and not strfind(source, "|r$") then
                            source = source .. "|r"
                        end

                        if not t[source] then
                            t[source] = {
                                ["auras"] = {},
                                ["casts"] = {}
                            }
                        end

                        -- move spells
                        for spellId, spellName in pairs(tbl) do
                            t[source][index == "debuffs" and "auras" or "casts"][spellId] = true

                            spell_temp[spellId] = {
                                ["sources"] = {},
                                ["encounters"] = {},
                                ["build"] = ISC.build,
                            }
                            if index == "debuffs" then
                                spell_temp[spellId]["auraType"] = "debuff"
                                spell_temp[spellId]["auraDesc"] = ISC_AuraDesc[spellId]
                            end
                        end

                        if strfind(source, "^|cff27ffff%d+ ") then
                            -- add encounter info
                            t[source]["npcs"] = {}
                            local id, name = strmatch(source, "^|cff27ffff(%d+) (.+)|r")
                            t[source]["encounterId"] = tonumber(id)
                            t[source]["encounterName"] = name
                        else
                            -- move npcId
                            local name = string.gsub(source, "^* ", "")
                            name = string.gsub(name, "^%d+ ", "")
                            if ISC_NpcId[instanceId] and ISC_NpcId[instanceId][name] then
                                t[source]["npcId"] = tonumber(ISC_NpcId[instanceId][name])
                                t[source]["npcName"] = name
                            end
                        end
                    end
                end
            end

            ISC_Data = data_temp
            ISC_Spell = spell_temp
            ISC_AuraDesc = nil
            ISC_NpcId = nil

            -- process spells
            for spellId, t in pairs(spell_temp) do
                local spell = Spell:CreateFromSpellID(spellId)
                spell:ContinueOnSpellLoad(function()
                    t["name"] = spell:GetSpellName() or "INVALID"
                    t["desc"] = spell:GetSpellDescription() or ""
                    t["icon"] = spell:GetSpellTexture() or 134400

                    if C_Spell and C_Spell.GetSpellInfo then
                        t["castTime"] = info.castTime or 0
                    else
                        t["castTime"] = select(4, GetSpellInfo(spellId)) or 0
                    end
                    if t["castTime"] == 0 then
                        t["castType"] = "instant"
                        t["castTime"] = nil
                    else
                        t["castType"] = "cast"
                    end
                end)
            end
        end

        -------------------------------------------------------------

        -- ignore (don't ask again)
        if type(ISC_Ignore) ~= "table" then
            ISC_Ignore = {
                -- [instanceId] = "instanceName",
            }
        end

        ISC:Fire("AddonLoaded")
    end
end

ISC:RegisterCallback("UpdateScale", "Collector_UpdateScale", function()
    P:SetRelativeScale(ISC_Config.scale)
    P:SetEffectiveScale(InstanceSpellCollectorFrame)
    P:SetEffectiveScale(InstanceSpellCollectorDialog)
    InstanceSpellCollectorDialog:UpdatePixelPerfect()
    P:SetEffectiveScale(ISCTooltip)
    ISCTooltip:UpdatePixelPerfect()
end)

-------------------------------------------------
-- slash command
-------------------------------------------------
SLASH_ISC1 = "/isc"
function SlashCmdList.ISC(msg, editbox)
    -- local command, rest = msg:match("^(%S*)%s*(.-)$")
    InstanceSpellCollectorFrame:Show()
end

function ISC_OnAddonCompartmentClick()
    InstanceSpellCollectorFrame:Show()
end