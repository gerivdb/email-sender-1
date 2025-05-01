# Script pour tester la détection des modules
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Créer un fichier temporaire avec des instructions using module et Import-Module
$tempFilePath = Join-Path -Path $env:TEMP -ChildPath "TestModuleDetection.ps1"
$content = @'
# Test d'importation de modules
using module PSScriptAnalyzer

# Import-Module simple
Import-Module Pester

# Import-Module avec chemin relatif
Import-Module .\ModuleDependencyDetector.psm1
'@
Set-Content -Path $tempFilePath -Value $content

# Analyser le fichier temporaire
$moduleImports = Find-ImportModuleInstruction -FilePath $tempFilePath

# Afficher les résultats
Write-Host "Nombre total d'instructions trouvées : $($moduleImports.Count)"
Write-Host "Instructions using module : $(($moduleImports | Where-Object { $_.ImportType -eq 'using module' }).Count)"
Write-Host "Instructions Import-Module : $(($moduleImports | Where-Object { $_.ImportType -eq 'Import-Module' }).Count)"

# Afficher les détails
foreach ($module in $moduleImports) {
    Write-Host "`nModule : $($module.Name)"
    Write-Host "  Type : $($module.ImportType)"
    Write-Host "  Ligne : $($module.LineNumber)"
    Write-Host "  Commande : $($module.RawCommand)"
}

# Nettoyer
Remove-Item -Path $tempFilePath -Force
