local _, ns = ...

-- Traduções em português do Brasil (ptBR). As chaves são os textos em inglês
-- usados em ns.L[...]. Chaves ausentes caem para o inglês via metatable em Locales.lua.
ns.RegisterLocale("ptBR", {
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
})
