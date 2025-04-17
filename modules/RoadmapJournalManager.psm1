#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion du système de journalisation de la roadmap.
.DESCRIPTION
    Ce module fournit des fonctions pour créer, mettre à jour, archiver et analyser
    les entrées du journal de la roadmap au format JSON.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
#>

# Chemins des fichiers et dossiers
$script:JournalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\Roadmap\journal"
$script:IndexPath = Join-Path -Path $script:JournalRoot -ChildPath "index.json"
$script:MetadataPath = Join-Path -Path $script:JournalRoot -ChildPath "metadata.json"
$script:StatusPath = Join-Path -Path $script:JournalRoot -ChildPath "status.json"
$script:TemplatesPath = Join-Path -Path $script:JournalRoot -ChildPath "templates"
$script:SectionsPath = Join-Path -Path $script:JournalRoot -ChildPath "sections"
$script:ArchivesPath = Join-Path -Path $script:JournalRoot -ChildPath "archives"
$script:LogsPath = Join-Path -Path $script:JournalRoot -ChildPath "logs"

# Fonction pour créer une nouvelle entrée de journal
function New-RoadmapJournalEntry {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^\d+(\.\d+)*$")]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$Status = "NotStarted",

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{},

        [Parameter(Mandatory = $false)]
        [string[]]$SubTasks = @(),

        [Parameter(Mandatory = $false)]
        [string]$ParentId = $null
    )

    try {
        # Vérifier si l'entrée existe déjà
        $index = Get-Content -Path $script:IndexPath -Raw | ConvertFrom-Json
        if ($index.entries.PSObject.Properties.Name -contains $Id) {
            Write-Error "Une entrée avec l'ID '$Id' existe déjà."
            return $false
        }

        # Créer le chemin pour l'entrée
        $sectionId = $Id.Split('.')[0]
        $sectionPath = Join-Path -Path $script:SectionsPath -ChildPath "${sectionId}_section"
        if (-not (Test-Path -Path $sectionPath)) {
            New-Item -Path $sectionPath -ItemType Directory -Force | Out-Null
        }

        # Créer l'entrée à partir du modèle
        $templatePath = Join-Path -Path $script:TemplatesPath -ChildPath "entry_template.json"
        $entry = Get-Content -Path $templatePath -Raw | ConvertFrom-Json

        # Remplir les champs obligatoires
        $entry.id = $Id
        $entry.title = $Title
        $entry.status = $Status
        $entry.description = $Description
        $entry.createdAt = (Get-Date).ToUniversalTime().ToString("o")
        $entry.updatedAt = $entry.createdAt

        # Remplir les métadonnées
        if ($Metadata.ContainsKey("complexity")) { $entry.metadata.complexity = $Metadata.complexity }
        if ($Metadata.ContainsKey("estimatedHours")) { $entry.metadata.estimatedHours = $Metadata.estimatedHours }
        if ($Metadata.ContainsKey("progress")) { $entry.metadata.progress = $Metadata.progress }
        if ($Metadata.ContainsKey("dueDate")) { $entry.metadata.dueDate = $Metadata.dueDate }
        if ($Metadata.ContainsKey("startDate")) { $entry.metadata.startDate = $Metadata.startDate }
        if ($Metadata.ContainsKey("owner")) { $entry.metadata.owner = $Metadata.owner }

        # Ajouter les sous-tâches et le parent
        $entry.subTasks = $SubTasks
        $entry.parentId = $ParentId

        # Enregistrer l'entrée
        $entryPath = Join-Path -Path $sectionPath -ChildPath "$Id.json"
        if ($PSCmdlet.ShouldProcess($entryPath, "Créer une nouvelle entrée de journal")) {
            $entry | ConvertTo-Json -Depth 10 | Out-File -FilePath $entryPath -Encoding utf8 -Force

            # Mettre à jour l'index
            $index.entries | Add-Member -MemberType NoteProperty -Name $Id -Value $entryPath
            $index.lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
            $index.statistics.totalEntries++

            switch ($Status) {
                "NotStarted" { $index.statistics.notStarted++ }
                "InProgress" { $index.statistics.inProgress++ }
                "Completed" { $index.statistics.completed++ }
                "Blocked" { $index.statistics.blocked++ }
            }

            $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:IndexPath -Encoding utf8 -Force

            # Journaliser l'opération
            Write-Log -Message "Nouvelle entrée créée: $Id - $Title" -Level "Info"

            return $true
        }

        return $false
    } catch {
        Write-Error "Erreur lors de la création de l'entrée: $_"
        Write-Log -Message "Erreur lors de la création de l'entrée $Id : $_" -Level "Error"
        return $false
    }
}

