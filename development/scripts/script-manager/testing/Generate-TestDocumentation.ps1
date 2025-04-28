#Requires -Version 5.1
<#
.SYNOPSIS
    Génère la documentation des tests unitaires du script manager.
.DESCRIPTION
    Ce script génère la documentation des tests unitaires du script manager,
    en analysant les fichiers de test et en générant un rapport HTML.
.PARAMETER OutputPath
    Chemin du dossier pour la documentation.
.EXAMPLE
    .\Generate-TestDocumentation.ps1 -OutputPath ".\docs\tests"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\docs\tests"
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Récupérer les fichiers de test
$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" -Recurse

if ($testFiles.Count -eq 0) {
    Write-Log "Aucun fichier de test trouvé." -Level "ERROR"
    exit 1
}

Write-Log "Analyse de $($testFiles.Count) fichier(s) de test..." -Level "INFO"

# Analyser les fichiers de test
$testInfo = @()
foreach ($testFile in $testFiles) {
    $content = Get-Content -Path $testFile.FullName -Raw
    
    # Extraire les informations du test
    $info = @{
        Name = $testFile.BaseName
        Path = $testFile.FullName
        Type = if ($testFile.Name -like "*Fixed*") { "Corrigé" } elseif ($testFile.Name -like "*Simple*") { "Simplifié" } else { "Original" }
        Description = ""
        TestCount = ([regex]::Matches($content, "It\s+""")).Count
        ContextCount = ([regex]::Matches($content, "Context\s+""")).Count
        MockCount = ([regex]::Matches($content, "Mock\s+")).Count
        HasBeforeAll = $content -match "BeforeAll"
        HasAfterAll = $content -match "AfterAll"
        HasBeforeEach = $content -match "BeforeEach"
        HasAfterEach = $content -match "AfterEach"
    }
    
    # Extraire la description du test
    if ($content -match "\.DESCRIPTION\s*(.*?)\.") {
        $info.Description = $matches[1].Trim()
    }
    
    $testInfo += $info
}

# Générer le rapport HTML
$htmlPath = Join-Path -Path $OutputPath -ChildPath "TestDocumentation.html"

# Créer le contenu HTML
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Documentation des tests unitaires du script manager</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        .summary { margin-bottom: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .test-type { font-weight: bold; }
        .test-type-original { color: blue; }
        .test-type-simplified { color: green; }
        .test-type-fixed { color: purple; }
    </style>
</head>
<body>
    <h1>Documentation des tests unitaires du script manager</h1>
    <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de fichiers de test: $($testInfo.Count)</p>
        <p>Nombre de tests originaux: $($testInfo | Where-Object { $_.Type -eq "Original" } | Measure-Object).Count</p>
        <p>Nombre de tests simplifiés: $($testInfo | Where-Object { $_.Type -eq "Simplifié" } | Measure-Object).Count</p>
        <p>Nombre de tests corrigés: $($testInfo | Where-Object { $_.Type -eq "Corrigé" } | Measure-Object).Count</p>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Type</th>
            <th>Description</th>
            <th>Nombre de tests</th>
            <th>Nombre de contextes</th>
            <th>Nombre de mocks</th>
            <th>Hooks</th>
        </tr>
"@

foreach ($test in $testInfo) {
    $typeClass = "test-type-" + $test.Type.ToLower()
    $hooks = @()
    if ($test.HasBeforeAll) { $hooks += "BeforeAll" }
    if ($test.HasAfterAll) { $hooks += "AfterAll" }
    if ($test.HasBeforeEach) { $hooks += "BeforeEach" }
    if ($test.HasAfterEach) { $hooks += "AfterEach" }
    
    $htmlContent += @"
        <tr>
            <td>$($test.Name)</td>
            <td class="test-type $typeClass">$($test.Type)</td>
            <td>$($test.Description)</td>
            <td>$($test.TestCount)</td>
            <td>$($test.ContextCount)</td>
            <td>$($test.MockCount)</td>
            <td>$($hooks -join ", ")</td>
        </tr>
"@
}

$htmlContent += @"
    </table>
    
    <h2>Types de tests</h2>
    <p>Il existe plusieurs types de tests :</p>
    <ul>
        <li><span class="test-type test-type-original">Tests originaux</span> : Les tests originaux qui ont été créés pour le script manager.</li>
        <li><span class="test-type test-type-simplified">Tests simplifiés</span> : Des versions simplifiées des tests qui ne nécessitent pas de modifications de l'environnement.</li>
        <li><span class="test-type test-type-fixed">Tests corrigés</span> : Des versions corrigées des tests qui utilisent des mocks pour éviter de modifier l'environnement.</li>
    </ul>
    
    <h2>Scripts d'exécution des tests</h2>
    <p>Plusieurs scripts sont disponibles pour exécuter les tests :</p>
    <ul>
        <li><strong>Run-AllManagerTests.ps1</strong> : Exécute tous les tests (originaux, simplifiés et corrigés) et génère des rapports détaillés.</li>
        <li><strong>Run-SimplifiedTests.ps1</strong> : Exécute uniquement les tests simplifiés.</li>
        <li><strong>Run-FixedTests.ps1</strong> : Exécute uniquement les tests corrigés.</li>
    </ul>
    
    <h3>Exemples d'utilisation</h3>
    <pre>
# Exécuter tous les tests et générer des rapports HTML
.\Run-AllManagerTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML

# Exécuter uniquement les tests corrigés liés à l'organisation
.\Run-FixedTests.ps1 -TestName "Organization" -OutputPath ".\reports\tests" -GenerateHTML

# Exécuter uniquement les tests simplifiés
.\Run-SimplifiedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
    </pre>
    
    <h2>Recommandations pour améliorer les tests</h2>
    <ol>
        <li><strong>Utiliser des mocks</strong> : Pour éviter que les tests ne modifient réellement les fichiers, il est recommandé d'utiliser des mocks pour simuler les opérations de fichier.</li>
        <li><strong>Isoler les tests</strong> : Chaque test devrait être indépendant des autres tests, ce qui signifie qu'il ne devrait pas dépendre de l'état laissé par un test précédent.</li>
        <li><strong>Utiliser des fixtures</strong> : Pour préparer l'environnement de test, il est recommandé d'utiliser des fixtures qui créent un environnement de test propre avant chaque test et le nettoient après.</li>
        <li><strong>Intégrer les tests dans le processus de CI/CD</strong> : Les tests devraient être exécutés automatiquement lors des commits et des pull requests pour s'assurer que les modifications ne cassent pas le code existant.</li>
    </ol>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $htmlPath -Encoding utf8

Write-Log "Documentation HTML générée: $htmlPath" -Level "SUCCESS"

# Copier le README.md dans le dossier de documentation
$readmePath = Join-Path -Path $PSScriptRoot -ChildPath "README.md"
$readmeDestPath = Join-Path -Path $OutputPath -ChildPath "README.md"

if (Test-Path -Path $readmePath) {
    Copy-Item -Path $readmePath -Destination $readmeDestPath -Force
    Write-Log "README.md copié dans le dossier de documentation." -Level "SUCCESS"
}
else {
    Write-Log "README.md non trouvé." -Level "WARNING"
}

Write-Log "Génération de la documentation terminée." -Level "SUCCESS"
