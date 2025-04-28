# Script PowerShell pour synchroniser le journal de bord avec l'Ã©cosystÃ¨me (Augment, MCP, Documentation)

# Chemin absolu vers le rÃ©pertoire du projet
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

# Fonction pour exÃ©cuter une commande et afficher son rÃ©sultat
function Invoke-CommandWithOutput {
    param (
        [string]$Command,
        [string]$Arguments
    )

    Write-Host "ExÃ©cution de: $Command $Arguments" -ForegroundColor Gray

    try {
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "Commande exÃ©cutÃ©e avec succÃ¨s." -ForegroundColor Green
        } else {
            Write-Host "La commande a Ã©chouÃ© avec le code de sortie $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'exÃ©cution de la commande: $_" -ForegroundColor Red
    }
}

# Afficher un message d'introduction
Write-Host "Synchronisation du journal de bord avec l'Ã©cosystÃ¨me" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va synchroniser le journal de bord avec:"
Write-Host "1. Augment Memories"
Write-Host "2. MCP (Model Context Protocol)"
Write-Host "3. Documentation"
Write-Host ""

# 1. Mettre Ã  jour les index du journal
Write-Section "Mise Ã  jour des index du journal"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_search_simple.py --rebuild"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_rag_simple.py --rebuild --export"

# 2. Synchroniser avec Augment Memories
Write-Section "Synchronisation avec Augment Memories"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\augment_integration.py export"

# 3. Extraire les insights pour la documentation
Write-Section "Extraction des insights pour la documentation"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\docs_integration.py extract"

# 4. Mettre Ã  jour les liens entre le journal et la documentation
Write-Section "Mise Ã  jour des liens entre le journal et la documentation"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\docs_integration.py update"

# 5. VÃ©rifier si le serveur MCP est en cours d'exÃ©cution
Write-Section "VÃ©rification du serveur MCP"
$mcpRunning = Get-Process | Where-Object { $_.ProcessName -eq "mcp-server" -or $_.ProcessName -eq "node" -and $_.CommandLine -like "*mcp-server*" }

if ($mcpRunning) {
    Write-Host "Le serveur MCP est dÃ©jÃ  en cours d'exÃ©cution." -ForegroundColor Green
} else {
    Write-Host "Le serveur MCP n'est pas en cours d'exÃ©cution." -ForegroundColor Yellow
    Write-Host "Pour dÃ©marrer le serveur MCP, exÃ©cutez: .\development\scripts\cmd\start-journal-mcp.ps1" -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Synchronisation terminÃ©e"
Write-Host "Le journal de bord a Ã©tÃ© synchronisÃ© avec succÃ¨s avec l'Ã©cosystÃ¨me!" -ForegroundColor Green
Write-Host ""
Write-Host "RÃ©sumÃ© des actions effectuÃ©es:"
Write-Host "1. Les index du journal ont Ã©tÃ© mis Ã  jour"
Write-Host "2. Les entrÃ©es du journal ont Ã©tÃ© exportÃ©es vers Augment Memories"
Write-Host "3. Les insights techniques ont Ã©tÃ© extraits pour la documentation"
Write-Host "4. Les liens entre le journal et la documentation ont Ã©tÃ© mis Ã  jour"
Write-Host ""
Write-Host "Pour une intÃ©gration complÃ¨te:"
Write-Host "- Assurez-vous que le serveur MCP est en cours d'exÃ©cution"
Write-Host "- Configurez Augment pour utiliser les memories exportÃ©es"
Write-Host "- Consultez la documentation gÃ©nÃ©rÃ©e dans le dossier docs/documentation"
Write-Host ""
Write-Host "Pour automatiser cette synchronisation, vous pouvez ajouter ce script Ã  une tÃ¢che planifiÃ©e Windows."
