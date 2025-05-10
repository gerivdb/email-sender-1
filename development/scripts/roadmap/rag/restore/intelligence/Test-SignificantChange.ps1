# Test-SignificantChange.ps1
# Script pour détecter les changements significatifs nécessitant un point de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$ConfigType,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigId,
    
    [Parameter(Mandatory = $false)]
    [string]$OldConfigPath,
    
    [Parameter(Mandatory = $false)]
    [string]$NewConfigPath,
    
    [Parameter(Mandatory = $false)]
    [object]$OldConfiguration,
    
    [Parameter(Mandatory = $false)]
    [object]$NewConfiguration,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Thresholds = @{},
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour charger une configuration à partir d'un fichier
function Get-ConfigurationFromPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Configuration file not found: $ConfigPath" -Level "Error"
        return $null
    }
    
    try {
        $configuration = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $configuration
    } catch {
        Write-Log "Error loading configuration from file: $_" -Level "Error"
        return $null
    }
}

# Fonction pour obtenir les seuils de changement par défaut
function Get-DefaultThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All"
    )
    
    # Seuils par défaut pour tous les types de configuration
    $defaultThresholds = @{
        # Pourcentage de changement global pour considérer un changement comme significatif
        global_change_percent = 20
        
        # Nombre de propriétés modifiées pour considérer un changement comme significatif
        modified_properties_count = 5
        
        # Nombre de propriétés ajoutées pour considérer un changement comme significatif
        added_properties_count = 3
        
        # Nombre de propriétés supprimées pour considérer un changement comme significatif
        removed_properties_count = 3
        
        # Changement de taille (en pourcentage) pour considérer un changement comme significatif
        size_change_percent = 30
        
        # Changement de structure (en pourcentage) pour considérer un changement comme significatif
        structure_change_percent = 25
        
        # Propriétés critiques dont la modification est toujours considérée comme significative
        critical_properties = @("id", "version", "type", "name")
    }
    
    # Seuils spécifiques par type de configuration
    $typeSpecificThresholds = @{
        Template = @{
            global_change_percent = 15
            critical_properties = @("id", "version", "type", "name", "content")
        }
        Visualization = @{
            global_change_percent = 25
            critical_properties = @("id", "version", "chart_configuration", "data_mapping")
        }
        DataMapping = @{
            global_change_percent = 30
            critical_properties = @("id", "version", "mappings", "transformations")
        }
        Chart = @{
            global_change_percent = 20
            critical_properties = @("id", "version", "chart_type", "data_field")
        }
        Export = @{
            global_change_percent = 15
            critical_properties = @("id", "version", "export_type", "source_id")
        }
        Search = @{
            global_change_percent = 25
            critical_properties = @("id", "version", "search_type", "query")
        }
    }
    
    # Retourner les seuils par défaut si aucun type spécifique n'est demandé
    if ($ConfigType -eq "All") {
        return $defaultThresholds
    }
    
    # Fusionner les seuils par défaut avec les seuils spécifiques au type
    $thresholds = $defaultThresholds.Clone()
    
    if ($typeSpecificThresholds.ContainsKey($ConfigType)) {
        foreach ($key in $typeSpecificThresholds[$ConfigType].Keys) {
            $thresholds[$key] = $typeSpecificThresholds[$ConfigType][$key]
        }
    }
    
    return $thresholds
}

# Fonction pour calculer le pourcentage de changement entre deux objets
function Get-ChangePercentage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$OldObject,
        
        [Parameter(Mandatory = $true)]
        [object]$NewObject
    )
    
    # Convertir les objets en JSON pour une comparaison basée sur la sérialisation
    $oldJson = $OldObject | ConvertTo-Json -Depth 10 -Compress
    $newJson = $NewObject | ConvertTo-Json -Depth 10 -Compress
    
    # Si l'un des objets est vide, retourner 100% de changement
    if ([string]::IsNullOrEmpty($oldJson) -or [string]::IsNullOrEmpty($newJson)) {
        return 100
    }
    
    # Calculer la distance de Levenshtein entre les deux chaînes JSON
    $distance = Get-LevenshteinDistance -String1 $oldJson -String2 $newJson
    
    # Calculer le pourcentage de changement
    $maxLength = [Math]::Max($oldJson.Length, $newJson.Length)
    $changePercentage = ($distance / $maxLength) * 100
    
    return [Math]::Round($changePercentage, 2)
}

