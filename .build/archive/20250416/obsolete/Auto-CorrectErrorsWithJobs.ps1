<#
.SYNOPSIS
    Corrige automatiquement les erreurs dans plusieurs scripts PowerShell en parallèle en utilisant des Jobs PowerShell.
.DESCRIPTION
    Ce script utilise des Jobs PowerShell pour analyser et corriger plusieurs scripts PowerShell simultanément
    en appliquant des corrections automatiques basées sur des patterns connus.
    Compatible avec PowerShell 5.1 et versions ultérieures.
.PARAMETER ScriptPaths
    Tableau des chemins des scripts à corriger. Peut également accepter des wildcards (*.ps1).
.PARAMETER MaxJobs
    Nombre maximum de jobs à exécuter en parallèle. La valeur par défaut est 5.
.PARAMETER GenerateReport
    Si spécifié, génère un rapport de correction consolidé.
.PARAMETER ReportPath
    Chemin du fichier de rapport. Par défaut, utilise le répertoire courant.
.PARAMETER WhatIf
    Si spécifié, affiche les corrections qui seraient appliquées sans les appliquer réellement.
.EXAMPLE
    .\Auto-CorrectErrorsWithJobs.ps1 -ScriptPaths "C:\Scripts\*.ps1"
    Corrige tous les scripts PowerShell dans le répertoire C:\Scripts en parallèle.
.EXAMPLE
    .\Auto-CorrectErrorsWithJobs.ps1 -ScriptPaths @("C:\Scripts\Script1.ps1", "C:\Scripts\Script2.ps1") -MaxJobs 2
    Corrige les deux scripts spécifiés en parallèle avec une limite de 2 jobs simultanés.
.EXAMPLE
    .\Auto-CorrectErrorsWithJobs.ps1 -ScriptPaths "C:\Scripts\*.ps1" -WhatIf
    Affiche les corrections qui seraient appliquées sans les appliquer réellement.
.NOTES
    Compatible avec PowerShell 5.1 et versions ultérieures.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$ScriptPaths,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxJobs = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ""
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Résoudre les wildcards dans les chemins de scripts
$resolvedPaths = @()
foreach ($path in $ScriptPaths) {
    if ($path -match '\*') {
        # C'est un wildcard, résoudre les chemins
        $resolvedPaths += Get-ChildItem -Path $path -File | Select-Object -ExpandProperty FullName
    }
    else {
        # C'est un chemin direct
        $resolvedPaths += $path
    }
}

# Vérifier que les chemins existent
$validPaths = @()
foreach ($path in $resolvedPaths) {
    if (Test-Path -Path $path) {
        $validPaths += $path
    }
    else {
        Write-Warning "Le chemin spécifié n'existe pas : $path"
    }
}

if ($validPaths.Count -eq 0) {
    Write-Error "Aucun script valide à corriger."
    exit 1
}

Write-Host "Correction de $($validPaths.Count) scripts en parallèle (MaxJobs: $MaxJobs)..."

# Définir les patterns d'erreurs courantes et leurs corrections
$errorPatterns = @(
    @{
        Name = "HardcodedPath"
        Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
        Description = "Chemin codé en dur détecté"
        Correction = {
            param($Line)
            $Line -replace '(?<!\\)["'']([A-Z]:\\|\\\\)[^"'']*["'']', '(Join-Path -Path $PSScriptRoot -ChildPath "CHEMIN_RELATIF")'
        }
    },
    @{
        Name = "NoErrorHandling"
        Pattern = '(?<!try\s*\{\s*)(?:Get-Content|Set-Content)(?!\s*-ErrorAction)'
        Description = "Absence de gestion d'erreurs détecté"
        Correction = {
            param($Line)
            $Line -replace '(Get-Content|Set-Content)(?!\s*-ErrorAction)', '$1 -ErrorAction Stop'
        }
    },
    @{
        Name = "WriteHostUsage"
        Pattern = 'Write-Host'
        Description = "Utilisation de Write-Host détecté"
        Correction = {
            param($Line)
            $Line -replace 'Write-Host', 'Write-Output'
        }
    },
    @{
        Name = "ObsoleteCmdlet"
        Pattern = '(Get-WmiObject|Invoke-Expression)'
        Description = "Utilisation de cmdlets obsolètes détecté"
        Correction = {
            param($Line)
            $Line -replace 'Get-WmiObject', 'Get-CimInstance'
        }
    }
)

