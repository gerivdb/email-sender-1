# Format-TextToRoadmap-Enhanced.ps1
# Script ameliore pour reformater du texte en format roadmap avec support pour differents formats


# Format-TextToRoadmap-Enhanced.ps1
# Script ameliore pour reformater du texte en format roadmap avec support pour differents formats

param (
    [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$InputFile = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "",

    [Parameter(Mandatory = $false)]
    [string]$Text = "",

    [Parameter(Mandatory = $false)]
    [string]$SectionTitle = "Nouvelle section",

    [Parameter(Mandatory = $false)]
    [string]$Complexity = "Moyenne",

    [Parameter(Mandatory = $false)]
    [string]$TimeEstimate = "3-5 jours",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Plain", "Markdown", "CSV", "JSON", "YAML")]
    [string]$InputFormat = "Auto",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Roadmap", "Markdown", "CSV", "JSON", "YAML")]
    [string]$OutputFormat = "Roadmap",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeMetadata,
    
    [Parameter(Mandatory = $false)]
    [switch]$Hierarchical,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeCheckboxes
)

# Importer le module Format-Converters
$ConvertersModule = Join-Path -Path $PSScriptRoot -ChildPath "Format-Converters.psm1"
if (Test-Path -Path $ConvertersModule) {
    Import-Module $ConvertersModule -Force
} else {
    Write-Error "Module Format-Converters non trouve: $ConvertersModule"
    exit 1
}

# Fonction pour formater le texte en format roadmap
function Format-TextToRoadmap {
    param (
        [string]$InputText,
        [string]$SectionTitle,
        [string]$Complexity,
        [string]$TimeEstimate
    )
    
    # Importer le script Format-TextToRoadmap.ps1
    $FormatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap.ps1"
    if (Test-Path -Path $FormatScript) {
        $formattedText = & $FormatScript -Text $InputText -SectionTitle $SectionTitle -Complexity $Complexity -TimeEstimate $TimeEstimate
        return $formattedText
    } else {
        Write-Error "Script Format-TextToRoadmap.ps1 non trouve: $FormatScript"
        exit 1
    }
}

# Fonction principale
function Main {
    # Obtenir le texte a formater
    $textToFormat = ""
    
    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        $textToFormat = $Text
    } elseif (-not [string]::IsNullOrWhiteSpace($InputFile) -and (Test-Path -Path $InputFile)) {
        $textToFormat = Get-Content -Path $InputFile -Raw
    } else {
        Write-Error "Aucun texte a formater. Utilisez le parametre -Text ou -InputFile."
        exit 1
    }
    
    # Convertir le texte depuis le format d'entree
    if ($InputFormat -ne "Plain") {
        $textToFormat = ConvertFrom-TextFormat -InputText $textToFormat -Format $InputFormat
    }
    
    # Si le format de sortie est Roadmap, formater le texte en format roadmap
    if ($OutputFormat -eq "Roadmap") {
        $formattedText = Format-TextToRoadmap -InputText $textToFormat -SectionTitle $SectionTitle -Complexity $Complexity -TimeEstimate $TimeEstimate
    } else {
        # Sinon, formater d'abord en format roadmap, puis convertir vers le format de sortie
        $roadmapText = Format-TextToRoadmap -InputText $textToFormat -SectionTitle $SectionTitle -Complexity $Complexity -TimeEstimate $TimeEstimate
        $formattedText = ConvertTo-TextFormat -RoadmapText $roadmapText -Format $OutputFormat -IncludeMetadata:$IncludeMetadata -Hierarchical:$Hierarchical -IncludeCheckboxes:$IncludeCheckboxes
    }
    
    # Enregistrer le texte formate dans un fichier si demande
    if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
        Set-Content -Path $OutputFile -Value $formattedText
        Write-Host "Le texte formate a ete enregistre dans le fichier $OutputFile" -ForegroundColor Green
    }
    
    # Retourner le texte formate
    return $formattedText
}

# Executer la fonction principale
Main

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
