# Script de test du Error Resolution Pipeline
# Teste le pipeline sur les erreurs existantes du projet EMAIL_SENDER_1

param(
    [string]$TargetPath = "../../.github/docs/algorithms",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false,
    [string]$OutputDir = "./test-results"
)

$ErrorActionPreference = "Stop"

Write-Host "=== ERROR RESOLUTION PIPELINE - TEST SCRIPT ===" -ForegroundColor Cyan
Write-Host "Version: 1.0.0" -ForegroundColor Green
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green

# Vérifier que nous sommes dans le bon répertoire
$currentDir = Get-Location
if (-not (Test-Path "go.mod")) {
    Write-Error "Ce script doit être exécuté depuis le répertoire error-resolution-pipeline"
}

# Créer le répertoire de sortie
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "✓ Répertoire de sortie créé: $OutputDir" -ForegroundColor Green
}

# Vérifier les dépendances Go
Write-Host "`n=== VÉRIFICATION DES DÉPENDANCES ===" -ForegroundColor Yellow

try {
    Write-Host "Téléchargement des dépendances Go..." -ForegroundColor White
    go mod download
    Write-Host "✓ Dépendances Go téléchargées" -ForegroundColor Green
} catch {
    Write-Error "Échec du téléchargement des dépendances Go: $_"
}

# Compiler le pipeline
Write-Host "`n=== COMPILATION DU PIPELINE ===" -ForegroundColor Yellow

try {
    Write-Host "Compilation en cours..." -ForegroundColor White
    go build -o pipeline.exe ./cmd/pipeline
    Write-Host "✓ Pipeline compilé avec succès" -ForegroundColor Green
} catch {
    Write-Error "Échec de la compilation: $_"
}

# Préparer la configuration de test
$configTest = @{
    target_path = $TargetPath
    error_reports = @("../../2025-05-28-errors.md")
    output_dir = $OutputDir
    metrics_port = 9091
    enable_metrics = $true
    processing_mode = "comprehensive"
    detector = @{
        max_file_size = "10MB"
        timeout = "30s"
        parallel_processing = $true
        max_goroutines = 5
    }
    resolver = @{
        safe_fixes_only = $true
        backup_before_fix = $true
        max_mutations_per_file = 3
        dry_run = $DryRun.IsPresent
    }
} | ConvertTo-Json -Depth 10

$configPath = Join-Path $OutputDir "test_config.json"
$configTest | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "✓ Configuration de test créée: $configPath" -ForegroundColor Green

# Exécuter le pipeline
Write-Host "`n=== EXÉCUTION DU PIPELINE ===" -ForegroundColor Yellow

$arguments = @(
    "-config", $configPath
    "-target", $TargetPath
)

if ($DryRun) {
    $arguments += "-dry-run"
    Write-Host "Mode DRY-RUN activé - aucune modification ne sera appliquée" -ForegroundColor Yellow
}

if ($Verbose) {
    $arguments += "-verbose"
}

Write-Host "Commande: ./pipeline.exe $($arguments -join ' ')" -ForegroundColor White

try {
    $startTime = Get-Date
    
    # Démarrer le serveur de métriques en arrière-plan
    Write-Host "Démarrage du serveur de métriques sur le port 9091..." -ForegroundColor White
    
    # Exécuter le pipeline
    Write-Host "Lancement de l'analyse..." -ForegroundColor White
    & "./pipeline.exe" @arguments
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "✓ Pipeline exécuté avec succès en $($duration.TotalSeconds.ToString('F2')) secondes" -ForegroundColor Green
    
} catch {
    Write-Error "Échec de l'exécution du pipeline: $_"
}

# Analyser les résultats
Write-Host "`n=== ANALYSE DES RÉSULTATS ===" -ForegroundColor Yellow

$resultFiles = Get-ChildItem -Path $OutputDir -Filter "pipeline_results_*.json" | Sort-Object LastWriteTime -Descending

