# HNZ Healing Tools

A lightweight World of Warcraft (Retail) addon that tracks your spells and auras through three complementary displays: floating icons next to your cursor, circular progress rings around your character, and a central pulse icon when key cooldowns become ready.

Designed to keep your eyes on the action — no more glancing at action bars to check cooldowns or aura timers.

![Interface](https://img.shields.io/badge/Interface-12.0.1-blue) ![License](https://img.shields.io/badge/License-MIT-green) ![Version](https://img.shields.io/badge/Version-1.0.7-orange)

---

## Features

### Three display modes

- **Cursor Icons** — floating icons next to the mouse cursor showing tracked spells (with cooldown sweep, charges, range/power state) and tracked auras (with stack count and remaining time).
- **Character Rings** — concentric circular progress rings around your character that drain as the aura expires. Per-aura color, optional inline icon, configurable thickness/spacing/segments.
- **Cooldown Pulse** — a large central icon that briefly flashes when a tracked spell finishes its cooldown or a tracked aura is gained. Optional sound cue per aura.
- **Cursor Ring** *(optional)* — a decorative ring that follows the mouse cursor, useful for keeping track of the pointer in busy fights. Configurable size, opacity, and color.

### Tracking flexibility

- Track spells by **ID or name** (drag-and-drop from spellbook also supported).
- Auras can be tracked on any unit (`player`, `target`, `focus`, `pet`, `mouseover`) with `HELPFUL` / `HARMFUL` filters.
- Per-aura **show modes**: always, only when active, only when missing.
- Minimum stacks threshold and manual duration override for hidden auras.
- **Per-spec / per-character** profiles — talent swap doesn't lose your setup.

### UX

- **Modal config window** with 6 tabbed pages, dark theme with teal accent.
- **Spell autocomplete** — start typing in any spell field to get live suggestions.
- **Minimap button** (draggable) — left click for config, right click to toggle displays.
- **Profile import / export** via shareable strings.
- **Localized** in 8 languages: English, Spanish, German, French, Korean, Brazilian Portuguese, Russian, Simplified Chinese.

### Robustness

- **Taint-safe** event registration (uses `RegisterUnitEvent` for raid/party-touching events) — won't break Blizzard's secure frame updates in combat.
- **SecureNumber-aware** cooldown extraction — works around the new "secret value" API returns introduced in recent patches.
- **Three-layer aura fallback**: Blizzard Cooldown Manager hooks → `UNIT_AURA` cache → `COMBAT_LOG_EVENT_UNFILTERED` tracking — catches hidden auras and short-lived procs.

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
| `/hht` *(or `/hannzoo`)* | Open the config window |
| `/hht toggle` | Toggle both cursor and ring displays |
| `/hht minimap` | Show / hide the minimap button |
| `/hht status` | Print status of all tracked spells and auras |
| `/hht debug <spellID>` | Diagnostic info for a tracked spell |
| `/hht auradebug <spellID> [unit] [filter]` | Diagnostic info for a tracked aura |
| `/hht cdm` | Dump Blizzard Cooldown Manager state |

### Adding entries

Open `/hht` and pick a tab:

- **Cursor Spells** — spells whose cooldown / charges you want to see near the cursor.
- **Cursor Auras** — auras you want to see near the cursor.
- **Ring Auras** — auras shown as a colored ring around your character.

Click **Add**, type the spell name or ID (autocomplete will help), pick the unit / filter / show mode, and you're done.

The **Cursor Settings**, **Ring Settings**, and **Cooldown Pulse** tabs control sizes, offsets, opacity, and the central pulse icon's anchor (draggable in-game). The **Cursor Ring** tab adds a decorative ring that follows the mouse, with optional cast-progress sub-ring (180 wedges that light up with `UnitCastingInfo` / `UnitChannelInfo`) and optional center dot.

### Profiles

The **Profiles** tab lets you create, copy, switch, delete, import, and export profiles. Each character automatically gets its own active profile, but profiles themselves are stored account-wide so you can share them across alts.

---

## Compatibility

- **Game version**: World of Warcraft Retail, Interface `120001` (The War Within 11.2.x / 12.0.x).
- **Classic / Wrath / Cata Classic**: not supported.

---

## Reporting bugs

Please open an issue with:

1. The exact spell or aura ID involved.
2. Output of `/sat debug <spellID>` or `/sat auradebug <spellID>`.
3. Any Lua errors (use BugSack / BugGrabber if possible).

---

## License

MIT — see [LICENSE](LICENSE).

## Credits

Developed by **fo**. Inspired by CDPulse (cooldown pulse pattern) and DandersFrames (UI theming approach).
