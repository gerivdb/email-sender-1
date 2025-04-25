<#
.SYNOPSIS
    Détecte les duplications de code dans les scripts.
.DESCRIPTION
    Ce script analyse les scripts pour détecter les duplications de code et génère
    un rapport détaillé des duplications trouvées. Il utilise plusieurs méthodes
    pour identifier les duplications, y compris la comparaison de chaînes et
    l'analyse de similarité.
.PARAMETER Path
    Chemin du dossier contenant les scripts à analyser. Par défaut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Par défaut: scripts\manager\data\duplication_report.json
.PARAMETER MinimumLineCount
    Nombre minimum de lignes pour considérer une duplication. Par défaut: 5
.PARAMETER SimilarityThreshold
    Seuil de similarité (0-1) pour considérer deux blocs comme similaires. Par défaut: 0.8
.PARAMETER ScriptType
    Type de script à analyser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par défaut: All
.PARAMETER ShowDetails
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Find-CodeDuplication.ps1
    Analyse tous les scripts dans le dossier scripts et génère un rapport.
.EXAMPLE
    .\Find-CodeDuplication.ps1 -Path "scripts\maintenance" -MinimumLineCount 10
    Analyse les scripts dans le dossier spécifié avec un seuil de 10 lignes.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\manager\data\duplication_report.json",
    [int]$MinimumLineCount = 5,
    [double]$SimilarityThreshold = 0.8,
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
    [switch]$ShowDetails
)

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Écrire dans un fichier de log
    $LogFile = "scripts\manager\data\duplication_detection.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour obtenir tous les fichiers de script
function Get-ScriptFiles {
    param (
        [string]$Path,
        [string]$ScriptType
    )
    
    $ScriptExtensions = @{
        "PowerShell" = @("*.ps1", "*.psm1", "*.psd1")
        "Python" = @("*.py")
        "Batch" = @("*.cmd", "*.bat")
        "Shell" = @("*.sh")
    }
    
    $Files = @()
    
    if ($ScriptType -eq "All") {
        foreach ($Type in $ScriptExtensions.Keys) {
            foreach ($Extension in $ScriptExtensions[$Type]) {
                $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
            }
        }
    } else {
        foreach ($Extension in $ScriptExtensions[$ScriptType]) {
            $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
        }
    }
    
    return $Files
}

# Fonction pour déterminer le type de script
function Get-ScriptType {
    param (
        [string]$FilePath
    )
    
    $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    switch ($Extension) {
        ".ps1" { return "PowerShell" }
        ".psm1" { return "PowerShell" }
        ".psd1" { return "PowerShell" }
        ".py" { return "Python" }
        ".cmd" { return "Batch" }
        ".bat" { return "Batch" }
        ".sh" { return "Shell" }
        default { return "Unknown" }
    }
}

# Fonction pour normaliser le contenu du script
function Get-NormalizedContent {
    param (
        [string]$Content,
        [string]$ScriptType
    )
    
    # Supprimer les commentaires et les lignes vides
    $Lines = $Content -split "`r?`n"
    $NormalizedLines = @()
    
    foreach ($Line in $Lines) {
        $TrimmedLine = $Line.Trim()
        
        # Ignorer les lignes vides
        if ([string]::IsNullOrWhiteSpace($TrimmedLine)) {
            continue
        }
        
        # Ignorer les commentaires selon le type de script
        $IsComment = switch ($ScriptType) {
            "PowerShell" { $TrimmedLine.StartsWith("#") -or $TrimmedLine.StartsWith("<#") }
            "Python" { $TrimmedLine.StartsWith("#") }
            "Batch" { $TrimmedLine.StartsWith("::") -or $TrimmedLine.StartsWith("REM ") }
            "Shell" { $TrimmedLine.StartsWith("#") }
            default { $false }
        }
        
        if (-not $IsComment) {
            # Normaliser les espaces
            $NormalizedLine = $TrimmedLine -replace "\s+", " "
            $NormalizedLines += $NormalizedLine
        }
    }
    
    return $NormalizedLines
}

# Fonction pour extraire les blocs de code
function Get-CodeBlocks {
    param (
        [string[]]$NormalizedLines,
        [int]$MinimumLineCount
    )
    
    $Blocks = @()
    
    for ($i = 0; $i -le $NormalizedLines.Count - $MinimumLineCount; $i++) {
        $Block = $NormalizedLines[$i..($i + $MinimumLineCount - 1)]
        $BlockText = $Block -join "`n"
        $Blocks += [PSCustomObject]@{
            StartLine = $i
            EndLine = $i + $MinimumLineCount - 1
            LineCount = $MinimumLineCount
            Text = $BlockText
            Hash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($BlockText)))).Hash
        }
    }
    
    return $Blocks
}

