# Real-File-Test.ps1
# Script de test pour l'extraction des dépendances à partir d'un fichier réel
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet\roadmaps\plans\plan-dev-v8-RAG-roadmap.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "projet\roadmaps\analysis\dependency-analysis.md",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV")]
    [string]$OutputFormat = "Markdown"
)

# Fonction pour extraire les références directes entre tâches
function Get-DirectReferences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des références directes entre tâches..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $references = @{}
    
    # Patterns pour détecter les tâches et les références
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    $referencePattern = '\b([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)\b'
    
    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }
            
            $tasks[$taskId] = @{
                Id = $taskId
                Title = $taskTitle
                Status = $taskStatus
                LineNumber = $lineNumber
                References = @()
            }
        }
    }
    
    # Deuxième passe : identifier les références entre tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            
            # Chercher les références à d'autres tâches dans le titre
            $potentialReferences = [regex]::Matches($taskTitle, $referencePattern) | ForEach-Object { $_.Groups[1].Value }
            
            foreach ($ref in $potentialReferences) {
                # Vérifier si la référence correspond à une tâche existante
                if ($tasks.ContainsKey($ref) -and $ref -ne $taskId) {
                    $tasks[$taskId].References += $ref
                    
                    if (-not $references.ContainsKey($taskId)) {
                        $references[$taskId] = @()
                    }
                    
                    if (-not $references[$taskId].Contains($ref)) {
                        $references[$taskId] += $ref
                    }
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        References = $references
    }
}

# Fonction pour formater les résultats
function Format-DependencyAttributesOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format
    )
    
    Write-Host "Formatage des résultats en $Format..." -ForegroundColor Cyan
    
    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des attributs de dépendances et relations`n`n"
            
            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Tasks.Count)`n"
            $markdown += "- Tâches avec références directes: $($Analysis.References.Count)`n`n"
            
            $markdown += "## Tâches avec dépendances`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasDependencies = ($Analysis.References.ContainsKey($taskId) -and $Analysis.References[$taskId].Count -gt 0)
                
                if ($hasDependencies) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($Analysis.References.ContainsKey($taskId) -and $Analysis.References[$taskId].Count -gt 0) {
                        $markdown += "- Références directes: $($Analysis.References[$taskId] -join ', ')`n"
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,DirectReferences`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $directReferences = if ($Analysis.References.ContainsKey($taskId)) { $Analysis.References[$taskId] -join ';' } else { "" }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$directReferences`"`n"
            }
            
            return $csv
        }
    }
}

# Fonction principale de test
function Test-RealFile {
    [CmdletBinding()]
    param (
        [string]$RoadmapPath,
        [string]$OutputPath,
        [string]$OutputFormat
    )
    
    Write-Host "=== TEST D'EXTRACTION À PARTIR D'UN FICHIER RÉEL ===" -ForegroundColor Magenta
    
    # Vérifier si le chemin de la roadmap est spécifié et existe
    if (-not [string]::IsNullOrEmpty($RoadmapPath) -and (Test-Path -Path $RoadmapPath)) {
        Write-Host "Utilisation de la roadmap réelle: $RoadmapPath" -ForegroundColor Green
        
        # Charger le contenu du fichier
        try {
            $content = Get-Content -Path $RoadmapPath -Raw -Encoding UTF8
            
            if ([string]::IsNullOrEmpty($content)) {
                Write-Host "Le fichier est vide ou n'a pas pu être lu correctement." -ForegroundColor Red
                return
            }
            
            Write-Host "Contenu chargé avec succès. Longueur: $($content.Length) caractères." -ForegroundColor Green
            
            # Extraire les références directes
            $directReferences = Get-DirectReferences -Content $content
            
            # Afficher les statistiques
            Write-Host "`nStatistiques:" -ForegroundColor Cyan
            Write-Host "Nombre de tâches: $($directReferences.Tasks.Count)" -ForegroundColor Green
            Write-Host "Nombre de références: $($directReferences.References.Count)" -ForegroundColor Green
            
            # Combiner les résultats
            $analysis = @{
                Tasks = $directReferences.Tasks
                References = $directReferences.References
            }
            
            # Formater les résultats
            Write-Host "`nFormatage des résultats..." -ForegroundColor Cyan
            $result = Format-DependencyAttributesOutput -Analysis $analysis -Format $OutputFormat
            
            # Enregistrer les résultats si un chemin de sortie est spécifié
            if (-not [string]::IsNullOrEmpty($OutputPath)) {
                $outputDirectory = Split-Path -Path $OutputPath -Parent
                
                if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -Path $outputDirectory)) {
                    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
                }
                
                Set-Content -Path $OutputPath -Value $result
                Write-Host "Résultats enregistrés dans $OutputPath" -ForegroundColor Green
            }
            
            # Afficher un aperçu des résultats
            Write-Host "`nAperçu des résultats:" -ForegroundColor Cyan
            $previewLines = $result -split "`n" | Select-Object -First 20
            $previewLines | ForEach-Object { Write-Host $_ }
            Write-Host "..." -ForegroundColor DarkGray
            
            Write-Host "`n=== TEST TERMINÉ AVEC SUCCÈS ===" -ForegroundColor Magenta
        } catch {
            Write-Host "Erreur lors de la lecture du fichier: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Le fichier spécifié n'existe pas: $RoadmapPath" -ForegroundColor Red
    }
}

# Exécuter le test
Test-RealFile -RoadmapPath $RoadmapPath -OutputPath $OutputPath -OutputFormat $OutputFormat
