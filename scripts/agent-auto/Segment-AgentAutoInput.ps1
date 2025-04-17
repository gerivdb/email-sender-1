#Requires -Version 5.1
<#
.SYNOPSIS
    Segmente automatiquement les entrées volumineuses pour Agent Auto.
.DESCRIPTION
    Ce script segmente les entrées volumineuses pour Agent Auto afin d'éviter
    les interruptions dues aux limites de taille d'entrée.
.PARAMETER Input
    Entrée à segmenter (texte, fichier, objet JSON).
.PARAMETER OutputPath
    Chemin du dossier de sortie pour les segments.
.PARAMETER MaxInputSizeKB
    Taille maximale d'entrée en KB (par défaut: 10).
.PARAMETER ChunkSizeKB
    Taille des segments en KB (par défaut: 5).
.PARAMETER PreserveLines
    Préserve les sauts de ligne lors de la segmentation de texte.
.PARAMETER InputType
    Type d'entrée (Auto, Text, Json, File).
.EXAMPLE
    .\Segment-AgentAutoInput.ps1 -Input "chemin/vers/fichier.json" -OutputPath "chemin/vers/sortie" -InputType File
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [object]$Input,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\output\segments",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxInputSizeKB = 10,
    
    [Parameter(Mandatory = $false)]
    [int]$ChunkSizeKB = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$PreserveLines,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Text", "Json", "File")]
    [string]$InputType = "Auto"
)

# Importer le module de segmentation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de segmentation introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction principale
function Start-InputSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Input,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxInputSizeKB,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines,
        
        [Parameter(Mandatory = $false)]
        [string]$InputType
    )
    
    Write-Log "Démarrage de la segmentation d'entrée pour Agent Auto..." -Level "TITLE"
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -MaxInputSizeKB $MaxInputSizeKB -DefaultChunkSizeKB $ChunkSizeKB
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputPath"
    }
    
    # Déterminer le type d'entrée si Auto
    $actualInputType = $InputType
    
    if ($InputType -eq "Auto") {
        if ($Input -is [string]) {
            if (Test-Path -Path $Input) {
                $actualInputType = "File"
            }
            else {
                $actualInputType = "Text"
            }
        }
        elseif ($Input -is [System.IO.FileInfo]) {
            $actualInputType = "File"
        }
        elseif ($Input -is [System.Collections.IDictionary] -or $Input -is [PSCustomObject] -or $Input -is [array]) {
            $actualInputType = "Json"
        }
        else {
            $actualInputType = "Text"
        }
    }
    
    Write-Log "Type d'entrée détecté: $actualInputType"
    
    # Mesurer la taille de l'entrée
    $sizeKB = Measure-InputSize -Input $Input
    Write-Log "Taille de l'entrée: $sizeKB KB"
    
    # Vérifier si la segmentation est nécessaire
    if ($sizeKB -le $MaxInputSizeKB) {
        Write-Log "L'entrée est déjà de taille acceptable (< $MaxInputSizeKB KB). Aucune segmentation nécessaire." -Level "SUCCESS"
        
        # Créer un seul fichier de sortie
        $outputFile = Join-Path -Path $OutputPath -ChildPath "input.txt"
        
        switch ($actualInputType) {
            "Text" {
                $Input | Out-File -FilePath $outputFile -Encoding utf8
            }
            "Json" {
                $Input | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding utf8
            }
            "File" {
                $filePath = if ($Input -is [System.IO.FileInfo]) { $Input.FullName } else { $Input }
                Copy-Item -Path $filePath -Destination $outputFile
            }
        }
        
        Write-Log "Entrée copiée dans: $outputFile" -Level "SUCCESS"
        return @($outputFile)
    }
    
    # Segmenter l'entrée
    $segments = @()
    
    switch ($actualInputType) {
        "Text" {
            $segments = Split-TextInput -Text $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
        }
        "Json" {
            $segments = Split-JsonInput -JsonObject $Input -ChunkSizeKB $ChunkSizeKB
        }
        "File" {
            $filePath = if ($Input -is [System.IO.FileInfo]) { $Input.FullName } else { $Input }
            $segments = Split-FileInput -FilePath $filePath -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
        }
    }
    
    Write-Log "Entrée segmentée en $($segments.Count) parties."
    
    # Enregistrer les segments
    $outputFiles = @()
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    for ($i = 0; $i -lt $segments.Count; $i++) {
        $segment = $segments[$i]
        $segmentNumber = ($i + 1).ToString("000")
        $outputFile = Join-Path -Path $OutputPath -ChildPath "segment_${timestamp}_${segmentNumber}.txt"
        
        if ($segment -is [string]) {
            $segment | Out-File -FilePath $outputFile -Encoding utf8
        }
        elseif ($segment -is [System.Collections.IDictionary] -or $segment -is [PSCustomObject] -or $segment -is [array]) {
            $segment | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding utf8
        }
        else {
            $segment.ToString() | Out-File -FilePath $outputFile -Encoding utf8
        }
        
        $outputFiles += $outputFile
    }
    
    # Créer un fichier d'index
    $indexFile = Join-Path -Path $OutputPath -ChildPath "index_${timestamp}.json"
    
    $index = @{
        Timestamp = (Get-Date).ToString("o")
        OriginalSize = $sizeKB
        SegmentCount = $segments.Count
        SegmentSize = $ChunkSizeKB
        InputType = $actualInputType
        Segments = $outputFiles
    }
    
    $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexFile -Encoding utf8
    
    Write-Log "Segmentation terminée. $($segments.Count) segments créés." -Level "SUCCESS"
    Write-Log "Fichier d'index: $indexFile" -Level "SUCCESS"
    
    return $outputFiles
}

# Exécuter la fonction principale
$result = Start-InputSegmentation -Input $Input -OutputPath $OutputPath -MaxInputSizeKB $MaxInputSizeKB -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines -InputType $InputType

# Afficher les résultats
Write-Log "Segments créés:" -Level "TITLE"

foreach ($file in $result) {
    Write-Host "- $file"
}

# Retourner les chemins des segments
return $result
