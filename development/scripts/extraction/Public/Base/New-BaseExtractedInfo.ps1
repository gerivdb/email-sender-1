<#
.SYNOPSIS
    CrÃ©e une nouvelle information extraite de base.
.DESCRIPTION
    CrÃ©e un nouvel objet reprÃ©sentant une information extraite avec les propriÃ©tÃ©s de base.
.PARAMETER Source
    La source de l'information extraite.
.PARAMETER ExtractorName
    Le nom de l'extracteur qui a produit l'information.
.EXAMPLE
    New-BaseExtractedInfo -Source "Email" -ExtractorName "EmailExtractor"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function New-BaseExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Source = "",
        
        [Parameter(Position = 1)]
        [string]$ExtractorName = ""
    )
    
    # IncrÃ©menter le compteur
    $script:ModuleData.Counters.InfoCreated++
    
    # CrÃ©er l'objet d'information extraite
    $info = @{
        Id = [guid]::NewGuid().ToString()
        Source = $Source
        ExtractedAt = [datetime]::Now
        ExtractorName = $ExtractorName
        Metadata = @{}
        ProcessingState = "Raw"
        ConfidenceScore = 0
        IsValid = $false
        
        # Type d'information
        _Type = "BaseExtractedInfo"
    }
    
    # Ajouter des mÃ©tadonnÃ©es systÃ¨me
    $info.Metadata["_CreatedBy"] = $script:ModuleName
    $info.Metadata["_CreatedAt"] = [datetime]::Now.ToString("o")
    $info.Metadata["_Version"] = $script:ModuleVersion
    
    return $info
}
