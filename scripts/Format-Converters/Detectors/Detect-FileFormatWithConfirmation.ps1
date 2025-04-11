#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte le format d'un fichier avec gestion des cas ambigus.

.DESCRIPTION
    Ce script détecte le format d'un fichier en utilisant des critères avancés et gère les cas ambigus.
    Il combine les fonctionnalités de détection de format améliorée et de gestion des cas ambigus.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER AutoResolve
    Indique si les cas ambigus doivent être résolus automatiquement sans intervention de l'utilisateur.

.PARAMETER ShowDetails
    Indique si les détails de la détection doivent être affichés.

.PARAMETER RememberChoices
    Indique si les choix de l'utilisateur doivent être mémorisés pour les cas similaires.

.PARAMETER ExportResults
    Indique si les résultats doivent être exportés.

.PARAMETER ExportFormat
    Le format d'exportation des résultats. Les valeurs possibles sont : "JSON", "CSV", "HTML".

.PARAMETER OutputPath
    Le chemin où exporter les résultats.

.EXAMPLE
    Detect-FileFormatWithConfirmation -FilePath "C:\path\to\file.txt"
    Détecte le format du fichier spécifié et gère les cas ambigus.

.EXAMPLE
    Detect-FileFormatWithConfirmation -FilePath "C:\path\to\file.txt" -AutoResolve
    Détecte le format du fichier spécifié et résout automatiquement les cas ambigus.

.EXAMPLE
    Detect-FileFormatWithConfirmation -FilePath "C:\path\to\file.txt" -ExportResults -ExportFormat "HTML"
    Détecte le format du fichier spécifié et exporte les résultats au format HTML.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Detect-FileFormatWithConfirmation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoResolve,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails,
        
        [Parameter(Mandatory = $false)]
        [switch]$RememberChoices,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExportResults,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "HTML")]
        [string]$ExportFormat = "HTML",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }
    
    # Gérer les cas ambigus
    $detectionResult = Handle-AmbiguousFormats -FilePath $FilePath -AutoResolve:$AutoResolve -RememberChoices:$RememberChoices -ShowDetails:$ShowDetails
    
    # Afficher les résultats
    if ($ShowDetails) {
        $showParams = @{
            FilePath = $FilePath
            DetectionResult = $detectionResult
            ShowAllFormats = $true
        }
        
        if ($ExportResults) {
            $showParams.ExportFormat = $ExportFormat
            
            if ($OutputPath) {
                $showParams.OutputPath = $OutputPath
            }
        }
        
        Show-FormatDetectionResults @showParams
    }
    
    return $detectionResult
}

# Exporter les fonctions
Export-ModuleMember -Function Detect-FileFormatWithConfirmation
