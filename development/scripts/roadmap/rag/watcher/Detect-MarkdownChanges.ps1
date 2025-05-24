#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte les modifications dans les fichiers Markdown.
.DESCRIPTION
    Ce script analyse les fichiers Markdown pour détecter les modifications
    de contenu, notamment les changements dans les tâches (statut, titre, etc.).
    Il fait partie du système de synchronisation bidirectionnelle entre les fichiers
    Markdown et la base vectorielle Qdrant.
.PARAMETER FilePath
    Chemin du fichier Markdown à analyser.
.PARAMETER PreviousVersion
    Chemin du fichier contenant la version précédente du fichier Markdown.
    Si non spécifié, le script tentera de récupérer la version précédente à partir
    de l'historique des modifications.
.PARAMETER OutputPath
    Chemin où enregistrer le rapport des modifications. Si non spécifié,
    le rapport sera affiché dans la console.
.PARAMETER OutputFormat
    Format du rapport de modifications (JSON, Markdown, Text). Par défaut, JSON.
.PARAMETER IncludeMetadata
    Indique si les métadonnées des tâches doivent être incluses dans l'analyse.
    Par défaut, $true.
.EXAMPLE
    .\Detect-MarkdownChanges.ps1 -FilePath "projet\roadmaps\plans\consolidated\plan-dev-v25.md"
    Détecte les modifications dans le fichier spécifié par rapport à sa version précédente.
.NOTES
    Nom: Detect-MarkdownChanges.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$PreviousVersion,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "Text")]
    [string]$OutputFormat = "JSON",
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeMetadata = $true
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "..\modules"
$loggingModulePath = Join-Path -Path $modulesPath -ChildPath "Logging.psm1"
$parserModulePath = Join-Path -Path $modulesPath -ChildPath "MarkdownParser.psm1"

if (Test-Path -Path $loggingModulePath) {
    Import-Module $loggingModulePath -Force
} else {
    # Fonction de logging simplifiée si le module n'est pas disponible
    function Write-Log {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Définir la couleur en fonction du niveau
        $color = switch ($Level) {
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Cyan" }
            default { "White" }
        }
        
        # Afficher le message dans la console
        Write-Host $logMessage -ForegroundColor $color
    }
}

if (Test-Path -Path $parserModulePath) {
    Import-Module $parserModulePath -Force
} else {
    # Fonction d'extraction des tâches si le module n'est pas disponible
    function Get-MarkdownTasks {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Content
        )
        
        $tasks = @()
        $taskPattern = '- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'
        
        $matches = [regex]::Matches($Content, $taskPattern)
        
        foreach ($match in $matches) {
            $status = if ($match.Groups[1].Value -match '[xX]') { "Completed" } else { "Pending" }
            $id = $match.Groups[2].Value
            $title = $match.Groups[3].Value.Trim()
            
            $tasks += [PSCustomObject]@{
                Id = $id
                Title = $title
                Status = $status
                LineNumber = 0  # Sera calculé plus tard si nécessaire
                Metadata = @{}
            }
        }
        
        return $tasks
    }
}

# Fonction pour obtenir la version précédente d'un fichier
function Get-PreviousVersion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Vérifier si Git est disponible
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    
    if ($gitCommand) {
        try {
            # Vérifier si le fichier est suivi par Git
            $isTracked = git ls-files --error-unmatch $FilePath 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                # Obtenir la version précédente du fichier
                $tempFile = [System.IO.Path]::GetTempFileName()
                git show HEAD:$FilePath > $tempFile 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    return $tempFile
                }
            }
        } catch {
            Write-Log "Erreur lors de la récupération de la version Git: $_" -Level "WARNING"
        }
    }
    
    # Si Git n'est pas disponible ou le fichier n'est pas suivi, vérifier les backups
    $backupDir = Join-Path -Path (Split-Path -Parent $FilePath) -ChildPath ".backups"
    $fileName = Split-Path -Leaf $FilePath
    $backupFile = Join-Path -Path $backupDir -ChildPath "$fileName.bak"
    
    if (Test-Path -Path $backupFile) {
        return $backupFile
    }
    
    # Aucune version précédente trouvée
    return $null
}

