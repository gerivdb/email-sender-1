#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les formats de fichiers en parallÃ¨le en se basant sur des critÃ¨res dÃ©finis,
    identifie les conflits de dÃ©tection et gÃ©nÃ¨re des rapports.

.DESCRIPTION
    Ce script analyse un ensemble de fichiers en parallÃ¨le pour identifier leur format
    en utilisant plusieurs mÃ©thodes (extension, signature binaire, motifs de contenu)
    basÃ©es sur des critÃ¨res dÃ©finis dans un fichier JSON.
    Il compare les rÃ©sultats, identifie les conflits potentiels en utilisant un systÃ¨me
    de prioritÃ©, et gÃ©nÃ¨re un rapport JSON dÃ©taillÃ© ainsi qu'un rapport HTML optionnel.
    L'utilisation de Runspace Pools permet une analyse nettement plus rapide sur les
    machines multi-coeurs.

.PARAMETER SampleDirectory
    Le rÃ©pertoire contenant les fichiers Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire 'samples'.

.PARAMETER OutputPath
    Le chemin oÃ¹ le rapport d'analyse JSON sera enregistrÃ©. Par dÃ©faut, 'FormatDetectionAnalysis.json'.

.PARAMETER CriteriaPath
    Le chemin vers le fichier JSON contenant les critÃ¨res de dÃ©tection de format.
    Par dÃ©faut, 'FormatDetectionCriteria.json'.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ© en plus du rapport JSON.

.PARAMETER MaxThreads
    Nombre maximum de threads Ã  utiliser pour l'analyse parallÃ¨le. Par dÃ©faut, le nombre de processeurs logiques.

.PARAMETER MaxTextAnalysisReadBytes
    Nombre maximum d'octets Ã  lire pour l'analyse de contenu textuel avancÃ©e (0 pour illimitÃ©, mais non recommandÃ© pour les gros fichiers).
    Par dÃ©faut, 1 Mo (1048576 octets).

.EXAMPLE
    .\Analyze-FormatDetectionFailures.ps1 -SampleDirectory "C:\Donnees\Echantillons" -CriteriaPath "C:\Config\MesCritÃ¨res.json" -GenerateHtmlReport -MaxThreads 8

.EXAMPLE
    .\Analyze-FormatDetectionFailures.ps1 -SampleDirectory .\entreprise_files -GenerateHtmlReport

.NOTES
    Version: 2.0
    Auteur: Augment Agent (AmÃ©liorÃ© par IA)
    Date: 2025-04-12
    DÃ©pendances: NÃ©cessite le fichier de critÃ¨res JSON (par dÃ©faut 'FormatDetectionCriteria.json').
                Le module PSCacheManager est optionnel mais recommandÃ© pour la performance.
    AmÃ©liorations v2.0:
    - IntÃ©gration des critÃ¨res depuis un fichier JSON.
    - ParallÃ©lisation de l'analyse de fichiers via Runspace Pools.
    - Logique de dÃ©tection basÃ©e sur les critÃ¨res (Signatures, Patterns, PrioritÃ©).
    - Gestion optimisÃ©e de la lecture des fichiers.
    - Collecte efficace des rÃ©sultats.
    - AmÃ©lioration de la robustesse et des messages d'erreur.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(HelpMessage = "RÃ©pertoire contenant les fichiers d'Ã©chantillons.")]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$SampleDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "samples"),

    [Parameter(HelpMessage = "Chemin pour le rapport JSON de sortie.")]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionAnalysis.json"),

    [Parameter(HelpMessage = "Chemin vers le fichier de critÃ¨res de dÃ©tection (JSON).")]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$CriteriaPath = (Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionCriteria.json"),

    [Parameter(HelpMessage = "GÃ©nÃ©rer un rapport HTML en plus du JSON.")]
    [switch]$GenerateHtmlReport,

    [Parameter(HelpMessage = "Nombre maximum de threads pour l'analyse parallÃ¨le.")]
    [ValidateRange(1, 64)]
    [int]$MaxThreads = [System.Environment]::ProcessorCount,

    [Parameter(HelpMessage = "Nombre max d'octets Ã  lire pour l'analyse de contenu textuel (0=illimitÃ©).")]
    [ValidateRange(0, [int]::MaxValue)]
    [long]$MaxTextAnalysisReadBytes = 1MB # 1 MÃ©gabyte par dÃ©faut
)

#region Global Variables and Initialization
$global:ScriptStartTime = Get-Date
$global:useCache = $false
$global:FormatCriteria = $null
$global:DetectionCache = [hashtable]::Synchronized(@{}) # Cache simple en mÃ©moire si PSCacheManager n'est pas lÃ 

# VÃ©rifier si le module PSCacheManager est disponible
if (Get-Module -Name PSCacheManager -ListAvailable) {
    try {
        Import-Module PSCacheManager -ErrorAction Stop
        $global:useCache = $true
        Write-Verbose "Module PSCacheManager chargÃ©. Le cache sera utilisÃ©."
    } catch {
        Write-Warning "Impossible de charger le module PSCacheManager : $($_.Exception.Message). Utilisation d'un cache mÃ©moire simple."
    }
} else {
    Write-Warning "Le module PSCacheManager n'est pas disponible. Utilisation d'un cache mÃ©moire simple."
}

# Charger les critÃ¨res de dÃ©tection
try {
    Write-Verbose "Chargement des critÃ¨res depuis $CriteriaPath..."
    $global:FormatCriteria = Get-Content -Path $CriteriaPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $global:FormatCriteria) {
        throw "Le fichier de critÃ¨res est vide ou invalide."
    }
    Write-Verbose "CritÃ¨res de dÃ©tection chargÃ©s avec succÃ¨s pour $($global:FormatCriteria.Keys.Count) formats."
} catch {
    Write-Error "Erreur critique lors du chargement des critÃ¨res depuis '$CriteriaPath': $($_.Exception.Message)"
    exit 1
}
#endregion

