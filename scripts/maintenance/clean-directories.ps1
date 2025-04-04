# Script pour nettoyer les dossiers restants a la racine

Write-Host "=== Nettoyage des dossiers restants a la racine ===" -ForegroundColor Cyan

# 1. Fusionner doc avec docs
if (Test-Path ".\doc") {
    Write-Host "Fusion du dossier doc avec docs..." -ForegroundColor Yellow
    
    # Verifier si le dossier docs existe
    if (-not (Test-Path ".\docs")) {
        New-Item -ItemType Directory -Path ".\docs" -Force | Out-Null
        Write-Host "Dossier docs cree" -ForegroundColor Green
    }
    
    # Copier les fichiers de doc vers docs
    $docFiles = Get-ChildItem -Path ".\doc" -Recurse -File
    
    foreach ($file in $docFiles) {
        $relativePath = $file.FullName.Substring((Get-Item ".\doc").FullName.Length + 1)
        $destinationPath = Join-Path ".\docs" $relativePath
        $destinationDir = Split-Path $destinationPath -Parent
        
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        Write-Host "Fichier $relativePath copie vers docs" -ForegroundColor Green
    }
    
    Write-Host "Voulez-vous supprimer le dossier doc apres la fusion ? (O/N)" -ForegroundColor Yellow
    $deleteDoc = Read-Host
    
    if ($deleteDoc -eq "O" -or $deleteDoc -eq "o") {
        Remove-Item -Path ".\doc" -Recurse -Force
        Write-Host "Dossier doc supprime" -ForegroundColor Green
    } else {
        Write-Host "Dossier doc conserve" -ForegroundColor Yellow
    }
}

# 2. Deplacer gateway dans src/mcp
if (Test-Path ".\gateway") {
    Write-Host "`nDeplacement du dossier gateway vers src/mcp..." -ForegroundColor Yellow
    
    # Verifier si le dossier src/mcp existe
    if (-not (Test-Path ".\src\mcp")) {
        New-Item -ItemType Directory -Path ".\src\mcp" -Force | Out-Null
        Write-Host "Dossier src/mcp cree" -ForegroundColor Green
    }
    
    # Copier le dossier gateway vers src/mcp
    if (Test-Path ".\src\mcp\gateway") {
        Write-Host "Le dossier src/mcp/gateway existe deja" -ForegroundColor Yellow
        Write-Host "Voulez-vous le remplacer ? (O/N)" -ForegroundColor Yellow
        $replaceGateway = Read-Host
        
        if ($replaceGateway -eq "O" -or $replaceGateway -eq "o") {
            Remove-Item -Path ".\src\mcp\gateway" -Recurse -Force
            Copy-Item -Path ".\gateway" -Destination ".\src\mcp" -Recurse -Force
            Write-Host "Dossier gateway copie vers src/mcp (remplace)" -ForegroundColor Green
        } else {
            Write-Host "Dossier src/mcp/gateway conserve" -ForegroundColor Yellow
        }
    } else {
        Copy-Item -Path ".\gateway" -Destination ".\src\mcp" -Recurse -Force
        Write-Host "Dossier gateway copie vers src/mcp" -ForegroundColor Green
    }
    
    Write-Host "Voulez-vous supprimer le dossier gateway a la racine ? (O/N)" -ForegroundColor Yellow
    $deleteGateway = Read-Host
    
    if ($deleteGateway -eq "O" -or $deleteGateway -eq "o") {
        Remove-Item -Path ".\gateway" -Recurse -Force
        Write-Host "Dossier gateway supprime" -ForegroundColor Green
    } else {
        Write-Host "Dossier gateway conserve" -ForegroundColor Yellow
    }
}

