# Guidelines d'utilisation optimale d'Augment
*Version 2.3 - 2025-05-16*

Ce document présente les meilleures pratiques pour interagir efficacement avec Augment/Claude afin de maximiser la productivité et minimiser les erreurs lors du développement. Ces guidelines s'inspirent des méthodes professionnelles de développement assisté par IA, des analyses des meilleures pratiques dans les projets n8n, d'automatisation et des principes de Langchain pour la création d'applications IA avancées.

## 1. Formulation des requêtes

### 1.1 Structure optimale des prompts

```
MODE: [GRAN|DEVR|DEBUG|TEST|MAJ|ARCHI|REVIEW]

TÂCHE: [Description concise de la tâche]

CONTEXTE:
- [Information contextuelle pertinente]
- [Contraintes ou exigences spécifiques]
- [Références aux fichiers pertinents avec @chemin/vers/fichier.md]

DÉTAILS:
[Description détaillée si nécessaire]
[Exemples ou cas d'utilisation pour clarifier l'intention]
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
- Roadmap actuelle: @projet/roadmaps/plans/plan-dev-v13.md
- Niveau de détail souhaité: 2 niveaux de profondeur
- Estimation de temps souhaitée pour chaque tâche: 1-2h max
- Granularité cible: 30-50 lignes de code par fonction

DÉTAILS:
- Identifier les composants logiques indépendants
- Spécifier les dépendances entre sous-tâches
- Estimer la complexité relative de chaque sous-tâche
```

#### Pour le mode DEVR (Développement)
```
MODE: DEVR

TÂCHE: Implémenter la fonction de régression linéaire simple

CONTEXTE:
- Module cible: @monitoring/PredictiveModels.psm1
- Algorithme: y = mx + b avec calcul des coefficients par moindres carrés
- Structures de données: entrée = tableaux X et Y, sortie = objet avec coefficients et métriques
- Standards de code: @projet/guides/methodologies/standards-code.md

DÉTAILS:
- Inclure le calcul du R², RMSE et MAE
- Gérer les cas d'erreur (données insuffisantes, division par zéro)
- Documenter avec le format de commentaires PowerShell standard
- Limiter la complexité cyclomatique à < 10
```

#### Pour le mode DEBUG
```
MODE: DEBUG

TÂCHE: Corriger les problèmes d'accès aux tableaux multidimensionnels

CONTEXTE:
- Fichier: @monitoring/PredictiveModels.psm1
- Erreur observée: "Impossible d'indexer dans un tableau null"
- Lignes concernées: 330-350
- Tests échoués: @development/testing/tests/PredictiveModels.Tests.ps1

DÉTAILS:
- Remplacer la syntaxe d'indexation directe par GetValue/SetValue
- Ajouter des vérifications de null
- Tester avec les cas limites
- Ajouter des instructions Write-Verbose pour les valeurs intermédiaires
```

#### Pour le mode ARCHI (Architecture)
```
MODE: ARCHI

TÂCHE: Concevoir l'architecture d'intégration MCP-n8n

CONTEXTE:
- Documentation MCP: @src/mcp/docs/api.md
- Workflows n8n existants: @src/n8n/workflows/email-sender-phase1.json
- Décisions architecturales: @projet/guides/architecture/decisions-architecturales.md

DÉTAILS:
- Définir le flux de données entre n8n et MCP
- Spécifier le format des échanges de données
- Concevoir le mécanisme de gestion des erreurs
- Proposer une stratégie de mise en cache pour optimiser les performances
- Fournir un diagramme d'architecture (ASCII ou mermaid)
```

## 2. Modes opérationnels

### 2.1 Séquence recommandée
```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   GRAN  │ -> │  DEVR   │ -> │  TESTS  │ -> │  DEBUG  │ -> │  CHECK  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
```

Cette séquence complète garantit un développement méthodique et de haute qualité :
1. **GRAN** : Décomposer la tâche en sous-tâches gérables
2. **DEVR** : Implémenter chaque sous-tâche
3. **TESTS** : Créer et exécuter des tests pour valider l'implémentation
4. **DEBUG** : Corriger les problèmes identifiés par les tests
5. **CHECK** : Vérifier l'implémentation et mettre à jour la roadmap

### 2.2 Description des modes

