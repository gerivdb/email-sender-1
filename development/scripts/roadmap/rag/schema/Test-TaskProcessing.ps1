# Test-TaskProcessing.ps1
# Script de test pour vérifier l'implémentation du traitement des tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'implémentation du traitement des tâches de roadmap.

.DESCRIPTION
    Ce script exécute une série de tests pour vérifier le bon fonctionnement des scripts
    Detect-TaskAnomalies.ps1 et Process-Task.ps1.

.PARAMETER Verbose
    Affiche des informations détaillées sur les tests exécutés.

.EXAMPLE
    .\Test-TaskProcessing.ps1 -Verbose

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding()]
param()

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$detectTaskAnomaliesPath = Join-Path -Path $scriptPath -ChildPath "Detect-TaskAnomalies.ps1"
$processTaskPath = Join-Path -Path $scriptPath -ChildPath "Process-Task.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $detectTaskAnomaliesPath)) {
    Write-Error "Le fichier Detect-TaskAnomalies.ps1 est introuvable."
    exit 1
}

if (-not (Test-Path -Path $processTaskPath)) {
    Write-Error "Le fichier Process-Task.ps1 est introuvable."
    exit 1
}

# Importer les scripts
. $detectTaskAnomaliesPath
. $processTaskPath

# Fonction pour exécuter un test
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )
    
    Write-Verbose "Exécution du test: $Name"
    
    try {
        $result = & $Test
        
        if ($result) {
            Write-Host "[SUCCÈS] $Name" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[ÉCHEC] $Name" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERREUR] $Name : $_" -ForegroundColor Red
        return $false
    }
}

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Vérifier que les fonctions de Detect-TaskAnomalies.ps1 sont disponibles
$totalTests++
$result = Invoke-Test -Name "Vérification des fonctions de Detect-TaskAnomalies.ps1" -Test {
    $functions = @(
        "Detect-TaskAnomalies"
    )
    
    $allFunctionsAvailable = $true
    
    foreach ($function in $functions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Verbose "Fonction non disponible: $function"
            $allFunctionsAvailable = $false
        }
    }
    
    return $allFunctionsAvailable
}
if ($result) { $passedTests++ }

# Test 2: Vérifier que les fonctions de Process-Task.ps1 sont disponibles
$totalTests++
$result = Invoke-Test -Name "Vérification des fonctions de Process-Task.ps1" -Test {
    $functions = @(
        "Process-Task",
        "Process-TaskFile"
    )
    
    $allFunctionsAvailable = $true
    
    foreach ($function in $functions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Verbose "Fonction non disponible: $function"
            $allFunctionsAvailable = $false
        }
    }
    
    return $allFunctionsAvailable
}
if ($result) { $passedTests++ }

# Test 3: Vérifier la détection d'anomalies structurelles
$totalTests++
$result = Invoke-Test -Name "Détection d'anomalies structurelles" -Test {
    $task = @{
        # Champ obligatoire manquant: status
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
        # Champ inconnu
        unknownField = "valeur inconnue"
    }
    
    $anomalies = Detect-TaskAnomalies -Task $task -AnomalyTypes "Structure"
    
    $structuralAnomaliesDetected = $false
    $missingStatusDetected = $false
    $unknownFieldDetected = $false
    
    foreach ($anomaly in $anomalies) {
        if ($anomaly.Type -eq "Structure") {
            $structuralAnomaliesDetected = $true
            
            if ($anomaly.Message -like "*Champs obligatoires manquants*" -and $anomaly.Fields -contains "status") {
                $missingStatusDetected = $true
            }
            
            if ($anomaly.Message -like "*Champs inconnus présents*" -and $anomaly.Fields -contains "unknownField") {
                $unknownFieldDetected = $true
            }
        }
    }
    
    return $structuralAnomaliesDetected -and $missingStatusDetected -and $unknownFieldDetected
}
if ($result) { $passedTests++ }

# Test 4: Vérifier la détection d'anomalies de valeurs
$totalTests++
$result = Invoke-Test -Name "Détection d'anomalies de valeurs" -Test {
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
        estimatedHours = 1000  # Valeur aberrante
        progress = 150  # Valeur aberrante
    }
    
    $anomalies = Detect-TaskAnomalies -Task $task -AnomalyTypes "Values"
    
    $valueAnomaliesDetected = $false
    $estimatedHoursAnomalyDetected = $false
    $progressAnomalyDetected = $false
    
    foreach ($anomaly in $anomalies) {
        if ($anomaly.Type -eq "Values") {
            $valueAnomaliesDetected = $true
            
            foreach ($detail in $anomaly.Details) {
                if ($detail.Field -eq "estimatedHours" -and $detail.Value -eq 1000) {
                    $estimatedHoursAnomalyDetected = $true
                }
                
                if ($detail.Field -eq "progress" -and $detail.Value -eq 150) {
                    $progressAnomalyDetected = $true
                }
            }
        }
    }
    
    return $valueAnomaliesDetected -and $estimatedHoursAnomalyDetected -and $progressAnomalyDetected
}
if ($result) { $passedTests++ }

# Test 5: Vérifier la détection d'anomalies de références
$totalTests++
$result = Invoke-Test -Name "Détection d'anomalies de références" -Test {
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
        dependencies = @("1.2.3")  # Auto-dépendance
    }
    
    $anomalies = Detect-TaskAnomalies -Task $task -AnomalyTypes "References"
    
    $referenceAnomaliesDetected = $false
    $selfDependencyDetected = $false
    
    foreach ($anomaly in $anomalies) {
        if ($anomaly.Type -eq "References") {
            $referenceAnomaliesDetected = $true
            
            foreach ($detail in $anomaly.Details) {
                if ($detail.Message -like "*Auto-dépendance détectée*") {
                    $selfDependencyDetected = $true
                }
            }
        }
    }
    
    return $referenceAnomaliesDetected -and $selfDependencyDetected
}
if ($result) { $passedTests++ }

