# Script PowerShell pour exécuter les tests des nodes MCP
# Ce script exécute tous les tests et génère un rapport de test

# Configuration
$TestTimeout = 60 # 60 secondes par test
$ReportDir = Join-Path $PSScriptRoot "reports"
$ReportFile = Join-Path $ReportDir "test-report-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').md"

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Tests à exécuter
$Tests = @(
    @{
        Name = "Tests automatisés des nodes MCP"
        Script = Join-Path $PSScriptRoot "test-mcp-nodes.js"
        Description = "Tests unitaires des nodes MCP Client et MCP Memory"
    },
    @{
        Name = "Tests de scénarios"
        Script = Join-Path $PSScriptRoot "test-scenarios.js"
        Description = "Tests de scénarios d'utilisation des nodes MCP"
    }
)

# Résultats des tests
$TestResults = @()

# Fonction pour exécuter un script de test
function Invoke-Test {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Test
    )
    
    Write-ColorMessage "`n=== Exécution de: $($Test.Name) ===" -ForegroundColor Magenta
    Write-ColorMessage "Script: $($Test.Script)"
    Write-ColorMessage "Description: $($Test.Description)"
    Write-ColorMessage ""
    
    $StartTime = Get-Date
    
    try {
        # Exécuter le script Node.js
        $Process = Start-Process -FilePath "node" -ArgumentList $Test.Script -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\mcp-test-output.txt" -RedirectStandardError "$env:TEMP\mcp-test-error.txt"
        
        # Attendre que le processus se termine ou timeout
        $Process.WaitForExit($TestTimeout * 1000)
        
        # Si le processus n'est pas terminé, le tuer
        if (!$Process.HasExited) {
            $Process.Kill()
            throw "Timeout lors de l'exécution du test: $($Test.Name)"
        }
        
        # Récupérer la sortie et les erreurs
        $Output = Get-Content -Path "$env:TEMP\mcp-test-output.txt" -Raw
        $Error = Get-Content -Path "$env:TEMP\mcp-test-error.txt" -Raw
        
        # Afficher la sortie
        if ($Output) {
            Write-Host $Output
        }
        
        # Afficher les erreurs
        if ($Error) {
            Write-Host $Error -ForegroundColor Red
        }
        
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        $Result = @{
            Name = $Test.Name
            Script = $Test.Script
            Description = $Test.Description
            ExitCode = $Process.ExitCode
            Output = $Output
            Error = $Error
            Duration = $Duration
            Success = $Process.ExitCode -eq 0
            Timestamp = Get-Date -Format "o"
        }
        
        if ($Process.ExitCode -eq 0) {
            Write-ColorMessage "`n✓ Test réussi en $([math]::Round($Duration, 2)) secondes" -ForegroundColor Green
        } else {
            Write-ColorMessage "`n✗ Test échoué avec le code $($Process.ExitCode) en $([math]::Round($Duration, 2)) secondes" -ForegroundColor Red
        }
        
        return $Result
    }
    catch {
        Write-ColorMessage "Erreur lors de l'exécution du test: $_" -ForegroundColor Red
        
        return @{
            Name = $Test.Name
            Script = $Test.Script
            Description = $Test.Description
            ExitCode = -1
            Output = ""
            Error = $_.ToString()
            Duration = 0
            Success = $false
            Timestamp = Get-Date -Format "o"
        }
    }
    finally {
        # Nettoyer les fichiers temporaires
        if (Test-Path "$env:TEMP\mcp-test-output.txt") {
            Remove-Item -Path "$env:TEMP\mcp-test-output.txt" -Force
        }
        
        if (Test-Path "$env:TEMP\mcp-test-error.txt") {
            Remove-Item -Path "$env:TEMP\mcp-test-error.txt" -Force
        }
    }
}

# Fonction pour générer un rapport de test
function New-TestReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results
    )
    
    # Créer le répertoire de rapports s'il n'existe pas
    if (!(Test-Path $ReportDir)) {
        New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null
    }
    
    # Calculer les statistiques
    $TotalTests = $Results.Count
    $PassedTests = ($Results | Where-Object { $_.Success }).Count
    $FailedTests = $TotalTests - $PassedTests
    $SuccessRate = ($PassedTests / $TotalTests) * 100
    
    # Générer le contenu du rapport
    $Report = "# Rapport de test des nodes MCP pour n8n`n`n"
    $Report += "Date: $(Get-Date -Format 'o')`n`n"
    
    $Report += "## Résumé`n`n"
    $Report += "- **Total des tests**: $TotalTests`n"
    $Report += "- **Tests réussis**: $PassedTests`n"
    $Report += "- **Tests échoués**: $FailedTests`n"
    $Report += "- **Taux de réussite**: $([math]::Round($SuccessRate, 2))%`n`n"
    
    $Report += "## Détails des tests`n`n"
    
    for ($i = 0; $i -lt $Results.Count; $i++) {
        $Result = $Results[$i]
        
        $Report += "### $($i + 1). $($Result.Name)`n`n"
        $Report += "- **Script**: ``$($Result.Script)```n"
        $Report += "- **Description**: $($Result.Description)`n"
        $Report += "- **Statut**: $(if ($Result.Success) { '✅ Réussi' } else { '❌ Échoué' })`n"
        $Report += "- **Code de sortie**: $($Result.ExitCode)`n"
        $Report += "- **Durée**: $([math]::Round($Result.Duration, 2)) secondes`n"
        $Report += "- **Horodatage**: $($Result.Timestamp)`n`n"
        
        if (!$Result.Success) {
            $Report += "#### Erreurs`n`n"
            $Report += "````n"
            $Report += $Result.Error -or "Aucune erreur spécifique rapportée"
            $Report += "`n````n`n"
        }
        
        $Report += "#### Sortie`n`n"
        $Report += "````n"
        $Report += $Result.Output -or "Aucune sortie"
        $Report += "`n````n`n"
    }
    
    # Écrire le rapport dans un fichier
    $Report | Out-File -FilePath $ReportFile -Encoding utf8
    
    Write-ColorMessage "`nRapport de test généré: $ReportFile" -ForegroundColor Cyan
}

# Fonction principale pour exécuter tous les tests
function Invoke-AllTests {
    Write-ColorMessage "=== Exécution de tous les tests des nodes MCP ===" -ForegroundColor Magenta
    Write-ColorMessage "Date: $(Get-Date -Format 'o')"
    Write-ColorMessage "Nombre de tests à exécuter: $($Tests.Count)"
    Write-ColorMessage ""
    
    try {
        # Exécuter chaque test séquentiellement
        foreach ($Test in $Tests) {
            $Result = Invoke-Test -Test $Test
            $TestResults += $Result
        }
        
        # Générer le rapport
        New-TestReport -Results $TestResults
        
        # Afficher le résumé
        $PassedTests = ($TestResults | Where-Object { $_.Success }).Count
        $FailedTests = $TestResults.Count - $PassedTests
        
        Write-ColorMessage "`n=== Résumé des tests ===" -ForegroundColor Magenta
        Write-ColorMessage "Total: $($TestResults.Count)"
        Write-ColorMessage "Réussis: $PassedTests" -ForegroundColor Green
        Write-ColorMessage "Échoués: $FailedTests" -ForegroundColor Red
        
        # Retourner le code de sortie approprié
        if ($FailedTests -gt 0) {
            exit 1
        } else {
            exit 0
        }
    }
    catch {
        Write-ColorMessage "Erreur lors de l'exécution des tests: $_" -ForegroundColor Red
        exit 1
    }
}

# Exécuter tous les tests
Invoke-AllTests
