<#
.SYNOPSIS
    DÃ©tecte les rÃ©fÃ©rences de variables dans les chaÃ®nes accentuÃ©es qui peuvent causer des problÃ¨mes.

.DESCRIPTION
    Ce script analyse les fichiers PowerShell pour dÃ©tecter les rÃ©fÃ©rences de variables ($var) 
    dans des chaÃ®nes contenant des caractÃ¨res accentuÃ©s, ce qui peut causer des problÃ¨mes 
    d'interprÃ©tation en fonction de l'encodage du fichier.

.PARAMETER Path
    Chemin du fichier ou du rÃ©pertoire Ã  analyser. Par dÃ©faut, analyse le rÃ©pertoire courant.

.PARAMETER Recurse
    Indique si l'analyse doit Ãªtre rÃ©cursive dans les sous-rÃ©pertoires.

.PARAMETER OutputFormat
    Format de sortie des rÃ©sultats. Valeurs possibles : "Text", "Object", "Json".
    Par dÃ©faut : "Text".

.EXAMPLE
    .\Detect-VariableReferencesInAccentedStrings-v2.ps1 -Path .\scripts -Recurse

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
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
        
        # VÃ©rifier les diffÃ©rents BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return @{
                Encoding = "UTF-8 with BOM"
                HasBOM = $true
            }
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            return @{
                Encoding = "UTF-16 BE"
                HasBOM = $true
            }
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            return @{
                Encoding = "UTF-16 LE"
                HasBOM = $true
            }
        }
        else {
            # Pas de BOM dÃ©tectÃ©, essayer de dÃ©terminer l'encodage
            return @{
                Encoding = "Unknown (possibly UTF-8 without BOM or ANSI)"
                HasBOM = $false
            }
        }
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection de l'encodage du fichier '$FilePath': $_"
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
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return @()
        }
        
        # VÃ©rifier l'encodage du fichier
        $encodingInfo = Test-FileEncoding -FilePath $FilePath
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # DÃ©finir les patterns de recherche pour les caractÃ¨res accentuÃ©s
        # Utiliser une liste explicite de caractÃ¨res accentuÃ©s pour Ã©viter les problÃ¨mes d'encodage
        $accentedChars = @('Ã ', 'Ã¡', 'Ã¢', 'Ã¤', 'Ã¦', 'Ã£', 'Ã¥', 'Ä', 'Ã¨', 'Ã©', 'Ãª', 'Ã«', 'Ä“', 'Ä—', 'Ä™', 
                          'Ã®', 'Ã¯', 'Ã­', 'Ä«', 'Ä¯', 'Ã¬', 'Ã´', 'Ã¶', 'Ã²', 'Ã³', 'Å“', 'Ã¸', 'Å', 'Ãµ', 
                          'Ã»', 'Ã¼', 'Ã¹', 'Ãº', 'Å«', 'Ã¿', 'Ã§', 'Ã±',
                          'Ã€', 'Ã', 'Ã‚', 'Ã„', 'Ã†', 'Ãƒ', 'Ã…', 'Ä€', 'Ãˆ', 'Ã‰', 'ÃŠ', 'Ã‹', 'Ä’', 'Ä–', 'Ä˜',
                          'ÃŽ', 'Ã', 'Ã', 'Äª', 'Ä®', 'ÃŒ', 'Ã”', 'Ã–', 'Ã’', 'Ã“', 'Å’', 'Ã˜', 'ÅŒ', 'Ã•',
                          'Ã›', 'Ãœ', 'Ã™', 'Ãš', 'Åª', 'Å¸', 'Ã‡', 'Ã‘')
        
        # Pattern pour les rÃ©fÃ©rences de variables
        $variableReferencePattern = '\$[a-zA-Z0-9_]+'
        
        # Rechercher les lignes contenant Ã  la fois des caractÃ¨res accentuÃ©s et des rÃ©fÃ©rences de variables
        $results = @()
        $lineNumber = 0
        
        foreach ($line in $content -split "`r`n|`r|`n") {
            $lineNumber++
            
            # VÃ©rifier si la ligne contient des rÃ©fÃ©rences de variables
            if ($line -match $variableReferencePattern) {
                # Extraire toutes les rÃ©fÃ©rences de variables
                $variableMatches = [regex]::Matches($line, $variableReferencePattern)
                $variables = $variableMatches | ForEach-Object { $_.Value }
                
                # VÃ©rifier si la ligne contient des caractÃ¨res accentuÃ©s
                $containsAccentedChar = $false
                $foundAccentedChars = @()
                
                foreach ($char in $accentedChars) {
                    if ($line.Contains($char)) {
                        $containsAccentedChar = $true
                        $foundAccentedChars += $char
                    }
                }
                
                if ($containsAccentedChar) {
                    # VÃ©rifier si les variables sont Ã  proximitÃ© des caractÃ¨res accentuÃ©s
                    $potentialIssue = $false
                    $closeVariables = @()
                    
                    foreach ($var in $variables) {
                        foreach ($char in $foundAccentedChars) {
                            # VÃ©rifier si le caractÃ¨re accentuÃ© est Ã  moins de 20 caractÃ¨res de la variable
                            $varIndex = $line.IndexOf($var)
                            $charIndex = $line.IndexOf($char)
                            
                            if ([Math]::Abs($varIndex - $charIndex) -lt 20) {
                                $potentialIssue = $true
                                $closeVariables += $var
                                break
                            }
                        }
                    }
                    
                    if ($potentialIssue) {
                        $results += [PSCustomObject]@{
                            FilePath = $FilePath
                            LineNumber = $lineNumber
                            Line = $line
                            Variables = ($closeVariables | Select-Object -Unique) -join ", "
                            AccentedChars = ($foundAccentedChars | Select-Object -Unique) -join ", "
                            Encoding = $encodingInfo.Encoding
                            HasBOM = $encodingInfo.HasBOM
                            Risk = if ($encodingInfo.HasBOM) { "Faible" } else { "Eleve" }
                        }
                    }
                }
            }
        }
        
        return $results
    }
    catch {
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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return @()
        }
        
        # Obtenir la liste des fichiers PowerShell
        $getChildItemParams = @{
            Path = $Path
            Filter = "*.ps1"
            File = $true
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
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection des rÃ©fÃ©rences de variables dans les chaÃ®nes accentuÃ©es: $_"
        return @()
    }
}

# ExÃ©cuter la dÃ©tection
$results = Start-Detection -Path $Path -Recurse:$Recurse

# Afficher les rÃ©sultats selon le format demandÃ©
switch ($OutputFormat) {
    "Text" {
        if ($results.Count -eq 0) {
            Write-Host "Aucune rÃ©fÃ©rence de variable dans des chaÃ®nes accentuÃ©es n'a Ã©tÃ© dÃ©tectÃ©e." -ForegroundColor Green
        }
        else {
            Write-Host "$($results.Count) rÃ©fÃ©rences de variables potentiellement problÃ©matiques dÃ©tectÃ©es:" -ForegroundColor Yellow
            
            foreach ($result in $results) {
                Write-Host "`nFichier: $($result.FilePath)" -ForegroundColor Cyan
                Write-Host "Ligne $($result.LineNumber): $($result.Line)" -ForegroundColor White
                Write-Host "Variables: $($result.Variables)" -ForegroundColor Yellow
                Write-Host "CaractÃ¨res accentuÃ©s: $($result.AccentedChars)" -ForegroundColor Magenta
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
