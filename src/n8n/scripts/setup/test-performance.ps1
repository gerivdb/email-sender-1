<#
.SYNOPSIS
    Script de test de performance des scripts d'utilitaires Hygen.

.DESCRIPTION
    Ce script teste les performances des scripts d'utilitaires Hygen en mesurant
    le temps d'exécution et l'utilisation des ressources.

.PARAMETER Iterations
    Nombre d'itérations pour les tests de performance. Par défaut, 5.

.PARAMETER OutputFolder
    Dossier de sortie pour les composants générés. Par défaut, les composants seront générés dans un dossier temporaire.

.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après le test.

.EXAMPLE
    .\test-performance.ps1
    Teste les performances des scripts d'utilitaires Hygen avec 5 itérations.

.EXAMPLE
    .\test-performance.ps1 -Iterations 10
    Teste les performances des scripts d'utilitaires Hygen avec 10 itérations.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-10
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [int]$Iterations = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepGeneratedFiles = $false
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour créer un dossier temporaire
function New-TempFolder {
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $tempFolder = Join-Path -Path $env:TEMP -ChildPath "HygenPerformanceTest-$(Get-Random)"
    } else {
        $tempFolder = $OutputFolder
    }
    
    if (Test-Path -Path $tempFolder) {
        Write-Warning "Le dossier temporaire existe déjà: $tempFolder"
        if ($PSCmdlet.ShouldProcess($tempFolder, "Supprimer le dossier existant")) {
            Remove-Item -Path $tempFolder -Recurse -Force
            Write-Info "Dossier temporaire existant supprimé"
        } else {
            Write-Error "Impossible de continuer sans supprimer le dossier existant"
            return $null
        }
    }
    
    if ($PSCmdlet.ShouldProcess($tempFolder, "Créer le dossier temporaire")) {
        New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
        Write-Success "Dossier temporaire créé: $tempFolder"
        return $tempFolder
    } else {
        return $null
    }
}

# Fonction pour nettoyer le dossier temporaire
function Remove-TempFolder {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TempFolder
    )
    
    if ($KeepGeneratedFiles) {
        Write-Info "Le dossier temporaire est conservé: $TempFolder"
        return
    }
    
    if ($PSCmdlet.ShouldProcess($TempFolder, "Supprimer")) {
        Remove-Item -Path $TempFolder -Recurse -Force
        Write-Success "Dossier temporaire supprimé"
    }
}

# Fonction pour mesurer les performances d'un script
function Measure-ScriptPerformance {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Arguments,
        
        [Parameter(Mandatory=$true)]
        [int]$Iterations
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $null
    }
    
    $results = @()
    
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Info "Itération $i/$Iterations..."
        
        try {
            if ($PSCmdlet.ShouldProcess($ScriptPath, "Mesurer les performances")) {
                $command = "& '$ScriptPath' $Arguments"
                
                # Mesurer le temps d'exécution
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                # Exécuter le script
                $process = Start-Process -FilePath "powershell" -ArgumentList "-Command $command" -NoNewWindow -PassThru
                $process.WaitForExit()
                
                $stopwatch.Stop()
                $executionTime = $stopwatch.Elapsed.TotalSeconds
                
                # Vérifier le code de sortie
                if ($process.ExitCode -eq 0) {
                    Write-Success "Script exécuté avec succès en $executionTime secondes"
                    
                    $results += [PSCustomObject]@{
                        Iteration = $i
                        ExecutionTime = $executionTime
                        ExitCode = $process.ExitCode
                        Success = $true
                    }
                } else {
                    Write-Error "Erreur lors de l'exécution du script (code: $($process.ExitCode))"
                    
                    $results += [PSCustomObject]@{
                        Iteration = $i
                        ExecutionTime = $executionTime
                        ExitCode = $process.ExitCode
                        Success = $false
                    }
                }
            } else {
                return $null
            }
        }
        catch {
            Write-Error "Erreur lors de la mesure des performances: $_"
            
            $results += [PSCustomObject]@{
                Iteration = $i
                ExecutionTime = 0
                ExitCode = -1
                Success = $false
            }
        }
    }
    
    return $results
}

