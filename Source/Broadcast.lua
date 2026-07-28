local GetFriendInfo, GetNumFriends = GetFriendInfo, GetNumFriends
local SendChatMessage = SendChatMessage
local C_Timer_After = C_Timer.After
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

local broadcastQueue = {}
local broadcastSent = 0
local broadcastTotal = 0
local broadcastActive = false

local function ProcessBroadcastQueue()
    if #broadcastQueue == 0 then
        broadcastActive = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff0099ffNotifriend:|r Broadcast complete. Sent to " .. broadcastSent .. "/" .. broadcastTotal .. " friends.")
        return
    end

    local name = table.remove(broadcastQueue, 1)
    SendChatMessage(broadcastQueue.text, "WHISPER", nil, name)
    broadcastSent = broadcastSent + 1

    if broadcastSent % 5 == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff0099ffNotifriend:|r Broadcast progress: " .. broadcastSent .. "/" .. broadcastTotal)
    end

    local delay = NotifriendDB.broadcastDelay or 1.5
    C_Timer_After(delay, ProcessBroadcastQueue)
end

function Notifriend.InitBroadcast()
    local BROADCAST_PLACEHOLDER = "Broadcast to friends..."

    local function Broadcast_OnEnterPressed(self)
        local text = self:GetText()
        if not text or text == "" or text == BROADCAST_PLACEHOLDER then return end

        local count = GetNumFriends()
        if count < 1 then return end

        if broadcastActive then
            broadcastQueue = {}
            broadcastActive = false
            DEFAULT_CHAT_FRAME:AddMessage("|cff0099ffNotifriend:|r Previous broadcast cancelled.")
        end

        broadcastQueue.text = text
        broadcastSent = 0
        broadcastTotal = 0

        for i = 1, count do
            local name, _, _, _, connected = GetFriendInfo(i)
            if connected then
                broadcastTotal = broadcastTotal + 1
                broadcastQueue[broadcastTotal] = name
            end
        end

        if broadcastTotal == 0 then return end

        broadcastActive = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff0099ffNotifriend:|r Broadcasting to " .. broadcastTotal .. " friends...")

        self:SetText("")
        self:ClearFocus()
        self:SetText(BROADCAST_PLACEHOLDER)
        self:SetTextColor(0.5, 0.5, 0.5)

        ProcessBroadcastQueue()
    end

    local function Broadcast_OnEditFocusGained(self)
        if self:GetText() == BROADCAST_PLACEHOLDER then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
        end
    end

    local function Broadcast_OnEditFocusLost(self)
        if self:GetText() == "" then
            self:SetText(BROADCAST_PLACEHOLDER)
            self:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    if FriendsFrameBroadcastInput then
        FriendsFrameBroadcastInput:SetScript("OnEnterPressed", Broadcast_OnEnterPressed)
        FriendsFrameBroadcastInput:SetScript("OnEditFocusGained", Broadcast_OnEditFocusGained)
        FriendsFrameBroadcastInput:SetScript("OnEditFocusLost", Broadcast_OnEditFocusLost)

        FriendsFrameBroadcastInput:Show()
        FriendsFrameBroadcastInput.Hide = function() end

        FriendsFrameBroadcastInput:SetText(BROADCAST_PLACEHOLDER)
        FriendsFrameBroadcastInput:SetTextColor(0.5, 0.5, 0.5)
    end
end
