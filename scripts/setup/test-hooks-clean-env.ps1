# Script pour tester les hooks Git dans un environnement sans espaces
# Ce script clone le dépôt dans un répertoire temporaire sans espaces et teste les hooks Git

param (
    [Parameter(Mandatory = $false)]
    [switch]$CleanupAfter,
    
    [Parameter(Mandatory = $false)]
    [string]$TempDir = "C:\Temp\n8n_test_hooks",
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Fonction pour afficher un message verbose
function Write-VerboseMessage {
    param (
        [string]$Message
    )
    
    if ($Verbose) {
        Write-ColorMessage $Message -ForegroundColor "Gray"
    }
}

# Obtenir le chemin racine du projet actuel
$currentProjectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Write-ColorMessage "Projet actuel: $currentProjectRoot" -ForegroundColor "Cyan"

# Vérifier si le répertoire temporaire existe déjà
if (Test-Path $TempDir) {
    Write-ColorMessage "Le répertoire temporaire $TempDir existe déjà." -ForegroundColor "Yellow"
    $confirmation = Read-Host "Voulez-vous le supprimer et le recréer? (O/N)"
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        Write-ColorMessage "Suppression du répertoire temporaire..." -ForegroundColor "Yellow"
        Remove-Item -Path $TempDir -Recurse -Force
    }
    else {
        Write-ColorMessage "Utilisation du répertoire temporaire existant." -ForegroundColor "Yellow"
    }
}

# Créer le répertoire temporaire s'il n'existe pas
if (-not (Test-Path $TempDir)) {
    Write-ColorMessage "Création du répertoire temporaire $TempDir..." -ForegroundColor "Cyan"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Obtenir l'URL du dépôt distant
Write-ColorMessage "Obtention de l'URL du dépôt distant..." -ForegroundColor "Cyan"
$remoteUrl = git -C $currentProjectRoot remote get-url origin
Write-ColorMessage "URL du dépôt distant: $remoteUrl" -ForegroundColor "White"

# Cloner le dépôt dans le répertoire temporaire
Write-ColorMessage "Clonage du dépôt dans le répertoire temporaire..." -ForegroundColor "Cyan"
git clone $remoteUrl $TempDir

# Vérifier si le clonage a réussi
if ($LASTEXITCODE -ne 0) {
    Write-ColorMessage "Erreur lors du clonage du dépôt." -ForegroundColor "Red"
    exit 1
}

# Se déplacer dans le répertoire temporaire
Set-Location $TempDir
Write-ColorMessage "Répertoire de travail actuel: $(Get-Location)" -ForegroundColor "White"

# Installer les hooks Git
Write-ColorMessage "Installation des hooks Git..." -ForegroundColor "Cyan"
$installScript = Join-Path $TempDir "scripts\setup\install-git-hooks.ps1"

if (Test-Path $installScript) {
    & $installScript -Force
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorMessage "Erreur lors de l'installation des hooks Git." -ForegroundColor "Red"
        exit 1
    }
}
else {
    Write-ColorMessage "Script d'installation des hooks Git non trouvé: $installScript" -ForegroundColor "Red"
    exit 1
}

# Créer un fichier de test
Write-ColorMessage "Création d'un fichier de test..." -ForegroundColor "Cyan"
$testFile = Join-Path $TempDir "test-file.txt"
Set-Content -Path $testFile -Value "Ceci est un fichier de test créé le $(Get-Date)"

# Ajouter le fichier au dépôt
Write-ColorMessage "Ajout du fichier au dépôt..." -ForegroundColor "Cyan"
git add $testFile

# Tester le hook pre-commit
Write-ColorMessage "Test du hook pre-commit..." -ForegroundColor "Cyan"
$commitOutput = git commit -m "Test du hook pre-commit" 2>&1

# Vérifier si le commit a réussi
if ($LASTEXITCODE -eq 0) {
    Write-ColorMessage "Le hook pre-commit a été exécuté avec succès." -ForegroundColor "Green"
    Write-ColorMessage "Sortie du commit:" -ForegroundColor "White"
    $commitOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
}
else {
    Write-ColorMessage "Erreur lors de l'exécution du hook pre-commit." -ForegroundColor "Red"
    Write-ColorMessage "Sortie du commit:" -ForegroundColor "Red"
    $commitOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "Red" }
    
    # Essayer avec --no-verify pour voir si c'est bien le hook qui pose problème
    Write-ColorMessage "Tentative de commit avec --no-verify..." -ForegroundColor "Yellow"
    $commitNoVerifyOutput = git commit --no-verify -m "Test du hook pre-commit (no-verify)" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorMessage "Le commit a réussi avec --no-verify, ce qui confirme que le problème vient du hook." -ForegroundColor "Yellow"
    }
    else {
        Write-ColorMessage "Le commit a échoué même avec --no-verify, ce qui suggère un autre problème." -ForegroundColor "Red"
    }
}

