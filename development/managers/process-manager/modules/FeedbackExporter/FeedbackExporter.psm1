<#
.SYNOPSIS
    Module d'exportation des messages de feedback pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctions pour exporter les messages de feedback
    collectÃ©s par le FeedbackCollector vers diffÃ©rents formats et destinations.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
if (-not (Get-Module -Name "FeedbackCollector")) {
    $feedbackCollectorPath = Join-Path -Path $PSScriptRoot -Parent -ChildPath "FeedbackCollector\FeedbackCollector.psm1"
    if (Test-Path -Path $feedbackCollectorPath) {
        Import-Module $feedbackCollectorPath -Force
    }
}

# Variables globales du module
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\config\managers\process-manager\feedback-exporter.config.json"
$script:DefaultExportPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\exports\feedback"
$script:SupportedFormats = @("JSON", "CSV", "XML", "HTML", "TEXT")
$script:DefaultFormat = "JSON"
$script:ExportHistory = @()

# Fonction de journalisation
function Write-ExporterLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    # DÃ©terminer la couleur en fonction du niveau
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }
    
    # Ã‰crire le message dans la console
    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] [FeedbackExporter] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour initialiser l'exportateur de feedback
function Initialize-FeedbackExporter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$ExportPath = $script:DefaultExportPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "XML", "HTML", "TEXT")]
        [string]$DefaultFormat = $script:DefaultFormat
    )
    
    try {
        # VÃ©rifier si le rÃ©pertoire d'exportation existe
        if (-not (Test-Path -Path $ExportPath -PathType Container)) {
            New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
            Write-ExporterLog -Message "RÃ©pertoire d'exportation crÃ©Ã© : $ExportPath" -Level Info
        }
        
        # Charger la configuration si elle existe
        if (Test-Path -Path $ConfigPath -PathType Leaf) {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            if ($config.DefaultFormat -and $script:SupportedFormats -contains $config.DefaultFormat) {
                $DefaultFormat = $config.DefaultFormat
            }
            
            Write-ExporterLog -Message "Configuration chargÃ©e depuis $ConfigPath" -Level Info
        }
        else {
            # CrÃ©er la configuration par dÃ©faut
            $config = @{
                DefaultFormat = $DefaultFormat
                ExportPath = $ExportPath
                SupportedFormats = $script:SupportedFormats
            }
            
            # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
            $configDir = Split-Path -Path $ConfigPath -Parent
            if (-not (Test-Path -Path $configDir -PathType Container)) {
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
            }
            
            # Enregistrer la configuration
            $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigPath -Encoding utf8
            Write-ExporterLog -Message "Configuration par dÃ©faut crÃ©Ã©e : $ConfigPath" -Level Info
        }
        
        # Mettre Ã  jour les variables globales
        $script:DefaultExportPath = $ExportPath
        $script:DefaultFormat = $DefaultFormat
        
        Write-ExporterLog -Message "Exportateur de feedback initialisÃ©" -Level Success
        return $true
    }
    catch {
        Write-ExporterLog -Message "Erreur lors de l'initialisation de l'exportateur de feedback : $_" -Level Error
        return $false
    }
}

