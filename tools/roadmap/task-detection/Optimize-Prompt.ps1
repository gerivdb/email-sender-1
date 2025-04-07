# Optimize-Prompt.ps1
# Script pour affiner le prompt systÃ¨me en fonction des rÃ©sultats des tests

param (
    [Parameter(Mandatory = $false)]
    [string]$PromptFile = ".\task-detection-prompt.md",
    
    [Parameter(Mandatory = $false)]
    [string]$TestResultsFile = ".\test-results.txt",
    
    [Parameter(Mandatory = $false)]
    [switch]$ApplyChanges
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$promptPath = Join-Path -Path $scriptPath -ChildPath $PromptFile
$testResultsPath = Join-Path -Path $scriptPath -ChildPath $TestResultsFile
$optimizedPromptPath = Join-Path -Path $scriptPath -ChildPath "task-detection-prompt-optimized.md"

# VÃ©rifier que les fichiers nÃ©cessaires existent
if (-not (Test-Path -Path $promptPath)) {
    Write-Error "Le fichier de prompt '$promptPath' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $testResultsPath)) {
    Write-Error "Le fichier de rÃ©sultats de test '$testResultsPath' n'existe pas."
    exit 1
}

# Fonction pour analyser les rÃ©sultats des tests
function Analyze-TestResults {
    param (
        [string]$FilePath
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $pattern = '## Test #(\d+) : (.*?) - (RÃ‰USSI|Ã‰CHEC)\s+(?:Aucune tÃ¢che dÃ©tectÃ©e|(\d+) tÃ¢che\(s\) dÃ©tectÃ©e\(s\) :)'
    $matches = [regex]::Matches($content, $pattern, 'Singleline')
    
    $results = @()
    
    foreach ($match in $matches) {
        $id = $match.Groups[1].Value
        $title = $match.Groups[2].Value
        $status = $match.Groups[3].Value
        $taskCount = $match.Groups[4].Value
        
        if (-not $taskCount) {
            $taskCount = 0
        }
        
        $result = @{
            Id = $id
            Title = $title
            Status = $status
            TaskCount = [int]$taskCount
        }
        
        $results += $result
    }
    
    return $results
}

# Fonction pour optimiser le prompt
function Optimize-PromptContent {
    param (
        [string]$PromptContent,
        [array]$TestResults
    )
    
    $failedTests = $TestResults | Where-Object { $_.Status -eq "Ã‰CHEC" }
    $optimizations = @()
    
    if ($failedTests.Count -eq 0) {
        Write-Host "Tous les tests ont rÃ©ussi. Aucune optimisation nÃ©cessaire." -ForegroundColor Green
        return $PromptContent
    }
    
    Write-Host "Tests Ã©chouÃ©s : $($failedTests.Count)"
    Write-Host ""
    
    foreach ($test in $failedTests) {
        Write-Host "Test #$($test.Id) : $($test.Title) - $($test.Status)"
        
        switch ($test.Id) {
            "5" {
                # Cas 5 : Besoin implicite d'une nouvelle fonctionnalitÃ©
                $optimizations += "AmÃ©lioration de la dÃ©tection des besoins implicites"
                $PromptContent = $PromptContent -replace "5\. L'utilisateur exprime clairement le besoin d'une nouvelle fonctionnalitÃ©", "5. L'utilisateur exprime le besoin d'une nouvelle fonctionnalitÃ© (mÃªme de maniÃ¨re implicite, par exemple 'Ce serait bien si...')"
            }
            "8" {
                # Cas 8 : Demande sans tÃ¢che
                $optimizations += "AmÃ©lioration de la distinction entre les demandes d'information et les tÃ¢ches"
                $PromptContent = $PromptContent -replace "## Quand marquer une tÃ¢che", "## Quand marquer une tÃ¢che`n`nNe marquez PAS une demande comme une tÃ¢che lorsque :`n1. L'utilisateur demande simplement des informations ou des explications`n2. L'utilisateur pose une question sans demander d'implÃ©mentation`n3. L'utilisateur demande votre avis sans demander d'action concrÃ¨te"
            }
            "9" {
                # Cas 9 : Demande avec prioritÃ© explicite
                $optimizations += "AmÃ©lioration de la dÃ©tection des prioritÃ©s explicites"
                $PromptContent = $PromptContent -replace "- `priority` est \"high\", \"medium\" ou \"low\" \(facultatif, dÃ©faut: \"medium\"\)", "- `priority` est \"high\", \"medium\" ou \"low\" (facultatif, dÃ©faut: \"medium\")`n  - Utilisez \"high\" pour les tÃ¢ches critiques, urgentes ou prioritaires`n  - Utilisez \"medium\" pour les tÃ¢ches normales`n  - Utilisez \"low\" pour les tÃ¢ches moins importantes ou qui peuvent attendre"
            }
            "10" {
                # Cas 10 : Demande avec estimation prÃ©cise
                $optimizations += "AmÃ©lioration de la dÃ©tection des estimations explicites"
                $PromptContent = $PromptContent -replace "- `estimate` est une estimation du temps en jours, au format \"X-Y\" ou \"X\" \(facultatif, dÃ©faut: \"1-3\"\)", "- `estimate` est une estimation du temps en jours, au format \"X-Y\" ou \"X\" (facultatif, dÃ©faut: \"1-3\")`n  - Si l'utilisateur mentionne une estimation de temps, utilisez cette valeur`n  - Sinon, estimez le temps en fonction de la complexitÃ© de la tÃ¢che"
            }
            default {
                Write-Host "  Aucune optimisation spÃ©cifique pour ce test." -ForegroundColor Yellow
            }
        }
    }
    
    if ($optimizations.Count -gt 0) {
        Write-Host ""
        Write-Host "Optimisations appliquÃ©es :"
        foreach ($opt in $optimizations) {
            Write-Host "- $opt" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host ""
        Write-Host "Aucune optimisation spÃ©cifique n'a Ã©tÃ© appliquÃ©e." -ForegroundColor Yellow
    }
    
    return $PromptContent
}

# Fonction principale
function Main {
    Write-Host "Optimisation du prompt systÃ¨me en fonction des rÃ©sultats des tests"
    Write-Host ""
    
    # Lire le contenu du prompt
    $promptContent = Get-Content -Path $promptPath -Raw
    
    # Analyser les rÃ©sultats des tests
    $testResults = Analyze-TestResults -FilePath $testResultsPath
    
    if ($testResults.Count -eq 0) {
        Write-Error "Aucun rÃ©sultat de test trouvÃ© dans le fichier '$testResultsPath'."
        exit 1
    }
    
    Write-Host "RÃ©sultats de test trouvÃ©s : $($testResults.Count)"
    Write-Host ""
    
    # Optimiser le prompt
    $optimizedPromptContent = Optimize-PromptContent -PromptContent $promptContent -TestResults $testResults
    
    # Sauvegarder le prompt optimisÃ©
    $optimizedPromptContent | Set-Content -Path $optimizedPromptPath
    
    Write-Host ""
    Write-Host "Prompt optimisÃ© sauvegardÃ© dans : $optimizedPromptPath"
    
    # Appliquer les changements si demandÃ©
    if ($ApplyChanges) {
        Copy-Item -Path $optimizedPromptPath -Destination $promptPath -Force
        Write-Host "Changements appliquÃ©s au prompt original : $promptPath" -ForegroundColor Green
    }
    else {
        Write-Host "Pour appliquer les changements au prompt original, utilisez le paramÃ¨tre -ApplyChanges." -ForegroundColor Yellow
    }
}

# ExÃ©cuter la fonction principale
Main
