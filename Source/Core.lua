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

-- Debug Print Helper Function
function ZenToast.DebugPrint(message)
    if ZenToastDB and ZenToastDB.debugMessages then
        print("|cff00ff00ZenToast Debug:|r " .. tostring(message))
    end
end

-- Defaults
ZenToast.defaults = {
    hideInRaid = false,
    hideInBG = false,
    hideInArena = false,
    hideGuildToasts = false,
    useCustomIcons = false,
    hideChatMessages = true,
    -- Enable/Disable Toasts
    enableOnlineToasts = true,
    enableOfflineToasts = true,
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
    debugMessages = false,
}

-- AFK Status Tracking
ZenToast.friendAFKStatus = {}
ZenToast.afkPollTimer = nil

-- Event Frame
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ZenToast" then
        if not ZenToastDB then ZenToastDB = {} end

        for k, v in pairs(ZenToast.defaults) do
            if ZenToastDB[k] == nil then ZenToastDB[k] = v end
        end

        -- Initialize Modules
        if ZenToast.InitConfig then ZenToast.InitConfig() end
        if ZenToast.InitBroadcast then ZenToast.InitBroadcast() end
    elseif event == "PLAYER_LOGIN" then
        -- Guild Toasts will require SetGuildRosterShowOffline(true) its an api limitation
        if not ZenToastDB.hideGuildToasts then
            SetGuildRosterShowOffline(true)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- Chat Filter (Hide System Msg, Trigger Toast)
-- Generic patterns that match both friend and guild messages
local patternOnline = "(.+) has come online"
local patternOffline = "(.+) has gone offline"

-- Deduplication: WoW sometimes fires CHAT_MSG_SYSTEM twice for the same message
-- Use a simple flag-based system to block the immediate duplicate
local lastMessageHash = nil
local function GetMessageHash(msg, name)
    return msg .. ":" .. name
end

local function IsMessageDuplicate(msg, name)
    local hash = GetMessageHash(msg, name)
    if lastMessageHash == hash then
        return true
    end
    lastMessageHash = hash
    return false
end

function IsPlayerInGuild(playerName)
    for i = 1, GetNumGuildMembers() do
        local gName = GetGuildRosterInfo(i)
        if gName and gName == playerName then
            return true
        end
    end
    return false
end

function IsPlayerInFriends(playerName)
    for i = 1, GetNumFriends() do
        local fName = GetFriendInfo(i)
        if fName and fName == playerName then
            return true
        end
    end
    return false
end

local function ChatFilter(self, event, msg, ...)
    local name = msg:match(patternOnline)
    if name then
        -- Extract only what's between the brackets [PlayerName] if present, otherwise use as-is
        local bracketName = string.match(name, "%[(.-)%]")
        if bracketName then
            name = bracketName
        end
        ZenToast.DebugPrint("Online: " .. name)

        -- Determine type: Friends take priority over guild
        GuildRoster()
        local inFriends = IsPlayerInFriends(name)
        local inGuild = IsPlayerInGuild(name)

        local toastType
        if inFriends then
            toastType = "friend"
        elseif inGuild then
            toastType = "guild"
        else
            toastType = "unknown"
        end

        ZenToast.DebugPrint("  In Friends: " .. tostring(inFriends) .. ", In Guild: " .. tostring(inGuild) .. ", Type: " .. toastType)

        -- Skip guild-only toasts if hideGuildToasts is enabled
        if toastType == "guild" and ZenToastDB.hideGuildToasts then
            ZenToast.DebugPrint("  Guild-only toast suppressed by setting")
            return ZenToastDB.hideChatMessages
        end

        -- Skip all online toasts if enableOnlineToasts is disabled
        if not ZenToastDB.enableOnlineToasts then
            ZenToast.DebugPrint("  Online toasts disabled")
            return ZenToastDB.hideChatMessages
        end

        if not IsMessageDuplicate(msg, name) then
            if ZenToast.ShowToast then
                local success, err = pcall(ZenToast.ShowToast, name, true, nil, nil, toastType)
                if not success then
                    print("ZenToast Error (Online): " .. tostring(err))
                end
            else
                print("ZenToast Error: ShowToast is nil")
            end
        end
        return ZenToastDB.hideChatMessages
    end

    name = msg:match(patternOffline)
    if name then
        -- Extract only what's between the brackets [PlayerName] if present, otherwise use as-is
        local bracketName = string.match(name, "%[(.-)%]")
        if bracketName then
            name = bracketName
        end
        ZenToast.DebugPrint("Offline: " .. name)

        -- Determine type: Friends take priority over guild
        GuildRoster()
        local inFriends = IsPlayerInFriends(name)
        local inGuild = IsPlayerInGuild(name)

        local toastType
        if inFriends then
            toastType = "friend"
        elseif inGuild then
            toastType = "guild"
        else
            toastType = "unknown"
        end

        ZenToast.DebugPrint("  In Friends: " .. tostring(inFriends) .. ", In Guild: " .. tostring(inGuild) .. ", Type: " .. toastType)

        -- Skip guild-only toasts if hideGuildToasts is enabled
        if toastType == "guild" and ZenToastDB.hideGuildToasts then
            ZenToast.DebugPrint("  Guild-only toast suppressed by setting")
            return ZenToastDB.hideChatMessages
        end

        -- Skip all offline toasts if enableOfflineToasts is disabled
        if not ZenToastDB.enableOfflineToasts then
            ZenToast.DebugPrint("  Offline toasts disabled")
            return ZenToastDB.hideChatMessages
        end

        if not IsMessageDuplicate(msg, name) then
            if ZenToast.ShowToast then
                local success, err = pcall(ZenToast.ShowToast, name, false, nil, nil, toastType)
                if not success then
                    print("ZenToast Error (Offline): " .. tostring(err))
                end
            else
                print("ZenToast Error: ShowToast is nil")
            end
        end
        return ZenToastDB.hideChatMessages
    end

    return false
end

if not ZenToast.chatFilterRegistered then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)
    ZenToast.chatFilterRegistered = true
end

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