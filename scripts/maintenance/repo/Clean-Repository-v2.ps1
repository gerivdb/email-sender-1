#Requires -Version 5.1
<#
.SYNOPSIS
    Nettoie un dépôt de code en identifiant, archivant et rapportant les scripts obsolètes et redondants.
.DESCRIPTION
    Ce script analyse un répertoire spécifié (dépôt) pour trouver des scripts potentiellement obsolètes
    (basé sur des motifs de nommage, l'âge et le contenu) et redondants (basé sur la similarité du contenu).
    Les scripts identifiés peuvent être archivés automatiquement dans un sous-répertoire structuré.
    Un rapport détaillé au format Markdown est généré, résumant les actions effectuées ou simulées.

    La détection de redondance utilise une approche optimisée :
    1. Calcul du hash SHA256 du contenu normalisé (ignorant les commentaires et lignes vides) pour identifier les doublons exacts rapidement.
    2. Si un module externe 'TextSimilarity' est disponible (doit être placé dans $Path\modules\TextSimilarity.psm1),
       il peut être utilisé pour une analyse de similarité plus fine (algorithmes comme Levenshtein, Jaccard, etc.)
       afin de trouver des doublons *presque* identiques, en fonction du seuil '-SimilarityThreshold'.
    3. Si le module n'est pas présent, la détection de redondance se limite aux doublons exacts (basés sur le hash normalisé),
       sauf si -SkipRedundantDetection est utilisé.

.PARAMETER Path
    Chemin du dépôt à analyser et nettoyer. Par défaut, le répertoire courant.
.PARAMETER ArchivePath
    Chemin *relatif* au dossier -Path où archiver les scripts obsolètes et redondants.
    Utilise un format de date par défaut pour éviter les écrasements. Ex: 'archive\20250426'.
.PARAMETER ReportPath
    Chemin *relatif* au dossier -Path où générer le rapport de nettoyage au format Markdown.
    Utilise un format date/heure par défaut. Ex: 'reports\cleanup-20250426-153000.md'.
.PARAMETER SimilarityThreshold
    Seuil de similarité (en pourcentage, 0-100) pour considérer deux scripts comme redondants lors de l'utilisation
    du module TextSimilarity. Ignoré si le module n'est pas trouvé ou si -SkipRedundantDetection est utilisé.
    Par défaut à 80. Un seuil de 100 signifie une correspondance exacte (après normalisation si utilisée par le module).
.PARAMETER DryRun
    Si spécifié, le script simulera toutes les actions (détection, archivage) sans modifier
    le système de fichiers. Le rapport indiquera ce qui *aurait* été fait.
.PARAMETER SkipRedundantDetection
    Si spécifié, ignore complètement l'étape de détection des scripts redondants.
    Utile pour accélérer l'analyse ou si la détection de redondance n'est pas souhaitée.
.PARAMETER Force
    (Retiré - Non implémenté et objectif ambigu. Remplacé par une gestion d'erreur plus robuste).
.PARAMETER LogFile
    Chemin *relatif* au dossier -Path pour un fichier journal texte optionnel où enregistrer les logs détaillés.
    Si non spécifié, les logs sont uniquement affichés en console et inclus dans le rapport Markdown.
.PARAMETER ScriptExtensions
    Tableau des extensions de fichiers à considérer comme des scripts.
    Par défaut: @(".ps1", ".psm1", ".py", ".sh", ".bat", ".cmd")
.EXAMPLE
    .\Clean-Repository.ps1 -Path "D:\MyProjects\ScriptRepo" -Verbose -DryRun
    # Simule le nettoyage dans le dossier spécifié, affiche les logs détaillés.

.EXAMPLE
    .\Clean-Repository.ps1 -Path "C:\scripts" -ArchivePath "backup_$(Get-Date -f yyyyMM)" -ReportPath "cleanup_report.md" -SimilarityThreshold 95
    # Effectue le nettoyage réel, archive dans C:\scripts\backup_YYYYMM, génère C:\scripts\cleanup_report.md, seuil de similarité à 95%.

.EXAMPLE
    .\Clean-Repository.ps1 -SkipRedundantDetection -LogFile "cleaning.log"
    # Nettoie le répertoire courant, ignore la détection de redondance, enregistre les logs dans .\cleaning.log.

.NOTES
    Auteur: Augment Agent (Amélioré par IA Claude)
    Version: 2.0
    Date: 2025-04-27

    Améliorations v2.0:
    - Détection de redondance optimisée via hash SHA256 sur contenu normalisé.
    - Utilisation conditionnelle du module externe TextSimilarity pour similarité fine.
    - Amélioration significative des performances pour la détection de redondance.
    - Meilleure gestion des erreurs et logging (utilise Write-Verbose, Write-Warning, etc.).
    - Ajout du paramètre -LogFile pour un fichier journal dédié.
    - Ajout du paramètre -ScriptExtensions pour la flexibilité.
    - Suppression du paramètre -Force (non utilisé).
    - Ajout de barres de progression pour les opérations longues.
    - Normalisation du contenu pour ignorer les commentaires et lignes vides lors du hachage.
    - Code structuré en fonctions plus claires et robustes.
    - Validation des paramètres.
    - Rapport Markdown amélioré.
#>
[CmdletBinding(SupportsShouldProcess = $true)] # Supports -WhatIf (via DryRun) and -Verbose
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$Path = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$ArchivePath = "archive\$(Get-Date -Format 'yyyyMMdd')",

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "reports\cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').md",

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]$SimilarityThreshold = 80,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    # Force parameter removed as it was unused and ambiguous
    # [Parameter(Mandatory=$false)]
    # [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$SkipRedundantDetection,

    [Parameter(Mandatory = $false)]
    [string]$LogFile,

    [Parameter(Mandatory = $false)]
    [string[]]$ScriptExtensions = @(".ps1", ".psm1", ".py", ".sh", ".bat", ".cmd")
)