| Mode | Objectif | Quand l'utiliser |
|------|----------|------------------|
| **GRAN** | Décomposer les tâches complexes | Avant de commencer une nouvelle fonctionnalité majeure |
| **DEVR** | Implémenter du code | Pour créer de nouvelles fonctionnalités |
| **TESTS** | Créer et exécuter des tests | Après l'implémentation initiale |
| **DEBUG** | Corriger les erreurs | Quand les tests échouent ou le code ne fonctionne pas comme prévu |
| **CHECK** | Vérifier et mettre à jour la roadmap | Après avoir corrigé tous les problèmes |
| **ARCHI** | Concevoir l'architecture | Avant d'implémenter des systèmes complexes |
| **REVIEW** | Réviser le code | Pour améliorer la qualité du code existant |
| **OPTI** | Optimiser les performances | Après avoir un code fonctionnel mais lent |
| **PREDIC** | Analyse prédictive | Pour anticiper les performances et anomalies |
| **C-BREAK** | Résoudre les dépendances circulaires | Quand des cycles de dépendances sont détectés |

### 2.3 Bonnes pratiques par mode

#### GRAN
- Spécifier le niveau de détail souhaité (1-3 niveaux)
- Indiquer la taille cible des tâches (30min-2h)
- Fournir le contexte du projet
- Viser une granularité de 30-50 lignes de code par fonction
- Identifier les dépendances entre sous-tâches

#### DEVR
- Limiter à une fonctionnalité cohérente par requête
- Spécifier les structures de données d'entrée/sortie
- Indiquer les dépendances et imports nécessaires
- Limiter la complexité cyclomatique à < 10
- Suivre le pattern standard pour les workflows n8n

#### TESTS
- Spécifier les cas de test prioritaires
- Indiquer les valeurs attendues
- Préciser le format de rapport souhaité
- Tester les cas normaux, limites et d'erreur
- Utiliser Pester pour PowerShell et pytest pour Python

#### DEBUG
- Décrire précisément l'erreur observée
- Fournir les messages d'erreur exacts
- Indiquer les conditions de reproduction
- Ajouter des instructions Write-Verbose pour les valeurs intermédiaires
- Isoler les problèmes en testant chaque fonction séparément

#### CHECK
- Vérifier que toutes les exigences sont satisfaites
- Mettre à jour la roadmap avec les tâches complétées
- Documenter les décisions prises et les solutions implémentées
- Vérifier la couverture de test
- S'assurer que la documentation est à jour

#### ARCHI
- Utiliser des diagrammes (ASCII ou mermaid) pour visualiser l'architecture
- Documenter les interfaces entre composants
- Considérer les aspects de sécurité, performance et maintenabilité
- Évaluer les options Multi-Instance vs. Multi-Tenant si pertinent
- Définir clairement les contrats d'interface

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
   - Architecture existante: @projet/guides/architecture/decisions-architecturales.md

   DÉTAILS:
   Générer un PRD structuré en Markdown avec les sections suivantes:
   1. Introduction
   2. Objectifs
   3. User Stories / Cas d'utilisation
   4. Spécifications fonctionnelles
   5. Spécifications techniques
   6. Intégration avec les systèmes existants
   7. Considérations de sécurité et performance
   8. Critères d'acceptation
   ```

2. **Utilisation du PRD** :
   - Stocker le PRD dans `/projet/guides/` ou `/docs/`
   - Référencer le PRD dans les prompts ultérieurs
   - Utiliser le PRD comme base pour la décomposition des tâches (mode GRAN)
   - Maintenir le PRD à jour au fur et à mesure de l'évolution du projet

### 5.1.1 Pattern de workflow n8n

Pour les projets impliquant n8n, suivre ce pattern standard dans le PRD :

```
Trigger -> Read -> Filter -> Act -> Update -> Wait -> Re-check -> Conditional Act -> Update
```

Exemple de workflow pour l'envoi d'emails :
```
+---------+      +----------------+      +-------+      +---------+      +----------------+
|  CRON   | ---> | Read Contacts  | ---> |  IF   | ---> |  Send   | ---> | Update Status  |
| (Sched) |      | (Notion/GCal)  |      | Filter|      | Email 1 |      | (e.g., Contacted)|
+---------+      +----------------+      +-------+      +---------+      +----------------+
                                                                               |
                                                                               V
+---------+      +----------------+      +-------+      +---------+      +----------------+
|  Wait   | <--- | Update Status  | <--- |  Send   | <--- |  IF   | <--- | Read Status    |
| (Delay) |      | (e.g., FollowUp)|      | Email 2 |      | NoReply?|      | (Check Reply)  |
+---------+      +----------------+      +---------+      +-------+      +----------------+
```

### 5.1.2 Intégration MCP-n8n

Pour les projets utilisant MCP (Model Context Protocol) avec n8n, suivre ce pattern :

```
+-----------------+      +--------------+      +-----------------+      +---------+
| Read Contact    | ---> | Prepare Data | ---> | Call MCP        | ---> | Send    |
| (Notion)        |      | (Context)    |      | (Get AI Text)   |      | Email   |
+-----------------+      +--------------+      +-----------------+      +---------+
                                 |                     |
                                 +---------------------+
                                       (Pass Data)
