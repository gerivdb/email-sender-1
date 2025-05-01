<#
.SYNOPSIS
    Script de test pour vérifier le fonctionnement du mode CHECK pour les roadmaps.

.DESCRIPTION
    Ce script crée un fichier de roadmap de test, exécute le script de mise à jour de la roadmap,
    et vérifie que les tâches sont correctement mises à jour.

.PARAMETER TestDirectory
    Répertoire où créer les fichiers de test. Par défaut, utilise un sous-répertoire "Tests" dans le répertoire courant.

.EXAMPLE
    .\Test-RoadmapCheck.ps1

.NOTES
    Auteur: Roadmap Tools Team
    Version: 1.0
    Date de création: 2023-11-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDirectory = ".\Tests"
)

# Créer le répertoire de test s'il n'existe pas
if (-not (Test-Path -Path $TestDirectory)) {
    New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
}

# Créer un fichier de roadmap de test
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

# Exécuter le script de mise à jour de la roadmap
function Invoke-UpdateRoadmapTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [int[]]$LineNumbers
    )

    $updateScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-RoadmapStatus.ps1"

    if (-not (Test-Path -Path $updateScriptPath)) {
        Write-Error "Le script de mise à jour de la roadmap n'a pas été trouvé : $updateScriptPath"
        return $false
    }

    Write-Host "Chemin du script de mise à jour : $updateScriptPath" -ForegroundColor Cyan
    Write-Host "Chemin du fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
    Write-Host "Numéros de lignes : $($LineNumbers -join ', ')" -ForegroundColor Cyan

    & $updateScriptPath -RoadmapPath $RoadmapPath -LineNumbers $LineNumbers -Verbose
    return $true
}

# Vérifier que les tâches ont été mises à jour correctement
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
            Write-Warning "La tâche $expectedTaskId n'a pas été marquée comme implémentée."
            $allExpectedImplemented = $false
        }
    }

    return $allExpectedImplemented
}

# Script principal
function Invoke-RoadmapCheckTest {
    # Créer un fichier de roadmap de test
    $testRoadmapPath = Join-Path -Path $TestDirectory -ChildPath "test_roadmap.md"
    New-TestRoadmap -Path $testRoadmapPath
    Write-Host "Fichier de roadmap de test créé : $testRoadmapPath" -ForegroundColor Cyan

    # Définir les lignes à vérifier (correspondant aux tâches implémentées)
    $lineNumbers = @(9, 10, 11, 12)  # Lignes des tâches 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.1 à 2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.4

    # Exécuter le script de mise à jour de la roadmap
    Write-Host "Exécution du script de mise à jour de la roadmap..." -ForegroundColor Cyan
    $updateSuccess = Invoke-UpdateRoadmapTest -RoadmapPath $testRoadmapPath -LineNumbers $lineNumbers

    if (-not $updateSuccess) {
        Write-Error "Échec de l'exécution du script de mise à jour de la roadmap."
        return
    }

    # Vérifier que les tâches ont été mises à jour correctement
    Write-Host "Vérification des mises à jour..." -ForegroundColor Cyan
    $expectedImplementedTaskIds = @(
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.1',
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.2',
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.3',
        '2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.4'
    )

    $testSuccess = Test-RoadmapUpdated -RoadmapPath $testRoadmapPath -ExpectedImplementedTaskIds $expectedImplementedTaskIds

    if ($testSuccess) {
        Write-Host "Test réussi ! Toutes les tâches ont été correctement mises à jour." -ForegroundColor Green
    } else {
        Write-Error "Test échoué. Certaines tâches n'ont pas été correctement mises à jour."
    }

    # Afficher le contenu du fichier de roadmap mis à jour
    Write-Host "`nContenu du fichier de roadmap mis à jour :" -ForegroundColor Cyan
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

# Exécuter le script principal
Invoke-RoadmapCheckTest
