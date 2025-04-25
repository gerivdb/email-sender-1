#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion centralisée de l'inventaire des scripts
.DESCRIPTION
    Ce module permet de scanner, inventorier, classifier et gérer les scripts du projet
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>

using namespace System.Collections.Generic
using namespace System.IO

#region Classes

class ScriptMetadata {
    [string]$FileName
    [string]$FullPath
    [string]$Language
    [string]$Author = ""
    [string]$Version = ""
    [string]$Description = ""
    [string[]]$Tags = @()
    [string]$Category = "Non classé"
    [string]$SubCategory = "Autre"
    [datetime]$LastModified
    [int]$LineCount
    [string]$Hash
    [bool]$IsDuplicate = $false
    [string]$DuplicateOf = ""
    [int]$SimilarityScore = 0
}

class ScriptInventory {
    static [string]$InventoryPath = "data/script_inventory.json"
    static [List[ScriptMetadata]]$Scripts = [List[ScriptMetadata]]::new()

    # Scan un répertoire et ses sous-répertoires pour trouver des scripts
    static [void] ScanDirectory([string]$path, [string[]]$extensions, [string[]]$excludeFolders) {
        if (-not $extensions) {
            $extensions = @('.ps1', '.psm1', '.py', '.cmd', '.bat', '.sh')
        }

        if (-not $excludeFolders) {
            $excludeFolders = @('node_modules', '.git', '.vscode', 'bin', 'obj')
        }

        Write-Verbose "Scanning directory: $path"

        # Créer le répertoire de données si nécessaire
        $dataDir = Join-Path -Path $PWD.Path -ChildPath "data"
        [ScriptInventory]::InventoryPath = Join-Path -Path $dataDir -ChildPath "script_inventory.json"
        if (-not (Test-Path -Path $dataDir)) {
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        }

        # Vider la liste des scripts
        [ScriptInventory]::Scripts.Clear()

        # Récupérer tous les fichiers avec les extensions spécifiées
        $files = Get-ChildItem -Path $path -Recurse -File |
            Where-Object {
                $extensions -contains $_.Extension -and
                -not ($_.FullName -split '\\' | Where-Object { $excludeFolders -contains $_ })
            }

        $totalFiles = $files.Count
        $processedFiles = 0

        foreach ($file in $files) {
            $processedFiles++
            $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100, 2)

            Write-Progress -Activity "Scanning scripts" -Status "Processing file $processedFiles/$totalFiles ($percentComplete%)" -PercentComplete $percentComplete

            $metadata = [ScriptMetadata]@{
                FileName     = $file.Name
                FullPath     = $file.FullName
                Language     = [ScriptInventory]::DetermineLanguage($file.Extension)
                LastModified = $file.LastWriteTime
                LineCount    = (Get-Content $file.FullName -ErrorAction SilentlyContinue).Count
                Hash         = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
            }

            # Extraction des métadonnées depuis le contenu du fichier
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $metadata = [ScriptInventory]::ExtractMetadata($content, $metadata)
            }

