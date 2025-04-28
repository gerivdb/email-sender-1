#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tecte le format d'un fichier avec gestion des cas ambigus.

.DESCRIPTION
    Ce script dÃ©tecte le format d'un fichier en utilisant des critÃ¨res avancÃ©s et gÃ¨re les cas ambigus.
    Il combine les fonctionnalitÃ©s de dÃ©tection de format amÃ©liorÃ©e et de gestion des cas ambigus.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER AutoResolve
    Indique si les cas ambigus doivent Ãªtre rÃ©solus automatiquement sans intervention de l'utilisateur.

.PARAMETER ShowDetails
    Indique si les dÃ©tails de la dÃ©tection doivent Ãªtre affichÃ©s.

.PARAMETER RememberChoices
    Indique si les choix de l'utilisateur doivent Ãªtre mÃ©morisÃ©s pour les cas similaires.

.PARAMETER ExportResults
    Indique si les rÃ©sultats doivent Ãªtre exportÃ©s.

.PARAMETER ExportFormat
    Le format d'exportation des rÃ©sultats. Les valeurs possibles sont : "JSON", "CSV", "HTML".

.PARAMETER OutputPath
    Le chemin oÃ¹ exporter les rÃ©sultats.

.EXAMPLE
    Test-FileFormatWithConfirmation -FilePath "C:\path\to\file.txt"
    DÃ©tecte le format du fichier spÃ©cifiÃ© et gÃ¨re les cas ambigus.

.EXAMPLE
    Test-FileFormatWithConfirmation -FilePath "C:\path\to\file.txt" -AutoResolve
    DÃ©tecte le format du fichier spÃ©cifiÃ© et rÃ©sout automatiquement les cas ambigus.

.EXAMPLE
    Test-FileFormatWithConfirmation -FilePath "C:\path\to\file.txt" -ExportResults -ExportFormat "HTML"
    DÃ©tecte le format du fichier spÃ©cifiÃ© et exporte les rÃ©sultats au format HTML.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Test-FileFormatWithConfirmation {
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # GÃ©rer les cas ambigus
    $detectionResult = Handle-AmbiguousFormats -FilePath $FilePath -AutoResolve:$AutoResolve -RememberChoices:$RememberChoices -ShowDetails:$ShowDetails

    # Afficher les rÃ©sultats
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
Export-ModuleMember -Function Test-FileFormatWithConfirmation

