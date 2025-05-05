# Initialize-TestData.ps1
# Script pour initialiser les donnÃ©es de test pour les tests unitaires

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

# DÃ©finir les chemins par dÃ©faut si non spÃ©cifiÃ©s
if ([string]::IsNullOrEmpty($TestDataPath)) {
  $TestDataPath = Join-Path -Path $PSScriptRoot -ChildPath "testdata"
}

if ([string]::IsNullOrEmpty($OutputPath)) {
  $OutputPath = Join-Path -Path $TestDataPath -ChildPath "output"
}

if ([string]::IsNullOrEmpty($SectionsPath)) {
  $SectionsPath = Join-Path -Path $OutputPath -ChildPath "sections"
}

# CrÃ©er les dossiers nÃ©cessaires
if (-not (Test-Path -Path $TestDataPath)) {
  New-Item -Path $TestDataPath -ItemType Directory -Force | Out-Null
  Write-Host "Dossier crÃ©Ã©: $TestDataPath"
}

if (-not (Test-Path -Path $OutputPath)) {
  New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
  Write-Host "Dossier crÃ©Ã©: $OutputPath"
}

if (-not (Test-Path -Path $SectionsPath)) {
  New-Item -Path $SectionsPath -ItemType Directory -Force | Out-Null
  Write-Host "Dossier crÃ©Ã©: $SectionsPath"
}

# CrÃ©er le fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $TestDataPath -ChildPath "test_roadmap.md"
$testRoadmapContent = @"
# Roadmap de test - EMAIL_SENDER_1

Ce fichier est utilisÃ© pour les tests unitaires du systÃ¨me de gestion de roadmap.

## Phase 1: FonctionnalitÃ©s de base

### 1.1 ImplÃ©mentation des composants essentiels
- [x] **1.1.1** CrÃ©er la structure de base
  - [x] **1.1.1.1** DÃ©finir l'architecture
  - [x] **1.1.1.2** CrÃ©er les dossiers principaux
  - [x] **1.1.1.3** Configurer l'environnement
- [ ] **1.1.2** DÃ©velopper les fonctionnalitÃ©s principales
  - [x] **1.1.2.1** ImplÃ©menter la gestion des utilisateurs
  - [ ] **1.1.2.2** DÃ©velopper le systÃ¨me de notifications
  - [ ] **1.1.2.3** CrÃ©er l'interface utilisateur

### 1.2 Tests et validation
- [x] **1.2.1** CrÃ©er les tests unitaires
  - [x] **1.2.1.1** Tests des composants de base
  - [x] **1.2.1.2** Tests des fonctionnalitÃ©s principales
- [ ] **1.2.2** Effectuer les tests d'intÃ©gration
  - [ ] **1.2.2.1** Tests de bout en bout
  - [ ] **1.2.2.2** Tests de performance

## Phase 2: FonctionnalitÃ©s avancÃ©es

### 2.1 DÃ©veloppement des modules avancÃ©s
- [ ] **2.1.1** ImplÃ©menter l'analyse de donnÃ©es
  - [ ] **2.1.1.1** CrÃ©er le module de collecte
  - [ ] **2.1.1.2** DÃ©velopper les algorithmes d'analyse
- [ ] **2.1.2** IntÃ©grer l'intelligence artificielle
  - [ ] **2.1.2.1** Rechercher les modÃ¨les appropriÃ©s
  - [ ] **2.1.2.2** ImplÃ©menter les modÃ¨les sÃ©lectionnÃ©s

### 2.2 Optimisation et dÃ©ploiement
- [ ] **2.2.1** Optimiser les performances
  - [ ] **2.2.1.1** Analyser les goulots d'Ã©tranglement
  - [ ] **2.2.1.2** ImplÃ©menter les optimisations
- [ ] **2.2.2** PrÃ©parer le dÃ©ploiement
  - [ ] **2.2.2.1** Configurer l'environnement de production
  - [ ] **2.2.2.2** CrÃ©er les scripts de dÃ©ploiement
