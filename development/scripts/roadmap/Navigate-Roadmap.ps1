# Navigate-Roadmap.ps1
# Script pour naviguer facilement dans la roadmap et ses archives

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Active", "Completed", "All", "Search")]
    [string]$Mode = "Active",
    
    [Parameter(Mandatory = $false)]
    [int]$DetailLevel = 2,
    
    [Parameter(Mandatory = $false)]
    [string]$SearchTerm,
    
    [Parameter(Mandatory = $false)]
    [string]$SectionId,
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor,
    
    [Parameter(Mandatory = $false)]
    [string]$ActiveRoadmapPath = "projet\roadmaps\active\roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$CompletedRoadmapPath = "projet\roadmaps\archive\roadmap_completed.md",
    
    [Parameter(Mandatory = $false)]
    [string]$SectionsArchivePath = "projet\roadmaps\archive\sections"
)

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
    }
}

function Test-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le fichier $Path n'existe pas." -Level Warning
        return $false
    }
    
    return $true
}

function Get-SectionLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Line
    )
    
    if ($Line -match '^#{1,6}\s') {
        return ($Line -split ' ')[0].Length
    }
    
    return 0
}

function Get-SectionId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HeaderLine
    )
    
    if ($HeaderLine -match '\*\*([0-9.]+)\*\*') {
        return $Matches[1]
    }
    elseif ($HeaderLine -match '([0-9.]+)') {
        return $Matches[1]
    }
    
    return ""
}

function Show-RoadmapSummary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLevel = 2
    )
    
    if (-not (Test-FileExists -Path $RoadmapPath)) {
        return
    }
    
    try {
        $content = Get-Content -Path $RoadmapPath -Encoding UTF8
        $summary = @()
        
        foreach ($line in $content) {
            $level = Get-SectionLevel -Line $line
            
            if ($level -gt 0 -and $level -le $MaxLevel) {
                $indent = "  " * ($level - 1)
                $sectionId = Get-SectionId -HeaderLine $line
                $sectionTitle = $line -replace '^#{1,6}\s+', ''
                
                if (-not [string]::IsNullOrEmpty($sectionId)) {
                    $summary += "$indent- [$sectionId] $sectionTitle"
                }
                else {
                    $summary += "$indent- $sectionTitle"
                }
            }
        }
        
        return $summary
    }
    catch {
        Write-Log "Erreur lors de la gÃ©nÃ©ration du rÃ©sumÃ©: $_" -Level Error
        return @()
    }
}

function Show-RoadmapSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$SectionId
    )
    
    if (-not (Test-FileExists -Path $RoadmapPath)) {
        return
    }
    
    try {
        $content = Get-Content -Path $RoadmapPath -Encoding UTF8
        $sectionContent = @()
        $inSection = $false
        $sectionLevel = 0
        
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]
            $level = Get-SectionLevel -Line $line
            $currentSectionId = if ($level -gt 0) { Get-SectionId -HeaderLine $line } else { "" }
            
            if ($level -gt 0 -and $currentSectionId -eq $SectionId) {
                $inSection = $true
                $sectionLevel = $level
                $sectionContent += $line
            }
            elseif ($inSection) {
                if ($level -gt 0 -and $level -le $sectionLevel) {
                    # Nouvelle section de mÃªme niveau ou supÃ©rieur, on sort de la section
                    break
                }
                
                $sectionContent += $line
            }
        }
        
        return $sectionContent
    }
    catch {
        Write-Log "Erreur lors de la rÃ©cupÃ©ration de la section: $_" -Level Error
        return @()
    }
}

function Search-Roadmap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm
    )
    
    if (-not (Test-FileExists -Path $RoadmapPath)) {
        return @()
    }
    
    try {
        $content = Get-Content -Path $RoadmapPath -Encoding UTF8
        $results = @()
        $currentSection = ""
        $currentSectionId = ""
        
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]
            $level = Get-SectionLevel -Line $line
            
            if ($level -gt 0) {
                $currentSection = $line -replace '^#{1,6}\s+', ''
                $currentSectionId = Get-SectionId -HeaderLine $line
            }
            
            if ($line -match [regex]::Escape($SearchTerm)) {
                $results += [PSCustomObject]@{
                    LineNumber = $i + 1
                    Line = $line
                    Section = $currentSection
                    SectionId = $currentSectionId
                    FilePath = $RoadmapPath
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Log "Erreur lors de la recherche: $_" -Level Error
        return @()
    }
}

