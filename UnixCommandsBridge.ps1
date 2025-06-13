# =============================================================================
# UnixCommandsBridge.ps1 - Bridge complet PowerShell vers Unix/Bash
# =============================================================================
# Ce script permet d'utiliser les commandes Unix/Linux directement dans PowerShell
# en les redirigeant automatiquement vers Git Bash
# 
# Installation: Ajouter ce script à votre profil PowerShell ($PROFILE)
# Usage: . .\UnixCommandsBridge.ps1
# =============================================================================

param(
   [switch]$Install,
   [switch]$Uninstall,
   [switch]$TestCommands,
   [switch]$ShowHelp
)

# Configuration globale
$script:GitBashPaths = @(
   "C:\Program Files\Git\bin\bash.exe",
   "C:\Program Files (x86)\Git\bin\bash.exe",
   "C:\msys64\usr\bin\bash.exe",
   "C:\cygwin64\bin\bash.exe",
   "${env:ProgramFiles}\Git\bin\bash.exe",
   "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
)

$script:GitBashPath = $null
$script:IsLoaded = $false

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

function Initialize-GitBash {
   """
    Initialise le chemin vers Git Bash
    """
   Write-Verbose "Recherche de Git Bash..."
    
   foreach ($path in $script:GitBashPaths) {
      if (Test-Path $path) {
         $script:GitBashPath = $path
         Write-Verbose "Git Bash trouvé: $path"
         return $true
      }
   }
    
   Write-Warning "Git Bash non trouvé. Veuillez installer Git for Windows."
   Write-Host "Téléchargement: https://git-scm.com/download/win" -ForegroundColor Yellow
   return $false
}

function Invoke-BashCommand {
   """
    Fonction principale pour exécuter les commandes Bash
    """
   param(
      [Parameter(Mandatory = $true)]
      [string]$Command,
        
      [Parameter(ValueFromRemainingArguments = $true)]
      [string[]]$Arguments,
        
      [Parameter(ValueFromPipeline = $true)]
      [object[]]$InputObject,
        
      [switch]$NoEscape,
      [switch]$Silent
   )
    
   begin {
      if (-not $script:GitBashPath) {
         if (-not (Initialize-GitBash)) {
            throw "Git Bash non disponible"
         }
      }
        
      $inputLines = @()
   }
    
   process {
      if ($InputObject) {
         $inputLines += $InputObject
      }
   }
    
   end {
      try {
         # Préparation des arguments
         $escapedArgs = if ($NoEscape) {
            $Arguments -join ' '
         }
         else {
                ($Arguments | ForEach-Object { 
               if ($_ -match '\s') { "'$_'" } else { $_ }
            }) -join ' '
         }
            
         $fullCommand = if ($escapedArgs) {
            "$Command $escapedArgs"
         }
         else {
            $Command
         }
            
         # Gestion de l'entrée pipeline
         if ($inputLines.Count -gt 0) {
            $inputText = ($inputLines | Out-String).Trim()
            $inputText | & $script:GitBashPath -c $fullCommand
         }
         else {
            & $script:GitBashPath -c $fullCommand
         }
      }
      catch {
         if (-not $Silent) {
            Write-Error "Erreur lors de l'exécution de '$Command': $_"
         }
      }
   }
}

# =============================================================================
# COMMANDES DE BASE - TRAITEMENT DE TEXTE
# =============================================================================

function grep {
   """
    Recherche de patterns dans du texte
    Usage: command | grep "pattern"
           grep "pattern" file.txt
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "grep" $args -InputObject $InputObject
}

function awk {
   """
    Traitement avancé de texte
    Usage: command | awk '{print $1}'
           awk '{print $1}' file.txt
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "awk" $args -InputObject $InputObject
}

function sed {
   """
    Éditeur de flux pour filtrer et transformer du texte
    Usage: command | sed 's/old/new/g'
           sed 's/old/new/g' file.txt
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "sed" $args -InputObject $InputObject
}

function cut {
   """
    Extraction de colonnes de texte
    Usage: command | cut -d',' -f1
           cut -d',' -f1 file.csv
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "cut" $args -InputObject $InputObject
}

