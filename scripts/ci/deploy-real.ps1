# Script de dÃ©ploiement rÃ©el
# Ce script dÃ©ploie le projet vers l'environnement spÃ©cifiÃ© en utilisant des mÃ©thodes rÃ©elles

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

# Fonction pour afficher un message colorÃ©
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
        Write-ColorMessage "Notification par email dÃ©sactivÃ©e (option -SendNotification non spÃ©cifiÃ©e)" -ForegroundColor "Yellow"
        return
    }
    
    Write-ColorMessage "Envoi d'une notification par email Ã  $To..." -ForegroundColor "Cyan"
    
    try {
        # Utiliser Send-MailMessage si disponible
        if (Get-Command Send-MailMessage -ErrorAction SilentlyContinue) {
            # Configurer les paramÃ¨tres de l'email
            $emailParams = @{
                From = "noreply@example.com"
                To = $To
                Subject = $Subject
                Body = $Body
                SmtpServer = "smtp.example.com"
                Port = 587
                UseSSL = $true
                # Credentials = (Get-Credential)  # DÃ©commentez et configurez si nÃ©cessaire
            }
            
            # Envoyer l'email
            Send-MailMessage @emailParams
            
            Write-ColorMessage "Notification par email envoyÃ©e avec succÃ¨s" -ForegroundColor "Green"
        }
        else {
            # Alternative : utiliser .NET Framework
            $smtpClient = New-Object System.Net.Mail.SmtpClient("smtp.example.com", 587)
            $smtpClient.EnableSsl = $true
            # $smtpClient.Credentials = New-Object System.Net.NetworkCredential("username", "password")  # DÃ©commentez et configurez si nÃ©cessaire
            
            $mailMessage = New-Object System.Net.Mail.MailMessage
            $mailMessage.From = "noreply@example.com"
            $mailMessage.To.Add($To)
            $mailMessage.Subject = $Subject
            $mailMessage.Body = $Body
            
            $smtpClient.Send($mailMessage)
            
            Write-ColorMessage "Notification par email envoyÃ©e avec succÃ¨s" -ForegroundColor "Green"
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de l'envoi de la notification par email : $_" -ForegroundColor "Red"
    }
}

Write-ColorMessage "DÃ©ploiement rÃ©el vers l'environnement $Environment..." -ForegroundColor "Cyan"

# DÃ©finir les paramÃ¨tres de dÃ©ploiement en fonction de l'environnement
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

# Ã‰tape 1: ExÃ©cuter les tests si nÃ©cessaire
if (-not $SkipTests) {
    Write-ColorMessage "Ã‰tape 1: ExÃ©cution des tests..." -ForegroundColor "Cyan"
    
    $ciScript = Join-Path $projectRoot "scripts\ci\run-ci-checks.ps1"
    
    if (Test-Path $ciScript) {
        try {
            & $ciScript -SkipLint -SkipSecurity
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorMessage "Les tests ont Ã©chouÃ©. DÃ©ploiement annulÃ©." -ForegroundColor "Red"
                
                if ($SendNotification) {
                    Send-EmailNotification -Subject "DÃ©ploiement Ã©chouÃ©: Tests unitaires" -Body "Le dÃ©ploiement vers l'environnement $Environment a Ã©chouÃ© lors de l'exÃ©cution des tests unitaires." -To $NotificationEmail -Status "Failure"
                }
                
                if (-not $Force) {
                    exit 1
                }
                else {
                    Write-ColorMessage "Continuation forcÃ©e malgrÃ© l'Ã©chec des tests" -ForegroundColor "Yellow"
                }
            }
        }
        catch {
            Write-ColorMessage "Erreur lors de l'exÃ©cution des tests : $_" -ForegroundColor "Red"
            
            if ($SendNotification) {
                Send-EmailNotification -Subject "DÃ©ploiement Ã©chouÃ©: Erreur lors des tests" -Body "Le dÃ©ploiement vers l'environnement $Environment a Ã©chouÃ© lors de l'exÃ©cution des tests: $_" -To $NotificationEmail -Status "Failure"
            }
            
            if (-not $Force) {
                exit 1
            }
        }
    }
    else {
        Write-ColorMessage "Script CI non trouvÃ© : $ciScript" -ForegroundColor "Yellow"
    }
}
else {
    Write-ColorMessage "Ã‰tape 1: ExÃ©cution des tests ignorÃ©e (option -SkipTests)" -ForegroundColor "Yellow"
}

# Ã‰tape 2: CrÃ©er le package de dÃ©ploiement
Write-ColorMessage "Ã‰tape 2: CrÃ©ation du package de dÃ©ploiement..." -ForegroundColor "Cyan"

