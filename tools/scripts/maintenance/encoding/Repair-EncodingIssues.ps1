# Script pour corriger les problemes d'encodage dans les fichiers PowerShell
# Version ASCII uniquement pour eviter les problemes d'encodage

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

function Test-FileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)

        # Verifier les differents BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return @{
                Encoding = "UTF-8 with BOM"
                HasBOM   = $true
            }
        } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            return @{
                Encoding = "UTF-16 BE"
                HasBOM   = $true
            }
        } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            return @{
                Encoding = "UTF-16 LE"
                HasBOM   = $true
            }
        } else {
            # Pas de BOM detecte
            return @{
                Encoding = "Unknown (possibly UTF-8 without BOM or ANSI)"
                HasBOM   = $false
            }
        }
    } catch {
        Write-Error "Erreur lors de la detection de l'encodage du fichier '$FilePath': $_"
        return $null
    }
}

function Repair-FileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    try {
        # Verifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return $false
        }

        # Verifier l'encodage du fichier
        $encodingInfo = Test-FileEncoding -FilePath $FilePath

        # Si le fichier a deja un BOM UTF-8, verifier s'il contient des references de variables dans des chaines accentuees
        if ($encodingInfo.HasBOM -and $encodingInfo.Encoding -eq "UTF-8 with BOM") {
            Write-Verbose "Le fichier '$FilePath' est deja en UTF-8 avec BOM."

            # Verifier s'il contient des references de variables dans des chaines accentuees
            $content = Get-Content -Path $FilePath -Raw
            $needsVariableFix = $false

            # Pattern pour les references de variables
            $variablePattern = '\$[a-zA-Z0-9_]+'

            # Pattern pour les caracteres accentues (utilisant des codes Unicode)
            $accentedPattern = '[^\x00-\x7F]'

            # Rechercher les lignes contenant a la fois des caracteres accentues et des references de variables
            $lines = $content -split "`r`n|`r|`n"
            $problematicLines = @()

            foreach ($line in $lines) {
                if ($line -match $variablePattern -and $line -match $accentedPattern) {
                    $needsVariableFix = $true
                    $problematicLines += $line
                }
            }

            if ($needsVariableFix) {
                Write-Verbose "Le fichier '$FilePath' contient des references de variables dans des chaines accentuees."

                if (-not $WhatIf) {
                    # Creer une sauvegarde du fichier
                    $backupPath = "$FilePath.bak"
                    Copy-Item -Path $FilePath -Destination $backupPath -Force
                    Write-Verbose "Sauvegarde creee: $backupPath"

                    # Corriger les references de variables
                    $newContent = $content

                    foreach ($line in $problematicLines) {
                        # Extraire les references de variables
                        $variableMatches = [regex]::Matches($line, $variablePattern)
                        $variables = $variableMatches | ForEach-Object { $_.Value }

                        $newLine = $line

                        foreach ($variable in $variables) {
                            # Remplacer la reference de variable par une concatenation
                            $newLine = $newLine -replace "\$variable", "' + $variable + '"
                        }

                        # Si la ligne commence par une concatenation, la corriger
                        $newLine = $newLine -replace "^' \+ ", ""

                        # Si la ligne se termine par une concatenation, la corriger
                        $newLine = $newLine -replace " \+ '$", ""

                        # Remplacer la ligne dans le contenu
                        $newContent = $newContent -replace [regex]::Escape($line), $newLine
                    }

                    # Enregistrer le fichier avec le meme encodage
                    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
                    [System.IO.File]::WriteAllText($FilePath, $newContent, $utf8WithBom)

                    Write-Host "References de variables corrigees dans le fichier '$FilePath'" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "Le fichier '$FilePath' serait corrige (WhatIf)" -ForegroundColor Yellow
                    return $true
                }
            }

            return $false
        }

        # Le fichier n'a pas de BOM UTF-8, le corriger
        if (-not $WhatIf) {
            # Lire le contenu du fichier
            $content = Get-Content -Path $FilePath -Raw

            # Creer une sauvegarde du fichier
            $backupPath = "$FilePath.bak"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Verbose "Sauvegarde creee: $backupPath"

            # Enregistrer le fichier en UTF-8 avec BOM
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText($FilePath, $content, $utf8WithBom)

            Write-Host "Encodage corrige pour le fichier '$FilePath'" -ForegroundColor Green
            return $true
        } else {
            Write-Host "L'encodage du fichier '$FilePath' serait corrige (WhatIf)" -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Error "Erreur lors de la correction de l'encodage du fichier '$FilePath': $_"
        return $false
    }
}

# Fonction principale
function Start-EncodingRepair {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    try {
        # Verifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Obtenir la liste des fichiers PowerShell
        $getChildItemParams = @{
            Path   = $Path
            Filter = "*.ps1"
            File   = $true
        }

        if ($Recurse) {
            $getChildItemParams.Recurse = $true
        }

        $files = Get-ChildItem @getChildItemParams

        # Corriger chaque fichier
        $correctedCount = 0

        foreach ($file in $files) {
            Write-Verbose "Analyse du fichier '$($file.FullName)'..."
            $corrected = Repair-FileEncoding -FilePath $file.FullName -WhatIf:$WhatIf

            if ($corrected) {
                $correctedCount++
            }
        }

        # Afficher le resume
        if ($WhatIf) {
            Write-Host "`n$correctedCount fichiers seraient corriges (WhatIf)" -ForegroundColor Yellow
        } else {
            Write-Host "`n$correctedCount fichiers corriges" -ForegroundColor Green
        }
    } catch {
        Write-Error "Erreur lors de la correction de l'encodage: $_"
    }
}

# Executer la correction
Start-EncodingRepair -Path $Path -Recurse:$Recurse -WhatIf:$WhatIf
