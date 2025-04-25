# Debug-DependencyExtraction.ps1
# Script pour déboguer l'extraction des métadonnées de dépendance

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test simple
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "debug-test.md"
$testMarkdown = @"
# Debug Test

## Tasks

- [ ] **A** Task A @depends:B
- [ ] **B** Task B
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Lire le contenu du fichier
    $content = Get-Content -Path $testMarkdownPath -Raw
    $lines = $content -split "`r?`n"
    
    # Trouver la ligne avec la dépendance
    $dependencyLine = $lines | Where-Object { $_ -match '@depends:' }
    Write-Host "Ligne avec dépendance: $dependencyLine" -ForegroundColor Yellow
    
    # Tester l'expression régulière
    $regex = '@depends:([^@\s]+)'
    if ($dependencyLine -match $regex) {
        Write-Host "Match trouvé avec -match: $($matches[1])" -ForegroundColor Green
    } else {
        Write-Host "Aucun match trouvé avec -match" -ForegroundColor Red
    }
    
    # Tester avec [regex]::Match
    $regexMatch = [regex]::Match($dependencyLine, $regex)
    if ($regexMatch.Success) {
        Write-Host "Match trouvé avec [regex]::Match: $($regexMatch.Groups[1].Value)" -ForegroundColor Green
    } else {
        Write-Host "Aucun match trouvé avec [regex]::Match" -ForegroundColor Red
    }
    
    # Tester avec une expression régulière plus simple
    $simpleRegex = '@depends:(\w+)'
    if ($dependencyLine -match $simpleRegex) {
        Write-Host "Match trouvé avec expression simple: $($matches[1])" -ForegroundColor Green
    } else {
        Write-Host "Aucun match trouvé avec expression simple" -ForegroundColor Red
    }
    
    Write-Host "Test terminé." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "Répertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
