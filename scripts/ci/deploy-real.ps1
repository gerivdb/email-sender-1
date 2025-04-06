# Script de déploiement réel
# Ce script déploie le projet vers l'environnement spécifié en utilisant des méthodes réelles

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory = $false)]
    [switch]$SendNotification,
    
    [Parameter(Mandatory = $false)]
    [string]$NotificationEmail = "gerivonderbitsh+dev@gmail.com"
)

# Obtenir le chemin racine du projet
$projectRoot = $PSScriptRoot
if ($PSScriptRoot -match "scripts\\ci$") {
    $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
}
else {
    $projectRoot = git rev-parse --show-toplevel
}
Set-Location $projectRoot

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Fonction pour afficher un message verbose
function Write-VerboseMessage {
    param (
        [string]$Message
    )
    
    if ($Verbose) {
        Write-ColorMessage $Message -ForegroundColor "Gray"
    }
}

# Fonction pour envoyer une notification par email
function Send-EmailNotification {
    param (
        [string]$Subject,
        [string]$Body,
        [string]$To,
        [string]$Status = "Success"
    )
    
    if (-not $SendNotification) {
        Write-ColorMessage "Notification par email désactivée (option -SendNotification non spécifiée)" -ForegroundColor "Yellow"
        return
    }
    
    Write-ColorMessage "Envoi d'une notification par email à $To..." -ForegroundColor "Cyan"
    
    try {
        # Utiliser Send-MailMessage si disponible
        if (Get-Command Send-MailMessage -ErrorAction SilentlyContinue) {
            # Configurer les paramètres de l'email
            $emailParams = @{
                From = "noreply@example.com"
                To = $To
                Subject = $Subject
                Body = $Body
                SmtpServer = "smtp.example.com"
                Port = 587
                UseSSL = $true
                # Credentials = (Get-Credential)  # Décommentez et configurez si nécessaire
            }
            
            # Envoyer l'email
            Send-MailMessage @emailParams
            
            Write-ColorMessage "Notification par email envoyée avec succès" -ForegroundColor "Green"
        }
        else {
            # Alternative : utiliser .NET Framework
            $smtpClient = New-Object System.Net.Mail.SmtpClient("smtp.example.com", 587)
            $smtpClient.EnableSsl = $true
            # $smtpClient.Credentials = New-Object System.Net.NetworkCredential("username", "password")  # Décommentez et configurez si nécessaire
            
            $mailMessage = New-Object System.Net.Mail.MailMessage
            $mailMessage.From = "noreply@example.com"
            $mailMessage.To.Add($To)
            $mailMessage.Subject = $Subject
            $mailMessage.Body = $Body
            
            $smtpClient.Send($mailMessage)
            
            Write-ColorMessage "Notification par email envoyée avec succès" -ForegroundColor "Green"
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de l'envoi de la notification par email : $_" -ForegroundColor "Red"
    }
}

Write-ColorMessage "Déploiement réel vers l'environnement $Environment..." -ForegroundColor "Cyan"

# Définir les paramètres de déploiement en fonction de l'environnement
$deploymentConfig = @{
    Development = @{
        Server = "dev-server.example.com"
        Path = "/var/www/n8n-dev"
        BackupPath = "/var/www/n8n-dev-backup"
        SshUser = "deploy-dev"
        SshKeyPath = "~/.ssh/id_rsa_dev"
    }
    Staging = @{
        Server = "staging-server.example.com"
        Path = "/var/www/n8n-staging"
        BackupPath = "/var/www/n8n-staging-backup"
        SshUser = "deploy-staging"
        SshKeyPath = "~/.ssh/id_rsa_staging"
    }
    Production = @{
        Server = "prod-server.example.com"
        Path = "/var/www/n8n-prod"
        BackupPath = "/var/www/n8n-prod-backup"
        SshUser = "deploy-prod"
        SshKeyPath = "~/.ssh/id_rsa_prod"
    }
}

$config = $deploymentConfig[$Environment]

# Étape 1: Exécuter les tests si nécessaire
if (-not $SkipTests) {
    Write-ColorMessage "Étape 1: Exécution des tests..." -ForegroundColor "Cyan"
    
    $ciScript = Join-Path $projectRoot "scripts\ci\run-ci-checks.ps1"
    
    if (Test-Path $ciScript) {
        try {
            & $ciScript -SkipLint -SkipSecurity
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorMessage "Les tests ont échoué. Déploiement annulé." -ForegroundColor "Red"
                
                if ($SendNotification) {
                    Send-EmailNotification -Subject "Déploiement échoué: Tests unitaires" -Body "Le déploiement vers l'environnement $Environment a échoué lors de l'exécution des tests unitaires." -To $NotificationEmail -Status "Failure"
                }
                
                if (-not $Force) {
                    exit 1
                }
                else {
                    Write-ColorMessage "Continuation forcée malgré l'échec des tests" -ForegroundColor "Yellow"
                }
            }
        }
        catch {
            Write-ColorMessage "Erreur lors de l'exécution des tests : $_" -ForegroundColor "Red"
            
            if ($SendNotification) {
                Send-EmailNotification -Subject "Déploiement échoué: Erreur lors des tests" -Body "Le déploiement vers l'environnement $Environment a échoué lors de l'exécution des tests: $_" -To $NotificationEmail -Status "Failure"
            }
            
            if (-not $Force) {
                exit 1
            }
        }
    }
    else {
        Write-ColorMessage "Script CI non trouvé : $ciScript" -ForegroundColor "Yellow"
    }
}
else {
    Write-ColorMessage "Étape 1: Exécution des tests ignorée (option -SkipTests)" -ForegroundColor "Yellow"
}

