<#
.SYNOPSIS
    Fonctions communes pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions communes utilisÃ©es par tous les modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

<#
.SYNOPSIS
    VÃ©rifie si un fichier existe et lÃ¨ve une exception si ce n'est pas le cas.

.DESCRIPTION
    Cette fonction vÃ©rifie si un fichier existe et lÃ¨ve une exception si ce n'est pas le cas.

.PARAMETER FilePath
    Chemin vers le fichier Ã  vÃ©rifier.

.PARAMETER ErrorMessage
    Message d'erreur Ã  afficher si le fichier n'existe pas.

.EXAMPLE
    Assert-FileExists -FilePath "roadmap.md" -ErrorMessage "Le fichier de roadmap est introuvable."

.OUTPUTS
    None
#>
function Assert-FileExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Le fichier est introuvable Ã  l'emplacement : $FilePath"
    )
    
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un rÃ©pertoire existe et le crÃ©e s'il n'existe pas.

.DESCRIPTION
    Cette fonction vÃ©rifie si un rÃ©pertoire existe et le crÃ©e s'il n'existe pas.

.PARAMETER DirectoryPath
    Chemin vers le rÃ©pertoire Ã  vÃ©rifier.

.PARAMETER CreateIfNotExists
    Indique si le rÃ©pertoire doit Ãªtre crÃ©Ã© s'il n'existe pas.

.PARAMETER ErrorMessage
    Message d'erreur Ã  afficher si le rÃ©pertoire n'existe pas et ne doit pas Ãªtre crÃ©Ã©.

.EXAMPLE
    Assert-DirectoryExists -DirectoryPath "output" -CreateIfNotExists $true

.OUTPUTS
    None
#>
function Assert-DirectoryExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,
        
        [Parameter(Mandatory = $false)]
        [bool]$CreateIfNotExists = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Le rÃ©pertoire est introuvable Ã  l'emplacement : $DirectoryPath"
    )
    
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        if ($CreateIfNotExists) {
            New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
        } else {
            throw $ErrorMessage
        }
    }
}

<#
.SYNOPSIS
    CrÃ©e une sauvegarde d'un fichier.

.DESCRIPTION
    Cette fonction crÃ©e une sauvegarde d'un fichier dans un rÃ©pertoire spÃ©cifiÃ©.

.PARAMETER FilePath
    Chemin vers le fichier Ã  sauvegarder.

.PARAMETER BackupPath
    Chemin vers le rÃ©pertoire de sauvegarde.

.PARAMETER Timestamp
    Indique si un horodatage doit Ãªtre ajoutÃ© au nom du fichier de sauvegarde.

.EXAMPLE
    Backup-File -FilePath "roadmap.md" -BackupPath "backup" -Timestamp $true

.OUTPUTS
    System.String
#>
function Backup-File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupPath = "backup",
        
        [Parameter(Mandatory = $false)]
        [bool]$Timestamp = $true
    )
    
    # VÃ©rifier si le fichier existe
    Assert-FileExists -FilePath $FilePath
    
    # CrÃ©er le rÃ©pertoire de sauvegarde s'il n'existe pas
    Assert-DirectoryExists -DirectoryPath $BackupPath -CreateIfNotExists $true
    
    # Obtenir le nom du fichier
    $fileName = Split-Path -Leaf $FilePath
    
    # Ajouter un horodatage si demandÃ©
    if ($Timestamp) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFileName = [System.IO.Path]::GetFileNameWithoutExtension($fileName) + "_" + $timestamp + [System.IO.Path]::GetExtension($fileName)
    } else {
        $backupFileName = $fileName
    }
    
    # Chemin complet du fichier de sauvegarde
    $backupFilePath = Join-Path -Path $BackupPath -ChildPath $backupFileName
    
    # Copier le fichier
    Copy-Item -Path $FilePath -Destination $backupFilePath -Force
    
    return $backupFilePath
}

<#
.SYNOPSIS
    Restaure un fichier Ã  partir d'une sauvegarde.

