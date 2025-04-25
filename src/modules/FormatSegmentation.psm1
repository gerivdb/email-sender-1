#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'intégration entre InputSegmentation.psm1 et les segmenteurs de formats.
.DESCRIPTION
    Ce module fournit une intégration entre le module InputSegmentation.psm1 existant
    et les segmenteurs de formats JSON, XML et texte, permettant une segmentation
    avancée avec détection automatique de format.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer les modules nécessaires
Import-Module "$PSScriptRoot\InputSegmentation.psm1" -Force -ErrorAction Stop
. "$PSScriptRoot\UnifiedSegmenter.ps1" -ErrorAction Stop

# Variables globales
$script:IsInitialized = $false

# Fonction pour initialiser le module d'intégration
function Initialize-FormatSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PythonPath = "python",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxInputSizeKB = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultChunkSizeKB = 5,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines
    )
    
    # Initialiser le module InputSegmentation
    Initialize-InputSegmentation -MaxInputSizeKB $MaxInputSizeKB -DefaultChunkSizeKB $DefaultChunkSizeKB
    
    # Initialiser le segmenteur unifié
    $result = Initialize-UnifiedSegmenter -PythonPath $PythonPath -MaxInputSizeKB $MaxInputSizeKB -DefaultChunkSizeKB $DefaultChunkSizeKB
    
    if ($result) {
        $script:IsInitialized = $true
        Write-Verbose "Module d'intégration initialisé avec succès."
    } else {
        Write-Error "Échec de l'initialisation du segmenteur unifié."
    }
    
    return $script:IsInitialized
}

# Fonction pour segmenter une entrée avec détection de format
function Split-FormatAwareInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Input,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT")]
        [string]$Format = "AUTO",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDir,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines,
        
        [Parameter(Mandatory = $false)]
        [string]$XPathExpression,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "paragraph", "sentence", "word", "char")]
        [string]$TextMethod = "auto"
    )
    
    begin {
        # Vérifier que le module est initialisé
        if (-not $script:IsInitialized) {
            $result = Initialize-FormatSegmentation
            if (-not $result) {
                throw "Le module d'intégration n'est pas initialisé. Utilisez Initialize-FormatSegmentation."
            }
        }
        
        # Créer le répertoire de sortie si spécifié
        if ($OutputDir -and -not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
    }
    
    process {
        # Mesurer la taille de l'entrée
        $sizeKB = Measure-InputSize -Input $Input
        
        # Si l'entrée est plus petite que la taille maximale, la retourner telle quelle
        if ($sizeKB -le $script:MaxInputSizeKB) {
            return $Input
        }
        
        # Traiter selon le type d'entrée
        if ($Input -is [string] -and (Test-Path -Path $Input -PathType Leaf)) {
            # L'entrée est un chemin de fichier
            if ($OutputDir) {
                return Split-File -FilePath $Input -Format $Format -OutputDir $OutputDir -ChunkSizeKB $ChunkSizeKB -PreserveStructure:$PreserveStructure -XPathExpression $XPathExpression -TextMethod $TextMethod
            } else {
                # Si aucun répertoire de sortie n'est spécifié, utiliser Split-FileInput
                return Split-FileInput -FilePath $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
            }
        } elseif ($Input -is [PSCustomObject] -or $Input -is [hashtable] -or $Input -is [array]) {
            # L'entrée est un objet PowerShell (probablement JSON)
            if ($Format -eq "AUTO" -or $Format -eq "JSON") {
                if ($OutputDir) {
                    # Créer un fichier temporaire pour l'objet JSON
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $Input | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8
                    
                    # Segmenter le fichier
                    $result = Split-File -FilePath $tempFile -Format "JSON" -OutputDir $OutputDir -ChunkSizeKB $ChunkSizeKB -PreserveStructure:$PreserveStructure
                    
                    # Supprimer le fichier temporaire
                    Remove-Item -Path $tempFile -Force
                    
                    return $result
                } else {
                    # Utiliser Split-JsonInput
                    return Split-JsonInput -JsonObject $Input -ChunkSizeKB $ChunkSizeKB
                }
            } else {
                # Convertir l'objet en chaîne selon le format spécifié
                $tempFile = [System.IO.Path]::GetTempFileName()
                
                if ($Format -eq "XML") {
                    $xml = ConvertTo-Xml -InputObject $Input -Depth 10 -NoTypeInformation
                    $xml.Save($tempFile)
                } else {
                    # Format TEXT
                    $Input | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8
                }
                
                # Segmenter le fichier
                $result = Split-File -FilePath $tempFile -Format $Format -OutputDir $OutputDir -ChunkSizeKB $ChunkSizeKB -PreserveStructure:$PreserveStructure -XPathExpression $XPathExpression -TextMethod $TextMethod
                
                # Supprimer le fichier temporaire
                Remove-Item -Path $tempFile -Force
                
                return $result
            }
        } elseif ($Input -is [string]) {
            # L'entrée est une chaîne
            if ($Format -eq "AUTO") {
                # Essayer de détecter le format
                $detectedFormat = "TEXT"
                
                # Essayer de parser comme JSON
                try {
                    $null = $Input | ConvertFrom-Json
                    $detectedFormat = "JSON"
                }
                catch {}
                
                # Essayer de parser comme XML
                if ($detectedFormat -eq "TEXT") {
                    try {
                        $null = [xml]$Input
                        $detectedFormat = "XML"
                    }
                    catch {}
                }
                
                $Format = $detectedFormat
            }
            
            if ($OutputDir) {
                # Créer un fichier temporaire pour la chaîne
                $tempFile = [System.IO.Path]::GetTempFileName()
                Set-Content -Path $tempFile -Value $Input -Encoding UTF8
                
                # Segmenter le fichier
                $result = Split-File -FilePath $tempFile -Format $Format -OutputDir $OutputDir -ChunkSizeKB $ChunkSizeKB -PreserveStructure:$PreserveStructure -XPathExpression $XPathExpression -TextMethod $TextMethod
                
                # Supprimer le fichier temporaire
                Remove-Item -Path $tempFile -Force
                
                return $result
            } else {
                # Segmenter la chaîne selon le format
                switch ($Format) {
                    "JSON" {
                        try {
                            $json = $Input | ConvertFrom-Json
                            return Split-JsonInput -JsonObject $json -ChunkSizeKB $ChunkSizeKB
                        }
                        catch {
                            Write-Warning "Erreur lors du parsing JSON. Traitement comme texte."
                            return Split-TextInput -Text $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
                        }
                    }
                    "XML" {
                        try {
                            $tempFile = [System.IO.Path]::GetTempFileName()
                            [xml]$Input | Set-Content -Path $tempFile -Encoding UTF8
                            
                            # Utiliser Split-FileInput pour le fichier XML
                            $result = Split-FileInput -FilePath $tempFile -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
                            
                            # Supprimer le fichier temporaire
                            Remove-Item -Path $tempFile -Force
                            
                            return $result
                        }
                        catch {
                            Write-Warning "Erreur lors du parsing XML. Traitement comme texte."
                            return Split-TextInput -Text $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
                        }
                    }
                    default {
                        # Format TEXT
                        return Split-TextInput -Text $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
                    }
                }
            }
        } else {
            # Type d'entrée non pris en charge, utiliser Split-Input
            return Split-Input -Input $Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:$PreserveLines
        }
    }
}

