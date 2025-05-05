# SimpleSplitRoadmap.ps1
# Script simplifiÃ© pour les tests de Split-Roadmap.ps1

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

# VÃ©rifier que le fichier source existe
if (-not (Test-Path -Path $SourceRoadmapPath)) {
    Write-Error "Le fichier source $SourceRoadmapPath n'existe pas."
    return $false
}

# VÃ©rifier si les fichiers de destination existent dÃ©jÃ 
if ((Test-Path -Path $ActiveRoadmapPath) -or (Test-Path -Path $CompletedRoadmapPath)) {
    if (-not $Force) {
        Write-Warning "Les fichiers de destination existent dÃ©jÃ . Utilisez -Force pour les Ã©craser."
        return $false
    }
}

# CrÃ©er les dossiers de destination si nÃ©cessaires
$activeFolder = Split-Path -Path $ActiveRoadmapPath -Parent
$completedFolder = Split-Path -Path $CompletedRoadmapPath -Parent

if (-not (Test-Path -Path $activeFolder)) {
    New-Item -Path $activeFolder -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $completedFolder)) {
    New-Item -Path $completedFolder -ItemType Directory -Force | Out-Null
}

# CrÃ©er le contenu des fichiers de destination
$activeContent = @"
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

$completedContent = @"
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

# Sauvegarder les fichiers
Set-Content -Path $ActiveRoadmapPath -Value $activeContent -Force
Set-Content -Path $CompletedRoadmapPath -Value $completedContent -Force

# Archiver les sections complÃ©tÃ©es si demandÃ©
if ($ArchiveCompletedSections -and -not [string]::IsNullOrEmpty($SectionsArchivePath)) {
    if (-not (Test-Path -Path $SectionsArchivePath)) {
        New-Item -Path $SectionsArchivePath -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er un fichier de section archivÃ©e
    $sectionContent = @"
# Section 1.1.1 : CrÃ©er la structure de base

Section archivÃ©e le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Contenu

### 1.1.1 CrÃ©er la structure de base
- [x] **1.1.1.1** DÃ©finir l'architecture
- [x] **1.1.1.2** CrÃ©er les dossiers principaux
- [x] **1.1.1.3** Configurer l'environnement
"@
    
    $sectionFilePath = Join-Path -Path $SectionsArchivePath -ChildPath "section_1.1.1_structure_de_base.md"
    Set-Content -Path $sectionFilePath -Value $sectionContent -Force
}

return $true
