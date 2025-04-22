<#
.SYNOPSIS
    Script pour migrer les fichiers .cmd de la racine vers la nouvelle structure.

.DESCRIPTION
    Ce script migre les fichiers .cmd de la racine du projet vers la nouvelle structure n8n.
    Il copie les fichiers dans les dossiers appropriés et crée des liens symboliques pour maintenir la compatibilité.

.PARAMETER CreateSymlinks
    Crée des liens symboliques dans la racine pour maintenir la compatibilité avec les scripts existants.

.EXAMPLE
    .\migrate-cmd-files.ps1
    .\migrate-cmd-files.ps1 -CreateSymlinks
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$CreateSymlinks
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$cmdPath = Join-Path -Path $n8nPath -ChildPath "cmd"

# Définir les mappages de fichiers
$fileMappings = @{
    # Installation
    "install-n8n-local.cmd" = "install\install-n8n-local.cmd"
    "install-community-nodes.cmd" = "install\install-community-nodes.cmd"
    "install-mcp-client.cmd" = "install\install-mcp-client.cmd"
    "reinstall-n8n.cmd" = "install\reinstall-n8n.cmd"
    "reinstall-n8n-full.cmd" = "install\reinstall-n8n-full.cmd"
    
    # Démarrage
    "start-n8n-local.cmd" = "start\start-n8n-local.cmd"
    "start-n8n-debug.cmd" = "start\start-n8n-debug.cmd"
    "start-n8n-env.cmd" = "start\start-n8n-env.cmd"
    "start-n8n-encryption.cmd" = "start\start-n8n-encryption.cmd"
    "start-n8n-global.cmd" = "start\start-n8n-global.cmd"
    "start-n8n-import-credentials.cmd" = "start\start-n8n-import-credentials.cmd"
    "start-n8n-no-auth.cmd" = "start\start-n8n-no-auth.cmd"
    "start-n8n-npx.cmd" = "start\start-n8n-npx.cmd"
    "start-n8n-simple.cmd" = "start\start-n8n-simple.cmd"
    "start-n8n-skip-auth.cmd" = "start\start-n8n-skip-auth.cmd"
    "start-n8n-tunnel.cmd" = "start\start-n8n-tunnel.cmd"
    "start-n8n-tunnel-env.cmd" = "start\start-n8n-tunnel-env.cmd"
    "start-n8n-tunnel-global.cmd" = "start\start-n8n-tunnel-global.cmd"
    "start-n8n-tunnel-only.cmd" = "start\start-n8n-tunnel-only.cmd"
    "start-n8n-default-user.cmd" = "start\start-n8n-default-user.cmd"
    
    # Arrêt
    "stop-n8n.cmd" = "stop\stop-n8n.cmd"
    
    # Utilitaires
    "reset-n8n.cmd" = "utils\reset-n8n.cmd"
    "reset-n8n-local.cmd" = "utils\reset-n8n-local.cmd"
}

# Fonction pour copier un fichier
function Copy-CmdFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationFile
    )
    
    $sourcePath = Join-Path -Path $rootPath -ChildPath $SourceFile
    $destinationPath = Join-Path -Path $cmdPath -ChildPath $DestinationFile
    
    if (Test-Path -Path $sourcePath) {
        try {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
            Write-Host "Copié: $SourceFile -> $DestinationFile"
            return $true
        } catch {
            Write-Error "Erreur lors de la copie du fichier '$SourceFile' : $_"
            return $false
        }
    } else {
        Write-Warning "Le fichier source '$SourceFile' n'existe pas."
        return $false
    }
}

# Fonction pour créer un lien symbolique
function New-SymbolicLink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetFile
    )
    
    $sourcePath = Join-Path -Path $rootPath -ChildPath $SourceFile
    $targetPath = Join-Path -Path $n8nPath -ChildPath $TargetFile
    
    if (Test-Path -Path $sourcePath) {
        Write-Warning "Le fichier '$SourceFile' existe déjà. Il ne sera pas remplacé par un lien symbolique."
        return $false
    }
    
    try {
        New-Item -ItemType SymbolicLink -Path $sourcePath -Target $targetPath -Force | Out-Null
        Write-Host "Lien symbolique créé: $SourceFile -> $TargetFile"
        return $true
    } catch {
        Write-Error "Erreur lors de la création du lien symbolique '$SourceFile' : $_"
        return $false
    }
}

# Migrer les fichiers
Write-Host "Migration des fichiers .cmd..."
$copiedCount = 0

foreach ($file in $fileMappings.Keys) {
    $destination = $fileMappings[$file]
    $result = Copy-CmdFile -SourceFile $file -DestinationFile $destination
    
    if ($result) {
        $copiedCount++
    }
}

Write-Host "$copiedCount fichiers copiés."

# Créer des liens symboliques si demandé
if ($CreateSymlinks) {
    Write-Host ""
    Write-Host "Création des liens symboliques..."
    $linkCount = 0
    
    foreach ($file in $fileMappings.Keys) {
        $destination = $fileMappings[$file]
        $result = New-SymbolicLink -SourceFile $file -TargetFile "cmd\$destination"
        
        if ($result) {
            $linkCount++
        }
    }
    
    Write-Host "$linkCount liens symboliques créés."
}

Write-Host ""
Write-Host "Migration terminée."
