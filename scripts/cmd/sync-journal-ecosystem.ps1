# Script PowerShell pour synchroniser le journal de bord avec l'écosystème (Augment, MCP, Documentation)

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"

# Fonction pour afficher un message de section
function Write-Section {
    param (
        [string]$Title
    )

    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Fonction pour exécuter une commande et afficher son résultat
function Invoke-CommandWithOutput {
    param (
        [string]$Command,
        [string]$Arguments
    )

    Write-Host "Exécution de: $Command $Arguments" -ForegroundColor Gray

    try {
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "Commande exécutée avec succès." -ForegroundColor Green
        } else {
            Write-Host "La commande a échoué avec le code de sortie $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'exécution de la commande: $_" -ForegroundColor Red
    }
}

# Afficher un message d'introduction
Write-Host "Synchronisation du journal de bord avec l'écosystème" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va synchroniser le journal de bord avec:"
Write-Host "1. Augment Memories"
Write-Host "2. MCP (Model Context Protocol)"
Write-Host "3. Documentation"
Write-Host ""

# 1. Mettre à jour les index du journal
Write-Section "Mise à jour des index du journal"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_search_simple.py --rebuild"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_rag_simple.py --rebuild --export"

# 2. Synchroniser avec Augment Memories
Write-Section "Synchronisation avec Augment Memories"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\augment_integration.py export"

# 3. Extraire les insights pour la documentation
Write-Section "Extraction des insights pour la documentation"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\docs_integration.py extract"

# 4. Mettre à jour les liens entre le journal et la documentation
Write-Section "Mise à jour des liens entre le journal et la documentation"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\docs_integration.py update"

# 5. Vérifier si le serveur MCP est en cours d'exécution
Write-Section "Vérification du serveur MCP"
$mcpRunning = Get-Process | Where-Object { $_.ProcessName -eq "mcp-server" -or $_.ProcessName -eq "node" -and $_.CommandLine -like "*mcp-server*" }

if ($mcpRunning) {
    Write-Host "Le serveur MCP est déjà en cours d'exécution." -ForegroundColor Green
} else {
    Write-Host "Le serveur MCP n'est pas en cours d'exécution." -ForegroundColor Yellow
    Write-Host "Pour démarrer le serveur MCP, exécutez: .\scripts\cmd\start-journal-mcp.ps1" -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Synchronisation terminée"
Write-Host "Le journal de bord a été synchronisé avec succès avec l'écosystème!" -ForegroundColor Green
Write-Host ""
Write-Host "Résumé des actions effectuées:"
Write-Host "1. Les index du journal ont été mis à jour"
Write-Host "2. Les entrées du journal ont été exportées vers Augment Memories"
Write-Host "3. Les insights techniques ont été extraits pour la documentation"
Write-Host "4. Les liens entre le journal et la documentation ont été mis à jour"
Write-Host ""
Write-Host "Pour une intégration complète:"
Write-Host "- Assurez-vous que le serveur MCP est en cours d'exécution"
Write-Host "- Configurez Augment pour utiliser les memories exportées"
Write-Host "- Consultez la documentation générée dans le dossier docs/documentation"
Write-Host ""
Write-Host "Pour automatiser cette synchronisation, vous pouvez ajouter ce script à une tâche planifiée Windows."
