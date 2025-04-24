# Debug-TaskCreationOrder.ps1
# Script pour déboguer l'ordre de création des tâches et des dépendances

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "debug-order.md"
$testMarkdown = @"
# Debug Order

## Tâches

- [ ] **A** Tâche A
- [ ] **B** Tâche B @depends:A
- [ ] **C** Tâche C @depends:B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Simuler le traitement du fichier
    $content = Get-Content -Path $testMarkdownPath -Raw
    $lines = $content -split "`r?`n"
    
    # Créer un dictionnaire pour stocker les tâches
    $tasks = @{}
    
    # Première passe : créer toutes les tâches
    Write-Host "`nPremière passe : création des tâches" -ForegroundColor Cyan
    
    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
            $id = $matches[2]
            $title = $matches[3]
            
            if (-not [string]::IsNullOrEmpty($id)) {
                $tasks[$id] = @{
                    Id = $id
                    Title = $title
                    Dependencies = @()
                    DependsOn = @()
                }
                
                Write-Host "  Tâche créée: $id - $title" -ForegroundColor Green
            }
        }
    }
    
    # Deuxième passe : traiter les dépendances
    Write-Host "`nDeuxième passe : traitement des dépendances" -ForegroundColor Cyan
    
    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
            $id = $matches[2]
            $title = $matches[3]
            
            if (-not [string]::IsNullOrEmpty($id) -and $title -match '@depends:(\w+)') {
                $dependsOn = $matches[1]
                
                if ($tasks.ContainsKey($dependsOn)) {
                    $tasks[$id].DependsOn += $dependsOn
                    $tasks[$dependsOn].Dependencies += $id
                    
                    Write-Host "  Dépendance ajoutée: $id dépend de $dependsOn" -ForegroundColor Yellow
                } else {
                    Write-Host "  Dépendance non trouvée: $dependsOn pour la tâche $id" -ForegroundColor Red
                }
            }
        }
    }
    
    # Afficher les tâches et leurs dépendances
    Write-Host "`nTâches et dépendances:" -ForegroundColor Cyan
    
    foreach ($id in $tasks.Keys) {
        $task = $tasks[$id]
        Write-Host "  Tâche: $($task.Id) - $($task.Title)" -ForegroundColor Green
        
        if ($task.DependsOn.Count -gt 0) {
            Write-Host "    Dépend de: $($task.DependsOn -join ', ')" -ForegroundColor Yellow
        }
        
        if ($task.Dependencies.Count -gt 0) {
            Write-Host "    Dépendances: $($task.Dependencies -join ', ')" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nTest terminé." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
