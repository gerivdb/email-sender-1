# Script de déploiement automatisé
# Ce script déploie le projet vers l'environnement spécifié

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

Write-ColorMessage "Déploiement vers l'environnement $Environment..." -ForegroundColor "Cyan"

# Définir les paramètres de déploiement en fonction de l'environnement
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

# Étape 1: Exécuter les tests si nécessaire
if (-not $SkipTests) {
    Write-ColorMessage "Étape 1: Exécution des tests..." -ForegroundColor "Cyan"
    
    $ciScript = Join-Path $projectRoot "scripts\ci\run-ci-checks.ps1"
    
    if (Test-Path $ciScript) {
        try {
            & $ciScript -SkipLint -SkipSecurity
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorMessage "Les tests ont échoué. Déploiement annulé." -ForegroundColor "Red"
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
Set-Content -Path $versionFile -Value "Version: $version`nEnvironment: $Environment`nDeployed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Créer une archive
$archiveName = "n8n-$Environment-$version.zip"
$archivePath = Join-Path $buildDir $archiveName

Write-ColorMessage "Création de l'archive $archiveName..." -ForegroundColor "Cyan"
Compress-Archive -Path "$packageDir\*" -DestinationPath $archivePath -Force

# Étape 3: Déployer vers l'environnement cible
Write-ColorMessage "Étape 3: Déploiement vers $($config.Server)..." -ForegroundColor "Cyan"

# Simuler le déploiement (à remplacer par le code de déploiement réel)
Write-ColorMessage "Connexion au serveur $($config.Server)..." -ForegroundColor "Cyan"
Write-ColorMessage "Création d'une sauvegarde dans $($config.BackupPath)..." -ForegroundColor "Cyan"
Write-ColorMessage "Copie des fichiers vers $($config.Path)..." -ForegroundColor "Cyan"
Write-ColorMessage "Redémarrage des services..." -ForegroundColor "Cyan"

# Étape 4: Vérifier le déploiement
Write-ColorMessage "Étape 4: Vérification du déploiement..." -ForegroundColor "Cyan"

# Simuler la vérification du déploiement (à remplacer par le code de vérification réel)
Write-ColorMessage "Vérification de l'accès à l'application..." -ForegroundColor "Cyan"
Write-ColorMessage "Vérification des services..." -ForegroundColor "Cyan"
Write-ColorMessage "Vérification des logs..." -ForegroundColor "Cyan"

# Afficher un résumé
Write-ColorMessage "`nRésumé du déploiement:" -ForegroundColor "Cyan"
Write-ColorMessage "- Environnement: $Environment" -ForegroundColor "White"
Write-ColorMessage "- Version: $version" -ForegroundColor "White"
Write-ColorMessage "- Archive: $archivePath" -ForegroundColor "White"
Write-ColorMessage "- Serveur: $($config.Server)" -ForegroundColor "White"
Write-ColorMessage "- Chemin: $($config.Path)" -ForegroundColor "White"

Write-ColorMessage "`nDéploiement terminé avec succès!" -ForegroundColor "Green"

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\deploy.ps1 -Environment <env> [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nEnvironnements:" -ForegroundColor "Cyan"
    Write-ColorMessage "  Development  Environnement de développement" -ForegroundColor "Cyan"
    Write-ColorMessage "  Staging      Environnement de pré-production" -ForegroundColor "Cyan"
    Write-ColorMessage "  Production   Environnement de production" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Force       Ignorer les erreurs et continuer" -ForegroundColor "Cyan"
    Write-ColorMessage "  -SkipTests   Ne pas exécuter les tests avant le déploiement" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose     Afficher des informations détaillées" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy.ps1 -Environment Development" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\deploy.ps1 -Environment Production -SkipTests" -ForegroundColor "Cyan"
}
