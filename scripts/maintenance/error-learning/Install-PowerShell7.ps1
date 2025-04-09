<#
.SYNOPSIS
    Script pour installer PowerShell 7.0 ou supérieur.
.DESCRIPTION
    Ce script télécharge et installe PowerShell 7.0 ou supérieur sur votre système.
.EXAMPLE
    .\Install-PowerShell7.ps1
    Installe PowerShell 7.0 ou supérieur.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

# Vérifier si PowerShell 7.0 ou supérieur est déjà installé
$ps7Path = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if (Test-Path -Path $ps7Path) {
    $ps7Version = & $ps7Path -Command '$PSVersionTable.PSVersion.ToString()'
    Write-Host "PowerShell $ps7Version est déjà installé à l'emplacement : $ps7Path" -ForegroundColor Green
    exit 0
}

# Télécharger et installer PowerShell 7.0 ou supérieur
try {
    Write-Host "Téléchargement et installation de PowerShell 7.0 ou supérieur..." -ForegroundColor Cyan
    
    # Télécharger le script d'installation
    $installScript = Join-Path -Path $env:TEMP -ChildPath "Install-PowerShell.ps1"
    Invoke-WebRequest -Uri "https://aka.ms/install-powershell.ps1" -OutFile $installScript
    
    # Exécuter le script d'installation
    if ($Quiet) {
        & $installScript -UseMSI -Quiet
    }
    else {
        & $installScript -UseMSI
    }
    
    # Vérifier si l'installation a réussi
    if (Test-Path -Path $ps7Path) {
        $ps7Version = & $ps7Path -Command '$PSVersionTable.PSVersion.ToString()'
        Write-Host "PowerShell $ps7Version a été installé avec succès à l'emplacement : $ps7Path" -ForegroundColor Green
        
        # Ajouter PowerShell 7 au PATH si ce n'est pas déjà fait
        $ps7Dir = Split-Path -Path $ps7Path -Parent
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$ps7Dir*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$ps7Dir", "Machine")
            Write-Host "PowerShell 7 a été ajouté au PATH système." -ForegroundColor Green
        }
        
        Write-Host "`nPour utiliser PowerShell 7, ouvrez une nouvelle fenêtre de terminal et exécutez la commande 'pwsh'." -ForegroundColor Yellow
        Write-Host "Vous pouvez également exécuter les scripts de parallélisation directement avec PowerShell 7 en utilisant la commande :" -ForegroundColor Yellow
        Write-Host "pwsh -File .\Analyze-ScriptsInParallel.ps1 -ScriptPaths 'C:\Scripts\*.ps1'" -ForegroundColor Cyan
    }
    else {
        Write-Error "L'installation de PowerShell 7 a échoué. Veuillez vérifier les journaux d'installation."
    }
}
catch {
    Write-Error "Une erreur s'est produite lors de l'installation de PowerShell 7 : $_"
}
finally {
    # Nettoyer
    if (Test-Path -Path $installScript) {
        Remove-Item -Path $installScript -Force
    }
}
