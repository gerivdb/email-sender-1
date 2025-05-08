# Configuration-Examples.ps1
# Exemples d'utilisation des fonctions de configuration avancées

# Importer le module
Import-Module "$PSScriptRoot\..\ExtractedInfoModule.psm1" -Force

# Afficher la configuration actuelle
Write-Host "Configuration actuelle :" -ForegroundColor Cyan
$config = Get-ExtractedInfoConfiguration
$config | ConvertTo-Json -Depth 5

# Modifier une valeur de configuration simple
Write-Host "`nModification d'une valeur de configuration simple :" -ForegroundColor Cyan
Set-ExtractedInfoConfiguration -Key "DefaultLanguage" -Value "en"
Write-Host "Nouvelle langue par défaut : $(Get-ExtractedInfoConfiguration -Key "DefaultLanguage")"

# Modifier une valeur de configuration avancée
Write-Host "`nModification d'une valeur de configuration avancée :" -ForegroundColor Cyan
$loggingConfig = $config.AdvancedOptions.Logging
$loggingConfig.Level = "Debug"
$loggingConfig.LogToFile = $true
Set-ExtractedInfoConfiguration -Key "AdvancedOptions.Logging" -Value $loggingConfig
Write-Host "Nouvelle configuration de journalisation :"
Get-ExtractedInfoConfiguration -Key "AdvancedOptions.Logging" | ConvertTo-Json

# Exporter la configuration vers un fichier
Write-Host "`nExportation de la configuration vers un fichier :" -ForegroundColor Cyan
$exportPath = "$PSScriptRoot\exported-config.json"
Export-ExtractedInfoConfiguration -Path $exportPath -Format "JSON" -Force -IncludeTimestamp
Write-Host "Configuration exportée vers $exportPath"

# Modifier complètement la configuration
Write-Host "`nModification complète de la configuration :" -ForegroundColor Cyan
$newConfig = @{
    DefaultSerializationFormat = "Xml"
    DefaultValidationEnabled = $true
    DefaultConfidenceThreshold = 90
    DefaultLanguage = "fr"
    AdvancedOptions = @{
        Performance = @{
            EnableParallelProcessing = $true
            MaxParallelJobs = 8
        }
        Logging = @{
            Enabled = $true
            Level = "Warning"
        }
    }
}
Set-ExtractedInfoConfiguration -Config $newConfig
Write-Host "Nouvelle configuration :"
Get-ExtractedInfoConfiguration | ConvertTo-Json -Depth 3

# Réinitialiser la configuration
Write-Host "`nRéinitialisation de la configuration :" -ForegroundColor Cyan
Initialize-ExtractedInfoConfiguration
Write-Host "Configuration réinitialisée"

# Importer la configuration depuis un fichier personnalisé
Write-Host "`nImportation de la configuration depuis un fichier personnalisé :" -ForegroundColor Cyan
Import-ExtractedInfoConfiguration -Path $exportPath -Merge
Write-Host "Configuration importée depuis $exportPath"

# Définir une variable d'environnement pour la configuration
Write-Host "`nDéfinition d'une variable d'environnement pour la configuration :" -ForegroundColor Cyan
$env:EXTRACTEDINFO_DefaultLanguage = "es"
$env:EXTRACTEDINFO_AdvancedOptions_Logging_Level = "Error"

# Importer la configuration depuis les variables d'environnement
Write-Host "`nImportation de la configuration depuis les variables d'environnement :" -ForegroundColor Cyan
Import-ExtractedInfoConfigurationFromEnv -Merge
Write-Host "Nouvelle langue par défaut : $(Get-ExtractedInfoConfiguration -Key "DefaultLanguage")"
Write-Host "Nouveau niveau de journalisation : $(Get-ExtractedInfoConfiguration -Key "AdvancedOptions.Logging.Level")"

# Nettoyer les variables d'environnement
Remove-Item -Path "Env:EXTRACTEDINFO_DefaultLanguage"
Remove-Item -Path "Env:EXTRACTEDINFO_AdvancedOptions_Logging_Level"

# Exemple d'utilisation des options avancées dans le code
Write-Host "`nExemple d'utilisation des options avancées dans le code :" -ForegroundColor Cyan

# Créer une information extraite
$info = New-BaseExtractedInfo -Source "example.txt" -ExtractorName "ExampleExtractor"

# Vérifier si la validation est activée
$validationEnabled = Get-ExtractedInfoConfiguration -Key "DefaultValidationEnabled"
if ($validationEnabled) {
    Write-Host "La validation est activée, validation de l'information..."
    # Code de validation ici
}

# Vérifier si le traitement parallèle est activé
$parallelEnabled = Get-ExtractedInfoConfiguration -Key "AdvancedOptions.Performance.EnableParallelProcessing"
if ($parallelEnabled) {
    $maxJobs = Get-ExtractedInfoConfiguration -Key "AdvancedOptions.Performance.MaxParallelJobs"
    Write-Host "Le traitement parallèle est activé avec $maxJobs jobs maximum"
    # Code de traitement parallèle ici
}

# Journalisation selon le niveau configuré
$loggingEnabled = Get-ExtractedInfoConfiguration -Key "AdvancedOptions.Logging.Enabled"
$loggingLevel = Get-ExtractedInfoConfiguration -Key "AdvancedOptions.Logging.Level"
if ($loggingEnabled) {
    Write-Host "Journalisation activée au niveau $loggingLevel"
    # Code de journalisation ici
}

# Sérialisation selon le format configuré
$serializationFormat = Get-ExtractedInfoConfiguration -Key "DefaultSerializationFormat"
Write-Host "Sérialisation au format $serializationFormat"
# Code de sérialisation ici

Write-Host "`nExemples terminés" -ForegroundColor Green
