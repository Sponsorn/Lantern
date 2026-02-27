# Changelog

## 0.6.2 - 2026-02-26
- Add: Item Info module — shows item level (color-coded by quality), missing enchant warnings, and empty gem socket indicators on the character and inspect panels, plus item level overlays on bags, loot, bank, and equipment flyout (disabled by default)
- Add: Item Info upgrade arrow — bag, bank, loot, and flyout items show a green arrow when they are an upgrade over currently equipped gear (toggleable, enabled by default)
- Change: Item Info now displays item level and socket icons beside equipment slots (left/right layout matching the character panel) instead of overlaid on top — empty sockets show colored socket-type icons, filled sockets show the gem texture
- Fix: DisableLootWarnings now correctly auto-confirms bind-on-pickup loot popups (ConfirmLootSlot is protected in 12.0 — now clicks the LOOT_BIND popup button instead)
- Add: Module status dots on the splash page are now clickable toggles — quickly enable or disable any module without navigating to its settings page
- Chore: Consolidated duplicate widget helpers (moduleEnabled, moduleToggle, refreshPage) into shared Utils/WidgetHelpers.lua
- Fix: Custom fonts (Roboto) sometimes showing as default WoW font on cold login — SetFont now retries after a short delay if the font file isn't cached yet
- Chore: Consolidated duplicate GetFontPath into shared Utils with SafeSetFont retry helper (RangeCheck, CombatTimer, CombatAlert, MissingPet)

## 0.6.1 - 2026-02-25
- Fix: Tooltip no longer crashes on secret tooltip text in instances (WoW 12.0 secret string guard)
- Fix: DisableLootWarnings no longer errors when confirming loot rolls, bind-on-pickup, and merchant refund popups
- Fix: Range Check now uses Pummel for all Warrior specs instead of Slam/Shield Slam
- Fix: Range Check now uses Death Strike for Death Knights instead of pre-spec Rune Strike
- Fix: Range Check now uses correct Blackout Kick spell for Windwalker Monk

## 0.6.0 - 2026-02-24
- Add: Tooltip module — shows mount names, item IDs, spell IDs, and talent node IDs on tooltips with Ctrl+C copy support (all features individually toggleable, disabled by default)
- Add: Tooltip Ctrl+C opens a copy popup showing the item/spell name with selectable ID fields — supports items with both ItemID and SpellID in one popup
- Add: Minimap icon now shows an amber glow overlay on hover
- Add: Cursor Ring trail color presets — Class Color (auto-matches your class), Lantern Gold, Arcane, Fel, Fire, Frost, Holy, Shadow, plus multi-color gradients: Rainbow, Al'ar, Ember, and Ocean
- Add: Cursor Ring trail style selector — choose between Glow, Line, Thick Line, and Dots presets, or go Custom
- Add: Cursor Ring trail manual controls — Max Points, Dot Size, Dot Spacing, and Shrink with Age settings
- Add: Cursor Ring trail now interpolates dots along the cursor path — no more gaps during fast mouse movement
- Add: Cursor Ring trail "Taper with Distance" option — dots shrink and fade toward the tail for a brush-stroke effect (enabled by default on Line and Thick Line presets)
- Add: Cursor Ring trail sparkle effect with two modes — Static (fade in place) and Twinkle (shimmer with upward drift)
- Add: Cursor Ring rainbow trail now shifts its starting color as you move, instead of always starting from red
- Add: Full localization support — all user-facing strings extracted to locale files with English as the base, 10 additional languages ready for community translations
- Add: Automated release pipeline — GitHub Actions with BigWigs packager for CurseForge uploads, localization substitution, and GitHub Releases
- Change: Cursor Ring Preview is now a button ("Start Preview" / "Stop Preview") instead of a toggle, so it reads as a tool rather than a setting
- Change: Cursor Ring renamed to Cursor Ring & Trail
- Change: Cursor Ring trail max points increased from 80 to 400
- Change: Cursor Ring trail performance improved — dot positions set once on placement instead of every frame, dormant mode when cursor is idle, and hitch recovery after loading screens
- Fix: Preview mode now loops continuously in Cursor Ring, Combat Timer, and Combat Alert (was checking wrong panel frame property, causing auto-disable after 0.5s)
- Fix: Tooltip module no longer errors on unit tooltips inside instances (secret value guard)
- Fix: Tooltip copy no longer triggers protected function errors during combat

## 0.5.1 - 2026-02-21
- Add: Range Check now detects Holy Paladin melee range (item-based check since Holy has no melee attack spell)
- Add: "Modern minimap icon" toggle in General settings — removes border and background with a lantern glow on hover
- Change: Warehousing panel text now uses bold font for better readability
- Chore: Updated LibDBIcon-1.0 to v56 (new button customization APIs)

