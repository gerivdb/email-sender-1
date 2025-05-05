<#
.SYNOPSIS
    Script pour le mode TEST qui permet de tester les fonctionnalitÃƒÂ©s d'un module.

.DESCRIPTION
    Ce script implÃƒÂ©mente le mode TEST qui permet de tester les fonctionnalitÃƒÂ©s d'un module
    en exÃƒÂ©cutant des tests unitaires et d'intÃƒÂ©gration et en gÃƒÂ©nÃƒÂ©rant des rapports de couverture.
    Il fait partie de la suite d'outils RoadmapParser pour la gestion de roadmaps.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ÃƒÂ  traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tÃƒÂ¢che ÃƒÂ  traiter (optionnel). Si non spÃƒÂ©cifiÃƒÂ©, toutes les tÃƒÂ¢ches seront traitÃƒÂ©es.

.PARAMETER OutputPath
    Chemin oÃƒÂ¹ seront gÃƒÂ©nÃƒÂ©rÃƒÂ©s les fichiers de sortie. Par dÃƒÂ©faut, les fichiers sont gÃƒÂ©nÃƒÂ©rÃƒÂ©s dans le rÃƒÂ©pertoire courant.

.PARAMETER ConfigFile
    Chemin vers un fichier de configuration personnalisÃƒÂ©. Si non spÃƒÂ©cifiÃƒÂ©, la configuration par dÃƒÂ©faut sera utilisÃƒÂ©e.

.PARAMETER LogLevel
    Niveau de journalisation ÃƒÂ  utiliser. Les valeurs possibles sont : ERROR, WARNING, INFO, VERBOSE, DEBUG.
    Par dÃƒÂ©faut, le niveau est INFO.

.PARAMETER ModulePath
    Chemin vers le rÃƒÂ©pertoire du module ÃƒÂ  tester.

.PARAMETER TestsPath
    Chemin vers le rÃƒÂ©pertoire contenant les tests ÃƒÂ  exÃƒÂ©cuter.

.PARAMETER CoverageThreshold
    Seuil de couverture de code en pourcentage. Par dÃƒÂ©faut, le seuil est de 80%.

.PARAMETER GenerateReport
    Indique si un rapport de test doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.

.PARAMETER IncludeCodeCoverage
    Indique si la couverture de code doit ÃƒÂªtre incluse dans le rapport.

.PARAMETER TestFramework
    Framework de test ÃƒÂ  utiliser. Les valeurs possibles sont : Pester, NUnit, xUnit.
    Par dÃƒÂ©faut, le framework est Pester.

.PARAMETER ParallelTests
    Indique si les tests doivent ÃƒÂªtre exÃƒÂ©cutÃƒÂ©s en parallÃƒÂ¨le.

.PARAMETER TestCases
    Chemin vers un fichier JSON contenant des cas de test supplÃƒÂ©mentaires.

.EXAMPLE
    .\test-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.1" -OutputPath "output" -ModulePath "module" -TestsPath "tests" -CoverageThreshold 80 -GenerateReport $true

    Traite la tÃƒÂ¢che 1.1 du fichier roadmap.md, teste le module dans le rÃƒÂ©pertoire "module" avec les tests dans le rÃƒÂ©pertoire "tests", vÃƒÂ©rifie que la couverture de code est d'au moins 80% et gÃƒÂ©nÃƒÂ¨re un rapport dans le rÃƒÂ©pertoire "output".

