# Changelog

## 0.2.11
- Add: Roboto SemiBold font added to theme font paths

## 0.2.10 - 2026-03-21
- Fix: Korean, Simplified Chinese, and Traditional Chinese text now renders correctly (falls back to system CJK fonts instead of Roboto)

## 0.2.9 - 2026-03-19
- Fix: BarChart y-axis grid lines now always show 3 lines with properly scaled round values that cover the full data range

## 0.2.8 - 2026-03-19
- Add: BarChart y-axis grid lines with value labels — pass `yLabelFn` to enable horizontal reference lines with formatted values

## 0.2.7 - 2026-03-16
- Add: DataTable optional search/filter — configure `searchColumns` to enable an inline search input with debounced filtering
- Add: `LanternUX.ShowReloadPrompt(message)` utility for settings that require a UI reload
- Add: DataTable `onRowRightClick` callback for right-click actions on rows
- Fix: DataTable expandable rows no longer reset scroll position when clicking to expand/collapse
- Fix: DataTable sorting now places empty values at the bottom regardless of sort direction

## 0.2.6 - 2026-03-12
- Add: New `heatmap` widget type — 7x24 day/hour grid with color scaling, tooltips, and responsive sizing
- Add: `LanternUX.CreateStandaloneWidget()` API for creating widgets outside the page renderer
- Add: DataTable expandable rows — click a parent row to reveal child rows inline with accent border and indent
- Add: New `barchart` widget type — vertical bar chart with tooltips, adaptive sizing, and highlight support

## 0.2.5 - 2026-03-07
- Fix: DataTable column header sort arrows now stay inside column bounds instead of blending into adjacent columns
- Change: DataTable column headers and cells have improved padding for better readability

## 0.2.4 - 2026-03-04
- Add: DataTable widget — sortable, scrollable data table with pagination footer for analytics and list views
- Add: Outer border on settings panel for better visual definition

## 0.2.3 - 2026-02-25
- Add: Collapse button on the title bar — click to minimize the panel to just the title bar

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
