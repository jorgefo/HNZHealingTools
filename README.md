# HNZ Healing Tools

A lightweight World of Warcraft (Retail) addon for healers and cooldown-heavy specs. Surfaces your spells, auras, and raid-note reminders through complementary displays — cursor icons, character rings, a central cooldown pulse, and an MRT/NSRT timeline reminder — so you can keep your eyes on the action instead of glancing at action bars or the chat frame.

![Interface](https://img.shields.io/badge/Interface-12.0.1-blue) ![License](https://img.shields.io/badge/License-MIT-green) ![Version](https://img.shields.io/badge/Version-1.2.0-orange)

---

## Features

### Display modes

- **Cursor Icons** — floating icons next to the mouse cursor showing tracked spells (cooldown sweep, charges, range/power state) and tracked auras (stack count and remaining time).
- **Character Rings** — concentric circular progress rings around your character that drain as the aura expires. Per-aura color, optional inline icon, configurable thickness/spacing/segments.
- **Cooldown Pulse** — large central icon that briefly flashes when a tracked spell finishes its cooldown or a tracked aura is gained. Optional sound cue per entry.
- **Cursor Ring** *(optional)* — decorative ring following the mouse, with sub-features:
  - **Cast progress** — 180-wedge progress sub-ring that fills during `UnitCastingInfo` / `UnitChannelInfo`.
  - **Center dot** with optional grow-on-movement.
  - **Trail** — mouse trail with configurable color, lifetime, and visibility.
  - **Sparkles** — particle effects (dot / thin ring / thick ring / wedge / mixed), with path-fill so fast cursor moves don't leave gaps.
  - Class-color option for the ring.

### MRT / NSRT Timeline Reminders

Parses your raid notes from **Method Raid Tools** or **Northern Sky Raid Tools** and shows reminders for each spell you're assigned, near the cursor / around your character / as a center pulse, as the trigger time approaches.

- Dual format parser: MRT (`{time:M:SS.t} - Name {spell:N}`) and NSRT (`time:N;tag:Name;spellid:N`).
- One note per encounter — auto-detection of `EncounterID` / `Name` from the NSRT header on import.
- **Difficulty filter per note**: LFR / Normal / Heroic / Mythic checkboxes; runtime matcher picks the right note for the current pull. Keep variants of the same fight for different difficulties.
- **Manual enable toggle per note** (checkbox in the row) — alternate between notes depending on raid comp without deleting them.
- **Encounter Journal integration**: boss portrait + raid name in each row, autocomplete by boss name in the ID field.
- State machine per entry: `PRE` (countdown 3,2,1 with dim icon), `ACTIVE` (saturated icon, configurable window), `CONSUMED` (cast detected via `UNIT_SPELLCAST_SUCCEEDED`).
- Three visual integrations, selectable: cursor (stacked icons), ring (segmented progress around the player), pulse (one-shot at trigger).
- Optional sound on trigger with LibSharedMedia awareness and channel selector.
- **Test pull** button to preview any note without being in the encounter.

### Tracking flexibility

- Track spells by **ID or name** (drag-and-drop from spellbook supported).
- Auras on any unit (`player`, `target`, `focus`, `pet`, `mouseover`) with `HELPFUL` / `HARMFUL` filters.
- Per-aura **show modes**: always, only when active, only when missing.
- Minimum stacks threshold and manual duration override for hidden auras.
- **Visibility dropdown** per feature (Always / Only in combat / Only out of combat), applied to displays and sub-features (trail, sparkle, etc.).

### Profiles

- **Per-character active profile**, with profiles themselves stored account-wide — shareable across alts.
- **Import / export** as portable strings.
- **Migration system** with versioned schema and **automatic pre-migration backup**; the Profiles tab includes a "Restore from backup" UI so you can revert if a future migration is buggy.
- Bootstrap for new alts: copies the legacy account-wide profile or the first existing profile alphabetically, instead of creating empty defaults.

### UX

- **Modal config window** (900 px wide) with sidebar tabs and sub-tabs:
  - Cursor → Spells / Auras / Config
  - Ring → Auras / Config
  - Pulse → Spells / Auras / Config
  - Cursor Ring → Ring / Cast / Dot
  - MRT / NSRT → Encounters / Config
  - General
  - Profiles
- **Spell autocomplete** in any spell field.
- **Minimap button** (draggable) — left click for config, right click to toggle displays.
- **Localized** in 8 languages: English, Spanish, German, French, Korean, Brazilian Portuguese, Russian, Simplified Chinese.

### Robustness

- **Taint-safe** event registration (uses `RegisterUnitEvent` for raid/party events) — won't break Blizzard's secure frame updates in combat.
- **SecureNumber-aware** cooldown extraction — handles the "secret value" API returns introduced in recent patches.
- **Three-layer aura fallback**: Blizzard Cooldown Manager hooks → `UNIT_AURA` cache → `COMBAT_LOG_EVENT_UNFILTERED` tracking — catches hidden auras and short-lived procs.
- **Event-driven polling via dirty flags**: consumers re-scan only when something actually changed, not every frame.

---

## Installation

### Via CurseForge / Wago / WoWInterface client (recommended)

Search for **HNZ Healing Tools** and install — the client handles updates automatically.

### Manual install

1. Download the latest release ZIP.
2. Extract so the folder structure is:
   `World of Warcraft/_retail_/Interface/AddOns/HNZHealingTools/`
3. Restart WoW (or `/reload`).

---

## Usage

### Slash commands

| Command | Action |
|---|---|
| `/hht` *(or `/hnz`)* | Open the config window |
| `/hht toggle` | Toggle both cursor and ring displays |
| `/hht minimap` | Show / hide the minimap button |
| `/hht status` | Print status of all tracked spells and auras |
| `/hht debug <spellID>` | Diagnostic info for a tracked spell |
| `/hht auradebug <spellID> [unit] [filter]` | Diagnostic info for a tracked aura |
| `/hht cdm` | Dump Blizzard Cooldown Manager state |

### Adding entries

Open `/hht` and pick a tab. Click **Add**, type the spell name or ID (autocomplete will help), pick the unit / filter / show mode, and you're done.

- **Cursor Spells** — spells whose cooldown / charges you want to see near the cursor.
- **Cursor Auras** — auras you want to see near the cursor.
- **Ring Auras** — auras shown as a colored ring around your character.
- **Pulse Spells / Auras** — entries that trigger a one-shot central icon flash.
- **MRT / NSRT → Encounters** — import a raid note (paste the text, optionally set difficulty filter), and the timeline reminder fires during `ENCOUNTER_START`.

The **Config** sub-tabs in each module control sizes, offsets, opacity, anchors (draggable in-game where applicable), and integrations.

### Profiles

The **Profiles** tab lets you create, copy, switch, delete, import, and export profiles. Each character automatically gets its own active profile, but profiles themselves are stored account-wide so you can share them across alts. If a migration ever misbehaves, restore from the auto-backup taken just before it ran.

---

## Compatibility

- **Game version**: World of Warcraft Retail, Interface `120001` (The War Within 12.0.x).
- **Classic / Wrath / Cata Classic**: not supported.
- **Optional dependency**: [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) — when present, expands the available sound library for cooldown pulses and MRT trigger sounds.

---

## Reporting bugs

Please open an issue at [github.com/jorgefo/HNZHealingTools](https://github.com/jorgefo/HNZHealingTools) with:

1. The exact spell or aura ID involved.
2. Output of `/hht debug <spellID>` or `/hht auradebug <spellID>`.
3. Any Lua errors (use BugSack / BugGrabber if possible).

---

## License

MIT — see [LICENSE](LICENSE).

## Credits

Developed by **fo**.

Inspired by and works alongside:

- [CursorRing](https://www.curseforge.com/wow/addons/cursorring) — cursor ring trail and sparkle ideas.
- [CDPulse](https://www.curseforge.com/wow/addons/cdpulse) — cooldown pulse pattern.
- [DandersFrames](https://www.curseforge.com/wow/addons/dandersframes) — UI theming and palette.
- [Method Raid Tools (MRT)](https://www.curseforge.com/wow/addons/method-raid-tools) — raid note timeline format.
- [Northern Sky Raid Tools (NSRT)](https://www.curseforge.com/wow/addons/northern-sky-raid-tools) — alternative timeline format.
