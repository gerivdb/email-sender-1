# Script pour exÃ©cuter les tests Pester pour le module Path-Manager

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Le module Pester n'est pas installÃ©. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.Run.PassThru = $true
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "TestResults.xml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = Join-Path -Path $PSScriptRoot -ChildPath "..\Path-Manager.psm1"
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "CodeCoverage.xml"

# Traiter les paramÃ¨tres
$showFailed = $false
foreach ($arg in $args) {
    if ($arg -eq "-Show" -and $args.IndexOf($arg) -lt $args.Count - 1) {
        $showValue = $args[$args.IndexOf($arg) + 1]
        if ($showValue -eq "Failed") {
            $showFailed = $true
        }
    }
}

if ($showFailed) {
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.Filter.Tag = @('Focus')
}

# ExÃ©cuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher les rÃ©sultats des tests qui ont Ã©chouÃ©
if ($testResults.FailedCount -gt 0) {
    Write-Host "\nTests qui ont Ã©chouÃ©:" -ForegroundColor Red
    $testResults.Failed | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
        Write-Host "    Message: $($_.ErrorRecord.Exception.Message)" -ForegroundColor Red
        Write-Host "    Dans: $($_.ErrorRecord.ScriptStackTrace)" -ForegroundColor Red
        Write-Host ""
    }
}
