# Analyse complète des corrélations .github
$ErrorActionPreference = "Continue"
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.github"

Write-Host "🔍 ANALYSE COMPLÈTE DES CORRÉLATIONS .github" -ForegroundColor Cyan
Write-Host "=" * 60

# 1. INVENTAIRE COMPLET
$allFiles = Get-ChildItem -Path $basePath -Recurse -File | Sort-Object FullName
Write-Host "📁 Total fichiers analysés: $($allFiles.Count)" -ForegroundColor Green

# 2. ANALYSE PAR CATÉGORIE
$categories = @{
    "Prompts" = @($allFiles | Where-Object { $_.FullName -like "*\prompts\*" })
    "Documentation" = @($allFiles | Where-Object { $_.FullName -like "*\docs\*" })
    "Instructions" = @($allFiles | Where-Object { $_.FullName -like "*\instructions\*" })
    "Workflows" = @($allFiles | Where-Object { $_.FullName -like "*\workflows\*" })
    "Templates" = @($allFiles | Where-Object { $_.FullName -like "*TEMPLATE*" })
    "Scripts" = @($allFiles | Where-Object { $_.Extension -eq ".ps1" })
    "Config" = @($allFiles | Where-Object { $_.Extension -in @(".yml", ".yaml", ".json") })
}

foreach ($cat in $categories.Keys) {
    Write-Host "`n📂 $cat : $($categories[$cat].Count) fichiers" -ForegroundColor Yellow
    $categories[$cat] | ForEach-Object { Write-Host "  - $($_.Name)" }
}

# 3. VÉRIFICATION DES RÉFÉRENCES CROISÉES
Write-Host "`n🔗 ANALYSE DES RÉFÉRENCES CROISÉES" -ForegroundColor Cyan

$references = @{}
$allFiles | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        # Recherche de références vers d'autres fichiers
        $matches = [regex]::Matches($content, '(?:\.\/|\.\.\/|\/)([a-zA-Z0-9_\-\/\.]+\.(?:md|yml|yaml|ps1|json))')
        foreach ($match in $matches) {
            $refFile = $match.Groups[1].Value
            if (-not $references.ContainsKey($_.Name)) {
                $references[$_.Name] = @()
            }
            $references[$_.Name] += $refFile
        }
    }
}

# 4. DÉTECTION DES INCOHÉRENCES
Write-Host "`n⚠️  DÉTECTION DES INCOHÉRENCES" -ForegroundColor Red

$issues = @()

# Vérifier les formats YAML des prompts
$promptFiles = $allFiles | Where-Object { $_.FullName -like "*\prompts\modes\*" -and $_.Extension -eq ".md" }
foreach ($prompt in $promptFiles) {
    $content = Get-Content $prompt.FullName -Raw
    if ($content -notmatch '^---\s*\n.*title:\s*".*"\s*\n.*description:\s*".*"\s*\n.*behavior:') {
        $issues += "❌ Format YAML incorrect: $($prompt.Name)"
    }
}

# Vérifier les liens dans README
$readmeFiles = $allFiles | Where-Object { $_.Name -eq "README.md" }
foreach ($readme in $readmeFiles) {
    $content = Get-Content $readme.FullName -Raw
    $links = [regex]::Matches($content, '\[([^\]]+)\]\(([^)]+)\)')
    foreach ($link in $links) {
        $linkPath = $link.Groups[2].Value
        if ($linkPath -match '^[^#http].*\.md$') {  # Liens relatifs vers fichiers .md
            $fullLinkPath = Join-Path (Split-Path $readme.FullName) $linkPath
            if (-not (Test-Path $fullLinkPath)) {
                $issues += "❌ Lien brisé dans $($readme.Name): $linkPath"
            }
        }
    }
}

# Vérifier la cohérence des standards techniques
$techStandardFiles = @(
    "docs\project\README_EMAIL_SENDER_1.md",
    "docs\github\development-methodology.md",
    "docs\guides\standards\README.md"
)

$golangPriority = @()
foreach ($file in $techStandardFiles) {
    $fullPath = Join-Path $basePath $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        if ($content -match 'Golang.*1\.2[12]\+.*principal') {
            $golangPriority += "✅ $file"
        } else {
            $golangPriority += "❌ $file - Priorité Golang manquante"
        }
    }
}

# 5. RAPPORT FINAL
Write-Host "`n📊 RAPPORT FINAL" -ForegroundColor Cyan
Write-Host "=" * 40

Write-Host "`n🎯 Standards Techniques Golang:"
$golangPriority | ForEach-Object { Write-Host "  $_" }

Write-Host "`n🔍 Problèmes détectés: $($issues.Count)"
if ($issues.Count -gt 0) {
    $issues | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  ✅ Aucun problème détecté" -ForegroundColor Green
}

Write-Host "`n📈 Métriques de corrélation:"
Write-Host "  - Fichiers avec références: $($references.Count)"
Write-Host "  - Prompts standardisés: $($promptFiles.Count)"
Write-Host "  - Workflows actifs: $(($categories['Workflows'] | Where-Object { $_.Name -notlike "*.disabled" }).Count)"
Write-Host "  - Documentation complète: $($categories['Documentation'].Count)"

# 6. VALIDATION FRAMEWORK RAG
Write-Host "`n🚀 VALIDATION FRAMEWORK RAG" -ForegroundColor Green
$ragFiles = @(
    "docs\project\README_EMAIL_SENDER_1.md",
    "docs\guides\go\7-methodes-time-saving.md"
)

$ragValidation = @()
foreach ($file in $ragFiles) {
    $fullPath = Join-Path $basePath $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        if ($content -match '7.*Time-Saving.*Methods|Framework.*d.*automatisation') {
            $ragValidation += "✅ $file - Framework RAG présent"
        } else {
            $ragValidation += "❌ $file - Framework RAG manquant"
        }
    }
}

Write-Host "`n📋 Validation Framework RAG:"
$ragValidation | ForEach-Object { Write-Host "  $_" }

Write-Host "`n✅ ANALYSE TERMINÉE" -ForegroundColor Green