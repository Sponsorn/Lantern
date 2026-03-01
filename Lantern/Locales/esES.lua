local ADDON_NAME, Lantern = ...;
Lantern:RegisterLocale("esES", {

    -- Shared
    ENABLE                                  = "Activar",
    SHARED_FONT                             = "Fuente",
    SHARED_FONT_SIZE                        = "Tamano de fuente",
    SHARED_FONT_OUTLINE                     = "Contorno de fuente",
    SHARED_FONT_COLOR                       = "Color de fuente",
    SHARED_GROUP_POSITION                   = "Posicion",
    SHARED_LOCK_POSITION                    = "Bloquear posicion",
    SHARED_RESET_POSITION                   = "Restablecer posicion",
    SHARED_GROUP_SOUND                      = "Sonido",
    SHARED_SOUND_SELECT                     = "Sonido",
    SHARED_PLAY_SOUND                       = "Reproducir sonido",
    SHARED_PREVIEW                          = "Vista previa",
    SHARED_GROUP_DISPLAY                    = "Visualizacion",
    SHARED_ANIMATION_STYLE                  = "Estilo de animacion",

    -- General settings
    GENERAL_MINIMAP_SHOW                    = "Mostrar icono en el minimapa",
    GENERAL_MINIMAP_SHOW_DESC               = "Mostrar u ocultar el boton de Lantern en el minimapa.",
    GENERAL_MINIMAP_MODERN                  = "Icono de minimapa moderno",
    GENERAL_MINIMAP_MODERN_DESC             = "Eliminar el borde y fondo del boton del minimapa para un aspecto moderno con un brillo de linterna al pasar el cursor.",
    GENERAL_PAUSE_MODIFIER                  = "Tecla modificadora de pausa",
    GENERAL_PAUSE_MODIFIER_DESC             = "Manten esta tecla para pausar temporalmente las funciones automaticas (Auto Quest, Auto Queue, Auto Repair, etc.).",

    -- Modifier values (used in dropdowns)
    MODIFIER_SHIFT                          = "Shift",
    MODIFIER_CTRL                           = "Ctrl",
    MODIFIER_ALT                            = "Alt",

    -- Delete Confirm
    DELETECONFIRM_ENABLE_DESC               = "Reemplazar escribir DELETE con un boton de confirmacion (Shift pausa).",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_ENABLE_DESC              = "Desactivar la adicion automatica de hechizos a la barra de accion.",

    -- Auto Queue
    AUTOQUEUE_ENABLE_DESC                   = "Activar o desactivar Auto Queue.",
    AUTOQUEUE_AUTO_ACCEPT                   = "Aceptar verificaciones de rol automaticamente",
    AUTOQUEUE_AUTO_ACCEPT_DESC              = "Aceptar verificaciones de rol de LFG automaticamente.",
    AUTOQUEUE_ANNOUNCE                      = "Anunciar en el chat",
    AUTOQUEUE_ANNOUNCE_DESC                 = "Mostrar un mensaje en el chat cuando se acepta una verificacion de rol automaticamente.",
    AUTOQUEUE_CALLOUT                       = "Manten %s para pausar temporalmente. Los roles se configuran en la herramienta de LFG.",

    -- Faster Loot
    FASTERLOOT_ENABLE_DESC                  = "Recoger todo el botin instantaneamente al abrir la ventana de botin. Manten %s para pausar.",

    -- Auto Keystone
    AUTOKEYSTONE_ENABLE_DESC                = "Colocar tu piedra angular automaticamente al abrir la interfaz de M+. Manten %s para omitir.",

    -- Release Protection
    RELEASEPROTECT_ENABLE_DESC              = "Requiere mantener %s para liberar el espiritu (previene liberaciones accidentales).",
    RELEASEPROTECT_SKIP_SOLO                = "Omitir en solitario",
    RELEASEPROTECT_SKIP_SOLO_DESC           = "Desactivar la proteccion cuando no estas en un grupo.",
    RELEASEPROTECT_ACTIVE_IN                = "Activo en",
    RELEASEPROTECT_ACTIVE_IN_DESC           = "Siempre: proteccion en todas partes. Todas las instancias: solo dentro de mazmorras, bandas y JcJ. Personalizado: elige tipos de instancia especificos.",
    RELEASEPROTECT_MODE_ALWAYS              = "Siempre",
    RELEASEPROTECT_MODE_INSTANCES           = "Todas las instancias",
    RELEASEPROTECT_MODE_CUSTOM              = "Personalizado",
    RELEASEPROTECT_HOLD_DURATION            = "Duracion de pulsacion",
    RELEASEPROTECT_HOLD_DURATION_DESC       = "Cuanto tiempo necesitas mantener la tecla modificadora antes de que el boton de liberar se active.",
    RELEASEPROTECT_INSTANCE_TYPES           = "Tipos de instancia",
    RELEASEPROTECT_OPEN_WORLD               = "Mundo abierto",
    RELEASEPROTECT_OPEN_WORLD_DESC          = "Proteger en el mundo abierto (fuera de cualquier instancia).",
    RELEASEPROTECT_DUNGEONS                 = "Mazmorras",
    RELEASEPROTECT_DUNGEONS_DESC            = "Proteger en mazmorras normales, heroicas y miticas.",
    RELEASEPROTECT_MYTHICPLUS               = "M+",
    RELEASEPROTECT_MYTHICPLUS_DESC          = "Proteger en piedras angulares de M+.",
    RELEASEPROTECT_RAIDS                    = "Bandas",
    RELEASEPROTECT_RAIDS_DESC               = "Proteger en todas las dificultades de banda (LFR, Normal, Heroica, Mitica).",
    RELEASEPROTECT_SCENARIOS                = "Escenarios",
    RELEASEPROTECT_SCENARIOS_DESC           = "Proteger en instancias de escenario.",
    RELEASEPROTECT_DELVES                   = "Incursiones",
    RELEASEPROTECT_DELVES_DESC              = "Proteger en Incursiones.",
    RELEASEPROTECT_ARENAS                   = "Arenas",
    RELEASEPROTECT_ARENAS_DESC              = "Proteger en arenas JcJ.",
    RELEASEPROTECT_BATTLEGROUNDS            = "Campos de batalla",
    RELEASEPROTECT_BATTLEGROUNDS_DESC       = "Proteger en campos de batalla JcJ.",

    -- Auto Repair
    AUTOREPAIR_ENABLE_DESC                  = "Activar o desactivar Auto Repair.",
    AUTOREPAIR_SOURCE                       = "Fuente de reparacion",
    AUTOREPAIR_SOURCE_DESC                  = "Oro personal: usar siempre tu propio oro. Fondos de hermandad primero: intentar el banco de hermandad, si no, usar oro personal. Solo fondos de hermandad: usar solo el banco de hermandad (avisa si no esta disponible).",
    AUTOREPAIR_SOURCE_PERSONAL              = "Oro personal",
    AUTOREPAIR_SOURCE_GUILD_FIRST           = "Fondos de hermandad primero",
    AUTOREPAIR_SOURCE_GUILD_ONLY            = "Solo fondos de hermandad",
    AUTOREPAIR_CALLOUT                      = "Manten %s al abrir un vendedor para omitir la reparacion automatica.",

    -- Splash page
    SPLASH_DESC                             = "Un addon modular de calidad de vida para World of Warcraft.\nHaz clic en el nombre de un modulo para configurarlo, o haz clic en el punto de estado para activarlo o desactivarlo.",
    SPLASH_ENABLED                          = "Activado",
    SPLASH_DISABLED                         = "Desactivado",
    SPLASH_CLICK_ENABLE                     = "Clic para activar",
    SPLASH_CLICK_DISABLE                    = "Clic para desactivar",
    SPLASH_COMPANION_HEADER                 = "Addons complementarios",
    SPLASH_CURSEFORGE                       = "CurseForge",
    SPLASH_COPY_LINK                        = "Copiar enlace",
    SPLASH_COPY_HINT                        = "Ctrl+C para copiar, Esc para cerrar",
    COPY                                    = "Copiar",
    SELECT                                  = "Seleccionar",

    -- Companion addon descriptions
    COMPANION_CO_LABEL                      = "Crafting Orders",
    COMPANION_CO_DESC                       = "Anuncia actividad de pedidos de hermandad, alertas de pedidos personales y un boton de Completar + Susurro.",
    COMPANION_WARBAND_LABEL                 = "Warband",
    COMPANION_WARBAND_DESC                  = "Organiza personajes en grupos con equilibrio automatico de oro hacia/desde el banco de clan al abrir un banco.",

    -- Section headers
    SECTION_MODULES                         = "Modulos",
    SECTION_ADDONS                          = "Addons",

    -- General settings page
    SECTION_GENERAL                         = "General",
    SECTION_GENERAL_DESC                    = "Ajustes generales del addon.",

    -- Sidebar page labels
    PAGE_HOME                               = "Inicio",

    -- Category headers
    CATEGORY_GENERAL                        = "General",
    CATEGORY_DUNGEONS                       = "Mazmorras y M+",
    CATEGORY_QUESTING                       = "Misiones y mundo",

    -- Messages (Options.lua / ui.lua)
    MSG_OPTIONS_AFTER_COMBAT                = "Las opciones se abriran despues del combate.",

    -- ui.lua: Minimap tooltip
    UI_MINIMAP_TITLE                        = "Lantern",
    UI_MINIMAP_LEFT_CLICK                   = "Clic izquierdo: Abrir opciones",
    UI_MINIMAP_SHIFT_CLICK                  = "Shift+Clic izquierdo: Recargar interfaz",

    -- ui.lua: StaticPopup link dialog
    UI_COPY_LINK_PROMPT                     = "Ctrl+C para copiar enlace",

    -- ui.lua: Blizzard Settings stub
    UI_SETTINGS_VERSION                     = "Version: %s",
    UI_SETTINGS_AUTHOR                      = "Autor: Dede en el juego / Sponsorn en CurseForge y GitHub",
    UI_SETTINGS_THANKS                      = "Agradecimientos especiales a los que tienen derechos de autor por hacer que me ponga las pilas.",
    UI_SETTINGS_OPEN                        = "Abrir ajustes",
    UI_SETTINGS_AVAILABLE_MODULES           = "Modulos disponibles",
    UI_SETTINGS_CO_DESC                     = "Crafting Orders: anuncia actividad de pedidos de hermandad, alertas de pedidos personales y un boton de Completar + Susurro.",
    UI_SETTINGS_ALREADY_ENABLED             = "Ya activado",
    UI_SETTINGS_WARBAND_DESC                = "Warband: organiza personajes en grupos con equilibrio automatico de oro hacia/desde el banco de clan al abrir un banco.",

    -- core.lua: Slash command
    MSG_MISSINGPET_NOT_FOUND                = "Modulo MissingPet no encontrado.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Metadata (title/desc)
    ---------------------------------------------------------------------------

    -- Auto Quest
    AUTOQUEST_TITLE                         = "Auto Quest",
    AUTOQUEST_DESC                          = "Acepta y entrega misiones automaticamente.",

    -- Auto Queue
    AUTOQUEUE_TITLE                         = "Auto Queue",
    AUTOQUEUE_DESC                          = "Acepta verificaciones de rol automaticamente usando tu seleccion de rol en LFG.",

    -- Auto Repair
    AUTOREPAIR_TITLE                        = "Auto Repair",
    AUTOREPAIR_DESC                         = "Repara el equipo automaticamente en comerciantes.",

    -- Auto Sell
    AUTOSELL_TITLE                          = "Auto Sell",
    AUTOSELL_DESC                           = "Vende basura y objetos personalizados automaticamente en comerciantes.",

    -- Chat Filter
    CHATFILTER_TITLE                        = "Chat Filter",
    CHATFILTER_DESC                         = "Filtra spam de oro, anuncios de boost y mensajes no deseados de susurros y canales publicos.",

    -- Cursor Ring
    CURSORRING_TITLE                        = "Cursor Ring & Trail",
    CURSORRING_DESC                         = "Muestra anillo(s) personalizables alrededor del cursor con indicadores de lanzamiento/GCD y un rastro opcional.",

    -- Delete Confirm
    DELETECONFIRM_TITLE                     = "Delete Confirm",
    DELETECONFIRM_DESC                      = "Ocultar la entrada de eliminacion y activar el boton de confirmacion.",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_TITLE                    = "Disable Auto Add Spells",
    DISABLEAUTOADD_DESC                     = "Impide que los hechizos se anadan automaticamente a las barras de accion.",

    -- Missing Pet
    MISSINGPET_TITLE                        = "Missing Pet",
    MISSINGPET_DESC                         = "Muestra una advertencia cuando tu mascota esta ausente o en modo pasivo.",

    -- Auto Playstyle
    AUTOPLAYSTYLE_TITLE                     = "Auto Playstyle",
    AUTOPLAYSTYLE_DESC                      = "Selecciona automaticamente tu estilo de juego preferido al crear grupos de M+ en el Buscador de grupos.",

    -- Faster Loot
    FASTERLOOT_TITLE                        = "Faster Loot",
    FASTERLOOT_DESC                         = "Recoge todo el botin instantaneamente al abrir la ventana de botin.",

    -- Auto Keystone
    AUTOKEYSTONE_TITLE                      = "Auto Keystone",
    AUTOKEYSTONE_DESC                       = "Coloca automaticamente tu piedra angular de M+ al abrir la interfaz de Modo Desafio.",

    -- Release Protection
    RELEASEPROTECT_TITLE                    = "Release Protection",
    RELEASEPROTECT_DESC                     = "Requiere mantener tu tecla modificadora de pausa antes de liberar el espiritu para prevenir clics accidentales.",

    -- Combat Timer
    COMBATTIMER_TITLE                       = "Combat Timer",
    COMBATTIMER_DESC                        = "Muestra un temporizador con el tiempo que llevas en combate.",

    -- Combat Alert
    COMBATALERT_TITLE                       = "Combat Alert",
    COMBATALERT_DESC                        = "Muestra una alerta de texto con fundido al entrar o salir de combate.",

    -- Range Check
    RANGECHECK_TITLE                        = "Range Check",
    RANGECHECK_DESC                         = "Muestra el estado de alcance o fuera de alcance de tu objetivo actual.",

    -- Tooltip
    TOOLTIP_TITLE                           = "Tooltip",
    TOOLTIP_DESC                            = "Mejora los tooltips con IDs y nombres de monturas.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Print Messages
    ---------------------------------------------------------------------------

    -- Auto Queue messages
    AUTOQUEUE_MSG_ACCEPTED                  = "Verificacion de rol aceptada automaticamente.",

    -- Auto Repair messages
    AUTOREPAIR_MSG_GUILD_UNAVAILABLE        = "No se puede reparar: fondos de hermandad no disponibles.",
    AUTOREPAIR_MSG_REPAIRED_GUILD           = "Reparado por %s (fondos de hermandad).",
    AUTOREPAIR_MSG_REPAIRED                 = "Reparado por %s.",
    AUTOREPAIR_MSG_NOT_ENOUGH_GOLD          = "No se puede reparar: oro insuficiente (se necesitan %s).",

    -- Auto Sell messages
    AUTOSELL_MSG_SOLD_ITEMS                 = "Vendido(s) %d objeto(s) por %s.",

    -- Faster Loot messages
    FASTERLOOT_MSG_INV_FULL                 = "Inventario lleno - algunos objetos no pudieron ser recogidos.",

    -- Chat Filter messages
    CHATFILTER_MSG_ACTIVE                   = "Filtro de chat activo con %d palabras clave.",
    CHATFILTER_MSG_KEYWORD_EXISTS           = "La palabra clave ya esta en la lista de filtros.",
    CHATFILTER_MSG_KEYWORD_ADDED            = "Se anadio \"%s\" al filtro de chat.",

    -- Auto Sell item messages
    AUTOSELL_MSG_ALREADY_IN_LIST            = "El objeto ya esta en la lista de venta.",
    AUTOSELL_MSG_ADDED_TO_LIST              = "Se anadio %s a la lista de venta.",
    AUTOSELL_MSG_INVALID_ITEM_ID            = "Item ID no valido.",

    -- Tooltip messages
    TOOLTIP_MSG_ID_COPIED                   = "%s %s copiado.",

    -- Release Protection overlay text
    RELEASEPROTECT_HOLD_PROGRESS            = "Mantener %s... %.1fs",
    RELEASEPROTECT_HOLD_PROMPT              = "Mantener %s (%.1fs)",

    -- Auto Quest messages
    AUTOQUEST_MSG_NO_NPC                    = "No se encontro NPC. Habla con un NPC primero.",
    AUTOQUEST_MSG_BLOCKED_NPC               = "NPC bloqueado: %s",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoQuest WidgetOptions
    ---------------------------------------------------------------------------

    AUTOQUEST_ENABLE_DESC                   = "Activar o desactivar Auto Quest.",
    AUTOQUEST_AUTO_ACCEPT                   = "Aceptar misiones automaticamente",
    AUTOQUEST_AUTO_ACCEPT_DESC              = "Aceptar misiones de NPCs automaticamente.",
    AUTOQUEST_AUTO_TURNIN                   = "Entregar misiones automaticamente",
    AUTOQUEST_AUTO_TURNIN_DESC              = "Entregar misiones completadas a NPCs automaticamente.",
    AUTOQUEST_SINGLE_REWARD                 = "Seleccionar recompensa unica automaticamente",
    AUTOQUEST_SINGLE_REWARD_DESC            = "Si una mision ofrece solo una recompensa, seleccionarla automaticamente.",
    AUTOQUEST_SINGLE_GOSSIP                 = "Seleccionar opcion de dialogo unica automaticamente",
    AUTOQUEST_SINGLE_GOSSIP_DESC            = "Seleccionar automaticamente NPCs con una sola opcion de dialogo para avanzar en cadenas de dialogo que llevan a misiones.",
    AUTOQUEST_SKIP_TRIVIAL                  = "Omitir misiones triviales",
    AUTOQUEST_SKIP_TRIVIAL_DESC             = "No aceptar automaticamente misiones grises (triviales/nivel bajo).",
    AUTOQUEST_CALLOUT                       = "Manten %s para pausar temporalmente la aceptacion y entrega automatica.",
    AUTOQUEST_ADDON_BYPASS_NOTE             = "Nota: otros addons de automatizacion de misiones (QuickQuest, Plumber, etc.) pueden ignorar la lista de bloqueo.",
    AUTOQUEST_ADD_NPC                       = "Anadir NPC actual a la lista de bloqueo",
    AUTOQUEST_ADD_NPC_DESC                  = "Habla con un NPC y luego haz clic en este boton para bloquearlo de la automatizacion de misiones.",
    AUTOQUEST_ZONE_FILTER                   = "Filtro de zona",
    AUTOQUEST_NPC_ZONE_FILTER_DESC          = "Filtrar NPCs bloqueados por zona.",
    AUTOQUEST_QUEST_ZONE_FILTER_DESC        = "Filtrar misiones bloqueadas por zona.",
    AUTOQUEST_ZONE_ALL                      = "Todas las zonas",
    AUTOQUEST_ZONE_CURRENT                  = "Zona actual",
    AUTOQUEST_BLOCKED_NPCS                  = "NPCs bloqueados (%d)",
    AUTOQUEST_NPC_EMPTY_ALL                 = "No hay NPCs bloqueados -- selecciona un NPC y haz clic en el boton de arriba para anadir uno.",
    AUTOQUEST_NPC_EMPTY_ZONE                = "No hay NPCs bloqueados en %s.",
    AUTOQUEST_REMOVE_NPC_DESC               = "Eliminar a %s de la lista de bloqueo.",
    AUTOQUEST_BLOCKED_QUESTS_HEADER         = "Misiones bloqueadas",
    AUTOQUEST_BLOCKED_QUESTS_NOTE           = "Las misiones bloqueadas no se aceptaran ni entregaran automaticamente.",
    AUTOQUEST_QUEST_EMPTY_ALL               = "No hay misiones bloqueadas -- las misiones aceptadas automaticamente de NPCs bloqueados apareceran aqui.",
    AUTOQUEST_QUEST_EMPTY_ZONE              = "No hay misiones bloqueadas en %s.",
    AUTOQUEST_UNKNOWN_NPC                   = "NPC desconocido",
    AUTOQUEST_QUEST_LABEL_WITH_ID           = "%s (ID: %s)",
    AUTOQUEST_QUEST_LABEL_ID_ONLY           = "Quest ID: %s",
    AUTOQUEST_UNBLOCK_DESC                  = "Desbloquear esta mision.",
    AUTOQUEST_BLOCK_QUEST                   = "Bloquear mision",
    AUTOQUEST_BLOCKED                       = "Bloqueado",
    AUTOQUEST_BLOCK_DESC                    = "Bloquear esta mision de la automatizacion futura.",
    AUTOQUEST_NPC_PREFIX                    = "NPC: %s",
    AUTOQUEST_NO_AUTOMATED                  = "No hay misiones automatizadas aun.",
    AUTOQUEST_RECENT_AUTOMATED              = "Misiones automatizadas recientes (%d)",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoSell WidgetOptions
    ---------------------------------------------------------------------------

    AUTOSELL_ENABLE_DESC                    = "Activar o desactivar Auto Sell.",
    AUTOSELL_SELL_GRAYS                     = "Vender objetos grises",
    AUTOSELL_SELL_GRAYS_DESC                = "Vender automaticamente todos los objetos de calidad inferior (grises).",
    AUTOSELL_CALLOUT                        = "Manten %s al abrir un vendedor para omitir la venta automatica.",
    AUTOSELL_DRAG_DROP                      = "Arrastrar y soltar:",
    AUTOSELL_DRAG_GLOBAL_DESC               = "Arrastra un objeto de tus bolsas y sueltalo aqui para anadirlo a la lista de venta global.",
    AUTOSELL_DRAG_CHAR_DESC                 = "Arrastra un objeto de tus bolsas y sueltalo aqui para anadirlo a la lista de venta de este personaje.",
    AUTOSELL_ITEM_ID                        = "Item ID",
    AUTOSELL_ITEM_ID_GLOBAL_DESC            = "Introduce un Item ID para anadirlo a la lista de venta global.",
    AUTOSELL_ITEM_ID_CHAR_DESC              = "Introduce un Item ID para anadirlo a la lista de venta de este personaje.",
    AUTOSELL_REMOVE_DESC                    = "Eliminar este objeto de la lista de venta.",
    AUTOSELL_GLOBAL_LIST                    = "Lista de venta global (%d)",
    AUTOSELL_CHAR_LIST                      = "Lista de venta de %s (%d)",
    AUTOSELL_CHAR_ONLY_NOTE                 = "Los objetos en esta lista solo se venden en este personaje.",
    AUTOSELL_EMPTY_GLOBAL                   = "No hay objetos en la lista de venta global.",
    AUTOSELL_EMPTY_CHAR                     = "No hay objetos en la lista de venta del personaje.",

    ---------------------------------------------------------------------------
    -- Phase 3: CursorRing WidgetOptions
    ---------------------------------------------------------------------------

    CURSORRING_ENABLE_DESC                  = "Activar o desactivar el modulo Cursor Ring & Trail.",
    CURSORRING_PREVIEW_START                = "Iniciar vista previa",
    CURSORRING_PREVIEW_STOP                 = "Detener vista previa",
    CURSORRING_PREVIEW_DESC                 = "Mostrar todos los elementos visuales en el cursor para edicion en tiempo real. Se desactiva automaticamente al cerrar el panel de ajustes.",
    CURSORRING_GROUP_GENERAL                = "General",
    CURSORRING_SHOW_OOC                     = "Mostrar fuera de combate",
    CURSORRING_SHOW_OOC_DESC                = "Mostrar el anillo del cursor fuera de combate e instancias.",
    CURSORRING_COMBAT_OPACITY               = "Opacidad en combate",
    CURSORRING_COMBAT_OPACITY_DESC          = "Opacidad del anillo en combate o contenido instanciado.",
    CURSORRING_OOC_OPACITY                  = "Opacidad fuera de combate",
    CURSORRING_OOC_OPACITY_DESC             = "Opacidad del anillo fuera de combate.",
    CURSORRING_GROUP_RING1                  = "Anillo 1 (exterior)",
    CURSORRING_ENABLE_RING1                 = "Activar Anillo 1",
    CURSORRING_ENABLE_RING1_DESC            = "Mostrar el anillo exterior.",
    CURSORRING_SHAPE                        = "Forma",
    CURSORRING_RING_SHAPE_DESC              = "Forma del anillo.",
    CURSORRING_SHwPE_CIRCLE                 = "Circulo",
    CURSORRING_SHAPE_THIN                   = "Circulo fino",
    CURSORRING_COLOR                        = "Color",
    CURSORRING_RING1_COLOR_DESC             = "Color del Anillo 1.",
    CURSORRING_SIZE                         = "Tamano",
    CURSORRING_RING1_SIZE_DESC              = "Tamano del Anillo 1 en pixeles.",
    CURSORRING_GROUP_RING2                  = "Anillo 2 (interior)",
    CURSORRING_ENABLE_RING2                 = "Activar Anillo 2",
    CURSORRING_ENABLE_RING2_DESC            = "Mostrar el anillo interior.",
    CURSORRING_RING2_COLOR_DESC             = "Color del Anillo 2.",
    CURSORRING_RING2_SIZE_DESC              = "Tamano del Anillo 2 en pixeles.",
    CURSORRING_GROUP_DOT                    = "Punto central",
    CURSORRING_ENABLE_DOT                   = "Activar punto",
    CURSORRING_ENABLE_DOT_DESC              = "Mostrar un punto pequeno en el centro de los anillos del cursor.",
    CURSORRING_DOT_COLOR_DESC               = "Color del punto.",
    CURSORRING_DOT_SIZE_DESC                = "Tamano del punto en pixeles.",
    CURSORRING_GROUP_CAST                   = "Efecto de lanzamiento",
    CURSORRING_ENABLE_CAST                  = "Activar efecto de lanzamiento",
    CURSORRING_ENABLE_CAST_DESC             = "Mostrar un efecto visual durante el lanzamiento y canalizacion de hechizos.",
    CURSORRING_STYLE                        = "Estilo",
    CURSORRING_CAST_STYLE_DESC              = "Segmentos: el arco se ilumina progresivamente. Relleno: la forma escala desde el centro. Barrido: barrido de enfriamiento (puede ejecutarse simultaneamente con el GCD).",
    CURSORRING_STYLE_SEGMENTS               = "Segmentos",
    CURSORRING_STYLE_FILL                   = "Relleno",
    CURSORRING_STYLE_SWIPE                  = "Barrido",
    CURSORRING_CAST_COLOR_DESC              = "Color del efecto de lanzamiento.",
    CURSORRING_SWIPE_OFFSET                 = "Desplazamiento del barrido",
    CURSORRING_SWIPE_OFFSET_DESC            = "Desplazamiento en pixeles del anillo de barrido de lanzamiento fuera del anillo de GCD. Solo aplica al estilo Barrido.",
    CURSORRING_GROUP_GCD                    = "Indicador de GCD",
    CURSORRING_ENABLE_GCD                   = "Activar GCD",
    CURSORRING_ENABLE_GCD_DESC              = "Mostrar un barrido de enfriamiento para el GCD.",
    CURSORRING_GCD_COLOR_DESC               = "Color del barrido de GCD.",
    CURSORRING_OFFSET                       = "Desplazamiento",
    CURSORRING_GCD_OFFSET_DESC              = "Desplazamiento en pixeles del anillo de GCD fuera del Anillo 1.",
    CURSORRING_GROUP_TRAIL                  = "Rastro del raton",
    CURSORRING_ENABLE_TRAIL                 = "Activar rastro",
    CURSORRING_ENABLE_TRAIL_DESC            = "Mostrar un rastro con desvanecimiento detras del cursor.",
    CURSORRING_TRAIL_STYLE_DESC             = "Estilo de visualizacion del rastro. Resplandor: rastro brillante con desvanecimiento. Linea: cinta continua fina. Linea gruesa: cinta ancha. Puntos: puntos espaciados con desvanecimiento. Personalizado: ajustes manuales.",
    CURSORRING_TRAIL_GLOW                   = "Resplandor",
    CURSORRING_TRAIL_LINE                   = "Linea",
    CURSORRING_TRAIL_THICKLINE              = "Linea gruesa",
    CURSORRING_TRAIL_DOTS                   = "Puntos",
    CURSORRING_TRAIL_CUSTOM                 = "Personalizado",
    CURSORRING_TRAIL_COLOR_DESC             = "Preset de color del rastro. Color de clase usa el color de tu clase actual automaticamente. Arcoiris, Ascuas y Oceano son gradientes multicolor. Personalizado te permite elegir cualquier color abajo.",
    CURSORRING_TRAIL_COLOR_CUSTOM           = "Personalizado",
    CURSORRING_TRAIL_COLOR_CLASS            = "Color de clase",
    CURSORRING_TRAIL_COLOR_GOLD             = "Lantern Gold",
    CURSORRING_TRAIL_COLOR_ARCANE           = "Arcano",
    CURSORRING_TRAIL_COLOR_FEL              = "Vil",
    CURSORRING_TRAIL_COLOR_FIRE             = "Fuego",
    CURSORRING_TRAIL_COLOR_FROST            = "Escarcha",
    CURSORRING_TRAIL_COLOR_HOLY             = "Sagrado",
    CURSORRING_TRAIL_COLOR_SHADOW           = "Sombra",
    CURSORRING_TRAIL_COLOR_RAINBOW          = "Arcoiris",
    CURSORRING_TRAIL_COLOR_ALAR             = "Al'ar",
    CURSORRING_TRAIL_COLOR_EMBER            = "Ascuas",
    CURSORRING_TRAIL_COLOR_OCEAN            = "Oceano",
    CURSORRING_CUSTOM_COLOR                 = "Color personalizado",
    CURSORRING_CUSTOM_COLOR_DESC            = "Color del rastro (solo se usa cuando Color esta en Personalizado).",
    CURSORRING_DURATION                     = "Duracion",
    CURSORRING_DURATION_DESC                = "Cuanto duran los puntos del rastro antes de desvanecerse.",
    CURSORRING_MAX_POINTS                   = "Puntos maximos",
    CURSORRING_MAX_POINTS_DESC              = "Numero de puntos del rastro en la reserva. Valores mas altos crean rastros mas largos pero usan mas memoria.",
    CURSORRING_DOT_SIZE                     = "Tamano de punto",
    CURSORRING_DOT_SIZE_TRAIL_DESC          = "Tamano de cada punto del rastro en pixeles.",
    CURSORRING_DOT_SPACING                  = "Espaciado de puntos",
    CURSORRING_DOT_SPACING_DESC             = "Distancia minima en pixeles antes de colocar un nuevo punto del rastro. Valores mas bajos crean un rastro mas denso y continuo.",
    CURSORRING_SHRINK_AGE                   = "Encoger con el tiempo",
    CURSORRING_SHRINK_AGE_DESC              = "Los puntos del rastro se encogen al desvanecerse. Desactiva para un rastro de ancho uniforme.",
    CURSORRING_TAPER_DISTANCE               = "Afinar con la distancia",
    CURSORRING_TAPER_DISTANCE_DESC          = "Los puntos del rastro se encogen y desvanecen hacia la cola, creando un efecto de pincelada afinada.",
    CURSORRING_SPARKLE                      = "Destello",
    CURSORRING_SPARKLE_DESC                 = "Anade pequenas particulas brillantes a lo largo del rastro al mover el cursor.",
    CURSORRING_SPARKLE_OFF                  = "Desactivado",
    CURSORRING_SPARKLE_STATIC               = "Estatico",
    CURSORRING_SPARKLE_TWINKLE              = "Centelleo",
    CURSORRING_TRAIL_PERF_NOTE              = "El rastro se ejecuta por fotograma. Mas puntos, destellos y efectos usaran mas CPU.",

    ---------------------------------------------------------------------------
    -- Phase 3: MissingPet WidgetOptions
    ---------------------------------------------------------------------------

    MISSINGPET_ENABLE_DESC                  = "Activar o desactivar la advertencia de Missing Pet.",
    MISSINGPET_GROUP_WARNING                = "Ajustes de advertencia",
    MISSINGPET_SHOW_MISSING                 = "Mostrar advertencia de ausencia",
    MISSINGPET_SHOW_MISSING_DESC            = "Mostrar una advertencia cuando tu mascota esta despedida o muerta.",
    MISSINGPET_SHOW_PASSIVE                 = "Mostrar advertencia de pasivo",
    MISSINGPET_SHOW_PASSIVE_DESC            = "Mostrar una advertencia cuando tu mascota esta en modo pasivo.",
    MISSINGPET_MISSING_TEXT                 = "Texto de ausencia",
    MISSINGPET_MISSING_TEXT_DESC            = "Texto a mostrar cuando tu mascota esta ausente.",
    MISSINGPET_PASSIVE_TEXT                 = "Texto de pasivo",
    MISSINGPET_PASSIVE_TEXT_DESC            = "Texto a mostrar cuando tu mascota esta en modo pasivo.",
    MISSINGPET_MISSING_COLOR                = "Color de ausencia",
    MISSINGPET_MISSING_COLOR_DESC           = "Color del texto de advertencia de mascota ausente.",
    MISSINGPET_PASSIVE_COLOR                = "Color de pasivo",
    MISSINGPET_PASSIVE_COLOR_DESC           = "Color del texto de advertencia de mascota en pasivo.",
    MISSINGPET_ANIMATION_DESC               = "Elige como se anima el texto de advertencia.",
    MISSINGPET_GROUP_FONT                   = "Ajustes de fuente",
    MISSINGPET_FONT_DESC                    = "Selecciona la fuente para el texto de advertencia.",
    MISSINGPET_FONT_SIZE_DESC               = "Tamano del texto de advertencia.",
    MISSINGPET_FONT_OUTLINE_DESC            = "Estilo de contorno del texto de advertencia.",
    MISSINGPET_LOCK_POSITION_DESC           = "Impedir que la advertencia se mueva.",
    MISSINGPET_RESET_POSITION_DESC          = "Restablecer la posicion del marco de advertencia al centro de la pantalla.",
    MISSINGPET_GROUP_VISIBILITY             = "Visibilidad",
    MISSINGPET_HIDE_MOUNTED                 = "Ocultar al montar",
    MISSINGPET_HIDE_MOUNTED_DESC            = "Ocultar la advertencia mientras estas montado, en un taxi o en un vehiculo.",
    MISSINGPET_HIDE_REST                    = "Ocultar en zonas de descanso",
    MISSINGPET_HIDE_REST_DESC               = "Ocultar la advertencia en zonas de descanso (ciudades y posadas).",
    MISSINGPET_DISMOUNT_DELAY               = "Retraso al desmontar",
    MISSINGPET_DISMOUNT_DELAY_DESC          = "Segundos a esperar tras desmontar antes de mostrar la advertencia. Pon 0 para mostrar inmediatamente.",
    MISSINGPET_PLAY_SOUND_DESC              = "Reproducir un sonido cuando se muestra la advertencia.",
    MISSINGPET_SOUND_MISSING                = "Sonido al estar ausente",
    MISSINGPET_SOUND_MISSING_DESC           = "Reproducir sonido cuando la mascota esta ausente.",
    MISSINGPET_SOUND_PASSIVE                = "Sonido al estar en pasivo",
    MISSINGPET_SOUND_PASSIVE_DESC           = "Reproducir sonido cuando la mascota esta en modo pasivo.",
    MISSINGPET_SOUND_COMBAT                 = "Sonido en combate",
    MISSINGPET_SOUND_COMBAT_DESC            = "Seguir reproduciendo sonido en combate. Si se desactiva, el sonido se detiene al iniciar combate.",
    MISSINGPET_SOUND_REPEAT                 = "Repetir sonido",
    MISSINGPET_SOUND_REPEAT_DESC            = "Repetir el sonido a intervalos regulares mientras se muestra la advertencia.",
    MISSINGPET_SOUND_SELECT_DESC            = "Selecciona el sonido a reproducir. Haz clic en el icono de altavoz para previsualizar.",
    MISSINGPET_REPEAT_INTERVAL              = "Intervalo de repeticion",
    MISSINGPET_REPEAT_INTERVAL_DESC         = "Segundos entre repeticiones de sonido.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatAlert WidgetOptions
    ---------------------------------------------------------------------------

    COMBATALERT_ENABLE_DESC                 = "Mostrar alertas de texto al entrar/salir de combate.",
    COMBATALERT_PREVIEW_DESC                = "Repetir alertas de entrada/salida en pantalla para edicion en tiempo real. Se desactiva automaticamente al cerrar el panel de ajustes.",
    COMBATALERT_GROUP_ENTER                 = "Entrada a combate",
    COMBATALERT_SHOW_ENTER                  = "Mostrar alerta de entrada",
    COMBATALERT_SHOW_ENTER_DESC             = "Mostrar una alerta al entrar en combate.",
    COMBATALERT_ENTER_TEXT                   = "Texto de entrada",
    COMBATALERT_ENTER_TEXT_DESC             = "Texto que se muestra al entrar en combate.",
    COMBATALERT_ENTER_COLOR                 = "Color de entrada",
    COMBATALERT_ENTER_COLOR_DESC            = "Color del texto de entrada a combate.",
    COMBATALERT_GROUP_LEAVE                 = "Salida de combate",
    COMBATALERT_SHOW_LEAVE                  = "Mostrar alerta de salida",
    COMBATALERT_SHOW_LEAVE_DESC             = "Mostrar una alerta al salir de combate.",
    COMBATALERT_LEAVE_TEXT                   = "Texto de salida",
    COMBATALERT_LEAVE_TEXT_DESC             = "Texto que se muestra al salir de combate.",
    COMBATALERT_LEAVE_COLOR                 = "Color de salida",
    COMBATALERT_LEAVE_COLOR_DESC            = "Color del texto de salida de combate.",
    COMBATALERT_GROUP_FONT                  = "Ajustes de fuente y visualizacion",
    COMBATALERT_FONT_DESC                   = "Selecciona la fuente para el texto de alerta.",
    COMBATALERT_FONT_SIZE_DESC              = "Tamano del texto de alerta.",
    COMBATALERT_FONT_OUTLINE_DESC           = "Estilo de contorno del texto de alerta.",
    COMBATALERT_FADE_DURATION               = "Duracion del desvanecimiento",
    COMBATALERT_FADE_DURATION_DESC          = "Duracion total de la alerta (mantenimiento + desvanecimiento) en segundos.",
    COMBATALERT_PLAY_SOUND_DESC             = "Reproducir un sonido al mostrar la alerta.",
    COMBATALERT_SOUND_SELECT_DESC           = "Selecciona el sonido a reproducir.",
    COMBATALERT_LOCK_POSITION_DESC          = "Impedir que la alerta se mueva.",
    COMBATALERT_RESET_POSITION_DESC         = "Restablecer la alerta a su posicion predeterminada.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatTimer WidgetOptions
    ---------------------------------------------------------------------------

    COMBATTIMER_ENABLE_DESC                 = "Mostrar un temporizador durante el combate.",
    COMBATTIMER_PREVIEW_DESC                = "Mostrar el temporizador en pantalla para edicion en tiempo real. Se desactiva automaticamente al cerrar el panel de ajustes.",
    COMBATTIMER_FONT_DESC                   = "Selecciona la fuente para el texto del temporizador.",
    COMBATTIMER_FONT_SIZE_DESC              = "Tamano del texto del temporizador.",
    COMBATTIMER_FONT_OUTLINE_DESC           = "Estilo de contorno del texto del temporizador.",
    COMBATTIMER_FONT_COLOR_DESC             = "Color del texto del temporizador.",
    COMBATTIMER_STICKY_DURATION             = "Duracion persistente",
    COMBATTIMER_STICKY_DURATION_DESC        = "Segundos que se muestra el tiempo final tras acabar el combate. Pon 0 para ocultar inmediatamente.",
    COMBATTIMER_LOCK_POSITION_DESC          = "Impedir que el temporizador se mueva.",
    COMBATTIMER_RESET_POSITION_DESC         = "Restablecer el temporizador a su posicion predeterminada.",

    ---------------------------------------------------------------------------
    -- Phase 3: RangeCheck WidgetOptions
    ---------------------------------------------------------------------------

    RANGECHECK_ENABLE_DESC                  = "Mostrar el estado de alcance o fuera de alcance de tu objetivo actual.",
    RANGECHECK_HIDE_IN_RANGE                = "Ocultar cuando esta en alcance",
    RANGECHECK_HIDE_IN_RANGE_DESC           = "Ocultar la visualizacion cuando tu objetivo esta dentro del alcance. Solo se muestra cuando esta fuera de alcance.",
    RANGECHECK_COMBAT_ONLY                  = "Solo en combate",
    RANGECHECK_COMBAT_ONLY_DESC             = "Solo mostrar el alcance durante el combate.",
    RANGECHECK_GROUP_STATUS                 = "Texto de estado",
    RANGECHECK_IN_RANGE_TEXT                = "Texto en alcance",
    RANGECHECK_IN_RANGE_TEXT_DESC           = "Texto a mostrar cuando tu objetivo esta dentro del alcance.",
    RANGECHECK_OUT_OF_RANGE_TEXT            = "Texto fuera de alcance",
    RANGECHECK_OUT_OF_RANGE_TEXT_DESC       = "Texto a mostrar cuando tu objetivo esta fuera de alcance.",
    RANGECHECK_IN_RANGE_COLOR               = "Color en alcance",
    RANGECHECK_IN_RANGE_COLOR_DESC          = "Color del texto de en alcance.",
    RANGECHECK_OUT_OF_RANGE_COLOR           = "Color fuera de alcance",
    RANGECHECK_OUT_OF_RANGE_COLOR_DESC      = "Color del texto de fuera de alcance.",
    RANGECHECK_ANIMATION_DESC               = "Elige como se anima el texto de estado al cambiar de estado.",
    RANGECHECK_FONT_DESC                    = "Selecciona la fuente para el texto de alcance.",
    RANGECHECK_FONT_SIZE_DESC               = "Tamano del texto de alcance.",
    RANGECHECK_FONT_OUTLINE_DESC            = "Estilo de contorno del texto de alcance.",
    RANGECHECK_LOCK_POSITION_DESC           = "Impedir que la visualizacion de alcance se mueva.",
    RANGECHECK_RESET_POSITION_DESC          = "Restablecer la visualizacion de alcance a su posicion predeterminada.",

    ---------------------------------------------------------------------------
    -- Phase 3: ChatFilter WidgetOptions
    ---------------------------------------------------------------------------

    CHATFILTER_ENABLE_DESC                  = "Activar o desactivar el Chat Filter.",
    CHATFILTER_LOGIN_MESSAGE                = "Mensaje de inicio de sesion",
    CHATFILTER_LOGIN_MESSAGE_DESC           = "Mostrar un mensaje en el chat al iniciar sesion confirmando que el filtro esta activo.",
    CHATFILTER_ADD_KEYWORD                  = "Anadir palabra clave",
    CHATFILTER_ADD_KEYWORD_DESC             = "Introduce una palabra o frase para filtrar. La coincidencia no distingue mayusculas de minusculas.",
    CHATFILTER_KEYWORDS_GROUP               = "Palabras clave (%d)",
    CHATFILTER_NO_KEYWORDS                  = "No hay palabras clave configuradas.",
    CHATFILTER_REMOVE_KEYWORD_DESC          = "Eliminar \"%s\" de la lista de filtros.",
    CHATFILTER_RESTORE_DEFAULTS             = "Restaurar palabras clave predeterminadas",
    CHATFILTER_RESTORE_DEFAULTS_DESC        = "Restablecer la lista de palabras clave a los valores predeterminados. Esto reemplaza todas las palabras clave personalizadas.",
    CHATFILTER_RESTORE_CONFIRM              = "Restaurar?",

    ---------------------------------------------------------------------------
    -- Phase 3: Tooltip WidgetOptions
    ---------------------------------------------------------------------------

    TOOLTIP_ENABLE_DESC                     = "Mejorar los tooltips con informacion adicional.",
    TOOLTIP_GROUP_PLAYER                    = "Jugador",
    TOOLTIP_MOUNT_NAME                      = "Nombre de montura",
    TOOLTIP_MOUNT_NAME_DESC                 = "Mostrar la montura que un jugador esta usando actualmente.",
    TOOLTIP_GROUP_ITEMS                     = "Objetos",
    TOOLTIP_ITEM_ID                         = "Item ID",
    TOOLTIP_ITEM_ID_DESC                    = "Mostrar el Item ID en los tooltips de objetos.",
    TOOLTIP_ITEM_SPELL_ID                   = "Spell ID de objeto",
    TOOLTIP_ITEM_SPELL_ID_DESC              = "Mostrar el Spell ID del efecto de uso en consumibles y otros objetos con habilidades de uso.",
    TOOLTIP_GROUP_SPELLS                    = "Hechizos",
    TOOLTIP_SPELL_ID                        = "Spell ID",
    TOOLTIP_SPELL_ID_DESC                   = "Mostrar el Spell ID en tooltips de hechizos, auras y talentos.",
    TOOLTIP_NODE_ID                         = "Node ID",
    TOOLTIP_NODE_ID_DESC                    = "Mostrar el Node ID del arbol de talentos en tooltips de talentos.",
    TOOLTIP_GROUP_COPY                      = "Copiar",
    TOOLTIP_CTRL_C                          = "Ctrl+C para copiar",
    TOOLTIP_CTRL_C_DESC                     = "Pulsa Ctrl+C para copiar el ID principal, o Ctrl+Shift+C para copiar el ID secundario (ej: el Spell ID de efecto de uso de un objeto).",
    TOOLTIP_COMBAT_NOTE                     = "Las mejoras de tooltip se desactivan en instancias. El escaneo de monturas y la copia con Ctrl+C se desactivan en combate.",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoPlaystyle WidgetOptions
    ---------------------------------------------------------------------------

    AUTOPLAYSTYLE_ENABLE_DESC               = "Seleccionar automaticamente el estilo de juego al crear grupos de M+.",
    AUTOPLAYSTYLE_PLAYSTYLE                 = "Estilo de juego",
    AUTOPLAYSTYLE_PLAYSTYLE_DESC            = "Selecciona automaticamente este estilo de juego al abrir el dialogo de creacion de grupo del Buscador de grupos para mazmorras M+.",

    ---------------------------------------------------------------------------
    -- Shared: Font outline values (used across multiple modules)
    ---------------------------------------------------------------------------

    FONT_OUTLINE_NONE                       = "Ninguno",
    FONT_OUTLINE_OUTLINE                    = "Contorno",
    FONT_OUTLINE_THICK                      = "Contorno grueso",
    FONT_OUTLINE_MONO                       = "Monocromo",
    FONT_OUTLINE_OUTLINE_MONO              = "Contorno + Mono",

    ---------------------------------------------------------------------------
    -- Shared: Animation values (used across MissingPet, RangeCheck)
    ---------------------------------------------------------------------------

    ANIMATION_NONE                          = "Ninguna (estatica)",
    ANIMATION_BOUNCE                        = "Rebote",
    ANIMATION_PULSE                         = "Pulso",
    ANIMATION_FADE                          = "Desvanecimiento",
    ANIMATION_SHAKE                         = "Temblor",
    ANIMATION_GLOW                          = "Resplandor",
    ANIMATION_HEARTBEAT                     = "Latido",

    ---------------------------------------------------------------------------
    -- Shared: Confirm/Remove labels
    ---------------------------------------------------------------------------

    SHARED_REMOVE                           = "Eliminar",
    SHARED_REMOVE_CONFIRM                   = "Eliminar?",

    ---------------------------------------------------------------------------
    -- Tooltip: in-game tooltip hint lines
    ---------------------------------------------------------------------------

    TOOLTIP_HINT_COPY                       = "Ctrl+C para copiar",
    TOOLTIP_HINT_COPY_BOTH                  = "Ctrl+C ItemID  |  Ctrl+Shift+C SpellID",
    TOOLTIP_COPY_HINT                       = "Ctrl+C para copiar, Esc para cerrar",
});
