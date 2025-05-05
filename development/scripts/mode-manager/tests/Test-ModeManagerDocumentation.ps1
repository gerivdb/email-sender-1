# Tests de documentation pour le mode manager

# DÃ©finir le chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable Ã  l'emplacement : $scriptPath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Fonction pour capturer la sortie d'une commande
function Capture-Output {
    param (
        [ScriptBlock]$ScriptBlock
    )
    
    $tempFile = Join-Path -Path $testDir -ChildPath "output.txt"
    & $ScriptBlock | Out-File -FilePath $tempFile -Encoding UTF8
    return Get-Content -Path $tempFile -Raw
}

# Test 1: VÃ©rification de l'aide intÃ©grÃ©e
Write-Host "Test 1: VÃ©rification de l'aide intÃ©grÃ©e" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande d'aide
    $helpOutput = Capture-Output {
        & $scriptPath -Help
    }
    
    # VÃ©rifier que l'aide contient des informations utiles
    $success = $true
    $requiredSections = @(
        "SYNOPSIS",
        "DESCRIPTION",
        "PARAMETERS",
        "EXAMPLES"
    )
    
    foreach ($section in $requiredSections) {
        if (-not ($helpOutput -match $section)) {
            Write-Host "Test 1 Ã©chouÃ©: L'aide ne contient pas la section $section" -ForegroundColor Red
            $success = $false
        }
    }
    
    # VÃ©rifier que l'aide contient des informations sur les paramÃ¨tres
    $requiredParameters = @(
        "-Mode",
        "-FilePath",
        "-TaskIdentifier",
        "-Force",
        "-ConfigPath",
        "-Help"
    )
    
    foreach ($parameter in $requiredParameters) {
        if (-not ($helpOutput -match $parameter)) {
            Write-Host "Test 1 Ã©chouÃ©: L'aide ne contient pas d'informations sur le paramÃ¨tre $parameter" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 1 rÃ©ussi: L'aide intÃ©grÃ©e contient toutes les sections et paramÃ¨tres requis" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de l'aide intÃ©grÃ©e" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: VÃ©rification des exemples d'utilisation
Write-Host "Test 2: VÃ©rification des exemples d'utilisation" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande d'aide
    $helpOutput = Capture-Output {
        & $scriptPath -Help
    }
    
    # VÃ©rifier que l'aide contient des exemples d'utilisation
    if ($helpOutput -match "EXAMPLES") {
        # Extraire les exemples
        $examplesMatch = $helpOutput -match "EXAMPLES([\s\S]*?)(?:\r?\n\s*\r?\n\s*[A-Z]+:|$)"
        if ($examplesMatch) {
            $examples = $Matches[1]
            
            # VÃ©rifier que les exemples contiennent des commandes PowerShell
            if ($examples -match ".\\\s*mode-manager\.ps1") {
                Write-Host "Test 2 rÃ©ussi: L'aide contient des exemples d'utilisation" -ForegroundColor Green
            } else {
                Write-Host "Test 2 Ã©chouÃ©: Les exemples ne contiennent pas de commandes PowerShell" -ForegroundColor Red
            }
        } else {
            Write-Host "Test 2 Ã©chouÃ©: Impossible d'extraire les exemples de l'aide" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 Ã©chouÃ©: L'aide ne contient pas la section EXAMPLES" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification des exemples d'utilisation" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: VÃ©rification de la documentation des modes
Write-Host "Test 3: VÃ©rification de la documentation des modes" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande de liste des modes
    $modesOutput = Capture-Output {
        & $scriptPath -ListModes
    }
    
    # VÃ©rifier que la liste des modes contient des descriptions
    $success = $true
    $requiredModes = @(
        "ARCHI",
        "CHECK",
        "DEBUG",
        "DEV-R",
        "GRAN",
        "OPTI",
        "REVIEW",
        "TEST"
    )
    
    foreach ($mode in $requiredModes) {
        if (-not ($modesOutput -match "$mode\s*:")) {
            Write-Host "Test 3 Ã©chouÃ©: La liste des modes ne contient pas le mode $mode" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 3 rÃ©ussi: La liste des modes contient tous les modes requis" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 3 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de la documentation des modes" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: VÃ©rification de la documentation des paramÃ¨tres
Write-Host "Test 4: VÃ©rification de la documentation des paramÃ¨tres" -ForegroundColor Cyan
try {
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $scriptPath -Raw
    
    # VÃ©rifier que les paramÃ¨tres sont documentÃ©s
    $success = $true
    $requiredParameters = @(
        "Mode",
        "FilePath",
        "TaskIdentifier",
        "Force",
        "ConfigPath",
        "Help"
    )
    
    foreach ($parameter in $requiredParameters) {
        $parameterPattern = "\[Parameter\([^\)]*\)\]\s*\[(?:string|switch)[^\]]*\]\s*\$($parameter)"
        if (-not ($scriptContent -match $parameterPattern)) {
            Write-Host "Test 4 Ã©chouÃ©: Le paramÃ¨tre $parameter n'est pas correctement documentÃ©" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 4 rÃ©ussi: Tous les paramÃ¨tres sont correctement documentÃ©s" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 4 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de la documentation des paramÃ¨tres" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: VÃ©rification de la documentation des fonctions
Write-Host "Test 5: VÃ©rification de la documentation des fonctions" -ForegroundColor Cyan
try {
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $scriptPath -Raw
    
    # Extraire les fonctions
    $functionMatches = [regex]::Matches($scriptContent, "function\s+([A-Za-z0-9\-_]+)\s*\{")
    $functions = $functionMatches | ForEach-Object { $_.Groups[1].Value }
    
    # VÃ©rifier que les fonctions sont documentÃ©es
    $success = $true
    foreach ($function in $functions) {
        # Rechercher un bloc de commentaires avant la fonction
        $functionPattern = "(?:<#[\s\S]*?#>|#[^\r\n]*(?:\r?\n#[^\r\n]*)*)\s*function\s+$([regex]::Escape($function))\s*\{"
        if (-not ($scriptContent -match $functionPattern)) {
            Write-Host "Test 5 Ã©chouÃ©: La fonction $function n'est pas documentÃ©e" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 5 rÃ©ussi: Toutes les fonctions sont documentÃ©es" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 5 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de la documentation des fonctions" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 6: VÃ©rification des exemples fonctionnels
Write-Host "Test 6: VÃ©rification des exemples fonctionnels" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande d'aide
    $helpOutput = Capture-Output {
        & $scriptPath -Help
    }
    
    # Extraire les exemples
    $examplesMatch = $helpOutput -match "EXAMPLES([\s\S]*?)(?:\r?\n\s*\r?\n\s*[A-Z]+:|$)"
    if ($examplesMatch) {
        $examples = $Matches[1]
        
        # Extraire les commandes des exemples
        $commandMatches = [regex]::Matches($examples, ".\\\s*mode-manager\.ps1\s+([^\r\n]+)")
        $commands = $commandMatches | ForEach-Object { $_.Groups[1].Value }
        
        # VÃ©rifier que les exemples sont fonctionnels
        $success = $true
        foreach ($command in $commands) {
            # CrÃ©er un fichier de roadmap de test
            $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
            "# Test Roadmap" | Set-Content -Path $testRoadmapPath -Encoding UTF8
            
            # Remplacer les chemins de fichier dans la commande
            $modifiedCommand = $command -replace "docs\\plans\\[^\""\s]+", $testRoadmapPath
            
            # ExÃ©cuter la commande
            try {
                $null = Invoke-Expression "& `"$scriptPath`" $modifiedCommand"
                Write-Host "Exemple fonctionnel: & `"$scriptPath`" $modifiedCommand" -ForegroundColor Cyan
            } catch {
                Write-Host "Test 6 Ã©chouÃ©: L'exemple '& `"$scriptPath`" $modifiedCommand' n'est pas fonctionnel" -ForegroundColor Red
                Write-Host "Erreur: $_" -ForegroundColor Red
                $success = $false
            }
        }
        
        if ($success) {
            Write-Host "Test 6 rÃ©ussi: Tous les exemples sont fonctionnels" -ForegroundColor Green
        }
    } else {
        Write-Host "Test 6 Ã©chouÃ©: Impossible d'extraire les exemples de l'aide" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 6 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification des exemples fonctionnels" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

Write-Host "Tests terminÃ©s." -ForegroundColor Cyan
