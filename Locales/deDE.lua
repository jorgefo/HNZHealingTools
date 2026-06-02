local _, ns = ...

-- Deutsche Übersetzungen (deDE). Schlüssel sind die englischen UI-Texte aus ns.L[...].
-- Fehlende Schlüssel fallen über die Metatable in Locales.lua auf Englisch zurück.
ns.RegisterLocale("deDE", {
    -- ===== Verschiedenes / Misc (Kampfwiederbelebung + Reinkarnation) =====
    ["Miscellaneous"] = "Verschiedenes",
    ["Combat Resurrections"] = "Kampfwiederbelebungen",
    ["Enable combat resurrection indicator"] = "Anzeige für Kampfwiederbelebungen aktivieren",
    ["Shows the group's shared battle-res charges (raid / Mythic+) — it does not depend on your class. With charges available: the number. Without: the icon dims and counts down to the next charge. Hidden in content with no shared pool."] = "Zeigt die geteilten Kampfwiederbelebungs-Ladungen der Gruppe (Schlachtzug / Mythisch+) – unabhängig von deiner Klasse. Mit verfügbaren Ladungen: die Zahl. Ohne: das Symbol wird abgedunkelt und zählt bis zur nächsten Ladung herunter. In Inhalten ohne geteilten Vorrat ausgeblendet.",
    ["Text size (0=auto)"] = "Textgröße (0=automatisch)",
    ["Move icon"] = "Symbol verschieben",
    ["Lock icon"] = "Symbol fixieren",
    ["Right-click: open settings (out of combat)"] = "Rechtsklick: Einstellungen öffnen (außerhalb des Kampfes)",
    ["Show Reincarnation (Shaman self-res)"] = "Reinkarnation anzeigen (Schamanen-Selbstwiederbelebung)",
    -- ===== Fehler- / Feedback-Meldungen =====
    ["Spell not found: "] = "Zauber nicht gefunden: ",
    [" already monitored."] = " wird bereits überwacht.",
    ["Enter a name/ID."] = "Name/ID eingeben.",
    ["Enter a name."] = "Name eingeben.",
    ["Already exists."] = "Existiert bereits.",
    ["Created: "] = "Erstellt: ",
    ["Can't copy to itself."] = "Kann nicht auf sich selbst kopieren.",
    ["Copied from "] = "Kopiert von ",
    ["Give the profile a name."] = "Gib dem Profil einen Namen.",
    ["Paste the exported string in the box."] = "Füge den exportierten String in das Feld ein.",
    ["Imported as: "] = "Importiert als: ",
    ["Import failed."] = "Import fehlgeschlagen.",
    ["Ready: Ctrl+C to copy"] = "Bereit: Strg+C zum Kopieren",
    ["No active profile to export"] = "Kein aktives Profil zum Exportieren",

    -- ===== Standard-Buttons =====
    ["Save"] = "Speichern",
    ["Cancel"] = "Abbrechen",
    ["Add"] = "Hinzufügen",
    ["Update"] = "Aktualisieren",
    ["Close"] = "Schließen",
    ["Edit"] = "Bearbeiten",
    ["Test"] = "Testen",
    ["Create"] = "Erstellen",
    ["Load"] = "Laden",
    ["Export"] = "Exportieren",
    ["Import"] = "Importieren",
    ["Copy to current"] = "Auf aktuelles kopieren",

    -- ===== Tabs / Seitentitel =====
    ["Cursor Spells"] = "Cursor-Zauber",
    ["Cursor Auras"] = "Cursor-Auren",
    ["Ring Auras"] = "Ring-Auren",
    ["Cursor Config"] = "Cursor-Konfig.",
    ["Ring Config"] = "Ring-Konfig.",
    ["Profiles"] = "Profile",

    -- ===== Editoren: Titel und Labels =====
    ["Cursor Spell"] = "Cursor-Zauber",
    ["Cursor Aura"] = "Cursor-Aura",
    ["Ring Aura"] = "Ring-Aura",
    ["New Cursor Spell"] = "Neuer Cursor-Zauber",
    ["New Cursor Aura"] = "Neue Cursor-Aura",
    ["New Ring Aura"] = "Neue Ring-Aura",
    ["Editing: "] = "Bearbeite: ",
    ["Spell name or ID:"] = "Zaubername oder ID:",
    ["Aura name or ID:"] = "Auraname oder ID:",
    ["Show only when charges >=  (0=always):"] = "Nur anzeigen wenn Aufladungen >=  (0=immer):",
    ["Stack text size (0=default):"] = "Stack-Textgröße (0=Standard):",
    ["Hide while on cooldown"] = "Während Abklingzeit ausblenden",
    ["Hide status overlay"] = "Status-Overlay ausblenden",
    ["Hide cooldown / duration timer"] = "Abklingzeit-/Dauer-Timer ausblenden",
    ["Hide timer"] = "Timer ausblenden",
    ["Specs:"] = "Spezialisierungen:",
    ["Required talent:"] = "Erforderliches Talent:",
    ["Unit:"] = "Einheit:",
    ["Type:"] = "Typ:",
    ["Show:"] = "Anzeigen:",
    ["Min stacks:"] = "Min. Stacks:",
    ["Duration (sec, 0=auto):"] = "Dauer (Sek., 0=auto):",
    ["Color:"] = "Farbe:",
    ["Show icon on ring"] = "Symbol auf Ring anzeigen",
    ["Play sound on activation"] = "Sound bei Aktivierung abspielen",
    ["Pulse icon at screen center on ready"] = "Symbolpuls in Bildschirmmitte bei Bereitschaft",
    ["Pulse icon at screen center on activation"] = "Symbolpuls in Bildschirmmitte bei Aktivierung",
    ["Play sound on ready"] = "Sound bei Bereitschaft abspielen",
    ["Pulse Display Settings"] = "Puls-Anzeige Einstellungen",
    ["Pulse Config"] = "Puls",
    ["Size & Timing"] = "Größe & Zeitpunkt",
    ["Hold Duration"] = "Haltedauer",
    ["Enable cooldown pulse"] = "Cooldown-Puls aktivieren",
    ["Show anchor"] = "Anker zeigen",
    ["Hide anchor"] = "Anker ausblenden",
    ["Test pulse"] = "Puls testen",
    ["Drag to move"] = "Zum Verschieben ziehen",

    -- ===== TalentPicker =====
    ["[No talent]"] = "[Kein Talent]",
    ["Select a talent"] = "Talent auswählen",
    ["search"] = "suchen",
    ["(no talents in this loadout)"] = "(keine Talente in diesem Loadout)",

    -- ===== SoundPicker =====
    ["Select a sound"] = "Sound auswählen",

    -- ===== DropZone =====
    ["Drag a spell here"] = "Zauber hierher ziehen",

    -- ===== Dropdowns: Einheiten / Filter / showWhen =====
    ["Target"] = "Ziel",
    ["Player"] = "Spieler",
    ["Focus"] = "Fokus",
    ["Mouseover"] = "Mauszeiger",
    ["Pet"] = "Begleiter",
    ["Buff"] = "Stärkungseffekt",
    ["Debuff"] = "Schwächungseffekt",
    ["Always"] = "Immer",
    ["Only missing"] = "Nur wenn fehlend",
    ["Only active"] = "Nur wenn aktiv",
    ["Active only"] = "Nur wenn aktiv",
    ["Missing only"] = "Nur wenn fehlend",
    ["Below stacks"] = "Unter Stacks",

    -- ===== Listenzeilen (Badges) =====
    ["Unknown"] = "Unbekannt",
    ["Min:"] = "Min:",
    ["Hide CD"] = "CD aus",
    ["Talent"] = "Talent",
    ["[icon]"] = "[Symbol]",

    -- ===== Empty-State / Hinweise auf Seiten =====
    ["No spells. Use 'Add Cursor Spell...' below."] = "Keine Zauber. Nutze 'Cursor-Zauber hinzufügen...' unten.",
    ["No auras. Use 'Add Cursor Aura...' below."] = "Keine Auren. Nutze 'Cursor-Aura hinzufügen...' unten.",
    ["No ring auras. Use 'Add Ring Aura...' below."] = "Keine Ring-Auren. Nutze 'Ring-Aura hinzufügen...' unten.",
    ["Spells shown as icons near the mouse cursor. Click the gear to edit."] = "Zauber werden als Symbole am Mauszeiger angezeigt. Klicke das Zahnrad zum Bearbeiten.",
    ["Auras shown as icons near the mouse cursor. Click the gear to edit."] = "Auren werden als Symbole am Mauszeiger angezeigt. Klicke das Zahnrad zum Bearbeiten.",
    ["Auras shown as circular rings around the character. Click the gear to edit, click color to change."] = "Auren werden als Ringe um den Charakter angezeigt. Klicke das Zahnrad zum Bearbeiten, klicke die Farbe zum Ändern.",
    ["Add Cursor Spell..."] = "Cursor-Zauber hinzufügen...",
    ["Add Cursor Aura..."] = "Cursor-Aura hinzufügen...",
    ["Add Ring Aura..."] = "Ring-Aura hinzufügen...",
    ["or drag a spell here:"] = "oder zieh einen Zauber hierher:",

    -- ===== Cursor-Einstellungen =====
    ["Cursor Display Settings"] = "Cursor-Anzeige-Einstellungen",
    ["Size & Layout"] = "Größe & Layout",
    ["Icon Size"] = "Symbolgröße",
    ["Icon Spacing"] = "Symbolabstand",
    ["Max Columns"] = "Max. Spalten",
    ["Font Size"] = "Schriftgröße",
    ["Position"] = "Position",
    ["Offset X"] = "Versatz X",
    ["Offset Y"] = "Versatz Y",
    ["Opacity"] = "Deckkraft",
    ["Update Interval"] = "Aktualisierungsintervall",
    ["Show only in combat"] = "Nur im Kampf anzeigen",
    ["Enable cursor display"] = "Cursor-Anzeige aktivieren",

    -- ===== Ring-Einstellungen =====
    ["Ring Display Settings"] = "Ring-Anzeige-Einstellungen",
    ["Size"] = "Größe",
    ["Base Radius"] = "Basisradius",
    ["Ring Thickness"] = "Ringdicke",
    ["Ring Spacing"] = "Ringabstand",
    ["Appearance"] = "Erscheinungsbild",
    ["Segments (smooth)"] = "Segmente (geglättet)",
    ["Enable ring display"] = "Ring-Anzeige aktivieren",

    -- ===== Profile-Seite =====
    ["Profile Manager"] = "Profilverwaltung",
    ["Active: "] = "Aktiv: ",
    ["(active)"] = "(aktiv)",
    ["Create New Profile"] = "Neues Profil erstellen",
    ["Copy From Profile"] = "Aus Profil kopieren",
    ["Export Current Profile"] = "Aktuelles Profil exportieren",
    ["(Press Export then Ctrl+C in the box)"] = "(Exportieren drücken, dann Strg+C im Feld)",
    ["Import Profile"] = "Profil importieren",
    ["Name:"] = "Name:",
    ["(paste below and press Import)"] = "(unten einfügen und Importieren drücken)",

    -- ===== Minimap-Tooltip =====
    ["Left click:"] = "Linksklick:",
    ["Right click:"] = "Rechtsklick:",
    ["Drag:"] = "Ziehen:",
    ["open/close config"] = "Konfig. öffnen/schließen",
    ["toggle cursor + ring icons"] = "Cursor- + Ring-Symbole umschalten",
    ["move icon"] = "Symbol verschieben",

    -- ===== Lade-Meldung =====
    ["loaded"] = "geladen",
    ["Profile:"] = "Profil:",
    ["Type"] = "Tippe",
    ["for options"] = "für Optionen",

    -- ===== Talentbaum-Bezeichnungen =====
    ["Class"] = "Klasse",
    ["Hero"] = "Heldenklasse",
    -- "Spec" bleibt unverändert (üblich im deutschen Client).

    -- ===== Changelog / What's New =====
    ["What's New"] = "Neuigkeiten",
    ["Got it"] = "Verstanden",
    ["Changelog"] = "Änderungsprotokoll",
    ["View release notes for all versions"] = "Versionshinweise aller Versionen anzeigen",

    -- ===== Release notes 1.4.0 =====
    ["Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically."] =
        "Trinkets oder Tränke aus deinen Taschen oder ausgerüsteten Plätzen in die Eingabezone ziehen — das Addon ermittelt automatisch die Zauber-ID des Nutzungseffekts.",
    ["Per-entry visibility for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility)."] =
        "Sichtbarkeit pro Eintrag für Cursor-Zauber und Auren: Immer / Nur im Kampf / Nur außerhalb des Kampfes (unabhängig von der globalen Cursor-Sichtbarkeit).",
    ["Per-entry visual overrides for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely)."] =
        "Visuelle Überschreibungen pro Eintrag für Cursor-Zauber und Auren: Symbolgröße, Deckkraft und eigene Position mit Offset X/Y (das Symbol löst sich vom Raster und schwebt frei).",
    ["Tabbed editor modals: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound."] =
        "Editor-Modals mit Tabs: Cursor Spell und Cursor Aura aufgeteilt in General / Display / Effects; Ring Aura in General / Effects; Pulse Spell und Pulse Aura in General / Sound.",
    ["Changelog button (?) in the config window title bar — opens this popup with all release notes on demand."] =
        "Changelog-Schaltfläche (?) in der Titelleiste des Konfigurationsfensters — öffnet dieses Popup mit allen Versionshinweisen auf Abruf.",
    ["Fix: 'Spell not found' when adding via the autocomplete dropdown for spells/auras the character does not know. The autocomplete-resolved spell ID is now preferred over name lookup."] =
        "Fix: 'Zauber nicht gefunden' beim Hinzufügen über das Autovervollständigungs-Dropdown für Zauber/Auren, die der Charakter nicht kennt. Die vom Autocomplete aufgelöste Zauber-ID wird jetzt der Namenssuche vorgezogen.",
    ["Fix: creating or switching profiles left some menus showing the old profile's values. Config pages are now rebuilt against the active profile on every switch."] =
        "Fix: Beim Erstellen oder Wechseln von Profilen zeigten einige Menüs noch Werte des alten Profils. Die Konfigurationsseiten werden nun bei jedem Wechsel gegen das aktive Profil neu aufgebaut.",

    -- ===== Release notes 1.5.0 =====
    ["Track items as cooldowns: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New 'Add Item...' button + drag-and-drop dispatches by type (spell vs item) and opens the right editor."] =
        "Items als Cooldowns verfolgen: Schmuckstücke, Tränke und on-use-Verbrauchsgüter können jetzt zur Cursor- oder Pulse-Liste hinzugefügt werden. Neue 'Add Item...'-Schaltfläche + Drag-and-Drop verteilt nach Typ (Zauber vs. Item) und öffnet den richtigen Editor.",
    ["Item editors with full tabs (mirror of the Spell editor): General + Display + Effects for cursor items; General + Sound for pulse items. Visual overrides, hide flags, pulse on ready, sound — all available."] =
        "Item-Editoren mit vollständigen Tabs (Spiegel des Zauber-Editors): General + Display + Effects für Cursor-Items; General + Sound für Pulse-Items. Visuelle Überschreibungen, Hide-Flags, Pulse bei Bereitschaft, Ton — alles verfügbar.",
    ["Per-entry instance-type filter on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP (Arena/BG), Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances."] =
        "Filter pro Eintrag nach Instanztyp in jedem Aura-/Zauber-/Item-Editor: Tracking auf Offene Welt, Delves, PvP (Arena/BG), Schlachtzug, Mythisch+ und/oder Dungeon beschränken. Reagiert sofort beim Betreten/Verlassen von Instanzen.",
    ["Aura detection paths 6 + 7: slot iteration (catches semi-restricted auras Midnight hides from name/ID lookups) + manual trigger workaround (for fully-restricted auras like consumable buffs — configure a trigger spell or item ID and the addon synthesizes the ACTIVE state on cast/use)."] =
        "Aura-Erkennungspfade 6 + 7: Slot-Iteration (fängt semi-eingeschränkte Auren, die Midnight vor Namen-/ID-Lookups versteckt) + manueller Trigger-Workaround (für vollständig eingeschränkte Auren wie Verbrauchsgüter-Buffs — konfiguriere eine Trigger-Zauber- oder Item-ID und das Addon synthetisiert den ACTIVE-Status beim Wirken/Verwenden).",
    ["New /hht listauras command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID of a buff when the guessed one isn't detected."] =
        "Neuer /hht listauras Befehl: gibt jeden aktiven Buff/Debuff mit Name + spellID + Quelle + Dauer aus. Nützlich, um die echte spellID eines Buffs zu finden, wenn die geratene nicht erkannt wird.",
    ["Config window no longer closes when opening the Spellbook (PlayerSpellsFrame). ESC still closes it via a custom handler that doesn't break other keybinds."] =
        "Konfigurationsfenster schließt sich nicht mehr beim Öffnen des Zauberbuchs (PlayerSpellsFrame). ESC schließt es weiterhin über einen eigenen Handler, der andere Keybinds nicht bricht.",
    ["Fix: comparing SecureNumber spellId in slot iteration tainted the addon ('attempt to compare a secret number value'). Wrapped in ToPublic + pcall — fully restricted auras are skipped safely instead of crashing the whole frame."] =
        "Fix: Vergleich von SecureNumber spellId in der Slot-Iteration verunreinigte das Addon ('attempt to compare a secret number value'). In ToPublic + pcall verpackt — vollständig eingeschränkte Auren werden sicher übersprungen, statt den gesamten Frame zum Absturz zu bringen.",
    ["Fix: ApplyRingVisibility nil call when a ring test entry expired (forward declaration bug, latent since 1.3.0)."] =
        "Fix: ApplyRingVisibility nil-Aufruf, wenn ein Ring-Test-Eintrag abgelaufen ist (Forward-Declaration-Bug, latent seit 1.3.0).",

    -- ===== Release notes 1.6.0 =====
    ["Macro trigger system: every aura, pulse, and item editor has a new 'Trigger key' field. Fire any configured display from a macro with /hht trigger <key> or from another addon via HNZHealingTools.Trigger(key). Multiple entries can share a key — one keybind fires them all at once."] =
        "Makro-Trigger-System: Jeder Aura-, Pulse- und Item-Editor hat ein neues Feld 'Trigger key'. Löse jede konfigurierte Anzeige aus einem Makro mit /hht trigger <key> oder aus einem anderen Addon via HNZHealingTools.Trigger(key) aus. Mehrere Einträge können sich einen Key teilen — ein Keybind löst sie alle gleichzeitig aus.",
    ["New Macros help page in the config sidebar with copy-pasteable macro examples and Lua snippets."] =
        "Neue Seite 'Macros' in der Konfigurations-Seitenleiste mit kopierbaren Makro-Beispielen und Lua-Snippets.",
    ["Floating preview popup: 'Show preview' button at the top of pages with a Live Preview block (Cursor / Ring / Pulse settings + Cursor Ring sub-tabs). Opens to the right of the config window, single-active across pages, inherits position when switching."] =
        "Schwebendes Vorschau-Popup: 'Vorschau anzeigen'-Knopf oben auf Seiten mit Live-Vorschau (Cursor / Ring / Pulse-Einstellungen + Cursor-Ring-Unterregister). Öffnet rechts vom Konfigurationsfenster, jeweils nur eines aktiv, übernimmt die Position beim Wechsel.",
    ["Stack count now displays correctly for fully-restricted auras tracked by Blizzard's Cooldown Manager (e.g. Mana Tea). The addon now reads the stack count via the same SetText/GetText technique Blizzard's own CDM viewer uses, so SecureNumber values are no longer lost in combat."] =
        "Stack-Anzahl wird jetzt korrekt angezeigt für vollständig eingeschränkte Auren, die von Blizzards Cooldown Manager getrackt werden (z. B. Mana-Tee). Das Addon liest den Stack-Wert jetzt über dieselbe SetText/GetText-Technik wie Blizzards eigene CDM-Anzeige, sodass SecureNumber-Werte im Kampf nicht mehr verloren gehen.",
    ["Restricted auras visible in the Cooldown Manager but invisible to addon APIs now synthesize ACTIVE state from the CDM hook (stacks + appliedAt) — icon + count + optional timer render correctly even when all 6 detection paths fail."] =
        "Eingeschränkte Auren, die im Cooldown Manager sichtbar, aber für Addon-APIs unsichtbar sind, synthetisieren jetzt den ACTIVE-Status aus dem CDM-Hook (stacks + appliedAt) — Icon + Zähler + optionaler Timer werden korrekt gerendert, auch wenn alle 6 Erkennungspfade versagen.",
    ["/hht auradebug now reports inCombat status, CDM-captured stack count, and the full list of FontStrings on the matching CDM frame — useful for diagnosing in-combat detection failures."] =
        "/hht auradebug meldet jetzt den Kampfstatus (inCombat), den vom CDM erfassten Stack-Wert und die komplette Liste der FontStrings im passenden CDM-Frame — nützlich, um Erkennungsfehler im Kampf zu diagnostizieren.",
    ["Public API namespace _G.HNZHealingTools exposed for macros and other addons (.version, .Trigger(key))."] =
        "Öffentlicher API-Namespace _G.HNZHealingTools für Makros und andere Addons verfügbar (.version, .Trigger(key)).",

    -- ===== Macros page + trigger UI =====
    ["Macros"] = "Makros",
    ["Trigger key:"] = "Trigger-Schlüssel:",
    ["Show preview"] = "Vorschau anzeigen",
    ["Optional. Fire this aura from a macro: /hht trigger <key>. Requires Duration > 0. Case-insensitive."] =
        "Optional. Diese Aura aus einem Makro auslösen: /hht trigger <key>. Benötigt Duration > 0. Groß-/Kleinschreibung egal.",
    ["Optional. Fire this pulse from a macro: /hht trigger <key>. Case-insensitive."] =
        "Optional. Diesen Pulse aus einem Makro auslösen: /hht trigger <key>. Groß-/Kleinschreibung egal.",
    ["Optional. Fire this item from a macro: /hht trigger <key>. Case-insensitive."] =
        "Optional. Dieses Item aus einem Makro auslösen: /hht trigger <key>. Groß-/Kleinschreibung egal.",
    ["Usage: /hht trigger <key>"] = "Verwendung: /hht trigger <key>",
    ["Triggered %d entrie(s) for key '%s'"] = "%d Eintrag/Einträge für Key '%s' ausgelöst",
    ["No entries match triggerKey '%s'"] = "Keine Einträge passen zu triggerKey '%s'",
    ["Trigger displays from macros"] = "Anzeigen aus Makros auslösen",
    ["You can fire any aura or pulse from a macro, keybind, or another addon — without needing the actual aura/cooldown to trigger. Useful for one-shot visual signals (panic ring, cooldown reminder, callout from a partner addon)."] =
        "Du kannst jede Aura oder jeden Pulse aus einem Makro, Keybind oder anderen Addon auslösen — ohne dass die eigentliche Aura/Abklingzeit auslösen muss. Nützlich für einmalige visuelle Signale (Panik-Ring, Abklingzeit-Erinnerung, Callout aus einem Partner-Addon).",
    ["1. Where you can set a Trigger key"] = "1. Wo du einen Trigger-Schlüssel setzen kannst",
    ["Open the editor of any of these and fill in the \"Trigger key\" field:"] =
        "Öffne den Editor eines dieser Elemente und fülle das Feld \"Trigger-Schlüssel\" aus:",
    ["  • Cursor Aura — fires the aura's icon at cursor for its Duration."] =
        "  • Cursor-Aura — löst das Aura-Icon am Cursor für ihre Duration aus.",
    ["  • Ring Aura — fires the colored ring around your character for its Duration."] =
        "  • Ring-Aura — löst den farbigen Ring um deinen Charakter für ihre Duration aus.",
    ["  • Cursor Item — fires the central pulse with the item's icon + optional sound."] =
        "  • Cursor-Item — löst den zentralen Pulse mit dem Item-Icon + optionalem Sound aus.",
    ["  • Pulse Spell / Pulse Aura / Pulse Item — fires the central screen pulse + optional sound."] =
        "  • Pulse-Spell / Pulse-Aura / Pulse-Item — löst den zentralen Bildschirm-Pulse + optionalen Sound aus.",
    ["2. Fire it"] = "2. Löse es aus",
    ["From a chat message or macro line:"] = "Aus einer Chatnachricht oder Makro-Zeile:",
    ["From Lua (other addons, /run, WeakAuras custom code):"] =
        "Aus Lua (andere Addons, /run, WeakAuras-Custom-Code):",
    ["Example: cast + trigger together"] = "Beispiel: Zauber + Trigger zusammen",
    ["Combine a real cast with a visual trigger in one macro:"] =
        "Kombiniere einen echten Zauber mit einem visuellen Trigger in einem Makro:",
    ["Tips"] = "Tipps",
    ["  • Multiple entries can share the same trigger key — they all fire at once (e.g. one key can show a Ring Aura + play a Pulse simultaneously)."] =
        "  • Mehrere Einträge können sich denselben Trigger-Schlüssel teilen — sie werden alle gleichzeitig ausgelöst (z. B. ein Key zeigt eine Ring-Aura + spielt einen Pulse gleichzeitig).",
    ["  • Trigger keys are case-insensitive. \"Panic\" and \"panic\" match the same entries."] =
        "  • Trigger-Schlüssel sind groß-/klein-schreibungsunabhängig. \"Panic\" und \"panic\" treffen dieselben Einträge.",
    ["  • Aura entries (Cursor / Ring) require Duration > 0 — without a duration there's no way to know when the visual should disappear."] =
        "  • Aura-Einträge (Cursor / Ring) benötigen Duration > 0 — ohne Dauer gibt es keine Möglichkeit zu wissen, wann das Visuelle verschwinden soll.",
    ["  • Pulse entries fire immediately and the animation has its own length (configured globally in Pulse → Config)."] =
        "  • Pulse-Einträge werden sofort ausgelöst, und die Animation hat ihre eigene Länge (global konfiguriert in Pulse → Config).",
    ["  • HNZHealingTools.Trigger(key) returns the number of entries that matched (0 = no entries have that key)."] =
        "  • HNZHealingTools.Trigger(key) gibt die Anzahl übereinstimmender Einträge zurück (0 = kein Eintrag mit diesem Key).",
    ["  • Combat-safe: trigger keys work during combat lockdown."] =
        "  • Kampfsicher: Trigger-Schlüssel funktionieren während Combat Lockdown.",

    -- ===== Raid Spells (Alpha) =====
    ["Raid Spells"] = "Schlachtzug Zauber (A)",

    -- ===== Simulated Auras (Coming Soon) =====
    ["Simulated Auras"] = "Simulierte Auren (A)",
    ["Coming soon"] = "Demnächst",

    -- ===== Ready Check Panel — talent loadout content type =====
    ["Dungeon / M+"] = "Dungeon / M+",
    ["No loadout assigned for %s"] = "Keine Talentauswahl zugewiesen für %s",
    ["Wrong talent build"] = "Falsche Talentauswahl",

    -- ===== Release 1.9.0 notes =====
    ["Raid Spells (A): the panel now lists every healer in your raid who has the addon enabled, not just those who cast something in the last 5 seconds. Discovery is automatic via a hello protocol broadcast on group join and every 60s; stale entries are pruned after 3 minutes of silence."] =
        "Schlachtzug Zauber (A): Das Panel listet jetzt jeden Heiler im Schlachtzug auf, der das Addon aktiviert hat — nicht nur jene, die in den letzten 5 Sekunden gewirkt haben. Die Erkennung erfolgt automatisch via Hello-Broadcast beim Gruppenbeitritt und alle 60 Sekunden; veraltete Einträge werden nach 3 Minuten Stille entfernt.",
    ["Raid Spells (A): each cast icon now shows a compact age label (5s / 2m / 1h) under it. Replaces the age-based alpha fade — the elapsed time is communicated explicitly."] =
        "Schlachtzug Zauber (A): Jedes Zaubersymbol zeigt jetzt ein kompaktes Alterskennzeichen (5s / 2m / 1h) darunter. Ersetzt das altersbasierte Alpha-Ausblenden — die verstrichene Zeit wird explizit angezeigt.",
    ["Raid Spells (A): panel only shows inside a raid instance by default (it was incorrectly visible in the open world when in a raid group during world events / world bosses)."] =
        "Schlachtzug Zauber (A): Das Panel ist standardmäßig nur innerhalb einer Schlachtzug-Instanz sichtbar (es wurde fälschlich in der offenen Welt angezeigt, wenn man in einer Schlachtzuggruppe bei Welt-Events / Weltbossen war).",
    ["Raid Spells (A): drag works correctly — fixed a regression where the 0.5s refresh ticker re-anchored the panel mid-drag and snapped it back to the saved position."] =
        "Schlachtzug Zauber (A): Ziehen funktioniert wieder korrekt — ein Regressionsfehler, bei dem der 0,5s-Refresh-Ticker das Panel während des Ziehens neu verankerte, wurde behoben.",
    ["Ready Check Panel: talent build row now shows an explicit warning when no loadout is assigned for the current content type (yellow text + red X) instead of a silent neutral state. Configure assignments in Config → Ready Check → Talents."] =
        "Bereitschaftsprüfungs-Panel: Die Talentauswahl-Zeile zeigt jetzt eine explizite Warnung (gelber Text + rotes X), wenn für den aktuellen Inhaltstyp keine Talentauswahl zugewiesen ist, statt eines stillen neutralen Zustands. Zuweisungen unter Config → Bereitschaftsprüfung → Talente.",
    ["Ready Check Panel: Dungeon and Mythic+ talent loadout categories merged into a single 'Dungeon / M+' checkbox. The ready check fires in the lobby before the keystone is inserted, so the distinction wasn't useful. Existing 'mplus=true' assignments still work as a synonym for 'dungeon'."] =
        "Bereitschaftsprüfungs-Panel: Die Talentauswahl-Kategorien Dungeon und Mythisch+ wurden zu einer einzigen Checkbox „Dungeon / M+\" zusammengefügt. Die Bereitschaftsprüfung erfolgt in der Lobby bevor der Schlüsselstein eingesetzt wird, daher war die Unterscheidung nicht hilfreich. Bestehende „mplus=true\"-Zuweisungen funktionieren weiterhin als Synonym für „dungeon\".",
    ["Ready Check Panel: default panel width bumped 320 → 420px so the longer status texts (e.g. 'No loadout assigned for Dungeon / M+') no longer get clipped. Slider max raised to 700. Migration v6 auto-bumps profiles still on the old default."] =
        "Bereitschaftsprüfungs-Panel: Standardbreite von 320 → 420px erhöht, damit längere Statustexte (z. B. „Keine Talentauswahl zugewiesen für Dungeon / M+\") nicht abgeschnitten werden. Schieberegler-Maximum auf 700 erhöht. Migration v6 aktualisiert Profile automatisch, die noch auf dem alten Standard sind.",
    ["Ready Check Panel: removed the 'Use' button from the healthstone cell — healthstones are combat-only and the ready check fires out of combat, so the click did nothing. Icon + count remain to indicate you have stones."] =
        "Bereitschaftsprüfungs-Panel: Der „Benutzen\"-Button beim Gesundheitsstein wurde entfernt — Gesundheitssteine sind kampfgebunden und die Bereitschaftsprüfung erfolgt außerhalb des Kampfes, daher bewirkte der Klick nichts. Symbol + Anzahl bleiben sichtbar.",
    ["Ready Check Panel: cauldron-cast Phial aura 1235108 added to the known flask aura list (was reported as missing)."] =
        "Bereitschaftsprüfungs-Panel: Die Phiolen-Aura 1235108 (Kessel) wurde der Liste bekannter Flakon-Auren hinzugefügt.",
    ["Aura tracking: fixed the 'ring stays active after the buff expired' bug for spells with known durations (e.g. Barkskin). When the Cooldown Manager cache has a stale entry whose appliedAt + duration is in the past, we now evict it and report MISSING instead of leaving the ring lit indefinitely. Also clears the CDM cache on zone changes (PLAYER_ENTERING_WORLD full updates)."] =
        "Auren-Verfolgung: Behoben — der Bug „Ring bleibt aktiv nachdem der Buff abgelaufen ist\" bei Zaubern mit bekannter Dauer (z. B. Baumrinde). Wenn der Cooldown-Manager-Cache einen veralteten Eintrag hat, dessen appliedAt + duration in der Vergangenheit liegt, wird er jetzt entfernt und MISSING gemeldet. Der CDM-Cache wird zudem bei Zonenwechseln (PLAYER_ENTERING_WORLD Full Updates) geleert.",
    ["Simulated Auras (A): new sidebar entry, currently 'Coming Soon'. The underlying state machine works via /hnzsim <spellID> and tracks an apply-then-consume aura pattern (for spells whose aura is hidden from the WoW API). UI integration with Cursor/Ring display is still in testing."] =
        "Simulierte Auren (A): Neuer Seitenleisten-Eintrag, derzeit „Demnächst\". Die zugrunde liegende Zustandsmaschine funktioniert via /hnzsim <spellID> und verfolgt ein Apply-then-Consume-Aura-Muster. Die UI-Integration mit Cursor-/Ring-Anzeige wird noch getestet.",
})
