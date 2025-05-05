<#
.SYNOPSIS
    RÃ©cupÃ¨re une mÃ©tadonnÃ©e d'une information extraite.
.DESCRIPTION
    RÃ©cupÃ¨re la valeur d'une mÃ©tadonnÃ©e spÃ©cifique d'une information extraite.
.PARAMETER Info
    L'information extraite dont on veut rÃ©cupÃ©rer la mÃ©tadonnÃ©e.
.PARAMETER Key
    La clÃ© de la mÃ©tadonnÃ©e Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $info = New-BaseExtractedInfo -Source "Email"
    Add-ExtractedInfoMetadata -Info $info -Key "Subject" -Value "RÃ©union importante"
    $subject = Get-ExtractedInfoMetadata -Info $info -Key "Subject"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Get-ExtractedInfoMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Key
    )
    
    # VÃ©rifier que l'information est valide
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "L'objet fourni n'est pas une information extraite valide"
    }
    
    # RÃ©cupÃ©rer la mÃ©tadonnÃ©e
    if ($Info.Metadata.ContainsKey($Key)) {
        return $Info.Metadata[$Key]
    }
    
    return $null
}
