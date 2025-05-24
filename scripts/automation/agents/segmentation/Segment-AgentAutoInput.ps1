#Requires -Version 5.1
<#
.SYNOPSIS
    Segmente automatiquement les entrÃ©es volumineuses pour Agent Auto.
.DESCRIPTION
    Ce script segmente les entrÃ©es volumineuses pour Agent Auto afin d'Ã©viter
    les interruptions dues aux limites de taille d'entrÃ©e.
.PARAMETER Input
    EntrÃ©e Ã  segmenter (texte, fichier, objet JSON).
.PARAMETER OutputPath
    Chemin du dossier de sortie pour les segments.
.PARAMETER MaxInputSizeKB
    Taille maximale d'entrÃ©e en KB (par dÃ©faut: 10).
.PARAMETER ChunkSizeKB
    Taille des segments en KB (par dÃ©faut: 5).
.PARAMETER PreserveLines
    PrÃ©serve les sauts de ligne lors de la segmentation de texte.
.PARAMETER InputType
    Type d'entrÃ©e (Auto, Text, Json, File).
.EXAMPLE
    .\Segment-AgentAutoInput.ps1 -Input "chemin/vers/fichier.json" -OutputPath "chemin/vers/sortie" -InputType File
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
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

# Fonction pour Ã©crire dans le journal
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
    
    Write-Log "DÃ©marrage de la segmentation d'entrÃ©e pour Agent Auto..." -Level "TITLE"
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -MaxInputSizeKB $MaxInputSizeKB -DefaultChunkSizeKB $ChunkSizeKB
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath"
    }
    
    # DÃ©terminer le type d'entrÃ©e si Auto
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
    
    Write-Log "Type d'entrÃ©e dÃ©tectÃ©: $actualInputType"
    
    # Mesurer la taille de l'entrÃ©e
    $sizeKB = Measure-InputSize -Input $Input
    Write-Log "Taille de l'entrÃ©e: $sizeKB KB"
    
    # VÃ©rifier si la segmentation est nÃ©cessaire
    if ($sizeKB -le $MaxInputSizeKB) {
        Write-Log "L'entrÃ©e est dÃ©jÃ  de taille acceptable (< $MaxInputSizeKB KB). Aucune segmentation nÃ©cessaire." -Level "SUCCESS"
        
        # CrÃ©er un seul fichier de sortie
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
        
        Write-Log "EntrÃ©e copiÃ©e dans: $outputFile" -Level "SUCCESS"
        return @($outputFile)
    }
    
    # Segmenter l'entrÃ©e
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
    
    Write-Log "EntrÃ©e segmentÃ©e en $($segments.Count) parties."
    
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
    
    # CrÃ©er un fichier d'index
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
    
    Write-Log "Segmentation terminÃ©e. $($segments.Count) segments crÃ©Ã©s." -Level "SUCCESS"
    Write-Log "Fichier d'index: $indexFile" -Level "SUCCESS"
    
    return $outputFiles
}

# ExÃ©cuter la fonction principale
$result = Start-InputSegmentation -Input $Input -OutputPath $OutputPath -MaxInputSizeKB $MaxInputSizeKB -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines -InputType $InputType

# Afficher les rÃ©sultats
Write-Log "Segments crÃ©Ã©s:" -Level "TITLE"

foreach ($file in $result) {
    Write-Host "- $file"
}

# Retourner les chemins des segments
return $result
