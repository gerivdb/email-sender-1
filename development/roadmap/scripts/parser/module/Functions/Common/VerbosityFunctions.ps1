<#
.SYNOPSIS
    Fonctions de gestion de la verbositÃ© pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions pour configurer et gÃ©rer la verbositÃ©
    des messages de journalisation dans les diffÃ©rents modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Configuration par dÃ©faut pour la verbositÃ©
$script:VerbosityConfig = @{
    # Niveau de verbositÃ© global
    Level      = "Normal"  # Valeurs possibles : "Minimal", "Normal", "Detailed", "Debug", "Diagnostic"

    # Formats de message par niveau de verbositÃ©
    Formats    = @{
        "Minimal"    = "[{0}] {1}"  # Niveau, Message
        "Normal"     = "[{0}] [{1}] {2}"  # Timestamp, Niveau, Message
        "Detailed"   = "[{0}] [{1}] [{2}] {3}"  # Timestamp, Niveau, CatÃ©gorie, Message
        "Debug"      = "[{0}] [{1}] [{2}] [{3}] {4}"  # Timestamp, Niveau, CatÃ©gorie, Source, Message
        "Diagnostic" = "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"  # Timestamp, Niveau, CatÃ©gorie, Source, ID, Message
    }

    # CatÃ©gories activÃ©es par niveau de verbositÃ©
    Categories = @{
        "Minimal"    = @("Error", "Critical")
        "Normal"     = @("Error", "Critical", "Warning", "Info")
        "Detailed"   = @("Error", "Critical", "Warning", "Info", "Verbose")
        "Debug"      = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug")
        "Diagnostic" = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug", "Trace")
    }

    # PrÃ©rÃ©glages de verbositÃ©
    Presets    = @{
        "Silent"      = @{
            Level      = "Minimal"
            Categories = @("Critical")
            Format     = "[{0}] {1}"  # Niveau, Message
        }
        "Production"  = @{
            Level      = "Normal"
            Categories = @("Error", "Critical", "Warning")
            Format     = "[{0}] [{1}] {2}"  # Timestamp, Niveau, Message
        }
        "Development" = @{
            Level      = "Detailed"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose")
            Format     = "[{0}] [{1}] [{2}] {3}"  # Timestamp, Niveau, CatÃ©gorie, Message
        }
        "Debugging"   = @{
            Level      = "Debug"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug")
            Format     = "[{0}] [{1}] [{2}] [{3}] {4}"  # Timestamp, Niveau, CatÃ©gorie, Source, Message
        }
        "Diagnostic"  = @{
            Level      = "Diagnostic"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug", "Trace")
            Format     = "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"  # Timestamp, Niveau, CatÃ©gorie, Source, ID, Message
        }
    }
}

<#
.SYNOPSIS
    Obtient la configuration actuelle de verbositÃ©.

.DESCRIPTION
    Cette fonction retourne la configuration actuelle de verbositÃ©.

.EXAMPLE
    $config = Get-VerbosityConfig

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-VerbosityConfig {
    [CmdletBinding()]
    param()

    return $script:VerbosityConfig
}

<#
.SYNOPSIS
    DÃ©finit le niveau de verbositÃ©.

.DESCRIPTION
    Cette fonction dÃ©finit le niveau de verbositÃ© global.

.PARAMETER Level
    Niveau de verbositÃ© Ã  utiliser.

.EXAMPLE
    Set-VerbosityLevel -Level "Detailed"

.OUTPUTS
    None
#>
function Set-VerbosityLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Debug", "Diagnostic")]
        [string]$Level
    )

    $script:VerbosityConfig.Level = $Level
    Write-Verbose "Niveau de verbositÃ© dÃ©fini Ã  : $Level"
}

<#
.SYNOPSIS
    Obtient le niveau de verbositÃ© actuel.

.DESCRIPTION
    Cette fonction retourne le niveau de verbositÃ© actuel.

.EXAMPLE
    $level = Get-VerbosityLevel

.OUTPUTS
    System.String
#>
function Get-VerbosityLevel {
    [CmdletBinding()]
    param()

    return $script:VerbosityConfig.Level
}

<#
.SYNOPSIS
    DÃ©finit le format de message pour un niveau de verbositÃ© spÃ©cifique.

.DESCRIPTION
    Cette fonction dÃ©finit le format de message pour un niveau de verbositÃ© spÃ©cifique.

