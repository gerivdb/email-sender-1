<#
.SYNOPSIS
    Script pour le mode TEST qui permet de tester les fonctionnalitÃ©s d'un module.

.DESCRIPTION
    Ce script implÃ©mente le mode TEST qui permet de tester les fonctionnalitÃ©s d'un module
    en exÃ©cutant des tests unitaires et d'intÃ©gration et en gÃ©nÃ©rant des rapports de couverture.
    Il fait partie de la suite d'outils RoadmapParser pour la gestion de roadmaps.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (optionnel). Si non spÃ©cifiÃ©, toutes les tÃ¢ches seront traitÃ©es.

.PARAMETER OutputPath
    Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie. Par dÃ©faut, les fichiers sont gÃ©nÃ©rÃ©s dans le rÃ©pertoire courant.

.PARAMETER ConfigFile
    Chemin vers un fichier de configuration personnalisÃ©. Si non spÃ©cifiÃ©, la configuration par dÃ©faut sera utilisÃ©e.

.PARAMETER LogLevel
    Niveau de journalisation Ã  utiliser. Les valeurs possibles sont : ERROR, WARNING, INFO, VERBOSE, DEBUG.
    Par dÃ©faut, le niveau est INFO.

.PARAMETER ModulePath
    Chemin vers le rÃ©pertoire du module Ã  tester.

.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire contenant les tests Ã  exÃ©cuter.

.PARAMETER CoverageThreshold
    Seuil de couverture de code en pourcentage. Par dÃ©faut, le seuil est de 80%.

.PARAMETER GenerateReport
    Indique si un rapport de test doit Ãªtre gÃ©nÃ©rÃ©.

.PARAMETER IncludeCodeCoverage
    Indique si la couverture de code doit Ãªtre incluse dans le rapport.

.PARAMETER TestFramework
    Framework de test Ã  utiliser. Les valeurs possibles sont : Pester, NUnit, xUnit.
    Par dÃ©faut, le framework est Pester.

.PARAMETER ParallelTests
    Indique si les tests doivent Ãªtre exÃ©cutÃ©s en parallÃ¨le.

.PARAMETER TestCases
    Chemin vers un fichier JSON contenant des cas de test supplÃ©mentaires.

.EXAMPLE
    .\test-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.1" -OutputPath "output" -ModulePath "module" -TestsPath "tests" -CoverageThreshold 80 -GenerateReport $true

    Traite la tÃ¢che 1.1 du fichier roadmap.md, teste le module dans le rÃ©pertoire "module" avec les tests dans le rÃ©pertoire "tests", vÃ©rifie que la couverture de code est d'au moins 80% et gÃ©nÃ¨re un rapport dans le rÃ©pertoire "output".

.EXAMPLE
    .\test-mode.ps1 -FilePath "roadmap.md" -ModulePath "module" -TestsPath "tests" -IncludeCodeCoverage $true -TestFramework "Pester" -ParallelTests $true

    Traite toutes les tÃ¢ches du fichier roadmap.md, teste le module dans le rÃ©pertoire "module" avec les tests dans le rÃ©pertoire "tests", inclut la couverture de code dans le rapport et exÃ©cute les tests en parallÃ¨le avec le framework Pester.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Chemin vers le fichier de roadmap Ã  traiter.")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Identifiant de la tÃ¢che Ã  traiter (optionnel).")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie.")]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier de configuration personnalisÃ©.")]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de journalisation Ã  utiliser.")]
    [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
    [string]$LogLevel = "INFO",

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le rÃ©pertoire du module Ã  tester.")]
    [string]$ModulePath,

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le rÃ©pertoire contenant les tests Ã  exÃ©cuter.")]
    [string]$TestsPath,

    [Parameter(Mandatory = $false, HelpMessage = "Seuil de couverture de code en pourcentage.")]
    [int]$CoverageThreshold = 80,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si un rapport de test doit Ãªtre gÃ©nÃ©rÃ©.")]
    [bool]$GenerateReport = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si la couverture de code doit Ãªtre incluse dans le rapport.")]
    [bool]$IncludeCodeCoverage = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Framework de test Ã  utiliser.")]
    [ValidateSet("Pester", "NUnit", "xUnit")]
    [string]$TestFramework = "Pester",

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les tests doivent Ãªtre exÃ©cutÃ©s en parallÃ¨le.")]
    [bool]$ParallelTests = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier JSON contenant des cas de test supplÃ©mentaires.")]
    [string]$TestCases,

    [Parameter(Mandatory = $false, HelpMessage = "Active la mise Ã  jour automatique des tÃ¢ches dans le document actif.")]
    [bool]$UpdateTasksInDocument = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document contenant les tÃ¢ches Ã  mettre Ã  jour.")]
    [string]$DocumentPath,

    [Parameter(Mandatory = $false, HelpMessage = "Expression rÃ©guliÃ¨re pour identifier les tÃ¢ches.")]
    [string]$TaskIdentifierPattern = "\*\*([0-9.]+)\*\*",

    [Parameter(Mandatory = $false, HelpMessage = "Fichier JSON dÃ©finissant la correspondance entre tests et tÃ¢ches.")]
    [string]$TestToTaskMappingFile
)

