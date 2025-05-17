# Move-VisualizationFiles.ps1
# Script pour déplacer les fichiers de visualisation de la racine vers le dossier src
# Version: 1.0
# Date: 2025-05-17

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\visualization",
    
    [Parameter(Mandatory = $false)]
    [string]$DestinationPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\visualization\src",
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\reports\visualization-files-moved.md",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $color
}

# Fonction pour déplacer les fichiers
function Move-Files {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [array]$ExcludeFolders = @("coverage", "data", "node_modules", "scripts", "test", "tests", "src"),
        [array]$ExcludeFiles = @("package.json", "package-lock.json", "babel.config.js", "jest.config.js")
    )
    
    # Vérifier que les chemins existent
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Log "Le chemin source n'existe pas: $SourcePath" -Level "Error"
        return $null
    }
    
    if (-not (Test-Path -Path $DestinationPath)) {
        Write-Log "Création du dossier de destination: $DestinationPath" -Level "Info"
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }
    
    # Obtenir la liste des fichiers à la racine (en excluant les dossiers et certains fichiers)
    $files = Get-ChildItem -Path $SourcePath -File | Where-Object { 
        $_.DirectoryName -eq $SourcePath -and 
        $ExcludeFiles -notcontains $_.Name
    }
    
    if ($files.Count -eq 0) {
        Write-Log "Aucun fichier à déplacer trouvé à la racine du dossier: $SourcePath" -Level "Warning"
        return $null
    }
    
    Write-Log "Nombre de fichiers à déplacer: $($files.Count)" -Level "Info"
    
    $movedFiles = @()
    
    # Déplacer chaque fichier
    foreach ($file in $files) {
        $destinationFile = Join-Path -Path $DestinationPath -ChildPath $file.Name
        
        try {
            Move-Item -Path $file.FullName -Destination $destinationFile -Force:$Force
            Write-Log "Fichier déplacé: $($file.Name)" -Level "Success"
            
            $movedFiles += [PSCustomObject]@{
                Name = $file.Name
                OriginalPath = $file.FullName
                NewPath = $destinationFile
                Size = $file.Length
                LastModified = $file.LastWriteTime
                Extension = $file.Extension
            }
        } catch {
            Write-Log "Erreur lors du déplacement du fichier $($file.Name): $_" -Level "Error"
        }
    }
    
    return $movedFiles
}

# Fonction pour mettre à jour les références dans les fichiers HTML
function Update-HtmlReferences {
    param (
        [array]$MovedFiles,
        [string]$DestinationPath
    )
    
    $htmlFiles = $MovedFiles | Where-Object { $_.Extension -eq ".html" }
    $updatedFiles = @()
    
    foreach ($file in $htmlFiles) {
        $content = Get-Content -Path $file.NewPath -Raw
        $modified = $false
        
        # Mettre à jour les références aux fichiers JS
        $jsFiles = $MovedFiles | Where-Object { $_.Extension -eq ".js" }
        foreach ($jsFile in $jsFiles) {
            $jsFileName = Split-Path -Path $jsFile.OriginalPath -Leaf
            if ($content -match [regex]::Escape($jsFileName)) {
                $content = $content -replace "src=`"$jsFileName`"", "src=`"$jsFileName`""
                $modified = $true
                Write-Log "Référence mise à jour dans $($file.Name): $jsFileName" -Level "Info"
            }
        }
        
        # Mettre à jour les références aux fichiers CSS
        $cssFiles = $MovedFiles | Where-Object { $_.Extension -eq ".css" }
        foreach ($cssFile in $cssFiles) {
            $cssFileName = Split-Path -Path $cssFile.OriginalPath -Leaf
            if ($content -match [regex]::Escape($cssFileName)) {
                $content = $content -replace "href=`"$cssFileName`"", "href=`"$cssFileName`""
                $modified = $true
                Write-Log "Référence mise à jour dans $($file.Name): $cssFileName" -Level "Info"
            }
        }
        
        # Enregistrer le fichier si des modifications ont été apportées
        if ($modified) {
            Set-Content -Path $file.NewPath -Value $content
            Write-Log "Fichier mis à jour avec les nouvelles références: $($file.Name)" -Level "Success"
            $updatedFiles += $file.Name
        }
    }
    
    return $updatedFiles
}

# Fonction pour mettre à jour les références dans les fichiers JS
function Update-JsReferences {
    param (
        [array]$MovedFiles,
        [string]$DestinationPath
    )
    
    $jsFiles = $MovedFiles | Where-Object { $_.Extension -eq ".js" }
    $updatedFiles = @()
    
    foreach ($file in $jsFiles) {
        $content = Get-Content -Path $file.NewPath -Raw
        $modified = $false
        
        # Mettre à jour les imports relatifs
        $importMatches = [regex]::Matches($content, 'import\s+.*\s+from\s+[''"](\.[^''"]*)');
        foreach ($match in $importMatches) {
            $importPath = $match.Groups[1].Value
            $importFileName = Split-Path -Path $importPath -Leaf
            
            # Vérifier si le fichier importé a été déplacé
            $importedFile = $MovedFiles | Where-Object { $_.Name -eq $importFileName -or $_.Name -eq "$importFileName.js" }
            if ($importedFile) {
                $newImportPath = "./$importFileName"
                $content = $content -replace [regex]::Escape($importPath), $newImportPath
                $modified = $true
                Write-Log "Import mis à jour dans $($file.Name): $importPath -> $newImportPath" -Level "Info"
            }
        }
        
        # Enregistrer le fichier si des modifications ont été apportées
        if ($modified) {
            Set-Content -Path $file.NewPath -Value $content
            Write-Log "Fichier mis à jour avec les nouveaux imports: $($file.Name)" -Level "Success"
            $updatedFiles += $file.Name
        }
    }
    
    return $updatedFiles
}

