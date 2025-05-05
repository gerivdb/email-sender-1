<#
.SYNOPSIS
    CrÃ©e une copie d'une information extraite.
.DESCRIPTION
    CrÃ©e une copie profonde d'une information extraite, y compris ses mÃ©tadonnÃ©es.
.PARAMETER Info
    L'information extraite Ã  copier.
.EXAMPLE
    $info = New-BaseExtractedInfo -Source "Email"
    $copy = Copy-ExtractedInfo -Info $info
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Copy-ExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info
    )
    
    # VÃ©rifier que l'information est valide
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "L'objet fourni n'est pas une information extraite valide"
    }
    
    # CrÃ©er une copie de base
    $copy = @{}
    
    # Copier toutes les propriÃ©tÃ©s de premier niveau
    foreach ($key in $Info.Keys) {
        if ($key -ne "Metadata") {
            $copy[$key] = $Info[$key]
        }
    }
    
    # Copier les mÃ©tadonnÃ©es (copie profonde)
    $copy.Metadata = @{}
    foreach ($key in $Info.Metadata.Keys) {
        $copy.Metadata[$key] = $Info.Metadata[$key]
    }
    
    # Ajouter une mÃ©tadonnÃ©e systÃ¨me pour indiquer qu'il s'agit d'une copie
    $copy.Metadata["_IsCopy"] = $true
    $copy.Metadata["_CopiedAt"] = [datetime]::Now.ToString("o")
    $copy.Metadata["_OriginalId"] = $Info.Id
    
    # GÃ©nÃ©rer un nouvel ID pour la copie
    $copy.Id = [guid]::NewGuid().ToString()
    
    return $copy
}
