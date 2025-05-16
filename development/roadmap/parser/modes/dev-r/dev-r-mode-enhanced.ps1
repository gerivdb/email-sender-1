<#
.SYNOPSIS
    Script amÃ©liorÃ© pour le mode DEV-R qui permet d'implÃ©menter les tÃ¢ches dÃ©finies dans une roadmap.

.DESCRIPTION
    Ce script implÃ©mente le mode DEV-R (Roadmap Delivery) amÃ©liorÃ© qui permet d'implÃ©menter
    les tÃ¢ches dÃ©finies dans une roadmap de maniÃ¨re sÃ©quentielle et mÃ©thodique.
    Il prend en charge le traitement de la sÃ©lection actuelle dans le document et
    peut traiter les tÃ¢ches enfants avant les tÃ¢ches parentes.

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

.PARAMETER ProjectPath
    Chemin vers le rÃ©pertoire du projet.

.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire des tests.

.PARAMETER AutoCommit
    Indique si les changements doivent Ãªtre automatiquement commitÃ©s.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit Ãªtre mise Ã  jour automatiquement.

.PARAMETER GenerateTests
    Indique si des tests doivent Ãªtre gÃ©nÃ©rÃ©s automatiquement.

.PARAMETER ProcessSelection
    Indique si le script doit traiter la sÃ©lection actuelle dans le document.

.PARAMETER Selection
    La sÃ©lection de texte Ã  traiter si ProcessSelection est activÃ©.

.PARAMETER ChildrenFirst
    Indique si les tÃ¢ches enfants doivent Ãªtre traitÃ©es avant les tÃ¢ches parentes.

.PARAMETER StepByStep
    Indique si les tÃ¢ches doivent Ãªtre traitÃ©es une par une avec une pause entre chaque tÃ¢che.

.EXAMPLE
    .\dev-r-mode-enhanced.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -OutputPath "output" -ProjectPath "project" -TestsPath "tests"

    Traite la tÃ¢che 1.2.3 du fichier roadmap.md, implÃ©mente la fonctionnalitÃ© dans le rÃ©pertoire "project", gÃ©nÃ¨re les tests dans le rÃ©pertoire "tests" et gÃ©nÃ¨re des rapports dans le rÃ©pertoire "output".

.EXAMPLE
    .\dev-r-mode-enhanced.ps1 -FilePath "roadmap.md" -ProjectPath "project" -TestsPath "tests" -AutoCommit $true -UpdateRoadmap $true

    Traite toutes les tÃ¢ches du fichier roadmap.md, implÃ©mente les fonctionnalitÃ©s dans le rÃ©pertoire "project", gÃ©nÃ¨re les tests dans le rÃ©pertoire "tests", commit automatiquement les changements et met Ã  jour la roadmap.

.EXAMPLE
    .\dev-r-mode-enhanced.ps1 -FilePath "roadmap.md" -ProcessSelection -Selection "- [ ] 1.1 TÃ¢che parent`n  - [ ] 1.1.1 TÃ¢che enfant" -ChildrenFirst -StepByStep

    Traite la sÃ©lection spÃ©cifiÃ©e en commenÃ§ant par les tÃ¢ches enfants, avec une pause entre chaque tÃ¢che.

.NOTES
    Auteur: RoadmapParser Team
    Version: 2.0
    Date de crÃ©ation: 2025-05-16
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

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le rÃ©pertoire du projet.")]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le rÃ©pertoire des tests.")]
    [string]$TestsPath,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les changements doivent Ãªtre automatiquement commitÃ©s.")]
    [bool]$AutoCommit = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si la roadmap doit Ãªtre mise Ã  jour automatiquement.")]
    [bool]$UpdateRoadmap = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si des tests doivent Ãªtre gÃ©nÃ©rÃ©s automatiquement.")]
    [bool]$GenerateTests = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si le script doit traiter la sÃ©lection actuelle dans le document.")]
    [switch]$ProcessSelection,

    [Parameter(Mandatory = $false, HelpMessage = "La sÃ©lection de texte Ã  traiter si ProcessSelection est activÃ©.")]
    [string]$Selection,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les tÃ¢ches enfants doivent Ãªtre traitÃ©es avant les tÃ¢ches parentes.")]
    [switch]$ChildrenFirst,

    [Parameter(Mandatory = $false, HelpMessage = "Indique si les tÃ¢ches doivent Ãªtre traitÃ©es une par une avec une pause entre chaque tÃ¢che.")]
    [switch]$StepByStep
)

#region Initialisation

# Chemin vers le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "..\..\module"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module RoadmapParser est introuvable Ã  l'emplacement : $modulePath"
    exit 1
}

# Importer les fonctions communes
$commonFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\CommonFunctions.ps1"
if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
} else {
    Write-Error "Le fichier de fonctions communes est introuvable Ã  l'emplacement : $commonFunctionsPath"
    exit 1
}

