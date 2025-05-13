# Guidelines d'implémentation optimale avec Augment/Claude
*Version 1.1 - 2025-05-14*

Ce document définit les meilleures pratiques pour l'implémentation de code avec Augment/Claude, basées sur l'analyse des sessions précédentes et l'optimisation des workflows. Ces guidelines s'inspirent des meilleures pratiques professionnelles de développement assisté par IA.

## 1. Granularité optimale

### 1.1 Taille des modules
- **Optimal**: 100-200 lignes de code par module
- **Maximum**: 300 lignes avant de considérer une division
- **Fonctions**: 30-50 lignes maximum par fonction

### 1.2 Découpage des tâches
- **Unité atomique**: Une fonctionnalité cohérente et testable indépendamment
- **Exemple optimal**: Un module avec 3-5 fonctions liées (ex: SimpleLinearRegression.psm1)
- **À éviter**: Implémentation de systèmes entiers ou de modules fortement interdépendants en une seule fois

### 1.3 Séquence d'implémentation
```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   DEVR  │ -> │  DEBUG  │ -> │  TEST   │ -> │   MAJ   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

1. **DEVR**: Implémentation minimale fonctionnelle
2. **DEBUG**: Correction des erreurs et vérification du fonctionnement
3. **TEST**: Tests unitaires et validation
4. **MAJ**: Mise à jour de la roadmap et documentation

## 2. Structure de code

### 2.1 Organisation des modules PowerShell
```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Description courte du module (1 ligne)
.DESCRIPTION
    Description détaillée du module (2-5 lignes)
.NOTES
    Nom: ModuleName.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: YYYY-MM-DD
#>

# Variables globales (limitées au strict nécessaire)
$script:SharedState = @{}

# Fonctions d'accès aux variables globales
function Get-SharedState { ... }
function Set-SharedState { ... }

# Fonctions principales (avec documentation complète)
function New-Something {
    [CmdletBinding()]
    param ( ... )

    begin { ... }
    process { ... }
    end { ... }
}

# Fonctions internes/privées
function private:Invoke-InternalOperation { ... }

# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function New-Something, Get-SharedState
```

### 2.2 Tests unitaires
```powershell
# Structure recommandée pour les tests
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestScript
    )

    Write-Host "`n========== TEST: $TestName ==========" -ForegroundColor Cyan

    try {
        $result = & $TestScript

        if ($result) {
            Write-Host "TEST RÉUSSI: $TestName" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "TEST ÉCHOUÉ: $TestName" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "TEST ÉCHOUÉ: $TestName - $_" -ForegroundColor Red
        return $false
    }
}

# Exemple d'utilisation
$test1 = Invoke-Test -TestName "Nom du test" -TestScript {
    # Arrange
    $input = ...

    # Act
    $result = ...

    # Assert
    if ($result -eq $expected) {
        return $true
    }
    return $false
}
```

## 3. Spécificités PowerShell à respecter

### 3.1 Tableaux multidimensionnels
```powershell
# CORRECT - Utiliser GetValue/SetValue
$matrix = New-Object 'double[,]' $rows, $cols
$matrix.SetValue($value, $i, $j)
$value = $matrix.GetValue($i, $j)

# INCORRECT - Éviter cette syntaxe
$value = $matrix[$i, $j]  # Peut causer des erreurs
```

### 3.2 Variables globales
```powershell
# CORRECT - Utiliser des fonctions d'accès
function Get-ModelByName {
    param([string]$Name)
    return $script:Models[$Name]
}

# INCORRECT - Accès direct depuis d'autres scripts
$model = $script:Models[$modelName]  # Peut être inaccessible
```

### 3.3 Gestion des erreurs
```powershell
# CORRECT - Gestion explicite des erreurs
try {
    # Code qui peut échouer
}
catch {
    Write-Error "Message explicite: $_"
    return $null  # Valeur de retour claire en cas d'échec
}

# CORRECT - Vérification des valeurs nulles
if ($null -eq $input) {
    Write-Warning "Input est null, utilisation de la valeur par défaut"
    $input = $defaultValue
}
```

## 4. Débogage efficace

### 4.1 Instructions de débogage
```powershell
# Ajouter des points de débogage stratégiques
Write-Verbose "Valeurs d'entrée: $($inputValues | ConvertTo-Json -Compress)"
Write-Verbose "Dimensions de la matrice: $($matrix.GetLength(0)) x $($matrix.GetLength(1))"

# Pour les tests, afficher des informations détaillées
Write-Host "  Valeur calculée: $([Math]::Round($result, 4))"
Write-Host "  Valeur attendue: $([Math]::Round($expected, 4))"
Write-Host "  Erreur: $([Math]::Round($error, 4))"
```

### 4.2 Tests dédiés
- Créer des tests spécifiques pour chaque fonctionnalité
- Utiliser des jeux de données synthétiques simples et prévisibles
- Tester les cas limites explicitement

## 5. Communication avec Augment/Claude

### 5.1 Instructions optimales
- **Trop vague**: "Implémenter les modèles prédictifs"
- **Optimal**: "Implémenter un modèle de régression linéaire simple avec les fonctions New-SimpleLinearModel et Invoke-SimpleLinearPrediction"
- **Trop détaillé**: Instructions ligne par ligne

### 5.2 Format de prompt recommandé
```
MODE: DEVR

