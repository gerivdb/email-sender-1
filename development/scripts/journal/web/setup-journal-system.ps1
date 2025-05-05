# Script PowerShell pour configurer l'ensemble du systÃƒÂ¨me de journal de bord RAG

# VÃƒÂ©rifier si le script est exÃƒÂ©cutÃƒÂ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Chemin absolu vers le rÃƒÂ©pertoire du projet
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

# Fonction pour exÃƒÂ©cuter une commande et afficher son rÃƒÂ©sultat
function Invoke-CommandWithOutput {
    param (
        [string]$Command,
        [string]$Arguments,
        [switch]$RequiresAdmin = $false
    )
    
    if ($RequiresAdmin -and -not $isAdmin) {
        Write-Host "Cette commande nÃƒÂ©cessite des privilÃƒÂ¨ges d'administrateur et sera ignorÃƒÂ©e:" -ForegroundColor Yellow
        Write-Host "  $Command $Arguments" -ForegroundColor Yellow
        return
    }
    
    Write-Host "ExÃƒÂ©cution de: $Command $Arguments" -ForegroundColor Gray
    
    try {
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Commande exÃƒÂ©cutÃƒÂ©e avec succÃƒÂ¨s." -ForegroundColor Green
        } else {
            Write-Host "La commande a ÃƒÂ©chouÃƒÂ© avec le code de sortie $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'exÃƒÂ©cution de la commande: $_" -ForegroundColor Red
    }
}

# Afficher un message d'introduction
Write-Host "Configuration du systÃƒÂ¨me de journal de bord RAG" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va configurer tous les aspects du systÃƒÂ¨me de journal de bord RAG:"
Write-Host "1. Installation des dÃƒÂ©pendances Python"
Write-Host "2. Configuration des tÃƒÂ¢ches planifiÃƒÂ©es"
Write-Host "3. Configuration de la surveillance des fichiers"
Write-Host "4. Configuration de l'intÃƒÂ©gration avec VS Code"
Write-Host ""

if (-not $isAdmin) {
    Write-Host "AVERTISSEMENT: Ce script n'est pas exÃƒÂ©cutÃƒÂ© en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host "Certaines fonctionnalitÃƒÂ©s nÃƒÂ©cessitant des privilÃƒÂ¨ges d'administrateur seront ignorÃƒÂ©es." -ForegroundColor Yellow
    Write-Host "Pour une installation complÃƒÂ¨te, exÃƒÂ©cutez ce script en tant qu'administrateur." -ForegroundColor Yellow
    Write-Host ""
    
    $continue = Read-Host "Voulez-vous continuer avec une installation partielle? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "Installation annulÃƒÂ©e." -ForegroundColor Red
        exit
    }
}

# 1. Installation des dÃƒÂ©pendances Python
Write-Section "Installation des dÃƒÂ©pendances Python"
Invoke-CommandWithOutput -Command "pip" -Arguments "install -r $PythonScriptsDir\requirements.txt"
Invoke-CommandWithOutput -Command "pip" -Arguments "install watchdog pywin32"

# 2. Configuration du systÃƒÂ¨me de base
Write-Section "Configuration du systÃƒÂ¨me de base"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\setup.py"

# 3. Configuration des tÃƒÂ¢ches planifiÃƒÂ©es
Write-Section "Configuration des tÃƒÂ¢ches planifiÃƒÂ©es"
if ($isAdmin) {
    Invoke-CommandWithOutput -Command "powershell" -Arguments "-File $CmdScriptsDir\setup-journal-tasks.ps1" -RequiresAdmin
} else {
    Write-Host "La configuration des tÃƒÂ¢ches planifiÃƒÂ©es nÃƒÂ©cessite des privilÃƒÂ¨ges d'administrateur." -ForegroundColor Yellow
    Write-Host "Pour configurer les tÃƒÂ¢ches planifiÃƒÂ©es, exÃƒÂ©cutez manuellement:" -ForegroundColor Yellow
    Write-Host "  powershell -File $CmdScriptsDir\setup-journal-tasks.ps1" -ForegroundColor Yellow
}

# 4. Configuration de la surveillance des fichiers
Write-Section "Configuration de la surveillance des fichiers"
if ($isAdmin) {
    Invoke-CommandWithOutput -Command "powershell" -Arguments "-File $CmdScriptsDir\setup-journal-watcher.ps1" -RequiresAdmin
} else {
    Write-Host "La configuration du service de surveillance nÃƒÂ©cessite des privilÃƒÂ¨ges d'administrateur." -ForegroundColor Yellow
    Write-Host "Pour configurer le service de surveillance, exÃƒÂ©cutez manuellement:" -ForegroundColor Yellow
    Write-Host "  powershell -File $CmdScriptsDir\setup-journal-watcher.ps1" -ForegroundColor Yellow
    
    # DÃƒÂ©marrer le watcher en mode non-service
    Write-Host "DÃƒÂ©marrage du watcher en mode non-service..." -ForegroundColor Cyan
    Start-Process -FilePath "python" -ArgumentList "$PythonScriptsDir\journal_watcher.py --background" -WindowStyle Hidden
}

