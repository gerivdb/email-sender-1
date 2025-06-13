# Prompt de référence pour Augment

*Version 1.1 - 2025-05-14*

Ce document présente un exemple de prompt idéal pour Augment/Claude, servant de référence pour la formulation de requêtes optimales. Ce format est conçu pour maximiser l'efficacité et minimiser les erreurs d'interprétation, en s'inspirant des meilleures pratiques professionnelles de développement assisté par IA.

## Structure du prompt de référence

```plaintext
MODE: DEVR

TÂCHE: Implémenter un module de prédiction par régression linéaire simple

CONTEXTE:
@projet/guides/prd/prediction_module.md
@development/scripts/monitoring/TrendAnalyzer.psm1
@projet/tasks/task_123_regression_lineaire.md

# Informations supplémentaires

- Module: development/scripts/monitoring/SimpleLinearRegression.psm1 (à créer)
- Dépendances: Aucune externe, utilisation des fonctionnalités PowerShell standard
- Contraintes: Compatible PowerShell 5.1+, pas de dépendances externes

SPÉCIFICATIONS:

1. Structure du module:
   - Variables globales minimales (uniquement $script:Models pour stocker les modèles)
   - Fonctions d'accès aux modèles (Get-SimpleLinearModel)
   - Fonctions principales exposées (New-SimpleLinearModel, Invoke-SimpleLinearPrediction)

2. Fonction New-SimpleLinearModel:
   - Paramètres:
     * XValues [double[]] (obligatoire): Valeurs indépendantes
     * YValues [double[]] (obligatoire): Valeurs dépendantes
     * ModelName [string] (optionnel): Nom du modèle, généré automatiquement si non fourni
   - Comportement:
     * Calcul des coefficients (pente et ordonnée) par méthode des moindres carrés
     * Calcul des métriques de qualité (R², RMSE, MAE)
     * Stockage du modèle dans $script:Models
   - Retour: Nom du modèle créé

3. Fonction Invoke-SimpleLinearPrediction:
   - Paramètres:
     * ModelName [string] (obligatoire): Nom du modèle à utiliser
     * XValues [double[]] (obligatoire): Valeurs pour lesquelles prédire
     * ConfidenceLevel [double] (optionnel, défaut 0.95): Niveau de confiance
   - Comportement:
     * Récupération du modèle par son nom
     * Calcul des prédictions pour chaque valeur X
     * Calcul des intervalles de confiance
   - Retour: Hashtable avec prédictions et intervalles

4. Gestion des erreurs:
   - Vérification des dimensions des tableaux d'entrée
   - Gestion des cas de division par zéro
   - Validation des paramètres (ConfidenceLevel entre 0 et 1)
   - Retour de $null avec message d'erreur explicite en cas d'échec

5. Documentation:
   - Commentaires .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE pour chaque fonction
   - En-tête de module avec version et auteur
   - Commentaires explicatifs pour les algorithmes complexes

TESTS:

1. Test de création de modèle:
   - Données parfaitement linéaires (y = 2x)
   - Vérification des coefficients (pente = 2, ordonnée = 0)
   - Vérification des métriques (R² proche de 1)

2. Test de prédiction:
   - Prédiction pour des valeurs dans la plage des données d'entraînement
   - Prédiction pour des valeurs hors de la plage (extrapolation)
   - Vérification des intervalles de confiance

3. Test avec données bruitées:
   - Données avec tendance linéaire + bruit aléatoire
   - Vérification que les coefficients sont proches des valeurs attendues
   - Vérification que R² est raisonnable (> 0.8)

4. Tests de robustesse:
   - Gestion des tableaux vides ou trop petits
   - Gestion des valeurs extrêmes
   - Gestion des noms de modèles invalides ou inexistants

LIVRABLES ATTENDUS:

1. Module SimpleLinearRegression.psm1 complet
2. Script de test Test-SimpleLinearRegression.ps1
3. Documentation des fonctions et exemples d'utilisation

APPROCHE RECOMMANDÉE:

1. Implémenter d'abord la structure de base du module
2. Développer la fonction de création de modèle avec algorithme simple
3. Ajouter les métriques de qualité
4. Implémenter la fonction de prédiction
5. Ajouter la gestion des erreurs
6. Créer les tests unitaires
7. Finaliser la documentation
```plaintext
## Analyse des éléments clés

### 1. Spécification du mode

Le prompt commence par `MODE: DEVR` qui indique clairement qu'il s'agit d'une demande de développement. Cela oriente immédiatement Augment vers le bon type de réponse.

### 2. Tâche concise

La section `TÂCHE:` fournit une description claire et concise de l'objectif, en une seule phrase.

### 3. Contexte structuré

La section `CONTEXTE:` utilise des puces pour présenter les informations essentielles:
- Emplacement du fichier
- Dépendances
- Objectif fonctionnel
- Contraintes techniques

### 4. Spécifications détaillées

Les `SPÉCIFICATIONS:` sont organisées en sections numérotées avec:
- Structure claire avec hiérarchie (puces et sous-puces)
- Détails précis sur les paramètres et comportements attendus
- Informations sur la gestion des erreurs et la documentation

