<span style="color:#e03e2d"><strong>Pre-release</strong> - This addon is in early development.</span> Spell data is incomplete and some class/spec combinations may be missing cooldowns. Expect frequent updates as spells are verified and added. You can still use it, but expect lua errors and missing spells.

<span style="color:#e03e2d"><strong>Note:</strong></span> The "Party Frames" display mode currently only works with Blizzard's default raid-style party frames. Custom party frame addons (ElvUI, VuhDo, Grid2, etc.) are not supported yet. Open Edit Mode (Game Menu) and then type `/lmt preview` to preview attached icons on party frames.

***

Lantern - Mythic+ Tracker passively tracks party member spell cooldowns in Mythic+ dungeons. See at a glance who has their interrupt ready, who just used a defensive, and when everything comes back up.

### Interrupts

*   Tracks all interrupt spells across every class and spec
*   Detects kicks via taint laundering and mob interrupt correlation — no manual setup needed
*   Inspects party members for spec overrides and talent-based cooldown reductions
*   Optional addon sync between Lantern users for instant party detection

### Defensives

*   Tracks major defensive cooldowns (Shield Wall, Ice Block, Cloak of Shadows, etc.)
*   Shows active buff duration and cooldown remaining
*   Charge tracking for multi-charge abilities (Survival Instincts, etc.)

### Cooldowns

*   Tracks major offensive cooldowns (Combustion, Metamorphosis, Recklessness, etc.)
*   Covers all DPS specs with Midnight-accurate spell data
*   Shows active buff duration and cooldown remaining
*   Charge tracking for multi-charge abilities (Zenith, etc.)

### Display Modes

*   **Bar layout**: Class-colored cooldown bars with spell icons and player names
*   **Icon Grid layout**: Spell icons grouped by player with cooldown swipes and glow effects

### Features

*   Per-category settings: enable/disable, layout mode, filtering (show all, hide ready, active only)
*   Configurable sorting by remaining cooldown or base cooldown, with self-on-top option
*   Customizable bar width, height, opacity, icon size, fonts, and grow direction
*   Draggable frames with lock and saved positions
*   Preview mode with simulated party data for positioning and testing
*   Frame docking to stack tracker frames together

### Standalone or with Lantern

Works as a fully standalone addon — no dependencies required. If you have [Lantern](https://www.curseforge.com/wow/addons/lantern) installed, it integrates into Lantern's module system and settings panel automatically.

#### Configuration

Type `/lmt` to open the settings frame. Use `/lmt preview` to toggle preview mode, `/lmt lock` to lock frame positions, and `/lmt reset` to reset positions.