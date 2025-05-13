# Guidelines d'utilisation optimale d'Augment
*Version 2.1 - 2025-05-14*

Ce document présente les meilleures pratiques pour interagir efficacement avec Augment/Claude afin de maximiser la productivité et minimiser les erreurs lors du développement. Ces guidelines s'inspirent des méthodes professionnelles de développement assisté par IA.

## 1. Formulation des requêtes

### 1.1 Structure optimale des prompts

```
MODE: [GRAN|DEVR|DEBUG|TEST|MAJ]

TÂCHE: [Description concise de la tâche]

CONTEXTE:
- [Information contextuelle pertinente]
- [Contraintes ou exigences spécifiques]

DÉTAILS:
[Description détaillée si nécessaire]
```

### 1.2 Niveaux de granularité

| Niveau | Description | Exemple |
|--------|-------------|---------|
| **Trop fin** | Instructions trop détaillées | "Écris la ligne 27 avec cette syntaxe exacte..." |
| **Optimal** | Fonctionnalité cohérente | "Implémente une fonction qui calcule la moyenne mobile avec une fenêtre paramétrable" |
| **Trop large** | Objectif trop ambitieux | "Crée tout le système de prédiction" |

### 1.3 Exemples de prompts efficaces

#### Pour le mode GRAN (Granularisation)
```
MODE: GRAN

TÂCHE: Décomposer la tâche 2.3 "Système de prédiction" en sous-tâches gérables

CONTEXTE:
- Roadmap actuelle: projet/roadmaps/plans/plan-dev-v13.md
- Niveau de détail souhaité: 2 niveaux de profondeur
- Estimation de temps souhaitée pour chaque tâche: 1-2h max
```

#### Pour le mode DEVR (Développement)
```
MODE: DEVR

TÂCHE: Implémenter la fonction de régression linéaire simple

CONTEXTE:
- Module cible: monitoring/PredictiveModels.psm1
- Algorithme: y = mx + b avec calcul des coefficients par moindres carrés
- Structures de données: entrée = tableaux X et Y, sortie = objet avec coefficients et métriques

DÉTAILS:
- Inclure le calcul du R², RMSE et MAE
- Gérer les cas d'erreur (données insuffisantes, division par zéro)
- Documenter avec le format de commentaires PowerShell standard
```

#### Pour le mode DEBUG
```
MODE: DEBUG

TÂCHE: Corriger les problèmes d'accès aux tableaux multidimensionnels

CONTEXTE:
- Fichier: monitoring/PredictiveModels.psm1
- Erreur observée: "Impossible d'indexer dans un tableau null"
- Lignes concernées: 330-350

DÉTAILS:
- Remplacer la syntaxe d'indexation directe par GetValue/SetValue
- Ajouter des vérifications de null
- Tester avec les cas limites
```

## 2. Modes opérationnels

### 2.1 Séquence recommandée
```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   DEVR  │ -> │  DEBUG  │ -> │  TEST   │ -> │   MAJ   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

### 2.2 Description des modes

| Mode | Objectif | Quand l'utiliser |
|------|----------|------------------|
| **GRAN** | Décomposer les tâches complexes | Avant de commencer une nouvelle fonctionnalité majeure |
| **DEVR** | Implémenter du code | Pour créer de nouvelles fonctionnalités |
| **DEBUG** | Corriger les erreurs | Quand le code ne fonctionne pas comme prévu |
| **TEST** | Créer et exécuter des tests | Après l'implémentation ou le débogage |
| **MAJ** | Mettre à jour la documentation/roadmap | Après validation des tests |
| **ARCHI** | Concevoir l'architecture | Avant d'implémenter des systèmes complexes |
| **REVIEW** | Réviser le code | Pour améliorer la qualité du code existant |

### 2.3 Bonnes pratiques par mode

#### GRAN
- Spécifier le niveau de détail souhaité (1-3 niveaux)
- Indiquer la taille cible des tâches (30min-2h)
- Fournir le contexte du projet

#### DEVR
- Limiter à une fonctionnalité cohérente par requête
- Spécifier les structures de données d'entrée/sortie
- Indiquer les dépendances et imports nécessaires

#### DEBUG
- Décrire précisément l'erreur observée
- Fournir les messages d'erreur exacts
- Indiquer les conditions de reproduction

#### TEST
- Spécifier les cas de test prioritaires
- Indiquer les valeurs attendues
- Préciser le format de rapport souhaité

## 3. Taille et complexité optimales

### 3.1 Modules et fonctions

| Élément | Taille optimale | Maximum recommandé |
|---------|-----------------|-------------------|
| Module | 100-200 lignes | 300 lignes |
| Fonction | 30-50 lignes | 100 lignes |
| Paramètres | 3-5 | 7 |
| Profondeur d'imbrication | 2-3 niveaux | 4 niveaux |

### 3.2 Complexité cognitive

- **Simple**: Une fonction avec un flux linéaire
- **Modéré**: Quelques conditions et boucles
- **Complexe**: Algorithmes avec récursion ou structures de données avancées

### 3.3 Recommandations

- Privilégier plusieurs fonctions simples plutôt qu'une fonction complexe
- Limiter la portée des variables (utiliser begin/process/end en PowerShell)
- Documenter les structures de données complexes

## 4. Gestion des erreurs et débogage

### 4.1 Stratégies de débogage efficaces

1. **Isolation**: Tester les fonctions individuellement
2. **Visualisation**: Afficher les valeurs intermédiaires
3. **Simplification**: Réduire à un cas minimal reproductible

### 4.2 Instructions de débogage à inclure

```powershell
# Points de débogage stratégiques
Write-Verbose "Entrée: $($input | ConvertTo-Json -Compress)"
Write-Verbose "État intermédiaire: $intermediateValue"
Write-Verbose "Résultat: $result"

