<#
.SYNOPSIS
    Script pour le mode TEST qui permet de tester les fonctionnalités d'un module.

.DESCRIPTION
    Ce script implémente le mode TEST qui permet de tester les fonctionnalités d'un module
    en exécutant des tests unitaires et d'intégration et en générant des rapports de couverture.
    Il fait partie de la suite d'outils RoadmapParser pour la gestion de roadmaps.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à traiter (optionnel). Si non spécifié, toutes les tâches seront traitées.

.PARAMETER OutputPath
    Chemin où seront générés les fichiers de sortie. Par défaut, les fichiers sont générés dans le répertoire courant.

.PARAMETER ConfigFile
    Chemin vers un fichier de configuration personnalisé. Si non spécifié, la configuration par défaut sera utilisée.

.PARAMETER LogLevel
    Niveau de journalisation à utiliser. Les valeurs possibles sont : ERROR, WARNING, INFO, VERBOSE, DEBUG.
    Par défaut, le niveau est INFO.

.PARAMETER ModulePath
    Chemin vers le répertoire du module à tester.

.PARAMETER TestsPath
    Chemin vers le répertoire contenant les tests à exécuter.

.PARAMETER CoverageThreshold
    Seuil de couverture de code en pourcentage. Par défaut, le seuil est de 80%.

.PARAMETER GenerateReport
    Indique si un rapport de test doit être généré.

.PARAMETER IncludeCodeCoverage
    Indique si la couverture de code doit être incluse dans le rapport.

.PARAMETER TestFramework
    Framework de test à utiliser. Les valeurs possibles sont : Pester, NUnit, xUnit.
    Par défaut, le framework est Pester.

.PARAMETER ParallelTests
    Indique si les tests doivent être exécutés en parallèle.

.PARAMETER TestCases
    Chemin vers un fichier JSON contenant des cas de test supplémentaires.

.EXAMPLE
    .\test-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.1" -OutputPath "output" -ModulePath "module" -TestsPath "tests" -CoverageThreshold 80 -GenerateReport $true

    Traite la tâche 1.1 du fichier roadmap.md, teste le module dans le répertoire "module" avec les tests dans le répertoire "tests", vérifie que la couverture de code est d'au moins 80% et génère un rapport dans le répertoire "output".

.EXAMPLE
    .\test-mode.ps1 -FilePath "roadmap.md" -ModulePath "module" -TestsPath "tests" -IncludeCodeCoverage $true -TestFramework "Pester" -ParallelTests $true

    Traite toutes les tâches du fichier roadmap.md, teste le module dans le répertoire "module" avec les tests dans le répertoire "tests", inclut la couverture de code dans le rapport et exécute les tests en parallèle avec le framework Pester.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Chemin vers le fichier de roadmap à traiter.")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Identifiant de la tâche à traiter (optionnel).")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin où seront générés les fichiers de sortie.")]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier de configuration personnalisé.")]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de journalisation à utiliser.")]
    [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
    [string]$LogLevel = "INFO",

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le répertoire du module à tester.")]
    [string]$ModulePath,

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le répertoire contenant les tests à exécuter.")]
    [string]$TestsPath,

    [Parameter(Mandatory = $false, HelpMessage = "Seuil de couverture de code en pourcentage.")]
    [int]$CoverageThreshold = 80,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si un rapport de test doit être généré.")]
    [bool]$GenerateReport = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si la couverture de code doit être incluse dans le rapport.")]
    [bool]$IncludeCodeCoverage = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Framework de test à utiliser.")]
    [ValidateSet("Pester", "NUnit", "xUnit")]
    [string]$TestFramework = "Pester",

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les tests doivent être exécutés en parallèle.")]
    [bool]$ParallelTests = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier JSON contenant des cas de test supplémentaires.")]
    [string]$TestCases,

    [Parameter(Mandatory = $false, HelpMessage = "Active la mise à jour automatique des tâches dans le document actif.")]
    [bool]$UpdateTasksInDocument = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document contenant les tâches à mettre à jour.")]
    [string]$DocumentPath,

    [Parameter(Mandatory = $false, HelpMessage = "Expression régulière pour identifier les tâches.")]
    [string]$TaskIdentifierPattern = "\*\*([0-9.]+)\*\*",

    [Parameter(Mandatory = $false, HelpMessage = "Fichier JSON définissant la correspondance entre tests et tâches.")]
    [string]$TestToTaskMappingFile
)

