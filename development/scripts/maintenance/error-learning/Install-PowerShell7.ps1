<#
.SYNOPSIS
    Script pour installer PowerShell 7.0 ou supÃ©rieur.
.DESCRIPTION
    Ce script tÃ©lÃ©charge et installe PowerShell 7.0 ou supÃ©rieur sur votre systÃ¨me.
.EXAMPLE
    .\Install-PowerShell7.ps1
    Installe PowerShell 7.0 ou supÃ©rieur.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

# VÃ©rifier si PowerShell 7.0 ou supÃ©rieur est dÃ©jÃ  installÃ©
$ps7Path = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if (Test-Path -Path $ps7Path) {
    $ps7Version = & $ps7Path -Command '$PSVersionTable.PSVersion.ToString()'
    Write-Host "PowerShell $ps7Version est dÃ©jÃ  installÃ© Ã  l'emplacement : $ps7Path" -ForegroundColor Green
    exit 0
}

# TÃ©lÃ©charger et installer PowerShell 7.0 ou supÃ©rieur
try {
    Write-Host "TÃ©lÃ©chargement et installation de PowerShell 7.0 ou supÃ©rieur..." -ForegroundColor Cyan
    
    # TÃ©lÃ©charger le script d'installation
    $installScript = Join-Path -Path $env:TEMP -ChildPath "Install-PowerShell.ps1"
    Invoke-WebRequest -Uri "https://aka.ms/install-powershell.ps1" -OutFile $installScript
    
    # ExÃ©cuter le script d'installation
    if ($Quiet) {
        & $installScript -UseMSI -Quiet
    }
    else {
        & $installScript -UseMSI
    }
    
    # VÃ©rifier si l'installation a rÃ©ussi
    if (Test-Path -Path $ps7Path) {
        $ps7Version = & $ps7Path -Command '$PSVersionTable.PSVersion.ToString()'
        Write-Host "PowerShell $ps7Version a Ã©tÃ© installÃ© avec succÃ¨s Ã  l'emplacement : $ps7Path" -ForegroundColor Green
        
        # Ajouter PowerShell 7 au PATH si ce n'est pas dÃ©jÃ  fait
        $ps7Dir = Split-Path -Path $ps7Path -Parent
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$ps7Dir*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$ps7Dir", "Machine")
            Write-Host "PowerShell 7 a Ã©tÃ© ajoutÃ© au PATH systÃ¨me." -ForegroundColor Green
        }
        
        Write-Host "`nPour utiliser PowerShell 7, ouvrez une nouvelle fenÃªtre de terminal et exÃ©cutez la commande 'pwsh'." -ForegroundColor Yellow
        Write-Host "Vous pouvez Ã©galement exÃ©cuter les scripts de parallÃ©lisation directement avec PowerShell 7 en utilisant la commande :" -ForegroundColor Yellow
        Write-Host "pwsh -File .\Analyze-ScriptsInParallel.ps1 -ScriptPaths 'C:\Scripts\*.ps1'" -ForegroundColor Cyan
    }
    else {
        Write-Error "L'installation de PowerShell 7 a Ã©chouÃ©. Veuillez vÃ©rifier les journaux d'installation."
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
