#Requires -Version 5.1
<#
.SYNOPSIS
    Module de segmentation des entrées pour Agent Auto.
.DESCRIPTION
    Ce module fournit des fonctions pour segmenter automatiquement les entrées volumineuses
    pour Agent Auto, évitant ainsi les interruptions dues aux limites de taille d'entrée.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

# Variables globales
$script:MaxInputSizeKB = 10
$script:DefaultChunkSizeKB = 5
$script:StateFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\cache\agent_auto_state.json"
$script:LogsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\logs\segmentation"

# Créer les dossiers nécessaires s'ils n'existent pas
if (-not (Test-Path -Path (Split-Path -Path $script:StateFilePath -Parent))) {
    New-Item -Path (Split-Path -Path $script:StateFilePath -Parent) -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $script:LogsPath)) {
    New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
}

# Fonction pour initialiser le module
function Initialize-InputSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxInputSizeKB = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultChunkSizeKB = 5,
        
        [Parameter(Mandatory = $false)]
        [string]$StateFilePath = ""
    )
    
    $script:MaxInputSizeKB = $MaxInputSizeKB
    $script:DefaultChunkSizeKB = $DefaultChunkSizeKB
    
    if ($StateFilePath) {
        $script:StateFilePath = $StateFilePath
    }
    
    Write-Verbose "Module de segmentation initialisé. Taille max: $MaxInputSizeKB KB, Taille de segment: $DefaultChunkSizeKB KB"
}

# Fonction pour mesurer la taille d'une entrée
function Measure-InputSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Input
    )
    
    $size = 0
    
    if ($Input -is [string]) {
        $size = [System.Text.Encoding]::UTF8.GetByteCount($Input)
    }
    elseif ($Input -is [byte[]]) {
        $size = $Input.Length
    }
    elseif ($Input -is [System.IO.FileInfo]) {
        $size = $Input.Length
    }
    elseif ($Input -is [System.Collections.IDictionary] -or $Input -is [PSCustomObject]) {
        $json = ConvertTo-Json -InputObject $Input -Depth 10 -Compress
        $size = [System.Text.Encoding]::UTF8.GetByteCount($json)
    }
    elseif ($Input -is [array]) {
        $json = ConvertTo-Json -InputObject $Input -Depth 10 -Compress
        $size = [System.Text.Encoding]::UTF8.GetByteCount($json)
    }
    else {
        $size = [System.Text.Encoding]::UTF8.GetByteCount($Input.ToString())
    }
    
    return [math]::Round($size / 1024, 2)  # Taille en KB
}

# Fonction pour segmenter une entrée texte
function Split-TextInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines
    )
    
    if ($ChunkSizeKB -le 0) {
        $ChunkSizeKB = $script:DefaultChunkSizeKB
    }
    
    $chunkSizeBytes = $ChunkSizeKB * 1024
    $chunks = @()
    
    if ($PreserveLines) {
        # Segmenter en préservant les lignes
        $lines = $Text -split "`n"
        $currentChunk = ""
        $currentSize = 0
        
        foreach ($line in $lines) {
            $lineSize = [System.Text.Encoding]::UTF8.GetByteCount($line + "`n")
            
            if ($currentSize + $lineSize -gt $chunkSizeBytes) {
                # Ajouter le chunk actuel et commencer un nouveau
                $chunks += $currentChunk
                $currentChunk = $line + "`n"
                $currentSize = $lineSize
            }
            else {
                # Ajouter la ligne au chunk actuel
                $currentChunk += $line + "`n"
                $currentSize += $lineSize
            }
        }
        
        # Ajouter le dernier chunk s'il n'est pas vide
        if ($currentChunk) {
            $chunks += $currentChunk
        }
    }
    else {
        # Segmenter par taille sans préserver les lignes
        $textBytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $totalBytes = $textBytes.Length
        $position = 0
        
        while ($position -lt $totalBytes) {
            $remainingBytes = $totalBytes - $position
            $bytesToTake = [Math]::Min($chunkSizeBytes, $remainingBytes)
            
            $chunkBytes = New-Object byte[] $bytesToTake
            [Array]::Copy($textBytes, $position, $chunkBytes, 0, $bytesToTake)
            
            $chunk = [System.Text.Encoding]::UTF8.GetString($chunkBytes)
            $chunks += $chunk
            
            $position += $bytesToTake
        }
    }
    
    return $chunks
}

