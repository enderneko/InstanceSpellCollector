local addonName, addon = ...
local P = addon.pixelPerfectFuncs

-----------------------------------------
-- colors
-----------------------------------------
local colors = {
    grey = {s="|cFFB2B2B2", t={0.7, 0.7, 0.7}},
    yellow = {s="|cFFFFD100", t= {1, 0.82, 0}},
    orange = {s="|cFFFFC0CB", t= {1, 0.65, 0}},
    firebrick = {s="|cFFFF3030", t={1, 0.19, 0.19}},
    skyblue = {s="|cFF00CCFF", t={0, 0.8, 1}},
    chartreuse = {s="|cFF80FF00", t={.5, 1, 0}},
}

local accentColor = {0.6, 0.1, 0.1, 1}
-- local class = select(2, UnitClass("player"))
-- local classColor = {s="|cCCB2B2B2", t={0.7, 0.7, 0.7}}
-- if class then
--     accentColor[1], accentColor[2], accentColor[3], classColor.s = GetClassColor(class)
--     classColor.s = "|c"..classColor.s
-- end

-----------------------------------------
-- font
-----------------------------------------
local font_normal = CreateFont("ISC_FONT_NORMAL")
font_normal:SetFont(GameFontNormal:GetFont(), 13, "")
font_normal:SetTextColor(1, 1, 1, 1)
font_normal:SetShadowColor(0, 0, 0)
font_normal:SetShadowOffset(1, -1)
font_normal:SetJustifyH("CENTER")

local font_disabled = CreateFont("ISC_FONT_DISABLED")
font_disabled:SetFont(GameFontNormal:GetFont(), 13, "")
font_disabled:SetTextColor(0.4, 0.4, 0.4, 1)
font_disabled:SetShadowColor(0, 0, 0)
font_disabled:SetShadowOffset(1, -1)
font_disabled:SetJustifyH("CENTER")

local font_title = CreateFont("ISC_FONT_TITLE")
font_title:SetFont(GameFontNormal:GetFont(), 14, "")
font_title:SetTextColor(1, 1, 1, 1)
font_title:SetShadowColor(0, 0, 0)
font_title:SetShadowOffset(1, -1)
font_title:SetJustifyH("CENTER")

-----------------------------------------
-- frame
-----------------------------------------
function addon:StylizeFrame(frame, color, borderColor)
    if not color then color = {0.1, 0.1, 0.1, 0.9} end
    if not borderColor then borderColor = {0, 0, 0, 1} end

    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(unpack(borderColor))
end

function addon:CreateFrame(name, parent, width, height, isTransparent)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:Hide()
    if not isTransparent then addon:StylizeFrame(f) end
    f:EnableMouse(true)
    if width and height then f:SetSize(width, height) end
    return f
end

-----------------------------------------
-- Tooltip
-----------------------------------------
local function SetTooltip(widget, anchor, x, y, ...)
    local tooltips = {...}

    if #tooltips ~= 0 then
        widget:HookScript("OnEnter", function()
            ISCTooltip:SetOwner(widget, anchor or "ANCHOR_TOP", x or 0, y or 0)
            ISCTooltip:AddLine(tooltips[1])
            for i = 2, #tooltips do
                ISCTooltip:AddLine("|cffffffff" .. tooltips[i])
            end
            ISCTooltip:Show()
        end)
        widget:HookScript("OnLeave", function()
            ISCTooltip:Hide()
        end)
    end
end

-- hooksecurefunc("SecureActionButton_OnClick", function(self, inputButton, down, isKeyPress, isSecureAction)
--     print(self:GetName(), self:GetAttribute("pressAndHoldAction"), inputButton, down, isKeyPress, isSecureAction)
-- end)

