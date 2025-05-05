<#
.SYNOPSIS
    Ajoute une mÃ©tadonnÃ©e Ã  une information extraite.
.DESCRIPTION
    Ajoute ou met Ã  jour une mÃ©tadonnÃ©e dans une information extraite.
.PARAMETER Info
    L'information extraite Ã  laquelle ajouter la mÃ©tadonnÃ©e.
.PARAMETER Key
    La clÃ© de la mÃ©tadonnÃ©e.
.PARAMETER Value
    La valeur de la mÃ©tadonnÃ©e.
.EXAMPLE
    $info = New-BaseExtractedInfo -Source "Email"
    Add-ExtractedInfoMetadata -Info $info -Key "Subject" -Value "RÃ©union importante"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Add-ExtractedInfoMetadata {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Key,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [object]$Value
    )
    
    # VÃ©rifier que l'information est valide
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "L'objet fourni n'est pas une information extraite valide"
    }
    
    # Ajouter ou mettre Ã  jour la mÃ©tadonnÃ©e
    $Info.Metadata[$Key] = $Value
    
    # Ajouter une mÃ©tadonnÃ©e systÃ¨me pour suivre les modifications
    $Info.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
    
    return $Info
}
