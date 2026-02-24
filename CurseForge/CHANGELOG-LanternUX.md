# Changelog

## 0.2.2 - 2026-02-24
- Fix: Range slider drag area now covers the full widget height, making it easier to grab
- Change: Toggle widget uses a simpler solid texture instead of backdrop borders for a cleaner look

## 0.2.1 - 2026-02-23
- Add: Automated release pipeline — GitHub Actions with BigWigs packager for CurseForge uploads

## 0.2.0 - 2026-02-21
- Add: Callout widget type with three severity levels (info, notice, warning) — colored left border with tinted background
- Add: Draggable frame registry with auto-lock when settings panel closes
- Add: Roboto font family (Thin, Light, Regular) bundled with theme FontObjects
- Fix: Draggable frames now restore original text and color when re-locking

## 0.1.0 - 2026-02-18
- Add: Initial release
- Add: Panel framework with sidebar navigation, sections, and collapsible groups
- Add: Widget types: toggle, range, select, input, color, execute, label, header, description, divider, group, label_action, item_row, drop_slot
- Add: Dark monochrome theme (near-black backgrounds, amber accents)
- Add: Widget search with real-time filtering and jump-to-widget
- Add: Description panel for contextual widget help on hover
- Add: Smooth scrolling with easing and fade overlays
- Add: Widget pooling for memory-efficient page switching
- Add: AceConfig fallback support for mixed panel pages
- Add: Custom frame page support
- Add: Draggable title bar with icon, version, and close button
- Add: ESC key to close, sound effects on open/close
