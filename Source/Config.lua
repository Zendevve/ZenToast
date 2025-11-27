local _G = _G

function ZenToast.InitConfig()
    -- Main Panel
    local mainPanel = CreateFrame("Frame", "ZenToastOptions", UIParent)
    mainPanel.name = "ZenToast"
    InterfaceOptions_AddCategory(mainPanel)

    local title = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ZenToast Options")

    local desc = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetText("Configure your toast notification settings")

    -- Helper Functions
    local function CreateCheck(label, key, yOffset, parent)
        local cb = CreateFrame("CheckButton", "ZenToastCheck"..key, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOffset)
        _G[cb:GetName().."Text"]:SetText(label)
        cb:SetChecked(ZenToastDB[key])
        cb:SetScript("OnClick", function(self)
            ZenToastDB[key] = self:GetChecked()
        end)
        return cb
    end

    local function CreateHeader(text, yOffset, parent)
        local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", 16, yOffset)
        header:SetText(text)
        header:SetTextColor(1, 0.82, 0)
        return header
    end

    -- Tab 1: Display (Child Panel)
    local displayPanel = CreateFrame("Frame", "ZenToastOptionsDisplay", UIParent)
    displayPanel.name = "Display"
    displayPanel.parent = "ZenToast"
    InterfaceOptions_AddCategory(displayPanel)

    CreateHeader("Online Display Options", -20, displayPanel)
    CreateCheck("Show Icon", "showIcon", -50, displayPanel)
    CreateCheck("Show Faction Badge", "showFactionBadge", -75, displayPanel)
    CreateCheck("Show Level", "showLevel", -100, displayPanel)
    CreateCheck("Show Class", "showClass", -125, displayPanel)
    CreateCheck("Show Location", "showLocation", -150, displayPanel)

    -- Tab 2: Offline (Child Panel)
    local offlinePanel = CreateFrame("Frame", "ZenToastOptionsOffline", UIParent)
    offlinePanel.name = "Offline"
    offlinePanel.parent = "ZenToast"
    InterfaceOptions_AddCategory(offlinePanel)

    CreateHeader("Offline Display Options", -20, offlinePanel)
    CreateCheck("Show Icon (Offline)", "showIconOffline", -50, offlinePanel)
    CreateCheck("Show Faction Badge (Offline)", "showFactionBadgeOffline", -75, offlinePanel)
    CreateCheck("Show Level (Offline)", "showLevelOffline", -100, offlinePanel)
    CreateCheck("Show Class (Offline)", "showClassOffline", -125, offlinePanel)
    CreateCheck("Show Location (Offline)", "showLocationOffline", -150, offlinePanel)

    -- Tab 3: Advanced (Child Panel)
    local advancedPanel = CreateFrame("Frame", "ZenToastOptionsAdvanced", UIParent)
    advancedPanel.name = "Advanced"
    advancedPanel.parent = "ZenToast"
    InterfaceOptions_AddCategory(advancedPanel)

    CreateHeader("Suppression", -20, advancedPanel)
    CreateCheck("Hide in Raid", "hideInRaid", -50, advancedPanel)
    CreateCheck("Hide in Battleground", "hideInBG", -75, advancedPanel)
    CreateCheck("Hide in Arena", "hideInArena", -100, advancedPanel)

    CreateHeader("Other Options", -135, advancedPanel)
    CreateCheck("Use Custom Icons", "useCustomIcons", -165, advancedPanel)

    local afkCb = CreateCheck("Enable AFK Notifications", "enableAFK", -190, advancedPanel)
    afkCb:SetScript("OnClick", function(self)
        ZenToastDB.enableAFK = self:GetChecked()
        if ZenToastDB.enableAFK then
            ZenToast.StartAFKPolling()
        else
            ZenToast.StopAFKPolling()
        end
    end)

    local unlockCb = CreateCheck("Unlock Anchor", "unlockAnchor", -215, advancedPanel)
    unlockCb:SetChecked(false)
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

    -- Start AFK polling if enabled
    if ZenToastDB.enableAFK then
        ZenToast.StartAFKPolling()
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
