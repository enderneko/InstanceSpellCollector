local addonName, ISC = ...
local P = ISC.pixelPerfectFuncs
 
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
                    -- [sourceName] = {spellId=spellname}
                },
                ["casts"] = {
                    -- [sourceName] = {spellId=spellname}
                }
            }
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