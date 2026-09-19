# HNZ Healing Tools

**A complete heads-up toolkit for Retail healers and cooldown-heavy specs.** Track your spells, auras, cooldowns and raid utility through clean, fully-configurable displays — so you can watch the fight instead of your action bars, chat, or unit frames.

---

## 🎯 Displays — your cooldowns where you're already looking

- **Cursor Icons** — tracked spells (cooldown sweep, charges, range/power) and auras (stacks + remaining time) floating right next to your mouse.
- **Character Rings** — concentric progress rings around your character that drain as an aura expires. Per-aura color and optional icon.
- **Cooldown Pulse** — a big center-screen flash the moment a key spell comes off cooldown or a buff is gained.
- **Cursor Ring** *(optional)* — cast-progress wedge, mouse trail, and particle sparkle effects.

## 🛡️ Raid & group utility

- **Ready Check Panel** — pops on `/readycheck` with a visual pull-ready checklist: food, flask/phial, augment rune, weapon imbue, class buffs, healthstone, mana, and your talent loadout. If you're the one who casts a group buff (Skyfury, Fortitude, Intellect…), the row stays red until *every* living member actually has it — so you know to recast. One-click talent-loadout switching per content type.
- **Combat Resurrection tracker** — see your group's **shared battle-res charges** in raids and Mythic+, on **any class** (you don't need a brez yourself). Shows how many are available, or counts down to the next charge. Shamans also get a **Reincarnation** self-res indicator.
- **Raid Spells comms** *(alpha)* — broadcasts your major healing cooldowns to other healers running the addon and shows who used what, and how long ago.
- **MRT / NSRT timeline reminders** — reads your Method Raid Tools / Northern Sky raid notes and reminds you of your assigned spells as the trigger approaches — near the cursor, around your character, or as a center pulse, with optional **pre-recorded voice callouts**.

## 🧰 Quality of life

- **Auction House Restock** — a curated shopping list with per-item target counts and max prices, plus a guided buy flow with price-history and "price spike" warnings.
- **Macros & API** — fire any display from a macro with a trigger key, or from another addon via `HNZHealingTools.Trigger(key)`.
- **Item tracking** — trinkets, potions and on-use consumables, by drag-and-drop.
- **Profiles** — per-character, account-wide and shareable across alts, with versioned migrations and automatic pre-migration backups.
- **Localized** in 8 languages: English, Spanish, German, French, Korean, Brazilian Portuguese, Russian, Simplified Chinese.

## ⚙️ Built to behave

Taint-safe event handling in combat, SecureNumber-aware cooldown/aura reads for recent patches, a three-layer fallback that catches hidden auras, and event-driven polling that only works when something actually changes.

---

**Getting started:** type `/hht` (or `/hnz`) to open the config. Every display, color, size and position is configurable, and every entry can be scoped to specific content (Raid, Mythic+, Dungeon, PvP, Delve, Open World). A draggable minimap button gives you quick access — left-click for config, right-click to toggle displays.

*Works on World of Warcraft Retail (Midnight, 12.0.x). Optional: LibSharedMedia-3.0 for an expanded sound library.*
