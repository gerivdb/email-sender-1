#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse des patterns d'erreurs inÃ©dits.
.DESCRIPTION
    Ce module permet d'analyser les erreurs PowerShell pour identifier des patterns inÃ©dits,
    les classifier et les corrÃ©ler pour amÃ©liorer la dÃ©tection et la prÃ©vention des erreurs.
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

# Variables globales
$script:ErrorDatabase = @{
    Patterns        = @()
    RawErrors       = @()
    Classifications = @()
    Correlations    = @()
}

$script:ErrorDatabasePath = Join-Path -Path $PSScriptRoot -ChildPath "error_database.json"
$script:ErrorLogPath = Join-Path -Path $PSScriptRoot -ChildPath "error_log.md"

# Charger la base de donnÃ©es d'erreurs si elle existe
function Initialize-ErrorDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = $script:ErrorDatabasePath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if (Test-Path -Path $DatabasePath -PathType Leaf) {
        try {
            $database = Get-Content -Path $DatabasePath -Raw | ConvertFrom-Json

            $script:ErrorDatabase.Patterns = $database.Patterns
            $script:ErrorDatabase.RawErrors = $database.RawErrors
            $script:ErrorDatabase.Classifications = $database.Classifications
            $script:ErrorDatabase.Correlations = $database.Correlations

            Write-Verbose "Base de donnÃ©es d'erreurs chargÃ©e depuis $DatabasePath"
        } catch {
            Write-Warning "Erreur lors du chargement de la base de donnÃ©es d'erreurs: $_"

            if ($Force) {
                Write-Verbose "Initialisation d'une nouvelle base de donnÃ©es d'erreurs"
                $script:ErrorDatabase = @{
                    Patterns        = @()
                    RawErrors       = @()
                    Classifications = @()
                    Correlations    = @()
                }
            }
        }
    } else {
        Write-Verbose "Initialisation d'une nouvelle base de donnÃ©es d'erreurs"
        $script:ErrorDatabase = @{
            Patterns        = @()
            RawErrors       = @()
            Classifications = @()
            Correlations    = @()
        }
    }
}

# Sauvegarder la base de donnÃ©es d'erreurs
function Save-ErrorDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = $script:ErrorDatabasePath
    )

    try {
        $script:ErrorDatabase | ConvertTo-Json -Depth 10 | Out-File -FilePath $DatabasePath -Encoding utf8
        Write-Verbose "Base de donnÃ©es d'erreurs sauvegardÃ©e dans $DatabasePath"
    } catch {
        Write-Error "Erreur lors de la sauvegarde de la base de donnÃ©es d'erreurs: $_"
    }
}

# Collecter une erreur et l'ajouter Ã  la base de donnÃ©es
function Add-ErrorRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$Context,

        [Parameter(Mandatory = $false)]
        [string]$Source,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags
    )

    process {
        # Normaliser l'erreur
        $normalizedError = @{
            Timestamp        = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
            ErrorId          = $ErrorRecord.FullyQualifiedErrorId
            Exception        = $ErrorRecord.Exception.GetType().FullName
            Message          = $ErrorRecord.Exception.Message
            ScriptName       = $ErrorRecord.InvocationInfo.ScriptName
            ScriptLineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber
            Line             = $ErrorRecord.InvocationInfo.Line
            PositionMessage  = $ErrorRecord.InvocationInfo.PositionMessage
            StackTrace       = $ErrorRecord.ScriptStackTrace
            Context          = $Context
            Source           = $Source
            Tags             = $Tags
            CategoryInfo     = $ErrorRecord.CategoryInfo.ToString()
        }

        # Ajouter l'erreur Ã  la base de donnÃ©es
        $script:ErrorDatabase.RawErrors += $normalizedError

        # Analyser l'erreur pour identifier des patterns
        $patternId = Find-ErrorPattern -ErrorRecord $normalizedError

        # Sauvegarder la base de donnÃ©es
        Save-ErrorDatabase

        # Retourner l'ID du pattern identifiÃ©
        return $patternId
    }
}

