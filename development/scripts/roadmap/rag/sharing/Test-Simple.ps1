<#
.SYNOPSIS
    Test simple pour le partage des vues.

.DESCRIPTION
    Ce script teste les fonctionnalités de base du partage des vues.

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

if (Test-Path -Path $exchangeFormatPath) {
    . $exchangeFormatPath
}
else {
    throw "Le module ExchangeFormat.ps1 est requis mais n'a pas été trouvé à l'emplacement: $exchangeFormatPath"
}

if (Test-Path -Path $viewSharingManagerPath) {
    . $viewSharingManagerPath
}
else {
    throw "Le module ViewSharingManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $viewSharingManagerPath"
}

# Créer un répertoire de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ViewSharingTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Cyan

# Créer un objet de test
$testView = @{
    Id = [guid]::NewGuid().ToString()
    Name = "Vue de test"
    Description = "Description de la vue de test"
    CreationDate = (Get-Date).ToString('o')
    Properties = @{
        Color = "Blue"
        Size = 42
        Enabled = $true
    }
    Items = @(
        @{
            Id = 1
            Name = "Item 1"
        },
        @{
            Id = 2
            Name = "Item 2"
        }
    )
}

# Créer des métadonnées de test
$testMetadata = @{
    Author = "Utilisateur test"
    Tags = @("tag1", "tag2")
    Version = "1.0"
}

# Test 1: Créer un objet ExchangeFormat
Write-Host "Test 1: Création d'un objet ExchangeFormat" -ForegroundColor Cyan
$exchangeFormat = New-ExchangeFormat -FormatType "JSON" -Content $testView -Metadata $testMetadata

if ($null -ne $exchangeFormat) {
    Write-Host "Objet ExchangeFormat créé avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de la création de l'objet ExchangeFormat" -ForegroundColor Red
    exit 1
}

# Test 2: Sérialiser l'objet en JSON
Write-Host "Test 2: Sérialisation de l'objet en JSON" -ForegroundColor Cyan
$json = $exchangeFormat.ToJson()

if (-not [string]::IsNullOrEmpty($json)) {
    Write-Host "Objet sérialisé avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de la sérialisation de l'objet" -ForegroundColor Red
    exit 1
}

# Test 3: Sauvegarder l'objet dans un fichier
Write-Host "Test 3: Sauvegarde de l'objet dans un fichier" -ForegroundColor Cyan
$filePath = Join-Path -Path $testDir -ChildPath "test_exchange_format.json"
$result = Save-ExchangeFormat -ExchangeFormat $exchangeFormat -FilePath $filePath

if ($result) {
    Write-Host "Objet sauvegardé avec succès dans: $filePath" -ForegroundColor Green
}
else {
    Write-Host "Échec de la sauvegarde de l'objet" -ForegroundColor Red
    exit 1
}

# Test 4: Charger l'objet depuis le fichier
Write-Host "Test 4: Chargement de l'objet depuis le fichier" -ForegroundColor Cyan
$loadedExchangeFormat = Import-ExchangeFormat -FilePath $filePath

if ($null -ne $loadedExchangeFormat) {
    Write-Host "Objet chargé avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec du chargement de l'objet" -ForegroundColor Red
    exit 1
}

# Test 5: Vérifier l'intégrité des données
Write-Host "Test 5: Vérification de l'intégrité des données" -ForegroundColor Cyan
$originalChecksum = $exchangeFormat.Checksum
$loadedChecksum = $loadedExchangeFormat.Checksum

if ($originalChecksum -eq $loadedChecksum) {
    Write-Host "Checksums identiques: $originalChecksum" -ForegroundColor Green
}
else {
    Write-Host "Checksums différents: Original=$originalChecksum, Chargé=$loadedChecksum" -ForegroundColor Red
    exit 1
}

# Test 6: Créer un gestionnaire de partage des vues
Write-Host "Test 6: Création d'un gestionnaire de partage des vues" -ForegroundColor Cyan
$options = @{
    InstanceId = "instance_test"
    DefaultExportPath = $testDir
    Debug = $true
}

$sharingManager = New-ViewSharingManager -Options $options

if ($null -ne $sharingManager) {
    Write-Host "Gestionnaire de partage des vues créé avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de la création du gestionnaire de partage des vues" -ForegroundColor Red
    exit 1
}

# Test 7: Exporter une vue
Write-Host "Test 7: Exportation d'une vue" -ForegroundColor Cyan
$exportPath = $sharingManager.ExportView($testView, "JSON", $testMetadata, $null)

if (-not [string]::IsNullOrEmpty($exportPath)) {
    Write-Host "Vue exportée avec succès vers: $exportPath" -ForegroundColor Green
}
else {
    Write-Host "Échec de l'exportation de la vue" -ForegroundColor Red
    exit 1
}

# Test 8: Importer une vue
Write-Host "Test 8: Importation d'une vue" -ForegroundColor Cyan
$importedView = $sharingManager.ImportView($exportPath)

if ($null -ne $importedView) {
    Write-Host "Vue importée avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de l'importation de la vue" -ForegroundColor Red
    exit 1
}

# Test 9: Vérifier le contenu de la vue importée
Write-Host "Test 9: Vérification du contenu de la vue importée" -ForegroundColor Cyan
$originalId = $testView.Id
$importedId = $importedView.Id

if ($originalId -eq $importedId) {
    Write-Host "ID identique: $originalId" -ForegroundColor Green
}
else {
    Write-Host "ID différent: Original=$originalId, Importé=$importedId" -ForegroundColor Red
    exit 1
}

# Test 10: Obtenir les métadonnées d'une vue
Write-Host "Test 10: Récupération des métadonnées d'une vue" -ForegroundColor Cyan
$metadata = $sharingManager.GetViewMetadata($exportPath)

if ($null -ne $metadata -and $metadata.Count -gt 0) {
    Write-Host "Métadonnées récupérées avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de la récupération des métadonnées" -ForegroundColor Red
    exit 1
}

# Test 11: Lister les vues exportées
Write-Host "Test 11: Listage des vues exportées" -ForegroundColor Cyan
$exportedViews = $sharingManager.ListExportedViews()

if ($null -ne $exportedViews -and $exportedViews.Count -gt 0) {
    Write-Host "Vues exportées listées avec succès: $($exportedViews.Count) vue(s)" -ForegroundColor Green
}
else {
    Write-Host "Échec du listage des vues exportées" -ForegroundColor Red
    exit 1
}

# Nettoyage
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Tests terminés avec succès" -ForegroundColor Green
