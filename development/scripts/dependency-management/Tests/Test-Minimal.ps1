# Test minimal pour le module ModuleDependencyAnalyzer
# Ce test vÃ©rifie uniquement les fonctionnalitÃ©s de base sans dÃ©pendances complexes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # VÃ©rifier que les fonctions sont disponibles
    $functions = Get-Command -Module ModuleDependencyAnalyzer
    Write-Host "Fonctions disponibles : $($functions.Count)" -ForegroundColor Green
    $functions | ForEach-Object { Write-Host "  - $($_.Name)" }

    # Test de la fonction Test-SystemModule
    $result = Test-SystemModule -ModuleName "Microsoft.PowerShell.Core"
    Write-Host "Test-SystemModule : $result" -ForegroundColor Green

    # Tout est OK
    Write-Host "Tous les tests ont rÃ©ussi !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
