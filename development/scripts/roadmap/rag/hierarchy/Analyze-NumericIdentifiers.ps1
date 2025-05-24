# Test-NumericIdentifiers.ps1
# Script pour analyser et normaliser les identifiants numériques dans les fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [switch]$FixInconsistencies,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Numeric", "Hierarchical", "Mixed")]
    [string]$PreferredFormat = "Hierarchical",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour analyser les identifiants numériques
function Get-NumericIdentifiersAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Log "Analyse des identifiants numériques..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        IdentifierFormats = @{
            Numeric = 0        # Format simple: 1, 2, 3
            Hierarchical = 0   # Format hiérarchique: 1.1, 1.2, 2.1
            AlphaNumeric = 0   # Format alphanumérique: A.1, B.2
            Mixed = 0          # Format mixte: combinaison des formats précédents
            Other = 0          # Autres formats
        }
        IdentifierPatterns = @{}
        IdentifiersByLine = @{}
        InconsistentLines = @()
        MissingIdentifiers = @()
        DuplicateIdentifiers = @{}
        HierarchyDepth = 0
        Stats = @{
            TotalLines = $lines.Count
            LinesWithIdentifiers = 0
            InconsistentLines = 0
            MissingIdentifiers = 0
            DuplicateIdentifiers = 0
        }
    }
    
    # Patterns pour détecter les différents formats d'identifiants
    $patterns = @{
        Numeric = '^\s*[-*+]\s*(?:\*\*)?(\d+)(?:\*\*)?\s'
        Hierarchical = '^\s*[-*+]\s*(?:\*\*)?(\d+(?:\.\d+)+)(?:\*\*)?\s'
        AlphaNumeric = '^\s*[-*+]\s*(?:\*\*)?([A-Za-z]+(?:\.\d+)+)(?:\*\*)?\s'
        TaskWithCheckbox = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s'
    }
    
    # Analyser chaque ligne
    $lineNumber = 0
    $previousIdentifier = ""
    $identifierMap = @{}
    $hierarchyLevels = @{}
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Ignorer les lignes vides ou les lignes de commentaires
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }
        
        # Détecter les identifiants dans la ligne
        $identifierFound = $false
        $identifierType = "None"
        $identifier = ""
        
        # Vérifier d'abord les tâches avec cases à cocher (format spécial)
        if ($line -match $patterns.TaskWithCheckbox) {
            $identifier = $matches[2]
            $identifierFound = $true
            
            # Déterminer le type d'identifiant
            if ($identifier -match '^\d+$') {
                $identifierType = "Numeric"
                $analysis.IdentifierFormats.Numeric++
            } elseif ($identifier -match '^\d+(?:\.\d+)+$') {
                $identifierType = "Hierarchical"
                $analysis.IdentifierFormats.Hierarchical++
            } elseif ($identifier -match '^[A-Za-z]+(?:\.\d+)+$') {
                $identifierType = "AlphaNumeric"
                $analysis.IdentifierFormats.AlphaNumeric++
            } else {
                $identifierType = "Mixed"
                $analysis.IdentifierFormats.Mixed++
            }
        } else {
            # Vérifier les autres formats d'identifiants
            foreach ($patternKey in $patterns.Keys) {
                if ($patternKey -eq "TaskWithCheckbox") { continue }
                
                if ($line -match $patterns[$patternKey]) {
                    $identifier = $matches[1]
                    $identifierFound = $true
                    $identifierType = $patternKey
                    $analysis.IdentifierFormats[$patternKey]++
                    break
                }
            }
        }
        
        # Si un identifiant a été trouvé, l'analyser
        if ($identifierFound) {
            $analysis.Stats.LinesWithIdentifiers++
            
            # Enregistrer l'identifiant pour cette ligne
            $analysis.IdentifiersByLine[$lineNumber] = @{
                Identifier = $identifier
                Type = $identifierType
                Line = $line
            }
            
            # Compter les occurrences de ce pattern d'identifiant
            if (-not $analysis.IdentifierPatterns.ContainsKey($identifier)) {
                $analysis.IdentifierPatterns[$identifier] = 1
            } else {
                $analysis.IdentifierPatterns[$identifier]++
                
                # Détecter les identifiants en double
                if ($analysis.IdentifierPatterns[$identifier] -gt 1) {
                    $analysis.DuplicateIdentifiers[$identifier] = $analysis.IdentifierPatterns[$identifier]
                    $analysis.Stats.DuplicateIdentifiers++
                }
            }
            
            # Analyser la hiérarchie pour les identifiants hiérarchiques
            if ($identifierType -eq "Hierarchical" -or $identifierType -eq "AlphaNumeric") {
                $parts = $identifier -split '\.'
                $depth = $parts.Count
                
                # Mettre à jour la profondeur maximale de la hiérarchie
                if ($depth -gt $analysis.HierarchyDepth) {
                    $analysis.HierarchyDepth = $depth
                }
                
                # Vérifier la cohérence de la hiérarchie
                $parentIdentifier = [string]::Join(".", $parts[0..($depth-2)])
                
                if ($depth -gt 1 -and -not [string]::IsNullOrEmpty($parentIdentifier)) {
                    if (-not $identifierMap.ContainsKey($parentIdentifier)) {
                        # Le parent n'existe pas, c'est une incohérence
                        $analysis.InconsistentLines += $lineNumber
                        $analysis.Stats.InconsistentLines++
                    }
                }
                
                # Enregistrer cet identifiant dans la carte
                $identifierMap[$identifier] = $lineNumber
                
                # Vérifier la séquence des identifiants au même niveau
                $currentLevel = $depth
                $currentIndex = [int]($parts[-1])
                
                if (-not $hierarchyLevels.ContainsKey($parentIdentifier)) {
                    $hierarchyLevels[$parentIdentifier] = @{
                        LastIndex = $currentIndex
                        ExpectedNext = $currentIndex + 1
                    }
                } else {
                    $expected = $hierarchyLevels[$parentIdentifier].ExpectedNext
                    
                    if ($currentIndex -ne $expected) {
                        # La séquence est interrompue, c'est une incohérence
                        $analysis.InconsistentLines += $lineNumber
                        $analysis.Stats.InconsistentLines++
                    }
                    
                    $hierarchyLevels[$parentIdentifier].LastIndex = $currentIndex
                    $hierarchyLevels[$parentIdentifier].ExpectedNext = $currentIndex + 1
                }
            }
            
            $previousIdentifier = $identifier
        } else {
            # Ligne sans identifiant, mais qui pourrait en avoir besoin
            if ($line -match '^\s*[-*+]' -or $line -match '^\s*\d+\.') {
                $analysis.MissingIdentifiers += $lineNumber
                $analysis.Stats.MissingIdentifiers++
            }
        }
    }
    
    return $analysis
}

