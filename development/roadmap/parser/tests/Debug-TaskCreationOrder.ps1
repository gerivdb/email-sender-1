# Debug-TaskCreationOrder.ps1
# Script pour dÃ©boguer l'ordre de crÃ©ation des tÃ¢ches et des dÃ©pendances

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "debug-order.md"
$testMarkdown = @"
# Debug Order

## TÃ¢ches

- [ ] **A** TÃ¢che A
- [ ] **B** TÃ¢che B @depends:A
- [ ] **C** TÃ¢che C @depends:B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Simuler le traitement du fichier
    $content = Get-Content -Path $testMarkdownPath -Raw
    $lines = $content -split "`r?`n"
    
    # CrÃ©er un dictionnaire pour stocker les tÃ¢ches
    $tasks = @{}
    
    # PremiÃ¨re passe : crÃ©er toutes les tÃ¢ches
    Write-Host "`nPremiÃ¨re passe : crÃ©ation des tÃ¢ches" -ForegroundColor Cyan
    
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
                
                Write-Host "  TÃ¢che crÃ©Ã©e: $id - $title" -ForegroundColor Green
            }
        }
    }
    
    # DeuxiÃ¨me passe : traiter les dÃ©pendances
    Write-Host "`nDeuxiÃ¨me passe : traitement des dÃ©pendances" -ForegroundColor Cyan
    
    foreach ($line in $lines) {
        if ($line -match '^\s*[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
            $id = $matches[2]
            $title = $matches[3]
            
            if (-not [string]::IsNullOrEmpty($id) -and $title -match '@depends:(\w+)') {
                $dependsOn = $matches[1]
                
                if ($tasks.ContainsKey($dependsOn)) {
                    $tasks[$id].DependsOn += $dependsOn
                    $tasks[$dependsOn].Dependencies += $id
                    
                    Write-Host "  DÃ©pendance ajoutÃ©e: $id dÃ©pend de $dependsOn" -ForegroundColor Yellow
                } else {
                    Write-Host "  DÃ©pendance non trouvÃ©e: $dependsOn pour la tÃ¢che $id" -ForegroundColor Red
                }
            }
        }
    }
    
    # Afficher les tÃ¢ches et leurs dÃ©pendances
    Write-Host "`nTÃ¢ches et dÃ©pendances:" -ForegroundColor Cyan
    
    foreach ($id in $tasks.Keys) {
        $task = $tasks[$id]
        Write-Host "  TÃ¢che: $($task.Id) - $($task.Title)" -ForegroundColor Green
        
        if ($task.DependsOn.Count -gt 0) {
            Write-Host "    DÃ©pend de: $($task.DependsOn -join ', ')" -ForegroundColor Yellow
        }
        
        if ($task.Dependencies.Count -gt 0) {
            Write-Host "    DÃ©pendances: $($task.Dependencies -join ', ')" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nTest terminÃ©." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
