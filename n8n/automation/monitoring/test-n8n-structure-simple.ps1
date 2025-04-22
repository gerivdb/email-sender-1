# Script de test pour vérifier la structure n8n

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"

# Vérifier la structure des dossiers
Write-Host "`n=== Vérification de la structure des dossiers ===" -ForegroundColor Cyan
$foldersOk = $true

# Vérifier si le dossier n8n existe
if (Test-Path -Path $n8nPath -PathType Container) {
    Write-Host "Le dossier n8n existe." -ForegroundColor Green
} else {
    Write-Host "Le dossier n8n n'existe pas: $n8nPath" -ForegroundColor Red
    $foldersOk = $false
}

# Vérifier si le dossier core existe
$corePath = Join-Path -Path $n8nPath -ChildPath "core"
if (Test-Path -Path $corePath -PathType Container) {
    Write-Host "Le dossier core existe." -ForegroundColor Green
} else {
    Write-Host "Le dossier core n'existe pas: $corePath" -ForegroundColor Red
    $foldersOk = $false
}

# Vérifier si le dossier core/workflows existe
$workflowsPath = Join-Path -Path $corePath -ChildPath "workflows"
if (Test-Path -Path $workflowsPath -PathType Container) {
    Write-Host "Le dossier core/workflows existe." -ForegroundColor Green
} else {
    Write-Host "Le dossier core/workflows n'existe pas: $workflowsPath" -ForegroundColor Red
    $foldersOk = $false
}

# Vérifier si le dossier core/credentials existe
$credentialsPath = Join-Path -Path $corePath -ChildPath "credentials"
if (Test-Path -Path $credentialsPath -PathType Container) {
    Write-Host "Le dossier core/credentials existe." -ForegroundColor Green
} else {
    Write-Host "Le dossier core/credentials n'existe pas: $credentialsPath" -ForegroundColor Red
    $foldersOk = $false
}

# Vérifier si le dossier integrations existe
$integrationsPath = Join-Path -Path $n8nPath -ChildPath "integrations"
if (Test-Path -Path $integrationsPath -PathType Container) {
    Write-Host "Le dossier integrations existe." -ForegroundColor Green
} else {
    Write-Host "Le dossier integrations n'existe pas: $integrationsPath" -ForegroundColor Red
    $foldersOk = $false
}

# Vérifier si le dossier automation existe
$automationPath = Join-Path -Path $n8nPath -ChildPath "automation"
if (Test-Path -Path $automationPath -PathType Container) {
    Write-Host "Le dossier automation existe." -ForegroundColor Green
} else {
    Write-Host "Le dossier automation n'existe pas: $automationPath" -ForegroundColor Red
    $foldersOk = $false
}

# Vérifier si le dossier docs existe
$docsPath = Join-Path -Path $n8nPath -ChildPath "docs"
if (Test-Path -Path $docsPath -PathType Container) {
    Write-Host "Le dossier docs existe." -ForegroundColor Green
} else {
    Write-Host "Le dossier docs n'existe pas: $docsPath" -ForegroundColor Red
    $foldersOk = $false
}

# Vérifier les fichiers essentiels
Write-Host "`n=== Vérification des fichiers essentiels ===" -ForegroundColor Cyan
$filesOk = $true

# Vérifier si le fichier n8n-config.json existe
$configPath = Join-Path -Path $corePath -ChildPath "n8n-config.json"
if (Test-Path -Path $configPath -PathType Leaf) {
    Write-Host "Le fichier n8n-config.json existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier n8n-config.json n'existe pas: $configPath" -ForegroundColor Red
    $filesOk = $false
}

# Vérifier si le fichier .env existe
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"
if (Test-Path -Path $envPath -PathType Leaf) {
    Write-Host "Le fichier .env existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier .env n'existe pas: $envPath" -ForegroundColor Red
    $filesOk = $false
}

# Vérifier si le fichier start-n8n.ps1 existe
$startScriptPath = Join-Path -Path $automationPath -ChildPath "deployment\start-n8n.ps1"
if (Test-Path -Path $startScriptPath -PathType Leaf) {
    Write-Host "Le fichier start-n8n.ps1 existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier start-n8n.ps1 n'existe pas: $startScriptPath" -ForegroundColor Red
    $filesOk = $false
}

# Vérifier si le fichier start-n8n-new.cmd existe
$startCmdPath = Join-Path -Path $rootPath -ChildPath "start-n8n-new.cmd"
if (Test-Path -Path $startCmdPath -PathType Leaf) {
    Write-Host "Le fichier start-n8n-new.cmd existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier start-n8n-new.cmd n'existe pas: $startCmdPath" -ForegroundColor Red
    $filesOk = $false
}

# Afficher le résultat global
Write-Host "`n=== Résultat global ===" -ForegroundColor Cyan
if ($foldersOk -and $filesOk) {
    Write-Host "La structure n8n est correcte." -ForegroundColor Green
} else {
    Write-Host "La structure n8n présente des problèmes." -ForegroundColor Red
    
    if (-not $foldersOk) {
        Write-Host "  - Certains dossiers sont manquants." -ForegroundColor Red
    }
    
    if (-not $filesOk) {
        Write-Host "  - Certains fichiers essentiels sont manquants." -ForegroundColor Red
    }
}
