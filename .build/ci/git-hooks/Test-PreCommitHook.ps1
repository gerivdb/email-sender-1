<#
.SYNOPSIS
    Teste le hook pre-commit sur un fichier PowerShell.
.DESCRIPTION
    Ce script teste le hook pre-commit sur un fichier PowerShell spécifié.
    Il simule l'exécution du hook pre-commit sans effectuer de commit réel.
.PARAMETER FilePath
    Chemin du fichier PowerShell à tester.
.EXAMPLE
    .\Test-PreCommitHook.ps1 -FilePath ".\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter()]
    [switch]$IgnoreWarnings,

    [Parameter()]
    [switch]$IgnoreErrors
)

# Vérifier si le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Fichier non trouvé: $FilePath"
    exit 1
}

# Obtenir le chemin absolu du fichier
$absolutePath = Resolve-Path -Path $FilePath

# Obtenir le chemin du dépôt Git
$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    Write-Error "Ce script doit être exécuté dans un dépôt Git."
    exit 1
}

# Obtenir le chemin relatif du fichier par rapport au dépôt Git
$relativePath = $absolutePath.Path.Replace("$repoRoot\", "").Replace("\", "/")

Write-Host "Test du hook pre-commit sur le fichier: $relativePath" -ForegroundColor Cyan

# Importer le module d'analyse des patterns d'erreurs
$modulePath = Join-Path -Path $repoRoot -ChildPath "scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ErrorPatternAnalyzer non trouvé: $modulePath"
    exit 1
}

# Charger la configuration
$configPath = Join-Path -Path $repoRoot -ChildPath "git-hooks\config\pre-commit-config.json"
$config = @{
    IgnorePatterns = @()
    SeverityLevel  = "Warning"
    MaxErrors      = 10
    ExcludePaths   = @(
        "node_modules",
        "vendor",
        "dist",
        "out"
    )
}

if (Test-Path -Path $configPath) {
    try {
        $configJson = Get-Content -Path $configPath -Raw | ConvertFrom-Json

        if ($configJson.IgnorePatterns) {
            $config.IgnorePatterns = $configJson.IgnorePatterns
        }

        if ($configJson.SeverityLevel) {
            $config.SeverityLevel = $configJson.SeverityLevel
        }

        if ($configJson.MaxErrors) {
            $config.MaxErrors = $configJson.MaxErrors
        }

        if ($configJson.ExcludePaths) {
            $config.ExcludePaths = $configJson.ExcludePaths
        }
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration: $_"
        Write-Warning "Utilisation de la configuration par défaut."
    }
}

# Analyser le fichier
Write-Host "Analyse du fichier $FilePath..." -ForegroundColor Yellow

# Obtenir le contenu du fichier
$content = Get-Content -Path $FilePath -Raw

# Analyser le fichier pour détecter les erreurs potentielles
$patterns = Get-ErrorPatterns -ScriptContent $content

if (-not $patterns) {
    Write-Host "  Aucun pattern d'erreur détecté." -ForegroundColor Green
    exit 0
}

# Filtrer les patterns ignorés
$filteredPatterns = $patterns | Where-Object {
    $pattern = $_
    -not ($config.IgnorePatterns | Where-Object { $pattern.Id -like $_ })
}

if (-not $filteredPatterns) {
    Write-Host "  Aucun pattern d'erreur après filtrage." -ForegroundColor Green
    exit 0
}

# Initialiser les compteurs
$errorCount = 0
$warningCount = 0
$errorList = @()

# Afficher les erreurs et avertissements
foreach ($pattern in $filteredPatterns) {
    $severity = $pattern.Severity
    $message = $pattern.Message
    $lineNumber = $pattern.LineNumber
    $id = $pattern.Id

    $errorInfo = [PSCustomObject]@{
        File       = $FilePath
        LineNumber = $lineNumber
        Severity   = $severity
        Message    = $message
        Id         = $id
    }

    $errorList += $errorInfo

    if ($severity -eq "Error") {
        if (-not $IgnoreErrors) {
            Write-Host "  [ERROR] Ligne $lineNumber : $message [$id]" -ForegroundColor Red
            $errorCount++
        }
    } elseif ($severity -eq "Warning") {
        if (-not $IgnoreWarnings) {
            Write-Host "  [WARNING] Ligne $lineNumber : $message [$id]" -ForegroundColor Yellow
            $warningCount++
        }
    }
}

