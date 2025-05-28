# 🔄 Script de Restructuration Modulaire - Algorithmes EMAIL_SENDER_1
# Auteur: Assistant AI
# Date: 2025-05-27
# Description: Découpe et réorganise les gros fichiers d'algorithmes en modules

param(
    [switch]$DryRun = $true,
    [switch]$Force = $false,
    [string]$SourceDir = ".\.github\docs\guides\go",
    [string]$TargetDir = ".\.github\docs\algorithms"
)

Write-Host "🚀 RESTRUCTURATION MODULAIRE ALGORITHMES EMAIL_SENDER_1" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Blue
Write-Host "Target: $TargetDir" -ForegroundColor Blue
Write-Host "Mode: $(if($DryRun){'DRY-RUN (preview)'}else{'EXECUTION'})" -ForegroundColor Yellow

# Configuration de la nouvelle structure modulaire
$algorithmModules = @{
    "error-triage" = @{
        Title = "🔍 Error Triage & Classification EMAIL_SENDER_1"
        Description = "Classification automatique des erreurs multi-stack"
        SourcePattern = "Algorithme 1.*?(?=## 🎯 \*\*Algorithme 2|$)"
        Files = @("README.md", "email_sender_error_classifier.go", "Invoke-EmailSenderErrorTriage.ps1")
        Priority = 1
    }
    "binary-search" = @{
        Title = "🎯 Binary Search Debug EMAIL_SENDER_1"
        Description = "Isolation systématique des composants défaillants"
        SourcePattern = "Algorithme 2.*?(?=## 🎯 \*\*Algorithme 3|$)"
        Files = @("README.md", "email_sender_binary_search_debug.go", "Find-FailingEmailSenderComponents.ps1")
        Priority = 2
    }
    "dependency-analysis" = @{
        Title = "🔗 Dependency Graph Analysis EMAIL_SENDER_1"
        Description = "Analyse des dépendances circulaires inter-composants"
        SourcePattern = "Algorithme 3.*?(?=## 🎯 \*\*Algorithme 4|$)"
        Files = @("README.md", "email_sender_dependency_analyzer.go", "Find-EmailSenderCircularDependencies.ps1")
        Priority = 3
    }
    "progressive-build" = @{
        Title = "🏗️ Progressive Build Strategy EMAIL_SENDER_1"
        Description = "Build incrémental par couches de l'architecture"
        SourcePattern = "Algorithme 4.*?(?=## 🎯 \*\*Algorithme 5|$)"
        Files = @("README.md", "Progressive-EmailSenderBuild.ps1")
        Priority = 4
    }
    "auto-fix" = @{
        Title = "🤖 Auto-Fix Pattern Matching EMAIL_SENDER_1"
        Description = "Correction automatique des erreurs répétitives"
        SourcePattern = "Algorithme 5.*?(?=## 🎯 \*\*Algorithme 6|$)"
        Files = @("README.md", "email_sender_auto_fixer.go", "Auto-Fix-EmailSenderErrors.ps1")
        Priority = 5
    }
    "analysis-pipeline" = @{
        Title = "🔬 Static Analysis Pipeline EMAIL_SENDER_1"
        Description = "Pipeline de validation multi-stack avancé"
        SourcePattern = "Algorithme 6.*?(?=## 🎯 \*\*Algorithme 7|$)"
        Files = @("README.md", "email_sender_analysis_pipeline.go", "Invoke-EmailSenderAnalysisPipeline.ps1")
        Priority = 6
    }
    "config-validator" = @{
        Title = "⚙️ Configuration Validator EMAIL_SENDER_1"
        Description = "Validation systématique des configurations"
        SourcePattern = "Algorithme 7.*?(?=## 🎯 \*\*Algorithme 8|$)"
        Files = @("README.md", "Validate-EmailSenderConfigurations.ps1")
        Priority = 7
    }
    "dependency-resolution" = @{
        Title = "📊 Dependency Resolution Matrix EMAIL_SENDER_1"
        Description = "Gestion intelligente des conflits de dépendances"
        SourcePattern = "Algorithme 8.*?(?=## 🚀|$)"
        Files = @("README.md", "dependency_resolver.go", "Resolve-DependencyConflicts.ps1")
        Priority = 8
    }
}

