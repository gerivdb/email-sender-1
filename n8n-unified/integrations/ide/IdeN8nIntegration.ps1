<#
.SYNOPSIS
    Script d'intégration entre n8n et l'IDE.

.DESCRIPTION
    Ce script fournit des fonctions pour intégrer n8n avec l'IDE, permettant
    de créer, exécuter et gérer des workflows n8n depuis l'IDE.
#>

#Requires -Version 5.1

# Paramètres globaux
param (
    [string]$N8nUrl = "http://localhost:5678",
    [string]$ApiKey = "",
    [switch]$EnableDebug
)

# Variables globales
$script:N8nBaseUrl = $N8nUrl
$script:N8nApiKey = $ApiKey
$script:LogFile = Join-Path -Path $PSScriptRoot -ChildPath "logs\ide-n8n-integration.log"
$script:ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "config\ide-n8n-config.json"
$script:WorkflowsDir = Join-Path -Path $PSScriptRoot -ChildPath "workflows"
$script:TemplatesDir = Join-Path -Path $PSScriptRoot -ChildPath "templates"

# Création des dossiers nécessaires
$Dirs = @(
    (Split-Path -Path $script:LogFile -Parent),
    (Split-Path -Path $script:ConfigFile -Parent),
    $script:WorkflowsDir,
    $script:TemplatesDir
)

