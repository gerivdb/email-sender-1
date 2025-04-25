#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'aide pour le traitement parallÃ¨le des fichiers.
.DESCRIPTION
    Ce module fournit des fonctions pour traiter des fichiers en parallÃ¨le
    afin d'amÃ©liorer les performances des opÃ©rations intensives.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Fonction pour traiter des fichiers en parallÃ¨le
function Invoke-ParallelFileProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 5,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # VÃ©rifier si PowerShell 7+ est disponible pour utiliser ForEach-Object -Parallel
    $isPwsh7 = $PSVersionTable.PSVersion.Major -ge 7

    if ($isPwsh7) {
        Write-Verbose "Utilisation de ForEach-Object -Parallel (PowerShell 7+)"

        # CrÃ©er un tableau pour stocker les rÃ©sultats
        $results = @()

        # Traiter les fichiers en parallÃ¨le
        $results = $FilePaths | ForEach-Object -Parallel {
            $filePath = $_
            $scriptBlock = $using:ScriptBlock
            $params = $using:Parameters

            # CrÃ©er une copie locale des paramÃ¨tres et ajouter le chemin du fichier
            $localParams = $params.Clone()
            $localParams["FilePath"] = $filePath

            # ExÃ©cuter le script block avec les paramÃ¨tres
            & $scriptBlock @localParams
        } -ThrottleLimit $ThrottleLimit

        return $results
    } else {
        Write-Verbose "Utilisation de RunspacePool (PowerShell 5.1)"

        # CrÃ©er un pool de runspaces
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
        $runspacePool.Open()

        # CrÃ©er un tableau pour stocker les runspaces et les rÃ©sultats
        $runspaces = @()
        $results = @()

        # PrÃ©parer les runspaces pour chaque fichier
        foreach ($filePath in $FilePaths) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter le script block Ã  exÃ©cuter
            [void]$powershell.AddScript({
                    param($filePath, $scriptBlock, $parameters)

                    # CrÃ©er une copie locale des paramÃ¨tres et ajouter le chemin du fichier
                    $localParams = $parameters.Clone()
                    $localParams["FilePath"] = $filePath

                    # ExÃ©cuter le script block avec les paramÃ¨tres
                    & $scriptBlock @localParams
                })

            # Ajouter les paramÃ¨tres
            [void]$powershell.AddParameter("filePath", $filePath)
            [void]$powershell.AddParameter("scriptBlock", $ScriptBlock)
            [void]$powershell.AddParameter("parameters", $Parameters)

            # DÃ©marrer l'exÃ©cution asynchrone
            $handle = $powershell.BeginInvoke()

            # Stocker les informations sur le runspace
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                FilePath   = $filePath
            }
        }

        # Attendre que tous les runspaces soient terminÃ©s et collecter les rÃ©sultats
        foreach ($runspace in $runspaces) {
            $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
            $results += $result

            # Nettoyer le runspace
            $runspace.PowerShell.Dispose()
        }

        # Fermer et nettoyer le pool de runspaces
        $runspacePool.Close()
        $runspacePool.Dispose()

        return $results
    }
}

