#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re la documentation des tests unitaires du script manager.
.DESCRIPTION
    Ce script gÃ©nÃ¨re la documentation des tests unitaires du script manager,
    en analysant les fichiers de test et en gÃ©nÃ©rant un rapport HTML.
.PARAMETER OutputPath
    Chemin du dossier pour la documentation.
.EXAMPLE
    .\Generate-TestDocumentation.ps1 -OutputPath ".\docs\tests"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\docs\tests"
)

# Fonction pour Ã©crire dans le journal
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

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# RÃ©cupÃ©rer les fichiers de test
$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" -Recurse

if ($testFiles.Count -eq 0) {
    Write-Log "Aucun fichier de test trouvÃ©." -Level "ERROR"
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
        Type = if ($testFile.Name -like "*Fixed*") { "CorrigÃ©" } elseif ($testFile.Name -like "*Simple*") { "SimplifiÃ©" } else { "Original" }
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

# GÃ©nÃ©rer le rapport HTML
$htmlPath = Join-Path -Path $OutputPath -ChildPath "TestDocumentation.html"

# CrÃ©er le contenu HTML
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
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Nombre total de fichiers de test: $($testInfo.Count)</p>
        <p>Nombre de tests originaux: $($testInfo | Where-Object { $_.Type -eq "Original" } | Measure-Object).Count</p>
        <p>Nombre de tests simplifiÃ©s: $($testInfo | Where-Object { $_.Type -eq "SimplifiÃ©" } | Measure-Object).Count</p>
        <p>Nombre de tests corrigÃ©s: $($testInfo | Where-Object { $_.Type -eq "CorrigÃ©" } | Measure-Object).Count</p>
    </div>
    
    <h2>DÃ©tails des tests</h2>
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
        <li><span class="test-type test-type-original">Tests originaux</span> : Les tests originaux qui ont Ã©tÃ© crÃ©Ã©s pour le script manager.</li>
        <li><span class="test-type test-type-simplified">Tests simplifiÃ©s</span> : Des versions simplifiÃ©es des tests qui ne nÃ©cessitent pas de modifications de l'environnement.</li>
        <li><span class="test-type test-type-fixed">Tests corrigÃ©s</span> : Des versions corrigÃ©es des tests qui utilisent des mocks pour Ã©viter de modifier l'environnement.</li>
    </ul>
    
    <h2>Scripts d'exÃ©cution des tests</h2>
    <p>Plusieurs scripts sont disponibles pour exÃ©cuter les tests :</p>
    <ul>
        <li><strong>Run-AllManagerTests.ps1</strong> : ExÃ©cute tous les tests (originaux, simplifiÃ©s et corrigÃ©s) et gÃ©nÃ¨re des rapports dÃ©taillÃ©s.</li>
        <li><strong>Run-SimplifiedTests.ps1</strong> : ExÃ©cute uniquement les tests simplifiÃ©s.</li>
        <li><strong>Run-FixedTests.ps1</strong> : ExÃ©cute uniquement les tests corrigÃ©s.</li>
    </ul>
    
    <h3>Exemples d'utilisation</h3>
    <pre>
# ExÃ©cuter tous les tests et gÃ©nÃ©rer des rapports HTML
.\Run-AllManagerTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML

# ExÃ©cuter uniquement les tests corrigÃ©s liÃ©s Ã  l'organisation
.\Run-FixedTests.ps1 -TestName "Organization" -OutputPath ".\reports\tests" -GenerateHTML

# ExÃ©cuter uniquement les tests simplifiÃ©s
.\Run-SimplifiedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
    </pre>
    
    <h2>Recommandations pour amÃ©liorer les tests</h2>
    <ol>
        <li><strong>Utiliser des mocks</strong> : Pour Ã©viter que les tests ne modifient rÃ©ellement les fichiers, il est recommandÃ© d'utiliser des mocks pour simuler les opÃ©rations de fichier.</li>
        <li><strong>Isoler les tests</strong> : Chaque test devrait Ãªtre indÃ©pendant des autres tests, ce qui signifie qu'il ne devrait pas dÃ©pendre de l'Ã©tat laissÃ© par un test prÃ©cÃ©dent.</li>
        <li><strong>Utiliser des fixtures</strong> : Pour prÃ©parer l'environnement de test, il est recommandÃ© d'utiliser des fixtures qui crÃ©ent un environnement de test propre avant chaque test et le nettoient aprÃ¨s.</li>
        <li><strong>IntÃ©grer les tests dans le processus de CI/CD</strong> : Les tests devraient Ãªtre exÃ©cutÃ©s automatiquement lors des commits et des pull requests pour s'assurer que les modifications ne cassent pas le code existant.</li>
    </ol>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $htmlPath -Encoding utf8

Write-Log "Documentation HTML gÃ©nÃ©rÃ©e: $htmlPath" -Level "SUCCESS"

# Copier le README.md dans le dossier de documentation
$readmePath = Join-Path -Path $PSScriptRoot -ChildPath "README.md"
$readmeDestPath = Join-Path -Path $OutputPath -ChildPath "README.md"

if (Test-Path -Path $readmePath) {
    Copy-Item -Path $readmePath -Destination $readmeDestPath -Force
    Write-Log "README.md copiÃ© dans le dossier de documentation." -Level "SUCCESS"
}
else {
    Write-Log "README.md non trouvÃ©." -Level "WARNING"
}

Write-Log "GÃ©nÃ©ration de la documentation terminÃ©e." -Level "SUCCESS"
