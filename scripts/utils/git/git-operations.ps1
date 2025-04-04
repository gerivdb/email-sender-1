# Script pour exécuter des opérations Git de manière fiable
# Utilisation : .\scripts\utils\git\git-operations.ps1 -Operation "add" -Files "file1.txt,file2.txt" -Message "Commit message"

param (
    [Parameter(Mandatory=$true)]
    [string]$Operation,
    
    [Parameter(Mandatory=$false)]
    [string]$Files = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "main"
)

# Définir le répertoire de travail
$workingDir = $PSScriptRoot
while (-not (Test-Path (Join-Path $workingDir ".git"))) {
    $workingDir = Split-Path $workingDir -Parent
    if ($null -eq $workingDir) {
        Write-Error "Impossible de trouver le répertoire Git"
        exit 1
    }
}

Write-Host "Répertoire Git trouvé : $workingDir" -ForegroundColor Cyan
Set-Location $workingDir

# Fonction pour exécuter une commande Git
function Invoke-GitCommand {
    param (
        [string]$Command,
        [string[]]$Arguments
    )
    
    $gitCommand = "git $Command $($Arguments -join ' ')"
    Write-Host "Exécution de : $gitCommand" -ForegroundColor Yellow
    
    try {
        $output = & git $Command $Arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Erreur lors de l'exécution de la commande Git : $output"
            return $false
        }
        Write-Host $output
        return $true
    }
    catch {
        Write-Error "Exception lors de l'exécution de la commande Git : $_"
        return $false
    }
}

# Exécuter l'opération demandée
switch ($Operation) {
    "status" {
        Invoke-GitCommand "status"
    }
    "add" {
        if ($Files -eq "") {
            Write-Error "Vous devez spécifier des fichiers à ajouter"
            exit 1
        }
        
        $fileList = $Files -split ","
        foreach ($file in $fileList) {
            $file = $file.Trim()
            Invoke-GitCommand "add" @($file)
        }
    }
    "commit" {
        if ($Message -eq "") {
            Write-Error "Vous devez spécifier un message de commit"
            exit 1
        }
        
        Invoke-GitCommand "commit" @("-m", $Message)
    }
    "push" {
        Invoke-GitCommand "push" @("origin", $Branch)
    }
    "pull" {
        Invoke-GitCommand "pull" @("origin", $Branch)
    }
    "log" {
        Invoke-GitCommand "log" @("--oneline", "-n", "10")
    }
    "add-commit-push" {
        if ($Files -eq "") {
            Write-Error "Vous devez spécifier des fichiers à ajouter"
            exit 1
        }
        
        if ($Message -eq "") {
            Write-Error "Vous devez spécifier un message de commit"
            exit 1
        }
        
        $fileList = $Files -split ","
        foreach ($file in $fileList) {
            $file = $file.Trim()
            $success = Invoke-GitCommand "add" @($file)
            if (-not $success) {
                exit 1
            }
        }
        
        $success = Invoke-GitCommand "commit" @("-m", $Message)
        if (-not $success) {
            exit 1
        }
        
        Invoke-GitCommand "push" @("origin", $Branch)
    }
    default {
        Write-Error "Opération non reconnue : $Operation"
        Write-Host "Opérations disponibles : status, add, commit, push, pull, log, add-commit-push"
        exit 1
    }
}
