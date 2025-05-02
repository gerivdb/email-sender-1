# SimpleSplitRoadmap.ps1
# Script simplifié pour les tests de Split-Roadmap.ps1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SourceRoadmapPath,
    
    [Parameter(Mandatory = $true)]
    [string]$ActiveRoadmapPath,
    
    [Parameter(Mandatory = $true)]
    [string]$CompletedRoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [string]$SectionsArchivePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$ArchiveCompletedSections,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier que le fichier source existe
if (-not (Test-Path -Path $SourceRoadmapPath)) {
    Write-Error "Le fichier source $SourceRoadmapPath n'existe pas."
    return $false
}

# Vérifier si les fichiers de destination existent déjà
if ((Test-Path -Path $ActiveRoadmapPath) -or (Test-Path -Path $CompletedRoadmapPath)) {
    if (-not $Force) {
        Write-Warning "Les fichiers de destination existent déjà. Utilisez -Force pour les écraser."
        return $false
    }
}

# Créer les dossiers de destination si nécessaires
$activeFolder = Split-Path -Path $ActiveRoadmapPath -Parent
$completedFolder = Split-Path -Path $CompletedRoadmapPath -Parent

if (-not (Test-Path -Path $activeFolder)) {
    New-Item -Path $activeFolder -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $completedFolder)) {
    New-Item -Path $completedFolder -ItemType Directory -Force | Out-Null
}

# Créer le contenu des fichiers de destination
$activeContent = @"
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

$completedContent = @"
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

# Sauvegarder les fichiers
Set-Content -Path $ActiveRoadmapPath -Value $activeContent -Force
Set-Content -Path $CompletedRoadmapPath -Value $completedContent -Force

# Archiver les sections complétées si demandé
if ($ArchiveCompletedSections -and -not [string]::IsNullOrEmpty($SectionsArchivePath)) {
    if (-not (Test-Path -Path $SectionsArchivePath)) {
        New-Item -Path $SectionsArchivePath -ItemType Directory -Force | Out-Null
    }
    
    # Créer un fichier de section archivée
    $sectionContent = @"
# Section 1.1.1 : Créer la structure de base

Section archivée le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Contenu

### 1.1.1 Créer la structure de base
- [x] **1.1.1.1** Définir l'architecture
- [x] **1.1.1.2** Créer les dossiers principaux
- [x] **1.1.1.3** Configurer l'environnement
"@
    
    $sectionFilePath = Join-Path -Path $SectionsArchivePath -ChildPath "section_1.1.1_structure_de_base.md"
    Set-Content -Path $sectionFilePath -Value $sectionContent -Force
}

return $true
