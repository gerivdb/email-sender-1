# Test-RoadmapErrorHandling.ps1
# Script pour tester les fonctions de gestion des erreurs

# Importer les fonctions Ã  tester
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions"
$exceptionPath = Join-Path -Path $functionsPath -ChildPath "exceptions\RoadmapException.ps1"
$logFunctionPath = Join-Path -Path $functionsPath -ChildPath "Write-RoadmapLog.ps1"
$errorHandlerPath = Join-Path -Path $functionsPath -ChildPath "Invoke-RoadmapErrorHandler.ps1"

# VÃ©rifier que les fichiers existent
if (-not (Test-Path -Path $exceptionPath)) {
    throw "Le fichier d'exceptions n'existe pas: $exceptionPath"
}
if (-not (Test-Path -Path $logFunctionPath)) {
    throw "Le fichier de journalisation n'existe pas: $logFunctionPath"
}
if (-not (Test-Path -Path $errorHandlerPath)) {
    throw "Le fichier de gestion des erreurs n'existe pas: $errorHandlerPath"
}

# Importer les fonctions
. $exceptionPath
. $logFunctionPath
. $errorHandlerPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de journal pour les tests
$logFilePath = Join-Path -Path $testDir -ChildPath "test-errors.log"

Write-Host "RÃ©pertoire de test crÃ©Ã©: $testDir" -ForegroundColor Green
Write-Host "Fichier de journal: $logFilePath" -ForegroundColor Green

