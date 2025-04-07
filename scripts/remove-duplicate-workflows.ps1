# Script pour supprimer les workflows dupliquÃ©s dans n8n
# Ce script identifie et supprime les workflows dupliquÃ©s en se basant sur leur nom

# Configuration
$n8nUrl = "http://localhost:5678"
$apiEndpoint = "$n8nUrl/api/v1/workflows"
$authToken = $null

# Demander le token d'authentification si nÃ©cessaire
if (-not $authToken) {
    $authToken = Read-Host "Entrez votre token d'authentification n8n"
    if ([string]::IsNullOrEmpty($authToken)) {
        Write-Host "Token d'authentification requis pour continuer." -ForegroundColor Red
        exit
    }
}

# Headers pour les requÃªtes API
$headers = @{
    "X-N8N-API-KEY" = $authToken
    "Content-Type" = "application/json"
}

# RÃ©cupÃ©rer tous les workflows
try {
    Write-Host "RÃ©cupÃ©ration des workflows depuis n8n..." -NoNewline
    $workflows = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Get
    Write-Host " OK!" -ForegroundColor Green
    Write-Host "Nombre de workflows trouvÃ©s: $($workflows.Count)"
}
catch {
    Write-Host " Ã‰chec!" -ForegroundColor Red
    Write-Host "Erreur lors de la rÃ©cupÃ©ration des workflows: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Identifier les workflows dupliquÃ©s
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

        Write-Host "Doublon trouvÃ©: '$name' (ID: $($workflow.id))" -ForegroundColor Yellow
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

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ©:"
Write-Host "Total des workflows: $($workflows.Count)"
Write-Host "Workflows uniques: $($workflowNames.Count)"
Write-Host "Doublons identifiÃ©s: $($duplicates.Count)"

# Demander confirmation pour supprimer les doublons
if ($duplicates.Count -gt 0) {
    $confirmation = Read-Host "`nVoulez-vous supprimer les $($duplicates.Count) workflows dupliquÃ©s? (O/N)"

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
                Write-Host " Ã‰chec!" -ForegroundColor Red
                Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        Write-Host "`nSuppression terminÃ©e: $successCount/$($duplicates.Count) workflows supprimÃ©s."
    }
    else {
        Write-Host "OpÃ©ration annulÃ©e. Aucun workflow n'a Ã©tÃ© supprimÃ©."
    }
}
else {
    Write-Host "`nAucun workflow dupliquÃ© trouvÃ©. Rien Ã  supprimer."
}
