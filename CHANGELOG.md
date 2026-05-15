# Changelog

All notable changes to **HNZ Healing Tools** (formerly *SpellAuraTracker*) will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.5.0] — 2026-05-15

### Added
- **Item tracking en Cursor Spells y Pulse Spells**: ahora se puede trackear el cooldown de items (trinkets, pociones, on-use consumibles) además de spells. Las entries item-based usan el campo `entry.itemID` en lugar de `entry.spellID`; ambos tipos coexisten en la misma lista. La consulta de status se despacha vía `ns:GetEntryStatus(entry)` que internamente elige `GetSpellStatus` o el nuevo `GetItemStatus(itemID)` (que lee `C_Item.GetItemCooldown`, filtra el global item cooldown ~1.5s post-uso, y mapea status READY/COOLDOWN/UNUSABLE igual que las spells).
- **Botón "Add Item..."** en las páginas Cursor Spells y Pulse Spells, al lado del botón existente "Add Cursor/Pulse Spell". Abre un editor dedicado con tabs completos (mirror del Cursor Spell editor para Cursor Items: General + Display + Effects; mirror del Pulse Spell editor para Pulse Items: General + Sound). Skipea minCharges/talent (no aplican a items).
- **DropZone con dispatch por tipo**: arrastrar un spell sigue abriendo el editor de spell, arrastrar un item ahora abre el editor de item con el `itemID` precargado (en lugar de resolverlo al use-effect spell silenciosamente como antes). El comportamiento legacy se preserva en las pages de Auras (rings/cursor auras) que no soportan items.
- **Preview live en el editor de items**: al tipear/pegar un itemID, nombre o link, se renderiza icon + nombre + ID confirmado debajo del input para que el usuario vea qué item está agregando antes de guardar.
- **Filtro per-entry por tipo de instancia** (`Show only in:`): cada entry de Cursor Spell, Cursor Aura, Ring Aura, Pulse Spell, Pulse Aura, Cursor Item y Pulse Item puede restringirse a Mundo abierto, Delves, PvP (Arena/BG), Banda, Mítica+ y/o Mazmorra. Multi-select mediante checklist (3×2 grid). Empty/all-checked = sin restricción. Detección via `IsInInstance()` + `C_ChallengeMode.IsChallengeModeActive()` para distinguir M+ de mazmorra normal + `C_PartyInfo.IsDelveInProgress()` (con fallback por `difficultyID`) para delves. Cache invalidada en `PLAYER_ENTERING_WORLD`, `CHALLENGE_MODE_START/COMPLETED/RESET`, `ZONE_CHANGED_NEW_AREA` para que el filtro reaccione al instante. Badge en la fila de la lista cuando hay restricción (`@R/M+`).
- **Path 6 de detección de auras: slot iteration con ToPublic**. `FindAuraBySpellID` agrega como sexto fallback la iteración manual de `C_UnitAuras.GetAuraSlots` + `GetAuraDataBySlot`, comparando spellId via `ns.ToPublic` (que envuelve la conversión SecureNumber → public en pcall — comparar SecureNumber con `==` directo taintea toda la ejecución del addon). Captura auras "semi-restringidas" en Midnight: visibles en iteración pero suprimidas por los lookups por-ID/nombre.
- **Manual trigger workaround para auras "fully restricted"**: en Cursor Aura y Ring Aura editors, dos campos nuevos `Trigger spell:` y `Trigger item:` permiten al usuario configurar un disparador manual cuando los 6 paths de detección estándar fallan (típico en buffs de items consumibles de Midnight donde hasta el `spellId` es SecureNumber irrecuperable). Hooks instalados sobre `UseInventoryItem` (slots equipados), `UseContainerItem` global y `C_Container.UseContainerItem`, más `UNIT_SPELLCAST_SUCCEEDED` para player. Reverse lookup item→use-effect-spell vía `C_Item.GetItemSpell` para que una sola config "Item disparador=N" cubra los 4 modos de activar el item: hooks de bag/inventory directos, action bar (via UNIT_SPELLCAST_SUCCEEDED del use-effect spell), macros `/use`, y trinket slots. Sintetiza `status="ACTIVE"` con `manualDuration` configurada.
- **Comando `/hht listauras [unit]`**: lista todos los buffs/debuffs activos en el unit (default player) con name + spellID + source + duración + remaining. Útil para encontrar el spellID real de un buff cuando el ID adivinado no se detecta. Usa `C_UnitAuras.GetAuraSlots`/`GetAuraDataBySlot` con `tostring()` defensivo (que no taintea sobre SecureNumbers, a diferencia del `==`).
- **`/hht auradebug` enriquecido**: ahora reporta el estado del manual trigger (config + última activación + segundos transcurridos), el resultado final de `GetAuraStatus` aunque `FindAuraBySpellID` falle (para visibilizar la sintetización del path 7), y la elegibilidad del aura para el Cooldown Manager de Blizzard (eligible/configured) con hint apropiado para guiar al usuario hacia configurar el viewer correcto.
- **Helper `InfoHint(parent, tooltipText)`** reusable: ícono `(?)` clickable que muestra un tooltip al hover. Aplicado al campo "Duración" para explicar que algunas auras no exponen su tiempo via API y necesitan duración manual; y a los campos "Trigger spell/item" para explicar el workaround.

