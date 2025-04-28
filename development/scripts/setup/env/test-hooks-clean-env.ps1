# Script pour tester les hooks Git dans un environnement sans espaces
# Ce script clone le dÃ©pÃ´t dans un rÃ©pertoire temporaire sans espaces et teste les hooks Git


# Script pour tester les hooks Git dans un environnement sans espaces
# Ce script clone le dÃ©pÃ´t dans un rÃ©pertoire temporaire sans espaces et teste les hooks Git

param (
    [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [switch]$CleanupAfter,
    
    [Parameter(Mandatory = $false)]
    [string]$TempDir = "C:\Temp\n8n_test_hooks",
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Fonction pour afficher un message colorÃ©
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Fonction pour afficher un message verbose
function Write-VerboseMessage {
    param (
        [string]$Message
    )
    
    if ($Verbose) {
        Write-ColorMessage $Message -ForegroundColor "Gray"
    }
}

# Obtenir le chemin racine du projet actuel
$currentProjectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Write-ColorMessage "Projet actuel: $currentProjectRoot" -ForegroundColor "Cyan"

# VÃ©rifier si le rÃ©pertoire temporaire existe dÃ©jÃ 
if (Test-Path $TempDir) {
    Write-ColorMessage "Le rÃ©pertoire temporaire $TempDir existe dÃ©jÃ ." -ForegroundColor "Yellow"
    $confirmation = Read-Host "Voulez-vous le supprimer et le recrÃ©er? (O/N)"
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        Write-ColorMessage "Suppression du rÃ©pertoire temporaire..." -ForegroundColor "Yellow"
        Remove-Item -Path $TempDir -Recurse -Force
    }
    else {
        Write-ColorMessage "Utilisation du rÃ©pertoire temporaire existant." -ForegroundColor "Yellow"
    }
}

# CrÃ©er le rÃ©pertoire temporaire s'il n'existe pas
if (-not (Test-Path $TempDir)) {
    Write-ColorMessage "CrÃ©ation du rÃ©pertoire temporaire $TempDir..." -ForegroundColor "Cyan"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Obtenir l'URL du dÃ©pÃ´t distant
Write-ColorMessage "Obtention de l'URL du dÃ©pÃ´t distant..." -ForegroundColor "Cyan"
$remoteUrl = git -C $currentProjectRoot remote get-url origin
Write-ColorMessage "URL du dÃ©pÃ´t distant: $remoteUrl" -ForegroundColor "White"

# Cloner le dÃ©pÃ´t dans le rÃ©pertoire temporaire
Write-ColorMessage "Clonage du dÃ©pÃ´t dans le rÃ©pertoire temporaire..." -ForegroundColor "Cyan"
git clone $remoteUrl $TempDir

# VÃ©rifier si le clonage a rÃ©ussi
if ($LASTEXITCODE -ne 0) {
    Write-ColorMessage "Erreur lors du clonage du dÃ©pÃ´t." -ForegroundColor "Red"
    exit 1
}

# Se dÃ©placer dans le rÃ©pertoire temporaire
Set-Location $TempDir
Write-ColorMessage "RÃ©pertoire de travail actuel: $(Get-Location)" -ForegroundColor "White"

# Installer les hooks Git
Write-ColorMessage "Installation des hooks Git..." -ForegroundColor "Cyan"
$installScript = Join-Path $TempDir "..\..\D"

if (Test-Path $installScript) {
    & $installScript -Force
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorMessage "Erreur lors de l'installation des hooks Git." -ForegroundColor "Red"
        exit 1
    }
}
else {
    Write-ColorMessage "Script d'installation des hooks Git non trouvÃ©: $installScript" -ForegroundColor "Red"
    exit 1
}

# CrÃ©er un fichier de test
Write-ColorMessage "CrÃ©ation d'un fichier de test..." -ForegroundColor "Cyan"
$testFile = Join-Path $TempDir "test-file.txt"
Set-Content -Path $testFile -Value "Ceci est un fichier de test crÃ©Ã© le $(Get-Date)"

# Ajouter le fichier au dÃ©pÃ´t
Write-ColorMessage "Ajout du fichier au dÃ©pÃ´t..." -ForegroundColor "Cyan"
git add $testFile

# Tester le hook pre-commit
Write-ColorMessage "Test du hook pre-commit..." -ForegroundColor "Cyan"
$commitOutput = git commit -m "Test du hook pre-commit" 2>&1

# VÃ©rifier si le commit a rÃ©ussi
if ($LASTEXITCODE -eq 0) {
    Write-ColorMessage "Le hook pre-commit a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s." -ForegroundColor "Green"
    Write-ColorMessage "Sortie du commit:" -ForegroundColor "White"
    $commitOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
}
else {
    Write-ColorMessage "Erreur lors de l'exÃ©cution du hook pre-commit." -ForegroundColor "Red"
    Write-ColorMessage "Sortie du commit:" -ForegroundColor "Red"
    $commitOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "Red" }
    
    # Essayer avec --no-verify pour voir si c'est bien le hook qui pose problÃ¨me
    Write-ColorMessage "Tentative de commit avec --no-verify..." -ForegroundColor "Yellow"
    $commitNoVerifyOutput = git commit --no-verify -m "Test du hook pre-commit (no-verify)" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorMessage "Le commit a rÃ©ussi avec --no-verify, ce qui confirme que le problÃ¨me vient du hook." -ForegroundColor "Yellow"
    }
    else {
        Write-ColorMessage "Le commit a Ã©chouÃ© mÃªme avec --no-verify, ce qui suggÃ¨re un autre problÃ¨me." -ForegroundColor "Red"
    }
}