            [ScriptInventory]::Scripts.Add($metadata)
        }

        Write-Progress -Activity "Scanning scripts" -Completed

        # Détecter les scripts similaires
        [ScriptInventory]::DetectSimilarScripts()
    }

    # Détermine le langage en fonction de l'extension
    static [string] DetermineLanguage([string]$extension) {
        switch ($extension.ToLower()) {
            '.ps1' { return 'PowerShell' }
            '.psm1' { return 'PowerShell Module' }
            '.psd1' { return 'PowerShell Manifest' }
            '.py' { return 'Python' }
            '.cmd' { return 'Batch' }
            '.bat' { return 'Batch' }
            '.sh' { return 'Shell' }
            default { return 'Unknown' }
        }
        return 'Unknown' # Pour s'assurer que toutes les branches retournent une valeur
    }

    # Extrait les métadonnées depuis les commentaires du script
    static [ScriptMetadata] ExtractMetadata([string]$content, [ScriptMetadata]$metadata) {
        # Patterns pour extraire les métadonnées des commentaires
        $patterns = @{
            PowerShell = @{
                Author      = '(?i)\.AUTHOR\s*(.*?)(?=\r?\n|\.|$)'
                Version     = '(?i)\.VERSION\s*(.*?)(?=\r?\n|\.|$)'
                Description = '(?i)\.DESCRIPTION\s*(.*?)(?=\r?\n\.|$)'
                Tags        = '(?i)\.TAGS\s*(.*?)(?=\r?\n\.|$)'
            }
            Python     = @{
                Author      = '(?i)@author\s*:\s*(.*?)(?=\r?\n|$)'
                Version     = '(?i)@version\s*:\s*(.*?)(?=\r?\n|$)'
                Description = '(?i)"""(.*?)"""'
                Tags        = '(?i)@tags\s*:\s*(.*?)(?=\r?\n|$)'
            }
            Batch      = @{
                Author      = '(?i)::.*?[aA]uthor\s*:\s*(.*?)(?=\r?\n|$)'
                Version     = '(?i)::.*?[vV]ersion\s*:\s*(.*?)(?=\r?\n|$)'
                Description = '(?i)::.*?[dD]escription\s*:\s*(.*?)(?=\r?\n|$)'
                Tags        = '(?i)::.*?[tT]ags\s*:\s*(.*?)(?=\r?\n|$)'
            }
        }

        $patternSet = $null

        if ($metadata.Language -like 'PowerShell*') {
            $patternSet = $patterns.PowerShell
        } elseif ($metadata.Language -eq 'Python') {
            $patternSet = $patterns.Python
        } elseif ($metadata.Language -like 'Batch*') {
            $patternSet = $patterns.Batch
        } else {
            # Utiliser PowerShell comme fallback
            $patternSet = $patterns.PowerShell
        }

        if ($patternSet) {
            $authorMatch = [regex]::Match($content, $patternSet.Author)
            if ($authorMatch.Success) {
                $metadata.Author = $authorMatch.Groups[1].Value.Trim()
            }

            $versionMatch = [regex]::Match($content, $patternSet.Version)
            if ($versionMatch.Success) {
                $metadata.Version = $versionMatch.Groups[1].Value.Trim()
            }

            $descriptionMatch = [regex]::Match($content, $patternSet.Description)
            if ($descriptionMatch.Success) {
                $metadata.Description = $descriptionMatch.Groups[1].Value.Trim()
            }

            $tagsMatch = [regex]::Match($content, $patternSet.Tags)
            if ($tagsMatch.Success) {
                $metadata.Tags = $tagsMatch.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() }
            }
        }

        return $metadata
    }

    # Sauvegarde l'inventaire dans un fichier JSON
    static [void] SaveInventory() {
        $json = [ScriptInventory]::Scripts | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText([ScriptInventory]::InventoryPath, $json)
    }

    # Charge l'inventaire depuis le fichier JSON
    static [void] LoadInventory() {
        # S'assurer que le chemin d'inventaire est correctement défini
        $dataDir = Join-Path -Path $PWD.Path -ChildPath "data"
        [ScriptInventory]::InventoryPath = Join-Path -Path $dataDir -ChildPath "script_inventory.json"

        if (Test-Path [ScriptInventory]::InventoryPath) {
            $json = Get-Content [ScriptInventory]::InventoryPath -Raw
            [ScriptInventory]::Scripts = $json | ConvertFrom-Json
        }
    }

    # Détecte les scripts similaires ou dupliqués
    static [void] DetectSimilarScripts() {
        # Charger le module TextSimilarity s'il n'est pas déjà chargé
        if (-not (Get-Module -Name TextSimilarity)) {
            $modulePath = Join-Path -Path (Split-Path -Parent ([ScriptInventory]::InventoryPath)) -ChildPath "..\modules\TextSimilarity.psm1"
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force -ErrorAction SilentlyContinue
            }
        }

        $scriptCount = [ScriptInventory]::Scripts.Count
        $processedPairs = 0
        $totalPairs = ($scriptCount * ($scriptCount - 1)) / 2

        for ($i = 0; $i -lt $scriptCount; $i++) {
            for ($j = $i + 1; $j -lt $scriptCount; $j++) {
                $processedPairs++
                $percentComplete = [Math]::Round(($processedPairs / $totalPairs) * 100, 2)

                Write-Progress -Activity "Détection des scripts similaires" -Status "Comparaison $processedPairs/$totalPairs ($percentComplete%)" -PercentComplete $percentComplete

                $script1 = [ScriptInventory]::Scripts[$i]
                $script2 = [ScriptInventory]::Scripts[$j]

                # Si les hachages sont identiques, c'est un duplicat
                if ($script1.Hash -eq $script2.Hash -and $null -ne $script1.Hash -and '' -ne $script1.Hash) {
                    $script2.IsDuplicate = $true
                    $script2.DuplicateOf = $script1.FullPath
                    $script2.SimilarityScore = 100
                    continue
                }

                # Comparer le contenu des fichiers
                $contentSimilarity = 0

                # Utiliser le module TextSimilarity si disponible
                if (Get-Command -Name Get-ContentSimilarity -ErrorAction SilentlyContinue) {
                    $contentSimilarity = Get-ContentSimilarity -FilePathA $script1.FullPath -FilePathB $script2.FullPath -Algorithm Combined
                } else {
                    # Fallback : comparer directement le contenu
                    $content1 = Get-Content $script1.FullPath -Raw -ErrorAction SilentlyContinue
                    $content2 = Get-Content $script2.FullPath -Raw -ErrorAction SilentlyContinue

                    if ($content1 -eq $content2) {
                        $contentSimilarity = 100
                    }
                }

                # Si le contenu est très similaire, marquer comme duplicat
                if ($contentSimilarity -ge 95) {
                    $script2.IsDuplicate = $true
                    $script2.DuplicateOf = $script1.FullPath
                    $script2.SimilarityScore = $contentSimilarity
                    continue
                }

                # Si le contenu est similaire, marquer comme potentiellement similaire
                if ($contentSimilarity -ge 80) {
                    if ($script1.SimilarityScore -lt $contentSimilarity) {
                        $script1.SimilarityScore = $contentSimilarity
                    }
                    if ($script2.SimilarityScore -lt $contentSimilarity) {
                        $script2.SimilarityScore = $contentSimilarity
                    }
                    continue
                }

                # Vérifier la similarité des noms
                $nameScore = [ScriptInventory]::CalculateSimilarity($script1.FileName, $script2.FileName)

                # Si les noms sont très similaires, marquer comme potentiellement similaire
                if ($nameScore -gt 80) {
                    $combinedScore = [Math]::Round(($nameScore * 0.4) + ($contentSimilarity * 0.6), 2)

                    if ($script1.SimilarityScore -lt $combinedScore) {
                        $script1.SimilarityScore = $combinedScore
                    }
                    if ($script2.SimilarityScore -lt $combinedScore) {
                        $script2.SimilarityScore = $combinedScore
                    }
                }
            }
        }

        Write-Progress -Activity "Détection des scripts similaires" -Completed
    }

    # Calcule la similarité entre deux chaînes (algorithme de Levenshtein simplifié)
    static [int] CalculateSimilarity([string]$str1, [string]$str2) {
        if ([string]::IsNullOrEmpty($str1) -or [string]::IsNullOrEmpty($str2)) {
            return 0
        }

        $len1 = $str1.Length
        $len2 = $str2.Length

        if ($len1 -eq 0) { return $len2 * 100 }
        if ($len2 -eq 0) { return $len1 * 100 }

        # Distance de Levenshtein simplifiée
        $distance = 0
        $maxLen = [Math]::Max($len1, $len2)

        for ($i = 0; $i -lt $maxLen; $i++) {
            if ($i -ge $len1 -or $i -ge $len2 -or $str1[$i] -ne $str2[$i]) {
                $distance++
            }
        }

        $similarity = 100 - (($distance / $maxLen) * 100)
        return [Math]::Round($similarity)
    }

    # Classifie les scripts selon une taxonomie définie
    static [void] ClassifyScripts([hashtable]$taxonomy, [hashtable]$classificationRules) {
        foreach ($script in [ScriptInventory]::Scripts) {
            $content = Get-Content $script.FullPath -Raw -ErrorAction SilentlyContinue

            # Vérifier les règles de classification
            foreach ($category in $classificationRules.Keys) {
                $matchFound = $false

                # Vérifier les patterns dans le nom
                foreach ($pattern in $classificationRules[$category].Patterns) {
                    if ($script.FileName -like "*$pattern*") {
                        $matchFound = $true
                        break
                    }
                }

                # Vérifier les keywords dans le contenu
                if (-not $matchFound -and $content) {
                    foreach ($keyword in $classificationRules[$category].Keywords) {
                        if ($content -match $keyword) {
                            $matchFound = $true
                            break
                        }
                    }
                }

                if ($matchFound) {
                    $script.Category = $category

                    # Trouver la sous-catégorie la plus probable
                    if ($taxonomy[$category].SubCategories) {
                        foreach ($subCat in $taxonomy[$category].SubCategories.Keys) {
                            if ($script.FileName -like "*$subCat*" -or ($content -and $content -match $subCat)) {
                                $script.SubCategory = $subCat
                                break
                            }
                        }
                    }

                    break
                }
            }

            # Ajouter des tags basés sur le contenu
            if ($content) {
                if ($content -match "function ") { $script.Tags += "Fonctions" }
                if ($content -match "class ") { $script.Tags += "Classes" }
                if ($content -match "workflow") { $script.Tags += "Workflow" }
                if ($content -match "param\(") { $script.Tags += "Paramètres" }
            }
        }
    }
}

