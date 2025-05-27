#!/usr/bin/env pwsh
<#
.SYNOPSIS
Script pour corriger les incohérences dans le dossier .github

.DESCRIPTION
Corrige les formats incohérents, les doublons et les erreurs de configuration
dans la structure .github du projet EMAIL_SENDER_1

.PARAMETER Fix
Active les corrections automatiques

.PARAMETER DryRun
Mode simulation sans modifications

.EXAMPLE
.\fix-github-inconsistencies.ps1 -DryRun
.\fix-github-inconsistencies.ps1 -Fix
#>

param(
    [switch]$Fix,
    [switch]$DryRun = $true
)

$script:IssuesFound = @()
$script:FixesApplied = @()

function Write-Issue {
    param([string]$Category, [string]$File, [string]$Issue, [string]$Suggestion = "")
    
    $issueObj = [PSCustomObject]@{
        Category = $Category
        File = $File
        Issue = $Issue
        Suggestion = $Suggestion
        Timestamp = Get-Date
    }
    
    $script:IssuesFound += $issueObj
    Write-Host "❌ [$Category] $File : $Issue" -ForegroundColor Red
    if ($Suggestion) {
        Write-Host "   💡 Suggestion: $Suggestion" -ForegroundColor Yellow
    }
}

function Write-Fix {
    param([string]$Category, [string]$File, [string]$Action)
    
    $fixObj = [PSCustomObject]@{
        Category = $Category
        File = $File
        Action = $Action
        Timestamp = Get-Date
    }
    
    $script:FixesApplied += $fixObj
    Write-Host "✅ [$Category] $File : $Action" -ForegroundColor Green
}

function Test-PromptFileFormat {
    param([string]$FilePath)
    
    if (!(Test-Path $FilePath)) {
        Write-Issue "MISSING" $FilePath "Fichier inexistant"
        return $false
    }
    
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $fileName = Split-Path $FilePath -Leaf
    
    # Vérifier le front matter YAML
    if ($content -notmatch '^---\s*\n') {
        Write-Issue "FORMAT" $fileName "Front matter YAML manquant" "Ajouter ---\ntitle: '...'\n---"
        return $false
    }
    
    # Vérifier la cohérence du format
    $lines = $content -split "`n"
    $frontMatterEnd = -1
    $inFrontMatter = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^---\s*$') {
            if (-not $inFrontMatter) {
                $inFrontMatter = $true
            } else {
                $frontMatterEnd = $i
                break
            }
        }
    }
    
    if ($frontMatterEnd -eq -1) {
        Write-Issue "FORMAT" $fileName "Front matter YAML mal fermé" "Ajouter --- à la fin du front matter"
        return $false
    }
    
    # Vérifier les propriétés requises
    $frontMatter = ($lines[1..($frontMatterEnd-1)] -join "`n")
    $requiredFields = @('title', 'description')
      foreach ($field in $requiredFields) {
        if ($frontMatter -notmatch "$field\s*:") {
            Write-Issue "FORMAT" $fileName "Champ '$field' manquant dans le front matter" "Ajouter ${field}: '...'"
        }
    }
    
    return $true
}