# Fonction pour calculer la similarité entre deux chaînes
function Get-StringSimilarity {
    param (
        [string]$String1,
        [string]$String2
    )
    
    # Utiliser la distance de Levenshtein pour calculer la similarité
    $MaxLength = [Math]::Max($String1.Length, $String2.Length)
    if ($MaxLength -eq 0) {
        return 1.0
    }
    
    $Distance = Get-LevenshteinDistance -String1 $String1 -String2 $String2
    $Similarity = 1 - ($Distance / $MaxLength)
    
    return $Similarity
}

# Fonction pour calculer la distance de Levenshtein
function Get-LevenshteinDistance {
    param (
        [string]$String1,
        [string]$String2
    )
    
    $Len1 = $String1.Length
    $Len2 = $String2.Length
    
    # Créer une matrice pour stocker les distances
    $Matrix = New-Object 'int[,]' ($Len1 + 1), ($Len2 + 1)
    
    # Initialiser la première colonne et la première ligne
    for ($i = 0; $i -le $Len1; $i++) {
        $Matrix[$i, 0] = $i
    }
    
    for ($j = 0; $j -le $Len2; $j++) {
        $Matrix[0, $j] = $j
    }
    
    # Remplir la matrice
    for ($i = 1; $i -le $Len1; $i++) {
        for ($j = 1; $j -le $Len2; $j++) {
            $Cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            $Matrix[$i, $j] = [Math]::Min(
                [Math]::Min(
                    $Matrix[$i - 1, $j] + 1,     # Suppression
                    $Matrix[$i, $j - 1] + 1      # Insertion
                ),
                $Matrix[$i - 1, $j - 1] + $Cost  # Substitution
            )
        }
    }
    
    return $Matrix[$Len1, $Len2]
}

# Fonction pour trouver les duplications dans un fichier
function Find-DuplicationsInFile {
    param (
        [string]$FilePath,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold
    )
    
    $ScriptType = Get-ScriptType -FilePath $FilePath
    
    if ($ScriptType -eq "Unknown") {
        Write-Log "Type de script inconnu: $FilePath" -Level "WARNING"
        return @()
    }
    
    try {
        $Content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $NormalizedLines = Get-NormalizedContent -Content $Content -ScriptType $ScriptType
        
        if ($NormalizedLines.Count -lt $MinimumLineCount) {
            return @()
        }
        
        $Blocks = Get-CodeBlocks -NormalizedLines $NormalizedLines -MinimumLineCount $MinimumLineCount
        $Duplications = @()
        
        # Comparer les blocs entre eux
        for ($i = 0; $i -lt $Blocks.Count; $i++) {
            for ($j = $i + 1; $j -lt $Blocks.Count; $j++) {
                # Si les hachages sont identiques, c'est une duplication exacte
                if ($Blocks[$i].Hash -eq $Blocks[$j].Hash) {
                    $Duplications += [PSCustomObject]@{
                        Type = "Exact"
                        Block1 = $Blocks[$i]
                        Block2 = $Blocks[$j]
                        Similarity = 1.0
                    }
                } else {
                    # Sinon, calculer la similarité
                    $Similarity = Get-StringSimilarity -String1 $Blocks[$i].Text -String2 $Blocks[$j].Text
                    
                    if ($Similarity -ge $SimilarityThreshold) {
                        $Duplications += [PSCustomObject]@{
                            Type = "Similar"
                            Block1 = $Blocks[$i]
                            Block2 = $Blocks[$j]
                            Similarity = $Similarity
                        }
                    }
                }
            }
        }
        
        return $Duplications
    } catch {
        Write-Log "Erreur lors de l'analyse du fichier $FilePath : $_" -Level "ERROR"
        return @()
    }
}

# Fonction pour trouver les duplications entre fichiers
function Find-DuplicationsBetweenFiles {
    param (
        [array]$Files,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold
    )
    
    $AllBlocks = @{}
    $Duplications = @()
    
    # Extraire les blocs de code de chaque fichier
    foreach ($File in $Files) {
        $ScriptType = Get-ScriptType -FilePath $File.FullName
        
        if ($ScriptType -eq "Unknown") {
            continue
        }
        
        try {
            $Content = Get-Content -Path $File.FullName -Raw -ErrorAction Stop
            $NormalizedLines = Get-NormalizedContent -Content $Content -ScriptType $ScriptType
            
            if ($NormalizedLines.Count -lt $MinimumLineCount) {
                continue
            }
            
            $Blocks = Get-CodeBlocks -NormalizedLines $NormalizedLines -MinimumLineCount $MinimumLineCount
            $AllBlocks[$File.FullName] = $Blocks
        } catch {
            Write-Log "Erreur lors de l'analyse du fichier $($File.FullName) : $_" -Level "ERROR"
        }
    }
    
    # Comparer les blocs entre fichiers
    $FileNames = $AllBlocks.Keys
    for ($i = 0; $i -lt $FileNames.Count; $i++) {
        for ($j = $i + 1; $j -lt $FileNames.Count; $j++) {
            $File1 = $FileNames[$i]
            $File2 = $FileNames[$j]
            
            foreach ($Block1 in $AllBlocks[$File1]) {
                foreach ($Block2 in $AllBlocks[$File2]) {
                    # Si les hachages sont identiques, c'est une duplication exacte
                    if ($Block1.Hash -eq $Block2.Hash) {
                        $Duplications += [PSCustomObject]@{
                            Type = "Exact"
                            File1 = $File1
                            Block1 = $Block1
                            File2 = $File2
                            Block2 = $Block2
                            Similarity = 1.0
                        }
                    } else {
                        # Sinon, calculer la similarité
                        $Similarity = Get-StringSimilarity -String1 $Block1.Text -String2 $Block2.Text
                        
                        if ($Similarity -ge $SimilarityThreshold) {
                            $Duplications += [PSCustomObject]@{
                                Type = "Similar"
                                File1 = $File1
                                Block1 = $Block1
                                File2 = $File2
                                Block2 = $Block2
                                Similarity = $Similarity
                            }
                        }
                    }
                }
            }
        }
    }
    
    return $Duplications
}

