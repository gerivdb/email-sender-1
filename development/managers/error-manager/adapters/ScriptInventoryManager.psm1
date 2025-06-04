# ScriptInventoryManager.psm1
# Module PowerShell pour l'inventaire des scripts
# Intégration avec ErrorManager Go

# Fonction principale pour obtenir l'inventaire des scripts
function Get-ScriptInventory {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$Path,
        
      [Parameter(Mandatory = $false)]
      [switch]$Detailed,
        
      [Parameter(Mandatory = $false)]
      [string]$OutputFormat = "JSON"
   )
    
   try {
      Write-Verbose "Scanning path: $Path"
        
      $scripts = @()
      $supportedExtensions = @("*.ps1", "*.py", "*.go", "*.js", "*.ts")
        
      foreach ($extension in $supportedExtensions) {
         $files = Get-ChildItem -Path $Path -Filter $extension -Recurse -ErrorAction SilentlyContinue
            
         foreach ($file in $files) {
            $scriptInfo = @{
               Path         = $file.FullName
               Type         = Get-ScriptType -Extension $file.Extension
               Size         = $file.Length
               LastModified = $file.LastWriteTime
               Hash         = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
            }
                
            if ($Detailed) {
               $scriptInfo.Dependencies = Get-ScriptDependencies -ScriptPath $file.FullName
               $scriptInfo.Metadata = Get-ScriptMetadata -ScriptPath $file.FullName
            }
                
            $scripts += $scriptInfo
         }
      }
        
      $result = @{
         Success    = $true
         Scripts    = $scripts
         TotalCount = $scripts.Count
         ScanPath   = $Path
         Timestamp  = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
      }
        
      if ($OutputFormat -eq "JSON") {
         return ($result | ConvertTo-Json -Depth 10)
      }
      else {
         return $result
      }
   }
   catch {
      $errorResult = @{
         Success    = $false
         Error      = $_.Exception.Message
         StackTrace = $_.ScriptStackTrace
         Timestamp  = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
      }
        
      # Signaler l'erreur au ErrorManager Go via API REST ou fichier
      Send-ErrorToManager -Error $errorResult
        
      if ($OutputFormat -eq "JSON") {
         return ($errorResult | ConvertTo-Json -Depth 10)
      }
      else {
         return $errorResult
      }
   }
}

# Fonction pour déterminer le type de script
function Get-ScriptType {
   [CmdletBinding()]
   param([string]$Extension)
    
   switch ($Extension.ToLower()) {
      ".ps1" { return "PowerShell" }
      ".py" { return "Python" }
      ".go" { return "Go" }
      ".js" { return "JavaScript" }
      ".ts" { return "TypeScript" }
      default { return "Unknown" }
   }
}

# Fonction pour obtenir les dépendances d'un script
function Get-ScriptDependencies {
   [CmdletBinding()]
   param([string]$ScriptPath)
    
   $dependencies = @()
    
   try {
      $content = Get-Content -Path $ScriptPath -Raw
        
      # Analyse des imports/requires selon le type de fichier
      $extension = [System.IO.Path]::GetExtension($ScriptPath).ToLower()
        
      switch ($extension) {
         ".ps1" {
            # Rechercher Import-Module, Import-Module, using module
            $importPattern = '(?:Import-Module|using module)\s+[''"]?([^''";\s]+)[''"]?'
            $matches = [regex]::Matches($content, $importPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            foreach ($match in $matches) {
               $dependencies += $match.Groups[1].Value
            }
         }
         ".py" {
            # Rechercher import et from...import
            $importPattern = '(?:^|\n)\s*(?:import|from)\s+([^\s;#]+)'
            $matches = [regex]::Matches($content, $importPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            foreach ($match in $matches) {
               $dependencies += $match.Groups[1].Value
            }
         }
         ".go" {
            # Rechercher les imports Go
            $importPattern = 'import\s+[''"]([^''"]+)[''"]'
            $matches = [regex]::Matches($content, $importPattern)
            foreach ($match in $matches) {
               $dependencies += $match.Groups[1].Value
            }
         }
      }
   }
   catch {
      Write-Warning "Failed to analyze dependencies for $ScriptPath : $($_.Exception.Message)"
   }
    
   return $dependencies
}

# Fonction pour obtenir les métadonnées d'un script
function Get-ScriptMetadata {
   [CmdletBinding()]
   param([string]$ScriptPath)
    
   $metadata = @{}
    
   try {
      $content = Get-Content -Path $ScriptPath -Raw
        
      # Rechercher des métadonnées dans les commentaires
      $metadataPatterns = @{
         "Author"      = '(?:#|//|\*)\s*Author\s*:\s*(.+)'
         "Version"     = '(?:#|//|\*)\s*Version\s*:\s*(.+)'
         "Description" = '(?:#|//|\*)\s*Description\s*:\s*(.+)'
         "Created"     = '(?:#|//|\*)\s*Created\s*:\s*(.+)'
         "Modified"    = '(?:#|//|\*)\s*Modified\s*:\s*(.+)'
      }
        
      foreach ($key in $metadataPatterns.Keys) {
         $match = [regex]::Match($content, $metadataPatterns[$key], [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
         if ($match.Success) {
            $metadata[$key] = $match.Groups[1].Value.Trim()
         }
      }
        
      # Ajouter des métadonnées calculées
      $lines = ($content -split '\n').Count
      $metadata["LineCount"] = $lines
      $metadata["FileSize"] = (Get-Item $ScriptPath).Length
   }
   catch {
      Write-Warning "Failed to extract metadata for $ScriptPath : $($_.Exception.Message)"
   }
    
   return $metadata
}

# Fonction pour envoyer une erreur au ErrorManager Go
function Send-ErrorToManager {
   [CmdletBinding()]
   param([hashtable]$Error)
    
   try {
      # Créer un objet d'erreur compatible avec ErrorManager
      $errorEntry = @{
         id              = [System.Guid]::NewGuid().ToString()
         timestamp       = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
         message         = $Error.Error
         stack_trace     = $Error.StackTrace
         module          = "script-inventory-manager"
         error_code      = "SCRIPT_INVENTORY_ERROR"
         manager_context = @{
            powershell_version = $PSVersionTable.PSVersion.ToString()
            execution_policy   = Get-ExecutionPolicy
            current_user       = $env:USERNAME
         }
         severity        = "ERROR"
      }
        
      # Option 1: Écrire dans un fichier que Go peut surveiller
      $errorFile = Join-Path $env:TEMP "error-manager-ps-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
      $errorEntry | ConvertTo-Json -Depth 10 | Out-File -FilePath $errorFile -Encoding UTF8
        
      # Option 2: Envoyer via API REST (si le serveur Go est en cours d'exécution)
      # $apiUrl = "http://localhost:8080/api/errors"
      # Invoke-RestMethod -Uri $apiUrl -Method POST -Body ($errorEntry | ConvertTo-Json) -ContentType "application/json"
        
      Write-Verbose "Error sent to ErrorManager: $errorFile"
   }
   catch {
      Write-Warning "Failed to send error to ErrorManager: $($_.Exception.Message)"
   }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ScriptInventory, Get-ScriptDependencies, Get-ScriptMetadata
