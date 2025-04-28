<#
.SYNOPSIS
    Script d'installation du systÃ¨me d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script installe et configure le systÃ¨me d'apprentissage des erreurs PowerShell.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$RegisterGlobalErrorHandler,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateScheduledTasks,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©finir les chemins
$scriptRoot = $PSScriptRoot
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$logsPath = Join-Path -Path $scriptRoot -ChildPath "logs"
$patternsPath = Join-Path -Path $scriptRoot -ChildPath "patterns"
$dashboardPath = Join-Path -Path $scriptRoot -ChildPath "dashboard"

# CrÃ©er les dossiers nÃ©cessaires
$folders = @(
    $dataPath,
    $logsPath,
    $patternsPath,
    $dashboardPath
)

foreach ($folder in $folders) {
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier crÃ©Ã© : $folder" -ForegroundColor Green
    }
    else {
        Write-Host "Dossier existant : $folder" -ForegroundColor Yellow
    }
}

# Importer le module
Import-Module $modulePath -Force

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem -Force

# CrÃ©er un gestionnaire d'erreurs global
if ($RegisterGlobalErrorHandler) {
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path -Path $profilePath -Parent
    
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    
    $errorHandlerCode = @"
# Gestionnaire d'erreurs global pour le systÃ¨me d'apprentissage des erreurs PowerShell
`$ErrorLearningSystemPath = "$modulePath"
if (Test-Path -Path `$ErrorLearningSystemPath) {
    Import-Module `$ErrorLearningSystemPath -Force
    
    # Initialiser le systÃ¨me
    Initialize-ErrorLearningSystem
    
    # DÃ©finir le gestionnaire d'erreurs global
    `$Global:ErrorActionPreference = 'Continue'
    
    # Sauvegarder le gestionnaire d'erreurs existant
    if (-not `$Global:OriginalErrorView) {
        `$Global:OriginalErrorView = `$ErrorView
    }
    
    # DÃ©finir un nouveau gestionnaire d'erreurs
    `$ErrorView = 'CategoryView'
    
    # DÃ©finir une fonction pour enregistrer les erreurs
    function Global:Register-GlobalError {
        param(`$ErrorRecord)
        
        # Enregistrer l'erreur
        Register-PowerShellError -ErrorRecord `$ErrorRecord -Source "GlobalErrorHandler" -Category "Uncategorized"
        
        # Obtenir des suggestions
        `$suggestions = Get-ErrorSuggestions -ErrorRecord `$ErrorRecord
        
        if (`$suggestions.Found) {
            Write-Host "`nSuggestions pour rÃ©soudre l'erreur :" -ForegroundColor Cyan
            foreach (`$suggestion in `$suggestions.Suggestions) {
                Write-Host "- `$(`$suggestion.Solution)" -ForegroundColor Yellow
            }
            Write-Host ""
        }
    }
    
    # DÃ©finir un trap pour capturer les erreurs
    trap {
        Register-GlobalError -ErrorRecord `$_
        continue
    }
    
    Write-Host "SystÃ¨me d'apprentissage des erreurs PowerShell initialisÃ©." -ForegroundColor Green
}
"@
    
    # VÃ©rifier si le profil existe
    if (Test-Path -Path $profilePath) {
        $profileContent = Get-Content -Path $profilePath -Raw
        
        # VÃ©rifier si le gestionnaire d'erreurs est dÃ©jÃ  prÃ©sent
        if ($profileContent -match "ErrorLearningSystemPath") {
            if ($Force) {
                # Supprimer l'ancien gestionnaire d'erreurs
                $profileContent = $profileContent -replace "(?ms)# Gestionnaire d'erreurs global pour le systÃ¨me d'apprentissage des erreurs PowerShell.*?Write-Host `"SystÃ¨me d'apprentissage des erreurs PowerShell initialisÃ©.`" -ForegroundColor Green", ""
                $profileContent = $profileContent.Trim()
                
                # Ajouter le nouveau gestionnaire d'erreurs
                $profileContent += "`n`n$errorHandlerCode"
                
                # Enregistrer le profil
                $profileContent | Set-Content -Path $profilePath -Force
                
                Write-Host "Gestionnaire d'erreurs global mis Ã  jour dans le profil : $profilePath" -ForegroundColor Green
            }
            else {
                Write-Host "Le gestionnaire d'erreurs global est dÃ©jÃ  prÃ©sent dans le profil. Utilisez -Force pour le remplacer." -ForegroundColor Yellow
            }
        }
        else {
            # Ajouter le gestionnaire d'erreurs
            $profileContent += "`n`n$errorHandlerCode"
            
            # Enregistrer le profil
            $profileContent | Set-Content -Path $profilePath -Force
            
            Write-Host "Gestionnaire d'erreurs global ajoutÃ© au profil : $profilePath" -ForegroundColor Green
        }
    }
    else {
        # CrÃ©er le profil
        $errorHandlerCode | Set-Content -Path $profilePath -Force
        
        Write-Host "Profil crÃ©Ã© avec le gestionnaire d'erreurs global : $profilePath" -ForegroundColor Green
    }
}