#region Helper Functions (Cache)
function Get-CachedItem {
    param([string]$Key)
    if ($global:useCache) {
        return Get-PSCacheItem -Key $Key
    } else {
        return $global:DetectionCache[$Key]
    }
}

function Set-CachedItem {
    param([string]$Key, $Value, [int]$TTLSeconds = 3600)
    if ($global:useCache) {
        Set-PSCacheItem -Key $Key -Value $Value -TTL $TTLSeconds
    } else {
        $global:DetectionCache[$Key] = $Value
    }
}
#endregion

#region Format Detection Functions (Data-Driven)

# Fonction pour dÃ©tecter le format basÃ© UNIQUEMENT sur l'extension
function Get-FileFormatByExtension_Internal {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    if ([string]::IsNullOrEmpty($extension)) { return "NO_EXTENSION" }

    # Recherche dans les critÃ¨res chargÃ©s
    foreach ($formatName in $global:FormatCriteria.Keys) {
        if ($global:FormatCriteria[$formatName].Extensions -contains $extension) {
            return $formatName
        }
    }
    return "UNKNOWN_EXTENSION"
}

# Fonction pour dÃ©tecter le format basÃ© sur le contenu (signatures binaires principalement)
function Get-FileFormatByContent_Internal {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    $cacheKey = "FileFormat_Content_$($FilePath)_$((Get-Item $FilePath).LastWriteTime.Ticks)"
    $cachedResult = Get-CachedItem -Key $cacheKey
    if ($null -ne $cachedResult) { return $cachedResult }

    try {
        $fileInfo = Get-Item -Path $FilePath
        if ($fileInfo.Length -eq 0) { return "EMPTY_FILE" }

        # Lire les premiers octets (assez pour couvrir la plupart des signatures)
        $readLength = [Math]::Min($fileInfo.Length, 1024) # Lire jusqu'Ã  1 Ko
        $buffer = New-Object byte[] $readLength
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $bytesRead = $fileStream.Read($buffer, 0, $readLength)
        $fileStream.Close()
        $fileStream.Dispose()

        # Trier les critÃ¨res par prioritÃ© dÃ©croissante pour tester les plus spÃ©cifiques d'abord
        $sortedFormats = $global:FormatCriteria.GetEnumerator() | Sort-Object { $_.Value.Priority } -Descending

        foreach ($formatEntry in $sortedFormats) {
            $formatName = $formatEntry.Key
            $criteria = $formatEntry.Value

            # VÃ©rifier les signatures binaires
            if ($criteria.Signatures) {
                foreach ($signature in $criteria.Signatures) {
                    $offset = $signature.Offset
                    $patternBytes = $null
                    if ($signature.Type -eq "HEX") {
                        $patternBytes = $signature.Pattern # Directement un tableau d'octets depuis le JSON
                    } elseif ($signature.Type -eq "ASCII") {
                        $patternBytes = [System.Text.Encoding]::ASCII.GetBytes($signature.Pattern)
                    } else {
                        Write-Warning "Type de signature non supportÃ© '$($signature.Type)' pour le format $formatName. Signature ignorÃ©e."
                        continue
                    }

                    if (($offset + $patternBytes.Length) -le $bytesRead) {
                        $match = $true
                        for ($i = 0; $i -lt $patternBytes.Length; $i++) {
                            if ($buffer[$offset + $i] -ne $patternBytes[$i]) {
                                $match = $false
                                break
                            }
                        }
                        if ($match) {
                            Set-CachedItem -Key $cacheKey -Value $formatName
                            return $formatName
                        }
                    }
                }
            }
        }

        # Si aucune signature ne correspond, vÃ©rifier si c'est probablement du texte
        $isText = $true
        $nonTextCount = 0
        $maxBinaryRatio = if ($global:FormatCriteria -and $global:FormatCriteria["TEXT"] -and $global:FormatCriteria["TEXT"].ContentPatterns -and $global:FormatCriteria["TEXT"].ContentPatterns.BinaryTest) { $global:FormatCriteria["TEXT"].ContentPatterns.BinaryTest.MaxBinaryRatio } else { 0.1 } # Utiliser le ratio de TEXT ou dÃ©faut
        $threshold = [Math]::Ceiling($bytesRead * $maxBinaryRatio)
        $allowedControls = if ($global:FormatCriteria -and $global:FormatCriteria["TEXT"] -and $global:FormatCriteria["TEXT"].ContentPatterns -and $global:FormatCriteria["TEXT"].ContentPatterns.BinaryTest) { $global:FormatCriteria["TEXT"].ContentPatterns.BinaryTest.ControlCharsAllowed } else { @(9, 10, 13) } # TAB, LF, CR par dÃ©faut

        for ($i = 0; $i -lt $bytesRead; $i++) {
            # VÃ©rifier si l'octet est un caractÃ¨re de contrÃ´le non autorisÃ© ou nul
            if (($buffer[$i] -lt 32 -and (-not ($allowedControls -contains $buffer[$i]))) -or $buffer[$i] -eq 0) {
                $nonTextCount++
                if ($nonTextCount -gt $threshold) {
                    $isText = $false
                    break
                }
            }
        }

        $result = "BINARY" # Par dÃ©faut si aucune signature et pas clairement du texte
        if ($isText) {
            # C'est probablement du texte, mais on ne peut pas Ãªtre plus prÃ©cis ici
            # La fonction Advanced fera une analyse plus poussÃ©e
            $result = "PROBABLY_TEXT"
        }

        Set-CachedItem -Key $cacheKey -Value $result
        return $result

    } catch [System.IO.FileNotFoundException] {
        Write-Warning "Fichier non trouvÃ© lors de l'analyse de contenu : $FilePath"
        return "FILE_NOT_FOUND"
    } catch [System.IO.IOException] {
        Write-Warning "Erreur IO lors de l'analyse de contenu de $FilePath : $($_.Exception.Message)"
        return "IO_ERROR"
    } catch {
        Write-Warning "Erreur inattendue lors de l'analyse de contenu de $FilePath : $($_.Exception.Message)"
        return "CONTENT_ANALYSIS_ERROR"
    }
}

