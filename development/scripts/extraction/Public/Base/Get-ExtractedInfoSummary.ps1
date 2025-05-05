<#
.SYNOPSIS
    Obtient un rÃ©sumÃ© d'une information extraite.
.DESCRIPTION
    GÃ©nÃ¨re une chaÃ®ne de caractÃ¨res rÃ©sumant les propriÃ©tÃ©s principales d'une information extraite.
.PARAMETER Info
    L'information extraite dont on veut obtenir le rÃ©sumÃ©.
.EXAMPLE
    $info = New-BaseExtractedInfo -Source "Email" -ExtractorName "EmailExtractor"
    Get-ExtractedInfoSummary -Info $info
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Get-ExtractedInfoSummary {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info
    )
    
    # VÃ©rifier que l'information est valide
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "L'objet fourni n'est pas une information extraite valide"
    }
    
    # GÃ©nÃ©rer le rÃ©sumÃ© en fonction du type d'information
    $summary = "ID: $($Info.Id), Source: $($Info.Source), Extrait le: $($Info.ExtractedAt), Ã‰tat: $($Info.ProcessingState), Confiance: $($Info.ConfidenceScore)%"
    
    # Ajouter des informations spÃ©cifiques selon le type
    switch ($Info._Type) {
        "TextExtractedInfo" {
            $summary += ", Texte: $($Info.CharacterCount) caractÃ¨res, $($Info.WordCount) mots"
        }
        "StructuredDataExtractedInfo" {
            $summary += ", DonnÃ©es: $($Info.DataItemCount) Ã©lÃ©ments, Profondeur max: $($Info.MaxDepth)"
        }
        "MediaExtractedInfo" {
            $sizeKB = [math]::Round($Info.FileSize / 1024, 2)
            $summary += ", MÃ©dia: $($Info.MediaType), Taille: $sizeKB KB, CrÃ©Ã© le: $($Info.FileCreatedDate.ToString('yyyy-MM-dd'))"
        }
    }
    
    return $summary
}
