local pairs, string, table = pairs, string, table
local GetFriendInfo, GetNumFriends = GetFriendInfo, GetNumFriends
local GetNumGuildMembers, GetGuildRosterInfo = GetNumGuildMembers, GetGuildRosterInfo
local PlaySound = PlaySound
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GameTooltip = GameTooltip
local math_min, math_max = math.min, math.max

local MAX_WIDTH = 450

-- Faction mapping by class (uppercase)
local CLASS_FACTION = {
    SHAMAN = "Horde",
    PALADIN = "Alliance",
    -- Neutral classes
    WARRIOR = "Both",
    HUNTER = "Both",
    ROGUE = "Both",
    PRIEST = "Both",
    MAGE = "Both",
    WARLOCK = "Both",
    DRUID = "Both",
    DEATHKNIGHT = "Both"
}

-- Toast Pooling & Stacking
local activeToasts = {}
local toastPool = {}

local function BuildSubText(showLevel, showClass, showLocation, level, class, area)
    local firstLine = {}
    if showLevel then table.insert(firstLine, "Level " .. level) end
    if showClass then table.insert(firstLine, class) end

    local subText = #firstLine > 0 and table.concat(firstLine, " ") or ""

    if showLocation then
        if subText ~= "" then
            subText = subText .. "\n" .. area
        else
            subText = area
        end
    end

    return subText
end

local function ReanchorToasts()
    local growth = NotifriendDB.growthDirection or "DOWN"
    local point, relativePoint, offsetMult

    if growth == "DOWN" then
        point = "TOP"
        relativePoint = "BOTTOM"
        offsetMult = -1
    else
        point = "BOTTOM"
        relativePoint = "TOP"
        offsetMult = 1
    end

    for i, toast in ipairs(activeToasts) do
        toast:ClearAllPoints()
        if i == 1 then
            toast:SetPoint(point, Notifriend.Anchor, relativePoint, 0, Notifriend.SPACING * offsetMult)
        else
            toast:SetPoint(point, activeToasts[i-1], relativePoint, 0, Notifriend.SPACING * offsetMult)
        end
    end
end