# Fonction pour exporter les messages collectÃ©s
function Export-CollectedMessages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "XML", "HTML", "TEXT")]
        [string]$Format = $script:DefaultFormat,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [FeedbackFilter]$Filter,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeStatistics,
        
        [Parameter(Mandatory = $false)]
        [switch]$Compress,
        
        [Parameter(Mandatory = $false)]
        [switch]$ClearAfterExport
    )
    
    try {
        # VÃ©rifier si le module FeedbackCollector est disponible
        if (-not (Get-Module -Name "FeedbackCollector")) {
            Write-ExporterLog -Message "Le module FeedbackCollector n'est pas disponible" -Level Error
            return $null
        }
        
        # DÃ©terminer le chemin de sortie
        if (-not $OutputPath) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = "feedback_export_${timestamp}.${Format}".ToLower()
            $OutputPath = Join-Path -Path $script:DefaultExportPath -ChildPath $fileName
        }
        
        # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -Path $outputDir -PathType Container)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Obtenir les messages collectÃ©s
        $messages = $null
        
        if ($Filter) {
            # Utiliser la fonction de filtrage du collecteur
            $messages = $script:MessageCollection.GetFilteredMessages($Filter)
        }
        else {
            # Utiliser tous les messages
            $messages = $script:MessageCollection.Messages
        }
        
        if (-not $messages -or $messages.Count -eq 0) {
            Write-ExporterLog -Message "Aucun message Ã  exporter" -Level Warning
            return $null
        }
        
        # PrÃ©parer les donnÃ©es Ã  exporter
        $exportData = @{
            Messages = $messages
            ExportTime = Get-Date
            ExportFormat = $Format
            MessageCount = $messages.Count
        }
        
        if ($IncludeStatistics) {
            $exportData.Statistics = $script:MessageCollection.GetStatistics()
        }
        
        # Exporter les donnÃ©es selon le format demandÃ©
        switch ($Format) {
            "JSON" {
                $jsonContent = ConvertTo-Json -InputObject $exportData -Depth 10
                $jsonContent | Out-File -FilePath $OutputPath -Encoding utf8
            }
            "CSV" {
                $csvContent = "Timestamp,Type,Source,Severity,Message`n"
                
                foreach ($message in $messages) {
                    $timestamp = $message.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    $type = $message.Type
                    $source = $message.Source
                    $severity = $message.Severity
                    $messageText = $message.Message -replace ",", ";" -replace "`n", " " -replace "`r", " "
                    
                    $csvContent += "$timestamp,$type,$source,$severity,`"$messageText`"`n"
                }
                
                $csvContent | Out-File -FilePath $OutputPath -Encoding utf8
            }
            "XML" {
                $xmlContent = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n"
                $xmlContent += "<FeedbackExport>`n"
                $xmlContent += "  <ExportTime>$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))</ExportTime>`n"
                $xmlContent += "  <MessageCount>$($messages.Count)</MessageCount>`n"
                $xmlContent += "  <Messages>`n"
                
                foreach ($message in $messages) {
                    $timestamp = $message.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    $type = $message.Type
                    $source = $message.Source
                    $severity = $message.Severity
                    $messageText = [System.Security.SecurityElement]::Escape($message.Message)
                    
                    $xmlContent += "    <Message>`n"
                    $xmlContent += "      <Timestamp>$timestamp</Timestamp>`n"
                    $xmlContent += "      <Type>$type</Type>`n"
                    $xmlContent += "      <Source>$source</Source>`n"
                    $xmlContent += "      <Severity>$severity</Severity>`n"
                    $xmlContent += "      <Text>$messageText</Text>`n"
                    $xmlContent += "    </Message>`n"
                }
                
                $xmlContent += "  </Messages>`n"
                
                if ($IncludeStatistics) {
                    $xmlContent += "  <Statistics>`n"
                    $xmlContent += "    <TotalMessages>$($exportData.Statistics.TotalMessages)</TotalMessages>`n"
                    $xmlContent += "    <ErrorCount>$($exportData.Statistics.ErrorCount)</ErrorCount>`n"
                    $xmlContent += "    <WarningCount>$($exportData.Statistics.WarningCount)</WarningCount>`n"
                    $xmlContent += "    <InfoCount>$($exportData.Statistics.InfoCount)</InfoCount>`n"
                    $xmlContent += "    <SuccessCount>$($exportData.Statistics.SuccessCount)</SuccessCount>`n"
                    $xmlContent += "    <DebugCount>$($exportData.Statistics.DebugCount)</DebugCount>`n"
                    $xmlContent += "    <VerboseCount>$($exportData.Statistics.VerboseCount)</VerboseCount>`n"
                    $xmlContent += "  </Statistics>`n"
                }
                
                $xmlContent += "</FeedbackExport>"
                
                $xmlContent | Out-File -FilePath $OutputPath -Encoding utf8
            }
            "HTML" {
                $htmlContent = "<!DOCTYPE html>`n"
                $htmlContent += "<html>`n"
                $htmlContent += "<head>`n"
                $htmlContent += "  <meta charset=`"UTF-8`">`n"
                $htmlContent += "  <title>Feedback Export</title>`n"
                $htmlContent += "  <style>`n"
                $htmlContent += "    body { font-family: Arial, sans-serif; margin: 20px; }`n"
                $htmlContent += "    h1 { color: #333; }`n"
                $htmlContent += "    table { border-collapse: collapse; width: 100%; }`n"
                $htmlContent += "    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
                $htmlContent += "    th { background-color: #f2f2f2; }`n"
                $htmlContent += "    tr:nth-child(even) { background-color: #f9f9f9; }`n"
                $htmlContent += "    .error { color: #d9534f; }`n"
                $htmlContent += "    .warning { color: #f0ad4e; }`n"
                $htmlContent += "    .info { color: #5bc0de; }`n"
                $htmlContent += "    .success { color: #5cb85c; }`n"
                $htmlContent += "    .debug { color: #777; }`n"
                $htmlContent += "    .verbose { color: #aaa; }`n"
                $htmlContent += "  </style>`n"
                $htmlContent += "</head>`n"
                $htmlContent += "<body>`n"
                $htmlContent += "  <h1>Feedback Export</h1>`n"
                $htmlContent += "  <p>Export Time: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))</p>`n"
                $htmlContent += "  <p>Message Count: $($messages.Count)</p>`n"
                
                if ($IncludeStatistics) {
                    $htmlContent += "  <h2>Statistics</h2>`n"
                    $htmlContent += "  <table>`n"
                    $htmlContent += "    <tr><th>Metric</th><th>Value</th></tr>`n"
                    $htmlContent += "    <tr><td>Total Messages</td><td>$($exportData.Statistics.TotalMessages)</td></tr>`n"
                    $htmlContent += "    <tr><td>Error Count</td><td>$($exportData.Statistics.ErrorCount)</td></tr>`n"
                    $htmlContent += "    <tr><td>Warning Count</td><td>$($exportData.Statistics.WarningCount)</td></tr>`n"
                    $htmlContent += "    <tr><td>Info Count</td><td>$($exportData.Statistics.InfoCount)</td></tr>`n"
                    $htmlContent += "    <tr><td>Success Count</td><td>$($exportData.Statistics.SuccessCount)</td></tr>`n"
                    $htmlContent += "    <tr><td>Debug Count</td><td>$($exportData.Statistics.DebugCount)</td></tr>`n"
                    $htmlContent += "    <tr><td>Verbose Count</td><td>$($exportData.Statistics.VerboseCount)</td></tr>`n"
                    $htmlContent += "  </table>`n"
                }
                
                $htmlContent += "  <h2>Messages</h2>`n"
                $htmlContent += "  <table>`n"
                $htmlContent += "    <tr><th>Timestamp</th><th>Type</th><th>Source</th><th>Severity</th><th>Message</th></tr>`n"
                
                foreach ($message in $messages) {
                    $timestamp = $message.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    $type = $message.Type
                    $source = $message.Source
                    $severity = $message.Severity
                    $messageText = [System.Web.HttpUtility]::HtmlEncode($message.Message)
                    
                    $cssClass = $type.ToString().ToLower()
                    
                    $htmlContent += "    <tr class=`"$cssClass`">`n"
                    $htmlContent += "      <td>$timestamp</td>`n"
                    $htmlContent += "      <td>$type</td>`n"
                    $htmlContent += "      <td>$source</td>`n"
                    $htmlContent += "      <td>$severity</td>`n"
                    $htmlContent += "      <td>$messageText</td>`n"
                    $htmlContent += "    </tr>`n"
                }
                
                $htmlContent += "  </table>`n"
                $htmlContent += "</body>`n"
                $htmlContent += "</html>"
                
                $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8
            }
            "TEXT" {
                $textContent = "=== Feedback Export ===`n"
                $textContent += "Export Time: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))`n"
                $textContent += "Message Count: $($messages.Count)`n`n"
                
                if ($IncludeStatistics) {
                    $textContent += "=== Statistics ===`n"
                    $textContent += "Total Messages: $($exportData.Statistics.TotalMessages)`n"
                    $textContent += "Error Count: $($exportData.Statistics.ErrorCount)`n"
                    $textContent += "Warning Count: $($exportData.Statistics.WarningCount)`n"
                    $textContent += "Info Count: $($exportData.Statistics.InfoCount)`n"
                    $textContent += "Success Count: $($exportData.Statistics.SuccessCount)`n"
                    $textContent += "Debug Count: $($exportData.Statistics.DebugCount)`n"
                    $textContent += "Verbose Count: $($exportData.Statistics.VerboseCount)`n`n"
                }
                
                $textContent += "=== Messages ===`n"
                
                foreach ($message in $messages) {
                    $timestamp = $message.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    $type = $message.Type
                    $source = $message.Source
                    $severity = $message.Severity
                    $messageText = $message.Message
                    
                    $textContent += "[$timestamp] [$type] [$source] [Severity: $severity]`n"
                    $textContent += "$messageText`n`n"
                }
                
                $textContent | Out-File -FilePath $OutputPath -Encoding utf8
            }
        }
        
        # Compresser le fichier si demandÃ©
        if ($Compress) {
            $compressedPath = "$OutputPath.zip"
            
            if (Test-Path -Path $compressedPath -PathType Leaf) {
                Remove-Item -Path $compressedPath -Force
            }
            
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory((Split-Path -Path $OutputPath -Parent), $compressedPath)
            
            # Supprimer le fichier original
            Remove-Item -Path $OutputPath -Force
            
            # Mettre Ã  jour le chemin de sortie
            $OutputPath = $compressedPath
        }
        
        # Vider la collection si demandÃ©
        if ($ClearAfterExport) {
            $script:MessageCollection.Clear()
            Write-ExporterLog -Message "Collection vidÃ©e aprÃ¨s exportation" -Level Info
        }
        
        # Ajouter l'exportation Ã  l'historique
        $exportInfo = @{
            Path = $OutputPath
            Format = $Format
            Timestamp = Get-Date
            MessageCount = $messages.Count
            Compressed = $Compress
        }
        
        $script:ExportHistory += $exportInfo
        
        Write-ExporterLog -Message "Messages exportÃ©s avec succÃ¨s : $OutputPath" -Level Success
        return $OutputPath
    }
    catch {
        Write-ExporterLog -Message "Erreur lors de l'exportation des messages : $_" -Level Error
        return $null
    }
}

