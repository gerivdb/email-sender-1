# Fix-Encoding.ps1
# Script pour corriger l'encodage des fichiers de test

param (
    [Parameter(Mandatory = $false)]
    [string]$FolderPath = ".\development\testing\tests",
    
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
        
        # Corriger les caractÃƒÂ¨res mal encodÃƒÂ©s
        $correctedContent = $content -replace "ÃƒÆ’Ã‚Â©", "ÃƒÂ©" `
                                     -replace "ÃƒÆ’Ã‚Â¨", "ÃƒÂ¨" `
                                     -replace "ÃƒÆ’ ", "ÃƒÂ " `
                                     -replace "ÃƒÆ’Ã‚Â®", "ÃƒÂ®" `
                                     -replace "ÃƒÆ’Ã‚Â´", "ÃƒÂ´" `
                                     -replace "ÃƒÆ’Ã‚Â»", "ÃƒÂ»" `
                                     -replace "ÃƒÆ’Ã‚Â§", "ÃƒÂ§" `
                                     -replace "ÃƒÆ’Ã¢â‚¬Â°", "Ãƒâ€°" `
                                     -replace "ÃƒÆ’Ã‹â€ ", "ÃƒË†" `
                                     -replace "ÃƒÆ’Ã¢â€šÂ¬", "Ãƒâ‚¬" `
                                     -replace "ÃƒÆ’Ã…Â½", "ÃƒÅ½" `
                                     -replace "ÃƒÆ’"", "Ãƒâ€" `
                                     -replace "ÃƒÆ’Ã¢â‚¬Âº", "Ãƒâ€º" `
                                     -replace "ÃƒÆ’Ã¢â‚¬Â¡", "Ãƒâ€¡"
        
        # VÃƒÂ©rifier si des modifications ont ÃƒÂ©tÃƒÂ© apportÃƒÂ©es
        if ($content -ne $correctedContent) {
            if ($WhatIf) {
                Write-Output "Le fichier $FilePath serait corrigÃƒÂ©."
            }
            else {
                # Sauvegarder le fichier avec l'encodage UTF-8 avec BOM
                $utf8WithBom = New-Object System.Text.UTF8Encoding $true
                [System.IO.File]::WriteAllText($FilePath, $correctedContent, $utf8WithBom)
                Write-Output "Le fichier $FilePath a ÃƒÂ©tÃƒÂ© corrigÃƒÂ©."
            }
            return $true
        }
        else {
            Write-Output "Le fichier $FilePath ne nÃƒÂ©cessite pas de correction."
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
    
    # VÃƒÂ©rifier que le dossier existe
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
    
    # Afficher le rÃƒÂ©sumÃƒÂ©
    Write-Output ""
    if ($WhatIf) {
        Write-Output "$correctedCount fichiers seraient corrigÃƒÂ©s."
    }
    else {
        Write-Output "$correctedCount fichiers ont ÃƒÂ©tÃƒÂ© corrigÃƒÂ©s."
    }
}

# Traiter le dossier spÃƒÂ©cifiÃƒÂ©
Process-Folder -FolderPath $FolderPath -Recursive:$Recursive -WhatIf:$WhatIf
