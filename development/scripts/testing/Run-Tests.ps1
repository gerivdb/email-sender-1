# Run-Tests.ps1
# Script pour tester automatiquement le systÃƒÂ¨me de dÃƒÂ©tection des tÃƒÂ¢ches


# Run-Tests.ps1
# Script pour tester automatiquement le systÃƒÂ¨me de dÃƒÂ©tection des tÃƒÂ¢ches

param (
    [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$TestCasesFile = ".\development\testing\tests\test-cases.txt",
    
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

# VÃƒÂ©rifier que les fichiers nÃƒÂ©cessaires existent
if (-not (Test-Path -Path $testCasesPath)) {
    Write-Error "Le fichier de cas de test '$testCasesPath' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $processConversationPath)) {
    Write-Error "Le script Process-Conversation.ps1 n'a pas ÃƒÂ©tÃƒÂ© trouvÃƒÂ© ÃƒÂ  l'emplacement : $processConversationPath"
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

# Fonction pour exÃƒÂ©cuter un test
function Run-Test {
    param (
        [hashtable]$TestCase,
        [switch]$AddToRoadmap,
        [switch]$Verbose
    )
    
    Write-Host "ExÃƒÂ©cution du test #$($TestCase.Id) : $($TestCase.Title)"
    
    # CrÃƒÂ©er un fichier temporaire pour le contenu du test
    $tempFile = [System.IO.Path]::GetTempFileName()
    $TestCase.Content | Set-Content -Path $tempFile
    
    # ExÃƒÂ©cuter le script de traitement des conversations
    $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }
    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
    
    $command = "powershell -ExecutionPolicy Bypass -File `"$processConversationPath`" -ConversationFile `"$tempFile`" $addToRoadmapParam $verboseParam"
    
    if ($Verbose) {
        Write-Host "ExÃƒÂ©cution de la commande : $command"
    }
    
    $result = Invoke-Expression $command
    
    # Supprimer le fichier temporaire
    Remove-Item -Path $tempFile -Force
    
    # Analyser les rÃƒÂ©sultats
    $taskCount = $result.Count
    
    if ($taskCount -eq 0) {
        Write-Host "  RÃƒÂ©sultat : Aucune tÃƒÂ¢che dÃƒÂ©tectÃƒÂ©e" -ForegroundColor Yellow
        $success = $TestCase.Id -eq "8"  # Le cas 8 ne contient pas de tÃƒÂ¢che
    }
    else {
        Write-Host "  RÃƒÂ©sultat : $taskCount tÃƒÂ¢che(s) dÃƒÂ©tectÃƒÂ©e(s)" -ForegroundColor Green
        
        foreach ($task in $result) {
            Write-Host "    - CatÃƒÂ©gorie : $($task.Category), PrioritÃƒÂ© : $($task.Priority), Estimation : $($task.Estimate), DÃƒÂ©marrer : $($task.Start)"
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

# Fonction pour gÃƒÂ©nÃƒÂ©rer un rapport de test
function Generate-TestReport {
    param (
        [array]$TestResults
    )
    
    $report = "# Rapport de test du systÃƒÂ¨me de dÃƒÂ©tection des tÃƒÂ¢ches`n`n"
    $report += "Date : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    
    $successCount = ($TestResults | Where-Object { $_.Success }).Count
    $totalCount = $TestResults.Count
    $successRate = [math]::Round(($successCount / $totalCount) * 100)
    
    $report += "RÃƒÂ©sumÃƒÂ© : $successCount / $totalCount tests rÃƒÂ©ussis ($successRate%)`n`n"
    
    foreach ($result in $TestResults) {
        $status = if ($result.Success) { "RÃƒâ€°USSI" } else { "Ãƒâ€°CHEC" }
        $report += "## Test #$($result.TestCase.Id) : $($result.TestCase.Title) - $status`n`n"
        
        $taskCount = $result.Result.Count
        
        if ($taskCount -eq 0) {
            $report += "Aucune tÃƒÂ¢che dÃƒÂ©tectÃƒÂ©e`n`n"
        }
        else {
            $report += "$taskCount tÃƒÂ¢che(s) dÃƒÂ©tectÃƒÂ©e(s) :`n`n"
            
            foreach ($task in $result.Result) {
                $report += "- CatÃƒÂ©gorie : $($task.Category)`n"
                $report += "  PrioritÃƒÂ© : $($task.Priority)`n"
                $report += "  Estimation : $($task.Estimate) jours`n"
                $report += "  DÃƒÂ©marrer : $($task.Start)`n"
                $report += "  Description : $($task.Description)`n`n"
            }
        }
        
        $report += "---`n`n"
    }
    
    return $report
}

# Fonction principale
function Main {
    Write-Host "Test automatique du systÃƒÂ¨me de dÃƒÂ©tection des tÃƒÂ¢ches"
    Write-Host ""
    
    # Extraire les cas de test
    $testCases = Extract-TestCases -FilePath $testCasesPath
    
    if ($testCases.Count -eq 0) {
        Write-Error "Aucun cas de test trouvÃƒÂ© dans le fichier '$testCasesPath'."
        exit 1
    }
    
    Write-Host "Cas de test trouvÃƒÂ©s : $($testCases.Count)"
    Write-Host ""
    
    # ExÃƒÂ©cuter les tests
    $testResults = @()
    
    foreach ($testCase in $testCases) {
        $result = Run-Test -TestCase $testCase -AddToRoadmap:$AddToRoadmap -Verbose:$Verbose
        $testResults += $result
        Write-Host ""
    }
    
    # GÃƒÂ©nÃƒÂ©rer et sauvegarder le rapport de test
    $report = Generate-TestReport -TestResults $testResults
    $report | Set-Content -Path $testResultsPath
    
    # Afficher le rÃƒÂ©sumÃƒÂ©
    $successCount = ($testResults | Where-Object { $_.Success }).Count
    $totalCount = $testResults.Count
    $successRate = [math]::Round(($successCount / $totalCount) * 100)
    
    Write-Host "Tests terminÃƒÂ©s : $successCount / $totalCount tests rÃƒÂ©ussis ($successRate%)"
    Write-Host "Rapport de test sauvegardÃƒÂ© dans : $testResultsPath"
}

# ExÃƒÂ©cuter la fonction principale
Main

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