# Analyser une erreur pour identifier des patterns
function Find-ErrorPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ErrorRecord
    )

    # Extraire les caractÃ©ristiques clÃ©s de l'erreur
    $errorFeatures = @{
        ExceptionType  = $ErrorRecord.Exception
        ErrorId        = $ErrorRecord.ErrorId
        MessagePattern = Get-MessagePattern -Message $ErrorRecord.Message
        ScriptContext  = if ($ErrorRecord.ScriptName) { Split-Path -Leaf $ErrorRecord.ScriptName } else { "Unknown" }
        LinePattern    = Get-LinePattern -Line $ErrorRecord.Line
    }

    # Rechercher des patterns similaires
    $similarPatterns = @()
    foreach ($pattern in $script:ErrorDatabase.Patterns) {
        $similarity = Measure-PatternSimilarity -Pattern1 $errorFeatures -Pattern2 $pattern.Features

        if ($similarity -ge 0.7) {
            # Seuil de similaritÃ© Ã  70%
            $similarPatterns += @{
                PatternId  = $pattern.Id
                Similarity = $similarity
                Pattern    = $pattern
            }
        }
    }

    # Trier les patterns par similaritÃ©
    $similarPatterns = $similarPatterns | Sort-Object -Property Similarity -Descending

    if ($similarPatterns.Count -gt 0) {
        # Mettre Ã  jour le pattern existant
        $patternId = $similarPatterns[0].PatternId
        $pattern = $similarPatterns[0].Pattern

        # IncrÃ©menter le compteur d'occurrences
        $pattern.Occurrences++

        # Mettre Ã  jour la derniÃ¨re occurrence
        $pattern.LastOccurrence = $ErrorRecord.Timestamp

        # Ajouter l'erreur Ã  la liste des exemples
        if ($pattern.Examples.Count -lt 5) {
            # Limiter Ã  5 exemples
            $pattern.Examples += $ErrorRecord
        }

        # Mettre Ã  jour les caractÃ©ristiques du pattern
        $pattern.Features = Update-PatternFeatures -CurrentFeatures $pattern.Features -NewFeatures $errorFeatures

        # Ajouter une classification pour cette erreur
        $classification = @{
            ErrorTimestamp = $ErrorRecord.Timestamp
            PatternId      = $patternId
            Confidence     = $similarPatterns[0].Similarity
            IsValidated    = $false
        }

        $script:ErrorDatabase.Classifications += $classification

        return $patternId
    } else {
        # CrÃ©er un nouveau pattern
        $newPatternId = [guid]::NewGuid().ToString()

        $newPattern = @{
            Id               = $newPatternId
            Name             = "Pattern-$($script:ErrorDatabase.Patterns.Count + 1)"
            Description      = "Pattern automatiquement dÃ©tectÃ©: $($ErrorRecord.Message)"
            Features         = $errorFeatures
            FirstOccurrence  = $ErrorRecord.Timestamp
            LastOccurrence   = $ErrorRecord.Timestamp
            Occurrences      = 1
            Examples         = @($ErrorRecord)
            IsInedited       = $true  # Marquer comme potentiellement inÃ©dit
            ValidationStatus = "Pending"  # En attente de validation
            RelatedPatterns  = @()
        }

        $script:ErrorDatabase.Patterns += $newPattern

        # Ajouter une classification pour cette erreur
        $classification = @{
            ErrorTimestamp = $ErrorRecord.Timestamp
            PatternId      = $newPatternId
            Confidence     = 1.0  # Confiance maximale pour un nouveau pattern
            IsValidated    = $false
        }

        $script:ErrorDatabase.Classifications += $classification

        # Rechercher des corrÃ©lations avec d'autres patterns
        Find-ErrorCorrelations -PatternId $newPatternId

        return $newPatternId
    }
}

# Extraire un pattern Ã  partir d'un message d'erreur
function Get-MessagePattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    # Remplacer les valeurs spÃ©cifiques par des placeholders
    $pattern = $Message

    # Remplacer les chemins de fichiers
    $pattern = $pattern -replace '([A-Za-z]:\\[^"<>|:*?\\]+)+', '<PATH>'

    # Remplacer les nombres
    $pattern = $pattern -replace '\b\d+\b', '<NUMBER>'

    # Remplacer les GUID
    $pattern = $pattern -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '<GUID>'

    # Remplacer les noms de variables
    $pattern = $pattern -replace '\$[a-zA-Z0-9_]+', '<VARIABLE>'

    return $pattern
}

