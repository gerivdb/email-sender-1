<#
.SYNOPSIS
    Script pour le mode MODE_NAME qui MODE_DESCRIPTION.

.DESCRIPTION
    Ce script implÃ©mente le mode MODE_NAME qui permet de MODE_DESCRIPTION_LONG.
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

.PARAMETER MODE_PARAM1
    Description du paramÃ¨tre spÃ©cifique au mode.

.PARAMETER MODE_PARAM2
    Description du paramÃ¨tre spÃ©cifique au mode.

.EXAMPLE
    .\mode-name.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.1" -OutputPath "output"

    Traite la tÃ¢che 1.1 du fichier roadmap.md et gÃ©nÃ¨re les fichiers de sortie dans le rÃ©pertoire "output".

.EXAMPLE
    .\mode-name.ps1 -FilePath "roadmap.md" -MODE_PARAM1 "Value1" -MODE_PARAM2 "Value2"

    Traite toutes les tÃ¢ches du fichier roadmap.md avec les paramÃ¨tres spÃ©cifiques au mode.

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
    
    [Parameter(Mandatory = $false, HelpMessage = "Description du paramÃ¨tre spÃ©cifique au mode.")]
    [string]$MODE_PARAM1,
    
    [Parameter(Mandatory = $false, HelpMessage = "Description du paramÃ¨tre spÃ©cifique au mode.")]
    [string]$MODE_PARAM2
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

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapModeName.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapModeName importÃ©e." -ForegroundColor Green
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
if (-not (Test-Path -Path $FilePath)) {
    Write-LogError "Le fichier de roadmap est introuvable Ã  l'emplacement : $FilePath"
    exit 1
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

#endregion

#region Traitement principal

Write-LogInfo "DÃ©but du traitement du mode MODE_NAME."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "TÃ¢che Ã  traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tÃ¢ches seront traitÃ©es."
}
Write-LogInfo "RÃ©pertoire de sortie : $OutputPath"

# Appeler la fonction principale du mode
try {
    $params = @{
        FilePath = $FilePath
        OutputPath = $OutputPath
    }
    
    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }
    
    if ($MODE_PARAM1) {
        $params.MODE_PARAM1 = $MODE_PARAM1
    }
    
    if ($MODE_PARAM2) {
        $params.MODE_PARAM2 = $MODE_PARAM2
    }
    
    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapModeName", "ExÃ©cuter avec les paramÃ¨tres spÃ©cifiÃ©s")) {
        $result = Invoke-RoadmapModeName @params
        
        # Traiter les rÃ©sultats
        if ($result) {
            Write-LogInfo "Traitement terminÃ© avec succÃ¨s."
            
            # Afficher un rÃ©sumÃ© des rÃ©sultats
            Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Yellow
            # Afficher les rÃ©sultats spÃ©cifiques au mode
            
            # Indiquer les fichiers gÃ©nÃ©rÃ©s
            if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
                Write-Host "`nFichiers gÃ©nÃ©rÃ©s :" -ForegroundColor Yellow
                foreach ($file in $result.OutputFiles) {
                    Write-Host "  - $file" -ForegroundColor Gray
                }
            }
        } else {
            Write-LogWarning "Aucun rÃ©sultat n'a Ã©tÃ© retournÃ© par la fonction Invoke-RoadmapModeName."
        }
    } else {
        Write-LogWarning "ExÃ©cution de Invoke-RoadmapModeName annulÃ©e."
    }
} catch {
    Write-LogError "Une erreur s'est produite lors du traitement : $_"
    Write-LogError $_.ScriptStackTrace
    exit 1
}

Write-LogInfo "Fin du traitement du mode MODE_NAME."

#endregion

# Retourner les rÃ©sultats
return $result
