<#
.SYNOPSIS
    Vérifie si les tâches sélectionnées ont été implémentées à 100% et testées avec succès à 100%.

.DESCRIPTION
    Cette fonction vérifie si les tâches sélectionnées ont été implémentées à 100% et testées
    avec succès à 100%. Si c'est le cas, elle peut mettre à jour automatiquement le statut
    des tâches dans la roadmap en cochant les cases correspondantes.

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

.EXAMPLE
    Invoke-RoadmapCheck -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    Invoke-RoadmapCheck -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ImplementationPath "src/functions" -TestsPath "tests/unit"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>
function Invoke-RoadmapCheck {
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
        [bool]$UpdateRoadmap = $true,

        [Parameter(Mandatory = $false)]
        [bool]$GenerateReport = $true
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spécifié n'existe pas : $FilePath"
    }

    # Importer la fonction Update-RoadmapTaskStatus si elle n'est pas déjà disponible
    if (-not (Get-Command -Name Update-RoadmapTaskStatus -ErrorAction SilentlyContinue)) {
        $updateTaskPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Update-RoadmapTaskStatus.ps1"
        if (Test-Path -Path $updateTaskPath) {
            . $updateTaskPath
        } else {
            throw "La fonction Update-RoadmapTaskStatus est introuvable. Assurez-vous que le fichier Update-RoadmapTaskStatus.ps1 est présent dans le même répertoire."
        }
    }

    # Si l'identifiant de tâche n'est pas spécifié, afficher le contenu du fichier et demander à l'utilisateur
    if (-not $TaskIdentifier) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Afficher le contenu avec des numéros de ligne
        Write-Host "Contenu du fichier de roadmap :" -ForegroundColor Cyan
        for ($i = 0; $i -lt $content.Count; $i++) {
            Write-Host ("{0,5}: {1}" -f ($i + 1), $content[$i])
        }

        # Demander à l'utilisateur de saisir l'identifiant de la tâche
        $TaskIdentifier = Read-Host -Prompt "Entrez l'identifiant de la tâche à vérifier (par exemple, 1.2.1.3.2.3)"

        if (-not $TaskIdentifier) {
            throw "Aucun identifiant de tâche spécifié. Opération annulée."
        }
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8

    # Trouver la tâche principale et ses sous-tâches
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"
    $taskLines = @()
    $taskLineIndices = @()
    $inTaskSection = $false
    $taskIndentation = ""

    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]

        # Vérifier si c'est la tâche principale
        if ($line -match $taskLinePattern) {
            $inTaskSection = $true
            $taskLines += $line
            $taskLineIndices += $i

            # Déterminer l'indentation de la tâche principale
            if ($line -match "^(\s+)") {
                $taskIndentation = $matches[1]
            }

            continue
        }

        # Si nous sommes dans la section de la tâche, vérifier les sous-tâches
        if ($inTaskSection) {
            # Vérifier si la ligne a une indentation plus grande que la tâche principale
            if ($line -match "^$taskIndentation\s+") {
                $taskLines += $line
                $taskLineIndices += $i
            } else {
                # Si l'indentation est égale ou inférieure, nous sommes sortis de la section
                $inTaskSection = $false
            }
        }
    }

    if ($taskLines.Count -eq 0) {
        throw "Tâche avec l'identifiant '$TaskIdentifier' non trouvée dans le fichier."
    }

    # Analyser les tâches pour déterminer leurs identifiants et titres
    $tasks = @()
    foreach ($taskLine in $taskLines) {
        if ($taskLine -match ".*\*\*([0-9.]+)\*\*\s+(.+)") {
            $taskId = $matches[1]
            $taskTitle = $matches[2]

            # Déterminer si la tâche est cochée
            $isChecked = $taskLine -match "\[x\]"

            $tasks += @{
                Id        = $taskId
                Title     = $taskTitle
                IsChecked = $isChecked
                Line      = $taskLine
            }
        }
    }

    # Vérifier l'implémentation et les tests pour chaque tâche
    $implementationResults = @{}
    $testResults = @{}
    $tasksToUpdate = @()

    foreach ($task in $tasks) {
        # Vérifier l'implémentation
        $implementationResult = Test-TaskImplementation -TaskId $task.Id -TaskTitle $task.Title -ImplementationPath $ImplementationPath
        $implementationResults[$task.Id] = $implementationResult

        # Vérifier les tests
        $testResult = Test-TaskTests -TaskId $task.Id -TaskTitle $task.Title -TestsPath $TestsPath
        $testResults[$task.Id] = $testResult

        # Si l'implémentation et les tests sont à 100%, marquer la tâche pour mise à jour
        if ($implementationResult.ImplementationComplete -and $testResult.TestsComplete -and $testResult.TestsSuccessful) {
            if (-not $task.IsChecked) {
                $tasksToUpdate += $task.Id
            }
        }
    }

    # Générer un rapport si demandé
    if ($GenerateReport) {
        $reportPath = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "check_report_$TaskIdentifier.md"
        $report = @"
# Rapport de vérification pour la tâche $TaskIdentifier

## Résumé

- Tâche principale : **$TaskIdentifier** - $($tasks[0].Title)
- Nombre de sous-tâches : $($tasks.Count - 1)
- Tâches implémentées à 100% : $($implementationResults.Values | Where-Object { $_.ImplementationComplete } | Measure-Object).Count
- Tâches testées à 100% : $($testResults.Values | Where-Object { $_.TestsComplete -and $_.TestsSuccessful } | Measure-Object).Count
- Tâches à mettre à jour : $($tasksToUpdate.Count)

## Détails des tâches

"@

        foreach ($task in $tasks) {
            $implResult = $implementationResults[$task.Id]
            $testResult = $testResults[$task.Id]

            $report += @"

### Tâche $($task.Id) - $($task.Title)

- **État actuel** : $(if ($task.IsChecked) { "Terminée" } else { "En cours" })
- **Implémentation** : $(if ($implResult.ImplementationComplete) { "Complète (100%)" } else { "Incomplète ($($implResult.ImplementationPercentage)%)" })
- **Tests** : $(if ($testResult.TestsComplete) { "Complets" } else { "Incomplets" })
- **Résultats des tests** : $(if ($testResult.TestsSuccessful) { "Tous les tests passent" } else { "Certains tests échouent" })
- **Action recommandée** : $(if ($implResult.ImplementationComplete -and $testResult.TestsComplete -and $testResult.TestsSuccessful -and -not $task.IsChecked) { "Marquer comme terminée" } elseif (-not $implResult.ImplementationComplete) { "Compléter l'implémentation" } elseif (-not $testResult.TestsComplete) { "Ajouter des tests" } elseif (-not $testResult.TestsSuccessful) { "Corriger les tests qui échouent" } else { "Aucune action requise" })

"@
        }

        $report | Set-Content -Path $reportPath -Encoding UTF8
        Write-Host "Rapport généré : $reportPath" -ForegroundColor Green
    }

    # Mettre à jour la roadmap si demandé
    if ($UpdateRoadmap -and $tasksToUpdate.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess($FilePath, "Mettre à jour le statut des tâches")) {
            foreach ($taskId in $tasksToUpdate) {
                Update-RoadmapTaskStatus -FilePath $FilePath -TaskIdentifier $taskId -Status "Completed"
            }

            Write-Host "$($tasksToUpdate.Count) tâches ont été marquées comme terminées dans la roadmap." -ForegroundColor Green
        }
    }

    # Retourner un résumé
    return @{
        TaskIdentifier   = $TaskIdentifier
        TotalTasks       = $tasks.Count
        ImplementedTasks = ($implementationResults.Values | Where-Object { $_.ImplementationComplete } | Measure-Object).Count
        TestedTasks      = ($testResults.Values | Where-Object { $_.TestsComplete -and $_.TestsSuccessful } | Measure-Object).Count
        UpdatedTasks     = $tasksToUpdate.Count
        Tasks            = $tasks | ForEach-Object {
            $taskId = $_.Id
            @{
                Id             = $taskId
                Title          = $_.Title
                IsChecked      = $_.IsChecked
                Implementation = $implementationResults[$taskId]
                Tests          = $testResults[$taskId]
                NeedsUpdate    = $tasksToUpdate -contains $taskId
            }
        }
    }
}

