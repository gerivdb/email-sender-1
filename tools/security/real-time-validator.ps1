# Real-Time Validation System - Plan Dev v41
# Phase 1.1.1.2 - Système de validation en temps réel
# Version: 1.0
# Date: 2025-06-03

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OperationLogPath,
    
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    
    [switch]$ContinuousMonitoring,
    
    [int]$MonitoringIntervalSeconds = 30,
    
    [string]$AlertThreshold = "Medium"
)

# Configuration de validation en temps réel
$ValidationRules = @{
    FileIntegrity = @{
        RequiredFiles = @('.gitignore', 'package.json', 'go.mod', 'README.md')
        ForbiddenPatterns = @('*.tmp', '*.log', 'temp*', 'debug*')
        MaxFileSize = 50MB
        ChecksumValidation = $true
    }
    
    DirectoryStructure = @{
        ProtectedDirectories = @('.git', '.github', '.vscode', 'tools', 'projet')
        RequiredDirectories = @('src', 'cmd', 'internal')
        MaxDepth = 10
    }
    
    SecurityCompliance = @{
        NoExecutablesInRoot = $true
        NoSecretsInPlainText = $true
        RequireSecurePatterns = $true
        EnforceGitignore = $true
    }
    
    PerformanceMetrics = @{
        MaxProcessingTime = 300  # 5 minutes
        MaxMemoryUsage = 1GB
        MinDiskSpace = 5GB
    }
}

function Initialize-RealTimeValidator {
    [CmdletBinding()]
    param()
    
    Write-Information "🔄 INITIALISATION DU SYSTÈME DE VALIDATION TEMPS RÉEL"
    Write-Information "Plan Dev v41 - Phase 1.1.1.2 - Validation System v1.0"
    
    # Vérification des prérequis
    if (-not (Test-Path $ProjectRoot)) {
        throw "Racine du projet introuvable: $ProjectRoot"
    }
    
    # Création du répertoire de validation
    $validationDir = Join-Path $ProjectRoot "projet\security\validation"
    if (-not (Test-Path $validationDir)) {
        New-Item -ItemType Directory -Path $validationDir -Force | Out-Null
        Write-Information "📁 Répertoire de validation créé: $validationDir"
    }
    
    return @{
        ValidationDirectory = $validationDir
        StartTime = Get-Date
        SessionId = [System.Guid]::NewGuid().ToString().Substring(0,8)
        Rules = $ValidationRules
    }
}

function Test-FileIntegrity {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [hashtable]$Rules
    )
    
    Write-Verbose "🔍 Vérification de l'intégrité des fichiers..."
    
    $results = @{
        Status = "Valid"
        Issues = @()
        Details = @()
    }
    
    # Vérification des fichiers requis
    foreach ($requiredFile in $Rules.FileIntegrity.RequiredFiles) {
        $filePath = Join-Path $ProjectRoot $requiredFile
        if (-not (Test-Path $filePath)) {
            $results.Issues += "Fichier requis manquant: $requiredFile"
            $results.Status = "Invalid"
        }
        else {
            $results.Details += "✅ Fichier requis présent: $requiredFile"
        }
    }
    
    # Vérification des patterns interdits
    foreach ($pattern in $Rules.FileIntegrity.ForbiddenPatterns) {
        $forbiddenFiles = Get-ChildItem -Path $ProjectRoot -Filter $pattern -File -ErrorAction SilentlyContinue
        if ($forbiddenFiles) {
            foreach ($file in $forbiddenFiles) {
                $results.Issues += "Fichier interdit détecté: $($file.Name)"
                $results.Status = "Invalid"
            }
        }
    }
    
    # Vérification de la taille des fichiers
    $largeFiles = Get-ChildItem -Path $ProjectRoot -File | Where-Object { $_.Length -gt $Rules.FileIntegrity.MaxFileSize }
    foreach ($file in $largeFiles) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        $results.Issues += "Fichier trop volumineux: $($file.Name) (${sizeMB}MB)"
        $results.Status = "Warning"
    }
    
    return $results
}