#endregion

#region Fonctions exportées

function Get-ScriptInventory {
    <#
    .SYNOPSIS
        Récupère l'inventaire des scripts
    .DESCRIPTION
        Récupère l'inventaire des scripts du projet, avec options de filtrage
    .PARAMETER Path
        Chemin du répertoire à scanner
    .PARAMETER Extensions
        Extensions de fichiers à inclure
    .PARAMETER ExcludeFolders
        Dossiers à exclure du scan
    .PARAMETER ForceRescan
        Force un nouveau scan même si l'inventaire existe déjà
    .PARAMETER Category
        Filtre par catégorie
    .PARAMETER Language
        Filtre par langage
    .PARAMETER Author
        Filtre par auteur
    .PARAMETER Tag
        Filtre par tag
    .EXAMPLE
        Get-ScriptInventory -Path "C:\Projects\MyProject" -ForceRescan
    #>
    [CmdletBinding()]
    param(
        [string]$Path = $PWD.Path,
        [string[]]$Extensions,
        [string[]]$ExcludeFolders,
        [switch]$ForceRescan,
        [string]$Category,
        [string]$Language,
        [string]$Author,
        [string]$Tag
    )

    if ($ForceRescan -or [ScriptInventory]::Scripts.Count -eq 0) {
        [ScriptInventory]::ScanDirectory($Path, $Extensions, $ExcludeFolders)
        [ScriptInventory]::SaveInventory()
    } else {
        [ScriptInventory]::LoadInventory()
    }

    $results = [ScriptInventory]::Scripts

    # Appliquer les filtres
    if ($Category) {
        $results = $results | Where-Object { $_.Category -like "*$Category*" }
    }

    if ($Language) {
        $results = $results | Where-Object { $_.Language -like "*$Language*" }
    }

    if ($Author) {
        $results = $results | Where-Object { $_.Author -like "*$Author*" }
    }

    if ($Tag) {
        $results = $results | Where-Object { $_.Tags -contains $Tag }
    }

    return $results
}

