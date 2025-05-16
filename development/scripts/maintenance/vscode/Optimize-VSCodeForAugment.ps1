# Script pour optimiser VS Code pour Augment Code
param(
    [switch]$Force,
    [switch]$Backup
)

# Chemins des fichiers
$userSettingsPath = "$env:APPDATA\Code\User\settings.json"
$workspaceSettingsPath = ".vscode\settings.json"
$optimizedSettingsPath = "augment-optimized-settings.json"

# Fonction pour fusionner les configurations
function Merge-JsonConfigs {
    param (
        [string]$existingConfigPath,
        [string]$optimizedConfigPath
    )

    if (-not (Test-Path $existingConfigPath)) {
        Write-Host "Le fichier de configuration n'existe pas: $existingConfigPath" -ForegroundColor Yellow
        return Get-Content $optimizedConfigPath -Raw | ConvertFrom-Json
    }

    $existingConfig = Get-Content $existingConfigPath -Raw | ConvertFrom-Json
    $optimizedConfig = Get-Content $optimizedConfigPath -Raw | ConvertFrom-Json

    # Convertir en PSObject pour faciliter la manipulation
    $existingConfigPSO = [PSCustomObject]$existingConfig
    $optimizedConfigPSO = [PSCustomObject]$optimizedConfig

    # Fusionner les propriÃ©tÃ©s
    $optimizedConfigPSO.PSObject.Properties | ForEach-Object {
        $property = $_
        $name = $property.Name
        $value = $property.Value

        # Si la propriÃ©tÃ© commence par "augment.", l'ajouter ou la remplacer
        if ($name -like "augment.*") {
            $existingConfigPSO | Add-Member -MemberType NoteProperty -Name $name -Value $value -Force
        }
        # Pour les autres propriÃ©tÃ©s, ne les ajouter que si elles n'existent pas dÃ©jÃ 
        elseif (-not ($existingConfigPSO.PSObject.Properties.Name -contains $name)) {
            $existingConfigPSO | Add-Member -MemberType NoteProperty -Name $name -Value $value
        }
    }

    # Ajouter spÃ©cifiquement les patterns d'exclusion pour Augment
    if ($existingConfigPSO.PSObject.Properties.Name -contains "files.watcherExclude") {
        $optimizedConfigPSO.PSObject.Properties["files.watcherExclude"].Value.PSObject.Properties | ForEach-Object {
            $pattern = $_.Name
            $value = $_.Value
            if (-not ($existingConfigPSO."files.watcherExclude".PSObject.Properties.Name -contains $pattern)) {
                $existingConfigPSO."files.watcherExclude" | Add-Member -MemberType NoteProperty -Name $pattern -Value $value
            }
        }
    }

    if ($existingConfigPSO.PSObject.Properties.Name -contains "search.exclude") {
        $optimizedConfigPSO.PSObject.Properties["search.exclude"].Value.PSObject.Properties | ForEach-Object {
            $pattern = $_.Name
            $value = $_.Value
            if (-not ($existingConfigPSO."search.exclude".PSObject.Properties.Name -contains $pattern)) {
                $existingConfigPSO."search.exclude" | Add-Member -MemberType NoteProperty -Name $pattern -Value $value
            }
        }
    }

    return $existingConfigPSO
}

# Fonction pour appliquer les optimisations
function Set-VSCodeOptimizations {
    param (
        [string]$configPath
    )

    if (-not (Test-Path $optimizedSettingsPath)) {
        Write-Host "Le fichier de configuration optimisÃ©e n'existe pas: $optimizedSettingsPath" -ForegroundColor Red
        return $false
    }

    try {
        # CrÃ©er une sauvegarde si demandÃ© et si le fichier existe
        if ($Backup -and (Test-Path $configPath)) {
            $backupFilePath = "$configPath.backup"
            Copy-Item -Path $configPath -Destination $backupFilePath -Force
            Write-Host "Sauvegarde crÃ©Ã©e: $backupFilePath" -ForegroundColor Green
        }

        # Fusionner les configurations
        $mergedConfig = Merge-JsonConfigs -existingConfigPath $configPath -optimizedConfigPath $optimizedSettingsPath

        # Convertir en JSON et Ã©crire dans le fichier
        $mergedConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        Write-Host "Configuration optimisÃ©e appliquÃ©e Ã : $configPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erreur lors de l'application des optimisations: $_" -ForegroundColor Red
        return $false
    }
}

# VÃ©rifier si le fichier de configuration optimisÃ©e existe
if (-not (Test-Path $optimizedSettingsPath)) {
    Write-Host "Le fichier de configuration optimisÃ©e n'existe pas: $optimizedSettingsPath" -ForegroundColor Red
    exit 1
}

# Appliquer les optimisations au fichier de configuration utilisateur
if (Test-Path $userSettingsPath) {
    Write-Host "Application des optimisations au fichier de configuration utilisateur..." -ForegroundColor Cyan
    $success = Set-VSCodeOptimizations -configPath $userSettingsPath
    if (-not $success) {
        Write-Host "Ã‰chec de l'application des optimisations au fichier de configuration utilisateur." -ForegroundColor Red
    }
} else {
    Write-Host "Le fichier de configuration utilisateur n'existe pas: $userSettingsPath" -ForegroundColor Yellow
    Write-Host "CrÃ©ation d'un nouveau fichier de configuration utilisateur..." -ForegroundColor Cyan

    # CrÃ©er le dossier parent s'il n'existe pas
    $userSettingsDir = Split-Path -Path $userSettingsPath -Parent
    if (-not (Test-Path $userSettingsDir)) {
        New-Item -Path $userSettingsDir -ItemType Directory -Force | Out-Null
    }

    # Copier le fichier de configuration optimisÃ©e
    Copy-Item -Path $optimizedSettingsPath -Destination $userSettingsPath -Force
    Write-Host "Nouveau fichier de configuration utilisateur crÃ©Ã©: $userSettingsPath" -ForegroundColor Green
}

# Appliquer les optimisations au fichier de configuration de l'espace de travail
if (Test-Path $workspaceSettingsPath) {
    Write-Host "Application des optimisations au fichier de configuration de l'espace de travail..." -ForegroundColor Cyan
    $success = Set-VSCodeOptimizations -configPath $workspaceSettingsPath
    if (-not $success) {
        Write-Host "Ã‰chec de l'application des optimisations au fichier de configuration de l'espace de travail." -ForegroundColor Red
    }
} else {
    Write-Host "Le fichier de configuration de l'espace de travail n'existe pas: $workspaceSettingsPath" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "CrÃ©ation d'un nouveau fichier de configuration de l'espace de travail..." -ForegroundColor Cyan

        # CrÃ©er le dossier parent s'il n'existe pas
        $workspaceSettingsDir = Split-Path -Path $workspaceSettingsPath -Parent
        if (-not (Test-Path $workspaceSettingsDir)) {
            New-Item -Path $workspaceSettingsDir -ItemType Directory -Force | Out-Null
        }

        # Copier le fichier de configuration optimisÃ©e
        Copy-Item -Path $optimizedSettingsPath -Destination $workspaceSettingsPath -Force
        Write-Host "Nouveau fichier de configuration de l'espace de travail crÃ©Ã©: $workspaceSettingsPath" -ForegroundColor Green
    } else {
        Write-Host "Utilisez le paramÃ¨tre -Force pour crÃ©er un nouveau fichier de configuration de l'espace de travail." -ForegroundColor Yellow
    }
}

Write-Host "Optimisations terminÃ©es." -ForegroundColor Green
Write-Host "RedÃ©marrez VS Code pour appliquer les modifications." -ForegroundColor Cyan
