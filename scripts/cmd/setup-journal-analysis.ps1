# Script PowerShell pour configurer et exécuter l'analyse du journal de bord

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section
function Write-Section {
    param (
        [string]$Title
    )
    
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Afficher un message d'introduction
Write-Host "Configuration et exécution de l'analyse du journal de bord" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Installer les dépendances Python
Write-Section "Installation des dépendances Python"
pip install numpy pandas matplotlib wordcloud scikit-learn

# 2. Créer les répertoires nécessaires
Write-Section "Création des répertoires"
$AnalysisDir = Join-Path $ProjectDir "docs\journal_de_bord\analysis"
New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
Write-Host "Répertoire d'analyse créé: $AnalysisDir" -ForegroundColor Green

# 3. Exécuter les analyses
Write-Section "Exécution des analyses"

Write-Host "Analyse de la fréquence des termes..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --term-frequency

Write-Host "Génération du nuage de mots..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --word-cloud

Write-Host "Analyse de l'évolution des tags..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --tag-evolution

Write-Host "Analyse des tendances des sujets..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --topic-trends

Write-Host "Regroupement des entrées..." -ForegroundColor Cyan
python "$PythonScriptsDir\journal_analyzer.py" --cluster

# 4. Configurer une tâche planifiée pour l'analyse périodique
Write-Section "Configuration de l'analyse périodique"

$ScheduleAnalysis = Read-Host "Voulez-vous configurer une analyse périodique automatique? (O/N)"

if ($ScheduleAnalysis -eq "O" -or $ScheduleAnalysis -eq "o") {
    $TaskName = "Journal_Analysis"
    $TaskPath = "\Journal\"
    
    # Créer le dossier de tâches s'il n'existe pas
    $null = schtasks /query /tn $TaskPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        $null = schtasks /create /tn "$TaskPath\dummy" /tr "cmd.exe" /sc once /st 00:00 /sd 01/01/2099
        $null = schtasks /delete /tn "$TaskPath\dummy" /f
    }
    
    # Créer la tâche planifiée
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PythonScriptsDir\journal_analyzer.py`" --all"
    $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
    $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # Vérifier si la tâche existe déjà
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    
    if ($ExistingTask) {
        # Mettre à jour la tâche existante
        Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings
        Write-Host "Tâche planifiée mise à jour: $TaskPath$TaskName" -ForegroundColor Green
    } else {
        # Créer une nouvelle tâche
        Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings -User "SYSTEM"
        Write-Host "Tâche planifiée créée: $TaskPath$TaskName" -ForegroundColor Green
    }
    
    Write-Host "L'analyse sera exécutée automatiquement chaque dimanche à 3h du matin." -ForegroundColor Green
} else {
    Write-Host "Configuration de l'analyse périodique ignorée." -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Analyse terminée"
Write-Host "L'analyse du journal de bord a été exécutée avec succès!" -ForegroundColor Green
Write-Host ""
Write-Host "Résultats sauvegardés dans: $AnalysisDir"
Write-Host ""
Write-Host "Vous pouvez exécuter des analyses spécifiques avec:"
Write-Host "  python scripts/python/journal/journal_analyzer.py --term-frequency"
Write-Host "  python scripts/python/journal/journal_analyzer.py --word-cloud"
Write-Host "  python scripts/python/journal/journal_analyzer.py --tag-evolution"
Write-Host "  python scripts/python/journal/journal_analyzer.py --topic-trends"
Write-Host "  python scripts/python/journal/journal_analyzer.py --cluster"
Write-Host ""
Write-Host "Ou toutes les analyses à la fois:"
Write-Host "  python scripts/python/journal/journal_analyzer.py --all"
