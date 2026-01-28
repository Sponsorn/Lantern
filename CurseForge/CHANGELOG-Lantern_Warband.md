# Changelog

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
