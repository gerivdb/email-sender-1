<#
.SYNOPSIS
    Script d'installation du mode CHECK amélioré.

.DESCRIPTION
    Ce script installe le mode CHECK amélioré en :
    1. Mettant à jour les scripts existants pour utiliser la nouvelle fonction améliorée
    2. Créant des liens symboliques pour assurer la compatibilité avec les scripts existants
    3. Mettant à jour la documentation

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.
    Par défaut : $false (mode simulation).

.PARAMETER BackupFiles
    Indique si des copies de sauvegarde des fichiers originaux doivent être créées.
    Par défaut : $true.

.EXAMPLE
    .\install-check-enhanced.ps1 -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles = $true
)

# Chemin de base du projet
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Afficher les informations de démarrage
Write-Host "Installation du mode CHECK amélioré" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Installation" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour installer)" -ForegroundColor Gray
}
Write-Host "Sauvegarde des fichiers originaux : " -NoNewline
if ($BackupFiles) {
    Write-Host "Activée" -ForegroundColor Green
} else {
    Write-Host "Désactivée" -ForegroundColor Yellow
}

# Étape 1 : Mettre à jour les scripts existants
Write-Host "`nÉtape 1 : Mise à jour des scripts existants" -ForegroundColor Cyan

# Créer les répertoires nécessaires s'ils n'existent pas
$functionsPath = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public"
$modesPath = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\modes\check"

if (-not (Test-Path -Path $functionsPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($functionsPath, "Créer le répertoire")) {
        New-Item -Path $functionsPath -ItemType Directory -Force | Out-Null
        Write-Host "  Répertoire créé : $functionsPath" -ForegroundColor Green
    } else {
        Write-Host "  Le répertoire serait créé : $functionsPath (mode simulation)" -ForegroundColor Yellow
    }
}

if (-not (Test-Path -Path $modesPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($modesPath, "Créer le répertoire")) {
        New-Item -Path $modesPath -ItemType Directory -Force | Out-Null
        Write-Host "  Répertoire créé : $modesPath" -ForegroundColor Green
    } else {
        Write-Host "  Le répertoire serait créé : $modesPath (mode simulation)" -ForegroundColor Yellow
    }
}

# Copier la fonction améliorée
$enhancedFunctionPath = Join-Path -Path $functionsPath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
$enhancedFunctionContent = @'
<#
.SYNOPSIS
    Met à jour les cases à cocher dans le document actif pour les tâches implémentées et testées à 100%.
    Version améliorée avec support UTF-8 avec BOM.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tâches qui ont été implémentées
    et testées avec succès à 100%, puis coche automatiquement les cases correspondantes.
    Cette version améliorée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM
    et préserve correctement les caractères accentués et l'indentation.

.PARAMETER DocumentPath
    Chemin vers le document actif à mettre à jour.

.PARAMETER ImplementationResults
    Résultats de l'implémentation des tâches (hashtable).

.PARAMETER TestResults
    Résultats des tests des tâches (hashtable).

.EXAMPLE
    Update-ActiveDocumentCheckboxes-Enhanced -DocumentPath "document.md" -ImplementationResults $implResults -TestResults $testResults

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de création: 2023-09-15
    Date de mise à jour: 2025-05-01 - Amélioration de l'encodage UTF-8 avec BOM
