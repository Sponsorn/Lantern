# Lantern

Lantern is a modular QoL addon for World of Warcraft (Retail). It bundles small, focused features you can toggle on/off through a custom settings panel.

## Modules

- **Auto Quest**: Accepts and turns in quests automatically (pause modifier to pause). Blocklist support for NPCs and quests.
- **Auto Queue**: Auto-accepts LFG role checks using your roles set in the LFG tool.
- **Auto Repair**: Automatically repairs gear at merchants using personal gold, guild funds, or guild-first fallback.
- **Auto Sell**: Automatically sells gray items and custom-listed items at merchants, with global and per-character sell lists.
- **Auto Keystone**: Automatically slots your Mythic+ keystone when the Challenge Mode UI opens.
- **Auto Playstyle**: Auto-selects your preferred playstyle when listing M+ groups in the Group Finder.
- **Chat Filter**: Filters gold spam, boost ads, and unwanted messages with a customizable keyword list.
- **Combat Timer**: On-screen combat duration timer with sticky mode. Disabled by default.
- **Combat Alert**: Fade-in/out text alerts when entering or leaving combat. Disabled by default.
- **Cursor Ring**: Customizable ring(s) around your mouse cursor with cast/GCD indicators and mouse trail. Disabled by default.
- **Death Release Protection**: Requires holding your pause modifier to release spirit, preventing accidental clicks. Disabled by default.
- **Delete Confirm**: Hides the delete prompt input and enables the confirm button immediately.
- **Disable Auto Add Spells**: Prevents spells from being auto-added to your action bars.
- **Disable Loot Warnings**: Auto-confirms bind-on-pickup, loot roll, merchant refund, and mail lock popups.
- **Faster Loot**: Instantly collects all loot when a loot window opens, with inventory-full warning.
- **Missing Pet**: On-screen warning when your pet is missing or set to passive. Supports Hunters, Warlocks, Unholy DK, Frost Mage.
- **Range Check**: Color-coded distance display to your target. Two modes: range numbers or in/out of range status (auto-detects spec max range). Disabled by default.

## Companion Addons

- **Lantern_CraftingOrders**: Crafting order monitoring — notifications for personal orders, guild message when placing orders.
- **Lantern_Warband**: Organize characters into groups with automated gold balancing to/from warbank.

## LanternUX

LanternUX is a standalone settings panel UI framework that powers Lantern's options. It provides a dark-themed panel with sidebar navigation, searchable settings, and a library of custom widgets (toggles, sliders, dropdowns, inputs, color pickers, buttons, collapsible groups). LanternUX has no dependencies and can be used by any addon.

Key features:
- `LanternUX:CreatePanel(config)` — creates a panel with sidebar, content area, and description panel
- Widget-based pages with automatic layout and hover descriptions
- `LanternUX.MakeDraggable(frame, config)` — reusable utility for draggable, lockable frames with position persistence
- Searchable settings with widget-level highlighting

## Configuration

Click the minimap button or type `/lantern` to open the settings panel. Each module has an enable toggle and per-module settings.

## License

Licensed under GPLv3. See `LICENSE`.
