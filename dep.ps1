# Gestionnaire de dépendances Go - Script d'utilisation facile
# Usage: .\dep.ps1 [command] [options]

param(
   [Parameter(Position = 0)]
   [ValidateSet("list", "add", "remove", "update", "build", "help")]
   [string]$Command = "help",
    
   [Parameter(Position = 1)]
   [string]$Module = "",
    
   [Parameter(Position = 2)]
   [string]$Version = "latest"
)

$BinaryPath = ".\tools\dependency_manager.exe"

function Show-Help {
   Write-Host "Gestionnaire de dépendances Go" -ForegroundColor Green
   Write-Host "===============================`n" -ForegroundColor Green
   Write-Host "Commandes disponibles:" -ForegroundColor Yellow
   Write-Host "  list                    - Affiche toutes les dépendances"
   Write-Host "  add <module> [version]  - Ajoute une dépendance"
   Write-Host "  remove <module>         - Supprime une dépendance"
   Write-Host "  update <module>         - Met à jour une dépendance"
   Write-Host "  build                   - Compile le gestionnaire"
   Write-Host "  help                    - Affiche cette aide`n"
    
   Write-Host "Exemples:" -ForegroundColor Cyan
   Write-Host "  .\dep.ps1 list"
   Write-Host "  .\dep.ps1 add github.com/pkg/errors v0.9.1"
   Write-Host "  .\dep.ps1 remove github.com/pkg/errors"
   Write-Host "  .\dep.ps1 update github.com/gorilla/mux"
}

function Build-DepManager {
   Write-Host "Compilation du gestionnaire de dépendances..." -ForegroundColor Yellow
   Set-Location tools
   try {
      go build -o dependency_manager.exe dependency_manager.go
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Compilation réussie!" -ForegroundColor Green
      }
      else {
         Write-Host "❌ Erreur de compilation" -ForegroundColor Red
         exit 1
      }
   }
   finally {
      Set-Location ..
   }
}

function Invoke-DepManager {
   param($Parameters)
    
   # Vérifier si le binaire existe, sinon le compiler
   if (-not (Test-Path $BinaryPath)) {
      Write-Host "Binaire non trouvé, compilation en cours..." -ForegroundColor Yellow
      Build-DepManager
   }
   Set-Location tools
   try {
      & ".\dependency_manager.exe" @Parameters
   }
   finally {
      Set-Location ..
   }
}

# Traitement des commandes
switch ($Command) {
   "help" {
      Show-Help
   }
   "build" {
      Build-DepManager
   }
   "list" {
      Invoke-DepManager @("list")
   }
   "add" {
      if ([string]::IsNullOrEmpty($Module)) {
         Write-Host "❌ Erreur: Module requis pour la commande 'add'" -ForegroundColor Red
         Write-Host "Usage: .\dep.ps1 add <module> [version]" -ForegroundColor Yellow
         exit 1
      }
      Invoke-DepManager @("add", "--module", $Module, "--version", $Version)
   }
   "remove" {
      if ([string]::IsNullOrEmpty($Module)) {
         Write-Host "❌ Erreur: Module requis pour la commande 'remove'" -ForegroundColor Red
         Write-Host "Usage: .\dep.ps1 remove <module>" -ForegroundColor Yellow
         exit 1
      }
      Invoke-DepManager @("remove", "--module", $Module)
   }
   "update" {
      if ([string]::IsNullOrEmpty($Module)) {
         Write-Host "❌ Erreur: Module requis pour la commande 'update'" -ForegroundColor Red
         Write-Host "Usage: .\dep.ps1 update <module>" -ForegroundColor Yellow
         exit 1
      }
      Invoke-DepManager @("update", "--module", $Module)
   }
   default {
      Write-Host "❌ Commande inconnue: $Command" -ForegroundColor Red
      Show-Help
      exit 1
   }
}
