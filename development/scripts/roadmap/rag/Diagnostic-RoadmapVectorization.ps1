﻿﻿# Diagnostic-RoadmapVectorization.ps1
# Script pour diagnostiquer les problèmes de vectorisation des tâches de roadmap dans Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapDir = "projet\roadmaps\plans\consolidated",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter(Mandatory = $false)]
    [switch]$CreateCollection,

    [Parameter(Mandatory = $false)]
    [switch]$FixEncoding,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "..\utils\Common-Utils.ps1"

if (Test-Path -Path $utilsPath) {
    . $utilsPath
} else {
    Write-Error "Le fichier d'utilitaires communs est introuvable: $utilsPath"
    exit 1
}

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour analyser un fichier Markdown et extraire les tâches
function Get-MarkdownTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Extraire les tâches avec regex
        $taskPattern = '- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'
        $matches = [regex]::Matches($content, $taskPattern)

        $tasks = @()
        foreach ($match in $matches) {
            $status = $match.Groups[1].Value
            $taskId = $match.Groups[2].Value
            $description = $match.Groups[3].Value.Trim()

            # Déterminer le niveau d'indentation
            $indentLevel = ($taskId -split '\.').Count

            # Déterminer l'ID parent
            $parentId = if ($indentLevel -gt 1) {
                $parts = $taskId -split '\.'
                $parts[0..($parts.Count - 2)] -join '.'
            } else {
                ""
            }

            # Extraire la section (en cherchant le dernier titre avant la tâche)
            $sectionPattern = '##\s+(.*?)(?:\r?\n)'
            $sections = [regex]::Matches($content, $sectionPattern)
            $section = "Non spécifié"

            foreach ($sec in $sections) {
                if ($sec.Index -lt $match.Index) {
                    $section = $sec.Groups[1].Value.Trim()
                } else {
                    break
                }
            }

            # Extraire les métadonnées supplémentaires (MVP, priorité, etc.)
            $isMVP = $description -match '\bMVP\b'
            $priorityMatch = [regex]::Match($description, '\b(P[0-3])\b')
            $priority = if ($priorityMatch.Success) { $priorityMatch.Groups[1].Value } else { "P3" }

            $tasks += [PSCustomObject]@{
                TaskId      = $taskId
                Description = $description
                Status      = if ($status -match '[xX]') { "completed" } else { "pending" }
                IndentLevel = $indentLevel
                ParentId    = $parentId
                Section     = $section
                FilePath    = $FilePath
                IsMVP       = $isMVP
                Priority    = $priority
            }
        }

        return $tasks
    } catch {
        Write-Log "Erreur lors de l'analyse du fichier $FilePath : $_" -Level Error
        return @()
    }
}

# Fonction pour vérifier l'état de Qdrant
function Test-QdrantConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        return $true
    } catch {
        Write-Log "Erreur de connexion à Qdrant: $_" -Level Error
        return $false
    }
}

# Fonction pour vérifier si une collection existe
function Test-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        $collections = $response.result.collections
        return $collections | Where-Object { $_.name -eq $CollectionName }
    } catch {
        Write-Log "Erreur lors de la vérification de la collection: $_" -Level Error
        return $null
    }
}

# Fonction pour créer une collection Qdrant
function New-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $false)]
        [int]$VectorSize = 1536
    )

    try {
        $body = @{
            vectors = @{
                size     = $VectorSize
                distance = "Cosine"
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Put -Body $body -ContentType "application/json"
        return $response.result
    } catch {
        Write-Log "Erreur lors de la création de la collection: $_" -Level Error
        return $null
    }
}

# Fonction pour compter les points dans une collection
function Get-QdrantCollectionCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Get
        return $response.result.vectors_count
    } catch {
        Write-Log "Erreur lors du comptage des points: $_" -Level Error
        return 0
    }
}

