# Script pour tester les endpoints fonctionnels de l'API n8n avec des exemples concrets

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT
$outputFile = "docs/api/N8N_API_EXAMPLES.md"

# Creation du repertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Parent $outputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Repertoire cree: $outputDir" -ForegroundColor Green
}

# Preparation des en-tetes pour les requetes API
$headers = @{
    "X-N8N-API-KEY" = $apiToken
}

# Creation de l'en-tete du fichier de documentation
$documentation = @"
# Exemples d'utilisation de l'API n8n (Version locale)

Ce document contient des exemples concrets d'utilisation des endpoints fonctionnels de l'API n8n sur votre instance locale.

URL de base: $n8nUrl

## Table des matieres

- [Workflows](#workflows)
- [Executions](#executions)
- [Tags](#tags)
- [Utilisateurs](#utilisateurs)

## Endpoints fonctionnels

Voici les endpoints qui fonctionnent sur votre instance n8n:

1. GET /api/v1/workflows - Liste tous les workflows
2. GET /api/v1/executions - Liste toutes les executions
3. GET /api/v1/tags - Liste tous les tags
4. POST /api/v1/tags - Cree un nouveau tag
5. GET /api/v1/users - Liste tous les utilisateurs

"@

# Test 1: Liste des workflows
Write-Host "Test 1: Liste des workflows..." -NoNewline
try {
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    
    $documentation += @"

## Workflows

### Liste des workflows

#### Requete

```powershell
Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
```

#### Reponse

```json
{
  "data": [
"@
    
    # Ajouter les 3 premiers workflows (ou moins s'il y en a moins)
    $workflowCount = [Math]::Min($response.data.Count, 3)
    for ($i = 0; $i -lt $workflowCount; $i++) {
        $workflow = $response.data[$i]
        $workflowJson = $workflow | ConvertTo-Json -Depth 1
        $documentation += "    $workflowJson"
        if ($i -lt $workflowCount - 1) {
            $documentation += ","
        }
        $documentation += "`n"
    }
    
    if ($response.data.Count -gt 3) {
        $documentation += "    // ... plus d'elements ..."
    }
    
    $documentation += @"
  ],
  "nextCursor": null
}
```

#### Proprietes importantes

- `data` - Tableau contenant les workflows
  - `id` - Identifiant unique du workflow
  - `name` - Nom du workflow
  - `active` - Indique si le workflow est actif
  - `createdAt` - Date de creation du workflow
  - `updatedAt` - Date de derniere mise a jour du workflow

#### Exemple d'utilisation

```powershell
# Recuperer tous les workflows
`$workflows = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers `$headers

# Afficher les noms des workflows
`$workflows.data | ForEach-Object { Write-Host `$_.name }

# Recuperer les IDs des workflows actifs
`$activeWorkflowIds = `$workflows.data | Where-Object { `$_.active -eq `$true } | Select-Object -ExpandProperty id
```

"@
    
    Write-Host " Succes!" -ForegroundColor Green
}
catch {
    Write-Host " Echec: $($_.Exception.Message)" -ForegroundColor Red
    $documentation += @"

## Workflows

### Liste des workflows

Cet endpoint a echoue lors du test. Erreur: $($_.Exception.Message)

"@
}

# Test 2: Liste des executions
Write-Host "Test 2: Liste des executions..." -NoNewline
try {
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/executions" -Method Get -Headers $headers
    
    $documentation += @"

## Executions

### Liste des executions

#### Requete

```powershell
Invoke-RestMethod -Uri "$n8nUrl/api/v1/executions" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
```

#### Reponse

```json
"@
    
    $executionsJson = $response | ConvertTo-Json -Depth 2
    $documentation += "$executionsJson"
    
    $documentation += @"
```

#### Proprietes importantes

- `data` - Tableau contenant les executions
  - `id` - Identifiant unique de l'execution
  - `finished` - Indique si l'execution est terminee
  - `status` - Statut de l'execution (success, error, etc.)
  - `startedAt` - Date de debut de l'execution
  - `stoppedAt` - Date de fin de l'execution
  - `workflowId` - ID du workflow execute

#### Exemple d'utilisation

```powershell
# Recuperer toutes les executions
`$executions = Invoke-RestMethod -Uri "$n8nUrl/api/v1/executions" -Method Get -Headers `$headers

# Afficher les executions recentes
`$executions.data | Sort-Object startedAt -Descending | Select-Object -First 5 | Format-Table id, workflowId, status

# Recuperer les executions en erreur
`$failedExecutions = `$executions.data | Where-Object { `$_.status -eq "error" }
```

"@
    
    Write-Host " Succes!" -ForegroundColor Green
}
catch {
    Write-Host " Echec: $($_.Exception.Message)" -ForegroundColor Red
    $documentation += @"

## Executions

### Liste des executions

Cet endpoint a echoue lors du test. Erreur: $($_.Exception.Message)

"@
}

# Test 3: Liste des tags
Write-Host "Test 3: Liste des tags..." -NoNewline
try {
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/tags" -Method Get -Headers $headers
    
    $documentation += @"

## Tags

### Liste des tags

#### Requete

```powershell
Invoke-RestMethod -Uri "$n8nUrl/api/v1/tags" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
```

#### Reponse

```json
"@
    
    $tagsJson = $response | ConvertTo-Json -Depth 2
    $documentation += "$tagsJson"
    
    $documentation += @"