# Modules partagés
$sharedModules = @{
    "types" = @{
        Title = "📋 Types EMAIL_SENDER_1"
        Description = "Définitions communes pour tous les algorithmes"
        Content = @"
package debug

type EmailSenderComponent int

const (
    RAGEngine EmailSenderComponent = iota
    N8NWorkflow
    NotionAPI
    GmailProcessing
    PowerShellScript
    ConfigFiles
)

type EmailSenderError struct {
    Type      string
    Message   string
    File      string
    Line      int
    Component EmailSenderComponent
    Severity  int
}
"@
    }
    "utils" = @{
        Title = "🔧 Utils EMAIL_SENDER_1"
        Description = "Fonctions utilitaires partagées"
        Content = @"
package debug

import (
    "fmt"
    "strings"
)

func ComponentToString(c EmailSenderComponent) string {
    switch c {
    case RAGEngine:
        return "RAGEngine"
    case N8NWorkflow:
        return "N8NWorkflow"
    case NotionAPI:
        return "NotionAPI"
    case GmailProcessing:
        return "GmailProcessing"
    case PowerShellScript:
        return "PowerShellScript"
    case ConfigFiles:
        return "ConfigFiles"
    default:
        return "Unknown"
    }
}

func GetComponentIcon(c EmailSenderComponent) string {
    switch c {
    case RAGEngine:
        return "⚙️"
    case N8NWorkflow:
        return "🌊"
    case NotionAPI:
        return "📝"
    case GmailProcessing:
        return "📧"
    case PowerShellScript:
        return "⚡"
    case ConfigFiles:
        return "🏗️"
    default:
        return "❓"
    }
}
"@
    }
}