#region Initialisation

# Chemin vers le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module RoadmapParser est introuvable Ã  l'emplacement : $modulePath"
    exit 1
}

# Importer les fonctions communes
$commonFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\CommonFunctions.ps1"
if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
    Write-Host "Fonctions communes importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions communes est introuvable Ã  l'emplacement : $commonFunctionsPath"
    exit 1
}

# Importer les fonctions de journalisation
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"
if (Test-Path -Path $loggingFunctionsPath) {
    . $loggingFunctionsPath
    Write-Host "Fonctions de journalisation importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de journalisation est introuvable Ã  l'emplacement : $loggingFunctionsPath"
    exit 1
}

# Configurer la journalisation
Set-LoggingLevel -Level $LogLevel

# Importer les fonctions de validation
$validationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ValidationFunctions.ps1"
if (Test-Path -Path $validationFunctionsPath) {
    . $validationFunctionsPath
    Write-Host "Fonctions de validation importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de validation est introuvable Ã  l'emplacement : $validationFunctionsPath"
    exit 1
}

# Importer les fonctions de gestion des erreurs
$errorHandlingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ErrorHandlingFunctions.ps1"
if (Test-Path -Path $errorHandlingFunctionsPath) {
    . $errorHandlingFunctionsPath
    Write-Host "Fonctions de gestion des erreurs importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de gestion des erreurs est introuvable Ã  l'emplacement : $errorHandlingFunctionsPath"
    exit 1
}

# Importer les fonctions de configuration
$configurationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"
if (Test-Path -Path $configurationFunctionsPath) {
    . $configurationFunctionsPath
    Write-Host "Fonctions de configuration importÃ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de configuration est introuvable Ã  l'emplacement : $configurationFunctionsPath"
    exit 1
}

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapTest.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapTest importÃ©e." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonction du mode est introuvable Ã  l'emplacement : $modeFunctionPath"
    exit 1
}

