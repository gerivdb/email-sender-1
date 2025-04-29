# Script pour nettoyer les fichiers temporaires générés par les tests

# Définir les paramètres
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

# Définir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# Définir les chemins des répertoires à nettoyer
$testsDir = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\tests"
$tempDir = Join-Path -Path $testsDir -ChildPath "temp"
$reportsDir = Join-Path -Path $projectRoot -ChildPath "reports\tests"

# Afficher les informations
Write-Host "Nettoyage des fichiers temporaires générés par les tests" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsDir" -ForegroundColor Cyan
Write-Host "Chemin des fichiers temporaires : $tempDir" -ForegroundColor Cyan
Write-Host "Chemin des rapports : $reportsDir" -ForegroundColor Cyan

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    $tempFiles = Get-ChildItem -Path $tempDir -Recurse
    $tempFileCount = $tempFiles.Count
    
    if ($tempFileCount -gt 0) {
        Write-Host "Fichiers temporaires trouvés : $tempFileCount" -ForegroundColor Cyan
        
        if (-not $Force -and -not $SkipConfirmation) {
            $confirmation = Read-Host "Voulez-vous supprimer les fichiers temporaires ? (O/N)"
            if ($confirmation -ne "O") {
                Write-Host "Nettoyage des fichiers temporaires annulé." -ForegroundColor Yellow
            } else {
                Remove-Item -Path $tempDir -Recurse -Force
                Write-Host "Fichiers temporaires supprimés." -ForegroundColor Green
            }
        } else {
            Remove-Item -Path $tempDir -Recurse -Force
            Write-Host "Fichiers temporaires supprimés." -ForegroundColor Green
        }
    } else {
        Write-Host "Aucun fichier temporaire trouvé." -ForegroundColor Green
    }
} else {
    Write-Host "Répertoire des fichiers temporaires introuvable." -ForegroundColor Yellow
}

# Nettoyer les fichiers de mock
$mockFiles = Get-ChildItem -Path $testsDir -Filter "mock-*.ps1"
$mockFileCount = $mockFiles.Count

if ($mockFileCount -gt 0) {
    Write-Host "Fichiers de mock trouvés : $mockFileCount" -ForegroundColor Cyan
    
    if (-not $Force -and -not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous supprimer les fichiers de mock ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Host "Nettoyage des fichiers de mock annulé." -ForegroundColor Yellow
        } else {
            $mockFiles | Remove-Item -Force
            Write-Host "Fichiers de mock supprimés." -ForegroundColor Green
        }
    } else {
        $mockFiles | Remove-Item -Force
        Write-Host "Fichiers de mock supprimés." -ForegroundColor Green
    }
} else {
    Write-Host "Aucun fichier de mock trouvé." -ForegroundColor Green
}

# Nettoyer les rapports
if ($CleanReports -or $CleanAll) {
    if (Test-Path -Path $reportsDir) {
        $reportFiles = Get-ChildItem -Path $reportsDir -Recurse
        $reportFileCount = $reportFiles.Count
        
        if ($reportFileCount -gt 0) {
            Write-Host "Fichiers de rapport trouvés : $reportFileCount" -ForegroundColor Cyan
            
            if (-not $Force -and -not $SkipConfirmation) {
                $confirmation = Read-Host "Voulez-vous supprimer les fichiers de rapport ? (O/N)"
                if ($confirmation -ne "O") {
                    Write-Host "Nettoyage des fichiers de rapport annulé." -ForegroundColor Yellow
                } else {
                    Remove-Item -Path $reportsDir -Recurse -Force
                    Write-Host "Fichiers de rapport supprimés." -ForegroundColor Green
                }
            } else {
                Remove-Item -Path $reportsDir -Recurse -Force
                Write-Host "Fichiers de rapport supprimés." -ForegroundColor Green
            }
        } else {
            Write-Host "Aucun fichier de rapport trouvé." -ForegroundColor Green
        }
    } else {
        Write-Host "Répertoire des rapports introuvable." -ForegroundColor Yellow
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
            Write-Host "Fichiers de cache Pester trouvés : $pesterCacheFileCount" -ForegroundColor Cyan
            
            if (-not $Force -and -not $SkipConfirmation) {
                $confirmation = Read-Host "Voulez-vous supprimer les fichiers de cache Pester ? (O/N)"
                if ($confirmation -ne "O") {
                    Write-Host "Nettoyage des fichiers de cache Pester annulé." -ForegroundColor Yellow
                } else {
                    Remove-Item -Path $pesterCacheDir -Recurse -Force
                    Write-Host "Fichiers de cache Pester supprimés." -ForegroundColor Green
                }
            } else {
                Remove-Item -Path $pesterCacheDir -Recurse -Force
                Write-Host "Fichiers de cache Pester supprimés." -ForegroundColor Green
            }
        } else {
            Write-Host "Aucun fichier de cache Pester trouvé." -ForegroundColor Green
        }
    } else {
        Write-Host "Répertoire de cache Pester introuvable." -ForegroundColor Yellow
    }
}

Write-Host "`nNettoyage terminé." -ForegroundColor Green
exit 0
