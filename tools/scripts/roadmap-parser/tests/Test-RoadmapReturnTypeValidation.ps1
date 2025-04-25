# Test-RoadmapReturnTypeValidation.ps1
# Script pour tester la fonction Test-RoadmapReturnType

# Importer les fonctions à tester
$returnTypeFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Test-RoadmapReturnType.ps1"
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
$exportFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"

. $returnTypeFunctionPath
. $dependenciesFunctionPath
if (Test-Path -Path $exportFunctionPath) {
    . $exportFunctionPath
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-return-types.md"
$testMarkdown = @"
# Roadmap de Test pour Types de Retour

Ceci est une roadmap de test pour valider la fonction Test-RoadmapReturnType.

## Section 1

- [ ] **TASK-1** Tâche 1
  - [x] **TASK-1.1** Tâche 1.1
  - [ ] **TASK-1.2** Tâche 1.2
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap pour les tests
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies

    # Test 1: Validation d'objet roadmap
    Write-Host "`nTest 1: Validation d'objet roadmap" -ForegroundColor Cyan
    $validRoadmap = $roadmap
    $invalidRoadmap = [PSCustomObject]@{
        Title       = "Invalid Roadmap"
        Description = "This is an invalid roadmap"
    }

    $validResult = Test-RoadmapReturnType -Value $validRoadmap -Type Roadmap
    $invalidResult = Test-RoadmapReturnType -Value $invalidRoadmap -Type Roadmap

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation d'objet roadmap fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation d'objet roadmap ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour roadmap valide: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour roadmap invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 2: Validation d'objet section
    Write-Host "`nTest 2: Validation d'objet section" -ForegroundColor Cyan
    $validSection = $roadmap.Sections[0]
    $invalidSection = [PSCustomObject]@{
        Title = "Invalid Section"
    }

    $validResult = Test-RoadmapReturnType -Value $validSection -Type Section
    $invalidResult = Test-RoadmapReturnType -Value $invalidSection -Type Section

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation d'objet section fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation d'objet section ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour section valide: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour section invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 3: Validation d'objet tâche
    Write-Host "`nTest 3: Validation d'objet tâche" -ForegroundColor Cyan
    $validTask = $roadmap.AllTasks["TASK-1"]
    $invalidTask = [PSCustomObject]@{
        Id    = "INVALID-1"
        Title = "Invalid Task"
    }

    $validResult = Test-RoadmapReturnType -Value $validTask -Type Task
    $invalidResult = Test-RoadmapReturnType -Value $invalidTask -Type Task

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation d'objet tâche fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation d'objet tâche ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour tâche valide: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour tâche invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 4: Validation d'objet résultat de validation
    Write-Host "`nTest 4: Validation d'objet résultat de validation" -ForegroundColor Cyan
    $validValidationResult = [PSCustomObject]@{
        IsValid  = $true
        Errors   = @()
        Warnings = @()
    }
    $invalidValidationResult = [PSCustomObject]@{
        IsValid = "Not a boolean"
        Errors  = "Not an array"
    }

    $validResult = Test-RoadmapReturnType -Value $validValidationResult -Type ValidationResult
    $invalidResult = Test-RoadmapReturnType -Value $invalidValidationResult -Type ValidationResult

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation d'objet résultat de validation fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation d'objet résultat de validation ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour résultat de validation valide: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour résultat de validation invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 5: Validation d'objet résultat de dépendance
    Write-Host "`nTest 5: Validation d'objet résultat de dépendance" -ForegroundColor Cyan
    $validDependencyResult = [PSCustomObject]@{
        DependencyCount      = 2
        ExplicitDependencies = @()
        ImplicitDependencies = @()
    }
    $invalidDependencyResult = [PSCustomObject]@{
        DependencyCount      = "Not an integer"
        ExplicitDependencies = "Not an array"
    }

    $validResult = Test-RoadmapReturnType -Value $validDependencyResult -Type DependencyResult
    $invalidResult = Test-RoadmapReturnType -Value $invalidDependencyResult -Type DependencyResult

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation d'objet résultat de dépendance fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation d'objet résultat de dépendance ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour résultat de dépendance valide: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour résultat de dépendance invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 6: Validation de chaîne JSON
    Write-Host "`nTest 6: Validation de chaîne JSON" -ForegroundColor Cyan
    $validJson = '{"name":"Test","value":42}'
    $invalidJson = '{"name":"Test","value":42'

    $validResult = Test-RoadmapReturnType -Value $validJson -Type JsonString
    $invalidResult = Test-RoadmapReturnType -Value $invalidJson -Type JsonString

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation de chaîne JSON fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation de chaîne JSON ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour JSON valide: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour JSON invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 7: Validation personnalisée
    Write-Host "`nTest 7: Validation personnalisée" -ForegroundColor Cyan
    $validValue = 42
    $invalidValue = "not a number"

    $customValidation = {
        param($value)
        return $value -is [int]
    }

    $validResult = Test-RoadmapReturnType -Value $validValue -Type Custom -CustomValidation $customValidation
    $invalidResult = Test-RoadmapReturnType -Value $invalidValue -Type Custom -CustomValidation $customValidation

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation personnalisée fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation personnalisée ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour valeur valide: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour valeur invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 8: Validation avec propriétés requises personnalisées
    Write-Host "`nTest 8: Validation avec propriétés requises personnalisées" -ForegroundColor Cyan
    $customObject = [PSCustomObject]@{
        Name      = "Custom Object"
        Value     = 42
        IsEnabled = $true
    }

    Write-Host "  Objet de test:" -ForegroundColor Yellow
    Write-Host "    - Name = $($customObject.Name)" -ForegroundColor Yellow
    Write-Host "    - Value = $($customObject.Value)" -ForegroundColor Yellow
    Write-Host "    - IsEnabled = $($customObject.IsEnabled)" -ForegroundColor Yellow

    Write-Host "  Test avec propriétés valides (Name, Value, IsEnabled):" -ForegroundColor Yellow
    $validResult = Test-RoadmapReturnType -Value $customObject -Type Custom -CustomValidation { $true } -RequiredProperties @("Name", "Value", "IsEnabled")
    Write-Host "    Résultat: $validResult" -ForegroundColor Yellow

    Write-Host "  Test avec propriétés invalides (Name, Value, Missing):" -ForegroundColor Yellow
    $invalidResult = $null
    $warningMessage = $null
    $previousWarningAction = $WarningPreference
    $WarningPreference = 'Continue'
    $warningVar = New-Object -TypeName System.Collections.ArrayList

    # Rediriger les avertissements vers une variable
    $invalidResult = Test-RoadmapReturnType -Value $customObject -Type Custom -CustomValidation { $true } -RequiredProperties @("Name", "Value", "Missing") -WarningAction SilentlyContinue -WarningVariable +warningVar

    $WarningPreference = $previousWarningAction

    if ($warningVar.Count -gt 0) {
        $warningMessage = $warningVar[0]
    }

    Write-Host "    Résultat: $invalidResult" -ForegroundColor Yellow
    Write-Host "    Avertissement: $warningMessage" -ForegroundColor Yellow

    if ($validResult -and -not $invalidResult) {
        Write-Host "✓ Validation avec propriétés requises personnalisées fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation avec propriétés requises personnalisées ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Résultat pour propriétés valides: $validResult" -ForegroundColor Red
        Write-Host "  Résultat pour propriétés invalides: $invalidResult" -ForegroundColor Red
    }

    # Test 9: Validation avec ThrowOnFailure
    Write-Host "`nTest 9: Validation avec ThrowOnFailure" -ForegroundColor Cyan
    $exceptionThrown = $false

    try {
        Test-RoadmapReturnType -Value $invalidRoadmap -Type Roadmap -ThrowOnFailure
    } catch {
        $exceptionThrown = $true
        Write-Host "  Exception: $_" -ForegroundColor Yellow
    }

    if ($exceptionThrown) {
        Write-Host "✓ Validation avec ThrowOnFailure fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Validation avec ThrowOnFailure ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Aucune exception n'a été levée" -ForegroundColor Red
    }

    # Test 10: Validation avec Export-RoadmapToJson (si disponible)
    if (Test-Path -Path $exportFunctionPath) {
        Write-Host "`nTest 10: Validation avec Export-RoadmapToJson" -ForegroundColor Cyan
        $json = Export-RoadmapToJson -Roadmap $roadmap

        $validResult = Test-RoadmapReturnType -Value $json -Type JsonString

        if ($validResult) {
            Write-Host "✓ Validation avec Export-RoadmapToJson fonctionne correctement" -ForegroundColor Green
        } else {
            Write-Host "✗ Validation avec Export-RoadmapToJson ne fonctionne pas correctement" -ForegroundColor Red
            Write-Host "  Résultat pour JSON exporté: $validResult" -ForegroundColor Red
        }
    } else {
        Write-Host "`nTest 10: Validation avec Export-RoadmapToJson (ignoré - fonction non disponible)" -ForegroundColor Gray
    }

    Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
