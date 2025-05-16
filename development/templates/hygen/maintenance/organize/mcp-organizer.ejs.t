---
to: "<%= template === 'mcp' ? `development/scripts/maintenance/organize/${name}.ps1` : null %>"
---
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    Ce script utilise le MCP Desktop Commander pour déplacer les fichiers <%= sourceDescription %> vers <%= targetDescription %>.
    Il crée également de nouveaux sous-dossiers si nécessaire.

.PARAMETER DryRun
    Si spécifié, le script simule les opérations sans effectuer de modifications réelles.

.PARAMETER Force
    Si spécifié, le script effectue les opérations sans demander de confirmation.

.EXAMPLE
    .\<%= name %>.ps1 -DryRun
    Simule l'organisation des fichiers sans effectuer de modifications.

.EXAMPLE
    .\<%= name %>.ps1
    Organise les fichiers avec confirmation pour chaque action.

.EXAMPLE
    .\<%= name %>.ps1 -Force
    Organise les fichiers sans demander de confirmation.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir les chemins
$rootPath = "<%= rootPath %>"
$rootPath = Resolve-Path $rootPath

# Vérifier si le MCP Desktop Commander est disponible
function Test-MCPDesktopCommander {
    try {
        $npmList = npm list -g @wonderwhy-er/desktop-commander
        if ($npmList -match "@wonderwhy-er/desktop-commander") {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Fonction pour démarrer le MCP Desktop Commander
function Start-MCPDesktopCommander {
    $mcpProcess = Start-Process -FilePath "npx" -ArgumentList "-y @wonderwhy-er/desktop-commander" -PassThru
    # Attendre que le serveur démarre
    Start-Sleep -Seconds 5
    return $mcpProcess
}

# Fonction pour arrêter le MCP Desktop Commander
function Stop-MCPDesktopCommander {
    param (
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process
    )

    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force
    }
}

# Fonction pour exécuter une commande MCP
function Invoke-MCPCommand {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host "[SIMULATION] Commande MCP: $Command avec paramètres: $($Parameters | ConvertTo-Json -Compress)" -ForegroundColor Yellow
        return $null
    }

    try {
        $body = @{
            command = $Command
        } + $Parameters

        $bodyJson = $body | ConvertTo-Json -Compress
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/command" -Method Post -Body $bodyJson -ContentType "application/json"
        return $response
    }
    catch {
        Write-Error "Erreur lors de l'exécution de la commande MCP: $_"
        return $null
    }
}

# Fonction pour déplacer un fichier
function Move-FileWithMCP {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($DryRun) {
        Write-Host "[SIMULATION] Déplacement: $SourcePath -> $DestinationPath" -ForegroundColor Yellow
        return $true
    }

    # Vérifier si le fichier de destination existe déjà
    $destExists = Invoke-MCPCommand -Command "file_exists" -Parameters @{
        path = $DestinationPath
    }

    if ($destExists.result -and -not $Force) {
        $confirmResult = $Host.UI.PromptForChoice(
            "Confirmation",
            "Le fichier $DestinationPath existe déjà. Voulez-vous le remplacer?",
            @("&Oui", "&Non"),
            1
        )

        if ($confirmResult -ne 0) {
            Write-Host "Déplacement annulé pour $SourcePath" -ForegroundColor Yellow
            return $false
        }
    }

    if ($PSCmdlet.ShouldProcess($SourcePath, "Déplacer vers $DestinationPath")) {
        $result = Invoke-MCPCommand -Command "move_file" -Parameters @{
            source = $SourcePath
            destination = $DestinationPath
        }

        if ($result.success) {
            Write-Host "Déplacé: $SourcePath -> $DestinationPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Erreur lors du déplacement de $SourcePath vers $DestinationPath: $($result.error)"
            return $false
        }
    }

    return $false
}

# Fonction pour créer un répertoire
function New-DirectoryWithMCP {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host "[SIMULATION] Création du répertoire: $Path" -ForegroundColor Yellow
        return $true
    }

    # Vérifier si le répertoire existe déjà
    $dirExists = Invoke-MCPCommand -Command "directory_exists" -Parameters @{
        path = $Path
    }

    if ($dirExists.result) {
        Write-Host "Le répertoire $Path existe déjà" -ForegroundColor Cyan
        return $true
    }

    if ($PSCmdlet.ShouldProcess($Path, "Créer le répertoire")) {
        $result = Invoke-MCPCommand -Command "create_directory" -Parameters @{
            path = $Path
        }

        if ($result.success) {
            Write-Host "Créé: $Path" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Erreur lors de la création du répertoire $Path: $($result.error)"
            return $false
        }
    }

    return $false
}