.PARAMETER Level
    Niveau de verbositÃ© pour lequel dÃ©finir le format.

.PARAMETER Format
    Format de message Ã  utiliser.

.EXAMPLE
    Set-VerbosityFormat -Level "Detailed" -Format "[{0}] [{1}] [{2}] {3}"

.OUTPUTS
    None
#>
function Set-VerbosityFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Debug", "Diagnostic")]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    $script:VerbosityConfig.Formats[$Level] = $Format
    Write-Verbose "Format de verbositÃ© dÃ©fini pour le niveau $Level : $Format"
}

<#
.SYNOPSIS
    Obtient le format de message pour un niveau de verbositÃ© spÃ©cifique.

.DESCRIPTION
    Cette fonction retourne le format de message pour un niveau de verbositÃ© spÃ©cifique.

.PARAMETER Level
    Niveau de verbositÃ© pour lequel obtenir le format.

.EXAMPLE
    $format = Get-VerbosityFormat -Level "Detailed"

.OUTPUTS
    System.String
#>
function Get-VerbosityFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Debug", "Diagnostic")]
        [string]$Level
    )

    return $script:VerbosityConfig.Formats[$Level]
}

<#
.SYNOPSIS
    DÃ©finit les catÃ©gories activÃ©es pour un niveau de verbositÃ© spÃ©cifique.

.DESCRIPTION
    Cette fonction dÃ©finit les catÃ©gories activÃ©es pour un niveau de verbositÃ© spÃ©cifique.

.PARAMETER Level
    Niveau de verbositÃ© pour lequel dÃ©finir les catÃ©gories.

.PARAMETER Categories
    CatÃ©gories Ã  activer.

.EXAMPLE
    Set-VerbosityCategories -Level "Detailed" -Categories "Error", "Critical", "Warning", "Info", "Verbose"

.OUTPUTS
    None
#>
function Set-VerbosityCategories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Debug", "Diagnostic")]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string[]]$Categories
    )

    $script:VerbosityConfig.Categories[$Level] = $Categories
    Write-Verbose "CatÃ©gories de verbositÃ© dÃ©finies pour le niveau $Level : $($Categories -join ', ')"
}

<#
.SYNOPSIS
    Obtient les catÃ©gories activÃ©es pour un niveau de verbositÃ© spÃ©cifique.

.DESCRIPTION
    Cette fonction retourne les catÃ©gories activÃ©es pour un niveau de verbositÃ© spÃ©cifique.

.PARAMETER Level
    Niveau de verbositÃ© pour lequel obtenir les catÃ©gories.

.EXAMPLE
    $categories = Get-VerbosityCategories -Level "Detailed"

.OUTPUTS
    System.String[]
#>
function Get-VerbosityCategories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Debug", "Diagnostic")]
        [string]$Level
    )

    return $script:VerbosityConfig.Categories[$Level]
}

<#
.SYNOPSIS
    Applique un prÃ©rÃ©glage de verbositÃ©.

.DESCRIPTION
    Cette fonction applique un prÃ©rÃ©glage de verbositÃ© prÃ©dÃ©fini.

.PARAMETER PresetName
    Nom du prÃ©rÃ©glage Ã  appliquer.

.EXAMPLE
    Set-VerbosityPreset -PresetName "Development"

.OUTPUTS
    None
#>
function Set-VerbosityPreset {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Silent", "Production", "Development", "Debugging", "Diagnostic")]
        [string]$PresetName
    )

    $preset = $script:VerbosityConfig.Presets[$PresetName]

    $script:VerbosityConfig.Level = $preset.Level

    if ($preset.Categories) {
        $script:VerbosityConfig.Categories[$preset.Level] = $preset.Categories
    }

    if ($preset.Format) {
        $script:VerbosityConfig.Formats[$preset.Level] = $preset.Format
    }

    Write-Verbose "PrÃ©rÃ©glage de verbositÃ© appliquÃ© : $PresetName"
}

<#
.SYNOPSIS
    VÃ©rifie si un message doit Ãªtre journalisÃ© en fonction de la configuration de verbositÃ©.

.DESCRIPTION
    Cette fonction vÃ©rifie si un message doit Ãªtre journalisÃ© en fonction de la configuration de verbositÃ©.

.PARAMETER Category
    CatÃ©gorie du message.

.EXAMPLE
    $shouldLog = Test-VerbosityLogLevel -Category "Debug"

.OUTPUTS
    System.Boolean
