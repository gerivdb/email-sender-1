# IndexLogFormat.ps1
# Script définissant le format de journal d'indexation
# Version: 1.0
# Date: 2025-05-15

# Classe pour représenter une entrée de journal d'indexation
class IndexLogEntry {
    # ID de l'entrée
    [string]$Id
    
    # Horodatage de l'entrée
    [DateTime]$Timestamp
    
    # Niveau de l'entrée (Info, Warning, Error, Debug)
    [string]$Level
    
    # Catégorie de l'entrée (Add, Update, Delete, Search, Compact, etc.)
    [string]$Category
    
    # Message de l'entrée
    [string]$Message
    
    # Données supplémentaires
    [hashtable]$Data
    
    # Constructeur par défaut
    IndexLogEntry() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Timestamp = Get-Date
        $this.Level = "Info"
        $this.Category = "General"
        $this.Message = ""
        $this.Data = @{}
    }
    
    # Constructeur avec niveau, catégorie et message
    IndexLogEntry([string]$level, [string]$category, [string]$message) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Timestamp = Get-Date
        $this.Level = $level
        $this.Category = $category
        $this.Message = $message
        $this.Data = @{}
    }
    
    # Constructeur complet
    IndexLogEntry([string]$level, [string]$category, [string]$message, [hashtable]$data) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Timestamp = Get-Date
        $this.Level = $level
        $this.Category = $category
        $this.Message = $message
        $this.Data = $data
    }
    
    # Méthode pour ajouter des données
    [void] AddData([string]$key, [object]$value) {
        $this.Data[$key] = $value
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "[$($this.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$($this.Level)] [$($this.Category)] $($this.Message)"
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        $obj = @{
            id = $this.Id
            timestamp = $this.Timestamp.ToString("o")
            level = $this.Level
            category = $this.Category
            message = $this.Message
            data = $this.Data
        }
        
        return ConvertTo-Json -InputObject $obj -Depth 10 -Compress
    }
    
    # Méthode pour convertir en CSV
    [string] ToCsv() {
        $dataStr = if ($this.Data.Count -gt 0) {
            $this.Data | ConvertTo-Json -Compress
        } else {
            ""
        }
        
        $fields = @(
            $this.Id,
            $this.Timestamp.ToString("o"),
            $this.Level,
            $this.Category,
            $this.Message,
            $dataStr
        )
        
        return $fields -join ","
    }
    
    # Méthode pour créer à partir de JSON
    static [IndexLogEntry] FromJson([string]$json) {
        $obj = ConvertFrom-Json -InputObject $json
        
        $entry = [IndexLogEntry]::new()
        $entry.Id = $obj.id
        $entry.Timestamp = [DateTime]::Parse($obj.timestamp)
        $entry.Level = $obj.level
        $entry.Category = $obj.category
        $entry.Message = $obj.message
        
        $entry.Data = @{}
        foreach ($prop in $obj.data.PSObject.Properties) {
            $entry.Data[$prop.Name] = $prop.Value
        }
        
        return $entry
    }
}

# Classe pour représenter un journal d'indexation
class IndexLog {
    # Liste des entrées
    [System.Collections.Generic.List[IndexLogEntry]]$Entries
    
    # Constructeur par défaut
    IndexLog() {
        $this.Entries = [System.Collections.Generic.List[IndexLogEntry]]::new()
    }
    
    # Méthode pour ajouter une entrée
    [void] AddEntry([IndexLogEntry]$entry) {
        $this.Entries.Add($entry)
    }
    
    # Méthode pour ajouter une entrée de niveau Info
    [IndexLogEntry] Info([string]$category, [string]$message, [hashtable]$data = @{}) {
        $entry = [IndexLogEntry]::new("Info", $category, $message, $data)
        $this.AddEntry($entry)
        return $entry
    }
    
    # Méthode pour ajouter une entrée de niveau Warning
    [IndexLogEntry] Warning([string]$category, [string]$message, [hashtable]$data = @{}) {
        $entry = [IndexLogEntry]::new("Warning", $category, $message, $data)
        $this.AddEntry($entry)
        return $entry
    }
    
