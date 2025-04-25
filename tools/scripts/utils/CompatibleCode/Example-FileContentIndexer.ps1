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

# Vérifier la disponibilité des fonctionnalités
Write-Host "Vérification des fonctionnalités disponibles:" -ForegroundColor Cyan
$features = @('Classes', 'AdvancedClasses', 'Ternary', 'PipelineChain', 'NullCoalescing', 'ForEachParallel')
foreach ($feature in $features) {
    $available = Test-FeatureAvailability -FeatureName $feature
    Write-Host "  $feature : $available"
}
Write-Host ""

# Créer une instance du module
Write-Host "Création d'une instance de FileContentIndexer:" -ForegroundColor Cyan
$instance = New-FileContentIndexer -Name "MonInstance" -Properties @{
    Setting1 = "Valeur1"
    Setting2 = 42
}

Write-Host "Instance créée: $($instance.ToString())"
Write-Host "Propriétés: $($instance.Properties | ConvertTo-Json -Compress)"
Write-Host ""

# Tester la méthode Process
Write-Host "Test de la méthode Process:" -ForegroundColor Cyan
$result1 = $instance.Process("Test")
$result2 = $instance.Process($null)
Write-Host "  Process('Test'): $result1"
Write-Host "  Process(null): $result2"
Write-Host ""

# Tester la parallélisation
Write-Host "Test de parallélisation:" -ForegroundColor Cyan
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

Write-Host "Résultats de la parallélisation:"
$results | Format-Table -AutoSize
