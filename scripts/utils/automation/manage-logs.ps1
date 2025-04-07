# Script pour gÃ©rer automatiquement les logs par unitÃ© de temps
# Ce script organise les logs dans des dossiers quotidiens, hebdomadaires et mensuels

# CrÃ©ation des dossiers de logs s'ils n'existent pas
$logFolders = @(
    "logs\daily",
    "logs\weekly",
    "logs\monthly",
    "logs\scripts",
    "logs\workflows"
)

foreach ($folder in $logFolders) {
    if (-not (Test-Path -Path $folder)) {
        Write-Host "CrÃ©ation du dossier: $folder" -ForegroundColor Yellow
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour obtenir le nom du dossier quotidien
function Get-DailyFolder {
    $date = Get-Date
    $year = $date.Year
    $month = $date.Month.ToString("00")
    $day = $date.Day.ToString("00")
    return "logs\daily\$year-$month-$day"
}

# Fonction pour obtenir le nom du dossier hebdomadaire
function Get-WeeklyFolder {
    $date = Get-Date
    $year = $date.Year
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $calendar = $cultureInfo.Calendar
    $weekOfYear = $calendar.GetWeekOfYear($date, [System.Globalization.CalendarWeekRule]::FirstDay, [System.DayOfWeek]::Monday)
    return "logs\weekly\$year-W$($weekOfYear.ToString("00"))"
}

# Fonction pour obtenir le nom du dossier mensuel
function Get-MonthlyFolder {
    $date = Get-Date
    $year = $date.Year
    $month = $date.Month.ToString("00")
    return "logs\monthly\$year-$month"
}

# CrÃ©ation des dossiers par unitÃ© de temps
$dailyFolder = Get-DailyFolder
$weeklyFolder = Get-WeeklyFolder
$monthlyFolder = Get-MonthlyFolder

foreach ($folder in @($dailyFolder, $weeklyFolder, $monthlyFolder)) {
    if (-not (Test-Path -Path $folder)) {
        Write-Host "CrÃ©ation du dossier: $folder" -ForegroundColor Yellow
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour crÃ©er un nouveau fichier log avec horodatage
function New-LogFile {
    param (
        [string]$LogName,
        [string]$Category = "scripts"  # "scripts" ou "workflows"
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFileName = "$LogName-$timestamp.log"
    
    # CrÃ©ation du fichier log dans le dossier quotidien
    $dailyLogPath = Join-Path -Path (Get-DailyFolder) -ChildPath $logFileName
    New-Item -Path $dailyLogPath -ItemType File -Force | Out-Null
    
    # CrÃ©ation de liens symboliques dans les dossiers hebdomadaires et mensuels
    $weeklyLogPath = Join-Path -Path (Get-WeeklyFolder) -ChildPath $logFileName
    $monthlyLogPath = Join-Path -Path (Get-MonthlyFolder) -ChildPath $logFileName
    $categoryLogPath = Join-Path -Path "logs\$Category" -ChildPath $logFileName
    
    # Copie du fichier dans les autres dossiers
    Copy-Item -Path $dailyLogPath -Destination $weeklyLogPath -Force
    Copy-Item -Path $dailyLogPath -Destination $monthlyLogPath -Force
    Copy-Item -Path $dailyLogPath -Destination $categoryLogPath -Force
    
    return $dailyLogPath
}

# Fonction pour archiver les anciens logs
function Archive-OldLogs {
    param (
        [int]$DaysToKeepDaily = 7,
        [int]$DaysToKeepWeekly = 30,
        [int]$DaysToKeepMonthly = 365
    )
    
    # Archivage des logs quotidiens
    $dailyFolders = Get-ChildItem -Path "logs\daily" -Directory
    foreach ($folder in $dailyFolders) {
        $folderDate = [datetime]::ParseExact($folder.Name, "yyyy-MM-dd", $null)
        $daysOld = (Get-Date) - $folderDate
        
        if ($daysOld.Days -gt $DaysToKeepDaily) {
            Write-Host "Archivage du dossier quotidien: $($folder.FullName)" -ForegroundColor Yellow
            # Option 1: Supprimer le dossier
            # Remove-Item -Path $folder.FullName -Recurse -Force
            
            # Option 2: Compresser le dossier
            $archiveName = "logs\archives\daily_$($folder.Name).zip"
            if (-not (Test-Path -Path "logs\archives")) {
                New-Item -Path "logs\archives" -ItemType Directory -Force | Out-Null
            }
            
            Compress-Archive -Path $folder.FullName -DestinationPath $archiveName -Force
            Remove-Item -Path $folder.FullName -Recurse -Force
        }
    }
    
    # Archivage des logs hebdomadaires
    $weeklyFolders = Get-ChildItem -Path "logs\weekly" -Directory
    foreach ($folder in $weeklyFolders) {
        $folderName = $folder.Name
        $year = [int]($folderName.Split('-')[0])
        $week = [int](($folderName.Split('-')[1]).Substring(1))
        
        $firstDayOfYear = Get-Date -Year $year -Month 1 -Day 1
        $daysToAdd = ($week - 1) * 7
        $folderDate = $firstDayOfYear.AddDays($daysToAdd)
        $daysOld = (Get-Date) - $folderDate
        
        if ($daysOld.Days -gt $DaysToKeepWeekly) {
            Write-Host "Archivage du dossier hebdomadaire: $($folder.FullName)" -ForegroundColor Yellow
            $archiveName = "logs\archives\weekly_$($folder.Name).zip"
            if (-not (Test-Path -Path "logs\archives")) {
                New-Item -Path "logs\archives" -ItemType Directory -Force | Out-Null
            }
            
            Compress-Archive -Path $folder.FullName -DestinationPath $archiveName -Force
            Remove-Item -Path $folder.FullName -Recurse -Force
        }
    }
    
    # Archivage des logs mensuels
    $monthlyFolders = Get-ChildItem -Path "logs\monthly" -Directory
    foreach ($folder in $monthlyFolders) {
        $folderName = $folder.Name
        $year = [int]($folderName.Split('-')[0])
        $month = [int]($folderName.Split('-')[1])
        
        $folderDate = Get-Date -Year $year -Month $month -Day 1
        $daysOld = (Get-Date) - $folderDate
        
        if ($daysOld.Days -gt $DaysToKeepMonthly) {
            Write-Host "Archivage du dossier mensuel: $($folder.FullName)" -ForegroundColor Yellow
            $archiveName = "logs\archives\monthly_$($folder.Name).zip"
            if (-not (Test-Path -Path "logs\archives")) {
                New-Item -Path "logs\archives" -ItemType Directory -Force | Out-Null
            }
            
            Compress-Archive -Path $folder.FullName -DestinationPath $archiveName -Force
            Remove-Item -Path $folder.FullName -Recurse -Force
        }
    }
}

# Exemple d'utilisation
if ($args.Count -gt 0) {
    $logName = $args[0]
    $category = if ($args.Count -gt 1) { $args[1] } else { "scripts" }
    
    $logPath = New-LogFile -LogName $logName -Category $category
    Write-Host "Nouveau fichier log crÃ©Ã©: $logPath" -ForegroundColor Green
    
    # Archivage des anciens logs
    Archive-OldLogs
} else {
    Write-Host "Usage: manage-logs.ps1 <LogName> [Category]" -ForegroundColor Cyan
    Write-Host "  LogName: Nom du fichier log (sans extension)" -ForegroundColor Cyan
    Write-Host "  Category: 'scripts' ou 'workflows' (par dÃ©faut: 'scripts')" -ForegroundColor Cyan
}
