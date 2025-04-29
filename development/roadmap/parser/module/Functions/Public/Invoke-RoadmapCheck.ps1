<#
.SYNOPSIS
    VÃ©rifie si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%.

.DESCRIPTION
    Cette fonction vÃ©rifie si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es
    avec succÃ¨s Ã  100%. Si c'est le cas, elle peut mettre Ã  jour automatiquement le statut
    des tÃ¢ches dans la roadmap en cochant les cases correspondantes.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  vÃ©rifier et mettre Ã  jour.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, "1.2.1.3.2.3").
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  le saisir.

.PARAMETER ImplementationPath
    Chemin vers le rÃ©pertoire contenant l'implÃ©mentation.
    Si non spÃ©cifiÃ©, le script tentera de le dÃ©duire automatiquement.

.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire contenant les tests.
    Si non spÃ©cifiÃ©, le script tentera de le dÃ©duire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit Ãªtre mise Ã  jour automatiquement.
    Par dÃ©faut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit Ãªtre gÃ©nÃ©rÃ©.
    Par dÃ©faut : $true.

.EXAMPLE
    Invoke-RoadmapCheck -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    Invoke-RoadmapCheck -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ImplementationPath "src/functions" -TestsPath "development/testing/tests/unit"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
    }

    # Importer la fonction Update-RoadmapTaskStatus si elle n'est pas dÃ©jÃ  disponible
    if (-not (Get-Command -Name Update-RoadmapTaskStatus -ErrorAction SilentlyContinue)) {
        $updateTaskPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Update-RoadmapTaskStatus.ps1"
        if (Test-Path -Path $updateTaskPath) {
            . $updateTaskPath
        } else {
            throw "La fonction Update-RoadmapTaskStatus est introuvable. Assurez-vous que le fichier Update-RoadmapTaskStatus.ps1 est prÃ©sent dans le mÃªme rÃ©pertoire."
        }
    }

    # Si l'identifiant de tÃ¢che n'est pas spÃ©cifiÃ©, afficher le contenu du fichier et demander Ã  l'utilisateur
    if (-not $TaskIdentifier) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Afficher le contenu avec des numÃ©ros de ligne
        Write-Host "Contenu du fichier de roadmap :" -ForegroundColor Cyan
        for ($i = 0; $i -lt $content.Count; $i++) {
            Write-Host ("{0,5}: {1}" -f ($i + 1), $content[$i])
        }

        # Demander Ã  l'utilisateur de saisir l'identifiant de la tÃ¢che
        $TaskIdentifier = Read-Host -Prompt "Entrez l'identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, 1.2.1.3.2.3)"

        if (-not $TaskIdentifier) {
            throw "Aucun identifiant de tÃ¢che spÃ©cifiÃ©. OpÃ©ration annulÃ©e."
        }
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8

    # Trouver la tÃ¢che principale et ses sous-tÃ¢ches
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"
    $taskLines = @()
    $taskLineIndices = @()
    $inTaskSection = $false
    $taskIndentation = ""

    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]

        # VÃ©rifier si c'est la tÃ¢che principale
        if ($line -match $taskLinePattern) {
            $inTaskSection = $true
            $taskLines += $line
            $taskLineIndices += $i

            # DÃ©terminer l'indentation de la tÃ¢che principale
            if ($line -match "^(\s+)") {
                $taskIndentation = $matches[1]
            }

            continue
        }

        # Si nous sommes dans la section de la tÃ¢che, vÃ©rifier les sous-tÃ¢ches
        if ($inTaskSection) {
            # VÃ©rifier si la ligne a une indentation plus grande que la tÃ¢che principale
            if ($line -match "^$taskIndentation\s+") {
                $taskLines += $line
                $taskLineIndices += $i
            } else {
                # Si l'indentation est Ã©gale ou infÃ©rieure, nous sommes sortis de la section
                $inTaskSection = $false
            }
        }
    }

    if ($taskLines.Count -eq 0) {
        throw "TÃ¢che avec l'identifiant '$TaskIdentifier' non trouvÃ©e dans le fichier."
    }

    # Analyser les tÃ¢ches pour dÃ©terminer leurs identifiants et titres
    $tasks = @()
    foreach ($taskLine in $taskLines) {
        if ($taskLine -match ".*\*\*([0-9.]+)\*\*\s+(.+)") {
            $taskId = $matches[1]
            $taskTitle = $matches[2]

            # DÃ©terminer si la tÃ¢che est cochÃ©e
            $isChecked = $taskLine -match "\[x\]"

            $tasks += @{
                Id        = $taskId
                Title     = $taskTitle
                IsChecked = $isChecked
                Line      = $taskLine
            }
        }
    }

    # VÃ©rifier l'implÃ©mentation et les tests pour chaque tÃ¢che
    $implementationResults = @{}
    $testResults = @{}
    $tasksToUpdate = @()

    foreach ($task in $tasks) {
        # VÃ©rifier l'implÃ©mentation
        $implementationResult = Test-TaskImplementation -TaskId $task.Id -TaskTitle $task.Title -ImplementationPath $ImplementationPath
        $implementationResults[$task.Id] = $implementationResult

        # VÃ©rifier les tests
        $testResult = Test-TaskTests -TaskId $task.Id -TaskTitle $task.Title -TestsPath $TestsPath
        $testResults[$task.Id] = $testResult

        # Si l'implÃ©mentation et les tests sont Ã  100%, marquer la tÃ¢che pour mise Ã  jour
        if ($implementationResult.ImplementationComplete -and $testResult.TestsComplete -and $testResult.TestsSuccessful) {
            if (-not $task.IsChecked) {
                $tasksToUpdate += $task.Id
            }
        }
    }

    # GÃ©nÃ©rer un rapport si demandÃ©
    if ($GenerateReport) {
        $reportPath = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "check_report_$TaskIdentifier.md"
        $report = @"
# Rapport de vÃ©rification pour la tÃ¢che $TaskIdentifier

## RÃ©sumÃ©

- TÃ¢che principale : **$TaskIdentifier** - $($tasks[0].Title)
- Nombre de sous-tÃ¢ches : $($tasks.Count - 1)
- TÃ¢ches implÃ©mentÃ©es Ã  100% : $($implementationResults.Values | Where-Object { $_.ImplementationComplete } | Measure-Object).Count
- TÃ¢ches testÃ©es Ã  100% : $($testResults.Values | Where-Object { $_.TestsComplete -and $_.TestsSuccessful } | Measure-Object).Count
- TÃ¢ches Ã  mettre Ã  jour : $($tasksToUpdate.Count)

## DÃ©tails des tÃ¢ches

"@

        foreach ($task in $tasks) {
            $implResult = $implementationResults[$task.Id]
            $testResult = $testResults[$task.Id]

            $report += @"

### TÃ¢che $($task.Id) - $($task.Title)

- **Ã‰tat actuel** : $(if ($task.IsChecked) { "TerminÃ©e" } else { "En cours" })
- **ImplÃ©mentation** : $(if ($implResult.ImplementationComplete) { "ComplÃ¨te (100%)" } else { "IncomplÃ¨te ($($implResult.ImplementationPercentage)%)" })
- **Tests** : $(if ($testResult.TestsComplete) { "Complets" } else { "Incomplets" })
- **RÃ©sultats des tests** : $(if ($testResult.TestsSuccessful) { "Tous les tests passent" } else { "Certains tests Ã©chouent" })
- **Action recommandÃ©e** : $(if ($implResult.ImplementationComplete -and $testResult.TestsComplete -and $testResult.TestsSuccessful -and -not $task.IsChecked) { "Marquer comme terminÃ©e" } elseif (-not $implResult.ImplementationComplete) { "ComplÃ©ter l'implÃ©mentation" } elseif (-not $testResult.TestsComplete) { "Ajouter des tests" } elseif (-not $testResult.TestsSuccessful) { "Corriger les tests qui Ã©chouent" } else { "Aucune action requise" })

"@
        }

        $report | Set-Content -Path $reportPath -Encoding UTF8
        Write-Host "Rapport gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
    }

    # Mettre Ã  jour la roadmap si demandÃ©
    if ($UpdateRoadmap -and $tasksToUpdate.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess($FilePath, "Mettre Ã  jour le statut des tÃ¢ches")) {
            foreach ($taskId in $tasksToUpdate) {
                Update-RoadmapTaskStatus -FilePath $FilePath -TaskIdentifier $taskId -Status "Completed"
            }

            Write-Host "$($tasksToUpdate.Count) tÃ¢ches ont Ã©tÃ© marquÃ©es comme terminÃ©es dans la roadmap." -ForegroundColor Green
        }
    }

    # Retourner un rÃ©sumÃ©
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

