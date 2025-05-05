# Script de mise Ã  jour de la roadmap en fonction des commits Git
# Ce script analyse les commits Git et met Ã  jour la roadmap en consÃ©quence

param (
    [string]$RoadmapPath = "Roadmap\roadmap_perso.md",
    [string]$GitRepo = ".",
    [int]$DaysToAnalyze = 7,
    [switch]$AutoUpdate,
    [switch]$GenerateReport
)

# Configuration
$logFile = "RoadmapGitUpdater.log"
$reportPath = "Roadmap\Reports\git_update_report.html"
$keywordsCompleted = @("fix", "fixes", "fixed", "close", "closes", "closed", "resolve", "resolves", "resolved", "implement", "implements", "implemented", "complete", "completes", "completed")
$keywordsStarted = @("start", "starts", "started", "begin", "begins", "began", "work on", "working on", "progress", "in progress")

# Fonction pour Ã©crire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Ã‰crire dans le fichier journal
    Add-Content -Path $logFile -Value $logEntry

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# Fonction pour analyser la roadmap
function Get-RoadmapContent {
    param (
        [string]$Path
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le fichier roadmap n'existe pas: $Path" "ERROR"
        return $null
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw

    # Structure pour stocker les donnÃ©es de la roadmap
    $roadmap = @{
        Title    = ""
        Content  = $content
        Lines    = @()
        Sections = @()
    }

    # Extraire le titre
    if ($content -match "^# (.+)$") {
        $roadmap.Title = $Matches[1]
    }

    # Analyser les sections, phases et tÃ¢ches
    $lines = $content -split "`n"
    $roadmap.Lines = $lines
    $currentSection = $null
    $currentPhase = $null

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # DÃ©tecter une section
        if ($line -match "^## (\d+)\. (.+)$") {
            $sectionId = $Matches[1]
            $sectionTitle = $Matches[2]

            $currentSection = @{
                Id         = $sectionId
                Title      = $sectionTitle
                LineNumber = $i
                Phases     = @()
            }

            $roadmap.Sections += $currentSection
            $currentPhase = $null
        }

        # DÃ©tecter une phase
        elseif ($line -match "^  - \[([ x])\] \*\*Phase (\d+): (.+)\*\*$" -and $null -ne $currentSection) {
            $isCompleted = $Matches[1] -eq "x"
            $phaseId = $Matches[2]
            $phaseTitle = $Matches[3]

            $currentPhase = @{
                Id          = $phaseId
                Title       = $phaseTitle
                LineNumber  = $i
                IsCompleted = $isCompleted
                Tasks       = @()
            }

            $currentSection.Phases += $currentPhase
        }

        # DÃ©tecter une tÃ¢che
        elseif ($line -match "^    - \[([ x])\] (.+)$" -and $null -ne $currentPhase) {
            $isCompleted = $Matches[1] -eq "x"
            $taskTitle = $Matches[2]

            $task = @{
                Title       = $taskTitle
                LineNumber  = $i
                IsCompleted = $isCompleted
                Subtasks    = @()
            }

            $currentPhase.Tasks += $task
        }

        # DÃ©tecter une sous-tÃ¢che
        elseif ($line -match "^      - \[([ x])\] (.+)$" -and $null -ne $currentPhase -and $currentPhase.Tasks.Count -gt 0) {
            $isCompleted = $Matches[1] -eq "x"
            $subtaskTitle = $Matches[2]

            $subtask = @{
                Title       = $subtaskTitle
                LineNumber  = $i
                IsCompleted = $isCompleted
            }

            $currentPhase.Tasks[-1].Subtasks += $subtask
        }
    }

    return $roadmap
}