# Fonction pour comparer deux ensembles de tâches
function Compare-TaskSets {
    param (
        [Parameter(Mandatory = $true)]
        [array]$OldTasks,
        
        [Parameter(Mandatory = $true)]
        [array]$NewTasks
    )
    
    $changes = @{
        Added = @()
        Removed = @()
        Modified = @()
        StatusChanged = @()
    }
    
    # Créer des dictionnaires pour faciliter la recherche
    $oldTasksDict = @{}
    $newTasksDict = @{}
    
    foreach ($task in $OldTasks) {
        $oldTasksDict[$task.Id] = $task
    }
    
    foreach ($task in $NewTasks) {
        $newTasksDict[$task.Id] = $task
    }
    
    # Trouver les tâches ajoutées
    foreach ($task in $NewTasks) {
        if (-not $oldTasksDict.ContainsKey($task.Id)) {
            $changes.Added += $task
        }
    }
    
    # Trouver les tâches supprimées
    foreach ($task in $OldTasks) {
        if (-not $newTasksDict.ContainsKey($task.Id)) {
            $changes.Removed += $task
        }
    }
    
    # Trouver les tâches modifiées
    foreach ($task in $NewTasks) {
        if ($oldTasksDict.ContainsKey($task.Id)) {
            $oldTask = $oldTasksDict[$task.Id]
            
            # Vérifier si le statut a changé
            if ($oldTask.Status -ne $task.Status) {
                $changes.StatusChanged += [PSCustomObject]@{
                    Id = $task.Id
                    Title = $task.Title
                    OldStatus = $oldTask.Status
                    NewStatus = $task.Status
                }
            }
            
            # Vérifier si le titre a changé
            if ($oldTask.Title -ne $task.Title) {
                $changes.Modified += [PSCustomObject]@{
                    Id = $task.Id
                    OldTitle = $oldTask.Title
                    NewTitle = $task.Title
                    Status = $task.Status
                }
            }
        }
    }
    
    return $changes
}

# Fonction pour générer un rapport au format Markdown
function ConvertTo-MarkdownReport {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Changes,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $fileName = Split-Path -Leaf $FilePath
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $markdown = @"
# Rapport de modifications - $fileName
*Généré le $timestamp*

## Résumé des modifications

- **Tâches ajoutées**: ${$Changes.Added.Count}
- **Tâches supprimées**: ${$Changes.Removed.Count}
- **Tâches modifiées**: ${$Changes.Modified.Count}
- **Statuts changés**: ${$Changes.StatusChanged.Count}

"@
    
    if ($Changes.Added.Count -gt 0) {
        $markdown += @"
## Tâches ajoutées

| ID | Titre | Statut |
|---|---|---|
"@
        
        foreach ($task in $Changes.Added) {
            $markdown += "`n| $($task.Id) | $($task.Title) | $($task.Status) |"
        }
        
        $markdown += "`n`n"
    }
    
    if ($Changes.Removed.Count -gt 0) {
        $markdown += @"
## Tâches supprimées

| ID | Titre | Statut |
|---|---|---|
"@
        
        foreach ($task in $Changes.Removed) {
            $markdown += "`n| $($task.Id) | $($task.Title) | $($task.Status) |"
        }
        
        $markdown += "`n`n"
    }
    
    if ($Changes.Modified.Count -gt 0) {
        $markdown += @"
## Tâches modifiées

| ID | Ancien titre | Nouveau titre |
|---|---|---|
"@
        
        foreach ($task in $Changes.Modified) {
            $markdown += "`n| $($task.Id) | $($task.OldTitle) | $($task.NewTitle) |"
        }
        
        $markdown += "`n`n"
    }
    
    if ($Changes.StatusChanged.Count -gt 0) {
        $markdown += @"
## Statuts changés

| ID | Titre | Ancien statut | Nouveau statut |
|---|---|---|---|
"@
        
        foreach ($task in $Changes.StatusChanged) {
            $markdown += "`n| $($task.Id) | $($task.Title) | $($task.OldStatus) | $($task.NewStatus) |"
        }
        
        $markdown += "`n`n"
    }
    
    return $markdown
}

