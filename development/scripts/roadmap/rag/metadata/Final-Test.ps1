# Final-Test.ps1
# Script de test final pour l'extraction des dépendances
# Version: 1.0
# Date: 2025-05-15

# Contenu de test
$testContent = @'
# Test de dépendances

## Section 1

- [ ] **1.1** Tâche 1.1
- [ ] **1.2** Tâche 1.2 #blockedBy:1.1
- [ ] **1.3** Tâche 1.3 dépend de: 1.1, 1.2
- [ ] **1.4** Tâche 1.4 requis pour: 1.5, 1.6
- [ ] **1.5** Tâche 1.5 #dependsOn:1.4
- [ ] **1.6** Tâche 1.6 #required_for:2.1
- [ ] **1.7** Tâche 1.7 #customTag:1.1,1.2 #priority:high

## Section 2

- [ ] **2.1** Tâche 2.1 référence à 1.1 et 1.3
- [ ] **2.2** Tâche 2.2 bloqué par: 2.1
- [ ] **2.3** Tâche 2.3 #depends_on:2.2 #blocked_by:1.7
- [ ] **2.4** Tâche 2.4 #relatedTo:2.3,2.5 #milestone:true
- [ ] **2.5** Tâche 2.5
'@

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

# Fonction pour extraire les dépendances de type "bloqué par"
function Get-BlockedByDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des dépendances de type 'bloqué par'..." -ForegroundColor Cyan
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    $blockedByDependencies = @{}
    
    # Patterns pour détecter les tâches et les dépendances
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    $blockedByPatterns = @(
        '(?:bloqué par|blocked by):\s*([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#blockedBy:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#blocked_by:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)'
    )
    
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
                BlockedBy = @()
            }
        }
    }
    
    # Deuxième passe : identifier les dépendances "bloqué par"
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            
            foreach ($pattern in $blockedByPatterns) {
                if ($line -match $pattern) {
                    $blockedByIds = $matches[1] -split '\s*,\s*'
                    
                    foreach ($blockedById in $blockedByIds) {
                        # Vérifier si la référence correspond à une tâche existante
                        if ($tasks.ContainsKey($blockedById) -and $blockedById -ne $taskId) {
                            $tasks[$taskId].BlockedBy += $blockedById
                            
                            if (-not $blockedByDependencies.ContainsKey($taskId)) {
                                $blockedByDependencies[$taskId] = @()
                            }
                            
                            if (-not $blockedByDependencies[$taskId].Contains($blockedById)) {
                                $blockedByDependencies[$taskId] += $blockedById
                            }
                        }
                    }
                }
            }
        }
    }
    
    return @{
        Tasks = $tasks
        BlockedByDependencies = $blockedByDependencies
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
            $markdown += "- Tâches avec références directes: $($Analysis.References.Count)`n"
            $markdown += "- Tâches avec dépendances 'bloqué par': $($Analysis.BlockedByDependencies.Count)`n`n"
            
            $markdown += "## Tâches avec dépendances`n`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasDependencies = ($Analysis.References.ContainsKey($taskId) -and $Analysis.References[$taskId].Count -gt 0) -or
                                   ($Analysis.BlockedByDependencies.ContainsKey($taskId) -and $Analysis.BlockedByDependencies[$taskId].Count -gt 0)
                
                if ($hasDependencies) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"
                    
                    if ($Analysis.References.ContainsKey($taskId) -and $Analysis.References[$taskId].Count -gt 0) {
                        $markdown += "- Références directes: $($Analysis.References[$taskId] -join ', ')`n"
                    }
                    
                    if ($Analysis.BlockedByDependencies.ContainsKey($taskId) -and $Analysis.BlockedByDependencies[$taskId].Count -gt 0) {
                        $markdown += "- Bloqué par: $($Analysis.BlockedByDependencies[$taskId] -join ', ')`n"
                    }
                    
                    $markdown += "`n"
                }
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,DirectReferences,BlockedBy`n"
            
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                $directReferences = if ($Analysis.References.ContainsKey($taskId)) { $Analysis.References[$taskId] -join ';' } else { "" }
                $blockedBy = if ($Analysis.BlockedByDependencies.ContainsKey($taskId)) { $Analysis.BlockedByDependencies[$taskId] -join ';' } else { "" }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$directReferences`",`"$blockedBy`"`n"
            }
            
            return $csv
        }
    }
}

# Fonction principale de test
function Test-Extraction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$OutputFormat = "Markdown"
    )
    
    Write-Host "=== TEST FINAL D'EXTRACTION DES DÉPENDANCES ===" -ForegroundColor Magenta
    
    # Vérifier le contenu
    Write-Host "`nContenu de test:" -ForegroundColor Cyan
    Write-Host "Longueur: $($testContent.Length) caractères" -ForegroundColor Cyan
    Write-Host "Début du contenu:" -ForegroundColor Cyan
    Write-Host ($testContent.Substring(0, [Math]::Min(100, $testContent.Length)))
    
    # Extraire les références directes
    Write-Host "`nExtraction des références directes..." -ForegroundColor Cyan
    $directReferences = Get-DirectReferences -Content $testContent
    
    # Extraire les dépendances "bloqué par"
    Write-Host "`nExtraction des dépendances 'bloqué par'..." -ForegroundColor Cyan
    $blockedByDependencies = Get-BlockedByDependencies -Content $testContent
    
    # Combiner les résultats
    $analysis = @{
        Tasks = @{}
        References = $directReferences.References
        BlockedByDependencies = $blockedByDependencies.BlockedByDependencies
    }
    
    # Fusionner les informations des tâches
    $allTaskIds = @($directReferences.Tasks.Keys) + @($blockedByDependencies.Tasks.Keys) | Select-Object -Unique
    
    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id = $taskId
            Title = ""
            Status = ""
            LineNumber = 0
        }
        
        if ($directReferences.Tasks.ContainsKey($taskId)) {
            $task.Title = $directReferences.Tasks[$taskId].Title
            $task.Status = $directReferences.Tasks[$taskId].Status
            $task.LineNumber = $directReferences.Tasks[$taskId].LineNumber
        } elseif ($blockedByDependencies.Tasks.ContainsKey($taskId)) {
            $task.Title = $blockedByDependencies.Tasks[$taskId].Title
            $task.Status = $blockedByDependencies.Tasks[$taskId].Status
            $task.LineNumber = $blockedByDependencies.Tasks[$taskId].LineNumber
        }
        
        $analysis.Tasks[$taskId] = $task
    }
    
    # Formater les résultats
    Write-Host "`nFormatage des résultats..." -ForegroundColor Cyan
    $result = Format-DependencyAttributesOutput -Analysis $analysis -Format $OutputFormat
    
    # Afficher les résultats
    Write-Host "`nRésultats:" -ForegroundColor Green
    Write-Host $result
    
    Write-Host "`n=== TEST TERMINÉ ===" -ForegroundColor Magenta
}

# Exécuter le test
Test-Extraction
