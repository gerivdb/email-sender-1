# Exemple d'utilisation des fonctionnalités avancées
# Ce script montre comment utiliser les fonctionnalités avancées du module UnifiedFileProcessor,
# notamment la mise en cache et le chiffrement.

# Importer le module UnifiedFileProcessor
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedFileProcessorPath = Join-Path -Path $modulesPath -ChildPath "UnifiedFileProcessor.ps1"
. $unifiedFileProcessorPath

# Initialiser le module avec le cache activé
$initResult = Initialize-UnifiedFileProcessor -EnableCache -CacheMaxItems 100 -CacheTTL 3600 -CacheEvictionPolicy "LRU"
if (-not $initResult) {
    Write-Error "Erreur lors de l'initialisation du module UnifiedFileProcessor"
    return
}

# Créer un répertoire temporaire pour les exemples
$tempDir = Join-Path -Path $env:TEMP -ChildPath "AdvancedFeaturesExample"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des sous-répertoires
$inputDir = Join-Path -Path $tempDir -ChildPath "input"
$outputDir = Join-Path -Path $tempDir -ChildPath "output"
$encryptedDir = Join-Path -Path $tempDir -ChildPath "encrypted"
$decryptedDir = Join-Path -Path $tempDir -ChildPath "decrypted"
$cachedDir = Join-Path -Path $tempDir -ChildPath "cached"
New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
New-Item -Path $encryptedDir -ItemType Directory -Force | Out-Null
New-Item -Path $decryptedDir -ItemType Directory -Force | Out-Null
New-Item -Path $cachedDir -ItemType Directory -Force | Out-Null

