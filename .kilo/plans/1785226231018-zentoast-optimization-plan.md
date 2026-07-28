# ZenToast Optimization Plan

## Scope
Comprehensive fix of all 25 identified issues across the ZenToast WoW 3.3.5a addon codebase, organized into 4 implementation sprints.

## Sprint 1 — Bug Fixes (P1)

### 1.1 Remove debug print statements
**Files:** `Source/Toast.lua`
**What:** Delete the 4 `print("ZenToast Debug: ...")` calls at lines 413, 419, 421, 428. These spam the chat frame on every toast.

### 1.2 Fix cross-realm name pattern matching
**Files:** `Source/Toast.lua` line 204
**What:** Replace `gName:match("^" .. name .. "-")` with `gName:sub(1, #name + 1) == name .. "-"` to avoid Lua pattern metacharacter injection in player names.

### 1.3 Implement broadcast rate limiting
**Files:** `Source/Broadcast.lua`
**What:** Replace the synchronous loop with a throttled queue. Create a pending messages table. Send one whisper per 1.5 seconds via an OnUpdate frame. Track sent/total count and show progress in chat. Add configurable delay (default 1.5s) to `ZenToastDB`.

### 1.4 Fix AFK polling frame leak
**Files:** `Source/Core.lua`
**What:** Create the poll frame once at file scope. Reuse it by toggling `OnUpdate` on/off in `StartAFKPolling`/`StopAFKPolling` instead of creating new frames.

## Sprint 2 — Code Quality (P2)

### 2.1 Extract SubText builder helper
**Files:** `Source/Toast.lua`
**What:** Create `local function BuildSubText(showLevel, showClass, showLocation, level, class, area)` returning the subtext string. Replace the 3 duplicated blocks (lines 319-381) with calls to this helper.

### 2.2 Deduplicate settings selection
**Files:** `Source/Toast.lua`
**What:** Replace the 36-line if/else tree (lines 264-300) with a helper:
```lua
local base = useOfflineSettings and "Offline" or ""
local function s(key) return ZenToastDB["show" .. key .. base] end
```
Then call `s("Icon")`, `s("FactionBadge")`, etc.

### 2.3 Add missing local API caches
**Files:** `Source/Toast.lua`, `Source/Broadcast.lua`
**What:** Add at top of `Toast.lua`:
```lua
local GetNumGuildMembers, GetGuildRosterInfo = GetNumGuildMembers, GetGuildRosterInfo
```
Add at top of `Broadcast.lua`:
```lua
local SendChatMessage = SendChatMessage
```

### 2.4 Fix O(n) toast removal
**Files:** `Source/Toast.lua`
**What:** In `RecycleToast`, replace `table.remove(activeToasts, i)` with swap-and-pop:
```lua
activeToasts[i] = activeToasts[#activeToasts]
activeToasts[#activeToasts] = nil
```

### 2.5 Add friend/guild name lookup cache
**Files:** `Source/Core.lua`, `Source/Toast.lua`
**What:** Add `ZenToast.friendCache = {}` and `ZenToast.guildCache = {}`. Populate on `FRIENDLIST_UPDATE` and `GUILD_ROSTER_UPDATE` events. Key by lowercase name → `{class, level, zone}`. In `ShowToast`, do O(1) lookup instead of linear scan. Call `GuildRoster()` once on login if in guild.

## Sprint 3 — Features & UX (P3)

### 3.1 Add hover tooltip
**Files:** `Source/Toast.lua`
**What:** Add `OnEnter`/`OnLeave` scripts to `CreateToastFrame` that show `GameTooltip` with name, class, level, zone, and guild info.

### 3.2 Add maximum width clamp
**Files:** `Source/Toast.lua`
**What:** Add `local MAX_WIDTH = 450` constant. Clamp: `finalWidth = math.min(MAX_WIDTH, math.max(minWidth, requiredWidth))`.

### 3.3 Add eased animation
**Files:** `Source/Toast.lua`
**What:** Replace linear alpha interpolation with smoothstep: `t * t * (3 - 2 * t)` in both FADEIN and FADEOUT states.

### 3.4 Add slash commands
**Files:** `Source/Core.lua`
**What:** Register `SLASH_ZENTEST1 = "/zentest"`. Handler shows a test toast. Add `/zentest unlock` subcommand to toggle anchor.

### 3.5 Add sound selection
**Files:** `Source/Core.lua`, `Source/Config.lua`, `Source/Toast.lua`
**What:** Add `ZenToastDB.soundFile` (default `"igQuestLogOpen"`). Add dropdown in General settings with WoW sound IDs. Separate online/offline sound options. Use `PlaySound(ZenToastDB.soundFile)` in toast display.

### 3.6 Add DND status tracking
**Files:** `Source/Core.lua`, `Source/Toast.lua`
**What:** Extend `friendAFKStatus` to track `"<DND>"` as a third state. Add `statusType = "dnd"` / `"undnd"` toast types. Handle in `ShowToast` text generation.

### 3.7 Add dismiss all
**Files:** `Source/Toast.lua`
**What:** Add middle-click handler in `CreateToastFrame`'s `OnClick` that calls `RecycleToast` on all active toasts.

## Sprint 4 — Defensive & Polish (P4/P5/P6)

### 4.1 Clamp toasts to screen
**Files:** `Source/Toast.lua`
**What:** Add `Toast:SetClampedToScreen(true)` in `CreateToastFrame`.

### 4.2 Validate anchor position on load
**Files:** `Source/Config.lua`
**What:** Whitelist valid anchor points (`TOP`, `BOTTOM`, `CENTER`, `LEFT`, `RIGHT`, etc.). Fall back to defaults if invalid.

### 4.3 Guard InitConfig anchor dependency
**Files:** `Source/Config.lua`
**What:** Wrap anchor init block with `if ZenToast.Anchor then ... end`.

### 4.4 Disable OnUpdate for hidden toasts
**Files:** `Source/Toast.lua`
**What:** In `RecycleToast`, add `toast:SetScript("OnUpdate", nil)`. In `ShowToast` after checkout, restore the OnUpdate handler.

### 5.2 Add guild roster pre-scan
**Files:** `Source/Core.lua`
**What:** Call `GuildRoster()` once on `PLAYER_LOGIN` event if player is in a guild.

### 6.2 Centralize version constant
**Files:** `Source/Core.lua`, `Source/Config.lua`, `ZenToast.toc`
**What:** Add `ZenToast.VERSION = "1.1"` in Core.lua. Reference it in Config.lua for the UI display. Keep TOC version as-is (API limitation).

### 6.3 Add CHANGELOG.md
**Files:** New file `CHANGELOG.md`
**What:** Create a changelog documenting all versions from git history.

## Validation Plan

After each sprint:
1. Load the addon in WoW 3.3.5a client
2. Verify toast displays on friend online/offline
3. Verify guild toast displays and suppresses correctly
4. Test broadcast with multiple online friends (Sprint 1)
5. Test AFK/DND toggle (Sprint 3)
6. Test `/zentest` slash command (Sprint 3)
7. Test hover tooltip (Sprint 3)
8. Test anchor drag + position persistence (Sprint 4)
9. Verify no Lua errors in `/console reloadui` cycle
10. Verify SavedVariables round-trip correctly

## Key Constraints
- WoW 3.3.5a API only (no retail API calls)
- `C_Timer.After` IS available in 3.3.5a
- No external dependencies
- All changes must be backwards-compatible with existing SavedVariables
- Keep file load order: Core → Config → Toast → Broadcast
