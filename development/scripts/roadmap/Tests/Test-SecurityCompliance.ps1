# Test-SecurityCompliance.ps1
# Tests unitaires pour les modules de sécurité et conformité
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Tests unitaires pour les modules de sécurité et conformité.

.DESCRIPTION
    Ce script contient des tests unitaires pour les modules de sécurité et conformité,
    notamment le chiffrement, l'authentification multi-facteurs, la gestion des accès et la conformité RGPD.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$securityPath = Join-Path -Path $parentPath -ChildPath "security"

$protectRoadmapDataPath = Join-Path -Path $securityPath -ChildPath "Protect-RoadmapData.ps1"
$enableMultiFactorAuthPath = Join-Path -Path $securityPath -ChildPath "Enable-MultiFactorAuth.ps1"
$manageAccessControlPath = Join-Path -Path $securityPath -ChildPath "Manage-AccessControl.ps1"
$ensureGDPRCompliancePath = Join-Path -Path $securityPath -ChildPath "Ensure-GDPRCompliance.ps1"

# Charger les modules
Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $protectRoadmapDataPath) {
    . $protectRoadmapDataPath
    Write-Host "  Module Protect-RoadmapData.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Protect-RoadmapData.ps1 introuvable à l'emplacement: $protectRoadmapDataPath"
    exit
}

if (Test-Path $enableMultiFactorAuthPath) {
    . $enableMultiFactorAuthPath
    Write-Host "  Module Enable-MultiFactorAuth.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Enable-MultiFactorAuth.ps1 introuvable à l'emplacement: $enableMultiFactorAuthPath"
    exit
}

if (Test-Path $manageAccessControlPath) {
    . $manageAccessControlPath
    Write-Host "  Module Manage-AccessControl.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Manage-AccessControl.ps1 introuvable à l'emplacement: $manageAccessControlPath"
    exit
}

if (Test-Path $ensureGDPRCompliancePath) {
    . $ensureGDPRCompliancePath
    Write-Host "  Module Ensure-GDPRCompliance.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Ensure-GDPRCompliance.ps1 introuvable à l'emplacement: $ensureGDPRCompliancePath"
    exit
}

