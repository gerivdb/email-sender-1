# Script de démarrage pour le projet EMAIL_SENDER_1
# ----------------------------------------------

# 1. Définition des variables d'environnement
$env:EMAIL_SENDER_ROOT = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$env:MCP_SERVER_PORT = "3000"
$env:N8N_PORT = "5678"
$env:QDRANT_PORT = "6333"
$env:OPENROUTER_API_KEY = $env:OPENROUTER_API_KEY # Préserve la clé API si déjà définie

# 2. Configuration des chemins et des alias
$devScriptsPath = Join-Path $env:EMAIL_SENDER_ROOT "development\scripts"
$modesPath = Join-Path $devScriptsPath "modes"
$modulesPath = Join-Path $modesPath "modules"
$mcpPath = Join-Path $env:EMAIL_SENDER_ROOT "projet\mcp"
$reportsPath = Join-Path $env:EMAIL_SENDER_ROOT "reports"

# Créer le dossier reports s'il n'existe pas
if (-not (Test-Path $reportsPath)) {
    New-Item -Path $reportsPath -ItemType Directory -Force | Out-Null
}

# 3. Charger les modules personnalisés
try {
    # Importer le module FileLengthAnalyzer
    $fileLengthAnalyzerPath = Join-Path $modulesPath "FileLengthAnalyzer"
    if (Test-Path $fileLengthAnalyzerPath) {
        Import-Module $fileLengthAnalyzerPath -Force -ErrorAction Stop
        Write-Host "✓ Module FileLengthAnalyzer chargé" -ForegroundColor Green
    } else {
        Write-Host "✗ Module FileLengthAnalyzer non trouvé" -ForegroundColor Yellow
    }

    # Importer d'autres modules si nécessaire
    # Import-Module ...
} catch {
    Write-Host "✗ Erreur lors du chargement des modules: $_" -ForegroundColor Red
}

# 4. Définir des fonctions utiles
function Start-EmailSenderDashboard {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                EMAIL SENDER 1 - DASHBOARD               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Vérifier l'état des services
    $n8nRunning = Test-NetConnection -ComputerName localhost -Port $env:N8N_PORT -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $mcpRunning = Test-NetConnection -ComputerName localhost -Port $env:MCP_SERVER_PORT -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $qdrantRunning = Test-NetConnection -ComputerName localhost -Port $env:QDRANT_PORT -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

    Write-Host "SERVICES:" -ForegroundColor White
    Write-Host "  n8n:    " -NoNewline
    if ($n8nRunning) { Write-Host "ACTIF" -ForegroundColor Green } else { Write-Host "INACTIF" -ForegroundColor Red }

    Write-Host "  MCP:    " -NoNewline
    if ($mcpRunning) { Write-Host "ACTIF" -ForegroundColor Green } else { Write-Host "INACTIF" -ForegroundColor Red }

    Write-Host "  Qdrant: " -NoNewline
    if ($qdrantRunning) { Write-Host "ACTIF" -ForegroundColor Green } else { Write-Host "INACTIF" -ForegroundColor Red }

    # Vérifier l'état Git
    try {
        Push-Location $env:EMAIL_SENDER_ROOT
        $gitStatus = git status --porcelain
        $hasChanges = $gitStatus.Length -gt 0

        Write-Host "`nGIT STATUS:" -ForegroundColor White
        if ($hasChanges) {
            Write-Host "  Modifications non commitées: " -NoNewline
            Write-Host "OUI" -ForegroundColor Yellow
            Write-Host "  Utilisez 'esgit' pour voir les détails"
        } else {
            Write-Host "  Dépôt propre: " -NoNewline
            Write-Host "OUI" -ForegroundColor Green
        }
        Pop-Location
    } catch {
        Write-Host "`nGIT STATUS:" -ForegroundColor White
        Write-Host "  Erreur lors de la vérification Git: $_" -ForegroundColor Red
    }

    Write-Host "`nCOMMANDES RAPIDES:" -ForegroundColor White
    Write-Host "  escheck [path]      - Analyser la longueur des fichiers"
    Write-Host "  esmcp              - Démarrer le serveur MCP"
    Write-Host "  esn8n              - Démarrer n8n"
    Write-Host "  esqdrant           - Démarrer Qdrant"
    Write-Host "  esgit              - Afficher le statut Git détaillé"
    Write-Host "  esverbs            - Vérifier les verbes non approuvés"
    Write-Host "  esdashboard        - Afficher ce tableau de bord"
    Write-Host "  eshelp             - Afficher l'aide complète"
    Write-Host ""
}

function Show-EmailSenderHelp {
    Write-Host "EMAIL SENDER 1 - AIDE" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "COMMANDES DISPONIBLES:" -ForegroundColor White
    Write-Host "  escheck [path] [reportPath]  - Analyser la longueur des fichiers"
    Write-Host "    path: Chemin à analyser (défaut: répertoire courant)"
    Write-Host "    reportPath: Chemin du rapport (défaut: reports/file-lengths-report.md)"
    Write-Host ""
    Write-Host "  esmcp                       - Démarrer le serveur MCP"
    Write-Host "  esn8n                       - Démarrer n8n"
    Write-Host "  esqdrant                    - Démarrer Qdrant"
    Write-Host "  esgit                       - Afficher le statut Git détaillé"
    Write-Host "  esverbs                     - Vérifier les verbes non approuvés"
    Write-Host "  esdashboard                 - Afficher le tableau de bord"
    Write-Host "  eshelp                      - Afficher cette aide"
    Write-Host ""
    Write-Host "VARIABLES D'ENVIRONNEMENT:" -ForegroundColor White
    Write-Host "  EMAIL_SENDER_ROOT: $env:EMAIL_SENDER_ROOT"
    Write-Host "  MCP_SERVER_PORT:   $env:MCP_SERVER_PORT"
    Write-Host "  N8N_PORT:          $env:N8N_PORT"
    Write-Host "  QDRANT_PORT:       $env:QDRANT_PORT"
    Write-Host ""
}