function Test-DirectoryStructure {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [hashtable]$Rules
    )
    
    Write-Verbose "📁 Vérification de la structure des répertoires..."
    
    $results = @{
        Status = "Valid"
        Issues = @()
        Details = @()
    }
    
    # Vérification des répertoires protégés
    foreach ($protectedDir in $Rules.DirectoryStructure.ProtectedDirectories) {
        $dirPath = Join-Path $ProjectRoot $protectedDir
        if (Test-Path $dirPath) {
            $results.Details += "🛡️  Répertoire protégé intact: $protectedDir"
        }
        else {
            $results.Issues += "Répertoire protégé manquant: $protectedDir"
            $results.Status = "Warning"
        }
    }
    
    # Vérification des répertoires requis
    foreach ($requiredDir in $Rules.DirectoryStructure.RequiredDirectories) {
        $dirPath = Join-Path $ProjectRoot $requiredDir
        if (-not (Test-Path $dirPath)) {
            $results.Issues += "Répertoire requis manquant: $requiredDir"
            $results.Status = "Invalid"
        }
        else {
            $results.Details += "✅ Répertoire requis présent: $requiredDir"
        }
    }
    
    # Vérification de la profondeur maximale
    try {
        $deepPaths = Get-ChildItem -Path $ProjectRoot -Recurse -Directory -ErrorAction SilentlyContinue | 
                     Where-Object { ($_.FullName -replace [regex]::Escape($ProjectRoot)).Split([IO.Path]::DirectorySeparatorChar).Count -gt $Rules.DirectoryStructure.MaxDepth }
        
        foreach ($deepPath in $deepPaths) {
            $depth = ($deepPath.FullName -replace [regex]::Escape($ProjectRoot)).Split([IO.Path]::DirectorySeparatorChar).Count
            $results.Issues += "Répertoire trop profond: $($deepPath.Name) (profondeur: $depth)"
            $results.Status = "Warning"
        }
    }
    catch {
        $results.Issues += "Erreur lors de la vérification de profondeur: $_"
        $results.Status = "Warning"
    }
    
    return $results
}

function Test-SecurityCompliance {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [hashtable]$Rules
    )
    
    Write-Verbose "🔒 Vérification de la conformité sécuritaire..."
    
    $results = @{
        Status = "Valid"
        Issues = @()
        Details = @()
    }
    
    # Vérification: pas d'exécutables dans la racine
    if ($Rules.SecurityCompliance.NoExecutablesInRoot) {
        $executables = Get-ChildItem -Path $ProjectRoot -Filter "*.exe" -File
        foreach ($exe in $executables) {
            $results.Issues += "Exécutable détecté dans la racine: $($exe.Name)"
            $results.Status = "Warning"
        }
        
        if ($executables.Count -eq 0) {
            $results.Details += "✅ Aucun exécutable dans la racine"
        }
    }
    
    # Vérification: pas de secrets en texte clair
    if ($Rules.SecurityCompliance.NoSecretsInPlainText) {
        $secretPatterns = @("password", "secret", "token", "key", "api", "auth")
        $textFiles = Get-ChildItem -Path $ProjectRoot -Include "*.txt", "*.md", "*.json", "*.yaml", "*.yml" -File
        
        foreach ($file in $textFiles) {
            try {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                foreach ($pattern in $secretPatterns) {
                    if ($content -and $content -match $pattern) {
                        $results.Issues += "Potentiel secret détecté dans: $($file.Name)"
                        $results.Status = "Warning"
                        break
                    }
                }
            }
            catch {
                # Ignorer les fichiers non lisibles
            }
        }
    }
    
    # Vérification: .gitignore présent et fonctionnel
    if ($Rules.SecurityCompliance.EnforceGitignore) {
        $gitignorePath = Join-Path $ProjectRoot ".gitignore"
        if (Test-Path $gitignorePath) {
            $results.Details += "✅ .gitignore présent"
            
            # Vérifier si .gitignore contient des règles importantes
            $gitignoreContent = Get-Content $gitignorePath -Raw
            $importantRules = @("*.exe", "*.log", "node_modules", ".env")
            
            foreach ($rule in $importantRules) {
                if ($gitignoreContent -notmatch [regex]::Escape($rule)) {
                    $results.Issues += ".gitignore ne contient pas la règle: $rule"
                    $results.Status = "Warning"
                }
            }
        }
        else {
            $results.Issues += "Fichier .gitignore manquant"
            $results.Status = "Invalid"
        }
    }
    
    return $results
}

