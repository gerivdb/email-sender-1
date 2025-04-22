<#
.SYNOPSIS
    Script pour tester l'installation de n8n.

.DESCRIPTION
    Ce script vérifie si l'installation de n8n est correcte et fonctionnelle.
    Il vérifie la présence des fichiers et dossiers nécessaires et teste la connexion à n8n.

.EXAMPLE
    .\test-installation.ps1
#>

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$dataPath = Join-Path -Path $rootPath -ChildPath "data"
$workflowsPath = Join-Path -Path $rootPath -ChildPath "workflows"
$scriptsPath = Join-Path -Path $rootPath -ChildPath "scripts"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$envPath = Join-Path -Path $rootPath -ChildPath ".env"

# Fonction pour vérifier si un dossier existe
function Test-FolderExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-Path -Path $Path) {
        Write-Host "[OK] Le dossier $Name existe: $Path"
        return $true
    } else {
        Write-Host "[ERREUR] Le dossier $Name n'existe pas: $Path"
        return $false
    }
}

# Fonction pour vérifier si un fichier existe
function Test-FileExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-Path -Path $Path) {
        Write-Host "[OK] Le fichier $Name existe: $Path"
        return $true
    } else {
        Write-Host "[ERREUR] Le fichier $Name n'existe pas: $Path"
        return $false
    }
}

# Fonction pour vérifier si n8n est en cours d'exécution
function Test-N8nRunning {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost"
    )

    try {
        $uri = "http://$($Hostname):$($Port)/healthz"
        $response = Invoke-WebRequest -Uri $uri -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "[OK] n8n est en cours d'exécution sur le port $Port"
            return $true
        } else {
            Write-Host "[ERREUR] n8n est en cours d'exécution sur le port $Port, mais le statut de la réponse est $($response.StatusCode)"
            return $false
        }
    } catch {
        Write-Host "[ERREUR] n8n n'est pas en cours d'exécution sur le port $Port"
        return $false
    }
}

# Vérifier la structure des dossiers
Write-Host "Vérification de la structure des dossiers..."
$foldersOk = $true
$foldersOk = $foldersOk -and (Test-FolderExists -Path $rootPath -Name "racine")
$foldersOk = $foldersOk -and (Test-FolderExists -Path $configPath -Name "config")
$foldersOk = $foldersOk -and (Test-FolderExists -Path $dataPath -Name "data")
$foldersOk = $foldersOk -and (Test-FolderExists -Path $workflowsPath -Name "workflows")
$foldersOk = $foldersOk -and (Test-FolderExists -Path $scriptsPath -Name "scripts")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $workflowsPath -ChildPath "local") -Name "workflows/local")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $workflowsPath -ChildPath "ide") -Name "workflows/ide")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $workflowsPath -ChildPath "archive") -Name "workflows/archive")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $dataPath -ChildPath "credentials") -Name "data/credentials")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $dataPath -ChildPath "database") -Name "data/database")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $dataPath -ChildPath "storage") -Name "data/storage")

if ($foldersOk) {
    Write-Host "Tous les dossiers nécessaires sont présents."
} else {
    Write-Warning "Certains dossiers sont manquants. Veuillez exécuter le script d'installation."
}

# Vérifier les fichiers de configuration
Write-Host ""
Write-Host "Vérification des fichiers de configuration..."
$filesOk = $true
$filesOk = $filesOk -and (Test-FileExists -Path $n8nConfigPath -Name "n8n-config.json")
$filesOk = $filesOk -and (Test-FileExists -Path $envPath -Name ".env")

if ($filesOk) {
    Write-Host "Tous les fichiers de configuration sont présents."
} else {
    Write-Warning "Certains fichiers de configuration sont manquants. Veuillez exécuter le script d'installation."
}

# Vérifier si n8n est installé
Write-Host ""
Write-Host "Vérification de l'installation de n8n..."
try {
    $n8nVersion = n8n --version
    Write-Host "[OK] n8n est installé (version $n8nVersion)."
    $n8nInstalled = $true
} catch {
    Write-Host "[ERREUR] n8n n'est pas installé ou n'est pas accessible dans le PATH."
    $n8nInstalled = $false
}

# Vérifier si n8n est en cours d'exécution
if ($n8nInstalled -and (Test-FileExists -Path $n8nConfigPath -Name "n8n-config.json")) {
    Write-Host ""
    Write-Host "Vérification si n8n est en cours d'exécution..."

    # Lire la configuration
    $config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

    # Vérifier si n8n est en cours d'exécution
    $n8nRunning = Test-N8nRunning -Port $config.port

    if (-not $n8nRunning) {
        Write-Host "n8n n'est pas en cours d'exécution. Vous pouvez le démarrer avec la commande: .\scripts\start-n8n.ps1"
    }
}

# Résumé
Write-Host ""
Write-Host "Résumé des tests:"
Write-Host "- Structure des dossiers: $(if ($foldersOk) { "OK" } else { "ERREUR" })"
Write-Host "- Fichiers de configuration: $(if ($filesOk) { "OK" } else { "ERREUR" })"
Write-Host "- Installation de n8n: $(if ($n8nInstalled) { "OK" } else { "ERREUR" })"
if ($n8nInstalled -and (Test-FileExists -Path $n8nConfigPath -Name "n8n-config.json")) {
    Write-Host "- n8n en cours d'exécution: $(if ($n8nRunning) { "OK" } else { "NON" })"
}

# Conclusion
Write-Host ""
if ($foldersOk -and $filesOk -and $n8nInstalled) {
    Write-Host "L'installation de n8n est correcte."
    if (-not $n8nRunning) {
        Write-Host "Pour démarrer n8n, exécutez: .\scripts\start-n8n.ps1"
    }
} else {
    Write-Warning "L'installation de n8n n'est pas complète. Veuillez exécuter le script d'installation."
    Write-Host "Pour installer n8n, exécutez: .\scripts\setup\install-n8n-local.ps1"
}