### Changed
- **Ventana de config ya no se cierra al abrir el libro de hechizos**: removido el registro en `UISpecialFrames` que provocaba el cierre cuando Blizzard abría el `PlayerSpellsFrame`. Reemplazado con un handler `OnKeyDown` propio que captura ESC con `SetPropagateKeyboardInput(false)` (otras teclas siguen propagando para que casts/keybinds no se rompan). El usuario puede ahora arrastrar spells/items desde el spellbook abierto sin perder la ventana del addon.
- **`SpellRow` y `PulseSpellRow` mixed-type rendering**: las filas de la lista distinguen automáticamente entries de spell vs item (badge verde "Item", icon resuelto via `GetItemDisplayInfo`, label `ItemID:` en lugar de `ID:`).
- **Editores con tabs altos**: bumpeadas las dimensiones de Cursor Spell (440→500), Cursor Aura (460→520), Ring Aura (440→540) y Pulse Spell/Aura (290/300→360/380) para acomodar los nuevos campos sin sacrificar densidad.

### Fixed
- **`ApplyRingVisibility nil call`** en `RingDisplay.lua:136`: bug pre-existente (forward reference). `UpdateRings` referenciaba `ApplyRingVisibility` antes de su declaración (línea 195), resolvía a global nil y explotaba en la transición test→no-test del ring (cuando el botón Test de una entry expiraba). Solo se manifestaba con frecuencia desde 1.5.0 porque `MarkAuraDirty` se llama más seguido (cada `UNIT_SPELLCAST_SUCCEEDED` del player). Fix: forward declaration de `ApplyRingVisibility` antes de `UpdateRings`.
- **Comparación de SecureNumber en path 6 (`FindAuraBySpellID`)**: `data.spellId == spellID` directo taintaba la ejecución del addon ("attempt to compare field 'spellId' (a secret number value)") cuando se iteraba sobre auras restringidas (Ascensión de Shaman, buffs de items). Reemplazado por `ns.ToPublic(data.spellId)` con guardia de nil. Auras fully restringidas no matchean (correcto — caen al manual trigger), semi-restringidas sí (path 6 funciona).
- **`ListAuras` mostraba todos los campos como nil/0**: la signature de `AuraUtil.ForEachAura` por defecto pasa al callback los valores desempaquetados (`name, icon, count, ...`), no el AuraData table. Reescrita para usar `GetAuraSlots` + `GetAuraDataBySlot` directo (ruta confiable que devuelve siempre el table); fallback a `ForEachAura` con `usePackedAura=true` si la API directa no está.
- **Window stuck en error loop**: cuando `data.spellId` era SecureNumber irrecuperable y la comparación tainteaba, el frame quedaba marcado como tainted permanentemente y los siguientes ticks re-disparaban el error (las "426x" del bug report). Mismo fix de path 6 con `ToPublic` resuelve la cadena.
- **Símbolo `ⓘ` aparecía como rectángulo** en el InfoHint: el cliente WoW no incluye el glifo Unicode U+24D8 en su fuente default. Reemplazado por `(?)` ASCII puro que renderiza en cualquier fuente/locale.

---

## [1.4.0] — 2026-05-14

### Added
- **Drag items to the spell input zone**: trinkets, potions y otros items con `Use:` se pueden arrastrar desde la bolsa o slots de equipo a la zona "Drag a spell or item here". El addon resuelve el spellID del use-effect via `C_Item.GetItemSpell` (con fallback a `GetItemSpell` legacy) y lo pasa al callback igual que un drop de spell. Funciona en todos los editors que tienen DropZone (Cursor / Ring / Pulse).
- **Per-entry visibility para Cursor Spells y Auras**: cada entry tiene su propio gate `visibility` (Always / Only in combat / Only out of combat) independiente del visibility global de `cursorDisplay`. Editado desde el dropdown "Visibilidad" en el tab General de cada editor; filtrado en `CursorDisplay.UpdateData` via `ns.MatchesVisibility(entry.visibility, inCombat)`. Default `"always"` para entries existentes (sin migration). Eventos `PLAYER_REGEN_*` marcan dirty para que la transición sea instantánea (sin esperar el idle-poll de 1Hz).
- **Per-entry visual overrides para Cursor Spells y Auras**: cada entry puede override del global `iconSize`, `opacity`, y `useCustomPosition` + `offsetX/Y`. Cuando `useCustomPosition=true` el icono se desconecta del grid layout y se ancla al cursor + offset (permite "trinket arriba, healing CDs en grid abajo"). El `displayFrame` se forzó a alpha 1 para que el opacity per-entry sea absoluto y no se multiplique por el global del padre. CursorDisplay.UpdateData ahora separa iconos en buckets grid vs detached para el pass de layout.
- **Tabs en los editor modals**: Cursor Spell y Cursor Aura divididos en 3 tabs (General / Display / Effects); Ring Aura en 2 (General / Effects); Pulse Spell y Pulse Aura en 2 (General / Sound). Helper nuevo `CreateModalTabs(parent, tabNames)` reutilizable. Reduce el scroll vertical y agrupa controles relacionados.
- **Botón Changelog (?)** en la barra de título de la ventana de config. Abre el popup `WhatsNew` con todas las release notes en cualquier momento (no solo durante upgrades). Tooltip "Changelog" (localizado).
- **Release notes localizadas**: los items de cada release ahora pasan por `ns.L[...]`, así que las traducciones en cada locale file aplican. Spanish traducido para 1.4.0; otros locales caen al texto en inglés via la metatable de `ns.L`.