# Fonction pour convertir des fichiers en parallÃ¨le
function Convert-FilesInParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$InputFiles,

        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$InputFormat = "AUTO",

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [bool]$FlattenNestedObjects = $true,

        [Parameter(Mandatory = $false)]
        [string]$NestedSeparator = ".",

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 5
    )

    # VÃ©rifier que le module UnifiedSegmenter est disponible
    $scriptPath = $MyInvocation.MyCommand.Path
    $moduleRoot = Split-Path -Parent $scriptPath
    $unifiedSegmenterPath = Join-Path -Path $moduleRoot -ChildPath "UnifiedSegmenter.ps1"

    if (-not (Test-Path -Path $unifiedSegmenterPath)) {
        Write-Error "Le module UnifiedSegmenter.ps1 n'est pas disponible."
        return $null
    }

    # Importer le module UnifiedSegmenter
    . $unifiedSegmenterPath

    # Initialiser le segmenteur unifiÃ©
    $initResult = Initialize-UnifiedSegmenter
    if (-not $initResult) {
        Write-Error "Erreur lors de l'initialisation du segmenteur unifiÃ©."
        return $null
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    # DÃ©finir le script block pour la conversion
    $convertScriptBlock = {
        param (
            [string]$FilePath,
            [string]$OutputDir,
            [string]$InputFormat,
            [string]$OutputFormat,
            [bool]$FlattenNestedObjects,
            [string]$NestedSeparator
        )

        # Obtenir le nom du fichier de sortie
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $outputExtension = switch ($OutputFormat) {
            "JSON" { ".json" }
            "XML" { ".xml" }
            "TEXT" { ".txt" }
            "CSV" { ".csv" }
            "YAML" { ".yaml" }
            default { ".txt" }
        }
        $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName$outputExtension"

        # DÃ©tecter le format d'entrÃ©e si nÃ©cessaire
        if ($InputFormat -eq "AUTO") {
            $detectedFormat = Get-FileFormat -FilePath $FilePath
            $InputFormat = $detectedFormat
        }

        # Convertir le fichier
        $result = Convert-FileFormat -InputFile $FilePath -OutputFile $outputPath -InputFormat $InputFormat -OutputFormat $OutputFormat -FlattenNestedObjects $FlattenNestedObjects -NestedSeparator $NestedSeparator

        # Retourner le rÃ©sultat
        return [PSCustomObject]@{
            InputFile    = $FilePath
            OutputFile   = $outputPath
            Success      = $result
            InputFormat  = $InputFormat
            OutputFormat = $OutputFormat
        }
    }

    # PrÃ©parer les paramÃ¨tres pour le traitement parallÃ¨le
    $parameters = @{
        OutputDir            = $OutputDir
        InputFormat          = $InputFormat
        OutputFormat         = $OutputFormat
        FlattenNestedObjects = $FlattenNestedObjects
        NestedSeparator      = $NestedSeparator
    }

    # Traiter les fichiers en parallÃ¨le
    $results = Invoke-ParallelFileProcessing -FilePaths $InputFiles -ScriptBlock $convertScriptBlock -ThrottleLimit $ThrottleLimit -Parameters $parameters

    return $results
}

# Fonction pour analyser des fichiers en parallÃ¨le
function Get-FileAnalysisInParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 5
    )

    # VÃ©rifier que le module UnifiedSegmenter est disponible
    $scriptPath = $MyInvocation.MyCommand.Path
    $moduleRoot = Split-Path -Parent $scriptPath
    $unifiedSegmenterPath = Join-Path -Path $moduleRoot -ChildPath "UnifiedSegmenter.ps1"

    if (-not (Test-Path -Path $unifiedSegmenterPath)) {
        Write-Error "Le module UnifiedSegmenter.ps1 n'est pas disponible."
        return $null
    }

    # Importer le module UnifiedSegmenter
    . $unifiedSegmenterPath

    # Initialiser le segmenteur unifiÃ©
    $initResult = Initialize-UnifiedSegmenter
    if (-not $initResult) {
        Write-Error "Erreur lors de l'initialisation du segmenteur unifiÃ©."
        return $null
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    # DÃ©finir le script block pour l'analyse
    $analyzeScriptBlock = {
        param (
            [string]$FilePath,
            [string]$OutputDir,
            [string]$Format
        )

        # Obtenir le nom du fichier de sortie
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-analysis.json"

        # DÃ©tecter le format si nÃ©cessaire
        if ($Format -eq "AUTO") {
            $detectedFormat = Get-FileFormat -FilePath $FilePath
            $Format = $detectedFormat
        }

        # Analyser le fichier
        $result = Get-FileAnalysis -FilePath $FilePath -Format $Format -OutputFile $outputPath

        # Retourner le rÃ©sultat
        return [PSCustomObject]@{
            InputFile  = $FilePath
            OutputFile = $outputPath
            Format     = $Format
            Success    = ($null -ne $result)
        }
    }

    # PrÃ©parer les paramÃ¨tres pour le traitement parallÃ¨le
    $parameters = @{
        OutputDir = $OutputDir
        Format    = $Format
    }

    # Traiter les fichiers en parallÃ¨le
    $results = Invoke-ParallelFileProcessing -FilePaths $FilePaths -ScriptBlock $analyzeScriptBlock -ThrottleLimit $ThrottleLimit -Parameters $parameters

    return $results
}

# Exporter les fonctions
# Export-ModuleMember est commentÃ© pour permettre le chargement direct du script