# Extraire un pattern Ã  partir d'une ligne de code
function Get-LinePattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    if ([string]::IsNullOrEmpty($Line)) {
        return ""
    }

    # Remplacer les valeurs spÃ©cifiques par des placeholders
    $pattern = $Line

    # Remplacer les chaÃ®nes de caractÃ¨res
    $pattern = $pattern -replace '"[^"]*"', '<STRING>'

    # Remplacer les nombres
    $pattern = $pattern -replace '\b\d+\b', '<NUMBER>'

    # Remplacer les noms de variables
    $pattern = $pattern -replace '\$[a-zA-Z0-9_]+', '<VARIABLE>'

    return $pattern
}

# Mesurer la similaritÃ© entre deux patterns
function Measure-PatternSimilarity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Pattern1,

        [Parameter(Mandatory = $true)]
        [hashtable]$Pattern2
    )

    $similarityScore = 0
    $totalFeatures = 0

    # Comparer les types d'exception
    if ($Pattern1.ExceptionType -eq $Pattern2.ExceptionType) {
        $similarityScore += 0.3
    }
    $totalFeatures += 0.3

    # Comparer les ID d'erreur
    if ($Pattern1.ErrorId -eq $Pattern2.ErrorId) {
        $similarityScore += 0.2
    }
    $totalFeatures += 0.2

    # Comparer les patterns de message
    if ($Pattern1.MessagePattern -eq $Pattern2.MessagePattern) {
        $similarityScore += 0.3
    } elseif ($Pattern1.MessagePattern -and $Pattern2.MessagePattern) {
        # Calculer la similaritÃ© de Levenshtein
        $levenshtein = Measure-LevenshteinDistance -String1 $Pattern1.MessagePattern -String2 $Pattern2.MessagePattern
        $maxLength = [Math]::Max($Pattern1.MessagePattern.Length, $Pattern2.MessagePattern.Length)

        if ($maxLength -gt 0) {
            $similarity = 1 - ($levenshtein / $maxLength)
            $similarityScore += 0.3 * $similarity
        }
    }
    $totalFeatures += 0.3

    # Comparer les contextes de script
    if ($Pattern1.ScriptContext -eq $Pattern2.ScriptContext) {
        $similarityScore += 0.1
    }
    $totalFeatures += 0.1

    # Comparer les patterns de ligne
    if ($Pattern1.LinePattern -eq $Pattern2.LinePattern) {
        $similarityScore += 0.1
    } elseif ($Pattern1.LinePattern -and $Pattern2.LinePattern) {
        # Calculer la similaritÃ© de Levenshtein
        $levenshtein = Measure-LevenshteinDistance -String1 $Pattern1.LinePattern -String2 $Pattern2.LinePattern
        $maxLength = [Math]::Max($Pattern1.LinePattern.Length, $Pattern2.LinePattern.Length)

        if ($maxLength -gt 0) {
            $similarity = 1 - ($levenshtein / $maxLength)
            $similarityScore += 0.1 * $similarity
        }
    }
    $totalFeatures += 0.1

    # Calculer le score final
    if ($totalFeatures -gt 0) {
        return $similarityScore / $totalFeatures
    } else {
        return 0
    }
}

# Calculer la distance de Levenshtein entre deux chaÃ®nes
function Measure-LevenshteinDistance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$String1 = "",

        [Parameter(Mandatory = $false)]
        [string]$String2 = ""
    )

    # Cas particuliers
    if ($String1 -eq $String2) { return 0 }
    if ($String1.Length -eq 0) { return $String2.Length }
    if ($String2.Length -eq 0) { return $String1.Length }

    # Utiliser une approche plus simple avec des tableaux 1D
    $len1 = $String1.Length
    $len2 = $String2.Length

    # CrÃ©er deux tableaux pour stocker les distances
    $d0 = New-Object int[] ($len2 + 1)
    $d1 = New-Object int[] ($len2 + 1)

    # Initialiser le premier tableau
    for ($j = 0; $j -le $len2; $j++) {
        $d0[$j] = $j
    }

    # Calculer la distance
    for ($i = 0; $i -lt $len1; $i++) {
        $d1[0] = $i + 1

        for ($j = 0; $j -lt $len2; $j++) {
            $cost = if ($String1[$i] -eq $String2[$j]) { 0 } else { 1 }
            $d1[$j + 1] = [Math]::Min(
                $d0[$j + 1] + 1, # Suppression
                [Math]::Min(
                    $d1[$j] + 1, # Insertion
                    $d0[$j] + $cost        # Substitution
                )
            )
        }

        # Ã‰changer les tableaux pour la prochaine itÃ©ration
        $temp = $d0
        $d0 = $d1
        $d1 = $temp
    }

    # Retourner la distance
    return $d0[$len2]
}

