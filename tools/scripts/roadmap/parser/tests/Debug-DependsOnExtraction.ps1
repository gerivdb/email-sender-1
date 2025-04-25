# Debug-DependsOnExtraction.ps1
# Script pour déboguer l'extraction des dépendances

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "debug-depends.md"
$testMarkdown = @"
# Debug Depends

## Tâches

- [ ] **A** Tâche A
- [ ] **B** Tâche B @depends:A
- [ ] **C** Tâche C @depends:B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Lire le contenu du fichier
    $content = Get-Content -Path $testMarkdownPath -Raw
    $lines = $content -split "`r?`n"
    
    # Trouver les lignes avec des dépendances
    $dependsLines = $lines | Where-Object { $_ -match '@depends:' }
    Write-Host "`nLignes avec dépendances:" -ForegroundColor Cyan
    foreach ($line in $dependsLines) {
        Write-Host "  $line" -ForegroundColor Yellow
    }
    
    # Tester différentes expressions régulières
    $regexTests = @(
        '@depends:(\w+)',
        '@depends:([\w\.-]+)',
        '@depends:([A-Za-z0-9_\.-]+)'
    )
    
    foreach ($regex in $regexTests) {
        Write-Host "`nTest avec regex: $regex" -ForegroundColor Cyan
        
        foreach ($line in $dependsLines) {
            if ($line -match $regex) {
                Write-Host "  Match trouvé: $($matches[1])" -ForegroundColor Green
                
                # Tester le remplacement
                $newLine = $line -replace $regex, ''
                Write-Host "  Après remplacement: $newLine" -ForegroundColor Yellow
            } else {
                Write-Host "  Aucun match trouvé" -ForegroundColor Red
            }
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
