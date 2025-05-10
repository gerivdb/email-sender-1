# Analyze-IndentationLevels.ps1
# Script pour analyser et normaliser les niveaux d'indentation dans les fichiers markdown de roadmap
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
    [int]$PreferredSpacesPerLevel = 2,
    
    [Parameter(Mandatory = $false)]
    [switch]$ConvertTabsToSpaces,
    
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

# Fonction pour analyser les niveaux d'indentation
function Get-IndentationAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Log "Analyse des niveaux d'indentation..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        SpacesPerLevel = 0
        TabsUsed = $false
        SpacesUsed = $false
        MixedIndentation = $false
        InconsistentIndentation = $false
        IndentationLevels = @{}
        IndentationDifferences = @{}
        LineIndentations = @{}
        InconsistentLines = @()
        MaxIndentLevel = 0
        IndentationStats = @{
            TotalLines = $lines.Count
            IndentedLines = 0
            TabIndentedLines = 0
            SpaceIndentedLines = 0
            MixedIndentedLines = 0
            InconsistentLines = 0
        }
    }
    
    # Analyser chaque ligne
    $previousIndent = 0
    $previousIndentLevel = 0
    $lineNumber = 0
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Ignorer les lignes vides ou les lignes de commentaires
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }
        
        # Analyser l'indentation de la ligne
        if ($line -match '^(\s*)') {
            $indentation = $matches[1]
            $indentLength = $indentation.Length
            
            # Enregistrer l'indentation de la ligne
            $analysis.LineIndentations[$lineNumber] = @{
                Indentation = $indentation
                Length = $indentLength
                ContainsTabs = $indentation.Contains("`t")
                ContainsSpaces = $indentation.Contains(" ")
            }
            
            # Mettre à jour les statistiques
            if ($indentLength -gt 0) {
                $analysis.IndentationStats.IndentedLines++
                
                if ($indentation.Contains("`t")) {
                    $analysis.TabsUsed = $true
                    $analysis.IndentationStats.TabIndentedLines++
                }
                
                if ($indentation.Contains(" ")) {
                    $analysis.SpacesUsed = $true
                    $analysis.IndentationStats.SpaceIndentedLines++
                }
                
                if ($indentation.Contains("`t") -and $indentation.Contains(" ")) {
                    $analysis.MixedIndentation = $true
                    $analysis.IndentationStats.MixedIndentedLines++
                }
                
                # Mettre à jour le niveau d'indentation maximal
                if ($indentLength -gt $analysis.MaxIndentLevel) {
                    $analysis.MaxIndentLevel = $indentLength
                }
                
                # Compter les occurrences de chaque niveau d'indentation
                if (-not $analysis.IndentationLevels.ContainsKey($indentLength)) {
                    $analysis.IndentationLevels[$indentLength] = 1
                } else {
                    $analysis.IndentationLevels[$indentLength]++
                }
                
                # Analyser les différences d'indentation (pour les listes et tâches)
                if ($line -match '^\s*[-*+]' -or $line -match '^\s*\d+\.') {
                    if ($previousIndent -gt 0 -and $indentLength -ne $previousIndent) {
                        $diff = [Math]::Abs($indentLength - $previousIndent)
                        
                        if (-not $analysis.IndentationDifferences.ContainsKey($diff)) {
                            $analysis.IndentationDifferences[$diff] = 1
                        } else {
                            $analysis.IndentationDifferences[$diff]++
                        }
                        
                        # Déterminer le niveau d'indentation actuel
                        $currentIndentLevel = if ($indentLength -gt $previousIndent) {
                            $previousIndentLevel + 1
                        } elseif ($indentLength -lt $previousIndent) {
                            [Math]::Max(0, $previousIndentLevel - 1)
                        } else {
                            $previousIndentLevel
                        }
                        
                        # Vérifier la cohérence de l'indentation
                        if ($analysis.SpacesPerLevel -gt 0) {
                            $expectedIndent = $currentIndentLevel * $analysis.SpacesPerLevel
                            if ($indentLength -ne $expectedIndent) {
                                $analysis.InconsistentIndentation = $true
                                $analysis.InconsistentLines += $lineNumber
                                $analysis.IndentationStats.InconsistentLines++
                            }
                        }
                        
                        $previousIndentLevel = $currentIndentLevel
                    }
                    
                    $previousIndent = $indentLength
                }
            }
        }
    }
    
    # Déterminer le nombre d'espaces par niveau d'indentation
    if ($analysis.IndentationDifferences.Count -gt 0) {
        $mostCommonDiff = $analysis.IndentationDifferences.GetEnumerator() | 
            Sort-Object -Property Value -Descending | 
            Select-Object -First 1
        
        $analysis.SpacesPerLevel = $mostCommonDiff.Key
    } else {
        # Si aucune différence n'a été trouvée, utiliser la valeur par défaut
        $analysis.SpacesPerLevel = $PreferredSpacesPerLevel
    }
    
    return $analysis
}

