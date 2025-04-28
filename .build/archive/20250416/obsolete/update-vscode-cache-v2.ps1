# Script pour mettre a jour les chemins dans le fichier mtime-cache.json de VS Code
# Ce script remplace les anciens chemins par les nouveaux chemins dans le fichier de cache VS Code

Write-Host "=== Mise a jour des chemins dans le fichier mtime-cache.json de VS Code ===" -ForegroundColor Cyan

# Chemin du fichier mtime-cache.json
$mtimeCachePath = "c:\Users\user\AppData\Roaming\Code\User\workspaceStorage\ea77b552dca9e4ba40f313708c3f5bed\Augment.vscode-augment\deee7de52a4bd9428252590c8216ae2c701e3fb3c590a6f2fedc6c8278ac38d2\mtime-cache.json"

# Ancien chemin (avec et sans espaces)
$oldPathVariants = @(
    # Variante avec espaces et underscores
    "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1",
    "D:/DO/WEB/N8N_development/testing/tests/scripts_ json_a_ tester/EMAIL_SENDER_1",
    "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1",
    
    # Variante sans espaces
    "D:\\DO\\WEB\\N8N_tests\\scripts_json_a_tester\\EMAIL_SENDER_1",
    "D:/DO/WEB/N8N_development/testing/tests/scripts_json_a_tester/EMAIL_SENDER_1",
    "D:\DO\WEB\N8N_tests\scripts_json_a_tester\EMAIL_SENDER_1",
    
    # Variante avec espaces et accents
    "D:\\DO\\WEB\\N8N tests\\scripts json a tester\\EMAIL SENDER 1",
    "D:/DO/WEB/N8N development/testing/tests/scripts json a tester/EMAIL SENDER 1",
    "D:\DO\WEB\N8N tests\scripts json a tester\EMAIL SENDER 1"
)

# Nouveau chemin
$newPath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"

# Verifier si le fichier existe
if (-not (Test-Path $mtimeCachePath)) {
    Write-Host "Le fichier mtime-cache.json n'existe pas a l'emplacement specifie." -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier
try {
    $content = Get-Content -Path $mtimeCachePath -Raw -ErrorAction Stop
    Write-Host "Fichier mtime-cache.json lu avec succes." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la lecture du fichier mtime-cache.json : $_" -ForegroundColor Red
    exit 1
}

# Creer une copie de sauvegarde du fichier
$backupPath = "$mtimeCachePath.backup"
try {
    Copy-Item -Path $mtimeCachePath -Destination $backupPath -Force -ErrorAction Stop
    Write-Host "Copie de sauvegarde creee : $backupPath" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la creation de la copie de sauvegarde : $_" -ForegroundColor Red
    exit 1
}

# Remplacer les anciens chemins par le nouveau chemin
$modified = $false
foreach ($variant in $oldPathVariants) {
    # Echapper les caracteres speciaux pour la regex
    $escapedVariant = [regex]::Escape($variant)
    if ($content -match $escapedVariant) {
        $content = $content -replace $escapedVariant, $newPath
        $modified = $true
    }
}

# Enregistrer le fichier modifie
if ($modified) {
    try {
        Set-Content -Path $mtimeCachePath -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
        Write-Host "Fichier mtime-cache.json mis a jour avec succes." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'enregistrement du fichier mtime-cache.json : $_" -ForegroundColor Red
        Write-Host "Restauration de la copie de sauvegarde..." -ForegroundColor Yellow
        Copy-Item -Path $backupPath -Destination $mtimeCachePath -Force
        exit 1
    }
}
else {
    Write-Host "Aucune modification necessaire dans le fichier mtime-cache.json." -ForegroundColor Blue
}

Write-Host "`n=== Termine ===" -ForegroundColor Cyan
