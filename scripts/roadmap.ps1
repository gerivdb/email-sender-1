# Gestionnaire de roadmap TaskMaster - Script d'utilisation facile
# Usage: .\scripts\roadmap.ps1 [command] [options]

param(
   [Parameter(Position = 0)]
   [ValidateSet("help", "create", "view", "ingest", "ingest-advanced", "build", "test")]
   [string]$Command = "help",
    
   [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
   [string[]]$Arguments = @()
)

# Utilise le nouveau gestionnaire de roadmap unifié
$BinaryPath = ".\development\managers\roadmap-manager\roadmap-cli\roadmap-cli.exe"

function Show-Help {
   Write-Host "Gestionnaire de roadmap TaskMaster" -ForegroundColor Green
   Write-Host "===================================`n" -ForegroundColor Green
   Write-Host "Commandes disponibles:" -ForegroundColor Yellow
   Write-Host "  help                    - Affiche cette aide"
   Write-Host "  create                  - Créer un nouvel item"
   Write-Host "  view                    - Interface TUI interactive"
   Write-Host "  ingest                  - Ingérer un document"
   Write-Host "  ingest-advanced         - Ingestion avancée avec parsing"
   Write-Host "  build                   - Compile le gestionnaire"
   Write-Host "  test                    - Lance les tests`n"
    
   Write-Host "Exemples:" -ForegroundColor Cyan
   Write-Host "  .\scripts\roadmap.ps1 help"
   Write-Host "  .\scripts\roadmap.ps1 view"
   Write-Host "  .\scripts\roadmap.ps1 create item `"Build API`" --priority high"
   Write-Host "  .\scripts\roadmap.ps1 ingest-advanced plan.md --dry-run"
}

function Build-RoadmapManager {
   Write-Host "Compilation du gestionnaire de roadmap..." -ForegroundColor Yellow
   Set-Location "development\managers\roadmap-manager\roadmap-cli"
   try {
      go build -o "roadmap-cli.exe" main.go
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Compilation réussie!" -ForegroundColor Green
      }
      else {
         Write-Host "❌ Erreur de compilation" -ForegroundColor Red
         exit 1
      }
   }
   finally {
      Set-Location "..\..\..\.."
   }
}

function Test-RoadmapManager {
   Write-Host "Lancement des tests du gestionnaire de roadmap..." -ForegroundColor Yellow
   Set-Location "development\managers\roadmap-manager\roadmap-cli"
   try {
      go test ./...
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Tests réussis!" -ForegroundColor Green
      }
      else {
         Write-Host "❌ Erreur dans les tests" -ForegroundColor Red
         exit 1
      }
   }
   finally {
      Set-Location "..\..\..\.."
   }
}

function Invoke-RoadmapManager {
   param($Args)
    
   # Vérifier si le binaire existe, sinon le compiler
   if (-not (Test-Path $BinaryPath)) {
      Write-Host "Binaire non trouvé, compilation en cours..." -ForegroundColor Yellow
      Build-RoadmapManager
   }
    
   Set-Location "development\managers\roadmap-manager\roadmap-cli"
   try {
      & ".\roadmap-cli.exe" @Args
   }
   finally {
      Set-Location "..\..\..\.."
   }
}

# Traitement des commandes
switch ($Command) {
   "help" {
      Show-Help
   }
   "build" {
      Build-RoadmapManager
   }
   "test" {
      Test-RoadmapManager
   }
   default {
      # Pour toutes les autres commandes, les passer directement au binaire
      $allArgs = @($Command) + $Arguments
      Invoke-RoadmapManager $allArgs
   }
}