"@

Set-Content -Path $testRoadmapPath -Value $testRoadmapContent -Force
Write-Host "Fichier de roadmap de test crÃ©Ã©: $testRoadmapPath"

# CrÃ©er le fichier de roadmap active de test
$testActiveRoadmapPath = Join-Path -Path $OutputPath -ChildPath "roadmap_active.md"
$testActiveRoadmapContent = @"
# Roadmap Active - EMAIL_SENDER_1

Ce fichier contient les tÃ¢ches actives et Ã  venir de la roadmap.
GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: FonctionnalitÃ©s de base

### 1.1 ImplÃ©mentation des composants essentiels
- [ ] **1.1.2** DÃ©velopper les fonctionnalitÃ©s principales
  - [x] **1.1.2.1** ImplÃ©menter la gestion des utilisateurs
  - [ ] **1.1.2.2** DÃ©velopper le systÃ¨me de notifications
  - [ ] **1.1.2.3** CrÃ©er l'interface utilisateur

### 1.2 Tests et validation
- [ ] **1.2.2** Effectuer les tests d'intÃ©gration
  - [ ] **1.2.2.1** Tests de bout en bout
  - [ ] **1.2.2.2** Tests de performance

## Phase 2: FonctionnalitÃ©s avancÃ©es

### 2.1 DÃ©veloppement des modules avancÃ©s
- [ ] **2.1.1** ImplÃ©menter l'analyse de donnÃ©es
  - [ ] **2.1.1.1** CrÃ©er le module de collecte
  - [ ] **2.1.1.2** DÃ©velopper les algorithmes d'analyse
"@

Set-Content -Path $testActiveRoadmapPath -Value $testActiveRoadmapContent -Force
Write-Host "Fichier de roadmap active de test crÃ©Ã©: $testActiveRoadmapPath"

# CrÃ©er le fichier de roadmap complÃ©tÃ©e de test
$testCompletedRoadmapPath = Join-Path -Path $OutputPath -ChildPath "roadmap_completed.md"
$testCompletedRoadmapContent = @"
# Roadmap ComplÃ©tÃ©e - EMAIL_SENDER_1

Ce fichier contient les tÃ¢ches complÃ©tÃ©es de la roadmap.
GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Phase 1: FonctionnalitÃ©s de base

### 1.1 ImplÃ©mentation des composants essentiels
- [x] **1.1.1** CrÃ©er la structure de base
  - [x] **1.1.1.1** DÃ©finir l'architecture
  - [x] **1.1.1.2** CrÃ©er les dossiers principaux
  - [x] **1.1.1.3** Configurer l'environnement

### 1.2 Tests et validation
- [x] **1.2.1** CrÃ©er les tests unitaires
  - [x] **1.2.1.1** Tests des composants de base
  - [x] **1.2.1.2** Tests des fonctionnalitÃ©s principales
"@

Set-Content -Path $testCompletedRoadmapPath -Value $testCompletedRoadmapContent -Force
Write-Host "Fichier de roadmap complÃ©tÃ©e de test crÃ©Ã©: $testCompletedRoadmapPath"

# CrÃ©er un fichier de section archivÃ©e
$testSectionPath = Join-Path -Path $SectionsPath -ChildPath "section_1.1.1_CrÃ©er_la_structure_de_base.md"
$testSectionContent = @"
# Section 1.1.1 : CrÃ©er la structure de base

Section archivÃ©e le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Contenu

### 1.1.1 CrÃ©er la structure de base
- [x] **1.1.1.1** DÃ©finir l'architecture
- [x] **1.1.1.2** CrÃ©er les dossiers principaux
- [x] **1.1.1.3** Configurer l'environnement
"@

Set-Content -Path $testSectionPath -Value $testSectionContent -Force
Write-Host "Fichier de section archivÃ©e de test crÃ©Ã©: $testSectionPath"

Write-Host "Initialisation des donnÃ©es de test terminÃ©e avec succÃ¨s."
