local _G = _G

function ZenToast.InitConfig()
    -- =========================================================================
    -- 1. Main Panel (Credits & Info Only)
    -- =========================================================================
    local mainPanel = CreateFrame("Frame", "ZenToastOptions", UIParent)
    mainPanel.name = "ZenToast"
    InterfaceOptions_AddCategory(mainPanel)

    local title = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ZenToast")

    local version = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 4, 0)
    version:SetText("v1.1")

    local author = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    author:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    author:SetText("Created by |cff00ff00Zendevve|r")

    local desc = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -20)
    desc:SetWidth(400)
    desc:SetJustifyH("LEFT")
    desc:SetText("ZenToast provides minimalist, customizable toast notifications for friends coming online and offline.\n\nUse the sub-categories on the left to configure the addon.")

    -- =========================================================================
    -- 2. General Settings Tab
    -- =========================================================================
    local generalPanel = CreateFrame("Frame", "ZenToastOptionsGeneral", UIParent)
    generalPanel.name = "General"
    generalPanel.parent = "ZenToast"
    InterfaceOptions_AddCategory(generalPanel)

    local genTitle = generalPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    genTitle:SetPoint("TOPLEFT", 16, -16)
    genTitle:SetText("General Settings")

    -- Scroll Frame for General Settings
    local scrollFrame = CreateFrame("ScrollFrame", "ZenToastGeneralScrollFrame", generalPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 10)

    local scrollChild = CreateFrame("Frame", "ZenToastGeneralScrollChild", scrollFrame)
    scrollChild:SetWidth(500)
    scrollChild:SetHeight(500) -- Will be adjusted dynamically
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnShow", function(self)
        scrollChild:SetWidth(self:GetWidth() - 20)
    end)

    -- --- Helper Functions for Controls ---
    local function CreateCheck(label, key, yOffset, parent)
        local cb = CreateFrame("CheckButton", "ZenToastCheck"..key, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOffset)
        _G[cb:GetName().."Text"]:SetText(label)

        -- Load saved value
        cb:SetChecked(ZenToastDB[key])

        cb:SetScript("OnClick", function(self)
            -- Explicitly save true or false, never nil
            ZenToastDB[key] = self:GetChecked() and true or false
        end)
        return cb
    end

    local function CreateSlider(label, key, minVal, maxVal, step, yOffset, parent)
        local slider = CreateFrame("Slider", "ZenToastSlider"..key, parent, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 16, yOffset)
        slider:SetWidth(180)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)

        -- Load saved value
        slider:SetValue(ZenToastDB[key])

        _G[slider:GetName().."Text"]:SetText(label)
        _G[slider:GetName().."Low"]:SetText(minVal)
        _G[slider:GetName().."High"]:SetText(maxVal)

        local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
        valueText:SetText(slider:GetValue())

        slider:SetScript("OnValueChanged", function(self, value)
            -- Round to appropriate decimal places
            if step < 1 then
                value = math.floor(value * 10 + 0.5) / 10
            else
                value = math.floor(value + 0.5)
            end

            ZenToastDB[key] = value
            valueText:SetText(value)
        end)

        return slider
    end

    local function CreateHeader(text, yOffset, parent)
        local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", 16, yOffset)
        header:SetText(text)
        header:SetTextColor(1, 0.82, 0)
        return header
    end

    -- --- General Tab Content ---
    local y = -10

    -- Appearance
    CreateHeader("Appearance & Behavior", y, scrollChild)
    y = y - 40
    CreateSlider("Scale", "scale", 0.5, 2.0, 0.1, y, scrollChild)
    CreateSlider("Opacity", "opacity", 0.1, 1.0, 0.1, y, scrollChild):SetPoint("TOPLEFT", 220, y)
    y = y - 50
    CreateSlider("Duration (sec)", "toastDuration", 1, 10, 1, y, scrollChild)
    CreateSlider("Max Toasts", "maxToasts", 1, 10, 1, y, scrollChild):SetPoint("TOPLEFT", 220, y)
    y = y - 50

    CreateCheck("Play Sound", "playSound", y, scrollChild)

    -- Stack Direction (Custom Logic)
    local stackCb = CreateFrame("CheckButton", "ZenToastCheckStack", scrollChild, "InterfaceOptionsCheckButtonTemplate")
    stackCb:SetPoint("TOPLEFT", 220, y)
    _G[stackCb:GetName().."Text"]:SetText("Stack Upwards")
    stackCb:SetChecked(ZenToastDB.growthDirection == "UP")
    stackCb:SetScript("OnClick", function(self)
        ZenToastDB.growthDirection = self:GetChecked() and "UP" or "DOWN"
    end)

    y = y - 40

    -- Suppression
    CreateHeader("Suppression", y, scrollChild)
    y = y - 30
    CreateCheck("Hide in Raid", "hideInRaid", y, scrollChild)
    y = y - 25
    CreateCheck("Hide in Battleground", "hideInBG", y, scrollChild)
    y = y - 25
    CreateCheck("Hide in Arena", "hideInArena", y, scrollChild)
    y = y - 40

    -- Other
    CreateHeader("Other Options", y, scrollChild)
    y = y - 30
    CreateCheck("Use Custom Icons", "useCustomIcons", y, scrollChild)
    y = y - 25

    -- AFK
    local afkCb = CreateCheck("Enable AFK Notifications", "enableAFK", y, scrollChild)
    afkCb:SetScript("OnClick", function(self)
        ZenToastDB.enableAFK = self:GetChecked()
        if ZenToastDB.enableAFK then
            ZenToast.StartAFKPolling()
        else
            ZenToast.StopAFKPolling()
        end
    end)
    y = y - 25

    -- Unlock Anchor (Not persisted by default, but state is managed)
    local unlockCb = CreateCheck("Unlock Anchor", "unlockAnchor", y, scrollChild)
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
    y = y - 25

    -- Adjust Scroll Height
    scrollChild:SetHeight(math.abs(y) + 20)


    -- =========================================================================
    -- 3. Online Settings Tab
    -- =========================================================================
    local onlinePanel = CreateFrame("Frame", "ZenToastOptionsOnline", UIParent)
    onlinePanel.name = "Online Settings"
    onlinePanel.parent = "ZenToast"
    InterfaceOptions_AddCategory(onlinePanel)

    CreateHeader("Online Display Options", -20, onlinePanel)
    CreateCheck("Show Icon", "showIcon", -50, onlinePanel)
    CreateCheck("Show Faction Badge", "showFactionBadge", -75, onlinePanel)
    CreateCheck("Show Level", "showLevel", -100, onlinePanel)
    CreateCheck("Show Class", "showClass", -125, onlinePanel)
    CreateCheck("Show Location", "showLocation", -150, onlinePanel)

    -- =========================================================================
    -- 4. Offline Settings Tab
    -- =========================================================================
    local offlinePanel = CreateFrame("Frame", "ZenToastOptionsOffline", UIParent)
    offlinePanel.name = "Offline Settings"
    offlinePanel.parent = "ZenToast"
    InterfaceOptions_AddCategory(offlinePanel)

    CreateHeader("Offline Display Options", -20, offlinePanel)
    CreateCheck("Show Icon (Offline)", "showIconOffline", -50, offlinePanel)
    CreateCheck("Show Faction Badge (Offline)", "showFactionBadgeOffline", -75, offlinePanel)
    CreateCheck("Show Level (Offline)", "showLevelOffline", -100, offlinePanel)
    CreateCheck("Show Class (Offline)", "showClassOffline", -125, offlinePanel)
    CreateCheck("Show Location (Offline)", "showLocationOffline", -150, offlinePanel)

    -- =========================================================================
    -- Initialization Logic
    -- =========================================================================

    -- Restore Anchor Position
    if ZenToastDB.anchorPoint then
        ZenToast.Anchor:ClearAllPoints()
        ZenToast.Anchor:SetPoint(ZenToastDB.anchorPoint, UIParent, ZenToastDB.anchorPoint, ZenToastDB.anchorX, ZenToastDB.anchorY)
    end

    -- Start AFK polling if enabled
    if ZenToastDB.enableAFK then
        ZenToast.StartAFKPolling()
    end
end

-- =========================================================================
-- Anchor Frame Definition
-- =========================================================================
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
