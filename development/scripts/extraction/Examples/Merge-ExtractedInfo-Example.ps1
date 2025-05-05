#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de la fonction Merge-ExtractedInfo.

.DESCRIPTION
Ce script montre comment utiliser la fonction Merge-ExtractedInfo pour fusionner
des objets d'information extraite dans différents scénarios.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
Import-Module -Name ".\ExtractedInfoModuleV2.psm1" -Force

# Activer l'affichage des messages verbeux
$VerbosePreference = "Continue"

Write-Host "=== Exemple d'utilisation de Merge-ExtractedInfo ===" -ForegroundColor Cyan

#region Exemple 1: Fusion simple de deux objets TextExtractedInfo
Write-Host "`n=== Exemple 1: Fusion simple de deux objets TextExtractedInfo ===" -ForegroundColor Green

# Créer deux objets TextExtractedInfo
$text1 = New-TextExtractedInfo -Source "document.txt" -Text "Première partie du texte." -Language "fr"
$text1.ConfidenceScore = 80
$text1 = Add-ExtractedInfoMetadata -Info $text1 -Metadata @{
    Author = "John Doe"
    Category = "Test"
}

$text2 = New-TextExtractedInfo -Source "document.txt" -Text "Seconde partie du texte." -Language "fr"
$text2.ConfidenceScore = 90
$text2 = Add-ExtractedInfoMetadata -Info $text2 -Metadata @{
    Author = "Jane Smith"
    Keywords = @("test", "exemple")
}

# Afficher les objets originaux
Write-Host "Objet 1:" -ForegroundColor Yellow
$text1 | Format-List

Write-Host "Objet 2:" -ForegroundColor Yellow
$text2 | Format-List

# Fusionner les objets avec la stratégie Combine
$mergedText = Merge-ExtractedInfo -PrimaryInfo $text1 -SecondaryInfo $text2 -MergeStrategy "Combine"

# Afficher le résultat
Write-Host "Résultat de la fusion (Combine):" -ForegroundColor Yellow
$mergedText | Format-List
#endregion

#region Exemple 2: Fusion avec priorité basée sur le score de confiance
Write-Host "`n=== Exemple 2: Fusion avec priorité basée sur le score de confiance ===" -ForegroundColor Green

# Créer deux objets StructuredDataExtractedInfo
$data1 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
    Name = "John"
    Age = 30
} -DataFormat "Hashtable"
$data1.ConfidenceScore = 70

$data2 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
    Name = "John Doe"
    Email = "john@example.com"
} -DataFormat "Hashtable"
$data2.ConfidenceScore = 90

# Afficher les objets originaux
Write-Host "Objet 1:" -ForegroundColor Yellow
$data1 | Format-List

Write-Host "Objet 2:" -ForegroundColor Yellow
$data2 | Format-List

# Fusionner les objets avec la stratégie HighestConfidence
$mergedData = Merge-ExtractedInfo -PrimaryInfo $data1 -SecondaryInfo $data2 -MergeStrategy "HighestConfidence"

# Afficher le résultat
Write-Host "Résultat de la fusion (HighestConfidence):" -ForegroundColor Yellow
$mergedData | Format-List
#endregion

#region Exemple 3: Fusion de plusieurs objets
Write-Host "`n=== Exemple 3: Fusion de plusieurs objets ===" -ForegroundColor Green

# Créer un troisième objet TextExtractedInfo
$text3 = New-TextExtractedInfo -Source "document.txt" -Text "Troisième partie du texte." -Language "fr"
$text3.ConfidenceScore = 85
$text3 = Add-ExtractedInfoMetadata -Info $text3 -Metadata @{
    Author = "Bob Johnson"
    Keywords = @("exemple", "fusion")
}

# Afficher l'objet original
Write-Host "Objet 3:" -ForegroundColor Yellow
$text3 | Format-List

# Fusionner les trois objets avec la stratégie LastWins
$mergedInfo = Merge-ExtractedInfo -InfoArray @($text1, $text2, $text3) -MergeStrategy "LastWins"

# Afficher le résultat
Write-Host "Résultat de la fusion (LastWins):" -ForegroundColor Yellow
$mergedInfo | Format-List
#endregion

#region Exemple 4: Fusion avec stratégies différentes pour le contenu et les métadonnées
Write-Host "`n=== Exemple 4: Fusion avec stratégies différentes pour le contenu et les métadonnées ===" -ForegroundColor Green

# Fusionner les objets avec des stratégies différentes
$mergedInfo2 = Merge-ExtractedInfo -PrimaryInfo $text1 -SecondaryInfo $text2 -MergeStrategy "FirstWins" -MetadataMergeStrategy "Combine"

# Afficher le résultat
Write-Host "Résultat de la fusion (FirstWins pour le contenu, Combine pour les métadonnées):" -ForegroundColor Yellow
$mergedInfo2 | Format-List
#endregion

#region Exemple 5: Fusion d'objets de types différents avec Force
Write-Host "`n=== Exemple 5: Fusion d'objets de types différents avec Force ===" -ForegroundColor Green

# Fusionner un objet TextExtractedInfo et un objet StructuredDataExtractedInfo
$forcedMerge = Merge-ExtractedInfo -PrimaryInfo $text1 -SecondaryInfo $data1 -MergeStrategy "Combine" -Force

# Afficher le résultat
Write-Host "Résultat de la fusion forcée:" -ForegroundColor Yellow
$forcedMerge | Format-List
#endregion

#region Exemple 6: Utilisation avec une collection
Write-Host "`n=== Exemple 6: Utilisation avec une collection ===" -ForegroundColor Green

# Créer une collection
$collection = New-ExtractedInfoCollection -Name "Collection de test"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text2
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $text3

# Afficher la collection
Write-Host "Collection:" -ForegroundColor Yellow
$collection | Format-List

# Récupérer les objets de la collection
$collectionItems = Get-ExtractedInfoFromCollection -Collection $collection

# Fusionner les objets de la collection
$mergedCollection = Merge-ExtractedInfo -InfoArray $collectionItems -MergeStrategy "Combine"

# Afficher le résultat
Write-Host "Résultat de la fusion de la collection:" -ForegroundColor Yellow
$mergedCollection | Format-List
#endregion

Write-Host "`n=== Fin des exemples ===" -ForegroundColor Cyan

# Restaurer la préférence verbose
$VerbosePreference = "SilentlyContinue"
