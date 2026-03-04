# Changelog

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