.EXAMPLE
    .\test-mode.ps1 -FilePath "roadmap.md" -ModulePath "module" -TestsPath "tests" -IncludeCodeCoverage $true -TestFramework "Pester" -ParallelTests $true

    Traite toutes les tÃƒÂ¢ches du fichier roadmap.md, teste le module dans le rÃƒÂ©pertoire "module" avec les tests dans le rÃƒÂ©pertoire "tests", inclut la couverture de code dans le rapport et exÃƒÂ©cute les tests en parallÃƒÂ¨le avec le framework Pester.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃƒÂ©ation: 2023-08-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Chemin vers le fichier de roadmap ÃƒÂ  traiter.")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Identifiant de la tÃƒÂ¢che ÃƒÂ  traiter (optionnel).")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin oÃƒÂ¹ seront gÃƒÂ©nÃƒÂ©rÃƒÂ©s les fichiers de sortie.")]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier de configuration personnalisÃƒÂ©.")]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false, HelpMessage = "Niveau de journalisation ÃƒÂ  utiliser.")]
    [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
    [string]$LogLevel = "INFO",

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le rÃƒÂ©pertoire du module ÃƒÂ  tester.")]
    [string]$ModulePath,

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le rÃƒÂ©pertoire contenant les tests ÃƒÂ  exÃƒÂ©cuter.")]
    [string]$TestsPath,

    [Parameter(Mandatory = $false, HelpMessage = "Seuil de couverture de code en pourcentage.")]
    [int]$CoverageThreshold = 80,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si un rapport de test doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.")]
    [bool]$GenerateReport = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si la couverture de code doit ÃƒÂªtre incluse dans le rapport.")]
    [bool]$IncludeCodeCoverage = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Framework de test ÃƒÂ  utiliser.")]
    [ValidateSet("Pester", "NUnit", "xUnit")]
    [string]$TestFramework = "Pester",

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les tests doivent ÃƒÂªtre exÃƒÂ©cutÃƒÂ©s en parallÃƒÂ¨le.")]
    [bool]$ParallelTests = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers un fichier JSON contenant des cas de test supplÃƒÂ©mentaires.")]
    [string]$TestCases,

    [Parameter(Mandatory = $false, HelpMessage = "Active la mise ÃƒÂ  jour automatique des tÃƒÂ¢ches dans le document actif.")]
    [bool]$UpdateTasksInDocument = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document contenant les tÃƒÂ¢ches ÃƒÂ  mettre ÃƒÂ  jour.")]
    [string]$DocumentPath,

    [Parameter(Mandatory = $false, HelpMessage = "Expression rÃƒÂ©guliÃƒÂ¨re pour identifier les tÃƒÂ¢ches.")]
    [string]$TaskIdentifierPattern = "\*\*([0-9.]+)\*\*",

    [Parameter(Mandatory = $false, HelpMessage = "Fichier JSON dÃƒÂ©finissant la correspondance entre tests et tÃƒÂ¢ches.")]
    [string]$TestToTaskMappingFile
)

#region Initialisation

# Chemin vers le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module"

# VÃƒÂ©rifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module RoadmapParser est introuvable ÃƒÂ  l'emplacement : $modulePath"
    exit 1
}

# Importer les fonctions communes
$commonFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\CommonFunctions.ps1"
if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
    Write-Host "Fonctions communes importÃƒÂ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions communes est introuvable ÃƒÂ  l'emplacement : $commonFunctionsPath"
    exit 1
}

# Importer les fonctions de journalisation
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"
if (Test-Path -Path $loggingFunctionsPath) {
    . $loggingFunctionsPath
    Write-Host "Fonctions de journalisation importÃƒÂ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de journalisation est introuvable ÃƒÂ  l'emplacement : $loggingFunctionsPath"
    exit 1
}

# Configurer la journalisation
Set-LoggingLevel -Level $LogLevel

# Importer les fonctions de validation
$validationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ValidationFunctions.ps1"
if (Test-Path -Path $validationFunctionsPath) {
    . $validationFunctionsPath
    Write-Host "Fonctions de validation importÃƒÂ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de validation est introuvable ÃƒÂ  l'emplacement : $validationFunctionsPath"
    exit 1
}

# Importer les fonctions de gestion des erreurs
$errorHandlingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ErrorHandlingFunctions.ps1"
if (Test-Path -Path $errorHandlingFunctionsPath) {
    . $errorHandlingFunctionsPath
    Write-Host "Fonctions de gestion des erreurs importÃƒÂ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de gestion des erreurs est introuvable ÃƒÂ  l'emplacement : $errorHandlingFunctionsPath"
    exit 1
}

# Importer les fonctions de configuration
$configurationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"
if (Test-Path -Path $configurationFunctionsPath) {
    . $configurationFunctionsPath
    Write-Host "Fonctions de configuration importÃƒÂ©es." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonctions de configuration est introuvable ÃƒÂ  l'emplacement : $configurationFunctionsPath"
    exit 1
}

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapTest.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapTest importÃƒÂ©e." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonction du mode est introuvable ÃƒÂ  l'emplacement : $modeFunctionPath"
    exit 1
}

