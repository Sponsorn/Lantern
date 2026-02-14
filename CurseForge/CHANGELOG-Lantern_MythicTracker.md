# Changelog

## 0.2.0 - 2026-02-14
- Add: Attach spell icons to Blizzard party frames (per-player icon mode, like OmniCD)
- Add: Anchor direction (Right, Left, Bottom) with X/Y offset sliders
- Add: Category stacking when multiple trackers are attached to the same frame
- Add: Icons grow in the anchor direction (left anchor grows left, etc.)
- Add: Per-spec cooldown values for spells with different CDs per spec
- Add: Re-inspect party members on ready check
- Fix: Cooldowns not showing for party members before inspect (spec filtering was too strict)
- Fix: Ret Paladin cooldowns missing due to duplicate Avenging Wrath entry
- Fix: Self player now included in attached mode for raid-style party frames

## 0.1.0 - 2026-02-14
- Add: Initial release — party spell tracking for Mythic+ dungeons
- Add: Interrupt tracking with taint laundering, mob correlation, and addon sync
- Add: Defensive cooldown tracking with buff duration and charge support
- Add: Major offensive cooldown tracking (Recklessness, Combustion, Metamorphosis, etc.)
- Add: Bar display layout with class-colored cooldown bars
- Add: Icon Grid display layout with cooldown swipes and glow effects
- Add: Per-category settings (enable, layout, filter, sort, show self, grow direction)
- Add: Preview mode with simulated party data for positioning
- Add: Frame docking to stack tracker frames together
- Add: Inspect system for spec detection and talent-based cooldown reductions
- Add: Basic settings frame with `/lmt` slash command
- Add: Optional Lantern integration (registers as Lantern module if installed)
