# Search-TasksByTags.ps1
# Script pour rechercher des tâches par tags via Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Query = "Tâches importantes",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tags",

    [Parameter(Mandatory = $false)]
    [int]$Limit = 10,

    [Parameter(Mandatory = $false)]
    [float]$ScoreThreshold = 0.7,

    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "Table",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeTaskContent
)

# Importer les modules nécessaires
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "utils"

# Importer les modules
. (Join-Path -Path $utilsDir -ChildPath "Write-Log.ps1")
. (Join-Path -Path $utilsDir -ChildPath "Get-OpenRouterEmbeddings.ps1")

# Fonction pour vérifier si une collection existe dans Qdrant
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

        foreach ($collection in $collections) {
            if ($collection.name -eq $CollectionName) {
                return $true
            }
        }

        return $false
    } catch {
        Write-Log "Erreur lors de la vérification de la collection Qdrant: $_" -Level Error
        return $false
    }
}

# Fonction pour rechercher dans Qdrant
function Search-Qdrant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [float[]]$Vector,

        [Parameter(Mandatory = $false)]
        [int]$Limit = 10,

        [Parameter(Mandatory = $false)]
        [float]$ScoreThreshold = 0.7
    )

    $body = @{
        vector          = $Vector
        limit           = $Limit
        with_payload    = $true
        with_vectors    = $false
        score_threshold = $ScoreThreshold
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points/search" -Method Post -Body $body -ContentType "application/json"
        return $response.result
    } catch {
        Write-Log "Erreur lors de la recherche dans Qdrant: $_" -Level Error
        return $null
    }
}

# Fonction pour formater les résultats
function Format-SearchResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,

        [Parameter(Mandatory = $false)]
        [string]$Format = "Table",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTaskContent
    )

    # Créer un tableau pour stocker les résultats formatés
    $formattedResults = @()

    foreach ($result in $Results) {
        $score = [math]::Round($result.score, 4)
        $payload = $result.payload

        $formattedResult = [PSCustomObject]@{
            Score    = $score
            TaskId   = $payload.task_id
            TagType  = $payload.tag_type
            TagName  = $payload.tag_name
            TagValue = $payload.tag_value
            TagUnit  = $payload.tag_unit
            FileName = $payload.file_name
            FilePath = $payload.file_path
        }

        if ($IncludeTaskContent) {
            $formattedResult | Add-Member -MemberType NoteProperty -Name "TaskText" -Value $payload.task_text
        }

        $formattedResults += $formattedResult
    }

    # Afficher ou enregistrer les résultats selon le format spécifié
    switch ($Format) {
        "Table" {
            if ($OutputPath) {
                $formattedResults | Format-Table -AutoSize | Out-File -FilePath $OutputPath
                Write-Log "Résultats enregistrés dans $OutputPath" -Level Success
            } else {
                $formattedResults | Format-Table -AutoSize
            }
        }
        "List" {
            if ($OutputPath) {
                $formattedResults | Format-List | Out-File -FilePath $OutputPath
                Write-Log "Résultats enregistrés dans $OutputPath" -Level Success
            } else {
                $formattedResults | Format-List
            }
        }
        "CSV" {
            if ($OutputPath) {
                $formattedResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                Write-Log "Résultats enregistrés dans $OutputPath" -Level Success
            } else {
                $formattedResults | ConvertTo-Csv -NoTypeInformation
            }
        }
        "JSON" {
            if ($OutputPath) {
                $formattedResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Log "Résultats enregistrés dans $OutputPath" -Level Success
            } else {
                $formattedResults | ConvertTo-Json -Depth 10
            }
        }
        default {
            if ($OutputPath) {
                $formattedResults | Format-Table -AutoSize | Out-File -FilePath $OutputPath
                Write-Log "Résultats enregistrés dans $OutputPath" -Level Success
            } else {
                $formattedResults | Format-Table -AutoSize
            }
        }
    }

    return $formattedResults
}