# Fonction pour traiter une entrée avec segmentation automatique selon le format
function Invoke-WithFormatSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Input,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT")]
        [string]$Format = "AUTO",
        
        [Parameter(Mandatory = $false)]
        [string]$Id = "",
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveLines,
        
        [Parameter(Mandatory = $false)]
        [switch]$ContinueFromLastState
    )
    
    # Vérifier que le module est initialisé
    if (-not $script:IsInitialized) {
        $result = Initialize-FormatSegmentation
        if (-not $result) {
            throw "Le module d'intégration n'est pas initialisé. Utilisez Initialize-FormatSegmentation."
        }
    }
    
    # Générer un ID unique si non fourni
    if (-not $Id) {
        $Id = [guid]::NewGuid().ToString()
    }
    
    # Créer un répertoire temporaire pour les segments
    $tempDir = Join-Path -Path $env:TEMP -ChildPath "FormatSegmentation_$Id"
    if (Test-Path -Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # Segmenter l'entrée
    $segments = Split-FormatAwareInput -Input $Input -Format $Format -OutputDir $tempDir -ChunkSizeKB $ChunkSizeKB -PreserveStructure:$PreserveStructure -PreserveLines:$PreserveLines
    
    # Si aucun segment n'a été créé, traiter l'entrée directement
    if (-not $segments -or $segments.Count -eq 0) {
        Write-Verbose "Aucun segment créé. Traitement de l'entrée directement."
        return & $ScriptBlock $Input
    }
    
    # Créer un fichier de log
    $logFile = Join-Path -Path $tempDir -ChildPath "segmentation.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Début du traitement avec segmentation. $($segments.Count) segments." | Out-File -FilePath $logFile -Encoding utf8
    
    # Créer un état de segmentation
    $state = [PSCustomObject]@{
        Id = $Id
        TotalSegments = $segments.Count
        Segments = $segments
        CurrentIndex = 0
        Results = @()
    }
    
    # Sauvegarder l'état initial
    Save-SegmentationState -Id $Id -Segments $segments -CurrentIndex 0
    
    # Récupérer l'état précédent si demandé
    if ($ContinueFromLastState) {
        $previousState = Get-SegmentationState -Id $Id
        if ($previousState) {
            $state.CurrentIndex = $previousState.CurrentIndex
            $state.Results = $previousState.Results
            "[$timestamp] Reprise du traitement à partir du segment $($state.CurrentIndex + 1)/$($state.TotalSegments)." | Out-File -FilePath $logFile -Encoding utf8 -Append
        }
    }
    
    # Traiter chaque segment
    $results = @()
    
    for ($i = $state.CurrentIndex; $i -lt $state.TotalSegments; $i++) {
        $segment = $segments[$i]
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] Traitement du segment $($i + 1)/$($state.TotalSegments): $segment" | Out-File -FilePath $logFile -Encoding utf8 -Append
        
        try {
            # Charger le segment
            $segmentContent = Get-Content -Path $segment -Raw
            
            # Convertir le segment selon le format
            $segmentData = $segmentContent
            
            if ($Format -eq "JSON" -or ($Format -eq "AUTO" -and $segment -like "*.json")) {
                $segmentData = $segmentContent | ConvertFrom-Json
            }
            elseif ($Format -eq "XML" -or ($Format -eq "AUTO" -and $segment -like "*.xml")) {
                $segmentData = [xml]$segmentContent
            }
            
            # Traiter le segment
            $result = & $ScriptBlock $segmentData
            $results += $result
            
            # Mettre à jour l'état
            $state.Results += $result
            $state.CurrentIndex = $i + 1
            
            # Sauvegarder l'état
            Save-SegmentationState -Id $Id -Segments $segments -CurrentIndex $state.CurrentIndex -Results $state.Results
            
            "[$timestamp] Segment $($i + 1)/$($state.TotalSegments) traité avec succès." | Out-File -FilePath $logFile -Encoding utf8 -Append
        }
        catch {
            "[$timestamp] Erreur lors du traitement du segment $($i + 1): $_" | Out-File -FilePath $logFile -Encoding utf8 -Append
            
            # Sauvegarder l'état pour pouvoir reprendre plus tard
            Save-SegmentationState -Id $Id -Segments $state.Segments -CurrentIndex $i
            
            throw $_
        }
    }
    
    "[$timestamp] Traitement terminé. $($state.TotalSegments) segments traités." | Out-File -FilePath $logFile -Encoding utf8 -Append
    
    # Nettoyer les fichiers temporaires si tout s'est bien passé
    if (-not $ContinueFromLastState) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    
    return $results
}

