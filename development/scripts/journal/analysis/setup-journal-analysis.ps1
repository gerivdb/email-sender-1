# Script PowerShell pour configurer et exÃƒÂ©cuter l'analyse du journal de bord

# Chemin absolu vers le rÃƒÂ©pertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section

# Script PowerShell pour configurer et exÃƒÂ©cuter l'analyse du journal de bord

# Chemin absolu vers le rÃƒÂ©pertoire du projet
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
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal

    
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Afficher un message d'introduction
Write-Host "Configuration et exÃƒÂ©cution de l'analyse du journal de bord" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Installer les dÃƒÂ©pendances Python
Write-Section "Installation des dÃƒÂ©pendances Python"
pip install numpy pandas matplotlib wordcloud scikit-learn

# 2. CrÃƒÂ©er les rÃƒÂ©pertoires nÃƒÂ©cessaires
Write-Section "CrÃƒÂ©ation des rÃƒÂ©pertoires"
$AnalysisDir = Join-Path $ProjectDir "docs\journal_de_bord\analysis"
New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
Write-Host "RÃƒÂ©pertoire d'analyse crÃƒÂ©ÃƒÂ©: $AnalysisDir" -ForegroundColor Green

# 3. ExÃƒÂ©cuter les analyses
Write-Section "ExÃƒÂ©cution des analyses"

Write-Host "Analyse de la frÃƒÂ©quence des termes..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --term-frequency

Write-Host "GÃƒÂ©nÃƒÂ©ration du nuage de mots..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --word-cloud

Write-Host "Analyse de l'ÃƒÂ©volution des tags..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --tag-evolution

Write-Host "Analyse des tendances des sujets..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --topic-trends

Write-Host "Regroupement des entrÃƒÂ©es..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --cluster

# 4. Configurer une tÃƒÂ¢che planifiÃƒÂ©e pour l'analyse pÃƒÂ©riodique
Write-Section "Configuration de l'analyse pÃƒÂ©riodique"

$ScheduleAnalysis = Read-Host "Voulez-vous configurer une analyse pÃƒÂ©riodique automatique? (O/N)"

if ($ScheduleAnalysis -eq "O" -or $ScheduleAnalysis -eq "o") {
    $TaskName = "Journal_Analysis"
    $TaskPath = "\Journal\"
    
    # CrÃƒÂ©er le dossier de tÃƒÂ¢ches s'il n'existe pas
    $null = schtasks /query /tn $TaskPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        $null = schtasks /create /tn "$TaskPath\dummy" /tr "cmd.exe" /sc once /st 00:00 /sd 01/01/2099
        $null = schtasks /delete /tn "$TaskPath\dummy" /f
    }
    
    # CrÃƒÂ©er la tÃƒÂ¢che planifiÃƒÂ©e
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PythonScriptsDir\journal_analyzer.py`" --all"
    $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
    $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # VÃƒÂ©rifier si la tÃƒÂ¢che existe dÃƒÂ©jÃƒÂ 
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    
    if ($ExistingTask) {
        # Mettre ÃƒÂ  jour la tÃƒÂ¢che existante
        Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings
        Write-Host "TÃƒÂ¢che planifiÃƒÂ©e mise ÃƒÂ  jour: $TaskPath$TaskName" -ForegroundColor Green
    } else {
        # CrÃƒÂ©er une nouvelle tÃƒÂ¢che
        Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings -User "SYSTEM"
        Write-Host "TÃƒÂ¢che planifiÃƒÂ©e crÃƒÂ©ÃƒÂ©e: $TaskPath$TaskName" -ForegroundColor Green
    }
    
    Write-Host "L'analyse sera exÃƒÂ©cutÃƒÂ©e automatiquement chaque dimanche ÃƒÂ  3h du matin." -ForegroundColor Green
} else {
    Write-Host "Configuration de l'analyse pÃƒÂ©riodique ignorÃƒÂ©e." -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Analyse terminÃƒÂ©e"
Write-Host "L'analyse du journal de bord a ÃƒÂ©tÃƒÂ© exÃƒÂ©cutÃƒÂ©e avec succÃƒÂ¨s!" -ForegroundColor Green
Write-Host ""
Write-Host "RÃƒÂ©sultats sauvegardÃƒÂ©s dans: $AnalysisDir"
Write-Host ""
Write-Host "Vous pouvez exÃƒÂ©cuter des analyses spÃƒÂ©cifiques avec:"
Write-Host "  python development/scripts/python/journal/journal_analyzer.py --term-frequency"
Write-Host "  python development/scripts/python/journal/journal_analyzer.py --word-cloud"
Write-Host "  python development/scripts/python/journal/journal_analyzer.py --tag-evolution"
Write-Host "  python development/scripts/python/journal/journal_analyzer.py --topic-trends"
Write-Host "  python development/scripts/python/journal/journal_analyzer.py --cluster"
Write-Host ""
Write-Host "Ou toutes les analyses ÃƒÂ  la fois:"
Write-Host "  python development/scripts/python/journal/journal_analyzer.py --all"

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