function addon:CreateButton(parent, text, buttonColor, size, noBorder, isSecure, ...)
    local b
    if isSecure then
        b = CreateFrame("Button", "ISC_"..text, parent, "SecureActionButtonTemplate,BackdropTemplate")
        b:RegisterForClicks("AnyUp", "AnyDown")

        -- b:SetAttribute("type", "click")
        -- b:SetAttribute("clickbutton", b.real)
        -- SecureHandlerWrapScript(b, "OnClick", b, [[
        --     if down then
        --         print("saved", button, "on down")
        --         self:SetAttribute("origbutton", button)
        --     else
        --         print("restored", self:GetAttribute("origbutton"), "on up")
        --         return self:GetAttribute("origbutton")
        --     end
        -- ]])
    else
        b = CreateFrame("Button", "ISC_"..text, parent, "BackdropTemplate")
    end

    if parent then b:SetFrameLevel(parent:GetFrameLevel()+1) end
    b:SetText(text)
    P:Size(b, size[1], size[2])
    
    local color, hoverColor
    if buttonColor == "red" then
        color = {0.6, 0.1, 0.1, 0.6}
        hoverColor = {0.6, 0.1, 0.1, 1}
    elseif buttonColor == "red-hover" then
        color = {0.1, 0.1, 0.1, 1}
        hoverColor = {0.6, 0.1, 0.1, 1}
    elseif buttonColor == "green" then
        color = {0.1, 0.6, 0.1, 0.6}
        hoverColor = {0.1, 0.6, 0.1, 1}
    elseif buttonColor == "green-hover" then
        color = {0.1, 0.1, 0.1, 1}
        hoverColor = {0.1, 0.6, 0.1, 1}
    elseif buttonColor == "cyan" then
        color = {0, 0.9, 0.9, 0.6}
        hoverColor = {0, 0.9, 0.9, 1}
    elseif buttonColor == "blue" then
        color = {0, 0.5, 0.8, 0.6}
        hoverColor = {0, 0.5, 0.8, 1}
    elseif buttonColor == "blue-hover" then
        color = {0.1, 0.1, 0.1, 1}
        hoverColor = {0, 0.5, 0.8, 1}
    elseif buttonColor == "yellow" then
        color = {0.7, 0.7, 0, 0.6}
        hoverColor = {0.7, 0.7, 0, 1}
    elseif buttonColor == "yellow-hover" then
        color = {0.1, 0.1, 0.1, 1}
        hoverColor = {0.7, 0.7, 0, 1}
    elseif buttonColor == "chartreuse" then
        color = {0.5, 1, 0, 0.6}
        hoverColor = {0.5, 1, 0, 0.8}
    elseif buttonColor == "magenta" then
        color = {0.6, 0.1, 0.6, 0.6}
        hoverColor = {0.6, 0.1, 0.6, 1}
    elseif buttonColor == "transparent" then -- drop down item
        color = {0, 0, 0, 0}
        hoverColor = {.5, 1, 0, 0.7}
    elseif buttonColor == "transparent-white" then -- drop down item
        color = {0, 0, 0, 0}
        hoverColor = {0.4, 0.4, 0.4, 0.7}
    elseif buttonColor == "transparent-light" then -- list button
        color = {0, 0, 0, 0}
        hoverColor = {.5, 1, 0, 0.5}
    elseif buttonColor == "none" then
        color = {0, 0, 0, 0}
    else
        color = {0.1, 0.1, 0.1, 0.7}
        hoverColor = {0.5, 1, 0, 0.6}
    end

    -- keep color & hoverColor
    b.color = color
    b.hoverColor = hoverColor

    local s = b:GetFontString()
    if s then
        s:SetWordWrap(false)
        -- s:SetWidth(size[1])
        s:SetPoint("LEFT")
        s:SetPoint("RIGHT")
    end
    
    if noBorder then
        b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    else
        b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1, insets = {left=1,top=1,right=1,bottom=1}})
    end
    
    if buttonColor and string.find(buttonColor, "transparent") then -- drop down item
        -- b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        if s then
            s:SetJustifyH("LEFT")
            s:SetPoint("LEFT", 5, 0)
            s:SetPoint("RIGHT", -5, 0)
        end
        b:SetBackdropBorderColor(1, 1, 1, 0)
        b:SetPushedTextOffset(0, 0)
    else
        b:SetBackdropBorderColor(0, 0, 0, 1)
        b:SetPushedTextOffset(0, -1)
    end


    b:SetBackdropColor(unpack(color)) 
    b:SetDisabledFontObject(font_disabled)
    b:SetNormalFontObject(font_normal)
    b:SetHighlightFontObject(font_normal)
    
    if buttonColor ~= "none" then
        b:SetScript("OnEnter", function(self) self:SetBackdropColor(unpack(hoverColor)) end)
        b:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(color)) end)
    end
    
    -- click sound
    if addon.isRetail then
        b:SetScript("PostClick", function(self, button, down)
            --! NOTE: ActionButtonUseKeyDown will affect OnClick
            if isSecure then
                if down == GetCVarBool("ActionButtonUseKeyDown") then
                    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
                end
            else
                PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
            end
        end)
    else
        b:SetScript("PostClick", function() PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end)
    end

    -- texture
    function b:SetTexture(tex, texSize, point, isAtlas)
        b.tex = b:CreateTexture(nil, "ARTWORK")
        b.tex:SetPoint(unpack(point))
        b.tex:SetSize(unpack(texSize))
        if isAtlas then
            b.tex:SetAtlas(tex)
        else
            b.tex:SetTexture(tex)
        end
        -- update fontstring point
        if s then
            s:ClearAllPoints()
            s:SetPoint("LEFT", b.tex, "RIGHT", point[2], 0)
            s:SetPoint("RIGHT", -point[2], 0)
            b:SetPushedTextOffset(0, 0)
        end
        -- push effect
        b.onMouseDown = function()
            b.tex:ClearAllPoints()
            b.tex:SetPoint(point[1], point[2], point[3]-1)
        end
        b.onMouseUp = function()
            b.tex:ClearAllPoints()
            b.tex:SetPoint(unpack(point))
        end
        b:SetScript("OnMouseDown", b.onMouseDown)
        b:SetScript("OnMouseUp", b.onMouseUp)
        -- enable / disable
        b:HookScript("OnEnable", function()
            b.tex:SetVertexColor(1, 1, 1)
            b:SetScript("OnMouseDown", b.onMouseDown)
            b:SetScript("OnMouseUp", b.onMouseUp)
        end)
        b:HookScript("OnDisable", function()
            b.tex:SetVertexColor(0.4, 0.4, 0.4)
            b:SetScript("OnMouseDown", nil)
            b:SetScript("OnMouseUp", nil)
        end)
    end

    SetTooltip(b, "ANCHOR_TOPLEFT", 0, 3, ...)

    function b:UpdatePixelPerfect()
        P:Resize(b)
        P:Repoint(b)

        if not noBorder then
            -- backup colors
            local currentBackdropColor = {b:GetBackdropColor()}
            local currentBackdropBorderColor = {b:GetBackdropBorderColor()}
            -- update backdrop
            local n = P:Scale(1)
            b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = n, insets = {left=n, right=n, top=n, bottom=n}})
            -- restore colors
            b:SetBackdropColor(unpack(currentBackdropColor))
            b:SetBackdropBorderColor(unpack(currentBackdropBorderColor))
            currentBackdropColor = nil
            currentBackdropBorderColor = nil
        end
    end

    return b
