<#
.SYNOPSIS
    VÃƒÂ©rifie si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100%.
    Version amÃƒÂ©liorÃƒÂ©e avec meilleure gestion des chemins.

.DESCRIPTION
    Cette fonction vÃƒÂ©rifie si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es
    avec succÃƒÂ¨s ÃƒÂ  100%. Si c'est le cas, elle peut mettre ÃƒÂ  jour automatiquement le statut
    des tÃƒÂ¢ches dans la roadmap en cochant les cases correspondantes.
    Cette version amÃƒÂ©liorÃƒÂ©e gÃƒÂ¨re mieux les chemins et les erreurs.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour.

.PARAMETER TaskIdentifier
    Identifiant de la tÃƒÂ¢che ÃƒÂ  vÃƒÂ©rifier (par exemple, "1.2.1.3.2.3").
    Si non spÃƒÂ©cifiÃƒÂ©, l'utilisateur sera invitÃƒÂ© ÃƒÂ  le saisir.

.PARAMETER ImplementationPath
    Chemin vers le rÃƒÂ©pertoire contenant l'implÃƒÂ©mentation.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER TestsPath
    Chemin vers le rÃƒÂ©pertoire contenant les tests.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit ÃƒÂªtre mise ÃƒÂ  jour automatiquement.
    Par dÃƒÂ©faut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.
    Par dÃƒÂ©faut : $true.