.DESCRIPTION
    Cette fonction restaure un fichier Ã  partir d'une sauvegarde.

.PARAMETER BackupFilePath
    Chemin vers le fichier de sauvegarde.

.PARAMETER OriginalFilePath
    Chemin vers le fichier original Ã  restaurer.

.EXAMPLE
    Restore-File -BackupFilePath "backup\roadmap_20230815_120000.md" -OriginalFilePath "roadmap.md"

.OUTPUTS
    None
#>
function Restore-File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OriginalFilePath
    )
    
    # VÃ©rifier si le fichier de sauvegarde existe
    Assert-FileExists -FilePath $BackupFilePath -ErrorMessage "Le fichier de sauvegarde est introuvable Ã  l'emplacement : $BackupFilePath"
    
    # Copier le fichier de sauvegarde vers le fichier original
    Copy-Item -Path $BackupFilePath -Destination $OriginalFilePath -Force
}

<#
.SYNOPSIS
    Convertit un fichier Markdown en HTML.

.DESCRIPTION
    Cette fonction convertit un fichier Markdown en HTML.

.PARAMETER MarkdownFile
    Chemin vers le fichier Markdown Ã  convertir.

.PARAMETER HtmlFile
    Chemin vers le fichier HTML de sortie.

.PARAMETER Title
    Titre de la page HTML.

.PARAMETER Css
    Contenu CSS Ã  inclure dans la page HTML.

.EXAMPLE
    Convert-MarkdownToHtml -MarkdownFile "roadmap.md" -HtmlFile "roadmap.html" -Title "Roadmap"

.OUTPUTS
    None
#>
function Convert-MarkdownToHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MarkdownFile,
        
        [Parameter(Mandatory = $true)]
        [string]$HtmlFile,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Markdown to HTML",
        
        [Parameter(Mandatory = $false)]
        [string]$Css = @"
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    color: #333;
}
h1, h2, h3, h4, h5, h6 {
    color: #2c3e50;
    margin-top: 24px;
    margin-bottom: 16px;
}
h1 {
    font-size: 2em;
    border-bottom: 1px solid #eaecef;
    padding-bottom: 0.3em;
}
h2 {
    font-size: 1.5em;
    border-bottom: 1px solid #eaecef;
    padding-bottom: 0.3em;
}
a {
    color: #0366d6;
    text-decoration: none;
}
a:hover {
    text-decoration: underline;
}
pre {
    background-color: #f6f8fa;
    border-radius: 3px;
    padding: 16px;
    overflow: auto;
}
code {
    background-color: #f6f8fa;
    border-radius: 3px;
    padding: 0.2em 0.4em;
    font-family: SFMono-Regular, Consolas, Liberation Mono, Menlo, monospace;
}
table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 16px;
}
table, th, td {
    border: 1px solid #dfe2e5;
}
th, td {
    padding: 6px 13px;
}
tr:nth-child(even) {
    background-color: #f6f8fa;
}
"@
    )
    
    # VÃ©rifier si le fichier Markdown existe
    Assert-FileExists -FilePath $MarkdownFile -ErrorMessage "Le fichier Markdown est introuvable Ã  l'emplacement : $MarkdownFile"
    
    # CrÃ©er le rÃ©pertoire parent du fichier HTML s'il n'existe pas
    $htmlDir = Split-Path -Parent $HtmlFile
    if (-not [string]::IsNullOrEmpty($htmlDir)) {
        Assert-DirectoryExists -DirectoryPath $htmlDir -CreateIfNotExists $true
    }
    
    # Lire le contenu du fichier Markdown
    $markdownContent = Get-Content -Path $MarkdownFile -Raw
    
    # Convertir le Markdown en HTML
    # Note: Cette implÃ©mentation est simplifiÃ©e et ne gÃ¨re pas toutes les fonctionnalitÃ©s de Markdown
    # Pour une conversion complÃ¨te, il faudrait utiliser une bibliothÃ¨que comme Markdig
    
    # Remplacer les titres
    $htmlContent = $markdownContent -replace '# (.*)', '<h1>$1</h1>'
    $htmlContent = $htmlContent -replace '## (.*)', '<h2>$1</h2>'
    $htmlContent = $htmlContent -replace '### (.*)', '<h3>$1</h3>'
    $htmlContent = $htmlContent -replace '#### (.*)', '<h4>$1</h4>'
    $htmlContent = $htmlContent -replace '##### (.*)', '<h5>$1</h5>'
    $htmlContent = $htmlContent -replace '###### (.*)', '<h6>$1</h6>'
    
    # Remplacer les listes
    $htmlContent = $htmlContent -replace '- (.*)', '<li>$1</li>'
    $htmlContent = $htmlContent -replace '\* (.*)', '<li>$1</li>'
    $htmlContent = $htmlContent -replace '\d+\. (.*)', '<li>$1</li>'
    
    # Entourer les listes avec <ul> ou <ol>
    $htmlContent = $htmlContent -replace '(<li>.*?</li>)+', '<ul>$0</ul>'
    
    # Remplacer les liens
    $htmlContent = $htmlContent -replace '\[(.*?)\]\((.*?)\)', '<a href="$2">$1</a>'
    
    # Remplacer les images
    $htmlContent = $htmlContent -replace '!\[(.*?)\]\((.*?)\)', '<img src="$2" alt="$1">'
    
    # Remplacer les blocs de code
    $htmlContent = $htmlContent -replace '```(.*?)```', '<pre><code>$1</code></pre>'
    
    # Remplacer le texte en gras
    $htmlContent = $htmlContent -replace '\*\*(.*?)\*\*', '<strong>$1</strong>'
    
    # Remplacer le texte en italique
    $htmlContent = $htmlContent -replace '\*(.*?)\*', '<em>$1</em>'
    
    # Remplacer les sauts de ligne
    $htmlContent = $htmlContent -replace '\r\n', '<br>'
    
    # CrÃ©er le document HTML complet
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
$Css
    </style>
