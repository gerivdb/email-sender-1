# Script pour nettoyer les notifications des serveurs MCP
# Ce script supprime les notifications d'erreur des serveurs MCP dans VS Code

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

Write-Log "Nettoyage des notifications des serveurs MCP..." -Level "INFO"

# Chemin du fichier de configuration de VS Code
$vsCodeStoragePath = Join-Path -Path $env:APPDATA -ChildPath "Code\User\globalStorage"

# Vérifier si le répertoire existe
if (Test-Path $vsCodeStoragePath) {
    Write-Log "Recherche des fichiers de notification dans $vsCodeStoragePath..." -Level "INFO"
    
    # Rechercher les fichiers de notification liés aux serveurs MCP
    $notificationFiles = Get-ChildItem -Path $vsCodeStoragePath -Recurse -File | Where-Object {
        $_.Name -like "*notifications*" -or $_.Name -like "*mcp*"
    }
    
    if ($notificationFiles.Count -gt 0) {
        Write-Log "Trouvé $($notificationFiles.Count) fichiers de notification potentiels." -Level "INFO"
        
        foreach ($file in $notificationFiles) {
            try {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                
                # Vérifier si le fichier contient des notifications liées aux serveurs MCP
                if ($content -match "MCP server" -or $content -match "modelcontextprotocol" -or $content -match "supergateway") {
                    Write-Log "Nettoyage du fichier de notification : $($file.FullName)" -Level "INFO"
                    
                    # Lire le contenu JSON
                    $jsonContent = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
                    
                    if ($null -ne $jsonContent) {
                        # Filtrer les notifications liées aux serveurs MCP
                        $filteredNotifications = $jsonContent | Where-Object {
                            -not ($_.message -match "MCP server" -or $_.message -match "modelcontextprotocol" -or $_.message -match "supergateway")
                        }
                        
                        # Écrire le contenu filtré dans le fichier
                        $filteredNotifications | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Force
                        Write-Log "Notifications des serveurs MCP supprimées du fichier." -Level "SUCCESS"
                    }
                }
            } catch {
                Write-Log "Erreur lors du traitement du fichier $($file.FullName): $_" -Level "ERROR"
            }
        }
    } else {
        Write-Log "Aucun fichier de notification trouvé." -Level "WARNING"
    }
} else {
    Write-Log "Le répertoire de stockage de VS Code n'existe pas: $vsCodeStoragePath" -Level "WARNING"
}

# Chemin du fichier de configuration de VS Code Workspace Storage
$vsCodeWorkspaceStoragePath = Join-Path -Path $env:APPDATA -ChildPath "Code\User\workspaceStorage"

# Vérifier si le répertoire existe
if (Test-Path $vsCodeWorkspaceStoragePath) {
    Write-Log "Recherche des fichiers de notification dans $vsCodeWorkspaceStoragePath..." -Level "INFO"
    
    # Rechercher les fichiers de notification liés aux serveurs MCP
    $notificationFiles = Get-ChildItem -Path $vsCodeWorkspaceStoragePath -Recurse -File | Where-Object {
        $_.Name -like "*notifications*" -or $_.Name -like "*mcp*"
    }
    
    if ($notificationFiles.Count -gt 0) {
        Write-Log "Trouvé $($notificationFiles.Count) fichiers de notification potentiels." -Level "INFO"
        
        foreach ($file in $notificationFiles) {
            try {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                
                # Vérifier si le fichier contient des notifications liées aux serveurs MCP
                if ($content -match "MCP server" -or $content -match "modelcontextprotocol" -or $content -match "supergateway") {
                    Write-Log "Nettoyage du fichier de notification : $($file.FullName)" -Level "INFO"
                    
                    # Lire le contenu JSON
                    $jsonContent = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
                    
                    if ($null -ne $jsonContent) {
                        # Filtrer les notifications liées aux serveurs MCP
                        $filteredNotifications = $jsonContent | Where-Object {
                            -not ($_.message -match "MCP server" -or $_.message -match "modelcontextprotocol" -or $_.message -match "supergateway")
                        }
                        
                        # Écrire le contenu filtré dans le fichier
                        $filteredNotifications | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Force
                        Write-Log "Notifications des serveurs MCP supprimées du fichier." -Level "SUCCESS"
                    }
                }
            } catch {
                Write-Log "Erreur lors du traitement du fichier $($file.FullName): $_" -Level "ERROR"
            }
        }
    } else {
        Write-Log "Aucun fichier de notification trouvé." -Level "WARNING"
    }
} else {
    Write-Log "Le répertoire de stockage de VS Code Workspace n'existe pas: $vsCodeWorkspaceStoragePath" -Level "WARNING"
}

Write-Log "Nettoyage des notifications terminé." -Level "SUCCESS"