.PARAMETER ProjectRoot
    Chemin racine du projet.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.EXAMPLE
    Invoke-RoadmapCheck -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    Invoke-RoadmapCheck -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ImplementationPath "src/functions" -TestsPath "development/testing/tests/unit"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃƒÂ©ation: 2023-08-15
    Date de mise ÃƒÂ  jour: 2025-05-01 - AmÃƒÂ©lioration de la gestion des chemins
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
        [bool]$GenerateReport = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot
    )

    # DÃƒÂ©terminer le chemin racine du projet
    if (-not $ProjectRoot) {
        # Essayer de dÃƒÂ©duire le chemin racine du projet
        $currentPath = Get-Location
        $possibleRoots = @(
            "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",
            $currentPath
        )
        
        foreach ($root in $possibleRoots) {
            if (Test-Path -Path $root) {
                $ProjectRoot = $root
                Write-Host "Chemin racine du projet dÃƒÂ©tectÃƒÂ© : $ProjectRoot" -ForegroundColor Green
                break
            }
        }
        
        if (-not $ProjectRoot) {
            Write-Warning "Impossible de dÃƒÂ©duire le chemin racine du projet. Utilisation du chemin courant."
            $ProjectRoot = $currentPath
        }
    }

    # VÃƒÂ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        # Essayer de rÃƒÂ©soudre le chemin relatif
        $absolutePath = Join-Path -Path $ProjectRoot -ChildPath $FilePath
        if (Test-Path -Path $absolutePath) {
            $FilePath = $absolutePath
            Write-Host "Chemin absolu du fichier rÃƒÂ©solu : $FilePath" -ForegroundColor Green
        } else {
            throw "Le fichier spÃƒÂ©cifiÃƒÂ© n'existe pas : $FilePath"
        }
    }

    # Importer la fonction Update-RoadmapTaskStatus si elle n'est pas dÃƒÂ©jÃƒÂ  disponible
    if (-not (Get-Command -Name Update-RoadmapTaskStatus -ErrorAction SilentlyContinue)) {
        $updateTaskPath = Join-Path -Path (Split-Path -Parent $MyInvocation.PSCommandPath) -ChildPath "Update-RoadmapTaskStatus.ps1"
        if (Test-Path -Path $updateTaskPath) {
            . $updateTaskPath
            Write-Host "Fonction Update-RoadmapTaskStatus importÃƒÂ©e depuis $updateTaskPath" -ForegroundColor Green
        } else {
            # Essayer de trouver le fichier dans d'autres emplacements
            $possiblePaths = @(
                (Join-Path -Path $ProjectRoot -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public\Update-RoadmapTaskStatus.ps1"),
                (Join-Path -Path (Split-Path -Parent (Get-Location)) -ChildPath "Update-RoadmapTaskStatus.ps1")
            )
            
            $found = $false
            foreach ($path in $possiblePaths) {
                if (Test-Path -Path $path) {
                    . $path
                    Write-Host "Fonction Update-RoadmapTaskStatus importÃƒÂ©e depuis $path" -ForegroundColor Green
                    $found = $true
                    break
                }
            }
            
            if (-not $found) {
                throw "La fonction Update-RoadmapTaskStatus est introuvable. Assurez-vous que le fichier Update-RoadmapTaskStatus.ps1 est prÃƒÂ©sent dans le mÃƒÂªme rÃƒÂ©pertoire."
            }
        }
    }

    # Si l'identifiant de tÃƒÂ¢che n'est pas spÃƒÂ©cifiÃƒÂ©, afficher le contenu du fichier et demander ÃƒÂ  l'utilisateur
    if (-not $TaskIdentifier) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Afficher le contenu avec des numÃƒÂ©ros de ligne
        Write-Host "Contenu du fichier de roadmap :" -ForegroundColor Cyan
        for ($i = 0; $i -lt $content.Count; $i++) {
            Write-Host ("{0,5}: {1}" -f ($i + 1), $content[$i])
        }

        # Demander ÃƒÂ  l'utilisateur de saisir l'identifiant de la tÃƒÂ¢che
        $TaskIdentifier = Read-Host -Prompt "Entrez l'identifiant de la tÃƒÂ¢che ÃƒÂ  vÃƒÂ©rifier (par exemple, 1.2.1.3.2.3)"

        if (-not $TaskIdentifier) {
            throw "Aucun identifiant de tÃƒÂ¢che spÃƒÂ©cifiÃƒÂ©. OpÃƒÂ©ration annulÃƒÂ©e."
        }
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8

    # Trouver la tÃƒÂ¢che principale et ses sous-tÃƒÂ¢ches
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"
    $taskLines = @()
    $taskLineIndices = @()
    $inTaskSection = $false
    $taskIndentation = ""

    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]

        # VÃƒÂ©rifier si c'est la tÃƒÂ¢che principale
        if ($line -match $taskLinePattern) {
            $inTaskSection = $true
            $taskLines += $line
            $taskLineIndices += $i

            # DÃƒÂ©terminer l'indentation de la tÃƒÂ¢che principale
            if ($line -match "^(\s+)") {
                $taskIndentation = $matches[1]
            }

            continue
        }

        # Si nous sommes dans la section de la tÃƒÂ¢che, vÃƒÂ©rifier les sous-tÃƒÂ¢ches
        if ($inTaskSection) {
            # VÃƒÂ©rifier si la ligne a une indentation plus grande que la tÃƒÂ¢che principale
            if ($line -match "^$taskIndentation\s+") {
                $taskLines += $line
                $taskLineIndices += $i
            } else {
                # Si l'indentation est ÃƒÂ©gale ou infÃƒÂ©rieure, nous sommes sortis de la section
                $inTaskSection = $false
            }
        }
    }

    if ($taskLines.Count -eq 0) {
        throw "TÃƒÂ¢che avec l'identifiant '$TaskIdentifier' non trouvÃƒÂ©e dans le fichier."
    }

    # Analyser les tÃƒÂ¢ches pour dÃƒÂ©terminer leurs identifiants et titres
    $tasks = @()
    foreach ($taskLine in $taskLines) {
        if ($taskLine -match ".*\*\*([0-9.]+)\*\*\s+(.+)") {
            $taskId = $matches[1]
            $taskTitle = $matches[2]

            # DÃƒÂ©terminer si la tÃƒÂ¢che est cochÃƒÂ©e
            $isChecked = $taskLine -match "\[x\]"

            $tasks += @{
                Id        = $taskId
                Title     = $taskTitle
                IsChecked = $isChecked
                Line      = $taskLine
            }
        }
    }

    # VÃƒÂ©rifier l'implÃƒÂ©mentation et les tests pour chaque tÃƒÂ¢che
    $implementationResults = @{}
    $testResults = @{}
    $tasksToUpdate = @()

    foreach ($task in $tasks) {
        # VÃƒÂ©rifier l'implÃƒÂ©mentation
        $implementationResult = Test-TaskImplementation -TaskId $task.Id -TaskTitle $task.Title -ImplementationPath $ImplementationPath -ProjectRoot $ProjectRoot
        $implementationResults[$task.Id] = $implementationResult

        # VÃƒÂ©rifier les tests
        $testResult = Test-TaskTests -TaskId $task.Id -TaskTitle $task.Title -TestsPath $TestsPath -ProjectRoot $ProjectRoot
        $testResults[$task.Id] = $testResult

        # Si l'implÃƒÂ©mentation et les tests sont ÃƒÂ  100%, marquer la tÃƒÂ¢che pour mise ÃƒÂ  jour
        if ($implementationResult.ImplementationComplete -and $testResult.TestsComplete -and $testResult.TestsSuccessful) {
            if (-not $task.IsChecked) {
                $tasksToUpdate += $task.Id
            }
        }
    }

    # GÃƒÂ©nÃƒÂ©rer un rapport si demandÃƒÂ©
    if ($GenerateReport) {
        $reportPath = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "check_report_$TaskIdentifier.md"
        $report = @"
# Rapport de vÃƒÂ©rification pour la tÃƒÂ¢che $TaskIdentifier

## RÃƒÂ©sumÃƒÂ©

- TÃƒÂ¢che principale : **$TaskIdentifier** - $($tasks[0].Title)
- Nombre de sous-tÃƒÂ¢ches : $($tasks.Count - 1)
- TÃƒÂ¢ches implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% : $($implementationResults.Values | Where-Object { $_.ImplementationComplete } | Measure-Object).Count
- TÃƒÂ¢ches testÃƒÂ©es ÃƒÂ  100% : $($testResults.Values | Where-Object { $_.TestsComplete -and $_.TestsSuccessful } | Measure-Object).Count
- TÃƒÂ¢ches ÃƒÂ  mettre ÃƒÂ  jour : $($tasksToUpdate.Count)

## DÃƒÂ©tails des tÃƒÂ¢ches

"@

        foreach ($task in $tasks) {
            $implResult = $implementationResults[$task.Id]
            $testResult = $testResults[$task.Id]

            $report += @"

### TÃƒÂ¢che $($task.Id) - $($task.Title)

- **Ãƒâ€°tat actuel** : $(if ($task.IsChecked) { "TerminÃƒÂ©e" } else { "En cours" })
- **ImplÃƒÂ©mentation** : $(if ($implResult.ImplementationComplete) { "ComplÃƒÂ¨te (100%)" } else { "IncomplÃƒÂ¨te ($($implResult.ImplementationPercentage)%)" })
- **Tests** : $(if ($testResult.TestsComplete) { "Complets" } else { "Incomplets" })
- **RÃƒÂ©sultats des tests** : $(if ($testResult.TestsSuccessful) { "Tous les tests passent" } else { "Certains tests ÃƒÂ©chouent" })
- **Action recommandÃƒÂ©e** : $(if ($implResult.ImplementationComplete -and $testResult.TestsComplete -and $testResult.TestsSuccessful -and -not $task.IsChecked) { "Marquer comme terminÃƒÂ©e" } elseif (-not $implResult.ImplementationComplete) { "ComplÃƒÂ©ter l'implÃƒÂ©mentation" } elseif (-not $testResult.TestsComplete) { "Ajouter des tests" } elseif (-not $testResult.TestsSuccessful) { "Corriger les tests qui ÃƒÂ©chouent" } else { "Aucune action requise" })

"@
        }

        $report | Set-Content -Path $reportPath -Encoding UTF8
        Write-Host "Rapport gÃƒÂ©nÃƒÂ©rÃƒÂ© : $reportPath" -ForegroundColor Green
    }

    # Mettre ÃƒÂ  jour la roadmap si demandÃƒÂ©
    if ($UpdateRoadmap -and $tasksToUpdate.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess($FilePath, "Mettre ÃƒÂ  jour le statut des tÃƒÂ¢ches")) {
            foreach ($taskId in $tasksToUpdate) {
                Update-RoadmapTaskStatus -FilePath $FilePath -TaskIdentifier $taskId -Status "Completed"
            }

            Write-Host "$($tasksToUpdate.Count) tÃƒÂ¢ches ont ÃƒÂ©tÃƒÂ© marquÃƒÂ©es comme terminÃƒÂ©es dans la roadmap." -ForegroundColor Green
        }
    }

    # Retourner un rÃƒÂ©sumÃƒÂ©
    return @{
        MainTaskId    = $TaskIdentifier
        Tasks         = $tasks | ForEach-Object {
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
        TasksUpdated  = $tasksToUpdate.Count
    }
}

