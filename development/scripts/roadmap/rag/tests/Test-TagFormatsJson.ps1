# Test-TagFormatsJson.ps1
# Script de test pour le module de gestion des formats de tags avec JSON manuel

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Manage-TagFormats-Fixed.ps1"

# Définir le chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TestTagFormatsJson.config.json"

# Supprimer le fichier de configuration s'il existe déjà
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration existant supprimé" -ForegroundColor Yellow
}

# Créer un contenu JSON pour la configuration
$configJson = @"
{
    "name": "Tag Formats Configuration",
    "description": "Configuration des formats de tags",
    "version": "1.0.0",
    "updated_at": "2025-05-12T16:30:00Z",
    "tag_formats": {
        "test": {
            "name": "test",
            "description": "Tags pour test",
            "formats": [
                {
                    "name": "TestFormat1",
                    "pattern": "#test:(\\\\d+)",
                    "description": "Format de test",
                    "example": "#test:123",
                    "value_group": 1,
                    "unit": "units"
                }
            ]
        }
    }
}
"@

# Enregistrer le contenu
Set-Content -Path $testConfigPath -Value $configJson -Encoding UTF8

# Vérifier que le fichier existe
if (Test-Path -Path $testConfigPath) {
    Write-Host "Fichier de configuration créé avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de création du fichier de configuration" -ForegroundColor Red
    exit 1
}

# Charger les fonctions du script
. $scriptPath

# Test 1: Chargement de la configuration
Write-Host "Test 1: Chargement de la configuration" -ForegroundColor Cyan
$config = Get-TagFormatsConfig -ConfigPath $testConfigPath
if ($config) {
    Write-Host "La configuration a été chargée" -ForegroundColor Green
    
    # Vérifier la structure de la configuration
    if ($config.tag_formats) {
        Write-Host "La propriété tag_formats existe" -ForegroundColor Green
        
        if ($config.tag_formats.test) {
            Write-Host "Le type de tag 'test' existe" -ForegroundColor Green
            
            if ($config.tag_formats.test.formats -is [array]) {
                Write-Host "La propriété formats est un tableau" -ForegroundColor Green
                Write-Host "Nombre de formats: $($config.tag_formats.test.formats.Count)" -ForegroundColor Green
                
                $format = $config.tag_formats.test.formats | Where-Object { $_.name -eq "TestFormat1" }
                if ($format) {
                    Write-Host "Le format 'TestFormat1' existe" -ForegroundColor Green
                    Write-Host "Pattern: $($format.pattern)" -ForegroundColor Gray
                } else {
                    Write-Host "Le format 'TestFormat1' n'existe pas" -ForegroundColor Red
                }
            } else {
                Write-Host "La propriété formats n'est pas un tableau" -ForegroundColor Red
                Write-Host "Type: $($config.tag_formats.test.formats.GetType().FullName)" -ForegroundColor Gray
            }
        } else {
            Write-Host "Le type de tag 'test' n'existe pas" -ForegroundColor Red
        }
    } else {
        Write-Host "La propriété tag_formats n'existe pas" -ForegroundColor Red
    }
} else {
    Write-Host "Échec de chargement de la configuration" -ForegroundColor Red
}

# Test 2: Récupération d'un format de tag
Write-Host "Test 2: Récupération d'un format de tag" -ForegroundColor Cyan
$format = Get-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1"
if ($format) {
    Write-Host "Le format a été récupéré" -ForegroundColor Green
    Write-Host "Nom: $($format.name)" -ForegroundColor Gray
    Write-Host "Pattern: $($format.pattern)" -ForegroundColor Gray
} else {
    Write-Host "Échec de récupération du format" -ForegroundColor Red
}

# Test 3: Mise à jour d'un format de tag
Write-Host "Test 3: Mise à jour d'un format de tag" -ForegroundColor Cyan
$result = Update-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1" -Description "Description mise à jour"
if ($result) {
    Write-Host "Le format a été mis à jour" -ForegroundColor Green
    
    # Vérifier la mise à jour
    $updatedFormat = Get-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1"
    if ($updatedFormat.description -eq "Description mise à jour") {
        Write-Host "La description a été mise à jour" -ForegroundColor Green
    } else {
        Write-Host "La description n'a pas été mise à jour" -ForegroundColor Red
        Write-Host "Attendu: Description mise à jour" -ForegroundColor Yellow
        Write-Host "Obtenu: $($updatedFormat.description)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Échec de mise à jour du format" -ForegroundColor Red
}

# Test 4: Suppression d'un format de tag
Write-Host "Test 4: Suppression d'un format de tag" -ForegroundColor Cyan
$result = Remove-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1"
if ($result) {
    Write-Host "Le format a été supprimé" -ForegroundColor Green
    
    # Vérifier la suppression
    $deletedFormat = Get-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1"
    if (-not $deletedFormat) {
        Write-Host "Le format a bien été supprimé" -ForegroundColor Green
    } else {
        Write-Host "Le format n'a pas été supprimé" -ForegroundColor Red
    }
} else {
    Write-Host "Échec de suppression du format" -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration de test supprimé" -ForegroundColor Yellow
}

Write-Host "Tests terminés" -ForegroundColor Cyan
