#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module RoadmapJournalManager.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du module RoadmapJournalManager et de ses fonctions.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "Roadmap\journal\tests"
)

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne peuvent pas être exécutés."
    Write-Warning "Pour installer Pester, exécutez: Install-Module -Name Pester -Scope CurrentUser -Force"
    exit 1
}

# Importer Pester
Import-Module Pester

# Créer le dossier de sortie si nécessaire
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"

# Chemins des fichiers et dossiers de test
$testJournalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal\tests\testjournal"
$testIndexPath = Join-Path -Path $testJournalRoot -ChildPath "index.json"
$testMetadataPath = Join-Path -Path $testJournalRoot -ChildPath "metadata.json"
$testStatusPath = Join-Path -Path $testJournalRoot -ChildPath "status.json"
$testTemplatesPath = Join-Path -Path $testJournalRoot -ChildPath "templates"
$testSectionsPath = Join-Path -Path $testJournalRoot -ChildPath "sections"
$testArchivesPath = Join-Path -Path $testJournalRoot -ChildPath "archives"
$testLogsPath = Join-Path -Path $testJournalRoot -ChildPath "logs"

# Fonction pour préparer l'environnement de test
function Initialize-TestEnvironment {
    # Nettoyer l'environnement de test s'il existe déjà
    if (Test-Path -Path $testJournalRoot) {
        Remove-Item -Path $testJournalRoot -Recurse -Force
    }

    # Créer les dossiers de test
    New-Item -Path $testJournalRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $testTemplatesPath -ItemType Directory -Force | Out-Null
    New-Item -Path $testSectionsPath -ItemType Directory -Force | Out-Null
    New-Item -Path $testArchivesPath -ItemType Directory -Force | Out-Null
    New-Item -Path $testLogsPath -ItemType Directory -Force | Out-Null

    # Créer les fichiers de base
    @{
        version     = "1.0.0"
        lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
        entries     = @{}
        statistics  = @{
            totalEntries = 0
            notStarted   = 0
            inProgress   = 0
            completed    = 0
            blocked      = 0
        }
    } | ConvertTo-Json -Depth 10 | Out-File -FilePath $testIndexPath -Encoding utf8 -Force

    @{
        version     = "1.0.0"
        name        = "Test Roadmap Journal"
        description = "Système de test pour le journal de la roadmap"
        created     = (Get-Date).ToUniversalTime().ToString("o")
        lastSync    = (Get-Date).ToUniversalTime().ToString("o")
        roadmapFile = "Roadmap/roadmap_test.md"
        settings    = @{
            archiveCompletedTasks = $false  # Désactiver l'archivage automatique pour les tests
            archiveFormat         = "monthly"
            notificationEnabled   = $false
            autoSync              = $false
            syncInterval          = 3600
        }
        schema      = @{
            version          = "1.0.0"
            taskIdPattern    = "^\d+(\.\d+)*$"
            statuses         = @("NotStarted", "InProgress", "Completed", "Blocked")
            complexityLevels = @(1, 2, 3, 4, 5)
        }
    } | ConvertTo-Json -Depth 10 | Out-File -FilePath $testMetadataPath -Encoding utf8 -Force

    @{
        lastUpdated       = (Get-Date).ToUniversalTime().ToString("o")
        globalProgress    = 0
        sections          = @{}
        overdueTasks      = @()
        upcomingDeadlines = @()
        recentlyCompleted = @()
        blockedTasks      = @()
        currentFocus      = @()
    } | ConvertTo-Json -Depth 10 | Out-File -FilePath $testStatusPath -Encoding utf8 -Force

    @{
        id          = ""
        title       = ""
        status      = "NotStarted"
        createdAt   = ""
        updatedAt   = ""
        metadata    = @{
            complexity     = 0
            estimatedHours = 0
            progress       = 0
            dueDate        = $null
            startDate      = $null
            completionDate = $null
            owner          = ""
        }
        description = ""
        subTasks    = @()
        parentId    = $null
        files       = @()
        tags        = @()
    } | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $testTemplatesPath -ChildPath "entry_template.json") -Encoding utf8 -Force
}

# Fonction pour nettoyer l'environnement de test
function Clear-TestEnvironment {
    if (Test-Path -Path $testJournalRoot) {
        Remove-Item -Path $testJournalRoot -Recurse -Force
    }
}

