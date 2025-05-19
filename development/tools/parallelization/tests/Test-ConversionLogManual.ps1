# Script de test manuel pour la fonction Write-ConversionLog
# Ce script teste directement la fonction sans dépendre de Pester

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Créer un dossier temporaire pour les logs
$tempFolder = Join-Path -Path $env:TEMP -ChildPath "UnifiedParallelTests_$(Get-Random)"
New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null

# Définir un chemin de log temporaire
$tempLogPath = Join-Path -Path $tempFolder -ChildPath "ConversionLog.log"

# Sauvegarder la configuration actuelle
$originalConfig = Get-ModuleConfig

# Créer une configuration de test
$testConfig = $originalConfig.Clone()
if (-not $testConfig.Logging) {
    $testConfig.Logging = @{}
}
$testConfig.Logging.EnableFileLogging = $true
$testConfig.Logging.EnableConsoleLogging = $true
$testConfig.Logging.LogFilePath = $tempLogPath
$testConfig.Logging.LogLevel = 'Info'

# Appliquer la configuration de test
Set-ModuleConfig -Config $testConfig

# Tester Write-ConversionLog
Write-Host "`n=== Tests pour Write-ConversionLog ===" -ForegroundColor Magenta

# Test 1: Message simple
Write-Host "`n--- Test 1: Message simple ---" -ForegroundColor Cyan
try {
    Write-ConversionLog -Message "Test de journalisation simple"
    
    if (Test-Path -Path $tempLogPath) {
        Write-Host "Fichier de log créé: $tempLogPath" -ForegroundColor Green
        $logContent = Get-Content -Path $tempLogPath -Raw
        Write-Host "Contenu du log:" -ForegroundColor Green
        Write-Host $logContent
    } else {
        Write-Host "ERREUR: Le fichier de log n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

# Test 2: Message avec niveau Error
Write-Host "`n--- Test 2: Message avec niveau Error ---" -ForegroundColor Cyan
try {
    Write-ConversionLog -Message "Test de journalisation avec niveau Error" -Level Error
    
    if (Test-Path -Path $tempLogPath) {
        $logContent = Get-Content -Path $tempLogPath -Raw
        Write-Host "Contenu du log:" -ForegroundColor Green
        Write-Host $logContent
    } else {
        Write-Host "ERREUR: Le fichier de log n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

# Test 3: Message avec énumération
Write-Host "`n--- Test 3: Message avec énumération ---" -ForegroundColor Cyan
try {
    Write-ConversionLog -Message "Test de journalisation avec énumération" -EnumType ([System.Threading.ApartmentState])
    
    if (Test-Path -Path $tempLogPath) {
        $logContent = Get-Content -Path $tempLogPath -Raw
        Write-Host "Contenu du log:" -ForegroundColor Green
        Write-Host $logContent
    } else {
        Write-Host "ERREUR: Le fichier de log n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

# Test 4: Message avec valeur
Write-Host "`n--- Test 4: Message avec valeur ---" -ForegroundColor Cyan
try {
    Write-ConversionLog -Message "Test de journalisation avec valeur" -Value "TestValue"
    
    if (Test-Path -Path $tempLogPath) {
        $logContent = Get-Content -Path $tempLogPath -Raw
        Write-Host "Contenu du log:" -ForegroundColor Green
        Write-Host $logContent
    } else {
        Write-Host "ERREUR: Le fichier de log n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

# Test 5: Message avec exception
Write-Host "`n--- Test 5: Message avec exception ---" -ForegroundColor Cyan
try {
    $exception = [System.ArgumentException]::new("Message d'erreur de test")
    Write-ConversionLog -Message "Test de journalisation avec exception" -Exception $exception
    
    if (Test-Path -Path $tempLogPath) {
        $logContent = Get-Content -Path $tempLogPath -Raw
        Write-Host "Contenu du log:" -ForegroundColor Green
        Write-Host $logContent
    } else {
        Write-Host "ERREUR: Le fichier de log n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

# Test 6: Message avec tous les paramètres
Write-Host "`n--- Test 6: Message avec tous les paramètres ---" -ForegroundColor Cyan
try {
    $exception = [System.ArgumentException]::new("Message d'erreur de test")
    Write-ConversionLog -Message "Test de journalisation avec tous les paramètres" -Level Error -EnumType ([System.Threading.ApartmentState]) -Value "TestValue" -Exception $exception
    
    if (Test-Path -Path $tempLogPath) {
        $logContent = Get-Content -Path $tempLogPath -Raw
        Write-Host "Contenu du log:" -ForegroundColor Green
        Write-Host $logContent
    } else {
        Write-Host "ERREUR: Le fichier de log n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
}

# Restaurer la configuration d'origine
Set-ModuleConfig -Config $originalConfig

# Supprimer le dossier temporaire
if (Test-Path -Path $tempFolder) {
    Remove-Item -Path $tempFolder -Recurse -Force
}

Write-Host "`n=== Tests terminés ===" -ForegroundColor Cyan
