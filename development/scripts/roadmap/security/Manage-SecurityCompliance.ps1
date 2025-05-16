# Manage-SecurityCompliance.ps1
# Script principal pour les fonctionnalités de sécurité et conformité
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Script principal pour les fonctionnalités de sécurité et conformité.

.DESCRIPTION
    Ce script fournit une interface utilisateur pour les fonctionnalités de sécurité et conformité,
    notamment le chiffrement, l'authentification multi-facteurs, la gestion des accès et la conformité RGPD.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$securityPath = Join-Path -Path $scriptPath -ChildPath "security"

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
    Write-Host "  Module Protect-RoadmapData.ps1 introuvable à l'emplacement: $protectRoadmapDataPath" -ForegroundColor Red
    exit
}

if (Test-Path $enableMultiFactorAuthPath) {
    . $enableMultiFactorAuthPath
    Write-Host "  Module Enable-MultiFactorAuth.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Enable-MultiFactorAuth.ps1 introuvable à l'emplacement: $enableMultiFactorAuthPath" -ForegroundColor Red
    exit
}

if (Test-Path $manageAccessControlPath) {
    . $manageAccessControlPath
    Write-Host "  Module Manage-AccessControl.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Manage-AccessControl.ps1 introuvable à l'emplacement: $manageAccessControlPath" -ForegroundColor Red
    exit
}

if (Test-Path $ensureGDPRCompliancePath) {
    . $ensureGDPRCompliancePath
    Write-Host "  Module Ensure-GDPRCompliance.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Ensure-GDPRCompliance.ps1 introuvable à l'emplacement: $ensureGDPRCompliancePath" -ForegroundColor Red
    exit
}

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "=== SÉCURITÉ ET CONFORMITÉ ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Chiffrement et protection des données" -ForegroundColor Yellow
    Write-Host "2. Authentification multi-facteurs" -ForegroundColor Yellow
    Write-Host "3. Gestion des accès et audit" -ForegroundColor Yellow
    Write-Host "4. Conformité RGPD" -ForegroundColor Yellow
    Write-Host "5. Quitter" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-5): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour afficher le menu de chiffrement
function Show-EncryptionMenu {
    Clear-Host
    Write-Host "=== CHIFFREMENT ET PROTECTION DES DONNÉES ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Générer une clé de chiffrement" -ForegroundColor Yellow
    Write-Host "2. Charger une clé de chiffrement" -ForegroundColor Yellow
    Write-Host "3. Chiffrer un fichier de roadmap" -ForegroundColor Yellow
    Write-Host "4. Déchiffrer un fichier de roadmap" -ForegroundColor Yellow
    Write-Host "5. Retour au menu principal" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-5): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour afficher le menu d'authentification multi-facteurs
function Show-MFAMenu {
    Clear-Host
    Write-Host "=== AUTHENTIFICATION MULTI-FACTEURS ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Générer une clé secrète TOTP" -ForegroundColor Yellow
    Write-Host "2. Charger une clé secrète TOTP" -ForegroundColor Yellow
    Write-Host "3. Générer un code TOTP" -ForegroundColor Yellow
    Write-Host "4. Vérifier un code TOTP" -ForegroundColor Yellow
    Write-Host "5. Générer un QR code pour TOTP" -ForegroundColor Yellow
    Write-Host "6. Enregistrer un appareil pour MFA" -ForegroundColor Yellow
    Write-Host "7. Retour au menu principal" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-7): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour afficher le menu de gestion des accès
function Show-AccessControlMenu {
    Clear-Host
    Write-Host "=== GESTION DES ACCÈS ET AUDIT ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Créer un utilisateur" -ForegroundColor Yellow
    Write-Host "2. Obtenir les informations d'un utilisateur" -ForegroundColor Yellow
    Write-Host "3. Mettre à jour un utilisateur" -ForegroundColor Yellow
    Write-Host "4. Vérifier les permissions d'un utilisateur" -ForegroundColor Yellow
    Write-Host "5. Ajouter une entrée au journal d'audit" -ForegroundColor Yellow
    Write-Host "6. Exporter le journal d'audit" -ForegroundColor Yellow
    Write-Host "7. Retour au menu principal" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-7): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour afficher le menu de conformité RGPD
