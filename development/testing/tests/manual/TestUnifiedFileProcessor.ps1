# Test du module UnifiedFileProcessor
Write-Host "Test du module UnifiedFileProcessor" -ForegroundColor Green

# Importer le module
$scriptPath = $MyInvocation.MyCommand.Path
$testRoot = Split-Path -Parent $scriptPath
$manualTestRoot = Split-Path -Parent $testRoot
$projectRoot = Split-Path -Parent $manualTestRoot
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
$unifiedFileProcessorPath = Join-Path -Path $modulesPath -ChildPath "UnifiedFileProcessor.ps1"

Write-Host "Chemin du module : $unifiedFileProcessorPath" -ForegroundColor Cyan
if (-not (Test-Path -Path $unifiedFileProcessorPath)) {
    Write-Error "Le module UnifiedFileProcessor.ps1 n'existe pas au chemin spÃ©cifiÃ©."
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$tempDir = Join-Path -Path $env:TEMP -ChildPath "UnifiedFileProcessorTest"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# CrÃ©er des sous-rÃ©pertoires pour les tests
$inputDir = Join-Path -Path $tempDir -ChildPath "input"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
$encryptedDir = Join-Path -Path $tempDir -ChildPath "encrypted"
$decryptedDir = Join-Path -Path $tempDir -ChildPath "decrypted"
New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
New-Item -Path $encryptedDir -ItemType Directory -Force | Out-Null
New-Item -Path $decryptedDir -ItemType Directory -Force | Out-Null

# CrÃ©er un fichier JSON de test
$jsonFilePath = Join-Path -Path $inputDir -ChildPath "test.json"
$jsonContent = @{
    "name"  = "Test Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# CrÃ©er un fichier CSV de test
$csvFilePath = Join-Path -Path $inputDir -ChildPath "test.csv"
$csvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Charger les fonctions du module
. $unifiedFileProcessorPath

# Tester la fonction Initialize-UnifiedFileProcessor
Write-Host "Test de Initialize-UnifiedFileProcessor..." -ForegroundColor Yellow
$initResult = Initialize-UnifiedFileProcessor -EnableCache
Write-Host "RÃ©sultat de l'initialisation : $initResult" -ForegroundColor $(if ($initResult) { "Green" } else { "Red" })

# Tester la fonction Invoke-SecureFileProcessing
Write-Host "Test de Invoke-SecureFileProcessing..." -ForegroundColor Yellow
$outputJsonPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
$processResult = Invoke-SecureFileProcessing -InputFile $csvFilePath -OutputFile $outputJsonPath -InputFormat "CSV" -OutputFormat "JSON"
Write-Host "RÃ©sultat du traitement : $processResult" -ForegroundColor $(if ($processResult) { "Green" } else { "Red" })

# VÃ©rifier que le fichier de sortie existe
if (Test-Path -Path $outputJsonPath) {
    $outputContent = Get-Content -Path $outputJsonPath -Raw
    Write-Host "Contenu du fichier de sortie :" -ForegroundColor Cyan
    Write-Host $outputContent -ForegroundColor Cyan
}

# Tester la fonction Protect-SecureFile si le module EncryptionUtils est disponible
if ($availableOptionalModules.ContainsKey("EncryptionUtils")) {
    Write-Host "Test de Protect-SecureFile..." -ForegroundColor Yellow

    # GÃ©nÃ©rer une clÃ© de chiffrement
    $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
    $key = New-EncryptionKey -Password $password

    # Chiffrer un fichier
    $encryptedFilePath = Join-Path -Path $encryptedDir -ChildPath "test.json.enc"
    $encryptResult = Protect-SecureFile -InputFile $jsonFilePath -OutputFile $encryptedFilePath -EncryptionKey $key -CreateSignature

    Write-Host "RÃ©sultat du chiffrement : $($encryptResult.Success)" -ForegroundColor $(if ($encryptResult.Success) { "Green" } else { "Red" })
    Write-Host "Fichier chiffrÃ© : $($encryptResult.OutputFile)" -ForegroundColor Cyan
    Write-Host "Fichier de signature : $($encryptResult.SignatureFile)" -ForegroundColor Cyan

    # DÃ©chiffrer le fichier
    $decryptedFilePath = Join-Path -Path $decryptedDir -ChildPath "test_decrypted.json"
    $decryptResult = Unprotect-SecureFile -InputFile $encryptedFilePath -OutputFile $decryptedFilePath -EncryptionKey $key -VerifySignature

    Write-Host "RÃ©sultat du dÃ©chiffrement : $($decryptResult.Success)" -ForegroundColor $(if ($decryptResult.Success) { "Green" } else { "Red" })
    Write-Host "Fichier dÃ©chiffrÃ© : $($decryptResult.OutputFile)" -ForegroundColor Cyan

    # VÃ©rifier que le contenu est identique
    $originalContent = Get-Content -Path $jsonFilePath -Raw
    $decryptedContent = Get-Content -Path $decryptedFilePath -Raw

    Write-Host "Correspondance du contenu : $($originalContent -eq $decryptedContent)" -ForegroundColor $(if ($originalContent -eq $decryptedContent) { "Green" } else { "Red" })
} else {
    Write-Host "Le module EncryptionUtils n'est pas disponible. Test de chiffrement ignorÃ©." -ForegroundColor Yellow
}

# Tester la fonction Invoke-CachedFileProcessing si le module CacheManager est disponible
if ($availableOptionalModules.ContainsKey("CacheManager")) {
    Write-Host "Test de Invoke-CachedFileProcessing..." -ForegroundColor Yellow

    # Premier appel (sans cache)
    Write-Host "Premier appel (sans cache)..." -ForegroundColor Yellow
    $outputYamlPath1 = Join-Path -Path $outputDir -ChildPath "cached1.yaml"
    $startTime = Get-Date
    $cachedResult1 = Invoke-CachedFileProcessing -InputFile $jsonFilePath -OutputFile $outputYamlPath1 -InputFormat "JSON" -OutputFormat "YAML"
    $endTime = Get-Date
    $duration1 = ($endTime - $startTime).TotalMilliseconds

    Write-Host "RÃ©sultat du premier appel : $cachedResult1" -ForegroundColor $(if ($cachedResult1) { "Green" } else { "Red" })
    Write-Host "DurÃ©e du premier appel : $duration1 ms" -ForegroundColor Cyan

    # DeuxiÃ¨me appel (avec cache)
    Write-Host "DeuxiÃ¨me appel (avec cache)..." -ForegroundColor Yellow
    $outputYamlPath2 = Join-Path -Path $outputDir -ChildPath "cached2.yaml"
    $startTime = Get-Date
    $cachedResult2 = Invoke-CachedFileProcessing -InputFile $jsonFilePath -OutputFile $outputYamlPath2 -InputFormat "JSON" -OutputFormat "YAML"
    $endTime = Get-Date
    $duration2 = ($endTime - $startTime).TotalMilliseconds

    Write-Host "RÃ©sultat du deuxiÃ¨me appel : $cachedResult2" -ForegroundColor $(if ($cachedResult2) { "Green" } else { "Red" })
    Write-Host "DurÃ©e du deuxiÃ¨me appel : $duration2 ms" -ForegroundColor Cyan
    Write-Host "Gain de performance : $([Math]::Round(($duration1 - $duration2) / $duration1 * 100))%" -ForegroundColor Cyan

    # Afficher les statistiques du cache
    $cacheStats = Get-CacheStatistics
    Write-Host "Statistiques du cache :" -ForegroundColor Cyan
    Write-Host "  Hits : $($cacheStats.Hits)" -ForegroundColor Cyan
    Write-Host "  Misses : $($cacheStats.Misses)" -ForegroundColor Cyan
    Write-Host "  Taux de succÃ¨s : $($cacheStats.HitRate * 100)%" -ForegroundColor Cyan
} else {
    Write-Host "Le module CacheManager n'est pas disponible. Test de mise en cache ignorÃ©." -ForegroundColor Yellow
}

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Tests terminÃ©s." -ForegroundColor Green
