local ADDON_NAME, Lantern = ...;
Lantern:RegisterLocale("itIT", {

    -- Shared
    ENABLE                                  = "Attiva",
    SHARED_FONT                             = "Carattere",
    SHARED_FONT_SIZE                        = "Dimensione carattere",
    SHARED_FONT_OUTLINE                     = "Contorno carattere",
    SHARED_FONT_COLOR                       = "Colore carattere",
    SHARED_GROUP_POSITION                   = "Posizione",
    SHARED_LOCK_POSITION                    = "Blocca posizione",
    SHARED_RESET_POSITION                   = "Ripristina posizione",
    SHARED_GROUP_SOUND                      = "Suono",
    SHARED_SOUND_SELECT                     = "Suono",
    SHARED_PLAY_SOUND                       = "Riproduci suono",
    SHARED_PREVIEW                          = "Anteprima",
    SHARED_GROUP_DISPLAY                    = "Visualizzazione",
    SHARED_ANIMATION_STYLE                  = "Stile animazione",

    -- General settings
    GENERAL_MINIMAP_SHOW                    = "Mostra icona minimappa",
    GENERAL_MINIMAP_SHOW_DESC               = "Mostra o nascondi il pulsante di Lantern sulla minimappa.",
    GENERAL_MINIMAP_MODERN                  = "Icona minimappa moderna",
    GENERAL_MINIMAP_MODERN_DESC             = "Rimuove il bordo e lo sfondo dal pulsante della minimappa per un aspetto moderno con un bagliore di lanterna al passaggio del mouse.",
    GENERAL_PAUSE_MODIFIER                  = "Tasto modificatore pausa",
    GENERAL_PAUSE_MODIFIER_DESC             = "Tieni premuto questo tasto per mettere in pausa temporaneamente le funzioni automatiche (Auto Quest, Auto Queue, Auto Repair, ecc.).",

    -- Modifier values (used in dropdowns)
    MODIFIER_SHIFT                          = "Shift",
    MODIFIER_CTRL                           = "Ctrl",
    MODIFIER_ALT                            = "Alt",

    -- Delete Confirm
    DELETECONFIRM_ENABLE_DESC               = "Sostituisce la digitazione di DELETE con un pulsante di conferma (Shift per mettere in pausa).",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_ENABLE_DESC              = "Impedisce l'aggiunta automatica degli incantesimi alla barra delle azioni.",

    -- Auto Queue
    AUTOQUEUE_ENABLE_DESC                   = "Attiva o disattiva Auto Queue.",
    AUTOQUEUE_AUTO_ACCEPT                   = "Accetta automaticamente i controlli ruolo",
    AUTOQUEUE_AUTO_ACCEPT_DESC              = "Accetta automaticamente i controlli ruolo LFG.",
    AUTOQUEUE_ANNOUNCE                      = "Annuncio in chat",
    AUTOQUEUE_ANNOUNCE_DESC                 = "Invia un messaggio in chat quando un controllo ruolo viene accettato automaticamente.",
    AUTOQUEUE_CALLOUT                       = "Tieni premuto %s per mettere in pausa temporaneamente. I ruoli sono impostati nello strumento LFG.",

    -- Faster Loot
    FASTERLOOT_ENABLE_DESC                  = "Raccoglie istantaneamente tutto il bottino quando si apre la finestra del loot. Tieni premuto %s per mettere in pausa.",

    -- Auto Keystone
    AUTOKEYSTONE_ENABLE_DESC                = "Inserisce automaticamente la tua chiave del potere quando apri l'interfaccia M+. Tieni premuto %s per saltare.",

    -- Release Protection
    RELEASEPROTECT_ENABLE_DESC              = "Richiede di tenere premuto %s per liberare lo spirito (previene rilasci accidentali).",
    RELEASEPROTECT_SKIP_SOLO                = "Ignora quando da solo",
    RELEASEPROTECT_SKIP_SOLO_DESC           = "Disattiva la protezione quando non sei in un gruppo.",
    RELEASEPROTECT_ACTIVE_IN                = "Attivo in",
    RELEASEPROTECT_ACTIVE_IN_DESC           = "Sempre: protezione ovunque. Tutte le istanze: solo dentro spedizioni, incursioni e PvP. Personalizzato: scegli tipi di istanza specifici.",
    RELEASEPROTECT_MODE_ALWAYS              = "Sempre",
    RELEASEPROTECT_MODE_INSTANCES           = "Tutte le istanze",
    RELEASEPROTECT_MODE_CUSTOM              = "Personalizzato",
    RELEASEPROTECT_HOLD_DURATION            = "Durata pressione",
    RELEASEPROTECT_HOLD_DURATION_DESC       = "Per quanto tempo devi tenere premuto il tasto modificatore prima che il pulsante di rilascio diventi attivo.",
    RELEASEPROTECT_INSTANCE_TYPES           = "Tipi di istanza",
    RELEASEPROTECT_OPEN_WORLD               = "Mondo aperto",
    RELEASEPROTECT_OPEN_WORLD_DESC          = "Protegge nel mondo aperto (non dentro alcuna istanza).",
    RELEASEPROTECT_DUNGEONS                 = "Spedizioni",
    RELEASEPROTECT_DUNGEONS_DESC            = "Protegge nelle spedizioni normali, eroiche e mitiche.",
    RELEASEPROTECT_MYTHICPLUS               = "Mythic+",
    RELEASEPROTECT_MYTHICPLUS_DESC          = "Protegge nelle chiavi del potere Mythic+.",
    RELEASEPROTECT_RAIDS                    = "Incursioni",
    RELEASEPROTECT_RAIDS_DESC               = "Protegge in tutte le difficolta delle incursioni (LFR, Normale, Eroica, Mitica).",
    RELEASEPROTECT_SCENARIOS                = "Scenari",
    RELEASEPROTECT_SCENARIOS_DESC           = "Protegge nelle istanze scenario.",
    RELEASEPROTECT_DELVES                   = "Profondita",
    RELEASEPROTECT_DELVES_DESC              = "Protegge nelle Profondita.",
    RELEASEPROTECT_ARENAS                   = "Arene",
    RELEASEPROTECT_ARENAS_DESC              = "Protegge nelle arene PvP.",
    RELEASEPROTECT_BATTLEGROUNDS            = "Campi di battaglia",
    RELEASEPROTECT_BATTLEGROUNDS_DESC       = "Protegge nei campi di battaglia PvP.",

    -- Auto Repair
    AUTOREPAIR_ENABLE_DESC                  = "Attiva o disattiva Auto Repair.",
    AUTOREPAIR_SOURCE                       = "Fonte riparazione",
    AUTOREPAIR_SOURCE_DESC                  = "Oro personale: usa sempre il tuo oro. Prima fondi gilda: prova la banca di gilda, poi ripieghi sull'oro personale. Solo fondi gilda: usa solo la banca di gilda (avvisa se non disponibile).",
    AUTOREPAIR_SOURCE_PERSONAL              = "Oro personale",
    AUTOREPAIR_SOURCE_GUILD_FIRST           = "Prima fondi gilda",
    AUTOREPAIR_SOURCE_GUILD_ONLY            = "Solo fondi gilda",
    AUTOREPAIR_CALLOUT                      = "Tieni premuto %s quando apri un mercante per saltare la riparazione automatica.",

    -- Splash page
    SPLASH_DESC                             = "Un addon modulare per migliorare la qualita della vita in World of Warcraft.\nClicca sul nome di un modulo per configurarlo, oppure clicca sul pallino di stato per attivarlo o disattivarlo.",
    SPLASH_ENABLED                          = "Attivato",
    SPLASH_DISABLED                         = "Disattivato",
    SPLASH_CLICK_ENABLE                     = "Clicca per attivare",
    SPLASH_CLICK_DISABLE                    = "Clicca per disattivare",
    SPLASH_COMPANION_HEADER                 = "Addon complementari",
    SPLASH_CURSEFORGE                       = "CurseForge",
    SPLASH_COPY_LINK                        = "Copia link",
    SPLASH_COPY_HINT                        = "Ctrl+C per copiare, Esc per chiudere",
    COPY                                    = "Copia",
    SELECT                                  = "Seleziona",

    -- Companion addon descriptions
    COMPANION_CO_LABEL                      = "Crafting Orders",
    COMPANION_CO_DESC                       = "Annuncia l'attivita degli ordini di gilda, avvisi sugli ordini personali e un pulsante Completa + Sussurra.",
    COMPANION_WARBAND_LABEL                 = "Warband",
    COMPANION_WARBAND_DESC                  = "Organizza i personaggi in gruppi con bilanciamento automatico dell'oro da/verso la banca della squadra all'apertura della banca.",

    -- Section headers
    SECTION_MODULES                         = "Moduli",
    SECTION_ADDONS                          = "Addon",

    -- General settings page
    SECTION_GENERAL                         = "Generale",
    SECTION_GENERAL_DESC                    = "Impostazioni principali dell'addon.",

    -- Sidebar page labels
    PAGE_HOME                               = "Home",

    -- Category headers
    CATEGORY_GENERAL                        = "Generale",
    CATEGORY_DUNGEONS                       = "Spedizioni & M+",
    CATEGORY_QUESTING                       = "Missioni & Mondo",

    -- Messages (Options.lua / ui.lua)
    MSG_OPTIONS_AFTER_COMBAT                = "Le opzioni si apriranno al termine del combattimento.",

    -- ui.lua: Minimap tooltip
    UI_MINIMAP_TITLE                        = "Lantern",
    UI_MINIMAP_LEFT_CLICK                   = "Clic sinistro: Apri opzioni",
    UI_MINIMAP_SHIFT_CLICK                  = "Shift+Clic sinistro: Ricarica interfaccia",

    -- ui.lua: StaticPopup link dialog
    UI_COPY_LINK_PROMPT                     = "Ctrl+C per copiare il link",

    -- ui.lua: Blizzard Settings stub
    UI_SETTINGS_VERSION                     = "Versione: %s",
    UI_SETTINGS_AUTHOR                      = "Autore: Dede in-game / Sponsorn su curseforge & github",
    UI_SETTINGS_THANKS                      = "Un ringraziamento speciale ai copyrighters per avermi fatto dare una mossa.",
    UI_SETTINGS_OPEN                        = "Apri impostazioni",
    UI_SETTINGS_AVAILABLE_MODULES           = "Moduli disponibili",
    UI_SETTINGS_CO_DESC                     = "Crafting Orders: annuncia l'attivita degli ordini di gilda, avvisi sugli ordini personali e un pulsante Completa + Sussurra.",
    UI_SETTINGS_ALREADY_ENABLED             = "Gia attivato",
    UI_SETTINGS_WARBAND_DESC                = "Warband: organizza i personaggi in gruppi con bilanciamento automatico dell'oro da/verso la banca della squadra all'apertura della banca.",

    -- core.lua: Slash command
    MSG_MISSINGPET_NOT_FOUND                = "Modulo MissingPet non trovato.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Metadata (title/desc)
    ---------------------------------------------------------------------------

    -- Auto Quest
    AUTOQUEST_TITLE                         = "Auto Quest",
    AUTOQUEST_DESC                          = "Accetta e consegna automaticamente le missioni.",

    -- Auto Queue
    AUTOQUEUE_TITLE                         = "Auto Queue",
    AUTOQUEUE_DESC                          = "Accetta automaticamente i controlli ruolo usando la tua selezione ruolo LFG.",

    -- Auto Repair
    AUTOREPAIR_TITLE                        = "Auto Repair",
    AUTOREPAIR_DESC                         = "Ripara automaticamente l'equipaggiamento dai mercanti.",

    -- Auto Sell
    AUTOSELL_TITLE                          = "Auto Sell",
    AUTOSELL_DESC                           = "Vende automaticamente oggetti spazzatura e oggetti personalizzati dai mercanti.",

    -- Chat Filter
    CHATFILTER_TITLE                        = "Chat Filter",
    CHATFILTER_DESC                         = "Filtra spam di oro, pubblicita di boost e messaggi indesiderati da sussurri e canali pubblici.",

    -- Cursor Ring
    CURSORRING_TITLE                        = "Cursor Ring & Trail",
    CURSORRING_DESC                         = "Visualizza anello/i personalizzabili attorno al cursore del mouse con indicatori di lancio/GCD e una scia opzionale.",

    -- Delete Confirm
    DELETECONFIRM_TITLE                     = "Delete Confirm",
    DELETECONFIRM_DESC                      = "Nasconde il campo di eliminazione e attiva il pulsante di conferma.",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_TITLE                    = "Disable Auto Add Spells",
    DISABLEAUTOADD_DESC                     = "Impedisce agli incantesimi di aggiungersi automaticamente alle barre delle azioni.",

    -- Missing Pet
    MISSINGPET_TITLE                        = "Missing Pet",
    MISSINGPET_DESC                         = "Mostra un avviso quando il tuo famiglio e assente o impostato su passivo.",

    -- Auto Playstyle
    AUTOPLAYSTYLE_TITLE                     = "Auto Playstyle",
    AUTOPLAYSTYLE_DESC                      = "Seleziona automaticamente lo stile di gioco preferito quando crei gruppi M+ nel Cerca Gruppo.",

    -- Faster Loot
    FASTERLOOT_TITLE                        = "Faster Loot",
    FASTERLOOT_DESC                         = "Raccoglie istantaneamente tutto il bottino quando si apre la finestra del loot.",

    -- Auto Keystone
    AUTOKEYSTONE_TITLE                      = "Auto Keystone",
    AUTOKEYSTONE_DESC                       = "Inserisce automaticamente la tua chiave del potere Mythic+ quando si apre l'interfaccia Sfida.",

    -- Release Protection
    RELEASEPROTECT_TITLE                    = "Release Protection",
    RELEASEPROTECT_DESC                     = "Richiede di tenere premuto il tasto modificatore pausa prima di liberare lo spirito per prevenire clic accidentali.",

    -- Combat Timer
    COMBATTIMER_TITLE                       = "Combat Timer",
    COMBATTIMER_DESC                        = "Mostra un timer che indica da quanto tempo sei in combattimento.",

    -- Combat Alert
    COMBATALERT_TITLE                       = "Combat Alert",
    COMBATALERT_DESC                        = "Mostra un avviso testuale con dissolvenza quando entri o esci dal combattimento.",

    -- Range Check
    RANGECHECK_TITLE                        = "Range Check",
    RANGECHECK_DESC                         = "Mostra lo stato di portata o fuori portata per il tuo bersaglio attuale.",

    -- Tooltip
    TOOLTIP_TITLE                           = "Tooltip",
    TOOLTIP_DESC                            = "Migliora i tooltip con ID e nomi delle cavalcature.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Print Messages
    ---------------------------------------------------------------------------

    -- Auto Queue messages
    AUTOQUEUE_MSG_ACCEPTED                  = "Controllo ruolo accettato automaticamente.",

    -- Auto Repair messages
    AUTOREPAIR_MSG_GUILD_UNAVAILABLE        = "Impossibile riparare: fondi gilda non disponibili.",
    AUTOREPAIR_MSG_REPAIRED_GUILD           = "Riparato per %s (fondi gilda).",
    AUTOREPAIR_MSG_REPAIRED                 = "Riparato per %s.",
    AUTOREPAIR_MSG_NOT_ENOUGH_GOLD          = "Impossibile riparare: oro insufficiente (%s necessari).",

    -- Auto Sell messages
    AUTOSELL_MSG_SOLD_ITEMS                 = "Venduti %d oggetto/i per %s.",

    -- Faster Loot messages
    FASTERLOOT_MSG_INV_FULL                 = "Inventario pieno - alcuni oggetti non sono stati raccolti.",

    -- Chat Filter messages
    CHATFILTER_MSG_ACTIVE                   = "Chat Filter attivo con %d parole chiave.",
    CHATFILTER_MSG_KEYWORD_EXISTS           = "Parola chiave gia presente nella lista dei filtri.",
    CHATFILTER_MSG_KEYWORD_ADDED            = "Aggiunta \"%s\" al filtro chat.",

    -- Auto Sell item messages
    AUTOSELL_MSG_ALREADY_IN_LIST            = "Oggetto gia nella lista di vendita.",
    AUTOSELL_MSG_ADDED_TO_LIST              = "Aggiunto %s alla lista di vendita.",
    AUTOSELL_MSG_INVALID_ITEM_ID            = "Item ID non valido.",

    -- Tooltip messages
    TOOLTIP_MSG_ID_COPIED                   = "%s %s copiato.",

    -- Release Protection overlay text
    RELEASEPROTECT_HOLD_PROGRESS            = "Tieni premuto %s... %.1fs",
    RELEASEPROTECT_HOLD_PROMPT              = "Tieni premuto %s (%.1fs)",

    -- Auto Quest messages
    AUTOQUEST_MSG_NO_NPC                    = "Nessun NPC trovato. Parla prima con un NPC.",
    AUTOQUEST_MSG_BLOCKED_NPC               = "NPC bloccato: %s",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoQuest WidgetOptions
    ---------------------------------------------------------------------------

    AUTOQUEST_ENABLE_DESC                   = "Attiva o disattiva Auto Quest.",
    AUTOQUEST_AUTO_ACCEPT                   = "Accetta missioni automaticamente",
    AUTOQUEST_AUTO_ACCEPT_DESC              = "Accetta automaticamente le missioni dagli NPC.",
    AUTOQUEST_AUTO_TURNIN                   = "Consegna missioni automaticamente",
    AUTOQUEST_AUTO_TURNIN_DESC              = "Consegna automaticamente le missioni completate agli NPC.",
    AUTOQUEST_SINGLE_REWARD                 = "Seleziona automaticamente ricompensa singola",
    AUTOQUEST_SINGLE_REWARD_DESC            = "Se una missione offre una sola ricompensa, la seleziona automaticamente.",
    AUTOQUEST_SINGLE_GOSSIP                 = "Seleziona automaticamente opzione dialogo singola",
    AUTOQUEST_SINGLE_GOSSIP_DESC            = "Seleziona automaticamente gli NPC con una sola opzione di dialogo per proseguire nelle catene di dialogo che portano a missioni.",
    AUTOQUEST_SKIP_TRIVIAL                  = "Ignora missioni banali",
    AUTOQUEST_SKIP_TRIVIAL_DESC             = "Non accettare automaticamente missioni grigie (banali/di basso livello).",
    AUTOQUEST_CALLOUT                       = "Tieni premuto %s per mettere in pausa temporaneamente l'accettazione e la consegna automatiche.",
    AUTOQUEST_ADDON_BYPASS_NOTE             = "Nota: altri addon di automazione missioni (QuickQuest, Plumber, ecc.) potrebbero ignorare la lista di blocco.",
    AUTOQUEST_ADD_NPC                       = "Aggiungi NPC attuale alla lista di blocco",
    AUTOQUEST_ADD_NPC_DESC                  = "Parla con un NPC, poi clicca questo pulsante per bloccarlo dall'automazione delle missioni.",
    AUTOQUEST_ZONE_FILTER                   = "Filtro zona",
    AUTOQUEST_NPC_ZONE_FILTER_DESC          = "Filtra gli NPC bloccati per zona.",
    AUTOQUEST_QUEST_ZONE_FILTER_DESC        = "Filtra le missioni bloccate per zona.",
    AUTOQUEST_ZONE_ALL                      = "Tutte le zone",
    AUTOQUEST_ZONE_CURRENT                  = "Zona attuale",
    AUTOQUEST_BLOCKED_NPCS                  = "NPC bloccati (%d)",
    AUTOQUEST_NPC_EMPTY_ALL                 = "Nessun NPC bloccato -- seleziona un NPC e clicca il pulsante qui sopra per aggiungerne uno.",
    AUTOQUEST_NPC_EMPTY_ZONE                = "Nessun NPC bloccato in %s.",
    AUTOQUEST_REMOVE_NPC_DESC               = "Rimuovi %s dalla lista di blocco.",
    AUTOQUEST_BLOCKED_QUESTS_HEADER         = "Missioni bloccate",
    AUTOQUEST_BLOCKED_QUESTS_NOTE           = "Le missioni bloccate non saranno accettate o consegnate automaticamente.",
    AUTOQUEST_QUEST_EMPTY_ALL               = "Nessuna missione bloccata -- le missioni accettate automaticamente da NPC bloccati appariranno qui.",
    AUTOQUEST_QUEST_EMPTY_ZONE              = "Nessuna missione bloccata in %s.",
    AUTOQUEST_UNKNOWN_NPC                   = "NPC sconosciuto",
    AUTOQUEST_QUEST_LABEL_WITH_ID           = "%s (ID: %s)",
    AUTOQUEST_QUEST_LABEL_ID_ONLY           = "Quest ID: %s",
    AUTOQUEST_UNBLOCK_DESC                  = "Sblocca questa missione.",
    AUTOQUEST_BLOCK_QUEST                   = "Blocca missione",
    AUTOQUEST_BLOCKED                       = "Bloccata",
    AUTOQUEST_BLOCK_DESC                    = "Blocca questa missione dall'automazione futura.",
    AUTOQUEST_NPC_PREFIX                    = "NPC: %s",
    AUTOQUEST_NO_AUTOMATED                  = "Nessuna missione automatizzata finora.",
    AUTOQUEST_RECENT_AUTOMATED              = "Missioni automatizzate recenti (%d)",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoSell WidgetOptions
    ---------------------------------------------------------------------------

    AUTOSELL_ENABLE_DESC                    = "Attiva o disattiva Auto Sell.",
    AUTOSELL_SELL_GRAYS                     = "Vendi oggetti grigi",
    AUTOSELL_SELL_GRAYS_DESC                = "Vende automaticamente tutti gli oggetti di qualita scadente (grigi).",
    AUTOSELL_CALLOUT                        = "Tieni premuto %s quando apri un mercante per saltare la vendita automatica.",
    AUTOSELL_DRAG_DROP                      = "Trascina e rilascia:",
    AUTOSELL_DRAG_GLOBAL_DESC               = "Trascina un oggetto dalle borse e rilascialo qui per aggiungerlo alla lista di vendita globale.",
    AUTOSELL_DRAG_CHAR_DESC                 = "Trascina un oggetto dalle borse e rilascialo qui per aggiungerlo alla lista di vendita di questo personaggio.",
    AUTOSELL_ITEM_ID                        = "Item ID",
    AUTOSELL_ITEM_ID_GLOBAL_DESC            = "Inserisci un Item ID per aggiungerlo alla lista di vendita globale.",
    AUTOSELL_ITEM_ID_CHAR_DESC              = "Inserisci un Item ID per aggiungerlo alla lista di vendita di questo personaggio.",
    AUTOSELL_REMOVE_DESC                    = "Rimuovi questo oggetto dalla lista di vendita.",
    AUTOSELL_GLOBAL_LIST                    = "Lista vendita globale (%d)",
    AUTOSELL_CHAR_LIST                      = "Lista vendita %s (%d)",
    AUTOSELL_CHAR_ONLY_NOTE                 = "Gli oggetti in questa lista vengono venduti solo su questo personaggio.",
    AUTOSELL_EMPTY_GLOBAL                   = "Nessun oggetto nella lista di vendita globale.",
    AUTOSELL_EMPTY_CHAR                     = "Nessun oggetto nella lista di vendita del personaggio.",

    ---------------------------------------------------------------------------
    -- Phase 3: CursorRing WidgetOptions
    ---------------------------------------------------------------------------

    CURSORRING_ENABLE_DESC                  = "Attiva o disattiva il modulo Cursor Ring & Trail.",
    CURSORRING_PREVIEW_START                = "Avvia anteprima",
    CURSORRING_PREVIEW_STOP                 = "Ferma anteprima",
    CURSORRING_PREVIEW_DESC                 = "Mostra tutti gli elementi visivi sul cursore per la modifica in tempo reale. Si disattiva automaticamente alla chiusura del pannello impostazioni.",
    CURSORRING_GROUP_GENERAL                = "Generale",
    CURSORRING_SHOW_OOC                     = "Mostra fuori dal combattimento",
    CURSORRING_SHOW_OOC_DESC                = "Mostra l'anello del cursore fuori dal combattimento e dalle istanze.",
    CURSORRING_COMBAT_OPACITY               = "Opacita in combattimento",
    CURSORRING_COMBAT_OPACITY_DESC          = "Opacita dell'anello durante il combattimento o in contenuti instanziati.",
    CURSORRING_OOC_OPACITY                  = "Opacita fuori dal combattimento",
    CURSORRING_OOC_OPACITY_DESC             = "Opacita dell'anello fuori dal combattimento.",
    CURSORRING_GROUP_RING1                  = "Anello 1 (esterno)",
    CURSORRING_ENABLE_RING1                 = "Attiva anello 1",
    CURSORRING_ENABLE_RING1_DESC            = "Mostra l'anello esterno.",
    CURSORRING_SHAPE                        = "Forma",
    CURSORRING_RING_SHAPE_DESC              = "Forma dell'anello.",
    CURSORRING_SHwPE_CIRCLE                 = "Cerchio",
    CURSORRING_SHAPE_THIN                   = "Cerchio sottile",
    CURSORRING_COLOR                        = "Colore",
    CURSORRING_RING1_COLOR_DESC             = "Colore anello 1.",
    CURSORRING_SIZE                         = "Dimensione",
    CURSORRING_RING1_SIZE_DESC              = "Dimensione anello 1 in pixel.",
    CURSORRING_GROUP_RING2                  = "Anello 2 (interno)",
    CURSORRING_ENABLE_RING2                 = "Attiva anello 2",
    CURSORRING_ENABLE_RING2_DESC            = "Mostra l'anello interno.",
    CURSORRING_RING2_COLOR_DESC             = "Colore anello 2.",
    CURSORRING_RING2_SIZE_DESC              = "Dimensione anello 2 in pixel.",
    CURSORRING_GROUP_DOT                    = "Punto centrale",
    CURSORRING_ENABLE_DOT                   = "Attiva punto",
    CURSORRING_ENABLE_DOT_DESC              = "Mostra un piccolo punto al centro degli anelli del cursore.",
    CURSORRING_DOT_COLOR_DESC               = "Colore del punto.",
    CURSORRING_DOT_SIZE_DESC                = "Dimensione del punto in pixel.",
    CURSORRING_GROUP_CAST                   = "Effetto lancio",
    CURSORRING_ENABLE_CAST                  = "Attiva effetto lancio",
    CURSORRING_ENABLE_CAST_DESC             = "Mostra un effetto visivo durante il lancio e la canalizzazione degli incantesimi.",
    CURSORRING_STYLE                        = "Stile",
    CURSORRING_CAST_STYLE_DESC              = "Segmenti: l'arco si illumina progressivamente. Riempimento: la forma si espande dal centro. Rotazione: animazione di ricarica (puo funzionare insieme al GCD).",
    CURSORRING_STYLE_SEGMENTS               = "Segmenti",
    CURSORRING_STYLE_FILL                   = "Riempimento",
    CURSORRING_STYLE_SWIPE                  = "Rotazione",
    CURSORRING_CAST_COLOR_DESC              = "Colore dell'effetto lancio.",
    CURSORRING_SWIPE_OFFSET                 = "Offset rotazione",
    CURSORRING_SWIPE_OFFSET_DESC            = "Offset in pixel per l'anello di rotazione del lancio fuori dall'anello GCD. Si applica solo allo stile Rotazione.",
    CURSORRING_GROUP_GCD                    = "Indicatore GCD",
    CURSORRING_ENABLE_GCD                   = "Attiva GCD",
    CURSORRING_ENABLE_GCD_DESC              = "Mostra un'animazione di ricarica per il cooldown globale.",
    CURSORRING_GCD_COLOR_DESC               = "Colore dell'animazione GCD.",
    CURSORRING_OFFSET                       = "Offset",
    CURSORRING_GCD_OFFSET_DESC              = "Offset in pixel per l'anello GCD fuori dall'anello 1.",
    CURSORRING_GROUP_TRAIL                  = "Scia del mouse",
    CURSORRING_ENABLE_TRAIL                 = "Attiva scia",
    CURSORRING_ENABLE_TRAIL_DESC            = "Mostra una scia che sfuma dietro il cursore.",
    CURSORRING_TRAIL_STYLE_DESC             = "Stile della scia. Bagliore: scia scintillante che sfuma. Linea: nastro sottile continuo. Linea spessa: nastro largo. Punti: punti distanziati che sfumano. Personalizzato: impostazioni manuali.",
    CURSORRING_TRAIL_GLOW                   = "Bagliore",
    CURSORRING_TRAIL_LINE                   = "Linea",
    CURSORRING_TRAIL_THICKLINE              = "Linea spessa",
    CURSORRING_TRAIL_DOTS                   = "Punti",
    CURSORRING_TRAIL_CUSTOM                 = "Personalizzato",
    CURSORRING_TRAIL_COLOR_DESC             = "Preset colore scia. Colore classe usa automaticamente il colore della tua classe. Arcobaleno, Brace e Oceano sono gradienti multicolore. Personalizzato ti permette di scegliere un colore qui sotto.",
    CURSORRING_TRAIL_COLOR_CUSTOM           = "Personalizzato",
    CURSORRING_TRAIL_COLOR_CLASS            = "Colore classe",
    CURSORRING_TRAIL_COLOR_GOLD             = "Lantern Gold",
    CURSORRING_TRAIL_COLOR_ARCANE           = "Arcano",
    CURSORRING_TRAIL_COLOR_FEL              = "Vil",
    CURSORRING_TRAIL_COLOR_FIRE             = "Fuoco",
    CURSORRING_TRAIL_COLOR_FROST            = "Gelo",
    CURSORRING_TRAIL_COLOR_HOLY             = "Sacro",
    CURSORRING_TRAIL_COLOR_SHADOW           = "Ombra",
    CURSORRING_TRAIL_COLOR_RAINBOW          = "Arcobaleno",
    CURSORRING_TRAIL_COLOR_ALAR             = "Al'ar",
    CURSORRING_TRAIL_COLOR_EMBER            = "Brace",
    CURSORRING_TRAIL_COLOR_OCEAN            = "Oceano",
    CURSORRING_CUSTOM_COLOR                 = "Colore personalizzato",
    CURSORRING_CUSTOM_COLOR_DESC            = "Colore della scia (usato solo quando il colore e impostato su Personalizzato).",
    CURSORRING_DURATION                     = "Durata",
    CURSORRING_DURATION_DESC                = "Durata dei punti della scia prima di svanire.",
    CURSORRING_MAX_POINTS                   = "Punti massimi",
    CURSORRING_MAX_POINTS_DESC              = "Numero di punti della scia nel pool. Valori piu alti creano scie piu lunghe ma usano piu memoria.",
    CURSORRING_DOT_SIZE                     = "Dimensione punto",
    CURSORRING_DOT_SIZE_TRAIL_DESC          = "Dimensione di ogni punto della scia in pixel.",
    CURSORRING_DOT_SPACING                  = "Spaziatura punti",
    CURSORRING_DOT_SPACING_DESC             = "Distanza minima in pixel prima di posizionare un nuovo punto. Valori piu bassi creano una scia piu densa e continua.",
    CURSORRING_SHRINK_AGE                   = "Rimpicciolisci con il tempo",
    CURSORRING_SHRINK_AGE_DESC              = "I punti della scia si rimpiccioliscono mentre sfumano. Disattiva per una scia a larghezza uniforme.",
    CURSORRING_TAPER_DISTANCE               = "Affusola con la distanza",
    CURSORRING_TAPER_DISTANCE_DESC          = "I punti della scia si rimpiccioliscono e sfumano verso la coda, creando un effetto pennellata affusolata.",
    CURSORRING_SPARKLE                      = "Scintillio",
    CURSORRING_SPARKLE_DESC                 = "Aggiunge piccole particelle luccicanti lungo la scia mentre muovi il cursore.",
    CURSORRING_SPARKLE_OFF                  = "Disattivato",
    CURSORRING_SPARKLE_STATIC               = "Statico",
    CURSORRING_SPARKLE_TWINKLE              = "Intermittente",
    CURSORRING_TRAIL_PERF_NOTE              = "La scia si aggiorna ad ogni fotogramma. Piu punti, scintillii ed effetti useranno piu CPU.",

    ---------------------------------------------------------------------------
    -- Phase 3: MissingPet WidgetOptions
    ---------------------------------------------------------------------------

    MISSINGPET_ENABLE_DESC                  = "Attiva o disattiva l'avviso Missing Pet.",
    MISSINGPET_GROUP_WARNING                = "Impostazioni avviso",
    MISSINGPET_SHOW_MISSING                 = "Mostra avviso assenza",
    MISSINGPET_SHOW_MISSING_DESC            = "Mostra un avviso quando il tuo famiglio e congedato o morto.",
    MISSINGPET_SHOW_PASSIVE                 = "Mostra avviso passivo",
    MISSINGPET_SHOW_PASSIVE_DESC            = "Mostra un avviso quando il tuo famiglio e impostato su passivo.",
    MISSINGPET_MISSING_TEXT                 = "Testo assenza",
    MISSINGPET_MISSING_TEXT_DESC            = "Testo da mostrare quando il famiglio e assente.",
    MISSINGPET_PASSIVE_TEXT                 = "Testo passivo",
    MISSINGPET_PASSIVE_TEXT_DESC            = "Testo da mostrare quando il famiglio e impostato su passivo.",
    MISSINGPET_MISSING_COLOR                = "Colore assenza",
    MISSINGPET_MISSING_COLOR_DESC           = "Colore del testo di avviso famiglio assente.",
    MISSINGPET_PASSIVE_COLOR                = "Colore passivo",
    MISSINGPET_PASSIVE_COLOR_DESC           = "Colore del testo di avviso famiglio passivo.",
    MISSINGPET_ANIMATION_DESC               = "Scegli come si anima il testo di avviso.",
    MISSINGPET_GROUP_FONT                   = "Impostazioni carattere",
    MISSINGPET_FONT_DESC                    = "Seleziona il carattere per il testo di avviso.",
    MISSINGPET_FONT_SIZE_DESC               = "Dimensione del testo di avviso.",
    MISSINGPET_FONT_OUTLINE_DESC            = "Stile contorno per il testo di avviso.",
    MISSINGPET_LOCK_POSITION_DESC           = "Impedisce lo spostamento dell'avviso.",
    MISSINGPET_RESET_POSITION_DESC          = "Ripristina la posizione della finestra di avviso al centro dello schermo.",
    MISSINGPET_GROUP_VISIBILITY             = "Visibilita",
    MISSINGPET_HIDE_MOUNTED                 = "Nascondi in cavalcatura",
    MISSINGPET_HIDE_MOUNTED_DESC            = "Nascondi l'avviso mentre sei in cavalcatura, su un taxi o in un veicolo.",
    MISSINGPET_HIDE_REST                    = "Nascondi in zone di riposo",
    MISSINGPET_HIDE_REST_DESC               = "Nascondi l'avviso mentre sei in una zona di riposo (citta e locande).",
    MISSINGPET_DISMOUNT_DELAY               = "Ritardo smontaggio",
    MISSINGPET_DISMOUNT_DELAY_DESC          = "Secondi di attesa dopo lo smontaggio prima di mostrare l'avviso. Imposta a 0 per mostrarlo immediatamente.",
    MISSINGPET_PLAY_SOUND_DESC              = "Riproduci un suono quando l'avviso viene mostrato.",
    MISSINGPET_SOUND_MISSING                = "Suono per assenza",
    MISSINGPET_SOUND_MISSING_DESC           = "Riproduci un suono quando il famiglio e assente.",
    MISSINGPET_SOUND_PASSIVE                = "Suono per passivo",
    MISSINGPET_SOUND_PASSIVE_DESC           = "Riproduci un suono quando il famiglio e impostato su passivo.",
    MISSINGPET_SOUND_COMBAT                 = "Suono in combattimento",
    MISSINGPET_SOUND_COMBAT_DESC            = "Continua a riprodurre il suono durante il combattimento. Se disattivato, il suono si ferma quando inizia il combattimento.",
    MISSINGPET_SOUND_REPEAT                 = "Ripeti suono",
    MISSINGPET_SOUND_REPEAT_DESC            = "Ripete il suono a intervalli regolari mentre l'avviso e visualizzato.",
    MISSINGPET_SOUND_SELECT_DESC            = "Seleziona il suono da riprodurre. Clicca l'icona dell'altoparlante per un'anteprima.",
    MISSINGPET_REPEAT_INTERVAL              = "Intervallo di ripetizione",
    MISSINGPET_REPEAT_INTERVAL_DESC         = "Secondi tra le ripetizioni del suono.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatAlert WidgetOptions
    ---------------------------------------------------------------------------

    COMBATALERT_ENABLE_DESC                 = "Mostra avvisi testuali quando entri/esci dal combattimento.",
    COMBATALERT_PREVIEW_DESC                = "Riproduce in loop gli avvisi di entrata/uscita sullo schermo per la modifica in tempo reale. Si disattiva automaticamente alla chiusura del pannello impostazioni.",
    COMBATALERT_GROUP_ENTER                 = "Entrata in combattimento",
    COMBATALERT_SHOW_ENTER                  = "Mostra avviso entrata",
    COMBATALERT_SHOW_ENTER_DESC             = "Mostra un avviso quando entri in combattimento.",
    COMBATALERT_ENTER_TEXT                   = "Testo entrata",
    COMBATALERT_ENTER_TEXT_DESC             = "Testo mostrato quando entri in combattimento.",
    COMBATALERT_ENTER_COLOR                 = "Colore entrata",
    COMBATALERT_ENTER_COLOR_DESC            = "Colore del testo di entrata in combattimento.",
    COMBATALERT_GROUP_LEAVE                 = "Uscita dal combattimento",
    COMBATALERT_SHOW_LEAVE                  = "Mostra avviso uscita",
    COMBATALERT_SHOW_LEAVE_DESC             = "Mostra un avviso quando esci dal combattimento.",
    COMBATALERT_LEAVE_TEXT                   = "Testo uscita",
    COMBATALERT_LEAVE_TEXT_DESC             = "Testo mostrato quando esci dal combattimento.",
    COMBATALERT_LEAVE_COLOR                 = "Colore uscita",
    COMBATALERT_LEAVE_COLOR_DESC            = "Colore del testo di uscita dal combattimento.",
    COMBATALERT_GROUP_FONT                  = "Impostazioni carattere e visualizzazione",
    COMBATALERT_FONT_DESC                   = "Seleziona il carattere per il testo dell'avviso.",
    COMBATALERT_FONT_SIZE_DESC              = "Dimensione del testo dell'avviso.",
    COMBATALERT_FONT_OUTLINE_DESC           = "Stile contorno per il testo dell'avviso.",
    COMBATALERT_FADE_DURATION               = "Durata dissolvenza",
    COMBATALERT_FADE_DURATION_DESC          = "Durata totale dell'avviso (attesa + dissolvenza) in secondi.",
    COMBATALERT_PLAY_SOUND_DESC             = "Riproduci un suono quando l'avviso viene mostrato.",
    COMBATALERT_SOUND_SELECT_DESC           = "Seleziona il suono da riprodurre.",
    COMBATALERT_LOCK_POSITION_DESC          = "Impedisce lo spostamento dell'avviso.",
    COMBATALERT_RESET_POSITION_DESC         = "Ripristina la posizione predefinita dell'avviso.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatTimer WidgetOptions
    ---------------------------------------------------------------------------

    COMBATTIMER_ENABLE_DESC                 = "Mostra un timer durante il combattimento.",
    COMBATTIMER_PREVIEW_DESC                = "Mostra il timer sullo schermo per la modifica in tempo reale. Si disattiva automaticamente alla chiusura del pannello impostazioni.",
    COMBATTIMER_FONT_DESC                   = "Seleziona il carattere per il testo del timer.",
    COMBATTIMER_FONT_SIZE_DESC              = "Dimensione del testo del timer.",
    COMBATTIMER_FONT_OUTLINE_DESC           = "Stile contorno per il testo del timer.",
    COMBATTIMER_FONT_COLOR_DESC             = "Colore del testo del timer.",
    COMBATTIMER_STICKY_DURATION             = "Durata persistente",
    COMBATTIMER_STICKY_DURATION_DESC        = "Secondi per continuare a mostrare il tempo finale dopo la fine del combattimento. Imposta a 0 per nasconderlo immediatamente.",
    COMBATTIMER_LOCK_POSITION_DESC          = "Impedisce lo spostamento del timer.",
    COMBATTIMER_RESET_POSITION_DESC         = "Ripristina la posizione predefinita del timer.",

    ---------------------------------------------------------------------------
    -- Phase 3: RangeCheck WidgetOptions
    ---------------------------------------------------------------------------

    RANGECHECK_ENABLE_DESC                  = "Mostra lo stato di portata o fuori portata per il tuo bersaglio attuale.",
    RANGECHECK_HIDE_IN_RANGE                = "Nascondi se in portata",
    RANGECHECK_HIDE_IN_RANGE_DESC           = "Nascondi il display quando il bersaglio e in portata. Mostra solo quando e fuori portata.",
    RANGECHECK_COMBAT_ONLY                  = "Solo in combattimento",
    RANGECHECK_COMBAT_ONLY_DESC             = "Mostra la portata solo durante il combattimento.",
    RANGECHECK_GROUP_STATUS                 = "Testo di stato",
    RANGECHECK_IN_RANGE_TEXT                = "Testo in portata",
    RANGECHECK_IN_RANGE_TEXT_DESC           = "Testo da mostrare quando il bersaglio e in portata.",
    RANGECHECK_OUT_OF_RANGE_TEXT            = "Testo fuori portata",
    RANGECHECK_OUT_OF_RANGE_TEXT_DESC       = "Testo da mostrare quando il bersaglio e fuori portata.",
    RANGECHECK_IN_RANGE_COLOR               = "Colore in portata",
    RANGECHECK_IN_RANGE_COLOR_DESC          = "Colore per il testo in portata.",
    RANGECHECK_OUT_OF_RANGE_COLOR           = "Colore fuori portata",
    RANGECHECK_OUT_OF_RANGE_COLOR_DESC      = "Colore per il testo fuori portata.",
    RANGECHECK_ANIMATION_DESC               = "Scegli come si anima il testo di stato al cambio di stato.",
    RANGECHECK_FONT_DESC                    = "Seleziona il carattere per il testo della portata.",
    RANGECHECK_FONT_SIZE_DESC               = "Dimensione del testo della portata.",
    RANGECHECK_FONT_OUTLINE_DESC            = "Stile contorno per il testo della portata.",
    RANGECHECK_LOCK_POSITION_DESC           = "Impedisce lo spostamento del display della portata.",
    RANGECHECK_RESET_POSITION_DESC          = "Ripristina la posizione predefinita del display della portata.",

    ---------------------------------------------------------------------------
    -- Phase 3: ChatFilter WidgetOptions
    ---------------------------------------------------------------------------

    CHATFILTER_ENABLE_DESC                  = "Attiva o disattiva il Chat Filter.",
    CHATFILTER_LOGIN_MESSAGE                = "Messaggio di accesso",
    CHATFILTER_LOGIN_MESSAGE_DESC           = "Mostra un messaggio in chat all'accesso per confermare che il filtro e attivo.",
    CHATFILTER_ADD_KEYWORD                  = "Aggiungi parola chiave",
    CHATFILTER_ADD_KEYWORD_DESC             = "Inserisci una parola o una frase da filtrare. Il confronto non distingue maiuscole e minuscole.",
    CHATFILTER_KEYWORDS_GROUP               = "Parole chiave (%d)",
    CHATFILTER_NO_KEYWORDS                  = "Nessuna parola chiave configurata.",
    CHATFILTER_REMOVE_KEYWORD_DESC          = "Rimuovi \"%s\" dalla lista dei filtri.",
    CHATFILTER_RESTORE_DEFAULTS             = "Ripristina parole chiave predefinite",
    CHATFILTER_RESTORE_DEFAULTS_DESC        = "Ripristina la lista delle parole chiave ai valori predefiniti. Questo sostituisce tutte le parole chiave personalizzate.",
    CHATFILTER_RESTORE_CONFIRM              = "Ripristinare?",

    ---------------------------------------------------------------------------
    -- Phase 3: Tooltip WidgetOptions
    ---------------------------------------------------------------------------

    TOOLTIP_ENABLE_DESC                     = "Migliora i tooltip con informazioni aggiuntive.",
    TOOLTIP_GROUP_PLAYER                    = "Giocatore",
    TOOLTIP_MOUNT_NAME                      = "Nome cavalcatura",
    TOOLTIP_MOUNT_NAME_DESC                 = "Mostra quale cavalcatura sta usando un giocatore.",
    TOOLTIP_GROUP_ITEMS                     = "Oggetti",
    TOOLTIP_ITEM_ID                         = "Item ID",
    TOOLTIP_ITEM_ID_DESC                    = "Mostra l'Item ID nei tooltip degli oggetti.",
    TOOLTIP_ITEM_SPELL_ID                   = "Spell ID oggetto",
    TOOLTIP_ITEM_SPELL_ID_DESC              = "Mostra lo Spell ID dell'effetto d'uso su consumabili e altri oggetti con abilita d'uso.",
    TOOLTIP_GROUP_SPELLS                    = "Incantesimi",
    TOOLTIP_SPELL_ID                        = "Spell ID",
    TOOLTIP_SPELL_ID_DESC                   = "Mostra lo Spell ID nei tooltip di incantesimi, aure e talenti.",
    TOOLTIP_NODE_ID                         = "Node ID",
    TOOLTIP_NODE_ID_DESC                    = "Mostra il Node ID dell'albero dei talenti nei tooltip dei talenti.",
    TOOLTIP_GROUP_COPY                      = "Copia",
    TOOLTIP_CTRL_C                          = "Ctrl+C per copiare",
    TOOLTIP_CTRL_C_DESC                     = "Premi Ctrl+C per copiare l'ID principale, oppure Ctrl+Shift+C per copiare l'ID secondario (es. lo Spell ID dell'effetto d'uso di un oggetto).",
    TOOLTIP_COMBAT_NOTE                     = "I miglioramenti ai tooltip sono disattivati nelle istanze. La scansione delle cavalcature e la copia con Ctrl+C sono disattivati durante il combattimento.",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoPlaystyle WidgetOptions
    ---------------------------------------------------------------------------

    AUTOPLAYSTYLE_ENABLE_DESC               = "Seleziona automaticamente lo stile di gioco quando crei gruppi M+.",
    AUTOPLAYSTYLE_PLAYSTYLE                 = "Stile di gioco",
    AUTOPLAYSTYLE_PLAYSTYLE_DESC            = "Seleziona automaticamente questo stile di gioco quando apri la finestra di creazione gruppo nel Cerca Gruppo per le spedizioni M+.",

    ---------------------------------------------------------------------------
    -- Shared: Font outline values (used across multiple modules)
    ---------------------------------------------------------------------------

    FONT_OUTLINE_NONE                       = "Nessuno",
    FONT_OUTLINE_OUTLINE                    = "Contorno",
    FONT_OUTLINE_THICK                      = "Contorno spesso",
    FONT_OUTLINE_MONO                       = "Monocromatico",
    FONT_OUTLINE_OUTLINE_MONO              = "Contorno + Mono",

    ---------------------------------------------------------------------------
    -- Shared: Animation values (used across MissingPet, RangeCheck)
    ---------------------------------------------------------------------------

    ANIMATION_NONE                          = "Nessuna (statico)",
    ANIMATION_BOUNCE                        = "Rimbalzo",
    ANIMATION_PULSE                         = "Pulsazione",
    ANIMATION_FADE                          = "Dissolvenza",
    ANIMATION_SHAKE                         = "Vibrazione",
    ANIMATION_GLOW                          = "Bagliore",
    ANIMATION_HEARTBEAT                     = "Battito",

    ---------------------------------------------------------------------------
    -- Shared: Confirm/Remove labels
    ---------------------------------------------------------------------------

    SHARED_REMOVE                           = "Rimuovi",
    SHARED_REMOVE_CONFIRM                   = "Rimuovere?",

    ---------------------------------------------------------------------------
    -- Tooltip: in-game tooltip hint lines
    ---------------------------------------------------------------------------

    TOOLTIP_HINT_COPY                       = "Ctrl+C per copiare",
    TOOLTIP_HINT_COPY_BOTH                  = "Ctrl+C ItemID  |  Ctrl+Shift+C SpellID",
    TOOLTIP_COPY_HINT                       = "Ctrl+C per copiare, Esc per chiudere",
});
