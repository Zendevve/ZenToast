local pairs, string, table = pairs, string, table
local GetFriendInfo, GetNumFriends = GetFriendInfo, GetNumFriends
local PlaySound = PlaySound
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

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

local function ReanchorToasts()
    for i, toast in ipairs(activeToasts) do
        toast:ClearAllPoints()
        if i == 1 then
            toast:SetPoint("TOP", ZenToast.Anchor, "BOTTOM", 0, -ZenToast.SPACING)
        else
            toast:SetPoint("TOP", activeToasts[i-1], "BOTTOM", 0, -ZenToast.SPACING)
        end
    end
end

local function RecycleToast(toast)
    toast:Hide()
    toast:SetAlpha(0)
    toast.animState = "HIDDEN"
    table.insert(toastPool, toast)

    -- Remove from active list
    for i, t in ipairs(activeToasts) do
        if t == toast then
            table.remove(activeToasts, i)
            break
        end
    end
    ReanchorToasts()
end

local function CreateToastFrame()
    local Toast = CreateFrame("Button", nil, UIParent)
    Toast:SetSize(ZenToast.FRAME_WIDTH, ZenToast.FRAME_HEIGHT)
    Toast:SetFrameStrata("FULLSCREEN_DIALOG")
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
    Toast.Icon:SetSize(ZenToast.FRAME_HEIGHT - 4, ZenToast.FRAME_HEIGHT - 4)
    Toast.Icon:SetPoint("LEFT", 2, 0)

    -- Faction Icon (overlay on class icon)
    Toast.FactionIcon = Toast:CreateTexture(nil, "OVERLAY")
    Toast.FactionIcon:SetSize(18, 18)
    Toast.FactionIcon:SetPoint("BOTTOMRIGHT", Toast.Icon, "BOTTOMRIGHT", 2, -2)

    -- Aesthetic: Text
    Toast.Text = Toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Toast.Text:SetPoint("TOPLEFT", Toast.Icon, "TOPRIGHT", 10, -2)
    Toast.Text:SetJustifyH("LEFT")

    Toast.SubText = Toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    Toast.SubText:SetPoint("TOPLEFT", Toast.Text, "BOTTOMLEFT", 0, -2)
    Toast.SubText:SetJustifyH("LEFT")

    -- Click Handler
    Toast:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    Toast:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if FriendsFrame_ShowDropdown then
                FriendsFrame_ShowDropdown(self.name, 1)
            end
        else
            if self.name then
                ChatFrame_OpenChat("/w " .. self.name .. " ")
            end
        end
        RecycleToast(self)
    end)

    -- Animation Logic
    Toast.animTime = 0
    Toast.animState = "HIDDEN"

    Toast:SetScript("OnUpdate", function(self, elapsed)
        if self.animState == "HIDDEN" then return end

        self.animTime = self.animTime + elapsed

        if self.animState == "FADEIN" then
            local alpha = self.animTime / ZenToast.FADE_DURATION
            if alpha >= 1 then
                alpha = 1
                self.animState = "HOLD"
                self.animTime = 0
            end
            self:SetAlpha(alpha)
        elseif self.animState == "HOLD" then
            if self.animTime >= ZenToast.TOAST_DURATION then
                self.animState = "FADEOUT"
                self.animTime = 0
            end
        elseif self.animState == "FADEOUT" then
            local alpha = 1 - (self.animTime / ZenToast.FADE_DURATION)
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

function ZenToast.ShowToast(name, isOnline, debugClass)
    -- 1. Combat Suppression
    if InCombatLockdown() then return end

    -- 2. Instance Suppression
    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "raid" and ZenToastDB.hideInRaid then return end
        if instanceType == "pvp" and ZenToastDB.hideInBG then return end -- Battleground
        if instanceType == "arena" and ZenToastDB.hideInArena then return end
    end

    -- 3. Play Sound
    PlaySound("igQuestLogOpen")

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
        for i = 1, GetNumFriends() do
            local fName, fLevel, fClass, fArea, fConnected = GetFriendInfo(i)
            if fName and fName == name then
                level = fLevel or "??"
                class = fClass or "Unknown"
                area = fArea or "Unknown"

                if fClass then
                    -- Normalize class to English uppercase
                    local englishClass = ZenToast.GetEnglishClass(fClass)
                    if englishClass and englishClass ~= "Unknown" then
                        class = englishClass
                        local color = RAID_CLASS_COLORS[class]
                        if color then
                            classColor = color.colorStr
                        end
                    else
                         -- Fallback if lookup fails (shouldn't happen with valid classes)
                         class = fClass
                    end
                end
                break
            end
        end
    end

    -- 5. Setup Toast
    local toast = GetToast()
    toast.name = name

    -- Extract class color for border
    local borderR, borderG, borderB = 0.5, 0.5, 0.5 -- Default gray
    if class ~= "Unknown" then
        local color = RAID_CLASS_COLORS[class]
        if color then
            borderR, borderG, borderB = color.r, color.g, color.b
        end
    end

    if isOnline then
        toast.Text:SetText("|c" .. classColor .. name .. "|r has come online")

        -- Build SubText dynamically based on display settings
        local subParts = {}
        if ZenToastDB.showLevel then
            table.insert(subParts, "Level " .. level)
        end
        if ZenToastDB.showClass then
            table.insert(subParts, class)
        end
        if ZenToastDB.showLocation then
            table.insert(subParts, area)
        end

        local subText = ""
        if #subParts > 0 then
            -- First line: Level and Class (if both shown)
            local firstLine = {}
            if ZenToastDB.showLevel then table.insert(firstLine, "Level " .. level) end
            if ZenToastDB.showClass then table.insert(firstLine, class) end

            if #firstLine > 0 then
                subText = table.concat(firstLine, " ")
            end

            -- Second line: Location
            if ZenToastDB.showLocation then
                if subText ~= "" then
                    subText = subText .. "\n" .. area
                else
                    subText = area
                end
            end
        end

        toast.SubText:SetText(subText)
        toast:SetBackdropBorderColor(borderR, borderG, borderB, 0.8)
    else
        toast.Text:SetText("|c" .. classColor .. name .. "|r")
        toast.SubText:SetText("Went Offline")
        toast:SetBackdropBorderColor(borderR, borderG, borderB, 0.5)
    end

    -- Icon Logic
    if ZenToastDB.showIcon then
        if ZenToastDB.useCustomIcons then
            -- Custom Icon Path: Interface\AddOns\ZenToast\Icons\CLASS.tga
            local customPath = "Interface\\AddOns\\ZenToast\\Icons\\" .. class .. ".tga"
            toast.Icon:SetTexture(customPath)
            toast.Icon:SetTexCoord(0, 1, 0, 1) -- Full image
        else
            -- Default Blizzard Icons
            local iconTexture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
            local coords = ZenToast.CLASS_ICON_TCOORDS[class]

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

    -- Faction Icon Logic (Class Based)
    if ZenToastDB.showFactionBadge then
        local faction = CLASS_FACTION[class]
        print("ZenToast Debug: Name=" .. name .. ", Class=" .. class .. ", Faction=" .. tostring(faction))

        if faction == "Alliance" then
            toast.FactionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
            toast.FactionIcon:SetTexCoord(0, 1, 0, 1)
            toast.FactionIcon:Show()
            print("ZenToast Debug: Showing Alliance icon")
        elseif faction == "Horde" then
            toast.FactionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
            toast.FactionIcon:SetTexCoord(0, 1, 0, 1)
            toast.FactionIcon:Show()
            print("ZenToast Debug: Showing Horde icon")
        else
            toast.FactionIcon:Hide()
            print("ZenToast Debug: Hiding faction icon (neutral class)")
        end
    else
        toast.FactionIcon:Hide()
    end

    toast:Show()
    toast:SetAlpha(0)
    toast.animState = "FADEIN"
    toast.animTime = 0

    -- 6. Stacking Logic
    table.insert(activeToasts, 1, toast)
    if #activeToasts > ZenToast.MAX_TOASTS then
        RecycleToast(activeToasts[#activeToasts])
    end
    ReanchorToasts()
end

print("ZenToast: Toast loaded")
