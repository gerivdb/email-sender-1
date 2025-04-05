# Script PowerShell pour configurer l'ensemble du système de journal de bord RAG

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$ScriptsDir = Join-Path $ProjectDir "scripts"
$PythonScriptsDir = Join-Path $ScriptsDir "python\journal"
$CmdScriptsDir = Join-Path $ScriptsDir "cmd"

# Fonction pour afficher un message de section
function Write-Section {
    param (
        [string]$Title
    )
    
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Fonction pour exécuter une commande et afficher son résultat
function Invoke-CommandWithOutput {
    param (
        [string]$Command,
        [string]$Arguments,
        [switch]$RequiresAdmin = $false
    )
    
    if ($RequiresAdmin -and -not $isAdmin) {
        Write-Host "Cette commande nécessite des privilèges d'administrateur et sera ignorée:" -ForegroundColor Yellow
        Write-Host "  $Command $Arguments" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Exécution de: $Command $Arguments" -ForegroundColor Gray
    
    try {
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Commande exécutée avec succès." -ForegroundColor Green
        } else {
            Write-Host "La commande a échoué avec le code de sortie $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'exécution de la commande: $_" -ForegroundColor Red
    }
}

# Afficher un message d'introduction
Write-Host "Configuration du système de journal de bord RAG" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va configurer tous les aspects du système de journal de bord RAG:"
Write-Host "1. Installation des dépendances Python"
Write-Host "2. Configuration des tâches planifiées"
Write-Host "3. Configuration de la surveillance des fichiers"
Write-Host "4. Configuration de l'intégration avec VS Code"
Write-Host ""

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exécuté en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalités nécessitant des privilèges d'administrateur seront ignorées." -ForegroundColor Yellow
    Write-Host "Pour une installation complète, exécutez ce script en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host ""
    
    $continue = Read-Host "Voulez-vous continuer avec une installation partielle? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "Installation annulée." -ForegroundColor Red
        exit
    }
}

# 1. Installation des dépendances Python
Write-Section "Installation des dépendances Python"
Invoke-CommandWithOutput -Command "pip" -Arguments "install -r $PythonScriptsDir\requirements.txt"
Invoke-CommandWithOutput -Command "pip" -Arguments "install watchdog pywin32"

# 2. Configuration du système de base
Write-Section "Configuration du système de base"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\setup.py"

# 3. Configuration des tâches planifiées
Write-Section "Configuration des tâches planifiées"
if ($isAdmin) {
    Invoke-CommandWithOutput -Command "powershell" -Arguments "-File $CmdScriptsDir\setup-journal-tasks.ps1" -RequiresAdmin
} else {
    Write-Host "La configuration des tâches planifiées nécessite des privilèges d'administrateur." -ForegroundColor Yellow
    Write-Host "Pour configurer les tâches planifiées, exécutez manuellement:" -ForegroundColor Yellow
    Write-Host "  powershell -File $CmdScriptsDir\setup-journal-tasks.ps1" -ForegroundColor Yellow
}

# 4. Configuration de la surveillance des fichiers
Write-Section "Configuration de la surveillance des fichiers"
if ($isAdmin) {
    Invoke-CommandWithOutput -Command "powershell" -Arguments "-File $CmdScriptsDir\setup-journal-watcher.ps1" -RequiresAdmin
} else {
    Write-Host "La configuration du service de surveillance nécessite des privilèges d'administrateur." -ForegroundColor Yellow
    Write-Host "Pour configurer le service de surveillance, exécutez manuellement:" -ForegroundColor Yellow
    Write-Host "  powershell -File $CmdScriptsDir\setup-journal-watcher.ps1" -ForegroundColor Yellow
    
    # Démarrer le watcher en mode non-service
    Write-Host "Démarrage du watcher en mode non-service..." -ForegroundColor Cyan
    Start-Process -FilePath "python" -ArgumentList "$PythonScriptsDir\journal_watcher.py --background" -WindowStyle Hidden
}

# 5. Création d'une entrée de journal pour documenter l'installation
Write-Section "Création d'une entrée de journal pour documenter l'installation"
$date = Get-Date -Format "yyyy-MM-dd"
$installDetails = @"
## Installation du système de journal de bord RAG

Le système de journal de bord RAG a été installé et configuré le $date.

### Composants installés:
- Scripts Python pour la création et la recherche d'entrées
- Système RAG simplifié pour l'interrogation du journal
- Tâches planifiées pour la création automatique d'entrées
- Surveillance des fichiers pour la mise à jour automatique des index
- Intégration avec VS Code pour faciliter l'utilisation

### Fonctionnalités disponibles:
- Création manuelle d'entrées via les scripts ou VS Code
- Création automatique d'entrées quotidiennes et hebdomadaires
- Recherche dans le journal par mots-clés, tags ou date
- Interrogation du système RAG pour obtenir des réponses basées sur le contenu du journal
- Mise à jour automatique des index lors de modifications

### Utilisation:
- Via les scripts Python: `python scripts/python/journal/journal_entry.py "Titre"`
- Via PowerShell: `.\scripts\cmd\journal-rag.ps1 new`
- Via VS Code: Utiliser les tâches configurées ou les raccourcis clavier
"@

Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_entry.py `"Installation du système de journal de bord RAG`" --tags installation rag journal"

# Afficher un message de conclusion
Write-Section "Installation terminée"
Write-Host "Le système de journal de bord RAG a été configuré avec succès!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant utiliser le système de plusieurs façons:"
Write-Host "1. Via les scripts Python:" -ForegroundColor Cyan
Write-Host "   python scripts/python/journal/journal_entry.py `"Titre de l'entrée`" --tags tag1 tag2"
Write-Host "   python scripts/python/journal/journal_search_simple.py --query `"votre recherche`""
Write-Host "   python scripts/python/journal/journal_rag_simple.py --query `"votre question`""
Write-Host ""
Write-Host "2. Via le script PowerShell:" -ForegroundColor Cyan
Write-Host "   .\scripts\cmd\journal-rag.ps1 new"
Write-Host "   .\scripts\cmd\journal-rag.ps1 search"
Write-Host "   .\scripts\cmd\journal-rag.ps1 query `"votre question`""
Write-Host ""
Write-Host "3. Via VS Code:" -ForegroundColor Cyan
Write-Host "   Utiliser les tâches configurées dans le menu Tâches"
Write-Host "   Utiliser les raccourcis clavier (Ctrl+Alt+J suivi de D, W, N, S, R, Q)"
Write-Host ""
Write-Host "Entrées automatiques:" -ForegroundColor Cyan
Write-Host "   Entrée quotidienne: Créée automatiquement chaque jour à 09:00"
Write-Host "   Entrée hebdomadaire: Créée automatiquement chaque lundi à 08:00"
Write-Host ""
Write-Host "Surveillance des fichiers:" -ForegroundColor Cyan
Write-Host "   Les index sont automatiquement mis à jour lorsque des fichiers du journal sont modifiés"
Write-Host ""
Write-Host "Profitez de votre système de journal de bord RAG!" -ForegroundColor Magenta
