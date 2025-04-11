#Requires -Version 5.1
<#
.SYNOPSIS
    Module Format-Converters pour la détection et la conversion de formats de fichiers.

.DESCRIPTION
    Ce module fournit des fonctionnalités pour détecter automatiquement le format d'un fichier
    et convertir des fichiers entre différents formats. Il prend en charge la gestion des cas
    ambigus et offre une interface utilisateur pour la confirmation des formats détectés.

.NOTES
    Version: 2.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Définir le chemin du module
$script:ModuleRoot = $PSScriptRoot
$script:DetectorsPath = Join-Path -Path $script:ModuleRoot -ChildPath "Detectors"
$script:ConvertersPath = Join-Path -Path $script:ModuleRoot -ChildPath "Converters"
$script:IntegrationsPath = Join-Path -Path $script:ModuleRoot -ChildPath "Integrations"
$script:UtilsPath = Join-Path -Path $script:ModuleRoot -ChildPath "Utils"

# Importer les fonctions utilitaires
Get-ChildItem -Path $script:UtilsPath -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# Importer les détecteurs de format
Get-ChildItem -Path $script:DetectorsPath -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# Importer les convertisseurs de format
Get-ChildItem -Path $script:ConvertersPath -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# Importer les intégrations
Get-ChildItem -Path $script:IntegrationsPath -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# Initialiser le registre des convertisseurs
$script:ConverterRegistry = @{}

# Fonction pour enregistrer un convertisseur
function Register-FormatConverter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Format,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ConverterInfo
    )
    
    $script:ConverterRegistry[$Format] = $ConverterInfo
}

# Fonction pour obtenir tous les convertisseurs enregistrés
function Get-RegisteredConverters {
    [CmdletBinding()]
    param()
    
    return $script:ConverterRegistry
}

# Fonction pour détecter le format d'un fichier
function Detect-FileFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoResolve,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails,
        
        [Parameter(Mandatory = $false)]
        [switch]$RememberChoices
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }
    
    # Appeler la fonction de détection améliorée
    $detectionResult = Detect-FileFormatWithConfirmation -FilePath $FilePath -AutoResolve:$AutoResolve -ShowDetails:$ShowDetails -RememberChoices:$RememberChoices
    
    return $detectionResult
}

# Fonction pour convertir un fichier d'un format à un autre
function Convert-FileFormat {
    [CmdletBinding()]
    param (
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
    
    # Vérifier si le fichier de sortie existe déjà
    if ((Test-Path -Path $OutputPath) -and -not $Force) {
        throw "Le fichier de sortie '$OutputPath' existe déjà. Utilisez -Force pour écraser."
    }
    
    # Détecter automatiquement le format d'entrée si nécessaire
    if (-not $InputFormat -or $AutoDetect) {
        $detectionResult = Detect-FileFormat -FilePath $InputPath -AutoResolve
        $InputFormat = $detectionResult.DetectedFormat
        
        Write-Verbose "Format détecté : $InputFormat (Score de confiance : $($detectionResult.ConfidenceScore)%)"
    }
    
    # Vérifier si les convertisseurs nécessaires sont disponibles
    if (-not $script:ConverterRegistry.ContainsKey($InputFormat.ToLower())) {
        throw "Aucun convertisseur n'est disponible pour le format d'entrée '$InputFormat'."
    }
    
    if (-not $script:ConverterRegistry.ContainsKey($OutputFormat.ToLower())) {
        throw "Aucun convertisseur n'est disponible pour le format de sortie '$OutputFormat'."
    }
    
    $inputConverter = $script:ConverterRegistry[$InputFormat.ToLower()]
    $outputConverter = $script:ConverterRegistry[$OutputFormat.ToLower()]
    
    # Vérifier si la conversion directe est possible
    $canConvertDirectly = $false
    
    if ($inputConverter.ConvertToFunction -and $inputConverter.ConvertToFunction.ContainsKey($OutputFormat.ToLower())) {
        $canConvertDirectly = $true
    }
    
    # Effectuer la conversion
    try {
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Lecture du fichier d'entrée..." -PercentComplete 0
        }
        
        # Lire le fichier d'entrée
        $inputContent = & $inputConverter.ImportFunction -FilePath $InputPath
        
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Conversion du contenu..." -PercentComplete 33
        }
        
        # Convertir le contenu
        $outputContent = $null
        
        if ($canConvertDirectly) {
            # Conversion directe
            $convertFunction = $inputConverter.ConvertToFunction[$OutputFormat.ToLower()]
            $outputContent = & $convertFunction -Content $inputContent
        }
        else {
            # Conversion via format intermédiaire
            throw "La conversion directe de '$InputFormat' vers '$OutputFormat' n'est pas prise en charge."
        }
        
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Écriture du fichier de sortie..." -PercentComplete 66
        }
        
        # Écrire le fichier de sortie
        & $outputConverter.ExportFunction -Data $outputContent -FilePath $OutputPath
        
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Terminé" -PercentComplete 100 -Completed
        }
        
        return [PSCustomObject]@{
            InputPath = $InputPath
            OutputPath = $OutputPath
            InputFormat = $InputFormat
            OutputFormat = $OutputFormat
            Success = $true
            Message = "Conversion réussie."
        }
    }
    catch {
        if ($ShowProgress) {
            Write-Progress -Activity "Conversion de fichier" -Status "Erreur" -PercentComplete 100 -Completed
        }
        
        return [PSCustomObject]@{
            InputPath = $InputPath
            OutputPath = $OutputPath
            InputFormat = $InputFormat
            OutputFormat = $OutputFormat
            Success = $false
            Message = "Erreur lors de la conversion : $_"
        }
    }
}

# Fonction pour analyser un fichier
function Analyze-FileFormat {
    [CmdletBinding()]
    param (
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
    
    # Détecter automatiquement le format si nécessaire
    if (-not $Format -or $AutoDetect) {
        $detectionResult = Detect-FileFormat -FilePath $FilePath -AutoResolve
        $Format = $detectionResult.DetectedFormat
        
        Write-Verbose "Format détecté : $Format (Score de confiance : $($detectionResult.ConfidenceScore)%)"
    }
    
    # Vérifier si le convertisseur est disponible
    if (-not $script:ConverterRegistry.ContainsKey($Format.ToLower())) {
        throw "Aucun convertisseur n'est disponible pour le format '$Format'."
    }
    
    $converter = $script:ConverterRegistry[$Format.ToLower()]
    
    # Vérifier si une fonction d'analyse est disponible
    if (-not $converter.AnalyzeFunction) {
        throw "Aucune fonction d'analyse n'est disponible pour le format '$Format'."
    }
    
    # Analyser le fichier
    $analysisResult = & $converter.AnalyzeFunction -FilePath $FilePath
    
    # Ajouter le contenu du fichier si demandé
    if ($IncludeContent) {
        $fileContent = Get-Content -Path $FilePath -Raw
        $analysisResult | Add-Member -MemberType NoteProperty -Name "Content" -Value $fileContent
    }
    
    # Exporter le rapport si demandé
    if ($ExportReport) {
        if (-not $ReportPath) {
            $ReportPath = [System.IO.Path]::ChangeExtension($FilePath, "report.json")
        }
        
        $analysisResult | ConvertTo-Json -Depth 10 | Set-Content -Path $ReportPath -Encoding UTF8
    }
    
    return $analysisResult
}

# Exporter les fonctions publiques
Export-ModuleMember -Function @(
    'Register-FormatConverter',
    'Get-RegisteredConverters',
    'Detect-FileFormat',
    'Convert-FileFormat',
    'Analyze-FileFormat'
)
