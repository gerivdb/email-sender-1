# Script simple pour activer les commandes Unix dans PowerShell
# Utilisation: . .\Enable-UnixCommands.ps1

# Vérifier si Git Bash est disponible
$GitBashPaths = @(
   "C:\Program Files\Git\bin\bash.exe",
   "C:\Program Files (x86)\Git\bin\bash.exe"
)

$GitBashPath = $null
foreach ($path in $GitBashPaths) {
   if (Test-Path $path) {
      $GitBashPath = $path
      break
   }
}

if (-not $GitBashPath) {
   Write-Warning "Git Bash non trouvé. Les commandes Unix ne seront pas disponibles."
   return
}

# Marquer que le script a été chargé (pour éviter les chargements multiples)
if ($global:UnixCommandsLoaded) {
   Write-Host "Commandes Unix déjà chargées dans cette session" -ForegroundColor Cyan
   return
}

Write-Host "Git Bash trouvé: $GitBashPath" -ForegroundColor Green

# Fonction pour exécuter des commandes bash
function Invoke-Bash {
   param(
      [Parameter(Mandatory = $true)]
      [string]$Command,
      [Parameter(ValueFromRemainingArguments = $true)]
      [string[]]$Arguments
   )
    
   # Convertir les chemins Windows en chemins Unix
   $convertedArgs = $Arguments | ForEach-Object {
      if ($_ -match '^[a-zA-Z]:\\' -or $_ -match '^\.\\\S+') {
         # Convertir le chemin Windows en chemin Unix pour Git Bash
         $unixPath = $_ -replace '\\', '/'
         if ($unixPath -match '^[a-zA-Z]:') {
            # Convertir C:\path en /c/path
            $drive = $unixPath.Substring(0, 1).ToLower()
            $unixPath = "/$drive" + $unixPath.Substring(2)
         }
         "`"$unixPath`""
      }
      else {
         # Garder les autres arguments tels quels
         if ($_ -match '\s') { "`"$_`"" } else { $_ }
      }
   }
    
   $fullCommand = if ($convertedArgs) {
      "$Command " + ($convertedArgs -join ' ')
   }
   else {
      $Command
   }
    
   & $GitBashPath -c $fullCommand
}

# Créer des alias pour les commandes Unix courantes
function grep { Invoke-Bash "grep" @args }
function awk { Invoke-Bash "awk" @args }
function sed { Invoke-Bash "sed" @args }
function find { Invoke-Bash "find" @args }
function cat { Invoke-Bash "cat" @args }
function tail { Invoke-Bash "tail" @args }
function head { Invoke-Bash "head" @args }
function wc { Invoke-Bash "wc" @args }
function sort { Invoke-Bash "sort" @args }
function uniq { Invoke-Bash "uniq" @args }
function cut { Invoke-Bash "cut" @args }
function tr { Invoke-Bash "tr" @args }

Write-Host "Commandes Unix activées : grep, awk, sed, find, cat, tail, head, wc, sort, uniq, cut, tr" -ForegroundColor Green
Write-Host "Utilisation: grep 'pattern' file.txt" -ForegroundColor Yellow

# Marquer comme chargé
$global:UnixCommandsLoaded = $true

# Fonction d'aide pour les commandes Unix
function Show-UnixHelp {
   Write-Host "`n🔧 Commandes Unix disponibles :" -ForegroundColor Cyan
   Write-Host "  grep 'pattern' file.txt    - Rechercher du texte" -ForegroundColor White
   Write-Host "  find . -name '*.go'        - Trouver des fichiers" -ForegroundColor White
   Write-Host "  cat file.txt               - Afficher le contenu" -ForegroundColor White
   Write-Host "  head -n 5 file.txt         - Premières lignes" -ForegroundColor White
   Write-Host "  tail -n 5 file.txt         - Dernières lignes" -ForegroundColor White
   Write-Host "  wc -l file.txt             - Compter les lignes" -ForegroundColor White
   Write-Host "  sort file.txt              - Trier les lignes" -ForegroundColor White
   Write-Host "`n💡 Alternatives PowerShell natives :" -ForegroundColor Yellow
   Write-Host "  Get-Content | Select-String   - Équivalent de grep" -ForegroundColor White
   Write-Host "  Get-ChildItem -Recurse        - Équivalent de find" -ForegroundColor White
   Write-Host "  Get-Content | Select -First   - Équivalent de head" -ForegroundColor White
   Write-Host "`n"
}

# Créer un alias pour l'aide
Set-Alias unix-help Show-UnixHelp
Set-Alias uh Show-UnixHelp