local function RecycleToast(toast)
    toast:Hide()
    toast:SetAlpha(0)
    toast.animState = "HIDDEN"
    toast:SetScript("OnUpdate", nil)
    table.insert(toastPool, toast)

    for i, t in ipairs(activeToasts) do
        if t == toast then
            activeToasts[i] = activeToasts[#activeToasts]
            activeToasts[#activeToasts] = nil
            break
        end
    end
    ReanchorToasts()
end

local function CreateToastFrame()
    local Toast = CreateFrame("Button", nil, UIParent)
    Toast:SetSize(Notifriend.FRAME_WIDTH, Notifriend.FRAME_HEIGHT)
    Toast:SetFrameStrata("FULLSCREEN_DIALOG")
    Toast:SetClampedToScreen(true)
    Toast:Hide()
    Toast:SetAlpha(0)

    -- Aesthetic: Dark Background with thin border
    Toast:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    Toast:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    Toast:SetBackdropBorderColor(0, 0, 0, 1)

    -- Aesthetic: Icon
    Toast.Icon = Toast:CreateTexture(nil, "ARTWORK")
    Toast.Icon:SetSize(Notifriend.FRAME_HEIGHT - 4, Notifriend.FRAME_HEIGHT - 4)
    Toast.Icon:SetPoint("LEFT", 2, 0)

    -- Faction Icon (overlay on class icon)
    Toast.FactionIcon = Toast:CreateTexture(nil, "OVERLAY")
    Toast.FactionIcon:SetSize(18, 18)
    Toast.FactionIcon:SetPoint("BOTTOMRIGHT", Toast.Icon, "BOTTOMRIGHT", 2, -2)

    -- Aesthetic: Text
    Toast.Text = Toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Toast.Text:SetPoint("TOPLEFT", Toast.Icon, "TOPRIGHT", 10, -2)
    Toast.Text:SetJustifyH("LEFT")
    -- Toast.Text:SetWordWrap(false) -- Disable wrapping for dynamic width calculation

    Toast.SubText = Toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    Toast.SubText:SetPoint("TOPLEFT", Toast.Text, "BOTTOMLEFT", 0, -2)
    Toast.SubText:SetJustifyH("LEFT")

    -- Apply Scale
    local scale = NotifriendDB.scale or 1.0
    Toast:SetScale(scale)

    -- Click Handler
    Toast:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    Toast:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if FriendsFrame_ShowDropdown then
                FriendsFrame_ShowDropdown(self.name, 1)
            end
        elseif button == "MiddleButton" then
            for i = #activeToasts, 1, -1 do
                RecycleToast(activeToasts[i])
            end
            return
        else
            if self.name then
                ChatFrame_OpenChat("/w " .. self.name .. " ")
            end
        end
        RecycleToast(self)
    end)

    -- Hover Tooltip
    Toast:SetScript("OnEnter", function(self)
        if not self.tooltipData then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.tooltipData.name, 1, 1, 1)
        if self.tooltipData.level and self.tooltipData.level ~= "??" then
            GameTooltip:AddLine("Level " .. self.tooltipData.level .. " " .. self.tooltipData.class, 0.8, 0.8, 0.8)
        end
        if self.tooltipData.zone and self.tooltipData.zone ~= "Unknown" then
            GameTooltip:AddLine(self.tooltipData.zone, 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    Toast:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Animation Logic
    Toast.animTime = 0
    Toast.animState = "HIDDEN"

    Toast:SetScript("OnUpdate", function(self, elapsed)
        if self.animState == "HIDDEN" then return end

        self.animTime = self.animTime + elapsed
        local maxAlpha = NotifriendDB.opacity or 1.0
        local duration = NotifriendDB.toastDuration or 4.0

        if self.animState == "FADEIN" then
            local t = math_min(self.animTime / Notifriend.FADE_DURATION, 1)
            t = t * t * (3 - 2 * t)
            local alpha = t * maxAlpha
            if alpha >= maxAlpha then
                alpha = maxAlpha
                self.animState = "HOLD"
                self.animTime = 0
            end
            self:SetAlpha(alpha)
        elseif self.animState == "HOLD" then
            if self.animTime >= duration then
                self.animState = "FADEOUT"
                self.animTime = 0
            end
        elseif self.animState == "FADEOUT" then
            local t = math_min(self.animTime / Notifriend.FADE_DURATION, 1)
            t = t * t * (3 - 2 * t)
            local alpha = maxAlpha * (1 - t)
            if alpha <= 0 then
                RecycleToast(self)
            else
                self:SetAlpha(alpha)
            end
        end
    end)

    return Toast
end

local function GetToast()
    local toast = table.remove(toastPool)
    if not toast then
        toast = CreateToastFrame()
    end
    return toast
end

function Notifriend.ShowToast(name, isOnline, debugClass, statusType, isGuild)
    -- statusType: nil (normal online/offline), "afk" (went AFK), "away" (returned from AFK)
    -- isGuild: boolean (true if triggered by guild event)
    -- 1. Combat Suppression
    if InCombatLockdown() then return end

    -- 2. Instance Suppression
    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "raid" and NotifriendDB.hideInRaid then return end
        if instanceType == "pvp" and NotifriendDB.hideInBG then return end -- Battleground
        if instanceType == "arena" and NotifriendDB.hideInArena then return end
    end

    -- 3. Play Sound
    if NotifriendDB.playSound then
        if isOnline or statusType then
            PlaySound(NotifriendDB.soundFile or "igQuestLogOpen")
        else
            PlaySound(NotifriendDB.soundFileOffline or "igQuestLogClose")
        end
    end

    -- 4. Fetch Data
    local classColor = "ffffffff"
    local level = "??"
    local class = "Unknown"
    local area = "Unknown"

    if debugClass then
        class = debugClass
        level = "80"
        area = "Test Zone"
        local color = RAID_CLASS_COLORS[class]
        if color then classColor = color.colorStr end
    else
        if isGuild then
            local key = name:lower()
            local cached = Notifriend.guildCache[key]
            if not cached then
                for k, v in pairs(Notifriend.guildCache) do
                    if k:sub(1, #key + 1) == key .. "-" then
                        cached = v
                        break
                    end
                end
            end
            if cached then
                level = cached.level or "??"
                class = cached.class or "Unknown"
                area = cached.zone or "Unknown"
                if class ~= "Unknown" then
                    local color = RAID_CLASS_COLORS[class]
                    if color then classColor = color.colorStr end
                end
            end
        else
            local cached = Notifriend.friendCache[name:lower()]
            if cached then
                level = cached.level or "??"
                class = cached.class or "Unknown"
                area = cached.zone or "Unknown"
                if class ~= "Unknown" then
                    local color = RAID_CLASS_COLORS[class]
                    if color then classColor = color.colorStr end
                end
            end
        end
    end

    -- 5. Setup Toast
    local toast = GetToast()
    toast.name = name
    toast.tooltipData = { name = name, class = class, level = level, zone = area }

    -- Update scale in case it changed
    local scale = NotifriendDB.scale or 1.0
    toast:SetScale(scale)

    -- Extract class color for border
    local borderR, borderG, borderB = 0.5, 0.5, 0.5 -- Default gray
    if class ~= "Unknown" then
        local color = RAID_CLASS_COLORS[class]
        if color then
            borderR, borderG, borderB = color.r, color.g, color.b
        end
    end

    -- Determine which settings to use based on status type
    local useOfflineSettings = (not isOnline and not statusType)
    local base = useOfflineSettings and "Offline" or ""
    local function s(key) return NotifriendDB["show" .. key .. base] end

    local showIconSetting = s("Icon")
    local showFactionSetting = s("FactionBadge")
    local showLevelSetting = s("Level")
    local showClassSetting = s("Class")
    local showLocationSetting = s("Location")

    -- Set main text based on status type
    local nameText = "|c" .. classColor .. name .. "|r"
    if isGuild then
        nameText = nameText .. " |cff00ff00[Guild]|r"
    end

    if statusType == "afk" then
        toast.Text:SetText(nameText .. " is now AFK")
    elseif statusType == "dnd" then
        toast.Text:SetText(nameText .. " is now DND")
    elseif statusType == "undnd" or statusType == "away" then
        toast.Text:SetText(nameText .. " is no longer " .. (statusType == "undnd" and "DND" or "AFK"))
    elseif isOnline then
        toast.Text:SetText(nameText .. " has come online")
    else
        toast.Text:SetText(nameText .. " went offline")
    end

    -- Build SubText dynamically
    if statusType == "afk" or statusType == "dnd" or statusType == "undnd" or statusType == "away" then
        toast.SubText:SetText(BuildSubText(NotifriendDB.showLevel, NotifriendDB.showClass, NotifriendDB.showLocation, level, class, area))
        toast:SetBackdropBorderColor(borderR, borderG, borderB, 0.6)
    elseif isOnline then
        toast.SubText:SetText(BuildSubText(showLevelSetting, showClassSetting, showLocationSetting, level, class, area))
        toast:SetBackdropBorderColor(borderR, borderG, borderB, 0.8)
    else
        toast.SubText:SetText(BuildSubText(showLevelSetting, showClassSetting, showLocationSetting, level, class, area))
        toast:SetBackdropBorderColor(borderR, borderG, borderB, 0.5)
    end

    -- Icon Logic (use appropriate setting)
    if showIconSetting then
        if NotifriendDB.useCustomIcons then
            -- Custom Icon Path: Interface\AddOns\Notifriend\Icons\CLASS.tga
            local customPath = "Interface\\AddOns\\Notifriend\\Icons\\" .. class .. ".tga"
            toast.Icon:SetTexture(customPath)
            toast.Icon:SetTexCoord(0, 1, 0, 1) -- Full image
        else
            -- Default Blizzard Icons
            local iconTexture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
            local coords = Notifriend.CLASS_ICON_TCOORDS[class]

            if coords then
                toast.Icon:SetTexture(iconTexture)
                toast.Icon:SetTexCoord(unpack(coords))
            else
                -- Fallback: Use a generic icon
                toast.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                toast.Icon:SetTexCoord(0, 1, 0, 1)
            end
        end
        toast.Icon:Show()
    else
        toast.Icon:Hide()
    end

    -- Faction Icon Logic (use appropriate setting)
    if showFactionSetting then
        local faction = CLASS_FACTION[class]

        if faction == "Alliance" then
            toast.FactionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
            toast.FactionIcon:SetTexCoord(0, 1, 0, 1)
            toast.FactionIcon:Show()
        elseif faction == "Horde" then
            toast.FactionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
            toast.FactionIcon:SetTexCoord(0, 1, 0, 1)
            toast.FactionIcon:Show()
        else
            toast.FactionIcon:Hide()
        end
    else
        toast.FactionIcon:Hide()
    end

    toast:Show()
    toast:SetAlpha(0)
    toast.animState = "FADEIN"
    toast.animTime = 0

    -- 6. Dynamic Width Calculation
    local iconWidth = Notifriend.FRAME_HEIGHT - 4
    local padding = 20 -- Left + Right padding
    local textPadding = 10 -- Spacing between icon and text

    -- Force string update to get accurate width
    toast.Text:SetWidth(0) -- Allow auto-width to measure
    toast.SubText:SetWidth(0)

    local textWidth = toast.Text:GetStringWidth()
    local subTextWidth = toast.SubText:GetStringWidth()
    local maxWidth = math.max(textWidth, subTextWidth)

    local requiredWidth = iconWidth + textPadding + maxWidth + padding
    local minWidth = 200 -- Reduced minimum width for tighter fit

    -- Clamp to min width, allow expansion
    local finalWidth = math_min(MAX_WIDTH, math_max(minWidth, requiredWidth))
    toast:SetWidth(finalWidth)

    -- Re-constrain text to new width (minus icon and padding)
    toast.Text:SetWidth(finalWidth - iconWidth - textPadding - padding)
    toast.SubText:SetWidth(finalWidth - iconWidth - textPadding - padding)

    -- 7. Stacking Logic
    table.insert(activeToasts, 1, toast)
    local maxToasts = NotifriendDB.maxToasts or 3
    if #activeToasts > maxToasts then
        RecycleToast(activeToasts[#activeToasts])
    end
    ReanchorToasts()
end

print("Notifriend: Toast loaded")