# Fonction pour mettre Ã  jour les tÃ¢ches dans le document actif
function Update-TasksInActiveDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TestResults,

        [Parameter(Mandatory = $true)]
        [string]$DocumentPath,

        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifierPattern = "\*\*([0-9.]+)\*\*",

        [Parameter(Mandatory = $false)]
        [string]$TestToTaskMappingFile
    )

    try {
        # VÃ©rifier que le document existe
        if (-not (Test-Path -Path $DocumentPath)) {
            Write-LogError "Le document '$DocumentPath' n'existe pas."
            return $false
        }

        # Lire le contenu du document
        $documentContent = Get-Content -Path $DocumentPath -Raw

        # Charger le mapping entre tests et tÃ¢ches si spÃ©cifiÃ©
        $testToTaskMapping = @{}
        if ($TestToTaskMappingFile -and (Test-Path -Path $TestToTaskMappingFile)) {
            $testToTaskMapping = Get-Content -Path $TestToTaskMappingFile -Raw | ConvertFrom-Json -AsHashtable
            Write-LogInfo "Mapping entre tests et tÃ¢ches chargÃ© depuis : $TestToTaskMappingFile"
        } else {
            # CrÃ©er un mapping automatique basÃ© sur les noms de tests
            Write-LogInfo "CrÃ©ation automatique du mapping entre tests et tÃ¢ches..."
            foreach ($test in $TestResults.Tests) {
                if ($test.Name -match $TaskIdentifierPattern) {
                    $taskId = $matches[1]
                    if (-not $testToTaskMapping.ContainsKey($taskId)) {
                        $testToTaskMapping[$taskId] = @()
                    }
                    $testToTaskMapping[$taskId] += $test.Name
                    Write-LogDebug "Test '$($test.Name)' associÃ© Ã  la tÃ¢che '$taskId'"
                }
            }
        }

        # Analyser les rÃ©sultats des tests par tÃ¢che
        $taskResults = @{}
        foreach ($taskId in $testToTaskMapping.Keys) {
            $testsForTask = $testToTaskMapping[$taskId]
            $passedTests = 0
            $totalTests = $testsForTask.Count

            foreach ($testName in $testsForTask) {
                $test = $TestResults.Tests | Where-Object { $_.Name -eq $testName }
                if ($test -and $test.Result -eq 'Passed') {
                    $passedTests++
                }
            }

            $taskResults[$taskId] = @{
                PassedTests = $passedTests
                TotalTests  = $totalTests
                Success     = ($passedTests -eq $totalTests -and $totalTests -gt 0)
            }

            Write-LogDebug "TÃ¢che '$taskId' : $passedTests/$totalTests tests rÃ©ussis, SuccÃ¨s = $($taskResults[$taskId].Success)"
        }

        # Mettre Ã  jour les tÃ¢ches dans le document
        $tasksUpdated = 0
        $tasksPartiallyTested = @()
        $tasksFullyTested = @()

        foreach ($taskId in $taskResults.Keys) {
            $taskResult = $taskResults[$taskId]
            $taskPattern = "- \[ \] \*\*$taskId\*\*"
            $taskReplacement = "- [x] **$taskId**"

            if ($taskResult.Success) {
                $documentContent = $documentContent -replace $taskPattern, $taskReplacement
                $tasksUpdated++
                $tasksFullyTested += "- [x] **$taskId**"
                Write-LogInfo "TÃ¢che '$taskId' marquÃ©e comme complÃ©tÃ©e dans le document."
            } elseif ($taskResult.PassedTests -gt 0) {
                $tasksPartiallyTested += "- [ ] **$taskId** ($($taskResult.PassedTests)/$($taskResult.TotalTests) tests rÃ©ussis)"
                Write-LogInfo "TÃ¢che '$taskId' partiellement testÃ©e : $($taskResult.PassedTests)/$($taskResult.TotalTests) tests rÃ©ussis."
            }
        }

        # Enregistrer le document mis Ã  jour
        $documentContent | Set-Content -Path $DocumentPath -Force
        Write-LogInfo "Document mis Ã  jour : $DocumentPath"

        # GÃ©nÃ©rer le rapport de mise Ã  jour
        $updateReport = @"
## Mise Ã  jour des tÃ¢ches dans le document

Document : $DocumentPath
TÃ¢ches mises Ã  jour : $tasksUpdated

### TÃ¢ches cochÃ©es automatiquement

$($tasksFullyTested -join "`n")

### TÃ¢ches partiellement testÃ©es

$($tasksPartiallyTested -join "`n")
"@

        # Enregistrer le rapport de mise Ã  jour
        $updateReportPath = Join-Path -Path $OutputPath -ChildPath "update-report.md"
        $updateReport | Set-Content -Path $updateReportPath -Force
        Write-LogInfo "Rapport de mise Ã  jour gÃ©nÃ©rÃ© : $updateReportPath"

        # Afficher le rapport
        Write-Host "`n$updateReport" -ForegroundColor Cyan

        return $true
    } catch {
        Write-LogError "Erreur lors de la mise Ã  jour des tÃ¢ches dans le document : $_"
        return $false
    }
}

# Charger la configuration
$config = Get-DefaultConfiguration
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    $customConfig = Get-Configuration -ConfigFile $ConfigFile
    $config = Merge-Configuration -DefaultConfig $config -CustomConfig $customConfig
    Write-LogInfo "Configuration personnalisÃ©e chargÃ©e depuis : $ConfigFile"
} else {
    Write-LogInfo "Configuration par dÃ©faut utilisÃ©e."
}

#endregion

#region Validation des entrÃ©es