function Test-PerformanceMetrics {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [hashtable]$Rules,
        [datetime]$StartTime
    )
    
    Write-Verbose "📊 Vérification des métriques de performance..."
    
    $results = @{
        Status = "Valid"
        Issues = @()
        Details = @()
        Metrics = @{}
    }
    
    # Temps de traitement
    $elapsedTime = (Get-Date) - $StartTime
    $results.Metrics.ProcessingTime = $elapsedTime.TotalSeconds
    
    if ($elapsedTime.TotalSeconds -gt $Rules.PerformanceMetrics.MaxProcessingTime) {
        $results.Issues += "Temps de traitement excessif: $([math]::Round($elapsedTime.TotalSeconds))s"
        $results.Status = "Warning"
    }
    else {
        $results.Details += "✅ Temps de traitement acceptable: $([math]::Round($elapsedTime.TotalSeconds))s"
    }
    
    # Utilisation mémoire
    try {
        $process = Get-Process -Id $PID
        $memoryUsage = $process.WorkingSet64
        $results.Metrics.MemoryUsage = $memoryUsage
        
        if ($memoryUsage -gt $Rules.PerformanceMetrics.MaxMemoryUsage) {
            $memoryMB = [math]::Round($memoryUsage / 1MB, 2)
            $results.Issues += "Utilisation mémoire élevée: ${memoryMB}MB"
            $results.Status = "Warning"
        }
        else {
            $memoryMB = [math]::Round($memoryUsage / 1MB, 2)
            $results.Details += "✅ Utilisation mémoire normale: ${memoryMB}MB"
        }
    }
    catch {
        $results.Issues += "Impossible de mesurer l'utilisation mémoire: $_"
    }
    
    # Espace disque disponible
    try {
        $drive = (Get-Item $ProjectRoot).PSDrive
        $freeSpace = $drive.Free
        $results.Metrics.FreeSpace = $freeSpace
        
        if ($freeSpace -lt $Rules.PerformanceMetrics.MinDiskSpace) {
            $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
            $results.Issues += "Espace disque insuffisant: ${freeSpaceGB}GB"
            $results.Status = "Invalid"
        }
        else {
            $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
            $results.Details += "✅ Espace disque suffisant: ${freeSpaceGB}GB"
        }
    }
    catch {
        $results.Issues += "Impossible de vérifier l'espace disque: $_"
    }
    
    return $results
}

