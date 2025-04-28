<#
.SYNOPSIS
    Test d'integration pour les fonctions de journalisation.

.DESCRIPTION
    Ce script contient un test d'integration pour verifier que les fonctions de journalisation,
    de rotation des journaux et de verbosite configurable fonctionnent correctement ensemble.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de creation: 2023-08-16
#>

# Importer les fonctions a tester
$modulePath = (Split-Path -Parent $PSScriptRoot)
$logRotationFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LogRotationFunctions.ps1"
$verbosityFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\VerbosityFunctions.ps1"

# Fonction d'assertion simple
function Assert-Condition {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    if ($Condition) {
        Write-Host "[OK] $Message" -ForegroundColor Green
        return $true
    } 
    else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        return $false
    }
}

# Fonction pour tester les fonctions de rotation des journaux
function Test-LogRotationFunctions {
    # Verifier si les fichiers existent
    $logRotationExists = Test-Path -Path $logRotationFunctionsPath
    $result1 = Assert-Condition -Condition $logRotationExists -Message "Le fichier LogRotationFunctions.ps1 existe"
    
    if (-not $logRotationExists) {
        return $false
    }
    
    # Sourcer les fonctions
    try {
        . $logRotationFunctionsPath
        $result2 = Assert-Condition -Condition $true -Message "Les fonctions de rotation des journaux ont ete importees avec succes"
    }
    catch {
        $result2 = Assert-Condition -Condition $false -Message "Erreur lors de l'importation des fonctions de rotation des journaux: $_"
        return $false
    }
    
    # Verifier que les fonctions principales existent
    $functionExists1 = Get-Command -Name "Get-LogRotationConfig" -ErrorAction SilentlyContinue
    $functionExists2 = Get-Command -Name "Set-LogRotationConfig" -ErrorAction SilentlyContinue
    $functionExists3 = Get-Command -Name "Test-LogRotationBySize" -ErrorAction SilentlyContinue
    $functionExists4 = Get-Command -Name "Invoke-LogRotation" -ErrorAction SilentlyContinue
    
    $result3 = Assert-Condition -Condition ($functionExists1 -ne $null) -Message "La fonction Get-LogRotationConfig existe"
    $result4 = Assert-Condition -Condition ($functionExists2 -ne $null) -Message "La fonction Set-LogRotationConfig existe"
    $result5 = Assert-Condition -Condition ($functionExists3 -ne $null) -Message "La fonction Test-LogRotationBySize existe"
    $result6 = Assert-Condition -Condition ($functionExists4 -ne $null) -Message "La fonction Invoke-LogRotation existe"
    
    # Tester la configuration
    try {
        $config = Get-LogRotationConfig
        $result7 = Assert-Condition -Condition ($config -ne $null) -Message "La configuration de rotation des journaux a ete recuperee"
        
        # Modifier la configuration
        Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 2048
        $newConfig = Get-LogRotationConfig
        $result8 = Assert-Condition -Condition ($newConfig.SizeBasedRotation.MaxSizeKB -eq 2048) -Message "La configuration a ete modifiee avec succes"
    }
    catch {
        $result7 = Assert-Condition -Condition $false -Message "Erreur lors de la manipulation de la configuration: $_"
        $result8 = $false
        return $false
    }
    
    return $result1 -and $result2 -and $result3 -and $result4 -and $result5 -and $result6 -and $result7 -and $result8
}

