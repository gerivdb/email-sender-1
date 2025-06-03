#Requires -Version 5.1
<#
.SYNOPSIS
    Installe et configure le gestionnaire de dépendances.

.DESCRIPTION
    Ce script installe le gestionnaire de dépendances Go pour le projet EMAIL_SENDER_1.
    Il configure l'environnement, construit le binaire et vérifie l'installation.

.PARAMETER Force
    Force l'installation sans demander de confirmation.

.PARAMETER SkipBuild
    Ignore la construction du binaire.

.EXAMPLE
    .\install-dependency-manager.ps1 -Force
    Installe le gestionnaire sans demander de confirmation.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-03
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
   [Parameter(Mandatory = $false)]
   [switch]$Force,
    
   [Parameter(Mandatory = $false)]
   [switch]$SkipBuild
)

# Variables
$script:ManagerRoot = $PSScriptRoot | Split-Path
$script:ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:ManagerRoot))
$script:ConfigPath = Join-Path $script:ProjectRoot "projet\config\managers\dependency-manager"
$script:LogsPath = Join-Path $script:ProjectRoot "logs"

# Fonction pour écrire dans le journal
function Write-Log {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [string]$Message,
        
      [Parameter(Mandatory = $false)]
      [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
      [string]$Level = "INFO"
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logMessage = "[$timestamp] [$Level] install-dependency-manager: $Message"
    
   $color = switch ($Level) {
      "INFO" { "White" }
      "WARNING" { "Yellow" }
      "ERROR" { "Red" }
      "SUCCESS" { "Green" }
   }
    
   Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour vérifier si une commande existe
function Test-Command {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [string]$Command
   )
    
   try {
      Get-Command $Command -ErrorAction Stop | Out-Null
      return $true
   }
   catch {
      return $false
   }
}

# Fonction pour vérifier les prérequis
function Test-Prerequisites {
   Write-Log "Vérification des prérequis..." -Level "INFO"
    
   $allGood = $true
    
   # Vérifier PowerShell version
   if ($PSVersionTable.PSVersion.Major -lt 5) {
      Write-Log "PowerShell 5.1 ou plus récent est requis" -Level "ERROR"
      $allGood = $false
   }
    
   # Vérifier Go
   if (!(Test-Command "go")) {
      Write-Log "Go n'est pas installé ou n'est pas dans le PATH" -Level "ERROR"
      Write-Log "Veuillez installer Go depuis https://golang.org/dl/" -Level "INFO"
      $allGood = $false
   }
   else {
      $goVersion = go version
      Write-Log "Go détecté: $goVersion" -Level "SUCCESS"
   }
    
   # Vérifier go.mod
   $goModPath = Join-Path $script:ProjectRoot "go.mod"
   if (!(Test-Path $goModPath)) {
      Write-Log "Fichier go.mod introuvable: $goModPath" -Level "ERROR"
      $allGood = $false
   }
    
   return $allGood
}

# Fonction pour créer les répertoires nécessaires
function Initialize-Directories {
   Write-Log "Initialisation des répertoires..." -Level "INFO"
    
   $directories = @(
      $script:ConfigPath,
      $script:LogsPath,
        (Join-Path $script:ManagerRoot "modules"),
        (Join-Path $script:ManagerRoot "tests")
   )
    
   foreach ($dir in $directories) {
      if (!(Test-Path $dir)) {
         try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Log "Répertoire créé: $dir" -Level "SUCCESS"
         }
         catch {
            Write-Log "Erreur lors de la création du répertoire $dir : $($_.Exception.Message)" -Level "ERROR"
            return $false
         }
      }
   }
    
   return $true
}