function Show-GDPRMenu {
    Clear-Host
    Write-Host "=== CONFORMITÉ RGPD ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Enregistrer le consentement d'un utilisateur" -ForegroundColor Yellow
    Write-Host "2. Vérifier le consentement d'un utilisateur" -ForegroundColor Yellow
    Write-Host "3. Anonymiser des données personnelles" -ForegroundColor Yellow
    Write-Host "4. Créer une demande d'accès aux données" -ForegroundColor Yellow
    Write-Host "5. Mettre à jour une demande d'accès aux données" -ForegroundColor Yellow
    Write-Host "6. Retour au menu principal" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-6): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour générer une clé de chiffrement
function Invoke-GenerateEncryptionKey {
    Clear-Host
    Write-Host "=== GÉNÉRER UNE CLÉ DE CHIFFREMENT ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Taille de la clé (128, 192, 256) (défaut: 256): " -ForegroundColor Yellow -NoNewline
    $keySizeInput = Read-Host

    $keySize = 256
    if (-not [string]::IsNullOrEmpty($keySizeInput)) {
        [int]::TryParse($keySizeInput, [ref]$keySize) | Out-Null
    }

    Write-Host "Chemin où sauvegarder la clé: " -ForegroundColor Yellow -NoNewline
    $keyPath = Read-Host

    if ([string]::IsNullOrEmpty($keyPath)) {
        $keyPath = ".\keys\roadmap-key.xml"
    }

    Write-Host "Mot de passe pour protéger la clé (laisser vide pour générer automatiquement): " -ForegroundColor Yellow -NoNewline
    $password = Read-Host

    # Générer la clé
    Write-Host
    Write-Host "Génération de la clé de chiffrement..." -ForegroundColor Cyan

    $key = New-EncryptionKey -KeySize $keySize -KeyPath $keyPath -Password $password

    if ($null -ne $key) {
        Write-Host "Clé de chiffrement générée avec succès!" -ForegroundColor Green
        Write-Host "Algorithme: $($key.Algorithm)" -ForegroundColor Green
        Write-Host "Taille de la clé: $($key.KeySize) bits" -ForegroundColor Green
        Write-Host "Date de création: $($key.CreationDate)" -ForegroundColor Green

        if ([string]::IsNullOrEmpty($password)) {
            Write-Host "Mot de passe généré: $($key.Password)" -ForegroundColor Yellow
            Write-Host "IMPORTANT: Conservez ce mot de passe en lieu sûr!" -ForegroundColor Red
        }
    } else {
        Write-Host "Échec de la génération de la clé de chiffrement." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour charger une clé de chiffrement
function Invoke-LoadEncryptionKey {
    Clear-Host
    Write-Host "=== CHARGER UNE CLÉ DE CHIFFREMENT ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin vers le fichier de clé: " -ForegroundColor Yellow -NoNewline
    $keyPath = Read-Host

    if ([string]::IsNullOrEmpty($keyPath) -or -not (Test-Path $keyPath)) {
        Write-Host "Chemin de clé invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Mot de passe pour déprotéger la clé: " -ForegroundColor Yellow -NoNewline
    $password = Read-Host

    if ([string]::IsNullOrEmpty($password)) {
        Write-Host "Mot de passe invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Charger la clé
    Write-Host
    Write-Host "Chargement de la clé de chiffrement..." -ForegroundColor Cyan

    $key = Get-EncryptionKey -KeyPath $keyPath -Password $password

    if ($null -ne $key) {
        Write-Host "Clé de chiffrement chargée avec succès!" -ForegroundColor Green
        Write-Host "Algorithme: $($key.Algorithm)" -ForegroundColor Green
        Write-Host "Taille de la clé: $($key.KeySize) bits" -ForegroundColor Green
        Write-Host "Date de création: $($key.CreationDate)" -ForegroundColor Green

        # Stocker la clé dans une variable globale pour une utilisation ultérieure
        $Global:CurrentKey = $key
    } else {
        Write-Host "Échec du chargement de la clé de chiffrement." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour chiffrer un fichier de roadmap
function Invoke-EncryptRoadmapFile {
    Clear-Host
    Write-Host "=== CHIFFRER UN FICHIER DE ROADMAP ===" -ForegroundColor Cyan
    Write-Host

    # Vérifier si une clé est chargée
    if ($null -eq $Global:CurrentKey) {
        Write-Host "Aucune clé de chiffrement n'est chargée. Veuillez d'abord charger une clé." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Demander les paramètres
    Write-Host "Chemin vers le fichier à chiffrer: " -ForegroundColor Yellow -NoNewline
    $filePath = Read-Host

    if ([string]::IsNullOrEmpty($filePath) -or -not (Test-Path $filePath)) {
        Write-Host "Chemin de fichier invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Chemin où sauvegarder le fichier chiffré (laisser vide pour ajouter .enc): " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = "$filePath.enc"
    }

    Write-Host "Ajouter une somme de contrôle pour vérifier l'intégrité (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
    $addChecksumInput = Read-Host

    $addChecksum = $addChecksumInput -ne "n"

    # Chiffrer le fichier
    Write-Host
    Write-Host "Chiffrement du fichier..." -ForegroundColor Cyan

    $result = Protect-RoadmapFile -FilePath $filePath -Key $Global:CurrentKey -OutputPath $outputPath -AddChecksum:$addChecksum

    if ($null -ne $result) {
        Write-Host "Fichier chiffré avec succès!" -ForegroundColor Green
        Write-Host "Fichier original: $($result.OriginalFile)" -ForegroundColor Green
        Write-Host "Fichier chiffré: $($result.EncryptedFile)" -ForegroundColor Green
        Write-Host "Algorithme: $($result.Algorithm)" -ForegroundColor Green
        Write-Host "Taille de la clé: $($result.KeySize) bits" -ForegroundColor Green
        Write-Host "Somme de contrôle ajoutée: $($result.HasChecksum)" -ForegroundColor Green
        Write-Host "Date de chiffrement: $($result.EncryptionDate)" -ForegroundColor Green
    } else {
        Write-Host "Échec du chiffrement du fichier." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour déchiffrer un fichier de roadmap
function Invoke-DecryptRoadmapFile {
    Clear-Host
    Write-Host "=== DÉCHIFFRER UN FICHIER DE ROADMAP ===" -ForegroundColor Cyan
    Write-Host

    # Vérifier si une clé est chargée
    if ($null -eq $Global:CurrentKey) {
        Write-Host "Aucune clé de chiffrement n'est chargée. Veuillez d'abord charger une clé." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Demander les paramètres
    Write-Host "Chemin vers le fichier à déchiffrer: " -ForegroundColor Yellow -NoNewline
    $filePath = Read-Host

    if ([string]::IsNullOrEmpty($filePath) -or -not (Test-Path $filePath)) {
        Write-Host "Chemin de fichier invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Chemin où sauvegarder le fichier déchiffré (laisser vide pour générer automatiquement): " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    Write-Host "Vérifier la somme de contrôle (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
    $verifyChecksumInput = Read-Host

    $verifyChecksum = $verifyChecksumInput -ne "n"

    # Déchiffrer le fichier
    Write-Host
    Write-Host "Déchiffrement du fichier..." -ForegroundColor Cyan

    $result = Unprotect-RoadmapFile -FilePath $filePath -Key $Global:CurrentKey -OutputPath $outputPath -VerifyChecksum:$verifyChecksum

    if ($null -ne $result) {
        Write-Host "Fichier déchiffré avec succès!" -ForegroundColor Green
        Write-Host "Fichier chiffré: $($result.EncryptedFile)" -ForegroundColor Green
        Write-Host "Fichier déchiffré: $($result.DecryptedFile)" -ForegroundColor Green
        Write-Host "Algorithme: $($result.Algorithm)" -ForegroundColor Green
        Write-Host "Taille de la clé: $($result.KeySize) bits" -ForegroundColor Green
        Write-Host "Somme de contrôle vérifiée: $($result.ChecksumVerified)" -ForegroundColor Green
        Write-Host "Date de chiffrement: $($result.EncryptionDate)" -ForegroundColor Green
    } else {
        Write-Host "Échec du déchiffrement du fichier." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour générer une clé secrète TOTP
function Invoke-GenerateTOTPSecret {
    Clear-Host
    Write-Host "=== GÉNÉRER UNE CLÉ SECRÈTE TOTP ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Longueur de la clé secrète en octets (défaut: 20): " -ForegroundColor Yellow -NoNewline
    $secretLengthInput = Read-Host

    $secretLength = 20
    if (-not [string]::IsNullOrEmpty($secretLengthInput)) {
        [int]::TryParse($secretLengthInput, [ref]$secretLength) | Out-Null
    }

    Write-Host "Identifiant de l'utilisateur: " -ForegroundColor Yellow -NoNewline
    $userId = Read-Host

    Write-Host "Nom de l'application (défaut: Roadmap Manager): " -ForegroundColor Yellow -NoNewline
    $appName = Read-Host

    if ([string]::IsNullOrEmpty($appName)) {
        $appName = "Roadmap Manager"
    }

    Write-Host "Chemin où sauvegarder la clé secrète: " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = ".\totp\$userId-secret.json"
    }

    # Générer la clé secrète
    Write-Host
    Write-Host "Génération de la clé secrète TOTP..." -ForegroundColor Cyan

    $secret = New-TOTPSecret -SecretLength $secretLength -OutputPath $outputPath -UserId $userId -AppName $appName

    if ($null -ne $secret) {
        Write-Host "Clé secrète TOTP générée avec succès!" -ForegroundColor Green
        Write-Host "Secret: $($secret.Secret)" -ForegroundColor Green
        Write-Host "Utilisateur: $($secret.UserId)" -ForegroundColor Green
        Write-Host "Application: $($secret.AppName)" -ForegroundColor Green
        Write-Host "Date de création: $($secret.CreationDate)" -ForegroundColor Green
        Write-Host "URL OTP Auth: $($secret.OtpAuthUrl)" -ForegroundColor Green

        # Stocker la clé secrète dans une variable globale pour une utilisation ultérieure
        $Global:CurrentTOTPSecret = $secret

        # Demander si un QR code doit être généré
        Write-Host
        Write-Host "Générer un QR code pour configurer l'application d'authentification (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
        $generateQRCodeInput = Read-Host

        if ($generateQRCodeInput -ne "n") {
            Write-Host "Chemin où sauvegarder le QR code (laisser vide pour afficher dans le navigateur): " -ForegroundColor Yellow -NoNewline
            $qrCodePath = Read-Host

            $qrCode = New-TOTPQRCode -Secret $secret -OutputPath $qrCodePath

            if ($null -ne $qrCode) {
                Write-Host "QR code généré avec succès!" -ForegroundColor Green
                if (-not [string]::IsNullOrEmpty($qrCode.OutputPath)) {
                    Write-Host "QR code sauvegardé dans: $($qrCode.OutputPath)" -ForegroundColor Green
                } else {
                    Write-Host "QR code affiché dans le navigateur." -ForegroundColor Green
                }
            } else {
                Write-Host "Échec de la génération du QR code." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Échec de la génération de la clé secrète TOTP." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour charger une clé secrète TOTP
function Invoke-LoadTOTPSecret {
    Clear-Host
    Write-Host "=== CHARGER UNE CLÉ SECRÈTE TOTP ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin vers le fichier de clé secrète: " -ForegroundColor Yellow -NoNewline
    $secretPath = Read-Host

    if ([string]::IsNullOrEmpty($secretPath) -or -not (Test-Path $secretPath)) {
        Write-Host "Chemin de clé secrète invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Charger la clé secrète
    Write-Host
    Write-Host "Chargement de la clé secrète TOTP..." -ForegroundColor Cyan

    $secret = Get-TOTPSecret -SecretPath $secretPath

    if ($null -ne $secret) {
        Write-Host "Clé secrète TOTP chargée avec succès!" -ForegroundColor Green
        Write-Host "Secret: $($secret.Secret)" -ForegroundColor Green
        Write-Host "Utilisateur: $($secret.UserId)" -ForegroundColor Green
        Write-Host "Application: $($secret.AppName)" -ForegroundColor Green
        Write-Host "Date de création: $($secret.CreationDate)" -ForegroundColor Green
        Write-Host "URL OTP Auth: $($secret.OtpAuthUrl)" -ForegroundColor Green

        # Stocker la clé secrète dans une variable globale pour une utilisation ultérieure
        $Global:CurrentTOTPSecret = $secret
    } else {
        Write-Host "Échec du chargement de la clé secrète TOTP." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour générer un code TOTP
function Invoke-GenerateTOTPCode {
    Clear-Host
    Write-Host "=== GÉNÉRER UN CODE TOTP ===" -ForegroundColor Cyan
    Write-Host

    # Vérifier si une clé secrète est chargée
    if ($null -eq $Global:CurrentTOTPSecret) {
        Write-Host "Aucune clé secrète TOTP n'est chargée. Veuillez d'abord charger une clé secrète." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Générer le code TOTP
    Write-Host "Génération du code TOTP..." -ForegroundColor Cyan

    $code = Get-TOTPCode -Secret $Global:CurrentTOTPSecret

    if ($null -ne $code) {
        Write-Host "Code TOTP généré avec succès!" -ForegroundColor Green
        Write-Host "Code: $code" -ForegroundColor Green
        Write-Host "Valide pour les prochaines $($Global:CurrentTOTPSecret.Period) secondes." -ForegroundColor Green
    } else {
        Write-Host "Échec de la génération du code TOTP." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour vérifier un code TOTP
function Invoke-VerifyTOTPCode {
    Clear-Host
    Write-Host "=== VÉRIFIER UN CODE TOTP ===" -ForegroundColor Cyan
    Write-Host

    # Vérifier si une clé secrète est chargée
    if ($null -eq $Global:CurrentTOTPSecret) {
        Write-Host "Aucune clé secrète TOTP n'est chargée. Veuillez d'abord charger une clé secrète." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Demander le code à vérifier
    Write-Host "Code TOTP à vérifier: " -ForegroundColor Yellow -NoNewline
    $code = Read-Host

    if ([string]::IsNullOrEmpty($code)) {
        Write-Host "Code TOTP invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Demander la taille de la fenêtre
    Write-Host "Taille de la fenêtre (nombre de périodes avant et après à vérifier, défaut: 1): " -ForegroundColor Yellow -NoNewline
    $windowSizeInput = Read-Host

    $windowSize = 1
    if (-not [string]::IsNullOrEmpty($windowSizeInput)) {
        [int]::TryParse($windowSizeInput, [ref]$windowSize) | Out-Null
    }

    # Vérifier le code TOTP
    Write-Host
    Write-Host "Vérification du code TOTP..." -ForegroundColor Cyan

    $result = Test-TOTPCode -Secret $Global:CurrentTOTPSecret -Code $code -WindowSize $windowSize

    if ($result) {
        Write-Host "Code TOTP valide!" -ForegroundColor Green
    } else {
        Write-Host "Code TOTP invalide." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour générer un QR code pour TOTP
function Invoke-GenerateTOTPQRCode {
    Clear-Host
    Write-Host "=== GÉNÉRER UN QR CODE POUR TOTP ===" -ForegroundColor Cyan
    Write-Host

    # Vérifier si une clé secrète est chargée
    if ($null -eq $Global:CurrentTOTPSecret) {
        Write-Host "Aucune clé secrète TOTP n'est chargée. Veuillez d'abord charger une clé secrète." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Demander les paramètres
    Write-Host "Chemin où sauvegarder le QR code (laisser vide pour afficher dans le navigateur): " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    Write-Host "Taille du QR code en pixels (défaut: 300): " -ForegroundColor Yellow -NoNewline
    $sizeInput = Read-Host

    $size = 300
    if (-not [string]::IsNullOrEmpty($sizeInput)) {
        [int]::TryParse($sizeInput, [ref]$size) | Out-Null
    }

    # Générer le QR code
    Write-Host
    Write-Host "Génération du QR code..." -ForegroundColor Cyan

    $qrCode = New-TOTPQRCode -Secret $Global:CurrentTOTPSecret -OutputPath $outputPath -Size $size

    if ($null -ne $qrCode) {
        Write-Host "QR code généré avec succès!" -ForegroundColor Green
        if (-not [string]::IsNullOrEmpty($qrCode.OutputPath)) {
            Write-Host "QR code sauvegardé dans: $($qrCode.OutputPath)" -ForegroundColor Green
        } else {
            Write-Host "QR code affiché dans le navigateur." -ForegroundColor Green
        }
    } else {
        Write-Host "Échec de la génération du QR code." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour enregistrer un appareil pour MFA
function Invoke-RegisterMFADevice {
    Clear-Host
    Write-Host "=== ENREGISTRER UN APPAREIL POUR MFA ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Identifiant de l'utilisateur: " -ForegroundColor Yellow -NoNewline
    $userId = Read-Host

    if ([string]::IsNullOrEmpty($userId)) {
        Write-Host "Identifiant d'utilisateur invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom de l'appareil: " -ForegroundColor Yellow -NoNewline
    $deviceName = Read-Host

    if ([string]::IsNullOrEmpty($deviceName)) {
        Write-Host "Nom d'appareil invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom de l'application (défaut: Roadmap Manager): " -ForegroundColor Yellow -NoNewline
    $appName = Read-Host

    if ([string]::IsNullOrEmpty($appName)) {
        $appName = "Roadmap Manager"
    }

    Write-Host "Adresse e-mail de contact: " -ForegroundColor Yellow -NoNewline
    $contactEmail = Read-Host

    if ([string]::IsNullOrEmpty($contactEmail)) {
        Write-Host "Adresse e-mail de contact invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Chemin où sauvegarder les informations d'enregistrement: " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = ".\mfa\$userId-$deviceName.json"
    }

    Write-Host "Générer un QR code (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
    $generateQRCodeInput = Read-Host

    $generateQRCode = $generateQRCodeInput -ne "n"

    Write-Host "Chemin où sauvegarder le QR code (laisser vide pour afficher dans le navigateur): " -ForegroundColor Yellow -NoNewline
    $qrCodePath = Read-Host

    # Enregistrer l'appareil
    Write-Host
    Write-Host "Enregistrement de l'appareil pour MFA..." -ForegroundColor Cyan

    $registration = Register-MFADevice -UserId $userId -DeviceName $deviceName -AppName $appName -ContactEmail $contactEmail -OutputPath $outputPath -GenerateQRCode:$generateQRCode -QRCodePath $qrCodePath

    if ($null -ne $registration) {
        Write-Host "Appareil enregistré pour MFA avec succès!" -ForegroundColor Green
        Write-Host "Utilisateur: $($registration.UserId)" -ForegroundColor Green
        Write-Host "Appareil: $($registration.DeviceName)" -ForegroundColor Green
        Write-Host "Application: $($registration.AppName)" -ForegroundColor Green
        Write-Host "Secret: $($registration.Secret)" -ForegroundColor Green
        Write-Host "Date d'enregistrement: $($registration.RegistrationDate)" -ForegroundColor Green

        if ($generateQRCode) {
            if (-not [string]::IsNullOrEmpty($registration.QRCodePath)) {
                Write-Host "QR code sauvegardé dans: $($registration.QRCodePath)" -ForegroundColor Green
            } else {
                Write-Host "QR code affiché dans le navigateur." -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Échec de l'enregistrement de l'appareil pour MFA." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour créer un utilisateur
function Invoke-CreateUser {
    Clear-Host
    Write-Host "=== CRÉER UN UTILISATEUR ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Identifiant de l'utilisateur: " -ForegroundColor Yellow -NoNewline
    $userId = Read-Host

    if ([string]::IsNullOrEmpty($userId)) {
        Write-Host "Identifiant d'utilisateur invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom complet: " -ForegroundColor Yellow -NoNewline
    $fullName = Read-Host

    if ([string]::IsNullOrEmpty($fullName)) {
        Write-Host "Nom complet invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Adresse e-mail: " -ForegroundColor Yellow -NoNewline
    $email = Read-Host

    if ([string]::IsNullOrEmpty($email)) {
        Write-Host "Adresse e-mail invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Rôles (séparés par des virgules, défaut: Viewer): " -ForegroundColor Yellow -NoNewline
    $rolesInput = Read-Host

    $roles = @("Viewer")
    if (-not [string]::IsNullOrEmpty($rolesInput)) {
        $roles = $rolesInput -split "," | ForEach-Object { $_.Trim() }
    }

    Write-Host "Permissions personnalisées (séparées par des virgules): " -ForegroundColor Yellow -NoNewline
    $customPermissionsInput = Read-Host

    $customPermissions = @()
    if (-not [string]::IsNullOrEmpty($customPermissionsInput)) {
        $customPermissions = $customPermissionsInput -split "," | ForEach-Object { $_.Trim() }
    }

    Write-Host "Activé (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
    $enabledInput = Read-Host

    $enabled = $enabledInput -ne "n"

    Write-Host "Authentification multi-facteurs requise (o/n, défaut: n): " -ForegroundColor Yellow -NoNewline
    $requireMFAInput = Read-Host

    $requireMFA = $requireMFAInput -eq "o"

    Write-Host "Chemin où sauvegarder les informations de l'utilisateur: " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = ".\users\$userId.json"
    }

    # Créer l'utilisateur
    Write-Host
    Write-Host "Création de l'utilisateur..." -ForegroundColor Cyan

    $user = New-RoadmapUser -UserId $userId -FullName $fullName -Email $email -Roles $roles -CustomPermissions $customPermissions -Enabled $enabled -RequireMFA $requireMFA -OutputPath $outputPath

    if ($null -ne $user) {
        Write-Host "Utilisateur créé avec succès!" -ForegroundColor Green
        Write-Host "Identifiant: $($user.UserId)" -ForegroundColor Green
        Write-Host "Nom complet: $($user.FullName)" -ForegroundColor Green
        Write-Host "Adresse e-mail: $($user.Email)" -ForegroundColor Green
        Write-Host "Rôles: $($user.Roles -join ', ')" -ForegroundColor Green
        Write-Host "Permissions: $($user.Permissions -join ', ')" -ForegroundColor Green
        Write-Host "Activé: $($user.Enabled)" -ForegroundColor Green
        Write-Host "MFA requise: $($user.RequireMFA)" -ForegroundColor Green
        Write-Host "Date de création: $($user.CreationDate)" -ForegroundColor Green
    } else {
        Write-Host "Échec de la création de l'utilisateur." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}