# VÃ©rifier si le fichier de roadmap existe
Assert-ValidFile -FilePath $FilePath -FileType ".md" -ParameterName "FilePath" -ErrorMessage "Le fichier de roadmap est introuvable ou n'est pas un fichier Markdown : $FilePath"

# VÃ©rifier si le rÃ©pertoire du module existe
Assert-ValidDirectory -DirectoryPath $ModulePath -ParameterName "ModulePath" -ErrorMessage "Le rÃ©pertoire du module est introuvable : $ModulePath"

# VÃ©rifier si le rÃ©pertoire des tests existe
Assert-ValidDirectory -DirectoryPath $TestsPath -ParameterName "TestsPath" -ErrorMessage "Le rÃ©pertoire des tests est introuvable : $TestsPath"

# VÃ©rifier si le rÃ©pertoire de sortie existe, sinon le crÃ©er
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le rÃ©pertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-LogInfo "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath"
    } else {
        Write-LogWarning "CrÃ©ation du rÃ©pertoire de sortie annulÃ©e : $OutputPath"
        exit 0
    }
}

# VÃ©rifier si l'identifiant de tÃ¢che est valide
if ($TaskIdentifier) {
    Assert-ValidTaskIdentifier -TaskIdentifier $TaskIdentifier -ParameterName "TaskIdentifier" -ErrorMessage "L'identifiant de tÃ¢che n'est pas valide : $TaskIdentifier. Il doit Ãªtre au format 'X.Y.Z'."
}

# VÃ©rifier si le fichier de cas de test existe
if ($TestCases) {
    Assert-ValidFile -FilePath $TestCases -FileType ".json" -ParameterName "TestCases" -ErrorMessage "Le fichier de cas de test est introuvable ou n'est pas un fichier JSON : $TestCases"
}

# VÃ©rifier si le document Ã  mettre Ã  jour existe
if ($UpdateTasksInDocument -and -not $DocumentPath) {
    Write-LogWarning "Le paramÃ¨tre DocumentPath est requis lorsque UpdateTasksInDocument est activÃ©. La mise Ã  jour des tÃ¢ches dans le document sera dÃ©sactivÃ©e."
    $UpdateTasksInDocument = $false
} elseif ($UpdateTasksInDocument -and $DocumentPath) {
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-LogWarning "Le document spÃ©cifiÃ© n'existe pas : $DocumentPath. La mise Ã  jour des tÃ¢ches dans le document sera dÃ©sactivÃ©e."
        $UpdateTasksInDocument = $false
    } elseif (-not $DocumentPath.EndsWith(".md")) {
        Write-LogWarning "Le document spÃ©cifiÃ© n'est pas un fichier Markdown : $DocumentPath. La mise Ã  jour des tÃ¢ches dans le document sera dÃ©sactivÃ©e."
        $UpdateTasksInDocument = $false
    }
}

# VÃ©rifier si le fichier de mapping entre tests et tÃ¢ches existe
if ($TestToTaskMappingFile -and -not (Test-Path -Path $TestToTaskMappingFile)) {
    Write-LogWarning "Le fichier de mapping entre tests et tÃ¢ches est introuvable : $TestToTaskMappingFile. Le mapping automatique sera utilisÃ©."
    $TestToTaskMappingFile = ""
}

#endregion

#region Traitement principal

Write-LogInfo "DÃ©but du traitement du mode TEST."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "TÃ¢che Ã  traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tÃ¢ches seront traitÃ©es."
}
Write-LogInfo "RÃ©pertoire du module : $ModulePath"
Write-LogInfo "RÃ©pertoire des tests : $TestsPath"
Write-LogInfo "Seuil de couverture : $CoverageThreshold%"
Write-LogInfo "Framework de test : $TestFramework"
Write-LogInfo "RÃ©pertoire de sortie : $OutputPath"

