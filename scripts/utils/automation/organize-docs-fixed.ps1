# Script pour organiser les fichiers de documentation
# Ce script organise les fichiers de documentation dans des sous-dossiers appropries

# Definition des regles de deplacement pour le dossier docs
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
        Pattern = "GLOSSAIRE_*.md", "STRUCTURE_*.md", "CHANGEMENTS_*.md", "CMS*.md"
        Destination = "docs\reference"
    }
)

# Definition des regles de deplacement pour le dossier docs\plans
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
    # Versions restructurees
    @{
        Pattern = "*-restructured.md"
        Destination = "docs\plans\versions"
    }
)

# Fonction pour deplacer les fichiers selon les regles
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
                    Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
                    Move-Item -Path $file.FullName -Destination $destination -Force
                } else {
                    Write-Host "Le fichier $($file.Name) existe deja dans $destination" -ForegroundColor Red
                }
            }
        }
    }
}

# Fonction pour organiser les fichiers dans les sous-dossiers de plans
function Organize-PlansSubfolders {
    # Deplacer les fichiers des anciens dossiers vers les nouveaux
    $oldFolders = @(
        @{ Old = "docs\plans\plan de depart"; New = "docs\plans\implementation" },
        @{ Old = "docs\plans\plan de transition"; New = "docs\plans\transition" },
        @{ Old = "docs\plans\pour le futur"; New = "docs\plans\magistral" }
    )
    
    foreach ($folder in $oldFolders) {
        $oldPath = $folder.Old
        $newPath = $folder.New
        
        if (Test-Path -Path $oldPath) {
            $files = Get-ChildItem -Path $oldPath -File
            
            foreach ($file in $files) {
                $destinationPath = ""
                
                # Determiner le dossier de destination en fonction du nom du fichier
                if ($file.Name -like "PLAN_IMPLEMENTATION*") {
                    $destinationPath = "docs\plans\implementation"
                } elseif ($file.Name -like "*transi*" -or $file.Name -like "PLAN_TRANSITION*") {
                    $destinationPath = "docs\plans\transition"
                } elseif ($file.Name -like "Plan Magistral*") {
                    $destinationPath = "docs\plans\magistral"
                } elseif ($file.Name -like "PILIER_*") {
                    $destinationPath = "docs\plans\piliers"
                } elseif ($file.Name -like "*-restructured*") {
                    $destinationPath = "docs\plans\versions"
                } else {
                    $destinationPath = $newPath
                }
                
                $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name
                
                if (-not (Test-Path -Path $destinationFile)) {
                    Write-Host "Deplacement de $($file.Name) depuis $oldPath vers $destinationPath" -ForegroundColor Yellow
                    Move-Item -Path $file.FullName -Destination $destinationPath -Force
                }
            }
        }
    }
    
    # Deplacer les fichiers restructures vers le dossier versions
    $restructuredFiles = Get-ChildItem -Path "docs\plans" -Filter "*-restructured.md" -File -Recurse | 
                         Where-Object { $_.DirectoryName -ne (Resolve-Path "docs\plans\versions").Path }
    
    foreach ($file in $restructuredFiles) {
        $destination = "docs\plans\versions"
        $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
        
        if (-not (Test-Path -Path $destinationFile)) {
            Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
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

# Execution principale
Write-Host "Debut de l'organisation des fichiers de documentation..." -ForegroundColor Cyan

# Organiser les fichiers dans le dossier docs
Move-FilesAccordingToRules -SourceFolder "docs" -Rules $docsRules

# Organiser les fichiers dans le dossier docs\plans
Move-FilesAccordingToRules -SourceFolder "docs\plans" -Rules $plansRules

# Organiser les fichiers dans les sous-dossiers de plans
Organize-PlansSubfolders

# Supprimer les dossiers vides
Remove-EmptyFolders -RootFolder "docs"

Write-Host "`nOrganisation des fichiers de documentation terminee avec succes!" -ForegroundColor Green