### Changed
- **Layout de los editors numéricos**: parámetros visuales continuos (icon size, opacity, offset X/Y) usan sliders con label arriba y valor en accent — mismo helper `CreateSlider` que usa la config global. Parámetros con valor numérico específico (min charges, min stacks, duration en segundos, stack text size) usan text input directo. La distinción es: slider cuando el feedback visual del rango aporta, text input cuando el usuario ya sabe qué número quiere ingresar.
- **Specs y Required talent movidos al tab General** en Cursor Spell y Cursor Aura editors (antes estaban en Effects).
- **Stack text size layout fix**: cada par label-input ahora va en su propia fila en línea (`label: [input]` mismo y), en lugar del cramped "label en una línea, input + label-siguiente en la línea de abajo".

### Fixed
- **"Spell not found" al agregar desde el autocomplete**: cuando el usuario seleccionaba una sugerencia del dropdown del autocomplete y apretaba **Add**, el editor llamaba a `Add*Spell/Aura(input)` pasando solo el texto. `GetSpellIDFromInput(name)` falla con hechizos/auras que el personaje no conoce (típico para buffs/debuffs de otras clases o use-effects de items). Ahora los handlers de Save prefieren `ns.GetResolvedSpellID(eb)` que lee el `spellID` cacheado por el OnClick del autocomplete (`eb._satResolvedID`); si existe, se pasa como string numérico al Add* y el path de `tonumber(input)` resuelve el ID directo. Aplicado a Cursor Spell, Cursor Aura, y Ring Aura editors. Pulse editors ya lo hacían.
- **Crear o cambiar perfil dejaba algunos menús con valores del perfil anterior**: las páginas del config se construían una sola vez al abrir la ventana, y muchos widgets cacheaban upvalues del perfil activo en ese momento (`local cast = ns.db.cursorRing.cast`, `ColorSwatch.ct` con la tabla del color). Al hacer SwitchProfile, `ns.db` se rebindeaba pero esos upvalues seguían apuntando al perfil viejo — el usuario veía y escribía al perfil incorrecto. Refactor: se extrajo el page-build loop en una función `BuildAllPages()` y se agregó `RebuildAllPages()` que orfaniza las páginas viejas, resetea los file-scope locals (spell/aura/mrt/pulse list containers), wipe `allSliders/allCheckboxes`, y vuelve a buildear contra el `ns.db` actual. Llamado desde Load / Copy-to-current / Restore-from-backup.

---

## [1.3.0] — 2026-05-13

### Added
- **Live preview in config**: cada modulo (Ring / Pulse / Cursor Ring / Cursor Icons) muestra un preview animado al pie de su pagina de Config con datos de muestra renderizados con los settings actuales. Cualquier slider/dropdown actualiza el preview al instante.
- **Reorder en Cursor Spells / Cursor Auras**: flechas arriba/abajo por fila para mover entries en la lista (define el orden en que aparecen junto al cursor). Texturas custom incluidas en `Textures/arrow_up.tga` (TGA 64x64, antialiased).
- **Boton Test (T) por entry de Cursor**: fuerza al icono a aparecer junto al cursor real durante 5 segundos para previsualizar como va a verse en juego. Bypass de todos los gates (display disabled / out-of-combat / lista vacia).
- **Ventana de config redimensionable**: drag handle en la esquina inferior derecha permite cambiar el tamano manualmente. Min 720x420, max 1600x1080. Tamano se persiste en `db.configWindow` por profile.
- **What's New popup**: al instalar una version nueva, aparece una sola vez al login con las notas de la version. Estado persistido account-wide en `HNZHealingToolsDB.lastSeenVersion`.

### Changed
- **Selector de formato MRT/NSRT en el editor de notas**: el dropdown se reemplazo por dos botones tipo radio (NSRT a la izquierda, MRT a la derecha). El boton activo se resalta con el color de acento. NSRT pasa a ser el default al crear una nota nueva — alineado con el flujo mas comun (pegar nota de NSRT con header `EncounterID:` y dejar que el auto-detect llene ID y Name).

### Fixed
- **Pulse de MRT/NSRT no aparecia cuando la visibility del Cooldown Pulse no era `always`**: el bypass que pasa MrtTimeline a `ShowPulse` saltaba solo el toggle `enabled` del modulo, pero no el gate de visibility (`combat` / `ooc`). Si el usuario tenia `cooldownPulse.visibility = "combat"` (default de perfiles migrados desde `showOnlyInCombat = true`) y probaba la nota fuera de combate con el boton Test, el pulse nunca aparecia. Ahora `bypassEnabled = true` saltea ambos gates — MRT/NSRT solo dispara durante encounters (in-combat por definicion) y la checkbox "Show MRT/NSRT triggers" del modulo Pulse es opt-in explicito del usuario.

