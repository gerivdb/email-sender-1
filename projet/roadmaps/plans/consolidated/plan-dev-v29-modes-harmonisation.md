---
to: "plan-dev/plan-dev-v29-modes-harmonisation.md"
---
# Plan Dev: Modes Harmonisation (v29)

Date de création : 2025-05-21
Auteur : À compléter

## Introduction globale

Ce document présente l’ensemble des modes opérationnels harmonisés pour la gestion des workflows roadmap. Chaque mode est autonome, modulaire et conçu pour être combiné avec les autres selon les besoins du projet. La logique modulaire permet d’assembler les modes dans des séquences adaptées (ex : GRAN → DEV-R → TEST → DEBUG → REVIEW → OPTI → CHECK), tout en évitant toute redondance fonctionnelle.

### Liste des modes harmonisés
- ARCHI (Architecture)
- GRAN (Granularisation)
- DEV-R (Développement Roadmap)
- TEST (Tests automatisés)
- DEBUG (Débogage)
- CHECK (Vérification d’avancement)
- REVIEW (Revue qualité)
- OPTI (Optimisation)
- PREDIC (Prédiction/Analyse)
- C-BREAK (Résolution de cycles/dépendances)

Chaque fiche mode détaille : objectifs, commandes principales, fonctionnement, bonnes pratiques, intégration avec les autres modes, exemples d’utilisation et snippet VS Code. Les points d’entrée/sortie sont explicités pour faciliter la combinaison et l’automatisation.

## Objectif

Harmoniser, modulariser et rendre cohérents tous les modes opérationnels décrits dans `development/methodologies/modes`, afin de constituer une base unifiée, sans redondance, directement exploitable pour la génération de snippets et l'automatisation des workflows roadmap.

## Étapes principales

- [x] Recenser tous les fichiers de mode existants dans `development/methodologies/modes`
  - Fichiers trouvés :
    - index.md
    - mode_archi.md
    - mode_c-break.md
    - mode_check_enhanced.md
    - mode_c_break.md
    - mode_debug.md
    - mode_dev_r.md
    - mode_gran.md
    - mode_opti.md
    - mode_predic.md
    - mode_review.md
    - mode_test.md
- [x] Identifier et supprimer les doublons (ex : C-BREAK)
  - Doublons détectés :
    - mode_c-break.md / mode_c_break.md (variante de nommage pour C-BREAK)
  - Action recommandée : fusionner le contenu et ne conserver qu'un seul fichier pour le mode C-BREAK.
- [x] Définir une structure unifiée pour chaque mode
  - Structure proposée (voir section dédiée ci-dessous) :
    - Titre, Description, Objectifs, Commandes principales, Fonctionnement, Bonnes pratiques, Intégration avec les autres modes, Exemples d’utilisation, Snippet VS Code (optionnel)
  - Cette structure est détaillée dans la section « Structure unifiée pour chaque mode » du plan.
- [x] Réécrire chaque fichier de mode selon cette structure
  - Chaque fichier de mode sera restructuré selon la structure unifiée définie ci-dessus (Titre, Description, Objectifs, Commandes principales, Fonctionnement, Bonnes pratiques, Intégration, Exemples, Snippet VS Code).
  - Priorité : traiter d'abord les modes principaux (ARCHI, GRAN, DEV-R, TEST, DEBUG, CHECK, REVIEW, OPTI, PREDIC, C-BREAK).
  - Les doublons (ex : C-BREAK) seront fusionnés lors de la réécriture.
- [x] Vérifier la cohérence globale (pas de redondance, pas d’incohérence)
  - Chaque mode a été restructuré selon la structure unifiée, les doublons ont été fusionnés.
  - Vérification effectuée : pas de redondance fonctionnelle, chaque mode est autonome et les interactions sont référencées.
  - Les points d’entrée/sortie et les combinaisons typiques sont explicités dans chaque fiche mode.
- [x] Ajouter une introduction globale listant tous les modes et expliquant la logique modulaire/combinatoire
  - Introduction ajoutée en tête de document :

## Structure unifiée pour chaque mode

```markdown
# Mode <NOM>

## Description
Résumé du mode, son objectif principal et son rôle dans le workflow.

## Objectifs
- Liste des objectifs spécifiques du mode.

## Commandes principales
- <COMMANDE> : Description courte
- ...

## Fonctionnement
- Étapes clés du mode (séquentiel, déclencheurs, automatisations, etc.)

## Bonnes pratiques
- Conseils d’utilisation, pièges à éviter, standards à respecter.

## Intégration avec les autres modes
- Comment ce mode s’articule avec les autres (ex : TEST s’active après DEV-R, DEBUG après TEST, etc.)
- Exemples de combinaisons typiques.

## Exemples d’utilisation
```powershell
# Exemple d’appel du mode en CLI ou via snippet
Invoke-AugmentMode -Mode "<NOM>" -FilePath "<roadmap>" -TaskIdentifier "<id>"
```

## Snippet VS Code (optionnel)
```json
{
  "Mode <NOM>": {
    "prefix": "<prefix>",
    "body": [
      // contenu du snippet
    ],
    "description": "Insère le template du mode <NOM>."
  }
}
```
```

## Modes à harmoniser (liste indicative)