# 3. Fusionner mcp avec src/mcp
if (Test-Path ".\mcp") {
    Write-Host "`nFusion du dossier mcp avec src/mcp..." -ForegroundColor Yellow
    
    # Verifier si le dossier src/mcp existe
    if (-not (Test-Path ".\src\mcp")) {
        New-Item -ItemType Directory -Path ".\src\mcp" -Force | Out-Null
        Write-Host "Dossier src/mcp cree" -ForegroundColor Green
    }
    
    # Copier les fichiers de mcp vers src/mcp
    $mcpFiles = Get-ChildItem -Path ".\mcp" -Recurse -File
    
    foreach ($file in $mcpFiles) {
        $relativePath = $file.FullName.Substring((Get-Item ".\mcp").FullName.Length + 1)
        $destinationPath = Join-Path ".\src\mcp" $relativePath
        $destinationDir = Split-Path $destinationPath -Parent
        
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        Write-Host "Fichier $relativePath copie vers src/mcp" -ForegroundColor Green
    }
    
    Write-Host "Voulez-vous supprimer le dossier mcp apres la fusion ? (O/N)" -ForegroundColor Yellow
    $deleteMcp = Read-Host
    
    if ($deleteMcp -eq "O" -or $deleteMcp -eq "o") {
        Remove-Item -Path ".\mcp" -Recurse -Force
        Write-Host "Dossier mcp supprime" -ForegroundColor Green
    } else {
        Write-Host "Dossier mcp conserve" -ForegroundColor Yellow
    }
}

# 4. Archiver old
if (Test-Path ".\old") {
    Write-Host "`nTraitement du dossier old..." -ForegroundColor Yellow
    Write-Host "Que souhaitez-vous faire du dossier old ?" -ForegroundColor Yellow
    Write-Host "1. Archiver dans un dossier archive" -ForegroundColor Yellow
    Write-Host "2. Supprimer" -ForegroundColor Yellow
    Write-Host "3. Conserver" -ForegroundColor Yellow
    
    $oldChoice = Read-Host "Votre choix (1-3)"
    
    switch ($oldChoice) {
        "1" {
            # Archiver old
            if (-not (Test-Path ".\archive")) {
                New-Item -ItemType Directory -Path ".\archive" -Force | Out-Null
                Write-Host "Dossier archive cree" -ForegroundColor Green
            }
            
            Copy-Item -Path ".\old" -Destination ".\archive" -Recurse -Force
            Write-Host "Dossier old copie vers archive" -ForegroundColor Green
            
            Remove-Item -Path ".\old" -Recurse -Force
            Write-Host "Dossier old supprime" -ForegroundColor Green
        }
        "2" {
            # Supprimer old
            Remove-Item -Path ".\old" -Recurse -Force
            Write-Host "Dossier old supprime" -ForegroundColor Green
        }
        "3" {
            # Conserver old
            Write-Host "Dossier old conserve" -ForegroundColor Yellow
        }
        default {
            Write-Host "Choix invalide, dossier old conserve" -ForegroundColor Yellow
        }
    }
}

# 5. Deplacer plans dans docs
if (Test-Path ".\plans") {
    Write-Host "`nDeplacement du dossier plans vers docs..." -ForegroundColor Yellow
    
    # Verifier si le dossier docs existe
    if (-not (Test-Path ".\docs")) {
        New-Item -ItemType Directory -Path ".\docs" -Force | Out-Null
        Write-Host "Dossier docs cree" -ForegroundColor Green
    }
    
    # Copier le dossier plans vers docs
    if (Test-Path ".\docs\plans") {
        Write-Host "Le dossier docs/plans existe deja" -ForegroundColor Yellow
        Write-Host "Voulez-vous le remplacer ? (O/N)" -ForegroundColor Yellow
        $replacePlans = Read-Host
        
        if ($replacePlans -eq "O" -or $replacePlans -eq "o") {
            Remove-Item -Path ".\docs\plans" -Recurse -Force
            Copy-Item -Path ".\plans" -Destination ".\docs" -Recurse -Force
            Write-Host "Dossier plans copie vers docs (remplace)" -ForegroundColor Green
        } else {
            Write-Host "Dossier docs/plans conserve" -ForegroundColor Yellow
        }
    } else {
        Copy-Item -Path ".\plans" -Destination ".\docs" -Recurse -Force
        Write-Host "Dossier plans copie vers docs" -ForegroundColor Green
    }
    
    Write-Host "Voulez-vous supprimer le dossier plans a la racine ? (O/N)" -ForegroundColor Yellow
    $deletePlans = Read-Host
    
    if ($deletePlans -eq "O" -or $deletePlans -eq "o") {
        Remove-Item -Path ".\plans" -Recurse -Force
        Write-Host "Dossier plans supprime" -ForegroundColor Green
    } else {
        Write-Host "Dossier plans conserve" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Nettoyage termine ===" -ForegroundColor Cyan