# Fonction pour reconstruire la hiérarchie à partir des identifiants
function Update-HierarchyFromIdentifiers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Numeric", "Hierarchical", "Mixed")]
        [string]$PreferredFormat = "Hierarchical"
    )
    
    Write-Log "Reconstruction de la hiérarchie à partir des identifiants..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    $rebuiltLines = @()
    
    # Déterminer le format dominant
    $dominantFormat = $PreferredFormat
    if ($PreferredFormat -eq "Mixed") {
        # Trouver le format le plus utilisé
        $formatCounts = $Analysis.IdentifierFormats
        $dominantFormat = ($formatCounts.GetEnumerator() | 
            Where-Object { $_.Name -ne "Other" -and $_.Name -ne "Mixed" } | 
            Sort-Object -Property Value -Descending | 
            Select-Object -First 1).Name
    }
    
    # Initialiser les variables pour la reconstruction
    $currentHierarchy = @()
    $lineNumber = 0
    $newIdentifiers = @{}
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Ignorer les lignes vides ou les lignes de commentaires
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            $rebuiltLines += $line
            continue
        }
        
        # Vérifier si la ligne a un identifiant
        if ($Analysis.IdentifiersByLine.ContainsKey($lineNumber)) {
            $identifierInfo = $Analysis.IdentifiersByLine[$lineNumber]
            $identifier = $identifierInfo.Identifier
            $type = $identifierInfo.Type
            
            # Analyser l'indentation pour déterminer le niveau hiérarchique
            if ($line -match '^(\s*)') {
                $indentation = $matches[1]
                $indentLevel = [Math]::Ceiling($indentation.Length / 2)
                
                # Mettre à jour la hiérarchie actuelle
                if ($indentLevel -ge $currentHierarchy.Count) {
                    # Ajouter un nouveau niveau
                    while ($currentHierarchy.Count -le $indentLevel) {
                        $currentHierarchy += 1
                    }
                } elseif ($indentLevel -lt $currentHierarchy.Count) {
                    # Remonter dans la hiérarchie
                    $currentHierarchy = $currentHierarchy[0..$indentLevel]
                    $currentHierarchy[-1]++
                } else {
                    # Même niveau, incrémenter
                    $currentHierarchy[-1]++
                }
                
                # Générer un nouvel identifiant selon le format préféré
                $newIdentifier = ""
                
                if ($dominantFormat -eq "Numeric") {
                    $newIdentifier = $currentHierarchy[-1].ToString()
                } elseif ($dominantFormat -eq "Hierarchical") {
                    $newIdentifier = [string]::Join(".", $currentHierarchy)
                }
                
                # Remplacer l'ancien identifiant par le nouveau
                $newIdentifiers[$lineNumber] = $newIdentifier
                
                # Remplacer l'identifiant dans la ligne
                if ($line -match '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)') {
                    # Ligne avec case à cocher et identifiant
                    $checkbox = $matches[1]
                    $oldIdentifier = $matches[2]
                    $rest = $matches[3]
                    $rebuiltLines += "$indentation- [$checkbox] **$newIdentifier** $rest"
                } elseif ($line -match '^\s*[-*+]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)') {
                    # Ligne avec identifiant sans case à cocher
                    $oldIdentifier = $matches[1]
                    $rest = $matches[2]
                    $rebuiltLines += "$indentation- **$newIdentifier** $rest"
                } else {
                    # Conserver la ligne telle quelle
                    $rebuiltLines += $line
                }
            } else {
                # Conserver la ligne telle quelle
                $rebuiltLines += $line
            }
        } elseif ($Analysis.MissingIdentifiers -contains $lineNumber) {
            # Ligne sans identifiant mais qui devrait en avoir un
            if ($line -match '^(\s*)[-*+]\s*(.*)') {
                $indentation = $matches[1]
                $rest = $matches[2]
                $indentLevel = [Math]::Ceiling($indentation.Length / 2)
                
                # Mettre à jour la hiérarchie actuelle
                if ($indentLevel -ge $currentHierarchy.Count) {
                    # Ajouter un nouveau niveau
                    while ($currentHierarchy.Count -le $indentLevel) {
                        $currentHierarchy += 1
                    }
                } elseif ($indentLevel -lt $currentHierarchy.Count) {
                    # Remonter dans la hiérarchie
                    $currentHierarchy = $currentHierarchy[0..$indentLevel]
                    $currentHierarchy[-1]++
                } else {
                    # Même niveau, incrémenter
                    $currentHierarchy[-1]++
                }
                
                # Générer un nouvel identifiant selon le format préféré
                $newIdentifier = ""
                
                if ($dominantFormat -eq "Numeric") {
                    $newIdentifier = $currentHierarchy[-1].ToString()
                } elseif ($dominantFormat -eq "Hierarchical") {
                    $newIdentifier = [string]::Join(".", $currentHierarchy)
                }
                
                # Ajouter l'identifiant à la ligne
                $newIdentifiers[$lineNumber] = $newIdentifier
                
                # Vérifier si la ligne contient une case à cocher
                if ($rest -match '^\[([ xX])\]\s*(.*)') {
                    $checkbox = $matches[1]
                    $restAfterCheckbox = $matches[2]
                    $rebuiltLines += "$indentation- [$checkbox] **$newIdentifier** $restAfterCheckbox"
                } else {
                    $rebuiltLines += "$indentation- **$newIdentifier** $rest"
                }
            } else {
                # Conserver la ligne telle quelle
                $rebuiltLines += $line
            }
        } else {
            # Conserver la ligne telle quelle
            $rebuiltLines += $line
        }
    }
    
    return @{
        RebuiltContent = $rebuiltLines -join "`n"
        NewIdentifiers = $newIdentifiers
    }
}