# Importer les fonctions de journalisation
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"
if (Test-Path -Path $loggingFunctionsPath) {
    . $loggingFunctionsPath
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
} else {
    Write-Error "Le fichier de fonctions de validation est introuvable Ã  l'emplacement : $validationFunctionsPath"
    exit 1
}

# Importer les fonctions de gestion des erreurs
$errorHandlingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ErrorHandlingFunctions.ps1"
if (Test-Path -Path $errorHandlingFunctionsPath) {
    . $errorHandlingFunctionsPath
} else {
    Write-Error "Le fichier de fonctions de gestion des erreurs est introuvable Ã  l'emplacement : $errorHandlingFunctionsPath"
    exit 1
}

# Importer les fonctions de configuration
$configurationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\ConfigurationFunctions.ps1"
if (Test-Path -Path $configurationFunctionsPath) {
    . $configurationFunctionsPath
} else {
    Write-Error "Le fichier de fonctions de configuration est introuvable Ã  l'emplacement : $configurationFunctionsPath"
    exit 1
}

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapDevelopment.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
} else {
    Write-Error "Le fichier de fonction du mode est introuvable Ã  l'emplacement : $modeFunctionPath"
    exit 1
}

# Importer les nouvelles fonctions pour le traitement de la sÃ©lection
$selectionFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Get-TasksFromSelection.ps1"
if (Test-Path -Path $selectionFunctionPath) {
    . $selectionFunctionPath
} else {
    Write-Error "Le fichier de fonction pour le traitement de la sÃ©lection est introuvable Ã  l'emplacement : $selectionFunctionPath"
    exit 1
}

$taskProcessingFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-TasksProcessing.ps1"
if (Test-Path -Path $taskProcessingFunctionPath) {
    . $taskProcessingFunctionPath
} else {
    Write-Error "Le fichier de fonction pour le traitement des tÃ¢ches est introuvable Ã  l'emplacement : $taskProcessingFunctionPath"
    exit 1
}

# Charger la configuration
$config = Get-DefaultConfiguration
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    $customConfig = Get-Configuration -ConfigFile $ConfigFile
    $config = Merge-Configuration -DefaultConfig $config -CustomConfig $customConfig
    Write-LogDebug "Configuration personnalisÃ©e chargÃ©e depuis : $ConfigFile"
} else {
    Write-LogDebug "Configuration par dÃ©faut utilisÃ©e."
}

#endregion

#region Validation des entrÃ©es

# VÃ©rifier si le fichier de roadmap existe
Assert-ValidFile -FilePath $FilePath -FileType ".md" -ParameterName "FilePath" -ErrorMessage "Le fichier de roadmap est introuvable ou n'est pas un fichier Markdown : $FilePath"

# VÃ©rifier si le rÃ©pertoire du projet est spÃ©cifiÃ© et existe
if ($ProjectPath) {
    Assert-ValidDirectory -DirectoryPath $ProjectPath -ParameterName "ProjectPath" -ErrorMessage "Le rÃ©pertoire du projet est introuvable : $ProjectPath"
}

# VÃ©rifier si le rÃ©pertoire des tests est spÃ©cifiÃ© et existe
if ($TestsPath) {
    Assert-ValidDirectory -DirectoryPath $TestsPath -ParameterName "TestsPath" -ErrorMessage "Le rÃ©pertoire des tests est introuvable : $TestsPath"
}

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

# VÃ©rifier si la sÃ©lection est spÃ©cifiÃ©e lorsque ProcessSelection est activÃ©
if ($ProcessSelection -and -not $Selection) {
    Write-Error "La sÃ©lection doit Ãªtre spÃ©cifiÃ©e lorsque ProcessSelection est activÃ©."
    exit 1
}

#endregion

#region Traitement principal

Write-LogInfo "DÃ©but du traitement du mode DEV-R amÃ©liorÃ©."

# Logs minimaux pour le dÃ©bogage uniquement
if ($LogLevel -eq "DEBUG") {
    Write-LogDebug "Fichier de roadmap : $FilePath"
    if ($TaskIdentifier) {
        Write-LogDebug "TÃ¢che Ã  traiter : $TaskIdentifier"
    } else {
        Write-LogDebug "Toutes les tÃ¢ches seront traitÃ©es."
    }
    if ($ProcessSelection) {
        Write-LogDebug "Traitement de la sÃ©lection activÃ©."
        Write-LogDebug "SÃ©lection : $Selection"
    }
    if ($ProjectPath) {
        Write-LogDebug "RÃ©pertoire du projet : $ProjectPath"
    }
    if ($TestsPath) {
        Write-LogDebug "RÃ©pertoire des tests : $TestsPath"
    }
    Write-LogDebug "RÃ©pertoire de sortie : $OutputPath"
    Write-LogDebug "Auto-commit : $AutoCommit"
    Write-LogDebug "Mise Ã  jour de la roadmap : $UpdateRoadmap"
    Write-LogDebug "GÃ©nÃ©ration de tests : $GenerateTests"
    Write-LogDebug "Traitement des tÃ¢ches enfants d'abord : $ChildrenFirst"
    Write-LogDebug "Traitement pas Ã  pas : $StepByStep"
}