```

#### Proprietes importantes

- `data` - Tableau contenant les tags
  - `id` - Identifiant unique du tag
  - `name` - Nom du tag
  - `createdAt` - Date de creation du tag
  - `updatedAt` - Date de derniere mise a jour du tag

#### Exemple d'utilisation

```powershell
# Recuperer tous les tags
`$tags = Invoke-RestMethod -Uri "$n8nUrl/api/v1/tags" -Method Get -Headers `$headers

# Afficher les noms des tags
`$tags.data | ForEach-Object { Write-Host `$_.name }

# Recuperer les IDs des tags
`$tagIds = `$tags.data | Select-Object -ExpandProperty id
```

"@
    
    Write-Host " Succes!" -ForegroundColor Green
}
catch {
    Write-Host " Echec: $($_.Exception.Message)" -ForegroundColor Red
    $documentation += @"

## Tags

### Liste des tags

Cet endpoint a echoue lors du test. Erreur: $($_.Exception.Message)

"@
}

# Test 4: Creation d'un tag
Write-Host "Test 4: Creation d'un tag..." -NoNewline
try {
    $tagName = "Test Tag " + (Get-Date -Format "yyyyMMddHHmmss")
    $body = @{
        name = $tagName
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/tags" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    
    $documentation += @"

### Creation d'un tag

#### Requete

```powershell
`$body = @{
    name = "Mon Tag"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$n8nUrl/api/v1/tags" -Method Post -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" } -Body `$body -ContentType "application/json"
```

#### Reponse

```json
"@
    
    $tagJson = $response | ConvertTo-Json -Depth 2
    $documentation += "$tagJson"
    
    $documentation += @"
```

#### Proprietes importantes

- `id` - Identifiant unique du tag cree
- `name` - Nom du tag
- `createdAt` - Date de creation du tag
- `updatedAt` - Date de derniere mise a jour du tag

#### Exemple d'utilisation

```powershell
# Creer un nouveau tag
`$body = @{
    name = "Nouveau Tag"
} | ConvertTo-Json

`$newTag = Invoke-RestMethod -Uri "$n8nUrl/api/v1/tags" -Method Post -Headers `$headers -Body `$body -ContentType "application/json"

# Afficher l'ID du tag cree
Write-Host "Tag cree avec l'ID: `$(`$newTag.id)"
```

"@
    
    Write-Host " Succes!" -ForegroundColor Green
}
catch {
    Write-Host " Echec: $($_.Exception.Message)" -ForegroundColor Red
    $documentation += @"

### Creation d'un tag

Cet endpoint a echoue lors du test. Erreur: $($_.Exception.Message)

"@
}

# Test 5: Liste des utilisateurs
Write-Host "Test 5: Liste des utilisateurs..." -NoNewline
try {
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/users" -Method Get -Headers $headers
    
    $documentation += @"

## Utilisateurs

### Liste des utilisateurs

#### Requete

```powershell
Invoke-RestMethod -Uri "$n8nUrl/api/v1/users" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
```

#### Reponse

```json
"@
    
    $usersJson = $response | ConvertTo-Json -Depth 2
    $documentation += "$usersJson"
    
    $documentation += @"
```

#### Proprietes importantes

- `data` - Tableau contenant les utilisateurs
  - `id` - Identifiant unique de l'utilisateur
  - `email` - Adresse email de l'utilisateur
  - `firstName` - Prenom de l'utilisateur
  - `lastName` - Nom de l'utilisateur
  - `isOwner` - Indique si l'utilisateur est proprietaire
  - `isPending` - Indique si l'utilisateur est en attente d'activation

#### Exemple d'utilisation

```powershell
# Recuperer tous les utilisateurs
`$users = Invoke-RestMethod -Uri "$n8nUrl/api/v1/users" -Method Get -Headers `$headers

# Afficher les emails des utilisateurs
`$users.data | ForEach-Object { Write-Host `$_.email }

# Recuperer les IDs des utilisateurs actifs (non en attente)
`$activeUserIds = `$users.data | Where-Object { `$_.isPending -eq `$false } | Select-Object -ExpandProperty id
```

"@
    
    Write-Host " Succes!" -ForegroundColor Green
}
catch {
    Write-Host " Echec: $($_.Exception.Message)" -ForegroundColor Red
    $documentation += @"

## Utilisateurs

### Liste des utilisateurs

Cet endpoint a echoue lors du test. Erreur: $($_.Exception.Message)

"@
}

# Ajout de la conclusion
$documentation += @"

## Conclusion

Cette documentation a ete generee automatiquement en testant les endpoints fonctionnels de l'API n8n sur votre instance locale.

### Remarques importantes

- Les exemples fournis utilisent PowerShell, mais vous pouvez adapter ces requetes a d'autres langages de programmation.
- Remplacez toujours "votre-jeton-api" par votre jeton d'API n8n reel.
- Les reponses peuvent varier en fonction de votre configuration n8n et des donnees presentes dans votre instance.
- Cette documentation a ete generee le $(Get-Date -Format "dd/MM/yyyy HH:mm:ss").
- Version de n8n testee: Verifiez votre version dans l'interface utilisateur de n8n.

### Ressources additionnelles

- [Documentation officielle de n8n](https://docs.n8n.io/)
- [Documentation de l'API n8n](http://localhost:5678/api/v1/docs/)
"@

# Ecriture de la documentation dans le fichier de sortie
$documentation | Out-File -FilePath $outputFile -Encoding utf8
Write-Host "`nDocumentation des exemples generee: $outputFile" -ForegroundColor Green
