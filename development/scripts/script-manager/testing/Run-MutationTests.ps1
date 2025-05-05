#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests de mutation pour le script manager.
.DESCRIPTION
    Ce script exÃ©cute des tests de mutation pour vÃ©rifier la qualitÃ© des tests existants.
    Les tests de mutation modifient lÃ©gÃ¨rement le code source et vÃ©rifient si les tests
    dÃ©tectent ces modifications.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.PARAMETER MaxMutations
    Nombre maximum de mutations Ã  effectuer.
.EXAMPLE
    .\Run-MutationTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML -MaxMutations 10
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
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

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installÃ©. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# Fonction pour crÃ©er une mutation du code source
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
                    Description = "Valeur de retour modifiÃ©e: '$originalValue' -> '$newValue'"
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
                    Description = "Condition inversÃ©e: '$originalCondition' -> '$newCondition'"
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
                $newLines[$lineToRemove.Index] = "# Ligne supprimÃ©e: $($lineToRemove.Line.Trim())"
                $mutatedCode = $newLines -join "`n"
                
                return @{
                    MutatedCode = $mutatedCode
                    Description = "Ligne supprimÃ©e: '$($lineToRemove.Line.Trim())'"
                    LineNumber = $lineToRemove.Index + 1
                    OriginalValue = $lineToRemove.Line.Trim()
                    NewValue = "# Ligne supprimÃ©e: $($lineToRemove.Line.Trim())"
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
                    Description = "Valeur de variable modifiÃ©e: '$variableName' = '$originalValue' -> '$newValue'"
                    LineNumber = ($SourceCode.Substring(0, $match.Index).Split("`n")).Count
                    OriginalValue = $originalValue
                    NewValue = $newValue
                }
            }
        }
        "ChangeRegex" {
            # Modifier une expression rÃ©guliÃ¨re
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
                    Description = "Expression rÃ©guliÃ¨re modifiÃ©e: '$originalRegex' -> '$newRegex'"
                    LineNumber = ($SourceCode.Substring(0, $match.Index).Split("`n")).Count
                    OriginalValue = $originalRegex
                    NewValue = $newRegex
                }
            }
        }
    }
    
    return $null
}

# Fonction pour exÃ©cuter les tests sur une version mutÃ©e du code
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
    
    # CrÃ©er un fichier temporaire avec le code mutÃ©
    $tempFilePath = [System.IO.Path]::GetTempFileName() + ".ps1"
    $MutatedCode | Out-File -FilePath $tempFilePath -Encoding utf8
    
    try {
        # ExÃ©cuter les tests avec le code mutÃ©
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $TestFilePath
        $pesterConfig.Output.Verbosity = "None"
        $pesterConfig.Run.PassThru = $true
        
        # Remplacer temporairement le fichier original par le fichier mutÃ©
        $originalContent = Get-Content -Path $OriginalFilePath -Raw
        $MutatedCode | Out-File -FilePath $OriginalFilePath -Encoding utf8
        
        # ExÃ©cuter les tests
        $testResults = Invoke-Pester -Configuration $pesterConfig
        
        # Restaurer le fichier original
        $originalContent | Out-File -FilePath $OriginalFilePath -Encoding utf8
        
        return $testResults
    }
    catch {
        Write-Log "Erreur lors de l'exÃ©cution des tests: $_" -Level "ERROR"
        return $null
    }
    finally {
        # Supprimer le fichier temporaire
        if (Test-Path -Path $tempFilePath) {
            Remove-Item -Path $tempFilePath -Force
        }
        
        # S'assurer que le fichier original est restaurÃ©
        if (-not (Get-Content -Path $OriginalFilePath -Raw -eq $originalContent)) {
            $originalContent | Out-File -FilePath $OriginalFilePath -Encoding utf8
        }
    }
}

# Fichiers Ã  tester
$filesToTest = @(
    @{
        SourcePath = "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1"
        TestPath = "$PSScriptRoot/OrganizationFunctions.Fixed.Tests.ps1"
    }
)

# Types de mutations Ã  effectuer
$mutationTypes = @(
    "ChangeReturnValue",
    "ChangeCondition",
    "RemoveCode",
    "ChangeVariable",
    "ChangeRegex"
)

# ExÃ©cuter les tests de mutation
$mutationResults = @()
$mutationCount = 0

foreach ($file in $filesToTest) {
    Write-Log "Test de mutation pour le fichier: $($file.SourcePath)" -Level "INFO"
    
    # VÃ©rifier si les fichiers existent
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
    
    # ExÃ©cuter les tests originaux pour vÃ©rifier qu'ils passent
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $file.TestPath
    $pesterConfig.Output.Verbosity = "None"
    $pesterConfig.Run.PassThru = $true
    
    $originalTestResults = Invoke-Pester -Configuration $pesterConfig
    
    if ($originalTestResults.FailedCount -gt 0) {
        Write-Log "Les tests originaux Ã©chouent. Impossible de continuer les tests de mutation." -Level "ERROR"
        continue
    }
    
    # CrÃ©er des mutations et exÃ©cuter les tests
    for ($i = 0; $i -lt $MaxMutations; $i++) {
        # SÃ©lectionner un type de mutation alÃ©atoire
        $mutationType = $mutationTypes | Get-Random
        
        # CrÃ©er une mutation
        $mutation = New-CodeMutation -SourceCode $sourceCode -MutationType $mutationType
        
        if ($null -eq $mutation) {
            Write-Log "Impossible de crÃ©er une mutation de type '$mutationType'." -Level "WARNING"
            continue
        }
        
        Write-Log "Mutation $($i + 1)/$MaxMutations: $($mutation.Description)" -Level "INFO"
        
        # ExÃ©cuter les tests sur le code mutÃ©
        $mutatedTestResults = Test-MutatedCode -OriginalFilePath $file.SourcePath -MutatedCode $mutation.MutatedCode -TestFilePath $file.TestPath
        
        if ($null -eq $mutatedTestResults) {
            Write-Log "Erreur lors de l'exÃ©cution des tests sur le code mutÃ©." -Level "ERROR"
            continue
        }
        
        # VÃ©rifier si les tests ont dÃ©tectÃ© la mutation
        $mutationDetected = $mutatedTestResults.FailedCount -gt 0
        
        # Ajouter les rÃ©sultats
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
            Write-Log "  Mutation dÃ©tectÃ©e: $($mutatedTestResults.FailedCount) test(s) Ã©chouÃ©(s)" -Level "SUCCESS"
        }
        else {
            Write-Log "  Mutation non dÃ©tectÃ©e: tous les tests ont rÃ©ussi" -Level "ERROR"
        }
    }
}