# Générer un rapport
$reportPath = Join-Path -Path $repoRoot -ChildPath "git-hooks\reports\pre-commit-report.md"
$reportDir = Split-Path -Path $reportPath -Parent

if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report = @"
# Rapport d'analyse pre-commit

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- Fichiers analysés: 1
- Erreurs détectées: $errorCount
- Avertissements détectés: $warningCount

## Détails

| Fichier | Ligne | Sévérité | Message | ID |
|---------|-------|----------|---------|-----|
"@

foreach ($errorItem in $errorList) {
    $report += "`n| $($errorItem.File) | $($errorItem.LineNumber) | $($errorItem.Severity) | $($errorItem.Message) | $($errorItem.Id) |"
}

$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nRapport généré: $reportPath" -ForegroundColor Cyan

# Afficher le rapport
Write-Host "`nRapport de test:" -ForegroundColor Cyan
Get-Content -Path $reportPath | ForEach-Object {
    Write-Host $_
}

# Déterminer si le commit doit être bloqué
$blockCommit = $false

if ($errorCount -gt 0 -and -not $IgnoreErrors) {
    if ($errorCount -ge $config.MaxErrors) {
        Write-Host "`nTrop d'erreurs détectées ($errorCount). Commit bloqué." -ForegroundColor Red
        $blockCommit = $true
    } else {
        Write-Host "`nErreurs détectées ($errorCount). Veuillez les corriger avant de committer." -ForegroundColor Red
        $blockCommit = $true
    }
}

if ($blockCommit) {
    exit 1
} else {
    Write-Host "`nAnalyse terminée. Commit autorisé." -ForegroundColor Green
    exit 0
}
$content = Get-Content -Path $FilePath -Raw

# Analyser le fichier pour détecter les erreurs potentielles
$patterns = Get-ErrorPatterns -ScriptContent $content

if (-not $patterns) {
    Write-Host "  Aucun pattern d'erreur détecté." -ForegroundColor Green
    exit 0
}

# Filtrer les patterns ignorés
$filteredPatterns = $patterns | Where-Object {
    $pattern = $_
    -not ($config.IgnorePatterns | Where-Object { $pattern.Id -like $_ })
}

if (-not $filteredPatterns) {
    Write-Host "  Aucun pattern d'erreur après filtrage." -ForegroundColor Green
    exit 0
}

# Initialiser les compteurs
$errorCount = 0
$warningCount = 0
$errorList = @()

# Afficher les erreurs et avertissements
foreach ($pattern in $filteredPatterns) {
    $severity = $pattern.Severity
    $message = $pattern.Message
    $lineNumber = $pattern.LineNumber
    $id = $pattern.Id

    $errorInfo = [PSCustomObject]@{
        File       = $FilePath
        LineNumber = $lineNumber
        Severity   = $severity
        Message    = $message
        Id         = $id
    }

    $errorList += $errorInfo

    if ($severity -eq "Error") {
        if (-not $IgnoreErrors) {
            Write-Host "  [ERROR] Ligne $lineNumber : $message [$id]" -ForegroundColor Red
            $errorCount++
        }
    } elseif ($severity -eq "Warning") {
        if (-not $IgnoreWarnings) {
            Write-Host "  [WARNING] Ligne $lineNumber : $message [$id]" -ForegroundColor Yellow
            $warningCount++
        }
    }
}

# Générer un rapport
$reportPath = Join-Path -Path $repoRoot -ChildPath "git-hooks\reports\pre-commit-report.md"
$reportDir = Split-Path -Path $reportPath -Parent

