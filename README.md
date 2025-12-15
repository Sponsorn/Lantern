# Lantern

Lantern is a modular QoL addon for World of Warcraft. It bundles small, focused features you can toggle on/off:

- **Auto Quest**: Accepts and turns in quests automatically (Shift to pause).
- **Auto Queue**: Auto-accepts LFG role checks using your roles set in the LFG tool (Shift to pause).
- **Delete Confirm**: Hides the delete prompt input and enables the confirm button immediately.
- **Disable Auto Add Spells**: Prevents spells from being auto-added to your action bars.

The framework is module-based, so additional features can be plugged in later without impacting the core. Modules marked `skipOptions` only appear under General Options, keeping the AddOns list tidy.

Current WIP modules:
- Vendor Filter: Filter/sort vendor items by type (icons on the merchant frame).
- Crafting Orders: Functionality to get info if you received a personal crafting order, send guild message when placing orders. Maybe stats to see what people are requesting in trade chat to be able to make decisions on which profession trees to pick.

## Configuration

Open the game’s Interface → AddOns → Lantern → General Options. Each module has an enable toggle and a short description. Modules marked “skipOptions” only appear under General Options (not as separate menu entries).

## Versioning

Current version: 0.2.0

## License

Licensed under GPLv3. See `LICENSE`.