# Fonction pour calculer la distance de Levenshtein entre deux chaînes
function Get-LevenshteinDistance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Créer une matrice pour stocker les distances
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    # Initialiser la première colonne
    for ($i = 0; $i -le $len1; $i++) {
        $matrix[$i, 0] = $i
    }
    
    # Initialiser la première ligne
    for ($j = 0; $j -le $len2; $j++) {
        $matrix[0, $j] = $j
    }
    
    # Remplir la matrice
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            
            $matrix[$i, $j] = [Math]::Min(
                $matrix[$i - 1, $j] + 1,          # Suppression
                [Math]::Min(
                    $matrix[$i, $j - 1] + 1,      # Insertion
                    $matrix[$i - 1, $j - 1] + $cost # Substitution
                )
            )
        }
    }
    
    return $matrix[$len1, $len2]
}

# Fonction pour comparer deux objets et identifier les différences
function Compare-Objects {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$OldObject,
        
        [Parameter(Mandatory = $true)]
        [object]$NewObject,
        
        [Parameter(Mandatory = $false)]
        [string]$Path = ""
    )
    
    $differences = @{
        added = @{}
        removed = @{}
        modified = @{}
        path = $Path
    }
    
    # Vérifier si les objets sont null
    if ($null -eq $OldObject -and $null -eq $NewObject) {
        return $differences
    }
    
    if ($null -eq $OldObject) {
        $differences.added[$Path] = $NewObject
        return $differences
    }
    
    if ($null -eq $NewObject) {
        $differences.removed[$Path] = $OldObject
        return $differences
    }
    
    # Comparer les propriétés des objets
    $oldProperties = $OldObject.PSObject.Properties.Name
    $newProperties = $NewObject.PSObject.Properties.Name
    
    # Trouver les propriétés ajoutées
    foreach ($prop in $newProperties) {
        if ($oldProperties -notcontains $prop) {
            $propPath = if ([string]::IsNullOrEmpty($Path)) { $prop } else { "$Path.$prop" }
            $differences.added[$propPath] = $NewObject.$prop
        }
    }
    
    # Trouver les propriétés supprimées
    foreach ($prop in $oldProperties) {
        if ($newProperties -notcontains $prop) {
            $propPath = if ([string]::IsNullOrEmpty($Path)) { $prop } else { "$Path.$prop" }
            $differences.removed[$propPath] = $OldObject.$prop
        }
    }
    
    # Trouver les propriétés modifiées
    foreach ($prop in $oldProperties) {
        if ($newProperties -contains $prop) {
            $propPath = if ([string]::IsNullOrEmpty($Path)) { $prop } else { "$Path.$prop" }
            
            # Vérifier si les valeurs sont différentes
            $oldValue = $OldObject.$prop
            $newValue = $NewObject.$prop
            
            if ($oldValue -is [System.Management.Automation.PSCustomObject] -and $newValue -is [System.Management.Automation.PSCustomObject]) {
                # Comparer récursivement les objets imbriqués
                $subDifferences = Compare-Objects -OldObject $oldValue -NewObject $newValue -Path $propPath
                
                # Fusionner les différences
                foreach ($key in $subDifferences.added.Keys) {
                    $differences.added[$key] = $subDifferences.added[$key]
                }
                
                foreach ($key in $subDifferences.removed.Keys) {
                    $differences.removed[$key] = $subDifferences.removed[$key]
                }
                
                foreach ($key in $subDifferences.modified.Keys) {
                    $differences.modified[$key] = $subDifferences.modified[$key]
                }
            } elseif ($oldValue -is [array] -and $newValue -is [array]) {
                # Comparer les tableaux
                if (($oldValue | ConvertTo-Json -Depth 10) -ne ($newValue | ConvertTo-Json -Depth 10)) {
                    $differences.modified[$propPath] = @{
                        old = $oldValue
                        new = $newValue
                    }
                }
            } else {
                # Comparer les valeurs simples
                if ($oldValue -ne $newValue) {
                    $differences.modified[$propPath] = @{
                        old = $oldValue
                        new = $newValue
                    }
                }
            }
        }
    }
    
    return $differences
}

