<#
.SYNOPSIS
    Test des fonctionnalités de sécurité pour le partage des vues.

.DESCRIPTION
    Ce script teste les fonctionnalités de sécurité pour le partage des vues,
    y compris le chiffrement, l'authentification et le contrôle d'accès.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$encryptionManagerPath = Join-Path -Path $scriptDir -ChildPath "EncryptionManager.ps1"
$authenticationManagerPath = Join-Path -Path $scriptDir -ChildPath "AuthenticationManager.ps1"
$accessControlManagerPath = Join-Path -Path $scriptDir -ChildPath "AccessControlManager.ps1"

if (Test-Path -Path $encryptionManagerPath) {
    . $encryptionManagerPath
} else {
    throw "Le module EncryptionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $encryptionManagerPath"
}

if (Test-Path -Path $authenticationManagerPath) {
    . $authenticationManagerPath
} else {
    throw "Le module AuthenticationManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $authenticationManagerPath"
}

if (Test-Path -Path $accessControlManagerPath) {
    . $accessControlManagerPath
} else {
    throw "Le module AccessControlManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $accessControlManagerPath"
}

# Fonction pour afficher un message formaté
function Write-TestMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $colors = @{
        Info    = "White"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Fonction pour créer un répertoire de test temporaire
function New-TestDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $env:TEMP,

        [Parameter(Mandatory = $false)]
        [string]$DirectoryName = "SecurityTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )

    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName

    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    return $testDir
}

# Fonction pour tester le gestionnaire de chiffrement
function Test-EncryptionManager {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du gestionnaire de chiffrement" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Test 1: Créer un gestionnaire de chiffrement
    Write-TestMessage "Test 1: Création d'un gestionnaire de chiffrement" -Level "Info"

    $encryptionManager = New-EncryptionManager -EnableDebug

    if ($null -ne $encryptionManager) {
        Write-TestMessage "Gestionnaire de chiffrement créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du gestionnaire de chiffrement" -Level "Error"
        return
    }

    # Test 2: Générer une clé AES
    Write-TestMessage "Test 2: Génération d'une clé AES" -Level "Info"

    $aesKey = New-AESKey -EnableDebug

    if ($null -ne $aesKey -and $null -ne $aesKey.Key -and $null -ne $aesKey.IV) {
        Write-TestMessage "Clé AES générée avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la génération de la clé AES" -Level "Error"
        return
    }

    # Test 3: Chiffrer des données avec AES
    Write-TestMessage "Test 3: Chiffrement de données avec AES" -Level "Info"

    $testData = "Ceci est un test de chiffrement AES"
    $testDataBytes = [System.Text.Encoding]::UTF8.GetBytes($testData)

    $encryptedData = Protect-Data -Data $testDataBytes -Method "AES" -KeyData $aesKey -EnableDebug

    if ($null -ne $encryptedData -and $encryptedData.Length -gt 0) {
        Write-TestMessage "Données chiffrées avec succès: $($encryptedData.Length) octets" -Level "Success"
    } else {
        Write-TestMessage "Échec du chiffrement des données" -Level "Error"
        return
    }

    # Test 4: Déchiffrer des données avec AES
    Write-TestMessage "Test 4: Déchiffrement de données avec AES" -Level "Info"

    $decryptedData = Unprotect-Data -EncryptedData $encryptedData -Method "AES" -KeyData $aesKey -EnableDebug

    if ($null -ne $decryptedData -and $decryptedData.Length -gt 0) {
        $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedData)

        if ($decryptedText -eq $testData) {
            Write-TestMessage "Données déchiffrées avec succès: $decryptedText" -Level "Success"
        } else {
            Write-TestMessage "Les données déchiffrées ne correspondent pas aux données originales" -Level "Error"
            return
        }
    } else {
        Write-TestMessage "Échec du déchiffrement des données" -Level "Error"
        return
    }

    # Test 5: Chiffrer un fichier avec AES
    Write-TestMessage "Test 5: Chiffrement d'un fichier avec AES" -Level "Info"

    $testFilePath = Join-Path -Path $testDir -ChildPath "test_file.txt"
    $testData = "Ceci est un test de chiffrement de fichier AES"
    $testData | Out-File -FilePath $testFilePath -Encoding utf8

    $encryptedFilePath = Protect-File -InputPath $testFilePath -Method "AES" -KeyData $aesKey -EnableDebug

    if (-not [string]::IsNullOrEmpty($encryptedFilePath) -and (Test-Path -Path $encryptedFilePath)) {
        Write-TestMessage "Fichier chiffré avec succès: $encryptedFilePath" -Level "Success"
    } else {
        Write-TestMessage "Échec du chiffrement du fichier" -Level "Error"
        return
    }

    # Test 6: Déchiffrer un fichier avec AES
    Write-TestMessage "Test 6: Déchiffrement d'un fichier avec AES" -Level "Info"

    $decryptedFilePath = Unprotect-File -InputPath $encryptedFilePath -Method "AES" -KeyData $aesKey -EnableDebug

    if (-not [string]::IsNullOrEmpty($decryptedFilePath) -and (Test-Path -Path $decryptedFilePath)) {
        $decryptedContent = Get-Content -Path $decryptedFilePath -Raw

        if ($decryptedContent -eq $testData) {
            Write-TestMessage "Fichier déchiffré avec succès: $decryptedFilePath" -Level "Success"
        } else {
            Write-TestMessage "Le contenu du fichier déchiffré ne correspond pas au contenu original" -Level "Error"
            return
        }
    } else {
        Write-TestMessage "Échec du déchiffrement du fichier" -Level "Error"
        return
    }



    Write-TestMessage "Tests du gestionnaire de chiffrement terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le gestionnaire d'authentification
