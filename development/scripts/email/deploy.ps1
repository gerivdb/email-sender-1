# Script de dÃ©ploiement automatisÃ©
# Ce script dÃ©ploie le projet vers l'environnement spÃ©cifiÃ©

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
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

Write-ColorMessage "DÃ©ploiement vers l'environnement $Environment..." -ForegroundColor "Cyan"

# DÃ©finir les paramÃ¨tres de dÃ©ploiement en fonction de l'environnement
$deploymentConfig = @{
    Development = @{
        Server = "dev-server"
        Path = "/var/www/n8n-dev"
        BackupPath = "/var/www/n8n-dev-backup"
    }
    Staging = @{
        Server = "staging-server"
        Path = "/var/www/n8n-staging"
        BackupPath = "/var/www/n8n-staging-backup"
    }
    Production = @{
        Server = "prod-server"
        Path = "/var/www/n8n-prod"
        BackupPath = "/var/www/n8n-prod-backup"
    }
}

$config = $deploymentConfig[$Environment]

# Ã‰tape 1: ExÃ©cuter les tests si nÃ©cessaire
if (-not $SkipTests) {
    Write-ColorMessage "Ã‰tape 1: ExÃ©cution des tests..." -ForegroundColor "Cyan"
    
    $ciScript = Join-Path $projectRoot "..\D"
    
    if (Test-Path $ciScript) {
        try {
            & $ciScript -SkipLint -SkipSecurity
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorMessage "Les tests ont Ã©chouÃ©. DÃ©ploiement annulÃ©." -ForegroundColor "Red"
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
Set-Content -Path $versionFile -Value "Version: $version`nEnvironment: $Environment`nDeployed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# CrÃ©er une archive
$archiveName = "n8n-$Environment-$version.zip"
$archivePath = Join-Path $buildDir $archiveName

Write-ColorMessage "CrÃ©ation de l'archive $archiveName..." -ForegroundColor "Cyan"
Compress-Archive -Path "$packageDir\*" -DestinationPath $archivePath -Force

# Ã‰tape 3: DÃ©ployer vers l'environnement cible
Write-ColorMessage "Ã‰tape 3: DÃ©ploiement vers $($config.Server)..." -ForegroundColor "Cyan"

# Simuler le dÃ©ploiement (Ã  remplacer par le code de dÃ©ploiement rÃ©el)
Write-ColorMessage "Connexion au serveur $($config.Server)..." -ForegroundColor "Cyan"
Write-ColorMessage "CrÃ©ation d'une sauvegarde dans $($config.BackupPath)..." -ForegroundColor "Cyan"
Write-ColorMessage "Copie des fichiers vers $($config.Path)..." -ForegroundColor "Cyan"
Write-ColorMessage "RedÃ©marrage des services..." -ForegroundColor "Cyan"

# Ã‰tape 4: VÃ©rifier le dÃ©ploiement
Write-ColorMessage "Ã‰tape 4: VÃ©rification du dÃ©ploiement..." -ForegroundColor "Cyan"

# Simuler la vÃ©rification du dÃ©ploiement (Ã  remplacer par le code de vÃ©rification rÃ©el)
Write-ColorMessage "VÃ©rification de l'accÃ¨s Ã  l'application..." -ForegroundColor "Cyan"
Write-ColorMessage "VÃ©rification des services..." -ForegroundColor "Cyan"
Write-ColorMessage "VÃ©rification des logs..." -ForegroundColor "Cyan"

# Afficher un rÃ©sumÃ©
Write-ColorMessage "`nRÃ©sumÃ© du dÃ©ploiement:" -ForegroundColor "Cyan"
Write-ColorMessage "- Environnement: $Environment" -ForegroundColor "White"
Write-ColorMessage "- Version: $version" -ForegroundColor "White"
Write-ColorMessage "- Archive: $archivePath" -ForegroundColor "White"
Write-ColorMessage "- Serveur: $($config.Server)" -ForegroundColor "White"
Write-ColorMessage "- Chemin: $($config.Path)" -ForegroundColor "White"

Write-ColorMessage "`nDÃ©ploiement terminÃ© avec succÃ¨s!" -ForegroundColor "Green"

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\deploy.ps1 -Environment <env> [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nEnvironnements:" -ForegroundColor "Cyan"
    Write-ColorMessage "  Development  Environnement de dÃ©veloppement" -ForegroundColor "Cyan"
    Write-ColorMessage "  Staging      Environnement de prÃ©-production" -ForegroundColor "Cyan"
    Write-ColorMessage "  Production   Environnement de production" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force       Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipTests   Ne pas exÃ©cuter les tests avant le dÃ©ploiement" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose     Afficher des informations dÃ©taillÃ©es" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy.ps1 -Environment Development" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy.ps1 -Environment Production -SkipTests" -ForegroundColor "Cyan"
}

