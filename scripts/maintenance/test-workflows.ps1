# Script pour tester les workflows n8n avec la nouvelle structure

Write-Host "=== Test des workflows n8n avec la nouvelle structure ===" -ForegroundColor Cyan

# Verifier si n8n est installe
try {
    $n8nVersion = npx n8n --version
    Write-Host "n8n version $n8nVersion detectee" -ForegroundColor Green
} catch {
    Write-Host "n8n n'est pas installe ou n'est pas accessible via npx" -ForegroundColor Red
    Write-Host "Veuillez installer n8n ou verifier votre installation"
    exit 1
}

# Verifier si les fichiers batch MCP existent
$mcpFiles = @(
    ".\src\mcp\batch\mcp-standard.cmd",
    ".\src\mcp\batch\mcp-notion.cmd",
    ".\src\mcp\batch\gateway.exe.cmd",
    ".\src\mcp\batch\mcp-git-ingest.cmd"
)

$allFilesExist = $true
foreach ($file in $mcpFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "Le fichier $file n'existe pas" -ForegroundColor Red
        $allFilesExist = $false
    } else {
        Write-Host "Le fichier $file existe" -ForegroundColor Green
    }
}

if (-not $allFilesExist) {
    Write-Host "Certains fichiers batch MCP sont manquants. Verifiez la structure des dossiers." -ForegroundColor Red
    exit 1
}

# Verifier si les workflows existent
$workflowFiles = Get-ChildItem -Path ".\src\workflows" -Filter "*.json" -File

if ($workflowFiles.Count -eq 0) {
    Write-Host "Aucun workflow n'a ete trouve dans le dossier src/workflows" -ForegroundColor Red
    exit 1
} else {
    Write-Host "$($workflowFiles.Count) workflows trouves dans le dossier src/workflows" -ForegroundColor Green
    
    foreach ($file in $workflowFiles) {
        Write-Host "- $($file.Name)" -ForegroundColor Green
    }
}

# Definir les variables d'environnement
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')
Write-Host "Variable d'environnement N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE definie" -ForegroundColor Green

# Tester un workflow specifique
$testWorkflow = "test-mcp-git-ingest-workflow.json"
$testWorkflowPath = ".\src\workflows\$testWorkflow"

if (Test-Path $testWorkflowPath) {
    Write-Host "`nTest du workflow $testWorkflow..." -ForegroundColor Cyan
    
    # Importer le workflow dans n8n
    Write-Host "Importation du workflow dans n8n..." -ForegroundColor Yellow
    
    # Executer le workflow
    Write-Host "Pour executer le workflow, suivez ces etapes:" -ForegroundColor Yellow
    Write-Host "1. Demarrez n8n avec la commande: .\tools\start-n8n-mcp.cmd" -ForegroundColor Yellow
    Write-Host "2. Accedez a http://localhost:5678 dans votre navigateur" -ForegroundColor Yellow
    Write-Host "3. Importez le workflow $testWorkflow" -ForegroundColor Yellow
    Write-Host "4. Executez le workflow et verifiez les resultats" -ForegroundColor Yellow
    
    # Demander a l'utilisateur s'il souhaite demarrer n8n
    Write-Host "`nSouhaitez-vous demarrer n8n maintenant ? (O/N)" -ForegroundColor Yellow
    $startN8n = Read-Host
    
    if ($startN8n -eq "O" -or $startN8n -eq "o") {
        Write-Host "Demarrage de n8n..." -ForegroundColor Green
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", ".\tools\start-n8n-mcp.cmd"
    } else {
        Write-Host "Vous pouvez demarrer n8n plus tard avec la commande: .\tools\start-n8n-mcp.cmd" -ForegroundColor Yellow
    }
} else {
    Write-Host "Le workflow de test $testWorkflow n'existe pas dans le dossier src/workflows" -ForegroundColor Red
}

Write-Host "`n=== Test termine ===" -ForegroundColor Cyan