# Fonction pour mettre ÃƒÂ  jour les tÃƒÂ¢ches dans le document actif
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
        # VÃƒÂ©rifier que le document existe
        if (-not (Test-Path -Path $DocumentPath)) {
            Write-LogError "Le document '$DocumentPath' n'existe pas."
            return $false
        }

        # Lire le contenu du document
        $documentContent = Get-Content -Path $DocumentPath -Raw

        # Charger le mapping entre tests et tÃƒÂ¢ches si spÃƒÂ©cifiÃƒÂ©
        $testToTaskMapping = @{}
        if ($TestToTaskMappingFile -and (Test-Path -Path $TestToTaskMappingFile)) {
            $testToTaskMapping = Get-Content -Path $TestToTaskMappingFile -Raw | ConvertFrom-Json -AsHashtable
            Write-LogInfo "Mapping entre tests et tÃƒÂ¢ches chargÃƒÂ© depuis : $TestToTaskMappingFile"
        } else {
            # CrÃƒÂ©er un mapping automatique basÃƒÂ© sur les noms de tests
            Write-LogInfo "CrÃƒÂ©ation automatique du mapping entre tests et tÃƒÂ¢ches..."
            foreach ($test in $TestResults.Tests) {
                if ($test.Name -match $TaskIdentifierPattern) {
                    $taskId = $matches[1]
                    if (-not $testToTaskMapping.ContainsKey($taskId)) {
                        $testToTaskMapping[$taskId] = @()
                    }
                    $testToTaskMapping[$taskId] += $test.Name
                    Write-LogDebug "Test '$($test.Name)' associÃƒÂ© ÃƒÂ  la tÃƒÂ¢che '$taskId'"
                }
            }
        }

        # Analyser les rÃƒÂ©sultats des tests par tÃƒÂ¢che
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

            Write-LogDebug "TÃƒÂ¢che '$taskId' : $passeddevelopment/testing/tests/$totalTests tests rÃƒÂ©ussis, SuccÃƒÂ¨s = $($taskResults[$taskId].Success)"
        }

        # Mettre ÃƒÂ  jour les tÃƒÂ¢ches dans le document
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
                Write-LogInfo "TÃƒÂ¢che '$taskId' marquÃƒÂ©e comme complÃƒÂ©tÃƒÂ©e dans le document."
            } elseif ($taskResult.PassedTests -gt 0) {
                $tasksPartiallyTested += "- [ ] **$taskId** ($($taskResult.PassedTests)/$($taskResult.TotalTests) tests rÃƒÂ©ussis)"
                Write-LogInfo "TÃƒÂ¢che '$taskId' partiellement testÃƒÂ©e : $($taskResult.PassedTests)/$($taskResult.TotalTests) tests rÃƒÂ©ussis."
            }
        }

        # Enregistrer le document mis ÃƒÂ  jour
        $documentContent | Set-Content -Path $DocumentPath -Force
        Write-LogInfo "Document mis ÃƒÂ  jour : $DocumentPath"

        # GÃƒÂ©nÃƒÂ©rer le rapport de mise ÃƒÂ  jour
        $updateReport = @"
## Mise ÃƒÂ  jour des tÃƒÂ¢ches dans le document

Document : $DocumentPath
TÃƒÂ¢ches mises ÃƒÂ  jour : $tasksUpdated

### TÃƒÂ¢ches cochÃƒÂ©es automatiquement

$($tasksFullyTested -join "`n")

### TÃƒÂ¢ches partiellement testÃƒÂ©es

$($tasksPartiallyTested -join "`n")
"@

        # Enregistrer le rapport de mise ÃƒÂ  jour
        $updateReportPath = Join-Path -Path $OutputPath -ChildPath "update-report.md"
        $updateReport | Set-Content -Path $updateReportPath -Force
        Write-LogInfo "Rapport de mise ÃƒÂ  jour gÃƒÂ©nÃƒÂ©rÃƒÂ© : $updateReportPath"

        # Afficher le rapport
        Write-Host "`n$updateReport" -ForegroundColor Cyan

        return $true
    } catch {
        Write-LogError "Erreur lors de la mise ÃƒÂ  jour des tÃƒÂ¢ches dans le document : $_"
        return $false
    }
}

# Charger la configuration
$config = Get-DefaultConfiguration
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    $customConfig = Get-Configuration -ConfigFile $ConfigFile
    $config = Merge-Configuration -DefaultConfig $config -CustomConfig $customConfig
    Write-LogInfo "Configuration personnalisÃƒÂ©e chargÃƒÂ©e depuis : $ConfigFile"
} else {
    Write-LogInfo "Configuration par dÃƒÂ©faut utilisÃƒÂ©e."
}

#endregion

#region Validation des entrÃƒÂ©es