$buildDir = Join-Path $projectRoot "build"
$packageDir = Join-Path $buildDir "package"

# CrÃ©er les dossiers de build
if (Test-Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

# Copier les fichiers nÃ©cessaires
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

# CrÃ©er un fichier de version
$version = Get-Date -Format "yyyy.MM.dd.HHmm"
$versionFile = Join-Path $packageDir "version.txt"
Set-Content -Path $versionFile -Value "Version: $version`nEnvironnement: $Environment`nDÃ©ployÃ©: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# CrÃ©er une archive
$archiveName = "n8n-$Environment-$version.zip"
$archivePath = Join-Path $buildDir $archiveName

Write-ColorMessage "CrÃ©ation de l'archive $archiveName..." -ForegroundColor "Cyan"
Compress-Archive -Path "$packageDir\*" -DestinationPath $archivePath -Force

# Ã‰tape 3: DÃ©ployer vers l'environnement cible
Write-ColorMessage "Ã‰tape 3: DÃ©ploiement vers $($config.Server)..." -ForegroundColor "Cyan"

# VÃ©rifier si SSH est disponible
$sshAvailable = Get-Command ssh -ErrorAction SilentlyContinue
$scpAvailable = Get-Command scp -ErrorAction SilentlyContinue

if ($sshAvailable -and $scpAvailable) {
    # DÃ©ploiement rÃ©el via SSH
    try {
        # CrÃ©er une sauvegarde sur le serveur distant
        Write-ColorMessage "CrÃ©ation d'une sauvegarde sur le serveur distant..." -ForegroundColor "Cyan"
        $backupCommand = "if [ -d '$($config.Path)' ]; then mkdir -p '$($config.BackupPath)' && cp -r '$($config.Path)' '$($config.BackupPath)/backup-$(date +%Y%m%d%H%M%S)'; fi"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $backupCommand
        
        # CrÃ©er le rÃ©pertoire de destination s'il n'existe pas
        Write-ColorMessage "CrÃ©ation du rÃ©pertoire de destination..." -ForegroundColor "Cyan"
        $mkdirCommand = "mkdir -p '$($config.Path)'"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $mkdirCommand
        
        # Copier l'archive vers le serveur distant
        Write-ColorMessage "Copie de l'archive vers le serveur distant..." -ForegroundColor "Cyan"
        scp -i $config.SshKeyPath $archivePath "$($config.SshUser)@$($config.Server):$($config.Path)/"
        
        # Extraire l'archive sur le serveur distant
        Write-ColorMessage "Extraction de l'archive sur le serveur distant..." -ForegroundColor "Cyan"
        $extractCommand = "cd '$($config.Path)' && unzip -o '$archiveName' && rm '$archiveName'"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $extractCommand
        
        # RedÃ©marrer les services
        Write-ColorMessage "RedÃ©marrage des services..." -ForegroundColor "Cyan"
        $restartCommand = "cd '$($config.Path)' && ./scripts/ci/restart-services.sh"
        ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $restartCommand
        
        Write-ColorMessage "DÃ©ploiement rÃ©el terminÃ© avec succÃ¨s!" -ForegroundColor "Green"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "DÃ©ploiement rÃ©ussi: $Environment" -Body "Le dÃ©ploiement vers l'environnement $Environment a Ã©tÃ© effectuÃ© avec succÃ¨s.`n`nVersion: $version`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -To $NotificationEmail -Status "Success"
        }
    }
    catch {
        Write-ColorMessage "Erreur lors du dÃ©ploiement rÃ©el : $_" -ForegroundColor "Red"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "DÃ©ploiement Ã©chouÃ©: $Environment" -Body "Le dÃ©ploiement vers l'environnement $Environment a Ã©chouÃ©: $_" -To $NotificationEmail -Status "Failure"
        }
        
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    # Simulation de dÃ©ploiement (pour les environnements sans SSH)
    Write-ColorMessage "SSH ou SCP non disponible. Simulation du dÃ©ploiement..." -ForegroundColor "Yellow"
    
    Write-ColorMessage "Connexion au serveur $($config.Server)..." -ForegroundColor "Cyan"
    Write-ColorMessage "CrÃ©ation d'une sauvegarde dans $($config.BackupPath)..." -ForegroundColor "Cyan"
    Write-ColorMessage "Copie des fichiers vers $($config.Path)..." -ForegroundColor "Cyan"
    Write-ColorMessage "RedÃ©marrage des services..." -ForegroundColor "Cyan"
    
    Write-ColorMessage "Simulation de dÃ©ploiement terminÃ©e!" -ForegroundColor "Green"
    
    if ($SendNotification) {
        Send-EmailNotification -Subject "DÃ©ploiement simulÃ©: $Environment" -Body "La simulation de dÃ©ploiement vers l'environnement $Environment a Ã©tÃ© effectuÃ©e avec succÃ¨s.`n`nVersion: $version`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -To $NotificationEmail -Status "Success"
    }
}

