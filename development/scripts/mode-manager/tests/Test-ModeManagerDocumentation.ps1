# Tests de documentation pour le mode manager

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable à l'emplacement : $scriptPath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
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

# Test 1: Vérification de l'aide intégrée
Write-Host "Test 1: Vérification de l'aide intégrée" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande d'aide
    $helpOutput = Capture-Output {
        & $scriptPath -Help
    }
    
    # Vérifier que l'aide contient des informations utiles
    $success = $true
    $requiredSections = @(
        "SYNOPSIS",
        "DESCRIPTION",
        "PARAMETERS",
        "EXAMPLES"
    )
    
    foreach ($section in $requiredSections) {
        if (-not ($helpOutput -match $section)) {
            Write-Host "Test 1 échoué: L'aide ne contient pas la section $section" -ForegroundColor Red
            $success = $false
        }
    }
    
    # Vérifier que l'aide contient des informations sur les paramètres
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
            Write-Host "Test 1 échoué: L'aide ne contient pas d'informations sur le paramètre $parameter" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 1 réussi: L'aide intégrée contient toutes les sections et paramètres requis" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de la vérification de l'aide intégrée" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Vérification des exemples d'utilisation
Write-Host "Test 2: Vérification des exemples d'utilisation" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande d'aide
    $helpOutput = Capture-Output {
        & $scriptPath -Help
    }
    
    # Vérifier que l'aide contient des exemples d'utilisation
    if ($helpOutput -match "EXAMPLES") {
        # Extraire les exemples
        $examplesMatch = $helpOutput -match "EXAMPLES([\s\S]*?)(?:\r?\n\s*\r?\n\s*[A-Z]+:|$)"
        if ($examplesMatch) {
            $examples = $Matches[1]
            
            # Vérifier que les exemples contiennent des commandes PowerShell
            if ($examples -match ".\\\s*mode-manager\.ps1") {
                Write-Host "Test 2 réussi: L'aide contient des exemples d'utilisation" -ForegroundColor Green
            } else {
                Write-Host "Test 2 échoué: Les exemples ne contiennent pas de commandes PowerShell" -ForegroundColor Red
            }
        } else {
            Write-Host "Test 2 échoué: Impossible d'extraire les exemples de l'aide" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 échoué: L'aide ne contient pas la section EXAMPLES" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de la vérification des exemples d'utilisation" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Vérification de la documentation des modes
Write-Host "Test 3: Vérification de la documentation des modes" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande de liste des modes
    $modesOutput = Capture-Output {
        & $scriptPath -ListModes
    }
    
    # Vérifier que la liste des modes contient des descriptions
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
            Write-Host "Test 3 échoué: La liste des modes ne contient pas le mode $mode" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 3 réussi: La liste des modes contient tous les modes requis" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 3 échoué: Une erreur s'est produite lors de la vérification de la documentation des modes" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Vérification de la documentation des paramètres
Write-Host "Test 4: Vérification de la documentation des paramètres" -ForegroundColor Cyan
try {
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $scriptPath -Raw
    
    # Vérifier que les paramètres sont documentés
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
            Write-Host "Test 4 échoué: Le paramètre $parameter n'est pas correctement documenté" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 4 réussi: Tous les paramètres sont correctement documentés" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 4 échoué: Une erreur s'est produite lors de la vérification de la documentation des paramètres" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: Vérification de la documentation des fonctions
Write-Host "Test 5: Vérification de la documentation des fonctions" -ForegroundColor Cyan
try {
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $scriptPath -Raw
    
    # Extraire les fonctions
    $functionMatches = [regex]::Matches($scriptContent, "function\s+([A-Za-z0-9\-_]+)\s*\{")
    $functions = $functionMatches | ForEach-Object { $_.Groups[1].Value }
    
    # Vérifier que les fonctions sont documentées
    $success = $true
    foreach ($function in $functions) {
        # Rechercher un bloc de commentaires avant la fonction
        $functionPattern = "(?:<#[\s\S]*?#>|#[^\r\n]*(?:\r?\n#[^\r\n]*)*)\s*function\s+$([regex]::Escape($function))\s*\{"
        if (-not ($scriptContent -match $functionPattern)) {
            Write-Host "Test 5 échoué: La fonction $function n'est pas documentée" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 5 réussi: Toutes les fonctions sont documentées" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 5 échoué: Une erreur s'est produite lors de la vérification de la documentation des fonctions" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 6: Vérification des exemples fonctionnels
Write-Host "Test 6: Vérification des exemples fonctionnels" -ForegroundColor Cyan
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
        
        # Vérifier que les exemples sont fonctionnels
        $success = $true
        foreach ($command in $commands) {
            # Créer un fichier de roadmap de test
            $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
            "# Test Roadmap" | Set-Content -Path $testRoadmapPath -Encoding UTF8
            
            # Remplacer les chemins de fichier dans la commande
            $modifiedCommand = $command -replace "docs\\plans\\[^\""\s]+", $testRoadmapPath
            
            # Exécuter la commande
            try {
                $null = Invoke-Expression "& `"$scriptPath`" $modifiedCommand"
                Write-Host "Exemple fonctionnel: & `"$scriptPath`" $modifiedCommand" -ForegroundColor Cyan
            } catch {
                Write-Host "Test 6 échoué: L'exemple '& `"$scriptPath`" $modifiedCommand' n'est pas fonctionnel" -ForegroundColor Red
                Write-Host "Erreur: $_" -ForegroundColor Red
                $success = $false
            }
        }
        
        if ($success) {
            Write-Host "Test 6 réussi: Tous les exemples sont fonctionnels" -ForegroundColor Green
        }
    } else {
        Write-Host "Test 6 échoué: Impossible d'extraire les exemples de l'aide" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 6 échoué: Une erreur s'est produite lors de la vérification des exemples fonctionnels" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

Write-Host "Tests terminés." -ForegroundColor Cyan
