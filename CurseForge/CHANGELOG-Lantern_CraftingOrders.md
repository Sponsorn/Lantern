# Changelog

## 0.6.6
- Fix: Chat decoration and right-click menu now register correctly on login
- Add: Customer nicknames — assign nicknames to customers via the right-click "Customer Info" popup
- Add: Alt grouping — customers with the same nickname can be merged into a single row (toggle in analytics Settings)
- Add: Customer Info popup — right-click any player name in chat to view/edit their tipper profile
- Add: Chat decoration — tipper rating icons appear next to known customer names in whispers and trade chat
- Add: Rating override — manually set a customer as good or bad tipper from the Customer Info popup
- Add: Right-click menu can be restricted to rest areas only (on by default)
- Add: Tipper rating system — customers are rated as good, neutral, or bad based on personal order tip averages (off by default, enable in analytics Settings)
- Add: Tipper icon column in the Customers analytics tab (coins or crafting quality icons)
- Add: Tipper rating settings — configurable thresholds, icon style, neutral icon toggle
- Add: Customer cache for fast lookups (built on login, updated on new orders)
- Add: Search filter on the Customers analytics tab — type to filter by name or nickname
- Add: Pagination on the Customers analytics tab with configurable page size
- Change: Page size controls for Orders and Customers tabs moved from settings into the analytics panel (dropdown next to character filter)

## 0.6.5 - 2026-03-13
- Fix: Analytics panel failing to open when Lantern core hasn't been updated yet (missing weekly reset function)
- Add: Open analytics directly from the Lantern minimap button (configurable in General settings)

## 0.6.4 - 2026-03-12
- Add: Dashboard now shows daily/weekly/monthly timeframes with both order count and tips earned per period
- Add: Reset timer shown on daily and weekly timeframe cards (e.g., "Resets in 4h 23m")
- Add: Reset timer settings — toggle visibility, choose auto (region-based) or custom reset day/hour
- Add: Timeframe filter on dashboard top 5 customers and items sections (All Time, Today, This Week, Last 30 Days)
- Add: Heat Maps analytics tab showing order count, gold earned, and trade chat activity as 7x24 day/hour grids
- Add: Trade chat tracker — monitors Trade channel for crafting requests with customizable keywords and profession detection
- Add: Trade chat settings — enable/disable toggle, data retention (30/60/90 days), keyword management
- Add: Expandable customer rows — click a customer to see their individual order history inline
- Change: Analytics settings page now uses collapsible sections for better organization
- Fix: Trade chat tracker not detecting Trade channel messages (wrong event argument position)
- Fix: Trade chat listener continued running after module was disabled
- Add: Earnings over time bar chart on the analytics dashboard with adaptive daily/weekly bucketing
- Change: Dashboard stat cards and timeframe cards now use uniform column widths for a cleaner layout
- Fix: Heat Maps timeframe dropdown persisting on other pages (e.g., Settings)
- Fix: Login error when Trade Chat Tracker loaded after module initialization

## 0.6.3 - 2026-03-08
- Fix: Module was disabled by default on fresh installs with no toggle to enable it
- Fix: Order fulfillments not recorded when using CraftSim's craft queue (or other addons that call FulfillOrder directly)

## 0.6.2 - 2026-03-07
- Fix: Complete+Whisper button and analytics button not appearing when Professions window loads after addon initialization

## 0.6.1 - 2026-03-06
- Add: Order type filtering in analytics — choose which order types (guild, personal) to track and display
- Change: Renamed analytics "Filters" tab to "Settings" and reorganized with order type toggles and customer exclusion sections
- Fix: Guild order fulfillments not being recorded in analytics — use GetClaimedOrder API as primary lookup instead of relying on view frame state
- Fix: Incorrect enum fallback values for guild/personal order type detection
- Add: Pagination on analytics Orders page for large order histories
- Add: "Orders per page" setting to control how many orders are shown per page
- Change: Increased max order history limit from 2000 to 10000 (default now 2000)
- Change: Orders page now uses sortable columns (click headers to sort)
- Change: Removing orders now requires Shift-click to prevent accidental deletion
- Change: Dashboard stat cards now use compact money formatting (e.g., "1.2k g" instead of full amounts)
- Add: Hover tooltips on dashboard tip stat cards showing the full money amount
- Fix: Background sound notification not playing when game is in the background — delay playback briefly after enabling sound engine

## 0.6.0 - 2026-03-04
- Add: Filters page in analytics — exclude specific customers from all analytics views
- Add: Orders page in analytics — view and remove individual recorded orders
- Add: Order history tracking — automatically records fulfilled crafting orders (guild and personal)
- Add: Analytics window with Dashboard, Customers, Items, Orders, and Filters pages using native LanternUX panel (`/lantern orders`)
- Add: Per-customer stats: order count, total tips, average tip, last order
- Add: Per-item stats: craft count, average tip, total revenue, unique customers
- Add: Dashboard with overall stats, top 5 customers, and top 5 items
- Add: Character filter to view current character or all characters
- Add: Analytics button in the crafting window
- Add: Order History settings page with tracking toggle, max orders limit, and clear history
- Change: Customer names now preserve realm suffix for cross-realm guild orders
- Add: Background sound option for personal order notifications

## 0.5.0 - 2026-02-23
- Add: Full localization support — all user-facing strings extracted to locale files with English as the base, 10 additional languages ready for community translations
- Add: Automated release pipeline — GitHub Actions with BigWigs packager for CurseForge uploads and localization substitution

## 0.4.10
- Change: Default notification font changed from Friz Quadrata to Roboto Light

## 0.4.9 - 2026-02-18
- Change: Settings now use a custom UI panel (LanternUX) instead of the Blizzard options interface
- Change: LanternUX is now a required dependency (previously optional)

## 0.4.8 - 2026-02-18
- Fix: Work order notifications not working on non-English game clients (GitHub issue #3)

## 0.4.7b - 2026-02-01
- Fix zip file not extracting as folder on macOS/Linux (GitHub issue #2)

## 0.4.7 - 2026-01-28
- Personal Orders: add customizable notification appearance (font, size, outline, color, duration)
- Personal Orders: use custom notification frame instead of LibSink for better visual control

## 0.4.6 - 2026-01-23
- Initial release with guild order announcements and personal order notifications
- Complete + Whisper button for personal orders
