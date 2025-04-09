# Analyze-PhaseCompletion.ps1
# Script pour analyser la fin d'une phase et mettre à jour le journal


# Analyze-PhaseCompletion.ps1
# Script pour analyser la fin d'une phase et mettre à jour le journal

param (
    [Parameter(Mandatory = $true)

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
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}
try {
    # Script principal
]
    [string]$PhaseId,

    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\"Roadmap\roadmap_perso.md"",

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
        # Détecter la catégorie
        if ($line -match "^## (\d+)\. (.+)") {
            $categoryId = $matches[1]
            $categoryName = $matches[2]
            $currentCategory = "$categoryId. $categoryName"
            $inPhase = ($categoryId -eq $PhaseId)
            continue
        }

        # Si on n'est pas dans la phase recherchée, passer à la ligne suivante
        if (-not $inPhase) {
            continue
        }

        # Détecter les tâches
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

        # Détecter le nom de la phase
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
    # Vérifier que le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Error "Le fichier roadmap '$RoadmapPath' n'existe pas."
        return
    }

    # Lire le contenu de la roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Raw

    # Extraire les informations de la phase
    $phaseInfo = Get-PhaseInfo -Content $roadmapContent -PhaseId $PhaseId

    # Vérifier si la phase existe
    if ([string]::IsNullOrEmpty($phaseInfo.Name)) {
        Write-Error "La phase avec l'ID '$PhaseId' n'a pas été trouvée dans la roadmap."
        return
    }

    # Vérifier si la phase est terminée
    $isCompleted = ($phaseInfo.Tasks.Count -gt 0) -and ($phaseInfo.CompletedTasks.Count -eq $phaseInfo.Tasks.Count)

    if (-not $isCompleted) {
        Write-Output "La phase '$($phaseInfo.Name)' n'est pas encore terminee ($($phaseInfo.CompletedTasks.Count)/$($phaseInfo.Tasks.Count) taches terminees)."
        return
    }

    # Generer l'analyse de la phase
    $analysis = New-PhaseAnalysis -PhaseInfo $phaseInfo

    # Mettre à jour le journal
    $success = Update-Journal -JournalPath $JournalPath -Analysis $analysis -WhatIf:$WhatIf

    if (-not $success) {
        Write-Error "La mise à jour du journal a échoué."
        return
    }

    Write-Output "L'analyse de la phase '$($phaseInfo.Name)' a été générée et ajoutée au journal."
}

# Exécuter la fonction principale
Main

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
