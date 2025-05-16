# Script de vérification pour l'intégration MCP avec n8n
# Ce script vérifie la structure des fichiers et la syntaxe du code

# Configuration
$rootDir = Join-Path $PSScriptRoot ".."
$clientNodeDir = Join-Path $rootDir "mcp-client"
$memoryNodeDir = Join-Path $rootDir "mcp-memory"
$workflowsDir = Join-Path $rootDir ".." "workflows" "examples"

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [string]$Message
    )
    
    Write-Host $Message -ForegroundColor Cyan
}

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [string]$Message
    )
    
    Write-Host $Message -ForegroundColor Green
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [string]$Message
    )
    
    Write-Host "ERREUR: $Message" -ForegroundColor Red
}

# Fonction pour vérifier l'existence d'un fichier
function Test-FileExists {
    param (
        [string]$FilePath,
        [string]$Description
    )
    
    Write-Info "Vérification de $Description ($FilePath)..."
    
    if (Test-Path $FilePath) {
        Write-Success "OK: $Description existe."
        return $true
    }
    else {
        Write-Error "$Description n'existe pas."
        return $false
    }
}

# Fonction pour vérifier la syntaxe d'un fichier JSON
function Test-JsonSyntax {
    param (
        [string]$FilePath,
        [string]$Description
    )
    
    Write-Info "Vérification de la syntaxe JSON de $Description ($FilePath)..."
    
    if (Test-Path $FilePath) {
        try {
            $null = Get-Content $FilePath -Raw | ConvertFrom-Json
            Write-Success "OK: La syntaxe JSON de $Description est valide."
            return $true
        }
        catch {
            Write-Error "La syntaxe JSON de $Description n'est pas valide: $_"
            return $false
        }
    }
    else {
        Write-Error "$Description n'existe pas."
        return $false
    }
}

# Fonction pour vérifier la syntaxe d'un fichier TypeScript
function Test-TypeScriptSyntax {
    param (
        [string]$FilePath,
        [string]$Description
    )
    
    Write-Info "Vérification de la syntaxe TypeScript de $Description ($FilePath)..."
    
    if (Test-Path $FilePath) {
        # Vérifier si le fichier contient des erreurs de syntaxe évidentes
        $content = Get-Content $FilePath -Raw
        
        # Vérifier les accolades non fermées
        $openBraces = ($content | Select-String -Pattern "{" -AllMatches).Matches.Count
        $closeBraces = ($content | Select-String -Pattern "}" -AllMatches).Matches.Count
        
        if ($openBraces -ne $closeBraces) {
            Write-Error "La syntaxe TypeScript de $Description n'est pas valide: Accolades non équilibrées ($openBraces ouvertes, $closeBraces fermées)."
            return $false
        }
        
        # Vérifier les parenthèses non fermées
        $openParens = ($content | Select-String -Pattern "\(" -AllMatches).Matches.Count
        $closeParens = ($content | Select-String -Pattern "\)" -AllMatches).Matches.Count
        
        if ($openParens -ne $closeParens) {
            Write-Error "La syntaxe TypeScript de $Description n'est pas valide: Parenthèses non équilibrées ($openParens ouvertes, $closeParens fermées)."
            return $false
        }
        
        Write-Success "OK: La syntaxe TypeScript de $Description semble valide."
        return $true
    }
    else {
        Write-Error "$Description n'existe pas."
        return $false
    }
}

# Fonction pour vérifier le nœud MCP Client
function Test-MCPClientNode {
    Write-Info "`n=== Vérification du nœud MCP Client ==="
    
    $nodeFile = Join-Path $clientNodeDir "MCP.node.ts"
    $credentialsFile = Join-Path $clientNodeDir "MCPClientApi.credentials.ts"
    $nodeJsonFile = Join-Path $clientNodeDir "node.json"
    $iconFile = Join-Path $clientNodeDir "mcp.svg"
    
    $nodeFileOk = Test-FileExists -FilePath $nodeFile -Description "Fichier du nœud MCP Client"
    $credentialsFileOk = Test-FileExists -FilePath $credentialsFile -Description "Fichier des credentials MCP Client"
    $nodeJsonFileOk = Test-JsonSyntax -FilePath $nodeJsonFile -Description "Fichier node.json du nœud MCP Client"
    $iconFileOk = Test-FileExists -FilePath $iconFile -Description "Icône du nœud MCP Client"
    
    if ($nodeFileOk) {
        Test-TypeScriptSyntax -FilePath $nodeFile -Description "Fichier du nœud MCP Client"
    }
    
    if ($credentialsFileOk) {
        Test-TypeScriptSyntax -FilePath $credentialsFile -Description "Fichier des credentials MCP Client"
    }
    
    if ($nodeFileOk -and $credentialsFileOk -and $nodeJsonFileOk -and $iconFileOk) {
        Write-Success "Le nœud MCP Client est correctement configuré."
        return $true
    }
    else {
        Write-Error "Le nœud MCP Client n'est pas correctement configuré."
        return $false
    }
}

