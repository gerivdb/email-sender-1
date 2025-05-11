<#
.SYNOPSIS
    Script de test pour le partage des vues.

.DESCRIPTION
    Ce script teste les fonctionnalités de partage des vues, y compris
    le format d'échange, la conversion de format et la compression.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$exchangeFormatPath = Join-Path -Path $scriptDir -ChildPath "ExchangeFormat.ps1"
$viewSharingManagerPath = Join-Path -Path $scriptDir -ChildPath "ViewSharingManager.ps1"
$formatConverterPath = Join-Path -Path $scriptDir -ChildPath "FormatConverter.ps1"
$compressionManagerPath = Join-Path -Path $scriptDir -ChildPath "CompressionManager.ps1"

if (Test-Path -Path $exchangeFormatPath) {
    . $exchangeFormatPath
} else {
    throw "Le module ExchangeFormat.ps1 est requis mais n'a pas été trouvé à l'emplacement: $exchangeFormatPath"
}

if (Test-Path -Path $viewSharingManagerPath) {
    . $viewSharingManagerPath
} else {
    throw "Le module ViewSharingManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $viewSharingManagerPath"
}

if (Test-Path -Path $formatConverterPath) {
    . $formatConverterPath
} else {
    throw "Le module FormatConverter.ps1 est requis mais n'a pas été trouvé à l'emplacement: $formatConverterPath"
}

if (Test-Path -Path $compressionManagerPath) {
    . $compressionManagerPath
} else {
    throw "Le module CompressionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $compressionManagerPath"
}

# Fonction pour afficher un message formaté
function Write-TestMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $colors = @{
        Info    = "White"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Fonction pour créer un répertoire de test temporaire
function New-TestDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $env:TEMP,

        [Parameter(Mandatory = $false)]
        [string]$DirectoryName = "ViewSharingTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )

    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName

    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    return $testDir
}

