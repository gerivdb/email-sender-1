# Script pour réorganiser les fichiers Markdown dans le dossier docs/guides en utilisant Hygen

# Fonction pour déplacer un fichier vers un dossier de destination
function Move-FileToDestination {
    param (
        [string]$SourcePath,
        [string]$DestinationFolder
    )
    
    $fileName = Split-Path -Leaf $SourcePath
    $destinationPath = Join-Path -Path $DestinationFolder -ChildPath $fileName
    
    # Créer le dossier de destination s'il n'existe pas
    if (-not (Test-Path -Path $DestinationFolder)) {
        New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
    }
    
    # Copier le fichier vers la destination
    Copy-Item -Path $SourcePath -Destination $destinationPath -Force
    Write-Host "Déplacé: $SourcePath -> $destinationPath"
}

# Chemin de base
$basePath = "docs/guides"

# Créer la structure de dossiers
$folders = @(
    "best-practices",
    "core",
    "git",
    "installation",
    "mcp",
    "methodologies",
    "n8n",
    "powershell",
    "python",
    "tools",
    "troubleshooting"
)

foreach ($folder in $folders) {
    $folderPath = Join-Path -Path $basePath -ChildPath $folder
    if (-not (Test-Path -Path $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Host "Créé: $folderPath"
    }
}

# Fichiers à conserver à la racine
$rootFiles = @(
    "index.md",
    "guidelines_index.md",
    "GUIDELINES.md",
    "template.md"
)

# Déplacer les fichiers liés à PowerShell
$powershellFiles = @(
    "powershell_best_practices.md",
    "powershell_execution.md",
    "PowerShell-5.1-Guidelines.md"
)

foreach ($file in $powershellFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/powershell"
    }
}

# Déplacer les fichiers liés à Python
$pythonFiles = @(
    "python_best_practices.md"
)

foreach ($file in $pythonFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/python"
    }
}

# Déplacer les fichiers liés à Git
$gitFiles = @(
    "GUIDE_BONNES_PRATIQUES_GIT.md",
    "GUIDE_GIT_GITHUB.md",
    "GUIDE_HOOKS_GIT.md",
    "GUIDE_MCP_GIT_INGEST.md"
)

foreach ($file in $gitFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/git"
    }
}

# Déplacer les fichiers liés à MCP
$mcpFiles = @(
    "GUIDE_MCP_GATEWAY.md",
    "GUIDE_MCP_FILESYSTEM.md",
    "GUIDE_MCP_N8N.md",
    "GUIDE_MCP_NOTION_SERVER.md",
    "GUIDE_BIFROST_MCP.md",
    "GUIDE_FINAL_MCP.md",
    "MCPClient_UserGuide.md",
    "mcp_integration.md",
    "CONFIGURATION_MCP_GATEWAY_N8N.md",
    "CONFIGURATION_MCP_MISE_A_JOUR.md",
    "RESOLUTION_PROBLEMES_MCP.md"
)

foreach ($file in $mcpFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/mcp"
    }
}

# Déplacer les fichiers liés à n8n
$n8nFiles = @(
    "DEMARRER_N8N_LOCAL.md",
    "GUIDE_DOSSIER_N8N.md"
)

foreach ($file in $n8nFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/n8n"
    }
}

# Déplacer les fichiers liés aux méthodologies
$methodologiesFiles = @(
    "methodologies.md",
    "modes_fonctionnement.md",
    "programmation_16_bases.md",
    "auto_confirm_keep_all.md",
    "augment_dialog_management.md",
    "augment_vscode_guidelines.md"
)

foreach ($file in $methodologiesFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/methodologies"
    }
}

# Déplacer les fichiers liés aux bonnes pratiques
$bestPracticesFiles = @(
    "erreurs_integrite.md",
    "optimisations.md",
    "BONNES_PRATIQUES_CHEMINS.md",
    "GUIDE_GESTION_CARACTERES_ACCENTUES.md"
)

foreach ($file in $bestPracticesFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/best-practices"
    }
}

# Déplacer les fichiers liés à l'installation
$installationFiles = @(
    "GUIDE_INSTALLATION_COMPLET.md",
    "getting_started.md"
)

foreach ($file in $installationFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/installation"
    }
}

# Déplacer les fichiers liés au dépannage
$troubleshootingFiles = @(
    "instructions_test_integration.md"
)

foreach ($file in $troubleshootingFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/troubleshooting"
    }
}

# Déplacer les fichiers liés aux outils
$toolsFiles = @(
    "cycle_detection.md",
    "dependency_management.md",
    "input_segmentation.md",
    "DependencyCycleResolver_UserGuide.md",
    "GUIDE_INTEGRATION_CI_CD.md",
    "GUIDE_NOUVELLES_FONCTIONNALITES.md",
    "GUIDE_ORGANISATION_AUTOMATIQUE_DOSSIERS.md",
    "GUIDE_ORGANISATION_AUTOMATIQUE_FICHIERS.md"
)

foreach ($file in $toolsFiles) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/tools"
    }
}

# Déplacer les fichiers restants vers le dossier core
$allFiles = Get-ChildItem -Path $basePath -Filter "*.md" | Select-Object -ExpandProperty Name
$filesToMove = $allFiles | Where-Object { 
    ($rootFiles -notcontains $_) -and
    ($powershellFiles -notcontains $_) -and
    ($pythonFiles -notcontains $_) -and
    ($gitFiles -notcontains $_) -and
    ($mcpFiles -notcontains $_) -and
    ($n8nFiles -notcontains $_) -and
    ($methodologiesFiles -notcontains $_) -and
    ($bestPracticesFiles -notcontains $_) -and
    ($installationFiles -notcontains $_) -and
    ($troubleshootingFiles -notcontains $_) -and
    ($toolsFiles -notcontains $_)
}

foreach ($file in $filesToMove) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    if (Test-Path $sourcePath) {
        Move-FileToDestination -SourcePath $sourcePath -DestinationFolder "$basePath/core"
    }
}

Write-Host "Réorganisation terminée !"
