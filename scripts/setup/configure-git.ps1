# Script pour configurer Git et GitHub pour le projet Email Sender 1

Write-Host "=== Configuration de Git et GitHub ===" -ForegroundColor Cyan

# VÃ©rifier si Git est installÃ©
$gitVersion = git --version 2>$null
if (-not $gitVersion) {
    Write-Host "âŒ Git n'est pas installÃ© ou n'est pas accessible" -ForegroundColor Red
    Write-Host "Veuillez installer Git depuis https://git-scm.com/downloads"
    exit 1
}

Write-Host "âœ… Git version $gitVersion dÃ©tectÃ©" -ForegroundColor Green

# Configurer les informations utilisateur Git
$userEmail = "gerivonderbitsh+dev@gmail.com"
$userName = "Gribitch"

git config --global user.email $userEmail
git config --global user.name $userName

Write-Host "âœ… Informations utilisateur Git configurÃ©es" -ForegroundColor Green

# VÃ©rifier si le dÃ©pÃ´t Git est dÃ©jÃ  initialisÃ©
if (-not (Test-Path ".git")) {
    Write-Host "Initialisation du dÃ©pÃ´t Git local..." -ForegroundColor Yellow
    git init
    Write-Host "âœ… DÃ©pÃ´t Git local initialisÃ©" -ForegroundColor Green
} else {
    Write-Host "âœ… DÃ©pÃ´t Git local dÃ©jÃ  initialisÃ©" -ForegroundColor Green
}

# VÃ©rifier si .gitignore existe
if (-not (Test-Path ".gitignore")) {
    Write-Host "CrÃ©ation du fichier .gitignore..." -ForegroundColor Yellow
    $gitignoreContent = @"
# DÃ©pendances
node_modules/
.npm
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environnement
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Fichiers systÃ¨me
.DS_Store
Thumbs.db

# Fichiers de build
dist/
build/
*.tsbuildinfo

# Logs
logs/
*.log

# Fichiers temporaires
tmp/
temp/

# Fichiers de credentials sensibles
.n8n/credentials/
credentials/*.json

# Cache
.cache/
"@
    Set-Content -Path ".gitignore" -Value $gitignoreContent
    Write-Host "âœ… Fichier .gitignore crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "âœ… Fichier .gitignore existe dÃ©jÃ " -ForegroundColor Green
}

# VÃ©rifier si .gitattributes existe
if (-not (Test-Path ".gitattributes")) {
    Write-Host "CrÃ©ation du fichier .gitattributes..." -ForegroundColor Yellow
    $gitattributesContent = @"
# Auto detect text files and perform LF normalization
* text=auto

# Documents
*.md text diff=markdown
*.txt text
*.json text

# Scripts
*.js text
*.ps1 text
*.sh text eol=lf
*.cmd text eol=crlf
*.bat text eol=crlf

# Binaries
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.zip binary
*.7z binary
*.ttf binary
*.eot binary
*.woff binary
*.woff2 binary
"@
    Set-Content -Path ".gitattributes" -Value $gitattributesContent
    Write-Host "âœ… Fichier .gitattributes crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "âœ… Fichier .gitattributes existe dÃ©jÃ " -ForegroundColor Green
}

# Configurer GitHub comme remote
$repoName = "email-sender-1"
$repoOwner = "Gribitch"

$remoteUrl = "https://github.com/$repoOwner/$repoName.git"
$remoteExists = git remote -v | Select-String -Pattern "origin"

if (-not $remoteExists) {
    Write-Host "Ajout de GitHub comme remote..." -ForegroundColor Yellow
    git remote add origin $remoteUrl
    Write-Host "âœ… GitHub ajoutÃ© comme remote" -ForegroundColor Green
} else {
    Write-Host "Mise Ã  jour du remote GitHub..." -ForegroundColor Yellow
    git remote set-url origin $remoteUrl
    Write-Host "âœ… Remote GitHub mis Ã  jour" -ForegroundColor Green
}

# Instructions pour crÃ©er un dÃ©pÃ´t privÃ© sur GitHub
Write-Host "`nInstructions pour crÃ©er un dÃ©pÃ´t privÃ© sur GitHub :" -ForegroundColor Cyan
Write-Host "1. Connectez-vous Ã  votre compte GitHub (https://github.com/login)"
Write-Host "2. Cliquez sur le bouton '+' en haut Ã  droite et sÃ©lectionnez 'New repository'"
Write-Host "3. Entrez '$repoName' comme nom de dÃ©pÃ´t"
Write-Host "4. SÃ©lectionnez 'Private' pour rendre le dÃ©pÃ´t privÃ©"
Write-Host "5. Ne cochez PAS 'Initialize this repository with a README'"
Write-Host "6. Cliquez sur 'Create repository'"

Write-Host "`nUne fois le dÃ©pÃ´t crÃ©Ã©, exÃ©cutez les commandes suivantes pour pousser votre code :" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host "git commit -m 'Initial commit'"
Write-Host "git push -u origin master"

Write-Host "`n=== Configuration de Git et GitHub terminÃ©e ===" -ForegroundColor Cyan
