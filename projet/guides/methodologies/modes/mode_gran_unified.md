# Mode GRAN Unifié

## Description

Le mode GRAN (Granularisation) est un mode opérationnel qui décompose les tâches complexes en sous-tâches plus petites et plus faciles à gérer. Cette version unifiée intègre le support pour la granularité adaptative, optimisée pour les besoins d'Augment.

## Objectif

L'objectif principal du mode GRAN est de faciliter la gestion de tâches complexes en les décomposant en unités de travail plus petites, plus précises et plus faciles à estimer. La granularisation adaptative permet d'ajuster automatiquement le niveau de détail en fonction de la complexité de la tâche et du domaine technique.

## Fonctionnalités

- Décomposition des tâches complexes en sous-tâches
- Adaptation du niveau de granularité en fonction de la complexité
- Détection automatique de la complexité des tâches
- Support pour la granularité adaptative basée sur la configuration
- Granularisation récursive avec contrôle de la profondeur
- Intégration avec le système RAG pour une indexation optimale
- Compatibilité avec les modes de développement existants

## Utilisation

### Mode GRAN standard

```powershell
# Granulariser une tâche avec détection automatique de la complexité

.\development\scripts\maintenance\modes\gran-mode-unified.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3"

# Granulariser une tâche avec granularité adaptative

.\development\scripts\maintenance\modes\gran-mode-unified.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AdaptiveGranularity

# Granulariser une tâche avec un niveau de complexité spécifique

.\development\scripts\maintenance\modes\gran-mode-unified.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -ComplexityLevel "Complex"

# Granulariser une tâche avec un domaine spécifique

.\development\scripts\maintenance\modes\gran-mode-unified.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -Domain "Backend"

# Utiliser le mode-manager

.\development\scripts\mode-manager\mode-manager.ps1 -Mode GRAN -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AdaptiveGranularity
```plaintext
### Mode GRAN récursif

```powershell
# Granulariser récursivement une tâche avec granularité adaptative

.\development\scripts\maintenance\modes\gran-mode-recursive-unified.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AdaptiveGranularity

# Granulariser récursivement avec une profondeur spécifique

.\development\scripts\maintenance\modes\gran-mode-recursive-unified.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -RecursionDepth 3 -AdaptiveGranularity

# Granulariser récursivement avec analyse de complexité pour chaque sous-tâche

.\development\scripts\maintenance\modes\gran-mode-recursive-unified.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AnalyzeComplexity -AdaptiveGranularity

# Utiliser le mode-manager

.\development\scripts\mode-manager\mode-manager.ps1 -Mode GRAN-R -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AdaptiveGranularity
```plaintext
## Granularité adaptative

Le mode GRAN unifié intègre un système de granularité adaptative qui ajuste automatiquement le niveau de détail en fonction de la complexité de la tâche et du domaine technique. Ce système est basé sur les recommandations définies dans le fichier de configuration `development\config\granularite-adaptative.json`.

### Niveaux de granularité recommandés

La structure hiérarchique optimale pour les roadmaps comprend 4 à 6 niveaux de profondeur:

1. **Niveau 1**: Sections principales (grands domaines fonctionnels)
2. **Niveau 2**: Composants majeurs (sous-systèmes ou composants principaux)
3. **Niveau 3**: Fonctionnalités spécifiques (fonctionnalités ou capacités distinctes)
4. **Niveau 4**: Tâches d'implémentation concrètes (tâches techniques spécifiques)
5. **Niveau 5**: Sous-tâches techniques détaillées (pour les tâches complexes)
6. **Niveau 6**: Détails d'implémentation très spécifiques (à utiliser avec parcimonie)

### Adaptation selon la complexité

La profondeur de granularité est adaptée à la complexité de la tâche:

| Complexité | Profondeur recommandée | Exemple de domaine |
|------------|------------------------|-------------------|
| Simple     | 3-4 niveaux            | Documentation, configuration simple |
| Moyenne    | 4-5 niveaux            | Développement frontend, scripts simples |
| Élevée     | 5-6 niveaux            | Algorithmes complexes, intégration système |
| Très élevée| 6+ niveaux             | Systèmes distribués, optimisation avancée |

## Optimisation pour le RAG

La structure hiérarchique recommandée est optimisée pour le système RAG (Retrieval-Augmented Generation):

