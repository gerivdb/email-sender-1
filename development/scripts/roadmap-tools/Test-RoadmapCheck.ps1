<#
.SYNOPSIS
    Script de test pour vÃ©rifier le fonctionnement du mode CHECK pour les roadmaps.

.DESCRIPTION
    Ce script crÃ©e un fichier de roadmap de test, exÃ©cute le script de mise Ã  jour de la roadmap,
    et vÃ©rifie que les tÃ¢ches sont correctement mises Ã  jour.

.PARAMETER TestDirectory
    RÃ©pertoire oÃ¹ crÃ©er les fichiers de test. Par dÃ©faut, utilise un sous-rÃ©pertoire "Tests" dans le rÃ©pertoire courant.

.EXAMPLE
    .\Test-RoadmapCheck.ps1

.NOTES
    Auteur: Roadmap Tools Team
    Version: 1.0
    Date de crÃ©ation: 2023-11-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDirectory = ".\Tests"
)

# CrÃ©er le rÃ©pertoire de test s'il n'existe pas
if (-not (Test-Path -Path $TestDirectory)) {
    New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de roadmap de test
function New-TestRoadmap {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $content = @"
# Roadmap de test

## Module AST Navigator

### Parcours de l'arbre syntaxique

#### Parcours en profondeur (DFS)

- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.1 Creer la structure de base de la fonction avec gestion de la profondeur maximale
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.2 Implementer la logique de parcours recursif des noeuds enfants
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.3 Ajouter des options de filtrage par type de noeud AST
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.4 Implementer la gestion des erreurs et des cas limites
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.5 Optimiser les performances pour les grands arbres syntaxiques

#### Parcours en largeur (BFS)

- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.2.1 Creer la structure de base de la fonction avec gestion de la profondeur maximale
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.2.2 Implementer la logique de parcours iteratif des noeuds enfants
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.2.3 Ajouter des options de filtrage par type de noeud AST
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.2.4 Implementer la gestion des erreurs et des cas limites
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.2.5 Optimiser les performances pour les grands arbres syntaxiques

### Recherche de noeuds specifiques

- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1 Creer une fonction pour rechercher des noeuds par type
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2 Creer une fonction pour rechercher des noeuds par predicat personnalise
- [ ] 2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3 Creer une fonction pour rechercher des noeuds par expression reguliere
"@

    $content | Out-File -FilePath $Path -Encoding UTF8
    return $Path
}

# ExÃ©cuter le script de mise Ã  jour de la roadmap
function Invoke-UpdateRoadmapTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [int[]]$LineNumbers
    )

    $updateScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-RoadmapStatus.ps1"

    if (-not (Test-Path -Path $updateScriptPath)) {
        Write-Error "Le script de mise Ã  jour de la roadmap n'a pas Ã©tÃ© trouvÃ© : $updateScriptPath"
        return $false
    }

    Write-Host "Chemin du script de mise Ã  jour : $updateScriptPath" -ForegroundColor Cyan
    Write-Host "Chemin du fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
    Write-Host "NumÃ©ros de lignes : $($LineNumbers -join ', ')" -ForegroundColor Cyan

    & $updateScriptPath -RoadmapPath $RoadmapPath -LineNumbers $LineNumbers -Verbose
    return $true
}

# VÃ©rifier que les tÃ¢ches ont Ã©tÃ© mises Ã  jour correctement
function Test-RoadmapUpdated {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedImplementedTaskIds
    )

    $content = Get-Content -Path $RoadmapPath -Encoding UTF8
    $taskRegex = '^\s*-\s+\[([ xX])\]\s+(\d+(\.\d+)*)\s+(.+)$'
    $implementedTasks = @()

    foreach ($line in $content) {
        if ($line -match $taskRegex) {
            $status = $matches[1]
            $taskId = $matches[2]

            if ($status -eq 'x' -or $status -eq 'X') {
                $implementedTasks += $taskId
            }
        }
    }

    $allExpectedImplemented = $true
    foreach ($expectedTaskId in $ExpectedImplementedTaskIds) {
        if (-not ($implementedTasks -contains $expectedTaskId)) {
            Write-Warning "La tÃ¢che $expectedTaskId n'a pas Ã©tÃ© marquÃ©e comme implÃ©mentÃ©e."
            $allExpectedImplemented = $false
        }
    }

    return $allExpectedImplemented
}

# Script principal
function Invoke-RoadmapCheckTest {
    # CrÃ©er un fichier de roadmap de test
    $testRoadmapPath = Join-Path -Path $TestDirectory -ChildPath "test_roadmap.md"
    New-TestRoadmap -Path $testRoadmapPath
    Write-Host "Fichier de roadmap de test crÃ©Ã© : $testRoadmapPath" -ForegroundColor Cyan

    # DÃ©finir les lignes Ã  vÃ©rifier (correspondant aux tÃ¢ches implÃ©mentÃ©es)
    $lineNumbers = @(9, 10, 11, 12)  # Lignes des tÃ¢ches 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.1 Ã  2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.4

    # ExÃ©cuter le script de mise Ã  jour de la roadmap
    Write-Host "ExÃ©cution du script de mise Ã  jour de la roadmap..." -ForegroundColor Cyan
    $updateSuccess = Invoke-UpdateRoadmapTest -RoadmapPath $testRoadmapPath -LineNumbers $lineNumbers

    if (-not $updateSuccess) {
        Write-Error "Ã‰chec de l'exÃ©cution du script de mise Ã  jour de la roadmap."
        return
    }

    # VÃ©rifier que les tÃ¢ches ont Ã©tÃ© mises Ã  jour correctement
    Write-Host "VÃ©rification des mises Ã  jour..." -ForegroundColor Cyan
    $expectedImplementedTaskIds = @(
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.1',
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.2',
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.3',
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.4'
    )

    $testSuccess = Test-RoadmapUpdated -RoadmapPath $testRoadmapPath -ExpectedImplementedTaskIds $expectedImplementedTaskIds

    if ($testSuccess) {
        Write-Host "Test rÃ©ussi ! Toutes les tÃ¢ches ont Ã©tÃ© correctement mises Ã  jour." -ForegroundColor Green
    } else {
        Write-Error "Test Ã©chouÃ©. Certaines tÃ¢ches n'ont pas Ã©tÃ© correctement mises Ã  jour."
    }

    # Afficher le contenu du fichier de roadmap mis Ã  jour
    Write-Host "`nContenu du fichier de roadmap mis Ã  jour :" -ForegroundColor Cyan
    Get-Content -Path $testRoadmapPath | ForEach-Object {
        if ($_ -match '^\s*-\s+\[(x|X)\]') {
            Write-Host $_ -ForegroundColor Green
        } elseif ($_ -match '^\s*-\s+\[ \]') {
            Write-Host $_ -ForegroundColor Yellow
        } else {
            Write-Host $_
        }
    }
}

# ExÃ©cuter le script principal
Invoke-RoadmapCheckTest
