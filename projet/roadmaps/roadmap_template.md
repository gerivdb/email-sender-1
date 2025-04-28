# Template de Roadmap - Standard de Documentation

Ce document sert de référence pour la création et la maintenance de la roadmap du projet. Il définit la structure, le format et les conventions à suivre pour assurer une documentation cohérente, complète et facilement parsable par les outils automatisés.

## Structure hiérarchique standard

```markdown
# Roadmap [NOM_PROJET]

## 1. [SECTION_PRINCIPALE]
**Description**: [Description concise de la section]
**Responsable**: [Équipe ou personne responsable]
**Statut global**: [Statut] - [Pourcentage]

### 1.1 [SOUS-SECTION]
**Complexité**: [Faible/Moyenne/Élevée]
**Temps estimé total**: [X jours]
**Progression globale**: [Pourcentage]
**Dépendances**: [Liste des dépendances]

#### Outils et technologies
- **Langages**: [Liste des langages de programmation]
- **Frameworks**: [Liste des frameworks]
- **Outils IA**: [Liste des outils d'IA]
- **Outils d'analyse**: [Liste des outils d'analyse]
- **Environnement**: [Description de l'environnement]

#### Fichiers principaux
| Chemin | Description |
|--------|-------------|
| `[chemin/vers/fichier]` | [Description du fichier] |
| `[chemin/vers/fichier]` | [Description du fichier] |

#### Guidelines
- **Codage**: [Conventions de codage]
- **Tests**: [Approche de test]
- **Documentation**: [Standards de documentation]
- **Sécurité**: [Pratiques de sécurité]
- **Performance**: [Considérations de performance]

#### 1.1.1 [TÂCHE]
**Complexité**: [Faible/Moyenne/Élevée]
**Temps estimé**: [X jours]
**Progression**: [Pourcentage] - *[Statut]*
**Date de début prévue**: [JJ/MM/AAAA]
**Date d'achèvement prévue**: [JJ/MM/AAAA]
**Responsable**: [Personne responsable]
**Tags**: #[tag1] #[tag2] #[tag3]

##### Fichiers à créer/modifier
| Chemin | Description | Statut |
|--------|-------------|--------|
| `[chemin/vers/fichier]` | [Description] | [À créer/À modifier/Terminé] |
| `[chemin/vers/fichier]` | [Description] | [À créer/À modifier/Terminé] |

##### Format de journalisation
```json
{
  "module": "[Nom du module]",
  "version": "[Version]",
  "date": "[AAAA-MM-JJ]",
  "changes": [
    {"feature": "[Fonctionnalité]", "status": "[Statut]"},
    {"feature": "[Fonctionnalité]", "status": "[Statut]"}
  ],
  "performance": {
    "[scénario1]": {"time_ms": [temps], "memory_mb": [mémoire]},
    "[scénario2]": {"time_ms": [temps], "memory_mb": [mémoire]}
  }
}
```

##### [Jour X] - [Description de la journée] (Xh)
- [ ] **Sous-tâche X.1**: [Nom de la sous-tâche] (Xh)
  - **Description**: [Description détaillée]
  - **Livrable**: [Description du livrable]
  - **Fichier**: `[chemin/vers/fichier]`
  - **Outils**: [Outils utilisés]
  - **Statut**: [Non commencé/En cours/Terminé]
  - **Exemple de code**:
  ```[langage]
  [Exemple de code]
  ```
```

## Conventions de nommage et formatage

