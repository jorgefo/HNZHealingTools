# Changelog

All notable changes to **HNZ Healing Tools** are listed below.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

- Project page: <https://www.curseforge.com/wow/addons/hnz-healing-tools>
- Source: <https://github.com/jorgefo/HNZHealingTools>

---

## [1.9.0] — 2026-05-26

- **Raid Spells (A)**: the panel now lists every healer in your raid who has the addon enabled, not just those who cast recently. Discovery is automatic via a hello protocol broadcast on group join and every 60s; stale entries are pruned after 3 minutes of silence.
- **Raid Spells (A)**: each cast icon now shows a compact age label (`5s` / `2m` / `1h`) under it. Replaces the alpha fade — the elapsed time is communicated explicitly.
- **Raid Spells (A)**: panel only shows inside a raid instance by default. Fixed visibility in the open world while in a raid group during world events / world bosses.
- **Raid Spells (A)**: drag works correctly — fixed a regression where the 0.5s refresh ticker re-anchored the panel mid-drag and snapped it back.
- **Ready Check Panel**: talent build row now shows an explicit warning when no loadout is assigned for the current content type (yellow text + red X) instead of a silent neutral state.
- **Ready Check Panel**: Dungeon and Mythic+ talent loadout categories merged into a single "Dungeon / M+" checkbox — the ready check fires before the keystone is inserted, so the distinction wasn't useful. Existing `mplus=true` assignments still work as a synonym for `dungeon`.
- **Ready Check Panel**: default panel width 320 → 420px so longer status texts no longer get clipped. Slider max raised to 700. Migration v6 auto-bumps profiles still on the old default.
- **Ready Check Panel**: removed the "Use" button from the healthstone cell — healthstones are combat-only and the ready check fires out of combat. Icon + count remain to indicate you have stones.
- **Ready Check Panel**: cauldron-cast Phial aura `1235108` added to the known flask aura list.
- **Aura tracking**: fixed the "ring stays active after the buff expired" bug (e.g. Barkskin). When the Cooldown Manager cache has a stale entry whose `appliedAt + duration` is in the past, the entry is now evicted and the status reported as MISSING. Also clears the CDM cache on zone changes (PLAYER_ENTERING_WORLD full updates).
- **Simulated Auras (A)**: new sidebar entry, currently "Coming Soon". The state machine works via `/hnzsim <spellID>` and models an apply-then-consume aura pattern (for spells whose aura is hidden from the WoW API). UI integration with Cursor/Ring display is still in testing.

---

## [1.8.0] — 2026-05-21

- **Auction Restock**: floating button at the auction house that searches commodities for items in your curated list and starts a guided purchase via the standard AH flow. Per-item target quantity, max unit price, and a confirm-above threshold. lastPaid history persists per item, with up/down indicators in the tooltip and confirmation popup.
- **Detailed buy confirmation popup**: icon + name, quantity × unit = total, bag delta (have → after, vs target), price change vs lastPaid (^ +X% or v -X%), time since last purchase, and a "price spike" warning if the unit price jumped 50% or more.
- **Global confirm threshold**: extra safety-net popup if the total cost exceeds a global gold amount, even when the per-item threshold doesn't trigger. Configurable in Config → Auction House.
- **Stuck-ring fix**: the character ring auras now re-validate at known checkpoints (combat start, combat end, ready check). Fixes the random "ring stays visible after the buff expired" bug.
- Ready Check Panel can now be moved by clicking and dragging the panel (no Shift needed). Position persists across sessions.
- Talent loadout row renamed "Loadout" → "Talent Build" for clarity.
- Drag the Auction Restock floating button directly to reposition it (Shift no longer required). Position is auto-saved.
- Fix: `AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED` no longer cancels in-flight commodity purchases — the event is system-wide and was a false-positive that aborted purchases the server actually completed.
- Fix: reduced AH search query spam on Restock click — only the target item is refreshed, cutting throttle contention.

---

## [1.7.0] — 2026-05-18

- **Ready Check Panel**: floating checklist that appears on `/readycheck` and auto-hides when you respond (or on combat start, or via the new × close button). Tracks Well Fed, Flask, Augment Rune, Weapon Imbue, party-aware Class Buffs (Skyfury / Power Word: Fortitude / Mark of the Wild / Arcane Intellect / Battle Shout / Blessing of the Bronze), Healthstone (only when a Warlock is in the group), a mana reminder, and your active Talent Loadout. Bag oils / runes / foods / flasks / mana drinks / healthstones appear as clickable sub-rows.
- **Talent Loadout per content type**: in Config → Ready Check → Talents, assign each saved loadout to one or more categories (Raid, Mythic+, Dungeon, PvP, Delve). The panel warns when the active loadout doesn't match the current content and offers a Switch button that applies the saved loadout for you (out of combat only).
- **Universal weapon imbue detection**: works for every class, both hands. Self-casters (Shaman / Rogue) get a Cast button; other classes get the bag oils as click-to-use sub-rows. Eating channel is auto-detected via the food/drink aura.
- **Habilitar Funciones** (General page): master enable per feature (Cursor, Ring, Pulse, Cursor Ring, MRT/NSRT, Ready Check). Disabling grays the sidebar entry and locks its config page behind a translucent overlay.
- Sidebar reorganized: General moved to the top. Hover the icon of any green check row in the panel to see the native spell or item tooltip.
- New `/hnz oildiag` slash command: dumps weapon enchant state + player auras for diagnosing weapon imbue detection per patch.
- Fix: weapon imbue on classes without a self-cast spell (Monk, Druid, etc.) was rendered as red × even with the oil applied — now shows green check.
- Fix: Blessing of the Bronze and other class buffs whose aura spellID differs from the cast spellID are now detected via name fallback.
- Fix: Talent loadout Switch now actually applies the talents (was only selecting them in the editor).
- Fix: item counts in sub-rows are now bag-only (warband / account bank excluded).
- Fix: Cursor Ring master toggle now hides the dot and cast wedges too.

