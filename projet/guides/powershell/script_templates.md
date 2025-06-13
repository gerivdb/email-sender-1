# Modèles de Scripts PowerShell

Ce document contient des modèles de scripts PowerShell réutilisables pour différents scénarios.

## Table des matières

- [Script de base](#script-de-base)

- [Script avec paramètres](#script-avec-paramètres)

- [Script avec gestion des erreurs](#script-avec-gestion-des-erreurs)

- [Script avec logging](#script-avec-logging)

- [Script avec exécution en mode batch](#script-avec-exécution-en-mode-batch)

- [Module PowerShell](#module-powershell)

## Script de base

```powershell
<#

.SYNOPSIS
    Description courte du script.
.DESCRIPTION
    Description détaillée du script.
.NOTES
    Nom du fichier    : Script.ps1
    Auteur           : Votre nom
    Date de création : 25/04/2025
    Version          : 1.0
#>

[CmdletBinding()]
param()

# Code du script

Write-Verbose "Exécution du script"
```plaintext
## Script avec paramètres

```powershell
<#

.SYNOPSIS
    Description courte du script.
.DESCRIPTION
    Description détaillée du script.
.PARAMETER Path
    Chemin du fichier ou du dossier à traiter.
.PARAMETER Force
    Force l'exécution sans demander de confirmation.
.EXAMPLE
    .\Script.ps1 -Path "C:\Temp" -Force
.NOTES
    Nom du fichier    : Script.ps1
    Auteur           : Votre nom
    Date de création : 25/04/2025
    Version          : 1.0
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Code du script

if ($Force -or $PSCmdlet.ShouldProcess($Path, "Traiter")) {
    Write-Verbose "Traitement de $Path"
}
```plaintext
## Script avec gestion des erreurs

```powershell
<#

.SYNOPSIS
    Description courte du script.
.DESCRIPTION
    Description détaillée du script.
.PARAMETER Path
    Chemin du fichier ou du dossier à traiter.
.EXAMPLE
    .\Script.ps1 -Path "C:\Temp"
.NOTES
    Nom du fichier    : Script.ps1
    Auteur           : Votre nom
    Date de création : 25/04/2025
    Version          : 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
)

# Définir la préférence d'action d'erreur sur Stop pour capturer les erreurs

$ErrorActionPreference = 'Stop'

try {
    # Code du script

    Write-Verbose "Traitement de $Path"
    
    if (-not (Test-Path -Path $Path)) {
        throw "Le chemin '$Path' n'existe pas."
    }
    
    # Autres opérations...

}
catch {
    Write-Error "Une erreur s'est produite : $_"
    exit 1
}
finally {
    # Nettoyage

    Write-Verbose "Nettoyage des ressources"
}
```plaintext
## Script avec logging

```powershell
<#

.SYNOPSIS
    Description courte du script.
.DESCRIPTION
    Description détaillée du script.
.PARAMETER Path
    Chemin du fichier ou du dossier à traiter.
.PARAMETER LogFile
    Chemin du fichier de log.
.EXAMPLE
    .\Script.ps1 -Path "C:\Temp" -LogFile "C:\Logs\script.log"
.NOTES
    Nom du fichier    : Script.ps1
    Auteur           : Votre nom
    Date de création : 25/04/2025
    Version          : 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory=$false)]
    [string]$LogFile = ".\script.log"
)

# Fonction de logging

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Afficher le message dans la console

    switch ($Level) {
        'INFO' { Write-Verbose $logMessage }
        'WARNING' { Write-Warning $Message }
        'ERROR' { Write-Error $Message }
    }
    
    # Écrire dans le fichier de log

    Add-Content -Path $LogFile -Value $logMessage
}

# Code du script

try {
    Write-Log -Message "Début du script" -Level 'INFO'
    Write-Log -Message "Traitement de $Path" -Level 'INFO'
    
    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message "Le chemin '$Path' n'existe pas." -Level 'ERROR'
        exit 1
    }
    
    # Autres opérations...

    
    Write-Log -Message "Fin du script" -Level 'INFO'
}
catch {
    Write-Log -Message "Une erreur s'est produite : $_" -Level 'ERROR'
    exit 1
}
```plaintext
## Script avec exécution en mode batch

```powershell
<#

.SYNOPSIS
    Description courte du script.
.DESCRIPTION
    Description détaillée du script.
.PARAMETER Path
    Chemin du fichier ou du dossier à traiter.
.PARAMETER Force
    Force l'exécution sans demander de confirmation.
.EXAMPLE
    .\Script.ps1 -Path "C:\Temp" -Force
.NOTES
    Nom du fichier    : Script.ps1
    Auteur           : Votre nom
    Date de création : 25/04/2025
    Version          : 1.0
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Fonction pour demander une confirmation

function Get-YesNo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt
    )
    
    $response = Read-Host -Prompt "$Prompt (O/N)"
    return $response -match '^[Oo]'
}

# Code du script

if (-not $Force) {
    if (-not (Get-YesNo -Prompt "Voulez-vous traiter $Path ?")) {
        Write-Verbose "Opération annulée par l'utilisateur."
        return
    }
}

Write-Verbose "Traitement de $Path"

# Exemple d'opération avec suppression de confirmation

if (Test-Path -Path "$Path\temp") {
    Remove-Item -Path "$Path\temp" -Recurse -Force -Confirm:$false
}

# Autres opérations...

```plaintext
## Module PowerShell

```powershell
<#

.SYNOPSIS
    Module PowerShell d'exemple.
.DESCRIPTION
    Ce module contient des fonctions utilitaires.
.NOTES
    Nom du fichier    : Module.psm1
    Auteur           : Votre nom
    Date de création : 25/04/2025
    Version          : 1.0
#>

# Fonction publique

function Get-Something {
    <#

    .SYNOPSIS
        Récupère quelque chose.
    .DESCRIPTION
        Description détaillée de la fonction.
    .PARAMETER Name
        Nom de la chose à récupérer.
    .EXAMPLE
        Get-Something -Name "Test"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    Write-Verbose "Récupération de $Name"
    return $Name
}

# Fonction privée

function private:Get-SomethingInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    return "Internal: $Name"
}

# Exporter uniquement les fonctions publiques

Export-ModuleMember -Function Get-Something
```plaintext
## Fichier de manifeste de module (.psd1)

```powershell
@{
    # Version du module

    ModuleVersion = '1.0'
    
    # ID utilisé pour identifier de manière unique ce module

    GUID = '00000000-0000-0000-0000-000000000000'
    
    # Auteur de ce module

    Author = 'Votre nom'
    
    # Description de la fonctionnalité fournie par ce module

    Description = 'Description du module'
    
    # Version minimale du moteur PowerShell requise par ce module

    PowerShellVersion = '5.1'
    
    # Fonctions à exporter à partir de ce module

    FunctionsToExport = @('Get-Something')
    
    # Cmdlets à exporter à partir de ce module

    CmdletsToExport = @()
    
    # Variables à exporter à partir de ce module

    VariablesToExport = @()
    
    # Alias à exporter à partir de ce module

    AliasesToExport = @()
    
    # Fichiers privés du module

    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module pour faciliter la découverte

            Tags = @('Utility')
            
            # URL vers la page d'accueil de ce projet

            ProjectUri = 'https://github.com/username/project'
        }
    }
}
```plaintext