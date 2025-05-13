#Requires -Version 5.1
<#
.SYNOPSIS
    Testhygenmodule module (Advanced).
.DESCRIPTION
    Module de test pour Hygen
    Ce module avancé inclut une gestion d'état complète.
.EXAMPLE
    Import-Module TestHygenModule
    Get-Command -Module TestHygenModule
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-13
#>

#region Variables globales
$script:ModuleName = 'TestHygenModule'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '1.0.0'
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config\$script:ModuleName.config.json"
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs\$script:ModuleName.log"
$script:StatePath = Join-Path -Path $PSScriptRoot -ChildPath "state\$script:ModuleName.state.json"
$script:StateBackupPath = Join-Path -Path $PSScriptRoot -ChildPath "state\backup"
$script:ModuleState = $null
$script:StateLoaded = $false
$script:StateModified = $false
$script:StateBackupInterval = 30 # minutes
$script:LastStateBackup = [DateTime]::MinValue
#endregion

#region Fonctions de gestion d'état
function Initialize-ModuleState {
    <#
    .SYNOPSIS
        Initialise l'état du module.
    .DESCRIPTION
        Charge l'état du module depuis le fichier d'état ou crée un nouvel état si le fichier n'existe pas.
    .EXAMPLE
        Initialize-ModuleState
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if (-not (Test-Path -Path (Split-Path -Parent $script:StatePath))) {
        if ($PSCmdlet.ShouldProcess((Split-Path -Parent $script:StatePath), "Créer le dossier d'état")) {
            New-Item -Path (Split-Path -Parent $script:StatePath) -ItemType Directory -Force | Out-Null
            Write-Verbose "Dossier d'état créé : $(Split-Path -Parent $script:StatePath)"
        }
    }

    if (-not (Test-Path -Path $script:StateBackupPath)) {
        if ($PSCmdlet.ShouldProcess($script:StateBackupPath, "Créer le dossier de sauvegarde d'état")) {
            New-Item -Path $script:StateBackupPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Dossier de sauvegarde d'état créé : $script:StateBackupPath"
        }
    }

    if (Test-Path -Path $script:StatePath) {
        try {
            $script:ModuleState = Get-Content -Path $script:StatePath -Raw | ConvertFrom-Json
            $script:StateLoaded = $true
            Write-Verbose "État du module chargé depuis $script:StatePath"
        }
        catch {
            Write-Error "Échec du chargement de l'état du module : $_"
            $script:ModuleState = [PSCustomObject]@{
                Version = $script:ModuleVersion
                LastUpdated = [DateTime]::Now.ToString('o')
                Data = @{}
            }
            $script:StateLoaded = $true
            $script:StateModified = $true
            Write-Verbose "Nouvel état du module créé suite à une erreur de chargement"
        }
    }
    else {
        $script:ModuleState = [PSCustomObject]@{
            Version = $script:ModuleVersion
            LastUpdated = [DateTime]::Now.ToString('o')
            Data = @{}
        }
        $script:StateLoaded = $true
        $script:StateModified = $true
        Write-Verbose "Nouvel état du module créé"
    }
}

function Save-ModuleState {
    <#
    .SYNOPSIS
        Sauvegarde l'état du module.
    .DESCRIPTION
        Sauvegarde l'état du module dans le fichier d'état.
    .EXAMPLE
        Save-ModuleState
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if (-not $script:StateLoaded) {
        Write-Warning "L'état du module n'est pas chargé. Impossible de sauvegarder."
        return
    }

    if (-not $script:StateModified) {
        Write-Verbose "L'état du module n'a pas été modifié. Pas besoin de sauvegarder."
        return
    }

    $script:ModuleState.LastUpdated = [DateTime]::Now.ToString('o')

    if ($PSCmdlet.ShouldProcess($script:StatePath, "Sauvegarder l'état du module")) {
        try {
            $script:ModuleState | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:StatePath -Encoding utf8 -Force
            $script:StateModified = $false
            Write-Verbose "État du module sauvegardé dans $script:StatePath"

            # Vérifier si une sauvegarde est nécessaire
            $now = [DateTime]::Now
            if (($now - $script:LastStateBackup).TotalMinutes -ge $script:StateBackupInterval) {
                $backupFileName = "$script:ModuleName.state_$($now.ToString('yyyyMMdd_HHmmss')).json"
                $backupFilePath = Join-Path -Path $script:StateBackupPath -ChildPath $backupFileName
                $script:ModuleState | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupFilePath -Encoding utf8 -Force
                $script:LastStateBackup = $now
                Write-Verbose "Sauvegarde de l'état créée : $backupFilePath"

                # Nettoyer les anciennes sauvegardes (garder les 10 plus récentes)
                $backupFiles = Get-ChildItem -Path $script:StateBackupPath -Filter "$script:ModuleName.state_*.json" | Sort-Object LastWriteTime -Descending
                if ($backupFiles.Count -gt 10) {
                    $backupFiles | Select-Object -Skip 10 | Remove-Item -Force
                    Write-Verbose "Anciennes sauvegardes nettoyées. $(($backupFiles | Select-Object -Skip 10).Count) fichiers supprimés."
                }
            }
        }
        catch {
            Write-Error "Échec de la sauvegarde de l'état du module : $_"
        }
    }
}