#region Initialisation

# Chemin vers le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module RoadmapParser est introuvable à l'emplacement : $modulePath"
    exit 1
}

# Importer les fonctions communes
$commonFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\CommonFunctions.ps1"
if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
    Write-Host "Fonctions communes importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions communes est introuvable à l'emplacement : $commonFunctionsPath"
    exit 1
}

# Importer les fonctions de journalisation
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"
if (Test-Path -Path $loggingFunctionsPath) {
    . $loggingFunctionsPath
    Write-Host "Fonctions de journalisation importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de journalisation est introuvable à l'emplacement : $loggingFunctionsPath"
    exit 1
}

# Configurer la journalisation
Set-LoggingLevel -Level $LogLevel

# Importer les fonctions de validation
$validationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ValidationFunctions.ps1"
if (Test-Path -Path $validationFunctionsPath) {
    . $validationFunctionsPath
    Write-Host "Fonctions de validation importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de validation est introuvable à l'emplacement : $validationFunctionsPath"
    exit 1
}

# Importer les fonctions de gestion des erreurs
$errorHandlingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ErrorHandlingFunctions.ps1"
if (Test-Path -Path $errorHandlingFunctionsPath) {
    . $errorHandlingFunctionsPath
    Write-Host "Fonctions de gestion des erreurs importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de gestion des erreurs est introuvable à l'emplacement : $errorHandlingFunctionsPath"
    exit 1
}

# Importer les fonctions de configuration
$configurationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"
if (Test-Path -Path $configurationFunctionsPath) {
    . $configurationFunctionsPath
    Write-Host "Fonctions de configuration importées." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de configuration est introuvable à l'emplacement : $configurationFunctionsPath"
    exit 1
}

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapTest.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapTest importée." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonction du mode est introuvable à l'emplacement : $modeFunctionPath"
    exit 1
}

# Fonction pour mettre à jour les tâches dans le document actif
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
        # Vérifier que le document existe
        if (-not (Test-Path -Path $DocumentPath)) {
            Write-LogError "Le document '$DocumentPath' n'existe pas."
            return $false
        }

        # Lire le contenu du document
        $documentContent = Get-Content -Path $DocumentPath -Raw

        # Charger le mapping entre tests et tâches si spécifié
        $testToTaskMapping = @{}
        if ($TestToTaskMappingFile -and (Test-Path -Path $TestToTaskMappingFile)) {
            $testToTaskMapping = Get-Content -Path $TestToTaskMappingFile -Raw | ConvertFrom-Json -AsHashtable
            Write-LogInfo "Mapping entre tests et tâches chargé depuis : $TestToTaskMappingFile"
        } else {
            # Créer un mapping automatique basé sur les noms de tests
            Write-LogInfo "Création automatique du mapping entre tests et tâches..."
            foreach ($test in $TestResults.Tests) {
                if ($test.Name -match $TaskIdentifierPattern) {
                    $taskId = $matches[1]
                    if (-not $testToTaskMapping.ContainsKey($taskId)) {
                        $testToTaskMapping[$taskId] = @()
                    }
                    $testToTaskMapping[$taskId] += $test.Name
                    Write-LogDebug "Test '$($test.Name)' associé à la tâche '$taskId'"
                }
            }
        }

        # Analyser les résultats des tests par tâche
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

            Write-LogDebug "Tâche '$taskId' : $passedTests/$totalTests tests réussis, Succès = $($taskResults[$taskId].Success)"
        }

        # Mettre à jour les tâches dans le document
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
                Write-LogInfo "Tâche '$taskId' marquée comme complétée dans le document."
            } elseif ($taskResult.PassedTests -gt 0) {
                $tasksPartiallyTested += "- [ ] **$taskId** ($($taskResult.PassedTests)/$($taskResult.TotalTests) tests réussis)"
                Write-LogInfo "Tâche '$taskId' partiellement testée : $($taskResult.PassedTests)/$($taskResult.TotalTests) tests réussis."
            }
        }

        # Enregistrer le document mis à jour
        $documentContent | Set-Content -Path $DocumentPath -Force
        Write-LogInfo "Document mis à jour : $DocumentPath"

        # Générer le rapport de mise à jour
        $updateReport = @"
