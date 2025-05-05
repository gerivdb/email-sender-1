using namespace System.Collections.Generic

<#
.SYNOPSIS
    Classe de base pour les informations extraites.
.DESCRIPTION
    Fournit une structure de base pour toutes les informations extraites
    dans le systÃ¨me, avec des propriÃ©tÃ©s et mÃ©thodes communes.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

class BaseExtractedInfo {
    # PropriÃ©tÃ©s communes Ã  toutes les informations extraites
    [string]$Id
    [string]$Source
    [datetime]$ExtractedAt
    [string]$ExtractorName
    [hashtable]$Metadata
    [ValidateSet("Raw", "Processed", "Validated", "Normalized", "Enriched")]
    [string]$ProcessingState = "Raw"
    [int]$ConfidenceScore = 0
    [bool]$IsValid = $false

    # Constructeur par dÃ©faut
    BaseExtractedInfo() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.ExtractedAt = [datetime]::Now
        $this.Metadata = @{}
    }

    # Constructeur avec source
    BaseExtractedInfo([string]$source) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Source = $source
        $this.ExtractedAt = [datetime]::Now
        $this.Metadata = @{}
    }

    # Constructeur avec source et extracteur
    BaseExtractedInfo([string]$source, [string]$extractorName) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Source = $source
        $this.ExtractorName = $extractorName
        $this.ExtractedAt = [datetime]::Now
        $this.Metadata = @{}
    }

    # MÃ©thode pour ajouter des mÃ©tadonnÃ©es
    [void] AddMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
    }

    # MÃ©thode pour obtenir une mÃ©tadonnÃ©e
    [object] GetMetadata([string]$key) {
        if ($this.Metadata.ContainsKey($key)) {
            return $this.Metadata[$key]
        }
        return $null
    }

    # MÃ©thode pour vÃ©rifier si une mÃ©tadonnÃ©e existe
    [bool] HasMetadata([string]$key) {
        return $this.Metadata.ContainsKey($key)
    }

    # MÃ©thode pour supprimer une mÃ©tadonnÃ©e
    [void] RemoveMetadata([string]$key) {
        if ($this.Metadata.ContainsKey($key)) {
            $this.Metadata.Remove($key)
        }
    }

    # MÃ©thode pour obtenir toutes les mÃ©tadonnÃ©es
    [hashtable] GetAllMetadata() {
        return $this.Metadata.Clone()
    }

    # MÃ©thode pour dÃ©finir l'Ã©tat de traitement
    [void] SetProcessingState([string]$state) {
        $this.ProcessingState = $state
    }

    # MÃ©thode pour dÃ©finir le score de confiance
    [void] SetConfidenceScore([int]$score) {
        if ($score -lt 0) { $score = 0 }
        if ($score -gt 100) { $score = 100 }
        $this.ConfidenceScore = $score
    }

    # MÃ©thode pour marquer comme valide/invalide
    [void] SetValidity([bool]$isValid) {
        $this.IsValid = $isValid
    }

    # MÃ©thode pour obtenir un rÃ©sumÃ© de l'information
    [string] GetSummary() {
        return "ID: $($this.Id), Source: $($this.Source), Extrait le: $($this.ExtractedAt), Ã‰tat: $($this.ProcessingState), Confiance: $($this.ConfidenceScore)%"
    }

    # MÃ©thode pour cloner l'objet (Ã  implÃ©menter dans les classes dÃ©rivÃ©es)
    [BaseExtractedInfo] Clone() {
        $clone = [BaseExtractedInfo]::new()
        $clone.Id = $this.Id
        $clone.Source = $this.Source
        $clone.ExtractedAt = $this.ExtractedAt
        $clone.ExtractorName = $this.ExtractorName
        $clone.ProcessingState = $this.ProcessingState
        $clone.ConfidenceScore = $this.ConfidenceScore
        $clone.IsValid = $this.IsValid
        
        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }
        
        return $clone
    }

    # MÃ©thode ToString() surchargÃ©e
    [string] ToString() {
        return $this.GetSummary()
    }
}
