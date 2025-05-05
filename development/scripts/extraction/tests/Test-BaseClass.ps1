<#
.SYNOPSIS
    Test simple pour la classe BaseExtractedInfo.
.DESCRIPTION
    VÃ©rifie le bon fonctionnement de la classe de base.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer la classe de base
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$modelsPath = Join-Path -Path $rootPath -ChildPath "models"

Write-Host "Chargement de la classe BaseExtractedInfo..."
. "$modelsPath\BaseExtractedInfo.ps1"

Write-Host "CrÃ©ation d'une instance..."
$info = [BaseExtractedInfo]::new("TestSource", "TestExtractor")

Write-Host "VÃ©rification des propriÃ©tÃ©s..."
Write-Host "Source: $($info.Source)"
Write-Host "ExtractorName: $($info.ExtractorName)"
Write-Host "Id: $($info.Id)"
Write-Host "ExtractedAt: $($info.ExtractedAt)"
Write-Host "ProcessingState: $($info.ProcessingState)"
Write-Host "ConfidenceScore: $($info.ConfidenceScore)"
Write-Host "IsValid: $($info.IsValid)"

Write-Host "Test des mÃ©tadonnÃ©es..."
$info.AddMetadata("TestKey", "TestValue")
Write-Host "HasMetadata('TestKey'): $($info.HasMetadata('TestKey'))"
Write-Host "GetMetadata('TestKey'): $($info.GetMetadata('TestKey'))"

Write-Host "Test de la mÃ©thode GetSummary..."
$summary = $info.GetSummary()
Write-Host "Summary: $summary"

Write-Host "Test de la mÃ©thode Clone..."
$clone = $info.Clone()
Write-Host "Clone.Source: $($clone.Source)"
Write-Host "Clone.ExtractorName: $($clone.ExtractorName)"
Write-Host "Clone.GetMetadata('TestKey'): $($clone.GetMetadata('TestKey'))"

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
