# Compare-RoadmapStructure.ps1
# Script pour comparer la structure des roadmaps et détecter les changements structurels
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OriginalContent,
    
    [Parameter(Mandatory = $false)]
    [string]$NewContent,
    
    [Parameter(Mandatory = $false)]
    [string]$OriginalPath,
    
    [Parameter(Mandatory = $false)]
    [string]$NewPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "..\utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        Write-Host "[$Level] $Message"
    }
}

# Fonction pour extraire la structure hiérarchique d'un contenu markdown
function Get-MarkdownStructure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $structure = @()
    $lines = $Content -split "`n"
    $currentPath = @()
    $currentLevel = 0
    
    foreach ($line in $lines) {
        # Détecter les en-têtes
        if ($line -match '^(#+)\s+(.+)$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            
            # Ajuster le chemin actuel
            if ($level -le $currentLevel) {
                $currentPath = $currentPath[0..($level - 2)]
            }
            
            $currentLevel = $level
            $currentPath += $title
            
            $structure += [PSCustomObject]@{
                Type = "Header"
                Level = $level
                Title = $title
                Path = $currentPath -join " > "
                OriginalLine = $line
            }
        }
        # Détecter les tâches
        elseif ($line -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
            $status = $matches[1] -ne ' ' ? "Completed" : "Incomplete"
            $taskId = $matches[2]
            $description = $matches[3].Trim()
            
            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0
            
            $structure += [PSCustomObject]@{
                Type = "Task"
                TaskId = $taskId
                Description = $description
                Status = $status
                IndentLevel = $indentLevel
                Path = $currentPath -join " > "
                OriginalLine = $line
            }
        }
        # Détecter les listes
        elseif ($line -match '^\s*-\s+(.+)$') {
            $item = $matches[1].Trim()
            
            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0
            
            $structure += [PSCustomObject]@{
                Type = "ListItem"
                Content = $item
                IndentLevel = $indentLevel
                Path = $currentPath -join " > "
                OriginalLine = $line
            }
        }
    }
    
    return $structure
}

# Fonction pour comparer deux structures
function Compare-Structures {
    param (
        [Parameter(Mandatory = $true)]
        [array]$OriginalStructure,
        
        [Parameter(Mandatory = $true)]
        [array]$NewStructure
    )
    
    $changes = @{
        AddedHeaders = @()
        RemovedHeaders = @()
        ModifiedHeaders = @()
        StructuralChanges = @()
        HeaderCount = @{
            Original = ($OriginalStructure | Where-Object { $_.Type -eq "Header" }).Count
            New = ($NewStructure | Where-Object { $_.Type -eq "Header" }).Count
        }
        TaskCount = @{
            Original = ($OriginalStructure | Where-Object { $_.Type -eq "Task" }).Count
            New = ($NewStructure | Where-Object { $_.Type -eq "Task" }).Count
        }
    }
    
    # Comparer les en-têtes
    $originalHeaders = $OriginalStructure | Where-Object { $_.Type -eq "Header" }
    $newHeaders = $NewStructure | Where-Object { $_.Type -eq "Header" }
    
    # Créer des dictionnaires pour un accès rapide
    $originalHeadersByPath = @{}
    $newHeadersByPath = @{}
    
    foreach ($header in $originalHeaders) {
        $originalHeadersByPath[$header.Path] = $header
    }
    
    foreach ($header in $newHeaders) {
        $newHeadersByPath[$header.Path] = $header
        
        # Vérifier si l'en-tête existe dans la structure originale
        if (-not $originalHeadersByPath.ContainsKey($header.Path)) {
            $changes.AddedHeaders += $header
        } elseif ($header.Title -ne $originalHeadersByPath[$header.Path].Title) {
            $changes.ModifiedHeaders += [PSCustomObject]@{
                Path = $header.Path
                OldTitle = $originalHeadersByPath[$header.Path].Title
                NewTitle = $header.Title
                Level = $header.Level
            }
        }
    }
    
    # Trouver les en-têtes supprimés
    foreach ($header in $originalHeaders) {
        if (-not $newHeadersByPath.ContainsKey($header.Path)) {
            $changes.RemovedHeaders += $header
        }
    }
    
    # Analyser les changements structurels
    $originalPaths = $OriginalStructure | ForEach-Object { $_.Path } | Select-Object -Unique
    $newPaths = $NewStructure | ForEach-Object { $_.Path } | Select-Object -Unique
    
    foreach ($path in $newPaths) {
        if ($originalPaths -notcontains $path) {
            $changes.StructuralChanges += [PSCustomObject]@{
                Type = "Added"
                Path = $path
            }
        }
    }
    
    foreach ($path in $originalPaths) {
        if ($newPaths -notcontains $path) {
            $changes.StructuralChanges += [PSCustomObject]@{
                Type = "Removed"
                Path = $path
            }
        }
    }
    
    return $changes
}

