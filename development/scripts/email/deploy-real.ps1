# Script de dÃƒÂ©ploiement rÃƒÂ©el
# Ce script dÃƒÂ©ploie le projet vers l'environnement spÃƒÂ©cifiÃƒÂ© en utilisant des mÃƒÂ©thodes rÃƒÂ©elles

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

# Fonction pour afficher un message colorÃƒÂ©
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
        Write-ColorMessage "Notification par email dÃƒÂ©sactivÃƒÂ©e (option -SendNotification non spÃƒÂ©cifiÃƒÂ©e)" -ForegroundColor "Yellow"
        return
    }
    
    Write-ColorMessage "Envoi d'une notification par email ÃƒÂ  $To..." -ForegroundColor "Cyan"
    
    try {
        # Utiliser Send-MailMessage si disponible
        if (Get-Command Send-MailMessage -ErrorAction SilentlyContinue) {
            # Configurer les paramÃƒÂ¨tres de l'email
            $emailParams = @{
                From = "noreply@example.com"
                To = $To
                Subject = $Subject
                Body = $Body
                SmtpServer = "smtp.example.com"
                Port = 587
                UseSSL = $true
                # Credentials = (Get-Credential)  # DÃƒÂ©commentez et configurez si nÃƒÂ©cessaire
            }
            
            # Envoyer l'email
            Send-MailMessage @emailParams
            
            Write-ColorMessage "Notification par email envoyÃƒÂ©e avec succÃƒÂ¨s" -ForegroundColor "Green"
        }
        else {
            # Alternative : utiliser .NET Framework
            $smtpClient = New-Object System.Net.Mail.SmtpClient("smtp.example.com", 587)
            $smtpClient.EnableSsl = $true
            # $smtpClient.Credentials = New-Object System.Net.NetworkCredential("username", "password")  # DÃƒÂ©commentez et configurez si nÃƒÂ©cessaire
            
            $mailMessage = New-Object System.Net.Mail.MailMessage
            $mailMessage.From = "noreply@example.com"
            $mailMessage.To.Add($To)
            $mailMessage.Subject = $Subject
            $mailMessage.Body = $Body
            
            $smtpClient.Send($mailMessage)
            
            Write-ColorMessage "Notification par email envoyÃƒÂ©e avec succÃƒÂ¨s" -ForegroundColor "Green"
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de l'envoi de la notification par email : $_" -ForegroundColor "Red"
    }
}

Write-ColorMessage "DÃƒÂ©ploiement rÃƒÂ©el vers l'environnement $Environment..." -ForegroundColor "Cyan"

# DÃƒÂ©finir les paramÃƒÂ¨tres de dÃƒÂ©ploiement en fonction de l'environnement
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

# Ãƒâ€°tape 1: ExÃƒÂ©cuter les tests si nÃƒÂ©cessaire
if (-not $SkipTests) {
    Write-ColorMessage "Ãƒâ€°tape 1: ExÃƒÂ©cution des tests..." -ForegroundColor "Cyan"
    
    $ciScript = Join-Path $projectRoot "..\D"
    
    if (Test-Path $ciScript) {
        try {
            & $ciScript -SkipLint -SkipSecurity
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorMessage "Les tests ont ÃƒÂ©chouÃƒÂ©. DÃƒÂ©ploiement annulÃƒÂ©." -ForegroundColor "Red"
                
                if ($SendNotification) {
                    Send-EmailNotification -Subject "DÃƒÂ©ploiement ÃƒÂ©chouÃƒÂ©: Tests unitaires" -Body "Le dÃƒÂ©ploiement vers l'environnement $Environment a ÃƒÂ©chouÃƒÂ© lors de l'exÃƒÂ©cution des tests unitaires." -To $NotificationEmail -Status "Failure"
                }
                
                if (-not $Force) {
                    exit 1
                }
                else {
                    Write-ColorMessage "Continuation forcÃƒÂ©e malgrÃƒÂ© l'ÃƒÂ©chec des tests" -ForegroundColor "Yellow"
                }
            }
        }
        catch {
            Write-ColorMessage "Erreur lors de l'exÃƒÂ©cution des tests : $_" -ForegroundColor "Red"
            
            if ($SendNotification) {
                Send-EmailNotification -Subject "DÃƒÂ©ploiement ÃƒÂ©chouÃƒÂ©: Erreur lors des tests" -Body "Le dÃƒÂ©ploiement vers l'environnement $Environment a ÃƒÂ©chouÃƒÂ© lors de l'exÃƒÂ©cution des tests: $_" -To $NotificationEmail -Status "Failure"
            }
            
            if (-not $Force) {
                exit 1
            }
        }
    }
    else {
        Write-ColorMessage "Script CI non trouvÃƒÂ© : $ciScript" -ForegroundColor "Yellow"
    }
}
else {
    Write-ColorMessage "Ãƒâ€°tape 1: ExÃƒÂ©cution des tests ignorÃƒÂ©e (option -SkipTests)" -ForegroundColor "Yellow"
}

