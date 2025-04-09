# Script pour détecter de nouveaux patterns d'erreur

# Configuration
$PatternConfig = @{
    # Dossier des patterns d'erreur
    PatternsFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorPatterns"
    
    # Fichier de base de données des patterns
    PatternsFile = Join-Path -Path $env:TEMP -ChildPath "ErrorPatterns\patterns.json"
    
    # Dossier des logs à analyser
    LogsFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorLogs"
    
    # Seuil de similarité pour considérer un pattern comme nouveau
    SimilarityThreshold = 0.7
    
    # Nombre minimum d'occurrences pour considérer un pattern
    MinOccurrences = 3
}

# Fonction pour initialiser la détection de patterns
function Initialize-PatternDetection {
    param (
        [Parameter(Mandatory = $false)]
        [string]$PatternsFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$PatternsFile = "",
        
        [Parameter(Mandatory = $false)]
        [string]$LogsFolder = "",
        
        [Parameter(Mandatory = $false)]
        [double]$SimilarityThreshold = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$MinOccurrences = 0
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($PatternsFolder)) {
        $PatternConfig.PatternsFolder = $PatternsFolder
    }
    
    if (-not [string]::IsNullOrEmpty($PatternsFile)) {
        $PatternConfig.PatternsFile = $PatternsFile
    }
    
    if (-not [string]::IsNullOrEmpty($LogsFolder)) {
        $PatternConfig.LogsFolder = $LogsFolder
    }
    
    if ($SimilarityThreshold -gt 0) {
        $PatternConfig.SimilarityThreshold = $SimilarityThreshold
    }
    
    if ($MinOccurrences -gt 0) {
        $PatternConfig.MinOccurrences = $MinOccurrences
    }
    
    # Créer les dossiers s'ils n'existent pas
    foreach ($folder in @($PatternConfig.PatternsFolder, $PatternConfig.LogsFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    # Créer le fichier de patterns s'il n'existe pas
    if (-not (Test-Path -Path $PatternConfig.PatternsFile)) {
        $initialPatterns = @{
            Patterns = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialPatterns | ConvertTo-Json -Depth 5 | Set-Content -Path $PatternConfig.PatternsFile
    }
    
    return $PatternConfig
}

# Fonction pour ajouter un pattern d'erreur
function Add-ErrorPattern {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = "Warning",
        
        [Parameter(Mandatory = $false)]
        [string]$Solution = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Examples = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier de patterns existe
    if (-not (Test-Path -Path $PatternConfig.PatternsFile)) {
        Initialize-PatternDetection
    }
    
    # Charger les patterns existants
    $patternsData = Get-Content -Path $PatternConfig.PatternsFile -Raw | ConvertFrom-Json
    
    # Vérifier si le pattern existe déjà
    $existingPattern = $patternsData.Patterns | Where-Object { $_.Pattern -eq $Pattern -or $_.Name -eq $Name }
    
    if ($existingPattern) {
        Write-Warning "Un pattern avec ce nom ou cette expression existe déjà."
        return $null
    }
    
    # Créer le pattern
    $newPattern = @{
        ID = [Guid]::NewGuid().ToString()
        Pattern = $Pattern
        Name = $Name
        Description = $Description
        Category = $Category
        Severity = $Severity
        Solution = $Solution
        Examples = $Examples
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        Occurrences = 0
    }
    
    # Ajouter le pattern
    $patternsData.Patterns += $newPattern
    $patternsData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les patterns
    $patternsData | ConvertTo-Json -Depth 5 | Set-Content -Path $PatternConfig.PatternsFile
    
    return $newPattern
}

# Fonction pour analyser les logs et détecter des patterns
function Find-ErrorPatterns {
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogsFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$FileFilter = "*.log",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxFiles = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeExisting
    )
    
    # Utiliser le dossier de logs par défaut si non spécifié
    if ([string]::IsNullOrEmpty($LogsFolder)) {
        $LogsFolder = $PatternConfig.LogsFolder
    }
    
    # Vérifier si le dossier de logs existe
    if (-not (Test-Path -Path $LogsFolder)) {
        Write-Error "Le dossier de logs n'existe pas: $LogsFolder"
        return $null
    }
    
    # Charger les patterns existants
    $patternsData = Get-Content -Path $PatternConfig.PatternsFile -Raw | ConvertFrom-Json
    $existingPatterns = $patternsData.Patterns
    
    # Obtenir les fichiers de logs
    $logFiles = Get-ChildItem -Path $LogsFolder -Filter $FileFilter -Recurse
    
    if ($MaxFiles -gt 0 -and $logFiles.Count -gt $MaxFiles) {
        $logFiles = $logFiles | Select-Object -First $MaxFiles
    }
    
    Write-Host "Analyse de $($logFiles.Count) fichiers de logs..."
    
    # Collecter les erreurs
    $errors = @()
    
    foreach ($logFile in $logFiles) {
        $content = Get-Content -Path $logFile.FullName -Raw
        
        # Rechercher les erreurs dans le fichier
        $errorMatches = [regex]::Matches($content, "(?i)error|exception|failed|failure|crash|fatal")
        
        foreach ($match in $errorMatches) {
            # Extraire le contexte de l'erreur (ligne complète)
            $lineStart = $content.LastIndexOf("`n", $match.Index) + 1
            if ($lineStart -lt 0) { $lineStart = 0 }
            
            $lineEnd = $content.IndexOf("`n", $match.Index)
            if ($lineEnd -lt 0) { $lineEnd = $content.Length }
            
            $errorLine = $content.Substring($lineStart, $lineEnd - $lineStart).Trim()
            
            # Ignorer les lignes trop courtes
            if ($errorLine.Length -lt 10) {
                continue
            }
            
            $errors += @{
                Line = $errorLine
                File = $logFile.FullName
                Index = $match.Index
                Matched = $false
            }
        }
    }
    
    Write-Host "Trouvé $($errors.Count) erreurs potentielles."
    
    # Vérifier les patterns existants
    if ($IncludeExisting) {
        foreach ($pattern in $existingPatterns) {
            $regex = [regex]$pattern.Pattern
            $matchCount = 0
            
            foreach ($error in $errors) {
                if ($regex.IsMatch($error.Line)) {
                    $error.Matched = $true
                    $matchCount++
                }
            }
            
            # Mettre à jour le nombre d'occurrences
            $pattern.Occurrences += $matchCount
        }
        
        # Enregistrer les patterns mis à jour
        $patternsData.LastUpdate = Get-Date -Format "o"
        $patternsData | ConvertTo-Json -Depth 5 | Set-Content -Path $PatternConfig.PatternsFile
    }
    
    # Rechercher de nouveaux patterns
    $unmatchedErrors = $errors | Where-Object { -not $_.Matched }
    $potentialPatterns = @()
    
    # Regrouper les erreurs similaires
    $groups = @{}
    
    foreach ($error in $unmatchedErrors) {
        $added = $false
        
        foreach ($groupKey in $groups.Keys) {
            $similarity = Get-StringSimilarity -String1 $error.Line -String2 $groupKey
            
            if ($similarity -ge $PatternConfig.SimilarityThreshold) {
                $groups[$groupKey] += $error
                $added = $true
                break
            }
        }
        
        if (-not $added) {
            $groups[$error.Line] = @($error)
        }
    }
    
    # Filtrer les groupes par nombre d'occurrences
    $significantGroups = $groups.GetEnumerator() | Where-Object { $_.Value.Count -ge $PatternConfig.MinOccurrences }
    
    Write-Host "Trouvé $($significantGroups.Count) groupes d'erreurs significatifs."
    
    # Générer des patterns pour chaque groupe
    foreach ($group in $significantGroups) {
        $representative = $group.Key
        $occurrences = $group.Value.Count
        
        # Générer un pattern à partir des occurrences
        $pattern = Get-GeneralizedPattern -Strings ($group.Value | ForEach-Object { $_.Line })
        
        # Créer un nom pour le pattern
        $name = "Pattern_" + [Guid]::NewGuid().ToString().Substring(0, 8)
        
        # Ajouter le pattern
        $potentialPatterns += @{
            Pattern = $pattern
            Name = $name
            Description = "Pattern détecté automatiquement"
            Category = "Auto-detected"
            Severity = "Warning"
            Solution = ""
            Examples = ($group.Value | Select-Object -First 5 | ForEach-Object { $_.Line })
            Occurrences = $occurrences
        }
    }
    
    return $potentialPatterns
}

# Fonction pour calculer la similarité entre deux chaînes
function Get-StringSimilarity {
    param (
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    # Utiliser la distance de Levenshtein pour calculer la similarité
    $maxLength = [Math]::Max($String1.Length, $String2.Length)
    if ($maxLength -eq 0) {
        return 1.0
    }
    
    $distance = Get-LevenshteinDistance -String1 $String1 -String2 $String2
    $similarity = 1.0 - ($distance / $maxLength)
    
    return $similarity
}

# Fonction pour calculer la distance de Levenshtein
function Get-LevenshteinDistance {
    param (
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Créer la matrice de distance
    $distance = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    # Initialiser la première colonne
    for ($i = 0; $i -le $len1; $i++) {
        $distance[$i, 0] = $i
    }
    
    # Initialiser la première ligne
    for ($j = 0; $j -le $len2; $j++) {
        $distance[0, $j] = $j
    }
    
    # Remplir la matrice
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            
            $distance[$i, $j] = [Math]::Min(
                [Math]::Min(
                    $distance[$i - 1, $j] + 1,      # Suppression
                    $distance[$i, $j - 1] + 1       # Insertion
                ),
                $distance[$i - 1, $j - 1] + $cost   # Substitution
            )
        }
    }
    
    return $distance[$len1, $len2]
}

# Fonction pour généraliser un pattern à partir d'un ensemble de chaînes
function Get-GeneralizedPattern {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Strings
    )
    
    if ($Strings.Count -eq 0) {
        return ""
    }
    
    if ($Strings.Count -eq 1) {
        return [regex]::Escape($Strings[0])
    }
    
    # Trouver les parties communes
    $tokens = @()
    $reference = $Strings[0]
    
    # Diviser la référence en tokens (mots)
    $referenceTokens = $reference -split '\s+'
    
    foreach ($token in $referenceTokens) {
        $commonToken = $true
        
        foreach ($string in $Strings) {
            if ($string -notmatch [regex]::Escape($token)) {
                $commonToken = $false
                break
            }
        }
        
        if ($commonToken) {
            $tokens += $token
        }
    }
    
    # Construire le pattern
    if ($tokens.Count -eq 0) {
        # Aucun token commun, utiliser une approche plus générale
        $pattern = ($Strings | ForEach-Object { [regex]::Escape($_) }) -join "|"
    }
    else {
        $pattern = ($tokens | ForEach-Object { [regex]::Escape($_) }) -join ".*?"
    }
    
    return $pattern
}

# Fonction pour sauvegarder les patterns détectés
function Save-DetectedPatterns {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Patterns,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoApprove
    )
    
    # Vérifier si le fichier de patterns existe
    if (-not (Test-Path -Path $PatternConfig.PatternsFile)) {
        Initialize-PatternDetection
    }
    
    # Charger les patterns existants
    $patternsData = Get-Content -Path $PatternConfig.PatternsFile -Raw | ConvertFrom-Json
    
    $savedPatterns = @()
    
    foreach ($pattern in $Patterns) {
        if ($AutoApprove) {
            # Ajouter directement le pattern
            $newPattern = Add-ErrorPattern -Pattern $pattern.Pattern -Name $pattern.Name `
                -Description $pattern.Description -Category $pattern.Category `
                -Severity $pattern.Severity -Solution $pattern.Solution `
                -Examples $pattern.Examples
            
            if ($newPattern) {
                $savedPatterns += $newPattern
            }
        }
        else {
            # Demander confirmation
            Write-Host "`nPattern: $($pattern.Pattern)"
            Write-Host "Occurrences: $($pattern.Occurrences)"
            Write-Host "Exemples:"
            foreach ($example in $pattern.Examples) {
                Write-Host "  - $example"
            }
            
            $confirm = Read-Host "Voulez-vous ajouter ce pattern? (O/N)"
            
            if ($confirm -eq "O" -or $confirm -eq "o") {
                $name = Read-Host "Nom du pattern (laisser vide pour utiliser le nom par défaut)"
                if ([string]::IsNullOrEmpty($name)) {
                    $name = $pattern.Name
                }
                
                $description = Read-Host "Description (laisser vide pour utiliser la description par défaut)"
                if ([string]::IsNullOrEmpty($description)) {
                    $description = $pattern.Description
                }
                
                $category = Read-Host "Catégorie (laisser vide pour utiliser la catégorie par défaut)"
                if ([string]::IsNullOrEmpty($category)) {
                    $category = $pattern.Category
                }
                
                $severity = Read-Host "Sévérité (laisser vide pour utiliser la sévérité par défaut)"
                if ([string]::IsNullOrEmpty($severity)) {
                    $severity = $pattern.Severity
                }
                
                $solution = Read-Host "Solution (laisser vide pour utiliser la solution par défaut)"
                if ([string]::IsNullOrEmpty($solution)) {
                    $solution = $pattern.Solution
                }
                
                $newPattern = Add-ErrorPattern -Pattern $pattern.Pattern -Name $name `
                    -Description $description -Category $category `
                    -Severity $severity -Solution $solution `
                    -Examples $pattern.Examples
                
                if ($newPattern) {
                    $savedPatterns += $newPattern
                }
            }
        }
    }
    
    return $savedPatterns
}

# Fonction pour générer un rapport des patterns
function New-PatternReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport des patterns d'erreur",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Charger les patterns
    $patternsData = Get-Content -Path $PatternConfig.PatternsFile -Raw | ConvertFrom-Json
    
    # Filtrer par catégorie si spécifiée
    $patterns = $patternsData.Patterns
    if (-not [string]::IsNullOrEmpty($Category)) {
        $patterns = $patterns | Where-Object { $_.Category -eq $Category }
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "PatternReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .pattern {
            margin-bottom: 30px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .pattern h3 {
            margin-top: 0;
            margin-bottom: 10px;
        }
        
        .pattern-meta {
            font-size: 14px;
            color: #666;
            margin-bottom: 10px;
        }
        
        .pattern-regex {
            font-family: monospace;
            background-color: #f1f1f1;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 10px;
            overflow-x: auto;
        }
        
        .examples {
            margin-top: 10px;
        }
        
        .example {
            font-family: monospace;
            background-color: #f1f1f1;
            padding: 8px;
            border-radius: 4px;
            margin-bottom: 5px;
        }
        
        .severity-critical {
            color: #d9534f;
            font-weight: bold;
        }
        
        .severity-error {
            color: #f0ad4e;
            font-weight: bold;
        }
        
        .severity-warning {
            color: #5bc0de;
        }
        
        .severity-info {
            color: #5cb85c;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <p>Nombre total de patterns: $($patterns.Count)</p>
            $(if (-not [string]::IsNullOrEmpty($Category)) { "<p>Catégorie: $Category</p>" })
        </div>
        
        <h2>Patterns d'erreur</h2>
        
        $(foreach ($pattern in ($patterns | Sort-Object -Property CreatedAt -Descending)) {
            $severityClass = "severity-" + $pattern.Severity.ToLower()
            $createdAt = [DateTime]::Parse($pattern.CreatedAt).ToString("yyyy-MM-dd HH:mm:ss")
            
            "<div class='pattern'>
                <h3>$($pattern.Name)</h3>
                <div class='pattern-meta'>
                    <span>ID: $($pattern.ID)</span> |
                    <span>Catégorie: $($pattern.Category)</span> |
                    <span>Sévérité: <span class='$severityClass'>$($pattern.Severity)</span></span> |
                    <span>Créé le: $createdAt</span> |
                    <span>Occurrences: $($pattern.Occurrences)</span>
                </div>
                <p>$($pattern.Description)</p>
                <div class='pattern-regex'>
                    <strong>Expression régulière:</strong><br>
                    $($pattern.Pattern)
                </div>
                $(if (-not [string]::IsNullOrEmpty($pattern.Solution)) {
                    "<div class='solution'>
                        <strong>Solution:</strong><br>
                        $($pattern.Solution)
                    </div>"
                })
                $(if ($pattern.Examples.Count -gt 0) {
                    "<div class='examples'>
                        <strong>Exemples:</strong>
                        $(foreach ($example in $pattern.Examples) {
                            "<div class='example'>$example</div>"
                        })
                    </div>"
                })
            </div>"
        })
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-PatternDetection, Add-ErrorPattern, Find-ErrorPatterns
Export-ModuleMember -Function Save-DetectedPatterns, New-PatternReport
