# Mode CHECK Amélioré

## Description

Le mode CHECK amélioré est une version avancée du mode CHECK qui vérifie si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100%, puis met à jour automatiquement les cases à cocher dans le document actif.

## Objectifs
- Vérifier l’implémentation complète des tâches sélectionnées.
- S’assurer que les tests associés sont réussis à 100%.
- Mettre à jour automatiquement les cases à cocher dans les roadmaps et documents actifs.
- Préserver l’encodage, l’indentation et le texte des tâches.

## Commandes principales
- `check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tâche>` : Vérification simple (mode simulation)
- `check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tâche> -Force` : Mise à jour automatique des cases à cocher
- `check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tâche> -ActiveDocumentPath <chemin_document>` : Spécification manuelle du document actif

## Fonctionnement
- Analyse la roadmap pour identifier les tâches et leur structure.
- Vérifie l’implémentation et les tests de chaque tâche.
- Détecte automatiquement le document actif (via variable d’environnement ou fichiers récemment modifiés).
- Met à jour les cases à cocher si toutes les conditions sont remplies.
- Préserve l’encodage UTF-8 avec BOM et l’indentation.

## Fonctionnalités avancées et options de configuration

- Génération de rapports de vérification (paramètre `GenerateReport`, chemin configurable via `ReportPath`).
- Mode simulation avancé avec le paramètre `WhatIf` (simule les actions sans les exécuter).
- Configuration avancée possible via le fichier `config.json` (exemple : `AutoUpdateRoadmap`, `RequireFullTestCoverage`, `SimulationModeDefault`, etc.).

Exemple de configuration :
```json
{
  "Check": {
    "DefaultRoadmapFile": "projet/roadmaps/plans/roadmap_complete_2.md",
    "DefaultActiveDocumentPath": "projet/roadmaps/plans/plan-modes-stepup.md",
    "AutoUpdateRoadmap": true,
    "GenerateReport": true,
    "ReportPath": "reports",
    "AutoUpdateCheckboxes": true,
    "RequireFullTestCoverage": true,
    "SimulationModeDefault": true
  }
}
```

### Algorithme de vérification (rappel)
- Recherche de la tâche à vérifier dans la roadmap
- Analyse de l’implémentation et des tests associés
- Mise à jour automatique si tout est validé
- Génération d’un rapport de vérification

## Bonnes pratiques
- Exécuter le mode CHECK après chaque étape de développement/test pour garantir la cohérence de la roadmap.
- Toujours vérifier l’encodage des fichiers si des caractères spéciaux sont présents.
- Utiliser le paramètre `-Force` uniquement après avoir validé les modifications en mode simulation.
- Documenter les cas particuliers ou corrections manuelles dans la roadmap.

## Intégration avec les autres modes
- **[Mode DEV-R](mode_dev_r.md)** : Vérifie automatiquement les tâches implémentées pendant le développement.
- **[Mode GRAN](mode_gran.md)** : Complémentaire pour la granularisation des tâches.
- **[Mode TEST](mode_test.md)** : Utilise les résultats de tests pour valider les tâches.
- **[Mode REVIEW](mode_review.md)** : Peut être utilisé pour valider l’avancement avant la revue qualité.
- **[Mode OPTI](mode_opti.md)** : S’assure que les optimisations sont bien validées et testées.
- **[Mode C-BREAK](mode_c-break.md)** : Vérifie que les tâches de résolution de cycles sont bien prises en compte dans la roadmap.
- **[Mode ARCHI](mode_archi.md)** : Vérifie l’architecture des composants en complément de l’implémentation et des tests.

## Exemples d’utilisation
```powershell
# Vérification simple (simulation)
.\development\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3"

# Mise à jour automatique
.\development\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force

# Spécification du document actif
.\development\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ActiveDocumentPath "projet/documentation/roadmap/roadmap.md" -Force
```

## Snippet VS Code (optionnel)
```json
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
```

## Documentation associée et approfondissements

Pour la gestion avancée de la validation, des erreurs et de la robustesse, voir :
- [Propriétés communes de System.Exception](../exception_properties_documentation.md)
- [Structure de la taxonomie des exceptions PowerShell](../exception_taxonomy_structure.md)
- [Exceptions du namespace System](../system_exceptions_documentation.md)
- [Exceptions du namespace System.IO](../system_io_exceptions_documentation.md)
- [Les 16 bases de la programmation](../programmation_16_bases.md) (document de référence supérieur)
