# Prompts efficaces pour Augment

*Version 2025-05-15*

Ce guide présente les meilleures pratiques pour formuler des prompts efficaces avec Augment, basées sur l'analyse des documents de référence et des exemples pratiques.

## 1. Principes fondamentaux

### 1.1 Clarté et précision

- **Soyez spécifique** : Définissez clairement l'objectif, le contexte et les contraintes
- **Utilisez un langage précis** : Évitez les ambiguïtés et les termes vagues
- **Structurez vos prompts** : Utilisez des sections, des listes et des exemples

### 1.2 Contexte et contraintes

- **Fournissez le contexte nécessaire** : Architecture, standards, dépendances
- **Spécifiez les contraintes** : Limites de taille, performance, compatibilité
- **Indiquez le niveau de détail attendu** : Conception de haut niveau ou implémentation détaillée

### 1.3 Gestion des inputs volumineux

- **Segmentez les inputs** : Limitez à 5KB par prompt
- **Référencez les fichiers** : Utilisez `@chemin/vers/fichier.md` plutôt que de copier-coller
- **Compressez l'information** : Supprimez les commentaires et espaces inutiles

## 2. Structure recommandée par mode

### 2.1 Prompts pour le mode GRAN

```plaintext
# Demande de granularisation de tâche

## Tâche à granulariser

- Identifiant : 1.2.3
- Description : [Description de la tâche]
- Fichier : @projet/roadmaps/plans/plan-dev-v14.md

## Contexte

- [Informations sur le projet, l'architecture, les contraintes]
- [Dépendances avec d'autres tâches]

## Niveau de granularité souhaité

- Profondeur : 2 niveaux
- Taille cible par sous-tâche : 30-50 lignes de code

## Format de sortie attendu

- Liste hiérarchique avec identifiants (1.2.3.1, 1.2.3.2, etc.)
- Description claire pour chaque sous-tâche
- Estimation de complexité (Faible/Moyenne/Élevée)
```plaintext
### 2.2 Prompts pour le mode DEV-R

```plaintext
# Demande d'implémentation de tâche

## Tâche à implémenter

- Identifiant : 1.2.3.1
- Description : [Description de la sous-tâche]
- Fichier : @projet/roadmaps/plans/plan-dev-v14.md

## Contexte technique

- Langage : PowerShell 7 / Python 3.11
- Standards : [Conventions de nommage, structure, etc.]
- Dépendances : [Modules, bibliothèques, services]

## Contraintes

- Taille maximale : 5KB de code
- Complexité cyclomatique < 10
- Documentation : minimum 20% du code

## Résultats attendus

- Fichier(s) à créer/modifier : [Liste des fichiers]
- Fonctionnalités à implémenter : [Liste des fonctionnalités]
- Tests à créer : [Description des tests]
```plaintext
### 2.3 Prompts pour le mode ARCHI

```plaintext
# Demande de conception architecturale

## Objectif

- [Description du système/composant à concevoir]
- [Problématiques à résoudre]

## Contexte

- [Architecture existante]
- [Contraintes techniques et métier]
- [Intégrations requises]

## Points de décision

- [Liste des décisions architecturales à prendre]
- [Options à considérer pour chaque décision]

## Format de sortie attendu

- Diagramme d'architecture (ASCII ou mermaid)
- Description des composants et leurs interactions
- Justification des choix architecturaux
- Identification des risques et mitigations
```plaintext
### 2.4 Prompts pour le mode DEBUG

```plaintext
# Demande de débogage

## Problème rencontré

- [Description du bug ou de l'erreur]
- [Message d'erreur exact]
- [Comportement attendu vs. observé]

## Contexte

- Fichier : @development/scripts/modules/Module.psm1
- Fonction : [Nom de la fonction problématique]
- Environnement : [Version PowerShell, OS, etc.]

## Tentatives de résolution

- [Actions déjà entreprises]
- [Hypothèses testées]

## Résultats attendus

- Identification de la cause racine
- Correction du code
- Tests pour valider la correction
- Documentation de la solution
```plaintext
### 2.5 Prompts pour le mode TEST

```plaintext
# Demande de création de tests

## Code à tester

- Fichier : @development/scripts/modules/Module.psm1
- Fonctions : [Liste des fonctions à tester]

## Types de tests requis

- Tests unitaires
- Tests d'intégration
- Tests de performance (si applicable)

## Cas de test à couvrir

- Cas normaux : [Description]
- Cas limites : [Description]
- Cas d'erreur : [Description]

## Format de sortie attendu

- Fichiers de test Pester/pytest
- Documentation des tests
- Mesure de la couverture de test
```plaintext
## 3. Techniques avancées

### 3.1 Prompting itératif

Le prompting itératif consiste à affiner progressivement les prompts en fonction des résultats :

1. **Commencer simple** : Prompt initial clair et concis
2. **Analyser le résultat** : Identifier les forces et faiblesses
3. **Affiner le prompt** : Ajouter des précisions, contraintes ou exemples
4. **Répéter** : Continuer jusqu'à obtenir le résultat souhaité

### 3.2 Few-shot prompting

Le few-shot prompting consiste à fournir des exemples pour guider la génération :

```plaintext
# Demande de création de fonctions PowerShell

## Format attendu

Exemple 1:
```powershell
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
```plaintext
Exemple 2:
[...]

## Fonction à créer

- Nom : Get-ContactStatus
- Paramètres : $ContactId (string, obligatoire), $Verbose (switch, optionnel)
- Fonctionnalité : Récupérer le statut d'un contact dans Notion
```plaintext
### 3.3 Chain-of-Thought (CoT)

