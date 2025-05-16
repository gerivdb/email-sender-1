# SYNOPSIS
# Configure les options de démarrage de Visual Studio Code pour optimiser les performances.
#
# DESCRIPTION
# Ce script configure les options de démarrage de Visual Studio Code
# pour réduire le nombre de processus créés et optimiser l'utilisation
# de la mémoire. Il modifie les raccourcis et les paramètres de démarrage.
#
# PARAMETER DisableExtensions
# Si spécifié, ajoute l'option --disable-extensions au démarrage de VSCode.
#
# PARAMETER DisableGPU
# Si spécifié, ajoute l'option --disable-gpu au démarrage de VSCode.
#
# PARAMETER MaxMemory
# Définit la limite de mémoire maximale pour le processus principal de VSCode.
# Par défaut: 4096 Mo.
#
# PARAMETER UpdateShortcuts
# Si spécifié, met à jour les raccourcis de VSCode sur le bureau et dans le menu Démarrer.
#
# PARAMETER RestoreDefaults
# Si spécifié, restaure les paramètres de démarrage par défaut.
#
# EXAMPLE
# .\Set-VSCodeStartupOptions.ps1 -DisableExtensions -MaxMemory 2048
#
# EXAMPLE
# .\Set-VSCodeStartupOptions.ps1 -RestoreDefaults
#
# NOTES
# Auteur: Maintenance Team
# Version: 1.0
# Date de création: 2025-05-16

[CmdletBinding(DefaultParameterSetName = 'Configure')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Configure')]
    [switch]$DisableExtensions,

    [Parameter(Mandatory = $false, ParameterSetName = 'Configure')]
    [switch]$DisableGPU,

    [Parameter(Mandatory = $false, ParameterSetName = 'Configure')]
    [int]$MaxMemory = 4096,

    [Parameter(Mandatory = $false, ParameterSetName = 'Configure')]
    [switch]$UpdateShortcuts,

    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [switch]$RestoreDefaults
)

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

# Fonction pour obtenir le chemin d'installation de VSCode
function Get-VSCodeInstallPath {
    [CmdletBinding()]
    param ()

    $vscodePath = $null

    # Rechercher dans les emplacements courants
    $possiblePaths = @(
        "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe",
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path -Path $path -PathType Leaf) {
            $vscodePath = $path
            break
        }
    }

    if ($null -eq $vscodePath) {
        # Essayer de trouver via le registre
        try {
            $regPath = Get-ItemProperty -Path "HKCU:\Software\Classes\Applications\Code.exe\shell\open\command" -ErrorAction SilentlyContinue
            if ($regPath) {
                $command = $regPath.'(default)'
                if ($command -match '"([^"]+)\\Code\.exe"') {
                    $vscodePath = "$($matches[1])\Code.exe"
                }
            }
        } catch {
            # Ignorer les erreurs de registre
        }
    }

    if ($null -eq $vscodePath) {
        Write-Log "Impossible de trouver le chemin d'installation de VSCode." -Level "ERROR"
        return $null
    }

    return $vscodePath
}

# Fonction pour mettre à jour les raccourcis de VSCode
function Update-VSCodeShortcuts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VSCodePath,

        [Parameter(Mandatory = $true)]
        [string]$Arguments,

        [Parameter(Mandatory = $false)]
        [switch]$RestoreDefaults
    )

    # Créer un objet COM pour gérer les raccourcis
    $wshShell = New-Object -ComObject WScript.Shell

    # Emplacements courants des raccourcis
    $shortcutLocations = @(
        [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "Visual Studio Code.lnk"),
        [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Programs"), "Visual Studio Code\Visual Studio Code.lnk")
    )

    $updatedCount = 0

    foreach ($shortcutPath in $shortcutLocations) {
        if (Test-Path -Path $shortcutPath -PathType Leaf) {
            try {
                $shortcut = $wshShell.CreateShortcut($shortcutPath)

                # Sauvegarder le raccourci original si ce n'est pas déjà fait
                $backupPath = "$shortcutPath.backup"
                if (-not (Test-Path -Path $backupPath -PathType Leaf) -and -not $RestoreDefaults) {
                    Copy-Item -Path $shortcutPath -Destination $backupPath -Force
                    Write-Log "Sauvegarde du raccourci créée: $backupPath" -Level "INFO"
                }

                if ($RestoreDefaults) {
                    # Restaurer depuis la sauvegarde si elle existe
                    if (Test-Path -Path $backupPath -PathType Leaf) {
                        Copy-Item -Path $backupPath -Destination $shortcutPath -Force
                        Write-Log "Raccourci restauré: $shortcutPath" -Level "SUCCESS"
                        $updatedCount++
                    } else {
                        # Sinon, réinitialiser aux valeurs par défaut
                        $shortcut.TargetPath = $VSCodePath
                        $shortcut.Arguments = ""
                        $shortcut.Save()
                        Write-Log "Raccourci réinitialisé: $shortcutPath" -Level "SUCCESS"
                        $updatedCount++
                    }
                } else {
                    # Mettre à jour avec les nouveaux arguments
                    $shortcut.TargetPath = $VSCodePath
                    $shortcut.Arguments = $Arguments
                    $shortcut.Save()
                    Write-Log "Raccourci mis à jour: $shortcutPath" -Level "SUCCESS"
                    $updatedCount++
                }
            } catch {
                Write-Log "Erreur lors de la mise à jour du raccourci $shortcutPath : $_" -Level "ERROR"
            }
        }
    }

    return $updatedCount
}

