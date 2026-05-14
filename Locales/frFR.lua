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
})