# CrÃ©er des tÃ¢ches planifiÃ©es
if ($CreateScheduledTasks) {
    # TÃ¢che pour collecter les erreurs
    $collectErrorsPath = Join-Path -Path $scriptRoot -ChildPath "Collect-ErrorData.ps1"
    $collectErrorsAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$collectErrorsPath`" -IncludeEventLogs"
    $collectErrorsTrigger = New-ScheduledTaskTrigger -Daily -At "00:00"
    $collectErrorsSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # VÃ©rifier si la tÃ¢che existe
    $taskName = "ErrorLearningSystem_CollectErrors"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        if ($Force) {
            # Supprimer la tÃ¢che existante
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            
            # CrÃ©er la nouvelle tÃ¢che
            Register-ScheduledTask -TaskName $taskName -Action $collectErrorsAction -Trigger $collectErrorsTrigger -Settings $collectErrorsSettings -Description "Collecte les erreurs PowerShell pour le systÃ¨me d'apprentissage des erreurs"
            
            Write-Host "TÃ¢che planifiÃ©e mise Ã  jour : $taskName" -ForegroundColor Green
        }
        else {
            Write-Host "La tÃ¢che planifiÃ©e existe dÃ©jÃ  : $taskName. Utilisez -Force pour la remplacer." -ForegroundColor Yellow
        }
    }
    else {
        # CrÃ©er la tÃ¢che
        Register-ScheduledTask -TaskName $taskName -Action $collectErrorsAction -Trigger $collectErrorsTrigger -Settings $collectErrorsSettings -Description "Collecte les erreurs PowerShell pour le systÃ¨me d'apprentissage des erreurs"
        
        Write-Host "TÃ¢che planifiÃ©e crÃ©Ã©e : $taskName" -ForegroundColor Green
    }
    
    # TÃ¢che pour gÃ©nÃ©rer le tableau de bord
    $generateDashboardPath = Join-Path -Path $scriptRoot -ChildPath "Generate-ErrorDashboard.ps1"
    $generateDashboardAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$generateDashboardPath`""
    $generateDashboardTrigger = New-ScheduledTaskTrigger -Daily -At "01:00"
    $generateDashboardSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # VÃ©rifier si la tÃ¢che existe
    $taskName = "ErrorLearningSystem_GenerateDashboard"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        if ($Force) {
            # Supprimer la tÃ¢che existante
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            
            # CrÃ©er la nouvelle tÃ¢che
            Register-ScheduledTask -TaskName $taskName -Action $generateDashboardAction -Trigger $generateDashboardTrigger -Settings $generateDashboardSettings -Description "GÃ©nÃ¨re le tableau de bord pour le systÃ¨me d'apprentissage des erreurs"
            
            Write-Host "TÃ¢che planifiÃ©e mise Ã  jour : $taskName" -ForegroundColor Green
        }
        else {
            Write-Host "La tÃ¢che planifiÃ©e existe dÃ©jÃ  : $taskName. Utilisez -Force pour la remplacer." -ForegroundColor Yellow
        }
    }
    else {
        # CrÃ©er la tÃ¢che
        Register-ScheduledTask -TaskName $taskName -Action $generateDashboardAction -Trigger $generateDashboardTrigger -Settings $generateDashboardSettings -Description "GÃ©nÃ¨re le tableau de bord pour le systÃ¨me d'apprentissage des erreurs"
        
        Write-Host "TÃ¢che planifiÃ©e crÃ©Ã©e : $taskName" -ForegroundColor Green
    }
}

Write-Host "`nInstallation du systÃ¨me d'apprentissage des erreurs PowerShell terminÃ©e." -ForegroundColor Green
Write-Host "Pour commencer Ã  utiliser le systÃ¨me, consultez le fichier README.md." -ForegroundColor Cyan