# VÃƒÂ©rifier si le fichier de roadmap existe
Assert-ValidFile -FilePath $FilePath -FileType ".md" -ParameterName "FilePath" -ErrorMessage "Le fichier de roadmap est introuvable ou n'est pas un fichier Markdown : $FilePath"

# VÃƒÂ©rifier si le rÃƒÂ©pertoire du module existe
Assert-ValidDirectory -DirectoryPath $ModulePath -ParameterName "ModulePath" -ErrorMessage "Le rÃƒÂ©pertoire du module est introuvable : $ModulePath"

# VÃƒÂ©rifier si le rÃƒÂ©pertoire des tests existe
Assert-ValidDirectory -DirectoryPath $TestsPath -ParameterName "TestsPath" -ErrorMessage "Le rÃƒÂ©pertoire des tests est introuvable : $TestsPath"

# VÃƒÂ©rifier si le rÃƒÂ©pertoire de sortie existe, sinon le crÃƒÂ©er
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃƒÂ©er le rÃƒÂ©pertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-LogInfo "RÃƒÂ©pertoire de sortie crÃƒÂ©ÃƒÂ© : $OutputPath"
    } else {
        Write-LogWarning "CrÃƒÂ©ation du rÃƒÂ©pertoire de sortie annulÃƒÂ©e : $OutputPath"
        exit 0
    }
}

# VÃƒÂ©rifier si l'identifiant de tÃƒÂ¢che est valide
if ($TaskIdentifier) {
    Assert-ValidTaskIdentifier -TaskIdentifier $TaskIdentifier -ParameterName "TaskIdentifier" -ErrorMessage "L'identifiant de tÃƒÂ¢che n'est pas valide : $TaskIdentifier. Il doit ÃƒÂªtre au format 'X.Y.Z'."
}

# VÃƒÂ©rifier si le fichier de cas de test existe
if ($TestCases) {
    Assert-ValidFile -FilePath $TestCases -FileType ".json" -ParameterName "TestCases" -ErrorMessage "Le fichier de cas de test est introuvable ou n'est pas un fichier JSON : $TestCases"
}

# VÃƒÂ©rifier si le document ÃƒÂ  mettre ÃƒÂ  jour existe
if ($UpdateTasksInDocument -and -not $DocumentPath) {
    Write-LogWarning "Le paramÃƒÂ¨tre DocumentPath est requis lorsque UpdateTasksInDocument est activÃƒÂ©. La mise ÃƒÂ  jour des tÃƒÂ¢ches dans le document sera dÃƒÂ©sactivÃƒÂ©e."
    $UpdateTasksInDocument = $false
} elseif ($UpdateTasksInDocument -and $DocumentPath) {
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-LogWarning "Le document spÃƒÂ©cifiÃƒÂ© n'existe pas : $DocumentPath. La mise ÃƒÂ  jour des tÃƒÂ¢ches dans le document sera dÃƒÂ©sactivÃƒÂ©e."
        $UpdateTasksInDocument = $false
    } elseif (-not $DocumentPath.EndsWith(".md")) {
        Write-LogWarning "Le document spÃƒÂ©cifiÃƒÂ© n'est pas un fichier Markdown : $DocumentPath. La mise ÃƒÂ  jour des tÃƒÂ¢ches dans le document sera dÃƒÂ©sactivÃƒÂ©e."
        $UpdateTasksInDocument = $false
    }
}

# VÃƒÂ©rifier si le fichier de mapping entre tests et tÃƒÂ¢ches existe
if ($TestToTaskMappingFile -and -not (Test-Path -Path $TestToTaskMappingFile)) {
    Write-LogWarning "Le fichier de mapping entre tests et tÃƒÂ¢ches est introuvable : $TestToTaskMappingFile. Le mapping automatique sera utilisÃƒÂ©."
    $TestToTaskMappingFile = ""
}

#endregion

#region Traitement principal