# Fonction principale
function Start-DuplicationDetection {
    param (
        [string]$Path,
        [string]$OutputPath,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold,
        [string]$ScriptType,
        [switch]$ShowDetails
    )
    
    Write-Log "Démarrage de la détection des duplications de code..." -Level "TITLE"
    Write-Log "Dossier des scripts: $Path" -Level "INFO"
    Write-Log "Nombre minimum de lignes: $MinimumLineCount" -Level "INFO"
    Write-Log "Seuil de similarité: $SimilarityThreshold" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Fichier de sortie: $OutputPath" -Level "INFO"
    
    # Vérifier si le dossier des scripts existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le dossier des scripts n'existe pas: $Path" -Level "ERROR"
        return
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputDir" -Level "SUCCESS"
    }
    
    # Obtenir tous les fichiers de script
    $ScriptFiles = Get-ScriptFiles -Path $Path -ScriptType $ScriptType
    $TotalFiles = $ScriptFiles.Count
    Write-Log "Nombre de fichiers à analyser: $TotalFiles" -Level "INFO"
    
    # Initialiser les résultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalFiles = $TotalFiles
        ScriptType = $ScriptType
        MinimumLineCount = $MinimumLineCount
        SimilarityThreshold = $SimilarityThreshold
        IntraFileDuplications = @()
        InterFileDuplications = @()
    }
    
    # Analyser chaque fichier pour les duplications internes
    $FileCounter = 0
    foreach ($File in $ScriptFiles) {
        $FileCounter++
        $Progress = [math]::Round(($FileCounter / $TotalFiles) * 100)
        Write-Progress -Activity "Analyse des duplications internes" -Status "$FileCounter / $TotalFiles ($Progress%)" -PercentComplete $Progress
        
        if ($ShowDetails) {
            Write-Log "Analyse du fichier: $($File.FullName)" -Level "INFO"
        }
        
        # Trouver les duplications dans le fichier
        $Duplications = Find-DuplicationsInFile -FilePath $File.FullName -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold
        
        if ($Duplications.Count -gt 0) {
            $Results.IntraFileDuplications += [PSCustomObject]@{
                FilePath = $File.FullName
                Duplications = $Duplications
            }
            
            if ($ShowDetails) {
                Write-Log "  Duplications trouvées: $($Duplications.Count)" -Level "WARNING"
            }
        }
    }
    
    Write-Progress -Activity "Analyse des duplications internes" -Completed
    
    # Analyser les duplications entre fichiers
    Write-Log "Analyse des duplications entre fichiers..." -Level "INFO"
    $InterFileDuplications = Find-DuplicationsBetweenFiles -Files $ScriptFiles -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold
    $Results.InterFileDuplications = $InterFileDuplications
    
    # Enregistrer les résultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un résumé
    $IntraFileCount = ($Results.IntraFileDuplications | Measure-Object -Property Duplications -Sum).Sum
    $InterFileCount = $Results.InterFileDuplications.Count
    Write-Log "Analyse terminée" -Level "SUCCESS"
    Write-Log "Nombre total de fichiers analysés: $TotalFiles" -Level "INFO"
    Write-Log "Nombre de duplications internes trouvées: $IntraFileCount" -Level "WARNING"
    Write-Log "Nombre de duplications entre fichiers trouvées: $InterFileCount" -Level "WARNING"
    Write-Log "Résultats enregistrés dans: $OutputPath" -Level "SUCCESS"
    
    return $Results
}

# Exécuter la fonction principale
Start-DuplicationDetection -Path $Path -OutputPath $OutputPath -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -ScriptType $ScriptType -ShowDetails:$ShowDetails
