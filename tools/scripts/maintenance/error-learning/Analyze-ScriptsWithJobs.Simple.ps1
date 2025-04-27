<#
.SYNOPSIS
    Version simplifiÃ©e pour analyser plusieurs scripts PowerShell en parallÃ¨le avec Jobs PowerShell.
.DESCRIPTION
    Ce script utilise des Jobs PowerShell pour analyser plusieurs scripts PowerShell simultanÃ©ment.
    Compatible avec PowerShell 5.1.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$ScriptPaths,

    [Parameter(Mandatory = $false)]
    [int]$MaxJobs = 5
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem

# VÃ©rifier que les chemins existent et convertir en chemins absolus
$validPaths = @()
foreach ($path in $ScriptPaths) {
    # Convertir en chemin absolu
    $absolutePath = $path
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $absolutePath = Join-Path -Path $PWD.Path -ChildPath $path
    }

    if (Test-Path -Path $absolutePath) {
        $validPaths += $absolutePath
    }
    else {
        Write-Warning "Le chemin spÃ©cifiÃ© n'existe pas : $absolutePath"
    }
}

if ($validPaths.Count -eq 0) {
    Write-Error "Aucun script valide Ã  analyser."
    exit 1
}

Write-Host "Analyse de $($validPaths.Count) scripts en parallÃ¨le (MaxJobs: $MaxJobs)..."

# DÃ©finir les patterns d'erreurs courantes
$errorPatterns = @(
    @{
        Name = "HardcodedPath"
        Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
        Description = "Chemin codÃ© en dur dÃ©tectÃ©"
    },
    @{
        Name = "NoErrorHandling"
        Pattern = '(?<!try\s*\{\s*)(?:Get-Content|Set-Content)(?!\s*-ErrorAction)'
        Description = "Absence de gestion d'erreurs dÃ©tectÃ©"
    },
    @{
        Name = "WriteHostUsage"
        Pattern = 'Write-Host'
        Description = "Utilisation de Write-Host dÃ©tectÃ©"
    }
)

# CrÃ©er un script block pour l'analyse d'un script
$scriptBlock = {
    param($scriptPath, $patterns)

    Write-Host "Analyse du script : $scriptPath"

    try {
        # Lire le contenu du script
        $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop

        # Analyser le script
        $scriptIssues = @()

        # Analyser chaque pattern
        foreach ($pattern in $patterns) {
            $regexMatches = [regex]::Matches($scriptContent, $pattern.Pattern)

            if ($regexMatches.Count -gt 0) {
                foreach ($match in $regexMatches) {
                    # Trouver le numÃ©ro de ligne
                    $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length

                    # CrÃ©er un objet pour l'erreur dÃ©tectÃ©e
                    $issue = [PSCustomObject]@{
                        Name = $pattern.Name
                        Description = $pattern.Description
                        LineNumber = $lineNumber
                        Match = $match.Value
                    }

                    $scriptIssues += $issue
                }
            }
        }

        # CrÃ©er un objet de rÃ©sultat pour ce script
        $scriptResult = [PSCustomObject]@{
            ScriptPath = $scriptPath
            IssuesCount = $scriptIssues.Count
            Issues = $scriptIssues
            Success = $true
        }

        Write-Host "Analyse terminÃ©e pour $scriptPath. Erreurs dÃ©tectÃ©es : $($scriptIssues.Count)"

        return $scriptResult
    }
    catch {
        Write-Warning "Erreur lors de l'analyse de $scriptPath : $($_.Exception.Message)"
        return $null
    }
}

# CrÃ©er un tableau pour stocker les rÃ©sultats
$results = @()

# CrÃ©er un tableau pour stocker les jobs
$jobs = @()

# Traiter les scripts par lots
$scriptIndex = 0
while ($scriptIndex -lt $validPaths.Count) {
    # VÃ©rifier le nombre de jobs en cours d'exÃ©cution
    $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }

    # Si nous avons atteint le nombre maximum de jobs, attendre qu'un job se termine
    while ($runningJobs.Count -ge $MaxJobs) {
        Start-Sleep -Seconds 1
        $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }
    }

    # DÃ©marrer un nouveau job
    $scriptPath = $validPaths[$scriptIndex]
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $scriptPath, $errorPatterns
    $jobs += $job

    # IncrÃ©menter l'index
    $scriptIndex++
}

# Attendre que tous les jobs se terminent
Write-Host "Attente de la fin de tous les jobs..."
$jobs | Wait-Job | Out-Null

# RÃ©cupÃ©rer les rÃ©sultats
foreach ($job in $jobs) {
    $jobResult = Receive-Job -Job $job
    if ($jobResult) {
        $results += $jobResult
    }
    Remove-Job -Job $job
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© de l'analyse :"
Write-Host "  Scripts analysÃ©s : $($results.Count)"
Write-Host "  Total des problÃ¨mes dÃ©tectÃ©s : $(($results | Measure-Object -Property IssuesCount -Sum).Sum)"

# Afficher les scripts avec le plus de problÃ¨mes
$topIssueScripts = $results | Sort-Object -Property IssuesCount -Descending | Select-Object -First 3
if ($topIssueScripts.Count -gt 0) {
    Write-Host "`nTop 3 des scripts avec le plus de problÃ¨mes :"
    foreach ($script in $topIssueScripts) {
        Write-Host "  $($script.ScriptPath) : $($script.IssuesCount) problÃ¨mes"
    }
}

Write-Host "`nAnalyse terminÃ©e."
