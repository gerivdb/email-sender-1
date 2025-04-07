# Script pour nettoyer les fichiers MCP obsoletes

Write-Host "=== Nettoyage des fichiers MCP obsoletes ===" -ForegroundColor Cyan

# Liste des fichiers a supprimer (apres avoir verifie qu'ils ont ete copies dans le dossier mcp)
$filesToRemove = @(
    # Fichiers batch
    "mcp-standard.cmd",
    "mcp-notion.cmd",
    "gateway.exe.cmd",
    
    # Fichiers de configuration
    "mcp-config.json",
    "mcp-config-fixed.json",
    "gateway.yaml",
    
    # Fichiers de workflow
    "test-mcp-workflow-updated.json"
)

# Verifier que les fichiers existent dans le dossier mcp avant de les supprimer
foreach ($file in $filesToRemove) {
    $fileType = ""
    $targetFolder = ""
    
    if ($file -like "*.cmd") {
        $fileType = "batch"
        $targetFolder = "mcp\batch"
    } elseif ($file -like "*.json" -and $file -notlike "*workflow*.json") {
        $fileType = "config"
        $targetFolder = "mcp\config"
    } elseif ($file -like "*workflow*.json") {
        $fileType = "workflow"
        $targetFolder = "mcp\workflows"
    } elseif ($file -like "*.yaml") {
        $fileType = "config"
        $targetFolder = "mcp\config"
    }
    
    if (Test-Path ".\$targetFolder\$file") {
        Write-Host "Le fichier $file existe dans le dossier $targetFolder" -ForegroundColor Green
        
        # Demander confirmation avant de supprimer
        Write-Host "Voulez-vous supprimer le fichier $file de la racine ? (O/N)" -ForegroundColor Yellow
        $confirmation = Read-Host
        
        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            if (Test-Path ".\$file") {
                Remove-Item ".\$file"
                Write-Host "âœ… Fichier $file supprime" -ForegroundColor Green
            } else {
                Write-Host "âŒ Fichier $file non trouve a la racine" -ForegroundColor Red
            }
        } else {
            Write-Host "Fichier $file conserve" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âŒ Fichier $file non trouve dans le dossier $targetFolder" -ForegroundColor Red
        Write-Host "Le fichier ne sera pas supprime de la racine" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Nettoyage termine ===" -ForegroundColor Cyan
Write-Host "Les fichiers MCP obsoletes ont ete nettoyes."
Write-Host "Tous les fichiers necessaires sont disponibles dans le dossier mcp."

