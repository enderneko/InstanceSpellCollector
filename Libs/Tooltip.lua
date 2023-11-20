local _, addon = ...
local P = addon.pixelPerfectFuncs

local accentColor = {0.6, 0.1, 0.1, 1}

-----------------------------------------
-- Tooltip
-----------------------------------------
local function CreateTooltip(name)
    local tooltip = CreateFrame("GameTooltip", name, nil, "ISCTooltipTemplate,BackdropTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")

    local auraDesc = CreateFrame("GameTooltip", name.."AuraDesc", tooltip, "ISCAuraDescTooltipTemplate,BackdropTemplate")

    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        tooltip:RegisterEvent("TOOLTIP_DATA_UPDATE")
        tooltip:SetScript("OnEvent", function()
            -- Interface\FrameXML\GameTooltip.lua line924
            tooltip:RefreshData()
        end)
    end

    tooltip:SetScript("OnTooltipCleared", function()
        -- reset border color
        tooltip:SetBackdropBorderColor(unpack(accentColor))
    end)

    tooltip:SetScript("OnHide", function()
        -- SetX with invalid data may or may not clear the tooltip's contents.
        tooltip:ClearLines()
        auraDesc:Hide()
    end)

    auraDesc:SetScript("OnHide", function()
        auraDesc:ClearLines()
    end)

    function tooltip:SetAuraDesc(desc)
        if not desc then return end
        auraDesc:SetOwner(tooltip:GetOwner(), "ANCHOR_NONE")
        auraDesc:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 0, -1)
        auraDesc:AddLine(desc)
        auraDesc:Show()
    end

    function tooltip:UpdatePixelPerfect()
        tooltip:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = P:Scale(1)})
        tooltip:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        tooltip:SetBackdropBorderColor(unpack(accentColor))

        auraDesc:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = P:Scale(1)})
        auraDesc:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        auraDesc:SetBackdropBorderColor(unpack(accentColor))
    end
end

CreateTooltip("ISCTooltip")