## ![Developer Library -- Not a standalone addon](https://img.shields.io/badge/Developer Library -- Not a standalone addon-e04040?style=for-the-badge)

## **This is a developer library.** LanternUX does nothing on its own -- it's a dependency used by addons like [Lantern](https://www.curseforge.com/wow/addons/lantern-qol) to build settings panels. If you're a player, you don't need to install this manually.

***

[![Buy me a coffee](https://img.shields.io/badge/Buy me a coffee-fff?logo=buymeacoffee&logoColor=e08f2e)](https://buymeacoffee.com/sponsorn)

LanternUX is a standalone settings panel framework for WoW addon developers. No dependencies -- drop it in and create polished settings panels.

### Features

*   **Dark monochrome theme** inspired by Linear - near-black backgrounds with warm amber accents
*   **15 built-in widget types**: toggle, range (slider), select (dropdown), input (text field), color picker, execute (button), label, header, description, divider, callout, collapsible group, label with action button, item row, drop slot
*   **Sidebar navigation** with sections, collapsible groups, and accent-highlighted selection
*   **Widget search** with real-time filtering and jump-to-widget
*   **Description panel** that shows contextual help on widget hover
*   **Smooth scrolling** with easing and fade overlays
*   **Widget pooling** for efficient memory reuse across page switches
*   **Multiple page types**: widget-based or custom frame

### Quick Start

```
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

| Type         |Description                         |
| ------------ |----------------------------------- |
| <code>toggle</code> |Toggle switch with label            |
| <code>range</code> |Slider with min/max/step            |
| <code>select</code> |Dropdown with values/sorting        |
| <code>input</code> |Text field                          |
| <code>color</code> |Color picker swatch                 |
| <code>execute</code> |Button with optional confirm        |
| <code>label</code> |Static text (small/medium/large)    |
| <code>header</code> |Section header with divider line    |
| <code>description</code> |Wrapping paragraph text             |
| <code>divider</code> |Horizontal separator                |
| <code>callout</code> |Info/notice/warning box             |
| <code>group</code> |Collapsible container with children |
| <code>label_action</code> |Text label + action button          |
| <code>item_row</code> |Item icon + name + remove button    |
| <code>drop_slot</code> |Drag-and-drop item slot             |

All widgets support `disabled` (value or function) for dynamic state.

Full developer documentation is available on [GitHub](https://github.com/Sponsorn/Lantern/blob/master/LanternUX/DEVELOPERS.md).

Used by [Lantern](https://www.curseforge.com/wow/addons/lantern-qol) for its settings panel.