---

## [1.6.0] — 2026-05-16

- **Macro trigger system**: every aura, pulse, and item editor has a new "Trigger key" field. Fire any configured display from a macro with `/hht trigger <key>` or from another addon via `HNZHealingTools.Trigger(key)`. Multiple entries can share a key — one keybind fires them all at once.
- New **Macros** help page in the config sidebar with copy-pasteable macro examples and Lua snippets.
- **Floating preview popup**: "Show preview" button at the top of pages with a Live Preview block (Cursor / Ring / Pulse settings + Cursor Ring sub-tabs). Opens to the right of the config window, single-active across pages.
- Stack count now displays correctly for fully-restricted auras tracked by Blizzard's Cooldown Manager (e.g. Mana Tea). SecureNumber values are no longer lost in combat.
- Restricted auras visible in the Cooldown Manager but invisible to addon APIs now synthesize the ACTIVE state from the CDM hook — icon + count + timer render correctly.
- `/hht auradebug` enriched with `inCombat` status, CDM-captured stack count, and the full list of FontStrings on the matching CDM frame.
- Public API namespace `_G.HNZHealingTools` exposed for macros and other addons (`.version`, `.Trigger(key)`).

---

## [1.5.0] — 2026-05-15

- **Track items as cooldowns**: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New "Add Item..." button + drag-and-drop dispatches by type (spell vs item).
- Item editors with full tabs: General + Display + Effects for cursor items; General + Sound for pulse items.
- **Per-entry instance-type filter** on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP, Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances.
- **Aura detection paths 6 + 7**: slot iteration catches semi-restricted auras Midnight hides from name/ID lookups; manual trigger workaround (configure a trigger spell or item ID) handles fully-restricted auras like consumable buffs.
- New `/hht listauras` command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID when the guessed one isn't detected.
- Config window no longer closes when opening the Spellbook. ESC still closes it via a custom handler.
- Fix: comparing SecureNumber spellId in slot iteration tainted the addon. Wrapped in safe conversion — fully restricted auras are now skipped safely.
- Fix: `ApplyRingVisibility nil call` when a ring test entry expired (forward declaration bug).

---

## [1.4.0] — 2026-05-14

- Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically.
- **Per-entry visibility** for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility).
- **Per-entry visual overrides** for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely).
- **Tabbed editor modals**: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound.
- Changelog button (?) in the config window title bar — opens the What's New popup with all release notes on demand.
- Fix: "Spell not found" when adding via the autocomplete dropdown for spells/auras the character doesn't know.
- Fix: creating or switching profiles left some menus showing the old profile's values.

---

## [1.3.0] — 2026-05-13

- Live preview in the config for Ring, Pulse, Cursor Ring and Cursor Icons — all sliders are reflected live.
- Reorder entries in Cursor Spells / Auras with up/down arrows on each row.
- Test (T) button per entry — forces the icon to the real cursor for 5s to preview how it looks.
- Config window is now resizable from the bottom-right corner (size persists per profile).
- Custom textures for move arrows (bundled with the addon, no dependency on built-ins).
- MRT/NSRT note editor: format selector switched to 2 radio buttons (NSRT default).
- Fix: the MRT/NSRT pulse now appears even when Cooldown Pulse visibility is set to something other than "always".
- Added the "What's New" popup that appears once after installing a new version.

---

## Earlier versions

Older releases (1.0.0 – 1.2.2, May 2026) covered the initial public launch:
the **rename from SpellAuraTracker to HNZ Healing Tools** (1.0.28), the
**MRT/NSRT Timeline reminders** module with multi-note + difficulty filter
(1.1.0 / 1.2.0), profile bootstrap fixes, visibility dropdowns, automatic
schema migrations with backup, plus a long polish stream on the Cursor Ring
(cast progress ring, center dot, mouse trail, sparkle effects), Pulse modal
editors, autocomplete improvements, and dozens of UI bug fixes.

Full per-commit history: <https://github.com/jorgefo/HNZHealingTools/commits/main>