# Fonction pour configurer les options de démarrage de VSCode
function Set-VSCodeStartupOptions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$DisableExtensions,

        [Parameter(Mandatory = $false)]
        [switch]$DisableGPU,

        [Parameter(Mandatory = $false)]
        [int]$MaxMemory = 4096,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateShortcuts,

        [Parameter(Mandatory = $false)]
        [switch]$RestoreDefaults
    )

    # Obtenir le chemin d'installation de VSCode
    $vscodePath = Get-VSCodeInstallPath

    if ($null -eq $vscodePath) {
        return $false
    }

    # Construire les arguments de ligne de commande
    $arguments = ""

    if (-not $RestoreDefaults) {
        if ($DisableExtensions) {
            $arguments += "--disable-extensions "
        }

        if ($DisableGPU) {
            $arguments += "--disable-gpu "
        }

        if ($MaxMemory -gt 0) {
            $arguments += "--max-memory=$MaxMemory "
        }

        # Ajouter d'autres options pour réduire le nombre de processus
        $arguments += "--unity-launch "
        $arguments += "--max-old-space-size=$MaxMemory "
    }

    # Mettre à jour les raccourcis si demandé
    if ($UpdateShortcuts -or $RestoreDefaults) {
        $updatedCount = Update-VSCodeShortcuts -VSCodePath $vscodePath -Arguments $arguments -RestoreDefaults:$RestoreDefaults

        if ($updatedCount -gt 0) {
            Write-Log "$updatedCount raccourcis ont été mis à jour." -Level "SUCCESS"
        } else {
            Write-Log "Aucun raccourci n'a été trouvé ou mis à jour." -Level "WARNING"
        }
    }

    # Mettre à jour le fichier de configuration de VSCode
    $configPath = Join-Path -Path $env:APPDATA -ChildPath "Code\User\settings.json"

    if (Test-Path -Path $configPath -PathType Leaf) {
        try {
            $settings = Get-Content -Path $configPath -Raw | ConvertFrom-Json

            # Convertir en hashtable pour faciliter les modifications
            $settingsHash = @{}
            $settings.PSObject.Properties | ForEach-Object { $settingsHash[$_.Name] = $_.Value }

            if ($RestoreDefaults) {
                # Supprimer les paramètres liés aux performances
                @("window.zoomLevel", "editor.minimap.enabled", "files.useExperimentalFileWatcher",
                    "search.followSymlinks", "typescript.disableAutomaticTypeAcquisition",
                    "npm.fetchOnlinePackageInfo", "window.titleBarStyle", "files.restoreUndoStack") | ForEach-Object {
                    if ($settingsHash.ContainsKey($_)) {
                        $settingsHash.Remove($_)
                    }
                }
            } else {
                # Mettre à jour les paramètres liés aux performances
                $settingsHash["window.zoomLevel"] = 0
                $settingsHash["editor.minimap.enabled"] = $false
                $settingsHash["files.useExperimentalFileWatcher"] = $false
                $settingsHash["search.followSymlinks"] = $false
                $settingsHash["typescript.disableAutomaticTypeAcquisition"] = $true
                $settingsHash["npm.fetchOnlinePackageInfo"] = $false
                $settingsHash["window.titleBarStyle"] = "custom"
                $settingsHash["files.restoreUndoStack"] = $false
            }

            # Convertir le hashtable en objet JSON
            $updatedSettings = [PSCustomObject]$settingsHash

            # Enregistrer les paramètres mis à jour
            $updatedSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8

            Write-Log "Paramètres de VSCode mis à jour avec succès." -Level "SUCCESS"
        } catch {
            Write-Log "Erreur lors de la mise à jour des paramètres de VSCode: $_" -Level "ERROR"
            return $false
        }
    } else {
        Write-Log "Fichier de configuration de VSCode non trouvé: $configPath" -Level "WARNING"
    }

    return $true
}

# Fonction principale
function Main {
    if ($RestoreDefaults) {
        Write-Log "Restauration des paramètres de démarrage par défaut de VSCode..." -Level "INFO"
        $result = Set-VSCodeStartupOptions -RestoreDefaults -UpdateShortcuts
    } else {
        Write-Log "Configuration des options de démarrage de VSCode..." -Level "INFO"
        Write-Log "Désactiver les extensions: $DisableExtensions" -Level "INFO"
        Write-Log "Désactiver le GPU: $DisableGPU" -Level "INFO"
        Write-Log "Limite de mémoire: $MaxMemory MB" -Level "INFO"
        Write-Log "Mettre à jour les raccourcis: $UpdateShortcuts" -Level "INFO"

        $result = Set-VSCodeStartupOptions -DisableExtensions:$DisableExtensions -DisableGPU:$DisableGPU -MaxMemory $MaxMemory -UpdateShortcuts:$UpdateShortcuts
    }

    if ($result) {
        Write-Log "Configuration des options de démarrage de VSCode terminée." -Level "SUCCESS"
        Write-Log "Redémarrez VSCode pour appliquer les changements." -Level "WARNING"
    } else {
        Write-Log "Échec de la configuration des options de démarrage de VSCode." -Level "ERROR"
    }
}

# Exécuter la fonction principale
Main