# Fonction pour tester les fonctions de verbosite configurable
function Test-VerbosityFunctions {
    # Verifier si les fichiers existent
    $verbosityExists = Test-Path -Path $verbosityFunctionsPath
    $result1 = Assert-Condition -Condition $verbosityExists -Message "Le fichier VerbosityFunctions.ps1 existe"
    
    if (-not $verbosityExists) {
        return $false
    }
    
    # Sourcer les fonctions
    try {
        . $verbosityFunctionsPath
        $result2 = Assert-Condition -Condition $true -Message "Les fonctions de verbosite ont ete importees avec succes"
    }
    catch {
        $result2 = Assert-Condition -Condition $false -Message "Erreur lors de l'importation des fonctions de verbosite: $_"
        return $false
    }
    
    # Verifier que les fonctions principales existent
    $functionExists1 = Get-Command -Name "Get-VerbosityConfig" -ErrorAction SilentlyContinue
    $functionExists2 = Get-Command -Name "Set-VerbosityLevel" -ErrorAction SilentlyContinue
    $functionExists3 = Get-Command -Name "Set-VerbosityPreset" -ErrorAction SilentlyContinue
    $functionExists4 = Get-Command -Name "Format-MessageByVerbosity" -ErrorAction SilentlyContinue
    
    $result3 = Assert-Condition -Condition ($functionExists1 -ne $null) -Message "La fonction Get-VerbosityConfig existe"
    $result4 = Assert-Condition -Condition ($functionExists2 -ne $null) -Message "La fonction Set-VerbosityLevel existe"
    $result5 = Assert-Condition -Condition ($functionExists3 -ne $null) -Message "La fonction Set-VerbosityPreset existe"
    $result6 = Assert-Condition -Condition ($functionExists4 -ne $null) -Message "La fonction Format-MessageByVerbosity existe"
    
    # Tester la configuration
    try {
        $config = Get-VerbosityConfig
        $result7 = Assert-Condition -Condition ($config -ne $null) -Message "La configuration de verbosite a ete recuperee"
        
        # Modifier le niveau de verbosite
        Set-VerbosityLevel -Level "Detailed"
        $level = Get-VerbosityLevel
        $result8 = Assert-Condition -Condition ($level -eq "Detailed") -Message "Le niveau de verbosite a ete modifie avec succes"
        
        # Appliquer un prereglage
        Set-VerbosityPreset -PresetName "Development"
        $newConfig = Get-VerbosityConfig
        $result9 = Assert-Condition -Condition ($newConfig.Level -eq $newConfig.Presets["Development"].Level) -Message "Le prereglage a ete applique avec succes"
    }
    catch {
        $result7 = Assert-Condition -Condition $false -Message "Erreur lors de la manipulation de la configuration: $_"
        $result8 = $false
        $result9 = $false
        return $false
    }
    
    return $result1 -and $result2 -and $result3 -and $result4 -and $result5 -and $result6 -and $result7 -and $result8 -and $result9
}

# Fonction pour tester l'integration des fonctions
function Test-LoggingIntegration {
    # Creer un repertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "LoggingIntegrationTest"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # Creer un fichier de journal de test
    $testLogFile = Join-Path -Path $testDir -ChildPath "integration.log"
    
    # Configurer la rotation des journaux
    Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 1 -BackupCount 3
    
    # Configurer la verbosite
    Set-VerbosityLevel -Level "Detailed"
    
    # Ecrire un message dans le fichier de journal
    $testMessage = "Test message for integration"
    $formattedMessage = Format-MessageByVerbosity -Message $testMessage -Level "Info" -Category "TestCategory"
    Add-Content -Path $testLogFile -Value $formattedMessage -Encoding UTF8
    
    # Verifier que le message a ete ecrit
    $logContent = Get-Content -Path $testLogFile -Raw
    $result1 = Assert-Condition -Condition ($logContent -match $testMessage) -Message "Le message a ete correctement ecrit dans le journal"
    
    # Remplir le fichier pour declencher la rotation
    Set-Content -Path $testLogFile -Value ("A" * 1024) -Force
    
    # Effectuer la rotation
    $shouldRotate = Test-LogRotationBySize -LogFile $testLogFile
    $result2 = Assert-Condition -Condition $shouldRotate -Message "Le fichier doit etre rotate"
    
    if ($shouldRotate) {
        Invoke-LogRotationBySize -LogFile $testLogFile
    }
    
    # Verifier que le fichier de sauvegarde a ete cree
    $backupFile = "$testLogFile.1"
    $backupExists = Test-Path -Path $backupFile
    $result3 = Assert-Condition -Condition $backupExists -Message "Le fichier de sauvegarde a ete cree"
    
    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force
    
    return $result1 -and $result2 -and $result3
}

# Executer les tests
Write-Host "Execution des tests d'integration pour les fonctions de journalisation..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------" -ForegroundColor Cyan

Write-Host "`nTest des fonctions de rotation des journaux:" -ForegroundColor Yellow
$rotationResult = Test-LogRotationFunctions

Write-Host "`nTest des fonctions de verbosite configurable:" -ForegroundColor Yellow
$verbosityResult = Test-VerbosityFunctions

Write-Host "`nTest d'integration des fonctions:" -ForegroundColor Yellow
$integrationResult = Test-LoggingIntegration

# Afficher le resume
Write-Host "`nResume des tests:" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan
$totalTests = 3
$passedTests = @($rotationResult, $verbosityResult, $integrationResult).Where({ $_ -eq $true }).Count

if ($passedTests -eq $totalTests) {
    Write-Host "Tests reussis: $passeddevelopment/testing/tests/$totalTests" -ForegroundColor Green
}
else {
    Write-Host "Tests reussis: $passeddevelopment/testing/tests/$totalTests" -ForegroundColor Red
}