    # Méthode pour ajouter une entrée de niveau Error
    [IndexLogEntry] Error([string]$category, [string]$message, [hashtable]$data = @{}) {
        $entry = [IndexLogEntry]::new("Error", $category, $message, $data)
        $this.AddEntry($entry)
        return $entry
    }
    
    # Méthode pour ajouter une entrée de niveau Debug
    [IndexLogEntry] Debug([string]$category, [string]$message, [hashtable]$data = @{}) {
        $entry = [IndexLogEntry]::new("Debug", $category, $message, $data)
        $this.AddEntry($entry)
        return $entry
    }
    
    # Méthode pour obtenir les entrées par niveau
    [IndexLogEntry[]] GetEntriesByLevel([string]$level) {
        return $this.Entries | Where-Object { $_.Level -eq $level }
    }
    
    # Méthode pour obtenir les entrées par catégorie
    [IndexLogEntry[]] GetEntriesByCategory([string]$category) {
        return $this.Entries | Where-Object { $_.Category -eq $category }
    }
    
    # Méthode pour obtenir les entrées par plage de dates
    [IndexLogEntry[]] GetEntriesByDateRange([DateTime]$startDate, [DateTime]$endDate) {
        return $this.Entries | Where-Object { $_.Timestamp -ge $startDate -and $_.Timestamp -le $endDate }
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        $entries = $this.Entries | ForEach-Object { $_.ToJson() }
        return "[$($entries -join ',')]"
    }
    
    # Méthode pour convertir en CSV
    [string] ToCsv() {
        $header = "Id,Timestamp,Level,Category,Message,Data"
        $rows = $this.Entries | ForEach-Object { $_.ToCsv() }
        return "$header`n$($rows -join "`n")"
    }
    
    # Méthode pour créer à partir de JSON
    static [IndexLog] FromJson([string]$json) {
        $log = [IndexLog]::new()
        $entries = ConvertFrom-Json -InputObject $json
        
        foreach ($entryObj in $entries) {
            $entryJson = $entryObj | ConvertTo-Json -Compress
            $entry = [IndexLogEntry]::FromJson($entryJson)
            $log.AddEntry($entry)
        }
        
        return $log
    }
}

# Classe pour représenter un formateur de journal
class IndexLogFormatter {
    # Format de sortie (JSON, CSV, Text)
    [string]$OutputFormat
    
    # Constructeur par défaut
    IndexLogFormatter() {
        $this.OutputFormat = "Text"
    }
    
    # Constructeur avec format de sortie
    IndexLogFormatter([string]$outputFormat) {
        $this.OutputFormat = $outputFormat
    }
    
    # Méthode pour formater une entrée
    [string] FormatEntry([IndexLogEntry]$entry) {
        switch ($this.OutputFormat) {
            "JSON" {
                return $entry.ToJson()
            }
            "CSV" {
                return $entry.ToCsv()
            }
            "Text" {
                return $entry.ToString()
            }
            default {
                return $entry.ToString()
            }
        }
    }
    
    # Méthode pour formater un journal
    [string] FormatLog([IndexLog]$log) {
        switch ($this.OutputFormat) {
            "JSON" {
                return $log.ToJson()
            }
            "CSV" {
                return $log.ToCsv()
            }
            "Text" {
                $lines = $log.Entries | ForEach-Object { $_.ToString() }
                return $lines -join "`n"
            }
            default {
                $lines = $log.Entries | ForEach-Object { $_.ToString() }
                return $lines -join "`n"
            }
        }
    }
}

# Fonction pour créer une entrée de journal
function New-IndexLogEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level,
        
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{}
    )
    
    return [IndexLogEntry]::new($Level, $Category, $Message, $Data)
}

# Fonction pour créer un journal
function New-IndexLog {
    [CmdletBinding()]
    param ()
    
    return [IndexLog]::new()
}

# Fonction pour créer un formateur de journal
function New-IndexLogFormatter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "CSV")]
        [string]$OutputFormat = "Text"
    )
    
    return [IndexLogFormatter]::new($OutputFormat)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexLogEntry, New-IndexLog, New-IndexLogFormatter