# Fonction pour vérifier le nœud MCP Memory
function Test-MCPMemoryNode {
    Write-Info "`n=== Vérification du nœud MCP Memory ==="
    
    $nodeFile = Join-Path $memoryNodeDir "MCPMemory.node.ts"
    $nodeJsonFile = Join-Path $memoryNodeDir "node.json"
    $iconFile = Join-Path $memoryNodeDir "memory.svg"
    
    $nodeFileOk = Test-FileExists -FilePath $nodeFile -Description "Fichier du nœud MCP Memory"
    $nodeJsonFileOk = Test-JsonSyntax -FilePath $nodeJsonFile -Description "Fichier node.json du nœud MCP Memory"
    $iconFileOk = Test-FileExists -FilePath $iconFile -Description "Icône du nœud MCP Memory"
    
    if ($nodeFileOk) {
        Test-TypeScriptSyntax -FilePath $nodeFile -Description "Fichier du nœud MCP Memory"
    }
    
    if ($nodeFileOk -and $nodeJsonFileOk -and $iconFileOk) {
        Write-Success "Le nœud MCP Memory est correctement configuré."
        return $true
    }
    else {
        Write-Error "Le nœud MCP Memory n'est pas correctement configuré."
        return $false
    }
}

# Fonction pour vérifier les workflows d'exemple
function Test-ExampleWorkflows {
    Write-Info "`n=== Vérification des workflows d'exemple ==="
    
    $memoryWorkflowFile = Join-Path $workflowsDir "mcp-memory-management.json"
    $emailWorkflowFile = Join-Path $workflowsDir "mcp-email-generation.json"
    
    $memoryWorkflowOk = Test-JsonSyntax -FilePath $memoryWorkflowFile -Description "Workflow de gestion des mémoires"
    $emailWorkflowOk = Test-JsonSyntax -FilePath $emailWorkflowFile -Description "Workflow de génération d'emails"
    
    if ($memoryWorkflowOk -and $emailWorkflowOk) {
        Write-Success "Les workflows d'exemple sont correctement configurés."
        return $true
    }
    else {
        Write-Error "Les workflows d'exemple ne sont pas correctement configurés."
        return $false
    }
}

# Fonction pour vérifier le package.json
function Test-PackageJson {
    Write-Info "`n=== Vérification du package.json ==="
    
    $packageJsonFile = Join-Path $rootDir "package.json"
    
    $packageJsonOk = Test-JsonSyntax -FilePath $packageJsonFile -Description "Fichier package.json"
    
    if ($packageJsonOk) {
        # Vérifier que les nœuds sont correctement référencés
        $packageJson = Get-Content $packageJsonFile -Raw | ConvertFrom-Json
        
        if ($packageJson.n8n -and $packageJson.n8n.nodes -and $packageJson.n8n.credentials) {
            Write-Success "Le fichier package.json est correctement configuré."
            return $true
        }
        else {
            Write-Error "Le fichier package.json ne référence pas correctement les nœuds et les credentials."
            return $false
        }
    }
    else {
        return $false
    }
}

# Fonction principale pour vérifier l'intégration MCP
function Test-MCPIntegration {
    Write-Info "Démarrage de la vérification de l'intégration MCP avec n8n...`n"
    
    $clientNodeOk = Test-MCPClientNode
    $memoryNodeOk = Test-MCPMemoryNode
    $workflowsOk = Test-ExampleWorkflows
    $packageJsonOk = Test-PackageJson
    
    Write-Info "`n=== Résumé de la vérification ==="
    
    if ($clientNodeOk) {
        Write-Success "✓ Nœud MCP Client: OK"
    }
    else {
        Write-Error "✗ Nœud MCP Client: NOK"
    }
    
    if ($memoryNodeOk) {
        Write-Success "✓ Nœud MCP Memory: OK"
    }
    else {
        Write-Error "✗ Nœud MCP Memory: NOK"
    }
    
    if ($workflowsOk) {
        Write-Success "✓ Workflows d'exemple: OK"
    }
    else {
        Write-Error "✗ Workflows d'exemple: NOK"
    }
    
    if ($packageJsonOk) {
        Write-Success "✓ Configuration package.json: OK"
    }
    else {
        Write-Error "✗ Configuration package.json: NOK"
    }
    
    if ($clientNodeOk -and $memoryNodeOk -and $workflowsOk -and $packageJsonOk) {
        Write-Success "`nL'intégration MCP avec n8n est correctement configurée et prête à être utilisée."
    }
    else {
        Write-Error "`nL'intégration MCP avec n8n présente des problèmes qui doivent être corrigés."
    }
}

# Exécuter la vérification
Test-MCPIntegration
