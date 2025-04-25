#Requires -Version 5.1
<#
.SYNOPSIS
    Intègre les résultats d'analyse de code avec des outils tiers (SonarQube, GitHub, AzureDevOps).
.PARAMETER Path
    Chemin du fichier JSON contenant les résultats d'analyse.
.PARAMETER Tool
    Outil tiers avec lequel intégrer les résultats (SonarQube, GitHub, AzureDevOps).
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats convertis.
.PARAMETER ApiKey, ApiUrl, ProjectKey
    Paramètres d'API pour l'outil tiers (si nécessaire).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][ValidateSet("SonarQube", "GitHub", "AzureDevOps")][string]$Tool,
    [Parameter(Mandatory = $false)][string]$OutputPath,
    [Parameter(Mandatory = $false)][string]$ApiKey,
    [Parameter(Mandatory = $false)][string]$ApiUrl,
    [Parameter(Mandatory = $false)][string]$ProjectKey
)

# Vérifications et initialisation
if (-not (Test-Path -Path $Path -PathType Leaf)) { throw "Le fichier '$Path' n'existe pas." }
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $outputDirectory = Split-Path -Path $Path -Parent
    $OutputPath = Join-Path -Path $outputDirectory -ChildPath "$baseName-$Tool-$timestamp.json"
}

# Lire les résultats d'analyse
try { $results = Get-Content -Path $Path -Raw | ConvertFrom-Json }
catch { throw "Erreur lors de la lecture du fichier '$Path': $_" }

# Convertir vers le format SonarQube
function ConvertTo-SonarQubeFormat($Results, $ProjectKey) {
    $issues = foreach ($result in $Results) {
        $severity = switch ($result.Severity) {
            "Error" { "CRITICAL" }
            "Warning" { "MAJOR" }
            "Information" { "MINOR" }
            default { "INFO" }
        }
        $type = if ($result.Category -in @("Security")) { "VULNERABILITY" } else { "CODE_SMELL" }
        @{
            engineId        = $result.ToolName
            ruleId          = $result.RuleId
            severity        = $severity
            type            = $type
            primaryLocation = @{
                message   = $result.Message
                filePath  = $result.FilePath
                textRange = @{
                    startLine = $result.Line; endLine = $result.Line
                    startColumn = $result.Column; endColumn = $result.Column + 1
                }
            }
        }
    }
    return @{ issues = $issues }
}

# Convertir vers le format GitHub
function ConvertTo-GitHubFormat($Results) {
    $annotations = foreach ($result in $Results) {
        $level = switch ($result.Severity) {
            "Error" { "error" }
            "Warning" { "warning" }
            default { "notice" }
        }
        @{
            path = $result.FilePath
            start_line = $result.Line; end_line = $result.Line
            start_column = $result.Column; end_column = $result.Column + 1
            annotation_level = $level
            message = $result.Message
            title = "$($result.ToolName): $($result.RuleId)"
        }
    }
    return @{ annotations = $annotations }
}

# Convertir vers le format Azure DevOps
function ConvertTo-AzureDevOpsFormat($Results) {
    $issues = foreach ($result in $Results) {
        $severity = switch ($result.Severity) {
            "Error" { 1 }
            "Warning" { 2 }
            default { 3 }
        }
        @{
            type        = "issue"
            check_name  = $result.RuleId
            description = $result.Message
            categories  = @($result.Category)
            location    = @{
                path      = $result.FilePath
                positions = @{
                    begin = @{ line = $result.Line; column = $result.Column }
                    end   = @{ line = $result.Line; column = $result.Column + 1 }
                }
            }
            severity    = $severity
            engine_name = $result.ToolName
        }
    }
    return @{ version = "2.0"; tool_name = "CodeAnalysis"; tool_version = "1.0"; issues = $issues }
}

# Convertir les résultats vers le format approprié
try {
    $convertedResults = switch ($Tool) {
        "SonarQube" {
            if (-not $ProjectKey) { throw "Le paramètre ProjectKey est requis pour SonarQube." }
            ConvertTo-SonarQubeFormat -Results $results -ProjectKey $ProjectKey
        }
        "GitHub" { ConvertTo-GitHubFormat -Results $results }
        "AzureDevOps" { ConvertTo-AzureDevOpsFormat -Results $results }
    }

    # Enregistrer les résultats convertis
    $convertedResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
    Write-Host "Résultats convertis enregistrés dans '$OutputPath'." -ForegroundColor Green

    # Envoyer les résultats à l'outil tiers si nécessaire
    if ($Tool -eq "SonarQube" -and $ApiKey -and $ApiUrl) {
        $headers = @{ "Content-Type" = "application/json"; "Authorization" = "Bearer $ApiKey" }
        $body = $convertedResults | ConvertTo-Json -Depth 10 -Compress
        try {
            Invoke-RestMethod -Uri "$ApiUrl/api/issues/bulk_create" -Method Post -Headers $headers -Body $body
            Write-Host "Résultats envoyés à SonarQube avec succès." -ForegroundColor Green
        } catch { Write-Error "Erreur lors de l'envoi des résultats à SonarQube: $_" }
    }
} catch { Write-Error "Erreur lors de la conversion des résultats: $_" }
