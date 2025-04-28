# Test-RoadmapReturnTypeValidation.ps1
# Script pour tester la fonction Test-RoadmapReturnType

# Importer les fonctions Ã  tester
$returnTypeFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Test-RoadmapReturnType.ps1"
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
$exportFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"

. $returnTypeFunctionPath
. $dependenciesFunctionPath
if (Test-Path -Path $exportFunctionPath) {
    . $exportFunctionPath
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-return-types.md"
$testMarkdown = @"
# Roadmap de Test pour Types de Retour

Ceci est une roadmap de test pour valider la fonction Test-RoadmapReturnType.

## Section 1

- [ ] **TASK-1** TÃ¢che 1
  - [x] **TASK-1.1** TÃ¢che 1.1
  - [ ] **TASK-1.2** TÃ¢che 1.2
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

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
        Write-Host "âœ“ Validation d'objet roadmap fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation d'objet roadmap ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour roadmap valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour roadmap invalide: $invalidResult" -ForegroundColor Red
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
        Write-Host "âœ“ Validation d'objet section fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation d'objet section ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour section valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour section invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 3: Validation d'objet tÃ¢che
    Write-Host "`nTest 3: Validation d'objet tÃ¢che" -ForegroundColor Cyan
    $validTask = $roadmap.AllTasks["TASK-1"]
    $invalidTask = [PSCustomObject]@{
        Id    = "INVALID-1"
        Title = "Invalid Task"
    }

    $validResult = Test-RoadmapReturnType -Value $validTask -Type Task
    $invalidResult = Test-RoadmapReturnType -Value $invalidTask -Type Task

    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation d'objet tÃ¢che fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation d'objet tÃ¢che ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour tÃ¢che valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour tÃ¢che invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 4: Validation d'objet rÃ©sultat de validation
    Write-Host "`nTest 4: Validation d'objet rÃ©sultat de validation" -ForegroundColor Cyan
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
        Write-Host "âœ“ Validation d'objet rÃ©sultat de validation fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation d'objet rÃ©sultat de validation ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour rÃ©sultat de validation valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour rÃ©sultat de validation invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 5: Validation d'objet rÃ©sultat de dÃ©pendance
    Write-Host "`nTest 5: Validation d'objet rÃ©sultat de dÃ©pendance" -ForegroundColor Cyan
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
        Write-Host "âœ“ Validation d'objet rÃ©sultat de dÃ©pendance fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation d'objet rÃ©sultat de dÃ©pendance ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour rÃ©sultat de dÃ©pendance valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour rÃ©sultat de dÃ©pendance invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 6: Validation de chaÃ®ne JSON
    Write-Host "`nTest 6: Validation de chaÃ®ne JSON" -ForegroundColor Cyan
    $validJson = '{"name":"Test","value":42}'
    $invalidJson = '{"name":"Test","value":42'

    $validResult = Test-RoadmapReturnType -Value $validJson -Type JsonString
    $invalidResult = Test-RoadmapReturnType -Value $invalidJson -Type JsonString

    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation de chaÃ®ne JSON fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation de chaÃ®ne JSON ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour JSON valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour JSON invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 7: Validation personnalisÃ©e
    Write-Host "`nTest 7: Validation personnalisÃ©e" -ForegroundColor Cyan
    $validValue = 42
    $invalidValue = "not a number"

    $customValidation = {
        param($value)
        return $value -is [int]
    }

    $validResult = Test-RoadmapReturnType -Value $validValue -Type Custom -CustomValidation $customValidation
    $invalidResult = Test-RoadmapReturnType -Value $invalidValue -Type Custom -CustomValidation $customValidation

    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation personnalisÃ©e fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation personnalisÃ©e ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour valeur valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour valeur invalide: $invalidResult" -ForegroundColor Red
    }

    # Test 8: Validation avec propriÃ©tÃ©s requises personnalisÃ©es
    Write-Host "`nTest 8: Validation avec propriÃ©tÃ©s requises personnalisÃ©es" -ForegroundColor Cyan
    $customObject = [PSCustomObject]@{
        Name      = "Custom Object"
        Value     = 42
        IsEnabled = $true
    }

    Write-Host "  Objet de test:" -ForegroundColor Yellow
    Write-Host "    - Name = $($customObject.Name)" -ForegroundColor Yellow
    Write-Host "    - Value = $($customObject.Value)" -ForegroundColor Yellow
    Write-Host "    - IsEnabled = $($customObject.IsEnabled)" -ForegroundColor Yellow

    Write-Host "  Test avec propriÃ©tÃ©s valides (Name, Value, IsEnabled):" -ForegroundColor Yellow
    $validResult = Test-RoadmapReturnType -Value $customObject -Type Custom -CustomValidation { $true } -RequiredProperties @("Name", "Value", "IsEnabled")
    Write-Host "    RÃ©sultat: $validResult" -ForegroundColor Yellow

    Write-Host "  Test avec propriÃ©tÃ©s invalides (Name, Value, Missing):" -ForegroundColor Yellow
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

    Write-Host "    RÃ©sultat: $invalidResult" -ForegroundColor Yellow
    Write-Host "    Avertissement: $warningMessage" -ForegroundColor Yellow

    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation avec propriÃ©tÃ©s requises personnalisÃ©es fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation avec propriÃ©tÃ©s requises personnalisÃ©es ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour propriÃ©tÃ©s valides: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour propriÃ©tÃ©s invalides: $invalidResult" -ForegroundColor Red
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
        Write-Host "âœ“ Validation avec ThrowOnFailure fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation avec ThrowOnFailure ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Aucune exception n'a Ã©tÃ© levÃ©e" -ForegroundColor Red
    }

    # Test 10: Validation avec Export-RoadmapToJson (si disponible)
    if (Test-Path -Path $exportFunctionPath) {
        Write-Host "`nTest 10: Validation avec Export-RoadmapToJson" -ForegroundColor Cyan
        $json = Export-RoadmapToJson -Roadmap $roadmap

        $validResult = Test-RoadmapReturnType -Value $json -Type JsonString

        if ($validResult) {
            Write-Host "âœ“ Validation avec Export-RoadmapToJson fonctionne correctement" -ForegroundColor Green
        } else {
            Write-Host "âœ— Validation avec Export-RoadmapToJson ne fonctionne pas correctement" -ForegroundColor Red
            Write-Host "  RÃ©sultat pour JSON exportÃ©: $validResult" -ForegroundColor Red
        }
    } else {
        Write-Host "`nTest 10: Validation avec Export-RoadmapToJson (ignorÃ© - fonction non disponible)" -ForegroundColor Gray
    }

    Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
