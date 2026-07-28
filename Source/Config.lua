local _G = _G

function Notifriend.InitConfig()
    -- =========================================================================
    -- 1. Main Panel (Credits & Info Only)
    -- =========================================================================
    local mainPanel = CreateFrame("Frame", "NotifriendOptions", UIParent)
    mainPanel.name = "Notifriend"
    InterfaceOptions_AddCategory(mainPanel)

    local title = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Notifriend")

    local version = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 4, 0)
    version:SetText("v" .. Notifriend.VERSION)

    local author = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    author:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    author:SetText("Created by |cff00ff00Zendevve|r")

    local desc = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -20)
    desc:SetWidth(400)
    desc:SetJustifyH("LEFT")
    desc:SetText("Notifriend provides minimalist, customizable toast notifications for friends coming online and offline.\n\nUse the sub-categories on the left to configure the addon.")

    -- =========================================================================
    -- 2. General Settings Tab
    -- =========================================================================
    local generalPanel = CreateFrame("Frame", "NotifriendOptionsGeneral", UIParent)
    generalPanel.name = "General"
    generalPanel.parent = "Notifriend"
    InterfaceOptions_AddCategory(generalPanel)

    local genTitle = generalPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    genTitle:SetPoint("TOPLEFT", 16, -16)
    genTitle:SetText("General Settings")

    -- Scroll Frame for General Settings
    local scrollFrame = CreateFrame("ScrollFrame", "NotifriendGeneralScrollFrame", generalPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 10)

    local scrollChild = CreateFrame("Frame", "NotifriendGeneralScrollChild", scrollFrame)
    scrollChild:SetWidth(500)
    scrollChild:SetHeight(600) -- Increased height for vertical layout
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnShow", function(self)
        scrollChild:SetWidth(self:GetWidth() - 20)
    end)

    -- --- Helper Functions for Controls ---
    local function CreateCheck(label, key, yOffset, parent)
        local cb = CreateFrame("CheckButton", "NotifriendCheck"..key, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, yOffset)
        _G[cb:GetName().."Text"]:SetText(label)

        -- Load saved value
        cb:SetChecked(NotifriendDB[key])

        cb:SetScript("OnClick", function(self)
            -- Explicitly save true or false, never nil
            NotifriendDB[key] = self:GetChecked() and true or false
        end)
        return cb
    end

    local function CreateSlider(label, key, minVal, maxVal, step, yOffset, parent)
        local slider = CreateFrame("Slider", "NotifriendSlider"..key, parent, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 16, yOffset)
        slider:SetWidth(180)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)

        -- Load saved value
        slider:SetValue(NotifriendDB[key])

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

            NotifriendDB[key] = value
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

    local function CreateButton(text, yOffset, parent, onClick)
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetPoint("TOPLEFT", 16, yOffset)
        btn:SetSize(120, 25)
        btn:SetText(text)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    -- --- General Tab Content ---
    local y = -10

    -- Appearance
    CreateHeader("Appearance & Behavior", y, scrollChild)
    y = y - 40

    -- Stack sliders vertically to avoid clipping
    CreateSlider("Scale", "scale", 0.5, 2.0, 0.1, y, scrollChild)
    y = y - 50
    CreateSlider("Opacity", "opacity", 0.1, 1.0, 0.1, y, scrollChild)
    y = y - 50
    CreateSlider("Duration (sec)", "toastDuration", 1, 10, 1, y, scrollChild)
    y = y - 50
    CreateSlider("Max Toasts", "maxToasts", 1, 10, 1, y, scrollChild)
    y = y - 50

    CreateCheck("Play Sound", "playSound", y, scrollChild)
    y = y - 30

    local function CreateDropdown(label, key, options, yOffset, parent)
        local dropdown = CreateFrame("Frame", "NotifriendDropdown"..key, parent, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", 16, yOffset)

        local soundLabels = {
            ["igQuestLogOpen"] = "Quest Log Open",
            ["igQuestLogClose"] = "Quest Log Close",
            ["igMainMenuItem"] = "Main Menu",
            ["igCharacterInfoOpen"] = "Character Info",
            ["igCharacterInfoClose"] = "Character Info Close",
            ["igMoneyWithdraw"] = "Money Withdraw",
            ["igMoneyDeposit"] = "Money Deposit",
            ["igPlayerInvite"] = "Player Invite",
            ["igSpellLearnNew"] = "Spell Learn",
            ["igAbilitiesClear"] = "Abilities Clear",
        }

        UIDropDownMenu_SetWidth(dropdown, 150)
        UIDropDownMenu_SetText(dropdown, soundLabels[NotifriendDB[key]] or NotifriendDB[key])

        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            for _, soundID in ipairs(options) do
                info.text = soundLabels[soundID] or soundID
                info.value = soundID
                info.func = function(self)
                    NotifriendDB[key] = self.value
                    UIDropDownMenu_SetText(dropdown, soundLabels[self.value] or self.value)
                end
                info.checked = (NotifriendDB[key] == soundID)
                UIDropDownMenu_AddButton(info)
            end
        end)

        local lbl = dropdown:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        lbl:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 5)
        lbl:SetText(label)

        return dropdown
    end

    local soundOptions = {"igQuestLogOpen", "igQuestLogClose", "igMainMenuItem", "igCharacterInfoOpen", "igCharacterInfoClose", "igMoneyWithdraw", "igMoneyDeposit", "igPlayerInvite", "igSpellLearnNew", "igAbilitiesClear"}
    CreateDropdown("Online Sound", "soundFile", soundOptions, y, scrollChild)
    y = y - 60
    CreateDropdown("Offline Sound", "soundFileOffline", soundOptions, y, scrollChild)
    y = y - 60

    -- Stack Direction (Custom Logic)
    local stackCb = CreateFrame("CheckButton", "NotifriendCheckStack", scrollChild, "InterfaceOptionsCheckButtonTemplate")
    stackCb:SetPoint("TOPLEFT", 16, y)
    _G[stackCb:GetName().."Text"]:SetText("Stack Upwards")
    stackCb:SetChecked(NotifriendDB.growthDirection == "UP")
    stackCb:SetScript("OnClick", function(self)
        NotifriendDB.growthDirection = self:GetChecked() and "UP" or "DOWN"
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
        NotifriendDB.enableAFK = self:GetChecked()
        if NotifriendDB.enableAFK then
            Notifriend.StartAFKPolling()
        else
            Notifriend.StopAFKPolling()
        end
    end)
    y = y - 25

    -- Unlock Anchor (Not persisted by default, but state is managed)
    local unlockCb = CreateCheck("Unlock Anchor", "unlockAnchor", y, scrollChild)
    unlockCb:SetChecked(false) -- Always start locked
    unlockCb:SetScript("OnClick", function(self)
        if self:GetChecked() then
            Notifriend.Anchor:Show()
            Notifriend.Anchor:EnableMouse(true)
        else
            Notifriend.Anchor:Hide()
            Notifriend.Anchor:EnableMouse(false)
        end
    end)
    y = y - 40

    -- Reset Button
    CreateButton("Reset to Defaults", y, scrollChild, function()
        NotifriendDB = nil -- Clear saved variables
        ReloadUI()       -- Reload to re-initialize with defaults
    end)
    y = y - 30

    -- Adjust Scroll Height
    scrollChild:SetHeight(math.abs(y) + 20)


    -- =========================================================================
    -- 3. Online Settings Tab
    -- =========================================================================
    local onlinePanel = CreateFrame("Frame", "NotifriendOptionsOnline", UIParent)
    onlinePanel.name = "Online Settings"
    onlinePanel.parent = "Notifriend"
    InterfaceOptions_AddCategory(onlinePanel)

    CreateHeader("Online Display Options", -20, onlinePanel)
    CreateCheck("Show Icon", "showIcon", -50, onlinePanel)
    CreateCheck("Show Faction Badge", "showFactionBadge", -75, onlinePanel)
    CreateCheck("Show Guild Members", "showGuildOnline", -100, onlinePanel) -- New
    CreateCheck("Show Level", "showLevel", -125, onlinePanel)
    CreateCheck("Show Class", "showClass", -150, onlinePanel)
    CreateCheck("Show Location", "showLocation", -175, onlinePanel)

    -- =========================================================================
    -- 4. Offline Settings Tab
    -- =========================================================================
    local offlinePanel = CreateFrame("Frame", "NotifriendOptionsOffline", UIParent)
    offlinePanel.name = "Offline Settings"
    offlinePanel.parent = "Notifriend"
    InterfaceOptions_AddCategory(offlinePanel)

    CreateHeader("Offline Display Options", -20, offlinePanel)
    CreateCheck("Show Icon (Offline)", "showIconOffline", -50, offlinePanel)
    CreateCheck("Show Faction Badge (Offline)", "showFactionBadgeOffline", -75, offlinePanel)
    CreateCheck("Show Guild Members (Offline)", "showGuildOffline", -100, offlinePanel) -- New
    CreateCheck("Show Level (Offline)", "showLevelOffline", -125, offlinePanel)
    CreateCheck("Show Class (Offline)", "showClassOffline", -150, offlinePanel)
    CreateCheck("Show Location (Offline)", "showLocationOffline", -175, offlinePanel)

    -- =========================================================================
    -- Initialization Logic
    -- =========================================================================

    local validAnchorPoints = {
        TOP = true, BOTTOM = true, CENTER = true,
        LEFT = true, RIGHT = true,
        TOPLEFT = true, TOPRIGHT = true,
        BOTTOMLEFT = true, BOTTOMRIGHT = true,
    }

    -- Restore Anchor Position
    if Notifriend.Anchor and NotifriendDB.anchorPoint then
        if validAnchorPoints[NotifriendDB.anchorPoint] then
            Notifriend.Anchor:ClearAllPoints()
            Notifriend.Anchor:SetPoint(NotifriendDB.anchorPoint, UIParent, NotifriendDB.anchorPoint, NotifriendDB.anchorX, NotifriendDB.anchorY)
        else
            NotifriendDB.anchorPoint = Notifriend.defaults.anchorPoint
            NotifriendDB.anchorX = Notifriend.defaults.anchorX
            NotifriendDB.anchorY = Notifriend.defaults.anchorY
        end
    end

    -- Start AFK polling if enabled
    if NotifriendDB.enableAFK then
        Notifriend.StartAFKPolling()
    end
