# Script pour configurer Git et GitHub pour le projet Email Sender 1

Write-Host "=== Configuration de Git et GitHub ===" -ForegroundColor Cyan

# Vérifier si Git est installé
$gitVersion = git --version 2>$null
if (-not $gitVersion) {
    Write-Host "❌ Git n'est pas installé ou n'est pas accessible" -ForegroundColor Red
    Write-Host "Veuillez installer Git depuis https://git-scm.com/downloads"
    exit 1
}

Write-Host "✅ Git version $gitVersion détecté" -ForegroundColor Green

# Configurer les informations utilisateur Git
$userEmail = "gerivonderbitsh+dev@gmail.com"
$userName = "Gribitch"

git config --global user.email $userEmail
git config --global user.name $userName

Write-Host "✅ Informations utilisateur Git configurées" -ForegroundColor Green

# Vérifier si le dépôt Git est déjà initialisé
if (-not (Test-Path ".git")) {
    Write-Host "Initialisation du dépôt Git local..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Dépôt Git local initialisé" -ForegroundColor Green
} else {
    Write-Host "✅ Dépôt Git local déjà initialisé" -ForegroundColor Green
}

# Vérifier si .gitignore existe
if (-not (Test-Path ".gitignore")) {
    Write-Host "Création du fichier .gitignore..." -ForegroundColor Yellow
    $gitignoreContent = @"
# Dépendances
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

# Fichiers système
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
    Write-Host "✅ Fichier .gitignore créé" -ForegroundColor Green
} else {
    Write-Host "✅ Fichier .gitignore existe déjà" -ForegroundColor Green
}

# Vérifier si .gitattributes existe
if (-not (Test-Path ".gitattributes")) {
    Write-Host "Création du fichier .gitattributes..." -ForegroundColor Yellow
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
    Write-Host "✅ Fichier .gitattributes créé" -ForegroundColor Green
} else {
    Write-Host "✅ Fichier .gitattributes existe déjà" -ForegroundColor Green
}

# Configurer GitHub comme remote
$repoName = "email-sender-1"
$repoOwner = "Gribitch"

$remoteUrl = "https://github.com/$repoOwner/$repoName.git"
$remoteExists = git remote -v | Select-String -Pattern "origin"

if (-not $remoteExists) {
    Write-Host "Ajout de GitHub comme remote..." -ForegroundColor Yellow
    git remote add origin $remoteUrl
    Write-Host "✅ GitHub ajouté comme remote" -ForegroundColor Green
} else {
    Write-Host "Mise à jour du remote GitHub..." -ForegroundColor Yellow
    git remote set-url origin $remoteUrl
    Write-Host "✅ Remote GitHub mis à jour" -ForegroundColor Green
}

# Instructions pour créer un dépôt privé sur GitHub
Write-Host "`nInstructions pour créer un dépôt privé sur GitHub :" -ForegroundColor Cyan
Write-Host "1. Connectez-vous à votre compte GitHub (https://github.com/login)"
Write-Host "2. Cliquez sur le bouton '+' en haut à droite et sélectionnez 'New repository'"
Write-Host "3. Entrez '$repoName' comme nom de dépôt"
Write-Host "4. Sélectionnez 'Private' pour rendre le dépôt privé"
Write-Host "5. Ne cochez PAS 'Initialize this repository with a README'"
Write-Host "6. Cliquez sur 'Create repository'"

Write-Host "`nUne fois le dépôt créé, exécutez les commandes suivantes pour pousser votre code :" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host "git commit -m 'Initial commit'"
Write-Host "git push -u origin master"

Write-Host "`n=== Configuration de Git et GitHub terminée ===" -ForegroundColor Cyan
