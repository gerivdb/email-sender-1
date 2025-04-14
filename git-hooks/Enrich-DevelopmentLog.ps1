<#
.SYNOPSIS
    Enrichit le journal de développement avec les résultats d'analyse après un commit.
.DESCRIPTION
    Ce script analyse les fichiers PowerShell modifiés dans le dernier commit et enrichit
    le journal de développement avec les résultats d'analyse. Il génère également un rapport
    d'analyse au format Markdown.
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter()]
    [string]$JournalPath,

    [Parameter()]
    [string]$ReportPath,

    [Parameter()]
    [switch]$IncludeAllFiles,

    [Parameter()]
    [switch]$SkipJournalUpdate,

    [Parameter()]
    [switch]$VerboseOutput
)

# Obtenir le chemin du dépôt Git
$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    Write-Error "Ce script doit être exécuté dans un dépôt Git."
    exit 1
}

# Définir les chemins par défaut si non spécifiés
if (-not $JournalPath) {
    $JournalPath = Join-Path -Path $repoRoot -ChildPath "journal_de_bord.md"
}

if (-not $ReportPath) {
    $reportDir = Join-Path -Path $repoRoot -ChildPath "git-hooks\reports"
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    $ReportPath = Join-Path -Path $reportDir -ChildPath "post-commit-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').md"
}

# Importer le module d'analyse des patterns d'erreurs
$modulePath = Join-Path -Path $repoRoot -ChildPath "scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ErrorPatternAnalyzer non trouvé: $modulePath"
    exit 1
}

# Obtenir les informations sur le dernier commit
$commitHash = git rev-parse HEAD
$commitAuthor = git log -1 --pretty=format:"%an <%ae>"
$commitDate = git log -1 --pretty=format:"%ad" --date=format:"%Y-%m-%d %H:%M:%S"
$commitMessage = git log -1 --pretty=format:"%s"
$commitBody = git log -1 --pretty=format:"%b"

# Obtenir la liste des fichiers modifiés dans le dernier commit
if ($IncludeAllFiles) {
    $modifiedFiles = git diff-tree --no-commit-id --name-only -r $commitHash
} else {
    $modifiedFiles = git diff-tree --no-commit-id --name-only -r $commitHash | Where-Object { $_ -like "*.ps1" -or $_ -like "*.psm1" }
}

if (-not $modifiedFiles) {
    Write-Host "Aucun fichier PowerShell modifié dans le dernier commit."
    exit 0
}

Write-Host "Analyse des fichiers PowerShell modifiés dans le dernier commit..." -ForegroundColor Cyan

$errorCount = 0
$warningCount = 0
$errorList = @()

# Analyser chaque fichier
foreach ($file in $modifiedFiles) {
    $filePath = Join-Path -Path $repoRoot -ChildPath $file

    if (-not (Test-Path -Path $filePath)) {
        Write-Warning "Fichier non trouvé: $filePath"
        continue
    }

    Write-Host "Analyse de $file..." -ForegroundColor Yellow

    # Obtenir le contenu du fichier
    $content = Get-Content -Path $filePath -Raw

    # Analyser le fichier pour détecter les erreurs potentielles
    $patterns = Get-ErrorPatterns -ScriptContent $content

    if (-not $patterns) {
        Write-Host "  Aucun pattern d'erreur détecté." -ForegroundColor Green
        continue
    }

    # Afficher les erreurs et avertissements
    foreach ($pattern in $patterns) {
        $severity = $pattern.Severity
        $message = $pattern.Message
        $lineNumber = $pattern.LineNumber
        $id = $pattern.Id

        $errorInfo = [PSCustomObject]@{
            File        = $file
            LineNumber  = $lineNumber
            Severity    = $severity
            Message     = $message
            Id          = $id
            Description = $pattern.Description
            Suggestion  = $pattern.Suggestion
            CodeExample = $pattern.CodeExample
        }

        $errorList += $errorInfo

        if ($severity -eq "Error") {
            Write-Host "  [ERROR] Ligne $lineNumber : $message [$id]" -ForegroundColor Red
            $errorCount++
        } elseif ($severity -eq "Warning") {
            Write-Host "  [WARNING] Ligne $lineNumber : $message [$id]" -ForegroundColor Yellow
            $warningCount++
        }
    }
}

# Générer un rapport d'analyse
# Catégorisation des erreurs par type (Id)
$categoryGroups = $errorList | Group-Object -Property Id

