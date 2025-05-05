# Script PowerShell pour synchroniser le journal de bord avec l'ÃƒÂ©cosystÃƒÂ¨me (Augment, MCP, Documentation)

# Chemin absolu vers le rÃƒÂ©pertoire du projet
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

# Fonction pour exÃƒÂ©cuter une commande et afficher son rÃƒÂ©sultat
function Invoke-CommandWithOutput {
    param (
        [string]$Command,
        [string]$Arguments
    )

    Write-Host "ExÃƒÂ©cution de: $Command $Arguments" -ForegroundColor Gray

    try {
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "Commande exÃƒÂ©cutÃƒÂ©e avec succÃƒÂ¨s." -ForegroundColor Green
        } else {
            Write-Host "La commande a ÃƒÂ©chouÃƒÂ© avec le code de sortie $($process.ExitCode)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'exÃƒÂ©cution de la commande: $_" -ForegroundColor Red
    }
}

# Afficher un message d'introduction
Write-Host "Synchronisation du journal de bord avec l'ÃƒÂ©cosystÃƒÂ¨me" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Ce script va synchroniser le journal de bord avec:"
Write-Host "1. Augment Memories"
Write-Host "2. MCP (Model Context Protocol)"
Write-Host "3. Documentation"
Write-Host ""

# 1. Mettre ÃƒÂ  jour les index du journal
Write-Section "Mise ÃƒÂ  jour des index du journal"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_search_simple.py --rebuild"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\journal_rag_simple.py --rebuild --export"

# 2. Synchroniser avec Augment Memories
Write-Section "Synchronisation avec Augment Memories"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\augment_integration.py export"

# 3. Extraire les insights pour la documentation
Write-Section "Extraction des insights pour la documentation"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\docs_integration.py extract"

# 4. Mettre ÃƒÂ  jour les liens entre le journal et la documentation
Write-Section "Mise ÃƒÂ  jour des liens entre le journal et la documentation"
Invoke-CommandWithOutput -Command "python" -Arguments "$PythonScriptsDir\docs_integration.py update"

# 5. VÃƒÂ©rifier si le serveur MCP est en cours d'exÃƒÂ©cution
Write-Section "VÃƒÂ©rification du serveur MCP"
$mcpRunning = Get-Process | Where-Object { $_.ProcessName -eq "mcp-server" -or $_.ProcessName -eq "node" -and $_.CommandLine -like "*mcp-server*" }

if ($mcpRunning) {
    Write-Host "Le serveur MCP est dÃƒÂ©jÃƒÂ  en cours d'exÃƒÂ©cution." -ForegroundColor Green
} else {
    Write-Host "Le serveur MCP n'est pas en cours d'exÃƒÂ©cution." -ForegroundColor Yellow
    Write-Host "Pour dÃƒÂ©marrer le serveur MCP, exÃƒÂ©cutez: .\development\scripts\cmd\start-journal-mcp.ps1" -ForegroundColor Yellow
}

# Afficher un message de conclusion
Write-Section "Synchronisation terminÃƒÂ©e"
Write-Host "Le journal de bord a ÃƒÂ©tÃƒÂ© synchronisÃƒÂ© avec succÃƒÂ¨s avec l'ÃƒÂ©cosystÃƒÂ¨me!" -ForegroundColor Green
Write-Host ""
Write-Host "RÃƒÂ©sumÃƒÂ© des actions effectuÃƒÂ©es:"
Write-Host "1. Les index du journal ont ÃƒÂ©tÃƒÂ© mis ÃƒÂ  jour"
Write-Host "2. Les entrÃƒÂ©es du journal ont ÃƒÂ©tÃƒÂ© exportÃƒÂ©es vers Augment Memories"
Write-Host "3. Les insights techniques ont ÃƒÂ©tÃƒÂ© extraits pour la documentation"
Write-Host "4. Les liens entre le journal et la documentation ont ÃƒÂ©tÃƒÂ© mis ÃƒÂ  jour"
Write-Host ""
Write-Host "Pour une intÃƒÂ©gration complÃƒÂ¨te:"
Write-Host "- Assurez-vous que le serveur MCP est en cours d'exÃƒÂ©cution"
Write-Host "- Configurez Augment pour utiliser les memories exportÃƒÂ©es"
Write-Host "- Consultez la documentation gÃƒÂ©nÃƒÂ©rÃƒÂ©e dans le dossier docs/documentation"
Write-Host ""
Write-Host "Pour automatiser cette synchronisation, vous pouvez ajouter ce script ÃƒÂ  une tÃƒÂ¢che planifiÃƒÂ©e Windows."
