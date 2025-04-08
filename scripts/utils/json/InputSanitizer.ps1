# Script de sécurisation des entrées utilisateur

# Fonction pour valider et nettoyer une chaîne de caractères
function Test-StringInput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Input,
        
        [Parameter(Mandatory = $false)]
        [string]$Pattern = "^[a-zA-Z0-9\s\-_\.]+$",
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowEmpty,
        
        [Parameter(Mandatory = $false)]
        [int]$MinLength = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLength = 0
    )
    
    # Vérifier si la chaîne est vide
    if ([string]::IsNullOrEmpty($Input)) {
        return $AllowEmpty
    }
    
    # Vérifier la longueur minimale
    if ($MinLength -gt 0 -and $Input.Length -lt $MinLength) {
        return $false
    }
    
    # Vérifier la longueur maximale
    if ($MaxLength -gt 0 -and $Input.Length -gt $MaxLength) {
        return $false
    }
    
    # Vérifier le motif
    return $Input -match $Pattern
}

# Fonction pour nettoyer une chaîne de caractères
function Get-SanitizedString {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Input,
        
        [Parameter(Mandatory = $false)]
        [string]$Pattern = "^[a-zA-Z0-9\s\-_\.]+$",
        
        [Parameter(Mandatory = $false)]
        [string]$Replacement = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveNonMatching
    )
    
    if ([string]::IsNullOrEmpty($Input)) {
        return ""
    }
    
    if ($RemoveNonMatching) {
        # Supprimer tous les caractères qui ne correspondent pas au motif
        return [regex]::Replace($Input, "[^$Pattern]", $Replacement)
    }
    else {
        # Remplacer les caractères spéciaux par leur équivalent HTML
        $sanitized = $Input
        $sanitized = $sanitized.Replace("&", "&amp;")
        $sanitized = $sanitized.Replace("<", "&lt;")
        $sanitized = $sanitized.Replace(">", "&gt;")
        $sanitized = $sanitized.Replace('"', "&quot;")
        $sanitized = $sanitized.Replace("'", "&#39;")
        return $sanitized
    }
}

# Fonction pour valider un chemin de fichier
function Test-SafePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$DisallowedPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$PreventPathTraversal
    )
    
    # Normaliser le chemin
    $normalizedPath = $Path.Replace('\', [System.IO.Path]::DirectorySeparatorChar)
    $normalizedPath = $normalizedPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    
    # Vérifier les chemins autorisés
    if ($AllowedPaths.Count -gt 0) {
        $isAllowed = $false
        foreach ($allowedPath in $AllowedPaths) {
            if ($normalizedPath.StartsWith($allowedPath)) {
                $isAllowed = $true
                break
            }
        }
        
        if (-not $isAllowed) {
            return $false
        }
    }
    
    # Vérifier les chemins interdits
    if ($DisallowedPaths.Count -gt 0) {
        foreach ($disallowedPath in $DisallowedPaths) {
            if ($normalizedPath.StartsWith($disallowedPath)) {
                return $false
            }
        }
    }
    
    # Vérifier la traversée de chemin
    if ($PreventPathTraversal) {
        if ($normalizedPath -match "\.\.") {
            return $false
        }
    }
    
    return $true
}

# Fonction pour valider une URL
function Test-SafeUrl {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedDomains = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedSchemes = @("http", "https"),
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowRelativeUrls
    )
    
    # Vérifier si l'URL est vide
    if ([string]::IsNullOrEmpty($Url)) {
        return $false
    }
    
    # Vérifier si c'est une URL relative
    if ($Url.StartsWith("/") -or $Url.StartsWith("./") -or $Url.StartsWith("../")) {
        return $AllowRelativeUrls
    }
    
    # Essayer de parser l'URL
    try {
        $uri = [System.Uri]$Url
        
        # Vérifier le schéma
        if ($AllowedSchemes.Count -gt 0 -and -not $AllowedSchemes.Contains($uri.Scheme)) {
            return $false
        }
        
        # Vérifier le domaine
        if ($AllowedDomains.Count -gt 0) {
            $isAllowedDomain = $false
            foreach ($domain in $AllowedDomains) {
                if ($uri.Host -eq $domain -or $uri.Host.EndsWith(".$domain")) {
                    $isAllowedDomain = $true
                    break
                }
            }
            
            if (-not $isAllowedDomain) {
                return $false
            }
        }
        
        return $true
    }
    catch {
        return $false
    }
}

# Fonction pour valider un paramètre de commande
function Test-SafeCommandParameter {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Parameter,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreventCommandInjection
    )
    
    # Vérifier si le paramètre est vide
    if ([string]::IsNullOrEmpty($Parameter)) {
        return $true
    }
    
    # Vérifier l'injection de commande
    if ($PreventCommandInjection) {
        # Caractères suspects pour l'injection de commande
        $suspiciousChars = @(';', '&', '|', '>', '<', '`', '$', '(', ')', '{', '}', '[', ']', '!', '#')
        
        foreach ($char in $suspiciousChars) {
            if ($Parameter.Contains($char)) {
                return $false
            }
        }
    }
    
    return $true
}

# Exporter les fonctions
Export-ModuleMember -Function Test-StringInput, Get-SanitizedString, Test-SafePath, Test-SafeUrl, Test-SafeCommandParameter
