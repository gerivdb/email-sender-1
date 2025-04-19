#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module UnifiedFileProcessor.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module UnifiedFileProcessor.ps1,
    y compris les fonctionnalités de mise en cache et de chiffrement.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules à tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedFileProcessorPath = Join-Path -Path $modulesPath -ChildPath "UnifiedFileProcessor.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "UnifiedFileProcessorTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des sous-répertoires pour les tests
$inputDir = Join-Path -Path $testTempDir -ChildPath "input"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"
$encryptedDir = Join-Path -Path $testTempDir -ChildPath "encrypted"
$decryptedDir = Join-Path -Path $testTempDir -ChildPath "decrypted"
New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
New-Item -Path $encryptedDir -ItemType Directory -Force | Out-Null
New-Item -Path $decryptedDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$jsonFilePath = Join-Path -Path $inputDir -ChildPath "test.json"
$csvFilePath = Join-Path -Path $inputDir -ChildPath "test.csv"
$yamlFilePath = Join-Path -Path $inputDir -ChildPath "test.yaml"

# Créer un fichier JSON de test
$jsonContent = @{
    "name" = "Test Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# Créer un fichier CSV de test
$csvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
Set-Content -Path $csvFilePath -Value $csvContent -Encoding UTF8

# Créer un fichier YAML de test
$yamlContent = @"
name: Test Object
items:
  - id: 1
    value: Item 1
  - id: 2
    value: Item 2
  - id: 3
    value: Item 3
"@
Set-Content -Path $yamlFilePath -Value $yamlContent -Encoding UTF8

# Définir les tests
Describe "Tests du module UnifiedFileProcessor" {
    BeforeAll {
        # Importer le module
        . $unifiedFileProcessorPath
        
        # Initialiser le module avec le cache activé
        $initResult = Initialize-UnifiedFileProcessor -EnableCache -CacheMaxItems 100 -CacheTTL 60
        $initResult | Should -Be $true
    }
    
    Context "Tests de la fonction Initialize-UnifiedFileProcessor" {
        It "Initialise correctement le module" {
            $result = Initialize-UnifiedFileProcessor -Force
            $result | Should -Be $true
        }
        
        It "Initialise correctement le module avec le cache activé" {
            $result = Initialize-UnifiedFileProcessor -Force -EnableCache -CacheMaxItems 200 -CacheTTL 120 -CacheEvictionPolicy "LFU"
            $result | Should -Be $true
        }
    }
    
    Context "Tests de la fonction Invoke-SecureFileProcessing" {
        It "Convertit correctement un fichier JSON en YAML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_yaml.yaml"
            $result = Invoke-SecureFileProcessing -InputFile $jsonFilePath -OutputFile $outputPath -InputFormat "JSON" -OutputFormat "YAML"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier YAML est valide
            $yamlContent = Get-Content -Path $outputPath -Raw
            $yamlContent | Should -Not -BeNullOrEmpty
        }
        
        It "Convertit correctement un fichier CSV en JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "csv_to_json.json"
            $result = Invoke-SecureFileProcessing -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "CSV" -OutputFormat "JSON"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
            
            # Vérifier que le fichier JSON est valide
            $jsonContent = Get-Content -Path $outputPath -Raw
            $jsonContent | Should -Not -BeNullOrEmpty
            { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "Détecte automatiquement le format d'entrée" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "auto_to_json.json"
            $result = Invoke-SecureFileProcessing -InputFile $csvFilePath -OutputFile $outputPath -InputFormat "AUTO" -OutputFormat "JSON"
            
            $result | Should -Be $true
            Test-Path -Path $outputPath | Should -Be $true
        }
    }
    
    Context "Tests de la fonction Invoke-ParallelSecureFileProcessing" {
        It "Traite correctement plusieurs fichiers en parallèle" {
            $files = @($jsonFilePath, $csvFilePath, $yamlFilePath)
            $results = Invoke-ParallelSecureFileProcessing -InputFiles $files -OutputDir $outputDir -InputFormat "AUTO" -OutputFormat "JSON" -ThrottleLimit 3
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3
            $results | ForEach-Object { $_.Success | Should -Be $true }
            
            # Vérifier que les fichiers de sortie existent
            $results | ForEach-Object { Test-Path -Path $_.OutputFile | Should -Be $true }
        }
    }
    
    Context "Tests des fonctions de chiffrement" {
        It "Chiffre et déchiffre correctement un fichier" -Skip:(-not $availableOptionalModules.ContainsKey("EncryptionUtils")) {
            # Générer une clé de chiffrement
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            # Chiffrer un fichier
            $encryptedPath = Join-Path -Path $encryptedDir -ChildPath "test.json.enc"
            $encryptResult = Protect-SecureFile -InputFile $jsonFilePath -OutputFile $encryptedPath -EncryptionKey $key
            
            $encryptResult | Should -Not -BeNullOrEmpty
            $encryptResult.Success | Should -Be $true
            Test-Path -Path $encryptedPath | Should -Be $true
            
            # Déchiffrer le fichier
            $decryptedPath = Join-Path -Path $decryptedDir -ChildPath "test_decrypted.json"
            $decryptResult = Unprotect-SecureFile -InputFile $encryptedPath -OutputFile $decryptedPath -EncryptionKey $key
            
            $decryptResult | Should -Not -BeNullOrEmpty
            $decryptResult.Success | Should -Be $true
            Test-Path -Path $decryptedPath | Should -Be $true
            
            # Vérifier que le contenu est identique
            $originalContent = Get-Content -Path $jsonFilePath -Raw
            $decryptedContent = Get-Content -Path $decryptedPath -Raw
            
            $decryptedContent | Should -Be $originalContent
        }
        
        It "Chiffre et signe correctement un fichier" -Skip:(-not $availableOptionalModules.ContainsKey("EncryptionUtils")) {
            # Générer une clé de chiffrement
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            # Chiffrer et signer un fichier
            $encryptedPath = Join-Path -Path $encryptedDir -ChildPath "test_signed.json.enc"
            $encryptResult = Protect-SecureFile -InputFile $jsonFilePath -OutputFile $encryptedPath -EncryptionKey $key -CreateSignature
            
            $encryptResult | Should -Not -BeNullOrEmpty
            $encryptResult.Success | Should -Be $true
            $encryptResult.SignatureFile | Should -Not -BeNullOrEmpty
            Test-Path -Path $encryptedPath | Should -Be $true
            Test-Path -Path $encryptResult.SignatureFile | Should -Be $true
            
            # Déchiffrer le fichier avec vérification de la signature
            $decryptedPath = Join-Path -Path $decryptedDir -ChildPath "test_signed_decrypted.json"
            $decryptResult = Unprotect-SecureFile -InputFile $encryptedPath -OutputFile $decryptedPath -EncryptionKey $key -VerifySignature -SignatureFile $encryptResult.SignatureFile
            
            $decryptResult | Should -Not -BeNullOrEmpty
            $decryptResult.Success | Should -Be $true
        }
    }
    
    Context "Tests des fonctions de mise en cache" {
        It "Utilise correctement le cache pour les opérations répétitives" -Skip:(-not $availableOptionalModules.ContainsKey("CacheManager")) {
            # Réinitialiser le cache
            Initialize-UnifiedFileProcessor -Force -EnableCache
            
            # Premier appel (sans cache)
            $outputPath1 = Join-Path -Path $outputDir -ChildPath "cached1.json"
            $startTime = Get-Date
            $result1 = Invoke-CachedFileProcessing -InputFile $csvFilePath -OutputFile $outputPath1 -InputFormat "CSV" -OutputFormat "JSON"
            $endTime = Get-Date
            $duration1 = ($endTime - $startTime).TotalMilliseconds
            
            $result1 | Should -Be $true
            Test-Path -Path $outputPath1 | Should -Be $true
            
            # Deuxième appel (avec cache)
            $outputPath2 = Join-Path -Path $outputDir -ChildPath "cached2.json"
            $startTime = Get-Date
            $result2 = Invoke-CachedFileProcessing -InputFile $csvFilePath -OutputFile $outputPath2 -InputFormat "CSV" -OutputFormat "JSON"
            $endTime = Get-Date
            $duration2 = ($endTime - $startTime).TotalMilliseconds
            
            $result2 | Should -Be $true
            Test-Path -Path $outputPath2 | Should -Be $true
            
            # Le deuxième appel devrait être plus rapide
            $duration2 | Should -BeLessThan $duration1
            
            # Vérifier les statistiques du cache
            $stats = Get-CacheStatistics
            $stats.Hits | Should -BeGreaterThan 0
        }
    }
    
    Context "Tests d'intégration" {
        It "Convertit, chiffre et déchiffre correctement un fichier" -Skip:(-not $availableOptionalModules.ContainsKey("EncryptionUtils")) {
            # Générer une clé de chiffrement
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            # Convertir le fichier
            $convertedPath = Join-Path -Path $outputDir -ChildPath "integrated.yaml"
            $convertResult = Invoke-SecureFileProcessing -InputFile $jsonFilePath -OutputFile $convertedPath -InputFormat "JSON" -OutputFormat "YAML"
            
            $convertResult | Should -Be $true
            Test-Path -Path $convertedPath | Should -Be $true
            
            # Chiffrer le fichier converti
            $encryptedPath = Join-Path -Path $encryptedDir -ChildPath "integrated.yaml.enc"
            $encryptResult = Protect-SecureFile -InputFile $convertedPath -OutputFile $encryptedPath -EncryptionKey $key -CreateSignature
            
            $encryptResult | Should -Not -BeNullOrEmpty
            $encryptResult.Success | Should -Be $true
            Test-Path -Path $encryptedPath | Should -Be $true
            
            # Déchiffrer le fichier
            $decryptedPath = Join-Path -Path $decryptedDir -ChildPath "integrated_decrypted.yaml"
            $decryptResult = Unprotect-SecureFile -InputFile $encryptedPath -OutputFile $decryptedPath -EncryptionKey $key -VerifySignature
            
            $decryptResult | Should -Not -BeNullOrEmpty
            $decryptResult.Success | Should -Be $true
            Test-Path -Path $decryptedPath | Should -Be $true
            
            # Vérifier que le contenu est identique
            $convertedContent = Get-Content -Path $convertedPath -Raw
            $decryptedContent = Get-Content -Path $decryptedPath -Raw
            
            $decryptedContent | Should -Be $convertedContent
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