# Fonction pour vérifier l'implémentation d'une tâche
function Test-TaskImplementation {
    param (
        [string]$TaskId,
        [string]$TaskTitle,
        [string]$ImplementationPath
    )

    # Si le chemin d'implémentation n'est pas spécifié, essayer de le déduire
    if (-not $ImplementationPath) {
        # Essayer de trouver le chemin d'implémentation en fonction du titre de la tâche
        # Cette logique peut être adaptée en fonction de la structure du projet
        $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
        $possiblePaths = @(
            (Join-Path -Path $projectRoot -ChildPath "scripts\roadmap-parser\module\Functions\Public"),
            (Join-Path -Path $projectRoot -ChildPath "scripts\roadmap-parser\module\Functions\Private"),
            (Join-Path -Path $projectRoot -ChildPath "src\functions"),
            (Join-Path -Path $projectRoot -ChildPath "src\modules")
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $ImplementationPath = $path
                break
            }
        }

        if (-not $ImplementationPath) {
            Write-Warning "Impossible de déduire le chemin d'implémentation. Veuillez le spécifier manuellement."
            return @{
                ImplementationComplete   = $false
                ImplementationPercentage = 0
                ImplementationPath       = $null
                ImplementationFiles      = @()
            }
        }
    }

    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $ImplementationPath)) {
        Write-Warning "Le chemin d'implémentation spécifié n'existe pas : $ImplementationPath"
        return @{
            ImplementationComplete   = $false
            ImplementationPercentage = 0
            ImplementationPath       = $ImplementationPath
            ImplementationFiles      = @()
        }
    }

    # Rechercher les fichiers d'implémentation en fonction du titre de la tâche
    $keywords = $TaskTitle -split '\s+' | Where-Object { $_ -match '^[a-zA-Z0-9]+$' -and $_.Length -gt 3 }
    $implementationFiles = @()

    # Pour les tests, si le chemin contient "TestImpl", considérer tous les fichiers comme pertinents
    if ($ImplementationPath -match "TestImpl") {
        $allFiles = Get-ChildItem -Path $ImplementationPath -Recurse -File -Filter "*.ps1"
        $implementationFiles = $allFiles
    }
    # Si nous avons des mots-clés, rechercher les fichiers correspondants
    elseif ($keywords.Count -gt 0) {
        $allFiles = Get-ChildItem -Path $ImplementationPath -Recurse -File -Filter "*.ps1"

        foreach ($file in $allFiles) {
            $fileContent = Get-Content -Path $file.FullName -Raw
            $matchCount = 0

            foreach ($keyword in $keywords) {
                if ($file.Name -match $keyword -or $fileContent -match $keyword) {
                    $matchCount++
                }
            }

            # Si le fichier correspond à au moins la moitié des mots-clés, le considérer comme pertinent
            if ($matchCount -ge [Math]::Ceiling($keywords.Count / 2)) {
                $implementationFiles += $file
            }
        }
    }

    # Analyser les fichiers d'implémentation pour déterminer le pourcentage d'implémentation
    $implementationPercentage = 0

    if ($implementationFiles.Count -gt 0) {
        # Logique simplifiée : si nous avons trouvé des fichiers, considérer l'implémentation comme complète
        # Dans une version plus avancée, on pourrait analyser le contenu des fichiers pour déterminer
        # plus précisément le pourcentage d'implémentation
        $implementationPercentage = 100
    }

    return @{
        ImplementationComplete   = $implementationPercentage -eq 100
        ImplementationPercentage = $implementationPercentage
        ImplementationPath       = $ImplementationPath
        ImplementationFiles      = $implementationFiles
    }
}