## 0.5.0 - 2026-02-21
tldr: 8 new modules — Auto Repair, Auto Sell, Chat Filter, Auto Playstyle, Faster Loot, Disable Loot Warnings, Auto Keystone, and Release Protection. Three new HUD overlays — Combat Timer, Combat Alert, and Range Check — all draggable and fully customizable. Settings home page redesigned with category groups and clickable module navigation. Roboto font family across all UI. Pause modifier key is now configurable (Shift/Ctrl/Alt). Enough QoL to make your UI feel like it finally graduated from high school.

- Change: Settings panel and HUD modules now use Roboto font for a modern, cohesive look
- Add: Roboto Bold and Roboto ExtraBold fonts available in all font selectors
- Change: Default font for Missing Pet and Crafting Orders notifications changed from Friz Quadrata to Roboto Light
- Add: Home page status dot legend (enabled/disabled)
- Add: Slider default value markers across all modules
- Change: Home page modules displayed in two columns
- Add: Font, outline, and color selectors for Combat Timer and Combat Alert modules
- Add: Combat Timer and Combat Alert preview mode for real-time settings editing
- Add: Combat Alert and Missing Pet now use the draggable frame system with lock/unlock position
- Add: Draggable frames show "Unlocked - drag to move" label when unlocked
- Fix: Cursor Ring preview now correctly auto-disables when closing the settings panel
- Change: Improved empty state messages in Auto Quest blocklists
- Add: Auto Repair module — automatically repairs gear at merchants with personal gold, guild funds, or guild-first fallback (disabled by default)
- Add: Auto Sell module — automatically sells gray items and custom-listed items at merchants, with global and per-character sell lists (disabled by default)
- Add: Chat Filter module — filters gold spam, boost ads, and unwanted messages from whispers and public channels with a customizable keyword list
- Add: Configurable pause modifier key (Shift, Ctrl, or Alt) in General settings — applies to all auto-features
- Add: Auto Playstyle module — auto-selects your preferred playstyle when listing M+ groups in the Group Finder
- Add: Faster Loot module — instantly collects all loot when a loot window opens, with inventory-full warning
- Add: Disable Loot Warnings module — auto-confirms bind-on-pickup, loot roll, merchant refund, and mail lock popups with per-type toggles (disabled by default)
- Add: Auto Keystone module — automatically slots your Mythic+ keystone when the Challenge Mode UI opens
- Add: Release Protection module — requires holding your pause modifier to release spirit, preventing accidental clicks (disabled by default)
- Add: Combat Timer module — on-screen combat duration timer with sticky mode that keeps showing after combat ends (disabled by default)
- Add: Combat Alert module — fade-in/out text alerts when entering or leaving combat with configurable colors and sound (disabled by default)
- Add: Range Check module — in-range or out-of-range status display for your current target with customizable text, colors, animations, and optional hide-when-in-range (disabled by default)
- Change: Options sidebar reorganized into context-based categories (General, Dungeons & M+, Questing & World)
- Change: Home page now shows all modules grouped by category with clickable navigation to settings
- Add: Release Protection now supports scenario filtering — choose Always, All Instances, or Custom mode with per-type toggles (dungeons, M+, raids, arenas, battlegrounds, open world)
- Add: Range Check font and outline selectors
- Add: Combat Alert separate toggles to enable/disable enter and leave alerts independently
- Add: Range Check customizable status text, colors, and animation style
- Fix: Range Check melee detection now works reliably for all melee specs (direct spell checks matching MeleeRangeIndicator approach)
- Fix: Range Check now detects Devourer Demon Hunter range correctly (added missing Consume spell to LibRangeCheck)
- Fix: Range Check no longer shows "Out of Range" for friendly targets
- Fix: Combat Alert banner no longer stays visible after locking position
- Fix: Draggable frames restore original text and color when re-locking position
- Fix: Draggable frames auto-lock when closing the settings panel
- Chore: Split large module options into separate WidgetOptions.lua files (AutoQuest, AutoSell, CursorRing, MissingPet)
- Fix: Faster Loot inventory-full detection now works on all WoW client languages
- Fix: Home page now scrollable when content extends beyond the panel

## 0.4.35 - 2026-02-19
- Remove: Old Interrupt Tracker module
- Chore: Renamed UXBridge.lua to Options.lua

## 0.4.34 - 2026-02-18
~16k lines removed, whole UI framework added, "patch" version, well, perks of not being 1.0 yet I guess, I hope you will enjoy the new options panel, any feedback is welcome, I think I have covered all bases with migration.
- Fix: Missing Pet no longer plays false alarm sounds on login before the pet has loaded
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
