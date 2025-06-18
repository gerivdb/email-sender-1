# =============================================================================
# ERROR RESOLUTION AUTOMATION SCRIPT V1
# Basé sur l'analyse getErrors du projet EMAIL_SENDER_1
# =============================================================================

param(
   [Parameter(Mandatory = $false)]
   [ValidateSet("analyze", "fix-main", "fix-imports", "fix-local", "all")]
   [string]$Action = "analyze",
    
   [Parameter(Mandatory = $false)]
   [switch]$DryRun = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$Verbose = $false
)

# Configuration
$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$ContextualManagerPath = "$ProjectRoot\development\managers\contextual-memory-manager"
$LogFile = "$ProjectRoot\error-resolution-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Fonctions utilitaires
function Write-Log {
   param([string]$Message, [string]$Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
   Write-Host $logEntry
   Add-Content -Path $LogFile -Value $logEntry
}

function Test-GoErrors {
   param([string]$FilePath)
   try {
      $result = go build -o /dev/null $FilePath 2>&1
      return $LASTEXITCODE -ne 0
   }
   catch {
      return $true
   }
}

# =============================================================================
# PHASE 1: ANALYSE DES ERREURS ACTUELLES
# =============================================================================

function Invoke-ErrorAnalysis {
   Write-Log "=== DÉMARRAGE ANALYSE DES ERREURS ===" "HEADER"
    
   $errorFiles = @(
      "$ContextualManagerPath\test_cli.go",
      "$ContextualManagerPath\simple_test.go", 
      "$ContextualManagerPath\minimal_cli.go",
      "$ContextualManagerPath\demo.go",
      "$ContextualManagerPath\development\contextual_memory_manager.go",
      "$ContextualManagerPath\interfaces\contextual_memory.go"
   )
    
   $errorCount = 0
   $mainDuplicates = @()
   $brokenImports = @()
   $localImports = @()
    
   foreach ($file in $errorFiles) {
      if (Test-Path $file) {
         Write-Log "Analyse de: $file"
            
         $content = Get-Content $file -Raw
            
         # Détection des fonctions main dupliquées
         if ($content -match "func main\(\)") {
            $mainDuplicates += $file
            Write-Log "✗ Fonction main() détectée dans: $file" "ERROR"
         }
            
         # Détection des imports cassés github.com/email-sender
         if ($content -match 'github\.com/email-sender/') {
            $brokenImports += $file
            Write-Log "✗ Import github.com/email-sender/* détecté dans: $file" "ERROR"
         }
            
         # Détection des imports locaux
         if ($content -match '"\.\/') {
            $localImports += $file
            Write-Log "✗ Import local './' détecté dans: $file" "ERROR"
         }
      }
   }
    
   # Rapport de synthèse
   Write-Log "=== SYNTHÈSE D'ANALYSE ===" "HEADER"
   Write-Log "Fichiers avec main() dupliquées: $($mainDuplicates.Count)"
   Write-Log "Fichiers avec imports cassés: $($brokenImports.Count)" 
   Write-Log "Fichiers avec imports locaux: $($localImports.Count)"
    
   return @{
      MainDuplicates = $mainDuplicates
      BrokenImports  = $brokenImports
      LocalImports   = $localImports
   }
}

# =============================================================================
# PHASE 2: RÉSOLUTION DES FONCTIONS MAIN DUPLIQUÉES  
# =============================================================================

function Resolve-MainDuplicates {
   param([array]$MainFiles)
    
   Write-Log "=== RÉSOLUTION DES FONCTIONS MAIN ===" "HEADER"
    
   if ($DryRun) {
      Write-Log "MODE DRY-RUN: Simulation des changements" "WARNING"
   }
    
   foreach ($file in $MainFiles) {
      $fileName = Split-Path $file -Leaf
      $baseName = $fileName -replace '\.go$', ''
        
      # Créer le sous-répertoire cmd/
      $cmdDir = "$ContextualManagerPath\cmd\$baseName"
        
      if (-not $DryRun) {
         if (-not (Test-Path $cmdDir)) {
            New-Item -Path $cmdDir -ItemType Directory -Force
            Write-Log "✓ Créé répertoire: $cmdDir" "SUCCESS"
         }
            
         # Déplacer le fichier vers cmd/baseName/main.go
         $newPath = "$cmdDir\main.go"
         Move-Item -Path $file -Destination $newPath -Force
         Write-Log "✓ Déplacé $file → $newPath" "SUCCESS"
            
         # Mettre à jour le package dans le fichier
         $content = Get-Content $newPath -Raw
         $content = $content -replace '^package.*', 'package main'
         Set-Content -Path $newPath -Value $content
         Write-Log "✓ Package mis à jour dans: $newPath" "SUCCESS"
      }
      else {
         Write-Log "SIMULATION: Déplacerait $file → $cmdDir\main.go" "INFO"
      }
   }
}

# =============================================================================
# PHASE 3: RÉSOLUTION DES IMPORTS CASSÉS
# =============================================================================

function Resolve-BrokenImports {
   param([array]$ImportFiles)
    
   Write-Log "=== RÉSOLUTION DES IMPORTS CASSÉS ===" "HEADER"
    
   foreach ($file in $ImportFiles) {
      Write-Log "Traitement des imports dans: $file"
        
      if (-not $DryRun) {
         $content = Get-Content $file -Raw
            
         # Remplacer les imports github.com/email-sender par des chemins relatifs
         $content = $content -replace 'github\.com/email-sender/development/managers/contextual-memory-manager/', '../'
            
         Set-Content -Path $file -Value $content
         Write-Log "✓ Imports corrigés dans: $file" "SUCCESS"
      }
      else {
         Write-Log "SIMULATION: Corrigerait les imports dans: $file" "INFO"
      }
   }
}

# =============================================================================
# PHASE 4: RÉSOLUTION DES IMPORTS LOCAUX
# =============================================================================

function Resolve-LocalImports {
   param([array]$LocalFiles)
    
   Write-Log "=== RÉSOLUTION DES IMPORTS LOCAUX ===" "HEADER"
    
   foreach ($file in $LocalFiles) {
      Write-Log "Traitement des imports locaux dans: $file"
        
      if (-not $DryRun) {
         $content = Get-Content $file -Raw
            
         # Remplacer ./interfaces par le chemin relatif approprié
         $content = $content -replace '"\.\/interfaces"', '"../interfaces"'
            
         Set-Content -Path $file -Value $content
         Write-Log "✓ Imports locaux corrigés dans: $file" "SUCCESS"
      }
      else {
         Write-Log "SIMULATION: Corrigerait les imports locaux dans: $file" "INFO"
      }
   }
}

# =============================================================================
# PHASE 5: VALIDATION POST-RÉSOLUTION
# =============================================================================

function Invoke-PostResolutionValidation {
   Write-Log "=== VALIDATION POST-RÉSOLUTION ===" "HEADER"
    
   # Test de compilation du module
   Push-Location $ContextualManagerPath
   try {
      $buildResult = go build ./... 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-Log "✓ Compilation réussie du module contextual-memory-manager" "SUCCESS"
      }
      else {
         Write-Log "✗ Erreurs de compilation détectées:" "ERROR"
         Write-Log $buildResult "ERROR"
      }
   }
   finally {
      Pop-Location
   }
}