# Mettre Ã  jour les caractÃ©ristiques d'un pattern
function Update-PatternFeatures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$CurrentFeatures,

        [Parameter(Mandatory = $true)]
        [hashtable]$NewFeatures
    )

    # Pour l'instant, on conserve les caractÃ©ristiques actuelles
    # Dans une version plus avancÃ©e, on pourrait fusionner les caractÃ©ristiques
    return $CurrentFeatures
}

# Rechercher des corrÃ©lations entre les patterns d'erreur
function Find-ErrorCorrelations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PatternId
    )

    $pattern = $script:ErrorDatabase.Patterns | Where-Object { $_.Id -eq $PatternId }

    if (-not $pattern) {
        Write-Warning "Pattern non trouvÃ©: $PatternId"
        return
    }

    # Rechercher des patterns qui se produisent souvent ensemble
    $relatedPatterns = @()

    foreach ($otherPattern in $script:ErrorDatabase.Patterns) {
        if ($otherPattern.Id -eq $PatternId) {
            continue
        }

        # VÃ©rifier si les patterns partagent des caractÃ©ristiques
        $similarity = Measure-PatternSimilarity -Pattern1 $pattern.Features -Pattern2 $otherPattern.Features

        if ($similarity -ge 0.5) {
            # Seuil de similaritÃ© Ã  50%
            $relatedPatterns += @{
                PatternId    = $otherPattern.Id
                Similarity   = $similarity
                Relationship = "Similar"
            }
        }

        # VÃ©rifier si les patterns se produisent dans le mÃªme contexte
        if ($pattern.Features.ScriptContext -eq $otherPattern.Features.ScriptContext) {
            $relatedPatterns += @{
                PatternId    = $otherPattern.Id
                Similarity   = 0.3
                Relationship = "SameContext"
            }
        }
    }

    # Ajouter les patterns liÃ©s au pattern actuel
    $pattern.RelatedPatterns = $relatedPatterns | Sort-Object -Property Similarity -Descending | Select-Object -First 5

    # Ajouter des corrÃ©lations Ã  la base de donnÃ©es
    foreach ($relatedPattern in $relatedPatterns) {
        $correlation = @{
            PatternId1   = $PatternId
            PatternId2   = $relatedPattern.PatternId
            Similarity   = $relatedPattern.Similarity
            Relationship = $relatedPattern.Relationship
            Timestamp    = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        }

        $script:ErrorDatabase.Correlations += $correlation
    }
}

# Valider un pattern d'erreur
function Confirm-ErrorPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PatternId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Valid", "Invalid", "Duplicate")]
        [string]$ValidationStatus,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [switch]$IsInedited
    )

    $pattern = $script:ErrorDatabase.Patterns | Where-Object { $_.Id -eq $PatternId }

    if (-not $pattern) {
        Write-Error "Pattern non trouvÃ©: $PatternId"
        return
    }

    # Mettre Ã  jour le pattern
    $pattern.ValidationStatus = $ValidationStatus

    if ($Name) {
        $pattern.Name = $Name
    }

    if ($Description) {
        $pattern.Description = $Description
    }

    if ($PSBoundParameters.ContainsKey('IsInedited')) {
        $pattern.IsInedited = $IsInedited
    }

    # Mettre Ã  jour les classifications
    $classifications = $script:ErrorDatabase.Classifications | Where-Object { $_.PatternId -eq $PatternId }

    foreach ($classification in $classifications) {
        $classification.IsValidated = $true
    }

    # Sauvegarder la base de donnÃ©es
    Save-ErrorDatabase

    # Ajouter le pattern au journal des erreurs s'il est inÃ©dit
    if ($pattern.IsInedited -and $ValidationStatus -eq "Valid") {
        Add-ErrorPatternToLog -PatternId $PatternId
    }

    return $pattern
}