function Fix-PromptFileFormat {
    param([string]$FilePath)
    
    if (!(Test-Path $FilePath)) {
        return
    }
    
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $fileName = Split-Path $FilePath -Leaf
    $modeName = ($fileName -replace '-mode\.prompt\.md$', '') -replace '\.prompt\.md$', ''
    
    # Template standard pour les prompts
    $standardTemplate = @"
---
title: "Mode $modeName"
description: "Mode opérationnel $modeName pour le projet EMAIL_SENDER_1"
behavior:
  temperature: 0.2
  maxTokens: 2048
tags: ["mode", "$($modeName.ToLower())", "operation"]
---

# Mode $modeName

## 🎯 Objectif
[Description de l'objectif du mode]

## 📋 Paramètres
[Liste des paramètres]

## 🔄 Workflow
[Description du workflow]

## 🛠️ Commandes Principales
```powershell
# Exemple de commande
.\$($modeName.ToLower())-mode.ps1 -Parameter "value"
```

## 📊 Métriques
[Métriques et indicateurs]

## 🔗 Intégration
[Intégration avec autres modes]

## ⚠️ Points d'Attention
[Points importants à noter]
"@

    if ($Fix) {
        # Sauvegarder l'original
        $backupPath = "$FilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $FilePath $backupPath
        
        # Si le fichier a un format incohérent, appliquer le template standard
        if ($content -notmatch '^---\s*\n.*title\s*:.*\n.*---' -or 
            $content -match 'mode:\s*[''"]agent[''"]') {
            
            Set-Content $FilePath $standardTemplate -Encoding UTF8
            Write-Fix "FORMAT" $fileName "Format standardisé appliqué"
        }
    }
}

function Test-DocumentationConsistency {
    $githubReadme = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.github\README.md"
    $docsReadme = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.github\docs\README.md"
    $projectReadme = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.github\docs\project\README_EMAIL_SENDER_1.md"
    
    # Vérifier la cohérence des priorités technologiques
    if (Test-Path $projectReadme) {
        $projectContent = Get-Content $projectReadme -Raw -Encoding UTF8
        if ($projectContent -notmatch "Golang.*1\.2[12]\+.*primary") {
            Write-Issue "PRIORITY" "README_EMAIL_SENDER_1.md" "Priorité Golang non claire" "Mettre Golang 1.21+ comme langage principal"
        }
    }
    
    # Vérifier les liens entre documents
    $files = @($githubReadme, $docsReadme)
    foreach ($file in $files) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw -Encoding UTF8
            # Vérifier les liens brisés (simple check)
            $links = [regex]::Matches($content, '\[.*?\]\((.*?)\)')
            foreach ($match in $links) {
                $linkPath = $match.Groups[1].Value
                if ($linkPath -match '^[^http]' -and $linkPath -notmatch '^#') {
                    $fullLinkPath = Join-Path (Split-Path $file -Parent) $linkPath
                    if (!(Test-Path $fullLinkPath)) {
                        Write-Issue "LINK" (Split-Path $file -Leaf) "Lien brisé: $linkPath"
                    }
                }
            }
        }
    }
}

function Test-PromptModeConsistency {
    $promptsDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.github\prompts\modes"
    $methodologiesDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\methodologies\modes"
    
    if (!(Test-Path $promptsDir)) {
        Write-Issue "MISSING" "prompts/modes" "Dossier des prompts modes manquant"
        return
    }
    
    $promptFiles = Get-ChildItem $promptsDir -Filter "*.prompt.md"
    $methodologyFiles = Get-ChildItem $methodologiesDir -Filter "mode_*.md" -ErrorAction SilentlyContinue
    
    # Extraire les noms de modes
    $promptModes = $promptFiles | ForEach-Object { 
        ($_.BaseName -replace '-mode\.prompt$', '') -replace '\.prompt$', ''
    }
    $methodologyModes = $methodologyFiles | ForEach-Object {
        ($_.BaseName -replace '^mode_', '') -replace '_enhanced$', ''
    }
    
    # Vérifier la cohérence
    foreach ($mode in $promptModes) {
        $methodologyEquivalent = $methodologyModes | Where-Object { $_ -match $mode -or $mode -match $_ }
        if (-not $methodologyEquivalent) {
            Write-Issue "CONSISTENCY" "$mode-mode.prompt.md" "Mode sans documentation méthodologique correspondante"
        }
    }
    
    foreach ($mode in $methodologyModes) {
        $promptEquivalent = $promptModes | Where-Object { $_ -match $mode -or $mode -match $_ }
        if (-not $promptEquivalent) {
            Write-Issue "CONSISTENCY" "mode_$mode.md" "Mode sans prompt correspondant"
        }
    }
}