# Fonction pour générer un rapport au format texte
function ConvertTo-TextReport {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Changes,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $fileName = Split-Path -Leaf $FilePath
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $text = @"
Rapport de modifications - $fileName
Généré le $timestamp

Résumé des modifications:
- Tâches ajoutées: ${$Changes.Added.Count}
- Tâches supprimées: ${$Changes.Removed.Count}
- Tâches modifiées: ${$Changes.Modified.Count}
- Statuts changés: ${$Changes.StatusChanged.Count}

"@
    
    if ($Changes.Added.Count -gt 0) {
        $text += "Tâches ajoutées:`n"
        
        foreach ($task in $Changes.Added) {
            $text += "- $($task.Id): $($task.Title) [$($task.Status)]`n"
        }
        
        $text += "`n"
    }
    
    if ($Changes.Removed.Count -gt 0) {
        $text += "Tâches supprimées:`n"
        
        foreach ($task in $Changes.Removed) {
            $text += "- $($task.Id): $($task.Title) [$($task.Status)]`n"
        }
        
        $text += "`n"
    }
    
    if ($Changes.Modified.Count -gt 0) {
        $text += "Tâches modifiées:`n"
        
        foreach ($task in $Changes.Modified) {
            $text += "- $($task.Id): '$($task.OldTitle)' -> '$($task.NewTitle)'`n"
        }
        
        $text += "`n"
    }
    
    if ($Changes.StatusChanged.Count -gt 0) {
        $text += "Statuts changés:`n"
        
        foreach ($task in $Changes.StatusChanged) {
            $text += "- $($task.Id): $($task.Title) [$($task.OldStatus) -> $($task.NewStatus)]`n"
        }
        
        $text += "`n"
    }
    
    return $text
}

# Fonction principale
function Find-Changes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$PreviousVersion,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "Text")]
        [string]$OutputFormat = "JSON",
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeMetadata = $true
    )
    
    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier spécifié n'existe pas: $FilePath" -Level "ERROR"
            return $null
        }
        
        # Lire le contenu du fichier actuel
        $currentContent = Get-Content -Path $FilePath -Raw
        $currentTasks = Get-MarkdownTasks -Content $currentContent
        
        Write-Log "Nombre de tâches dans la version actuelle: $($currentTasks.Count)" -Level "INFO"
        
        # Obtenir la version précédente si non spécifiée
        if (-not $PreviousVersion) {
            $PreviousVersion = Get-PreviousVersion -FilePath $FilePath
            
            if (-not $PreviousVersion) {
                Write-Log "Aucune version précédente trouvée pour le fichier: $FilePath" -Level "WARNING"
                return $null
            }
        }
        
        # Lire le contenu de la version précédente
        $previousContent = Get-Content -Path $PreviousVersion -Raw
        $previousTasks = Get-MarkdownTasks -Content $previousContent
        
        Write-Log "Nombre de tâches dans la version précédente: $($previousTasks.Count)" -Level "INFO"
        
        # Comparer les tâches
        $changes = Compare-TaskSets -OldTasks $previousTasks -NewTasks $currentTasks
        
        # Générer le rapport selon le format demandé
        $report = $null
        
        switch ($OutputFormat) {
            "JSON" {
                $report = $changes | ConvertTo-Json -Depth 5
            }
            "Markdown" {
                $report = ConvertTo-MarkdownReport -Changes $changes -FilePath $FilePath
            }
            "Text" {
                $report = ConvertTo-TextReport -Changes $changes -FilePath $FilePath
            }
        }
        
        # Enregistrer ou afficher le rapport
        if ($OutputPath) {
            $report | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log "Rapport enregistré dans: $OutputPath" -Level "SUCCESS"
        } else {
            return $report
        }
        
        return $changes
    } catch {
        Write-Log "Erreur lors de la détection des modifications: $_" -Level "ERROR"
        throw $_
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Find-Changes -FilePath $FilePath -PreviousVersion $PreviousVersion -OutputPath $OutputPath -OutputFormat $OutputFormat -IncludeMetadata $IncludeMetadata

