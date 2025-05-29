# Script PowerShell pour le hook pre-push
# Ce script est exécuté automatiquement avant chaque push

param (
   [Parameter(Mandatory = $false)]
   [switch]$SkipTests,
    
   [Parameter(Mandatory = $false)]
   [switch]$Force,
    
   [Parameter(Mandatory = $false)]
   [switch]$Verbose
)

# Obtenir le chemin racine du projet
$projectRoot = git rev-parse --show-toplevel
Set-Location $projectRoot

# Fonction pour afficher un message coloré
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

Write-ColorMessage "Exécution du hook pre-push PowerShell..." -ForegroundColor "Cyan"

# Vérifications de base avant push
try {
   # Vérifier les conflits non résolus
   Write-VerboseMessage "Vérification des conflits non résolus..."
   $conflictFiles = git diff --name-only --diff-filter=U
    
   if (-not [string]::IsNullOrEmpty($conflictFiles)) {
      Write-ColorMessage "Des conflits non résolus ont été détectés dans les fichiers suivants:" -ForegroundColor "Red"
      $conflictFiles | ForEach-Object {
         Write-ColorMessage "  - $_" -ForegroundColor "Red"
      }
        
      if (-not $Force) {
         Write-ColorMessage "Push annulé à cause des conflits non résolus. Utilisez -Force pour ignorer." -ForegroundColor "Red"
         exit 1
      }
      else {
         Write-ColorMessage "Conflits ignorés (mode Force activé)" -ForegroundColor "Yellow"
      }
   }
    
   # Vérifier si nous sommes à jour avec la branche distante
   Write-VerboseMessage "Vérification de la synchronisation avec la branche distante..."
   $currentBranch = git rev-parse --abbrev-ref HEAD
   $remoteBranch = "origin/$currentBranch"
    
   # Vérifier si la branche distante existe
   $remoteBranchExists = git rev-parse --verify "$remoteBranch" 2>$null
    
   if ($remoteBranchExists -and -not $Force) {
      $behindCommits = git rev-list --count HEAD..$remoteBranch 2>$null
        
      if ($behindCommits -and $behindCommits -gt 0) {
         Write-ColorMessage "Votre branche locale est en retard de $behindCommits commit(s) par rapport à la branche distante." -ForegroundColor "Yellow"
         Write-ColorMessage "Considérez effectuer un 'git pull' avant de pousser." -ForegroundColor "Yellow"
      }
   }
    
   Write-ColorMessage "Vérifications pre-push terminées avec succès." -ForegroundColor "Green"
   exit 0
}
catch {
   Write-ColorMessage "Erreur lors des vérifications pre-push: $_" -ForegroundColor "Red"
    
   if (-not $Force) {
      Write-ColorMessage "Push annulé à cause d'une erreur. Utilisez -Force pour ignorer." -ForegroundColor "Red"
      exit 1
   }
   else {
      Write-ColorMessage "Erreur ignorée (mode Force activé)" -ForegroundColor "Yellow"
      exit 0
   }
}
