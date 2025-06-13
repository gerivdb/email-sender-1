# Modes opérationnels Augment

*Version 2025-05-15*

Ce guide détaille les différents modes opérationnels d'Augment, leur utilisation et les bonnes pratiques associées, basés sur l'analyse des documents de référence et des exemples pratiques.

## 1. Vue d'ensemble des modes

Les modes opérationnels Augment sont des approches structurées pour aborder différentes tâches de développement. Chaque mode a un objectif spécifique et une méthodologie associée.

| Mode | Fonction | Utilisation |
|------|----------|-------------|
| **GRAN** | Décomposition des tâches complexes | `Invoke-AugmentMode -Mode GRAN -FilePath "path/to/roadmap.md" -TaskIdentifier "1.2.3"` |
| **DEV-R** | Implémentation des tâches roadmap | Développement séquentiel des sous-tâches |
| **ARCHI** | Conception et modélisation | Diagrammes, contrats d'interface, chemins critiques |
| **DEBUG** | Résolution de bugs | Isolation et correction d'anomalies |
| **TEST** | Tests automatisés | Maximisation de la couverture de test |
| **OPTI** | Optimisation des performances | Réduction de complexité, parallélisation |
| **REVIEW** | Vérification de qualité | Standards SOLID, KISS, DRY |
| **PREDIC** | Analyse prédictive | Anticipation des performances et anomalies |
| **C-BREAK** | Résolution de dépendances circulaires | Détection et correction des cycles |

## 2. Détail des modes principaux

### 2.1 Mode GRAN (Granularisation)

**Objectif** : Décomposer une tâche complexe en sous-tâches plus petites et gérables.

**Méthodologie** :
1. Analyser la tâche principale pour comprendre son objectif et sa portée
2. Identifier les composants logiques ou les étapes nécessaires
3. Décomposer en sous-tâches avec une granularité adaptée (30-50 lignes de code par fonction)
4. Attribuer des identifiants hiérarchiques aux sous-tâches (ex: 1.2.3.1, 1.2.3.2)
5. Documenter les dépendances entre les sous-tâches

**Exemple d'utilisation** :
```powershell
Invoke-AugmentMode -Mode GRAN -FilePath "projet/roadmaps/plans/plan-dev-v14-augment-optimization.md" -TaskIdentifier "1.2.3" -UpdateMemories
```plaintext
**Bonnes pratiques** :
- Viser une granularité de 30-50 lignes de code par fonction
- Limiter la profondeur de décomposition à 2 niveaux
- S'assurer que chaque sous-tâche a un objectif clair et mesurable
- Documenter les prérequis et les résultats attendus pour chaque sous-tâche

### 2.2 Mode DEV-R (Développement Roadmap)

**Objectif** : Implémenter séquentiellement les sous-tâches identifiées par le mode GRAN.

**Méthodologie** :
1. Prendre une sous-tâche spécifique de la roadmap
2. Analyser les exigences et les contraintes
3. Rechercher des patterns existants ou des solutions similaires
4. Prototyper des solutions (Tree of Thoughts)
5. Implémenter la solution en suivant les standards du projet
6. Avancer séquentiellement sans attendre de confirmation

**Exemple d'utilisation** :
```powershell
Invoke-AugmentMode -Mode "DEV-R" -FilePath "projet/roadmaps/plans/plan-dev-v14-augment-optimization.md" -TaskIdentifier "1.2.3.1"
```plaintext
**Bonnes pratiques** :
- Limiter chaque implémentation à 5KB de code maximum
- Suivre les standards de codage du projet (PowerShell 7, Python 3.11)
- Documenter le code (minimum 20% du code)
- Implémenter de manière incrémentale, fonction par fonction

### 2.3 Mode ARCHI (Architecture)

**Objectif** : Concevoir et modéliser des solutions architecturales pour le projet.

**Méthodologie** :
1. Analyser les exigences et les contraintes du système
2. Identifier les composants principaux et leurs interactions
3. Créer des diagrammes et des modèles (ASCII, mermaid, etc.)
4. Définir les contrats d'interface entre les composants
5. Identifier les chemins critiques et les risques

**Exemple d'utilisation** :
```powershell
Invoke-AugmentMode -Mode "ARCHI" -FilePath "projet/architecture/email-sender-architecture.md"
```plaintext
**Bonnes pratiques** :
- Utiliser des diagrammes ASCII ou mermaid pour la visualisation
- Documenter clairement les interfaces entre les composants
- Considérer les aspects de sécurité, performance et maintenabilité
- Évaluer les options Multi-Instance vs. Multi-Tenant si pertinent

### 2.4 Mode DEBUG (Débogage)

**Objectif** : Identifier et corriger les bugs et les problèmes dans le code.

**Méthodologie** :
1. Reproduire le problème dans un environnement contrôlé
2. Isoler la source du problème (fonction, module, composant)
3. Analyser le code et les données pour identifier la cause
4. Implémenter une correction
5. Vérifier que la correction résout le problème
6. S'assurer que la correction n'introduit pas de nouveaux problèmes

**Exemple d'utilisation** :
```powershell
Invoke-AugmentMode -Mode "DEBUG" -FilePath "development/scripts/modules/EmailSender.psm1"
```plaintext
**Bonnes pratiques** :
- Ajouter des instructions Write-Verbose pour les valeurs intermédiaires
- Créer des tests unitaires simples pour isoler le problème
- Tester chaque fonction séparément
- Documenter la nature du bug et la solution appliquée

### 2.5 Mode TEST (Tests)

**Objectif** : Créer et exécuter des tests pour valider le fonctionnement du code.