# Fonction pour segmenter une entrée JSON
function Split-JsonInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$JsonObject,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0
    )
    
    if ($ChunkSizeKB -le 0) {
        $ChunkSizeKB = $script:DefaultChunkSizeKB
    }
    
    $chunks = @()
    
    # Convertir en JSON
    $jsonString = ConvertTo-Json -InputObject $JsonObject -Depth 10
    
    # Mesurer la taille
    $sizeKB = Measure-InputSize -Input $jsonString
    
    if ($sizeKB -le $ChunkSizeKB) {
        # Pas besoin de segmenter
        return @($JsonObject)
    }
    
    # Segmenter selon le type
    if ($JsonObject -is [array]) {
        # Segmenter un tableau
        $currentChunk = @()
        $currentSize = 0
        
        foreach ($item in $JsonObject) {
            $itemJson = ConvertTo-Json -InputObject $item -Depth 10
            $itemSize = Measure-InputSize -Input $itemJson
            
            if ($currentSize + $itemSize -gt $ChunkSizeKB) {
                # Ajouter le chunk actuel et commencer un nouveau
                if ($currentChunk.Count -gt 0) {
                    $chunks += ,$currentChunk
                    $currentChunk = @()
                    $currentSize = 0
                }
                
                # Si l'élément est trop grand, le segmenter récursivement
                if ($itemSize -gt $ChunkSizeKB) {
                    $subChunks = Split-JsonInput -JsonObject $item -ChunkSizeKB $ChunkSizeKB
                    foreach ($subChunk in $subChunks) {
                        $chunks += ,$subChunk
                    }
                }
                else {
                    $currentChunk += $item
                    $currentSize = $itemSize
                }
            }
            else {
                # Ajouter l'élément au chunk actuel
                $currentChunk += $item
                $currentSize += $itemSize
            }
        }
        
        # Ajouter le dernier chunk s'il n'est pas vide
        if ($currentChunk.Count -gt 0) {
            $chunks += ,$currentChunk
        }
    }
    elseif ($JsonObject -is [System.Collections.IDictionary] -or $JsonObject -is [PSCustomObject]) {
        # Segmenter un objet
        $properties = $JsonObject | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        $currentChunk = @{}
        $currentSize = 0
        
        foreach ($prop in $properties) {
            $value = $JsonObject.$prop
            $valueJson = ConvertTo-Json -InputObject $value -Depth 10
            $valueSize = Measure-InputSize -Input $valueJson
            
            if ($currentSize + $valueSize -gt $ChunkSizeKB) {
                # Ajouter le chunk actuel et commencer un nouveau
                if ($currentChunk.Count -gt 0) {
                    $chunks += [PSCustomObject]$currentChunk
                    $currentChunk = @{}
                    $currentSize = 0
                }
                
                # Si la valeur est trop grande, la segmenter récursivement
                if ($valueSize -gt $ChunkSizeKB) {
                    $subChunks = Split-JsonInput -JsonObject $value -ChunkSizeKB $ChunkSizeKB
                    foreach ($subChunk in $subChunks) {
                        $chunks += [PSCustomObject]@{ $prop = $subChunk }
                    }
                }
                else {
                    $currentChunk[$prop] = $value
                    $currentSize = $valueSize
                }
            }
            else {
                # Ajouter la propriété au chunk actuel
                $currentChunk[$prop] = $value
                $currentSize += $valueSize
            }
        }
        
        # Ajouter le dernier chunk s'il n'est pas vide
        if ($currentChunk.Count -gt 0) {
            $chunks += [PSCustomObject]$currentChunk
        }
    }
    else {
        # Type non pris en charge, segmenter comme du texte
        $textChunks = Split-TextInput -Text $jsonString -ChunkSizeKB $ChunkSizeKB
        
        foreach ($chunk in $textChunks) {
            try {
                $obj = ConvertFrom-Json -InputObject $chunk
                $chunks += $obj
            }
            catch {
                # Si la conversion échoue, ajouter le texte brut
                $chunks += $chunk
            }
        }
    }
    
    return $chunks
}

