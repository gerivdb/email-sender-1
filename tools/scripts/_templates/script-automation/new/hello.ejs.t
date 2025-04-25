---
to: scripts/automation/<%= name %>.ps1
---
#Requires -Version 5.1
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>
    <%= additionalDescription ? additionalDescription : '' %>

.PARAMETER Path
    Chemin du répertoire à traiter.

.PARAMETER Force
    Indique s'il faut forcer l'exécution sans confirmation.

.EXAMPLE
    .\<%= name %>.ps1 -Path "C:\Scripts"
    Exécute le script sur le répertoire spécifié.

.EXAMPLE
    .\<%= name %>.ps1 -Path "C:\Scripts" -Force
    Exécute le script sur le répertoire spécifié sans demander de confirmation.

.NOTES
    Auteur: <%= author || 'EMAIL_SENDER_1' %>
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
    Tags: <%= tags || 'automation, scripts' %>
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
$utilsModulePath = Join-Path -Path $modulesPath -ChildPath "ScriptUtils.psm1"

if (Test-Path $utilsModulePath) {
    Import-Module $utilsModulePath -Force
    Write-Verbose "Module ScriptUtils importé depuis $utilsModulePath"
}
else {
    Write-Warning "Module ScriptUtils non trouvé à l'emplacement $utilsModulePath"
}

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor Green
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Fonction principale
function Start-<%= h.changeCase.pascal(name) %> {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    # Vérifier que le répertoire existe
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Le répertoire spécifié n'existe pas: $Path"
        return $false
    }
    
    Write-Info "Démarrage du traitement sur le répertoire: $Path"
    
    # Demander confirmation si -Force n'est pas spécifié
    if (-not $Force) {
        $confirmation = Read-Host "Êtes-vous sûr de vouloir exécuter ce script sur le répertoire $Path ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Warning "Opération annulée par l'utilisateur."
            return $false
        }
    }
    
    # Traitement principal
    if ($PSCmdlet.ShouldProcess("Répertoire $Path", "Traitement d'automatisation")) {
        try {
            # TODO: Implémentez votre logique d'automatisation ici
            
            # Exemple de traitement
            $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
            Write-Info "Nombre de fichiers trouvés: $($files.Count)"
            
            # Traitement des fichiers
            $processedCount = 0
            foreach ($file in $files) {
                # TODO: Traitez chaque fichier selon vos besoins
                $processedCount++
                Write-Verbose "Traitement du fichier: $($file.FullName)"
            }
            
            Write-Success "Traitement terminé. $processedCount fichiers traités."
            return $true
        }
        catch {
            Write-Error "Une erreur s'est produite lors du traitement: $_"
            return $false
        }
    }
    
    return $true
}

# Exécuter la fonction principale
$result = Start-<%= h.changeCase.pascal(name) %>

# Afficher un résumé
if ($result) {
    Write-Host "`nOpération terminée avec succès." -ForegroundColor Green
}
else {
    Write-Host "`nL'opération a échoué ou a été annulée." -ForegroundColor Red
}