try {
    # Traiter la sÃ©lection si demandÃ©
    if ($ProcessSelection) {
        Write-LogInfo "Traitement de la sÃ©lection..."
        
        # Extraire les tÃ¢ches de la sÃ©lection
        $tasks = Get-TasksFromSelection -Selection $Selection -IdentifyChildren -SortByHierarchy
        
        if ($tasks.Count -eq 0) {
            Write-LogWarning "Aucune tÃ¢che trouvÃ©e dans la sÃ©lection."
            exit 0
        }
        
        Write-LogInfo "Nombre de tÃ¢ches trouvÃ©es dans la sÃ©lection : $($tasks.Count)"
        
        # DÃ©finir la fonction de traitement
        $processFunction = {
            param($task)
            
            Write-Host "Traitement de la tÃ¢che : $($task.Id) - $($task.Content)" -ForegroundColor Cyan
            
            # ParamÃ¨tres pour Invoke-RoadmapDevelopment
            $params = @{
                FilePath = $FilePath
                TaskIdentifier = $task.Id
            }
            
            if ($ProjectPath) {
                $params.ProjectPath = $ProjectPath
            }
            
            if ($TestsPath) {
                $params.TestsPath = $TestsPath
            }
            
            $params.OutputPath = $OutputPath
            $params.AutoCommit = $AutoCommit
            $params.UpdateRoadmap = $UpdateRoadmap
            $params.GenerateTests = $GenerateTests
            
            # ExÃ©cuter Invoke-RoadmapDevelopment pour cette tÃ¢che
            $taskResult = Invoke-WithErrorHandling -Action {
                Invoke-RoadmapDevelopment @params
            } -ErrorMessage "Une erreur s'est produite lors du traitement de la tÃ¢che $($task.Id)." -ExitOnError $false
            
            return $taskResult
        }
        
        # Traiter les tÃ¢ches
        $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction -ChildrenFirst:$ChildrenFirst -StepByStep:$StepByStep
    }
    else {
        # Traitement standard avec Invoke-RoadmapDevelopment
        $params = @{
            FilePath = $FilePath
            OutputPath = $OutputPath
            AutoCommit = $AutoCommit
            UpdateRoadmap = $UpdateRoadmap
            GenerateTests = $GenerateTests
        }
        
        if ($ProjectPath) {
            $params.ProjectPath = $ProjectPath
        }
        
        if ($TestsPath) {
            $params.TestsPath = $TestsPath
        }
        
        if ($TaskIdentifier) {
            $params.TaskIdentifier = $TaskIdentifier
        }
        
        if ($PSCmdlet.ShouldProcess("Invoke-RoadmapDevelopment", "ExÃ©cuter avec les paramÃ¨tres spÃ©cifiÃ©s")) {
            $result = Invoke-WithErrorHandling -Action {
                Invoke-RoadmapDevelopment @params
            } -ErrorMessage "Une erreur s'est produite lors de l'exÃ©cution du mode DEV-R." -ExitOnError $false
        }
    }
    
    # Traiter les rÃ©sultats
    if ($result) {
        # Afficher uniquement les prochaines Ã©tapes
        if ($result.NextSteps -and $result.NextSteps.Count -gt 0) {
            Write-Host "`nProchaines Ã©tapes :" -ForegroundColor Yellow
            foreach ($step in $result.NextSteps) {
                Write-Host "  - $step" -ForegroundColor Gray
            }
        }
        
        # Afficher les tÃ¢ches Ã©chouÃ©es (information critique)
        if ($result.FailedTasks -and $result.FailedTasks.Count -gt 0) {
            Write-Host "`nTÃ¢ches Ã©chouÃ©es :" -ForegroundColor Red
            foreach ($task in $result.FailedTasks) {
                Write-Host "  - $($task.Identifier) : $($task.Title)" -ForegroundColor Red
            }
        }
    } else {
        Write-LogWarning "Aucun rÃ©sultat n'a Ã©tÃ© retournÃ©."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode DEV-R amÃ©liorÃ©." -ExitOnError $true
}

# Fin silencieuse pour Ã©viter les verboses inutiles
if ($LogLevel -eq "DEBUG") {
    Write-LogDebug "Fin du traitement du mode DEV-R amÃ©liorÃ©."
}

#endregion

# Retourner les rÃ©sultats
return $result
