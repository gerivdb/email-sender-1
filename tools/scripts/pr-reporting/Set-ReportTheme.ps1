#Requires -Version 5.1
<#
.SYNOPSIS
    Configure le thÃ¨me pour les rapports d'analyse de pull requests.

.DESCRIPTION
    Ce script permet de configurer le thÃ¨me par dÃ©faut pour les rapports
    d'analyse de pull requests, ainsi que de personnaliser les couleurs
    et les styles.

.PARAMETER Theme
    Le thÃ¨me Ã  utiliser pour les rapports.
    Valeurs possibles: "Light", "Dark", "Blue", "Green", "Custom"
    Par dÃ©faut: "Light"

.PARAMETER PrimaryColor
    La couleur principale du thÃ¨me. UtilisÃ© uniquement avec le thÃ¨me "Custom".
    Format: code hexadÃ©cimal (#RRGGBB)
    Par dÃ©faut: "#4285F4"

.PARAMETER BackgroundColor
    La couleur d'arriÃ¨re-plan du thÃ¨me. UtilisÃ© uniquement avec le thÃ¨me "Custom".
    Format: code hexadÃ©cimal (#RRGGBB)
    Par dÃ©faut: "#FFFFFF"

.PARAMETER TextColor
    La couleur du texte du thÃ¨me. UtilisÃ© uniquement avec le thÃ¨me "Custom".
    Format: code hexadÃ©cimal (#RRGGBB)
    Par dÃ©faut: "#333333"

.PARAMETER BorderColor
    La couleur des bordures du thÃ¨me. UtilisÃ© uniquement avec le thÃ¨me "Custom".
    Format: code hexadÃ©cimal (#RRGGBB)
    Par dÃ©faut: "#DDDDDD"

.PARAMETER SaveAsDefault
    Indique s'il faut enregistrer le thÃ¨me comme thÃ¨me par dÃ©faut.
    Par dÃ©faut: $true

.PARAMETER ConfigPath
    Le chemin du fichier de configuration des thÃ¨mes.
    Par dÃ©faut: "config\report-themes.json"

.EXAMPLE
    .\Set-ReportTheme.ps1 -Theme "Dark"
    Configure le thÃ¨me sombre comme thÃ¨me par dÃ©faut pour les rapports.

.EXAMPLE
    .\Set-ReportTheme.ps1 -Theme "Custom" -PrimaryColor "#FF5722" -BackgroundColor "#FAFAFA" -TextColor "#212121"
    Configure un thÃ¨me personnalisÃ© avec les couleurs spÃ©cifiÃ©es.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Light", "Dark", "Blue", "Green", "Custom")]
    [string]$Theme = "Light",

    [Parameter()]
    [ValidatePattern("^#[0-9A-Fa-f]{6}$")]
    [string]$PrimaryColor = "#4285F4",

    [Parameter()]
    [ValidatePattern("^#[0-9A-Fa-f]{6}$")]
    [string]$BackgroundColor = "#FFFFFF",

    [Parameter()]
    [ValidatePattern("^#[0-9A-Fa-f]{6}$")]
    [string]$TextColor = "#333333",

    [Parameter()]
    [ValidatePattern("^#[0-9A-Fa-f]{6}$")]
    [string]$BorderColor = "#DDDDDD",

    [Parameter()]
    [bool]$SaveAsDefault = $true,

    [Parameter()]
    [string]$ConfigPath = "config\report-themes.json"
)

# CrÃ©er le rÃ©pertoire de configuration s'il n'existe pas
$configDir = Split-Path -Path $ConfigPath -Parent
if (-not [string]::IsNullOrWhiteSpace($configDir) -and -not (Test-Path -Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir les thÃ¨mes prÃ©dÃ©finis
$predefinedThemes = @{
    "Light" = @{
        PrimaryColor = "#4285F4"
        BackgroundColor = "#FFFFFF"
        TextColor = "#333333"
        BorderColor = "#DDDDDD"
        CardBackground = "#F8F9FA"
        HoverColor = "#E9ECEF"
    }
    "Dark" = @{
        PrimaryColor = "#BB86FC"
        BackgroundColor = "#121212"
        TextColor = "#E0E0E0"
        BorderColor = "#333333"
        CardBackground = "#1E1E1E"
        HoverColor = "#2D2D2D"
    }
    "Blue" = @{
        PrimaryColor = "#0078D7"
        BackgroundColor = "#F0F8FF"
        TextColor = "#333333"
        BorderColor = "#B0C4DE"
        CardBackground = "#E6F2FF"
        HoverColor = "#D4E6F9"
    }
    "Green" = @{
        PrimaryColor = "#34A853"
        BackgroundColor = "#F0FFF0"
        TextColor = "#333333"
        BorderColor = "#C0DCC0"
        CardBackground = "#E6FFE6"
        HoverColor = "#D4F9D4"
    }
}

# Charger la configuration existante si elle existe
$config = @{
    DefaultTheme = "Light"
    Themes = $predefinedThemes
    CustomThemes = @{}
}

if (Test-Path -Path $ConfigPath) {
    try {
        $existingConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        # Convertir l'objet JSON en hashtable
        $config.DefaultTheme = $existingConfig.DefaultTheme
        
        if ($existingConfig.CustomThemes) {
            $customThemes = @{}
            foreach ($theme in $existingConfig.CustomThemes.PSObject.Properties) {
                $customThemes[$theme.Name] = @{}
                foreach ($prop in $theme.Value.PSObject.Properties) {
                    $customThemes[$theme.Name][$prop.Name] = $prop.Value
                }
            }
            $config.CustomThemes = $customThemes
        }
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration existante: $_"
        Write-Warning "Utilisation de la configuration par dÃ©faut."
    }
}

# CrÃ©er ou mettre Ã  jour le thÃ¨me personnalisÃ©
if ($Theme -eq "Custom") {
    $customTheme = @{
        PrimaryColor = $PrimaryColor
        BackgroundColor = $BackgroundColor
        TextColor = $TextColor
        BorderColor = $BorderColor
        CardBackground = LightenOrDarken -Color $BackgroundColor -Amount 0.05
        HoverColor = LightenOrDarken -Color $BackgroundColor -Amount 0.1
    }
    
    # GÃ©nÃ©rer un nom unique pour le thÃ¨me personnalisÃ©
    $customThemeName = "Custom_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $config.CustomThemes[$customThemeName] = $customTheme
    
    # DÃ©finir le thÃ¨me personnalisÃ© comme thÃ¨me actif
    $activeTheme = $customTheme
    $activeThemeName = $customThemeName
} else {
    # Utiliser un thÃ¨me prÃ©dÃ©fini
    $activeTheme = $predefinedThemes[$Theme]
    $activeThemeName = $Theme
}

# Enregistrer le thÃ¨me comme thÃ¨me par dÃ©faut si demandÃ©
if ($SaveAsDefault) {
    $config.DefaultTheme = $activeThemeName
}

# Enregistrer la configuration
$configJson = $config | ConvertTo-Json -Depth 5
Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8

# Afficher un rÃ©sumÃ©
Write-Host "Configuration du thÃ¨me terminÃ©e" -ForegroundColor Green
Write-Host "  ThÃ¨me: $activeThemeName" -ForegroundColor White
Write-Host "  Couleur principale: $($activeTheme.PrimaryColor)" -ForegroundColor White
Write-Host "  Couleur d'arriÃ¨re-plan: $($activeTheme.BackgroundColor)" -ForegroundColor White
Write-Host "  Couleur du texte: $($activeTheme.TextColor)" -ForegroundColor White
Write-Host "  Couleur des bordures: $($activeTheme.BorderColor)" -ForegroundColor White

if ($SaveAsDefault) {
    Write-Host "  ThÃ¨me enregistrÃ© comme thÃ¨me par dÃ©faut" -ForegroundColor White
}

Write-Host "  Configuration enregistrÃ©e dans: $ConfigPath" -ForegroundColor White

# Fonction pour Ã©claircir ou assombrir une couleur
function LightenOrDarken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Color,
        
        [Parameter(Mandatory = $true)]
        [double]$Amount
    )
    
    # Convertir la couleur hexadÃ©cimale en composantes RGB
    $r = [Convert]::ToInt32($Color.Substring(1, 2), 16)
    $g = [Convert]::ToInt32($Color.Substring(3, 2), 16)
    $b = [Convert]::ToInt32($Color.Substring(5, 2), 16)
    
    # DÃ©terminer s'il faut Ã©claircir ou assombrir
    $isDark = ($r * 0.299 + $g * 0.587 + $b * 0.114) < 128
    
    if ($isDark) {
        # Ã‰claircir
        $r = [Math]::Min(255, $r + 255 * $Amount)
        $g = [Math]::Min(255, $g + 255 * $Amount)
        $b = [Math]::Min(255, $b + 255 * $Amount)
    } else {
        # Assombrir
        $r = [Math]::Max(0, $r - 255 * $Amount)
        $g = [Math]::Max(0, $g - 255 * $Amount)
        $b = [Math]::Max(0, $b - 255 * $Amount)
    }
    
    # Convertir en hexadÃ©cimal
    return "#{0:X2}{1:X2}{2:X2}" -f [int]$r, [int]$g, [int]$b
}

# Retourner le thÃ¨me actif
return @{
    Name = $activeThemeName
    Theme = $activeTheme
}
