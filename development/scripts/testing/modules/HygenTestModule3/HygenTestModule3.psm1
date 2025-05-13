#Requires -Version 5.1
<#
.SYNOPSIS
    HygenTestModule3 module.
.DESCRIPTION
    Module de test pour Hygen 3
.EXAMPLE
    Import-Module HygenTestModule3
    Get-Command -Module HygenTestModule3
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-13
#>

#region Variables globales
$script:ModuleName = 'HygenTestModule3'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '1.0.0'
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config\$script:ModuleName.config.json"
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs\$script:ModuleName.log"
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
function Initialize-HygenTestModule3Module {
    <#
    .SYNOPSIS
        Initialise le module HygenTestModule3.
    .DESCRIPTION
        Crée les dossiers nécessaires et initialise les configurations du module.
    .EXAMPLE
        Initialize-HygenTestModule3Module
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Créer les dossiers nécessaires s'ils n'existent pas
    $Folders = @(
        (Join-Path -Path $script:ModuleRoot -ChildPath "config"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "logs"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "data")
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
}
#endregion

#region Exportation des fonctions
# Exporter uniquement les fonctions publiques
$FunctionsToExport = $PublicFunctions.BaseName
Export-ModuleMember -Function $FunctionsToExport -Variable @()
#endregion

# Initialiser le module lors du chargement
Initialize-HygenTestModule3Module