# Fonction principale
function Start-Diagnostic {
    [CmdletBinding()]
    param()

    # Vérifier la connexion à Qdrant
    Write-Log "Vérification de la connexion à Qdrant..." -Level Info
    $connected = Test-QdrantConnection -QdrantUrl $QdrantUrl

    if (-not $connected) {
        Write-Log "Impossible de se connecter à Qdrant. Vérifiez que le conteneur est en cours d'exécution." -Level Error
        return
    }

    Write-Log "Connexion à Qdrant établie." -Level Success

    # Vérifier l'existence de la collection
    Write-Log "Vérification de l'existence de la collection $CollectionName..." -Level Info
    $collection = Test-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    if ($null -eq $collection) {
        if ($CreateCollection) {
            Write-Log "Création de la collection $CollectionName..." -Level Info
            $result = New-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName

            if ($null -eq $result) {
                Write-Log "Échec de la création de la collection." -Level Error
                return
            }

            Write-Log "Collection $CollectionName créée avec succès." -Level Success
        } else {
            Write-Log "La collection $CollectionName n'existe pas. Utilisez le paramètre -CreateCollection pour la créer." -Level Warning

            # Lister les collections existantes
            $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
            $collections = $response.result.collections

            Write-Log "Collections existantes:" -Level Info
            foreach ($coll in $collections) {
                Write-Log "- $($coll.name)" -Level Info
            }

            return
        }
    } else {
        Write-Log "Collection $CollectionName trouvée." -Level Success
        $vectorCount = Get-QdrantCollectionCount -QdrantUrl $QdrantUrl -CollectionName $CollectionName
        Write-Log "Nombre de vecteurs dans la collection: $vectorCount" -Level Info
    }

    # Analyser les fichiers Markdown
    Write-Log "Analyse des fichiers Markdown dans $RoadmapDir..." -Level Info
    $files = Get-ChildItem -Path $RoadmapDir -Filter "*.md" -Recurse

    if ($files.Count -eq 0) {
        Write-Log "Aucun fichier Markdown trouvé dans $RoadmapDir" -Level Warning
        return
    }

    Write-Log "Nombre de fichiers Markdown trouvés: $($files.Count)" -Level Info

    $allTasks = @()
    foreach ($file in $files) {
        Write-Log "Analyse du fichier $($file.Name)..." -Level Info
        $tasks = Get-MarkdownTasks -FilePath $file.FullName
        Write-Log "  - $($tasks.Count) tâches trouvées" -Level Info
        $allTasks += $tasks
    }

    Write-Log "Nombre total de tâches trouvées: $($allTasks.Count)" -Level Info

    # Comparer avec le nombre de vecteurs dans Qdrant
    $vectorCount = Get-QdrantCollectionCount -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    if ($vectorCount -eq 0) {
        Write-Log "Aucun vecteur trouvé dans la collection $CollectionName" -Level Warning
        Write-Log "La vectorisation n'a pas été effectuée ou a échoué." -Level Warning
    } elseif ($vectorCount -lt $allTasks.Count) {
        $percentage = [math]::Round(($vectorCount / $allTasks.Count) * 100, 2)
        Write-Log "Vectorisation incomplète: $vectorCount/$($allTasks.Count) tâches vectorisées ($percentage%)" -Level Warning
    } elseif ($vectorCount -eq $allTasks.Count) {
        Write-Log "Vectorisation complète: toutes les tâches sont vectorisées." -Level Success
    } else {
        Write-Log "Plus de vecteurs que de tâches: $vectorCount vecteurs pour $($allTasks.Count) tâches" -Level Warning
        Write-Log "Cela peut indiquer des doublons ou des tâches obsolètes dans la collection." -Level Warning
    }

    # Générer un rapport détaillé
    $reportPath = "projet\roadmaps\analysis\vectorization_report.md"
    $reportDir = Split-Path -Parent $reportPath

    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }

    $report = @"
# Rapport de diagnostic de vectorisation
*Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## Résumé

- **Nombre total de fichiers Markdown**: $($files.Count)
- **Nombre total de tâches**: $($allTasks.Count)
- **Nombre de vecteurs dans Qdrant**: $vectorCount
- **Taux de vectorisation**: $([math]::Round(($vectorCount / $allTasks.Count) * 100, 2))%

## Détails par fichier

| Fichier | Nombre de tâches | Tâches MVP | Tâches P0 | Tâches P1 | Tâches P2 | Tâches P3 |
|---------|-----------------|------------|-----------|-----------|-----------|-----------|
"@

    foreach ($file in $files) {
        $fileTasks = $allTasks | Where-Object { $_.FilePath -eq $file.FullName }
        $mvpCount = ($fileTasks | Where-Object { $_.IsMVP }).Count
        $p0Count = ($fileTasks | Where-Object { $_.Priority -eq "P0" }).Count
        $p1Count = ($fileTasks | Where-Object { $_.Priority -eq "P1" }).Count
        $p2Count = ($fileTasks | Where-Object { $_.Priority -eq "P2" }).Count
        $p3Count = ($fileTasks | Where-Object { $_.Priority -eq "P3" }).Count

        $report += "`n| $($file.Name) | $($fileTasks.Count) | $mvpCount | $p0Count | $p1Count | $p2Count | $p3Count |"
    }

    $report | Set-Content -Path $reportPath -Encoding UTF8
    Write-Log "Rapport de diagnostic généré: $reportPath" -Level Success
}

# Exécuter le diagnostic
Start-Diagnostic