# 5. Définir des alias pour les commandes fréquentes
function Invoke-FileLengthCheck {
    param (
        [string]$Path = (Get-Location).Path,
        [string]$ReportPath = "reports/file-lengths-report.md"
    )

    $checkScript = Join-Path $modesPath "Check-FileLengths.ps1"
    if (Test-Path $checkScript) {
        & $checkScript -Path $Path -ReportPath $ReportPath -Verbose
    } else {
        Write-Host "✗ Script Check-FileLengths.ps1 non trouvé" -ForegroundColor Red
    }
}

function Start-MCPServer {
    $mcpScript = Join-Path $mcpPath "scripts\start-git-ingest-mcp.ps1"
    if (Test-Path $mcpScript) {
        & $mcpScript
    } else {
        Write-Host "✗ Script de démarrage MCP non trouvé" -ForegroundColor Red
    }
}

function Start-N8NServer {
    Write-Host "Démarrage de n8n sur le port $env:N8N_PORT..." -ForegroundColor Cyan
    Start-Process "n8n" -ArgumentList "start" -NoNewWindow
}

function Start-QdrantServer {
    Write-Host "Démarrage de Qdrant via Docker..." -ForegroundColor Cyan
    docker run -d -p $env:QDRANT_PORT`:6333 -v qdrant_storage:/qdrant/storage qdrant/qdrant
}

function Show-GitStatus {
    Push-Location $env:EMAIL_SENDER_ROOT
    Write-Host "STATUS GIT - EMAIL SENDER 1" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan

    # Afficher le statut
    Write-Host "`nStatut des fichiers:" -ForegroundColor White
    git status

    # Afficher les derniers commits
    Write-Host "`nDerniers commits:" -ForegroundColor White
    git log --oneline -n 5

    # Afficher les branches
    Write-Host "`nBranches:" -ForegroundColor White
    git branch

    Pop-Location
}

function Test-UnapprovedVerbs {
    param (
        [string]$Path = $env:EMAIL_SENDER_ROOT
    )

    Write-Host "Recherche de verbes non approuvés dans les scripts PowerShell..." -ForegroundColor Cyan

    $results = @()
    $psFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1" -ErrorAction SilentlyContinue

    foreach ($file in $psFiles) {
        $content = Get-Content -Path $file.FullName -Raw

        # Rechercher les définitions de fonctions avec des verbes non approuvés
        $pattern = 'function\s+((?<verb>[A-Z][a-z]+)-[A-Za-z]+)'
        $regexMatches = [regex]::Matches($content, $pattern)

        foreach ($match in $regexMatches) {
            $verb = $match.Groups['verb'].Value

            # Vérifier si le verbe est approuvé
            $isApproved = Get-Verb | Where-Object { $_.Verb -eq $verb }

            if (-not $isApproved) {
                $results += [PSCustomObject]@{
                    File     = $file.FullName.Replace($Path, '').TrimStart('\/')
                    Verb     = $verb
                    Function = $match.Groups[1].Value
                    Line     = ($content.Substring(0, $match.Index).Split("`n")).Count
                }
            }
        }
    }

    if ($results.Count -gt 0) {
        Write-Host "`nVerbes non approuvés trouvés:" -ForegroundColor Yellow
        $results | Format-Table -AutoSize

        Write-Host "`nSuggestions de remplacement:" -ForegroundColor Cyan
        foreach ($result in $results) {
            $verb = $result.Verb
            $suggestions = switch ($verb) {
                "Ensure" { "New, Set, Confirm" }
                "Process" { "Update, Invoke, Convert" }
                "Count" { "Measure" }
                default { "Get, Set, New, Remove" }
            }
            Write-Host "  $($result.Function) -> Remplacer '$verb' par l'un de ces verbes: $suggestions"
        }
    } else {
        Write-Host "`nAucun verbe non approuvé trouvé. Excellent!" -ForegroundColor Green
    }
}

# Créer les alias
Set-Alias -Name escheck -Value Invoke-FileLengthCheck
Set-Alias -Name esmcp -Value Start-MCPServer
Set-Alias -Name esn8n -Value Start-N8NServer
Set-Alias -Name esqdrant -Value Start-QdrantServer
Set-Alias -Name esgit -Value Show-GitStatus
Set-Alias -Name esverbs -Value Test-UnapprovedVerbs
Set-Alias -Name esdashboard -Value Start-EmailSenderDashboard
Set-Alias -Name eshelp -Value Show-EmailSenderHelp

# 6. Afficher le tableau de bord au démarrage
Start-EmailSenderDashboard

# Message de bienvenue
Write-Host "Environnement EMAIL_SENDER_1 initialisé" -ForegroundColor Green
Write-Host "Tapez 'eshelp' pour afficher l'aide complète" -ForegroundColor Cyan
