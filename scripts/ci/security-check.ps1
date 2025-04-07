# Script de vÃ©rification de sÃ©curitÃ© de base
# Ce script vÃ©rifie les fichiers pour des informations sensibles

Write-Host "ExÃ©cution des vÃ©rifications de sÃ©curitÃ© de base" -ForegroundColor Cyan

# DÃ©finir les patterns d'informations sensibles
$sensitivePatterns = @(
    "password\s*=\s*['\"][^'\"]+['\"]",
    "apikey\s*=\s*['\"][^'\"]+['\"]",
    "api_key\s*=\s*['\"][^'\"]+['\"]",
    "secret\s*=\s*['\"][^'\"]+['\"]",
    "token\s*=\s*['\"][^'\"]+['\"]"
)

# RÃ©cupÃ©rer tous les fichiers Ã  vÃ©rifier
$allFiles = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.py", "*.json", "*.md", "*.txt" -File
Write-Host "VÃ©rification de $($allFiles.Count) fichiers pour des informations sensibles" -ForegroundColor Cyan

$foundSensitive = $false

# VÃ©rifier chaque fichier
foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if ($content) {
        foreach ($pattern in $sensitivePatterns) {
            if ($content -match $pattern) {
                Write-Host "Information sensible dÃ©tectÃ©e dans $($file.FullName) : $pattern" -ForegroundColor Yellow
                $foundSensitive = $true
            }
        }
    }
}

# Afficher le rÃ©sultat
if ($foundSensitive) {
    Write-Host "Des informations sensibles ont Ã©tÃ© dÃ©tectÃ©es, mais le workflow continuera" -ForegroundColor Yellow
} else {
    Write-Host "Aucune information sensible dÃ©tectÃ©e" -ForegroundColor Green
}

Write-Host "VÃ©rifications de sÃ©curitÃ© de base terminÃ©es avec succÃ¨s" -ForegroundColor Green
exit 0
