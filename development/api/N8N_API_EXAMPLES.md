# Exemples d'utilisation de l'API n8n (Version locale)

Ce document contient des exemples concrets d'utilisation des endpoints fonctionnels de l'API n8n sur votre instance locale.

URL de base: http://localhost:5678

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

## Workflows

### Liste des workflows

#### Requete

`powershell
Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
`

#### Reponse

`json
{
  "data": [    {
    "createdAt":  "2025-04-04T19:50:26.249Z",
    "updatedAt":  "2025-04-04T19:50:26.249Z",
    "id":  "20SfVS1GVrswV6Zu",
    "name":  "Email Sender - Phase 2 (G�n�ration \u0026 Envoi des Emails)",
    "active":  false,
    "nodes":  [
                  "@{parameters=; id=a0143ff5-d39f-446c-b1f9-dd148ae80ce1; name=Trigger Phase 2; type=n8n-nodes-base.executeWorkflow; typeVersion=1; position=System.Object[]}",
                  "@{parameters=; id=b0143ff5-d39f-446c-b1f9-dd148ae80ce2; name=Superviseur IA (DeepSeek v3); type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=c0143ff5-d39f-446c-b1f9-dd148ae80ce3; name=Prep DeepSeek Cal; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=3faccf85-c7bd-4d20-8ce0-abf8ebedb14c; name=Appel API; type=n8n-nodes-base.httpRequest; typeVersion=4.1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=8c5bdd98-92f0-4b2c-9d8c-d9b9dc76752b; name=Set Message G�n�r� IA; type=n8n-nodes-base.set; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=84ff84d6-4b23-4169-aae4-2dfd77d22cc8; name=Fusion LOT1 + Lieux; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=94ff84d6-4b23-4169-aae4-2dfd77d22cc9; name=Fusion IA + Contacts; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=f8aa20be-3218-4144-9b82-23592378def7; name=Personnalisation Message; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=fb17c164-0d0a-42a6-8373-f2402238ae6f; name=Get Gmail Template; type=n8n-nodes-base.gmail; typeVersion=2.1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=3f5b2bd1-4485-4c55-8e51-339033be453b; name=Inject Message into HTML; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=f0ef9b9c-0eba-4238-b366-3d28a84429d0; name=Create Final Gmail Draft; type=n8n-nodes-base.gmail; typeVersion=2.1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=2649c986-4f25-4ae5-baef-dbed32b8cc7e; name=Set Delay Config; type=n8n-nodes-base.set; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=df75c3b2-ad3a-477e-9480-c253ec4a0858; name=Calc Random Delay; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=80570037-507c-4767-a947-c009e69a5e8b; name=Wait Anti-Spam; type=n8n-nodes-base.wait; typeVersion=1; position=System.Object[]; webhookId=1a2b3c4d-5e6f-7g8h-9i0j-1k2l3m4n5o6p}",
                  "@{parameters=; id=671105b1-2405-4f83-8f16-3c4ad34a22a6; name=Update Notion Status; type=n8n-nodes-base.notion; typeVersion=1; position=System.Object[]; credentials=}",
                  "@{parameters=; type=n8n-nodes-base.stickyNote; typeVersion=1; position=System.Object[]; id=b59a6337-cc99-4396-940b-3f17a585b003; name=Sticky Note Phase 2}"
              ],
    "connections":  {
                        "a0143ff5-d39f-446c-b1f9-dd148ae80ce1":  "@{main=System.Object[]}",
                        "b0143ff5-d39f-446c-b1f9-dd148ae80ce2":  "@{main=System.Object[]}",
                        "c0143ff5-d39f-446c-b1f9-dd148ae80ce3":  "@{main=System.Object[]}",
                        "3faccf85-c7bd-4d20-8ce0-abf8ebedb14c":  "@{main=System.Object[]}",
                        "8c5bdd98-92f0-4b2c-9d8c-d9b9dc76752b":  "@{main=System.Object[]}",
                        "84ff84d6-4b23-4169-aae4-2dfd77d22cc8":  "@{main=System.Object[]}",
                        "94ff84d6-4b23-4169-aae4-2dfd77d22cc9":  "@{main=System.Object[]}",
                        "f8aa20be-3218-4144-9b82-23592378def7":  "@{main=System.Object[]}",
                        "fb17c164-0d0a-42a6-8373-f2402238ae6f":  "@{main=System.Object[]}",
                        "3f5b2bd1-4485-4c55-8e51-339033be453b":  "@{main=System.Object[]}",
                        "f0ef9b9c-0eba-4238-b366-3d28a84429d0":  "@{main=System.Object[]}",
                        "2649c986-4f25-4ae5-baef-dbed32b8cc7e":  "@{main=System.Object[]}",
                        "df75c3b2-ad3a-477e-9480-c253ec4a0858":  "@{main=System.Object[]}",
                        "80570037-507c-4767-a947-c009e69a5e8b":  "@{main=System.Object[]}"
                    },
    "settings":  {
                     "executionOrder":  "v1"
                 },
    "staticData":  null,
    "meta":  null,
    "pinData":  null,
    "versionId":  "44405881-cb57-4f2f-a790-0a6b76386622",
    "triggerCount":  0,
    "tags":  [

             ]
},
    {
    "createdAt":  "2025-04-04T19:50:26.415Z",
    "updatedAt":  "2025-04-04T19:50:26.415Z",
    "id":  "8lFgC7hFqQWoDFdJ",
    "name":  "Email Sender - Phase 3 (Traitement des R�ponses)",
    "active":  false,
    "nodes":  [
                  "@{parameters=; id=8d417011-1f73-4706-abeb-be21c52f1195; name=Trigger Gmail R�ponse; type=n8n-nodes-base.gmail; typeVersion=2.1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=c51a167d-b1de-4f76-a30e-ceca5b8c8742; name=Cherche Email Notion; type=n8n-nodes-base.notion; typeVersion=1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d; name=Analyse IA R�ponse; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=8a8459bc-d38a-43ef-92b3-5517ba97a1a1; name=Update Notion R�pondu; type=n8n-nodes-base.notion; typeVersion=1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=47f136ed-17fc-4e0d-b8e2-c1c48c52d589; name=Check DEAL; type=n8n-nodes-base.if; typeVersion=1; position=System.Object[]}",
                  "@{parameters=; type=n8n-nodes-base.stickyNote; typeVersion=1; position=System.Object[]; id=429a26dc-88cf-45c5-98c4-65528ad50da3; name=Sticky Note Phase 3}"
              ],
    "connections":  {
                        "8d417011-1f73-4706-abeb-be21c52f1195":  "@{main=System.Object[]}",
                        "c51a167d-b1de-4f76-a30e-ceca5b8c8742":  "@{main=System.Object[]}",
                        "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d":  "@{main=System.Object[]}",
                        "8a8459bc-d38a-43ef-92b3-5517ba97a1a1":  "@{main=System.Object[]}"
                    },
    "settings":  {
                     "executionOrder":  "v1"
                 },
    "staticData":  null,
    "meta":  null,
    "pinData":  null,
    "versionId":  "5b883673-197e-4ce5-8e2d-1247c0f8de63",
    "triggerCount":  0,
    "tags":  [

             ]
},
    {
    "createdAt":  "2025-04-04T19:50:26.770Z",
    "updatedAt":  "2025-04-04T19:50:26.770Z",
    "id":  "Abqyny8wms6ArE17",
    "name":  "Email Sender - Phase 5 (Suivi Post-Concert)",
    "active":  false,
    "nodes":  [
                  "@{parameters=; id=3b7319d1-e905-4843-8f1e-30793b97e403; name=Concert ? Timer J+3; type=n8n-nodes-base.cron; typeVersion=1; position=System.Object[]}",
                  "@{parameters=; id=894f9cd2-f4f7-4ecd-a5b1-7fe91fb87260; name=Get Recent Concerts; type=n8n-nodes-base.notion; typeVersion=1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=3802bc6c-c156-479d-81a7-24a1235f0d18; name=Pr�parer Emails Remerciement; type=n8n-nodes-base.code; typeVersion=2; position=System.Object[]}",
                  "@{parameters=; id=f0ef9b9c-0eba-4238-b366-3d28a84429d0; name=Send Thank You Email; type=n8n-nodes-base.gmail; typeVersion=2.1; position=System.Object[]; credentials=}",
                  "@{parameters=; id=671105b1-2405-4f83-8f16-3c4ad34a22a6; name=Update Notion Status; type=n8n-nodes-base.notion; typeVersion=1; position=System.Object[]; credentials=}",
                  "@{parameters=; type=n8n-nodes-base.stickyNote; typeVersion=1; position=System.Object[]; id=d8679572-aef3-4d0d-bb2c-e6dd340a5deb; name=Sticky Note Phase 5}"
              ],
    "connections":  {
                        "3b7319d1-e905-4843-8f1e-30793b97e403":  "@{main=System.Object[]}",
                        "894f9cd2-f4f7-4ecd-a5b1-7fe91fb87260":  "@{main=System.Object[]}",
                        "3802bc6c-c156-479d-81a7-24a1235f0d18":  "@{main=System.Object[]}",
                        "f0ef9b9c-0eba-4238-b366-3d28a84429d0":  "@{main=System.Object[]}"
                    },
    "settings":  {
                     "executionOrder":  "v1"
                 },
    "staticData":  null,
    "meta":  null,
    "pinData":  null,
    "versionId":  "9309afb9-a3ea-4ff0-9a67-882172c50c74",
    "triggerCount":  0,
    "tags":  [

             ]
}
    // ... plus d'elements ...  ],
  "nextCursor": null
}
`

