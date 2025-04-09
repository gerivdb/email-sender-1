<#
.SYNOPSIS
    Teste la Phase 3 : Élimination des duplications.
.DESCRIPTION
    Ce script teste spécifiquement la Phase 3 du projet de réorganisation des scripts,
    qui concerne l'élimination des duplications. Il vérifie que les duplications de code
    ont été éliminées et que les fonctions communes ont été extraites.
.PARAMETER Path
    Chemin du dossier contenant les scripts à tester. Par défaut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport de test. Par défaut: scripts\tests\duplications_test_report.json
.PARAMETER MinimumLineCount
    Nombre minimum de lignes pour considérer une duplication. Par défaut: 5
.PARAMETER SimilarityThreshold
    Seuil de similarité (0-1) pour considérer deux blocs comme similaires. Par défaut: 0.8
.PARAMETER Verbose
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Test-Phase3-Duplications.ps1
    Teste la Phase 3 sur tous les scripts du dossier "scripts".
.EXAMPLE
    .\Test-Phase3-Duplications.ps1 -Path "scripts\maintenance" -MinimumLineCount 10 -Verbose
    Teste la Phase 3 sur les scripts du dossier "scripts\maintenance" avec un seuil de 10 lignes et des informations détaillées.
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "scripts\tests\duplications_test_report.json",
    [int]$MinimumLineCount = 5,
    [double]$SimilarityThreshold = 0.8,
    [switch]$Verbose
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
    $LogFile = "scripts\tests\test_results.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour obtenir tous les fichiers de script
function Get-ScriptFiles {
    param (
        [string]$Path
    )
    
    $ScriptExtensions = @("*.ps1", "*.py", "*.cmd", "*.bat", "*.sh")
    $Files = @()
    
    foreach ($Extension in $ScriptExtensions) {
        $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
    }
    
    return $Files
}

# Fonction pour calculer le hachage d'un bloc de code
function Get-BlockHash {
    param (
        [string]$BlockText
    )
    
    # Normaliser le texte (supprimer les espaces, tabulations, etc.)
    $NormalizedText = $BlockText -replace '\s+', ' ' -replace '\s*\r?\n\s*', '\n'
    
    # Calculer le hachage SHA256
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    $HashBytes = $SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($NormalizedText))
    $Hash = [BitConverter]::ToString($HashBytes) -replace '-', ''
    
    return $Hash
}

# Fonction pour diviser un fichier en blocs de code
function Get-CodeBlocks {
    param (
        [string]$FilePath,
        [int]$MinimumLineCount
    )
    
    $Content = Get-Content -Path $FilePath -Raw
    $Lines = $Content -split '\r?\n'
    $Blocks = @()
    
    # Ignorer les fichiers vides ou trop courts
    if ($Lines.Count -lt $MinimumLineCount) {
        return $Blocks
    }
    
    # Créer des blocs de code de taille variable
    for ($i = 0; $i -le $Lines.Count - $MinimumLineCount; $i++) {
        for ($j = $MinimumLineCount; $j -le [Math]::Min(50, $Lines.Count - $i); $j++) {
            $BlockLines = $Lines[$i..($i + $j - 1)]
            $BlockText = $BlockLines -join "`n"
            
            # Ignorer les blocs vides ou trop courts
            if ($BlockText.Trim().Length -lt 50) {
                continue
            }
            
            $Block = @{
                StartLine = $i + 1
                EndLine = $i + $j
                LineCount = $j
                Text = $BlockText
                Hash = Get-BlockHash -BlockText $BlockText
            }
            
            $Blocks += $Block
        }
    }
    
    return $Blocks
}

# Fonction pour calculer la similarité entre deux blocs de code
function Get-Similarity {
    param (
        [string]$Text1,
        [string]$Text2
    )
    
    # Utiliser la distance de Levenshtein pour calculer la similarité
    $MaxLength = [Math]::Max($Text1.Length, $Text2.Length)
    if ($MaxLength -eq 0) {
        return 1.0
    }
    
    $Distance = Get-LevenshteinDistance -String1 $Text1 -String2 $Text2
    $Similarity = 1.0 - ($Distance / $MaxLength)
    
    return $Similarity
}

