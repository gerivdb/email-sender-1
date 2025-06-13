# =============================================================================
# Install-UnixBridge.ps1 - Installation automatique du bridge Unix
# =============================================================================

[CmdletBinding()]
param(
   [switch]$Auto,
   [switch]$Uninstall,
   [switch]$Test
)

$bridgeScript = Join-Path $PSScriptRoot "UnixCommandsBridge.ps1"

if (-not (Test-Path $bridgeScript)) {
   Write-Error "UnixCommandsBridge.ps1 non trouvé dans le même répertoire"
   exit 1
}

if ($Uninstall) {
   Write-Host "🗑️  Désinstallation du bridge Unix..." -ForegroundColor Yellow
   & $bridgeScript -Uninstall
   exit 0
}

if ($Test) {
   Write-Host "🧪 Test des commandes Unix..." -ForegroundColor Yellow
   & $bridgeScript -TestCommands
   exit 0
}

Write-Host "🚀 Installation du bridge Unix vers PowerShell..." -ForegroundColor Green
Write-Host ""

# Vérification de Git Bash
$gitPaths = @(
   "C:\Program Files\Git\bin\bash.exe",
   "C:\Program Files (x86)\Git\bin\bash.exe"
)

$gitFound = $false
foreach ($path in $gitPaths) {
   if (Test-Path $path) {
      $gitFound = $true
      Write-Host "✅ Git Bash trouvé: $path" -ForegroundColor Green
      break
   }
}

if (-not $gitFound) {
   Write-Host "❌ Git Bash non trouvé!" -ForegroundColor Red
   Write-Host "   Téléchargez Git for Windows: https://git-scm.com/download/win" -ForegroundColor Yellow
   if (-not $Auto) {
      $response = Read-Host "Continuer quand même? (y/N)"
      if ($response -ne 'y' -and $response -ne 'Y') {
         exit 1
      }
   }
}

# Installation
Write-Host "📝 Installation dans le profil PowerShell..." -ForegroundColor Cyan
& $bridgeScript -Install

Write-Host ""
Write-Host "🎉 Installation terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "Actions disponibles:" -ForegroundColor White
Write-Host "  • Redémarrer PowerShell OU exécuter: . `$PROFILE" -ForegroundColor Yellow
Write-Host "  • Tester: Show-UnixCommands" -ForegroundColor Yellow
Write-Host "  • Aide: Get-Help grep" -ForegroundColor Yellow
Write-Host ""
Write-Host "Exemples d'utilisation:" -ForegroundColor White
Write-Host "  go test ./... -v | grep 'PASS' | wc -l" -ForegroundColor Cyan
Write-Host "  Get-Process | ConvertTo-Json | jq '.[] | .Name'" -ForegroundColor Cyan
Write-Host "  ls *.go | xargs grep -l 'func main'" -ForegroundColor Cyan

if (-not $Auto) {
   Write-Host ""
   $response = Read-Host "Charger le profil maintenant? (Y/n)"
   if ($response -ne 'n' -and $response -ne 'N') {
      . $PROFILE
      Write-Host "✅ Bridge chargé!" -ForegroundColor Green
   }
}
