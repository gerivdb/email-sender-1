<#
.SYNOPSIS
    Script pour synchroniser les roadmaps entre différents formats (Mode ROADMAP-SYNC).

.DESCRIPTION
    Ce script permet de synchroniser les roadmaps entre différents formats (Markdown, JSON, HTML, etc.).
    Il implémente le mode ROADMAP-SYNC qui est conçu pour maintenir la cohérence entre les différentes
    représentations de la roadmap.

.PARAMETER SourcePath
    Chemin vers le fichier de roadmap source. Peut être un chemin unique ou un tableau de chemins.

.PARAMETER TargetPath
    Chemin vers le fichier de roadmap cible. Si non spécifié, le script utilisera les valeurs de la configuration.
    Si SourcePath est un tableau, TargetPath doit également être un tableau de même longueur ou être omis.

.PARAMETER MultiSync
    Indique si plusieurs roadmaps doivent être synchronisées en une seule opération.
    Si ce paramètre est spécifié, SourcePath doit être un tableau de chemins.

.PARAMETER SourceFormat
    Format du fichier source. Valeurs possibles : "Markdown", "JSON", "HTML", "CSV".
    Par défaut : "Markdown".

.PARAMETER TargetFormat
    Format du fichier cible. Valeurs possibles : "Markdown", "JSON", "HTML", "CSV".
    Par défaut : "JSON".

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.
    Par défaut : $false.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json".

.EXAMPLE
    .\roadmap-sync-mode.ps1 -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetPath "projet\roadmaps\Roadmap\roadmap_complete.json"

.EXAMPLE
    .\roadmap-sync-mode.ps1 -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "HTML" -Force

.EXAMPLE
    .\roadmap-sync-mode.ps1 -SourcePath @("projet\roadmaps\Roadmap\roadmap_complete_converted.md", "projet\roadmaps\mes-plans\roadmap_perso.md") -MultiSync -TargetFormat "JSON"

.EXAMPLE
    .\roadmap-sync-mode.ps1 -SourcePath @("projet\roadmaps\Roadmap\roadmap_complete_converted.md", "projet\roadmaps\mes-plans\roadmap_perso.md") -TargetPath @("projet\roadmaps\Roadmap\roadmap_complete.json", "projet\roadmaps\mes-plans\roadmap_perso.json") -MultiSync

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [object]$SourcePath,

    [Parameter(Mandatory = $false, Position = 1)]
    [object]$TargetPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Markdown", "JSON", "HTML", "CSV")]
    [string]$SourceFormat = "Markdown",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Markdown", "JSON", "HTML", "CSV")]
    [string]$TargetFormat = "JSON",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$MultiSync,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json"
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Charger la configuration unifiée
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    Write-Warning "Tentative de recherche d'un fichier de configuration alternatif..."

    # Essayer de trouver un fichier de configuration alternatif
    $alternativePaths = @(
        "development\config\unified-config.json",
        "development\roadmap\parser\config\modes-config.json",
        "development\roadmap\parser\config\config.json"
    )

    foreach ($path in $alternativePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de configuration trouvé à l'emplacement : $fullPath" -ForegroundColor Green
            $configPath = $fullPath
            try {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                break
            } catch {
                Write-Warning "Erreur lors du chargement de la configuration : $_"
            }
        }
    }

    if (-not $config) {
        Write-Error "Aucun fichier de configuration valide trouvé."
        exit 1
    }
}

