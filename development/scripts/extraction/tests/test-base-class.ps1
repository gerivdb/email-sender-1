Write-Host "Test de la classe BaseExtractedInfo..."

# DÃ©finir la classe BaseExtractedInfo directement dans ce script
using namespace System.Collections.Generic

class BaseExtractedInfo {
    # PropriÃ©tÃ©s communes Ã  toutes les informations extraites
    [string]$Id
    [string]$Source
    [datetime]$ExtractedAt
    [string]$ExtractorName
    [hashtable]$Metadata
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

    # MÃ©thode pour obtenir un rÃ©sumÃ© de l'information
    [string] GetSummary() {
        return "ID: $($this.Id), Source: $($this.Source), Extrait le: $($this.ExtractedAt), Ã‰tat: $($this.ProcessingState), Confiance: $($this.ConfidenceScore)%"
    }
}

# CrÃ©er une instance
$info = [BaseExtractedInfo]::new("TestSource", "TestExtractor")
$info.AddMetadata("TestKey", "TestValue")

# Afficher les propriÃ©tÃ©s
Write-Host "Source: $($info.Source)"
Write-Host "ExtractorName: $($info.ExtractorName)"
Write-Host "Id: $($info.Id)"
Write-Host "Metadata[TestKey]: $($info.GetMetadata('TestKey'))"
Write-Host "Summary: $($info.GetSummary())"

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
