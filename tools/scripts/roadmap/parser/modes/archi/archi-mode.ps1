<#
.SYNOPSIS
    Script pour le mode ARCHI qui permet de concevoir l'architecture d'un projet.

.DESCRIPTION
    Ce script implÃ©mente le mode ARCHI qui permet de concevoir l'architecture d'un projet
    en gÃ©nÃ©rant des diagrammes et des documents de conception.
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

.PARAMETER ProjectPath
    Chemin vers le rÃ©pertoire du projet Ã  analyser.

.PARAMETER DiagramType
    Type de diagramme Ã  gÃ©nÃ©rer. Les valeurs possibles sont : C4, UML, Mermaid.
    Par dÃ©faut, le type est C4.

.PARAMETER IncludeComponents
    Indique si les composants doivent Ãªtre inclus dans les diagrammes.

.PARAMETER IncludeInterfaces
    Indique si les interfaces doivent Ãªtre incluses dans les diagrammes.

.PARAMETER IncludeDependencies
    Indique si les dÃ©pendances doivent Ãªtre incluses dans les diagrammes.

.EXAMPLE
    .\archi-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.1" -OutputPath "output" -ProjectPath "project" -DiagramType "C4"

    Traite la tÃ¢che 1.1 du fichier roadmap.md, analyse le projet dans le rÃ©pertoire "project" et gÃ©nÃ¨re des diagrammes C4 dans le rÃ©pertoire "output".

.EXAMPLE
    .\archi-mode.ps1 -FilePath "roadmap.md" -ProjectPath "project" -DiagramType "UML" -IncludeComponents $true -IncludeInterfaces $true -IncludeDependencies $true

    Traite toutes les tÃ¢ches du fichier roadmap.md, analyse le projet dans le rÃ©pertoire "project" et gÃ©nÃ¨re des diagrammes UML complets dans le rÃ©pertoire courant.

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
    
    [Parameter(Mandatory = $true, HelpMessage = "Chemin vers le rÃ©pertoire du projet Ã  analyser.")]
    [string]$ProjectPath,
    
    [Parameter(Mandatory = $false, HelpMessage = "Type de diagramme Ã  gÃ©nÃ©rer.")]
    [ValidateSet("C4", "UML", "Mermaid")]
    [string]$DiagramType = "C4",
    
    [Parameter(Mandatory = $false, HelpMessage = "Indique si les composants doivent Ãªtre inclus dans les diagrammes.")]
    [bool]$IncludeComponents = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Indique si les interfaces doivent Ãªtre incluses dans les diagrammes.")]
    [bool]$IncludeInterfaces = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Indique si les dÃ©pendances doivent Ãªtre incluses dans les diagrammes.")]
    [bool]$IncludeDependencies = $true
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
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapArchitecture.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapArchitecture importÃ©e." -ForegroundColor Green
} else {
    Write-Error "Le fichier de fonction du mode est introuvable Ã  l'emplacement : $modeFunctionPath"
    exit 1
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

# VÃ©rifier si le rÃ©pertoire du projet existe
Assert-ValidDirectory -DirectoryPath $ProjectPath -ParameterName "ProjectPath" -ErrorMessage "Le rÃ©pertoire du projet est introuvable : $ProjectPath"

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

#endregion

#region Traitement principal

Write-LogInfo "DÃ©but du traitement du mode ARCHI."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "TÃ¢che Ã  traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tÃ¢ches seront traitÃ©es."
}
Write-LogInfo "RÃ©pertoire du projet : $ProjectPath"
Write-LogInfo "Type de diagramme : $DiagramType"
Write-LogInfo "RÃ©pertoire de sortie : $OutputPath"

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
    
    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapArchitecture", "ExÃ©cuter avec les paramÃ¨tres spÃ©cifiÃ©s")) {
        $result = Invoke-WithErrorHandling -Action {
            Invoke-RoadmapArchitecture @params
        } -ErrorMessage "Une erreur s'est produite lors de l'exÃ©cution du mode ARCHI." -ExitOnError $false
        
        # Traiter les rÃ©sultats
        if ($result) {
            Write-LogInfo "Traitement terminÃ© avec succÃ¨s."
            
            # Afficher un rÃ©sumÃ© des rÃ©sultats
            Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Yellow
            Write-Host "  - Nombre de diagrammes gÃ©nÃ©rÃ©s : $($result.DiagramCount)" -ForegroundColor Green
            Write-Host "  - Nombre de composants analysÃ©s : $($result.ComponentCount)" -ForegroundColor Green
            Write-Host "  - Nombre d'interfaces analysÃ©es : $($result.InterfaceCount)" -ForegroundColor Green
            Write-Host "  - Nombre de dÃ©pendances analysÃ©es : $($result.DependencyCount)" -ForegroundColor Green
            
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
        } else {
            Write-LogWarning "Aucun rÃ©sultat n'a Ã©tÃ© retournÃ© par la fonction Invoke-RoadmapArchitecture."
        }
    } else {
        Write-LogWarning "ExÃ©cution de Invoke-RoadmapArchitecture annulÃ©e."
    }
} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement du mode ARCHI." -ExitOnError $true
}

Write-LogInfo "Fin du traitement du mode ARCHI."

#endregion

# Retourner les rÃ©sultats
return $result