# Fonction principale
function Compare-RoadmapStructure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent,
        
        [Parameter(Mandatory = $true)]
        [string]$NewContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput
    )
    
    # Extraire les structures
    $originalStructure = Get-MarkdownStructure -Content $OriginalContent
    $newStructure = Get-MarkdownStructure -Content $NewContent
    
    # Comparer les structures
    $changes = Compare-Structures -OriginalStructure $originalStructure -NewStructure $newStructure
    
    # Déterminer s'il y a des changements structurels
    $hasStructuralChanges = $changes.AddedHeaders.Count -gt 0 -or 
                           $changes.RemovedHeaders.Count -gt 0 -or 
                           $changes.ModifiedHeaders.Count -gt 0 -or 
                           $changes.StructuralChanges.Count -gt 0
    
    return @{
        HasStructuralChanges = $hasStructuralChanges
        Changes = $changes
        OriginalStructure = if ($DetailedOutput) { $originalStructure } else { $null }
        NewStructure = if ($DetailedOutput) { $newStructure } else { $null }
    }
}

# Fonction principale du script
function Main {
    # Vérifier si nous avons le contenu ou les chemins
    if (-not $OriginalContent -and -not $OriginalPath) {
        Write-Log "Vous devez spécifier soit OriginalContent, soit OriginalPath" -Level "Error"
        return
    }
    
    if (-not $NewContent -and -not $NewPath) {
        Write-Log "Vous devez spécifier soit NewContent, soit NewPath" -Level "Error"
        return
    }
    
    # Charger le contenu à partir des fichiers si nécessaire
    if (-not $OriginalContent -and $OriginalPath) {
        if (Test-Path -Path $OriginalPath) {
            $OriginalContent = Get-Content -Path $OriginalPath -Raw
        } else {
            Write-Log "Le fichier original n'existe pas: $OriginalPath" -Level "Error"
            return
        }
    }
    
    if (-not $NewContent -and $NewPath) {
        if (Test-Path -Path $NewPath) {
            $NewContent = Get-Content -Path $NewPath -Raw
        } else {
            Write-Log "Le nouveau fichier n'existe pas: $NewPath" -Level "Error"
            return
        }
    }
    
    # Comparer les structures
    $result = Compare-RoadmapStructure -OriginalContent $OriginalContent -NewContent $NewContent -DetailedOutput:$DetailedOutput
    
    # Afficher les résultats
    if ($result.HasStructuralChanges) {
        Write-Log "Changements structurels détectés:" -Level "Info"
        Write-Log "  - En-têtes ajoutés: $($result.Changes.AddedHeaders.Count)" -Level "Info"
        Write-Log "  - En-têtes supprimés: $($result.Changes.RemovedHeaders.Count)" -Level "Info"
        Write-Log "  - En-têtes modifiés: $($result.Changes.ModifiedHeaders.Count)" -Level "Info"
        Write-Log "  - Autres changements structurels: $($result.Changes.StructuralChanges.Count)" -Level "Info"
    } else {
        Write-Log "Aucun changement structurel détecté" -Level "Info"
    }
    
    # Enregistrer les résultats détaillés si demandé
    if ($OutputPath) {
        $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Résultats détaillés enregistrés dans $OutputPath" -Level "Info"
    }
    
    return $result
}

# Exécuter la fonction principale
Main