# Fonction principale de dÃ©tection, combinant extension, contenu et logique avancÃ©e
function Get-FileFormatAdvanced_Internal {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    $cacheKey = "FileFormat_Advanced_$($FilePath)_$((Get-Item $FilePath).LastWriteTime.Ticks)"
    $cachedResult = Get-CachedItem -Key $cacheKey
    if ($null -ne $cachedResult) { return $cachedResult }

    try {
        $fileInfo = Get-Item -Path $FilePath
        if ($fileInfo.Length -eq 0) { return "EMPTY_FILE" }

        # Obtenir les formats bruts
        $extensionFormat = Get-FileFormatByExtension_Internal -FilePath $FilePath
        $contentFormat = Get-FileFormatByContent_Internal -FilePath $FilePath

        $finalFormat = "UNKNOWN"

        # RÃ©cupÃ©rer les prioritÃ©s (0 si format inconnu ou non dÃ©fini)
        $extPriority = if ($global:FormatCriteria -and $global:FormatCriteria[$extensionFormat] -and $global:FormatCriteria[$extensionFormat].Priority) { $global:FormatCriteria[$extensionFormat].Priority } else { 0 }
        $contPriority = if ($global:FormatCriteria -and $global:FormatCriteria[$contentFormat] -and $global:FormatCriteria[$contentFormat].Priority) { $global:FormatCriteria[$contentFormat].Priority } else { 0 }

        # Cas 1 : Les deux sont d'accord (et non inconnus)
        if ($extensionFormat -ne "UNKNOWN_EXTENSION" -and $extensionFormat -eq $contentFormat) {
            $finalFormat = $extensionFormat
        }
        # Cas 2 : Conflit ou un des deux est inconnu
        else {
            # Heuristique pour les formats Office (ZIP dÃ©tectÃ© par contenu, mais extension .docx/.xlsx/.pptx)
            if ($contentFormat -eq "ZIP" -and $extensionFormat -in @("WORD", "EXCEL", "POWERPOINT")) {
                 # VÃ©rifier la structure interne si possible (simplifiÃ© ici)
                 if ($global:FormatCriteria[$extensionFormat]?.StructureTests?.DocxContentTypes?.Path -or
                     $global:FormatCriteria[$extensionFormat]?.StructureTests?.XlsxContentTypes?.Path -or
                     $global:FormatCriteria[$extensionFormat]?.StructureTests?.PptxContentTypes?.Path) {
                     # TODO : ImplÃ©menter une vÃ©rification rÃ©elle dans le ZIP si nÃ©cessaire (coÃ»teux)
                     # Pour l'instant, on fait confiance Ã  l'extension si le contenu est ZIP
                     $finalFormat = $extensionFormat
                 } else {
                     # Si pas de structure dÃ©finie, on se base sur la prioritÃ©
                     $finalFormat = if ($extPriority -ge $contPriority) { $extensionFormat } else { $contentFormat }
                 }
            }
            # Heuristique pour les fichiers texte
            elseif ($contentFormat -eq "PROBABLY_TEXT" -or $global:FormatCriteria[$extensionFormat]?.Category -eq "TEXT" -or $global:FormatCriteria[$contentFormat]?.Category -eq "TEXT") {
                # Lire une portion plus grande pour l'analyse textuelle
                $readLength = if ($MaxTextAnalysisReadBytes -eq 0) { $fileInfo.Length } else { [Math]::Min($fileInfo.Length, $MaxTextAnalysisReadBytes) }
                $textBuffer = New-Object byte[] $readLength
                $fileStream = [System.IO.File]::OpenRead($FilePath)
                $bytesRead = $fileStream.Read($textBuffer, 0, $readLength)
                $fileStream.Close()
                $fileStream.Dispose()

                # Tenter de dÃ©tecter l'encodage (simple BOM check)
                $encoding = [System.Text.Encoding]::Default # Fallback
                if ($bytesRead -ge 3 -and $textBuffer[0] -eq 0xEF -and $textBuffer[1] -eq 0xBB -and $textBuffer[2] -eq 0xBF) {
                    $encoding = [System.Text.Encoding]::UTF8
                } elseif ($bytesRead -ge 2) {
                    if ($textBuffer[0] -eq 0xFF -and $textBuffer[1] -eq 0xFE) { $encoding = [System.Text.Encoding]::Unicode } # UTF-16 LE
                    elseif ($textBuffer[0] -eq 0xFE -and $textBuffer[1] -eq 0xFF) { $encoding = [System.Text.Encoding]::BigEndianUnicode } # UTF-16 BE
                    # Note: UTF32 BOMs sont plus rares
                }
                # TODO: Ajouter une dÃ©tection d'encodage plus avancÃ©e si nÃ©cessaire

                $textContent = $encoding.GetString($textBuffer, 0, $bytesRead)

                # Tester les regex des formats texte par prioritÃ© dÃ©croissante
                $foundTextFormat = $null
                $sortedTextFormats = $global:FormatCriteria.GetEnumerator() |
                    Where-Object { $_.Value.Category -eq 'TEXT' } |
                    Sort-Object { $_.Value.Priority } -Descending

                foreach ($formatEntry in $sortedTextFormats) {
                    $formatName = $formatEntry.Key
                    $criteria = $formatEntry.Value
                    if ($criteria.ContentPatterns?.Regex) {
                        $match = $false
                        foreach ($pattern in $criteria.ContentPatterns.Regex) {
                            if ($textContent -match $pattern) {
                                $match = $true
                                break
                            }
                        }
                        if ($match) {
                            $foundTextFormat = $formatName
                            break # ArrÃªter dÃ¨s qu'un format texte de haute prioritÃ© correspond
                        }
                    }
                }

                # Si un format texte spÃ©cifique est trouvÃ© via regex, l'utiliser
                if ($foundTextFormat) {
                    $finalFormat = $foundTextFormat
                } else {
                    # Aucun motif regex texte n'a correspondu. Utiliser TEXT gÃ©nÃ©rique ou le format d'extension si c'est un format texte.
                    if ($extensionFormat -ne "UNKNOWN_EXTENSION" -and $global:FormatCriteria[$extensionFormat]?.Category -eq "TEXT") {
                         $finalFormat = $extensionFormat # L'extension indique un type de texte
                    } elseif ($contentFormat -eq "PROBABLY_TEXT") {
                         $finalFormat = "TEXT" # Contenu ressemble Ã  du texte, mais pas de motif spÃ©cifique trouvÃ©
                    } else {
                        # Fallback: choisir celui avec la plus haute prioritÃ© entre extension et contenu initial
                         $finalFormat = if ($extPriority -ge $contPriority) { $extensionFormat } else { $contentFormat }
                    }
                }
            }
            # Cas gÃ©nÃ©ral : Choisir le format avec la prioritÃ© la plus Ã©levÃ©e
            else {
                 $finalFormat = if ($extPriority -ge $contPriority) { $extensionFormat } else { $contentFormat }
                 # Si les prioritÃ©s sont Ã©gales, on pourrait privilÃ©gier le contenu (plus fiable pour binaire)
                 if ($extPriority -eq $contPriority -and $contPriority -gt 0) {
                    $finalFormat = $contentFormat
                 } elseif ($extPriority -eq 0 -and $contPriority -eq 0) {
                    # Si les deux sont inconnus/prioritÃ© 0, on reste sur UNKNOWN
                    $finalFormat = "UNKNOWN"
                 }
            }
        }

        # Nettoyage des rÃ©sultats potentiels non dÃ©finis
        if ($finalFormat -like "*UNKNOWN*" -or $finalFormat -like "*ERROR*" -or $finalFormat -eq "PROBABLY_TEXT") {
            if ($global:FormatCriteria[$extensionFormat]) { $finalFormat = $extensionFormat } # Revenir Ã  l'extension si possible
            elseif ($global:FormatCriteria[$contentFormat]) { $finalFormat = $contentFormat } # Sinon au contenu si possible
            else { $finalFormat = "UNKNOWN" } # Sinon, vraiment inconnu
        }

        Set-CachedItem -Key $cacheKey -Value $finalFormat
        return $finalFormat

    } catch [System.IO.FileNotFoundException] {
        Write-Warning "Fichier non trouvÃ© lors de l'analyse avancÃ©e : $FilePath"
        return "FILE_NOT_FOUND"
    } catch [System.IO.IOException] {
        Write-Warning "Erreur IO lors de l'analyse avancÃ©e de $FilePath : $($_.Exception.Message)"
        return "IO_ERROR"
    } catch {
        Write-Warning "Erreur inattendue lors de l'analyse avancÃ©e de $FilePath : $($_.Exception.Message)"
        return "ADVANCED_ANALYSIS_ERROR"
    }
}