end

-- =========================================================================
-- Anchor Frame Definition
-- =========================================================================
Notifriend.Anchor = CreateFrame("Frame", "NotifriendAnchor", UIParent)
Notifriend.Anchor:SetSize(Notifriend.FRAME_WIDTH, 20)
Notifriend.Anchor:SetPoint(Notifriend.defaults.anchorPoint, UIParent, Notifriend.defaults.anchorPoint, Notifriend.defaults.anchorX, Notifriend.defaults.anchorY)
Notifriend.Anchor:SetClampedToScreen(true)
Notifriend.Anchor:SetMovable(true)
Notifriend.Anchor:EnableMouse(false)
Notifriend.Anchor:RegisterForDrag("LeftButton")
Notifriend.Anchor:Hide()

Notifriend.Anchor.bg = Notifriend.Anchor:CreateTexture(nil, "BACKGROUND")
Notifriend.Anchor.bg:SetAllPoints(true)
Notifriend.Anchor.bg:SetTexture(0, 1, 0, 0.5)

Notifriend.Anchor.text = Notifriend.Anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Notifriend.Anchor.text:SetPoint("CENTER")
Notifriend.Anchor.text:SetText("Notifriend Anchor")

Notifriend.Anchor:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

Notifriend.Anchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    NotifriendDB.anchorPoint = point
    NotifriendDB.anchorX = x
    NotifriendDB.anchorY = y
end)

print("Notifriend: Config loaded")