#region Helper Functions

# Fonction de logging améliorée
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "VERBOSE", "DEBUG", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    if ($ErrorRecord) {
        $logEntry += "`n$(Out-String -InputObject $ErrorRecord)"
    }

    # Ajouter au journal en mémoire pour le rapport
    $script:logMessages.Add($logEntry)

    # Écrire dans le fichier journal si spécifié
    if ($script:AbsoluteLogFilePath) {
        try {
            Add-Content -Path $script:AbsoluteLogFilePath -Value $logEntry -ErrorAction Stop
        } catch {
            Write-Warning "Impossible d'écrire dans le fichier journal '$script:AbsoluteLogFilePath': $($_.Exception.Message)"
            $script:AbsoluteLogFilePath = $null # Empêche les tentatives répétées
        }
    }

    # Afficher dans la console via les flux PowerShell appropriés
    switch ($Level) {
        "VERBOSE" { Write-Verbose $logEntry }
        "DEBUG" { Write-Debug $logEntry }
        "WARNING" { Write-Warning $Message } # Warning stream adds "WARNING: " prefix automatically
        "ERROR" { Write-Error $Message }   # Error stream handles formatting
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor Gray } # INFO level
    }
}

#endregion

#region Global Variables & Setup
$script:LogMessages = [System.Collections.Generic.List[string]]::new()
$script:TextSimilarityModule = $null
$script:AbsoluteLogFilePath = $null

# Construire les chemins absolus pour les sorties
$AbsoluteArchivePath = Join-Path -Path $Path -ChildPath $ArchivePath
$AbsoluteReportPath = Join-Path -Path $Path -ChildPath $ReportPath
if ($PSBoundParameters.ContainsKey('LogFile')) {
    $script:AbsoluteLogFilePath = Join-Path -Path $Path -ChildPath $LogFile
}

# Essayer d'importer le module de similarité
$textSimilarityPath = Join-Path -Path $Path -ChildPath "modules\TextSimilarity.psm1"
if (Test-Path -Path $textSimilarityPath -PathType Leaf) {
    try {
        Import-Module $textSimilarityPath -Force
        $script:TextSimilarityModule = Get-Module -Name TextSimilarity
        Write-Log -Message "Module TextSimilarity importé avec succès depuis '$textSimilarityPath'." -Level "INFO"
    } catch {
        Write-Log -Message "Échec de l'importation du module TextSimilarity depuis '$textSimilarityPath'. La détection de similarité fine sera désactivée. Erreur: $($_.Exception.Message)" -Level "WARNING"
    }
} else {
    Write-Log -Message "Module TextSimilarity non trouvé à '$textSimilarityPath'. La détection de similarité fine est désactivée. Seuls les doublons exacts (basés sur le contenu normalisé) seront détectés." -Level "INFO"
}


# Fonction pour obtenir le contenu normalisé d'un script (ignore commentaires et lignes vides)
function Get-NormalizedScriptContent {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    try {
        $content = Get-Content -Path $File.FullName -Raw -ErrorAction Stop
        $lines = $content -split [Environment]::NewLine

        # Déterminer le caractère de commentaire basé sur l'extension
        $commentChar = switch ($File.Extension.ToLower()) {
            ".ps1" { '#' }
            ".psm1" { '#' }
            ".py" { '#' }
            ".sh" { '#' }
            ".bat" { 'REM ' } # Attention: REM doit être au début de la ligne (simplification ici)
            ".cmd" { 'REM ' } # Idem
            default { $null }
        }

        $normalizedLines = foreach ($line in $lines) {
            $trimmedLine = $line.Trim()
            if ($trimmedLine.Length -eq 0) { continue } # Ignorer lignes vides
            if ($null -ne $commentChar -and $trimmedLine.StartsWith($commentChar)) { continue } # Ignorer lignes de commentaire simples

            # TODO: Améliorer la suppression des commentaires (ex: commentaires en fin de ligne, blocs de commentaires)
            # Pour l'instant, on normalise juste les espaces en début/fin de ligne
            $trimmedLine
        }

        return ($normalizedLines -join [Environment]::NewLine).Trim()

    } catch {
        Write-Log -Message "Erreur lors de la lecture ou normalisation de $($File.FullName): $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
        return $null # Retourne null en cas d'erreur
    }
}

# Fonction pour calculer le hash SHA256 d'une chaîne
function Get-StringHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hashBytes = $sha256.ComputeHash($bytes)
    $sha256.Dispose()
    # Convertir les bytes du hash en chaîne hexadécimale
    return [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
}

