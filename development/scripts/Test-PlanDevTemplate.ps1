# Script pour tester le template de plan de développement
param (
    [switch]$UseHygen = $false
)

# Chemin du projet
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent (Split-Path -Parent $scriptPath)

# Paramètres de test
$testVersion = "v99"
$testTitle = "Test Template Accents"
$testDescription = "Ce plan est généré automatiquement pour tester le template Hygen avec des caractères accentués : é è ê ë à â ù ü ç"
$testPhases = 2

# Chemin du fichier de sortie attendu
$expectedOutputPath = "$projectPath\projet\roadmaps\plans\plan-dev-$testVersion-test-template-accents.md"

# Supprimer le fichier de test s'il existe déjà
if (Test-Path $expectedOutputPath) {
    Remove-Item $expectedOutputPath -Force
    Write-Host "Fichier de test précédent supprimé." -ForegroundColor Yellow
}

# Générer le plan de test
Write-Host "Génération d'un plan de test avec les paramètres suivants :" -ForegroundColor Cyan
Write-Host "  Version: $testVersion" -ForegroundColor Cyan
Write-Host "  Titre: $testTitle" -ForegroundColor Cyan
Write-Host "  Description: $testDescription" -ForegroundColor Cyan
Write-Host "  Phases: $testPhases" -ForegroundColor Cyan
Write-Host ""

if ($UseHygen) {
    # Utiliser Hygen directement
    Write-Host "Test avec Hygen..." -ForegroundColor Cyan
    Set-Location $projectPath
    hygen plan-dev new --version $testVersion --title $testTitle --description $testDescription --phases $testPhases
} else {
    # Utiliser notre script
    Write-Host "Test avec le script Generate-PlanDev.ps1..." -ForegroundColor Cyan
    & "$scriptPath\Generate-PlanDev.ps1" -Version $testVersion -Title $testTitle -Description $testDescription -Phases $testPhases
}

# Vérifier si le fichier a été créé
if (Test-Path $expectedOutputPath) {
    Write-Host "Test réussi ! Le fichier a été créé à l'emplacement attendu." -ForegroundColor Green

    # Afficher le contenu du fichier
    Write-Host "Contenu du fichier généré :" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor Cyan
    Get-Content $expectedOutputPath | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
    Write-Host "... (contenu tronqué)" -ForegroundColor DarkGray
    Write-Host "------------------------" -ForegroundColor Cyan

    # Supprimer le fichier de test
    $removeFile = Read-Host "Voulez-vous supprimer le fichier de test ? (O/N)"
    if ($removeFile -eq "O" -or $removeFile -eq "o") {
        Remove-Item $expectedOutputPath -Force
        Write-Host "Fichier de test supprimé." -ForegroundColor Yellow
    }
} else {
    Write-Host "Test échoué ! Le fichier n'a pas été créé à l'emplacement attendu." -ForegroundColor Red
}