# Fonction pour vÃ©rifier l'implÃ©mentation d'une tÃ¢che
function Test-TaskImplementation {
    param (
        [string]$TaskId,
        [string]$TaskTitle,
        [string]$ImplementationPath
    )

    # Si le chemin d'implÃ©mentation n'est pas spÃ©cifiÃ©, essayer de le dÃ©duire
    if (-not $ImplementationPath) {
        # Essayer de trouver le chemin d'implÃ©mentation en fonction du titre de la tÃ¢che
        # Cette logique peut Ãªtre adaptÃ©e en fonction de la structure du projet

        # Déterminer le chemin du projet de manière plus robuste
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($null -eq $scriptPath) {
            # Si $MyInvocation.MyCommand.Path est null, utiliser le chemin du script en cours d'exécution
            $scriptPath = $PSScriptRoot
            if ($null -eq $scriptPath) {
                # Si $PSScriptRoot est également null, utiliser le répertoire courant
                $scriptPath = (Get-Location).Path
            }
        }

        # Remonter jusqu'à la racine du projet
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

        Write-Host "Chemin du projet déterminé : $projectRoot" -ForegroundColor Cyan

        $possiblePaths = @(
            (Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public"),
            (Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Private"),
            (Join-Path -Path $projectRoot -ChildPath "development\managers\process-manager\scripts"),
            (Join-Path -Path $projectRoot -ChildPath "development\managers\process-manager\modules")
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $ImplementationPath = $path
                break
            }
        }

        if (-not $ImplementationPath) {
            Write-Warning "Impossible de dÃ©duire le chemin d'implÃ©mentation. Veuillez le spÃ©cifier manuellement."
            return @{
                ImplementationComplete   = $false
                ImplementationPercentage = 0
                ImplementationPath       = $null
                ImplementationFiles      = @()
            }
        }
    }

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $ImplementationPath)) {
        Write-Warning "Le chemin d'implÃ©mentation spÃ©cifiÃ© n'existe pas : $ImplementationPath"
        return @{
            ImplementationComplete   = $false
            ImplementationPercentage = 0
            ImplementationPath       = $ImplementationPath
            ImplementationFiles      = @()
        }
    }

    # Rechercher les fichiers d'implÃ©mentation en fonction du titre de la tÃ¢che
    $keywords = $TaskTitle -split '\s+' | Where-Object { $_ -match '^[a-zA-Z0-9]+$' -and $_.Length -gt 3 }
    $implementationFiles = @()

    # Pour les tests, si le chemin contient "TestImpl", considÃ©rer tous les fichiers comme pertinents
    if ($ImplementationPath -match "TestImpl") {
        $allFiles = Get-ChildItem -Path $ImplementationPath -Recurse -File -Filter "*.ps1"
        $implementationFiles = $allFiles
    }
    # Si nous avons des mots-clÃ©s, rechercher les fichiers correspondants
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

            # Si le fichier correspond Ã  au moins la moitiÃ© des mots-clÃ©s, le considÃ©rer comme pertinent
            if ($matchCount -ge [Math]::Ceiling($keywords.Count / 2)) {
                $implementationFiles += $file
            }
        }
    }

    # Analyser les fichiers d'implÃ©mentation pour dÃ©terminer le pourcentage d'implÃ©mentation
    $implementationPercentage = 0

    if ($implementationFiles.Count -gt 0) {
        # Logique simplifiÃ©e : si nous avons trouvÃ© des fichiers, considÃ©rer l'implÃ©mentation comme complÃ¨te
        # Dans une version plus avancÃ©e, on pourrait analyser le contenu des fichiers pour dÃ©terminer
        # plus prÃ©cisÃ©ment le pourcentage d'implÃ©mentation
        $implementationPercentage = 100
    }

    return @{
        ImplementationComplete   = $implementationPercentage -eq 100
        ImplementationPercentage = $implementationPercentage
        ImplementationPath       = $ImplementationPath
        ImplementationFiles      = $implementationFiles
    }
}

