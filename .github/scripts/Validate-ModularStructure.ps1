param(
    [string]$AlgorithmsDir = ".github/docs/algorithms"
)

Write-Host "VALIDATION STRUCTURE MODULAIRE EMAIL_SENDER_1" -ForegroundColor Cyan

if (-not (Test-Path $AlgorithmsDir)) {
    Write-Error "Dossier algorithms non trouve: $AlgorithmsDir"
    exit 1
}

# Verifier les modules existants
$expectedModules = @(
    "error-triage",
    "binary-search", 
    "dependency-analysis",
    "progressive-build",
    "auto-fix",
    "analysis-pipeline",
    "config-validator",
    "dependency-resolution",
    "shared"
)

Write-Host "MODULES ATTENDUS:" -ForegroundColor Yellow
foreach ($module in $expectedModules) {
    $modulePath = Join-Path $AlgorithmsDir $module
    if (Test-Path $modulePath) {
        Write-Host "  ✓ $module" -ForegroundColor Green
        
        # Verifier les fichiers dans le module
        $files = Get-ChildItem $modulePath -File
        foreach ($file in $files) {
            Write-Host "    - $($file.Name) ($($file.Length) bytes)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ $module MANQUANT" -ForegroundColor Red
    }
}

# Verifier l'index principal
$indexPath = Join-Path $AlgorithmsDir "README.md"
if (Test-Path $indexPath) {
    $indexSize = (Get-Item $indexPath).Length
    Write-Host "INDEX PRINCIPAL: ✓ README.md ($indexSize bytes)" -ForegroundColor Green
} else {
    Write-Host "INDEX PRINCIPAL: ✗ README.md MANQUANT" -ForegroundColor Red
}

# Compter les fichiers totaux
$totalFiles = Get-ChildItem $AlgorithmsDir -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "TOTAL FICHIERS: $totalFiles" -ForegroundColor Cyan

# Tester un module specifique
$testModule = "error-triage"
$testModulePath = Join-Path $AlgorithmsDir $testModule
if (Test-Path $testModulePath) {
    Write-Host "TEST MODULE $testModule:" -ForegroundColor Blue
    $testReadme = Join-Path $testModulePath "README.md"
    if (Test-Path $testReadme) {
        $content = Get-Content $testReadme -Raw
        $lines = $content -split "`n" | Measure-Object | Select-Object -ExpandProperty Count
        Write-Host "  README.md: $lines lignes" -ForegroundColor Green
        
        # Chercher des patterns cles
        if ($content -match "EMAIL_SENDER_1") {
            Write-Host "  ✓ Contient EMAIL_SENDER_1" -ForegroundColor Green
        }
        if ($content -match "Classification") {
            Write-Host "  ✓ Contient terme-cle 'Classification'" -ForegroundColor Green
        }
    }
}

Write-Host "VALIDATION TERMINEE!" -ForegroundColor Cyan