# =============================================================================
# POINT D'ENTRÉE PRINCIPAL
# =============================================================================

function Main {
   Write-Log "=== DÉMARRAGE ERROR RESOLUTION AUTOMATION V1 ===" "HEADER"
   Write-Log "Action: $Action | DryRun: $DryRun | Verbose: $Verbose"
   Write-Log "Projet: $ProjectRoot"
   Write-Log "Log: $LogFile"
    
   switch ($Action) {
      "analyze" {
         $analysis = Invoke-ErrorAnalysis
      }
      "fix-main" {
         $analysis = Invoke-ErrorAnalysis
         Resolve-MainDuplicates -MainFiles $analysis.MainDuplicates
      }
      "fix-imports" {
         $analysis = Invoke-ErrorAnalysis
         Resolve-BrokenImports -ImportFiles $analysis.BrokenImports
      }
      "fix-local" {
         $analysis = Invoke-ErrorAnalysis
         Resolve-LocalImports -LocalFiles $analysis.LocalImports
      }
      "all" {
         $analysis = Invoke-ErrorAnalysis
         Resolve-MainDuplicates -MainFiles $analysis.MainDuplicates
         Resolve-BrokenImports -ImportFiles $analysis.BrokenImports
         Resolve-LocalImports -LocalFiles $analysis.LocalImports
         Invoke-PostResolutionValidation
      }
   }
    
   Write-Log "=== EXÉCUTION TERMINÉE ===" "HEADER"
   Write-Log "Log complet disponible: $LogFile"
}

# Exécution
Main
