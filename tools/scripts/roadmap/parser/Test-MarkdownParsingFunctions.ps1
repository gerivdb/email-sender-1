# Test-MarkdownParsingFunctions.ps1
# Script pour tester les fonctions de parsing du markdown

# Importer le module RoadmapParser3
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser3.psm1"
Import-Module $modulePath -Force

# Tester les fonctions de parsing du markdown
Write-Host "Test des fonctions de parsing du markdown..." -ForegroundColor Cyan

# Tester Get-MarkdownTaskIndentation
Write-Host "`nTest de Get-MarkdownTaskIndentation..." -ForegroundColor Cyan
$testLines = @(
    "- [ ] TÃ¢che sans indentation",
    "  - [ ] TÃ¢che avec 1 niveau d'indentation",
    "    - [ ] TÃ¢che avec 2 niveaux d'indentation",
    "      - [ ] TÃ¢che avec 3 niveaux d'indentation"
)

foreach ($line in $testLines) {
    $indentation = Get-MarkdownTaskIndentation -Line $line
    Write-Host "Ligne: '$line'" -ForegroundColor Gray
    Write-Host "Indentation: $indentation" -ForegroundColor Green
}

# Tester ConvertFrom-MarkdownTaskStatus
Write-Host "`nTest de ConvertFrom-MarkdownTaskStatus..." -ForegroundColor Cyan
$testMarkers = @(" ", "x", "X", "~", "!")

foreach ($marker in $testMarkers) {
    $status = ConvertFrom-MarkdownTaskStatus -StatusMarker $marker
    Write-Host "Marqueur: '$marker'" -ForegroundColor Gray
    Write-Host "Statut: $status" -ForegroundColor Green
}

# Tester Get-MarkdownTaskId
Write-Host "`nTest de Get-MarkdownTaskId..." -ForegroundColor Cyan
$testLines = @(
    "- [ ] TÃ¢che sans ID",
    "- [ ] **1** TÃ¢che avec ID simple",
    "- [ ] **1.2.3** TÃ¢che avec ID complexe"
)

foreach ($line in $testLines) {
    $id = Get-MarkdownTaskId -Line $line
    Write-Host "Ligne: '$line'" -ForegroundColor Gray
    Write-Host "ID: $id" -ForegroundColor Green
}

# Tester Get-MarkdownTaskTitle
Write-Host "`nTest de Get-MarkdownTaskTitle..." -ForegroundColor Cyan
$testLines = @(
    "- [ ] TÃ¢che sans ID",
    "- [ ] **1** TÃ¢che avec ID simple",
    "- [ ] **1.2.3** TÃ¢che avec ID complexe"
)

foreach ($line in $testLines) {
    $title = Get-MarkdownTaskTitle -Line $line
    Write-Host "Ligne: '$line'" -ForegroundColor Gray
    Write-Host "Titre: $title" -ForegroundColor Green
}

# Tester Get-MarkdownTaskDescription
Write-Host "`nTest de Get-MarkdownTaskDescription..." -ForegroundColor Cyan
$testLines = @(
    "- [ ] **1** TÃ¢che 1",
    "  Description de la tÃ¢che 1",
    "  Suite de la description",
    "- [ ] **2** TÃ¢che 2",
    "  Description de la tÃ¢che 2"
)

$description1 = Get-MarkdownTaskDescription -Lines $testLines -StartIndex 0
$description2 = Get-MarkdownTaskDescription -Lines $testLines -StartIndex 3

Write-Host "Lignes:" -ForegroundColor Gray
$testLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host "Description de la tÃ¢che 1: '$description1'" -ForegroundColor Green
Write-Host "Description de la tÃ¢che 2: '$description2'" -ForegroundColor Green

# Tester ConvertFrom-MarkdownTaskLine
Write-Host "`nTest de ConvertFrom-MarkdownTaskLine..." -ForegroundColor Cyan
$testLines = @(
    "- [ ] TÃ¢che sans ID",
    "- [x] **1** TÃ¢che complÃ©tÃ©e",
    "- [~] **1.2** TÃ¢che en cours",
    "- [!] **1.2.3** TÃ¢che bloquÃ©e",
    "  - [ ] **1.2.3.1** TÃ¢che avec indentation"
)

foreach ($line in $testLines) {
    $taskInfo = ConvertFrom-MarkdownTaskLine -Line $line
    Write-Host "Ligne: '$line'" -ForegroundColor Gray
    Write-Host "ID: $($taskInfo.Id)" -ForegroundColor Green
    Write-Host "Titre: $($taskInfo.Title)" -ForegroundColor Green
    Write-Host "Statut: $($taskInfo.Status)" -ForegroundColor Green
    Write-Host "Indentation: $($taskInfo.Indentation)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Tests terminÃ©s!" -ForegroundColor Cyan
