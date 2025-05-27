# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\roadmap\parser\modes\dev-r\dev-r-mode.ps1
# Forcer l'encodage UTF-8 pour éviter les problèmes d'accents
Set-StrictMode -Version Latest
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

<#
.SYNOPSIS
    Script pour le mode DEV-R qui permet d'implémenter les tâches définies dans une roadmap.

.DESCRIPTION
    Ce script implémente le mode DEV-R (Roadmap Delivery) qui permet d'implémenter les tâches définies dans une roadmap de manière séquentielle et méthodique.
    
.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Définition de la fonction principale
function Invoke-DevRMode {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory=$false)]
        [string]$TaskIdentifier = "",
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = (Get-Location).Path,
        
        [Parameter(Mandatory=$false)]
        [string]$ConfigFile = "",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
        [string]$LogLevel = "INFO",
        
        [Parameter(Mandatory=$false)]
        [string]$ProjectPath = (Join-Path $PSScriptRoot "../../development"),
        
        [Parameter(Mandatory=$false)]
        [string]$TestsPath = (Join-Path $PSScriptRoot "../../tests"),
        
        [Parameter(Mandatory=$false)]
        [bool]$AutoCommit = $false,
        
        [Parameter(Mandatory=$false)]
        [bool]$UpdateRoadmap = $true,
        
        [Parameter(Mandatory=$false)]
        [bool]$GenerateTests = $true,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    # Obtenir le chemin du fichier de plan de développement
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    $planFile = Join-Path $projectRoot "projet\roadmaps\plans\consolidated\plan-dev-v34-rag-go.md"

    if (-not (Test-Path -Path $planFile -PathType Leaf)) {
        # Plan par défaut non trouvé, chercher dans le répertoire du projet
        $mdFiles = Get-ChildItem -Path $projectRoot -Filter "*plan-dev*.md" -Recurse |
            Where-Object { $_.Name -like "*rag-go.md" }
        
        if ($mdFiles.Count -gt 0) {
            $planFile = ($mdFiles | Sort-Object LastWriteTime -Descending)[0].FullName
        } else {
            throw "Impossible de trouver le fichier de plan de développement RAG Go"
        }
    }

    $FilePath = $planFile
    Write-Host "`nUtilisation du fichier de plan : $FilePath"
    Write-Host "Identifiant de tâche : $(if($TaskIdentifier){"$TaskIdentifier"}else{"Toutes les tâches"})"
    Write-Host "Répertoire de sortie : $OutputPath"
    Write-Host "Niveau de journalisation : $LogLevel"
    Write-Host "Répertoire du projet : $ProjectPath"
    Write-Host "Répertoire des tests : $TestsPath"

    # Vérifier l'existence de la tâche si un ID est fourni
    if ($TaskIdentifier) {
        $taskDescription = "Traiter la tâche $TaskIdentifier du plan de développement"
        if ($PSCmdlet.ShouldProcess($FilePath, $taskDescription)) {
            $content = Get-Content -Path $FilePath -Raw 
            if ($content -match $TaskIdentifier) {
                Write-Host "Tâche trouvée dans le plan de développement"
                # TODO: Implémenter la logique de traitement de la tâche
            } else {
                throw "La tâche $TaskIdentifier n'a pas été trouvée dans le plan de développement"
            }
        }
    } else {
        $allTasksDescription = "Traiter toutes les tâches du plan de développement"
        if ($PSCmdlet.ShouldProcess($FilePath, $allTasksDescription)) {
            Write-Host "`nTraitement de toutes les tâches du plan..."
            # TODO: Implémenter la logique pour toutes les tâches
        }
    }
}

# Appeler la fonction avec les paramètres passés au script
$params = @{}
$PSBoundParameters.GetEnumerator() | ForEach-Object { $params[$_.Key] = $_.Value }
Invoke-DevRMode @params
