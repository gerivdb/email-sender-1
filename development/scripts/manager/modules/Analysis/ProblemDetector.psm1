# Module de dÃ©tection des problÃ¨mes pour le Script Manager
# Ce module dÃ©tecte les problÃ¨mes potentiels dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, problems, scripts

function Find-CodeProblems {
    <#
    .SYNOPSIS
        DÃ©tecte les problÃ¨mes potentiels dans un script
    .DESCRIPTION
        Analyse le contenu d'un script pour dÃ©tecter les problÃ¨mes courants
    .PARAMETER Content
        Contenu du script Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .PARAMETER Path
        Chemin du script (utilisÃ© pour des vÃ©rifications contextuelles)
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
    
    # Initialiser le tableau des problÃ¨mes
    $Problems = @()
    
    # VÃ©rifications communes Ã  tous les types de scripts
    
    # VÃ©rifier les lignes trop longues
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
            Message = "Lignes trop longues (> 120 caractÃ¨res)"
            Details = "$($LongLines.Count) lignes dÃ©passent la longueur recommandÃ©e"
            Locations = $LongLines | ForEach-Object {
                [PSCustomObject]@{
                    LineNumber = $_.LineNumber
                    Description = "Ligne de $($_.Length) caractÃ¨res: $($_.Line)"
                }
            }
            Recommendation = "Limiter la longueur des lignes Ã  120 caractÃ¨res maximum"
        }
    }
    
    # VÃ©rifier les chemins absolus
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
            Details = "$($AbsolutePaths.Count) chemins absolus dÃ©tectÃ©s"
            Locations = $AbsolutePaths | ForEach-Object {
                [PSCustomObject]@{
                    LineNumber = $_.LineNumber
                    Description = "Chemin absolu: $($_.Path)"
                }
            }
            Recommendation = "Utiliser des chemins relatifs ou des variables d'environnement"
        }
    }
    
    # VÃ©rifications spÃ©cifiques au type de script
    switch ($ScriptType) {
        "PowerShell" {
            # VÃ©rifier l'utilisation de $null Ã  gauche des comparaisons
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
                    Message = "Comparaisons avec `$null du mauvais cÃ´tÃ©"
                    Details = "$($NullComparisons.Count) comparaisons incorrectes avec `$null"
                    Locations = $NullComparisons | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Variable $($_.Variable) comparÃ©e Ã  `$null du mauvais cÃ´tÃ©"
                        }
                    }
                    Recommendation = "Placer `$null Ã  gauche des comparaisons: if (`$null -eq `$variable)"
                }
            }
            
            # VÃ©rifier l'utilisation de Write-Host sans couleur
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
                    Details = "$($WriteHosts.Count) appels Ã  Write-Host sans spÃ©cifier de couleur"
                    Locations = $WriteHosts | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Commande: $($_.Command)"
                        }
                    }
                    Recommendation = "Utiliser -ForegroundColor pour amÃ©liorer la lisibilitÃ© des messages"
                }
            }
            
            # VÃ©rifier l'utilisation de paramÃ¨tres switch avec valeur par dÃ©faut
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
                    Message = "ParamÃ¨tres switch avec valeur par dÃ©faut `$true"
                    Details = "$($SwitchDefaults.Count) paramÃ¨tres switch avec valeur par dÃ©faut `$true"
                    Locations = $SwitchDefaults | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "ParamÃ¨tre: $($_.Parameter)"
                        }
                    }
                    Recommendation = "Ne pas dÃ©finir de valeur par dÃ©faut pour les paramÃ¨tres switch"
                }
            }
            
            # VÃ©rifier l'encodage du fichier (si c'est un fichier PowerShell)
            if ($Path -match "\.ps1$") {
                try {
                    $FileContent = Get-Content -Path $Path -Raw -Encoding Byte
                    $HasBOM = $FileContent.Length -ge 3 -and $FileContent[0] -eq 0xEF -and $FileContent[1] -eq 0xBB -and $FileContent[2] -eq 0xBF
                    
                    if (-not $HasBOM) {
                        $Problems += [PSCustomObject]@{
                            Type = "Encoding"
                            Severity = "High"
                            Message = "Fichier PowerShell sans BOM UTF-8"
                            Details = "Le fichier n'est pas encodÃ© en UTF-8 avec BOM"
                            Locations = @(
                                [PSCustomObject]@{
                                    LineNumber = 0
                                    Description = "Encodage du fichier"
                                }
                            )
                            Recommendation = "Enregistrer le fichier en UTF-8 avec BOM pour Ã©viter les problÃ¨mes d'encodage avec PowerShell"
                        }
                    }
                } catch {
                    # Ignorer les erreurs de lecture du fichier
                }
            }
        }
        "Python" {
            # VÃ©rifier l'utilisation de print au lieu de logging
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
                    Details = "$($Prints.Count) appels Ã  print sans utilisation du module logging"
                    Locations = $Prints | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Commande: $($_.Command)"
                        }
                    }
                    Recommendation = "Utiliser le module logging pour les messages de log"
                }
            }
            
            # VÃ©rifier l'utilisation de except sans type d'exception spÃ©cifiÃ©
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
                    Details = "$($BareExcepts.Count) blocs except sans type d'exception spÃ©cifiÃ©"
                    Locations = $BareExcepts | ForEach-Object {
                        [PSCustomObject]@{
                            LineNumber = $_.LineNumber
                            Description = "Commande: $($_.Command)"
                        }
                    }
                    Recommendation = "SpÃ©cifier le type d'exception Ã  capturer: except ExceptionType:"
                }
            }
        }
        "Batch" {
            # VÃ©rifier l'utilisation de ECHO sans OFF
            $EchoOffMissing = -not ($Content -match "@ECHO OFF")
            
            if ($EchoOffMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Low"
                    Message = "Absence de @ECHO OFF"
                    Details = "Le script ne dÃ©sactive pas l'affichage des commandes"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "DÃ©but du script"
                        }
                    )
                    Recommendation = "Ajouter @ECHO OFF au dÃ©but du script pour dÃ©sactiver l'affichage des commandes"
                }
            }
            
            # VÃ©rifier l'utilisation de SETLOCAL
            $SetlocalMissing = -not ($Content -match "SETLOCAL")
            
            if ($SetlocalMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Absence de SETLOCAL"
                    Details = "Le script ne limite pas la portÃ©e des variables"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "DÃ©but du script"
                        }
                    )
                    Recommendation = "Ajouter SETLOCAL au dÃ©but du script pour limiter la portÃ©e des variables"
                }
            }
        }
        "Shell" {
            # VÃ©rifier l'utilisation de #!/bin/bash ou #!/bin/sh
            $ShebangMissing = -not ($Content -match "^#!/bin/(bash|sh)")
            
            if ($ShebangMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Absence de shebang"
                    Details = "Le script ne spÃ©cifie pas l'interprÃ©teur Ã  utiliser"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "DÃ©but du script"
                        }
                    )
                    Recommendation = "Ajouter #!/bin/bash ou #!/bin/sh en premiÃ¨re ligne du script"
                }
            }
            
            # VÃ©rifier l'utilisation de set -e
            $SetEMissing = -not ($Content -match "set -e")
            
            if ($SetEMissing) {
                $Problems += [PSCustomObject]@{
                    Type = "BestPractice"
                    Severity = "Medium"
                    Message = "Absence de set -e"
                    Details = "Le script ne s'arrÃªte pas en cas d'erreur"
                    Locations = @(
                        [PSCustomObject]@{
                            LineNumber = 1
                            Description = "DÃ©but du script"
                        }
                    )
                    Recommendation = "Ajouter set -e au dÃ©but du script pour qu'il s'arrÃªte en cas d'erreur"
                }
            }
        }
    }
    
    return $Problems
}

# Exporter les fonctions
Export-ModuleMember -Function Find-CodeProblems
