local _, LUP = ...

function LUP:CreateButton(parent, title, OnClick)
    local button = CreateFrame("Button", nil, parent)

    button.OnEnter = function() end
    button.OnLeave = function() end

    button:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    button:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    button.OnClick = OnClick
    
    button:SetText(title)
    button:SetNormalFontObject(AUFont13)
    button:SetHighlightFontObject(AUFont13)
    button:SetDisabledFontObject(AUFont13)
    button:SetScript("OnClick", button.OnClick)

    local function UpdateWidth()
        button:SetSize(button:GetFontString():GetUnboundedStringWidth() + 20, 26)
    end

    hooksecurefunc(button, "SetText", UpdateWidth)
    hooksecurefunc(button, "SetNormalFontObject", UpdateWidth)

    -- Background
    button.tex = button:CreateTexture(nil, "BACKGROUND")
    button.tex:SetAllPoints()
    button.tex:SetColorTexture(0, 0, 0, 0.3)

    -- Border
    local borderColor = LUP.gs.visual.borderColor

    LUP:AddBorder(button)
    button:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Highlight
    LUP:AddHoverHighlight(button)

    UpdateWidth()
    
    return button
end
