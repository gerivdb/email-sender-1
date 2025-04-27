<#
.SYNOPSIS
    Script pour vérifier si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100% (Mode CHECK).
    Version améliorée avec support UTF-8 avec BOM.

.DESCRIPTION
    Ce script permet de vérifier si les tâches sélectionnées ont été implémentées à 100% et testées
    avec succès à 100%. Si c'est le cas, il peut mettre à jour automatiquement le statut des tâches
    dans la roadmap en cochant les cases correspondantes. Il implémente le mode CHECK décrit dans
    la documentation des modes de fonctionnement.
    Cette version améliorée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à vérifier et mettre à jour.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à vérifier (par exemple, "1.2.1.3.2.3").
    Si non spécifié, l'utilisateur sera invité à le saisir.

.PARAMETER ImplementationPath
    Chemin vers le répertoire contenant l'implémentation.
    Si non spécifié, le script tentera de le déduire automatiquement.

.PARAMETER TestsPath
    Chemin vers le répertoire contenant les tests.
    Si non spécifié, le script tentera de le déduire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit être mise à jour automatiquement.
    Par défaut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit être généré.
    Par défaut : $true.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif à vérifier et mettre à jour.
    Si non spécifié, le script tentera de détecter automatiquement le document actif.

.PARAMETER CheckActiveDocument
    Indique si le document actif doit être vérifié et mis à jour.
    Par défaut : $true.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.
    Par défaut : $false (mode simulation).

.EXAMPLE
    .\check-mode-enhanced.ps1 -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    .\check-mode-enhanced.ps1 -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de création: 2023-08-15
    Date de mise à jour: 2025-05-01 - Amélioration de l'encodage UTF-8 avec BOM
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ImplementationPath,

    [Parameter(Mandatory = $false)]
    [string]$TestsPath,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateRoadmap = $true,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif à vérifier et mettre à jour. Si non spécifié, le document actif sera détecté automatiquement.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$CheckActiveDocument = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les fonctions nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "module\Functions\Public"
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
$updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"

# Si les chemins n'existent pas, essayer d'autres chemins
if (-not (Test-Path -Path $modulePath)) {
    $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath "module\Functions\Public"
    $invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
    $updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
    $updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
}

# Si les chemins n'existent toujours pas, essayer d'autres chemins
if (-not (Test-Path -Path $modulePath)) {
    $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath)))) -ChildPath "module\Functions\Public"
    $invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
    $updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
    $updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
}

# Afficher les chemins pour le débogage
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Yellow
Write-Host "Chemin du module : $modulePath" -ForegroundColor Yellow
Write-Host "Chemin de Invoke-RoadmapCheck : $invokeCheckPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-RoadmapTaskStatus : $updateTaskPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-ActiveDocumentCheckboxes-Enhanced : $updateCheckboxesPath" -ForegroundColor Yellow

if (Test-Path -Path $invokeCheckPath) {
    . $invokeCheckPath
    Write-Host "Fonction Invoke-RoadmapCheck importée." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapCheck est introuvable à l'emplacement : $invokeCheckPath"
}

if (Test-Path -Path $updateTaskPath) {
    . $updateTaskPath
    Write-Host "Fonction Update-RoadmapTaskStatus importée." -ForegroundColor Green
} else {
    throw "La fonction Update-RoadmapTaskStatus est introuvable à l'emplacement : $updateTaskPath"
}

if (Test-Path -Path $updateCheckboxesPath) {
    . $updateCheckboxesPath
    Write-Host "Fonction Update-ActiveDocumentCheckboxes-Enhanced importée." -ForegroundColor Green
} else {
    Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced est introuvable à l'emplacement : $updateCheckboxesPath. La mise à jour automatique des cases à cocher dans le document actif ne sera pas disponible."
}

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spécifié n'existe pas : $FilePath"
}

# Détecter automatiquement le document actif si nécessaire
if ($CheckActiveDocument -and -not $ActiveDocumentPath) {
    Write-Host "Détection automatique du document actif..." -ForegroundColor Cyan

    # Méthode 1: Vérifier la variable d'environnement VSCODE_ACTIVE_DOCUMENT
    if ($env:VSCODE_ACTIVE_DOCUMENT -and (Test-Path -Path $env:VSCODE_ACTIVE_DOCUMENT)) {
        $ActiveDocumentPath = $env:VSCODE_ACTIVE_DOCUMENT
        Write-Host "Document actif détecté via variable d'environnement : $ActiveDocumentPath" -ForegroundColor Green
    }
    # Méthode 2: Rechercher les fichiers Markdown récemment modifiés
    else {
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        $recentMdFiles = Get-ChildItem -Path $projectRoot -Filter "*.md" -Recurse |
                         Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) } |
                         Sort-Object LastWriteTime -Descending

        if ($recentMdFiles.Count -gt 0) {
            $ActiveDocumentPath = $recentMdFiles[0].FullName
            Write-Host "Document actif détecté automatiquement (fichier récemment modifié) : $ActiveDocumentPath" -ForegroundColor Green
        }
        else {
            Write-Warning "Aucun document actif n'a pu être détecté automatiquement. La vérification du document actif sera désactivée."
            $CheckActiveDocument = $false
        }
    }
}