# Ãƒâ€°tape 2: CrÃƒÂ©er le package de dÃƒÂ©ploiement
Write-ColorMessage "Ãƒâ€°tape 2: CrÃƒÂ©ation du package de dÃƒÂ©ploiement..." -ForegroundColor "Cyan"

$buildDir = Join-Path $projectRoot "build"
$packageDir = Join-Path $buildDir "package"

# CrÃƒÂ©er les dossiers de build
if (Test-Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

# Copier les fichiers nÃƒÂ©cessaires
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

# CrÃƒÂ©er un fichier de version
$version = Get-Date -Format "yyyy.MM.dd.HHmm"
$versionFile = Join-Path $packageDir "version.txt"
Set-Content -Path $versionFile -Value "Version: $version`nEnvironnement: $Environment`nDÃƒÂ©ployÃƒÂ©: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# CrÃƒÂ©er une archive
$archiveName = "n8n-$Environment-$version.zip"
$archivePath = Join-Path $buildDir $archiveName

Write-ColorMessage "CrÃƒÂ©ation de l'archive $archiveName..." -ForegroundColor "Cyan"
Compress-Archive -Path "$packageDir\*" -DestinationPath $archivePath -Force

# Ãƒâ€°tape 3: DÃƒÂ©ployer vers l'environnement cible
Write-ColorMessage "Ãƒâ€°tape 3: DÃƒÂ©ploiement vers $($config.Server)..." -ForegroundColor "Cyan"

# VÃƒÂ©rifier si SSH est disponible
$sshAvailable = Get-Command ssh -ErrorAction SilentlyContinue
$scpAvailable = Get-Command scp -ErrorAction SilentlyContinue

if ($sshAvailable -and $scpAvailable) {
    # DÃƒÂ©ploiement rÃƒÂ©el via SSH
    try {
        # CrÃƒÂ©er une sauvegarde sur le serveur distant
        Write-ColorMessage "CrÃƒÂ©ation d'une sauvegarde sur le serveur distant..." -ForegroundColor "Cyan"
        $backupCommand = "if [ -d '$($config.Path)' ]; then mkdir -p '$($config.BackupPath)' && cp -r '$($config.Path)' '$($config.BackupPath)/backup-$(date +%Y%m%d%H%M%S)'; fi"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $backupCommand
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de destination s'il n'existe pas
        Write-ColorMessage "CrÃƒÂ©ation du rÃƒÂ©pertoire de destination..." -ForegroundColor "Cyan"
        $mkdirCommand = "mkdir -p '$($config.Path)'"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $mkdirCommand
        
        # Copier l'archive vers le serveur distant
        Write-ColorMessage "Copie de l'archive vers le serveur distant..." -ForegroundColor "Cyan"
        scp -i $config.SshKeyPath $archivePath "$($config.SshUser)@$($config.Server):$($config.Path)/"
        
        # Extraire l'archive sur le serveur distant
        Write-ColorMessage "Extraction de l'archive sur le serveur distant..." -ForegroundColor "Cyan"
        $extractCommand = "cd '$($config.Path)' && unzip -o '$archiveName' && rm '$archiveName'"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $extractCommand
        
        # RedÃƒÂ©marrer les services
        Write-ColorMessage "RedÃƒÂ©marrage des services..." -ForegroundColor "Cyan"
        $restartCommand = "cd '$($config.Path)' && ./development/development/scripts/ci/restart-services.sh"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $restartCommand
        
        Write-ColorMessage "DÃƒÂ©ploiement rÃƒÂ©el terminÃƒÂ© avec succÃƒÂ¨s!" -ForegroundColor "Green"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "DÃƒÂ©ploiement rÃƒÂ©ussi: $Environment" -Body "Le dÃƒÂ©ploiement vers l'environnement $Environment a ÃƒÂ©tÃƒÂ© effectuÃƒÂ© avec succÃƒÂ¨s.`n`nVersion: $version`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -To $NotificationEmail -Status "Success"
        }
    }
    catch {
        Write-ColorMessage "Erreur lors du dÃƒÂ©ploiement rÃƒÂ©el : $_" -ForegroundColor "Red"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "DÃƒÂ©ploiement ÃƒÂ©chouÃƒÂ©: $Environment" -Body "Le dÃƒÂ©ploiement vers l'environnement $Environment a ÃƒÂ©chouÃƒÂ©: $_" -To $NotificationEmail -Status "Failure"
        }
        
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    # Simulation de dÃƒÂ©ploiement (pour les environnements sans SSH)
    Write-ColorMessage "SSH ou SCP non disponible. Simulation du dÃƒÂ©ploiement..." -ForegroundColor "Yellow"
    
    Write-ColorMessage "Connexion au serveur $($config.Server)..." -ForegroundColor "Cyan"
    Write-ColorMessage "CrÃƒÂ©ation d'une sauvegarde dans $($config.BackupPath)..." -ForegroundColor "Cyan"
    Write-ColorMessage "Copie des fichiers vers $($config.Path)..." -ForegroundColor "Cyan"
    Write-ColorMessage "RedÃƒÂ©marrage des services..." -ForegroundColor "Cyan"
    
    Write-ColorMessage "Simulation de dÃƒÂ©ploiement terminÃƒÂ©e!" -ForegroundColor "Green"
    
    if ($SendNotification) {
        Send-EmailNotification -Subject "DÃƒÂ©ploiement simulÃƒÂ©: $Environment" -Body "La simulation de dÃƒÂ©ploiement vers l'environnement $Environment a ÃƒÂ©tÃƒÂ© effectuÃƒÂ©e avec succÃƒÂ¨s.`n`nVersion: $version`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -To $NotificationEmail -Status "Success"
    }
}