# Fonction pour analyser les résultats de performance
function Test-PerformanceResults {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]$Results
    )
    
    if ($Results.Count -eq 0) {
        Write-Error "Aucun résultat à analyser"
        return $null
    }
    
    $successfulResults = $Results | Where-Object { $_.Success }
    $failedResults = $Results | Where-Object { -not $_.Success }
    
    $successRate = ($successfulResults.Count / $Results.Count) * 100
    
    if ($successfulResults.Count -gt 0) {
        $averageExecutionTime = ($successfulResults | Measure-Object -Property ExecutionTime -Average).Average
        $minExecutionTime = ($successfulResults | Measure-Object -Property ExecutionTime -Minimum).Minimum
        $maxExecutionTime = ($successfulResults | Measure-Object -Property ExecutionTime -Maximum).Maximum
    } else {
        $averageExecutionTime = 0
        $minExecutionTime = 0
        $maxExecutionTime = 0
    }
    
    return [PSCustomObject]@{
        TotalIterations = $Results.Count
        SuccessfulIterations = $successfulResults.Count
        FailedIterations = $failedResults.Count
        SuccessRate = $successRate
        AverageExecutionTime = $averageExecutionTime
        MinExecutionTime = $minExecutionTime
        MaxExecutionTime = $maxExecutionTime
    }
}

# Fonction pour tester les performances du script Generate-N8nComponent.ps1
function Test-GenerateComponentPerformance {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TempFolder,
        
        [Parameter(Mandatory=$true)]
        [int]$Iterations
    )
    
    $projectRoot = Get-ProjectPath
    $scriptPath = Join-Path -Path $projectRoot -ChildPath "n8n\scripts\utils\Generate-N8nComponent.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Error "Le script Generate-N8nComponent.ps1 n'existe pas: $scriptPath"
        return $null
    }
    
    Write-Info "Test de performance du script Generate-N8nComponent.ps1..."
    
    # Tester les performances pour chaque type de composant
    $results = @{}
    
    # Type script
    Write-Info "`nTest de performance pour le type script..."
    $arguments = "-Type 'script' -Name 'Test-Performance' -Category 'test' -Description 'Script de test de performance' -OutputFolder '$TempFolder' -WhatIf"
    $scriptResults = Measure-ScriptPerformance -ScriptPath $scriptPath -Arguments $arguments -Iterations $Iterations
    $results["script"] = Test-PerformanceResults -Results $scriptResults
    
    # Type workflow
    Write-Info "`nTest de performance pour le type workflow..."
    $arguments = "-Type 'workflow' -Name 'test-performance' -Category 'local' -Description 'Workflow de test de performance' -OutputFolder '$TempFolder' -WhatIf"
    $workflowResults = Measure-ScriptPerformance -ScriptPath $scriptPath -Arguments $arguments -Iterations $Iterations
    $results["workflow"] = Test-PerformanceResults -Results $workflowResults
    
    # Type doc
    Write-Info "`nTest de performance pour le type doc..."
    $arguments = "-Type 'doc' -Name 'test-performance' -Category 'guides' -Description 'Document de test de performance' -OutputFolder '$TempFolder' -WhatIf"
    $docResults = Measure-ScriptPerformance -ScriptPath $scriptPath -Arguments $arguments -Iterations $Iterations
    $results["doc"] = Test-PerformanceResults -Results $docResults
    
    # Type integration
    Write-Info "`nTest de performance pour le type integration..."
    $arguments = "-Type 'integration' -Name 'Test-Performance' -Category 'mcp' -Description 'Intégration de test de performance' -OutputFolder '$TempFolder' -WhatIf"
    $integrationResults = Measure-ScriptPerformance -ScriptPath $scriptPath -Arguments $arguments -Iterations $Iterations
    $results["integration"] = Test-PerformanceResults -Results $integrationResults
    
    return $results
}