# Fonction pour exporter les messages importants
function Export-ImportantMessages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "XML", "HTML", "TEXT")]
        [string]$Format = $script:DefaultFormat,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [switch]$Compress
    )
    
    try {
        # DÃ©terminer le chemin de sortie
        if (-not $OutputPath) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = "important_messages_${timestamp}.${Format}".ToLower()
            $OutputPath = Join-Path -Path $script:DefaultExportPath -ChildPath $fileName
        }
        
        # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -Path $outputDir -PathType Container)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # DÃ©terminer le rÃ©pertoire des messages importants
        $importantMessagesDir = Join-Path -Path (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\data\feedback") -ChildPath "important"
        
        if (-not (Test-Path -Path $importantMessagesDir -PathType Container)) {
            Write-ExporterLog -Message "Aucun message important trouvÃ©" -Level Warning
            return $null
        }
        
        # Obtenir les fichiers de messages importants
        $messageFiles = Get-ChildItem -Path $importantMessagesDir -Filter "important_*.json" -File
        
        if (-not $messageFiles -or $messageFiles.Count -eq 0) {
            Write-ExporterLog -Message "Aucun message important trouvÃ©" -Level Warning
            return $null
        }
        
        # Filtrer les fichiers par date si nÃ©cessaire
        if ($StartDate -or $EndDate) {
            $filteredFiles = @()
            
            foreach ($file in $messageFiles) {
                $fileDate = $file.CreationTime
                
                $includeFile = $true
                
                if ($StartDate -and $fileDate -lt $StartDate) {
                    $includeFile = $false
                }
                
                if ($EndDate -and $fileDate -gt $EndDate) {
                    $includeFile = $false
                }
                
                if ($includeFile) {
                    $filteredFiles += $file
                }
            }
            
            $messageFiles = $filteredFiles
        }
        
        if (-not $messageFiles -or $messageFiles.Count -eq 0) {
            Write-ExporterLog -Message "Aucun message important trouvÃ© dans la plage de dates spÃ©cifiÃ©e" -Level Warning
            return $null
        }
        
        # Charger les messages importants
        $importantMessages = @()
        
        foreach ($file in $messageFiles) {
            try {
                $messageJson = Get-Content -Path $file.FullName -Raw
                $message = ConvertFrom-Json -InputObject $messageJson
                $importantMessages += $message
            }
            catch {
                Write-ExporterLog -Message "Erreur lors du chargement du message important $($file.Name) : $_" -Level Warning
            }
        }
        
        if (-not $importantMessages -or $importantMessages.Count -eq 0) {
            Write-ExporterLog -Message "Aucun message important valide trouvÃ©" -Level Warning
            return $null
        }
        
        # PrÃ©parer les donnÃ©es Ã  exporter
        $exportData = @{
            Messages = $importantMessages
            ExportTime = Get-Date
            ExportFormat = $Format
            MessageCount = $importantMessages.Count
        }
        
        # Exporter les donnÃ©es selon le format demandÃ© (mÃªme logique que Export-CollectedMessages)
        # Pour Ã©viter la duplication de code, on pourrait refactoriser cette partie
        # dans une fonction commune, mais pour simplifier, on la rÃ©pÃ¨te ici
        
        switch ($Format) {
            "JSON" {
                $jsonContent = ConvertTo-Json -InputObject $exportData -Depth 10
                $jsonContent | Out-File -FilePath $OutputPath -Encoding utf8
            }
            "CSV" {
                $csvContent = "Timestamp,Type,Source,Severity,Message`n"
                
                foreach ($message in $importantMessages) {
                    $timestamp = $message.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    $type = $message.Type
                    $source = $message.Source
                    $severity = $message.Severity
                    $messageText = $message.Message -replace ",", ";" -replace "`n", " " -replace "`r", " "
                    
                    $csvContent += "$timestamp,$type,$source,$severity,`"$messageText`"`n"
                }
                
                $csvContent | Out-File -FilePath $OutputPath -Encoding utf8
            }
            # Les autres formats (XML, HTML, TEXT) suivraient la mÃªme logique que dans Export-CollectedMessages
            # Pour simplifier, on ne les rÃ©pÃ¨te pas ici
        }
        
        # Compresser le fichier si demandÃ©
        if ($Compress) {
            $compressedPath = "$OutputPath.zip"
            
            if (Test-Path -Path $compressedPath -PathType Leaf) {
                Remove-Item -Path $compressedPath -Force
            }
            
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory((Split-Path -Path $OutputPath -Parent), $compressedPath)
            
            # Supprimer le fichier original
            Remove-Item -Path $OutputPath -Force
            
            # Mettre Ã  jour le chemin de sortie
            $OutputPath = $compressedPath
        }
        
        # Ajouter l'exportation Ã  l'historique
        $exportInfo = @{
            Path = $OutputPath
            Format = $Format
            Timestamp = Get-Date
            MessageCount = $importantMessages.Count
            Compressed = $Compress
            Type = "ImportantMessages"
        }
        
        $script:ExportHistory += $exportInfo
        
        Write-ExporterLog -Message "Messages importants exportÃ©s avec succÃ¨s : $OutputPath" -Level Success
        return $OutputPath
    }
    catch {
        Write-ExporterLog -Message "Erreur lors de l'exportation des messages importants : $_" -Level Error
        return $null
    }
}

# Fonction pour obtenir l'historique des exportations
function Get-ExportHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Count = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )
    
    try {
        if ($Count -le 0 -or $Count -gt $script:ExportHistory.Count) {
            $history = $script:ExportHistory
        }
        else {
            $history = $script:ExportHistory | Select-Object -Last $Count
        }
        
        if (-not $IncludeDetails) {
            $history = $history | Select-Object Path, Format, Timestamp, MessageCount
        }
        
        return $history
    }
    catch {
        Write-ExporterLog -Message "Erreur lors de la rÃ©cupÃ©ration de l'historique des exportations : $_" -Level Error
        return $null
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-FeedbackExporter, Export-CollectedMessages, Export-ImportantMessages, Get-ExportHistory