# Vérifier si le mode MultiSync est activé
if ($MultiSync) {
    # Vérifier que SourcePath est un tableau
    if (-not ($SourcePath -is [array])) {
        Write-Error "Lorsque le paramètre MultiSync est spécifié, SourcePath doit être un tableau de chemins."
        exit 1
    }

    # Vérifier que TargetPath est un tableau de même longueur ou n'est pas spécifié
    if ($TargetPath -and -not ($TargetPath -is [array])) {
        Write-Error "Lorsque le paramètre MultiSync est spécifié et que SourcePath est un tableau, TargetPath doit également être un tableau ou être omis."
        exit 1
    }

    if ($TargetPath -and ($SourcePath.Count -ne $TargetPath.Count)) {
        Write-Error "Les tableaux SourcePath et TargetPath doivent avoir le même nombre d'éléments."
        exit 1
    }

    # Initialiser un tableau pour les chemins cibles
    $targetPaths = @()

    # Traiter chaque chemin source
    for ($i = 0; $i -lt $SourcePath.Count; $i++) {
        $currentSourcePath = $SourcePath[$i]

        # Convertir les chemins relatifs en chemins absolus
        if (-not [System.IO.Path]::IsPathRooted($currentSourcePath)) {
            $currentSourcePath = Join-Path -Path $projectRoot -ChildPath $currentSourcePath
        }

        # Vérifier que le fichier source existe
        if (-not (Test-Path -Path $currentSourcePath)) {
            Write-Error "Le fichier source spécifié n'existe pas : $currentSourcePath"
            exit 1
        }

        # Déterminer le chemin cible si non spécifié
        if ($TargetPath) {
            $currentTargetPath = $TargetPath[$i]

            # Convertir les chemins relatifs en chemins absolus
            if (-not [System.IO.Path]::IsPathRooted($currentTargetPath)) {
                $currentTargetPath = Join-Path -Path $projectRoot -ChildPath $currentTargetPath
            }
        } else {
            $directory = [System.IO.Path]::GetDirectoryName($currentSourcePath)
            $filename = [System.IO.Path]::GetFileNameWithoutExtension($currentSourcePath)

            $extension = switch ($TargetFormat) {
                "Markdown" { ".md" }
                "JSON" { ".json" }
                "HTML" { ".html" }
                "CSV" { ".csv" }
                default { ".json" }
            }

            $currentTargetPath = Join-Path -Path $directory -ChildPath "$filename$extension"
        }

        $targetPaths += $currentTargetPath

        # Mettre à jour les tableaux
        $SourcePath[$i] = $currentSourcePath
    }

    # Mettre à jour TargetPath
    if (-not $TargetPath) {
        $TargetPath = $targetPaths
    }
} else {
    # Mode standard (un seul fichier)

    # Utiliser les valeurs de la configuration si les paramètres ne sont pas spécifiés
    if (-not $SourcePath) {
        if ($config.Roadmaps.Main.Path) {
            $SourcePath = Join-Path -Path $projectRoot -ChildPath $config.Roadmaps.Main.Path
        } elseif ($config.General.RoadmapPath) {
            $SourcePath = Join-Path -Path $projectRoot -ChildPath $config.General.RoadmapPath
        } else {
            Write-Error "Aucun chemin source spécifié et aucun chemin par défaut trouvé dans la configuration."
            exit 1
        }
    }

    # Convertir les chemins relatifs en chemins absolus
    if (-not [System.IO.Path]::IsPathRooted($SourcePath)) {
        $SourcePath = Join-Path -Path $projectRoot -ChildPath $SourcePath
    }

    # Vérifier que le fichier source existe
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Error "Le fichier source spécifié n'existe pas : $SourcePath"
        exit 1
    }

    # Déterminer le format source à partir de l'extension du fichier si non spécifié
    if ($SourceFormat -eq "Markdown" -and -not $SourcePath.EndsWith(".md")) {
        $extension = [System.IO.Path]::GetExtension($SourcePath).ToLower()
        switch ($extension) {
            ".json" { $SourceFormat = "JSON" }
            ".html" { $SourceFormat = "HTML" }
            ".csv" { $SourceFormat = "CSV" }
        }
    }

    # Déterminer le chemin cible si non spécifié
    if (-not $TargetPath) {
        $directory = [System.IO.Path]::GetDirectoryName($SourcePath)
        $filename = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)

        $extension = switch ($TargetFormat) {
            "Markdown" { ".md" }
            "JSON" { ".json" }
            "HTML" { ".html" }
            "CSV" { ".csv" }
            default { ".json" }
        }

        $TargetPath = Join-Path -Path $directory -ChildPath "$filename$extension"
    }

    # Convertir les chemins relatifs en chemins absolus
    if (-not [System.IO.Path]::IsPathRooted($TargetPath)) {
        $TargetPath = Join-Path -Path $projectRoot -ChildPath $TargetPath
    }
}

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\RoadmapParser.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le module RoadmapParser est introuvable : $modulePath"
    exit 1
}