---

## [1.2.2] — 2026-05-11

### Changed
- **Interface version `120001` → `120005`**: bumpeada para matchear el cliente actual de Retail (parche 12.0.5). Sin este bump el addon aparece "Out of date" en el listado in-game y los usuarios necesitan tildar "Load out of date AddOns" para que cargue. Sin cambios funcionales.

---

## [1.2.1] — 2026-05-11

### Fixed
- **Cliente de Wago no reconocía el addon instalado**: faltaban las líneas `## X-Curse-Project-ID:` y `## X-Wago-ID:` en el `.toc`. Sin ellas, el cliente de Wago crea la carpeta al instalar pero no la matchea con el proyecto en wago.io, así que el addon no aparece en el listado de instalados. Agregadas ambas referencias al `.toc`.

---

## [1.2.0] — 2026-05-11

### Added
- **Filtro de dificultad por nota MRT/NSRT** — cada nota declara en cuáles dificultades aplica via 4 checkboxes (LFR / Normal / Heroico / Mítico) en el editor. En `ENCOUNTER_START` el matcher filtra por la dificultad actual del raid/dungeon además del encounterID, así podés tener varias notas para el mismo jefe (una por dificultad) y solo dispara la que corresponde. Notas viejas sin filtro aplican a cualquier dificultad (backwards-compat). Badge `[R/N/H/M]` en cada row del listado cuando hay filtro activo.
- **Toggle manual de activación por nota** — checkbox a la izquierda de cada row en MRT/NSRT → Encounters. Permite activar/desactivar una nota sin abrir el editor ni borrarla — pensado para alternar entre notas según compo del raid. Row deshabilitada se muestra dim. `FindNoteForEncounter` salta notas con `enabled=false`.
- **Soporte de múltiples notas para el mismo encuentro** — antes solo se usaba la primera match por ID; ahora con difficulty filter + enabled toggle podés tener varias variantes del mismo boss y el runtime elige la correcta. El botón "Test" ahora usa el índice exacto de la fila (no el encounterID) para previsualizar la nota específica que clickeaste.

### Changed
- **Carga lazy del `Blizzard_EncounterJournal`** desde `GetEncounterDisplay` la primera vez que se necesita info de un encuentro — sin esto el journal podía devolver datos parciales para algunos jefes hasta que el usuario lo abría manualmente, lo que causaba portraits/raid names faltantes en el listado.
- **`MrtTimelineTest(noteIndex)`** — refactor: ahora recibe el índice de la nota en lugar del encounterID. Necesario para distinguir entre varias notas con el mismo ID en distintas dificultades.

### Removed
- **Página de Créditos** — eliminada del sidebar de configuración. Removida la función `BuildCreditsPage`, su entry en `pageDefs`, y las 13 traducciones esES exclusivas de esa página.

---

## [1.1.0] — 2026-05-10

### Added
- **Credits page** in the config window (last tab in the sidebar). Lists the reference addons (CursorRing, CDPulse, MRT, NSRT — Northern Sky Raid Tools, Classic WeakAuras) and optional library (LibSharedMedia-3.0). Each entry shows a copyable URL.
- **MRT / NSRT Timeline Reminders** — nuevo módulo que parsea notas de Method Raid Tools y Northern Sky Raid Tools, filtradas a tu nombre, y muestra recordatorios cerca del cursor / en un anillo / como pulse cuando se acerca el momento de castear cada hechizo. Características:
  - Parser dual MRT (`{time:M:SS.t} - Nombre {spell:N}`) + NSRT (`time:N;tag:Nombre;spellid:N`)
  - Lista de notas por encuentro: cada nota asociada a un `EncounterID` específico (o 0 = cualquiera). Auto-detección del ID/Nombre del header NSRT al importar.
  - Integración con Encounter Journal: portrait del jefe + nombre de la raid/dungeon en cada fila, autocomplete por nombre del jefe en el campo ID.
  - Modal de importación con selector de formato (MRT/NSRT), autocomplete, validación.
  - Modal "View" que muestra todas las entries parseadas (tiempo + ícono + nombre del spell + ID).
  - State machine por entry: `PRE` (countdown 3,2,1 con ícono dim), `ACTIVE` (ícono saturado, ventana configurable), `CONSUMED` (cast detectado via `UNIT_SPELLCAST_SUCCEEDED`).
  - Tres integraciones visuales seleccionables: cursor (íconos stackeados), ring (anillo segmentado con progress alrededor del jugador), pulse (one-shot en trigger).
  - Sonido configurable al trigger (LibSharedMedia-aware) con canal seleccionable.
  - Botón "Test pull" para simular un encuentro con cualquier nota.
- **Cursor Ring → Dot effects:**
  - Mouse trail con color, longitud (lifetime) y visibilidad propia (always/combat/ooc) configurables.
  - Sparkle effect con color, tamaño, forma (dot, ring fino, ring grueso, wedge, mixed = random por spawn) y visibilidad propia.
  - Path-fill: cuando el cursor se mueve rápido, los sparkles ahora interpolan a lo largo del path en vez de dejar gaps grandes en el rastro lejano.
