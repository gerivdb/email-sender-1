#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module EncryptionUtils.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module EncryptionUtils.ps1.
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
$encryptionUtilsPath = Join-Path -Path $modulesPath -ChildPath "EncryptionUtils.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "EncryptionUtilsTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Définir les tests
Describe "Tests du module EncryptionUtils" {
    BeforeAll {
        # Importer le module
        . $encryptionUtilsPath
        
        # Créer des fichiers de test
        $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
        $encryptedFilePath = Join-Path -Path $testTempDir -ChildPath "test.enc"
        $decryptedFilePath = Join-Path -Path $testTempDir -ChildPath "test_decrypted.txt"
        $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test.sig"
        
        # Créer un fichier de test
        $testContent = "Ceci est un fichier de test pour le chiffrement."
        Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
    }
    
    Context "Tests de la fonction New-EncryptionKey" {
        It "Génère une clé à partir d'un mot de passe" {
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $key | Should -Not -BeNullOrEmpty
            $key.Key | Should -Not -BeNullOrEmpty
            $key.KeyBase64 | Should -Not -BeNullOrEmpty
            $key.Salt | Should -Be "EMAIL_SENDER_1_Salt"
            $key.KeySize | Should -Be 256
            $key.Iterations | Should -Be 10000
            $key.HashAlgorithm | Should -Be "SHA256"
        }
        
        It "Génère une clé aléatoire si aucun mot de passe n'est fourni" {
            $key = New-EncryptionKey
            
            $key | Should -Not -BeNullOrEmpty
            $key.Key | Should -Not -BeNullOrEmpty
            $key.KeyBase64 | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests des fonctions Protect-String et Unprotect-String" {
        It "Chiffre et déchiffre correctement une chaîne" {
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $originalString = "Ceci est une chaîne de test pour le chiffrement."
            $encryptedString = Protect-String -InputString $originalString -EncryptionKey $key
            
            $encryptedString | Should -Not -BeNullOrEmpty
            $encryptedString | Should -Not -Be $originalString
            
            $decryptedString = Unprotect-String -EncryptedString $encryptedString -EncryptionKey $key
            
            $decryptedString | Should -Be $originalString
        }
    }
    
    Context "Tests des fonctions Protect-File et Unprotect-File" {
        It "Chiffre et déchiffre correctement un fichier" {
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $encryptedFilePath = Join-Path -Path $testTempDir -ChildPath "test.enc"
            $decryptedFilePath = Join-Path -Path $testTempDir -ChildPath "test_decrypted.txt"
            
            # Chiffrer le fichier
            $encryptResult = Protect-File -InputFile $testFilePath -OutputFile $encryptedFilePath -EncryptionKey $key
            
            $encryptResult | Should -Be $true
            Test-Path -Path $encryptedFilePath | Should -Be $true
            
            # Déchiffrer le fichier
            $decryptResult = Unprotect-File -InputFile $encryptedFilePath -OutputFile $decryptedFilePath -EncryptionKey $key
            
            $decryptResult | Should -Be $true
            Test-Path -Path $decryptedFilePath | Should -Be $true
            
            # Vérifier que le contenu est identique
            $originalContent = Get-Content -Path $testFilePath -Raw
            $decryptedContent = Get-Content -Path $decryptedFilePath -Raw
            
            $decryptedContent | Should -Be $originalContent
        }
    }
    
    Context "Tests de la fonction Get-FileHash" {
        It "Calcule correctement le hachage d'un fichier" {
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            
            $hash = Get-FileHash -FilePath $testFilePath -Algorithm "SHA256"
            
            $hash | Should -Not -BeNullOrEmpty
            $hash.FilePath | Should -Be $testFilePath
            $hash.Algorithm | Should -Be "SHA256"
            $hash.Hash | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Tests des fonctions New-FileSignature et Test-FileSignature" {
        It "Signe et vérifie correctement un fichier" {
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test.sig"
            
            # Signer le fichier
            $signature = New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            $signature | Should -Not -BeNullOrEmpty
            Test-Path -Path $signatureFilePath | Should -Be $true
            
            # Vérifier la signature
            $verifyResult = Test-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            $verifyResult | Should -Not -BeNullOrEmpty
            $verifyResult.IsValid | Should -Be $true
            $verifyResult.FilePath | Should -Be $testFilePath
            $verifyResult.Algorithm | Should -Be "SHA256"
        }
        
        It "Détecte correctement une modification du fichier" {
            $password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test.sig"
            
            # Signer le fichier
            $signature = New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            # Modifier le fichier
            $modifiedContent = "Contenu modifié après la signature."
            Set-Content -Path $testFilePath -Value $modifiedContent -Encoding UTF8
            
            # Vérifier la signature
            $verifyResult = Test-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            $verifyResult | Should -Not -BeNullOrEmpty
            $verifyResult.IsValid | Should -Be $false
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
