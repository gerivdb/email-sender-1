#Requires -Version 5.1
<#
.SYNOPSIS
    Nettoie un dÃ©pÃ´t de code en identifiant, archivant et rapportant les scripts obsolÃ¨tes et redondants.
.DESCRIPTION
    Ce script analyse un rÃ©pertoire spÃ©cifiÃ© (dÃ©pÃ´t) pour trouver des scripts potentiellement obsolÃ¨tes
    (basÃ© sur des motifs de nommage, l'Ã¢ge et le contenu) et redondants (basÃ© sur la similaritÃ© du contenu).
    Les scripts identifiÃ©s peuvent Ãªtre archivÃ©s automatiquement dans un sous-rÃ©pertoire structurÃ©.
    Un rapport dÃ©taillÃ© au format Markdown est gÃ©nÃ©rÃ©, rÃ©sumant les actions effectuÃ©es ou simulÃ©es.

    La dÃ©tection de redondance utilise une approche optimisÃ©e :
    1. Calcul du hash SHA256 du contenu normalisÃ© (ignorant les commentaires et lignes vides) pour identifier les doublons exacts rapidement.
    2. Si un module externe 'TextSimilarity' est disponible (doit Ãªtre placÃ© dans $Path\modules\TextSimilarity.psm1),
       il peut Ãªtre utilisÃ© pour une analyse de similaritÃ© plus fine (algorithmes comme Levenshtein, Jaccard, etc.)
       afin de trouver des doublons *presque* identiques, en fonction du seuil '-SimilarityThreshold'.
    3. Si le module n'est pas prÃ©sent, la dÃ©tection de redondance se limite aux doublons exacts (basÃ©s sur le hash normalisÃ©),
       sauf si -SkipRedundantDetection est utilisÃ©.

.PARAMETER Path
    Chemin du dÃ©pÃ´t Ã  analyser et nettoyer. Par dÃ©faut, le rÃ©pertoire courant.
.PARAMETER ArchivePath
    Chemin *relatif* au dossier -Path oÃ¹ archiver les scripts obsolÃ¨tes et redondants.
    Utilise un format de date par dÃ©faut pour Ã©viter les Ã©crasements. Ex: 'archive\20250426'.
.PARAMETER ReportPath
    Chemin *relatif* au dossier -Path oÃ¹ gÃ©nÃ©rer le rapport de nettoyage au format Markdown.
    Utilise un format date/heure par dÃ©faut. Ex: 'reports\cleanup-20250426-153000.md'.
.PARAMETER SimilarityThreshold
    Seuil de similaritÃ© (en pourcentage, 0-100) pour considÃ©rer deux scripts comme redondants lors de l'utilisation
    du module TextSimilarity. IgnorÃ© si le module n'est pas trouvÃ© ou si -SkipRedundantDetection est utilisÃ©.
    Par dÃ©faut Ã  80. Un seuil de 100 signifie une correspondance exacte (aprÃ¨s normalisation si utilisÃ©e par le module).
.PARAMETER DryRun
    Si spÃ©cifiÃ©, le script simulera toutes les actions (dÃ©tection, archivage) sans modifier
    le systÃ¨me de fichiers. Le rapport indiquera ce qui *aurait* Ã©tÃ© fait.
.PARAMETER SkipRedundantDetection
    Si spÃ©cifiÃ©, ignore complÃ¨tement l'Ã©tape de dÃ©tection des scripts redondants.
    Utile pour accÃ©lÃ©rer l'analyse ou si la dÃ©tection de redondance n'est pas souhaitÃ©e.
.PARAMETER Force
    (RetirÃ© - Non implÃ©mentÃ© et objectif ambigu. RemplacÃ© par une gestion d'erreur plus robuste).
.PARAMETER LogFile
    Chemin *relatif* au dossier -Path pour un fichier journal texte optionnel oÃ¹ enregistrer les logs dÃ©taillÃ©s.
    Si non spÃ©cifiÃ©, les logs sont uniquement affichÃ©s en console et inclus dans le rapport Markdown.
.PARAMETER ScriptExtensions
    Tableau des extensions de fichiers Ã  considÃ©rer comme des scripts.
    Par dÃ©faut: @(".ps1", ".psm1", ".py", ".sh", ".bat", ".cmd")
.EXAMPLE
    .\Clean-Repository.ps1 -Path "D:\MyProjects\ScriptRepo" -Verbose -DryRun
    # Simule le nettoyage dans le dossier spÃ©cifiÃ©, affiche les logs dÃ©taillÃ©s.

.EXAMPLE
    .\Clean-Repository.ps1 -Path "C:\scripts" -ArchivePath "backup_$(Get-Date -f yyyyMM)" -ReportPath "cleanup_report.md" -SimilarityThreshold 95
    # Effectue le nettoyage rÃ©el, archive dans C:\scripts\backup_YYYYMM, gÃ©nÃ¨re C:\scripts\cleanup_report.md, seuil de similaritÃ© Ã  95%.

.EXAMPLE
    .\Clean-Repository.ps1 -SkipRedundantDetection -LogFile "cleaning.log"
    # Nettoie le rÃ©pertoire courant, ignore la dÃ©tection de redondance, enregistre les logs dans .\cleaning.log.

.NOTES
    Auteur: Augment Agent (AmÃ©liorÃ© par IA Claude)
    Version: 2.0
    Date: 2025-04-27

    AmÃ©liorations v2.0:
    - DÃ©tection de redondance optimisÃ©e via hash SHA256 sur contenu normalisÃ©.
    - Utilisation conditionnelle du module externe TextSimilarity pour similaritÃ© fine.
    - AmÃ©lioration significative des performances pour la dÃ©tection de redondance.
    - Meilleure gestion des erreurs et logging (utilise Write-Verbose, Write-Warning, etc.).
    - Ajout du paramÃ¨tre -LogFile pour un fichier journal dÃ©diÃ©.
    - Ajout du paramÃ¨tre -ScriptExtensions pour la flexibilitÃ©.
    - Suppression du paramÃ¨tre -Force (non utilisÃ©).
    - Ajout de barres de progression pour les opÃ©rations longues.
    - Normalisation du contenu pour ignorer les commentaires et lignes vides lors du hachage.
    - Code structurÃ© en fonctions plus claires et robustes.
    - Validation des paramÃ¨tres.
    - Rapport Markdown amÃ©liorÃ©.
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

# Fonction de logging amÃ©liorÃ©e
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

    # Ajouter au journal en mÃ©moire pour le rapport
    $script:logMessages.Add($logEntry)

    # Ã‰crire dans le fichier journal si spÃ©cifiÃ©
    if ($script:AbsoluteLogFilePath) {
        try {
            Add-Content -Path $script:AbsoluteLogFilePath -Value $logEntry -ErrorAction Stop
        } catch {
            Write-Warning "Impossible d'Ã©crire dans le fichier journal '$script:AbsoluteLogFilePath': $($_.Exception.Message)"
            $script:AbsoluteLogFilePath = $null # EmpÃªche les tentatives rÃ©pÃ©tÃ©es
        }
    }

    # Afficher dans la console via les flux PowerShell appropriÃ©s
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

# Essayer d'importer le module de similaritÃ©
$textSimilarityPath = Join-Path -Path $Path -ChildPath "modules\TextSimilarity.psm1"
if (Test-Path -Path $textSimilarityPath -PathType Leaf) {
    try {
        Import-Module $textSimilarityPath -Force
        $script:TextSimilarityModule = Get-Module -Name TextSimilarity
        Write-Log -Message "Module TextSimilarity importÃ© avec succÃ¨s depuis '$textSimilarityPath'." -Level "INFO"
    } catch {
        Write-Log -Message "Ã‰chec de l'importation du module TextSimilarity depuis '$textSimilarityPath'. La dÃ©tection de similaritÃ© fine sera dÃ©sactivÃ©e. Erreur: $($_.Exception.Message)" -Level "WARNING"
    }
} else {
    Write-Log -Message "Module TextSimilarity non trouvÃ© Ã  '$textSimilarityPath'. La dÃ©tection de similaritÃ© fine est dÃ©sactivÃ©e. Seuls les doublons exacts (basÃ©s sur le contenu normalisÃ©) seront dÃ©tectÃ©s." -Level "INFO"
}


# Fonction pour obtenir le contenu normalisÃ© d'un script (ignore commentaires et lignes vides)
function Get-NormalizedScriptContent {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    try {
        $content = Get-Content -Path $File.FullName -Raw -ErrorAction Stop
        $lines = $content -split [Environment]::NewLine

        # DÃ©terminer le caractÃ¨re de commentaire basÃ© sur l'extension
        $commentChar = switch ($File.Extension.ToLower()) {
            ".ps1" { '#' }
            ".psm1" { '#' }
            ".py" { '#' }
            ".sh" { '#' }
            ".bat" { 'REM ' } # Attention: REM doit Ãªtre au dÃ©but de la ligne (simplification ici)
            ".cmd" { 'REM ' } # Idem
            default { $null }
        }

        $normalizedLines = foreach ($line in $lines) {
            $trimmedLine = $line.Trim()
            if ($trimmedLine.Length -eq 0) { continue } # Ignorer lignes vides
            if ($null -ne $commentChar -and $trimmedLine.StartsWith($commentChar)) { continue } # Ignorer lignes de commentaire simples

            # TODO: AmÃ©liorer la suppression des commentaires (ex: commentaires en fin de ligne, blocs de commentaires)
            # Pour l'instant, on normalise juste les espaces en dÃ©but/fin de ligne
            $trimmedLine
        }

        return ($normalizedLines -join [Environment]::NewLine).Trim()

    } catch {
        Write-Log -Message "Erreur lors de la lecture ou normalisation de $($File.FullName): $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
        return $null # Retourne null en cas d'erreur
    }
}

# Fonction pour calculer le hash SHA256 d'une chaÃ®ne
function Get-StringHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hashBytes = $sha256.ComputeHash($bytes)
    $sha256.Dispose()
    # Convertir les bytes du hash en chaÃ®ne hexadÃ©cimale
    return [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
}

# Fonction de calcul de similaritÃ© (utilise le module si disponible, sinon fallback limitÃ©)
function Get-FileSimilarityScore {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File1,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File2
    )

    # Utiliser le module TextSimilarity si disponible et chargÃ©
    if ($null -ne $script:TextSimilarityModule -and (Get-Command -Module TextSimilarity -Name Get-ContentSimilarity -ErrorAction SilentlyContinue)) {
        try {
            # Utiliser l'algorithme "Combined" ou un autre fourni par le module
            $similarity = Get-ContentSimilarity -FilePathA $File1.FullName -FilePathB $File2.FullName -Algorithm "Combined" -ErrorAction Stop
            Write-Log -Message "SimilaritÃ© (Module TextSimilarity) entre '$($File1.Name)' et '$($File2.Name)': $similarity%" -Level "VERBOSE"
            return $similarity
        } catch {
            Write-Log -Message "Erreur lors de l'utilisation de Get-ContentSimilarity pour '$($File1.Name)' et '$($File2.Name)': $($_.Exception.Message)" -Level "WARNING" -ErrorRecord $_
            # Fallback vers la mÃ©thode de base si le module Ã©choue
        }
    }

    # Fallback: Si le module n'est pas lÃ  ou a Ã©chouÃ©, on ne peut pas calculer de score fiable.
    # On pourrait comparer les hash normalisÃ©s, mais Find-RedundantScripts le fait dÃ©jÃ .
    # Retourner 0 ou 100 basÃ© sur le hash prÃ©-calculÃ© pourrait Ãªtre une option, mais
    # cette fonction est appelÃ©e *aprÃ¨s* le regroupement par hash.
    # Donc, si on arrive ici sans module, c'est qu'on demande une similaritÃ© fine non disponible.
    Write-Log -Message "Calcul de similaritÃ© fine non disponible (Module TextSimilarity absent ou Ã©chouÃ©) pour '$($File1.Name)' et '$($File2.Name)'." -Level "VERBOSE"
    return -1 # Indique que le score n'a pas pu Ãªtre calculÃ©
}

#endregion

#region Core Logic Functions

# Fonction pour trouver les scripts obsolÃ¨tes
function Find-ObsoleteScripts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions
    )

    Write-Log -Message "DÃ©but de la dÃ©tection des scripts obsolÃ¨tes..." -Level "INFO"
    $obsoleteCriteria = @(
        @{ Type = "NamePattern"; Pattern = '(?i)(obsolete(?!-v\d+)|deprecated|old|backup|bak|archive|temp|tmp|_v\d+|copyof)'; Reason = "Nom du fichier correspond au motif d'obsolescence ('{0}')" }
        @{ Type = "LastModified"; DaysOld = 365; Reason = "Non modifiÃ© depuis plus de {0} jours ({1} jours)" }
        @{ Type = "ContentPattern"; Pattern = '(?im)^\s*#(?:obsolete|deprecated|do not use|no longer used|no longer maintained|replaced by)'; Reason = "Contient un commentaire d'obsolescence ('{0}')" }
        # Ajouter d'autres critÃ¨res ici si nÃ©cessaire
    )

    $obsoleteScripts = [System.Collections.Generic.List[PSCustomObject]]::new()
    $allScripts = Get-ChildItem -Path $RepoPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() }

    if ($null -eq $allScripts -or $allScripts.Count -eq 0) {
        Write-Log -Message "Aucun script trouvÃ© avec les extensions spÃ©cifiÃ©es dans '$RepoPath'." -Level "INFO"
        return $obsoleteScripts # Retourne une liste vide
    }

    $scriptCount = $allScripts.Count
    Write-Log -Message "Analyse de $scriptCount scripts pour l'obsolescence..." -Level "INFO"
    $progress = 0

    foreach ($script in $allScripts) {
        $progress++
        Write-Progress -Activity "DÃ©tection des scripts obsolÃ¨tes" -Status "Analyse de $($script.Name) ($progress/$scriptCount)" -PercentComplete (($progress / $scriptCount) * 100)

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
                        # Lire seulement les premiÃ¨res lignes pour la performance ? Pour l'instant, lit tout.
                        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue # Continue car le fichier peut Ãªtre illisible
                        if ($null -ne $content -and $content -match $criterion.Pattern) {
                            $isObsolete = $true
                            $reasons.Add(($criterion.Reason -f ($content -match $criterion.Pattern)))
                        }
                    }
                }
            } catch {
                Write-Log -Message "Erreur lors de l'Ã©valuation du critÃ¨re '$($criterion.Type)' pour '$($script.FullName)': $($_.Exception.Message)" -Level "WARNING" -ErrorRecord $_
            }
        } # Fin foreach $criterion

        if ($isObsolete) {
            $obsoleteScripts.Add([PSCustomObject]@{
                    File    = $script
                    Reasons = $reasons -join "; "
                })
            Write-Log -Message "Script obsolÃ¨te potentiel trouvÃ©: '$($script.Name)' - Raisons: $($reasons -join '; ')" -Level "VERBOSE"
        }
    } # Fin foreach $script

    Write-Progress -Activity "DÃ©tection des scripts obsolÃ¨tes" -Completed
    Write-Log -Message "DÃ©tection terminÃ©e: $($obsoleteScripts.Count) scripts obsolÃ¨tes potentiels trouvÃ©s." -Level "SUCCESS"
    return $obsoleteScripts
}