- **Sistema de migraciones versionado** con backup automático pre-migración (`HNZHealingToolsDB.profileBackups[name]`). UI "Restore from backup" en la página Profiles permite revertir si una migración futura tiene un bug.
- **Visibility dropdown** (Always / Only in combat / Only out of combat) reemplaza al viejo checkbox "Show only in combat" en cada feature. Aplica también a sub-features nuevas (trail, sparkle, grow on movement).

### Changed
- **Esquema de savedvars v2 → v3**: campo `showOnlyInCombat` (boolean) migrado a `visibility` (enum); `mrtTimeline.noteText` (string única) migrado a `mrtTimeline.notes` (lista por encuentro). Migración corre una sola vez por perfil con backup automático.
- **Ancho de la ventana de configuración**: 760px → 900px. Columnas reposicionadas (C1 16→20, C2 260→340) para acomodar labels largos en esES y dropdowns de visibilidad.
- **Bootstrap per-character**: cuando un alt no tiene perfil propio, ahora copia del legacy account-wide profile o del primer perfil existente (alfabético), en vez de crear defaults frescos. Evita "todos mis perfiles dejaron de funcionar" en multi-char.
- **Cursor Ring → Dot page**: secciones separadas con sub-headers ("Center dot", "Grow dot when moving", "Effects"). Checkbox de Grow renombrado a "Habilitar" ahora que el header indica la sección.
- **Migración de todos los perfiles al login** (no solo el activo): evita que `SwitchProfile` mid-sesión dispare migración con potencial bug.

### Fixed
- **Pulse falso después de Roll / channel / stun**: removido el fallback `IsSpellUsable` que marcaba `COOLDOWN` por cualquier estado transitorio (Roll de Monk, channeling, stun, GCD). Causaba que al terminar el estado transitorio el spell volviera a "READY" y disparara pulse como si su cooldown acabara de terminar. Los cooldowns reales se siguen detectando via `C_Spell.GetSpellCooldown` con filtro `isOnGCD`; los estados transitorios ahora caen al check de `UNUSABLE` posterior, y `UNUSABLE → READY` no dispara pulse.
- **SoundPicker no persistía la selección sin presionar "Apply"**: ahora `SoundPicker` acepta callback opcional `onChange` que se dispara al seleccionar desde el popup. MRT lo usa para guardar en savedvars al instante.

### Removed
- **Ocultar cursor de Blizzard**: feature descartado tras confirmar que la API restringe esto desde Wrath 3.0.6 (anti-botting). `SetCursor` no tiene efecto sobre `WorldFrame`. Ningún addon público lo logra. Removidos: `BlizzardCursor.lua`, `Textures/transparent.tga`, checkboxes asociados.

## [1.0.28] — 2026-05-09

### Changed
- **Renamed addon** from *SpellAuraTracker* to **HNZ Healing Tools**. Folder, TOC, slash commands, all frame names, texture paths and saved-variable globals updated. The old `SpellAuraTrackerDB` / `SpellAuraTrackerCharDB` are NOT migrated — config starts fresh under `HNZHealingToolsDB` / `HNZHealingToolsCharDB`.
- **New slash commands**: `/hht` (primary) and `/hannzoo`. The old `/sat` and `/spellaura` are gone.
- **Cursor Ring texture labels** dropped the `(SAT)` suffix (now just `Thin Ring — 2 px`, `Ring — 6 px`, etc.).
- TOC `## Notes` rewritten to mention the actual feature set (cursor icons + ring auras + central pulse + cursor ring + cast progress) instead of just spells/auras.

## [1.0.27] — 2026-05-09

### Fixed
- **Green square next to spell name when sound was enabled** in Pulse rows. The badge was the `♪` character (U+266A) tinted teal — the in-game font doesn't carry that glyph in some locales, so it rendered as a coloured placeholder square. Replaced both Pulse-row badges and the Cursor-row legacy `Pulse♪` badge with the inline atlas `|A:voicechat-icon-speaker:14:14|a`, which always renders as a proper speaker icon.
- **Preview button in the SoundPicker** also showed `♪`; changed to a plain `>` glyph.
- Removed the now-unused `["♪"] = "♪"` entry in `esES.lua`.

## [1.0.26] — 2026-05-09

### Fixed
- **Solid green square instead of the spell icon** in the Cursor / Ring / Pulse lists. `C_Spell.GetSpellInfo(id)` can return an `info` table with `iconID = 0` for spells/auras the player doesn't currently know (e.g. enemy debuffs the user adds by ID), and `Texture:SetTexture(0)` leaves the texture empty — the WoW renderer fills the cleared texture slot with a solid color (green here) instead of falling back to anything sensible.
- `ns.GetSpellDisplayInfo` now retries with `C_Spell.GetSpellTexture(id)` (a more direct lookup) when `iconID` comes back as 0 / nil, and only falls back to the question-mark default (134400) if both lookups fail.
- Migrated the inline `info=C_Spell.GetSpellInfo(...); ic=info and info.iconID or 134400` pattern in `SpellRow`, `CursorAuraRow` and `RingAuraRow` to the helper, so all three list types benefit from the same robust fallback.