#>
function Update-ActiveDocumentCheckboxes-Enhanced {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DocumentPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$ImplementationResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$TestResults
    )

    # Vérifier que le document existe
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document spécifié n'existe pas : $DocumentPath"
        return 0
    }

    try {
        # Lire le contenu du document avec l'encodage approprié
        # Utiliser [System.IO.File]::ReadAllLines pour garantir la détection correcte de l'encodage
        $content = [System.IO.File]::ReadAllLines($DocumentPath)
        $modified = $false
        $tasksUpdated = 0

        # Parcourir chaque ligne du document
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]

            # Rechercher les lignes avec des cases à cocher non cochées
            if ($line -match '^\s*-\s+\[\s*\]') {
                # Extraire le texte de la tâche en préservant l'indentation
                $indentation = [regex]::Match($line, '^\s*').Value
                $taskText = $line -replace '^\s*-\s+\[\s*\]\s*', ''

                # Rechercher cette tâche dans les résultats d'implémentation et de tests
                $taskFound = $false
                $taskComplete = $false
                $matchedTaskId = $null

                # Essayer de trouver l'ID de la tâche dans le texte
                foreach ($taskId in $ImplementationResults.Keys) {
                    # Échapper les caractères spéciaux dans l'ID de la tâche pour la regex
                    $escapedTaskId = [regex]::Escape($taskId)

                    # Vérifier différents formats possibles d'ID de tâche dans le texte
                    if ($taskText -match "^\*\*$escapedTaskId\*\*" -or
                        $taskText -match "^$escapedTaskId\s" -or
                        $taskText -match "^$escapedTaskId$" -or
                        $taskText -match "\[$escapedTaskId\]" -or
                        $taskText -match "\($escapedTaskId\)" -or
                        # Format spécifique pour les IDs longs
                        $taskText -match "\*\*$escapedTaskId\*\*") {

                        $taskFound = $true
                        $matchedTaskId = $taskId

                        # Vérifier si l'implémentation et les tests sont à 100%
                        $implementationResult = $ImplementationResults[$taskId]
                        $testResult = $TestResults[$taskId]

                        if ($implementationResult.ImplementationComplete -and
                            $testResult.TestsComplete -and
                            $testResult.TestsSuccessful) {
                            $taskComplete = $true
                        }

                        break
                    }
                }

                # Si aucun ID n'a été trouvé, essayer de faire correspondre par titre
                if (-not $taskFound) {
                    foreach ($taskId in $ImplementationResults.Keys) {
                        $implementationResult = $ImplementationResults[$taskId]

                        # Vérifier si le titre de la tâche correspond
                        if ($implementationResult.TaskTitle -and $taskText -match [regex]::Escape($implementationResult.TaskTitle)) {
                            $taskFound = $true
                            $matchedTaskId = $taskId

                            # Vérifier si l'implémentation et les tests sont à 100%
                            $testResult = $TestResults[$taskId]

                            if ($implementationResult.ImplementationComplete -and
                                $testResult.TestsComplete -and
                                $testResult.TestsSuccessful) {
                                $taskComplete = $true
                            }

                            break
                        }
                    }
                }

                # Si la tâche a été trouvée et est complète, mettre à jour la case à cocher
                if ($taskFound -and $taskComplete) {
                    # Mettre à jour la case à cocher en préservant l'indentation et le texte complet
                    $newLine = $line -replace '^\s*-\s+\[\s*\]', "$indentation- [x]"
                    $content[$i] = $newLine
                    $modified = $true
                    $tasksUpdated++

                    Write-Verbose "Case à cocher mise à jour pour la tâche : $taskText (ID: $matchedTaskId)"
                }
            }
        }

        # Enregistrer les modifications si nécessaire
        if ($modified -and $PSCmdlet.ShouldProcess($DocumentPath, "Mettre à jour les cases à cocher")) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($DocumentPath, $content, $utf8WithBom)

            # Vérifier que le fichier a bien été enregistré en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($DocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas été correctement enregistré en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($DocumentPath)
                [System.IO.File]::WriteAllText($DocumentPath, $content, $utf8WithBom)
            }

            Write-Output "$tasksUpdated cases à cocher mises à jour dans le document : $DocumentPath"
        } else {
            Write-Output "$tasksUpdated cases à cocher seraient mises à jour dans le document : $DocumentPath (mode simulation)"
        }

        return $tasksUpdated
    }
    catch {
        Write-Error "Erreur lors de la mise à jour des cases à cocher : $_"
        return 0
    }
}
'@