# Fonction pour générer un rapport
function New-Report {
    param (
        [array]$MovedFiles,
        [array]$UpdatedHtmlFiles,
        [array]$UpdatedJsFiles,
        [string]$ReportPath
    )
    
    $reportContent = @"
# Rapport de déplacement des fichiers de visualisation
*Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## Résumé

- **Nombre de fichiers déplacés**: $($MovedFiles.Count)
- **Nombre de fichiers HTML avec références mises à jour**: $($UpdatedHtmlFiles.Count)
- **Nombre de fichiers JS avec imports mis à jour**: $($UpdatedJsFiles.Count)
- **Source**: `$SourcePath`
- **Destination**: `$DestinationPath`

## Liste des fichiers déplacés par type

### Fichiers HTML
"@
    
    $htmlFiles = $MovedFiles | Where-Object { $_.Extension -eq ".html" }
    foreach ($file in $htmlFiles) {
        $reportContent += "`n- $($file.Name) ($(($file.Size / 1KB).ToString("F2")) KB)"
    }
    
    $reportContent += @"

### Fichiers JavaScript
"@
    
    $jsFiles = $MovedFiles | Where-Object { $_.Extension -eq ".js" }
    foreach ($file in $jsFiles) {
        $reportContent += "`n- $($file.Name) ($(($file.Size / 1KB).ToString("F2")) KB)"
    }
    
    $reportContent += @"

### Fichiers CSS
"@
    
    $cssFiles = $MovedFiles | Where-Object { $_.Extension -eq ".css" }
    foreach ($file in $cssFiles) {
        $reportContent += "`n- $($file.Name) ($(($file.Size / 1KB).ToString("F2")) KB)"
    }
    
    $reportContent += @"

### Autres fichiers
"@
    
    $otherFiles = $MovedFiles | Where-Object { $_.Extension -notin @(".html", ".js", ".css") }
    foreach ($file in $otherFiles) {
        $reportContent += "`n- $($file.Name) ($(($file.Size / 1KB).ToString("F2")) KB)"
    }
    
    $reportContent += @"

## Fichiers avec références mises à jour

### Fichiers HTML
"@
    
    if ($UpdatedHtmlFiles.Count -gt 0) {
        foreach ($file in $UpdatedHtmlFiles) {
            $reportContent += "`n- $file"
        }
    } else {
        $reportContent += "`nAucun fichier HTML n'a nécessité de mise à jour des références."
    }
    
    $reportContent += @"

### Fichiers JavaScript
"@
    
    if ($UpdatedJsFiles.Count -gt 0) {
        foreach ($file in $UpdatedJsFiles) {
            $reportContent += "`n- $file"
        }
    } else {
        $reportContent += "`nAucun fichier JavaScript n'a nécessité de mise à jour des imports."
    }
    
    # Créer le dossier du rapport si nécessaire
    $reportFolder = Split-Path -Path $ReportPath -Parent
    if (-not (Test-Path -Path $reportFolder)) {
        New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    Set-Content -Path $ReportPath -Value $reportContent
    
    Write-Log "Rapport généré: $ReportPath" -Level "Success"
}

# Fonction principale
function Main {
    Write-Log "Démarrage du déplacement des fichiers de visualisation..." -Level "Info"
    
    # Déplacer les fichiers
    $movedFiles = Move-Files -SourcePath $SourcePath -DestinationPath $DestinationPath
    
    if ($null -eq $movedFiles -or $movedFiles.Count -eq 0) {
        Write-Log "Aucun fichier n'a été déplacé. Fin du script." -Level "Warning"
        return
    }
    
    # Mettre à jour les références dans les fichiers HTML
    $updatedHtmlFiles = Update-HtmlReferences -MovedFiles $movedFiles -DestinationPath $DestinationPath
    
    # Mettre à jour les références dans les fichiers JS
    $updatedJsFiles = Update-JsReferences -MovedFiles $movedFiles -DestinationPath $DestinationPath
    
    # Générer un rapport
    New-Report -MovedFiles $movedFiles -UpdatedHtmlFiles $updatedHtmlFiles -UpdatedJsFiles $updatedJsFiles -ReportPath $ReportPath
    
    Write-Log "Déplacement des fichiers de visualisation terminé." -Level "Success"
}

# Exécuter la fonction principale
Main
