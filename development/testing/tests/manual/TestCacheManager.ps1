# Test du module CacheManager
Write-Host "Test du module CacheManager" -ForegroundColor Green

# Importer le module
$scriptPath = $MyInvocation.MyCommand.Path
$testRoot = Split-Path -Parent $scriptPath
$manualTestRoot = Split-Path -Parent $testRoot
$projectRoot = Split-Path -Parent $manualTestRoot
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
$cacheManagerPath = Join-Path -Path $modulesPath -ChildPath "CacheManager.ps1"

Write-Host "Chemin du module : $cacheManagerPath" -ForegroundColor Cyan
if (-not (Test-Path -Path $cacheManagerPath)) {
    Write-Error "Le module CacheManager.ps1 n'existe pas au chemin spÃ©cifiÃ©."
    exit 1
}

# Charger les fonctions du module
. $cacheManagerPath

# Initialiser le gestionnaire de cache
Write-Host "Initialisation du gestionnaire de cache..." -ForegroundColor Yellow
$initResult = Initialize-CacheManager -Enabled $true -MaxItems 100 -DefaultTTL 60 -EvictionPolicy "LRU"
Write-Host "RÃ©sultat de l'initialisation : $initResult" -ForegroundColor $(if ($initResult) { "Green" } else { "Red" })

# Tester la fonction Set-CacheItem
Write-Host "Test de Set-CacheItem..." -ForegroundColor Yellow
Set-CacheItem -Key "TestKey1" -Value "TestValue1"
Set-CacheItem -Key "TestKey2" -Value "TestValue2" -TTL 120
Write-Host "Ã‰lÃ©ments ajoutÃ©s au cache." -ForegroundColor Cyan

# Tester la fonction Get-CacheItem
Write-Host "Test de Get-CacheItem..." -ForegroundColor Yellow
$value1 = Get-CacheItem -Key "TestKey1"
$value2 = Get-CacheItem -Key "TestKey2"
$nonExistentValue = Get-CacheItem -Key "NonExistentKey"
Write-Host "Valeur 1 : $value1" -ForegroundColor Cyan
Write-Host "Valeur 2 : $value2" -ForegroundColor Cyan
Write-Host "Valeur non existante : $nonExistentValue" -ForegroundColor Cyan

# Tester la fonction Get-CacheStatistics
Write-Host "Test de Get-CacheStatistics..." -ForegroundColor Yellow
$stats = Get-CacheStatistics
Write-Host "Statistiques du cache :" -ForegroundColor Cyan
Write-Host "  ActivÃ© : $($stats.Enabled)" -ForegroundColor Cyan
Write-Host "  Nombre d'Ã©lÃ©ments : $($stats.ItemCount)" -ForegroundColor Cyan
Write-Host "  Nombre maximum d'Ã©lÃ©ments : $($stats.MaxItems)" -ForegroundColor Cyan
Write-Host "  Pourcentage d'utilisation : $($stats.UsagePercentage)%" -ForegroundColor Cyan
Write-Host "  Hits : $($stats.Hits)" -ForegroundColor Cyan
Write-Host "  Misses : $($stats.Misses)" -ForegroundColor Cyan
Write-Host "  Taux de succÃ¨s : $($stats.HitRate * 100)%" -ForegroundColor Cyan
Write-Host "  Ã‰victions : $($stats.Evictions)" -ForegroundColor Cyan
Write-Host "  Politique d'Ã©viction : $($stats.EvictionPolicy)" -ForegroundColor Cyan

# Tester la fonction Remove-CacheItem
Write-Host "Test de Remove-CacheItem..." -ForegroundColor Yellow
$removeResult = Remove-CacheItem -Key "TestKey1"
Write-Host "RÃ©sultat de la suppression : $removeResult" -ForegroundColor $(if ($removeResult) { "Green" } else { "Red" })
$value1AfterRemove = Get-CacheItem -Key "TestKey1"
Write-Host "Valeur 1 aprÃ¨s suppression : $value1AfterRemove" -ForegroundColor Cyan

# Tester la fonction Invoke-CachedFunction
Write-Host "Test de Invoke-CachedFunction..." -ForegroundColor Yellow

# DÃ©finir une fonction coÃ»teuse
$expensiveFunction = {
    param($id)

    Write-Host "  ExÃ©cution de la fonction coÃ»teuse pour l'ID $id..." -ForegroundColor Gray
    Start-Sleep -Seconds 2  # Simuler une opÃ©ration coÃ»teuse
    return "RÃ©sultat pour l'ID $id"
}

# Premier appel (sans cache)
Write-Host "Premier appel (sans cache)..." -ForegroundColor Yellow
$startTime = Get-Date
$result1 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)
$endTime = Get-Date
$duration1 = ($endTime - $startTime).TotalMilliseconds
Write-Host "RÃ©sultat 1 : $result1" -ForegroundColor Cyan
Write-Host "DurÃ©e du premier appel : $duration1 ms" -ForegroundColor Cyan

# DeuxiÃ¨me appel (avec cache)
Write-Host "DeuxiÃ¨me appel (avec cache)..." -ForegroundColor Yellow
$startTime = Get-Date
$result2 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)
$endTime = Get-Date
$duration2 = ($endTime - $startTime).TotalMilliseconds
Write-Host "RÃ©sultat 2 : $result2" -ForegroundColor Cyan
Write-Host "DurÃ©e du deuxiÃ¨me appel : $duration2 ms" -ForegroundColor Cyan
Write-Host "Gain de performance : $([Math]::Round(($duration1 - $duration2) / $duration1 * 100))%" -ForegroundColor Cyan

# Tester l'expiration du cache
Write-Host "Test de l'expiration du cache..." -ForegroundColor Yellow
Set-CacheItem -Key "ExpiringKey" -Value "ExpiringValue" -TTL 3
Write-Host "Ã‰lÃ©ment ajoutÃ© au cache avec un TTL de 3 secondes." -ForegroundColor Cyan
$valueBeforeExpiration = Get-CacheItem -Key "ExpiringKey"
Write-Host "Valeur avant expiration : $valueBeforeExpiration" -ForegroundColor Cyan
Write-Host "Attente de l'expiration (4 secondes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 4
$valueAfterExpiration = Get-CacheItem -Key "ExpiringKey"
Write-Host "Valeur aprÃ¨s expiration : $valueAfterExpiration" -ForegroundColor Cyan

# Tester la fonction Clear-Cache
Write-Host "Test de Clear-Cache..." -ForegroundColor Yellow
$clearResult = Clear-Cache
Write-Host "RÃ©sultat du vidage du cache : $clearResult" -ForegroundColor $(if ($clearResult) { "Green" } else { "Red" })
$statsAfterClear = Get-CacheStatistics
Write-Host "Nombre d'Ã©lÃ©ments aprÃ¨s vidage : $($statsAfterClear.ItemCount)" -ForegroundColor Cyan

Write-Host "Tests terminÃ©s." -ForegroundColor Green
