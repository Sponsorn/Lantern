local ADDON_NAME, Lantern = ...;
Lantern:RegisterLocale("deDE", {

    -- Shared
    ENABLE                                  = "Aktivieren",
    SHARED_FONT                             = "Schriftart",
    SHARED_FONT_SIZE                        = "Schriftgroesse",
    SHARED_FONT_OUTLINE                     = "Schriftumriss",
    SHARED_FONT_COLOR                       = "Schriftfarbe",
    SHARED_GROUP_POSITION                   = "Position",
    SHARED_LOCK_POSITION                    = "Position sperren",
    SHARED_RESET_POSITION                   = "Position zuruecksetzen",
    SHARED_GROUP_SOUND                      = "Sound",
    SHARED_SOUND_SELECT                     = "Sound",
    SHARED_PLAY_SOUND                       = "Sound abspielen",
    SHARED_PREVIEW                          = "Vorschau",
    SHARED_GROUP_DISPLAY                    = "Anzeige",
    SHARED_ANIMATION_STYLE                  = "Animationsstil",

    -- General settings
    GENERAL_MINIMAP_SHOW                    = "Minimap-Symbol anzeigen",
    GENERAL_MINIMAP_SHOW_DESC               = "Lantern Minimap-Symbol ein- oder ausblenden.",
    GENERAL_MINIMAP_MODERN                  = "Modernes Minimap-Symbol",
    GENERAL_MINIMAP_MODERN_DESC             = "Rahmen und Hintergrund des Minimap-Symbols entfernen fuer ein modernes Aussehen mit Laternen-Leuchten beim Ueberfahren.",
    GENERAL_PAUSE_MODIFIER                  = "Pause-Zusatztaste",
    GENERAL_PAUSE_MODIFIER_DESC             = "Halte diese Taste gedrueckt, um Auto-Funktionen voruebergehend zu pausieren (Auto Quest, Auto Queue, Auto Repair, usw.).",

    -- Modifier values (used in dropdowns)
    MODIFIER_SHIFT                          = "Shift",
    MODIFIER_CTRL                           = "Strg",
    MODIFIER_ALT                            = "Alt",

    -- Delete Confirm
    DELETECONFIRM_ENABLE_DESC               = "Ersetzt die DELETE-Eingabe durch einen Bestaetigungsbutton (Shift pausiert).",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_ENABLE_DESC              = "Verhindert das automatische Hinzufuegen von Zaubern zur Aktionsleiste.",

    -- Auto Queue
    AUTOQUEUE_ENABLE_DESC                   = "Auto Queue aktivieren oder deaktivieren.",
    AUTOQUEUE_AUTO_ACCEPT                   = "Rollenpruefungen automatisch annehmen",
    AUTOQUEUE_AUTO_ACCEPT_DESC              = "LFG-Rollenpruefungen automatisch annehmen.",
    AUTOQUEUE_ANNOUNCE                      = "Chat-Benachrichtigung",
    AUTOQUEUE_ANNOUNCE_DESC                 = "Chat-Nachricht ausgeben, wenn eine Rollenpruefung automatisch angenommen wurde.",
    AUTOQUEUE_CALLOUT                       = "Halte %s gedrueckt, um voruebergehend zu pausieren. Rollen werden im LFG-Tool festgelegt.",

    -- Faster Loot
    FASTERLOOT_ENABLE_DESC                  = "Sammelt sofort alle Beute, wenn ein Beutefenster geoeffnet wird. Halte %s zum Pausieren.",

    -- Auto Keystone
    AUTOKEYSTONE_ENABLE_DESC                = "Setzt deinen Schluesselstein automatisch ein, wenn die M+ Oberflaeche geoeffnet wird. Halte %s zum Ueberspringen.",

    -- Release Protection
    RELEASEPROTECT_ENABLE_DESC              = "Erfordert das Halten von %s zum Geist freilassen (verhindert versehentliches Freilassen).",
    RELEASEPROTECT_SKIP_SOLO                = "Solo ueberspringen",
    RELEASEPROTECT_SKIP_SOLO_DESC           = "Schutz deaktivieren, wenn du nicht in einer Gruppe bist.",
    RELEASEPROTECT_ACTIVE_IN                = "Aktiv in",
    RELEASEPROTECT_ACTIVE_IN_DESC           = "Immer: Schutz ueberall. Alle Instanzen: nur in Dungeons, Schlachtzuegen und PvP. Benutzerdefiniert: bestimmte Instanztypen waehlen.",
    RELEASEPROTECT_MODE_ALWAYS              = "Immer",
    RELEASEPROTECT_MODE_INSTANCES           = "Alle Instanzen",
    RELEASEPROTECT_MODE_CUSTOM              = "Benutzerdefiniert",
    RELEASEPROTECT_HOLD_DURATION            = "Haltedauer",
    RELEASEPROTECT_HOLD_DURATION_DESC       = "Wie lange die Zusatztaste gehalten werden muss, bevor der Freilassen-Button aktiv wird.",
    RELEASEPROTECT_INSTANCE_TYPES           = "Instanztypen",
    RELEASEPROTECT_OPEN_WORLD               = "Offene Welt",
    RELEASEPROTECT_OPEN_WORLD_DESC          = "Schutz in der offenen Welt (nicht innerhalb einer Instanz).",
    RELEASEPROTECT_DUNGEONS                 = "Dungeons",
    RELEASEPROTECT_DUNGEONS_DESC            = "Schutz in normalen, heroischen und mythischen Dungeons.",
    RELEASEPROTECT_MYTHICPLUS               = "Mythisch+",
    RELEASEPROTECT_MYTHICPLUS_DESC          = "Schutz in Mythisch+ Schluesselsteinen.",
    RELEASEPROTECT_RAIDS                    = "Schlachtzuege",
    RELEASEPROTECT_RAIDS_DESC               = "Schutz in allen Schlachtzugsschwierigkeiten (LFR, Normal, Heroisch, Mythisch).",
    RELEASEPROTECT_SCENARIOS                = "Szenarien",
    RELEASEPROTECT_SCENARIOS_DESC           = "Schutz in Szenario-Instanzen.",
    RELEASEPROTECT_DELVES                   = "Tiefen",
    RELEASEPROTECT_DELVES_DESC              = "Schutz in Tiefen.",
    RELEASEPROTECT_ARENAS                   = "Arenen",
    RELEASEPROTECT_ARENAS_DESC              = "Schutz in PvP-Arenen.",
    RELEASEPROTECT_BATTLEGROUNDS            = "Schlachtfelder",
    RELEASEPROTECT_BATTLEGROUNDS_DESC       = "Schutz in PvP-Schlachtfeldern.",

    -- Auto Repair
    AUTOREPAIR_ENABLE_DESC                  = "Auto Repair aktivieren oder deaktivieren.",
    AUTOREPAIR_SOURCE                       = "Reparaturquelle",
    AUTOREPAIR_SOURCE_DESC                  = "Eigenes Gold: immer eigenes Gold verwenden. Gildenbank zuerst: versucht Gildenbank, faellt auf eigenes Gold zurueck. Nur Gildenbank: nur Gildenbank verwenden (warnt, wenn nicht verfuegbar).",
    AUTOREPAIR_SOURCE_PERSONAL              = "Eigenes Gold",
    AUTOREPAIR_SOURCE_GUILD_FIRST           = "Gildenbank zuerst",
    AUTOREPAIR_SOURCE_GUILD_ONLY            = "Nur Gildenbank",
    AUTOREPAIR_CALLOUT                      = "Halte %s beim Oeffnen eines Haendlers, um Auto-Reparatur zu ueberspringen.",

    -- Splash page
    SPLASH_DESC                             = "Ein modulares Quality-of-Life-Addon fuer World of Warcraft.\nKlicke auf einen Modulnamen, um ihn zu konfigurieren, oder auf einen Statuspunkt, um ihn umzuschalten.",
    SPLASH_ENABLED                          = "Aktiviert",
    SPLASH_DISABLED                         = "Deaktiviert",
    SPLASH_CLICK_ENABLE                     = "Klicken zum Aktivieren",
    SPLASH_CLICK_DISABLE                    = "Klicken zum Deaktivieren",
    SPLASH_COMPANION_HEADER                 = "Begleit-Addons",
    SPLASH_CURSEFORGE                       = "CurseForge",
    SPLASH_COPY_LINK                        = "Link kopieren",
    SPLASH_COPY_HINT                        = "Ctrl+C zum Kopieren, Esc zum Schliessen",
    COPY                                    = "Kopieren",
    SELECT                                  = "Auswaehlen",

    -- Companion addon descriptions
    COMPANION_CO_LABEL                      = "Crafting Orders",
    COMPANION_CO_DESC                       = "Meldet Gilden-Auftragsaktivitaeten, persoenliche Auftragsbenachrichtigungen und einen Abschliessen- + Fluestern-Button.",
    COMPANION_WARBAND_LABEL                 = "Warband",
    COMPANION_WARBAND_DESC                  = "Organisiere Charaktere in Gruppen mit automatischem Goldausgleich zur/von der Kriegsmeute-Bank beim Oeffnen einer Bank.",

    -- Section headers
    SECTION_MODULES                         = "Module",
    SECTION_ADDONS                          = "Addons",

    -- General settings page
    SECTION_GENERAL                         = "Allgemein",
    SECTION_GENERAL_DESC                    = "Allgemeine Addon-Einstellungen.",

    -- Sidebar page labels
    PAGE_HOME                               = "Startseite",

    -- Category headers
    CATEGORY_GENERAL                        = "Allgemein",
    CATEGORY_DUNGEONS                       = "Dungeons & M+",
    CATEGORY_QUESTING                       = "Quests & Welt",

    -- Messages (Options.lua / ui.lua)
    MSG_OPTIONS_AFTER_COMBAT                = "Optionen werden nach dem Kampf geoeffnet.",

    -- ui.lua: Minimap tooltip
    UI_MINIMAP_TITLE                        = "Lantern",
    UI_MINIMAP_LEFT_CLICK                   = "Linksklick: Optionen oeffnen",
    UI_MINIMAP_SHIFT_CLICK                  = "Shift+Linksklick: UI neu laden",

    -- ui.lua: StaticPopup link dialog
    UI_COPY_LINK_PROMPT                     = "Ctrl+C zum Kopieren des Links",

    -- ui.lua: Blizzard Settings stub
    UI_SETTINGS_VERSION                     = "Version: %s",
    UI_SETTINGS_AUTHOR                      = "Autor: Dede im Spiel / Sponsorn auf CurseForge & GitHub",
    UI_SETTINGS_THANKS                      = "Besonderen Dank an copyrighters, die mich in die Gaenge gebracht haben.",
    UI_SETTINGS_OPEN                        = "Einstellungen oeffnen",
    UI_SETTINGS_AVAILABLE_MODULES           = "Verfuegbare Module",
    UI_SETTINGS_CO_DESC                     = "Crafting Orders: meldet Gilden-Auftragsaktivitaeten, persoenliche Auftragsbenachrichtigungen und einen Abschliessen- + Fluestern-Button.",
    UI_SETTINGS_ALREADY_ENABLED             = "Bereits aktiviert",
    UI_SETTINGS_WARBAND_DESC                = "Warband: organisiere Charaktere in Gruppen mit automatischem Goldausgleich zur/von der Kriegsmeute-Bank beim Oeffnen einer Bank.",

    -- core.lua: Slash command
    MSG_MISSINGPET_NOT_FOUND                = "Missing Pet Modul nicht gefunden.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Metadata (title/desc)
    ---------------------------------------------------------------------------

    -- Auto Quest
    AUTOQUEST_TITLE                         = "Auto Quest",
    AUTOQUEST_DESC                          = "Nimmt Quests automatisch an und gibt sie ab.",

    -- Auto Queue
    AUTOQUEUE_TITLE                         = "Auto Queue",
    AUTOQUEUE_DESC                          = "Nimmt Rollenpruefungen automatisch an basierend auf deiner LFG-Rollenauswahl.",

    -- Auto Repair
    AUTOREPAIR_TITLE                        = "Auto Repair",
    AUTOREPAIR_DESC                         = "Repariert Ausruestung automatisch bei Haendlern.",

    -- Auto Sell
    AUTOSELL_TITLE                          = "Auto Sell",
    AUTOSELL_DESC                           = "Verkauft automatisch Ramsch und benutzerdefinierte Gegenstaende bei Haendlern.",

    -- Chat Filter
    CHATFILTER_TITLE                        = "Chat Filter",
    CHATFILTER_DESC                         = "Filtert Goldspam, Boost-Werbung und unerwuenschte Nachrichten aus Fluestern und oeffentlichen Kanaelen.",

    -- Cursor Ring
    CURSORRING_TITLE                        = "Cursor Ring & Trail",
    CURSORRING_DESC                         = "Zeigt anpassbare Ringe um den Mauszeiger mit Zauber-/GCD-Anzeigen und einer optionalen Spur.",

    -- Delete Confirm
    DELETECONFIRM_TITLE                     = "Delete Confirm",
    DELETECONFIRM_DESC                      = "Blendet die Loeschen-Eingabe aus und aktiviert den Bestaetigungsbutton.",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_TITLE                    = "Disable Auto Add Spells",
    DISABLEAUTOADD_DESC                     = "Verhindert das automatische Hinzufuegen von Zaubern zu Aktionsleisten.",

    -- Missing Pet
    MISSINGPET_TITLE                        = "Missing Pet",
    MISSINGPET_DESC                         = "Zeigt eine Warnung an, wenn dein Begleiter fehlt oder auf passiv gestellt ist.",

    -- Auto Playstyle
    AUTOPLAYSTYLE_TITLE                     = "Auto Playstyle",
    AUTOPLAYSTYLE_DESC                      = "Waehlt automatisch deinen bevorzugten Spielstil beim Erstellen von M+ Gruppen im Gruppensuche-Tool.",

    -- Faster Loot
    FASTERLOOT_TITLE                        = "Faster Loot",
    FASTERLOOT_DESC                         = "Sammelt sofort alle Beute, wenn ein Beutefenster geoeffnet wird.",

    -- Auto Keystone
    AUTOKEYSTONE_TITLE                      = "Auto Keystone",
    AUTOKEYSTONE_DESC                       = "Setzt automatisch deinen Mythisch+ Schluesselstein ein, wenn die Herausforderungsmodus-Oberflaeche geoeffnet wird.",

    -- Release Protection
    RELEASEPROTECT_TITLE                    = "Release Protection",
    RELEASEPROTECT_DESC                     = "Erfordert das Halten der Pause-Zusatztaste, bevor der Geist freigelassen wird, um versehentliche Klicks zu verhindern.",

    -- Combat Timer
    COMBATTIMER_TITLE                       = "Combat Timer",
    COMBATTIMER_DESC                        = "Zeigt einen Timer an, der die Kampfdauer misst.",

    -- Combat Alert
    COMBATALERT_TITLE                       = "Combat Alert",
    COMBATALERT_DESC                        = "Zeigt eine Ein-/Ausblend-Textnachricht beim Betreten oder Verlassen des Kampfes.",

    -- Range Check
    RANGECHECK_TITLE                        = "Range Check",
    RANGECHECK_DESC                         = "Zeigt den Reichweiten-Status fuer dein aktuelles Ziel an.",

    -- Tooltip
    TOOLTIP_TITLE                           = "Tooltip",
    TOOLTIP_DESC                            = "Erweitert Tooltips mit IDs und Reittier-Namen.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Print Messages
    ---------------------------------------------------------------------------

    -- Auto Queue messages
    AUTOQUEUE_MSG_ACCEPTED                  = "Rollenpruefung automatisch angenommen.",

    -- Auto Repair messages
    AUTOREPAIR_MSG_GUILD_UNAVAILABLE        = "Reparatur nicht moeglich: Gildenbank nicht verfuegbar.",
    AUTOREPAIR_MSG_REPAIRED_GUILD           = "Repariert fuer %s (Gildenbank).",
    AUTOREPAIR_MSG_REPAIRED                 = "Repariert fuer %s.",
    AUTOREPAIR_MSG_NOT_ENOUGH_GOLD          = "Reparatur nicht moeglich: nicht genug Gold (%s benoetigt).",

    -- Auto Sell messages
    AUTOSELL_MSG_SOLD_ITEMS                 = "%d Gegenstand/Gegenstaende fuer %s verkauft.",

    -- Faster Loot messages
    FASTERLOOT_MSG_INV_FULL                 = "Inventar ist voll - einige Gegenstaende konnten nicht aufgesammelt werden.",

    -- Chat Filter messages
    CHATFILTER_MSG_ACTIVE                   = "Chat Filter aktiv mit %d Schluesselwoertern.",
    CHATFILTER_MSG_KEYWORD_EXISTS           = "Schluesselwort bereits in der Filterliste.",
    CHATFILTER_MSG_KEYWORD_ADDED            = "\"%s\" zum Chatfilter hinzugefuegt.",

    -- Auto Sell item messages
    AUTOSELL_MSG_ALREADY_IN_LIST            = "Gegenstand bereits in der Verkaufsliste.",
    AUTOSELL_MSG_ADDED_TO_LIST              = "%s zur Verkaufsliste hinzugefuegt.",
    AUTOSELL_MSG_INVALID_ITEM_ID            = "Ungueltige Item ID.",

    -- Tooltip messages
    TOOLTIP_MSG_ID_COPIED                   = "%s %s kopiert.",

    -- Release Protection overlay text
    RELEASEPROTECT_HOLD_PROGRESS            = "Halte %s... %.1fs",
    RELEASEPROTECT_HOLD_PROMPT              = "Halte %s (%.1fs)",

    -- Auto Quest messages
    AUTOQUEST_MSG_NO_NPC                    = "Kein NPC gefunden. Sprich zuerst mit einem NPC.",
    AUTOQUEST_MSG_BLOCKED_NPC               = "Blockierter NPC: %s",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoQuest WidgetOptions
    ---------------------------------------------------------------------------

    AUTOQUEST_ENABLE_DESC                   = "Auto Quest aktivieren oder deaktivieren.",
    AUTOQUEST_AUTO_ACCEPT                   = "Quests automatisch annehmen",
    AUTOQUEST_AUTO_ACCEPT_DESC              = "Quests automatisch von NPCs annehmen.",
    AUTOQUEST_AUTO_TURNIN                   = "Quests automatisch abgeben",
    AUTOQUEST_AUTO_TURNIN_DESC              = "Abgeschlossene Quests automatisch bei NPCs abgeben.",
    AUTOQUEST_SINGLE_REWARD                 = "Einzelne Belohnung automatisch waehlen",
    AUTOQUEST_SINGLE_REWARD_DESC            = "Wenn eine Quest nur eine Belohnung bietet, diese automatisch auswaehlen.",
    AUTOQUEST_SINGLE_GOSSIP                 = "Einzelne Dialogoption automatisch waehlen",
    AUTOQUEST_SINGLE_GOSSIP_DESC            = "NPCs mit nur einer Dialogoption automatisch auswaehlen, um Dialogketten zu Quests zu durchlaufen.",
    AUTOQUEST_SKIP_TRIVIAL                  = "Triviale Quests ueberspringen",
    AUTOQUEST_SKIP_TRIVIAL_DESC             = "Graue (triviale/niedrigstufige) Quests nicht automatisch annehmen.",
    AUTOQUEST_CALLOUT                       = "Halte %s gedrueckt, um automatisches Annehmen und Abgeben voruebergehend zu pausieren.",
    AUTOQUEST_ADDON_BYPASS_NOTE             = "Hinweis: Andere Quest-Automatisierungs-Addons (QuickQuest, Plumber, usw.) koennen die Blockliste umgehen.",
    AUTOQUEST_ADD_NPC                       = "Aktuellen NPC zur Blockliste hinzufuegen",
    AUTOQUEST_ADD_NPC_DESC                  = "Sprich mit einem NPC und klicke dann diesen Button, um ihn von der Auto-Quest-Automatisierung auszuschliessen.",
    AUTOQUEST_ZONE_FILTER                   = "Zonenfilter",
    AUTOQUEST_NPC_ZONE_FILTER_DESC          = "Blockierte NPCs nach Zone filtern.",
    AUTOQUEST_QUEST_ZONE_FILTER_DESC        = "Blockierte Quests nach Zone filtern.",
    AUTOQUEST_ZONE_ALL                      = "Alle Zonen",
    AUTOQUEST_ZONE_CURRENT                  = "Aktuelle Zone",
    AUTOQUEST_BLOCKED_NPCS                  = "Blockierte NPCs (%d)",
    AUTOQUEST_NPC_EMPTY_ALL                 = "Noch keine NPCs blockiert -- waehle einen NPC an und klicke den Button oben, um ihn hinzuzufuegen.",
    AUTOQUEST_NPC_EMPTY_ZONE                = "Keine blockierten NPCs in %s.",
    AUTOQUEST_REMOVE_NPC_DESC               = "%s von der Blockliste entfernen.",
    AUTOQUEST_BLOCKED_QUESTS_HEADER         = "Blockierte Quests",
    AUTOQUEST_BLOCKED_QUESTS_NOTE           = "Blockierte Quests werden nicht automatisch angenommen oder abgegeben.",
    AUTOQUEST_QUEST_EMPTY_ALL               = "Noch keine Quests blockiert -- automatisch angenommene Quests von blockierten NPCs erscheinen hier.",
    AUTOQUEST_QUEST_EMPTY_ZONE              = "Keine blockierten Quests in %s.",
    AUTOQUEST_UNKNOWN_NPC                   = "Unbekannter NPC",
    AUTOQUEST_QUEST_LABEL_WITH_ID           = "%s (ID: %s)",
    AUTOQUEST_QUEST_LABEL_ID_ONLY           = "Quest ID: %s",
    AUTOQUEST_UNBLOCK_DESC                  = "Diese Quest entsperren.",
    AUTOQUEST_BLOCK_QUEST                   = "Quest blockieren",
    AUTOQUEST_BLOCKED                       = "Blockiert",
    AUTOQUEST_BLOCK_DESC                    = "Diese Quest von zukuenftiger Automatisierung ausschliessen.",
    AUTOQUEST_NPC_PREFIX                    = "NPC: %s",
    AUTOQUEST_NO_AUTOMATED                  = "Noch keine automatisierten Quests.",
    AUTOQUEST_RECENT_AUTOMATED              = "Letzte automatisierte Quests (%d)",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoSell WidgetOptions
    ---------------------------------------------------------------------------

    AUTOSELL_ENABLE_DESC                    = "Auto Sell aktivieren oder deaktivieren.",
    AUTOSELL_SELL_GRAYS                     = "Graue Gegenstaende verkaufen",
    AUTOSELL_SELL_GRAYS_DESC                = "Automatisch alle Gegenstaende schlechter Qualitaet (grau) verkaufen.",
    AUTOSELL_CALLOUT                        = "Halte %s beim Oeffnen eines Haendlers, um Auto-Verkauf zu ueberspringen.",
    AUTOSELL_DRAG_DROP                      = "Drag & Drop:",
    AUTOSELL_DRAG_GLOBAL_DESC               = "Ziehe einen Gegenstand aus deinen Taschen und lege ihn hier ab, um ihn zur globalen Verkaufsliste hinzuzufuegen.",
    AUTOSELL_DRAG_CHAR_DESC                 = "Ziehe einen Gegenstand aus deinen Taschen und lege ihn hier ab, um ihn zur Verkaufsliste dieses Charakters hinzuzufuegen.",
    AUTOSELL_ITEM_ID                        = "Item ID",
    AUTOSELL_ITEM_ID_GLOBAL_DESC            = "Gib eine Item ID ein, um sie zur globalen Verkaufsliste hinzuzufuegen.",
    AUTOSELL_ITEM_ID_CHAR_DESC              = "Gib eine Item ID ein, um sie zur Verkaufsliste dieses Charakters hinzuzufuegen.",
    AUTOSELL_REMOVE_DESC                    = "Diesen Gegenstand von der Verkaufsliste entfernen.",
    AUTOSELL_GLOBAL_LIST                    = "Globale Verkaufsliste (%d)",
    AUTOSELL_CHAR_LIST                      = "%s Verkaufsliste (%d)",
    AUTOSELL_CHAR_ONLY_NOTE                 = "Gegenstaende in dieser Liste werden nur auf diesem Charakter verkauft.",
    AUTOSELL_EMPTY_GLOBAL                   = "Keine Gegenstaende in der globalen Verkaufsliste.",
    AUTOSELL_EMPTY_CHAR                     = "Keine Gegenstaende in der Charakter-Verkaufsliste.",

    ---------------------------------------------------------------------------
    -- Phase 3: CursorRing WidgetOptions
    ---------------------------------------------------------------------------

    CURSORRING_ENABLE_DESC                  = "Cursor Ring & Trail Modul aktivieren oder deaktivieren.",
    CURSORRING_PREVIEW_START                = "Vorschau starten",
    CURSORRING_PREVIEW_STOP                 = "Vorschau beenden",
    CURSORRING_PREVIEW_DESC                 = "Alle visuellen Elemente am Cursor fuer Echtzeitbearbeitung anzeigen. Deaktiviert sich automatisch, wenn das Einstellungsfenster geschlossen wird.",
    CURSORRING_GROUP_GENERAL                = "Allgemein",
    CURSORRING_SHOW_OOC                     = "Ausserhalb des Kampfes anzeigen",
    CURSORRING_SHOW_OOC_DESC                = "Den Cursor Ring ausserhalb von Kampf und Instanzen anzeigen.",
    CURSORRING_COMBAT_OPACITY               = "Kampf-Deckkraft",
    CURSORRING_COMBAT_OPACITY_DESC          = "Ring-Deckkraft im Kampf oder in instanzierten Inhalten.",
    CURSORRING_OOC_OPACITY                  = "Ausser-Kampf-Deckkraft",
    CURSORRING_OOC_OPACITY_DESC             = "Ring-Deckkraft ausserhalb des Kampfes.",
    CURSORRING_GROUP_RING1                  = "Ring 1 (Aussen)",
    CURSORRING_ENABLE_RING1                 = "Ring 1 aktivieren",
    CURSORRING_ENABLE_RING1_DESC            = "Den aeusseren Ring anzeigen.",
    CURSORRING_SHAPE                        = "Form",
    CURSORRING_RING_SHAPE_DESC              = "Ringform.",
    CURSORRING_SHwPE_CIRCLE                 = "Kreis",
    CURSORRING_SHAPE_THIN                   = "Duenner Kreis",
    CURSORRING_COLOR                        = "Farbe",
    CURSORRING_RING1_COLOR_DESC             = "Ring 1 Farbe.",
    CURSORRING_SIZE                         = "Groesse",
    CURSORRING_RING1_SIZE_DESC              = "Ring 1 Groesse in Pixeln.",
    CURSORRING_GROUP_RING2                  = "Ring 2 (Innen)",
    CURSORRING_ENABLE_RING2                 = "Ring 2 aktivieren",
    CURSORRING_ENABLE_RING2_DESC            = "Den inneren Ring anzeigen.",
    CURSORRING_RING2_COLOR_DESC             = "Ring 2 Farbe.",
    CURSORRING_RING2_SIZE_DESC              = "Ring 2 Groesse in Pixeln.",
    CURSORRING_GROUP_DOT                    = "Mittelpunkt",
    CURSORRING_ENABLE_DOT                   = "Punkt aktivieren",
    CURSORRING_ENABLE_DOT_DESC              = "Einen kleinen Punkt in der Mitte der Cursor-Ringe anzeigen.",
    CURSORRING_DOT_COLOR_DESC               = "Punktfarbe.",
    CURSORRING_DOT_SIZE_DESC                = "Punktgroesse in Pixeln.",
    CURSORRING_GROUP_CAST                   = "Zaubereffekt",
    CURSORRING_ENABLE_CAST                  = "Zaubereffekt aktivieren",
    CURSORRING_ENABLE_CAST_DESC             = "Einen visuellen Effekt waehrend des Zauberns und Kanalisierens anzeigen.",
    CURSORRING_STYLE                        = "Stil",
    CURSORRING_CAST_STYLE_DESC              = "Segmente: Bogen leuchtet fortschreitend auf. Fuellen: Form skaliert von der Mitte. Swipe: Cooldown-Sweep (kann gleichzeitig mit GCD laufen).",
    CURSORRING_STYLE_SEGMENTS               = "Segmente",
    CURSORRING_STYLE_FILL                   = "Fuellen",
    CURSORRING_STYLE_SWIPE                  = "Swipe",
    CURSORRING_CAST_COLOR_DESC              = "Zaubereffekt-Farbe.",
    CURSORRING_SWIPE_OFFSET                 = "Swipe-Versatz",
    CURSORRING_SWIPE_OFFSET_DESC            = "Pixel-Versatz fuer den Zauber-Swipe-Ring ausserhalb des GCD-Rings. Gilt nur fuer den Swipe-Stil.",
    CURSORRING_GROUP_GCD                    = "GCD-Anzeige",
    CURSORRING_ENABLE_GCD                   = "GCD aktivieren",
    CURSORRING_ENABLE_GCD_DESC              = "Einen Cooldown-Swipe fuer den globalen Cooldown anzeigen.",
    CURSORRING_GCD_COLOR_DESC               = "GCD-Swipe-Farbe.",
    CURSORRING_OFFSET                       = "Versatz",
    CURSORRING_GCD_OFFSET_DESC              = "Pixel-Versatz fuer den GCD-Ring ausserhalb von Ring 1.",
    CURSORRING_GROUP_TRAIL                  = "Maus-Spur",
    CURSORRING_ENABLE_TRAIL                 = "Spur aktivieren",
    CURSORRING_ENABLE_TRAIL_DESC            = "Eine verblassende Spur hinter dem Cursor anzeigen.",
    CURSORRING_TRAIL_STYLE_DESC             = "Spur-Anzeigestil. Glow: verblassende Glitzerspur. Line: durchgehendes duennes Band. Thick Line: breites Band. Dots: verblassende Punkte mit Abstand. Custom: manuelle Einstellungen.",
    CURSORRING_TRAIL_GLOW                   = "Glow",
    CURSORRING_TRAIL_LINE                   = "Line",
    CURSORRING_TRAIL_THICKLINE              = "Thick Line",
    CURSORRING_TRAIL_DOTS                   = "Dots",
    CURSORRING_TRAIL_CUSTOM                 = "Custom",
    CURSORRING_TRAIL_COLOR_DESC             = "Spur-Farbvoreinstellung. Klassenfarbe verwendet automatisch deine aktuelle Klassenfarbe. Rainbow, Ember und Ocean sind Mehrfarben-Farbverlaeufe. Custom laesst dich unten eine beliebige Farbe waehlen.",
    CURSORRING_TRAIL_COLOR_CUSTOM           = "Custom",
    CURSORRING_TRAIL_COLOR_CLASS            = "Klassenfarbe",
    CURSORRING_TRAIL_COLOR_GOLD             = "Lantern Gold",
    CURSORRING_TRAIL_COLOR_ARCANE           = "Arkan",
    CURSORRING_TRAIL_COLOR_FEL              = "Fel",
    CURSORRING_TRAIL_COLOR_FIRE             = "Feuer",
    CURSORRING_TRAIL_COLOR_FROST            = "Frost",
    CURSORRING_TRAIL_COLOR_HOLY             = "Heilig",
    CURSORRING_TRAIL_COLOR_SHADOW           = "Schatten",
    CURSORRING_TRAIL_COLOR_RAINBOW          = "Regenbogen",
    CURSORRING_TRAIL_COLOR_ALAR             = "Al'ar",
    CURSORRING_TRAIL_COLOR_EMBER            = "Glut",
    CURSORRING_TRAIL_COLOR_OCEAN            = "Ozean",
    CURSORRING_CUSTOM_COLOR                 = "Benutzerdefinierte Farbe",
    CURSORRING_CUSTOM_COLOR_DESC            = "Spurfarbe (wird nur verwendet, wenn Farbe auf Custom gestellt ist).",
    CURSORRING_DURATION                     = "Dauer",
    CURSORRING_DURATION_DESC                = "Wie lange Spurpunkte bestehen, bevor sie verblassen.",
    CURSORRING_MAX_POINTS                   = "Max. Punkte",
    CURSORRING_MAX_POINTS_DESC              = "Anzahl der Spurpunkte im Pool. Hoehere Werte erzeugen laengere Spuren, verbrauchen aber mehr Speicher.",
    CURSORRING_DOT_SIZE                     = "Punktgroesse",
    CURSORRING_DOT_SIZE_TRAIL_DESC          = "Groesse jedes Spurpunkts in Pixeln.",
    CURSORRING_DOT_SPACING                  = "Punktabstand",
    CURSORRING_DOT_SPACING_DESC             = "Mindestabstand in Pixeln, bevor ein neuer Spurpunkt gesetzt wird. Niedrigere Werte erzeugen eine dichtere, durchgehendere Spur.",
    CURSORRING_SHRINK_AGE                   = "Mit Alter schrumpfen",
    CURSORRING_SHRINK_AGE_DESC              = "Spurpunkte schrumpfen beim Verblassen. Deaktivieren fuer eine gleichmaessig breite Spur.",
    CURSORRING_TAPER_DISTANCE               = "Mit Entfernung verjuengen",
    CURSORRING_TAPER_DISTANCE_DESC          = "Spurpunkte schrumpfen und verblassen zum Ende hin und erzeugen einen sich verjuengenden Pinselstrich-Effekt.",
    CURSORRING_SPARKLE                      = "Funkeln",
    CURSORRING_SPARKLE_DESC                 = "Fuegt kleine glitzernde Partikel entlang der Spur hinzu, wenn du den Cursor bewegst.",
    CURSORRING_SPARKLE_OFF                  = "Aus",
    CURSORRING_SPARKLE_STATIC               = "Statisch",
    CURSORRING_SPARKLE_TWINKLE              = "Glitzern",
    CURSORRING_TRAIL_PERF_NOTE              = "Die Spur laeuft pro Frame. Mehr Punkte, Funkeln und Effekte verbrauchen mehr CPU.",

    ---------------------------------------------------------------------------
    -- Phase 3: MissingPet WidgetOptions
    ---------------------------------------------------------------------------

    MISSINGPET_ENABLE_DESC                  = "Missing Pet Warnung aktivieren oder deaktivieren.",
    MISSINGPET_GROUP_WARNING                = "Warnungseinstellungen",
    MISSINGPET_SHOW_MISSING                 = "Fehlend-Warnung anzeigen",
    MISSINGPET_SHOW_MISSING_DESC            = "Eine Warnung anzeigen, wenn dein Begleiter entlassen oder tot ist.",
    MISSINGPET_SHOW_PASSIVE                 = "Passiv-Warnung anzeigen",
    MISSINGPET_SHOW_PASSIVE_DESC            = "Eine Warnung anzeigen, wenn dein Begleiter auf passiv gestellt ist.",
    MISSINGPET_MISSING_TEXT                 = "Fehlend-Text",
    MISSINGPET_MISSING_TEXT_DESC            = "Text, der angezeigt wird, wenn dein Begleiter fehlt.",
    MISSINGPET_PASSIVE_TEXT                 = "Passiv-Text",
    MISSINGPET_PASSIVE_TEXT_DESC            = "Text, der angezeigt wird, wenn dein Begleiter auf passiv gestellt ist.",
    MISSINGPET_MISSING_COLOR                = "Fehlend-Farbe",
    MISSINGPET_MISSING_COLOR_DESC           = "Farbe fuer den Warnungstext bei fehlendem Begleiter.",
    MISSINGPET_PASSIVE_COLOR                = "Passiv-Farbe",
    MISSINGPET_PASSIVE_COLOR_DESC           = "Farbe fuer den Warnungstext bei passivem Begleiter.",
    MISSINGPET_ANIMATION_DESC               = "Waehle, wie der Warnungstext animiert wird.",
    MISSINGPET_GROUP_FONT                   = "Schrifteinstellungen",
    MISSINGPET_FONT_DESC                    = "Schriftart fuer den Warnungstext auswaehlen.",
    MISSINGPET_FONT_SIZE_DESC               = "Groesse des Warnungstextes.",
    MISSINGPET_FONT_OUTLINE_DESC            = "Umrissstil fuer den Warnungstext.",
    MISSINGPET_LOCK_POSITION_DESC           = "Verhindert, dass die Warnung verschoben wird.",
    MISSINGPET_RESET_POSITION_DESC          = "Position des Warnungsfensters auf die Bildschirmmitte zuruecksetzen.",
    MISSINGPET_GROUP_VISIBILITY             = "Sichtbarkeit",
    MISSINGPET_HIDE_MOUNTED                 = "Auf Reittier ausblenden",
    MISSINGPET_HIDE_MOUNTED_DESC            = "Warnung ausblenden, waehrend du auf einem Reittier, Taxi oder Fahrzeug bist.",
    MISSINGPET_HIDE_REST                    = "In Erholungsgebieten ausblenden",
    MISSINGPET_HIDE_REST_DESC               = "Warnung ausblenden, waehrend du dich in einem Erholungsgebiet befindest (Staedte und Gasthaeuser).",
    MISSINGPET_DISMOUNT_DELAY               = "Absitz-Verzoegerung",
    MISSINGPET_DISMOUNT_DELAY_DESC          = "Sekunden, die nach dem Absitzen gewartet wird, bevor die Warnung angezeigt wird. Auf 0 setzen fuer sofortige Anzeige.",
    MISSINGPET_PLAY_SOUND_DESC              = "Einen Sound abspielen, wenn die Warnung angezeigt wird.",
    MISSINGPET_SOUND_MISSING                = "Sound bei Fehlen",
    MISSINGPET_SOUND_MISSING_DESC           = "Sound abspielen, wenn der Begleiter fehlt.",
    MISSINGPET_SOUND_PASSIVE                = "Sound bei Passiv",
    MISSINGPET_SOUND_PASSIVE_DESC           = "Sound abspielen, wenn der Begleiter auf passiv gestellt ist.",
    MISSINGPET_SOUND_COMBAT                 = "Sound im Kampf",
    MISSINGPET_SOUND_COMBAT_DESC            = "Sound im Kampf weiter abspielen. Wenn deaktiviert, stoppt der Sound bei Kampfbeginn.",
    MISSINGPET_SOUND_REPEAT                 = "Sound wiederholen",
    MISSINGPET_SOUND_REPEAT_DESC            = "Den Sound in regelmaessigen Abstaenden wiederholen, waehrend die Warnung angezeigt wird.",
    MISSINGPET_SOUND_SELECT_DESC            = "Abzuspielenden Sound auswaehlen. Klicke auf das Lautsprechersymbol fuer eine Vorschau.",
    MISSINGPET_REPEAT_INTERVAL              = "Wiederholungsintervall",
    MISSINGPET_REPEAT_INTERVAL_DESC         = "Sekunden zwischen Soundwiederholungen.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatAlert WidgetOptions
    ---------------------------------------------------------------------------

    COMBATALERT_ENABLE_DESC                 = "Textmeldungen beim Betreten/Verlassen des Kampfes anzeigen.",
    COMBATALERT_PREVIEW_DESC                = "Kampfbeginn-/Kampfende-Meldungen auf dem Bildschirm fuer Echtzeitbearbeitung wiederholen. Deaktiviert sich automatisch, wenn das Einstellungsfenster geschlossen wird.",
    COMBATALERT_GROUP_ENTER                 = "Kampfbeginn",
    COMBATALERT_SHOW_ENTER                  = "Kampfbeginn-Meldung anzeigen",
    COMBATALERT_SHOW_ENTER_DESC             = "Eine Meldung beim Betreten des Kampfes anzeigen.",
    COMBATALERT_ENTER_TEXT                   = "Kampfbeginn-Text",
    COMBATALERT_ENTER_TEXT_DESC             = "Text, der beim Betreten des Kampfes angezeigt wird.",
    COMBATALERT_ENTER_COLOR                 = "Kampfbeginn-Farbe",
    COMBATALERT_ENTER_COLOR_DESC            = "Farbe des Kampfbeginn-Textes.",
    COMBATALERT_GROUP_LEAVE                 = "Kampfende",
    COMBATALERT_SHOW_LEAVE                  = "Kampfende-Meldung anzeigen",
    COMBATALERT_SHOW_LEAVE_DESC             = "Eine Meldung beim Verlassen des Kampfes anzeigen.",
    COMBATALERT_LEAVE_TEXT                   = "Kampfende-Text",
    COMBATALERT_LEAVE_TEXT_DESC             = "Text, der beim Verlassen des Kampfes angezeigt wird.",
    COMBATALERT_LEAVE_COLOR                 = "Kampfende-Farbe",
    COMBATALERT_LEAVE_COLOR_DESC            = "Farbe des Kampfende-Textes.",
    COMBATALERT_GROUP_FONT                  = "Schrift- und Anzeigeeinstellungen",
    COMBATALERT_FONT_DESC                   = "Schriftart fuer den Meldungstext auswaehlen.",
    COMBATALERT_FONT_SIZE_DESC              = "Groesse des Meldungstextes.",
    COMBATALERT_FONT_OUTLINE_DESC           = "Umrissstil fuer den Meldungstext.",
    COMBATALERT_FADE_DURATION               = "Ausblenddauer",
    COMBATALERT_FADE_DURATION_DESC          = "Gesamtdauer der Meldung (Halten + Ausblenden) in Sekunden.",
    COMBATALERT_PLAY_SOUND_DESC             = "Einen Sound abspielen, wenn die Meldung angezeigt wird.",
    COMBATALERT_SOUND_SELECT_DESC           = "Abzuspielenden Sound auswaehlen.",
    COMBATALERT_LOCK_POSITION_DESC          = "Verhindert, dass die Meldung verschoben wird.",
    COMBATALERT_RESET_POSITION_DESC         = "Meldung auf die Standardposition zuruecksetzen.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatTimer WidgetOptions
    ---------------------------------------------------------------------------

    COMBATTIMER_ENABLE_DESC                 = "Einen Timer waehrend des Kampfes anzeigen.",
    COMBATTIMER_PREVIEW_DESC                = "Den Timer auf dem Bildschirm fuer Echtzeitbearbeitung anzeigen. Deaktiviert sich automatisch, wenn das Einstellungsfenster geschlossen wird.",
    COMBATTIMER_FONT_DESC                   = "Schriftart fuer den Timer-Text auswaehlen.",
    COMBATTIMER_FONT_SIZE_DESC              = "Groesse des Timer-Textes.",
    COMBATTIMER_FONT_OUTLINE_DESC           = "Umrissstil fuer den Timer-Text.",
    COMBATTIMER_FONT_COLOR_DESC             = "Farbe des Timer-Textes.",
    COMBATTIMER_STICKY_DURATION             = "Nachhaltedauer",
    COMBATTIMER_STICKY_DURATION_DESC        = "Sekunden, die die Endzeit nach dem Kampfende weiterhin angezeigt wird. Auf 0 setzen, um sofort auszublenden.",
    COMBATTIMER_LOCK_POSITION_DESC          = "Verhindert, dass der Timer verschoben wird.",
    COMBATTIMER_RESET_POSITION_DESC         = "Timer auf die Standardposition zuruecksetzen.",

    ---------------------------------------------------------------------------
    -- Phase 3: RangeCheck WidgetOptions
    ---------------------------------------------------------------------------

    RANGECHECK_ENABLE_DESC                  = "Reichweiten-Status fuer dein aktuelles Ziel anzeigen.",
    RANGECHECK_HIDE_IN_RANGE                = "In Reichweite ausblenden",
    RANGECHECK_HIDE_IN_RANGE_DESC           = "Anzeige ausblenden, wenn dein Ziel in Reichweite ist. Zeigt nur an, wenn ausser Reichweite.",
    RANGECHECK_COMBAT_ONLY                  = "Nur im Kampf",
    RANGECHECK_COMBAT_ONLY_DESC             = "Reichweite nur im Kampf anzeigen.",
    RANGECHECK_GROUP_STATUS                 = "Statustext",
    RANGECHECK_IN_RANGE_TEXT                = "In-Reichweite-Text",
    RANGECHECK_IN_RANGE_TEXT_DESC           = "Text, der angezeigt wird, wenn dein Ziel in Reichweite ist.",
    RANGECHECK_OUT_OF_RANGE_TEXT            = "Ausser-Reichweite-Text",
    RANGECHECK_OUT_OF_RANGE_TEXT_DESC       = "Text, der angezeigt wird, wenn dein Ziel ausser Reichweite ist.",
    RANGECHECK_IN_RANGE_COLOR               = "In-Reichweite-Farbe",
    RANGECHECK_IN_RANGE_COLOR_DESC          = "Farbe fuer den In-Reichweite-Text.",
    RANGECHECK_OUT_OF_RANGE_COLOR           = "Ausser-Reichweite-Farbe",
    RANGECHECK_OUT_OF_RANGE_COLOR_DESC      = "Farbe fuer den Ausser-Reichweite-Text.",
    RANGECHECK_ANIMATION_DESC               = "Waehle, wie der Statustext bei Zustandswechsel animiert wird.",
    RANGECHECK_FONT_DESC                    = "Schriftart fuer den Reichweitentext auswaehlen.",
    RANGECHECK_FONT_SIZE_DESC               = "Groesse des Reichweitentextes.",
    RANGECHECK_FONT_OUTLINE_DESC            = "Umrissstil fuer den Reichweitentext.",
    RANGECHECK_LOCK_POSITION_DESC           = "Verhindert, dass die Reichweitenanzeige verschoben wird.",
    RANGECHECK_RESET_POSITION_DESC          = "Reichweitenanzeige auf die Standardposition zuruecksetzen.",

    ---------------------------------------------------------------------------
    -- Phase 3: ChatFilter WidgetOptions
    ---------------------------------------------------------------------------

    CHATFILTER_ENABLE_DESC                  = "Chat Filter aktivieren oder deaktivieren.",
    CHATFILTER_LOGIN_MESSAGE                = "Login-Nachricht",
    CHATFILTER_LOGIN_MESSAGE_DESC           = "Beim Login eine Chat-Nachricht anzeigen, die den aktiven Filter bestaetigt.",
    CHATFILTER_ADD_KEYWORD                  = "Schluesselwort hinzufuegen",
    CHATFILTER_ADD_KEYWORD_DESC             = "Ein Wort oder eine Phrase zum Filtern eingeben. Gross-/Kleinschreibung wird nicht beachtet.",
    CHATFILTER_KEYWORDS_GROUP               = "Schluesselwoerter (%d)",
    CHATFILTER_NO_KEYWORDS                  = "Keine Schluesselwoerter konfiguriert.",
    CHATFILTER_REMOVE_KEYWORD_DESC          = "\"%s\" aus der Filterliste entfernen.",
    CHATFILTER_RESTORE_DEFAULTS             = "Standard-Schluesselwoerter wiederherstellen",
    CHATFILTER_RESTORE_DEFAULTS_DESC        = "Die Schluesselwortliste auf die integrierten Standards zuruecksetzen. Dadurch werden alle benutzerdefinierten Schluesselwoerter ersetzt.",
    CHATFILTER_RESTORE_CONFIRM              = "Wiederherstellen?",

    ---------------------------------------------------------------------------
    -- Phase 3: Tooltip WidgetOptions
    ---------------------------------------------------------------------------

    TOOLTIP_ENABLE_DESC                     = "Tooltips mit zusaetzlichen Informationen erweitern.",
    TOOLTIP_GROUP_PLAYER                    = "Spieler",
    TOOLTIP_MOUNT_NAME                      = "Reittier-Name",
    TOOLTIP_MOUNT_NAME_DESC                 = "Anzeigen, welches Reittier ein Spieler gerade reitet.",
    TOOLTIP_GROUP_ITEMS                     = "Gegenstaende",
    TOOLTIP_ITEM_ID                         = "Item ID",
    TOOLTIP_ITEM_ID_DESC                    = "Die Item ID in Gegenstands-Tooltips anzeigen.",
    TOOLTIP_ITEM_SPELL_ID                   = "Gegenstand Spell ID",
    TOOLTIP_ITEM_SPELL_ID_DESC              = "Die Nutzeffekt-Spell ID bei Verbrauchsguetern und anderen Gegenstaenden mit Nutzeffekten anzeigen.",
    TOOLTIP_GROUP_SPELLS                    = "Zauber",
    TOOLTIP_SPELL_ID                        = "Spell ID",
    TOOLTIP_SPELL_ID_DESC                   = "Die Spell ID in Zauber-, Aura- und Talent-Tooltips anzeigen.",
    TOOLTIP_NODE_ID                         = "Node ID",
    TOOLTIP_NODE_ID_DESC                    = "Die Talentbaum-Node ID in Talent-Tooltips anzeigen.",
    TOOLTIP_GROUP_COPY                      = "Kopieren",
    TOOLTIP_CTRL_C                          = "Ctrl+C zum Kopieren",
    TOOLTIP_CTRL_C_DESC                     = "Druecke Ctrl+C, um die primaere ID zu kopieren, oder Ctrl+Shift+C fuer die sekundaere ID (z.B. die Nutzeffekt-SpellID eines Gegenstands).",
    TOOLTIP_COMBAT_NOTE                     = "Tooltip-Erweiterungen sind in Instanzen deaktiviert. Reittier-Erkennung und Ctrl+C-Kopieren sind im Kampf deaktiviert.",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoPlaystyle WidgetOptions
    ---------------------------------------------------------------------------

    AUTOPLAYSTYLE_ENABLE_DESC               = "Spielstil beim Erstellen von M+ Gruppen automatisch auswaehlen.",
    AUTOPLAYSTYLE_PLAYSTYLE                 = "Spielstil",
    AUTOPLAYSTYLE_PLAYSTYLE_DESC            = "Waehlt diesen Spielstil automatisch aus, wenn der Gruppensuche-Erstellungsdialog fuer M+ Dungeons geoeffnet wird.",

    ---------------------------------------------------------------------------
    -- Shared: Font outline values (used across multiple modules)
    ---------------------------------------------------------------------------

    FONT_OUTLINE_NONE                       = "Keiner",
    FONT_OUTLINE_OUTLINE                    = "Umriss",
    FONT_OUTLINE_THICK                      = "Dicker Umriss",
    FONT_OUTLINE_MONO                       = "Monochrom",
    FONT_OUTLINE_OUTLINE_MONO              = "Umriss + Mono",

    ---------------------------------------------------------------------------
    -- Shared: Animation values (used across MissingPet, RangeCheck)
    ---------------------------------------------------------------------------

    ANIMATION_NONE                          = "Keine (statisch)",
    ANIMATION_BOUNCE                        = "Huepfen",
    ANIMATION_PULSE                         = "Pulsieren",
    ANIMATION_FADE                          = "Verblassen",
    ANIMATION_SHAKE                         = "Schuetteln",
    ANIMATION_GLOW                          = "Leuchten",
    ANIMATION_HEARTBEAT                     = "Herzschlag",

    ---------------------------------------------------------------------------
    -- Shared: Confirm/Remove labels
    ---------------------------------------------------------------------------

    SHARED_REMOVE                           = "Entfernen",
    SHARED_REMOVE_CONFIRM                   = "Entfernen?",

    ---------------------------------------------------------------------------
    -- Tooltip: in-game tooltip hint lines
    ---------------------------------------------------------------------------

    TOOLTIP_HINT_COPY                       = "Ctrl+C zum Kopieren",
    TOOLTIP_HINT_COPY_BOTH                  = "Ctrl+C ItemID  |  Ctrl+Shift+C SpellID",
    TOOLTIP_COPY_HINT                       = "Ctrl+C zum Kopieren, Esc zum Schliessen",
});
