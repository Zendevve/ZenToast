-- Namespace
Notifriend = {}
Notifriend.VERSION = "1.1"

-- Configuration & Constants --
Notifriend.FRAME_WIDTH = 250
Notifriend.FRAME_HEIGHT = 50
Notifriend.FADE_DURATION = 0.5
Notifriend.SPACING = 10

-- Class Icon Coordinates (Standard WoW Coords)
Notifriend.CLASS_ICON_TCOORDS = {
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

function Notifriend.GetEnglishClass(localizedClass)
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
Notifriend.defaults = {
    hideInRaid = true,
    hideInBG = false,
    hideInArena = true,
    useCustomIcons = false,
    -- Online Display Options
    showIcon = true,
    showFactionBadge = true,
    showGuildOnline = true, -- New: Guild Online
    showLevel = true,
    showClass = true,
    showLocation = true,
    -- Offline Display Options
    showIconOffline = true,
    showFactionBadgeOffline = true,
    showGuildOffline = true, -- New: Guild Offline
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
    broadcastDelay = 1.5,
    soundFile = "igQuestLogOpen",
    soundFileOffline = "igQuestLogClose",
}

-- AFK Status Tracking
Notifriend.friendAFKStatus = {} -- name -> "afk", "dnd", or nil

-- Name Lookup Cache
Notifriend.friendCache = {}
Notifriend.guildCache = {}

local function RebuildFriendCache()
    wipe(Notifriend.friendCache)
    for i = 1, GetNumFriends() do
        local name, level, class, zone, connected = GetFriendInfo(i)
        if name then
            local englishClass = Notifriend.GetEnglishClass(class)
            Notifriend.friendCache[name:lower()] = { class = englishClass, level = level, zone = zone }
        end
    end
end

local function RebuildGuildCache()
    wipe(Notifriend.guildCache)
    for i = 1, GetNumGuildMembers() do
        local name, _, _, level, _, zone, _, _, _, _, classFileName = GetGuildRosterInfo(i)
        if name then
            Notifriend.guildCache[name:lower()] = { class = classFileName, level = level, zone = zone }
        end
    end
end

-- AFK Poll Frame (created once, reused)
Notifriend.afkPollFrame = CreateFrame("Frame")
Notifriend.afkPollFrame.elapsed = 0
Notifriend.afkPollFrame:SetScript("OnUpdate", nil) -- Start disabled

-- Event Frame
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("FRIENDLIST_UPDATE")
EventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Notifriend" then
        if not NotifriendDB then NotifriendDB = {} end

        for k, v in pairs(Notifriend.defaults) do
            if NotifriendDB[k] == nil then NotifriendDB[k] = v end
        end
        self:UnregisterEvent("ADDON_LOADED")

        -- Initialize Modules
        if Notifriend.InitConfig then Notifriend.InitConfig() end
        if Notifriend.InitBroadcast then Notifriend.InitBroadcast() end
    elseif event == "FRIENDLIST_UPDATE" then
        RebuildFriendCache()
    elseif event == "GUILD_ROSTER_UPDATE" then
        RebuildGuildCache()
    elseif event == "PLAYER_LOGIN" then
        if IsInGuild() then
            GuildRoster()
        end
    end
end)

-- Chat Filter (Hide System Msg, Trigger Toast)
local patternOnline = ERR_FRIEND_ONLINE_SS:gsub("%%s", "(.+)"):gsub("%[", "%%["):gsub("%]","%%]")
local patternOffline = ERR_FRIEND_OFFLINE_S:gsub("%%s", "(.+)"):gsub("%[", "%%["):gsub("%]","%%]")
local patternGuildOnline = (ERR_GUILD_MEMBER_ONLINE_S or "%s has come online"):gsub("%%s", "(.+)"):gsub("%[", "%%["):gsub("%]","%%]")
local patternGuildOffline = (ERR_GUILD_MEMBER_OFFLINE_S or "%s has gone offline"):gsub("%%s", "(.+)"):gsub("%[", "%%["):gsub("%]","%%]")

