# Installation automatique d'Enable-UnixCommands.ps1
# Utilisation: .\Install-UnixCommands.ps1

param(
   [switch]$Remove
)

$scriptPath = Join-Path $PSScriptRoot "Enable-UnixCommands.ps1"
$profileLine = ". `"$scriptPath`""

# Créer le profil s'il n'existe pas
if (-not (Test-Path $PROFILE)) {
   $profileDir = Split-Path $PROFILE -Parent
   if (-not (Test-Path $profileDir)) {
      New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
   }
   New-Item -ItemType File -Path $PROFILE -Force | Out-Null
   Write-Host "✅ Profil PowerShell créé: $PROFILE" -ForegroundColor Green
}

# Lire le contenu actuel du profil
$profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue

if ($Remove) {
   # Supprimer le script du profil
   if ($profileContent -contains $profileLine) {
      $newContent = $profileContent | Where-Object { $_ -ne $profileLine }
      Set-Content $PROFILE $newContent
      Write-Host "✅ Enable-UnixCommands.ps1 supprimé du profil PowerShell" -ForegroundColor Green
   }
   else {
      Write-Host "ℹ️  Enable-UnixCommands.ps1 n'était pas dans le profil" -ForegroundColor Yellow
   }
}
else {
   # Ajouter le script au profil
   if ($profileContent -notcontains $profileLine) {
      Add-Content $PROFILE "`n# Pour activer les commandes Unix dans chaque session PowerShell"
      Add-Content $PROFILE $profileLine
      Write-Host "✅ Enable-UnixCommands.ps1 ajouté au profil PowerShell" -ForegroundColor Green
      Write-Host "🔄 Redémarrez PowerShell ou exécutez: . `$PROFILE" -ForegroundColor Yellow
   }
   else {
      Write-Host "ℹ️  Enable-UnixCommands.ps1 déjà configuré dans le profil" -ForegroundColor Cyan
   }
}

Write-Host "`n📍 Profil PowerShell: $PROFILE" -ForegroundColor Magenta
Write-Host "📍 Script Unix: $scriptPath" -ForegroundColor Magenta