# Fonction pour vérifier la configuration
function Test-Configuration {
   $configFile = Join-Path $script:ConfigPath "dependency-manager.config.json"
    
   if (!(Test-Path $configFile)) {
      Write-Log "Fichier de configuration introuvable: $configFile" -Level "WARNING"
      return $false
   }
    
   try {
      $config = Get-Content $configFile | ConvertFrom-Json
      Write-Log "Configuration chargée avec succès" -Level "SUCCESS"
      Write-Log "Nom: $($config.name), Version: $($config.version)" -Level "INFO"
      return $true
   }
   catch {
      Write-Log "Erreur lors du chargement de la configuration: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

# Fonction pour construire le gestionnaire
function Build-Manager {
   if ($SkipBuild) {
      Write-Log "Construction ignorée (-SkipBuild)" -Level "INFO"
      return $true
   }
    
   Write-Log "Construction du gestionnaire de dépendances..." -Level "INFO"
    
   $modulePath = Join-Path $script:ManagerRoot "modules\dependency_manager.go"
   $binaryPath = Join-Path $script:ManagerRoot "modules\dependency_manager.exe"
    
   if (!(Test-Path $modulePath)) {
      Write-Log "Module Go introuvable: $modulePath" -Level "ERROR"
      return $false
   }
    
   $currentLocation = Get-Location
   try {
      Set-Location (Split-Path $modulePath)
        
      Write-Log "Téléchargement des dépendances Go..." -Level "INFO"
      go mod download
        
      Write-Log "Construction du binaire..." -Level "INFO"
      go build -o dependency_manager.exe dependency_manager.go
        
      if ($LASTEXITCODE -eq 0 -and (Test-Path $binaryPath)) {
         Write-Log "Construction réussie: $binaryPath" -Level "SUCCESS"
         return $true
      }
      else {
         Write-Log "Erreur lors de la construction" -Level "ERROR"
         return $false
      }
   }
   finally {
      Set-Location $currentLocation
   }
}

# Fonction pour tester l'installation
function Test-Installation {
   Write-Log "Test de l'installation..." -Level "INFO"
    
   $scriptPath = Join-Path $script:ManagerRoot "scripts\dependency-manager.ps1"
   $binaryPath = Join-Path $script:ManagerRoot "modules\dependency_manager.exe"
    
   # Vérifier que le script principal existe
   if (!(Test-Path $scriptPath)) {
      Write-Log "Script principal introuvable: $scriptPath" -Level "ERROR"
      return $false
   }
    
   # Vérifier que le binaire existe
   if (!(Test-Path $binaryPath)) {
      Write-Log "Binaire introuvable: $binaryPath" -Level "ERROR"
      return $false
   }
    
   # Tester la commande help
   try {
      $currentLocation = Get-Location
      Set-Location $script:ProjectRoot
        
      & $scriptPath -Action help
      if ($LASTEXITCODE -eq 0) {
         Write-Log "Test de l'aide réussi" -Level "SUCCESS"
      }
        
      # Tester la commande list
      & $scriptPath -Action list
      if ($LASTEXITCODE -eq 0) {
         Write-Log "Test de listage réussi" -Level "SUCCESS"
         return $true
      }
      else {
         Write-Log "Erreur lors du test de listage" -Level "WARNING"
         return $false
      }
   }
   catch {
      Write-Log "Erreur lors des tests: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
   finally {
      Set-Location $currentLocation
   }
}

# Fonction pour afficher le résumé d'installation
function Show-InstallationSummary {
   Write-Log "Installation terminée!" -Level "SUCCESS"
   Write-Host ""
   Write-Host "RÉSUMÉ DE L'INSTALLATION" -ForegroundColor Green
   Write-Host "=========================" -ForegroundColor Green
   Write-Host ""
   Write-Host "📁 Emplacement: $script:ManagerRoot" -ForegroundColor Cyan
   Write-Host "⚙️  Configuration: $script:ConfigPath" -ForegroundColor Cyan
   Write-Host "📝 Logs: $script:LogsPath" -ForegroundColor Cyan
   Write-Host ""
   Write-Host "UTILISATION:" -ForegroundColor Yellow
   Write-Host "  # Lister les dépendances" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action list" -ForegroundColor White
   Write-Host ""
   Write-Host "  # Ajouter une dépendance" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action add -Module 'github.com/pkg/errors'" -ForegroundColor White
   Write-Host ""
   Write-Host "  # Supprimer une dépendance" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action remove -Module 'github.com/pkg/errors'" -ForegroundColor White
   Write-Host ""
   Write-Host "  # Aide complète" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action help" -ForegroundColor White
   Write-Host ""
}

# Fonction principale
function Main {
   Write-Host "Installation du Gestionnaire de Dépendances" -ForegroundColor Green
   Write-Host "============================================" -ForegroundColor Green
   Write-Host ""
    
   if (!$Force) {
      $confirmation = Read-Host "Voulez-vous installer le gestionnaire de dépendances ? (y/N)"
      if ($confirmation -ne "y" -and $confirmation -ne "Y") {
         Write-Log "Installation annulée" -Level "INFO"
         return
      }
   }
    
   # Vérifier les prérequis
   if (!(Test-Prerequisites)) {
      Write-Log "Les prérequis ne sont pas satisfaits" -Level "ERROR"
      exit 1
   }
    
   # Initialiser les répertoires
   if (!(Initialize-Directories)) {
      Write-Log "Erreur lors de l'initialisation des répertoires" -Level "ERROR"
      exit 1
   }
    
   # Vérifier la configuration
   if (!(Test-Configuration)) {
      Write-Log "La configuration sera créée automatiquement lors de la première utilisation" -Level "INFO"
   }
    
   # Construire le gestionnaire
   if (!(Build-Manager)) {
      Write-Log "Erreur lors de la construction" -Level "ERROR"
      exit 1
   }
    
   # Tester l'installation
   if (!(Test-Installation)) {
      Write-Log "Erreur lors des tests d'installation" -Level "ERROR"
      exit 1
   }
    
   # Afficher le résumé
   Show-InstallationSummary
}

# Point d'entrée
try {
   Main
}
catch {
   Write-Log "Erreur inattendue: $($_.Exception.Message)" -Level "ERROR"
   exit 1
}