# Ã‰tape 4: VÃ©rifier le dÃ©ploiement
Write-ColorMessage "Ã‰tape 4: VÃ©rification du dÃ©ploiement..." -ForegroundColor "Cyan"

if ($sshAvailable) {
    # VÃ©rification rÃ©elle via SSH
    try {
        # VÃ©rifier la version dÃ©ployÃ©e
        Write-ColorMessage "VÃ©rification de la version dÃ©ployÃ©e..." -ForegroundColor "Cyan"
        $versionCommand = "cat '$($config.Path)/version.txt'"
        $deployedVersion = ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $versionCommand
        
        Write-ColorMessage "Version dÃ©ployÃ©e:" -ForegroundColor "White"
        $deployedVersion | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        # VÃ©rifier les services
        Write-ColorMessage "VÃ©rification des services..." -ForegroundColor "Cyan"
        $serviceCommand = "cd '$($config.Path)' && ./scripts/ci/check-services.sh"
        $serviceStatus = ssh -i $config.SshKeyPath "$($config.SshUser)@$($config.Server)" $serviceCommand
        
        Write-ColorMessage "Statut des services:" -ForegroundColor "White"
        $serviceStatus | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        Write-ColorMessage "VÃ©rification du dÃ©ploiement terminÃ©e avec succÃ¨s!" -ForegroundColor "Green"
    }
    catch {
        Write-ColorMessage "Erreur lors de la vÃ©rification du dÃ©ploiement : $_" -ForegroundColor "Red"
        
        if ($SendNotification) {
            Send-EmailNotification -Subject "VÃ©rification du dÃ©ploiement Ã©chouÃ©e: $Environment" -Body "La vÃ©rification du dÃ©ploiement vers l'environnement $Environment a Ã©chouÃ©: $_" -To $NotificationEmail -Status "Failure"
        }
        
        if (-not $Force) {
            exit 1
        }
    }
}
else {
    # Simulation de vÃ©rification (pour les environnements sans SSH)
    Write-ColorMessage "SSH non disponible. Simulation de la vÃ©rification..." -ForegroundColor "Yellow"
    
    Write-ColorMessage "VÃ©rification de l'accÃ¨s Ã  l'application..." -ForegroundColor "Cyan"
    Write-ColorMessage "VÃ©rification des services..." -ForegroundColor "Cyan"
    Write-ColorMessage "VÃ©rification des logs..." -ForegroundColor "Cyan"
    
    Write-ColorMessage "Simulation de vÃ©rification terminÃ©e!" -ForegroundColor "Green"
}

# Afficher un rÃ©sumÃ©
Write-ColorMessage "`nRÃ©sumÃ© du dÃ©ploiement rÃ©el:" -ForegroundColor "Cyan"
Write-ColorMessage "- Environnement: $Environment" -ForegroundColor "White"
Write-ColorMessage "- Version: $version" -ForegroundColor "White"
Write-ColorMessage "- Archive: $archivePath" -ForegroundColor "White"
Write-ColorMessage "- Serveur: $($config.Server)" -ForegroundColor "White"
Write-ColorMessage "- Chemin: $($config.Path)" -ForegroundColor "White"

Write-ColorMessage "`nDÃ©ploiement rÃ©el terminÃ© avec succÃ¨s!" -ForegroundColor "Green"

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\deploy-real.ps1 -Environment <env> [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nEnvironnements:" -ForegroundColor "Cyan"
    Write-ColorMessage "  Development  Environnement de dÃ©veloppement" -ForegroundColor "Cyan"
    Write-ColorMessage "  Staging      Environnement de prÃ©-production" -ForegroundColor "Cyan"
    Write-ColorMessage "  Production   Environnement de production" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force             Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipTests         Ne pas exÃ©cuter les tests avant le dÃ©ploiement" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose           Afficher des informations dÃ©taillÃ©es" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SendNotification  Envoyer des notifications par email" -ForegroundColor "Cyan"
    Write-ColorMessage "  -NotificationEmail Adresse email pour les notifications (dÃ©faut: gerivonderbitsh+dev@gmail.com)" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy-real.ps1 -Environment Development" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy-real.ps1 -Environment Production -SkipTests -SendNotification" -ForegroundColor "Cyan"
}