## Mise à jour des tâches dans le document

Document : $DocumentPath
Tâches mises à jour : $tasksUpdated

### Tâches cochées automatiquement

$($tasksFullyTested -join "`n")

### Tâches partiellement testées

$($tasksPartiallyTested -join "`n")
"@

        # Enregistrer le rapport de mise à jour
        $updateReportPath = Join-Path -Path $OutputPath -ChildPath "update-report.md"
        $updateReport | Set-Content -Path $updateReportPath -Force
        Write-LogInfo "Rapport de mise à jour généré : $updateReportPath"

        # Afficher le rapport
        Write-Host "`n$updateReport" -ForegroundColor Cyan

        return $true
    } catch {
        Write-LogError "Erreur lors de la mise à jour des tâches dans le document : $_"
        return $false
    }
}

# Charger la configuration
$config = Get-DefaultConfiguration
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    $customConfig = Get-Configuration -ConfigFile $ConfigFile
    $config = Merge-Configuration -DefaultConfig $config -CustomConfig $customConfig
    Write-LogInfo "Configuration personnalisée chargée depuis : $ConfigFile"
} else {
    Write-LogInfo "Configuration par défaut utilisée."
}

#endregion

#region Validation des entrées

# Vérifier si le fichier de roadmap existe
Assert-ValidFile -FilePath $FilePath -FileType ".md" -ParameterName "FilePath" -ErrorMessage "Le fichier de roadmap est introuvable ou n'est pas un fichier Markdown : $FilePath"

# Vérifier si le répertoire du module existe
Assert-ValidDirectory -DirectoryPath $ModulePath -ParameterName "ModulePath" -ErrorMessage "Le répertoire du module est introuvable : $ModulePath"

# Vérifier si le répertoire des tests existe
Assert-ValidDirectory -DirectoryPath $TestsPath -ParameterName "TestsPath" -ErrorMessage "Le répertoire des tests est introuvable : $TestsPath"

# Vérifier si le répertoire de sortie existe, sinon le créer
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le répertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-LogInfo "Répertoire de sortie créé : $OutputPath"
    } else {
        Write-LogWarning "Création du répertoire de sortie annulée : $OutputPath"
        exit 0
    }
}

# Vérifier si l'identifiant de tâche est valide
if ($TaskIdentifier) {
    Assert-ValidTaskIdentifier -TaskIdentifier $TaskIdentifier -ParameterName "TaskIdentifier" -ErrorMessage "L'identifiant de tâche n'est pas valide : $TaskIdentifier. Il doit être au format 'X.Y.Z'."
}

# Vérifier si le fichier de cas de test existe
if ($TestCases) {
    Assert-ValidFile -FilePath $TestCases -FileType ".json" -ParameterName "TestCases" -ErrorMessage "Le fichier de cas de test est introuvable ou n'est pas un fichier JSON : $TestCases"
}

# Vérifier si le document à mettre à jour existe
if ($UpdateTasksInDocument -and -not $DocumentPath) {
    Write-LogWarning "Le paramètre DocumentPath est requis lorsque UpdateTasksInDocument est activé. La mise à jour des tâches dans le document sera désactivée."
    $UpdateTasksInDocument = $false
} elseif ($UpdateTasksInDocument -and $DocumentPath) {
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-LogWarning "Le document spécifié n'existe pas : $DocumentPath. La mise à jour des tâches dans le document sera désactivée."
        $UpdateTasksInDocument = $false
    } elseif (-not $DocumentPath.EndsWith(".md")) {
        Write-LogWarning "Le document spécifié n'est pas un fichier Markdown : $DocumentPath. La mise à jour des tâches dans le document sera désactivée."
        $UpdateTasksInDocument = $false
    }
}

