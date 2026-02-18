# Changelog

## 0.4.34 - 2026-02-18
- Change: Settings now use a custom UI panel (LanternUX) instead of the Blizzard options interface
- Remove: Dropped AceConfig, AceGUI, and AceEvent library dependencies
- Change: LanternUX is now a required dependency (previously optional)
- Change: Blizzard Settings entry (ESC > Options > Addons > Lantern) replaced with a simple splash screen and "Open Settings" button

## 0.4.33 - 2026-02-15
- Fix: MissingPet warning text is now clickthrough when locked
- Change: Interrupt Tracker preview uses original character names
- Change: Interrupt Tracker default position moved to avoid overlapping the options panel

## 0.4.32 - 2026-02-14
- Fix: Interrupt Tracker title bar no longer shifts bars when toggling lock
- Fix: Interrupt Tracker lock toggle now properly refreshes the display
- Fix: Interrupt Tracker bar backgrounds are now fully opaque
- Change: Interrupt Tracker title floats above the frame as a draggable handle
- Change: Interrupt Tracker title uses Lantern theme color
- Add: Interrupt Tracker title bar added to minimal mode
- Remove: Interrupt Tracker frame background behind bars removed for cleaner look
- Fix: Interrupt Tracker frame strata lowered to avoid overlapping other UI elements
- Change: Interrupt Tracker description updated to reflect non-raid group support

## 0.4.31 - 2026-02-14
- Add: Interrupt Tracker module (disabled by default) - passively tracks party member interrupt cooldowns in non-raid groups
    - Two display modes: Bar (class-colored cooldown bars with icons) and Minimal (compact rows with icon, name, and status)
    - Passively detects kicks via taint laundering and mob interrupt correlation — no manual setup needed
    - Optional addon sync with other Lantern users for instant party member detection
    - Inspects party members for spec overrides and talent-based cooldown reductions
    - Configurable sorting: by remaining cooldown or base cooldown, with option to pin self on top
    - Customizable bar width, height, opacity, grow direction, font, and font outline
    - Preview mode with simulated party data for positioning and testing
    - Separate draggable frames for each display mode with independent saved positions

## 0.4.30 - 2026-02-11
- Change: Cursor Ring preview is now a persistent toggle at the top of options for real-time editing
- Change: Cursor Ring preview continuously loops cast/GCD animations and auto-disables when closing settings
- Change: Cursor Ring all sub-controls become interactive during preview for easy tweaking
- Change: Cursor Ring sliders accept precise decimal values typed into the input box
- Change: Cursor Ring ring size max reduced to 80 for sharper visuals
- Fix: Cursor Ring no longer pollutes /fstack output

## 0.4.29 - 2026-02-09
- Add: Cursor Ring module (disabled by default) - customizable ring(s) around your cursor with cast/GCD indicators and optional mouse trail
    - Cursor Ring supports two independent rings with adjustable size, shape, and color
    - Cursor Ring cast effect with three styles (segments, fill, swipe)
    - Cursor Ring GCD indicator that can display simultaneously with cast effects
    - Cursor Ring optional center dot with color and size settings
    - Cursor Ring optional mouse trail with adjustable duration and color
    - Cursor Ring preview buttons to test cast/GCD animations from the options panel
- Add: MissingPet, added /lantern petdebug
- Chore: Checked all api dependabilities still working in 12.0.1
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