# Fonction pour mettre à jour une entrée existante
function Update-RoadmapJournalEntry {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^\d+(\.\d+)*$")]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata,

        [Parameter(Mandatory = $false)]
        [string[]]$SubTasks,

        [Parameter(Mandatory = $false)]
        [string]$ParentId
    )

    try {
        # Vérifier si l'entrée existe
        $index = Get-Content -Path $script:IndexPath -Raw | ConvertFrom-Json
        if ($index.entries.PSObject.Properties.Name -notcontains $Id) {
            Write-Error "Aucune entrée avec l'ID '$Id' n'a été trouvée."
            return $false
        }

        # Récupérer le chemin de l'entrée
        $entryPath = $index.entries.$Id
        if (-not (Test-Path -Path $entryPath)) {
            Write-Error "Le fichier d'entrée '$entryPath' n'existe pas."
            return $false
        }

        # Charger l'entrée existante
        $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
        $oldStatus = $entry.status

        # Mettre à jour les champs
        if ($PSBoundParameters.ContainsKey('Title')) { $entry.title = $Title }
        if ($PSBoundParameters.ContainsKey('Status')) { $entry.status = $Status }
        if ($PSBoundParameters.ContainsKey('Description')) { $entry.description = $Description }
        if ($PSBoundParameters.ContainsKey('SubTasks')) { $entry.subTasks = $SubTasks }
        if ($PSBoundParameters.ContainsKey('ParentId')) { $entry.parentId = $ParentId }

        # Mettre à jour les métadonnées
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            if ($Metadata.ContainsKey("complexity")) { $entry.metadata.complexity = $Metadata.complexity }
            if ($Metadata.ContainsKey("estimatedHours")) { $entry.metadata.estimatedHours = $Metadata.estimatedHours }
            if ($Metadata.ContainsKey("progress")) { $entry.metadata.progress = $Metadata.progress }
            if ($Metadata.ContainsKey("dueDate")) { $entry.metadata.dueDate = $Metadata.dueDate }
            if ($Metadata.ContainsKey("startDate")) { $entry.metadata.startDate = $Metadata.startDate }
            if ($Metadata.ContainsKey("completionDate")) { $entry.metadata.completionDate = $Metadata.completionDate }
            if ($Metadata.ContainsKey("owner")) { $entry.metadata.owner = $Metadata.owner }
        }

        # Mettre à jour la date de modification
        $entry.updatedAt = (Get-Date).ToUniversalTime().ToString("o")

        # Enregistrer l'entrée mise à jour
        if ($PSCmdlet.ShouldProcess($entryPath, "Mettre à jour l'entrée de journal")) {
            $entry | ConvertTo-Json -Depth 10 | Out-File -FilePath $entryPath -Encoding utf8 -Force

            # Mettre à jour les statistiques de l'index si le statut a changé
            if ($PSBoundParameters.ContainsKey('Status') -and $Status -ne $oldStatus) {
                $index = Get-Content -Path $script:IndexPath -Raw | ConvertFrom-Json

                # Décrémenter l'ancien statut
                switch ($oldStatus) {
                    "NotStarted" { $index.statistics.notStarted-- }
                    "InProgress" { $index.statistics.inProgress-- }
                    "Completed" { $index.statistics.completed-- }
                    "Blocked" { $index.statistics.blocked-- }
                }

                # Incrémenter le nouveau statut
                switch ($Status) {
                    "NotStarted" { $index.statistics.notStarted++ }
                    "InProgress" { $index.statistics.inProgress++ }
                    "Completed" { $index.statistics.completed++ }
                    "Blocked" { $index.statistics.blocked++ }
                }

                $index.lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
                $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:IndexPath -Encoding utf8 -Force

                # Si la tâche est marquée comme terminée, vérifier si elle doit être archivée
                if ($Status -eq "Completed") {
                    $metadata = Get-Content -Path $script:MetadataPath -Raw | ConvertFrom-Json
                    if ($metadata.settings.archiveCompletedTasks) {
                        Move-RoadmapJournalEntryToArchive -Id $Id
                    }
                }
            }

            # Journaliser l'opération
            Write-Log -Message "Entrée mise à jour: $Id" -Level "Info"

            return $true
        }

        return $false
    } catch {
        Write-Error "Erreur lors de la mise à jour de l'entrée: $_"
        Write-Log -Message "Erreur lors de la mise à jour de l'entrée $Id : $_" -Level "Error"
        return $false
    }
}

