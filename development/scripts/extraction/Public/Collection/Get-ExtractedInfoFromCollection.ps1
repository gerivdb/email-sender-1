<#
.SYNOPSIS
    RÃ©cupÃ¨re une information extraite d'une collection.
.DESCRIPTION
    RÃ©cupÃ¨re une ou plusieurs informations extraites d'une collection selon diffÃ©rents critÃ¨res.
.PARAMETER Collection
    La collection dans laquelle rechercher.
.PARAMETER Id
    L'ID de l'information Ã  rÃ©cupÃ©rer.
.PARAMETER Source
    La source des informations Ã  rÃ©cupÃ©rer.
.PARAMETER ExtractorName
    Le nom de l'extracteur des informations Ã  rÃ©cupÃ©rer.
.PARAMETER ProcessingState
    L'Ã©tat de traitement des informations Ã  rÃ©cupÃ©rer.
.PARAMETER IsValid
    Indique si on doit rÃ©cupÃ©rer les informations valides ou invalides.
.PARAMETER MinConfidenceScore
    Le score de confiance minimum des informations Ã  rÃ©cupÃ©rer.
.EXAMPLE
    $collection = New-ExtractedInfoCollection -Name "Emails"
    $info = New-BaseExtractedInfo -Source "Email"
    Add-ExtractedInfoToCollection -Collection $collection -Info $info
    $retrievedInfo = Get-ExtractedInfoFromCollection -Collection $collection -Id $info.Id
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Get-ExtractedInfoFromCollection {
    [CmdletBinding(DefaultParameterSetName = "ById")]
    [OutputType([hashtable[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection,
        
        [Parameter(ParameterSetName = "ById")]
        [string]$Id,
        
        [Parameter(ParameterSetName = "ByFilter")]
        [string]$Source,
        
        [Parameter(ParameterSetName = "ByFilter")]
        [string]$ExtractorName,
        
        [Parameter(ParameterSetName = "ByFilter")]
        [string]$ProcessingState,
        
        [Parameter(ParameterSetName = "ByFilter")]
        [bool]$IsValid,
        
        [Parameter(ParameterSetName = "ByFilter")]
        [int]$MinConfidenceScore = 0
    )
    
    # VÃ©rifier que la collection est valide
    if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
        throw "L'objet fourni n'est pas une collection d'informations extraites valide"
    }
    
    # Si aucun paramÃ¨tre de filtre n'est spÃ©cifiÃ©, retourner toutes les informations
    if ($PSCmdlet.ParameterSetName -eq "ByFilter" -and 
        [string]::IsNullOrEmpty($Source) -and 
        [string]::IsNullOrEmpty($ExtractorName) -and 
        [string]::IsNullOrEmpty($ProcessingState) -and 
        $MinConfidenceScore -eq 0 -and 
        $PSBoundParameters.ContainsKey("IsValid") -eq $false) {
        return $Collection.Items
    }
    
    # Rechercher par ID
    if ($PSCmdlet.ParameterSetName -eq "ById" -and -not [string]::IsNullOrEmpty($Id)) {
        foreach ($item in $Collection.Items) {
            if ($item.Id -eq $Id) {
                return @($item)
            }
        }
        return @()
    }
    
    # Rechercher par filtres
    $result = @($Collection.Items)
    
    # Filtrer par source
    if (-not [string]::IsNullOrEmpty($Source)) {
        $result = @($result | Where-Object { $_.Source -eq $Source })
    }
    
    # Filtrer par extracteur
    if (-not [string]::IsNullOrEmpty($ExtractorName)) {
        $result = @($result | Where-Object { $_.ExtractorName -eq $ExtractorName })
    }
    
    # Filtrer par Ã©tat de traitement
    if (-not [string]::IsNullOrEmpty($ProcessingState)) {
        $result = @($result | Where-Object { $_.ProcessingState -eq $ProcessingState })
    }
    
    # Filtrer par validitÃ©
    if ($PSBoundParameters.ContainsKey("IsValid")) {
        $result = @($result | Where-Object { $_.IsValid -eq $IsValid })
    }
    
    # Filtrer par score de confiance
    if ($MinConfidenceScore -gt 0) {
        $result = @($result | Where-Object { $_.ConfidenceScore -ge $MinConfidenceScore })
    }
    
    return $result
}