function Fix-GolangPriority {
    $projectReadme = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.github\docs\project\README_EMAIL_SENDER_1.md"
    
    if ($Fix -and (Test-Path $projectReadme)) {
        $content = Get-Content $projectReadme -Raw -Encoding UTF8
        
        # Mise à jour pour prioriser Golang
        $updatedContent = $content -replace 
            '(Technologies?)[\s\S]*?(?=##|$)',
            @"
## Technologies Principales

### Environnement de Développement (Priorité)
1. **Golang 1.21+** - Langage principal (10-1000x plus rapide que PowerShell/Python)
2. **PowerShell 7.0+** - Compatibilité legacy et automatisation Windows
3. **Python 3.11+** - Scripts d'analyse et intégrations tierces
4. **TypeScript** - Interface utilisateur et intégrations web

### Architecture RAG System
- **Performance**: Golang pour les composants critiques
- **Automatisation**: Framework 7-méthodes avec ROI prouvé
- **Compatibilité**: Support legacy PS+Py pour migration progressive

"@
        
        if ($content -ne $updatedContent) {
            $backupPath = "$projectReadme.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $projectReadme $backupPath
            Set-Content $projectReadme $updatedContent -Encoding UTF8
            Write-Fix "PRIORITY" "README_EMAIL_SENDER_1.md" "Priorité Golang mise à jour"
        }
    }
}

function Generate-ConsistencyReport {
    $reportPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\analysis\.github-consistency-report.md"
    
    $report = @"
# Rapport de Cohérence .github

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Issues trouvées**: $($script:IssuesFound.Count)
**Corrections appliquées**: $($script:FixesApplied.Count)

## Résumé par Catégorie

"@

    $categorizedIssues = $script:IssuesFound | Group-Object Category
    foreach ($category in $categorizedIssues) {
        $report += "`n### $($category.Name) ($($category.Count) issues)`n`n"
        foreach ($issue in $category.Group) {
            $report += "- **$($issue.File)**: $($issue.Issue)`n"
            if ($issue.Suggestion) {
                $report += "  - 💡 $($issue.Suggestion)`n"
            }
        }
    }

    if ($script:FixesApplied.Count -gt 0) {
        $report += "`n## Corrections Appliquées`n`n"
        foreach ($fix in $script:FixesApplied) {
            $report += "- **$($fix.File)**: $($fix.Action)`n"
        }
    }

    $report += @"

## Actions Recommandées

1. **Formats des Prompts**: Standardiser tous les prompts avec le format YAML front-matter
2. **Documentation**: Mettre à jour les liens et références croisées
3. **Priorité Golang**: Assurer la cohérence dans tous les documents
4. **Tests d'Intégrité**: Implémenter des vérifications automatiques en CI/CD

## Script de Validation

```powershell
# Vérification complète
.\fix-github-inconsistencies.ps1 -DryRun

# Application des corrections
.\fix-github-inconsistencies.ps1 -Fix
```
"@

    Set-Content $reportPath $report -Encoding UTF8
    Write-Host "`n📊 Rapport généré: $reportPath" -ForegroundColor Cyan
}

# Exécution principale
Write-Host "🔍 Analyse de cohérence .github..." -ForegroundColor Cyan
Write-Host "Mode: $(if ($Fix) { 'CORRECTION' } else { 'SIMULATION' })" -ForegroundColor Yellow

# Tests de cohérence
Test-DocumentationConsistency
Test-PromptModeConsistency

# Tests des formats de prompts
$promptFiles = Get-ChildItem "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.github\prompts\modes" -Filter "*.prompt.md" -ErrorAction SilentlyContinue
foreach ($file in $promptFiles) {
    Test-PromptFileFormat $file.FullName
    if ($Fix) {
        Fix-PromptFileFormat $file.FullName
    }
}

# Correction priorité Golang
Fix-GolangPriority

# Génération du rapport
Generate-ConsistencyReport

Write-Host "`n✅ Analyse terminée" -ForegroundColor Green
Write-Host "Issues trouvées: $($script:IssuesFound.Count)" -ForegroundColor Yellow
Write-Host "Corrections: $($script:FixesApplied.Count)" -ForegroundColor Green
