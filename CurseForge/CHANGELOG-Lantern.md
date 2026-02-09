# Changelog

## 0.4.29 - 2026-02-09
- Add: Cursor Ring module -- customizable ring(s) around your cursor with cast/GCD indicators and optional mouse trail (disabled by default)
- Add: Cursor Ring supports two independent rings with adjustable size, shape, and color
- Add: Cursor Ring cast effect with three styles (segments, fill, swipe)
- Add: Cursor Ring GCD indicator that can display simultaneously with cast effects
- Add: Cursor Ring optional center dot with color and size settings
- Add: Cursor Ring optional mouse trail with adjustable duration and color
- Add: Cursor Ring preview buttons to test cast/GCD animations from the options panel
- Add: MissingPet, added /lantern petdebug
- Chore: Removed old experiment addons (ChatQoL, VendorQoL)
- Fix: Removed invalid interface versions from CraftingOrders and Warband TOC files

## 0.4.28 - 2026-02-01
- Fix: MissingPet not detecting Death Knight pets (passive warning not showing)
- Fix: MissingPet pet stance detection delayed on bar update

## 0.4.27b - 2026-02-01
- Fix zip file not extracting as folder on macOS/Linux (GitHub issue #2)

## 0.4.27 - 2026-01-31
- Add /lantern slash command to open the options panel
- Minimap icon left-click now toggles the options panel (closes if already open)

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