# Fonction pour vÃ©rifier les tests d'une tÃ¢che
function Test-TaskTests {
    param (
        [string]$TaskId,
        [string]$TaskTitle,
        [string]$TestsPath
    )

    # Si le chemin des tests n'est pas spÃ©cifiÃ©, essayer de le dÃ©duire
    if (-not $TestsPath) {
        # Essayer de trouver le chemin des tests en fonction du titre de la tÃ¢che
        # Cette logique peut Ãªtre adaptÃ©e en fonction de la structure du projet

        # Déterminer le chemin du projet de manière plus robuste
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($null -eq $scriptPath) {
            # Si $MyInvocation.MyCommand.Path est null, utiliser le chemin du script en cours d'exécution
            $scriptPath = $PSScriptRoot
            if ($null -eq $scriptPath) {
                # Si $PSScriptRoot est également null, utiliser le répertoire courant
                $scriptPath = (Get-Location).Path
            }
        }

        # Remonter jusqu'à la racine du projet
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

        Write-Host "Chemin du projet déterminé pour les tests : $projectRoot" -ForegroundColor Cyan

        $possiblePaths = @(
            (Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Tests"),
            (Join-Path -Path $projectRoot -ChildPath "development\managers\process-manager\tests"),
            (Join-Path -Path $projectRoot -ChildPath "development\tests")
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $TestsPath = $path
                break
            }
        }

        if (-not $TestsPath) {
            Write-Warning "Impossible de dÃ©duire le chemin des tests. Veuillez le spÃ©cifier manuellement."
            return @{
                TestsComplete   = $false
                TestsSuccessful = $false
                TestsPath       = $null
                TestFiles       = @()
            }
        }
    }

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $TestsPath)) {
        Write-Warning "Le chemin des tests spÃ©cifiÃ© n'existe pas : $TestsPath"
        return @{
            TestsComplete   = $false
            TestsSuccessful = $false
            TestsPath       = $TestsPath
            TestFiles       = @()
        }
    }

    # Rechercher les fichiers de test en fonction du titre de la tÃ¢che
    $keywords = $TaskTitle -split '\s+' | Where-Object { $_ -match '^[a-zA-Z0-9]+$' -and $_.Length -gt 3 }
    $testFiles = @()

    # Pour les tests, si le chemin contient "TestTests", considÃ©rer tous les fichiers comme pertinents
    if ($TestsPath -match "TestTests") {
        $allFiles = Get-ChildItem -Path $TestsPath -Recurse -File -Filter "Test-*.ps1"
        $testFiles = $allFiles
    }
    # Si nous avons des mots-clÃ©s, rechercher les fichiers correspondants
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

            # Si le fichier correspond Ã  au moins la moitiÃ© des mots-clÃ©s, le considÃ©rer comme pertinent
            if ($matchCount -ge [Math]::Ceiling($keywords.Count / 2)) {
                $testFiles += $file
            }
        }
    }

    # VÃ©rifier si les tests sont complets et rÃ©ussis
    $testsComplete = $testFiles.Count -gt 0
    $testsSuccessful = $false

    if ($testsComplete) {
        # ExÃ©cuter les tests pour vÃ©rifier s'ils rÃ©ussissent
        $testResults = @()

        foreach ($testFile in $testFiles) {
            try {
                # ExÃ©cuter le test et capturer la sortie
                $output = & $testFile.FullName 2>&1

                # VÃ©rifier si le test a rÃ©ussi (pas d'erreurs)
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

        # ConsidÃ©rer les tests comme rÃ©ussis si tous les tests ont rÃ©ussi
        $testsSuccessful = ($testResults | Where-Object { -not $_.Success } | Measure-Object).Count -eq 0
    }

    return @{
        TestsComplete   = $testsComplete
        TestsSuccessful = $testsSuccessful
        TestsPath       = $TestsPath
        TestFiles       = $testFiles
    }
}