# Fonction pour calculer la distance de Levenshtein entre deux chaînes
function Get-LevenshteinDistance {
    param (
        [string]$String1,
        [string]$String2
    )
    
    $Len1 = $String1.Length
    $Len2 = $String2.Length
    
    # Créer une matrice de distance
    $Distance = New-Object 'int[,]' ($Len1 + 1), ($Len2 + 1)
    
    # Initialiser la première colonne
    for ($i = 0; $i -le $Len1; $i++) {
        $Distance[$i, 0] = $i
    }
    
    # Initialiser la première ligne
    for ($j = 0; $j -le $Len2; $j++) {
        $Distance[0, $j] = $j
    }
    
    # Remplir la matrice
    for ($i = 1; $i -le $Len1; $i++) {
        for ($j = 1; $j -le $Len2; $j++) {
            $Cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            $Distance[$i, $j] = [Math]::Min(
                [Math]::Min(
                    $Distance[$i - 1, $j] + 1,     # Suppression
                    $Distance[$i, $j - 1] + 1      # Insertion
                ),
                $Distance[$i - 1, $j - 1] + $Cost  # Substitution
            )
        }
    }
    
    return $Distance[$Len1, $Len2]
}

# Fonction pour détecter les duplications dans un fichier
function Find-IntraFileDuplications {
    param (
        [string]$FilePath,
        [int]$MinimumLineCount
    )
    
    $Blocks = Get-CodeBlocks -FilePath $FilePath -MinimumLineCount $MinimumLineCount
    $Duplications = @()
    
    # Comparer les blocs entre eux
    for ($i = 0; $i -lt $Blocks.Count; $i++) {
        $Block1 = $Blocks[$i]
        
        for ($j = $i + 1; $j -lt $Blocks.Count; $j++) {
            $Block2 = $Blocks[$j]
            
            # Vérifier si les blocs se chevauchent
            if ($Block1.EndLine -ge $Block2.StartLine) {
                continue
            }
            
            # Vérifier si les hachages sont identiques
            if ($Block1.Hash -eq $Block2.Hash) {
                $Duplications += @{
                    File = $FilePath
                    Block1 = $Block1
                    Block2 = $Block2
                    Type = "Exact"
                    Similarity = 1.0
                }
            }
        }
    }
    
    return $Duplications
}