TÂCHE: Implémenter [fonctionnalité spécifique]

CONTEXTE:
- Module: [nom du module]
- Dépendances: [modules/fonctions requis]
- Structures de données: [description des structures]

SPÉCIFICATIONS:
1. Créer la fonction [nom] avec les paramètres [liste]
2. Implémenter [algorithme/logique spécifique]
3. Gérer les cas d'erreur [liste des cas]
4. Retourner [format de sortie attendu]

TESTS:
- Vérifier [comportement attendu 1]
- Vérifier [comportement attendu 2]
```

## 6. Méthodologie de développement structurée

### 6.1 Approche PRD (Product Requirements Document)

Le développement efficace avec Augment commence par un PRD clair et structuré :

1. **Création du PRD** :
   - Rédiger les exigences initiales en langage naturel
   - Utiliser Augment pour générer un PRD structuré en Markdown
   - Stocker le PRD dans `/projet/guides/` ou `/docs/`

2. **Structure recommandée du PRD** :
   ```markdown
   # Product Requirements Document: [Nom du Projet/Module]

   ## 1. Introduction
   [Description générale du projet/module]

   ## 2. Objectifs
   [Liste des objectifs principaux]

   ## 3. User Stories / Cas d'utilisation
   [Description des scénarios d'utilisation]

   ## 4. Spécifications fonctionnelles
   [Détail des fonctionnalités requises]

   ## 5. Spécifications techniques
   [Contraintes techniques, dépendances, etc.]

   ## 6. Critères d'acceptation
   [Comment valider que les exigences sont satisfaites]
   ```

3. **Utilisation du PRD** :
   - Référencer le PRD dans les prompts via `@chemin/vers/prd.md`
   - Utiliser le PRD comme source de vérité pour la décomposition des tâches
   - Mettre à jour le PRD si les exigences évoluent

### 6.2 Système de gestion de tâches (Taskmaster)

Un système de gestion de tâches intégré à Augment via MCP améliore considérablement l'efficacité :

1. **Structure des tâches** :
   - Chaque tâche est un fichier Markdown dans `/projet/tasks/`
   - Format recommandé :
     ```markdown
     # Tâche: [ID]

     ## Titre
     [Titre descriptif]

     ## Statut
     [pending|in-progress|done]

     ## Dépendances
     [Liste des IDs de tâches dont celle-ci dépend]

     ## Priorité
     [high|medium|low]

     ## Description
     [Description détaillée]

     ## Stratégie de test
     [Comment tester cette fonctionnalité]
     ```

2. **Outils MCP pour la gestion des tâches** :
   - `parse_prd` : Décompose un PRD en tâches individuelles
   - `get_tasks` : Liste les tâches disponibles
   - `next_task` : Suggère la prochaine tâche à implémenter
   - `expand_task` : Décompose une tâche complexe en sous-tâches
   - `update_task_status` : Met à jour le statut d'une tâche

3. **Workflow de développement avec Taskmaster** :
   ```
   PRD → Décomposition en tâches → Sélection de la prochaine tâche →
   Implémentation → Test → Mise à jour du statut → Répéter
   ```

### 6.3 Approche itérative d'implémentation

Pour chaque tâche identifiée :

1. **Prototype minimal** - Implémenter la version la plus simple qui fonctionne
2. **Tests de base** - Vérifier le fonctionnement avec des cas simples
3. **Raffinement** - Ajouter les fonctionnalités secondaires
4. **Tests complets** - Vérifier tous les cas d'utilisation
5. **Documentation** - Finaliser la documentation et les exemples
6. **Intégration** - Intégrer avec les autres modules
7. **Mise à jour du statut** - Marquer la tâche comme terminée

## 7. Contextualisation efficace pour Augment

### 7.1 Référencement de fichiers

Plutôt que de copier-coller de grands blocs de code ou de documentation, référencer les fichiers pertinents :

```
@chemin/vers/prd.md Je souhaite implémenter la fonctionnalité X décrite dans ce PRD.
@chemin/vers/module.psm1 Comment puis-je étendre ce module pour ajouter la fonctionnalité Y?
```

### 7.2 Règles et memories Augment

Définir des règles claires pour guider Augment :

```
Règles de codage PowerShell:
1. Utiliser les verbes approuvés pour les noms de fonctions
2. Préférer $null -eq $variable à $variable -eq $null
3. Utiliser ShouldProcess pour les fonctions qui modifient l'état
4. Documenter toutes les fonctions avec le format de commentaires standard
5. Limiter la complexité cyclomatique à 10 maximum
```

Ces règles doivent être fournies systématiquement à Augment via le système de memories.

---

Ces guidelines sont évolutives et seront mises à jour en fonction des retours d'expérience et des nouveaux apprentissages.