1. **Indexation sémantique efficace**: La structure à 4-6 niveaux permet une indexation sémantique optimale.
2. **Recherche contextuelle**: Les niveaux hiérarchiques fournissent un contexte riche pour les recherches.
3. **Génération de vues**: La structure facilite la génération de vues adaptées à différents besoins.
4. **Traçabilité**: La numérotation hiérarchique permet une référence unique à chaque tâche.

## Paramètres

### Paramètres communs

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|------------------|
| FilePath | Chemin vers le fichier de roadmap | (obligatoire) |
| TaskIdentifier | Identifiant de la tâche à granulariser | (obligatoire) |
| ComplexityLevel | Niveau de complexité (Auto, Simple, Medium, Complex, VeryComplex) | Auto |
| Domain | Domaine technique (Frontend, Backend, Database, etc.) | None |
| SubTasksFile | Fichier de sous-tâches personnalisées | "" |
| AddTimeEstimation | Ajouter des estimations de temps aux sous-tâches | $false |
| UseAI | Utiliser l'IA pour générer des sous-tâches | $false |
| SimulateAI | Simuler l'utilisation de l'IA (pour les tests) | $false |
| IndentationStyle | Style d'indentation (Spaces2, Spaces4, Tab, Auto) | Auto |
| CheckboxStyle | Style de case à cocher (GitHub, Custom, Auto) | Auto |
| AdaptiveGranularity | Utiliser la granularité adaptative basée sur la configuration | $true |

### Paramètres spécifiques au mode GRAN récursif

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|------------------|
| RecursionDepth | Profondeur maximale de récursion | 2 |
| AnalyzeComplexity | Analyser la complexité de chaque sous-tâche | $false |

## Exemples de granularisation adaptative

### Exemple 1: Tâche simple (3-4 niveaux)

```markdown
- [ ] **1.1** Configurer l'environnement de développement
  - [ ] **1.1.1** Installer les dépendances requises
  - [ ] **1.1.2** Configurer les variables d'environnement
  - [ ] **1.1.3** Vérifier l'installation
```plaintext
### Exemple 2: Tâche complexe (5-6 niveaux)

```markdown
- [ ] **3.1** Implémenter le système de recherche vectorielle
  - [ ] **3.1.1** Concevoir l'architecture du système
    - [ ] **3.1.1.1** Définir les composants principaux
    - [ ] **3.1.1.2** Établir les interfaces entre composants
    - [ ] **3.1.1.3** Concevoir le modèle de données
  - [ ] **3.1.2** Développer le moteur d'indexation
    - [ ] **3.1.2.1** Implémenter l'extraction de caractéristiques
      - [ ] **3.1.2.1.1** Développer le prétraitement des textes
      - [ ] **3.1.2.1.2** Implémenter la vectorisation des documents
      - [ ] **3.1.2.1.3** Créer le système de mise à jour incrémentale
    - [ ] **3.1.2.2** Développer le stockage des vecteurs
      - [ ] **3.1.2.2.1** Implémenter la structure de données optimisée
      - [ ] **3.1.2.2.2** Créer les mécanismes de persistance
```plaintext
## Bonnes pratiques

- Utiliser la granularité adaptative pour maintenir une structure cohérente
- Limiter la profondeur de récursion à 2-3 niveaux pour éviter une granularisation excessive
- Analyser la complexité des sous-tâches pour une granularisation plus précise
- Adapter la granularité en fonction du domaine technique
- Vérifier le résultat après la granularisation et ajuster manuellement si nécessaire

## Intégration avec d'autres modes

Le mode GRAN unifié peut être utilisé en combinaison avec d'autres modes :
- **DEV-R** : Pour implémenter les tâches granularisées
- **ARCHI** : Pour concevoir l'architecture des composants granularisés
- **CHECK** : Pour vérifier l'état d'avancement des sous-tâches
- **REVIEW** : Pour réviser la qualité des tâches granularisées

## Implémentation

Le mode GRAN unifié est implémenté dans les scripts suivants :
- `development\scripts\maintenance\modes\gran-mode-unified.ps1` : Version standard
- `development\scripts\maintenance\modes\gran-mode-recursive-unified.ps1` : Version récursive
- `development\config\granularite-adaptative.json` : Configuration de la granularité adaptative
- `projet\guides\methodologies\granularite-adaptative.md` : Guide détaillé sur la granularité adaptative
