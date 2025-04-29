# Script pour nettoyer les fichiers temporaires gÃ©nÃ©rÃ©s par les tests

# DÃ©finir les paramÃ¨tres
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false,

    [Parameter(Mandatory = $false)]
    [switch]$SkipConfirmation = $false,

    [Parameter(Mandatory = $false)]
    [switch]$CleanReports = $false,

    [Parameter(Mandatory = $false)]
    [switch]$CleanAll = $false
)

# DÃ©finir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# DÃ©finir les chemins des rÃ©pertoires Ã  nettoyer
$testsDir = Join-Path -Path $projectRoot -ChildPath "development\\scripts\\mode-manager\tests"
$tempDir = Join-Path -Path $testsDir -ChildPath "temp"
$reportsDir = Join-Path -Path $projectRoot -ChildPath "reports\tests"

# Afficher les informations
Write-Host "Nettoyage des fichiers temporaires gÃ©nÃ©rÃ©s par les tests" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsDir" -ForegroundColor Cyan
Write-Host "Chemin des fichiers temporaires : $tempDir" -ForegroundColor Cyan
Write-Host "Chemin des rapports : $reportsDir" -ForegroundColor Cyan

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    $tempFiles = Get-ChildItem -Path $tempDir -Recurse
    $tempFileCount = $tempFiles.Count
    
    if ($tempFileCount -gt 0) {
        Write-Host "Fichiers temporaires trouvÃ©s : $tempFileCount" -ForegroundColor Cyan
        
        if (-not $Force -and -not $SkipConfirmation) {
            $confirmation = Read-Host "Voulez-vous supprimer les fichiers temporaires ? (O/N)"
            if ($confirmation -ne "O") {
                Write-Host "Nettoyage des fichiers temporaires annulÃ©." -ForegroundColor Yellow
            } else {
                Remove-Item -Path $tempDir -Recurse -Force
                Write-Host "Fichiers temporaires supprimÃ©s." -ForegroundColor Green
            }
        } else {
            Remove-Item -Path $tempDir -Recurse -Force
            Write-Host "Fichiers temporaires supprimÃ©s." -ForegroundColor Green
        }
    } else {
        Write-Host "Aucun fichier temporaire trouvÃ©." -ForegroundColor Green
    }
} else {
    Write-Host "RÃ©pertoire des fichiers temporaires introuvable." -ForegroundColor Yellow
}

# Nettoyer les fichiers de mock
$mockFiles = Get-ChildItem -Path $testsDir -Filter "mock-*.ps1"
$mockFileCount = $mockFiles.Count

if ($mockFileCount -gt 0) {
    Write-Host "Fichiers de mock trouvÃ©s : $mockFileCount" -ForegroundColor Cyan
    
    if (-not $Force -and -not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous supprimer les fichiers de mock ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Host "Nettoyage des fichiers de mock annulÃ©." -ForegroundColor Yellow
        } else {
            $mockFiles | Remove-Item -Force
            Write-Host "Fichiers de mock supprimÃ©s." -ForegroundColor Green
        }
    } else {
        $mockFiles | Remove-Item -Force
        Write-Host "Fichiers de mock supprimÃ©s." -ForegroundColor Green
    }
} else {
    Write-Host "Aucun fichier de mock trouvÃ©." -ForegroundColor Green
}

# Nettoyer les rapports
if ($CleanReports -or $CleanAll) {
    if (Test-Path -Path $reportsDir) {
        $reportFiles = Get-ChildItem -Path $reportsDir -Recurse
        $reportFileCount = $reportFiles.Count
        
        if ($reportFileCount -gt 0) {
            Write-Host "Fichiers de rapport trouvÃ©s : $reportFileCount" -ForegroundColor Cyan
            
            if (-not $Force -and -not $SkipConfirmation) {
                $confirmation = Read-Host "Voulez-vous supprimer les fichiers de rapport ? (O/N)"
                if ($confirmation -ne "O") {
                    Write-Host "Nettoyage des fichiers de rapport annulÃ©." -ForegroundColor Yellow
                } else {
                    Remove-Item -Path $reportsDir -Recurse -Force
                    Write-Host "Fichiers de rapport supprimÃ©s." -ForegroundColor Green
                }
            } else {
                Remove-Item -Path $reportsDir -Recurse -Force
                Write-Host "Fichiers de rapport supprimÃ©s." -ForegroundColor Green
            }
        } else {
            Write-Host "Aucun fichier de rapport trouvÃ©." -ForegroundColor Green
        }
    } else {
        Write-Host "RÃ©pertoire des rapports introuvable." -ForegroundColor Yellow
    }
}

# Nettoyer tous les fichiers
if ($CleanAll) {
    # Nettoyer les fichiers de cache Pester
    $pesterCacheDir = Join-Path -Path $env:TEMP -ChildPath "Pester"
    if (Test-Path -Path $pesterCacheDir) {
        $pesterCacheFiles = Get-ChildItem -Path $pesterCacheDir -Recurse
        $pesterCacheFileCount = $pesterCacheFiles.Count
        
        if ($pesterCacheFileCount -gt 0) {
            Write-Host "Fichiers de cache Pester trouvÃ©s : $pesterCacheFileCount" -ForegroundColor Cyan
            
            if (-not $Force -and -not $SkipConfirmation) {
                $confirmation = Read-Host "Voulez-vous supprimer les fichiers de cache Pester ? (O/N)"
                if ($confirmation -ne "O") {
                    Write-Host "Nettoyage des fichiers de cache Pester annulÃ©." -ForegroundColor Yellow
                } else {
                    Remove-Item -Path $pesterCacheDir -Recurse -Force
                    Write-Host "Fichiers de cache Pester supprimÃ©s." -ForegroundColor Green
                }
            } else {
                Remove-Item -Path $pesterCacheDir -Recurse -Force
                Write-Host "Fichiers de cache Pester supprimÃ©s." -ForegroundColor Green
            }
        } else {
            Write-Host "Aucun fichier de cache Pester trouvÃ©." -ForegroundColor Green
        }
    } else {
        Write-Host "RÃ©pertoire de cache Pester introuvable." -ForegroundColor Yellow
    }
}

Write-Host "`nNettoyage terminÃ©." -ForegroundColor Green
exit 0