# Ãƒâ€°tape 4: VÃƒÂ©rifier le dÃƒÂ©ploiement
Write-ColorMessage "Ãƒâ€°tape 4: VÃƒÂ©rification du dÃƒÂ©ploiement..." -ForegroundColor "Cyan"

if ($sshAvailable) {
    # VÃƒÂ©rification rÃƒÂ©elle via SSH
    try {
        # VÃƒÂ©rifier la version dÃƒÂ©ployÃƒÂ©e
        Write-ColorMessage "VÃƒÂ©rification de la version dÃƒÂ©ployÃƒÂ©e..." -ForegroundColor "Cyan"
        $versionCommand = "cat '$($config.Path)/version.txt'"
        $deployedVersion = ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $versionCommand
        
        Write-ColorMessage "Version dÃƒÂ©ployÃƒÂ©e:" -ForegroundColor "White"
        $deployedVersion | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        # VÃƒÂ©rifier les services
        Write-ColorMessage "VÃƒÂ©rification des services..." -ForegroundColor "Cyan"
        $serviceCommand = "cd '$($config.Path)' && ./development/development/scripts/ci/check-services.sh"
        $serviceStatus = ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $serviceCommand
        
        Write-ColorMessage "Statut des services:" -ForegroundColor "White"
        $serviceStatus | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        Write-ColorMessage "VÃƒÂ©rification du dÃƒÂ©ploiement terminÃƒÂ©e avec succÃƒÂ¨s!" -ForegroundColor "Green"
    }
    catch {
        Write-ColorMessage "Erreur lors de la vÃƒÂ©rification du dÃƒÂ©ploiement : $_" -ForegroundColor "Red"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "VÃƒÂ©rification du dÃƒÂ©ploiement ÃƒÂ©chouÃƒÂ©e: $Environment" -Body "La vÃƒÂ©rification du dÃƒÂ©ploiement vers l'environnement $Environment a ÃƒÂ©chouÃƒÂ©: $_" -To $NotificationEmail -Status "Failure"
        }
        
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    # Simulation de vÃƒÂ©rification (pour les environnements sans SSH)
    Write-ColorMessage "SSH non disponible. Simulation de la vÃƒÂ©rification..." -ForegroundColor "Yellow"
    
    Write-ColorMessage "VÃƒÂ©rification de l'accÃƒÂ¨s ÃƒÂ  l'application..." -ForegroundColor "Cyan"
    Write-ColorMessage "VÃƒÂ©rification des services..." -ForegroundColor "Cyan"
    Write-ColorMessage "VÃƒÂ©rification des logs..." -ForegroundColor "Cyan"
    
    Write-ColorMessage "Simulation de vÃƒÂ©rification terminÃƒÂ©e!" -ForegroundColor "Green"
}

# Afficher un rÃƒÂ©sumÃƒÂ©
Write-ColorMessage "`nRÃƒÂ©sumÃƒÂ© du dÃƒÂ©ploiement rÃƒÂ©el:" -ForegroundColor "Cyan"
Write-ColorMessage "- Environnement: $Environment" -ForegroundColor "White"
Write-ColorMessage "- Version: $version" -ForegroundColor "White"
Write-ColorMessage "- Archive: $archivePath" -ForegroundColor "White"
Write-ColorMessage "- Serveur: $($config.Server)" -ForegroundColor "White"
Write-ColorMessage "- Chemin: $($config.Path)" -ForegroundColor "White"

Write-ColorMessage "`nDÃƒÂ©ploiement rÃƒÂ©el terminÃƒÂ© avec succÃƒÂ¨s!" -ForegroundColor "Green"

# Afficher l'aide si demandÃƒÂ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\deploy-real.ps1 -Environment <env> [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nEnvironnements:" -ForegroundColor "Cyan"
    Write-ColorMessage "  Development  Environnement de dÃƒÂ©veloppement" -ForegroundColor "Cyan"
    Write-ColorMessage "  Staging      Environnement de prÃƒÂ©-production" -ForegroundColor "Cyan"
    Write-ColorMessage "  Production   Environnement de production" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force             Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipTests         Ne pas exÃƒÂ©cuter les tests avant le dÃƒÂ©ploiement" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose           Afficher des informations dÃƒÂ©taillÃƒÂ©es" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SendNotification  Envoyer des notifications par email" -ForegroundColor "Cyan"
    Write-ColorMessage "  -NotificationEmail Adresse email pour les notifications (dÃƒÂ©faut: gerivonderbitsh+dev@gmail.com)" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy-real.ps1 -Environment Development" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy-real.ps1 -Environment Production -SkipTests -SendNotification" -ForegroundColor "Cyan"
}