Write-LogInfo "DÃƒÂ©but du traitement du mode TEST."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "TÃƒÂ¢che ÃƒÂ  traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tÃƒÂ¢ches seront traitÃƒÂ©es."
}
Write-LogInfo "RÃƒÂ©pertoire du module : $ModulePath"
Write-LogInfo "RÃƒÂ©pertoire des tests : $TestsPath"
Write-LogInfo "Seuil de couverture : $CoverageThreshold%"
Write-LogInfo "Framework de test : $TestFramework"
Write-LogInfo "RÃƒÂ©pertoire de sortie : $OutputPath"

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

    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapTest", "ExÃƒÂ©cuter avec les paramÃƒÂ¨tres spÃƒÂ©cifiÃƒÂ©s")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapTest @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exÃƒÂ©cution du mode TEST." -ExitOnError $false

        # Traiter les rÃƒÂ©sultats
        if ($result) {
            Write-LogInfo "Traitement terminÃƒÂ© avec succÃƒÂ¨s."

            # Afficher un rÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats
            Write-Host "`nRÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats :" -ForegroundColor Yellow
            Write-Host "  - Nombre de tests exÃƒÂ©cutÃƒÂ©s : $($result.TestCount)" -ForegroundColor Green
            Write-Host "  - Nombre de tests rÃƒÂ©ussis : $($result.PassedCount)" -ForegroundColor Green
            Write-Host "  - Nombre de tests ÃƒÂ©chouÃƒÂ©s : $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { "Green" } else { "Red" })
            Write-Host "  - Nombre de tests ignorÃƒÂ©s : $($result.SkippedCount)" -ForegroundColor $(if ($result.SkippedCount -eq 0) { "Green" } else { "Yellow" })
            Write-Host "  - Couverture de code : $($result.Coverage)%" -ForegroundColor $(if ($result.Coverage -ge $CoverageThreshold) { "Green" } else { "Red" })

            # Afficher les tests ÃƒÂ©chouÃƒÂ©s
            if ($result.FailedTests -and $result.FailedTests.Count -gt 0) {
                Write-Host "`nTests ÃƒÂ©chouÃƒÂ©s :" -ForegroundColor Red
                foreach ($test in $result.FailedTests) {
                    Write-Host "  - $($test.Name) : $($test.Message)" -ForegroundColor Red
                    Write-Host "    Fichier : $($test.File)" -ForegroundColor Gray
                    Write-Host "    Ligne : $($test.Line)" -ForegroundColor Gray
                }
            }

            # Indiquer les fichiers gÃƒÂ©nÃƒÂ©rÃƒÂ©s
            if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
                Write-Host "`nFichiers gÃƒÂ©nÃƒÂ©rÃƒÂ©s :" -ForegroundColor Yellow
                foreach ($file in $result.OutputFiles) {
                    Write-Host "  - $file" -ForegroundColor Gray
                }
            }

            # Mettre ÃƒÂ  jour la roadmap si une tÃƒÂ¢che a ÃƒÂ©tÃƒÂ© spÃƒÂ©cifiÃƒÂ©e
            if ($TaskIdentifier -and $result.Success) {
                if ($PSCmdlet.ShouldProcess("Update-RoadmapTask", "Mettre ÃƒÂ  jour l'ÃƒÂ©tat de la tÃƒÂ¢che $TaskIdentifier")) {
                    Update-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -Completed $true -BackupFile $true
                    Write-LogInfo "TÃƒÂ¢che $TaskIdentifier marquÃƒÂ©e comme complÃƒÂ©tÃƒÂ©e dans la roadmap."
                }
            }

            # Mettre ÃƒÂ  jour les tÃƒÂ¢ches dans le document actif si demandÃƒÂ©
            if ($UpdateTasksInDocument -and $DocumentPath) {
                if ($PSCmdlet.ShouldProcess("Update-TasksInActiveDocument", "Mettre ÃƒÂ  jour les tÃƒÂ¢ches dans le document $DocumentPath")) {
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
                        Write-LogInfo "TÃƒÂ¢ches mises ÃƒÂ  jour avec succÃƒÂ¨s dans le document $DocumentPath."
                    } else {
                        Write-LogWarning "Ãƒâ€°chec de la mise ÃƒÂ  jour des tÃƒÂ¢ches dans le document $DocumentPath."
                    }
                } else {
                    Write-LogWarning "Mise ÃƒÂ  jour des tÃƒÂ¢ches dans le document annulÃƒÂ©e."
                }
            }
        } else {
            Write-LogWarning "Aucun rÃƒÂ©sultat n'a ÃƒÂ©tÃƒÂ© retournÃƒÂ© par la fonction Invoke-RoadmapTest."
        }
    } else {
        Write-LogWarning "ExÃƒÂ©cution de Invoke-RoadmapTest annulÃƒÂ©e."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode TEST." -ExitOnError $true
}

Write-LogInfo "Fin du traitement du mode TEST."

#endregion

# Retourner les rÃƒÂ©sultats
return $result
