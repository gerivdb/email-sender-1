﻿# Ensure-CompleteVectorization.ps1
# Script pour assurer une vectorisation complète des tâches de roadmap dans Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapDir = "projet\roadmaps\plans\consolidated",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter(Mandatory = $false)]
    [string]$ModelEndpoint = "https://api.openrouter.ai/api/v1/embeddings",

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY,

    [Parameter(Mandatory = $false)]
    [string]$ModelName = "qwen/qwen2-7b",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDiagnostic,

    [Parameter(Mandatory = $false)]
    [switch]$SkipVerification,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$diagnosticPath = Join-Path -Path $scriptPath -ChildPath "Diagnostic-RoadmapVectorization.ps1"
$fixPath = Join-Path -Path $scriptPath -ChildPath "Fix-RoadmapVectorization.ps1"
$verifyPath = Join-Path -Path $scriptPath -ChildPath "Verify-RoadmapVectorization.ps1"

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction principale
function Start-CompleteVectorization {
    [CmdletBinding()]
    param()

    # Vérifier l'existence des scripts
    if (-not (Test-Path -Path $diagnosticPath)) {
        Write-Log "Le script de diagnostic est introuvable: $diagnosticPath" -Level Error
        return $false
    }

    if (-not (Test-Path -Path $fixPath)) {
        Write-Log "Le script de correction est introuvable: $fixPath" -Level Error
        return $false
    }

    if (-not (Test-Path -Path $verifyPath)) {
        Write-Log "Le script de vérification est introuvable: $verifyPath" -Level Error
        return $false
    }

    # Étape 1: Diagnostic
    if (-not $SkipDiagnostic) {
        Write-Log "Étape 1: Diagnostic de la vectorisation..." -Level Info

        $diagnosticParams = @(
            "-RoadmapDir", $RoadmapDir,
            "-QdrantUrl", $QdrantUrl,
            "-CollectionName", $CollectionName
        )

        if ($CreateCollection) {
            $diagnosticParams += "-CreateCollection"
        }

        if ($Verbose) {
            $diagnosticParams += "-Verbose"
        }

        & $diagnosticPath @diagnosticParams

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Le diagnostic a échoué avec le code de sortie $LASTEXITCODE" -Level Warning
        }
    }

    # Étape 2: Correction
    Write-Log "Étape 2: Correction de la vectorisation..." -Level Info

    $fixParams = @(
        "-RoadmapDir", $RoadmapDir,
        "-QdrantUrl", $QdrantUrl,
        "-CollectionName", $CollectionName,
        "-ModelEndpoint", $ModelEndpoint,
        "-ModelName", $ModelName
    )

    if ($ApiKey) {
        $fixParams += "-ApiKey", $ApiKey
    }

    if ($Force) {
        $fixParams += "-Force"
    }

    if ($Verbose) {
        $fixParams += "-Verbose"
    }

    & $fixPath @fixParams

    if ($LASTEXITCODE -ne 0) {
        Write-Log "La correction a échoué avec le code de sortie $LASTEXITCODE" -Level Error
        return $false
    }

    # Étape 3: Vérification
    if (-not $SkipVerification) {
        Write-Log "Étape 3: Vérification de la vectorisation..." -Level Info

        $verifyParams = @(
            "-RoadmapDir", $RoadmapDir,
            "-QdrantUrl", $QdrantUrl,
            "-CollectionName", $CollectionName,
            "-GenerateReport"
        )

        if ($Verbose) {
            $verifyParams += "-Verbose"
        }

        & $verifyPath @verifyParams

        if ($LASTEXITCODE -ne 0) {
            Write-Log "La vérification a échoué avec le code de sortie $LASTEXITCODE" -Level Warning
            Write-Log "Certaines tâches pourraient ne pas être correctement vectorisées." -Level Warning
            return $false
        }

        Write-Log "Vectorisation complète vérifiée avec succès." -Level Success
    }

    return $true
}

# Exécuter la vectorisation complète
$result = Start-CompleteVectorization
exit [int](!$result)
