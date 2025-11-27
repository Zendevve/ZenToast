-- Namespace
ZenToast = {}

-- Configuration & Constants --
ZenToast.TOAST_DURATION = 4.0
ZenToast.FADE_DURATION = 0.5
ZenToast.FRAME_WIDTH = 250
ZenToast.FRAME_HEIGHT = 50
ZenToast.MAX_TOASTS = 3
ZenToast.POS_POINT = "TOP"
ZenToast.POS_X = 0
ZenToast.POS_Y = -150
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
    showIcon = true,
    showFactionBadge = true,
    showLevel = true,
    showClass = true,
    showLocation = true,
    anchorPoint = "TOP",
    anchorX = 0,
    anchorY = -150,
}

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
print("ZenToast: Core loaded")
