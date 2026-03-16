local ADDON_NAME, Lantern = ...;
Lantern:RegisterLocale("ptBR", {

    -- Shared
    ENABLE                                  = "Ativar",
    MODULE_ENABLE_DESC                      = "Ativar ou desativar %s.",
    SHARED_FONT                             = "Fonte",
    SHARED_FONT_SIZE                        = "Tamanho da Fonte",
    SHARED_FONT_OUTLINE                     = "Contorno da Fonte",
    SHARED_FONT_COLOR                       = "Cor da Fonte",
    SHARED_GROUP_POSITION                   = "Posicao",
    SHARED_LOCK_POSITION                    = "Travar Posicao",
    SHARED_RESET_POSITION                   = "Redefinir Posicao",
    SHARED_GROUP_SOUND                      = "Som",
    SHARED_SOUND_SELECT                     = "Som",
    SHARED_PLAY_SOUND                       = "Tocar Som",
    SHARED_PREVIEW                          = "Visualizar",
    SHARED_GROUP_DISPLAY                    = "Exibicao",
    SHARED_ANIMATION_STYLE                  = "Estilo de Animacao",
    SHARED_SHOW_CHAT_MESSAGE                = "Mostrar mensagem no chat",

    -- General settings
    GENERAL_MINIMAP_SHOW                    = "Mostrar icone no minimapa",
    GENERAL_MINIMAP_SHOW_DESC               = "Mostrar ou ocultar o botao do Lantern no minimapa.",
    GENERAL_MINIMAP_MODERN                  = "Icone moderno no minimapa",
    GENERAL_MINIMAP_MODERN_DESC             = "Remove a borda e o fundo do botao do minimapa para um visual moderno com brilho ao passar o mouse.",
    GENERAL_AUTO_ENABLE_NEW                 = "Ativar novos recursos automaticamente",
    GENERAL_AUTO_ENABLE_NEW_DESC            = "Ativar automaticamente modulos recem-adicionados. Quando desativado, novos modulos comecam desativados e devem ser ativados manualmente.",
    GENERAL_PAUSE_MODIFIER                  = "Tecla modificadora de pausa",
    GENERAL_PAUSE_MODIFIER_DESC             = "Segure esta tecla para pausar temporariamente recursos automaticos (Auto Quest, Auto Queue, Auto Repair, etc.).",

    -- Minimap button actions
    MINIMAP_CLICKS_HEADER                   = "Acoes do botao do minimapa",
    MINIMAP_CLICK_LEFT                      = "Clique esquerdo",
    MINIMAP_CLICK_SHIFT_LEFT                = "Shift + Clique esquerdo",
    MINIMAP_CLICK_CTRL_LEFT                 = "Ctrl + Clique esquerdo",
    MINIMAP_CLICK_RIGHT                     = "Clique direito",
    MINIMAP_CLICK_SHIFT_RIGHT               = "Shift + Clique direito",
    MINIMAP_CLICK_CTRL_RIGHT                = "Ctrl + Clique direito",
    MINIMAP_ACTION_SETTINGS                 = "Configuracoes do Lantern",
    MINIMAP_ACTION_CRAFTING                 = "Abrir analise CO",
    MINIMAP_ACTION_WARBAND                  = "Warband",
    MINIMAP_ACTION_SPELLBOOK                = "Livro de feiticos",
    MINIMAP_ACTION_TALENTS                  = "Talentos",
    MINIMAP_ACTION_COLLECTIONS              = "Colecoes",
    MINIMAP_ACTION_GROUP_FINDER             = "Localizador de grupo",
    MINIMAP_ACTION_COMMUNITIES              = "Guilda / Comunidades",
    MINIMAP_ACTION_WORLD_MAP                = "Mapa-mundi",
    MINIMAP_ACTION_ACHIEVEMENTS             = "Conquistas",
    MINIMAP_ACTION_CALENDAR                 = "Calendario",
    MINIMAP_ACTION_EDIT_MODE                = "Modo de edicao",
    MINIMAP_ACTION_RELOAD                   = "Recarregar IU",
    MINIMAP_ACTION_SLASH                    = "Comando de barra",
    MINIMAP_ACTION_NONE                     = "Nada",
    MINIMAP_SLASH_PLACEHOLDER               = "ex. /reload",
    MINIMAP_NO_SETTINGS_HINT                = "Voce sempre pode abrir as configuracoes do Lantern digitando /lantern",

    -- Modifier values (used in dropdowns)
    MODIFIER_SHIFT                          = "Shift",
    MODIFIER_CTRL                           = "Ctrl",
    MODIFIER_ALT                            = "Alt",

    -- Delete Confirm
    DELETECONFIRM_ENABLE_DESC               = "Substituir a digitacao de DELETE por um botao de confirmacao (Shift pausa).",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_ENABLE_DESC              = "Impedir que feiticos sejam adicionados automaticamente a barra de acoes.",

    -- Auto Queue
    AUTOQUEUE_AUTO_ACCEPT                   = "Aceitar verificacoes de papel automaticamente",
    AUTOQUEUE_AUTO_ACCEPT_DESC              = "Aceitar verificacoes de papel do LFG automaticamente.",
    AUTOQUEUE_AUTO_ACCEPT_INVITE            = "Aceitar convites de grupo automaticamente",
    AUTOQUEUE_AUTO_ACCEPT_INVITE_DESC       = "Aceitar automaticamente convites do Localizador de Grupo quando sua candidatura e aceita.",
    AUTOQUEUE_ONE_CLICK_SIGNUP              = "Inscricao com um clique",
    AUTOQUEUE_ONE_CLICK_SIGNUP_DESC         = "Pular o dialogo de papel/nota ao se candidatar a grupos no Localizador de Grupo.",
    AUTOQUEUE_ANNOUNCE_DESC                 = "Mostrar uma mensagem no chat quando uma acao automatica e realizada.",
    AUTOQUEUE_CALLOUT                       = "Segure %s para pausar temporariamente. Os papeis sao definidos na ferramenta LFG.",

    -- Faster Loot
    FASTERLOOT_ENABLE_DESC                  = "Coletar todo o saque instantaneamente ao abrir a janela de saque. Segure %s para pausar.",

    -- Auto Keystone
    AUTOKEYSTONE_ENABLE_DESC                = "Inserir automaticamente sua pedra angular ao abrir a IU de M+. Segure %s para pular.",

    -- Release Protection
    RELEASEPROTECT_ENABLE_DESC              = "Exigir segurar %s para liberar o espirito (previne liberacao acidental).",
    RELEASEPROTECT_SKIP_SOLO                = "Pular quando sozinho",
    RELEASEPROTECT_SKIP_SOLO_DESC           = "Desativar a protecao quando voce nao esta em um grupo.",
    RELEASEPROTECT_ACTIVE_IN                = "Ativo em",
    RELEASEPROTECT_ACTIVE_IN_DESC           = "Sempre: protecao em todos os lugares. Todas as instancias: apenas dentro de masmorras, raides e PvP. Personalizado: escolha tipos de instancia especificos.",
    RELEASEPROTECT_MODE_ALWAYS              = "Sempre",
    RELEASEPROTECT_MODE_INSTANCES           = "Todas as instancias",
    RELEASEPROTECT_MODE_CUSTOM              = "Personalizado",
    RELEASEPROTECT_HOLD_DURATION            = "Duracao de segurar",
    RELEASEPROTECT_HOLD_DURATION_DESC       = "Quanto tempo voce precisa segurar a tecla modificadora antes que o botao de liberar fique ativo.",
    RELEASEPROTECT_INSTANCE_TYPES           = "Tipos de Instancia",
    RELEASEPROTECT_OPEN_WORLD               = "Mundo Aberto",
    RELEASEPROTECT_OPEN_WORLD_DESC          = "Proteger no mundo aberto (fora de qualquer instancia).",
    RELEASEPROTECT_DUNGEONS                 = "Masmorras",
    RELEASEPROTECT_DUNGEONS_DESC            = "Proteger em masmorras normais, heroicas e miticas.",
    RELEASEPROTECT_MYTHICPLUS               = "Mitico+",
    RELEASEPROTECT_MYTHICPLUS_DESC          = "Proteger em pedras angulares Mitico+.",
    RELEASEPROTECT_RAIDS                    = "Raides",
    RELEASEPROTECT_RAIDS_DESC               = "Proteger em todas as dificuldades de raide (LFR, Normal, Heroico, Mitico).",
    RELEASEPROTECT_SCENARIOS                = "Cenarios",
    RELEASEPROTECT_SCENARIOS_DESC           = "Proteger em instancias de cenario.",
    RELEASEPROTECT_DELVES                   = "Incursoes",
    RELEASEPROTECT_DELVES_DESC              = "Proteger em Incursoes.",
    RELEASEPROTECT_ARENAS                   = "Arenas",
    RELEASEPROTECT_ARENAS_DESC              = "Proteger em arenas PvP.",
    RELEASEPROTECT_BATTLEGROUNDS            = "Campos de Batalha",
    RELEASEPROTECT_BATTLEGROUNDS_DESC       = "Proteger em campos de batalha PvP.",

    -- Auto Repair
    AUTOREPAIR_SOURCE                       = "Fonte de reparo",
    AUTOREPAIR_SOURCE_DESC                  = "Ouro pessoal: sempre usar seu proprio ouro. Fundos da guilda primeiro: tentar banco da guilda, recorrer ao pessoal. Apenas fundos da guilda: usar apenas o banco da guilda (avisa se indisponivel).",
    AUTOREPAIR_SOURCE_PERSONAL              = "Ouro pessoal",
    AUTOREPAIR_SOURCE_GUILD_FIRST           = "Fundos da guilda primeiro",
    AUTOREPAIR_SOURCE_GUILD_ONLY            = "Apenas fundos da guilda",
    AUTOREPAIR_SHOW_MESSAGE_DESC            = "Mostrar uma mensagem no chat quando o equipamento e reparado automaticamente.",
    AUTOREPAIR_CALLOUT                      = "Segure %s ao abrir um vendedor para pular o reparo automatico.",

    -- Splash page
    SPLASH_DESC                             = "Um addon modular de qualidade de vida para World of Warcraft.\nClique no nome de um modulo para configura-lo, ou clique no indicador de status para ativa-lo/desativa-lo.",
    SPLASH_ENABLED                          = "Ativado",
    SPLASH_DISABLED                         = "Desativado",
    SPLASH_CLICK_ENABLE                     = "Clique para ativar",
    SPLASH_CLICK_DISABLE                    = "Clique para desativar",
    SPLASH_COMPANION_HEADER                 = "Addons Complementares",
    SPLASH_CURSEFORGE                       = "CurseForge",
    SPLASH_COPY_LINK                        = "Copiar link",
    SPLASH_COPY_HINT                        = "Ctrl+C para copiar, Escape para fechar",
    SPLASH_CREDITS_HEADER                   = "Creditos",
    SPLASH_CREDITS                          = "Agradecimento especial a @imhavingfun pelos testes e relatorios de bugs.",
    COPY                                    = "Copiar",
    SELECT                                  = "Selecionar",

    -- Companion addon descriptions
    COMPANION_CO_LABEL                      = "Crafting Orders",
    COMPANION_CO_DESC                       = "Anuncia atividade de ordens da guilda, alertas de ordens pessoais e um botao de Completar + Sussurrar.",
    COMPANION_WARBAND_LABEL                 = "Warband",
    COMPANION_WARBAND_DESC                  = "Organize personagens em grupos com balanceamento automatico de ouro para/do banco de guerra ao abrir um banco.",

    -- Section headers
    SECTION_MODULES                         = "Modulos",
    SECTION_ADDONS                          = "Addons",

    -- General settings page
    SECTION_GENERAL                         = "Geral",
    SECTION_GENERAL_DESC                    = "Configuracoes principais do addon.",

    -- Sidebar page labels
    PAGE_HOME                               = "Inicio",

    -- Category headers
    CATEGORY_GENERAL                        = "Geral",
    CATEGORY_DUNGEONS                       = "Masmorras e M+",
    CATEGORY_MYTHICPLUS                     = "Mitico+",
    CATEGORY_MAP                            = "Mapa",
    CATEGORY_QUESTING                       = "Missoes e Mundo",

    -- Messages (Options.lua / ui.lua)
    MSG_OPTIONS_AFTER_COMBAT                = "Opcoes serao abertas apos o combate.",

    -- ui.lua: Minimap tooltip
    UI_MINIMAP_TITLE                        = "Lantern",

    -- ui.lua: StaticPopup link dialog
    UI_COPY_LINK_PROMPT                     = "CTRL-C para copiar o link",

    -- ui.lua: Blizzard Settings stub
    UI_SETTINGS_VERSION                     = "Versao: %s",
    UI_SETTINGS_AUTHOR                      = "Autor: Dede no jogo / Sponsorn no CurseForge e GitHub",
    UI_SETTINGS_THANKS                      = "Agradecimentos especiais aos copyrighters por me fazerem tomar uma atitude.",
    UI_SETTINGS_OPEN                        = "Abrir Configuracoes",
    UI_SETTINGS_AVAILABLE_MODULES           = "Modulos disponiveis",
    UI_SETTINGS_CO_DESC                     = "Crafting Orders: anuncia atividade de ordens da guilda, alertas de ordens pessoais e um botao de Completar + Sussurrar.",
    UI_SETTINGS_ALREADY_ENABLED             = "Ja ativado",
    UI_SETTINGS_WARBAND_DESC                = "Warband: organize personagens em grupos com balanceamento automatico de ouro para/do banco de guerra ao abrir um banco.",

    -- core.lua: Slash command
    MSG_MISSINGPET_NOT_FOUND                = "Modulo MissingPet nao encontrado.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Metadata (title/desc)
    ---------------------------------------------------------------------------

    -- Auto Quest
    AUTOQUEST_TITLE                         = "Auto Quest",
    AUTOQUEST_DESC                          = "Aceitar e entregar missoes automaticamente.",

    -- Auto Queue
    AUTOQUEUE_TITLE                         = "Auto Queue",
    AUTOQUEUE_DESC                          = "Aceitar automaticamente verificacoes de papel usando sua selecao de papel do LFG.",

    -- Auto Repair
    AUTOREPAIR_TITLE                        = "Auto Repair",
    AUTOREPAIR_DESC                         = "Reparar equipamento automaticamente em mercadores.",

    -- Auto Sell
    AUTOSELL_TITLE                          = "Auto Sell",
    AUTOSELL_DESC                           = "Vender automaticamente itens indesejados e listados em mercadores.",

    -- Chat Filter
    CHATFILTER_TITLE                        = "Chat Filter",
    CHATFILTER_DESC                         = "Filtra spam de ouro, anuncios de boost e mensagens indesejadas de sussurros e canais publicos.",

    -- Cursor Ring
    CURSORRING_TITLE                        = "Cursor Ring & Trail",
    CURSORRING_DESC                         = "Exibe aneis personalizaveis ao redor do cursor com indicadores de conjuracao/GCD e um rastro opcional.",

    -- Delete Confirm
    DELETECONFIRM_TITLE                     = "Delete Confirm",
    DELETECONFIRM_DESC                      = "Ocultar campo de digitacao de exclusao e ativar o botao de confirmacao.",

    -- Disable Auto Add Spells
    DISABLEAUTOADD_TITLE                    = "Disable Auto Add Spells",
    DISABLEAUTOADD_DESC                     = "Impede que feiticos sejam adicionados automaticamente as barras de acao.",

    -- Missing Pet
    MISSINGPET_TITLE                        = "Missing Pet",
    MISSINGPET_DESC                         = "Exibe um aviso quando seu pet esta ausente ou em modo passivo.",

    -- Auto Playstyle
    AUTOPLAYSTYLE_TITLE                     = "Auto Playstyle",
    AUTOPLAYSTYLE_DESC                      = "Seleciona automaticamente seu estilo de jogo preferido ao listar grupos de M+ no Localizador de Grupo.",

    -- Faster Loot
    FASTERLOOT_TITLE                        = "Faster Loot",
    FASTERLOOT_DESC                         = "Coleta instantaneamente todo o saque ao abrir a janela de saque.",

    -- Auto Keystone
    AUTOKEYSTONE_TITLE                      = "Auto Keystone",
    AUTOKEYSTONE_DESC                       = "Insere automaticamente sua pedra angular Mitico+ ao abrir a IU de Modo Desafio.",

    -- Release Protection
    RELEASEPROTECT_TITLE                    = "Release Protection",
    RELEASEPROTECT_DESC                     = "Exigir segurar o modificador de pausa antes de liberar o espirito para evitar cliques acidentais.",

    -- Combat Timer
    COMBATTIMER_TITLE                       = "Combat Timer",
    COMBATTIMER_DESC                        = "Exibe um cronometro mostrando ha quanto tempo voce esta em combate.",

    -- Combat Alert
    COMBATALERT_TITLE                       = "Combat Alert",
    COMBATALERT_DESC                        = "Mostra um alerta de texto ao entrar ou sair de combate.",

    -- Range Check
    RANGECHECK_TITLE                        = "Range Check",
    RANGECHECK_DESC                         = "Exibe o status de alcance para seu alvo atual.",

    -- Tooltip
    TOOLTIP_TITLE                           = "Tooltip",
    TOOLTIP_DESC                            = "Aprimora dicas com IDs e nomes de montarias.",

    ---------------------------------------------------------------------------
    -- Phase 3: Module Print Messages
    ---------------------------------------------------------------------------

    -- Auto Queue messages
    AUTOQUEUE_MSG_ACCEPTED                  = "Verificacao de papel aceita automaticamente.",
    AUTOQUEUE_MSG_INVITE_ACCEPTED           = "Convite de grupo aceito automaticamente.",
    AUTOQUEUE_MSG_SIGNUP_SKIPPED            = "Candidatura ao grupo enviada automaticamente.",

    -- Auto Repair messages
    AUTOREPAIR_MSG_GUILD_UNAVAILABLE        = "Nao e possivel reparar: fundos da guilda indisponiveis.",
    AUTOREPAIR_MSG_REPAIRED_GUILD           = "Reparado por %s (fundos da guilda).",
    AUTOREPAIR_MSG_REPAIRED                 = "Reparado por %s.",
    AUTOREPAIR_MSG_NOT_ENOUGH_GOLD          = "Nao e possivel reparar: ouro insuficiente (%s necessario).",

    -- Auto Sell messages
    AUTOSELL_MSG_SOLD_ITEMS                 = "Vendido(s) %d item(ns) por %s.",

    -- Faster Loot messages
    FASTERLOOT_MSG_INV_FULL                 = "Inventario cheio - alguns itens nao puderam ser coletados.",

    -- Chat Filter messages
    CHATFILTER_MSG_ACTIVE                   = "Filtro de Chat ativo com %d palavras-chave.",
    CHATFILTER_MSG_KEYWORD_EXISTS           = "Palavra-chave ja esta na lista de filtros.",
    CHATFILTER_MSG_KEYWORD_ADDED            = "Adicionado \"%s\" ao filtro de chat.",

    -- Auto Sell item messages
    AUTOSELL_MSG_ALREADY_IN_LIST            = "Item ja esta na lista de venda.",
    AUTOSELL_MSG_ADDED_TO_LIST              = "Adicionado %s a lista de venda.",
    AUTOSELL_MSG_INVALID_ITEM_ID            = "ID de item invalido.",

    -- Tooltip messages
    TOOLTIP_MSG_ID_COPIED                   = "%s %s copiado.",

    -- Release Protection overlay text
    RELEASEPROTECT_HOLD_PROGRESS            = "Segure %s... %.1fs",
    RELEASEPROTECT_HOLD_PROMPT              = "Segure %s (%.1fs)",

    -- Auto Quest messages
    AUTOQUEST_MSG_NO_NPC                    = "Nenhum NPC encontrado. Fale com um NPC primeiro.",
    AUTOQUEST_MSG_BLOCKED_NPC               = "NPC bloqueado: %s",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoQuest WidgetOptions
    ---------------------------------------------------------------------------

    AUTOQUEST_AUTO_ACCEPT                   = "Aceitar missoes automaticamente",
    AUTOQUEST_AUTO_ACCEPT_DESC              = "Aceitar missoes de NPCs automaticamente.",
    AUTOQUEST_AUTO_TURNIN                   = "Entregar missoes automaticamente",
    AUTOQUEST_AUTO_TURNIN_DESC              = "Entregar missoes completas a NPCs automaticamente.",
    AUTOQUEST_SINGLE_REWARD                 = "Selecionar recompensa unica automaticamente",
    AUTOQUEST_SINGLE_REWARD_DESC            = "Se uma missao oferece apenas uma recompensa, seleciona-la automaticamente.",
    AUTOQUEST_SINGLE_GOSSIP                 = "Selecionar opcao de dialogo unica automaticamente",
    AUTOQUEST_SINGLE_GOSSIP_DESC            = "Selecionar automaticamente NPCs com apenas uma opcao de dialogo para progredir em cadeias de dialogo que levam a missoes.",
    AUTOQUEST_SKIP_TRIVIAL                  = "Pular missoes triviais",
    AUTOQUEST_SKIP_TRIVIAL_DESC             = "Nao aceitar automaticamente missoes cinzas (triviais/nivel baixo).",
    AUTOQUEST_CALLOUT                       = "Segure %s para pausar temporariamente a aceitacao e entrega automaticas.",
    AUTOQUEST_ADDON_BYPASS_NOTE             = "Nota: outros addons de automacao de missoes (QuickQuest, Plumber, etc.) podem ignorar a lista de bloqueio.",
    AUTOQUEST_ADD_NPC                       = "Adicionar NPC atual a lista de bloqueio",
    AUTOQUEST_ADD_NPC_DESC                  = "Fale com um NPC e clique neste botao para bloquea-lo da automacao de missoes.",
    AUTOQUEST_ZONE_FILTER                   = "Filtro de zona",
    AUTOQUEST_NPC_ZONE_FILTER_DESC          = "Filtrar NPCs bloqueados por zona.",
    AUTOQUEST_QUEST_ZONE_FILTER_DESC        = "Filtrar missoes bloqueadas por zona.",
    AUTOQUEST_ZONE_ALL                      = "Todas as zonas",
    AUTOQUEST_ZONE_CURRENT                  = "Zona atual",
    AUTOQUEST_BLOCKED_NPCS                  = "NPCs Bloqueados (%d)",
    AUTOQUEST_NPC_EMPTY_ALL                 = "Nenhum NPC bloqueado ainda -- selecione um NPC e clique no botao acima para adicionar.",
    AUTOQUEST_NPC_EMPTY_ZONE                = "Nenhum NPC bloqueado em %s.",
    AUTOQUEST_REMOVE_NPC_DESC               = "Remover %s da lista de bloqueio.",
    AUTOQUEST_BLOCKED_QUESTS_HEADER         = "Missoes Bloqueadas",
    AUTOQUEST_BLOCKED_QUESTS_NOTE           = "Missoes bloqueadas nao serao aceitas ou entregues automaticamente.",
    AUTOQUEST_QUEST_EMPTY_ALL               = "Nenhuma missao bloqueada ainda -- missoes aceitas automaticamente de NPCs bloqueados aparecerao aqui.",
    AUTOQUEST_QUEST_EMPTY_ZONE              = "Nenhuma missao bloqueada em %s.",
    AUTOQUEST_UNKNOWN_NPC                   = "NPC Desconhecido",
    AUTOQUEST_QUEST_LABEL_WITH_ID           = "%s (ID: %s)",
    AUTOQUEST_QUEST_LABEL_ID_ONLY           = "ID da Missao: %s",
    AUTOQUEST_UNBLOCK_DESC                  = "Desbloquear esta missao.",
    AUTOQUEST_BLOCK_QUEST                   = "Bloquear Missao",
    AUTOQUEST_BLOCKED                       = "Bloqueado",
    AUTOQUEST_BLOCK_DESC                    = "Bloquear esta missao da automacao futura.",
    AUTOQUEST_NPC_PREFIX                    = "NPC: %s",
    AUTOQUEST_NO_AUTOMATED                  = "Nenhuma missao automatizada ainda.",
    AUTOQUEST_RECENT_AUTOMATED              = "Missoes automatizadas recentes (%d)",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoSell WidgetOptions
    ---------------------------------------------------------------------------

    AUTOSELL_SELL_GRAYS                     = "Vender itens cinzas",
    AUTOSELL_SELL_GRAYS_DESC                = "Vender automaticamente todos os itens de qualidade inferior (cinzas).",
    AUTOSELL_SHOW_MESSAGE_DESC              = "Mostrar uma mensagem no chat quando itens sao vendidos automaticamente.",
    AUTOSELL_CALLOUT                        = "Segure %s ao abrir um vendedor para pular a venda automatica.",
    AUTOSELL_DRAG_DROP                      = "Arrastar e soltar:",
    AUTOSELL_DRAG_GLOBAL_DESC               = "Arraste um item das suas bolsas e solte aqui para adiciona-lo a lista de venda global.",
    AUTOSELL_DRAG_CHAR_DESC                 = "Arraste um item das suas bolsas e solte aqui para adiciona-lo a lista de venda deste personagem.",
    AUTOSELL_ITEM_ID                        = "ID do Item",
    AUTOSELL_ITEM_ID_GLOBAL_DESC            = "Insira um ID de item para adicionar a lista de venda global.",
    AUTOSELL_ITEM_ID_CHAR_DESC              = "Insira um ID de item para adicionar a lista de venda deste personagem.",
    AUTOSELL_REMOVE_DESC                    = "Remover este item da lista de venda.",
    AUTOSELL_GLOBAL_LIST                    = "Lista de Venda Global (%d)",
    AUTOSELL_CHAR_LIST                      = "Lista de Venda de %s (%d)",
    AUTOSELL_CHAR_ONLY_NOTE                 = "Itens nesta lista so sao vendidos neste personagem.",
    AUTOSELL_EMPTY_GLOBAL                   = "Nenhum item na lista de venda global.",
    AUTOSELL_EMPTY_CHAR                     = "Nenhum item na lista de venda do personagem.",

    ---------------------------------------------------------------------------
    -- Phase 3: CursorRing WidgetOptions
    ---------------------------------------------------------------------------

    CURSORRING_ENABLE_DESC                  = "Ativar ou desativar o modulo Cursor Ring & Trail.",
    CURSORRING_PREVIEW_START                = "Iniciar Visualizacao",
    CURSORRING_PREVIEW_STOP                 = "Parar Visualizacao",
    CURSORRING_PREVIEW_DESC                 = "Mostrar todos os elementos visuais no cursor para edicao em tempo real. Desativa automaticamente quando o painel de configuracoes e fechado.",
    CURSORRING_GROUP_GENERAL                = "Geral",
    CURSORRING_SHOW_OOC                     = "Mostrar Fora de Combate",
    CURSORRING_SHOW_OOC_DESC                = "Mostrar o anel do cursor fora de combate e instancias.",
    CURSORRING_COMBAT_OPACITY               = "Opacidade em Combate",
    CURSORRING_COMBAT_OPACITY_DESC          = "Opacidade do anel durante combate ou conteudo instanciado.",
    CURSORRING_OOC_OPACITY                  = "Opacidade Fora de Combate",
    CURSORRING_OOC_OPACITY_DESC             = "Opacidade do anel fora de combate.",
    CURSORRING_GROUP_RING1                  = "Anel 1 (Externo)",
    CURSORRING_ENABLE_RING1                 = "Ativar Anel 1",
    CURSORRING_ENABLE_RING1_DESC            = "Mostrar o anel externo.",
    CURSORRING_SHAPE                        = "Forma",
    CURSORRING_RING_SHAPE_DESC              = "Forma do anel.",
    CURSORRING_SHAPE_CIRCLE                 = "Circulo",
    CURSORRING_SHAPE_THIN                   = "Circulo Fino",
    CURSORRING_COLOR                        = "Cor",
    CURSORRING_RING1_COLOR_DESC             = "Cor do Anel 1.",
    CURSORRING_SIZE                         = "Tamanho",
    CURSORRING_RING1_SIZE_DESC              = "Tamanho do Anel 1 em pixels.",
    CURSORRING_GROUP_RING2                  = "Anel 2 (Interno)",
    CURSORRING_ENABLE_RING2                 = "Ativar Anel 2",
    CURSORRING_ENABLE_RING2_DESC            = "Mostrar o anel interno.",
    CURSORRING_RING2_COLOR_DESC             = "Cor do Anel 2.",
    CURSORRING_RING2_SIZE_DESC              = "Tamanho do Anel 2 em pixels.",
    CURSORRING_GROUP_DOT                    = "Ponto Central",
    CURSORRING_ENABLE_DOT                   = "Ativar Ponto",
    CURSORRING_ENABLE_DOT_DESC              = "Mostrar um pequeno ponto no centro dos aneis do cursor.",
    CURSORRING_DOT_COLOR_DESC               = "Cor do ponto.",
    CURSORRING_DOT_SIZE_DESC                = "Tamanho do ponto em pixels.",
    CURSORRING_GROUP_CAST                   = "Efeito de Conjuracao",
    CURSORRING_ENABLE_CAST                  = "Ativar Efeito de Conjuracao",
    CURSORRING_ENABLE_CAST_DESC             = "Mostrar um efeito visual durante conjuracao e canalizacao de feiticos.",
    CURSORRING_STYLE                        = "Estilo",
    CURSORRING_CAST_STYLE_DESC              = "Segmentos: arco se ilumina progressivamente. Preenchimento: forma cresce do centro. Varredura: varredura de cooldown (pode funcionar simultaneamente com GCD).",
    CURSORRING_STYLE_SEGMENTS               = "Segmentos",
    CURSORRING_STYLE_FILL                   = "Preenchimento",
    CURSORRING_STYLE_SWIPE                  = "Varredura",
    CURSORRING_CAST_COLOR_DESC              = "Cor do efeito de conjuracao.",
    CURSORRING_SWIPE_OFFSET                 = "Deslocamento da Varredura",
    CURSORRING_SWIPE_OFFSET_DESC            = "Deslocamento em pixels para o anel de varredura de conjuracao fora do anel GCD. Aplica-se apenas ao estilo Varredura.",
    CURSORRING_GROUP_GCD                    = "Indicador de GCD",
    CURSORRING_ENABLE_GCD                   = "Ativar GCD",
    CURSORRING_ENABLE_GCD_DESC              = "Mostrar uma varredura de cooldown para o cooldown global.",
    CURSORRING_GCD_COLOR_DESC               = "Cor da varredura de GCD.",
    CURSORRING_OFFSET                       = "Deslocamento",
    CURSORRING_GCD_OFFSET_DESC              = "Deslocamento em pixels para o anel GCD fora do Anel 1.",
    CURSORRING_GROUP_TRAIL                  = "Rastro do Mouse",
    CURSORRING_ENABLE_TRAIL                 = "Ativar Rastro",
    CURSORRING_ENABLE_TRAIL_DESC            = "Mostrar um rastro que desaparece atras do cursor.",
    CURSORRING_TRAIL_STYLE_DESC             = "Estilo de exibicao do rastro. Brilho: rastro cintilante. Linha: fita fina continua. Linha Grossa: fita larga. Pontos: pontos espacados. Personalizado: configuracoes manuais.",
    CURSORRING_TRAIL_GLOW                   = "Brilho",
    CURSORRING_TRAIL_LINE                   = "Linha",
    CURSORRING_TRAIL_THICKLINE              = "Linha Grossa",
    CURSORRING_TRAIL_DOTS                   = "Pontos",
    CURSORRING_TRAIL_CUSTOM                 = "Personalizado",
    CURSORRING_TRAIL_COLOR_DESC             = "Preset de cor do rastro. Cor da Classe usa a cor da sua classe automaticamente. Arco-iris, Brasa e Oceano sao gradientes multicoloridos. Personalizado permite escolher qualquer cor abaixo.",
    CURSORRING_TRAIL_COLOR_CUSTOM           = "Personalizado",
    CURSORRING_TRAIL_COLOR_CLASS            = "Cor da Classe",
    CURSORRING_TRAIL_COLOR_GOLD             = "Dourado Lantern",
    CURSORRING_TRAIL_COLOR_ARCANE           = "Arcano",
    CURSORRING_TRAIL_COLOR_FEL              = "Vil",
    CURSORRING_TRAIL_COLOR_FIRE             = "Fogo",
    CURSORRING_TRAIL_COLOR_FROST            = "Gelo",
    CURSORRING_TRAIL_COLOR_HOLY             = "Sagrado",
    CURSORRING_TRAIL_COLOR_SHADOW           = "Sombra",
    CURSORRING_TRAIL_COLOR_RAINBOW          = "Arco-iris",
    CURSORRING_TRAIL_COLOR_ALAR             = "Al'ar",
    CURSORRING_TRAIL_COLOR_EMBER            = "Brasa",
    CURSORRING_TRAIL_COLOR_OCEAN            = "Oceano",
    CURSORRING_CUSTOM_COLOR                 = "Cor Personalizada",
    CURSORRING_CUSTOM_COLOR_DESC            = "Cor do rastro (usada apenas quando Cor esta definida como Personalizado).",
    CURSORRING_DURATION                     = "Duracao",
    CURSORRING_DURATION_DESC                = "Quanto tempo os pontos do rastro duram antes de desaparecer.",
    CURSORRING_MAX_POINTS                   = "Pontos Maximos",
    CURSORRING_MAX_POINTS_DESC              = "Numero de pontos do rastro no pool. Valores mais altos criam rastros mais longos mas usam mais memoria.",
    CURSORRING_DOT_SIZE                     = "Tamanho do Ponto",
    CURSORRING_DOT_SIZE_TRAIL_DESC          = "Tamanho de cada ponto do rastro em pixels.",
    CURSORRING_DOT_SPACING                  = "Espacamento de Pontos",
    CURSORRING_DOT_SPACING_DESC             = "Distancia minima em pixels antes de um novo ponto do rastro ser colocado. Valores menores criam um rastro mais denso e continuo.",
    CURSORRING_SHRINK_AGE                   = "Encolher com Idade",
    CURSORRING_SHRINK_AGE_DESC              = "Pontos do rastro encolhem conforme desaparecem. Desative para um rastro de largura uniforme.",
    CURSORRING_TAPER_DISTANCE               = "Afinar com Distancia",
    CURSORRING_TAPER_DISTANCE_DESC          = "Pontos do rastro encolhem e desvanecem em direcao a cauda, criando um efeito de pincelada afilada.",
    CURSORRING_SPARKLE                      = "Brilho",
    CURSORRING_SPARKLE_DESC                 = "Adiciona pequenas particulas cintilantes ao longo do rastro conforme voce move o cursor.",
    CURSORRING_SPARKLE_OFF                  = "Desligado",
    CURSORRING_SPARKLE_STATIC               = "Estatico",
    CURSORRING_SPARKLE_TWINKLE              = "Cintilante",
    CURSORRING_TRAIL_PERF_NOTE              = "O rastro e executado por quadro. Mais pontos, brilhos e efeitos usarao mais CPU.",

    ---------------------------------------------------------------------------
    -- Phase 3: MissingPet WidgetOptions
    ---------------------------------------------------------------------------

    MISSINGPET_ENABLE_DESC                  = "Ativar ou desativar o aviso de Pet Ausente.",
    MISSINGPET_GROUP_WARNING                = "Configuracoes de Aviso",
    MISSINGPET_SHOW_MISSING                 = "Mostrar Aviso de Ausente",
    MISSINGPET_SHOW_MISSING_DESC            = "Exibir um aviso quando seu pet esta dispensado ou morto.",
    MISSINGPET_SHOW_PASSIVE                 = "Mostrar Aviso de Passivo",
    MISSINGPET_SHOW_PASSIVE_DESC            = "Exibir um aviso quando seu pet esta em modo passivo.",
    MISSINGPET_MISSING_TEXT                 = "Texto de Ausente",
    MISSINGPET_MISSING_TEXT_DESC            = "Texto a exibir quando seu pet esta ausente.",
    MISSINGPET_PASSIVE_TEXT                 = "Texto de Passivo",
    MISSINGPET_PASSIVE_TEXT_DESC            = "Texto a exibir quando seu pet esta em modo passivo.",
    MISSINGPET_MISSING_COLOR                = "Cor de Ausente",
    MISSINGPET_MISSING_COLOR_DESC           = "Cor do texto de aviso de pet ausente.",
    MISSINGPET_PASSIVE_COLOR                = "Cor de Passivo",
    MISSINGPET_PASSIVE_COLOR_DESC           = "Cor do texto de aviso de pet passivo.",
    MISSINGPET_ANIMATION_DESC               = "Escolha como o texto de aviso e animado.",
    MISSINGPET_GROUP_FONT                   = "Configuracoes de Fonte",
    MISSINGPET_FONT_DESC                    = "Selecione a fonte para o texto de aviso.",
    MISSINGPET_FONT_SIZE_DESC               = "Tamanho do texto de aviso.",
    MISSINGPET_FONT_OUTLINE_DESC            = "Estilo de contorno para o texto de aviso.",
    MISSINGPET_LOCK_POSITION_DESC           = "Impedir que o aviso seja movido.",
    MISSINGPET_RESET_POSITION_DESC          = "Redefinir a posicao do quadro de aviso para o centro da tela.",
    MISSINGPET_GROUP_VISIBILITY             = "Visibilidade",
    MISSINGPET_HIDE_MOUNTED                 = "Ocultar Quando Montado",
    MISSINGPET_HIDE_MOUNTED_DESC            = "Ocultar o aviso enquanto montado, em taxi ou em um veiculo.",
    MISSINGPET_HIDE_REST                    = "Ocultar em Zonas de Descanso",
    MISSINGPET_HIDE_REST_DESC               = "Ocultar o aviso enquanto em uma zona de descanso (cidades e estalagens).",
    MISSINGPET_DISMOUNT_DELAY               = "Atraso ao Desmontar",
    MISSINGPET_DISMOUNT_DELAY_DESC          = "Segundos para esperar apos desmontar antes de mostrar o aviso. Defina como 0 para mostrar imediatamente.",
    MISSINGPET_PLAY_SOUND_DESC              = "Tocar um som quando o aviso e exibido.",
    MISSINGPET_SOUND_MISSING                = "Som Quando Ausente",
    MISSINGPET_SOUND_MISSING_DESC           = "Tocar som quando o pet esta ausente.",
    MISSINGPET_SOUND_PASSIVE                = "Som Quando Passivo",
    MISSINGPET_SOUND_PASSIVE_DESC           = "Tocar som quando o pet esta em modo passivo.",
    MISSINGPET_SOUND_COMBAT                 = "Som em Combate",
    MISSINGPET_SOUND_COMBAT_DESC            = "Continuar tocando som durante combate. Quando desativado, o som para quando o combate comeca.",
    MISSINGPET_SOUND_REPEAT                 = "Repetir Som",
    MISSINGPET_SOUND_REPEAT_DESC            = "Repetir o som em intervalos regulares enquanto o aviso esta exibido.",
    MISSINGPET_SOUND_SELECT_DESC            = "Selecione o som a tocar. Clique no icone do alto-falante para visualizar.",
    MISSINGPET_REPEAT_INTERVAL              = "Intervalo de Repeticao",
    MISSINGPET_REPEAT_INTERVAL_DESC         = "Segundos entre repeticoes do som.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatAlert WidgetOptions
    ---------------------------------------------------------------------------

    COMBATALERT_ENABLE_DESC                 = "Mostrar alertas de texto ao entrar/sair de combate.",
    COMBATALERT_PREVIEW_DESC                = "Repetir alertas de entrada/saida na tela para edicao em tempo real. Desativa automaticamente quando o painel de configuracoes e fechado.",
    COMBATALERT_GROUP_ENTER                 = "Entrada em Combate",
    COMBATALERT_SHOW_ENTER                  = "Mostrar Alerta de Entrada",
    COMBATALERT_SHOW_ENTER_DESC             = "Mostrar um alerta ao entrar em combate.",
    COMBATALERT_ENTER_TEXT                   = "Texto de Entrada",
    COMBATALERT_ENTER_TEXT_DESC             = "Texto exibido ao entrar em combate.",
    COMBATALERT_ENTER_COLOR                 = "Cor de Entrada",
    COMBATALERT_ENTER_COLOR_DESC            = "Cor do texto de entrada em combate.",
    COMBATALERT_GROUP_LEAVE                 = "Saida de Combate",
    COMBATALERT_SHOW_LEAVE                  = "Mostrar Alerta de Saida",
    COMBATALERT_SHOW_LEAVE_DESC             = "Mostrar um alerta ao sair de combate.",
    COMBATALERT_LEAVE_TEXT                   = "Texto de Saida",
    COMBATALERT_LEAVE_TEXT_DESC             = "Texto exibido ao sair de combate.",
    COMBATALERT_LEAVE_COLOR                 = "Cor de Saida",
    COMBATALERT_LEAVE_COLOR_DESC            = "Cor do texto de saida de combate.",
    COMBATALERT_GROUP_FONT                  = "Configuracoes de Fonte e Exibicao",
    COMBATALERT_FONT_DESC                   = "Selecione a fonte para o texto de alerta.",
    COMBATALERT_FONT_SIZE_DESC              = "Tamanho do texto de alerta.",
    COMBATALERT_FONT_OUTLINE_DESC           = "Estilo de contorno para o texto de alerta.",
    COMBATALERT_FADE_DURATION               = "Duracao do Desvanecimento",
    COMBATALERT_FADE_DURATION_DESC          = "Duracao total do alerta (exibicao + desvanecimento) em segundos.",
    COMBATALERT_PLAY_SOUND_DESC             = "Tocar um som quando o alerta e mostrado.",
    COMBATALERT_SOUND_SELECT_DESC           = "Selecione o som a tocar.",
    COMBATALERT_LOCK_POSITION_DESC          = "Impedir que o alerta seja movido.",
    COMBATALERT_RESET_POSITION_DESC         = "Redefinir o alerta para sua posicao padrao.",

    ---------------------------------------------------------------------------
    -- Phase 3: CombatTimer WidgetOptions
    ---------------------------------------------------------------------------

    COMBATTIMER_ENABLE_DESC                 = "Mostrar um cronometro durante combate.",
    COMBATTIMER_PREVIEW_DESC                = "Mostrar o cronometro na tela para edicao em tempo real. Desativa automaticamente quando o painel de configuracoes e fechado.",
    COMBATTIMER_FONT_DESC                   = "Selecione a fonte para o texto do cronometro.",
    COMBATTIMER_FONT_SIZE_DESC              = "Tamanho do texto do cronometro.",
    COMBATTIMER_FONT_OUTLINE_DESC           = "Estilo de contorno para o texto do cronometro.",
    COMBATTIMER_FONT_COLOR_DESC             = "Cor do texto do cronometro.",
    COMBATTIMER_STICKY_DURATION             = "Duracao de Persistencia",
    COMBATTIMER_STICKY_DURATION_DESC        = "Segundos para continuar mostrando o tempo final apos o combate terminar. Defina como 0 para ocultar imediatamente.",
    COMBATTIMER_LOCK_POSITION_DESC          = "Impedir que o cronometro seja movido.",
    COMBATTIMER_RESET_POSITION_DESC         = "Redefinir o cronometro para sua posicao padrao.",

    ---------------------------------------------------------------------------
    -- Phase 3: RangeCheck WidgetOptions
    ---------------------------------------------------------------------------

    RANGECHECK_ENABLE_DESC                  = "Mostrar status de alcance para seu alvo atual.",
    RANGECHECK_HIDE_IN_RANGE                = "Ocultar Quando no Alcance",
    RANGECHECK_HIDE_IN_RANGE_DESC           = "Ocultar a exibicao quando seu alvo esta dentro do alcance. Mostra apenas quando fora do alcance.",
    RANGECHECK_COMBAT_ONLY                  = "Apenas em Combate",
    RANGECHECK_COMBAT_ONLY_DESC             = "Mostrar alcance apenas quando em combate.",
    RANGECHECK_GROUP_STATUS                 = "Texto de Status",
    RANGECHECK_IN_RANGE_TEXT                = "Texto no Alcance",
    RANGECHECK_IN_RANGE_TEXT_DESC           = "Texto a exibir quando seu alvo esta dentro do alcance.",
    RANGECHECK_OUT_OF_RANGE_TEXT            = "Texto Fora do Alcance",
    RANGECHECK_OUT_OF_RANGE_TEXT_DESC       = "Texto a exibir quando seu alvo esta fora do alcance.",
    RANGECHECK_IN_RANGE_COLOR               = "Cor no Alcance",
    RANGECHECK_IN_RANGE_COLOR_DESC          = "Cor para o texto de dentro do alcance.",
    RANGECHECK_OUT_OF_RANGE_COLOR           = "Cor Fora do Alcance",
    RANGECHECK_OUT_OF_RANGE_COLOR_DESC      = "Cor para o texto de fora do alcance.",
    RANGECHECK_ANIMATION_DESC               = "Escolha como o texto de status e animado ao mudar de estado.",
    RANGECHECK_FONT_DESC                    = "Selecione a fonte para o texto de alcance.",
    RANGECHECK_FONT_SIZE_DESC               = "Tamanho do texto de alcance.",
    RANGECHECK_FONT_OUTLINE_DESC            = "Estilo de contorno para o texto de alcance.",
    RANGECHECK_LOCK_POSITION_DESC           = "Impedir que a exibicao de alcance seja movida.",
    RANGECHECK_RESET_POSITION_DESC          = "Redefinir a exibicao de alcance para sua posicao padrao.",

    ---------------------------------------------------------------------------
    -- Phase 3: ChatFilter WidgetOptions
    ---------------------------------------------------------------------------

    CHATFILTER_ENABLE_DESC                  = "Ativar ou desativar o Filtro de Chat.",
    CHATFILTER_LOGIN_MESSAGE                = "Mensagem de login",
    CHATFILTER_LOGIN_MESSAGE_DESC           = "Mostrar uma mensagem no chat ao fazer login confirmando que o filtro esta ativo.",
    CHATFILTER_ADD_KEYWORD                  = "Adicionar palavra-chave",
    CHATFILTER_ADD_KEYWORD_DESC             = "Insira uma palavra ou frase para filtrar. A correspondencia nao diferencia maiusculas de minusculas.",
    CHATFILTER_KEYWORDS_GROUP               = "Palavras-chave (%d)",
    CHATFILTER_NO_KEYWORDS                  = "Nenhuma palavra-chave configurada.",
    CHATFILTER_REMOVE_KEYWORD_DESC          = "Remover \"%s\" da lista de filtros.",
    CHATFILTER_RESTORE_DEFAULTS             = "Restaurar palavras-chave padrao",
    CHATFILTER_RESTORE_DEFAULTS_DESC        = "Redefinir a lista de palavras-chave para os padroes integrados. Isso substitui todas as palavras-chave personalizadas.",
    CHATFILTER_RESTORE_CONFIRM              = "Restaurar?",

    ---------------------------------------------------------------------------
    -- Phase 3: Tooltip WidgetOptions
    ---------------------------------------------------------------------------

    TOOLTIP_ENABLE_DESC                     = "Aprimorar dicas com informacoes extras.",
    TOOLTIP_GROUP_PLAYER                    = "Jogador",
    TOOLTIP_MOUNT_NAME                      = "Nome da montaria",
    TOOLTIP_MOUNT_NAME_DESC                 = "Mostrar qual montaria um jogador esta usando.",
    TOOLTIP_GROUP_ITEMS                     = "Itens",
    TOOLTIP_ITEM_ID                         = "ID do Item",
    TOOLTIP_ITEM_ID_DESC                    = "Mostrar o ID do item nas dicas de itens.",
    TOOLTIP_ITEM_SPELL_ID                   = "ID do feitico do item",
    TOOLTIP_ITEM_SPELL_ID_DESC              = "Mostrar o ID do feitico de uso em consumiveis e outros itens com habilidades de uso.",
    TOOLTIP_GROUP_SPELLS                    = "Feiticos",
    TOOLTIP_SPELL_ID                        = "ID do Feitico",
    TOOLTIP_SPELL_ID_DESC                   = "Mostrar o ID do feitico nas dicas de feiticos, auras e talentos.",
    TOOLTIP_NODE_ID                         = "ID do Node",
    TOOLTIP_NODE_ID_DESC                    = "Mostrar o ID do node da arvore de talentos nas dicas de talentos.",
    TOOLTIP_GROUP_COPY                      = "Copiar",
    TOOLTIP_CTRL_C                          = "Ctrl+C para copiar",
    TOOLTIP_CTRL_C_DESC                     = "Pressione Ctrl+C para copiar o ID principal, ou Ctrl+Shift+C para copiar o ID secundario (ex. SpellID de uso de um item).",
    TOOLTIP_COMBAT_NOTE                     = "Aprimoramentos de dicas sao desativados em instancias. Verificacao de montaria e copia via Ctrl+C sao desativadas durante combate.",

    ---------------------------------------------------------------------------
    -- Phase 3: AutoPlaystyle WidgetOptions
    ---------------------------------------------------------------------------

    AUTOPLAYSTYLE_ENABLE_DESC               = "Selecionar estilo de jogo automaticamente ao listar grupos de M+.",
    AUTOPLAYSTYLE_PLAYSTYLE                 = "Estilo de Jogo",
    AUTOPLAYSTYLE_PLAYSTYLE_DESC            = "Seleciona automaticamente este estilo de jogo ao abrir o dialogo de listagem do Localizador de Grupo para masmorras M+.",

    ---------------------------------------------------------------------------
    -- Shared: Font outline values (used across multiple modules)
    ---------------------------------------------------------------------------

    FONT_OUTLINE_NONE                       = "Nenhum",
    FONT_OUTLINE_OUTLINE                    = "Contorno",
    FONT_OUTLINE_THICK                      = "Contorno Grosso",
    FONT_OUTLINE_MONO                       = "Monocromatico",
    FONT_OUTLINE_OUTLINE_MONO              = "Contorno + Mono",

    ---------------------------------------------------------------------------
    -- Shared: Animation values (used across MissingPet, RangeCheck)
    ---------------------------------------------------------------------------

    ANIMATION_NONE                          = "Nenhum (estatico)",
    ANIMATION_BOUNCE                        = "Quicar",
    ANIMATION_PULSE                         = "Pulsar",
    ANIMATION_FADE                          = "Desvanecer",
    ANIMATION_SHAKE                         = "Tremer",
    ANIMATION_GLOW                          = "Brilhar",
    ANIMATION_HEARTBEAT                     = "Batimento",

    ---------------------------------------------------------------------------
    -- Shared: Day names
    ---------------------------------------------------------------------------

    DAY_SUN                                 = "Domingo",
    DAY_MON                                 = "Segunda",
    DAY_TUE                                 = "Terca",
    DAY_WED                                 = "Quarta",
    DAY_THU                                 = "Quinta",
    DAY_FRI                                 = "Sexta",
    DAY_SAT                                 = "Sabado",

    ---------------------------------------------------------------------------
    -- Shared: Confirm/Remove labels
    ---------------------------------------------------------------------------

    SHARED_REMOVE                           = "Remover",
    SHARED_REMOVE_CONFIRM                   = "Remover?",

    ---------------------------------------------------------------------------
    -- Tooltip: in-game tooltip hint lines
    ---------------------------------------------------------------------------

    TOOLTIP_HINT_COPY                       = "Ctrl+C para copiar",
    TOOLTIP_HINT_COPY_BOTH                  = "Ctrl+C ItemID  |  Ctrl+Shift+C SpellID",
    TOOLTIP_COPY_HINT                       = "Ctrl+C para copiar, Esc para fechar",

    -- Reset Minimap Zoom
    RESETMINIMAPZOOM_TITLE                  = "Reset Minimap Zoom",
    RESETMINIMAPZOOM_DESC                   = "Restaura automaticamente o zoom do minimapa apos um atraso.",
    RESETMINIMAPZOOM_ENABLE_DESC            = "Redefinir automaticamente o zoom do minimapa para totalmente afastado apos um atraso.",
    RESETMINIMAPZOOM_DELAY                  = "Atraso de Redefinicao",
    RESETMINIMAPZOOM_DELAY_DESC             = "Segundos para esperar antes de redefinir o zoom do minimapa.",

    -- Map Pins
    MAPPINS_TITLE                           = "Map Pins",
    MAPPINS_DESC                            = "Mostra marcadores personalizados no mapa-mundi e minimapa.",
    MAPPINS_ENABLE_DESC                     = "Mostrar marcadores personalizados no mapa-mundi e minimapa.",
    MAPPINS_SHOW_MINIMAP                    = "Mostrar no Minimapa",
    MAPPINS_SHOW_MINIMAP_DESC               = "Exibir marcadores no minimapa quando proximo.",
    MAPPINS_PIN_SIZE                        = "Tamanho do Marcador",
    MAPPINS_PIN_SIZE_DESC                   = "Tamanho dos icones de marcador em pixels.",
    MAPPINS_SHOW_LABELS                     = "Mostrar Rotulos",
    MAPPINS_SHOW_LABELS_DESC                = "Exibir nomes dos marcadores abaixo dos icones.",
    MAPPINS_GROUP_CATEGORIES                = "Categorias",
    MAPPINS_CAT_TRAINERS                    = "Treinadores de Profissao",
    MAPPINS_CAT_TRAINERS_DESC               = "Mostrar localizacoes de treinadores de profissao.",

    -- Flight Path Line
    MAPLINE_TITLE                           = "Flight Path Line",
    MAPLINE_DESC                            = "Desenha uma linha pontilhada direcional no mapa-mundi durante voo.",
    MAPLINE_ENABLE_DESC                     = "Mostrar uma linha pontilhada no mapa-mundi indicando a direcao do seu voo.",
    MAPLINE_STYLE                           = "Estilo da Linha",
    MAPLINE_STYLE_DESC                      = "Como a linha direcional aparece no mapa.",
    MAPLINE_STYLE_SOLID                     = "Solida",
    MAPLINE_STYLE_DOTTED                    = "Pontilhada",
    MAPLINE_STYLE_THICK                     = "Grossa",
    MAPLINE_COLOR                           = "Cor da Linha",
    MAPLINE_COLOR_DESC                      = "Cor e opacidade da linha direcional.",
    MAPLINE_LENGTH                          = "Comprimento da Linha",
    MAPLINE_LENGTH_DESC                     = "Ate onde a linha direcional se estende a partir da sua posicao.",

    -- Skip Cinematics
    SKIPCINEMATICS_TITLE                    = "Skip Cinematics",
    SKIPCINEMATICS_DESC                     = "Pula automaticamente filmes, cinematicas e cenas.",
    SKIPCINEMATICS_ENABLE_DESC              = "Pular filmes, cinematicas e cenas automaticamente. Segure %s para assistir.",
    SKIPCINEMATICS_SKIPPED                  = "Cinematica pulada.",
    SKIPCINEMATICS_SHOW_MESSAGE_DESC        = "Mostrar uma mensagem no chat quando uma cinematica e pulada.",
});
