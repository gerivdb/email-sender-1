# Run-Tests.ps1
# Script pour tester automatiquement le systÃ¨me de dÃ©tection des tÃ¢ches

param (
    [Parameter(Mandatory = $false)]
    [string]$TestCasesFile = ".\tests\test-cases.txt",
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory = $false)]
    [switch]$AddToRoadmap
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testCasesPath = Join-Path -Path $scriptPath -ChildPath $TestCasesFile
$processConversationPath = Join-Path -Path $scriptPath -ChildPath "Process-Conversation.ps1"
$testResultsPath = Join-Path -Path $scriptPath -ChildPath "test-results.txt"

# VÃ©rifier que les fichiers nÃ©cessaires existent
if (-not (Test-Path -Path $testCasesPath)) {
    Write-Error "Le fichier de cas de test '$testCasesPath' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $processConversationPath)) {
    Write-Error "Le script Process-Conversation.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $processConversationPath"
    exit 1
}

# Fonction pour extraire les cas de test du fichier
function Extract-TestCases {
    param (
        [string]$FilePath
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $testCases = @()
    $pattern = '## Cas (\d+) : (.*?)\n(.*?)(?=\n## Cas|\z)'
    $matches = [regex]::Matches($content, $pattern, 'Singleline')
    
    foreach ($match in $matches) {
        $id = $match.Groups[1].Value
        $title = $match.Groups[2].Value
        $content = $match.Groups[3].Value.Trim()
        
        $testCase = @{
            Id = $id
            Title = $title
            Content = $content
        }
        
        $testCases += $testCase
    }
    
    return $testCases
}

# Fonction pour exÃ©cuter un test
function Run-Test {
    param (
        [hashtable]$TestCase,
        [switch]$AddToRoadmap,
        [switch]$Verbose
    )
    
    Write-Host "ExÃ©cution du test #$($TestCase.Id) : $($TestCase.Title)"
    
    # CrÃ©er un fichier temporaire pour le contenu du test
    $tempFile = [System.IO.Path]::GetTempFileName()
    $TestCase.Content | Set-Content -Path $tempFile
    
    # ExÃ©cuter le script de traitement des conversations
    $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }
    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
    
    $command = "powershell -ExecutionPolicy Bypass -File `"$processConversationPath`" -ConversationFile `"$tempFile`" $addToRoadmapParam $verboseParam"
    
    if ($Verbose) {
        Write-Host "ExÃ©cution de la commande : $command"
    }
    
    $result = Invoke-Expression $command
    
    # Supprimer le fichier temporaire
    Remove-Item -Path $tempFile -Force
    
    # Analyser les rÃ©sultats
    $taskCount = $result.Count
    
    if ($taskCount -eq 0) {
        Write-Host "  RÃ©sultat : Aucune tÃ¢che dÃ©tectÃ©e" -ForegroundColor Yellow
        $success = $TestCase.Id -eq "8"  # Le cas 8 ne contient pas de tÃ¢che
    }
    else {
        Write-Host "  RÃ©sultat : $taskCount tÃ¢che(s) dÃ©tectÃ©e(s)" -ForegroundColor Green
        
        foreach ($task in $result) {
            Write-Host "    - CatÃ©gorie : $($task.Category), PrioritÃ© : $($task.Priority), Estimation : $($task.Estimate), DÃ©marrer : $($task.Start)"
            Write-Host "      Description : $($task.Description)"
        }
        
        $success = $true
    }
    
    return @{
        TestCase = $TestCase
        Result = $result
        Success = $success
    }
}

# Fonction pour gÃ©nÃ©rer un rapport de test
function Generate-TestReport {
    param (
        [array]$TestResults
    )
    
    $report = "# Rapport de test du systÃ¨me de dÃ©tection des tÃ¢ches`n`n"
    $report += "Date : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    
    $successCount = ($TestResults | Where-Object { $_.Success }).Count
    $totalCount = $TestResults.Count
    $successRate = [math]::Round(($successCount / $totalCount) * 100)
    
    $report += "RÃ©sumÃ© : $successCount / $totalCount tests rÃ©ussis ($successRate%)`n`n"
    
    foreach ($result in $TestResults) {
        $status = if ($result.Success) { "RÃ‰USSI" } else { "Ã‰CHEC" }
        $report += "## Test #$($result.TestCase.Id) : $($result.TestCase.Title) - $status`n`n"
        
        $taskCount = $result.Result.Count
        
        if ($taskCount -eq 0) {
            $report += "Aucune tÃ¢che dÃ©tectÃ©e`n`n"
        }
        else {
            $report += "$taskCount tÃ¢che(s) dÃ©tectÃ©e(s) :`n`n"
            
            foreach ($task in $result.Result) {
                $report += "- CatÃ©gorie : $($task.Category)`n"
                $report += "  PrioritÃ© : $($task.Priority)`n"
                $report += "  Estimation : $($task.Estimate) jours`n"
                $report += "  DÃ©marrer : $($task.Start)`n"
                $report += "  Description : $($task.Description)`n`n"
            }
        }
        
        $report += "---`n`n"
    }
    
    return $report
}

# Fonction principale
function Main {
    Write-Host "Test automatique du systÃ¨me de dÃ©tection des tÃ¢ches"
    Write-Host ""
    
    # Extraire les cas de test
    $testCases = Extract-TestCases -FilePath $testCasesPath
    
    if ($testCases.Count -eq 0) {
        Write-Error "Aucun cas de test trouvÃ© dans le fichier '$testCasesPath'."
        exit 1
    }
    
    Write-Host "Cas de test trouvÃ©s : $($testCases.Count)"
    Write-Host ""
    
    # ExÃ©cuter les tests
    $testResults = @()
    
    foreach ($testCase in $testCases) {
        $result = Run-Test -TestCase $testCase -AddToRoadmap:$AddToRoadmap -Verbose:$Verbose
        $testResults += $result
        Write-Host ""
    }
    
    # GÃ©nÃ©rer et sauvegarder le rapport de test
    $report = Generate-TestReport -TestResults $testResults
    $report | Set-Content -Path $testResultsPath
    
    # Afficher le rÃ©sumÃ©
    $successCount = ($testResults | Where-Object { $_.Success }).Count
    $totalCount = $testResults.Count
    $successRate = [math]::Round(($successCount / $totalCount) * 100)
    
    Write-Host "Tests terminÃ©s : $successCount / $totalCount tests rÃ©ussis ($successRate%)"
    Write-Host "Rapport de test sauvegardÃ© dans : $testResultsPath"
}

# ExÃ©cuter la fonction principale
Main