# Fonction pour obtenir les commits rÃ©cents
function Get-RecentCommits {
    param (
        [string]$RepoPath,
        [int]$Days
    )

    # VÃ©rifier si le dossier est un dÃ©pÃ´t Git
    if (-not (Test-Path -Path "$RepoPath\.git")) {
        Write-Log "Le dossier n'est pas un dÃ©pÃ´t Git: $RepoPath" "ERROR"
        return $null
    }

    # Calculer la date limite
    $since = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd")

    # Obtenir les commits rÃ©cents
    $commits = @()

    try {
        # Changer de rÃ©pertoire
        $currentDir = Get-Location
        Set-Location -Path $RepoPath

        # ExÃ©cuter la commande Git
        $gitOutput = git log --since="$since" --pretty=format:"%h|%an|%ad|%s" --date=short

        # Analyser la sortie
        foreach ($line in $gitOutput -split "`n") {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $parts = $line -split "\|"

                if ($parts.Count -ge 4) {
                    $commit = @{
                        Hash    = $parts[0]
                        Author  = $parts[1]
                        Date    = $parts[2]
                        Message = $parts[3]
                    }

                    $commits += $commit
                }
            }
        }

        # Revenir au rÃ©pertoire d'origine
        Set-Location -Path $currentDir
    } catch {
        Write-Log "Erreur lors de l'obtention des commits: $_" "ERROR"

        # Revenir au rÃ©pertoire d'origine en cas d'erreur
        Set-Location -Path $currentDir
        return $null
    }

    return $commits
}

# Fonction pour trouver les tÃ¢ches correspondant aux commits
function Find-MatchingTasks {
    param (
        [hashtable]$Roadmap,
        [array]$Commits
    )

    $matchingTasks = @()

    foreach ($commit in $Commits) {
        $message = $commit.Message.ToLower()
        $status = "unknown"

        # DÃ©terminer le statut en fonction des mots-clÃ©s
        foreach ($keyword in $keywordsCompleted) {
            if ($message -match "\b$keyword\b") {
                $status = "completed"
                break
            }
        }

        if ($status -eq "unknown") {
            foreach ($keyword in $keywordsStarted) {
                if ($message -match "\b$keyword\b") {
                    $status = "started"
                    break
                }
            }
        }

        # Chercher des correspondances dans les tÃ¢ches
        foreach ($section in $Roadmap.Sections) {
            foreach ($phase in $section.Phases) {
                foreach ($task in $phase.Tasks) {
                    $taskTitle = $task.Title.ToLower()

                    # VÃ©rifier si le message du commit correspond Ã  la tÃ¢che
                    if ($message -match [regex]::Escape($taskTitle) -or $taskTitle -match [regex]::Escape($message)) {
                        $matchingTasks += @{
                            Commit  = $commit
                            Section = $section
                            Phase   = $phase
                            Task    = $task
                            Status  = $status
                        }
                    }

                    # VÃ©rifier les sous-tÃ¢ches
                    foreach ($subtask in $task.Subtasks) {
                        $subtaskTitle = $subtask.Title.ToLower()

                        if ($message -match [regex]::Escape($subtaskTitle) -or $subtaskTitle -match [regex]::Escape($message)) {
                            $matchingTasks += @{
                                Commit  = $commit
                                Section = $section
                                Phase   = $phase
                                Task    = $task
                                Subtask = $subtask
                                Status  = $status
                            }
                        }
                    }
                }
            }
        }
    }

    return $matchingTasks
}

