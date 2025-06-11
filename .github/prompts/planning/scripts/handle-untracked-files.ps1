# Script de gestion des fichiers non suivis
# handle-untracked-files.ps1

[CmdletBinding()]
param(
    [switch]$AutoCommit = $false,
    [switch]$DryRun = $false
)

Write-Host "🔍 GESTION DES FICHIERS NON SUIVIS" -ForegroundColor Cyan

# Obtenir la liste des fichiers non suivis
$untrackedFiles = git status --porcelain | Where-Object { $_ -match "^\?\?" }

if ($untrackedFiles.Count -eq 0) {
    Write-Host "✅ Aucun fichier non suivi détecté" -ForegroundColor Green
    return
}

Write-Host "📁 Fichiers non suivis détectés: $($untrackedFiles.Count)" -ForegroundColor Yellow

# Créer hashtable pour regrouper par domaine
$domainGroups = @{}

foreach ($file in $untrackedFiles) {
    $filePath = $file.Substring(3)  # Enlever "?? "
    
    # Déterminer domaine thématique
    $domain = switch -Regex ($filePath) {
        "^tools/" { "sync-tools" }
        "^config/" { "configuration" }
        "^docs/" { "documentation" }
        "^tests/" { "testing" }
        "^scripts/" { "automation" }
        "^web/" { "interface" }
        "\.ps1$" { "powershell-scripts" }
        "\.go$" { "core-development" }
        "\.md$" { "documentation" }
        "^\.github/" { "github-workflows" }
        "^planning-ecosystem-sync/" { "planning-sync" }
        "^projet/roadmaps/plans/" { "planning-documents" }
        default { "miscellaneous" }
    }
    
    if (-not $domainGroups.ContainsKey($domain)) {
        $domainGroups[$domain] = @()
    }
    $domainGroups[$domain] += $filePath
    
    Write-Host "  📄 $filePath → $domain" -ForegroundColor Yellow
}

# Afficher résumé par domaine
Write-Host "`n📊 RÉSUMÉ PAR DOMAINE:" -ForegroundColor Cyan
foreach ($domain in $domainGroups.Keys | Sort-Object) {
    $fileCount = $domainGroups[$domain].Count
    Write-Host "  🎯 $domain : $fileCount fichiers" -ForegroundColor White
}

# Proposer commits thématiques
Write-Host "`n💡 COMMITS THÉMATIQUES SUGGÉRÉS:" -ForegroundColor Cyan
foreach ($domain in $domainGroups.Keys | Sort-Object) {
    $files = $domainGroups[$domain]
    Write-Host "`n  🎯 Domaine: $domain ($($files.Count) fichiers)" -ForegroundColor White
    Write-Host "     Fichiers: $($files -join ', ')" -ForegroundColor Gray
    
    if ($DryRun) {
        Write-Host "     [DRY RUN] git add $($files -join ' ')" -ForegroundColor Magenta
        Write-Host "     [DRY RUN] git commit -m 'feat($domain): add untracked files for plan-dev-v55'" -ForegroundColor Magenta
    } else {
        Write-Host "     git add $($files -join ' ')" -ForegroundColor Gray
        Write-Host "     git commit -m 'feat($domain): add untracked files for plan-dev-v55'" -ForegroundColor Gray
    }
}

if ($DryRun) {
    Write-Host "`n🧪 MODE DRY RUN - Aucune modification effectuée" -ForegroundColor Magenta
    return
}

# Demander confirmation ou commit automatique
if ($AutoCommit) {
    $proceed = $true
    Write-Host "`n🤖 MODE AUTO-COMMIT activé" -ForegroundColor Green
} else {
    Write-Host ""
    $response = Read-Host "Effectuer les commits automatiquement? [y/N]"
    $proceed = ($response -eq 'y' -or $response -eq 'Y' -or $response -eq 'yes')
}

if ($proceed) {
    Write-Host "`n🚀 EXÉCUTION DES COMMITS..." -ForegroundColor Green
    
    foreach ($domain in $domainGroups.Keys | Sort-Object) {
        $files = $domainGroups[$domain]
        
        Write-Host "  📦 Commit domaine: $domain..." -ForegroundColor Yellow
        
        # Ajouter les fichiers
        git add $files
        
        # Créer le commit
        $commitMessage = @"
feat($domain): add untracked files for plan-dev-v55

- Added $($files.Count) files in $domain domain
- Files: $($files -join ', ')
- Part of planning ecosystem synchronization implementation

Refs: plan-dev-v55-planning-ecosystem-sync.md
"@
        
        git commit -m $commitMessage
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✅ Commit réussi pour $domain" -ForegroundColor Green
        } else {
            Write-Host "    ❌ Échec commit pour $domain" -ForegroundColor Red
        }
    }
    
    Write-Host "`n🎉 TOUS LES COMMITS TERMINÉS" -ForegroundColor Green
    
    # Afficher résumé final
    $totalCommits = $domainGroups.Keys.Count
    $totalFiles = ($domainGroups.Values | Measure-Object -Sum Count).Sum
    
    Write-Host "📊 RÉSUMÉ FINAL:" -ForegroundColor Cyan
    Write-Host "  • Commits créés: $totalCommits" -ForegroundColor White
    Write-Host "  • Fichiers traités: $totalFiles" -ForegroundColor White
    Write-Host "  • Branche: $(git branch --show-current)" -ForegroundColor White
    
} else {
    Write-Host "`n❌ Opération annulée par l'utilisateur" -ForegroundColor Yellow
    Write-Host "💡 Vous pouvez traiter les fichiers manuellement avec les commandes affichées ci-dessus" -ForegroundColor Cyan
}