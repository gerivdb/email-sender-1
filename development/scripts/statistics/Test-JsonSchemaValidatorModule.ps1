# Test-JsonSchemaValidatorModule.ps1
# Ce script teste le module JsonSchemaValidator

# Importer le module JsonSchemaValidator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "JsonSchemaValidator.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module JsonSchemaValidator.psm1 n'a pas été trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Définir les chemins des fichiers
$schemasFolder = Join-Path -Path $PSScriptRoot -ChildPath "schemas"
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
$docsFolder = Join-Path -Path $PSScriptRoot -ChildPath "docs"

# Créer les dossiers s'ils n'existent pas
if (-not (Test-Path -Path $schemasFolder)) {
    New-Item -Path $schemasFolder -ItemType Directory | Out-Null
}

if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

if (-not (Test-Path -Path $docsFolder)) {
    New-Item -Path $docsFolder -ItemType Directory | Out-Null
}

# Définir les chemins des fichiers de test
$schemaPath = Join-Path -Path $schemasFolder -ChildPath "AsymmetryReportSchema.json"
$validJsonPath = Join-Path -Path $reportsFolder -ChildPath "normal_report.json"
$invalidJsonPath = Join-Path -Path $reportsFolder -ChildPath "invalid_report.json"
$schemaDocPath = Join-Path -Path $docsFolder -ChildPath "AsymmetryReportSchema.html"

# Vérifier que le fichier de schéma existe
if (-not (Test-Path -Path $schemaPath)) {
    Write-Error "Le fichier de schéma n'existe pas: $schemaPath"
    exit 1
}

# Vérifier que le fichier JSON valide existe
if (-not (Test-Path -Path $validJsonPath)) {
    Write-Error "Le fichier JSON valide n'existe pas: $validJsonPath"
    exit 1
}

# Créer un fichier JSON invalide pour les tests
$invalidJson = @"
{
    "metadata": {
        "title": "Rapport d'analyse d'asymétrie",
        "generationDate": "2025-05-08T06:16:47Z"
        // Manque "version" et "sampleSize" qui sont requis
    },
    "summary": {
        "asymmetryDirection": "Symétrique",
        "asymmetryIntensity": "Négligeable",
        "compositeScore": 0.0345,
        "consistencyScore": 0.979
        // Manque "recommendedMethod" qui est requis
    },
    // Manque "statistics" qui est requis
    "methods": {
        "slope": {
            "slopeRatio": 1.0699,
            "leftSlope": 10.9573,
            "rightSlope": 11.7232,
            "asymmetryDirection": "Queue droite plus pentue",
            "asymmetryIntensity": "Négligeable",
            "score": 0.0999
        }
    },
    "recommendations": [
        "Le score composite d'asymétrie de 0.03 indique une distribution symétrique avec une asymétrie de niveau 'négligeable'."
    ]
}
"@

$invalidJson | Out-File -FilePath $invalidJsonPath -Encoding UTF8

# Test 1: Validation d'un fichier JSON valide
Write-Host "`n=== Test 1: Validation d'un fichier JSON valide ===" -ForegroundColor Magenta
$validResult = Test-JsonSchema -JsonPath $validJsonPath -SchemaPath $schemaPath -Detailed
Write-Host "Résultat de la validation: $($validResult.IsValid)" -ForegroundColor $(if ($validResult.IsValid) { "Green" } else { "Red" })
if (-not $validResult.IsValid) {
    Write-Host "Erreurs:" -ForegroundColor Red
    foreach ($error in $validResult.Errors) {
        Write-Host "- $error" -ForegroundColor Red
    }
}

# Test 2: Validation d'un fichier JSON invalide
Write-Host "`n=== Test 2: Validation d'un fichier JSON invalide ===" -ForegroundColor Magenta
$invalidResult = Test-JsonSchema -JsonPath $invalidJsonPath -SchemaPath $schemaPath -Detailed
Write-Host "Résultat de la validation: $($invalidResult.IsValid)" -ForegroundColor $(if ($invalidResult.IsValid) { "Green" } else { "Red" })
if (-not $invalidResult.IsValid) {
    Write-Host "Erreurs:" -ForegroundColor Red
    foreach ($error in $invalidResult.Errors) {
        Write-Host "- $error" -ForegroundColor Red
    }
}

# Test 3: Validation avec contenu direct
Write-Host "`n=== Test 3: Validation avec contenu direct ===" -ForegroundColor Magenta
$jsonContent = Get-Content -Path $validJsonPath -Raw -Encoding UTF8
$schemaContent = Get-Content -Path $schemaPath -Raw -Encoding UTF8
$contentResult = Test-JsonSchema -JsonContent $jsonContent -SchemaContent $schemaContent
Write-Host "Résultat de la validation: $contentResult" -ForegroundColor $(if ($contentResult) { "Green" } else { "Red" })

# Test 4: Génération de documentation HTML
Write-Host "`n=== Test 4: Génération de documentation HTML ===" -ForegroundColor Magenta
$docResult = New-JsonSchemaDocumentation -SchemaPath $schemaPath -OutputPath $schemaDocPath -Title "Documentation du schéma de rapport d'asymétrie"
if ($docResult) {
    Write-Host "Documentation HTML générée avec succès: $schemaDocPath" -ForegroundColor Green
    Write-Host "Taille de la documentation: $((Get-Item -Path $schemaDocPath).Length) octets" -ForegroundColor White
    
    # Ouvrir la documentation dans le navigateur par défaut
    Write-Host "Ouverture de la documentation dans le navigateur..." -ForegroundColor White
    Start-Process $schemaDocPath
} else {
    Write-Host "Échec de la génération de la documentation HTML." -ForegroundColor Red
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
$testsPassed = 0
$testsTotal = 4

if ($validResult.IsValid) { $testsPassed++ }
if (-not $invalidResult.IsValid) { $testsPassed++ }
if ($contentResult) { $testsPassed++ }
if ($docResult) { $testsPassed++ }

Write-Host "$testsPassed/$testsTotal tests réussis." -ForegroundColor $(if ($testsPassed -eq $testsTotal) { "Green" } else { "Yellow" })
if ($testsPassed -eq $testsTotal) {
    Write-Host "Le module JsonSchemaValidator fonctionne correctement." -ForegroundColor Green
} else {
    Write-Host "Certains tests ont échoué. Vérifiez les erreurs ci-dessus." -ForegroundColor Yellow
}

Write-Host "Documentation HTML générée dans: $schemaDocPath" -ForegroundColor Green
