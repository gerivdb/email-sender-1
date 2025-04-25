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

Write-Host "Début des tests des fonctions de journalisation publiques..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

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

# Test 2: Tester la configuration de la journalisation
Write-Host "`nTest 2: Tester la configuration de la journalisation" -ForegroundColor Cyan

# Pas besoin de fichier temporaire pour les tests

# Obtenir la configuration
$config = Get-RoadmapLogConfiguration

# Vérifier que la configuration existe
$success = $null -ne $config

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Configuration de la journalisation: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    La configuration de journalisation n'a pas été obtenue" -ForegroundColor Red
}

# Test 3: Tester les fonctions de journalisation par niveau
Write-Host "`nTest 3: Tester les fonctions de journalisation par niveau" -ForegroundColor Cyan

# Écrire des messages de journal avec les différentes fonctions
Write-RoadmapDebug -Message "Message de débogage"
Write-RoadmapVerbose -Message "Message détaillé"
Write-RoadmapInformation -Message "Message d'information"
Write-RoadmapWarning -Message "Message d'avertissement"
Write-RoadmapError -Message "Message d'erreur"
Write-RoadmapCritical -Message "Message critique"

# Vérifier visuellement que les messages sont affichés dans la console
Write-Host "  Vérifiez que les messages ci-dessus sont affichés dans la console" -ForegroundColor Cyan

# Test 4: Tester le filtrage par niveau de journalisation
Write-Host "`nTest 4: Tester le filtrage par niveau de journalisation" -ForegroundColor Cyan

# Configurer la journalisation pour écrire uniquement les messages de niveau Warning et supérieur
Set-RoadmapLogLevel -Level Warning

# Écrire des messages de journal avec les différentes fonctions
Write-RoadmapDebug -Message "Message de débogage (ne devrait pas être affiché)"
Write-RoadmapVerbose -Message "Message détaillé (ne devrait pas être affiché)"
Write-RoadmapInformation -Message "Message d'information (ne devrait pas être affiché)"
Write-RoadmapWarning -Message "Message d'avertissement (devrait être affiché)"
Write-RoadmapError -Message "Message d'erreur (devrait être affiché)"
Write-RoadmapCritical -Message "Message critique (devrait être affiché)"

# Vérifier visuellement que seuls les messages de niveau Warning et supérieur sont affichés dans la console
Write-Host "  Vérifiez que seuls les messages d'avertissement, d'erreur et critiques sont affichés dans la console" -ForegroundColor Cyan

# Test 5: Tester les paramètres supplémentaires
Write-Host "`nTest 5: Tester les paramètres supplémentaires" -ForegroundColor Cyan

# Configurer la journalisation pour écrire tous les messages
Set-RoadmapLogLevel -Level Debug

# Écrire des messages de journal avec des paramètres supplémentaires
Write-RoadmapLog -Message "Message avec catégorie" -Category "TestCategory"
Write-RoadmapLog -Message "Message avec informations supplémentaires" -AdditionalInfo @{ "Key1" = "Value1"; "Key2" = "Value2" }
Write-RoadmapLog -Message "Message avec exception" -Exception (New-Object System.Exception "Test exception")

# Vérifier visuellement que les messages avec paramètres supplémentaires sont affichés dans la console
Write-Host "  Vérifiez que les messages avec paramètres supplémentaires sont affichés dans la console" -ForegroundColor Cyan

Write-Host "`nTests des fonctions de journalisation publiques terminés." -ForegroundColor Cyan