## [1.0.25] — 2026-05-09

### Changed
- **Pulse list rows — Edit/Remove buttons now match the Cursor/Ring rows visually**: a teal gear icon (`Interface\GossipFrame\BinderGossipIcon` tinted with the SAT accent) for Edit and a red **X** glyph for Remove, both with hover highlight and tooltip. Replaces the plain `MakeButton` text glyphs that were rendering inconsistently across some clients.
- Extracted the small builder into a local `AddRowEditRemoveButtons(row, entry, onRemove, onEdit)` reused by `PulseSpellRow` and `PulseAuraRow`.

## [1.0.24] — 2026-05-09

### Fixed
- **"Spell not found" after picking from autocomplete**. `C_Spell.GetSpellInfo(name)` resolves only spells the player currently knows, so picking a name the player hasn't learned (debuffs, enemy auras, talent-locked spells) failed even though the autocomplete clearly listed it. The autocomplete now stores the chosen `spellID` on the EditBox (`_satResolvedID`) and Pulse editors prefer that ID over the typed text — and reset it the moment the user edits the text further. Exposed `ns.GetResolvedSpellID(eb)` so other editors can reuse the same path.
- **Autocomplete popup tall enough to cover the modal buttons**. The popup had a fixed 220 px height regardless of how many suggestions it showed. Switched to dynamic sizing: `min(220, content + 12)`, so a popup with three matches is small and stops obscuring the Save/Cancel/Test row underneath.

## [1.0.23] — 2026-05-09

### Fixed
- **Pulse Aura editor crashed on open** with `bad argument #1 to 'ipairs' (table expected, got nil)` inside the unit dropdown. `PULSE_UNITS` / `PULSE_FILTERS` were declared further down in the file than `CreatePulseAuraEditor`, so the closure resolved them as a missing global instead of an upvalue. Moved the two tables next to `SOUND_CHANNEL_OPTIONS`, before the modal editor closures.

## [1.0.22] — 2026-05-09

### Added
- **Pulse modal editors** — Pulse Spells and Pulse Auras now use dedicated modal dialogs to add/edit entries (matching the Cursor and Ring tabs). Each modal includes:
  - Spell name/ID input with the same live autocomplete as the rest of the addon.
  - **Sound** toggle, **sound picker** (LSM + curated SAT list, same widget as the cursor pulse) and **Test** button to preview right from the editor.
  - **Channel selector** (Master / SFX / Music / Ambience / Dialog) — saved per entry as `entry.soundChannel` and forwarded all the way through `ns:ShowPulse → ns.PlayAuraSound → PlaySound/PlaySoundFile`. Existing entries default to `Master`.
  - For Pulse Auras, also **Unit** and **Filter** dropdowns.
- `ns.SOUND_CHANNELS` exported for any external integration.

### Changed
- **Pulse list rows simplified**: now show icon + name + ID + inline badges (`[unit][buff/debuff]` for auras, `♪` when sound is enabled) plus an Edit (✎) and Remove (×) button. All editing — sound, channel, unit, filter — happens inside the modal, so the row stays narrow and icons no longer get clipped regardless of window width.
- The Add inline input (with `Spell not found:` feedback that was being truncated) is replaced by a single **Add Pulse Spell…** / **Add Pulse Aura…** button that opens the modal — same pattern Cursor and Ring already used.

## [1.0.21] — 2026-05-09

### Changed
- **Config window** widened from 680 to 760 px to give Pulse Spells / Pulse Auras rows enough horizontal room for icon + name + dropdowns + sound checkbox + remove button without clipping.

### Fixed
- **Pulse Add → "Spell not found" feedback was truncated** to a stub like *"spell no"*. The message lived to the right of the Add button and was crushed by the auto-complete dropdowns. Moved it to its own line below the input row, with `SetWordWrap` so long names/IDs wrap instead of being cut.
- **Pulse rows clipping the right-side icons**. Two causes fixed together:
  - The `ScrollList` scroll-child was hard-coded to 500 px wide. Now it syncs to the real `ScrollFrame:GetWidth()` via `OnSizeChanged`.
  - `PulseSpellRow` / `PulseAuraRow` used `SetSize(parent:GetWidth() - 16, ...)` at build time, so they kept the old width even after the ScrollList grew. Replaced with `SetHeight(32)` plus `SetPoint("RIGHT", parent, ...)` so each row tracks the parent width automatically.

## [1.0.20] — 2026-05-09

### Added
- Two extra cursor-ring textures: **Thicker (14 px)** and **Thickest (18 px)**. The Texture picker now offers a continuous progression of six SAT-owned thicknesses (2 / 4 / 6 / 10 / 14 / 18 px), each labeled with its stroke width. All share the same outer radius (62/128 of the canvas) so swapping between them only changes the line weight.
- Helper `ResolveTexture()` that maps an unknown texture path (e.g. a Blizzard built-in retired in this version) back to the default SAT ring, applied on every `RefreshCursorRing` so older saved profiles auto-migrate without showing an empty dropdown.

