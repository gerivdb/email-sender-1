# Script de test manuel pour la fonction Get-PowerShellVersionInfo
# Ce script teste directement la fonction sans dépendre de Pester

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Tester Get-PowerShellVersionInfo
Write-Host "`n=== Test de Get-PowerShellVersionInfo ===" -ForegroundColor Magenta
try {
    $result = Get-PowerShellVersionInfo
    
    # Afficher les informations
    Write-Host "Version: $($result.Version)" -ForegroundColor Green
    Write-Host "Major: $($result.Major)" -ForegroundColor Green
    Write-Host "Minor: $($result.Minor)" -ForegroundColor Green
    Write-Host "Build: $($result.Build)" -ForegroundColor Green
    Write-Host "Revision: $($result.Revision)" -ForegroundColor Green
    Write-Host "Edition: $($result.Edition)" -ForegroundColor Green
    Write-Host "IsCore: $($result.IsCore)" -ForegroundColor Green
    Write-Host "IsDesktop: $($result.IsDesktop)" -ForegroundColor Green
    Write-Host "IsWindows: $($result.IsWindows)" -ForegroundColor Green
    Write-Host "IsLinux: $($result.IsLinux)" -ForegroundColor Green
    Write-Host "IsMacOS: $($result.IsMacOS)" -ForegroundColor Green
    Write-Host "Is64Bit: $($result.Is64Bit)" -ForegroundColor Green
    Write-Host "CLRVersion: $($result.CLRVersion)" -ForegroundColor Green
    Write-Host "HasForEachParallel: $($result.HasForEachParallel)" -ForegroundColor Green
    Write-Host "HasRunspaces: $($result.HasRunspaces)" -ForegroundColor Green
    Write-Host "HasThreadJobs: $($result.HasThreadJobs)" -ForegroundColor Green
    Write-Host "SupportsUTF8NoBOM: $($result.SupportsUTF8NoBOM)" -ForegroundColor Green
    Write-Host "OptimalParallelizationMethod: $($result.OptimalParallelizationMethod)" -ForegroundColor Green
    
    # Vérifier le cache
    Write-Host "`n=== Test du cache ===" -ForegroundColor Magenta
    $result1 = Get-PowerShellVersionInfo
    $result2 = Get-PowerShellVersionInfo
    $sameReference = [object]::ReferenceEquals($result1, $result2)
    Write-Host "Même référence d'objet: $sameReference" -ForegroundColor $(if ($sameReference) { "Green" } else { "Red" })
    
    # Vérifier le paramètre Refresh
    Write-Host "`n=== Test du paramètre Refresh ===" -ForegroundColor Magenta
    $result3 = Get-PowerShellVersionInfo -Refresh
    $sameReference = [object]::ReferenceEquals($result1, $result3)
    Write-Host "Même référence d'objet après Refresh: $sameReference" -ForegroundColor $(if (-not $sameReference) { "Green" } else { "Red" })
    
    # Vérifier la cohérence avec $PSVersionTable
    Write-Host "`n=== Cohérence avec `$PSVersionTable ===" -ForegroundColor Magenta
    $psVersionMatch = $result.Version -eq $PSVersionTable.PSVersion
    Write-Host "Version cohérente avec `$PSVersionTable.PSVersion: $psVersionMatch" -ForegroundColor $(if ($psVersionMatch) { "Green" } else { "Red" })
    
    if ($PSVersionTable.ContainsKey('PSEdition')) {
        $psEditionMatch = $result.Edition -eq $PSVersionTable.PSEdition
        Write-Host "Edition cohérente avec `$PSVersionTable.PSEdition: $psEditionMatch" -ForegroundColor $(if ($psEditionMatch) { "Green" } else { "Red" })
    } else {
        $psEditionMatch = $result.Edition -eq 'Desktop'
        Write-Host "Edition correctement détectée comme 'Desktop': $psEditionMatch" -ForegroundColor $(if ($psEditionMatch) { "Green" } else { "Red" })
    }
    
    # Vérifier la détection de ForEach-Object -Parallel
    $expectedHasForEachParallel = ($PSVersionTable.PSVersion.Major -ge 7)
    $hasForEachParallelMatch = $result.HasForEachParallel -eq $expectedHasForEachParallel
    Write-Host "Détection correcte de ForEach-Object -Parallel: $hasForEachParallelMatch" -ForegroundColor $(if ($hasForEachParallelMatch) { "Green" } else { "Red" })
    
    # Vérifier la méthode de parallélisation optimale
    $expectedMethod = if ($PSVersionTable.PSVersion.Major -ge 7) { 'ForEachParallel' } else { 'RunspacePool' }
    $optimalMethodMatch = $result.OptimalParallelizationMethod -eq $expectedMethod
    Write-Host "Méthode de parallélisation optimale correcte: $optimalMethodMatch" -ForegroundColor $(if ($optimalMethodMatch) { "Green" } else { "Red" })
    
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

Write-Host "`n=== Tests terminés ===" -ForegroundColor Cyan
