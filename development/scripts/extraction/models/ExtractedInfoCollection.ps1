using namespace System.Collections.Generic

<#
.SYNOPSIS
    Collection d'informations extraites.
.DESCRIPTION
    Fournit une structure pour gÃ©rer une collection d'informations extraites,
    avec des mÃ©thodes pour ajouter, supprimer, filtrer et manipuler les informations.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer la classe de base
. "$PSScriptRoot\BaseExtractedInfo.ps1"

class ExtractedInfoCollection {
    # Collection d'informations extraites
    [List[BaseExtractedInfo]]$Items
    [string]$Name
    [datetime]$CreatedAt
    [hashtable]$Metadata

    # Constructeur par dÃ©faut
    ExtractedInfoCollection() {
        $this.Items = [List[BaseExtractedInfo]]::new()
        $this.CreatedAt = [datetime]::Now
        $this.Metadata = @{}
    }

    # Constructeur avec nom
    ExtractedInfoCollection([string]$name) {
        $this.Items = [List[BaseExtractedInfo]]::new()
        $this.Name = $name
        $this.CreatedAt = [datetime]::Now
        $this.Metadata = @{}
    }

    # MÃ©thode pour ajouter une information
    [void] Add([BaseExtractedInfo]$item) {
        $this.Items.Add($item)
    }

    # MÃ©thode pour ajouter plusieurs informations
    [void] AddRange([BaseExtractedInfo[]]$items) {
        $this.Items.AddRange($items)
    }

    # MÃ©thode pour supprimer une information
    [bool] Remove([BaseExtractedInfo]$item) {
        return $this.Items.Remove($item)
    }

    # MÃ©thode pour supprimer une information par ID
    [bool] RemoveById([string]$id) {
        $itemToRemove = $this.GetById($id)
        if ($null -ne $itemToRemove) {
            return $this.Items.Remove($itemToRemove)
        }
        return $false
    }

    # MÃ©thode pour vider la collection
    [void] Clear() {
        $this.Items.Clear()
    }

    # MÃ©thode pour obtenir le nombre d'Ã©lÃ©ments
    [int] Count() {
        return $this.Items.Count
    }

    # MÃ©thode pour obtenir une information par ID
    [BaseExtractedInfo] GetById([string]$id) {
        foreach ($item in $this.Items) {
            if ($item.Id -eq $id) {
                return $item
            }
        }
        return $null
    }

    # MÃ©thode pour filtrer les informations par source
    [BaseExtractedInfo[]] FilterBySource([string]$source) {
        return $this.Items | Where-Object { $_.Source -eq $source }
    }

    # MÃ©thode pour filtrer les informations par extracteur
    [BaseExtractedInfo[]] FilterByExtractor([string]$extractorName) {
        return $this.Items | Where-Object { $_.ExtractorName -eq $extractorName }
    }

    # MÃ©thode pour filtrer les informations par Ã©tat de traitement
    [BaseExtractedInfo[]] FilterByProcessingState([string]$state) {
        return $this.Items | Where-Object { $_.ProcessingState -eq $state }
    }

    # MÃ©thode pour filtrer les informations par validitÃ©
    [BaseExtractedInfo[]] FilterByValidity([bool]$isValid) {
        return $this.Items | Where-Object { $_.IsValid -eq $isValid }
    }

    # MÃ©thode pour filtrer les informations par score de confiance minimum
    [BaseExtractedInfo[]] FilterByMinConfidence([int]$minScore) {
        return $this.Items | Where-Object { $_.ConfidenceScore -ge $minScore }
    }

    # MÃ©thode pour filtrer les informations par mÃ©tadonnÃ©e
    [BaseExtractedInfo[]] FilterByMetadata([string]$key, [object]$value) {
        return $this.Items | Where-Object { 
            $_.HasMetadata($key) -and $_.GetMetadata($key) -eq $value 
        }
    }

    # MÃ©thode pour trier les informations par date d'extraction
    [BaseExtractedInfo[]] SortByExtractionDate([bool]$ascending = $true) {
        if ($ascending) {
            return $this.Items | Sort-Object -Property ExtractedAt
        } else {
            return $this.Items | Sort-Object -Property ExtractedAt -Descending
        }
    }

    # MÃ©thode pour trier les informations par score de confiance
    [BaseExtractedInfo[]] SortByConfidence([bool]$ascending = $false) {
        if ($ascending) {
            return $this.Items | Sort-Object -Property ConfidenceScore
        } else {
            return $this.Items | Sort-Object -Property ConfidenceScore -Descending
        }
    }

    # MÃ©thode pour obtenir des statistiques sur la collection
    [hashtable] GetStatistics() {
        $stats = @{
            TotalCount = $this.Items.Count
            ValidCount = ($this.Items | Where-Object { $_.IsValid }).Count
            InvalidCount = ($this.Items | Where-Object { -not $_.IsValid }).Count
            AverageConfidence = 0
            SourceDistribution = @{}
            StateDistribution = @{}
        }

        # Calculer la confiance moyenne
        if ($stats.TotalCount -gt 0) {
            $stats.AverageConfidence = ($this.Items | Measure-Object -Property ConfidenceScore -Average).Average
        }

        # Calculer la distribution par source
        foreach ($item in $this.Items) {
            if (-not [string]::IsNullOrEmpty($item.Source)) {
                if (-not $stats.SourceDistribution.ContainsKey($item.Source)) {
                    $stats.SourceDistribution[$item.Source] = 0
                }
                $stats.SourceDistribution[$item.Source]++
            }

            if (-not [string]::IsNullOrEmpty($item.ProcessingState)) {
                if (-not $stats.StateDistribution.ContainsKey($item.ProcessingState)) {
                    $stats.StateDistribution[$item.ProcessingState] = 0
                }
                $stats.StateDistribution[$item.ProcessingState]++
            }
        }

        return $stats
    }

    # MÃ©thode pour ajouter des mÃ©tadonnÃ©es Ã  la collection
    [void] AddMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
    }

    # MÃ©thode pour obtenir une mÃ©tadonnÃ©e de la collection
    [object] GetMetadata([string]$key) {
        if ($this.Metadata.ContainsKey($key)) {
            return $this.Metadata[$key]
        }
        return $null
    }

    # MÃ©thode pour cloner la collection
    [ExtractedInfoCollection] Clone() {
        $clone = [ExtractedInfoCollection]::new($this.Name)
        
        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }
        
        # Cloner les items
        foreach ($item in $this.Items) {
            $clone.Add($item.Clone())
        }
        
        return $clone
    }

    # MÃ©thode ToString() surchargÃ©e
    [string] ToString() {
        return "Collection '$($this.Name)' contenant $($this.Items.Count) informations extraites"
    }
}
