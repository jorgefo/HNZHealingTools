local _, ns = ...

-- Deutsche Übersetzungen (deDE). Schlüssel sind die englischen UI-Texte aus ns.L[...].
-- Fehlende Schlüssel fallen über die Metatable in Locales.lua auf Englisch zurück.
ns.RegisterLocale("deDE", {
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
})
