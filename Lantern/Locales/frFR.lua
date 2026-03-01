local ADDON_NAME, Lantern = ...;
Lantern:RegisterLocale("frFR", {

    -- Shared
    ENABLE                                  = "Activer",
    SHARED_FONT                             = "Police",
    SHARED_FONT_SIZE                        = "Taille de police",
    SHARED_FONT_OUTLINE                     = "Contour de police",
    SHARED_FONT_COLOR                       = "Couleur de police",
    SHARED_GROUP_POSITION                   = "Position",
    SHARED_LOCK_POSITION                    = "Verrouiller la position",
    SHARED_RESET_POSITION                   = "Reinitialiser la position",
    SHARED_GROUP_SOUND                      = "Son",
    SHARED_SOUND_SELECT                     = "Son",
    SHARED_PLAY_SOUND                       = "Jouer un son",
    SHARED_PREVIEW                          = "Apercu",
    SHARED_GROUP_DISPLAY                    = "Affichage",
    SHARED_ANIMATION_STYLE                  = "Style d'animation",

    -- General settings
    GENERAL_MINIMAP_SHOW                    = "Afficher l'icone de minicarte",
    GENERAL_MINIMAP_SHOW_DESC               = "Afficher ou masquer le bouton Lantern sur la minicarte.",
    GENERAL_MINIMAP_MODERN                  = "Icone de minicarte moderne",
    GENERAL_MINIMAP_MODERN_DESC             = "Retirer la bordure et le fond du bouton de minicarte pour un style moderne avec un halo de lanterne au survol.",
    GENERAL_PAUSE_MODIFIER                  = "Touche de pause",
    GENERAL_PAUSE_MODIFIER_DESC             = "Maintenez cette touche pour mettre en pause temporairement les fonctions automatiques (Auto Quest, Auto Queue, Auto Repair, etc.).",

    -- Modifier values (used in dropdowns)
    MODIFIER_SHIFT                          = "Shift",
    MODIFIER_CTRL                           = "Ctrl",
    MODIFIER_ALT                            = "Alt",

    -- Delete Confirm
    DELETECONFIRM_ENABLE_DESC               = "Remplacer la saisie de SUPPRIMER par un bouton de confirmation (Shift pour suspendre).",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_ENABLE_DESC              = "Empecher l'ajout automatique de sorts dans la barre d'action.",

    -- Auto Queue
    AUTOQUEUE_ENABLE_DESC                   = "Activer ou desactiver Auto Queue.",
    AUTOQUEUE_AUTO_ACCEPT                   = "Accepter automatiquement les verifications de role",
    AUTOQUEUE_AUTO_ACCEPT_DESC              = "Accepter automatiquement les verifications de role LFG.",
    AUTOQUEUE_ANNOUNCE                      = "Annonce dans le chat",
    AUTOQUEUE_ANNOUNCE_DESC                 = "Afficher un message dans le chat quand une verification de role est auto-acceptee.",
    AUTOQUEUE_CALLOUT                       = "Maintenez %s pour mettre en pause temporairement. Les roles sont definis dans l'outil LFG.",

    -- Faster Loot
    FASTERLOOT_ENABLE_DESC                  = "Recuperer instantanement tout le butin a l'ouverture de la fenetre. Maintenez %s pour suspendre.",

    -- Auto Keystone
    AUTOKEYSTONE_ENABLE_DESC                = "Inserer automatiquement votre clef de voute a l'ouverture de l'interface M+. Maintenez %s pour passer.",

    -- Release Protection
    RELEASEPROTECT_ENABLE_DESC              = "Exiger de maintenir %s pour liberer l'esprit (empeche les clics accidentels).",
    RELEASEPROTECT_SKIP_SOLO                = "Ignorer en solo",
    RELEASEPROTECT_SKIP_SOLO_DESC           = "Desactiver la protection quand vous n'etes pas dans un groupe.",
    RELEASEPROTECT_ACTIVE_IN                = "Actif dans",
    RELEASEPROTECT_ACTIVE_IN_DESC           = "Toujours : protection partout. Toutes les instances : uniquement dans les donjons, raids et JcJ. Personnalise : choisir des types d'instance specifiques.",
    RELEASEPROTECT_MODE_ALWAYS              = "Toujours",
    RELEASEPROTECT_MODE_INSTANCES           = "Toutes les instances",
    RELEASEPROTECT_MODE_CUSTOM              = "Personnalise",
    RELEASEPROTECT_HOLD_DURATION            = "Duree de maintien",
    RELEASEPROTECT_HOLD_DURATION_DESC       = "Combien de temps vous devez maintenir la touche modificatrice avant que le bouton de liberation devienne actif.",
    RELEASEPROTECT_INSTANCE_TYPES           = "Types d'instance",
    RELEASEPROTECT_OPEN_WORLD               = "Monde ouvert",
    RELEASEPROTECT_OPEN_WORLD_DESC          = "Proteger dans le monde ouvert (hors de toute instance).",
    RELEASEPROTECT_DUNGEONS                 = "Donjons",
    RELEASEPROTECT_DUNGEONS_DESC            = "Proteger dans les donjons normaux, heroiques et mythiques.",
    RELEASEPROTECT_MYTHICPLUS               = "Mythic+",
    RELEASEPROTECT_MYTHICPLUS_DESC          = "Proteger dans les clefs de voute Mythic+.",
    RELEASEPROTECT_RAIDS                    = "Raids",
    RELEASEPROTECT_RAIDS_DESC               = "Proteger dans toutes les difficultes de raid (RdR, Normal, Heroique, Mythique).",
    RELEASEPROTECT_SCENARIOS                = "Scenarios",
    RELEASEPROTECT_SCENARIOS_DESC           = "Proteger dans les scenarios.",
    RELEASEPROTECT_DELVES                   = "Profondeurs",
    RELEASEPROTECT_DELVES_DESC              = "Proteger dans les Profondeurs.",
    RELEASEPROTECT_ARENAS                   = "Arenes",
    RELEASEPROTECT_ARENAS_DESC              = "Proteger dans les arenes JcJ.",
    RELEASEPROTECT_BATTLEGROUNDS            = "Champs de bataille",
    RELEASEPROTECT_BATTLEGROUNDS_DESC       = "Proteger dans les champs de bataille JcJ.",

    -- Auto Repair
    AUTOREPAIR_ENABLE_DESC                  = "Activer ou desactiver Auto Repair.",
    AUTOREPAIR_SOURCE                       = "Source de reparation",
    AUTOREPAIR_SOURCE_DESC                  = "Or personnel : toujours utiliser votre or. Fonds de guilde d'abord : essayer la banque de guilde, puis l'or personnel. Fonds de guilde uniquement : utiliser seulement la banque de guilde (avertit si indisponible).",
    AUTOREPAIR_SOURCE_PERSONAL              = "Or personnel",
    AUTOREPAIR_SOURCE_GUILD_FIRST           = "Fonds de guilde d'abord",
    AUTOREPAIR_SOURCE_GUILD_ONLY            = "Fonds de guilde uniquement",
    AUTOREPAIR_CALLOUT                      = "Maintenez %s en ouvrant un marchand pour ignorer la reparation automatique.",

    -- Splash page
    SPLASH_DESC                             = "Un addon modulaire de confort pour World of Warcraft.\nCliquez sur le nom d'un module pour le configurer, ou cliquez sur le point de statut pour l'activer/desactiver.",
    SPLASH_ENABLED                          = "Active",
    SPLASH_DISABLED                         = "Desactive",
    SPLASH_CLICK_ENABLE                     = "Cliquer pour activer",
    SPLASH_CLICK_DISABLE                    = "Cliquer pour desactiver",
    SPLASH_COMPANION_HEADER                 = "Addons compagnons",
    SPLASH_CURSEFORGE                       = "CurseForge",
    SPLASH_COPY_LINK                        = "Copier le lien",
    SPLASH_COPY_HINT                        = "Ctrl+C pour copier, Esc pour fermer",
    COPY                                    = "Copier",
    SELECT                                  = "Selectionner",

    -- Companion addon descriptions
    COMPANION_CO_LABEL                      = "Crafting Orders",
    COMPANION_CO_DESC                       = "Annonce l'activite des commandes de guilde, les alertes de commandes personnelles, et un bouton Terminer + Chuchoter.",
    COMPANION_WARBAND_LABEL                 = "Warband",
    COMPANION_WARBAND_DESC                  = "Organisez vos personnages en groupes avec un equilibrage automatique de l'or vers/depuis la banque de bande a l'ouverture de la banque.",

    -- Section headers
    SECTION_MODULES                         = "Modules",
    SECTION_ADDONS                          = "Addons",

    -- General settings page
    SECTION_GENERAL                         = "General",
    SECTION_GENERAL_DESC                    = "Parametres generaux de l'addon.",

    -- Sidebar page labels
    PAGE_HOME                               = "Accueil",

    -- Category headers
    CATEGORY_GENERAL                        = "General",
    CATEGORY_DUNGEONS                       = "Donjons & M+",
    CATEGORY_QUESTING                       = "Quetes & Monde",

    -- Messages (Options.lua / ui.lua)
    MSG_OPTIONS_AFTER_COMBAT                = "Les options s'ouvriront apres le combat.",

    -- ui.lua: Minimap tooltip
    UI_MINIMAP_TITLE                        = "Lantern",
    UI_MINIMAP_LEFT_CLICK                   = "Clic gauche : Ouvrir les options",
    UI_MINIMAP_SHIFT_CLICK                  = "Shift+Clic gauche : Recharger l'interface",

    -- ui.lua: StaticPopup link dialog
    UI_COPY_LINK_PROMPT                     = "Ctrl+C pour copier le lien",

    -- ui.lua: Blizzard Settings stub
    UI_SETTINGS_VERSION                     = "Version : %s",
    UI_SETTINGS_AUTHOR                      = "Auteur : Dede en jeu / Sponsorn sur CurseForge & GitHub",
    UI_SETTINGS_THANKS                      = "Remerciements speciaux aux copyrighters pour m'avoir motive a m'y mettre.",
    UI_SETTINGS_OPEN                        = "Ouvrir les parametres",
    UI_SETTINGS_AVAILABLE_MODULES           = "Modules disponibles",
    UI_SETTINGS_CO_DESC                     = "Crafting Orders : annonce l'activite des commandes de guilde, les alertes de commandes personnelles, et un bouton Terminer + Chuchoter.",
    UI_SETTINGS_ALREADY_ENABLED             = "Deja active",
    UI_SETTINGS_WARBAND_DESC                = "Warband : organisez vos personnages en groupes avec un equilibrage automatique de l'or vers/depuis la banque de bande a l'ouverture de la banque.",

    -- core.lua: Slash command
    MSG_MISSINGPET_NOT_FOUND                = "Module Missing Pet introuvable.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Metadata (title/desc)
    ---------------------------------------------------------------------------

    -- Auto Quest
    AUTOQUEST_TITLE                         = "Auto Quest",
    AUTOQUEST_DESC                          = "Accepter et rendre automatiquement les quetes.",

    -- Auto Queue
    AUTOQUEUE_TITLE                         = "Auto Queue",
    AUTOQUEUE_DESC                          = "Accepter automatiquement les verifications de role selon votre selection LFG.",

    -- Auto Repair
    AUTOREPAIR_TITLE                        = "Auto Repair",
    AUTOREPAIR_DESC                         = "Reparer automatiquement l'equipement chez les marchands.",

    -- Auto Sell
    AUTOSELL_TITLE                          = "Auto Sell",
    AUTOSELL_DESC                           = "Vendre automatiquement la camelote et les objets personnalises chez les marchands.",

    -- Chat Filter
    CHATFILTER_TITLE                        = "Chat Filter",
    CHATFILTER_DESC                         = "Filtre les spams d'or, les pubs de boost et les messages indesirables dans les chuchotements et les canaux publics.",

    -- Cursor Ring
    CURSORRING_TITLE                        = "Cursor Ring & Trail",
    CURSORRING_DESC                         = "Affiche un ou plusieurs anneaux personnalisables autour du curseur avec des indicateurs d'incantation/GCD et une trainee optionnelle.",

    -- Delete Confirm
    DELETECONFIRM_TITLE                     = "Delete Confirm",
    DELETECONFIRM_DESC                      = "Masquer le champ de suppression et activer le bouton de confirmation.",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_TITLE                    = "Disable Auto Add Spells",
    DISABLEAUTOADD_DESC                     = "Empeche les sorts de s'ajouter automatiquement aux barres d'action.",

    -- Missing Pet
    MISSINGPET_TITLE                        = "Missing Pet",
    MISSINGPET_DESC                         = "Affiche un avertissement quand votre familier est absent ou en mode passif.",

    -- Auto Playstyle
    AUTOPLAYSTYLE_TITLE                     = "Auto Playstyle",
    AUTOPLAYSTYLE_DESC                      = "Selectionne automatiquement votre style de jeu prefere lors de la creation de groupes M+ dans l'outil de recherche de groupe.",

    -- Faster Loot
    FASTERLOOT_TITLE                        = "Faster Loot",
    FASTERLOOT_DESC                         = "Recuperer instantanement tout le butin a l'ouverture de la fenetre de butin.",

    -- Auto Keystone
    AUTOKEYSTONE_TITLE                      = "Auto Keystone",
    AUTOKEYSTONE_DESC                       = "Inserer automatiquement votre clef de voute Mythic+ a l'ouverture de l'interface de defi.",

    -- Release Protection
    RELEASEPROTECT_TITLE                    = "Release Protection",
    RELEASEPROTECT_DESC                     = "Exiger de maintenir votre touche de pause avant de liberer l'esprit pour eviter les clics accidentels.",

    -- Combat Timer
    COMBATTIMER_TITLE                       = "Combat Timer",
    COMBATTIMER_DESC                        = "Afficher un chronometre indiquant la duree de votre combat.",

    -- Combat Alert
    COMBATALERT_TITLE                       = "Combat Alert",
    COMBATALERT_DESC                        = "Afficher une alerte en fondu a l'entree et a la sortie du combat.",

    -- Range Check
    RANGECHECK_TITLE                        = "Range Check",
    RANGECHECK_DESC                         = "Afficher si votre cible actuelle est a portee ou hors de portee.",

    -- Tooltip
    TOOLTIP_TITLE                           = "Tooltip",
    TOOLTIP_DESC                            = "Ameliore les infobulles avec les IDs et les noms de montures.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Print Messages
    ---------------------------------------------------------------------------

    -- Auto Queue messages
    AUTOQUEUE_MSG_ACCEPTED                  = "Verification de role auto-acceptee.",

    -- Auto Repair messages
    AUTOREPAIR_MSG_GUILD_UNAVAILABLE        = "Reparation impossible : fonds de guilde indisponibles.",
    AUTOREPAIR_MSG_REPAIRED_GUILD           = "Repare pour %s (fonds de guilde).",
    AUTOREPAIR_MSG_REPAIRED                 = "Repare pour %s.",
    AUTOREPAIR_MSG_NOT_ENOUGH_GOLD          = "Reparation impossible : pas assez d'or (%s necessaires).",

    -- Auto Sell messages
    AUTOSELL_MSG_SOLD_ITEMS                 = "%d objet(s) vendu(s) pour %s.",

    -- Faster Loot messages
    FASTERLOOT_MSG_INV_FULL                 = "Inventaire plein - certains objets n'ont pas pu etre recuperes.",

    -- Chat Filter messages
    CHATFILTER_MSG_ACTIVE                   = "Filtre de chat actif avec %d mots-cles.",
    CHATFILTER_MSG_KEYWORD_EXISTS           = "Mot-cle deja dans la liste de filtres.",
    CHATFILTER_MSG_KEYWORD_ADDED            = "\"%s\" ajoute au filtre de chat.",

    -- Auto Sell item messages
    AUTOSELL_MSG_ALREADY_IN_LIST            = "Objet deja dans la liste de vente.",
    AUTOSELL_MSG_ADDED_TO_LIST              = "%s ajoute a la liste de vente.",
    AUTOSELL_MSG_INVALID_ITEM_ID            = "Item ID invalide.",

    -- Tooltip messages
    TOOLTIP_MSG_ID_COPIED                   = "%s %s copie.",

    -- Release Protection overlay text
    RELEASEPROTECT_HOLD_PROGRESS            = "Maintenez %s... %.1fs",
    RELEASEPROTECT_HOLD_PROMPT              = "Maintenez %s (%.1fs)",

    -- Auto Quest messages
    AUTOQUEST_MSG_NO_NPC                    = "Aucun PNJ trouve. Parlez d'abord a un PNJ.",
    AUTOQUEST_MSG_BLOCKED_NPC               = "PNJ bloque : %s",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoQuest WidgetOptions
    ---------------------------------------------------------------------------

    AUTOQUEST_ENABLE_DESC                   = "Activer ou desactiver Auto Quest.",
    AUTOQUEST_AUTO_ACCEPT                   = "Accepter automatiquement les quetes",
    AUTOQUEST_AUTO_ACCEPT_DESC              = "Accepter automatiquement les quetes aupres des PNJ.",
    AUTOQUEST_AUTO_TURNIN                   = "Rendre automatiquement les quetes",
    AUTOQUEST_AUTO_TURNIN_DESC              = "Rendre automatiquement les quetes terminees aupres des PNJ.",
    AUTOQUEST_SINGLE_REWARD                 = "Selection automatique de recompense unique",
    AUTOQUEST_SINGLE_REWARD_DESC            = "Si une quete n'offre qu'une seule recompense, la selectionner automatiquement.",
    AUTOQUEST_SINGLE_GOSSIP                 = "Selection automatique du dialogue unique",
    AUTOQUEST_SINGLE_GOSSIP_DESC            = "Selectionner automatiquement les PNJ n'ayant qu'une seule option de dialogue pour progresser dans les chaines de dialogues menant a des quetes.",
    AUTOQUEST_SKIP_TRIVIAL                  = "Ignorer les quetes insignifiantes",
    AUTOQUEST_SKIP_TRIVIAL_DESC             = "Ne pas accepter automatiquement les quetes grises (insignifiantes/bas niveau).",
    AUTOQUEST_CALLOUT                       = "Maintenez %s pour mettre en pause temporairement l'acceptation et le rendu automatiques.",
    AUTOQUEST_ADDON_BYPASS_NOTE             = "Note : d'autres addons d'automatisation de quetes (QuickQuest, Plumber, etc.) peuvent contourner la liste de blocage.",
    AUTOQUEST_ADD_NPC                       = "Ajouter le PNJ actuel a la liste de blocage",
    AUTOQUEST_ADD_NPC_DESC                  = "Parlez a un PNJ, puis cliquez sur ce bouton pour le bloquer dans l'automatisation des quetes.",
    AUTOQUEST_ZONE_FILTER                   = "Filtre de zone",
    AUTOQUEST_NPC_ZONE_FILTER_DESC          = "Filtrer les PNJ bloques par zone.",
    AUTOQUEST_QUEST_ZONE_FILTER_DESC        = "Filtrer les quetes bloquees par zone.",
    AUTOQUEST_ZONE_ALL                      = "Toutes les zones",
    AUTOQUEST_ZONE_CURRENT                  = "Zone actuelle",
    AUTOQUEST_BLOCKED_NPCS                  = "PNJ bloques (%d)",
    AUTOQUEST_NPC_EMPTY_ALL                 = "Aucun PNJ bloque pour l'instant -- ciblez un PNJ et cliquez sur le bouton ci-dessus pour en ajouter un.",
    AUTOQUEST_NPC_EMPTY_ZONE                = "Aucun PNJ bloque dans %s.",
    AUTOQUEST_REMOVE_NPC_DESC               = "Retirer %s de la liste de blocage.",
    AUTOQUEST_BLOCKED_QUESTS_HEADER         = "Quetes bloquees",
    AUTOQUEST_BLOCKED_QUESTS_NOTE           = "Les quetes bloquees ne seront pas automatiquement acceptees ou rendues.",
    AUTOQUEST_QUEST_EMPTY_ALL               = "Aucune quete bloquee pour l'instant -- les quetes auto-acceptees depuis des PNJ bloques apparaitront ici.",
    AUTOQUEST_QUEST_EMPTY_ZONE              = "Aucune quete bloquee dans %s.",
    AUTOQUEST_UNKNOWN_NPC                   = "PNJ inconnu",
    AUTOQUEST_QUEST_LABEL_WITH_ID           = "%s (ID: %s)",
    AUTOQUEST_QUEST_LABEL_ID_ONLY           = "Quest ID: %s",
    AUTOQUEST_UNBLOCK_DESC                  = "Debloquer cette quete.",
    AUTOQUEST_BLOCK_QUEST                   = "Bloquer la quete",
    AUTOQUEST_BLOCKED                       = "Bloque",
    AUTOQUEST_BLOCK_DESC                    = "Bloquer cette quete pour l'automatisation future.",
    AUTOQUEST_NPC_PREFIX                    = "PNJ : %s",
    AUTOQUEST_NO_AUTOMATED                  = "Aucune quete automatisee pour l'instant.",
    AUTOQUEST_RECENT_AUTOMATED              = "Quetes automatisees recentes (%d)",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoSell WidgetOptions
    ---------------------------------------------------------------------------

    AUTOSELL_ENABLE_DESC                    = "Activer ou desactiver Auto Sell.",
    AUTOSELL_SELL_GRAYS                     = "Vendre les objets gris",
    AUTOSELL_SELL_GRAYS_DESC                = "Vendre automatiquement tous les objets de qualite mediocre (gris).",
    AUTOSELL_CALLOUT                        = "Maintenez %s en ouvrant un marchand pour ignorer la vente automatique.",
    AUTOSELL_DRAG_DROP                      = "Glisser-deposer :",
    AUTOSELL_DRAG_GLOBAL_DESC               = "Glissez un objet de vos sacs et deposez-le ici pour l'ajouter a la liste de vente globale.",
    AUTOSELL_DRAG_CHAR_DESC                 = "Glissez un objet de vos sacs et deposez-le ici pour l'ajouter a la liste de vente de ce personnage.",
    AUTOSELL_ITEM_ID                        = "Item ID",
    AUTOSELL_ITEM_ID_GLOBAL_DESC            = "Entrez un Item ID pour l'ajouter a la liste de vente globale.",
    AUTOSELL_ITEM_ID_CHAR_DESC              = "Entrez un Item ID pour l'ajouter a la liste de vente de ce personnage.",
    AUTOSELL_REMOVE_DESC                    = "Retirer cet objet de la liste de vente.",
    AUTOSELL_GLOBAL_LIST                    = "Liste de vente globale (%d)",
    AUTOSELL_CHAR_LIST                      = "Liste de vente de %s (%d)",
    AUTOSELL_CHAR_ONLY_NOTE                 = "Les objets de cette liste ne sont vendus que sur ce personnage.",
    AUTOSELL_EMPTY_GLOBAL                   = "Aucun objet dans la liste de vente globale.",
    AUTOSELL_EMPTY_CHAR                     = "Aucun objet dans la liste de vente du personnage.",

    ---------------------------------------------------------------------------
    -- Phase 3: CursorRing WidgetOptions
    ---------------------------------------------------------------------------

    CURSORRING_ENABLE_DESC                  = "Activer ou desactiver le module Cursor Ring & Trail.",
    CURSORRING_PREVIEW_START                = "Demarrer l'apercu",
    CURSORRING_PREVIEW_STOP                 = "Arreter l'apercu",
    CURSORRING_PREVIEW_DESC                 = "Afficher tous les elements visuels sur le curseur pour un reglage en temps reel. Se desactive automatiquement a la fermeture du panneau de parametres.",
    CURSORRING_GROUP_GENERAL                = "General",
    CURSORRING_SHOW_OOC                     = "Afficher hors combat",
    CURSORRING_SHOW_OOC_DESC                = "Afficher l'anneau du curseur en dehors du combat et des instances.",
    CURSORRING_COMBAT_OPACITY               = "Opacite en combat",
    CURSORRING_COMBAT_OPACITY_DESC          = "Opacite de l'anneau en combat ou en instance.",
    CURSORRING_OOC_OPACITY                  = "Opacite hors combat",
    CURSORRING_OOC_OPACITY_DESC             = "Opacite de l'anneau hors combat.",
    CURSORRING_GROUP_RING1                  = "Anneau 1 (Exterieur)",
    CURSORRING_ENABLE_RING1                 = "Activer l'anneau 1",
    CURSORRING_ENABLE_RING1_DESC            = "Afficher l'anneau exterieur.",
    CURSORRING_SHAPE                        = "Forme",
    CURSORRING_RING_SHAPE_DESC              = "Forme de l'anneau.",
    CURSORRING_SHwPE_CIRCLE                 = "Cercle",
    CURSORRING_SHAPE_THIN                   = "Cercle fin",
    CURSORRING_COLOR                        = "Couleur",
    CURSORRING_RING1_COLOR_DESC             = "Couleur de l'anneau 1.",
    CURSORRING_SIZE                         = "Taille",
    CURSORRING_RING1_SIZE_DESC              = "Taille de l'anneau 1 en pixels.",
    CURSORRING_GROUP_RING2                  = "Anneau 2 (Interieur)",
    CURSORRING_ENABLE_RING2                 = "Activer l'anneau 2",
    CURSORRING_ENABLE_RING2_DESC            = "Afficher l'anneau interieur.",
    CURSORRING_RING2_COLOR_DESC             = "Couleur de l'anneau 2.",
    CURSORRING_RING2_SIZE_DESC              = "Taille de l'anneau 2 en pixels.",
    CURSORRING_GROUP_DOT                    = "Point central",
    CURSORRING_ENABLE_DOT                   = "Activer le point",
    CURSORRING_ENABLE_DOT_DESC              = "Afficher un petit point au centre des anneaux du curseur.",
    CURSORRING_DOT_COLOR_DESC               = "Couleur du point.",
    CURSORRING_DOT_SIZE_DESC                = "Taille du point en pixels.",
    CURSORRING_GROUP_CAST                   = "Effet d'incantation",
    CURSORRING_ENABLE_CAST                  = "Activer l'effet d'incantation",
    CURSORRING_ENABLE_CAST_DESC             = "Afficher un effet visuel pendant l'incantation et la canalisation de sorts.",
    CURSORRING_STYLE                        = "Style",
    CURSORRING_CAST_STYLE_DESC              = "Segments : l'arc s'illumine progressivement. Remplissage : la forme s'agrandit depuis le centre. Balayage : effet de recharge (peut s'executer en meme temps que le GCD).",
    CURSORRING_STYLE_SEGMENTS               = "Segments",
    CURSORRING_STYLE_FILL                   = "Remplissage",
    CURSORRING_STYLE_SWIPE                  = "Balayage",
    CURSORRING_CAST_COLOR_DESC              = "Couleur de l'effet d'incantation.",
    CURSORRING_SWIPE_OFFSET                 = "Decalage du balayage",
    CURSORRING_SWIPE_OFFSET_DESC            = "Decalage en pixels de l'anneau de balayage d'incantation par rapport a l'anneau GCD. S'applique uniquement au style Balayage.",
    CURSORRING_GROUP_GCD                    = "Indicateur de GCD",
    CURSORRING_ENABLE_GCD                   = "Activer le GCD",
    CURSORRING_ENABLE_GCD_DESC              = "Afficher un balayage de recharge pour le temps de recharge global.",
    CURSORRING_GCD_COLOR_DESC               = "Couleur du balayage GCD.",
    CURSORRING_OFFSET                       = "Decalage",
    CURSORRING_GCD_OFFSET_DESC              = "Decalage en pixels de l'anneau GCD par rapport a l'anneau 1.",
    CURSORRING_GROUP_TRAIL                  = "Trainee de souris",
    CURSORRING_ENABLE_TRAIL                 = "Activer la trainee",
    CURSORRING_ENABLE_TRAIL_DESC            = "Afficher une trainee qui s'estompe derriere le curseur.",
    CURSORRING_TRAIL_STYLE_DESC             = "Style d'affichage de la trainee. Lueur : trainee scintillante qui s'estompe. Ligne : ruban fin continu. Ligne epaisse : ruban large. Points : points espaces qui s'estompent. Personnalise : reglages manuels.",
    CURSORRING_TRAIL_GLOW                   = "Lueur",
    CURSORRING_TRAIL_LINE                   = "Ligne",
    CURSORRING_TRAIL_THICKLINE              = "Ligne epaisse",
    CURSORRING_TRAIL_DOTS                   = "Points",
    CURSORRING_TRAIL_CUSTOM                 = "Personnalise",
    CURSORRING_TRAIL_COLOR_DESC             = "Couleur predefinie de la trainee. Couleur de classe utilise automatiquement la couleur de votre classe. Arc-en-ciel, Braise et Ocean sont des degrades multicolores. Personnalise vous permet de choisir une couleur ci-dessous.",
    CURSORRING_TRAIL_COLOR_CUSTOM           = "Personnalise",
    CURSORRING_TRAIL_COLOR_CLASS            = "Couleur de classe",
    CURSORRING_TRAIL_COLOR_GOLD             = "Or Lantern",
    CURSORRING_TRAIL_COLOR_ARCANE           = "Arcane",
    CURSORRING_TRAIL_COLOR_FEL              = "Gangrene",
    CURSORRING_TRAIL_COLOR_FIRE             = "Feu",
    CURSORRING_TRAIL_COLOR_FROST            = "Givre",
    CURSORRING_TRAIL_COLOR_HOLY             = "Sacre",
    CURSORRING_TRAIL_COLOR_SHADOW           = "Ombre",
    CURSORRING_TRAIL_COLOR_RAINBOW          = "Arc-en-ciel",
    CURSORRING_TRAIL_COLOR_ALAR             = "Al'ar",
    CURSORRING_TRAIL_COLOR_EMBER            = "Braise",
    CURSORRING_TRAIL_COLOR_OCEAN            = "Ocean",
    CURSORRING_CUSTOM_COLOR                 = "Couleur personnalisee",
    CURSORRING_CUSTOM_COLOR_DESC            = "Couleur de la trainee (utilisee uniquement quand la couleur est sur Personnalise).",
    CURSORRING_DURATION                     = "Duree",
    CURSORRING_DURATION_DESC                = "Duree de vie des points de trainee avant de s'estomper.",
    CURSORRING_MAX_POINTS                   = "Points maximum",
    CURSORRING_MAX_POINTS_DESC              = "Nombre de points de trainee dans le pool. Des valeurs plus elevees creent des trainees plus longues mais utilisent plus de memoire.",
    CURSORRING_DOT_SIZE                     = "Taille des points",
    CURSORRING_DOT_SIZE_TRAIL_DESC          = "Taille de chaque point de trainee en pixels.",
    CURSORRING_DOT_SPACING                  = "Espacement des points",
    CURSORRING_DOT_SPACING_DESC             = "Distance minimale en pixels avant de placer un nouveau point de trainee. Des valeurs plus basses creent une trainee plus dense et continue.",
    CURSORRING_SHRINK_AGE                   = "Retrecir avec le temps",
    CURSORRING_SHRINK_AGE_DESC              = "Les points de trainee retrecissent en s'estompant. Desactivez pour une trainee de largeur uniforme.",
    CURSORRING_TAPER_DISTANCE               = "Effiler avec la distance",
    CURSORRING_TAPER_DISTANCE_DESC          = "Les points de trainee retrecissent et s'estompent vers l'extremite, creant un effet de coup de pinceau effile.",
    CURSORRING_SPARKLE                      = "Scintillement",
    CURSORRING_SPARKLE_DESC                 = "Ajoute de petites particules scintillantes le long de la trainee lorsque vous deplacez le curseur.",
    CURSORRING_SPARKLE_OFF                  = "Desactive",
    CURSORRING_SPARKLE_STATIC               = "Statique",
    CURSORRING_SPARKLE_TWINKLE              = "Clignotant",
    CURSORRING_TRAIL_PERF_NOTE              = "La trainee s'execute a chaque image. Plus de points, de scintillements et d'effets consommeront plus de CPU.",

    ---------------------------------------------------------------------------
    -- Phase 3: MissingPet WidgetOptions
    ---------------------------------------------------------------------------

    MISSINGPET_ENABLE_DESC                  = "Activer ou desactiver l'avertissement Missing Pet.",
    MISSINGPET_GROUP_WARNING                = "Parametres d'avertissement",
    MISSINGPET_SHOW_MISSING                 = "Avertissement familier absent",
    MISSINGPET_SHOW_MISSING_DESC            = "Afficher un avertissement quand votre familier est renvoye ou mort.",
    MISSINGPET_SHOW_PASSIVE                 = "Avertissement familier passif",
    MISSINGPET_SHOW_PASSIVE_DESC            = "Afficher un avertissement quand votre familier est en mode passif.",
    MISSINGPET_MISSING_TEXT                 = "Texte d'absence",
    MISSINGPET_MISSING_TEXT_DESC            = "Texte a afficher quand votre familier est absent.",
    MISSINGPET_PASSIVE_TEXT                 = "Texte de passif",
    MISSINGPET_PASSIVE_TEXT_DESC            = "Texte a afficher quand votre familier est en mode passif.",
    MISSINGPET_MISSING_COLOR                = "Couleur d'absence",
    MISSINGPET_MISSING_COLOR_DESC           = "Couleur du texte d'avertissement de familier absent.",
    MISSINGPET_PASSIVE_COLOR                = "Couleur de passif",
    MISSINGPET_PASSIVE_COLOR_DESC           = "Couleur du texte d'avertissement de familier passif.",
    MISSINGPET_ANIMATION_DESC               = "Choisir comment le texte d'avertissement s'anime.",
    MISSINGPET_GROUP_FONT                   = "Parametres de police",
    MISSINGPET_FONT_DESC                    = "Selectionner la police du texte d'avertissement.",
    MISSINGPET_FONT_SIZE_DESC               = "Taille du texte d'avertissement.",
    MISSINGPET_FONT_OUTLINE_DESC            = "Style de contour du texte d'avertissement.",
    MISSINGPET_LOCK_POSITION_DESC           = "Empecher le deplacement de l'avertissement.",
    MISSINGPET_RESET_POSITION_DESC          = "Reinitialiser la position de l'avertissement au centre de l'ecran.",
    MISSINGPET_GROUP_VISIBILITY             = "Visibilite",
    MISSINGPET_HIDE_MOUNTED                 = "Masquer sur monture",
    MISSINGPET_HIDE_MOUNTED_DESC            = "Masquer l'avertissement sur une monture, en taxi ou dans un vehicule.",
    MISSINGPET_HIDE_REST                    = "Masquer en zone de repos",
    MISSINGPET_HIDE_REST_DESC               = "Masquer l'avertissement dans les zones de repos (villes et auberges).",
    MISSINGPET_DISMOUNT_DELAY               = "Delai apres demontage",
    MISSINGPET_DISMOUNT_DELAY_DESC          = "Secondes a attendre apres avoir demonte avant d'afficher l'avertissement. Mettre a 0 pour afficher immediatement.",
    MISSINGPET_PLAY_SOUND_DESC              = "Jouer un son quand l'avertissement est affiche.",
    MISSINGPET_SOUND_MISSING                = "Son quand absent",
    MISSINGPET_SOUND_MISSING_DESC           = "Jouer un son quand le familier est absent.",
    MISSINGPET_SOUND_PASSIVE                = "Son quand passif",
    MISSINGPET_SOUND_PASSIVE_DESC           = "Jouer un son quand le familier est en mode passif.",
    MISSINGPET_SOUND_COMBAT                 = "Son en combat",
    MISSINGPET_SOUND_COMBAT_DESC            = "Continuer a jouer le son en combat. Si desactive, le son s'arrete au debut du combat.",
    MISSINGPET_SOUND_REPEAT                 = "Repeter le son",
    MISSINGPET_SOUND_REPEAT_DESC            = "Repeter le son a intervalles reguliers tant que l'avertissement est affiche.",
    MISSINGPET_SOUND_SELECT_DESC            = "Selectionner le son a jouer. Cliquez sur l'icone de haut-parleur pour un apercu.",
    MISSINGPET_REPEAT_INTERVAL              = "Intervalle de repetition",
    MISSINGPET_REPEAT_INTERVAL_DESC         = "Secondes entre les repetitions du son.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatAlert WidgetOptions
    ---------------------------------------------------------------------------

    COMBATALERT_ENABLE_DESC                 = "Afficher des alertes textuelles a l'entree/sortie du combat.",
    COMBATALERT_PREVIEW_DESC                = "Afficher en boucle les alertes d'entree/sortie a l'ecran pour un reglage en temps reel. Se desactive automatiquement a la fermeture du panneau de parametres.",
    COMBATALERT_GROUP_ENTER                 = "Entree en combat",
    COMBATALERT_SHOW_ENTER                  = "Afficher l'alerte d'entree",
    COMBATALERT_SHOW_ENTER_DESC             = "Afficher une alerte a l'entree en combat.",
    COMBATALERT_ENTER_TEXT                   = "Texte d'entree",
    COMBATALERT_ENTER_TEXT_DESC             = "Texte affiche a l'entree en combat.",
    COMBATALERT_ENTER_COLOR                 = "Couleur d'entree",
    COMBATALERT_ENTER_COLOR_DESC            = "Couleur du texte d'entree en combat.",
    COMBATALERT_GROUP_LEAVE                 = "Sortie de combat",
    COMBATALERT_SHOW_LEAVE                  = "Afficher l'alerte de sortie",
    COMBATALERT_SHOW_LEAVE_DESC             = "Afficher une alerte a la sortie du combat.",
    COMBATALERT_LEAVE_TEXT                   = "Texte de sortie",
    COMBATALERT_LEAVE_TEXT_DESC             = "Texte affiche a la sortie du combat.",
    COMBATALERT_LEAVE_COLOR                 = "Couleur de sortie",
    COMBATALERT_LEAVE_COLOR_DESC            = "Couleur du texte de sortie de combat.",
    COMBATALERT_GROUP_FONT                  = "Parametres de police et d'affichage",
    COMBATALERT_FONT_DESC                   = "Selectionner la police du texte d'alerte.",
    COMBATALERT_FONT_SIZE_DESC              = "Taille du texte d'alerte.",
    COMBATALERT_FONT_OUTLINE_DESC           = "Style de contour du texte d'alerte.",
    COMBATALERT_FADE_DURATION               = "Duree du fondu",
    COMBATALERT_FADE_DURATION_DESC          = "Duree totale de l'alerte (maintien + fondu sortant) en secondes.",
    COMBATALERT_PLAY_SOUND_DESC             = "Jouer un son quand l'alerte est affichee.",
    COMBATALERT_SOUND_SELECT_DESC           = "Selectionner le son a jouer.",
    COMBATALERT_LOCK_POSITION_DESC          = "Empecher le deplacement de l'alerte.",
    COMBATALERT_RESET_POSITION_DESC         = "Reinitialiser l'alerte a sa position par defaut.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatTimer WidgetOptions
    ---------------------------------------------------------------------------

    COMBATTIMER_ENABLE_DESC                 = "Afficher un chronometre pendant le combat.",
    COMBATTIMER_PREVIEW_DESC                = "Afficher le chronometre a l'ecran pour un reglage en temps reel. Se desactive automatiquement a la fermeture du panneau de parametres.",
    COMBATTIMER_FONT_DESC                   = "Selectionner la police du chronometre.",
    COMBATTIMER_FONT_SIZE_DESC              = "Taille du texte du chronometre.",
    COMBATTIMER_FONT_OUTLINE_DESC           = "Style de contour du texte du chronometre.",
    COMBATTIMER_FONT_COLOR_DESC             = "Couleur du texte du chronometre.",
    COMBATTIMER_STICKY_DURATION             = "Duree de persistance",
    COMBATTIMER_STICKY_DURATION_DESC        = "Secondes pendant lesquelles le temps final reste affiche apres la fin du combat. Mettre a 0 pour masquer immediatement.",
    COMBATTIMER_LOCK_POSITION_DESC          = "Empecher le deplacement du chronometre.",
    COMBATTIMER_RESET_POSITION_DESC         = "Reinitialiser le chronometre a sa position par defaut.",

    ---------------------------------------------------------------------------
    -- Phase 3: RangeCheck WidgetOptions
    ---------------------------------------------------------------------------

    RANGECHECK_ENABLE_DESC                  = "Afficher si votre cible actuelle est a portee ou hors de portee.",
    RANGECHECK_HIDE_IN_RANGE                = "Masquer si a portee",
    RANGECHECK_HIDE_IN_RANGE_DESC           = "Masquer l'affichage quand votre cible est a portee. N'affiche que lorsqu'elle est hors de portee.",
    RANGECHECK_COMBAT_ONLY                  = "Combat uniquement",
    RANGECHECK_COMBAT_ONLY_DESC             = "N'afficher la portee qu'en combat.",
    RANGECHECK_GROUP_STATUS                 = "Texte de statut",
    RANGECHECK_IN_RANGE_TEXT                = "Texte a portee",
    RANGECHECK_IN_RANGE_TEXT_DESC           = "Texte a afficher quand votre cible est a portee.",
    RANGECHECK_OUT_OF_RANGE_TEXT            = "Texte hors de portee",
    RANGECHECK_OUT_OF_RANGE_TEXT_DESC       = "Texte a afficher quand votre cible est hors de portee.",
    RANGECHECK_IN_RANGE_COLOR               = "Couleur a portee",
    RANGECHECK_IN_RANGE_COLOR_DESC          = "Couleur du texte a portee.",
    RANGECHECK_OUT_OF_RANGE_COLOR           = "Couleur hors de portee",
    RANGECHECK_OUT_OF_RANGE_COLOR_DESC      = "Couleur du texte hors de portee.",
    RANGECHECK_ANIMATION_DESC               = "Choisir comment le texte de statut s'anime au changement d'etat.",
    RANGECHECK_FONT_DESC                    = "Selectionner la police du texte de portee.",
    RANGECHECK_FONT_SIZE_DESC               = "Taille du texte de portee.",
    RANGECHECK_FONT_OUTLINE_DESC            = "Style de contour du texte de portee.",
    RANGECHECK_LOCK_POSITION_DESC           = "Empecher le deplacement de l'affichage de portee.",
    RANGECHECK_RESET_POSITION_DESC          = "Reinitialiser l'affichage de portee a sa position par defaut.",

    ---------------------------------------------------------------------------
    -- Phase 3: ChatFilter WidgetOptions
    ---------------------------------------------------------------------------

    CHATFILTER_ENABLE_DESC                  = "Activer ou desactiver le filtre de chat.",
    CHATFILTER_LOGIN_MESSAGE                = "Message de connexion",
    CHATFILTER_LOGIN_MESSAGE_DESC           = "Afficher un message dans le chat a la connexion confirmant que le filtre est actif.",
    CHATFILTER_ADD_KEYWORD                  = "Ajouter un mot-cle",
    CHATFILTER_ADD_KEYWORD_DESC             = "Entrez un mot ou une expression a filtrer. La correspondance est insensible a la casse.",
    CHATFILTER_KEYWORDS_GROUP               = "Mots-cles (%d)",
    CHATFILTER_NO_KEYWORDS                  = "Aucun mot-cle configure.",
    CHATFILTER_REMOVE_KEYWORD_DESC          = "Retirer \"%s\" de la liste de filtres.",
    CHATFILTER_RESTORE_DEFAULTS             = "Restaurer les mots-cles par defaut",
    CHATFILTER_RESTORE_DEFAULTS_DESC        = "Reinitialiser la liste de mots-cles aux valeurs par defaut. Cela remplace tous les mots-cles personnalises.",
    CHATFILTER_RESTORE_CONFIRM              = "Restaurer ?",

    ---------------------------------------------------------------------------
    -- Phase 3: Tooltip WidgetOptions
    ---------------------------------------------------------------------------

    TOOLTIP_ENABLE_DESC                     = "Ameliorer les infobulles avec des informations supplementaires.",
    TOOLTIP_GROUP_PLAYER                    = "Joueur",
    TOOLTIP_MOUNT_NAME                      = "Nom de la monture",
    TOOLTIP_MOUNT_NAME_DESC                 = "Afficher la monture actuellement utilisee par un joueur.",
    TOOLTIP_GROUP_ITEMS                     = "Objets",
    TOOLTIP_ITEM_ID                         = "Item ID",
    TOOLTIP_ITEM_ID_DESC                    = "Afficher l'Item ID dans les infobulles d'objets.",
    TOOLTIP_ITEM_SPELL_ID                   = "Item Spell ID",
    TOOLTIP_ITEM_SPELL_ID_DESC              = "Afficher le Spell ID de l'effet d'utilisation sur les consommables et autres objets a effet actif.",
    TOOLTIP_GROUP_SPELLS                    = "Sorts",
    TOOLTIP_SPELL_ID                        = "Spell ID",
    TOOLTIP_SPELL_ID_DESC                   = "Afficher le Spell ID dans les infobulles de sorts, d'auras et de talents.",
    TOOLTIP_NODE_ID                         = "Node ID",
    TOOLTIP_NODE_ID_DESC                    = "Afficher le Node ID de l'arbre de talents dans les infobulles de talents.",
    TOOLTIP_GROUP_COPY                      = "Copie",
    TOOLTIP_CTRL_C                          = "Ctrl+C pour copier",
    TOOLTIP_CTRL_C_DESC                     = "Appuyez sur Ctrl+C pour copier l'ID principal, ou Ctrl+Shift+C pour copier l'ID secondaire (par ex. le Spell ID d'utilisation d'un objet).",
    TOOLTIP_COMBAT_NOTE                     = "Les ameliorations d'infobulles sont desactivees en instance. Le scan de monture et la copie Ctrl+C sont desactives en combat.",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoPlaystyle WidgetOptions
    ---------------------------------------------------------------------------

    AUTOPLAYSTYLE_ENABLE_DESC               = "Selection automatique du style de jeu lors de la creation de groupes M+.",
    AUTOPLAYSTYLE_PLAYSTYLE                 = "Style de jeu",
    AUTOPLAYSTYLE_PLAYSTYLE_DESC            = "Selectionne automatiquement ce style de jeu a l'ouverture de la fenetre de creation de groupe M+ dans l'outil de recherche de groupe.",

    ---------------------------------------------------------------------------
    -- Shared: Font outline values (used across multiple modules)
    ---------------------------------------------------------------------------

    FONT_OUTLINE_NONE                       = "Aucun",
    FONT_OUTLINE_OUTLINE                    = "Contour",
    FONT_OUTLINE_THICK                      = "Contour epais",
    FONT_OUTLINE_MONO                       = "Monochrome",
    FONT_OUTLINE_OUTLINE_MONO              = "Contour + Mono",

    ---------------------------------------------------------------------------
    -- Shared: Animation values (used across MissingPet, RangeCheck)
    ---------------------------------------------------------------------------

    ANIMATION_NONE                          = "Aucune (statique)",
    ANIMATION_BOUNCE                        = "Rebond",
    ANIMATION_PULSE                         = "Pulsation",
    ANIMATION_FADE                          = "Fondu",
    ANIMATION_SHAKE                         = "Secousse",
    ANIMATION_GLOW                          = "Lueur",
    ANIMATION_HEARTBEAT                     = "Battement",

    ---------------------------------------------------------------------------
    -- Shared: Confirm/Remove labels
    ---------------------------------------------------------------------------

    SHARED_REMOVE                           = "Retirer",
    SHARED_REMOVE_CONFIRM                   = "Retirer ?",

    ---------------------------------------------------------------------------
    -- Tooltip: in-game tooltip hint lines
    ---------------------------------------------------------------------------

    TOOLTIP_HINT_COPY                       = "Ctrl+C pour copier",
    TOOLTIP_HINT_COPY_BOTH                  = "Ctrl+C ItemID  |  Ctrl+Shift+C SpellID",
    TOOLTIP_COPY_HINT                       = "Ctrl+C pour copier, Esc pour fermer",
});