end

-----------------------------------------
-- Button Group
-----------------------------------------
function addon:CreateButtonGroup(buttons, onClick, func1, func2, onEnter, onLeave)
    local function HighlightButton(id)
        for _, b in pairs(buttons) do
            if id == b.id then
                b:SetBackdropColor(unpack(b.hoverColor))
                b:SetScript("OnEnter", function()
                    if b.ShowTooltip then b.ShowTooltip(b) end
                    if onEnter then onEnter(b) end
                end)
                b:SetScript("OnLeave", function()
                    if b.HideTooltip then b.HideTooltip() end
                    if onLeave then onLeave() end
                end)
                if func1 then func1(b.id) end
            else
                b:SetBackdropColor(unpack(b.color))
                b:SetScript("OnEnter", function() 
                    if b.ShowTooltip then b.ShowTooltip(b) end
                    b:SetBackdropColor(unpack(b.hoverColor))
                    if onEnter then onEnter(b) end
                end)
                b:SetScript("OnLeave", function() 
                    if b.HideTooltip then b.HideTooltip() end
                    b:SetBackdropColor(unpack(b.color))
                    if onLeave then onLeave() end
                end)
                if func2 then func2(b.id) end
            end
        end
    end

    HighlightButton() -- REVIEW:
    
    for _, b in pairs(buttons) do
        b:SetScript("OnClick", function(self, button)
            HighlightButton(b.id)
            onClick(b, button)
        end)
    end
    
    -- buttons.HighlightButton = HighlightButton

    return buttons, HighlightButton