function Update-ScriptInventory {
    <#
    .SYNOPSIS
        Met à jour l'inventaire des scripts
    .DESCRIPTION
        Effectue un nouveau scan et met à jour l'inventaire des scripts
    .PARAMETER Path
        Chemin du répertoire à scanner
    .PARAMETER Extensions
        Extensions de fichiers à inclure
    .PARAMETER ExcludeFolders
        Dossiers à exclure du scan
    .EXAMPLE
        Update-ScriptInventory -Path "C:\Projects\MyProject"
    #>
    [CmdletBinding()]
    param(
        [string]$Path = $PWD.Path,
        [string[]]$Extensions,
        [string[]]$ExcludeFolders
    )

    [ScriptInventory]::ScanDirectory($Path, $Extensions, $ExcludeFolders)
    [ScriptInventory]::SaveInventory()

    return [ScriptInventory]::Scripts
}

function Get-ScriptDuplicates {
    <#
    .SYNOPSIS
        Récupère les scripts dupliqués ou similaires
    .DESCRIPTION
        Identifie et retourne les scripts dupliqués ou similaires
    .PARAMETER SimilarityThreshold
        Seuil de similarité (0-100) pour considérer deux scripts comme similaires
    .EXAMPLE
        Get-ScriptDuplicates -SimilarityThreshold 80
    #>
    [CmdletBinding()]
    param(
        [int]$SimilarityThreshold = 90
    )

    if ([ScriptInventory]::Scripts.Count -eq 0) {
        [ScriptInventory]::LoadInventory()
    }

    $duplicates = [ScriptInventory]::Scripts | Where-Object { $_.IsDuplicate -eq $true }
    $similar = [ScriptInventory]::Scripts | Where-Object { -not $_.IsDuplicate -and $_.SimilarityScore -ge $SimilarityThreshold }

    $results = @()

    foreach ($script in $duplicates) {
        $results += [PSCustomObject]@{
            ScriptName      = $script.FileName
            Path            = $script.FullPath
            DuplicateOf     = $script.DuplicateOf
            SimilarityScore = 100
            Type            = "Duplicate"
        }
    }

    foreach ($script in $similar) {
        $results += [PSCustomObject]@{
            ScriptName      = $script.FileName
            Path            = $script.FullPath
            SimilarityScore = $script.SimilarityScore
            Type            = "Similar"
        }
    }

    return $results
}

