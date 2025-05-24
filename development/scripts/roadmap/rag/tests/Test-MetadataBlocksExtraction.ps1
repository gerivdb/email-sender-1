# Test-MetadataBlocksExtraction.ps1
# Script de test pour l'extraction des blocs de métadonnées
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestFilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour créer un fichier de test
function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $testContent = @"
---
title: Test de l'extraction des blocs de métadonnées
author: Augment Code
date: 2025-05-15
version: 1.0
tags: [test, metadata, extraction]
---

# Test de l'extraction des blocs de métadonnées

## Front Matter

Ce fichier commence par un bloc de front matter en YAML qui contient des métadonnées sur le document.

## Blocs de code

Voici un exemple de bloc de code Python :

```python
def extract_metadata(content):
    """
    Extraire les métadonnées d'un contenu markdown.
    
    Args:
        content (str): Le contenu markdown à analyser
        
    Returns:
        dict: Les métadonnées extraites
    """
    metadata = {}
    # Code d'extraction des métadonnées
    return metadata
```

Et voici un exemple de bloc de code PowerShell :

```powershell
function Export-Metadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $metadata = @{}
    # Code d'extraction des métadonnées
    return $metadata
}
```

## Blocs de commentaires

<!-- 
Ce bloc de commentaire contient des métadonnées cachées.
type: documentation
status: draft
priority: high
-->

Voici un paragraphe normal qui n'est pas un commentaire.

<!-- Ceci est un commentaire sur une seule ligne -->

<!-- 
Ce bloc de commentaire contient des informations structurées :
- Point 1
- Point 2
- Point 3
-->

## Combinaison de métadonnées

Ce document combine différents types de blocs de métadonnées :
1. Front matter en YAML
2. Blocs de code avec documentation
3. Blocs de commentaires avec métadonnées

<!-- 
metadata:
  version: 1.0
  status: draft
  author: Augment Code
  date: 2025-05-15
-->
"@
    
    try {
        $testContent | Set-Content -Path $FilePath -Encoding UTF8
        Write-Log "Fichier de test créé : $FilePath" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de la création du fichier de test : $_" -Level "Error"
        return $false
    }
}

