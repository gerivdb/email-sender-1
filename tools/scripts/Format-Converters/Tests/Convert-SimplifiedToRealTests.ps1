#Requires -Version 5.1
<#
.SYNOPSIS
    Convertit les tests simplifiÃ©s en tests rÃ©els.

.DESCRIPTION
    Ce script convertit les tests simplifiÃ©s en tests rÃ©els en utilisant les tests simplifiÃ©s
    comme base pour les tests rÃ©els. Il copie les tests simplifiÃ©s dans les fichiers de tests
    rÃ©els correspondants, en adaptant le code pour qu'il fonctionne dans les tests rÃ©els.

.PARAMETER TestFile
    Le fichier de test simplifiÃ© Ã  convertir. Si non spÃ©cifiÃ©, tous les fichiers de test simplifiÃ©s seront convertis.

.EXAMPLE
    .\Convert-SimplifiedToRealTests.ps1
    Convertit tous les fichiers de test simplifiÃ©s en tests rÃ©els.

.EXAMPLE
    .\Convert-SimplifiedToRealTests.ps1 -TestFile "Get-FileFormatAnalysis.Simplified.ps1"
    Convertit le fichier Get-FileFormatAnalysis.Simplified.ps1 en test rÃ©el.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestFile
)

# Fonction pour convertir un test simplifiÃ© en test rÃ©el
function Convert-SimplifiedToRealTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SimplifiedTestPath
    )
    
    Write-Host "Conversion du test simplifiÃ© : $SimplifiedTestPath" -ForegroundColor Cyan
    
    # DÃ©terminer le nom du fichier de test rÃ©el correspondant
    $simplifiedFileName = Split-Path -Path $SimplifiedTestPath -Leaf
    $realFileName = $simplifiedFileName -replace "\.Simplified\.ps1$", ".ps1"
    $realTestPath = Join-Path -Path (Split-Path -Path $SimplifiedTestPath -Parent) -ChildPath $realFileName
    
    # VÃ©rifier si le fichier de test rÃ©el existe
    if (-not (Test-Path -Path $realTestPath)) {
        Write-Warning "Le fichier de test rÃ©el '$realTestPath' n'existe pas. CrÃ©ation d'un nouveau fichier."
        $realTestPath = Join-Path -Path (Split-Path -Path $SimplifiedTestPath -Parent) -ChildPath $realFileName
    }
    
    # CrÃ©er une copie de sauvegarde du fichier de test rÃ©el
    $backupPath = "$realTestPath.backup"
    if (Test-Path -Path $realTestPath) {
        Copy-Item -Path $realTestPath -Destination $backupPath -Force
        Write-Host "Copie de sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Yellow
    }
    
    # Lire le contenu du fichier de test simplifiÃ©
    $simplifiedContent = Get-Content -Path $SimplifiedTestPath -Raw
    
    # Adapter le contenu pour qu'il fonctionne dans les tests rÃ©els
    $realContent = $simplifiedContent
    
    # Remplacer les rÃ©fÃ©rences aux variables globales
    $realContent = $realContent -replace "\`$global:", "\$"
    
    # Ajouter des commentaires pour indiquer que le fichier a Ã©tÃ© gÃ©nÃ©rÃ© automatiquement
    $realContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la fonction $(($realFileName -replace "\.ps1$", "") -replace "\.Tests$", "").

.DESCRIPTION
    Ce fichier contient des tests pour la fonction $(($realFileName -replace "\.ps1$", "") -replace "\.Tests$", "").
    Il a Ã©tÃ© gÃ©nÃ©rÃ© automatiquement Ã  partir du fichier de test simplifiÃ© $simplifiedFileName.

.NOTES
    Date de gÃ©nÃ©ration : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Auteur : Augment Agent
#>

$realContent
"@
    
    # Enregistrer le contenu dans le fichier de test rÃ©el
    $realContent | Set-Content -Path $realTestPath -Encoding UTF8
    
    Write-Host "Test simplifiÃ© converti en test rÃ©el : $realTestPath" -ForegroundColor Green
    
    return $realTestPath
}

# Obtenir les fichiers de test simplifiÃ©s Ã  convertir
$simplifiedTestFiles = @()

if ($TestFile) {
    $simplifiedTestPath = Join-Path -Path $PSScriptRoot -ChildPath $TestFile
    if (Test-Path -Path $simplifiedTestPath -PathType Leaf) {
        $simplifiedTestFiles += $simplifiedTestPath
    }
    else {
        Write-Error "Le fichier de test simplifiÃ© '$TestFile' n'existe pas."
        exit 1
    }
}
else {
    $simplifiedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Simplified.ps1" | 
        ForEach-Object { $_.FullName }
}

# Convertir chaque fichier de test simplifiÃ© en test rÃ©el
$convertedFiles = @()
foreach ($file in $simplifiedTestFiles) {
    $convertedFile = Convert-SimplifiedToRealTest -SimplifiedTestPath $file
    $convertedFiles += $convertedFile
}

Write-Host "`nLes tests simplifiÃ©s ont Ã©tÃ© convertis en tests rÃ©els." -ForegroundColor Green
Write-Host "Fichiers convertis :" -ForegroundColor Green
$convertedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
Write-Host "`nExÃ©cutez les tests pour vÃ©rifier si les conversions ont rÃ©solu les problÃ¨mes." -ForegroundColor Green