#### Proprietes importantes

- data - Tableau contenant les workflows
  - id - Identifiant unique du workflow
  - 
ame - Nom du workflow
  - ctive - Indique si le workflow est actif
  - createdAt - Date de creation du workflow
  - updatedAt - Date de derniere mise a jour du workflow

#### Exemple d'utilisation

`powershell
# Recuperer tous les workflows
$workflows = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Method Get -Headers $headers

# Afficher les noms des workflows
$workflows.data | ForEach-Object { Write-Host $_.name }

# Recuperer les IDs des workflows actifs
$activeWorkflowIds = $workflows.data | Where-Object { $_.active -eq $true } | Select-Object -ExpandProperty id
`

## Executions

### Liste des executions

#### Requete

`powershell
Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
`

#### Reponse

`json{
    "data":  [

             ],
    "nextCursor":  null
}`

#### Proprietes importantes

- data - Tableau contenant les executions
  - id - Identifiant unique de l'execution
  - inished - Indique si l'execution est terminee
  - status - Statut de l'execution (success, error, etc.)
  - startedAt - Date de debut de l'execution
  - stoppedAt - Date de fin de l'execution
  - workflowId - ID du workflow execute

#### Exemple d'utilisation

`powershell
# Recuperer toutes les executions
$executions = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions" -Method Get -Headers $headers

# Afficher les executions recentes
$executions.data | Sort-Object startedAt -Descending | Select-Object -First 5 | Format-Table id, workflowId, status

# Recuperer les executions en erreur
$failedExecutions = $executions.data | Where-Object { $_.status -eq "error" }
`