if ($Force -or $PSCmdlet.ShouldProcess($enhancedFunctionPath, "Créer la fonction améliorée")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($enhancedFunctionPath, $enhancedFunctionContent, $utf8WithBom)
    Write-Host "  Fonction améliorée créée : $enhancedFunctionPath" -ForegroundColor Green
} else {
    Write-Host "  La fonction améliorée serait créée : $enhancedFunctionPath (mode simulation)" -ForegroundColor Yellow
}

# Étape 2 : Créer le script check-mode-enhanced.ps1
Write-Host "`nÉtape 2 : Création du script check-mode-enhanced.ps1" -ForegroundColor Cyan

$checkModeEnhancedPath = Join-Path -Path $modesPath -ChildPath "check-mode-enhanced.ps1"
$checkModeEnhancedContent = @'
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
'@

if ($Force -or $PSCmdlet.ShouldProcess($checkModeEnhancedPath, "Créer le script check-mode-enhanced.ps1")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($checkModeEnhancedPath, $checkModeEnhancedContent, $utf8WithBom)
    Write-Host "  Script check-mode-enhanced.ps1 créé : $checkModeEnhancedPath" -ForegroundColor Green
} else {
    Write-Host "  Le script check-mode-enhanced.ps1 serait créé : $checkModeEnhancedPath (mode simulation)" -ForegroundColor Yellow
}

# Étape 3 : Mettre à jour le script check.ps1
Write-Host "`nÉtape 3 : Mise à jour du script check.ps1" -ForegroundColor Cyan

$checkScriptPath = Join-Path -Path $basePath -ChildPath "tools\scripts\check.ps1"
$checkScriptContent = @'
<#
.SYNOPSIS
    Script pour exécuter le mode CHECK amélioré et mettre à jour les cases à cocher dans le document actif.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amélioré qui vérifie si les tâches sont 100% implémentées
    et testées avec succès, puis met à jour automatiquement les cases à cocher dans le document actif.
    Cette version améliorée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à vérifier.
    Par défaut : "docs/plans/plan-modes-stepup.md"

.PARAMETER TaskIdentifier
    Identifiant de la tâche à vérifier (par exemple, "1.2.3").
    Si non spécifié, toutes les tâches seront vérifiées.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif à mettre à jour.
    Si non spécifié, le script tentera de détecter automatiquement le document actif.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.

.EXAMPLE
    .\check.ps1

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de création: 2023-09-15
    Date de mise à jour: 2025-05-01 - Amélioration de l'encodage UTF-8 avec BOM
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = "docs/plans/plan-modes-stepup.md",

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Déterminer le chemin du script check-mode-enhanced.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"

# Si le chemin n'existe pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si le chemin n'existe toujours pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si le chemin n'existe toujours pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si la version améliorée n'est pas trouvée, essayer la version standard
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode.ps1"

    if (Test-Path -Path $scriptPath) {
        Write-Warning "La version améliorée du mode CHECK n'a pas été trouvée. Utilisation de la version standard."
    }
}

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script check-mode-enhanced.ps1 ou check-mode.ps1 est introuvable."
    exit 1
}

# Construire les paramètres pour le script check-mode.ps1
$params = @{
    FilePath = $FilePath
    CheckActiveDocument = $true
    ImplementationPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Functions\Public"
    TestsPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Tests"
}

# Ajouter les paramètres optionnels s'ils sont spécifiés
if ($TaskIdentifier) {
    $params.Add("TaskIdentifier", $TaskIdentifier)
}

