<#
.SYNOPSIS
    Ajoute une information extraite Ã  une collection.
.DESCRIPTION
    Ajoute une ou plusieurs informations extraites Ã  une collection existante.
.PARAMETER Collection
    La collection Ã  laquelle ajouter l'information.
.PARAMETER Info
    L'information extraite Ã  ajouter.
.EXAMPLE
    $collection = New-ExtractedInfoCollection -Name "Emails"
    $info = New-BaseExtractedInfo -Source "Email"
    Add-ExtractedInfoToCollection -Collection $collection -Info $info
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Add-ExtractedInfoToCollection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection,
        
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [hashtable[]]$Info
    )
    
    begin {
        # VÃ©rifier que la collection est valide
        if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
            throw "L'objet fourni n'est pas une collection d'informations extraites valide"
        }
    }
    
    process {
        foreach ($item in $Info) {
            # VÃ©rifier que l'information est valide
            if ($null -eq $item -or -not $item.ContainsKey("_Type")) {
                Write-Warning "Un Ã©lÃ©ment non valide a Ã©tÃ© ignorÃ©"
                continue
            }
            
            # Ajouter l'information Ã  la collection
            $Collection.Items += $item
            
            # Ajouter une mÃ©tadonnÃ©e systÃ¨me pour suivre les modifications
            $Collection.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
            $Collection.Metadata["_ItemCount"] = $Collection.Items.Count
        }
    }
    
    end {
        return $Collection
    }
}