$report = @"
# 🛠️ Rapport d'analyse post-commit

> *Généré automatiquement par le système d'analyse d'erreurs*

---

**🗓️ Date :** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 📝 Informations sur le commit

- **Hash** : `$commitHash`
- **Auteur** : $commitAuthor
- **Date** : $commitDate
- **Message** : $commitMessage
- **Description** : $commitBody

---

## 📊 Résumé

- **Fichiers analysés** : $($modifiedFiles.Count)
- **❌ Erreurs détectées** : $errorCount
- **⚠️ Avertissements détectés** : $warningCount

---

## 🗂️ Répartition des erreurs par type

| 🏷️ Type d'erreur (ID) | 💬 Message | 🛑 Sévérité | 🔢 Nombre d'occurrences |
|-----------------------|------------|-------------|------------------------|
"@

foreach ($group in $categoryGroups) {
    $first = $group.Group | Select-Object -First 1
    $report += "`n| $($group.Name) | $($first.Message) | $($first.Severity) | $($group.Count) |"
}

$report += @"

## Détails

| Fichier | Ligne | Sévérité | Message | ID |
|---------|-------|----------|---------|-----|
"@

foreach ($errorItem in $errorList) {
    $report += "`n| $($errorItem.File) | $($errorItem.LineNumber) | $($errorItem.Severity) | $($errorItem.Message) | $($errorItem.Id) |"
}

$report += @"

## Suggestions d'amélioration

"@

$uniquePatterns = $errorList | Group-Object -Property Id | ForEach-Object { $_.Group[0] }

foreach ($pattern in $uniquePatterns) {
    $report += @"

### $($pattern.Message) [$($pattern.Id)]

**Description**: $($pattern.Description)

**Suggestion**: $($pattern.Suggestion)

**Exemple de code**:
```powershell
$($pattern.CodeExample)
```

"@
}

# Enregistrer le rapport
$report | Out-File -FilePath $ReportPath -Encoding utf8

Write-Host "`nRapport généré: $ReportPath" -ForegroundColor Cyan

# Mettre à jour le journal de développement
if (-not $SkipJournalUpdate) {
    # Vérifier si le journal existe
    $journalExists = Test-Path -Path $JournalPath

    # Créer l'entrée de journal
    $journalEntry = @"
## $(Get-Date -Format "HH-mm") - Commit: $commitHash

### Actions
- Commit: $commitMessage
- Fichiers modifiés: $($modifiedFiles.Count)
- Erreurs détectées: $errorCount
- Avertissements détectés: $warningCount

### Analyse
"@

    if ($errorCount -gt 0 -or $warningCount -gt 0) {
        $journalEntry += @"

Les problèmes potentiels suivants ont été détectés:

| Fichier | Ligne | Sévérité | Message | ID |
|---------|-------|----------|---------|-----|
"@

        foreach ($errorItem in $errorList) {
            $journalEntry += "`n| $($errorItem.File) | $($errorItem.LineNumber) | $($errorItem.Severity) | $($errorItem.Message) | $($errorItem.Id) |"
        }
    } else {
        $journalEntry += "`n\nAucun problème potentiel détecté."
    }

    $journalEntry += @"

### Leçons apprises
- Rapport d'analyse complet: [Rapport post-commit]($(Resolve-Path -Path $ReportPath -Relative))

"@

    # Mettre à jour le journal
    if ($journalExists) {
        $journalContent = Get-Content -Path $JournalPath -Raw
        $journalContent = "$journalContent`n`n$journalEntry"
        $journalContent | Out-File -FilePath $JournalPath -Encoding utf8
    } else {
        $journalHeader = @"
# Journal de développement

Ce journal contient les entrées de développement enrichies automatiquement par le hook post-commit.

"@
        "$journalHeader`n`n$journalEntry" | Out-File -FilePath $JournalPath -Encoding utf8
    }

    Write-Host "`nJournal de développement mis à jour: $JournalPath" -ForegroundColor Cyan
}

# Retourner un code de sortie en fonction des résultats
if ($errorCount -gt 0) {
    Write-Warning "Des erreurs ont été détectées dans les fichiers modifiés."
    exit 0  # Ne pas bloquer le commit, juste informer
} else {
    Write-Host "`nAnalyse terminée. Aucune erreur détectée." -ForegroundColor Green
    exit 0
}
