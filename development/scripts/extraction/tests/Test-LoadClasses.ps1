# Script pour tester le chargement des classes
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$modelsPath = Join-Path -Path $rootPath -ChildPath "models"
$interfacesPath = Join-Path -Path $rootPath -ChildPath "interfaces"
$convertersPath = Join-Path -Path $rootPath -ChildPath "converters"

function Test-LoadClass {
    param (
        [string]$Path,
        [string]$Name
    )
    
    Write-Host "Chargement de $Name... " -NoNewline
    try {
        . $Path
        Write-Host "OK" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ECHEC" -ForegroundColor Red
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Tester le chargement des classes de base
$success = $true
$success = $success -and (Test-LoadClass -Path "$modelsPath\BaseExtractedInfo.ps1" -Name "BaseExtractedInfo")
$success = $success -and (Test-LoadClass -Path "$modelsPath\ExtractedInfoCollection.ps1" -Name "ExtractedInfoCollection")

# Tester le chargement des interfaces
$success = $success -and (Test-LoadClass -Path "$interfacesPath\ISerializable.ps1" -Name "ISerializable")
$success = $success -and (Test-LoadClass -Path "$interfacesPath\IValidatable.ps1" -Name "IValidatable")

# Tester le chargement des classes de sÃ©rialisation et validation
$success = $success -and (Test-LoadClass -Path "$modelsPath\SerializableExtractedInfo.ps1" -Name "SerializableExtractedInfo")
$success = $success -and (Test-LoadClass -Path "$modelsPath\ValidationRule.ps1" -Name "ValidationRule")
$success = $success -and (Test-LoadClass -Path "$modelsPath\ValidatableExtractedInfo.ps1" -Name "ValidatableExtractedInfo")

# Tester le chargement des classes spÃ©cifiques
$success = $success -and (Test-LoadClass -Path "$modelsPath\TextExtractedInfo.ps1" -Name "TextExtractedInfo")
$success = $success -and (Test-LoadClass -Path "$modelsPath\StructuredDataExtractedInfo.ps1" -Name "StructuredDataExtractedInfo")
$success = $success -and (Test-LoadClass -Path "$modelsPath\MediaExtractedInfo.ps1" -Name "MediaExtractedInfo")

# Tester le chargement des convertisseurs
$success = $success -and (Test-LoadClass -Path "$convertersPath\FormatConverter.ps1" -Name "FormatConverter")
$success = $success -and (Test-LoadClass -Path "$convertersPath\ExtractedInfoConverter.ps1" -Name "ExtractedInfoConverter")

# Afficher le rÃ©sultat final
if ($success) {
    Write-Host "`nToutes les classes ont Ã©tÃ© chargÃ©es avec succÃ¨s!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertaines classes n'ont pas pu Ãªtre chargÃ©es." -ForegroundColor Red
    exit 1
}