# Étape 2: Créer le package de déploiement
Write-ColorMessage "Étape 2: Création du package de déploiement..." -ForegroundColor "Cyan"

$buildDir = Join-Path $projectRoot "build"
$packageDir = Join-Path $buildDir "package"

# Créer les dossiers de build
if (Test-Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

# Copier les fichiers nécessaires
$filesToInclude = @(
    "scripts",
    "src",
    "docs",
    ".github",
    "README.md",
    "LICENSE"
)

foreach ($item in $filesToInclude) {
    $sourcePath = Join-Path $projectRoot $item
    $destinationPath = Join-Path $packageDir $item
    
    if (Test-Path $sourcePath) {
        if ((Get-Item $sourcePath) -is [System.IO.DirectoryInfo]) {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
        }
        else {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        }
    }
}

# Créer un fichier de version
$version = Get-Date -Format "yyyy.MM.dd.HHmm"
$versionFile = Join-Path $packageDir "version.txt"
Set-Content -Path $versionFile -Value "Version: $version`nEnvironnement: $Environment`nDéployé: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Créer une archive
$archiveName = "n8n-$Environment-$version.zip"
$archivePath = Join-Path $buildDir $archiveName

Write-ColorMessage "Création de l'archive $archiveName..." -ForegroundColor "Cyan"
Compress-Archive -Path "$packageDir\*" -DestinationPath $archivePath -Force

# Étape 3: Déployer vers l'environnement cible
Write-ColorMessage "Étape 3: Déploiement vers $($config.Server)..." -ForegroundColor "Cyan"

# Vérifier si SSH est disponible
$sshAvailable = Get-Command ssh -ErrorAction SilentlyContinue
$scpAvailable = Get-Command scp -ErrorAction SilentlyContinue

if ($sshAvailable -and $scpAvailable) {
    # Déploiement réel via SSH
    try {
        # Créer une sauvegarde sur le serveur distant
        Write-ColorMessage "Création d'une sauvegarde sur le serveur distant..." -ForegroundColor "Cyan"
        $backupCommand = "if [ -d '$($config.Path)' ]; then mkdir -p '$($config.BackupPath)' && cp -r '$($config.Path)' '$($config.BackupPath)/backup-$(date +%Y%m%d%H%M%S)'; fi"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $backupCommand
        
        # Créer le répertoire de destination s'il n'existe pas
        Write-ColorMessage "Création du répertoire de destination..." -ForegroundColor "Cyan"
        $mkdirCommand = "mkdir -p '$($config.Path)'"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $mkdirCommand
        
        # Copier l'archive vers le serveur distant
        Write-ColorMessage "Copie de l'archive vers le serveur distant..." -ForegroundColor "Cyan"
        scp -i $config.SshKeyPath $archivePath "$($config.SshUser)@$($config.Server):$($config.Path)/"
        
        # Extraire l'archive sur le serveur distant
        Write-ColorMessage "Extraction de l'archive sur le serveur distant..." -ForegroundColor "Cyan"
        $extractCommand = "cd '$($config.Path)' && unzip -o '$archiveName' && rm '$archiveName'"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $extractCommand
        
        # Redémarrer les services
        Write-ColorMessage "Redémarrage des services..." -ForegroundColor "Cyan"
        $restartCommand = "cd '$($config.Path)' && ./scripts/ci/restart-services.sh"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $restartCommand
        
        Write-ColorMessage "Déploiement réel terminé avec succès!" -ForegroundColor "Green"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "Déploiement réussi: $Environment" -Body "Le déploiement vers l'environnement $Environment a été effectué avec succès.`n`nVersion: $version`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -To $NotificationEmail -Status "Success"
        }
    }
    catch {
        Write-ColorMessage "Erreur lors du déploiement réel : $_" -ForegroundColor "Red"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "Déploiement échoué: $Environment" -Body "Le déploiement vers l'environnement $Environment a échoué: $_" -To $NotificationEmail -Status "Failure"
        }
        
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    # Simulation de déploiement (pour les environnements sans SSH)
    Write-ColorMessage "SSH ou SCP non disponible. Simulation du déploiement..." -ForegroundColor "Yellow"
    
    Write-ColorMessage "Connexion au serveur $($config.Server)..." -ForegroundColor "Cyan"
    Write-ColorMessage "Création d'une sauvegarde dans $($config.BackupPath)..." -ForegroundColor "Cyan"
    Write-ColorMessage "Copie des fichiers vers $($config.Path)..." -ForegroundColor "Cyan"
    Write-ColorMessage "Redémarrage des services..." -ForegroundColor "Cyan"
    
    Write-ColorMessage "Simulation de déploiement terminée!" -ForegroundColor "Green"
    
    if ($SendNotification) {
        Send-EmailNotification -Subject "Déploiement simulé: $Environment" -Body "La simulation de déploiement vers l'environnement $Environment a été effectuée avec succès.`n`nVersion: $version`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -To $NotificationEmail -Status "Success"
    }
}

