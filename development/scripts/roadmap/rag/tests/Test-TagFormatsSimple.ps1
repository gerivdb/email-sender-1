# Test-TagFormatsSimple.ps1
# Script de test simplifié pour le module de gestion des formats de tags

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Manage-TagFormats.ps1"

# Définir le chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TestTagFormatsSimple.config.json"

# Supprimer le fichier de configuration s'il existe déjà
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration existant supprimé" -ForegroundColor Yellow
}

# Charger les fonctions du script
. $scriptPath

Write-Host "Test 1: Création d'un fichier de configuration" -ForegroundColor Cyan
$config = Get-TagFormatsConfig -ConfigPath $testConfigPath -CreateIfNotExists
if ($config) {
    Write-Host "Configuration créée avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de création de la configuration" -ForegroundColor Red
}

Write-Host "Test 2: Ajout d'un format de tag" -ForegroundColor Cyan
$result = Add-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1" -Pattern "#test:(\\d+)" -Description "Format de test" -Example "#test:123" -Unit "units" -ValueGroup 1
if ($result) {
    Write-Host "Format ajouté avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec d'ajout du format" -ForegroundColor Red
}

Write-Host "Test 3: Sauvegarde de la configuration" -ForegroundColor Cyan
$result = Save-TagFormatsConfig -Config $config -ConfigPath $testConfigPath
if ($result) {
    Write-Host "Configuration sauvegardée avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de sauvegarde de la configuration" -ForegroundColor Red
}

Write-Host "Test 4: Chargement de la configuration" -ForegroundColor Cyan
$loadedConfig = Get-TagFormatsConfig -ConfigPath $testConfigPath
if ($loadedConfig) {
    Write-Host "Configuration chargée avec succès" -ForegroundColor Green
    Write-Host "Structure de la configuration:" -ForegroundColor Gray
    $loadedConfig | ConvertTo-Json -Depth 5 | Write-Host

    Write-Host "Propriétés disponibles:" -ForegroundColor Gray
    $loadedConfig | Get-Member | Format-Table -Property Name, MemberType | Out-String | Write-Host

    Write-Host "Vérification de la propriété tag_formats:" -ForegroundColor Gray
    if ($loadedConfig.tag_formats) {
        Write-Host "La propriété tag_formats existe" -ForegroundColor Green
        Write-Host "Types de tags disponibles:" -ForegroundColor Gray
        $loadedConfig.tag_formats | Get-Member -MemberType NoteProperty | Format-Table -Property Name | Out-String | Write-Host
    } else {
        Write-Host "La propriété tag_formats n'existe pas" -ForegroundColor Red
    }
} else {
    Write-Host "Échec de chargement de la configuration" -ForegroundColor Red
}

Write-Host "Test 5: Récupération d'un format de tag" -ForegroundColor Cyan
$format = Get-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
if ($format) {
    Write-Host "Format récupéré avec succès" -ForegroundColor Green
    Write-Host "Nom: $($format.name)" -ForegroundColor Gray
    Write-Host "Pattern: $($format.pattern)" -ForegroundColor Gray
} else {
    Write-Host "Échec de récupération du format" -ForegroundColor Red
}

Write-Host "Test 6: Mise à jour d'un format de tag" -ForegroundColor Cyan
$result = Update-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1" -Description "Description mise à jour"
if ($result) {
    Write-Host "Format mis à jour avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de mise à jour du format" -ForegroundColor Red
}

Write-Host "Test 7: Suppression d'un format de tag" -ForegroundColor Cyan
$result = Remove-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
if ($result) {
    Write-Host "Format supprimé avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de suppression du format" -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration de test supprimé" -ForegroundColor Yellow
}