# Fonction pour exécuter le test d'extraction des blocs de métadonnées
function Test-MetadataBlocksExtraction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Log "Test de l'extraction des blocs de métadonnées..." -Level "Info"
    
    # Vérifier si le script d'extraction des blocs de métadonnées existe
    $metadataScriptPath = Join-Path -Path $parentPath -ChildPath "metadata\Extract-MetadataBlocks.ps1"
    
    if (-not (Test-Path -Path $metadataScriptPath)) {
        Write-Log "Script d'extraction des blocs de métadonnées introuvable : $metadataScriptPath" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie
    $outputDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "output"
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Exécuter l'extraction des blocs de métadonnées
    $outputPath = Join-Path -Path $outputDir -ChildPath "metadata-blocks.md"
    
    $params = @{
        FilePath = $FilePath
        OutputPath = $outputPath
        OutputFormat = "Markdown"
        DetectFrontMatter = $true
        DetectCodeBlocks = $true
        DetectCommentBlocks = $true
    }
    
    try {
        $result = & $metadataScriptPath @params
        
        if ($null -eq $result) {
            Write-Log "L'extraction des blocs de métadonnées n'a pas retourné de résultat." -Level "Error"
            return $false
        }
        
        # Vérifier les résultats
        $analysis = $result.Analysis
        
        Write-Log "Résultats de l'extraction des blocs de métadonnées :" -Level "Info"
        Write-Log "  - Front matter : $($analysis.Stats.HasFrontMatter)" -Level "Info"
        Write-Log "  - Blocs de code : $($analysis.Stats.CodeBlocksCount)" -Level "Info"
        Write-Log "  - Blocs de commentaires : $($analysis.Stats.CommentBlocksCount)" -Level "Info"
        
        # Exporter les résultats au format YAML
        $yamlOutputPath = Join-Path -Path $outputDir -ChildPath "metadata-blocks.yaml"
        
        $yamlParams = @{
            FilePath = $FilePath
            OutputPath = $yamlOutputPath
            OutputFormat = "YAML"
            DetectFrontMatter = $true
            DetectCodeBlocks = $true
            DetectCommentBlocks = $true
        }
        
        $yamlResult = & $metadataScriptPath @yamlParams
        
        if ($null -ne $yamlResult -and $null -ne $yamlResult.Output) {
            Write-Log "Blocs de métadonnées exportés au format YAML : $yamlOutputPath" -Level "Success"
        }
        
        # Générer un rapport si demandé
        if ($GenerateReport) {
            $reportPath = Join-Path -Path $outputDir -ChildPath "metadata-blocks-report.md"
            
            $report = "# Rapport d'extraction des blocs de métadonnées`n`n"
            $report += "Date d'analyse : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            
            $report += "## Résultats`n`n"
            $report += "- Front matter : $($analysis.Stats.HasFrontMatter)`n"
            $report += "- Blocs de code : $($analysis.Stats.CodeBlocksCount)`n"
            $report += "- Blocs de commentaires : $($analysis.Stats.CommentBlocksCount)`n`n"
            
            if ($analysis.Stats.HasFrontMatter -and $analysis.FrontMatter.Data) {
                $report += "## Front Matter`n`n"
                $report += "```yaml`n$($analysis.FrontMatter.Content)`n````n`n"
                
                $report += "### Données extraites`n`n"
                $report += "| Clé | Valeur |`n"
                $report += "|-----|--------|`n"
                
                foreach ($key in $analysis.FrontMatter.Data.Keys | Sort-Object) {
                    $value = $analysis.FrontMatter.Data[$key]
                    
                    if ($value -is [array]) {
                        $value = $value -join ", "
                    }
                    
                    $report += "| $key | $value |`n"
                }
                
                $report += "`n"
            }
            
            if ($analysis.CodeBlocks.Count -gt 0) {
                $report += "## Blocs de code`n`n"
                
                for ($i = 0; $i -lt $analysis.CodeBlocks.Count; $i++) {
                    $codeBlock = $analysis.CodeBlocks[$i]
                    $report += "### Bloc de code $($i + 1) ($($codeBlock.Language))`n`n"
                    $report += "- Lignes : $($codeBlock.StartLine) - $($codeBlock.EndLine)`n`n"
                    $report += "```$($codeBlock.Language)`n$($codeBlock.Content)`n````n`n"
                }
            }
            
            if ($analysis.CommentBlocks.Count -gt 0) {
                $report += "## Blocs de commentaires`n`n"
                
                for ($i = 0; $i -lt $analysis.CommentBlocks.Count; $i++) {
                    $commentBlock = $analysis.CommentBlocks[$i]
                    $report += "### Bloc de commentaire $($i + 1)`n`n"
                    $report += "- Lignes : $($commentBlock.StartLine) - $($commentBlock.EndLine)`n"
                    
                    if ($commentBlock.ContainsKey("ContainsMetadata")) {
                        $report += "- Contient des métadonnées : $($commentBlock.ContainsMetadata)`n"
                    }
                    
                    $report += "`n"
                    $report += "````n$($commentBlock.Content)`n````n`n"
                    
                    if ($commentBlock.ContainsKey("Metadata") -and $commentBlock.Metadata.Count -gt 0) {
                        $report += "#### Métadonnées extraites`n`n"
                        $report += "| Clé | Valeur |`n"
                        $report += "|-----|--------|`n"
                        
                        foreach ($key in $commentBlock.Metadata.Keys | Sort-Object) {
                            $value = $commentBlock.Metadata[$key]
                            $report += "| $key | $value |`n"
                        }
                        
                        $report += "`n"
                    }
                }
            }
            
            $report | Set-Content -Path $reportPath -Encoding UTF8
            Write-Log "Rapport d'extraction enregistré dans : $reportPath" -Level "Success"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de l'exécution de l'extraction des blocs de métadonnées : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-MetadataBlocksTest {
    [CmdletBinding()]
    param (
        [string]$TestFilePath,
        [switch]$GenerateReport
    )
    
    Write-Log "Démarrage du test d'extraction des blocs de métadonnées..." -Level "Info"
    
    # Créer un fichier de test si nécessaire
    if ([string]::IsNullOrEmpty($TestFilePath)) {
        $TestFilePath = Join-Path -Path $scriptPath -ChildPath "data\metadata-blocks-test.md"
        
        # Créer le répertoire de données si nécessaire
        $dataDir = Join-Path -Path $scriptPath -ChildPath "data"
        
        if (-not (Test-Path -Path $dataDir)) {
            New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
        }
        
        if (-not (New-TestFile -FilePath $TestFilePath)) {
            return $false
        }
    } else {
        if (-not (Test-Path -Path $TestFilePath)) {
            Write-Log "Le fichier de test spécifié n'existe pas : $TestFilePath" -Level "Error"
            return $false
        }
    }
    
    # Exécuter le test
    $testResult = Test-MetadataBlocksExtraction -FilePath $TestFilePath -GenerateReport:$GenerateReport
    
    if ($testResult) {
        Write-Log "Test d'extraction des blocs de métadonnées terminé avec succès." -Level "Success"
    } else {
        Write-Log "Test d'extraction des blocs de métadonnées terminé avec des erreurs." -Level "Error"
    }
    
    return $testResult
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-MetadataBlocksTest -TestFilePath $TestFilePath -GenerateReport:$GenerateReport
}

