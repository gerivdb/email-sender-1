<#
.SYNOPSIS
    Importe la configuration du module depuis un fichier.
.DESCRIPTION
    Cette fonction permet d'importer la configuration du module depuis un fichier
    au format JSON, YAML, XML ou PSD1.
.PARAMETER Path
    Chemin du fichier de configuration à importer.
.PARAMETER Format
    Format du fichier de configuration (JSON, YAML, XML, PSD1).
    Si non spécifié, le format est déterminé à partir de l'extension du fichier.
.PARAMETER Merge
    Si spécifié, fusionne la configuration importée avec la configuration existante
    au lieu de la remplacer complètement.
.PARAMETER PassThru
    Si spécifié, retourne la configuration mise à jour.
.EXAMPLE
    Import-ExtractedInfoConfiguration -Path "config.json"
    Importe la configuration depuis le fichier config.json.
.EXAMPLE
    Import-ExtractedInfoConfiguration -Path "config.xml" -Format "XML" -Merge -PassThru
    Importe la configuration depuis le fichier config.xml au format XML,
    la fusionne avec la configuration existante et retourne la configuration mise à jour.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-15
#>
function Import-ExtractedInfoConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        
        [Parameter(Position = 1)]
        [ValidateSet("JSON", "YAML", "XML", "PSD1", "AUTO")]
        [string]$Format = "AUTO",
        
        [Parameter()]
        [switch]$Merge,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            throw "Le fichier de configuration n'existe pas: $Path"
        }
        
        # Déterminer le format si AUTO est spécifié
        if ($Format -eq "AUTO") {
            $extension = [System.IO.Path]::GetExtension($Path).ToLower()
            
            switch ($extension) {
                ".json" { $Format = "JSON" }
                ".yaml" { $Format = "YAML" }
                ".yml"  { $Format = "YAML" }
                ".xml"  { $Format = "XML" }
                ".psd1" { $Format = "PSD1" }
                default {
                    # Essayer de déterminer le format à partir du contenu
                    $content = Get-Content -Path $Path -Raw
                    
                    if ($content -match '^\s*\{') {
                        $Format = "JSON"
                    }
                    elseif ($content -match '^\s*<') {
                        $Format = "XML"
                    }
                    elseif ($content -match '^\s*[a-zA-Z0-9_]+\s*:') {
                        $Format = "YAML"
                    }
                    elseif ($content -match '@\{') {
                        $Format = "PSD1"
                    }
                    else {
                        throw "Impossible de déterminer le format du fichier. Veuillez spécifier le format explicitement."
                    }
                }
            }
        }
        
        # Charger la configuration selon le format
        $config = $null
        
        switch ($Format) {
            "JSON" {
                $content = Get-Content -Path $Path -Raw
                $config = ConvertFrom-Json -InputObject $content -AsHashtable
            }
            "YAML" {
                # Vérifier si le module PowerShell-Yaml est installé
                if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
                    throw "Le module PowerShell-Yaml est requis pour charger des fichiers YAML. Installez-le avec : Install-Module -Name powershell-yaml -Force"
                }
                
                Import-Module -Name "powershell-yaml" -ErrorAction Stop
                $content = Get-Content -Path $Path -Raw
                $config = ConvertFrom-Yaml -Yaml $content -AsHashtable
            }
            "XML" {
                [xml]$xml = Get-Content -Path $Path
                $config = ConvertFrom-Xml -Xml $xml
            }
            "PSD1" {
                $config = Import-PowerShellDataFile -Path $Path
            }
        }
        
        # Vérifier que la configuration a été chargée correctement
        if ($null -eq $config) {
            throw "Erreur lors du chargement de la configuration depuis le fichier $Path"
        }
        
        # Appliquer la configuration
        if ($Merge) {
            # Fusionner avec la configuration existante
            $currentConfig = $script:ModuleData.Config
            
            foreach ($key in $config.Keys) {
                $currentConfig[$key] = $config[$key]
            }
            
            Write-Verbose "Configuration fusionnée depuis $Path"
        }
        else {
            # Remplacer complètement la configuration
            $script:ModuleData.Config = $config
            
            Write-Verbose "Configuration remplacée depuis $Path"
        }
        
        # Ajouter un timestamp de dernière modification
        $script:ModuleData.Config["_LastModified"] = [datetime]::Now.ToString("o")
        $script:ModuleData.Config["_ImportedFrom"] = $Path
        
        # Retourner la configuration si PassThru est spécifié
        if ($PassThru) {
            return $script:ModuleData.Config
        }
    }
    catch {
        Write-Error "Erreur lors de l'importation de la configuration: $_"
        return $null
    }
}

# Fonction auxiliaire pour convertir XML en hashtable
function ConvertFrom-Xml {
    param (
        [Parameter(Mandatory = $true)]
        [xml]$Xml
    )
    
    $result = @{}
    
    # Parcourir les éléments XML de premier niveau
    foreach ($node in $Xml.DocumentElement.ChildNodes) {
        if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
            $result[$node.Name] = ConvertXmlNodeToObject -Node $node
        }
    }
    
    return $result
}

# Fonction récursive pour convertir un nœud XML en objet PowerShell
function ConvertXmlNodeToObject {
    param (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlNode]$Node
    )
    
    # Si le nœud a des enfants, créer un hashtable
    if ($Node.HasChildNodes -and $Node.ChildNodes.Count -gt 1) {
        $result = @{}
        
        foreach ($childNode in $Node.ChildNodes) {
            if ($childNode.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                $result[$childNode.Name] = ConvertXmlNodeToObject -Node $childNode
            }
        }
        
        return $result
    }
    # Si le nœud a un seul enfant qui est du texte, retourner la valeur
    elseif ($Node.HasChildNodes -and $Node.ChildNodes.Count -eq 1 -and $Node.ChildNodes[0].NodeType -eq [System.Xml.XmlNodeType]::Text) {
        return $Node.InnerText
    }
    # Si le nœud n'a pas d'enfants, retourner une chaîne vide
    else {
        return ""
    }
}
