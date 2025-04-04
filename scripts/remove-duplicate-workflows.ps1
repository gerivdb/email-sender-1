# Script pour supprimer les workflows dupliqués dans n8n
# Ce script identifie et supprime les workflows dupliqués en se basant sur leur nom

# Configuration
$n8nUrl = "http://localhost:5678"
$apiEndpoint = "$n8nUrl/api/v1/workflows"
$authToken = $null

# Demander le token d'authentification si nécessaire
if (-not $authToken) {
    $authToken = Read-Host "Entrez votre token d'authentification n8n"
    if ([string]::IsNullOrEmpty($authToken)) {
        Write-Host "Token d'authentification requis pour continuer." -ForegroundColor Red
        exit
    }
}

# Headers pour les requêtes API
$headers = @{
    "X-N8N-API-KEY" = $authToken
    "Content-Type" = "application/json"
}

# Récupérer tous les workflows
try {
    Write-Host "Récupération des workflows depuis n8n..." -NoNewline
    $workflows = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Get
    Write-Host " OK!" -ForegroundColor Green
    Write-Host "Nombre de workflows trouvés: $($workflows.Count)"
}
catch {
    Write-Host " Échec!" -ForegroundColor Red
    Write-Host "Erreur lors de la récupération des workflows: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Identifier les workflows dupliqués
$workflowNames = @{}
$duplicates = @()

foreach ($workflow in $workflows) {
    $name = $workflow.name

    if ($workflowNames.ContainsKey($name)) {
        # C'est un doublon
        $duplicates += @{
            Id = $workflow.id
            Name = $name
            CreatedAt = $workflow.createdAt
            UpdatedAt = $workflow.updatedAt
        }

        Write-Host "Doublon trouvé: '$name' (ID: $($workflow.id))" -ForegroundColor Yellow
    }
    else {
        # Premier workflow avec ce nom
        $workflowNames[$name] = @{
            Id = $workflow.id
            CreatedAt = $workflow.createdAt
            UpdatedAt = $workflow.updatedAt
        }
    }
}

# Afficher un résumé
Write-Host "`nRésumé:"
Write-Host "Total des workflows: $($workflows.Count)"
Write-Host "Workflows uniques: $($workflowNames.Count)"
Write-Host "Doublons identifiés: $($duplicates.Count)"

# Demander confirmation pour supprimer les doublons
if ($duplicates.Count -gt 0) {
    $confirmation = Read-Host "`nVoulez-vous supprimer les $($duplicates.Count) workflows dupliqués? (O/N)"

    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        $successCount = 0

        foreach ($duplicate in $duplicates) {
            $deleteUrl = "$apiEndpoint/$($duplicate.Id)"

            try {
                Write-Host "Suppression du workflow '$($duplicate.Name)' (ID: $($duplicate.Id))..." -NoNewline
                Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete | Out-Null
                Write-Host " OK!" -ForegroundColor Green
                $successCount++
            }
            catch {
                Write-Host " Échec!" -ForegroundColor Red
                Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        Write-Host "`nSuppression terminée: $successCount/$($duplicates.Count) workflows supprimés."
    }
    else {
        Write-Host "Opération annulée. Aucun workflow n'a été supprimé."
    }
}
else {
    Write-Host "`nAucun workflow dupliqué trouvé. Rien à supprimer."
}
