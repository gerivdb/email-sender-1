<#
.SYNOPSIS
    Script pour le mode DEV-R qui permet d'implémenter les tâches définies dans une roadmap.

.DESCRIPTION
    Ce script implémente le mode DEV-R (Roadmap Delivery) qui permet d'implémenter
    les tâches définies dans une roadmap de manière séquentielle et méthodique.
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

.PARAMETER ProjectPath
    Chemin vers le répertoire du projet.

.PARAMETER TestsPath
    Chemin vers le répertoire des tests.

.PARAMETER AutoCommit
    Indique si les changements doivent être automatiquement commités.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit être mise à jour automatiquement.

.PARAMETER GenerateTests
    Indique si des tests doivent être générés automatiquement.

.EXAMPLE
    .\dev-r-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -OutputPath "output" -ProjectPath "project" -TestsPath "tests"

    Traite la tâche 1.2.3 du fichier roadmap.md, implémente la fonctionnalité dans le répertoire "project", génère les tests dans le répertoire "tests" et génère des rapports dans le répertoire "output".

.EXAMPLE
    .\dev-r-mode.ps1 -FilePath "roadmap.md" -ProjectPath "project" -TestsPath "tests" -AutoCommit $true -UpdateRoadmap $true

    Traite toutes les tâches du fichier roadmap.md, implémente les fonctionnalités dans le répertoire "project", génère les tests dans le répertoire "tests", commit automatiquement les changements et met à jour la roadmap.

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

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le répertoire du projet.")]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le répertoire des tests.")]
    [string]$TestsPath,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les changements doivent être automatiquement commités.")]
    [bool]$AutoCommit = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si la roadmap doit être mise à jour automatiquement.")]
    [bool]$UpdateRoadmap = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si des tests doivent être générés automatiquement.")]
    [bool]$GenerateTests = $true
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
} else {
    Write-Error "Le fichier de fonctions communes est introuvable à l'emplacement : $commonFunctionsPath"
    exit 1
}

# Importer les fonctions de journalisation
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"
if (Test-Path -Path $loggingFunctionsPath) {
    . $loggingFunctionsPath
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
} else {
    Write-Error "Le fichier de fonctions de validation est introuvable à l'emplacement : $validationFunctionsPath"
    exit 1
}

# Importer les fonctions de gestion des erreurs
$errorHandlingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ErrorHandlingFunctions.ps1"
if (Test-Path -Path $errorHandlingFunctionsPath) {
    . $errorHandlingFunctionsPath
} else {
    Write-Error "Le fichier de fonctions de gestion des erreurs est introuvable à l'emplacement : $errorHandlingFunctionsPath"
    exit 1
}

# Importer les fonctions de configuration
$configurationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"
if (Test-Path -Path $configurationFunctionsPath) {
    . $configurationFunctionsPath
} else {
    Write-Error "Le fichier de fonctions de configuration est introuvable à l'emplacement : $configurationFunctionsPath"
    exit 1
}

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapDevelopment.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
} else {
    Write-Error "Le fichier de fonction du mode est introuvable à l'emplacement : $modeFunctionPath"
    exit 1
}

# Charger la configuration
$config = Get-DefaultConfiguration
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    $customConfig = Get-Configuration -ConfigFile $ConfigFile
    $config = Merge-Configuration -DefaultConfig $config -CustomConfig $customConfig
    Write-LogDebug "Configuration personnalisée chargée depuis : $ConfigFile"
} else {
    Write-LogDebug "Configuration par défaut utilisée."
}

#endregion

#region Validation des entrées

# Vérifier si le fichier de roadmap existe
Assert-ValidFile -FilePath $FilePath -FileType ".md" -ParameterName "FilePath" -ErrorMessage "Le fichier de roadmap est introuvable ou n'est pas un fichier Markdown : $FilePath"

# Vérifier si le répertoire du projet existe
Assert-ValidDirectory -DirectoryPath $ProjectPath -ParameterName "ProjectPath" -ErrorMessage "Le répertoire du projet est introuvable : $ProjectPath"

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

#endregion

#region Traitement principal

Write-LogInfo "Début du traitement du mode DEV-R."
# Logs minimaux pour le débogage uniquement
if ($LogLevel -eq "DEBUG") {
    Write-LogDebug "Fichier de roadmap : $FilePath"
    if ($TaskIdentifier) {
        Write-LogDebug "Tâche à traiter : $TaskIdentifier"
    } else {
        Write-LogDebug "Toutes les tâches seront traitées."
    }
    Write-LogDebug "Répertoire du projet : $ProjectPath"
    Write-LogDebug "Répertoire des tests : $TestsPath"
    Write-LogDebug "Répertoire de sortie : $OutputPath"
    Write-LogDebug "Auto-commit : $AutoCommit"
    Write-LogDebug "Mise à jour de la roadmap : $UpdateRoadmap"
    Write-LogDebug "Génération de tests : $GenerateTests"
}

# Appeler la fonction principale du mode
try {
    $params = @{
        FilePath = $FilePath
        ProjectPath = $ProjectPath
        TestsPath = $TestsPath
        OutputPath = $OutputPath
        AutoCommit = $AutoCommit
        UpdateRoadmap = $UpdateRoadmap
        GenerateTests = $GenerateTests
    }

    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }

    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapDevelopment", "Exécuter avec les paramètres spécifiés")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapDevelopment @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exécution du mode DEV-R." -ExitOnError $false

        # Traiter les résultats
        if ($result) {
            # Afficher uniquement les prochaines étapes
            if ($result.NextSteps -and $result.NextSteps.Count -gt 0) {
                Write-Host "`nProchaines étapes :" -ForegroundColor Yellow
                foreach ($step in $result.NextSteps) {
                    Write-Host "  - $step" -ForegroundColor Gray
                }
            }

            # Afficher les tâches échouées (information critique)
            if ($result.FailedTasks -and $result.FailedTasks.Count -gt 0) {
                Write-Host "`nTâches échouées :" -ForegroundColor Red
                foreach ($task in $result.FailedTasks) {
                    Write-Host "  - $($task.Identifier) : $($task.Title)" -ForegroundColor Red
                }
            }
        } else {
            Write-LogWarning "Aucun résultat n'a été retourné par la fonction Invoke-RoadmapDevelopment."
        }
    } else {
        Write-LogWarning "Exécution de Invoke-RoadmapDevelopment annulée."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode DEV-R." -ExitOnError $true
}

# Fin silencieuse pour éviter les verboses inutiles
if ($LogLevel -eq "DEBUG") {
    Write-LogDebug "Fin du traitement du mode DEV-R."
}

#endregion

# Retourner les résultats
return $result
