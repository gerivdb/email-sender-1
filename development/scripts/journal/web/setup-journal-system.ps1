# Script PowerShell pour configurer l'ensemble du systÃ¨me de journal de bord RAG

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃ©pertoire du projet
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

# Fonction pour exÃ©cuter une commande et afficher son rÃ©sultat
function Invoke-CommandWithOutput {
    param (
        [string]$Command,
        [string]$Arguments,
        [switch]$RequiresAdmin = $false
    )
    
    if ($RequiresAdmin -and -not $isAdmin) {
        Write-Host "Cette commande nÃ©cessite des privilÃ¨ges d'administrateur et sera ignorÃ©e:" -ForegroundColor Yellow
        Write-Host "  $Command $Arguments" -ForegroundColor Yellow
        return
    }
    
    Write-Host "ExÃ©cution de: $Command $Arguments" -ForegroundColor Gray
    
    try {
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Commande exÃ©cutÃ©e avec succÃ¨s." -ForegroundColor Green
        } else {
            Write-Host "La commande a Ã©chouÃ© avec le code de sortie $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'exÃ©cution de la commande: $_" -ForegroundColor Red
    }
}

# Afficher un message d'introduction
Write-Host "Configuration du systÃ¨me de journal de bord RAG" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va configurer tous les aspects du systÃ¨me de journal de bord RAG:"
Write-Host "1. Installation des dÃ©pendances Python"
Write-Host "2. Configuration des tÃ¢ches planifiÃ©es"
Write-Host "3. Configuration de la surveillance des fichiers"
Write-Host "4. Configuration de l'intÃ©gration avec VS Code"
Write-Host ""

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exÃ©cutÃ© en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalitÃ©s nÃ©cessitant des privilÃ¨ges d'administrateur seront ignorÃ©es." -ForegroundColor Yellow
    Write-Host "Pour une installation complÃ¨te, exÃ©cutez ce script en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host ""
    
    $continue = Read-Host "Voulez-vous continuer avec une installation partielle? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "Installation annulÃ©e." -ForegroundColor Red
        exit
    }
}

# 1. Installation des dÃ©pendances Python
Write-Section "Installation des dÃ©pendances Python"
Invoke-CommandWithOutput -Command "pip" -Arguments "install -r $PythonScriptsDir\requirements.txt"
Invoke-CommandWithOutput -Command "pip" -Arguments "install watchdog pywin32"

# 2. Configuration du systÃ¨me de base
Write-Section "Configuration du systÃ¨me de base"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\setup.py"

# 3. Configuration des tÃ¢ches planifiÃ©es
Write-Section "Configuration des tÃ¢ches planifiÃ©es"
if ($isAdmin) {
    Invoke-CommandWithOutput -Command "powershell" -Arguments "-File $CmdScriptsDir\setup-journal-tasks.ps1" -RequiresAdmin
} else {
    Write-Host "La configuration des tÃ¢ches planifiÃ©es nÃ©cessite des privilÃ¨ges d'administrateur." -ForegroundColor Yellow
    Write-Host "Pour configurer les tÃ¢ches planifiÃ©es, exÃ©cutez manuellement:" -ForegroundColor Yellow
    Write-Host "  powershell -File $CmdScriptsDir\setup-journal-tasks.ps1" -ForegroundColor Yellow
}

# 4. Configuration de la surveillance des fichiers
Write-Section "Configuration de la surveillance des fichiers"
if ($isAdmin) {
    Invoke-CommandWithOutput -Command "powershell" -Arguments "-File $CmdScriptsDir\setup-journal-watcher.ps1" -RequiresAdmin
} else {
    Write-Host "La configuration du service de surveillance nÃ©cessite des privilÃ¨ges d'administrateur." -ForegroundColor Yellow
    Write-Host "Pour configurer le service de surveillance, exÃ©cutez manuellement:" -ForegroundColor Yellow
    Write-Host "  powershell -File $CmdScriptsDir\setup-journal-watcher.ps1" -ForegroundColor Yellow
    
    # DÃ©marrer le watcher en mode non-service
    Write-Host "DÃ©marrage du watcher en mode non-service..." -ForegroundColor Cyan
    Start-Process -FilePath "python" -ArgumentList "$PythonScriptsDir\journal_watcher.py --background" -WindowStyle Hidden
}

