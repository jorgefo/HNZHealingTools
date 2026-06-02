local _, ns = ...

-- Traduções em português do Brasil (ptBR). As chaves são os textos em inglês
-- usados em ns.L[...]. Chaves ausentes caem para o inglês via metatable em Locales.lua.
ns.RegisterLocale("ptBR", {
    -- ===== Diversos / Misc (ressurreição em combate + reencarnação) =====
    ["Miscellaneous"] = "Diversos",
    ["Combat Resurrections"] = "Ressurreições em combate",
    ["Enable combat resurrection indicator"] = "Ativar indicador de ressurreições em combate",
    ["Shows the group's shared battle-res charges (raid / Mythic+) — it does not depend on your class. With charges available: the number. Without: the icon dims and counts down to the next charge. Hidden in content with no shared pool."] = "Mostra as cargas de ressurreição em combate compartilhadas do grupo (raide / Mítica+) — não depende da sua classe. Com cargas disponíveis: o número. Sem: o ícone escurece e faz contagem regressiva até a próxima carga. Oculto em conteúdo sem reserva compartilhada.",
    ["Text size (0=auto)"] = "Tamanho do texto (0=auto)",
    ["Move icon"] = "Mover ícone",
    ["Lock icon"] = "Travar ícone",
    ["Right-click: open settings (out of combat)"] = "Clique direito: abrir configurações (fora de combate)",
    ["Show Reincarnation (Shaman self-res)"] = "Mostrar Reencarnação (auto-ressurreição de Xamã)",
    -- ===== Mensagens de erro / feedback =====
    ["Spell not found: "] = "Magia não encontrada: ",
    [" already monitored."] = " já está sendo monitorada.",
    ["Enter a name/ID."] = "Digite um nome/ID.",
    ["Enter a name."] = "Digite um nome.",
    ["Already exists."] = "Já existe.",
    ["Created: "] = "Criado: ",
    ["Can't copy to itself."] = "Não é possível copiar sobre si mesmo.",
    ["Copied from "] = "Copiado de ",
    ["Give the profile a name."] = "Dê um nome ao perfil.",
    ["Paste the exported string in the box."] = "Cole a string exportada na caixa.",
    ["Imported as: "] = "Importado como: ",
    ["Import failed."] = "Falha na importação.",
    ["Ready: Ctrl+C to copy"] = "Pronto: Ctrl+C para copiar",
    ["No active profile to export"] = "Sem perfil ativo para exportar",

    -- ===== Botões genéricos =====
    ["Save"] = "Salvar",
    ["Cancel"] = "Cancelar",
    ["Add"] = "Adicionar",
    ["Update"] = "Atualizar",
    ["Close"] = "Fechar",
    ["Edit"] = "Editar",
    ["Test"] = "Testar",
    ["Create"] = "Criar",
    ["Load"] = "Carregar",
    ["Export"] = "Exportar",
    ["Import"] = "Importar",
    ["Copy to current"] = "Copiar para atual",

    -- ===== Abas / títulos de página =====
    ["Cursor Spells"] = "Magias do cursor",
    ["Cursor Auras"] = "Auras do cursor",
    ["Ring Auras"] = "Auras em anel",
    ["Cursor Config"] = "Config. cursor",
    ["Ring Config"] = "Config. anel",
    ["Profiles"] = "Perfis",

    -- ===== Editores: títulos e rótulos =====
    ["Cursor Spell"] = "Magia do cursor",
    ["Cursor Aura"] = "Aura do cursor",
    ["Ring Aura"] = "Aura em anel",
    ["New Cursor Spell"] = "Nova magia do cursor",
    ["New Cursor Aura"] = "Nova aura do cursor",
    ["New Ring Aura"] = "Nova aura em anel",
    ["Editing: "] = "Editando: ",
    ["Spell name or ID:"] = "Nome da magia ou ID:",
    ["Aura name or ID:"] = "Nome da aura ou ID:",
    ["Show only when charges >=  (0=always):"] = "Mostrar somente quando cargas >=  (0=sempre):",
    ["Stack text size (0=default):"] = "Tamanho texto stacks (0=padrão):",
    ["Hide while on cooldown"] = "Ocultar durante a recarga",
    ["Hide status overlay"] = "Ocultar sobreposição de status",
    ["Hide cooldown / duration timer"] = "Ocultar temporizador de recarga/duração",
    ["Hide timer"] = "Ocultar temporizador",
    ["Specs:"] = "Especializações:",
    ["Required talent:"] = "Talento requerido:",
    ["Unit:"] = "Unidade:",
    ["Type:"] = "Tipo:",
    ["Show:"] = "Mostrar:",
    ["Min stacks:"] = "Stacks mín.:",
    ["Duration (sec, 0=auto):"] = "Duração (seg, 0=auto):",
    ["Color:"] = "Cor:",
    ["Show icon on ring"] = "Mostrar ícone no anel",
    ["Play sound on activation"] = "Tocar som ao ativar",
    ["Pulse icon at screen center on ready"] = "Pulso do ícone no centro da tela quando pronto",
    ["Pulse icon at screen center on activation"] = "Pulso do ícone no centro da tela ao ativar",
    ["Play sound on ready"] = "Tocar som quando pronto",
    ["Pulse Display Settings"] = "Configurações do pulso",
    ["Pulse Config"] = "Pulso",
    ["Size & Timing"] = "Tamanho e tempo",
    ["Hold Duration"] = "Duração",
    ["Enable cooldown pulse"] = "Ativar pulso de recarga",
    ["Show anchor"] = "Mostrar âncora",
    ["Hide anchor"] = "Ocultar âncora",
    ["Test pulse"] = "Testar pulso",
    ["Drag to move"] = "Arraste para mover",

    -- ===== TalentPicker =====
    ["[No talent]"] = "[Sem talento]",
    ["Select a talent"] = "Selecione um talento",
    ["search"] = "buscar",
    ["(no talents in this loadout)"] = "(sem talentos neste loadout)",

    -- ===== SoundPicker =====
    ["Select a sound"] = "Selecione um som",

    -- ===== DropZone =====
    ["Drag a spell here"] = "Arraste uma magia aqui",

    -- ===== Dropdowns: unidades / filtros / showWhen =====
    ["Target"] = "Alvo",
    ["Player"] = "Jogador",
    ["Focus"] = "Foco",
    ["Mouseover"] = "Sob o cursor",
    ["Pet"] = "Mascote",
    ["Buff"] = "Bônus",
    ["Debuff"] = "Penalidade",
    ["Always"] = "Sempre",
    ["Only missing"] = "Só se faltando",
    ["Only active"] = "Só se ativa",
    ["Active only"] = "Só se ativa",
    ["Missing only"] = "Só se faltando",
    ["Below stacks"] = "Abaixo dos stacks",

    -- ===== Linhas de listagem (badges) =====
    ["Unknown"] = "Desconhecido",
    ["Min:"] = "Mín:",
    ["Hide CD"] = "Sem CD",
    ["Talent"] = "Talento",
    ["[icon]"] = "[ícone]",

    -- ===== Estados vazios / dicas =====
    ["No spells. Use 'Add Cursor Spell...' below."] = "Sem magias. Use 'Adicionar magia do cursor...' abaixo.",
    ["No auras. Use 'Add Cursor Aura...' below."] = "Sem auras. Use 'Adicionar aura do cursor...' abaixo.",
    ["No ring auras. Use 'Add Ring Aura...' below."] = "Sem auras em anel. Use 'Adicionar aura em anel...' abaixo.",
    ["Spells shown as icons near the mouse cursor. Click the gear to edit."] = "Magias mostradas como ícones perto do cursor. Clique na engrenagem para editar.",
    ["Auras shown as icons near the mouse cursor. Click the gear to edit."] = "Auras mostradas como ícones perto do cursor. Clique na engrenagem para editar.",
    ["Auras shown as circular rings around the character. Click the gear to edit, click color to change."] = "Auras mostradas como anéis ao redor do personagem. Clique na engrenagem para editar, clique na cor para mudar.",
    ["Add Cursor Spell..."] = "Adicionar magia do cursor...",
    ["Add Cursor Aura..."] = "Adicionar aura do cursor...",
    ["Add Ring Aura..."] = "Adicionar aura em anel...",
    ["or drag a spell here:"] = "ou arraste uma magia aqui:",

    -- ===== Configurações do cursor =====
    ["Cursor Display Settings"] = "Configurações do display do cursor",
    ["Size & Layout"] = "Tamanho e layout",
    ["Icon Size"] = "Tamanho do ícone",
    ["Icon Spacing"] = "Espaçamento do ícone",
    ["Max Columns"] = "Colunas máx.",
    ["Font Size"] = "Tamanho da fonte",
    ["Position"] = "Posição",
    ["Offset X"] = "Deslocamento X",
    ["Offset Y"] = "Deslocamento Y",
    ["Opacity"] = "Opacidade",
    ["Update Interval"] = "Intervalo de atualização",
    ["Show only in combat"] = "Mostrar somente em combate",
    ["Enable cursor display"] = "Ativar display do cursor",

    -- ===== Configurações do anel =====
    ["Ring Display Settings"] = "Configurações do display do anel",
    ["Size"] = "Tamanho",
    ["Base Radius"] = "Raio base",
    ["Ring Thickness"] = "Espessura do anel",
    ["Ring Spacing"] = "Espaçamento entre anéis",
    ["Appearance"] = "Aparência",
    ["Segments (smooth)"] = "Segmentos (suave)",
    ["Enable ring display"] = "Ativar display do anel",

    -- ===== Página de perfis =====
    ["Profile Manager"] = "Gerenciador de perfis",
    ["Active: "] = "Ativo: ",
    ["(active)"] = "(ativo)",
    ["Create New Profile"] = "Criar novo perfil",
    ["Copy From Profile"] = "Copiar de perfil",
    ["Export Current Profile"] = "Exportar perfil atual",
    ["(Press Export then Ctrl+C in the box)"] = "(Pressione Exportar e depois Ctrl+C na caixa)",
    ["Import Profile"] = "Importar perfil",
    ["Name:"] = "Nome:",
    ["(paste below and press Import)"] = "(cole abaixo e pressione Importar)",

    -- ===== Tooltip do minimapa =====
    ["Left click:"] = "Clique esquerdo:",
    ["Right click:"] = "Clique direito:",
    ["Drag:"] = "Arrastar:",
    ["open/close config"] = "abrir/fechar config",
    ["toggle cursor + ring icons"] = "alternar ícones cursor + anel",
    ["move icon"] = "mover ícone",

    -- ===== Mensagem de carregamento =====
    ["loaded"] = "carregado",
    ["Profile:"] = "Perfil:",
    ["Type"] = "Digite",
    ["for options"] = "para opções",

    -- ===== Rótulos da árvore de talentos =====
    ["Class"] = "Classe",
    ["Hero"] = "Herói",
    -- "Spec" permanece como está (já comum em pt-BR no contexto do jogo).

    -- ===== Changelog / What's New =====
    ["What's New"] = "Novidades",
    ["Got it"] = "Entendi",
    ["Changelog"] = "Registro de mudanças",
    ["View release notes for all versions"] = "Ver notas de versão de todas as versões",

    -- ===== Release notes 1.4.0 =====
    ["Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically."] =
        "Arraste trinkets ou poções da sua bolsa ou slots equipados para a área de entrada — o addon resolve automaticamente o spellID do efeito de uso.",
    ["Per-entry visibility for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility)."] =
        "Visibilidade por entrada para Cursor Spells e Auras: Sempre / Apenas em combate / Apenas fora de combate (independente da visibilidade global do cursor).",
    ["Per-entry visual overrides for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely)."] =
        "Sobrescritas visuais por entrada para Cursor Spells e Auras: tamanho do ícone, opacidade e posição personalizada com offset X/Y (o ícone sai do grid e flutua livremente).",
    ["Tabbed editor modals: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound."] =
        "Modais de editor com abas: Cursor Spell e Cursor Aura divididos em General / Display / Effects; Ring Aura em General / Effects; Pulse Spell e Pulse Aura em General / Sound.",
    ["Changelog button (?) in the config window title bar — opens this popup with all release notes on demand."] =
        "Botão Changelog (?) na barra de título da janela de configuração — abre este popup com todas as notas de versão sob demanda.",
    ["Fix: 'Spell not found' when adding via the autocomplete dropdown for spells/auras the character does not know. The autocomplete-resolved spell ID is now preferred over name lookup."] =
        "Correção: 'Magia não encontrada' ao adicionar via dropdown de autocompletar para magias/auras que o personagem não conhece. O spell ID resolvido pelo autocompletar agora tem prioridade sobre a busca por nome.",
    ["Fix: creating or switching profiles left some menus showing the old profile's values. Config pages are now rebuilt against the active profile on every switch."] =
        "Correção: criar ou trocar de perfil deixava alguns menus com os valores do perfil antigo. As páginas de configuração agora são reconstruídas contra o perfil ativo a cada troca.",

    -- ===== Release notes 1.5.0 =====
    ["Track items as cooldowns: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New 'Add Item...' button + drag-and-drop dispatches by type (spell vs item) and opens the right editor."] =
        "Rastrear itens como cooldowns: berloques, poções e consumíveis de uso agora podem ser adicionados à lista Cursor ou Pulse. Novo botão 'Add Item...' + arrastar-e-soltar despacha por tipo (magia vs item) e abre o editor correto.",
    ["Item editors with full tabs (mirror of the Spell editor): General + Display + Effects for cursor items; General + Sound for pulse items. Visual overrides, hide flags, pulse on ready, sound — all available."] =
        "Editores de itens com abas completas (espelho do editor de Magia): General + Display + Effects para itens do cursor; General + Sound para itens do pulse. Overrides visuais, hide flags, pulse ao ficar pronto, som — tudo disponível.",
    ["Per-entry instance-type filter on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP (Arena/BG), Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances."] =
        "Filtro por entrada de tipo de instância em todo editor de aura/magia/item: restringir o rastreamento a Mundo aberto, Cavernas, PvP (Arena/BG), Banda, Mítica+ e/ou Masmorra. Reage instantaneamente ao entrar/sair de instâncias.",
    ["Aura detection paths 6 + 7: slot iteration (catches semi-restricted auras Midnight hides from name/ID lookups) + manual trigger workaround (for fully-restricted auras like consumable buffs — configure a trigger spell or item ID and the addon synthesizes the ACTIVE state on cast/use)."] =
        "Caminhos de detecção de aura 6 + 7: iteração de slots (captura auras semi-restritas que Midnight oculta dos lookups por nome/ID) + workaround de gatilho manual (para auras totalmente restritas como buffs de consumíveis — configure um ID de magia ou item gatilho e o addon sintetiza o estado ACTIVE ao conjurar/usar).",
    ["New /hht listauras command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID of a buff when the guessed one isn't detected."] =
        "Novo comando /hht listauras: imprime todos os buffs/debuffs ativos com nome + spellID + origem + duração. Útil para encontrar o spellID real de um buff quando o adivinhado não é detectado.",
    ["Config window no longer closes when opening the Spellbook (PlayerSpellsFrame). ESC still closes it via a custom handler that doesn't break other keybinds."] =
        "A janela de config não fecha mais ao abrir o Grimório (PlayerSpellsFrame). ESC ainda a fecha via um handler personalizado que não quebra outros keybinds.",
    ["Fix: comparing SecureNumber spellId in slot iteration tainted the addon ('attempt to compare a secret number value'). Wrapped in ToPublic + pcall — fully restricted auras are skipped safely instead of crashing the whole frame."] =
        "Correção: comparar spellId SecureNumber na iteração de slots contaminava o addon ('attempt to compare a secret number value'). Envolvido em ToPublic + pcall — auras totalmente restritas são puladas em segurança ao invés de quebrar o frame inteiro.",
    ["Fix: ApplyRingVisibility nil call when a ring test entry expired (forward declaration bug, latent since 1.3.0)."] =
        "Correção: chamada nil de ApplyRingVisibility quando uma entrada de teste do ring expirava (bug de forward declaration, latente desde 1.3.0).",

    -- ===== Release notes 1.6.0 =====
    ["Macro trigger system: every aura, pulse, and item editor has a new 'Trigger key' field. Fire any configured display from a macro with /hht trigger <key> or from another addon via HNZHealingTools.Trigger(key). Multiple entries can share a key — one keybind fires them all at once."] =
        "Sistema de gatilho por macro: cada editor de aura, pulse e item agora tem um campo 'Trigger key'. Dispare qualquer display configurado de uma macro com /hht trigger <key> ou de outro addon via HNZHealingTools.Trigger(key). Várias entradas podem compartilhar uma key — um único keybind dispara todas de uma vez.",
    ["New Macros help page in the config sidebar with copy-pasteable macro examples and Lua snippets."] =
        "Nova página Macros na barra lateral da config com exemplos de macro e snippets Lua copiáveis.",
    ["Floating preview popup: 'Show preview' button at the top of pages with a Live Preview block (Cursor / Ring / Pulse settings + Cursor Ring sub-tabs). Opens to the right of the config window, single-active across pages, inherits position when switching."] =
        "Popup de preview flutuante: botão 'Mostrar preview' no topo das páginas que tinham bloco de Live Preview (Cursor / Ring / Pulse settings + sub-abas de Cursor Ring). Abre à direita da janela de config, único ativo entre páginas, herda a posição ao trocar.",
    ["Stack count now displays correctly for fully-restricted auras tracked by Blizzard's Cooldown Manager (e.g. Mana Tea). The addon now reads the stack count via the same SetText/GetText technique Blizzard's own CDM viewer uses, so SecureNumber values are no longer lost in combat."] =
        "Contagem de stacks agora aparece corretamente para auras totalmente restritas rastreadas pelo Cooldown Manager da Blizzard (ex. Chá de Mana). O addon agora lê a contagem via a mesma técnica SetText/GetText que o visualizador CDM da Blizzard usa, então valores SecureNumber não se perdem mais em combate.",
    ["Restricted auras visible in the Cooldown Manager but invisible to addon APIs now synthesize ACTIVE state from the CDM hook (stacks + appliedAt) — icon + count + optional timer render correctly even when all 6 detection paths fail."] =
        "Auras restritas visíveis no Cooldown Manager mas invisíveis para APIs de addon agora sintetizam estado ACTIVE pelo hook CDM (stacks + appliedAt) — ícone + contagem + timer opcional renderizam corretamente mesmo quando os 6 caminhos de detecção falham.",
    ["/hht auradebug now reports inCombat status, CDM-captured stack count, and the full list of FontStrings on the matching CDM frame — useful for diagnosing in-combat detection failures."] =
        "/hht auradebug agora reporta status de combate (inCombat), contagem de stacks capturada pelo CDM, e a lista completa de FontStrings no frame CDM correspondente — útil para diagnosticar falhas de detecção em combate.",
    ["Public API namespace _G.HNZHealingTools exposed for macros and other addons (.version, .Trigger(key))."] =
        "Namespace de API pública _G.HNZHealingTools exposto para macros e outros addons (.version, .Trigger(key)).",

    -- ===== Macros page + trigger UI =====
    ["Macros"] = "Macros",
    ["Trigger key:"] = "Chave do gatilho:",
    ["Show preview"] = "Mostrar preview",
    ["Optional. Fire this aura from a macro: /hht trigger <key>. Requires Duration > 0. Case-insensitive."] =
        "Opcional. Disparar esta aura de uma macro: /hht trigger <key>. Requer Duration > 0. Não diferencia maiúsculas.",
    ["Optional. Fire this pulse from a macro: /hht trigger <key>. Case-insensitive."] =
        "Opcional. Disparar este pulse de uma macro: /hht trigger <key>. Não diferencia maiúsculas.",
    ["Optional. Fire this item from a macro: /hht trigger <key>. Case-insensitive."] =
        "Opcional. Disparar este item de uma macro: /hht trigger <key>. Não diferencia maiúsculas.",
    ["Usage: /hht trigger <key>"] = "Uso: /hht trigger <key>",
    ["Triggered %d entrie(s) for key '%s'"] = "Disparada(s) %d entrada(s) para a chave '%s'",
    ["No entries match triggerKey '%s'"] = "Nenhuma entrada combina com triggerKey '%s'",
    ["Trigger displays from macros"] = "Disparar displays de macros",
    ["You can fire any aura or pulse from a macro, keybind, or another addon — without needing the actual aura/cooldown to trigger. Useful for one-shot visual signals (panic ring, cooldown reminder, callout from a partner addon)."] =
        "Você pode disparar qualquer aura ou pulse de uma macro, keybind ou outro addon — sem precisar que a aura/cooldown realmente dispare. Útil para sinais visuais pontuais (ring de pânico, lembrete de cooldown, aviso de um addon parceiro).",
    ["1. Where you can set a Trigger key"] = "1. Onde definir uma chave de gatilho",
    ["Open the editor of any of these and fill in the \"Trigger key\" field:"] =
        "Abra o editor de qualquer um destes e preencha o campo \"Chave do gatilho\":",
    ["  • Cursor Aura — fires the aura's icon at cursor for its Duration."] =
        "  • Cursor Aura — dispara o ícone da aura no cursor durante sua Duration.",
    ["  • Ring Aura — fires the colored ring around your character for its Duration."] =
        "  • Ring Aura — dispara o anel colorido ao redor do personagem durante sua Duration.",
    ["  • Cursor Item — fires the central pulse with the item's icon + optional sound."] =
        "  • Cursor Item — dispara o pulse central com o ícone do item + som opcional.",
    ["  • Pulse Spell / Pulse Aura / Pulse Item — fires the central screen pulse + optional sound."] =
        "  • Pulse Spell / Pulse Aura / Pulse Item — dispara o pulse central da tela + som opcional.",
    ["2. Fire it"] = "2. Dispare",
    ["From a chat message or macro line:"] = "De uma mensagem de chat ou linha de macro:",
    ["From Lua (other addons, /run, WeakAuras custom code):"] =
        "De Lua (outros addons, /run, código custom de WeakAuras):",
    ["Example: cast + trigger together"] = "Exemplo: cast + gatilho juntos",
    ["Combine a real cast with a visual trigger in one macro:"] =
        "Combine um cast real com um gatilho visual em uma só macro:",
    ["Tips"] = "Dicas",
    ["  • Multiple entries can share the same trigger key — they all fire at once (e.g. one key can show a Ring Aura + play a Pulse simultaneously)."] =
        "  • Várias entradas podem compartilhar a mesma chave de gatilho — todas disparam de uma vez (ex. uma chave pode mostrar Ring Aura + tocar um Pulse simultaneamente).",
    ["  • Trigger keys are case-insensitive. \"Panic\" and \"panic\" match the same entries."] =
        "  • Chaves de gatilho não diferenciam maiúsculas. \"Panic\" e \"panic\" combinam com as mesmas entradas.",
    ["  • Aura entries (Cursor / Ring) require Duration > 0 — without a duration there's no way to know when the visual should disappear."] =
        "  • Entradas de aura (Cursor / Ring) requerem Duration > 0 — sem duração não há como saber quando o visual deve sumir.",
    ["  • Pulse entries fire immediately and the animation has its own length (configured globally in Pulse → Config)."] =
        "  • Entradas de pulse disparam imediatamente e a animação tem duração própria (configurada globalmente em Pulse → Config).",
    ["  • HNZHealingTools.Trigger(key) returns the number of entries that matched (0 = no entries have that key)."] =
        "  • HNZHealingTools.Trigger(key) retorna a quantidade de entradas que combinaram (0 = nenhuma entrada tem essa chave).",
    ["  • Combat-safe: trigger keys work during combat lockdown."] =
        "  • Combat-safe: chaves de gatilho funcionam durante combat lockdown.",

    -- ===== Raid Spells (Alpha) =====
    ["Raid Spells"] = "Raide Magias (A)",

    -- ===== Simulated Auras (Coming Soon) =====
    ["Simulated Auras"] = "Auras simuladas (A)",
    ["Coming soon"] = "Em breve",

    -- ===== Ready Check Panel — talent loadout content type =====
    ["Dungeon / M+"] = "Masmorra / M+",
    ["No loadout assigned for %s"] = "Sem loadout atribuído para %s",
    ["Wrong talent build"] = "Build de talentos incorreto",

    -- ===== Release 1.9.0 notes =====
    ["Raid Spells (A): the panel now lists every healer in your raid who has the addon enabled, not just those who cast something in the last 5 seconds. Discovery is automatic via a hello protocol broadcast on group join and every 60s; stale entries are pruned after 3 minutes of silence."] =
        "Raide Magias (A): o painel agora lista todos os curandeiros do raide que têm o addon ativado, não apenas os que conjuraram algo nos últimos 5 segundos. A descoberta é automática via um protocolo hello transmitido ao entrar no grupo e a cada 60s; entradas obsoletas são removidas após 3 minutos de silêncio.",
    ["Raid Spells (A): each cast icon now shows a compact age label (5s / 2m / 1h) under it. Replaces the age-based alpha fade — the elapsed time is communicated explicitly."] =
        "Raide Magias (A): cada ícone de magia agora mostra uma etiqueta de tempo compacta (5s / 2m / 1h) abaixo. Substitui o fade alpha baseado em idade — o tempo decorrido é mostrado explicitamente.",
    ["Raid Spells (A): panel only shows inside a raid instance by default (it was incorrectly visible in the open world when in a raid group during world events / world bosses)."] =
        "Raide Magias (A): o painel só aparece dentro de uma instância de raide por padrão (era incorretamente visível no mundo aberto quando em grupo de raide durante eventos mundiais / chefes mundiais).",
    ["Raid Spells (A): drag works correctly — fixed a regression where the 0.5s refresh ticker re-anchored the panel mid-drag and snapped it back to the saved position."] =
        "Raide Magias (A): arrastar funciona corretamente — corrigida uma regressão onde o ticker de atualização de 0,5s reancorava o painel durante o arrasto.",
    ["Ready Check Panel: talent build row now shows an explicit warning when no loadout is assigned for the current content type (yellow text + red X) instead of a silent neutral state. Configure assignments in Config → Ready Check → Talents."] =
        "Painel Ready Check: a linha de build de talentos agora mostra um aviso explícito (texto amarelo + X vermelho) quando nenhum loadout está atribuído ao tipo de conteúdo atual. Configure as atribuições em Config → Ready Check → Talents.",
    ["Ready Check Panel: Dungeon and Mythic+ talent loadout categories merged into a single 'Dungeon / M+' checkbox. The ready check fires in the lobby before the keystone is inserted, so the distinction wasn't useful. Existing 'mplus=true' assignments still work as a synonym for 'dungeon'."] =
        "Painel Ready Check: as categorias de loadout Masmorra e Mítica+ foram fundidas em uma única caixa 'Masmorra / M+'. As atribuições 'mplus=true' existentes continuam funcionando como sinônimo de 'dungeon'.",
    ["Ready Check Panel: default panel width bumped 320 → 420px so the longer status texts (e.g. 'No loadout assigned for Dungeon / M+') no longer get clipped. Slider max raised to 700. Migration v6 auto-bumps profiles still on the old default."] =
        "Painel Ready Check: largura padrão aumentada de 320 → 420px para que textos de status mais longos não sejam cortados. Máximo do controle deslizante aumentado para 700. A migração v6 atualiza automaticamente perfis ainda no padrão antigo.",
    ["Ready Check Panel: removed the 'Use' button from the healthstone cell — healthstones are combat-only and the ready check fires out of combat, so the click did nothing. Icon + count remain to indicate you have stones."] =
        "Painel Ready Check: removido o botão 'Usar' da célula da pedra de saúde — pedras de saúde só funcionam em combate e o ready check ocorre fora de combate. Ícone + contador permanecem para indicar que você as possui.",
    ["Ready Check Panel: cauldron-cast Phial aura 1235108 added to the known flask aura list (was reported as missing)."] =
        "Painel Ready Check: a aura de frasco 1235108 (caldeirão) foi adicionada à lista de auras de frascos conhecidos.",
    ["Aura tracking: fixed the 'ring stays active after the buff expired' bug for spells with known durations (e.g. Barkskin). When the Cooldown Manager cache has a stale entry whose appliedAt + duration is in the past, we now evict it and report MISSING instead of leaving the ring lit indefinitely. Also clears the CDM cache on zone changes (PLAYER_ENTERING_WORLD full updates)."] =
        "Rastreamento de auras: corrigido o bug 'o anel permanece ativo após o buff expirar' para magias com durações conhecidas (ex. Pele de Casca). Quando o cache do Cooldown Manager tem uma entrada obsoleta cujo appliedAt + duration está no passado, ela agora é removida e reportada como MISSING. O cache CDM também é limpo em mudanças de zona.",
    ["Simulated Auras (A): new sidebar entry, currently 'Coming Soon'. The underlying state machine works via /hnzsim <spellID> and tracks an apply-then-consume aura pattern (for spells whose aura is hidden from the WoW API). UI integration with Cursor/Ring display is still in testing."] =
        "Auras simuladas (A): nova entrada na barra lateral, atualmente 'Em breve'. A máquina de estados funciona via /hnzsim <spellID> e rastreia um padrão de aura aplicar-então-consumir. A integração com a tela Cursor / Anel ainda está em testes.",
})
