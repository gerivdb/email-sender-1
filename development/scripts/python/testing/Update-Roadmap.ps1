#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour la roadmap avec l'implÃ©mentation de TestOmnibus.
.DESCRIPTION
    Ce script met Ã  jour la roadmap du projet avec l'implÃ©mentation de TestOmnibus.
.PARAMETER RoadmapPath
    Le chemin du fichier roadmap Ã  mettre Ã  jour.
.EXAMPLE
    .\Update-Roadmap.ps1 -RoadmapPath "Roadmap\roadmap_perso_fixed.md"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath
)

# VÃ©rifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $RoadmapPath"
    return 1
}

# Lire le contenu du fichier roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# CrÃ©er l'entrÃ©e pour TestOmnibus
$today = Get-Date -Format "dd/MM/yyyy"
$testOmnibusEntry = @"

## 2.4 ImplÃ©mentation de TestOmnibus pour l'analyse des tests Python
**ComplexitÃ©**: Moyenne
**Temps estimÃ©**: 3-5 jours
**Progression**: 100% - *TerminÃ© le $today*
**Date de dÃ©but**: $today
**Date d'achÃ¨vement**: $today

### 2.4.1 DÃ©veloppement du script principal
- [x] CrÃ©er le script Python run_testomnibus.py
- [x] ImplÃ©menter l'exÃ©cution parallÃ¨le des tests
- [x] DÃ©velopper l'analyse des erreurs
- [x] CrÃ©er la gÃ©nÃ©ration de rapports HTML

### 2.4.2 DÃ©veloppement du wrapper PowerShell
- [x] CrÃ©er le script Invoke-TestOmnibus.ps1
- [x] ImplÃ©menter la vÃ©rification des dÃ©pendances
- [x] DÃ©velopper l'interface utilisateur
- [x] CrÃ©er les options avancÃ©es

### 2.4.3 IntÃ©gration avec le systÃ¨me d'apprentissage des erreurs
- [x] CrÃ©er le script Integrate-ErrorLearning.ps1
- [x] ImplÃ©menter la sauvegarde des erreurs
- [x] DÃ©velopper l'analyse des patterns d'erreur
- [x] CrÃ©er les suggestions de correction

### 2.4.4 Documentation et exemples
- [x] CrÃ©er le fichier README.md
- [x] Documenter les options disponibles
- [x] CrÃ©er des exemples d'utilisation
- [x] Documenter l'intÃ©gration avec CI/CD
"@

# Ajouter l'entrÃ©e Ã  la roadmap
$sectionToFind = "# 2. TÃ‚CHES DE PRIORITÃ‰ MOYENNE"
$updatedRoadmapContent = $roadmapContent -replace "($sectionToFind)", "`$1$testOmnibusEntry"

# Ã‰crire le contenu mis Ã  jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedRoadmapContent

Write-Host "Roadmap mise Ã  jour avec succÃ¨s." -ForegroundColor Green
return 0