function New-AlgorithmModule {
    param(
        [string]$ModuleName,
        [hashtable]$ModuleConfig,
        [string]$SourceContent,
        [string]$BasePath
    )
    
    $modulePath = Join-Path $BasePath $ModuleName
    
    if ($DryRun) {
        Write-Host "  📁 Créerait: $modulePath" -ForegroundColor Green
        $ModuleConfig.Files | ForEach-Object {
            Write-Host "    📄 $_" -ForegroundColor Blue
        }
        return
    }
    
    # Création du dossier
    if (-not (Test-Path $modulePath)) {
        New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
        Write-Host "  ✅ Créé: $modulePath" -ForegroundColor Green
    }
    
    # Extraction du contenu spécifique
    $algorithmContent = ""
    if ($SourceContent -match $ModuleConfig.SourcePattern) {
        $algorithmContent = $matches[0]
    }
    
    # Création du README.md
    $readmePath = Join-Path $modulePath "README.md"
    $readmeContent = @"
# $($ModuleConfig.Title)

## 📝 Description
$($ModuleConfig.Description)

## 🚀 Usage rapide
``````powershell
# Exécution directe
./$($ModuleConfig.Files | Where-Object {$_ -like "*.ps1"} | Select-Object -First 1)
``````

## 📊 Priorité
**Niveau $($ModuleConfig.Priority)** dans le plan d'action EMAIL_SENDER_1

## 🔧 Fichiers
$($ModuleConfig.Files | ForEach-Object {"- ``$_``"} | Out-String)

## 📋 Contenu détaillé

$algorithmContent

## 🔗 Voir aussi
- [Index des algorithmes](../README.md)
- [Plan d'action EMAIL_SENDER_1](../action-plan.md)
"@
    
    $readmeContent | Set-Content -Path $readmePath -Encoding UTF8
    Write-Host "    📄 Créé: README.md" -ForegroundColor Blue
}

function New-IndexFile {
    param([string]$TargetPath)
    
    $indexContent = @"
# 🚀 Algorithmes EMAIL_SENDER_1 - Index Modulaire

*Algorithmes de debug et validation spécialement conçus pour l'architecture EMAIL_SENDER_1*

## 🎯 Vue d'ensemble

EMAIL_SENDER_1 est un système hybride multi-stack nécessitant des algorithmes spécialisés :
- **🔧 RAG Go Engine** - Core vectoriel
- **🌊 n8n Workflows** - Orchestration  
- **📝 Notion Integration** - CRM
- **📧 Gmail Processing** - Email handling
- **⚡ PowerShell Scripts** - Coordination

## 🚨 Algorithmes par priorité (Urgence 400+ erreurs)

### 🔥 Priorité Critique (1-2)
$($algorithmModules.GetEnumerator() | Where-Object {$_.Value.Priority -le 2} | Sort-Object {$_.Value.Priority} | ForEach-Object {
"- [**$($_.Value.Title)**](./$($_.Key)/) - $($_.Value.Description)"
} | Out-String)

### ⚡ Priorité Haute (3-4)  
$($algorithmModules.GetEnumerator() | Where-Object {$_.Value.Priority -in 3,4} | Sort-Object {$_.Value.Priority} | ForEach-Object {
"- [**$($_.Value.Title)**](./$($_.Key)/) - $($_.Value.Description)"
} | Out-String)

### 🔧 Priorité Standard (5+)
$($algorithmModules.GetEnumerator() | Where-Object {$_.Value.Priority -ge 5} | Sort-Object {$_.Value.Priority} | ForEach-Object {
"- [**$($_.Value.Title)**](./$($_.Key)/) - $($_.Value.Description)"
} | Out-String)

## 🧩 Modules partagés
- [**Types EMAIL_SENDER_1**](./shared/types.go) - Définitions communes
- [**Utils EMAIL_SENDER_1**](./shared/utils.go) - Fonctions utilitaires

## 🚀 Usage rapide

``````powershell
# Plan d'action complet (4h45)
./action-plan.ps1

# Algorithme spécifique
cd ./error-triage
./Invoke-EmailSenderErrorTriage.ps1
``````

## 📊 ROI Global
**285 minutes → 320-540 erreurs résolues = 80-135% des 400 erreurs** 🎯

---
*Généré automatiquement le $(Get-Date -Format 'yyyy-MM-dd HH:mm')*
"@

    if ($DryRun) {
        Write-Host "  📄 Créerait: INDEX.md" -ForegroundColor Blue
        return
    }
    
    $indexPath = Join-Path $TargetPath "README.md"
    $indexContent | Set-Content -Path $indexPath -Encoding UTF8
    Write-Host "  ✅ Créé: INDEX.md" -ForegroundColor Green
}

# === EXÉCUTION PRINCIPALE ===

Write-Host "`n📋 PLAN DE RESTRUCTURATION:" -ForegroundColor Yellow

# Vérification des chemins
$sourceFile = Join-Path $SourceDir "Algorithmes-go.md"
if (-not (Test-Path $sourceFile)) {
    Write-Host "❌ ERREUR: Fichier source introuvable: $sourceFile" -ForegroundColor Red
    exit 1
}

# Lecture du contenu source
$sourceContent = Get-Content -Path $sourceFile -Raw -Encoding UTF8

# Création de la structure cible
if (-not $DryRun -and -not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# Création des modules partagés
Write-Host "`n🧩 MODULES PARTAGÉS:" -ForegroundColor Magenta
$sharedPath = Join-Path $TargetDir "shared"
if (-not $DryRun -and -not (Test-Path $sharedPath)) {
    New-Item -ItemType Directory -Path $sharedPath -Force | Out-Null
}

foreach ($module in $sharedModules.GetEnumerator()) {
    if ($DryRun) {
        Write-Host "  📄 Créerait: shared/$($module.Key).go" -ForegroundColor Blue
    } else {
        $filePath = Join-Path $sharedPath "$($module.Key).go"
        $module.Value.Content | Set-Content -Path $filePath -Encoding UTF8
        Write-Host "  ✅ Créé: shared/$($module.Key).go" -ForegroundColor Green
    }
}

# Création des modules d'algorithmes
Write-Host "`n🎯 ALGORITHMES:" -ForegroundColor Magenta
foreach ($algorithm in $algorithmModules.GetEnumerator()) {
    Write-Host "`n  📁 Module: $($algorithm.Key)" -ForegroundColor Yellow
    New-AlgorithmModule -ModuleName $algorithm.Key -ModuleConfig $algorithm.Value -SourceContent $sourceContent -BasePath $TargetDir
}

# Création de l'index
Write-Host "`n📚 INDEX:" -ForegroundColor Magenta
New-IndexFile -TargetPath $TargetDir

# Résumé
Write-Host "`n📊 RÉSUMÉ RESTRUCTURATION:" -ForegroundColor Cyan
Write-Host "Modules créés: $($algorithmModules.Count)" -ForegroundColor Green
Write-Host "Modules partagés: $($sharedModules.Count)" -ForegroundColor Green
Write-Host "Fichiers totaux: ~$($algorithmModules.Count * 3 + $sharedModules.Count + 1)" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n⚠️ MODE DRY-RUN - Aucune modification appliquée" -ForegroundColor Yellow
    Write-Host "Relancer avec -DryRun:`$false pour exécuter la restructuration" -ForegroundColor Yellow
} else {
    Write-Host "`n🎉 RESTRUCTURATION TERMINÉE!" -ForegroundColor Green
    Write-Host "Nouvelle structure disponible dans: $TargetDir" -ForegroundColor Green
}
