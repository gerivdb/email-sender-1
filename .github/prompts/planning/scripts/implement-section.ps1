# Script principal d'implémentation par section
# implement-section.ps1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Section,
    
    [Parameter(Mandatory=$true)]
    [string]$TaskId,
    
    [string]$Description = "",
    [string]$Phase = "",
    [string]$PlanFile = "projet\roadmaps\plans\consolidated\plan-dev-v55-planning-ecosystem-sync.md",
    [string]$Branch = "planning-ecosystem-sync",
    [switch]$ValidateUntracked,
    [switch]$AutoCommit,
    [switch]$UpdateProgress,
    [switch]$SkipTests,
    [switch]$DryRun
)

# Variables globales
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))

Write-Host "🚀 IMPLÉMENTATION MÉTHODIQUE - PLAN-DEV-V55" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "📋 Section: $Section" -ForegroundColor White
Write-Host "🎯 Tâche: $TaskId" -ForegroundColor White
Write-Host "📝 Description: $Description" -ForegroundColor White
Write-Host "🌿 Branche cible: $Branch" -ForegroundColor White
if ($DryRun) { Write-Host "🧪 MODE DRY RUN activé" -ForegroundColor Magenta }

# Définir variables d'environnement pour les autres scripts
$env:TASK_TYPE = "plan-dev-v55"
$env:SECTION = $Section
$env:TASK_ID = $TaskId
$env:DESCRIPTION = $Description
$env:PHASE = $Phase

# ==============================================================================
# PHASE 1: VÉRIFICATIONS PRÉ-IMPLÉMENTATION
# ==============================================================================

Write-Host "`n" + "="*60 -ForegroundColor Yellow
Write-Host "🔍 PHASE 1: VÉRIFICATIONS PRÉ-IMPLÉMENTATION" -ForegroundColor Yellow
Write-Host "="*60 -ForegroundColor Yellow

# 1.1 Vérifier existence du plan
Write-Host "`n📋 Vérification du plan de développement..." -ForegroundColor Gray
$planPath = Join-Path $ProjectRoot $PlanFile

if (-not (Test-Path $planPath)) {
    Write-Host "❌ Plan non trouvé: $planPath" -ForegroundColor Red
    exit 1
}

$planLastModified = (Get-Item $planPath).LastWriteTime
Write-Host "✅ Plan trouvé - Dernière modification: $planLastModified" -ForegroundColor Green

# 1.2 Gestion des fichiers non suivis
if ($ValidateUntracked) {
    Write-Host "`n📁 Gestion des fichiers non suivis..." -ForegroundColor Gray
    
    $untrackedScript = Join-Path $ScriptDir "handle-untracked-files.ps1"
    if (Test-Path $untrackedScript) {
        & $untrackedScript -AutoCommit:$AutoCommit -DryRun:$DryRun
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Échec de la gestion des fichiers non suivis" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠️ Script de gestion des fichiers non suivis non trouvé" -ForegroundColor Yellow
    }
} else {
    Write-Host "⏭️ Validation fichiers non suivis ignorée" -ForegroundColor Gray
}

# 1.3 Vérification/basculement de branche
Write-Host "`n🌿 Gestion des branches..." -ForegroundColor Gray

$branchScript = Join-Path $ScriptDir "ensure-correct-branch.ps1"
if (Test-Path $branchScript) {
    & $branchScript -TargetBranch $Branch -TaskType "plan-dev-v55" -CreateIfNotExists
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Échec de la gestion des branches" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️ Script de gestion des branches non trouvé" -ForegroundColor Yellow
    Write-Host "📝 Vérification manuelle de la branche..." -ForegroundColor Gray
    
    $currentBranch = git branch --show-current
    if ($currentBranch -ne $Branch) {
        Write-Host "⚠️ Branche incorrecte: $currentBranch (attendu: $Branch)" -ForegroundColor Yellow
        $switchBranch = Read-Host "Basculer vers $Branch? [Y/n]"
        
        if ($switchBranch -ne 'n' -and $switchBranch -ne 'N') {
            git checkout $Branch
            if ($LASTEXITCODE -ne 0) {
                git checkout -b $Branch
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "❌ Impossible de basculer vers $Branch" -ForegroundColor Red
                    exit 1
                }
            }
        }
    }
}

# 1.4 Vérification environnement technique
Write-Host "`n🔧 Vérification environnement technique..." -ForegroundColor Gray

# Go
$goVersion = go version 2>$null
if ($goVersion) {
    Write-Host "✅ Go: $goVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️ Go non disponible" -ForegroundColor Yellow
}

# Git
$gitVersion = git version 2>$null
if ($gitVersion) {
    Write-Host "✅ Git: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Git non disponible - CRITIQUE" -ForegroundColor Red
    exit 1
}

# PowerShell
Write-Host "✅ PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Green