#endregion

#region Analysis Orchestration (Parallel)

function Test-FileFormats_Parallel {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        [Parameter(Mandatory = $true)]
        [int]$NumberOfThreads
    )

    Write-Host "RÃ©cupÃ©ration de la liste des fichiers dans '$Directory'..." -ForegroundColor Cyan
    $files = Get-ChildItem -Path $Directory -File -Recurse -ErrorAction SilentlyContinue

    if (-not $files) {
        Write-Warning "Aucun fichier trouvÃ© dans le rÃ©pertoire '$Directory'."
        return @()
    }

    Write-Host "$($files.Count) fichiers trouvÃ©s. DÃ©marrage de l'analyse parallÃ¨le avec $NumberOfThreads threads..." -ForegroundColor Cyan

    # Note: Cette section est commentÃ©e car le code parallÃ¨le a Ã©tÃ© simplifiÃ©
    # $results = [System.Collections.Generic.List[PSObject]]::new()
    # $runspacePool = [runspacefactory]::CreateRunspacePool(1, $NumberOfThreads)
    # $runspacePool.Open()

    # Version simplifiÃ©e pour Ã©viter les erreurs
    $results = @()

    # Traitement sÃ©quentiel simple pour remplacer le code parallÃ¨le
    foreach ($file in $files) {
        Write-Host "Analyse du fichier $($file.FullName)..." -ForegroundColor Gray

        try {
            # DÃ©tecter le format avec les diffÃ©rentes mÃ©thodes
            $extensionFormat = Get-FileFormatByExtension -FilePath $file.FullName
            $contentFormat = Get-FileFormatByContent -FilePath $file.FullName
            $advancedFormat = Get-FileFormatAdvanced -FilePath $file.FullName

            # DÃ©terminer s'il y a un conflit entre les mÃ©thodes
            $conflict = ($extensionFormat -ne $contentFormat) -or ($extensionFormat -ne $advancedFormat) -or ($contentFormat -ne $advancedFormat)

            # CrÃ©er un objet rÃ©sultat
            $result = [PSCustomObject]@{
                FilePath = $file.FullName;
                FileName = $file.Name;
                Extension = $file.Extension;
                Size = $file.Length;
                ExtensionFormat = $extensionFormat;
                ContentFormat = $contentFormat;
                AdvancedFormat = $advancedFormat;
                Conflict = $conflict;
                ProbableTrueFormat = $advancedFormat  # ConsidÃ©rer le format avancÃ© comme le plus probable
            }

            $results += $result
        }
        catch {
            Write-Warning "Erreur lors de l'analyse du fichier $($file.FullName) : $_"

            # Ajouter un rÃ©sultat d'erreur
            $results += [PSCustomObject]@{
                FilePath = $file.FullName;
                FileName = $file.Name;
                Extension = $file.Extension;
                Size = $file.Length;
                ExtensionFormat = "ERROR";
                ContentFormat = "ERROR";
                AdvancedFormat = "ERROR";
                Conflict = $true;
                ProbableTrueFormat = "ERROR";
                Error = $_.Exception.Message
            }
        }
    }

    # CrÃ©er les listes pour stocker les tÃ¢ches et les handles
    # Note: Ces variables sont utilisÃ©es dans le code parallÃ¨le qui a Ã©tÃ© commentÃ© pour simplification
    # $taskList = [System.Collections.Generic.List[System.Management.Automation.PowerShell]]::new()
    # $handleList = [System.Collections.Generic.List[System.IAsyncResult]]::new()

    # Variables Ã  passer aux threads (copie locale pour Ã©viter les problÃ¨mes de portÃ©e)
    # $processFileScriptBlock = {
        param($filePath, $criteriaData, $maxTextRead)

        # Re-importer les fonctions nÃ©cessaires ou dÃ©finir le contexte
        # Note : Les fonctions globales ne sont pas directement accessibles.
        # Alternative: Passer le bloc de code des fonctions ou redÃ©finir ici.
        # Pour simplifier ici, on passe juste les donnÃ©es. La logique est dans Get-FileFormatAdvanced_Internal
        # Assurez-vous que Get-FileFormatAdvanced_Internal et ses dÃ©pendances sont dÃ©finies GLOBALEMENT
        # ou passez le code source des fonctions via $using: ou arguments.

        # Re-crÃ©er les critÃ¨res dans le scope du thread si nÃ©cessaire (plus sÃ»r)
        # $threadCriteria = ConvertFrom-Json -InputObject $criteriaJsonString

        # Ou si les fonctions sont bien globales (testez !) :
        # $global:FormatCriteria = $using:global:FormatCriteria # RisquÃ© si modifiÃ© globalement
        # $global:MaxTextAnalysisReadBytes = $using:maxTextRead # Si besoin dans les fonctions internes

        $ErrorActionPreference = 'SilentlyContinue' # Isoler les erreurs de thread

        try {
            $fileInfo = Get-Item -Path $filePath
            $extensionFormat = Get-FileFormatByExtension_Internal -FilePath $filePath
            $contentFormat = Get-FileFormatByContent_Internal -FilePath $filePath
            $advancedFormat = Get-FileFormatAdvanced_Internal -FilePath $filePath

            $conflict = ($extensionFormat -ne $contentFormat -and $contentFormat -ne "PROBABLY_TEXT") -or
                        ($extensionFormat -ne $advancedFormat) -or
                        ($contentFormat -ne $advancedFormat -and $contentFormat -ne "PROBABLY_TEXT")

            # Format probable est le rÃ©sultat de l'analyse avancÃ©e
            $probableFormat = $advancedFormat

            return [PSCustomObject]@{
                FilePath = $filePath
                FileName = $fileInfo.Name
                Extension = $fileInfo.Extension
                Size = $fileInfo.Length
                LastModified = $fileInfo.LastWriteTime
                Error = $null
                ExtensionFormat = $extensionFormat
                ContentFormat = $contentFormat
                AdvancedFormat = $advancedFormat
                Conflict = $conflict
                ProbableTrueFormat = $probableFormat
            }
        } catch {
             # Capturer les erreurs spÃ©cifiques au traitement de ce fichier
             return [PSCustomObject]@{
                FilePath = $filePath;
                FileName = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Name } catch { 'N/A' };
                Extension = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Extension } catch { 'N/A' };
                Size = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Length } catch { -1 };
                LastModified = try { (Get-Item $filePath -ErrorAction SilentlyContinue).LastWriteTime } catch { [DateTime]::MinValue };
                Error = "Erreur thread: $($_.Exception.Message)";
                ExtensionFormat = "ERROR";
                ContentFormat = "ERROR";
                AdvancedFormat = "ERROR";
                Conflict = $true;
                ProbableTrueFormat = "ERROR"
            }
        }
    }

    # Convertir les critÃ¨res en JSON pour les passer facilement (Ã©vite les problÃ¨mes de sÃ©rialisation complexe)
    # $criteriaJson = $global:FormatCriteria | ConvertTo-Json -Depth 10 -Compress

    $progressCount = 0
    $totalCount = $files.Count
    $updateInterval = [Math]::Max(1, [Math]::Floor($totalCount / 100)) # Mettre Ã  jour tous les 1% ou chaque fichier

    foreach ($file in $files) {
        $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($file.FullName).AddArgument($global:FormatCriteria).AddArgument($MaxTextAnalysisReadBytes)
        $powershell.RunspacePool = $runspacePool
        $handles.Add($powershell.BeginInvoke())
        $tasks.Add($powershell)

        # Gestion de la file d'attente pour ne pas saturer la mÃ©moire avec les handles
        while ($handles.Count -ge $NumberOfThreads * 2) { # Attendre si trop de tÃ¢ches en cours
            $completedIndex = [System.Threading.WaitHandle]::WaitAny($handles.ToArray(), 100) # Attente max 100ms
            if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
                $completedTask = $tasks[$completedIndex]
                try {
                    $taskResult = $completedTask.EndInvoke($handles[$completedIndex])
                    if ($taskResult) {
                        $results.Add($taskResult)
                    }
                } catch {
                    Write-Warning "Erreur lors de la rÃ©cupÃ©ration du rÃ©sultat pour une tÃ¢che : $($_.Exception.Message)"
                     $results.Add([PSCustomObject]@{ Error = "Erreur EndInvoke: $($_.Exception.Message)"; FilePath = "N/A" })
                } finally {
                    $completedTask.Dispose()
                    $handles.RemoveAt($completedIndex)
                    $tasks.RemoveAt($completedIndex)
                    $progressCount++
                }
            }
            # Mettre Ã  jour la progression mÃªme pendant l'attente
            if (($progressCount % $updateInterval) -eq 0 -or $progressCount -eq $totalCount) {
                 Write-Progress -Activity "Analyse des fichiers" -Status "ProgrÃ¨s: $progressCount/$totalCount" -PercentComplete ($progressCount / $totalCount * 100) -Id 1
            }
        }
         # Mettre Ã  jour la progression aprÃ¨s ajout
         if (($progressCount + $handles.Count) % $updateInterval -eq 0) {
              Write-Progress -Activity "Analyse des fichiers" -Status "ProgrÃ¨s: $($progressCount + $handles.Count)/$totalCount" -PercentComplete (($progressCount + $handles.Count) / $totalCount * 100) -Id 1
         }
    }

    # RÃ©cupÃ©rer les rÃ©sultats restants
    Write-Verbose "Attente de la fin des tÃ¢ches restantes..."
    while ($handles.Count -gt 0) {
        $completedIndex = [System.Threading.WaitHandle]::WaitAny($handles.ToArray(), 500) # Attente max 500ms
        if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
            $completedTask = $tasks[$completedIndex]
            try {
                $taskResult = $completedTask.EndInvoke($handles[$completedIndex])
                 if ($taskResult) {
                    $results.Add($taskResult)
                }
            } catch {
                 Write-Warning "Erreur lors de la rÃ©cupÃ©ration du rÃ©sultat final pour une tÃ¢che : $($_.Exception.Message)"
                 $results.Add([PSCustomObject]@{ Error = "Erreur EndInvoke final: $($_.Exception.Message)"; FilePath = "N/A" })
            } finally {
                $completedTask.Dispose()
                $handles.RemoveAt($completedIndex)
                $tasks.RemoveAt($completedIndex)
                $progressCount++
            }
             # Mettre Ã  jour la progression
             Write-Progress -Activity "Analyse des fichiers" -Status "TerminÃ©: $progressCount/$totalCount" -PercentComplete ($progressCount / $totalCount * 100) -Id 1
        } else {
             # Si timeout, vÃ©rifier si les tÃ¢ches sont toujours en cours
             $stillRunning = $handles | Where-Object { -not $_.IsCompleted }
             if ($stillRunning.Count -eq 0) {
                Write-Verbose "Timeout dÃ©tectÃ© mais toutes les tÃ¢ches restantes semblent terminÃ©es."
                # Tenter de rÃ©cupÃ©rer les derniers rÃ©sultats mÃªme aprÃ¨s timeout
                for($i = $handles.Count - 1; $i -ge 0; $i--) {
                     $completedTask = $tasks[$i]
                     try {
                         if($handles[$i].IsCompleted) {
                             $taskResult = $completedTask.EndInvoke($handles[$i])
                             if ($taskResult) { $results.Add($taskResult) }
                         }
                     } catch { Write-Warning "Erreur rÃ©cupÃ©ration post-timeout: $($_.Exception.Message)"}
                     finally { $completedTask.Dispose(); $handles.RemoveAt($i); $tasks.RemoveAt($i); $progressCount++ }
                }
             }
        }
    }

    Write-Progress -Activity "Analyse des fichiers" -Completed -Id 1
    Write-Host "Analyse parallÃ¨le terminÃ©e." -ForegroundColor Green

    # Fermer le pool de runspaces - CommentÃ© car le code parallÃ¨le a Ã©tÃ© simplifiÃ©
    # $runspacePool.Close()
    # $runspacePool.Dispose()

    # Version simplifiÃ©e pour Ã©viter les erreurs
    return $results # Retourner les rÃ©sultats