# 5. CrÃ©ation d'une entrÃ©e de journal pour documenter l'installation
Write-Section "CrÃ©ation d'une entrÃ©e de journal pour documenter l'installation"
$date = Get-Date -Format "yyyy-MM-dd"
$installDetails = @"
## Installation du systÃ¨me de journal de bord RAG

Le systÃ¨me de journal de bord RAG a Ã©tÃ© installÃ© et configurÃ© le $date.

### Composants installÃ©s:
- Scripts Python pour la crÃ©ation et la recherche d'entrÃ©es
- SystÃ¨me RAG simplifiÃ© pour l'interrogation du journal
- TÃ¢ches planifiÃ©es pour la crÃ©ation automatique d'entrÃ©es
- Surveillance des fichiers pour la mise Ã  jour automatique des index
- IntÃ©gration avec VS Code pour faciliter l'utilisation

### FonctionnalitÃ©s disponibles:
- CrÃ©ation manuelle d'entrÃ©es via les scripts ou VS Code
- CrÃ©ation automatique d'entrÃ©es quotidiennes et hebdomadaires
- Recherche dans le journal par mots-clÃ©s, tags ou date
- Interrogation du systÃ¨me RAG pour obtenir des rÃ©ponses basÃ©es sur le contenu du journal
- Mise Ã  jour automatique des index lors de modifications

### Utilisation:
- Via les scripts Python: `python development/scripts/python/journal/journal_entry.py "Titre"`
- Via PowerShell: `.\development\scripts\cmd\journal-rag.ps1 new`
- Via VS Code: Utiliser les tÃ¢ches configurÃ©es ou les raccourcis clavier
"@

Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_entry.py `"Installation du systÃ¨me de journal de bord RAG`" --tags installation rag journal"

# Afficher un message de conclusion
Write-Section "Installation terminÃ©e"
Write-Host "Le systÃ¨me de journal de bord RAG a Ã©tÃ© configurÃ© avec succÃ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant utiliser le systÃ¨me de plusieurs faÃ§ons:"
Write-Host "1. Via les scripts Python:" -ForegroundColor Cyan
Write-Host "   python development/scripts/python/journal/journal_entry.py `"Titre de l'entrÃ©e`" --tags tag1 tag2"
Write-Host "   python development/scripts/python/journal/journal_search_simple.py --query `"votre recherche`""
Write-Host "   python development/scripts/python/journal/journal_rag_simple.py --query `"votre question`""
Write-Host ""
Write-Host "2. Via le script PowerShell:" -ForegroundColor Cyan
Write-Host "   .\development\scripts\cmd\journal-rag.ps1 new"
Write-Host "   .\development\scripts\cmd\journal-rag.ps1 search"
Write-Host "   .\development\scripts\cmd\journal-rag.ps1 query `"votre question`""
Write-Host ""
Write-Host "3. Via VS Code:" -ForegroundColor Cyan
Write-Host "   Utiliser les tÃ¢ches configurÃ©es dans le menu TÃ¢ches"
Write-Host "   Utiliser les raccourcis clavier (Ctrl+Alt+J suivi de D, W, N, S, R, Q)"
Write-Host ""
Write-Host "EntrÃ©es automatiques:" -ForegroundColor Cyan
Write-Host "   EntrÃ©e quotidienne: CrÃ©Ã©e automatiquement chaque jour Ã  09:00"
Write-Host "   EntrÃ©e hebdomadaire: CrÃ©Ã©e automatiquement chaque lundi Ã  08:00"
Write-Host ""
Write-Host "Surveillance des fichiers:" -ForegroundColor Cyan
Write-Host "   Les index sont automatiquement mis Ã  jour lorsque des fichiers du journal sont modifiÃ©s"
Write-Host ""
Write-Host "Profitez de votre systÃ¨me de journal de bord RAG!" -ForegroundColor Magenta