# Fonction pour ouvrir un fichier à une position spécifique
function Open-FileAtPosition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TaskId
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Log "Le fichier n'existe pas: $FilePath" -Level Error
        return $false
    }

    # Ouvrir le fichier dans l'éditeur par défaut
    if ([string]::IsNullOrEmpty($TaskId)) {
        # Ouvrir le fichier sans position spécifique
        Start-Process $FilePath
    } else {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # Rechercher la position de la tâche
        $taskPattern = "\*\*$([regex]::Escape($TaskId))\*\*"
        $match = [regex]::Match($content, $taskPattern)

        if ($match.Success) {
            # Calculer le numéro de ligne
            $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Length

            # Ouvrir le fichier à la ligne spécifiée (dépend de l'éditeur)
            # Pour VS Code
            Start-Process "code" -ArgumentList "--goto `"$FilePath`:$lineNumber`""
        } else {
            # Ouvrir le fichier sans position spécifique
            Start-Process $FilePath
        }
    }

    return $true
}

# Fonction principale
function Main {
    # Vérifier si la collection existe
    if (-not (Test-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName)) {
        Write-Log "La collection $CollectionName n'existe pas dans Qdrant. Exécutez d'abord Index-TagsInQdrant.ps1." -Level Error
        return $false
    }

    # Générer l'embedding pour la requête
    Write-Log "Génération de l'embedding pour la requête: $Query" -Level Info
    $embedding = Get-OpenRouterEmbeddings -Text $Query -TestMode

    # Obtenir la dimension des vecteurs dans la collection
    try {
        $collectionInfo = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Get
        $vectorDimension = $collectionInfo.result.config.params.vectors.size

        # Redimensionner l'embedding à la dimension spécifiée
        if ($embedding.Count -ne $vectorDimension) {
            Write-Log "Redimensionnement de l'embedding de $($embedding.Count) à $vectorDimension dimensions" -Level Warning

            if ($embedding.Count -gt $vectorDimension) {
                # Tronquer l'embedding
                $embedding = $embedding[0..($vectorDimension - 1)]
            } else {
                # Étendre l'embedding avec des zéros
                $embedding = $embedding + (New-Object float[] ($vectorDimension - $embedding.Count))
            }
        }
    } catch {
        Write-Log "Erreur lors de la récupération des informations de la collection: $_" -Level Warning
    }

    if (-not $embedding) {
        Write-Log "Impossible de générer l'embedding pour la requête" -Level Error
        return $false
    }

    # Rechercher dans Qdrant
    Write-Log "Recherche dans Qdrant..." -Level Info
    $results = Search-Qdrant -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Vector $embedding -Limit $Limit -ScoreThreshold $ScoreThreshold

    if (-not $results -or $results.Count -eq 0) {
        Write-Log "Aucun résultat trouvé pour la requête: $Query" -Level Warning
        return $false
    }

    Write-Log "Nombre de résultats trouvés: $($results.Count)" -Level Success

    # Formater et afficher les résultats
    $formattedResults = Format-SearchResults -Results $results -Format $OutputFormat -OutputPath $OutputPath -IncludeTaskContent:$IncludeTaskContent

    # Demander à l'utilisateur s'il souhaite ouvrir un fichier
    $openFile = Read-Host "Souhaitez-vous ouvrir un fichier ? (O/N)"

    if ($openFile -eq "O" -or $openFile -eq "o") {
        # Afficher la liste des fichiers disponibles
        $fileList = $formattedResults | Select-Object -Property FileName, FilePath, TaskId -Unique

        for ($i = 0; $i -lt $fileList.Count; $i++) {
            Write-Host "$($i+1). $($fileList[$i].FileName) - Tâche: $($fileList[$i].TaskId)"
        }

        # Demander à l'utilisateur quel fichier ouvrir
        $fileIndex = Read-Host "Entrez le numéro du fichier à ouvrir (1-$($fileList.Count))"

        if ($fileIndex -match '^\d+$' -and [int]$fileIndex -ge 1 -and [int]$fileIndex -le $fileList.Count) {
            $selectedFile = $fileList[[int]$fileIndex - 1]
            Open-FileAtPosition -FilePath $selectedFile.FilePath -TaskId $selectedFile.TaskId
        } else {
            Write-Log "Numéro de fichier invalide" -Level Warning
        }
    }

    return $true
}

# Exécuter la fonction principale
Main
