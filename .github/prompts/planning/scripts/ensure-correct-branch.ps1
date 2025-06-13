# Script de gestion des branches
# ensure-correct-branch.ps1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetBranch,
    
    [string]$TaskType = "plan-dev-v55",
    [switch]$CreateIfNotExists = $true,
    [switch]$Force = $false
)

Write-Host "🔄 VÉRIFICATION ET GESTION DES BRANCHES" -ForegroundColor Cyan

# Obtenir branche actuelle
$currentBranch = git branch --show-current
Write-Host "📍 Branche actuelle: $currentBranch" -ForegroundColor White

# Vérifier si on est déjà sur la bonne branche
if ($currentBranch -eq $TargetBranch) {
    Write-Host "✅ Déjà sur la branche correcte: $TargetBranch" -ForegroundColor Green
    return
}

Write-Host "🎯 Branche cible: $TargetBranch" -ForegroundColor Yellow
Write-Host "📝 Type de tâche: $TaskType" -ForegroundColor Gray

# Vérifier l'état du workspace
$gitStatus = git status --porcelain
if ($gitStatus -and -not $Force) {
    Write-Host "⚠️ ATTENTION: Modifications non commitées détectées!" -ForegroundColor Red
    Write-Host ""
    git status --short
    Write-Host ""
    
    $response = Read-Host "Continuer quand même? Les modifications pourraient être perdues [y/N]"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "❌ Opération annulée - Commitez vos modifications d'abord" -ForegroundColor Red
        Write-Host "💡 Utilisez: git add . && git commit -m 'WIP: temporary commit'" -ForegroundColor Cyan
        exit 1
    }
}

# Vérifier si la branche cible existe localement
$localBranches = git branch --list $TargetBranch
$branchExists = $localBranches -ne $null -and $localBranches.Count -gt 0

Write-Host "🔍 Vérification existence branche locale..." -ForegroundColor Gray

if ($branchExists) {
    Write-Host "✅ Branche existe localement: $TargetBranch" -ForegroundColor Green
    
    # Basculer vers la branche existante
    Write-Host "🔄 Basculement vers: $TargetBranch..." -ForegroundColor Yellow
    git checkout $TargetBranch
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Basculement réussi vers: $TargetBranch" -ForegroundColor Green
        
        # Vérifier si on peut faire un pull
        Write-Host "📡 Vérification mises à jour distantes..." -ForegroundColor Gray
        git fetch origin $TargetBranch 2>$null
        
        $behind = git rev-list --count HEAD..origin/$TargetBranch 2>$null
        if ($behind -and $behind -gt 0) {
            Write-Host "📥 $behind commits en retard - Mise à jour recommandée" -ForegroundColor Yellow
            $pullResponse = Read-Host "Effectuer git pull? [Y/n]"
            
            if ($pullResponse -ne 'n' -and $pullResponse -ne 'N') {
                git pull origin $TargetBranch
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Branche mise à jour avec succès" -ForegroundColor Green
                } else {
                    Write-Host "⚠️ Problème lors de la mise à jour - continuez manuellement" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "✅ Branche à jour" -ForegroundColor Green
        }
        
    } else {
        Write-Host "❌ Échec du basculement vers: $TargetBranch" -ForegroundColor Red
        exit 1
    }
    
} else {
    Write-Host "📝 Branche n'existe pas localement: $TargetBranch" -ForegroundColor Yellow
    
    if ($CreateIfNotExists) {
        # Vérifier si la branche existe sur le remote
        Write-Host "🔍 Vérification branche distante..." -ForegroundColor Gray
        git fetch origin 2>$null
        
        $remoteBranches = git branch -r --list "origin/$TargetBranch"
        $remoteExists = $remoteBranches -ne $null -and $remoteBranches.Count -gt 0
        
        if ($remoteExists) {
            Write-Host "📡 Branche trouvée sur remote - Création locale..." -ForegroundColor Yellow
            git checkout -b $TargetBranch origin/$TargetBranch
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Branche créée et configurée depuis remote" -ForegroundColor Green
            } else {
                Write-Host "❌ Échec création branche depuis remote" -ForegroundColor Red
                exit 1
            }
            
        } else {
            Write-Host "🆕 Création nouvelle branche: $TargetBranch..." -ForegroundColor Yellow
            
            # Demander confirmation pour nouvelle branche
            if (-not $Force) {
                Write-Host "⚠️ Cette branche n'existe nulle part - elle sera créée" -ForegroundColor Yellow
                $createResponse = Read-Host "Créer la nouvelle branche $TargetBranch? [Y/n]"
                
                if ($createResponse -eq 'n' -or $createResponse -eq 'N') {
                    Write-Host "❌ Création de branche annulée" -ForegroundColor Red
                    exit 1
                }
            }
            
            git checkout -b $TargetBranch
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Nouvelle branche créée: $TargetBranch" -ForegroundColor Green
                
                # Optionnel: push de la nouvelle branche
                $pushResponse = Read-Host "Pousser la nouvelle branche vers remote? [Y/n]"
                if ($pushResponse -ne 'n' -and $pushResponse -ne 'N') {
                    git push -u origin $TargetBranch
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Branche poussée vers remote avec tracking" -ForegroundColor Green
                    } else {
                        Write-Host "⚠️ Échec push - la branche existe localement" -ForegroundColor Yellow
                    }
                }
                
            } else {
                Write-Host "❌ Échec création nouvelle branche" -ForegroundColor Red
                exit 1
            }
        }
        
    } else {
        Write-Host "❌ Branche n'existe pas et création non autorisée" -ForegroundColor Red
        Write-Host "💡 Utilisez -CreateIfNotExists pour créer automatiquement" -ForegroundColor Cyan
        exit 1
    }
}

# Vérification finale
$finalBranch = git branch --show-current
Write-Host ""
Write-Host "🎉 OPÉRATION TERMINÉE" -ForegroundColor Green
Write-Host "📍 Branche active: $finalBranch" -ForegroundColor Cyan
Write-Host "🎯 Branche attendue: $TargetBranch" -ForegroundColor Cyan

if ($finalBranch -eq $TargetBranch) {
    Write-Host "✅ SUCCÈS: Vous êtes maintenant sur la bonne branche!" -ForegroundColor Green
} else {
    Write-Host "❌ PROBLÈME: Branche actuelle ne correspond pas à la cible" -ForegroundColor Red
    exit 1
}