# Fonction pour segmenter un fichier
function Split-FileInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines
    )
    
    if ($ChunkSizeKB -le 0) {
        $ChunkSizeKB = $script:DefaultChunkSizeKB
    }
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Obtenir l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    # Segmenter selon le type de fichier
    if ($extension -eq ".json") {
        # Fichier JSON
        try {
            $json = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
            return Split-JsonInput -JsonObject $json -ChunkSizeKB $ChunkSizeKB
        }
        catch {
            Write-Warning "Erreur lors de la lecture du fichier JSON. Traitement comme texte."
            $content = Get-Content -Path $FilePath -Raw
            return Split-TextInput -Text $content -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
        }
    }
    elseif ($extension -in @(".txt", ".md", ".ps1", ".py", ".cs", ".js", ".html", ".css", ".xml", ".csv")) {
        # Fichier texte
        $content = Get-Content -Path $FilePath -Raw
        return Split-TextInput -Text $content -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
    }
    else {
        # Fichier binaire ou non pris en charge
        Write-Warning "Type de fichier non pris en charge pour la segmentation: $extension"
        return @()
    }
}

# Fonction pour segmenter une entrée générique
function Split-Input {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Input,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines
    )
    
    if ($ChunkSizeKB -le 0) {
        $ChunkSizeKB = $script:DefaultChunkSizeKB
    }
    
    # Mesurer la taille de l'entrée
    $sizeKB = Measure-InputSize -Input $Input
    
    # Si l'entrée est plus petite que la taille maximale, la retourner telle quelle
    if ($sizeKB -le $script:MaxInputSizeKB) {
        return @($Input)
    }
    
    Write-Verbose "Entrée trop volumineuse ($sizeKB KB). Segmentation en cours..."
    
    # Segmenter selon le type
    if ($Input -is [string]) {
        return Split-TextInput -Text $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
    }
    elseif ($Input -is [System.IO.FileInfo] -or ($Input -is [string] -and (Test-Path -Path $Input))) {
        $path = if ($Input -is [System.IO.FileInfo]) { $Input.FullName } else { $Input }
        return Split-FileInput -FilePath $path -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
    }
    elseif ($Input -is [System.Collections.IDictionary] -or $Input -is [PSCustomObject] -or $Input -is [array]) {
        return Split-JsonInput -JsonObject $Input -ChunkSizeKB $ChunkSizeKB
    }
    else {
        # Type non pris en charge, convertir en chaîne
        return Split-TextInput -Text $Input.ToString() -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
    }
}

# Fonction pour sauvegarder l'état de segmentation
function Save-SegmentationState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        
        [Parameter(Mandatory = $true)]
        [array]$Segments,
        
        [Parameter(Mandatory = $true)]
        [int]$CurrentIndex,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    $state = @{
        Id = $Id
        Timestamp = (Get-Date).ToString("o")
        TotalSegments = $Segments.Count
        CurrentIndex = $CurrentIndex
        RemainingSegments = $Segments.Count - $CurrentIndex
        Metadata = $Metadata
        Segments = $Segments
    }
    
    $state | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:StateFilePath -Encoding utf8
    
    Write-Verbose "État de segmentation sauvegardé pour l'ID: $Id"
}

# Fonction pour charger l'état de segmentation
function Get-SegmentationState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id
    )
    
    if (-not (Test-Path -Path $script:StateFilePath)) {
        Write-Verbose "Aucun état de segmentation trouvé."
        return $null
    }
    
    try {
        $state = Get-Content -Path $script:StateFilePath -Raw | ConvertFrom-Json
        
        if ($state.Id -ne $Id) {
            Write-Verbose "L'état de segmentation ne correspond pas à l'ID: $Id"
            return $null
        }
        
        return $state
    }
    catch {
        Write-Warning "Erreur lors du chargement de l'état de segmentation: $_"
        return $null
    }
}