if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report = @"
# Rapport d'analyse pre-commit

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- Fichiers analysés: 1
- Erreurs détectées: $errorCount
- Avertissements détectés: $warningCount

## Détails

| Fichier | Ligne | Sévérité | Message | ID |
|---------|-------|----------|---------|-----|
"@

foreach ($error in $errorList) {
    $report += "`n| $($error.File) | $($error.LineNumber) | $($error.Severity) | $($error.Message) | $($error.Id) |"
}

$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nRapport généré: $reportPath" -ForegroundColor Cyan

# Afficher le rapport
Write-Host "`nRapport de test:" -ForegroundColor Cyan
Get-Content -Path $reportPath | ForEach-Object {
    Write-Host $_
}

# Déterminer si le commit doit être bloqué
$blockCommit = $false

if ($errorCount -gt 0 -and -not $IgnoreErrors) {
    if ($errorCount -ge $config.MaxErrors) {
        Write-Host "`nTrop d'erreurs détectées ($errorCount). Commit bloqué." -ForegroundColor Red
        $blockCommit = $true
    } else {
        Write-Host "`nErreurs détectées ($errorCount). Veuillez les corriger avant de committer." -ForegroundColor Red
        $blockCommit = $true
    }
}

if ($blockCommit) {
    exit 1
} else {
    Write-Host "`nAnalyse terminée. Commit autorisé." -ForegroundColor Green
    exit 0
}
$content = Get-Content -Path $FilePath -Raw

# Analyser le fichier pour détecter les erreurs potentielles
$patterns = Get-ErrorPatterns -ScriptContent $content

if (-not $patterns) {
    Write-Host "  Aucun pattern d'erreur détecté." -ForegroundColor Green
    exit 0
}

# Filtrer les patterns ignorés
$filteredPatterns = $patterns | Where-Object {
    $pattern = $_
    -not ($config.IgnorePatterns | Where-Object { $pattern.Id -like $_ })
}

if (-not $filteredPatterns) {
    Write-Host "  Aucun pattern d'erreur après filtrage." -ForegroundColor Green
    exit 0
}

# Initialiser les compteurs
$errorCount = 0
$warningCount = 0
$errorList = @()

# Afficher les erreurs et avertissements
foreach ($pattern in $filteredPatterns) {
    $severity = $pattern.Severity
    $message = $pattern.Message
    $lineNumber = $pattern.LineNumber
    $id = $pattern.Id

    $errorInfo = [PSCustomObject]@{
        File       = $FilePath
        LineNumber = $lineNumber
        Severity   = $severity
        Message    = $message
        Id         = $id
    }

    $errorList += $errorInfo

    if ($severity -eq "Error") {
        if (-not $IgnoreErrors) {
            Write-Host "  [ERROR] Ligne $lineNumber : $message [$id]" -ForegroundColor Red
            $errorCount++
        }
    } elseif ($severity -eq "Warning") {
        if (-not $IgnoreWarnings) {
            Write-Host "  [WARNING] Ligne $lineNumber : $message [$id]" -ForegroundColor Yellow
            $warningCount++
        }
    }
}

# Générer un rapport
$reportPath = Join-Path -Path $repoRoot -ChildPath "git-hooks\reports\pre-commit-report.md"
$reportDir = Split-Path -Path $reportPath -Parent

if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report = @"
# Rapport d'analyse pre-commit

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- Fichiers analysés: 1
- Erreurs détectées: $errorCount
- Avertissements détectés: $warningCount

## Détails

| Fichier | Ligne | Sévérité | Message | ID |
|---------|-------|----------|---------|-----|
"@

foreach ($error in $errorList) {
    $report += "`n| $($error.File) | $($error.LineNumber) | $($error.Severity) | $($error.Message) | $($error.Id) |"
}

$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nRapport généré: $reportPath" -ForegroundColor Cyan

# Afficher le rapport
Write-Host "`nRapport de test:" -ForegroundColor Cyan
Get-Content -Path $reportPath | ForEach-Object {
    Write-Host $_
}