# Créer un fichier JSON d'exemple
$jsonFilePath = Join-Path -Path $inputDir -ChildPath "example.json"
$jsonContent = @{
    "name"     = "Example Object"
    "items"    = @(
        @{ "id" = 1; "value" = "Item 1"; "description" = "Description 1" },
        @{ "id" = 2; "value" = "Item 2"; "description" = "Description 2" },
        @{ "id" = 3; "value" = "Item 3"; "description" = "Description 3" }
    )
    "metadata" = @{
        "created" = "2025-06-06"
        "version" = "1.0.0"
    }
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# Créer un fichier CSV d'exemple
$csvFilePath = Join-Path -Path $inputDir -ChildPath "example.csv"
$csvContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,Value 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Exemple 1 : Traitement avec mise en cache
Write-Host "`n=== Exemple 1 : Traitement avec mise en cache ===" -ForegroundColor Green

# Premier appel (sans cache)
Write-Host "Premier appel (sans cache)..."
$startTime = Get-Date
$cachedOutputPath = Join-Path -Path $cachedDir -ChildPath "cached_output.yaml"
$result1 = Invoke-CachedFileProcessing -InputFile $jsonFilePath -OutputFile $cachedOutputPath -InputFormat "JSON" -OutputFormat "YAML" -CacheTTL 3600
$endTime = Get-Date
$duration1 = ($endTime - $startTime).TotalMilliseconds
Write-Host "Durée du premier appel : $duration1 ms"
Write-Host "Résultat du premier appel : $($result1.Success)"

# Deuxième appel (avec cache)
Write-Host "Deuxième appel (avec cache)..."
$startTime = Get-Date
$cachedOutputPath2 = Join-Path -Path $cachedDir -ChildPath "cached_output2.yaml"
$result2 = Invoke-CachedFileProcessing -InputFile $jsonFilePath -OutputFile $cachedOutputPath2 -InputFormat "JSON" -OutputFormat "YAML" -CacheTTL 3600
$endTime = Get-Date
$duration2 = ($endTime - $startTime).TotalMilliseconds
Write-Host "Durée du deuxième appel : $duration2 ms"
Write-Host "Résultat du deuxième appel : $($result2.Success)"

# Afficher les statistiques du cache
$cacheStats = Get-CacheStatistics
Write-Host "Statistiques du cache :"
$cacheStats | Format-List

# Exemple 2 : Chiffrement et déchiffrement de fichiers
Write-Host "`n=== Exemple 2 : Chiffrement et déchiffrement de fichiers ===" -ForegroundColor Green

# Générer une clé de chiffrement
$password = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
$encryptionKey = New-EncryptionKey -Password $password

# Chiffrer un fichier
$encryptedFilePath = Join-Path -Path $encryptedDir -ChildPath "encrypted.json"
$encryptResult = Protect-SecureFile -InputFile $jsonFilePath -OutputFile $encryptedFilePath -EncryptionKey $encryptionKey -CreateSignature
Write-Host "Chiffrement du fichier : $($encryptResult.Success)"
Write-Host "Fichier chiffré : $($encryptResult.OutputFile)"
Write-Host "Fichier de signature : $($encryptResult.SignatureFile)"

# Afficher les informations sur le fichier chiffré
$encryptedFileInfo = Get-Item -Path $encryptedFilePath
Write-Host "Taille du fichier original : $((Get-Item -Path $jsonFilePath).Length) octets"
Write-Host "Taille du fichier chiffré : $($encryptedFileInfo.Length) octets"

# Déchiffrer le fichier
$decryptedFilePath = Join-Path -Path $decryptedDir -ChildPath "decrypted.json"
$decryptResult = Unprotect-SecureFile -InputFile $encryptedFilePath -OutputFile $decryptedFilePath -EncryptionKey $encryptionKey -VerifySignature
Write-Host "Déchiffrement du fichier : $($decryptResult.Success)"
Write-Host "Fichier déchiffré : $($decryptResult.OutputFile)"

# Vérifier que le fichier déchiffré est identique au fichier original
$originalContent = Get-Content -Path $jsonFilePath -Raw
$decryptedContent = Get-Content -Path $decryptedFilePath -Raw
$isIdentical = $originalContent -eq $decryptedContent
Write-Host "Le fichier déchiffré est identique au fichier original : $isIdentical"

# Exemple 3 : Calcul de hachage et signature de fichiers
Write-Host "`n=== Exemple 3 : Calcul de hachage et signature de fichiers ===" -ForegroundColor Green

# Calculer le hachage d'un fichier
$fileHash = Get-FileHash -FilePath $jsonFilePath -Algorithm "SHA256"
Write-Host "Hachage du fichier : $($fileHash.Hash)"

# Signer un fichier
$signatureFilePath = Join-Path -Path $outputDir -ChildPath "example.json.sig"
$signResult = New-FileSignature -FilePath $jsonFilePath -EncryptionKey $encryptionKey -SignatureFile $signatureFilePath
Write-Host "Signature du fichier : $signResult"

# Vérifier la signature
$verifyResult = Test-FileSignature -FilePath $jsonFilePath -EncryptionKey $encryptionKey -SignatureFile $signatureFilePath
Write-Host "Vérification de la signature : $($verifyResult.IsValid)"
Write-Host "Horodatage de la signature : $($verifyResult.SignatureTimestamp)"

# Exemple 4 : Traitement sécurisé avec chiffrement
Write-Host "`n=== Exemple 4 : Traitement sécurisé avec chiffrement ===" -ForegroundColor Green

# Convertir un fichier CSV en YAML et chiffrer le résultat
$yamlOutputPath = Join-Path -Path $outputDir -ChildPath "example.yaml"
$convertResult = Invoke-SecureFileProcessing -InputFile $csvFilePath -OutputFile $yamlOutputPath -InputFormat "CSV" -OutputFormat "YAML"
Write-Host "Conversion CSV vers YAML : $($convertResult.Success)"

$encryptedYamlPath = Join-Path -Path $encryptedDir -ChildPath "encrypted.yaml"
$encryptYamlResult = Protect-SecureFile -InputFile $yamlOutputPath -OutputFile $encryptedYamlPath -EncryptionKey $encryptionKey
Write-Host "Chiffrement du fichier YAML : $($encryptYamlResult.Success)"

# Déchiffrer le fichier YAML
$decryptedYamlPath = Join-Path -Path $decryptedDir -ChildPath "decrypted.yaml"
$decryptYamlResult = Unprotect-SecureFile -InputFile $encryptedYamlPath -OutputFile $decryptedYamlPath -EncryptionKey $encryptionKey
Write-Host "Déchiffrement du fichier YAML : $($decryptYamlResult.Success)"

# Vérifier que le fichier déchiffré est identique au fichier original
$originalYamlContent = Get-Content -Path $yamlOutputPath -Raw
$decryptedYamlContent = Get-Content -Path $decryptedYamlPath -Raw
$isYamlIdentical = $originalYamlContent -eq $decryptedYamlContent
Write-Host "Le fichier YAML déchiffré est identique au fichier original : $isYamlIdentical"

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."