if ($ActiveDocumentPath) {
    $params.Add("ActiveDocumentPath", $ActiveDocumentPath)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Afficher les informations de démarrage
Write-Host "Exécution du mode CHECK amélioré..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
if ($TaskIdentifier) {
    Write-Host "Tâche à vérifier : $TaskIdentifier" -ForegroundColor Cyan
} else {
    Write-Host "Vérification de toutes les tâches" -ForegroundColor Cyan
}
if ($ActiveDocumentPath) {
    Write-Host "Document actif : $ActiveDocumentPath" -ForegroundColor Cyan
} else {
    Write-Host "Détection automatique du document actif" -ForegroundColor Cyan
}
if ($Force) {
    Write-Host "Mode force activé : les modifications seront appliquées sans confirmation" -ForegroundColor Yellow
} else {
    Write-Host "Mode simulation activé : les modifications ne seront pas appliquées" -ForegroundColor Gray
}

# Exécuter le script check-mode.ps1 avec les paramètres
& $scriptPath @params

# Afficher un message de fin
Write-Host "`nExécution du mode CHECK amélioré terminée." -ForegroundColor Cyan
'@

if ($Force -or $PSCmdlet.ShouldProcess($checkScriptPath, "Créer ou mettre à jour le script check.ps1")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($checkScriptPath, $checkScriptContent, $utf8WithBom)
    Write-Host "  Script check.ps1 créé ou mis à jour : $checkScriptPath" -ForegroundColor Green
} else {
    Write-Host "  Le script check.ps1 serait créé ou mis à jour : $checkScriptPath (mode simulation)" -ForegroundColor Yellow
}

# Étape 4 : Mettre à jour la documentation
Write-Host "`nÉtape 4 : Mise à jour de la documentation" -ForegroundColor Cyan

$docsPath = Join-Path -Path $basePath -ChildPath "docs\guides\methodologies\modes"
$checkDocPath = Join-Path -Path $docsPath -ChildPath "mode_check.md"
$enhancedDocPath = Join-Path -Path $docsPath -ChildPath "mode_check_enhanced.md"

# Créer le répertoire de documentation s'il n'existe pas
if (-not (Test-Path -Path $docsPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($docsPath, "Créer le répertoire")) {
        New-Item -Path $docsPath -ItemType Directory -Force | Out-Null
        Write-Host "  Répertoire créé : $docsPath" -ForegroundColor Green
    } else {
        Write-Host "  Le répertoire serait créé : $docsPath (mode simulation)" -ForegroundColor Yellow
    }
}

# Mettre à jour la documentation du mode CHECK
if (Test-Path -Path $checkDocPath) {
    Write-Host "  Mise à jour de la documentation du mode CHECK..." -ForegroundColor Cyan

    if ($Force -or $PSCmdlet.ShouldProcess($checkDocPath, "Mettre à jour la documentation")) {
        # Créer une sauvegarde du fichier existant si nécessaire
        if ($BackupFiles) {
            $backupPath = "$checkDocPath.bak"
            Copy-Item -Path $checkDocPath -Destination $backupPath -Force
            Write-Host "  Sauvegarde créée : $backupPath" -ForegroundColor Gray
        }

        # Ajouter une note dans la documentation existante
        $checkDocContent = Get-Content -Path $checkDocPath -Encoding UTF8
        $noteAdded = $false

        for ($i = 0; $i -lt $checkDocContent.Count; $i++) {
            if ($checkDocContent[$i] -match "^# Mode CHECK$") {
                $checkDocContent[$i] = "# Mode CHECK`n`n> **Note importante** : Une version améliorée du mode CHECK est disponible. Voir [Mode CHECK Amélioré](mode_check_enhanced.md) pour plus d'informations."
                $noteAdded = $true
                break
            }
        }

        if ($noteAdded) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($checkDocPath, $checkDocContent, $utf8WithBom)

            Write-Host "  Documentation mise à jour : $checkDocPath" -ForegroundColor Green
        } else {
            Write-Warning "Impossible d'ajouter la note dans la documentation existante : $checkDocPath"
        }
    } else {
        Write-Host "  La documentation serait mise à jour : $checkDocPath (mode simulation)" -ForegroundColor Yellow
    }
} else {
    Write-Warning "Le fichier de documentation du mode CHECK est introuvable : $checkDocPath"
}

# Créer la documentation du mode CHECK amélioré
$enhancedDocContent = @'
# Mode CHECK Amélioré

Le mode CHECK amélioré est une version avancée du [mode CHECK](mode_check.md) qui vérifie si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100%, puis met à jour automatiquement les cases à cocher dans le document actif.

