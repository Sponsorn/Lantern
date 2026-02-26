# Changelog

## 0.4.1
- Fix: Warehousing engine looping indefinitely when warbank is full instead of stopping after retries
- Fix: Warehousing panel now uses the game's default fonts instead of Roboto Bold

## 0.4.0 - 2026-02-23
- Add: Full localization support — all user-facing strings extracted to locale files with English as the base, 10 additional languages ready for community translations
- Add: Automated release pipeline — GitHub Actions with BigWigs packager for CurseForge uploads and localization substitution

## 0.3.3 - 2026-02-21
- Fix: Warehousing panel close button causing an error
- Change: Warehousing panel now uses Roboto font to match the settings panel theme

## 0.3.2 - 2026-02-18
- Change: Settings now use a custom UI panel (LanternUX) instead of the Blizzard options interface
- Remove: Old warehousing settings panel replaced by LanternUX Warehousing page
- Change: Warehousing Settings button now opens the main settings panel
- Change: LanternUX is now a required dependency (previously optional)

## 0.3.1 - 2026-02-11
- Change: Warehousing engine now uses event-driven move confirmation instead of polling, for faster and more reliable item transfers
- Change: Full-stack deposits use Blizzard's deposit API for improved reliability and automatic stacking
- Fix: Items are less prone to get "frozen" when server-side moves complete between poll cycles
- Fix: Silent deposit failures (e.g. warbank full) are now detected within 200ms
- Change: More generous timeouts for warbank operations (5s base, up from 2s)
- Change: Less aggressive stall detection with exponential backoff retry delays
- Fix: Progress bar not updating during warbank deposits due to false failure detection on slow server responses
- Fix: Progress bar fill extending outside its border frame
- Change: Progress bar now uses casting bar fill texture for a smoother look

## 0.3.0b - 2026-02-01
- Fix zip file not extracting as folder on macOS/Linux (GitHub issue #2)

## 0.3.0 - 2026-01-28
- Warehousing UI redesign, hopefully more intuitive than beta version; separate Settings panel for group management
- Operations panel simplified: shows groups with checkboxes and item counts
- New Settings button opens dedicated panel for creating/editing groups
- Restyled Settings panel
- Added "All" option for deposit and restock to move all matching items
- Keep limit now applies independently: preserves a minimum in bags (when depositing) or warbank (when restocking)
- Existing groups should be automatically migrated to the new settings format

## 0.2.10 - 2026-01-28
- Improved options UI layout and consistency

## 0.2.9 - 2026-01-25
- Remember warehousing panel open state across bank sessions
- Fix retry logic: operations with failures now properly retry instead of triggering stall counter
- Store group selection per character instead of account-wide
- Show/hide panel when switching between bank tabs

## 0.2.8 - 2026-01-25
- Reorganize warehousing files into Warehousing/ folder (Data.lua, Engine.lua, UI.lua, Options.lua)

## 0.2.7 - 2026-01-25
- Split Options.lua into Options.lua, OptionsGroups.lua, OptionsWarehousing.lua

## 0.2.6 - 2026-01-24
- Redesign warehousing to group-based system (groups with items, limit, deposit mode)
- Add warehousing UI panel anchored to bank frame with per-group deposit/restock buttons
- Add group management in options (create/delete groups, add/remove items, configure limit/mode)
- Persist group selection state between sessions
- Add cogwheel options button on warehousing panel
- Add batch progress bar with "Restock/Deposit: Batch x/x, Items x/x" format
- Auto-hide progress bar after completion
- Fix batch processing: failed items no longer cascade to future batches
- Add source bag range validation to prevent wrong-direction moves
- Add per-operation retry logic (max 3 retries before permanent failure)
- Add batch settle delay to prevent stale re-scans after moves confirm
- Increase move timeout per item for unstacked items
