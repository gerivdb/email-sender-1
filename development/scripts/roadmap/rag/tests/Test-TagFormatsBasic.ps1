# Test-TagFormatsBasic.ps1
# Script de test basique pour le module de gestion des formats de tags

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Manage-TagFormats-Fixed.ps1"

# Définir le chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TestTagFormatsBasic.config.json"

# Supprimer le fichier de configuration s'il existe déjà
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration existant supprimé" -ForegroundColor Yellow
}

# Charger les fonctions du script
. $scriptPath

# Test 1: Création d'un fichier de configuration
Write-Host "Test 1: Création d'un fichier de configuration" -ForegroundColor Cyan
$config = Get-TagFormatsConfig -ConfigPath $testConfigPath -CreateIfNotExists
if ($config) {
    Write-Host "✓ La configuration a été créée" -ForegroundColor Green
} else {
    Write-Host "✗ Échec de création de la configuration" -ForegroundColor Red
}

# Test 2: Ajout d'un format de tag
Write-Host "Test 2: Ajout d'un format de tag" -ForegroundColor Cyan
$result = Add-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1" -Pattern "#test:(\\d+)" -Description "Format de test" -Example "#test:123" -Unit "units" -ValueGroup 1
if ($result) {
    Write-Host "✓ Le format a été ajouté" -ForegroundColor Green
} else {
    Write-Host "✗ Échec d'ajout du format" -ForegroundColor Red
}

# Test 3: Sauvegarde de la configuration
Write-Host "Test 3: Sauvegarde de la configuration" -ForegroundColor Cyan
$result = Save-TagFormatsConfig -Config $config -ConfigPath $testConfigPath
if ($result) {
    Write-Host "✓ La configuration a été sauvegardée" -ForegroundColor Green
} else {
    Write-Host "✗ Échec de sauvegarde de la configuration" -ForegroundColor Red
}

# Test 4: Chargement de la configuration
Write-Host "Test 4: Chargement de la configuration" -ForegroundColor Cyan
$loadedConfig = Get-TagFormatsConfig -ConfigPath $testConfigPath
if ($loadedConfig) {
    Write-Host "✓ La configuration a été chargée" -ForegroundColor Green
    
    if ($loadedConfig.tag_formats) {
        Write-Host "✓ La propriété tag_formats existe dans la configuration chargée" -ForegroundColor Green
    } else {
        Write-Host "✗ La propriété tag_formats n'existe pas dans la configuration chargée" -ForegroundColor Red
    }
    
    if ($loadedConfig.tag_formats.test) {
        Write-Host "✓ Le type de tag 'test' existe dans la configuration chargée" -ForegroundColor Green
    } else {
        Write-Host "✗ Le type de tag 'test' n'existe pas dans la configuration chargée" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Échec de chargement de la configuration" -ForegroundColor Red
}

# Test 5: Récupération d'un format de tag
Write-Host "Test 5: Récupération d'un format de tag" -ForegroundColor Cyan
$format = Get-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
if ($format) {
    Write-Host "✓ Le format a été récupéré" -ForegroundColor Green
    
    if ($format.name -eq "TestFormat1") {
        Write-Host "✓ Le nom du format est correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Le nom du format est incorrect" -ForegroundColor Red
        Write-Host "  Attendu: TestFormat1" -ForegroundColor Yellow
        Write-Host "  Obtenu: $($format.name)" -ForegroundColor Yellow
    }
    
    if ($format.pattern -eq "#test:(\\d+)") {
        Write-Host "✓ Le pattern du format est correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Le pattern du format est incorrect" -ForegroundColor Red
        Write-Host "  Attendu: #test:(\\d+)" -ForegroundColor Yellow
        Write-Host "  Obtenu: $($format.pattern)" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Échec de récupération du format" -ForegroundColor Red
}

# Test 6: Mise à jour d'un format de tag
Write-Host "Test 6: Mise à jour d'un format de tag" -ForegroundColor Cyan
$result = Update-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1" -Description "Description mise à jour"
if ($result) {
    Write-Host "✓ Le format a été mis à jour" -ForegroundColor Green
    
    # Vérifier la mise à jour
    $updatedFormat = Get-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
    if ($updatedFormat.description -eq "Description mise à jour") {
        Write-Host "✓ La description a été mise à jour" -ForegroundColor Green
    } else {
        Write-Host "✗ La description n'a pas été mise à jour" -ForegroundColor Red
        Write-Host "  Attendu: Description mise à jour" -ForegroundColor Yellow
        Write-Host "  Obtenu: $($updatedFormat.description)" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Échec de mise à jour du format" -ForegroundColor Red
}

# Test 7: Suppression d'un format de tag
Write-Host "Test 7: Suppression d'un format de tag" -ForegroundColor Cyan
$result = Remove-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
if ($result) {
    Write-Host "✓ Le format a été supprimé" -ForegroundColor Green
} else {
    Write-Host "✗ Échec de suppression du format" -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration de test supprimé" -ForegroundColor Yellow
}

Write-Host "Tests terminés" -ForegroundColor Cyan
