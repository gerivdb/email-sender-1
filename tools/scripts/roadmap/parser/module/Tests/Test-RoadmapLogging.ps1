#
# Test-RoadmapLogging.ps1
#
# Script pour tester les fonctions de journalisation publiques
#

# Importer le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$modulePsdPath = Join-Path -Path $modulePath -ChildPath "RoadmapParser.psd1"

# Importer le module
Import-Module -Name $modulePsdPath -Force

Write-Host "DÃ©but des tests des fonctions de journalisation publiques..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que les fonctions sont dÃ©finies
Write-Host "`nTest 1: VÃ©rifier que les fonctions sont dÃ©finies" -ForegroundColor Cyan

$functions = @(
    "Set-RoadmapLogLevel",
    "Get-RoadmapLogConfiguration",
    "Set-RoadmapLogDestination",
    "Set-RoadmapLogFormat",
    "Write-RoadmapLog",
    "Write-RoadmapDebug",
    "Write-RoadmapVerbose",
    "Write-RoadmapInformation",
    "Write-RoadmapWarning",
    "Write-RoadmapError",
    "Write-RoadmapCritical"
)

$successCount = 0
$failureCount = 0

foreach ($function in $functions) {
    $command = Get-Command -Name $function -ErrorAction SilentlyContinue
    $success = $null -ne $command

    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  VÃ©rification de la fonction $function : $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    La fonction $function n'est pas dÃ©finie" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Tester la configuration de la journalisation
Write-Host "`nTest 2: Tester la configuration de la journalisation" -ForegroundColor Cyan

# Pas besoin de fichier temporaire pour les tests

# Obtenir la configuration
$config = Get-RoadmapLogConfiguration

# VÃ©rifier que la configuration existe
$success = $null -ne $config

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Configuration de la journalisation: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    La configuration de journalisation n'a pas Ã©tÃ© obtenue" -ForegroundColor Red
}

# Test 3: Tester les fonctions de journalisation par niveau
Write-Host "`nTest 3: Tester les fonctions de journalisation par niveau" -ForegroundColor Cyan

# Ã‰crire des messages de journal avec les diffÃ©rentes fonctions
Write-RoadmapDebug -Message "Message de dÃ©bogage"
Write-RoadmapVerbose -Message "Message dÃ©taillÃ©"
Write-RoadmapInformation -Message "Message d'information"
Write-RoadmapWarning -Message "Message d'avertissement"
Write-RoadmapError -Message "Message d'erreur"
Write-RoadmapCritical -Message "Message critique"

# VÃ©rifier visuellement que les messages sont affichÃ©s dans la console
Write-Host "  VÃ©rifiez que les messages ci-dessus sont affichÃ©s dans la console" -ForegroundColor Cyan

# Test 4: Tester le filtrage par niveau de journalisation
Write-Host "`nTest 4: Tester le filtrage par niveau de journalisation" -ForegroundColor Cyan

# Configurer la journalisation pour Ã©crire uniquement les messages de niveau Warning et supÃ©rieur
Set-RoadmapLogLevel -Level Warning

# Ã‰crire des messages de journal avec les diffÃ©rentes fonctions
Write-RoadmapDebug -Message "Message de dÃ©bogage (ne devrait pas Ãªtre affichÃ©)"
Write-RoadmapVerbose -Message "Message dÃ©taillÃ© (ne devrait pas Ãªtre affichÃ©)"
Write-RoadmapInformation -Message "Message d'information (ne devrait pas Ãªtre affichÃ©)"
Write-RoadmapWarning -Message "Message d'avertissement (devrait Ãªtre affichÃ©)"
Write-RoadmapError -Message "Message d'erreur (devrait Ãªtre affichÃ©)"
Write-RoadmapCritical -Message "Message critique (devrait Ãªtre affichÃ©)"

# VÃ©rifier visuellement que seuls les messages de niveau Warning et supÃ©rieur sont affichÃ©s dans la console
Write-Host "  VÃ©rifiez que seuls les messages d'avertissement, d'erreur et critiques sont affichÃ©s dans la console" -ForegroundColor Cyan

# Test 5: Tester les paramÃ¨tres supplÃ©mentaires
Write-Host "`nTest 5: Tester les paramÃ¨tres supplÃ©mentaires" -ForegroundColor Cyan

# Configurer la journalisation pour Ã©crire tous les messages
Set-RoadmapLogLevel -Level Debug

# Ã‰crire des messages de journal avec des paramÃ¨tres supplÃ©mentaires
Write-RoadmapLog -Message "Message avec catÃ©gorie" -Category "TestCategory"
Write-RoadmapLog -Message "Message avec informations supplÃ©mentaires" -AdditionalInfo @{ "Key1" = "Value1"; "Key2" = "Value2" }
Write-RoadmapLog -Message "Message avec exception" -Exception (New-Object System.Exception "Test exception")

# VÃ©rifier visuellement que les messages avec paramÃ¨tres supplÃ©mentaires sont affichÃ©s dans la console
Write-Host "  VÃ©rifiez que les messages avec paramÃ¨tres supplÃ©mentaires sont affichÃ©s dans la console" -ForegroundColor Cyan

Write-Host "`nTests des fonctions de journalisation publiques terminÃ©s." -ForegroundColor Cyan