Write-Host "`n✅ PHASE 1 TERMINÉE - Prêt pour l'implémentation" -ForegroundColor Green

# ==============================================================================
# PHASE 2: IMPLÉMENTATION GUIDÉE
# ==============================================================================

Write-Host "`n" + "="*60 -ForegroundColor Yellow
Write-Host "🛠️ PHASE 2: IMPLÉMENTATION GUIDÉE" -ForegroundColor Yellow
Write-Host "="*60 -ForegroundColor Yellow

# Afficher les détails de la tâche depuis le plan
Write-Host "`n📖 Détails de la tâche depuis le plan:" -ForegroundColor Cyan

try {
    $planContent = Get-Content $planPath -Raw -Encoding UTF8
    
    # Rechercher la tâche spécifique
    $taskPattern = "Micro-étape $([regex]::Escape($TaskId)):.*?(?=Micro-étape|\z)"
    $taskMatch = [regex]::Match($planContent, $taskPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($taskMatch.Success) {
        $taskContent = $taskMatch.Value
        # Limiter l'affichage aux 15 premières lignes pour éviter l'overflow
        $taskLines = $taskContent -split "`n" | Select-Object -First 15
        
        Write-Host "┌─ Extrait du plan ─┐" -ForegroundColor Gray
        foreach ($line in $taskLines) {
            Write-Host "│ $line" -ForegroundColor White
        }
        if ($taskContent -split "`n" | Measure-Object | Select-Object -ExpandProperty Count -gt 15) {
            Write-Host "│ ... (contenu tronqué)" -ForegroundColor Gray
        }
        Write-Host "└─────────────────────┘" -ForegroundColor Gray
    } else {
        Write-Host "⚠️ Tâche $TaskId non trouvée dans le plan" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Impossible de lire le contenu du plan: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Guide d'implémentation
Write-Host "`n📋 GUIDE D'IMPLÉMENTATION:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 📁 Créez/modifiez les fichiers nécessaires selon les spécifications" -ForegroundColor White
Write-Host "2. 🧪 Ajoutez les tests unitaires appropriés" -ForegroundColor White
Write-Host "3. 📝 Mettez à jour la documentation inline" -ForegroundColor White
Write-Host "4. ✅ Vérifiez que le code compile et les tests passent" -ForegroundColor White
Write-Host "5. 🔍 Effectuez une review rapide de votre code" -ForegroundColor White

# Recommandations spécifiques selon la section
Write-Host "`n💡 RECOMMANDATIONS SPÉCIFIQUES:" -ForegroundColor Cyan

switch -Regex ($Section) {
    "sync-tools|migration" {
        Write-Host "• Utilisez les interfaces ToolkitOperation v3.0.0" -ForegroundColor Yellow
        Write-Host "• Implémentez String(), GetDescription(), Stop()" -ForegroundColor Yellow
        Write-Host "• Ajoutez la gestion d'erreurs appropriée" -ForegroundColor Yellow
    }
    "validation" {
        Write-Host "• Respectez les patterns de validation existants" -ForegroundColor Yellow
        Write-Host "• Testez avec des données invalides" -ForegroundColor Yellow
        Write-Host "• Documentez les règles de validation" -ForegroundColor Yellow
    }
    "testing" {
        Write-Host "• Visez une couverture > 80%" -ForegroundColor Yellow
        Write-Host "• Incluez tests positifs et négatifs" -ForegroundColor Yellow
        Write-Host "• Testez les cas limites" -ForegroundColor Yellow
    }
    "documentation" {
        Write-Host "• Utilisez un langage clair et concis" -ForegroundColor Yellow
        Write-Host "• Ajoutez des exemples pratiques" -ForegroundColor Yellow
        Write-Host "• Vérifiez la cohérence avec docs existantes" -ForegroundColor Yellow
    }
    default {
        Write-Host "• Suivez les conventions du projet" -ForegroundColor Yellow
        Write-Host "• Documentez les APIs publiques" -ForegroundColor Yellow
        Write-Host "• Testez l'intégration avec composants existants" -ForegroundColor Yellow
    }
}

if ($DryRun) {
    Write-Host "`n🧪 MODE DRY RUN - Phase d'implémentation simulée" -ForegroundColor Magenta
} else {
    Write-Host "`n⏳ IMPLÉMENTATION EN COURS..." -ForegroundColor Yellow
    Write-Host "Appuyez sur [Entrée] quand l'implémentation est terminée..."
    Read-Host
}

Write-Host "✅ PHASE 2 TERMINÉE - Implémentation effectuée" -ForegroundColor Green

# ==============================================================================
# PHASE 3: POST-IMPLÉMENTATION
# ==============================================================================

Write-Host "`n" + "="*60 -ForegroundColor Yellow
Write-Host "✅ PHASE 3: POST-IMPLÉMENTATION" -ForegroundColor Yellow
Write-Host "="*60 -ForegroundColor Yellow

# 3.1 Tests automatiques
if (-not $SkipTests) {
    Write-Host "`n🧪 Validation technique..." -ForegroundColor Gray
    
    # Tests Go si disponible
    $goAvailable = Get-Command "go" -ErrorAction SilentlyContinue
    if ($goAvailable) {
        Write-Host "📋 Exécution des tests Go..." -ForegroundColor Yellow
        
        if ($DryRun) {
            Write-Host "[DRY RUN] go test ./... -v -short" -ForegroundColor Magenta
        } else {
            go test ./... -v -short
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Tests Go: TOUS PASSÉS" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Tests Go: ÉCHECS détectés" -ForegroundColor Yellow
                $continueAnyway = Read-Host "Continuer malgré les échecs? [y/N]"
                if ($continueAnyway -ne 'y' -and $continueAnyway -ne 'Y') {
                    Write-Host "❌ Arrêt - Corrigez les tests d'abord" -ForegroundColor Red
                    exit 1
                }
            }
        }
    }
} else {
    Write-Host "⏭️ Tests ignorés (SkipTests activé)" -ForegroundColor Gray
}

# 3.2 Commit automatique
if ($AutoCommit) {
    Write-Host "`n📦 Commit automatique..." -ForegroundColor Gray
    
    $commitScript = Join-Path $ScriptDir "commit-completed-task.ps1"
    if (Test-Path $commitScript) {
        $commitArgs = @{
            TaskId = $TaskId
            Section = $Section
            Description = $Description
            Phase = $Phase
            SkipTests = $SkipTests
            DryRun = $DryRun
        }
        
        & $commitScript @commitArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️ Problème lors du commit automatique" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️ Script de commit non trouvé - commit manuel requis" -ForegroundColor Yellow
    }
} else {
    Write-Host "📝 Commit manuel requis" -ForegroundColor Yellow
    Write-Host "💡 Utilisez: git add . && git commit -m 'feat($Section): complete $TaskId'" -ForegroundColor Cyan
}

# 3.3 Mise à jour du plan
if ($UpdateProgress) {
    Write-Host "`n📊 Mise à jour progression du plan..." -ForegroundColor Gray
    
    # Script de mise à jour (simplifié ici)
    if ($DryRun) {
        Write-Host "[DRY RUN] Mise à jour case à cocher pour tâche $TaskId" -ForegroundColor Magenta
    } else {
        try {
            $planContent = Get-Content $planPath -Raw -Encoding UTF8
            
            # Marquer la tâche comme terminée
            $taskPattern = "- \[ \] (.*$([regex]::Escape($TaskId)).*)"
            $replacement = "- [x] `$1"
            
            if ($planContent -match $taskPattern) {
                $planContent = $planContent -replace $taskPattern, $replacement
                Set-Content -Path $planPath -Value $planContent -Encoding UTF8
                
                Write-Host "✅ Tâche $TaskId marquée comme terminée dans le plan" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Tâche $TaskId non trouvée pour mise à jour" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌ Erreur lors de la mise à jour: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "📝 Mise à jour manuelle du plan requise" -ForegroundColor Yellow
}

# ==============================================================================
# RÉSUMÉ FINAL
# ==============================================================================

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "🎉 IMPLÉMENTATION TERMINÉE AVEC SUCCÈS!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host "`n📊 RÉSUMÉ DE L'OPÉRATION:" -ForegroundColor Cyan
Write-Host "• Tâche: $TaskId" -ForegroundColor White
Write-Host "• Section: $Section" -ForegroundColor White
Write-Host "• Description: $Description" -ForegroundColor White
Write-Host "• Branche: $(git branch --show-current)" -ForegroundColor White
Write-Host "• Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

if ($DryRun) {
    Write-Host "• Mode: DRY RUN (aucune modification réelle)" -ForegroundColor Magenta
}

Write-Host "`n🎯 PROCHAINES ÉTAPES:" -ForegroundColor Cyan
Write-Host "1. Vérifiez que tout fonctionne comme attendu" -ForegroundColor White
Write-Host "2. Effectuez une review de code si nécessaire" -ForegroundColor White
Write-Host "3. Passez à la tâche suivante du plan" -ForegroundColor White
Write-Host "4. Mettez à jour la documentation projet si applicable" -ForegroundColor White

Write-Host "`n🔗 LIENS UTILES:" -ForegroundColor Cyan
Write-Host "• Plan: $PlanFile" -ForegroundColor Blue
Write-Host "• Branche: $(git branch --show-current)" -ForegroundColor Blue
Write-Host "• Dernier commit: $(git log -1 --oneline 2>$null)" -ForegroundColor Blue

Write-Host "`n🌟 Excellente progression sur le plan-dev-v55!" -ForegroundColor Green