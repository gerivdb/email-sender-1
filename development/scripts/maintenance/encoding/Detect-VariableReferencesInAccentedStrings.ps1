<#
.SYNOPSIS
    DÃƒÂ©tecte les rÃƒÂ©fÃƒÂ©rences de variables dans les chaÃƒÂ®nes accentuÃƒÂ©es qui peuvent causer des problÃƒÂ¨mes.

.DESCRIPTION
    Ce script analyse les fichiers PowerShell pour dÃƒÂ©tecter les rÃƒÂ©fÃƒÂ©rences de variables ($var)
    dans des chaÃƒÂ®nes contenant des caractÃƒÂ¨res accentuÃƒÂ©s, ce qui peut causer des problÃƒÂ¨mes
    d'interprÃƒÂ©tation en fonction de l'encodage du fichier.

.PARAMETER Path
    Chemin du fichier ou du rÃƒÂ©pertoire ÃƒÂ  analyser. Par dÃƒÂ©faut, analyse le rÃƒÂ©pertoire courant.

.PARAMETER Recurse
    Indique si l'analyse doit ÃƒÂªtre rÃƒÂ©cursive dans les sous-rÃƒÂ©pertoires.

.PARAMETER OutputFormat
    Format de sortie des rÃƒÂ©sultats. Valeurs possibles : "Text", "Object", "Json".
    Par dÃƒÂ©faut : "Text".

.EXAMPLE
    .\Detect-VariableReferencesInAccentedStrings.ps1 -Path .\development\scripts -Recurse

.NOTES
    Auteur: SystÃƒÂ¨me d'analyse d'erreurs
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "Object", "Json")]
    [string]$OutputFormat = "Text"
)

function Test-FileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)

        # VÃƒÂ©rifier les diffÃƒÂ©rents BOM
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
            # Pas de BOM dÃƒÂ©tectÃƒÂ©, essayer de dÃƒÂ©terminer l'encodage
            return @{
                Encoding = "Unknown (possibly UTF-8 without BOM or ANSI)"
                HasBOM   = $false
            }
        }
    } catch {
        Write-Error "Erreur lors de la dÃƒÂ©tection de l'encodage du fichier '$FilePath': $_"
        return $null
    }
}

function Find-VariableReferencesInAccentedStrings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # VÃƒÂ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return @()
        }

        # VÃƒÂ©rifier l'encodage du fichier
        $encodingInfo = Test-FileEncoding -FilePath $FilePath

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # DÃƒÂ©finir les patterns de recherche
        $accentedCharsPattern = '[\u00E0-\u00FF\u0100-\u017F]'  # Plage de caractÃƒÂ¨res accentuÃƒÂ©s latins
        $variableReferencePattern = '\$[a-zA-Z0-9_]+'

        # Rechercher les lignes contenant ÃƒÂ  la fois des caractÃƒÂ¨res accentuÃƒÂ©s et des rÃƒÂ©fÃƒÂ©rences de variables
        $results = @()
        $lineNumber = 0

        foreach ($line in $content -split "`r`n|`r|`n") {
            $lineNumber++

            # VÃƒÂ©rifier si la ligne contient des caractÃƒÂ¨res accentuÃƒÂ©s et des rÃƒÂ©fÃƒÂ©rences de variables
            if ($line -match $accentedCharsPattern -and $line -match $variableReferencePattern) {
                # Extraire toutes les rÃƒÂ©fÃƒÂ©rences de variables
                $variableMatches = [regex]::Matches($line, $variableReferencePattern)
                $variables = $variableMatches | ForEach-Object { $_.Value }

                # Extraire tous les caractÃƒÂ¨res accentuÃƒÂ©s
                $accentedMatches = [regex]::Matches($line, $accentedCharsPattern)
                $accentedChars = $accentedMatches | ForEach-Object { $_.Value }

                # VÃƒÂ©rifier si les variables sont ÃƒÂ  proximitÃƒÂ© des caractÃƒÂ¨res accentuÃƒÂ©s
                $potentialIssue = $false
                foreach ($var in $variables) {
                    foreach ($char in $accentedChars) {
                        # VÃƒÂ©rifier si le caractÃƒÂ¨re accentuÃƒÂ© est ÃƒÂ  moins de 10 caractÃƒÂ¨res de la variable
                        $varIndex = $line.IndexOf($var)
                        $charIndex = $line.IndexOf($char)

                        if ([Math]::Abs($varIndex - $charIndex) -lt 10) {
                            $potentialIssue = $true
                            break
                        }
                    }

                    if ($potentialIssue) {
                        break
                    }
                }

                if ($potentialIssue) {
                    $results += [PSCustomObject]@{
                        FilePath      = $FilePath
                        LineNumber    = $lineNumber
                        Line          = $line
                        Variables     = $variables -join ", "
                        AccentedChars = ($accentedChars | Select-Object -Unique) -join ", "
                        Encoding      = $encodingInfo.Encoding
                        HasBOM        = $encodingInfo.HasBOM
                        Risk          = if ($encodingInfo.HasBOM) { "Faible" } else { "Eleve" }
                    }
                }
            }
        }

        return $results
    } catch {
        Write-Error "Erreur lors de l'analyse du fichier '$FilePath': $_"
        return @()
    }
}

# Fonction principale
function Start-Detection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    try {
        # VÃƒÂ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return @()
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

        # Analyser chaque fichier
        $results = @()

        foreach ($file in $files) {
            Write-Verbose "Analyse du fichier '$($file.FullName)'..."
            $fileResults = Find-VariableReferencesInAccentedStrings -FilePath $file.FullName
            $results += $fileResults
        }

        return $results
    } catch {
        Write-Error "Erreur lors de la dÃƒÂ©tection des rÃƒÂ©fÃƒÂ©rences de variables dans les chaÃƒÂ®nes accentuÃƒÂ©es: $_"
        return @()
    }
}

# ExÃƒÂ©cuter la dÃƒÂ©tection
$results = Start-Detection -Path $Path -Recurse:$Recurse

# Afficher les rÃƒÂ©sultats selon le format demandÃƒÂ©
switch ($OutputFormat) {
    "Text" {
        if ($results.Count -eq 0) {
            Write-Host "Aucune rÃƒÂ©fÃƒÂ©rence de variable dans des chaÃƒÂ®nes accentuÃƒÂ©es n'a ÃƒÂ©tÃƒÂ© dÃƒÂ©tectÃƒÂ©e." -ForegroundColor Green
        } else {
            Write-Host "$($results.Count) rÃƒÂ©fÃƒÂ©rences de variables potentiellement problÃƒÂ©matiques dÃƒÂ©tectÃƒÂ©es:" -ForegroundColor Yellow

            foreach ($result in $results) {
                Write-Host "`nFichier: $($result.FilePath)" -ForegroundColor Cyan
                Write-Host "Ligne $($result.LineNumber): $($result.Line)" -ForegroundColor White
                Write-Host "Variables: $($result.Variables)" -ForegroundColor Yellow
                Write-Host "CaractÃƒÂ¨res accentuÃƒÂ©s: $($result.AccentedChars)" -ForegroundColor Magenta
                Write-Host "Encodage: $($result.Encoding)" -ForegroundColor Gray
                Write-Host "Niveau de risque: $($result.Risk)" -ForegroundColor $(if ($result.Risk -eq "Eleve") { "Red" } else { "Green" })
            }
        }
    }
    "Object" {
        $results
    }
    "Json" {
        $results | ConvertTo-Json -Depth 3
    }
}