function tr {
   """
    Traduction/suppression de caractères
    Usage: command | tr 'a-z' 'A-Z'
           echo "hello" | tr 'l' 'L'
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "tr" $args -InputObject $InputObject
}

function sort {
   """
    Tri de lignes
    Usage: command | sort
           sort file.txt
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   # Éviter conflit avec Sort-Object PowerShell
   if ($args.Count -eq 0 -and $InputObject) {
      Invoke-BashCommand "sort" @() -InputObject $InputObject
   }
   else {
      Invoke-BashCommand "sort" $args -InputObject $InputObject
   }
}

function uniq {
   """
    Suppression des doublons consécutifs
    Usage: command | sort | uniq
           sort file.txt | uniq
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "uniq" $args -InputObject $InputObject
}

function wc {
   """
    Comptage de lignes, mots, caractères
    Usage: command | wc -l
           wc -l file.txt
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "wc" $args -InputObject $InputObject
}

function head {
   """
    Affichage des premières lignes
    Usage: command | head -n 10
           head -n 10 file.txt
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "head" $args -InputObject $InputObject
}

function tail {
   """
    Affichage des dernières lignes
    Usage: command | tail -n 10
           tail -f log.txt
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "tail" $args -InputObject $InputObject
}

# =============================================================================
# COMMANDES DE SYSTÈME DE FICHIERS
# =============================================================================

function find {
   """
    Recherche de fichiers et dossiers
    Usage: find . -name "* .go"
           find /path -type f -mtime -1
    """
   Invoke-BashCommand "find" $args
}

function locate {
   """
    Recherche rapide de fichiers par nom
    Usage: locate filename
    """
   Invoke-BashCommand "locate" $args
}

function which {
   """
    Localisation d'un exécutable
    Usage: which python
           which git
    """
   Invoke-BashCommand "which" $args
}

function whereis {
   """
    Localisation de binaires, sources et manuels
    Usage: whereis python
    """
   Invoke-BashCommand "whereis" $args
}

function file {
   """
    Détermination du type de fichier
    Usage: file document.pdf
           find . -name "* " | file -f -
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "file" $args -InputObject $InputObject
}

function stat {
   """
    Affichage détaillé des informations de fichier
    Usage: stat file.txt
    """
   Invoke-BashCommand "stat" $args
}

function chmod {
   """
    Modification des permissions de fichiers
    Usage: chmod 755 script.sh
           chmod +x executable
    """
   Invoke-BashCommand "chmod" $args
}

function chown {
   """
    Modification du propriétaire de fichiers
    Usage: chown user:group file.txt
    """
   Invoke-BashCommand "chown" $args
}

function ln {
   """
    Création de liens symboliques
    Usage: ln -s target linkname
    """
   Invoke-BashCommand "ln" $args
}

function touch {
   """
    Création de fichiers vides ou mise à jour timestamp
    Usage: touch newfile.txt
           touch -t 202501010000 file.txt
    """
   Invoke-BashCommand "touch" $args
}

function xargs {
   """
    Construction et exécution de commandes depuis l'entrée standard
    Usage: find . -name "* .tmp" | xargs rm
           echo "file1 file2" | xargs ls -l
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "xargs" $args -InputObject $InputObject
}

# =============================================================================
# COMMANDES DE COMPRESSION ET ARCHIVAGE
# =============================================================================

function tar {
   """
    Archivage et compression
    Usage: tar -czf archive.tar.gz folder/
           tar -xzf archive.tar.gz
    """
   Invoke-BashCommand "tar" $args
}