**Méthodologie** :
1. Identifier les fonctionnalités à tester
2. Définir les cas de test (normal, limite, erreur)
3. Implémenter les tests unitaires avec Pester (PowerShell) ou pytest (Python)
4. Exécuter les tests et analyser les résultats
5. Corriger les problèmes identifiés
6. Mesurer la couverture de test

**Exemple d'utilisation** :
```powershell
Invoke-AugmentMode -Mode "TEST" -FilePath "development/scripts/modules/EmailSender.psm1"
```plaintext
**Bonnes pratiques** :
- Viser une couverture de test élevée (>80%)
- Tester les cas normaux, limites et d'erreur
- Utiliser des mocks pour isoler les dépendances externes
- Automatiser l'exécution des tests

## 3. Séquence recommandée des modes

Pour un développement efficace, suivre cette séquence de modes pour chaque tâche :

1. **GRAN** : Décomposer la tâche en sous-tâches gérables
2. **ARCHI** (si nécessaire) : Concevoir l'architecture pour les tâches complexes
3. **DEV-R** : Implémenter chaque sous-tâche
4. **TEST** : Créer et exécuter des tests pour valider l'implémentation
5. **DEBUG** : Corriger les problèmes identifiés par les tests
6. **REVIEW** : Vérifier la qualité du code
7. **OPTI** (si nécessaire) : Optimiser les performances

Cette séquence garantit une progression méthodique et une qualité constante.

## 4. Cycle de développement par tâche

Le cycle de développement par tâche est un processus structuré pour aborder chaque tâche :

1. **Analyze** : Décomposition et estimation
2. **Learn** : Recherche de patterns existants
3. **Explore** : Prototypage de solutions (ToT)
4. **Reason** : Boucle ReAct (analyser→exécuter→ajuster)
5. **Code** : Implémentation fonctionnelle (≤ 5KB)
6. **Progress** : Avancement séquentiel sans confirmation
7. **Adapt** : Ajustement de la granularité selon complexité
8. **Segment** : Division des tâches complexes

Ce cycle s'applique à chaque sous-tâche identifiée par le mode GRAN.

## 5. Gestion des inputs volumineux

Pour gérer efficacement les inputs volumineux :

- **Segmentation automatique** si > 5KB
- **Compression** (suppression commentaires/espaces)
- **Implémentation incrémentale** fonction par fonction
- **Référencement de fichiers** (@chemin/vers/fichier.md) plutôt que copier-coller

## 6. Intégration avec le module PowerShell

Le module PowerShell AugmentIntegration permet d'invoquer les modes opérationnels :

```powershell
# Importer le module

Import-Module AugmentIntegration

# Initialiser l'intégration

Initialize-AugmentIntegration -StartServers

# Exécuter un mode spécifique

Invoke-AugmentMode -Mode GRAN -FilePath "docs/plans/plan.md" -TaskIdentifier "1.2.3" -UpdateMemories
```plaintext
## 7. Gestion des Memories

Les Memories sont essentielles pour maintenir le contexte entre les sessions :

- **Mise à jour après chaque changement de mode**
- **Optimisation pour réduire la taille des contextes**
- **Segmentation intelligente des inputs volumineux**
- **Priorisation des informations pertinentes**

## 8. Exemples pratiques

### 8.1 Exemple de décomposition GRAN

```markdown
# Tâche originale

- [ ] **1.2.3** Implémenter l'analyse de complexité cyclomatique

# Après GRAN

- [ ] **1.2.3** Implémenter l'analyse de complexité cyclomatique
  - [ ] **1.2.3.1** Créer le module d'analyse AST PowerShell
  - [ ] **1.2.3.2** Implémenter la détection des structures de contrôle
  - [ ] **1.2.3.3** Développer l'algorithme de calcul de complexité
  - [ ] **1.2.3.4** Créer le rapport de complexité
  - [ ] **1.2.3.5** Intégrer avec le système de validation
```plaintext
### 8.2 Exemple de séquence complète

```powershell
# 1. Décomposer la tâche

Invoke-AugmentMode -Mode GRAN -FilePath "projet/roadmaps/plans/plan-dev-v14.md" -TaskIdentifier "1.2.3"

# 2. Implémenter la première sous-tâche

Invoke-AugmentMode -Mode "DEV-R" -FilePath "projet/roadmaps/plans/plan-dev-v14.md" -TaskIdentifier "1.2.3.1"

# 3. Tester l'implémentation

Invoke-AugmentMode -Mode "TEST" -FilePath "development/scripts/modules/ComplexityAnalyzer.psm1"

# 4. Déboguer les problèmes

Invoke-AugmentMode -Mode "DEBUG" -FilePath "development/scripts/modules/ComplexityAnalyzer.psm1"

# 5. Vérifier la qualité

Invoke-AugmentMode -Mode "REVIEW" -FilePath "development/scripts/modules/ComplexityAnalyzer.psm1"
```plaintext
## 9. Ressources additionnelles

- [Guide d'utilisation d'Augment](/docs/guides/augment/utilisation-augment.md)
- [Exemples de prompts efficaces](/docs/guides/augment/prompts-efficaces.md)
- [Bonnes pratiques pour la gestion des roadmaps](/projet/guides/methodologies/gestion-roadmaps.md)
- [Intégration avec n8n](/projet/guides/n8n/integration-augment-n8n.md)

---

> **Règle d'or** : *Granularité adaptative, tests systématiques, documentation claire*.
> Pour toute question, utiliser le mode approprié et progresser par étapes incrémentielles.