# Afficher les paramètres
Write-Host "Mode ROADMAP-SYNC - Synchronisation des roadmaps" -ForegroundColor Cyan

if ($MultiSync) {
    Write-Host "Mode multi-synchronisation activé" -ForegroundColor Yellow
    Write-Host "Nombre de fichiers à synchroniser : $($SourcePath.Count)" -ForegroundColor Gray

    for ($i = 0; $i -lt $SourcePath.Count; $i++) {
        Write-Host "Fichier source $($i+1) : $($SourcePath[$i]) ($SourceFormat)" -ForegroundColor Gray
        Write-Host "Fichier cible $($i+1) : $($TargetPath[$i]) ($TargetFormat)" -ForegroundColor Gray
    }
} else {
    Write-Host "Fichier source : $SourcePath ($SourceFormat)" -ForegroundColor Gray
    Write-Host "Fichier cible : $TargetPath ($TargetFormat)" -ForegroundColor Gray
}

Write-Host "Mode force : $Force" -ForegroundColor Gray
Write-Host ""

# Fonction pour convertir la roadmap de Markdown vers JSON
function ConvertFrom-MarkdownToJson {
    param (
        [string]$MarkdownPath,
        [string]$JsonPath
    )

    # Lire le contenu du fichier Markdown
    $markdownContent = Get-Content -Path $MarkdownPath -Encoding UTF8 -Raw

    # Analyser le contenu Markdown pour extraire les tâches
    $tasks = @()
    $lines = $markdownContent -split "`n"
    $currentTask = $null
    $currentSubTasks = @()

    foreach ($line in $lines) {
        # Détecter les tâches principales (lignes commençant par "## ")
        if ($line -match "^## (.+)") {
            # Si une tâche est en cours de traitement, l'ajouter à la liste
            if ($currentTask) {
                $currentTask.SubTasks = $currentSubTasks
                $tasks += $currentTask
                $currentSubTasks = @()
            }

            # Créer une nouvelle tâche
            $currentTask = @{
                Title       = $matches[1].Trim()
                Id          = ""
                Description = ""
                Status      = "NotStarted"
                SubTasks    = @()
            }
        }
        # Détecter les descriptions (lignes commençant par "### Description")
        elseif ($line -match "^### Description" -and $currentTask) {
            $descriptionLines = @()
            $i = [array]::IndexOf($lines, $line) + 1

            while ($i -lt $lines.Length -and -not $lines[$i].StartsWith("###")) {
                $descriptionLines += $lines[$i]
                $i++
            }

            $currentTask.Description = ($descriptionLines -join "`n").Trim()
        }
        # Détecter les sous-tâches (lignes commençant par "- [ ]" ou "- [x]")
        elseif ($line -match "^- \[([ x])\] (?:\*\*([0-9.]+)\*\* )?(.+)" -and $currentTask) {
            $isChecked = $matches[1] -eq "x"
            $id = if ($matches[2]) { $matches[2] } else { "" }
            $title = $matches[3].Trim()

            $subTask = @{
                Title  = $title
                Id     = $id
                Status = if ($isChecked) { "Completed" } else { "NotStarted" }
            }

            $currentSubTasks += $subTask
        }
    }

    # Ajouter la dernière tâche
    if ($currentTask) {
        $currentTask.SubTasks = $currentSubTasks
        $tasks += $currentTask
    }

    # Créer l'objet JSON
    $roadmap = @{
        Title       = "Roadmap"
        Description = "Roadmap générée à partir du fichier Markdown"
        LastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Tasks       = $tasks
    }

    # Convertir en JSON et enregistrer
    $json = ConvertTo-Json -InputObject $roadmap -Depth 10
    Set-Content -Path $JsonPath -Value $json -Encoding UTF8

    return $roadmap
}

