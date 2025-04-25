#
# Test-LoggingFunctions.ps1
#
# Script pour tester les fonctions de journalisation
#

# Importer le script des fonctions de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Logging\LoggingFunctions.ps1"

# Créer le répertoire s'il n'existe pas
$loggingFunctionsDir = Split-Path -Parent $loggingFunctionsPath
if (-not (Test-Path -Path $loggingFunctionsDir)) {
    New-Item -Path $loggingFunctionsDir -ItemType Directory -Force | Out-Null
}

# Importer le script
. $loggingFunctionsPath

Write-Host "Début des tests des fonctions de journalisation..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

$functions = @(
    "Set-LoggingConfiguration",
    "Get-LoggingConfiguration",
    "Write-Log",
    "Write-LogDebug",
    "Write-LogVerbose",
    "Write-LogInformation",
    "Write-LogWarning",
    "Write-LogError",
    "Write-LogCritical"
)

$successCount = 0
$failureCount = 0

foreach ($function in $functions) {
    $command = Get-Command -Name $function -ErrorAction SilentlyContinue
    $success = $null -ne $command
    
    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }
    
    Write-Host "  Vérification de la fonction $function : $status" -ForegroundColor $color
    
    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    La fonction $function n'est pas définie" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Tester la fonction Set-LoggingConfiguration
Write-Host "`nTest 2: Tester la fonction Set-LoggingConfiguration" -ForegroundColor Cyan

# Créer un fichier temporaire pour les tests
$tempDir = [System.IO.Path]::GetTempPath()
$tempFile = Join-Path -Path $tempDir -ChildPath "RoadmapParserTest_$([Guid]::NewGuid().ToString()).log"

# Configurer la journalisation
Set-LoggingConfiguration -Level $LogLevelDebug -Destination "Both" -FilePath $tempFile -SourceName "TestLogger"

# Obtenir la configuration
$config = Get-LoggingConfiguration

# Vérifier la configuration
$success = $config.Level -eq $LogLevelDebug -and
           $config.Destination -eq "Both" -and
           $config.FilePath -eq $tempFile -and
           $config.SourceName -eq "TestLogger"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Configuration de la journalisation: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Configuration attendue: Level=$LogLevelDebug, Destination=Both, FilePath=$tempFile, SourceName=TestLogger" -ForegroundColor Red
    Write-Host "    Configuration obtenue: Level=$($config.Level), Destination=$($config.Destination), FilePath=$($config.FilePath), SourceName=$($config.SourceName)" -ForegroundColor Red
}

# Test 3: Tester la fonction Write-Log
Write-Host "`nTest 3: Tester la fonction Write-Log" -ForegroundColor Cyan

# Écrire des messages de journal
Write-Log -Message "Message de test" -Level $LogLevelDebug
Write-Log -Message "Message de test" -Level $LogLevelVerbose
Write-Log -Message "Message de test" -Level $LogLevelInformation
Write-Log -Message "Message de test" -Level $LogLevelWarning
Write-Log -Message "Message de test" -Level $LogLevelError
Write-Log -Message "Message de test" -Level $LogLevelCritical

# Vérifier que le fichier de journal existe
$fileExists = Test-Path -Path $tempFile -PathType Leaf
$status = if ($fileExists) { "Réussi" } else { "Échoué" }
$color = if ($fileExists) { "Green" } else { "Red" }

Write-Host "  Création du fichier de journal: $status" -ForegroundColor $color

if (-not $fileExists) {
    Write-Host "    Le fichier de journal n'a pas été créé: $tempFile" -ForegroundColor Red
}

# Vérifier que le fichier de journal contient les messages
if ($fileExists) {
    $logContent = Get-Content -Path $tempFile -Raw
    $containsMessages = $logContent -match "Message de test"
    
    $status = if ($containsMessages) { "Réussi" } else { "Échoué" }
    $color = if ($containsMessages) { "Green" } else { "Red" }
    
    Write-Host "  Contenu du fichier de journal: $status" -ForegroundColor $color
    
    if (-not $containsMessages) {
        Write-Host "    Le fichier de journal ne contient pas les messages attendus" -ForegroundColor Red
        Write-Host "    Contenu du fichier: $logContent" -ForegroundColor Red
    }
}

