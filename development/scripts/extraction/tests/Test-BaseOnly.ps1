# Test uniquement de la classe de base
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$modelsPath = Join-Path -Path $rootPath -ChildPath "models"

Write-Host "Chargement de BaseExtractedInfo..."
. "$modelsPath\BaseExtractedInfo.ps1"

Write-Host "CrÃ©ation d'une instance..."
$info = [BaseExtractedInfo]::new("TestSource", "TestExtractor")

Write-Host "VÃ©rification des propriÃ©tÃ©s..."
Write-Host "Source: $($info.Source)"
Write-Host "ExtractorName: $($info.ExtractorName)"

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
