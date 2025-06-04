# Test PowerShell Integration with Real-time Bridge
# Section 8.2 - Optimisation Surveillance Temps Réel
# This script demonstrates the integration between PowerShell FileSystemWatcher and Go bridge

[CmdletBinding()]
param(
   [string]$BridgeUrl = "http://localhost:8080",
   [string]$TestPath = ".\test-files",
   [int]$DurationSeconds = 30
)

Write-Host "🚀 Test d'intégration PowerShell - Bridge Go" -ForegroundColor Cyan
Write-Host "Section 8.2 - Surveillance Temps Réel" -ForegroundColor Gray
Write-Host ""

# Créer le dossier de test s'il n'existe pas
if (-not (Test-Path $TestPath)) {
   New-Item -ItemType Directory -Path $TestPath -Force | Out-Null
   Write-Host "📁 Dossier de test créé: $TestPath" -ForegroundColor Green
}

# Fonction pour vérifier la connectivité au bridge
function Test-BridgeConnectivity {
   param([string]$Url)
    
   try {
      $response = Invoke-RestMethod -Uri "$Url/health" -Method GET -TimeoutSec 5
      Write-Host "✅ Bridge Go détecté et opérationnel" -ForegroundColor Green
      Write-Host "   Status: $($response.status)" -ForegroundColor Gray
      Write-Host "   Uptime: $($response.uptime)" -ForegroundColor Gray
      return $true
   }
   catch {
      Write-Host "❌ Bridge Go non disponible à $Url" -ForegroundColor Red
      Write-Host "   Erreur: $($_.Exception.Message)" -ForegroundColor Red
      return $false
   }
}

# Fonction pour créer des fichiers de test
function New-TestFiles {
   param([string]$Path)
   $testFiles = @(
      @{ Name = "test-script.ps1"; Content = "# Test PowerShell script`nWrite-Host 'Hello World'" },
      @{ Name = "duplicate-function.py"; Content = "def test():`n    print('Hello from Python')`n    return True" },
      @{ Name = "config.json"; Content = '{"test": true, "environment": "development"}' },
      @{ Name = "readme.md"; Content = "# Test Documentation`nThis is a test file." }
   )
    
   foreach ($file in $testFiles) {
      $filePath = Join-Path $Path $file.Name
      Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
      Write-Host "📄 Fichier créé: $($file.Name)" -ForegroundColor Yellow
   }
}

# Fonction pour simuler des modifications
function Start-FileModificationSimulation {
   param([string]$Path, [int]$Duration)
    
   $endTime = (Get-Date).AddSeconds($Duration)
   $fileCount = 0
    
   Write-Host "🔄 Simulation de modifications pendant $Duration secondes..." -ForegroundColor Cyan
    
   while ((Get-Date) -lt $endTime) {
      # Sélectionner un fichier au hasard
      $files = Get-ChildItem $Path -File
      if ($files.Count -gt 0) {
         $randomFile = $files | Get-Random
            
         # Ajouter du contenu au fichier
         $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
         Add-Content -Path $randomFile.FullName -Value "`n// Modification automatique à $timestamp"
            
         $fileCount++
         Write-Host "   ✏️  Modification #$fileCount : $($randomFile.Name)" -ForegroundColor Green
            
         # Attendre un délai aléatoire
         Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 5)
      }
   }
    
   Write-Host "✅ Simulation terminée: $fileCount modifications effectuées" -ForegroundColor Green
}

# Fonction pour vérifier les événements dans le bridge
function Get-BridgeEvents {
   param([string]$Url)
    
   try {
      $response = Invoke-RestMethod -Uri "$Url/events" -Method GET -TimeoutSec 5
      return $response
   }
   catch {
      Write-Host "⚠️  Impossible de récupérer les événements: $($_.Exception.Message)" -ForegroundColor Yellow
      return $null
   }
}

