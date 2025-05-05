<#
.SYNOPSIS
    RÃ©organise les fichiers dans le dossier development/docs.

.DESCRIPTION
    Ce script dÃ©place les fichiers du dossier development/docs vers des sous-dossiers thÃ©matiques.

.EXAMPLE
    .\reorganize-docs.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Reorganize-Docs {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "RÃ©organisation des fichiers dans le dossier development/docs..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        $docsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\docs"
        
        # VÃ©rifier que le dossier existe
        if (-not (Test-Path $docsRoot)) {
            Write-Error "Le dossier development\docs n'existe pas : $docsRoot"
            return $false
        }
        
        # DÃ©finir les mappages de fichiers vers les sous-dossiers
        $fileMappings = @{
            "algorithms" = @(
                "AlgorithmesDetectionCycles.md",
                "ComparaisonAlgorithmesCycles.md",
                "CycleDetector.md",
                "DecisionAlgorithmeCycles.md",
                "GraphDataStructure.md"
            )
            "api" = @(
                "CycleDetectorAPI.md",
                "DependencyCycleAPI.md",
                "DependencyCycleResolver_API.md",
                "InputSegmenter.md"
            )
            "security" = @(
                "EncryptionUtils.md",
                "FileSecurityUtils.md"
            )
            "performance" = @(
                "CacheManager.md",
                "InputSegmentation.md",
                "OPTIMIZATIONS.md",
                "ParallelProcessing.md"
            )
            "structure" = @(
                "CHANGELOG.md",
                "CSV_YAML_Support.md",
                "ErrorHandlingStrategy.md",
                "ImplementationsReference.md",
                "RepoStructureStandard.md",
                "ScriptInventorySystem.md"
            )
            "mcp" = @(
                "MCPClientAPI.md",
                "MCPManager.md",
                "MCPPowerShellServer.md"
            )
        }
    }
    
    process {
        try {
            # DÃ©placer les fichiers vers les sous-dossiers
            foreach ($folder in $fileMappings.Keys) {
                $destFolder = Join-Path -Path $docsRoot -ChildPath $folder
                
                # VÃ©rifier que le dossier de destination existe
                if (-not (Test-Path $destFolder)) {
                    if ($PSCmdlet.ShouldProcess($destFolder, "CrÃ©er le dossier")) {
                        New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                        Write-Host "  Dossier crÃ©Ã© : $destFolder" -ForegroundColor Yellow
                    }
                }
                
                # DÃ©placer les fichiers
                foreach ($file in $fileMappings[$folder]) {
                    $sourcePath = Join-Path -Path $docsRoot -ChildPath $file
                    $destPath = Join-Path -Path $destFolder -ChildPath $file
                    
                    if (Test-Path $sourcePath) {
                        if ($PSCmdlet.ShouldProcess("$sourcePath -> $destPath", "DÃ©placer le fichier")) {
                            Move-Item -Path $sourcePath -Destination $destPath -Force
                            Write-Host "  Fichier dÃ©placÃ© : $sourcePath -> $destPath" -ForegroundColor Green
                        }
                    }
                    else {
                        Write-Host "  Fichier non trouvÃ© : $sourcePath" -ForegroundColor Yellow
                    }
                }
            }
            
            # Mettre Ã  jour le fichier index.md
            $indexPath = Join-Path -Path $docsRoot -ChildPath "index.md"
            $indexContent = @"
# Documentation Technique

Cette section contient la documentation technique du projet.

## Algorithmes

- [AlgorithmesDetectionCycles](algorithms/AlgorithmesDetectionCycles.md) - Algorithmes de dÃ©tection de cycles
- [ComparaisonAlgorithmesCycles](algorithms/ComparaisonAlgorithmesCycles.md) - Comparaison des algorithmes de dÃ©tection de cycles
- [CycleDetector](algorithms/CycleDetector.md) - DÃ©tecteur de cycles
- [DecisionAlgorithmeCycles](algorithms/DecisionAlgorithmeCycles.md) - DÃ©cision sur les algorithmes de cycles
- [GraphDataStructure](algorithms/GraphDataStructure.md) - Structure de donnÃ©es de graphe

## API

- [CycleDetectorAPI](api/CycleDetectorAPI.md) - API du dÃ©tecteur de cycles
- [DependencyCycleAPI](api/DependencyCycleAPI.md) - API de cycle de dÃ©pendance
- [DependencyCycleResolver_API](api/DependencyCycleResolver_API.md) - API de rÃ©solution de cycle de dÃ©pendance
- [InputSegmenter](api/InputSegmenter.md) - Segmenteur d'entrÃ©e

## SÃ©curitÃ©

- [EncryptionUtils](security/EncryptionUtils.md) - Utilitaires de chiffrement
- [FileSecurityUtils](security/FileSecurityUtils.md) - Utilitaires de sÃ©curitÃ© de fichiers

## Performance

- [CacheManager](performance/CacheManager.md) - Gestionnaire de cache
- [InputSegmentation](performance/InputSegmentation.md) - Segmentation d'entrÃ©e
- [OPTIMIZATIONS](performance/OPTIMIZATIONS.md) - Optimisations
- [ParallelProcessing](performance/ParallelProcessing.md) - Traitement parallÃ¨le

## Structure

- [CHANGELOG](structure/CHANGELOG.md) - Journal des modifications
- [CSV_YAML_Support](structure/CSV_YAML_Support.md) - Support CSV et YAML
- [ErrorHandlingStrategy](structure/ErrorHandlingStrategy.md) - StratÃ©gie de gestion des erreurs
- [ImplementationsReference](structure/ImplementationsReference.md) - RÃ©fÃ©rence des implÃ©mentations
- [RepoStructureStandard](structure/RepoStructureStandard.md) - Standard de structure du dÃ©pÃ´t
- [ScriptInventorySystem](structure/ScriptInventorySystem.md) - SystÃ¨me d'inventaire de scripts

## MCP

- [MCPClientAPI](mcp/MCPClientAPI.md) - API client MCP
- [MCPManager](mcp/MCPManager.md) - Gestionnaire MCP
- [MCPPowerShellServer](mcp/MCPPowerShellServer.md) - Serveur PowerShell MCP

## Augment

- [Augment](augment/index.md) - Documentation liÃ©e Ã  Augment
"@
            
            if ($PSCmdlet.ShouldProcess($indexPath, "Mettre Ã  jour le fichier index.md")) {
                Set-Content -Path $indexPath -Value $indexContent -Force
                Write-Host "  Fichier index.md mis Ã  jour : $indexPath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la rÃ©organisation des fichiers : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nRÃ©organisation des fichiers terminÃ©e !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Reorganize-Docs