# Calculer les statistiques
$totalMutations = $mutationResults.Count
$detectedMutations = ($mutationResults | Where-Object { $_.Detected } | Measure-Object).Count
$detectionRate = if ($totalMutations -gt 0) { [math]::Round(($detectedMutations / $totalMutations) * 100, 2) } else { 0 }

Write-Log "`nRÃ©sumÃ© des tests de mutation:" -Level "INFO"
Write-Log "  Mutations totales: $totalMutations" -Level "INFO"
Write-Log "  Mutations dÃ©tectÃ©es: $detectedMutations" -Level "SUCCESS"
Write-Log "  Mutations non dÃ©tectÃ©es: $($totalMutations - $detectedMutations)" -Level "ERROR"
Write-Log "  Taux de dÃ©tection: $detectionRate%" -Level $(if ($detectionRate -ge 80) { "SUCCESS" } elseif ($detectionRate -ge 60) { "WARNING" } else { "ERROR" })

# Exporter les rÃ©sultats au format JSON
$jsonPath = Join-Path -Path $OutputPath -ChildPath "MutationResults.json"
$mutationResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8
Write-Log "RÃ©sultats exportÃ©s au format JSON: $jsonPath" -Level "SUCCESS"

# Exporter les rÃ©sultats au format CSV
$csvPath = Join-Path -Path $OutputPath -ChildPath "MutationResults.csv"
$mutationResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8
Write-Log "RÃ©sultats exportÃ©s au format CSV: $csvPath" -Level "SUCCESS"

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "MutationResults.html"
    
    # CrÃ©er un rapport HTML
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
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Mutations totales: $totalMutations</p>
        <p class="success">Mutations dÃ©tectÃ©es: $detectedMutations</p>
        <p class="error">Mutations non dÃ©tectÃ©es: $($totalMutations - $detectedMutations)</p>
        <p>Taux de dÃ©tection: <span class="$(if ($detectionRate -ge 80) { "success" } elseif ($detectionRate -ge 60) { "warning" } else { "error" })">$detectionRate%</span></p>
    </div>
    
    <div class="chart-container">
        <canvas id="detectionRateChart"></canvas>
    </div>
    
    <h2>DÃ©tails des mutations</h2>
    <table>
        <tr>
            <th>Fichier source</th>
            <th>Type de mutation</th>
            <th>Description</th>
            <th>Ligne</th>
            <th>DÃ©tectÃ©e</th>
            <th>Tests Ã©chouÃ©s</th>
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
    <p>Les tests de mutation sont une technique de test qui consiste Ã  introduire des modifications (mutations) dans le code source et Ã  vÃ©rifier si les tests existants dÃ©tectent ces modifications. Si les tests dÃ©tectent la mutation, cela signifie qu'ils sont efficaces. Si les tests ne dÃ©tectent pas la mutation, cela signifie qu'ils ne sont pas assez robustes.</p>
    
    <h3>Types de mutations</h3>
    <ul>
        <li><strong>ChangeReturnValue</strong>: Modifie la valeur de retour d'une fonction</li>
        <li><strong>ChangeCondition</strong>: Inverse une condition dans une instruction if</li>
        <li><strong>RemoveCode</strong>: Supprime une ligne de code</li>
        <li><strong>ChangeVariable</strong>: Modifie la valeur d'une variable</li>
        <li><strong>ChangeRegex</strong>: Modifie une expression rÃ©guliÃ¨re</li>
    </ul>
    
    <h3>InterprÃ©tation des rÃ©sultats</h3>
    <p>Un taux de dÃ©tection Ã©levÃ© (> 80%) indique que les tests sont robustes et dÃ©tectent efficacement les erreurs dans le code. Un taux de dÃ©tection faible (< 60%) indique que les tests ne sont pas assez robustes et qu'ils devraient Ãªtre amÃ©liorÃ©s.</p>
    
    <script>
        // DonnÃ©es pour les graphiques
        const detectionRateCtx = document.getElementById('detectionRateChart').getContext('2d');
        new Chart(detectionRateCtx, {
            type: 'pie',
            data: {
                labels: ['DÃ©tectÃ©es', 'Non dÃ©tectÃ©es'],
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
                        text: 'Taux de dÃ©tection des mutations'
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -Level "SUCCESS"
}

Write-Log "Tests de mutation terminÃ©s." -Level "SUCCESS"