# Fonction pour convertir la roadmap de JSON vers Markdown
function ConvertFrom-JsonToMarkdown {
    param (
        [string]$JsonPath,
        [string]$MarkdownPath
    )

    # Lire le contenu du fichier JSON
    $jsonContent = Get-Content -Path $JsonPath -Encoding UTF8 -Raw | ConvertFrom-Json

    # Créer le contenu Markdown
    $markdown = "# $($jsonContent.Title)`n`n"

    if ($jsonContent.Description) {
        $markdown += "$($jsonContent.Description)`n`n"
    }

    if ($jsonContent.LastUpdated) {
        $markdown += "Dernière mise à jour : $($jsonContent.LastUpdated)`n`n"
    }

    # Ajouter les tâches
    foreach ($task in $jsonContent.Tasks) {
        $markdown += "## $($task.Title)`n`n"

        if ($task.Description) {
            $markdown += "### Description`n$($task.Description)`n`n"
        }

        if ($task.SubTasks -and $task.SubTasks.Count -gt 0) {
            $markdown += "### Sous-tâches`n"

            foreach ($subTask in $task.SubTasks) {
                $checkbox = if ($subTask.Status -eq "Completed") { "x" } else { " " }
                $id = if ($subTask.Id) { "**$($subTask.Id)** " } else { "" }
                $markdown += "- [$checkbox] $id$($subTask.Title)`n"
            }

            $markdown += "`n"
        }
    }

    # Enregistrer le contenu Markdown
    Set-Content -Path $MarkdownPath -Value $markdown -Encoding UTF8

    return $markdown
}

# Fonction pour convertir la roadmap de Markdown vers HTML
function ConvertFrom-MarkdownToHtml {
    param (
        [string]$MarkdownPath,
        [string]$HtmlPath
    )

    # Vérifier si le module MarkdownPS est installé
    if (-not (Get-Module -ListAvailable -Name MarkdownPS)) {
        Write-Warning "Le module MarkdownPS n'est pas installé. Installation en cours..."
        Install-Module -Name MarkdownPS -Force -Scope CurrentUser
    }

    # Importer le module MarkdownPS
    Import-Module MarkdownPS

    # Lire le contenu du fichier Markdown
    $markdownContent = Get-Content -Path $MarkdownPath -Encoding UTF8 -Raw

    # Convertir le Markdown en HTML
    $html = ConvertFrom-Markdown -Markdown $markdownContent -AsHTML

    # Ajouter des styles CSS
    $htmlWithStyles = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Roadmap</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #2980b9;
            margin-top: 30px;
        }
        h3 {
            color: #3498db;
            margin-top: 20px;
        }
        ul {
            list-style-type: none;
            padding-left: 20px;
        }
        li {
            margin-bottom: 5px;
        }
        .completed {
            text-decoration: line-through;
            color: #7f8c8d;
        }
        .task-id {
            font-weight: bold;
            color: #e74c3c;
        }
        .last-updated {
            font-style: italic;
            color: #7f8c8d;
            margin-bottom: 30px;
        }
    </style>
</head>
<body>
$html
</body>
</html>
"@

    # Remplacer les cases à cocher Markdown par des cases à cocher HTML
    $htmlWithStyles = $htmlWithStyles -replace '<li>\[ \]', '<li><input type="checkbox" disabled>'
    $htmlWithStyles = $htmlWithStyles -replace '<li>\[x\]', '<li><input type="checkbox" checked disabled>'

    # Enregistrer le contenu HTML
    Set-Content -Path $HtmlPath -Value $htmlWithStyles -Encoding UTF8

    return $htmlWithStyles
}