if ($resultFiles.Count -gt 0) {
    $latestResult = $resultFiles[0]
    Write-Host "Fichier de résultats le plus récent: $($latestResult.Name)" -ForegroundColor White
    
    try {
        $results = Get-Content $latestResult.FullName | ConvertFrom-Json
        
        Write-Host "`n--- RÉSUMÉ DÉTAILLÉ ---" -ForegroundColor Cyan
        Write-Host "Fichiers traités: $($results.files_processed)" -ForegroundColor White
        Write-Host "Erreurs détectées: $($results.summary.total_errors)" -ForegroundColor White
        Write-Host "Erreurs corrigées: $($results.summary.errors_fixed)" -ForegroundColor White
        Write-Host "Taux de succès: $($results.summary.fix_success_rate.ToString('F1'))%" -ForegroundColor White
        Write-Host "Confiance moyenne: $($results.summary.average_confidence.ToString('F1'))%" -ForegroundColor White
        Write-Host "Issues critiques: $($results.summary.critical_issues)" -ForegroundColor Red
        Write-Host "Révision manuelle requise: $($results.summary.manual_review_required)" -ForegroundColor Yellow
        
        if ($results.errors_detected.Count -gt 0) {
            Write-Host "`n--- DÉTAIL DES ERREURS DÉTECTÉES ---" -ForegroundColor Cyan
            $errorGroups = $results.errors_detected | Group-Object type
            foreach ($group in $errorGroups) {
                Write-Host "$($group.Name): $($group.Count) erreur(s)" -ForegroundColor White
            }
        }
        
        if ($results.fixes_applied.Count -gt 0) {
            Write-Host "`n--- FIXES APPLIQUÉS ---" -ForegroundColor Cyan
            $appliedFixes = $results.fixes_applied | Where-Object { $_.applied -eq $true }
            Write-Host "Fixes appliqués automatiquement: $($appliedFixes.Count)" -ForegroundColor Green
            
            $highConfidenceFixes = $appliedFixes | Where-Object { $_.confidence -gt 0.9 }
            Write-Host "Fixes haute confiance (>90%): $($highConfidenceFixes.Count)" -ForegroundColor Green
        }
        
    } catch {
        Write-Warning "Impossible d'analyser le fichier de résultats: $_"
    }
} else {
    Write-Warning "Aucun fichier de résultats trouvé dans $OutputDir"
}

# Vérifier les métriques Prometheus
Write-Host "`n=== VÉRIFICATION DES MÉTRIQUES ===" -ForegroundColor Yellow

try {
    $metricsUrl = "http://localhost:9091/metrics"
    Write-Host "Tentative de récupération des métriques depuis $metricsUrl..." -ForegroundColor White
    
    $response = Invoke-WebRequest -Uri $metricsUrl -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        $metricsContent = $response.Content
        $errorMetrics = $metricsContent | Select-String "error_detector_errors_total"
        $fileMetrics = $metricsContent | Select-String "error_detector_files_processed_total"
        
        Write-Host "✓ Métriques Prometheus disponibles" -ForegroundColor Green
        if ($errorMetrics) {
            Write-Host "Métriques d'erreurs: $($errorMetrics.Line)" -ForegroundColor White
        }
        if ($fileMetrics) {
            Write-Host "Métriques de fichiers: $($fileMetrics.Line)" -ForegroundColor White
        }
    }
} catch {
    Write-Warning "Impossible de récupérer les métriques Prometheus: $_"
}

# Recommandations finales
Write-Host "`n=== RECOMMANDATIONS ===" -ForegroundColor Yellow

Write-Host "1. Consultez les résultats détaillés dans: $OutputDir" -ForegroundColor White
Write-Host "2. Examinez les fixes nécessitant une révision manuelle" -ForegroundColor White
Write-Host "3. Vérifiez les sauvegardes créées avant application des fixes" -ForegroundColor White
Write-Host "4. Surveillez les métriques Prometheus pour le monitoring continu" -ForegroundColor White

if ($DryRun) {
    Write-Host "5. Relancez sans -DryRun pour appliquer les fixes automatiques" -ForegroundColor Yellow
}

Write-Host "`n=== TEST TERMINÉ ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green

# Nettoyer le processus en arrière-plan si nécessaire
try {
    Get-Process -Name "pipeline" -ErrorAction SilentlyContinue | Stop-Process -Force
} catch {
    # Ignore errors
}