# Fonction principale pour organiser les fichiers
function Start-FileOrganization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Définir les mappages de fichiers vers les sous-dossiers
    $fileMappings = @{
<% for (const [file, folder] of Object.entries(fileMappings)) { %>
        "<%= file %>" = "<%= folder %>"
<% } %>
    }

    # Créer les sous-dossiers nécessaires
    $subDirectories = $fileMappings.Values | Sort-Object -Unique
    foreach ($dir in $subDirectories) {
        $dirPath = Join-Path -Path $rootPath -ChildPath $dir
        New-DirectoryWithMCP -Path $dirPath -DryRun:$DryRun
    }

    # Lister les fichiers à la racine
    $files = Invoke-MCPCommand -Command "list_directory" -Parameters @{
        path = $rootPath
    }

    if ($null -eq $files -or $null -eq $files.files) {
        Write-Error "Impossible de lister les fichiers dans $rootPath"
        return
    }

    # Déplacer les fichiers
    foreach ($file in $files.files) {
        # Vérifier si le fichier est dans le dossier organize
        $organizeDir = Join-Path -Path $rootPath -ChildPath "organize"
        $fileDir = Split-Path -Path (Join-Path -Path $rootPath -ChildPath $file.name) -Parent

        # Normaliser les chemins pour une comparaison correcte
        $organizeDir = [System.IO.Path]::GetFullPath($organizeDir)
        $fileDir = [System.IO.Path]::GetFullPath($fileDir)

        if ($fileDir -eq $organizeDir) {
            Write-Host "Fichier dans le dossier organize, ignoré: $($file.name)" -ForegroundColor Cyan
            continue
        }

        if ($file.type -eq "file" -and $fileMappings.ContainsKey($file.name)) {
            $sourcePath = Join-Path -Path $rootPath -ChildPath $file.name
            $destDir = Join-Path -Path $rootPath -ChildPath $fileMappings[$file.name]
            $destPath = Join-Path -Path $destDir -ChildPath $file.name

            Move-FileWithMCP -SourcePath $sourcePath -DestinationPath $destPath -DryRun:$DryRun -Force:$Force
        } else {
            Write-Host "Aucun mapping défini pour le fichier: $($file.name)" -ForegroundColor Yellow
        }
    }
}

# Vérifier si le MCP Desktop Commander est installé
if (-not (Test-MCPDesktopCommander)) {
    Write-Error "MCP Desktop Commander n'est pas installé. Veuillez l'installer avec 'npm install -g @wonderwhy-er/desktop-commander'"
    exit 1
}

# Démarrer le MCP Desktop Commander
Write-Host "Démarrage du MCP Desktop Commander..." -ForegroundColor Cyan
$mcpProcess = Start-MCPDesktopCommander

# Créer le répertoire organize s'il n'existe pas
$organizeDir = Join-Path -Path $rootPath -ChildPath "organize"
$dirExists = Invoke-MCPCommand -Command "directory_exists" -Parameters @{
    path = $organizeDir
}

if (-not $dirExists.result) {
    if (-not $DryRun) {
        $result = Invoke-MCPCommand -Command "create_directory" -Parameters @{
            path = $organizeDir
        }
        if ($result.success) {
            Write-Host "Créé: $organizeDir" -ForegroundColor Green
        }
    } else {
        Write-Host "[SIMULATION] Création du répertoire: $organizeDir" -ForegroundColor Yellow
    }
}

try {
    # Organiser les fichiers
    Write-Host "<%= description %>..." -ForegroundColor Cyan
    Write-Host "Répertoire racine: $rootPath" -ForegroundColor Cyan

    # Lister les fichiers à la racine pour vérification
    $files = Invoke-MCPCommand -Command "list_directory" -Parameters @{
        path = $rootPath
    }

    if ($null -ne $files -and $null -ne $files.files) {
        Write-Host "Fichiers à la racine:" -ForegroundColor Cyan
        foreach ($file in $files.files) {
            if ($file.type -eq "file") {
                Write-Host "- $($file.name)" -ForegroundColor Gray
            }
        }
    }

    Start-FileOrganization -DryRun:$DryRun -Force:$Force

    Write-Host "Organisation terminée." -ForegroundColor Green
}
finally {
    # Arrêter le MCP Desktop Commander
    Write-Host "Arrêt du MCP Desktop Commander..." -ForegroundColor Cyan
    Stop-MCPDesktopCommander -Process $mcpProcess
}
