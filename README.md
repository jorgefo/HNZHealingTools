# HNZ Healing Tools

A complete heads-up toolkit for World of Warcraft (Retail) healers and cooldown-heavy specs. It surfaces your spells, auras, cooldowns and raid utility through complementary, fully-configurable displays — cursor icons, character rings, a central cooldown pulse, MRT/NSRT timeline reminders, a pre-pull ready-check checklist, auction-house restocking, raid-wide healer cooldown comms, a combat-resurrection tracker, and more — so you can keep your eyes on the fight instead of scanning action bars, chat, or unit frames.

![Interface](https://img.shields.io/badge/Interface-12.0.5-blue) ![License](https://img.shields.io/badge/License-MIT-green) ![Version](https://img.shields.io/badge/Version-1.10.1-orange)

---

## Features

### Display modes

- **Cursor Icons** — floating icons next to the mouse cursor showing tracked spells (cooldown sweep, charges, range/power state) and tracked auras (stack count and remaining time).
- **Character Rings** — concentric circular progress rings around your character that drain as the aura expires. Per-aura color, optional inline icon, configurable thickness/spacing/segments.
- **Cooldown Pulse** — large central icon that briefly flashes when a tracked spell finishes its cooldown or a tracked aura is gained. Optional sound cue per entry.
- **Cursor Ring** *(optional)* — decorative ring following the mouse, with sub-features: cast-progress wedge that fills during casts/channels, a center dot with optional grow-on-movement, a configurable mouse trail, and particle sparkles (with path-fill so fast moves don't leave gaps). Class-color option.

### Ready Check Panel

A floating checklist that pops on `/readycheck` and auto-hides when you respond — so you can confirm you're pull-ready at a glance.

- Tracks **Well Fed**, **Flask / Phial**, **Augment Rune**, **Weapon Imbue**, party-aware **Class Buffs** (Skyfury / Power Word: Fortitude / Mark of the Wild / Arcane Intellect / Battle Shout / Blessing of the Bronze), **Healthstone** (only when a Warlock is in the group), a **mana reminder**, and your active **Talent Loadout**.
- **Provider-aware buff checks** — if you're the one who casts a group buff (e.g. Skyfury), the row stays red until every connected, alive group member actually has it, not just you.
- **Talent Loadout per content type** — assign each saved loadout to Raid / Mythic+ / PvP / Delve; the panel warns when the active loadout doesn't match the current content and offers a one-click **Switch** (out of combat).
- Missing consumables (oils / runes / food / flasks / mana drinks / healthstones) appear as clickable bag sub-rows.

### Auction House Restock

A floating button at the auction house that works a curated shopping list of consumables and starts a guided purchase through the standard AH flow.

- Per-item **target quantity**, **max unit price**, and a **confirm-above** gold threshold (plus a global safety-net threshold).
- **`lastPaid` history** per item, with up/down price indicators in the tooltip and a detailed confirmation popup: icon + name, quantity × unit = total, bag delta (have → after vs. target), price change vs. last purchase, and a "price spike" warning.

### Raid Spells — healer cooldown comms *(alpha)*

Coordinate raid cooldowns with the other healers without watching chat.

- Broadcasts your **major healing cooldowns** to every raider running the addon and shows a panel listing each healer and their recent casts, each with a compact age label (`5s` / `2m`).
- Healers are discovered automatically (hello protocol on group join + heartbeat); only spells with a **base cooldown over 30 seconds** are shown, keeping the list focused on cooldowns that actually matter.

### Misc

Small but handy utilities that don't warrant their own menu.

- **Combat Resurrection tracker** — shows your group's **shared battle-res charges** in raids and Mythic+. It works on **any class** (it does not depend on you having a brez spell): when charges are available it shows the count; when empty, the icon dims and counts down to the next charge. Visible the whole time you're in raid / M+, in or out of combat.
- **Reincarnation indicator (Shaman)** — a companion icon showing whether you can self-res, or the cooldown remaining until you can.
- Icons are freely movable (drag with a single button) and **right-click** (out of combat) opens their settings directly.

### MRT / NSRT Timeline Reminders

Parses your raid notes from **Method Raid Tools** or **Northern Sky Raid Tools** and shows reminders for each spell you're assigned — near the cursor, around your character, or as a center pulse — as the trigger time approaches.

- Dual format parser: MRT (`{time:M:SS.t} - Name {spell:N}`) and NSRT (`time:N;tag:Name;spellid:N`).
- One note per encounter, with **Encounter Journal integration** (boss portrait + name, autocomplete by boss name) and a **per-note difficulty filter** (LFR / Normal / Heroic / Mythic) so the right variant fires for the current pull.
- Per-entry state machine: `PRE` (3-2-1 countdown, dimmed), `ACTIVE` (saturated, configurable window), `CONSUMED` (cast detected). Optional trigger sound and **pre-recorded voice announcements** for the spell name (bundled WAVs, no in-game TTS engine required).
- **Test pull** button to preview any note outside the encounter.

### Tracking flexibility

- Track spells by **ID or name** (drag-and-drop from spellbook / bag / equipment supported), including **items** (trinkets, potions, on-use consumables) via the **Add Item…** button.
- Auras on any unit (`player`, `target`, `focus`, `pet`, `mouseover`) with `HELPFUL` / `HARMFUL` filters, per-aura **show modes** (always / active / missing / below-stacks), minimum-stacks threshold, and manual duration override for hidden auras.
- **Per-entry content filter** (Open World / Delves / PvP / Raid / Mythic+ / Dungeon) and a **visibility dropdown** (Always / Only in combat / Only out of combat) on every editor.

### Macros & integration

- **Trigger key** field on every aura / spell / item editor — fire any configured display from a macro with `/hht trigger <key>`, or from another addon via `HNZHealingTools.Trigger(key)`. Multiple entries can share a key.
- Public API namespace `_G.HNZHealingTools` (`.version`, `.Trigger(key)`), with a dedicated **Macros** help page of copy-pasteable examples.

### Profiles

- **Per-character active profile**, with profiles stored account-wide so they're shareable across alts. Import / export as portable strings.
- **Migration system** with versioned schema and **automatic pre-migration backup** — the Profiles tab includes a "Restore from backup" UI in case a future migration misbehaves.

### UX

- **Modal config window** (resizable) with a sidebar of feature sections: General, Cursor, Ring, Pulse, Cursor Ring, MRT / NSRT, Ready Check, Auction House, Raid Spells, Simulated Auras, Misc, Macros, Profiles. A central **Enable Features** panel toggles each module on/off.
- **Spell autocomplete** in any spell field.
- **Minimap button** (draggable) — left click for config, right click to toggle displays.
- **Localized** in 8 languages: English, Spanish, German, French, Korean, Brazilian Portuguese, Russian, Simplified Chinese.

### Robustness

- **Taint-safe** event registration (`RegisterUnitEvent` for raid/party events) — won't break Blizzard's secure frame updates in combat.
- **SecureNumber-aware** cooldown/aura extraction — handles the "secret value" API returns introduced in recent patches.
- **Three-layer aura fallback**: Blizzard Cooldown Manager hooks → `UNIT_AURA` cache → combat-log tracking — catches hidden auras and short-lived procs.
- **Event-driven polling via dirty flags**: consumers re-scan only when something actually changed, not every frame.

---

## Installation

### Via CurseForge / Wago / WoWInterface client (recommended)

Search for **HNZ Healing Tools** and install — the client handles updates automatically.

### Manual install

1. Download the latest release ZIP.
2. Extract so the folder structure is `World of Warcraft/_retail_/Interface/AddOns/HNZHealingTools/`.
3. Restart WoW (or `/reload`).

---

## Usage

### Slash commands

| Command | Action |
|---|---|
| `/hht` *(or `/hnz`)* | Open the config window |
| `/hht toggle` | Toggle both cursor and ring displays |
| `/hht trigger <key>` | Fire every entry that has the matching trigger key (for macros) |
| `/hht minimap` | Show / hide the minimap button |
| `/hht status` | Print status of all tracked spells and auras |
| `/hht debug <spellID>` | Diagnostic info for a tracked spell |
| `/hht auradebug <spellID> [unit] [filter]` | Diagnostic info for a tracked aura (manual trigger state + CDM eligibility) |
| `/hht listauras [unit]` | List every active buff/debuff on the unit with name + spellID + source + duration |
| `/hht cdm` | Dump Blizzard Cooldown Manager state |

### Adding entries

Open `/hht`, pick a section, click **Add**, type the spell name or ID (autocomplete helps) or drag a spell/item in, then choose the unit / filter / show mode. Each entry editor exposes a **Show only in:** content filter so you can scope tracking; the per-module **Config** sub-tabs control sizes, offsets, opacity, and draggable anchors.

For *fully restricted* auras (some item buffs Midnight hides from the public API), set a **Trigger spell** or **Trigger item** + **Duration** in the editor — the addon synthesizes the ACTIVE state on cast/use.

---

## Compatibility

- **Game version**: World of Warcraft Retail, Interface `120005` (Midnight 12.0.x).
- **Classic / Wrath / Cata Classic**: not supported.
- **Optional dependency**: [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) — when present, expands the sound library for cooldown pulses and MRT trigger sounds.

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