# Test 4: Tester les fonctions de journalisation par niveau
Write-Host "`nTest 4: Tester les fonctions de journalisation par niveau" -ForegroundColor Cyan

# Configurer la journalisation pour écrire uniquement dans le fichier
Set-LoggingConfiguration -Level $LogLevelDebug -Destination "File" -FilePath $tempFile -SourceName "TestLogger"

# Effacer le fichier de journal
if (Test-Path -Path $tempFile -PathType Leaf) {
    Remove-Item -Path $tempFile -Force
}

# Écrire des messages de journal avec les différentes fonctions
Write-LogDebug -Message "Message de débogage"
Write-LogVerbose -Message "Message détaillé"
Write-LogInformation -Message "Message d'information"
Write-LogWarning -Message "Message d'avertissement"
Write-LogError -Message "Message d'erreur"
Write-LogCritical -Message "Message critique"

# Vérifier que le fichier de journal existe
$fileExists = Test-Path -Path $tempFile -PathType Leaf
$status = if ($fileExists) { "Réussi" } else { "Échoué" }
$color = if ($fileExists) { "Green" } else { "Red" }

Write-Host "  Création du fichier de journal: $status" -ForegroundColor $color

if (-not $fileExists) {
    Write-Host "    Le fichier de journal n'a pas été créé: $tempFile" -ForegroundColor Red
}

