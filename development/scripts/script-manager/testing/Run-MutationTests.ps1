#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute des tests de mutation pour le script manager.
.DESCRIPTION
    Ce script exécute des tests de mutation pour vérifier la qualité des tests existants.
    Les tests de mutation modifient légèrement le code source et vérifient si les tests
    détectent ces modifications.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    Génère un rapport HTML des résultats des tests.
.PARAMETER MaxMutations
    Nombre maximum de mutations à effectuer.
.EXAMPLE
    .\Run-MutationTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML -MaxMutations 10
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\mutation",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxMutations = 5
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

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installé. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Fonction pour créer une mutation du code source
function New-CodeMutation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceCode,
        
        [Parameter(Mandatory = $true)]
        [string]$MutationType,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$MutationParams = @{}
    )
    
    $mutatedCode = $SourceCode
    
    switch ($MutationType) {
        "ChangeReturnValue" {
            # Remplacer une valeur de retour
            $pattern = "return\s+'([^']+)'"
            $matches = [regex]::Matches($SourceCode, $pattern)
            
            if ($matches.Count -gt 0) {
                $randomIndex = Get-Random -Minimum 0 -Maximum $matches.Count
                $match = $matches[$randomIndex]
                $originalValue = $match.Groups[1].Value
                $newValue = $MutationParams.NewValue -or "mutated_$originalValue"
                
                $mutatedCode = $SourceCode.Substring(0, $match.Groups[1].Index) + 
                               $newValue + 
                               $SourceCode.Substring($match.Groups[1].Index + $match.Groups[1].Length)
                
                return @{
                    MutatedCode = $mutatedCode
                    Description = "Valeur de retour modifiée: '$originalValue' -> '$newValue'"
                    LineNumber = ($SourceCode.Substring(0, $match.Index).Split("`n")).Count
                    OriginalValue = $originalValue
                    NewValue = $newValue
                }
            }
        }
        "ChangeCondition" {
            # Inverser une condition
            $pattern = "if\s*\(([^)]+)\)"
            $matches = [regex]::Matches($SourceCode, $pattern)
            
            if ($matches.Count -gt 0) {
                $randomIndex = Get-Random -Minimum 0 -Maximum $matches.Count
                $match = $matches[$randomIndex]
                $originalCondition = $match.Groups[1].Value
                $newCondition = "-not ($originalCondition)"
                
                $mutatedCode = $SourceCode.Substring(0, $match.Groups[1].Index) + 
                               $newCondition + 
                               $SourceCode.Substring($match.Groups[1].Index + $match.Groups[1].Length)
                
                return @{
                    MutatedCode = $mutatedCode
                    Description = "Condition inversée: '$originalCondition' -> '$newCondition'"
                    LineNumber = ($SourceCode.Substring(0, $match.Index).Split("`n")).Count
                    OriginalValue = $originalCondition
                    NewValue = $newCondition
                }
            }
        }
        "RemoveCode" {
            # Supprimer une ligne de code
            $lines = $SourceCode -split "`n"
            $nonEmptyLines = @()
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                if ($line.Trim() -ne "" -and -not $line.Trim().StartsWith("#")) {
                    $nonEmptyLines += @{
                        Index = $i
                        Line = $line
                    }
                }
            }
            
            if ($nonEmptyLines.Count -gt 0) {
                $randomIndex = Get-Random -Minimum 0 -Maximum $nonEmptyLines.Count
                $lineToRemove = $nonEmptyLines[$randomIndex]
                
                $newLines = $lines.Clone()
                $newLines[$lineToRemove.Index] = "# Ligne supprimée: $($lineToRemove.Line.Trim())"
                $mutatedCode = $newLines -join "`n"
                
                return @{
                    MutatedCode = $mutatedCode
                    Description = "Ligne supprimée: '$($lineToRemove.Line.Trim())'"
                    LineNumber = $lineToRemove.Index + 1
                    OriginalValue = $lineToRemove.Line.Trim()
                    NewValue = "# Ligne supprimée: $($lineToRemove.Line.Trim())"
                }
            }
        }
        "ChangeVariable" {
            # Modifier la valeur d'une variable
            $pattern = "\$([a-zA-Z0-9_]+)\s*=\s*([^;]+)"
            $matches = [regex]::Matches($SourceCode, $pattern)
            
            if ($matches.Count -gt 0) {
                $randomIndex = Get-Random -Minimum 0 -Maximum $matches.Count
                $match = $matches[$randomIndex]
                $variableName = $match.Groups[1].Value
                $originalValue = $match.Groups[2].Value.Trim()
                $newValue = "'mutated_$variableName'"
                
                $mutatedCode = $SourceCode.Substring(0, $match.Groups[2].Index) + 
                               $newValue + 
                               $SourceCode.Substring($match.Groups[2].Index + $match.Groups[2].Length)
                
                return @{
                    MutatedCode = $mutatedCode
                    Description = "Valeur de variable modifiée: '$variableName' = '$originalValue' -> '$newValue'"
                    LineNumber = ($SourceCode.Substring(0, $match.Index).Split("`n")).Count
                    OriginalValue = $originalValue
                    NewValue = $newValue
                }
            }
        }
        "ChangeRegex" {
            # Modifier une expression régulière
            $pattern = "-match\s+'([^']+)'"
            $matches = [regex]::Matches($SourceCode, $pattern)
            
            if ($matches.Count -gt 0) {
                $randomIndex = Get-Random -Minimum 0 -Maximum $matches.Count
                $match = $matches[$randomIndex]
                $originalRegex = $match.Groups[1].Value
                $newRegex = "INVALID_REGEX_$originalRegex"
                
                $mutatedCode = $SourceCode.Substring(0, $match.Groups[1].Index) + 
                               $newRegex + 
                               $SourceCode.Substring($match.Groups[1].Index + $match.Groups[1].Length)
                
                return @{
                    MutatedCode = $mutatedCode
                    Description = "Expression régulière modifiée: '$originalRegex' -> '$newRegex'"
                    LineNumber = ($SourceCode.Substring(0, $match.Index).Split("`n")).Count
                    OriginalValue = $originalRegex
                    NewValue = $newRegex
                }
            }
        }
    }
    
    return $null
}

