-- Namespace
ZenToast = {}

-- Configuration & Constants --
ZenToast.FRAME_WIDTH = 250
ZenToast.FRAME_HEIGHT = 50
ZenToast.FADE_DURATION = 0.5
ZenToast.SPACING = 10

-- Class Icon Coordinates (Standard WoW Coords)
ZenToast.CLASS_ICON_TCOORDS = {
    WARRIOR     = {0, 0.25, 0, 0.25},
    MAGE        = {0.25, 0.5, 0, 0.25},
    ROGUE       = {0.5, 0.75, 0, 0.25},
    DRUID       = {0.75, 1, 0, 0.25},
    HUNTER      = {0, 0.25, 0.25, 0.5},
    SHAMAN      = {0.25, 0.5, 0.25, 0.5},
    PRIEST      = {0.5, 0.75, 0.25, 0.5},
    WARLOCK     = {0.75, 1, 0.25, 0.5},
    PALADIN     = {0, 0.25, 0.5, 0.75},
    DEATHKNIGHT = {0.25, 0.5, 0.5, 0.75},
}

-- Helper: Get English Class Name from Localized Name
local localizedClassMap = {}
do
    local genderTable = { "MALE", "FEMALE" }
    for _, gender in ipairs(genderTable) do
        FillLocalizedClassList(localizedClassMap, gender == "FEMALE")
    end
end

function ZenToast.GetEnglishClass(localizedClass)
    if not localizedClass then return "Unknown" end
    -- Reverse lookup from localized map
    for english, localized in pairs(localizedClassMap) do
        if localized == localizedClass then
            return english
        end
    end
    return "Unknown"
end

-- Defaults
ZenToast.defaults = {
    hideInRaid = false,
    hideInBG = false,
    hideInArena = false,
    useCustomIcons = false,
    -- Online Display Options
    showIcon = true,
    showFactionBadge = true,
    showLevel = true,
    showClass = true,
    showLocation = true,
    -- Offline Display Options
    showIconOffline = true,
    showFactionBadgeOffline = false,
    showLevelOffline = true,
    showClassOffline = true,
    showLocationOffline = true,
    -- AFK Detection
    enableAFK = false,
    afkPollInterval = 3,
    anchorPoint = "TOP",
    anchorX = 0,
    anchorY = -150,
    -- General Customization
    scale = 1.0,
    opacity = 1.0,
    toastDuration = 4.0,
    maxToasts = 3,
    playSound = true,
    growthDirection = "DOWN",
}

-- AFK Status Tracking
ZenToast.friendAFKStatus = {}
ZenToast.afkPollTimer = nil

-- Event Frame
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ZenToast" then
        if not ZenToastDB then ZenToastDB = {} end

        for k, v in pairs(ZenToast.defaults) do
            if ZenToastDB[k] == nil then ZenToastDB[k] = v end
        end
        self:UnregisterEvent("ADDON_LOADED")

        -- Initialize Modules
        if ZenToast.InitConfig then ZenToast.InitConfig() end
        if ZenToast.InitBroadcast then ZenToast.InitBroadcast() end
    end
end)

-- Chat Filter (Hide System Msg, Trigger Toast)
local patternOnline = ERR_FRIEND_ONLINE_SS:gsub("%%s", "(.+)"):gsub("%[", "%%["):gsub("%]","%%]")
local patternOffline = ERR_FRIEND_OFFLINE_S:gsub("%%s", "(.+)"):gsub("%[", "%%["):gsub("%]","%%]")

local function ChatFilter(self, event, msg, ...)
    local name = msg:match(patternOnline)
    if name then
        if ZenToast.ShowToast then
            local success, err = pcall(ZenToast.ShowToast, name, true)
            if not success then
                print("ZenToast Error (Online): " .. tostring(err))
            end
        else
            print("ZenToast Error: ShowToast is nil")
        end
        return true -- Block original message
    end

    name = msg:match(patternOffline)
    if name then
        if ZenToast.ShowToast then
            local success, err = pcall(ZenToast.ShowToast, name, false)
            if not success then
                print("ZenToast Error (Offline): " .. tostring(err))
            end
        else
            print("ZenToast Error: ShowToast is nil")
        end
        return true -- Block original message
    end

    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)

-- AFK Status Polling
function ZenToast.CheckAFKStatus()
    if not ZenToastDB.enableAFK then return end

    for i = 1, GetNumFriends() do
        local name, _, _, _, connected, status = GetFriendInfo(i)
        if name and connected then
            local currentStatus = status or "" -- "<AFK>" or "<DND>" or ""
            local isAFK = (currentStatus == "<AFK>")
            local wasPreviouslyAFK = ZenToast.friendAFKStatus[name]

            if wasPreviouslyAFK == nil then
                -- First time seeing this friend, record their status
                ZenToast.friendAFKStatus[name] = isAFK
            elseif wasPreviouslyAFK ~= isAFK then
                -- Status changed!
                ZenToast.friendAFKStatus[name] = isAFK
                if ZenToast.ShowToast then
                    if isAFK then
                        ZenToast.ShowToast(name, true, nil, "afk")
                    else
                        ZenToast.ShowToast(name, true, nil, "away")
                    end
                end
            end
        else
            -- Friend disconnected, clear their status
            if name then
                ZenToast.friendAFKStatus[name] = nil
            end
        end
    end
end

function ZenToast.StartAFKPolling()
    if ZenToast.afkPollTimer then
        ZenToast.afkPollTimer:Cancel()
    end

    local pollFrame = CreateFrame("Frame")
    pollFrame.elapsed = 0
    pollFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= ZenToastDB.afkPollInterval then
            self.elapsed = 0
            ZenToast.CheckAFKStatus()
        end
    end)

    ZenToast.afkPollTimer = pollFrame
end

function ZenToast.StopAFKPolling()
    if ZenToast.afkPollTimer then
        ZenToast.afkPollTimer:SetScript("OnUpdate", nil)
        ZenToast.afkPollTimer = nil
    end
    -- Clear tracking table
    ZenToast.friendAFKStatus = {}
end

print("ZenToast: Core loaded")
