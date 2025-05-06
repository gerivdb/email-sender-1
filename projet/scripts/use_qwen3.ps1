# Script pour utiliser Qwen3 via OpenRouter

# Demander la clé API à l'utilisateur
$apiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter"

# Définir la variable d'environnement
[Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $apiKey, "Process")

# Préparer les en-têtes de la requête
$headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer $apiKey"
    "HTTP-Referer"  = "https://github.com/augmentcode-ai"
    "X-Title"       = "Weighted Metrics Development"
}

# Préparer le corps de la requête
$body = @{
    model       = "qwen/qwen3-235b-a22b"
    messages    = @(
        @{
            role    = "system"
            content = "Tu es un expert en développement Python et en statistiques. Tu dois développer des formules de métriques pondérées pour chaque moment statistique (moyenne, variance, asymétrie, aplatissement) dans le cadre d'un système d'évaluation de la qualité des histogrammes. Fournis un document technique détaillé et le code Python correspondant."
        },
        @{
            role    = "user"
            content = "Développe des formules de métriques pondérées pour chaque moment statistique (moyenne, variance, asymétrie, aplatissement) dans le cadre de notre système d'évaluation de la qualité des histogrammes. Inclus les formules mathématiques et le code Python correspondant."
        }
    )
    temperature = 0.7
    max_tokens  = 4000
} | ConvertTo-Json -Depth 10

# Appeler l'API
try {
    Write-Host "Appel de l'API Qwen3 via OpenRouter..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body
    
    # Traiter la réponse
    $generatedContent = $response.choices[0].message.content
    
    # Enregistrer le contenu généré dans un fichier
    $outputPath = "projet/documentation/technical/TestFrameworkStructures/MemoryMetrics/FileSystemCache/BinningStrategies/WeightedMetricsFormulas.md"
    
    # Créer le dossier parent s'il n'existe pas
    $outputDir = Split-Path -Path $outputPath -Parent
    if (-not (Test-Path -Path $outputDir -PathType Container)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Enregistrer le contenu
    $generatedContent | Out-File -FilePath $outputPath -Encoding utf8
    
    Write-Host "Contenu généré enregistré dans : $outputPath" -ForegroundColor Green
    
    # Afficher un aperçu du contenu
    Write-Host "Aperçu du contenu généré :" -ForegroundColor Cyan
    Write-Host "--------------------"
    Write-Host ($generatedContent.Substring(0, [Math]::Min(500, $generatedContent.Length)))
    Write-Host "..."
    Write-Host "--------------------"
    
} catch {
    Write-Warning "Erreur lors de l'appel à l'API : $_"
}
