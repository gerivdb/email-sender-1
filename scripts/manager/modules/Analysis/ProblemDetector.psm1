# Module de détection des problèmes pour le Script Manager
# Ce module détecte les problèmes potentiels dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, problems, scripts

function Find-CodeProblems {
    <#
    .SYNOPSIS
        Détecte les problèmes potentiels dans un script
    .DESCRIPTION
        Analyse le contenu d'un script pour détecter les problèmes courants
    .PARAMETER Content
        Contenu du script à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .PARAMETER Path
        Chemin du script (utilisé pour des vérifications contextuelles)
    .EXAMPLE
        Find-CodeProblems -Content $scriptContent -ScriptType "PowerShell" -Path "C:\Scripts\MyScript.ps1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("PowerShell", "Python", "Batch", "Shell", "Unknown")]
        [string]$ScriptType,
        
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    # Initialiser le tableau des problèmes
    $Problems = @()
    
    # Vérifications communes à tous les types de scripts
    
    # Vérifier les lignes trop longues
    $Lines = $Content -split "`n"
    $LongLines = @()
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Length -gt 120) {
            $LongLines += [PSCustomObject]@{
                LineNumber = $i + 1
                Length = $Lines[$i].Length
                Line = $Lines[$i].Substring(0, [math]::Min(50, $Lines[$i].Length)) + "..."
            }
        }
    }
    
    if ($LongLines.Count -gt 0) {
        $Problems += [PSCustomObject]@{
            Type = "Style"
            Severity = "Low"
            Message = "Lignes trop longues (> 120 caractères)"
            Details = "$($LongLines.Count) lignes dépassent la longueur recommandée"
            Locations = $LongLines | ForEach-Object {
                [PSCustomObject]@{
                    LineNumber = $_.LineNumber
                    Description = "Ligne de $($_.Length) caractères: $($_.Line)"
                }
            }
            Recommendation = "Limiter la longueur des lignes à 120 caractères maximum"
        }
    }
    
    # Vérifier les chemins absolus
    $AbsolutePathMatches = [regex]::Matches($Content, "([A-Z]:\\|/(?:etc|usr|var|opt|home))")
    $AbsolutePaths = @()
    foreach ($Match in $AbsolutePathMatches) {
        $LineNumber = $Content.Substring(0, $Match.Index).Split("`n").Length
        $AbsolutePaths += [PSCustomObject]@{
            LineNumber = $LineNumber
            Path = $Match.Value
        }
    }
    
    if ($AbsolutePaths.Count -gt 0) {
        $Problems += [PSCustomObject]@{
            Type = "Portability"
            Severity = "Medium"
            Message = "Utilisation de chemins absolus"
            Details = "$($AbsolutePaths.Count) chemins absolus détectés"
            Locations = $AbsolutePaths | ForEach-Object {
                [PSCustomObject]@{
                    LineNumber = $_.LineNumber
                    Description = "Chemin absolu: $($_.Path)"
                }
            }
            Recommendation = "Utiliser des chemins relatifs ou des variables d'environnement"
        }
    }
    
    # Vérifications spécifiques au type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Vérifier l'utilisation de $null à gauche des comparaisons
            $NullComparisonMatches = [regex]::Matches($Content, "if\s*\(\s*(\$\w+)\s*-eq\s*\$null\s*\)")
            $NullComparisons = @()
            foreach ($Match in $NullComparisonMatches) {
                $LineNumber = $Content.Substring(0, $Match.Index).Split("`n").Length
                $NullComparisons += [PSCustomObject]@{
                    LineNumber = $LineNumber
                    Variable = $Match.Groups[1].Value
                }
            }
            
            if ($NullComparisons.Count -gt 0) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Comparaisons avec `$null du mauvais côté"
                    Details = "$($NullComparisons.Count) comparaisons incorrectes avec `$null"
                    Locations = $NullComparisons | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Variable $($_.Variable) comparée à `$null du mauvais côté"
                        }
                    }
                    Recommendation = "Placer `$null à gauche des comparaisons: if (`$null -eq `$variable)"
                }
            }
            
            # Vérifier l'utilisation de Write-Host sans couleur
            $WriteHostMatches = [regex]::Matches($Content, "Write-Host\s+[^-]+(?!-ForegroundColor)")
            $WriteHosts = @()
            foreach ($Match in $WriteHostMatches) {
                $LineNumber = $Content.Substring(0, $Match.Index).Split("`n").Length
                $WriteHosts += [PSCustomObject]@{
                    LineNumber = $LineNumber
                    Command = $Match.Value.Trim()
                }
            }
            
            if ($WriteHosts.Count -gt 0) {
                $Problems += [PSCustomObject]@{
                    Type = "Style"
                    Severity = "Low"
                    Message = "Utilisation de Write-Host sans couleur"
                    Details = "$($WriteHosts.Count) appels à Write-Host sans spécifier de couleur"
                    Locations = $WriteHosts | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Commande: $($_.Command)"
                        }
                    }
                    Recommendation = "Utiliser -ForegroundColor pour améliorer la lisibilité des messages"
                }
            }
            
            # Vérifier l'utilisation de paramètres switch avec valeur par défaut
            $SwitchDefaultMatches = [regex]::Matches($Content, "\[switch\]\$(\w+)\s*=\s*\$true")
            $SwitchDefaults = @()
            foreach ($Match in $SwitchDefaultMatches) {
                $LineNumber = $Content.Substring(0, $Match.Index).Split("`n").Length
                $SwitchDefaults += [PSCustomObject]@{
                    LineNumber = $LineNumber
                    Parameter = $Match.Groups[1].Value
                }
            }
            
            if ($SwitchDefaults.Count -gt 0) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Paramètres switch avec valeur par défaut `$true"
                    Details = "$($SwitchDefaults.Count) paramètres switch avec valeur par défaut `$true"
                    Locations = $SwitchDefaults | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Paramètre: $($_.Parameter)"
                        }
                    }
                    Recommendation = "Ne pas définir de valeur par défaut pour les paramètres switch"
                }
            }
            
            # Vérifier l'encodage du fichier (si c'est un fichier PowerShell)
            if ($Path -match "\.ps1$") {
                try {
                    $FileContent = Get-Content -Path $Path -Raw -Encoding Byte
                    $HasBOM = $FileContent.Length -ge 3 -and $FileContent[0] -eq 0xEF -and $FileContent[1] -eq 0xBB -and $FileContent[2] -eq 0xBF
                    
                    if (-not $HasBOM) {
                        $Problems += [PSCustomObject]@{
                            Type = "Encoding"
                            Severity = "High"
                            Message = "Fichier PowerShell sans BOM UTF-8"
                            Details = "Le fichier n'est pas encodé en UTF-8 avec BOM"
                            Locations = @(
                                [PSCustomObject]@{
                                    LineNumber = 0
                                    Description = "Encodage du fichier"
                                }
                            )
                            Recommendation = "Enregistrer le fichier en UTF-8 avec BOM pour éviter les problèmes d'encodage avec PowerShell"
                        }
                    }
                } catch {
                    # Ignorer les erreurs de lecture du fichier
                }
            }
        }
        "Python" {
            # Vérifier l'utilisation de print au lieu de logging
            $PrintMatches = [regex]::Matches($Content, "print\s*\(")
            $LoggingImport = $Content -match "import\s+logging"
            $Prints = @()
            foreach ($Match in $PrintMatches) {
                $LineNumber = $Content.Substring(0, $Match.Index).Split("`n").Length
                $Prints += [PSCustomObject]@{
                    LineNumber = $LineNumber
                    Command = $Match.Value.Trim()
                }
            }
            
            if ($Prints.Count -gt 0 -and -not $LoggingImport) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Low"
                    Message = "Utilisation de print au lieu de logging"
                    Details = "$($Prints.Count) appels à print sans utilisation du module logging"
                    Locations = $Prints | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Commande: $($_.Command)"
                        }
                    }
                    Recommendation = "Utiliser le module logging pour les messages de log"
                }
            }
            
            # Vérifier l'utilisation de except sans type d'exception spécifié
            $BareExceptMatches = [regex]::Matches($Content, "except\s*:")
            $BareExcepts = @()
            foreach ($Match in $BareExceptMatches) {
                $LineNumber = $Content.Substring(0, $Match.Index).Split("`n").Length
                $BareExcepts += [PSCustomObject]@{
                    LineNumber = $LineNumber
                    Command = $Match.Value.Trim()
                }
            }
            
            if ($BareExcepts.Count -gt 0) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Utilisation de except sans type d'exception"
                    Details = "$($BareExcepts.Count) blocs except sans type d'exception spécifié"
                    Locations = $BareExcepts | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Commande: $($_.Command)"
                        }
                    }
                    Recommendation = "Spécifier le type d'exception à capturer: except ExceptionType:"
                }
            }
        }
        "Batch" {
            # Vérifier l'utilisation de ECHO sans OFF
            $EchoOffMissing = -not ($Content -match "@ECHO OFF")
            
            if ($EchoOffMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Low"
                    Message = "Absence de @ECHO OFF"
                    Details = "Le script ne désactive pas l'affichage des commandes"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "Début du script"
                        }
                    )
                    Recommendation = "Ajouter @ECHO OFF au début du script pour désactiver l'affichage des commandes"
                }
            }
            
            # Vérifier l'utilisation de SETLOCAL
            $SetlocalMissing = -not ($Content -match "SETLOCAL")
            
            if ($SetlocalMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Absence de SETLOCAL"
                    Details = "Le script ne limite pas la portée des variables"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "Début du script"
                        }
                    )
                    Recommendation = "Ajouter SETLOCAL au début du script pour limiter la portée des variables"
                }
            }
        }
        "Shell" {
            # Vérifier l'utilisation de #!/bin/bash ou #!/bin/sh
            $ShebangMissing = -not ($Content -match "^#!/bin/(bash|sh)")
            
            if ($ShebangMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Absence de shebang"
                    Details = "Le script ne spécifie pas l'interpréteur à utiliser"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "Début du script"
                        }
                    )
                    Recommendation = "Ajouter #!/bin/bash ou #!/bin/sh en première ligne du script"
                }
            }
            
            # Vérifier l'utilisation de set -e
            $SetEMissing = -not ($Content -match "set -e")
            
            if ($SetEMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Absence de set -e"
                    Details = "Le script ne s'arrête pas en cas d'erreur"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "Début du script"
                        }
                    )
                    Recommendation = "Ajouter set -e au début du script pour qu'il s'arrête en cas d'erreur"
                }
            }
        }
    }
    
    return $Problems
}

# Exporter les fonctions
Export-ModuleMember -Function Find-CodeProblems
