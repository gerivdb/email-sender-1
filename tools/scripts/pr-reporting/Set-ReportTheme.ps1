#Requires -Version 5.1
<#
.SYNOPSIS
    Configure le thème pour les rapports d'analyse de pull requests.

.DESCRIPTION
    Ce script permet de configurer le thème par défaut pour les rapports
    d'analyse de pull requests, ainsi que de personnaliser les couleurs
    et les styles.

.PARAMETER Theme
    Le thème à utiliser pour les rapports.
    Valeurs possibles: "Light", "Dark", "Blue", "Green", "Custom"
    Par défaut: "Light"

.PARAMETER PrimaryColor
    La couleur principale du thème. Utilisé uniquement avec le thème "Custom".
    Format: code hexadécimal (#RRGGBB)
    Par défaut: "#4285F4"

.PARAMETER BackgroundColor
    La couleur d'arrière-plan du thème. Utilisé uniquement avec le thème "Custom".
    Format: code hexadécimal (#RRGGBB)
    Par défaut: "#FFFFFF"

.PARAMETER TextColor
    La couleur du texte du thème. Utilisé uniquement avec le thème "Custom".
    Format: code hexadécimal (#RRGGBB)
    Par défaut: "#333333"

.PARAMETER BorderColor
    La couleur des bordures du thème. Utilisé uniquement avec le thème "Custom".
    Format: code hexadécimal (#RRGGBB)
    Par défaut: "#DDDDDD"

.PARAMETER SaveAsDefault
    Indique s'il faut enregistrer le thème comme thème par défaut.
    Par défaut: $true

.PARAMETER ConfigPath
    Le chemin du fichier de configuration des thèmes.
    Par défaut: "config\report-themes.json"

.EXAMPLE
    .\Set-ReportTheme.ps1 -Theme "Dark"
    Configure le thème sombre comme thème par défaut pour les rapports.

.EXAMPLE
    .\Set-ReportTheme.ps1 -Theme "Custom" -PrimaryColor "#FF5722" -BackgroundColor "#FAFAFA" -TextColor "#212121"
    Configure un thème personnalisé avec les couleurs spécifiées.

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

# Créer le répertoire de configuration s'il n'existe pas
$configDir = Split-Path -Path $ConfigPath -Parent
if (-not [string]::IsNullOrWhiteSpace($configDir) -and -not (Test-Path -Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
}

# Définir les thèmes prédéfinis
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
        Write-Warning "Utilisation de la configuration par défaut."
    }
}

# Créer ou mettre à jour le thème personnalisé
if ($Theme -eq "Custom") {
    $customTheme = @{
        PrimaryColor = $PrimaryColor
        BackgroundColor = $BackgroundColor
        TextColor = $TextColor
        BorderColor = $BorderColor
        CardBackground = LightenOrDarken -Color $BackgroundColor -Amount 0.05
        HoverColor = LightenOrDarken -Color $BackgroundColor -Amount 0.1
    }
    
    # Générer un nom unique pour le thème personnalisé
    $customThemeName = "Custom_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $config.CustomThemes[$customThemeName] = $customTheme
    
    # Définir le thème personnalisé comme thème actif
    $activeTheme = $customTheme
    $activeThemeName = $customThemeName
} else {
    # Utiliser un thème prédéfini
    $activeTheme = $predefinedThemes[$Theme]
    $activeThemeName = $Theme
}

# Enregistrer le thème comme thème par défaut si demandé
if ($SaveAsDefault) {
    $config.DefaultTheme = $activeThemeName
}

# Enregistrer la configuration
$configJson = $config | ConvertTo-Json -Depth 5
Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8

# Afficher un résumé
Write-Host "Configuration du thème terminée" -ForegroundColor Green
Write-Host "  Thème: $activeThemeName" -ForegroundColor White
Write-Host "  Couleur principale: $($activeTheme.PrimaryColor)" -ForegroundColor White
Write-Host "  Couleur d'arrière-plan: $($activeTheme.BackgroundColor)" -ForegroundColor White
Write-Host "  Couleur du texte: $($activeTheme.TextColor)" -ForegroundColor White
Write-Host "  Couleur des bordures: $($activeTheme.BorderColor)" -ForegroundColor White

if ($SaveAsDefault) {
    Write-Host "  Thème enregistré comme thème par défaut" -ForegroundColor White
}

Write-Host "  Configuration enregistrée dans: $ConfigPath" -ForegroundColor White

# Fonction pour éclaircir ou assombrir une couleur
function LightenOrDarken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Color,
        
        [Parameter(Mandatory = $true)]
        [double]$Amount
    )
    
    # Convertir la couleur hexadécimale en composantes RGB
    $r = [Convert]::ToInt32($Color.Substring(1, 2), 16)
    $g = [Convert]::ToInt32($Color.Substring(3, 2), 16)
    $b = [Convert]::ToInt32($Color.Substring(5, 2), 16)
    
    # Déterminer s'il faut éclaircir ou assombrir
    $isDark = ($r * 0.299 + $g * 0.587 + $b * 0.114) < 128
    
    if ($isDark) {
        # Éclaircir
        $r = [Math]::Min(255, $r + 255 * $Amount)
        $g = [Math]::Min(255, $g + 255 * $Amount)
        $b = [Math]::Min(255, $b + 255 * $Amount)
    } else {
        # Assombrir
        $r = [Math]::Max(0, $r - 255 * $Amount)
        $g = [Math]::Max(0, $g - 255 * $Amount)
        $b = [Math]::Max(0, $b - 255 * $Amount)
    }
    
    # Convertir en hexadécimal
    return "#{0:X2}{1:X2}{2:X2}" -f [int]$r, [int]$g, [int]$b
}

# Retourner le thème actif
return @{
    Name = $activeThemeName
    Theme = $activeTheme
}