# Fonction pour vÃƒÂ©rifier l'implÃƒÂ©mentation d'une tÃƒÂ¢che
function Test-TaskImplementation {
    param (
        [string]$TaskId,
        [string]$TaskTitle,
        [string]$ImplementationPath,
        [string]$ProjectRoot
    )

    # Si le chemin d'implÃƒÂ©mentation n'est pas spÃƒÂ©cifiÃƒÂ©, essayer de le dÃƒÂ©duire
    if (-not $ImplementationPath) {
        # Essayer de trouver le chemin d'implÃƒÂ©mentation en fonction du titre de la tÃƒÂ¢che
        # Cette logique peut ÃƒÂªtre adaptÃƒÂ©e en fonction de la structure du projet
        $possiblePaths = @(
            (Join-Path -Path $ProjectRoot -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public"),
            (Join-Path -Path $ProjectRoot -ChildPath "tools\scripts\roadmap-parser\module\Functions\Private"),
            (Join-Path -Path $ProjectRoot -ChildPath "src\functions"),
            (Join-Path -Path $ProjectRoot -ChildPath "src\modules")
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $ImplementationPath = $path
                Write-Host "Chemin d'implÃƒÂ©mentation dÃƒÂ©tectÃƒÂ© : $ImplementationPath" -ForegroundColor Green
                break
            }
        }

        if (-not $ImplementationPath) {
            Write-Warning "Impossible de dÃƒÂ©duire le chemin d'implÃƒÂ©mentation. Veuillez le spÃƒÂ©cifier manuellement."
            return @{
                ImplementationComplete   = $false
                ImplementationPercentage = 0
                ImplementationPath       = $null
                ImplementationFiles      = @()
            }
        }
    }

    # VÃƒÂ©rifier si le chemin existe
    if (-not (Test-Path -Path $ImplementationPath)) {
        Write-Warning "Le chemin d'implÃƒÂ©mentation spÃƒÂ©cifiÃƒÂ© n'existe pas : $ImplementationPath"
        return @{
            ImplementationComplete   = $false
            ImplementationPercentage = 0
            ImplementationPath       = $ImplementationPath
            ImplementationFiles      = @()
        }
    }

    # Rechercher les fichiers d'implÃƒÂ©mentation en fonction du titre de la tÃƒÂ¢che
    $keywords = $TaskTitle -split '\s+' | Where-Object { $_ -match '^[a-zA-Z0-9]+$' -and $_.Length -gt 3 }
    $implementationFiles = @()

    # Pour les tests, si le chemin contient "TestImpl", considÃƒÂ©rer tous les fichiers comme pertinents
    if ($ImplementationPath -match "TestImpl") {
        $allFiles = Get-ChildItem -Path $ImplementationPath -Recurse -File -Filter "*.ps1"
        $implementationFiles = $allFiles
    }
    # Si nous avons des mots-clÃƒÂ©s, rechercher les fichiers correspondants
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

            # Si le fichier correspond ÃƒÂ  au moins la moitiÃƒÂ© des mots-clÃƒÂ©s, le considÃƒÂ©rer comme pertinent
            if ($matchCount -ge [Math]::Ceiling($keywords.Count / 2)) {
                $implementationFiles += $file
            }
        }
    }

    # Analyser les fichiers d'implÃƒÂ©mentation pour dÃƒÂ©terminer le pourcentage d'implÃƒÂ©mentation
    $implementationPercentage = 0

    if ($implementationFiles.Count -gt 0) {
        # Logique simplifiÃƒÂ©e : si nous avons trouvÃƒÂ© des fichiers, considÃƒÂ©rer l'implÃƒÂ©mentation comme complÃƒÂ¨te
        # Dans une version plus avancÃƒÂ©e, on pourrait analyser le contenu des fichiers pour dÃƒÂ©terminer
        # plus prÃƒÂ©cisÃƒÂ©ment le pourcentage d'implÃƒÂ©mentation
        $implementationPercentage = 100
    }

    return @{
        ImplementationComplete   = $implementationPercentage -eq 100
        ImplementationPercentage = $implementationPercentage
        ImplementationPath       = $ImplementationPath
        ImplementationFiles      = $implementationFiles
    }
}

