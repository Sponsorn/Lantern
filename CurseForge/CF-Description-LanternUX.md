<img src="https://img.shields.io/badge/Developer%20Library%20--%20Not%20a%20standalone%20addon-e04040?style=for-the-badge" alt="Developer Library -- Not a standalone addon" />
----
**This is a developer library.** LanternUX does nothing on its own -- it's a dependency used by addons like [Lantern](https://www.curseforge.com/wow/addons/lantern-qol) to build settings panels. If you're a player, you don't need to install this manually.
----
---
<a href="https://buymeacoffee.com/sponsorn"><img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-fff?logo=buymeacoffee&logoColor=e08f2e" alt="Buy me a coffee" /></a>



LanternUX is a standalone settings panel framework for WoW addon developers. No dependencies -- drop it in and create polished settings panels.

### Features

*   **Dark monochrome theme** inspired by Linear - near-black backgrounds with muted lavender accents
*   **15 built-in widget types**: toggle, range (slider), select (dropdown), input (text field), color picker, execute (button), label, header, description, divider, collapsible group, label with action button, item row, drop slot, search result
*   **Sidebar navigation** with sections, collapsible groups, and accent-highlighted selection
*   **Widget search** with real-time filtering and jump-to-widget
*   **Description panel** that shows contextual help on widget hover
*   **Smooth scrolling** with easing and fade overlays
*   **Widget pooling** for efficient memory reuse across page switches
*   **Multiple page types**: widget-based or custom frame

### Quick Start

```lua
local panel = LanternUX:CreatePanel({
    name = "MyAddonSettings",
    title = "My Addon",
    version = "1.0",
})

panel:AddPage("general", {
    label = "General",
    widgets = function()
        return {
            { type = "toggle", label = "Enable Feature", get = function() return MyDB.enabled end, set = function(val) MyDB.enabled = val end },
            { type = "range", label = "Speed", min = 1, max = 10, step = 1, get = function() return MyDB.speed end, set = function(val) MyDB.speed = val end },
            { type = "select", label = "Mode", values = { fast = "Fast", slow = "Slow" }, get = function() return MyDB.mode end, set = function(val) MyDB.mode = val end },
        }
    end,
})

panel:Toggle()
```

### API

*   `LanternUX:CreatePanel(config)` -- create a panel (name, title, icon, version)
*   `panel:AddSection(key, label)` -- add a sidebar section header
*   `panel:AddPage(key, opts)` -- add a page (widgets or custom frame)
*   `panel:AddSidebarGroup(key, opts)` -- add a collapsible sidebar group
*   `panel:Show()` / `panel:Hide()` / `panel:Toggle()`
*   `panel:SelectPage(key)` -- navigate to a page
*   `panel:RefreshCurrentPage()` -- re-render widgets (preserves scroll)

### Widget Types

| Type | Description |
|------|-------------|
| `toggle` | Checkbox with label |
| `range` | Slider with min/max/step |
| `select` | Dropdown with values/sorting |
| `input` | Text field |
| `color` | Color picker swatch |
| `execute` | Button with optional confirm |
| `label` | Static text (small/medium/large) |
| `header` | Section header with divider line |
| `description` | Wrapping paragraph text |
| `divider` | Horizontal separator |
| `group` | Collapsible container with children |
| `label_action` | Text label + action button |
| `item_row` | Item icon + name + remove button |
| `drop_slot` | Drag-and-drop item slot |

All widgets support `disabled` (value or function) for dynamic state.

Used by [Lantern](https://www.curseforge.com/wow/addons/lantern-qol) for its settings panel.

