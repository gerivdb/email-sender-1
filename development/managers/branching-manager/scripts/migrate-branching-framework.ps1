#!/usr/bin/env pwsh
# Migration du Framework de Branchement vers l'Écosystème Manager
# Ce script déplace les fichiers de branchement de la racine vers la structure manager organisée

param(
    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Configuration de la migration
$MigrationConfig = @{
    SourceRoot      = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    TargetManager   = "development\managers\branching-manager"
    BackupFolder    = "development\managers\branching-manager\legacy-migration"
    ExecutionId     = "migration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

function Write-MigrationLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [MIGRATION] $Message"
    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
    )
}

function Start-BranchingMigration {
    Write-MigrationLog "========================================" 
    Write-MigrationLog "🔄 MIGRATION DU FRAMEWORK DE BRANCHEMENT"
    Write-MigrationLog "========================================" 
    Write-MigrationLog "Mode: $(if ($DryRun) { 'DRY RUN (simulation)' } else { 'EXECUTION RÉELLE' })"
    Write-MigrationLog "Execution ID: $($MigrationConfig.ExecutionId)"
    Write-MigrationLog "========================================" 
    
    # 1. Analyser les fichiers de branchement à la racine
    $branchingFiles = Get-BranchingFilesAtRoot
    
    if ($branchingFiles.Count -eq 0) {
        Write-MigrationLog "✅ Aucun fichier de branchement trouvé à la racine" "SUCCESS"
        return
    }
    
    Write-MigrationLog "📋 Fichiers de branchement détectés à la racine:"
    foreach ($file in $branchingFiles) {
        Write-MigrationLog "   - $($file.Name) ($($file.Category))"
    }
    
    # 2. Vérifier la structure du manager de branchement existant
    $managerPath = Join-Path $MigrationConfig.SourceRoot $MigrationConfig.TargetManager
    if (-not (Test-Path $managerPath)) {
        Write-MigrationLog "❌ Le manager de branchement n'existe pas: $managerPath" "ERROR"
        return
    }
    
    Write-MigrationLog "✅ Manager de branchement existant trouvé: $managerPath" "SUCCESS"
    
    # 3. Créer la structure de migration
    Create-MigrationStructure
    
    # 4. Migrer les fichiers
    foreach ($file in $branchingFiles) {
        Move-BranchingFile -FileInfo $file
    }
    
    # 5. Créer le script d'intégration
    Create-IntegrationScript
    
    # 6. Mettre à jour la configuration du manager
    Update-ManagerConfiguration
    
    Write-MigrationLog "========================================" 
    Write-MigrationLog "✅ MIGRATION TERMINÉE AVEC SUCCÈS" "SUCCESS"
    Write-MigrationLog "========================================" 
}

function Get-BranchingFilesAtRoot {
    $rootPath = $MigrationConfig.SourceRoot
    $branchingFiles = @()
    
    # Fichiers spécifiques au branchement à la racine
    $patterns = @(
        @{ Pattern = "*branch*"; Category = "branching-core" }
        @{ Pattern = "*orchestrat*"; Category = "orchestration" }
        @{ Pattern = "start-branching-server.ps1"; Category = "server" }
        @{ Pattern = "demo-branching-framework.ps1"; Category = "demo" }
    )
    
    foreach ($pattern in $patterns) {
        $files = Get-ChildItem -Path $rootPath -Name $pattern.Pattern -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $fullPath = Join-Path $rootPath $file
            # Exclure les fichiers déjà dans le dossier managers
            if ($file -notlike "*managers*") {
                $branchingFiles += @{
                    Name = $file
                    FullPath = $fullPath
                    Category = $pattern.Category
                }
            }
        }
    }
    
    return $branchingFiles
}

function Create-MigrationStructure {
    $managerPath = Join-Path $MigrationConfig.SourceRoot $MigrationConfig.TargetManager
    
    # Créer les dossiers manquants selon la convention manager
    $requiredFolders = @(
        "scripts",           # Scripts PowerShell
        "legacy-migration",  # Fichiers migrés de la racine
        "web",              # Interface web (serveur)
        "demos",            # Scripts de démonstration
        "orchestration"     # Scripts d'orchestration
    )
    
    foreach ($folder in $requiredFolders) {
        $folderPath = Join-Path $managerPath $folder
        if (-not (Test-Path $folderPath)) {
            Write-MigrationLog "📁 Création du dossier: $folder"
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            }
        }
    }
}

function Move-BranchingFile {
    param($FileInfo)
    
    $managerPath = Join-Path $MigrationConfig.SourceRoot $MigrationConfig.TargetManager
    
    # Déterminer le dossier de destination selon le type de fichier
    $targetFolder = switch ($FileInfo.Category) {
        "branching-core" { "scripts" }
        "orchestration" { "orchestration" }
        "server" { "web" }
        "demo" { "demos" }
        default { "legacy-migration" }
    }
    
    $targetPath = Join-Path $managerPath $targetFolder
    $targetFile = Join-Path $targetPath $FileInfo.Name
    
    Write-MigrationLog "🔄 Migration: $($FileInfo.Name) → $targetFolder/"
    
    if (-not $DryRun) {
        try {
            # Créer une sauvegarde si le fichier existe déjà
            if (Test-Path $targetFile) {
                $backupName = "$($FileInfo.Name).backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                $backupPath = Join-Path $targetPath $backupName
                Move-Item -Path $targetFile -Destination $backupPath
                Write-MigrationLog "📦 Sauvegarde créée: $backupName" "WARNING"
            }
            
            # Déplacer le fichier
            Move-Item -Path $FileInfo.FullPath -Destination $targetFile
            Write-MigrationLog "✅ Migration réussie: $($FileInfo.Name)" "SUCCESS"
            
        } catch {
            Write-MigrationLog "❌ Erreur de migration pour $($FileInfo.Name): $($_.Exception.Message)" "ERROR"
        }
    }
}