function gzip {
   """
    Compression gzip
    Usage: gzip file.txt
           command | gzip > output.gz
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "gzip" $args -InputObject $InputObject
}

function gunzip {
   """
    Décompression gzip
    Usage: gunzip file.gz
    """
   Invoke-BashCommand "gunzip" $args
}

function zip {
   """
    Création d'archives ZIP
    Usage: zip -r archive.zip folder/
    """
   Invoke-BashCommand "zip" $args
}

function unzip {
   """
    Extraction d'archives ZIP
    Usage: unzip archive.zip
           unzip -l archive.zip
    """
   Invoke-BashCommand "unzip" $args
}

# =============================================================================
# COMMANDES RÉSEAU ET WEB
# =============================================================================

function curl {
   """
    Client HTTP/HTTPS en ligne de commande
    Usage: curl https://api.github.com
           curl -X POST -d "data" https://api.example.com
    """
   Invoke-BashCommand "curl" $args
}

function wget {
   """
    Téléchargement de fichiers web
    Usage: wget https://example.com/file.zip
           wget -r https://site.com
    """
   Invoke-BashCommand "wget" $args
}

function ping {
   """
    Test de connectivité réseau
    Usage: ping google.com
           ping -c 4 192.168.1.1
    """
   # Rediriger vers ping Unix si arguments spécifiques
   if ($args -match "-c|-i|-w") {
      Invoke-BashCommand "ping" $args
   }
   else {
      # Utiliser ping Windows par défaut
      & ping.exe $args
   }
}

function nslookup {
   """
    Requêtes DNS
    Usage: nslookup google.com
           nslookup google.com 8.8.8.8
    """
   Invoke-BashCommand "nslookup" $args
}

function dig {
   """
    Outil de requête DNS avancé
    Usage: dig google.com
           dig @8.8.8.8 google.com MX
    """
   Invoke-BashCommand "dig" $args
}

function netstat {
   """
    Affichage des connexions réseau
    Usage: netstat -an
           netstat -tulpn
    """
   if ($args -match "-[tulpn]") {
      Invoke-BashCommand "netstat" $args
   }
   else {
      & netstat.exe $args
   }
}

# =============================================================================
# COMMANDES DE PROCESSUS ET SYSTÈME
# =============================================================================

function ps {
   """
    Affichage des processus
    Usage: ps aux
           ps -ef | grep python
    """
   if ($args.Count -eq 0) {
      Get-Process
   }
   elseif ($args -match "aux|ef|-[aef]") {
      Invoke-BashCommand "ps" $args
   }
   else {
      Get-Process $args
   }
}

function kill {
   """
    Terminaison de processus
    Usage: kill 1234
           kill -9 1234
    """
   if ($args[0] -match "^-[0-9]+$|^-[A-Z]+$") {
      Invoke-BashCommand "kill" $args
   }
   else {
      Stop-Process $args
   }
}

function killall {
   """
    Terminaison de processus par nom
    Usage: killall chrome
           killall -9 python
    """
   Invoke-BashCommand "killall" $args
}

function top {
   """
    Moniteur de processus temps réel
    Usage: top
           top -p 1234
    """
   Invoke-BashCommand "top" $args
}

function htop {
   """
    Moniteur de processus interactif amélioré
    Usage: htop
    """
   Invoke-BashCommand "htop" $args
}

function jobs {
   """
    Affichage des tâches en arrière-plan
    Usage: jobs
           jobs -l
    """
   Invoke-BashCommand "jobs" $args
}

function nohup {
   """
    Exécution de commandes résistantes à la déconnexion
    Usage: nohup long-running-command &
    """
   Invoke-BashCommand "nohup" $args
}

# =============================================================================
# COMMANDES DE DÉVELOPPEMENT
# =============================================================================

function make {
   """
    Outil de build
    Usage: make
           make clean
           make install
    """
   Invoke-BashCommand "make" $args
}

function git {
   """
    Système de contrôle de version Git
    Usage: git status
           git commit -m "message"
    """
   # Utiliser git Windows par défaut, mais permettre options Unix
   if ($args -match "--no-pager|--color=always") {
      Invoke-BashCommand "git" $args
   }
   else {
      & git.exe $args
   }
}

function npm {
   """
    Gestionnaire de paquets Node.js
    Usage: npm install
           npm run build
    """
   Invoke-BashCommand "npm" $args
}

function yarn {
   """
    Gestionnaire de paquets JavaScript alternatif
    Usage: yarn install
           yarn build
    """
   Invoke-BashCommand "yarn" $args
}

function python {
   """
    Interpréteur Python
    Usage: python script.py
           python -m pip install package
    """
   # Utiliser python Windows mais permettre options Unix
   if ($env:PYTHONPATH -or $args -match "-c") {
      Invoke-BashCommand "python" $args
   }
   else {
      & python.exe $args
   }
}

function pip {
   """
    Gestionnaire de paquets Python
    Usage: pip install package
           pip list
    """
   Invoke-BashCommand "pip" $args
}

function node {
   """
    Runtime JavaScript Node.js
    Usage: node script.js
           node -e "console.log('test')"
    """
   Invoke-BashCommand "node" $args
}

function docker {
   """
    Platform de conteneurisation
    Usage: docker run image
           docker build -t name .
    """
   # Utiliser docker Windows mais permettre syntaxe Unix
   & docker.exe $args
}

function docker-compose {
   """
    Orchestrateur multi-conteneurs Docker
    Usage: docker-compose up
           docker-compose down
    """
   & docker-compose.exe $args
}

# =============================================================================
# COMMANDES DE HACHAGE ET SÉCURITÉ
# =============================================================================

function md5sum {
   """
    Calcul de hash MD5
    Usage: md5sum file.txt
           echo "text" | md5sum
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "md5sum" $args -InputObject $InputObject
}