# Pré-compiler les expressions régulières pour de meilleures performances
$compiledPatterns = @()
foreach ($pattern in $errorPatterns) {
    $compiledPatterns += @{
        Name = $pattern.Name
        Regex = [regex]::new($pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
        Description = $pattern.Description
        Correction = $pattern.Correction
    }
}

# Créer un script block pour la correction d'un script
$scriptBlock = {
    param($scriptPath, $patterns, $whatIf)
    
    Write-Host "Traitement du script : $scriptPath"
    
    try {
        # Lire le contenu du script
        $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop
        $scriptLines = Get-Content -Path $scriptPath -ErrorAction Stop
        
        # Préparer les lignes une seule fois
        $lines = $scriptContent.Split("`n")
        
        # Analyser le script
        $detectedIssues = @()
        
        # Analyser chaque pattern
        foreach ($pattern in $patterns) {
            $regexMatches = $pattern.Regex.Matches($scriptContent)
            
            # Traiter les correspondances par lots pour améliorer les performances
            if ($regexMatches.Count -gt 0) {
                foreach ($match in $regexMatches) {
                    # Trouver le numéro de ligne
                    $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length
                    
                    # Extraire la ligne complète
                    $line = $lines[$lineNumber - 1].Trim()
                    
                    # Créer un objet pour l'erreur détectée
                    $issue = [PSCustomObject]@{
                        Name = $pattern.Name
                        Description = $pattern.Description
                        LineNumber = $lineNumber
                        Line = $line
                        Match = $match.Value
                        Correction = $pattern.Correction
                    }
                    
                    $detectedIssues += $issue
                }
            }
        }
        
        # Si aucune erreur n'est détectée, retourner un résultat vide
        if ($detectedIssues.Count -eq 0) {
            $scriptResult = [PSCustomObject]@{
                ScriptPath = $scriptPath
                IssuesCount = 0
                CorrectionCount = 0
                Issues = @()
                Success = $true
                Error = $null
                WhatIf = $whatIf
            }
            
            Write-Host "Aucune erreur détectée dans $scriptPath."
            return $scriptResult
        }
        
        # Trier les problèmes par numéro de ligne (décroissant) pour éviter les décalages
        $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending
        
        # Créer une sauvegarde du script original
        $backupPath = "$scriptPath.bak"
        
        if (-not $whatIf) {
            Copy-Item -Path $scriptPath -Destination $backupPath -Force
        }
        
        # Optimisation : Regrouper les corrections par ligne pour éviter les modifications redondantes
        $lineCorrections = @{}
        
        foreach ($issue in $sortedIssues) {
            $lineIndex = $issue.LineNumber - 1
            
            if (-not $lineCorrections.ContainsKey($lineIndex)) {
                $lineCorrections[$lineIndex] = @{
                    OriginalLine = $scriptLines[$lineIndex]
                    Issues = @()
                }
            }
            
            $lineCorrections[$lineIndex].Issues += $issue
        }
        
        # Appliquer les corrections par ligne
        $correctionsApplied = 0
        
        foreach ($lineIndex in $lineCorrections.Keys | Sort-Object -Descending) {
            $correction = $lineCorrections[$lineIndex]
            $currentLine = $correction.OriginalLine
            
            # Appliquer toutes les corrections pour cette ligne
            foreach ($issue in $correction.Issues) {
                try {
                    $newLine = & $issue.Correction $currentLine
                    
                    if ($whatIf) {
                        Write-Host "WhatIf: Ligne $($issue.LineNumber) - $($issue.Description)"
                        Write-Host "  Avant: $currentLine"
                        Write-Host "  Après: $newLine"
                    }
                    
                    $currentLine = $newLine
                    $correctionsApplied++
                }
                catch {
                    Write-Warning "Impossible d'appliquer une correction pour l'erreur à la ligne $($issue.LineNumber) : $($issue.Description)"
                }
            }
            
            # Mettre à jour la ligne dans le script
            if (-not $whatIf) {
                $scriptLines[$lineIndex] = $currentLine
            }
        }
        
        # Sauvegarder le script corrigé en une seule opération
        if (-not $whatIf) {
            $scriptLines | Out-File -FilePath $scriptPath -Force -Encoding UTF8
        }
        
        # Créer un objet de résultat pour ce script
        $scriptResult = [PSCustomObject]@{
            ScriptPath = $scriptPath
            IssuesCount = $detectedIssues.Count
            CorrectionCount = $correctionsApplied
            Issues = $detectedIssues
            Success = $true
            Error = $null
            WhatIf = $whatIf
        }
        
        if ($whatIf) {
            Write-Host "Simulation terminée pour $scriptPath. Corrections potentielles : $correctionsApplied"
        }
        else {
            Write-Host "Correction terminée pour $scriptPath. Corrections appliquées : $correctionsApplied"
        }
        
        return $scriptResult
    }
    catch {
        # En cas d'erreur, ajouter un résultat d'erreur
        $scriptResult = [PSCustomObject]@{
            ScriptPath = $scriptPath
            IssuesCount = 0
            CorrectionCount = 0
            Issues = @()
            Success = $false
            Error = $_.Exception.Message
            WhatIf = $whatIf
        }
        
        Write-Warning "Erreur lors de la correction de $scriptPath : $($_.Exception.Message)"
        
        return $scriptResult
    }
}

# Créer un tableau pour stocker les résultats
$results = @()

# Créer un tableau pour stocker les jobs
$jobs = @()

# Traiter les scripts par lots
$scriptIndex = 0
while ($scriptIndex -lt $validPaths.Count) {
    # Vérifier le nombre de jobs en cours d'exécution
    $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }
    
    # Si nous avons atteint le nombre maximum de jobs, attendre qu'un job se termine
    while ($runningJobs.Count -ge $MaxJobs) {
        Write-Verbose "Nombre maximum de jobs atteint ($($runningJobs.Count)/$MaxJobs). Attente..."
        Start-Sleep -Seconds 1
        $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }
    }
    
    # Démarrer un nouveau job
    $scriptPath = $validPaths[$scriptIndex]
    Write-Verbose "Démarrage du job pour le script : $scriptPath"
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $scriptPath, $compiledPatterns, $WhatIfPreference
    $jobs += $job
    
    # Incrémenter l'index
    $scriptIndex++
}

