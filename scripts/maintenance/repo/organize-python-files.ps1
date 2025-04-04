# Script pour organiser les fichiers Python dans un dossier scripts

Write-Host "=== Organisation des fichiers Python ===" -ForegroundColor Cyan

# Creer le dossier scripts s'il n'existe pas
if (-not (Test-Path ".\scripts")) {
    New-Item -ItemType Directory -Path ".\scripts" | Out-Null
    Write-Host "✅ Dossier scripts cree" -ForegroundColor Green
} else {
    Write-Host "✅ Dossier scripts existe deja" -ForegroundColor Green
}

# Trouver tous les fichiers Python a la racine
$pythonFiles = Get-ChildItem -Path "." -Filter "*.py" -File

if ($pythonFiles.Count -eq 0) {
    Write-Host "Aucun fichier Python trouve a la racine" -ForegroundColor Yellow
} else {
    Write-Host "Fichiers Python trouves a la racine : $($pythonFiles.Count)" -ForegroundColor Yellow
    
    foreach ($file in $pythonFiles) {
        # Verifier si le fichier existe deja dans le dossier scripts
        if (Test-Path ".\scripts\$($file.Name)") {
            Write-Host "⚠️ Le fichier $($file.Name) existe deja dans le dossier scripts" -ForegroundColor Yellow
            Write-Host "Voulez-vous le remplacer ? (O/N)" -ForegroundColor Yellow
            $confirmation = Read-Host
            
            if ($confirmation -eq "O" -or $confirmation -eq "o") {
                Move-Item -Path $file.FullName -Destination ".\scripts\$($file.Name)" -Force
                Write-Host "✅ Fichier $($file.Name) deplace vers scripts (remplace)" -ForegroundColor Green
            } else {
                Write-Host "Fichier $($file.Name) conserve a la racine" -ForegroundColor Yellow
            }
        } else {
            Move-Item -Path $file.FullName -Destination ".\scripts\$($file.Name)"
            Write-Host "✅ Fichier $($file.Name) deplace vers scripts" -ForegroundColor Green
        }
    }
}

# Rechercher des fichiers Python dans d'autres dossiers (sauf scripts et mcp)
Write-Host "`nRecherche de fichiers Python dans d'autres dossiers..." -ForegroundColor Yellow
$otherPythonFiles = Get-ChildItem -Path "." -Recurse -Filter "*.py" -File | 
    Where-Object { $_.DirectoryName -notlike "*\scripts*" -and $_.DirectoryName -notlike "*\mcp*" -and $_.DirectoryName -ne "." }

if ($otherPythonFiles.Count -eq 0) {
    Write-Host "Aucun fichier Python trouve dans d'autres dossiers" -ForegroundColor Yellow
} else {
    Write-Host "Fichiers Python trouves dans d'autres dossiers : $($otherPythonFiles.Count)" -ForegroundColor Yellow
    Write-Host "Voulez-vous egalement deplacer ces fichiers vers scripts ? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        foreach ($file in $otherPythonFiles) {
            $relativePath = $file.DirectoryName.Substring($PWD.Path.Length + 1)
            Write-Host "Fichier : $relativePath\$($file.Name)" -ForegroundColor Yellow
            
            # Verifier si le fichier existe deja dans le dossier scripts
            if (Test-Path ".\scripts\$($file.Name)") {
                Write-Host "⚠️ Un fichier du meme nom existe deja dans scripts" -ForegroundColor Yellow
                Write-Host "Voulez-vous le remplacer ? (O/N/R pour renommer)" -ForegroundColor Yellow
                $fileConfirmation = Read-Host
                
                if ($fileConfirmation -eq "O" -or $fileConfirmation -eq "o") {
                    Move-Item -Path $file.FullName -Destination ".\scripts\$($file.Name)" -Force
                    Write-Host "✅ Fichier deplace vers scripts (remplace)" -ForegroundColor Green
                } elseif ($fileConfirmation -eq "R" -or $fileConfirmation -eq "r") {
                    $newName = "$($file.BaseName)_$($relativePath.Replace('\', '_'))$($file.Extension)"
                    Move-Item -Path $file.FullName -Destination ".\scripts\$newName"
                    Write-Host "✅ Fichier deplace vers scripts (renomme en $newName)" -ForegroundColor Green
                } else {
                    Write-Host "Fichier conserve a son emplacement actuel" -ForegroundColor Yellow
                }
            } else {
                Move-Item -Path $file.FullName -Destination ".\scripts\$($file.Name)"
                Write-Host "✅ Fichier deplace vers scripts" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Les fichiers Python dans d'autres dossiers n'ont pas ete deplaces" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Organisation terminee ===" -ForegroundColor Cyan
Write-Host "Les fichiers Python ont ete organises dans le dossier scripts."