# Pour les tests
Write-Host "  Attendu: $expected"
Write-Host "  Obtenu: $actual"
Write-Host "  Différence: $($actual - $expected)"
```

### 4.3 Tests progressifs

- Commencer par des cas simples et prévisibles
- Ajouter progressivement des cas plus complexes
- Tester explicitement les cas limites

## 5. Méthodologie de développement structurée

### 5.1 Approche PRD (Product Requirements Document)

Le PRD est un document fondamental qui sert de "source de vérité" pour le développement :

1. **Création du PRD** :
   ```
   MODE: ARCHI

   TÂCHE: Générer un PRD pour [nom du projet/fonctionnalité]

   CONTEXTE:
   - Exigences principales: [liste des exigences]
   - Contraintes techniques: [liste des contraintes]
   - Utilisateurs cibles: [description des utilisateurs]

   DÉTAILS:
   Générer un PRD structuré en Markdown avec les sections suivantes:
   1. Introduction
   2. Objectifs
   3. User Stories / Cas d'utilisation
   4. Spécifications fonctionnelles
   5. Spécifications techniques
   6. Critères d'acceptation
   ```

2. **Utilisation du PRD** :
   - Stocker le PRD dans `/projet/guides/` ou `/docs/`
   - Référencer le PRD dans les prompts ultérieurs
   - Utiliser le PRD comme base pour la décomposition des tâches (mode GRAN)

### 5.2 Système de gestion de tâches

Un système de gestion de tâches efficace améliore considérablement la productivité :

1. **Décomposition du PRD en tâches** :
   ```
   MODE: GRAN

   TÂCHE: Décomposer le PRD en tâches gérables

   CONTEXTE:
   @chemin/vers/prd.md

   DÉTAILS:
   Analyser ce PRD et créer une liste de tâches avec:
   - ID unique
   - Titre descriptif
   - Description détaillée
   - Dépendances entre tâches
   - Priorité (high/medium/low)
   - Stratégie de test
   ```

2. **Workflow de développement par tâches** :
   - Identifier la prochaine tâche à implémenter (selon dépendances et priorités)
   - Implémenter la tâche en mode DEVR
   - Déboguer et tester (modes DEBUG et TEST)
   - Mettre à jour le statut de la tâche
   - Passer à la tâche suivante

### 5.3 Référencement de fichiers et contextualisation

Plutôt que de copier-coller de grands blocs de code ou de documentation, référencer les fichiers pertinents :

```
MODE: DEVR

TÂCHE: Implémenter la fonctionnalité X

CONTEXTE:
@chemin/vers/prd.md
@chemin/vers/module_existant.psm1
@chemin/vers/tache_123.md

DÉTAILS:
Implémenter la fonctionnalité X décrite dans le PRD et la tâche 123,
en étendant le module existant.
```

Cette approche permet de :
- Fournir un contexte riche sans dépasser les limites de taille des prompts
- Maintenir la cohérence entre les différentes sessions
- Assurer que l'IA a accès à toutes les informations pertinentes

## 6. Communication efficace avec Augment

### 6.1 Principes clés

- **Spécificité**: Être précis sur ce qui est attendu
- **Contexte**: Fournir les informations nécessaires via référencement de fichiers
- **Feedback**: Indiquer ce qui fonctionne et ce qui ne fonctionne pas
- **Itération**: Voir le développement comme un processus collaboratif et itératif

### 6.2 À faire et à éviter

| À faire | À éviter |
|---------|----------|
| Spécifier le mode opérationnel | Changer de sujet sans transition |
| Référencer les fichiers pertinents (@fichier) | Copier-coller de grands blocs de code |
| Indiquer les contraintes | Supposer des connaissances implicites |
| Demander des clarifications | Continuer malgré l'incompréhension |
| Fournir des règles de codage claires | Accepter du code de mauvaise qualité |
| Décomposer les tâches complexes | Demander trop en une seule fois |

### 6.3 Gestion des sessions longues

- Résumer périodiquement l'état d'avancement
- Utiliser des points de contrôle explicites
- Diviser les tâches complexes en sessions distinctes
- Maintenir un système de tâches externe pour suivre la progression

---

Ces guidelines sont évolutives et seront mises à jour en fonction des retours d'expérience et des nouveaux apprentissages.