function Invoke-ScriptClassification {
    <#
    .SYNOPSIS
        Classifie les scripts selon une taxonomie définie
    .DESCRIPTION
        Analyse et classifie les scripts selon une taxonomie et des règles définies
    .PARAMETER Taxonomy
        Taxonomie de classification (catégories et sous-catégories)
    .PARAMETER ClassificationRules
        Règles de classification (patterns et mots-clés)
    .EXAMPLE
        Invoke-ScriptClassification -Taxonomy $taxonomy -ClassificationRules $rules
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Taxonomy,

        [Parameter(Mandatory = $true)]
        [hashtable]$ClassificationRules
    )

    if ([ScriptInventory]::Scripts.Count -eq 0) {
        [ScriptInventory]::LoadInventory()
    }

    [ScriptInventory]::ClassifyScripts($Taxonomy, $ClassificationRules)
    [ScriptInventory]::SaveInventory()

    return [ScriptInventory]::Scripts
}

function Export-ScriptInventory {
    <#
    .SYNOPSIS
        Exporte l'inventaire des scripts
    .DESCRIPTION
        Exporte l'inventaire des scripts dans différents formats
    .PARAMETER Path
        Chemin du fichier de sortie
    .PARAMETER Format
        Format de sortie (CSV, JSON, HTML)
    .EXAMPLE
        Export-ScriptInventory -Path "inventory.csv" -Format CSV
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet("CSV", "JSON", "HTML")]
        [string]$Format
    )

    if ([ScriptInventory]::Scripts.Count -eq 0) {
        [ScriptInventory]::LoadInventory()
    }

    $scripts = [ScriptInventory]::Scripts

    switch ($Format) {
        "CSV" {
            $scripts | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        }
        "JSON" {
            $scripts | ConvertTo-Json -Depth 5 | Out-File -FilePath $Path -Encoding UTF8
        }
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Inventaire des Scripts</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .duplicate { background-color: #ffdddd; }
        .similar { background-color: #ffffcc; }
    </style>
</head>
<body>
    <h1>Inventaire des Scripts</h1>
    <p>Généré le $(Get-Date)</p>
    <table>
        <tr>
            <th>Nom</th>
            <th>Chemin</th>
            <th>Langage</th>
            <th>Catégorie</th>
            <th>Sous-catégorie</th>
            <th>Auteur</th>
            <th>Version</th>
            <th>Lignes</th>
            <th>Dernière modification</th>
        </tr>
"@

            foreach ($script in $scripts) {
                $rowClass = ""
                if ($script.IsDuplicate) { $rowClass = "duplicate" }
                elseif ($script.SimilarityScore -ge 80) { $rowClass = "similar" }

                $html += @"
        <tr class="$rowClass">
            <td>$($script.FileName)</td>
            <td>$($script.FullPath)</td>
            <td>$($script.Language)</td>
            <td>$($script.Category)</td>
            <td>$($script.SubCategory)</td>
            <td>$($script.Author)</td>
            <td>$($script.Version)</td>
            <td>$($script.LineCount)</td>
            <td>$($script.LastModified)</td>
        </tr>
"@
            }

            $html += @"
    </table>
</body>
</html>
"@

            $html | Out-File -FilePath $Path -Encoding UTF8
        }
    }

    Write-Host "Inventaire exporté vers $Path"
}

function Find-Script {
    <#
    .SYNOPSIS
        Recherche des scripts selon différents critères
    .DESCRIPTION
        Recherche des scripts dans l'inventaire selon le nom, l'auteur, les tags ou le langage
    .PARAMETER Name
        Filtre par nom de fichier
    .PARAMETER Author
        Filtre par auteur
    .PARAMETER Tag
        Filtre par tag
    .PARAMETER Language
        Filtre par langage
    .EXAMPLE
        Find-Script -Name "Backup" -Language "PowerShell"
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Author,
        [string]$Tag,
        [string]$Language
    )

    $scripts = Get-ScriptInventory

    if ($Name) { $scripts = $scripts | Where-Object { $_.FileName -like "*$Name*" } }
    if ($Author) { $scripts = $scripts | Where-Object { $_.Author -like "*$Author*" } }
    if ($Tag) { $scripts = $scripts | Where-Object { $_.Tags -contains $Tag } }
    if ($Language) { $scripts = $scripts | Where-Object { $_.Language -eq $Language } }

    return $scripts
}

#endregion

# Exporter les fonctions
Export-ModuleMember -Function Get-ScriptInventory, Update-ScriptInventory, Get-ScriptDuplicates, Invoke-ScriptClassification, Export-ScriptInventory, Find-Script
