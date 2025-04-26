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

    # Fusionner les propriétés
    $optimizedConfigPSO.PSObject.Properties | ForEach-Object {
        $property = $_
        $name = $property.Name
        $value = $property.Value

        # Si la propriété commence par "augment.", l'ajouter ou la remplacer
        if ($name -like "augment.*") {
            $existingConfigPSO | Add-Member -MemberType NoteProperty -Name $name -Value $value -Force
        }
        # Pour les autres propriétés, ne les ajouter que si elles n'existent pas déjà
        elseif (-not ($existingConfigPSO.PSObject.Properties.Name -contains $name)) {
            $existingConfigPSO | Add-Member -MemberType NoteProperty -Name $name -Value $value
        }
    }

    # Ajouter spécifiquement les patterns d'exclusion pour Augment
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
        Write-Host "Le fichier de configuration optimisée n'existe pas: $optimizedSettingsPath" -ForegroundColor Red
        return $false
    }

    try {
        # Créer une sauvegarde si demandé et si le fichier existe
        if ($Backup -and (Test-Path $configPath)) {
            $backupFilePath = "$configPath.backup"
            Copy-Item -Path $configPath -Destination $backupFilePath -Force
            Write-Host "Sauvegarde créée: $backupFilePath" -ForegroundColor Green
        }

        # Fusionner les configurations
        $mergedConfig = Merge-JsonConfigs -existingConfigPath $configPath -optimizedConfigPath $optimizedSettingsPath

        # Convertir en JSON et écrire dans le fichier
        $mergedConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        Write-Host "Configuration optimisée appliquée à: $configPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erreur lors de l'application des optimisations: $_" -ForegroundColor Red
        return $false
    }
}

# Vérifier si le fichier de configuration optimisée existe
if (-not (Test-Path $optimizedSettingsPath)) {
    Write-Host "Le fichier de configuration optimisée n'existe pas: $optimizedSettingsPath" -ForegroundColor Red
    exit 1
}

# Appliquer les optimisations au fichier de configuration utilisateur
if (Test-Path $userSettingsPath) {
    Write-Host "Application des optimisations au fichier de configuration utilisateur..." -ForegroundColor Cyan
    $success = Set-VSCodeOptimizations -configPath $userSettingsPath
    if (-not $success) {
        Write-Host "Échec de l'application des optimisations au fichier de configuration utilisateur." -ForegroundColor Red
    }
} else {
    Write-Host "Le fichier de configuration utilisateur n'existe pas: $userSettingsPath" -ForegroundColor Yellow
    Write-Host "Création d'un nouveau fichier de configuration utilisateur..." -ForegroundColor Cyan

    # Créer le dossier parent s'il n'existe pas
    $userSettingsDir = Split-Path -Path $userSettingsPath -Parent
    if (-not (Test-Path $userSettingsDir)) {
        New-Item -Path $userSettingsDir -ItemType Directory -Force | Out-Null
    }

    # Copier le fichier de configuration optimisée
    Copy-Item -Path $optimizedSettingsPath -Destination $userSettingsPath -Force
    Write-Host "Nouveau fichier de configuration utilisateur créé: $userSettingsPath" -ForegroundColor Green
}

# Appliquer les optimisations au fichier de configuration de l'espace de travail
if (Test-Path $workspaceSettingsPath) {
    Write-Host "Application des optimisations au fichier de configuration de l'espace de travail..." -ForegroundColor Cyan
    $success = Set-VSCodeOptimizations -configPath $workspaceSettingsPath
    if (-not $success) {
        Write-Host "Échec de l'application des optimisations au fichier de configuration de l'espace de travail." -ForegroundColor Red
    }
} else {
    Write-Host "Le fichier de configuration de l'espace de travail n'existe pas: $workspaceSettingsPath" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "Création d'un nouveau fichier de configuration de l'espace de travail..." -ForegroundColor Cyan

        # Créer le dossier parent s'il n'existe pas
        $workspaceSettingsDir = Split-Path -Path $workspaceSettingsPath -Parent
        if (-not (Test-Path $workspaceSettingsDir)) {
            New-Item -Path $workspaceSettingsDir -ItemType Directory -Force | Out-Null
        }

        # Copier le fichier de configuration optimisée
        Copy-Item -Path $optimizedSettingsPath -Destination $workspaceSettingsPath -Force
        Write-Host "Nouveau fichier de configuration de l'espace de travail créé: $workspaceSettingsPath" -ForegroundColor Green
    } else {
        Write-Host "Utilisez le paramètre -Force pour créer un nouveau fichier de configuration de l'espace de travail." -ForegroundColor Yellow
    }
}

Write-Host "Optimisations terminées." -ForegroundColor Green
Write-Host "Redémarrez VS Code pour appliquer les modifications." -ForegroundColor Cyan
