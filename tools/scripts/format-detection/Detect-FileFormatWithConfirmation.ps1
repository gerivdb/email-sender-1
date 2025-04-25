#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte le format d'un fichier avec confirmation utilisateur pour les cas ambigus.

.DESCRIPTION
    Ce script détecte le format d'un fichier en utilisant des algorithmes avancés et gère
    les cas ambigus en demandant une confirmation à l'utilisateur. Il peut également afficher
    les résultats détaillés avec les scores de confiance et exporter les résultats dans
    différents formats.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER AmbiguityThreshold
    Le seuil de différence de score en dessous duquel deux formats sont considérés comme ambigus.
    Par défaut, la valeur est de 20 (si la différence entre les deux meilleurs scores est inférieure à 20).

.PARAMETER AutoResolve
    Indique si le script doit tenter de résoudre automatiquement les cas ambigus sans intervention utilisateur.
    Par défaut, cette option est désactivée.

.PARAMETER RememberChoices
    Indique si le script doit mémoriser les choix de l'utilisateur pour des cas similaires.
    Par défaut, cette option est activée.

.PARAMETER ShowDetails
    Indique si le script doit afficher les détails des résultats de détection.
    Par défaut, cette option est activée.

.PARAMETER ExportFormat
    Le format d'exportation des résultats (JSON ou HTML). Par défaut, aucune exportation n'est effectuée.

.PARAMETER OutputPath
    Le chemin du fichier de sortie pour l'exportation. Par défaut, utilise le même nom que le fichier d'entrée
    avec l'extension appropriée.

.EXAMPLE
    .\Detect-FileFormatWithConfirmation.ps1 -FilePath "C:\path\to\file.txt"
    Détecte le format du fichier spécifié et gère les cas ambigus avec confirmation utilisateur.

.EXAMPLE
    .\Detect-FileFormatWithConfirmation.ps1 -FilePath "C:\path\to\file.txt" -AutoResolve -ExportFormat HTML
    Détecte le format du fichier, résout automatiquement les cas ambigus et exporte les résultats au format HTML.

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

# Importer les scripts nécessaires
$handleAmbiguousScript = "$PSScriptRoot\analysis\Handle-AmbiguousFormats.ps1"
$showResultsScript = "$PSScriptRoot\analysis\Show-FormatDetectionResults.ps1"

if (-not (Test-Path -Path $handleAmbiguousScript)) {
    Write-Error "Le script de gestion des cas ambigus '$handleAmbiguousScript' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $showResultsScript)) {
    Write-Error "Le script d'affichage des résultats '$showResultsScript' n'existe pas."
    exit 1
}

# Fonction principale
function Main {
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        exit 1
    }
    
    # Exécuter le script de gestion des cas ambigus
    $result = & $handleAmbiguousScript -FilePath $FilePath -AmbiguityThreshold $AmbiguityThreshold -AutoResolve:$AutoResolve -RememberChoices:$RememberChoices
    
    # Afficher les détails si demandé
    if ($ShowDetails) {
        & $showResultsScript -FilePath $FilePath -DetectionResult $result -ExportFormat $ExportFormat -OutputPath $OutputPath
    }
    else {
        # Afficher uniquement le format détecté
        Write-Host "Format détecté pour '$([System.IO.Path]::GetFileName($FilePath))': $($result.DetectedFormat) (Confiance: $($result.ConfidenceScore)%)" -ForegroundColor Green
        
        # Exporter les résultats si demandé
        if ($ExportFormat -ne "") {
            & $showResultsScript -FilePath $FilePath -DetectionResult $result -ExportFormat $ExportFormat -OutputPath $OutputPath -ShowAllFormats:$false
        }
    }
    
    return $result
}

# Exécuter le script
$result = Main
return $result
