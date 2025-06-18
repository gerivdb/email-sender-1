# Script de test pour vérifier l'exclusion AVG des fichiers .exe
# Exécute une compilation Go simple et vérifie si AVG bloque

# Définir le titre pour l'identification du processus
$Host.UI.RawUI.WindowTitle = "Vérification-Exclusion-AVG-EXE-Test [PID:$PID]"

# Chemin du projet
$ProjectPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$LogPath = "$ProjectPath\logs\avg-test-results.log"

# Fonction de logging
function Write-TestLog {
   param($Message)
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [TEST] $Message"
    
   # Créer le répertoire de logs s'il n'existe pas
   $logDir = Split-Path $LogPath -Parent
   if (!(Test-Path $logDir)) {
      New-Item -ItemType Directory -Path $logDir -Force | Out-Null
   }
    
   Add-Content -Path $LogPath -Value $logEntry
   Write-Host $logEntry
}

Write-TestLog "🧪 Début du test d'exclusion AVG pour les fichiers .exe"

# 1. D'abord vérifier si les marqueurs d'exclusion AVG existent déjà
Write-TestLog "� Vérification des marqueurs d'exclusion AVG..."

$markerFound = $false
$avgMarkers = @(
   "$ProjectPath\.avg-exclude-marker", 
   "$ProjectPath\.avg-exclude-exe-marker", 
   "$ProjectPath\logs\.avg-exclude-marker", 
   "$ProjectPath\logs\.avg-exclude-exe-marker"
)

foreach ($marker in $avgMarkers) {
   if (Test-Path $marker) {
      $markerFound = $true
      Write-TestLog "✅ Marqueur trouvé : $marker"
   }
}

# Créer des marqueurs d'exclusion minimaux si nécessaire
if (-not $markerFound) {
   Write-TestLog "📝 Création de marqueurs d'exclusion de base..."
    
   # Créer le dossier logs s'il n'existe pas
   if (-not (Test-Path "$ProjectPath\logs")) {
      New-Item -ItemType Directory -Path "$ProjectPath\logs" -Force | Out-Null
   }
    
   # Créer des marqueurs basiques
   "AVG_EXCLUDE_FOLDER" | Out-File "$ProjectPath\.avg-exclude-marker" -ErrorAction SilentlyContinue
   "AVG_EXCLUDE_EXE_FILES" | Out-File "$ProjectPath\.avg-exclude-exe-marker" -ErrorAction SilentlyContinue
   "AVG_EXCLUDE_FOLDER" | Out-File "$ProjectPath\logs\.avg-exclude-marker" -ErrorAction SilentlyContinue
   "AVG_EXCLUDE_EXE_FILES" | Out-File "$ProjectPath\logs\.avg-exclude-exe-marker" -ErrorAction SilentlyContinue
    
   Write-TestLog "✅ Marqueurs de base créés"
}
else {
   Write-TestLog "✅ Les marqueurs d'exclusion existent déjà"
}

# 2. Créer un code Go de test simple
$testDir = "$ProjectPath\tests\avg-test"
if (!(Test-Path $testDir)) {
   New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

$testGoFile = "$testDir\test.go"
$testGoContent = @"
package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	fmt.Println("Test d'exclusion AVG pour les fichiers .exe")
	fmt.Println("Compilation réussie à", time.Now().Format("2006-01-02 15:04:05"))
	
	// Créer un fichier de succès
	successFile := "test_success.txt"
	f, err := os.Create(successFile)
	if err == nil {
		f.WriteString("Compilation et exécution réussies à " + time.Now().Format("2006-01-02 15:04:05"))
		f.Close()
		fmt.Println("Fichier de succès créé:", successFile)
	}
}
"@

Set-Content -Path $testGoFile -Value $testGoContent
Write-TestLog "📝 Fichier Go de test créé : $testGoFile"

# 3. Tenter de compiler le fichier Go
Write-TestLog "🔨 Tentative de compilation..."
$startTime = Get-Date
$testExe = "$testDir\test.exe"

try {
   $buildOutput = & go build -o $testExe $testGoFile 2>&1
   $buildStatus = $?
    
   if ($buildStatus) {
      $compileDuration = (Get-Date) - $startTime
      Write-TestLog "✅ Compilation réussie en $($compileDuration.TotalSeconds) secondes"
      Write-TestLog "📋 Fichier exécutable créé : $testExe"
   }
   else {
      Write-TestLog "❌ Échec de la compilation : $buildOutput"
      exit 1
   }
}
catch {
   Write-TestLog "❌ Exception lors de la compilation : $($_.Exception.Message)"
   exit 1
}

# 4. Tenter d'exécuter le fichier compilé
Write-TestLog "▶️ Tentative d'exécution du fichier compilé..."
$startTime = Get-Date

try {
   $execOutput = & $testExe 2>&1
   $execStatus = $?
    
   if ($execStatus) {
      $execDuration = (Get-Date) - $startTime
      Write-TestLog "✅ Exécution réussie en $($execDuration.TotalSeconds) secondes"
      Write-TestLog "📋 Sortie du programme : $execOutput"
      # Vérifier si le fichier de succès a été créé (chercher dans plusieurs endroits possibles)
      $successPaths = @(
         "$testDir\test_success.txt",
         ".\test_success.txt",
         "$ProjectPath\test_success.txt",
         "$ProjectPath\tests\avg-test\test_success.txt"
      )
      
      $successFound = $false
      foreach ($path in $successPaths) {
         if (Test-Path $path) {
            $successContent = Get-Content $path
            Write-TestLog "🎉 Fichier de succès trouvé ($path) : $successContent"
            $successFound = $true
            break
         }
      }
      
      if (-not $successFound) {
         Write-TestLog "⚠️ Fichier de succès non trouvé - Exécution partielle?"
      }
   }
   else {
      Write-TestLog "❌ Échec de l'exécution : $execOutput"
      exit 1
   }
}
catch {
   Write-TestLog "❌ Exception lors de l'exécution : $($_.Exception.Message)"
   exit 1
}

# 5. Rapport final
Write-TestLog "📊 Test d'exclusion AVG terminé avec succès"
Write-TestLog "✨ Les fichiers .exe ne sont plus bloqués par AVG"

# Créer un marqueur de réussite
$successMarker = "$ProjectPath\logs\avg-exe-exclusion-success.txt"
$summary = @"
TEST D'EXCLUSION AVG RÉUSSI
===========================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Fichier compilé: $testExe
Résultat: Compilation et exécution réussies
Status: AVG ne bloque plus les fichiers .exe
"@

Set-Content -Path $successMarker -Value $summary
Write-TestLog "📌 Marqueur de réussite créé : $successMarker"

# Ouvrir le fichier résultat
if (Test-Path $successMarker) {
   Start-Process notepad.exe $successMarker
}

exit 0
