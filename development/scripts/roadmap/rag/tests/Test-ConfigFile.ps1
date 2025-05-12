# Test-ConfigFile.ps1
# Script de test pour la création et la lecture d'un fichier de configuration

# Définir le chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TestConfig.json"

# Supprimer le fichier de configuration s'il existe déjà
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration existant supprimé" -ForegroundColor Yellow
}

# Créer un objet de configuration
$config = @{
    name = "Test Configuration"
    description = "Configuration de test"
    version = "1.0.0"
    updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    tag_formats = @{
        test = @{
            name = "test"
            description = "Tags pour test"
            formats = @(
                @{
                    name = "TestFormat1"
                    pattern = "#test:(\\d+)"
                    description = "Format de test"
                    example = "#test:123"
                    value_group = 1
                    unit = "units"
                }
            )
        }
    }
}

# Convertir en JSON et enregistrer
$configJson = ConvertTo-Json -InputObject $config -Depth 10
Set-Content -Path $testConfigPath -Value $configJson -Encoding UTF8

# Vérifier que le fichier existe
if (Test-Path -Path $testConfigPath) {
    Write-Host "Fichier de configuration créé avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de création du fichier de configuration" -ForegroundColor Red
    exit 1
}

# Lire le fichier de configuration
$loadedJson = Get-Content -Path $testConfigPath -Raw
$loadedConfig = ConvertFrom-Json -InputObject $loadedJson

# Vérifier la structure de la configuration chargée
Write-Host "Structure de la configuration chargée:" -ForegroundColor Cyan
$loadedConfig | ConvertTo-Json -Depth 10 | Write-Host

# Vérifier si la propriété tag_formats existe
if ($loadedConfig.tag_formats) {
    Write-Host "La propriété tag_formats existe" -ForegroundColor Green
    
    # Vérifier si le type de tag 'test' existe
    if ($loadedConfig.tag_formats.test) {
        Write-Host "Le type de tag 'test' existe" -ForegroundColor Green
        
        # Vérifier si la propriété formats existe
        if ($loadedConfig.tag_formats.test.formats) {
            Write-Host "La propriété formats existe" -ForegroundColor Green
            Write-Host "Type de formats: $($loadedConfig.tag_formats.test.formats.GetType().FullName)" -ForegroundColor Gray
            
            # Vérifier si formats est un tableau
            if ($loadedConfig.tag_formats.test.formats -is [array]) {
                Write-Host "La propriété formats est un tableau" -ForegroundColor Green
                Write-Host "Nombre de formats: $($loadedConfig.tag_formats.test.formats.Count)" -ForegroundColor Green
                
                # Vérifier si le format 'TestFormat1' existe
                $format = $loadedConfig.tag_formats.test.formats | Where-Object { $_.name -eq "TestFormat1" }
                if ($format) {
                    Write-Host "Le format 'TestFormat1' existe" -ForegroundColor Green
                    Write-Host "Pattern: $($format.pattern)" -ForegroundColor Gray
                } else {
                    Write-Host "Le format 'TestFormat1' n'existe pas" -ForegroundColor Red
                }
            } else {
                Write-Host "La propriété formats n'est pas un tableau" -ForegroundColor Red
                Write-Host "Valeur: $($loadedConfig.tag_formats.test.formats)" -ForegroundColor Gray
            }
        } else {
            Write-Host "La propriété formats n'existe pas" -ForegroundColor Red
        }
    } else {
        Write-Host "Le type de tag 'test' n'existe pas" -ForegroundColor Red
    }
} else {
    Write-Host "La propriété tag_formats n'existe pas" -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration de test supprimé" -ForegroundColor Yellow
}

Write-Host "Test terminé" -ForegroundColor Cyan