# Appeler la fonction principale du mode
try {
    $params = @{
        FilePath            = $FilePath
        ModulePath          = $ModulePath
        TestsPath           = $TestsPath
        OutputPath          = $OutputPath
        CoverageThreshold   = $CoverageThreshold
        GenerateReport      = $GenerateReport
        IncludeCodeCoverage = $IncludeCodeCoverage
        TestFramework       = $TestFramework
        ParallelTests       = $ParallelTests
    }

    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }

    if ($TestCases) {
        $params.TestCases = $TestCases
    }

    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapTest", "ExÃ©cuter avec les paramÃ¨tres spÃ©cifiÃ©s")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapTest @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exÃ©cution du mode TEST." -ExitOnError $false

        # Traiter les rÃ©sultats
        if ($result) {
            Write-LogInfo "Traitement terminÃ© avec succÃ¨s."

            # Afficher un rÃ©sumÃ© des rÃ©sultats
            Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Yellow
            Write-Host "  - Nombre de tests exÃ©cutÃ©s : $($result.TestCount)" -ForegroundColor Green
            Write-Host "  - Nombre de tests rÃ©ussis : $($result.PassedCount)" -ForegroundColor Green
            Write-Host "  - Nombre de tests Ã©chouÃ©s : $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { "Green" } else { "Red" })
            Write-Host "  - Nombre de tests ignorÃ©s : $($result.SkippedCount)" -ForegroundColor $(if ($result.SkippedCount -eq 0) { "Green" } else { "Yellow" })
            Write-Host "  - Couverture de code : $($result.Coverage)%" -ForegroundColor $(if ($result.Coverage -ge $CoverageThreshold) { "Green" } else { "Red" })

            # Afficher les tests Ã©chouÃ©s
            if ($result.FailedTests -and $result.FailedTests.Count -gt 0) {
                Write-Host "`nTests Ã©chouÃ©s :" -ForegroundColor Red
                foreach ($test in $result.FailedTests) {
                    Write-Host "  - $($test.Name) : $($test.Message)" -ForegroundColor Red
                    Write-Host "    Fichier : $($test.File)" -ForegroundColor Gray
                    Write-Host "    Ligne : $($test.Line)" -ForegroundColor Gray
                }
            }

            # Indiquer les fichiers gÃ©nÃ©rÃ©s
            if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
                Write-Host "`nFichiers gÃ©nÃ©rÃ©s :" -ForegroundColor Yellow
                foreach ($file in $result.OutputFiles) {
                    Write-Host "  - $file" -ForegroundColor Gray
                }
            }

            # Mettre Ã  jour la roadmap si une tÃ¢che a Ã©tÃ© spÃ©cifiÃ©e
            if ($TaskIdentifier -and $result.Success) {
                if ($PSCmdlet.ShouldProcess("Update-RoadmapTask", "Mettre Ã  jour l'Ã©tat de la tÃ¢che $TaskIdentifier")) {
                    Update-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -Completed $true -BackupFile $true
                    Write-LogInfo "TÃ¢che $TaskIdentifier marquÃ©e comme complÃ©tÃ©e dans la roadmap."
                }
            }

            # Mettre Ã  jour les tÃ¢ches dans le document actif si demandÃ©
            if ($UpdateTasksInDocument -and $DocumentPath) {
                if ($PSCmdlet.ShouldProcess("Update-TasksInActiveDocument", "Mettre Ã  jour les tÃ¢ches dans le document $DocumentPath")) {
                    $updateParams = @{
                        TestResults           = $result
                        DocumentPath          = $DocumentPath
                        TaskIdentifierPattern = $TaskIdentifierPattern
                    }

                    if ($TestToTaskMappingFile) {
                        $updateParams.TestToTaskMappingFile = $TestToTaskMappingFile
                    }

                    $updateResult = Update-TasksInActiveDocument @updateParams
                    if ($updateResult) {
                        Write-LogInfo "TÃ¢ches mises Ã  jour avec succÃ¨s dans le document $DocumentPath."
                    } else {
                        Write-LogWarning "Ã‰chec de la mise Ã  jour des tÃ¢ches dans le document $DocumentPath."
                    }
                } else {
                    Write-LogWarning "Mise Ã  jour des tÃ¢ches dans le document annulÃ©e."
                }
            }
        } else {
            Write-LogWarning "Aucun rÃ©sultat n'a Ã©tÃ© retournÃ© par la fonction Invoke-RoadmapTest."
        }
    } else {
        Write-LogWarning "ExÃ©cution de Invoke-RoadmapTest annulÃ©e."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode TEST." -ExitOnError $true
}

Write-LogInfo "Fin du traitement du mode TEST."

#endregion

# Retourner les rÃ©sultats
return $result
