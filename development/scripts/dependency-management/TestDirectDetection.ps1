# Script pour tester directement la dÃ©tection des instructions using module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un fichier temporaire avec des instructions using module et Import-Module
$tempFilePath = Join-Path -Path $env:TEMP -ChildPath "TestDirectDetection.ps1"
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

# Afficher les rÃ©sultats
Write-Host "Nombre total d'instructions trouvÃ©es : $($moduleImports.Count)"

# Afficher les dÃ©tails de chaque instruction
foreach ($module in $moduleImports) {
    Write-Host "`nModule : $($module.Name)"
    Write-Host "  Type : $($module.ImportType)"
    Write-Host "  Ligne : $($module.LineNumber)"
    Write-Host "  Commande : $($module.RawCommand)"
    Write-Host "  ArgumentType : $($module.ArgumentType)"
}

# Compter les diffÃ©rents types d'importation
$importModules = @($moduleImports | Where-Object { $_.ImportType -eq "Import-Module" })
$usingModules = @($moduleImports | Where-Object { $_.ImportType -eq "using module" })

Write-Host "`nNombre d'instructions Import-Module : $($importModules.Count)"
Write-Host "Nombre d'instructions using module : $($usingModules.Count)"

# Afficher les dÃ©tails des instructions using module
Write-Host "`nDÃ©tails des instructions using module :"
foreach ($module in $usingModules) {
    Write-Host "  Module : $($module.Name), Type : $($module.ImportType), Ligne : $($module.LineNumber)"
}

# Nettoyer
Remove-Item -Path $tempFilePath -Force
