# Debug-DependsOnExtraction.ps1
# Script pour dÃ©boguer l'extraction des dÃ©pendances

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "debug-depends.md"
$testMarkdown = @"
# Debug Depends

## TÃ¢ches

- [ ] **A** TÃ¢che A
- [ ] **B** TÃ¢che B @depends:A
- [ ] **C** TÃ¢che C @depends:B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Lire le contenu du fichier
    $content = Get-Content -Path $testMarkdownPath -Raw
    $lines = $content -split "`r?`n"
    
    # Trouver les lignes avec des dÃ©pendances
    $dependsLines = $lines | Where-Object { $_ -match '@depends:' }
    Write-Host "`nLignes avec dÃ©pendances:" -ForegroundColor Cyan
    foreach ($line in $dependsLines) {
        Write-Host "  $line" -ForegroundColor Yellow
    }
    
    # Tester diffÃ©rentes expressions rÃ©guliÃ¨res
    $regexTests = @(
        '@depends:(\w+)',
        '@depends:([\w\.-]+)',
        '@depends:([A-Za-z0-9_\.-]+)'
    )
    
    foreach ($regex in $regexTests) {
        Write-Host "`nTest avec regex: $regex" -ForegroundColor Cyan
        
        foreach ($line in $dependsLines) {
            if ($line -match $regex) {
                Write-Host "  Match trouvÃ©: $($matches[1])" -ForegroundColor Green
                
                # Tester le remplacement
                $newLine = $line -replace $regex, ''
                Write-Host "  AprÃ¨s remplacement: $newLine" -ForegroundColor Yellow
            } else {
                Write-Host "  Aucun match trouvÃ©" -ForegroundColor Red
            }
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
