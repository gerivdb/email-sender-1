# Script de test pour vérifier la fonction Initialize-EncodingSettings dans un environnement réel
# Ce script teste la fonction avec des cas d'utilisation réels

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser l'encodage
$encodingResult = Initialize-EncodingSettings -Verbose
Write-Host "Encodage initialisé avec succès: $($encodingResult.Success)" -ForegroundColor $(if ($encodingResult.Success) { "Green" } else { "Red" })
Write-Host ""

# Test 1: Écrire et lire un fichier avec des caractères accentués
Write-Host "=== Test 1: Écrire et lire un fichier avec des caractères accentués ===" -ForegroundColor Cyan
$tempFile1 = Join-Path -Path $env:TEMP -ChildPath "test_encoding_real_1_$(Get-Random).txt"
$testString1 = @"
Fichier de test avec des caractères accentués
============================================

Voici quelques exemples de caractères accentués:
- éèêëàâäùûüôöçÉÈÊËÀÂÄÙÛÜÔÖÇ
- æœÆŒ
- ñÑ
- åÅ
- øØ

Et quelques symboles:
- €£¥$¢
- ©®™
- §¶†‡
- «»""''
"@

# Écrire dans le fichier
$testString1 | Out-File -FilePath $tempFile1
Write-Host "Fichier écrit: $tempFile1" -ForegroundColor Yellow

# Lire le contenu du fichier
$content1 = Get-Content -Path $tempFile1 -Raw
Write-Host "Contenu lu: $content1" -ForegroundColor Yellow

# Vérifier que les caractères accentués sont préservés
$success1 = $content1.Trim() -eq $testString1.Trim()
Write-Host "Test réussi: $success1" -ForegroundColor $(if ($success1) { "Green" } else { "Red" })

# Nettoyer
Remove-Item -Path $tempFile1 -Force
Write-Host "Fichier temporaire supprimé" -ForegroundColor Yellow
Write-Host ""

# Test 2: Exporter et importer un CSV avec des caractères accentués
Write-Host "=== Test 2: Exporter et importer un CSV avec des caractères accentués ===" -ForegroundColor Cyan
$tempFile2 = Join-Path -Path $env:TEMP -ChildPath "test_encoding_real_2_$(Get-Random).csv"

# Créer un objet avec des caractères accentués
$data = @(
    [PSCustomObject]@{
        Nom = "Prénom"
        Prenom = "Éric"
        Adresse = "123 Rue des Chênes"
        Ville = "Montréal"
        Pays = "Québec"
    },
    [PSCustomObject]@{
        Nom = "Müller"
        Prenom = "François"
        Adresse = "456 Avenue des Érables"
        Ville = "Québec"
        Pays = "Canada"
    },
    [PSCustomObject]@{
        Nom = "Dürr"
        Prenom = "Hélène"
        Adresse = "789 Boulevard Saint-Étienne"
        Ville = "Trois-Rivières"
        Pays = "Canada"
    }
)

# Exporter les données au format CSV
$data | Export-Csv -Path $tempFile2 -NoTypeInformation
Write-Host "Fichier CSV exporté: $tempFile2" -ForegroundColor Yellow

# Importer les données du fichier CSV
$importedData = Import-Csv -Path $tempFile2
Write-Host "Données importées: $($importedData | ConvertTo-Json)" -ForegroundColor Yellow

# Vérifier que les caractères accentués sont préservés
$success2 = $importedData[0].Prenom -eq "Éric" -and $importedData[1].Nom -eq "Müller" -and $importedData[2].Adresse -eq "789 Boulevard Saint-Étienne"
Write-Host "Test réussi: $success2" -ForegroundColor $(if ($success2) { "Green" } else { "Red" })

# Nettoyer
Remove-Item -Path $tempFile2 -Force
Write-Host "Fichier temporaire supprimé" -ForegroundColor Yellow
Write-Host ""

# Test 3: Écrire et lire un fichier XML avec des caractères accentués
Write-Host "=== Test 3: Écrire et lire un fichier XML avec des caractères accentués ===" -ForegroundColor Cyan
$tempFile3 = Join-Path -Path $env:TEMP -ChildPath "test_encoding_real_3_$(Get-Random).xml"

# Créer un objet avec des caractères accentués
$xmlData = [PSCustomObject]@{
    Titre = "Données de test avec caractères accentués"
    Description = "Ce fichier contient des données de test avec des caractères accentués"
    Elements = @(
        [PSCustomObject]@{
            Nom = "Élément 1"
            Valeur = "Première valeur avec des caractères accentués"
        },
        [PSCustomObject]@{
            Nom = "Élément 2"
            Valeur = "Deuxième valeur avec des caractères accentués"
        }
    )
}

# Exporter les données au format XML
$xmlData | Export-Clixml -Path $tempFile3
Write-Host "Fichier XML exporté: $tempFile3" -ForegroundColor Yellow

# Importer les données du fichier XML
$importedXmlData = Import-Clixml -Path $tempFile3
Write-Host "Données importées: $($importedXmlData | ConvertTo-Json -Depth 3)" -ForegroundColor Yellow

# Vérifier que les caractères accentués sont préservés
$success3 = $importedXmlData.Titre -eq "Données de test avec caractères accentués" -and $importedXmlData.Elements[0].Nom -eq "Élément 1"
Write-Host "Test réussi: $success3" -ForegroundColor $(if ($success3) { "Green" } else { "Red" })

# Nettoyer
Remove-Item -Path $tempFile3 -Force
Write-Host "Fichier temporaire supprimé" -ForegroundColor Yellow
Write-Host ""

# Résumé
Write-Host "=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Test 1 (Fichier texte): $success1" -ForegroundColor $(if ($success1) { "Green" } else { "Red" })
Write-Host "Test 2 (Fichier CSV): $success2" -ForegroundColor $(if ($success2) { "Green" } else { "Red" })
Write-Host "Test 3 (Fichier XML): $success3" -ForegroundColor $(if ($success3) { "Green" } else { "Red" })
Write-Host ""