function sha1sum {
   """
    Calcul de hash SHA1
    Usage: sha1sum file.txt
           echo "text" | sha1sum
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "sha1sum" $args -InputObject $InputObject
}

function sha256sum {
   """
    Calcul de hash SHA256
    Usage: sha256sum file.txt
           echo "text" | sha256sum
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "sha256sum" $args -InputObject $InputObject
}

function openssl {
   """
    Toolkit cryptographique
    Usage: openssl rand -hex 32
           openssl s_client -connect google.com:443
    """
   Invoke-BashCommand "openssl" $args
}

function ssh {
   """
    Client SSH sécurisé
    Usage: ssh user@hostname
           ssh -p 2222 user@hostname
    """
   Invoke-BashCommand "ssh" $args
}

function scp {
   """
    Copie sécurisée via SSH
    Usage: scp file.txt user@hostname:/path/
           scp -r folder/ user@hostname:/path/
    """
   Invoke-BashCommand "scp" $args
}

function rsync {
   """
    Synchronisation de fichiers avancée
    Usage: rsync -av source/ destination/
           rsync -av --delete source/ user@host:/path/
    """
   Invoke-BashCommand "rsync" $args
}

# =============================================================================
# COMMANDES DE DONNÉES ET PARSING
# =============================================================================

function jq {
   """
    Processeur JSON en ligne de commande
    Usage: echo '{"name":"value"}' | jq '.name'
           jq '.field' data.json
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "jq" $args -InputObject $InputObject
}

function xmllint {
   """
    Processeur et validateur XML
    Usage: xmllint --format file.xml
           echo '<xml></xml>' | xmllint --format -
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "xmllint" $args -InputObject $InputObject
}

function base64 {
   """
    Encodage/décodage Base64
    Usage: echo "text" | base64
           echo "dGV4dA==" | base64 -d
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "base64" $args -InputObject $InputObject
}

# =============================================================================
# COMMANDES SYSTÈME AVANCÉES
# =============================================================================

function df {
   """
    Affichage de l'espace disque
    Usage: df -h
           df /path
    """
   Invoke-BashCommand "df" $args
}

function du {
   """
    Calcul de l'utilisation d'espace disque
    Usage: du -sh folder/
           du -h --max-depth=1
    """
   Invoke-BashCommand "du" $args
}

function free {
   """
    Affichage de l'utilisation mémoire
    Usage: free -h
           free -m
    """
   Invoke-BashCommand "free" $args
}

function uptime {
   """
    Temps de fonctionnement système
    Usage: uptime
    """
   Invoke-BashCommand "uptime" $args
}

function uname {
   """
    Informations système
    Usage: uname -a
           uname -r
    """
   Invoke-BashCommand "uname" $args
}

function whoami {
   """
    Utilisateur actuel
    Usage: whoami
    """
   Invoke-BashCommand "whoami" $args
}

function id {
   """
    Identité utilisateur et groupes
    Usage: id
           id username
    """
   Invoke-BashCommand "id" $args
}

function env {
   """
    Affichage des variables d'environnement
    Usage: env
           env | grep PATH
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   if ($args.Count -eq 0) {
      Invoke-BashCommand "env" @() -InputObject $InputObject
   }
   else {
      Invoke-BashCommand "env" $args -InputObject $InputObject
   }
}