# Fonction pour vérifier si un changement est significatif
function Test-SignificantChange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId,
        
        [Parameter(Mandatory = $false)]
        [string]$OldConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$NewConfigPath,
        
        [Parameter(Mandatory = $false)]
        [object]$OldConfiguration,
        
        [Parameter(Mandatory = $false)]
        [object]$NewConfiguration,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Thresholds = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    # Charger les configurations à partir des fichiers si nécessaire
    if ($null -eq $OldConfiguration -and -not [string]::IsNullOrEmpty($OldConfigPath)) {
        $OldConfiguration = Get-ConfigurationFromPath -ConfigPath $OldConfigPath
    }
    
    if ($null -eq $NewConfiguration -and -not [string]::IsNullOrEmpty($NewConfigPath)) {
        $NewConfiguration = Get-ConfigurationFromPath -ConfigPath $NewConfigPath
    }
    
    # Vérifier si les configurations sont disponibles
    if ($null -eq $OldConfiguration -or $null -eq $NewConfiguration) {
        Write-Log "Both old and new configurations must be provided" -Level "Error"
        return $false
    }
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        if ($NewConfiguration.PSObject.Properties.Name.Contains("type")) {
            $ConfigType = $NewConfiguration.type
        } else {
            $ConfigType = "All"
        }
    }
    
    # Obtenir les seuils par défaut si non spécifiés
    if ($Thresholds.Count -eq 0) {
        $Thresholds = Get-DefaultThresholds -ConfigType $ConfigType
    }
    
    # Calculer le pourcentage de changement global
    $globalChangePercent = Get-ChangePercentage -OldObject $OldConfiguration -NewObject $NewConfiguration
    
    # Comparer les objets pour identifier les différences spécifiques
    $differences = Compare-Objects -OldObject $OldConfiguration -NewObject $NewConfiguration
    
    # Calculer les métriques de changement
    $addedCount = $differences.added.Count
    $removedCount = $differences.removed.Count
    $modifiedCount = $differences.modified.Count
    $totalChanges = $addedCount + $removedCount + $modifiedCount
    
    # Vérifier si des propriétés critiques ont été modifiées
    $criticalChanges = @()
    foreach ($criticalProp in $Thresholds.critical_properties) {
        foreach ($modifiedProp in $differences.modified.Keys) {
            if ($modifiedProp -eq $criticalProp -or $modifiedProp.EndsWith(".$criticalProp")) {
                $criticalChanges += $modifiedProp
            }
        }
    }
    
    # Déterminer si le changement est significatif
    $isSignificant = $false
    $reasons = @()
    
    if ($globalChangePercent -ge $Thresholds.global_change_percent) {
        $isSignificant = $true
        $reasons += "Global change percentage ($globalChangePercent%) exceeds threshold ($($Thresholds.global_change_percent)%)"
    }
    
    if ($modifiedCount -ge $Thresholds.modified_properties_count) {
        $isSignificant = $true
        $reasons += "Number of modified properties ($modifiedCount) exceeds threshold ($($Thresholds.modified_properties_count))"
    }
    
    if ($addedCount -ge $Thresholds.added_properties_count) {
        $isSignificant = $true
        $reasons += "Number of added properties ($addedCount) exceeds threshold ($($Thresholds.added_properties_count))"
    }
    
    if ($removedCount -ge $Thresholds.removed_properties_count) {
        $isSignificant = $true
        $reasons += "Number of removed properties ($removedCount) exceeds threshold ($($Thresholds.removed_properties_count))"
    }
    
    if ($criticalChanges.Count -gt 0) {
        $isSignificant = $true
        $reasons += "Critical properties were modified: $($criticalChanges -join ', ')"
    }
    
    # Créer le résultat
    $result = @{
        is_significant = $isSignificant
        config_type = $ConfigType
        config_id = $ConfigId
        global_change_percent = $globalChangePercent
        added_count = $addedCount
        removed_count = $removedCount
        modified_count = $modifiedCount
        total_changes = $totalChanges
        critical_changes = $criticalChanges
        reasons = $reasons
    }
    
    # Ajouter les différences détaillées si demandé
    if ($Detailed) {
        $result.differences = $differences
    }
    
    # Journaliser le résultat
    if ($isSignificant) {
        Write-Log "Significant change detected for $ConfigType configuration" -Level "Info"
        foreach ($reason in $reasons) {
            Write-Log "  - $reason" -Level "Info"
        }
    } else {
        Write-Log "No significant change detected for $ConfigType configuration" -Level "Debug"
    }
    
    return $result
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-SignificantChange -ConfigType $ConfigType -ConfigId $ConfigId -OldConfigPath $OldConfigPath -NewConfigPath $NewConfigPath -OldConfiguration $OldConfiguration -NewConfiguration $NewConfiguration -Thresholds $Thresholds -Detailed:$Detailed
}
