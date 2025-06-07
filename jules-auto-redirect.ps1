# =============================================================================
# Script automatique de redirection des contributions Jules
# A executer regulierement pour nettoyer et organiser
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

Write-Host "=== REDIRECTION AUTOMATIQUE CONTRIBUTIONS JULES ===" -ForegroundColor Cyan
Write-Host "Mode: $(if($DryRun){'DRY RUN'}else{'EXECUTION'})" -ForegroundColor $(if($DryRun){'Yellow'}else{'Green'})
Write-Host ""

$protectedBranches = @('main', 'dev', 'contextual-memory', 'jules-google')
$redirectCount = 0

# Rechercher les branches qui ne sont pas sous jules-google/* mais creees par le bot
$allBranches = git branch -r --format='%(refname:short)' | Where-Object { 
    $_ -notmatch '^origin/(main|dev|jules-google|contextual-memory)' -and 
    $_ -notmatch '^origin/jules-google/' 
}

foreach ($branch in $allBranches) {
    if ($branch -match '^origin/(.+)') {
        $branchName = $matches[1]
        
        if ($Verbose) {
            Write-Host "Verification branche: $branchName" -ForegroundColor Gray
        }
        
        # Verifier si c'est une contribution Jules (via commit author)
        $lastCommitAuthor = git log --format='%an' "$branch" -1 2>$null
        
        if ($lastCommitAuthor -match 'google-labs-jules.*bot') {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $newBranchName = "jules-google/auto-redirect-$timestamp-$branchName"
            
            Write-Host "Detection contribution Jules: $branchName -> $newBranchName" -ForegroundColor Yellow
            
            if (-not $DryRun) {
                try {
                    # Creer la nouvelle branche
                    git checkout -b "$newBranchName" "$branch" 2>$null
                    git push origin "$newBranchName" 2>$null
                    
                    # Supprimer l'ancienne (seulement si pas protegee)
                    if ($branchName -notin $protectedBranches) {
                        git push origin --delete "$branchName" 2>$null
                    }
                    
                    Write-Host "  ✓ Redirige: $newBranchName" -ForegroundColor Green
                    $redirectCount++
                }
                catch {
                    Write-Host "  ✗ Erreur redirection: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "  → DryRun: $newBranchName" -ForegroundColor Cyan
                $redirectCount++
            }
        }
    }
}

Write-Host ""
if ($redirectCount -eq 0) {
    Write-Host "Aucune contribution Jules a rediriger." -ForegroundColor Green
} else {
    Write-Host "Redirections $(if($DryRun){'simulees'}else{'effectuees'}): $redirectCount" -ForegroundColor $(if($DryRun){'Yellow'}else{'Green'})
}
