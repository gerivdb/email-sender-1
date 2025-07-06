#Requires -Version 5.1
<#
.SYNOPSIS
    Gestionnaire de dépendances Go pour le projet EMAIL_SENDER_1.

.DESCRIPTION
    Ce script permet de gérer les dépendances Go du projet via une interface unifiée.
    Il offre des fonctionnalités pour lister, ajouter, supprimer, mettre à jour et auditer les dépendances.

.PARAMETER Action
    L'action à exécuter. Valeurs possibles : list, add, remove, update, audit, cleanup, build, install.

.PARAMETER Module
    Le nom du module Go à traiter (ex: github.com/pkg/errors).

.PARAMETER Version
    La version du module à installer/mettre à jour. Par défaut : "latest".

.PARAMETER Force
    Force l'exécution sans demander de confirmation.

.PARAMETER JSON
    Affiche la sortie au format JSON (pour l'action list).

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut, utilise la configuration standard.

.PARAMETER LogLevel
    Niveau de log. Valeurs possibles : DEBUG, INFO, WARNING, ERROR.

.EXAMPLE
    .\dependency-manager.ps1 -Action list
    Liste toutes les dépendances du projet.

.EXAMPLE
    .\dependency-manager.ps1 -Action add -Module "github.com/pkg/errors" -Version "v0.9.1"
    Ajoute la dépendance github.com/pkg/errors en version v0.9.1.

.EXAMPLE
    .\dependency-manager.ps1 -Action remove -Module "github.com/pkg/errors" -Force
    Supprime la dépendance github.com/pkg/errors sans demander de confirmation.

.EXAMPLE
    .\dependency-manager.ps1 -Action update -Module "github.com/gorilla/mux"
    Met à jour github.com/gorilla/mux vers la dernière version.

.EXAMPLE
    .\dependency-manager.ps1 -Action audit
    Vérifie les vulnérabilités des dépendances.

.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0.0
    Date: 2025-06-03
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
   [Parameter(Mandatory = $true)]
   [ValidateSet("list", "add", "remove", "update", "audit", "cleanup", "build", "install", "help")]
   [string]$Action,
    
   [Parameter(Mandatory = $false)]
   [string]$Module = "",
    
   [Parameter(Mandatory = $false)]
   [string]$Version = "latest",
    
   [Parameter(Mandatory = $false)]
   [switch]$Force,
    
   [Parameter(Mandatory = $false)]
   [switch]$JSON,
    
   [Parameter(Mandatory = $false)]
   [string]$ConfigPath = "",
    
   [Parameter(Mandatory = $false)]
   [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
   [string]$LogLevel = "INFO"
)

# Variables globales
$script:ManagerRoot = if ($PSScriptRoot) { Split-Path $PSScriptRoot } else { "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\dependency-manager" }
$script:ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:ManagerRoot))
$script:GoModulePath = Join-Path $script:ManagerRoot "modules\dependency_manager.go"
$script:BinaryPath = Join-Path $script:ManagerRoot "dependency-manager.exe"
$script:ConfigPath = Join-Path $script:ProjectRoot "projet\config\managers\dependency-manager\dependency-manager.config.json"
$script:LogsPath = Join-Path $script:ProjectRoot "logs"