# Test 6: Vérifier la détection d'anomalies de dates
$totalTests++
$result = Invoke-Test -Name "Détection d'anomalies de dates" -Test {
    $now = Get-Date
    $yesterday = $now.AddDays(-1)
    $tomorrow = $now.AddDays(1)
    
    $task = @{
        id = "1.2.3"
        title = "Implémenter la validation de schéma"
        status = "InProgress"
        createdAt = $tomorrow.ToUniversalTime().ToString("o")  # Date de création dans le futur
        updatedAt = $yesterday.ToUniversalTime().ToString("o")  # Date de mise à jour antérieure à la date de création
    }
    
    $anomalies = Detect-TaskAnomalies -Task $task -AnomalyTypes "Dates"
    
    $dateAnomaliesDetected = $false
    $createdInFutureDetected = $false
    $updatedBeforeCreatedDetected = $false
    
    foreach ($anomaly in $anomalies) {
        if ($anomaly.Type -eq "Dates") {
            $dateAnomaliesDetected = $true
            
            foreach ($detail in $anomaly.Details) {
                if ($detail.Message -like "*La date de mise à jour est antérieure à la date de création*") {
                    $updatedBeforeCreatedDetected = $true
                }
            }
        }
    }
    
    return $dateAnomaliesDetected -and $updatedBeforeCreatedDetected
}
if ($result) { $passedTests++ }

# Test 7: Vérifier le traitement complet d'une tâche
$totalTests++
$result = Invoke-Test -Name "Traitement complet d'une tâche" -Test {
    $task = @{
        id = "1.2.3"
        title = "  implémenter la validation de schéma  "
        status = "inprogress"
        createdAt = "2025-05-15T10:00:00"
        updatedAt = "2025-05-14T10:00:00"  # Date de mise à jour antérieure à la date de création
        estimatedHours = "2h"
        progress = 150  # Valeur aberrante
        tags = @("important", "URGENT")
    }
    
    $report = Process-Task -Task $task -Validate -Normalize -DetectAnomalies -FixAnomalies -OutputReport
    
    $processingSuccessful = $report.Success
    $normalizationApplied = $report.NormalizationApplied
    $anomaliesDetected = $report.Anomalies.Count -gt 0
    $fixesApplied = $report.FixesApplied.Count -gt 0
    
    $titleNormalized = $report.ProcessedTask.title -eq "Implémenter La Validation De Schéma"
    $statusNormalized = $report.ProcessedTask.status -eq "InProgress"
    $estimatedHoursNormalized = $report.ProcessedTask.estimatedHours -eq 2.0
    $progressFixed = $report.ProcessedTask.progress -eq 100
    $datesFixed = $report.ProcessedTask.updatedAt -eq $report.ProcessedTask.createdAt
    
    return $processingSuccessful -and $normalizationApplied -and $anomaliesDetected -and $fixesApplied -and
           $titleNormalized -and $statusNormalized -and $estimatedHoursNormalized -and $progressFixed -and $datesFixed
}
if ($result) { $passedTests++ }

# Test 8: Vérifier le traitement d'un fichier JSON
$totalTests++
$result = Invoke-Test -Name "Traitement d'un fichier JSON" -Test {
    # Créer un fichier JSON temporaire
    $tempFile = [System.IO.Path]::GetTempFileName()
    $tempFile = [System.IO.Path]::ChangeExtension($tempFile, "json")
    
    $task = @{
        id = "1.2.3"
        title = "  implémenter la validation de schéma  "
        status = "inprogress"
        createdAt = "2025-05-15T10:00:00"
        updatedAt = "2025-05-14T10:00:00"
        estimatedHours = "2h"
        progress = 150
        tags = @("important", "URGENT")
    }
    
    $json = ConvertTo-Json -InputObject $task -Depth 10
    Set-Content -Path $tempFile -Value $json -Encoding UTF8
    
    # Traiter le fichier
    $outputFile = [System.IO.Path]::GetTempFileName()
    $outputFile = [System.IO.Path]::ChangeExtension($outputFile, "json")
    
    $result = Process-TaskFile -FilePath $tempFile -OutputPath $outputFile -Validate -Normalize -DetectAnomalies -FixAnomalies -OutputReport
    
    # Vérifier que les fichiers ont été créés
    $outputFileExists = Test-Path -Path $outputFile
    $reportFileExists = Test-Path -Path ([System.IO.Path]::ChangeExtension($outputFile, "report.json"))
    
    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $tempFile) {
        Remove-Item -Path $tempFile -Force
    }
    
    if (Test-Path -Path $outputFile) {
        Remove-Item -Path $outputFile -Force
    }
    
    if (Test-Path -Path ([System.IO.Path]::ChangeExtension($outputFile, "report.json"))) {
        Remove-Item -Path ([System.IO.Path]::ChangeExtension($outputFile, "report.json")) -Force
    }
    
    return $result.Success -and $outputFileExists -and $reportFileExists
}
if ($result) { $passedTests++ }

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Tests exécutés: $totalTests" -ForegroundColor Cyan
Write-Host "Tests réussis: $passedTests" -ForegroundColor Cyan
Write-Host "Tests échoués: $($totalTests - $passedTests)" -ForegroundColor Cyan

# Retourner le résultat global
return $passedTests -eq $totalTests
