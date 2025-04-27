#
# Exemple d'utilisation du module FileContentIndexer
# Compatible avec PowerShell 5.1 et PowerShell 7+
#

# Importer le module
Import-Module .\FileContentIndexer.psm1 -Force

# Afficher les informations de version
$versionInfo = Get-PSVersionInfo
Write-Host "PowerShell Version: $($versionInfo.FullVersion)" -ForegroundColor Cyan
Write-Host "Edition: $($versionInfo.Edition)" -ForegroundColor Cyan
Write-Host "PowerShell 7+: $($versionInfo.IsPowerShell7)" -ForegroundColor Cyan
Write-Host "PowerShell 5.1: $($versionInfo.IsPowerShell5)" -ForegroundColor Cyan
Write-Host ""

# VÃ©rifier la disponibilitÃ© des fonctionnalitÃ©s
Write-Host "VÃ©rification des fonctionnalitÃ©s disponibles:" -ForegroundColor Cyan
$features = @('Classes', 'AdvancedClasses', 'Ternary', 'PipelineChain', 'NullCoalescing', 'ForEachParallel')
foreach ($feature in $features) {
    $available = Test-FeatureAvailability -FeatureName $feature
    Write-Host "  $feature : $available"
}
Write-Host ""

# CrÃ©er une instance du module
Write-Host "CrÃ©ation d'une instance de FileContentIndexer:" -ForegroundColor Cyan
$instance = New-FileContentIndexer -Name "MonInstance" -Properties @{
    Setting1 = "Valeur1"
    Setting2 = 42
}

Write-Host "Instance crÃ©Ã©e: $($instance.ToString())"
Write-Host "PropriÃ©tÃ©s: $($instance.Properties | ConvertTo-Json -Compress)"
Write-Host ""

# Tester la mÃ©thode Process
Write-Host "Test de la mÃ©thode Process:" -ForegroundColor Cyan
$result1 = $instance.Process("Test")
$result2 = $instance.Process($null)
Write-Host "  Process('Test'): $result1"
Write-Host "  Process(null): $result2"
Write-Host ""

# Tester la parallÃ©lisation
Write-Host "Test de parallÃ©lisation:" -ForegroundColor Cyan
$items = 1..5
$results = Invoke-Parallel -ScriptBlock {
    param($item)
    $computerName = $env:COMPUTERNAME
    $processId = $PID
    return [PSCustomObject]@{
        Item = $item
        ComputerName = $computerName
        ProcessId = $processId
        Timestamp = Get-Date
    }
} -InputObject $items -ThrottleLimit 3

Write-Host "RÃ©sultats de la parallÃ©lisation:"
$results | Format-Table -AutoSize
