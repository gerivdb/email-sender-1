#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de sécurité pour le module EncryptionUtils.ps1.
.DESCRIPTION
    Ce script contient des tests de sécurité pour vérifier la robustesse du module EncryptionUtils.ps1.
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
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "EncryptionSecurityTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Définir les tests
Describe "Tests de sécurité pour le module EncryptionUtils" {
    BeforeAll {
        # Importer le module
        . $encryptionUtilsPath
        
        # Créer des fichiers de test
        $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
        $sensitiveDataPath = Join-Path -Path $testTempDir -ChildPath "sensitive.txt"
        
        # Créer un fichier de test
        $testContent = "Ceci est un fichier de test pour le chiffrement."
        Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
        
        # Créer un fichier avec des données sensibles
        $sensitiveContent = @"
Données sensibles :
Nom d'utilisateur : admin
Mot de passe : P@ssw0rd
Numéro de carte de crédit : 1234-5678-9012-3456
Clé API : abcdef1234567890
"@
        Set-Content -Path $sensitiveDataPath -Value $sensitiveContent -Encoding UTF8
    }
    
    Context "Tests de robustesse des clés de chiffrement" {
        It "Génère des clés différentes pour des mots de passe différents" {
            $password1 = ConvertTo-SecureString -String "MotDePasse1" -AsPlainText -Force
            $password2 = ConvertTo-SecureString -String "MotDePasse2" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password1
            $key2 = New-EncryptionKey -Password $password2
            
            $key1.KeyBase64 | Should -Not -Be $key2.KeyBase64
        }
        
        It "Génère des clés identiques pour le même mot de passe et sel" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $salt = "TestSalt"
            
            $key1 = New-EncryptionKey -Password $password -Salt $salt
            $key2 = New-EncryptionKey -Password $password -Salt $salt
            
            $key1.KeyBase64 | Should -Be $key2.KeyBase64
        }
        
        It "Génère des clés différentes pour le même mot de passe mais des sels différents" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password -Salt "Salt1"
            $key2 = New-EncryptionKey -Password $password -Salt "Salt2"
            
            $key1.KeyBase64 | Should -Not -Be $key2.KeyBase64
        }
        
        It "Génère des clés de la taille spécifiée" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            
            $key128 = New-EncryptionKey -Password $password -KeySize 128
            $key256 = New-EncryptionKey -Password $password -KeySize 256
            
            $key128.Key.Length | Should -Be 16  # 128 bits = 16 octets
            $key256.Key.Length | Should -Be 32  # 256 bits = 32 octets
        }
        
        It "Utilise le nombre d'itérations spécifié" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password -Iterations 1000
            $key2 = New-EncryptionKey -Password $password -Iterations 10000
            
            $key1.Iterations | Should -Be 1000
            $key2.Iterations | Should -Be 10000
            $key1.KeyBase64 | Should -Not -Be $key2.KeyBase64
        }
    }
    
    Context "Tests de robustesse du chiffrement de chaînes" {
        It "Produit des chaînes chiffrées différentes pour la même entrée" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $inputString = "Données sensibles"
            
            $encrypted1 = Protect-String -InputString $inputString -EncryptionKey $key
            $encrypted2 = Protect-String -InputString $inputString -EncryptionKey $key
            
            $encrypted1 | Should -Not -Be $encrypted2  # Les IVs sont générés aléatoirement
        }
        
        It "Ne peut pas déchiffrer avec une clé incorrecte" {
            $password1 = ConvertTo-SecureString -String "MotDePasse1" -AsPlainText -Force
            $password2 = ConvertTo-SecureString -String "MotDePasse2" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password1
            $key2 = New-EncryptionKey -Password $password2
            
            $inputString = "Données sensibles"
            $encrypted = Protect-String -InputString $inputString -EncryptionKey $key1
            
            # Tenter de déchiffrer avec la mauvaise clé
            { Unprotect-String -EncryptedString $encrypted -EncryptionKey $key2 } | Should -Throw
        }
        
        It "Chiffre correctement des chaînes de différentes longueurs" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $shortString = "Court"
            $mediumString = "Chaîne de longueur moyenne"
            $longString = "Chaîne très longue " * 100  # Environ 2000 caractères
            
            # Chiffrer et déchiffrer les chaînes
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
        
        It "Chiffre correctement des chaînes avec des caractères spéciaux" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $specialChars = "!@#$%^&*()_+-=[]{}|;':,./<>?`~éèêëàâäôöùûüÿçÉÈÊËÀÂÄÔÖÙÛÜŸÇ"
            
            # Chiffrer et déchiffrer la chaîne
            $encrypted = Protect-String -InputString $specialChars -EncryptionKey $key
            $decrypted = Unprotect-String -EncryptedString $encrypted -EncryptionKey $key
            
            $decrypted | Should -Be $specialChars
        }
    }
    
    Context "Tests de robustesse du chiffrement de fichiers" {
        It "Produit des fichiers chiffrés différents pour le même fichier d'entrée" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $encryptedPath1 = Join-Path -Path $testTempDir -ChildPath "test1.enc"
            $encryptedPath2 = Join-Path -Path $testTempDir -ChildPath "test2.enc"
            
            # Chiffrer le fichier deux fois
            Protect-File -InputFile $testFilePath -OutputFile $encryptedPath1 -EncryptionKey $key
            Protect-File -InputFile $testFilePath -OutputFile $encryptedPath2 -EncryptionKey $key
            
            # Vérifier que les fichiers chiffrés sont différents
            $encryptedContent1 = Get-Content -Path $encryptedPath1 -Raw -Encoding Byte
            $encryptedContent2 = Get-Content -Path $encryptedPath2 -Raw -Encoding Byte
            
            $encryptedContent1 | Should -Not -Be $encryptedContent2  # Les IVs sont générés aléatoirement
        }
        
        It "Ne peut pas déchiffrer avec une clé incorrecte" {
            $password1 = ConvertTo-SecureString -String "MotDePasse1" -AsPlainText -Force
            $password2 = ConvertTo-SecureString -String "MotDePasse2" -AsPlainText -Force
            
            $key1 = New-EncryptionKey -Password $password1
            $key2 = New-EncryptionKey -Password $password2
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $encryptedPath = Join-Path -Path $testTempDir -ChildPath "test.enc"
            $decryptedPath = Join-Path -Path $testTempDir -ChildPath "test_decrypted.txt"
            
            # Chiffrer le fichier avec la première clé
            Protect-File -InputFile $testFilePath -OutputFile $encryptedPath -EncryptionKey $key1
            
            # Tenter de déchiffrer avec la mauvaise clé
            { Unprotect-File -InputFile $encryptedPath -OutputFile $decryptedPath -EncryptionKey $key2 } | Should -Throw
        }
        
        It "Chiffre correctement des fichiers de différentes tailles" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            # Créer des fichiers de différentes tailles
            $smallFilePath = Join-Path -Path $testTempDir -ChildPath "small.txt"
            $mediumFilePath = Join-Path -Path $testTempDir -ChildPath "medium.txt"
            $largeFilePath = Join-Path -Path $testTempDir -ChildPath "large.txt"
            
            $smallContent = "Petit fichier"
            $mediumContent = "Contenu de taille moyenne " * 100  # Environ 2500 caractères
            $largeContent = "Contenu volumineux " * 1000  # Environ 20000 caractères
            
            Set-Content -Path $smallFilePath -Value $smallContent -Encoding UTF8
            Set-Content -Path $mediumFilePath -Value $mediumContent -Encoding UTF8
            Set-Content -Path $largeFilePath -Value $largeContent -Encoding UTF8
            
            # Chiffrer et déchiffrer les fichiers
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
            
            # Vérifier que les fichiers déchiffrés sont identiques aux originaux
            $decryptedSmallContent = Get-Content -Path $decryptedSmallPath -Raw
            $decryptedMediumContent = Get-Content -Path $decryptedMediumPath -Raw
            $decryptedLargeContent = Get-Content -Path $decryptedLargePath -Raw
            
            $decryptedSmallContent | Should -Be $smallContent
            $decryptedMediumContent | Should -Be $mediumContent
            $decryptedLargeContent | Should -Be $largeContent
        }
    }
    
    Context "Tests de robustesse des signatures" {
        It "Détecte correctement une modification du fichier" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test.sig"
            $modifiedFilePath = Join-Path -Path $testTempDir -ChildPath "test_modified.txt"
            
            # Signer le fichier
            New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            # Créer une copie modifiée du fichier
            $originalContent = Get-Content -Path $testFilePath -Raw
            $modifiedContent = $originalContent + " Contenu modifié."
            Set-Content -Path $modifiedFilePath -Value $modifiedContent -Encoding UTF8
            
            # Vérifier la signature avec le fichier original
            $originalResult = Test-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            # Vérifier la signature avec le fichier modifié
            $modifiedResult = Test-FileSignature -FilePath $modifiedFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            $originalResult.IsValid | Should -Be $true
            $modifiedResult.IsValid | Should -Be $false
        }
        
        It "Détecte correctement une modification mineure du fichier" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test.sig"
            $modifiedFilePath = Join-Path -Path $testTempDir -ChildPath "test_minor_modified.txt"
            
            # Signer le fichier
            New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            # Créer une copie légèrement modifiée du fichier (un seul caractère)
            $originalContent = Get-Content -Path $testFilePath -Raw
            $modifiedContent = $originalContent.Replace("e", "E")  # Remplacer un 'e' par un 'E'
            Set-Content -Path $modifiedFilePath -Value $modifiedContent -Encoding UTF8
            
            # Vérifier la signature avec le fichier modifié
            $modifiedResult = Test-FileSignature -FilePath $modifiedFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
            
            $modifiedResult.IsValid | Should -Be $false
        }
        
        It "Vérifie correctement les signatures avec différents algorithmes de hachage" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $testFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
            
            $algorithms = @("SHA256", "SHA384", "SHA512")
            
            foreach ($algorithm in $algorithms) {
                $signatureFilePath = Join-Path -Path $testTempDir -ChildPath "test_$algorithm.sig"
                
                # Signer le fichier avec l'algorithme spécifié
                New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath -Algorithm $algorithm
                
                # Vérifier la signature
                $result = Test-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
                
                $result.IsValid | Should -Be $true
                $result.Algorithm | Should -Be $algorithm
            }
        }
    }
    
    Context "Tests de sécurité des données sensibles" {
        It "Chiffre correctement les données sensibles" {
            $password = ConvertTo-SecureString -String "MotDePasse" -AsPlainText -Force
            $key = New-EncryptionKey -Password $password
            
            $sensitiveDataPath = Join-Path -Path $testTempDir -ChildPath "sensitive.txt"
            $encryptedPath = Join-Path -Path $testTempDir -ChildPath "sensitive.enc"
            $decryptedPath = Join-Path -Path $testTempDir -ChildPath "sensitive_decrypted.txt"
            
            # Chiffrer le fichier
            Protect-File -InputFile $sensitiveDataPath -OutputFile $encryptedPath -EncryptionKey $key
            
            # Vérifier que le fichier chiffré ne contient pas de données sensibles en clair
            $encryptedContent = Get-Content -Path $encryptedPath -Raw
            $encryptedContent | Should -Not -Match "admin"
            $encryptedContent | Should -Not -Match "P@ssw0rd"
            $encryptedContent | Should -Not -Match "1234-5678-9012-3456"
            $encryptedContent | Should -Not -Match "abcdef1234567890"
            
            # Déchiffrer le fichier
            Unprotect-File -InputFile $encryptedPath -OutputFile $decryptedPath -EncryptionKey $key
            
            # Vérifier que le fichier déchiffré contient les données sensibles
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
