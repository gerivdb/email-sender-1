# Fix-Encoding.ps1
# Script pour corriger l'encodage des fichiers de test

param (
    [Parameter(Mandatory = $false)]
    [string]$FolderPath = ".\tests",
    
    [Parameter(Mandatory = $false)]
    [switch]$Recursive,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour corriger l'encodage d'un fichier
function Repair-FileEncoding {
    param (
        [string]$FilePath,
        [switch]$WhatIf
    )
    
    try {
        # Lire le contenu du fichier avec l'encodage actuel
        $content = Get-Content -Path $FilePath -Raw
        
        # Corriger les caractÃ¨res mal encodÃ©s
        $correctedContent = $content -replace "ÃƒÂ©", "Ã©" `
                                     -replace "ÃƒÂ¨", "Ã¨" `
                                     -replace "Ãƒ ", "Ã " `
                                     -replace "ÃƒÂ®", "Ã®" `
                                     -replace "ÃƒÂ´", "Ã´" `
                                     -replace "ÃƒÂ»", "Ã»" `
                                     -replace "ÃƒÂ§", "Ã§" `
                                     -replace "Ãƒâ€°", "Ã‰" `
                                     -replace "ÃƒË†", "Ãˆ" `
                                     -replace "Ãƒâ‚¬", "Ã€" `
                                     -replace "ÃƒÅ½", "ÃŽ" `
                                     -replace "Ãƒ"", "Ã”" `
                                     -replace "Ãƒâ€º", "Ã›" `
                                     -replace "Ãƒâ€¡", "Ã‡"
        
        # VÃ©rifier si des modifications ont Ã©tÃ© apportÃ©es
        if ($content -ne $correctedContent) {
            if ($WhatIf) {
                Write-Output "Le fichier $FilePath serait corrigÃ©."
            }
            else {
                # Sauvegarder le fichier avec l'encodage UTF-8 avec BOM
                $utf8WithBom = New-Object System.Text.UTF8Encoding $true
                [System.IO.File]::WriteAllText($FilePath, $correctedContent, $utf8WithBom)
                Write-Output "Le fichier $FilePath a Ã©tÃ© corrigÃ©."
            }
            return $true
        }
        else {
            Write-Output "Le fichier $FilePath ne nÃ©cessite pas de correction."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la correction du fichier $FilePath : $_"
        return $false
    }
}

# Fonction pour traiter un dossier
function Process-Folder {
    param (
        [string]$FolderPath,
        [switch]$Recursive,
        [switch]$WhatIf
    )
    
    # VÃ©rifier que le dossier existe
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier $FolderPath n'existe pas."
        return
    }
    
    # Obtenir la liste des fichiers
    $searchOption = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
    $files = [System.IO.Directory]::GetFiles($FolderPath, "*.txt", [System.IO.SearchOption]::$searchOption)
    $files += [System.IO.Directory]::GetFiles($FolderPath, "*.md", [System.IO.SearchOption]::$searchOption)
    $files += [System.IO.Directory]::GetFiles($FolderPath, "*.json", [System.IO.SearchOption]::$searchOption)
    
    # Traiter chaque fichier
    $correctedCount = 0
    foreach ($file in $files) {
        $corrected = Repair-FileEncoding -FilePath $file -WhatIf:$WhatIf
        if ($corrected) {
            $correctedCount++
        }
    }
    
    # Afficher le rÃ©sumÃ©
    Write-Output ""
    if ($WhatIf) {
        Write-Output "$correctedCount fichiers seraient corrigÃ©s."
    }
    else {
        Write-Output "$correctedCount fichiers ont Ã©tÃ© corrigÃ©s."
    }
}

# Traiter le dossier spÃ©cifiÃ©
Process-Folder -FolderPath $FolderPath -Recursive:$Recursive -WhatIf:$WhatIf
