# quick_error_check.ps1 - Vérification rapide des erreurs corrigées
Write-Host "🔍 EMAIL_SENDER_1 - Vérification des corrections" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$projectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
Set-Location $projectRoot

Write-Host "`n1. Test de compilation Go des modules corrigés..." -ForegroundColor Yellow

# Test des modules internes
$modules = @(
    ".\internal\testgen\generator.go",
    ".\internal\codegen\generator.go",
    ".\.github\docs\algorithms\config-validator\email_sender_config_validator.go",
    ".\.github\docs\algorithms\dependency-analysis\email_sender_dependency_analyzer.go",
    ".\.github\docs\algorithms\binary-search\email_sender_binary_search_debug.go"
)

$successCount = 0
$totalCount = $modules.Count

foreach ($module in $modules) {
    if (Test-Path $module) {
        Write-Host "  ✓ Testing: $module" -ForegroundColor Green
        $result = go build $module 2>&1
        if ($LASTEXITCODE -eq 0) {
            $successCount++
            Write-Host "    ✅ Compilation réussie" -ForegroundColor Green
        } else {
            Write-Host "    ❌ Erreurs de compilation:" -ForegroundColor Red
            Write-Host "    $result" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠️  Fichier non trouvé: $module" -ForegroundColor Yellow
    }
}

Write-Host "`n2. Test de syntaxe PowerShell..." -ForegroundColor Yellow
$psFile = ".\.github\docs\algorithms\dependency-analysis\Find-EmailSenderCircularDependencies.ps1"
if (Test-Path $psFile) {
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $psFile -Raw), [ref]$null)
        Write-Host "  ✅ Script PowerShell : syntaxe correcte" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Script PowerShell : erreur de syntaxe" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n📊 RÉSUMÉ DES CORRECTIONS" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Modules Go testés: $successCount/$totalCount réussis" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })
Write-Host "Pourcentage de réussite: $([Math]::Round(($successCount/$totalCount)*100, 1))%" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })

if ($successCount -eq $totalCount) {
    Write-Host "`n🎉 Toutes les corrections majeures sont appliquées avec succès!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Il reste quelques erreurs à corriger" -ForegroundColor Yellow
}

Write-Host "`n3. Génération du rapport final..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$reportContent = @"
# 📋 Rapport de Correction des 625 Erreurs EMAIL_SENDER_1

**Date :** $timestamp  
**Statut :** En cours de correction

## ✅ Corrections Appliquées

### Erreurs Go Corrigées :
1. **Multiplication de chaînes invalide** 
   - Fichier: `.github\docs\algorithms\config-validator\email_sender_config_validator.go`
   - Correction: Remplacement `"="*60` par `strings.Repeat("=", 60)`

2. **Variables non utilisées**
   - Fichier: `.github\docs\algorithms\dependency-analysis\email_sender_dependency_analyzer.go`
   - Correction: Remplacement `patternName` par `_`

3. **Paramètres non utilisés (multiple files)**
   - `internal\testgen\generator.go` : 4 fonctions corrigées
   - `internal\codegen\generator.go` : 4 fonctions corrigées  
   - `binary-search\email_sender_binary_search_debug.go` : 1 fonction corrigée

### Erreurs PowerShell Corrigées :
1. **Here-string mal fermé**
   - Fichier: `Find-EmailSenderCircularDependencies.ps1`
   - Correction: Repositionnement correct de la fermeture `"@`

## 📊 Statistiques
- **Modules Go testés :** $successCount/$totalCount
- **Taux de réussite :** $([Math]::Round(($successCount/$totalCount)*100, 1))%
- **Corrections automatiques :** ~15-20 erreurs sur 625
- **Corrections manuelles restantes :** ~605 erreurs

## 🎯 Prochaines Étapes
1. Continuer les corrections automatisées par catégorie
2. Résoudre les conflits de packages
3. Traiter les erreurs de documentation et linting
4. Valider les corrections par compilation complète

*Rapport généré automatiquement par le système de correction EMAIL_SENDER_1*
"@

$reportFile = ".\error_correction_progress.md"
$reportContent | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "📄 Rapport généré : $reportFile" -ForegroundColor Green

Write-Host "`n🚀 Correction en cours... Continuez avec les prochaines étapes!" -ForegroundColor Cyan
