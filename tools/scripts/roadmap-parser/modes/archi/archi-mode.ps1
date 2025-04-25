<#
.SYNOPSIS
    Script pour le mode ARCHI qui permet de concevoir l'architecture d'un projet.

.DESCRIPTION
    Ce script implémente le mode ARCHI qui permet de concevoir l'architecture d'un projet
    en générant des diagrammes et des documents de conception.
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
    Chemin vers le répertoire du projet à analyser.

.PARAMETER DiagramType
    Type de diagramme à générer. Les valeurs possibles sont : C4, UML, Mermaid.
    Par défaut, le type est C4.

.PARAMETER IncludeComponents
    Indique si les composants doivent être inclus dans les diagrammes.

.PARAMETER IncludeInterfaces
    Indique si les interfaces doivent être incluses dans les diagrammes.

.PARAMETER IncludeDependencies
    Indique si les dépendances doivent être incluses dans les diagrammes.

.EXAMPLE
    .\archi-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.1" -OutputPath "output" -ProjectPath "project" -DiagramType "C4"

    Traite la tâche 1.1 du fichier roadmap.md, analyse le projet dans le répertoire "project" et génère des diagrammes C4 dans le répertoire "output".

.EXAMPLE
    .\archi-mode.ps1 -FilePath "roadmap.md" -ProjectPath "project" -DiagramType "UML" -IncludeComponents $true -IncludeInterfaces $true -IncludeDependencies $true

    Traite toutes les tâches du fichier roadmap.md, analyse le projet dans le répertoire "project" et génère des diagrammes UML complets dans le répertoire courant.

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
    
    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le répertoire du projet à analyser.")]
    [string]$ProjectPath,
    
    [Parameter(Mandatory = $false, HelpMessage = "Type de diagramme à générer.")]
    [ValidateSet("C4", "UML", "Mermaid")]
    [string]$DiagramType = "C4",
    
    [Parameter(Mandatory = $false, HelpMessage = "Indique si les composants doivent être inclus dans les diagrammes.")]
    [bool]$IncludeComponents = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Indique si les interfaces doivent être incluses dans les diagrammes.")]
    [bool]$IncludeInterfaces = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Indique si les dépendances doivent être incluses dans les diagrammes.")]
    [bool]$IncludeDependencies = $true
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
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapArchitecture.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapArchitecture importée." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonction du mode est introuvable à l'emplacement : $modeFunctionPath"
    exit 1
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

# Vérifier si le répertoire du projet existe
Assert-ValidDirectory -DirectoryPath $ProjectPath -ParameterName "ProjectPath" -ErrorMessage "Le répertoire du projet est introuvable : $ProjectPath"

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

Write-LogInfo "Début du traitement du mode ARCHI."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "Tâche à traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tâches seront traitées."
}
Write-LogInfo "Répertoire du projet : $ProjectPath"
Write-LogInfo "Type de diagramme : $DiagramType"
Write-LogInfo "Répertoire de sortie : $OutputPath"

# Appeler la fonction principale du mode
try {
    $params = @{
        FilePath = $FilePath
        ProjectPath = $ProjectPath
        OutputPath = $OutputPath
        DiagramType = $DiagramType
        IncludeComponents = $IncludeComponents
        IncludeInterfaces = $IncludeInterfaces
        IncludeDependencies = $IncludeDependencies
    }
    
    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }
    
    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapArchitecture", "Exécuter avec les paramètres spécifiés")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapArchitecture @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exécution du mode ARCHI." -ExitOnError $false
        
        # Traiter les résultats
        if ($result) {
            Write-LogInfo "Traitement terminé avec succès."
            
            # Afficher un résumé des résultats
            Write-Host "`nRésumé des résultats :" -ForegroundColor Yellow
            Write-Host "  - Nombre de diagrammes générés : $($result.DiagramCount)" -ForegroundColor Green
            Write-Host "  - Nombre de composants analysés : $($result.ComponentCount)" -ForegroundColor Green
            Write-Host "  - Nombre d'interfaces analysées : $($result.InterfaceCount)" -ForegroundColor Green
            Write-Host "  - Nombre de dépendances analysées : $($result.DependencyCount)" -ForegroundColor Green
            
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
        } else {
            Write-LogWarning "Aucun résultat n'a été retourné par la fonction Invoke-RoadmapArchitecture."
        }
    } else {
        Write-LogWarning "Exécution de Invoke-RoadmapArchitecture annulée."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode ARCHI." -ExitOnError $true
}

Write-LogInfo "Fin du traitement du mode ARCHI."

#endregion

# Retourner les résultats
return $result