function Test-AuthenticationManager {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du gestionnaire d'authentification" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un chemin de stockage des utilisateurs pour les tests
    $userStorePath = Join-Path -Path $testDir -ChildPath "UserStore"

    # Test 1: Créer un gestionnaire d'authentification
    Write-TestMessage "Test 1: Création d'un gestionnaire d'authentification" -Level "Info"

    $authManager = New-AuthenticationManager -UserStorePath $userStorePath -EnableDebug

    if ($null -ne $authManager) {
        Write-TestMessage "Gestionnaire d'authentification créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du gestionnaire d'authentification" -Level "Error"
        return
    }

    # Test 2: Créer un utilisateur avec authentification par mot de passe
    Write-TestMessage "Test 2: Création d'un utilisateur avec authentification par mot de passe" -Level "Info"

    $username = "testuser"
    $password = "P@ssw0rd"

    $result = New-PasswordUser -Username $username -Password $password -UserStorePath $userStorePath -EnableDebug

    if ($result) {
        Write-TestMessage "Utilisateur créé avec succès: $username" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création de l'utilisateur" -Level "Error"
        return
    }

    # Test 3: Authentifier un utilisateur avec mot de passe
    Write-TestMessage "Test 3: Authentification d'un utilisateur avec mot de passe" -Level "Info"

    $credentials = @{
        Username = $username
        Password = $password
    }

    $authenticated = Test-UserAuthentication -Method "PASSWORD" -Credentials $credentials -UserStorePath $userStorePath -EnableDebug

    if ($authenticated) {
        Write-TestMessage "Utilisateur authentifié avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'authentification de l'utilisateur" -Level "Error"
        return
    }

    # Test 4: Authentifier un utilisateur avec un mot de passe incorrect
    Write-TestMessage "Test 4: Authentification d'un utilisateur avec un mot de passe incorrect" -Level "Info"

    $wrongCredentials = @{
        Username = $username
        Password = "WrongPassword"
    }

    $authenticated = Test-UserAuthentication -Method "PASSWORD" -Credentials $wrongCredentials -UserStorePath $userStorePath -EnableDebug

    if (-not $authenticated) {
        Write-TestMessage "Authentification avec mot de passe incorrect échouée comme prévu" -Level "Success"
    } else {
        Write-TestMessage "L'authentification avec mot de passe incorrect a réussi, ce qui est inattendu" -Level "Error"
        return
    }

    # Test 5: Générer un token d'authentification
    Write-TestMessage "Test 5: Génération d'un token d'authentification" -Level "Info"

    $token = New-AuthToken -Username $username -UserStorePath $userStorePath -EnableDebug

    if ($null -ne $token -and -not [string]::IsNullOrEmpty($token.Token)) {
        Write-TestMessage "Token généré avec succès: $($token.Token)" -Level "Success"
    } else {
        Write-TestMessage "Échec de la génération du token" -Level "Error"
        return
    }

    # Test 6: Authentifier un utilisateur avec un token
    Write-TestMessage "Test 6: Authentification d'un utilisateur avec un token" -Level "Info"

    $authenticated = Test-UserAuthentication -Method "TOKEN" -Credentials $token.Token -UserStorePath $userStorePath -EnableDebug

    if ($authenticated) {
        Write-TestMessage "Utilisateur authentifié avec succès via token" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'authentification de l'utilisateur via token" -Level "Error"
        return
    }

    # Test 7: Révoquer un token
    Write-TestMessage "Test 7: Révocation d'un token" -Level "Info"

    $revoked = Revoke-AuthToken -Token $token.Token -Username $username -UserStorePath $userStorePath -EnableDebug

    if ($revoked) {
        Write-TestMessage "Token révoqué avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la révocation du token" -Level "Error"
        return
    }

    # Test 8: Authentifier un utilisateur avec un token révoqué
    Write-TestMessage "Test 8: Authentification d'un utilisateur avec un token révoqué" -Level "Info"

    $authenticated = Test-UserAuthentication -Method "TOKEN" -Credentials $token.Token -UserStorePath $userStorePath -EnableDebug

    if (-not $authenticated) {
        Write-TestMessage "Authentification avec token révoqué échouée comme prévu" -Level "Success"
    } else {
        Write-TestMessage "L'authentification avec token révoqué a réussi, ce qui est inattendu" -Level "Error"
        return
    }

    Write-TestMessage "Tests du gestionnaire d'authentification terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le gestionnaire de contrôle d'accès
function Test-AccessControlManager {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du gestionnaire de contrôle d'accès" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un chemin de stockage des ACL pour les tests
    $aclStorePath = Join-Path -Path $testDir -ChildPath "ACLStore"

    # Test 1: Créer un gestionnaire de contrôle d'accès
    Write-TestMessage "Test 1: Création d'un gestionnaire de contrôle d'accès" -Level "Info"

    $acManager = New-AccessControlManager -ACLStorePath $aclStorePath -EnableDebug

    if ($null -ne $acManager) {
        Write-TestMessage "Gestionnaire de contrôle d'accès créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du gestionnaire de contrôle d'accès" -Level "Error"
        return
    }

    # Test 2: Créer une ACL pour une ressource
    Write-TestMessage "Test 2: Création d'une ACL pour une ressource" -Level "Info"

    $resourceId = [guid]::NewGuid().ToString()
    $owner = "admin"

    $result = New-ResourceACL -ResourceId $resourceId -Owner $owner -ACLStorePath $aclStorePath -EnableDebug

    if ($result) {
        Write-TestMessage "ACL créée avec succès pour la ressource: $resourceId" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création de l'ACL" -Level "Error"
        return
    }

    # Test 3: Vérifier l'accès du propriétaire
    Write-TestMessage "Test 3: Vérification de l'accès du propriétaire" -Level "Info"

    $hasAccess = Test-ResourceAccess -ResourceId $resourceId -Principal $owner -Permission "READ" -ACLStorePath $aclStorePath -EnableDebug

    if ($hasAccess) {
        Write-TestMessage "Le propriétaire a accès en lecture comme prévu" -Level "Success"
    } else {
        Write-TestMessage "Le propriétaire n'a pas accès en lecture, ce qui est inattendu" -Level "Error"
        return
    }

    # Test 4: Ajouter une entrée à l'ACL
    Write-TestMessage "Test 4: Ajout d'une entrée à l'ACL" -Level "Info"

    $user = "user1"
    $permissions = @("READ")

    $result = Add-ACLEntry -ResourceId $resourceId -Principal $user -Permissions $permissions -GrantedBy $owner -ACLStorePath $aclStorePath -EnableDebug

    if ($result) {
        Write-TestMessage "Entrée ajoutée avec succès à l'ACL" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'ajout de l'entrée à l'ACL" -Level "Error"
        return
    }

    # Test 5: Vérifier l'accès de l'utilisateur
    Write-TestMessage "Test 5: Vérification de l'accès de l'utilisateur" -Level "Info"

    $hasAccess = Test-ResourceAccess -ResourceId $resourceId -Principal $user -Permission "READ" -ACLStorePath $aclStorePath -EnableDebug

    if ($hasAccess) {
        Write-TestMessage "L'utilisateur a accès en lecture comme prévu" -Level "Success"
    } else {
        Write-TestMessage "L'utilisateur n'a pas accès en lecture, ce qui est inattendu" -Level "Error"
        return
    }

    # Test 6: Vérifier l'absence d'accès en écriture
    Write-TestMessage "Test 6: Vérification de l'absence d'accès en écriture" -Level "Info"

    $hasAccess = Test-ResourceAccess -ResourceId $resourceId -Principal $user -Permission "WRITE" -ACLStorePath $aclStorePath -EnableDebug

    if (-not $hasAccess) {
        Write-TestMessage "L'utilisateur n'a pas accès en écriture comme prévu" -Level "Success"
    } else {
        Write-TestMessage "L'utilisateur a accès en écriture, ce qui est inattendu" -Level "Error"
        return
    }

    # Test 7: Supprimer une entrée de l'ACL
    Write-TestMessage "Test 7: Suppression d'une entrée de l'ACL" -Level "Info"

    $result = Remove-ACLEntry -ResourceId $resourceId -Principal $user -RemovedBy $owner -ACLStorePath $aclStorePath -EnableDebug

    if ($result) {
        Write-TestMessage "Entrée supprimée avec succès de l'ACL" -Level "Success"
    } else {
        Write-TestMessage "Échec de la suppression de l'entrée de l'ACL" -Level "Error"
        return
    }

    # Test 8: Vérifier l'absence d'accès après suppression
    Write-TestMessage "Test 8: Vérification de l'absence d'accès après suppression" -Level "Info"

    $hasAccess = Test-ResourceAccess -ResourceId $resourceId -Principal $user -Permission "READ" -ACLStorePath $aclStorePath -EnableDebug

    if (-not $hasAccess) {
        Write-TestMessage "L'utilisateur n'a plus accès en lecture comme prévu" -Level "Success"
    } else {
        Write-TestMessage "L'utilisateur a encore accès en lecture, ce qui est inattendu" -Level "Error"
        return
    }

    # Test 9: Changer le propriétaire de la ressource
    Write-TestMessage "Test 9: Changement du propriétaire de la ressource" -Level "Info"

    $newOwner = "admin2"

    $result = Set-ResourceOwner -ResourceId $resourceId -NewOwner $newOwner -RequestedBy $owner -ACLStorePath $aclStorePath -EnableDebug

    if ($result) {
        Write-TestMessage "Propriétaire changé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec du changement de propriétaire" -Level "Error"
        return
    }

    # Test 10: Vérifier l'accès du nouveau propriétaire
    Write-TestMessage "Test 10: Vérification de l'accès du nouveau propriétaire" -Level "Info"

    $hasAccess = Test-ResourceAccess -ResourceId $resourceId -Principal $newOwner -Permission "ADMIN" -ACLStorePath $aclStorePath -EnableDebug

    if ($hasAccess) {
        Write-TestMessage "Le nouveau propriétaire a accès administrateur comme prévu" -Level "Success"
    } else {
        Write-TestMessage "Le nouveau propriétaire n'a pas accès administrateur, ce qui est inattendu" -Level "Error"
        return
    }

    Write-TestMessage "Tests du gestionnaire de contrôle d'accès terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter tous les tests
Write-TestMessage "Démarrage des tests de sécurité pour le partage des vues" -Level "Info"
Test-EncryptionManager
Test-AuthenticationManager
Test-AccessControlManager
Write-TestMessage "Tous les tests de sécurité pour le partage des vues sont terminés" -Level "Info"
