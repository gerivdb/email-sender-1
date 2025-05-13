# Product Requirements Document: Module de Prédiction par Régression Linéaire
*Version 1.0 - 2025-05-13*

## 1. Introduction

### 1.1 Objectif
Ce document définit les exigences pour le développement d'un module PowerShell de prédiction par régression linéaire, destiné à être intégré au système de monitoring EMAIL_SENDER_1. Ce module permettra de prédire les valeurs futures des métriques système à partir des données historiques, facilitant ainsi la planification des ressources et l'anticipation des problèmes potentiels.

### 1.2 Portée
Le module de prédiction par régression linéaire fait partie du système de prédiction de charge global, qui vise à optimiser l'utilisation des ressources système. Ce PRD couvre spécifiquement le module de régression linéaire simple, qui constitue la première étape du système de prédiction.

### 1.3 Définitions
- **Régression linéaire** : Technique statistique qui modélise la relation entre une variable dépendante et une ou plusieurs variables indépendantes par une équation linéaire.
- **R²** : Coefficient de détermination, mesure de la qualité d'un modèle de régression.
- **RMSE** : Root Mean Square Error, mesure de l'erreur moyenne du modèle.
- **MAE** : Mean Absolute Error, mesure de l'erreur absolue moyenne du modèle.
- **Intervalle de confiance** : Plage de valeurs qui a une probabilité spécifiée de contenir la valeur réelle.

## 2. User Stories / Cas d'utilisation

### 2.1 User Stories

1. **En tant qu'**administrateur système, **je veux** prédire l'utilisation future du CPU **afin de** planifier les ressources nécessaires.
   
2. **En tant qu'**analyste de performance, **je veux** visualiser les tendances futures des métriques système **afin d'**identifier les potentiels goulots d'étranglement.
   
3. **En tant que**développeur d'automatisation, **je veux** intégrer des prédictions dans mes scripts **afin de** créer des alertes proactives.

### 2.2 Cas d'utilisation

1. **UC1: Prédiction de l'utilisation du CPU**
   - L'administrateur extrait les données historiques d'utilisation du CPU
   - Le système crée un modèle de régression linéaire à partir de ces données
   - L'administrateur demande une prédiction pour les 24 prochaines heures
   - Le système fournit les valeurs prédites avec des intervalles de confiance

2. **UC2: Analyse de tendance de la mémoire**
   - L'analyste extrait les données historiques d'utilisation de la mémoire
   - Le système détecte un pattern cyclique dans les données
   - L'analyste demande une prédiction tenant compte de ce pattern
   - Le système fournit une prédiction avec visualisation de la tendance

3. **UC3: Intégration dans un script d'alerte**
   - Le développeur crée un script qui collecte des métriques en temps réel
   - Le script utilise le module pour prédire les valeurs futures
   - Si la prédiction dépasse un seuil critique, une alerte est générée
   - L'alerte inclut la valeur prédite et la probabilité de dépassement

## 3. Spécifications fonctionnelles

### 3.1 Création de modèles de régression

Le module doit permettre de créer des modèles de régression linéaire simple à partir de données historiques:

- **Entrée**: Séries de valeurs X (indépendantes) et Y (dépendantes)
- **Traitement**: Calcul des coefficients par la méthode des moindres carrés
- **Sortie**: Modèle de régression avec coefficients et métriques de qualité

### 3.2 Prédiction de valeurs futures

Le module doit permettre de prédire des valeurs futures à partir d'un modèle existant:

- **Entrée**: Modèle de régression et valeurs X pour lesquelles prédire
- **Traitement**: Application de l'équation de régression et calcul des intervalles de confiance
- **Sortie**: Valeurs prédites avec intervalles de confiance

### 3.3 Évaluation de la qualité des modèles

Le module doit fournir des métriques pour évaluer la qualité des modèles:

- Coefficient de détermination (R²)
- Root Mean Square Error (RMSE)
- Mean Absolute Error (MAE)

