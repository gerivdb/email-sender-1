<#
.SYNOPSIS
    Script pour le mode MODE_NAME qui MODE_DESCRIPTION.

.DESCRIPTION
    Ce script implémente le mode MODE_NAME qui permet de MODE_DESCRIPTION_LONG.
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

.PARAMETER MODE_PARAM1
    Description du paramètre spécifique au mode.

.PARAMETER MODE_PARAM2
    Description du paramètre spécifique au mode.

.EXAMPLE
    .\mode-name.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.1" -OutputPath "output"

    Traite la tâche 1.1 du fichier roadmap.md et génère les fichiers de sortie dans le répertoire "output".

.EXAMPLE
    .\mode-name.ps1 -FilePath "roadmap.md" -MODE_PARAM1 "Value1" -MODE_PARAM2 "Value2"

    Traite toutes les tâches du fichier roadmap.md avec les paramètres spécifiques au mode.

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
    
    [Parameter(Mandatory = $false, HelpMessage = "Description du paramètre spécifique au mode.")]
    [string]$MODE_PARAM1,
    
    [Parameter(Mandatory = $false, HelpMessage = "Description du paramètre spécifique au mode.")]
    [string]$MODE_PARAM2
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

# Importer la fonction principale du mode
$modeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapModeName.ps1"
if (Test-Path -Path $modeFunctionPath) {
    . $modeFunctionPath
    Write-Host "Fonction Invoke-RoadmapModeName importée." -ForegroundColor Green
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
if (-not (Test-Path -Path $FilePath)) {
    Write-LogError "Le fichier de roadmap est introuvable à l'emplacement : $FilePath"
    exit 1
}

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

#endregion

#region Traitement principal

Write-LogInfo "Début du traitement du mode MODE_NAME."
Write-LogInfo "Fichier de roadmap : $FilePath"
if ($TaskIdentifier) {
    Write-LogInfo "Tâche à traiter : $TaskIdentifier"
} else {
    Write-LogInfo "Toutes les tâches seront traitées."
}
Write-LogInfo "Répertoire de sortie : $OutputPath"

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
    
    if ($PSCmdlet.ShouldProcess("Invoke-RoadmapModeName", "Exécuter avec les paramètres spécifiés")) {
        $result = Invoke-RoadmapModeName @params
        
        # Traiter les résultats
        if ($result) {
            Write-LogInfo "Traitement terminé avec succès."
            
            # Afficher un résumé des résultats
            Write-Host "`nRésumé des résultats :" -ForegroundColor Yellow
            # Afficher les résultats spécifiques au mode
            
            # Indiquer les fichiers générés
            if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
                Write-Host "`nFichiers générés :" -ForegroundColor Yellow
                foreach ($file in $result.OutputFiles) {
                    Write-Host "  - $file" -ForegroundColor Gray
                }
            }
        } else {
            Write-LogWarning "Aucun résultat n'a été retourné par la fonction Invoke-RoadmapModeName."
        }
    } else {
        Write-LogWarning "Exécution de Invoke-RoadmapModeName annulée."
    }
} catch {
    Write-LogError "Une erreur s'est produite lors du traitement : $_"
    Write-LogError $_.ScriptStackTrace
    exit 1
}

Write-LogInfo "Fin du traitement du mode MODE_NAME."

#endregion

# Retourner les résultats
return $result
