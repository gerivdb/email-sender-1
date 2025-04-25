<#
.SYNOPSIS
    Standardise les chemins dans les scripts PowerShell.
.DESCRIPTION
    Ce script standardise les chemins dans les scripts PowerShell pour améliorer
    la compatibilité entre différents environnements.
.EXAMPLE
    . .\PathStandardizer.ps1
    Standardize-PathsInScript -Path "C:\path\to\script.ps1" -CreateBackup
#>

function Standardize-PathsInScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    process {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "Le fichier '$Path' n'existe pas."
            return $false
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $Path
        }
        
        # Créer une sauvegarde si demandé
        if ($CreateBackup) {
            $backupPath = "$Path.bak"
            Copy-Item -Path $Path -Destination $backupPath -Force
            Write-Verbose "Sauvegarde créée: $backupPath"
        }
        
        # Lire le contenu du script
        $content = Get-Content -Path $Path -Raw
        
        # Définir les modèles de recherche et de remplacement
        $patterns = @(
            # Remplacer les chemins codés en dur avec des barres obliques inversées par Join-Path
            @{
                Pattern = '([''"])([A-Za-z]:\\[^''"\r\n]+)([''"])'
                Replacement = {
                    param($match)
                    $quote = $match.Groups[1].Value
                    $path = $match.Groups[2].Value
                    
                    # Diviser le chemin en segments
                    $segments = $path -split '\\'
                    $drive = $segments[0]
                    $remainingSegments = $segments[1..($segments.Length - 1)]
                    
                    # Construire l'expression Join-Path
                    if ($remainingSegments.Count -eq 1) {
                        "$quote(Join-Path -Path $drive -ChildPath $($quote)$($remainingSegments[0])$($quote))$quote"
                    }
                    else {
                        $joinPathExpr = "(Join-Path -Path $drive"
                        foreach ($segment in $remainingSegments) {
                            $joinPathExpr += " -ChildPath $($quote)$segment$($quote)"
                        }
                        $joinPathExpr += ")"
                        "$quote$joinPathExpr$quote"
                    }
                }
                Description = "Remplacer les chemins codés en dur par Join-Path"
            },
            
            # Remplacer les chemins relatifs avec des barres obliques inversées par Join-Path
            @{
                Pattern = '([''"])(\.\.[\\\/][^''"\r\n]+)([''"])'
                Replacement = {
                    param($match)
                    $quote = $match.Groups[1].Value
                    $path = $match.Groups[2].Value
                    
                    # Diviser le chemin en segments
                    $segments = $path -split '[\\\/]'
                    
                    # Construire l'expression Join-Path
                    if ($segments.Count -eq 2) {
                        "$quote(Join-Path -Path $($quote)$($segments[0])$($quote) -ChildPath $($quote)$($segments[1])$($quote))$quote"
                    }
                    else {
                        $joinPathExpr = "(Join-Path -Path $($quote)$($segments[0])$($quote)"
                        foreach ($segment in $segments[1..($segments.Length - 1)]) {
                            $joinPathExpr += " -ChildPath $($quote)$segment$($quote)"
                        }
                        $joinPathExpr += ")"
                        "$quote$joinPathExpr$quote"
                    }
                }
                Description = "Remplacer les chemins relatifs par Join-Path"
            },
            
            # Remplacer les concaténations de chemins par Join-Path
            @{
                Pattern = '([''"][^''"\r\n]*[''"])\s*\+\s*[''"][\\\/]?([^''"\r\n]*)[''"]'
                Replacement = '(Join-Path -Path $1 -ChildPath "$2")'
                Description = "Remplacer les concaténations de chemins par Join-Path"
            },
            
            # Remplacer les chemins avec des variables d'environnement par [System.Environment]::GetFolderPath
            @{
                Pattern = '\$env:([A-Za-z0-9_]+)'
                Replacement = {
                    param($match)
                    $envVar = $match.Groups[1].Value
                    
                    # Mapper les variables d'environnement courantes aux dossiers spéciaux
                    switch ($envVar) {
                        "USERPROFILE" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)" }
                        "APPDATA" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)" }
                        "LOCALAPPDATA" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)" }
                        "TEMP" { "[System.IO.Path]::GetTempPath()" }
                        "TMP" { "[System.IO.Path]::GetTempPath()" }
                        "PROGRAMFILES" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles)" }
                        "PROGRAMFILES(X86)" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86)" }
                        "PROGRAMDATA" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData)" }
                        "PUBLIC" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonDocuments)" }
                        "DOCUMENTS" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)" }
                        "DESKTOP" { "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)" }
                        default { "`$env:$envVar" }
                    }
                }
                Description = "Remplacer les variables d'environnement par GetFolderPath"
            },
            
            # Remplacer les séparateurs de chemin codés en dur par [System.IO.Path]::DirectorySeparatorChar
            @{
                Pattern = '([''"])\\([''"])'
                Replacement = '[System.IO.Path]::DirectorySeparatorChar'
                Description = "Remplacer les séparateurs de chemin codés en dur"
            },
            
            # Remplacer les appels à Test-Path sans -PathType
            @{
                Pattern = 'Test-Path\s+([^-\r\n]+)(?!\s+-PathType)'
                Replacement = 'Test-Path -Path $1 -PathType Any'
                Description = "Ajouter -PathType à Test-Path"
            }
        )
        
        # Appliquer les modèles
        $modifiedContent = $content
        $modifications = @()
        
        foreach ($pattern in $patterns) {
            $regex = [regex]$pattern.Pattern
            
            # Trouver toutes les correspondances
            $matches = $regex.Matches($modifiedContent)
            
            if ($matches.Count -gt 0) {
                # Appliquer les remplacements en commençant par la fin pour éviter les décalages
                for ($i = $matches.Count - 1; $i -ge 0; $i--) {
                    $match = $matches[$i]
                    
                    # Déterminer le texte de remplacement
                    $replacement = if ($pattern.Replacement -is [scriptblock]) {
                        & $pattern.Replacement $match
                    }
                    else {
                        $regex.Replace($match.Value, $pattern.Replacement)
                    }
                    
                    # Appliquer le remplacement
                    $modifiedContent = $modifiedContent.Substring(0, $match.Index) + $replacement + $modifiedContent.Substring($match.Index + $match.Length)
                    
                    # Enregistrer la modification
                    $modifications += [PSCustomObject]@{
                        Pattern = $pattern.Description
                        Original = $match.Value
                        Replacement = $replacement
                    }
                }
            }
        }
        
        # Ajouter une fonction d'aide pour la gestion des chemins si des modifications ont été apportées
        if ($modifications.Count -gt 0) {
            $pathHelperFunction = @"

# Fonction d'aide pour la gestion des chemins
function Get-NormalizedPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, Position = 0)]
        [string]`$Path,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$Resolve,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$AsRelativePath,
        
        [Parameter(Mandatory = `$false)]
        [string]`$BasePath = ""
    )
    
    # Normaliser les séparateurs de chemin
    `$normalizedPath = `$Path.Replace('\', [System.IO.Path]::DirectorySeparatorChar).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    
    # Résoudre le chemin si demandé
    if (`$Resolve) {
        try {
            `$normalizedPath = Resolve-Path -Path `$normalizedPath -ErrorAction Stop | Select-Object -ExpandProperty Path
        }
        catch {
            Write-Warning "Impossible de résoudre le chemin '`$Path': `$_"
        }
    }
    
    # Convertir en chemin relatif si demandé
    if (`$AsRelativePath) {
        `$basePathToUse = if ([string]::IsNullOrEmpty(`$BasePath)) {
            (Get-Location).Path
        }
        else {
            `$BasePath
        }
        
        try {
            `$basePathResolved = Resolve-Path -Path `$basePathToUse -ErrorAction Stop | Select-Object -ExpandProperty Path
            `$normalizedPathResolved = if (`$Resolve) { `$normalizedPath } else { Resolve-Path -Path `$normalizedPath -ErrorAction Stop | Select-Object -ExpandProperty Path }
            
            # Obtenir le chemin relatif
            `$normalizedPath = [System.IO.Path]::GetRelativePath(`$basePathResolved, `$normalizedPathResolved)
        }
        catch {
            Write-Warning "Impossible de convertir en chemin relatif: `$_"
        }
    }
    
    return `$normalizedPath
}

"@
            
            # Trouver l'endroit où insérer la fonction d'aide
            $insertPosition = 0
            
            # Chercher après les commentaires initiaux, les déclarations param et les fonctions existantes
            if ($modifiedContent -match '(?s)^(#[^\n]*\n)+\s*(param\s*\([^\)]+\))?\s*(\$ErrorActionPreference\s*=\s*[\'"]Stop[\'"])?\s*') {
                $insertPosition = $matches[0].Length
            }
            
            # Insérer la fonction d'aide
            $modifiedContent = $modifiedContent.Substring(0, $insertPosition) + $pathHelperFunction + $modifiedContent.Substring($insertPosition)
            
            $modifications += [PSCustomObject]@{
                Pattern = "Ajout de la fonction d'aide Get-NormalizedPath"
                Original = ""
                Replacement = $pathHelperFunction
            }
        }
        
        # Appliquer les modifications si ce n'est pas un test
        if (-not $WhatIf) {
            if ($modifications.Count -gt 0) {
                Set-Content -Path $OutputPath -Value $modifiedContent
                Write-Verbose "Script modifié avec $($modifications.Count) standardisations de chemins."
                return $true
            }
            else {
                Write-Verbose "Aucune modification nécessaire pour le script."
                return $false
            }
        }
        else {
            # Afficher les modifications prévues
            Write-Host "Modifications prévues pour le script '$Path':"
            
            foreach ($mod in $modifications) {
                Write-Host "- $($mod.Pattern)"
                Write-Host "  Original: $($mod.Original)"
                Write-Host "  Remplacement: $($mod.Replacement)"
                Write-Host ""
            }
            
            return $modifications.Count -gt 0
        }
    }
}

function Standardize-PathsInDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.ps1",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Le répertoire '$Path' n'existe pas."
        return $null
    }
    
    # Obtenir la liste des fichiers à traiter
    $files = Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse
    
    $results = @{
        TotalFiles = $files.Count
        ModifiedFiles = 0
        SkippedFiles = 0
        FailedFiles = 0
        Details = @()
    }
    
    foreach ($file in $files) {
        Write-Verbose "Traitement du fichier: $($file.FullName)"
        
        try {
            # Standardiser les chemins
            $success = Standardize-PathsInScript -Path $file.FullName -CreateBackup:$CreateBackup -WhatIf:$WhatIf
            
            if ($success -and -not $WhatIf) {
                $results.ModifiedFiles++
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "Modified"
                }
            }
            elseif ($WhatIf) {
                if ($success) {
                    $results.Details += [PSCustomObject]@{
                        FilePath = $file.FullName
                        Status = "WhatIf"
                    }
                }
                else {
                    $results.SkippedFiles++
                    $results.Details += [PSCustomObject]@{
                        FilePath = $file.FullName
                        Status = "Skipped"
                        Reason = "Aucune modification nécessaire"
                    }
                }
            }
            elseif (-not $success) {
                $results.SkippedFiles++
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "Skipped"
                    Reason = "Aucune modification nécessaire"
                }
            }
        }
        catch {
            $results.FailedFiles++
            $results.Details += [PSCustomObject]@{
                FilePath = $file.FullName
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
    }
    
    return [PSCustomObject]$results
}

# Exporter les fonctions
Export-ModuleMember -Function Standardize-PathsInScript, Standardize-PathsInDirectory