# Fonction pour détecter les duplications entre fichiers
function Find-InterFileDuplications {
    param (
        [array]$Files,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold
    )
    
    $AllBlocks = @{}
    $Duplications = @()
    
    # Extraire les blocs de code de chaque fichier
    foreach ($File in $Files) {
        $Blocks = Get-CodeBlocks -FilePath $File.FullName -MinimumLineCount $MinimumLineCount
        $AllBlocks[$File.FullName] = $Blocks
    }
    
    # Comparer les blocs entre fichiers
    $FileList = $Files.FullName
    for ($i = 0; $i -lt $FileList.Count; $i++) {
        $File1 = $FileList[$i]
        $Blocks1 = $AllBlocks[$File1]
        
        for ($j = $i + 1; $j -lt $FileList.Count; $j++) {
            $File2 = $FileList[$j]
            $Blocks2 = $AllBlocks[$File2]
            
            # Comparer les blocs entre les deux fichiers
            foreach ($Block1 in $Blocks1) {
                foreach ($Block2 in $Blocks2) {
                    # Vérifier si les hachages sont identiques
                    if ($Block1.Hash -eq $Block2.Hash) {
                        $Duplications += @{
                            File1 = $File1
                            File2 = $File2
                            Block1 = $Block1
                            Block2 = $Block2
                            Type = "Exact"
                            Similarity = 1.0
                        }
                    } else {
                        # Calculer la similarité entre les blocs
                        $Similarity = Get-Similarity -Text1 $Block1.Text -Text2 $Block2.Text
                        
                        if ($Similarity -ge $SimilarityThreshold) {
                            $Duplications += @{
                                File1 = $File1
                                File2 = $File2
                                Block1 = $Block1
                                Block2 = $Block2
                                Type = "Similar"
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
function Test-Duplications {
    param (
        [string]$Path,
        [string]$OutputPath,
        [int]$MinimumLineCount,
        [double]$SimilarityThreshold,
        [switch]$Verbose
    )
    
    Write-Log "=== Test de la Phase 3 : Élimination des duplications ===" -Level "TITLE"
    Write-Log "Chemin des scripts à tester: $Path" -Level "INFO"
    Write-Log "Nombre minimum de lignes: $MinimumLineCount" -Level "INFO"
    Write-Log "Seuil de similarité: $SimilarityThreshold" -Level "INFO"
    
    # Créer le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputDir" -Level "INFO"
    }
    
    # Obtenir tous les fichiers de script
    $ScriptFiles = Get-ScriptFiles -Path $Path
    $TotalFiles = $ScriptFiles.Count
    Write-Log "Nombre de fichiers à analyser: $TotalFiles" -Level "INFO"
    
    # Initialiser les résultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalFiles = $TotalFiles
        MinimumLineCount = $MinimumLineCount
        SimilarityThreshold = $SimilarityThreshold
        IntraFileDuplications = @()
        InterFileDuplications = @()
    }
    
    # Détecter les duplications dans chaque fichier
    Write-Log "Détection des duplications internes..." -Level "INFO"
    $FileCounter = 0
    foreach ($File in $ScriptFiles) {
        $FileCounter++
        $Progress = [math]::Round(($FileCounter / $TotalFiles) * 100)
        Write-Progress -Activity "Détection des duplications internes" -Status "$FileCounter / $TotalFiles ($Progress%)" -PercentComplete $Progress
        
        if ($Verbose) {
            Write-Log "Analyse du fichier: $($File.FullName)" -Level "INFO"
        }
        
        $Duplications = Find-IntraFileDuplications -FilePath $File.FullName -MinimumLineCount $MinimumLineCount
        
        if ($Duplications.Count -gt 0) {
            $Results.IntraFileDuplications += @{
                File = $File.FullName
                Duplications = $Duplications.Count
                Details = $Duplications
            }
            
            if ($Verbose) {
                Write-Log "  Duplications internes trouvées: $($Duplications.Count)" -Level "WARNING"
            }
        }
    }
    
    Write-Progress -Activity "Détection des duplications internes" -Completed
    
    # Détecter les duplications entre fichiers
    Write-Log "Détection des duplications entre fichiers..." -Level "INFO"
    $InterFileDuplications = Find-InterFileDuplications -Files $ScriptFiles -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold
    $Results.InterFileDuplications = $InterFileDuplications
    
    # Enregistrer les résultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un résumé
    $IntraFileCount = ($Results.IntraFileDuplications | Measure-Object -Property Duplications -Sum).Sum
    $InterFileCount = $Results.InterFileDuplications.Count
    
    Write-Log "Analyse terminée" -Level "SUCCESS"
    Write-Log "Nombre total de fichiers analysés: $TotalFiles" -Level "INFO"
    Write-Log "Nombre de duplications internes trouvées: $IntraFileCount" -Level $(if ($IntraFileCount -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Log "Nombre de duplications entre fichiers trouvées: $InterFileCount" -Level $(if ($InterFileCount -gt 0) { "WARNING" } else { "SUCCESS" })
    Write-Log "Résultats enregistrés dans: $OutputPath" -Level "SUCCESS"
    
    # Déterminer si le test est réussi
    if ($InterFileCount -gt 10) {
        Write-Log "Un nombre important de duplications entre fichiers a été détecté" -Level "WARNING"
        Write-Log "La Phase 3 n'a pas complètement réussi" -Level "WARNING"
        return $false
    } elseif ($InterFileCount -gt 0) {
        Write-Log "Quelques duplications entre fichiers ont été détectées" -Level "WARNING"
        Write-Log "La Phase 3 a partiellement réussi" -Level "WARNING"
        return $true
    } else {
        Write-Log "Aucune duplication significative détectée" -Level "SUCCESS"
        Write-Log "La Phase 3 a réussi" -Level "SUCCESS"
        return $true
    }
}

# Exécuter le test
$Success = Test-Duplications -Path $Path -OutputPath $OutputPath -MinimumLineCount $MinimumLineCount -SimilarityThreshold $SimilarityThreshold -Verbose:$Verbose

# Retourner le résultat
return $Success
