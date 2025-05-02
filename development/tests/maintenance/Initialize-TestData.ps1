# Initialize-TestData.ps1
# Script pour initialiser les données de test pour les tests unitaires

[CmdletBinding()]
param (
  [Parameter(Mandatory = $false)]
  [string]$TestDataPath = $null,

  [Parameter(Mandatory = $false)]
  [string]$OutputPath = $null,

  [Parameter(Mandatory = $false)]
  [string]$SectionsPath = $null,

  [Parameter(Mandatory = $false)]
  [switch]$Force
)

# Définir les chemins par défaut si non spécifiés
if ([string]::IsNullOrEmpty($TestDataPath)) {
  $TestDataPath = Join-Path -Path $PSScriptRoot -ChildPath "testdata"
}

if ([string]::IsNullOrEmpty($OutputPath)) {
  $OutputPath = Join-Path -Path $TestDataPath -ChildPath "output"
}

if ([string]::IsNullOrEmpty($SectionsPath)) {
  $SectionsPath = Join-Path -Path $OutputPath -ChildPath "sections"
}

# Créer les dossiers nécessaires
if (-not (Test-Path -Path $TestDataPath)) {
  New-Item -Path $TestDataPath -ItemType Directory -Force | Out-Null
  Write-Host "Dossier créé: $TestDataPath"
}

if (-not (Test-Path -Path $OutputPath)) {
  New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
  Write-Host "Dossier créé: $OutputPath"
}

if (-not (Test-Path -Path $SectionsPath)) {
  New-Item -Path $SectionsPath -ItemType Directory -Force | Out-Null
  Write-Host "Dossier créé: $SectionsPath"
}

# Créer le fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $TestDataPath -ChildPath "test_roadmap.md"
$testRoadmapContent = @"
# Roadmap de test - EMAIL_SENDER_1

Ce fichier est utilisé pour les tests unitaires du système de gestion de roadmap.

## Phase 1: Fonctionnalités de base

### 1.1 Implémentation des composants essentiels
- [x] **1.1.1** Créer la structure de base
  - [x] **1.1.1.1** Définir l'architecture
  - [x] **1.1.1.2** Créer les dossiers principaux
  - [x] **1.1.1.3** Configurer l'environnement
- [ ] **1.1.2** Développer les fonctionnalités principales
  - [x] **1.1.2.1** Implémenter la gestion des utilisateurs
  - [ ] **1.1.2.2** Développer le système de notifications
  - [ ] **1.1.2.3** Créer l'interface utilisateur

### 1.2 Tests et validation
- [x] **1.2.1** Créer les tests unitaires
  - [x] **1.2.1.1** Tests des composants de base
  - [x] **1.2.1.2** Tests des fonctionnalités principales
- [ ] **1.2.2** Effectuer les tests d'intégration
  - [ ] **1.2.2.1** Tests de bout en bout
  - [ ] **1.2.2.2** Tests de performance

## Phase 2: Fonctionnalités avancées

### 2.1 Développement des modules avancés
- [ ] **2.1.1** Implémenter l'analyse de données
  - [ ] **2.1.1.1** Créer le module de collecte
  - [ ] **2.1.1.2** Développer les algorithmes d'analyse
- [ ] **2.1.2** Intégrer l'intelligence artificielle
  - [ ] **2.1.2.1** Rechercher les modèles appropriés
  - [ ] **2.1.2.2** Implémenter les modèles sélectionnés

### 2.2 Optimisation et déploiement
- [ ] **2.2.1** Optimiser les performances
  - [ ] **2.2.1.1** Analyser les goulots d'étranglement
  - [ ] **2.2.1.2** Implémenter les optimisations
- [ ] **2.2.2** Préparer le déploiement
  - [ ] **2.2.2.1** Configurer l'environnement de production
  - [ ] **2.2.2.2** Créer les scripts de déploiement
"@

Set-Content -Path $testRoadmapPath -Value $testRoadmapContent -Force
Write-Host "Fichier de roadmap de test créé: $testRoadmapPath"

# Créer le fichier de roadmap active de test
$testActiveRoadmapPath = Join-Path -Path $OutputPath -ChildPath "roadmap_active.md"
$testActiveRoadmapContent = @"
# Roadmap Active - EMAIL_SENDER_1

Ce fichier contient les tâches actives et à venir de la roadmap.
Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: Fonctionnalités de base

### 1.1 Implémentation des composants essentiels
- [ ] **1.1.2** Développer les fonctionnalités principales
  - [x] **1.1.2.1** Implémenter la gestion des utilisateurs
  - [ ] **1.1.2.2** Développer le système de notifications
  - [ ] **1.1.2.3** Créer l'interface utilisateur

### 1.2 Tests et validation
- [ ] **1.2.2** Effectuer les tests d'intégration
  - [ ] **1.2.2.1** Tests de bout en bout
  - [ ] **1.2.2.2** Tests de performance

## Phase 2: Fonctionnalités avancées

### 2.1 Développement des modules avancés
- [ ] **2.1.1** Implémenter l'analyse de données
  - [ ] **2.1.1.1** Créer le module de collecte
  - [ ] **2.1.1.2** Développer les algorithmes d'analyse
"@

Set-Content -Path $testActiveRoadmapPath -Value $testActiveRoadmapContent -Force
Write-Host "Fichier de roadmap active de test créé: $testActiveRoadmapPath"

# Créer le fichier de roadmap complétée de test
$testCompletedRoadmapPath = Join-Path -Path $OutputPath -ChildPath "roadmap_completed.md"
$testCompletedRoadmapContent = @"
# Roadmap Complétée - EMAIL_SENDER_1

Ce fichier contient les tâches complétées de la roadmap.
Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: Fonctionnalités de base

### 1.1 Implémentation des composants essentiels
- [x] **1.1.1** Créer la structure de base
  - [x] **1.1.1.1** Définir l'architecture
  - [x] **1.1.1.2** Créer les dossiers principaux
  - [x] **1.1.1.3** Configurer l'environnement

### 1.2 Tests et validation
- [x] **1.2.1** Créer les tests unitaires
  - [x] **1.2.1.1** Tests des composants de base
  - [x] **1.2.1.2** Tests des fonctionnalités principales
"@

Set-Content -Path $testCompletedRoadmapPath -Value $testCompletedRoadmapContent -Force
Write-Host "Fichier de roadmap complétée de test créé: $testCompletedRoadmapPath"

# Créer un fichier de section archivée
$testSectionPath = Join-Path -Path $SectionsPath -ChildPath "section_1.1.1_Créer_la_structure_de_base.md"
$testSectionContent = @"
# Section 1.1.1 : Créer la structure de base

Section archivée le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Contenu

### 1.1.1 Créer la structure de base
- [x] **1.1.1.1** Définir l'architecture
- [x] **1.1.1.2** Créer les dossiers principaux
- [x] **1.1.1.3** Configurer l'environnement
"@

Set-Content -Path $testSectionPath -Value $testSectionContent -Force
Write-Host "Fichier de section archivée de test créé: $testSectionPath"

Write-Host "Initialisation des données de test terminée avec succès."
