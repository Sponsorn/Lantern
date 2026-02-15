# Changelog

## 0.3.0 - 2026-02-15
- Add: Class-colored bar backgrounds with state-dependent brightness (ready, cooldown, active)
- Add: Border glow on active spell icons (replaces yellow overlay)
- Add: Preview mode now uses real Edit Mode party frames for attached layout
- Add: `/lmt preview` opens the options panel automatically
- Add: Addon sync broadcasts cooldown info when you use your interrupt
- Add: Re-inspect party members when they change spec
- Add: Re-evaluate tracker exclusions when party roles change
- Add: Staggered inspect attempts for queued dungeons (2s, 5s, 10s after zone-in)
- Add: Inspect retries (up to 3 attempts) when spec data is unavailable
- Add: Edit Mode hint text in options for attached layout preview
- Fix: Spec-restricted spells no longer show before inspect completes
- Fix: Warlock interrupts now correctly filter by spec (Spell Lock vs Axe Toss)
- Fix: Pet spell detection for Warlock Felhunter and similar pet casters
- Fix: Frame mover bounce-back when dragging (ApplyDocking no longer interrupts drags)
- Fix: Secret value errors in self-cooldown tracking
- Fix: Memory leak from closures created on every roster or nameplate update
- Fix: Options panel repositioned to avoid overlapping Edit Mode HUD
- Fix: Inspect cleanup with ClearInspectPlayer() after each scan
- Change: Split display code into separate files for bars, icons, and attached mode
- Change: Bar height slider resizes bars live without frame rebuild
- Change: Options panel preserves scroll position when settings change
- Chore: All frames named for /fstack debugging
- Chore: Added credits for ShimmerTracker and MythicInterruptTracker

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