# Fonction pour convertir la roadmap de Markdown vers CSV
function ConvertFrom-MarkdownToCsv {
    param (
        [string]$MarkdownPath,
        [string]$CsvPath
    )

    # Lire le contenu du fichier Markdown
    $markdownContent = Get-Content -Path $MarkdownPath -Encoding UTF8 -Raw

    # Analyser le contenu Markdown pour extraire les tâches
    $tasks = @()
    $lines = $markdownContent -split "`n"
    $currentTaskTitle = ""
    $currentTaskDescription = ""

    foreach ($line in $lines) {
        # Détecter les tâches principales (lignes commençant par "## ")
        if ($line -match "^## (.+)") {
            $currentTaskTitle = $matches[1].Trim()
            $currentTaskDescription = ""
        }
        # Détecter les descriptions (lignes commençant par "### Description")
        elseif ($line -match "^### Description" -and $currentTaskTitle) {
            $descriptionLines = @()
            $i = [array]::IndexOf($lines, $line) + 1

            while ($i -lt $lines.Length -and -not $lines[$i].StartsWith("###")) {
                $descriptionLines += $lines[$i]
                $i++
            }

            $currentTaskDescription = ($descriptionLines -join " ").Trim()
        }
        # Détecter les sous-tâches (lignes commençant par "- [ ]" ou "- [x]")
        elseif ($line -match "^- \[([ x])\] (?:\*\*([0-9.]+)\*\* )?(.+)" -and $currentTaskTitle) {
            $isChecked = $matches[1] -eq "x"
            $id = if ($matches[2]) { $matches[2] } else { "" }
            $title = $matches[3].Trim()

            $task = [PSCustomObject]@{
                TaskGroup       = $currentTaskTitle
                TaskDescription = $currentTaskDescription
                SubTaskId       = $id
                SubTaskTitle    = $title
                Status          = if ($isChecked) { "Completed" } else { "NotStarted" }
            }

            $tasks += $task
        }
    }

    # Exporter vers CSV
    $tasks | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

    return $tasks
}

# Fonction pour convertir la roadmap de JSON vers HTML
function ConvertFrom-JsonToHtml {
    param (
        [string]$JsonPath,
        [string]$HtmlPath
    )

    # Convertir d'abord de JSON vers Markdown
    $tempMarkdownPath = [System.IO.Path]::GetTempFileName() + ".md"
    ConvertFrom-JsonToMarkdown -JsonPath $JsonPath -MarkdownPath $tempMarkdownPath

    # Puis de Markdown vers HTML
    ConvertFrom-MarkdownToHtml -MarkdownPath $tempMarkdownPath -HtmlPath $HtmlPath

    # Supprimer le fichier temporaire
    Remove-Item -Path $tempMarkdownPath -Force
}

# Fonction pour convertir la roadmap de JSON vers CSV
function ConvertFrom-JsonToCsv {
    param (
        [string]$JsonPath,
        [string]$CsvPath
    )

    # Convertir d'abord de JSON vers Markdown
    $tempMarkdownPath = [System.IO.Path]::GetTempFileName() + ".md"
    ConvertFrom-JsonToMarkdown -JsonPath $JsonPath -MarkdownPath $tempMarkdownPath

    # Puis de Markdown vers CSV
    ConvertFrom-MarkdownToCsv -MarkdownPath $tempMarkdownPath -CsvPath $CsvPath

    # Supprimer le fichier temporaire
    Remove-Item -Path $tempMarkdownPath -Force
}

# Fonction pour convertir la roadmap de HTML vers Markdown
function ConvertFrom-HtmlToMarkdown {
    param (
        [string]$HtmlPath,
        [string]$MarkdownPath
    )

    # Vérifier si le module PSParseHTML est installé
    if (-not (Get-Module -ListAvailable -Name PSParseHTML)) {
        Write-Warning "Le module PSParseHTML n'est pas installé. Installation en cours..."
        Install-Module -Name PSParseHTML -Force -Scope CurrentUser
    }

    # Importer le module PSParseHTML
    Import-Module PSParseHTML

    # Lire le contenu du fichier HTML
    $htmlContent = Get-Content -Path $HtmlPath -Encoding UTF8 -Raw

    # Convertir le HTML en Markdown
    $markdown = ConvertFrom-HTML -HTML $htmlContent -Format Markdown

    # Enregistrer le contenu Markdown
    Set-Content -Path $MarkdownPath -Value $markdown -Encoding UTF8

    return $markdown
}

