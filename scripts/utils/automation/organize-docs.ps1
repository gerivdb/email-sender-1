# Script pour organiser les fichiers de documentation
# Ce script organise les fichiers de documentation dans des sous-dossiers appropriés

# Définition des règles de déplacement pour le dossier docs
$docsRules = @(
    # Guides
    @{
        Pattern = "GUIDE_*.md", "DEMARRER_*.md", "CONFIGURATION_*.md"
        Destination = "docs\guides"
    },
    # Workflows
    @{
        Pattern = "WORKFLOW_*.md", "README_EMAIL_SENDER_*.md"
        Destination = "docs\workflows"
    },
    # N8N
    @{
        Pattern = "N8N_*.md", "n8n*.md"
        Destination = "docs\n8n"
    },
    # MCP
    @{
        Pattern = "*MCP*.md", "RAPPORT_FINAL_MCP.md"
        Destination = "docs\mcp"
    },
    # Reference
    @{
        Pattern = "GLOSSAIRE_*.md", "STRUCTURE_*.md", "CHANGEMENTS_*.md"
        Destination = "docs\reference"
    }
)

# Définition des règles de déplacement pour le dossier docs\plans
$plansRules = @(
    # Implementation
    @{
        Pattern = "PLAN_IMPLEMENTATION*.md"
        Destination = "docs\plans\implementation"
    },
    # Transition
    @{
        Pattern = "PLAN_TRANSITION*.md", "phase*-transi*.md"
        Destination = "docs\plans\transition"
    },
    # Magistral
    @{
        Pattern = "Plan Magistral*.md"
        Destination = "docs\plans\magistral"
    },
    # Piliers
    @{
        Pattern = "PILIER_*.md"
        Destination = "docs\plans\piliers"
    },
    # Versions restructurées
    @{
        Pattern = "*-restructured.md"
        Destination = "docs\plans\versions"
    }
)

# Fonction pour déplacer les fichiers selon les règles
function Move-FilesAccordingToRules {
    param (
        [string]$SourceFolder,
        [array]$Rules
    )
    
    Write-Host "Organisation des fichiers dans $SourceFolder..." -ForegroundColor Cyan
    
    foreach ($rule in $Rules) {
        foreach ($pattern in $rule.Pattern) {
            $files = Get-ChildItem -Path $SourceFolder -Filter $pattern -File
            
            foreach ($file in $files) {
                $destination = $rule.Destination
                $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
                
                if (-not (Test-Path -Path $destinationFile)) {
                    Write-Host "Déplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
                    Move-Item -Path $file.FullName -Destination $destination -Force
                } else {
                    Write-Host "Le fichier $($file.Name) existe déjà dans $destination" -ForegroundColor Red
                }
            }
        }
    }
}

# Fonction pour organiser les fichiers dans les sous-dossiers de plans
function Organize-PlansSubfolders {
    # Déplacer les fichiers de "plan de départ" vers "implementation"
    $files = Get-ChildItem -Path "docs\plans\plan de départ" -File
    foreach ($file in $files) {
        $destination = "docs\plans\implementation"
        $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
        
        if (-not (Test-Path -Path $destinationFile)) {
            Write-Host "Déplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
            Move-Item -Path $file.FullName -Destination $destination -Force
        }
    }
    
    # Déplacer les fichiers de "plan de transition" vers "transition"
    $files = Get-ChildItem -Path "docs\plans\plan de transition" -File
    foreach ($file in $files) {
        $destination = "docs\plans\transition"
        $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
        
        if (-not (Test-Path -Path $destinationFile)) {
            Write-Host "Déplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
            Move-Item -Path $file.FullName -Destination $destination -Force
        }
    }
    
    # Déplacer les fichiers de "pour le futur" vers les dossiers appropriés
    $files = Get-ChildItem -Path "docs\plans\pour le futur" -File
    foreach ($file in $files) {
        if ($file.Name -like "PILIER_*") {
            $destination = "docs\plans\piliers"
        } elseif ($file.Name -like "Plan Magistral*") {
            $destination = "docs\plans\magistral"
        } elseif ($file.Name -like "*-restructured.md") {
            $destination = "docs\plans\versions"
        } else {
            $destination = "docs\plans"
        }
        
        $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
        
        if (-not (Test-Path -Path $destinationFile)) {
            Write-Host "Déplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
            Move-Item -Path $file.FullName -Destination $destination -Force
        }
    }
    
    # Déplacer les fichiers restructurés vers le dossier versions
    $files = Get-ChildItem -Path "docs\plans" -Filter "*-restructured.md" -File -Recurse | 
             Where-Object { $_.DirectoryName -ne (Resolve-Path "docs\plans\versions").Path }
    
    foreach ($file in $files) {
        $destination = "docs\plans\versions"
        $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
        
        if (-not (Test-Path -Path $destinationFile)) {
            Write-Host "Déplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
            Move-Item -Path $file.FullName -Destination $destination -Force
        }
    }
}

# Fonction pour supprimer les dossiers vides
function Remove-EmptyFolders {
    param (
        [string]$RootFolder
    )
    
    $emptyFolders = Get-ChildItem -Path $RootFolder -Directory -Recurse | 
                    Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -File).Count -eq 0 }
    
    foreach ($folder in $emptyFolders) {
        Write-Host "Suppression du dossier vide: $($folder.FullName)" -ForegroundColor Yellow
        Remove-Item -Path $folder.FullName -Force
    }
}

# Exécution principale
Write-Host "Début de l'organisation des fichiers de documentation..." -ForegroundColor Cyan

# Organiser les fichiers dans le dossier docs
Move-FilesAccordingToRules -SourceFolder "docs" -Rules $docsRules

# Organiser les fichiers dans le dossier docs\plans
Move-FilesAccordingToRules -SourceFolder "docs\plans" -Rules $plansRules

# Organiser les fichiers dans les sous-dossiers de plans
Organize-PlansSubfolders

# Supprimer les dossiers vides
Remove-EmptyFolders -RootFolder "docs"

Write-Host "`nOrganisation des fichiers de documentation terminée avec succès!" -ForegroundColor Green
