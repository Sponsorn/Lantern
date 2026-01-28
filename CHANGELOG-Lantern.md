# Changelog

## 0.4.26 - 2026-01-28
- Core: defer options panel opening if clicked during combat (opens automatically after combat)
- OptionsLayout: add editableField helper for display + edit button pattern
- OptionsLayout: add staticPopupInput helper for text input dialogs

## 0.4.25 - 2026-01-28
- Add MissingPet module: displays a warning when your pet is missing or set to passive
- Add TextAnimations utility library with reusable animation styles (bounce, pulse, fade, shake, glow, heartbeat)
- Add OptionsLayout utility library for reusable AceConfig multi-column layouts
- MissingPet: customizable text, colors, fonts, animations, and optional sound alerts
- MissingPet: auto-hides while mounted or in rest zones (visible during combat)
- MissingPet: smart detection for Hunters, Warlocks, Unholy DKs, and Frost Mages
- MissingPet: Marksmanship Hunters only trigger warning if pet talent (Unbreakable Bond) is selected
- MissingPet: refreshes warning on talent/spec changes
- MissingPet: granular sound options (separate toggles for missing/passive, in-combat sounds)

## 0.4.23 - 2026-01-26
- AutoQuest: add option to skip trivial (gray/low-level) quests
- AutoQuest: allow automation in instances (removed instance pause)

## 0.4.22 - 2026-01-25
- Split ui.lua: extract module options into AutoQuest/Options.lua, AutoQueue/Options.lua, DeleteConfirm/Options.lua, DisableAutoAddSpells/Options.lua

## 0.4.21 - 2026-01-25
- Add minimap compartment support (Blizzard addon button dropdown)

## 0.4.20 - 2026-01-24
- AutoQuest: pause automation while in instances