# Fonction pour tester le format d'échange
function Test-ExchangeFormat {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du format d'échange" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un objet de test
    $testView = @{
        Id           = [guid]::NewGuid().ToString()
        Name         = "Vue de test"
        Description  = "Description de la vue de test"
        CreationDate = (Get-Date).ToString('o')
        Properties   = @{
            Color   = "Blue"
            Size    = 42
            Enabled = $true
        }
        Items        = @(
            @{
                Id   = 1
                Name = "Item 1"
            },
            @{
                Id   = 2
                Name = "Item 2"
            }
        )
    }

    # Créer des métadonnées de test
    $testMetadata = @{
        Author  = "Utilisateur test"
        Tags    = @("tag1", "tag2")
        Version = "1.0"
    }

    # Test 1: Créer un objet ExchangeFormat
    Write-TestMessage "Test 1: Création d'un objet ExchangeFormat" -Level "Info"

    $exchangeFormat = New-ExchangeFormat -FormatType "JSON" -Content $testView -Metadata $testMetadata

    if ($null -ne $exchangeFormat) {
        Write-TestMessage "Objet ExchangeFormat créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création de l'objet ExchangeFormat" -Level "Error"
        return
    }

    # Test 2: Sérialiser l'objet en JSON
    Write-TestMessage "Test 2: Sérialisation de l'objet en JSON" -Level "Info"

    $json = $exchangeFormat.ToJson()

    if (-not [string]::IsNullOrEmpty($json)) {
        Write-TestMessage "Objet sérialisé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la sérialisation de l'objet" -Level "Error"
        return
    }

    # Test 3: Sauvegarder l'objet dans un fichier
    Write-TestMessage "Test 3: Sauvegarde de l'objet dans un fichier" -Level "Info"

    $filePath = Join-Path -Path $testDir -ChildPath "test_exchange_format.json"
    $result = Save-ExchangeFormat -ExchangeFormat $exchangeFormat -FilePath $filePath

    if ($result) {
        Write-TestMessage "Objet sauvegardé avec succès dans: $filePath" -Level "Success"
    } else {
        Write-TestMessage "Échec de la sauvegarde de l'objet" -Level "Error"
        return
    }

    # Test 4: Charger l'objet depuis le fichier
    Write-TestMessage "Test 4: Chargement de l'objet depuis le fichier" -Level "Info"

    $loadedExchangeFormat = Import-ExchangeFormat -FilePath $filePath

    if ($null -ne $loadedExchangeFormat) {
        Write-TestMessage "Objet chargé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec du chargement de l'objet" -Level "Error"
        return
    }

    # Test 5: Vérifier l'intégrité des données
    Write-TestMessage "Test 5: Vérification de l'intégrité des données" -Level "Info"

    $originalChecksum = $exchangeFormat.Checksum
    $loadedChecksum = $loadedExchangeFormat.Checksum

    if ($originalChecksum -eq $loadedChecksum) {
        Write-TestMessage "Checksums identiques: $originalChecksum" -Level "Success"
    } else {
        Write-TestMessage "Checksums différents: Original=$originalChecksum, Chargé=$loadedChecksum" -Level "Error"
        return
    }

    # Test 6: Vérifier le contenu
    Write-TestMessage "Test 6: Vérification du contenu" -Level "Info"

    $originalContent = $exchangeFormat.Content | ConvertTo-Json -Depth 10
    $loadedContent = $loadedExchangeFormat.Content | ConvertTo-Json -Depth 10

    if ($originalContent -eq $loadedContent) {
        Write-TestMessage "Contenu identique" -Level "Success"
    } else {
        Write-TestMessage "Contenu différent" -Level "Error"
        return
    }

    Write-TestMessage "Tests du format d'échange terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le gestionnaire de partage des vues
function Test-ViewSharingManager {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du gestionnaire de partage des vues" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de partage des vues
    $options = @{
        InstanceId        = "instance_test"
        DefaultExportPath = $testDir
        Debug             = $true
    }

    $sharingManager = New-ViewSharingManager -Options $options

    if ($null -ne $sharingManager) {
        Write-TestMessage "Gestionnaire de partage des vues créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du gestionnaire de partage des vues" -Level "Error"
        return
    }

    # Créer une vue de test
    $testView = @{
        Id           = [guid]::NewGuid().ToString()
        Name         = "Vue de test"
        Description  = "Description de la vue de test"
        CreationDate = (Get-Date).ToString('o')
        Properties   = @{
            Color   = "Blue"
            Size    = 42
            Enabled = $true
        }
        Items        = @(
            @{
                Id   = 1
                Name = "Item 1"
            },
            @{
                Id   = 2
                Name = "Item 2"
            }
        )
    }

    # Créer des métadonnées de test
    $testMetadata = @{
        Author  = "Utilisateur test"
        Tags    = @("tag1", "tag2")
        Version = "1.0"
    }

    # Test 1: Exporter une vue
    Write-TestMessage "Test 1: Exportation d'une vue" -Level "Info"

    $exportPath = $sharingManager.ExportView($testView, "JSON", $testMetadata, $null)

    if (-not [string]::IsNullOrEmpty($exportPath)) {
        Write-TestMessage "Vue exportée avec succès vers: $exportPath" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'exportation de la vue" -Level "Error"
        return
    }

    # Test 2: Importer une vue
    Write-TestMessage "Test 2: Importation d'une vue" -Level "Info"

    $importedView = $sharingManager.ImportView($exportPath)

    if ($null -ne $importedView) {
        Write-TestMessage "Vue importée avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'importation de la vue" -Level "Error"
        return
    }

    # Test 3: Vérifier le contenu de la vue importée
    Write-TestMessage "Test 3: Vérification du contenu de la vue importée" -Level "Info"

    $originalId = $testView.Id
    $importedId = $importedView.Id

    if ($originalId -eq $importedId) {
        Write-TestMessage "ID identique: $originalId" -Level "Success"
    } else {
        Write-TestMessage "ID différent: Original=$originalId, Importé=$importedId" -Level "Error"
        return
    }

    # Test 4: Obtenir les métadonnées d'une vue
    Write-TestMessage "Test 4: Récupération des métadonnées d'une vue" -Level "Info"

    $metadata = $sharingManager.GetViewMetadata($exportPath)

    if ($null -ne $metadata -and $metadata.Count -gt 0) {
        Write-TestMessage "Métadonnées récupérées avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la récupération des métadonnées" -Level "Error"
        return
    }

    # Test 5: Lister les vues exportées
    Write-TestMessage "Test 5: Listage des vues exportées" -Level "Info"

    $exportedViews = $sharingManager.ListExportedViews()

    if ($null -ne $exportedViews -and $exportedViews.Count -gt 0) {
        Write-TestMessage "Vues exportées listées avec succès: $($exportedViews.Count) vue(s)" -Level "Success"
    } else {
        Write-TestMessage "Échec du listage des vues exportées" -Level "Error"
        return
    }

    Write-TestMessage "Tests du gestionnaire de partage des vues terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le convertisseur de format
function Test-FormatConverter {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du convertisseur de format" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un convertisseur de format
    $converter = New-FormatConverter -EnableDebug

    if ($null -ne $converter) {
        Write-TestMessage "Convertisseur de format créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du convertisseur de format" -Level "Error"
        return
    }

    # Créer un objet de test
    $testObject = @{
        Id         = [guid]::NewGuid().ToString()
        Name       = "Objet de test"
        Properties = @{
            Color = "Red"
            Size  = 100
        }
        Items      = @(1, 2, 3)
    }

    # Test 1: Convertir un objet en JSON
    Write-TestMessage "Test 1: Conversion d'un objet en JSON" -Level "Info"

    $jsonContent = $testObject | ConvertTo-Json -Depth 10
    $jsonPath = Join-Path -Path $testDir -ChildPath "test_object.json"
    $jsonContent | Out-File -FilePath $jsonPath -Encoding utf8

    if (Test-Path -Path $jsonPath) {
        Write-TestMessage "Objet JSON créé avec succès: $jsonPath" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création de l'objet JSON" -Level "Error"
        return
    }

    # Test 2: Convertir un fichier JSON en XML
    Write-TestMessage "Test 2: Conversion d'un fichier JSON en XML" -Level "Info"

    $xmlPath = $converter.ConvertFile($jsonPath, $null, "XML")

    if (-not [string]::IsNullOrEmpty($xmlPath) -and (Test-Path -Path $xmlPath)) {
        Write-TestMessage "Fichier JSON converti en XML avec succès: $xmlPath" -Level "Success"
    } else {
        Write-TestMessage "Échec de la conversion du fichier JSON en XML" -Level "Error"
        return
    }

    # Test 3: Convertir un contenu JSON en XML
    Write-TestMessage "Test 3: Conversion d'un contenu JSON en XML" -Level "Info"

    $jsonContent = Get-Content -Path $jsonPath -Raw
    $xmlContent = $converter.ConvertFormat($jsonContent, "JSON", "XML")

    if (-not [string]::IsNullOrEmpty($xmlContent)) {
        Write-TestMessage "Contenu JSON converti en XML avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la conversion du contenu JSON en XML" -Level "Error"
        return
    }

    # Test 4: Détecter automatiquement le format d'un contenu
    Write-TestMessage "Test 4: Détection automatique du format d'un contenu" -Level "Info"

    $detectedFormat = $converter.DetectFormat($jsonContent)

    if ($detectedFormat -eq "JSON") {
        Write-TestMessage "Format JSON détecté avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la détection du format JSON: $detectedFormat" -Level "Error"
        return
    }

    Write-TestMessage "Tests du convertisseur de format terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le gestionnaire de compression
function Test-CompressionManager {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du gestionnaire de compression" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de compression
    $compressionManager = New-CompressionManager -CompressionLevel 5 -EnableDebug

    if ($null -ne $compressionManager) {
        Write-TestMessage "Gestionnaire de compression créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du gestionnaire de compression" -Level "Error"
        return
    }

    # Créer un fichier de test
    $testContent = "Ceci est un contenu de test pour la compression. " * 100
    $testFilePath = Join-Path -Path $testDir -ChildPath "test_file.txt"
    $testContent | Out-File -FilePath $testFilePath -Encoding utf8

    if (Test-Path -Path $testFilePath) {
        $fileSize = (Get-Item -Path $testFilePath).Length
        Write-TestMessage "Fichier de test créé avec succès: $testFilePath ($fileSize octets)" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du fichier de test" -Level "Error"
        return
    }

    # Test 1: Compresser un fichier avec GZip
    Write-TestMessage "Test 1: Compression d'un fichier avec GZip" -Level "Info"

    $compressedFilePath = $compressionManager.CompressFile($testFilePath, $null, "GZIP")

    if (-not [string]::IsNullOrEmpty($compressedFilePath) -and (Test-Path -Path $compressedFilePath)) {
        $compressedFileSize = (Get-Item -Path $compressedFilePath).Length
        $compressionRatio = [math]::Round(($compressedFileSize / $fileSize) * 100, 2)
        Write-TestMessage "Fichier compressé avec succès: $compressedFilePath ($compressedFileSize octets, $compressionRatio% de l'original)" -Level "Success"
    } else {
        Write-TestMessage "Échec de la compression du fichier" -Level "Error"
        return
    }

    # Test 2: Décompresser un fichier GZip
    Write-TestMessage "Test 2: Décompression d'un fichier GZip" -Level "Info"

    $decompressedFilePath = $compressionManager.DecompressFile($compressedFilePath, "$testFilePath.decompressed", "GZIP")

    if (-not [string]::IsNullOrEmpty($decompressedFilePath) -and (Test-Path -Path $decompressedFilePath)) {
        $decompressedFileSize = (Get-Item -Path $decompressedFilePath).Length
        Write-TestMessage "Fichier décompressé avec succès: $decompressedFilePath ($decompressedFileSize octets)" -Level "Success"
    } else {
        Write-TestMessage "Échec de la décompression du fichier" -Level "Error"
        return
    }

    # Test 3: Vérifier l'intégrité des données
    Write-TestMessage "Test 3: Vérification de l'intégrité des données" -Level "Info"

    $originalContent = Get-Content -Path $testFilePath -Raw
    $decompressedContent = Get-Content -Path $decompressedFilePath -Raw

    if ($originalContent -eq $decompressedContent) {
        Write-TestMessage "Contenu identique après compression/décompression" -Level "Success"
    } else {
        Write-TestMessage "Contenu différent après compression/décompression" -Level "Error"
        return
    }

    # Test 4: Compresser des données en mémoire
    Write-TestMessage "Test 4: Compression de données en mémoire" -Level "Info"

    $testData = [System.Text.Encoding]::UTF8.GetBytes($testContent)
    $compressedData = $compressionManager.CompressData($testData, "GZIP")

    if ($null -ne $compressedData -and $compressedData.Length -gt 0) {
        $compressionRatio = [math]::Round(($compressedData.Length / $testData.Length) * 100, 2)
        Write-TestMessage "Données compressées avec succès: $($compressedData.Length) octets ($compressionRatio% de l'original)" -Level "Success"
    } else {
        Write-TestMessage "Échec de la compression des données" -Level "Error"
        return
    }

    # Test 5: Décompresser des données en mémoire
    Write-TestMessage "Test 5: Décompression de données en mémoire" -Level "Info"

    $decompressedData = $compressionManager.DecompressData($compressedData, "GZIP")

    if ($null -ne $decompressedData -and $decompressedData.Length -gt 0) {
        Write-TestMessage "Données décompressées avec succès: $($decompressedData.Length) octets" -Level "Success"
    } else {
        Write-TestMessage "Échec de la décompression des données" -Level "Error"
        return
    }

    # Test 6: Vérifier l'intégrité des données en mémoire
    Write-TestMessage "Test 6: Vérification de l'intégrité des données en mémoire" -Level "Info"

    $decompressedContent = [System.Text.Encoding]::UTF8.GetString($decompressedData)

    if ($testContent -eq $decompressedContent) {
        Write-TestMessage "Contenu identique après compression/décompression en mémoire" -Level "Success"
    } else {
        Write-TestMessage "Contenu différent après compression/décompression en mémoire" -Level "Error"
        return
    }

    Write-TestMessage "Tests du gestionnaire de compression terminés avec succès" -Level "Success"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter tous les tests
Write-TestMessage "Démarrage des tests du système de partage des vues" -Level "Info"
Test-ExchangeFormat
Test-ViewSharingManager
Test-FormatConverter
Test-CompressionManager
Write-TestMessage "Tous les tests du système de partage des vues sont terminés" -Level "Info"
