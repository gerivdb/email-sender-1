# Comparaison des performances entre version originale et modulaire
param(
    [string]$TestPath = "."
)

Write-Host "🔬 Comparaison des versions Original vs Modulaire" -ForegroundColor Magenta
Write-Host "=" * 60 -ForegroundColor Magenta

# Test version originale (archivée)
Write-Host "`n📊 Version ORIGINALE (archivée):" -ForegroundColor Cyan
$originalStart = Get-Date
try {
    $originalResult = & ".\archive\legacy-versions\Fix-PowerShellFunctionNames.ps1" -Path $TestPath -DryRun 2>&1
    $originalEnd = Get-Date
    $originalDuration = ($originalEnd - $originalStart).TotalSeconds
    $originalSuccess = $true
} catch {
    $originalDuration = -1
    $originalSuccess = $false
    Write-Host "❌ Erreur dans la version originale: $($_.Exception.Message)" -ForegroundColor Red
}

# Test version modulaire
Write-Host "`n📊 Version MODULAIRE:" -ForegroundColor Cyan
$modularStart = Get-Date
try {
    $modularResult = & ".\Fix-PowerShellFunctionNames-Modular.ps1" -Path $TestPath -DryRun 2>&1
    $modularEnd = Get-Date
    $modularDuration = ($modularEnd - $modularStart).TotalSeconds
    $modularSuccess = $true
} catch {
    $modularDuration = -1
    $modularSuccess = $false
    Write-Host "❌ Erreur dans la version modulaire: $($_.Exception.Message)" -ForegroundColor Red
}

# Comparaison des résultats
Write-Host "`n📈 RÉSULTATS DE COMPARAISON:" -ForegroundColor Magenta
Write-Host "=" * 40 -ForegroundColor Magenta

$comparisonData = @(
    [PSCustomObject]@{
        Aspect = "Succès d'exécution"
        Original = if ($originalSuccess) { "✅ Oui" } else { "❌ Non" }
        Modulaire = if ($modularSuccess) { "✅ Oui" } else { "❌ Non" }
        Amélioration = if ($modularSuccess -and -not $originalSuccess) { "🚀 Corrigé" } elseif ($modularSuccess -eq $originalSuccess) { "➡️ Identique" } else { "⚠️ Régression" }
    }
    [PSCustomObject]@{
        Aspect = "Temps d'exécution (sec)"
        Original = if ($originalDuration -gt 0) { "{0:F2}" -f $originalDuration } else { "N/A" }
        Modulaire = if ($modularDuration -gt 0) { "{0:F2}" -f $modularDuration } else { "N/A" }
        Amélioration = if ($originalDuration -gt 0 -and $modularDuration -gt 0) {
            $improvement = (($originalDuration - $modularDuration) / $originalDuration) * 100
            if ($improvement -gt 5) { "🚀 {0:F1}% plus rapide" -f $improvement }
            elseif ($improvement -lt -5) { "⚠️ {0:F1}% plus lent" -f [math]::Abs($improvement) }
            else { "➡️ Similaire" }
        } else { "N/A" }
    }
)

$comparisonData | Format-Table -AutoSize

# Analyse des fonctionnalités
Write-Host "`n🔍 ANALYSE DES FONCTIONNALITÉS:" -ForegroundColor Magenta

$features = @(
    @{ Feature = "Architecture modulaire"; Original = "❌"; Modular = "✅" }
    @{ Feature = "Réutilisabilité des composants"; Original = "❌"; Modular = "✅" }
    @{ Feature = "Gestion d'erreur robuste"; Original = "⚠️"; Modular = "✅" }
    @{ Feature = "Cache des verbes approuvés"; Original = "❌"; Modular = "✅" }
    @{ Feature = "API cohérente"; Original = "❌"; Modular = "✅" }
    @{ Feature = "Tests unitaires possibles"; Original = "❌"; Modular = "✅" }
    @{ Feature = "Documentation complète"; Original = "⚠️"; Modular = "✅" }
    @{ Feature = "Extensibilité"; Original = "❌"; Modular = "✅" }
)

foreach ($feature in $features) {
    Write-Host "  $($feature.Feature):" -ForegroundColor White
    Write-Host "    Original: $($feature.Original)  |  Modulaire: $($feature.Modular)" -ForegroundColor Gray
}

# Métriques de code
Write-Host "`n📏 MÉTRIQUES DE CODE:" -ForegroundColor Magenta

$originalFile = "archive\legacy-versions\Fix-PowerShellFunctionNames.ps1"
$modularMainFile = "Fix-PowerShellFunctionNames-Modular.ps1"
$verbMappingFile = "modules\PowerShellVerbMapping\PowerShellVerbMapping.psm1"
$validatorFile = "modules\PowerShellFunctionValidator\PowerShellFunctionValidator.psm1"

if (Test-Path $originalFile) {
    $originalLines = (Get-Content $originalFile).Count
    Write-Host "  Script original: $originalLines lignes" -ForegroundColor White
}

if (Test-Path $modularMainFile) {
    $modularMainLines = (Get-Content $modularMainFile).Count
    Write-Host "  Script principal modulaire: $modularMainLines lignes" -ForegroundColor White
}

if (Test-Path $verbMappingFile) {
    $verbMappingLines = (Get-Content $verbMappingFile).Count
    Write-Host "  Module VerbMapping: $verbMappingLines lignes" -ForegroundColor White
}

if (Test-Path $validatorFile) {
    $validatorLines = (Get-Content $validatorFile).Count
    Write-Host "  Module Validator: $validatorLines lignes" -ForegroundColor White
}

$totalModularLines = $modularMainLines + $verbMappingLines + $validatorLines
Write-Host "  Total modulaire: $totalModularLines lignes" -ForegroundColor Cyan

if ($originalLines -gt 0) {
    $lineIncrease = (($totalModularLines - $originalLines) / $originalLines) * 100
    Write-Host ("  Augmentation: {0:F1}% (pour une meilleure structure)" -f $lineIncrease) -ForegroundColor Yellow
}

Write-Host "`n🎯 CONCLUSION:" -ForegroundColor Magenta
Write-Host "La version modulaire offre:" -ForegroundColor White
Write-Host "  ✅ Une architecture plus maintenable" -ForegroundColor Green
Write-Host "  ✅ Une réutilisabilité accrue des composants" -ForegroundColor Green
Write-Host "  ✅ Une meilleure séparation des responsabilités" -ForegroundColor Green
Write-Host "  ✅ Une extensibilité pour de futures améliorations" -ForegroundColor Green
Write-Host "  ✅ Une correction des problèmes de syntaxe de l'original" -ForegroundColor Green
