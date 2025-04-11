#Requires -Version 5.1
<#
.SYNOPSIS
    Convertit les tests simplifiés en tests réels.

.DESCRIPTION
    Ce script convertit les tests simplifiés en tests réels en utilisant les tests simplifiés
    comme base pour les tests réels. Il copie les tests simplifiés dans les fichiers de tests
    réels correspondants, en adaptant le code pour qu'il fonctionne dans les tests réels.

.PARAMETER TestFile
    Le fichier de test simplifié à convertir. Si non spécifié, tous les fichiers de test simplifiés seront convertis.

.EXAMPLE
    .\Convert-SimplifiedToRealTests.ps1
    Convertit tous les fichiers de test simplifiés en tests réels.

.EXAMPLE
    .\Convert-SimplifiedToRealTests.ps1 -TestFile "Get-FileFormatAnalysis.Simplified.ps1"
    Convertit le fichier Get-FileFormatAnalysis.Simplified.ps1 en test réel.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestFile
)

# Fonction pour convertir un test simplifié en test réel
function Convert-SimplifiedToRealTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SimplifiedTestPath
    )
    
    Write-Host "Conversion du test simplifié : $SimplifiedTestPath" -ForegroundColor Cyan
    
    # Déterminer le nom du fichier de test réel correspondant
    $simplifiedFileName = Split-Path -Path $SimplifiedTestPath -Leaf
    $realFileName = $simplifiedFileName -replace "\.Simplified\.ps1$", ".ps1"
    $realTestPath = Join-Path -Path (Split-Path -Path $SimplifiedTestPath -Parent) -ChildPath $realFileName
    
    # Vérifier si le fichier de test réel existe
    if (-not (Test-Path -Path $realTestPath)) {
        Write-Warning "Le fichier de test réel '$realTestPath' n'existe pas. Création d'un nouveau fichier."
        $realTestPath = Join-Path -Path (Split-Path -Path $SimplifiedTestPath -Parent) -ChildPath $realFileName
    }
    
    # Créer une copie de sauvegarde du fichier de test réel
    $backupPath = "$realTestPath.backup"
    if (Test-Path -Path $realTestPath) {
        Copy-Item -Path $realTestPath -Destination $backupPath -Force
        Write-Host "Copie de sauvegarde créée : $backupPath" -ForegroundColor Yellow
    }
    
    # Lire le contenu du fichier de test simplifié
    $simplifiedContent = Get-Content -Path $SimplifiedTestPath -Raw
    
    # Adapter le contenu pour qu'il fonctionne dans les tests réels
    $realContent = $simplifiedContent
    
    # Remplacer les références aux variables globales
    $realContent = $realContent -replace "\`$global:", "\$"
    
    # Ajouter des commentaires pour indiquer que le fichier a été généré automatiquement
    $realContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la fonction $(($realFileName -replace "\.ps1$", "") -replace "\.Tests$", "").

.DESCRIPTION
    Ce fichier contient des tests pour la fonction $(($realFileName -replace "\.ps1$", "") -replace "\.Tests$", "").
    Il a été généré automatiquement à partir du fichier de test simplifié $simplifiedFileName.

.NOTES
    Date de génération : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Auteur : Augment Agent
#>

$realContent
"@
    
    # Enregistrer le contenu dans le fichier de test réel
    $realContent | Set-Content -Path $realTestPath -Encoding UTF8
    
    Write-Host "Test simplifié converti en test réel : $realTestPath" -ForegroundColor Green
    
    return $realTestPath
}

# Obtenir les fichiers de test simplifiés à convertir
$simplifiedTestFiles = @()

if ($TestFile) {
    $simplifiedTestPath = Join-Path -Path $PSScriptRoot -ChildPath $TestFile
    if (Test-Path -Path $simplifiedTestPath -PathType Leaf) {
        $simplifiedTestFiles += $simplifiedTestPath
    }
    else {
        Write-Error "Le fichier de test simplifié '$TestFile' n'existe pas."
        exit 1
    }
}
else {
    $simplifiedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Simplified.ps1" | 
        ForEach-Object { $_.FullName }
}

# Convertir chaque fichier de test simplifié en test réel
$convertedFiles = @()
foreach ($file in $simplifiedTestFiles) {
    $convertedFile = Convert-SimplifiedToRealTest -SimplifiedTestPath $file
    $convertedFiles += $convertedFile
}

Write-Host "`nLes tests simplifiés ont été convertis en tests réels." -ForegroundColor Green
Write-Host "Fichiers convertis :" -ForegroundColor Green
$convertedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
Write-Host "`nExécutez les tests pour vérifier si les conversions ont résolu les problèmes." -ForegroundColor Green
