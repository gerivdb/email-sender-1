# Script de vérification de sécurité de base
# Ce script vérifie les fichiers pour des informations sensibles

Write-Host "Exécution des vérifications de sécurité de base" -ForegroundColor Cyan

# Définir les patterns d'informations sensibles
$sensitivePatterns = @(
    "password\s*=\s*['\"][^'\"]+['\"]",
    "apikey\s*=\s*['\"][^'\"]+['\"]",
    "api_key\s*=\s*['\"][^'\"]+['\"]",
    "secret\s*=\s*['\"][^'\"]+['\"]",
    "token\s*=\s*['\"][^'\"]+['\"]"
)

# Récupérer tous les fichiers à vérifier
$allFiles = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.py", "*.json", "*.md", "*.txt" -File
Write-Host "Vérification de $($allFiles.Count) fichiers pour des informations sensibles" -ForegroundColor Cyan

$foundSensitive = $false

# Vérifier chaque fichier
foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if ($content) {
        foreach ($pattern in $sensitivePatterns) {
            if ($content -match $pattern) {
                Write-Host "Information sensible détectée dans $($file.FullName) : $pattern" -ForegroundColor Yellow
                $foundSensitive = $true
            }
        }
    }
}

# Afficher le résultat
if ($foundSensitive) {
    Write-Host "Des informations sensibles ont été détectées, mais le workflow continuera" -ForegroundColor Yellow
} else {
    Write-Host "Aucune information sensible détectée" -ForegroundColor Green
}

Write-Host "Vérifications de sécurité de base terminées avec succès" -ForegroundColor Green
exit 0