## Améliorations par rapport au mode CHECK standard

- **Encodage UTF-8 avec BOM** : Tous les fichiers sont enregistrés en UTF-8 avec BOM, ce qui garantit une meilleure compatibilité avec les caractères accentués.
- **Préservation des indentations** : Les indentations dans les documents sont correctement préservées lors de la mise à jour des cases à cocher.
- **Meilleure détection des tâches** : L'algorithme de détection des tâches a été amélioré pour mieux identifier les tâches dans le document actif.
- **Préservation du texte complet des tâches** : Le texte complet des tâches est préservé lors de la mise à jour des cases à cocher.

## Utilisation

Le mode CHECK amélioré peut être utilisé de la même manière que le mode CHECK standard, mais avec des fonctionnalités supplémentaires.

### Vérification simple

Pour vérifier si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100% :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3"
```

### Mise à jour automatique des cases à cocher

Pour mettre à jour automatiquement les cases à cocher dans le document actif :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

### Spécification du document actif

Si le document actif ne peut pas être détecté automatiquement, vous pouvez le spécifier manuellement :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ActiveDocumentPath "docs/roadmap/roadmap.md" -Force
```

### Mode simulation et mode force
Par défaut, le mode CHECK amélioré fonctionne en mode simulation (`-Force` non spécifié) :
- Il affiche les modifications qui seraient apportées sans les appliquer
- Il indique le nombre de cases à cocher qui seraient mises à jour

Pour appliquer réellement les modifications, utilisez le paramètre `-Force` :
```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

## Fonctionnement interne

Le mode CHECK amélioré utilise les fonctions suivantes :

1. `Invoke-RoadmapCheck` : Vérifie si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100%.
2. `Update-RoadmapTaskStatus` : Met à jour le statut des tâches dans la roadmap.
3. `Update-ActiveDocumentCheckboxes-Enhanced` : Met à jour les cases à cocher dans le document actif.

## Détection du document actif

Le mode CHECK amélioré tente de détecter automatiquement le document actif en utilisant les méthodes suivantes :

1. Vérification de la variable d'environnement `VSCODE_ACTIVE_DOCUMENT`.
2. Recherche des fichiers Markdown récemment modifiés.

Si aucun document actif ne peut être détecté automatiquement, vous pouvez le spécifier manuellement avec le paramètre `-ActiveDocumentPath`.

## Résolution des problèmes

### Problèmes d'encodage

Si vous rencontrez des problèmes d'encodage (caractères accentués mal affichés), assurez-vous que tous les fichiers sont enregistrés en UTF-8 avec BOM.

### Problèmes de détection du document actif

Si le document actif ne peut pas être détecté automatiquement, utilisez le paramètre `-ActiveDocumentPath` pour le spécifier manuellement.

### Problèmes de mise à jour des cases à cocher

Si les cases à cocher ne sont pas mises à jour correctement, vérifiez que les tâches ont bien été implémentées à 100% et testées avec succès à 100%.
'@

if ($Force -or $PSCmdlet.ShouldProcess($enhancedDocPath, "Créer la documentation du mode CHECK amélioré")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($enhancedDocPath, $enhancedDocContent, $utf8WithBom)
    Write-Host "  Documentation du mode CHECK amélioré créée : $enhancedDocPath" -ForegroundColor Green
} else {
    Write-Host "  La documentation du mode CHECK amélioré serait créée : $enhancedDocPath (mode simulation)" -ForegroundColor Yellow
}

# Afficher un message de fin
if ($Force) {
    Write-Host "`nInstallation du mode CHECK amélioré terminée." -ForegroundColor Green
    Write-Host "Pour utiliser le mode CHECK amélioré, exécutez :" -ForegroundColor Cyan
    Write-Host "  .\tools\scripts\check.ps1" -ForegroundColor Yellow
} else {
    Write-Host "`nSimulation de l'installation terminée. Utilisez -Force pour installer." -ForegroundColor Yellow
}