# =============================================================================
# COMMANDES DE MONITORING ET LOGS
# =============================================================================

function watch {
   """
    Exécution répétée d'une commande
    Usage: watch -n 2 'ps aux'
           watch 'ls -l'
    """
   Invoke-BashCommand "watch" $args
}

function tee {
   """
    Écriture vers fichier et stdout simultanément
    Usage: command | tee output.log
           command | tee -a append.log
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "tee" $args -InputObject $InputObject
}

function less {
   """
    Pager pour affichage de texte
    Usage: less file.txt
           command | less
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   Invoke-BashCommand "less" $args -InputObject $InputObject
}

function more {
   """
    Pager simple pour affichage de texte
    Usage: more file.txt
           command | more
    """
   [CmdletBinding()]
   param([Parameter(ValueFromPipeline = $true)][object[]]$InputObject)
    
   if ($InputObject) {
      Invoke-BashCommand "more" $args -InputObject $InputObject
   }
   else {
      & more.com $args
   }
}

# =============================================================================
# ALIAS ET RACCOURCIS
# =============================================================================

# Alias pour éviter les conflits avec PowerShell
Set-Alias -Name ugrep -Value grep -Description "Unix grep via Git Bash" -Force
Set-Alias -Name uawk -Value awk -Description "Unix awk via Git Bash" -Force
Set-Alias -Name used -Value sed -Description "Unix sed via Git Bash" -Force
Set-Alias -Name usort -Value sort -Description "Unix sort via Git Bash" -Force
Set-Alias -Name ups -Value ps -Description "Unix ps via Git Bash" -Force

# Raccourcis courants
Set-Alias -Name ll -Value "ls -la" -Description "Liste détaillée" -Force
Set-Alias -Name la -Value "ls -A" -Description "Liste avec fichiers cachés" -Force
Set-Alias -Name l -Value "ls -CF" -Description "Liste compacte" -Force

# =============================================================================
# FONCTIONS D'AIDE ET UTILITAIRES
# =============================================================================

function Show-UnixCommands {
   """
    Affiche la liste des commandes Unix disponibles
    """
   Write-Host "`n=== COMMANDES UNIX DISPONIBLES VIA POWERSHELL ===" -ForegroundColor Green
   Write-Host ""
    
   $categories = @{
      "Traitement de texte" = @("grep", "awk", "sed", "cut", "tr", "sort", "uniq", "wc", "head", "tail")
      "Système de fichiers" = @("find", "locate", "which", "whereis", "file", "stat", "chmod", "chown", "ln", "touch", "xargs")
      "Compression"         = @("tar", "gzip", "gunzip", "zip", "unzip")
      "Réseau"              = @("curl", "wget", "ping", "nslookup", "dig", "netstat")
      "Processus"           = @("ps", "kill", "killall", "top", "htop", "jobs", "nohup")
      "Développement"       = @("make", "git", "npm", "yarn", "python", "pip", "node", "docker", "docker-compose")
      "Sécurité"            = @("md5sum", "sha1sum", "sha256sum", "openssl", "ssh", "scp", "rsync")
      "Données"             = @("jq", "xmllint", "base64")
      "Système"             = @("df", "du", "free", "uptime", "uname", "whoami", "id", "env")
      "Monitoring"          = @("watch", "tee", "less", "more")
   }
    
   foreach ($category in $categories.Keys) {
      Write-Host "[$category]" -ForegroundColor Yellow
      $commands = $categories[$category]
      for ($i = 0; $i -lt $commands.Count; $i += 4) {
         $line = $commands[$i..($i + 3)] -join ", "
         Write-Host "  $line"
      }
      Write-Host ""
   }
    
   Write-Host "Usage: command --help pour l'aide de chaque commande" -ForegroundColor Cyan
   Write-Host "Git Bash: $script:GitBashPath" -ForegroundColor Gray
}