# 5. CrÃƒÂ©ation d'une entrÃƒÂ©e de journal pour documenter l'installation
Write-Section "CrÃƒÂ©ation d'une entrÃƒÂ©e de journal pour documenter l'installation"
$date = Get-Date -Format "yyyy-MM-dd"
$installDetails = @"
## Installation du systÃƒÂ¨me de journal de bord RAG

Le systÃƒÂ¨me de journal de bord RAG a ÃƒÂ©tÃƒÂ© installÃƒÂ© et configurÃƒÂ© le $date.

### Composants installÃƒÂ©s:
- Scripts Python pour la crÃƒÂ©ation et la recherche d'entrÃƒÂ©es
- SystÃƒÂ¨me RAG simplifiÃƒÂ© pour l'interrogation du journal
- TÃƒÂ¢ches planifiÃƒÂ©es pour la crÃƒÂ©ation automatique d'entrÃƒÂ©es
- Surveillance des fichiers pour la mise ÃƒÂ  jour automatique des index
- IntÃƒÂ©gration avec VS Code pour faciliter l'utilisation

### FonctionnalitÃƒÂ©s disponibles:
- CrÃƒÂ©ation manuelle d'entrÃƒÂ©es via les scripts ou VS Code
- CrÃƒÂ©ation automatique d'entrÃƒÂ©es quotidiennes et hebdomadaires
- Recherche dans le journal par mots-clÃƒÂ©s, tags ou date
- Interrogation du systÃƒÂ¨me RAG pour obtenir des rÃƒÂ©ponses basÃƒÂ©es sur le contenu du journal
- Mise ÃƒÂ  jour automatique des index lors de modifications

### Utilisation:
- Via les scripts Python: `python development/scripts/python/journal/journal_entry.py "Titre"`
- Via PowerShell: `.\development\scripts\cmd\journal-rag.ps1 new`
- Via VS Code: Utiliser les tÃƒÂ¢ches configurÃƒÂ©es ou les raccourcis clavier
"@

Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_entry.py `"Installation du systÃƒÂ¨me de journal de bord RAG`" --tags installation rag journal"

# Afficher un message de conclusion
Write-Section "Installation terminÃƒÂ©e"
Write-Host "Le systÃƒÂ¨me de journal de bord RAG a ÃƒÂ©tÃƒÂ© configurÃƒÂ© avec succÃƒÂ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant utiliser le systÃƒÂ¨me de plusieurs faÃƒÂ§ons:"
Write-Host "1. Via les scripts Python:" -ForegroundColor Cyan
Write-Host "   python development/scripts/python/journal/journal_entry.py `"Titre de l'entrÃƒÂ©e`" --tags tag1 tag2"
Write-Host "   python development/scripts/python/journal/journal_search_simple.py --query `"votre recherche`""
Write-Host "   python development/scripts/python/journal/journal_rag_simple.py --query `"votre question`""
Write-Host ""
Write-Host "2. Via le script PowerShell:" -ForegroundColor Cyan
Write-Host "   .\development\scripts\cmd\journal-rag.ps1 new"
Write-Host "   .\development\scripts\cmd\journal-rag.ps1 search"
Write-Host "   .\development\scripts\cmd\journal-rag.ps1 query `"votre question`""
Write-Host ""
Write-Host "3. Via VS Code:" -ForegroundColor Cyan
Write-Host "   Utiliser les tÃƒÂ¢ches configurÃƒÂ©es dans le menu TÃƒÂ¢ches"
Write-Host "   Utiliser les raccourcis clavier (Ctrl+Alt+J suivi de D, W, N, S, R, Q)"
Write-Host ""
Write-Host "EntrÃƒÂ©es automatiques:" -ForegroundColor Cyan
Write-Host "   EntrÃƒÂ©e quotidienne: CrÃƒÂ©ÃƒÂ©e automatiquement chaque jour ÃƒÂ  09:00"
Write-Host "   EntrÃƒÂ©e hebdomadaire: CrÃƒÂ©ÃƒÂ©e automatiquement chaque lundi ÃƒÂ  08:00"
Write-Host ""
Write-Host "Surveillance des fichiers:" -ForegroundColor Cyan
Write-Host "   Les index sont automatiquement mis ÃƒÂ  jour lorsque des fichiers du journal sont modifiÃƒÂ©s"
Write-Host ""
Write-Host "Profitez de votre systÃƒÂ¨me de journal de bord RAG!" -ForegroundColor Magenta