function Get-ModuleStateValue {
    <#
    .SYNOPSIS
        Récupère une valeur de l'état du module.
    .DESCRIPTION
        Récupère une valeur de l'état du module à partir de la clé spécifiée.
    .PARAMETER Key
        Clé de la valeur à récupérer.
    .PARAMETER DefaultValue
        Valeur par défaut à retourner si la clé n'existe pas.
    .EXAMPLE
        Get-ModuleStateValue -Key "LastRun" -DefaultValue ([DateTime]::MinValue)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        $DefaultValue = $null
    )

    if (-not $script:StateLoaded) {
        Initialize-ModuleState
    }

    if ($script:ModuleState.Data.PSObject.Properties.Name -contains $Key) {
        return $script:ModuleState.Data.$Key
    }
    else {
        return $DefaultValue
    }
}

function Set-ModuleStateValue {
    <#
    .SYNOPSIS
        Définit une valeur dans l'état du module.
    .DESCRIPTION
        Définit une valeur dans l'état du module pour la clé spécifiée.
    .PARAMETER Key
        Clé de la valeur à définir.
    .PARAMETER Value
        Valeur à définir.
    .PARAMETER AutoSave
        Indique si l'état doit être sauvegardé automatiquement après la modification.
    .EXAMPLE
        Set-ModuleStateValue -Key "LastRun" -Value ([DateTime]::Now) -AutoSave
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $false)]
        [switch]$AutoSave
    )

    if (-not $script:StateLoaded) {
        Initialize-ModuleState
    }

    if ($PSCmdlet.ShouldProcess("État du module", "Définir la valeur '$Key'")) {
        # Créer la propriété si elle n'existe pas
        if ($script:ModuleState.Data.PSObject.Properties.Name -notcontains $Key) {
            $script:ModuleState.Data | Add-Member -MemberType NoteProperty -Name $Key -Value $Value
        }
        else {
            $script:ModuleState.Data.$Key = $Value
        }

        $script:StateModified = $true
        Write-Verbose "Valeur d'état '$Key' définie à '$Value'"

        if ($AutoSave) {
            Save-ModuleState
        }
    }
}

function Remove-ModuleStateValue {
    <#
    .SYNOPSIS
        Supprime une valeur de l'état du module.
    .DESCRIPTION
        Supprime une valeur de l'état du module pour la clé spécifiée.
    .PARAMETER Key
        Clé de la valeur à supprimer.
    .PARAMETER AutoSave
        Indique si l'état doit être sauvegardé automatiquement après la modification.
    .EXAMPLE
        Remove-ModuleStateValue -Key "TemporaryData" -AutoSave
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [switch]$AutoSave
    )

    if (-not $script:StateLoaded) {
        Initialize-ModuleState
    }

    if ($script:ModuleState.Data.PSObject.Properties.Name -contains $Key) {
        if ($PSCmdlet.ShouldProcess("État du module", "Supprimer la valeur '$Key'")) {
            $script:ModuleState.Data.PSObject.Properties.Remove($Key)
            $script:StateModified = $true
            Write-Verbose "Valeur d'état '$Key' supprimée"

            if ($AutoSave) {
                Save-ModuleState
            }
        }
    }
    else {
        Write-Verbose "La clé '$Key' n'existe pas dans l'état du module"
    }
}

