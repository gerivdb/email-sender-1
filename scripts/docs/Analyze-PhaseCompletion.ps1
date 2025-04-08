# Analyze-PhaseCompletion.ps1
# Script pour analyser la fin d'une phase et mettre Ã  jour le journal

param (
    [Parameter(Mandatory = $true)]
    [string]$PhaseId,

    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\roadmap_perso.md",

    [Parameter(Mandatory = $false)]
    [string]$JournalPath = ".\journal\journal.md",

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour extraire les informations d'une phase
function Get-PhaseInfo {
    param (
        [string]$Content,
        [string]$PhaseId
    )

    $lines = $Content -split "`n"
    $phaseInfo = @{
        Id = $PhaseId
        Name = ""
        Tasks = @()
        CompletedTasks = @()
        InProgressTasks = @()
        PendingTasks = @()
    }

    $inPhase = $false
    $currentCategory = ""

    foreach ($line in $lines) {
        # DÃ©tecter la catÃ©gorie
        if ($line -match "^## (\d+)\. (.+)") {
            $categoryId = $matches[1]
            $categoryName = $matches[2]
            $currentCategory = "$categoryId. $categoryName"
            $inPhase = ($categoryId -eq $PhaseId)
            continue
        }

        # Si on n'est pas dans la phase recherchÃ©e, passer Ã  la ligne suivante
        if (-not $inPhase) {
            continue
        }

        # DÃ©tecter les tÃ¢ches
        if ($line -match "^- \[([ x])\] (.+?) \((.+?)\)") {
            $completed = ($matches[1] -eq "x")
            $description = $matches[2]
            $estimation = $matches[3]

            $task = @{
                Description = $description
                Estimation = $estimation
                Completed = $completed
                Category = $currentCategory
            }

            $phaseInfo.Tasks += $task

            if ($completed) {
                $phaseInfo.CompletedTasks += $task
            }
            elseif ($line -match "Demarre le") {
                $phaseInfo.InProgressTasks += $task
            }
            else {
                $phaseInfo.PendingTasks += $task
            }
        }

        # DÃ©tecter le nom de la phase
        if ([string]::IsNullOrEmpty($phaseInfo.Name) -and $line -match "^\*\*Complexite\*\*:") {
            $phaseInfo.Name = $currentCategory
        }
    }

    return $phaseInfo
}

# Fonction pour generer l'analyse de la phase
function New-PhaseAnalysis {
    param (
        [hashtable]$PhaseInfo
    )

    $analysis = "# Analyse de la phase : $($PhaseInfo.Name)`n`n"
    $analysis += "## Resume`n`n"
    $analysis += "- **Taches totales** : $($PhaseInfo.Tasks.Count)`n"
    $analysis += "- **Taches terminees** : $($PhaseInfo.CompletedTasks.Count)`n"
    $analysis += "- **Taches en cours** : $($PhaseInfo.InProgressTasks.Count)`n"
    $analysis += "- **Taches en attente** : $($PhaseInfo.PendingTasks.Count)`n"

    $completionPercentage = if ($PhaseInfo.Tasks.Count -gt 0) {
        [math]::Round(($PhaseInfo.CompletedTasks.Count / $PhaseInfo.Tasks.Count) * 100)
    } else {
        0
    }

    $analysis += "- **Progression** : $completionPercentage%`n`n"

    $analysis += "## Taches terminees`n`n"
    if ($PhaseInfo.CompletedTasks.Count -gt 0) {
        foreach ($task in $PhaseInfo.CompletedTasks) {
            $analysis += "- [OK] $($task.Description) ($($task.Estimation))`n"
        }
    } else {
        $analysis += "Aucune tache terminee.`n"
    }

    $analysis += "`n## Taches en cours`n`n"
    if ($PhaseInfo.InProgressTasks.Count -gt 0) {
        foreach ($task in $PhaseInfo.InProgressTasks) {
            $analysis += "- [EN COURS] $($task.Description) ($($task.Estimation))`n"
        }
    } else {
        $analysis += "Aucune tache en cours.`n"
    }

    $analysis += "`n## Taches en attente`n`n"
    if ($PhaseInfo.PendingTasks.Count -gt 0) {
        foreach ($task in $PhaseInfo.PendingTasks) {
            $analysis += "- [ATTENTE] $($task.Description) ($($task.Estimation))`n"
        }
    } else {
        $analysis += "Aucune tache en attente.`n"
    }

    $analysis += "`n## Lecons apprises`n`n"
    $analysis += "- A completer manuellement`n"

    $analysis += "`n## Prochaines etapes`n`n"
    $analysis += "- A completer manuellement`n"

    return $analysis
}

# Fonction pour mettre a jour le journal
function Update-Journal {
    param (
        [string]$JournalPath,
        [string]$Analysis,
        [switch]$WhatIf
    )

    # Verifier si le dossier du journal existe
    $journalFolder = Split-Path -Parent $JournalPath
    if (-not (Test-Path -Path $journalFolder)) {
        if ($WhatIf) {
            Write-Output "Le dossier du journal '$journalFolder' serait cree."
        } else {
            New-Item -Path $journalFolder -ItemType Directory -Force | Out-Null
            Write-Output "Le dossier du journal '$journalFolder' a ete cree."
        }
    }

    # Verifier si le fichier du journal existe
    $journalExists = Test-Path -Path $JournalPath

    # Generer l'entree du journal
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $journalEntry = "# Entree du $timestamp`n`n$Analysis"

    if ($journalExists) {
        # Lire le contenu du journal
        $journalContent = Get-Content -Path $JournalPath -Raw

        # Verifier si l'analyse existe deja dans le journal
        $phaseHeader = $Analysis.Split("`n")[0]
        if ($journalContent -match [regex]::Escape($phaseHeader)) {
            Write-Output "Une analyse similaire existe deja dans le journal. Mise a jour annulee."
            return $false
        }

        # Ajouter l'analyse au debut du journal
        $updatedContent = "$journalEntry`n`n---`n`n$journalContent"

        if ($WhatIf) {
            Write-Output "L'analyse serait ajoutee au journal existant."
        } else {
            $updatedContent | Out-File -FilePath $JournalPath -Encoding ascii
            Write-Output "L'analyse a ete ajoutee au journal existant."
        }
    } else {
        # Creer un nouveau fichier journal
        $journalContent = "# Journal de developpement`n`n$journalEntry"

        if ($WhatIf) {
            Write-Output "Un nouveau fichier journal serait cree avec l'analyse."
        } else {
            $journalContent | Out-File -FilePath $JournalPath -Encoding ascii
            Write-Output "Un nouveau fichier journal a ete cree avec l'analyse."
        }
    }

    return $true
}

# Fonction principale
function Main {
    # VÃ©rifier que le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier roadmap '$RoadmapPath' n'existe pas."
        return
    }

    # Lire le contenu de la roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw

    # Extraire les informations de la phase
    $phaseInfo = Get-PhaseInfo -Content $roadmapContent -PhaseId $PhaseId

    # VÃ©rifier si la phase existe
    if ([string]::IsNullOrEmpty($phaseInfo.Name)) {
        Write-Error "La phase avec l'ID '$PhaseId' n'a pas Ã©tÃ© trouvÃ©e dans la roadmap."
        return
    }

    # VÃ©rifier si la phase est terminÃ©e
    $isCompleted = ($phaseInfo.Tasks.Count -gt 0) -and ($phaseInfo.CompletedTasks.Count -eq $phaseInfo.Tasks.Count)

    if (-not $isCompleted) {
        Write-Output "La phase '$($phaseInfo.Name)' n'est pas encore terminee ($($phaseInfo.CompletedTasks.Count)/$($phaseInfo.Tasks.Count) taches terminees)."
        return
    }

    # Generer l'analyse de la phase
    $analysis = New-PhaseAnalysis -PhaseInfo $phaseInfo

    # Mettre Ã  jour le journal
    $success = Update-Journal -JournalPath $JournalPath -Analysis $analysis -WhatIf:$WhatIf

    if (-not $success) {
        Write-Error "La mise Ã  jour du journal a Ã©chouÃ©."
        return
    }

    Write-Output "L'analyse de la phase '$($phaseInfo.Name)' a Ã©tÃ© gÃ©nÃ©rÃ©e et ajoutÃ©e au journal."
}

# ExÃ©cuter la fonction principale
Main
