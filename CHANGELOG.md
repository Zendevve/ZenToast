# Changelog

All notable changes to ZenToast will be documented in this file.

## [1.1] - 2026-07-28

### Fixed
- Removed debug print statements that spammed chat on every toast
- Fixed cross-realm name pattern matching to avoid Lua pattern injection
- Fixed AFK polling frame leak by reusing a single frame
- Implemented broadcast rate limiting with configurable delay (1.5s default)
- Fixed O(n) toast removal with swap-and-pop optimization

### Added
- Hover tooltip showing name, class, level, and zone on toast hover
- Maximum width clamp (450px) for long toasts
- Smoothstep easing for fade-in and fade-out animations
- Slash commands: `/zentest` (test toast), `/zentest unlock` (toggle anchor), `/zentest lock`, `/zentest config`
- Configurable sound selection for online and offline toasts
- DND status tracking alongside AFK
- Middle-click to dismiss all active toasts
- Toasts clamped to screen bounds
- Anchor position validation on load
- Friend and guild name lookup cache (O(1) instead of linear scan)
- Guild roster pre-scan on PLAYER_LOGIN

### Changed
- Extracted SubText builder helper to reduce code duplication
- Deduplicated settings selection logic
- Added local API caches for performance
- Centralized version constant

## [1.0] - 2024-01-01

### Added
- Initial release with friend online/offline toast notifications
- Class icons and faction badges
- Configurable display options
- Movable anchor with position persistence
- Offline settings panel
- AFK detection
- Custom class icon support (TGA files)
- Broadcast to friends feature