#>
function Test-VerbosityLogLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    $currentLevel = $script:VerbosityConfig.Level
    $enabledCategories = $script:VerbosityConfig.Categories[$currentLevel]

    return $enabledCategories -contains $Category
}

<#
.SYNOPSIS
    Formate un message en fonction de la configuration de verbositÃ©.

.DESCRIPTION
    Cette fonction formate un message en fonction de la configuration de verbositÃ©.

.PARAMETER Message
    Message Ã  formater.

.PARAMETER Level
    Niveau de journalisation du message.

.PARAMETER Category
    CatÃ©gorie du message.

.PARAMETER Source
    Source du message.

.PARAMETER Id
    Identifiant du message.

.EXAMPLE
    $formattedMessage = Format-MessageByVerbosity -Message "Une erreur s'est produite." -Level "Error" -Category "Database" -Source "UserRepository" -Id "DB001"

.OUTPUTS
    System.String
#>
function Format-MessageByVerbosity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$Level,

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [string]$Source = "",

        [Parameter(Mandatory = $false)]
        [string]$Id = ""
    )

    $currentLevel = $script:VerbosityConfig.Level
    $format = $script:VerbosityConfig.Formats[$currentLevel]
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    switch ($currentLevel) {
        "Minimal" {
            return $format -f $Level, $Message
        }
        "Normal" {
            return $format -f $timestamp, $Level, $Message
        }
        "Detailed" {
            return $format -f $timestamp, $Level, $Category, $Message
        }
        "Debug" {
            return $format -f $timestamp, $Level, $Category, $Source, $Message
        }
        "Diagnostic" {
            return $format -f $timestamp, $Level, $Category, $Source, $Id, $Message
        }
    }
}

<#
.SYNOPSIS
    Journalise un message en fonction de la configuration de verbositÃ©.

.DESCRIPTION
    Cette fonction journalise un message en fonction de la configuration de verbositÃ©.

.PARAMETER Message
    Message Ã  journaliser.

.PARAMETER Level
    Niveau de journalisation du message.

.PARAMETER Category
    CatÃ©gorie du message.

.PARAMETER Source
    Source du message.

.PARAMETER Id
    Identifiant du message.

.PARAMETER LogFile
    Chemin vers le fichier de journalisation.

.EXAMPLE
    Write-LogWithVerbosity -Message "Une erreur s'est produite." -Level "Error" -Category "Database" -Source "UserRepository" -Id "DB001" -LogFile "logs\app.log"

.OUTPUTS
    None
#>
function Write-LogWithVerbosity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Critical", "Error", "Warning", "Info", "Verbose", "Debug", "Trace")]
        [string]$Level,

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [string]$Source = "",

        [Parameter(Mandatory = $false)]
        [string]$Id = "",

        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )

    if (-not (Test-VerbosityLogLevel -Category $Level)) {
        return
    }

    $formattedMessage = Format-MessageByVerbosity -Message $Message -Level $Level -Category $Category -Source $Source -Id $Id

    # Afficher le message dans la console avec la couleur appropriÃ©e
    switch ($Level) {
        "Critical" { Write-Host $formattedMessage -ForegroundColor Red -BackgroundColor Black }
        "Error" { Write-Host $formattedMessage -ForegroundColor Red }
        "Warning" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "Info" { Write-Host $formattedMessage -ForegroundColor White }
        "Verbose" { Write-Host $formattedMessage -ForegroundColor Gray }
        "Debug" { Write-Host $formattedMessage -ForegroundColor DarkGray }
        "Trace" { Write-Host $formattedMessage -ForegroundColor DarkCyan }
    }

    # Journaliser dans un fichier si spÃ©cifiÃ©
    if ($LogFile) {
        # CrÃ©er le rÃ©pertoire parent s'il n'existe pas
        $parentDir = Split-Path -Parent $LogFile
        if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path -Path $parentDir)) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }

        Add-Content -Path $LogFile -Value $formattedMessage -Encoding UTF8
    }
}

# Exporter les fonctions
if ($MyInvocation.ScriptName -ne '') {
    # Nous sommes dans un module
    Export-ModuleMember -Function Get-VerbosityConfig, Set-VerbosityLevel, Get-VerbosityLevel, Set-VerbosityFormat, Get-VerbosityFormat, Set-VerbosityCategories, Get-VerbosityCategories, Set-VerbosityPreset, Test-VerbosityLogLevel, Format-MessageByVerbosity, Write-LogWithVerbosity
}