### 5. Tests explicites

La section `TESTS:` définit clairement:
- Les scénarios de test à implémenter
- Les critères de validation
- Les cas limites à gérer

### 6. Livrables et approche

Les sections finales clarifient:
- Les fichiers attendus
- Une séquence d'implémentation recommandée

## Pourquoi ce format est optimal

1. **Structuration claire**: La hiérarchie visuelle facilite la compréhension
2. **Niveau de détail équilibré**: Suffisamment précis sans micro-management
3. **Contexte complet**: Toutes les informations nécessaires sont fournies
4. **Attentes explicites**: Les critères de succès sont clairement définis
5. **Approche guidée**: Une séquence d'implémentation est suggérée

## Approche PRD et système de tâches

L'utilisation d'un PRD (Product Requirements Document) comme source de vérité et d'un système de gestion de tâches améliore considérablement l'efficacité du développement avec Augment.

### Exemple de prompt pour générer un PRD

```plaintext
MODE: ARCHI

TÂCHE: Générer un PRD pour le module de prédiction par régression linéaire

CONTEXTE:
- Objectif: Créer un module PowerShell pour prédire des valeurs futures basées sur des données historiques
- Utilisateurs: Administrateurs système et analystes de données
- Intégration: Doit s'intégrer avec le module TrendAnalyzer existant

DÉTAILS:
Générer un PRD structuré en Markdown avec les sections suivantes:
1. Introduction et objectifs
2. User Stories / Cas d'utilisation
3. Spécifications fonctionnelles détaillées
4. Spécifications techniques et contraintes
5. Critères d'acceptation et stratégie de test
6. Dépendances et intégrations

Le PRD doit être suffisamment détaillé pour servir de base à la décomposition en tâches
et à l'implémentation, tout en restant concis (max 2-3 pages).
```plaintext
### Exemple de prompt pour décomposer un PRD en tâches

```plaintext
MODE: GRAN

TÂCHE: Décomposer le PRD du module de prédiction en tâches gérables

CONTEXTE:
@projet/guides/prd/prediction_module.md

DÉTAILS:
Analyser ce PRD et créer une liste de tâches avec:
- ID unique (format: PRED-XXX)
- Titre descriptif
- Description détaillée
- Dépendances entre tâches
- Priorité (high/medium/low)
- Estimation de temps (en heures)
- Stratégie de test

Organiser les tâches en groupes logiques et identifier le chemin critique.
Chaque tâche doit représenter environ 2-4 heures de travail.
```plaintext
## Adaptations selon les modes

Ce format peut être adapté pour d'autres modes:

### Mode GRAN

```plaintext
MODE: GRAN

TÂCHE: Décomposer la fonctionnalité de prédiction en sous-tâches gérables

CONTEXTE:
@projet/guides/prd/prediction_system.md
@projet/roadmaps/plans/plan-dev-v13.md

# Informations supplémentaires

- Fonctionnalité: Système de prédiction de charge
- Complexité estimée: Élevée (40-60h)
- Niveau de granularité souhaité: Tâches de 2-4h maximum
- Structure: 2 niveaux de profondeur minimum

SPÉCIFICATIONS:
[...]
```plaintext
### Mode DEBUG

```plaintext
MODE: DEBUG

TÂCHE: Corriger les erreurs dans le calcul du R² négatif

CONTEXTE:
@development/scripts/monitoring/SimpleLinearRegression.psm1
@development/scripts/monitoring/Test-SimpleLinearRegression.ps1
@projet/tasks/task_124_debug_r2.md

# Informations supplémentaires

- Fonction: New-SimpleLinearModel
- Symptôme: R² négatif avec certaines données
- Lignes concernées: 120-135

SPÉCIFICATIONS:
[...]
```plaintext
## Conclusion

Ce format de prompt représente un équilibre optimal entre:
- Précision des instructions
- Clarté de la structure
- Complétude des informations
- Flexibilité pour Augment

Les éléments clés qui distinguent cette approche professionnelle sont:

1. **Utilisation du PRD comme source de vérité**
   - Document central qui définit clairement les exigences
   - Base pour la décomposition en tâches
   - Référence pour valider l'implémentation

2. **Référencement de fichiers plutôt que copier-coller**
   - Fournit un contexte riche sans dépasser les limites de taille
   - Maintient la cohérence entre les sessions
   - Permet d'accéder à l'information complète

3. **Système de gestion de tâches structuré**
   - Décomposition en unités de travail gérables
   - Suivi clair des dépendances et priorités
   - Progression méthodique et vérifiable

4. **Workflow de développement itératif**
   - PRD → Tâches → DEVR → DEBUG → TEST → MAJ → Tâche suivante
   - Chaque étape a un objectif clair et des livrables définis
   - Permet de maintenir une qualité constante

En suivant ce modèle et en l'adaptant selon les besoins spécifiques, vous maximiserez l'efficacité de vos interactions avec Augment et minimiserez les erreurs d'interprétation, tout en produisant du code de qualité professionnelle.