### Changed
- **Cursor Ring → Texture picker** label is now **"Texture & thickness"** with a small inline note "Each option uses a different stroke width", since the dropdown effectively controls both visual style and ring thickness now that all options are SAT rings.

### Removed
- Blizzard built-in textures from the Cursor Ring picker (Tracking Border, Ring Border, Cooldown Edge, Cooldown Edge LoC). They were sub-optimal for cursor use (atlas sprites with off-axis centers needing calibration); the six SAT rings cover the same range cleanly. Profiles still pointing to those paths get rewritten to `Ring (SAT) — 6 px` on the next refresh.

## [1.0.19] — 2026-05-09

### Added
- Two extra cursor-ring textures: **Medium Ring (SAT)** (4 px stroke) and **Thick Ring (SAT)** (10 px stroke). Together with the existing **Thin** (2 px) and **Ring** (6 px) you now get four discrete thicknesses, all sharing the same outer radius (62/128 of the canvas) so they're freely interchangeable from the Texture picker without needing to re-tune the Size slider. Texture rendering is still 1 quad per frame — significantly cheaper than a 96-line vector ring would be.

### Removed
- The `Ring thickness` slider and the vector-Lines code path introduced in 1.0.18. Lines didn't render reliably in this case and the texture approach is faster (1 draw call vs 96). The `cursorRing.thickness` saved-variable key is no longer read.

## [1.0.18] — 2026-05-09

### Added
- **Cursor Ring — variable ring thickness**. New `Ring thickness` slider (0–24 px) on the Cursor Ring page. When set above 0 the base ring is rendered as a 96-segment vector ring (`CreateLine` + `SetThickness`) instead of the texture, so the stroke width is fully decoupled from the diameter. The stroke is centered on `radius = (size − thickness)/2`, so the outer edge stays aligned with the existing `Size` slider. Set to 0 (default) to keep the previous texture-based rendering and the texture picker. Texture-atlas calibration (`fracX/fracY`) is bypassed in vector mode since the line geometry is exactly centered on the frame.

## [1.0.17] — 2026-05-09

### Added
- **Cursor Ring — center dot**: optional small dot rendered at the cursor center, with its own size slider (1–32 px) and color picker. New `Textures/dot.tga` (64×64 anti-aliased filled circle). Independent of the decorative ring and cast ring — any combination of the three sub-features can be enabled.
- **Cast progress ring — absolute size slider**: replaces the previous *Cast separation* offset. The cast sub-frame now reads `cast.size` directly (8–256 px), so the cast ring radius is fully independent of the base ring size. The legacy `cast.separation` saved-variable key is ignored (no migration needed; existing profiles fall back to the default 48 px and can be retuned).

### Changed
- The cursor ring frame now stays visible if **any** of base ring / cast ring / center dot is enabled, so the cast ring or the dot can be used standalone without forcing the decorative ring on.

## [1.0.16] — 2026-05-09

### Added
- **Cast progress ring — separation and opacity sliders**. The 180 wedges now live in their own sub-frame inside the cursor ring, so they can be drawn at a different radius than the decorative ring without any texture work. New controls in the Cursor Ring page:
  - **Cast separation** (-32…+32 px): radial offset relative to the base ring — positive pushes the cast ring outward, negative pulls it inward, 0 keeps both concentric.
  - **Cast opacity** (0.10…1.00): independent alpha for the cast progress, so it can be subtler or more prominent than the decorative ring.

## [1.0.15] — 2026-05-09

### Added
- **Cast progress ring** (Cursor Ring): optional sub-ring that shows player cast / channel progress around the cursor. Built from 180 rotated copies of a new `Textures/cast_wedge.tga` (2° annular wedge); the first `floor(progress * 180)` are lit per `OnUpdate`, giving a clean clockwise sweep starting at 12 o'clock. Driven by `UNIT_SPELLCAST_START / STOP / FAILED / INTERRUPTED / CHANNEL_START / CHANNEL_STOP`. Channels animate in reverse (full → empty) to match Blizzard's cast bar convention. Opt-in checkbox + color picker in the **Cursor Ring** config page; works independently of the decorative ring (you can run only the cast ring with the base ring disabled).

## [1.0.14] — 2026-05-09

### Changed
- **Cursor Ring** now ships with two own anti-aliased ring textures (`Textures/ring.tga`, `Textures/thin_ring.tga`) drawn at 128×128 with a transparent background and a clean white stroke. The default texture switched from Blizzard's `MiniMap-TrackingBorder` (a square atlas sprite that needed off-axis calibration) to the new `Ring (SAT)`. The Blizzard built-ins are still selectable from the Texture picker. Both new textures are MIT-licensed alongside the rest of the addon.

## [1.0.13] — 2026-05-08

### Fixed
- **Checkbox visual stayed unchecked after click** (Cursor Ring page and elsewhere). The skinned checkmark relied on `hooksecurefunc(SetChecked)` and `HookScript("OnClick")`, neither of which is reliably triggered by the C++ click toggle of `CheckButton` once a `SetScript("OnClick", ...)` is set later by the call site. Switched to `PostClick`, which always fires after the click handler regardless of whether/when `OnClick` is replaced.

