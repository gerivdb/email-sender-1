# Script pour corriger les references de variables dans les chaines accentuees
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

# Importer le script de detection
$detectionScriptPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "Detect-VariableReferences.ps1"
if (-not (Test-Path -Path $detectionScriptPath -PathType Leaf)) {
    Write-Error "Le script de detection 'Detect-VariableReferences.ps1' est introuvable."
    exit 1
}

# Fonction pour corriger les references de variables dans les chaines accentuees
function Fix-VariableReferences {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    try {
        # Detecter les problemes en executant le script de detection
        $detectionResults = & $detectionScriptPath -Path $FilePath

        if ($detectionResults.Count -eq 0) {
            Write-Verbose "Aucun probleme detecte dans le fichier '$FilePath'."
            return $false
        }

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # Creer une sauvegarde du fichier
        $backupPath = "$FilePath.bak"
        if (-not $WhatIf) {
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Verbose "Sauvegarde creee: $backupPath"
        }

        # Corriger les problemes
        $modified = $false
        $lines = $content -split "`r`n|`r|`n"

        foreach ($result in $detectionResults) {
            $lineNumber = $result.LineNumber - 1  # Ajuster pour l'index base 0
            $line = $lines[$lineNumber]
            $variables = $result.Variables -split ", "

            # Corriger chaque variable dans la ligne
            foreach ($variable in $variables) {
                # Remplacer la reference de variable par une concatenation
                $newLine = $line -replace "\$variable", "' + $variable + '"

                # Si la ligne commence par une concatenation, la corriger
                if ($newLine -match "^' \+ ") {
                    $newLine = $newLine -replace "^' \+ ", ""
                }

                # Si la ligne se termine par une concatenation, la corriger
                if ($newLine -match " \+ '$") {
                    $newLine = $newLine -replace " \+ '$", ""
                }

                # Mettre a jour la ligne
                if ($newLine -ne $line) {
                    $lines[$lineNumber] = $newLine
                    $line = $newLine
                    $modified = $true
                }
            }
        }

        # Enregistrer les modifications
        if ($modified -and -not $WhatIf) {
            $newContent = $lines -join "`r`n"

            # Determiner l'encodage du fichier original
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            # Utiliser UTF-8 avec BOM pour les fichiers PowerShell
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText($FilePath, $newContent, $utf8WithBom)

            Write-Host "Fichier corrige: $FilePath" -ForegroundColor Green
        } elseif ($modified -and $WhatIf) {
            Write-Host "Le fichier '$FilePath' serait modifie (WhatIf)" -ForegroundColor Yellow
        } else {
            Write-Verbose "Aucune modification necessaire pour le fichier '$FilePath'."
        }

        return $modified
    } catch {
        Write-Error "Erreur lors de la correction du fichier '$FilePath': $_"
        return $false
    }
}

# Fonction principale
function Start-Correction {
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
            $corrected = Fix-VariableReferences -FilePath $file.FullName -WhatIf:$WhatIf

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
        Write-Error "Erreur lors de la correction des references de variables: $_"
    }
}

# Executer la correction
Start-Correction -Path $Path -Recurse:$Recurse -WhatIf:$WhatIf