function Create-IntegrationScript {
    $managerPath = Join-Path $MigrationConfig.SourceRoot $MigrationConfig.TargetManager
    $integrationScript = Join-Path $managerPath "scripts\branching-integration.ps1"
    
    $scriptContent = @"
#!/usr/bin/env pwsh
# Script d'intégration du Framework de Branchement 8-Niveaux
# Généré automatiquement par la migration du $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))

param(
    [Parameter(Mandatory = `$false)]
    [string]`$Mode = "development",
    
    [Parameter(Mandatory = `$false)]
    [int]`$Port = 8090
)

`$ErrorActionPreference = "Stop"

# Configuration du framework intégré
`$FrameworkConfig = @{
    Mode = `$Mode
    Port = `$Port
    ManagerPath = `$PSScriptRoot
    ExecutionId = "integration-`$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

function Write-IntegrationLog {
    param(`$Message, `$Level = "INFO")
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    `$logMessage = "[`$timestamp] [`$Level] [BRANCHING-INTEGRATION] `$Message"
    Write-Host `$logMessage
}

function Start-BranchingFramework {
    Write-IntegrationLog "🌿 Démarrage du Framework de Branchement 8-Niveaux"
    Write-IntegrationLog "Mode: `$(`$FrameworkConfig.Mode)"
    Write-IntegrationLog "Port: `$(`$FrameworkConfig.Port)"
    
    # 1. Vérifier les services essentiels
    Test-EssentialServices
    
    # 2. Démarrer le serveur web si disponible
    `$webScript = Join-Path `$FrameworkConfig.ManagerPath "web\branching-server.ps1"
    if (Test-Path `$webScript) {
        Write-IntegrationLog "🚀 Démarrage du serveur web..."
        & `$webScript -Port `$FrameworkConfig.Port
    }
    
    # 3. Initialiser l'orchestrateur si disponible
    `$orchestratorScript = Join-Path `$FrameworkConfig.ManagerPath "orchestration\*orchestrat*.ps1"
    `$orchestratorFiles = Get-ChildItem -Path `$orchestratorScript -ErrorAction SilentlyContinue
    if (`$orchestratorFiles) {
        Write-IntegrationLog "🎯 Initialisation de l'orchestrateur..."
        & `$orchestratorFiles[0].FullName
    }
    
    Write-IntegrationLog "✅ Framework de branchement initialisé avec succès"
}

function Test-EssentialServices {
    Write-IntegrationLog "🔍 Vérification des services essentiels..."
    
    # Test Redis
    try {
        `$redisTest = Test-NetConnection -ComputerName "localhost" -Port 6379 -InformationLevel Quiet
        if (`$redisTest) {
            Write-IntegrationLog "✅ Redis: Disponible"
        } else {
            Write-IntegrationLog "⚠️  Redis: Non disponible" "WARNING"
        }
    } catch {
        Write-IntegrationLog "⚠️  Redis: Test échoué" "WARNING"
    }
    
    # Test QDrant
    try {
        `$qdrantTest = Test-NetConnection -ComputerName "localhost" -Port 6333 -InformationLevel Quiet
        if (`$qdrantTest) {
            Write-IntegrationLog "✅ QDrant: Disponible"
        } else {
            Write-IntegrationLog "⚠️  QDrant: Non disponible" "WARNING"
        }
    } catch {
        Write-IntegrationLog "⚠️  QDrant: Test échoué" "WARNING"
    }
}

# Point d'entrée principal
try {
    Start-BranchingFramework
} catch {
    Write-IntegrationLog "❌ Erreur fatale: `$(`$_.Exception.Message)" "ERROR"
    exit 1
}
"@
    
    Write-MigrationLog "📝 Création du script d'intégration: branching-integration.ps1"
    if (-not $DryRun) {
        Set-Content -Path $integrationScript -Value $scriptContent -Encoding UTF8
    }
}

function Update-ManagerConfiguration {
    $configPath = Join-Path $MigrationConfig.SourceRoot "projet\config\managers\branching-manager"
    
    if (-not (Test-Path $configPath)) {
        Write-MigrationLog "📁 Création de la configuration manager: $configPath"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $configPath -Force | Out-Null
        }
    }
    
    $configFile = Join-Path $configPath "branching-manager.config.json"
    $config = @{
        "enabled" = $true
        "version" = "2.0.0"
        "framework" = @{
            "levels" = 8
            "type" = "ultra-advanced"
            "integration_date" = (Get-Date).ToString('yyyy-MM-dd')
        }
        "services" = @{
            "redis" = @{
                "required" = $true
                "port" = 6379
            }
            "qdrant" = @{
                "required" = $true
                "port" = 6333
            }
            "web_server" = @{
                "enabled" = $true
                "port" = 8090
            }
        }
        "paths" = @{
            "scripts" = "scripts"
            "web" = "web"
            "demos" = "demos"
            "orchestration" = "orchestration"
        }
    }
    
    Write-MigrationLog "⚙️  Mise à jour de la configuration manager"
    if (-not $DryRun) {
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
    }
}

# Point d'entrée principal
try {
    if ($DryRun) {
        Write-MigrationLog "🔍 SIMULATION DE MIGRATION (DRY RUN)" "WARNING"
    }
    
    Start-BranchingMigration
    
    if ($DryRun) {
        Write-MigrationLog "ℹ️  Pour exécuter réellement la migration, utilisez: .\migrate-branching-framework.ps1 -Force" "INFO"
    }
    
} catch {
    Write-MigrationLog "❌ Erreur fatale de migration: $($_.Exception.Message)" "ERROR"
    exit 1
}