# Ajouter un pattern d'erreur au journal
function Add-ErrorPatternToLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PatternId
    )

    $pattern = $script:ErrorDatabase.Patterns | Where-Object { $_.Id -eq $PatternId }

    if (-not $pattern) {
        Write-Error "Pattern non trouvÃ©: $PatternId"
        return
    }

    # CrÃ©er une entrÃ©e de journal
    $logEntry = @"
## $(Get-Date -Format "yyyy-MM-dd HH:mm") - Nouveau pattern d'erreur inÃ©dit

### $($pattern.Name)
- **Description**: $($pattern.Description)
- **PremiÃ¨re occurrence**: $($pattern.FirstOccurrence)
- **Nombre d'occurrences**: $($pattern.Occurrences)
- **CaractÃ©ristiques**:
  - Type d'exception: $($pattern.Features.ExceptionType)
  - ID d'erreur: $($pattern.Features.ErrorId)
  - Contexte: $($pattern.Features.ScriptContext)

#### Exemple de message d'erreur:
```
$($pattern.Examples[0].Message)
```

#### Exemple de ligne de code:
```
$($pattern.Examples[0].Line)
```

#### Patterns liÃ©s:
$($pattern.RelatedPatterns | ForEach-Object { "- $($_.Relationship): $($_.PatternId)" } | Out-String)

"@

    # Ajouter l'entrÃ©e au journal
    if (Test-Path -Path $script:ErrorLogPath) {
        $logEntry | Out-File -FilePath $script:ErrorLogPath -Encoding utf8 -Append
    } else {
        "# Journal des patterns d'erreur inÃ©dits`n`n$logEntry" | Out-File -FilePath $script:ErrorLogPath -Encoding utf8
    }

    Write-Verbose "Pattern ajoutÃ© au journal: $($pattern.Name)"
}

# Obtenir les patterns d'erreur
function Get-ErrorPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PatternId,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeExamples,

        [Parameter(Mandatory = $false)]
        [switch]$OnlyInedited,

        [Parameter(Mandatory = $false)]
        [switch]$OnlyValidated
    )

    if ($PatternId) {
        $patterns = $script:ErrorDatabase.Patterns | Where-Object { $_.Id -eq $PatternId }
    } else {
        $patterns = $script:ErrorDatabase.Patterns

        if ($OnlyInedited) {
            $patterns = $patterns | Where-Object { $_.IsInedited }
        }

        if ($OnlyValidated) {
            $patterns = $patterns | Where-Object { $_.ValidationStatus -eq "Valid" }
        }
    }

    if (-not $IncludeExamples) {
        $patterns = $patterns | ForEach-Object {
            $patternCopy = $_ | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            $patternCopy.Examples = @($patternCopy.Examples | Select-Object -First 1)
            $patternCopy
        }
    }

    return $patterns
}

# Obtenir les corrÃ©lations entre les patterns d'erreur
function Get-ErrorCorrelation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PatternId
    )

    if ($PatternId) {
        $correlations = $script:ErrorDatabase.Correlations | Where-Object { $_.PatternId1 -eq $PatternId -or $_.PatternId2 -eq $PatternId }
    } else {
        $correlations = $script:ErrorDatabase.Correlations
    }

    return $correlations
}

# GÃ©nÃ©rer un rapport d'analyse des patterns d'erreur
function New-ErrorPatternReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "error_pattern_report.md"),

        [Parameter(Mandatory = $false)]
        [switch]$IncludeExamples,

        [Parameter(Mandatory = $false)]
        [switch]$OnlyInedited
    )

    # Obtenir les patterns
    $patterns = Get-ErrorPattern -IncludeExamples:$IncludeExamples -OnlyInedited:$OnlyInedited

    # CrÃ©er le rapport
    $report = @"
# Rapport d'analyse des patterns d'erreur
*GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## RÃ©sumÃ©
- Nombre total de patterns: $($patterns.Count)
- Patterns inÃ©dits: $($patterns | Where-Object { $_.IsInedited } | Measure-Object | Select-Object -ExpandProperty Count)
- Patterns validÃ©s: $($patterns | Where-Object { $_.ValidationStatus -eq "Valid" } | Measure-Object | Select-Object -ExpandProperty Count)
- Patterns invalidÃ©s: $($patterns | Where-Object { $_.ValidationStatus -eq "Invalid" } | Measure-Object | Select-Object -ExpandProperty Count)
- Patterns en attente: $($patterns | Where-Object { $_.ValidationStatus -eq "Pending" } | Measure-Object | Select-Object -ExpandProperty Count)