# Tester le hook pre-push (si le commit a réussi)
if ($LASTEXITCODE -eq 0) {
    Write-ColorMessage "Test du hook pre-push..." -ForegroundColor "Cyan"
    
    # Créer une branche temporaire pour le test
    $testBranch = "test-hooks-$(Get-Date -Format 'yyyyMMddHHmmss')"
    git checkout -b $testBranch
    
    # Essayer de pousser la branche
    $pushOutput = git push --set-upstream origin $testBranch 2>&1
    
    # Vérifier si le push a réussi
    if ($LASTEXITCODE -eq 0) {
        Write-ColorMessage "Le hook pre-push a été exécuté avec succès." -ForegroundColor "Green"
        Write-ColorMessage "Sortie du push:" -ForegroundColor "White"
        $pushOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        # Supprimer la branche distante
        Write-ColorMessage "Suppression de la branche distante..." -ForegroundColor "Cyan"
        git push origin --delete $testBranch
    }
    else {
        Write-ColorMessage "Erreur lors de l'exécution du hook pre-push." -ForegroundColor "Red"
        Write-ColorMessage "Sortie du push:" -ForegroundColor "Red"
        $pushOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "Red" }
        
        # Essayer avec --no-verify pour voir si c'est bien le hook qui pose problème
        Write-ColorMessage "Tentative de push avec --no-verify..." -ForegroundColor "Yellow"
        $pushNoVerifyOutput = git push --no-verify --set-upstream origin $testBranch 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "Le push a réussi avec --no-verify, ce qui confirme que le problème vient du hook." -ForegroundColor "Yellow"
            
            # Supprimer la branche distante
            Write-ColorMessage "Suppression de la branche distante..." -ForegroundColor "Cyan"
            git push origin --delete $testBranch
        }
        else {
            Write-ColorMessage "Le push a échoué même avec --no-verify, ce qui suggère un autre problème." -ForegroundColor "Red"
        }
    }
}

# Nettoyer si demandé
if ($CleanupAfter) {
    Write-ColorMessage "Nettoyage du répertoire temporaire..." -ForegroundColor "Cyan"
    Set-Location $currentProjectRoot
    Remove-Item -Path $TempDir -Recurse -Force
    Write-ColorMessage "Répertoire temporaire supprimé." -ForegroundColor "Green"
}
else {
    Write-ColorMessage "Le répertoire temporaire $TempDir a été conservé pour inspection." -ForegroundColor "Yellow"
    Write-ColorMessage "N'oubliez pas de le supprimer manuellement lorsque vous avez terminé." -ForegroundColor "Yellow"
}

# Revenir au répertoire du projet
Set-Location $currentProjectRoot
Write-ColorMessage "Retour au répertoire du projet: $currentProjectRoot" -ForegroundColor "Cyan"

# Afficher un résumé
Write-ColorMessage "`nRésumé des tests:" -ForegroundColor "Cyan"
Write-ColorMessage "- Répertoire de test: $TempDir" -ForegroundColor "White"
Write-ColorMessage "- Hook pre-commit: $(if ($LASTEXITCODE -eq 0) { 'Succès' } else { 'Échec' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" })
Write-ColorMessage "- Hook pre-push: $(if ($LASTEXITCODE -eq 0) { 'Succès' } else { 'Échec' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" })

# Afficher l'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\test-hooks-clean-env.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CleanupAfter    Supprimer le répertoire temporaire après les tests" -ForegroundColor "Cyan"
    Write-ColorMessage "  -TempDir <path>  Spécifier un répertoire temporaire personnalisé" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose         Afficher des informations détaillées" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\test-hooks-clean-env.ps1" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\test-hooks-clean-env.ps1 -CleanupAfter" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\test-hooks-clean-env.ps1 -TempDir D:\Temp\n8n_test" -ForegroundColor "Cyan"
}
