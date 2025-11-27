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

    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "ZenToastOptionsScrollFrame", mainPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 10)

    local scrollChild = CreateFrame("Frame", "ZenToastOptionsScrollChild", scrollFrame)
    scrollChild:SetWidth(600) -- Default width to ensure visibility
    scrollChild:SetHeight(500) -- Initial height, adjusted below
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnShow", function(self)
        scrollChild:SetWidth(self:GetWidth() - 20) -- Adjust for scrollbar
    end)

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

    local function CreateSlider(label, key, minVal, maxVal, step, yOffset, parent)
        local slider = CreateFrame("Slider", "ZenToastSlider"..key, parent, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 16, yOffset)
        slider:SetWidth(160) -- Reduced width to fit better
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetValue(ZenToastDB[key])

        _G[slider:GetName().."Text"]:SetText(label)
        _G[slider:GetName().."Low"]:SetText(minVal)
        _G[slider:GetName().."High"]:SetText(maxVal)

        local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
        valueText:SetText(slider:GetValue())

        slider:SetScript("OnValueChanged", function(self, value)
            -- Round to appropriate decimal places based on step
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

    -- Tab 1: Online Settings (Child Panel)
    local displayPanel = CreateFrame("Frame", "ZenToastOptionsDisplay", UIParent)
    displayPanel.name = "Online Settings"
    displayPanel.parent = "ZenToast"
    InterfaceOptions_AddCategory(displayPanel)

    CreateHeader("Online Display Options", -20, displayPanel)
    CreateCheck("Show Icon", "showIcon", -50, displayPanel)
    CreateCheck("Show Faction Badge", "showFactionBadge", -75, displayPanel)
    CreateCheck("Show Level", "showLevel", -100, displayPanel)
    CreateCheck("Show Class", "showClass", -125, displayPanel)
    CreateCheck("Show Location", "showLocation", -150, displayPanel)

    -- Tab 2: Offline Settings (Child Panel)
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

    -- Main Panel Content (General Settings)
    local y = -10
    CreateHeader("Appearance & Behavior", y, scrollChild)
    y = y - 40
    CreateSlider("Scale", "scale", 0.5, 2.0, 0.1, y, scrollChild)
    CreateSlider("Opacity", "opacity", 0.1, 1.0, 0.1, y, scrollChild):SetPoint("TOPLEFT", 200, y)
    y = y - 50
    CreateSlider("Duration (sec)", "toastDuration", 1, 10, 1, y, scrollChild)
    CreateSlider("Max Toasts", "maxToasts", 1, 10, 1, y, scrollChild):SetPoint("TOPLEFT", 200, y)
    y = y - 50

    CreateCheck("Play Sound", "playSound", y, scrollChild)

    -- Custom logic for Stack Upwards (string mapping)
    local stackCb = CreateFrame("CheckButton", "ZenToastCheckStack", scrollChild, "InterfaceOptionsCheckButtonTemplate")
    stackCb:SetPoint("TOPLEFT", 200, y)
    _G[stackCb:GetName().."Text"]:SetText("Stack Upwards")
    stackCb:SetChecked(ZenToastDB.growthDirection == "UP")
    stackCb:SetScript("OnClick", function(self)
        ZenToastDB.growthDirection = self:GetChecked() and "UP" or "DOWN"
    end)

    y = y - 40

    CreateHeader("Suppression", y, scrollChild)
    y = y - 30
    CreateCheck("Hide in Raid", "hideInRaid", y, scrollChild)
    y = y - 25
    CreateCheck("Hide in Battleground", "hideInBG", y, scrollChild)
    y = y - 25
    CreateCheck("Hide in Arena", "hideInArena", y, scrollChild)
    y = y - 40

    CreateHeader("Other Options", y, scrollChild)
    y = y - 30
    CreateCheck("Use Custom Icons", "useCustomIcons", y, scrollChild)
    y = y - 25

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

    local unlockCb = CreateCheck("Unlock Anchor", "unlockAnchor", y, scrollChild)
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
    y = y - 25

    -- Set ScrollChild height
    scrollChild:SetHeight(math.abs(y) + 20)

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