# Fonction pour archiver une entrée
function Move-RoadmapJournalEntryToArchive {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^\d+(\.\d+)*$")]
        [string]$Id
    )

    try {
        # Vérifier si l'entrée existe
        $index = Get-Content -Path $script:IndexPath -Raw | ConvertFrom-Json
        if ($index.entries.PSObject.Properties.Name -notcontains $Id) {
            Write-Error "Aucune entrée avec l'ID '$Id' n'a été trouvée."
            return $false
        }

        # Récupérer le chemin de l'entrée
        $entryPath = $index.entries.$Id
        if (-not (Test-Path -Path $entryPath)) {
            Write-Error "Le fichier d'entrée '$entryPath' n'existe pas."
            return $false
        }

        # Charger l'entrée
        $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

        # Créer le dossier d'archives pour le mois en cours
        $archiveFolder = Join-Path -Path $script:ArchivesPath -ChildPath (Get-Date -Format "yyyy-MM")
        if (-not (Test-Path -Path $archiveFolder)) {
            New-Item -Path $archiveFolder -ItemType Directory -Force | Out-Null
        }

        # Définir le chemin d'archive
        $archivePath = Join-Path -Path $archiveFolder -ChildPath "$Id.json"

        # Archiver l'entrée
        if ($PSCmdlet.ShouldProcess($archivePath, "Archiver l'entrée de journal")) {
            Copy-Item -Path $entryPath -Destination $archivePath -Force
            Remove-Item -Path $entryPath -Force

            # Mettre à jour l'index
            $index = Get-Content -Path $script:IndexPath -Raw | ConvertFrom-Json
            $index.entries.PSObject.Properties.Remove($Id)
            $index.lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
            $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:IndexPath -Encoding utf8 -Force

            # Journaliser l'opération
            Write-Log -Message "Entrée archivée: $Id" -Level "Info"

            return $true
        }

        return $false
    } catch {
        Write-Error "Erreur lors de l'archivage de l'entrée: $_"
        Write-Log -Message "Erreur lors de l'archivage de l'entrée $Id : $_" -Level "Error"
        return $false
    }
}

# Fonction pour obtenir l'état global du projet
function Get-RoadmapJournalStatus {
    [CmdletBinding()]
    param()

    try {
        # Charger le fichier de statut
        $status = Get-Content -Path $script:StatusPath -Raw | ConvertFrom-Json

        # Charger l'index pour les statistiques à jour
        $index = Get-Content -Path $script:IndexPath -Raw | ConvertFrom-Json

        # Calculer la progression globale
        $totalTasks = $index.statistics.totalEntries
        $completedTasks = $index.statistics.completed

        if ($totalTasks -gt 0) {
            $globalProgress = [math]::Round(($completedTasks / $totalTasks) * 100)
        } else {
            $globalProgress = 0
        }

        # Mettre à jour le statut
        $status.lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
        $status.globalProgress = $globalProgress

        # Identifier les tâches en retard
        $overdueTasks = @()
        $upcomingDeadlines = @()
        $blockedTasks = @()

        foreach ($entryId in $index.entries.PSObject.Properties.Name) {
            $entryPath = $index.entries.$entryId
            $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

            # Vérifier si la tâche est en retard
            if ($entry.metadata.dueDate -and $entry.status -ne "Completed") {
                $dueDate = [DateTime]::Parse($entry.metadata.dueDate)
                if ($dueDate -lt (Get-Date)) {
                    $overdueTasks += @{
                        id          = $entry.id
                        title       = $entry.title
                        dueDate     = $entry.metadata.dueDate
                        daysOverdue = ((Get-Date) - $dueDate).Days
                    }
                } elseif ($dueDate -lt (Get-Date).AddDays(7)) {
                    $upcomingDeadlines += @{
                        id            = $entry.id
                        title         = $entry.title
                        dueDate       = $entry.metadata.dueDate
                        daysRemaining = ($dueDate - (Get-Date)).Days
                    }
                }
            }

            # Vérifier si la tâche est bloquée
            if ($entry.status -eq "Blocked") {
                $blockedTasks += @{
                    id    = $entry.id
                    title = $entry.title
                }
            }
        }

        # Mettre à jour les listes
        $status.overdueTasks = $overdueTasks
        $status.upcomingDeadlines = $upcomingDeadlines
        $status.blockedTasks = $blockedTasks

        # Enregistrer le statut mis à jour
        $status | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:StatusPath -Encoding utf8 -Force

        return $status
    } catch {
        Write-Error "Erreur lors de la récupération du statut: $_"
        Write-Log -Message "Erreur lors de la récupération du statut : $_" -Level "Error"
        return $null
    }
}

# Fonction utilitaire pour la journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )

    $logFile = Join-Path -Path $script:LogsPath -ChildPath "journal_$(Get-Date -Format 'yyyy-MM-dd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

# Exporter les fonctions
Export-ModuleMember -Function New-RoadmapJournalEntry, Update-RoadmapJournalEntry, Move-RoadmapJournalEntryToArchive, Get-RoadmapJournalStatus