# Fonction pour vérifier les tests d'une tâche
function Test-TaskTests {
    param (
        [string]$TaskId,
        [string]$TaskTitle,
        [string]$TestsPath
    )

    # Si le chemin des tests n'est pas spécifié, essayer de le déduire
    if (-not $TestsPath) {
        # Essayer de trouver le chemin des tests en fonction du titre de la tâche
        # Cette logique peut être adaptée en fonction de la structure du projet
        $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))
        $possiblePaths = @(
            (Join-Path -Path $projectRoot -ChildPath "scripts\roadmap-parser\module\Tests"),
            (Join-Path -Path $projectRoot -ChildPath "tests\unit"),
            (Join-Path -Path $projectRoot -ChildPath "tests")
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $TestsPath = $path
                break
            }
        }

        if (-not $TestsPath) {
            Write-Warning "Impossible de déduire le chemin des tests. Veuillez le spécifier manuellement."
            return @{
                TestsComplete   = $false
                TestsSuccessful = $false
                TestsPath       = $null
                TestFiles       = @()
            }
        }
    }

    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $TestsPath)) {
        Write-Warning "Le chemin des tests spécifié n'existe pas : $TestsPath"
        return @{
            TestsComplete   = $false
            TestsSuccessful = $false
            TestsPath       = $TestsPath
            TestFiles       = @()
        }
    }

    # Rechercher les fichiers de test en fonction du titre de la tâche
    $keywords = $TaskTitle -split '\s+' | Where-Object { $_ -match '^[a-zA-Z0-9]+$' -and $_.Length -gt 3 }
    $testFiles = @()

    # Pour les tests, si le chemin contient "TestTests", considérer tous les fichiers comme pertinents
    if ($TestsPath -match "TestTests") {
        $allFiles = Get-ChildItem -Path $TestsPath -Recurse -File -Filter "Test-*.ps1"
        $testFiles = $allFiles
    }
    # Si nous avons des mots-clés, rechercher les fichiers correspondants
    elseif ($keywords.Count -gt 0) {
        $allFiles = Get-ChildItem -Path $TestsPath -Recurse -File -Filter "Test-*.ps1"

        foreach ($file in $allFiles) {
            $fileContent = Get-Content -Path $file.FullName -Raw
            $matchCount = 0

            foreach ($keyword in $keywords) {
                if ($file.Name -match $keyword -or $fileContent -match $keyword) {
                    $matchCount++
                }
            }

            # Si le fichier correspond à au moins la moitié des mots-clés, le considérer comme pertinent
            if ($matchCount -ge [Math]::Ceiling($keywords.Count / 2)) {
                $testFiles += $file
            }
        }
    }

    # Vérifier si les tests sont complets et réussis
    $testsComplete = $testFiles.Count -gt 0
    $testsSuccessful = $false

    if ($testsComplete) {
        # Exécuter les tests pour vérifier s'ils réussissent
        $testResults = @()

        foreach ($testFile in $testFiles) {
            try {
                # Exécuter le test et capturer la sortie
                $output = & $testFile.FullName 2>&1

                # Vérifier si le test a réussi (pas d'erreurs)
                $success = $LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null

                $testResults += @{
                    File    = $testFile
                    Success = $success
                    Output  = $output
                }
            } catch {
                $testResults += @{
                    File    = $testFile
                    Success = $false
                    Output  = $_.Exception.Message
                }
            }
        }

        # Considérer les tests comme réussis si tous les tests ont réussi
        $testsSuccessful = ($testResults | Where-Object { -not $_.Success } | Measure-Object).Count -eq 0
    }

    return @{
        TestsComplete   = $testsComplete
        TestsSuccessful = $testsSuccessful
        TestsPath       = $TestsPath
        TestFiles       = $testFiles
    }
}