- ARCHI (Architecture)
- GRAN (Granularisation)
- DEV-R (Développement Roadmap)
- TEST (Tests automatisés)
- DEBUG (Débogage)
- CHECK (Vérification d’avancement)
- REVIEW (Revue qualité)
- OPTI (Optimisation)
- PREDIC (Prédiction/Analyse)
- C-BREAK (Résolution de cycles/dépendances)
- (Optionnel : GIT, UI, DB, SECURE, META...)

## Principes d’intégration et de combinaison

- Chaque mode est autonome mais expose clairement ses points d’entrée/sortie pour être combiné avec d’autres.
- Pas de redondance : chaque fonctionnalité n’est décrite que dans un seul mode, les interactions sont référencées.
- Workflows recommandés (exemples) :
  - GRAN → DEV-R → TEST → DEBUG → REVIEW → OPTI → CHECK
  - ARCHI → C-BREAK → DEV-R → TEST → DEBUG → REVIEW
- Exemples de combinaisons sont donnés dans chaque fiche mode.
- Préparation à la génération de snippets : chaque fiche peut être copiée telle quelle dans un fichier de snippets VS Code.

## Détails

- Utiliser la structure imbriquée ci-dessus pour détailler chaque niveau, jusqu’à 10 niveaux si nécessaire.
- S’assurer que l’ensemble couvre tous les besoins de développement, debug, test, review, optimisation, etc.

# Étapes suivantes pour l’harmonisation des modes (v29)

- [ ] Mettre à jour la documentation associée à chaque mode harmonisé
  - [ ] Vérifier que chaque fiche mode est bien référencée dans la documentation globale.
    - [x] mode_archi.md
    - [x] mode_gran.md
    - [x] mode_dev_r.md
    - [x] mode_test.md
    - [x] mode_debug.md
{
  "Mode CHECK Amélioré": {
    "prefix": "mode-check-ameliore",
    "body": [
      "# Mode CHECK Amélioré",
      "",
      "## Description",
      "Le mode CHECK amélioré vérifie l’implémentation et les tests des tâches, puis met à jour les cases à cocher.",
      "",
      "## Objectifs",
      "- Vérifier l’implémentation complète des tâches.",
      "- S’assurer que les tests sont réussis à 100%.",
      "- Mettre à jour automatiquement les cases à cocher.",
      "",
      "## Commandes principales",
      "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tâche>",
      "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tâche> -Force",
      "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tâche> -ActiveDocumentPath <chemin_document>",
      "",
      "## Fonctionnement",
      "- Analyse la roadmap, vérifie l’implémentation et les tests, met à jour les cases à cocher.",
      "",
      "## Bonnes pratiques",
      "- Exécuter après chaque étape de développement/test.",
      "- Vérifier l’encodage des fichiers.",
      "- Utiliser -Force après validation.",
      "",
      "## Intégration avec les autres modes",
      "- DEV-R, GRAN, TEST, REVIEW, OPTI, C-BREAK.",
      "",
      "## Exemples d’utilisation",
      "# Vérification simple",
      ".\\development\\tools\\scripts\\check.ps1 -FilePath \"projet/documentation/roadmap/roadmap.md\" -TaskIdentifier \"1.2.3\"",
      "# Mise à jour automatique",
      ".\\development\\tools\\scripts\\check.ps1 -FilePath \"projet/documentation/roadmap/roadmap.md\" -TaskIdentifier \"1.2.3\" -Force"
    ],
    "description": "Insère le template du mode CHECK Amélioré."
  }
}
    - [x] mode_check_enhanced.md
    - [ ] mode_review.md
    - [ ] mode_opti.md
    - [ ] mode_predic.md
    - [x] mode_c-break.md
    - [ ] index.md
  - [x] Ajouter des liens croisés entre modes pour faciliter la navigation.
- [x] Générer automatiquement les snippets VS Code à partir des fiches modes
  - [x] Extraire la section « Snippet VS Code » de chaque fiche mode.
  - [x] Générer un fichier de snippets global.
- [x] Mettre en place des tests d’intégrité pour les modes
  - [x] Vérifier la présence de toutes les sections obligatoires dans chaque fiche mode.
  - [x] Détecter les incohérences ou oublis (ex : absence d’exemple, de bonnes pratiques, etc.).
- [x] Intégrer les modes harmonisés dans les workflows d’automatisation
  - [x] Adapter les scripts ou outils existants pour exploiter la nouvelle structure des modes (extraction automatique des snippets opérationnelle via `misc/extract_vscode_snippets.py`).
  - [x] Documenter les points d’intégration (ex : génération de roadmap, automatisation de tâches, extraction de snippets utilisable dans CI/CD ou autres outils).
- [x] Organiser une revue collective pour valider l’harmonisation
  - [x] Faire relire les fiches modes par plusieurs membres de l’équipe (DEV-R, ARCHI, GRAN, TEST, DEBUG, CHECK, REVIEW, OPTI, PREDIC, C-BREAK).
  - [x] Recueillir les retours et ajuster si besoin.
- [ ] Planifier la maintenance et l’évolution des modes
  - [ ] Définir un processus de mise à jour (ajout, modification, suppression de modes).
  - [ ] Mettre en place un suivi des évolutions (changelog, versionning, etc.).

---

> Généré avec Hygen (plan-dev template)



