<#
.SYNOPSIS
    Fusionne les dossiers de scripts.

.DESCRIPTION
    Ce script dÃ©place les scripts de development/scripts vers les sous-dossiers appropriÃ©s
    dans development/scripts.

.EXAMPLE
    .\merge-scripts-folders.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Merge-ScriptsFolders {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Fusion des dossiers de scripts..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        $sourceRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\tools\scripts"
        $destRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts"
        
        # VÃ©rifier que les dossiers existent
        if (-not (Test-Path $sourceRoot)) {
            Write-Error "Le dossier source n'existe pas : $sourceRoot"
            return $false
        }
        
        if (-not (Test-Path $destRoot)) {
            Write-Error "Le dossier de destination n'existe pas : $destRoot"
            return $false
        }
        
        # DÃ©finir les mappages de dossiers
        $folderMappings = @{
            "agent-auto" = "automation"
            "analysis" = "analysis"
            "analytics" = "analytics"
            "api" = "api"
            "augment" = "maintenance\augment"
            "automation" = "automation"
            "ci" = "ci"
            "cleanup" = "maintenance\cleanup"
            "cmd" = "batch"
            "core" = "core"
            "debug" = "debug"
            "deployment" = "deployment"
            "docs" = "documentation"
            "email" = "email"
            "examples" = "examples"
            "Format-Converters" = "utils"
            "format-detection" = "utils"
            "gui" = "gui"
            "integration" = "integration"
            "journal" = "journal"
            "maintenance" = "maintenance"
            "manager" = "manager"
            "mcp" = "mcp"
            "mcp_project" = "mcp"
            "monitoring" = "monitoring"
            "n8n" = "n8n"
            "node" = "node"
            "parallel-hybrid" = "performance"
            "performance" = "performance"
            "pr-reporting" = "reporting"
            "pr-testing" = "testing"
            "python" = "python"
            "reporting" = "reporting"
            "roadmap" = "roadmap"
            "roadmap-parser" = "roadmap-parser"
            "setup" = "setup"
            "templates" = "templates"
            "test" = "testing\tests"
            "testing" = "testing"
            "tests" = "testing\tests"
            "utils" = "utils"
            "visualization" = "visualization"
            "workflow" = "workflow"
        }
        
        # DÃ©finir les mappages de fichiers
        $fileMappings = @{
            "archi-mode.ps1" = "maintenance\modes"
            "c-break-mode.ps1" = "maintenance\modes"
            "check-enhanced.ps1" = "maintenance\modes"
            "check-services.ps1" = "maintenance\services"
            "check.ps1" = "maintenance\modes"
            "copy-docs.ps1" = "documentation"
            "copy-files.ps1" = "utils"
            "diagnose-services.ps1" = "maintenance\services"
            "get-local-ip.ps1" = "network"
            "get-public-ip.ps1" = "network"
            "move-docs.ps1" = "documentation"
            "README.md" = "."
            "reorganize-docs-hygen.ps1" = "documentation"
            "reorganize-docs.ps1" = "documentation"
            "requirements.txt" = "python"
            "Run-FunctionalTests.ps1" = "testing"
            "standardize-encoding.ps1" = "utils"
            "start-local-services.ps1" = "maintenance\services"
            "test_extension_manual.ps1" = "testing\tests"
            "test_extension.ps1" = "testing\tests"
            "test-browser-config.ps1" = "testing\tests"
            "Test-InvokeRoadmapGranularity.ps1" = "roadmap"
            "Test-RoadmapModel3.ps1" = "roadmap"
            "Test-RoadmapModel4.ps1" = "roadmap"
            "Test-SplitRoadmapTaskSimple.ps1" = "roadmap"
            "TestOmnibus-Integration.ps1" = "testing\integration"
            "validate-local-ip.ps1" = "network"
        }
    }
    
    process {
        try {
            # CrÃ©er les dossiers de destination s'ils n'existent pas
            foreach ($mapping in $folderMappings.GetEnumerator()) {
                $destFolder = Join-Path -Path $destRoot -ChildPath $mapping.Value
                if (-not (Test-Path $destFolder)) {
                    if ($PSCmdlet.ShouldProcess($destFolder, "CrÃ©er le dossier")) {
                        New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                        Write-Host "  Dossier crÃ©Ã© : $destFolder" -ForegroundColor Yellow
                    }
                }
            }
            
            # CrÃ©er le dossier network s'il n'existe pas
            $networkFolder = Join-Path -Path $destRoot -ChildPath "network"
            if (-not (Test-Path $networkFolder)) {
                if ($PSCmdlet.ShouldProcess($networkFolder, "CrÃ©er le dossier")) {
                    New-Item -Path $networkFolder -ItemType Directory -Force | Out-Null
                    Write-Host "  Dossier crÃ©Ã© : $networkFolder" -ForegroundColor Yellow
                }
            }
            
            # CrÃ©er le dossier modes s'il n'existe pas
            $modesFolder = Join-Path -Path $destRoot -ChildPath "maintenance\modes"
            if (-not (Test-Path $modesFolder)) {
                if ($PSCmdlet.ShouldProcess($modesFolder, "CrÃ©er le dossier")) {
                    New-Item -Path $modesFolder -ItemType Directory -Force | Out-Null
                    Write-Host "  Dossier crÃ©Ã© : $modesFolder" -ForegroundColor Yellow
                }
            }
            
            # CrÃ©er le dossier services s'il n'existe pas
            $servicesFolder = Join-Path -Path $destRoot -ChildPath "maintenance\services"
            if (-not (Test-Path $servicesFolder)) {
                if ($PSCmdlet.ShouldProcess($servicesFolder, "CrÃ©er le dossier")) {
                    New-Item -Path $servicesFolder -ItemType Directory -Force | Out-Null
                    Write-Host "  Dossier crÃ©Ã© : $servicesFolder" -ForegroundColor Yellow
                }
            }
            
            # DÃ©placer les dossiers
            foreach ($mapping in $folderMappings.GetEnumerator()) {
                $sourceFolder = Join-Path -Path $sourceRoot -ChildPath $mapping.Key
                $destFolder = Join-Path -Path $destRoot -ChildPath $mapping.Value
                
                if (Test-Path $sourceFolder) {
                    if ($PSCmdlet.ShouldProcess("$sourceFolder -> $destFolder", "DÃ©placer le dossier")) {
                        # Copier le contenu du dossier
                        Copy-Item -Path "$sourceFolder\*" -Destination $destFolder -Recurse -Force
                        Write-Host "  Dossier dÃ©placÃ© : $sourceFolder -> $destFolder" -ForegroundColor Green
                    }
                }
            }
            
            # DÃ©placer les fichiers
            foreach ($mapping in $fileMappings.GetEnumerator()) {
                $sourceFile = Join-Path -Path $sourceRoot -ChildPath $mapping.Key
                $destFolder = Join-Path -Path $destRoot -ChildPath $mapping.Value
                $destFile = Join-Path -Path $destFolder -ChildPath $mapping.Key
                
                if (Test-Path $sourceFile) {
                    if ($PSCmdlet.ShouldProcess("$sourceFile -> $destFile", "DÃ©placer le fichier")) {
                        # Copier le fichier
                        Copy-Item -Path $sourceFile -Destination $destFile -Force
                        Write-Host "  Fichier dÃ©placÃ© : $sourceFile -> $destFile" -ForegroundColor Green
                    }
                }
            }
            
            # DÃ©placer les templates Hygen
            $sourceTemplates = Join-Path -Path $sourceRoot -ChildPath "_templates"
            $destTemplates = Join-Path -Path (Get-Location).Path -ChildPath "development\templates\hygen"
            
            if (Test-Path $sourceTemplates) {
                if ($PSCmdlet.ShouldProcess("$sourceTemplates -> $destTemplates", "DÃ©placer les templates")) {
                    # Copier le contenu du dossier
                    Copy-Item -Path "$sourceTemplates\*" -Destination $destTemplates -Recurse -Force
                    Write-Host "  Templates dÃ©placÃ©s : $sourceTemplates -> $destTemplates" -ForegroundColor Green
                }
            }
            
            # Supprimer le dossier source
            if ($PSCmdlet.ShouldProcess($sourceRoot, "Supprimer le dossier")) {
                Remove-Item -Path $sourceRoot -Recurse -Force
                Write-Host "  Dossier source supprimÃ© : $sourceRoot" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la fusion des dossiers de scripts : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nFusion des dossiers de scripts terminÃ©e !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Merge-ScriptsFolders