# Déterminer si le commit doit être bloqué
$blockCommit = $false

if ($errorCount -gt 0 -and -not $IgnoreErrors) {
    if ($errorCount -ge $config.MaxErrors) {
        Write-Host "`nTrop d'erreurs détectées ($errorCount). Commit bloqué." -ForegroundColor Red
        $blockCommit = $true
    } else {
        Write-Host "`nErreurs détectées ($errorCount). Veuillez les corriger avant de committer." -ForegroundColor Red
        $blockCommit = $true
    }
}

if ($blockCommit) {
    exit 1
} else {
    Write-Host "`nAnalyse terminée. Commit autorisé." -ForegroundColor Green
    exit 0
}
$content = Get-Content -Path $FilePath -Raw

# Analyser le fichier pour détecter les erreurs potentielles
$patterns = Get-ErrorPatterns -ScriptContent $content

if (-not $patterns) {
    Write-Host "  Aucun pattern d'erreur détecté." -ForegroundColor Green
    exit 0
}

# Filtrer les patterns ignorés
$filteredPatterns = $patterns | Where-Object {
    $pattern = $_
    -not ($config.IgnorePatterns | Where-Object { $pattern.Id -like $_ })
}

if (-not $filteredPatterns) {
    Write-Host "  Aucun pattern d'erreur après filtrage." -ForegroundColor Green
    exit 0
}

# Initialiser les compteurs
$errorCount = 0
$warningCount = 0
$errorList = @()

# Afficher les erreurs et avertissements
foreach ($pattern in $filteredPatterns) {
    $severity = $pattern.Severity
    $message = $pattern.Message
    $lineNumber = $pattern.LineNumber
    $id = $pattern.Id
    
    $errorInfo = [PSCustomObject]@{
        File       = $FilePath
        LineNumber = $lineNumber
        Severity   = $severity
        Message    = $message
        Id         = $id
    }
    
    $errorList += $errorInfo
    
    if ($severity -eq "Error") {
        if (-not $IgnoreErrors) {
            Write-Host "  [ERROR] Ligne $lineNumber : $message [$id]" -ForegroundColor Red
            $errorCount++
        }
    } elseif ($severity -eq "Warning") {
        if (-not $IgnoreWarnings) {
            Write-Host "  [WARNING] Ligne $lineNumber : $message [$id]" -ForegroundColor Yellow
            $warningCount++
        }
    }
}

# Générer un rapport
$reportPath = Join-Path -Path $repoRoot -ChildPath "git-hooks\reports\pre-commit-report.md"
$reportDir = Split-Path -Path $reportPath -Parent

if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report = @"
# Rapport d'analyse pre-commit

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- Fichiers analysés: 1
- Erreurs détectées: $errorCount
- Avertissements détectés: $warningCount

## Détails

| Fichier | Ligne | Sévérité | Message | ID |
|---------|-------|----------|---------|-----|
"@

foreach ($error in $errorList) {
    $report += "`n| $($error.File) | $($error.LineNumber) | $($error.Severity) | $($error.Message) | $($error.Id) |"
}

$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nRapport généré: $reportPath" -ForegroundColor Cyan

# Afficher le rapport
Write-Host "`nRapport de test:" -ForegroundColor Cyan
Get-Content -Path $reportPath | ForEach-Object {
    Write-Host $_
}

# Déterminer si le commit doit être bloqué
$blockCommit = $false

if ($errorCount -gt 0 -and -not $IgnoreErrors) {
    if ($errorCount -ge $config.MaxErrors) {
        Write-Host "`nTrop d'erreurs détectées ($errorCount). Commit bloqué." -ForegroundColor Red
        $blockCommit = $true
    } else {
        Write-Host "`nErreurs détectées ($errorCount). Veuillez les corriger avant de committer." -ForegroundColor Red
        $blockCommit = $true
    }
}

if ($blockCommit) {
    exit 1
} else {
    Write-Host "`nAnalyse terminée. Commit autorisé." -ForegroundColor Green
    exit 0
}