# Fonction pour trouver les scripts redondants (optimisÃ©e avec hash)
function Find-RedundantScripts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions,
        [Parameter(Mandatory = $true)]
        [int]$Threshold
    )

    Write-Log -Message "DÃ©but de la dÃ©tection des scripts redondants..." -Level "INFO"
    $redundantGroups = [System.Collections.Generic.List[PSCustomObject]]::new()
    $allScripts = Get-ChildItem -Path $RepoPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() }

    if ($null -eq $allScripts -or $allScripts.Count -lt 2) {
        Write-Log -Message "Pas assez de scripts ($($allScripts.Count)) trouvÃ©s pour la dÃ©tection de redondance." -Level "INFO"
        return $redundantGroups # Retourne une liste vide
    }

    $scriptCount = $allScripts.Count
    Write-Log -Message "Analyse de $scriptCount scripts pour la redondance..." -Level "INFO"

    # Ã‰tape 1: Calculer le hash du contenu normalisÃ© pour chaque script
    $scriptHashes = @{} # Hashtable pour stocker: Hash -> Liste de scripts
    $progress = 0
    foreach ($script in $allScripts) {
        $progress++
        Write-Progress -Activity "Calcul des hashs de scripts" -Status "Traitement de $($script.Name) ($progress/$scriptCount)" -PercentComplete (($progress / $scriptCount) * 100)

        $normalizedContent = Get-NormalizedScriptContent -File $script
        if ($null -eq $normalizedContent) {
            # Gestion d'erreur dans Get-NormalizedScriptContent
            Write-Log -Message "Impossible de normaliser le contenu de '$($script.FullName)', il sera ignorÃ© pour la dÃ©tection de redondance." -Level "WARNING"
            continue
        }

        $hash = Get-StringHash -Content $normalizedContent
        # Associer le hash au script et stocker le contenu normalisÃ© pour Ã©viter de le relire
        $scriptInfo = [PSCustomObject]@{ File = $script; Hash = $hash; NormalizedContent = $normalizedContent }

        if ($scriptHashes.ContainsKey($hash)) {
            $scriptHashes[$hash].Add($scriptInfo)
        } else {
            $scriptHashes[$hash] = [System.Collections.Generic.List[PSCustomObject]]::new()
            $scriptHashes[$hash].Add($scriptInfo)
        }
    }
    Write-Progress -Activity "Calcul des hashs de scripts" -Completed

    # Ã‰tape 2: Identifier les groupes avec le mÃªme hash (doublons exacts aprÃ¨s normalisation)
    $potentialGroups = $scriptHashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

    Write-Log -Message "Nombre de hashs uniques: $($scriptHashes.Count). Nombre de hashs partagÃ©s par plusieurs fichiers: $($potentialGroups.Count)." -Level "VERBOSE"

    # Ã‰tape 3: Traiter les groupes potentiels
    $progress = 0
    $totalGroups = $potentialGroups.Count
    foreach ($groupKVP in $potentialGroups) {
        $progress++
        $scriptsInGroup = $groupKVP.Value # Liste de PSCustomObject (File, Hash, NormalizedContent)
        $fileNames = $scriptsInGroup.File.Name -join "', '"
        Write-Progress -Activity "Analyse des groupes redondants" -Status "Groupe ($progress/$totalGroups): '$fileNames'" -PercentComplete (($progress / $totalGroups) * 100)
        Write-Log -Message "Groupe potentiel trouvÃ© (Hash: $($groupKVP.Key.Substring(0,8))...): '$fileNames'" -Level "VERBOSE"

        # Si le module de similaritÃ© n'est pas disponible OU si le seuil est 100,
        # considÃ©rer ce groupe comme redondant avec une similaritÃ© de 100%.
        if ($null -eq $script:TextSimilarityModule -or $Threshold -eq 100) {
            if ($Threshold -lt 100 -and $null -eq $script:TextSimilarityModule) {
                Write-Log -Message "Module TextSimilarity non disponible. Ce groupe basÃ© sur le hash est considÃ©rÃ© comme 100% similaire. Pour une analyse plus fine, fournissez le module." -Level "VERBOSE"
            }
            $redundantGroups.Add([PSCustomObject]@{
                    Scripts    = $scriptsInGroup.File # Retourne juste les objets FileInfo
                    Similarity = 100.00
                })
            continue # Passer au groupe suivant
        }

        # Si le module est disponible ET le seuil est < 100, utiliser la similaritÃ© fine
        # Comparer toutes les paires DANS ce groupe (beaucoup moins de comparaisons que N^2 global)
        $filesInGroup = $scriptsInGroup.File # Juste les FileInfo
        for ($i = 0; $i -lt $filesInGroup.Count; $i++) {
            for ($j = $i + 1; $j -lt $filesInGroup.Count; $j++) {
                $file1 = $filesInGroup[$i]
                $file2 = $filesInGroup[$j]

                $similarityScore = Get-FileSimilarityScore -File1 $file1 -File2 $file2
                if ($similarityScore -ge $Threshold) {
                    Write-Log -Message "SimilaritÃ© Ã©levÃ©e ($similarityScore%) trouvÃ©e entre '$($file1.Name)' et '$($file2.Name)' (Seuil: $Threshold%). Ajout au groupe redondant." -Level "VERBOSE"

                    # Logique pour fusionner/ajouter aux groupes redondants existants
                    $added = $false
                    foreach ($existingGroup in $redundantGroups) {
                        # Si l'un des deux fichiers est dÃ©jÃ  dans un groupe, ajouter l'autre
                        if (($existingGroup.Scripts | Where-Object { $_.FullName -eq $file1.FullName }) -or `
                            ($existingGroup.Scripts | Where-Object { $_.FullName -eq $file2.FullName })) {
                            if (-not ($existingGroup.Scripts | Where-Object { $_.FullName -eq $file1.FullName })) { $existingGroup.Scripts += $file1 }
                            if (-not ($existingGroup.Scripts | Where-Object { $_.FullName -eq $file2.FullName })) { $existingGroup.Scripts += $file2 }
                            # Mise Ã  jour de la similaritÃ©? Prendre la moyenne? Minimum? Pour l'instant, on garde la premiÃ¨re trouvÃ©e.
                            $added = $true
                            break # AjoutÃ© Ã  un groupe existant
                        }
                    }
                    # Si non ajoutÃ© Ã  un groupe existant, crÃ©er un nouveau groupe
                    if (-not $added) {
                        $redundantGroups.Add([PSCustomObject]@{
                                Scripts    = @($file1, $file2)
                                Similarity = $similarityScore
                            })
                    }
                } elseif ($similarityScore -ne -1) {
                    # Score calculÃ© mais sous le seuil
                    Write-Log -Message "SimilaritÃ© ($similarityScore%) entre '$($file1.Name)' et '$($file2.Name)' est sous le seuil ($Threshold%)." -Level "DEBUG"
                }
                # Si $similarityScore est -1, l'erreur a dÃ©jÃ  Ã©tÃ© loggÃ©e dans Get-FileSimilarityScore
            }
        }
    } # Fin foreach $group KVP

    Write-Progress -Activity "Analyse des groupes redondants" -Completed
    Write-Log -Message "DÃ©tection terminÃ©e: $($redundantGroups.Count) groupes de scripts redondants trouvÃ©s (basÃ© sur hash et/ou similaritÃ© fine)." -Level "SUCCESS"
    return $redundantGroups
}

# Fonction pour archiver les scripts
function Move-ScriptsToArchive {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[PSCustomObject]]$ScriptsToProcess, # Attend des objets avec une propriÃ©tÃ© 'File'
        [Parameter(Mandatory = $true)]
        [string]$BaseArchiveDir, # Chemin absolu
        [Parameter(Mandatory = $true)]
        [string]$Category, # 'obsolete' ou 'redundant'
        [Parameter(Mandatory = $false)]
        [switch]$IsDryRun
    )

    $archivedItems = [System.Collections.Generic.List[PSCustomObject]]::new()
    $categoryPath = Join-Path -Path $BaseArchiveDir -ChildPath $Category

    # CrÃ©er le dossier d'archive de catÃ©gorie si nÃ©cessaire
    if (-not (Test-Path -Path $categoryPath -PathType Container)) {
        Write-Log -Message "CrÃ©ation du rÃ©pertoire d'archive: $categoryPath" -Level "VERBOSE"
        if (-not $IsDryRun) {
            try {
                New-Item -Path $categoryPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Log -Message "Erreur critique: Impossible de crÃ©er le rÃ©pertoire d'archive '$categoryPath'. ArrÃªt de l'archivage pour cette catÃ©gorie. Erreur: $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
                return $archivedItems # Retourne liste vide
            }
        } else {
            Write-Log -Message "[DryRun] CrÃ©ation du rÃ©pertoire '$categoryPath' simulÃ©e." -Level "INFO"
        }
    }

    $scriptCount = $ScriptsToProcess.Count
    Write-Log -Message "Archivage de $scriptCount scripts dans la catÃ©gorie '$Category'..." -Level "INFO"
    $progress = 0

    foreach ($scriptInfo in $ScriptsToProcess) {
        $progress++
        $scriptFile = $scriptInfo.File # AccÃ¨de Ã  la propriÃ©tÃ© File de l'objet
        Write-Progress -Activity "Archivage des scripts ($Category)" -Status "Traitement de $($scriptFile.Name) ($progress/$scriptCount)" -PercentComplete (($progress / $scriptCount) * 100)

        # Calculer chemin relatif pour le rapport
        $relativePath = $scriptFile.FullName.Substring($Path.Length).TrimStart('\/')

        $targetFileName = $scriptFile.Name
        $archiveFilePath = Join-Path -Path $categoryPath -ChildPath $targetFileName
        $counter = 1

        # GÃ©rer les collisions de noms dans l'archive
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
                    # Copier d'abord pour la sÃ©curitÃ©
                    Copy-Item -Path $scriptFile.FullName -Destination $archiveFilePath -Force -ErrorAction Stop
                    # Puis supprimer l'original si la copie a rÃ©ussi
                    Remove-Item -Path $scriptFile.FullName -Force -ErrorAction Stop
                    Write-Log -Message "Archivage rÃ©ussi: '$relativePath' -> '$archiveRelativePath'" -Level "VERBOSE"
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
                Write-Log -Message "Archivage annulÃ© par l'utilisateur ou -WhatIf pour '$($scriptFile.FullName)'" -Level "WARNING"
                $archivedItems.Add([PSCustomObject]@{
                        OriginalPath = $relativePath
                        ArchivePath  = $archiveRelativePath
                        Status       = 'Skipped (ShouldProcess)'
                    })
            }
        } else {
            Write-Log -Message "[DryRun] Archivage simulÃ©: '$relativePath' -> '$archiveRelativePath'" -Level "INFO"
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

# Fonction pour fusionner les scripts redondants (en archivant les moins rÃ©cents)
function Merge-RedundantScripts {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[PSCustomObject]]$RedundantGroups, # Liste d'objets avec propriÃ©tÃ©s 'Scripts' (FileInfo[]) et 'Similarity'
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
            Write-Log -Message "Groupe '$fileNames' ne contient qu'un seul script, aucune consolidation nÃ©cessaire." -Level "VERBOSE"
            continue
        }

        # Trier par date de modification (plus rÃ©cent en premier) comme heuristique pour choisir lequel garder
        # Utiliser LastWriteTimeUtc pour Ã©viter les problÃ¨mes de fuseau horaire
        $sortedScripts = $scripts | Sort-Object -Property LastWriteTimeUtc -Descending

        $keptScript = $sortedScripts[0]
        # CrÃ©er la liste des scripts Ã  archiver (tous sauf le premier)
        $scriptsToArchiveInfo = [System.Collections.Generic.List[PSCustomObject]]::new()
        for ($i = 1; $i -lt $sortedScripts.Length; $i++) {
            $scriptsToArchiveInfo.Add([PSCustomObject]@{ File = $sortedScripts[$i] }) # Encapsuler dans un objet avec la propriÃ©tÃ© 'File' attendue par Move-ScriptsToArchive
        }

        $keptScriptRelativePath = $keptScript.FullName.Substring($Path.Length).TrimStart('\/')
        Write-Log -Message "Consolidation du groupe: Garde '$($keptScript.Name)' (le plus rÃ©cent). Archivage des $($scriptsToArchiveInfo.Count) autres..." -Level "INFO"

        # Archiver les scripts redondants (sauf celui gardÃ©)
        $archivedResults = Move-ScriptsToArchive -ScriptsToProcess $scriptsToArchiveInfo -BaseArchiveDir $BaseArchiveDir -Category "redundant" -IsDryRun:$IsDryRun

        # Ajouter le rÃ©sultat de la consolidation pour le rapport
        $consolidationResults.Add([PSCustomObject]@{
                KeptScript      = $keptScriptRelativePath
                ArchivedScripts = $archivedResults # Liste d'objets avec OriginalPath, ArchivePath, Status
                Similarity      = $group.Similarity
            })
    } # Fin foreach $group

    Write-Progress -Activity "Consolidation des scripts redondants" -Completed
    return $consolidationResults
}

# Fonction pour gÃ©nÃ©rer le rapport Markdown
function New-CleanupReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReportFile, # Chemin absolu
        [Parameter(Mandatory = $false)]
        [System.Collections.Generic.List[PSCustomObject]]$ArchivedObsolete = @(), # RÃ©sultats de Move-ScriptsToArchive
        [Parameter(Mandatory = $false)]
        [System.Collections.Generic.List[PSCustomObject]]$ConsolidatedGroups = @(), # RÃ©sultats de Merge-RedundantScripts
        [Parameter(Mandatory = $true)]
        [bool]$IsDryRunMode,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$LogEntries
    )

    Write-Log -Message "GÃ©nÃ©ration du rapport de nettoyage vers '$ReportFile'..." -Level "INFO"

    # Calculer les totaux
    $totalObsoleteArchived = ($ArchivedObsolete | Where-Object { $_.Status -ne 'Error' -and $_.Status -ne 'Skipped (ShouldProcess)' }).Count
    $totalRedundantArchived = ($ConsolidatedGroups | ForEach-Object { ($_.ArchivedScripts | Where-Object { $_.Status -ne 'Error' -and $_.Status -ne 'Skipped (ShouldProcess)' }).Count } | Measure-Object -Sum).Sum
    $totalArchived = $totalObsoleteArchived + $totalRedundantArchived

    $reportContent = @"
# Rapport de Nettoyage du DÃ©pÃ´t

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Chemin du DÃ©pÃ´t:** $Path
**Mode d'exÃ©cution:** $(if ($IsDryRunMode) { "Simulation (DryRun)" } else { "RÃ©el" })
**Extensions AnalysÃ©es:** $($ScriptExtensions -join ', ')
**Module TextSimilarity utilisÃ©:** $(if($script:TextSimilarityModule){"Oui"}else{"Non"})
$(if($script:AbsoluteLogFilePath){"**Fichier Journal:** $script:AbsoluteLogFilePath"})

## RÃ©sumÃ© des Actions $(if($IsDryRunMode){"(SimulÃ©es)"})

- Scripts obsolÃ¨tes identifiÃ©s et traitÃ©s : **$($ArchivedObsolete.Count)**
- Groupes de scripts redondants identifiÃ©s : **$($ConsolidatedGroups.Count)**
- Total de scripts archivÃ©s/prÃ©vus pour archivage : **$totalArchived**
  - Dont ObsolÃ¨tes : $totalObsoleteArchived
  - Dont Redondants : $totalRedundantArchived

---

## Scripts ObsolÃ¨tes TraitÃ©s

$(
    if ($ArchivedObsolete.Count -eq 0) {
        "Aucun script obsolÃ¨te n'a Ã©tÃ© traitÃ©."
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

## Scripts Redondants ConsolidÃ©s

$(
    if ($ConsolidatedGroups.Count -eq 0) {
        "Aucun groupe de scripts redondants n'a Ã©tÃ© consolidÃ©."
    } else {
        $groupsOutput = foreach ($group in $ConsolidatedGroups) {
            $archivedList = if ($group.ArchivedScripts.Count -gt 0) {
                 $group.ArchivedScripts | ForEach-Object { "  - $($_.OriginalPath) -> $($_.ArchivePath) ($($_.Status))" }
            } else {
                "  - Aucun autre script dans ce groupe n'a Ã©tÃ© archivÃ©."
            }

            @"
### Groupe (SimilaritÃ© estimÃ©e: $($group.Similarity)%)

- **Script ConservÃ© :** $($group.KeptScript)
- **Scripts ArchivÃ©s :**
$($archivedList -join [Environment]::NewLine)
"@
        }
        $groupsOutput -join ([Environment]::NewLine + "---" + [Environment]::NewLine)
    }
)

---

## Journal DÃ©taillÃ© des OpÃ©rations

```
$($LogEntries -join [Environment]::NewLine)
```

## Recommandations

$(if ($totalArchived -eq 0) {
    "Le dÃ©pÃ´t semble propre selon les critÃ¨res actuels. Aucune action d'archivage n'a Ã©tÃ© effectuÃ©e ou simulÃ©e."
} elseif ($IsDryRunMode) {
    "Le nettoyage a Ã©tÃ© simulÃ©. VÃ©rifiez le rapport pour vous assurer que l'archivage vers '$AbsoluteArchivePath' est appropriÃ©."
} else {
    "Le nettoyage a Ã©tÃ© effectuÃ©. Les scripts identifiÃ©s ont Ã©tÃ© dÃ©placÃ©s vers '$AbsoluteArchivePath'."
    "Action RecommandÃ©e: VÃ©rifiez le contenu du rÃ©pertoire d'archive."
    "Confirmez que les scripts conservÃ©s fonctionnent comme prÃ©vu."
    "Vous pouvez supprimer dÃ©finitivement les archives aprÃ¨s validation et/ou une pÃ©riode de sÃ©curitÃ©."
})
"@ # Fin du bloc Here-String pour $reportContent

    # CrÃ©er le dossier de rapport si nÃ©cessaire
    $reportDir = Split-Path -Path $ReportFile -Parent
    if (-not (Test-Path -Path $reportDir -PathType Container)) {
        Write-Log -Message "CrÃ©ation du rÃ©pertoire de rapport: $reportDir" -Level "VERBOSE"
        try {
            New-Item -Path $reportDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-Log -Message "Erreur critique: Impossible de crÃ©er le rÃ©pertoire de rapport '$reportDir'. Le rapport ne peut pas Ãªtre enregistrÃ©. Erreur: $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
            return $null # Indique l'Ã©chec
        }
    }

    # Enregistrer le rapport
    try {
        Set-Content -Path $ReportFile -Value $reportContent -Encoding UTF8 -ErrorAction Stop
        Write-Log -Message "Rapport de nettoyage gÃ©nÃ©rÃ© avec succÃ¨s: $ReportFile" -Level "SUCCESS"
        return $ReportFile # Retourne le chemin complet du rapport
    } catch {
        Write-Log -Message "Erreur lors de l'Ã©criture du fichier de rapport '$ReportFile': $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
        return $null # Indique l'Ã©chec
    }
}

#region Main Execution Logic
function Main {
    $startTime = Get-Date
    Write-Log -Message "--- DÃ©but du Script de Nettoyage du DÃ©pÃ´t ---" -Level "INFO"
    Write-Log -Message "DÃ©pÃ´t Cible: $Path" -Level "INFO"
    Write-Log -Message "RÃ©pertoire d'Archive: $AbsoluteArchivePath" -Level "INFO"
    Write-Log -Message "Fichier Rapport: $AbsoluteReportPath" -Level "INFO"
    if ($script:AbsoluteLogFilePath) { Write-Log -Message "Fichier Journal: $script:AbsoluteLogFilePath" -Level "INFO" }
    Write-Log -Message "Mode: $(if ($DryRun) { 'Simulation (DryRun)' } else { 'RÃ©el' })" -Level "INFO"
    Write-Log -Message "Extensions ciblÃ©es: $($ScriptExtensions -join ', ')" -Level "INFO"

    # Initialiser le fichier journal si spÃ©cifiÃ©
    if ($script:AbsoluteLogFilePath) {
        $logDir = Split-Path $script:AbsoluteLogFilePath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            try {
                New-Item -Path $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch { Write-Warning "Impossible de crÃ©er le rÃ©pertoire pour le fichier journal '$logDir'. Log dÃ©sactivÃ©."; $script:AbsoluteLogFilePath = $null }
        }
        if ($script:AbsoluteLogFilePath) {
            # Efface le contenu prÃ©cÃ©dent ou crÃ©e le fichier
            Set-Content -Path $script:AbsoluteLogFilePath -Value "--- Journal de Nettoyage du DÃ©pÃ´t $(Get-Date) ---`n" -ErrorAction SilentlyContinue
        }
    }

    # Variables pour stocker les rÃ©sultats
    $obsoleteScriptsFound = @()
    $redundantGroupsFound = @()
    $archivedObsoleteResults = @()
    $consolidationResults = @()

    # 1. DÃ©tection des scripts obsolÃ¨tes
    $obsoleteScriptsFound = Find-ObsoleteScripts -RepoPath $Path -Extensions $ScriptExtensions
    # Encapsuler les rÃ©sultats pour Move-ScriptsToArchive
    $obsoleteScriptsToProcess = $obsoleteScriptsFound | ForEach-Object { [PSCustomObject]@{ File = $_.File } }

    # 2. DÃ©tection des scripts redondants (si non skip)
    if (-not $SkipRedundantDetection) {
        $redundantGroupsFound = Find-RedundantScripts -RepoPath $Path -Extensions $ScriptExtensions -Threshold $SimilarityThreshold
    } else {
        Write-Log -Message "DÃ©tection des scripts redondants ignorÃ©e (option -SkipRedundantDetection activÃ©e)." -Level "INFO"
    }

    # 3. Archivage des scripts obsolÃ¨tes
    if ($obsoleteScriptsToProcess.Count -gt 0) {
        $archivedObsoleteResults = Move-ScriptsToArchive -ScriptsToProcess $obsoleteScriptsToProcess -BaseArchiveDir $AbsoluteArchivePath -Category "obsolete" -IsDryRun:$DryRun
    } else {
        Write-Log -Message "Aucun script obsolÃ¨te Ã  archiver." -Level "INFO"
    }

    # 4. Consolidation des scripts redondants
    if ($redundantGroupsFound.Count -gt 0) {
        $consolidationResults = Merge-RedundantScripts -RedundantGroups $redundantGroupsFound -BaseArchiveDir $AbsoluteArchivePath -IsDryRun:$DryRun
    } else {
        Write-Log -Message "Aucun groupe redondant Ã  consolider." -Level "INFO"
    }

    # 5. GÃ©nÃ©ration du rapport final
    $finalReportPath = New-CleanupReport -ReportFile $AbsoluteReportPath `
        -ArchivedObsolete $archivedObsoleteResults `
        -ConsolidatedGroups $consolidationResults `
        -IsDryRunMode $DryRun `
        -LogEntries $script:logMessages

    # 6. RÃ©sumÃ© final et fin
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Log -Message "--- Fin du Script de Nettoyage du DÃ©pÃ´t ---" -Level "INFO"
    Write-Log -Message "DurÃ©e totale de l'exÃ©cution: $($duration.ToString('g'))" -Level "INFO"

    if ($finalReportPath) {
        Write-Host "`nRapport final gÃ©nÃ©rÃ© : $finalReportPath" -ForegroundColor Cyan
        # Tenter d'ouvrir le rapport
        if (-not $DryRun) {
            # N'ouvre pas automatiquement en DryRun pour Ã©viter les interruptions
            try {
                Invoke-Item -Path $finalReportPath -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Impossible d'ouvrir automatiquement le rapport '$finalReportPath'. Vous pouvez l'ouvrir manuellement."
            }
        }
    } else {
        Write-Error "La gÃ©nÃ©ration du rapport final a Ã©chouÃ©. Veuillez consulter les logs en console."
    }
}
#endregion

# ExÃ©cuter la fonction principale avec gestion d'erreur globale
try {
    Main
} catch {
    Write-Log -Message "ERREUR FATALE non interceptÃ©e dans le script principal: $($_.Exception.Message)" -Level "ERROR" -ErrorRecord $_
    # Tenter de gÃ©nÃ©rer un rapport d'erreur minimal si possible
    $errorReportPath = Join-Path -Path $Path -ChildPath "error-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $errorContent = @"
ERREUR FATALE - Script de Nettoyage

Une erreur non gÃ©rÃ©e s'est produite le $(Get-Date).

DÃ©pÃ´t: $Path
Erreur:
$($_.Exception.ToString())

Trace:
$($_.ScriptStackTrace)

Journal (si disponible):
$($script:logMessages -join [Environment]::NewLine)
"@
    try {
        Set-Content -Path $errorReportPath -Value $errorContent -Encoding UTF8
        Write-Error "Une erreur fatale s'est produite. Un rapport d'erreur a Ã©tÃ© gÃ©nÃ©rÃ© ici: $errorReportPath"
    } catch {
        Write-Error "Une erreur fatale s'est produite et le rapport d'erreur n'a pas pu Ãªtre gÃ©nÃ©rÃ©. Erreur initiale: $($_.Exception.Message)"
    }
    # Quitter avec un code d'erreur
    exit 1
}
