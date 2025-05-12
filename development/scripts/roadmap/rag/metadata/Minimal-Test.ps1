# Minimal-Test.ps1
# Script de test minimal pour l'extraction des dépendances
# Version: 1.0
# Date: 2025-05-15

# Fonction pour extraire les références directes entre tâches
function Get-DirectReferences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Host "Extraction des références directes entre tâches..."
    
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

# Créer un exemple de contenu pour les tests
$testContent = @"
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
"@

# Afficher le contenu de test
Write-Host "Contenu de test:" -ForegroundColor Cyan
Write-Host $testContent

# Exécuter la fonction d'extraction des références directes
Write-Host "`nExécution de la fonction d'extraction des références directes..." -ForegroundColor Cyan
$result = Get-DirectReferences -Content $testContent

# Afficher les résultats
Write-Host "`nRésultats:" -ForegroundColor Cyan
$result | ConvertTo-Json -Depth 10
