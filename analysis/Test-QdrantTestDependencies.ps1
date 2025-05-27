# Test-QdrantTestDependencies.ps1
# Script d'analyse des dépendances entre tests QDrant
# Version: 1.0
# Date: 2025-05-27

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportResults
)

# Structure pour stocker les résultats d'analyse
$AnalysisResults = @{
    GoTests = @()
    PowerShellTests = @()
    PythonTests = @()
    Dependencies = @()
    SharedComponents = @()
    Recommendations = @()
}

function Analyze-GoTests {
    [CmdletBinding()]
    param ([string]$RootPath)
    
    Write-Host "🔍 Analyse des tests Go..." -ForegroundColor Yellow
    
    $goTestFiles = Get-ChildItem -Path $RootPath -Recurse -Filter "*test*.go" | Where-Object { 
        $_.Name -like "*test.go" 
    }
    
    foreach ($file in $goTestFiles) {
        $content = Get-Content $file.FullName -Raw
        $testInfo = @{
            File = $file.FullName.Replace($RootPath, "")
            Type = "Go"
            UsesQdrant = $false
            UsesHTTP = $false
            UsesMocks = $false
            RequiresLiveQdrant = $false
            Dependencies = @()
        }
        
        # Analyser le contenu pour détecter l'usage QDrant
        if ($content -match "qdrant|Qdrant") {
            $testInfo.UsesQdrant = $true
        }
        
        if ($content -match "http\.Client|RestMethod|localhost:6333") {
            $testInfo.UsesHTTP = $true
        }
        
        if ($content -match "httptest|mock|Mock") {
            $testInfo.UsesMocks = $true
        }
        
        if ($content -match "localhost:6333" -and $content -notmatch "mock|Mock") {
            $testInfo.RequiresLiveQdrant = $true
        }
          # Détecter les imports et dépendances
        $imports = [System.Text.RegularExpressions.Regex]::Matches($content, 'import.*?"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        $testInfo.Dependencies = $imports | Where-Object { $_ -like "*qdrant*" -or $_ -like "*http*" }
        
        $AnalysisResults.GoTests += $testInfo
    }
    
    Write-Host "✅ Trouvé $($goTestFiles.Count) tests Go" -ForegroundColor Green
}

function Analyze-PowerShellTests {
    [CmdletBinding()]
    param ([string]$RootPath)
    
    Write-Host "🔍 Analyse des tests PowerShell..." -ForegroundColor Yellow
    
    $psTestFiles = Get-ChildItem -Path $RootPath -Recurse -Filter "*Test*.ps1"
    
    foreach ($file in $psTestFiles) {
        $content = Get-Content $file.FullName -Raw
        $testInfo = @{
            File = $file.FullName.Replace($RootPath, "")
            Type = "PowerShell"
            UsesQdrant = $false
            UsesHTTP = $false
            UsesMocks = $false
            RequiresLiveQdrant = $false
            Dependencies = @()
        }
        
        # Analyser le contenu pour détecter l'usage QDrant
        if ($content -match "qdrant|Qdrant|6333") {
            $testInfo.UsesQdrant = $true
        }
        
        if ($content -match "Invoke-RestMethod|Invoke-WebRequest|http://") {
            $testInfo.UsesHTTP = $true
        }
        
        if ($content -match "Mock|mock|Test-") {
            $testInfo.UsesMocks = $true
        }
        
        if ($content -match "localhost:6333|http://.*:6333" -and $content -notmatch "Mock") {
            $testInfo.RequiresLiveQdrant = $true
        }
        
        $AnalysisResults.PowerShellTests += $testInfo
    }
    
    Write-Host "✅ Trouvé $($psTestFiles.Count) tests PowerShell" -ForegroundColor Green
}

function Analyze-PythonTests {
    [CmdletBinding()]
    param ([string]$RootPath)
    
    Write-Host "🔍 Analyse des tests Python..." -ForegroundColor Yellow
    
    $pyTestFiles = Get-ChildItem -Path $RootPath -Recurse -Filter "*test*.py"
    
    foreach ($file in $pyTestFiles) {
        $content = Get-Content $file.FullName -Raw
        $testInfo = @{
            File = $file.FullName.Replace($RootPath, "")
            Type = "Python"
            UsesQdrant = $false
            UsesHTTP = $false
            UsesMocks = $false
            RequiresLiveQdrant = $false
            Dependencies = @()
        }
        
        # Analyser le contenu pour détecter l'usage QDrant
        if ($content -match "qdrant|Qdrant|QdrantClient") {
            $testInfo.UsesQdrant = $true
        }
        
        if ($content -match "requests\.|http|HTTP") {
            $testInfo.UsesHTTP = $true
        }
        
        if ($content -match "mock|Mock|MagicMock") {
            $testInfo.UsesMocks = $true
        }
        
        if ($content -match "localhost.*6333" -and $content -notmatch "mock") {
            $testInfo.RequiresLiveQdrant = $true
        }
        
        $AnalysisResults.PythonTests += $testInfo
    }
    
    Write-Host "✅ Trouvé $($pyTestFiles.Count) tests Python" -ForegroundColor Green
}

function Analyze-SharedComponents {
    Write-Host "🔍 Analyse des composants partagés..." -ForegroundColor Yellow
    
    $sharedComponents = @(
        @{ Name = "QdrantClient Go"; Path = "src/qdrant/qdrant.go"; Type = "Client" }
        @{ Name = "RAG QdrantClient"; Path = "development/tools/qdrant/rag-go/pkg/client/client.go"; Type = "Client" }
        @{ Name = "Python QdrantClient"; Path = "development/scripts/mcp/vector_storage.py"; Type = "Client" }
        @{ Name = "Integration Test Suite"; Path = "src/indexing/integration_test.go"; Type = "Framework" }
    )
    
    $AnalysisResults.SharedComponents = $sharedComponents
}

function Generate-DependencyMatrix {
    Write-Host "📊 Génération de la matrice des dépendances..." -ForegroundColor Yellow
    
    # Créer la matrice des dépendances
    $allTests = $AnalysisResults.GoTests + $AnalysisResults.PowerShellTests + $AnalysisResults.PythonTests
    
    $dependencyMatrix = @()
    
    foreach ($test in $allTests) {
        if ($test.UsesQdrant) {
            $dependency = @{
                TestFile = $test.File
                Type = $test.Type
                RequiresQdrant = $test.RequiresLiveQdrant
                UsesMocks = $test.UsesMocks
                UsesHTTP = $test.UsesHTTP
                RiskLevel = if ($test.RequiresLiveQdrant -and -not $test.UsesMocks) { "High" } 
                           elseif ($test.UsesQdrant -and $test.UsesMocks) { "Low" } 
                           else { "Medium" }
            }
            $dependencyMatrix += $dependency
        }
    }
    
    $AnalysisResults.Dependencies = $dependencyMatrix
}

function Generate-Recommendations {
    Write-Host "💡 Génération des recommandations..." -ForegroundColor Yellow
    
    $highRiskTests = $AnalysisResults.Dependencies | Where-Object { $_.RiskLevel -eq "High" }
    $mockTests = $AnalysisResults.Dependencies | Where-Object { $_.UsesMocks }
    
    $recommendations = @()
    
    if ($highRiskTests.Count -gt 0) {
        $recommendations += "⚠️ $($highRiskTests.Count) tests nécessitent une instance QDrant live - risque de flakiness"
        $recommendations += "🔧 Recommandation: Ajouter des mocks HTTP pour tests unitaires"
    }
    
    if ($mockTests.Count -lt 5) {
        $recommendations += "📈 Seulement $($mockTests.Count) tests utilisent des mocks - augmenter la couverture"
    }
    
    $recommendations += "✅ Privilégier les tests avec mocks pour la CI/CD"
    $recommendations += "🎯 Séparer tests unitaires (mocks) et tests d'intégration (live QDrant)"
    $recommendations += "🐳 Utiliser Docker Compose pour environnement de test isolé"
    
    $AnalysisResults.Recommendations = $recommendations
}

function Export-Results {
    if ($ExportResults) {
        $outputPath = Join-Path $ProjectRoot "analysis\qdrant-test-dependencies.json"
        $AnalysisResults | ConvertTo-Json -Depth 5 | Out-File $outputPath -Encoding UTF8
        Write-Host "📄 Résultats exportés vers: $outputPath" -ForegroundColor Green
    }
}

function Show-Summary {
    Write-Host "`n📋 RÉSUMÉ DE L'ANALYSE DES DÉPENDANCES QDRANT" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    $totalTests = $AnalysisResults.GoTests.Count + $AnalysisResults.PowerShellTests.Count + $AnalysisResults.PythonTests.Count
    $qdrantTests = $AnalysisResults.Dependencies.Count
    $highRiskTests = ($AnalysisResults.Dependencies | Where-Object { $_.RiskLevel -eq "High" }).Count
    $mockTests = ($AnalysisResults.Dependencies | Where-Object { $_.UsesMocks }).Count
    
    Write-Host "📊 Statistiques globales:" -ForegroundColor White
    Write-Host "  • Total des tests analysés: $totalTests" -ForegroundColor Gray
    Write-Host "  • Tests utilisant QDrant: $qdrantTests" -ForegroundColor Gray
    Write-Host "  • Tests à risque élevé: $highRiskTests" -ForegroundColor $(if($highRiskTests -gt 5) { "Red" } else { "Yellow" })
    Write-Host "  • Tests avec mocks: $mockTests" -ForegroundColor Green
    
    Write-Host "`n🔧 Répartition par type:" -ForegroundColor White
    Write-Host "  • Tests Go: $($AnalysisResults.GoTests.Count)" -ForegroundColor Gray
    Write-Host "  • Tests PowerShell: $($AnalysisResults.PowerShellTests.Count)" -ForegroundColor Gray
    Write-Host "  • Tests Python: $($AnalysisResults.PythonTests.Count)" -ForegroundColor Gray
    
    if ($Detailed) {
        Write-Host "`n⚠️ Tests nécessitant QDrant live:" -ForegroundColor Red
        $AnalysisResults.Dependencies | Where-Object { $_.RequiresQdrant } | ForEach-Object {
            Write-Host "  • $($_.TestFile) ($($_.Type))" -ForegroundColor Gray
        }
        
        Write-Host "`n✅ Tests avec mocks:" -ForegroundColor Green
        $AnalysisResults.Dependencies | Where-Object { $_.UsesMocks } | ForEach-Object {
            Write-Host "  • $($_.TestFile) ($($_.Type))" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n💡 Recommandations:" -ForegroundColor White
    $AnalysisResults.Recommendations | ForEach-Object {
        Write-Host "  $($_)" -ForegroundColor Gray
    }
    
    Write-Host "`n" -ForegroundColor White
}

# Exécution principale
try {
    Write-Host "🚀 Démarrage de l'analyse des dépendances QDrant..." -ForegroundColor Cyan
    
    if (-not (Test-Path $ProjectRoot)) {
        throw "Chemin du projet non trouvé: $ProjectRoot"
    }
    
    # Analyser chaque type de test
    Analyze-GoTests -RootPath $ProjectRoot
    Analyze-PowerShellTests -RootPath $ProjectRoot
    Analyze-PythonTests -RootPath $ProjectRoot
    
    # Analyser les composants partagés
    Analyze-SharedComponents
    
    # Générer la matrice des dépendances
    Generate-DependencyMatrix
    
    # Générer les recommandations
    Generate-Recommendations
    
    # Exporter si demandé
    Export-Results
    
    # Afficher le résumé
    Show-Summary
    
    Write-Host "✅ Analyse terminée avec succès!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erreur lors de l'analyse: $_" -ForegroundColor Red
    exit 1
}