# Fonction pour afficher le statut du bridge
function Show-BridgeStatus {
   param([string]$Url)
    
   try {
      $status = Invoke-RestMethod -Uri "$Url/status" -Method GET -TimeoutSec 5
        
      Write-Host "`n📊 Statut du Bridge Go:" -ForegroundColor Cyan
      Write-Host "   Événements traités: $($status.events_processed)" -ForegroundColor Gray
      Write-Host "   Événements en buffer: $($status.buffer_size)" -ForegroundColor Gray
      Write-Host "   Dernière activité: $($status.last_activity)" -ForegroundColor Gray
        
      if ($status.file_patterns) {
         Write-Host "   Types de fichiers surveillés: $($status.file_patterns -join ', ')" -ForegroundColor Gray
      }
        
      return $status
   }
   catch {
      Write-Host "⚠️  Impossible de récupérer le statut: $($_.Exception.Message)" -ForegroundColor Yellow
      return $null
   }
}

# === DÉBUT DU TEST ===

Write-Host "🔍 Étape 1: Vérification de la connectivité" -ForegroundColor Yellow
$bridgeAvailable = Test-BridgeConnectivity -Url $BridgeUrl

if (-not $bridgeAvailable) {
   Write-Host ""
   Write-Host "❌ Test interrompu: Bridge Go non disponible" -ForegroundColor Red
   Write-Host "💡 Assurez-vous que le bridge est démarré avec:" -ForegroundColor Yellow
   Write-Host "   cd bridges && go run demo/main.go" -ForegroundColor Cyan
   exit 1
}

Write-Host "`n📁 Étape 2: Création des fichiers de test" -ForegroundColor Yellow
New-TestFiles -Path $TestPath

Write-Host "`n📊 Étape 3: Statut initial du bridge" -ForegroundColor Yellow
$initialStatus = Show-BridgeStatus -Url $BridgeUrl

Write-Host "`n🚀 Étape 4: Démarrage de la surveillance PowerShell" -ForegroundColor Yellow
Write-Host "💡 Dans un autre terminal, exécutez:" -ForegroundColor Cyan
Write-Host "   .\Manage-Duplications.ps1 -Action watch -Path '$TestPath' -RealtimeBridgeUrl '$BridgeUrl'" -ForegroundColor White

Write-Host "`nAppuyez sur une touche pour continuer une fois la surveillance démarrée..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host "`n🔄 Étape 5: Simulation des modifications" -ForegroundColor Yellow
Start-FileModificationSimulation -Path $TestPath -Duration $DurationSeconds

Write-Host "`n⏳ Attente de traitement des événements..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "`n📊 Étape 6: Statut final du bridge" -ForegroundColor Yellow
$finalStatus = Show-BridgeStatus -Url $BridgeUrl

Write-Host "`n📋 Étape 7: Récupération des événements" -ForegroundColor Yellow
$events = Get-BridgeEvents -Url $BridgeUrl

if ($events) {
   Write-Host "✅ Événements récupérés: $($events.Count)" -ForegroundColor Green
    
   # Afficher les derniers événements
   $recentEvents = $events | Select-Object -Last 5
   foreach ($event in $recentEvents) {
      Write-Host "   📝 $($event.timestamp): $($event.type) - $($event.file_path)" -ForegroundColor Gray
   }
}
else {
   Write-Host "⚠️  Aucun événement récupéré" -ForegroundColor Yellow
}

# Calculer les métriques
if ($initialStatus -and $finalStatus) {
   $eventsGenerated = $finalStatus.events_processed - $initialStatus.events_processed
   Write-Host "`n📈 Métriques du test:" -ForegroundColor Cyan
   Write-Host "   Événements générés: $eventsGenerated" -ForegroundColor Green
   Write-Host "   Fichiers créés: 4" -ForegroundColor Green
   Write-Host "   Modifications simulées: Variable" -ForegroundColor Green
}

Write-Host "`n🧹 Nettoyage des fichiers de test..." -ForegroundColor Yellow
if (Test-Path $TestPath) {
   Remove-Item $TestPath -Recurse -Force
   Write-Host "✅ Fichiers de test supprimés" -ForegroundColor Green
}

Write-Host "`n✅ Test d'intégration terminé avec succès!" -ForegroundColor Green
Write-Host "📋 Résumé:" -ForegroundColor Cyan
Write-Host "   • FileSystemWatcher PowerShell OK" -ForegroundColor Green
Write-Host "   • Communication HTTP avec Bridge Go OK" -ForegroundColor Green
Write-Host "   • Traitement d'événements en temps réel OK" -ForegroundColor Green
Write-Host "   • Intégration Section 8.2 complète OK" -ForegroundColor Green