# Attendre que tous les jobs se terminent
Write-Host "Attente de la fin de tous les jobs..."
$jobs | Wait-Job | Out-Null

# Récupérer les résultats
foreach ($job in $jobs) {
    $jobResult = Receive-Job -Job $job
    $results += $jobResult
    Remove-Job -Job $job
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des corrections :"
Write-Host "  Scripts traités : $($results.Count)"
Write-Host "  Scripts avec succès : $($results | Where-Object { $_.Success } | Measure-Object).Count"
Write-Host "  Scripts avec erreurs : $($results | Where-Object { -not $_.Success } | Measure-Object).Count"
Write-Host "  Total des problèmes détectés : $(($results | Measure-Object -Property IssuesCount -Sum).Sum)"
Write-Host "  Total des corrections appliquées : $(($results | Measure-Object -Property CorrectionCount -Sum).Sum)"

# Afficher les scripts avec le plus de corrections
$topCorrectionScripts = $results | Where-Object { $_.Success } | Sort-Object -Property CorrectionCount -Descending | Select-Object -First 5
if ($topCorrectionScripts.Count -gt 0) {
    Write-Host "`nTop 5 des scripts avec le plus de corrections :"
    foreach ($script in $topCorrectionScripts) {
        Write-Host "  $($script.ScriptPath) : $($script.CorrectionCount) corrections"
    }
}

# Afficher les types de corrections les plus courants
$correctionTypes = @{}
foreach ($result in $results | Where-Object { $_.Success }) {
    foreach ($issue in $result.Issues) {
        if (-not $correctionTypes.ContainsKey($issue.Name)) {
            $correctionTypes[$issue.Name] = 0
        }
        $correctionTypes[$issue.Name]++
    }
}

if ($correctionTypes.Count -gt 0) {
    Write-Host "`nTypes de corrections les plus courants :"
    foreach ($type in $correctionTypes.GetEnumerator() | Sort-Object -Property Value -Descending) {
        Write-Host "  $($type.Key) : $($type.Value) occurrences"
    }
}

# Générer un rapport si demandé
if ($GenerateReport) {
    if (-not $ReportPath) {
        $ReportPath = Join-Path -Path (Get-Location) -ChildPath "ScriptCorrectionReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    }
    
    try {
        # Créer l'objet de rapport
        $report = [PSCustomObject]@{
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ScriptsProcessed = $results.Count
            ScriptsWithSuccess = ($results | Where-Object { $_.Success } | Measure-Object).Count
            ScriptsWithErrors = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
            TotalIssuesDetected = ($results | Measure-Object -Property IssuesCount -Sum).Sum
            TotalCorrectionsApplied = ($results | Measure-Object -Property CorrectionCount -Sum).Sum
            CorrectionTypesSummary = $correctionTypes
            WhatIfMode = $WhatIfPreference
            Results = $results
        }
        
        # Convertir le rapport en JSON et l'enregistrer
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $ReportPath -Force
        
        Write-Host "`nRapport généré : $ReportPath"
    }
    catch {
        Write-Error "Erreur lors de la génération du rapport : $_"
    }
}

Write-Host "`nTraitement terminé."
