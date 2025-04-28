<#
.SYNOPSIS
    Réorganise les fichiers dans le dossier development/docs.

.DESCRIPTION
    Ce script déplace les fichiers du dossier development/docs vers des sous-dossiers thématiques.

.EXAMPLE
    .\reorganize-docs.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Reorganize-Docs {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Réorganisation des fichiers dans le dossier development/docs..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        $docsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\docs"
        
        # Vérifier que le dossier existe
        if (-not (Test-Path $docsRoot)) {
            Write-Error "Le dossier development\docs n'existe pas : $docsRoot"
            return $false
        }
        
        # Définir les mappages de fichiers vers les sous-dossiers
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
            # Déplacer les fichiers vers les sous-dossiers
            foreach ($folder in $fileMappings.Keys) {
                $destFolder = Join-Path -Path $docsRoot -ChildPath $folder
                
                # Vérifier que le dossier de destination existe
                if (-not (Test-Path $destFolder)) {
                    if ($PSCmdlet.ShouldProcess($destFolder, "Créer le dossier")) {
                        New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                        Write-Host "  Dossier créé : $destFolder" -ForegroundColor Yellow
                    }
                }
                
                # Déplacer les fichiers
                foreach ($file in $fileMappings[$folder]) {
                    $sourcePath = Join-Path -Path $docsRoot -ChildPath $file
                    $destPath = Join-Path -Path $destFolder -ChildPath $file
                    
                    if (Test-Path $sourcePath) {
                        if ($PSCmdlet.ShouldProcess("$sourcePath -> $destPath", "Déplacer le fichier")) {
                            Move-Item -Path $sourcePath -Destination $destPath -Force
                            Write-Host "  Fichier déplacé : $sourcePath -> $destPath" -ForegroundColor Green
                        }
                    }
                    else {
                        Write-Host "  Fichier non trouvé : $sourcePath" -ForegroundColor Yellow
                    }
                }
            }
            
            # Mettre à jour le fichier index.md
            $indexPath = Join-Path -Path $docsRoot -ChildPath "index.md"
            $indexContent = @"
# Documentation Technique

Cette section contient la documentation technique du projet.

## Algorithmes

- [AlgorithmesDetectionCycles](algorithms/AlgorithmesDetectionCycles.md) - Algorithmes de détection de cycles
- [ComparaisonAlgorithmesCycles](algorithms/ComparaisonAlgorithmesCycles.md) - Comparaison des algorithmes de détection de cycles
- [CycleDetector](algorithms/CycleDetector.md) - Détecteur de cycles
- [DecisionAlgorithmeCycles](algorithms/DecisionAlgorithmeCycles.md) - Décision sur les algorithmes de cycles
- [GraphDataStructure](algorithms/GraphDataStructure.md) - Structure de données de graphe

## API

- [CycleDetectorAPI](api/CycleDetectorAPI.md) - API du détecteur de cycles
- [DependencyCycleAPI](api/DependencyCycleAPI.md) - API de cycle de dépendance
- [DependencyCycleResolver_API](api/DependencyCycleResolver_API.md) - API de résolution de cycle de dépendance
- [InputSegmenter](api/InputSegmenter.md) - Segmenteur d'entrée

## Sécurité

- [EncryptionUtils](security/EncryptionUtils.md) - Utilitaires de chiffrement
- [FileSecurityUtils](security/FileSecurityUtils.md) - Utilitaires de sécurité de fichiers

## Performance

- [CacheManager](performance/CacheManager.md) - Gestionnaire de cache
- [InputSegmentation](performance/InputSegmentation.md) - Segmentation d'entrée
- [OPTIMIZATIONS](performance/OPTIMIZATIONS.md) - Optimisations
- [ParallelProcessing](performance/ParallelProcessing.md) - Traitement parallèle

## Structure

- [CHANGELOG](structure/CHANGELOG.md) - Journal des modifications
- [CSV_YAML_Support](structure/CSV_YAML_Support.md) - Support CSV et YAML
- [ErrorHandlingStrategy](structure/ErrorHandlingStrategy.md) - Stratégie de gestion des erreurs
- [ImplementationsReference](structure/ImplementationsReference.md) - Référence des implémentations
- [RepoStructureStandard](structure/RepoStructureStandard.md) - Standard de structure du dépôt
- [ScriptInventorySystem](structure/ScriptInventorySystem.md) - Système d'inventaire de scripts

## MCP

- [MCPClientAPI](mcp/MCPClientAPI.md) - API client MCP
- [MCPManager](mcp/MCPManager.md) - Gestionnaire MCP
- [MCPPowerShellServer](mcp/MCPPowerShellServer.md) - Serveur PowerShell MCP

## Augment

- [Augment](augment/index.md) - Documentation liée à Augment
"@
            
            if ($PSCmdlet.ShouldProcess($indexPath, "Mettre à jour le fichier index.md")) {
                Set-Content -Path $indexPath -Value $indexContent -Force
                Write-Host "  Fichier index.md mis à jour : $indexPath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la réorganisation des fichiers : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nRéorganisation des fichiers terminée !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Reorganize-Docs