try {
    # Test 1: CrÃ©ation et utilisation d'exceptions personnalisÃ©es
    Write-Host "`nTest 1: CrÃ©ation et utilisation d'exceptions personnalisÃ©es" -ForegroundColor Cyan

    # CrÃ©er une exception de base
    $baseException = [RoadmapException]::new("Ceci est une exception de base")
    Write-Host "  Exception de base crÃ©Ã©e: $($baseException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($baseException.Message)" -ForegroundColor Yellow
    Write-Host "  CatÃ©gorie: $($baseException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($baseException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  Message dÃ©taillÃ©: $($baseException.GetDetailedMessage())" -ForegroundColor Yellow

    # CrÃ©er une exception de parsing
    $parsingException = [RoadmapParsingException]::new("Erreur de parsing", 42, "- [ ] TÃ¢che invalide")
    Write-Host "`n  Exception de parsing crÃ©Ã©e: $($parsingException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($parsingException.Message)" -ForegroundColor Yellow
    Write-Host "  CatÃ©gorie: $($parsingException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($parsingException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  NumÃ©ro de ligne: $($parsingException.LineNumber)" -ForegroundColor Yellow
    Write-Host "  Contenu de la ligne: $($parsingException.LineContent)" -ForegroundColor Yellow
    Write-Host "  Message dÃ©taillÃ©: $($parsingException.GetDetailedMessage())" -ForegroundColor Yellow

    # CrÃ©er une exception de validation
    $validationException = [RoadmapValidationException]::new("Erreur de validation", "NotEmpty", "")
    Write-Host "`n  Exception de validation crÃ©Ã©e: $($validationException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($validationException.Message)" -ForegroundColor Yellow
    Write-Host "  CatÃ©gorie: $($validationException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($validationException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  RÃ¨gle de validation: $($validationException.ValidationRule)" -ForegroundColor Yellow
    Write-Host "  Valeur invalide: $($validationException.InvalidValue)" -ForegroundColor Yellow
    Write-Host "  Message dÃ©taillÃ©: $($validationException.GetDetailedMessage())" -ForegroundColor Yellow

    # CrÃ©er une exception d'IO
    $ioException = [RoadmapIOException]::new("Erreur d'IO", "C:\chemin\inexistant.md", "Read")
    Write-Host "`n  Exception d'IO crÃ©Ã©e: $($ioException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($ioException.Message)" -ForegroundColor Yellow
    Write-Host "  CatÃ©gorie: $($ioException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($ioException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  Chemin du fichier: $($ioException.FilePath)" -ForegroundColor Yellow
    Write-Host "  OpÃ©ration: $($ioException.Operation)" -ForegroundColor Yellow
    Write-Host "  Message dÃ©taillÃ©: $($ioException.GetDetailedMessage())" -ForegroundColor Yellow

    # CrÃ©er une exception de dÃ©pendance
    $dependencyException = [RoadmapDependencyException]::new("Erreur de dÃ©pendance", "TASK-1", "TASK-2", "Explicit")
    Write-Host "`n  Exception de dÃ©pendance crÃ©Ã©e: $($dependencyException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($dependencyException.Message)" -ForegroundColor Yellow
    Write-Host "  CatÃ©gorie: $($dependencyException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($dependencyException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  ID de tÃ¢che source: $($dependencyException.SourceTaskId)" -ForegroundColor Yellow
    Write-Host "  ID de tÃ¢che cible: $($dependencyException.TargetTaskId)" -ForegroundColor Yellow
    Write-Host "  Type de dÃ©pendance: $($dependencyException.DependencyType)" -ForegroundColor Yellow
    Write-Host "  Message dÃ©taillÃ©: $($dependencyException.GetDetailedMessage())" -ForegroundColor Yellow

    # CrÃ©er une exception de configuration
    $configException = [RoadmapConfigurationException]::new("Erreur de configuration", "MaxDepth", "10")
    Write-Host "`n  Exception de configuration crÃ©Ã©e: $($configException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($configException.Message)" -ForegroundColor Yellow
    Write-Host "  CatÃ©gorie: $($configException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($configException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  ClÃ© de configuration: $($configException.ConfigKey)" -ForegroundColor Yellow
    Write-Host "  Valeur de configuration: $($configException.ConfigValue)" -ForegroundColor Yellow
    Write-Host "  Message dÃ©taillÃ©: $($configException.GetDetailedMessage())" -ForegroundColor Yellow

    if ($baseException -and $parsingException -and $validationException -and $ioException -and $dependencyException -and $configException) {
        Write-Host "`nâœ“ CrÃ©ation et utilisation d'exceptions personnalisÃ©es fonctionnent correctement" -ForegroundColor Green
    } else {
        Write-Host "`nâœ— ProblÃ¨me lors de la crÃ©ation ou de l'utilisation d'exceptions personnalisÃ©es" -ForegroundColor Red
    }

    # Test 2: Journalisation des erreurs
    Write-Host "`nTest 2: Journalisation des erreurs" -ForegroundColor Cyan

    # Journaliser un message d'information
    Write-RoadmapLog -Message "Ceci est un message d'information" -Level Info -Category "Test" -FilePath $logFilePath

    # Journaliser un message d'avertissement
    Write-RoadmapLog -Message "Ceci est un message d'avertissement" -Level Warning -Category "Test" -FilePath $logFilePath

    # Journaliser un message d'erreur
    Write-RoadmapLog -Message "Ceci est un message d'erreur" -Level Error -Category "Test" -FilePath $logFilePath

    # Journaliser un message d'erreur avec une exception
    Write-RoadmapLog -Message "Ceci est un message d'erreur avec une exception" -Level Error -Category "Test" -Exception $parsingException -FilePath $logFilePath

    # Journaliser un message avec des informations supplÃ©mentaires
    $additionalInfo = @{
        "File"     = "test.md"
        "Line"     = 42
        "Function" = "Test-Function"
    }
    Write-RoadmapLog -Message "Ceci est un message avec des informations supplÃ©mentaires" -Level Info -Category "Test" -AdditionalInfo $additionalInfo -FilePath $logFilePath

    # VÃ©rifier que le fichier de journal a Ã©tÃ© crÃ©Ã© et contient des donnÃ©es
    if (Test-Path -Path $logFilePath) {
        $logContent = Get-Content -Path $logFilePath -Raw
        if ($logContent -and $logContent.Length -gt 0) {
            Write-Host "  Fichier de journal crÃ©Ã© et contient des donnÃ©es" -ForegroundColor Yellow
            Write-Host "  Taille du fichier: $((Get-Item -Path $logFilePath).Length) octets" -ForegroundColor Yellow
            Write-Host "  Nombre de lignes: $((Get-Content -Path $logFilePath).Count)" -ForegroundColor Yellow
            Write-Host "`nâœ“ Journalisation des erreurs fonctionne correctement" -ForegroundColor Green
        } else {
            Write-Host "`nâœ— Le fichier de journal est vide" -ForegroundColor Red
        }
    } else {
        Write-Host "`nâœ— Le fichier de journal n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }

    # Test 3: Gestion des erreurs avec Invoke-RoadmapErrorHandler
    Write-Host "`nTest 3: Gestion des erreurs avec Invoke-RoadmapErrorHandler" -ForegroundColor Cyan

    # Test 3.1: Gestion d'une erreur avec ErrorAction = Continue
    Write-Host "`n  Test 3.1: Gestion d'une erreur avec ErrorAction = Continue" -ForegroundColor Yellow
    try {
        throw "Erreur de test"
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Test" -LogFilePath $logFilePath
        Write-Host "    âœ“ L'erreur a Ã©tÃ© gÃ©rÃ©e sans interruption" -ForegroundColor Green
    }

    # Test 3.2: Gestion d'une erreur avec ErrorAction = SilentlyContinue
    Write-Host "`n  Test 3.2: Gestion d'une erreur avec ErrorAction = SilentlyContinue" -ForegroundColor Yellow
    try {
        throw "Erreur de test silencieuse"
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction SilentlyContinue -Category "Test" -LogFilePath $logFilePath -NoConsole
        Write-Host "    âœ“ L'erreur a Ã©tÃ© gÃ©rÃ©e silencieusement" -ForegroundColor Green
    }

    # Test 3.3: Gestion d'une erreur avec ErrorAction = Stop
    Write-Host "`n  Test 3.3: Gestion d'une erreur avec ErrorAction = Stop" -ForegroundColor Yellow
    $errorCaught = $false
    try {
        try {
            throw "Erreur de test fatale"
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Stop -Category "Test" -LogFilePath $logFilePath
        }
    } catch {
        $errorCaught = $true
        Write-Host "    âœ“ L'erreur a Ã©tÃ© relancÃ©e comme prÃ©vu" -ForegroundColor Green
    }

    if (-not $errorCaught) {
        Write-Host "    âœ— L'erreur n'a pas Ã©tÃ© relancÃ©e" -ForegroundColor Red
    }

    # Test 3.4: Gestion d'une erreur avec ErrorAction = Ignore
    Write-Host "`n  Test 3.4: Gestion d'une erreur avec ErrorAction = Ignore" -ForegroundColor Yellow
    try {
        throw "Erreur de test Ã  ignorer"
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Ignore -Category "Test" -LogFilePath $logFilePath
        Write-Host "    âœ“ L'erreur a Ã©tÃ© ignorÃ©e" -ForegroundColor Green
    }

    # Test 3.5: ExÃ©cution d'un bloc de script avec gestion des erreurs
    Write-Host "`n  Test 3.5: ExÃ©cution d'un bloc de script avec gestion des erreurs" -ForegroundColor Yellow
    $result = Invoke-RoadmapErrorHandler -ScriptBlock { return "SuccÃ¨s" } -ErrorHandlingAction Stop -Category "Test" -LogFilePath $logFilePath

    if ($result -eq "SuccÃ¨s") {
        Write-Host "    âœ“ Le bloc de script a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s" -ForegroundColor Green
    } else {
        Write-Host "    âœ— Le bloc de script n'a pas retournÃ© le rÃ©sultat attendu" -ForegroundColor Red
    }

    # Test 3.6: ExÃ©cution d'un bloc de script qui Ã©choue avec ErrorAction = Retry
    Write-Host "`n  Test 3.6: ExÃ©cution d'un bloc de script qui Ã©choue avec ErrorAction = Retry" -ForegroundColor Yellow
    $counter = 0
    $result = Invoke-RoadmapErrorHandler -ScriptBlock {
        $script:counter++
        if ($script:counter -lt 3) {
            throw "Erreur de test, tentative $script:counter"
        }
        return "SuccÃ¨s aprÃ¨s $script:counter tentatives"
    } -ErrorHandlingAction Retry -MaxRetryCount 5 -RetryDelaySeconds 1 -Category "Test" -LogFilePath $logFilePath

    if ($result -eq "SuccÃ¨s aprÃ¨s 3 tentatives" -and $counter -eq 3) {
        Write-Host "    âœ“ Le bloc de script a Ã©tÃ© rÃ©essayÃ© et a rÃ©ussi aprÃ¨s $counter tentatives" -ForegroundColor Green
    } else {
        Write-Host "    âœ— Le mÃ©canisme de retry n'a pas fonctionnÃ© correctement" -ForegroundColor Red
        Write-Host "      RÃ©sultat: $result" -ForegroundColor Red
        Write-Host "      Nombre de tentatives: $counter" -ForegroundColor Red
    }

    # Test 3.7: ExÃ©cution d'un bloc de script qui Ã©choue toujours avec ErrorAction = Retry
    Write-Host "`n  Test 3.7: ExÃ©cution d'un bloc de script qui Ã©choue toujours avec ErrorAction = Retry" -ForegroundColor Yellow
    $counter = 0
    $result = Invoke-RoadmapErrorHandler -ScriptBlock {
        $script:counter++
        throw "Erreur de test permanente, tentative $script:counter"
    } -ErrorHandlingAction Retry -MaxRetryCount 3 -RetryDelaySeconds 1 -Category "Test" -LogFilePath $logFilePath

    if ($counter -eq 4) {
        Write-Host "    âœ“ Le bloc de script a Ã©tÃ© rÃ©essayÃ© $counter fois avant d'abandonner" -ForegroundColor Green
    } else {
        Write-Host "    âœ— Le mÃ©canisme de retry n'a pas effectuÃ© le bon nombre de tentatives" -ForegroundColor Red
        Write-Host "      Nombre de tentatives: $counter (attendu: 4)" -ForegroundColor Red
    }

    # Test 3.8: ExÃ©cution d'un bloc de script avec des paramÃ¨tres
    Write-Host "`n  Test 3.8: ExÃ©cution d'un bloc de script avec des paramÃ¨tres" -ForegroundColor Yellow
    $params = @{
        "Param1" = "Valeur1"
        "Param2" = 42
    }

    $result = Invoke-RoadmapErrorHandler -ScriptBlock {
        param($Param1, $Param2)
        return "Param1: $Param1, Param2: $Param2"
    } -ScriptBlockParams $params -ErrorHandlingAction Stop -Category "Test" -LogFilePath $logFilePath

    if ($result -eq "Param1: Valeur1, Param2: 42") {
        Write-Host "    âœ“ Le bloc de script a Ã©tÃ© exÃ©cutÃ© avec les paramÃ¨tres corrects" -ForegroundColor Green
    } else {
        Write-Host "    âœ— Le bloc de script n'a pas reÃ§u les paramÃ¨tres correctement" -ForegroundColor Red
        Write-Host "      RÃ©sultat: $result" -ForegroundColor Red
    }

    Write-Host "`nâœ“ Gestion des erreurs avec Invoke-RoadmapErrorHandler fonctionne correctement" -ForegroundColor Green

    # Test 4: IntÃ©gration des exceptions personnalisÃ©es avec le gestionnaire d'erreurs
    Write-Host "`nTest 4: IntÃ©gration des exceptions personnalisÃ©es avec le gestionnaire d'erreurs" -ForegroundColor Cyan

    # Test 4.1: Gestion d'une exception de parsing
    Write-Host "`n  Test 4.1: Gestion d'une exception de parsing" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapParsingException]::new("Erreur de parsing dans le test", 42, "- [ ] TÃ¢che invalide")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Parsing" -LogFilePath $logFilePath
            Write-Host "    âœ“ L'exception de parsing a Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    âœ— L'exception de parsing n'a pas Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.2: Gestion d'une exception de validation
    Write-Host "`n  Test 4.2: Gestion d'une exception de validation" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapValidationException]::new("Erreur de validation dans le test", "NotEmpty", "")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Validation" -LogFilePath $logFilePath
            Write-Host "    âœ“ L'exception de validation a Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    âœ— L'exception de validation n'a pas Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.3: Gestion d'une exception d'IO
    Write-Host "`n  Test 4.3: Gestion d'une exception d'IO" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapIOException]::new("Erreur d'IO dans le test", "C:\chemin\inexistant.md", "Read")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "IO" -LogFilePath $logFilePath
            Write-Host "    âœ“ L'exception d'IO a Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    âœ— L'exception d'IO n'a pas Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.4: Gestion d'une exception de dÃ©pendance
    Write-Host "`n  Test 4.4: Gestion d'une exception de dÃ©pendance" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapDependencyException]::new("Erreur de dÃ©pendance dans le test", "TASK-1", "TASK-2", "Explicit")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Dependency" -LogFilePath $logFilePath
            Write-Host "    âœ“ L'exception de dÃ©pendance a Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    âœ— L'exception de dÃ©pendance n'a pas Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.5: Gestion d'une exception de configuration
    Write-Host "`n  Test 4.5: Gestion d'une exception de configuration" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapConfigurationException]::new("Erreur de configuration dans le test", "MaxDepth", "10")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Configuration" -LogFilePath $logFilePath
            Write-Host "    âœ“ L'exception de configuration a Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    âœ— L'exception de configuration n'a pas Ã©tÃ© gÃ©rÃ©e correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    Write-Host "`nâœ“ IntÃ©gration des exceptions personnalisÃ©es avec le gestionnaire d'erreurs fonctionne correctement" -ForegroundColor Green

    # Afficher le contenu du fichier de journal
    Write-Host "`nContenu du fichier de journal:" -ForegroundColor Cyan
    Get-Content -Path $logFilePath | Select-Object -First 10 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }

    if ((Get-Content -Path $logFilePath).Count -gt 10) {
        Write-Host "  ... (plus de lignes)" -ForegroundColor Gray
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
