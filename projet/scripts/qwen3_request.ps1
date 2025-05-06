$env:OPENROUTER_API_KEY = (Get-Content 'projet\config\credentials.json' | ConvertFrom-Json).openrouter_api_key

$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = "Bearer $env:OPENROUTER_API_KEY"
}

$systemPrompt = "Tu es un expert en développement Python et en statistiques. Tu dois développer des formules de métriques pondérées pour chaque moment statistique (moyenne, variance, asymétrie, aplatissement) dans le cadre d'un système d'évaluation de la qualité des histogrammes. Fournis un document technique détaillé et le code Python correspondant."

$userPrompt = "Développe des formules de métriques pondérées pour chaque moment statistique (moyenne, variance, asymétrie, aplatissement) dans le cadre de notre système d'évaluation de la qualité des histogrammes. Inclus les formules mathématiques et le code Python correspondant."

$body = @{
    model = 'qwen/qwen3-235b-a22b'
    messages = @(
        @{
            role = 'system'
            content = $systemPrompt
        },
        @{
            role = 'user'
            content = $userPrompt
        }
    )
    max_tokens = 4000
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/chat/completions' -Method Post -Headers $headers -Body $body
$response.choices[0].message.content | Out-File -FilePath "projet/temp/qwen3_response.md" -Encoding utf8
Write-Output "Réponse enregistrée dans projet/temp/qwen3_response.md"
