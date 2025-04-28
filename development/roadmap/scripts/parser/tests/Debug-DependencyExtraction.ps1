# Debug-DependencyExtraction.ps1
# Script pour dÃ©boguer l'extraction des mÃ©tadonnÃ©es de dÃ©pendance

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "debug-test.md"
$testMarkdown = @"
# Debug Test

## Tasks

- [ ] **A** Task A @depends:B
- [ ] **B** Task B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Lire le contenu du fichier
    $content = Get-Content -Path $testMarkdownPath -Raw
    $lines = $content -split "`r?`n"
    
    # Trouver la ligne avec la dÃ©pendance
    $dependencyLine = $lines | Where-Object { $_ -match '@depends:' }
    Write-Host "Ligne avec dÃ©pendance: $dependencyLine" -ForegroundColor Yellow
    
    # Tester l'expression rÃ©guliÃ¨re
    $regex = '@depends:([^@\s]+)'
    if ($dependencyLine -match $regex) {
        Write-Host "Match trouvÃ© avec -match: $($matches[1])" -ForegroundColor Green
    } else {
        Write-Host "Aucun match trouvÃ© avec -match" -ForegroundColor Red
    }
    
    # Tester avec [regex]::Match
    $regexMatch = [regex]::Match($dependencyLine, $regex)
    if ($regexMatch.Success) {
        Write-Host "Match trouvÃ© avec [regex]::Match: $($regexMatch.Groups[1].Value)" -ForegroundColor Green
    } else {
        Write-Host "Aucun match trouvÃ© avec [regex]::Match" -ForegroundColor Red
    }
    
    # Tester avec une expression rÃ©guliÃ¨re plus simple
    $simpleRegex = '@depends:(\w+)'
    if ($dependencyLine -match $simpleRegex) {
        Write-Host "Match trouvÃ© avec expression simple: $($matches[1])" -ForegroundColor Green
    } else {
        Write-Host "Aucun match trouvÃ© avec expression simple" -ForegroundColor Red
    }
    
    Write-Host "Test terminÃ©." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "RÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
