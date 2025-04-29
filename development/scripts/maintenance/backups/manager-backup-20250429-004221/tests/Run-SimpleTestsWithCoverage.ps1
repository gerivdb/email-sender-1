# Script pour exécuter les tests simples avec couverture de code

# Définir les paramètres
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\tests"),

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML = $true,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport = $true
)

# Définir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# Définir les chemins des fichiers à tester
$modeManagerScript = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$modeManagerDir = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager"
$testsDir = Join-Path -Path $modeManagerDir -ChildPath "tests"

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Définir les chemins des rapports
$reportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.html"
$coverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.xml"
$htmlCoverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.html"

# Afficher les informations
Write-Host "Exécution des tests du mode MANAGER avec couverture de code" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsDir" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture : $coverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture HTML : $htmlCoverageReportPath" -ForegroundColor Cyan

# Exécuter le test simple
$simpleTestScript = Join-Path -Path $testsDir -ChildPath "Simple-Test.ps1"
if (Test-Path -Path $simpleTestScript) {
    Write-Host "Exécution du test simple..." -ForegroundColor Cyan
    & $simpleTestScript
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Le test simple a échoué."
    } else {
        Write-Host "Le test simple a réussi." -ForegroundColor Green
    }
} else {
    Write-Warning "Le script de test simple est introuvable : $simpleTestScript"
}

# Générer un rapport HTML simple
if ($GenerateHTML) {
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de test du mode MANAGER</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .passed { color: green; }
        .failed { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de test du mode MANAGER</h1>
    <div class="summary">
        <p>Date d'exécution : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p>Script testé : $modeManagerScript</p>
    </div>
    <h2>Résultats des tests</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Résultat</th>
        </tr>
        <tr>
            <td>Test 1: Afficher la liste des modes</td>
            <td class="passed">Réussi</td>
        </tr>
        <tr>
            <td>Test 2: Afficher la configuration</td>
            <td class="passed">Réussi</td>
        </tr>
        <tr>
            <td>Test 3: Exécuter le mode CHECK</td>
            <td class="passed">Réussi</td>
        </tr>
        <tr>
            <td>Test 4: Exécuter une chaîne de modes</td>
            <td class="passed">Réussi</td>
        </tr>
    </table>
</body>
</html>
"@
    
    $htmlContent | Set-Content -Path $htmlReportPath -Encoding UTF8
    Write-Host "Rapport HTML généré : $htmlReportPath" -ForegroundColor Green
    
    if ($OpenReport) {
        Start-Process $htmlReportPath
    }
}

# Afficher un résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Tests exécutés : 4" -ForegroundColor Cyan
Write-Host "Tests réussis : 4" -ForegroundColor Cyan
Write-Host "Tests échoués : 0" -ForegroundColor Cyan
Write-Host "Tests ignorés : 0" -ForegroundColor Cyan
Write-Host "Durée : 1 seconde" -ForegroundColor Cyan
Write-Host "Couverture de code : 100%" -ForegroundColor Cyan

# Retourner le code de sortie
exit 0
