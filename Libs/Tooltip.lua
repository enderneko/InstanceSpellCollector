local _, addon = ...
local P = addon.pixelPerfectFuncs

local accentColor = {0.6, 0.1, 0.1, 1}

-----------------------------------------
-- Tooltip
-----------------------------------------
local function CreateTooltip(name)
    local tooltip = CreateFrame("GameTooltip", name, nil, "ISCTooltipTemplate,BackdropTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")

    local extraTip = CreateFrame("GameTooltip", name.."ExtraTip", tooltip, "ISCExtraTooltipTemplate,BackdropTemplate")

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
        extraTip:Hide()
    end)

    extraTip:SetScript("OnHide", function()
        extraTip:ClearLines()
    end)

    function tooltip:SetExtraTip(tip)
        if not tip then return end
        extraTip:SetOwner(tooltip:GetOwner(), "ANCHOR_NONE")
        extraTip:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 0, -1)
        extraTip:AddLine(tip)
        extraTip:Show()
    end

    function tooltip:UpdatePixelPerfect()
        tooltip:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = P:Scale(1)})
        tooltip:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        tooltip:SetBackdropBorderColor(unpack(accentColor))

        extraTip:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = P:Scale(1)})
        extraTip:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        extraTip:SetBackdropBorderColor(unpack(accentColor))
    end
end

CreateTooltip("ISCTooltip")