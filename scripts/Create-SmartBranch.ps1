# Création automatique de branches selon le contexte
param(
   [Parameter(Mandatory = $true)]
   [ValidateSet("phase", "manager", "hotfix", "experimental")]
   [string]$Type,
    
   [Parameter(Mandatory = $true)]
   [string]$Name,
    
   [string]$Description = "",
   [string]$BaseBranch = "planning-ecosystem-sync"
)

# Configuration
$ErrorActionPreference = "Stop"

function Write-StatusMessage {
   param([string]$Message, [string]$Color = "White")
   Write-Host "🚀 $Message" -ForegroundColor $Color
}

function Get-BranchName {
   param([string]$Type, [string]$Name, [string]$Description)
    
   switch ($Type) {
      "phase" { 
         if ($Description) {
            return "feature/phase-$Name-$Description"
         }
         else {
            return "feature/phase-$Name"
         }
      }
      "manager" { return "feature/$Name-manager" }
      "hotfix" { return "hotfix/$Name" }
      "experimental" { return "experimental/$Name" }
      default { throw "Type de branche non supporté: $Type" }
   }
}

# Validation de l'environnement Git
Write-StatusMessage "Vérification de l'environnement Git..." "Cyan"

# Vérifier le statut Git
$gitStatus = git status --porcelain
if ($gitStatus) {
   Write-Warning "⚠️  Changements non committés détectés. Voulez-vous continuer? (y/N)"
   $continue = Read-Host
   if ($continue -ne "y" -and $continue -ne "Y") {
      Write-Host "❌ Opération annulée" -ForegroundColor Red
      exit 1
   }
}

# Basculer vers la branche de base
Write-StatusMessage "Basculement vers la branche de base: $BaseBranch" "Yellow"
git checkout $BaseBranch
if ($LASTEXITCODE -ne 0) {
   throw "Impossible de basculer vers $BaseBranch"
}

# Mettre à jour la branche de base
Write-StatusMessage "Mise à jour de $BaseBranch depuis origin" "Yellow"
git pull origin $BaseBranch
if ($LASTEXITCODE -ne 0) {
   Write-Warning "⚠️  Impossible de mettre à jour depuis origin. Continuer?"
}

# Créer la nouvelle branche
$branchName = Get-BranchName -Type $Type -Name $Name -Description $Description
Write-StatusMessage "Création de la branche: $branchName" "Green"

git checkout -b $branchName
if ($LASTEXITCODE -ne 0) {
   throw "Impossible de créer la branche $branchName"
}

# Configuration de la branche pour le tracking
git push -u origin $branchName
if ($LASTEXITCODE -ne 0) {
   Write-Warning "⚠️  Impossible de pousser la branche vers origin. Configuration locale seulement."
}

# Affichage des informations
Write-StatusMessage "✅ Branche créée avec succès!" "Green"
Write-Host ""
Write-Host "📋 Informations de la branche:" -ForegroundColor Cyan
Write-Host "   Nom: $branchName" -ForegroundColor White
Write-Host "   Base: $BaseBranch" -ForegroundColor White
Write-Host "   Type: $Type" -ForegroundColor White
Write-Host ""

# Suggestions de commandes suivantes
Write-Host "💡 Prochaines étapes suggérées:" -ForegroundColor Cyan
switch ($Type) {
   "phase" {
      Write-Host "   1. Créer la structure selon plan-dev-v55" -ForegroundColor Gray
      Write-Host "   2. Implémenter les tâches de la phase $Name" -ForegroundColor Gray
      Write-Host "   3. Ajouter les tests unitaires" -ForegroundColor Gray
   }
   "manager" {
      Write-Host "   1. Créer l'interface dans interfaces/" -ForegroundColor Gray
      Write-Host "   2. Implémenter le manager dans development/managers/" -ForegroundColor Gray
      Write-Host "   3. Ajouter les tests et la documentation" -ForegroundColor Gray
   }
   "hotfix" {
      Write-Host "   1. Identifier et corriger le problème critique" -ForegroundColor Gray
      Write-Host "   2. Ajouter des tests de régression" -ForegroundColor Gray
      Write-Host "   3. Créer une PR urgente" -ForegroundColor Gray
   }
   "experimental" {
      Write-Host "   1. Développer le proof of concept" -ForegroundColor Gray
      Write-Host "   2. Documenter les résultats" -ForegroundColor Gray
      Write-Host "   3. Décider de l'intégration ou abandon" -ForegroundColor Gray
   }
}

Write-Host ""
Write-Host "🔄 Pour créer une PR:" -ForegroundColor Cyan
Write-Host "   gh pr create --base $BaseBranch --title 'feat($Type): $Name' --body 'Description détaillée'" -ForegroundColor Gray
