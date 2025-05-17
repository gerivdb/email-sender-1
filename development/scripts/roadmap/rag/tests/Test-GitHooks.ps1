#Requires -Version 5.1
<#
.SYNOPSIS
    Teste l'intégration avec Git hooks.
.DESCRIPTION
    Ce script teste l'enregistrement et le fonctionnement des hooks Git
    pour la détection des modifications des fichiers Markdown.
.NOTES
    Nom: Test-GitHooks.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
#>

# Chemin du script d'enregistrement des hooks Git
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$registerScriptPath = Join-Path -Path $scriptPath -ChildPath "..\watcher\Register-GitHooks.ps1"

if (-not (Test-Path -Path $registerScriptPath)) {
    Write-Error "Script d'enregistrement des hooks Git non trouvé: $registerScriptPath"
    exit 1
}

# Vérifier que Git est disponible
try {
    $gitVersion = git --version
    Write-Host "Git détecté: $gitVersion" -ForegroundColor Green
} catch {
    Write-Error "Git n'est pas disponible. Veuillez installer Git et l'ajouter au PATH."
    exit 1
}

# Créer un dépôt Git temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "GitHooksTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Write-Host "Répertoire de test: $testDir" -ForegroundColor Cyan

# Initialiser le dépôt Git
Push-Location $testDir
try {
    git init
    Write-Host "Dépôt Git initialisé" -ForegroundColor Green
    
    # Créer un fichier Markdown de test
    $testFilePath = Join-Path -Path $testDir -ChildPath "test.md"
    @"
# Test
- [ ] **1.1** Tâche 1
- [ ] **1.2** Tâche 2
"@ | Set-Content -Path $testFilePath -Encoding UTF8
    Write-Host "Fichier de test créé: $testFilePath" -ForegroundColor Green
    
    # Ajouter le fichier au dépôt Git
    git add .
    git config --local user.email "test@example.com"
    git config --local user.name "Test User"
    git commit -m "Initial commit"
    Write-Host "Premier commit effectué" -ForegroundColor Green
    
    # Enregistrer les hooks Git
    & $registerScriptPath -RepositoryPath $testDir -Force
    Write-Host "Hooks Git enregistrés" -ForegroundColor Green
    
    # Vérifier que les hooks ont été créés
    $hooksDir = Join-Path -Path $testDir -ChildPath ".git\hooks"
    $hookTypes = @("post-commit", "post-merge", "post-checkout")
    $hooksCreated = $true
    
    foreach ($hookType in $hookTypes) {
        $hookPath = Join-Path -Path $hooksDir -ChildPath $hookType
        
        if (Test-Path -Path $hookPath) {
            Write-Host "Hook $hookType créé: $hookPath" -ForegroundColor Green
        } else {
            Write-Host "Erreur: Hook $hookType non créé" -ForegroundColor Red
            $hooksCreated = $false
        }
    }
    
    if ($hooksCreated) {
        Write-Host "Test réussi: Tous les hooks Git ont été correctement créés" -ForegroundColor Green
    } else {
        Write-Host "Test échoué: Certains hooks Git n'ont pas été créés" -ForegroundColor Red
    }
    
    # Tester le déclenchement d'un hook
    Write-Host "Test du déclenchement d'un hook..." -ForegroundColor Yellow
    
    # Modifier le fichier de test
    @"
# Test
- [ ] **1.1** Tâche 1
- [x] **1.2** Tâche 2
- [ ] **1.3** Nouvelle tâche
"@ | Set-Content -Path $testFilePath -Encoding UTF8
    
    # Committer les modifications
    git add .
    git commit -m "Modification du fichier de test"
    Write-Host "Modifications committées" -ForegroundColor Green
    
    # Vérifier que le hook a été déclenché
    # Note: Dans un environnement réel, nous vérifierions les logs ou les effets du hook
    Write-Host "Note: Dans un environnement réel, nous vérifierions les logs ou les effets du hook" -ForegroundColor Yellow
    Write-Host "Test de déclenchement du hook terminé" -ForegroundColor Green
} finally {
    # Revenir au répertoire d'origine
    Pop-Location
    
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Write-Host "Nettoyage des fichiers de test..." -ForegroundColor Yellow
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