### Niveaux hiérarchiques
1. **Niveau 1 (#)**: Titre du projet
2. **Niveau 2 (##)**: Sections principales (numérotées: 1., 2., etc.)
3. **Niveau 3 (###)**: Sous-sections (numérotées: 1.1, 1.2, etc.)
4. **Niveau 4 (####)**: Tâches (numérotées: 1.1.1, 1.1.2, etc.)
5. **Niveau 5 (#####)**: Journées ou catégories de sous-tâches
6. **Niveau 6 (######)**: Groupes de sous-tâches

### Statuts standardisés
- **Non commencé**: Tâche planifiée mais non démarrée
- **En cours**: Tâche démarrée mais non terminée
- **En attente**: Tâche bloquée par une dépendance
- **Presque terminé**: Tâche complétée à plus de 90%
- **Terminé**: Tâche complétée et validée
- **Annulé**: Tâche abandonnée ou reportée

### Complexité
- **Faible**: Tâche simple, peu de risques, technologie maîtrisée
- **Moyenne**: Tâche modérément complexe, quelques risques, technologie partiellement maîtrisée
- **Élevée**: Tâche complexe, risques importants, nouvelle technologie ou approche

### Format des sous-tâches
- Utiliser des cases à cocher pour indiquer l'état d'avancement: `- [ ]` ou `- [x]`
- Inclure l'estimation de temps entre parenthèses: (2h)
- Numéroter les sous-tâches pour faciliter la référence: X.1, X.2, etc.

### Chemins de fichiers
- Toujours utiliser des chemins complets relatifs à la racine du projet
- Utiliser des backticks pour encadrer les chemins: `chemin/vers/fichier`
- Utiliser des barres obliques (/) comme séparateurs de chemin (pas de backslashes)

## Format JSON pour parsing automatique

Chaque section de la roadmap doit être accompagnée d'une représentation JSON équivalente pour faciliter le parsing automatique. Exemple:

```json
{
  "project": "NOM_PROJET",
  "sections": [
    {
      "id": "1",
      "name": "SECTION_PRINCIPALE",
      "description": "Description concise de la section",
      "responsible": "Équipe ou personne responsable",
      "status": "En cours",
      "progress": 60,
      "subsections": [
        {
          "id": "1.1",
          "name": "SOUS-SECTION",
          "complexity": "Moyenne",
          "estimated_days": 11,
          "progress": 70,
          "dependencies": [],
          "tools": {
            "languages": ["PowerShell 5.1/7", "Python 3.11+"],
            "frameworks": ["Pester", "pytest"],
            "ai_tools": ["MCP", "Augment"],
            "analysis_tools": ["PSScriptAnalyzer", "pylint"],
            "environment": "VS Code avec extensions PowerShell et Python"
          },
          "files": [
            {"path": "modules/CycleDetector.psm1", "description": "Module principal de détection de cycles"},
            {"path": "tests/unit/CycleDetector.Tests.ps1", "description": "Tests unitaires du module"}
          ],
          "guidelines": {
            "coding": "Suivre les conventions PowerShell (PascalCase pour fonctions, verbes approuvés)",
            "testing": "Appliquer TDD avec Pester, viser 100% de couverture",
            "documentation": "Utiliser le format d'aide PowerShell et XML pour la documentation",
            "security": "Valider tous les inputs, éviter l'utilisation d'Invoke-Expression",
            "performance": "Optimiser pour les grands graphes, utiliser la mise en cache"
          },
          "tasks": [
            {
              "id": "1.1.1",
              "name": "Implémentation de l'algorithme de détection de cycles",
              "complexity": "Moyenne",
              "estimated_days": 3,
              "progress": 90,
              "status": "Presque terminé",
              "start_date": "2025-06-01",
              "end_date": "2025-06-03",
              "responsible": "Équipe IA",
              "tags": ["algorithme", "graphe", "optimisation"],
              "files_to_create": [
                {"path": "modules/CycleDetector.psm1", "description": "Module principal", "status": "À créer"},
                {"path": "tests/unit/CycleDetector.Tests.ps1", "description": "Tests unitaires", "status": "À créer"}
              ],
              "subtasks": [
                {
                  "id": "1.1",
                  "name": "Recherche bibliographique sur les algorithmes de détection de cycles",
                  "description": "Étudier les algorithmes DFS, BFS, et algorithme de Tarjan",
                  "estimated_hours": 1,
                  "deliverable": "Document de synthèse des algorithmes étudiés",
                  "file": "docs/technical/AlgorithmesDetectionCycles.md",
                  "tools": ["MCP", "Augment"],
                  "status": "Terminé",
                  "code_example": "function Find-CycleWithDFS {...}"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## Bonnes pratiques pour la maintenance de la roadmap

1. **Mise à jour régulière**: Mettre à jour la roadmap au moins une fois par semaine
2. **Archivage des tâches terminées**: Déplacer les tâches terminées vers un fichier d'archive
3. **Versionnement**: Utiliser le versionnement sémantique pour la roadmap (MAJOR.MINOR.PATCH)
4. **Validation**: Valider le format Markdown et JSON avant chaque commit
5. **Automatisation**: Utiliser des scripts pour générer des rapports d'avancement
6. **Traçabilité**: Lier les tâches aux commits Git correspondants
7. **Revue**: Organiser des revues régulières de la roadmap avec l'équipe

## Exemple d'utilisation du template

```markdown
# Roadmap EMAIL_SENDER_1

## 1. Intelligence
**Description**: Modules et fonctionnalités d'intelligence artificielle et d'optimisation algorithmique.
**Responsable**: Équipe IA
**Statut global**: En cours - 60%

### 1.1 Détection de cycles
**Complexité**: Moyenne
**Temps estimé total**: 11 jours
**Progression globale**: 70%
**Dépendances**: Aucune

#### Outils et technologies
- **Langages**: PowerShell 5.1/7, Python 3.11+
- **Frameworks**: Pester (tests PowerShell), pytest (tests Python)
- **Outils IA**: MCP pour l'automatisation, Augment pour l'assistance au développement
- **Outils d'analyse**: PSScriptAnalyzer, pylint
- **Environnement**: VS Code avec extensions PowerShell et Python

#### Fichiers principaux
| Chemin | Description |
|--------|-------------|
| `modules/CycleDetector.psm1` | Module principal de détection de cycles |
| `tests/unit/CycleDetector.Tests.ps1` | Tests unitaires du module |
| `docs/technical/CycleDetectorAPI.md` | Documentation de l'API |

#### Guidelines
- **Codage**: Suivre les conventions PowerShell (PascalCase pour fonctions, verbes approuvés)
- **Tests**: Appliquer TDD avec Pester, viser 100% de couverture
- **Documentation**: Utiliser le format d'aide PowerShell et XML pour la documentation
- **Sécurité**: Valider tous les inputs, éviter l'utilisation d'Invoke-Expression
- **Performance**: Optimiser pour les grands graphes, utiliser la mise en cache

#### 1.1.1 Implémentation de l'algorithme de détection de cycles
**Complexité**: Moyenne
**Temps estimé**: 3 jours
**Progression**: 90% - *Presque terminé*
**Date de début prévue**: 01/06/2025
**Date d'achèvement prévue**: 03/06/2025
**Responsable**: Équipe IA
**Tags**: #algorithme #graphe #optimisation

##### Fichiers à créer/modifier
| Chemin | Description | Statut |
|--------|-------------|--------|
| `modules/CycleDetector.psm1` | Module principal | À créer |
| `tests/unit/CycleDetector.Tests.ps1` | Tests unitaires | À créer |

##### Format de journalisation
```json
{
  "module": "CycleDetector",
  "version": "1.0.0",
  "date": "2025-06-03",
  "changes": [
    {"feature": "Implémentation DFS", "status": "Complété"},
    {"feature": "Détection de cycles", "status": "Complété"}
  ]
}
```

##### Jour 1 - Analyse et conception (8h)
- [x] **Sous-tâche 1.1**: Recherche bibliographique sur les algorithmes de détection de cycles (1h)
  - **Description**: Étudier les algorithmes DFS, BFS, et algorithme de Tarjan
  - **Livrable**: Document de synthèse des algorithmes étudiés
  - **Fichier**: `docs/technical/AlgorithmesDetectionCycles.md`
  - **Outils**: MCP pour la recherche, Augment pour la synthèse
  - **Statut**: Terminé
```

## Scripts d'automatisation

Des scripts d'automatisation sont disponibles pour faciliter la gestion de la roadmap:

1. **`Update-RoadmapProgress.ps1`**: Met à jour automatiquement les pourcentages de progression
2. **`Export-RoadmapToJSON.ps1`**: Exporte la roadmap au format JSON
3. **`New-RoadmapTask.ps1`**: Crée une nouvelle tâche selon le template
4. **`Archive-CompletedTasks.ps1`**: Archive les tâches terminées

Ces scripts sont disponibles dans le répertoire `scripts/roadmap/`.

---

Ce template est maintenu par l'équipe DevOps. Pour toute question ou suggestion d'amélioration, veuillez contacter [email@example.com].

Dernière mise à jour: 2025-04-20