```

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
| Suivre la séquence DEVR→TESTS→DEBUG→CHECK | Sauter des étapes dans le processus |
| Utiliser des techniques de prompting avancées | Se contenter de prompts vagues |
| Structurer les workflows n8n selon le pattern standard | Créer des workflows ad hoc sans structure |
| Considérer les aspects Multi-Instance vs. Multi-Tenant | Ignorer les implications architecturales |

### 6.3 Gestion des sessions longues

- Résumer périodiquement l'état d'avancement
- Utiliser des points de contrôle explicites
- Diviser les tâches complexes en sessions distinctes
- Maintenir un système de tâches externe pour suivre la progression

### 6.4 Techniques de prompting avancées

#### Few-shot prompting
Fournir des exemples pour guider la génération :

```
# Exemple de fonction bien formatée :
function Get-Example {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    # Description de la fonction
    Write-Verbose "Getting example for $Name"

    # Code de la fonction
    return "Example: $Name"
}

# Maintenant, créez une fonction Get-ContactStatus avec cette même structure
```

#### Chain-of-Thought (CoT)
Encourager un raisonnement étape par étape :

```
Analysez ce problème étape par étape :
1. Identifiez d'abord les structures de contrôle dans le code
2. Calculez la profondeur d'imbrication pour chaque structure
3. Déterminez les zones à risque de complexité excessive
4. Proposez des refactorisations pour simplifier ces zones
```

#### Prompting itératif
Affiner progressivement les prompts en fonction des résultats :

1. Commencer par un prompt simple et précis
2. Analyser le résultat et identifier les points à améliorer
3. Reformuler le prompt avec plus de détails ou de contraintes
4. Répéter jusqu'à obtenir le résultat souhaité

## 7. Principes de Langchain pour Augment

### 7.1 Concepts clés de Langchain applicables à Augment

- **Components** : LLM Wrappers (OpenRouter/DeepSeek), Prompt Templates, Indexes (VectorStores)
- **Chains** : Assemblage de composants pour des tâches spécifiques (ex: génération d'emails)
- **Agents** : LLM + outils pour interagir avec l'environnement (ex: modes opérationnels)
- **RAG (Retrieval Augmented Generation)** : Enrichissement des prompts avec des données contextuelles

### 7.2 Pipeline RAG pour la contextualisation

```
Document Source → Chunking → Embeddings → VectorStore → Similarity Search → Prompt Augmenté → Réponse
```

Ce pipeline peut être utilisé pour :
- Enrichir les prompts avec du contexte spécifique au projet
- Implémenter les Memories d'Augment via un VectorStore
- Permettre des recherches sémantiques dans la documentation et le code

### 7.3 Agents Langchain pour les modes opérationnels

Chaque mode d'Augment peut être implémenté comme un Agent Langchain avec des outils spécifiques :

| Mode | Outils potentiels |
|------|-------------------|
| GRAN | MCP Filesystem, VectorStore "Roadmaps Passées", LLM Interaction |
| DEVR | MCP GitHub, Code Generation, Test Execution |
| DEBUG | Error Analysis, Code Inspection, Test Runner |
| ARCHI | Diagramming, Pattern Matching, Dependency Analysis |

### 7.4 Intégration avec MCP et n8n

```
User Command (Invoke-AugmentMode)
     |
     V
+---------------------+
| AugmentCode (Core)  |
| (Orchestrateur)     |
+----+------------+---+
     |            |
(Lance Agent) (Prépare Contexte via MCP)
     V            V
+---------------------+      +---------------------------------+
| Agent Langchain     |----->| MCP (Filesystem, GitHub, etc.)  |
| (Mode Spécifique)   |      +---------------------------------+
| - LLM               |
| - PromptTemplate    |
| - Tools (MCP, Scripts) |
| - VectorStore (Memories)|
+---------+-----------+
          |
          V
Actions (Modification de fichiers,
         Appel API, etc.)
```

## 8. Ressources additionnelles

- [Guide des modes opérationnels Augment](/projet/guides/methodologies/modes-operationnels-augment.md)
- [Bonnes pratiques n8n](/projet/guides/n8n/bonnes-pratiques-n8n.md)
- [Décisions architecturales](/projet/guides/architecture/decisions-architecturales.md)
- [Intégration Augment-n8n](/projet/guides/n8n/integration-augment-n8n.md)
- [Principes de Langchain](/projet/guides/methodologies/principes-langchain.md)
- [Documentation officielle n8n](https://docs.n8n.io/)
- [Documentation officielle Langchain](https://python.langchain.com/docs/get_started/introduction)

---

Ces guidelines sont évolutives et seront mises à jour en fonction des retours d'expérience et des nouveaux apprentissages.