</head>
<body>
$htmlContent
</body>
</html>
"@
    
    # Ã‰crire le contenu HTML dans le fichier de sortie
    Set-Content -Path $HtmlFile -Value $html -Encoding UTF8
}

<#
.SYNOPSIS
    Extrait les tÃ¢ches d'un fichier de roadmap.

.DESCRIPTION
    Cette fonction extrait les tÃ¢ches d'un fichier de roadmap au format Markdown.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  extraire. Si non spÃ©cifiÃ©, toutes les tÃ¢ches sont extraites.

.EXAMPLE
    $tasks = Get-RoadmapTasks -FilePath "roadmap.md" -TaskIdentifier "1.1"

.OUTPUTS
    System.Collections.ArrayList
#>
function Get-RoadmapTasks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier
    )
    
    # VÃ©rifier si le fichier existe
    Assert-FileExists -FilePath $FilePath -ErrorMessage "Le fichier de roadmap est introuvable Ã  l'emplacement : $FilePath"
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Extraire les tÃ¢ches
    $tasks = New-Object System.Collections.ArrayList
    
    # Expression rÃ©guliÃ¨re pour extraire les tÃ¢ches
    $taskRegex = '- \[([ x])\] \*\*([0-9.]+)\*\* (.*)'
    
    # Parcourir chaque ligne du fichier
    foreach ($line in ($content -split "`r`n")) {
        if ($line -match $taskRegex) {
            $completed = $matches[1] -eq 'x'
            $id = $matches[2]
            $description = $matches[3]
            
            # VÃ©rifier si l'identifiant correspond Ã  celui demandÃ©
            if (-not $TaskIdentifier -or $id -eq $TaskIdentifier -or $id.StartsWith("$TaskIdentifier.")) {
                $task = [PSCustomObject]@{
                    ID = $id
                    Description = $description
                    Completed = $completed
                    Line = $line
                }
                
                [void]$tasks.Add($task)
            }
        }
    }
    
    return $tasks
}

