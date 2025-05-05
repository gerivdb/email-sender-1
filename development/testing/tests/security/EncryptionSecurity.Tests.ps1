#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de sÃ©curitÃ© pour le module EncryptionUtils.ps1.
.DESCRIPTION
    Ce script contient des tests de sÃ©curitÃ© pour vÃ©rifier la robustesse du module EncryptionUtils.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules Ã  tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$encryptionUtilsPath = Join-Path -Path $modulesPath -ChildPath "EncryptionUtils.ps1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "EncryptionSecurityTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# DÃ©finir les tests
Describe "Tests de sÃ©curitÃ© pour le module EncryptionUtils" {
    BeforeAll {
        # Importer le module
        . $encryptionUtilsPath
        
        # CrÃ©er des fichiers de test
        $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
        $sensitiveDataPath = Join-Path -Path $testTempDir -ChildPath "sensitive.txt"
        
        # CrÃ©er un fichier de test
        $testContent = "Ceci est un fichier de test pour le chiffrement."
        Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
        
        # CrÃ©er un fichier avec des donnÃ©es sensibles
        $sensitiveContent = @"
DonnÃ©es sensibles :
Nom d'utilisateur : admin
Mot de passe : P@ssw0rd
NumÃ©ro de carte de crÃ©dit : 1234-5678-9012-3456
ClÃ© API : abcdef1234567890
"@
        Set-Content -Path $sensitiveDataPath -Value $sensitiveContent -Encoding UTF8
    }
    
    Context "Tests de robustesse des clÃ©s de chiffrement" {
        It "GÃ©nÃ¨re des clÃ©s diffÃ©rentes pour des mots de passe diffÃ©rents" {
            $password1 = ConvertTo-SecureString -String "MotDePasse1" -AsPlainText -Force
            $password2 = ConvertTo-SecureString -String "MotDePasse2" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password1
            $key2 = New-EncryptionKey -Password $password2
            
            $key1.KeyBase64 | Should -Not -Be $key2.KeyBase64
        }
        
        It "GÃ©nÃ¨re des clÃ©s identiques pour le mÃªme mot de passe et sel" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $salt = "TestSalt"
            
            $key1 = New-EncryptionKey -Password $password -Salt $salt
            $key2 = New-EncryptionKey -Password $password -Salt $salt
            
            $key1.KeyBase64 | Should -Be $key2.KeyBase64
        }
        
        It "GÃ©nÃ¨re des clÃ©s diffÃ©rentes pour le mÃªme mot de passe mais des sels diffÃ©rents" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password -Salt "Salt1"
            $key2 = New-EncryptionKey -Password $password -Salt "Salt2"
            
            $key1.KeyBase64 | Should -Not -Be $key2.KeyBase64
        }
        
        It "GÃ©nÃ¨re des clÃ©s de la taille spÃ©cifiÃ©e" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            
            $key128 = New-EncryptionKey -Password $password -KeySize 128
            $key256 = New-EncryptionKey -Password $password -KeySize 256
            
            $key128.Key.Length | Should -Be 16  # 128 bits = 16 octets
            $key256.Key.Length | Should -Be 32  # 256 bits = 32 octets
        }
        
        It "Utilise le nombre d'itÃ©rations spÃ©cifiÃ©" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password -Iterations 1000
            $key2 = New-EncryptionKey -Password $password -Iterations 10000
            
            $key1.Iterations | Should -Be 1000
            $key2.Iterations | Should -Be 10000
            $key1.KeyBase64 | Should -Not -Be $key2.KeyBase64
        }
    }
    
    Context "Tests de robustesse du chiffrement de chaÃ®nes" {
        It "Produit des chaÃ®nes chiffrÃ©es diffÃ©rentes pour la mÃªme entrÃ©e" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $inputString = "DonnÃ©es sensibles"
            
            $encrypted1 = Protect-String -InputString $inputString -EncryptionKey $key
            $encrypted2 = Protect-String -InputString $inputString -EncryptionKey $key
            
            $encrypted1 | Should -Not -Be $encrypted2  # Les IVs sont gÃ©nÃ©rÃ©s alÃ©atoirement
        }
        
        It "Ne peut pas dÃ©chiffrer avec une clÃ© incorrecte" {
            $password1 = ConvertTo-SecureString -String "MotDePasse1" -AsPlainText -Force
            $password2 = ConvertTo-SecureString -String "MotDePasse2" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password1
            $key2 = New-EncryptionKey -Password $password2
            
            $inputString = "DonnÃ©es sensibles"
            $encrypted = Protect-String -InputString $inputString -EncryptionKey $key1
            
            # Tenter de dÃ©chiffrer avec la mauvaise clÃ©
            { Unprotect-String -EncryptedString $encrypted -EncryptionKey $key2 } | Should -Throw
        }
        
        It "Chiffre correctement des chaÃ®nes de diffÃ©rentes longueurs" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $shortString = "Court"
            $mediumString = "ChaÃ®ne de longueur moyenne"
            $longString = "ChaÃ®ne trÃ¨s longue " * 100  # Environ 2000 caractÃ¨res
            
            # Chiffrer et dÃ©chiffrer les chaÃ®nes
            $encryptedShort = Protect-String -InputString $shortString -EncryptionKey $key
            $encryptedMedium = Protect-String -InputString $mediumString -EncryptionKey $key
            $encryptedLong = Protect-String -InputString $longString -EncryptionKey $key
            
            $decryptedShort = Unprotect-String -EncryptedString $encryptedShort -EncryptionKey $key
            $decryptedMedium = Unprotect-String -EncryptedString $encryptedMedium -EncryptionKey $key
            $decryptedLong = Unprotect-String -EncryptedString $encryptedLong -EncryptionKey $key
            
            $decryptedShort | Should -Be $shortString
            $decryptedMedium | Should -Be $mediumString
            $decryptedLong | Should -Be $longString
        }
        
        It "Chiffre correctement des chaÃ®nes avec des caractÃ¨res spÃ©ciaux" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $specialChars = "!@#$%^&*()_+-=[]{}|;':,./<>?`~Ã©Ã¨ÃªÃ«Ã Ã¢Ã¤Ã´Ã¶Ã¹Ã»Ã¼Ã¿Ã§Ã‰ÃˆÃŠÃ‹Ã€Ã‚Ã„Ã”Ã–Ã™Ã›ÃœÅ¸Ã‡"
            
            # Chiffrer et dÃ©chiffrer la chaÃ®ne
            $encrypted = Protect-String -InputString $specialChars -EncryptionKey $key
            $decrypted = Unprotect-String -EncryptedString $encrypted -EncryptionKey $key
            
            $decrypted | Should -Be $specialChars
        }
    }
    
    Context "Tests de robustesse du chiffrement de fichiers" {
        It "Produit des fichiers chiffrÃ©s diffÃ©rents pour le mÃªme fichier d'entrÃ©e" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $encryptedPath1 = Join-Path -Path $testTempDir -ChildPath "test1.enc"
            $encryptedPath2 = Join-Path -Path $testTempDir -ChildPath "test2.enc"
            
            # Chiffrer le fichier deux fois
            Protect-File -InputFile $testFilePath -OutputFile $encryptedPath1 -EncryptionKey $key
            Protect-File -InputFile $testFilePath -OutputFile $encryptedPath2 -EncryptionKey $key
            
            # VÃ©rifier que les fichiers chiffrÃ©s sont diffÃ©rents
            $encryptedContent1 = Get-Content -Path $encryptedPath1 -Raw -Encoding Byte
            $encryptedContent2 = Get-Content -Path $encryptedPath2 -Raw -Encoding Byte
            
            $encryptedContent1 | Should -Not -Be $encryptedContent2  # Les IVs sont gÃ©nÃ©rÃ©s alÃ©atoirement
        }
        
        It "Ne peut pas dÃ©chiffrer avec une clÃ© incorrecte" {
            $password1 = ConvertTo-SecureString -String "MotDePasse1" -AsPlainText -Force
            $password2 = ConvertTo-SecureString -String "MotDePasse2" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password1
            $key2 = New-EncryptionKey -Password $password2
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $encryptedPath = Join-Path -Path $testTempDir -ChildPath "test.enc"
            $decryptedPath = Join-Path -Path $testTempDir -ChildPath "test_decrypted.txt"
            
            # Chiffrer le fichier avec la premiÃ¨re clÃ©
            Protect-File -InputFile $testFilePath -OutputFile $encryptedPath -EncryptionKey $key1
            
            # Tenter de dÃ©chiffrer avec la mauvaise clÃ©
            { Unprotect-File -InputFile $encryptedPath -OutputFile $decryptedPath -EncryptionKey $key2 } | Should -Throw
        }
        
        It "Chiffre correctement des fichiers de diffÃ©rentes tailles" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            # CrÃ©er des fichiers de diffÃ©rentes tailles
            $smallFilePath = Join-Path -Path $testTempDir -ChildPath "small.txt"
            $mediumFilePath = Join-Path -Path $testTempDir -ChildPath "medium.txt"
            $largeFilePath = Join-Path -Path $testTempDir -ChildPath "large.txt"
            
            $smallContent = "Petit fichier"
            $mediumContent = "Contenu de taille moyenne " * 100  # Environ 2500 caractÃ¨res
            $largeContent = "Contenu volumineux " * 1000  # Environ 20000 caractÃ¨res
            
            Set-Content -Path $smallFilePath -Value $smallContent -Encoding UTF8
            Set-Content -Path $mediumFilePath -Value $mediumContent -Encoding UTF8
            Set-Content -Path $largeFilePath -Value $largeContent -Encoding UTF8
            
            # Chiffrer et dÃ©chiffrer les fichiers
            $encryptedSmallPath = Join-Path -Path $testTempDir -ChildPath "small.enc"
            $encryptedMediumPath = Join-Path -Path $testTempDir -ChildPath "medium.enc"
            $encryptedLargePath = Join-Path -Path $testTempDir -ChildPath "large.enc"
            
            $decryptedSmallPath = Join-Path -Path $testTempDir -ChildPath "small_decrypted.txt"
            $decryptedMediumPath = Join-Path -Path $testTempDir -ChildPath "medium_decrypted.txt"
            $decryptedLargePath = Join-Path -Path $testTempDir -ChildPath "large_decrypted.txt"
            
            Protect-File -InputFile $smallFilePath -OutputFile $encryptedSmallPath -EncryptionKey $key
            Protect-File -InputFile $mediumFilePath -OutputFile $encryptedMediumPath -EncryptionKey $key
            Protect-File -InputFile $largeFilePath -OutputFile $encryptedLargePath -EncryptionKey $key
            
            Unprotect-File -InputFile $encryptedSmallPath -OutputFile $decryptedSmallPath -EncryptionKey $key
            Unprotect-File -InputFile $encryptedMediumPath -OutputFile $decryptedMediumPath -EncryptionKey $key
            Unprotect-File -InputFile $encryptedLargePath -OutputFile $decryptedLargePath -EncryptionKey $key
            
            # VÃ©rifier que les fichiers dÃ©chiffrÃ©s sont identiques aux originaux
            $decryptedSmallContent = Get-Content -Path $decryptedSmallPath -Raw
            $decryptedMediumContent = Get-Content -Path $decryptedMediumPath -Raw
            $decryptedLargeContent = Get-Content -Path $decryptedLargePath -Raw
            
            $decryptedSmallContent | Should -Be $smallContent
            $decryptedMediumContent | Should -Be $mediumContent
            $decryptedLargeContent | Should -Be $largeContent
        }
    }
    
    Context "Tests de robustesse des signatures" {
        It "DÃ©tecte correctement une modification du fichier" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test.sig"
            $modifiedFilePath = Join-Path -Path $testTempDir -ChildPath "test_modified.txt"
            
            # Signer le fichier
            New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            # CrÃ©er une copie modifiÃ©e du fichier
            $originalContent = Get-Content -Path $testFilePath -Raw
            $modifiedContent = $originalContent + " Contenu modifiÃ©."
            Set-Content -Path $modifiedFilePath -Value $modifiedContent -Encoding UTF8
            
            # VÃ©rifier la signature avec le fichier original
            $originalResult = Test-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            # VÃ©rifier la signature avec le fichier modifiÃ©
            $modifiedResult = Test-FileSignature -FilePath $modifiedFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            $originalResult.IsValid | Should -Be $true
            $modifiedResult.IsValid | Should -Be $false
        }
        
        It "DÃ©tecte correctement une modification mineure du fichier" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test.sig"
            $modifiedFilePath = Join-Path -Path $testTempDir -ChildPath "test_minor_modified.txt"
            
            # Signer le fichier
            New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            # CrÃ©er une copie lÃ©gÃ¨rement modifiÃ©e du fichier (un seul caractÃ¨re)
            $originalContent = Get-Content -Path $testFilePath -Raw
            $modifiedContent = $originalContent.Replace("e", "E")  # Remplacer un 'e' par un 'E'
            Set-Content -Path $modifiedFilePath -Value $modifiedContent -Encoding UTF8
            
            # VÃ©rifier la signature avec le fichier modifiÃ©
            $modifiedResult = Test-FileSignature -FilePath $modifiedFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            $modifiedResult.IsValid | Should -Be $false
        }
        
        It "VÃ©rifie correctement les signatures avec diffÃ©rents algorithmes de hachage" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            
            $algorithms = @("SHA256", "SHA384", "SHA512")
            
            foreach ($algorithm in $algorithms) {
                $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test_$algorithm.sig"
                
                # Signer le fichier avec l'algorithme spÃ©cifiÃ©
                New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath -Algorithm $algorithm
                
                # VÃ©rifier la signature
                $result = Test-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
                
                $result.IsValid | Should -Be $true
                $result.Algorithm | Should -Be $algorithm
            }
        }
    }
    
    Context "Tests de sÃ©curitÃ© des donnÃ©es sensibles" {
        It "Chiffre correctement les donnÃ©es sensibles" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $sensitiveDataPath = Join-Path -Path $testTempDir -ChildPath "sensitive.txt"
            $encryptedPath = Join-Path -Path $testTempDir -ChildPath "sensitive.enc"
            $decryptedPath = Join-Path -Path $testTempDir -ChildPath "sensitive_decrypted.txt"
            
            # Chiffrer le fichier
            Protect-File -InputFile $sensitiveDataPath -OutputFile $encryptedPath -EncryptionKey $key
            
            # VÃ©rifier que le fichier chiffrÃ© ne contient pas de donnÃ©es sensibles en clair
            $encryptedContent = Get-Content -Path $encryptedPath -Raw
            $encryptedContent | Should -Not -Match "admin"
            $encryptedContent | Should -Not -Match "P@ssw0rd"
            $encryptedContent | Should -Not -Match "1234-5678-9012-3456"
            $encryptedContent | Should -Not -Match "abcdef1234567890"
            
            # DÃ©chiffrer le fichier
            Unprotect-File -InputFile $encryptedPath -OutputFile $decryptedPath -EncryptionKey $key
            
            # VÃ©rifier que le fichier dÃ©chiffrÃ© contient les donnÃ©es sensibles
            $decryptedContent = Get-Content -Path $decryptedPath -Raw
            $decryptedContent | Should -Match "admin"
            $decryptedContent | Should -Match "P@ssw0rd"
            $decryptedContent | Should -Match "1234-5678-9012-3456"
            $decryptedContent | Should -Match "abcdef1234567890"
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
