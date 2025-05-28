param(
    [string]$SourceFile = ".github/docs/guides/go/Algorithmes-go.md",
    [string]$TargetDir = ".github/docs/algorithms",
    [switch]$DryRun = $false
)

Write-Host "EXTRACTION MODULAIRE EMAIL_SENDER_1" -ForegroundColor Cyan
Write-Host "Source: $SourceFile" -ForegroundColor Yellow
Write-Host "Target: $TargetDir" -ForegroundColor Yellow

if (-not (Test-Path $SourceFile)) {
    Write-Error "Fichier source non trouve: $SourceFile"
    exit 1
}

if (-not (Test-Path $TargetDir)) {
    Write-Error "Dossier cible non trouve: $TargetDir"
    exit 1
}

$sourceContent = Get-Content $SourceFile -Raw

# Test d'extraction simple
$modules = @(
    "error-triage",
    "binary-search", 
    "dependency-analysis",
    "progressive-build",
    "auto-fix",
    "analysis-pipeline",
    "config-validator",
    "dependency-resolution"
)

foreach ($module in $modules) {
    $modulePath = Join-Path $TargetDir $module
    $readmePath = Join-Path $modulePath "README.md"
    
    Write-Host "Traitement: $module" -ForegroundColor Blue
      # Recherche du contenu de l'algorithme dans le fichier source
    $algorithmNumber = switch ($module) {
        "error-triage" { "1" }
        "binary-search" { "2" }
        "dependency-analysis" { "3" }
        "progressive-build" { "4" }
        "auto-fix" { "5" }
        "analysis-pipeline" { "6" }
        "config-validator" { "7" }
        "dependency-resolution" { "8" }
    }
    
    # Pattern pour extraire le contenu complet de l'algorithme
    $pattern = "(?s)## .*Algorithme $algorithmNumber.*?(?=## .*Algorithme [1-8]|## .*Plan d'action|$)"
    
    if ($sourceContent -match $pattern) {
        $extractedContent = $matches[0]
        Write-Host "  Trouve contenu pour: $module ($($extractedContent.Length) chars)" -ForegroundColor Green
        
        if (-not $DryRun) {
            # Mise a jour du README avec le contenu extrait
            $currentReadme = Get-Content $readmePath -Raw
            $updatedReadme = $currentReadme -replace "## Contenu detaille.*", "## Contenu detaille`n`n$extractedContent`n"
            $updatedReadme | Out-File -FilePath $readmePath -Encoding UTF8
            Write-Host "  Mis a jour: $readmePath" -ForegroundColor Green
        }
    } else {
        Write-Host "  Contenu non trouve pour: $module" -ForegroundColor Yellow
    }
}

Write-Host "EXTRACTION TERMINEE!" -ForegroundColor Cyan
