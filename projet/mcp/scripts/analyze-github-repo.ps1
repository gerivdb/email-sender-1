#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse un dépôt GitHub avec MCP Git Ingest.
.DESCRIPTION
    Ce script permet d'analyser un dépôt GitHub avec MCP Git Ingest pour explorer
    sa structure et lire les fichiers importants.
.PARAMETER RepoUrl
    URL du dépôt GitHub à analyser.
.PARAMETER OutputDir
    Répertoire de sortie pour les résultats de l'analyse. Par défaut: output/repo-analysis.
.PARAMETER MaxFiles
    Nombre maximum de fichiers à analyser. Par défaut: 100.
.EXAMPLE
    .\analyze-github-repo.ps1 -RepoUrl "https://github.com/mem0ai/mem0"
    Analyse le dépôt mem0ai/mem0 avec les paramètres par défaut.
.EXAMPLE
    .\analyze-github-repo.ps1 -RepoUrl "https://github.com/mem0ai/mem0" -OutputDir "output/mem0-analysis" -MaxFiles 200
    Analyse le dépôt mem0ai/mem0 avec un répertoire de sortie personnalisé et un nombre maximum de fichiers de 200.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "output/repo-analysis",

    [Parameter(Mandatory = $false)]
    [int]$MaxFiles = 100
)

# Fonction pour écrire des logs
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

function Invoke-GitIngestCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Tool,

        [Parameter(Mandatory = $true)]
        [hashtable]$Params
    )

    try {
        # Convertir les paramètres en JSON
        $command = @{
            tool   = $Tool
            params = $Params
        } | ConvertTo-Json -Compress

        # Définir la variable d'environnement pour n8n
        $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

        # Créer un fichier temporaire pour la commande
        $tempFile = [System.IO.Path]::GetTempFileName()
        $command | Out-File -FilePath $tempFile -Encoding utf8

        # Exécuter la commande avec Python
        $result = Get-Content $tempFile -Raw | python -m mcp_git_ingest.main

        # Supprimer le fichier temporaire
        Remove-Item $tempFile -Force

        # Analyser la réponse JSON
        try {
            $response = $result | ConvertFrom-Json
            return $response
        } catch {
            Write-Log "Erreur lors de l'analyse de la réponse JSON: $_" -Level "ERROR"
            Write-Log "Réponse brute: $result" -Level "ERROR"
            return $null
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de la commande MCP Git Ingest: $_" -Level "ERROR"
        return $null
    }
}

try {
    # Vérifier si mcp-git-ingest est installé
    $mcpGitIngestInstalled = python -m pip list | Select-String -Pattern "mcp-git-ingest"

    if (-not $mcpGitIngestInstalled) {
        Write-Log "mcp-git-ingest n'est pas installé." -Level "ERROR"
        Write-Log "Veuillez exécuter setup-mcp-git-ingest.ps1 pour installer et configurer le serveur." -Level "INFO"
        exit 1
    }

    # Extraire le nom du dépôt à partir de l'URL
    $repoName = $RepoUrl.Split('/')[-1].Replace('.git', '')

    # Créer le répertoire de sortie
    $outputPath = Join-Path -Path (Get-Location) -ChildPath $OutputDir
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
        Write-Log "Répertoire de sortie créé: $outputPath" -Level "SUCCESS"
    }

    Write-Log "Analyse du dépôt $RepoUrl..." -Level "INFO"

    # Étape 1: Obtenir la structure du dépôt
    Write-Log "Étape 1: Récupération de la structure du dépôt..." -Level "INFO"
    $structureParams = @{
        repo_url = $RepoUrl
    }
    $structureResult = Invoke-GitIngestCommand -Tool "github_directory_structure" -Params $structureParams

    if ($structureResult) {
        # Sauvegarder la structure dans un fichier
        $structureResult | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputPath/structure.json" -Encoding utf8
        Write-Log "Structure du dépôt sauvegardée dans $outputPath/structure.json" -Level "SUCCESS"

        # Sauvegarder la structure en texte brut
        $structureResult.structure | Out-File -FilePath "$outputPath/structure.txt" -Encoding utf8
        Write-Log "Structure du dépôt (texte brut) sauvegardée dans $outputPath/structure.txt" -Level "SUCCESS"
    } else {
        Write-Log "Échec de la récupération de la structure du dépôt." -Level "ERROR"
    }

    # Étape 2: Déterminer les fichiers importants à lire
    Write-Log "Étape 2: Détermination des fichiers importants à lire..." -Level "INFO"

    # Liste des fichiers importants à lire
    $importantFiles = @(
        "README.md",
        "pyproject.toml",
        "setup.py",
        "LICENSE",
        "CONTRIBUTING.md"
    )

    # Ajouter des fichiers spécifiques en fonction du nom du dépôt
    if ($repoName -eq "mem0") {
        $importantFiles += @(
            "mem0/__init__.py",
            "mem0/main.py",
            "mem0/mcp/__init__.py",
            "mem0/mcp/server.py",
            "mem0/mcp/tools.py",
            "mem0/config.py",
            "docs/README.md"
        )
    }

    # Étape 3: Lire les fichiers importants
    Write-Log "Étape 3: Lecture des fichiers importants..." -Level "INFO"
    $filesParams = @{
        repo_url   = $RepoUrl
        file_paths = $importantFiles
    }
    $filesResult = Invoke-GitIngestCommand -Tool "github_read_important_files" -Params $filesParams

    if ($filesResult) {
        # Créer un répertoire pour les fichiers
        $filesDir = "$outputPath/files"
        if (-not (Test-Path $filesDir)) {
            New-Item -ItemType Directory -Path $filesDir -Force | Out-Null
            Write-Log "Répertoire pour les fichiers créé: $filesDir" -Level "SUCCESS"
        }

        # Sauvegarder le contenu des fichiers dans un fichier JSON
        $filesResult | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputPath/files_content.json" -Encoding utf8
        Write-Log "Contenu des fichiers sauvegardé dans $outputPath/files_content.json" -Level "SUCCESS"

        # Sauvegarder chaque fichier individuellement
        foreach ($file in $filesResult.files) {
            $safePath = $file.path.Replace("/", "_").Replace("\", "_")
            $file.content | Out-File -FilePath "$filesDir/$safePath" -Encoding utf8
            Write-Log "Fichier $($file.path) sauvegardé dans $filesDir/$safePath" -Level "SUCCESS"
        }
    } else {
        Write-Log "Échec de la récupération des fichiers importants." -Level "ERROR"
    }

    # Étape 4: Générer un rapport d'analyse
    Write-Log "Étape 4: Génération du rapport d'analyse..." -Level "INFO"

    $report = @"
# Analyse du dépôt $RepoUrl

## Structure du dépôt

```
$($structureResult.structure)
```

## Fichiers importants

"@

    if ($filesResult) {
        foreach ($file in $filesResult.files) {
            $content = $file.content
            if ($content.Length -gt 1000) {
                $content = $content.Substring(0, 1000) + "`n...[contenu tronqué]"
            }

            $report += @"

### $($file.path)

```
$content
```

"@
        }
    } else {
        $report += "`n*Erreur lors de la récupération des fichiers importants.*"
    }

    # Sauvegarder le rapport
    $report | Out-File -FilePath "$outputPath/report.md" -Encoding utf8
    Write-Log "Rapport d'analyse sauvegardé dans $outputPath/report.md" -Level "SUCCESS"

    # Ouvrir le rapport
    Invoke-Item "$outputPath/report.md"

    Write-Log "Analyse terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de l'analyse du dépôt: $_" -Level "ERROR"
    exit 1
}
