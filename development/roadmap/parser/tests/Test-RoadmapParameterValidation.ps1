# Test-RoadmapParameterValidation.ps1
# Script pour tester les fonctions de validation de paramÃ¨tres

# Importer les fonctions Ã  tester
$testParameterPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Test-RoadmapParameter.ps1"
$getDefaultPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Get-RoadmapParameterDefault.ps1"
$initializeParamsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Initialize-RoadmapParameters.ps1"
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"

. $testParameterPath
. $getDefaultPath
. $initializeParamsPath
. $dependenciesFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-params.md"
$testMarkdown = @"
# Roadmap de Test pour ParamÃ¨tres

Ceci est une roadmap de test pour valider les fonctions de validation de paramÃ¨tres.

## Section 1

- [ ] **TASK-1** TÃ¢che 1
  - [x] **TASK-1.1** TÃ¢che 1.1
  - [ ] **TASK-1.2** TÃ¢che 1.2
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

# CrÃ©er un fichier de configuration personnalisÃ©e
$configPath = Join-Path -Path $testDir -ChildPath "custom-config.json"
$configContent = @"
{
    "ConvertFrom-MarkdownToRoadmapOptimized": {
        "BlockSize": 500
    },
    "Select-RoadmapTask": {
        "Status": "Incomplete"
    }
}
"@

$configContent | Out-File -FilePath $configPath -Encoding UTF8

Write-Host "Fichiers de test crÃ©Ã©s." -ForegroundColor Green