function Search-ArchiveSections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm
    )
    
    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Log "Le dossier d'archive $ArchivePath n'existe pas." -Level Warning
        return @()
    }
    
    try {
        $results = @()
        $files = Get-ChildItem -Path $ArchivePath -Filter "*.md" -Recurse
        
        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -Encoding UTF8
            $currentSection = ""
            $currentSectionId = ""
            
            for ($i = 0; $i -lt $content.Count; $i++) {
                $line = $content[$i]
                $level = Get-SectionLevel -Line $line
                
                if ($level -gt 0) {
                    $currentSection = $line -replace '^#{1,6}\s+', ''
                    $currentSectionId = Get-SectionId -HeaderLine $line
                }
                
                if ($line -match [regex]::Escape($SearchTerm)) {
                    $results += [PSCustomObject]@{
                        LineNumber = $i + 1
                        Line = $line
                        Section = $currentSection
                        SectionId = $currentSectionId
                        FilePath = $file.FullName
                    }
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Log "Erreur lors de la recherche dans les archives: $_" -Level Error
        return @()
    }
}

function Open-InEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [int]$LineNumber = 1
    )
    
    if (-not (Test-FileExists -Path $FilePath)) {
        return $false
    }
    
    try {
        # Utiliser code (VS Code) si disponible, sinon notepad
        $editor = if (Get-Command "code" -ErrorAction SilentlyContinue) { "code" } else { "notepad" }
        
        if ($editor -eq "code") {
            & code -g "$FilePath`:$LineNumber"
        }
        else {
            & notepad $FilePath
        }
        
        return $true
    }
    catch {
        Write-Log "Erreur lors de l'ouverture de l'Ã©diteur: $_" -Level Error
        return $false
    }
}