<#
.SYNOPSIS
    Met Ã  jour l'Ã©tat d'une tÃ¢che dans un fichier de roadmap.

.DESCRIPTION
    Cette fonction met Ã  jour l'Ã©tat d'une tÃ¢che dans un fichier de roadmap au format Markdown.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  mettre Ã  jour.

.PARAMETER Completed
    Indique si la tÃ¢che est complÃ©tÃ©e.

.PARAMETER BackupFile
    Indique si une sauvegarde du fichier doit Ãªtre crÃ©Ã©e avant la modification.

.PARAMETER BackupPath
    Chemin vers le rÃ©pertoire de sauvegarde.

.EXAMPLE
    Update-RoadmapTask -FilePath "roadmap.md" -TaskIdentifier "1.1" -Completed $true -BackupFile $true

.OUTPUTS
    None
#>
function Update-RoadmapTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $true)]
        [bool]$Completed,
        
        [Parameter(Mandatory = $false)]
        [bool]$BackupFile = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupPath = "backup"
    )
    
    # VÃ©rifier si le fichier existe
    Assert-FileExists -FilePath $FilePath -ErrorMessage "Le fichier de roadmap est introuvable Ã  l'emplacement : $FilePath"
    
    # CrÃ©er une sauvegarde si demandÃ©
    if ($BackupFile) {
        $backupFilePath = Backup-File -FilePath $FilePath -BackupPath $BackupPath -Timestamp $true
        Write-LogInfo "Sauvegarde crÃ©Ã©e : $backupFilePath"
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath
    
    # Expression rÃ©guliÃ¨re pour identifier la tÃ¢che
    $taskRegex = "- \[([ x])\] \*\*$([regex]::Escape($TaskIdentifier))\*\* (.*)"
    
    # Parcourir chaque ligne du fichier
    $modified = $false
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskRegex) {
            $checkbox = if ($Completed) { "x" } else { " " }
            $description = $matches[3]
            $content[$i] = "- [$checkbox] **$TaskIdentifier** $description"
            $modified = $true
        }
    }
    
    # Ã‰crire le contenu modifiÃ© dans le fichier
    if ($modified) {
        Set-Content -Path $FilePath -Value $content -Encoding UTF8
        Write-LogInfo "TÃ¢che $TaskIdentifier mise Ã  jour : Completed = $Completed"
    } else {
        Write-LogWarning "TÃ¢che $TaskIdentifier non trouvÃ©e dans le fichier $FilePath"
    }
}

<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport sur l'Ã©tat des tÃ¢ches d'un fichier de roadmap.

.DESCRIPTION
    Cette fonction gÃ©nÃ¨re un rapport sur l'Ã©tat des tÃ¢ches d'un fichier de roadmap au format Markdown.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap.

.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie.

.PARAMETER Format
    Format du rapport (Markdown, HTML, JSON, CSV).

.PARAMETER IncludeSubtasks
    Indique si les sous-tÃ¢ches doivent Ãªtre incluses dans le rapport.

.EXAMPLE
    Generate-RoadmapReport -FilePath "roadmap.md" -OutputPath "reports" -Format "HTML" -IncludeSubtasks $true

.OUTPUTS
    System.String