end

-----------------------------------------
-- check button
-----------------------------------------
function addon:CreateCheckButton(parent, label, color, onClick, ...)
    -- InterfaceOptionsCheckButtonTemplate --> FrameXML\InterfaceOptionsPanels.xml line 19
    -- OptionsBaseCheckButtonTemplate -->  FrameXML\OptionsPanelTemplates.xml line 10
    
    local cb = CreateFrame("CheckButton", nil, parent)
    cb.onClick = onClick
    cb:SetScript("OnClick", function(self)
        PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        if cb.onClick then cb.onClick(self:GetChecked() and true or false, self) end
    end)
    
    cb.label = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cb.label:SetText(label)
    cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    if color then
        cb.label:SetTextColor(color.r, color.g, color.b)
    end
    
    cb:SetSize(16, 16)
    cb:SetHitRectInsets(0, -cb.label:GetStringWidth(), 0, 0)
    
    cb:SetNormalTexture([[Interface\AddOns\GuildRaidAttendance\Media\CheckBox\CheckBox-Normal-16x16]])
    -- cb:SetPushedTexture()
    cb:SetHighlightTexture([[Interface\AddOns\GuildRaidAttendance\Media\CheckBox\CheckBox-Highlight-16x16]], "ADD")
    cb:SetCheckedTexture([[Interface\AddOns\GuildRaidAttendance\Media\CheckBox\CheckBox-Checked-16x16]])
    cb:SetDisabledCheckedTexture([[Interface\AddOns\GuildRaidAttendance\Media\CheckBox\CheckBox-DisabledChecked-16x16]])
    
    SetTooltip(cb, "ANCHOR_TOPLEFT", 0, 0, ...)

    return cb
end

