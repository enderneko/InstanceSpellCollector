local addonName, ISC = ...
local P = ISC.pixelPerfectFuncs

ISC.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ISC.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
ISC.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
 
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

function eventFrame:ADDON_LOADED(arg1)
    if arg1 == addonName then
        eventFrame:UnregisterEvent("ADDON_LOADED")

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
                ["instances"] = {
                    -- [id] = {name=string, enabled=boolean}
                },
                ["debuffs"] = {
                    -- [instanceId] = {
                    --     [sourceName] = {spellId=spellname}
                    -- }
                },
                ["casts"] = {
                    -- [instanceId] = {
                    --     [sourceName] = {spellId=spellname}
                    -- }
                }
            }
        end

        -- aura descriptions
        if type(ISC_AuraDesc) ~= "table" then
            ISC_AuraDesc = {
                -- [auraId] = "auraDescription"
            }
        end

        -- npc id
        if type(ISC_NpcId) ~= "table" then
            ISC_NpcId = {
                -- [instanceId] = {
                --     [name] = id
                -- }
            }
        end

        -- fix
        for id in pairs(ISC_Data["instances"]) do
            if not ISC_NpcId[id] then ISC_NpcId[id] = {} end
        end

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