Le Chain-of-Thought encourage un raisonnement étape par étape :

```plaintext
# Demande d'optimisation de performance

## Problème

Le script d'analyse de complexité est trop lent sur les grands fichiers.

## Approche souhaitée

Veuillez analyser ce problème étape par étape :
1. Identifiez les goulots d'étranglement potentiels dans le code actuel
2. Proposez des optimisations pour chaque goulot d'étranglement
3. Évaluez l'impact potentiel de chaque optimisation
4. Implémentez les optimisations les plus prometteuses
5. Suggérez des métriques pour mesurer l'amélioration
```plaintext
## 4. Exemples concrets

### 4.1 Prompt pour créer un workflow n8n

```plaintext
# Création d'un workflow n8n pour EMAIL SENDER 1

## Objectif

Créer un workflow n8n pour la Phase 1 (Prospection initiale) qui :
1. Lit les contacts depuis Notion
2. Filtre les contacts avec statut "À contacter"
3. Génère un email personnalisé avec OpenRouter/DeepSeek
4. Envoie l'email via Gmail
5. Met à jour le statut du contact dans Notion

## Structure attendue

Suivre le pattern standard :
Trigger -> Read -> Filter -> Act -> Update

## Spécifications techniques

- Utiliser le nœud Notion pour lire et mettre à jour les contacts
- Utiliser le nœud HTTP Request pour appeler OpenRouter/DeepSeek
- Utiliser le nœud Gmail pour envoyer les emails
- Implémenter une gestion d'erreur robuste

## Format de sortie

- Code JSON du workflow n8n
- Documentation des nœuds et de leur configuration
- Instructions pour le déploiement
```plaintext
### 4.2 Prompt pour analyser un bug dans un script PowerShell

```plaintext
# Analyse de bug dans le script d'analyse de complexité

## Problème

Le script PowerShellComplexityValidator.psm1 échoue avec l'erreur :
"Cannot index into a null array at line 156"

## Contexte

- Fichier : @development/scripts/validation/PowerShellComplexityValidator.psm1
- Fonction : Get-CyclomaticComplexity
- Ligne 156 : $result = $complexityScores[$functionName]

## Code environnant

```powershell
function Get-CyclomaticComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $ast = Get-PowerShellFileAst -FilePath $FilePath
    $functions = Get-PowerShellFunctions -Ast $ast
    $complexityScores = @{}
    
    foreach ($function in $functions) {
        $functionName = $function.Name
        $score = Get-CyclomaticComplexityScore -FunctionAst $function
        $complexityScores[$functionName] = $score
    }
    
    # Ligne 156

    $result = $complexityScores[$functionName]
    return $result
}
```plaintext
## Comportement attendu

Le script devrait calculer et retourner le score de complexité cyclomatique pour chaque fonction.

## Analyse et correction demandées

Identifiez la cause du bug et proposez une correction.
```plaintext
### 4.3 Prompt pour la conception d'une intégration MCP-n8n

```plaintext
# Conception de l'intégration MCP-n8n

## Objectif

Concevoir l'architecture d'intégration entre MCP (Model Context Protocol) et n8n pour la personnalisation des emails.

## Contexte

- MCP fournit du contexte aux modèles IA (OpenRouter/DeepSeek)
- n8n est utilisé pour l'automatisation des workflows d'emails
- Les emails doivent être personnalisés en fonction des données de contact

## Questions de conception

1. Comment n8n doit-il appeler MCP ?
2. Quel format de données pour l'échange entre n8n et MCP ?
3. Comment gérer l'authentification et la sécurité ?
4. Comment optimiser les performances et la latence ?

## Format de sortie attendu

- Diagramme d'architecture de l'intégration
- Description des interfaces et des flux de données
- Recommandations pour l'implémentation
- Considérations de sécurité et de performance
```plaintext
## 5. Bonnes pratiques spécifiques à EMAIL SENDER 1

### 5.1 Référencement des composants du projet

Toujours référencer précisément les composants du projet :

- **Workflows n8n** : "Email Sender - Phase 1", "Email Sender - Config"
- **Sources de données** : "Notion LOT1 DB", "Google Calendar BOOKING1"
- **Services IA** : "OpenRouter avec modèle DeepSeek", "MCP filesystem"

### 5.2 Utilisation des modes opérationnels

Spécifier explicitement le mode opérationnel dans vos prompts :

```plaintext
# Mode: GRAN

# Tâche: Décomposer la fonctionnalité d'analyse des réponses

...

# Mode: DEV-R

# Tâche: Implémenter le module d'analyse de sentiment

...
```plaintext
### 5.3 Intégration avec les Memories

Optimiser l'utilisation des Memories :

- **Référencer les Memories pertinentes** : "Utiliser les informations des Memories sur l'architecture n8n"
- **Indiquer les mises à jour** : "Mettre à jour les Memories avec cette nouvelle architecture"
- **Prioriser l'information** : "Conserver dans les Memories uniquement les décisions architecturales clés"

## 6. Ressources additionnelles

- [Guide des modes opérationnels Augment](/projet/guides/methodologies/modes-operationnels-augment.md)
- [Décisions architecturales pour EMAIL SENDER 1](/projet/guides/architecture/decisions-architecturales.md)
- [Bonnes pratiques n8n](/projet/guides/n8n/bonnes-pratiques-n8n.md)
- [Documentation officielle n8n](https://docs.n8n.io/)

---

> **Conseil** : Commencez par des prompts simples et itérez progressivement. La qualité des prompts s'améliore avec la pratique et l'expérience.