function Invoke-ComprehensiveValidation {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [hashtable]$ValidationContext
    )
    
    Write-Information "🔍 VALIDATION COMPLÈTE EN COURS..."
    
    $validationReport = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SessionId = $ValidationContext.SessionId
        OverallStatus = "Valid"
        Categories = @{}
        Summary = @{
            TotalIssues = 0
            CriticalIssues = 0
            WarningIssues = 0
            PassedChecks = 0
        }
    }
    
    # Test 1: Intégrité des fichiers
    Write-Information "🔍 Test d'intégrité des fichiers..."
    $fileIntegrityResults = Test-FileIntegrity -ProjectRoot $ProjectRoot -Rules $ValidationContext.Rules
    $validationReport.Categories.FileIntegrity = $fileIntegrityResults
    
    # Test 2: Structure des répertoires
    Write-Information "🔍 Test de structure des répertoires..."
    $directoryResults = Test-DirectoryStructure -ProjectRoot $ProjectRoot -Rules $ValidationContext.Rules
    $validationReport.Categories.DirectoryStructure = $directoryResults
    
    # Test 3: Conformité sécuritaire
    Write-Information "🔍 Test de conformité sécuritaire..."
    $securityResults = Test-SecurityCompliance -ProjectRoot $ProjectRoot -Rules $ValidationContext.Rules
    $validationReport.Categories.SecurityCompliance = $securityResults
    
    # Test 4: Métriques de performance
    Write-Information "🔍 Test des métriques de performance..."
    $performanceResults = Test-PerformanceMetrics -ProjectRoot $ProjectRoot -Rules $ValidationContext.Rules -StartTime $ValidationContext.StartTime
    $validationReport.Categories.PerformanceMetrics = $performanceResults
    
    # Calcul du statut global
    $allCategories = @($fileIntegrityResults, $directoryResults, $securityResults, $performanceResults)
    $invalidCount = ($allCategories | Where-Object { $_.Status -eq "Invalid" }).Count
    $warningCount = ($allCategories | Where-Object { $_.Status -eq "Warning" }).Count
    
    if ($invalidCount -gt 0) {
        $validationReport.OverallStatus = "Invalid"
    }
    elseif ($warningCount -gt 0) {
        $validationReport.OverallStatus = "Warning"
    }
    
    # Calcul du résumé
    foreach ($category in $allCategories) {
        $validationReport.Summary.TotalIssues += $category.Issues.Count
        if ($category.Status -eq "Invalid") {
            $validationReport.Summary.CriticalIssues += $category.Issues.Count
        }
        elseif ($category.Status -eq "Warning") {
            $validationReport.Summary.WarningIssues += $category.Issues.Count
        }
        $validationReport.Summary.PassedChecks += $category.Details.Count
    }
    
    return $validationReport
}