# Fonction pour écrire dans le journal
function Write-Log {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [string]$Message,
        
      [Parameter(Mandatory = $false)]
      [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS")]
      [string]$Level = "INFO"
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logMessage = "[$timestamp] [$Level] dependency-manager: $Message"
    
   $color = switch ($Level) {
      "DEBUG" { "Gray" }
      "INFO" { "White" }
      "WARNING" { "Yellow" }
      "ERROR" { "Red" }
      "SUCCESS" { "Green" }
   }
    
   Write-Host $logMessage -ForegroundColor $color
    
   # Écrire dans le fichier de log
   if (!(Test-Path $script:LogsPath)) {
      New-Item -ItemType Directory -Path $script:LogsPath -Force | Out-Null
   }
    
   $logFile = Join-Path $script:LogsPath "dependency-manager.log"
   Add-Content -Path $logFile -Value $logMessage
}

# Fonction pour vérifier les prérequis
function Test-Prerequisites {
   Write-Log "Vérification des prérequis..." -Level "INFO"
    
   # Vérifier Go
   try {
      $goVersion = go version
      Write-Log "Go détecté: $goVersion" -Level "SUCCESS"
   }
   catch {
      Write-Log "Go n'est pas installé ou n'est pas dans le PATH" -Level "ERROR"
      return $false
   }
   # Vérifier go.mod
   $goModPath = Join-Path $script:ProjectRoot "go.mod"
   if (!(Test-Path $goModPath)) {
      Write-Log "Fichier go.mod introuvable: $goModPath" -Level "ERROR"
      return $false
   }
    
   Write-Log "Prérequis validés" -Level "SUCCESS"
   return $true
}

# Fonction pour construire le binaire
function Build-DependencyManager {
   Write-Log "Construction du gestionnaire de dépendances..." -Level "INFO"
    
   $currentLocation = Get-Location
   try {
      Set-Location (Split-Path $script:GoModulePath)
        
      $buildCmd = "go build -o dependency_manager.exe dependency_manager.go"
      Write-Log "Exécution: $buildCmd" -Level "DEBUG"
        
      Invoke-Expression $buildCmd
        
      if ($LASTEXITCODE -eq 0) {
         Write-Log "Construction réussie!" -Level "SUCCESS"
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

# Fonction pour installer le gestionnaire
function Install-DependencyManager {
   Write-Log "Installation du gestionnaire de dépendances..." -Level "INFO"
    
   if (!(Build-DependencyManager)) {
      return $false
   }
    
   # Copier le binaire vers un emplacement global si nécessaire
   # Ici, on peut ajouter la logique pour installer globalement
    
   Write-Log "Installation terminée" -Level "SUCCESS"
   return $true
}

# Fonction pour exécuter une commande du gestionnaire
function Invoke-DependencyCommand {
   param (
      [string]$Command,
      [string[]]$Arguments = @()
   )
    
   # Construire le binaire si nécessaire
   if (!(Test-Path $script:BinaryPath)) {
      Write-Log "Binaire introuvable, construction..." -Level "INFO"
      if (!(Build-DependencyManager)) {
         return $false
      }
   }
   $currentLocation = Get-Location
   try {
      Set-Location $script:ProjectRoot
        
      $allArgs = @($Command) + $Arguments
      
      Write-Log "Exécution: `"$script:BinaryPath`" $($allArgs -join ' ')" -Level "DEBUG"
      
      & $script:BinaryPath $allArgs
        
      return $LASTEXITCODE -eq 0
   }
   finally {
      Set-Location $currentLocation
   }
}

# Fonction pour afficher l'aide
function Show-Help {
   Write-Host "Gestionnaire de dépendances Go - EMAIL_SENDER_1" -ForegroundColor Green
   Write-Host "=================================================" -ForegroundColor Green
   Write-Host ""
   Write-Host "ACTIONS DISPONIBLES:" -ForegroundColor Yellow
   Write-Host "  list              - Liste toutes les dépendances" -ForegroundColor White
   Write-Host "  add               - Ajoute une dépendance" -ForegroundColor White
   Write-Host "  remove            - Supprime une dépendance" -ForegroundColor White
   Write-Host "  update            - Met à jour une dépendance" -ForegroundColor White
   Write-Host "  audit             - Vérifie les vulnérabilités" -ForegroundColor White
   Write-Host "  cleanup           - Nettoie les dépendances inutilisées" -ForegroundColor White
   Write-Host "  build             - Construit le gestionnaire" -ForegroundColor White
   Write-Host "  install           - Installe le gestionnaire" -ForegroundColor White
   Write-Host "  help              - Affiche cette aide" -ForegroundColor White
   Write-Host ""
   Write-Host "EXEMPLES:" -ForegroundColor Cyan
   Write-Host "  .\dependency-manager.ps1 -Action list" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action list -JSON" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action add -Module 'github.com/pkg/errors' -Version 'v0.9.1'" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action remove -Module 'github.com/pkg/errors' -Force" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action update -Module 'github.com/gorilla/mux'" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action audit" -ForegroundColor Gray
   Write-Host "  .\dependency-manager.ps1 -Action cleanup" -ForegroundColor Gray
   Write-Host ""
}

# Fonction principale
function Main {
   Write-Log "Démarrage du gestionnaire de dépendances" -Level "INFO"
    
   if ($Action -eq "help") {
      Show-Help
      return
   }
    
   if (!(Test-Prerequisites)) {
      Write-Log "Les prérequis ne sont pas satisfaits" -Level "ERROR"
      exit 1
   }
    
   switch ($Action) {
      "build" {
         if (Build-DependencyManager) {
            Write-Log "Construction terminée avec succès" -Level "SUCCESS"
            exit 0
         }
         else {
            Write-Log "Échec de la construction" -Level "ERROR"
            exit 1
         }
      }
        
      "install" {
         if (Install-DependencyManager) {
            Write-Log "Installation terminée avec succès" -Level "SUCCESS"
            exit 0
         }
         else {
            Write-Log "Échec de l'installation" -Level "ERROR"
            exit 1
         }
      }
        
      "list" {
         $arguments = @()
         if ($JSON) { $arguments += "--json" }
            
         if (Invoke-DependencyCommand "list" $arguments) {
            Write-Log "Liste des dépendances affichée" -Level "SUCCESS"
         }
         else {
            Write-Log "Erreur lors de l'affichage des dépendances" -Level "ERROR"
            exit 1
         }
      }
        
      "add" {
         if ([string]::IsNullOrEmpty($Module)) {
            Write-Log "Le paramètre -Module est requis pour l'action add" -Level "ERROR"
            exit 1
         }
            
         $arguments = @("--module", "`"$Module`"", "--version", "`"$Version`"")
            
         if (Invoke-DependencyCommand "add" $arguments) {
            Write-Log "Dépendance $Module@$Version ajoutée avec succès" -Level "SUCCESS"
         }
         else {
            Write-Log "Erreur lors de l'ajout de la dépendance $Module" -Level "ERROR"
            exit 1
         }
      }
        
      "remove" {
         if ([string]::IsNullOrEmpty($Module)) {
            Write-Log "Le paramètre -Module est requis pour l'action remove" -Level "ERROR"
            exit 1
         }
            
         if (!$Force) {
            $confirmation = Read-Host "Êtes-vous sûr de vouloir supprimer $Module ? (y/N)"
            if ($confirmation -ne "y" -and $confirmation -ne "Y") {
               Write-Log "Suppression annulée" -Level "INFO"
               return
            }
         }            
         $arguments = @("--module", "`"$Module`"")
            
         if (Invoke-DependencyCommand "remove" $arguments) {
            Write-Log "Dépendance $Module supprimée avec succès" -Level "SUCCESS"
         }
         else {
            Write-Log "Erreur lors de la suppression de la dépendance $Module" -Level "ERROR"
            exit 1
         }
      }
        
      "update" {
         if ([string]::IsNullOrEmpty($Module)) {
            Write-Log "Le paramètre -Module est requis pour l'action update" -Level "ERROR"
            exit 1
         }            
         $arguments = @("--module", "`"$Module`"")
            
         if (Invoke-DependencyCommand "update" $arguments) {
            Write-Log "Dépendance $Module mise à jour avec succès" -Level "SUCCESS"
         }
         else {
            Write-Log "Erreur lors de la mise à jour de la dépendance $Module" -Level "ERROR"
            exit 1
         }
      }
        
      "audit" {
         if (Invoke-DependencyCommand "audit") {
            Write-Log "Audit des dépendances terminé" -Level "SUCCESS"
         }
         else {
            Write-Log "Erreur lors de l'audit des dépendances" -Level "ERROR"
            exit 1
         }
      }
        
      "cleanup" {
         if (!$Force) {
            $confirmation = Read-Host "Êtes-vous sûr de vouloir nettoyer les dépendances inutilisées ? (y/N)"
            if ($confirmation -ne "y" -and $confirmation -ne "Y") {
               Write-Log "Nettoyage annulé" -Level "INFO"
               return
            }
         }
            
         if (Invoke-DependencyCommand "cleanup") {
            Write-Log "Nettoyage des dépendances terminé" -Level "SUCCESS"
         }
         else {
            Write-Log "Erreur lors du nettoyage des dépendances" -Level "ERROR"
            exit 1
         }
      }
        
      default {
         Write-Log "Action inconnue: $Action" -Level "ERROR"
         Show-Help
         exit 1
      }
   }
}

# Point d'entrée
try {
   Main
}
catch {
   Write-Log "Erreur inattendue: $($_.Exception.Message)" -Level "ERROR"
   exit 1
}
