# Test-RoadmapErrorHandling.ps1
# Script pour tester les fonctions de gestion des erreurs

# Importer les fonctions à tester
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions"
$exceptionPath = Join-Path -Path $functionsPath -ChildPath "exceptions\RoadmapException.ps1"
$logFunctionPath = Join-Path -Path $functionsPath -ChildPath "Write-RoadmapLog.ps1"
$errorHandlerPath = Join-Path -Path $functionsPath -ChildPath "Invoke-RoadmapErrorHandler.ps1"

# Vérifier que les fichiers existent
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

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de journal pour les tests
$logFilePath = Join-Path -Path $testDir -ChildPath "test-errors.log"

Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Green
Write-Host "Fichier de journal: $logFilePath" -ForegroundColor Green

try {
    # Test 1: Création et utilisation d'exceptions personnalisées
    Write-Host "`nTest 1: Création et utilisation d'exceptions personnalisées" -ForegroundColor Cyan

    # Créer une exception de base
    $baseException = [RoadmapException]::new("Ceci est une exception de base")
    Write-Host "  Exception de base créée: $($baseException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($baseException.Message)" -ForegroundColor Yellow
    Write-Host "  Catégorie: $($baseException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($baseException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  Message détaillé: $($baseException.GetDetailedMessage())" -ForegroundColor Yellow

    # Créer une exception de parsing
    $parsingException = [RoadmapParsingException]::new("Erreur de parsing", 42, "- [ ] Tâche invalide")
    Write-Host "`n  Exception de parsing créée: $($parsingException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($parsingException.Message)" -ForegroundColor Yellow
    Write-Host "  Catégorie: $($parsingException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($parsingException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  Numéro de ligne: $($parsingException.LineNumber)" -ForegroundColor Yellow
    Write-Host "  Contenu de la ligne: $($parsingException.LineContent)" -ForegroundColor Yellow
    Write-Host "  Message détaillé: $($parsingException.GetDetailedMessage())" -ForegroundColor Yellow

    # Créer une exception de validation
    $validationException = [RoadmapValidationException]::new("Erreur de validation", "NotEmpty", "")
    Write-Host "`n  Exception de validation créée: $($validationException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($validationException.Message)" -ForegroundColor Yellow
    Write-Host "  Catégorie: $($validationException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($validationException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  Règle de validation: $($validationException.ValidationRule)" -ForegroundColor Yellow
    Write-Host "  Valeur invalide: $($validationException.InvalidValue)" -ForegroundColor Yellow
    Write-Host "  Message détaillé: $($validationException.GetDetailedMessage())" -ForegroundColor Yellow

    # Créer une exception d'IO
    $ioException = [RoadmapIOException]::new("Erreur d'IO", "C:\chemin\inexistant.md", "Read")
    Write-Host "`n  Exception d'IO créée: $($ioException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($ioException.Message)" -ForegroundColor Yellow
    Write-Host "  Catégorie: $($ioException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($ioException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  Chemin du fichier: $($ioException.FilePath)" -ForegroundColor Yellow
    Write-Host "  Opération: $($ioException.Operation)" -ForegroundColor Yellow
    Write-Host "  Message détaillé: $($ioException.GetDetailedMessage())" -ForegroundColor Yellow

    # Créer une exception de dépendance
    $dependencyException = [RoadmapDependencyException]::new("Erreur de dépendance", "TASK-1", "TASK-2", "Explicit")
    Write-Host "`n  Exception de dépendance créée: $($dependencyException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($dependencyException.Message)" -ForegroundColor Yellow
    Write-Host "  Catégorie: $($dependencyException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($dependencyException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  ID de tâche source: $($dependencyException.SourceTaskId)" -ForegroundColor Yellow
    Write-Host "  ID de tâche cible: $($dependencyException.TargetTaskId)" -ForegroundColor Yellow
    Write-Host "  Type de dépendance: $($dependencyException.DependencyType)" -ForegroundColor Yellow
    Write-Host "  Message détaillé: $($dependencyException.GetDetailedMessage())" -ForegroundColor Yellow

    # Créer une exception de configuration
    $configException = [RoadmapConfigurationException]::new("Erreur de configuration", "MaxDepth", "10")
    Write-Host "`n  Exception de configuration créée: $($configException.GetType().Name)" -ForegroundColor Yellow
    Write-Host "  Message: $($configException.Message)" -ForegroundColor Yellow
    Write-Host "  Catégorie: $($configException.Category)" -ForegroundColor Yellow
    Write-Host "  Code d'erreur: $($configException.ErrorCode)" -ForegroundColor Yellow
    Write-Host "  Clé de configuration: $($configException.ConfigKey)" -ForegroundColor Yellow
    Write-Host "  Valeur de configuration: $($configException.ConfigValue)" -ForegroundColor Yellow
    Write-Host "  Message détaillé: $($configException.GetDetailedMessage())" -ForegroundColor Yellow

    if ($baseException -and $parsingException -and $validationException -and $ioException -and $dependencyException -and $configException) {
        Write-Host "`n✓ Création et utilisation d'exceptions personnalisées fonctionnent correctement" -ForegroundColor Green
    } else {
        Write-Host "`n✗ Problème lors de la création ou de l'utilisation d'exceptions personnalisées" -ForegroundColor Red
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

    # Journaliser un message avec des informations supplémentaires
    $additionalInfo = @{
        "File"     = "test.md"
        "Line"     = 42
        "Function" = "Test-Function"
    }
    Write-RoadmapLog -Message "Ceci est un message avec des informations supplémentaires" -Level Info -Category "Test" -AdditionalInfo $additionalInfo -FilePath $logFilePath

    # Vérifier que le fichier de journal a été créé et contient des données
    if (Test-Path -Path $logFilePath) {
        $logContent = Get-Content -Path $logFilePath -Raw
        if ($logContent -and $logContent.Length -gt 0) {
            Write-Host "  Fichier de journal créé et contient des données" -ForegroundColor Yellow
            Write-Host "  Taille du fichier: $((Get-Item -Path $logFilePath).Length) octets" -ForegroundColor Yellow
            Write-Host "  Nombre de lignes: $((Get-Content -Path $logFilePath).Count)" -ForegroundColor Yellow
            Write-Host "`n✓ Journalisation des erreurs fonctionne correctement" -ForegroundColor Green
        } else {
            Write-Host "`n✗ Le fichier de journal est vide" -ForegroundColor Red
        }
    } else {
        Write-Host "`n✗ Le fichier de journal n'a pas été créé" -ForegroundColor Red
    }

    # Test 3: Gestion des erreurs avec Invoke-RoadmapErrorHandler
    Write-Host "`nTest 3: Gestion des erreurs avec Invoke-RoadmapErrorHandler" -ForegroundColor Cyan

    # Test 3.1: Gestion d'une erreur avec ErrorAction = Continue
    Write-Host "`n  Test 3.1: Gestion d'une erreur avec ErrorAction = Continue" -ForegroundColor Yellow
    try {
        throw "Erreur de test"
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Test" -LogFilePath $logFilePath
        Write-Host "    ✓ L'erreur a été gérée sans interruption" -ForegroundColor Green
    }

    # Test 3.2: Gestion d'une erreur avec ErrorAction = SilentlyContinue
    Write-Host "`n  Test 3.2: Gestion d'une erreur avec ErrorAction = SilentlyContinue" -ForegroundColor Yellow
    try {
        throw "Erreur de test silencieuse"
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction SilentlyContinue -Category "Test" -LogFilePath $logFilePath -NoConsole
        Write-Host "    ✓ L'erreur a été gérée silencieusement" -ForegroundColor Green
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
        Write-Host "    ✓ L'erreur a été relancée comme prévu" -ForegroundColor Green
    }

    if (-not $errorCaught) {
        Write-Host "    ✗ L'erreur n'a pas été relancée" -ForegroundColor Red
    }

    # Test 3.4: Gestion d'une erreur avec ErrorAction = Ignore
    Write-Host "`n  Test 3.4: Gestion d'une erreur avec ErrorAction = Ignore" -ForegroundColor Yellow
    try {
        throw "Erreur de test à ignorer"
    } catch {
        Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Ignore -Category "Test" -LogFilePath $logFilePath
        Write-Host "    ✓ L'erreur a été ignorée" -ForegroundColor Green
    }

    # Test 3.5: Exécution d'un bloc de script avec gestion des erreurs
    Write-Host "`n  Test 3.5: Exécution d'un bloc de script avec gestion des erreurs" -ForegroundColor Yellow
    $result = Invoke-RoadmapErrorHandler -ScriptBlock { return "Succès" } -ErrorHandlingAction Stop -Category "Test" -LogFilePath $logFilePath

    if ($result -eq "Succès") {
        Write-Host "    ✓ Le bloc de script a été exécuté avec succès" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Le bloc de script n'a pas retourné le résultat attendu" -ForegroundColor Red
    }

    # Test 3.6: Exécution d'un bloc de script qui échoue avec ErrorAction = Retry
    Write-Host "`n  Test 3.6: Exécution d'un bloc de script qui échoue avec ErrorAction = Retry" -ForegroundColor Yellow
    $counter = 0
    $result = Invoke-RoadmapErrorHandler -ScriptBlock {
        $script:counter++
        if ($script:counter -lt 3) {
            throw "Erreur de test, tentative $script:counter"
        }
        return "Succès après $script:counter tentatives"
    } -ErrorHandlingAction Retry -MaxRetryCount 5 -RetryDelaySeconds 1 -Category "Test" -LogFilePath $logFilePath

    if ($result -eq "Succès après 3 tentatives" -and $counter -eq 3) {
        Write-Host "    ✓ Le bloc de script a été réessayé et a réussi après $counter tentatives" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Le mécanisme de retry n'a pas fonctionné correctement" -ForegroundColor Red
        Write-Host "      Résultat: $result" -ForegroundColor Red
        Write-Host "      Nombre de tentatives: $counter" -ForegroundColor Red
    }

    # Test 3.7: Exécution d'un bloc de script qui échoue toujours avec ErrorAction = Retry
    Write-Host "`n  Test 3.7: Exécution d'un bloc de script qui échoue toujours avec ErrorAction = Retry" -ForegroundColor Yellow
    $counter = 0
    $result = Invoke-RoadmapErrorHandler -ScriptBlock {
        $script:counter++
        throw "Erreur de test permanente, tentative $script:counter"
    } -ErrorHandlingAction Retry -MaxRetryCount 3 -RetryDelaySeconds 1 -Category "Test" -LogFilePath $logFilePath

    if ($counter -eq 4) {
        Write-Host "    ✓ Le bloc de script a été réessayé $counter fois avant d'abandonner" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Le mécanisme de retry n'a pas effectué le bon nombre de tentatives" -ForegroundColor Red
        Write-Host "      Nombre de tentatives: $counter (attendu: 4)" -ForegroundColor Red
    }

    # Test 3.8: Exécution d'un bloc de script avec des paramètres
    Write-Host "`n  Test 3.8: Exécution d'un bloc de script avec des paramètres" -ForegroundColor Yellow
    $params = @{
        "Param1" = "Valeur1"
        "Param2" = 42
    }

    $result = Invoke-RoadmapErrorHandler -ScriptBlock {
        param($Param1, $Param2)
        return "Param1: $Param1, Param2: $Param2"
    } -ScriptBlockParams $params -ErrorHandlingAction Stop -Category "Test" -LogFilePath $logFilePath

    if ($result -eq "Param1: Valeur1, Param2: 42") {
        Write-Host "    ✓ Le bloc de script a été exécuté avec les paramètres corrects" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Le bloc de script n'a pas reçu les paramètres correctement" -ForegroundColor Red
        Write-Host "      Résultat: $result" -ForegroundColor Red
    }

    Write-Host "`n✓ Gestion des erreurs avec Invoke-RoadmapErrorHandler fonctionne correctement" -ForegroundColor Green

    # Test 4: Intégration des exceptions personnalisées avec le gestionnaire d'erreurs
    Write-Host "`nTest 4: Intégration des exceptions personnalisées avec le gestionnaire d'erreurs" -ForegroundColor Cyan

    # Test 4.1: Gestion d'une exception de parsing
    Write-Host "`n  Test 4.1: Gestion d'une exception de parsing" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapParsingException]::new("Erreur de parsing dans le test", 42, "- [ ] Tâche invalide")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Parsing" -LogFilePath $logFilePath
            Write-Host "    ✓ L'exception de parsing a été gérée correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ✗ L'exception de parsing n'a pas été gérée correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.2: Gestion d'une exception de validation
    Write-Host "`n  Test 4.2: Gestion d'une exception de validation" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapValidationException]::new("Erreur de validation dans le test", "NotEmpty", "")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Validation" -LogFilePath $logFilePath
            Write-Host "    ✓ L'exception de validation a été gérée correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ✗ L'exception de validation n'a pas été gérée correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.3: Gestion d'une exception d'IO
    Write-Host "`n  Test 4.3: Gestion d'une exception d'IO" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapIOException]::new("Erreur d'IO dans le test", "C:\chemin\inexistant.md", "Read")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "IO" -LogFilePath $logFilePath
            Write-Host "    ✓ L'exception d'IO a été gérée correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ✗ L'exception d'IO n'a pas été gérée correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.4: Gestion d'une exception de dépendance
    Write-Host "`n  Test 4.4: Gestion d'une exception de dépendance" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapDependencyException]::new("Erreur de dépendance dans le test", "TASK-1", "TASK-2", "Explicit")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Dependency" -LogFilePath $logFilePath
            Write-Host "    ✓ L'exception de dépendance a été gérée correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ✗ L'exception de dépendance n'a pas été gérée correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    # Test 4.5: Gestion d'une exception de configuration
    Write-Host "`n  Test 4.5: Gestion d'une exception de configuration" -ForegroundColor Yellow
    try {
        try {
            throw [RoadmapConfigurationException]::new("Erreur de configuration dans le test", "MaxDepth", "10")
        } catch {
            Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorHandlingAction Continue -Category "Configuration" -LogFilePath $logFilePath
            Write-Host "    ✓ L'exception de configuration a été gérée correctement" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ✗ L'exception de configuration n'a pas été gérée correctement" -ForegroundColor Red
        Write-Host "      Erreur: $_" -ForegroundColor Red
    }

    Write-Host "`n✓ Intégration des exceptions personnalisées avec le gestionnaire d'erreurs fonctionne correctement" -ForegroundColor Green

    # Afficher le contenu du fichier de journal
    Write-Host "`nContenu du fichier de journal:" -ForegroundColor Cyan
    Get-Content -Path $logFilePath | Select-Object -First 10 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }

    if ((Get-Content -Path $logFilePath).Count -gt 10) {
        Write-Host "  ... (plus de lignes)" -ForegroundColor Gray
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