# ExÃ©cution principale
switch ($Mode) {
    "Active" {
        if (-not [string]::IsNullOrEmpty($SectionId)) {
            Write-Log "Affichage de la section $SectionId de la roadmap active..." -Level Info
            $sectionContent = Show-RoadmapSection -RoadmapPath $ActiveRoadmapPath -SectionId $SectionId
            
            if ($sectionContent.Count -gt 0) {
                $sectionContent | ForEach-Object { Write-Host $_ }
                
                if ($OpenInEditor) {
                    Open-InEditor -FilePath $ActiveRoadmapPath
                }
            }
            else {
                Write-Log "Section $SectionId non trouvÃ©e dans la roadmap active." -Level Warning
            }
        }
        else {
            Write-Log "Affichage du rÃ©sumÃ© de la roadmap active..." -Level Info
            $summary = Show-RoadmapSummary -RoadmapPath $ActiveRoadmapPath -MaxLevel $DetailLevel
            
            if ($summary.Count -gt 0) {
                Write-Host "`n# RÃ©sumÃ© de la Roadmap Active`n"
                $summary | ForEach-Object { Write-Host $_ }
                
                if ($OpenInEditor) {
                    Open-InEditor -FilePath $ActiveRoadmapPath
                }
            }
        }
    }
    "Completed" {
        if (-not [string]::IsNullOrEmpty($SectionId)) {
            Write-Log "Affichage de la section $SectionId de la roadmap complÃ©tÃ©e..." -Level Info
            $sectionContent = Show-RoadmapSection -RoadmapPath $CompletedRoadmapPath -SectionId $SectionId
            
            if ($sectionContent.Count -gt 0) {
                $sectionContent | ForEach-Object { Write-Host $_ }
                
                if ($OpenInEditor) {
                    Open-InEditor -FilePath $CompletedRoadmapPath
                }
            }
            else {
                # Chercher dans les sections archivÃ©es
                $archiveFiles = Get-ChildItem -Path $SectionsArchivePath -Filter "section_${SectionId}_*.md" -ErrorAction SilentlyContinue
                
                if ($archiveFiles.Count -gt 0) {
                    $archiveFile = $archiveFiles[0].FullName
                    Write-Log "Section trouvÃ©e dans les archives: $archiveFile" -Level Info
                    
                    $archiveContent = Get-Content -Path $archiveFile -Encoding UTF8
                    $archiveContent | ForEach-Object { Write-Host $_ }
                    
                    if ($OpenInEditor) {
                        Open-InEditor -FilePath $archiveFile
                    }
                }
                else {
                    Write-Log "Section $SectionId non trouvÃ©e dans la roadmap complÃ©tÃ©e ni dans les archives." -Level Warning
                }
            }
        }
        else {
            Write-Log "Affichage du rÃ©sumÃ© de la roadmap complÃ©tÃ©e..." -Level Info
            $summary = Show-RoadmapSummary -RoadmapPath $CompletedRoadmapPath -MaxLevel $DetailLevel
            
            if ($summary.Count -gt 0) {
                Write-Host "`n# RÃ©sumÃ© de la Roadmap ComplÃ©tÃ©e`n"
                $summary | ForEach-Object { Write-Host $_ }
                
                if ($OpenInEditor) {
                    Open-InEditor -FilePath $CompletedRoadmapPath
                }
            }
        }
    }
    "All" {
        Write-Log "Affichage du rÃ©sumÃ© complet de la roadmap..." -Level Info
        
        $activeSummary = Show-RoadmapSummary -RoadmapPath $ActiveRoadmapPath -MaxLevel $DetailLevel
        $completedSummary = Show-RoadmapSummary -RoadmapPath $CompletedRoadmapPath -MaxLevel $DetailLevel
        
        Write-Host "`n# RÃ©sumÃ© de la Roadmap Active`n"
        if ($activeSummary.Count -gt 0) {
            $activeSummary | ForEach-Object { Write-Host $_ }
        }
        else {
            Write-Host "  Aucune tÃ¢che active."
        }
        
        Write-Host "`n# RÃ©sumÃ© de la Roadmap ComplÃ©tÃ©e`n"
        if ($completedSummary.Count -gt 0) {
            $completedSummary | ForEach-Object { Write-Host $_ }
        }
        else {
            Write-Host "  Aucune tÃ¢che complÃ©tÃ©e."
        }
    }
    "Search" {
        if ([string]::IsNullOrEmpty($SearchTerm)) {
            Write-Log "Terme de recherche non spÃ©cifiÃ©." -Level Error
            return
        }
        
        Write-Log "Recherche de '$SearchTerm' dans la roadmap..." -Level Info
        
        $activeResults = Search-Roadmap -RoadmapPath $ActiveRoadmapPath -SearchTerm $SearchTerm
        $completedResults = Search-Roadmap -RoadmapPath $CompletedRoadmapPath -SearchTerm $SearchTerm
        $archiveResults = Search-ArchiveSections -ArchivePath $SectionsArchivePath -SearchTerm $SearchTerm
        
        $allResults = $activeResults + $completedResults + $archiveResults
        
        if ($allResults.Count -gt 0) {
            Write-Host "`n# RÃ©sultats de recherche pour '$SearchTerm'`n"
            
            $allResults | ForEach-Object {
                $filePath = $_.FilePath
                $fileName = Split-Path -Path $filePath -Leaf
                
                Write-Host "[$($_.SectionId)] $($_.Section) (Ligne $($_.LineNumber), $fileName)"
                Write-Host "  $($_.Line)" -ForegroundColor Yellow
                Write-Host ""
            }
            
            if ($OpenInEditor -and $allResults.Count -gt 0) {
                $firstResult = $allResults[0]
                Open-InEditor -FilePath $firstResult.FilePath -LineNumber $firstResult.LineNumber
            }
        }
        else {
            Write-Log "Aucun rÃ©sultat trouvÃ© pour '$SearchTerm'." -Level Warning
        }
    }
}