## Tags

### Liste des tags

#### Requete

`powershell
Invoke-RestMethod -Uri "http://localhost:5678/api/v1/tags" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
`

#### Reponse

`json{
    "data":  [
                 {
                     "createdAt":  "2025-04-04T20:08:53.301Z",
                     "updatedAt":  "2025-04-04T20:08:53.301Z",
                     "id":  "OYN2tV47hOb32z8T",
                     "name":  "Test Tag"
                 }
             ],
    "nextCursor":  null
}`

#### Proprietes importantes

- data - Tableau contenant les tags
  - id - Identifiant unique du tag
  - 
ame - Nom du tag
  - createdAt - Date de creation du tag
  - updatedAt - Date de derniere mise a jour du tag

#### Exemple d'utilisation

`powershell
# Recuperer tous les tags
$tags = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/tags" -Method Get -Headers $headers

# Afficher les noms des tags
$tags.data | ForEach-Object { Write-Host $_.name }

# Recuperer les IDs des tags
$tagIds = $tags.data | Select-Object -ExpandProperty id
`

### Creation d'un tag

#### Requete

`powershell
$body = @{
    name = "Mon Tag"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5678/api/v1/tags" -Method Post -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" } -Body $body -ContentType "application/json"
`

#### Reponse

`json{
    "name":  "Test Tag 20250404221004",
    "id":  "SF5G7l7qfj2VyHHV",
    "createdAt":  "2025-04-04T20:10:04.888Z",
    "updatedAt":  "2025-04-04T20:10:04.888Z"
}`

