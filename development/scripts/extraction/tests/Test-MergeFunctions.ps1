#Requires -Version 5.1
<#
.SYNOPSIS
Script simple pour tester les fonctions de fusion.

.DESCRIPTION
Ce script teste manuellement les fonctions de fusion pour vérifier qu'elles fonctionnent correctement.

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
Import-Module "$PSScriptRoot\..\ExtractedInfoModuleV2.psm1" -Force

# Afficher les fonctions exportées
Write-Host "Fonctions exportées :" -ForegroundColor Cyan
Get-Command -Module ExtractedInfoModuleV2 | Where-Object { $_.Name -like "*Merge*" -or $_.Name -like "*Confidence*" -or $_.Name -like "*Compatibility*" } | Format-Table -AutoSize

# Créer deux objets simples
$info1 = @{
    _Type = "TestExtractedInfo"
    Id = "1"
    Source = "test.txt"
    Text = "Texte 1"
    ConfidenceScore = 80
    Metadata = @{
        Author = "John"
        Category = "Test"
    }
}

$info2 = @{
    _Type = "TestExtractedInfo"
    Id = "2"
    Source = "test.txt"
    Text = "Texte 2"
    ConfidenceScore = 90
    Metadata = @{
        Author = "Jane"
        Tags = @("test")
    }
}

# Tester Test-ExtractedInfoCompatibility
Write-Host "`nTest de Test-ExtractedInfoCompatibility :" -ForegroundColor Green
try {
    $result = Test-ExtractedInfoCompatibility -Info1 $info1 -Info2 $info2
    Write-Host "Résultat : $($result | ConvertTo-Json -Depth 3)" -ForegroundColor Yellow
} catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
}

# Tester Merge-ExtractedInfoMetadata
Write-Host "`nTest de Merge-ExtractedInfoMetadata :" -ForegroundColor Green
try {
    $result = Merge-ExtractedInfoMetadata -Metadata1 $info1.Metadata -Metadata2 $info2.Metadata -MergeStrategy "LastWins"
    Write-Host "Résultat : $($result | ConvertTo-Json -Depth 3)" -ForegroundColor Yellow
} catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
}

# Tester Get-MergedConfidenceScore
Write-Host "`nTest de Get-MergedConfidenceScore :" -ForegroundColor Green
try {
    $result = Get-MergedConfidenceScore -ConfidenceScores @($info1.ConfidenceScore, $info2.ConfidenceScore) -Method "Average"
    Write-Host "Résultat : $result" -ForegroundColor Yellow
} catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
}

# Tester Merge-ExtractedInfo
Write-Host "`nTest de Merge-ExtractedInfo :" -ForegroundColor Green
try {
    $result = Merge-ExtractedInfo -PrimaryInfo $info1 -SecondaryInfo $info2 -MergeStrategy "LastWins"
    Write-Host "Résultat : $($result | ConvertTo-Json -Depth 3)" -ForegroundColor Yellow
} catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
}
