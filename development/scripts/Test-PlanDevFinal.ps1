# Script pour tester le générateur de plans de développement
# Version 1.0 - 2025-05-15
# Auteur: Augment Agent
# Description: Ce script teste le générateur de plans de développement avec différents cas de test.
param (
    [Parameter(Mandatory = $false)]
    [switch]$CleanupAfterTests = $true,

    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput = $false
)

# Configuration de l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Fonction pour écrire des messages de log
function Write-TestLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TEST")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "TEST" { Write-Host $logMessage -ForegroundColor Magenta }
    }
}

# Fonction pour exécuter un test
function Invoke-Test {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestScript
    )

    Write-TestLog "Exécution du test : $TestName" -Level "TEST"

    try {
        & $TestScript
        Write-TestLog "Test réussi : $TestName" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-TestLog "Test échoué : $TestName - $_" -Level "ERROR"
        return $false
    }
}

# Chemin du script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$scriptToTest = "$scriptPath\Generate-PlanDevFinal.ps1"

# Vérifier si le script à tester existe
if (-not (Test-Path $scriptToTest)) {
    Write-TestLog "Le script à tester n'existe pas : $scriptToTest" -Level "ERROR"
    exit 1
}

# Définir les cas de test
$testCases = @(
    @{
        Name = "Test avec caractères accentués dans le titre"
        Version = "v99"
        Title = "Test Caractères Accentués"
        Description = "Ce plan est généré automatiquement pour tester le support des caractères accentués : é è ê ë à â ù ü ç ô ö ï î"
        Phases = 2
    },
    @{
        Name = "Test avec caractères spéciaux dans le titre"
        Version = "v98"
        Title = "Test <>/\\:\"*?| Spéciaux"
        Description = "Ce plan est généré automatiquement pour tester le support des caractères spéciaux dans le titre."
        Phases = 1
    },
    @{
        Name = "Test avec nombre maximum de phases"
        Version = "v97"
        Title = "Test Maximum Phases"
        Description = "Ce plan est généré automatiquement pour tester le support du nombre maximum de phases."
        Phases = 6
    }
)

# Exécuter les tests
$testResults = @()
$testFiles = @()

foreach ($testCase in $testCases) {
    $testResult = Invoke-Test -TestName $testCase.Name -TestScript {
        # Exécuter le script avec les paramètres du cas de test
        $params = @{
            Version = $testCase.Version
            Title = $testCase.Title
            Description = $testCase.Description
            Phases = $testCase.Phases
        }

        if ($VerboseOutput) {
            Write-TestLog "Paramètres du test :" -Level "INFO"
            $params | Format-Table -AutoSize | Out-String | Write-Host
        }

        # Exécuter le script et capturer la sortie
        $result = & $scriptToTest @params

        # Vérifier si la sortie est valide
        if ([string]::IsNullOrEmpty($result)) {
            throw "Le script n'a pas retourné de chemin de fichier"
        }

        # Utiliser le chemin retourné par le script
        $outputPath = $result.Trim()

        # Vérifier si le fichier a été créé
        if (-not (Test-Path $outputPath)) {
            throw "Le fichier n'a pas été créé : $outputPath"
        }

        # Vérifier si le fichier contient les caractères accentués
        $content = Get-Content -Path $outputPath -Raw -Encoding UTF8

        if (-not $content.Contains($testCase.Title)) {
            throw "Le fichier ne contient pas le titre attendu : $($testCase.Title)"
        }

        if (-not $content.Contains($testCase.Description)) {
            throw "Le fichier ne contient pas la description attendue : $($testCase.Description)"
        }

        # Vérifier si le fichier contient le bon nombre de phases
        $phaseCount = ([regex]::Matches($content, "## \d+\. Phase \d+")).Count

        if ($phaseCount -ne $testCase.Phases) {
            throw "Le fichier ne contient pas le bon nombre de phases : $phaseCount (attendu : $($testCase.Phases))"
        }

        # Ajouter le fichier à la liste des fichiers à supprimer
        $script:testFiles += $outputPath

        return $outputPath
    }

    $testResults += [PSCustomObject]@{
        Name = $testCase.Name
        Result = $testResult
    }
}

# Afficher les résultats des tests
Write-TestLog "Résultats des tests :" -Level "INFO"
$testResults | Format-Table -AutoSize

# Calculer le taux de réussite
$successCount = ($testResults | Where-Object { $_.Result -eq $true }).Count
$totalCount = $testResults.Count
$successRate = [math]::Round(($successCount / $totalCount) * 100, 2)

Write-TestLog "Taux de réussite : $successRate% ($successCount/$totalCount)" -Level "INFO"

# Supprimer les fichiers de test si demandé
if ($CleanupAfterTests -and $testFiles.Count -gt 0) {
    Write-TestLog "Suppression des fichiers de test..." -Level "INFO"

    foreach ($file in $testFiles) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-TestLog "Fichier supprimé : $file" -Level "INFO"
        }
    }
}

# Sortir avec le code de retour approprié
if ($successCount -eq $totalCount) {
    Write-TestLog "Tous les tests ont réussi !" -Level "SUCCESS"
    exit 0
}
else {
    Write-TestLog "Certains tests ont échoué." -Level "ERROR"
    exit 1
}
