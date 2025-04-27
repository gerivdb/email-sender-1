# Script pour detecter les references de variables dans les chaines accentuees
# Version ASCII uniquement pour eviter les problemes d'encodage

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [switch]$Recurse
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
        throw "Erreur lors de la detection de l'encodage du fichier '$FilePath': $_"
    }
}

function Find-VariableReferences {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Verifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
        }

        # Verifier l'encodage du fichier
        $encodingInfo = Test-FileEncoding -FilePath $FilePath

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # Pattern pour les references de variables
        $variablePattern = '\$[a-zA-Z0-9_]+'

        # Pattern pour les caracteres accentues (utilisant des codes Unicode)
        $accentedPattern = '[^\x00-\x7F]'

        # Rechercher les lignes contenant a la fois des caracteres accentues et des references de variables
        $results = @()
        $lineNumber = 0

        foreach ($line in $content -split "`r`n|`r|`n") {
            $lineNumber++

            # Verifier si la ligne contient des references de variables et des caracteres accentues
            # S'assurer que les variables et les caractÃ¨res accentuÃ©s sont bien liÃ©s (proches l'un de l'autre)
            if ($line -match $variablePattern -and $line -match $accentedPattern) {
                # VÃ©rifier si les variables et les caractÃ¨res accentuÃ©s sont proches l'un de l'autre
                $variablePositions = [regex]::Matches($line, $variablePattern) | ForEach-Object { $_.Index }
                $accentedPositions = [regex]::Matches($line, $accentedPattern) | ForEach-Object { $_.Index }

                $closeProximity = $false
                foreach ($varPos in $variablePositions) {
                    foreach ($accPos in $accentedPositions) {
                        if ([Math]::Abs($varPos - $accPos) -lt 20) {
                            # 20 caractÃ¨res de proximitÃ©
                            $closeProximity = $true
                            break
                        }
                    }
                    if ($closeProximity) { break }
                }

                if (-not $closeProximity) { continue }
                # Extraire toutes les references de variables
                $variableMatches = [regex]::Matches($line, $variablePattern)
                $variables = $variableMatches | ForEach-Object { $_.Value }

                $results += [PSCustomObject]@{
                    FilePath   = $FilePath
                    LineNumber = $lineNumber
                    Line       = $line
                    Variables  = $variables -join ", "
                    Encoding   = $encodingInfo.Encoding
                    HasBOM     = $encodingInfo.HasBOM
                    Risk       = if ($encodingInfo.HasBOM) { "Faible" } else { "Eleve" }
                }
            }
        }

        return $results
    } catch {
        throw "Erreur lors de l'analyse du fichier '$FilePath': $_"
    }
}

# Fonction principale
function Start-Detection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    try {
        # Verifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            throw "Le chemin '$Path' n'existe pas."
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
            $fileResults = Find-VariableReferences -FilePath $file.FullName
            $results += $fileResults
        }

        return $results
    } catch {
        throw "Erreur lors de la detection des references de variables: $_"
    }
}

# Executer la detection
$results = Start-Detection -Path $Path -Recurse:$Recurse

# Afficher les resultats
if ($results.Count -eq 0) {
    Write-Host "Aucune reference de variable dans des chaines accentuees n'a ete detectee." -ForegroundColor Green
} else {
    Write-Host "$($results.Count) references de variables potentiellement problematiques detectees:" -ForegroundColor Yellow

    foreach ($result in $results) {
        Write-Host "`nFichier: $($result.FilePath)" -ForegroundColor Cyan
        Write-Host "Ligne $($result.LineNumber): $($result.Line)" -ForegroundColor White
        Write-Host "Variables: $($result.Variables)" -ForegroundColor Yellow
        Write-Host "Encodage: $($result.Encoding)" -ForegroundColor Gray
        Write-Host "Niveau de risque: $($result.Risk)" -ForegroundColor $(if ($result.Risk -eq "Eleve") { "Red" } else { "Green" })
    }
}
