#Requires -Version 5.1
<#
.SYNOPSIS
    Fonctions de base pour le module Format-Converters.

.DESCRIPTION
    Ce script contient les fonctions de base pour le module Format-Converters,
    notamment les fonctions pour enregistrer et récupérer les convertisseurs de format.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Hashtable pour stocker les convertisseurs de format
$script:FormatConverters = @{}

# Fonction pour enregistrer un convertisseur de format
function Register-FormatConverter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Format,

        [Parameter(Mandatory = $true)]
        [hashtable]$ConverterInfo
    )

    # Vérifier que le format n'est pas déjà enregistré
    if ($script:FormatConverters.ContainsKey($Format)) {
        Write-Warning "Le format '$Format' est déjà enregistré. Il sera remplacé."
    }

    # Vérifier que les informations requises sont présentes
    $requiredKeys = @("Name", "Description", "Extensions")
    $missingKeys = $requiredKeys | Where-Object { -not $ConverterInfo.ContainsKey($_) }

    if ($missingKeys.Count -gt 0) {
        throw "Les informations suivantes sont manquantes pour le format '$Format' : $($missingKeys -join ", ")"
    }

    # Enregistrer le convertisseur
    $script:FormatConverters[$Format] = $ConverterInfo

    Write-Verbose "Convertisseur de format '$Format' enregistré avec succès."
}

# Fonction pour récupérer les convertisseurs de format enregistrés
function Get-RegisteredConverters {
    [CmdletBinding()]
    param()

    return $script:FormatConverters
}

# Fonction pour récupérer un convertisseur de format spécifique
function Get-FormatConverter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    if (-not $script:FormatConverters.ContainsKey($Format)) {
        throw "Le format '$Format' n'est pas enregistré."
    }

    return $script:FormatConverters[$Format]
}

# Fonction pour convertir un fichier d'un format à un autre
function Convert-FileFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$InputFormat,

        [Parameter(Mandatory = $true)]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [switch]$AutoDetect,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )

    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath -PathType Leaf)) {
        throw "Le fichier d'entrée '$InputPath' n'existe pas."
    }

    # Vérifier si le fichier de sortie existe et si -Force n'est pas spécifié
    if ((Test-Path -Path $OutputPath -PathType Leaf) -and -not $Force) {
        throw "Le fichier de sortie '$OutputPath' existe déjà. Utilisez -Force pour l'écraser."
    }

    # Détecter le format d'entrée si nécessaire
    if (-not $InputFormat -and $AutoDetect) {
        $detectionResult = Detect-FileFormat -FilePath $InputPath
        $InputFormat = $detectionResult.DetectedFormat

        if (-not $InputFormat) {
            throw "Impossible de détecter le format du fichier d'entrée '$InputPath'."
        }

        Write-Verbose "Format d'entrée détecté : $InputFormat"
    }

    # Vérifier que les formats d'entrée et de sortie sont enregistrés
    if (-not $script:FormatConverters.ContainsKey($InputFormat.ToLower())) {
        throw "Le format d'entrée '$InputFormat' n'est pas pris en charge."
    }

    if (-not $script:FormatConverters.ContainsKey($OutputFormat.ToLower())) {
        throw "Le format de sortie '$OutputFormat' n'est pas pris en charge."
    }

    # Récupérer les convertisseurs
    $inputConverter = $script:FormatConverters[$InputFormat.ToLower()]
    $outputConverter = $script:FormatConverters[$OutputFormat.ToLower()]

    # Vérifier que les fonctions d'importation et d'exportation sont disponibles
    if (-not $inputConverter.ImportFunction) {
        throw "Le format d'entrée '$InputFormat' ne prend pas en charge l'importation."
    }

    if (-not $outputConverter.ExportFunction) {
        throw "Le format de sortie '$OutputFormat' ne prend pas en charge l'exportation."
    }

    try {
        # Afficher la progression
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Importation du fichier $InputPath" -PercentComplete 25
        }

        # Importer le fichier
        $data = & $inputConverter.ImportFunction $InputPath

        # Afficher la progression
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Exportation vers $OutputPath" -PercentComplete 75
        }

        # Exporter le fichier
        & $outputConverter.ExportFunction $data $OutputPath

        # Afficher la progression
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Terminé" -PercentComplete 100
        }

        return [PSCustomObject]@{
            Success = $true
            InputPath = $InputPath
            OutputPath = $OutputPath
            InputFormat = $InputFormat
            OutputFormat = $OutputFormat
            Message = "Conversion réussie."
        }
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            InputPath = $InputPath
            OutputPath = $OutputPath
            InputFormat = $InputFormat
            OutputFormat = $OutputFormat
            Message = "Erreur lors de la conversion : $_"
        }
    }
}

# Fonction pour obtenir l'analyse du format d'un fichier
function Get-FileFormatAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$AutoDetect,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,

        [Parameter(Mandatory = $false)]
        [switch]$ExportReport,

        [Parameter(Mandatory = $false)]
        [string]$ReportPath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Détecter le format si nécessaire
    if (-not $Format -and $AutoDetect) {
        $detectionResult = Detect-FileFormat -FilePath $FilePath
        $Format = $detectionResult.DetectedFormat

        if (-not $Format) {
            throw "Impossible de détecter le format du fichier '$FilePath'."
        }

        Write-Verbose "Format détecté : $Format"
    }

    # Vérifier que le format est enregistré
    if (-not $script:FormatConverters.ContainsKey($Format.ToLower())) {
        throw "Le format '$Format' n'est pas pris en charge."
    }

    # Récupérer le convertisseur
    $converter = $script:FormatConverters[$Format.ToLower()]

    # Vérifier que la fonction d'analyse est disponible
    if (-not $converter.AnalyzeFunction) {
        throw "Le format '$Format' ne prend pas en charge l'analyse."
    }

    try {
        # Analyser le fichier
        $result = & $converter.AnalyzeFunction $FilePath

        # Ajouter le contenu si demandé
        if ($IncludeContent) {
            $result | Add-Member -MemberType NoteProperty -Name "Content" -Value (Get-Content -Path $FilePath -Raw)
        }

        # Exporter le rapport si demandé
        if ($ExportReport) {
            if (-not $ReportPath) {
                $ReportPath = [System.IO.Path]::ChangeExtension($FilePath, "analysis.json")
            }

            $result | ConvertTo-Json -Depth 5 | Set-Content -Path $ReportPath -Encoding UTF8
            Write-Verbose "Rapport d'analyse exporté : $ReportPath"
        }

        return $result
    }
    catch {
        throw "Erreur lors de l'analyse du fichier '$FilePath' : $_"
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Register-FormatConverter, Get-RegisteredConverters, Get-FormatConverter, Convert-FileFormat, Get-FileFormatAnalysis
