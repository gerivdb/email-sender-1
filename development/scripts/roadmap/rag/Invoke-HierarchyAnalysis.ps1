# Invoke-HierarchyAnalysis.ps1
# Script principal pour analyser la hiérarchie et les métadonnées des roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeIndentation,
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeIdentifiers,
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeRelations,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExtractInlineMetadata,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExtractMetadataBlocks,
    
    [Parameter(Mandatory = $false)]
    [switch]$InferMetadata,
    
    [Parameter(Mandatory = $false)]
    [switch]$FixInconsistencies,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV", "YAML", "GraphViz")]
    [string]$OutputFormat = "JSON",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"
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

# Fonction pour vérifier si un fichier existe
function Test-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (-not (Test-Path -Path $FilePath)) {
        Write-Log "Le fichier spécifié n'existe pas : $FilePath" -Level "Error"
        return $false
    }
    
    return $true
}

# Fonction pour créer un répertoire de sortie
function New-OutputDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )
    
    if (-not (Test-Path -Path $OutputDir)) {
        try {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire de sortie créé : $OutputDir" -Level "Success"
        } catch {
            Write-Log "Erreur lors de la création du répertoire de sortie : $_" -Level "Error"
            return $false
        }
    }
    
    return $true
}

# Fonction pour générer un rapport complet
function New-AnalysisReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )
    
    Write-Log "Génération du rapport d'analyse..." -Level "Info"
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $reportPath = Join-Path -Path $OutputDir -ChildPath "$fileName-report.md"
    
    $report = "# Rapport d'analyse de la roadmap : $fileName`n`n"
    $report += "Date d'analyse : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    
    # Résumé
    $report += "## Résumé`n`n"
    $report += "| Analyse | Résultat |`n"
    $report += "|---------|----------|`n"
    
    if ($Results.ContainsKey("Indentation")) {
        $indentationStats = $Results.Indentation.Analysis.IndentationStats
        $report += "| Indentation | $($indentationStats.IndentedLines) lignes indentées sur $($indentationStats.TotalLines) |`n"
    }
    
    if ($Results.ContainsKey("Identifiers")) {
        $identifierStats = $Results.Identifiers.Analysis.Stats
        $report += "| Identifiants | $($identifierStats.LinesWithIdentifiers) tâches avec identifiants sur $($identifierStats.TotalLines) |`n"
    }
    
    if ($Results.ContainsKey("Relations")) {
        $relationStats = $Results.Relations.Analysis.Stats
        $report += "| Relations | $($relationStats.ExplicitRelations) relations explicites, $($relationStats.ImplicitRelations) relations implicites |`n"
    }
    
    if ($Results.ContainsKey("InlineMetadata")) {
        $metadataStats = $Results.InlineMetadata.Analysis.Stats
        $report += "| Métadonnées inline | $($metadataStats.TasksWithTags) tâches avec tags, $($metadataStats.TasksWithAttributes) avec attributs |`n"
    }
    
    if ($Results.ContainsKey("MetadataBlocks")) {
        $blockStats = $Results.MetadataBlocks.Analysis.Stats
        $report += "| Blocs de métadonnées | Front matter: $($blockStats.HasFrontMatter), Blocs de code: $($blockStats.CodeBlocksCount), Commentaires: $($blockStats.CommentBlocksCount) |`n"
    }
    
    if ($Results.ContainsKey("InferredMetadata")) {
        $inferredStats = @{
            Priority = ($Results.InferredMetadata.Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Priority') } | Measure-Object).Count
            Complexity = ($Results.InferredMetadata.Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Complexity') } | Measure-Object).Count
            Category = ($Results.InferredMetadata.Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Category') } | Measure-Object).Count
            Dependencies = ($Results.InferredMetadata.Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Dependencies') -and $_.InferredMetadata.Dependencies.Count -gt 0 } | Measure-Object).Count
        }
        $report += "| Métadonnées inférées | Priorité: $($inferredStats.Priority), Complexité: $($inferredStats.Complexity), Catégorie: $($inferredStats.Category), Dépendances: $($inferredStats.Dependencies) |`n"
    }
    
    $report += "`n"
    
    # Détails des analyses
    if ($Results.ContainsKey("Indentation")) {
        $report += "## Analyse de l'indentation`n`n"
        $indentation = $Results.Indentation.Analysis
        $report += "- Espaces par niveau : $($indentation.SpacesPerLevel)`n"
        $report += "- Tabulations utilisées : $($indentation.TabsUsed)`n"
        $report += "- Espaces utilisés : $($indentation.SpacesUsed)`n"
        $report += "- Indentation mixte : $($indentation.MixedIndentation)`n"
        $report += "- Indentation incohérente : $($indentation.InconsistentIndentation)`n"
        $report += "- Niveau d'indentation maximal : $($indentation.MaxIndentLevel)`n"
        
        if ($indentation.InconsistentLines.Count -gt 0) {
            $report += "- Lignes avec indentation incohérente : $($indentation.InconsistentLines -join ", ")`n"
        }
        
        $report += "`n"
    }
    
    if ($Results.ContainsKey("Identifiers")) {
        $report += "## Analyse des identifiants`n`n"
        $identifiers = $Results.Identifiers.Analysis
        $report += "- Format numérique : $($identifiers.IdentifierFormats.Numeric)`n"
        $report += "- Format hiérarchique : $($identifiers.IdentifierFormats.Hierarchical)`n"
        $report += "- Format alphanumérique : $($identifiers.IdentifierFormats.AlphaNumeric)`n"
        $report += "- Format mixte : $($identifiers.IdentifierFormats.Mixed)`n"
        $report += "- Profondeur de la hiérarchie : $($identifiers.HierarchyDepth)`n"
        
        if ($identifiers.InconsistentLines.Count -gt 0) {
            $report += "- Lignes avec identifiants incohérents : $($identifiers.InconsistentLines -join ", ")`n"
        }
        
        if ($identifiers.MissingIdentifiers.Count -gt 0) {
            $report += "- Lignes avec identifiants manquants : $($identifiers.MissingIdentifiers -join ", ")`n"
        }
        
        $report += "`n"
    }
    
    if ($Results.ContainsKey("Relations")) {
        $report += "## Analyse des relations`n`n"
        $relations = $Results.Relations.Analysis
        $report += "- Tâches totales : $($relations.Stats.TotalTasks)`n"
        $report += "- Tâches terminées : $($relations.Stats.CompletedTasks)`n"
        $report += "- Relations explicites : $($relations.Stats.ExplicitRelations)`n"
        $report += "- Relations implicites : $($relations.Stats.ImplicitRelations)`n"
        $report += "- Sections : $($relations.Stats.Sections)`n"
        $report += "- Groupes thématiques : $($relations.Stats.ThematicGroups)`n"
        $report += "`n"
    }
    
    if ($Results.ContainsKey("InlineMetadata")) {
        $report += "## Analyse des métadonnées inline`n`n"
        $metadata = $Results.InlineMetadata.Analysis
        $report += "- Tâches totales : $($metadata.Stats.TotalTasks)`n"
        $report += "- Tâches avec tags : $($metadata.Stats.TasksWithTags)`n"
        $report += "- Tâches avec attributs : $($metadata.Stats.TasksWithAttributes)`n"
        $report += "- Tâches avec dates : $($metadata.Stats.TasksWithDates)`n"
        $report += "- Tags uniques : $($metadata.Stats.UniqueTags)`n"
        $report += "- Attributs uniques : $($metadata.Stats.UniqueAttributes)`n"
        $report += "`n"
        
        if ($metadata.Tags.Count -gt 0) {
            $report += "### Tags les plus utilisés`n`n"
            $report += "| Tag | Occurrences |`n"
            $report += "|-----|------------|`n"
            
            $topTags = $metadata.Tags.GetEnumerator() | Sort-Object -Property { $_.Value.Count } -Descending | Select-Object -First 10
            foreach ($tag in $topTags) {
                $report += "| #$($tag.Key) | $($tag.Value.Count) |`n"
            }
            
            $report += "`n"
        }
    }
    
    if ($Results.ContainsKey("MetadataBlocks")) {
        $report += "## Analyse des blocs de métadonnées`n`n"
        $blocks = $Results.MetadataBlocks.Analysis
        $report += "- Front matter : $($blocks.Stats.HasFrontMatter)`n"
        $report += "- Blocs de code : $($blocks.Stats.CodeBlocksCount)`n"
        $report += "- Blocs de commentaires : $($blocks.Stats.CommentBlocksCount)`n"
        $report += "`n"
        
        if ($blocks.Stats.HasFrontMatter -and $blocks.FrontMatter.Data) {
            $report += "### Front Matter`n`n"
            $report += "| Clé | Valeur |`n"
            $report += "|-----|--------|`n"
            
            foreach ($key in $blocks.FrontMatter.Data.Keys | Sort-Object) {
                $value = $blocks.FrontMatter.Data[$key]
                
                if ($value -is [array]) {
                    $value = $value -join ", "
                }
                
                $report += "| $key | $value |`n"
            }
            
            $report += "`n"
        }
    }
    
    if ($Results.ContainsKey("InferredMetadata")) {
        $report += "## Métadonnées inférées`n`n"
        
        # Statistiques par priorité
        if (($Results.InferredMetadata.Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Priority') } | Measure-Object).Count -gt 0) {
            $report += "### Répartition par priorité`n`n"
            $priorityCounts = @{
                "High" = 0
                "Medium" = 0
                "Low" = 0
            }
            
            foreach ($task in $Results.InferredMetadata.Tasks.Values) {
                if ($task.InferredMetadata.ContainsKey('Priority')) {
                    $priorityCounts[$task.InferredMetadata.Priority]++
                }
            }
            
            $report += "| Priorité | Nombre de tâches |`n"
            $report += "|----------|-----------------|`n"
            $report += "| Haute | $($priorityCounts.High) |`n"
            $report += "| Moyenne | $($priorityCounts.Medium) |`n"
            $report += "| Basse | $($priorityCounts.Low) |`n"
            $report += "`n"
        }
        
        # Statistiques par complexité
        if (($Results.InferredMetadata.Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Complexity') } | Measure-Object).Count -gt 0) {
            $report += "### Répartition par complexité`n`n"
            $complexityCounts = @{
                "High" = 0
                "Medium" = 0
                "Low" = 0
            }
            
            foreach ($task in $Results.InferredMetadata.Tasks.Values) {
                if ($task.InferredMetadata.ContainsKey('Complexity')) {
                    $complexityCounts[$task.InferredMetadata.Complexity]++
                }
            }
            
            $report += "| Complexité | Nombre de tâches |`n"
            $report += "|------------|-----------------|`n"
            $report += "| Haute | $($complexityCounts.High) |`n"
            $report += "| Moyenne | $($complexityCounts.Medium) |`n"
            $report += "| Basse | $($complexityCounts.Low) |`n"
            $report += "`n"
        }
        
        # Statistiques par catégorie
        if (($Results.InferredMetadata.Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Category') } | Measure-Object).Count -gt 0) {
            $report += "### Répartition par catégorie`n`n"
            $categoryCounts = @{}
            
            foreach ($task in $Results.InferredMetadata.Tasks.Values) {
                if ($task.InferredMetadata.ContainsKey('Category')) {
                    $category = $task.InferredMetadata.Category
                    if (-not $categoryCounts.ContainsKey($category)) {
                        $categoryCounts[$category] = 0
                    }
                    $categoryCounts[$category]++
                }
            }
            
            $report += "| Catégorie | Nombre de tâches |`n"
            $report += "|-----------|-----------------|`n"
            
            foreach ($category in $categoryCounts.Keys | Sort-Object) {
                $report += "| $category | $($categoryCounts[$category]) |`n"
            }
            
            $report += "`n"
        }
    }
    
    # Recommandations
    $report += "## Recommandations`n`n"
    
    if ($Results.ContainsKey("Indentation") -and $Results.Indentation.Analysis.InconsistentIndentation) {
        $report += "- **Indentation** : Normaliser l'indentation en utilisant $($Results.Indentation.Analysis.SpacesPerLevel) espaces par niveau.`n"
    }
    
    if ($Results.ContainsKey("Identifiers") -and $Results.Identifiers.Analysis.Stats.InconsistentLines -gt 0) {
        $report += "- **Identifiants** : Normaliser les identifiants en utilisant un format hiérarchique cohérent.`n"
    }
    
    if ($Results.ContainsKey("InlineMetadata") -and $Results.InlineMetadata.Analysis.Stats.TasksWithTags -eq 0) {
        $report += "- **Métadonnées** : Ajouter des tags aux tâches pour faciliter le filtrage et la recherche.`n"
    }
    
    if ($Results.ContainsKey("Relations") -and $Results.Relations.Analysis.Stats.ExplicitRelations -eq 0) {
        $report += "- **Relations** : Ajouter des relations explicites entre les tâches dépendantes.`n"
    }
    
    # Enregistrer le rapport
    $report | Set-Content -Path $reportPath -Encoding UTF8
    Write-Log "Rapport d'analyse enregistré dans : $reportPath" -Level "Success"
    
    return $reportPath
}

# Fonction principale
function Invoke-HierarchyAnalysis {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [switch]$AnalyzeIndentation,
        [switch]$AnalyzeIdentifiers,
        [switch]$AnalyzeRelations,
        [switch]$ExtractInlineMetadata,
        [switch]$ExtractMetadataBlocks,
        [switch]$InferMetadata,
        [switch]$FixInconsistencies,
        [string]$OutputDir,
        [string]$OutputFormat,
        [switch]$GenerateReport
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-FileExists -FilePath $FilePath)) {
        return $false
    }
    
    # Créer le répertoire de sortie si nécessaire
    if ([string]::IsNullOrEmpty($OutputDir)) {
        $OutputDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath "analysis"
    }
    
    if (-not (New-OutputDirectory -OutputDir $OutputDir)) {
        return $false
    }
    
    # Lire le contenu du fichier
    try {
        $content = Get-Content -Path $FilePath -Raw
    } catch {
        Write-Log "Erreur lors de la lecture du fichier : $_" -Level "Error"
        return $false
    }
    
    # Initialiser les résultats
    $results = @{}
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    
    # Analyser l'indentation si demandé
    if ($AnalyzeIndentation) {
        Write-Log "Analyse de l'indentation..." -Level "Info"
        
        $indentationScriptPath = Join-Path -Path $scriptPath -ChildPath "hierarchy\Analyze-IndentationLevels.ps1"
        
        if (Test-Path -Path $indentationScriptPath) {
            $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-indentation.$($OutputFormat.ToLower())"
            
            $params = @{
                FilePath = $FilePath
                OutputPath = $outputPath
                FixInconsistencies = $FixInconsistencies
            }
            
            $indentationResult = & $indentationScriptPath @params
            $results.Indentation = $indentationResult
            
            Write-Log "Analyse de l'indentation terminée." -Level "Success"
        } else {
            Write-Log "Script d'analyse de l'indentation introuvable : $indentationScriptPath" -Level "Error"
        }
    }
    
    # Analyser les identifiants si demandé
    if ($AnalyzeIdentifiers) {
        Write-Log "Analyse des identifiants..." -Level "Info"
        
        $identifiersScriptPath = Join-Path -Path $scriptPath -ChildPath "hierarchy\Analyze-NumericIdentifiers.ps1"
        
        if (Test-Path -Path $identifiersScriptPath) {
            $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-identifiers.$($OutputFormat.ToLower())"
            
            $params = @{
                FilePath = $FilePath
                OutputPath = $outputPath
                FixInconsistencies = $FixInconsistencies
                PreferredFormat = "Hierarchical"
            }
            
            $identifiersResult = & $identifiersScriptPath @params
            $results.Identifiers = $identifiersResult
            
            Write-Log "Analyse des identifiants terminée." -Level "Success"
        } else {
            Write-Log "Script d'analyse des identifiants introuvable : $identifiersScriptPath" -Level "Error"
        }
    }
    
    # Analyser les relations si demandé
    if ($AnalyzeRelations) {
        Write-Log "Analyse des relations contextuelles..." -Level "Info"
        
        $relationsScriptPath = Join-Path -Path $scriptPath -ChildPath "hierarchy\Analyze-ContextualRelations.ps1"
        
        if (Test-Path -Path $relationsScriptPath) {
            $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-relations.$($OutputFormat.ToLower())"
            
            $params = @{
                FilePath = $FilePath
                OutputPath = $outputPath
                OutputFormat = $OutputFormat
                DetectImplicitRelations = $true
                AnalyzeSectionTitles = $true
                DetectThematicGroups = $true
            }
            
            $relationsResult = & $relationsScriptPath @params
            $results.Relations = $relationsResult
            
            Write-Log "Analyse des relations contextuelles terminée." -Level "Success"
        } else {
            Write-Log "Script d'analyse des relations contextuelles introuvable : $relationsScriptPath" -Level "Error"
        }
    }
    
    # Extraire les métadonnées inline si demandé
    if ($ExtractInlineMetadata) {
        Write-Log "Extraction des métadonnées inline..." -Level "Info"
        
        $inlineMetadataScriptPath = Join-Path -Path $scriptPath -ChildPath "metadata\Extract-InlineMetadata.ps1"
        
        if (Test-Path -Path $inlineMetadataScriptPath) {
            $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-inline-metadata.$($OutputFormat.ToLower())"
            
            $params = @{
                FilePath = $FilePath
                OutputPath = $outputPath
                OutputFormat = $OutputFormat
                DetectTags = $true
                DetectAttributes = $true
                DetectDates = $true
            }
            
            $inlineMetadataResult = & $inlineMetadataScriptPath @params
            $results.InlineMetadata = $inlineMetadataResult
            
            Write-Log "Extraction des métadonnées inline terminée." -Level "Success"
        } else {
            Write-Log "Script d'extraction des métadonnées inline introuvable : $inlineMetadataScriptPath" -Level "Error"
        }
    }
    
    # Extraire les blocs de métadonnées si demandé
    if ($ExtractMetadataBlocks) {
        Write-Log "Extraction des blocs de métadonnées..." -Level "Info"
        
        $metadataBlocksScriptPath = Join-Path -Path $scriptPath -ChildPath "metadata\Extract-MetadataBlocks.ps1"
        
        if (Test-Path -Path $metadataBlocksScriptPath) {
            $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-metadata-blocks.$($OutputFormat.ToLower())"
            
            $params = @{
                FilePath = $FilePath
                OutputPath = $outputPath
                OutputFormat = $OutputFormat
                DetectFrontMatter = $true
                DetectCodeBlocks = $true
                DetectCommentBlocks = $true
            }
            
            $metadataBlocksResult = & $metadataBlocksScriptPath @params
            $results.MetadataBlocks = $metadataBlocksResult
            
            Write-Log "Extraction des blocs de métadonnées terminée." -Level "Success"
        } else {
            Write-Log "Script d'extraction des blocs de métadonnées introuvable : $metadataBlocksScriptPath" -Level "Error"
        }
    }
    
    # Inférer les métadonnées si demandé
    if ($InferMetadata) {
        Write-Log "Inférence des métadonnées..." -Level "Info"
        
        $inferMetadataScriptPath = Join-Path -Path $scriptPath -ChildPath "metadata\Infer-TaskMetadata.ps1"
        
        if (Test-Path -Path $inferMetadataScriptPath) {
            $outputPath = Join-Path -Path $OutputDir -ChildPath "$fileName-inferred-metadata.$($OutputFormat.ToLower())"
            
            $params = @{
                FilePath = $FilePath
                OutputPath = $outputPath
                OutputFormat = $OutputFormat
                InferPriority = $true
                InferComplexity = $true
                InferCategory = $true
                InferDependencies = $true
            }
            
            $inferredMetadataResult = & $inferMetadataScriptPath @params
            $results.InferredMetadata = $inferredMetadataResult
            
            Write-Log "Inférence des métadonnées terminée." -Level "Success"
        } else {
            Write-Log "Script d'inférence des métadonnées introuvable : $inferMetadataScriptPath" -Level "Error"
        }
    }
    
    # Générer un rapport si demandé
    if ($GenerateReport) {
        $reportPath = New-AnalysisReport -FilePath $FilePath -Results $results -OutputDir $OutputDir
        $results.ReportPath = $reportPath
    }
    
    return $results
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-HierarchyAnalysis -FilePath $FilePath -AnalyzeIndentation:$AnalyzeIndentation -AnalyzeIdentifiers:$AnalyzeIdentifiers -AnalyzeRelations:$AnalyzeRelations -ExtractInlineMetadata:$ExtractInlineMetadata -ExtractMetadataBlocks:$ExtractMetadataBlocks -InferMetadata:$InferMetadata -FixInconsistencies:$FixInconsistencies -OutputDir $OutputDir -OutputFormat $OutputFormat -GenerateReport:$GenerateReport
}
