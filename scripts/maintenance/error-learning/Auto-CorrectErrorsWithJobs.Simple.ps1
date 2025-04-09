<#
.SYNOPSIS
    Version simplifiée pour corriger plusieurs scripts PowerShell en parallèle avec Jobs PowerShell.
.DESCRIPTION
    Ce script utilise des Jobs PowerShell pour corriger plusieurs scripts PowerShell simultanément.
    Compatible avec PowerShell 5.1.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$ScriptPaths,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxJobs = 5
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Vérifier que les chemins existent et convertir en chemins absolus
$validPaths = @()
foreach ($path in $ScriptPaths) {
    # Convertir en chemin absolu
    $absolutePath = $path
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $absolutePath = Join-Path -Path $PWD.Path -ChildPath $path
    }
    
    if (Test-Path -Path $absolutePath) {
        $validPaths += $absolutePath
    }
    else {
        Write-Warning "Le chemin spécifié n'existe pas : $absolutePath"
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
    }
)

# Créer un script block pour la correction d'un script
$scriptBlock = {
    param($scriptPath, $patterns, $whatIf)
    
    Write-Host "Traitement du script : $scriptPath"
    
    try {
        # Lire le contenu du script
        $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop
        $scriptLines = Get-Content -Path $scriptPath -ErrorAction Stop
        
        # Analyser le script
        $detectedIssues = @()
        
        # Analyser chaque pattern
        foreach ($pattern in $patterns) {
            $regexMatches = [regex]::Matches($scriptContent, $pattern.Pattern)
            
            if ($regexMatches.Count -gt 0) {
                foreach ($match in $regexMatches) {
                    # Trouver le numéro de ligne
                    $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length
                    
                    # Créer un objet pour l'erreur détectée
                    $issue = [PSCustomObject]@{
                        Name = $pattern.Name
                        Description = $pattern.Description
                        LineNumber = $lineNumber
                        Line = $scriptLines[$lineNumber - 1]
                        Match = $match.Value
                        Correction = $pattern.Correction
                    }
                    
                    $detectedIssues += $issue
                }
            }
        }
        
        # Si aucune erreur n'est détectée, retourner un résultat vide
        if ($detectedIssues.Count -eq 0) {
            Write-Host "Aucune erreur détectée dans $scriptPath."
            return [PSCustomObject]@{
                ScriptPath = $scriptPath
                IssuesCount = 0
                CorrectionCount = 0
                Success = $true
            }
        }
        
        # Trier les problèmes par numéro de ligne (décroissant) pour éviter les décalages
        $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending
        
        # Créer une sauvegarde du script original
        $backupPath = "$scriptPath.bak"
        
        if (-not $whatIf) {
            Copy-Item -Path $scriptPath -Destination $backupPath -Force
        }
        
        # Appliquer les corrections
        $correctionsApplied = 0
        
        foreach ($issue in $sortedIssues) {
            $lineIndex = $issue.LineNumber - 1
            $originalLine = $scriptLines[$lineIndex]
            
            try {
                $newLine = & $issue.Correction $originalLine
                
                if ($whatIf) {
                    Write-Host "WhatIf: Ligne $($issue.LineNumber) - $($issue.Description)"
                    Write-Host "  Avant: $originalLine"
                    Write-Host "  Après: $newLine"
                }
                else {
                    $scriptLines[$lineIndex] = $newLine
                }
                
                $correctionsApplied++
            }
            catch {
                Write-Warning "Impossible d'appliquer une correction pour l'erreur à la ligne $($issue.LineNumber) : $($issue.Description)"
            }
        }
        
        # Sauvegarder le script corrigé
        if (-not $whatIf) {
            $scriptLines | Out-File -FilePath $scriptPath -Force -Encoding UTF8
        }
        
        Write-Host "Correction terminée pour $scriptPath. Corrections appliquées : $correctionsApplied"
        
        return [PSCustomObject]@{
            ScriptPath = $scriptPath
            IssuesCount = $detectedIssues.Count
            CorrectionCount = $correctionsApplied
            Success = $true
        }
    }
    catch {
        Write-Warning "Erreur lors de la correction de $scriptPath : $($_.Exception.Message)"
        return $null
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
        Start-Sleep -Seconds 1
        $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }
    }
    
    # Démarrer un nouveau job
    $scriptPath = $validPaths[$scriptIndex]
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $scriptPath, $errorPatterns, $WhatIfPreference
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
    if ($jobResult) {
        $results += $jobResult
    }
    Remove-Job -Job $job
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des corrections :"
Write-Host "  Scripts traités : $($results.Count)"
Write-Host "  Total des problèmes détectés : $(($results | Measure-Object -Property IssuesCount -Sum).Sum)"
Write-Host "  Total des corrections appliquées : $(($results | Measure-Object -Property CorrectionCount -Sum).Sum)"

Write-Host "`nTraitement terminé."
