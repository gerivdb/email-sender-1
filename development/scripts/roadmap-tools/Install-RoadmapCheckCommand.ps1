<#
.SYNOPSIS
    Installe la commande de vérification de roadmap dans VS Code.

.DESCRIPTION
    Ce script installe une commande dans le menu contextuel de VS Code pour exécuter
    le mode CHECK sur les fichiers de roadmap. Il ajoute également un raccourci clavier
    pour exécuter la commande.

.PARAMETER VSCodeSettingsPath
    Chemin vers le fichier de paramètres de VS Code. Par défaut, utilise le chemin standard
    pour Windows.

.EXAMPLE
    .\Install-RoadmapCheckCommand.ps1

.NOTES
    Auteur: Roadmap Tools Team
    Version: 1.0
    Date de création: 2023-11-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VSCodeSettingsPath = "$env:APPDATA\Code\User\settings.json"
)

# Fonction pour vérifier si VS Code est installé
function Test-VSCodeInstalled {
    $vscodePath = Get-Command -Name "code" -ErrorAction SilentlyContinue
    return ($null -ne $vscodePath)
}

# Fonction pour vérifier si le fichier de paramètres de VS Code existe
function Test-VSCodeSettingsExist {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Test-Path -Path $Path)
}

# Fonction pour lire le fichier de paramètres de VS Code
function Get-VSCodeSettings {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $content = Get-Content -Path $Path -Raw -ErrorAction Stop
        $settings = ConvertFrom-Json -InputObject $content -ErrorAction Stop
        return $settings
    }
    catch {
        Write-Warning "Erreur lors de la lecture du fichier de paramètres de VS Code : $_"
        return $null
    }
}

# Fonction pour ajouter la commande de vérification de roadmap aux paramètres de VS Code
function Add-RoadmapCheckCommand {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Settings,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    # Convertir le chemin du script en chemin absolu
    $scriptFullPath = (Resolve-Path -Path $ScriptPath).Path
    
    # Échapper les barres obliques inverses dans le chemin
    $scriptPathEscaped = $scriptFullPath -replace '\\', '\\'
    
    # Vérifier si la propriété "powershell.commands" existe
    if (-not (Get-Member -InputObject $Settings -Name "powershell.commands" -MemberType NoteProperty)) {
        $Settings | Add-Member -NotePropertyName "powershell.commands" -NotePropertyValue @()
    }
    
    # Vérifier si la commande existe déjà
    $commandExists = $false
    foreach ($command in $Settings."powershell.commands") {
        if ($command.name -eq "roadmap.check") {
            $commandExists = $true
            $command.command = "& '$scriptPathEscaped'"
            break
        }
    }
    
    # Ajouter la commande si elle n'existe pas
    if (-not $commandExists) {
        $newCommand = [PSCustomObject]@{
            name = "roadmap.check"
            command = "& '$scriptPathEscaped'"
        }
        $Settings."powershell.commands" += $newCommand
    }
    
    # Vérifier si la propriété "powershell.keybindings" existe
    if (-not (Get-Member -InputObject $Settings -Name "powershell.keybindings" -MemberType NoteProperty)) {
        $Settings | Add-Member -NotePropertyName "powershell.keybindings" -NotePropertyValue @()
    }
    
    # Vérifier si le raccourci clavier existe déjà
    $keybindingExists = $false
    foreach ($keybinding in $Settings."powershell.keybindings") {
        if ($keybinding.command -eq "roadmap.check") {
            $keybindingExists = $true
            $keybinding.key = "ctrl+alt+c"
            break
        }
    }
    
    # Ajouter le raccourci clavier s'il n'existe pas
    if (-not $keybindingExists) {
        $newKeybinding = [PSCustomObject]@{
            command = "roadmap.check"
            key = "ctrl+alt+c"
        }
        $Settings."powershell.keybindings" += $newKeybinding
    }
    
    return $Settings
}

# Fonction pour sauvegarder les paramètres de VS Code
function Save-VSCodeSettings {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Settings,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $content = ConvertTo-Json -InputObject $Settings -Depth 10
        $content | Out-File -FilePath $Path -Encoding UTF8
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'écriture du fichier de paramètres de VS Code : $_"
        return $false
    }
}

# Script principal
function Install-RoadmapCheckCommand {
    # Vérifier si VS Code est installé
    if (-not (Test-VSCodeInstalled)) {
        Write-Error "VS Code n'est pas installé ou n'est pas dans le PATH."
        return
    }

    # Vérifier si le fichier de paramètres de VS Code existe
    if (-not (Test-VSCodeSettingsExist -Path $VSCodeSettingsPath)) {
        Write-Warning "Le fichier de paramètres de VS Code n'existe pas : $VSCodeSettingsPath"
        Write-Host "Création d'un nouveau fichier de paramètres..."
        $settings = [PSCustomObject]@{}
    }
    else {
        # Lire le fichier de paramètres de VS Code
        $settings = Get-VSCodeSettings -Path $VSCodeSettingsPath
        if ($null -eq $settings) {
            Write-Error "Impossible de lire le fichier de paramètres de VS Code."
            return
        }
    }

    # Chemin vers le script de vérification de roadmap
    $roadmapCheckScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-RoadmapCheck.ps1"
    
    if (-not (Test-Path -Path $roadmapCheckScriptPath)) {
        Write-Error "Le script de vérification de roadmap n'a pas été trouvé : $roadmapCheckScriptPath"
        return
    }

    # Ajouter la commande de vérification de roadmap aux paramètres de VS Code
    $settings = Add-RoadmapCheckCommand -Settings $settings -ScriptPath $roadmapCheckScriptPath

    # Sauvegarder les paramètres de VS Code
    $saved = Save-VSCodeSettings -Settings $settings -Path $VSCodeSettingsPath
    
    if ($saved) {
        Write-Host "La commande de vérification de roadmap a été installée avec succès." -ForegroundColor Green
        Write-Host "Vous pouvez maintenant utiliser la commande 'roadmap.check' dans VS Code." -ForegroundColor Green
        Write-Host "Raccourci clavier : Ctrl+Alt+C" -ForegroundColor Green
    }
    else {
        Write-Error "Échec de l'installation de la commande de vérification de roadmap."
    }
}

# Exécuter le script principal
Install-RoadmapCheckCommand