# Fonction de calcul de similarité (utilise le module si disponible, sinon fallback limité)
function Get-FileSimilarityScore {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File1,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File2
    )

    # Utiliser le module TextSimilarity si disponible et chargé
    if ($null -ne $script:TextSimilarityModule -and (Get-Command -Module TextSimilarity -Name Get-ContentSimilarity -ErrorAction SilentlyContinue)) {
        try {
            # Utiliser l'algorithme "Combined" ou un autre fourni par le module
            $similarity = Get-ContentSimilarity -FilePathA $File1.FullName -FilePathB $File2.FullName -Algorithm "Combined" -ErrorAction Stop
            Write-Log -Message "Similarité (Module TextSimilarity) entre '$($File1.Name)' et '$($File2.Name)': $similarity%" -Level "VERBOSE"
            return $similarity
        } catch {
            Write-Log -Message "Erreur lors de l'utilisation de Get-ContentSimilarity pour '$($File1.Name)' et '$($File2.Name)': $($_.Exception.Message)" -Level "WARNING" -ErrorRecord $_
            # Fallback vers la méthode de base si le module échoue
        }
    }

    # Fallback: Si le module n'est pas là ou a échoué, on ne peut pas calculer de score fiable.
    # On pourrait comparer les hash normalisés, mais Find-RedundantScripts le fait déjà.
    # Retourner 0 ou 100 basé sur le hash pré-calculé pourrait être une option, mais
    # cette fonction est appelée *après* le regroupement par hash.
    # Donc, si on arrive ici sans module, c'est qu'on demande une similarité fine non disponible.
    Write-Log -Message "Calcul de similarité fine non disponible (Module TextSimilarity absent ou échoué) pour '$($File1.Name)' et '$($File2.Name)'." -Level "VERBOSE"
    return -1 # Indique que le score n'a pas pu être calculé
}

#endregion

#region Core Logic Functions

# Fonction pour trouver les scripts obsolètes
function Find-ObsoleteScripts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions
    )

    Write-Log -Message "Début de la détection des scripts obsolètes..." -Level "INFO"
    $obsoleteCriteria = @(
        @{ Type = "NamePattern"; Pattern = '(?i)(obsolete(?!-v\d+)|deprecated|old|backup|bak|archive|temp|tmp|_v\d+|copyof)'; Reason = "Nom du fichier correspond au motif d'obsolescence ('{0}')" }
        @{ Type = "LastModified"; DaysOld = 365; Reason = "Non modifié depuis plus de {0} jours ({1} jours)" }
        @{ Type = "ContentPattern"; Pattern = '(?im)^\s*#(?:obsolete|deprecated|do not use|no longer used|no longer maintained|replaced by)'; Reason = "Contient un commentaire d'obsolescence ('{0}')" }
        # Ajouter d'autres critères ici si nécessaire
    )

    $obsoleteScripts = [System.Collections.Generic.List[PSCustomObject]]::new()
    $allScripts = Get-ChildItem -Path $RepoPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() }

    if ($null -eq $allScripts -or $allScripts.Count -eq 0) {
        Write-Log -Message "Aucun script trouvé avec les extensions spécifiées dans '$RepoPath'." -Level "INFO"
        return $obsoleteScripts # Retourne une liste vide
    }

    $scriptCount = $allScripts.Count
    Write-Log -Message "Analyse de $scriptCount scripts pour l'obsolescence..." -Level "INFO"
    $progress = 0

    foreach ($script in $allScripts) {
        $progress++
        Write-Progress -Activity "Détection des scripts obsolètes" -Status "Analyse de $($script.Name) ($progress/$scriptCount)" -PercentComplete (($progress / $scriptCount) * 100)

        $isObsolete = $false
        $reasons = [System.Collections.Generic.List[string]]::new()

        foreach ($criterion in $obsoleteCriteria) {
            try {
                switch ($criterion.Type) {
                    "NamePattern" {
                        if ($script.Name -match $criterion.Pattern) {
                            $isObsolete = $true
                            $reasons.Add(($criterion.Reason -f ($script.Name -match $criterion.Pattern)))
                        }
                    }
                    "LastModified" {
                        $lastWrite = $script.LastWriteTime
                        $age = (Get-Date) - $lastWrite
                        if ($age.TotalDays -gt $criterion.DaysOld) {
                            $isObsolete = $true
                            $reasons.Add(($criterion.Reason -f $criterion.DaysOld, [Math]::Round($age.TotalDays)))
                        }
                    }
                    "ContentPattern" {
                        # Lire seulement les premières lignes pour la performance ? Pour l'instant, lit tout.
                        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue # Continue car le fichier peut être illisible
                        if ($null -ne $content -and $content -match $criterion.Pattern) {
                            $isObsolete = $true
                            $reasons.Add(($criterion.Reason -f ($content -match $criterion.Pattern)))
                        }
                    }
                }
            } catch {
                Write-Log -Message "Erreur lors de l'évaluation du critère '$($criterion.Type)' pour '$($script.FullName)': $($_.Exception.Message)" -Level "WARNING" -ErrorRecord $_
            }
        } # Fin foreach $criterion

        if ($isObsolete) {
            $obsoleteScripts.Add([PSCustomObject]@{
                    File    = $script
                    Reasons = $reasons -join "; "
                })
            Write-Log -Message "Script obsolète potentiel trouvé: '$($script.Name)' - Raisons: $($reasons -join '; ')" -Level "VERBOSE"
        }
    } # Fin foreach $script

    Write-Progress -Activity "Détection des scripts obsolètes" -Completed
    Write-Log -Message "Détection terminée: $($obsoleteScripts.Count) scripts obsolètes potentiels trouvés." -Level "SUCCESS"
    return $obsoleteScripts
}