## Patterns d'erreur inÃ©dits
$(foreach ($pattern in ($patterns | Where-Object { $_.IsInedited -and $_.ValidationStatus -eq "Valid" })) {
    $patternText = "### $($pattern.Name)`n"
    $patternText += "- **Description**: $($pattern.Description)`n"
    $patternText += "- **PremiÃ¨re occurrence**: $($pattern.FirstOccurrence)`n"
    $patternText += "- **DerniÃ¨re occurrence**: $($pattern.LastOccurrence)`n"
    $patternText += "- **Nombre d'occurrences**: $($pattern.Occurrences)`n"
    $patternText += "- **CaractÃ©ristiques**:`n"
    $patternText += "  - Type d'exception: $($pattern.Features.ExceptionType)`n"
    $patternText += "  - ID d'erreur: $($pattern.Features.ErrorId)`n"
    $patternText += "  - Contexte: $($pattern.Features.ScriptContext)`n`n"

    if ($IncludeExamples -and $pattern.Examples.Count -gt 0) {
        $patternText += "#### Exemple de message d'erreur:`n"
        $patternText += "````n"
        $patternText += "$($pattern.Examples[0].Message)`n"
        $patternText += "````n`n"
        $patternText += "#### Exemple de ligne de code:`n"
        $patternText += "````n"
        $patternText += "$($pattern.Examples[0].Line)`n"
        $patternText += "````n`n"
    }

    $patternText
})

## CorrÃ©lations entre patterns
$(foreach ($relationGroup in ($script:ErrorDatabase.Correlations | Group-Object -Property Relationship)) {
    $correlationText = "### $($relationGroup.Name)`n"

    foreach ($correlation in ($relationGroup.Group | Sort-Object -Property Similarity -Descending | Select-Object -First 10)) {
        $pattern1 = $patterns | Where-Object { $_.Id -eq $correlation.PatternId1 } | Select-Object -First 1
        $pattern2 = $patterns | Where-Object { $_.Id -eq $correlation.PatternId2 } | Select-Object -First 1

        if ($pattern1 -and $pattern2) {
            $similarityPercent = [Math]::Round($correlation.Similarity * 100, 2)
            $correlationText += "- **$($pattern1.Name)** et **$($pattern2.Name)** (SimilaritÃ©: ${similarityPercent}%)`n"
        }
    }

    $correlationText += "`n"
    $correlationText
})

## Recommandations
$(foreach ($pattern in ($patterns | Where-Object { $_.IsInedited -and $_.ValidationStatus -eq "Valid" })) {
    # GÃ©nÃ©rer des recommandations basÃ©es sur le type d'erreur
    $recommendation = switch -Regex ($pattern.Features.ExceptionType) {
        "NullReferenceException" { "Ajouter des vÃ©rifications de nullitÃ© avant d'accÃ©der aux propriÃ©tÃ©s ou mÃ©thodes." }
        "ArgumentNullException" { "Valider les arguments des fonctions pour s'assurer qu'ils ne sont pas null." }
        "ArgumentException" { "VÃ©rifier que les arguments fournis sont valides et du bon type." }
        "IndexOutOfRangeException" { "VÃ©rifier les limites des tableaux avant d'y accÃ©der." }
        "FileNotFoundException" { "VÃ©rifier l'existence des fichiers avant de les ouvrir." }
        "UnauthorizedAccessException" { "VÃ©rifier les permissions avant d'accÃ©der aux ressources." }
        "InvalidOperationException" { "VÃ©rifier que l'objet est dans un Ã©tat valide avant d'effectuer l'opÃ©ration." }
        default { "Analyser le contexte de l'erreur pour dÃ©terminer la cause racine." }
    }

    $recommendationText = "### Recommandation pour $($pattern.Name)`n"
    $recommendationText += "$recommendation`n`n"
    $recommendationText += "#### Actions suggÃ©rÃ©es:`n"
    $recommendationText += "1. Ajouter des vÃ©rifications prÃ©alables dans le script $($pattern.Features.ScriptContext)`n"
    $recommendationText += "2. ImplÃ©menter une gestion d'erreur spÃ©cifique pour ce cas`n"
    $recommendationText += "3. Documenter ce pattern d'erreur dans le guide de dÃ©veloppement`n`n"

    $recommendationText
})
"@

    # Enregistrer le rapport
    $report | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Verbose "Rapport gÃ©nÃ©rÃ©: $OutputPath"

    return $OutputPath
}

