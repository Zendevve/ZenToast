local _G = _G

function ZenToast.InitConfig()
    -- Setup Options Panel
    local panel = CreateFrame("Frame", "ZenToastOptions", UIParent)
    panel.name = "ZenToast"
    InterfaceOptions_AddCategory(panel)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ZenToast Options")

    local function CreateCheck(label, key, yOffset)
        local cb = CreateFrame("CheckButton", "ZenToastCheck"..key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOffset)
        _G[cb:GetName().."Text"]:SetText(label)
        cb:SetChecked(ZenToastDB[key])
        cb:SetScript("OnClick", function(self)
            ZenToastDB[key] = self:GetChecked()
        end)
        return cb
    end

    local function CreateHeader(text, yOffset)
        local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        header:SetPoint("TOPLEFT", 16, yOffset)
        header:SetText(text)
        header:SetTextColor(1, 0.82, 0) -- Gold color
        return header
    end

    -- Suppression Options
    CreateHeader("Suppression Options", -50)
    CreateCheck("Hide in Raid", "hideInRaid", -75)
    CreateCheck("Hide in Battleground", "hideInBG", -100)
    CreateCheck("Hide in Arena", "hideInArena", -125)

    -- Display Options
    CreateHeader("Display Options", -160)
    CreateCheck("Show Icon", "showIcon", -185)
    CreateCheck("Show Faction Badge", "showFactionBadge", -210)
    CreateCheck("Show Level", "showLevel", -235)
    CreateCheck("Show Class", "showClass", -260)
    CreateCheck("Show Location", "showLocation", -285)

    -- Advanced Options
    CreateHeader("Advanced Options", -320)
    CreateCheck("Use Custom Icons", "useCustomIcons", -345)

    -- Unlock Anchor Checkbox
    local unlockCb = CreateCheck("Unlock Anchor", "unlockAnchor", -370)
    unlockCb:SetChecked(false) -- Always start locked
    unlockCb:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ZenToast.Anchor:Show()
            ZenToast.Anchor:EnableMouse(true)
        else
            ZenToast.Anchor:Hide()
            ZenToast.Anchor:EnableMouse(false)
        end
    end)

    -- Restore saved position
    if ZenToastDB.anchorPoint then
        ZenToast.Anchor:ClearAllPoints()
        ZenToast.Anchor:SetPoint(ZenToastDB.anchorPoint, UIParent, ZenToastDB.anchorPoint, ZenToastDB.anchorX, ZenToastDB.anchorY)
    end
end

-- Anchor Frame
ZenToast.Anchor = CreateFrame("Frame", "ZenToastAnchor", UIParent)
ZenToast.Anchor:SetSize(ZenToast.FRAME_WIDTH, 20)
ZenToast.Anchor:SetPoint(ZenToast.defaults.anchorPoint, UIParent, ZenToast.defaults.anchorPoint, ZenToast.defaults.anchorX, ZenToast.defaults.anchorY)
ZenToast.Anchor:SetClampedToScreen(true)
ZenToast.Anchor:SetMovable(true)
ZenToast.Anchor:EnableMouse(false)
ZenToast.Anchor:RegisterForDrag("LeftButton")
ZenToast.Anchor:Hide()

ZenToast.Anchor.bg = ZenToast.Anchor:CreateTexture(nil, "BACKGROUND")
ZenToast.Anchor.bg:SetAllPoints(true)
ZenToast.Anchor.bg:SetTexture(0, 1, 0, 0.5)

ZenToast.Anchor.text = ZenToast.Anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ZenToast.Anchor.text:SetPoint("CENTER")
ZenToast.Anchor.text:SetText("ZenToast Anchor")

ZenToast.Anchor:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

ZenToast.Anchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    ZenToastDB.anchorPoint = point
    ZenToastDB.anchorX = x
    ZenToastDB.anchorY = y
end)
print("ZenToast: Config loaded")
