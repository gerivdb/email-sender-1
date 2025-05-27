# Exemple de script de validation des instructions Copilot

# Usage :
#   pwsh ./validate-copilot-instructions.ps1

$instructionsPath = ".github/instructions"
$promptsPath = ".github/prompts"

Write-Host "Vérification des fichiers d'instructions Copilot..."

if (!(Test-Path $instructionsPath)) {
    Write-Error "Dossier d'instructions manquant : $instructionsPath"
    exit 1
}
if (!(Test-Path $promptsPath)) {
    Write-Error "Dossier de prompts manquant : $promptsPath"
    exit 1
}

$missing = $false
$requiredFiles = @(
    "modes.instructions.md",
    "augment.instructions.md",
    "plan-executor.instructions.md",
    "standards.instructions.md"
)
foreach ($file in $requiredFiles) {
    if (!(Test-Path (Join-Path $instructionsPath $file))) {
        Write-Warning "Fichier d'instructions manquant : $file"
        $missing = $true
    }
}

if ($missing) {
    Write-Error "Certains fichiers d'instructions sont manquants."
    exit 2
}

Write-Host "Tous les fichiers d'instructions Copilot sont présents."
exit 0