foreach ($Dir in $Dirs) {
    if (-not (Test-Path -Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if ($Level -eq "DEBUG" -and -not $EnableDebug) { return }
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Add-Content -Path $script:LogFile -Value $LogMessage -Encoding UTF8
    
    switch ($Level) {
        "INFO" { Write-Host $LogMessage -ForegroundColor White }
        "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "DEBUG" { Write-Host $LogMessage -ForegroundColor Gray }
    }
}

# Fonction pour charger la configuration
function Get-IdeN8nConfig {
    try {
        if (Test-Path -Path $script:ConfigFile) {
            $Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
            Write-Log -Message "Configuration chargée avec succès" -Level DEBUG
            return $Config
        }
        else {
            $Config = @{
                N8nUrl = $script:N8nBaseUrl
                ApiKey = $script:N8nApiKey
                LastSync = $null
                Workflows = @()
                Templates = @()
                VsCodeExtension = @{
                    Installed = $false
                    Version = ""
                }
            }
            
            $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Encoding UTF8
            Write-Log -Message "Configuration par défaut créée" -Level INFO
            return $Config
        }
    }
    catch {
        Write-Log -Message "Erreur lors du chargement de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour sauvegarder la configuration
function Save-IdeN8nConfig {
    param (
        [PSCustomObject]$Config
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Encoding UTF8
        Write-Log -Message "Configuration sauvegardée avec succès" -Level DEBUG
    }
    catch {
        Write-Log -Message "Erreur lors de la sauvegarde de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour tester la connexion à n8n
function Test-N8nConnection {
    try {
        $Config = Get-IdeN8nConfig
        $Headers = @{ "Accept" = "application/json" }
        
        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }
        
        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/healthz" -Method Get -Headers $Headers
        
        if ($Response.status -eq "ok") {
            Write-Log -Message "Connexion à n8n réussie" -Level INFO
            return $true
        }
        else {
            Write-Log -Message "Connexion à n8n échouée : $($Response.status)" -Level ERROR
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors de la connexion à n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction pour récupérer les workflows n8n
function Get-N8nWorkflows {
    try {
        $Config = Get-IdeN8nConfig
        $Headers = @{ "Accept" = "application/json" }
        
        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }
        
        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows" -Method Get -Headers $Headers
        
        Write-Log -Message "Récupération de $($Response.Count) workflows" -Level INFO
        return $Response
    }
    catch {
        Write-Log -Message "Erreur lors de la récupération des workflows : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour récupérer un workflow n8n par son ID
function Get-N8nWorkflow {
    param (
        [string]$WorkflowId
    )
    
    try {
        $Config = Get-IdeN8nConfig
        $Headers = @{ "Accept" = "application/json" }
        
        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }
        
        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId" -Method Get -Headers $Headers
        
        Write-Log -Message "Récupération du workflow $WorkflowId réussie" -Level INFO
        return $Response
    }
    catch {
        Write-Log -Message "Erreur lors de la récupération du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour exécuter un workflow n8n
function Invoke-N8nWorkflow {
    param (
        [string]$WorkflowId,
        [PSCustomObject]$Data
    )
    
    try {
        $Config = Get-IdeN8nConfig
        $Headers = @{
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        }
        
        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }
        
        $Body = $null
        if ($Data) {
            $Body = $Data | ConvertTo-Json -Depth 10
        }
        
        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId/execute" -Method Post -Headers $Headers -Body $Body
        
        Write-Log -Message "Exécution du workflow $WorkflowId réussie" -Level INFO
        return $Response
    }
    catch {
        Write-Log -Message "Erreur lors de l'exécution du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour créer un workflow n8n
function New-N8nWorkflow {
    param (
        [string]$Name,
        [string]$Description = "",
        [PSCustomObject]$Nodes = @(),
        [PSCustomObject]$Connections = @{},
        [bool]$Active = $false
    )
    
    try {
        $Config = Get-IdeN8nConfig
        $Headers = @{
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        }
        
        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }
        
        # Créer le workflow
        $Workflow = @{
            name = $Name
            active = $Active
            nodes = $Nodes
            connections = $Connections
        }
        
        if (-not [string]::IsNullOrEmpty($Description)) {
            $Workflow.Add("description", $Description)
        }
        
        $Body = $Workflow | ConvertTo-Json -Depth 10
        
        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows" -Method Post -Headers $Headers -Body $Body
        
        Write-Log -Message "Création du workflow $Name réussie (ID: $($Response.id))" -Level INFO
        return $Response
    }
    catch {
        Write-Log -Message "Erreur lors de la création du workflow $Name : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour mettre à jour un workflow n8n
function Update-N8nWorkflow {
    param (
        [string]$WorkflowId,
        [string]$Name,
        [string]$Description,
        [PSCustomObject]$Nodes,
        [PSCustomObject]$Connections,
        [bool]$Active
    )
    
    try {
        $Config = Get-IdeN8nConfig
        $Headers = @{
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        }
        
        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }
        
        # Récupérer le workflow existant
        $ExistingWorkflow = Get-N8nWorkflow -WorkflowId $WorkflowId
        
        # Mettre à jour les propriétés
        if ($Name) {
            $ExistingWorkflow.name = $Name
        }
        
        if ($Description) {
            $ExistingWorkflow.description = $Description
        }
        
        if ($Nodes) {
            $ExistingWorkflow.nodes = $Nodes
        }
        
        if ($Connections) {
            $ExistingWorkflow.connections = $Connections
        }
        
        if ($PSBoundParameters.ContainsKey('Active')) {
            $ExistingWorkflow.active = $Active
        }
        
        $Body = $ExistingWorkflow | ConvertTo-Json -Depth 10
        
        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId" -Method Put -Headers $Headers -Body $Body
        
        Write-Log -Message "Mise à jour du workflow $WorkflowId réussie" -Level INFO
        return $Response
    }
    catch {
        Write-Log -Message "Erreur lors de la mise à jour du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour supprimer un workflow n8n
function Remove-N8nWorkflow {
    param (
        [string]$WorkflowId
    )
    
    try {
        $Config = Get-IdeN8nConfig
        $Headers = @{ "Accept" = "application/json" }
        
        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }
        
        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId" -Method Delete -Headers $Headers
        
        Write-Log -Message "Suppression du workflow $WorkflowId réussie" -Level INFO
        return $Response
    }
    catch {
        Write-Log -Message "Erreur lors de la suppression du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour synchroniser les workflows n8n avec l'IDE
function Sync-N8nWorkflowsWithIde {
    try {
        # Récupérer les workflows n8n
        $Workflows = Get-N8nWorkflows
        
        # Récupérer la configuration
        $Config = Get-IdeN8nConfig
        
        # Mettre à jour la liste des workflows dans la configuration
        $Config.Workflows = $Workflows | Select-Object id, name, active, createdAt, updatedAt
        $Config.LastSync = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Sauvegarder la configuration
        Save-IdeN8nConfig -Config $Config
        
        # Sauvegarder les workflows dans des fichiers JSON
        foreach ($Workflow in $Workflows) {
            $WorkflowFile = Join-Path -Path $script:WorkflowsDir -ChildPath "$($Workflow.id).json"
            $Workflow | ConvertTo-Json -Depth 10 | Set-Content -Path $WorkflowFile -Encoding UTF8
        }
        
        Write-Log -Message "Synchronisation des workflows avec l'IDE réussie" -Level INFO
        return $Config.Workflows
    }
    catch {
        Write-Log -Message "Erreur lors de la synchronisation des workflows avec l'IDE : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour créer un workflow n8n à partir d'un modèle
function New-N8nWorkflowFromTemplate {
    param (
        [string]$TemplateName,
        [string]$Name,
        [string]$Description = "",
        [hashtable]$Parameters = @{}
    )
    
    try {
        # Vérifier si le modèle existe
        $TemplateFile = Join-Path -Path $script:TemplatesDir -ChildPath "$TemplateName.json"
        if (-not (Test-Path -Path $TemplateFile)) {
            Write-Log -Message "Le modèle $TemplateName n'existe pas" -Level ERROR
            return $null
        }
        
        # Charger le modèle
        $Template = Get-Content -Path $TemplateFile -Raw | ConvertFrom-Json
        
        # Remplacer les paramètres
        $TemplateJson = $Template | ConvertTo-Json -Depth 10
        foreach ($Key in $Parameters.Keys) {
            $TemplateJson = $TemplateJson -replace "{{$Key}}", $Parameters[$Key]
        }
        
        $Template = $TemplateJson | ConvertFrom-Json
        
        # Créer le workflow
        $Workflow = New-N8nWorkflow -Name $Name -Description $Description -Nodes $Template.nodes -Connections $Template.connections -Active $false
        
        Write-Log -Message "Création du workflow à partir du modèle $TemplateName réussie (ID: $($Workflow.id))" -Level INFO
        return $Workflow
    }
    catch {
        Write-Log -Message "Erreur lors de la création du workflow à partir du modèle $TemplateName : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour vérifier si l'extension VS Code est installée
function Test-VsCodeExtension {
    param (
        [string]$ExtensionId = "n8n-io.n8n-vscode"
    )
    
    try {
        $Extensions = & code --list-extensions
        $IsInstalled = $Extensions -contains $ExtensionId
        
        if ($IsInstalled) {
            Write-Log -Message "Extension VS Code $ExtensionId est installée" -Level INFO
            return $true
        }
        else {
            Write-Log -Message "Extension VS Code $ExtensionId n'est pas installée" -Level WARNING
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors de la vérification de l'extension VS Code : $_" -Level ERROR
        return $false
    }
}

# Fonction pour installer l'extension VS Code
function Install-VsCodeExtension {
    param (
        [string]$ExtensionId = "n8n-io.n8n-vscode"
    )
    
    try {
        # Vérifier si l'extension est déjà installée
        if (Test-VsCodeExtension -ExtensionId $ExtensionId) {
            Write-Log -Message "Extension VS Code $ExtensionId est déjà installée" -Level INFO
            return $true
        }
        
        # Installer l'extension
        & code --install-extension $ExtensionId
        
        # Vérifier si l'installation a réussi
        if (Test-VsCodeExtension -ExtensionId $ExtensionId) {
            Write-Log -Message "Installation de l'extension VS Code $ExtensionId réussie" -Level INFO
            
            # Mettre à jour la configuration
            $Config = Get-IdeN8nConfig
            $Config.VsCodeExtension.Installed = $true
            $Config.VsCodeExtension.Version = "1.0.0" # À remplacer par la version réelle
            Save-IdeN8nConfig -Config $Config
            
            return $true
        }
        else {
            Write-Log -Message "Échec de l'installation de l'extension VS Code $ExtensionId" -Level ERROR
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors de l'installation de l'extension VS Code : $_" -Level ERROR
        return $false
    }
}

# Fonction pour ouvrir un workflow dans VS Code
function Open-WorkflowInVsCode {
    param (
        [string]$WorkflowId
    )
    
    try {
        # Vérifier si le workflow existe
        $WorkflowFile = Join-Path -Path $script:WorkflowsDir -ChildPath "$WorkflowId.json"
        if (-not (Test-Path -Path $WorkflowFile)) {
            # Récupérer le workflow depuis n8n
            $Workflow = Get-N8nWorkflow -WorkflowId $WorkflowId
            
            # Sauvegarder le workflow dans un fichier JSON
            $Workflow | ConvertTo-Json -Depth 10 | Set-Content -Path $WorkflowFile -Encoding UTF8
        }
        
        # Ouvrir le fichier dans VS Code
        & code $WorkflowFile
        
        Write-Log -Message "Ouverture du workflow $WorkflowId dans VS Code réussie" -Level INFO
        return $true
    }
    catch {
        Write-Log -Message "Erreur lors de l'ouverture du workflow $WorkflowId dans VS Code : $_" -Level ERROR
        return $false
    }
}

# Fonction principale
function Start-IdeN8nIntegration {
    param (
        [ValidateSet("Test", "Sync", "Install", "Open")]
        [string]$Action = "Test",
        [string]$WorkflowId
    )
    
    try {
        Write-Log -Message "Démarrage de l'intégration IDE-n8n (Action: $Action)" -Level INFO
        
        # Tester la connexion à n8n
        $Connected = Test-N8nConnection
        if (-not $Connected) {
            Write-Log -Message "Impossible de se connecter à n8n. Vérifiez que n8n est en cours d'exécution et accessible." -Level ERROR
            return $false
        }
        
        # Exécuter l'action demandée
        switch ($Action) {
            "Test" {
                # Récupérer les workflows n8n
                $Workflows = Get-N8nWorkflows
                Write-Log -Message "Test réussi. $($Workflows.Count) workflows trouvés." -Level INFO
                return $Workflows
            }
            "Sync" {
                # Synchroniser les workflows n8n avec l'IDE
                $Workflows = Sync-N8nWorkflowsWithIde
                Write-Log -Message "Synchronisation réussie. $($Workflows.Count) workflows synchronisés." -Level INFO
                return $Workflows
            }
            "Install" {
                # Installer l'extension VS Code
                $Result = Install-VsCodeExtension
                Write-Log -Message "Installation de l'extension VS Code terminée." -Level INFO
                return $Result
            }
            "Open" {
                # Ouvrir un workflow dans VS Code
                if (-not $WorkflowId) {
                    Write-Log -Message "ID du workflow non spécifié." -Level ERROR
                    return $false
                }
                
                $Result = Open-WorkflowInVsCode -WorkflowId $WorkflowId
                Write-Log -Message "Ouverture du workflow terminée." -Level INFO
                return $Result
            }
        }
    }
    catch {
        Write-Log -Message "Erreur lors de l'exécution de l'action $Action : $_" -Level ERROR
        throw $_
    }
}