### 3.4 Gestion des modèles

Le module doit permettre de gérer plusieurs modèles:

- Création de modèles avec noms personnalisés
- Récupération de modèles par nom
- Listing des modèles disponibles

## 4. Spécifications techniques

### 4.1 Architecture

Le module sera implémenté sous forme d'un module PowerShell standard:

```
SimpleLinearRegression.psm1
├── Variables globales
│   └── $script:Models (hashtable)
├── Fonctions publiques
│   ├── New-SimpleLinearModel
│   ├── Invoke-SimpleLinearPrediction
│   └── Get-SimpleLinearModel
└── Fonctions privées
    ├── Invoke-LeastSquaresRegression
    └── Calculate-ConfidenceInterval
```

### 4.2 Interfaces

#### 4.2.1 New-SimpleLinearModel

```powershell
function New-SimpleLinearModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$XValues,
        
        [Parameter(Mandatory = $true)]
        [double[]]$YValues,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = ""
    )
    
    # Retourne le nom du modèle créé
}
```

#### 4.2.2 Invoke-SimpleLinearPrediction

```powershell
function Invoke-SimpleLinearPrediction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelName,
        
        [Parameter(Mandatory = $true)]
        [double[]]$XValues,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$ConfidenceLevel = 0.95
    )
    
    # Retourne un hashtable avec les prédictions
}
```

#### 4.2.3 Get-SimpleLinearModel

```powershell
function Get-SimpleLinearModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelName
    )
    
    # Retourne le modèle demandé
}
```

### 4.3 Contraintes techniques

- Compatible PowerShell 5.1 et versions ultérieures
- Pas de dépendances externes
- Performance: création de modèle < 100ms pour 1000 points
- Mémoire: < 10MB par modèle pour 1000 points

### 4.4 Intégration

Le module doit s'intégrer avec:
- Module TrendAnalyzer existant
- Système de monitoring global
- Scripts d'automatisation

## 5. Critères d'acceptation

### 5.1 Tests fonctionnels

1. **Création de modèle**
   - Avec données parfaitement linéaires: R² = 1.0 ± 0.001
   - Avec données bruitées: R² > 0.8
   - Avec données aléatoires: R² proche de 0

2. **Prédiction**
   - Prédiction dans la plage des données: erreur < 5%
   - Prédiction hors plage (extrapolation): intervalles de confiance corrects
   - Prédiction avec modèle inexistant: erreur appropriée

3. **Robustesse**
   - Gestion des entrées invalides
   - Gestion des cas limites (division par zéro, etc.)
   - Gestion des erreurs avec messages explicites

### 5.2 Tests de performance

- Création de modèle avec 1000 points: < 100ms
- Prédiction pour 100 points: < 10ms
- Utilisation mémoire: < 10MB par modèle

### 5.3 Documentation

- Commentaires de fonction complets (Synopsis, Description, Paramètres, Exemples)
- Exemples d'utilisation pour chaque fonction
- Guide d'intégration avec d'autres modules

## 6. Dépendances et intégrations

### 6.1 Dépendances

- Module TrendAnalyzer (pour l'extraction des données historiques)
- PowerShell 5.1+ (pour l'exécution)

### 6.2 Intégrations

- Système de monitoring (pour l'accès aux données)
- Scripts d'automatisation (pour l'utilisation des prédictions)
- Tableau de bord de visualisation (pour l'affichage des prédictions)

## 7. Livrables

1. Module PowerShell `SimpleLinearRegression.psm1`
2. Script de test `Test-SimpleLinearRegression.ps1`
3. Documentation et exemples d'utilisation

## 8. Calendrier

- Phase 1: Implémentation du module de base (2 jours)
- Phase 2: Tests et optimisation (1 jour)
- Phase 3: Documentation et intégration (1 jour)

## 9. Approbation

| Rôle | Nom | Date | Signature |
|------|-----|------|-----------|
| Product Owner | | | |
| Lead Developer | | | |
| QA Lead | | | |
