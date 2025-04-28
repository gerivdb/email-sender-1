#Requires -Version 5.1
<#
.SYNOPSIS
    Installe les dÃ©pendances pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script installe les dÃ©pendances Python nÃ©cessaires pour l'architecture
    hybride PowerShell-Python pour le traitement parallÃ¨le.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur, Python 3.6 et supÃ©rieur
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier la prÃ©sence de Python
function Test-PythonInstallation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            $version = $matches[1]
            Write-Host "Python version $version dÃ©tectÃ©e." -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "Python est installÃ© mais la version n'a pas pu Ãªtre dÃ©terminÃ©e."
            return $false
        }
    }
    catch {
        Write-Warning "Python n'est pas installÃ© ou n'est pas dans le PATH."
        return $false
    }
}

# Installer les dÃ©pendances Python
function Install-PythonDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @("numpy", "psutil", "filelock"),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # VÃ©rifier les dÃ©pendances dÃ©jÃ  installÃ©es
    $installedDependencies = @()
    $missingDependencies = @()
    
    foreach ($dependency in $Dependencies) {
        try {
            $output = python -c "import $dependency; print('OK')" 2>&1
            if ($output -eq "OK") {
                $installedDependencies += $dependency
                Write-Host "DÃ©pendance '$dependency' dÃ©jÃ  installÃ©e." -ForegroundColor Green
            }
            else {
                $missingDependencies += $dependency
                Write-Warning "DÃ©pendance '$dependency' non installÃ©e."
            }
        }
        catch {
            $missingDependencies += $dependency
            Write-Warning "DÃ©pendance '$dependency' non installÃ©e."
        }
    }
    
    # Installer les dÃ©pendances manquantes
    if ($missingDependencies.Count -gt 0 -or $Force) {
        Write-Host "Installation des dÃ©pendances Python..." -ForegroundColor Yellow
        
        foreach ($dependency in ($Force ? $Dependencies : $missingDependencies)) {
            try {
                Write-Host "Installation de $dependency..." -ForegroundColor Yellow
                $process = Start-Process -FilePath "python" -ArgumentList "-m", "pip", "install", "--upgrade", $dependency -NoNewWindow -PassThru -Wait
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "DÃ©pendance '$dependency' installÃ©e avec succÃ¨s." -ForegroundColor Green
                }
                else {
                    Write-Error "Ã‰chec de l'installation de la dÃ©pendance '$dependency'. Code de sortie : $($process.ExitCode)"
                }
            }
            catch {
                Write-Error "Erreur lors de l'installation de la dÃ©pendance '$dependency' : $_"
            }
        }
    }
    else {
        Write-Host "Toutes les dÃ©pendances sont dÃ©jÃ  installÃ©es." -ForegroundColor Green
    }
}

# VÃ©rifier si Python est installÃ©
$pythonInstalled = Test-PythonInstallation
if (-not $pythonInstalled) {
    Write-Error "Python est requis pour l'architecture hybride. Veuillez installer Python 3.6 ou supÃ©rieur."
    exit 1
}

# Installer les dÃ©pendances Python
Install-PythonDependencies -Force:$Force

Write-Host "`nInstallation des dÃ©pendances terminÃ©e." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser l'architecture hybride PowerShell-Python pour le traitement parallÃ¨le." -ForegroundColor Green