local function ChatFilter(self, event, msg, ...)
    local name = msg:match(patternOnline)
    if name then
        if Notifriend.ShowToast then
            local success, err = pcall(Notifriend.ShowToast, name, true)
            if not success then
                print("Notifriend Error (Online): " .. tostring(err))
            end
        else
            print("Notifriend Error: ShowToast is nil")
        end
        return true -- Block original message
    end

    name = msg:match(patternOffline)
    if name then
        if Notifriend.ShowToast then
            local success, err = pcall(Notifriend.ShowToast, name, false)
            if not success then
                print("Notifriend Error (Offline): " .. tostring(err))
            end
        else
            print("Notifriend Error: ShowToast is nil")
        end
        return true -- Block original message
    end

    -- Guild Online
    name = msg:match(patternGuildOnline)
    if name then
        if NotifriendDB.showGuildOnline then
            if Notifriend.ShowToast then
                local success, err = pcall(Notifriend.ShowToast, name, true, nil, nil, true) -- isGuild = true
                if not success then
                    print("Notifriend Error (Guild Online): " .. tostring(err))
                end
            end
            return true -- Block original message
        end
    end

    -- Guild Offline
    name = msg:match(patternGuildOffline)
    if name then
        if NotifriendDB.showGuildOffline then
            if Notifriend.ShowToast then
                local success, err = pcall(Notifriend.ShowToast, name, false, nil, nil, true) -- isGuild = true
                if not success then
                    print("Notifriend Error (Guild Offline): " .. tostring(err))
                end
            end
            return true -- Block original message
        end
    end

    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)

-- AFK Status Polling
function Notifriend.CheckAFKStatus()
    if not NotifriendDB.enableAFK then return end

    for i = 1, GetNumFriends() do
        local name, _, _, _, connected, status = GetFriendInfo(i)
        if name and connected then
            local currentStatus = status or ""
            local statusType = nil
            if currentStatus == "<AFK>" then
                statusType = "afk"
            elseif currentStatus == "<DND>" then
                statusType = "dnd"
            end

            local wasPreviousStatus = Notifriend.friendAFKStatus[name]

            if wasPreviousStatus == nil then
                Notifriend.friendAFKStatus[name] = statusType
            elseif wasPreviousStatus ~= statusType then
                Notifriend.friendAFKStatus[name] = statusType
                if Notifriend.ShowToast then
                    if statusType == "afk" then
                        Notifriend.ShowToast(name, true, nil, "afk")
                    elseif statusType == "dnd" then
                        Notifriend.ShowToast(name, true, nil, "dnd")
                    elseif wasPreviousStatus == "afk" then
                        Notifriend.ShowToast(name, true, nil, "undnd")
                    elseif wasPreviousStatus == "dnd" then
                        Notifriend.ShowToast(name, true, nil, "undnd")
                    end
                end
            end
        else
            if name then
                Notifriend.friendAFKStatus[name] = nil
            end
        end
    end
end

function Notifriend.StartAFKPolling()
    Notifriend.afkPollFrame.elapsed = 0
    Notifriend.afkPollFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= NotifriendDB.afkPollInterval then
            self.elapsed = 0
            Notifriend.CheckAFKStatus()
        end
    end)
end

function Notifriend.StopAFKPolling()
    Notifriend.afkPollFrame:SetScript("OnUpdate", nil)
    Notifriend.friendAFKStatus = {}
end

-- Slash Commands
SLASH_ZENTEST1 = "/zentest"
SlashCmdList["ZENTEST"] = function(msg)
    msg = msg:lower():trim()
    if msg == "unlock" then
        if Notifriend.Anchor:IsShown() then
            Notifriend.Anchor:Hide()
            Notifriend.Anchor:EnableMouse(false)
        else
            Notifriend.Anchor:Show()
            Notifriend.Anchor:EnableMouse(true)
        end
    elseif msg == "lock" then
        Notifriend.Anchor:Hide()
        Notifriend.Anchor:EnableMouse(false)
    elseif msg == "config" then
        InterfaceOptionsFrame_OpenToCategory("Notifriend")
    else
        if Notifriend.ShowToast then
            Notifriend.ShowToast("TestUser", true, "MAGE")
        end
    end
end

print("Notifriend: Core loaded")
