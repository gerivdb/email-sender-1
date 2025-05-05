<#
.SYNOPSIS
    Supprime une information extraite d'une collection.
.DESCRIPTION
    Supprime une information extraite d'une collection existante.
.PARAMETER Collection
    La collection de laquelle supprimer l'information.
.PARAMETER Id
    L'ID de l'information Ã  supprimer.
.PARAMETER Info
    L'information extraite Ã  supprimer.
.EXAMPLE
    $collection = New-ExtractedInfoCollection -Name "Emails"
    $info = New-BaseExtractedInfo -Source "Email"
    Add-ExtractedInfoToCollection -Collection $collection -Info $info
    Remove-ExtractedInfoFromCollection -Collection $collection -Id $info.Id
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Remove-ExtractedInfoFromCollection {
    [CmdletBinding(DefaultParameterSetName = "ById")]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ById", Position = 1)]
        [string]$Id,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByInfo", Position = 1)]
        [hashtable]$Info
    )
    
    # VÃ©rifier que la collection est valide
    if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
        throw "L'objet fourni n'est pas une collection d'informations extraites valide"
    }
    
    # DÃ©terminer l'ID Ã  supprimer
    $idToRemove = $Id
    if ($PSCmdlet.ParameterSetName -eq "ByInfo") {
        if ($null -eq $Info -or -not $Info.ContainsKey("Id")) {
            throw "L'information fournie n'est pas valide"
        }
        $idToRemove = $Info.Id
    }
    
    # Rechercher l'information Ã  supprimer
    $itemIndex = -1
    for ($i = 0; $i -lt $Collection.Items.Count; $i++) {
        if ($Collection.Items[$i].Id -eq $idToRemove) {
            $itemIndex = $i
            break
        }
    }
    
    # Supprimer l'information si elle a Ã©tÃ© trouvÃ©e
    if ($itemIndex -ge 0) {
        $Collection.Items = @($Collection.Items[0..($itemIndex-1)] + $Collection.Items[($itemIndex+1)..($Collection.Items.Count-1)])
        
        # Ajouter une mÃ©tadonnÃ©e systÃ¨me pour suivre les modifications
        $Collection.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
        $Collection.Metadata["_ItemCount"] = $Collection.Items.Count
        
        return $true
    }
    
    return $false
}