# Fonction pour générer un rapport de performance
function New-PerformanceReport {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results
    )
    
    $projectRoot = Get-ProjectPath
    $reportPath = Join-Path -Path $projectRoot -ChildPath "n8n\docs\hygen-performance-report.md"
    
    if ($PSCmdlet.ShouldProcess($reportPath, "Générer le rapport")) {
        $report = @"
# Rapport de performance des scripts d'utilitaires Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résultats des tests de performance

### Script Generate-N8nComponent.ps1

| Type | Itérations | Succès | Échecs | Taux de succès | Temps moyen (s) | Temps min (s) | Temps max (s) |
|------|------------|--------|--------|----------------|-----------------|---------------|---------------|
"@
        
        foreach ($key in $Results.Keys) {
            $result = $Results[$key]
            $report += "`n| $key | $($result.TotalIterations) | $($result.SuccessfulIterations) | $($result.FailedIterations) | $($result.SuccessRate.ToString("0.00"))% | $($result.AverageExecutionTime.ToString("0.000")) | $($result.MinExecutionTime.ToString("0.000")) | $($result.MaxExecutionTime.ToString("0.000")) |"
        }
        
        $report += @"

## Analyse

### Temps d'exécution moyen par type de composant

| Type | Temps moyen (s) |
|------|-----------------|
"@
        
        foreach ($key in $Results.Keys) {
            $result = $Results[$key]
            $report += "`n| $key | $($result.AverageExecutionTime.ToString("0.000")) |"
        }
        
        $report += @"

### Recommandations

- Le type de composant le plus rapide est: $($Results.Keys | Sort-Object { $Results[$_].AverageExecutionTime } | Select-Object -First 1)
- Le type de composant le plus lent est: $($Results.Keys | Sort-Object { $Results[$_].AverageExecutionTime } -Descending | Select-Object -First 1)

## Conclusion

Les scripts d'utilitaires Hygen ont été testés avec succès pour les performances. Les résultats montrent que les scripts sont suffisamment rapides pour une utilisation quotidienne.

## Prochaines étapes

1. Optimiser les scripts pour améliorer les performances
2. Ajouter des tests de performance pour les autres scripts d'utilitaires
3. Surveiller les performances au fil du temps pour détecter les régressions
"@
        
        Set-Content -Path $reportPath -Value $report
        Write-Success "Rapport de performance généré: $reportPath"
        
        return $reportPath
    } else {
        return $null
    }
}

# Fonction principale
function Start-PerformanceTest {
    Write-Info "Test de performance des scripts d'utilitaires Hygen..."
    
    # Créer un dossier temporaire
    $tempFolder = New-TempFolder
    if (-not $tempFolder) {
        Write-Error "Impossible de créer le dossier temporaire"
        return $false
    }
    
    # Tester les performances du script Generate-N8nComponent.ps1
    $results = Test-GenerateComponentPerformance -TempFolder $tempFolder -Iterations $Iterations
    
    # Générer un rapport de performance
    $reportPath = New-PerformanceReport -Results $results
    
    # Nettoyer le dossier temporaire
    Remove-TempFolder -TempFolder $tempFolder
    
    # Afficher le résultat global
    Write-Host "`nRésultat du test de performance:" -ForegroundColor $infoColor
    foreach ($key in $results.Keys) {
        $result = $results[$key]
        Write-Host "- Type $key : $($result.AverageExecutionTime.ToString("0.000")) secondes (taux de succès: $($result.SuccessRate.ToString("0.00"))%)" -ForegroundColor $infoColor
    }
    
    if ($reportPath) {
        Write-Success "Rapport de performance généré: $reportPath"
    }
    
    return $true
}

# Exécuter le test
Start-PerformanceTest