#>
function Generate-RoadmapReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "reports",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Markdown", "HTML", "JSON", "CSV")]
        [string]$Format = "Markdown",
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeSubtasks = $true
    )
    
    # VÃ©rifier si le fichier existe
    Assert-FileExists -FilePath $FilePath -ErrorMessage "Le fichier de roadmap est introuvable Ã  l'emplacement : $FilePath"
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    Assert-DirectoryExists -DirectoryPath $OutputPath -CreateIfNotExists $true
    
    # Extraire les tÃ¢ches
    $tasks = Get-RoadmapTasks -FilePath $FilePath
    
    # Filtrer les sous-tÃ¢ches si demandÃ©
    if (-not $IncludeSubtasks) {
        $tasks = $tasks | Where-Object { $_.ID -notmatch '\.[0-9]+$' }
    }
    
    # Calculer les statistiques
    $totalTasks = $tasks.Count
    $completedTasks = ($tasks | Where-Object { $_.Completed }).Count
    $completionRate = if ($totalTasks -gt 0) { [Math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }
    
    # GÃ©nÃ©rer le rapport selon le format demandÃ©
    $reportFileName = "roadmap_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').$($Format.ToLower())"
    $reportFilePath = Join-Path -Path $OutputPath -ChildPath $reportFileName
    
    switch ($Format) {
        "Markdown" {
            $report = @"
# Rapport de l'Ã©tat de la roadmap

## RÃ©sumÃ©

- **Date du rapport :** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Fichier analysÃ© :** $FilePath
- **Nombre total de tÃ¢ches :** $totalTasks
- **TÃ¢ches complÃ©tÃ©es :** $completedTasks
- **Taux de complÃ©tion :** $completionRate%

## DÃ©tail des tÃ¢ches

| ID | Description | Ã‰tat |
|---|---|---|
"@
            
            foreach ($task in $tasks) {
                $status = if ($task.Completed) { "âœ… ComplÃ©tÃ©e" } else { "â³ En cours" }
                $report += "`n| $($task.ID) | $($task.Description) | $status |"
            }
            
            Set-Content -Path $reportFilePath -Value $report -Encoding UTF8
        }
        "HTML" {
            $report = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de l'Ã©tat de la roadmap</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2 {
            color: #2c3e50;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .completed {
            color: green;
        }
        .in-progress {
            color: orange;
        }
        .progress-bar {
            width: 100%;
            background-color: #f1f1f1;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 5px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Rapport de l'Ã©tat de la roadmap</h1>
    
    <h2>RÃ©sumÃ©</h2>
    <p><strong>Date du rapport :</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <p><strong>Fichier analysÃ© :</strong> $FilePath</p>
    <p><strong>Nombre total de tÃ¢ches :</strong> $totalTasks</p>
    <p><strong>TÃ¢ches complÃ©tÃ©es :</strong> $completedTasks</p>
    <p><strong>Taux de complÃ©tion :</strong> $completionRate%</p>
    
    <div class="progress-bar">
        <div class="progress" style="width: $completionRate%">$completionRate%</div>
    </div>
    
    <h2>DÃ©tail des tÃ¢ches</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>Description</th>
            <th>Ã‰tat</th>
        </tr>
"@
            
            foreach ($task in $tasks) {
                $statusClass = if ($task.Completed) { "completed" } else { "in-progress" }
                $status = if ($task.Completed) { "âœ… ComplÃ©tÃ©e" } else { "â³ En cours" }
                $report += @"
        <tr>
            <td>$($task.ID)</td>
            <td>$($task.Description)</td>
            <td class="$statusClass">$status</td>
        </tr>
"@
            }
            
            $report += @"
    </table>
</body>
</html>
"@
            
            Set-Content -Path $reportFilePath -Value $report -Encoding UTF8
        }
        "JSON" {
            $reportData = [PSCustomObject]@{
                ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                FilePath = $FilePath
                TotalTasks = $totalTasks
                CompletedTasks = $completedTasks
                CompletionRate = $completionRate
                Tasks = $tasks | Select-Object ID, Description, Completed
            }
            
            $reportData | ConvertTo-Json -Depth 10 | Set-Content -Path $reportFilePath -Encoding UTF8
        }
        "CSV" {
            $tasks | Select-Object ID, Description, Completed | Export-Csv -Path $reportFilePath -NoTypeInformation -Encoding UTF8
        }
    }
    
    return $reportFilePath
}

# Exporter les fonctions
Export-ModuleMember -Function Assert-FileExists, Assert-DirectoryExists, Backup-File, Restore-File, Convert-MarkdownToHtml, Get-RoadmapTasks, Update-RoadmapTask, Generate-RoadmapReport