# Fonction pour analyser une entrée selon son format
function Get-FormatAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Input,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT")]
        [string]$Format = "AUTO",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFile
    )
    
    begin {
        # Vérifier que le module est initialisé
        if (-not $script:IsInitialized) {
            $result = Initialize-FormatSegmentation
            if (-not $result) {
                throw "Le module d'intégration n'est pas initialisé. Utilisez Initialize-FormatSegmentation."
            }
        }
    }
    
    process {
        # Traiter selon le type d'entrée
        if ($Input -is [string] -and (Test-Path -Path $Input -PathType Leaf)) {
            # L'entrée est un chemin de fichier
            return Get-FileAnalysis -FilePath $Input -Format $Format -OutputFile $OutputFile
        } elseif ($Input -is [PSCustomObject] -or $Input -is [hashtable] -or $Input -is [array]) {
            # L'entrée est un objet PowerShell (probablement JSON)
            # Créer un fichier temporaire pour l'objet
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            if ($Format -eq "AUTO" -or $Format -eq "JSON") {
                # Enregistrer comme JSON
                $Input | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8
                $actualFormat = "JSON"
            } elseif ($Format -eq "XML") {
                # Enregistrer comme XML
                $xml = ConvertTo-Xml -InputObject $Input -Depth 10 -NoTypeInformation
                $xml.Save($tempFile)
                $actualFormat = "XML"
            } else {
                # Enregistrer comme texte
                $Input | Out-String | Set-Content -Path $tempFile -Encoding UTF8
                $actualFormat = "TEXT"
            }
            
            # Analyser le fichier
            $result = Get-FileAnalysis -FilePath $tempFile -Format $actualFormat -OutputFile $OutputFile
            
            # Supprimer le fichier temporaire
            Remove-Item -Path $tempFile -Force
            
            return $result
        } elseif ($Input -is [string]) {
            # L'entrée est une chaîne
            # Créer un fichier temporaire pour la chaîne
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            if ($Format -eq "AUTO") {
                # Essayer de détecter le format
                $detectedFormat = "TEXT"
                
                # Essayer de parser comme JSON
                try {
                    $null = $Input | ConvertFrom-Json
                    $detectedFormat = "JSON"
                }
                catch {}
                
                # Essayer de parser comme XML
                if ($detectedFormat -eq "TEXT") {
                    try {
                        $null = [xml]$Input
                        $detectedFormat = "XML"
                    }
                    catch {}
                }
                
                $actualFormat = $detectedFormat
            } else {
                $actualFormat = $Format
            }
            
            # Enregistrer la chaîne dans le fichier temporaire
            Set-Content -Path $tempFile -Value $Input -Encoding UTF8
            
            # Analyser le fichier
            $result = Get-FileAnalysis -FilePath $tempFile -Format $actualFormat -OutputFile $OutputFile
            
            # Supprimer le fichier temporaire
            Remove-Item -Path $tempFile -Force
            
            return $result
        } else {
            # Type d'entrée non pris en charge
            Write-Error "Type d'entrée non pris en charge pour l'analyse."
            return $null
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-FormatSegmentation, Split-FormatAwareInput, Invoke-WithFormatSegmentation, Get-FormatAnalysis