# Fonction pour exécuter les tests sur une version mutée du code
function Test-MutatedCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OriginalFilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$MutatedCode,
        
        [Parameter(Mandatory = $true)]
        [string]$TestFilePath
    )
    
    # Créer un fichier temporaire avec le code muté
    $tempFilePath = [System.IO.Path]::GetTempFileName() + ".ps1"
    $MutatedCode | Out-File -FilePath $tempFilePath -Encoding utf8
    
    try {
        # Exécuter les tests avec le code muté
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $TestFilePath
        $pesterConfig.Output.Verbosity = "None"
        $pesterConfig.Run.PassThru = $true
        
        # Remplacer temporairement le fichier original par le fichier muté
        $originalContent = Get-Content -Path $OriginalFilePath -Raw
        $MutatedCode | Out-File -FilePath $OriginalFilePath -Encoding utf8
        
        # Exécuter les tests
        $testResults = Invoke-Pester -Configuration $pesterConfig
        
        # Restaurer le fichier original
        $originalContent | Out-File -FilePath $OriginalFilePath -Encoding utf8
        
        return $testResults
    }
    catch {
        Write-Log "Erreur lors de l'exécution des tests: $_" -Level "ERROR"
        return $null
    }
    finally {
        # Supprimer le fichier temporaire
        if (Test-Path -Path $tempFilePath) {
            Remove-Item -Path $tempFilePath -Force
        }
        
        # S'assurer que le fichier original est restauré
        if (-not (Get-Content -Path $OriginalFilePath -Raw -eq $originalContent)) {
            $originalContent | Out-File -FilePath $OriginalFilePath -Encoding utf8
        }
    }
}

# Fichiers à tester
$filesToTest = @(
    @{
        SourcePath = "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1"
        TestPath = "$PSScriptRoot/OrganizationFunctions.Fixed.Tests.ps1"
    }
)