function Show-ValidationReport {
    [CmdletBinding()]
    param(
        [hashtable]$Report
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                      RAPPORT DE VALIDATION TEMPS RÉEL                         ║" -ForegroundColor Green
    Write-Host "╠════════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║ Plan Dev v41 - Phase 1.1.1.2 - Real-Time Validation System v1.0              ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # Statut global
    $statusColor = switch ($Report.OverallStatus) {
        "Valid" { "Green" }
        "Warning" { "Yellow" }
        "Invalid" { "Red" }
        default { "White" }
    }
    
    Write-Host "`n🎯 STATUT GLOBAL: $($Report.OverallStatus.ToUpper())" -ForegroundColor $statusColor
    Write-Host "📅 Horodatage: $($Report.Timestamp)" -ForegroundColor White
    Write-Host "🔒 Session: $($Report.SessionId)" -ForegroundColor White
    
    # Résumé
    Write-Host "`n📊 RÉSUMÉ:" -ForegroundColor Cyan
    Write-Host "   ✅ Vérifications réussies: $($Report.Summary.PassedChecks)" -ForegroundColor Green
    Write-Host "   ⚠️  Avertissements: $($Report.Summary.WarningIssues)" -ForegroundColor Yellow
    Write-Host "   ❌ Problèmes critiques: $($Report.Summary.CriticalIssues)" -ForegroundColor Red
    Write-Host "   📋 Total des problèmes: $($Report.Summary.TotalIssues)" -ForegroundColor White
    
    # Détails par catégorie
    foreach ($categoryName in $Report.Categories.Keys) {
        $category = $Report.Categories[$categoryName]
        
        Write-Host "`n📂 CATÉGORIE: $categoryName" -ForegroundColor Cyan
        $categoryColor = switch ($category.Status) {
            "Valid" { "Green" }
            "Warning" { "Yellow" }
            "Invalid" { "Red" }
            default { "White" }
        }
        Write-Host "   📊 Statut: $($category.Status)" -ForegroundColor $categoryColor
        
        if ($category.Details.Count -gt 0) {
            Write-Host "   ✅ Détails positifs:" -ForegroundColor Green
            $category.Details | ForEach-Object { Write-Host "      $_" -ForegroundColor Green }
        }
        
        if ($category.Issues.Count -gt 0) {
            Write-Host "   ⚠️  Problèmes détectés:" -ForegroundColor Yellow
            $category.Issues | ForEach-Object { Write-Host "      $_" -ForegroundColor Yellow }
        }
        
        # Métriques spéciales pour la performance
        if ($categoryName -eq "PerformanceMetrics" -and $category.Metrics) {
            Write-Host "   📊 Métriques:" -ForegroundColor White
            if ($category.Metrics.ProcessingTime) {
                Write-Host "      ⏱️  Temps de traitement: $([math]::Round($category.Metrics.ProcessingTime, 2))s" -ForegroundColor White
            }
            if ($category.Metrics.MemoryUsage) {
                $memoryMB = [math]::Round($category.Metrics.MemoryUsage / 1MB, 2)
                Write-Host "      🧠 Utilisation mémoire: ${memoryMB}MB" -ForegroundColor White
            }
            if ($category.Metrics.FreeSpace) {
                $freeSpaceGB = [math]::Round($category.Metrics.FreeSpace / 1GB, 2)
                Write-Host "      💾 Espace disque libre: ${freeSpaceGB}GB" -ForegroundColor White
            }
        }
    }
}

function Save-ValidationReport {
    [CmdletBinding()]
    param(
        [hashtable]$Report,
        [string]$ValidationDirectory
    )
    
    $reportFileName = "validation-report_$($Report.SessionId)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $reportPath = Join-Path $ValidationDirectory $reportFileName
    
    try {
        $Report | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
        Write-Information "💾 Rapport de validation sauvegardé: $reportPath"
        return $reportPath
    }
    catch {
        Write-Warning "⚠️  Impossible de sauvegarder le rapport: $_"
        return $null
    }
}

# ===== FONCTION PRINCIPALE =====

function Start-RealTimeValidation {
    [CmdletBinding()]
    param()
    
    try {
        # Initialisation
        $validationContext = Initialize-RealTimeValidator
        Write-Information "🚀 Système de validation initialisé - Session: $($validationContext.SessionId)"
        
        # Validation complète
        $validationReport = Invoke-ComprehensiveValidation -ProjectRoot $ProjectRoot -ValidationContext $validationContext
        
        # Affichage du rapport
        Show-ValidationReport -Report $validationReport
        
        # Sauvegarde du rapport
        $reportPath = Save-ValidationReport -Report $validationReport -ValidationDirectory $validationContext.ValidationDirectory
        
        # Retour du code d'erreur approprié
        $exitCode = switch ($validationReport.OverallStatus) {
            "Valid" { 0 }
            "Warning" { 1 }
            "Invalid" { 2 }
            default { 3 }
        }
        
        Write-Information "✅ Validation complétée avec le code de sortie: $exitCode"
        return $exitCode
        
    }
    catch {
        Write-Error "💥 ERREUR CRITIQUE lors de la validation: $_"
        return 99
    }
}

# ===== POINT D'ENTRÉE =====

# Configuration globale
$ErrorActionPreference = "Continue"
$InformationPreference = "Continue"

# Affichage de l'en-tête
Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                     REAL-TIME VALIDATION SYSTEM v1.0                          ║" -ForegroundColor Green
Write-Host "║                       Plan Dev v41 - Phase 1.1.1.2                           ║" -ForegroundColor Green
Write-Host "║                     Système de Validation Temps Réel                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

# Exécution du système de validation
exit (Start-RealTimeValidation)