# Fonction principale
function Test-NumericIdentifiers {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [switch]$FixInconsistencies,
        [string]$PreferredFormat,
        [string]$OutputPath
    )
    
    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Log "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -Level "Error"
        return $null
    }
    
    # Lire le contenu du fichier si nécessaire
    if ([string]::IsNullOrEmpty($Content) -and -not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier spécifié n'existe pas : $FilePath" -Level "Error"
            return $null
        }
        
        try {
            $Content = Get-Content -Path $FilePath -Raw
        } catch {
            Write-Log "Erreur lors de la lecture du fichier : $_" -Level "Error"
            return $null
        }
    }
    
    # Analyser les identifiants numériques
    $analysis = Get-NumericIdentifiersAnalysis -Content $Content
    
    # Afficher les résultats de l'analyse
    Write-Log "Analyse des identifiants numériques terminée :" -Level "Info"
    Write-Log "  - Format numérique : $($analysis.IdentifierFormats.Numeric)" -Level "Info"
    Write-Log "  - Format hiérarchique : $($analysis.IdentifierFormats.Hierarchical)" -Level "Info"
    Write-Log "  - Format alphanumérique : $($analysis.IdentifierFormats.AlphaNumeric)" -Level "Info"
    Write-Log "  - Format mixte : $($analysis.IdentifierFormats.Mixed)" -Level "Info"
    Write-Log "  - Profondeur de la hiérarchie : $($analysis.HierarchyDepth)" -Level "Info"
    Write-Log "  - Lignes avec identifiants : $($analysis.Stats.LinesWithIdentifiers) / $($analysis.Stats.TotalLines)" -Level "Info"
    Write-Log "  - Lignes incohérentes : $($analysis.Stats.InconsistentLines)" -Level "Info"
    Write-Log "  - Identifiants manquants : $($analysis.Stats.MissingIdentifiers)" -Level "Info"
    Write-Log "  - Identifiants en double : $($analysis.Stats.DuplicateIdentifiers)" -Level "Info"
    
    # Reconstruire la hiérarchie si demandé
    if ($FixInconsistencies) {
        $rebuiltResult = Update-HierarchyFromIdentifiers -Content $Content -Analysis $analysis -PreferredFormat $PreferredFormat
        
        # Enregistrer le contenu reconstruit si un chemin de sortie est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            try {
                $rebuiltResult.RebuiltContent | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Log "Contenu reconstruit enregistré dans : $OutputPath" -Level "Success"
            } catch {
                Write-Log "Erreur lors de l'enregistrement du contenu reconstruit : $_" -Level "Error"
            }
        }
        
        return @{
            Analysis = $analysis
            RebuiltContent = $rebuiltResult.RebuiltContent
            NewIdentifiers = $rebuiltResult.NewIdentifiers
        }
    } else {
        return @{
            Analysis = $analysis
            RebuiltContent = $null
            NewIdentifiers = $null
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-NumericIdentifiers -FilePath $FilePath -Content $Content -FixInconsistencies:$FixInconsistencies -PreferredFormat $PreferredFormat -OutputPath $OutputPath
}


