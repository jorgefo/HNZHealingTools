# Changelog

All notable changes to **HNZ Healing Tools** (formerly *SpellAuraTracker*) will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] — 2026-05-10

### Added
- **Credits page** in the config window (last tab in the sidebar). Lists the reference addons (CursorRing, CDPulse, MRT, NSRT — Northern Sky Raid Tools, Classic WeakAuras), optional library (LibSharedMedia-3.0), and the tooling used to build the addon (Claude Code). Each entry shows a copyable URL.
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