-----------------------------------------
-- editbox 2017-06-21 10:19:33
-----------------------------------------
function addon:CreateEditBox(parent, width, height, isTransparent, isMultiLine, isNumeric)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    if not isTransparent then addon:StylizeFrame(eb, {0.1, 0.1, 0.1, 0.9}) end
    eb:SetFontObject("GameFontWhite")
    eb:SetMultiLine(isMultiLine)
    eb:SetMaxLetters(0)
    eb:SetJustifyH("LEFT")
    eb:SetJustifyV("MIDDLE")
    eb:SetWidth(width or 0)
    eb:SetHeight(height or 0)
    eb:SetTextInsets(5, 5, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetNumeric(isNumeric)
    eb:SetScript("OnEscapePressed", function() eb:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function() eb:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function() eb:HighlightText() end)
    eb:SetScript("OnEditFocusLost", function() eb:HighlightText(0, 0) end)
    eb:SetScript("OnDisable", function() eb:SetTextColor(0.7, 0.7, 0.7, 1) end)
    eb:SetScript("OnEnable", function() eb:SetTextColor(1, 1, 1, 1) end)

    return eb
end

function addon:CreateScrollEditBox(parent, onTextChanged)
    local frame = CreateFrame("Frame", nil, parent)
    addon:CreateScrollFrame(frame)
    addon:StylizeFrame(frame.scrollFrame, {0.15, 0.15, 0.15, 0.9})
    
    frame.eb = addon:CreateEditBox(frame.scrollFrame.content, 10, 20, true, true)
    frame.eb:SetPoint("TOPLEFT")
    frame.eb:SetPoint("RIGHT")
    frame.eb:SetTextInsets(2, 2, 1, 1)
    frame.eb:SetScript("OnEditFocusGained", nil)
    frame.eb:SetScript("OnEditFocusLost", nil)

    frame.eb:SetScript("OnEnterPressed", function(self) self:Insert("\n") end)

    -- https://wow.gamepedia.com/UIHANDLER_OnCursorChanged
    frame.eb:SetScript("OnCursorChanged", function(self, x, y, arg, lineHeight)
        frame.scrollFrame:SetScrollStep(lineHeight)

        local vs = frame.scrollFrame:GetVerticalScroll()
        local h  = frame.scrollFrame:GetHeight()

        local cursorHeight = lineHeight - y

        if vs + y > 0 then -- cursor above current view
            frame.scrollFrame:SetVerticalScroll(-y)
        elseif cursorHeight > h + vs then
            frame.scrollFrame:SetVerticalScroll(-y-h+lineHeight+arg)
        end

        if frame.scrollFrame:GetVerticalScroll() > frame.scrollFrame:GetVerticalScrollRange() then frame.scrollFrame:ScrollToBottom() end
    end)

    frame.eb:SetScript("OnTextChanged", function(self, userChanged)
        frame.scrollFrame:SetContentHeight(self:GetHeight())
        if userChanged and onTextChanged then
            onTextChanged(self)
        end
    end)

    frame.scrollFrame:SetScript("OnMouseDown", function()
        frame.eb:SetFocus(true)
    end)

    function frame:SetText(text)
        frame.scrollFrame:ResetScroll()
        frame.eb:SetText(text)
    end

    return frame
end

-----------------------------------------
-- slider
-----------------------------------------
-- Interface\FrameXML\OptionsPanelTemplates.xml, line 76, OptionsSliderTemplate
function addon:CreateSlider(name, parent, low, high, width, step, onValueChangedFn, afterValueChangedFn, isPercentage)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(width, 10)
    local unit = isPercentage and "%" or ""

    addon:StylizeFrame(slider, {0.115, 0.115, 0.115, 1})
    
    local nameText = slider:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
    nameText:SetText(name)
    nameText:SetPoint("BOTTOM", slider, "TOP", 0, 2)

    function slider:SetName(n)
        nameText:SetText(n)
    end

    local currentEditBox = addon:CreateEditBox(slider, 44, 14)
    slider.currentEditBox = currentEditBox
    currentEditBox:SetPoint("TOP", slider, "BOTTOM", 0, -1)
    currentEditBox:SetJustifyH("CENTER")
    currentEditBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    currentEditBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local value
        if isPercentage then
            value = string.gsub(self:GetText(), "%%", "")
            value = tonumber(value)
        else
            value = tonumber(self:GetText())
        end

        if value == self.oldValue then return end
        if value then
            if value < slider.low then value = slider.low end
            if value > slider.high then value = slider.high end
            self:SetText(value..unit)
            slider:SetValue(value)
            if slider.onValueChangedFn then slider.onValueChangedFn(value) end
            if slider.afterValueChangedFn then slider.afterValueChangedFn(value) end
        else
            self:SetText(self.oldValue..unit)
        end
    end)
    currentEditBox:SetScript("OnShow", function(self)
        if self.oldValue then self:SetText(self.oldValue..unit) end
    end)

    local lowText = slider:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
    slider.lowText = lowText
    lowText:SetTextColor(unpack(colors.grey.t))
    lowText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
    lowText:SetPoint("BOTTOM", currentEditBox)
    
    local highText = slider:CreateFontString(nil, "OVERLAY", "ISC_FONT_NORMAL")
    slider.highText = highText
    highText:SetTextColor(unpack(colors.grey.t))
    highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    highText:SetPoint("BOTTOM", currentEditBox)

    local tex = slider:CreateTexture(nil, "ARTWORK")
    tex:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.7)
    tex:SetSize(8, 8)
    slider:SetThumbTexture(tex)

    local valueBeforeClick
    slider.onEnter = function()
        tex:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 1)
        valueBeforeClick = slider:GetValue()
    end
    slider:SetScript("OnEnter", slider.onEnter)
    slider.onLeave = function()
        tex:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.7)
    end
    slider:SetScript("OnLeave", slider.onLeave)

    slider.onValueChangedFn = onValueChangedFn
    slider.afterValueChangedFn = afterValueChangedFn
    
    -- if tooltip then slider.tooltipText = tooltip end

    local oldValue
    slider:SetScript("OnValueChanged", function(self, value, userChanged)
        if oldValue == value then return end
        oldValue = value

        if math.floor(value) < value then -- decimal
            value = tonumber(string.format("%.2f", value))
        end

        currentEditBox:SetText(value..unit)
        currentEditBox.oldValue = value
        if userChanged and slider.onValueChangedFn then slider.onValueChangedFn(value) end
    end)

    slider:SetScript("OnMouseUp", function(self, button, isMouseOver)
        -- oldValue here == newValue, OnMouseUp called after OnValueChanged
        if valueBeforeClick ~= oldValue and slider.afterValueChangedFn then
            valueBeforeClick = oldValue
            local value = slider:GetValue()
            if math.floor(value) < value then -- decimal
                value = tonumber(string.format("%.2f", value))
            end
            slider.afterValueChangedFn(value)
        end
    end)

    slider:SetValue(low) -- NOTE: needs to be after OnValueChanged

    slider:SetScript("OnDisable", function()
        nameText:SetTextColor(0.4, 0.4, 0.4)
        currentEditBox:SetEnabled(false)
        slider:SetScript("OnEnter", nil)
        slider:SetScript("OnLeave", nil)
        tex:SetColorTexture(0.4, 0.4, 0.4, 0.7)
        lowText:SetTextColor(0.4, 0.4, 0.4)
        highText:SetTextColor(0.4, 0.4, 0.4)
    end)
    
    slider:SetScript("OnEnable", function()
        nameText:SetTextColor(1, 1, 1)
        currentEditBox:SetEnabled(true)
        slider:SetScript("OnEnter", slider.onEnter)
        slider:SetScript("OnLeave", slider.onLeave)
        tex:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.7)
        lowText:SetTextColor(unpack(colors.grey.t))
        highText:SetTextColor(unpack(colors.grey.t))
    end)

    function slider:UpdateMinMaxValues(minV, maxV)
        slider:SetMinMaxValues(minV, maxV)
        slider.low = minV
        slider.high = maxV
        lowText:SetText(minV..unit)
        highText:SetText(maxV..unit)
    end
    slider:UpdateMinMaxValues(low, high)
    
    return slider
