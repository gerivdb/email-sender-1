<#
.SYNOPSIS
    Script d'installation du système d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script installe et configure le système d'apprentissage des erreurs PowerShell.
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

# Définir les chemins
$scriptRoot = $PSScriptRoot
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$logsPath = Join-Path -Path $scriptRoot -ChildPath "logs"
$patternsPath = Join-Path -Path $scriptRoot -ChildPath "patterns"
$dashboardPath = Join-Path -Path $scriptRoot -ChildPath "dashboard"

# Créer les dossiers nécessaires
$folders = @(
    $dataPath,
    $logsPath,
    $patternsPath,
    $dashboardPath
)

foreach ($folder in $folders) {
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé : $folder" -ForegroundColor Green
    }
    else {
        Write-Host "Dossier existant : $folder" -ForegroundColor Yellow
    }
}

# Importer le module
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem -Force

# Créer un gestionnaire d'erreurs global
if ($RegisterGlobalErrorHandler) {
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path -Path $profilePath -Parent
    
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    
    $errorHandlerCode = @"
# Gestionnaire d'erreurs global pour le système d'apprentissage des erreurs PowerShell
`$ErrorLearningSystemPath = "$modulePath"
if (Test-Path -Path `$ErrorLearningSystemPath) {
    Import-Module `$ErrorLearningSystemPath -Force
    
    # Initialiser le système
    Initialize-ErrorLearningSystem
    
    # Définir le gestionnaire d'erreurs global
    `$Global:ErrorActionPreference = 'Continue'
    
    # Sauvegarder le gestionnaire d'erreurs existant
    if (-not `$Global:OriginalErrorView) {
        `$Global:OriginalErrorView = `$ErrorView
    }
    
    # Définir un nouveau gestionnaire d'erreurs
    `$ErrorView = 'CategoryView'
    
    # Définir une fonction pour enregistrer les erreurs
    function Global:Register-GlobalError {
        param(`$ErrorRecord)
        
        # Enregistrer l'erreur
        Register-PowerShellError -ErrorRecord `$ErrorRecord -Source "GlobalErrorHandler" -Category "Uncategorized"
        
        # Obtenir des suggestions
        `$suggestions = Get-ErrorSuggestions -ErrorRecord `$ErrorRecord
        
        if (`$suggestions.Found) {
            Write-Host "`nSuggestions pour résoudre l'erreur :" -ForegroundColor Cyan
            foreach (`$suggestion in `$suggestions.Suggestions) {
                Write-Host "- `$(`$suggestion.Solution)" -ForegroundColor Yellow
            }
            Write-Host ""
        }
    }
    
    # Définir un trap pour capturer les erreurs
    trap {
        Register-GlobalError -ErrorRecord `$_
        continue
    }
    
    Write-Host "Système d'apprentissage des erreurs PowerShell initialisé." -ForegroundColor Green
}
"@
    
    # Vérifier si le profil existe
    if (Test-Path -Path $profilePath) {
        $profileContent = Get-Content -Path $profilePath -Raw
        
        # Vérifier si le gestionnaire d'erreurs est déjà présent
        if ($profileContent -match "ErrorLearningSystemPath") {
            if ($Force) {
                # Supprimer l'ancien gestionnaire d'erreurs
                $profileContent = $profileContent -replace "(?ms)# Gestionnaire d'erreurs global pour le système d'apprentissage des erreurs PowerShell.*?Write-Host `"Système d'apprentissage des erreurs PowerShell initialisé.`" -ForegroundColor Green", ""
                $profileContent = $profileContent.Trim()
                
                # Ajouter le nouveau gestionnaire d'erreurs
                $profileContent += "`n`n$errorHandlerCode"
                
                # Enregistrer le profil
                $profileContent | Set-Content -Path $profilePath -Force
                
                Write-Host "Gestionnaire d'erreurs global mis à jour dans le profil : $profilePath" -ForegroundColor Green
            }
            else {
                Write-Host "Le gestionnaire d'erreurs global est déjà présent dans le profil. Utilisez -Force pour le remplacer." -ForegroundColor Yellow
            }
        }
        else {
            # Ajouter le gestionnaire d'erreurs
            $profileContent += "`n`n$errorHandlerCode"
            
            # Enregistrer le profil
            $profileContent | Set-Content -Path $profilePath -Force
            
            Write-Host "Gestionnaire d'erreurs global ajouté au profil : $profilePath" -ForegroundColor Green
        }
    }
    else {
        # Créer le profil
        $errorHandlerCode | Set-Content -Path $profilePath -Force
        
        Write-Host "Profil créé avec le gestionnaire d'erreurs global : $profilePath" -ForegroundColor Green
    }
}

