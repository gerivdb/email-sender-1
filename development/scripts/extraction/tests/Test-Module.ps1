# Script de test simple pour vÃ©rifier que le module fonctionne correctement
Write-Host "Test du module ExtractedInfoModule..."

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModule.psm1"
Write-Host "Chargement du module depuis: $modulePath"

try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Module chargÃ© avec succÃ¨s!" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du chargement du module: $_" -ForegroundColor Red
    exit 1
}

# Tester la crÃ©ation d'une information de base
Write-Host "CrÃ©ation d'une information de base..."
try {
    $info = New-BaseExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
    Write-Host "Information crÃ©Ã©e avec succÃ¨s: $($info.Id)" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de la crÃ©ation de l'information: $_" -ForegroundColor Red
    exit 1
}

# Tester l'ajout de mÃ©tadonnÃ©es
Write-Host "Ajout de mÃ©tadonnÃ©es..."
try {
    $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
    $value = Get-ExtractedInfoMetadata -Info $info -Key "TestKey"
    if ($value -eq "TestValue") {
        Write-Host "MÃ©tadonnÃ©es ajoutÃ©es et rÃ©cupÃ©rÃ©es avec succÃ¨s!" -ForegroundColor Green
    } else {
        Write-Host "Erreur: La valeur rÃ©cupÃ©rÃ©e ($value) ne correspond pas Ã  la valeur attendue (TestValue)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors de la manipulation des mÃ©tadonnÃ©es: $_" -ForegroundColor Red
    exit 1
}

# Tester la crÃ©ation d'une collection
Write-Host "CrÃ©ation d'une collection..."
try {
    $collection = New-ExtractedInfoCollection -Name "TestCollection"
    Write-Host "Collection crÃ©Ã©e avec succÃ¨s: $($collection.Name)" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de la crÃ©ation de la collection: $_" -ForegroundColor Red
    exit 1
}

# Tester l'ajout d'informations Ã  la collection
Write-Host "Ajout d'informations Ã  la collection..."
try {
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
    if ($collection.Items.Count -eq 1) {
        Write-Host "Information ajoutÃ©e Ã  la collection avec succÃ¨s!" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le nombre d'Ã©lÃ©ments dans la collection ($($collection.Items.Count)) ne correspond pas Ã  la valeur attendue (1)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors de l'ajout d'informations Ã  la collection: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
exit 0