try {
    # Convertir le markdown en roadmap pour les tests
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Test 1: Validation de chemin de fichier
    Write-Host "`nTest 1: Validation de chemin de fichier" -ForegroundColor Cyan
    $validFilePath = $testMarkdownPath
    $invalidFilePath = Join-Path -Path $testDir -ChildPath "non-existent.md"
    
    $validResult = Test-RoadmapParameter -Value $validFilePath -Type FilePath
    $invalidResult = Test-RoadmapParameter -Value $invalidFilePath -Type FilePath
    
    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation de chemin de fichier fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation de chemin de fichier ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour chemin valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour chemin invalide: $invalidResult" -ForegroundColor Red
    }
    
    # Test 2: Validation d'objet roadmap
    Write-Host "`nTest 2: Validation d'objet roadmap" -ForegroundColor Cyan
    $validRoadmap = $roadmap
    $invalidRoadmap = @{ Title = "Invalid Roadmap" }
    
    $validResult = Test-RoadmapParameter -Value $validRoadmap -Type RoadmapObject
    $invalidResult = Test-RoadmapParameter -Value $invalidRoadmap -Type RoadmapObject
    
    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation d'objet roadmap fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation d'objet roadmap ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour roadmap valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour roadmap invalide: $invalidResult" -ForegroundColor Red
    }
    
    # Test 3: Validation d'identifiant de tÃ¢che
    Write-Host "`nTest 3: Validation d'identifiant de tÃ¢che" -ForegroundColor Cyan
    $validTaskId = "TASK-1"
    $invalidTaskId = "NON-EXISTENT"
    
    $validResult = Test-RoadmapParameter -Value $validTaskId -Type TaskId -Roadmap $roadmap
    $invalidResult = Test-RoadmapParameter -Value $invalidTaskId -Type TaskId -Roadmap $roadmap
    
    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation d'identifiant de tÃ¢che fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation d'identifiant de tÃ¢che ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour ID valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour ID invalide: $invalidResult" -ForegroundColor Red
    }
    
    # Test 4: Validation de statut
    Write-Host "`nTest 4: Validation de statut" -ForegroundColor Cyan
    $validStatus = "Complete"
    $invalidStatus = "Invalid"
    
    $validResult = Test-RoadmapParameter -Value $validStatus -Type Status
    $invalidResult = Test-RoadmapParameter -Value $invalidStatus -Type Status
    
    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation de statut fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation de statut ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour statut valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour statut invalide: $invalidResult" -ForegroundColor Red
    }
    
    # Test 5: Validation personnalisÃ©e
    Write-Host "`nTest 5: Validation personnalisÃ©e" -ForegroundColor Cyan
    $validValue = 42
    $invalidValue = "not a number"
    
    $customValidation = {
        param($value)
        return $value -is [int]
    }
    
    $validResult = Test-RoadmapParameter -Value $validValue -Type Custom -CustomValidation $customValidation
    $invalidResult = Test-RoadmapParameter -Value $invalidValue -Type Custom -CustomValidation $customValidation
    
    if ($validResult -and -not $invalidResult) {
        Write-Host "âœ“ Validation personnalisÃ©e fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— Validation personnalisÃ©e ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour valeur valide: $validResult" -ForegroundColor Red
        Write-Host "  RÃ©sultat pour valeur invalide: $invalidResult" -ForegroundColor Red
    }
    
    # Test 6: RÃ©cupÃ©ration de valeur par dÃ©faut
    Write-Host "`nTest 6: RÃ©cupÃ©ration de valeur par dÃ©faut" -ForegroundColor Cyan
    $defaultBlockSize = Get-RoadmapParameterDefault -ParameterName "BlockSize" -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized"
    $defaultStatus = Get-RoadmapParameterDefault -ParameterName "Status" -FunctionName "Select-RoadmapTask"
    
    if ($defaultBlockSize -eq 1000 -and $defaultStatus -eq "All") {
        Write-Host "âœ“ RÃ©cupÃ©ration de valeur par dÃ©faut fonctionne correctement" -ForegroundColor Green
        Write-Host "  BlockSize par dÃ©faut: $defaultBlockSize" -ForegroundColor Yellow
        Write-Host "  Status par dÃ©faut: $defaultStatus" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— RÃ©cupÃ©ration de valeur par dÃ©faut ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  BlockSize par dÃ©faut: $defaultBlockSize (attendu: 1000)" -ForegroundColor Red
        Write-Host "  Status par dÃ©faut: $defaultStatus (attendu: All)" -ForegroundColor Red
    }
    
    # Test 7: RÃ©cupÃ©ration de valeur par dÃ©faut personnalisÃ©e
    Write-Host "`nTest 7: RÃ©cupÃ©ration de valeur par dÃ©faut personnalisÃ©e" -ForegroundColor Cyan
    $customBlockSize = Get-RoadmapParameterDefault -ParameterName "BlockSize" -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -ConfigurationPath $configPath
    $customStatus = Get-RoadmapParameterDefault -ParameterName "Status" -FunctionName "Select-RoadmapTask" -ConfigurationPath $configPath
    
    if ($customBlockSize -eq 500 -and $customStatus -eq "Incomplete") {
        Write-Host "âœ“ RÃ©cupÃ©ration de valeur par dÃ©faut personnalisÃ©e fonctionne correctement" -ForegroundColor Green
        Write-Host "  BlockSize personnalisÃ©: $customBlockSize" -ForegroundColor Yellow
        Write-Host "  Status personnalisÃ©: $customStatus" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— RÃ©cupÃ©ration de valeur par dÃ©faut personnalisÃ©e ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  BlockSize personnalisÃ©: $customBlockSize (attendu: 500)" -ForegroundColor Red
        Write-Host "  Status personnalisÃ©: $customStatus (attendu: Incomplete)" -ForegroundColor Red
    }
    
    # Test 8: Initialisation et validation de paramÃ¨tres
    Write-Host "`nTest 8: Initialisation et validation de paramÃ¨tres" -ForegroundColor Cyan
    $params = @{
        FilePath = $testMarkdownPath
        IncludeMetadata = $true
    }
    
    $validationRules = @{
        FilePath = @{
            Type = "FilePath"
            ThrowOnFailure = $true
        }
        IncludeMetadata = @{
            Type = "Custom"
            CustomValidation = { param($value) $value -is [bool] }
        }
        DetectDependencies = @{
            Type = "Custom"
            CustomValidation = { param($value) $value -is [bool] }
        }
    }
    
    $initializedParams = Initialize-RoadmapParameters -Parameters $params -FunctionName "ConvertFrom-MarkdownToRoadmapExtended" -ValidationRules $validationRules
    
    if ($initializedParams.ContainsKey("FilePath") -and 
        $initializedParams.ContainsKey("IncludeMetadata") -and 
        $initializedParams.ContainsKey("DetectDependencies") -and 
        $initializedParams["FilePath"] -eq $testMarkdownPath -and 
        $initializedParams["IncludeMetadata"] -eq $true -and 
        $initializedParams["DetectDependencies"] -eq $false) {
        Write-Host "âœ“ Initialisation et validation de paramÃ¨tres fonctionne correctement" -ForegroundColor Green
        Write-Host "  ParamÃ¨tres initialisÃ©s:" -ForegroundColor Yellow
        foreach ($key in $initializedParams.Keys) {
            Write-Host "    - $key = $($initializedParams[$key])" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âœ— Initialisation et validation de paramÃ¨tres ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  ParamÃ¨tres initialisÃ©s:" -ForegroundColor Red
        foreach ($key in $initializedParams.Keys) {
            Write-Host "    - $key = $($initializedParams[$key])" -ForegroundColor Red
        }
    }
    
    # Test 9: Initialisation et validation de paramÃ¨tres avec configuration personnalisÃ©e
    Write-Host "`nTest 9: Initialisation et validation de paramÃ¨tres avec configuration personnalisÃ©e" -ForegroundColor Cyan
    $params = @{
        FilePath = $testMarkdownPath
    }
    
    $validationRules = @{
        FilePath = @{
            Type = "FilePath"
            ThrowOnFailure = $true
        }
        BlockSize = @{
            Type = "PositiveInteger"
        }
    }
    
    $initializedParams = Initialize-RoadmapParameters -Parameters $params -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -ValidationRules $validationRules -ConfigurationPath $configPath
    
    if ($initializedParams.ContainsKey("FilePath") -and 
        $initializedParams.ContainsKey("BlockSize") -and 
        $initializedParams["FilePath"] -eq $testMarkdownPath -and 
        $initializedParams["BlockSize"] -eq 500) {
        Write-Host "âœ“ Initialisation et validation de paramÃ¨tres avec configuration personnalisÃ©e fonctionne correctement" -ForegroundColor Green
        Write-Host "  ParamÃ¨tres initialisÃ©s:" -ForegroundColor Yellow
        foreach ($key in $initializedParams.Keys) {
            Write-Host "    - $key = $($initializedParams[$key])" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âœ— Initialisation et validation de paramÃ¨tres avec configuration personnalisÃ©e ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  ParamÃ¨tres initialisÃ©s:" -ForegroundColor Red
        foreach ($key in $initializedParams.Keys) {
            Write-Host "    - $key = $($initializedParams[$key])" -ForegroundColor Red
        }
    }
    
    # Test 10: Validation avec ThrowOnFailure
    Write-Host "`nTest 10: Validation avec ThrowOnFailure" -ForegroundColor Cyan
    $exceptionThrown = $false
    
    try {
        Test-RoadmapParameter -Value $invalidFilePath -Type FilePath -ThrowOnFailure
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
    
    Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
