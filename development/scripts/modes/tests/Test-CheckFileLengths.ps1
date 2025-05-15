#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test manuel pour Check-FileLengths.ps1.

.DESCRIPTION
    Ce script teste manuellement les fonctionnalités de Check-FileLengths.ps1
    en créant un environnement de test contrôlé.

.NOTES
    Version: 1.0
    Auteur: Généré automatiquement
    Date de création: 2025-05-25
#>

# Chemin vers le script à tester
$scriptPath = "$PSScriptRoot\..\Check-FileLengths.ps1"

# Créer un dossier temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "TestProject_$(Get-Random)"
$testConfigDir = Join-Path -Path $testDir -ChildPath ".augment"
$testReportsDir = Join-Path -Path $testDir -ChildPath "reports"

Write-Host "Création de l'environnement de test dans $testDir" -ForegroundColor Cyan

# Créer la structure de test
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
New-Item -Path $testConfigDir -ItemType Directory -Force | Out-Null
New-Item -Path $testReportsDir -ItemType Directory -Force | Out-Null

# Fonction pour créer un fichier de test avec un nombre spécifique de lignes
function New-TestFile {
    param (
        [string]$Path,
        [string]$Name,
        [int]$Lines,
        [string]$Extension
    )
    
    $filePath = Join-Path -Path $Path -ChildPath "$Name.$Extension"
    $content = 1..$Lines | ForEach-Object { "Line $_" }
    Set-Content -Path $filePath -Value $content
    
    Write-Host "Créé: $filePath ($Lines lignes)" -ForegroundColor Gray
    return $filePath
}

# Créer un fichier de configuration de test
function New-TestConfig {
    param (
        [string]$Path,
        [hashtable]$Limits
    )
    
    $configContent = @{
        agent_auto = @{
            code_quality = @{
                file_length_limits = $Limits
            }
        }
    } | ConvertTo-Json -Depth 5
    
    $configPath = Join-Path -Path $Path -ChildPath "config.json"
    Set-Content -Path $configPath -Value $configContent
    
    Write-Host "Configuration créée: $configPath" -ForegroundColor Gray
    return $configPath
}

# Créer un fichier de configuration de test
$testLimits = @{
    enabled = $true
    ps1 = 100
    py = 150
    js = 80
    md = 200
}

$configPath = New-TestConfig -Path $testConfigDir -Limits $testLimits

# Créer des fichiers de test
$testFiles = @(
    @{ Name = "ShortScript"; Lines = 50; Extension = "ps1" }
    @{ Name = "LongScript"; Lines = 150; Extension = "ps1" }
    @{ Name = "ShortPython"; Lines = 100; Extension = "py" }
    @{ Name = "LongPython"; Lines = 200; Extension = "py" }
    @{ Name = "ShortJS"; Lines = 40; Extension = "js" }
    @{ Name = "LongJS"; Lines = 120; Extension = "js" }
    @{ Name = "ShortMarkdown"; Lines = 100; Extension = "md" }
    @{ Name = "LongMarkdown"; Lines = 250; Extension = "md" }
)

foreach ($file in $testFiles) {
    New-TestFile -Path $testDir -Name $file.Name -Lines $file.Lines -Extension $file.Extension
}

# Créer des dossiers à exclure avec des fichiers
$excludeDirs = @("node_modules", ".git", "dist", "build", "__pycache__")

foreach ($dir in $excludeDirs) {
    $excludePath = Join-Path -Path $testDir -ChildPath $dir
    New-Item -Path $excludePath -ItemType Directory -Force | Out-Null
    New-TestFile -Path $excludePath -Name "ExcludedFile" -Lines 500 -Extension "ps1"
}

# Exécuter le script
Write-Host "`nExécution du script Check-FileLengths.ps1..." -ForegroundColor Green
$reportPath = Join-Path -Path $testReportsDir -ChildPath "test-report.md"

try {
    & $scriptPath -Path $testDir -ReportPath $reportPath -ConfigPath "$testConfigDir\config.json" -Verbose
    
    if (Test-Path $reportPath) {
        Write-Host "`nRapport généré avec succès: $reportPath" -ForegroundColor Green
        Write-Host "`nContenu du rapport:" -ForegroundColor Cyan
        Get-Content -Path $reportPath | ForEach-Object { Write-Host $_ }
    }
    else {
        Write-Host "`nErreur: Le rapport n'a pas été généré." -ForegroundColor Red
    }
}
catch {
    Write-Host "`nErreur lors de l'exécution du script: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage de l'environnement de test..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Test terminé." -ForegroundColor Green