# Créer le dossier de tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "output"
if (-not (Test-Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Tests pour le module Protect-RoadmapData.ps1
function Test-ProtectRoadmapData {
    Write-Host
    Write-Host "=== TESTS POUR PROTECT-ROADMAPDATA.PS1 ===" -ForegroundColor Cyan
    
    # Test 1: Génération d'une clé de chiffrement
    Write-Host "Test 1: Génération d'une clé de chiffrement..." -ForegroundColor Yellow
    $keyPath = Join-Path -Path $testOutputPath -ChildPath "test-key.xml"
    $password = "TestPassword123!"
    
    $key = New-EncryptionKey -KeySize 256 -KeyPath $keyPath -Password $password
    
    if ($null -ne $key -and (Test-Path $keyPath)) {
        Write-Host "  SUCCÈS: Clé de chiffrement générée avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la génération de la clé de chiffrement." -ForegroundColor Red
        return $false
    }
    
    # Test 2: Chargement d'une clé de chiffrement
    Write-Host "Test 2: Chargement d'une clé de chiffrement..." -ForegroundColor Yellow
    
    $loadedKey = Get-EncryptionKey -KeyPath $keyPath -Password $password
    
    if ($null -ne $loadedKey -and $loadedKey.KeySize -eq 256) {
        Write-Host "  SUCCÈS: Clé de chiffrement chargée avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec du chargement de la clé de chiffrement." -ForegroundColor Red
        return $false
    }
    
    # Test 3: Chiffrement d'un fichier
    Write-Host "Test 3: Chiffrement d'un fichier..." -ForegroundColor Yellow
    $testFilePath = Join-Path -Path $testOutputPath -ChildPath "test-file.txt"
    $encryptedFilePath = Join-Path -Path $testOutputPath -ChildPath "test-file.enc"
    
    "Ceci est un fichier de test pour le chiffrement." | Out-File -FilePath $testFilePath -Encoding UTF8
    
    $encryptResult = Protect-RoadmapFile -FilePath $testFilePath -Key $loadedKey -OutputPath $encryptedFilePath -AddChecksum
    
    if ($null -ne $encryptResult -and (Test-Path $encryptedFilePath)) {
        Write-Host "  SUCCÈS: Fichier chiffré avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec du chiffrement du fichier." -ForegroundColor Red
        return $false
    }
    
    # Test 4: Déchiffrement d'un fichier
    Write-Host "Test 4: Déchiffrement d'un fichier..." -ForegroundColor Yellow
    $decryptedFilePath = Join-Path -Path $testOutputPath -ChildPath "test-file-decrypted.txt"
    
    $decryptResult = Unprotect-RoadmapFile -FilePath $encryptedFilePath -Key $loadedKey -OutputPath $decryptedFilePath -VerifyChecksum
    
    if ($null -ne $decryptResult -and (Test-Path $decryptedFilePath)) {
        $originalContent = Get-Content -Path $testFilePath -Raw
        $decryptedContent = Get-Content -Path $decryptedFilePath -Raw
        
        if ($originalContent -eq $decryptedContent) {
            Write-Host "  SUCCÈS: Fichier déchiffré avec succès et contenu identique." -ForegroundColor Green
        } else {
            Write-Host "  ÉCHEC: Le contenu du fichier déchiffré ne correspond pas au contenu original." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "  ÉCHEC: Échec du déchiffrement du fichier." -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Tests pour le module Enable-MultiFactorAuth.ps1
function Test-EnableMultiFactorAuth {
    Write-Host
    Write-Host "=== TESTS POUR ENABLE-MULTIFACTORAUTH.PS1 ===" -ForegroundColor Cyan
    
    # Test 1: Génération d'une clé secrète TOTP
    Write-Host "Test 1: Génération d'une clé secrète TOTP..." -ForegroundColor Yellow
    $secretPath = Join-Path -Path $testOutputPath -ChildPath "test-totp-secret.json"
    
    $secret = New-TOTPSecret -SecretLength 20 -OutputPath $secretPath -UserId "test-user" -AppName "Test App"
    
    if ($null -ne $secret -and (Test-Path $secretPath)) {
        Write-Host "  SUCCÈS: Clé secrète TOTP générée avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la génération de la clé secrète TOTP." -ForegroundColor Red
        return $false
    }
    
    # Test 2: Chargement d'une clé secrète TOTP
    Write-Host "Test 2: Chargement d'une clé secrète TOTP..." -ForegroundColor Yellow
    
    $loadedSecret = Get-TOTPSecret -SecretPath $secretPath
    
    if ($null -ne $loadedSecret -and $loadedSecret.UserId -eq "test-user") {
        Write-Host "  SUCCÈS: Clé secrète TOTP chargée avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec du chargement de la clé secrète TOTP." -ForegroundColor Red
        return $false
    }
    
    # Test 3: Génération d'un code TOTP
    Write-Host "Test 3: Génération d'un code TOTP..." -ForegroundColor Yellow
    
    $code = Get-TOTPCode -Secret $loadedSecret
    
    if ($null -ne $code -and $code.Length -eq $loadedSecret.Digits) {
        Write-Host "  SUCCÈS: Code TOTP généré avec succès: $code" -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la génération du code TOTP." -ForegroundColor Red
        return $false
    }
    
    # Test 4: Vérification d'un code TOTP
    Write-Host "Test 4: Vérification d'un code TOTP..." -ForegroundColor Yellow
    
    $result = Test-TOTPCode -Secret $loadedSecret -Code $code
    
    if ($result) {
        Write-Host "  SUCCÈS: Code TOTP vérifié avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la vérification du code TOTP." -ForegroundColor Red
        return $false
    }
    
    # Test 5: Enregistrement d'un appareil pour MFA
    Write-Host "Test 5: Enregistrement d'un appareil pour MFA..." -ForegroundColor Yellow
    $registrationPath = Join-Path -Path $testOutputPath -ChildPath "test-mfa-device.json"
    
    $registration = Register-MFADevice -UserId "test-user" -DeviceName "Test Device" -AppName "Test App" -ContactEmail "test@example.com" -OutputPath $registrationPath
    
    if ($null -ne $registration -and (Test-Path $registrationPath)) {
        Write-Host "  SUCCÈS: Appareil enregistré pour MFA avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de l'enregistrement de l'appareil pour MFA." -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Tests pour le module Manage-AccessControl.ps1
function Test-ManageAccessControl {
    Write-Host
    Write-Host "=== TESTS POUR MANAGE-ACCESSCONTROL.PS1 ===" -ForegroundColor Cyan
    
    # Test 1: Création d'un utilisateur
    Write-Host "Test 1: Création d'un utilisateur..." -ForegroundColor Yellow
    $userPath = Join-Path -Path $testOutputPath -ChildPath "test-user.json"
    
    $user = New-RoadmapUser -UserId "test-user" -FullName "Test User" -Email "test@example.com" -Roles @("Editor", "Viewer") -OutputPath $userPath
    
    if ($null -ne $user -and (Test-Path $userPath)) {
        Write-Host "  SUCCÈS: Utilisateur créé avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la création de l'utilisateur." -ForegroundColor Red
        return $false
    }
    
    # Test 2: Obtention des informations d'un utilisateur
    Write-Host "Test 2: Obtention des informations d'un utilisateur..." -ForegroundColor Yellow
    
    $loadedUser = Get-RoadmapUser -UserPath $userPath
    
    if ($null -ne $loadedUser -and $loadedUser.UserId -eq "test-user") {
        Write-Host "  SUCCÈS: Informations de l'utilisateur obtenues avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de l'obtention des informations de l'utilisateur." -ForegroundColor Red
        return $false
    }
    
    # Test 3: Mise à jour d'un utilisateur
    Write-Host "Test 3: Mise à jour d'un utilisateur..." -ForegroundColor Yellow
    
    $updatedUser = Update-RoadmapUser -User $loadedUser -FullName "Updated Test User" -Roles @("Admin") -OutputPath $userPath
    
    if ($null -ne $updatedUser -and $updatedUser.FullName -eq "Updated Test User" -and $updatedUser.Roles -contains "Admin") {
        Write-Host "  SUCCÈS: Utilisateur mis à jour avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la mise à jour de l'utilisateur." -ForegroundColor Red
        return $false
    }
    
    # Test 4: Vérification des permissions d'un utilisateur
    Write-Host "Test 4: Vérification des permissions d'un utilisateur..." -ForegroundColor Yellow
    
    $hasPermission = Test-UserPermission -User $updatedUser -Permission "roadmap:create"
    
    if ($hasPermission) {
        Write-Host "  SUCCÈS: Permission vérifiée avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la vérification de la permission." -ForegroundColor Red
        return $false
    }
    
    # Test 5: Ajout d'une entrée au journal d'audit
    Write-Host "Test 5: Ajout d'une entrée au journal d'audit..." -ForegroundColor Yellow
    $logPath = Join-Path -Path $testOutputPath -ChildPath "test-audit-log.json"
    
    $logEntry = Add-SecurityAuditLog -Action "TestAction" -UserId "test-user" -TargetId "test-target" -Details "Test details" -LogPath $logPath
    
    if ($null -ne $logEntry -and (Test-Path $logPath)) {
        Write-Host "  SUCCÈS: Entrée ajoutée au journal d'audit avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de l'ajout de l'entrée au journal d'audit." -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Tests pour le module Ensure-GDPRCompliance.ps1
function Test-EnsureGDPRCompliance {
    Write-Host
    Write-Host "=== TESTS POUR ENSURE-GDPRCOMPLIANCE.PS1 ===" -ForegroundColor Cyan
    
    # Test 1: Enregistrement du consentement d'un utilisateur
    Write-Host "Test 1: Enregistrement du consentement d'un utilisateur..." -ForegroundColor Yellow
    $consentPath = Join-Path -Path $testOutputPath -ChildPath "test-consent.json"
    
    $consent = Register-UserConsent -UserId "test-user" -ConsentType "Analytics" -ConsentValue "Granted" -OutputPath $consentPath
    
    if ($null -ne $consent -and (Test-Path $consentPath)) {
        Write-Host "  SUCCÈS: Consentement enregistré avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de l'enregistrement du consentement." -ForegroundColor Red
        return $false
    }
    
    # Test 2: Vérification du consentement d'un utilisateur
    Write-Host "Test 2: Vérification du consentement d'un utilisateur..." -ForegroundColor Yellow
    
    $hasConsent = Test-UserConsent -UserId "test-user" -ConsentType "Analytics" -ConsentPath $consentPath
    
    if ($hasConsent) {
        Write-Host "  SUCCÈS: Consentement vérifié avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la vérification du consentement." -ForegroundColor Red
        return $false
    }
    
    # Test 3: Anonymisation des données personnelles
    Write-Host "Test 3: Anonymisation des données personnelles..." -ForegroundColor Yellow
    $dataPath = Join-Path -Path $testOutputPath -ChildPath "test-data.json"
    $anonymizedPath = Join-Path -Path $testOutputPath -ChildPath "test-data-anonymized.json"
    
    @"
{
    "users": [
        {
            "id": "user1",
            "name": "John Doe",
            "email": "john.doe@example.com",
            "phone": "+1-555-123-4567",
            "address": "123 Main St, New York, NY 10001",
            "ip": "192.168.1.1"
        }
    ]
}
"@ | Out-File -FilePath $dataPath -Encoding UTF8
    
    $anonymization = Invoke-DataAnonymization -FilePath $dataPath -OutputPath $anonymizedPath -DataTypes @("Email", "Name", "Phone") -PreserveFormat
    
    if ($null -ne $anonymization -and (Test-Path $anonymizedPath)) {
        $anonymizedContent = Get-Content -Path $anonymizedPath -Raw
        
        if ($anonymizedContent -notmatch "john\.doe@example\.com" -and $anonymizedContent -notmatch "John Doe" -and $anonymizedContent -notmatch "\+1-555-123-4567") {
            Write-Host "  SUCCÈS: Données anonymisées avec succès." -ForegroundColor Green
        } else {
            Write-Host "  ÉCHEC: Les données n'ont pas été correctement anonymisées." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "  ÉCHEC: Échec de l'anonymisation des données." -ForegroundColor Red
        return $false
    }
    
    # Test 4: Création d'une demande d'accès aux données
    Write-Host "Test 4: Création d'une demande d'accès aux données..." -ForegroundColor Yellow
    $requestPath = Join-Path -Path $testOutputPath -ChildPath "test-data-request.json"
    
    $request = New-DataAccessRequest -UserId "test-user" -RequestType "Access" -RequestDetails "Test request" -ContactEmail "test@example.com" -OutputPath $requestPath
    
    if ($null -ne $request -and (Test-Path $requestPath)) {
        Write-Host "  SUCCÈS: Demande d'accès aux données créée avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la création de la demande d'accès aux données." -ForegroundColor Red
        return $false
    }
    
    # Test 5: Mise à jour d'une demande d'accès aux données
    Write-Host "Test 5: Mise à jour d'une demande d'accès aux données..." -ForegroundColor Yellow
    
    $updatedRequest = Update-DataAccessRequest -RequestPath $requestPath -Status "InProgress" -AssignedTo "admin" -Note "Test note"
    
    if ($null -ne $updatedRequest -and $updatedRequest.Status -eq "InProgress" -and $updatedRequest.AssignedTo -eq "admin") {
        Write-Host "  SUCCÈS: Demande d'accès aux données mise à jour avec succès." -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la mise à jour de la demande d'accès aux données." -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Exécuter tous les tests
function Invoke-AllTests {
    $allTestsPassed = $true
    
    Write-Host
    Write-Host "=== EXÉCUTION DE TOUS LES TESTS ===" -ForegroundColor Cyan
    Write-Host
    
    # Test du module Protect-RoadmapData.ps1
    $protectRoadmapDataResult = Test-ProtectRoadmapData
    if (-not $protectRoadmapDataResult) {
        $allTestsPassed = $false
    }
    
    # Test du module Enable-MultiFactorAuth.ps1
    $enableMultiFactorAuthResult = Test-EnableMultiFactorAuth
    if (-not $enableMultiFactorAuthResult) {
        $allTestsPassed = $false
    }
    
    # Test du module Manage-AccessControl.ps1
    $manageAccessControlResult = Test-ManageAccessControl
    if (-not $manageAccessControlResult) {
        $allTestsPassed = $false
    }
    
    # Test du module Ensure-GDPRCompliance.ps1
    $ensureGDPRComplianceResult = Test-EnsureGDPRCompliance
    if (-not $ensureGDPRComplianceResult) {
        $allTestsPassed = $false
    }
    
    # Afficher le résultat global
    Write-Host
    if ($allTestsPassed) {
        Write-Host "TOUS LES TESTS ONT RÉUSSI!" -ForegroundColor Green
    } else {
        Write-Host "CERTAINS TESTS ONT ÉCHOUÉ!" -ForegroundColor Red
    }
    
    return $allTestsPassed
}

# Exécuter tous les tests
$testResult = Invoke-AllTests