# Fonction pour convertir la roadmap de CSV vers Markdown
function ConvertFrom-CsvToMarkdown {
    param (
        [string]$CsvPath,
        [string]$MarkdownPath
    )

    # Lire le contenu du fichier CSV
    $csvContent = Import-Csv -Path $CsvPath -Encoding UTF8

    # Créer le contenu Markdown
    $markdown = "# Roadmap`n`n"
    $markdown += "Dernière mise à jour : $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")`n`n"

    # Regrouper les tâches par groupe
    $taskGroups = $csvContent | Group-Object -Property TaskGroup

    foreach ($group in $taskGroups) {
        $markdown += "## $($group.Name)`n`n"

        # Ajouter la description (prendre la première, car elles devraient toutes être identiques)
        $description = ($group.Group | Select-Object -First 1).TaskDescription
        if ($description) {
            $markdown += "### Description`n$description`n`n"
        }

        # Ajouter les sous-tâches
        $markdown += "### Sous-tâches`n"

        foreach ($task in $group.Group) {
            $checkbox = if ($task.Status -eq "Completed") { "x" } else { " " }
            $id = if ($task.SubTaskId) { "**$($task.SubTaskId)** " } else { "" }
            $markdown += "- [$checkbox] $id$($task.SubTaskTitle)`n"
        }

        $markdown += "`n"
    }

    # Enregistrer le contenu Markdown
    Set-Content -Path $MarkdownPath -Value $markdown -Encoding UTF8

    return $markdown
}

# Fonction pour convertir la roadmap de CSV vers JSON
function ConvertFrom-CsvToJson {
    param (
        [string]$CsvPath,
        [string]$JsonPath
    )

    # Convertir d'abord de CSV vers Markdown
    $tempMarkdownPath = [System.IO.Path]::GetTempFileName() + ".md"
    ConvertFrom-CsvToMarkdown -CsvPath $CsvPath -MarkdownPath $tempMarkdownPath

    # Puis de Markdown vers JSON
    ConvertFrom-MarkdownToJson -MarkdownPath $tempMarkdownPath -JsonPath $JsonPath

    # Supprimer le fichier temporaire
    Remove-Item -Path $tempMarkdownPath -Force
}

# Fonction pour convertir la roadmap de HTML vers JSON
function ConvertFrom-HtmlToJson {
    param (
        [string]$HtmlPath,
        [string]$JsonPath
    )

    # Convertir d'abord de HTML vers Markdown
    $tempMarkdownPath = [System.IO.Path]::GetTempFileName() + ".md"
    ConvertFrom-HtmlToMarkdown -HtmlPath $HtmlPath -MarkdownPath $tempMarkdownPath

    # Puis de Markdown vers JSON
    ConvertFrom-MarkdownToJson -MarkdownPath $tempMarkdownPath -JsonPath $JsonPath

    # Supprimer le fichier temporaire
    Remove-Item -Path $tempMarkdownPath -Force
}