# Fonction pour normaliser l'indentation
function Normalize-Indentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $false)]
        [int]$SpacesPerLevel = 2,
        
        [Parameter(Mandatory = $false)]
        [switch]$ConvertTabsToSpaces
    )
    
    Write-Log "Normalisation de l'indentation..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    $normalizedLines = @()
    
    # Déterminer le nombre d'espaces par niveau
    $spacesPerLevel = if ($Analysis.SpacesPerLevel -gt 0) { 
        $Analysis.SpacesPerLevel 
    } else { 
        $SpacesPerLevel 
    }
    
    # Normaliser chaque ligne
    $previousIndentLevel = 0
    $lineNumber = 0
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Si la ligne est vide ou est un commentaire, la conserver telle quelle
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            $normalizedLines += $line
            continue
        }
        
        # Analyser l'indentation actuelle
        if ($line -match '^(\s*)(.*)') {
            $indentation = $matches[1]
            $content = $matches[2]
            $indentLength = $indentation.Length
            
            # Déterminer le niveau d'indentation
            $indentLevel = 0
            
            if ($indentLength -gt 0) {
                if ($Analysis.LineIndentations.ContainsKey($lineNumber)) {
                    $lineInfo = $Analysis.LineIndentations[$lineNumber]
                    
                    # Si la ligne est incohérente, calculer le niveau d'indentation
                    if ($Analysis.InconsistentLines -contains $lineNumber) {
                        # Déterminer le niveau d'indentation en fonction de la ligne précédente
                        if ($line -match '^\s*[-*+]' -or $line -match '^\s*\d+\.') {
                            if ($indentLength -gt $previousIndent) {
                                $indentLevel = $previousIndentLevel + 1
                            } elseif ($indentLength -lt $previousIndent) {
                                $indentLevel = [Math]::Max(0, $previousIndentLevel - 1)
                            } else {
                                $indentLevel = $previousIndentLevel
                            }
                        } else {
                            # Pour les autres lignes, estimer le niveau d'indentation
                            $indentLevel = [Math]::Round($indentLength / $spacesPerLevel)
                        }
                    } else {
                        # Si la ligne est cohérente, utiliser le niveau d'indentation calculé
                        $indentLevel = [Math]::Round($indentLength / $spacesPerLevel)
                    }
                } else {
                    # Si la ligne n'a pas été analysée, estimer le niveau d'indentation
                    $indentLevel = [Math]::Round($indentLength / $spacesPerLevel)
                }
            }
            
            # Créer la nouvelle indentation
            $newIndentation = " " * ($indentLevel * $spacesPerLevel)
            
            # Convertir les tabulations en espaces si demandé
            if ($ConvertTabsToSpaces -and $indentation.Contains("`t")) {
                $content = $content.Replace("`t", " " * $spacesPerLevel)
            }
            
            # Ajouter la ligne normalisée
            $normalizedLines += "$newIndentation$content"
            
            # Mettre à jour les variables pour la prochaine ligne
            $previousIndent = $indentLength
            $previousIndentLevel = $indentLevel
        } else {
            # Si la ligne ne correspond pas au modèle, la conserver telle quelle
            $normalizedLines += $line
        }
    }
    
    return $normalizedLines -join "`n"
}

# Fonction principale
function Analyze-IndentationLevels {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [switch]$FixInconsistencies,
        [int]$PreferredSpacesPerLevel,
        [switch]$ConvertTabsToSpaces,
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
    
    # Analyser l'indentation
    $analysis = Get-IndentationAnalysis -Content $Content
    
    # Afficher les résultats de l'analyse
    Write-Log "Analyse de l'indentation terminée :" -Level "Info"
    Write-Log "  - Espaces par niveau : $($analysis.SpacesPerLevel)" -Level "Info"
    Write-Log "  - Tabulations utilisées : $($analysis.TabsUsed)" -Level "Info"
    Write-Log "  - Espaces utilisés : $($analysis.SpacesUsed)" -Level "Info"
    Write-Log "  - Indentation mixte : $($analysis.MixedIndentation)" -Level "Info"
    Write-Log "  - Indentation incohérente : $($analysis.InconsistentIndentation)" -Level "Info"
    Write-Log "  - Niveau d'indentation maximal : $($analysis.MaxIndentLevel)" -Level "Info"
    Write-Log "  - Lignes indentées : $($analysis.IndentationStats.IndentedLines) / $($analysis.IndentationStats.TotalLines)" -Level "Info"
    
    # Normaliser l'indentation si demandé
    if ($FixInconsistencies) {
        $normalizedContent = Normalize-Indentation -Content $Content -Analysis $analysis -SpacesPerLevel $PreferredSpacesPerLevel -ConvertTabsToSpaces:$ConvertTabsToSpaces
        
        # Enregistrer le contenu normalisé si un chemin de sortie est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            try {
                $normalizedContent | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Log "Contenu normalisé enregistré dans : $OutputPath" -Level "Success"
            } catch {
                Write-Log "Erreur lors de l'enregistrement du contenu normalisé : $_" -Level "Error"
            }
        }
        
        return @{
            Analysis = $analysis
            NormalizedContent = $normalizedContent
        }
    } else {
        return @{
            Analysis = $analysis
            NormalizedContent = $null
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Analyze-IndentationLevels -FilePath $FilePath -Content $Content -FixInconsistencies:$FixInconsistencies -PreferredSpacesPerLevel $PreferredSpacesPerLevel -ConvertTabsToSpaces:$ConvertTabsToSpaces -OutputPath $OutputPath
}