#### Proprietes importantes

- id - Identifiant unique du tag cree
- 
ame - Nom du tag
- createdAt - Date de creation du tag
- updatedAt - Date de derniere mise a jour du tag

#### Exemple d'utilisation

`powershell
# Creer un nouveau tag
$body = @{
    name = "Nouveau Tag"
} | ConvertTo-Json

$newTag = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/tags" -Method Post -Headers $headers -Body $body -ContentType "application/json"

# Afficher l'ID du tag cree
Write-Host "Tag cree avec l'ID: $($newTag.id)"
`

## Utilisateurs

### Liste des utilisateurs

#### Requete

`powershell
Invoke-RestMethod -Uri "http://localhost:5678/api/v1/users" -Method Get -Headers @{ "X-N8N-API-KEY" = "votre-jeton-api" }
`

#### Reponse

`json{
    "data":  [
                 {
                     "id":  "f72908bd-0beb-47c4-9833-38c5fdf66edd",
                     "email":  "gerivonderbitsh+1@gmail.com",
                     "firstName":  "Geri",
                     "lastName":  "VON DER BITSH",
                     "createdAt":  "2025-04-04T18:54:13.121Z",
                     "updatedAt":  "2025-04-04T18:57:28.554Z",
                     "isPending":  false
                 }
             ],
    "nextCursor":  null
}`

#### Proprietes importantes

- data - Tableau contenant les utilisateurs
  - id - Identifiant unique de l'utilisateur
  - email - Adresse email de l'utilisateur
  - irstName - Prenom de l'utilisateur
  - lastName - Nom de l'utilisateur
  - isOwner - Indique si l'utilisateur est proprietaire
  - isPending - Indique si l'utilisateur est en attente d'activation

#### Exemple d'utilisation

`powershell
# Recuperer tous les utilisateurs
$users = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/users" -Method Get -Headers $headers

# Afficher les emails des utilisateurs
$users.data | ForEach-Object { Write-Host $_.email }

# Recuperer les IDs des utilisateurs actifs (non en attente)
$activeUserIds = $users.data | Where-Object { $_.isPending -eq $false } | Select-Object -ExpandProperty id
`

## Conclusion

Cette documentation a ete generee automatiquement en testant les endpoints fonctionnels de l'API n8n sur votre instance locale.

### Remarques importantes

- Les exemples fournis utilisent PowerShell, mais vous pouvez adapter ces requetes a d'autres langages de programmation.
- Remplacez toujours "votre-jeton-api" par votre jeton d'API n8n reel.
- Les reponses peuvent varier en fonction de votre configuration n8n et des donnees presentes dans votre instance.
- Cette documentation a ete generee le 04/04/2025 22:10:05.
- Version de n8n testee: Verifiez votre version dans l'interface utilisateur de n8n.

### Ressources additionnelles

- [Documentation officielle de n8n](https://projet/documentation.n8n.io/)
- [Documentation de l'API n8n](http://localhost:5678/api/v1/projet/documentation/)
