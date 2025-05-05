<#
.SYNOPSIS
    Obtient des statistiques sur une collection d'informations extraites.
.DESCRIPTION
    Calcule et retourne diverses statistiques sur une collection d'informations extraites.
.PARAMETER Collection
    La collection pour laquelle calculer les statistiques.
.EXAMPLE
    $collection = New-ExtractedInfoCollection -Name "Emails"
    $info1 = New-BaseExtractedInfo -Source "Email1"
    $info2 = New-BaseExtractedInfo -Source "Email2"
    Add-ExtractedInfoToCollection -Collection $collection -Info $info1, $info2
    Get-ExtractedInfoCollectionStatistics -Collection $collection
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Get-ExtractedInfoCollectionStatistics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection
    )
    
    # VÃ©rifier que la collection est valide
    if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
        throw "L'objet fourni n'est pas une collection d'informations extraites valide"
    }
    
    # Initialiser les statistiques
    $stats = @{
        TotalCount = $Collection.Items.Count
        ValidCount = 0
        InvalidCount = 0
        AverageConfidence = 0
        SourceDistribution = @{}
        StateDistribution = @{}
        TypeDistribution = @{}
    }
    
    # Si la collection est vide, retourner les statistiques de base
    if ($stats.TotalCount -eq 0) {
        return $stats
    }
    
    # Calculer les statistiques dÃ©taillÃ©es
    $totalConfidence = 0
    
    foreach ($item in $Collection.Items) {
        # Compter les Ã©lÃ©ments valides et invalides
        if ($item.IsValid) {
            $stats.ValidCount++
        } else {
            $stats.InvalidCount++
        }
        
        # Additionner les scores de confiance
        $totalConfidence += $item.ConfidenceScore
        
        # Compter les Ã©lÃ©ments par source
        $source = $item.Source
        if (-not [string]::IsNullOrEmpty($source)) {
            if (-not $stats.SourceDistribution.ContainsKey($source)) {
                $stats.SourceDistribution[$source] = 0
            }
            $stats.SourceDistribution[$source]++
        }
        
        # Compter les Ã©lÃ©ments par Ã©tat de traitement
        $state = $item.ProcessingState
        if (-not [string]::IsNullOrEmpty($state)) {
            if (-not $stats.StateDistribution.ContainsKey($state)) {
                $stats.StateDistribution[$state] = 0
            }
            $stats.StateDistribution[$state]++
        }
        
        # Compter les Ã©lÃ©ments par type
        $type = $item._Type
        if (-not [string]::IsNullOrEmpty($type)) {
            if (-not $stats.TypeDistribution.ContainsKey($type)) {
                $stats.TypeDistribution[$type] = 0
            }
            $stats.TypeDistribution[$type]++
        }
    }
    
    # Calculer la confiance moyenne
    $stats.AverageConfidence = [math]::Round($totalConfidence / $stats.TotalCount, 2)
    
    # Ajouter des mÃ©tadonnÃ©es supplÃ©mentaires
    $stats.CollectionName = $Collection.Name
    $stats.CollectionCreatedAt = $Collection.CreatedAt
    $stats.StatisticsGeneratedAt = [datetime]::Now
    
    return $stats
}