# Fonction pour traiter une entrée avec segmentation automatique
function Invoke-WithSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Input,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [string]$Id = "",
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines,
        
        [Parameter(Mandatory = $false)]
        [switch]$ContinueFromLastState
    )
    
    if ($ChunkSizeKB -le 0) {
        $ChunkSizeKB = $script:DefaultChunkSizeKB
    }
    
    # Générer un ID unique si non fourni
    if (-not $Id) {
        $Id = [guid]::NewGuid().ToString()
    }
    
    # Mesurer la taille de l'entrée
    $sizeKB = Measure-InputSize -Input $Input
    
    # Journaliser l'opération
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile = Join-Path -Path $script:LogsPath -ChildPath "segmentation_${timestamp}.log"
    
    "[$timestamp] Démarrage de la segmentation pour l'ID: $Id" | Out-File -FilePath $logFile -Encoding utf8
    "[$timestamp] Taille de l'entrée: $sizeKB KB" | Out-File -FilePath $logFile -Encoding utf8 -Append
    
    # Vérifier si on doit continuer depuis un état précédent
    $state = $null
    
    if ($ContinueFromLastState) {
        $state = Get-SegmentationState -Id $Id
        
        if ($state) {
            "[$timestamp] Reprise depuis l'état précédent. Segment actuel: $($state.CurrentIndex + 1)/$($state.TotalSegments)" | Out-File -FilePath $logFile -Encoding utf8 -Append
        }
    }
    
    # Si pas d'état précédent ou si on ne continue pas, segmenter l'entrée
    if (-not $state) {
        # Si l'entrée est plus petite que la taille maximale, l'exécuter directement
        if ($sizeKB -le $script:MaxInputSizeKB) {
            "[$timestamp] Entrée de taille acceptable. Exécution directe." | Out-File -FilePath $logFile -Encoding utf8 -Append
            
            try {
                $result = & $ScriptBlock $Input
                return $result
            }
            catch {
                "[$timestamp] Erreur lors de l'exécution: $_" | Out-File -FilePath $logFile -Encoding utf8 -Append
                throw $_
            }
        }
        
        # Segmenter l'entrée
        $segments = Split-Input -Input $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
        
        "[$timestamp] Entrée segmentée en $($segments.Count) parties." | Out-File -FilePath $logFile -Encoding utf8 -Append
        
        # Sauvegarder l'état initial
        Save-SegmentationState -Id $Id -Segments $segments -CurrentIndex 0
        
        $state = @{
            Id = $Id
            TotalSegments = $segments.Count
            CurrentIndex = 0
            Segments = $segments
        }
    }
    
    # Traiter les segments
    $results = @()
    
    for ($i = $state.CurrentIndex; $i -lt $state.TotalSegments; $i++) {
        $segment = $state.Segments[$i]
        
        "[$timestamp] Traitement du segment $($i + 1)/$($state.TotalSegments)" | Out-File -FilePath $logFile -Encoding utf8 -Append
        
        try {
            $segmentResult = & $ScriptBlock $segment
            $results += $segmentResult
            
            # Mettre à jour l'état
            Save-SegmentationState -Id $Id -Segments $state.Segments -CurrentIndex ($i + 1)
            
            "[$timestamp] Segment $($i + 1) traité avec succès." | Out-File -FilePath $logFile -Encoding utf8 -Append
        }
        catch {
            "[$timestamp] Erreur lors du traitement du segment $($i + 1): $_" | Out-File -FilePath $logFile -Encoding utf8 -Append
            
            # Sauvegarder l'état pour pouvoir reprendre plus tard
            Save-SegmentationState -Id $Id -Segments $state.Segments -CurrentIndex $i
            
            throw $_
        }
    }
    
    "[$timestamp] Traitement terminé. $($state.TotalSegments) segments traités." | Out-File -FilePath $logFile -Encoding utf8 -Append
    
    return $results
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-InputSegmentation, Measure-InputSize, Split-TextInput, Split-JsonInput, Split-FileInput, Split-Input, Save-SegmentationState, Get-SegmentationState, Invoke-WithSegmentation
