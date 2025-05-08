<#
.SYNOPSIS
    Importe la configuration du module depuis les variables d'environnement.
.DESCRIPTION
    Cette fonction permet d'importer la configuration du module depuis les variables d'environnement
    ayant un préfixe spécifique.
.PARAMETER Prefix
    Préfixe des variables d'environnement à considérer (par défaut: "EXTRACTEDINFO_").
.PARAMETER Merge
    Si spécifié, fusionne la configuration importée avec la configuration existante
    au lieu de la remplacer complètement.
.PARAMETER PassThru
    Si spécifié, retourne la configuration mise à jour.
.EXAMPLE
    Import-ExtractedInfoConfigurationFromEnv
    Importe la configuration depuis les variables d'environnement avec le préfixe par défaut.
.EXAMPLE
    Import-ExtractedInfoConfigurationFromEnv -Prefix "MYAPP_" -Merge -PassThru
    Importe la configuration depuis les variables d'environnement avec le préfixe "MYAPP_",
    la fusionne avec la configuration existante et retourne la configuration mise à jour.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-15
#>
function Import-ExtractedInfoConfigurationFromEnv {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Prefix = "EXTRACTEDINFO_",
        
        [Parameter()]
        [switch]$Merge,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    try {
        # Récupérer toutes les variables d'environnement avec le préfixe spécifié
        $envVars = Get-ChildItem -Path Env: | Where-Object { $_.Name -like "$Prefix*" }
        
        # Créer un hashtable pour stocker la configuration
        $config = @{}
        
        # Traiter chaque variable d'environnement
        foreach ($var in $envVars) {
            # Extraire le nom de la clé (sans le préfixe)
            $key = $var.Name.Substring($Prefix.Length)
            
            # Convertir la valeur selon son type
            $value = $var.Value
            
            # Essayer de convertir en type approprié
            if ($value -eq "true" -or $value -eq "false") {
                # Booléen
                $value = [System.Convert]::ToBoolean($value)
            }
            elseif ($value -match "^\d+$") {
                # Entier
                $value = [int]$value
            }
            elseif ($value -match "^\d+\.\d+$") {
                # Nombre à virgule flottante
                $value = [double]$value
            }
            elseif ($value.StartsWith("[") -and $value.EndsWith("]")) {
                # Tableau
                $value = $value.Substring(1, $value.Length - 2).Split(",") | ForEach-Object { $_.Trim() }
            }
            elseif ($value.StartsWith("{") -and $value.EndsWith("}")) {
                # Hashtable (format JSON)
                try {
                    $value = ConvertFrom-Json -InputObject $value -AsHashtable
                }
                catch {
                    # Garder la valeur telle quelle si la conversion échoue
                    Write-Warning "Impossible de convertir la valeur JSON pour la clé $key"
                }
            }
            
            # Gérer les clés hiérarchiques (avec des points)
            if ($key -match "\.") {
                $keyParts = $key -split "\."
                $currentLevel = $config
                
                # Créer la structure hiérarchique
                for ($i = 0; $i -lt $keyParts.Count - 1; $i++) {
                    $keyPart = $keyParts[$i]
                    
                    if (-not $currentLevel.ContainsKey($keyPart)) {
                        $currentLevel[$keyPart] = @{}
                    }
                    
                    $currentLevel = $currentLevel[$keyPart]
                }
                
                # Définir la valeur au niveau le plus profond
                $currentLevel[$keyParts[-1]] = $value
            }
            else {
                # Clé simple
                $config[$key] = $value
            }
        }
        
        # Vérifier si des variables d'environnement ont été trouvées
        if ($config.Count -eq 0) {
            Write-Warning "Aucune variable d'environnement trouvée avec le préfixe '$Prefix'"
        }
        else {
            Write-Verbose "Configuration importée depuis $($config.Count) variables d'environnement"
        }
        
        # Appliquer la configuration
        if ($Merge) {
            # Fusionner avec la configuration existante
            $currentConfig = $script:ModuleData.Config
            
            foreach ($key in $config.Keys) {
                $currentConfig[$key] = $config[$key]
            }
            
            Write-Verbose "Configuration fusionnée depuis les variables d'environnement"
        }
        else {
            # Remplacer complètement la configuration
            $script:ModuleData.Config = $config
            
            Write-Verbose "Configuration remplacée depuis les variables d'environnement"
        }
        
        # Ajouter un timestamp de dernière modification
        $script:ModuleData.Config["_LastModified"] = [datetime]::Now.ToString("o")
        $script:ModuleData.Config["_ImportedFromEnv"] = $true
        
        # Retourner la configuration si PassThru est spécifié
        if ($PassThru) {
            return $script:ModuleData.Config
        }
    }
    catch {
        Write-Error "Erreur lors de l'importation de la configuration depuis les variables d'environnement: $_"
        return $null
    }
}
