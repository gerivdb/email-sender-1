<#
.SYNOPSIS
    Adaptateur pour le Dependency Manager.

.DESCRIPTION
    Cet adaptateur permet d'intégrer le Dependency Manager avec le Process Manager.
    Il fournit une interface standardisée pour interagir avec le gestionnaire de dépendances Go.

.PARAMETER Command
    La commande à exécuter. Les commandes disponibles sont :
    - List : Liste toutes les dépendances
    - Add : Ajoute une nouvelle dépendance
    - Remove : Supprime une dépendance
    - Update : Met à jour une dépendance
    - Audit : Vérifie les vulnérabilités de sécurité
    - Cleanup : Nettoie les dépendances inutilisées
    - GetInfo : Obtient des informations sur le gestionnaire

.PARAMETER Module
    Le nom du module pour les commandes Add, Remove et Update.

.PARAMETER Version
    La version spécifique pour la commande Add (optionnel).

.PARAMETER JsonOutput
    Indique si la sortie doit être en format JSON.

.PARAMETER Parameters
    Les paramètres supplémentaires à passer à la commande.

.EXAMPLE
    .\dependency-manager-adapter.ps1 -Command List
    Liste toutes les dépendances du projet.

.EXAMPLE
    .\dependency-manager-adapter.ps1 -Command Add -Module "github.com/pkg/errors" -Version "v0.9.1"
    Ajoute une nouvelle dépendance avec une version spécifique.

.EXAMPLE
    .\dependency-manager-adapter.ps1 -Command List -JsonOutput
    Liste toutes les dépendances en format JSON.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-01-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
   [Parameter(Mandatory = $true)]
   [ValidateSet("List", "Add", "Remove", "Update", "Audit", "Cleanup", "GetInfo", "Help")]
   [string]$Command,

   [Parameter(Mandatory = $false)]
   [string]$Module,

   [Parameter(Mandatory = $false)]
   [string]$Version,

   [Parameter(Mandatory = $false)]
   [switch]$JsonOutput,

   [Parameter(Mandatory = $false)]
   [hashtable]$Parameters = @{}
)

# Définir le chemin vers le Dependency Manager
$dependencyManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "dependency-manager"
$dependencyManagerScript = Join-Path -Path $dependencyManagerPath -ChildPath "scripts\dependency-manager.ps1"
$dependencyManagerBinary = Join-Path -Path $dependencyManagerPath -ChildPath "dependency-manager.exe"

# Vérifier que le Dependency Manager existe
if (-not (Test-Path -Path $dependencyManagerScript)) {
   Write-Error "Le script Dependency Manager est introuvable à l'emplacement : $dependencyManagerScript"
   exit 1
}

# Fonction pour exécuter une commande sur le Dependency Manager
function Invoke-DependencyManagerCommand {
   [CmdletBinding(SupportsShouldProcess = $true)]
   param (
      [Parameter(Mandatory = $true)]
      [string]$Command,

      [Parameter(Mandatory = $false)]
      [hashtable]$Parameters = @{}
   )

   # Traitement spécial pour GetInfo
   if ($Command.ToLower() -eq "getinfo") {
      return @{
         Name         = "DependencyManager"
         Version      = "1.0.0"
         Type         = "Go-Binary"
         Status       = if (Test-Path -Path $dependencyManagerBinary) { "Available" } else { "Binary Not Built" }
         BinaryPath   = $dependencyManagerBinary
         ScriptPath   = $dependencyManagerScript
         Capabilities = @("list", "add", "remove", "update", "audit", "cleanup")
         Description  = "Advanced Go dependency manager with enhanced features"
      }
   }

   # Exécuter la commande via PowerShell script
   if ($PSCmdlet.ShouldProcess("Dependency Manager", "Exécuter la commande $Command")) {
      try {
         # Préparer les arguments pour le script PowerShell
         $scriptArgs = @{
            Action = $Command.ToLower()
         }
            
         # Ajouter les arguments selon l'action
         switch ($Command.ToLower()) {
            "list" {
               if ($JsonOutput) {
                  $scriptArgs['JSON'] = $true
               }
            }
            "add" {
               if (-not $Module) {
                  Write-Error "Le paramètre Module est obligatoire pour la commande Add"
                  return $false
               }
               $scriptArgs['Module'] = $Module
               if ($Version) {
                  $scriptArgs['Version'] = $Version
               }
            }
            "remove" {
               if (-not $Module) {
                  Write-Error "Le paramètre Module est obligatoire pour la commande Remove"
                  return $false
               }
               $scriptArgs['Module'] = $Module
            }
            "update" {
               if (-not $Module) {
                  Write-Error "Le paramètre Module est obligatoire pour la commande Update"
                  return $false
               }
               $scriptArgs['Module'] = $Module
            }
            "audit" {
               # Pas de paramètres supplémentaires nécessaires
            }
            "cleanup" {
               # Pas de paramètres supplémentaires nécessaires
            }
            "help" {
               # Pas de paramètres supplémentaires nécessaires
            }
            default {
               Write-Error "Commande non supportée : $Command"
               return $false
            }
         }

         Write-Host "Exécution de la commande : $Command" -ForegroundColor Cyan
            
         # Exécuter le script PowerShell avec splatting
         $result = & $dependencyManagerScript @scriptArgs
            
         if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Host "Commande exécutée avec succès" -ForegroundColor Green
            return $result
         }
         else {
            Write-Error "Erreur lors de l'exécution de la commande (Code de sortie : $LASTEXITCODE)"
            return $false
         }
      }
      catch {
         Write-Error "Erreur lors de l'exécution de la commande $Command : $($_.Exception.Message)"
         return $false
      }
   }
}

# Fonction pour valider les paramètres
function Test-CommandParameters {
   param (
      [string]$Command,
      [string]$Module,
      [string]$Version
   )

   switch ($Command.ToLower()) {
      "add" {
         if ([string]::IsNullOrEmpty($Module)) {
            Write-Error "Le paramètre Module est obligatoire pour la commande Add"
            return $false
         }
      }
      "remove" {
         if ([string]::IsNullOrEmpty($Module)) {
            Write-Error "Le paramètre Module est obligatoire pour la commande Remove"
            return $false
         }
      }
      "update" {
         if ([string]::IsNullOrEmpty($Module)) {
            Write-Error "Le paramètre Module est obligatoire pour la commande Update"
            return $false
         }
      }
   }
   return $true
}

# Point d'entrée principal
try {
   # Valider les paramètres
   if (-not (Test-CommandParameters -Command $Command -Module $Module -Version $Version)) {
      exit 1
   }

   # Préparer les paramètres pour l'exécution
   $executeParams = @{
      Command    = $Command
      Parameters = $Parameters
   }

   # Ajouter les paramètres spécifiques si fournis
   if ($Module) { $executeParams.Parameters['Module'] = $Module }
   if ($Version) { $executeParams.Parameters['Version'] = $Version }
   if ($JsonOutput) { $executeParams.Parameters['JsonOutput'] = $true }

   # Exécuter la commande
   $result = Invoke-DependencyManagerCommand @executeParams

   # Afficher le résultat si nécessaire
   if ($result -and $result -ne $false) {
      if ($result -is [hashtable] -or $result -is [PSCustomObject]) {
         $result | ConvertTo-Json -Depth 10 | Write-Output
      }
      else {
         Write-Output $result
      }
   }

   exit 0
}
catch {
   Write-Error "Erreur dans l'adaptateur Dependency Manager : $($_.Exception.Message)"
   exit 1
}
