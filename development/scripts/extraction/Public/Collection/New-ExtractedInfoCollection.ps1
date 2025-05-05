<#
.SYNOPSIS
    CrÃ©e une nouvelle collection d'informations extraites.
.DESCRIPTION
    CrÃ©e un nouvel objet reprÃ©sentant une collection d'informations extraites.
.PARAMETER Name
    Le nom de la collection.
.EXAMPLE
    New-ExtractedInfoCollection -Name "Emails"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function New-ExtractedInfoCollection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Name = "Collection"
    )
    
    # IncrÃ©menter le compteur
    $script:ModuleData.Counters.CollectionCreated++
    
    # CrÃ©er l'objet collection
    $collection = @{
        Name = $Name
        CreatedAt = [datetime]::Now
        Items = @()
        Metadata = @{}
        
        # Type de collection
        _Type = "ExtractedInfoCollection"
    }
    
    # Ajouter des mÃ©tadonnÃ©es systÃ¨me
    $collection.Metadata["_CreatedBy"] = $script:ModuleName
    $collection.Metadata["_CreatedAt"] = [datetime]::Now.ToString("o")
    $collection.Metadata["_Version"] = $script:ModuleVersion
    
    return $collection
}
