# Script pour organiser les fichiers n8n
# Ce script organise les fichiers finaux indispensables au projet Email Sender

# CrÃ©ation des rÃ©pertoires s'ils n'existent pas
$directories = @("workflows", "credentials", "config", "mcp")
foreach ($dir in $directories) {
    if (-not (Test-Path -Path $dir)) {
        Write-Host "CrÃ©ation du rÃ©pertoire $dir..."
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Copie des fichiers de workflow
Write-Host "Copie des fichiers de workflow..."
Copy-Item -Path ".\src\workflows\EMAIL_SENDER_*.json" -Destination ".\workflows\" -Force

# Copie des fichiers de configuration MCP
Write-Host "Copie des fichiers de configuration MCP..."
Copy-Item -Path ".\src\mcp\config\*.json" -Destination ".\mcp\" -Force

# Copie des fichiers de credentials
Write-Host "Copie des fichiers de credentials..."
Copy-Item -Path ".\.n8n\credentials\*.json" -Destination ".\credentials\" -Force

# Copie du fichier de configuration n8n
Write-Host "Copie du fichier de configuration n8n..."
Copy-Item -Path ".\.n8n\config" -Destination ".\config\n8n-config.txt" -Force

Write-Host "Organisation des fichiers terminÃ©e avec succÃ¨s!"
Write-Host ""
Write-Host "Structure des rÃ©pertoires :"
Write-Host "- workflows/ : Contient les fichiers de workflow n8n"
Write-Host "- credentials/ : Contient les informations d'identification"
Write-Host "- config/ : Contient les fichiers de configuration"
Write-Host "- mcp/ : Contient les configurations MCP"
