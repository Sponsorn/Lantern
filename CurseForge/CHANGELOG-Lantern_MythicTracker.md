# Changelog

****
## <span style="color:#E03E2D;">**I cannot stress this enough, this will break. Have fun while it lasts.**</span>
****

## 0.4.2 - 2026-02-15
- Add: Explicit grow direction setting for party frame icons (Left, Right, Up, Down, Auto)
- Add: Orientation setting (Horizontal/Vertical) and Icons Per Row for party frame attached mode
- Add: All 8 anchor points for party frame attachment (was only Right, Left, Bottom)
- Change: Options dropdowns now use context menus instead of cycle buttons
- Change: Offsets no longer flip signs based on anchor — positive X always means right, positive Y always means up
- Change: Preview players updated to show more class diversity (Shaman, Mage, Rogue, Priest)
- Fix: Categories with different grow directions no longer interfere when stacking on the same anchor

## 0.4.1 - 2026-02-15
- Add: Grow direction setting (Down / Up) as a cycle button in category options
- Fix: Title bar and docking now respect grow direction (title below frame when growing up, docking stacks upward)
- Fix: Pet spell detection — re-scans spells when pet changes (Warlock Spell Lock, Hunter pet abilities)
- Fix: Options panel crash when changing layout or display mode (BuildContent reference error)

## 0.4.0 - 2026-02-15
- Add: Per-spell enable/disable toggles in the new "Spells" tab (uncheck individual spells to hide them)
- Add: Tab bar in options panel to switch between Settings and Spells views
- Add: Spell IDs shown next to spell names in the Spells tab
- Add: Passive cheat death detection via debuff aura tracking (Purgatory)
- Add: Inspect party on M+ dungeon start (CHALLENGE_MODE_START) for uninspected players
- Add: Comprehensive spell database expansion for all 13 classes:
  - Death Knight: Anti-Magic Zone, Lichborne, Death Pact, Vampiric Blood, Dancing Rune Weapon, Tombstone, Purgatory, Empower Rune Weapon, Abomination Limb, Gorefiend's Grasp
  - Demon Hunter: Darkness, The Hunt (Havoc/Devourer variants)
  - Druid: Berserk (Guardian), Incarnation variants for Balance/Feral/Guardian, Convoke the Spirits (all specs)
  - Evoker: Zephyr, Tip the Scales, Breath of Eons, Dream Flight, Stasis
  - Hunter: Survival of the Fittest (Lone Wolf)
  - Mage: Greater Invisibility
  - Monk: Dampen Harm, Touch of Death, Invoke Niuzao, Invoke Chi-Ji
  - Paladin: Guardian of Ancient Kings, Blessing of Protection, Lay on Hands, Blessing of Sacrifice
  - Priest: Desperate Prayer, Vampiric Embrace, Symbol of Hope
  - Shaman: Earth Elemental
  - Warrior: Rallying Cry, Last Stand, Avatar, Thunderous Roar, Ravager, Champion's Spear
- Fix: Preview mode now correctly resolves spec-specific cooldowns (cdBySpec)
- Fix: Mistweaver Monk excluded from interrupt tracking (no Spear Hand Strike)
- Fix: Convoke the Spirits spell ID updated to talent version (391528)
- Fix: Doom Winds spell ID updated (384352) and duration corrected
- Fix: Counterspell base CD corrected to 25s
- Fix: Ice Block base CD corrected to 240s (4 min)
- Fix: Silence base CD updated to 30s for Midnight
- Fix: Dispersion base CD updated to 90s for Midnight
- Fix: Adrenaline Rush duration corrected to 19s
- Fix: Shadow Blades restricted to Subtlety only
- Fix: Invoke Xuen CD corrected to 96s (Conduit of Celestials)
- Fix: Ultimate Penitence duration corrected to 4.3s

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
