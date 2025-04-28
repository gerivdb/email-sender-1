# Update-TerminalTests.ps1
# Script pour mettre Ã  jour les tests unitaires pour la compatibilitÃ© multi-terminaux

param (
    [Parameter(Mandatory = $false)]
    [string]$TestsFolder = ".\development\testing\tests",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour dÃ©tecter le type de terminal
function Get-TerminalType {
    # VÃ©rifier si nous sommes dans PowerShell Core (qui fonctionne sur diffÃ©rentes plateformes)
    if ($PSVersionTable.PSEdition -eq "Core") {
        if ($IsWindows) {
            return "PowerShell Core (Windows)"
        }
        elseif ($IsLinux) {
            return "PowerShell Core (Linux)"
        }
        elseif ($IsMacOS) {
            return "PowerShell Core (macOS)"
        }
        else {
            return "PowerShell Core (Autre)"
        }
    }
    else {
        # PowerShell Windows classique
        return "Windows PowerShell"
    }
}

# Fonction pour normaliser les chemins selon le terminal
function Get-NormalizedPath {
    param (
        [string]$Path,
        [string]$TerminalType
    )
    
    # Normaliser les chemins selon le terminal
    switch -Regex ($TerminalType) {
        "Windows" {
            # Utiliser des backslashes pour Windows
            $normalizedPath = $Path -replace "/", "\"
        }
        "Linux|macOS" {
            # Utiliser des forward slashes pour Linux/macOS
            $normalizedPath = $Path -replace "\\", "/"
        }
        default {
            # Par dÃ©faut, utiliser le chemin tel quel
            $normalizedPath = $Path
        }
    }
    
    return $normalizedPath
}

# Fonction pour mettre Ã  jour les tests
function Update-Tests {
    param (
        [string]$TestsFolder,
        [switch]$WhatIf
    )
    
    # VÃ©rifier que le dossier de tests existe
    if (-not (Test-Path -Path $TestsFolder -PathType Container)) {
        Write-Error "Le dossier de tests $TestsFolder n'existe pas."
        return
    }
    
    # Obtenir le type de terminal
    $terminalType = Get-TerminalType
    Write-Output "Type de terminal dÃ©tectÃ© : $terminalType"
    
    # Obtenir la liste des fichiers de test
    $testFiles = Get-ChildItem -Path $TestsFolder -Filter "*.txt" -Recurse
    
    # Mettre Ã  jour chaque fichier de test
    $updatedCount = 0
    foreach ($file in $testFiles) {
        try {
            # Lire le contenu du fichier
            $content = Get-Content -Path $file.FullName -Raw
            
            # Rechercher les chemins Ã  normaliser
            $pattern = '(["''])((?:[a-zA-Z]:\\|\.\\|\.\.\\|\/|\.\/|\.\.\/)[^"'']*)(["''])'
            $matches = [regex]::Matches($content, $pattern)
            
            if ($matches.Count -gt 0) {
                $updatedContent = $content
                
                foreach ($match in $matches) {
                    $originalPath = $match.Groups[2].Value
                    $normalizedPath = Get-NormalizedPath -Path $originalPath -TerminalType $terminalType
                    
                    if ($originalPath -ne $normalizedPath) {
                        $updatedContent = $updatedContent.Replace($match.Value, "$($match.Groups[1].Value)$normalizedPath$($match.Groups[3].Value)")
                    }
                }
                
                if ($content -ne $updatedContent) {
                    if ($WhatIf) {
                        Write-Output "Le fichier $($file.FullName) serait mis Ã  jour."
                    }
                    else {
                        # Sauvegarder le fichier avec l'encodage UTF-8 avec BOM
                        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
                        [System.IO.File]::WriteAllText($file.FullName, $updatedContent, $utf8WithBom)
                        Write-Output "Le fichier $($file.FullName) a Ã©tÃ© mis Ã  jour."
                    }
                    $updatedCount++
                }
                else {
                    Write-Output "Le fichier $($file.FullName) ne nÃ©cessite pas de mise Ã  jour."
                }
            }
            else {
                Write-Output "Aucun chemin Ã  normaliser dans le fichier $($file.FullName)."
            }
        }
        catch {
            Write-Error "Erreur lors de la mise Ã  jour du fichier $($file.FullName) : $_"
        }
    }
    
    # Afficher le rÃ©sumÃ©
    Write-Output ""
    if ($WhatIf) {
        Write-Output "$updatedCount fichiers seraient mis Ã  jour."
    }
    else {
        Write-Output "$updatedCount fichiers ont Ã©tÃ© mis Ã  jour."
    }
}

# Mettre Ã  jour les tests
Update-Tests -TestsFolder $TestsFolder -WhatIf:$WhatIf
