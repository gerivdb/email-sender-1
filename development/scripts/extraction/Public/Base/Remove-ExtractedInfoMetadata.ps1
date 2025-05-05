<#
.SYNOPSIS
    Supprime une mÃ©tadonnÃ©e d'une information extraite.
.DESCRIPTION
    Supprime une mÃ©tadonnÃ©e spÃ©cifique d'une information extraite.
.PARAMETER Info
    L'information extraite dont on veut supprimer la mÃ©tadonnÃ©e.
.PARAMETER Key
    La clÃ© de la mÃ©tadonnÃ©e Ã  supprimer.
.EXAMPLE
    $info = New-BaseExtractedInfo -Source "Email"
    Add-ExtractedInfoMetadata -Info $info -Key "Subject" -Value "RÃ©union importante"
    Remove-ExtractedInfoMetadata -Info $info -Key "Subject"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Remove-ExtractedInfoMetadata {
    [CmdletBinding()]
    [OutputType([hashtable])]
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
    
    # Supprimer la mÃ©tadonnÃ©e si elle existe
    if ($Info.Metadata.ContainsKey($Key)) {
        $Info.Metadata.Remove($Key)
        
        # Ajouter une mÃ©tadonnÃ©e systÃ¨me pour suivre les modifications
        $Info.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
    }
    
    return $Info
}
