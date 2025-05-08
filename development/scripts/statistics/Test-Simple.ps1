# Encoding: UTF-8 with BOM
#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "DensityRatioAsymmetry.psm1"
Import-Module -Name $modulePath -Force

# Créer des données de test
$data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50)

# Tester la fonction Get-DensityBasedAsymmetry
$result = Get-DensityBasedAsymmetry -Data $data -TailProportion 0.1
Write-Host "Ratio de densité: $($result.DensityRatio)"
Write-Host "Niveau d'intensité: $($result.AsymmetryEvaluation.IntensityLevel)"
Write-Host "Direction de l'asymétrie: $($result.AsymmetryEvaluation.AsymmetryDirection)"