# Fonction pour effectuer la conversion d'un fichier
function Convert-RoadmapFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$SourceFormat,
        [string]$TargetFormat,
        [switch]$Force
    )

    # Vérifier si le fichier cible existe déjà
    if (Test-Path -Path $TargetPath) {
        if (-not $Force) {
            $confirmation = Read-Host "Le fichier cible existe déjà ($TargetPath). Voulez-vous le remplacer ? (O/N)"
            if ($confirmation -ne "O" -and $confirmation -ne "o") {
                Write-Host "Opération annulée pour $TargetPath." -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "Le fichier cible existe déjà et sera remplacé (mode force activé) : $TargetPath" -ForegroundColor Yellow
        }
    }

    # Effectuer la conversion en fonction des formats source et cible
    $conversionFunction = switch ($SourceFormat) {
        "Markdown" {
            switch ($TargetFormat) {
                "JSON" { "ConvertFrom-MarkdownToJson" }
                "HTML" { "ConvertFrom-MarkdownToHtml" }
                "CSV" { "ConvertFrom-MarkdownToCsv" }
                default { "ConvertFrom-MarkdownToJson" }
            }
        }
        "JSON" {
            switch ($TargetFormat) {
                "Markdown" { "ConvertFrom-JsonToMarkdown" }
                "HTML" { "ConvertFrom-JsonToHtml" }
                "CSV" { "ConvertFrom-JsonToCsv" }
                default { "ConvertFrom-JsonToMarkdown" }
            }
        }
        "HTML" {
            switch ($TargetFormat) {
                "Markdown" { "ConvertFrom-HtmlToMarkdown" }
                "JSON" { "ConvertFrom-HtmlToJson" }
                "CSV" { "ConvertFrom-HtmlToMarkdown" }
                default { "ConvertFrom-HtmlToMarkdown" }
            }
        }
        "CSV" {
            switch ($TargetFormat) {
                "Markdown" { "ConvertFrom-CsvToMarkdown" }
                "JSON" { "ConvertFrom-CsvToJson" }
                "HTML" { "ConvertFrom-CsvToMarkdown" }
                default { "ConvertFrom-CsvToMarkdown" }
            }
        }
        default { "ConvertFrom-MarkdownToJson" }
    }

    # Exécuter la conversion
    if ($PSCmdlet.ShouldProcess($TargetPath, "Convertir de $SourceFormat vers $TargetFormat")) {
        try {
            & $conversionFunction -MarkdownPath $SourcePath -JsonPath $TargetPath
            Write-Host "Conversion réussie : $SourcePath ($SourceFormat) -> $TargetPath ($TargetFormat)" -ForegroundColor Green
            return $true
        } catch {
            Write-Error "Erreur lors de la conversion : $_"
            return $false
        }
    }

    return $false
}

# Effectuer les conversions
$results = @()

if ($MultiSync) {
    # Mode multi-synchronisation
    for ($i = 0; $i -lt $SourcePath.Count; $i++) {
        $currentSourcePath = $SourcePath[$i]
        $currentTargetPath = $TargetPath[$i]

        Write-Host "`nTraitement du fichier $($i+1)/$($SourcePath.Count) : $currentSourcePath -> $currentTargetPath" -ForegroundColor Cyan

        $success = Convert-RoadmapFile -SourcePath $currentSourcePath -TargetPath $currentTargetPath -SourceFormat $SourceFormat -TargetFormat $TargetFormat -Force:$Force

        $results += @{
            SourcePath   = $currentSourcePath
            TargetPath   = $currentTargetPath
            SourceFormat = $SourceFormat
            TargetFormat = $TargetFormat
            Success      = $success
        }
    }
} else {
    # Mode standard (un seul fichier)
    $success = Convert-RoadmapFile -SourcePath $SourcePath -TargetPath $TargetPath -SourceFormat $SourceFormat -TargetFormat $TargetFormat -Force:$Force

    $results += @{
        SourcePath   = $SourcePath
        TargetPath   = $TargetPath
        SourceFormat = $SourceFormat
        TargetFormat = $TargetFormat
        Success      = $success
    }
}

# Afficher un message de fin
Write-Host "`nExécution du mode ROADMAP-SYNC terminée." -ForegroundColor Cyan

# Afficher un résumé des résultats
$successCount = ($results | Where-Object { $_.Success -eq $true }).Count
$failureCount = ($results | Where-Object { $_.Success -eq $false }).Count
$totalCount = $results.Count

Write-Host "Résumé des conversions :" -ForegroundColor Yellow
Write-Host "  - Total : $totalCount" -ForegroundColor Gray
Write-Host "  - Réussies : $successCount" -ForegroundColor Green
Write-Host "  - Échouées : $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Gray" })

# Retourner un résultat
if ($MultiSync) {
    return @{
        MultiSync    = $true
        Results      = $results
        SourceFormat = $SourceFormat
        TargetFormat = $TargetFormat
        SuccessCount = $successCount
        FailureCount = $failureCount
        TotalCount   = $totalCount
        Success      = ($failureCount -eq 0)
    }
} else {
    return @{
        MultiSync    = $false
        SourcePath   = $SourcePath
        SourceFormat = $SourceFormat
        TargetPath   = $TargetPath
        TargetFormat = $TargetFormat
        Success      = $results[0].Success
    }
}