# Vérifier si le document actif existe
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if (-not (Test-Path -Path $ActiveDocumentPath)) {
        Write-Warning "Le document actif spécifié n'existe pas : $ActiveDocumentPath. La vérification du document actif sera désactivée."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# Vérifier et mettre à jour les cases à cocher dans le document actif si demandé
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVérification et mise à jour des cases à cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Extraire les résultats d'implémentation et de tests
    $implementationResults = @{}
    $testResults = @{}

    foreach ($task in $result.Tasks) {
        $implementationResults[$task.Id] = $task.Implementation
        $testResults[$task.Id] = $task.Tests
    }

    # Utiliser la fonction Update-ActiveDocumentCheckboxes-Enhanced si disponible
    if (Get-Command -Name Update-ActiveDocumentCheckboxes-Enhanced -ErrorAction SilentlyContinue) {
        # Préparer les paramètres pour la fonction
        $updateParams = @{
            DocumentPath = $ActiveDocumentPath
            ImplementationResults = $implementationResults
            TestResults = $testResults
        }

        # Ajouter le paramètre WhatIf si Force n'est pas spécifié
        if (-not $Force) {
            $updateParams.Add("WhatIf", $true)
        }

        # Appeler la fonction avec les paramètres
        $updateResult = Update-ActiveDocumentCheckboxes-Enhanced @updateParams
        $tasksUpdated = $updateResult
    } else {
        # Méthode alternative si la fonction n'est pas disponible
        Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced n'est pas disponible. Utilisation d'une méthode alternative."

        # Lire le contenu du document actif
        $activeDocumentContent = Get-Content -Path $ActiveDocumentPath -Encoding UTF8
        $tasksUpdated = 0
        $modified = $false

        # Pour chaque tâche vérifiée
        foreach ($task in $result.Tasks) {
            # Si la tâche est implémentée à 100% et testée avec succès à 100%
            if ($task.Implementation.ImplementationComplete -and $task.Tests.TestsComplete -and $task.Tests.TestsSuccessful) {
                # Rechercher la tâche dans le document actif (différents formats possibles)
                $taskPatterns = @(
                    "- \[ \] \*\*$($task.Id)\*\*",
                    "- \[ \] $($task.Id)",
                    "- \[ \] $($task.Title)"
                )

                foreach ($pattern in $taskPatterns) {
                    $newContent = $activeDocumentContent -replace $pattern, "- [x] $($task.Id)"

                    # Si le contenu a changé, c'est que la tâche a été trouvée et mise à jour
                    if ($newContent -ne $activeDocumentContent) {
                        $activeDocumentContent = $newContent
                        $modified = $true
                        $tasksUpdated++
                        Write-Host "  Tâche $($task.Id) - $($task.Title) : Case à cocher mise à jour" -ForegroundColor Green
                        break
                    }
                }
            }
        }

        # Enregistrer les modifications si nécessaire
        if ($modified -and $Force) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($ActiveDocumentPath, $activeDocumentContent, $utf8WithBom)

            # Vérifier que le fichier a bien été enregistré en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($ActiveDocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas été correctement enregistré en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($ActiveDocumentPath)
                [System.IO.File]::WriteAllText($ActiveDocumentPath, $content, $utf8WithBom)
            }

            Write-Host "  $tasksUpdated cases à cocher mises à jour dans le document actif." -ForegroundColor Green
        } elseif ($modified) {
            Write-Host "  $tasksUpdated cases à cocher seraient mises à jour dans le document actif (mode simulation)." -ForegroundColor Yellow
        } else {
            Write-Host "  Aucune case à cocher n'a été mise à jour dans le document actif." -ForegroundColor Gray
        }
    }
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats :" -ForegroundColor Cyan
Write-Host "  Tâche principale : $($result.MainTaskId)" -ForegroundColor Cyan
Write-Host "  Nombre total de tâches : $($result.Tasks.Count)" -ForegroundColor Cyan
Write-Host "  Tâches implémentées à 100% : $($result.Tasks | Where-Object { $_.Implementation.ImplementationComplete } | Measure-Object).Count" -ForegroundColor Cyan
Write-Host "  Tâches testées à 100% : $($result.Tasks | Where-Object { $_.Tests.TestsComplete -and $_.Tests.TestsSuccessful } | Measure-Object).Count" -ForegroundColor Cyan

if ($UpdateRoadmap) {
    Write-Host "  Tâches mises à jour dans la roadmap : $($result.TasksUpdated)" -ForegroundColor Cyan
}

if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "  Tâches mises à jour dans le document actif : $tasksUpdated" -ForegroundColor Cyan
}

# Afficher un message de fin
Write-Host "`nVérification terminée." -ForegroundColor Green