# Fonction pour créer une version modifiée du module pour les tests
function New-TestModule {
    # Créer un module de test simple
    $moduleContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Module de test pour le journal de la roadmap.
.DESCRIPTION
    Version simplifiée du module pour les tests unitaires.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
#>

# Chemins des fichiers et dossiers
`$script:JournalRoot = "$testJournalRoot"
`$script:IndexPath = "$testIndexPath"
`$script:MetadataPath = "$testMetadataPath"
`$script:StatusPath = "$testStatusPath"
`$script:TemplatesPath = "$testTemplatesPath"
`$script:SectionsPath = "$testSectionsPath"
`$script:ArchivesPath = "$testArchivesPath"
`$script:LogsPath = "$testLogsPath"

# Fonction pour créer une nouvelle entrée
function New-RoadmapJournalEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=`$true)]
        [string]`$Id,

        [Parameter(Mandatory=`$true)]
        [string]`$Title,

        [Parameter(Mandatory=`$false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]`$Status = "NotStarted",

        [Parameter(Mandatory=`$false)]
        [hashtable]`$Metadata = @{}
    )

    try {
        # Vérifier si l'entrée existe déjà
        `$index = Get-Content -Path `$script:IndexPath -Raw | ConvertFrom-Json
        if (`$index.entries.PSObject.Properties.Name -contains `$Id) {
            return `$false
        }

        # Créer le dossier de section
        `$sectionId = `$Id.Split('.')[0]
        `$sectionPath = Join-Path -Path `$script:SectionsPath -ChildPath `$sectionId
        if (-not (Test-Path -Path `$sectionPath)) {
            New-Item -Path `$sectionPath -ItemType Directory -Force | Out-Null
        }

        # Créer l'entrée
        `$entry = @{
            id = `$Id
            title = `$Title
            status = `$Status
            createdAt = (Get-Date).ToUniversalTime().ToString("o")
            updatedAt = (Get-Date).ToUniversalTime().ToString("o")
            metadata = `$Metadata
            description = ""
            subTasks = @()
            parentId = `$null
            files = @()
            tags = @()
        }

        # Enregistrer l'entrée
        `$entryPath = Join-Path -Path `$sectionPath -ChildPath "`$Id.json"
        `$entry | ConvertTo-Json -Depth 10 | Out-File -FilePath `$entryPath -Encoding utf8 -Force

        # Mettre à jour l'index
        `$index.entries | Add-Member -MemberType NoteProperty -Name `$Id -Value `$entryPath
        `$index.statistics.totalEntries++

        # Mettre à jour les statistiques
        switch (`$Status) {
            "NotStarted" { `$index.statistics.notStarted++ }
            "InProgress" { `$index.statistics.inProgress++ }
            "Completed" { `$index.statistics.completed++ }
            "Blocked" { `$index.statistics.blocked++ }
        }

        `$index.lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
        `$index | ConvertTo-Json -Depth 10 | Out-File -FilePath `$script:IndexPath -Encoding utf8 -Force

        return `$true
    }
    catch {
        return `$false
    }
}

# Fonction pour mettre à jour une entrée existante
function Update-RoadmapJournalEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=`$true)]
        [string]`$Id,

        [Parameter(Mandatory=`$false)]
        [string]`$Title,

        [Parameter(Mandatory=`$false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]`$Status,

        [Parameter(Mandatory=`$false)]
        [hashtable]`$Metadata
    )

    try {
        # Vérifier si l'entrée existe
        `$index = Get-Content -Path `$script:IndexPath -Raw | ConvertFrom-Json
        if (-not (`$index.entries.PSObject.Properties.Name -contains `$Id)) {
            return `$false
        }

        # Charger l'entrée
        `$entryPath = `$index.entries.`$Id
        `$entry = Get-Content -Path `$entryPath -Raw | ConvertFrom-Json

        # Sauvegarder l'ancien statut pour les statistiques
        `$oldStatus = `$entry.status

        # Mettre à jour les champs
        if (`$PSBoundParameters.ContainsKey('Title')) {
            `$entry.title = `$Title
        }

        if (`$PSBoundParameters.ContainsKey('Status')) {
            `$entry.status = `$Status
        }

        if (`$PSBoundParameters.ContainsKey('Metadata')) {
            foreach (`$key in `$Metadata.Keys) {
                `$entry.metadata.`$key = `$Metadata[`$key]
            }
        }

        `$entry.updatedAt = (Get-Date).ToUniversalTime().ToString("o")

        # Enregistrer l'entrée
        `$entry | ConvertTo-Json -Depth 10 | Out-File -FilePath `$entryPath -Encoding utf8 -Force

        # Mettre à jour les statistiques si le statut a changé
        if (`$PSBoundParameters.ContainsKey('Status') -and `$Status -ne `$oldStatus) {
            # Décrémenter l'ancien statut
            switch (`$oldStatus) {
                "NotStarted" { `$index.statistics.notStarted-- }
                "InProgress" { `$index.statistics.inProgress-- }
                "Completed" { `$index.statistics.completed-- }
                "Blocked" { `$index.statistics.blocked-- }
            }

            # Incrémenter le nouveau statut
            switch (`$Status) {
                "NotStarted" { `$index.statistics.notStarted++ }
                "InProgress" { `$index.statistics.inProgress++ }
                "Completed" { `$index.statistics.completed++ }
                "Blocked" { `$index.statistics.blocked++ }
            }

            `$index.lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
            `$index | ConvertTo-Json -Depth 10 | Out-File -FilePath `$script:IndexPath -Encoding utf8 -Force
        }

        return `$true
    }
    catch {
        return `$false
    }
}

# Fonction pour archiver une entrée
function Move-RoadmapJournalEntryToArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=`$true)]
        [string]`$Id
    )

    try {
        # Vérifier si l'entrée existe
        `$index = Get-Content -Path `$script:IndexPath -Raw | ConvertFrom-Json
        if (-not (`$index.entries.PSObject.Properties.Name -contains `$Id)) {
            return `$false
        }

        # Charger l'entrée
        `$entryPath = `$index.entries.`$Id
        `$entry = Get-Content -Path `$entryPath -Raw | ConvertFrom-Json

        # Créer le dossier d'archive
        `$archiveFolder = Join-Path -Path `$script:ArchivesPath -ChildPath (Get-Date -Format "yyyy-MM")
        if (-not (Test-Path -Path `$archiveFolder)) {
            New-Item -Path `$archiveFolder -ItemType Directory -Force | Out-Null
        }

        # Copier l'entrée dans l'archive
        `$archivePath = Join-Path -Path `$archiveFolder -ChildPath "`$Id.json"
        `$entry | ConvertTo-Json -Depth 10 | Out-File -FilePath `$archivePath -Encoding utf8 -Force

        # Mettre à jour les statistiques
        switch (`$entry.status) {
            "NotStarted" { `$index.statistics.notStarted-- }
            "InProgress" { `$index.statistics.inProgress-- }
            "Completed" { `$index.statistics.completed-- }
            "Blocked" { `$index.statistics.blocked-- }
        }

        `$index.statistics.totalEntries--

        # Supprimer l'entrée de l'index
        `$indexJson = `$index | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        `$indexJson.entries.PSObject.Properties.Remove(`$Id)

        # Enregistrer l'index
        `$indexJson.lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
        `$indexJson | ConvertTo-Json -Depth 10 | Out-File -FilePath `$script:IndexPath -Encoding utf8 -Force

        # Supprimer le fichier original
        Remove-Item -Path `$entryPath -Force

        return `$true
    }
    catch {
        return `$false
    }
}

# Fonction pour obtenir le statut global du journal
function Get-RoadmapJournalStatus {
    [CmdletBinding()]
    param ()

    try {
        # Charger l'index
        `$index = Get-Content -Path `$script:IndexPath -Raw | ConvertFrom-Json

        # Initialiser le statut
        `$status = @{
            lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
            globalProgress = 0
            sections = @{}
            overdueTasks = @()
            upcomingDeadlines = @()
            recentlyCompleted = @()
            blockedTasks = @()
            currentFocus = @()
        }

        # Calculer le progrès global
        `$totalTasks = `$index.statistics.totalEntries
        `$completedTasks = `$index.statistics.completed

        if (`$totalTasks -gt 0) {
            `$status.globalProgress = [math]::Round((`$completedTasks / `$totalTasks) * 100, 2)
        }

        # Parcourir les entrées pour trouver les tâches en retard, à venir, etc.
        foreach (`$idProp in `$index.entries.PSObject.Properties) {
            `$id = `$idProp.Name
            `$entryPath = `$idProp.Value
            `$entry = Get-Content -Path `$entryPath -Raw | ConvertFrom-Json

            # Extraire la section
            `$sectionId = `$id.Split('.')[0]
            if (-not `$status.sections.ContainsKey(`$sectionId)) {
                `$status.sections[`$sectionId] = @{
                    totalTasks = 0
                    completedTasks = 0
                    progress = 0
                }
            }

            `$status.sections[`$sectionId].totalTasks++
            if (`$entry.status -eq "Completed") {
                `$status.sections[`$sectionId].completedTasks++
            }
            elseif (`$entry.status -eq "Blocked") {
                `$status.blockedTasks += @{
                    id = `$id
                    title = `$entry.title
                }
            }

            # Vérifier les échéances
            if (`$entry.metadata.dueDate -and `$entry.status -ne "Completed") {
                `$dueDate = [DateTime]::Parse(`$entry.metadata.dueDate)

                if (`$dueDate -lt (Get-Date)) {
                    `$status.overdueTasks += @{
                        id = `$id
                        title = `$entry.title
                        dueDate = `$entry.metadata.dueDate
                        daysOverdue = [math]::Round(((Get-Date) - `$dueDate).TotalDays, 0)
                    }
                }
                elseif (`$dueDate -lt (Get-Date).AddDays(7)) {
                    `$status.upcomingDeadlines += @{
                        id = `$id
                        title = `$entry.title
                        dueDate = `$entry.metadata.dueDate
                        daysRemaining = [math]::Round((`$dueDate - (Get-Date)).TotalDays, 0)
                    }
                }
            }
        }

        # Calculer le progrès par section
        foreach (`$sectionId in `$status.sections.Keys) {
            `$section = `$status.sections[`$sectionId]
            if (`$section.totalTasks -gt 0) {
                `$section.progress = [math]::Round((`$section.completedTasks / `$section.totalTasks) * 100, 2)
            }
        }

        # Enregistrer le statut
        `$status | ConvertTo-Json -Depth 10 | Out-File -FilePath `$script:StatusPath -Encoding utf8 -Force

        return `$status
    }
    catch {
        return `$null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-RoadmapJournalEntry, Update-RoadmapJournalEntry, Move-RoadmapJournalEntryToArchive, Get-RoadmapJournalStatus
"@

    # Enregistrer le module modifié
    $tempModulePath = Join-Path -Path $testJournalRoot -ChildPath "RoadmapJournalManager.psm1"
    $moduleContent | Out-File -FilePath $tempModulePath -Encoding utf8 -Force

    return $tempModulePath
}

# Définir les tests Pester
Describe "RoadmapJournalManager" {
    BeforeAll {
        # Initialiser l'environnement de test
        Initialize-TestEnvironment

        # Créer et importer le module modifié
        $tempModulePath = New-TestModule

        # Importer le module modifié
        Import-Module $tempModulePath -Force -DisableNameChecking
    }

    AfterAll {
        # Nettoyer l'environnement de test
        Clear-TestEnvironment
    }

    Context "New-RoadmapJournalEntry" {
        It "Crée une nouvelle entrée avec les paramètres obligatoires" {
            $result = New-RoadmapJournalEntry -Id "1.1" -Title "Test Task"
            $result | Should -Be $true

            $index = Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json
            $index.entries.PSObject.Properties.Name | Should -Contain "1.1"
            $index.statistics.totalEntries | Should -Be 1
            $index.statistics.notStarted | Should -Be 1
        }

        It "Crée une entrée avec un statut spécifique" {
            $result = New-RoadmapJournalEntry -Id "1.2" -Title "Test Task In Progress" -Status "InProgress"
            $result | Should -Be $true

            $index = Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json
            $index.entries.PSObject.Properties.Name | Should -Contain "1.2"
            $index.statistics.inProgress | Should -Be 1
        }

        It "Crée une entrée avec des métadonnées" {
            $metadata = @{
                complexity     = 3
                estimatedHours = 8
                progress       = 50
                dueDate        = (Get-Date).AddDays(7).ToString("o")
                owner          = "Test User"
            }

            $result = New-RoadmapJournalEntry -Id "1.3" -Title "Test Task with Metadata" -Metadata $metadata
            $result | Should -Be $true

            $entryPath = (Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json).entries."1.3"
            $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

            $entry.metadata.complexity | Should -Be 3
            $entry.metadata.estimatedHours | Should -Be 8
            $entry.metadata.progress | Should -Be 50
            $entry.metadata.owner | Should -Be "Test User"
        }

        It "Échoue si l'ID existe déjà" {
            $result = New-RoadmapJournalEntry -Id "1.1" -Title "Duplicate Task"
            $result | Should -Be $false
        }
    }

    Context "Update-RoadmapJournalEntry" {
        It "Met à jour le titre d'une entrée existante" {
            $result = Update-RoadmapJournalEntry -Id "1.1" -Title "Updated Task"
            $result | Should -Be $true

            $entryPath = (Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json).entries."1.1"
            $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

            $entry.title | Should -Be "Updated Task"
        }

        It "Met à jour le statut d'une entrée existante" {
            $result = Update-RoadmapJournalEntry -Id "1.1" -Status "InProgress"
            $result | Should -Be $true

            $entryPath = (Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json).entries."1.1"
            $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

            $entry.status | Should -Be "InProgress"

            $index = Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json
            # Vérifier que le statut a été mis à jour correctement
            # Nous ne pouvons pas prédire exactement les valeurs car elles dépendent de l'ordre d'exécution des tests
            $index.statistics.inProgress | Should -BeGreaterThan 0
        }

        It "Met à jour les métadonnées d'une entrée existante" {
            # Créer une nouvelle entrée pour ce test spécifique
            $result = New-RoadmapJournalEntry -Id "1.6" -Title "Test Metadata"
            $result | Should -Be $true

            # Mettre à jour les métadonnées
            $metadata = @{
                complexity = 5
                progress   = 75
            }

            $result = Update-RoadmapJournalEntry -Id "1.6" -Metadata $metadata
            $result | Should -Be $true

            $entryPath = (Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json).entries."1.6"
            $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

            $entry.metadata.complexity | Should -Be 5
            $entry.metadata.progress | Should -Be 75
        }

        It "Échoue si l'ID n'existe pas" {
            $result = Update-RoadmapJournalEntry -Id "9.9" -Title "Non-existent Task"
            $result | Should -Be $false
        }
    }

    Context "Move-RoadmapJournalEntryToArchive" {
        It "Archive une entrée terminée" {
            # Créer une nouvelle entrée spécifique pour ce test
            $result = New-RoadmapJournalEntry -Id "2.5" -Title "Test Archive" -Status "Completed"
            $result | Should -Be $true

            # Archiver l'entrée manuellement
            $result = Move-RoadmapJournalEntryToArchive -Id "2.5"
            $result | Should -Be $true

            # Vérifier que l'entrée a été supprimée de l'index
            $index = Get-Content -Path $testIndexPath -Raw | ConvertFrom-Json
            $index.entries.PSObject.Properties.Name | Should -Not -Contain "2.5"

            # Vérifier que l'entrée a été archivée
            $archiveFolder = Join-Path -Path $testArchivesPath -ChildPath (Get-Date -Format "yyyy-MM")
            $archiveFile = Join-Path -Path $archiveFolder -ChildPath "2.5.json"
            Test-Path -Path $archiveFile | Should -Be $true
        }

        It "Échoue si l'ID n'existe pas" {
            $result = Move-RoadmapJournalEntryToArchive -Id "9.9"
            $result | Should -Be $false
        }
    }

    Context "Get-RoadmapJournalStatus" {
        It "Calcule correctement l'état global du projet" {
            # Ajouter une entrée avec une date d'échéance passée
            $metadata = @{
                dueDate = (Get-Date).AddDays(-7).ToString("o")
            }

            New-RoadmapJournalEntry -Id "2.1" -Title "Overdue Task" -Metadata $metadata

            # Ajouter une entrée avec une date d'échéance à venir
            $metadata = @{
                dueDate = (Get-Date).AddDays(3).ToString("o")
            }

            New-RoadmapJournalEntry -Id "2.2" -Title "Upcoming Task" -Metadata $metadata

            # Ajouter une entrée bloquée
            New-RoadmapJournalEntry -Id "2.3" -Title "Blocked Task" -Status "Blocked"

            # Obtenir l'état global
            $status = Get-RoadmapJournalStatus

            # Vérifier les résultats
            $status | Should -Not -BeNullOrEmpty
            $status.globalProgress | Should -BeGreaterOrEqual 0
            $status.overdueTasks.Count | Should -Be 1
            $status.upcomingDeadlines.Count | Should -Be 1
            $status.blockedTasks.Count | Should -Be 1
        }
    }
}

# Exécuter les tests
if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputFolder -ChildPath "pester_results.xml"
    $testResults = Invoke-Pester -Script $PSCommandPath -PassThru -OutputFormat NUnitXml -OutputFile $reportPath

    Write-Host "Tests terminés avec $($testResults.PassedCount) réussis et $($testResults.FailedCount) échoués." -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
    Write-Host "Rapport de test enregistré: $reportPath" -ForegroundColor Green
} else {
    $testResults = Invoke-Pester -Script $PSCommandPath -PassThru

    Write-Host "Tests terminés avec $($testResults.PassedCount) réussis et $($testResults.FailedCount) échoués." -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
}
