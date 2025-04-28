<#
.SYNOPSIS
    Detecte les references de variables dans les chaines accentuees qui peuvent causer des problemes.

.DESCRIPTION
    Ce script analyse les fichiers PowerShell pour detecter les references de variables ($var) 
    dans des chaines contenant des caracteres accentues, ce qui peut causer des problemes 
    d'interpretation en fonction de l'encodage du fichier.

.PARAMETER Path
    Chemin du fichier ou du repertoire a analyser. Par defaut, analyse le repertoire courant.

.PARAMETER Recurse
    Indique si l'analyse doit etre recursive dans les sous-repertoires.

.PARAMETER OutputFormat
    Format de sortie des resultats. Valeurs possibles : "Text", "Object", "Json".
    Par defaut : "Text".

.EXAMPLE
    .\Detect-VariableReferencesInAccentedStrings-v3.ps1 -Path .\development\scripts -Recurse

.NOTES
    Auteur: Systeme d'analyse d'erreurs
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
        
        # Verifier les differents BOM
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
            # Pas de BOM detecte, essayer de determiner l'encodage
            return @{
                Encoding = "Unknown (possibly UTF-8 without BOM or ANSI)"
                HasBOM = $false
            }
        }
    }
    catch {
        Write-Error "Erreur lors de la detection de l'encodage du fichier '$FilePath': $_"
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
        # Verifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return @()
        }
        
        # Verifier l'encodage du fichier
        $encodingInfo = Test-FileEncoding -FilePath $FilePath
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Pattern pour les references de variables
        $variableReferencePattern = '\$[a-zA-Z0-9_]+'
        
        # Rechercher les lignes contenant a la fois des caracteres accentues et des references de variables
        $results = @()
        $lineNumber = 0
        
        foreach ($line in $content -split "`r`n|`r|`n") {
            $lineNumber++
            
            # Verifier si la ligne contient des references de variables
            if ($line -match $variableReferencePattern) {
                # Extraire toutes les references de variables
                $variableMatches = [regex]::Matches($line, $variableReferencePattern)
                $variables = $variableMatches | ForEach-Object { $_.Value }
                
                # Verifier si la ligne contient des caracteres accentues
                # Utiliser une expression reguliere pour les caracteres accentues
                if ($line -match '[àáâäæãåāèéêëēėęîïíīįìôöòóœøōõûüùúūÿçñÀÁÂÄÆÃÅĀÈÉÊËĒĖĘÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪŸÇÑ]') {
                    $results += [PSCustomObject]@{
                        FilePath = $FilePath
                        LineNumber = $lineNumber
                        Line = $line
                        Variables = $variables -join ", "
                        Encoding = $encodingInfo.Encoding
                        HasBOM = $encodingInfo.HasBOM
                        Risk = if ($encodingInfo.HasBOM) { "Faible" } else { "Eleve" }
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
        # Verifier si le chemin existe
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
        Write-Error "Erreur lors de la detection des references de variables dans les chaines accentuees: $_"
        return @()
    }
}

# Executer la detection
$results = Start-Detection -Path $Path -Recurse:$Recurse

# Afficher les resultats selon le format demande
switch ($OutputFormat) {
    "Text" {
        if ($results.Count -eq 0) {
            Write-Host "Aucune reference de variable dans des chaines accentuees n'a ete detectee." -ForegroundColor Green
        }
        else {
            Write-Host "$($results.Count) references de variables potentiellement problematiques detectees:" -ForegroundColor Yellow
            
            foreach ($result in $results) {
                Write-Host "`nFichier: $($result.FilePath)" -ForegroundColor Cyan
                Write-Host "Ligne $($result.LineNumber): $($result.Line)" -ForegroundColor White
                Write-Host "Variables: $($result.Variables)" -ForegroundColor Yellow
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