# Créer des tâches planifiées
if ($CreateScheduledTasks) {
    # Tâche pour collecter les erreurs
    $collectErrorsPath = Join-Path -Path $scriptRoot -ChildPath "Collect-ErrorData.ps1"
    $collectErrorsAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$collectErrorsPath`" -IncludeEventLogs"
    $collectErrorsTrigger = New-ScheduledTaskTrigger -Daily -At "00:00"
    $collectErrorsSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # Vérifier si la tâche existe
    $taskName = "ErrorLearningSystem_CollectErrors"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        if ($Force) {
            # Supprimer la tâche existante
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            
            # Créer la nouvelle tâche
            Register-ScheduledTask -TaskName $taskName -Action $collectErrorsAction -Trigger $collectErrorsTrigger -Settings $collectErrorsSettings -Description "Collecte les erreurs PowerShell pour le système d'apprentissage des erreurs"
            
            Write-Host "Tâche planifiée mise à jour : $taskName" -ForegroundColor Green
        }
        else {
            Write-Host "La tâche planifiée existe déjà : $taskName. Utilisez -Force pour la remplacer." -ForegroundColor Yellow
        }
    }
    else {
        # Créer la tâche
        Register-ScheduledTask -TaskName $taskName -Action $collectErrorsAction -Trigger $collectErrorsTrigger -Settings $collectErrorsSettings -Description "Collecte les erreurs PowerShell pour le système d'apprentissage des erreurs"
        
        Write-Host "Tâche planifiée créée : $taskName" -ForegroundColor Green
    }
    
    # Tâche pour générer le tableau de bord
    $generateDashboardPath = Join-Path -Path $scriptRoot -ChildPath "Generate-ErrorDashboard.ps1"
    $generateDashboardAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$generateDashboardPath`""
    $generateDashboardTrigger = New-ScheduledTaskTrigger -Daily -At "01:00"
    $generateDashboardSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # Vérifier si la tâche existe
    $taskName = "ErrorLearningSystem_GenerateDashboard"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        if ($Force) {
            # Supprimer la tâche existante
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            
            # Créer la nouvelle tâche
            Register-ScheduledTask -TaskName $taskName -Action $generateDashboardAction -Trigger $generateDashboardTrigger -Settings $generateDashboardSettings -Description "Génère le tableau de bord pour le système d'apprentissage des erreurs"
            
            Write-Host "Tâche planifiée mise à jour : $taskName" -ForegroundColor Green
        }
        else {
            Write-Host "La tâche planifiée existe déjà : $taskName. Utilisez -Force pour la remplacer." -ForegroundColor Yellow
        }
    }
    else {
        # Créer la tâche
        Register-ScheduledTask -TaskName $taskName -Action $generateDashboardAction -Trigger $generateDashboardTrigger -Settings $generateDashboardSettings -Description "Génère le tableau de bord pour le système d'apprentissage des erreurs"
        
        Write-Host "Tâche planifiée créée : $taskName" -ForegroundColor Green
    }
}

Write-Host "`nInstallation du système d'apprentissage des erreurs PowerShell terminée." -ForegroundColor Green
Write-Host "Pour commencer à utiliser le système, consultez le fichier README.md." -ForegroundColor Cyan