# Vérifier que le fichier de journal contient les messages
if ($fileExists) {
    $logContent = Get-Content -Path $tempFile -Raw
    
    $testCases = @(
        @{ Message = "Message de débogage"; Level = "DEBUG"; Expected = $true },
        @{ Message = "Message détaillé"; Level = "VERBOSE"; Expected = $true },
        @{ Message = "Message d'information"; Level = "INFO"; Expected = $true },
        @{ Message = "Message d'avertissement"; Level = "WARNING"; Expected = $true },
        @{ Message = "Message d'erreur"; Level = "ERROR"; Expected = $true },
        @{ Message = "Message critique"; Level = "CRITICAL"; Expected = $true }
    )
    
    $successCount = 0
    $failureCount = 0
    
    foreach ($testCase in $testCases) {
        $containsMessage = $logContent -match "$($testCase.Level).*$($testCase.Message)"
        $success = $containsMessage -eq $testCase.Expected
        
        $status = if ($success) { "Réussi" } else { "Échoué" }
        $color = if ($success) { "Green" } else { "Red" }
        
        Write-Host "  Message de niveau $($testCase.Level): $status" -ForegroundColor $color
        
        if ($success) {
            $successCount++
        } else {
            $failureCount++
            Write-Host "    Le fichier de journal ne contient pas le message attendu: $($testCase.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })
}

# Test 5: Tester le filtrage par niveau de journalisation
Write-Host "`nTest 5: Tester le filtrage par niveau de journalisation" -ForegroundColor Cyan

# Configurer la journalisation pour écrire uniquement les messages de niveau Warning et supérieur
Set-LoggingConfiguration -Level $LogLevelWarning -Destination "File" -FilePath $tempFile -SourceName "TestLogger"

# Effacer le fichier de journal
if (Test-Path -Path $tempFile -PathType Leaf) {
    Remove-Item -Path $tempFile -Force
}

# Écrire des messages de journal avec les différentes fonctions
Write-LogDebug -Message "Message de débogage"
Write-LogVerbose -Message "Message détaillé"
Write-LogInformation -Message "Message d'information"
Write-LogWarning -Message "Message d'avertissement"
Write-LogError -Message "Message d'erreur"
Write-LogCritical -Message "Message critique"

# Vérifier que le fichier de journal existe
$fileExists = Test-Path -Path $tempFile -PathType Leaf
$status = if ($fileExists) { "Réussi" } else { "Échoué" }
$color = if ($fileExists) { "Green" } else { "Red" }

Write-Host "  Création du fichier de journal: $status" -ForegroundColor $color

if (-not $fileExists) {
    Write-Host "    Le fichier de journal n'a pas été créé: $tempFile" -ForegroundColor Red
}

# Vérifier que le fichier de journal contient uniquement les messages de niveau Warning et supérieur
if ($fileExists) {
    $logContent = Get-Content -Path $tempFile -Raw
    
    $testCases = @(
        @{ Message = "Message de débogage"; Level = "DEBUG"; Expected = $false },
        @{ Message = "Message détaillé"; Level = "VERBOSE"; Expected = $false },
        @{ Message = "Message d'information"; Level = "INFO"; Expected = $false },
        @{ Message = "Message d'avertissement"; Level = "WARNING"; Expected = $true },
        @{ Message = "Message d'erreur"; Level = "ERROR"; Expected = $true },
        @{ Message = "Message critique"; Level = "CRITICAL"; Expected = $true }
    )
    
    $successCount = 0
    $failureCount = 0
    
    foreach ($testCase in $testCases) {
        $containsMessage = $logContent -match "$($testCase.Level).*$($testCase.Message)"
        $success = $containsMessage -eq $testCase.Expected
        
        $status = if ($success) { "Réussi" } else { "Échoué" }
        $color = if ($success) { "Green" } else { "Red" }
        
        Write-Host "  Filtrage du message de niveau $($testCase.Level): $status" -ForegroundColor $color
        
        if ($success) {
            $successCount++
        } else {
            $failureCount++
            if ($testCase.Expected) {
                Write-Host "    Le fichier de journal ne contient pas le message attendu: $($testCase.Message)" -ForegroundColor Red
            } else {
                Write-Host "    Le fichier de journal contient un message qui devrait être filtré: $($testCase.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })
}

# Test 6: Tester la rotation des fichiers de journalisation
Write-Host "`nTest 6: Tester la rotation des fichiers de journalisation" -ForegroundColor Cyan

# Configurer la journalisation avec une taille maximale de fichier très petite
Set-LoggingConfiguration -Level $LogLevelDebug -Destination "File" -FilePath $tempFile -FileMaxSize 100 -FileMaxCount 3 -SourceName "TestLogger"

# Effacer les fichiers de journal existants
if (Test-Path -Path $tempFile -PathType Leaf) {
    Remove-Item -Path $tempFile -Force
}

for ($i = 1; $i -le 3; $i++) {
    $rotatedFile = "$tempFile.$i"
    if (Test-Path -Path $rotatedFile -PathType Leaf) {
        Remove-Item -Path $rotatedFile -Force
    }
}

# Écrire des messages de journal jusqu'à ce que la rotation se produise
for ($i = 1; $i -le 10; $i++) {
    Write-LogInformation -Message "Message de test $i avec beaucoup de contenu pour dépasser la taille maximale du fichier de journalisation et déclencher la rotation des fichiers."
}

# Vérifier que les fichiers de journal existent
$mainFileExists = Test-Path -Path $tempFile -PathType Leaf
$rotatedFileExists = Test-Path -Path "$tempFile.1" -PathType Leaf

$success = $mainFileExists -and $rotatedFileExists

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Rotation des fichiers de journal: $status" -ForegroundColor $color

if (-not $success) {
    if (-not $mainFileExists) {
        Write-Host "    Le fichier de journal principal n'a pas été créé: $tempFile" -ForegroundColor Red
    }
    if (-not $rotatedFileExists) {
        Write-Host "    Le fichier de journal rotatif n'a pas été créé: $tempFile.1" -ForegroundColor Red
    }
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempFile -PathType Leaf) {
    Remove-Item -Path $tempFile -Force
}

for ($i = 1; $i -le 3; $i++) {
    $rotatedFile = "$tempFile.$i"
    if (Test-Path -Path $rotatedFile -PathType Leaf) {
        Remove-Item -Path $rotatedFile -Force
    }
}

Write-Host "`nTests des fonctions de journalisation terminés." -ForegroundColor Cyan