# Vérifier si le fichier de mapping entre tests et tâches existe
if ($TestToTaskMappingFile -and -not (Test-Path -Path $TestToTaskMappingFile)) {
    Write-LogWarning "Le fichier de mapping entre tests et tâches est introuvable : $TestToTaskMappingFile. Le mapping automatique sera utilisé."
    $TestToTaskMappingFile = ""
}

#endregion

#region Traitement principal

Write-LogInfo "Début du traitement du mode TEST."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "Tâche à traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tâches seront traitées."
}
Write-LogInfo "Répertoire du module : $ModulePath"
Write-LogInfo "Répertoire des tests : $TestsPath"
Write-LogInfo "Seuil de couverture : $CoverageThreshold%"
Write-LogInfo "Framework de test : $TestFramework"
Write-LogInfo "Répertoire de sortie : $OutputPath"

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

    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapTest", "Exécuter avec les paramètres spécifiés")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapTest @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exécution du mode TEST." -ExitOnError $false

        # Traiter les résultats
        if ($result) {
            Write-LogInfo "Traitement terminé avec succès."

            # Afficher un résumé des résultats
            Write-Host "`nRésumé des résultats :" -ForegroundColor Yellow
            Write-Host "  - Nombre de tests exécutés : $($result.TestCount)" -ForegroundColor Green
            Write-Host "  - Nombre de tests réussis : $($result.PassedCount)" -ForegroundColor Green
            Write-Host "  - Nombre de tests échoués : $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { "Green" } else { "Red" })
            Write-Host "  - Nombre de tests ignorés : $($result.SkippedCount)" -ForegroundColor $(if ($result.SkippedCount -eq 0) { "Green" } else { "Yellow" })
            Write-Host "  - Couverture de code : $($result.Coverage)%" -ForegroundColor $(if ($result.Coverage -ge $CoverageThreshold) { "Green" } else { "Red" })

            # Afficher les tests échoués
            if ($result.FailedTests -and $result.FailedTests.Count -gt 0) {
                Write-Host "`nTests échoués :" -ForegroundColor Red
                foreach ($test in $result.FailedTests) {
                    Write-Host "  - $($test.Name) : $($test.Message)" -ForegroundColor Red
                    Write-Host "    Fichier : $($test.File)" -ForegroundColor Gray
                    Write-Host "    Ligne : $($test.Line)" -ForegroundColor Gray
                }
            }

            # Indiquer les fichiers générés
            if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
                Write-Host "`nFichiers générés :" -ForegroundColor Yellow
                foreach ($file in $result.OutputFiles) {
                    Write-Host "  - $file" -ForegroundColor Gray
                }
            }

            # Mettre à jour la roadmap si une tâche a été spécifiée
            if ($TaskIdentifier -and $result.Success) {
                if ($PSCmdlet.ShouldProcess("Update-RoadmapTask", "Mettre à jour l'état de la tâche $TaskIdentifier")) {
                    Update-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -Completed $true -BackupFile $true
                    Write-LogInfo "Tâche $TaskIdentifier marquée comme complétée dans la roadmap."
                }
            }

            # Mettre à jour les tâches dans le document actif si demandé
            if ($UpdateTasksInDocument -and $DocumentPath) {
                if ($PSCmdlet.ShouldProcess("Update-TasksInActiveDocument", "Mettre à jour les tâches dans le document $DocumentPath")) {
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
                        Write-LogInfo "Tâches mises à jour avec succès dans le document $DocumentPath."
                    } else {
                        Write-LogWarning "Échec de la mise à jour des tâches dans le document $DocumentPath."
                    }
                } else {
                    Write-LogWarning "Mise à jour des tâches dans le document annulée."
                }
            }
        } else {
            Write-LogWarning "Aucun résultat n'a été retourné par la fonction Invoke-RoadmapTest."
        }
    } else {
        Write-LogWarning "Exécution de Invoke-RoadmapTest annulée."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode TEST." -ExitOnError $true
}

Write-LogInfo "Fin du traitement du mode TEST."

#endregion

# Retourner les résultats
return $result