function Reset-ModuleState {
    <#
    .SYNOPSIS
        Réinitialise l'état du module.
    .DESCRIPTION
        Réinitialise l'état du module à un état vide.
    .PARAMETER CreateBackup
        Indique si une sauvegarde de l'état actuel doit être créée avant la réinitialisation.
    .EXAMPLE
        Reset-ModuleState -CreateBackup
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup
    )

    if (-not $script:StateLoaded) {
        Initialize-ModuleState
    }

    if ($PSCmdlet.ShouldProcess("État du module", "Réinitialiser complètement")) {
        if ($CreateBackup -and (Test-Path -Path $script:StatePath)) {
            $backupFileName = "$script:ModuleName.state_backup_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
            $backupFilePath = Join-Path -Path $script:StateBackupPath -ChildPath $backupFileName
            Copy-Item -Path $script:StatePath -Destination $backupFilePath -Force
            Write-Verbose "Sauvegarde de l'état créée avant réinitialisation : $backupFilePath"
        }

        $script:ModuleState = [PSCustomObject]@{
            Version = $script:ModuleVersion
            LastUpdated = [DateTime]::Now.ToString('o')
            Data = @{}
        }
        $script:StateModified = $true
        Save-ModuleState
        Write-Verbose "État du module réinitialisé"
    }
}
#endregion

#region Fonctions privées
# Importer toutes les fonctions privées
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction privée importée : $($Function.BaseName)"
    }
    catch {
        Write-Error "Échec de l'importation de la fonction privée $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions publiques
# Importer toutes les fonctions publiques
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction publique importée : $($Function.BaseName)"
    }
    catch {
        Write-Error "Échec de l'importation de la fonction publique $($Function.FullName): $_"
    }
}
#endregion

#region Initialisation du module
function Initialize-TestHygenModuleModule {
    <#
    .SYNOPSIS
        Initialise le module Testhygenmodule.
    .DESCRIPTION
        Crée les dossiers nécessaires et initialise les configurations du module.
    .EXAMPLE
        Initialize-TestHygenModuleModule
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Créer les dossiers nécessaires s'ils n'existent pas
    $Folders = @(
        (Join-Path -Path $script:ModuleRoot -ChildPath "config"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "logs"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "data"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "state"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "state\backup")
    )

    foreach ($Folder in $Folders) {
        if (-not (Test-Path -Path $Folder)) {
            if ($PSCmdlet.ShouldProcess($Folder, "Créer le dossier")) {
                New-Item -Path $Folder -ItemType Directory -Force | Out-Null
                Write-Verbose "Dossier créé : $Folder"
            }
        }
    }

    # Initialiser le fichier de configuration s'il n'existe pas
    if (-not (Test-Path -Path $script:ConfigPath)) {
        if ($PSCmdlet.ShouldProcess($script:ConfigPath, "Créer le fichier de configuration")) {
            $DefaultConfig = @{
                ModuleName = $script:ModuleName
                Version = $script:ModuleVersion
                LogLevel = "Info"
                LogPath = $script:LogPath
                Enabled = $true
                StateManagement = @{
                    StatePath = $script:StatePath
                    BackupPath = $script:StateBackupPath
                    BackupInterval = $script:StateBackupInterval
                    AutoSaveOnExit = $true
                }
                Settings = @{
                    MaxLogSize = 10MB
                    MaxLogAge = 30
                    DefaultTimeout = 30
                }
            }

            $DefaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $script:ConfigPath -Encoding utf8
            Write-Verbose "Fichier de configuration créé : $script:ConfigPath"
        }
    }

    # Initialiser l'état du module
    Initialize-ModuleState
}
#endregion

#region Exportation des fonctions
# Exporter les fonctions publiques et les fonctions de gestion d'état
$FunctionsToExport = @(
    $PublicFunctions.BaseName
    'Get-ModuleStateValue'
    'Set-ModuleStateValue'
    'Remove-ModuleStateValue'
    'Reset-ModuleState'
    'Save-ModuleState'
)
Export-ModuleMember -Function $FunctionsToExport -Variable @()
#endregion

#region Nettoyage à la décharge du module
# Enregistrer un script de nettoyage à exécuter lorsque le module est déchargé
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Sauvegarder l'état du module si nécessaire
    if ($script:StateLoaded -and $script:StateModified) {
        try {
            # Charger la configuration pour vérifier si la sauvegarde automatique est activée
            $config = Get-Content -Path $script:ConfigPath -Raw | ConvertFrom-Json
            if ($config.StateManagement.AutoSaveOnExit) {
                Write-Verbose "Sauvegarde automatique de l'état du module lors de la décharge"
                Save-ModuleState
            }
        }
        catch {
            Write-Warning "Impossible de sauvegarder l'état du module lors de la décharge : $_"
        }
    }
}
#endregion

# Initialiser le module lors du chargement
Initialize-TestHygenModuleModule
