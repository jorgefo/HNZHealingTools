local _, ns = ...

-- Traductions françaises (frFR). Les clés sont les textes anglais utilisés dans ns.L[...].
-- Les clés manquantes retombent sur l'anglais via la metatable de Locales.lua.
ns.RegisterLocale("frFR", {
    -- ===== Messages d'erreur / retour =====
    ["Spell not found: "] = "Sort introuvable : ",
    [" already monitored."] = " est déjà surveillé.",
    ["Enter a name/ID."] = "Entrez un nom/ID.",
    ["Enter a name."] = "Entrez un nom.",
    ["Already exists."] = "Existe déjà.",
    ["Created: "] = "Créé : ",
    ["Can't copy to itself."] = "Impossible de copier sur soi-même.",
    ["Copied from "] = "Copié depuis ",
    ["Give the profile a name."] = "Donnez un nom au profil.",
    ["Paste the exported string in the box."] = "Collez la chaîne exportée dans la boîte.",
    ["Imported as: "] = "Importé sous : ",
    ["Import failed."] = "Échec de l'import.",
    ["Ready: Ctrl+C to copy"] = "Prêt : Ctrl+C pour copier",
    ["No active profile to export"] = "Aucun profil actif à exporter",

    -- ===== Boutons génériques =====
    ["Save"] = "Enregistrer",
    ["Cancel"] = "Annuler",
    ["Add"] = "Ajouter",
    ["Update"] = "Mettre à jour",
    ["Close"] = "Fermer",
    ["Edit"] = "Modifier",
    ["Test"] = "Tester",
    ["Create"] = "Créer",
    ["Load"] = "Charger",
    ["Export"] = "Exporter",
    ["Import"] = "Importer",
    ["Copy to current"] = "Copier vers actuel",

    -- ===== Onglets / titres de page =====
    ["Cursor Spells"] = "Sorts du curseur",
    ["Cursor Auras"] = "Auras du curseur",
    ["Ring Auras"] = "Auras en anneau",
    ["Cursor Config"] = "Config. curseur",
    ["Ring Config"] = "Config. anneau",
    ["Profiles"] = "Profils",

    -- ===== Éditeurs : titres et labels =====
    ["Cursor Spell"] = "Sort du curseur",
    ["Cursor Aura"] = "Aura du curseur",
    ["Ring Aura"] = "Aura en anneau",
    ["New Cursor Spell"] = "Nouveau sort du curseur",
    ["New Cursor Aura"] = "Nouvelle aura du curseur",
    ["New Ring Aura"] = "Nouvelle aura en anneau",
    ["Editing: "] = "Édition : ",
    ["Spell name or ID:"] = "Nom du sort ou ID :",
    ["Aura name or ID:"] = "Nom de l'aura ou ID :",
    ["Show only when charges >=  (0=always):"] = "Afficher seulement quand charges >=  (0=toujours) :",
    ["Stack text size (0=default):"] = "Taille texte stacks (0=défaut) :",
    ["Hide while on cooldown"] = "Masquer pendant le temps de recharge",
    ["Hide status overlay"] = "Masquer la superposition d'état",
    ["Hide cooldown / duration timer"] = "Masquer le minuteur de recharge/durée",
    ["Hide timer"] = "Masquer le minuteur",
    ["Specs:"] = "Spécialisations :",
    ["Required talent:"] = "Talent requis :",
    ["Unit:"] = "Unité :",
    ["Type:"] = "Type :",
    ["Show:"] = "Afficher :",
    ["Min stacks:"] = "Stacks min. :",
    ["Duration (sec, 0=auto):"] = "Durée (sec, 0=auto) :",
    ["Color:"] = "Couleur :",
    ["Show icon on ring"] = "Afficher l'icône sur l'anneau",
    ["Play sound on activation"] = "Jouer un son à l'activation",
    ["Pulse icon at screen center on ready"] = "Pulse de l'icône au centre de l'écran quand prêt",
    ["Pulse icon at screen center on activation"] = "Pulse de l'icône au centre de l'écran à l'activation",
    ["Play sound on ready"] = "Jouer un son quand prêt",
    ["Pulse Display Settings"] = "Paramètres d'affichage du pulse",
    ["Pulse Config"] = "Pulse",
    ["Size & Timing"] = "Taille et durée",
    ["Hold Duration"] = "Durée d'affichage",
    ["Enable cooldown pulse"] = "Activer le pulse de cooldown",
    ["Show anchor"] = "Afficher l'ancrage",
    ["Hide anchor"] = "Masquer l'ancrage",
    ["Test pulse"] = "Tester le pulse",
    ["Drag to move"] = "Glisser pour déplacer",

    -- ===== TalentPicker =====
    ["[No talent]"] = "[Aucun talent]",
    ["Select a talent"] = "Sélectionner un talent",
    ["search"] = "rechercher",
    ["(no talents in this loadout)"] = "(aucun talent dans ce loadout)",

    -- ===== SoundPicker =====
    ["Select a sound"] = "Sélectionner un son",

    -- ===== DropZone =====
    ["Drag a spell here"] = "Glissez un sort ici",

    -- ===== Dropdowns : unités / filtres / showWhen =====
    ["Target"] = "Cible",
    ["Player"] = "Joueur",
    ["Focus"] = "Focalisation",
    ["Mouseover"] = "Survol souris",
    ["Pet"] = "Familier",
    ["Buff"] = "Bénéfique",
    ["Debuff"] = "Préjudiciable",
    ["Always"] = "Toujours",
    ["Only missing"] = "Seulement si manquant",
    ["Only active"] = "Seulement si actif",
    ["Active only"] = "Seulement si actif",
    ["Missing only"] = "Seulement si manquant",
    ["Below stacks"] = "Sous le seuil de stacks",

    -- ===== Lignes de liste (badges) =====
    ["Unknown"] = "Inconnu",
    ["Min:"] = "Min :",
    ["Hide CD"] = "Sans CD",
    ["Talent"] = "Talent",
    ["[icon]"] = "[icône]",

    -- ===== États vides / indications =====
    ["No spells. Use 'Add Cursor Spell...' below."] = "Aucun sort. Utilisez 'Ajouter un sort de curseur...' ci-dessous.",
    ["No auras. Use 'Add Cursor Aura...' below."] = "Aucune aura. Utilisez 'Ajouter une aura de curseur...' ci-dessous.",
    ["No ring auras. Use 'Add Ring Aura...' below."] = "Aucune aura en anneau. Utilisez 'Ajouter une aura en anneau...' ci-dessous.",
    ["Spells shown as icons near the mouse cursor. Click the gear to edit."] = "Sorts affichés en icônes près du curseur. Cliquez sur l'engrenage pour modifier.",
    ["Auras shown as icons near the mouse cursor. Click the gear to edit."] = "Auras affichées en icônes près du curseur. Cliquez sur l'engrenage pour modifier.",
    ["Auras shown as circular rings around the character. Click the gear to edit, click color to change."] = "Auras affichées en anneaux autour du personnage. Cliquez sur l'engrenage pour modifier, cliquez la couleur pour la changer.",
    ["Add Cursor Spell..."] = "Ajouter un sort de curseur...",
    ["Add Cursor Aura..."] = "Ajouter une aura de curseur...",
    ["Add Ring Aura..."] = "Ajouter une aura en anneau...",
    ["or drag a spell here:"] = "ou glissez un sort ici :",

    -- ===== Page Réglages curseur =====
    ["Cursor Display Settings"] = "Réglages d'affichage du curseur",
    ["Size & Layout"] = "Taille et disposition",
    ["Icon Size"] = "Taille d'icône",
    ["Icon Spacing"] = "Espacement d'icônes",
    ["Max Columns"] = "Colonnes max.",
    ["Font Size"] = "Taille de police",
    ["Position"] = "Position",
    ["Offset X"] = "Décalage X",
    ["Offset Y"] = "Décalage Y",
    ["Opacity"] = "Opacité",
    ["Update Interval"] = "Intervalle de rafraîchissement",
    ["Show only in combat"] = "Afficher seulement en combat",
    ["Enable cursor display"] = "Activer l'affichage du curseur",

    -- ===== Page Réglages anneau =====
    ["Ring Display Settings"] = "Réglages d'affichage de l'anneau",
    ["Size"] = "Taille",
    ["Base Radius"] = "Rayon de base",
    ["Ring Thickness"] = "Épaisseur de l'anneau",
    ["Ring Spacing"] = "Espacement entre anneaux",
    ["Appearance"] = "Apparence",
    ["Segments (smooth)"] = "Segments (lissé)",
    ["Enable ring display"] = "Activer l'affichage de l'anneau",

    -- ===== Page Profils =====
    ["Profile Manager"] = "Gestionnaire de profils",
    ["Active: "] = "Actif : ",
    ["(active)"] = "(actif)",
    ["Create New Profile"] = "Créer un nouveau profil",
    ["Copy From Profile"] = "Copier depuis un profil",
    ["Export Current Profile"] = "Exporter le profil actuel",
    ["(Press Export then Ctrl+C in the box)"] = "(Appuyez sur Exporter puis Ctrl+C dans la boîte)",
    ["Import Profile"] = "Importer un profil",
    ["Name:"] = "Nom :",
    ["(paste below and press Import)"] = "(collez ci-dessous et appuyez sur Importer)",

    -- ===== Tooltip minimap =====
    ["Left click:"] = "Clic gauche :",
    ["Right click:"] = "Clic droit :",
    ["Drag:"] = "Glisser :",
    ["open/close config"] = "ouvrir/fermer la config",
    ["toggle cursor + ring icons"] = "basculer icônes curseur + anneau",
    ["move icon"] = "déplacer l'icône",

    -- ===== Message de chargement =====
    ["loaded"] = "chargé",
    ["Profile:"] = "Profil :",
    ["Type"] = "Tapez",
    ["for options"] = "pour les options",

    -- ===== Étiquettes d'arbre de talents =====
    ["Class"] = "Classe",
    ["Hero"] = "Héros",
    -- "Spec" reste tel quel (terme commun dans le client français).

    -- ===== Changelog / What's New =====
    ["What's New"] = "Quoi de neuf",
    ["Got it"] = "Compris",
    ["Changelog"] = "Journal des modifications",
    ["View release notes for all versions"] = "Voir les notes de version de toutes les versions",

    -- ===== Release notes 1.4.0 =====
    ["Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically."] =
        "Glissez bijoux ou potions depuis vos sacs ou emplacements équipés vers la zone de saisie — l'addon résout automatiquement l'ID du sort de l'effet d'utilisation.",
    ["Per-entry visibility for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility)."] =
        "Visibilité par entrée pour les sorts et auras du curseur : Toujours / Uniquement en combat / Uniquement hors combat (indépendante de la visibilité globale du curseur).",
    ["Per-entry visual overrides for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely)."] =
        "Surcharges visuelles par entrée pour les sorts et auras du curseur : taille d'icône, opacité, et position personnalisée avec offset X/Y (l'icône se détache de la grille et flotte librement).",
    ["Tabbed editor modals: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound."] =
        "Modales d'édition à onglets : Cursor Spell et Cursor Aura divisés en General / Display / Effects ; Ring Aura en General / Effects ; Pulse Spell et Pulse Aura en General / Sound.",
    ["Changelog button (?) in the config window title bar — opens this popup with all release notes on demand."] =
        "Bouton Changelog (?) dans la barre de titre de la fenêtre de configuration — ouvre ce popup avec toutes les notes de version sur demande.",
    ["Fix: 'Spell not found' when adding via the autocomplete dropdown for spells/auras the character does not know. The autocomplete-resolved spell ID is now preferred over name lookup."] =
        "Correctif : 'Sort introuvable' lors de l'ajout via le menu d'autocomplétion pour les sorts/auras que le personnage ne connaît pas. L'ID de sort résolu par l'autocomplétion est désormais préféré à la recherche par nom.",
    ["Fix: creating or switching profiles left some menus showing the old profile's values. Config pages are now rebuilt against the active profile on every switch."] =
        "Correctif : créer ou changer de profil laissait certains menus avec les valeurs de l'ancien profil. Les pages de configuration sont maintenant reconstruites contre le profil actif à chaque changement.",

    -- ===== Release notes 1.5.0 =====
    ["Track items as cooldowns: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New 'Add Item...' button + drag-and-drop dispatches by type (spell vs item) and opens the right editor."] =
        "Suivre les objets comme cooldowns : bijoux, potions et consommables à utilisation peuvent maintenant être ajoutés à la liste Cursor ou Pulse. Nouveau bouton 'Add Item...' + glisser-déposer dispatch par type (sort vs objet) et ouvre le bon éditeur.",
    ["Item editors with full tabs (mirror of the Spell editor): General + Display + Effects for cursor items; General + Sound for pulse items. Visual overrides, hide flags, pulse on ready, sound — all available."] =
        "Éditeurs d'objets avec onglets complets (miroir de l'éditeur de Sort) : General + Display + Effects pour les objets du curseur ; General + Sound pour les objets du pulse. Overrides visuels, hide flags, pulse au prêt, son — tout disponible.",
    ["Per-entry instance-type filter on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP (Arena/BG), Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances."] =
        "Filtre par entrée selon le type d'instance dans chaque éditeur d'aura/sort/objet : restreindre le suivi à Monde ouvert, Delves, PvP (Arène/BG), Raid, Mythique+ et/ou Donjon. Réagit instantanément à l'entrée/sortie des instances.",
    ["Aura detection paths 6 + 7: slot iteration (catches semi-restricted auras Midnight hides from name/ID lookups) + manual trigger workaround (for fully-restricted auras like consumable buffs — configure a trigger spell or item ID and the addon synthesizes the ACTIVE state on cast/use)."] =
        "Chemins de détection d'aura 6 + 7 : itération des slots (capture les auras semi-restreintes que Midnight cache des lookups par nom/ID) + workaround de déclencheur manuel (pour les auras totalement restreintes comme les buffs de consommables — configure un sort ou un ID d'objet déclencheur et l'addon synthétise l'état ACTIVE au cast/utilisation).",
    ["New /hht listauras command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID of a buff when the guessed one isn't detected."] =
        "Nouvelle commande /hht listauras : affiche tous les buffs/debuffs actifs avec nom + spellID + source + durée. Utile pour trouver le vrai spellID d'un buff quand celui deviné n'est pas détecté.",
    ["Config window no longer closes when opening the Spellbook (PlayerSpellsFrame). ESC still closes it via a custom handler that doesn't break other keybinds."] =
        "La fenêtre de config ne se ferme plus à l'ouverture du Grimoire (PlayerSpellsFrame). ECHAP la ferme toujours via un handler personnalisé qui ne casse pas les autres keybinds.",
    ["Fix: comparing SecureNumber spellId in slot iteration tainted the addon ('attempt to compare a secret number value'). Wrapped in ToPublic + pcall — fully restricted auras are skipped safely instead of crashing the whole frame."] =
        "Correctif : comparer un spellId SecureNumber dans l'itération des slots contaminait l'addon ('attempt to compare a secret number value'). Enveloppé dans ToPublic + pcall — les auras totalement restreintes sont skipées en sécurité au lieu de planter tout le frame.",
    ["Fix: ApplyRingVisibility nil call when a ring test entry expired (forward declaration bug, latent since 1.3.0)."] =
        "Correctif : appel nil à ApplyRingVisibility lors de l'expiration d'une entrée test du ring (bug de forward declaration, latent depuis 1.3.0).",

    -- ===== Release notes 1.6.0 =====
    ["Macro trigger system: every aura, pulse, and item editor has a new 'Trigger key' field. Fire any configured display from a macro with /hht trigger <key> or from another addon via HNZHealingTools.Trigger(key). Multiple entries can share a key — one keybind fires them all at once."] =
        "Système de déclencheur par macro : chaque éditeur d'aura, de pulse et d'item dispose d'un nouveau champ 'Trigger key'. Déclenche n'importe quel affichage configuré depuis une macro avec /hht trigger <key> ou depuis un autre addon via HNZHealingTools.Trigger(key). Plusieurs entrées peuvent partager une clé — un seul keybind les déclenche toutes.",
    ["New Macros help page in the config sidebar with copy-pasteable macro examples and Lua snippets."] =
        "Nouvelle page d'aide Macros dans la barre latérale de la config avec des exemples de macros et des snippets Lua copiables.",
    ["Floating preview popup: 'Show preview' button at the top of pages with a Live Preview block (Cursor / Ring / Pulse settings + Cursor Ring sub-tabs). Opens to the right of the config window, single-active across pages, inherits position when switching."] =
        "Popup de prévisualisation flottant : bouton 'Afficher la prévisualisation' en haut des pages qui contenaient un bloc Live Preview (paramètres Cursor / Ring / Pulse + sous-onglets Cursor Ring). S'ouvre à droite de la fenêtre de config, un seul actif entre les pages, hérite de la position au changement.",
    ["Stack count now displays correctly for fully-restricted auras tracked by Blizzard's Cooldown Manager (e.g. Mana Tea). The addon now reads the stack count via the same SetText/GetText technique Blizzard's own CDM viewer uses, so SecureNumber values are no longer lost in combat."] =
        "Le nombre de stacks s'affiche désormais correctement pour les auras totalement restreintes suivies par le Cooldown Manager de Blizzard (par ex. Thé de mana). L'addon lit le nombre de stacks via la même technique SetText/GetText qu'utilise la vue CDM de Blizzard, donc les valeurs SecureNumber ne sont plus perdues en combat.",
    ["Restricted auras visible in the Cooldown Manager but invisible to addon APIs now synthesize ACTIVE state from the CDM hook (stacks + appliedAt) — icon + count + optional timer render correctly even when all 6 detection paths fail."] =
        "Les auras restreintes visibles dans le Cooldown Manager mais invisibles aux API addon synthétisent désormais l'état ACTIVE depuis le hook CDM (stacks + appliedAt) — icône + compteur + timer optionnel s'affichent correctement même quand les 6 chemins de détection échouent.",
    ["/hht auradebug now reports inCombat status, CDM-captured stack count, and the full list of FontStrings on the matching CDM frame — useful for diagnosing in-combat detection failures."] =
        "/hht auradebug rapporte désormais l'état de combat (inCombat), le nombre de stacks capturé par CDM, et la liste complète des FontStrings du frame CDM correspondant — utile pour diagnostiquer les échecs de détection en combat.",
    ["Public API namespace _G.HNZHealingTools exposed for macros and other addons (.version, .Trigger(key))."] =
        "Espace de noms d'API publique _G.HNZHealingTools exposé pour les macros et autres addons (.version, .Trigger(key)).",

    -- ===== Macros page + trigger UI =====
    ["Macros"] = "Macros",
    ["Trigger key:"] = "Clé de déclenchement :",
    ["Show preview"] = "Afficher la prévisualisation",
    ["Optional. Fire this aura from a macro: /hht trigger <key>. Requires Duration > 0. Case-insensitive."] =
        "Optionnel. Déclencher cette aura depuis une macro : /hht trigger <key>. Requiert Duration > 0. Insensible à la casse.",
    ["Optional. Fire this pulse from a macro: /hht trigger <key>. Case-insensitive."] =
        "Optionnel. Déclencher ce pulse depuis une macro : /hht trigger <key>. Insensible à la casse.",
    ["Optional. Fire this item from a macro: /hht trigger <key>. Case-insensitive."] =
        "Optionnel. Déclencher cet item depuis une macro : /hht trigger <key>. Insensible à la casse.",
    ["Usage: /hht trigger <key>"] = "Utilisation : /hht trigger <key>",
    ["Triggered %d entrie(s) for key '%s'"] = "%d entrée(s) déclenchée(s) pour la clé '%s'",
    ["No entries match triggerKey '%s'"] = "Aucune entrée ne correspond à triggerKey '%s'",
    ["Trigger displays from macros"] = "Déclencher des affichages depuis des macros",
    ["You can fire any aura or pulse from a macro, keybind, or another addon — without needing the actual aura/cooldown to trigger. Useful for one-shot visual signals (panic ring, cooldown reminder, callout from a partner addon)."] =
        "Tu peux déclencher n'importe quelle aura ou pulse depuis une macro, un keybind ou un autre addon — sans que l'aura/cooldown réelle ne s'active. Utile pour des signaux visuels ponctuels (ring de panique, rappel de cooldown, callout d'un addon partenaire).",
    ["1. Where you can set a Trigger key"] = "1. Où définir une clé de déclenchement",
    ["Open the editor of any of these and fill in the \"Trigger key\" field:"] =
        "Ouvre l'éditeur de l'un de ces éléments et remplis le champ \"Clé de déclenchement\" :",
    ["  • Cursor Aura — fires the aura's icon at cursor for its Duration."] =
        "  • Cursor Aura — déclenche l'icône de l'aura près du curseur pendant sa Duration.",
    ["  • Ring Aura — fires the colored ring around your character for its Duration."] =
        "  • Ring Aura — déclenche l'anneau coloré autour de ton personnage pendant sa Duration.",
    ["  • Cursor Item — fires the central pulse with the item's icon + optional sound."] =
        "  • Cursor Item — déclenche le pulse central avec l'icône de l'item + son optionnel.",
    ["  • Pulse Spell / Pulse Aura / Pulse Item — fires the central screen pulse + optional sound."] =
        "  • Pulse Spell / Pulse Aura / Pulse Item — déclenche le pulse central de l'écran + son optionnel.",
    ["2. Fire it"] = "2. Déclenche-le",
    ["From a chat message or macro line:"] = "Depuis un message de chat ou une ligne de macro :",
    ["From Lua (other addons, /run, WeakAuras custom code):"] =
        "Depuis Lua (autres addons, /run, code custom WeakAuras) :",
    ["Example: cast + trigger together"] = "Exemple : cast + déclencheur ensemble",
    ["Combine a real cast with a visual trigger in one macro:"] =
        "Combine un cast réel avec un déclencheur visuel dans une seule macro :",
    ["Tips"] = "Astuces",
    ["  • Multiple entries can share the same trigger key — they all fire at once (e.g. one key can show a Ring Aura + play a Pulse simultaneously)."] =
        "  • Plusieurs entrées peuvent partager la même clé de déclenchement — elles se déclenchent toutes en même temps (par ex. une clé peut afficher une Ring Aura + jouer un Pulse simultanément).",
    ["  • Trigger keys are case-insensitive. \"Panic\" and \"panic\" match the same entries."] =
        "  • Les clés de déclenchement sont insensibles à la casse. \"Panic\" et \"panic\" correspondent aux mêmes entrées.",
    ["  • Aura entries (Cursor / Ring) require Duration > 0 — without a duration there's no way to know when the visual should disappear."] =
        "  • Les entrées d'aura (Cursor / Ring) requièrent Duration > 0 — sans durée, impossible de savoir quand le visuel doit disparaître.",
    ["  • Pulse entries fire immediately and the animation has its own length (configured globally in Pulse → Config)."] =
        "  • Les entrées de pulse se déclenchent immédiatement et l'animation a sa propre durée (configurée globalement dans Pulse → Config).",
    ["  • HNZHealingTools.Trigger(key) returns the number of entries that matched (0 = no entries have that key)."] =
        "  • HNZHealingTools.Trigger(key) renvoie le nombre d'entrées correspondantes (0 = aucune entrée n'a cette clé).",
    ["  • Combat-safe: trigger keys work during combat lockdown."] =
        "  • Combat-safe : les clés de déclenchement fonctionnent pendant le combat lockdown.",
})
