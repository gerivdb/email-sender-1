# Script pour organiser les scripts en sous-dossiers sémantiques
# Ce script crée une structure de sous-dossiers et déplace les scripts dans les dossiers appropriés

# Définition des sous-dossiers à créer
$scriptFolders = @(
    # Maintenance
    "maintenance\repo",
    "maintenance\encoding",
    "maintenance\cleanup",
    
    # Setup
    "setup\mcp",
    "setup\env",
    
    # Workflow
    "workflow\validation",
    "workflow\testing",
    "workflow\monitoring",
    
    # Utils
    "utils\markdown",
    "utils\json",
    "utils\automation"
)

# Création des sous-dossiers
Write-Host "Création des sous-dossiers pour les scripts..." -ForegroundColor Cyan
foreach ($folder in $scriptFolders) {
    $path = Join-Path -Path "scripts" -ChildPath $folder
    if (-not (Test-Path -Path $path)) {
        Write-Host "Création du dossier: $path" -ForegroundColor Yellow
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Définition des règles de déplacement des fichiers
$fileRules = @(
    # Maintenance - Repo
    @{
        Pattern = "check-repo-*.ps1", "organize-repo*.ps1", "create-folders.ps1"
        Destination = "maintenance\repo"
    },
    # Maintenance - Encoding
    @{
        Pattern = "fix-encoding*.ps1", "convert_encoding*.ps1"
        Destination = "maintenance\encoding"
    },
    # Maintenance - Cleanup
    @{
        Pattern = "cleanup*.ps1", "clean-*.ps1", "move-*.ps1"
        Destination = "maintenance\cleanup"
    },
    
    # Setup - MCP
    @{
        Pattern = "setup-mcp*.ps1", "configure-mcp*.ps1"
        Destination = "setup\mcp"
    },
    # Setup - Env
    @{
        Pattern = "setup-environment.ps1"
        Destination = "setup\env"
    },
    
    # Workflow - Validation
    @{
        Pattern = "check_n8n_workflows.py", "validate_json.py", "check_expressions.py"
        Destination = "workflow\validation"
    },
    # Workflow - Testing
    @{
        Pattern = "simulate-workflow*.ps1", "test-workflow*.ps1"
        Destination = "workflow\testing"
    },
    # Workflow - Monitoring
    @{
        Pattern = "verify-*.ps1", "check-workflow*.ps1"
        Destination = "workflow\monitoring"
    },
    
    # Utils - Markdown
    @{
        Pattern = "*markdown*.py", "fix_markdown*.py", "batch_fix_markdown.py"
        Destination = "utils\markdown"
    },
    # Utils - JSON
    @{
        Pattern = "*json*.py"
        Destination = "utils\json"
    },
    # Utils - Automation
    @{
        Pattern = "auto-*.ps1", "setup-auto-*.ps1"
        Destination = "utils\automation"
    }
)

# Déplacement des fichiers selon les règles
Write-Host "`nDéplacement des fichiers selon les règles..." -ForegroundColor Cyan
foreach ($rule in $fileRules) {
    foreach ($pattern in $rule.Pattern) {
        $files = Get-ChildItem -Path "scripts" -Filter $pattern -File -Recurse | 
                 Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
        
        foreach ($file in $files) {
            $destination = Join-Path -Path "scripts" -ChildPath $rule.Destination
            $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
            
            if (-not (Test-Path -Path $destinationFile)) {
                Write-Host "Déplacement de $($file.Name) vers $($rule.Destination)" -ForegroundColor Yellow
                Move-Item -Path $file.FullName -Destination $destination -Force
            }
        }
    }
}

# Organisation des workflows
Write-Host "`nOrganisation des workflows..." -ForegroundColor Cyan
$workflowFolders = @(
    "workflows\core",
    "workflows\config",
    "workflows\phases",
    "workflows\testing"
)

foreach ($folder in $workflowFolders) {
    if (-not (Test-Path -Path $folder)) {
        Write-Host "Création du dossier: $folder" -ForegroundColor Yellow
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Déplacement des workflows
$workflowRules = @(
    @{
        Pattern = "EMAIL_SENDER_1*.json"
        Destination = "workflows\core"
    },
    @{
        Pattern = "EMAIL_SENDER_CONFIG*.json"
        Destination = "workflows\config"
    },
    @{
        Pattern = "EMAIL_SENDER_PHASE*.json"
        Destination = "workflows\phases"
    },
    @{
        Pattern = "test-*.json"
        Destination = "workflows\testing"
    }
)

foreach ($rule in $workflowRules) {
    foreach ($pattern in $rule.Pattern) {
        $files = Get-ChildItem -Path "workflows" -Filter $pattern -File
        
        foreach ($file in $files) {
            $destination = $rule.Destination
            $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
            
            if (-not (Test-Path -Path $destinationFile)) {
                Write-Host "Déplacement de $($file.Name) vers $($rule.Destination)" -ForegroundColor Yellow
                Move-Item -Path $file.FullName -Destination $destination -Force
            }
        }
    }
}

# Organisation des logs
Write-Host "`nOrganisation des logs..." -ForegroundColor Cyan
$logFolders = @(
    "logs\daily",
    "logs\weekly",
    "logs\monthly",
    "logs\scripts",
    "logs\workflows"
)

foreach ($folder in $logFolders) {
    if (-not (Test-Path -Path $folder)) {
        Write-Host "Création du dossier: $folder" -ForegroundColor Yellow
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Déplacement des logs existants
$logFiles = Get-ChildItem -Path "logs" -File
foreach ($file in $logFiles) {
    if ($file.Name -like "*workflow*" -or $file.Name -like "*n8n*") {
        $destination = "logs\workflows"
    } else {
        $destination = "logs\scripts"
    }
    
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "Déplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

Write-Host "`nOrganisation des scripts et dossiers terminée avec succès!" -ForegroundColor Green