# Analyser un script pour détecter les erreurs potentielles
function Get-ErrorPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
        [string]$ScriptContent,

        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [string]$FilePath
    )

    # Si un chemin de fichier est fourni, lire le contenu du fichier
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Fichier non trouvé: $FilePath"
            return @()
        }

        $ScriptContent = Get-Content -Path $FilePath -Raw
    }

    # Patterns d'erreurs à détecter
    $errorPatterns = @(
        @{
            Id          = "null-reference"
            Pattern     = '\$\w+\.\w+'
            Message     = "Référence potentiellement nulle"
            Severity    = "Warning"
            Description = "Accès à une propriété d'un objet potentiellement nul"
            Suggestion  = "Ajouter une vérification de nullité avant d'accéder aux propriétés"
            CodeExample = "if (\$object -ne \$null) { ... }"
        },
        @{
            Id          = "index-out-of-bounds"
            Pattern     = '\$\w+\[\d+\]'
            Message     = "Index potentiellement hors limites"
            Severity    = "Warning"
            Description = "Accès à un élément de tableau avec un index potentiellement hors limites"
            Suggestion  = "Vérifier les limites du tableau avant d'accéder aux éléments"
            CodeExample = "if (\$array.Length -gt \$index) { ... }"
        },
        @{
            Id          = "type-conversion"
            Pattern     = '\[\w+(\.\w+)*\]\$\w+'
            Message     = "Conversion de type potentiellement invalide"
            Severity    = "Warning"
            Description = "Conversion d'une variable vers un type spécifique sans vérification préalable"
            Suggestion  = "Vérifier que la conversion est valide avant de l'effectuer"
            CodeExample = "if (\$value -as [System.Int32]) { ... }"
        },
        @{
            Id          = "uninitialized-variable"
            Pattern     = '\$\w+\s*[^=]*'
            Message     = "Variable potentiellement non initialisée"
            Severity    = "Warning"
            Description = "Utilisation d'une variable qui pourrait ne pas être initialisée"
            Suggestion  = "Initialiser la variable avant de l'utiliser"
            CodeExample = "\$variable = \$null # ou une valeur par défaut"
        },
        @{
            Id          = "division-by-zero"
            Pattern     = '\d+\s*\/\s*\$\w+'
            Message     = "Division potentielle par zéro"
            Severity    = "Warning"
            Description = "Division par une variable qui pourrait être égale à zéro"
            Suggestion  = "Vérifier que le diviseur n'est pas égal à zéro avant d'effectuer la division"
            CodeExample = "if (\$divisor -ne 0) { ... }"
        }
    )

    # Analyser le contenu du script
    $results = @()
    $lines = $ScriptContent -split "`r?`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        foreach ($pattern in $errorPatterns) {
            if ($line -match $pattern.Pattern) {
                $results += @{
                    Id          = $pattern.Id
                    LineNumber  = $i
                    StartColumn = $matches[0].IndexOf('$')
                    EndColumn   = $matches[0].IndexOf('$') + $matches[0].Length
                    Message     = $pattern.Message
                    Severity    = $pattern.Severity
                    Description = $pattern.Description
                    Suggestion  = $pattern.Suggestion
                    CodeExample = $pattern.CodeExample
                }
            }
        }
    }

    return $results
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Add-ErrorRecord, Get-ErrorPattern, Confirm-ErrorPattern, New-ErrorPatternReport, Measure-LevenshteinDistance, Get-MessagePattern, Get-LinePattern, Measure-PatternSimilarity, Initialize-ErrorDatabase, Save-ErrorDatabase, Get-ErrorPatterns

# Initialiser le module
Initialize-ErrorDatabase

# Exporter les fonctions du module
Export-ModuleMember -Function Add-ErrorRecord, Get-ErrorPattern, Get-ErrorCorrelation, Confirm-ErrorPattern, New-ErrorPatternReport, Get-ErrorPatterns