# Types de mutations à effectuer
$mutationTypes = @(
    "ChangeReturnValue",
    "ChangeCondition",
    "RemoveCode",
    "ChangeVariable",
    "ChangeRegex"
)

# Exécuter les tests de mutation
$mutationResults = @()
$mutationCount = 0

foreach ($file in $filesToTest) {
    Write-Log "Test de mutation pour le fichier: $($file.SourcePath)" -Level "INFO"
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path -Path $file.SourcePath)) {
        Write-Log "Le fichier source n'existe pas: $($file.SourcePath)" -Level "ERROR"
        continue
    }
    
    if (-not (Test-Path -Path $file.TestPath)) {
        Write-Log "Le fichier de test n'existe pas: $($file.TestPath)" -Level "ERROR"
        continue
    }
    
    # Lire le contenu du fichier source
    $sourceCode = Get-Content -Path $file.SourcePath -Raw
    
    # Exécuter les tests originaux pour vérifier qu'ils passent
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $file.TestPath
    $pesterConfig.Output.Verbosity = "None"
    $pesterConfig.Run.PassThru = $true
    
    $originalTestResults = Invoke-Pester -Configuration $pesterConfig
    
    if ($originalTestResults.FailedCount -gt 0) {
        Write-Log "Les tests originaux échouent. Impossible de continuer les tests de mutation." -Level "ERROR"
        continue
    }
    
    # Créer des mutations et exécuter les tests
    for ($i = 0; $i -lt $MaxMutations; $i++) {
        # Sélectionner un type de mutation aléatoire
        $mutationType = $mutationTypes | Get-Random
        
        # Créer une mutation
        $mutation = New-CodeMutation -SourceCode $sourceCode -MutationType $mutationType
        
        if ($null -eq $mutation) {
            Write-Log "Impossible de créer une mutation de type '$mutationType'." -Level "WARNING"
            continue
        }
        
        Write-Log "Mutation $($i + 1)/$MaxMutations: $($mutation.Description)" -Level "INFO"
        
        # Exécuter les tests sur le code muté
        $mutatedTestResults = Test-MutatedCode -OriginalFilePath $file.SourcePath -MutatedCode $mutation.MutatedCode -TestFilePath $file.TestPath
        
        if ($null -eq $mutatedTestResults) {
            Write-Log "Erreur lors de l'exécution des tests sur le code muté." -Level "ERROR"
            continue
        }
        
        # Vérifier si les tests ont détecté la mutation
        $mutationDetected = $mutatedTestResults.FailedCount -gt 0
        
        # Ajouter les résultats
        $mutationResults += [PSCustomObject]@{
            SourceFile = $file.SourcePath
            TestFile = $file.TestPath
            MutationType = $mutationType
            Description = $mutation.Description
            LineNumber = $mutation.LineNumber
            OriginalValue = $mutation.OriginalValue
            NewValue = $mutation.NewValue
            Detected = $mutationDetected
            FailedTests = $mutatedTestResults.FailedCount
            TotalTests = $mutatedTestResults.TotalCount
        }
        
        $mutationCount++
        
        if ($mutationDetected) {
            Write-Log "  Mutation détectée: $($mutatedTestResults.FailedCount) test(s) échoué(s)" -Level "SUCCESS"
        }
        else {
            Write-Log "  Mutation non détectée: tous les tests ont réussi" -Level "ERROR"
        }
    }
}

# Calculer les statistiques
$totalMutations = $mutationResults.Count
$detectedMutations = ($mutationResults | Where-Object { $_.Detected } | Measure-Object).Count
$detectionRate = if ($totalMutations -gt 0) { [math]::Round(($detectedMutations / $totalMutations) * 100, 2) } else { 0 }

Write-Log "`nRésumé des tests de mutation:" -Level "INFO"
Write-Log "  Mutations totales: $totalMutations" -Level "INFO"
Write-Log "  Mutations détectées: $detectedMutations" -Level "SUCCESS"
Write-Log "  Mutations non détectées: $($totalMutations - $detectedMutations)" -Level "ERROR"
Write-Log "  Taux de détection: $detectionRate%" -Level $(if ($detectionRate -ge 80) { "SUCCESS" } elseif ($detectionRate -ge 60) { "WARNING" } else { "ERROR" })

