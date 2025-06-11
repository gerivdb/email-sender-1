# Script de commit de tâche terminée
# commit-completed-task.ps1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TaskId,
    
    [Parameter(Mandatory=$true)]
    [string]$Section,
    
    [string]$Description = "",
    [string[]]$Details = @(),
    [string]$Phase = "",
    [switch]$SkipTests = $false,
    [switch]$DryRun = $false
)

Write-Host "✅ COMMIT DE TÂCHE TERMINÉE" -ForegroundColor Green

# Validation des paramètres
if (-not $TaskId -or -not $Section) {
    Write-Error "❌ TaskId et Section sont obligatoires"
    exit 1
}

Write-Host "🎯 Tâche: $TaskId" -ForegroundColor Cyan
Write-Host "📂 Section: $Section" -ForegroundColor Cyan
if ($Description) { Write-Host "📝 Description: $Description" -ForegroundColor White }
if ($Phase) { Write-Host "📊 Phase: $Phase" -ForegroundColor White }

# Vérifier l'état du workspace
Write-Host "`n🔍 Vérification état du workspace..." -ForegroundColor Yellow
$gitStatus = git status --porcelain

if (-not $gitStatus) {
    Write-Host "⚠️ Aucune modification détectée - Rien à committer" -ForegroundColor Yellow
    $forceCommit = Read-Host "Créer un commit vide? [y/N]"
    if ($forceCommit -ne 'y' -and $forceCommit -ne 'Y') {
        Write-Host "❌ Opération annulée" -ForegroundColor Red
        exit 0
    }
    $allowEmpty = $true
} else {
    $allowEmpty = $false
    Write-Host "📋 Modifications détectées:" -ForegroundColor Green
    git status --short
}

# Tests automatiques (si non ignorés)
if (-not $SkipTests) {
    Write-Host "`n🧪 Exécution des tests..." -ForegroundColor Yellow
    
    # Vérifier si Go est disponible
    $goAvailable = Get-Command "go" -ErrorAction SilentlyContinue
    if ($goAvailable) {
        # Tests Go
        Write-Host "  🔧 Tests Go..." -ForegroundColor Gray
        go test ./... -short 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Tests Go: PASSÉS" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ Tests Go: ÉCHECS détectés" -ForegroundColor Yellow
            $continueAnyway = Read-Host "Continuer malgré les échecs de tests? [y/N]"
            if ($continueAnyway -ne 'y' -and $continueAnyway -ne 'Y') {
                Write-Host "❌ Commit annulé - Corrigez les tests d'abord" -ForegroundColor Red
                exit 1
            }
        }
        
        # Linting (si disponible)
        $lintAvailable = Get-Command "golangci-lint" -ErrorAction SilentlyContinue
        if ($lintAvailable) {
            Write-Host "  🔧 Linting..." -ForegroundColor Gray
            golangci-lint run --fast 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ Linting: PROPRE" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️ Linting: Problèmes détectés" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  ℹ️ Go non disponible - Tests ignorés" -ForegroundColor Gray
    }
} else {
    Write-Host "⏭️ Tests ignorés (SkipTests activé)" -ForegroundColor Gray
}

# Construction du message de commit
Write-Host "`n📝 Construction du message de commit..." -ForegroundColor Yellow

$commitType = "feat"  # Par défaut pour les nouvelles fonctionnalités
$scope = $Section

# Détails par défaut si non fournis
if ($Details.Count -eq 0) {
    $Details = @(
        "Implémentation terminée",
        "Code testé et validé",
        "Documentation mise à jour"
    )
}

# Construction du message structuré
$commitMessage = @"
$commitType($scope): complete $TaskId - $Description

$(foreach ($detail in $Details) { "- ✅ $detail" }) | Out-String
Refs: plan-dev-v55-planning-ecosystem-sync.md$(if ($Phase) { "#phase-$Phase" })
"@

# Nettoyer le message (enlever lignes vides en trop)
$commitMessage = $commitMessage -replace '\n\s*\n', "`n"
$commitMessage = $commitMessage.Trim()

Write-Host "`n📄 MESSAGE DE COMMIT:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host $commitMessage -ForegroundColor White
Write-Host "----------------------------------------" -ForegroundColor Gray

if ($DryRun) {
    Write-Host "`n🧪 MODE DRY RUN - Aucun commit effectué" -ForegroundColor Magenta
    Write-Host "Commande qui serait exécutée:" -ForegroundColor Gray
    if ($allowEmpty) {
        Write-Host "git commit --allow-empty -m `"$commitMessage`"" -ForegroundColor Gray
    } else {
        Write-Host "git add . && git commit -m `"$commitMessage`"" -ForegroundColor Gray
    }
    exit 0
}

# Confirmation utilisateur
Write-Host ""
$confirmation = Read-Host "Procéder au commit? [Y/n]"
if ($confirmation -eq 'n' -or $confirmation -eq 'N') {
    Write-Host "❌ Commit annulé par l'utilisateur" -ForegroundColor Red
    exit 0
}

# Ajout des fichiers (si nécessaire)
if (-not $allowEmpty) {
    Write-Host "`n📦 Ajout des fichiers..." -ForegroundColor Yellow
    git add .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Échec de l'ajout des fichiers" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Fichiers ajoutés à l'index" -ForegroundColor Green
}

# Exécution du commit
Write-Host "`n🚀 Création du commit..." -ForegroundColor Yellow

if ($allowEmpty) {
    git commit --allow-empty -m $commitMessage
} else {
    git commit -m $commitMessage
}

if ($LASTEXITCODE -eq 0) {
    # Récupération des informations du commit
    $lastCommit = git log -1 --oneline
    $commitHash = git rev-parse --short HEAD
    $currentBranch = git branch --show-current
    
    Write-Host "`n🎉 COMMIT CRÉÉ AVEC SUCCÈS!" -ForegroundColor Green
    Write-Host "📝 Commit: $lastCommit" -ForegroundColor Cyan
    Write-Host "🔗 Hash: $commitHash" -ForegroundColor Cyan
    Write-Host "🌿 Branche: $currentBranch" -ForegroundColor Cyan
    
    # Proposition de push
    Write-Host ""
    $pushNow = Read-Host "Pousser vers remote maintenant? [Y/n]"
    if ($pushNow -ne 'n' -and $pushNow -ne 'N') {
        Write-Host "📡 Push vers remote..." -ForegroundColor Yellow
        git push origin $currentBranch
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Push réussi!" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Échec du push - Faites-le manuellement plus tard" -ForegroundColor Yellow
        }
    }
    
    # Résumé final
    Write-Host "`n📊 RÉSUMÉ:" -ForegroundColor Cyan
    Write-Host "  • Tâche: $TaskId" -ForegroundColor White
    Write-Host "  • Section: $Section" -ForegroundColor White
    Write-Host "  • Commit: $commitHash" -ForegroundColor White
    Write-Host "  • Branche: $currentBranch" -ForegroundColor White
    
} else {
    Write-Host "❌ ÉCHEC DE LA CRÉATION DU COMMIT" -ForegroundColor Red
    Write-Host "Vérifiez les erreurs Git ci-dessus" -ForegroundColor Yellow
    exit 1
}