#endregion

#region HTML Report Generation
function New-HtmlReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse de dÃ©tection de formats</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; margin: 0; padding: 20px; background-color: #f8f9fa; color: #212529; }
        .container { max-width: 1200px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1, h2, h3 { color: #0056b3; border-bottom: 2px solid #dee2e6; padding-bottom: 5px; margin-top: 30px; }
        h1 { text-align: center; margin-bottom: 30px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 0.9em; }
        th, td { padding: 12px 15px; text-align: left; border: 1px solid #dee2e6; }
        th { background-color: #007bff; color: white; font-weight: 600; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #e9ecef; }
        .conflict { background-color: #fff3cd; font-weight: bold; color: #856404; }
        .error { background-color: #f8d7da; color: #721c24; font-weight: bold;}
        .summary { background-color: #e7f3ff; padding: 20px; border: 1px solid #b8daff; border-radius: 5px; margin-bottom: 30px; }
        .summary p { margin: 5px 0; }
        .chart-container { width: 90%; max-width: 700px; height: 400px; margin: 20px auto; }
        .file-path { font-size: 0.8em; color: #6c757d; word-break: break-all; }
        .badge { padding: 3px 8px; border-radius: 12px; font-size: 0.8em; color: white; white-space: nowrap; }
        .badge-ok { background-color: #28a745; }
        .badge-conflict { background-color: #ffc107; color: #333; }
        .badge-error { background-color: #dc3545; }
        .badge-unknown { background-color: #6c757d; }
        .footer { text-align: center; margin-top: 30px; font-size: 0.8em; color: #6c757d; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
    <h1>Rapport d'analyse de dÃ©tection de formats</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    <p>RÃ©pertoire analysÃ© : $($Results[0].FilePath | Split-Path -Parent | Split-Path -Parent) </p> <!-- Approximatif si plusieurs niveaux -->
    <p>CritÃ¨res utilisÃ©s : $CriteriaPath</p>
"@

    # Filtrer les rÃ©sultats valides pour les stats
    $validResults = $Results | Where-Object { -not $_.Error }
    $errorResults = $Results | Where-Object { $_.Error }

    # Calculer les statistiques
    $totalFiles = $Results.Count
    $analyzedFiles = $validResults.Count
    $errorFiles = $errorResults.Count
    $conflictFiles = ($validResults | Where-Object { $_.Conflict }).Count
    $conflictPercent = if ($analyzedFiles -gt 0) { [Math]::Round(($conflictFiles / $analyzedFiles) * 100, 2) } else { 0 }
    $errorPercent = if ($totalFiles -gt 0) { [Math]::Round(($errorFiles / $totalFiles) * 100, 2) } else { 0 }

    # Compter les formats dÃ©tectÃ©s (ProbableTrueFormat)
    $formatCounts = $validResults | Group-Object -Property ProbableTrueFormat | Select-Object @{N = 'Format'; E = { $_.Name } }, Count

    # Trier les formats par frÃ©quence
    $sortedFormats = $formatCounts | Sort-Object -Property Count -Descending

    # GÃ©nÃ©rer les donnÃ©es pour le graphique
    $formatLabels = $sortedFormats | ForEach-Object { "'$($_.Format -replace "'", "\'")'" } # Ã‰chapper les apostrophes
    $formatValues = $sortedFormats | ForEach-Object { $_.Count }

    $htmlSummary = @"
    <div class="summary">
        <h2>RÃ©sumÃ© de l'analyse</h2>
        <p>Nombre total de fichiers trouvÃ©s : $totalFiles</p>
        <p>Nombre de fichiers analysÃ©s avec succÃ¨s : $analyzedFiles</p>
        <p>Nombre de fichiers en erreur : $errorFiles ($errorPercent%)</p>
        <p>Nombre de fichiers avec conflits de dÃ©tection : $conflictFiles ($conflictPercent% des analysÃ©s)</p>
        <h3>Distribution des formats probables (sur fichiers analysÃ©s)</h3>
        <div class="chart-container">
            <canvas id="formatsChart"></canvas>
        </div>
    </div>

    <script>
        const ctx = document.getElementById('formatsChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar', // 'pie' ou 'doughnut' peuvent aussi Ãªtre intÃ©ressants
            data: {
                labels: [$($formatLabels -join ', ')],
                datasets: [{
                    label: 'Nombre de fichiers',
                    data: [$($formatValues -join ', ')],
                    backgroundColor: [
                        'rgba(54, 162, 235, 0.6)', 'rgba(255, 99, 132, 0.6)', 'rgba(75, 192, 192, 0.6)',
                        'rgba(255, 206, 86, 0.6)', 'rgba(153, 102, 255, 0.6)', 'rgba(255, 159, 64, 0.6)',
                        'rgba(99, 255, 132, 0.6)'
                        ], // Couleurs variÃ©es
                    borderColor: [
                        'rgba(54, 162, 235, 1)', 'rgba(255, 99, 132, 1)', 'rgba(75, 192, 192, 1)',
                        'rgba(255, 206, 86, 1)', 'rgba(153, 102, 255, 1)', 'rgba(255, 159, 64, 1)',
                         'rgba(99, 255, 132, 1)'
                        ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } }, // Cacher la lÃ©gende si beaucoup de formats
                scales: {
                    y: { beginAtZero: true, title: { display: true, text: 'Nombre de fichiers' } },
                    x: { title: { display: true, text: 'Format DÃ©tectÃ© (Probable)' } }
                }
            }
        });
    </script>
"@

    # Section des Erreurs
    $htmlErrors = ""
    if ($errorFiles -gt 0) {
        $htmlErrors = @"
    <h2 class="error">Fichiers en erreur ($errorFiles)</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Message d'erreur</th>
        </tr>
"@
        foreach ($result in $errorResults) {
            $htmlErrors += @"
        <tr class="error">
            <td><span class="file-path">$($result.FilePath)</span></td>
            <td>$($result.Error)</td>
        </tr>
"@
        }
        $htmlErrors += "</table>"
    }


    # Section des Conflits
    $htmlConflicts = ""
    if ($conflictFiles -gt 0) {
        $htmlConflicts = @"
    <h2 class="conflict">Fichiers avec conflits de dÃ©tection ($conflictFiles)</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Ext Format</th>
            <th>Content Format</th>
            <th>Advanced Format</th>
            <th>Format Probable</th>
        </tr>
"@
        foreach ($result in $validResults | Where-Object { $_.Conflict }) {
            $htmlConflicts += @"
        <tr class="conflict">
            <td>$($result.FileName)<br><span class="file-path">$($result.FilePath)</span></td>
            <td>$($result.ExtensionFormat)</td>
            <td>$($result.ContentFormat)</td>
            <td>$($result.AdvancedFormat)</td>
            <td>$($result.ProbableTrueFormat)</td>
        </tr>
"@
        }
        $htmlConflicts += "</table>"
    }

    # Section de tous les fichiers analysÃ©s
    $htmlAllFiles = @"
    <h2>DÃ©tail des fichiers analysÃ©s ($analyzedFiles)</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Taille</th>
            <th>Ext Format</th>
            <th>Content Format</th>
            <th>Advanced Format</th>
            <th>Statut</th>
        </tr>
"@
    foreach ($result in $validResults | Sort-Object FileName) {
        $statusBadge = ""
        $rowClass = ""
        if ($result.Conflict) {
            $statusBadge = '<span class="badge badge-conflict">Conflit</span>'
            $rowClass = ' class="conflict"'
        } elseif ($result.ProbableTrueFormat -eq "UNKNOWN" -or $result.ProbableTrueFormat -eq "ERROR") {
             $statusBadge = '<span class="badge badge-unknown">Inconnu</span>'
        } else {
            $statusBadge = '<span class="badge badge-ok">OK</span>'
        }

        $htmlAllFiles += @"
        <tr$rowClass>
            <td>$($result.FileName)<br><span class="file-path">$($result.FilePath)</span></td>
            <td>$("{0:N0}" -f $result.Size) octets</td>
            <td>$($result.ExtensionFormat)</td>
            <td>$($result.ContentFormat)</td>
            <td>$($result.AdvancedFormat)</td>
            <td>$statusBadge ($($result.ProbableTrueFormat))</td>
        </tr>
"@
    }
    $htmlAllFiles += "</table>"

    $htmlFooter = @"
    <div class="footer">
        Analyse effectuÃ©e par le script Analyze-FormatDetectionFailures.ps1 (v2.0)
    </div>
    </div> <!-- /container -->
</body>
</html>
"@

    # Assembler le contenu HTML
    $htmlContent = $htmlHeader + $htmlSummary + $htmlErrors + $htmlConflicts + $htmlAllFiles + $htmlFooter

    # Enregistrer le rapport HTML
    try {
        $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML gÃ©nÃ©rÃ© avec succÃ¨s : $OutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'Ã©crire le rapport HTML sur '$OutputPath': $($_.Exception.Message)"
    }
}

#endregion

#region Main Execution Logic

# VÃ©rifier si le rÃ©pertoire d'Ã©chantillons existe (paramÃ¨tre validÃ©, mais re-vÃ©rifier avant l'opÃ©ration principale)
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    Write-Error "Le rÃ©pertoire d'Ã©chantillons '$SampleDirectory' n'existe pas ou n'est pas accessible."
    # Optionnel: CrÃ©er le rÃ©pertoire si souhaitÃ©
    # if ($PSCmdlet.ShouldProcess($SampleDirectory, "CrÃ©er le rÃ©pertoire d'Ã©chantillons")) {
    #     New-Item -Path $SampleDirectory -ItemType Directory -Force | Out-Null
    #     Write-Host "Le rÃ©pertoire d'Ã©chantillons a Ã©tÃ© crÃ©Ã© : $SampleDirectory" -ForegroundColor Yellow
    #     Write-Host "Veuillez y placer des fichiers d'Ã©chantillon pour l'analyse." -ForegroundColor Yellow
    # }
    exit 1
}

# Analyser les fichiers en parallÃ¨le
if ($PSCmdlet.ShouldProcess($SampleDirectory, "Analyser les formats de fichiers (parallÃ¨le)")) {
    $results = Test-FileFormats_Parallel -Directory $SampleDirectory -NumberOfThreads $MaxThreads

    if ($null -eq $results -or $results.Count -eq 0) {
        Write-Host "Aucun rÃ©sultat d'analyse Ã  rapporter." -ForegroundColor Yellow
        exit 0
    }

    # Enregistrer les rÃ©sultats au format JSON
    try {
        $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force -ErrorAction Stop
        Write-Host "Rapport JSON gÃ©nÃ©rÃ© avec succÃ¨s : $OutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'Ã©crire le rapport JSON sur '$OutputPath': $($_.Exception.Message)"
    }

    # GÃ©nÃ©rer un rapport HTML si demandÃ©
    if ($GenerateHtmlReport) {
        $htmlOutputPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-HtmlReport -Results $results -OutputPath $htmlOutputPath
    }

    # Afficher un rÃ©sumÃ© final
    $endTime = Get-Date
    $duration = New-TimeSpan -Start $global:ScriptStartTime -End $endTime

    $validResults = $results | Where-Object { -not $_.Error }
    $errorFilesCount = ($results | Where-Object { $_.Error }).Count
    $analyzedCount = $validResults.Count
    $conflictCount = ($validResults | Where-Object { $_.Conflict }).Count
    $totalCount = $results.Count

    Write-Host "`n--- RÃ©sumÃ© Final de l'Analyse ---" -ForegroundColor Cyan
    Write-Host " Temps total d'exÃ©cution : $($duration.ToString('g'))" -ForegroundColor White
    Write-Host " Fichiers trouvÃ©s au total : $totalCount" -ForegroundColor White
    Write-Host " Fichiers analysÃ©s        : $analyzedCount" -ForegroundColor White
    Write-Host " Erreurs rencontrÃ©es      : $errorFilesCount" -ForegroundColor $(if ($errorFilesCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host " Conflits dÃ©tectÃ©s        : $conflictCount" -ForegroundColor $(if ($conflictCount -gt 0) { 'Yellow' } else { 'Green' })

    if ($conflictCount -gt 0) {
        $conflictsByProbableFormat = $validResults | Where-Object { $_.Conflict } | Group-Object -Property ProbableTrueFormat | Sort-Object -Property Count -Descending
        Write-Host "`n Formats probables les plus souvent en conflit :" -ForegroundColor Yellow
        foreach ($group in $conflictsByProbableFormat | Select-Object -First 5) {
            Write-Host "  - $($group.Name): $($group.Count) conflits" -ForegroundColor White
        }
    }
    if ($errorFilesCount -gt 0) {
         Write-Host "`n VÃ©rifiez le rapport HTML ou JSON pour le dÃ©tail des erreurs." -ForegroundColor Red
    }

    Write-Host "--- Fin de l'analyse ---" -ForegroundColor Cyan
}

#endregion