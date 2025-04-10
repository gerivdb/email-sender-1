#Requires -Version 5.1
<#
.SYNOPSIS
    Installe les dépendances pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script installe les dépendances Python nécessaires pour l'architecture
    hybride PowerShell-Python pour le traitement parallèle.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    Compatibilité: PowerShell 5.1 et supérieur, Python 3.6 et supérieur
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier la présence de Python
function Test-PythonInstallation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            $version = $matches[1]
            Write-Host "Python version $version détectée." -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "Python est installé mais la version n'a pas pu être déterminée."
            return $false
        }
    }
    catch {
        Write-Warning "Python n'est pas installé ou n'est pas dans le PATH."
        return $false
    }
}

# Installer les dépendances Python
function Install-PythonDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @("numpy", "psutil", "filelock"),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier les dépendances déjà installées
    $installedDependencies = @()
    $missingDependencies = @()
    
    foreach ($dependency in $Dependencies) {
        try {
            $output = python -c "import $dependency; print('OK')" 2>&1
            if ($output -eq "OK") {
                $installedDependencies += $dependency
                Write-Host "Dépendance '$dependency' déjà installée." -ForegroundColor Green
            }
            else {
                $missingDependencies += $dependency
                Write-Warning "Dépendance '$dependency' non installée."
            }
        }
        catch {
            $missingDependencies += $dependency
            Write-Warning "Dépendance '$dependency' non installée."
        }
    }
    
    # Installer les dépendances manquantes
    if ($missingDependencies.Count -gt 0 -or $Force) {
        Write-Host "Installation des dépendances Python..." -ForegroundColor Yellow
        
        foreach ($dependency in ($Force ? $Dependencies : $missingDependencies)) {
            try {
                Write-Host "Installation de $dependency..." -ForegroundColor Yellow
                $process = Start-Process -FilePath "python" -ArgumentList "-m", "pip", "install", "--upgrade", $dependency -NoNewWindow -PassThru -Wait
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "Dépendance '$dependency' installée avec succès." -ForegroundColor Green
                }
                else {
                    Write-Error "Échec de l'installation de la dépendance '$dependency'. Code de sortie : $($process.ExitCode)"
                }
            }
            catch {
                Write-Error "Erreur lors de l'installation de la dépendance '$dependency' : $_"
            }
        }
    }
    else {
        Write-Host "Toutes les dépendances sont déjà installées." -ForegroundColor Green
    }
}

# Vérifier si Python est installé
$pythonInstalled = Test-PythonInstallation
if (-not $pythonInstalled) {
    Write-Error "Python est requis pour l'architecture hybride. Veuillez installer Python 3.6 ou supérieur."
    exit 1
}

# Installer les dépendances Python
Install-PythonDependencies -Force:$Force

Write-Host "`nInstallation des dépendances terminée." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser l'architecture hybride PowerShell-Python pour le traitement parallèle." -ForegroundColor Green
