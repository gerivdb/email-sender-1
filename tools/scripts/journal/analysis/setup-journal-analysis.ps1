# Script PowerShell pour configurer et exÃ©cuter l'analyse du journal de bord

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section

# Script PowerShell pour configurer et exÃ©cuter l'analyse du journal de bord

# Chemin absolu vers le rÃ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section
function Write-Section {
    param (
        [string]$Title
    )

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Afficher un message d'introduction
Write-Host "Configuration et exÃ©cution de l'analyse du journal de bord" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Installer les dÃ©pendances Python
Write-Section "Installation des dÃ©pendances Python"
pip install numpy pandas matplotlib wordcloud scikit-learn

# 2. CrÃ©er les rÃ©pertoires nÃ©cessaires
Write-Section "CrÃ©ation des rÃ©pertoires"
$AnalysisDir = Join-Path $ProjectDir "docs\journal_de_bord\analysis"
New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
Write-Host "RÃ©pertoire d'analyse crÃ©Ã©: $AnalysisDir" -ForegroundColor Green

# 3. ExÃ©cuter les analyses
Write-Section "ExÃ©cution des analyses"

Write-Host "Analyse de la frÃ©quence des termes..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --term-frequency

Write-Host "GÃ©nÃ©ration du nuage de mots..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --word-cloud

Write-Host "Analyse de l'Ã©volution des tags..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --tag-evolution

Write-Host "Analyse des tendances des sujets..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --topic-trends

Write-Host "Regroupement des entrÃ©es..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --cluster

# 4. Configurer une tÃ¢che planifiÃ©e pour l'analyse pÃ©riodique
Write-Section "Configuration de l'analyse pÃ©riodique"

$ScheduleAnalysis = Read-Host "Voulez-vous configurer une analyse pÃ©riodique automatique? (O/N)"

if ($ScheduleAnalysis -eq "O" -or $ScheduleAnalysis -eq "o") {
    $TaskName = "Journal_Analysis"
    $TaskPath = "\Journal\"
    
    # CrÃ©er le dossier de tÃ¢ches s'il n'existe pas
    $null = schtasks /query /tn $TaskPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        $null = schtasks /create /tn "$TaskPath\dummy" /tr "cmd.exe" /sc once /st 00:00 /sd 01/01/2099
        $null = schtasks /delete /tn "$TaskPath\dummy" /f
    }
    
    # CrÃ©er la tÃ¢che planifiÃ©e
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PythonScriptsDir\journal_analyzer.py`" --all"
    $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
    $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    
    if ($ExistingTask) {
        # Mettre Ã  jour la tÃ¢che existante
        Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings
        Write-Host "TÃ¢che planifiÃ©e mise Ã  jour: $TaskPath$TaskName" -ForegroundColor Green
    } else {
        # CrÃ©er une nouvelle tÃ¢che
        Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings -User "SYSTEM"
        Write-Host "TÃ¢che planifiÃ©e crÃ©Ã©e: $TaskPath$TaskName" -ForegroundColor Green
    }
    
    Write-Host "L'analyse sera exÃ©cutÃ©e automatiquement chaque dimanche Ã  3h du matin." -ForegroundColor Green
} else {
    Write-Host "Configuration de l'analyse pÃ©riodique ignorÃ©e." -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Analyse terminÃ©e"
Write-Host "L'analyse du journal de bord a Ã©tÃ© exÃ©cutÃ©e avec succÃ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "RÃ©sultats sauvegardÃ©s dans: $AnalysisDir"
Write-Host ""
Write-Host "Vous pouvez exÃ©cuter des analyses spÃ©cifiques avec:"
Write-Host "  python scripts/python/journal/journal_analyzer.py --term-frequency"
Write-Host "  python scripts/python/journal/journal_analyzer.py --word-cloud"
Write-Host "  python scripts/python/journal/journal_analyzer.py --tag-evolution"
Write-Host "  python scripts/python/journal/journal_analyzer.py --topic-trends"
Write-Host "  python scripts/python/journal/journal_analyzer.py --cluster"
Write-Host ""
Write-Host "Ou toutes les analyses Ã  la fois:"
Write-Host "  python scripts/python/journal/journal_analyzer.py --all"

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