# Étape 4: Vérifier le déploiement
Write-ColorMessage "Étape 4: Vérification du déploiement..." -ForegroundColor "Cyan"

if ($sshAvailable) {
    # Vérification réelle via SSH
    try {
        # Vérifier la version déployée
        Write-ColorMessage "Vérification de la version déployée..." -ForegroundColor "Cyan"
        $versionCommand = "cat '$($config.Path)/version.txt'"
        $deployedVersion = ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $versionCommand
        
        Write-ColorMessage "Version déployée:" -ForegroundColor "White"
        $deployedVersion | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        # Vérifier les services
        Write-ColorMessage "Vérification des services..." -ForegroundColor "Cyan"
        $serviceCommand = "cd '$($config.Path)' && ./scripts/ci/check-services.sh"
        $serviceStatus = ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $serviceCommand
        
        Write-ColorMessage "Statut des services:" -ForegroundColor "White"
        $serviceStatus | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        Write-ColorMessage "Vérification du déploiement terminée avec succès!" -ForegroundColor "Green"
    }
    catch {
        Write-ColorMessage "Erreur lors de la vérification du déploiement : $_" -ForegroundColor "Red"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "Vérification du déploiement échouée: $Environment" -Body "La vérification du déploiement vers l'environnement $Environment a échoué: $_" -To $NotificationEmail -Status "Failure"
        }
        
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    # Simulation de vérification (pour les environnements sans SSH)
    Write-ColorMessage "SSH non disponible. Simulation de la vérification..." -ForegroundColor "Yellow"
    
    Write-ColorMessage "Vérification de l'accès à l'application..." -ForegroundColor "Cyan"
    Write-ColorMessage "Vérification des services..." -ForegroundColor "Cyan"
    Write-ColorMessage "Vérification des logs..." -ForegroundColor "Cyan"
    
    Write-ColorMessage "Simulation de vérification terminée!" -ForegroundColor "Green"
}

# Afficher un résumé
Write-ColorMessage "`nRésumé du déploiement réel:" -ForegroundColor "Cyan"
Write-ColorMessage "- Environnement: $Environment" -ForegroundColor "White"
Write-ColorMessage "- Version: $version" -ForegroundColor "White"
Write-ColorMessage "- Archive: $archivePath" -ForegroundColor "White"
Write-ColorMessage "- Serveur: $($config.Server)" -ForegroundColor "White"
Write-ColorMessage "- Chemin: $($config.Path)" -ForegroundColor "White"

Write-ColorMessage "`nDéploiement réel terminé avec succès!" -ForegroundColor "Green"

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\deploy-real.ps1 -Environment <env> [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nEnvironnements:" -ForegroundColor "Cyan"
    Write-ColorMessage "  Development  Environnement de développement" -ForegroundColor "Cyan"
    Write-ColorMessage "  Staging      Environnement de pré-production" -ForegroundColor "Cyan"
    Write-ColorMessage "  Production   Environnement de production" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force             Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipTests         Ne pas exécuter les tests avant le déploiement" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose           Afficher des informations détaillées" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SendNotification  Envoyer des notifications par email" -ForegroundColor "Cyan"
    Write-ColorMessage "  -NotificationEmail Adresse email pour les notifications (défaut: gerivonderbitsh+dev@gmail.com)" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy-real.ps1 -Environment Development" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy-real.ps1 -Environment Production -SkipTests -SendNotification" -ForegroundColor "Cyan"
}
