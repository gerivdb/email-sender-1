Write-Host "Test avec des objets PowerShell traditionnels..."

# CrÃ©er une fonction pour crÃ©er un objet d'information extraite
function New-ExtractedInfo {
    param (
        [string]$Source,
        [string]$ExtractorName
    )
    
    $info = New-Object -TypeName PSObject -Property @{
        Id = [guid]::NewGuid().ToString()
        Source = $Source
        ExtractedAt = [datetime]::Now
        ExtractorName = $ExtractorName
        Metadata = @{}
        ProcessingState = "Raw"
        ConfidenceScore = 0
        IsValid = $false
    }
    
    # Ajouter des mÃ©thodes
    $info | Add-Member -MemberType ScriptMethod -Name "AddMetadata" -Value {
        param ([string]$key, [object]$value)
        $this.Metadata[$key] = $value
    }
    
    $info | Add-Member -MemberType ScriptMethod -Name "GetMetadata" -Value {
        param ([string]$key)
        if ($this.Metadata.ContainsKey($key)) {
            return $this.Metadata[$key]
        }
        return $null
    }
    
    $info | Add-Member -MemberType ScriptMethod -Name "GetSummary" -Value {
        return "ID: $($this.Id), Source: $($this.Source), Extrait le: $($this.ExtractedAt), Ã‰tat: $($this.ProcessingState), Confiance: $($this.ConfidenceScore)%"
    }
    
    return $info
}

# CrÃ©er un objet
$info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
$info.AddMetadata("TestKey", "TestValue")

# Afficher les propriÃ©tÃ©s
Write-Host "Source: $($info.Source)"
Write-Host "ExtractorName: $($info.ExtractorName)"
Write-Host "Id: $($info.Id)"
Write-Host "Metadata[TestKey]: $($info.GetMetadata('TestKey'))"
Write-Host "Summary: $($info.GetSummary())"

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
