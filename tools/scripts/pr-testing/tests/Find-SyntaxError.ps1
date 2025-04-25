# Script pour trouver les erreurs de syntaxe dans un fichier PowerShell

param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

# Vérifier que le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Fichier non trouvé: $FilePath"
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $FilePath -Raw

# Diviser le contenu en lignes
$lines = $content -split "`n"

# Analyser chaque ligne
for ($i = 0; $i -lt $lines.Count; $i++) {
    $lineNumber = $i + 1
    $line = $lines[$i]
    
    # Ignorer les lignes vides ou les commentaires
    if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith("#")) {
        continue
    }
    
    # Essayer de parser la ligne
    try {
        [System.Management.Automation.PSParser]::Tokenize($line, [ref]$null) | Out-Null
    } catch {
        Write-Host "Erreur de syntaxe à la ligne $lineNumber : $line" -ForegroundColor Red
        Write-Host "Message d'erreur : $_" -ForegroundColor Yellow
    }
}

Write-Host "Analyse terminée." -ForegroundColor Green
