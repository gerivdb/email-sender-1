#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tecte le format d'un fichier avec confirmation utilisateur pour les cas ambigus.

.DESCRIPTION
    Ce script dÃ©tecte le format d'un fichier en utilisant des algorithmes avancÃ©s et gÃ¨re
    les cas ambigus en demandant une confirmation Ã  l'utilisateur. Il peut Ã©galement afficher
    les rÃ©sultats dÃ©taillÃ©s avec les scores de confiance et exporter les rÃ©sultats dans
    diffÃ©rents formats.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER AmbiguityThreshold
    Le seuil de diffÃ©rence de score en dessous duquel deux formats sont considÃ©rÃ©s comme ambigus.
    Par dÃ©faut, la valeur est de 20 (si la diffÃ©rence entre les deux meilleurs scores est infÃ©rieure Ã  20).

.PARAMETER AutoResolve
    Indique si le script doit tenter de rÃ©soudre automatiquement les cas ambigus sans intervention utilisateur.
    Par dÃ©faut, cette option est dÃ©sactivÃ©e.

.PARAMETER RememberChoices
    Indique si le script doit mÃ©moriser les choix de l'utilisateur pour des cas similaires.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER ShowDetails
    Indique si le script doit afficher les dÃ©tails des rÃ©sultats de dÃ©tection.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER ExportFormat
    Le format d'exportation des rÃ©sultats (JSON ou HTML). Par dÃ©faut, aucune exportation n'est effectuÃ©e.

.PARAMETER OutputPath
    Le chemin du fichier de sortie pour l'exportation. Par dÃ©faut, utilise le mÃªme nom que le fichier d'entrÃ©e
    avec l'extension appropriÃ©e.

.EXAMPLE
    .\Detect-FileFormatWithConfirmation.ps1 -FilePath "C:\path\to\file.txt"
    DÃ©tecte le format du fichier spÃ©cifiÃ© et gÃ¨re les cas ambigus avec confirmation utilisateur.

.EXAMPLE
    .\Detect-FileFormatWithConfirmation.ps1 -FilePath "C:\path\to\file.txt" -AutoResolve -ExportFormat HTML
    DÃ©tecte le format du fichier, rÃ©sout automatiquement les cas ambigus et exporte les rÃ©sultats au format HTML.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [int]$AmbiguityThreshold = 20,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoResolve,
    
    [Parameter(Mandatory = $false)]
    [switch]$RememberChoices = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowDetails = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "HTML", "")]
    [string]$ExportFormat = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ""
)

# Importer les scripts nÃ©cessaires
$handleAmbiguousScript = "$PSScriptRoot\analysis\Handle-AmbiguousFormats.ps1"
$showResultsScript = "$PSScriptRoot\analysis\Show-FormatDetectionResults.ps1"

if (-not (Test-Path -Path $handleAmbiguousScript)) {
    Write-Error "Le script de gestion des cas ambigus '$handleAmbiguousScript' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $showResultsScript)) {
    Write-Error "Le script d'affichage des rÃ©sultats '$showResultsScript' n'existe pas."
    exit 1
}

# Fonction principale
function Main {
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        exit 1
    }
    
    # ExÃ©cuter le script de gestion des cas ambigus
    $result = & $handleAmbiguousScript -FilePath $FilePath -AmbiguityThreshold $AmbiguityThreshold -AutoResolve:$AutoResolve -RememberChoices:$RememberChoices
    
    # Afficher les dÃ©tails si demandÃ©
    if ($ShowDetails) {
        & $showResultsScript -FilePath $FilePath -DetectionResult $result -ExportFormat $ExportFormat -OutputPath $OutputPath
    }
    else {
        # Afficher uniquement le format dÃ©tectÃ©
        Write-Host "Format dÃ©tectÃ© pour '$([System.IO.Path]::GetFileName($FilePath))': $($result.DetectedFormat) (Confiance: $($result.ConfidenceScore)%)" -ForegroundColor Green
        
        # Exporter les rÃ©sultats si demandÃ©
        if ($ExportFormat -ne "") {
            & $showResultsScript -FilePath $FilePath -DetectionResult $result -ExportFormat $ExportFormat -OutputPath $OutputPath -ShowAllFormats:$false
        }
    }
    
    return $result
}

# ExÃ©cuter le script
$result = Main
return $result