# Exporter les résultats au format JSON
$jsonPath = Join-Path -Path $OutputPath -ChildPath "MutationResults.json"
$mutationResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8
Write-Log "Résultats exportés au format JSON: $jsonPath" -Level "SUCCESS"

# Exporter les résultats au format CSV
$csvPath = Join-Path -Path $OutputPath -ChildPath "MutationResults.csv"
$mutationResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8
Write-Log "Résultats exportés au format CSV: $csvPath" -Level "SUCCESS"

# Générer un rapport HTML si demandé
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "MutationResults.html"
    
    # Créer un rapport HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests de mutation</title>
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
        .chart-container { width: 100%; height: 400px; margin-bottom: 20px; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de tests de mutation</h1>
    <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Mutations totales: $totalMutations</p>
        <p class="success">Mutations détectées: $detectedMutations</p>
        <p class="error">Mutations non détectées: $($totalMutations - $detectedMutations)</p>
        <p>Taux de détection: <span class="$(if ($detectionRate -ge 80) { "success" } elseif ($detectionRate -ge 60) { "warning" } else { "error" })">$detectionRate%</span></p>
    </div>
    
    <div class="chart-container">
        <canvas id="detectionRateChart"></canvas>
    </div>
    
    <h2>Détails des mutations</h2>
    <table>
        <tr>
            <th>Fichier source</th>
            <th>Type de mutation</th>
            <th>Description</th>
            <th>Ligne</th>
            <th>Détectée</th>
            <th>Tests échoués</th>
            <th>Tests totaux</th>
        </tr>
"@

    foreach ($result in $mutationResults) {
        $htmlContent += @"
        <tr>
            <td>$($result.SourceFile)</td>
            <td>$($result.MutationType)</td>
            <td>$($result.Description)</td>
            <td>$($result.LineNumber)</td>
            <td class="$(if ($result.Detected) { "success" } else { "error" })">$($result.Detected)</td>
            <td>$($result.FailedTests)</td>
            <td>$($result.TotalTests)</td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
    
    <h2>Qu'est-ce que les tests de mutation?</h2>
    <p>Les tests de mutation sont une technique de test qui consiste à introduire des modifications (mutations) dans le code source et à vérifier si les tests existants détectent ces modifications. Si les tests détectent la mutation, cela signifie qu'ils sont efficaces. Si les tests ne détectent pas la mutation, cela signifie qu'ils ne sont pas assez robustes.</p>
    
    <h3>Types de mutations</h3>
    <ul>
        <li><strong>ChangeReturnValue</strong>: Modifie la valeur de retour d'une fonction</li>
        <li><strong>ChangeCondition</strong>: Inverse une condition dans une instruction if</li>
        <li><strong>RemoveCode</strong>: Supprime une ligne de code</li>
        <li><strong>ChangeVariable</strong>: Modifie la valeur d'une variable</li>
        <li><strong>ChangeRegex</strong>: Modifie une expression régulière</li>
    </ul>
    
    <h3>Interprétation des résultats</h3>
    <p>Un taux de détection élevé (> 80%) indique que les tests sont robustes et détectent efficacement les erreurs dans le code. Un taux de détection faible (< 60%) indique que les tests ne sont pas assez robustes et qu'ils devraient être améliorés.</p>
    
    <script>
        // Données pour les graphiques
        const detectionRateCtx = document.getElementById('detectionRateChart').getContext('2d');
        new Chart(detectionRateCtx, {
            type: 'pie',
            data: {
                labels: ['Détectées', 'Non détectées'],
                datasets: [{
                    data: [$detectedMutations, $($totalMutations - $detectedMutations)],
                    backgroundColor: ['rgba(75, 192, 192, 0.5)', 'rgba(255, 99, 132, 0.5)'],
                    borderColor: ['rgba(75, 192, 192, 1)', 'rgba(255, 99, 132, 1)'],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Taux de détection des mutations'
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML généré: $htmlPath" -Level "SUCCESS"
}

Write-Log "Tests de mutation terminés." -Level "SUCCESS"