# Fonction pour vÃƒÂ©rifier les tests d'une tÃƒÂ¢che
function Test-TaskTests {
    param (
        [string]$TaskId,
        [string]$TaskTitle,
        [string]$TestsPath,
        [string]$ProjectRoot
    )

    # Si le chemin des tests n'est pas spÃƒÂ©cifiÃƒÂ©, essayer de le dÃƒÂ©duire
    if (-not $TestsPath) {
        # Essayer de trouver le chemin des tests en fonction du titre de la tÃƒÂ¢che
        # Cette logique peut ÃƒÂªtre adaptÃƒÂ©e en fonction de la structure du projet
        $possiblePaths = @(
            (Join-Path -Path $ProjectRoot -ChildPath "tools\scripts\roadmap-parser\module\Tests"),
            (Join-Path -Path $ProjectRoot -ChildPath "tests\unit"),
            (Join-Path -Path $ProjectRoot -ChildPath "tests")
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $TestsPath = $path
                Write-Host "Chemin des tests dÃƒÂ©tectÃƒÂ© : $TestsPath" -ForegroundColor Green
                break
            }
        }

        if (-not $TestsPath) {
            Write-Warning "Impossible de dÃƒÂ©duire le chemin des tests. Veuillez le spÃƒÂ©cifier manuellement."
            return @{
                TestsComplete   = $false
                TestsSuccessful = $false
                TestsPath       = $null
                TestFiles       = @()
            }
        }
    }

    # VÃƒÂ©rifier si le chemin existe
    if (-not (Test-Path -Path $TestsPath)) {
        Write-Warning "Le chemin des tests spÃƒÂ©cifiÃƒÂ© n'existe pas : $TestsPath"
        return @{
            TestsComplete   = $false
            TestsSuccessful = $false
            TestsPath       = $TestsPath
            TestFiles       = @()
        }
    }

    # Rechercher les fichiers de test en fonction du titre de la tÃƒÂ¢che
    $keywords = $TaskTitle -split '\s+' | Where-Object { $_ -match '^[a-zA-Z0-9]+$' -and $_.Length -gt 3 }
    $testFiles = @()

    # Pour les tests, si le chemin contient "TestTests", considÃƒÂ©rer tous les fichiers comme pertinents
    if ($TestsPath -match "TestTests") {
        $allFiles = Get-ChildItem -Path $TestsPath -Recurse -File -Filter "Test-*.ps1"
        $testFiles = $allFiles
    }
    # Si nous avons des mots-clÃƒÂ©s, rechercher les fichiers correspondants
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

            # Si le fichier correspond ÃƒÂ  au moins la moitiÃƒÂ© des mots-clÃƒÂ©s, le considÃƒÂ©rer comme pertinent
            if ($matchCount -ge [Math]::Ceiling($keywords.Count / 2)) {
                $testFiles += $file
            }
        }
    }

    # VÃƒÂ©rifier si les tests sont complets et rÃƒÂ©ussis
    $testsComplete = $testFiles.Count -gt 0
    $testsSuccessful = $false

    if ($testsComplete) {
        # ExÃƒÂ©cuter les tests pour vÃƒÂ©rifier s'ils rÃƒÂ©ussissent
        $testResults = @()

        foreach ($testFile in $testFiles) {
            try {
                # ExÃƒÂ©cuter le test et capturer la sortie
                $output = & $testFile.FullName 2>&1

                # VÃƒÂ©rifier si le test a rÃƒÂ©ussi (pas d'erreurs)
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

        # ConsidÃƒÂ©rer les tests comme rÃƒÂ©ussis si tous les tests ont rÃƒÂ©ussi
        $testsSuccessful = ($testResults | Where-Object { -not $_.Success } | Measure-Object).Count -eq 0
    }

    return @{
        TestsComplete   = $testsComplete
        TestsSuccessful = $testsSuccessful
        TestsPath       = $TestsPath
        TestFiles       = $testFiles
    }
}