# Tester le hook pre-push (si le commit a rÃ©ussi)
if ($LASTEXITCODE -eq 0) {
    Write-ColorMessage "Test du hook pre-push..." -ForegroundColor "Cyan"
    
    # CrÃ©er une branche temporaire pour le test
    $testBranch = "test-hooks-$(Get-Date -Format 'yyyyMMddHHmmss')"
    git checkout -b $testBranch
    
    # Essayer de pousser la branche
    $pushOutput = git push --set-upstream origin $testBranch 2>&1
    
    # VÃ©rifier si le push a rÃ©ussi
    if ($LASTEXITCODE -eq 0) {
        Write-ColorMessage "Le hook pre-push a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s." -ForegroundColor "Green"
        Write-ColorMessage "Sortie du push:" -ForegroundColor "White"
        $pushOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "White" }
        
        # Supprimer la branche distante
        Write-ColorMessage "Suppression de la branche distante..." -ForegroundColor "Cyan"
        git push origin --delete $testBranch
    }
    else {
        Write-ColorMessage "Erreur lors de l'exÃ©cution du hook pre-push." -ForegroundColor "Red"
        Write-ColorMessage "Sortie du push:" -ForegroundColor "Red"
        $pushOutput | ForEach-Object { Write-ColorMessage "  $_" -ForegroundColor "Red" }
        
        # Essayer avec --no-verify pour voir si c'est bien le hook qui pose problÃ¨me
        Write-ColorMessage "Tentative de push avec --no-verify..." -ForegroundColor "Yellow"
        $pushNoVerifyOutput = git push --no-verify --set-upstream origin $testBranch 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "Le push a rÃ©ussi avec --no-verify, ce qui confirme que le problÃ¨me vient du hook." -ForegroundColor "Yellow"
            
            # Supprimer la branche distante
            Write-ColorMessage "Suppression de la branche distante..." -ForegroundColor "Cyan"
            git push origin --delete $testBranch
        }
        else {
            Write-ColorMessage "Le push a Ã©chouÃ© mÃªme avec --no-verify, ce qui suggÃ¨re un autre problÃ¨me." -ForegroundColor "Red"
        }
    }
}

# Nettoyer si demandÃ©
if ($CleanupAfter) {
    Write-ColorMessage "Nettoyage du rÃ©pertoire temporaire..." -ForegroundColor "Cyan"
    Set-Location $currentProjectRoot
    Remove-Item -Path $TempDir -Recurse -Force
    Write-ColorMessage "RÃ©pertoire temporaire supprimÃ©." -ForegroundColor "Green"
}
else {
    Write-ColorMessage "Le rÃ©pertoire temporaire $TempDir a Ã©tÃ© conservÃ© pour inspection." -ForegroundColor "Yellow"
    Write-ColorMessage "N'oubliez pas de le supprimer manuellement lorsque vous avez terminÃ©." -ForegroundColor "Yellow"
}

# Revenir au rÃ©pertoire du projet
Set-Location $currentProjectRoot
Write-ColorMessage "Retour au rÃ©pertoire du projet: $currentProjectRoot" -ForegroundColor "Cyan"

# Afficher un rÃ©sumÃ©
Write-ColorMessage "`nRÃ©sumÃ© des tests:" -ForegroundColor "Cyan"
Write-ColorMessage "- RÃ©pertoire de test: $TempDir" -ForegroundColor "White"
Write-ColorMessage "- Hook pre-commit: $(if ($LASTEXITCODE -eq 0) { 'SuccÃ¨s' } else { 'Ã‰chec' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" })
Write-ColorMessage "- Hook pre-push: $(if ($LASTEXITCODE -eq 0) { 'SuccÃ¨s' } else { 'Ã‰chec' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" })

# Afficher l'aide si demandÃ©
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-ColorMessage "`nUtilisation: .\test-hooks-clean-env.ps1 [options]" -ForegroundColor "Cyan"
    Write-ColorMessage "`nOptions:" -ForegroundColor "Cyan"
    Write-ColorMessage "  -CleanupAfter    Supprimer le rÃ©pertoire temporaire aprÃ¨s les tests" -ForegroundColor "Cyan"
    Write-ColorMessage "  -TempDir <path>  SpÃ©cifier un rÃ©pertoire temporaire personnalisÃ©" -ForegroundColor "Cyan"
    Write-ColorMessage "  -Verbose         Afficher des informations dÃ©taillÃ©es" -ForegroundColor "Cyan"
    Write-ColorMessage "`nExemples:" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\test-hooks-clean-env.ps1" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\test-hooks-clean-env.ps1 -CleanupAfter" -ForegroundColor "Cyan"
    Write-ColorMessage "  .\test-hooks-clean-env.ps1 -TempDir D:\Temp\n8n_test" -ForegroundColor "Cyan"
}


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