# Fonction pour mettre Ã  jour la roadmap
function Update-RoadmapFromMatches {
    param (
        [hashtable]$Roadmap,
        [array]$MatchingTasks
    )

    # Copier les lignes de la roadmap
    $lines = $Roadmap.Lines.Clone()
    $updated = $false

    foreach ($match in $MatchingTasks) {
        if ($match.Status -eq "completed") {
            if ($match.ContainsKey("Subtask")) {
                # Mettre Ã  jour une sous-tÃ¢che
                $lineNumber = $match.Subtask.LineNumber
                $line = $lines[$lineNumber]

                if (-not $match.Subtask.IsCompleted) {
                    $newLine = $line -replace "\[ \]", "[x]"
                    $lines[$lineNumber] = $newLine
                    $updated = $true

                    Write-Log "Sous-tÃ¢che marquÃ©e comme terminÃ©e: $($match.Subtask.Title)" "SUCCESS"
                }
            } else {
                # Mettre Ã  jour une tÃ¢che
                $lineNumber = $match.Task.LineNumber
                $line = $lines[$lineNumber]

                if (-not $match.Task.IsCompleted) {
                    $newLine = $line -replace "\[ \]", "[x]"
                    $lines[$lineNumber] = $newLine
                    $updated = $true

                    Write-Log "TÃ¢che marquÃ©e comme terminÃ©e: $($match.Task.Title)" "SUCCESS"
                }
            }
        }
    }

    # VÃ©rifier si toutes les tÃ¢ches d'une phase sont terminÃ©es
    foreach ($section in $Roadmap.Sections) {
        foreach ($phase in $section.Phases) {
            if (-not $phase.IsCompleted) {
                $allTasksCompleted = $true

                foreach ($task in $phase.Tasks) {
                    if (-not $task.IsCompleted) {
                        # VÃ©rifier si la tÃ¢che a Ã©tÃ© mise Ã  jour
                        $lineNumber = $task.LineNumber
                        $line = $lines[$lineNumber]

                        if ($line -match "\[ \]") {
                            $allTasksCompleted = $false
                            break
                        }
                    }
                }

                if ($allTasksCompleted) {
                    # Mettre Ã  jour la phase
                    $lineNumber = $phase.LineNumber
                    $line = $lines[$lineNumber]
                    $newLine = $line -replace "\[ \]", "[x]"
                    $lines[$lineNumber] = $newLine
                    $updated = $true

                    Write-Log "Phase marquÃ©e comme terminÃ©e: $($phase.Title)" "SUCCESS"
                }
            }
        }
    }

    if ($updated) {
        # Enregistrer les modifications
        $content = $lines -join "`n"

        if ($AutoUpdate) {
            Set-Content -Path $RoadmapPath -Value $content -Encoding UTF8
            Write-Log "Roadmap mise Ã  jour avec succÃ¨s" "SUCCESS"
        } else {
            Write-Log "Modifications prÃªtes Ã  Ãªtre appliquÃ©es (utilisez -AutoUpdate pour appliquer)" "WARNING"
        }
    } else {
        Write-Log "Aucune modification Ã  appliquer" "INFO"
    }

    return @{
        Updated = $updated
        Lines   = $lines
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-GitUpdateReport {
    param (
        [hashtable]$Roadmap,
        [array]$Commits,
        [array]$MatchingTasks,
        [hashtable]$UpdateResult
    )

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de mise Ã  jour Git - $($Roadmap.Title)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        .section {
            margin-bottom: 30px;
            border-left: 4px solid #0066cc;
            padding-left: 15px;
        }
        .commit {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 15px;
            border-left: 4px solid #16a085;
        }
        .match {
            background-color: #e8f4fc;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 15px;
            border-left: 4px solid #e67e22;
        }
        .completed {
            color: #27ae60;
        }
        .started {
            color: #f39c12;
        }
        .unknown {
            color: #7f8c8d;
        }
        .timestamp {
            font-style: italic;
            color: #666;
            margin-top: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .diff {
            background-color: #f9f9f9;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            white-space: pre-wrap;
            margin: 10px 0;
        }
        .diff-added {
            background-color: #e6ffed;
            color: #22863a;
        }
        .diff-removed {
            background-color: #ffeef0;
            color: #cb2431;
        }
    </style>
</head>
<body>
    <h1>Rapport de mise Ã  jour Git - $($Roadmap.Title)</h1>
    <p class="timestamp">GÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>

    <div class="section">
        <h2>RÃ©sumÃ©</h2>
        <p>PÃ©riode analysÃ©e: $DaysToAnalyze jours</p>
        <p>Commits analysÃ©s: $($Commits.Count)</p>
        <p>Correspondances trouvÃ©es: $($MatchingTasks.Count)</p>
        <p>Roadmap mise Ã  jour: $($UpdateResult.Updated)</p>
    </div>

    <div class="section">
        <h2>Commits rÃ©cents</h2>
"@

    foreach ($commit in $Commits) {
        $html += @"
        <div class="commit">
            <h3>$($commit.Hash) - $($commit.Date)</h3>
            <p><strong>Auteur:</strong> $($commit.Author)</p>
            <p><strong>Message:</strong> $($commit.Message)</p>
        </div>
"@
    }

    $html += @"
    </div>

    <div class="section">
        <h2>Correspondances trouvÃ©es</h2>
"@

    if ($MatchingTasks.Count -eq 0) {
        $html += @"
        <p>Aucune correspondance trouvÃ©e.</p>
"@
    } else {
        foreach ($match in $MatchingTasks) {
            $statusClass = $match.Status

            $html += @"
        <div class="match">
            <h3 class="$statusClass">$($match.Commit.Hash) - $($match.Commit.Message)</h3>
            <p><strong>Section:</strong> $($match.Section.Id). $($match.Section.Title)</p>
            <p><strong>Phase:</strong> Phase $($match.Phase.Id): $($match.Phase.Title)</p>
"@

            if ($match.ContainsKey("Subtask")) {
                $html += @"
            <p><strong>TÃ¢che:</strong> $($match.Task.Title)</p>
            <p><strong>Sous-tÃ¢che:</strong> $($match.Subtask.Title)</p>
            <p><strong>Statut:</strong> <span class="$statusClass">$($match.Status)</span></p>
"@
            } else {
                $html += @"
            <p><strong>TÃ¢che:</strong> $($match.Task.Title)</p>
            <p><strong>Statut:</strong> <span class="$statusClass">$($match.Status)</span></p>
"@
            }

            $html += @"
        </div>
"@
        }
    }

    $html += @"
    </div>
"@

    if ($UpdateResult.Updated) {
        $html += @"
    <div class="section">
        <h2>Modifications apportÃ©es</h2>
        <div class="diff">
"@

        for ($i = 0; $i -lt $Roadmap.Lines.Count; $i++) {
            $originalLine = $Roadmap.Lines[$i]
            $newLine = $UpdateResult.Lines[$i]

            if ($originalLine -ne $newLine) {
                $html += @"
<div class="diff-removed">- $originalLine</div>
<div class="diff-added">+ $newLine</div>

"@
            }
        }

        $html += @"
        </div>
    </div>
"@
    }

    $html += @"
</body>
</html>
"@

    return $html
}

# Analyser la roadmap
Write-Log "Analyse de la roadmap: $RoadmapPath" "INFO"
$roadmap = Get-RoadmapContent -Path $RoadmapPath

if ($null -eq $roadmap) {
    Write-Log "Impossible d'analyser la roadmap" "ERROR"
    exit 1
}

# Obtenir les commits rÃ©cents
Write-Log "Obtention des commits des $DaysToAnalyze derniers jours..." "INFO"
$commits = Get-RecentCommits -RepoPath $GitRepo -Days $DaysToAnalyze

if ($null -eq $commits -or $commits.Count -eq 0) {
    Write-Log "Aucun commit trouvÃ©" "WARNING"
    exit 0
}

Write-Log "Commits trouvÃ©s: $($commits.Count)" "INFO"

# Trouver les tÃ¢ches correspondant aux commits
Write-Log "Recherche des correspondances..." "INFO"
$matchingTasks = Find-MatchingTasks -Roadmap $roadmap -Commits $commits

Write-Log "Correspondances trouvÃ©es: $($matchingTasks.Count)" "INFO"

# Mettre Ã  jour la roadmap
Write-Log "Mise Ã  jour de la roadmap..." "INFO"
$updateResult = Update-RoadmapFromMatches -Roadmap $roadmap -MatchingTasks $matchingTasks

# GÃ©nÃ©rer un rapport
if ($GenerateReport) {
    Write-Log "GÃ©nÃ©ration du rapport..." "INFO"

    # CrÃ©er le dossier de rapport s'il n'existe pas
    $reportFolder = Split-Path -Path $reportPath -Parent
    if (-not (Test-Path -Path $reportFolder)) {
        New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null
    }

    $report = New-GitUpdateReport -Roadmap $roadmap -Commits $commits -MatchingTasks $matchingTasks -UpdateResult $updateResult
    Set-Content -Path $reportPath -Value $report -Encoding UTF8

    Write-Log "Rapport gÃ©nÃ©rÃ©: $reportPath" "SUCCESS"

    # Ouvrir le rapport
    Start-Process $reportPath
}

Write-Log "TerminÃ©" "SUCCESS"
