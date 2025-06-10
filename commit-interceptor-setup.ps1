# commit-interceptor-setup.ps1
# Script de setup et de test pour le Commit Interceptor

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "start", "test", "build", "clean", "demo")]
    [string]$Action = "setup"
)

$ErrorActionPreference = "Stop"
$InterceptorPath = "development\hooks\commit-interceptor"

function Write-Status {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ERROR: $Message" -ForegroundColor Red
}

function Setup-Environment {
    Write-Status "Configuration de l'environnement Commit Interceptor..."
    
    # Vérifier Go
    try {
        $goVersion = go version
        Write-Status "Go détecté: $goVersion"
    } catch {
        Write-Error-Custom "Go n'est pas installé. Veuillez installer Go 1.21 ou supérieur."
        exit 1
    }
    
    # Vérifier Git
    try {
        $gitVersion = git --version
        Write-Status "Git détecté: $gitVersion"
    } catch {
        Write-Error-Custom "Git n'est pas installé. Veuillez installer Git."
        exit 1
    }
    
    # Créer les répertoires si nécessaire
    if (-not (Test-Path $InterceptorPath)) {
        Write-Status "Création du répertoire $InterceptorPath..."
        New-Item -Path $InterceptorPath -ItemType Directory -Force
    }
    
    # Aller dans le répertoire
    Set-Location $InterceptorPath
    
    # Initialiser le module Go si nécessaire
    if (-not (Test-Path "go.mod")) {
        Write-Status "Initialisation du module Go..."
        go mod init commit-interceptor
    }
    
    # Installer les dépendances
    Write-Status "Installation des dépendances..."
    go mod tidy
    
    # Créer la configuration par défaut si elle n'existe pas
    if (-not (Test-Path "branching-auto.json")) {
        Write-Status "Copie de la configuration par défaut..."
        if (Test-Path "config\branching-auto.json") {
            Copy-Item "config\branching-auto.json" "branching-auto.json"
        }
    }
    
    Write-Status "Setup terminé avec succès!"
}

function Start-Interceptor {
    Write-Status "Démarrage du Commit Interceptor..."
    
    Set-Location $InterceptorPath
    
    # Vérifier que les fichiers existent
    $requiredFiles = @("main.go", "interceptor.go", "analyzer.go", "router.go", "branching_manager.go", "config.go")
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-Error-Custom "Fichier manquant: $file"
            exit 1
        }
    }
    
    Write-Status "Compilation et démarrage..."
    go run .
}

function Run-Tests {
    Write-Status "Exécution des tests..."
    
    Set-Location $InterceptorPath
    
    # Tests unitaires
    Write-Status "Tests unitaires..."
    go test ./... -v
    
    # Tests avec couverture
    Write-Status "Tests de couverture..."
    go test ./... -cover
    
    # Tests de performance
    Write-Status "Tests de performance..."
    go test ./... -bench=.
    
    Write-Status "Tests terminés!"
}

function Build-Binary {
    Write-Status "Compilation du binaire..."
    
    Set-Location $InterceptorPath
    
    # Build pour Windows
    $env:GOOS = "windows"
    $env:GOARCH = "amd64"
    go build -o commit-interceptor.exe .
    
    # Build pour Linux
    $env:GOOS = "linux"
    $env:GOARCH = "amd64"
    go build -o commit-interceptor-linux .
    
    # Reset
    Remove-Item Env:\GOOS
    Remove-Item Env:\GOARCH
    
    Write-Status "Binaires créés: commit-interceptor.exe, commit-interceptor-linux"
}

function Clean-Environment {
    Write-Status "Nettoyage de l'environnement..."
    
    Set-Location $InterceptorPath
    
    # Supprimer les binaires
    $filesToClean = @("commit-interceptor.exe", "commit-interceptor-linux", "*.log")
    foreach ($pattern in $filesToClean) {
        Get-ChildItem -Path . -Name $pattern -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    
    Write-Status "Nettoyage terminé!"
}

function Run-Demo {
    Write-Status "Démonstration du Commit Interceptor..."
    
    Set-Location $InterceptorPath
    
    # Démarrer le serveur en arrière-plan
    Write-Status "Démarrage du serveur de demo..."
    $job = Start-Job -ScriptBlock {
        Set-Location $using:InterceptorPath
        go run .
    }
    
    # Attendre que le serveur démarre
    Start-Sleep -Seconds 3
    
    # Test de santé
    Write-Status "Test de santé du serveur..."
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
        Write-Status "Serveur opérationnel: $response"
    } catch {
        Write-Error-Custom "Le serveur n'a pas pu démarrer correctement."
        Stop-Job $job
        Remove-Job $job
        exit 1
    }
    
    # Test avec un payload de commit
    Write-Status "Test avec un commit exemple..."
    $payload = @{
        commits = @(
            @{
                id = "abc123def456"
                message = "feat: add user authentication system"
                timestamp = (Get-Date).ToString("o")
                author = @{
                    name = "Demo User"
                    email = "demo@example.com"
                }
                added = @("auth.go", "user.go")
                modified = @("main.go")
                removed = @()
            }
        )
        repository = @{
            name = "demo-repo"
            full_name = "user/demo-repo"
        }
        ref = "refs/heads/main"
    } | ConvertTo-Json -Depth 4
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/hooks/pre-commit" -Method POST -Body $payload -ContentType "application/json"
        Write-Status "Test commit réussi: $response"
    } catch {
        Write-Status "Test commit (erreur attendue car pas dans un repo Git): $($_.Exception.Message)"
    }
    
    # Test des métriques
    Write-Status "Récupération des métriques..."
    try {
        $metrics = Invoke-RestMethod -Uri "http://localhost:8080/metrics" -Method GET
        Write-Status "Métriques: $metrics"
    } catch {
        Write-Status "Erreur lors de la récupération des métriques: $($_.Exception.Message)"
    }
    
    # Arrêter le serveur
    Write-Status "Arrêt du serveur de demo..."
    Stop-Job $job
    Remove-Job $job
    
    Write-Status "Démonstration terminée!"
}

# Point d'entrée principal
switch ($Action) {
    "setup" { Setup-Environment }
    "start" { Start-Interceptor }
    "test" { Run-Tests }
    "build" { Build-Binary }
    "clean" { Clean-Environment }
    "demo" { Run-Demo }
    default { 
        Write-Host "Actions disponibles: setup, start, test, build, clean, demo"
        Write-Host "Usage: .\commit-interceptor-setup.ps1 -Action <action>"
    }
}

Write-Status "Script terminé!"