end

--------------------------------------------------------
-- create scroll frame (with scrollbar & content frame)
--------------------------------------------------------
function addon:CreateScrollFrame(parent, top, bottom, color, border)
    -- create scrollFrame & scrollbar seperately (instead of UIPanelScrollFrameTemplate), in order to custom it
    local scrollFrame = CreateFrame("ScrollFrame", parent:GetName() and parent:GetName().."ScrollFrame" or nil, parent, "BackdropTemplate")
    parent.scrollFrame = scrollFrame
    top = top or 0
    bottom = bottom or 0
    scrollFrame:SetPoint("TOPLEFT", 0, top) 
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, bottom)

    if color then
        addon:StylizeFrame(scrollFrame, color, border)
    end

    function scrollFrame:Resize(newTop, newBottom)
        top = newTop
        bottom = newBottom
        scrollFrame:SetPoint("TOPLEFT", 0, top) 
        scrollFrame:SetPoint("BOTTOMRIGHT", 0, bottom)
    end
    
    -- content
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 2)
    scrollFrame:SetScrollChild(content)
    scrollFrame.content = content
    -- content:SetFrameLevel(2)
    
    -- scrollbar
    local scrollbar = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, 0)
    scrollbar:SetPoint("BOTTOMRIGHT", scrollFrame, 7, 0)
    scrollbar:Hide()
    addon:StylizeFrame(scrollbar, {0.1, 0.1, 0.1, 0.8})
    scrollFrame.scrollbar = scrollbar
    
    -- scrollbar thumb
    local scrollThumb = CreateFrame("Frame", nil, scrollbar, "BackdropTemplate")
    scrollThumb:SetWidth(5) -- scrollbar's width is 5
    scrollThumb:SetHeight(scrollbar:GetHeight())
    scrollThumb:SetPoint("TOP")
    addon:StylizeFrame(scrollThumb, {accentColor[1], accentColor[2], accentColor[3], 0.8})
    scrollThumb:EnableMouse(true)
    scrollThumb:SetMovable(true)
    scrollThumb:SetHitRectInsets(-5, -5, 0, 0) -- Frame:SetHitRectInsets(left, right, top, bottom)
    scrollFrame.scrollThumb = scrollThumb
    
    -- reset content height manually ==> content:GetBoundsRect() make it right @OnUpdate
    function scrollFrame:ResetHeight()
        content:SetHeight(2)
    end
    
    -- reset to top, useful when used with DropDownMenu (variable content height)
    function scrollFrame:ResetScroll()
        scrollFrame:SetVerticalScroll(0)
    end
    
    -- FIXME: GetVerticalScrollRange goes wrong in 9.0.1
    function scrollFrame:GetVerticalScrollRange()
        local range = content:GetHeight() - scrollFrame:GetHeight()
        return range > 0 and range or 0
    end

    -- local scrollRange -- ACCURATE scroll range, for SetVerticalScroll(), instead of scrollFrame:GetVerticalScrollRange()
    function scrollFrame:VerticalScroll(step)
        local scroll = scrollFrame:GetVerticalScroll() + step
        -- if CANNOT SCROLL then scroll = -25/25, scrollFrame:GetVerticalScrollRange() = 0
        -- then scrollFrame:SetVerticalScroll(0) and scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange()) ARE THE SAME
        if scroll <= 0 then
            scrollFrame:SetVerticalScroll(0)
        elseif scroll >= scrollFrame:GetVerticalScrollRange() then
            scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
        else
            scrollFrame:SetVerticalScroll(scroll)
        end
    end

    -- NOTE: this func should not be called before Show, or GetVerticalScrollRange will be incorrect.
    function scrollFrame:ScrollToBottom()
        scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
    end

    function scrollFrame:SetContentHeight(height, num, spacing)
        if num and spacing then
            content:SetHeight(num*height+(num-1)*spacing)
        else
            content:SetHeight(height)
        end
    end

    --[[ BUG: not reliable
    -- to remove/hide widgets "widget:SetParent(nil)" MUST be called!!!
    scrollFrame:SetScript("OnUpdate", function()
        -- set content height, check if it CAN SCROLL
        local x, y, w, h = content:GetBoundsRect()
        -- NOTE: if content is not IN SCREEN -> x,y<0 -> h==-y!
        if x > 0 and y > 0 then
            content:SetHeight(h)
        end
    end)
    ]]
    
    -- stores all widgets on content frame
    -- local autoWidthWidgets = {}

    function scrollFrame:ClearContent()
        for _, c in pairs({content:GetChildren()}) do
            c:SetParent(nil)  -- or it will show (OnUpdate)
            c:ClearAllPoints()
            c:Hide()
        end
        -- wipe(autoWidthWidgets)
        scrollFrame:ResetHeight()
    end

    function scrollFrame:Reset()
        scrollFrame:ResetScroll()
        scrollFrame:ClearContent()
    end
    
    -- function scrollFrame:SetWidgetAutoWidth(widget)
    -- 	table.insert(autoWidthWidgets, widget)
    -- end
    
    -- on width changed, make the same change to widgets
    scrollFrame:SetScript("OnSizeChanged", function()
        -- change widgets width (marked as auto width)
        -- for i = 1, #autoWidthWidgets do
        -- 	autoWidthWidgets[i]:SetWidth(scrollFrame:GetWidth())
        -- end
        
        -- update content width
        content:SetWidth(scrollFrame:GetWidth())
    end)

    -- check if it can scroll
    content:SetScript("OnSizeChanged", function()
        -- set ACCURATE scroll range
        -- scrollRange = content:GetHeight() - scrollFrame:GetHeight()

        -- set thumb height (%)
        local p = scrollFrame:GetHeight() / content:GetHeight()
        p = tonumber(string.format("%.3f", p))
        if p < 1 then -- can scroll
            scrollThumb:SetHeight(scrollbar:GetHeight()*p)
            -- space for scrollbar
            scrollFrame:SetPoint("BOTTOMRIGHT", parent, -7, bottom)
            scrollbar:Show()
        else
            scrollFrame:SetPoint("BOTTOMRIGHT", parent, 0, bottom)
            scrollbar:Hide()
            if scrollFrame:GetVerticalScroll() > 0 then scrollFrame:SetVerticalScroll(0) end
        end
    end)

    -- DO NOT USE OnScrollRangeChanged to check whether it can scroll.
    -- "invisible" widgets should be hidden, then the scroll range is NOT accurate!
    -- scrollFrame:SetScript("OnScrollRangeChanged", function(self, xOffset, yOffset) end)
    
    -- dragging and scrolling
    scrollThumb:SetScript("OnMouseDown", function(self, button)
        if button ~= 'LeftButton' then return end
        local offsetY = select(5, scrollThumb:GetPoint(1))
        local mouseY = select(2, GetCursorPosition())
        local currentScroll = scrollFrame:GetVerticalScroll()
        self:SetScript("OnUpdate", function(self)
            --------------------- y offset before dragging + mouse offset
            local newOffsetY = offsetY + (select(2, GetCursorPosition()) - mouseY)
            
            -- even scrollThumb:SetPoint is already done in OnVerticalScroll, but it's useful in some cases.
            if newOffsetY >= 0 then -- @top
                scrollThumb:SetPoint("TOP")
                newOffsetY = 0
            elseif (-newOffsetY) + scrollThumb:GetHeight() >= scrollbar:GetHeight() then -- @bottom
                scrollThumb:SetPoint("TOP", 0, -(scrollbar:GetHeight() - scrollThumb:GetHeight()))
                newOffsetY = -(scrollbar:GetHeight() - scrollThumb:GetHeight())
            else
                scrollThumb:SetPoint("TOP", 0, newOffsetY)
            end
            local vs = (-newOffsetY / (scrollbar:GetHeight()-scrollThumb:GetHeight())) * scrollFrame:GetVerticalScrollRange()
            scrollFrame:SetVerticalScroll(vs)
        end)
    end)

    scrollThumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        if scrollFrame:GetVerticalScrollRange() ~= 0 then
            local scrollP = scrollFrame:GetVerticalScroll()/scrollFrame:GetVerticalScrollRange()
            local yoffset = -((scrollbar:GetHeight()-scrollThumb:GetHeight())*scrollP)
            scrollThumb:SetPoint("TOP", 0, yoffset)
        end
    end)
    
    local step = 19
    function scrollFrame:SetScrollStep(s)
        step = s
    end
    
    -- enable mouse wheel scroll
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        if delta == 1 then -- scroll up
            scrollFrame:VerticalScroll(-step)
        elseif delta == -1 then -- scroll down
            scrollFrame:VerticalScroll(step)
        end
    end)
    
    return scrollFrame
end