## [1.0.12] — 2026-05-08

### Changed
- **Internal cleanup** (no behavior change): trimmed cursor-ring `OnUpdate` hot path (cached UI scale, frame size, calibration and offsets so each frame only does the position math). Cooldown-pulse poll now early-exits when the three pulse lists are empty, caches per-aura keys via weak table to avoid per-tick string concatenation, and `Test` button prefers the new `pulseSpells` list. Autocomplete no longer recomputes `name:lower()` on every keystroke (precomputed once in `GetPlayerSpells`) and only hides previously-shown rows. Pulse list `UNITS`/`FILTERS` and the `RefreshAll*` triple-call were extracted; new `ns.GetSpellDisplayInfo` helper replaces a duplicated local in the Pulse rows.

## [1.0.11] — 2026-05-08

### Fixed
- Rows in Cursor Spells / Cursor Auras / Ring Auras were getting clipped on the right side, hiding the Edit (✎) and Remove (×) buttons. Caused by a 16-pixel reduction in the scroll-child width introduced with the subtab refactor in 1.0.8.

## [1.0.10] — 2026-05-08

### Added
- **Spell autocomplete on Pulse inputs** — the Add field on both Pulse Spells and Pulse Auras now shows the same live spell-name suggestions popup that already exists on Cursor and Ring editors.

## [1.0.9] — 2026-05-08

### Added
- **Pulse — independent Spells and Auras lists**: Pulse now has its own `Spells` and `Auras` sub-tabs, each with its own list (independent from Cursor Spells / Cursor Auras). Add any spell to fire a central icon pulse when its cooldown ends, or any aura to fire a pulse when gained. The legacy per-cursor-entry `cdPulse` flag still works for backwards compatibility.

### Fixed
- **Cursor Ring centering** — the `MiniMap-TrackingBorder` texture is part of an atlas and its visual center is offset from the texture center, which made the ring drift when offsets were 0/0. Each texture in the picker now declares an internal calibration so `Offset X/Y = 0/0` always means *centered on the cursor*, regardless of the chosen texture. The position sliders are now reserved for fine-tuning.

## [1.0.8] — 2026-05-08

### Changed
- **Config sidebar reorganized**: Cursor (Spells / Auras / Config), Ring (Auras / Config), Pulse, Cursor Ring, Profiles. Sub-pages within Cursor and Ring now appear as horizontal sub-tabs.

### Added
- **Cursor Ring** more options:
  - Offset X / Y sliders (anchor offset relative to the cursor).
  - Show only in combat checkbox.
  - Use class color checkbox (overrides the color picker with the player class color).
  - Texture picker dropdown — choose between several built-in Blizzard textures.

## [1.0.7] — 2026-05-08

### Added
- **Cursor Ring** — optional decorative ring that follows the mouse cursor, with configurable size, opacity and color. Built-in Blizzard texture, no external assets. Disabled by default; enable on the new "Cursor Ring" config page.

## [1.0.6] — 2026-05-08

### Added
- **Cooldown Pulse** central icon that briefly flashes when a tracked spell becomes ready or a tracked aura is gained.
- Per-aura **playSound** flag with a curated list of Blizzard SoundKit IDs.
- Dedicated **Cooldown Pulse** config page with draggable on-screen anchor and badges per spell/aura.

## [1.0.5] — 2026-05-05

### Added
- **Minimap button** — draggable, left click opens config, right click toggles displays.
- **Aura activation sound** — optional sound cue when a tracked aura is detected via `addedAuras`.

### Changed
- Restyled config window chrome and internal widgets with a Dragonflight-inspired skin (teal/mint accent), auto-hide scrollbars.

## [1.0.4] — 2026-05-05

### Added
- **Localization system** (`ns.L`) — 8 languages: enUS, esES, deDE, frFR, koKR, ptBR, ruRU, zhCN. English keys.

## [1.0.3] — 2026-05-05

### Added
- **Spell autocomplete** popup in all three modal editors (Cursor Spells, Cursor Auras, Ring Auras).

## [1.0.2] — 2026-05-02

### Changed
- Refactored config from inline forms to dedicated **modal editor windows** for Cursor Spells, Cursor Auras, and Ring Auras.

## [1.0.1] — 2026-05-05

### Fixed
- **SecureNumber taint in combat** — charges and durations were arriving tainted in combat, breaking cursor display and breaking aura tracking. Fixes in `CursorDisplay.lua` and `AuraMonitor.lua`, plus persistence of `knownDurations`.

## [1.0.0] — Initial release

### Added
- Cursor icon display for spells (cooldown sweep, charges, range/power state) and auras (stacks, remaining time).
- Character ring display for auras with per-aura color, configurable thickness/spacing/segments.
- Per-character profiles with import/export.
- Slash command `/sat` (alias `/spellaura`) with config window, debug helpers, and toggle.
- Three-layer aura fallback: Blizzard Cooldown Manager hooks → `UNIT_AURA` cache → CLEU tracking.
- Taint-safe event registration via `RegisterUnitEvent`.