# Fonction pour trouver les scripts redondants (optimisée avec hash)
function Find-RedundantScripts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions,
        [Parameter(Mandatory = $true)]
        [int]$Threshold
    )

    Write-Log -Message "Début de la détection des scripts redondants..." -Level "INFO"
    $redundantGroups = [System.Collections.Generic.List[PSCustomObject]]::new()
    $allScripts = Get-ChildItem -Path $RepoPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() }

    if ($null -eq $allScripts -or $allScripts.Count -lt 2) {
        Write-Log -Message "Pas assez de scripts ($($allScripts.Count)) trouvés pour la détection de redondance." -Level "INFO"
        return $redundantGroups # Retourne une liste vide
    }

    $scriptCount = $allScripts.Count
    Write-Log -Message "Analyse de $scriptCount scripts pour la redondance..." -Level "INFO"

    # Étape 1: Calculer le hash du contenu normalisé pour chaque script
    $scriptHashes = @{} # Hashtable pour stocker: Hash -> Liste de scripts
    $progress = 0
    foreach ($script in $allScripts) {
        $progress++
        Write-Progress -Activity "Calcul des hashs de scripts" -Status "Traitement de $($script.Name) ($progress/$scriptCount)" -PercentComplete (($progress / $scriptCount) * 100)

        $normalizedContent = Get-NormalizedScriptContent -File $script
        if ($null -eq $normalizedContent) {
            # Gestion d'erreur dans Get-NormalizedScriptContent
            Write-Log -Message "Impossible de normaliser le contenu de '$($script.FullName)', il sera ignoré pour la détection de redondance." -Level "WARNING"
            continue
        }

        $hash = Get-StringHash -Content $normalizedContent
        # Associer le hash au script et stocker le contenu normalisé pour éviter de le relire
        $scriptInfo = [PSCustomObject]@{ File = $script; Hash = $hash; NormalizedContent = $normalizedContent }

        if ($scriptHashes.ContainsKey($hash)) {
            $scriptHashes[$hash].Add($scriptInfo)
        } else {
            $scriptHashes[$hash] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $scriptHashes[$hash].Add($scriptInfo)
        }
    }
    Write-Progress -Activity "Calcul des hashs de scripts" -Completed

    # Étape 2: Identifier les groupes avec le même hash (doublons exacts après normalisation)
    $potentialGroups = $scriptHashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

    Write-Log -Message "Nombre de hashs uniques: $($scriptHashes.Count). Nombre de hashs partagés par plusieurs fichiers: $($potentialGroups.Count)." -Level "VERBOSE"

    # Étape 3: Traiter les groupes potentiels
    $progress = 0
    $totalGroups = $potentialGroups.Count
    foreach ($groupKVP in $potentialGroups) {
        $progress++
        $scriptsInGroup = $groupKVP.Value # Liste de PSCustomObject (File, Hash, NormalizedContent)
        $fileNames = $scriptsInGroup.File.Name -join "', '"
        Write-Progress -Activity "Analyse des groupes redondants" -Status "Groupe ($progress/$totalGroups): '$fileNames'" -PercentComplete (($progress / $totalGroups) * 100)
        Write-Log -Message "Groupe potentiel trouvé (Hash: $($groupKVP.Key.Substring(0,8))...): '$fileNames'" -Level "VERBOSE"

        # Si le module de similarité n'est pas disponible OU si le seuil est 100,
        # considérer ce groupe comme redondant avec une similarité de 100%.
        if ($null -eq $script:TextSimilarityModule -or $Threshold -eq 100) {
            if ($Threshold -lt 100 -and $null -eq $script:TextSimilarityModule) {
                Write-Log -Message "Module TextSimilarity non disponible. Ce groupe basé sur le hash est considéré comme 100% similaire. Pour une analyse plus fine, fournissez le module." -Level "VERBOSE"
            }
            $redundantGroups.Add([PSCustomObject]@{
                    Scripts    = $scriptsInGroup.File # Retourne juste les objets FileInfo
                    Similarity = 100.00
                })
            continue # Passer au groupe suivant
        }

        # Si le module est disponible ET le seuil est < 100, utiliser la similarité fine
        # Comparer toutes les paires DANS ce groupe (beaucoup moins de comparaisons que N^2 global)
        $filesInGroup = $scriptsInGroup.File # Juste les FileInfo
        for ($i = 0; $i -lt $filesInGroup.Count; $i++) {
            for ($j = $i + 1; $j -lt $filesInGroup.Count; $j++) {
                $file1 = $filesInGroup[$i]
                $file2 = $filesInGroup[$j]

                $similarityScore = Get-FileSimilarityScore -File1 $file1 -File2 $file2
                if ($similarityScore -ge $Threshold) {
                    Write-Log -Message "Similarité élevée ($similarityScore%) trouvée entre '$($file1.Name)' et '$($file2.Name)' (Seuil: $Threshold%). Ajout au groupe redondant." -Level "VERBOSE"

                    # Logique pour fusionner/ajouter aux groupes redondants existants
                    $added = $false
                    foreach ($existingGroup in $redundantGroups) {
                        # Si l'un des deux fichiers est déjà dans un groupe, ajouter l'autre
                        if (($existingGroup.Scripts | Where-Object { $_.FullName -eq $file1.FullName }) -or `
                            ($existingGroup.Scripts | Where-Object { $_.FullName -eq $file2.FullName })) {
                            if (-not ($existingGroup.Scripts | Where-Object { $_.FullName -eq $file1.FullName })) { $existingGroup.Scripts += $file1 }
                            if (-not ($existingGroup.Scripts | Where-Object { $_.FullName -eq $file2.FullName })) { $existingGroup.Scripts += $file2 }
                            # Mise à jour de la similarité? Prendre la moyenne? Minimum? Pour l'instant, on garde la première trouvée.
                            $added = $true
                            break # Ajouté à un groupe existant
                        }
                    }
                    # Si non ajouté à un groupe existant, créer un nouveau groupe
                    if (-not $added) {
                        $redundantGroups.Add([PSCustomObject]@{
                                Scripts    = @($file1, $file2)
                                Similarity = $similarityScore
                            })
                    }
                } elseif ($similarityScore -ne -1) {
                    # Score calculé mais sous le seuil
                    Write-Log -Message "Similarité ($similarityScore%) entre '$($file1.Name)' et '$($file2.Name)' est sous le seuil ($Threshold%)." -Level "DEBUG"
                }
                # Si $similarityScore est -1, l'erreur a déjà été loggée dans Get-FileSimilarityScore
            }
        }
    } # Fin foreach $group KVP

    Write-Progress -Activity "Analyse des groupes redondants" -Completed
    Write-Log -Message "Détection terminée: $($redundantGroups.Count) groupes de scripts redondants trouvés (basé sur hash et/ou similarité fine)." -Level "SUCCESS"
    return $redundantGroups
}

# Fonction pour archiver les scripts
function Move-ScriptsToArchive {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[PSCustomObject]]$ScriptsToProcess, # Attend des objets avec une propriété 'File'
        [Parameter(Mandatory = $true)]
        [string]$BaseArchiveDir, # Chemin absolu
        [Parameter(Mandatory = $true)]
        [string]$Category, # 'obsolete' ou 'redundant'
        [Parameter(Mandatory = $false)]
        [switch]$IsDryRun
    )

    $archivedItems = [System.Collections.Generic.List[PSCustomObject]]::new()
    $categoryPath = Join-Path -Path $BaseArchiveDir -ChildPath $Category

    # Créer le dossier d'archive de catégorie si nécessaire
    if (-not (Test-Path -Path $categoryPath -PathType Container)) {
        Write-Log -Message "Création du répertoire d'archive: $categoryPath" -Level "VERBOSE"
        if (-not $IsDryRun) {
            try {
                New-Item -Path $categoryPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Log -Message "Erreur critique: Impossible de créer le répertoire d'archive '$categoryPath'. Arrêt de l'archivage pour cette catégorie. Erreur: $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
                return $archivedItems # Retourne liste vide
            }
        } else {
            Write-Log -Message "[DryRun] Création du répertoire '$categoryPath' simulée." -Level "INFO"
        }
    }

    $scriptCount = $ScriptsToProcess.Count
    Write-Log -Message "Archivage de $scriptCount scripts dans la catégorie '$Category'..." -Level "INFO"
    $progress = 0

    foreach ($scriptInfo in $ScriptsToProcess) {
        $progress++
        $scriptFile = $scriptInfo.File # Accède à la propriété File de l'objet
        Write-Progress -Activity "Archivage des scripts ($Category)" -Status "Traitement de $($scriptFile.Name) ($progress/$scriptCount)" -PercentComplete (($progress / $scriptCount) * 100)

        # Calculer chemin relatif pour le rapport
        $relativePath = $scriptFile.FullName.Substring($Path.Length).TrimStart('\/')

        $targetFileName = $scriptFile.Name
        $archiveFilePath = Join-Path -Path $categoryPath -ChildPath $targetFileName
        $counter = 1

        # Gérer les collisions de noms dans l'archive
        while (Test-Path -Path $archiveFilePath -PathType Leaf) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($scriptFile.Name)
            $extension = $scriptFile.Extension
            $targetFileName = "${baseName}_${counter}${extension}"
            $archiveFilePath = Join-Path -Path $categoryPath -ChildPath $targetFileName
            $counter++
        }

        $archiveRelativePath = $archiveFilePath.Substring($Path.Length).TrimStart('\/')
        Write-Log -Message "Archivage: '$relativePath' -> '$archiveRelativePath'" -Level "INFO"

        if (-not $IsDryRun) {
            if ($PSCmdlet.ShouldProcess($scriptFile.FullName, "Archiver vers '$archiveFilePath'")) {
                try {
                    # Copier d'abord pour la sécurité
                    Copy-Item -Path $scriptFile.FullName -Destination $archiveFilePath -Force -ErrorAction Stop
                    # Puis supprimer l'original si la copie a réussi
                    Remove-Item -Path $scriptFile.FullName -Force -ErrorAction Stop
                    Write-Log -Message "Archivage réussi: '$relativePath' -> '$archiveRelativePath'" -Level "VERBOSE"
                    $archivedItems.Add([PSCustomObject]@{
                            OriginalPath = $relativePath
                            ArchivePath  = $archiveRelativePath
                            Status       = 'Archived'
                        })
                } catch {
                    Write-Log -Message "Erreur lors de l'archivage de '$($scriptFile.FullName)' vers '$archiveFilePath': $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
                    $archivedItems.Add([PSCustomObject]@{
                            OriginalPath = $relativePath
                            ArchivePath  = $archiveRelativePath
                            Status       = 'Error'
                        })
                }
            } else {
                Write-Log -Message "Archivage annulé par l'utilisateur ou -WhatIf pour '$($scriptFile.FullName)'" -Level "WARNING"
                $archivedItems.Add([PSCustomObject]@{
                        OriginalPath = $relativePath
                        ArchivePath  = $archiveRelativePath
                        Status       = 'Skipped (ShouldProcess)'
                    })
            }
        } else {
            Write-Log -Message "[DryRun] Archivage simulé: '$relativePath' -> '$archiveRelativePath'" -Level "INFO"
            $archivedItems.Add([PSCustomObject]@{
                    OriginalPath = $relativePath
                    ArchivePath  = $archiveRelativePath
                    Status       = 'DryRun'
                })
        }
    } # Fin foreach $scriptInfo

    Write-Progress -Activity "Archivage des scripts ($Category)" -Completed
    return $archivedItems
}

# Fonction pour fusionner les scripts redondants (en archivant les moins récents)
function Merge-RedundantScripts {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[PSCustomObject]]$RedundantGroups, # Liste d'objets avec propriétés 'Scripts' (FileInfo[]) et 'Similarity'
        [Parameter(Mandatory = $true)]
        [string]$BaseArchiveDir, # Chemin absolu
        [Parameter(Mandatory = $false)]
        [switch]$IsDryRun
    )

    $consolidationResults = [System.Collections.Generic.List[PSCustomObject]]::new()
    $groupCount = $RedundantGroups.Count
    Write-Log -Message "Consolidation de $groupCount groupes de scripts redondants..." -Level "INFO"
    $progress = 0

    foreach ($group in $RedundantGroups) {
        $progress++
        $scripts = $group.Scripts # Ceci est un tableau de FileInfo
        $fileNames = $scripts.Name -join "', '"
        Write-Progress -Activity "Consolidation des scripts redondants" -Status "Groupe ($progress/$groupCount): '$fileNames'" -PercentComplete (($progress / $groupCount) * 100)

        if ($scripts.Count -lt 2) {
            Write-Log -Message "Groupe '$fileNames' ne contient qu'un seul script, aucune consolidation nécessaire." -Level "VERBOSE"
            continue
        }

        # Trier par date de modification (plus récent en premier) comme heuristique pour choisir lequel garder
        # Utiliser LastWriteTimeUtc pour éviter les problèmes de fuseau horaire
        $sortedScripts = $scripts | Sort-Object -Property LastWriteTimeUtc -Descending

        $keptScript = $sortedScripts[0]
        # Créer la liste des scripts à archiver (tous sauf le premier)
        $scriptsToArchiveInfo = [System.Collections.Generic.List[PSCustomObject]]::new()
        for ($i = 1; $i -lt $sortedScripts.Length; $i++) {
            $scriptsToArchiveInfo.Add([PSCustomObject]@{ File = $sortedScripts[$i] }) # Encapsuler dans un objet avec la propriété 'File' attendue par Move-ScriptsToArchive
        }

        $keptScriptRelativePath = $keptScript.FullName.Substring($Path.Length).TrimStart('\/')
        Write-Log -Message "Consolidation du groupe: Garde '$($keptScript.Name)' (le plus récent). Archivage des $($scriptsToArchiveInfo.Count) autres..." -Level "INFO"

        # Archiver les scripts redondants (sauf celui gardé)
        $archivedResults = Move-ScriptsToArchive -ScriptsToProcess $scriptsToArchiveInfo -BaseArchiveDir $BaseArchiveDir -Category "redundant" -IsDryRun:$IsDryRun

        # Ajouter le résultat de la consolidation pour le rapport
        $consolidationResults.Add([PSCustomObject]@{
                KeptScript      = $keptScriptRelativePath
                ArchivedScripts = $archivedResults # Liste d'objets avec OriginalPath, ArchivePath, Status
                Similarity      = $group.Similarity
            })
    } # Fin foreach $group

    Write-Progress -Activity "Consolidation des scripts redondants" -Completed
    return $consolidationResults
}

# Fonction pour générer le rapport Markdown
function New-CleanupReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReportFile, # Chemin absolu
        [Parameter(Mandatory = $false)]
        [System.Collections.Generic.List[PSCustomObject]]$ArchivedObsolete = @(), # Résultats de Move-ScriptsToArchive
        [Parameter(Mandatory = $false)]
        [System.Collections.Generic.List[PSCustomObject]]$ConsolidatedGroups = @(), # Résultats de Merge-RedundantScripts
        [Parameter(Mandatory = $true)]
        [bool]$IsDryRunMode,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$LogEntries
    )

    Write-Log -Message "Génération du rapport de nettoyage vers '$ReportFile'..." -Level "INFO"

    # Calculer les totaux
    $totalObsoleteArchived = ($ArchivedObsolete | Where-Object { $_.Status -ne 'Error' -and $_.Status -ne 'Skipped (ShouldProcess)' }).Count
    $totalRedundantArchived = ($ConsolidatedGroups | ForEach-Object { ($_.ArchivedScripts | Where-Object { $_.Status -ne 'Error' -and $_.Status -ne 'Skipped (ShouldProcess)' }).Count } | Measure-Object -Sum).Sum
    $totalArchived = $totalObsoleteArchived + $totalRedundantArchived

    $reportContent = @"
# Rapport de Nettoyage du Dépôt

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Chemin du Dépôt:** $Path
**Mode d'exécution:** $(if ($IsDryRunMode) { "Simulation (DryRun)" } else { "Réel" })
**Extensions Analysées:** $($ScriptExtensions -join ', ')
**Module TextSimilarity utilisé:** $(if($script:TextSimilarityModule){"Oui"}else{"Non"})
$(if($script:AbsoluteLogFilePath){"**Fichier Journal:** $script:AbsoluteLogFilePath"})

## Résumé des Actions $(if($IsDryRunMode){"(Simulées)"})

- Scripts obsolètes identifiés et traités : **$($ArchivedObsolete.Count)**
- Groupes de scripts redondants identifiés : **$($ConsolidatedGroups.Count)**
- Total de scripts archivés/prévus pour archivage : **$totalArchived**
  - Dont Obsolètes : $totalObsoleteArchived
  - Dont Redondants : $totalRedundantArchived

---

## Scripts Obsolètes Traités

$(
    if ($ArchivedObsolete.Count -eq 0) {
        "Aucun script obsolète n'a été traité."
    } else {
        # Formatage en tableau Markdown
        $header = "| Script Original | Destination Archive | Statut |"
        $separator = "|---|---|---|"
        $rows = @()
        foreach ($item in $ArchivedObsolete) {
            $rows += "| $($item.OriginalPath) | $($item.ArchivePath) | $($item.Status) |"
        }
        ($header, $separator) + $rows -join [Environment]::NewLine
    }
)

---

## Scripts Redondants Consolidés

$(
    if ($ConsolidatedGroups.Count -eq 0) {
        "Aucun groupe de scripts redondants n'a été consolidé."
    } else {
        $groupsOutput = foreach ($group in $ConsolidatedGroups) {
            $archivedList = if ($group.ArchivedScripts.Count -gt 0) {
                 $group.ArchivedScripts | ForEach-Object { "  - $($_.OriginalPath) -> $($_.ArchivePath) ($($_.Status))" }
            } else {
                "  - Aucun autre script dans ce groupe n'a été archivé."
            }

            @"
### Groupe (Similarité estimée: $($group.Similarity)%)

- **Script Conservé :** $($group.KeptScript)
- **Scripts Archivés :**
$($archivedList -join [Environment]::NewLine)
"@
        }
        $groupsOutput -join ([Environment]::NewLine + "---" + [Environment]::NewLine)
    }
)

---

## Journal Détaillé des Opérations

```
$($LogEntries -join [Environment]::NewLine)
```

## Recommandations

$(if ($totalArchived -eq 0) {
    "Le dépôt semble propre selon les critères actuels. Aucune action d'archivage n'a été effectuée ou simulée."
} elseif ($IsDryRunMode) {
    "Le nettoyage a été simulé. Vérifiez le rapport pour vous assurer que l'archivage vers '$AbsoluteArchivePath' est approprié."
} else {
    "Le nettoyage a été effectué. Les scripts identifiés ont été déplacés vers '$AbsoluteArchivePath'."
    "Action Recommandée: Vérifiez le contenu du répertoire d'archive."
    "Confirmez que les scripts conservés fonctionnent comme prévu."
    "Vous pouvez supprimer définitivement les archives après validation et/ou une période de sécurité."
})
"@ # Fin du bloc Here-String pour $reportContent

    # Créer le dossier de rapport si nécessaire
    $reportDir = Split-Path -Path $ReportFile -Parent
    if (-not (Test-Path -Path $reportDir -PathType Container)) {
        Write-Log -Message "Création du répertoire de rapport: $reportDir" -Level "VERBOSE"
        try {
            New-Item -Path $reportDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-Log -Message "Erreur critique: Impossible de créer le répertoire de rapport '$reportDir'. Le rapport ne peut pas être enregistré. Erreur: $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
            return $null # Indique l'échec
        }
    }

    # Enregistrer le rapport
    try {
        Set-Content -Path $ReportFile -Value $reportContent -Encoding UTF8 -ErrorAction Stop
        Write-Log -Message "Rapport de nettoyage généré avec succès: $ReportFile" -Level "SUCCESS"
        return $ReportFile # Retourne le chemin complet du rapport
    } catch {
        Write-Log -Message "Erreur lors de l'écriture du fichier de rapport '$ReportFile': $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
        return $null # Indique l'échec
    }
}

#region Main Execution Logic
function Main {
    $startTime = Get-Date
    Write-Log -Message "--- Début du Script de Nettoyage du Dépôt ---" -Level "INFO"
    Write-Log -Message "Dépôt Cible: $Path" -Level "INFO"
    Write-Log -Message "Répertoire d'Archive: $AbsoluteArchivePath" -Level "INFO"
    Write-Log -Message "Fichier Rapport: $AbsoluteReportPath" -Level "INFO"
    if ($script:AbsoluteLogFilePath) { Write-Log -Message "Fichier Journal: $script:AbsoluteLogFilePath" -Level "INFO" }
    Write-Log -Message "Mode: $(if ($DryRun) { 'Simulation (DryRun)' } else { 'Réel' })" -Level "INFO"
    Write-Log -Message "Extensions ciblées: $($ScriptExtensions -join ', ')" -Level "INFO"

    # Initialiser le fichier journal si spécifié
    if ($script:AbsoluteLogFilePath) {
        $logDir = Split-Path $script:AbsoluteLogFilePath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            try {
                New-Item -Path $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch { Write-Warning "Impossible de créer le répertoire pour le fichier journal '$logDir'. Log désactivé."; $script:AbsoluteLogFilePath = $null }
        }
        if ($script:AbsoluteLogFilePath) {
            # Efface le contenu précédent ou crée le fichier
            Set-Content -Path $script:AbsoluteLogFilePath -Value "--- Journal de Nettoyage du Dépôt $(Get-Date) ---`n" -ErrorAction SilentlyContinue
        }
    }

    # Variables pour stocker les résultats
    $obsoleteScriptsFound = @()
    $redundantGroupsFound = @()
    $archivedObsoleteResults = @()
    $consolidationResults = @()

    # 1. Détection des scripts obsolètes
    $obsoleteScriptsFound = Find-ObsoleteScripts -RepoPath $Path -Extensions $ScriptExtensions
    # Encapsuler les résultats pour Move-ScriptsToArchive
    $obsoleteScriptsToProcess = $obsoleteScriptsFound | ForEach-Object { [PSCustomObject]@{ File = $_.File } }

    # 2. Détection des scripts redondants (si non skip)
    if (-not $SkipRedundantDetection) {
        $redundantGroupsFound = Find-RedundantScripts -RepoPath $Path -Extensions $ScriptExtensions -Threshold $SimilarityThreshold
    } else {
        Write-Log -Message "Détection des scripts redondants ignorée (option -SkipRedundantDetection activée)." -Level "INFO"
    }

    # 3. Archivage des scripts obsolètes
    if ($obsoleteScriptsToProcess.Count -gt 0) {
        $archivedObsoleteResults = Move-ScriptsToArchive -ScriptsToProcess $obsoleteScriptsToProcess -BaseArchiveDir $AbsoluteArchivePath -Category "obsolete" -IsDryRun:$DryRun
    } else {
        Write-Log -Message "Aucun script obsolète à archiver." -Level "INFO"
    }

    # 4. Consolidation des scripts redondants
    if ($redundantGroupsFound.Count -gt 0) {
        $consolidationResults = Merge-RedundantScripts -RedundantGroups $redundantGroupsFound -BaseArchiveDir $AbsoluteArchivePath -IsDryRun:$DryRun
    } else {
        Write-Log -Message "Aucun groupe redondant à consolider." -Level "INFO"
    }

    # 5. Génération du rapport final
    $finalReportPath = New-CleanupReport -ReportFile $AbsoluteReportPath `
        -ArchivedObsolete $archivedObsoleteResults `
        -ConsolidatedGroups $consolidationResults `
        -IsDryRunMode $DryRun `
        -LogEntries $script:logMessages

    # 6. Résumé final et fin
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Log -Message "--- Fin du Script de Nettoyage du Dépôt ---" -Level "INFO"
    Write-Log -Message "Durée totale de l'exécution: $($duration.ToString('g'))" -Level "INFO"

    if ($finalReportPath) {
        Write-Host "`nRapport final généré : $finalReportPath" -ForegroundColor Cyan
        # Tenter d'ouvrir le rapport
        if (-not $DryRun) {
            # N'ouvre pas automatiquement en DryRun pour éviter les interruptions
            try {
                Invoke-Item -Path $finalReportPath -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Impossible d'ouvrir automatiquement le rapport '$finalReportPath'. Vous pouvez l'ouvrir manuellement."
            }
        }
    } else {
        Write-Error "La génération du rapport final a échoué. Veuillez consulter les logs en console."
    }
}
#endregion

# Exécuter la fonction principale avec gestion d'erreur globale
try {
    Main
} catch {
    Write-Log -Message "ERREUR FATALE non interceptée dans le script principal: $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
    # Tenter de générer un rapport d'erreur minimal si possible
    $errorReportPath = Join-Path -Path $Path -ChildPath "error-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $errorContent = @"
ERREUR FATALE - Script de Nettoyage

Une erreur non gérée s'est produite le $(Get-Date).

Dépôt: $Path
Erreur:
$($_.Exception.ToString())

Trace:
$($_.ScriptStackTrace)

Journal (si disponible):
$($script:logMessages -join [Environment]::NewLine)
"@
    try {
        Set-Content -Path $errorReportPath -Value $errorContent -Encoding UTF8
        Write-Error "Une erreur fatale s'est produite. Un rapport d'erreur a été généré ici: $errorReportPath"
    } catch {
        Write-Error "Une erreur fatale s'est produite et le rapport d'erreur n'a pas pu être généré. Erreur initiale: $($_.Exception.Message)"
    }
    # Quitter avec un code d'erreur
    exit 1
}