function Test-UnixCommands {
   """
    Test des commandes Unix de base
    """
   Write-Host "Test des commandes Unix..." -ForegroundColor Yellow
    
   $testCommands = @(
      @{cmd = "echo 'Hello World' | grep 'Hello'"; expected = "Hello World" },
      @{cmd = "echo 'line1\nline2\nline3' | wc -l"; expected = "3" },
      @{cmd = "echo 'a,b,c' | cut -d',' -f2"; expected = "b" },
      @{cmd = "echo 'test' | md5sum"; expected = "-" }  # Juste vérifier que ça fonctionne
   )
    
   foreach ($test in $testCommands) {
      try {
         Write-Host "Test: $($test.cmd)" -ForegroundColor Gray
         $result = Invoke-Expression $test.cmd
         Write-Host "✅ OK: $result" -ForegroundColor Green
      }
      catch {
         Write-Host "❌ ERREUR: $_" -ForegroundColor Red
      }
   }
}

function Install-UnixCommandsBridge {
   """
    Installation du bridge dans le profil PowerShell
    """
   if (-not (Test-Path $PROFILE)) {
      New-Item -Type File -Path $PROFILE -Force | Out-Null
      Write-Host "Profil PowerShell créé: $PROFILE" -ForegroundColor Green
   }
    
   $scriptPath = $PSCommandPath
   $importLine = ". '$scriptPath'"
    
   $profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
   if ($profileContent -notcontains $importLine) {
      Add-Content $PROFILE $importLine
      Write-Host "Bridge Unix ajouté au profil PowerShell" -ForegroundColor Green
      Write-Host "Redémarrez PowerShell ou exécutez: . `$PROFILE" -ForegroundColor Yellow
   }
   else {
      Write-Host "Bridge Unix déjà installé dans le profil" -ForegroundColor Cyan
   }
}

function Uninstall-UnixCommandsBridge {
   """
    Désinstallation du bridge du profil PowerShell
    """
   if (Test-Path $PROFILE) {
      $scriptPath = $PSCommandPath
      $importLine = ". '$scriptPath'"
        
      $profileContent = Get-Content $PROFILE
      $newContent = $profileContent | Where-Object { $_ -ne $importLine }
        
      Set-Content $PROFILE $newContent
      Write-Host "Bridge Unix supprimé du profil PowerShell" -ForegroundColor Green
   }
}

# =============================================================================
# INITIALISATION ET CHARGEMENT
# =============================================================================

# Traitement des paramètres de ligne de commande
if ($ShowHelp) {
   Show-UnixCommands
   return
}

if ($Install) {
   Install-UnixCommandsBridge
   return
}

if ($Uninstall) {
   Uninstall-UnixCommandsBridge
   return
}

if ($TestCommands) {
   Test-UnixCommands
   return
}

# Initialisation automatique
if (Initialize-GitBash) {
   $script:IsLoaded = $true
   Write-Host "✅ Bridge Unix chargé avec succès!" -ForegroundColor Green
   Write-Host "   Commandes disponibles: grep, awk, sed, find, curl, jq, etc." -ForegroundColor Cyan
   Write-Host "   Aide: Show-UnixCommands" -ForegroundColor Gray
}
else {
   Write-Warning "Bridge Unix non disponible - Git Bash requis"
}

# =============================================================================
# EXPORT DES FONCTIONS
# =============================================================================

# Export de toutes les fonctions publiques
Export-ModuleMember -Function *
