<#
.SYNOPSIS
    Module de traitement parallèle optimisé pour PowerShell 5.1.
.DESCRIPTION
    Ce module fournit des fonctions pour exécuter des traitements parallèles optimisés
    en utilisant des Runspace Pools, qui sont plus performants que les Jobs PowerShell
    traditionnels. Compatible avec PowerShell 5.1.
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Compatibilité: PowerShell 5.1 et supérieur
#>

# Importer les fonctions
. "$PSScriptRoot\Invoke-OptimizedParallel.ps1"

# Fonction pour analyser plusieurs scripts en parallèle
function Invoke-ParallelScriptAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ScriptPaths,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,
        
        [Parameter(Mandatory = $false)]
        [array]$ErrorPatterns = @()
    )
    
    begin {
        # Définir les patterns d'erreurs par défaut si non spécifiés
        if ($ErrorPatterns.Count -eq 0) {
            $ErrorPatterns = @(
                @{
                    Name = "HardcodedPath"
                    Pattern = '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1'
                    Description = "Chemin codé en dur détecté"
                },
                @{
                    Name = "NoErrorHandling"
                    Pattern = '(?<!try\s*\{\s*)(?<!\s*\|\s*catch\s*\{\s*)(?:\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item))\b(?![^`n]*?-ErrorAction)'
                    Description = "Absence de gestion d'erreurs détectée"
                },
                @{
                    Name = "WriteHostUsage"
                    Pattern = '\bWrite-Host\b'
                    Description = "Utilisation de Write-Host détectée"
                }
            )
        }
        
        # Créer le script block pour l'analyse
        $scriptBlock = {
            param($scriptPath, $patterns)
            
            try {
                # Lire le contenu du script
                $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop
                
                # Initialiser le résultat
                $result = [PSCustomObject]@{
                    ScriptPath = $scriptPath
                    Issues = @()
                    IssueCount = 0
                    Success = $true
                    Error = $null
                }
                
                # Analyser le script pour chaque pattern
                foreach ($pattern in $patterns) {
                    $regexMatches = [regex]::Matches($scriptContent, $pattern.Pattern)
                    
                    foreach ($match in $regexMatches) {
                        # Trouver le numéro de ligne
                        $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length
                        
                        # Extraire la ligne complète
                        $lines = $scriptContent.Split("`n")
                        $line = $lines[$lineNumber - 1].Trim()
                        
                        # Créer un objet pour l'erreur détectée
                        $issue = [PSCustomObject]@{
                            Name = $pattern.Name
                            Description = $pattern.Description
                            LineNumber = $lineNumber
                            Line = $line
                            Match = $match.Value
                        }
                        
                        $result.Issues += $issue
                        $result.IssueCount++
                    }
                }
                
                return $result
            }
            catch {
                return [PSCustomObject]@{
                    ScriptPath = $scriptPath
                    Issues = @()
                    IssueCount = 0
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        }
        
        # Collecter tous les chemins de scripts
        $allScriptPaths = [System.Collections.Generic.List[string]]::new()
    }
    
    process {
        # Ajouter les chemins de scripts à la liste
        foreach ($path in $ScriptPaths) {
            $allScriptPaths.Add($path)
        }
    }
    
    end {
        # Analyser les scripts en parallèle
        $results = $allScriptPaths | Invoke-OptimizedParallel -ScriptBlock $scriptBlock -MaxThreads $MaxThreads -SharedVariables @{
            patterns = $ErrorPatterns
        }
        
        # Afficher un résumé
        $totalIssues = ($results | Measure-Object -Property IssueCount -Sum).Sum
        $successCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
        $failureCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
        
        Write-Host "`nRésumé de l'analyse :"
        Write-Host "  Scripts analysés : $($results.Count)"
        Write-Host "  Scripts avec succès : $successCount"
        Write-Host "  Scripts avec erreurs : $failureCount"
        Write-Host "  Total des problèmes détectés : $totalIssues"
        
        # Afficher les scripts avec le plus de problèmes
        $topIssueScripts = $results | Where-Object { $_.Success } | Sort-Object -Property IssueCount -Descending | Select-Object -First 5
        if ($topIssueScripts.Count -gt 0) {
            Write-Host "`nTop 5 des scripts avec le plus de problèmes :"
            foreach ($script in $topIssueScripts) {
                Write-Host "  $($script.ScriptPath) : $($script.IssueCount) problèmes"
            }
        }
        
        return $results
    }
}

# Fonction pour corriger plusieurs scripts en parallèle
function Invoke-ParallelScriptCorrection {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ScriptPaths,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,
        
        [Parameter(Mandatory = $false)]
        [array]$ErrorPatterns = @()
    )
    
    begin {
        # Définir les patterns d'erreurs et leurs corrections par défaut si non spécifiés
        if ($ErrorPatterns.Count -eq 0) {
            $ErrorPatterns = @(
                @{
                    Name = "HardcodedPath"
                    Pattern = '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1'
                    Description = "Chemin codé en dur détecté"
                    Correction = {
                        param($Line)
                        $match = [regex]::Match($Line, '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1')
                        if ($match.Success) {
                            $quote = $match.Groups[1].Value
                            return $Line -replace [regex]::Escape($match.Value), "$quote(Join-Path -Path `$PSScriptRoot -ChildPath ""CHEMIN_RELATIF"")$quote"
                        }
                        return $Line
                    }
                },
                @{
                    Name = "NoErrorHandling"
                    Pattern = '(?<!try\s*\{\s*)(?<!\s*\|\s*catch\s*\{\s*)(?:\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item))\b(?![^`n]*?-ErrorAction)'
                    Description = "Absence de gestion d'erreurs détectée"
                    Correction = {
                        param($Line)
                        return $Line -replace '(\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item)\b(?![^`n]*?-ErrorAction))', '$1 -ErrorAction Stop'
                    }
                },
                @{
                    Name = "WriteHostUsage"
                    Pattern = '\bWrite-Host\b'
                    Description = "Utilisation de Write-Host détectée"
                    Correction = {
                        param($Line)
                        return $Line -replace '\bWrite-Host\b', 'Write-Output'
                    }
                }
            )
        }
        
        # Créer le script block pour la correction
        $scriptBlock = {
            param($scriptPath, $patterns, $whatIf)
            
            try {
                # Lire le contenu du script
                $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop
                $scriptLines = Get-Content -Path $scriptPath -ErrorAction Stop
                
                # Initialiser le résultat
                $result = [PSCustomObject]@{
                    ScriptPath = $scriptPath
                    IssuesFound = 0
                    CorrectionsMade = 0
                    Success = $true
                    Error = $null
                    WhatIf = $whatIf
                }
                
                # Détecter les problèmes
                $detectedIssues = @()
                
                foreach ($pattern in $patterns) {
                    $regexMatches = [regex]::Matches($scriptContent, $pattern.Pattern)
                    $result.IssuesFound += $regexMatches.Count
                    
                    foreach ($match in $regexMatches) {
                        # Trouver le numéro de ligne
                        $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length
                        
                        # Créer un objet pour l'erreur détectée
                        $issue = @{
                            Name = $pattern.Name
                            Description = $pattern.Description
                            LineNumber = $lineNumber
                            Line = $scriptLines[$lineNumber - 1]
                            Match = $match.Value
                            Correction = $pattern.Correction
                        }
                        
                        $detectedIssues += [PSCustomObject]$issue
                    }
                }
                
                # Si aucun problème n'est détecté, retourner le résultat
                if ($detectedIssues.Count -eq 0) {
                    return $result
                }
                
                # Trier les problèmes par numéro de ligne (décroissant) pour éviter les décalages
                $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending
                
                # Créer une sauvegarde du script original
                $backupPath = "$scriptPath.bak"
                
                if (-not $whatIf) {
                    Copy-Item -Path $scriptPath -Destination $backupPath -Force
                }
                
                # Appliquer les corrections
                foreach ($issue in $sortedIssues) {
                    $lineIndex = $issue.LineNumber - 1
                    $originalLine = $scriptLines[$lineIndex]
                    
                    try {
                        $newLine = & $issue.Correction $originalLine
                        
                        if ($originalLine -ne $newLine) {
                            if (-not $whatIf) {
                                $scriptLines[$lineIndex] = $newLine
                            }
                            
                            $result.CorrectionsMade++
                        }
                    }
                    catch {
                        # Ignorer les erreurs de correction
                    }
                }
                
                # Sauvegarder le script corrigé
                if (-not $whatIf -and $result.CorrectionsMade -gt 0) {
                    $scriptLines | Out-File -FilePath $scriptPath -Force -Encoding UTF8
                }
                
                return $result
            }
            catch {
                return [PSCustomObject]@{
                    ScriptPath = $scriptPath
                    IssuesFound = 0
                    CorrectionsMade = 0
                    Success = $false
                    Error = $_.Exception.Message
                    WhatIf = $whatIf
                }
            }
        }
        
        # Collecter tous les chemins de scripts
        $allScriptPaths = [System.Collections.Generic.List[string]]::new()
    }
    
    process {
        # Ajouter les chemins de scripts à la liste
        foreach ($path in $ScriptPaths) {
            $allScriptPaths.Add($path)
        }
    }
    
    end {
        # Corriger les scripts en parallèle
        $results = $allScriptPaths | Invoke-OptimizedParallel -ScriptBlock $scriptBlock -MaxThreads $MaxThreads -SharedVariables @{
            patterns = $ErrorPatterns
            whatIf = $WhatIfPreference
        }
        
        # Afficher un résumé
        $totalIssues = ($results | Measure-Object -Property IssuesFound -Sum).Sum
        $totalCorrections = ($results | Measure-Object -Property CorrectionsMade -Sum).Sum
        $successCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
        $failureCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
        
        Write-Host "`nRésumé des corrections :"
        Write-Host "  Scripts traités : $($results.Count)"
        Write-Host "  Scripts avec succès : $successCount"
        Write-Host "  Scripts avec erreurs : $failureCount"
        Write-Host "  Total des problèmes détectés : $totalIssues"
        Write-Host "  Total des corrections appliquées : $totalCorrections"
        
        # Afficher les scripts avec le plus de corrections
        $topCorrectionScripts = $results | Where-Object { $_.Success } | Sort-Object -Property CorrectionsMade -Descending | Select-Object -First 5
        if ($topCorrectionScripts.Count -gt 0) {
            Write-Host "`nTop 5 des scripts avec le plus de corrections :"
            foreach ($script in $topCorrectionScripts) {
                Write-Host "  $($script.ScriptPath) : $($script.CorrectionsMade) corrections"
            }
        }
        
        return $results
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-OptimizedParallel, Invoke-ParallelScriptAnalysis, Invoke-ParallelScriptCorrection
